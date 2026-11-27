// Quick smoke test of the built game (dist/www), for CI on every push:
// it starts, reaches the title with no errors, a move plays in Free Dance,
// Settings opens, and a fake game controller plays a move.
//   (cd dist/www && python3 -m http.server 8766 --bind 127.0.0.1) &
//   node tests/smoke.js
const { chromium } = require('playwright');

const BASE = process.env.BASE || 'http://127.0.0.1:8766/';
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  await page.addInitScript(() => {
    window.MSMD_NO_SW = true;
    window.__pad = { id: 'Xbox Wireless Controller (STANDARD GAMEPAD)', index: 0, connected: true, mapping: 'standard', axes: [0, 0, 0, 0], buttons: Array.from({ length: 17 }, () => ({ pressed: false, value: 0 })) };
    navigator.getGamepads = () => [window.__pad];
  });
  const fail = (m) => { console.log('FAIL:', m); process.exitCode = 1; };
  try {
    await page.goto(BASE);
    await page.waitForSelector('html[data-ready="1"]', { timeout: 120000 });
    await page.waitForSelector('#scr-title.show');
    console.log('✓ starts and shows the title, version', await page.evaluate(() => MSMD.version));
    await page.click('#btn-free');
    await page.waitForFunction(() => MSMD.game.mode === 'free', null, { timeout: 30000 });
    await page.keyboard.press('q');
    await page.waitForFunction(() => MSMD.game.run.moves >= 1, null, { timeout: 10000 });
    console.log('✓ a keyboard move plays in Free Dance');
    await page.evaluate(() => { window.__pad.buttons[5] = { pressed: true, value: 1 }; });
    await page.waitForFunction(() => MSMD.game.run.moves >= 2, null, { timeout: 15000 });
    await page.evaluate(() => { window.__pad.buttons[5] = { pressed: false, value: 0 }; });
    console.log('✓ a controller button plays a move');
    await page.evaluate(() => { MSMD.game.quit(); MSMD.ui.show('settings'); });
    await page.waitForSelector('#act-report');
    console.log('✓ Settings opens with Report a problem');
  } catch (e) {
    fail(e.message.split('\n')[0]);
  }
  if (errors.length) fail('page errors: ' + errors.join(' | '));
  await browser.close();
  if (!process.exitCode) console.log('Smoke test passed');
})();
