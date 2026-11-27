import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { MASTER_DEFAULT_GAIN, MODULATION } from "@clc/core-safety";

// Static checks of the legacy Voyage console's Safety Guardian wiring. The behaviour is checked in a real
// browser by tests/console_guard.cjs (fades, beat guard, Lab mode, ceiling, FADE ALL).
const html = readFileSync(new URL("../../../console/index.html", import.meta.url), "utf8");
const attr = (id: string, name: string) => html.match(new RegExp(`id="${id}"[^>]*\\b${name}="([^"]+)"`))?.[1];

describe("legacy console safety wiring", () => {
  it("carries the Safety Guardian bundle", () => {
    const a = html.indexOf("/*SAFETY*/"), b = html.indexOf("/*END_SAFETY*/");
    expect(a).toBeGreaterThan(0);
    expect(b - a).toBeGreaterThan(1000);
    expect(html).toContain("const SG = window.CLCSafety;");
  });
  it("caps the pulse rate at the modulation limit", () => {
    expect(Number(attr("pulse", "max"))).toBeLessThanOrEqual(MODULATION.blockLowHz);
  });
  it("starts the volume at -18 dBFS", () => {
    expect(Math.abs(Number(attr("vol", "value")) - MASTER_DEFAULT_GAIN)).toBeLessThan(0.002);
  });
  it("routes tones through the drive guard and fades through guardRamp", () => {
    expect(html).toContain("SG.guardDriveTones(");
    expect(html).toContain("SG.guardRamp({kind:'in'");
    expect(html).toContain("SG.guardRamp({kind:'out'");
    expect(html).toContain("SG.guardModulationHz(");
    expect(html).not.toContain("master.gain.setTargetAtTime(0, ac.currentTime, 0.05)");
  });
  it("labels the preview as a SIMULATION", () => {
    expect(html).toMatch(/<div id="stage">.*<span class="simmark">SIMULATION<\/span><\/div>/);
  });
  it("starts with Lab mode off", () => {
    expect(html).toContain("$('labMode').checked = false;");
  });
});
