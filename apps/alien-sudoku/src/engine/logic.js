/**
 * Human-style logical solver: used for grading puzzles and for in-game hints.
 *
 * findNextStep() always returns the SIMPLEST applicable step, in this order:
 *   tier 1  full-house, hidden-single (boxes, then rows, then cols), naked-single
 *   tier 2  locked-candidates-pointing, locked-candidates-claiming
 *   tier 3  naked-pair, hidden-pair, naked-triple, hidden-triple
 *   tier 4  x-wing, swordfish, xy-wing, naked-quad, hidden-quad
 * Unit-based techniques scan boxes 0-8, then rows 0-8, then columns 0-8.
 *
 * DIFFICULTY RULES (gradePuzzle). c = clue count, T = highest tier used.
 *   The logic must solve the puzzle completely, otherwise difficulty = null
 *   (never pooled). Classification is total and invariant under the
 *   validity-preserving transforms in transform.js:
 *     easy    T = 1, no naked single needed (full houses + hidden singles
 *             suffice) and c >= 36
 *     medium  T = 1 otherwise, or T = 2 with c >= 30
 *     hard    T = 2 with c <= 29, or T = 3 with c >= 26
 *     alien   T = 4, or T = 3 with c <= 25
 *   Pool acceptance (tools/gen-puzzles.mjs) additionally restricts clues:
 *     easy   c 36-40 (and at least 75% of the steps are full houses or
 *            hidden singles in boxes, so the solve feels easy)
 *     medium c 30-34, and T = 2, or T = 1 with c <= 32 (the generator
 *            fills 40% of the medium pool with T = 2 puzzles by default)
 *     hard   c 25-29 (T is then 2 or 3, i.e. at least one tier-2/3 step)
 *     alien  c 22-26 (T = 4, or T = 3 with c <= 25)
 * Every pooled puzzle is therefore fully solvable by findNextStep, so hints
 * never run dry.
 */

import {
  ALL,
  UNITS,
  ROWS,
  COLS,
  BOXES,
  PEERS,
  rowOf,
  colOf,
  boxOf,
  computeCandidates,
  popcount,
  maskToValues,
  isConsistent,
} from './sudoku.js';

const BIT = (v) => 1 << (v - 1);

/** Technique metadata in search order (simplest first). `weight` feeds the grade score. */
export const TECHNIQUES = {
  'full-house': { tier: 1, label: 'Full House', weight: 1 },
  'hidden-single': { tier: 1, label: 'Hidden Single', weight: 1 },
  'naked-single': { tier: 1, label: 'Naked Single', weight: 3 },
  'locked-candidates-pointing': { tier: 2, label: 'Pointing', weight: 8 },
  'locked-candidates-claiming': { tier: 2, label: 'Claiming', weight: 9 },
  'naked-pair': { tier: 3, label: 'Naked Pair', weight: 14 },
  'hidden-pair': { tier: 3, label: 'Hidden Pair', weight: 18 },
  'naked-triple': { tier: 3, label: 'Naked Triple', weight: 22 },
  'hidden-triple': { tier: 3, label: 'Hidden Triple', weight: 26 },
  'x-wing': { tier: 4, label: 'X-Wing', weight: 32 },
  swordfish: { tier: 4, label: 'Swordfish', weight: 42 },
  'xy-wing': { tier: 4, label: 'XY-Wing', weight: 38 },
  'naked-quad': { tier: 4, label: 'Naked Quad', weight: 44 },
  'hidden-quad': { tier: 4, label: 'Hidden Quad', weight: 50 },
};

// Unit scan order: boxes, rows, columns (indices into UNITS).
const UNIT_ORDER = [];
for (let b = 0; b < 9; b++) UNIT_ORDER.push(18 + b);
for (let r = 0; r < 9; r++) UNIT_ORDER.push(r);
for (let c = 0; c < 9; c++) UNIT_ORDER.push(9 + c);

const LINE_UNITS = [];
for (let u = 0; u < 18; u++) LINE_UNITS.push(u);

