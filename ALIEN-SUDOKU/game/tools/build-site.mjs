#!/usr/bin/env node
/* ============================================================
   The game's public website: the address both stores ask for.

   node tools/build-site.mjs [outDir=../builds/site]   (after `npm run build`)
     index.html     home: what the game is, screenshots, play in the browser, store links
     privacy.html   the privacy policy (Google Play and App Store need its URL)
     support.html   help and contact (App Store needs a support URL)
     play/          the installable web game (dist/, works offline)

   Hosted at https://namastegeitz.github.io/Eddie-G/alien-sudoku/ (the gh-pages branch).
   Details come from src/data/publisher.js; store links from STORE_LINKS below.
   ============================================================ */
import { readFileSync, writeFileSync, mkdirSync, cpSync, rmSync, existsSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PUBLISHER } from '../src/data/publisher.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = resolve(process.argv[2] || join(root, '..', 'builds', 'site'));
const dist = join(root, 'dist');
if (!existsSync(join(dist, 'index.html'))) { console.error('Run `npm run build` first.'); process.exit(1); }
const pkg = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));

/** Filled in once each store listing is live. */
const STORE_LINKS = {
  google: '', // https://play.google.com/store/apps/details?id=com.eddieg.aliensudoku
  apple: '',  // https://apps.apple.com/app/id...
};

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
/** Just enough Markdown for the policy: headings, paragraphs, lists, bold, italics, links. */
function md(text) {
  const inline = (s) => esc(s)
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/(https?:\/\/[^\s<]+[^\s<.,)])/g, '<a href="$1">$1</a>')
    .replace(/([\w.+-]+@[\w-]+\.[\w.]+)/g, '<a href="mailto:$1">$1</a>');
  const html = [];
  let list = null;
  const flush = () => { if (list) { html.push(`<ul>${list.join('')}</ul>`); list = null; } };
  for (const block of text.split(/\n\s*\n/)) {
    const lines = block.trim().split('\n');
    if (!lines[0]) continue;
    if (/^#{1,3} /.test(lines[0])) { flush(); const n = lines[0].match(/^#+/)[0].length; html.push(`<h${n}>${inline(lines[0].replace(/^#+ /, ''))}</h${n}>`); if (lines.length > 1) html.push(`<p>${inline(lines.slice(1).join(' '))}</p>`); continue; }
    if (lines.every((l) => /^- /.test(l))) { if (!list) list = []; list.push(...lines.map((l) => `<li>${inline(l.slice(2))}</li>`)); continue; }
    flush();
    html.push(`<p>${lines.map((l) => inline(l.replace(/ {2}$/, ''))).join('<br>')}</p>`);
  }
  flush();
  return html.join('\n');
}

const p = PUBLISHER;
const contactLines = [p.supportEmail && `Email: ${p.supportEmail}`, `Website: ${p.website || ''}`].filter(Boolean).join('  \n');
const policy = readFileSync(join(root, 'src', 'data', 'privacy-policy.md'), 'utf8')
  .replace(/\{\{DEVELOPER\}\}/g, p.name).replace(/\{\{CONTACT\}\}/g, contactLines);

