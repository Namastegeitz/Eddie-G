# **CANOPY CROSSING: UPGRADE LEDGER**

Append-only record of upgrade runs (Eddie's *Universal Upgrade + Release
Build* prompt). The next run reads this first, skips what is done, and adds
only new value. Details and numbers: `UPGRADE_REPORT.md`.

## 2026-11-27 (branch upgrade/2026-11-27-canopy-crossing, from commit 8ea014e)

Engine: Godot 4.7.2 stable (pinned; 4.7.3 in RC, 4.8 in beta 5).

Done:
- Memory: run/ability reference cycle fixed (abilities hold their run weakly).
- Crash reporting: Sentry SDK 2.5.1 (all store builds, CI-installed when `SENTRY_DSN` is set) and Firebase Crashlytics 21.1.0 (own Android plugin `CanopyCrashlytics`, CI-built when `FIREBASE_ANDROID_CONFIG` is set); `CrashReport` autoload; Settings switch; privacy texts.
- Remote switches + update prompts (`RemoteConfig`, GitHub Pages file).
- Store rating card (In-app Review plugin 5.3, CI-installed).
- Auto-pause when the app loses focus; network time-outs; analytics retry with backoff.
- 2D batching: one draw call per figure (bird's-eye draw calls 2,131 -> ~310-350).
- Graphics: Ultra, frame-rate cap, first-person resolution.
- Settings page width fixed.
- CI: Node 24 actions, build number = commit count, SDK install order, Google Play pre-checks (`tools/check_android.sh`).
- Tests: performance gate (`tools/bench_check.py` + `tests/perf_baseline.json`), secret scan, visual regression (`tools/visual_check.py`, `tests/visual/`; a capture that runs out of time now fails instead of comparing an earlier frame).
- Store kit (`store-kit/`), `CHANGELOG.md`, CLAUDE.md build/test/release/rollback notes.
- Settings > Credits and licences (Godot's MIT licence and its third-party notices, font, map data, models).
- Before/after screenshots in `upgrade-shots/` (4 screens x 3 screen sizes).
- Android APK builds locally (SDK at /root/android-sdk) and passes the 16 KB / API 36 checks.
- Web game-data size budget (`tests/size_budget.json`, checked by `tools/build_web.sh`).

Results: bird's-eye draw calls -84%, frame time -9% (software GL); first person, start-up and download size unchanged; memory +1.5 MB; leak fixed (146 objects a run -> 0); phase audit 423 -> 451 checks; gameplay identical (same bot moves on all 220 levels).

Add-ons: Sentry (yes), Firebase Crashlytics (yes), In-app Review (yes), remote switches as a GitHub Pages file (yes), Play Games Services / Game Center (yes, after store accounts exist).

Deferred (next runs): Android 120 Hz (`Surface.setFrameRate` plugin); thermal quality step-down; translations; full screen-reader names, text size, gamepad menus; achievements + cloud saves; Crashlytics on iOS (with the Mac build job); Godot 4.7.3 when released; first end-to-end run of the release workflow on GitHub.

Sources checked (2026-11-27): developer.apple.com (submissions, age ratings, screenshot specs, accessibility labels, guidelines), developer.android.com (target SDK, 16 KB pages, vitals, developer verification, billing), github.blog (Node 20 removal), actions/runner-images, godotengine/godot 4.7 branch and 4.7.2 tag, godot-docs (renderers, AA, HDR, accessibility), getsentry/sentry-godot 2.5.1 source, godot-mobile-plugins/godot-inapp-review v5.3 source, dl.google.com Maven (Firebase versions), Maven Central (Godot Android library), pypi.org (Pillow, numpy), meshy.ai pricing.
