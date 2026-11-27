// Sets the game's version everywhere and raises the build number by one.
//   node scripts/set_version.mjs 1.2.0     new version, build number + 1
//   node scripts/set_version.mjs           same version, build number + 1
// Writes: js/main.js (VERSION), release/config.json (version, build),
// mobile/android/app/build.gradle (versionName, versionCode),
// mobile/ios/App/App.xcodeproj/project.pbxproj (MARKETING_VERSION,
// CURRENT_PROJECT_VERSION) and release/05-desktop/package.json (version).
// Stores need the build number to go up with every upload.
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const cfgPath = join(root, 'release/config.json');
const cfg = JSON.parse(readFileSync(cfgPath, 'utf8'));
const version = process.argv[2] || cfg.version;
if (!/^\d+\.\d+\.\d+$/.test(version)) throw new Error(`Version must look like 1.2.0 (got ${version})`);
const build = (Number(cfg.build) || 1) + 1;

const edit = (rel, fn) => {
  const p = join(root, rel);
  const before = readFileSync(p, 'utf8');
  const after = fn(before);
  if (after === before) throw new Error(`${rel}: nothing changed (pattern not found?)`);
  writeFileSync(p, after);
};
edit('js/main.js', (s) => s.replace(/const VERSION = '[^']*';/, `const VERSION = '${version}';`));
edit('mobile/android/app/build.gradle', (s) => s.replace(/versionCode \d+/, `versionCode ${build}`).replace(/versionName "[^"]*"/, `versionName "${version}"`));
edit('mobile/ios/App/App.xcodeproj/project.pbxproj', (s) => s.replace(/CURRENT_PROJECT_VERSION = \d+;/g, `CURRENT_PROJECT_VERSION = ${build};`).replace(/MARKETING_VERSION = [^;]+;/g, `MARKETING_VERSION = ${version};`));
edit('release/05-desktop/package.json', (s) => s.replace(/"version": "[^"]*"/, `"version": "${version}"`));
cfg.version = version;
cfg.build = build;
writeFileSync(cfgPath, JSON.stringify(cfg, null, 2) + '\n');
console.log(`Version ${version}, build ${build}. Add a CHANGELOG.md entry, rebuild, commit, then tag monkey-v${version}.`);
