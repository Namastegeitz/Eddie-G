// Copies the web build (../dist) into ./app so electron-builder can package it.
const fs = require('node:fs');
const path = require('node:path');

const src = path.join(__dirname, '..', 'dist');
const dst = path.join(__dirname, 'app');
if (!fs.existsSync(path.join(src, 'index.html'))) {
  console.error('No web build found. Run `npm run build` in apps/alien-sudoku first.');
  process.exit(1);
}
fs.rmSync(dst, { recursive: true, force: true });
fs.cpSync(src, dst, { recursive: true });
// The service worker is for the web build only.
for (const f of fs.readdirSync(dst)) if (/^(sw|workbox-.*)\.js(\.map)?$/.test(f)) fs.rmSync(path.join(dst, f));
console.log('Copied web build to desktop/app');
