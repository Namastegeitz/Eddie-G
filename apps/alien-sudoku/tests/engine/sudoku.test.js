import { describe, it, expect } from 'vitest';
import {
  ROWS,
  COLS,
  BOXES,
  UNITS,
  PEERS,
  rowOf,
  colOf,
  boxOf,
  parseGrid,
  gridToString,
  isValidPlacement,
  solve,
  countSolutions,
  computeCandidates,
  maskToValues,
  popcount,
  generateSolved,
  generatePuzzle,
  isSolved,
} from '../../src/engine/sudoku.js';
import { createRng } from '../../src/engine/rng.js';
import { INKALA, INKALA_SOLUTION, ESCARGOT, ESCARGOT_SOLUTION, SEVENTEEN, EULER_1, TWO_SOLUTIONS } from './fixtures.js';

const matchesGivens = (puzzle, solution) => puzzle.every((v, i) => !v || v === solution[i]);

describe('geometry', () => {
  it('units and peers', () => {
    expect(ROWS[2]).toEqual([18, 19, 20, 21, 22, 23, 24, 25, 26]);
    expect(COLS[1]).toEqual([1, 10, 19, 28, 37, 46, 55, 64, 73]);
    expect(BOXES[4]).toEqual([30, 31, 32, 39, 40, 41, 48, 49, 50]);
    expect(UNITS).toHaveLength(27);
    expect(PEERS).toHaveLength(81);
    for (let i = 0; i < 81; i++) {
      expect(PEERS[i]).toHaveLength(20);
      expect(PEERS[i]).not.toContain(i);
    }
    expect([rowOf(50), colOf(50), boxOf(50)]).toEqual([5, 5, 4]);
    expect(boxOf(80)).toBe(8);
  });
});

describe('parse / serialize', () => {
  it('accepts 0 and . for empty and round-trips with 0', () => {
    const g = parseGrid(SEVENTEEN);
    expect(g).toHaveLength(81);
    expect(g.filter(Boolean)).toHaveLength(17);
    expect(gridToString(g)).toBe(SEVENTEEN.replace(/\./g, '0'));
    expect(parseGrid(gridToString(g))).toEqual(g);
  });

  it('rejects bad input', () => {
    expect(() => parseGrid('123')).toThrow();
    expect(() => parseGrid('x'.repeat(81))).toThrow();
  });
});

describe('isValidPlacement', () => {
  it('checks row, column and box peers', () => {
    const g = parseGrid(INKALA);
    expect(isValidPlacement(g, 1, 8)).toBe(false); // row has 8
    expect(isValidPlacement(g, 9, 8)).toBe(false); // column has 8
    expect(isValidPlacement(g, 10, 3)).toBe(false); // box has 3 (r2c3)
    expect(isValidPlacement(g, 1, 1)).toBe(true);
    expect(isValidPlacement(g, 1, 0)).toBe(false);
  });
});

describe('solve / countSolutions', () => {
  it('solves known hard puzzles', () => {
    expect(gridToString(solve(parseGrid(INKALA)))).toBe(INKALA_SOLUTION);
    expect(gridToString(solve(parseGrid(ESCARGOT)))).toBe(ESCARGOT_SOLUTION);
    const s17 = solve(parseGrid(SEVENTEEN));
    expect(isSolved(s17)).toBe(true);
    expect(matchesGivens(parseGrid(SEVENTEEN), s17)).toBe(true);
  });

  it('counts unique, multiple and zero solutions', () => {
    expect(countSolutions(parseGrid(INKALA))).toBe(1);
    expect(countSolutions(parseGrid(ESCARGOT))).toBe(1);
    expect(countSolutions(parseGrid(EULER_1))).toBe(1);
    expect(countSolutions(parseGrid(TWO_SOLUTIONS))).toBe(2);
    expect(countSolutions(parseGrid(TWO_SOLUTIONS), 10)).toBe(2);
    expect(countSolutions(new Array(81).fill(0), 5)).toBe(5);
    // Conflicting givens: two 8s in row 1.
    const bad = parseGrid(INKALA);
    bad[1] = 8;
    expect(countSolutions(bad)).toBe(0);
    expect(solve(bad)).toBeNull();
  });

  it('is fast on hard puzzles', () => {
    const g = parseGrid(INKALA);
    solve(g);
    const t = performance.now();
    for (let i = 0; i < 20; i++) countSolutions(g);
    expect((performance.now() - t) / 20).toBeLessThan(20);
  });
});

describe('computeCandidates / masks', () => {
  it('computes basic candidates', () => {
    const g = parseGrid(INKALA);
    const c = computeCandidates(g);
    expect(c[0]).toBe(0); // filled
    // r1c2: row {8}, col {7,5,9}, box {8,3,7} -> {1,2,4,6}
    expect(maskToValues(c[1])).toEqual([1, 2, 4, 6]);
    const sol = parseGrid(INKALA_SOLUTION);
    for (let i = 0; i < 81; i++) {
      if (!g[i]) expect(c[i] & (1 << (sol[i] - 1))).not.toBe(0);
    }
  });

  it('maskToValues and popcount', () => {
    expect(maskToValues(0)).toEqual([]);
    expect(maskToValues(0x1ff)).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(maskToValues(0b100000101)).toEqual([1, 3, 9]);
    expect(popcount(0)).toBe(0);
    expect(popcount(0x1ff)).toBe(9);
    expect(popcount(0b1010)).toBe(2);
  });
});

describe('generation', () => {
  it('generateSolved gives valid, seed-deterministic grids', () => {
    const a = generateSolved(createRng(5));
    expect(isSolved(a)).toBe(true);
    expect(generateSolved(createRng(5))).toEqual(a);
    expect(generateSolved(createRng(6))).not.toEqual(a);
  });

  it('generatePuzzle carves unique, symmetric puzzles', () => {
    const rng = createRng('gen-test');
    for (let k = 0; k < 10; k++) {
      const { puzzle, solution } = generatePuzzle(rng, { targetClues: 30 });
      expect(countSolutions(puzzle)).toBe(1);
      expect(isSolved(solution)).toBe(true);
      expect(matchesGivens(puzzle, solution)).toBe(true);
      expect(puzzle.filter(Boolean).length).toBeLessThanOrEqual(36);
      for (let i = 0; i < 81; i++) expect(Boolean(puzzle[i])).toBe(Boolean(puzzle[80 - i]));
    }
    const free = generatePuzzle(rng, { targetClues: 26, symmetric: false });
    expect(countSolutions(free.puzzle)).toBe(1);
    expect(free.puzzle.filter(Boolean).length).toBeLessThanOrEqual(30);
  });
});
