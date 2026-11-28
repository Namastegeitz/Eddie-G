import { describe, expect, it } from "vitest";
import { claimsRegister, getClaim, isUsable, lintText, phraseBank } from "./index";

describe("claims register", () => {
  it("has unique IDs and valid grades", () => {
    const ids = claimsRegister.claims.map((c) => c.id);
    expect(new Set(ids).size).toBe(ids.length);
    for (const c of claimsRegister.claims) {
      expect(["A", "B", "C", "D", "T", ""]).toContain(c.grade);
      if (c.grade === "") expect(c.needsReview).toBe(true);
      expect(c.plainSummary.length).toBeGreaterThan(10);
    }
  });
  it("cites at least one source for every graded wellness/physics/safety claim, unless a note explains the gap", () => {
    for (const c of claimsRegister.claims) {
      if (c.kind === "tradition" || c.kind === "experience" || c.needsReview) continue;
      if (c.sources.length === 0 && c.grade !== "D") expect(c.notes, c.id).toBeTruthy();
    }
  });
  it("every approved phrase points at usable claims and passes the linter", () => {
    for (const p of phraseBank.phrases) {
      expect(p.claims.length).toBeGreaterThan(0);
      for (const id of p.claims) expect(getClaim(id) && isUsable(getClaim(id)!), `${p.text} -> ${id}`).toBe(true);
      expect(lintText(p.text), p.text).toEqual([]);
    }
  });
  it("flags never-say terms and trademarks", () => {
    expect(lintText("This bowl heals you")).not.toEqual([]);
    expect(lintText("Hemi-Sync style audio")).not.toEqual([]);
    expect(lintText("proven to reduce anxiety")).not.toEqual([]);
    expect(lintText("See your sound.")).toEqual([]);
  });
});