function unitRef(u) {
  if (u < 9) return { type: 'row', index: u };
  if (u < 18) return { type: 'col', index: u - 9 };
  return { type: 'box', index: u - 18 };
}

const IS_PEER = [];
for (let i = 0; i < 81; i++) {
  const a = new Uint8Array(81);
  for (const p of PEERS[i]) a[p] = 1;
  IS_PEER.push(a);
}

function makeStep(technique, fields) {
  return {
    technique,
    tier: TECHNIQUES[technique].tier,
    placement: null,
    eliminations: [],
    cells: [],
    unit: null,
    value: null,
    ...fields,
  };
}

/** All k-element combinations of arr (arr is small: at most 9 items). */
function combinations(arr, k) {
  const out = [];
  const cur = [];
  (function rec(start) {
    if (cur.length === k) {
      out.push(cur.slice());
      return;
    }
    for (let i = start; i <= arr.length - (k - cur.length); i++) {
      cur.push(arr[i]);
      rec(i + 1);
      cur.pop();
    }
  })(0);
  return out;
}

// ---------------------------------------------------------------- tier 1

function findFullHouse(grid, cand) {
  for (const u of UNIT_ORDER) {
    const unit = UNITS[u];
    let empty = -1;
    let emptyCount = 0;
    let used = 0;
    for (const i of unit) {
      if (grid[i]) used |= BIT(grid[i]);
      else {
        empty = i;
        emptyCount++;
      }
    }
    if (emptyCount !== 1) continue;
    const missing = ALL & ~used;
    if (popcount(missing) !== 1 || !(cand[empty] & missing)) continue;
    const value = maskToValues(missing)[0];
    return makeStep('full-house', {
      placement: { idx: empty, value },
      cells: [empty],
      unit: unitRef(u),
      value,
    });
  }
  return null;
}

function findHiddenSingle(grid, cand) {
  for (const u of UNIT_ORDER) {
    const unit = UNITS[u];
    let used = 0;
    for (const i of unit) if (grid[i]) used |= BIT(grid[i]);
    for (let v = 1; v <= 9; v++) {
      const bit = BIT(v);
      if (used & bit) continue;
      let pos = -1;
      let n = 0;
      for (const i of unit) {
        if (cand[i] & bit) {
          pos = i;
          if (++n > 1) break;
        }
      }
      if (n === 1) {
        return makeStep('hidden-single', {
          placement: { idx: pos, value: v },
          cells: [pos],
          unit: unitRef(u),
          value: v,
        });
      }
    }
  }
  return null;
}

function findNakedSingle(grid, cand) {
  for (let i = 0; i < 81; i++) {
    if (!grid[i] && popcount(cand[i]) === 1) {
      const value = maskToValues(cand[i])[0];
      return makeStep('naked-single', { placement: { idx: i, value }, cells: [i], value });
    }
  }
  return null;
}

// ---------------------------------------------------------------- tier 2

function findPointing(grid, cand) {
  for (let b = 0; b < 9; b++) {
    const box = BOXES[b];
    for (let v = 1; v <= 9; v++) {
      const bit = BIT(v);
      const cells = box.filter((i) => cand[i] & bit);
      if (cells.length < 2) continue;
      for (const [lineOf, lines, offset] of [
        [rowOf, ROWS, 0],
        [colOf, COLS, 9],
      ]) {
        const line = lineOf(cells[0]);
        if (!cells.every((i) => lineOf(i) === line)) continue;
        const eliminations = [];
        for (const i of lines[line]) {
          if (boxOf(i) !== b && cand[i] & bit) eliminations.push({ idx: i, value: v });
        }
        if (eliminations.length) {
          return makeStep('locked-candidates-pointing', {
            eliminations,
            cells,
            unit: { type: 'box', index: b },
            targetUnit: unitRef(offset + line),
            value: v,
          });
        }
      }
    }
  }
  return null;
}

