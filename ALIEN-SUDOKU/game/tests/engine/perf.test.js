import { describe, it, expect } from 'vitest';
import { getPuzzle } from '../../src/engine/pool.js';
import { findNextStep } from '../../src/engine/logic.js';

describe('performance', () => {
  it('200 getPuzzle() calls take < 1.5 s', () => {
    const t = performance.now();
    for (let k = 0; k < 200; k++) {
      const difficulty = ['easy', 'medium', 'hard', 'alien'][k % 4];
      getPuzzle({ difficulty, seed: `perf:${k}` });
    }
    expect(performance.now() - t).toBeLessThan(1500);
  });

  it('findNextStep on a fresh hard puzzle averages < 20 ms', () => {
    const puzzles = Array.from({ length: 50 }, (_, k) => getPuzzle({ difficulty: 'hard', seed: `perf-hint:${k}` }).puzzle);
    const t = performance.now();
    for (const p of puzzles) expect(findNextStep(p)).not.toBeNull();
    expect((performance.now() - t) / puzzles.length).toBeLessThan(20);
  });
});
