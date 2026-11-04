// Packs the whole game into single HTML files (code, styles, fonts inline):
//   dist/monkey-see-monkey-do.html   one file that plays when opened from disk or any host
//   dist/artifact/index.html         the same content in the shape a claude.ai artifact page expects
// Run from the app folder:  node scripts/build_single.mjs
// Needs esbuild (fetched by npx on first run).
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const dist = join(root, 'dist');
mkdirSync(join(dist, 'artifact'), { recursive: true });

const tmp = join(dist, '.bundle.js');
execFileSync('npx', ['--yes', 'esbuild@0.24.2', join(root, 'js/main.js'), '--bundle', '--format=iife', '--minify', '--target=es2020,chrome87,safari14,firefox78', '--legal-comments=none', `--outfile=${tmp}`], { stdio: 'inherit' });
let js = readFileSync(tmp, 'utf8').replace(/<\/script/gi, '<\\/script');
rmSync(tmp);

let css = readFileSync(join(root, 'css/game.css'), 'utf8');
css = css.replace(/url\('\.\.\/assets\/fonts\/([^']+)'\)/g, (_, f) => `url(data:font/woff2;base64,${readFileSync(join(root, 'assets/fonts', f)).toString('base64')})`);

const html = readFileSync(join(root, 'index.html'), 'utf8');
const body = html.slice(html.indexOf('<!--APP-START-->') + 16, html.indexOf('<!--APP-END-->')).trim();
const icon = `data:image/svg+xml;base64,${readFileSync(join(root, 'assets/icons/icon.svg')).toString('base64')}`;
let commit = '';
try { commit = execFileSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: root }).toString().trim(); } catch { /* not a git checkout */ }
const stamp = `<!-- Monkey See, Monkey Do · built ${new Date().toISOString().slice(0, 10)}${commit ? ' from ' + commit : ''} -->`;

const standalone = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Monkey See, Monkey Do</title>
<meta name="theme-color" content="#0e3527">
<link rel="icon" href="${icon}">
<style>${css}</style>
</head>
<body>
${stamp}
${body}
<script>window.MSMD_NO_SW = true;</script>
<script>${js}</script>
</body>
</html>
`;
writeFileSync(join(dist, 'monkey-see-monkey-do.html'), standalone);

// Artifact pages get wrapped in their own <html>/<head>/<body>, so only the content goes here.
const artifact = `<title>Monkey See, Monkey Do</title>
<meta name="claude:viewport-fit-sides" content="cover">
<style>${css}</style>
${stamp}
${body}
<script>window.MSMD_NO_SW = true;</script>
<script>${js}</script>
`;
writeFileSync(join(dist, 'artifact', 'index.html'), artifact);
const kb = (s) => (Buffer.byteLength(s) / 1024).toFixed(0) + ' KB';
console.log(`dist/monkey-see-monkey-do.html  ${kb(standalone)}\ndist/artifact/index.html       ${kb(artifact)}`);
