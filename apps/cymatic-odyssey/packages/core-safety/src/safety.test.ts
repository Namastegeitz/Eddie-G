import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  AUDIO, FlickerGuard, HARD_CEILING_GAIN, LIGHT, MASTER_DEFAULT_GAIN, SafetyGuardian, findDriveBeats,
  guardBinaural, guardDriveTones, guardFrequency, guardModulationHz, guardRamp, hardClip, luminance,
} from "./index";
import { maxInWindow, mulberry32, transitionTimes } from "./testing";

const run = (g: FlickerGuard, targets: Array<{ t: number; c: { r: number; g: number; b: number } }>) =>
  targets.map(({ t, c }) => ({ t, y: luminance(g.process(t, c)) }));

describe("flicker guard (property tests)", () => {
  it("never lets more than 3 transitions of >=10% luminance through in any 1 s window (400 random sequences)", () => {
    const rnd = mulberry32(20261127);
    for (let s = 0; s < 400; s++) {
      const g = new FlickerGuard();
      const seq: Array<{ t: number; c: { r: number; g: number; b: number } }> = [];
      let t = 0;
      let cur = { r: rnd(), g: rnd(), b: rnd() };
      while (t < 6000) {
        t += 2 + rnd() * 60;
        // mixture of holds, random jumps and fast strobing bursts (never saturated red here)
        const mode = rnd();
        if (mode < 0.35) cur = { r: rnd() * 0.5, g: rnd(), b: rnd() };
        else if (mode < 0.55) cur = cur.g > 0.5 ? { r: 0, g: 0, b: 0 } : { r: 1, g: 1, b: 1 };
        seq.push({ t, c: cur });
      }
      const out = run(g, seq);
      const worst = maxInWindow(transitionTimes(out, LIGHT.transitionThreshold), LIGHT.windowMs);
      expect(worst, `sequence ${s}`).toBeLessThanOrEqual(LIGHT.maxTransitionsPerWindow);
    }
  });

  it.each([3.5, 5, 8, 10, 15, 20, 30, 45, 60])("blocks %s Hz periodic modulation (amplitude 0.5)", (hz) => {
    const g = new FlickerGuard({ r: 0.5, g: 0.5, b: 0.5 });
    const seq = [];
    for (let t = 0; t <= 10000; t += 2) {
      const v = 0.5 + 0.5 * Math.sin((2 * Math.PI * hz * t) / 1000);
      seq.push({ t, c: { r: v, g: v, b: v } });
    }
    const out = run(g, seq);
    const times = transitionTimes(out, LIGHT.transitionThreshold);
    // no more than 3 transitions per second: the modulation is slowed to <= 3 Hz-equivalent or held
    expect(maxInWindow(times, 1000)).toBeLessThanOrEqual(3);
  });

  it("lets slow fades through (0.5 Hz sine keeps most of its swing)", () => {
    const g = new FlickerGuard({ r: 0.5, g: 0.5, b: 0.5 });
    const seq = [];
    for (let t = 0; t <= 8000; t += 10) {
      const v = 0.5 + 0.4 * Math.sin((2 * Math.PI * 0.5 * t) / 1000);
      seq.push({ t, c: { r: v, g: v, b: v } });
    }
    const out = run(g, seq).filter((p) => p.t > 4000).map((p) => p.y);
    expect(Math.max(...out) - Math.min(...out)).toBeGreaterThan(0.5);
  });

  it("turns a black-to-white jump into a fade of at least 333 ms", () => {
    const g = new FlickerGuard();
    for (let t = 0; t <= 1000; t += 5) {
      const y = luminance(g.process(t, { r: 1, g: 1, b: 1 }));
      expect(y).toBeLessThanOrEqual(t / LIGHT.minFadeMs + 1e-9);
    }
  });

  it("allows at most 1 saturated-red transition per second (10 Hz red strobe)", () => {
    const g = new FlickerGuard();
    const seq = [];
    for (let t = 0; t <= 6000; t += 5) seq.push({ t, c: Math.floor(t / 50) % 2 ? { r: 1, g: 0, b: 0 } : { r: 0, g: 0, b: 0 } });
    const out = run(g, seq);
    expect(maxInWindow(transitionTimes(out, LIGHT.redTransitionThreshold), 1000)).toBeLessThanOrEqual(LIGHT.maxRedTransitionsPerWindow);
  });
});

