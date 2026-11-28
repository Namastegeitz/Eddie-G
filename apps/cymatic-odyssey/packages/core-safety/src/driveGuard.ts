import { AUDIO, MODULATION } from "./limits";

export interface DriveTone {
  f: number;
  a: number; // linear amplitude 0..1 (relative to the firmware/driver ceiling)
  wave?: "sine" | "triangle" | "soft-square";
}

export type BeatPolicy = "limit" | "shift" | "lab";

export interface BeatFinding {
  i: number;
  j: number;
  deltaHz: number;
  /** "drive" = the tones' own difference; "subharmonic" = the Faraday response difference (delta / 2). */
  source: "drive" | "subharmonic";
}

export interface DriveGuardResult {
  tones: DriveTone[];
  findings: BeatFinding[];
  warnings: string[];
  changed: boolean;
}

const inBand = (hz: number) => hz >= MODULATION.blockLowHz && hz <= MODULATION.blockHighHz;

/** Beat frequencies between drive tones that fall in the blocked 3-60 Hz band.
 * Spec 9.1 checks the drive difference. Because Faraday waves answer at f/2, the water's own beat is
 * delta/2; with includeSubharmonic (default) that is checked too. This is stricter than the spec. */
export function findDriveBeats(tones: DriveTone[], includeSubharmonic = true, minAmp = 0.02): BeatFinding[] {
  const out: BeatFinding[] = [];
  for (let i = 0; i < tones.length; i++)
    for (let j = i + 1; j < tones.length; j++) {
      const ti = tones[i]!, tj = tones[j]!;
      if (ti.a < minAmp || tj.a < minAmp) continue;
      const d = Math.abs(ti.f - tj.f);
      if (d === 0) continue;
      if (inBand(d)) out.push({ i, j, deltaHz: d, source: "drive" });
      else if (includeSubharmonic && inBand(d / 2)) out.push({ i, j, deltaHz: d / 2, source: "subharmonic" });
    }
  return out;
}

/** Ratio of the weaker tone allowed in "limit" mode: modulation depth 2r/(1+r) stays under about 18 %. */
export const BEAT_AMPLITUDE_RATIO = 0.1;

export function guardDriveTones(input: DriveTone[], policy: BeatPolicy = "limit", includeSubharmonic = true): DriveGuardResult {
  const tones = input.map((t) => ({
    ...t,
    f: Math.min(Math.max(t.f, AUDIO.driveHz[0]), AUDIO.driveHz[1]),
    a: Math.min(Math.max(t.a, 0), 1),
  }));
  const warnings: string[] = [];
  let changed = tones.some((t, k) => t.f !== input[k]!.f || t.a !== input[k]!.a);
  if (changed) warnings.push("drive tone clamped to 5-200 Hz / amplitude 0-1");
  const findings = findDriveBeats(tones, includeSubharmonic);
  if (findings.length === 0) return { tones, findings, warnings, changed };
  if (policy === "lab") {
    warnings.push(`LAB OPT-IN: ${findings.length} beat(s) in the 3-60 Hz flicker band left as-is`);
    return { tones, findings, warnings, changed };
  }
  for (const fnd of findings) {
    const ti = tones[fnd.i]!, tj = tones[fnd.j]!;
    const weak = ti.a <= tj.a ? ti : tj;
    const strong = weak === ti ? tj : ti;
    if (policy === "shift") {
      // move the weaker tone so the drive difference is above the band (and its half above 60 too if checked)
      const minDelta = includeSubharmonic ? 2 * MODULATION.blockHighHz + 1 : MODULATION.blockHighHz + 1;
      const up = strong.f + minDelta, down = strong.f - minDelta;
      const nf = up <= AUDIO.driveHz[1] ? up : down >= AUDIO.driveHz[0] ? down : null;
      if (nf !== null) {
        weak.f = nf;
        warnings.push(`shifted a drive tone to ${nf.toFixed(2)} Hz to move a ${fnd.deltaHz.toFixed(2)} Hz beat out of the flicker band`);
        changed = true;
        continue;
      }
      // fall through to limiting when shifting is impossible
    }
    const cap = strong.a * BEAT_AMPLITUDE_RATIO;
    if (weak.a > cap) {
      weak.a = cap;
      changed = true;
    }
    warnings.push(`limited a drive tone to ${(BEAT_AMPLITUDE_RATIO * 100).toFixed(0)} % because the ${fnd.source} beat is ${fnd.deltaHz.toFixed(2)} Hz (3-60 Hz flicker band)`);
  }
  return { tones, findings: findDriveBeats(tones, includeSubharmonic, 0.0), warnings, changed };
}

/** Any periodic brightness modulation (pulse rate, light LFO, beat-driven cue rate) in 3-60 Hz is clamped to 3 Hz. */
export function guardModulationHz(hz: number): { hz: number; clamped: boolean } {
  if (hz > MODULATION.blockLowHz && hz <= MODULATION.blockHighHz) return { hz: MODULATION.blockLowHz, clamped: true };
  return { hz, clamped: false };
}
