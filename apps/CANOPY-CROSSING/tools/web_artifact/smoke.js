#!/usr/bin/env node
// Web build smoke test, run by tools/build_web.sh after every web build.
// Serves the packaged build, opens it in a phone-sized touch browser, taps
// the eye button the way a finger does, and checks that first person really
// shows (the game reports its view, and the picture changes to a 3D scene),
// that the tap did not also hop the animal, and that a second tap goes back.
// Then the X key switches back and forth, a tablet's finger taps do too,
// and so does a mouse click on a desktop-sized window.
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

// Does `act` (a tap, click or key press), then waits for the game to report
// a different view and lets it settle; returns the game's state.
async function switched(page, act) {
  const g = await page.evaluate(() => window.__canopy.game);
  await act();
  const t0 = Date.now();
  let now = g;
  while (Date.now() - t0 < 6000) {
    now = await page.evaluate(() => window.__canopy.game);
    if (now.view !== g.view) break;
    await page.waitForTimeout(40);
  }
  await page.waitForTimeout(600);
  return await page.evaluate(() => window.__canopy.game);
}

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
    // the page must lay out at the phone's width (viewport meta), or a phone
    // renders the game at desktop width and several times the pixels
    const lay = await page.evaluate(() => { const c = document.getElementById('canvas'); return { w: window.innerWidth, cw: c.width }; });
    console.log(`layout ${lay.w} px wide, canvas ${lay.cw} px`);
    if (lay.w > 500) fail(`the page lays out ${lay.w} px wide on a 390 px phone (missing viewport meta?)`);
    if (lay.cw > lay.w * 2 + 2) fail(`the canvas is ${lay.cw} px for a ${lay.w} px wide page (more than 2x)`);
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
    // the X key switches back and forth too
    for (const want of ['fpv', 'bird']) {
      const g = await switched(page, () => page.keyboard.press('x'));
      console.log(`key X: -> ${g.view}`);
      if (g.view !== want) fail(`pressing X did not switch to ${want}: ` + JSON.stringify(g));
      if (g.row !== g0.row) fail(`pressing X also hopped the animal (row ${g0.row} -> ${g.row})`);
    }
    // a tablet (finger) and a desktop window (mouse click)
    for (const dev of [
      { name: 'tablet tap', opts: { viewport: { width: 820, height: 1180 }, isMobile: true, hasTouch: true, deviceScaleFactor: 2 }, how: 'tap' },
      { name: 'desktop click', opts: { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 }, how: 'click' },
    ]) {
      const c2 = await browser.newContext(dev.opts);
      const p2 = await c2.newPage();
      p2.on('pageerror', e => errors.push(e.message));
      await p2.goto(url);
      await p2.waitForFunction(() => window.__canopy && window.__canopy.done, null, { timeout: 180000 });
      await p2.waitForFunction(() => window.__canopy.game && window.__canopy.game.eye[0] > 0 && window.__canopy.game.warm, null, { timeout: 90000 });
      await p2.keyboard.press('F2');
      await p2.waitForTimeout(1500);
      const b2 = await p2.locator('#canvas').boundingBox();
      const start = await p2.evaluate(() => window.__canopy.game);
      for (const want of [start.view === 'bird' ? 'fpv' : 'bird', start.view]) {
        const g = await switched(p2, async () => {
          const e = (await p2.evaluate(() => window.__canopy.game)).eye;
          const x = b2.x + e[0] * b2.width, y = b2.y + e[1] * b2.height;
          if (dev.how === 'tap') await p2.touchscreen.tap(x, y); else await p2.mouse.click(x, y);
        });
        console.log(`${dev.name}: -> ${g.view}`);
        if (g.view !== want) fail(`${dev.name} on the eye button did not switch to ${want}: ` + JSON.stringify(g));
        if (g.row !== start.row) fail(`${dev.name} also hopped the animal`);
        await p2.waitForTimeout(400);
      }
      await c2.close();
    }
    const fatal = errors.filter(e => /abort|RuntimeError|out of memory|unreachable|SCRIPT ERROR/i.test(e));
    if (fatal.length) fail('errors in the page: ' + fatal.slice(0, 5).join(' | '));
  } catch (e) {
    fail(String(e && e.message || e));
  } finally {
    await browser.close();
    srv.close();
  }
  if (!process.exitCode) console.log('web smoke: the view switches by touch on a phone and a tablet, by mouse click, and with the X key');
})();
