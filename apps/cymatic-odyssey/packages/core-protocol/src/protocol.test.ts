import { describe, expect, it } from "vitest";
import { isEnvelope, PROTOCOL_VERSION } from "./index";

describe("protocol envelope", () => {
  it("accepts the six v1 message types from the spec", () => {
    for (const m of [
      { v: 1, type: "hello" },
      { v: 1, type: "drive", tones: [{ f: 40, a: 0.3, wave: "sine" }], ramp_ms: 800 },
      { v: 1, type: "light", scene: { mode: "palette", colors: ["#1a0b3d", "#3b82f6"], fade_ms: 1500 } },
      { v: 1, type: "heartbeat", t: 123456 },
      { v: 1, type: "status" },
      { v: 1, type: "stop", fade_ms: 2000 },
    ]) expect(isEnvelope(m)).toBe(true);
    expect(PROTOCOL_VERSION).toBe(1);
  });
  it("rejects wrong versions and unknown types", () => {
    expect(isEnvelope({ v: 2, type: "hello" })).toBe(false);
    expect(isEnvelope({ v: 1, type: "strobe" })).toBe(false);
    expect(isEnvelope(null)).toBe(false);
  });
});