describe("drive beat guard (spec 9.1 water-beat flicker)", () => {
  it("flags a 10 Hz beat between 40 and 50 Hz and limits the weaker tone", () => {
    const r = guardDriveTones([{ f: 40, a: 0.5 }, { f: 50, a: 0.3 }]);
    expect(r.findings.some((f) => f.source === "drive" && Math.abs(f.deltaHz - 10) < 1e-9)).toBe(true);
    expect(r.tones[1]!.a).toBeLessThanOrEqual(0.5 * 0.1 + 1e-12);
    expect(r.changed).toBe(true);
  });
  it("shift policy moves the beat out of the band", () => {
    const r = guardDriveTones([{ f: 40, a: 0.5 }, { f: 50, a: 0.3 }], "shift");
    expect(findDriveBeats(r.tones)).toHaveLength(0);
  });
  it("lab policy passes tones through with a warning", () => {
    const r = guardDriveTones([{ f: 40, a: 0.5 }, { f: 50, a: 0.3 }], "lab");
    expect(r.tones[1]!.a).toBe(0.3);
    expect(r.warnings.join(" ")).toMatch(/LAB OPT-IN/);
  });
  it("checks the Faraday subharmonic beat (delta/2) unless turned off", () => {
    expect(findDriveBeats([{ f: 40, a: 0.5 }, { f: 110, a: 0.5 }])).toHaveLength(1);
    expect(findDriveBeats([{ f: 40, a: 0.5 }, { f: 110, a: 0.5 }], false)).toHaveLength(0);
  });
  it("leaves single tones and sub-3 Hz beats alone", () => {
    expect(findDriveBeats([{ f: 40, a: 1 }])).toHaveLength(0);
    expect(findDriveBeats([{ f: 40, a: 0.5 }, { f: 41.5, a: 0.5 }])).toHaveLength(0);
  });
  it("finds the existing two-tone styles that conflict (documented in ARCHITECTURE_NOW)", () => {
    const p = fileURLToPath(new URL("../../../catalog/styles.json", import.meta.url));
    const styles = JSON.parse(readFileSync(p, "utf8")) as Array<{ id: string; f: number; ratio: [number, number] | null }>;
    const bad = styles.filter((s) => s.ratio && findDriveBeats([{ f: s.f, a: 0.5 }, { f: (s.f * s.ratio[0]) / s.ratio[1], a: 0.5 }], false).length > 0);
    expect(bad.map((s) => s.id)).toHaveLength(12);
  });
});

describe("modulation and audio limits", () => {
  it("clamps periodic modulation in 3-60 Hz to 3 Hz", () => {
    expect(guardModulationHz(4)).toEqual({ hz: 3, clamped: true });
    expect(guardModulationHz(60)).toEqual({ hz: 3, clamped: true });
    expect(guardModulationHz(2)).toEqual({ hz: 2, clamped: false });
    expect(guardModulationHz(75)).toEqual({ hz: 75, clamped: false });
  });
  it("enforces fade minimums, master default and the hard ceiling", () => {
    expect(guardRamp({ kind: "in", seconds: 0.1 })).toBe(AUDIO.minFadeInS);
    expect(guardRamp({ kind: "out", seconds: 1 })).toBe(AUDIO.minFadeOutS);
    expect(guardRamp({ kind: "in", seconds: 5 })).toBe(5);
    expect(MASTER_DEFAULT_GAIN).toBeCloseTo(0.1259, 4);
    const b = new Float32Array([0, 0.5, 0.95, -1.2, 2]);
    expect(hardClip(b)).toBe(3);
    expect(Math.max(...Array.from(b).map(Math.abs))).toBeLessThanOrEqual(HARD_CEILING_GAIN + 1e-6);
  });
  it("clamps frequencies and binaural parameters to their ranges", () => {
    expect(guardFrequency("drive", 250).hz).toBe(200);
    expect(guardFrequency("listen", 10).hz).toBe(20);
    expect(guardBinaural(1500, 40)).toEqual({ carrierHz: 1000, beatHz: 30, clamped: true });
  });
});

describe("SafetyGuardian", () => {
  it("FADE ALL reaches every registered output and is logged", () => {
    let t = 0;
    const g = new SafetyGuardian(() => t);
    const seen: number[] = [];
    g.onFadeAll((ms) => seen.push(ms));
    g.onFadeAll((ms) => seen.push(ms));
    g.fadeAll();
    expect(seen).toEqual([2000, 2000]);
    expect(g.events.at(-1)!.source).toBe("fade-all");
    t = 10;
    g.modulation(10);
    expect(g.events.at(-1)!.message).toMatch(/clamped/);
  });
});
