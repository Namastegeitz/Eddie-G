/** Test helpers shared by the property tests (deterministic PRNG + an independent flash counter). */
export function mulberry32(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Independent re-implementation of the WCAG-style transition counter: returns completion times of
 * luminance excursions of at least thr that reverse direction from the last extreme. */
export function transitionTimes(series: Array<{ t: number; y: number }>, thr: number): number[] {
  const out: number[] = [];
  if (series.length === 0) return out;
  let dir = 0;
  let ext = series[0]!.y;
  for (const { t, y } of series) {
    if (dir === 0) {
      if (y >= ext + thr) { dir = 1; ext = y; out.push(t); }
      else if (y <= ext - thr) { dir = -1; ext = y; out.push(t); }
    } else if (dir > 0) {
      if (y > ext) ext = y;
      else if (y <= ext - thr) { dir = -1; ext = y; out.push(t); }
    } else {
      if (y < ext) ext = y;
      else if (y >= ext + thr) { dir = 1; ext = y; out.push(t); }
    }
  }
  return out;
}

export function maxInWindow(times: number[], windowMs: number): number {
  let best = 0;
  let j = 0;
  for (let i = 0; i < times.length; i++) {
    while (times[i]! - times[j]! >= windowMs) j++;
    best = Math.max(best, i - j + 1);
  }
  return best;
}
