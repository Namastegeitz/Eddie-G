// Every number that decides scores, stars, bananas and timers lives here.
// The How it works screen is generated from this file, so what players read
// is always what the game does.

export const RULES = {
  startLives: 3,
  // Points
  pointsPerStep: 100,
  perfectBonus: 50,
  greatBonus: 25,
  roundBonus: 200,
  streakTiers: [
    { at: 0, mult: 1 },
    { at: 10, mult: 2 },
    { at: 25, mult: 3 },
  ],
  // Timing windows (distance from the nearest beat)
  perfectMs: 90,
  greatMs: 180,
  // Combos: both taps must land within this window
  chordWindowMs: 320,
  assistChordWindowMs: 520,
  // Stars
  threeStarOnBeat: 0.5, // share of steps tapped Perfect or Great
  // Bananas
  bananasPerStep: 1,
  bananasPerStar: 5,
  firstClearBananas: 10,
  endlessPerRound: 1,
  endlessMilestoneEvery: 5,
  endlessMilestoneBananas: 10,
  endlessBestBonus: 10,
  // Spending inside a level
  replayCost: 5,
  continueCost: 15,
  // Golden Bananas (the premium currency). Earned by playing or swapped from
  // bananas. The phone apps also sell packs (js/store.js); nothing needs them.
  goldFirstThreeStar: 2, // first time a level gets 3 stars
  goldWorldClear: 10, // first clear of level 10, 20 and 30
  goldEndlessEvery: 10, // 1 golden banana per this many rounds in an Endless run
  goldSetComplete: 5, // own every skin in a set
  exchangeRate: 100, // bananas for 1 golden banana
  // Timer: seconds = base + steps * perStep * (100 / tempo)
  timerBase: 3,
  timerPerStep: 1.4,
  relaxedTimerMult: 2,
};

export function streakMult(streak) {
  let m = 1;
  for (const t of RULES.streakTiers) if (streak >= t.at) m = t.mult;
  return m;
}

/** offsetSec: tap time minus nearest beat time (seconds). */
export function gradeTiming(offsetSec) {
  const ms = Math.abs(offsetSec) * 1000;
  if (ms <= RULES.perfectMs) return 'perfect';
  if (ms <= RULES.greatMs) return 'great';
  return 'good';
}

export function stepPoints(grade, streak) {
  const bonus = grade === 'perfect' ? RULES.perfectBonus : grade === 'great' ? RULES.greatBonus : 0;
  return (RULES.pointsPerStep + bonus) * streakMult(streak);
}

/**
 * Seconds allowed to copy a sequence.
 * timerMode: 'normal' | 'relaxed' | 'off'  (off returns Infinity)
 */
export function timeLimit(steps, bpm, timerMode = 'normal') {
  if (timerMode === 'off') return Infinity;
  const t = RULES.timerBase + steps * RULES.timerPerStep * (100 / bpm);
  return Math.round((timerMode === 'relaxed' ? t * RULES.relaxedTimerMult : t) * 10) / 10;
}

/**
 * Stars for a cleared level.
 *  1 star: cleared.  2 stars: lost at most 1 life.  3 stars: lost no lives
 *  AND at least half the steps were Perfect or Great.
 */
export function starsFor({ livesLost, onBeat, steps }) {
  const share = steps > 0 ? onBeat / steps : 0;
  if (livesLost === 0 && share >= RULES.threeStarOnBeat) return 3;
  if (livesLost <= 1) return 2;
  return 1;
}

/** Itemised bananas for clearing a level, so the results screen can show the sum. */
export function levelBananas({ stepsCleared, stars, firstClear }) {
  const items = [];
  items.push({ label: `Moves copied (${stepsCleared} x ${RULES.bananasPerStep})`, amount: stepsCleared * RULES.bananasPerStep });
  items.push({ label: `Stars (${stars} x ${RULES.bananasPerStar})`, amount: stars * RULES.bananasPerStar });
  if (firstClear) items.push({ label: 'First clear bonus', amount: RULES.firstClearBananas });
  return { items, total: items.reduce((s, i) => s + i.amount, 0) };
}

/** Itemised bananas for an Endless run. */
export function endlessBananas({ rounds, newBest }) {
  const items = [];
  items.push({ label: `Rounds cleared (${rounds} x ${RULES.endlessPerRound})`, amount: rounds * RULES.endlessPerRound });
  const milestones = Math.floor(rounds / RULES.endlessMilestoneEvery);
  if (milestones > 0) items.push({ label: `Every ${RULES.endlessMilestoneEvery} rounds (${milestones} x ${RULES.endlessMilestoneBananas})`, amount: milestones * RULES.endlessMilestoneBananas });
  if (newBest && rounds > 0) items.push({ label: 'New best', amount: RULES.endlessBestBonus });
  return { items, total: items.reduce((s, i) => s + i.amount, 0) };
}

/** Golden bananas for an Endless run of `rounds` cleared rounds. */
export function endlessGolden(rounds) {
  return Math.floor(rounds / RULES.goldEndlessEvery);
}
