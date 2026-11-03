import { describe, it, expect } from 'vitest';
import { parseGrid, computeCandidates, solve, ALL } from '../../src/engine/sudoku.js';
import {
  findNextStep,
  findSingle,
  findStepByTechnique,
  applyStep,
  gradePuzzle,
  poolBand,
  describeStep,
  TECHNIQUES,
} from '../../src/engine/logic.js';
import { INKALA_SOLUTION, ESCARGOT, EULER_1, TECHNIQUE_PUZZLES } from './fixtures.js';

const B = (v) => 1 << (v - 1);
const idx = (r, c) => r * 9 + c;
const emptyGrid = () => new Array(81).fill(0);
const fullCands = () => new Array(81).fill(ALL);
const elimSet = (step) => new Set(step.eliminations.map((e) => `${e.idx}:${e.value}`));

/** Run the logic solver, asserting every step agrees with the true solution. Returns the steps. */
function logicSolve(puzzleStr) {
  const grid = parseGrid(puzzleStr);
  const solution = solve(grid);
  const cand = computeCandidates(grid);
  const steps = [];
  for (;;) {
    const step = findNextStep(grid, cand);
    if (!step) break;
    if (step.placement) expect(step.placement.value).toBe(solution[step.placement.idx]);
    for (const e of step.eliminations) expect(e.value).not.toBe(solution[e.idx]);
    expect(step.tier).toBe(TECHNIQUES[step.technique].tier);
    applyStep(grid, cand, step);
    steps.push(step);
  }
  return { steps, grid, solution };
}

describe('tier 1: singles', () => {
  it('full house is preferred when one cell is missing', () => {
    const grid = parseGrid(INKALA_SOLUTION);
    grid[40] = 0;
    const step = findNextStep(grid);
    expect(step.technique).toBe('full-house');
    expect(step.placement).toEqual({ idx: 40, value: 4 });
    expect(step.unit).toEqual({ type: 'box', index: 4 });
    expect(step.eliminations).toEqual([]);
  });

  it('hidden single in a box', () => {
    // 1s at r2c5, r3c8, r5c2, r8c3 (1-based) leave r1c1 as the only spot for 1 in box 1.
    const grid = emptyGrid();
    grid[idx(1, 4)] = 1;
    grid[idx(2, 7)] = 1;
    grid[idx(4, 1)] = 1;
    grid[idx(7, 2)] = 1;
    const step = findNextStep(grid);
    expect(step).toMatchObject({
      technique: 'hidden-single',
      tier: 1,
      placement: { idx: 0, value: 1 },
      unit: { type: 'box', index: 0 },
      value: 1,
      cells: [0],
    });
    expect(findSingle(grid)).toEqual(step);
  });

  it('naked single', () => {
    const grid = emptyGrid();
    [1, 2, 3].forEach((v, c) => (grid[idx(4, c)] = v)); // row 5: 1 2 3
    [4, 5, 6].forEach((v, r) => (grid[idx(r, 4)] = v)); // column 5: 4 5 6
    grid[idx(3, 3)] = 7;
    grid[idx(5, 5)] = 8;
    const step = findStepByTechnique('naked-single', grid);
    expect(step).toMatchObject({ technique: 'naked-single', placement: { idx: 40, value: 9 }, unit: null });
  });

  it('findSingle returns null when only harder techniques apply', () => {
    const cand = fullCands();
    for (const r of [1, 2]) for (const c of [0, 1, 2]) cand[idx(r, c)] &= ~B(5);
    expect(findSingle(emptyGrid(), cand)).toBeNull();
    expect(findNextStep(emptyGrid(), cand).technique).toBe('locked-candidates-pointing');
  });
});

describe('tier 2: locked candidates', () => {
  it('pointing: 5 confined to row 1 inside box 1', () => {
    const cand = fullCands();
    for (let r = 1; r < 3; r++) for (let c = 0; c < 3; c++) cand[idx(r, c)] &= ~B(5);
    const step = findNextStep(emptyGrid(), cand);
    expect(step).toMatchObject({
      technique: 'locked-candidates-pointing',
      tier: 2,
      placement: null,
      cells: [0, 1, 2],
      unit: { type: 'box', index: 0 },
      targetUnit: { type: 'row', index: 0 },
      value: 5,
    });
    expect(elimSet(step)).toEqual(new Set([3, 4, 5, 6, 7, 8].map((c) => `${c}:5`)));
  });

  it('claiming: 5 in row 1 confined to box 1', () => {
    const cand = fullCands();
    for (let c = 3; c < 9; c++) cand[idx(0, c)] &= ~B(5);
    const step = findNextStep(emptyGrid(), cand);
    expect(step).toMatchObject({
      technique: 'locked-candidates-claiming',
      unit: { type: 'row', index: 0 },
      targetUnit: { type: 'box', index: 0 },
      value: 5,
    });
    expect(elimSet(step)).toEqual(new Set([9, 10, 11, 18, 19, 20].map((i) => `${i}:5`)));
  });

  it('does not mutate the candidates passed in', () => {
    const cand = fullCands();
    for (let c = 3; c < 9; c++) cand[idx(0, c)] &= ~B(5);
    const copy = cand.slice();
    findNextStep(emptyGrid(), cand);
    expect(cand).toEqual(copy);
  });
});

