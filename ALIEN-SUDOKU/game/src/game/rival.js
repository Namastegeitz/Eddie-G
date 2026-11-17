/* ============================================================
   Alien Duel: the AI rival. Pure logic, no DOM.

   The rival solves the same puzzle as the player, on its own
   board, at a pace set by its configuration. Its whole game is
   planned up front from a seed: a list of moves, each at a time
   on the rival's own clock. The play screen advances that clock
   with the game timer (so pausing pauses the rival), and a
   "keeps pace" option speeds the clock up or slows it down
   depending on who is ahead.

   Because the plan is deterministic, a saved duel only stores
   the configuration, the seed and the rival's clock.
   ============================================================ */

import { findSingle } from '../engine/logic.js';
import { computeCandidates, popcount } from '../engine/sudoku.js';
import { createRng } from '../engine/rng.js';

/** Speed 1..5: average seconds the rival takes per glyph on an Easy puzzle. */
export const SPEEDS = [
  { label: 'Sleepy', seconds: 20 },
  { label: 'Steady', seconds: 13 },
  { label: 'Quick', seconds: 9 },
  { label: 'Fast', seconds: 6 },
  { label: 'Lightning', seconds: 3.5 },
];
/** Accuracy 1..5: chance that a move starts with a fumble (a wrong glyph that costs time). */
export const ACCURACIES = [
  { label: 'Clumsy', slip: 0.24 },
  { label: 'Careless', slip: 0.14 },
  { label: 'Careful', slip: 0.07 },
  { label: 'Sharp', slip: 0.03 },
  { label: 'Flawless', slip: 0 },
];
export const STYLES = {
  steady: { label: 'Steady', blurb: 'An even pace from start to finish.' },
  streaky: { label: 'Streaky', blurb: 'Thinks for a while, then places a burst of glyphs.' },
  closer: { label: 'Strong finish', blurb: 'Starts slow and speeds up as the board fills.' },
};
export const HEAD_STARTS = [0, 15, 30, 60];
/** Harder puzzles take everyone longer per glyph. */
const DIFF_PACE = { easy: 1, medium: 1.2, hard: 1.5, alien: 1.9 };
const AVG_EMPTY = { easy: 43, medium: 49, hard: 55, alien: 59 };
/** How long a move takes, by the reasoning it needs. */
const TECHNIQUE_PACE = { 'full-house': 0.55, 'naked-single': 0.95, 'hidden-single': 1.1, search: 2.1 };

/**
 * The four rivals, soft to gnarly. `look` is the glyph used as the avatar:
 * a lineup key and a glyph number (1..9).
 */
export const RIVALS = {
  blip: {
    id: 'blip', name: 'Baby Blip', look: { set: 'softies', n: 1 }, tone: 'soft',
    tagline: 'A sleepy rookie. Slow, and fumbles a lot.',
    speed: 1, accuracy: 2, style: 'steady',
  },
  zorp: {
    id: 'zorp', name: 'Zorp', look: { set: 'creatures', n: 2 }, tone: 'playful',
    tagline: 'A playful trickster who works in bursts.',
    speed: 3, accuracy: 3, style: 'streaky',
  },
  vex: {
    id: 'vex', name: 'Commander Vex', look: { set: 'hostile', n: 2 }, tone: 'hostile',
    tagline: 'Fast and precise. Does not wait for anyone.',
    speed: 4, accuracy: 4, style: 'steady',
  },
  maw: {
    id: 'maw', name: 'The Maw', look: { set: 'gnarly', n: 1 }, tone: 'gnarly',
    tagline: 'Relentless. Never wrong, and gets faster.',
    speed: 5, accuracy: 5, style: 'closer',
  },
};
export const RIVAL_ORDER = ['blip', 'zorp', 'vex', 'maw'];
const TONE_BY_SET = { softies: 'soft', creatures: 'playful', hostile: 'hostile', gnarly: 'gnarly' };
export const LOOK_SETS = ['softies', 'creatures', 'hostile', 'gnarly'];

