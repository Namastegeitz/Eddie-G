import { guardDriveTones } from "@clc/core-safety";
import { legacyStyles, type LegacyStyle } from "@clc/core-geometry";
import { shows as rawShows } from "../../../catalog/content.json";

/** Where the big files live (manual, zips, videos, Android app). The app itself works offline; these need a connection. */
export const SITE_URL = "https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber/";
export const fileUrl = (name: string) => `${SITE_URL}files/${name}`;
export const media = (p: string) => `./media/${p}`;
export const APP_VERSION = "1.0.0";

export type Style = LegacyStyle & { files?: string[] };
export const styles: Style[] = legacyStyles as Style[];
export const styleById = new Map(styles.map((s) => [s.id, s]));

export interface ShowStep {
  t: number;
  f: number;
  ratio: [number, number] | null;
  mix: number;
  pulse: number;
  breathe: number;
  mode: "faraday" | "dipper";
  style?: string;
  role?: string;
  text: string;
}
export interface Show {
  id: string;
  name: string;
  mood: string;
  minutes: number;
  next: string;
  guest_from: string;
  insert: string;
  steps: ShowStep[];
}
export const shows = rawShows as unknown as Show[];
export const showById = new Map(shows.map((s) => [s.id, s]));
export const showNumber = (id: string) => shows.findIndex((s) => s.id === id) + 1;
export const videoName = (id: string) => `${String(showNumber(id)).padStart(2, "0")}_${id}.mp4`;

export interface GuardStatus {
  ok: boolean;
  /** drive-tone difference and the water's own beat (half of it, Faraday response) */
  beatHz?: number;
  waterHz?: number;
  text: string;
}

/** Same rule the console applies when it plays: two tones that beat at 3-60 Hz get the second tone turned down to 10 %. */
export function guardStatus(sig: { f: number; ratio: [number, number] | null; mix?: number }): GuardStatus {
  if (!sig.ratio) return { ok: true, text: "Single tone: plays as designed." };
  const fB = (sig.f * sig.ratio[0]) / sig.ratio[1];
  const mix = sig.mix ?? 0.55;
  const r = guardDriveTones([{ f: sig.f, a: 1 - 0.5 * mix }, { f: fB, a: mix }], "limit");
  const beat = Math.abs(fB - sig.f);
  if (!r.changed) return { ok: true, beatHz: beat, waterHz: beat / 2, text: `Two tones, beat ${beat.toFixed(1)} Hz: outside the flicker band, plays as designed.` };
  return {
    ok: false,
    beatHz: beat,
    waterHz: beat / 2,
    text: `Two tones beat at ${beat.toFixed(1)} Hz (water ${(beat / 2).toFixed(1)} Hz), inside the 3-60 Hz flicker band, so the second tone plays at 10 %. Full strength only in Lab mode, in private.`,
  };
}

export const styleGuard = (s: Style) => guardStatus({ f: s.f, ratio: s.ratio, mix: s.ratio ? 0.55 : 0 });
export const stepGuard = (s: ShowStep) => guardStatus({ f: s.f, ratio: s.ratio, mix: s.mix });

export const modeLabel = (m: "faraday" | "dipper") => (m === "faraday" ? "Whole dish" : "Dipper");
export const modeHelp = (m: "faraday" | "dipper") =>
  m === "faraday" ? "The whole dish shakes; the water answers at half the drive frequency (Faraday waves)." : "A printed foot taps the surface; rings travel outward at the drive frequency.";

export const mmss = (t: number) => `${Math.floor(t / 60)}:${String(Math.floor(t % 60)).padStart(2, "0")}`;

export interface Download {
  file: string;
  title: string;
  size: string;
  what: string;
}
export const MAIN_DOWNLOADS: Download[] = [
  { file: "CYMATIC_ODYSSEY_Manual.pdf", title: "Complete manual (PDF, 77 pages)", size: "19 MB", what: "How it works, safety, five models, parts, printing, 7 assembly steps, wiring, every style and show." },
  { file: "CYMATIC_ODYSSEY_Sourcing_Guide.pdf", title: "Sourcing guide (PDF)", size: "1 MB", what: "Geometric glass, custom glass makers, clear and effect filaments." },
  { file: "CYMATIC_ODYSSEY_30_style_kits.zip", title: "30 style kits (STL + SVG)", size: "31 MB", what: "Gobo, insert and dipper foot for every style, plus all hardware parts." },
  { file: "CYMATIC_ODYSSEY_Bambu_Studio.zip", title: "Bambu Studio plates (3MF)", size: "24 MB", what: "Checked STLs and ready plates, two-colour gobos, A1 mini platform." },
  { file: "CYMATIC_ODYSSEY_Blender_enhanced.zip", title: "Blender-enhanced parts", size: "17 MB", what: "Bevelled, engraved and remeshed versions of the kit parts." },
  { file: "hardware.zip", title: "Hardware parts only", size: "0.3 MB", what: "Platform, carriers, mounts and enclosure parts." },
  { file: "inserts.zip", title: "All dish inserts", size: "0.8 MB", what: "Boundary shapes that set the pattern's symmetry." },
  { file: "dippers.zip", title: "All dipper feet", size: "0.1 MB", what: "Wave sources for the dipper mode." },
];
export const GOBO_FAMILIES = [
  "archimedean", "catalan", "classical", "cosmic", "fractals", "harmonographs", "hyperbolic", "islamic", "knots", "lissajous", "number",
  "optics", "physics", "platonic", "polygons", "polytopes4d", "quasicrystal", "roses", "sacred", "spirals", "spirographs", "stars", "stellated",
  "superformula", "tilings",
];
export const ANDROID_APK = "android/CymaticLightChamber-1.0.0.apk";

export function isNative(): boolean {
  const cap = (globalThis as { Capacitor?: { isNativePlatform?: () => boolean } }).Capacitor;
  return !!cap?.isNativePlatform?.();
}