describe('tier 3: subsets', () => {
  it('naked pair in a row', () => {
    const cand = fullCands();
    cand[idx(0, 0)] = B(1) | B(2);
    cand[idx(0, 4)] = B(1) | B(2);
    const step = findNextStep(emptyGrid(), cand);
    expect(step).toMatchObject({
      technique: 'naked-pair',
      tier: 3,
      cells: [0, 4],
      unit: { type: 'row', index: 0 },
      values: [1, 2],
    });
    const expected = [];
    for (const c of [1, 2, 3, 5, 6, 7, 8]) expected.push(`${c}:1`, `${c}:2`);
    expect(elimSet(step)).toEqual(new Set(expected));
  });

  it('hidden pair in a row', () => {
    const cand = fullCands();
    for (let c = 0; c < 9; c++) if (c !== 0 && c !== 4) cand[idx(0, c)] &= ~(B(1) | B(2));
    const step = findNextStep(emptyGrid(), cand);
    expect(step).toMatchObject({ technique: 'hidden-pair', cells: [0, 4], values: [1, 2] });
    const expected = [];
    for (const i of [0, 4]) for (let v = 3; v <= 9; v++) expected.push(`${i}:${v}`);
    expect(elimSet(step)).toEqual(new Set(expected));
  });
});

describe('tier 4: fish and wings', () => {
  it('x-wing on 5 in rows 2 and 6, columns 3 and 7', () => {
    const cand = fullCands();
    for (const r of [1, 5]) for (let c = 0; c < 9; c++) if (c !== 2 && c !== 6) cand[idx(r, c)] &= ~B(5);
    const step = findNextStep(emptyGrid(), cand);
    expect(step).toMatchObject({
      technique: 'x-wing',
      tier: 4,
      value: 5,
      cells: [idx(1, 2), idx(1, 6), idx(5, 2), idx(5, 6)],
      baseUnits: [
        { type: 'row', index: 1 },
        { type: 'row', index: 5 },
      ],
      coverUnits: [
        { type: 'col', index: 2 },
        { type: 'col', index: 6 },
      ],
    });
    const expected = [];
    for (let r = 0; r < 9; r++) if (r !== 1 && r !== 5) expected.push(`${idx(r, 2)}:5`, `${idx(r, 6)}:5`);
    expect(elimSet(step)).toEqual(new Set(expected));
  });

  it('swordfish on 7 in rows 1, 5, 9', () => {
    const cand = fullCands();
    const allowed = { 0: [1, 4], 4: [4, 7], 8: [1, 7] };
    for (const [r, cols] of Object.entries(allowed)) {
      for (let c = 0; c < 9; c++) if (!cols.includes(c)) cand[idx(Number(r), c)] &= ~B(7);
    }
    expect(findStepByTechnique('x-wing', emptyGrid(), cand)).toBeNull();
    const step = findStepByTechnique('swordfish', emptyGrid(), cand);
    expect(step).toMatchObject({ technique: 'swordfish', value: 7 });
    expect(step.eliminations).toHaveLength(18);
    for (const e of step.eliminations) {
      expect([1, 4, 7]).toContain(e.idx % 9);
      expect([0, 4, 8]).not.toContain(Math.floor(e.idx / 9));
    }
    expect(findNextStep(emptyGrid(), cand).technique).toBe('swordfish');
  });

  it('xy-wing', () => {
    const cand = fullCands();
    cand[idx(0, 0)] = B(1) | B(2); // pivot
    cand[idx(0, 5)] = B(1) | B(3); // pincer x/z
    cand[idx(5, 0)] = B(2) | B(3); // pincer y/z
    const step = findStepByTechnique('xy-wing', emptyGrid(), cand);
    expect(step).toMatchObject({
      technique: 'xy-wing',
      cells: [idx(0, 0), idx(0, 5), idx(5, 0)],
      value: 3,
      values: [1, 2, 3],
      eliminations: [{ idx: idx(5, 5), value: 3 }],
    });
  });
});

describe('logical solves of known puzzles', () => {
  for (const [technique, puzzle] of Object.entries(TECHNIQUE_PUZZLES)) {
    it(`${technique}: every step is sound and the technique is used`, () => {
      const { steps, grid, solution } = logicSolve(puzzle);
      expect(grid).toEqual(solution);
      expect(steps.some((s) => s.technique === technique)).toBe(true);
      for (const s of steps) expect(describeStep(s).length).toBeGreaterThan(10);
    });
  }
});

describe('gradePuzzle', () => {
  it('grades a singles-only puzzle', () => {
    const g = gradePuzzle(parseGrid(EULER_1));
    expect(g.solved).toBe(true);
    expect(g.maxTier).toBe(1);
    expect(g.clues).toBe(32);
    expect(g.difficulty).toBe('medium');
    expect(g.steps).toBe(49);
    expect(g.score).toBeGreaterThan(0);
  });

  it('grades technique puzzles into the expected bands', () => {
    const cases = {
      'locked-candidates-pointing': ['medium', 2],
      'naked-pair': ['hard', 3],
      'x-wing': ['alien', 4],
    };
    for (const [technique, [difficulty, tier]] of Object.entries(cases)) {
      const g = gradePuzzle(parseGrid(TECHNIQUE_PUZZLES[technique]));
      expect(g).toMatchObject({ solved: true, difficulty, maxTier: tier });
      expect(g.techniques[technique]).toBeGreaterThan(0);
      expect(poolBand(g)).toBe(difficulty);
    }
  });

  it('reports puzzles beyond the technique set as unsolved', () => {
    const g = gradePuzzle(parseGrid(ESCARGOT));
    expect(g.solved).toBe(false);
    expect(g.difficulty).toBeNull();
    expect(poolBand(g)).toBeNull();
  });
});

describe('describeStep', () => {
  it('uses the value formatter', () => {
    const grid = parseGrid(INKALA_SOLUTION);
    grid[40] = 0;
    const text = describeStep(findNextStep(grid), (v) => `glyph-${v}`);
    expect(text).toContain('glyph-4');
    expect(text).toContain('r5c5');
    expect(text).toContain('box 5');
  });
});