export const DUEL_DEFAULTS = {
  rival: 'zorp',
  name: '',            // empty = the rival's own name
  look: null,          // null = the rival's own look
  speed: null,         // null = the rival's own speed (1..5)
  accuracy: null,
  style: null,
  adaptive: false,     // keeps pace with the player
  headStart: 0,        // seconds the rival waits before its first move
  showGlyphs: false,   // show which glyphs the rival placed (not only where)
  chatter: true,
  difficulty: 'medium',
};

const clampInt = (v, lo, hi, fallback) => {
  const n = Math.round(Number(v));
  return Number.isFinite(n) ? Math.min(hi, Math.max(lo, n)) : fallback;
};

/**
 * Turn stored duel settings into a complete rival configuration.
 * `id` is the rival the result is recorded against: the chosen rival, or
 * 'custom' when it was made easier than that rival normally is.
 */
export function resolveRival(settings = {}) {
  const s = { ...DUEL_DEFAULTS, ...(settings || {}) };
  const base = RIVALS[s.rival] || RIVALS.zorp;
  const speed = clampInt(s.speed ?? base.speed, 1, 5, base.speed);
  const accuracy = clampInt(s.accuracy ?? base.accuracy, 1, 5, base.accuracy);
  const style = STYLES[s.style] ? s.style : base.style;
  const headStart = HEAD_STARTS.includes(Number(s.headStart)) ? Number(s.headStart) : 0;
  const look = s.look && LOOK_SETS.includes(s.look.set) ? { set: s.look.set, n: clampInt(s.look.n, 1, 9, 1) } : base.look;
  const name = String(s.name || '').replace(/\s+/g, ' ').trim().slice(0, 16) || base.name;
  const eased = speed < base.speed || accuracy < base.accuracy || headStart > 0;
  return {
    base: base.id,
    id: eased ? 'custom' : base.id,
    name,
    look,
    tone: TONE_BY_SET[look.set] || base.tone,
    speed, accuracy, style,
    adaptive: !!s.adaptive,
    headStart,
    showGlyphs: !!s.showGlyphs,
    chatter: s.chatter !== false,
    tuned: speed !== base.speed || accuracy !== base.accuracy || style !== base.style || headStart > 0 || !!s.adaptive,
  };
}

/** "Quick · Careful · Streaky" */
export function describeRival(r) {
  return `${SPEEDS[r.speed - 1].label} · ${ACCURACIES[r.accuracy - 1].label} · ${STYLES[r.style].label}`;
}

/** Roughly how long this rival takes on a puzzle of this difficulty, in ms (for the setup screen). */
export function estimateRivalMs(r, difficulty) {
  // Most moves are singles (quicker than the base pace), and bursts shorten a streaky game.
  const per = SPEEDS[r.speed - 1].seconds * (DIFF_PACE[difficulty] || 1) * 0.86 * (r.style === 'streaky' ? 0.82 : 1);
  const slipCost = 1 + ACCURACIES[r.accuracy - 1].slip * 1.1;
  return Math.round(((AVG_EMPTY[difficulty] || 49) * per * slipCost + r.headStart) * 1000);
}

/**
 * Plan the rival's whole game.
 * Returns { events: [{ at, i, v, wrong }], total, endsAt } where `at` is in ms on the
 * rival's clock, `i` the cell, `v` the glyph it places (or, for a fumble, the wrong
 * glyph it tried) and `total` the number of cells it has to fill.
 */
