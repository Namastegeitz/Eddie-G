// Checks the public beta website as an iPhone, an Android phone and a desktop
// browser: landing page, QR code, Play button into the game, one round of
// level 1, privacy and support pages, the game reopening offline, and that
// the Off-Grid Survival Kit (the rest of the GitHub Pages site) still works
// and its offline service worker doesn't take over these pages.
//
//   SITE=https://namastegeitz.github.io/Eddie-G/ node tests/beta_site.js    (live)
//   SITE=http://127.0.0.1:8791/Eddie-G/ node tests/beta_site.js             (local copy)
// Screenshots go to tests/output/beta-site/.
const { chromium, devices } = require('playwright');
const path = require('path');
const fs = require('fs');

const SITE = (process.env.SITE || 'https://namastegeitz.github.io/Eddie-G/').replace(/\/?$/, '/');
const BETA = SITE + 'monkey-see-monkey-do/';
const OUT = path.join(process.env.OUT || path.join(__dirname, 'output'), 'beta-site');
fs.mkdirSync(OUT, { recursive: true });
const remote = !/^http:\/\/(127\.0\.0\.1|localhost)/.test(SITE);
let pass = 0;
let fail = 0;
const expect = (c, m) => { if (!c) throw new Error(m); };

const PROFILES = [
  { name: 'iPhone', ctx: { ...devices['iPhone 13'] } },
  { name: 'Android phone', ctx: { ...devices['Pixel 7'] } },
  { name: 'desktop', ctx: { viewport: { width: 1366, height: 800 } }, offGridFirst: true },
];

(async () => {
  const browser = await chromium.launch({
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
    ...(remote && process.env.HTTPS_PROXY ? { proxy: { server: process.env.HTTPS_PROXY } } : {}),
  });
  const run = async (name, fn) => {
    try { await fn(); pass++; console.log('✓', name); } catch (e) { fail++; console.log('✗', name, '-', e.message.split('\n')[0]); }
  };
  const swScript = (page) => page.evaluate(() => (navigator.serviceWorker.controller || {}).scriptURL || '');

  for (const prof of PROFILES) {
    const ctx = await browser.newContext({ deviceScaleFactor: 1, ...prof.ctx });
    const page = await ctx.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(e.message));
    const tag = prof.name.replace(/\W+/g, '-').toLowerCase();

    if (prof.offGridFirst) {
      await run(`${prof.name}: Off-Grid Survival Kit still opens (and installs its offline worker)`, async () => {
        const res = await page.goto(SITE);
        expect(res.ok(), 'status ' + res.status());
        expect((await page.title()).includes('Off-Grid'), 'title ' + (await page.title()));
        await page.evaluate(() => navigator.serviceWorker.ready);
      });
    }

    await run(`${prof.name}: landing page, icon and QR code`, async () => {
      const res = await page.goto(BETA);
      expect(res.ok(), 'status ' + res.status());
      expect((await page.textContent('h1')).includes('Monkey See, Monkey Do'), 'heading');
      await page.waitForFunction(() => [...document.images].every((i) => i.complete && i.naturalWidth > 0), null, { timeout: 15000 });
      expect(!(await page.textContent('footer')).includes('__BUILD__'), 'build stamp filled in');
      await page.screenshot({ path: path.join(OUT, `${tag}-1-landing.png`) });
    });

    await run(`${prof.name}: Play opens the game and level 1 plays a round`, async () => {
      await page.click('a.play');
      await page.waitForURL(/\/monkey-see-monkey-do\/play\/$/);
      await page.waitForSelector('html[data-ready="1"]', { timeout: 60000 });
      await page.waitForSelector('#scr-title.show');
      await page.screenshot({ path: path.join(OUT, `${tag}-2-title.png`) });
      await page.click('#btn-play');
      await page.waitForSelector('#ov-howto.show');
      for (let i = 0; i < 3; i++) await page.click('#howto-next');
      await page.waitForSelector('#ov-intro.show');
      await page.evaluate(() => document.querySelector('#intro-go').click());
      await page.waitForFunction(() => MSMD.game.phase === 'watch', null, { timeout: 20000 });
      await page.waitForFunction(() => MSMD.game.phase === 'respond', null, { timeout: 30000 });
      const steps = await page.evaluate(() => MSMD.game.run.expected);
      for (const st of steps) {
        await page.click(`#pad [data-move="${st[0]}"]`);
        await page.waitForTimeout(60);
      }
      await page.waitForFunction(() => MSMD.game.phase !== 'respond', null, { timeout: 15000 });
      await page.screenshot({ path: path.join(OUT, `${tag}-3-played.png`) });
      expect(!errors.length, 'page errors: ' + errors.join(' | '));
    });

    await run(`${prof.name}: privacy and support pages`, async () => {
      for (const [f, word] of [['privacy.html', 'Privacy'], ['support.html', 'Support']]) {
        const p = await ctx.newPage();
        const res = await p.goto(BETA + f);
        expect(res.ok(), f + ' status ' + res.status());
        expect((await p.textContent('body')).includes(word), f + ' text');
        await p.close();
      }
    });

    await run(`${prof.name}: each page runs under its own service worker, game reopens offline`, async () => {
      await page.goto(BETA + 'play/');
      await page.waitForSelector('html[data-ready="1"]', { timeout: 60000 });
      await page.evaluate(() => navigator.serviceWorker.ready);
      await page.reload();
      await page.waitForSelector('html[data-ready="1"]', { timeout: 60000 });
      const game = await swScript(page);
      expect(game.endsWith('/monkey-see-monkey-do/play/sw.js'), 'game controlled by ' + game);
      await page.goto(BETA);
      await page.evaluate(() => navigator.serviceWorker.ready);
      await page.reload();
      const landing = await swScript(page);
      expect(landing.endsWith('/monkey-see-monkey-do/sw.js'), 'landing controlled by ' + landing);
      await ctx.setOffline(true);
      await page.goto(BETA + 'play/');
      await page.waitForSelector('html[data-ready="1"]', { timeout: 60000 });
      await page.waitForSelector('#scr-title.show');
      await ctx.setOffline(false);
    });

    await ctx.close();
  }
  await browser.close();
  console.log(`\nBeta site ${SITE}: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})();
