// Builds js/vendor/sentry.min.js from the official @sentry/browser package
// (MIT, Functional Software Inc. dba Sentry). The game loads it only in builds
// that have a Sentry DSN in release/config.json, so other builds don't carry it.
//   node scripts/vendor_sentry.mjs [version]
import { execFileSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync, rmSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const version = process.argv[2] || '11.19.0';
const work = mkdtempSync(join(tmpdir(), 'sentry-'));
try {
  writeFileSync(join(work, 'package.json'), JSON.stringify({ name: 'v', private: true }));
  execFileSync('npm', ['install', '--ignore-scripts', '--no-audit', '--no-fund', `@sentry/browser@${version}`], { cwd: work, stdio: 'inherit' });
  writeFileSync(join(work, 'entry.js'), "export { init, captureException, captureMessage, setTag, setContext, close } from '@sentry/browser';\n");
  const out = join(root, 'js/vendor/sentry.min.js');
  execFileSync('npx', ['--yes', 'esbuild@0.24.2', join(work, 'entry.js'), '--bundle', '--format=iife', '--global-name=Sentry', '--minify', '--target=es2020,chrome87,safari14,firefox78', '--legal-comments=none', `--outfile=${out}`], { cwd: work, stdio: 'inherit' });
  const lic = readFileSync(join(work, 'node_modules/@sentry/browser/LICENSE'), 'utf8').split('\n').slice(0, 3).join(' ');
  writeFileSync(out, `/* @sentry/browser ${version} (MIT). ${lic.trim()} */\n` + readFileSync(out, 'utf8'));
  console.log(`js/vendor/sentry.min.js: @sentry/browser ${version}, ${(statSync(out).size / 1024).toFixed(0)} KB`);
} finally {
  rmSync(work, { recursive: true, force: true });
}