export function planRival({ puzzle, solution, difficulty = 'medium', rival, seed = 1 }) {
  const rng = createRng(`duel:${seed}`);
  const board = puzzle.slice();
  const order = [];
  // Solve the way a person would: singles first, and when none is left, the most
  // constrained cell (which takes much longer to work out).
  for (;;) {
    let step = null;
    try { step = findSingle(board); } catch { step = null; }
    let i; let technique;
    if (step && step.placement) { i = step.placement.idx; technique = step.technique; } else {
      const cands = computeCandidates(board);
      let best = 10; i = -1;
      for (let k = 0; k < 81; k++) {
        if (board[k]) continue;
        const n = popcount(cands[k]);
        if (n < best) { best = n; i = k; }
      }
      technique = 'search';
    }
    if (i < 0) break;
    board[i] = solution[i];
    order.push({ i, technique });
  }

  const total = order.length;
  const base = SPEEDS[rival.speed - 1].seconds * 1000 * (DIFF_PACE[difficulty] || 1);
  const slip = ACCURACIES[rival.accuracy - 1].slip;
  const events = [];
  let t = rival.headStart * 1000;
  let burstLeft = 0;
  order.forEach(({ i, technique }, k) => {
    const progress = total > 1 ? k / (total - 1) : 1;
    let gap = base * (TECHNIQUE_PACE[technique] || 1) * (0.75 + rng.next() * 0.5);
    if (rival.style === 'closer') gap *= 1.4 - 0.8 * progress;
    if (rival.style === 'streaky') {
      // Bursts of 3-5 quick glyphs, then one long think that keeps the average.
      if (burstLeft > 0) { gap *= 0.3; burstLeft--; } else { gap *= 2.6; burstLeft = 2 + rng.int(3); }
    }
    if (k === 0) gap *= 0.6;
    if (slip > 0 && rng.next() < slip) {
      // A fumble: a wrong glyph partway through, then the time to recover.
      let wrong = 1 + rng.int(9);
      if (wrong === solution[i]) wrong = (wrong % 9) + 1;
      events.push({ at: Math.round(t + gap * 0.8), i, v: wrong, wrong: true });
      gap *= 1.9;
    }
    t += gap;
    events.push({ at: Math.round(t), i, v: solution[i], wrong: false });
  });
  return { events, total, endsAt: events.length ? events[events.length - 1].at : 0 };
}

/**
 * How fast the rival's clock runs against the game clock.
 * With "keeps pace" on, a rival that is behind hurries and one that is ahead eases off.
 * `gap` = glyphs the player has placed minus glyphs the rival has placed.
 */
export function paceRate(gap, adaptive) {
  if (!adaptive) return 1;
  return Math.min(1.6, Math.max(0.6, 1 + gap * 0.06));
}

/** The rival's running game. */
export class Rival {
  /**
   * @param {object} o { puzzle, solution, difficulty, rival (resolved config), seed, clock?, done? }
   */
  constructor(o) {
    this.config = o.rival;
    this.seed = o.seed;
    this.puzzle = o.puzzle;
    this.plan = planRival(o);
    this.total = this.plan.total;
    this.clock = 0;
    this.idx = 0;                       // next event to play
    this.board = o.puzzle.slice();      // the rival's own board
    this.filled = 0;
    this.fumbles = 0;
    if (o.clock) this.advance(o.clock, 1);
  }

  get finished() { return this.filled >= this.total; }
  get remaining() { return this.total - this.filled; }
  /** ms on the rival's clock until its next glyph, or null when done. */
  get nextIn() {
    for (let k = this.idx; k < this.plan.events.length; k++) if (!this.plan.events[k].wrong) return Math.max(0, this.plan.events[k].at - this.clock);
    return null;
  }

  /** Move the clock on by dt game-ms at the given rate. Returns the events that happened. */
  advance(dt, rate = 1) {
    if (dt > 0) this.clock += dt * rate;
    const out = [];
    const ev = this.plan.events;
    while (this.idx < ev.length && ev[this.idx].at <= this.clock) {
      const e = ev[this.idx++];
      if (e.wrong) this.fumbles++;
      else { this.board[e.i] = e.v; this.filled++; }
      out.push(e);
    }
    return out;
  }

  /** Jump straight to the end (tests, and "let the rival finish"). */
  finish() { return this.advance(Math.max(0, this.plan.endsAt - this.clock) + 1, 1); }

  state() { return { clock: Math.round(this.clock) }; }
}

