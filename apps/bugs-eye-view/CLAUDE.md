# Bug's-Eye View - notes for Claude Code

Godot 4.7.2 (Compatibility renderer), GDScript. Read `UPGRADE_LEDGER.md` before
an upgrade run; release material lives in `BUG'S-EYE VIEW/`.

## Build
- Rebuild generated content: `godot --headless --path . res://tools/build_all.tscn -- --force`, then `godot --headless --path . --import`.
- All platforms into `BUG'S-EYE VIEW/Builds/<Platform>/`: `tools/release/export_builds.sh` (Android needs `ANDROID_HOME` + Java 17+).
- Store art: `tools/release/make_store_assets.sh`. Checklist page + README: `python3 tools/release/make_checklist.py`.
- Version: `python3 tools/release/bump_version.py 1.0.1` (bumps the build number in every preset).

## Test (all must pass before a commit)
- `tools/run_tests.sh` - import, boot, warnings-as-errors, smoke + phase audit in the project and in an exported pack.
- `python3 tools/bench/check_perf.py` - fails if game logic is >5% slower than `tests/bench_baseline.json` (same machine only).
- `tools/visual/check_visual.sh` - screenshots at 1280x720, 844x390, 1280x800 and 200% text vs `tests/visual/` (needs xvfb). After a deliberate UI change: `... OUT --update`.
- One audit phase: `godot --headless --path . res://tests/phase_audit.tscn --fixed-fps 60 -- --phase=22`.

## Release
- GitHub Actions > "Bug's-Eye View release builds" > Run workflow (or push tag `bugs-eye-view-vX.Y.Z`). Secrets: `SENTRY_DSN`, `FIREBASE_ANDROID_CONFIG`, `BUGS_ANDROID_KEYSTORE_BASE64` / `_KEY_ALIAS` / `_KEY_PASSWORD`.
- Never upload or submit to a store without Eddie's go-ahead. Plan: `BUG'S-EYE VIEW/store-kit/release-plan.md`.

## Rules
- Additive only; new behaviour behind a setting or flag with defaults that keep today's behaviour.
- Saves must keep loading: `tests/fixtures/save_v1_2026-11-01.json` is checked by audit phase 22. A format change needs a version bump, a migration and a test.
- Secrets never in git: `config/crash_reporting.cfg`, `config/google-services.json`, `*.keystore` are ignored.
- Crash reporting is opt-in (`CrashReporter`); the privacy policy and store answers in `BUG'S-EYE VIEW/Legal/` must match what the game sends.

## Roll back
- Code: `git revert` the step commits (each step is its own commit), or check out commit 8ea014e (pre-upgrade, 27 Nov 2026).
- Feature flags: `GameManager.shader_warmup_enabled`, Settings switches (crash reports, motion, focus pause; frame cap / render scale "Same as quality").
