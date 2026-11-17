import { describe, it, expect, afterEach } from 'vitest';
import POOL from '../../src/data/puzzle-pool.json' with { type: 'json' };
import {
  DIFFICULTIES,
  POOL_SIZES,
  getPuzzle,
  getPuzzleById,
  randomPuzzle,
  getDailyPuzzle,
  weekdayOf,
  getCampaignPuzzle,
  campaignDifficulty,
  CAMPAIGN,
} from '../../src/engine/pool.js';
import { parseGrid, countSolutions, isSolved } from '../../src/engine/sudoku.js';
import { gradePuzzle, poolBand } from '../../src/engine/logic.js';

function expectConsistent(p) {
  expect(p.puzzle).toHaveLength(81);
  expect(p.solution).toHaveLength(81);
  expect(isSolved(p.solution)).toBe(true);
  p.puzzle.forEach((v, i) => {
    if (v) expect(v).toBe(p.solution[i]);
  });
  expect(p.clues).toBe(p.puzzle.filter(Boolean).length);
}

describe('pool file', () => {
  it('has the expected shape and no duplicates', () => {
    expect(POOL.version).toBe(1);
    expect(DIFFICULTIES).toEqual(['easy', 'medium', 'hard', 'alien']);
    const all = new Set();
    for (const d of DIFFICULTIES) {
      expect(POOL[d].length).toBeGreaterThanOrEqual(100);
      expect(POOL_SIZES[d]).toBe(POOL[d].length);
      for (const s of POOL[d]) {
        expect(s).toMatch(/^[0-9]{81}$/);
        all.add(s);
      }
    }
    expect(all.size).toBe(DIFFICULTIES.reduce((n, d) => n + POOL[d].length, 0));
  });

  // Full check of every pooled puzzle (~1s).
  it('every puzzle is unique and graded to its own band', () => {
    const clueRange = { easy: [36, 40], medium: [30, 34], hard: [25, 29], alien: [22, 26] };
    for (const d of DIFFICULTIES) {
      for (const s of POOL[d]) {
        const grid = parseGrid(s);
        expect(countSolutions(grid), s).toBe(1);
        const g = gradePuzzle(grid);
        expect(g.solved, s).toBe(true);
        expect(g.difficulty, s).toBe(d);
        expect(poolBand(g), s).toBe(d);
        expect(g.clues).toBeGreaterThanOrEqual(clueRange[d][0]);
        expect(g.clues).toBeLessThanOrEqual(clueRange[d][1]);
      }
    }
  });
});

describe('getPuzzle', () => {
  it('returns a solution consistent with the puzzle', () => {
    for (const difficulty of DIFFICULTIES) {
      for (let k = 0; k < 10; k++) {
        const p = getPuzzle({ difficulty, seed: `consistency:${k}` });
        expect(p.difficulty).toBe(difficulty);
        expectConsistent(p);
        expect(countSolutions(p.puzzle)).toBe(1);
        expect(gradePuzzle(p.puzzle).difficulty).toBe(difficulty);
      }
    }
  });

  it('is deterministic per seed and varies across seeds', () => {
    const a = getPuzzle({ difficulty: 'hard', seed: 'abc' });
    expect(getPuzzle({ difficulty: 'hard', seed: 'abc' })).toEqual(a);
    expect(getPuzzle({ difficulty: 'hard', seed: 'abd' }).puzzle).not.toEqual(a.puzzle);
    expect(getPuzzle({ difficulty: 'hard', seed: 12345 })).toEqual(getPuzzle({ difficulty: 'hard', seed: 12345 }));
    expect(a.id).toMatch(/^hard:\d+:[0-9a-z]+$/);
  });

  it('honours index and round-trips through getPuzzleById', () => {
    const p = getPuzzle({ difficulty: 'medium', seed: 'x', index: 7 });
    expect(p.id.startsWith('medium:7:')).toBe(true);
    expect(getPuzzleById(p.id)).toEqual(p);
    const q = getPuzzle({ difficulty: 'alien', seed: 99 });
    expect(getPuzzleById(q.id)).toEqual(q);
  });

  it('rejects unknown difficulties', () => {
    expect(() => getPuzzle({ difficulty: 'impossible', seed: 1 })).toThrow();
  });

  it('randomPuzzle gives valid puzzles', () => {
    const p = randomPuzzle('easy');
    expect(p.difficulty).toBe('easy');
    expectConsistent(p);
  });
});