// ------------------------------------------------------------
// What the rival says. One short line at a time.
// ------------------------------------------------------------
export const RIVAL_LINES = {
  soft: {
    start: ['Hi! Shall we play?', 'Ooh, a puzzle. Yay!', 'Good luck, friend!'],
    ahead: ['I found one! Did you?', 'Am I winning? Oh my!', 'Wheee, this is fun!'],
    behind: ['Wait for me, please!', 'You are so fast!', 'Wow, you are good at this.'],
    playerSlip: ['Oopsie! It happens.', 'Aw, try again!', 'I do that all the time.'],
    fumble: ['Oops, wrong one.', 'Hee hee, silly me.', 'That was not it.'],
    closing: ['Almost done, I think!', 'Just a few more!'],
    playerClosing: ['You are nearly there!', 'So close! Go, go!'],
    won: ['I did it! Good game!', 'Yay! Thank you for playing!'],
    lost: ['You won! Hooray for you!', 'That was amazing. Again?'],
  },
  playful: {
    start: ['Race you, earthling!', 'Ready? Too late, go!', 'Bet I finish first.'],
    ahead: ['Catch me if you can!', 'Zoom zoom. Keep up!', 'Is that all you have got?'],
    behind: ['Hey! No fair!', 'Slow down, will you?', 'Lucky guess, that one.'],
    playerSlip: ['Ha! Nice try.', 'Wrong glyph, earthling!', 'Whoops! Hee hee.'],
    fumble: ['Wait, not that one.', 'I meant to do that.', 'Oops. You saw nothing.'],
    closing: ['Nearly there. Bye bye!', 'Home stretch, earthling!'],
    playerClosing: ['Uh oh. Uh oh uh oh.', 'Do not finish. Please?'],
    won: ['Winner! That is me!', 'Too slow, earthling!'],
    lost: ['What? Rematch! Now!', 'Fine. You win this one.'],
  },
  hostile: {
    start: ['You will lose, human.', 'Begin. Try to keep up.', 'This will be quick.'],
    ahead: ['Too slow, human.', 'Is this your best?', 'Surrender now.'],
    behind: ['Impossible.', 'A temporary lead.', 'Enjoy it while it lasts.'],
    playerSlip: ['Pathetic.', 'Wrong. As expected.', 'Your species is doomed.'],
    fumble: ['A minor error.', 'Hmph.', 'That did not happen.'],
    closing: ['Your defeat is near.', 'Almost finished with you.'],
    playerClosing: ['No. This cannot be.', 'Faster. I must go faster.'],
    won: ['Victory. As planned.', 'Earth falls again.'],
    lost: ['You... defeated me?', 'This is not over, human.'],
  },
  gnarly: {
    start: ['I HUNGER FOR GLYPHS.', 'RUN, LITTLE MIND.', 'IT BEGINS.'],
    ahead: ['YOU ARE TOO SLOW.', 'I AM ALREADY AHEAD.', 'FEEL THE DREAD.'],
    behind: ['NO. NO. NO.', 'YOU WILL SLOW. THEY ALL DO.', 'GRRRRR.'],
    playerSlip: ['DELICIOUS MISTAKE.', 'YES. STUMBLE.', 'WRONG.'],
    fumble: ['HRRNGH.', 'A TWITCH. NOTHING MORE.', 'IGNORE THAT.'],
    closing: ['THE END IS NEAR.', 'ALMOST. FED.'],
    playerClosing: ['STOP. STOP NOW.', 'NOT POSSIBLE.'],
    won: ['DEVOURED.', 'I FEAST. YOU LOSE.'],
    lost: ['HOW. HOW?', 'I WILL RETURN.'],
  },
};

/** Pick a line for a situation. `roll` is a number 0..1. */
export function rivalLine(tone, situation, roll = Math.random()) {
  const set = (RIVAL_LINES[tone] || RIVAL_LINES.playful)[situation];
  if (!set || !set.length) return '';
  return set[Math.min(set.length - 1, Math.floor(roll * set.length))];
}
