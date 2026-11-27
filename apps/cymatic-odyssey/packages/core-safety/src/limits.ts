/** Safety constants (spec sections 4.1, 4.2, 4.3, 9.1, 9.2). Changing any of these needs a CHANGELOG entry. */
export const LIGHT = {
  /** A luminance change of at least this much (relative luminance, 0..1) counts as a flash transition (WCAG 2.x general-flash threshold). */
  transitionThreshold: 0.1,
  /** Stricter threshold while saturated red is involved. */
  redTransitionThreshold: 0.05,
  /** At most this many completed transitions in any rolling window (3 transitions = 1.5 flashes; spec allows 3 flashes/s). */
  maxTransitionsPerWindow: 3,
  /** At most this many transitions per window while saturated red is involved. */
  maxRedTransitionsPerWindow: 1,
  windowMs: 1000,
  /** Large swings become fades of at least this long. */
  minFadeMs: 333,
} as const;

export const MODULATION = {
  /** Periodic brightness modulation in [blockLowHz, blockHighHz] is blocked (clamped to blockLowHz). */
  blockLowHz: 3,
  blockHighHz: 60,
} as const;

export const AUDIO = {
  masterDefaultDbfs: -18,
  hardCeilingDbfs: -1,
  minFadeInS: 2,
  minFadeOutS: 3,
  driveHz: [5, 200] as const,
  listenHz: [20, 2000] as const,
  binauralCarrierHz: [100, 1000] as const,
  binauralBeatHz: [0.5, 30] as const,
  maxLayers: 8,
  slowLfoMaxHz: 0.5,
} as const;

export const dbToGain = (db: number): number => Math.pow(10, db / 20);
export const gainToDb = (g: number): number => 20 * Math.log10(Math.max(g, 1e-12));
