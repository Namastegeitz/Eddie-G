/**
 * Deterministic pseudo-random numbers.
 *
 * hashString: FNV-1a 32-bit with a murmur3 finalizer (good avalanche, identical
 * result on every JS engine). createRng: mulberry32 seeded from that hash.
 */

/** Hash a string to an unsigned 32-bit integer. */
export function hashString(str) {
  const s = String(str);
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  // murmur3 fmix32 finalizer
  h ^= h >>> 16;
  h = Math.imul(h, 0x85ebca6b);
  h ^= h >>> 13;
  h = Math.imul(h, 0xc2b2ae35);
  h ^= h >>> 16;
  return h >>> 0;
}

/** Normalize a number or string seed to a uint32. */
export function seedToUint32(seed) {
  if (typeof seed === 'number' && Number.isFinite(seed)) {
    if (Number.isInteger(seed) && seed >= 0 && seed <= 0xffffffff) return seed >>> 0;
    return hashString(String(seed));
  }
  return hashString(String(seed));
}

/**
 * Create a seeded RNG (mulberry32).
 * @param {number|string} seed
 * @returns {{ seed: number, next(): number, int(n: number): number, pick<T>(arr: T[]): T, shuffle<T>(arr: T[]): T[] }}
 */
export function createRng(seed = 0) {
  const seed32 = seedToUint32(seed);
  let state = seed32;
  function next() {
    state = (state + 0x6d2b79f5) | 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
  function int(n) {
    return Math.floor(next() * n);
  }
  function pick(arr) {
    return arr[int(arr.length)];
  }
  function shuffle(arr) {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = int(i + 1);
      const tmp = a[i];
      a[i] = a[j];
      a[j] = tmp;
    }
    return a;
  }
  return { seed: seed32, next, int, pick, shuffle };
}