function findClaiming(grid, cand) {
  for (const u of LINE_UNITS) {
    const unit = UNITS[u];
    for (let v = 1; v <= 9; v++) {
      const bit = BIT(v);
      const cells = unit.filter((i) => cand[i] & bit);
      if (cells.length < 2) continue;
      const b = boxOf(cells[0]);
      if (!cells.every((i) => boxOf(i) === b)) continue;
      const eliminations = [];
      for (const i of BOXES[b]) {
        if (!unit.includes(i) && cand[i] & bit) eliminations.push({ idx: i, value: v });
      }
      if (eliminations.length) {
        return makeStep('locked-candidates-claiming', {
          eliminations,
          cells,
          unit: unitRef(u),
          targetUnit: { type: 'box', index: b },
          value: v,
        });
      }
    }
  }
  return null;
}

// ------------------------------------------------------------ subsets (3/4)

const NAKED_NAMES = { 2: 'naked-pair', 3: 'naked-triple', 4: 'naked-quad' };
const HIDDEN_NAMES = { 2: 'hidden-pair', 3: 'hidden-triple', 4: 'hidden-quad' };

function findNakedSubset(grid, cand, k) {
  for (const u of UNIT_ORDER) {
    const unit = UNITS[u];
    const empties = unit.filter((i) => !grid[i]);
    if (empties.length <= k) continue;
    const pool = empties.filter((i) => popcount(cand[i]) >= 2 && popcount(cand[i]) <= k);
    if (pool.length < k) continue;
    for (const combo of combinations(pool, k)) {
      let union = 0;
      for (const i of combo) union |= cand[i];
      if (popcount(union) !== k) continue;
      const eliminations = [];
      for (const i of empties) {
        if (combo.includes(i)) continue;
        const hit = cand[i] & union;
        if (hit) for (const v of maskToValues(hit)) eliminations.push({ idx: i, value: v });
      }
      if (eliminations.length) {
        return makeStep(NAKED_NAMES[k], {
          eliminations,
          cells: combo,
          unit: unitRef(u),
          values: maskToValues(union),
        });
      }
    }
  }
  return null;
}

