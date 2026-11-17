#!/usr/bin/env node
/* ============================================================
   Store screenshots and promo art, at each store's exact sizes.

   node tools/store-assets.mjs <outDir>          (after `npm run build`)
     -> <outDir>/screenshots/<device>/NN-<scene>.png
     -> <outDir>/graphics/<store>-<name>-<w>x<h>.png

   Screenshots are taken from the real game (the web build in dist/,
   served locally) in staged states: a puzzle part-solved, the duel
   mid-race, the campaign map and so on. Promo art is drawn from the
   game's own glyphs, fonts and space backgrounds.
   Set PW_CHROMIUM to use a preinstalled Chromium.
   ============================================================ */
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, mkdirSync, existsSync, statSync } from 'node:fs';
import { join, dirname, resolve, extname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { chromium } from 'playwright';
import { spriteMarkup } from '../src/data/glyphs/index.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = resolve(process.argv[2] || join(root, '..', 'store-launch', 'assets'));
const only = process.argv[3] ? process.argv[3].split(',') : null; // 'screenshots' | 'graphics'
const dist = join(root, 'dist');
if (!existsSync(join(dist, 'index.html'))) { console.error('Run `npm run build` first.'); process.exit(1); }

// ---------- devices (logical size x scale = the store's pixel size) ----------
const DEVICES = [
  { id: 'apple-iphone-6.9in', w: 440, h: 956, scale: 3, mobile: true, note: 'App Store iPhone 6.9" (1320x2868)' },
  { id: 'apple-ipad-13in', w: 1032, h: 1376, scale: 2, mobile: true, note: 'App Store iPad 13" (2064x2752)' },
  { id: 'google-phone', w: 360, h: 640, scale: 3, mobile: true, note: 'Google Play phone (1080x1920, 9:16)' },
  { id: 'google-tablet-10in', w: 800, h: 1280, scale: 2, mobile: true, note: 'Google Play 10" tablet (1600x2560)' },
  { id: 'pc-1920x1080', w: 1280, h: 720, scale: 1.5, mobile: false, note: 'Steam, GOG, itch.io, Epic, Microsoft Store (1920x1080)' },
];

// ---------- a tiny static server for dist/ ----------
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.webp': 'image/webp', '.png': 'image/png', '.svg': 'image/svg+xml', '.woff2': 'font/woff2', '.woff': 'font/woff', '.json': 'application/json', '.webmanifest': 'application/manifest+json', '.jpg': 'image/jpeg', '.ico': 'image/x-icon' };
const server = createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/index.html';
  const f = join(dist, p);
  if (!f.startsWith(dist) || !existsSync(f) || statSync(f).isDirectory()) { res.statusCode = 404; res.end(); return; }
  res.setHeader('content-type', MIME[extname(f)] || 'application/octet-stream');
  res.end(readFileSync(f));
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const base = `http://127.0.0.1:${server.address().port}`;

const browser = await chromium.launch(process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {});
const written = [];
const save = (file) => { written.push(file); return file; };

// ---------- screenshots ----------
const STAGED_PROFILE = {
  settings: { seenTutorial: true },
  campaign: { levels: Object.fromEntries([3, 3, 2, 3, 3, 2].map((stars, l) => [`0-${l}`, { stars, bestMs: 180_000 + l * 41_000 }])) },
};
/** A believable clock for a puzzle in progress. */
const setClock = (page, ms) => page.evaluate((t) => { if (window.__alienSession) window.__alienSession.elapsedMs = t; }, ms);
async function freshPage(dev) {
  const ctx = await browser.newContext({
    viewport: { width: dev.w, height: dev.h }, deviceScaleFactor: dev.scale,
    isMobile: dev.mobile, hasTouch: dev.mobile, reducedMotion: 'reduce',
  });
  const page = await ctx.newPage();
  // Afternoon local time, so no "Night Owl" achievement shows up in a store shot.
  await page.clock.setFixedTime(new Date('2026-11-14T15:30:00'));
  // A returning player: tutorial seen, the first sector part-cleared.
  await page.addInitScript((profile) => {
    if (!localStorage.getItem('alien-sudoku:profile')) localStorage.setItem('alien-sudoku:profile', JSON.stringify(profile));
  }, STAGED_PROFILE);
  await page.goto(`${base}/#e2e`);
  await page.waitForSelector('.screen-menu');
  return { ctx, page };
}

/** Fill some of the board through the UI (correct glyphs), then select a cell. */
async function partSolve(page, fraction, { select = true } = {}) {
  const { board, solution } = await page.evaluate(() => ({ board: window.__alienSession.board.slice(), solution: window.__alienSession.solution.slice() }));
  const empties = board.map((v, i) => (v ? -1 : i)).filter((i) => i >= 0);
  const n = Math.round(empties.length * fraction);
  // Spread the filled cells around the board rather than top to bottom.
  const picked = empties.filter((_, k) => (k * 7) % empties.length < n);
  for (const i of picked) {
    await page.locator(`.cell[data-i="${i}"]`).dispatchEvent('pointerdown');
    await page.locator(`.glyph-btn[data-v="${solution[i]}"]`).click();
  }
  if (select) {
    const target = picked[Math.floor(picked.length / 2)];
    if (target != null) await page.locator(`.cell[data-i="${target}"]`).dispatchEvent('pointerdown');
  }
  await page.waitForTimeout(400);
}

async function settle(page) {
  await page.evaluate(() => document.querySelectorAll('.toast').forEach((t) => t.remove()));
  await page.waitForTimeout(700);
}

const SCENES = [
  { id: 'menu', run: async (page) => { await page.waitForTimeout(600); } },
  {
    id: 'play-easy', run: async (page) => {
      await page.locator('.menu-quick').click();
      await page.locator('.diff-option.diff-easy').click();
      await page.waitForSelector('.screen-play');
      await setClock(page, 3 * 60_000 + 12_000);
      await partSolve(page, 0.55);
    },
  },
  {
    id: 'play-cadets', run: async (page) => {
      await page.locator('.menu-quick').click();
      await page.locator('.diff-option.diff-medium').click();
      await page.waitForSelector('.screen-play');
      await setClock(page, 4 * 60_000 + 51_000);
      await partSolve(page, 0.5);
    },
  },
  {
    id: 'duel', run: async (page) => {
      await page.locator('.menu-duel').click();
      await page.locator('.rival-card', { hasText: 'Commander Vex' }).click();
      await page.locator('.duel-diff.diff-hard').click();
      await page.locator('.duel-start').click();
      await page.waitForSelector('.screen-play .rival');
      await setClock(page, 2 * 60_000 + 30_000);
      await page.evaluate(() => window.__alienDuelAdvance(150_000));
      await partSolve(page, 0.35);
      await page.evaluate(() => window.__alienDuelAdvance(1));
    },
  },
  {
    id: 'play-alien', run: async (page) => {
      await page.locator('.menu-quick').click();
      await page.locator('.diff-option.diff-alien').click();
      await page.waitForSelector('.screen-play');
      await setClock(page, 11 * 60_000 + 47_000);
      await partSolve(page, 0.5);
    },
  },
  {
    id: 'campaign', run: async (page) => {
      await page.locator('.menu-campaign').click();
      await page.locator('.sector-card').first().click();
      await page.waitForSelector('.level-node');
    },
  },
  {
    id: 'win', run: async (page) => {
      await page.locator('.menu-quick').click();
      await page.locator('.diff-option.diff-medium').click();
      await page.waitForSelector('.screen-play');
      await setClock(page, 6 * 60_000 + 38_000);
      await partSolve(page, 1, { select: false });
      await page.waitForSelector('.win-modal');
      await page.waitForTimeout(1200);
    },
  },
];

if (!only || only.includes('screenshots')) {
  for (const dev of DEVICES) {
    const dir = join(out, 'screenshots', dev.id);
    mkdirSync(dir, { recursive: true });
    for (const [k, scene] of SCENES.entries()) {
      const { ctx, page } = await freshPage(dev);
      const errors = [];
      page.on('pageerror', (e) => errors.push(e.message));
      await scene.run(page);
      await settle(page);
      // High-quality JPEG: every store accepts it, at a quarter of the PNG size.
      const file = join(dir, `${String(k + 1).padStart(2, '0')}-${scene.id}.jpg`);
      await page.screenshot({ path: save(file), type: 'jpeg', quality: 92 });
      if (errors.length) console.warn(`  ${dev.id}/${scene.id}: ${errors.join('; ')}`);
      await ctx.close();
    }
    console.log(`screenshots: ${dev.id} (${dev.note})`);
  }
}

// ---------- promo art ----------
const fontUrl = (pkg, file) => pathToFileURL(join(root, 'node_modules', '@fontsource', pkg, 'files', file)).href;
const bgUrl = (name) => pathToFileURL(join(root, 'public', 'space', name)).href;
// A 3x3 "board" mixing the four difficulty lineups, soft to gnarly.
const HERO_GLYPHS = ['softies-1', 'creatures-2', 'hostile-2', 'creatures-5', 'encounters-1', 'softies-6', 'gnarly-1', 'hostile-6', 'softies-9'];
const use = (id) => `<svg viewBox="0 0 64 64"><use href="#gl-${id}"/></svg>`;

function artHtml({ w, h, kind }) {
  const short = Math.min(w, h);
  const wide = w / h;
  const titleSize = kind === 'logo' ? h * 0.3 : wide > 1.25 ? Math.min(h * 0.24, w * 0.085) : w * 0.13;
  const showBoard = kind !== 'logo';
  const showTitle = kind !== 'hero';
  const boardSize = kind === 'hero' ? h * 0.78 : wide > 1.6 ? h * 0.78 : short * 0.62;
  const layout = kind === 'hero' || kind === 'logo' ? 'center' : wide > 1.25 ? 'row' : 'col';
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  @font-face { font-family: Orbitron; font-weight: 900; src: url(${fontUrl('orbitron', 'orbitron-latin-900-normal.woff2')}) format('woff2'); }
  @font-face { font-family: Orbitron; font-weight: 700; src: url(${fontUrl('orbitron', 'orbitron-latin-700-normal.woff2')}) format('woff2'); }
  @font-face { font-family: Grotesk; font-weight: 500; src: url(${fontUrl('space-grotesk', 'space-grotesk-latin-500-normal.woff2')}) format('woff2'); }
  html, body { margin: 0; width: ${w}px; height: ${h}px; overflow: hidden; background: ${kind === 'logo' ? 'transparent' : '#05010f'}; }
  .bg { position: absolute; inset: 0; background: url(${bgUrl(kind === 'hero' ? 'galaxy-spiral.webp' : 'nebula-pink.webp')}) center / cover; }
  .shade { position: absolute; inset: 0; background: radial-gradient(ellipse at 70% 50%, rgba(5,1,15,0.1), rgba(5,1,15,0.75) 75%), linear-gradient(90deg, rgba(5,1,15,0.85), rgba(5,1,15,0.25) 60%); }
  .stage { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; gap: ${short * 0.06}px;
    flex-direction: ${layout === 'col' ? 'column' : 'row'}; padding: ${short * 0.06}px; box-sizing: border-box; }
  .title { font-family: Orbitron; font-weight: 900; line-height: 0.95; letter-spacing: 0.04em; text-align: ${layout === 'row' ? 'left' : 'center'}; }
  .title .a { display: block; font-size: ${titleSize}px; color: #39ff9c; text-shadow: 0 0 ${titleSize * 0.18}px rgba(57,255,156,0.85), 0 0 ${titleSize * 0.5}px rgba(57,255,156,0.4); }
  .title .b { display: block; font-size: ${titleSize * 0.82}px; color: #ff5cd6; text-shadow: 0 0 ${titleSize * 0.18}px rgba(255,92,214,0.85), 0 0 ${titleSize * 0.5}px rgba(255,92,214,0.4); }
  .tag { margin-top: ${titleSize * 0.22}px; font-family: Grotesk; font-weight: 500; font-size: ${Math.max(14, titleSize * 0.2)}px; color: #e9e2ff; letter-spacing: 0.06em; }
  .board { flex: none; width: ${boardSize}px; height: ${boardSize}px; display: grid; grid-template-columns: repeat(3, 1fr); gap: ${boardSize * 0.025}px;
    padding: ${boardSize * 0.035}px; box-sizing: border-box; border-radius: ${boardSize * 0.06}px; background: rgba(12,4,32,0.72);
    border: ${Math.max(2, boardSize * 0.012)}px solid #39ff9c; box-shadow: 0 0 ${boardSize * 0.08}px rgba(57,255,156,0.45); transform: rotate(-4deg); }
  .board div { background: rgba(36,16,74,0.85); border-radius: ${boardSize * 0.035}px; display: grid; place-items: center; }
  .board svg { width: 86%; height: 86%; overflow: visible; }
  </style></head><body>
  <div id="sprite" style="position:absolute;width:0;height:0;overflow:hidden">${spriteMarkup()}</div>
  ${kind === 'logo' ? '' : '<div class="bg"></div><div class="shade"></div>'}
  <div class="stage">
    ${showTitle ? `<div class="title"><span class="a">ALIEN</span><span class="b">SUDOKU</span>${kind === 'logo' || h < 260 ? '' : '<div class="tag">Decode the UFO glyph puzzles</div>'}</div>` : ''}
    ${showBoard ? `<div class="board">${HERO_GLYPHS.map((g) => `<div>${use(g)}</div>`).join('')}</div>` : ''}
  </div></body></html>`;
}

const GRAPHICS = [
  { store: 'google', name: 'feature-graphic', w: 1024, h: 500 },
  { store: 'google', name: 'icon', w: 512, h: 512, icon: true },
  { store: 'steam', name: 'header-capsule', w: 920, h: 430 },
  { store: 'steam', name: 'small-capsule', w: 462, h: 174 },
  { store: 'steam', name: 'main-capsule', w: 1232, h: 706 },
  { store: 'steam', name: 'vertical-capsule', w: 748, h: 896 },
  { store: 'steam', name: 'library-capsule', w: 600, h: 900 },
  { store: 'steam', name: 'library-header', w: 920, h: 430 },
  { store: 'steam', name: 'library-hero', w: 3840, h: 1240, kind: 'hero' },
  { store: 'steam', name: 'library-logo', w: 1280, h: 720, kind: 'logo' },
  { store: 'steam', name: 'page-background', w: 1438, h: 810, kind: 'hero' },
  { store: 'itch', name: 'cover', w: 630, h: 500 },
  { store: 'microsoft', name: 'poster-art', w: 1440, h: 2160 },
  { store: 'microsoft', name: 'box-art', w: 2160, h: 2160 },
  { store: 'microsoft', name: 'hero-art', w: 1920, h: 1080 },
  { store: 'epic', name: 'landscape', w: 2560, h: 1440 },
  { store: 'epic', name: 'portrait', w: 1200, h: 1600 },
  { store: 'epic', name: 'logo', w: 1280, h: 720, kind: 'logo' },
  { store: 'press', name: 'key-art', w: 1920, h: 1080 },
];

if (!only || only.includes('graphics')) {
  const dir = join(out, 'graphics');
  mkdirSync(dir, { recursive: true });
  const tmp = join(out, '.art.html');
  const page = await browser.newPage();
  for (const g of GRAPHICS) {
    // Logos keep transparency and the icon stays PNG; everything else is high-quality JPEG.
    const png = g.icon || g.kind === 'logo';
    const file = join(dir, `${g.store}-${g.name}-${g.w}x${g.h}.${png ? 'png' : 'jpg'}`);
    if (g.icon) {
      // The app icon is already made by tools/gen-icons.mjs; export it at the store's size.
      const icon = join(root, 'assets', 'icon-only.png');
      await page.setViewportSize({ width: g.w, height: g.h });
      await page.setContent(`<html><body style="margin:0"><img src="data:image/png;base64,${readFileSync(icon).toString('base64')}" style="width:${g.w}px;height:${g.h}px;display:block"></body></html>`);
      await page.screenshot({ path: save(file) });
      continue;
    }
    writeFileSync(tmp, artHtml({ w: g.w, h: g.h, kind: g.kind || 'capsule' }));
    await page.setViewportSize({ width: g.w, height: g.h });
    await page.goto(pathToFileURL(tmp).href);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(150);
    await page.screenshot(png ? { path: save(file), omitBackground: g.kind === 'logo' } : { path: save(file), type: 'jpeg', quality: 92 });
  }
  await page.close();
  console.log(`graphics: ${GRAPHICS.length} files`);
}

await browser.close();
server.close();
writeFileSync(join(out, 'MANIFEST.md'), `# Store assets: Alien Sudoku\n\nMade by \`game/tools/store-assets.mjs\` from the current build. Run it again after the game changes.\n\n## Screenshot sets\n\n${DEVICES.map((d) => `- \`screenshots/${d.id}/\`: ${d.note}`).join('\n')}\n\nScenes (JPEG, quality 92): ${SCENES.map((s, k) => `${k + 1}. ${s.id}`).join(' · ')}\n\n## Graphics\n\n${GRAPHICS.map((g) => `- \`graphics/${g.store}-${g.name}-${g.w}x${g.h}.${g.icon || g.kind === 'logo' ? 'png' : 'jpg'}\``).join('\n')}\n`);
console.log(`wrote ${written.length} files to ${out}`);
