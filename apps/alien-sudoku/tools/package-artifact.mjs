#!/usr/bin/env node
/* Packages the web build as ONE self-contained HTML file for a claude.ai artifact.

   The artifact viewer runs pages in a locked-down sandbox: it wraps the page in its
   own <html>/<head>/<body>, blocks service workers, and does not reliably load
   ES-module scripts from separate files. So this file inlines everything: the JS
   bundle (one chunk, SINGLE_FILE=1), the CSS, the fonts (woff2 data URIs) and the
   space backgrounds (data URIs in window.__ALIEN_ASSETS__, read by ui/background.js).

   node tools/package-artifact.mjs <outDir>
   -> <outDir>/alien-sudoku.html  (publish this one file) */
import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync, rmSync, readdirSync, mkdirSync } from 'node:fs';
import { join, dirname, extname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = process.argv[2];
if (!out) { console.error('usage: node tools/package-artifact.mjs <outDir>'); process.exit(1); }
const build = join(out, '_build');

execSync(`npx vite build --outDir "${build}" --emptyOutDir`, {
  cwd: root, stdio: 'inherit', env: { ...process.env, VITE_NO_SW: '1', SINGLE_FILE: '1' },
});

const MIME = { '.woff2': 'font/woff2', '.woff': 'font/woff', '.webp': 'image/webp', '.png': 'image/png', '.svg': 'image/svg+xml', '.jpg': 'image/jpeg' };
const dataUri = (file) => `data:${MIME[extname(file)]};base64,${readFileSync(file).toString('base64')}`;

const html = readFileSync(join(build, 'index.html'), 'utf8');
const head = html.match(/<head>([\s\S]*?)<\/head>/)[1];
const body = html.match(/<body>([\s\S]*?)<\/body>/)[1];

// JS: exactly one bundle.
const jsFiles = readdirSync(join(build, 'assets')).filter((f) => f.endsWith('.js'));
if (jsFiles.length !== 1) throw new Error(`expected one JS bundle, got ${jsFiles.join(', ')}`);
let js = readFileSync(join(build, 'assets', jsFiles[0]), 'utf8');
if (/<\/script|<!--/i.test(js)) {
  // Only safe inside string literals; check where they occur before trusting this.
  js = js.replace(/<\/script/gi, '<\\/script').replace(/<!--/g, '<\\!--');
}

// CSS: inline fonts (woff2 only; drop the woff fallbacks).
const cssFile = readdirSync(join(build, 'assets')).find((f) => f.endsWith('.css'));
let css = readFileSync(join(build, 'assets', cssFile), 'utf8');
css = css.replace(/,\s*url\([^)]*\.woff\)\s*format\(["']?woff["']?\)/g, '');
css = css.replace(/url\(["']?([^)"']+\.woff2)["']?\)/g, (_, rel) => `url(${dataUri(join(build, 'assets', basename(rel)))})`);
if (/url\(["']?\.?\/?(assets|space|icons)\//.test(css)) throw new Error('CSS still references external files');

// Images used at runtime.
const assets = {};
for (const f of readdirSync(join(build, 'space'))) assets[`space/${f}`] = dataUri(join(build, 'space', f));

const bootStyle = (head.match(/<style>[\s\S]*?<\/style>/) || [''])[0];
const page = `<title>Alien Sudoku</title>
<meta name="claude:viewport-fit-sides" content="cover">
<meta name="theme-color" content="#05010f">
<meta name="color-scheme" content="dark">
${bootStyle}
<style>${css}</style>
${body.replace(/<script[\s\S]*?<\/script>/g, '').trim()}
<script>window.__ALIEN_ASSETS__=${JSON.stringify(assets)};</script>
<script type="module">${js}</script>
`;

mkdirSync(out, { recursive: true });
writeFileSync(join(out, 'alien-sudoku.html'), page);
rmSync(build, { recursive: true, force: true });
console.log(`wrote ${join(out, 'alien-sudoku.html')} (${(page.length / 1024 / 1024).toFixed(2)} MB)`);
