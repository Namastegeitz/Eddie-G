// Performance benchmark (Step 9 of the upgrade prompt). Records, on the built game:
//   - cold start: page open to playable (html[data-ready])
//   - JS memory after start and after a level
//   - per stage (jungle, beach, disco, moon) x graphics (low, high): draw calls,
//     triangles, shader programs, and the time to draw one frame (fastest of 11)
//   - first-use stutter: building + compiling a stage the first time it's shown
//   - frame times while playing level 1 (average, 1% low, worst spike)
// Results: tests/output/benchmark.json. With tests/benchmark-baseline.json present
// it compares and exits 1 if anything is more than 5% worse: draw calls and
// triangles per stage, and the total frame draw time over all 8 stage/graphics
// pairs. A single pair's time may vary up to BENCH_TIME_TOL (default 15%),
// because the software renderer's timings wobble about 10% run to run.
//
// The test machine draws with a software renderer (no GPU), so times are far
// slower than a phone; they are for before/after comparison on the same machine.
//   (cd dist/www && python3 -m http.server 8766 --bind 127.0.0.1) &
//   node tests/benchmark.js               compare with the baseline
//   node tests/benchmark.js --save        make this run the new baseline
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE = process.env.BASE || 'http://127.0.0.1:8766/';
const OUT = path.join(__dirname, 'output');
const BASELINE = path.join(__dirname, 'benchmark-baseline.json');
const TOL = 0.05;
const TIME_TOL = Number(process.env.BENCH_TIME_TOL || 0.15);
fs.mkdirSync(OUT, { recursive: true });

const STAGES = ['jungle', 'beach', 'disco', 'moon'];
const LEVELS = ['low', 'high'];

async function openPage(browser) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
  await ctx.addInitScript(() => { window.MSMD_NO_SW = true; try { localStorage.clear(); } catch (e) { /* fresh */ } });
  const page = await ctx.newPage();
  page.errors = [];
  page.on('pageerror', (e) => page.errors.push(e.message));
  return page;
}

