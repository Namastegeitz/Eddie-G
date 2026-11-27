import { describe, expect, it } from "vitest";
import { legacySummary, legacyStyles } from "./index";

describe("legacy adapter over the Python generator", () => {
  it("sees every generated look and style", () => {
    const s = legacySummary();
    expect(s.total).toBe(355);
    expect(s).toMatchObject({ gobo: 306, insert: 37, dipper: 12, styles: 30 });
  });
  it("every style references parts that exist in the catalog", () => {
    expect(legacyStyles.every((st) => st.gobo && st.insert)).toBe(true);
  });
});
