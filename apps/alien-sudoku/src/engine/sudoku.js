/**
 * Core Sudoku primitives.
 *
 * A grid is a flat array of 81 ints (0 = empty, 1..9 = value), index = row * 9 + col.
 * Candidate masks are 9-bit ints: bit (v - 1) set means value v is possible.
 */

export const ALL = 0x1ff;

/** @type {number[][]} */
export const ROWS = [];
/** @type {number[][]} */
export const COLS = [];
/** @type {number[][]} */
export const BOXES = [];

for (let n = 0; n < 9; n++) {
  ROWS.push([]);
  COLS.push([]);
  BOXES.push([]);
}
for (let i = 0; i < 81; i++) {
  const r = (i / 9) | 0;
  const c = i % 9;
  const b = ((r / 3) | 0) * 3 + ((c / 3) | 0);
  ROWS[r].push(i);
  COLS[c].push(i);
  BOXES[b].push(i);
}

/** 27 units: rows 0-8, columns 9-17, boxes 18-26. */
export const UNITS = [...ROWS, ...COLS, ...BOXES];

const ROW_OF = new Uint8Array(81);
const COL_OF = new Uint8Array(81);
const BOX_OF = new Uint8Array(81);
for (let i = 0; i < 81; i++) {
  const r = (i / 9) | 0;
  const c = i % 9;
  ROW_OF[i] = r;
  COL_OF[i] = c;
  BOX_OF[i] = ((r / 3) | 0) * 3 + ((c / 3) | 0);
}

export const rowOf = (i) => ROW_OF[i];
export const colOf = (i) => COL_OF[i];
export const boxOf = (i) => BOX_OF[i];

/** PEERS[i]: the 20 other cells sharing a row, column or box with i (sorted). */
export const PEERS = [];
for (let i = 0; i < 81; i++) {
  const set = new Set([...ROWS[ROW_OF[i]], ...COLS[COL_OF[i]], ...BOXES[BOX_OF[i]]]);
  set.delete(i);
  PEERS.push([...set].sort((a, b) => a - b));
}

const POP = new Uint8Array(512);
for (let m = 1; m < 512; m++) POP[m] = POP[m >> 1] + (m & 1);

/** Number of set bits in a mask. */
export function popcount(mask) {
  if (mask >= 0 && mask < 512) return POP[mask];
  let m = mask >>> 0;
  m = m - ((m >>> 1) & 0x55555555);
  m = (m & 0x33333333) + ((m >>> 2) & 0x33333333);
  return (Math.imul((m + (m >>> 4)) & 0x0f0f0f0f, 0x01010101) >>> 24);
}

/** Values (1..9, ascending) whose bits are set in mask. */
export function maskToValues(mask) {
  const out = [];
  for (let v = 1; v <= 9; v++) if (mask & (1 << (v - 1))) out.push(v);
  return out;
}

/** Parse an 81-char string ('1'-'9', '0' or '.' for empty; whitespace ignored). */
export function parseGrid(str) {
  const s = String(str).replace(/\s+/g, '');
  if (s.length !== 81) throw new Error(`parseGrid: expected 81 cells, got ${s.length}`);
  const grid = new Array(81);
  for (let i = 0; i < 81; i++) {
    const ch = s[i];
    if (ch === '.' || ch === '0') grid[i] = 0;
    else if (ch >= '1' && ch <= '9') grid[i] = ch.charCodeAt(0) - 48;
    else throw new Error(`parseGrid: invalid character '${ch}' at ${i}`);
  }
  return grid;
}

/** Serialize a grid to an 81-char string using '0' for empty cells. */
export function gridToString(grid) {
  let s = '';
  for (let i = 0; i < 81; i++) s += grid[i] ? String(grid[i]) : '0';
  return s;
}

/** True if value v (1..9) does not clash with any peer of idx (the cell itself is ignored). */
export function isValidPlacement(grid, idx, v) {
  if (!(v >= 1 && v <= 9)) return false;
  const peers = PEERS[idx];
  for (let k = 0; k < 20; k++) if (grid[peers[k]] === v) return false;
  return true;
}

/** True if the filled cells contain no duplicate in any unit. */
export function isConsistent(grid) {
  for (let u = 0; u < 27; u++) {
    let seen = 0;
    const unit = UNITS[u];
    for (let k = 0; k < 9; k++) {
      const v = grid[unit[k]];
      if (!v) continue;
      const bit = 1 << (v - 1);
      if (seen & bit) return false;
      seen |= bit;
    }
  }
  return true;
}

/** True if grid is a complete, valid solution. */
export function isSolved(grid) {
  for (let i = 0; i < 81; i++) if (!grid[i]) return false;
  return isConsistent(grid);
}

/** Count filled cells. */
export function countClues(grid) {
  let n = 0;
  for (let i = 0; i < 81; i++) if (grid[i]) n++;
  return n;
}

/**
 * Basic candidate masks: for each empty cell, values not used by any peer.
 * Filled cells get 0.
 */
export function computeCandidates(grid) {
  const rows = new Uint16Array(9);
  const cols = new Uint16Array(9);
  const boxes = new Uint16Array(9);
  for (let i = 0; i < 81; i++) {
    const v = grid[i];
    if (v) {
      const bit = 1 << (v - 1);
      rows[ROW_OF[i]] |= bit;
      cols[COL_OF[i]] |= bit;
      boxes[BOX_OF[i]] |= bit;
    }
  }
  const out = new Array(81);
  for (let i = 0; i < 81; i++) {
    out[i] = grid[i] ? 0 : ALL & ~(rows[ROW_OF[i]] | cols[COL_OF[i]] | boxes[BOX_OF[i]]);
  }
  return out;
}

