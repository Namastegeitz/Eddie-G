import { describe, it, expect } from 'vitest';
import { getPuzzle } from '../../src/engine/pool.js';
import {
  Rival, planRival, resolveRival, paceRate, estimateRivalMs, rivalLine, RIVAL_ORDER, RIVALS, RIVAL_LINES,
} from '../../src/game/rival.js';

const puzzleOf = (difficulty, index = 0) => getPuzzle({ difficulty, index });

describe('rival plan', () => {
  it('every rival solves the puzzle correctly, one placement per empty cell', () => {
    for (const d of ['easy', 'medium', 'hard', 'alien']) {
      const p = puzzleOf(d, 3);
      for (const id of RIVAL_ORDER) {
        const rival = resolveRival({ rival: id });
        const r = new Rival({ puzzle: p.puzzle, solution: p.solution, difficulty: d, rival, seed: 7 });
        r.finish();
        expect(r.finished).toBe(true);
        expect(r.board).toEqual(p.solution);
        expect(r.total).toBe(p.puzzle.filter((v) => !v).length);
        const placed = r.plan.events.filter((e) => !e.wrong).map((e) => e.i);
        expect(new Set(placed).size).toBe(r.total);
      }
    }
  });

  it('is deterministic for a seed, and fumbles are wrong glyphs', () => {
    const p = puzzleOf('medium', 1);
    const rival = resolveRival({ rival: 'blip' });
    const a = planRival({ ...p, difficulty: 'medium', rival, seed: 42 });
    const b = planRival({ ...p, difficulty: 'medium', rival, seed: 42 });
    expect(a).toEqual(b);
    const fumbles = a.events.filter((e) => e.wrong);
    expect(fumbles.length).toBeGreaterThan(0);
    for (const e of fumbles) expect(e.v).not.toBe(p.solution[e.i]);
    for (let k = 1; k < a.events.length; k++) expect(a.events[k].at).toBeGreaterThanOrEqual(a.events[k - 1].at);
  });

  it('a flawless rival never fumbles; faster rivals finish sooner', () => {
    const p = puzzleOf('hard', 2);
    const maw = planRival({ ...p, difficulty: 'hard', rival: resolveRival({ rival: 'maw' }), seed: 1 });
    expect(maw.events.some((e) => e.wrong)).toBe(false);
    const ends = [1, 3, 5].map((speed) => planRival({ ...p, difficulty: 'hard', rival: resolveRival({ rival: 'vex', speed, accuracy: 5 }), seed: 1 }).endsAt);
    expect(ends[0]).toBeGreaterThan(ends[1]);
    expect(ends[1]).toBeGreaterThan(ends[2]);
  });

  it('head start delays the first move', () => {
    const p = puzzleOf('easy', 0);
    const plan = planRival({ ...p, difficulty: 'easy', rival: resolveRival({ rival: 'maw', headStart: 30 }), seed: 3 });
    expect(plan.events[0].at).toBeGreaterThanOrEqual(30_000);
  });

  it('estimates land near the real finish time', () => {
    for (const id of RIVAL_ORDER) {
      const rival = resolveRival({ rival: id });
      let sum = 0;
      for (let k = 0; k < 8; k++) {
        const p = puzzleOf('medium', k);
        sum += planRival({ ...p, difficulty: 'medium', rival, seed: k + 1 }).endsAt;
      }
      const ratio = estimateRivalMs(rival, 'medium') / (sum / 8);
      expect(ratio).toBeGreaterThan(0.75);
      expect(ratio).toBeLessThan(1.3);
    }
  });
});

describe('running rival', () => {
  it('advances with the clock and restores from a saved clock', () => {
    const p = puzzleOf('medium', 4);
    const rival = resolveRival({ rival: 'zorp' });
    const r = new Rival({ ...p, difficulty: 'medium', rival, seed: 9 });
    expect(r.filled).toBe(0);
    const first = r.nextIn;
    expect(r.advance(first - 1)).toEqual([]);
    const evs = r.advance(2);
    expect(evs.length).toBeGreaterThan(0);
    r.advance(60_000);
    const copy = new Rival({ ...p, difficulty: 'medium', rival, seed: 9, clock: r.state().clock });
    expect(copy.board).toEqual(r.board);
    expect(copy.filled).toBe(r.filled);
  });

  it('keeps pace: hurries when behind, eases off when ahead, only when asked', () => {
    expect(paceRate(5, false)).toBe(1);
    expect(paceRate(5, true)).toBeGreaterThan(1);
    expect(paceRate(-5, true)).toBeLessThan(1);
    expect(paceRate(100, true)).toBe(1.6);
    expect(paceRate(-100, true)).toBe(0.6);
  });
});

describe('rival settings', () => {
  it('fills in defaults, clamps bad values and keeps a short name', () => {
    const r = resolveRival({ rival: 'vex', speed: 99, accuracy: -3, style: 'nope', headStart: 7, name: '  Captain   Very Long Name Here ' });
    expect(r.speed).toBe(5);
    expect(r.accuracy).toBe(1);
    expect(r.style).toBe(RIVALS.vex.style);
    expect(r.headStart).toBe(0);
    expect(r.name).toBe('Captain Very Lon');
    expect(resolveRival({}).base).toBe('zorp');
    expect(resolveRival({ rival: 'unknown' }).base).toBe('zorp');
  });

  it('a rival made easier is recorded as custom; harder or equal keeps its id', () => {
    expect(resolveRival({ rival: 'maw' }).id).toBe('maw');
    expect(resolveRival({ rival: 'maw', speed: 3 }).id).toBe('custom');
    expect(resolveRival({ rival: 'maw', headStart: 15 }).id).toBe('custom');
    expect(resolveRival({ rival: 'blip', speed: 5, accuracy: 5 }).id).toBe('blip');
  });

  it('the look sets the tone of what the rival says', () => {
    expect(resolveRival({ rival: 'blip', look: { set: 'gnarly', n: 4 } }).tone).toBe('gnarly');
    for (const tone of Object.keys(RIVAL_LINES)) {
      for (const sit of Object.keys(RIVAL_LINES[tone])) expect(rivalLine(tone, sit, 0.999)).toMatch(/\S/);
    }
  });
});