const CSS = `
:root { color-scheme: dark; --bg: #05010f; --panel: #120a26; --line: rgba(180,107,255,.28); --text: #ece8ff; --dim: #b9b3d4; --green: #39ff9c; --pink: #ff4fd8; --cyan: #3de8ff; }
* { box-sizing: border-box; }
body { margin: 0; background: radial-gradient(ellipse at 50% -10%, #2a0d55 0%, var(--bg) 60%) fixed, var(--bg); color: var(--text); font: 16px/1.6 system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif; }
a { color: var(--cyan); }
header.site { display: flex; align-items: center; justify-content: space-between; gap: 12px; max-width: 980px; margin: 0 auto; padding: 18px 20px; }
header.site a.brand { display: flex; align-items: center; gap: 10px; color: var(--text); text-decoration: none; font-weight: 800; letter-spacing: .12em; text-transform: uppercase; }
header.site img { width: 36px; height: 36px; border-radius: 9px; }
nav a { margin-left: 14px; color: var(--dim); text-decoration: none; font-size: .95rem; }
nav a:hover { color: var(--text); }
main { max-width: 980px; margin: 0 auto; padding: 0 20px 60px; }
.hero { text-align: center; padding: 34px 0 10px; }
.hero h1 { margin: 0; font-size: clamp(2.4rem, 7vw, 4.2rem); letter-spacing: .08em; line-height: 1.05; text-transform: uppercase; }
.hero h1 b { color: var(--green); text-shadow: 0 0 22px rgba(57,255,156,.55); }
.hero h1 i { font-style: normal; color: var(--pink); text-shadow: 0 0 22px rgba(255,79,216,.5); }
.hero p { max-width: 640px; margin: 14px auto; color: var(--dim); font-size: 1.08rem; }
.cta { display: flex; flex-wrap: wrap; gap: 12px; justify-content: center; margin: 22px 0 8px; }
.btn { display: inline-flex; align-items: center; gap: 8px; padding: 13px 22px; border-radius: 999px; font-weight: 700; text-decoration: none; border: 1px solid var(--line); color: var(--text); background: var(--panel); }
.btn.primary { background: var(--green); color: #05010f; border: 0; box-shadow: 0 0 24px rgba(57,255,156,.45); }
.btn.soon { opacity: .7; }
.shots { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 14px; margin: 34px 0; }
.shots img { width: 100%; border-radius: 18px; border: 1px solid var(--line); box-shadow: 0 10px 30px rgba(0,0,0,.5); }
.features { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 14px; }
.card { background: var(--panel); border: 1px solid var(--line); border-radius: 18px; padding: 16px 18px; }
.card h3 { margin: 0 0 4px; font-size: 1rem; color: var(--green); }
.card p { margin: 0; color: var(--dim); font-size: .95rem; }
.doc { max-width: 760px; margin: 0 auto; background: var(--panel); border: 1px solid var(--line); border-radius: 20px; padding: 10px 28px 26px; }
.doc h1 { font-size: 1.7rem; } .doc h2 { font-size: 1.15rem; margin-top: 1.6em; color: var(--green); }
.doc li { margin: 4px 0; }
footer { text-align: center; color: var(--dim); font-size: .85rem; padding: 26px 20px 40px; }
footer a { color: var(--dim); }
`;

