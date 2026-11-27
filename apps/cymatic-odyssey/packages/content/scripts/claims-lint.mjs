#!/usr/bin/env node
// Claims linter (spec 9.6). Fails (exit 1) when a never-say term or trademark appears in scanned
// content outside an allowlisted critical-discussion line. Run from the project root: pnpm claims:lint
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../../..");
const cfg = JSON.parse(readFileSync(join(here, "../claims-lint.config.json"), "utf8"));
const never = JSON.parse(readFileSync(join(here, "../src/never-say.json"), "utf8")).terms.map((t) => ({ re: new RegExp(t.pattern, "gi"), why: t.why }));
const TEXT = /\.(md|json|html|tsx?|jsx?|py|txt|csv)$/i;
const excluded = (rel) => cfg.exclude.some((e) => rel === e || rel.startsWith(e + "/"));

function* walk(p) {
  if (!existsSync(p)) return;
  const st = statSync(p);
  if (st.isDirectory()) {
    for (const n of readdirSync(p)) if (n !== "node_modules" && !n.startsWith(".")) yield* walk(join(p, n));
  } else if (TEXT.test(p)) yield p;
}

const hits = [];
let files = 0;
for (const inc of cfg.include) {
  for (const f of walk(join(root, inc))) {
    const rel = relative(root, f);
    if (excluded(rel)) continue;
    files++;
    // drop embedded data URIs / base64 so random letters can't match
    const lines = readFileSync(f, "utf8").replace(/data:[a-z/+-]+;base64,[A-Za-z0-9+/=]+/g, "data:").split("\n");
    lines.forEach((line, i) => {
      for (const t of never) {
        t.re.lastIndex = 0;
        let m;
        while ((m = t.re.exec(line))) {
          const ok = cfg.allow.some((a) => a.path === rel && line.includes(a.contains));
          if (!ok) hits.push({ file: rel, line: i + 1, term: m[0], why: t.why, text: line.trim().slice(0, 140) });
        }
      }
    });
  }
}
if (hits.length) {
  console.error(`claims-lint: ${hits.length} problem(s) in ${files} files`);
  for (const h of hits) console.error(`  ${h.file}:${h.line}  "${h.term}" (${h.why})  ${h.text}`);
  process.exit(1);
}
console.log(`claims-lint: OK (${files} files, ${never.length} rules)`);
