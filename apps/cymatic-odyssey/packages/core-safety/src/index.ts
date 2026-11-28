export * from "./limits";
export * from "./flickerGuard";
export * from "./driveGuard";
export * from "./audioGuard";

import { FlickerGuard, type RGB } from "./flickerGuard";
import { guardDriveTones, guardModulationHz, type BeatPolicy, type DriveTone } from "./driveGuard";

export interface GuardEvent {
  t: number;
  source: "light" | "drive" | "modulation" | "fade-all";
  message: string;
}

/** The single gate every output passes through. P0 skeleton: light, drive and modulation guards plus FADE ALL. */
export class SafetyGuardian {
  readonly events: GuardEvent[] = [];
  private lights = new Map<string, FlickerGuard>();
  private fadeListeners: Array<(fadeMs: number) => void> = [];
  labOptIn = false;

  constructor(private now: () => number = () => Date.now()) {}

  light(fixtureId: string, target: RGB, t = this.now()): RGB {
    let g = this.lights.get(fixtureId);
    if (!g) {
      g = new FlickerGuard();
      this.lights.set(fixtureId, g);
    }
    const before = g.events.length;
    const out = g.process(t, target);
    for (const e of g.events.slice(before)) this.log("light", `${fixtureId}: ${e.kind} ${e.detail}`, e.t);
    return out;
  }

  drive(tones: DriveTone[], policy?: BeatPolicy) {
    const res = guardDriveTones(tones, policy ?? (this.labOptIn ? "lab" : "limit"));
    for (const w of res.warnings) this.log("drive", w);
    return res;
  }

  modulation(hz: number) {
    const r = guardModulationHz(hz);
    if (r.clamped) this.log("modulation", `modulation ${hz} Hz clamped to ${r.hz} Hz`);
    return r.hz;
  }

  onFadeAll(fn: (fadeMs: number) => void) {
    this.fadeListeners.push(fn);
  }

  /** Emergency FADE ALL: every registered output fades to safe idle (lights off, drive 0) over 2 s. */
  fadeAll(fadeMs = 2000) {
    this.log("fade-all", `FADE ALL over ${fadeMs} ms`);
    for (const fn of this.fadeListeners) fn(fadeMs);
  }

  private log(source: GuardEvent["source"], message: string, t = this.now()) {
    this.events.push({ t, source, message });
  }
}