function page(file, title, body, { description = '', home = false } = {}) {
  // Apple reviews the support URL: only the home page points to the browser version.
  const nav = home ? '<a href="play/">Play</a><a href="support.html">Support</a><a href="privacy.html">Privacy</a>' : '<a href="./">Home</a><a href="support.html">Support</a><a href="privacy.html">Privacy</a>';
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#05010f">
<title>${esc(title)}</title>
${description ? `<meta name="description" content="${esc(description)}">` : ''}
<meta property="og:title" content="${esc(title)}">
<meta property="og:image" content="img/opengraph.jpg">
<link rel="icon" href="img/icon-192.png">
<style>${CSS}</style>
</head>
<body>
<header class="site">
  <a class="brand" href="./"><img src="img/icon-192.png" alt="">Alien Sudoku</a>
  <nav>${nav}</nav>
</header>
<main>
${body}
</main>
<footer>© ${new Date().getFullYear()} ${esc(p.name)} · Alien Sudoku ${pkg.version} · <a href="privacy.html">Privacy policy</a> · <a href="support.html">Support</a></footer>
</body>
</html>
`;
  writeFileSync(join(out, file), html);
}

rmSync(out, { recursive: true, force: true });
mkdirSync(join(out, 'img'), { recursive: true });
cpSync(dist, join(out, 'play'), { recursive: true });
cpSync(join(root, 'public', 'icons', 'icon-192.png'), join(out, 'img', 'icon-192.png'));
cpSync(join(root, 'public', 'opengraph.jpg'), join(out, 'img', 'opengraph.jpg'));
const shotDir = join(root, '..', 'store-launch', 'assets', 'screenshots', 'apple-iphone-6.9in');
const SHOTS = ['01-menu', '03-play-cadets', '06-campaign', '04-duel'];
for (const s of SHOTS) cpSync(join(shotDir, `${s}.jpg`), join(out, 'img', `${s}.jpg`));

const storeBtn = (url, label) => (url ? `<a class="btn" href="${url}">${label}</a>` : `<span class="btn soon">${label}: coming soon</span>`);
page('index.html', 'Alien Sudoku: decode the lost UFO archive', `
<section class="hero">
  <h1><b>Alien</b> <i>Sudoku</i></h1>
  <p>Sudoku with alien glyphs instead of numbers. Decode transmissions across a 54-level campaign, take on a new signal every day, race a computer rival in Alien Duel, or relax in Zen mode, with a theme song for every difficulty.</p>
  <div class="cta">
    <a class="btn primary" href="play/">▶ Play in your browser</a>
    ${storeBtn(STORE_LINKS.google, 'Google Play')}
    ${storeBtn(STORE_LINKS.apple, 'App Store')}
  </div>
</section>
<section class="shots">${SHOTS.map((s) => `<img src="img/${s}.jpg" alt="" loading="lazy">`).join('')}</section>
<section class="features">
  <div class="card"><h3>54-level campaign</h3><p>Six sectors from the Lunar Outpost to the Cluster Core, each with its own aliens and space art.</p></div>
  <div class="card"><h3>Daily transmission</h3><p>A new puzzle every day, with a streak to keep.</p></div>
  <div class="card"><h3>Alien Duel</h3><p>Race a computer rival you can tune: speed, accuracy and style.</p></div>
  <div class="card"><h3>Four difficulties</h3><p>From friendly Alien Creatures to the Gnarly Horde, each with its own look and music.</p></div>
</section>
`, { home: true, description: 'Alien Sudoku: Sudoku with alien glyphs. A 54-level campaign, daily puzzles, Alien Duel and Zen mode.' });

page('privacy.html', 'Alien Sudoku: Privacy Policy', `<article class="doc">${md(policy)}</article>`);

const email = p.supportEmail;
page('support.html', 'Alien Sudoku: Support', `<article class="doc">
<h1>Alien Sudoku: Support</h1>
${email ? `<p>Questions, bugs or ideas? Email <a href="mailto:${email}">${email}</a>. We read every message and usually answer within a few days.</p>` : '<p>Questions, bugs or ideas? Use the contact details on the game\'s store page.</p>'}
<h2>How do I play?</h2>
<p>Fill the grid so every row, every column and every 3×3 box holds each of the nine alien glyphs exactly once. Tap a cell, then a glyph. Turn on Notes to pencil in candidates. Settings → How to play has a full guide.</p>
<h2>Where is my progress saved?</h2>
<p>Only on your device. There are no accounts, so progress does not move between devices. Uninstalling the game deletes it.</p>
<h2>How do I start over?</h2>
<p>Settings → Reset all progress.</p>
<h2>I saw an inappropriate ad</h2>
<p>In the game, open Settings → Report an ad${email ? `, or email <a href="mailto:${email}">${email}</a>` : ''}. Say what the ad showed and when you saw it.</p>
<h2>How do I change my ad privacy choices?</h2>
<p>In the game: Settings → Ad privacy choices (shown where required). On iPhone: Settings → Privacy &amp; Security → Tracking. On Android: Settings → Google → Ads. See the <a href="privacy.html">privacy policy</a>.</p>
<h2>There's no sound</h2>
<p>Check that the phone is not on silent and the volume is up, then open Settings → Test sound in the game.</p>
</article>`);

writeFileSync(join(out, '.nojekyll'), '');
console.log(`site written to ${out} (support email: ${email || 'not set yet'})`);
