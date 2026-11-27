#!/usr/bin/env node
/* ============================================================
   Performance benchmark: the same scripted flow every run.

   node tools/perf-bench.mjs [--out=perf/latest.json] [--compare=perf/baseline.json] [--runs=3]
   (after `npm run build`; set PW_CHROMIUM to use a preinstalled Chromium)

   Profiles
     phone    Pixel 7 screen, touch, CPU slowed 4x (a mid-range phone)
     desktop  1280x800, full CPU
   For each profile it records
     coldStartMs    navigation to the main menu being on screen (fresh cache)
     heapMB         JS heap in use on the menu, and after a puzzle and the campaign map
     domNodes       DOM size on the play screen
     frames         per scene (menu, play, map): average frame time, fps,
                    1% low fps and the worst single frame, over 5 seconds
   With --compare it exits 1 if any headline number is more than 5% worse.
   Headless Chromium draws on the CPU, so absolute numbers are pessimistic;
   compare runs on the same machine.
   ============================================================ */
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, existsSync, statSync, mkdirSync } from 'node:fs';
import { join, dirname, extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium, devices } from 'playwright';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const arg = (k, d) => (process.argv.find((a) => a.startsWith(`--${k}=`)) || '').split('=')[1] || d;
const outFile = resolve(root, arg('out', 'perf/latest.json'));
const compareFile = arg('compare', '') && resolve(root, arg('compare', ''));
const RUNS = Number(arg('runs', '3'));
const dist = join(root, 'dist');
if (!existsSync(join(dist, 'index.html'))) { console.error('Run `npm run build` first.'); process.exit(2); }

const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.webp': 'image/webp', '.png': 'image/png', '.svg': 'image/svg+xml', '.woff2': 'font/woff2', '.json': 'application/json', '.webmanifest': 'application/manifest+json', '.jpg': 'image/jpeg' };
const server = createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]); if (p === '/') p = '/index.html';
  const f = join(dist, p);
  if (!f.startsWith(dist) || !existsSync(f) || statSync(f).isDirectory()) { res.statusCode = 404; res.end(); return; }
  res.setHeader('content-type', MIME[extname(f)] || 'application/octet-stream'); res.end(readFileSync(f));
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const base = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch(process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {});

const PROFILES = {
  phone: { context: { ...devices['Pixel 7'] }, cpu: 4 },
  desktop: { context: { viewport: { width: 1280, height: 800 } }, cpu: 1 },
};
const median = (xs) => { const s = [...xs].sort((a, b) => a - b); return s[Math.floor(s.length / 2)]; };
const round = (x, d = 1) => Math.round(x * 10 ** d) / 10 ** d;

/** Frame times for `ms` milliseconds of whatever the page is doing. */
async function frames(page, ms = 5000) {
  const deltas = await page.evaluate((ms) => new Promise((done) => {
    const out = []; let last = performance.now(); const end = last + ms;
    const tick = (t) => { out.push(t - last); last = t; if (t < end) requestAnimationFrame(tick); else done(out.slice(2)); };
    requestAnimationFrame(tick);
  }), ms);
  const avg = deltas.reduce((a, b) => a + b, 0) / deltas.length;
  const sorted = [...deltas].sort((a, b) => a - b);
  const p99 = sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * 0.99))];
  return { avgMs: round(avg, 2), fps: round(1000 / avg), low1Fps: round(1000 / p99), worstMs: round(sorted[sorted.length - 1]), samples: deltas.length };
}
async function heapMB(cdp) {
  await cdp.send('HeapProfiler.collectGarbage').catch(() => {});
  const { metrics } = await cdp.send('Performance.getMetrics');
  const m = Object.fromEntries(metrics.map((x) => [x.name, x.value]));
  return round(m.JSHeapUsedSize / 1048576);
}

