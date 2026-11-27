// Store screenshots from the built app (apps/web/dist served locally), at the sizes each store asks for.
//   (cd apps/web/dist && python3 -m http.server 8766) & node store-launch/make_store_assets.cjs
const { chromium } = require("playwright");
const path = require("path");
const fs = require("fs");
const BASE = process.env.BASE || "http://127.0.0.1:8766/";
const OUT = path.join(__dirname, "screenshots");
const SETS = [
  { dir: "apple-iphone-6.9in", w: 430, h: 932, scale: 3, mobile: true },   // 1290 x 2796
  { dir: "apple-ipad-13in", w: 1032, h: 1376, scale: 2, mobile: true },    // 2064 x 2752
  { dir: "google-phone", w: 360, h: 640, scale: 3, mobile: true },         // 1080 x 1920
];
const SHOTS = [
  ["01-home", ""],
  ["02-styles", "styles"],
  ["03-style-detail", "styles/S03"],
  ["04-console", "play?style=S05"],
  ["05-show", "shows/genesis"],
];
(async () => {
  const b = await chromium.launch();
  for (const s of SETS) {
    fs.mkdirSync(path.join(OUT, s.dir), { recursive: true });
    const ctx = await b.newContext({ viewport: { width: s.w, height: s.h }, deviceScaleFactor: s.scale, isMobile: s.mobile, hasTouch: true });
    const p = await ctx.newPage();
    await p.goto(BASE);
    await p.evaluate(() => localStorage.setItem("clc-safety-notice-v1", "yes"));
    for (const [name, route] of SHOTS) {
      await p.goto(BASE + "#/" + route);
      await p.reload();
      await p.waitForTimeout(route.startsWith("play") ? 3500 : 1200);
      const file = path.join(OUT, s.dir, `${name}.jpg`);
      await p.screenshot({ path: file, type: "jpeg", quality: 86 });
      console.log(file);
    }
    await ctx.close();
  }
  await b.close();
})();
