// Runs the saved eval cases through the offline engine and the rubric. Free; runs in CI and before release.
// Fails (exit 1) if any case misses an expected property or scores under minScore.
import { readFileSync } from "node:fs";
import * as E from "../../assets/js/engine.js";
const here = new URL(".", import.meta.url);
const data = (f) => JSON.parse(readFileSync(new URL("../../data/" + f, here)));
const cat = E.makeCatalog(["chips-sound.json", "chips-instruments.json", "chips-voice-mix.json"].map(data));
const { cases, minScore } = JSON.parse(readFileSync(new URL("cases.json", here)));
let failed = 0, total = 0;
for (const c of cases) {
  const missingIds = c.chips.filter((id) => !cat.byId.has(id));
  const p = E.parseQuery(c.query, cat);
  const st = { ...E.blankState(), query: c.query, brief: p.rest, bpm: p.bpm, key: p.key || "", length: p.length || "2m", language: p.language || "English", vocals: p.vocals || "auto", chips: [...new Set([...p.chipIds, ...c.chips.filter((id) => cat.byId.has(id))])] };
  const { prompt, lyrics } = E.buildPrompt(st, cat);
  const crit = E.critique(prompt, lyrics, st, cat);
  const problems = [];
  if (missingIds.length) problems.push(`unknown chip ids ${missingIds.join(",")}`);
  for (const s of c.expect.includes || []) if (!prompt.toLowerCase().includes(s.toLowerCase())) problems.push(`missing "${s}"`);
  if (c.expect.vocals && c.expect.vocals !== "auto" && E.vocalIntent(st) !== c.expect.vocals) problems.push(`vocals ${E.vocalIntent(st)} != ${c.expect.vocals}`);
  if (!crit.checks.find((x) => x.id === "positive").ok) problems.push("negative wording");
  if (!crit.checks.find((x) => x.id === "artists").ok) problems.push("artist name");
  if (crit.score < minScore) problems.push(`score ${crit.score} < ${minScore}`);
  total += crit.score;
  if (problems.length) { failed++; console.log(`  FAIL ${c.id} (${crit.score}): ${problems.join("; ")}\n       ${prompt}`); }
}
console.log(`evals: ${cases.length - failed}/${cases.length} passed, average score ${Math.round(total / cases.length)}`);
process.exit(failed ? 1 : 0);
