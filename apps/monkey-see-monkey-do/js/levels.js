// Worlds, levels, Endless mode and the sequence generator.
// Pure data + pure functions: no DOM, no 3D. tests/unit.mjs checks it in Node.
import { CHORDS, MOVES, sameStep, normStep } from './moves.js';

export const WORLDS = [
  { id: 1, name: 'Jungle Clearing', stage: 'jungle', blurb: 'Learn the moves. Slow and friendly.' },
  { id: 2, name: 'Beach Bash', stage: 'beach', blurb: 'Longer routines, new combos, routines that build up.' },
  { id: 3, name: 'Temple Disco', stage: 'disco', blurb: 'Fast tempos, and some rounds go backwards.' },
];

export const TWISTS = {
  buildup: { name: 'Build-up', short: 'BUILD-UP', text: 'Each round repeats the last routine and adds new moves on the end.' },
  speedup: { name: 'Speed-up', short: 'SPEED-UP', text: 'The monkey gets faster during the routine. Your timer is the same.' },
  reverse: { name: 'Backwards', short: 'BACKWARDS', text: 'Copy the routine in reverse order: last move first.' },
};

const W1 = ['LA', 'RA', 'LL', 'RL'];
const W1H = [...W1, 'HD'];
const ALL6 = ['LA', 'HD', 'RA', 'LL', 'FL', 'RL'];

// L(id, name, round lengths, tempo, move pool, combo pool, extras)
function L(id, name, rounds, bpm, moves, chords = [], extra = {}) {
  return { id, world: Math.ceil(id / 10), name, rounds, bpm, moves, chords, twist: null, intro: [], ...extra };
}

