# Monkey See, Monkey Do: working notes for Claude

3D rhythm and memory game. Plain ES modules + three.js r162 (pinned: r163 dropped
WebGL 1, which older Androids need). Wrappers: Capacitor 8.6.3 (`mobile/`),
Electron 45 PC edition (`release/05-desktop/`). No backend; saves live on the device.
Read `UPGRADE_LEDGER.md` first: it lists what earlier upgrade runs already did.

## Rules of the road
- Additive only: new behaviour goes behind a setting in `js/save.js`
  `DEFAULT_SETTINGS`, with a default that keeps today's behaviour. Never rename
  or remove a setting, save field, product ID, bundle ID or level.
- Old saves must keep loading: `tests/fixtures/save-first-release.json` is
  checked by `tests/unit.mjs`. A save-format change needs a migration in
  `migrateRaw()` plus a fixture.
- Crash reports stay off unless `release/config.json` sets `sentryDsn` or
  `firebaseCrashlytics`; the privacy page is generated to match. Never commit
  keys, DSN auth tokens, keystores or Firebase config files.
- Ask Eddie before: major version upgrades, signing/bundle-ID changes,
  save-format changes, publishing (beta link, artifact, stores), spending.

## Build
```
cd apps/monkey-see-monkey-do
node scripts/build_web.mjs        # dist/www (game) + dist/site (beta website)
node scripts/build_single.mjs     # single-file builds (claude.ai game page)
node scripts/build_release.mjs    # web zip, itch.io zip, desktop app folder
node scripts/set_version.mjs 1.2.0   # version everywhere, build number + 1
node scripts/vendor_sentry.mjs    # refresh js/vendor/sentry.min.js
```

## Test (the test machine renders in software: slow but consistent)
```
python3 -m http.server 8765 --bind 127.0.0.1 &            # source
(cd dist/www && python3 -m http.server 8766 --bind 127.0.0.1 &)   # build
node tests/unit.mjs              # rules, saves, keys, controller mapping (seconds)
node tests/smoke.js              # build starts, plays, controller works (1 min)
node tests/acceptance.js         # full play-through on the source (25-40 min)
node tests/devices.js            # phone/tablet/laptop sizes on the build (ONLY=<name> for some)
node tests/benchmark.js          # performance vs tests/benchmark-baseline.json (fails if 5% worse)
SITE=https://namastegeitz.github.io/Eddie-G/ node tests/beta_site.js   # the live beta link
```
CI: `.github/workflows/monkey-see-monkey-do-ci.yml` (every push: rules, store
text, build, smoke) and `monkey-see-monkey-do-mobile.yml` (phone builds, by hand
or on `monkey-v*` tags).

## Release
See `store-kit/release-plan.md` (internal, closed beta, staged rollout with
vitals gates) and `store-kit/README.md` (all store text, answers and art).
Beta link: `bash scripts/deploy_beta.sh` publishes `dist/site` to the
`monkey-see-monkey-do/` folder of `gh-pages` (the rest of that branch is the
Off-Grid Survival Kit: never touch it). Ask before publishing.

## Roll back
- Code: every release is tagged `monkey-v<version>`; the 27 Nov 2026 upgrade
  run started from commit `8ea014e` (branch `upgrade/2026-11-27-monkey-see-monkey-do`).
- Beta link: `git revert` the last `monkey-see-monkey-do/` commit on `gh-pages`, push.
- Stores: halt Play rollout / pause Apple phased release / set the previous
  Steam build live; fix forward with a higher build number.
