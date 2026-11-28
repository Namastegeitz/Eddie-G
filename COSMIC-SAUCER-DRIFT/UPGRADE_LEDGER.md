# Upgrade ledger: Cosmic Saucer Drift

One entry per run of Eddie's *Universal Upgrade + Release Build Prompt*. Newest first.
Details and evidence for each run are in `UPGRADE_REPORT.md` (latest) and the commits.

## Run 1 · 27–28 Nov 2026 · branch `upgrade/2026-11-27`
**Start point:** `8ea014e` (branch `rollback/pre-upgrade-2026-11-27`).

**Done (all additive, defaults keep the old behaviour, old saves load):**
| # | Change | Test |
|---|---|---|
| U1 | Credits & licences screen; upstream DejaVu licence; Meshy CC BY credit; `store-kit/credits.md` | smoke: Godot licence, FreeType, Bitstream, CC BY on screen |
| U2 | Colour-blind filter (deutan/protan/tritan) | smoke: on, mode, off; screenshot |
| U3 | Reduce motion (shake, dip, boost zoom, speed lines) | smoke: no shake or dip when on |
| U4 | Interface size 100/115/130 % | smoke + screenshots at 3 sizes |
| U5 | Frame cap 60/120; iOS ProMotion key (iPhone "Off" stays 60) | smoke: Engine.max_fps per choice |
| U7 | `tools/perf_check.py` + `tests/perf_baseline.json` | checked against baseline and after runs |
| U8 | `tools/visual_check.sh` + 15 baseline images | passes; catches a wrong screen (34 %) |
| U9 | 2027 store rules in the Apple and Play kits | review |
| U10 | `store-kit/`, `CHANGELOG.md`, `tools/bump_version.py`, release/rollback/signing plan | dry run |
| Add-on | Sentry + Firebase Crashlytics (opt-in, store builds only) | consent smoke tests; installer tested offline |
| Add-on | In-App Review prompt (store builds only) | rule smoke tests |
| Add-on | GitHub Actions workflow | written and valid; GitHub started no runner (account billing/minutes) |
| Fix | Two machine-speed-dependent tests (Lighthouse beat, safe area) | 3/3 and items group pass |

**Not done (why):** U6 clean exit. The last object alive at exit is a music playback held by
the dummy audio driver; two fixes didn't change it, so it stays a test-only artefact.

**Add-on decisions:** Sentry Yes (changed from No), Firebase Crashlytics Yes, CI Yes, In-App Review
Yes, Azure Artifact Signing No.

**Metrics (cloud computer, software GPU; solo runs):**
| | Before | After |
|---|---|---|
| Medium: frame time / 1 % low | 70.5 ms / 10.6 fps | 67.7 ms / 10.1 fps |
| High: frame time / 1 % low | 261.3 ms / 3.0 fps | 242.9 ms / 3.2 fps |
| Memory (static / video, Medium) | 103.2 / 57.4 MB | 103.4 / 57.5 MB |
| Smoke checks | 1,141 | 1,180 (0 failed); AI race on every track passes |
| Build sizes | APK 61.6 · Win 42.3 · Linux 33.1 · macOS 64.6 · iOS 100.1 MB | same |

**Waiting on Eddie:** free Sentry + Firebase accounts; GitHub Actions billing check; Meshy plan
check; go to republish the privacy policy; store accounts, upload key, Team ID (from the launch checklist).

**Next run should start with:** translation-ready strings, key remapping, real-phone performance pass.
