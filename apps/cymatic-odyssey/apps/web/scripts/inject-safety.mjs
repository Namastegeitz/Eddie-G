// Builds packages/core-safety as a browser bundle (window.CLCSafety) and injects it into the
// single-file Voyage console, between the /*SAFETY*/ and /*END_SAFETY*/ markers.
// The console then sends every audio decision through the same Safety Guardian code the new app uses.
//   pnpm console:safety          rebuild and inject
//   pnpm console:safety --check  exit 1 if the console bundle is out of date
import { build } from "vite";
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const APP = resolve(dirname(fileURLToPath(import.meta.url)), "../../..");
const consolePath = resolve(APP, "console/index.html");

const out = await build({
  configFile: false,
  logLevel: "silent",
  build: {
    write: false,
    minify: true,
    lib: { entry: resolve(APP, "packages/core-safety/src/index.ts"), name: "CLCSafety", formats: ["iife"], fileName: () => "safety.js" },
  },
});
const chunk = (Array.isArray(out) ? out[0] : out).output.find((o) => o.type === "chunk");
const bundle = chunk.code.trim().replace(/<\/script/gi, "<\\/script");

const html = readFileSync(consolePath, "utf8");
const a = html.indexOf("/*SAFETY*/"), b = html.indexOf("/*END_SAFETY*/");
if (a < 0 || b < a) throw new Error("console/index.html has no /*SAFETY*/ ... /*END_SAFETY*/ markers");
const current = html.slice(a + "/*SAFETY*/".length, b);
if (process.argv.includes("--check")) {
  if (current.trim() !== bundle) {
    console.error("console safety bundle is out of date: run pnpm console:safety");
    process.exit(1);
  }
  console.log("console safety bundle: up to date");
} else {
  writeFileSync(consolePath, html.slice(0, a) + "/*SAFETY*/" + bundle + "\n" + html.slice(b));
  console.log(`console safety bundle: injected ${bundle.length} bytes`);
}
