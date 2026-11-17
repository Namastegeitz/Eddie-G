// Writes release/README.md: the launch checklist with ✅ green checks, from
// release/checklist.json (steps, tips) and release/status.json (progress, synced
// from the live checklist page by Claude).
//   node scripts/release_readme.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const cl = JSON.parse(readFileSync(join(root, 'release/checklist.json'), 'utf8'));
const st = JSON.parse(readFileSync(join(root, 'release/status.json'), 'utf8'));
const cfg = JSON.parse(readFileSync(join(root, 'release/config.json'), 'utf8'));
const LIVE = 'https://claude.ai/artifact/Kz4xL5JoZfgC9bDzBAtQ1Y';
const BUGS = 'https://claude.ai/artifact/NiybkudZiDL75qvRyHvHuC';
const GAME = 'https://claude.ai/artifact/6ARndyKdPDcqbRxZ7ohyMY';

const status = st.status || {};
const all = cl.phases.flatMap((p) => p.steps.map((s) => ({ ...s, phase: p })));
const stateOf = (id) => (status[id] && status[id].state) || 'todo';
const isDone = (id) => ['done', 'skip'].includes(stateOf(id));
const ready = (s) => (s.needs || []).every(isDone);
const ICON = { done: '✅', doing: '🔄', skip: '⏭️', todo: '⬜' };
const OWNER = { you: 'You', claude: 'Claude', both: 'You + Claude' };
const day = (iso) => (iso ? new Date(iso).toISOString().slice(0, 10) : '');
const bar = (n, d) => { const k = Math.round((n / Math.max(1, d)) * 10); return '🟩'.repeat(k) + '⬜'.repeat(10 - k); };
const title = (id) => (all.find((s) => s.id === id) || { title: id }).title;

const req = all.filter((s) => !s.optional);
const doneReq = req.filter((s) => isDone(s.id)).length;
const pct = Math.round((doneReq / req.length) * 100);
const yours = all.filter((s) => !isDone(s.id) && s.owner !== 'claude' && ready(s));
const claudes = all.filter((s) => !isDone(s.id) && s.owner !== 'you' && ready(s));

let md = `# **MONKEY SEE, MONKEY DO** · Launch checklist

From beta to the App Store, Google Play, Steam, GOG, itch.io and more.

| | |
|---|---|
| **Live checklist** (tick steps, see tips, progress log) | ${LIVE} |
| **Bug & feedback reports** (testers write here) | ${BUGS} |
| **Playable game** (private) | ${GAME} |
| **Public beta link** (after GitHub Pages is on) | ${cfg.betaUrl} |

All three pages are in the **MONKEY SEE, MONKEY DO** folder on your claude.ai Artifacts screen.

> This file mirrors the live checklist. You tick steps on the live page; Claude
> ticks its own and copies the progress here (ask Claude to *sync the checklist*).
> Last synced: ${day(st.synced)}.

## Progress

**${pct}% done** ${bar(doneReq, req.length)} · ${all.filter((s) => isDone(s.id)).length} of ${all.length} steps
(${req.length} required, ${all.length - req.length} optional) · waiting on you: **${yours.length}** · Claude's queue: **${claudes.length}**

| Phase | Progress | Cost | Folder |
|---|---|---|---|
${cl.phases.map((p) => {
  const r0 = p.steps.filter((s) => !s.optional);
  const r = r0.length ? r0 : p.steps;
  const d = r.filter((s) => isDone(s.id)).length;
  return `| [${p.name}](#${anchor(p.name)}) | ${r0.length && d === r.length ? '✅ ' : ''}${d}/${r.length}${r0.length ? '' : ' (optional)'} | ${p.cost} | \`${p.folder}\` |`;
}).join('\n')}

Legend: ✅ done · 🔄 working on it · ⬜ to do · ⏭️ skipped. Owner: **You**, **Claude**, or **You + Claude**.

## Up next

**Your next steps**
${yours.slice(0, 4).map((s) => `- ${ICON[stateOf(s.id)]} **${s.title}** (${s.phase.name}). ${s.tip}`).join('\n') || '- Nothing waiting on you right now.'}

**Claude's next steps**
${claudes.slice(0, 3).map((s) => `- ${ICON[stateOf(s.id)]} **${s.title}** (${s.phase.name})`).join('\n') || '- Nothing in Claude\'s queue right now.'}

