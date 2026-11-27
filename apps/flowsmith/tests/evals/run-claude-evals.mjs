// Runs the saved eval cases through Claude (the Composer agent) and scores each answer with the
// app's rubric. This SPENDS MONEY on the Anthropic API (about 20 calls), so it is never run
// automatically. Usage:
//   ANTHROPIC_API_KEY=sk-ant-... node tests/evals/run-claude-evals.mjs [model]
// Blocks a release (exit 1) if the average rubric score drops below the saved baseline.
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import Anthropic from "@anthropic-ai/sdk";
import * as E from "../../assets/js/engine.js";
import { buildRequest, parseLooseJson } from "../../assets/js/ai.js";

const here = new URL(".", import.meta.url);
const data = (f) => JSON.parse(readFileSync(new URL("../../data/" + f, here)));
const cat = E.makeCatalog(["chips-sound.json", "chips-instruments.json", "chips-voice-mix.json"].map(data));
const { cases, minScore } = JSON.parse(readFileSync(new URL("cases.json", here)));
const model = process.argv[2] || "claude-opus-5-5";
const baselineFile = new URL("claude-baseline.json", here);
const client = new Anthropic();

let total = 0, failed = 0;
for (const c of cases) {
  const p = E.parseQuery(c.query, cat);
  const st = { ...E.blankState(), query: c.query, brief: p.rest, bpm: p.bpm, key: p.key || "", length: p.length || "2m", language: p.language || "English", vocals: p.vocals || "auto", chips: [...new Set([...p.chipIds, ...c.chips.filter((id) => cat.byId.has(id))])] };
  const req = buildRequest("composer", { state: st, draft: E.buildPrompt(st, cat).prompt, catalog: cat, lessons: [] });
  const params = { model, max_tokens: 16000, system: req.system, messages: [{ role: "user", content: req.task }], output_config: { effort: "medium", format: { type: "json_schema", schema: req.schema } } };
  try {
    const res = model.startsWith("claude-haiku")
      ? await client.messages.create(params)
      : await client.beta.messages.create({ ...params, betas: ["server-side-fallback-2026-07-01"], fallbacks: "default" });
    if (res.stop_reason === "refusal") throw new Error("refused");
    const o = parseLooseJson(res.content.filter((b) => b.type === "text").map((b) => b.text).join(""));
    const crit = E.critique(o.prompt, o.lyrics, st, cat);
    const misses = (c.expect.includes || []).filter((s) => !String(o.prompt).toLowerCase().includes(s.toLowerCase().replace(/^nstrumental$/, "instrumental")));
    total += crit.score;
    const bad = crit.score < minScore || !crit.checks.find((x) => x.id === "positive").ok || !crit.checks.find((x) => x.id === "artists").ok;
    if (bad) failed++;
    console.log(`${bad ? "FAIL" : "ok  "} ${c.id} score ${crit.score}${misses.length ? ` (didn't mention: ${misses.join(", ")})` : ""}`);
  } catch (e) {
    failed++;
    console.log(`FAIL ${c.id}: ${e.message}`);
  }
}
const avg = Math.round(total / cases.length);
const base = existsSync(baselineFile) ? JSON.parse(readFileSync(baselineFile)).average : null;
console.log(`claude evals (${model}): ${cases.length - failed}/${cases.length} passed, average ${avg}${base !== null ? `, baseline ${base}` : ""}`);
if (base === null) writeFileSync(baselineFile, JSON.stringify({ model, average: avg, date: new Date().toISOString() }, null, 2));
process.exit(failed || (base !== null && avg < base - 3) ? 1 : 0);
