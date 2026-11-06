// Injects portfolio.json into index.html and writes dist/index.html.
// Run: node apps/progress-desk/build.mjs
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const data = JSON.parse(readFileSync(join(here, "portfolio.json"), "utf8"));
const tpl = readFileSync(join(here, "index.html"), "utf8");

if (!tpl.includes("__PORTFOLIO_JSON__")) throw new Error("index.html has no __PORTFOLIO_JSON__ placeholder");
const json = JSON.stringify(data);
if (/<\/script/i.test(json)) throw new Error("portfolio.json contains a </script sequence; escape it before inlining");

const out = tpl.replace("__PORTFOLIO_JSON__", json);
mkdirSync(join(here, "dist"), { recursive: true });
writeFileSync(join(here, "dist", "index.html"), out);
console.log(`dist/index.html  ${out.length} bytes  (${data.artifacts.length} artifacts, ${data.apps.length} apps)`);
