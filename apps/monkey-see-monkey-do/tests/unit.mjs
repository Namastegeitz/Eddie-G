// Unit checks for the pure game rules (no browser needed):
//   node tests/unit.mjs
import { LEVELS, WORLDS, ENDLESS, TWISTS, generateRound, generateSteps, extendEndless, expectedSteps, watchSchedule, makeRng, twistFor, endlessBpm } from '../js/levels.js';
import { RULES, timeLimit, starsFor, levelBananas, endlessBananas, gradeTiming, streakMult, stepPoints } from '../js/rules.js';
import { MOVES, CHORDS, sameStep, moveName, chordFor, normStep } from '../js/moves.js';
import { ITEMS, CATEGORIES, DEFAULT_OWNED, DEFAULT_EQUIPPED, getItem } from '../js/shop.js';

let pass = 0;
let fail = 0;
function check(name, cond, info = '') {
  if (cond) pass++;
  else { fail++; console.log('✗', name, info); }
}

// ---- level table matches the design brief
check('30 levels', LEVELS.length === 30);
LEVELS.forEach((l, i) => check(`level ${i + 1} id`, l.id === i + 1));
check('3 worlds', WORLDS.length === 3);
for (const l of LEVELS) {
  check(`L${l.id} world`, l.world === Math.ceil(l.id / 10));
  check(`L${l.id} moves known`, l.moves.every((m) => MOVES[m]));
  check(`L${l.id} chords known`, l.chords.every((c) => CHORDS[c]));
  check(`L${l.id} chords use allowed moves`, l.chords.every((c) => CHORDS[c].parts.every((p) => l.moves.includes(p))));
  check(`L${l.id} 3-4 rounds`, l.rounds.length >= 3 && l.rounds.length <= 4);
  const tw = Array.isArray(l.twist) ? l.twist : [l.twist];
  check(`L${l.id} twists known`, tw.every((t) => t === null || TWISTS[t]));
}
for (const l of LEVELS.slice(0, 3)) {
  check(`L${l.id}: 2-3 steps`, l.rounds.every((n) => n >= 2 && n <= 3), l.rounds);
  check(`L${l.id}: slow tempo`, l.bpm <= 90);
  check(`L${l.id}: no combos`, l.chords.length === 0);
}
for (const l of LEVELS.slice(3, 10)) {
  check(`L${l.id}: 4-6 steps`, l.rounds.every((n) => n >= 4 && n <= 6), l.rounds);
  check(`L${l.id}: faster than level 3`, l.bpm > LEVELS[2].bpm);
  check(`L${l.id}: has combos (simultaneous moves)`, l.chords.length > 0);
}
for (let i = 1; i < 10; i++) check(`tempo rises in world 1 (${i + 1})`, LEVELS[i].bpm >= LEVELS[i - 1].bpm);
check('boss levels', [10, 20, 30].every((id) => LEVELS[id - 1].boss));

// ---- generator rules, over many seeds
let triples = 0, doubleChords = 0, outside = 0;
for (let seed = 1; seed < 4000; seed++) {
  const l = LEVELS[seed % 30];
  const rng = makeRng(seed * 2654435761);
  const steps = generateSteps(rng, 12, l.moves, l.chords, { chordChance: 0.4 });
  for (let i = 0; i < steps.length; i++) {
    const s = steps[i];
    if (s.length === 1 && !l.moves.includes(s[0])) outside++;
    if (s.length > 1 && !chordFor(s)) outside++;
    if (i >= 2 && sameStep(s, steps[i - 1]) && sameStep(s, steps[i - 2])) triples++;
    if (i >= 1 && s.length > 1 && steps[i - 1].length > 1) doubleChords++;
  }
}
check('never three of the same step in a row', triples === 0, triples);
check('never two combos in a row', doubleChords === 0, doubleChords);
check('steps only use the level\'s moves and combos', outside === 0, outside);

// determinism
const a = generateRound(LEVELS[8], 1, 12345);
const b = generateRound(LEVELS[8], 1, 12345);
check('same seed, same routine', JSON.stringify(a) === JSON.stringify(b));
const c = generateRound(LEVELS[8], 1, 54321);
check('different seed, (almost always) different routine', JSON.stringify(a.steps) !== JSON.stringify(c.steps));

// round lengths
for (const l of LEVELS) {
  let prev = null;
  l.rounds.forEach((n, r) => {
    const g = generateRound(l, r, 1000 + r * 7, prev);
    check(`L${l.id} r${r + 1} length`, g.steps.length === n, `${g.steps.length} vs ${n}`);
    if (twistFor(l, r) === 'buildup' && prev) check(`L${l.id} r${r + 1} builds on the last round`, JSON.stringify(g.steps.slice(0, prev.length)) === JSON.stringify(prev));
    prev = g.steps;
  });
}

