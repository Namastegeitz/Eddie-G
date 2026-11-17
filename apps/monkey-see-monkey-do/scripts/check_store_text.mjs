// Checks every field in release/00-shared/store-text.md against its store limit.
//   node scripts/check_store_text.mjs
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const md = readFileSync(join(root, 'release/00-shared/store-text.md'), 'utf8');
const re = /### (\S+) \(limit (\d+)\)\n```\n([\s\S]*?)\n```/g;
let m;
let bad = 0;
let n = 0;
while ((m = re.exec(md))) {
  n++;
  const [, name, limit, text] = m;
  const len = [...text].length; // characters, as the stores count them
  const ok = len <= Number(limit);
  if (!ok) bad++;
  console.log(`${ok ? 'ok  ' : 'LONG'} ${name.padEnd(18)} ${String(len).padStart(4)} / ${limit}`);
  if (name === 'apple-keywords' && /\s/.test(text)) { console.log('     apple-keywords: remove spaces'); bad++; }
}
console.log(`${n} fields, ${bad} over the limit`);
if (bad) process.exit(1);