async function runOnce(name, prof) {
  const ctx = await browser.newContext({ ...prof.context, serviceWorkers: 'block' });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  const cdp = await ctx.newCDPSession(page);
  await cdp.send('Performance.enable');
  if (prof.cpu > 1) await cdp.send('Emulation.setCPUThrottlingRate', { rate: prof.cpu });
  await page.addInitScript(() => { if (!sessionStorage.getItem('bench')) { sessionStorage.setItem('bench', '1'); localStorage.clear(); localStorage.setItem('alien-sudoku:profile', JSON.stringify({ settings: { seenTutorial: true } })); } });
  const t0 = Date.now();
  await page.goto(`${base}/#e2e`);
  await page.waitForSelector('.screen-menu', { state: 'visible' });
  const coldStartMs = await page.evaluate(() => Math.round(performance.now()));
  const wallMs = Date.now() - t0;
  await page.waitForTimeout(1500);
  const r = { coldStartMs, wallMs, heap: {}, frames: {} };
  r.heap.menu = await heapMB(cdp);
  r.frames.menu = await frames(page);
  await page.locator('.menu-quick').click();
  await page.locator('.diff-option.diff-medium').click();
  await page.waitForSelector('.screen-play');
  await page.waitForTimeout(1000);
  await page.locator('.cell:not(.fixed)').first().dispatchEvent('pointerdown');
  r.frames.play = await frames(page);
  r.heap.play = await heapMB(cdp);
  r.domNodes = await page.evaluate(() => document.getElementsByTagName('*').length);
  await page.reload();
  await page.waitForSelector('.screen-menu', { state: 'visible' });
  await page.locator('.menu-campaign').click();
  await page.locator('.sector-card').first().click();
  await page.waitForSelector('.level-map');
  await page.waitForTimeout(800);
  r.frames.map = await frames(page);
  r.heap.map = await heapMB(cdp);
  r.errors = errors;
  await ctx.close();
  return r;
}

const result = { date: new Date().toISOString(), version: JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')).version, runs: RUNS, profiles: {} };
for (const [name, prof] of Object.entries(PROFILES)) {
  const runs = [];
  for (let i = 0; i < RUNS; i++) runs.push(await runOnce(name, prof));
  const pick = (f) => median(runs.map(f));
  const scene = (s) => ({
    avgMs: pick((r) => r.frames[s].avgMs), fps: pick((r) => r.frames[s].fps),
    low1Fps: pick((r) => r.frames[s].low1Fps), worstMs: pick((r) => r.frames[s].worstMs),
  });
  result.profiles[name] = {
    coldStartMs: pick((r) => r.coldStartMs),
    heapMB: { menu: pick((r) => r.heap.menu), play: pick((r) => r.heap.play), map: pick((r) => r.heap.map) },
    domNodes: pick((r) => r.domNodes),
    frames: { menu: scene('menu'), play: scene('play'), map: scene('map') },
    errors: [...new Set(runs.flatMap((r) => r.errors))],
  };
}
await browser.close(); server.close();
mkdirSync(dirname(outFile), { recursive: true });
writeFileSync(outFile, JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result.profiles, null, 1));

if (compareFile) {
  const b = JSON.parse(readFileSync(compareFile, 'utf8'));
  const worse = [];
  const check = (label, now, then, higherIsBetter) => {
    if (then == null || now == null) return;
    const change = higherIsBetter ? (then - now) / then : (now - then) / then;
    if (change > 0.05) worse.push(`${label}: ${then} -> ${now} (${Math.round(change * 100)}% worse)`);
  };
  for (const p of Object.keys(result.profiles)) {
    const n = result.profiles[p], o = b.profiles[p];
    if (!o) continue;
    check(`${p} cold start ms`, n.coldStartMs, o.coldStartMs, false);
    check(`${p} heap MB (play)`, n.heapMB.play, o.heapMB.play, false);
    for (const s of ['menu', 'play', 'map']) {
      check(`${p} ${s} avg frame ms`, n.frames[s].avgMs, o.frames[s].avgMs, false);
      check(`${p} ${s} 1% low fps`, n.frames[s].low1Fps, o.frames[s].low1Fps, true);
    }
  }
  if (worse.length) { console.error('Worse than baseline by more than 5%:\n  ' + worse.join('\n  ')); process.exit(1); }
  console.log('Within 5% of the baseline or better.');
}
