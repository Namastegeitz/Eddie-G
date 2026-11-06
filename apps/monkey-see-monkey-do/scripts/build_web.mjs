// Builds dist/www: the phone-ready version of the game.
//   - one bundled, minified script (app.js) that older phone browsers can run
//   - styles, fonts, icons, manifest and an offline service worker
// It is what you host on the web (install from the browser on any phone),
// and what the iOS and Android apps load (mobile/capacitor.config.json -> webDir).
//
//   node scripts/build_web.mjs
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync, rmSync, cpSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'dist', 'www');
// Phones we aim at: iPhone iOS 14.5+ Safari, Android Chrome / WebView 87+ (2020 onwards)
const TARGET = 'es2020,chrome87,safari14,firefox78';

rmSync(out, { recursive: true, force: true });
mkdirSync(out, { recursive: true });

execFileSync('npx', ['--yes', 'esbuild@0.24.2', join(root, 'js/main.js'), '--bundle', '--format=iife', '--minify', `--target=${TARGET}`, '--legal-comments=none', `--outfile=${join(out, 'app.js')}`], { stdio: 'inherit' });
execFileSync('npx', ['--yes', 'esbuild@0.24.2', join(root, 'css/game.css'), '--minify', `--target=${TARGET}`, `--outfile=${join(out, 'css/game.css')}`], { stdio: 'inherit' });

cpSync(join(root, 'assets'), join(out, 'assets'), { recursive: true, filter: (p) => !p.endsWith('.txt') || p.includes('LICENSE') });
cpSync(join(root, 'manifest.webmanifest'), join(out, 'manifest.webmanifest'));
cpSync(join(root, 'sw.js'), join(out, 'sw.js'));
cpSync(join(root, 'mobile', 'update-webview.html'), join(out, 'update-webview.html'));

let html = readFileSync(join(root, 'index.html'), 'utf8');
html = html.replace('<script type="module" src="js/main.js"></script>', '<script src="app.js" defer></script>');
if (!html.includes('src="app.js"')) throw new Error('index.html: could not swap in app.js');
writeFileSync(join(out, 'index.html'), html);

execFileSync('python3', [join(root, 'scripts/build_sw.py'), out], { stdio: 'inherit' });
const kb = (f) => (readFileSync(join(out, f)).length / 1024).toFixed(0) + ' KB';
console.log(`dist/www ready: app.js ${kb('app.js')}, css ${kb('css/game.css')}`);
if (!existsSync(join(out, 'assets/fonts/lilita-one.woff2'))) throw new Error('fonts missing from dist/www');
// keep the public beta site (GitHub Pages, /docs) in step with this build
execFileSync('node', [join(root, 'scripts/publish_beta.mjs')], { stdio: 'inherit' });
