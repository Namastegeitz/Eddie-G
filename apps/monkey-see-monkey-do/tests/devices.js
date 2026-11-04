// Phone checks for the built game (dist/www):
//  1. inside a simulated iOS/Android app shell (a fake Capacitor bridge that
//     records calls): status bar, splash, back button, haptics, keep-awake,
//     pausing in the background, no service worker
//  2. older phones: WebGL 1 forced with ?gl=1
//  3. screen sizes from a 320 px phone to a tablet, and a phone held sideways
//
//   (cd dist/www && python3 -m http.server 8766 --bind 127.0.0.1) &
//   node tests/devices.js          (screenshots in tests/output/devices/)
const { chromium, devices } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE = process.env.BASE || 'http://127.0.0.1:8766/';
const OUT = path.join(process.env.OUT || path.join(__dirname, 'output'), 'devices');
fs.mkdirSync(OUT, { recursive: true });
let pass = 0;
let fail = 0;
const expect = (c, m) => { if (!c) throw new Error(m); };

const FAKE_BRIDGE = (platform) => `
  window.__calls = [];
  window.__listeners = {};
  window.Capacitor = {
    getPlatform: () => '${platform}',
    isNativePlatform: () => true,
    PluginHeaders: ['App', 'Haptics', 'KeepAwake', 'SplashScreen', 'SystemBars'].map((name) => ({ name, methods: [] })),
    nativePromise: (p, m, o) => { window.__calls.push(p + '.' + m + ' ' + JSON.stringify(o || {})); return Promise.resolve({}); },
    addListener: (p, e, cb) => { (window.__listeners[p + '.' + e] = window.__listeners[p + '.' + e] || []).push(cb); return { remove() {} }; },
  };
  window.__fire = (k, d) => (window.__listeners[k] || []).forEach((cb) => cb(d || {}));
`;

