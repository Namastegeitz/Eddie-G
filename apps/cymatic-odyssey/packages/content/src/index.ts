import register from "./claims-register.json";
import phrases from "./phrase-bank.json";
import neverSay from "./never-say.json";

export type Grade = "A" | "B" | "C" | "D" | "T";
export interface Claim {
  id: string;
  kind: "physics" | "wellness" | "tradition" | "safety" | "experience";
  statement: string;
  grade: Grade | "";
  plainSummary: string;
  whatWeSay: string;
  whatWeNeverSay: string[];
  sources: string[];
  needsReview?: boolean;
  notes?: string;
}

export const claimsRegister = register as { version: number; grades: Record<Grade, string>; claims: Claim[] };
export const phraseBank = phrases as { version: number; phrases: Array<{ text: string; claims: string[] }> };
export const neverSayTerms = (neverSay as { terms: Array<{ pattern: string; why: string }> }).terms.map((t) => ({
  re: new RegExp(t.pattern, "i"),
  why: t.why,
}));

export const getClaim = (id: string): Claim | undefined => claimsRegister.claims.find((c) => c.id === id);

/** A claim may be shown to users only when it is graded (not needsReview). */
export const isUsable = (c: Claim): boolean => !c.needsReview && c.grade !== "";

/** Labels every number the user sees must carry (spec rule 2). */
export type DataLabel = "Measured" | "Simulated" | "Estimated" | "Tradition (not science)";

export function lintText(text: string): Array<{ term: string; why: string; index: number }> {
  const hits: Array<{ term: string; why: string; index: number }> = [];
  for (const t of neverSayTerms) {
    const m = t.re.exec(text);
    if (m) hits.push({ term: m[0], why: t.why, index: m.index });
  }
  return hits;
}
