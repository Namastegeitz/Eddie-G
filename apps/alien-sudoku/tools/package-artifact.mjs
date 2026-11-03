#!/usr/bin/env node
/* Packages the web build as a claude.ai artifact: a page file plus its assets.
   The artifact host wraps the page in its own <html>/<head>/<body> and does not
   allow service workers, so this builds without the service worker and strips
   the document skeleton from index.html.

   node tools/package-artifact.mjs <outDir>
   -> <outDir>/alien-sudoku.html (the page) and <outDir>/assets, space, icons ... */
import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync, rmSync, readdirSync, statSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = process.argv[2];
if (!out) { console.error('usage: node tools/package-artifact.mjs <outDir>'); process.exit(1); }

execSync(`npx vite build --outDir "${out}" --emptyOutDir`, { cwd: root, stdio: 'inherit', env: { ...process.env, VITE_NO_SW: '1' } });

for (const f of readdirSync(out)) {
  if (/^(sw|workbox-.*|registerSW)\.js$|^manifest\.webmanifest$/.test(f)) rmSync(join(out, f));
}

let html = readFileSync(join(out, 'index.html'), 'utf8');
const head = html.match(/<head>([\s\S]*?)<\/head>/)[1];
const body = html.match(/<body>([\s\S]*?)<\/body>/)[1];
const keepHead = head
  .split('\n')
  .filter((l) => !/<meta charset|<meta name="viewport"|rel="manifest"|<meta name="(apple-mobile-web-app|mobile-web-app)/.test(l))
  .join('\n');
const page = `<title>Alien Sudoku</title>
<meta name="claude:viewport-fit-sides" content="cover">
${keepHead.replace(/\s*<title>[^<]*<\/title>/, '')}
${body}`;
rmSync(join(out, 'index.html'));
writeFileSync(join(out, 'alien-sudoku.html'), page);

const files = [];
(function walk(dir) {
  for (const f of readdirSync(dir)) {
    const p = join(dir, f);
    if (statSync(p).isDirectory()) walk(p);
    else if (f !== 'alien-sudoku.html') files.push(relative(out, p));
  }
})(out);
writeFileSync(join(out, 'files.json'), JSON.stringify(files, null, 1));
console.log(`page: ${join(out, 'alien-sudoku.html')}\n${files.length} supporting files`);
