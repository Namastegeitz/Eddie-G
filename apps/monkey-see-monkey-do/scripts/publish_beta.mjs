// Puts the web build where GitHub Pages serves it, for the public beta link:
//   <repo>/docs/                          landing page (Play button, QR code, tester notes)
//   <repo>/docs/monkey-see-monkey-do/     the game (a copy of dist/www)
// GitHub Pages: Settings > Pages > Deploy from a branch > this branch, folder /docs.
// The game is then at https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/
// Run after scripts/build_web.mjs (it runs this for you).
import { cpSync, rmSync, mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const www = join(root, 'dist', 'www');
const docs = join(root, '..', '..', 'docs');
const game = join(docs, 'monkey-see-monkey-do');
if (!existsSync(join(www, 'index.html'))) throw new Error('dist/www is missing: run node scripts/build_web.mjs first');

rmSync(game, { recursive: true, force: true });
mkdirSync(game, { recursive: true });
cpSync(www, game, { recursive: true });

const version = (readFileSync(join(root, 'js/main.js'), 'utf8').match(/const VERSION = '([^']+)'/) || [])[1] || '';
const stamp = `${version} · ${new Date().toISOString().slice(0, 10)}`;
writeFileSync(join(docs, 'index.html'), readFileSync(join(root, 'beta/index.html'), 'utf8').replaceAll('__BUILD__', stamp));
cpSync(join(root, 'beta/qr.svg'), join(docs, 'qr.svg'));
cpSync(join(root, 'beta/qr.png'), join(docs, 'qr.png'));
writeFileSync(join(docs, '.nojekyll'), ''); // serve files as they are
writeFileSync(join(docs, 'README.md'), `# Public beta (GitHub Pages)

This folder is the public beta website. It is generated: do not edit it by hand.

- \`index.html\`: landing page (from \`apps/monkey-see-monkey-do/beta/\`)
- \`monkey-see-monkey-do/\`: the game (a copy of \`apps/monkey-see-monkey-do/dist/www\`)

Rebuild with \`node apps/monkey-see-monkey-do/scripts/build_web.mjs\` (it copies here).
Served by GitHub Pages from this branch's \`/docs\` folder:
https://namastegeitz.github.io/Eddie-G/
`);
console.log(`docs/ ready for GitHub Pages (beta ${stamp})`);
