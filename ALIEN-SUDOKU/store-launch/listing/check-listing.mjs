#!/usr/bin/env node
/* Checks every listing field against each store's character limit and writes listing.md.
   node check-listing.mjs   (exit code 1 if anything is over a limit or still TODO) */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const listing = JSON.parse(readFileSync(join(here, 'listing.json'), 'utf8'));
const LABEL = {
  appName: 'App name', appleSubtitle: 'Subtitle (App Store)', applePromoText: 'Promotional text (App Store)',
  appleKeywords: 'Keywords (App Store)', googleShortDescription: 'Short description (Google Play)',
  steamShortDescription: 'Short description (Steam)', fullDescription: 'Full description',
  mobileAdsLine: 'Ads line (phones only)', pcLine: 'PC line (PC stores only)', whatsNew: "What's new",
  categories: 'Categories', copyright: 'Copyright', supportEmail: 'Support email', supportUrl: 'Support URL',
  privacyPolicyUrl: 'Privacy policy URL',
};
// Stores count characters (Unicode code points), not bytes.
const len = (s) => [...s].length;
let problems = 0;
let md = '# Store listing text: Alien Sudoku\n\nGenerated from `listing.json` by `check-listing.mjs`. Edit the JSON, then run the script again.\n\n';
for (const [key, f] of Object.entries(listing)) {
  if (key.startsWith('_')) continue;
  md += `## ${LABEL[key] || key}\n\n`;
  if (key === 'categories') {
    for (const [store, v] of Object.entries(f)) md += `- **${store}**: ${v}\n`;
    md += '\n';
    continue;
  }
  const v = f.value;
  const checks = Object.entries(f.limits || {}).map(([store, max]) => {
    const n = len(v);
    const ok = n <= max;
    if (!ok) problems++;
    return `${ok ? '✅' : '❌'} ${store} ${n}/${max}`;
  });
  if (/^TODO/.test(v)) { problems++; checks.push('⬜ to fill in'); }
  md += (v.includes('\n') ? '```text\n' + v + '\n```\n' : `> ${v}\n`) + '\n';
  if (checks.length) md += `${checks.join(' · ')}\n\n`;
  if (f.alternates) md += `Alternates: ${f.alternates.join(' · ')}\n\n`;
  if (f.note) md += `_${f.note}_\n\n`;
  console.log(`${(LABEL[key] || key).padEnd(34)} ${checks.join('  ') || '-'}`);
}
writeFileSync(join(here, 'listing.md'), md);
console.log(problems ? `\n${problems} field(s) need attention (over a limit or still TODO).` : '\nAll fields fit.');
process.exit(problems ? 1 : 0);
