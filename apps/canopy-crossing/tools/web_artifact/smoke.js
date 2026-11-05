#!/usr/bin/env node
// Web build smoke test, run by tools/build_web.sh after every web build.
// Serves the packaged build, opens it in a phone-sized touch browser, taps
// the eye button the way a finger does, and checks that first person really
// shows (the game reports its view, and the picture changes to a 3D scene),
// that the tap did not also hop the animal, and that a second tap goes back.
//   node tools/web_artifact/smoke.js build/web_artifact canopy-crossing.html [shots-dir]
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const dir = path.resolve(process.argv[2] || 'build/web_artifact');
const page_name = process.argv[3] || 'canopy-crossing.html';
const shots = process.argv[4] || '';
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };

function serve() {
  return new Promise(resolve => {
    const srv = http.createServer((req, res) => {
      const f = path.join(dir, decodeURIComponent(req.url.split('?')[0]));
      if (!f.startsWith(dir) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); return res.end(); }
      res.writeHead(200, { 'Content-Type': TYPES[path.extname(f)] || 'application/octet-stream' });
      fs.createReadStream(f).pipe(res);
    });
    srv.listen(0, '127.0.0.1', () => resolve(srv));
  });
}

function fail(msg) { console.error('WEB SMOKE FAILED: ' + msg); process.exitCode = 1; }

(async () => {
  const srv = await serve();
  const url = `http://127.0.0.1:${srv.address().port}/${page_name}`;
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true, deviceScaleFactor: 3 });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error' || /SCRIPT ERROR|USER ERROR/.test(m.text())) errors.push(m.text()); });
  try {
    await page.goto(url);
    await page.waitForFunction(() => window.__canopy && window.__canopy.done, null, { timeout: 180000 });
    await page.waitForFunction(() => window.__canopy.game && window.__canopy.game.eye[0] > 0, null, { timeout: 30000 });
    // the game builds and warms up first person just after a level starts;
    // a real phone GPU does that in well under a second, software GL is slower
    await page.waitForFunction(() => window.__canopy.game && window.__canopy.game.warm, null, { timeout: 60000 });
    // the page's first user gesture unlocks audio, which takes a moment in
    // some browsers; get that out of the way with a key the game ignores
    await page.keyboard.press('F2');
    await page.waitForTimeout(1500);
    const box = await page.locator('#canvas').boundingBox();
    const g0 = await page.evaluate(() => window.__canopy.game);
    const shot0 = await page.screenshot();
    if (shots) fs.writeFileSync(path.join(shots, 'smoke_bird.png'), shot0);
    // tap like a finger, then time how long until the game reports the new
    // view: a slow first switch makes players tap again and flip it back
    const tap = async () => {
      const g = await page.evaluate(() => window.__canopy.game);
      // tap() returns once the page has taken the touch; time from there
      await page.touchscreen.tap(box.x + g.eye[0] * box.width, box.y + g.eye[1] * box.height);
      const t0 = Date.now();
      let now = g;
      while (Date.now() - t0 < 6000) {
        now = await page.evaluate(() => window.__canopy.game);
        if (now.view !== g.view) break;
        await page.waitForTimeout(40);
      }
      now.ms = Date.now() - t0;
      await page.waitForTimeout(800);
      const settled = await page.evaluate(() => window.__canopy.game);
      settled.ms = now.ms;
      console.log(`tap eye: ${g.view} -> ${settled.view}, ${now.ms} ms after the touch was delivered (this test browser renders in software at a few fps)`);
      return settled;
    };
    if (g0.view !== 'bird') fail('expected to start in bird\'s-eye, got ' + g0.view);
    const g1 = await tap();
    const shot1 = await page.screenshot();
    if (shots) fs.writeFileSync(path.join(shots, 'smoke_fpv.png'), shot1);
    if (g1.view !== 'fpv' || !g1.fpv3d) fail('a finger tap on the eye button did not switch to first person: ' + JSON.stringify(g1));
    if (g1.row !== g0.row) fail(`the tap also hopped the animal (row ${g0.row} -> ${g1.row})`);
    // the picture must actually change into a 3D scene
    const diff = await page.evaluate(async ([a, b]) => {
      const load = src => new Promise(r => { const i = new Image(); i.onload = () => r(i); i.src = 'data:image/png;base64,' + src; });
      const [ia, ib] = await Promise.all([load(a), load(b)]);
      const c = document.createElement('canvas'); c.width = 96; c.height = 208;
      const x = c.getContext('2d');
      const px = img => { x.drawImage(img, 0, 0, 96, 208); return x.getImageData(0, 0, 96, 208).data; };
      const pa = px(ia), pb = px(ib);
      let d = 0, sum = 0, sq = 0, n = 0;
      for (let i = 0; i < pa.length; i += 4) {
        d += Math.abs(pa[i] - pb[i]) + Math.abs(pa[i + 1] - pb[i + 1]) + Math.abs(pa[i + 2] - pb[i + 2]);
        const l = (0.2126 * pb[i] + 0.7152 * pb[i + 1] + 0.0722 * pb[i + 2]) / 255;
        sum += l; sq += l * l; n++;
      }
      const mean = sum / n;
      return { change: d / (n * 3 * 255), mean, contrast: Math.sqrt(Math.max(0, sq / n - mean * mean)) };
    }, [shot0.toString('base64'), shot1.toString('base64')]);
    console.log('first person picture: change %s, mean %s, contrast %s', diff.change.toFixed(3), diff.mean.toFixed(2), diff.contrast.toFixed(3));
    if (diff.change < 0.05) fail('the screen barely changed after switching to first person');
    if (diff.mean < 0.03 || diff.mean > 0.97 || diff.contrast < 0.03) fail('the first-person picture is blank or flat');
    const g2 = await tap();
    if (g2.view !== 'bird') fail('a second tap did not switch back to bird\'s-eye: ' + JSON.stringify(g2));
    const fatal = errors.filter(e => /abort|RuntimeError|out of memory|unreachable|SCRIPT ERROR/i.test(e));
    if (fatal.length) fail('errors in the page: ' + fatal.slice(0, 5).join(' | '));
  } catch (e) {
    fail(String(e && e.message || e));
  } finally {
    await browser.close();
    srv.close();
  }
  if (!process.exitCode) console.log('web smoke: first person works by touch in a phone browser');
})();
