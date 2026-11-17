// Puts each store's build in its own release folder (run after scripts/build_web.mjs):
//   release/01-web-beta/monkey-see-monkey-do-web.zip     the web build for any static host
//   release/02-itch-io/monkey-see-monkey-do-html5.zip    itch.io HTML5 upload (PC edition, no Shop)
//   release/05-desktop/app/                              the game for the desktop app (not committed)
// Android (.aab) and iPhone (.ipa) builds need Google's and Apple's tools: see the
// README in release/03-google-play and release/04-apple-app-store.
import { execFileSync } from 'node:child_process';
import { cpSync, rmSync, mkdirSync, readFileSync, writeFileSync, existsSync, statSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const www = join(root, 'dist', 'www');
const rel = (p) => join(root, 'release', p);
if (!existsSync(join(www, 'index.html'))) throw new Error('Run node scripts/build_web.mjs first');
const tmp = join(root, 'dist', '.release-tmp');

function zipDir(dir, out) {
  rmSync(out, { force: true });
  mkdirSync(dirname(out), { recursive: true });
  execFileSync('zip', ['-r', '-X', '-q', out, '.'], { cwd: dir });
  return (statSync(out).size / 1024 / 1024).toFixed(2) + ' MB';
}
function countFiles(dir) {
  let n = 0;
  for (const e of readdirSync(dir, { withFileTypes: true })) n += e.isDirectory() ? countFiles(join(dir, e.name)) : 1;
  return n;
}

// web: as built
console.log('web zip', zipDir(www, rel('01-web-beta/monkey-see-monkey-do-web.zip')));
cpSync(join(root, 'beta/qr.png'), rel('01-web-beta/qr.png'));

// itch.io: PC edition (no Shop) and no service worker (itch.io plays games inside its own frame)
rmSync(tmp, { recursive: true, force: true });
cpSync(www, tmp, { recursive: true, filter: (p) => !/(sw\.js|update-webview\.html)$/.test(p) });
let html = readFileSync(join(tmp, 'index.html'), 'utf8');
html = html.replace('<script src="app.js" defer></script>', '<script>window.MSMD_EDITION = "pc"; window.MSMD_NO_SW = true;</script>\n<script src="app.js" defer></script>');
if (!html.includes('MSMD_EDITION')) throw new Error('itch build: could not set the PC edition');
writeFileSync(join(tmp, 'index.html'), html);
const files = countFiles(tmp);
console.log(`itch.io zip ${zipDir(tmp, rel('02-itch-io/monkey-see-monkey-do-html5.zip'))}, ${files} files (itch.io allows 1000 files, 500 MB unpacked)`);
rmSync(tmp, { recursive: true, force: true });

// desktop: the app folder the Electron project packages
execFileSync('node', [rel('05-desktop/scripts/copy-app.mjs')], { stdio: 'inherit' });
console.log('release builds ready');