const BIT_TO_VALUE = new Uint8Array(257);
for (let v = 1; v <= 9; v++) BIT_TO_VALUE[1 << (v - 1)] = v;

/**
 * Bitmask backtracking search with MRV (fewest candidates first).
 * @param {ArrayLike<number>} grid
 * @param {number} limit stop after this many solutions
 * @param {object|null} rng if given, candidate values are tried in random order
 * @returns {{ count: number, first: number[] | null }}
 */
function search(grid, limit, rng) {
  const g = new Uint8Array(81);
  const rows = new Uint16Array(9);
  const cols = new Uint16Array(9);
  const boxes = new Uint16Array(9);
  const empties = [];
  for (let i = 0; i < 81; i++) {
    const v = grid[i] | 0;
    if (v < 0 || v > 9) return { count: 0, first: null };
    if (!v) {
      empties.push(i);
      continue;
    }
    const bit = 1 << (v - 1);
    const r = ROW_OF[i];
    const c = COL_OF[i];
    const b = BOX_OF[i];
    if ((rows[r] | cols[c] | boxes[b]) & bit) return { count: 0, first: null };
    rows[r] |= bit;
    cols[c] |= bit;
    boxes[b] |= bit;
    g[i] = v;
  }
  const n = empties.length;
  let count = 0;
  let first = null;

  function rec(depth) {
    if (depth === n) {
      count++;
      if (!first) first = Array.from(g);
      return count >= limit;
    }
    let best = depth;
    let bestMask = 0;
    let bestCount = 10;
    for (let k = depth; k < n; k++) {
      const i = empties[k];
      const m = ALL & ~(rows[ROW_OF[i]] | cols[COL_OF[i]] | boxes[BOX_OF[i]]);
      const pc = POP[m];
      if (pc < bestCount) {
        best = k;
        bestMask = m;
        bestCount = pc;
        if (pc <= 1) break;
      }
    }
    if (bestCount === 0) return false;
    const i = empties[best];
    empties[best] = empties[depth];
    empties[depth] = i;
    const r = ROW_OF[i];
    const c = COL_OF[i];
    const b = BOX_OF[i];
    if (rng && bestCount > 1) {
      const vals = rng.shuffle(maskToValues(bestMask));
      for (let k = 0; k < vals.length; k++) {
        const bit = 1 << (vals[k] - 1);
        rows[r] |= bit;
        cols[c] |= bit;
        boxes[b] |= bit;
        g[i] = vals[k];
        const stop = rec(depth + 1);
        rows[r] &= ~bit;
        cols[c] &= ~bit;
        boxes[b] &= ~bit;
        if (stop) {
          g[i] = 0;
          return true;
        }
      }
    } else {
      let m = bestMask;
      while (m) {
        const bit = m & -m;
        m ^= bit;
        rows[r] |= bit;
        cols[c] |= bit;
        boxes[b] |= bit;
        g[i] = BIT_TO_VALUE[bit];
        const stop = rec(depth + 1);
        rows[r] &= ~bit;
        cols[c] &= ~bit;
        boxes[b] &= ~bit;
        if (stop) {
          g[i] = 0;
          return true;
        }
      }
    }
    g[i] = 0;
    return false;
  }

  rec(0);
  return { count, first };
}

/** Solve a puzzle. Returns the (first found) solution, or null if none / invalid givens. */
export function solve(grid) {
  return search(grid, 1, null).first;
}

/** Count solutions, stopping at `limit` (default 2: enough to test uniqueness). */
export function countSolutions(grid, limit = 2) {
  return search(grid, Math.max(1, limit), null).count;
}

/** True if the puzzle has exactly one solution. */
export function hasUniqueSolution(grid) {
  return countSolutions(grid, 2) === 1;
}

/** A uniformly shuffled complete valid grid. */
export function generateSolved(rng) {
  const empty = new Array(81).fill(0);
  return search(empty, 1, rng).first;
}

/**
 * Carve a unique-solution puzzle out of a random solved grid.
 * Cells (or 180-degree rotational pairs when symmetric) are removed in random
 * order; a removal is kept only if the puzzle still has exactly one solution.
 * Carving stops once clues <= targetClues (a symmetric pair may land one below),
 * or when no further cell can be removed (a minimal puzzle; clues may then be
 * above targetClues).
 * @returns {{ puzzle: number[], solution: number[] }}
 */
export function generatePuzzle(rng, { targetClues = 30, symmetric = true } = {}) {
  const solution = generateSolved(rng);
  const puzzle = solution.slice();
  let clues = 81;
  const cells = [];
  for (let i = 0; i < (symmetric ? 41 : 81); i++) cells.push(i);
  const order = rng.shuffle(cells);
  for (let k = 0; k < order.length && clues > targetClues; k++) {
    const i = order[k];
    const j = 80 - i;
    const pair = symmetric && i !== j;
    const vi = puzzle[i];
    const vj = puzzle[j];
    puzzle[i] = 0;
    if (pair) puzzle[j] = 0;
    if (countSolutions(puzzle, 2) === 1) {
      clues -= pair ? 2 : 1;
    } else {
      puzzle[i] = vi;
      if (pair) puzzle[j] = vj;
    }
  }
  return { puzzle, solution };
}
