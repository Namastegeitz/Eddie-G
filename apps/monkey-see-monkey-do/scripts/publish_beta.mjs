// Builds the public beta website in dist/site/ (run after dist/www is built;
// scripts/build_web.mjs runs this for you):
//   dist/site/                 landing page (Play button, QR code, tester notes),
//                              privacy.html, support.html
//   dist/site/play/            the game (a copy of dist/www)
// scripts/deploy_beta.sh then puts dist/site on GitHub Pages, in the
// monkey-see-monkey-do/ folder of the gh-pages branch:
//   https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/
// (the rest of gh-pages is the Off-Grid Survival Kit; it is left alone).
import { cpSync, rmSync, mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const www = join(root, 'dist', 'www');
const site = join(root, 'dist', 'site');
if (!existsSync(join(www, 'index.html'))) throw new Error('dist/www is missing: run node scripts/build_web.mjs first');

rmSync(site, { recursive: true, force: true });
mkdirSync(site, { recursive: true });
cpSync(www, join(site, 'play'), { recursive: true });

const version = (readFileSync(join(root, 'js/main.js'), 'utf8').match(/const VERSION = '([^']+)'/) || [])[1] || '';
const stamp = `${version} · ${new Date().toISOString().slice(0, 10)}`;
writeFileSync(join(site, 'index.html'), readFileSync(join(root, 'beta/index.html'), 'utf8').replaceAll('__BUILD__', stamp));
const cfg = JSON.parse(readFileSync(join(root, 'release/config.json'), 'utf8'));
const contact = cfg.supportEmail
  ? `Email <a href="mailto:${cfg.supportEmail}">${cfg.supportEmail}</a> with what happened and your device (phone model or computer). We usually reply within two days.`
  : 'Tell the person who shared the game with you, or use the review or support link of the store you got it from.';
writeFileSync(join(site, 'support.html'), readFileSync(join(root, 'beta/support.html'), 'utf8').replaceAll('__SUPPORT_CONTACT__', contact));
// the privacy page says exactly what this build's crash reports do (js/crash.js)
const crashOn = !!(cfg.sentryDsn || '').trim() || !!cfg.firebaseCrashlytics;
const services = [cfg.sentryDsn && cfg.sentryDsn.trim() ? 'Sentry (sentry.io)' : '', cfg.firebaseCrashlytics ? 'Google Firebase Crashlytics (phone apps)' : ''].filter(Boolean).join(' and ');
const crashSection = crashOn
  ? `<p>If the game crashes or hits an error, it sends a crash report to ${services} so we can fix it: the error message and where in the game's code it happened, the game version, and your device model, system and browser version. Firebase Crashlytics also uses a random installation ID (it identifies the app install, not you). Crash reports never include your name, an account, your location, an advertising ID, your save or anything you type, and they are not used for ads or tracking.</p>
    <p>You can switch them off in Settings &gt; Help and privacy &gt; Send crash reports. Versions of the game without that switch send nothing.</p>
    <p>The Android app has internet access only for these reports (its other store permissions: Google Play Billing for the optional Shop, and vibration).</p>`
  : `<p>This version sends no crash reports. The phone apps include a crash-report tool (Google Firebase Crashlytics) that is switched off and sends nothing. Because it is built in, the Android app lists internet access; nothing uses it. If crash reports are ever turned on, this page will say exactly what they contain, and Settings will have a switch to turn them off.</p>`;
writeFileSync(join(site, 'privacy.html'), readFileSync(join(root, 'beta/privacy.html'), 'utf8').replaceAll('__CRASH_SECTION__', crashSection));
for (const f of ['site.css', 'qr.svg', 'qr.png', 'sw.js']) cpSync(join(root, 'beta', f), join(site, f));
writeFileSync(join(site, 'README.md'), `# Monkey See, Monkey Do · public beta

This folder is generated: do not edit it by hand. Its source is
\`apps/monkey-see-monkey-do/beta/\` (landing, privacy, support pages) and
\`apps/monkey-see-monkey-do/dist/www\` (the game, in \`play/\`), on the
repository's default branch.

Rebuild and publish from there:

    cd apps/monkey-see-monkey-do
    node scripts/build_web.mjs     # game + this site (dist/site)
    bash scripts/deploy_beta.sh    # copies it here and pushes gh-pages

Live at ${cfg.betaUrl}
`);
console.log(`dist/site ready for GitHub Pages (beta ${stamp}); publish with: bash scripts/deploy_beta.sh`);
