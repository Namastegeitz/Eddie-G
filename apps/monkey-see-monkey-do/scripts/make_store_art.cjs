// Renders store art from the real game, at the exact pixel sizes each store wants:
//   release/00-shared/icons        Apple 1024, Google Play 512, desktop 1024/256
//   release/00-shared/art          Play feature graphic 1024x500, itch.io cover 630x500
//   release/06-steam/art           every Steam capsule and library image
//   release/00-shared/screenshots  iPhone 6.9", Android phone, iPad 13", desktop 1080p, Shop (for Apple's IAP review)
// Usage: node scripts/make_store_art.cjs [icons|art|steam|phone|android|ipad|desktop|all]
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const rel = (p) => path.join(root, 'release', p);
const PORT = 8790;
const BASE = `http://127.0.0.1:${PORT}/`;
const want = process.argv[2] || 'all';
const on = (k) => want === 'all' || want === k;

const svg = fs.readFileSync(path.join(root, 'assets/icons/icon.svg'), 'utf8');
const fullBleed = svg.replace('rx="112"', 'rx="0"');
const font = fs.readFileSync(path.join(root, 'assets/fonts/lilita-one.woff2')).toString('base64');
const KEYS = { LA: 'q', HD: 'w', RA: 'e', LL: 'a', FL: 's', RL: 'd' };

function logoHtml(size, align = 'center') {
  return `<div class="logo" style="font-size:${size}px;text-align:${align}">Monkey See,<br><span style="color:#fff8e6">Monkey Do</span></div>`;
}
const LOGO_CSS = `
  .logo { font-family: 'Lilita One', 'L', sans-serif; line-height: 0.95; color: #ffd23f; letter-spacing: 0.01em;
    -webkit-text-stroke: 0.06em #23160c; paint-order: stroke fill;
    text-shadow: 0 0.07em 0 #23160c, 0 0.12em 0.18em rgba(0,0,0,0.45); }
  .logo br + * { color: #fff8e6; }`;

