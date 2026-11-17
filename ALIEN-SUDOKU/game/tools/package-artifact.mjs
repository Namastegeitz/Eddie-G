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
if (/<\/script|<!--/i.test(js)) throw new Error('bundle contains </script or <!-- and cannot be inlined as-is');
// Run it as a classic script (no type="module"): the only module-only syntax in the
// single-chunk bundle is import.meta in Vite's lazy-import helper, which is unused here.
js = js.replace(/import\.meta\.resolve/g, 'undefined').replace(/import\.meta\.url/g, 'document.baseURI');
if (/import\.meta|^\s*(import|export)\s/m.test(js)) throw new Error('bundle still has module-only syntax');
js = `(function(){"use strict";\n${js}\n})();`;
new Function(js); // throws if it doesn't parse as a classic script

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

// Runs first: if anything fails, say so on screen instead of leaving a blank page.
const guard = `<script>
(function () {
  var shown = false;
  function show(msg) {
    if (shown) return; shown = true;
    var box = document.createElement('div');
    box.id = 'boot-error';
    box.setAttribute('role', 'alert');
    box.style.cssText = 'position:fixed;left:12px;right:12px;bottom:12px;z-index:200;padding:12px 14px;border:1px solid #ff4d6d;border-radius:12px;background:#1a0614;color:#ffd6de;font:13px/1.45 system-ui,sans-serif;white-space:pre-wrap;word-break:break-word';
    box.textContent = 'Alien Sudoku could not start.\\n' + msg;
    (document.body || document.documentElement).appendChild(box);
  }
  window.__alienBootError = show;
  window.addEventListener('error', function (e) { show((e.message || 'Script error') + (e.filename ? ' (' + e.filename.split('/').pop() + ':' + e.lineno + ')' : '')); });
  window.addEventListener('unhandledrejection', function (e) { show('Unhandled: ' + (e.reason && (e.reason.message || e.reason))); });
  setTimeout(function () {
    if (!document.querySelector('.screen-menu, .screen')) show('The menu did not appear after 8 seconds. Scripts may be blocked in this viewer.');
  }, 8000);
})();
</script>`;
const page = `<title>Alien Sudoku</title>
<meta name="claude:viewport-fit-sides" content="cover">
<meta name="theme-color" content="#05010f">
<meta name="color-scheme" content="dark">
${guard}
${bootStyle}
<style>${css}</style>
${body.replace(/<script[\s\S]*?<\/script>/g, '').trim()}
<script>window.__ALIEN_ASSETS__=${JSON.stringify(assets)};</script>
<script>${js}</script>
`;

// Complete document: for double-click offline play and for publishers that
// want a whole page (the fragment above is for hosts that add the skeleton).
const full = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
${page}
</body>
</html>
`;
const splitAt = full.indexOf('<div class="starfield"');
const fullDoc = full.slice(0, splitAt) + '</head>\n<body>\n' + full.slice(splitAt);

mkdirSync(out, { recursive: true });
writeFileSync(join(out, 'alien-sudoku.html'), page);
writeFileSync(join(out, 'AlienSudoku.html'), fullDoc);
rmSync(build, { recursive: true, force: true });
console.log(`wrote ${join(out, 'alien-sudoku.html')} (fragment) and AlienSudoku.html (full page), ${(page.length / 1024 / 1024).toFixed(2)} MB`);