describe('getDailyPuzzle', () => {
  const realTZ = process.env.TZ;
  afterEach(() => {
    if (realTZ === undefined) delete process.env.TZ;
    else process.env.TZ = realTZ;
  });

  it('maps weekdays to difficulties', () => {
    const week = {
      '2026-11-02': 'easy', // Monday
      '2026-11-03': 'medium',
      '2026-11-04': 'medium',
      '2026-11-05': 'hard',
      '2026-11-06': 'hard',
      '2026-11-07': 'alien', // Saturday
      '2026-11-08': 'hard', // Sunday
    };
    for (const [date, difficulty] of Object.entries(week)) {
      const p = getDailyPuzzle(date);
      expect(p.difficulty).toBe(difficulty);
      expect(p.date).toBe(date);
      expectConsistent(p);
    }
    expect(weekdayOf('2024-02-29')).toBe(4);
    expect(weekdayOf('2000-01-01')).toBe(6);
  });

  it('is deterministic and independent of the local timezone', () => {
    const ref = getDailyPuzzle('2026-03-29');
    for (const tz of ['Pacific/Kiritimati', 'Pacific/Pago_Pago', 'UTC', 'America/Los_Angeles']) {
      process.env.TZ = tz;
      expect(weekdayOf('2026-03-29')).toBe(0);
      expect(getDailyPuzzle('2026-03-29')).toEqual(ref);
    }
    expect(getDailyPuzzle('2026-03-30').id).not.toBe(ref.id);
  });

  it('rejects malformed dates', () => {
    expect(() => getDailyPuzzle('11/03/2026')).toThrow();
  });
});

describe('campaign', () => {
  const levels = [];
  for (let s = 0; s < CAMPAIGN.sectors; s++) for (let l = 0; l < CAMPAIGN.levelsPerSector; l++) levels.push([s, l]);

  it('has 6 sectors of 9 levels with the documented ramp', () => {
    expect(CAMPAIGN).toEqual({ sectors: 6, levelsPerSector: 9 });
    const ramp = levels.map(([s, l]) => campaignDifficulty(s, l)[0]).join('');
    expect(ramp).toBe(
      'eeeeeeeee' + 'eeeemmmmm' + 'mmmmmmmmm' + 'mmmmhhhhh' + 'hhhhhhhhh' + 'hhhaaaaaa',
    );
  });

  it('is deterministic, valid and never reuses a base puzzle', () => {
    const used = new Set();
    const lastIndex = {};
    for (const [s, l] of levels) {
      const p = getCampaignPuzzle(s, l);
      expect(getCampaignPuzzle(s, l)).toEqual(p);
      expect(p).toMatchObject({ sector: s, level: l, difficulty: campaignDifficulty(s, l) });
      expectConsistent(p);
      const [difficulty, index] = p.id.split(':');
      const key = `${difficulty}:${index}`;
      expect(used.has(key)).toBe(false);
      used.add(key);
      // Within a difficulty, later levels use later (harder-graded) pool entries.
      if (difficulty in lastIndex) expect(Number(index)).toBeGreaterThan(lastIndex[difficulty]);
      lastIndex[difficulty] = Number(index);
    }
    expect(used.size).toBe(54);
  });

  it('rejects out-of-range levels', () => {
    expect(() => getCampaignPuzzle(6, 0)).toThrow();
    expect(() => getCampaignPuzzle(0, 9)).toThrow();
    expect(() => getCampaignPuzzle(-1, 0)).toThrow();
  });
});
