// Real-browser check of the web build: loads it in headless Chromium as a
// phone (touch), taps the title screen and saves before/after screenshots.
// tools/web_tap_test.sh runs it and checks the screen actually changed.
//   node tools/web_tap_test.js <url> <out_prefix>
const { chromium } = require('playwright');
(async () => {
  const [url, out] = process.argv.slice(2);
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const ctx = await b.newContext({ viewport: { width: 960, height: 540 }, hasTouch: true, isMobile: true });
  const p = await ctx.newPage();
  const errs = [];
  p.on('pageerror', e => errs.push(e.message));
  p.on('console', m => { if (m.type() === 'error') errs.push(m.text().slice(0, 200)); });
  await p.goto(url);
  await p.waitForFunction(() => window.__bev && window.__bev.done, null, { timeout: 300000 });
  await p.waitForTimeout(6000);
  await p.screenshot({ path: out + '_before.png', timeout: 300000 });
  await p.touchscreen.tap(480, 300);
  await p.waitForTimeout(10000);
  await p.screenshot({ path: out + '_after.png', timeout: 300000 });
  console.log('page errors: ' + errs.length);
  errs.slice(0, 10).forEach(e => console.log('  ' + e));
  await b.close();
})().catch(e => { console.log('FAILED ' + e.message); process.exit(1); });