(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const run = async (name, fn) => {
    try { await fn(); pass++; console.log('✓', name); } catch (e) { fail++; console.log('✗', name, '-', e.message.split('\n')[0]); }
  };
  const open = async (ctxOpts, url = BASE, init = null) => {
    const ctx = await browser.newContext({ deviceScaleFactor: 1, ...ctxOpts });
    if (init) await ctx.addInitScript(init);
    const page = await ctx.newPage();
    page.errors = [];
    page.on('pageerror', (e) => page.errors.push(e.message));
    page.on('console', (m) => { if (m.type() === 'error') page.errors.push(m.text()); });
    await page.goto(url);
    await page.waitForSelector('html[data-ready="1"]', { timeout: 30000 });
    return page;
  };
  const calls = (page) => page.evaluate(() => window.__calls.slice());

  // ---------------------------------------------------------------- app shell
  let page;
  await run('Android app shell: hides status bar and splash, no service worker', async () => {
    page = await open({ viewport: { width: 393, height: 851 }, hasTouch: true, isMobile: true }, BASE, FAKE_BRIDGE('android'));
    await page.waitForTimeout(400);
    const c = await calls(page);
    expect(c.some((x) => x.startsWith('SystemBars.hide')), 'status bar ' + c);
    expect(c.some((x) => x.startsWith('SplashScreen.hide')), 'splash ' + c);
    expect(await page.evaluate(() => MSMD.platform) === 'android', 'platform');
    expect(await page.evaluate(() => document.documentElement.dataset.platform) === 'android', 'html data-platform');
    const sw = await page.evaluate(() => navigator.serviceWorker.getRegistrations().then((r) => r.length));
    expect(sw === 0, 'service worker registered in app');
  });

  await run('Android back button: screens, cards, pause, then minimise at the title', async () => {
    const back = () => page.evaluate(() => window.__fire('App.backButton'));
    await page.tap('#scr-title .mini[data-go="settings"]');
    await back();
    expect(await page.evaluate(() => MSMD.ui.current) === 'title', 'settings -> title');
    await page.evaluate(() => MSMD.game.openLevel(1));
    await page.waitForSelector('#ov-intro.show');
    await back();
    expect(await page.evaluate(() => MSMD.ui.current) === 'map', 'level card -> map');
    await back();
    await page.tap('#btn-free');
    await back();
    expect(await page.evaluate(() => MSMD.game.paused), 'free dance -> paused');
    await back();
    expect(!(await page.evaluate(() => MSMD.game.paused)), 'back again resumes');
    await page.evaluate(() => { MSMD.game.quit(); MSMD.ui.show('title'); window.__calls.length = 0; });
    await back();
    expect((await calls(page)).some((x) => x.startsWith('App.minimizeApp')), 'title -> minimise');
  });

  await run('app shell: haptics on taps, screen kept awake while playing, pause in background', async () => {
    await page.evaluate(() => { window.__calls.length = 0; });
    await page.tap('#btn-free');
    await page.tap('#pad [data-move="LA"]');
    await page.waitForTimeout(100);
    let c = await calls(page);
    expect(c.some((x) => x.startsWith('KeepAwake.keepAwake')), 'keep awake ' + c);
    await page.evaluate(() => MSMD.game.openLevel(1));
    await page.tap('#intro-go');
    await page.waitForFunction(() => MSMD.game.phase === 'respond', null, { timeout: 20000 });
    await page.evaluate(() => { window.__calls.length = 0; });
    const exp = await page.evaluate(() => MSMD.game.run.expected[0][0]);
    await page.tap(`#pad [data-move="${exp}"]`);
    c = await calls(page);
    expect(c.some((x) => x.startsWith('Haptics.impact')), 'haptic impact ' + c);
    await page.evaluate(() => window.__fire('App.pause'));
    expect(await page.evaluate(() => MSMD.game.paused), 'paused when app goes to background');
    await page.screenshot({ path: path.join(OUT, 'android-shell-paused.png') });
    await page.evaluate(() => { window.__calls.length = 0; MSMD.game.quit(); MSMD.ui.show('title'); });
    await page.waitForTimeout(100);
    c = await calls(page);
    expect(c.some((x) => x.startsWith('KeepAwake.allowSleep')), 'sleep allowed on menus ' + c);
    expect(page.errors.length === 0, page.errors.join(' | '));
  });

  await run('iOS app shell boots with haptics bridge', async () => {
    const p = await open({ ...devices['iPhone 13'] }, BASE, FAKE_BRIDGE('ios'));
    expect(await p.evaluate(() => MSMD.platform) === 'ios', 'platform');
    await p.tap('#btn-free');
    await p.tap('#pad [data-move="HD"]');
    expect((await calls(p)).some((x) => x.startsWith('Haptics.impact')), 'haptics');
    expect(p.errors.length === 0, p.errors.join(' | '));
    await p.context().close();
  });

  // ---------------------------------------------------------------- older phones
  await run('WebGL 1 fallback (older Android GPUs) renders and plays', async () => {
    const p = await open({ viewport: { width: 360, height: 740 }, hasTouch: true, isMobile: true }, BASE + '?gl=1');
    expect(await p.evaluate(() => MSMD.webgl) === 1, 'expected WebGL 1');
    await p.tap('#btn-free');
    for (const m of ['LA', 'RL', 'HD', 'FL']) await p.tap(`#pad [data-move="${m}"]`);
    expect(await p.evaluate(() => MSMD.game.run.moves) === 4, 'moves');
    await p.waitForTimeout(300);
    await p.screenshot({ path: path.join(OUT, 'webgl1-360x740.png') });
    expect(p.errors.length === 0, p.errors.join(' | '));
    await p.context().close();
  });

  // ---------------------------------------------------------------- sizes
  const sizes = [
    ['small Android 320x568', { viewport: { width: 320, height: 568 }, hasTouch: true, isMobile: true }],
    ['iPhone SE', devices['iPhone SE']],
    ['Galaxy S9+', devices['Galaxy S9+']],
    ['Pixel 7', devices['Pixel 7']],
    ['iPhone 15 Pro Max', devices['iPhone 15 Pro Max'] || devices['iPhone 14 Pro Max']],
    ['iPad Mini', devices['iPad Mini']],
  ];
  for (const [name, dev] of sizes) {
    await run(`fits on ${name}`, async () => {
      const p = await open({ ...dev, deviceScaleFactor: 1 });
      const check = async (where) => {
        const r = await p.evaluate(() => {
          const W = innerWidth, H = innerHeight;
          const off = [];
          for (const el of document.querySelectorAll('.screen.show button, .screen.show .pad-btn')) {
            const b = el.getBoundingClientRect();
            if (b.width === 0 || el.closest('[hidden]')) continue;
            if (b.left < -1 || b.right > W + 1 || b.bottom > H + 1 || b.top < -1) off.push((el.id || el.className || el.textContent).toString().slice(0, 30));
          }
          return { off, scroll: document.documentElement.scrollWidth > W + 1 };
        });
        expect(!r.scroll, `${where}: page scrolls sideways`);
        expect(r.off.length === 0, `${where}: off screen: ${r.off.join(', ')}`);
      };
      await check('title');
      await p.screenshot({ path: path.join(OUT, `${name.replace(/\W+/g, '_')}-title.png`) });
      await p.evaluate(() => { MSMD.Save.data.tutorialDone = true; MSMD.game.openLevel(5); });
      await p.evaluate(() => { MSMD.Save.data.levels[4] = { stars: 1, best: 1, clears: 1 }; });
      await p.tap('#intro-go');
      await p.waitForFunction(() => MSMD.game.phase === 'respond', null, { timeout: 25000 });
      await check('game');
      await p.screenshot({ path: path.join(OUT, `${name.replace(/\W+/g, '_')}-game.png`) });
      expect(p.errors.length === 0, p.errors.join(' | '));
      await p.context().close();
    });
  }

  await run('phone held sideways in a browser shows "turn upright" and pauses', async () => {
    const p = await open({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true });
    expect(await p.isVisible('#rotate'), 'rotate overlay visible');
    await p.setViewportSize({ width: 390, height: 844 });
    await p.waitForTimeout(200);
    expect(!(await p.isVisible('#rotate')), 'hidden when upright');
    await p.tap('#btn-free');
    await p.setViewportSize({ width: 844, height: 390 });
    await p.waitForTimeout(300);
    expect(await p.evaluate(() => MSMD.game.paused), 'paused when turned sideways');
    await p.screenshot({ path: path.join(OUT, 'sideways.png') });
    await p.context().close();
  });

  console.log(`\n${pass} passed, ${fail} failed`);
  await browser.close();
  process.exit(fail ? 1 : 0);
})();
