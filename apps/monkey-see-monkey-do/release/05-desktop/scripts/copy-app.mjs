// Copies the game's web build (../../dist/www) into ./app for the desktop app.
// Build the web version first: node ../../scripts/build_web.mjs (from release/05-desktop).
import { cpSync, rmSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = join(dirname(fileURLToPath(import.meta.url)), '..');
const www = join(here, '..', '..', 'dist', 'www');
const out = join(here, 'app');
if (!existsSync(join(www, 'index.html'))) {
  console.error('No web build found. Run: node ../../scripts/build_web.mjs');
  process.exit(1);
}
rmSync(out, { recursive: true, force: true });
mkdirSync(out, { recursive: true });
// the service worker and the Android WebView page aren't used on the desktop
cpSync(www, out, { recursive: true, filter: (p) => !/(sw\.js|update-webview\.html)$/.test(p) });
console.log('app/ ready (PC edition starts with ?edition=pc)');