// new things show up in round 1 (except level 1, which introduces 4 moves in 2 steps)
for (const l of LEVELS.filter((x) => x.id > 1 && x.intro.some((i) => MOVES[i] || CHORDS[i]))) {
  for (let seed = 0; seed < 200; seed++) {
    const g = generateRound(l, 0, seed * 97 + 1);
    for (const id of l.intro.filter((i) => MOVES[i] || CHORDS[i])) {
      const want = MOVES[id] ? [id] : normStep(CHORDS[id].parts);
      if (!g.steps.some((s) => sameStep(s, want))) { check(`L${l.id} round 1 includes new ${id}`, false, `seed ${seed}`); break; }
    }
  }
}
check('intro check ran', true);

// twists
check('reverse twist reverses', JSON.stringify(expectedSteps([['LA'], ['RL'], ['HD']], 'reverse')) === JSON.stringify([['HD'], ['RL'], ['LA']]));
check('no twist keeps order', JSON.stringify(expectedSteps([['LA'], ['RL']], null)) === JSON.stringify([['LA'], ['RL']]));
const sp = watchSchedule(10, 'speedup');
const gaps = sp.offsets.slice(1).map((o, i) => o - sp.offsets[i]);
check('speed-up gaps shrink', gaps.every((g, i) => i === 0 || g <= gaps[i - 1] + 1e-9));
check('speed-up never below 0.55 beats', gaps.every((g) => g >= 0.55 - 1e-9));
check('normal schedule is one beat per move', JSON.stringify(watchSchedule(4, null).offsets) === '[0,1,2,3]');

// endless
const rng = makeRng(7);
let seq = [];
for (let r = 0; r < 20; r++) {
  const next = extendEndless(rng, seq, r);
  check(`endless round ${r + 1} keeps the old routine`, JSON.stringify(next.slice(0, seq.length)) === JSON.stringify(seq));
  check(`endless round ${r + 1} length`, next.length === ENDLESS.startLength + r * ENDLESS.addPerRound);
  if (r < ENDLESS.chordsFromRound) check(`endless round ${r + 1} has no combos yet`, next.slice(seq.length).every((s) => s.length === 1));
  seq = next;
}
check('endless tempo capped', endlessBpm(1000) === ENDLESS.maxBpm);

// ---- rules
check('timer formula', timeLimit(2, 80) === Math.round((RULES.timerBase + 2 * RULES.timerPerStep * 1.25) * 10) / 10);
check('relaxed doubles', Math.abs(timeLimit(5, 100, 'relaxed') - 2 * timeLimit(5, 100)) < 0.11);
check('timer off', timeLimit(5, 100, 'off') === Infinity);
check('perfect', gradeTiming(0.05) === 'perfect' && gradeTiming(-0.09) === 'perfect');
check('great', gradeTiming(0.12) === 'great');
check('good', gradeTiming(0.25) === 'good');
check('streak tiers', streakMult(0) === 1 && streakMult(9) === 1 && streakMult(10) === 2 && streakMult(25) === 3);
check('step points', stepPoints('perfect', 10) === (RULES.pointsPerStep + RULES.perfectBonus) * 2);
check('3 stars', starsFor({ livesLost: 0, onBeat: 5, steps: 10 }) === 3);
check('2 stars when off-beat', starsFor({ livesLost: 0, onBeat: 4, steps: 10 }) === 2);
check('2 stars with one life lost', starsFor({ livesLost: 1, onBeat: 10, steps: 10 }) === 2);
check('1 star', starsFor({ livesLost: 2, onBeat: 10, steps: 10 }) === 1);
const lb = levelBananas({ stepsCleared: 7, stars: 3, firstClear: true });
check('level bananas add up', lb.total === 7 + 15 + 10 && lb.items.length === 3);
check('no first-clear bonus on replay', levelBananas({ stepsCleared: 7, stars: 3, firstClear: false }).total === 22);
const eb = endlessBananas({ rounds: 12, newBest: true });
check('endless bananas', eb.total === 12 + 20 + 10, eb.total);

// ---- moves + wardrobe
check('screen naming', moveName('LA') === 'Left Arm');
check('monkey naming swaps sides', moveName('LA', 'monkey') === 'Right Arm' && moveName('HD', 'monkey') === 'Head Bob');
check('chord lookup ignores order', chordFor(['RA', 'LA']).id === 'BA');
for (const cat of CATEGORIES) {
  const ids = ITEMS.filter((i) => i.cat === cat.id).map((i) => i.id);
  check(`${cat.id}: unique ids`, new Set(ids).size === ids.length);
  check(`${cat.id}: default owned exists`, DEFAULT_OWNED[cat.id].every((id) => getItem(cat.id, id)));
}
check('prices are whole, non-negative numbers', ITEMS.every((i) => Number.isInteger(i.price) && i.price >= 0));
check('default look is free', Object.entries(DEFAULT_EQUIPPED).every(([cat, id]) => id === 'auto' || getItem(cat, id).price === 0));

console.log(`${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
