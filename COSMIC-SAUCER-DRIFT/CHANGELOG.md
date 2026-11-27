# Changelog: Cosmic Saucer Drift

Not released to any store yet. The version stays 1.0.0 until the first upload
(`game/tools/bump_version.py` sets it everywhere).

## Unreleased: upgrade run 27 Nov 2026 (branch `upgrade/2026-11-27`)
Every change is additive: new behaviour sits behind a setting whose default keeps the old
behaviour, and old saves load unchanged.

### Added
- **Settings > Colour-blind filter:** Deuteranopia, Protanopia, Tritanopia (full-screen
  correction over game, HUD and menus). Default Off.
- **Settings > Reduce motion:** no camera shake, landing dip, boost zoom or speed lines. Default Off.
- **Settings > Interface size:** 100 / 115 / 130 %. Default 100 %.
- **Settings > Frame cap:** adds 60 and 120 fps. The iOS export allows ProMotion; "Off" stays
  60 fps on iPhone as before.
- **Settings > Credits & licences:** game credits, Meshy credit, the DejaVu font licence, Godot's
  MIT licence and every engine third-party notice (full texts on request).
- **Store rating prompt** after podium finishes (5+ races, 2+ podiums, at most 3 asks, 30 days
  apart). Works in store builds with the In-App Review plugin; does nothing elsewhere.
- **Crash reporting (opt-in):** Sentry (all platforms but web) and Firebase Crashlytics (Android,
  iOS). The player is asked once; nothing is sent without a yes. Only in store builds
  (`builds/store_build.sh`), which install the pinned add-ons into a git-ignored copy.
- **GitHub Actions workflow:** tests on every game change, web/Windows/Linux/debug APK builds,
  a store AAB on manual runs.
- **Checks:** `tools/perf_check.py` (5 % budget against `tests/perf_baseline.json`),
  `tools/visual_check.sh` (menus at 3 screen sizes against `tests/visual_baseline/`),
  `tools/bump_version.py`; 40 new smoke checks.
- **Release package:** `store-kit/` (credits, accessibility answers, shot list, release notes,
  release/rollback/signing plan), `stores/CRASH_REPORTING.md`, `stores/IN_APP_REVIEW.md`, and the
  2027 store rules in the Apple and Google Play kits.

### Fixed
- The shipped DejaVu licence file was Debian's packaging copy; it's now the upstream text.
- Two tests that could pass or fail by machine speed: the Lighthouse Wonder beat check (music
  clock vs. physics clock) and the safe-area check (headless runs have no window).

### Changed
- Privacy policy text: new "Crash reports (only if you agree)" section. Local file only; the live
  page is unchanged until Eddie approves republishing it.

## 1.0.0: first build (Nov 2026)
Five cups, 14 tracks on real planets, moons and exoplanets in normal, reverse and mirror
variants (42 layouts), 20 power-ups, 14 craft (HD Aurora), pilots with expressions, Super Upgrades and
Wonders, volcanic biomes, glide and secret skyways, time trials with ghosts, daily challenge,
split-screen versus, touch/keyboard/mouse/gamepad controls, quality tiers, and builds for web,
Android, iOS (Xcode project), Windows, macOS and Linux.