async function main() {
  const server = spawn('python3', ['-m', 'http.server', String(PORT), '--bind', '127.0.0.1'], { cwd: root, stdio: 'ignore' });
  await new Promise((r) => setTimeout(r, 900));
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const made = [];
  const save = (file) => { made.push(path.relative(root, file)); };
  try {
    // ---------------------------------------------------------------- icons (no game needed)
    if (on('icons')) {
      const pg = await browser.newPage();
      const icon = async (file, px, src, transparent = false) => {
        await pg.setViewportSize({ width: px, height: px });
        await pg.setContent(`<html><body style="margin:0;background:${transparent ? 'transparent' : '#0e3527'}">${src.replace('<svg ', `<svg width="${px}" height="${px}" `)}</body></html>`);
        fs.mkdirSync(path.dirname(file), { recursive: true });
        await pg.screenshot({ path: file, omitBackground: transparent });
        save(file);
      };
      await icon(rel('00-shared/icons/app-store-1024.png'), 1024, fullBleed);
      await icon(rel('00-shared/icons/google-play-512.png'), 512, fullBleed);
      await icon(rel('05-desktop/build/icon.png'), 1024, svg, true);
      await icon(rel('00-shared/icons/desktop-256.png'), 256, svg, true);
      // Steam library logo: the title alone on transparent, 1280x720
      await pg.setViewportSize({ width: 1280, height: 720 });
      await pg.setContent(`<html><head><style>@font-face{font-family:L;src:url(data:font/woff2;base64,${font})}
        html,body{margin:0;width:1280px;height:720px;background:transparent;display:flex;align-items:center;justify-content:center}${LOGO_CSS}</style></head>
        <body>${logoHtml(210)}</body></html>`);
      await pg.evaluate(() => document.fonts.ready);
      fs.mkdirSync(rel('06-steam/art'), { recursive: true });
      await pg.screenshot({ path: rel('06-steam/art/library-logo-1280x720.png'), omitBackground: true });
      save(rel('06-steam/art/library-logo-1280x720.png'));
      await pg.close();
    }

    // ---------------------------------------------------------------- helpers for game scenes
    const openGame = async (ctx, query = '') => {
      const page = await ctx.newPage();
      page.on('pageerror', (e) => console.log('pageerror', e.message));
      await page.goto(BASE + query);
      await page.waitForSelector('html[data-ready="1"]', { timeout: 90000 });
      await page.evaluate(() => {
        document.querySelectorAll('.overlay.open,.overlay.show').forEach((o) => o.classList.remove('open', 'show'));
        MSMD.Save.data.tutorialDone = true;
        // a believable save part-way through World 1 (not so far that skins unlock and pop up a card)
        for (let i = 1; i <= 6; i++) MSMD.Save.data.levels[i] = MSMD.Save.data.levels[i] || { stars: i < 5 ? 3 : 2, best: 1800 + i * 150, clears: 1 };
        MSMD.Save.data.bananas = 1250;
        MSMD.Save.checkSkinGoals();
        MSMD.ui.pendingUnlocks = null;
        MSMD.Save.data.golden = 40;
        MSMD.Save.setSetting('quality', 'ultra');
        MSMD.app.applySettings();
      });
      return page;
    };
    const look = (page, l) => page.evaluate((l) => {
      const eq = { skin: 'cocoa', hat: 'none', eyes: 'none', neck: 'none', back: 'none', hands: 'none', feet: 'none', face: 'none', aura: 'none', flair: 'wiggle', stage: 'auto', ...l };
      MSMD.monkey.applyLook(eq);
    }, l);
    const settle = (page, ms = 1200) => page.waitForTimeout(ms);
    const toTitle = async (page) => {
      await page.evaluate(() => { MSMD.game.quit(); MSMD.ui.hideOverlays(); MSMD.ui.show('title'); });
      await settle(page, 1500);
    };
    const level = async (page, n, phase = 'watch') => {
      await page.evaluate((n) => { MSMD.game.quit(); MSMD.ui.hideOverlays(); MSMD.game.openLevel(n); }, n);
      await page.waitForSelector('#intro-go', { state: 'attached', timeout: 30000 });
      await page.evaluate(() => document.getElementById('intro-go').click());
      await page.waitForFunction((p) => MSMD.game.phase === p, phase, { timeout: 90000 });
    };
    const tapRight = async (page) => {
      const step = await page.evaluate(() => MSMD.game.run.expected[MSMD.game.run.idx]);
      for (const id of step) await page.keyboard.down(KEYS[id]);
      for (const id of step) await page.keyboard.up(KEYS[id]);
    };
    // hide every bit of UI, park the camera, and optionally lay a logo over the scene
    const sceneOnly = (page, { env, cam, target, logo, logoSize, logoPos, action }) => page.evaluate((o) => {
      for (const el of document.body.children) if (el.id !== 'scene') el.style.visibility = 'hidden';
      MSMD.game.quit();
      const s = MSMD.stage;
      s.setEnvironment(o.env);
      s.computeCamera = () => {};
      s.viewShift = 0;
      s.camGoal.pos.set(...o.cam);
      s.camGoal.target.set(...o.target);
      s.camPos.copy(s.camGoal.pos);
      s.camTarget.copy(s.camGoal.target);
      MSMD.monkey.anims = [];
      if (o.action) MSMD.monkey.play(o.action, 1.6);
      document.getElementById('art-logo')?.remove();
      if (o.logo) {
        const d = document.createElement('div');
        d.id = 'art-logo';
        d.innerHTML = `<style>#art-logo{position:fixed;z-index:999;pointer-events:none;${o.logoPos}}
          #art-logo .logo{font-family:var(--font-display,'Lilita One'),sans-serif;line-height:.95;color:#ffd23f;-webkit-text-stroke:.06em #23160c;paint-order:stroke fill;text-shadow:0 .07em 0 #23160c,0 .12em .18em rgba(0,0,0,.45)}</style>
          <div class="logo" style="font-size:${o.logoSize}px">Monkey See,<br><span style="color:#fff8e6">Monkey Do</span></div>`;
        document.body.appendChild(d);
      }
    }, { env, cam, target, logo, logoSize, logoPos, action });

    // ---------------------------------------------------------------- key art (Play, itch, Steam)
    if (on('art') || on('steam')) {
      const ctx = await browser.newContext({ viewport: { width: 1024, height: 500 }, deviceScaleFactor: 1 });
      const page = await openGame(ctx, '?edition=pc');
      await look(page, { skin: 'cocoa', hat: 'party', hands: 'mic', feet: 'sneakers', aura: 'sparkle' });
      const shots = [];
      if (on('art')) {
        shots.push({ file: rel('00-shared/art/play-feature-graphic-1024x500.png'), w: 1024, h: 500, env: 'beach', cam: [-1.9, 2.5, 9.8], target: [-1.9, 2.2, 0], logo: true, logoSize: 64, logoPos: 'left:44px;top:50%;transform:translateY(-50%)', action: 'CHEER' });
        shots.push({ file: rel('00-shared/art/itch-cover-630x500.png'), w: 630, h: 500, env: 'disco', cam: [0, 3.3, 11.8], target: [0, 3.0, 0], logo: true, logoSize: 54, logoPos: 'left:0;right:0;top:20px;text-align:center', action: 'CHEER' });
      }
      if (on('steam')) {
        const S = (n) => rel(`06-steam/art/${n}`);
        shots.push({ file: S('header-capsule-920x430.png'), w: 920, h: 430, env: 'jungle', cam: [-1.9, 2.5, 9.8], target: [-1.9, 2.2, 0], logo: true, logoSize: 62, logoPos: 'left:40px;top:50%;transform:translateY(-50%)', action: 'CHEER' });
        shots.push({ file: S('library-header-920x430.png'), w: 920, h: 430, env: 'beach', cam: [-1.9, 2.5, 9.8], target: [-1.9, 2.2, 0], logo: true, logoSize: 62, logoPos: 'left:40px;top:50%;transform:translateY(-50%)', action: 'RA' });
        shots.push({ file: S('small-capsule-462x174.png'), w: 462, h: 174, env: 'jungle', cam: [-1.9, 2.6, 6.4], target: [-1.9, 2.45, 0], logo: true, logoSize: 40, logoPos: 'left:16px;top:50%;transform:translateY(-50%)' });
        shots.push({ file: S('main-capsule-1232x706.png'), w: 1232, h: 706, env: 'disco', cam: [-1.7, 2.5, 9.8], target: [-1.7, 2.2, 0], logo: true, logoSize: 92, logoPos: 'left:60px;top:50%;transform:translateY(-50%)', action: 'CHEER' });
        shots.push({ file: S('vertical-capsule-748x896.png'), w: 748, h: 896, env: 'moon', cam: [0, 3.4, 12.5], target: [0, 3.0, 0], logo: true, logoSize: 82, logoPos: 'left:0;right:0;top:34px;text-align:center', action: 'CHEER' });
        shots.push({ file: S('library-capsule-600x900.png'), w: 600, h: 900, env: 'jungle', cam: [0, 3.5, 14.5], target: [0, 3.2, 0], logo: true, logoSize: 70, logoPos: 'left:0;right:0;top:30px;text-align:center', action: 'CHEER' });
        shots.push({ file: S('page-background-1438x810.jpg'), w: 1438, h: 810, env: 'moon', cam: [1.2, 2.4, 11], target: [1.2, 2.0, 0] });
      }
      for (const s of shots) {
        await page.setViewportSize({ width: s.w, height: s.h });
        await page.evaluate(() => MSMD.stage.resize());
        await sceneOnly(page, s);
        await settle(page, s.action ? 700 : 1200);
        fs.mkdirSync(path.dirname(s.file), { recursive: true });
        await page.screenshot({ path: s.file, ...(s.file.endsWith('.jpg') ? { type: 'jpeg', quality: 92 } : {}) });
        save(s.file);
      }
      await ctx.close();
      if (on('steam')) {
        // the library hero is 3840x1240 with no text: render at half size, 2x
        const hctx = await browser.newContext({ viewport: { width: 1920, height: 620 }, deviceScaleFactor: 2 });
        const hp = await openGame(hctx, '?edition=pc');
        await look(hp, { skin: 'cocoa', hat: 'party', hands: 'mic', feet: 'sneakers', aura: 'sparkle' });
        await sceneOnly(hp, { env: 'beach', cam: [-2.4, 2.5, 10.2], target: [-2.4, 2.2, 0], action: 'CHEER' });
        await settle(hp, 900);
        const f = rel('06-steam/art/library-hero-3840x1240.jpg');
        await hp.screenshot({ path: f, type: 'jpeg', quality: 92 });
        save(f);
        await hctx.close();
      }
    }

    // ---------------------------------------------------------------- screenshots of real play
    const screenshotSet = async (name, viewport, dpr, query, list) => {
      const ctx = await browser.newContext({ viewport, deviceScaleFactor: dpr, hasTouch: viewport.width < 900, isMobile: viewport.width < 900 });
      const page = await openGame(ctx, query);
      const dir = rel(`00-shared/screenshots/${name}`);
      fs.mkdirSync(dir, { recursive: true });
      let i = 0;
      for (const shot of list) {
        i++;
        try {
          await shot.go(page);
          // no pop-up cards over the picture (unlocks, mistakes, toasts)
          await page.evaluate(() => {
            MSMD.ui.pendingUnlocks = null;
            document.querySelectorAll('.overlay').forEach((o) => { if (o.id !== 'ov-intro') o.classList.remove('open', 'show'); });
            document.querySelectorAll('.toast.show').forEach((t) => t.classList.remove('show'));
          });
          const f = path.join(dir, `${String(i).padStart(2, '0')}-${shot.id}.jpg`);
          await page.screenshot({ path: f, timeout: 120000, type: 'jpeg', quality: 92 });
          save(f);
        } catch (e) {
          console.log(`skipped ${name}/${shot.id}: ${e.message.split('\n')[0]}`);
        }
      }
      await ctx.close();
    };
    const PLAY = [
      { id: 'title', go: async (p) => { await look(p, { skin: 'cocoa', hat: 'party', feet: 'sneakers' }); await p.evaluate(() => MSMD.stage.setEnvironment('jungle')); await toTitle(p); } },
      { id: 'watch', go: async (p) => { await look(p, { skin: 'tiger', hat: 'pirate', back: 'cape' }); await level(p, 4, 'watch'); await settle(p, 500); } },
      { id: 'your-turn', go: async (p) => { await look(p, { skin: 'galaxy', hat: 'spacehelmet', aura: 'stars' }); await level(p, 6, 'respond'); await tapRight(p); await settle(p, 160); } },
      { id: 'take-turns', go: async (p) => { await look(p, { skin: 'cocoa', hat: 'party', hands: 'maracas' }); await level(p, 2, 'respond'); await tapRight(p); await p.waitForFunction(() => MSMD.game.phase === 'add', null, { timeout: 15000 }); await settle(p, 500); } },
      { id: 'disco', go: async (p) => { await look(p, { skin: 'gold', eyes: 'shades', neck: 'bowtie', aura: 'sparkle' }); await level(p, 5, 'watch'); await settle(p, 700); } },
      { id: 'wardrobe', go: async (p) => { await p.evaluate(() => { MSMD.game.quit(); MSMD.ui.hideOverlays(); }); await look(p, { skin: 'phoenix', hat: 'crown', back: 'angelwings' }); await p.evaluate(() => MSMD.ui.show('shop')); await settle(p, 1500); } },
    ];
    if (on('phone')) await screenshotSet('iphone-6.9', { width: 440, height: 956 }, 3, '', PLAY);
    if (on('android')) await screenshotSet('android-phone', { width: 360, height: 640 }, 3, '', PLAY.slice(0, 5));
    if (on('ipad')) await screenshotSet('ipad-13', { width: 1032, height: 1376 }, 2, '', PLAY.slice(0, 4));
    if (on('desktop')) await screenshotSet('desktop-1080p', { width: 1920, height: 1080 }, 1, '?edition=pc', PLAY);
    if (on('phone')) {
      await screenshotSet('shop-review', { width: 440, height: 956 }, 3, '?billing=test', [
        { id: 'shop', go: async (p) => { await p.evaluate(() => { MSMD.ui.show('store'); }); await settle(p, 1500); } },
      ]);
    }
  } finally {
    await browser.close();
    server.kill();
  }
  console.log(`${made.length} images:\n` + made.join('\n'));
}
main().catch((e) => { console.error(e); process.exit(1); });
