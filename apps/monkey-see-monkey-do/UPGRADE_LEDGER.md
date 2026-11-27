# Upgrade ledger · Monkey See, Monkey Do

Append only. Each run of the Universal Upgrade + Release Build prompt adds a
dated entry. The next run reads this first, skips what is done, and only adds
new value. Details and numbers: `UPGRADE_REPORT.md`.

## 2026-11-27 · version 1.1.0 (build 2)

- **Engine / framework:** three.js r162 (pinned: r163+ drops WebGL 1; r162
  already has compileAsync, AgX/Neutral); esbuild 0.24.2 (pinned: the advisory
  is for its dev server, unused); Capacitor 8.5.3 → **8.6.3**; Electron 36.9.5
  → **45.5.0**; electron-builder 25.1.8 → **26.18.0**; cordova-plugin-purchase
  13.19.1 (13.20.0 deferred: needs a real-store entitlement test).
- **Branch:** `upgrade/2026-11-27-monkey-see-monkey-do` from `8ea014e`
  (tag `pre-upgrade-2026-11-27-monkey-see-monkey-do`, local only: the remote
  refused tag pushes from the build environment).
- **Upgrades done**
  - Benchmark with a 5% gate (`tests/benchmark.js`, baseline file kept).
  - Maps got ready ahead: build, texture upload, shader compile and a 1-pixel
    warm draw while the results card or level map is up (setting, on).
  - Error safety net and on-device error log; the main loop can't stop on an
    error; GPU reset (context loss) recovery card.
  - Settings > Help and privacy > Report a problem.
  - Game controller support (standard mapping, button names on the pad, D-pad
    menus); custom keyboard keys.
  - Graphics: Medium selectable, Sharpness, Frame-rate cap, Auto keeps
    watching during play (one step down after ~10 s of slow frames).
  - Calmer disco flashing with Reduce motion.
  - Web: "a new version is ready" bar, hourly update check.
  - Version script (`scripts/set_version.mjs`), CHANGELOG.md, `store-kit/`
    (credits, accessibility labels, release and rollback plan, shot list),
    CI on every push (`.github/workflows/monkey-see-monkey-do-ci.yml`),
    smoke test, desktop (Electron) test, old-save fixture, 23 new rule checks.
  - Store docs corrected: Steam wait 21 days; privacy page and Data safety
    generated/annotated for crash reports.
  - Settings rows with more than 3 options stack under their description
    (found by the before/after screenshots).
- **Tests at the end of the run:** rules 790/790, play-through 42/42, devices
  15/15, PC edition (real Electron 45) 5/5, smoke pass, benchmark at or better
  than baseline. New baseline: `tests/benchmark-baseline.json` (1.1.0); the
  pre-upgrade numbers are in `tests/benchmark-baseline-1.0.0.json`.
- **Not done:** publishing 1.1.0 (waits for Eddie), merging the branch, store
  pre-checks, native phone builds; GitHub Actions runs stop before starting
  (account setting).
- **Add-ons (Eddie's answers)**
  - Electron 45 + electron-builder 26: **yes**, done.
  - Crash reports: **Sentry and Firebase Crashlytics**, both free tiers.
    Integrated and **off until set up** (`release/config.json` `sentryDsn`,
    `firebaseCrashlytics` + Firebase files). Sentry is vendored from
    @sentry/browser 11.19.0 by `scripts/vendor_sentry.mjs`.
  - Store rating prompt (`@capacitor-community/in-app-review` 8.0.0): **yes**, done.
  - Android in-app updates (`@capawesome/capacitor-app-update`): **not now**.
  - Not asked (didn't fit yet): PostHog, Azure Artifact Signing, fastlane,
    Maestro, GdUnit4/GUT, EAS, Grafana k6.
- **Deferred:** translation-ready string files; 1206x2622 iPhone screenshots;
  three.js upgrade; cordova-plugin-purchase 13.20.0; native phone builds not
  compiled here (no Android SDK / Mac).
- **Sources checked (27 Nov 2026):** see the Research section of
  `UPGRADE_REPORT.md` (Apple upcoming requirements, age ratings, screenshot
  specs, third-party SDK privacy; Android target SDK, billing deprecation, 16 KB
  pages, developer verification, vitals; Play Data safety, Families; Steam
  Direct, Deck compatibility; Microsoft MSIX; itch.io HTML5; Epic requirements;
  three.js r163/r187 releases and migration guide; Capacitor releases; Electron
  timelines and advisories; electron-builder releases; esbuild advisory).
