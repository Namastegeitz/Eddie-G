// Checks every FLOWSMITH data file against data/SCHEMA.md.
// Usage: node tests/validate-data.mjs            (all files)
//        node tests/validate-data.mjs chips-a.json (one file; cross-file links become warnings)
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const DATA = join(here, "..", "data");
const only = process.argv[2] || null;

const CATS = {
  genre: "g-", era: "er-", mood: "mo-", energy: "en-", groove: "gr-", key: "ke-",
  drums: "dr-", bass: "ba-", synths: "sy-", keys: "kb-", guitars: "gt-",
  orchestral: "or-", world: "wo-", vocals: "vo-", structure: "st-",
  production: "pr-", tuning: "tu-", usecase: "us-",
};
const EDIT_MODES = ["new", "compose", "extend", "cover", "replace", "stems", "lyrics"];
const BLOCKS = ["p", "h", "list", "table", "tip", "prompt"];
const ID_RE = /^[a-z0-9]+(-[a-z0-9]+)*$/;
// Lyria has no negative prompts: fragments must say what to include.
const NEG_RE = /\b(no|not|without|avoid|don't|dont|never|exclude|minus)\b/i;
// A short guard list; the rule is "no artist names" (gear names are fine).
const ARTISTS = /\b(drake|beyonc|taylor swift|kanye|dilla|dr\.? dre|metro boomin|travis scott|billie eilish|weeknd|daft punk|skrillex|aphex|zimmer|beatles|michael jackson|prince\b|madonna|eminem|kendrick|rihanna|adele|ed sheeran|bad bunny|burna|wizkid|fela|bob marley|nirvana|radiohead|tame impala|frank ocean|sza|post malone|calvin harris|avicii|deadmau5|kraftwerk|vangelis|john williams|morricone|pink floyd|led zeppelin|queen\b|metallica|kenny g|miles davis|coltrane)\b/i;

let errors = 0, warnings = 0;
const err = (f, m) => { errors++; console.log(`  ERROR ${f}: ${m}`); };
const warn = (f, m) => { warnings++; console.log(`  warn  ${f}: ${m}`); };
const words = (s) => String(s).trim().split(/\s+/).filter(Boolean).length;
const isStr = (v) => typeof v === "string" && v.trim().length > 0;

function load(file) {
  try { return JSON.parse(readFileSync(join(DATA, file), "utf8")); }
  catch (e) { err(file, `not valid JSON: ${e.message}`); return null; }
}

function checkText(file, where, s, { min = 1, max = 400, prompt = false } = {}) {
  if (!isStr(s)) return err(file, `${where}: missing text`);
  if (/<[a-z/][^>]*>/i.test(s)) err(file, `${where}: contains HTML`);
  if (/[“”‘’]/.test(s)) warn(file, `${where}: curly quotes`);
  const n = words(s);
  if (n < min || n > max) err(file, `${where}: ${n} words (want ${min}-${max})`);
  if (prompt) {
    const m = s.match(NEG_RE);
    if (m) err(file, `${where}: negative wording "${m[0]}" (Lyria has no negative prompts)`);
  }
  const a = s.match(ARTISTS);
  if (a) err(file, `${where}: names an artist "${a[0]}"`);
}

const files = readdirSync(DATA).filter((f) => f.endsWith(".json")).sort();
const targets = only ? files.filter((f) => f === only) : files;
if (only && !targets.length) { console.log(`No data/${only}`); process.exit(1); }

// ---- chips (all files together, so cross-file "pairs" can be checked) ----
const allChipIds = new Set();
const chipFiles = files.filter((f) => /^chips-.*\.json$/.test(f));
const chipsByFile = {};
for (const f of chipFiles) {
  const j = load(f); if (!j) continue;
  chipsByFile[f] = j;
  for (const c of j.chips || []) if (c && c.id) allChipIds.add(c.id);
}
const seen = new Map();
for (const f of chipFiles) {
  if (!targets.includes(f)) continue;
  const j = chipsByFile[f]; if (!j) continue;
  console.log(`${f}: ${(j.chips || []).length} chips`);
  if (!Array.isArray(j.chips)) { err(f, "missing chips array"); continue; }
  for (const [i, c] of j.chips.entries()) {
    const at = `chips[${i}] ${c && c.id}`;
    if (!c || typeof c !== "object") { err(f, `${at}: not an object`); continue; }
    if (!ID_RE.test(c.id || "")) err(f, `${at}: bad id`);
    if (seen.has(c.id)) err(f, `${at}: duplicate id (also in ${seen.get(c.id)})`); else seen.set(c.id, f);
    if (!CATS[c.cat]) err(f, `${at}: unknown cat "${c.cat}"`);
    else if (!String(c.id).startsWith(CATS[c.cat])) err(f, `${at}: id should start with ${CATS[c.cat]}`);
    if (!isStr(c.group)) err(f, `${at}: missing group`);
    checkText(f, `${at}.label`, c.label, { min: 1, max: 5 });
    checkText(f, `${at}.prompt`, c.prompt, { min: 3, max: 25, prompt: true });
    checkText(f, `${at}.desc`, c.desc, { min: 5, max: 70 });
    if (c.bpm !== undefined) {
      const ok = Array.isArray(c.bpm) && c.bpm.length === 2 && c.bpm.every((n) => Number.isInteger(n) && n >= 40 && n <= 220) && c.bpm[0] <= c.bpm[1];
      if (!ok) err(f, `${at}: bad bpm ${JSON.stringify(c.bpm)}`);
    }
    if (c.pairs !== undefined) {
      if (!Array.isArray(c.pairs) || c.pairs.length > 6) err(f, `${at}: pairs must be an array of up to 6 ids`);
      else for (const p of c.pairs) if (!allChipIds.has(p)) (only ? warn : warn)(f, `${at}: pairs -> unknown id "${p}"`);
    }
    const extra = Object.keys(c).filter((k) => !["id", "cat", "group", "label", "prompt", "desc", "bpm", "pairs"].includes(k));
    if (extra.length) warn(f, `${at}: extra fields ${extra.join(",")}`);
  }
}

// ---- beats ----
if (targets.includes("beats.json")) {
  const j = load("beats.json");
  if (j) {
    console.log(`beats.json: ${(j.patterns || []).length} patterns`);
    const ids = new Set();
    for (const [i, p] of (j.patterns || []).entries()) {
      const at = `patterns[${i}] ${p.id}`;
      if (!ID_RE.test(p.id || "") || !p.id.startsWith("bt-")) err("beats.json", `${at}: id must be bt-...`);
      if (ids.has(p.id)) err("beats.json", `${at}: duplicate id`); ids.add(p.id);
      for (const k of ["name", "genre", "timeSig", "desc", "prompt"]) if (!isStr(p[k])) err("beats.json", `${at}: missing ${k}`);
      if (![12, 16, 32].includes(p.steps)) err("beats.json", `${at}: steps must be 12, 16 or 32`);
      if (!(Number.isInteger(p.swing) && p.swing >= 50 && p.swing <= 75)) err("beats.json", `${at}: swing 50-75`);
      if (!(Array.isArray(p.bpm) && p.bpm.length === 2 && p.bpm[0] <= p.bpm[1])) err("beats.json", `${at}: bad bpm`);
      if (!Array.isArray(p.lanes) || p.lanes.length < 2) err("beats.json", `${at}: need 2+ lanes`);
      for (const l of p.lanes || []) {
        if (!isStr(l.inst)) err("beats.json", `${at}: lane missing inst`);
        if (typeof l.hits !== "string" || l.hits.length !== p.steps || /[^xXo.]/.test(l.hits)) err("beats.json", `${at}: lane ${l.inst} hits must be ${p.steps} chars of x X o .`);
      }
      checkText("beats.json", `${at}.prompt`, p.prompt, { min: 6, max: 40, prompt: true });
      checkText("beats.json", `${at}.desc`, p.desc, { min: 6, max: 80 });
    }
  }
}

// ---- recipes ----
if (targets.includes("recipes.json")) {
  const j = load("recipes.json");
  if (j) {
    console.log(`recipes.json: ${(j.recipes || []).length} recipes, ${(j.tunings || []).length} tunings, ${(j.edits || []).length} edits`);
    const ids = new Set();
    const uniq = (id, at) => { if (ids.has(id)) err("recipes.json", `${at}: duplicate id`); ids.add(id); if (!ID_RE.test(id || "")) err("recipes.json", `${at}: bad id`); };
    for (const [i, r] of (j.recipes || []).entries()) {
      const at = `recipes[${i}] ${r.id}`; uniq(r.id, at);
      if (!String(r.id).startsWith("rc-")) err("recipes.json", `${at}: id must be rc-...`);
      for (const k of ["title", "genre", "key", "why"]) if (!isStr(r[k])) err("recipes.json", `${at}: missing ${k}`);
      if (!Number.isInteger(r.bpm) || r.bpm < 40 || r.bpm > 220) err("recipes.json", `${at}: bad bpm`);
      if (typeof r.vocals !== "boolean") err("recipes.json", `${at}: vocals must be true/false`);
      if (!Array.isArray(r.tags)) err("recipes.json", `${at}: tags must be an array`);
      checkText("recipes.json", `${at}.prompt`, r.prompt, { min: 35, max: 120, prompt: true });
      if (r.vocals === false && !/instrumental/i.test(r.prompt)) warn("recipes.json", `${at}: no-vocal recipe should say "instrumental"`);
    }
    for (const [i, t] of (j.tunings || []).entries()) {
      const at = `tunings[${i}] ${t.id}`; uniq(t.id, at);
      if (!String(t.id).startsWith("tn-")) err("recipes.json", `${at}: id must be tn-...`);
      for (const k of ["label", "instrument", "notes", "desc"]) if (!isStr(t[k])) err("recipes.json", `${at}: missing ${k}`);
      checkText("recipes.json", `${at}.prompt`, t.prompt, { min: 3, max: 30, prompt: true });
    }
    for (const [i, e] of (j.edits || []).entries()) {
      const at = `edits[${i}] ${e.id}`; uniq(e.id, at);
      if (!String(e.id).startsWith("ed-")) err("recipes.json", `${at}: id must be ed-...`);
      if (!EDIT_MODES.includes(e.mode)) err("recipes.json", `${at}: bad mode ${e.mode}`);
      for (const k of ["label", "template", "example", "when"]) if (!isStr(e[k])) err("recipes.json", `${at}: missing ${k}`);
      checkText("recipes.json", `${at}.example`, e.example, { min: 3, max: 90 });
    }
  }
}

// ---- learn (and flow-guide, same shape) ----
for (const lf of ["learn.json", "flow-guide.json"]) {
  if (!targets.includes(lf)) continue;
  const j = load(lf);
  if (!j) continue;
  let n = 0;
  const ids = new Set();
  for (const s of j.sections || []) {
    if (!isStr(s.id) || !isStr(s.title)) err(lf, `section missing id/title`);
    for (const a of s.articles || []) {
      n++;
      const at = `${s.id}/${a.id}`;
      if (!ID_RE.test(a.id || "")) err(lf, `${at}: bad id`);
      if (ids.has(a.id)) err(lf, `${at}: duplicate id`); ids.add(a.id);
      if (!isStr(a.title) || !isStr(a.summary)) err(lf, `${at}: missing title/summary`);
      if (!Array.isArray(a.body) || !a.body.length) err(lf, `${at}: empty body`);
      for (const [bi, b] of (a.body || []).entries()) {
        const bat = `${at}.body[${bi}]`;
        if (!BLOCKS.includes(b.type)) { err(lf, `${bat}: bad type ${b.type}`); continue; }
        if (b.type === "list") { if (!Array.isArray(b.items) || !b.items.every(isStr)) err(lf, `${bat}: list items`); b.items?.forEach((t, k) => checkText(lf, `${bat}.items[${k}]`, t, { max: 120 })); }
        else if (b.type === "table") {
          if (!Array.isArray(b.head) || !Array.isArray(b.rows)) { err(lf, `${bat}: table needs head and rows`); continue; }
          for (const r of b.rows) if (!Array.isArray(r) || r.length !== b.head.length) err(lf, `${bat}: row length ${r && r.length} != head ${b.head.length}`);
        } else checkText(lf, `${bat}`, b.text, { max: 220, prompt: b.type === "prompt" });
      }
    }
  }
  console.log(`${lf}: ${(j.sections || []).length} sections, ${n} articles`);
}

console.log(`\n${errors} errors, ${warnings} warnings`);
process.exit(errors ? 1 : 0);
