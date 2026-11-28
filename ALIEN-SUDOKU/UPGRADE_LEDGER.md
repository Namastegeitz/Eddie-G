# Upgrade ledger (append only)

Each run of the *Universal Upgrade & Release Build* prompt adds one entry. The next run reads
this first and skips what is done.

## Run 1 · Nov 27–28, 2026 · version 1.2.0 → 1.3.0
- Stack: Vite 8.4.0, Capacitor 8.6.3, Electron 45.5.0, electron-builder 26.18.0, Vitest 5.1.2, Playwright 1.64.1 (pinned), AdMob plugin 8.3.0 (pinned).
- Starting commit: 826fc25 (local tag `pre-upgrade-2026-11-27`).
- Done:
  - Baseline benchmark tool (`game/tools/perf-bench.mjs`, `npm run bench` gate at 5%) and `game/perf/baseline.json`.
  - Graphics setting: Auto/Low/Medium/High/Ultra, resolution, frame rate, background motion, glow and blur; Auto steps down on slow frames; compositor-only pulses; half-size backdrops for Low.
  - Patch updates and non-breaking audit fix (game advisories 8 → 4, build tools only).
  - Add-ons (owner said yes): Sentry + Firebase Crashlytics (crash reports, off until set up, switch in Settings), Firebase Remote Config (ads switches, update notices), Capawesome App Review (rating card within store rules), Capacitor Text Zoom (text size follows the phone).
  - Send feedback in Settings; text size 100–150%.
  - Flaky duel test fixed; visual regression tests at 3 sizes; security pass (secrets, permissions).
  - Codemagic iOS + Android workflows with unit tests; CHANGELOG; store-kit (shot list, accessibility answers, credits, release plan); CLAUDE.md.
- Declined / deferred: desktop signing (Azure Artifact Signing, rcodesign), PostHog analytics, translations, gamepad, SKAdNetwork third-party IDs (source blocked), Next-Gen ads SDK (plugin not ready).
- Sources checked (Nov 27, 2026): developer.android.com (target-sdk, page-sizes, vitals, in-app review), developer.apple.com (upcoming requirements, news on age ratings, ratings and reviews, review guidelines, kids, accessibility labels), npm registry (all versions), MDN compat data, Chromium AwSettings; Google AdMob, Firebase, Sentry, PostHog, Microsoft and Steam pages via search only (blocked here).
