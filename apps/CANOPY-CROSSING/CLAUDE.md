# Canopy Crossing: notes for Claude sessions

## Every update goes live for beta testers

The owner has shared the playable web build with beta testers through this
public link, and wants every update to reach them there:

    https://claude.ai/artifact/NHzAQ2w4jCjWjLkoxLSdB3   (artifact slug ac6f0a1e-5e54-4bf4-91c9-f0aaf95bf4ce)

After any change to the game is tested, committed and pushed:

1. `tools/build_web.sh` (web export, packaging, phone-browser tap test; it
   must print `WEB BUILD OK`).
2. Republish to that same artifact (never a new one): read its current
   version, then publish `build/web_artifact/canopy-crossing.html` as
   `index.html` plus whichever of `index-gamedata.wasm`, `index.js`,
   `index.part0/1/2.wasm` changed (compare sha256 with the live files).
   The artifact is shared publicly, so the republish states that it is
   public (shared_live "public", title "Canopy Crossing").
3. Tell the owner the link is updated.

## Checks before a commit

`FAST=1 tools/run_tests.sh` (compile, first-person render, phase audit in
the project and an exported pack) and the 200-level sweep
(`godot --headless --path . res://tools/level_sweep.tscn`). See RUN.md.

## Store launch checklist and bug log

The live launch page is a separate artifact (not the game link):

    https://claude.ai/artifact/W8GbYN7jifz6X6fRE4QSNR   (slug ebdcd6af-9651-4a85-8037-504a82837946)

It stores data in its `db`: `progress/<step id>` ({done, note, by, at}),
`feedback/*` (bug and feedback reports: title, kind, severity, platform,
view, where, steps, status) and `activity/*`.

- At the start of a session, read `feedback` (db_list) for open reports and
  fix what you can; set a report's status to `fixing`, and let the owner set
  `fixed` after checking.
- When Claude finishes a checklist step, write `progress/<id>` with
  `done: true, by: "claude"` and a short note, plus an `activity` entry.
- The steps live in `LAUNCH/checklist.json`. After editing it, run
  `python3 tools/launch_docs.py` and republish `LAUNCH/page/checklist.json`
  (and `builds.json` after new builds) to that artifact. To refresh the
  README snapshot's green checks, export `progress` to
  `LAUNCH/progress.json` ({id: {done}}) first.

## Build, test, release, roll back (since the 2026-11-27 upgrade)

- **Upgrade runs** follow Eddie's *Universal Upgrade + Release Build* prompt:
  read `UPGRADE_LEDGER.md` first (skip what's done), write findings and the
  before/after table to `UPGRADE_REPORT.md`, append the run to the ledger.
- **Tests**: `FAST=1 tools/run_tests.sh` now also runs the performance gate
  (`tools/benchmark.tscn` + `tools/bench_check.py`: draw calls, objects and
  primitives must stay within 5% of `tests/perf_baseline.json`; re-record with
  `--record` only for a deliberate change, and say why in the commit) and a
  secret scan. `VISUAL=1` adds `tools/visual_check.py` (key screens at phone,
  tall-phone and tablet sizes vs `tests/visual/`, captured at Medium via the
  one-launch `--graphics=` switch). Plus the level sweep.
- **Size budget**: `tools/build_web.sh` fails if the game data grows over 5%
  past `tests/size_budget.json`. Folders of pictures that aren't game content
  (`upgrade-shots/`, `tests/visual/`) carry a `.gdignore`, or Godot packs them.
- **Android locally**: the SDK may be installed at `/root/android-sdk` (Google's
  hosts are reachable now). `tools/build_all.sh android` (needs a keystore: the
  `GODOT_ANDROID_KEYSTORE_RELEASE_*` variables; use a throwaway key outside the
  repo) and `tools/check_android.sh BUILDS/android/CanopyCrossing.apk`
  (16 KB pages, target API 36, permissions).
- **Release builds**: GitHub *Actions > Canopy Crossing release builds*. Order:
  web + APK, then the SDKs (`tools/install_sentry.sh` if `SENTRY_DSN`,
  `tools/install_review.sh`, `tools/build_crashlytics.sh` if
  `FIREBASE_ANDROID_CONFIG`), then `.aab`, iOS, desktop, then the Play checks.
  Build number = commit count. Never upload to a store without Eddie's go.
- **Crash reporting**: `autoload/crash_report.gd`; setup in
  `docs/CRASH_REPORTING.md`. Off without the keys (local builds, tests, beta link).
- **Remote switches**: `content/remote_config.json` (published by the beta
  workflow to GitHub Pages); `docs/REMOTE_CONFIG.md`. Switches may only turn
  shipped features off (App Review 2.5.19).
- **2D drawing**: painters draw through `Draw.*` helpers; entity views wrap
  their drawing in `Draw.begin_batch`/`end_batch` (one draw call per figure).
  New painter code must use `Draw.*` (and `Draw.set_transform`,
  `Draw.texture_rect`) rather than `ci.draw_*`, or its shapes land under the batch.
- **Store kit**: `store-kit/` (credits, privacy answers, screenshots list,
  accessibility labels, review notes, release plan, where keys live).
- **Roll back**: each upgrade step is its own commit; the 2026-11-27 run
  started from commit 8ea014e (local tag `pre-upgrade-2026-11-27-canopy-crossing`;
  the proxy refused to push tags). Store side: halt the staged rollout, flip a
  remote switch, or ship the previous tag with a higher build number
  (`store-kit/release-plan.md`).
