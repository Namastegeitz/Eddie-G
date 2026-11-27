// Browser check of the Voyage console's Safety Guardian wiring (headless Chromium via Playwright).
//   node tests/console_guard.cjs [path/to/console.html]
// Checks: SIMULATION mark, fade-in >= 2 s, stop fade >= 3 s, FADE ALL message, beat guard (tone B at 10 %),
// Lab mode needs a confirmation, pulse capped at 3/s, hard ceiling at -1 dBFS, no page errors.
const { chromium } = require("playwright");
const path = require("path");

const arg = process.argv[2] || path.join(__dirname, "../console/index.html");
const url = /^https?:/.test(arg) ? arg : "file://" + path.resolve(arg);
const results = [];
const check = (name, ok, detail = "") => results.push({ name, ok: !!ok, detail });

(async () => {
  const browser = await chromium.launch({ args: ["--autoplay-policy=no-user-gesture-required"] });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on("pageerror", (e) => errors.push(String(e)));
  page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
  await page.goto(url);
  await page.waitForFunction(() => window.__odyssey && window.CLCSafety);

  const mark = await page.locator("#stage .simmark").first();
  check("SIMULATION mark visible on the preview", (await mark.isVisible()) && (await mark.textContent()).trim() === "SIMULATION");
  check("pulse slider capped at 3 per second", (await page.getAttribute("#pulse", "max")) === "3");
  const vol0 = await page.evaluate(() => window.__odyssey.st.vol);
  check("volume starts at -18 dBFS", Math.abs(20 * Math.log10(vol0) + 18) < 0.1, `${(20 * Math.log10(vol0)).toFixed(2)} dBFS`);

  // fade-in: measured on the audio clock (the page's own time), so a slow machine can't fool the check
  const g = (expr) => page.evaluate(expr);
  const sample = () => g(() => { const a = window.__odyssey.audio(); return { t: a.ctx.currentTime, v: a.master.gain.value, ramp: window.__odyssey.guard.ramp }; });
  const onRamp = (x) => { const r = x.ramp, u = Math.min(1, Math.max(0, (x.t - r.t0) / r.s)); return r.from + (r.to - r.from) * u; };
  await page.click("#startBtn");
  let x = await sample();
  check("fade-in lasts at least 2 s", x.ramp && x.ramp.kind === "in" && x.ramp.s >= 2 && x.ramp.from === 0, `ramp ${x.ramp && x.ramp.s} s`);
  check("gain follows the fade-in ramp (no jump)", Math.abs(x.v - onRamp(x)) < 0.02 * vol0 + 1e-4, `at ${(x.t - x.ramp.t0).toFixed(2)} s: gain ${x.v.toFixed(4)}, ramp ${onRamp(x).toFixed(4)}`);
  await page.waitForTimeout(2600);
  x = await sample();
  check("fade-in reaches the set volume", Math.abs(x.v - vol0) < 0.01 * vol0 + 1e-4, `gain ${x.v.toFixed(4)}`);

  // hard ceiling
  const ceiling = await g(() => { const c = window.__odyssey.audio().clip.curve; return Math.max(...c.map(Math.abs)); });
  check("hard ceiling at -1 dBFS after the limiter", Math.abs(20 * Math.log10(ceiling) + 1) < 0.01, `${(20 * Math.log10(ceiling)).toFixed(3)} dBFS`);

  // beat guard: 40 Hz + 5:4 (50 Hz) beats at 10 Hz -> tone B limited to 10 % of tone A
  await page.evaluate(() => { const r = document.getElementById("ratio"); r.value = "5/4"; r.dispatchEvent(new Event("change")); });
  await page.evaluate(() => { const m = document.getElementById("mix"); m.value = "0.5"; m.dispatchEvent(new Event("input")); });
  let last = await g(() => window.__odyssey.guard.last);
  check("beat guard limits tone B to 10 % of tone A (40 + 50 Hz)", Math.abs(last.aB - 0.1 * last.aA) < 1e-9 && last.warn, `aA ${last.aA}, aB ${last.aB}`);
  check("guard note explains the limit", /turned down to 10 %/.test(await page.textContent("#guardNote")));

  // Lab mode: dismissing the confirmation keeps the guard on
  page.once("dialog", (d) => d.dismiss());
  await page.click("#labMode");
  last = await g(() => window.__odyssey.guard.last);
  check("Lab mode stays off when the warning is dismissed", !(await page.isChecked("#labMode")) && Math.abs(last.aB - 0.1 * last.aA) < 1e-9);
  page.once("dialog", (d) => d.accept());
  await page.click("#labMode");
  last = await g(() => window.__odyssey.guard.last);
  check("Lab mode after confirming plays both tones as set, with a warning", (await page.isChecked("#labMode")) && last.aB === 0.5 && /LAB MODE/.test(await page.textContent("#guardNote")));
  await page.click("#labMode"); // off again

  // back to a single tone
  await page.evaluate(() => { const r = document.getElementById("ratio"); r.value = ""; r.dispatchEvent(new Event("change")); });
  check("single tone plays as designed", /Plays as designed/.test(await page.textContent("#guardNote")));

  // pulse guard (a voyage step may ask for 4/s)
  // pulse guard: a voyage step may still ask for 4/s
  await page.evaluate(() => { window.__odyssey.st.pulse = 4; window.__odyssey.setF(40); });
  const ph = await g(() => window.__odyssey.guard.pulseHz);
  check("pulse requests above 3/s are slowed to 3/s", ph === 3, `pulse ${ph}/s`);
  await page.evaluate(() => { window.__odyssey.st.pulse = 0; window.__odyssey.setF(40); });

  // stop: fade-out >= 3 s
  await page.click("#panicBtn");
  x = await sample();
  check("Stop fades out over at least 3 s", x.ramp.kind === "out" && x.ramp.s >= 3 && x.ramp.from > 0.9 * vol0, `ramp ${x.ramp.s} s from ${x.ramp.from.toFixed(4)}`);
  check("gain follows the fade-out ramp (no jump)", Math.abs(x.v - onRamp(x)) < 0.02 * vol0 + 1e-4, `at ${(x.t - x.ramp.t0).toFixed(2)} s: gain ${x.v.toFixed(4)}, ramp ${onRamp(x).toFixed(4)}`);
  await page.waitForTimeout(3500);
  x = await sample();
  check("Stop reaches silence", x.v < 1e-4, `gain ${x.v.toExponential(2)}`);

  // FADE ALL message (same origin): 2 s emergency fade
  await page.click("#startBtn");
  await page.waitForTimeout(2600);
  await page.evaluate(() => window.postMessage({ type: "clc:fade-all" }, "*"));
  await page.waitForTimeout(3000);
  const fa = await g(() => window.__odyssey.audio().master.gain.value);
  const faRamp = await g(() => window.__odyssey.guard.ramp);
  const faLogged = await g(() => window.__odyssey.guard.events.some((e) => /FADE ALL/.test(e.msg)));
  check("FADE ALL message fades to silence over 2 s", faLogged && faRamp.s === 2 && fa < 1e-4, `ramp ${faRamp.s} s, gain ${fa.toExponential(2)}`);

  check("no page errors", errors.length === 0, errors.join(" | "));
  await browser.close();
  let failed = 0;
  for (const r of results) { console.log(`${r.ok ? "PASS" : "FAIL"}  ${r.name}${r.detail ? "  (" + r.detail + ")" : ""}`); if (!r.ok) failed++; }
  console.log(`${results.length - failed}/${results.length} passed`);
  process.exit(failed ? 1 : 0);
})();
