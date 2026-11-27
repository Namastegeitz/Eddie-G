// Renders the SVG icons to PNG with the pre-installed Playwright Chromium.
import { createRequire } from "node:module";
import { execSync } from "node:child_process";
const require = createRequire(execSync("npm root -g").toString().trim() + "/");
const { chromium } = require("playwright");
import { readFileSync } from "node:fs";
const dir = new URL("../assets/icons/", import.meta.url);
const jobs = [["icon.svg", "icon-180.png", 180], ["icon.svg", "icon-192.png", 192], ["icon.svg", "icon-512.png", 512], ["icon-maskable.svg", "icon-maskable-512.png", 512]];
const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 1 });
for (const [src, out, size] of jobs) {
  const svg = readFileSync(new URL(src, dir), "utf8");
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(`<html><body style="margin:0;background:transparent">${svg.replace("<svg ", `<svg width="${size}" height="${size}" `)}</body></html>`);
  await page.screenshot({ path: new URL(out, dir).pathname, omitBackground: true, clip: { x: 0, y: 0, width: size, height: size } });
}
await browser.close();
console.log("icons written");
