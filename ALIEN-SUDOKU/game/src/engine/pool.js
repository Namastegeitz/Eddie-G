/**
 * Runtime puzzle delivery: pick a pre-generated, pre-graded base puzzle and
 * apply a random validity-preserving transform. No search at runtime beyond
 * one cached solve() per base puzzle.
 *
 * The pools (src/data/puzzle-pool.json, built by tools/gen-puzzles.mjs) are
 * sorted easiest first within each band.
 */
import POOL from '../data/puzzle-pool.json' with { type: 'json' };
import { parseGrid, solve } from './sudoku.js';
import { createRng, seedToUint32 } from './rng.js';
import { randomTransform, applyTransform } from './transform.js';

export const DIFFICULTIES = ['easy', 'medium', 'hard', 'alien'];

/** Number of base puzzles per difficulty. */
export const POOL_SIZES = Object.fromEntries(DIFFICULTIES.map((d) => [d, POOL[d].length]));

const cache = Object.fromEntries(DIFFICULTIES.map((d) => [d, new Map()]));

function base(difficulty, index) {
  let entry = cache[difficulty].get(index);
  if (!entry) {
    const puzzle = parseGrid(POOL[difficulty][index]);
    entry = { puzzle, solution: solve(puzzle) };
    cache[difficulty].set(index, entry);
  }
  return entry;
}

function checkDifficulty(difficulty) {
  if (!DIFFICULTIES.includes(difficulty)) throw new Error(`Unknown difficulty: ${difficulty}`);
}

function build(difficulty, index, seedHash) {
  const b = base(difficulty, index);
  const t = randomTransform(createRng((seedHash ^ 0x9e3779b9) >>> 0));
  const puzzle = applyTransform(b.puzzle, t);
  let clues = 0;
  for (let i = 0; i < 81; i++) if (puzzle[i]) clues++;
  return {
    id: `${difficulty}:${index}:${seedHash.toString(36)}`,
    difficulty,
    puzzle,
    solution: applyTransform(b.solution, t),
    clues,
  };
}

/**
 * Deterministic puzzle for a seed (string or number): the seed picks the base
 * puzzle and the transform. Pass `index` to force the base puzzle.
 * @returns {{ id: string, difficulty: string, puzzle: number[], solution: number[], clues: number }}
 */
export function getPuzzle({ difficulty, seed = 0, index } = {}) {
  checkDifficulty(difficulty);
  const seedHash = seedToUint32(typeof seed === 'number' ? seed : String(seed));
  const n = POOL[difficulty].length;
  const idx = index == null ? createRng(seedHash).int(n) : ((index % n) + n) % n;
  return build(difficulty, idx, seedHash);
}

/** Rebuild a puzzle from its id ("medium:123:abc12"). Ids are stable while the pool file is unchanged. */
export function getPuzzleById(id) {
  const m = /^(\w+):(\d+):([0-9a-z]+)$/.exec(String(id));
  if (!m) throw new Error(`Bad puzzle id: ${id}`);
  const [, difficulty, index, hash] = m;
  checkDifficulty(difficulty);
  const idx = Number(index);
  if (idx >= POOL[difficulty].length) throw new Error(`Puzzle id out of range: ${id}`);
  return build(difficulty, idx, parseInt(hash, 36) >>> 0);
}

/** A fresh random puzzle (Math.random seed). */
export function randomPuzzle(difficulty) {
  return getPuzzle({ difficulty, seed: Math.floor(Math.random() * 0x100000000) });
}

// ------------------------------------------------------------------ daily

/** Difficulty by UTC weekday (0 = Sunday). */
export const DAILY_DIFFICULTY = ['hard', 'easy', 'medium', 'medium', 'hard', 'hard', 'alien'];

function parseDate(dateStr) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(dateStr));
  if (!m) throw new Error(`Expected YYYY-MM-DD, got ${dateStr}`);
  return [Number(m[1]), Number(m[2]), Number(m[3])];
}

/** Day of week (0 = Sunday) of a 'YYYY-MM-DD' calendar date, independent of the local timezone. */
export function weekdayOf(dateStr) {
  const [y, mo, d] = parseDate(dateStr);
  return new Date(Date.UTC(y, mo - 1, d)).getUTCDay();
}

/** The local calendar date as 'YYYY-MM-DD' (what "today" means to the player). */
export function localDateKey(date = new Date()) {
  const p = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${p(date.getMonth() + 1)}-${p(date.getDate())}`;
}

/** The daily puzzle for a calendar date: Mon easy, Tue/Wed medium, Thu/Fri/Sun hard, Sat alien. */
export function getDailyPuzzle(dateStr) {
  const difficulty = DAILY_DIFFICULTY[weekdayOf(dateStr)];
  return { ...getPuzzle({ difficulty, seed: `daily:${dateStr}` }), date: dateStr };
}

// --------------------------------------------------------------- campaign

export const CAMPAIGN = { sectors: 6, levelsPerSector: 9 };

/** Difficulty of a campaign level (sector 0..5, level 0..8). */
export function campaignDifficulty(sector, level) {
  switch (sector) {
    case 0:
      return 'easy';
    case 1:
      return level <= 3 ? 'easy' : 'medium';
    case 2:
      return 'medium';
    case 3:
      return level <= 3 ? 'medium' : 'hard';
    case 4:
      return 'hard';
    default:
      return level <= 2 ? 'hard' : 'alien';
  }
}

function checkCampaign(sector, level) {
  const ok = (v, n) => Number.isInteger(v) && v >= 0 && v < n;
  if (!ok(sector, CAMPAIGN.sectors) || !ok(level, CAMPAIGN.levelsPerSector)) {
    throw new Error(`Campaign level out of range: ${sector}/${level}`);
  }
}

// For each difficulty: the campaign levels using it, in play order.
const CAMPAIGN_SLOTS = Object.fromEntries(DIFFICULTIES.map((d) => [d, []]));
for (let s = 0; s < CAMPAIGN.sectors; s++) {
  for (let l = 0; l < CAMPAIGN.levelsPerSector; l++) CAMPAIGN_SLOTS[campaignDifficulty(s, l)].push(`${s}:${l}`);
}

/**
 * Base puzzle index for a campaign level. The k-th of n levels of a difficulty
 * draws from the k-th of n equal slices of that (easiest-first) pool, so
 * indices never repeat and difficulty ramps up within the band.
 */
function campaignIndex(difficulty, sector, level) {
  const slots = CAMPAIGN_SLOTS[difficulty];
  const k = slots.indexOf(`${sector}:${level}`);
  const n = slots.length;
  const size = POOL[difficulty].length;
  const lo = Math.floor((k * size) / n);
  const hi = Math.max(lo + 1, Math.floor(((k + 1) * size) / n));
  return lo + createRng(`campaign-pick:${difficulty}:${k}`).int(hi - lo);
}

/** Deterministic campaign puzzle (sector 0..5, level 0..8). */
export function getCampaignPuzzle(sector, level) {
  checkCampaign(sector, level);
  const difficulty = campaignDifficulty(sector, level);
  const index = campaignIndex(difficulty, sector, level);
  return { ...getPuzzle({ difficulty, seed: `campaign:${sector}:${level}`, index }), sector, level };
}
