import { LIGHT } from "./limits";

/** Linear RGB, each 0..1. */
export interface RGB {
  r: number;
  g: number;
  b: number;
}

export interface FlickerGuardEvent {
  t: number;
  kind: "transition-budget" | "red-budget";
  detail: string;
}

/** Relative luminance (sRGB primaries, linear components). */
export const luminance = (c: RGB): number => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;

export const isSaturatedRed = (c: RGB): boolean => c.r >= 0.6 && c.g <= 0.25 * c.r && c.b <= 0.25 * c.r;

const clamp01 = (v: number) => (v < 0 ? 0 : v > 1 ? 1 : v);

/**
 * Flicker guard for one light output (an LED ring segment, a screen layer, a projector).
 *
 * Guarantees (checked by property tests):
 *  1. at most LIGHT.maxTransitionsPerWindow completed luminance transitions (excursions of at least
 *     LIGHT.transitionThreshold that reverse from the last extreme) in any LIGHT.windowMs window;
 *  2. a single step never moves faster than max(gap, threshold) / minFadeMs, so large swings become
 *     fades of about minFadeMs or longer;
 *  3. stricter limits while saturated red is involved.
 * Because fast periodic modulation (3-60 Hz) would need many transitions per second, it is
 * attenuated to sub-threshold wobble or slowed to <= 3 transitions per second.
 */
export class FlickerGuard {
  private out: RGB;
  private lastT: number | null = null;
  private dir = 0; // +1 rising, -1 falling, 0 unknown
  private ext: number; // extreme luminance reached in the current direction
  private transitions: number[] = [];
  readonly events: FlickerGuardEvent[] = [];

  constructor(initial: RGB = { r: 0, g: 0, b: 0 }) {
    this.out = { r: clamp01(initial.r), g: clamp01(initial.g), b: clamp01(initial.b) };
    this.ext = luminance(this.out);
  }

  get current(): RGB {
    return { ...this.out };
  }

  /** Feed the desired colour at time t (ms, monotonic). Returns the colour that may be shown. */
  process(t: number, target: RGB): RGB {
    const tgt = { r: clamp01(target.r), g: clamp01(target.g), b: clamp01(target.b) };
    const dt = this.lastT === null ? 0 : Math.max(0, t - this.lastT);
    this.lastT = t;
    const red = isSaturatedRed(tgt) || isSaturatedRed(this.out);
    const thr = red ? LIGHT.redTransitionThreshold : LIGHT.transitionThreshold;
    const budget = red ? LIGHT.maxRedTransitionsPerWindow : LIGHT.maxTransitionsPerWindow;

    // 1) slew limit per channel
    const cand: RGB = { ...this.out };
    for (const k of ["r", "g", "b"] as const) {
      const gap = tgt[k] - this.out[k];
      const maxStep = (Math.max(Math.abs(gap), thr) / LIGHT.minFadeMs) * dt;
      cand[k] = this.out[k] + Math.sign(gap) * Math.min(Math.abs(gap), maxStep);
    }

    // 2) transition budget
    const winStart = t - LIGHT.windowMs;
    this.transitions = this.transitions.filter((x) => x > winStart);
    // red uses the same history with a smaller budget: no red transition if any transition happened in the window
    const used = this.transitions.length;
    const yOut = luminance(this.out);
    let yC = luminance(cand);
    // would cand complete a new transition (reversal of at least thr from the current extreme)?
    const limit = (y: number): number | null => {
      if (this.dir >= 0 && y <= this.ext - thr) return this.ext - thr + 1e-9; // falling transition
      if (this.dir <= 0 && y >= this.ext + thr) return this.ext + thr - 1e-9; // rising transition
      return null;
    };
    const lim = limit(yC);
    if (lim !== null && used >= budget) {
      // scale the step so luminance stops just short of completing the transition
      const s = yC === yOut ? 0 : Math.max(0, Math.min(1, (lim - yOut) / (yC - yOut)));
      for (const k of ["r", "g", "b"] as const) cand[k] = this.out[k] + s * (cand[k] - this.out[k]);
      yC = luminance(cand);
      this.events.push({ t, kind: red ? "red-budget" : "transition-budget", detail: `held at Y=${yC.toFixed(3)}` });
    }

    // 3) track extremes / record completed transitions
    if (this.dir === 0) {
      if (yC >= this.ext + thr) this.complete(t, 1, yC);
      else if (yC <= this.ext - thr) this.complete(t, -1, yC);
    } else if (this.dir > 0) {
      if (yC > this.ext) this.ext = yC;
      else if (yC <= this.ext - thr) this.complete(t, -1, yC);
    } else {
      if (yC < this.ext) this.ext = yC;
      else if (yC >= this.ext + thr) this.complete(t, 1, yC);
    }
    this.out = cand;
    return { ...cand };
  }

  private complete(t: number, dir: number, y: number) {
    this.transitions.push(t);
    this.dir = dir;
    this.ext = y;
  }
}
