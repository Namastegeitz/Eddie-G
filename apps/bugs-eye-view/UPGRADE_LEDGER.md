# Upgrade ledger (append only)

Each run of the Universal Upgrade & Release Build Prompt adds a section. The
next run reads this first and skips everything marked done.

## 2026-11-27/28 - run 1
- **Engine:** Godot 4.7.2 stable, Compatibility renderer (kept; 4.8 is beta 5 - revisit when stable).
- **Rollback point:** commit 8ea014e (local tag `pre-upgrade-2026-11-27`).
- **Done (upgrades):**
  - U1 atomic saves with a .bak backup and recovery from a broken or half-written save
  - U2 migration of desktop saves from Godot's old `app_userdata/Bug's-Eye View` folder
  - U3 load test with a save from the first build (`tests/fixtures/save_v1_2026-11-01.json`)
  - U4 pause on focus loss (setting, default on)
  - U5 shader warm-up under the loading fade (`GameManager.shader_warmup_enabled`)
  - U6 Ultra quality (MSAA 8x, 16x aniso, SSAO), frame cap 30/60/120/none, render scale 50-125%
  - U7 reduced motion (screen shake and menu spin off)
  - U8 text size 100-200%
  - U9 benchmark (`tools/bench/`) + 5% perf gate (`tools/bench/check_perf.py`, baseline `tests/bench_baseline.json`)
  - U10 screenshot regression at 3 sizes + 200% text (`tools/visual/`, baselines `tests/visual/`)
  - U11 GitHub Actions: `.github/workflows/bugs-eye-view-tests.yml` (every push touching the game), `bugs-eye-view-release.yml` (on demand / tag)
  - U12 `tools/release/bump_version.py` (version + build number everywhere), `CHANGELOG.md`
  - U13 `BUG'S-EYE VIEW/store-kit/` (credits, What's New, shot list, accessibility answers, signing, release plan)
  - Godot credit in Settings > Privacy & about
- **Done (add-ons, approved by Eddie 27 Nov):** Sentry Godot SDK 2.5.1 (installed by the release workflow when `SENTRY_DSN` is set); Firebase Crashlytics 21.1.0 NDK for Android (`addons/bugs_crashlytics`, when `FIREBASE_ANDROID_CONFIG` / `config/google-services.json` exists). Both opt-in in game.
- **Declined / later (Eddie 28 Nov):** GdUnit4 (not now), in-app review plugin (after launch), fastlane (once store accounts exist), Azure Artifact Signing (no, stay free).
- **Deferred:** translation string tables; screen-reader names (wait for Godot 4.8 mobile AccessKit); assist/difficulty mode; auto text size for phones; Crashlytics on iOS (needs the Firebase iOS SDK in the Xcode build on a Mac runner).
- **Sources checked 27 Nov 2026:** github.com/godotengine/godot releases and godot-docs (renderers, pipeline compilations, AccessKit); developer.apple.com news (age rating 16 Nov 2026, iOS 27 SDK April 2027, accessibility labels); developer.android.com (vitals, target SDK, 16 KB pages, foldables, developer verification, in-app review); github.com/getsentry/sentry-godot + sentry-docs; dl.google.com Maven (firebase-crashlytics 21.1.0); partner.steamgames.com (snippet); learn.microsoft.com (snippet).
