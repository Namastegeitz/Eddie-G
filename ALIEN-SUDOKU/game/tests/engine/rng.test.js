import { describe, it, expect } from 'vitest';
import { createRng, hashString } from '../../src/engine/rng.js';

describe('hashString', () => {
  it('is deterministic and returns uint32', () => {
    expect(hashString('daily:2026-11-03')).toBe(hashString('daily:2026-11-03'));
    for (const s of ['', 'a', 'b', 'campaign:0:0', 'x'.repeat(1000)]) {
      const h = hashString(s);
      expect(Number.isInteger(h)).toBe(true);
      expect(h).toBeGreaterThanOrEqual(0);
      expect(h).toBeLessThan(2 ** 32);
    }
  });

  it('spreads similar strings', () => {
    const hashes = new Set();
    for (let i = 0; i < 1000; i++) hashes.add(hashString(`seed:${i}`));
    expect(hashes.size).toBe(1000);
  });
});

describe('createRng', () => {
  it('is deterministic for the same seed (number or string)', () => {
    for (const seed of [42, 'hello', 0, 'daily:2026-01-01']) {
      const a = createRng(seed);
      const b = createRng(seed);
      const seqA = Array.from({ length: 50 }, () => a.next());
      const seqB = Array.from({ length: 50 }, () => b.next());
      expect(seqA).toEqual(seqB);
    }
  });

  it('differs for different seeds', () => {
    const a = createRng(1);
    const b = createRng(2);
    expect(Array.from({ length: 5 }, () => a.next())).not.toEqual(Array.from({ length: 5 }, () => b.next()));
  });

  it('next() is in [0,1) and int(n) in [0,n)', () => {
    const r = createRng('range');
    const counts = new Array(9).fill(0);
    for (let i = 0; i < 9000; i++) {
      const x = r.next();
      expect(x).toBeGreaterThanOrEqual(0);
      expect(x).toBeLessThan(1);
      const k = r.int(9);
      expect(Number.isInteger(k)).toBe(true);
      counts[k]++;
    }
    // Roughly uniform.
    for (const c of counts) expect(c).toBeGreaterThan(800);
  });

  it('pick and shuffle', () => {
    const r = createRng(7);
    const arr = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    const s = r.shuffle(arr);
    expect(s).not.toBe(arr);
    expect(arr).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect([...s].sort()).toEqual(arr);
    expect(arr).toContain(r.pick(arr));
    expect(createRng(7).shuffle(arr)).toEqual(s);
  });
});