export const LEVELS = [
  // World 1: 2-3 steps slow (1-3), then 4-6 steps, faster, combos (4-10)
  L(1, 'First Steps', [2, 2, 3], 80, W1, [], { intro: ['LA', 'RA', 'LL', 'RL'], guided: true }),
  L(2, 'Copy Cat', [2, 3, 3], 84, W1),
  L(3, 'Head Banana', [3, 3, 3], 88, W1H, [], { intro: ['HD'] }),
  L(4, 'Hooray!', [4, 4, 4], 95, W1H, ['BA'], { intro: ['BA'] }),
  L(5, 'Hip Wiggle', [4, 5, 5], 100, ALL6, ['BA'], { intro: ['FL'] }),
  L(6, 'Jump Up', [5, 5, 5], 104, ALL6, ['BA', 'BL'], { intro: ['BL'] }),
  L(7, 'Groove Time', [5, 5, 6], 108, ALL6, ['BA', 'BL']),
  L(8, 'Quick Feet', [5, 6, 6], 112, ALL6, ['BA', 'BL']),
  L(9, 'Big Routine', [6, 6, 6], 116, ALL6, ['BA', 'BL']),
  L(10, 'Jungle Showdown', [6, 6, 6, 6], 120, ALL6, ['BA', 'BL'], { boss: true }),
  // World 2: 6-9 steps, build-ups, cross combos, speed-ups
  L(11, 'Build It Up', [4, 6, 8], 108, ALL6, ['BA', 'BL'], { twist: 'buildup', intro: ['buildup'] }),
  L(12, 'Sandy Steps', [6, 6, 7], 112, ALL6, ['BA', 'BL']),
  L(13, 'Disco Point', [6, 7, 7], 114, ALL6, ['BA', 'BL', 'XL'], { intro: ['XL'] }),
  L(14, 'Wave Rider', [4, 6, 8], 116, ALL6, ['BA', 'BL', 'XL'], { twist: 'buildup' }),
  L(15, 'Crab Walk', [7, 7, 7], 118, ALL6, ['BA', 'BL', 'XL', 'XR'], { intro: ['XR'] }),
  L(16, 'Tide Turns', [7, 7, 8], 120, ALL6, ['BA', 'BL', 'XL', 'XR']),
  L(17, 'Speedboat', [6, 7, 7], 116, ALL6, ['BA', 'BL', 'XL', 'XR'], { twist: 'speedup', intro: ['speedup'] }),
  L(18, 'Sunset Groove', [5, 7, 9], 122, ALL6, ['BA', 'BL', 'XL', 'XR'], { twist: 'buildup' }),
  L(19, 'Coconut Combo', [8, 8, 8], 126, ALL6, ['BA', 'BL', 'XL', 'XR'], { chordChance: 0.3 }),
  L(20, 'Beach Showdown', [8, 8, 8, 8], 130, ALL6, ['BA', 'BL', 'XL', 'XR'], { boss: true, twist: [null, null, null, 'speedup'] }),
  // World 3: 7-10 steps, fast, backwards rounds
  L(21, 'Backwards Day', [4, 5, 5], 118, ALL6, ['BA', 'BL'], { twist: 'reverse', intro: ['reverse'] }),
  L(22, 'Temple Steps', [7, 8, 8], 126, ALL6, ['BA', 'BL', 'XL', 'XR']),
  L(23, 'Mirror Maze', [5, 6, 6], 124, ALL6, ['BA', 'BL', 'XL', 'XR'], { twist: 'reverse' }),
  L(24, 'Golden Idol', [8, 8, 9], 130, ALL6, ['BA', 'BL', 'XL', 'XR']),
  L(25, 'Torch Light', [6, 8, 10], 128, ALL6, ['BA', 'BL', 'XL', 'XR'], { twist: 'buildup' }),
  L(26, 'Flip Flop', [6, 6, 7], 128, ALL6, ['BA', 'BL', 'XL', 'XR'], { twist: 'reverse' }),
  L(27, 'Disco Fever', [8, 9, 9], 134, ALL6, ['BA', 'BL', 'XL', 'XR'], { twist: 'speedup' }),
  L(28, 'Ancient Rhythm', [9, 9, 9], 138, ALL6, ['BA', 'BL', 'XL', 'XR'], { chordChance: 0.3 }),
  L(29, 'Last Rehearsal', [7, 8, 9], 136, ALL6, ['BA', 'BL', 'XL', 'XR'], { twist: [null, 'reverse', 'speedup'] }),
  L(30, 'Temple Showdown', [9, 10, 10, 10], 142, ALL6, ['BA', 'BL', 'XL', 'XR'], { boss: true, twist: [null, 'speedup', 'reverse', null] }),
];

export const ENDLESS = {
  startLength: 2,
  addPerRound: 1,
  startBpm: 90,
  bpmPerRound: 3,
  maxBpm: 160,
  moves: ALL6,
  chordsFromRound: 6,
  chords: ['BA', 'BL', 'XL', 'XR'],
  chordChance: 0.18,
};

export function getLevel(id) {
  return LEVELS.find((l) => l.id === id) || null;
}

export function twistFor(level, roundIndex) {
  if (!level || !level.twist) return null;
  if (Array.isArray(level.twist)) return level.twist[roundIndex] || null;
  return level.twist;
}

/** Everything that is new in a level (moves, combos, twists). */
export function levelNews(level) {
  return (level.intro || []).map((id) => {
    if (MOVES[id]) return { kind: 'move', id, name: MOVES[id].name };
    if (CHORDS[id]) return { kind: 'chord', id, name: CHORDS[id].name };
    if (TWISTS[id]) return { kind: 'twist', id, name: TWISTS[id].name };
    return { kind: 'other', id, name: id };
  });
}

export function endlessBpm(roundIndex) {
  return Math.min(ENDLESS.maxBpm, ENDLESS.startBpm + roundIndex * ENDLESS.bpmPerRound);
}

// ---------------------------------------------------------------- random