function findHiddenSubset(grid, cand, k) {
  for (const u of UNIT_ORDER) {
    const unit = UNITS[u];
    let used = 0;
    let emptyCount = 0;
    for (const i of unit) {
      if (grid[i]) used |= BIT(grid[i]);
      else emptyCount++;
    }
    if (emptyCount <= k) continue;
    // posMask[v]: 9-bit mask of positions (0..8 within the unit) where v is a candidate.
    const digits = [];
    const posMask = new Array(10).fill(0);
    for (let v = 1; v <= 9; v++) {
      if (used & BIT(v)) continue;
      let m = 0;
      for (let p = 0; p < 9; p++) if (cand[unit[p]] & BIT(v)) m |= 1 << p;
      posMask[v] = m;
      const n = popcount(m);
      if (n >= 2 && n <= k) digits.push(v);
    }
    if (digits.length < k) continue;
    for (const combo of combinations(digits, k)) {
      let union = 0;
      let subsetMask = 0;
      for (const v of combo) {
        union |= posMask[v];
        subsetMask |= BIT(v);
      }
      if (popcount(union) !== k) continue;
      const cells = [];
      const eliminations = [];
      for (let p = 0; p < 9; p++) {
        if (!(union & (1 << p))) continue;
        const i = unit[p];
        cells.push(i);
        const extra = cand[i] & ~subsetMask;
        if (extra) for (const v of maskToValues(extra)) eliminations.push({ idx: i, value: v });
      }
      if (eliminations.length) {
        return makeStep(HIDDEN_NAMES[k], {
          eliminations,
          cells,
          unit: unitRef(u),
          values: combo.slice(),
        });
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------- tier 4

const FISH_NAMES = { 2: 'x-wing', 3: 'swordfish' };

function findFish(grid, cand, n) {
  for (let v = 1; v <= 9; v++) {
    const bit = BIT(v);
    for (const baseIsRow of [true, false]) {
      // lineMask[l]: mask over the cross index (cols for row-based fish).
      const lines = [];
      const lineMask = new Array(9).fill(0);
      for (let l = 0; l < 9; l++) {
        let m = 0;
        for (let x = 0; x < 9; x++) {
          const i = baseIsRow ? l * 9 + x : x * 9 + l;
          if (cand[i] & bit) m |= 1 << x;
        }
        lineMask[l] = m;
        const pc = popcount(m);
        if (pc >= 2 && pc <= n) lines.push(l);
      }
      if (lines.length < n) continue;
      for (const combo of combinations(lines, n)) {
        let cover = 0;
        for (const l of combo) cover |= lineMask[l];
        if (popcount(cover) !== n) continue;
        const coverLines = [];
        for (let x = 0; x < 9; x++) if (cover & (1 << x)) coverLines.push(x);
        const eliminations = [];
        for (const x of coverLines) {
          for (let l = 0; l < 9; l++) {
            if (combo.includes(l)) continue;
            const i = baseIsRow ? l * 9 + x : x * 9 + l;
            if (cand[i] & bit) eliminations.push({ idx: i, value: v });
          }
        }
        if (!eliminations.length) continue;
        const cells = [];
        for (const l of combo) {
          for (const x of coverLines) {
            const i = baseIsRow ? l * 9 + x : x * 9 + l;
            if (cand[i] & bit) cells.push(i);
          }
        }
        cells.sort((a, b) => a - b);
        return makeStep(FISH_NAMES[n], {
          eliminations,
          cells,
          value: v,
          baseUnits: combo.map((l) => ({ type: baseIsRow ? 'row' : 'col', index: l })),
          coverUnits: coverLines.map((x) => ({ type: baseIsRow ? 'col' : 'row', index: x })),
        });
      }
    }
  }
  return null;
}

function findXYWing(grid, cand) {
  for (let pivot = 0; pivot < 81; pivot++) {
    const pm = cand[pivot];
    if (grid[pivot] || popcount(pm) !== 2) continue;
    const [x, y] = maskToValues(pm);
    const wings = PEERS[pivot].filter((i) => !grid[i] && popcount(cand[i]) === 2 && popcount(cand[i] & pm) === 1);
    for (const a of wings) {
      if (!(cand[a] & BIT(x))) continue; // a = {x, z}
      const zMask = cand[a] & ~pm;
      for (const b of wings) {
        if (b === a || cand[b] !== (BIT(y) | zMask)) continue; // b = {y, z}
        const z = maskToValues(zMask)[0];
        const eliminations = [];
        for (const i of PEERS[a]) {
          if (i !== b && i !== pivot && IS_PEER[b][i] && cand[i] & zMask) {
            eliminations.push({ idx: i, value: z });
          }
        }
        if (eliminations.length) {
          return makeStep('xy-wing', {
            eliminations,
            cells: [pivot, a, b],
            value: z,
            values: [x, y, z],
          });
        }
      }
    }
  }
  return null;
}

// ----------------------------------------------------------------- driver

const FINDER_BY_NAME = {
  'full-house': findFullHouse,
  'hidden-single': findHiddenSingle,
  'naked-single': findNakedSingle,
  'locked-candidates-pointing': findPointing,
  'locked-candidates-claiming': findClaiming,
  'naked-pair': (g, c) => findNakedSubset(g, c, 2),
  'hidden-pair': (g, c) => findHiddenSubset(g, c, 2),
  'naked-triple': (g, c) => findNakedSubset(g, c, 3),
  'hidden-triple': (g, c) => findHiddenSubset(g, c, 3),
  'x-wing': (g, c) => findFish(g, c, 2),
  swordfish: (g, c) => findFish(g, c, 3),
  'xy-wing': findXYWing,
  'naked-quad': (g, c) => findNakedSubset(g, c, 4),
  'hidden-quad': (g, c) => findHiddenSubset(g, c, 4),
};
// Simplest first: the key order of TECHNIQUES.
const FINDERS = Object.keys(TECHNIQUES).map((name) => FINDER_BY_NAME[name]);
const SINGLE_FINDERS = FINDERS.slice(0, 3);

/** Working candidates: caller's masks (if any) intersected with the grid's basic candidates. */
function workingCandidates(grid, candidates) {
  const basic = computeCandidates(grid);
  if (!candidates) return basic;
  for (let i = 0; i < 81; i++) basic[i] &= candidates[i];
  return basic;
}

function runFinders(finders, grid, cand) {
  for (const f of finders) {
    const step = f(grid, cand);
    if (step) return step;
  }
  return null;
}

/**
 * The simplest applicable logical step, or null if none of the techniques apply
 * (or the grid is already full).
 * @param {number[]} grid 81 ints
 * @param {number[]} [candidates] 81 masks to work from (eliminations carry over);
 *   always intersected with the grid's basic candidates, never mutated.
 */
export function findNextStep(grid, candidates) {
  return runFinders(FINDERS, grid, workingCandidates(grid, candidates));
}

/** Only tier-1 steps (full-house / hidden-single / naked-single). For "explain the next move" hints. */
export function findSingle(grid, candidates) {
  return runFinders(SINGLE_FINDERS, grid, workingCandidates(grid, candidates));
}

/** Look for one specific technique only (e.g. 'x-wing'); null if it does not apply. */
export function findStepByTechnique(technique, grid, candidates) {
  const finder = FINDER_BY_NAME[technique];
  if (!finder) throw new Error(`Unknown technique: ${technique}`);
  return finder(grid, workingCandidates(grid, candidates));
}

/**
 * Apply a step in place: placement sets the cell and removes the value from its
 * peers' candidates; eliminations clear candidate bits.
 */
export function applyStep(grid, candidates, step) {
  if (step.placement) {
    const { idx, value } = step.placement;
    grid[idx] = value;
    candidates[idx] = 0;
    const bit = BIT(value);
    for (const p of PEERS[idx]) candidates[p] &= ~bit;
  }
  for (const { idx, value } of step.eliminations) candidates[idx] &= ~BIT(value);
}

/**
 * Grade a puzzle by solving it with findNextStep on a working copy.
 * @returns {{ solved: boolean, difficulty: 'easy'|'medium'|'hard'|'alien'|null, maxTier: number,
 *   score: number, steps: number, clues: number, techniques: Record<string, number>, easyRatio: number }}
 *   easyRatio = share of steps that are full houses or hidden singles in boxes.
 */
export function gradePuzzle(grid) {
  const g = Array.from(grid, (v) => v | 0);
  let clues = 0;
  for (let i = 0; i < 81; i++) if (g[i]) clues++;
  const cand = computeCandidates(g);
  const techniques = {};
  let maxTier = 0;
  let score = 0;
  let steps = 0;
  let easySteps = 0;
  let empties = 81 - clues;
  const consistent = isConsistent(g);
  while (consistent && empties > 0) {
    const step = runFinders(FINDERS, g, cand);
    if (!step) break;
    applyStep(g, cand, step);
    if (step.placement) empties--;
    steps++;
    techniques[step.technique] = (techniques[step.technique] || 0) + 1;
    score += TECHNIQUES[step.technique].weight;
    if (step.tier > maxTier) maxTier = step.tier;
    if (step.technique === 'full-house' || (step.technique === 'hidden-single' && step.unit.type === 'box')) {
      easySteps++;
    }
  }
  const solved = consistent && empties === 0 && isConsistent(g);
  return {
    solved,
    difficulty: solved ? classify(maxTier, clues, !techniques['naked-single']) : null,
    maxTier,
    score,
    steps,
    clues,
    techniques,
    easyRatio: steps ? easySteps / steps : 1,
  };
}

/** Difficulty band from max tier and clue count (see rules at the top of this file). */
function classify(maxTier, clues, noNakedSingles) {
  if (maxTier >= 4) return 'alien';
  if (maxTier === 3) return clues <= 25 ? 'alien' : 'hard';
  if (maxTier === 2) return clues <= 29 ? 'hard' : 'medium';
  return noNakedSingles && clues >= 36 ? 'easy' : 'medium';
}

/**
 * Pool acceptance test used by the generator: the difficulty band this puzzle
 * may be pooled under, or null. `grade` is a gradePuzzle() result.
 */
export function poolBand(grade) {
  if (!grade.solved) return null;
  const { difficulty, clues, maxTier } = grade;
  if (difficulty === 'easy') return clues <= 40 && grade.easyRatio >= 0.75 ? 'easy' : null;
  if (difficulty === 'medium') {
    if (clues < 30 || clues > 34) return null;
    return maxTier === 2 || clues <= 32 ? 'medium' : null;
  }
  if (difficulty === 'hard') return clues >= 25 && clues <= 29 ? 'hard' : null;
  if (difficulty === 'alien') return clues >= 22 && clues <= 26 ? 'alien' : null;
  return null;
}

// ------------------------------------------------------------ explanations

const cellName = (i) => `r${rowOf(i) + 1}c${colOf(i) + 1}`;
const UNIT_WORD = { row: 'row', col: 'column', box: 'box' };
const unitName = (u) => `${UNIT_WORD[u.type]} ${u.index + 1}`;
const list = (items) =>
  items.length <= 1 ? items.join('') : `${items.slice(0, -1).join(', ')} and ${items[items.length - 1]}`;

/**
 * Plain-English explanation of a step. `fmt` renders a value (e.g. as a glyph name).
 * Cells are written r{row}c{col}, units 1-based ("row 3", "column 5", "box 9").
 */
export function describeStep(step, fmt = (v) => String(v)) {
  if (!step) return '';
  const v = step.value != null ? fmt(step.value) : '';
  const vals = (step.values || []).map(fmt);
  const cells = list(step.cells.map(cellName));
  switch (step.technique) {
    case 'full-house':
      return `${cellName(step.placement.idx)} is the last empty cell in ${unitName(step.unit)}, so it must be ${v}.`;
    case 'hidden-single':
      return `In ${unitName(step.unit)}, ${v} fits in only one cell: ${cellName(step.placement.idx)}.`;
    case 'naked-single':
      return `${cellName(step.placement.idx)} sees every other value, so only ${v} fits there.`;
    case 'locked-candidates-pointing':
      return `In ${unitName(step.unit)}, ${v} can only go in ${unitName(step.targetUnit)}, so ${v} can be removed from the rest of ${unitName(step.targetUnit)}.`;
    case 'locked-candidates-claiming':
      return `In ${unitName(step.unit)}, ${v} can only go inside ${unitName(step.targetUnit)}, so ${v} can be removed from the rest of ${unitName(step.targetUnit)}.`;
    case 'naked-pair':
    case 'naked-triple':
    case 'naked-quad':
      return `${cells} in ${unitName(step.unit)} can only hold ${list(vals)}, so those values can be removed from the other cells of ${unitName(step.unit)}.`;
    case 'hidden-pair':
    case 'hidden-triple':
    case 'hidden-quad':
      return `In ${unitName(step.unit)}, ${list(vals)} can only go in ${cells}, so all other candidates can be removed from those cells.`;
    case 'x-wing':
    case 'swordfish': {
      const base = step.baseUnits[0].type === 'row' ? 'rows' : 'columns';
      const cover = step.coverUnits[0].type === 'row' ? 'rows' : 'columns';
      const b = list(step.baseUnits.map((u) => String(u.index + 1)));
      const c = list(step.coverUnits.map((u) => String(u.index + 1)));
      return `In ${base} ${b}, ${v} can only go in ${cover} ${c}, so ${v} can be removed from the rest of ${cover} ${c}.`;
    }
    case 'xy-wing': {
      const [pivot, a, b] = step.cells;
      const [x, y, z] = vals;
      return `${cellName(pivot)} is ${x} or ${y}. If ${x}, ${cellName(a)} is ${z}; if ${y}, ${cellName(b)} is ${z}. Either way, cells seeing both ${cellName(a)} and ${cellName(b)} cannot be ${z}.`;
    }
    default:
      return TECHNIQUES[step.technique] ? TECHNIQUES[step.technique].label : step.technique;
  }
}