`;

function anchor(name) {
  return name.toLowerCase().replace(/[^a-z0-9 -]/g, '').trim().replace(/ +/g, '-');
}

for (const p of cl.phases) {
  const r0 = p.steps.filter((s) => !s.optional);
  const r = r0.length ? r0 : p.steps;
  const d = r.filter((s) => isDone(s.id)).length;
  md += `## ${p.name}\n\n${p.goal}\n\n**${d}/${r.length}** ${bar(d, r.length)} · Cost: ${p.cost} · Folder: [\`${p.folder}\`](${p.folder.replace(/^release\/?/, './') || './'})\n\n`;
  for (const s of p.steps) {
    const x = status[s.id] || {};
    const state = stateOf(s.id);
    const meta = [OWNER[s.owner], s.optional ? 'optional' : '', state === 'done' ? `done by ${x.by === 'claude' ? 'Claude' : 'you'} ${day(x.at)}` : state === 'doing' ? 'in progress' : state === 'skip' ? 'skipped' : ''].filter(Boolean).join(' · ');
    const waiting = (s.needs || []).filter((n) => !isDone(n));
    md += `- [${state === 'done' ? 'x' : ' '}] ${ICON[state]} **${s.title}** · ${meta}\n`;
    if (waiting.length && !isDone(s.id)) md += `  - After: ${waiting.map(title).join('; ')}\n`;
    if (x.note) md += `  - Note: ${x.note}\n`;
    md += `  <details><summary>How to do it</summary>\n\n  **Why:** ${s.why}\n\n${(s.how || []).map((h, i) => `  ${i + 1}. ${h}`).join('\n')}\n\n  **Tip:** ${s.tip}\n\n  **Done when:** ${s.done_when}${(s.links || []).length ? `\n\n  **Links:** ${s.links.map((l) => `[${l.label}](${l.url})`).join(' · ')}` : ''}\n  </details>\n\n`;
  }
}

md += `## What's in each folder

| Folder | What's inside |
|---|---|
| [00-shared](00-shared/) | Store text, age-rating answers, icons, banner art, screenshots for every store |
| [01-web-beta](01-web-beta/) | Beta link, QR code, web build zip (published to GitHub Pages by \`scripts/deploy_beta.sh\`) |
| [02-itch-io](02-itch-io/) | HTML5 upload zip (PC edition) and upload steps |
| [03-google-play](03-google-play/) | Android build steps, signing key steps, data-safety answers, \`build/\` for the .aab |
| [04-apple-app-store](04-apple-app-store/) | iPhone/iPad build steps, reviewer notes, \`build/\` log |
| [05-desktop](05-desktop/) | PC edition desktop app (Electron) for Steam, GOG, Microsoft, Epic |
| [06-steam](06-steam/) | Steam capsule art at exact sizes, store and upload steps |
| [07-gog](07-gog/) | GOG requirements and submission pitch |
| [08-more-stores](08-more-stores/) | Microsoft Store, Epic, Samsung Galaxy Store, Amazon |

## Bug reports and progress data

- **Testers** report bugs, confusing bits, ideas and a 1-5 fun rating on the
  Bug & Feedback page. Device details fill in by themselves. Invite testers by
  email as Editors (the only level that lets people outside an organization
  write). Each tester can only add to their own reports; only you change a
  report's status (New, Confirmed, Fixed, Won't fix) and reply.
- **Claude** reads the reports directly, fixes the minor bugs, runs all tests,
  and marks them Fixed with a reply.
- **Progress log:** every tick on the live checklist is recorded with who and
  when, and charted as steps done over time.

## Rebuild everything

\`\`\`
cd apps/monkey-see-monkey-do
node scripts/build_web.mjs            # game + public beta site (dist/site)
bash scripts/deploy_beta.sh           # publish the beta site to GitHub Pages
node scripts/build_release.mjs        # web zip, itch.io zip, desktop app folder
node scripts/make_store_art.cjs all   # icons, banners, Steam art, screenshots
node scripts/check_store_text.mjs     # store text lengths
node scripts/release_readme.mjs       # this file
\`\`\`
`;

writeFileSync(join(root, 'release/README.md'), md);
console.log(`release/README.md: ${pct}% done, ${all.length} steps, ${yours.length} waiting on you`);
