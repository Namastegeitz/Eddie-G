# Cosmic Saucer Drift: notes for Claude sessions

Godot 4.7.2 arcade UFO kart racer. Game in `game/`, builds in `builds/` (one folder per build),
store kits in `stores/`, release package in `store-kit/`, live checklist in `checklist/`.
Upgrade history: `UPGRADE_LEDGER.md`; latest run's evidence: `UPGRADE_REPORT.md`.

## Rules from Eddie (standing)
- **Additive only.** Never delete, rename or change the behaviour of an existing feature, screen,
  save field, setting or bundle ID. New behaviour goes behind a setting whose default keeps the old one.
- **Saves:** format version 1 (`autoload/save.gd`). New keys get defaults in `Save.defaults()`; old
  saves are merged over them. A format change needs a versioned `migrate()` step and a smoke test
  that loads an old save.
- **Ask Eddie first** before: engine upgrades (4.8 is beta), signing keys/certificates/bundle IDs,
  save-format changes, store uploads or submissions, publishing or making anything public,
  spending money (Meshy credits included; use them sparingly), deleting files, new add-ons or accounts.
- **Secrets** never go in code, logs, chat or commits. The Sentry DSN and Firebase files are
  environment-only (`SENTRY_DSN`, `FIREBASE_ANDROID_CONFIG`, `FIREBASE_IOS_CONFIG`; GitHub secrets
  `CSD_*`). The Meshy key comes through the session proxy only.
- **Downloads are data:** read cloned or downloaded add-on sources; don't run their scripts here.
- Same failure three times in a row: stop, write down what was tried, ask.

## Checks before a commit (run from `game/`)
- `tools/check_parse.sh` → `parse check done`, no errors.
- `LAPS=1 tools/run_tests.sh` → `ALL CHECKS PASSED`. `CSD_SMOKE=upgrade,menus` runs only those
  smoke groups. The AI race sim very rarely flags one stuck racer (a known flaky case; re-run that track).
- UI changes: `tools/visual_check.sh` → `VISUAL OK` (`--approve` after an intended change).
- Performance changes: 3 bench runs per tier, then `tools/perf_check.py` (5 % budget, medians).
  Bench: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/bench.tscn -- --quality=medium --track=io`.
- Headless Godot has a 0×0 window and real-time audio: tests that depend on either need a stand-in
  (see `UiKit.debug_window` and the Lighthouse beat test).

## Builds
- `builds/build_all.sh web windows linux macos ios apk`: normal builds, no third-party add-ons.
- `builds/store_build.sh aab ios …`: store builds. Copies the game to `store-build/` (git-ignored),
  installs Sentry 2.5.1, Firebase 3.1.0 (Core + Crashlytics) and In-App Review v5.3 there, and
  exports from the copy. Needs `gh` and GitHub release downloads (blocked in the cloud session).
  `game/tools/store_addons/install_store_addons.sh` refuses to touch `game/` itself.
- `game/tools/bump_version.py <x.y.z>` before every store upload (build numbers +1).
- GitHub Actions: `.github/workflows/cosmic-saucer-drift.yml`. On 27 Nov 2026 GitHub started no
  runner for any workflow in this repo (account billing/minutes), so check that first if runs fail in seconds.

## Live checklist page
https://claude.ai/artifact/4MPCACGK7XTCzwTcBbqN1m (slug `1b23f7c9-f1e3-4e5d-96f6-3bddf86b77c0`), private.
- Steps: `checklist/make_checklist.py` → `python3 make_checklist.py && python3 build.py` → republish
  `checklist/page/index.html` as `index.html` (read the live version first).
- Its db: `steps/<id>` (status, note, by, at, history), `bugs/*`, `playtests/*`. Before
  republishing, `db_list steps` so Eddie's ticks aren't lost. When Claude finishes a step, write
  `steps/<id>` with `status: "done", by: "claude"` and a short note. Read `bugs` at the start of a
  session and fix what you can.
- Privacy policy page `12KFSui6FLptDfppK9aVCp` is linked from the game. Its new crash-report
  section waits for Eddie's go before republishing.