/** Small, fast, seedable PRNG (mulberry32). Same seed -> same routine. */
export function makeRng(seed) {
  let a = seed >>> 0;
  return function rng() {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function newSeed() {
  return (Math.floor(Math.random() * 0xffffffff) ^ Date.now()) >>> 0;
}

const pick = (rng, arr) => arr[Math.floor(rng() * arr.length)];

/**
 * Make `count` steps. A step is an array of move ids (one move, or two for a combo).
 * Rules: no step three times in a row; no two combos back to back.
 */
export function generateSteps(rng, count, pool, chords = [], opts = {}) {
  const chordChance = chords.length ? (opts.chordChance ?? 0.22) : 0;
  const prev = opts.prev || [];
  const steps = [];
  for (let i = 0; i < count; i++) {
    const all = [...prev, ...steps];
    const p1 = all[all.length - 1];
    const p2 = all[all.length - 2];
    let step = null;
    for (let tries = 0; tries < 30; tries++) {
      const wantChord = chordChance > 0 && rng() < chordChance && !(p1 && p1.length > 1);
      step = wantChord ? normStep(CHORDS[pick(rng, chords)].parts) : [pick(rng, pool)];
      if (p1 && p2 && sameStep(step, p1) && sameStep(step, p2)) continue;
      break;
    }
    steps.push(step);
  }
  return steps;
}

/** Make sure each newly introduced move or combo shows up in the level's first round. */
export function forceIntro(rng, steps, intro) {
  const out = steps.map((s) => [...s]);
  const wanted = intro.filter((id) => MOVES[id] || CHORDS[id]);
  if (wanted.length > out.length) return out; // e.g. level 1 introduces 4 moves in 2 steps
  const used = new Set();
  for (const id of wanted) {
    const step = MOVES[id] ? [id] : normStep(CHORDS[id].parts);
    if (out.some((s) => sameStep(s, step))) continue;
    let slot;
    let guard = 0;
    do { slot = Math.floor(rng() * out.length); } while (used.has(slot) && guard++ < 20);
    used.add(slot);
    out[slot] = step;
  }
  return out;
}

/**
 * The routine for one round of an Adventure level.
 * prevSteps: the previous round's routine (needed for build-up levels).
 */
export function generateRound(level, roundIndex, seed, prevSteps = null) {
  const rng = makeRng(seed);
  const len = level.rounds[roundIndex];
  const twist = twistFor(level, roundIndex);
  const opts = { chordChance: level.chordChance };
  let steps;
  if (twist === 'buildup' && prevSteps && prevSteps.length < len) {
    steps = [...prevSteps.map((s) => [...s]), ...generateSteps(rng, len - prevSteps.length, level.moves, level.chords, { ...opts, prev: prevSteps })];
  } else {
    steps = generateSteps(rng, len, level.moves, level.chords, opts);
  }
  if (roundIndex === 0 && level.intro && level.intro.length) steps = forceIntro(rng, steps, level.intro);
  return { steps, twist, seed };
}

/** Endless: one new step on the end of the routine each round. */
export function extendEndless(rng, steps, roundIndex) {
  const chords = roundIndex >= ENDLESS.chordsFromRound ? ENDLESS.chords : [];
  const add = steps.length === 0 ? ENDLESS.startLength : ENDLESS.addPerRound;
  return [...steps, ...generateSteps(rng, add, ENDLESS.moves, chords, { chordChance: ENDLESS.chordChance, prev: steps })];
}

/** What the player must tap, in order, for a routine + twist. */
export function expectedSteps(steps, twist) {
  return twist === 'reverse' ? [...steps].reverse() : steps;
}

/**
 * Beat offsets (in beats from the first step) for showing each step.
 * Speed-up rounds squeeze each gap by 7%, never below 0.55 beats.
 */
export function watchSchedule(count, twist) {
  const out = [];
  let t = 0;
  for (let i = 0; i < count; i++) {
    out.push(t);
    const gap = twist === 'speedup' ? Math.max(0.55, Math.pow(0.93, i + 1)) : 1;
    t += gap;
  }
  return { offsets: out, length: t };
}