(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--enable-precise-memory-info'] });
  const res = { when: new Date().toISOString(), base: BASE, viewport: '390x844@1x', renderer: 'SwiftShader (software)' };

  // ---- cold start + first-use stutter (fresh page: only the jungle is built at start)
  let page = await openPage(browser);
  const t0 = Date.now();
  await page.goto(BASE);
  await page.waitForSelector('html[data-ready="1"]', { timeout: 120000 });
  res.coldStartMs = Date.now() - t0;
  res.heapAfterStartMB = await page.evaluate(() => +(performance.memory.usedJSHeapSize / 1048576).toFixed(1));
  await page.evaluate(() => { MSMD.Save.settings.quality = 'low'; MSMD.app.setLevel('low'); });
  res.firstUseMs = await page.evaluate(() => {
    const st = MSMD.stage, R = st.renderer, gl = R.getContext(), px = new Uint8Array(4);
    const out = {};
    for (const id of ['beach', 'disco', 'moon']) {
      const t = performance.now();
      st.setEnvironment(id);
      R.render(st.scene, st.camera);
      gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, px);
      out[id] = Math.round(performance.now() - t);
    }
    st.setEnvironment('jungle');
    return out;
  });
  res.firstUseWorstMs = Math.max(...Object.values(res.firstUseMs));

  // ---- per stage x graphics level: draw calls, triangles, frame draw time
  res.stages = await page.evaluate(({ STAGES, LEVELS }) => {
    const st = MSMD.stage, R = st.renderer, gl = R.getContext(), px = new Uint8Array(4);
    const sync = () => gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, px);
    // a still monkey with no sparks or trails, so every run draws the same scene
    const settle = () => {
      MSMD.monkey.stop();
      let t = 1000;
      for (let i = 0; i < 80; i++) { t += 0.05; MSMD.monkey.update(t, 0.05, 0); st.update(t, 0.05, 0, MSMD.monkey); }
    };
    const out = {};
    for (const lvl of LEVELS) {
      MSMD.app.setLevel(lvl);
      for (const id of STAGES) {
        st.setEnvironment(id);
        settle();
        R.render(st.scene, st.camera); sync(); // compile
        R.render(st.scene, st.camera); sync();
        const info = R.info;
        const calls = info.render.calls, tris = info.render.triangles;
        let best = Infinity;
        for (let i = 0; i < 11; i++) {
          const t = performance.now();
          R.render(st.scene, st.camera); sync();
          best = Math.min(best, performance.now() - t);
        }
        out[`${id}/${lvl}`] = { drawCalls: calls, triangles: tris, programs: info.programs.length, drawMs: Math.round(best) };
      }
    }
    MSMD.app.setLevel('low');
    st.setEnvironment('jungle');
    return out;
  }, { STAGES, LEVELS });

  // ---- playing level 1: frame times for 8 seconds (graphics Low)
  await page.click('#btn-play');
  await page.waitForSelector('#ov-howto.show');
  for (let i = 0; i < 3; i++) await page.click('#howto-next');
  await page.waitForSelector('#ov-intro.show');
  await page.evaluate(() => document.querySelector('#intro-go').click());
  await page.waitForFunction(() => MSMD.game.phase === 'watch', null, { timeout: 60000 });
  res.play = await page.evaluate(() => new Promise((done) => {
    const dts = [];
    let last = performance.now();
    const t0 = last;
    const f = (now) => {
      dts.push(now - last);
      last = now;
      if (now - t0 < 8000) requestAnimationFrame(f);
      else {
        dts.shift();
        const sorted = dts.slice().sort((a, b) => a - b);
        const avg = dts.reduce((a, b) => a + b, 0) / dts.length;
        const p99 = sorted[Math.floor(sorted.length * 0.99)] || sorted[sorted.length - 1];
        done({ frames: dts.length, avgMs: +avg.toFixed(1), avgFps: +(1000 / avg).toFixed(1), low1pctFps: +(1000 / p99).toFixed(1), worstMs: Math.round(sorted[sorted.length - 1]), spikesOver2x: dts.filter((d) => d > 2 * avg).length });
      }
    };
    requestAnimationFrame(f);
  }));
  res.heapAfterPlayMB = await page.evaluate(() => +(performance.memory.usedJSHeapSize / 1048576).toFixed(1));
  res.pageErrors = page.errors.slice(0, 5);
  await browser.close();

  fs.writeFileSync(path.join(OUT, 'benchmark.json'), JSON.stringify(res, null, 2));
  console.log(JSON.stringify(res, null, 2));

  if (process.argv.includes('--save')) {
    fs.writeFileSync(BASELINE, JSON.stringify(res, null, 2));
    console.log('\nSaved as the new baseline: tests/benchmark-baseline.json');
    return;
  }
  if (!fs.existsSync(BASELINE)) { console.log('\nNo baseline yet (run with --save).'); return; }
  const base = JSON.parse(fs.readFileSync(BASELINE, 'utf8'));
  const fails = [];
  const worse = (name, now, was, tol) => { if (was > 0 && now > was * (1 + tol)) fails.push(`${name}: ${now} vs ${was} (+${Math.round((now / was - 1) * 100)}%)`); };
  for (const [k, v] of Object.entries(res.stages)) {
    const b = base.stages[k];
    if (!b) continue;
    worse(`${k} draw calls`, v.drawCalls, b.drawCalls, TOL);
    worse(`${k} triangles`, v.triangles, b.triangles, TOL);
    worse(`${k} frame draw ms`, v.drawMs, b.drawMs, TIME_TOL);
  }
  const total = (st) => Object.values(st).reduce((a, v) => a + v.drawMs, 0);
  res.totalDrawMs = total(res.stages);
  worse('total frame draw ms (all stages)', res.totalDrawMs, total(base.stages), TOL);
  worse('first-use worst ms', res.firstUseWorstMs, base.firstUseWorstMs, TIME_TOL);
  if (res.pageErrors.length) fails.push('page errors: ' + res.pageErrors.join(' | '));
  if (fails.length) { console.log('\nWORSE THAN BASELINE:\n- ' + fails.join('\n- ')); process.exit(1); }
  console.log('\nAt or better than the baseline on every check.');
})();
