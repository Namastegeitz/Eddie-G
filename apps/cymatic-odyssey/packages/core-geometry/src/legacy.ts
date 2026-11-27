import catalog from "../../../catalog/geometry_catalog.json";
import styles from "../../../catalog/styles.json";

export interface LegacyEntry {
  id: string;
  name: string;
  part: "gobo" | "insert" | "dipper";
  family: string;
  family_title: string;
  math: string;
  symmetry: string;
  stl: string;
  svg: string;
  ok: boolean;
}

export interface LegacyStyle {
  id: string;
  name: string;
  gobo: string;
  insert: string;
  dipper: string | null;
  mode: "faraday" | "dipper";
  f: number;
  ratio: [number, number] | null;
  pulse: number;
  breathe: number;
  pal: string[];
  mood: string;
  how: string;
  best: string;
  folder: string;
}

export const legacyCatalog = catalog as unknown as LegacyEntry[];
export const legacyStyles = styles as unknown as LegacyStyle[];

export function legacySummary() {
  const byPart = { gobo: 0, insert: 0, dipper: 0 } as Record<LegacyEntry["part"], number>;
  for (const e of legacyCatalog) byPart[e.part]++;
  return { total: legacyCatalog.length, ...byPart, styles: legacyStyles.length, families: new Set(legacyCatalog.map((e) => e.family)).size };
}
