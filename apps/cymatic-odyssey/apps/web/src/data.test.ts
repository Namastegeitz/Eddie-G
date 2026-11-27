import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { guardStatus, shows, stepGuard, styleGuard, styles, videoName } from "./data";
import { parseHash } from "./router";

const pub = (p: string) => fileURLToPath(new URL(`../public/${p}`, import.meta.url));
const repo = (p: string) => fileURLToPath(new URL(`../../../${p}`, import.meta.url));

describe("app data", () => {
  it("has 30 styles and 15 chained shows", () => {
    expect(styles).toHaveLength(30);
    expect(shows).toHaveLength(15);
    const ids = new Set(shows.map((s) => s.id));
    for (const s of shows) expect(ids.has(s.next)).toBe(true);
  });
  it("flags the same 12 two-tone styles the Safety Guardian audit found", () => {
    expect(styles.filter((s) => !styleGuard(s).ok)).toHaveLength(12);
    expect(guardStatus({ f: 40, ratio: [5, 4], mix: 0.5 }).ok).toBe(false); // 10 Hz beat
    expect(guardStatus({ f: 40, ratio: null }).ok).toBe(true);
  });
  it("flags 52 of the show steps", () => {
    expect(shows.flatMap((s) => s.steps).filter((st) => !stepGuard(st).ok)).toHaveLength(52);
  });
  it("has a marked picture set for every style and a poster and video for every show", () => {
    for (const s of styles) for (const k of ["wall", "water", "chamber", "thumb"]) expect(existsSync(pub(`media/styles/${s.id}-${k}.jpg`)), `${s.id} ${k}`).toBe(true);
    for (const s of shows) {
      expect(existsSync(pub(`media/shows/${s.id}.jpg`)), s.id).toBe(true);
      expect(existsSync(repo(`marketing/videos/${videoName(s.id)}`)), videoName(s.id)).toBe(true);
    }
  });
  it("ships the store-required privacy and support pages", () => {
    expect(existsSync(pub("privacy/index.html"))).toBe(true);
    expect(existsSync(pub("support/index.html"))).toBe(true);
  });
});

describe("hash router", () => {
  it("parses paths and queries", () => {
    expect(parseHash("#/styles/S05").path).toEqual(["styles", "S05"]);
    const r = parseHash("#/play?style=S05");
    expect(r.path).toEqual(["play"]);
    expect(r.query.get("style")).toBe("S05");
    expect(parseHash("").path).toEqual([]);
  });
});
