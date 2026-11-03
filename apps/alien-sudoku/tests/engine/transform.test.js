import { describe, it, expect } from 'vitest';
import { randomTransform, applyTransform, identityTransform } from '../../src/engine/transform.js';
import { parseGrid, countSolutions, isSolved, solve, ROWS, COLS, BOXES } from '../../src/engine/sudoku.js';
import { gradePuzzle } from '../../src/engine/logic.js';
import { createRng } from '../../src/engine/rng.js';
import { INKALA, INKALA_SOLUTION, TECHNIQUE_PUZZLES, TWO_SOLUTIONS } from './fixtures.js';

const isPerm = (arr, values) => [...arr].sort((a, b) => a - b).join() === values.join();

describe('randomTransform', () => {
  it('produces JSON-serializable, structurally valid descriptors', () => {
    const rng = createRng('t');
    for (let k = 0; k < 100; k++) {
      const t = randomTransform(rng);
      expect(JSON.parse(JSON.stringify(t))).toEqual(t);
      expect(isPerm(t.digits, [1, 2, 3, 4, 5, 6, 7, 8, 9])).toBe(true);
      for (const p of [t.rows, t.cols]) {
        expect(isPerm(p, [0, 1, 2, 3, 4, 5, 6, 7, 8])).toBe(true);
        // Bands/stacks stay together.
        for (let b = 0; b < 3; b++) {
          const band = new Set(p.slice(b * 3, b * 3 + 3).map((x) => Math.floor(x / 3)));
          expect(band.size).toBe(1);
        }
      }
      expect(typeof t.transpose).toBe('boolean');
    }
  });

  it('is deterministic per seed', () => {
    expect(randomTransform(createRng(99))).toEqual(randomTransform(createRng(99)));
  });
});

describe('applyTransform', () => {
  it('identity is a no-op and the input is not mutated', () => {
    const g = parseGrid(INKALA);
    const copy = g.slice();
    expect(applyTransform(g, identityTransform())).toEqual(g);
    applyTransform(g, randomTransform(createRng(1)));
    expect(g).toEqual(copy);
  });

  it('transpose and relabel behave as described', () => {
    const g = parseGrid(INKALA_SOLUTION);
    const t = { ...identityTransform(), transpose: true };
    const out = applyTransform(g, t);
    for (let r = 0; r < 9; r++) for (let c = 0; c < 9; c++) expect(out[r * 9 + c]).toBe(g[c * 9 + r]);
    const relabel = { ...identityTransform(), digits: [2, 3, 4, 5, 6, 7, 8, 9, 1] };
    expect(applyTransform([1, 9, 0], relabel).slice(0, 3)).toEqual([2, 1, 0]);
  });

  it('preserves validity, uniqueness and difficulty over many random transforms', () => {
    const rng = createRng('preserve');
    const sol = parseGrid(INKALA_SOLUTION);
    const puzzles = [INKALA, ...Object.values(TECHNIQUE_PUZZLES)].map(parseGrid);
    const grades = puzzles.map(gradePuzzle);
    for (let k = 0; k < 300; k++) {
      const t = randomTransform(rng);
      const s2 = applyTransform(sol, t);
      expect(isSolved(s2)).toBe(true);
      for (const unit of [...ROWS, ...COLS, ...BOXES]) expect(new Set(unit.map((i) => s2[i])).size).toBe(9);
      const which = k % puzzles.length;
      const p2 = applyTransform(puzzles[which], t);
      expect(countSolutions(p2)).toBe(1);
      expect(solve(p2)).toEqual(applyTransform(solve(puzzles[which]), t));
      if (k < 120) {
        const g2 = gradePuzzle(p2);
        expect(g2.difficulty).toBe(grades[which].difficulty);
        expect(g2.maxTier).toBe(grades[which].maxTier);
        expect(g2.clues).toBe(grades[which].clues);
      }
    }
    // Non-unique stays non-unique.
    expect(countSolutions(applyTransform(parseGrid(TWO_SOLUTIONS), randomTransform(rng)))).toBe(2);
  });
});
