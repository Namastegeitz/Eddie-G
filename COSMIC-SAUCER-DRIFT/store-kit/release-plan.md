# Release plan, rollback and signing

Nothing is uploaded, submitted or published without Eddie's go (upgrade-run rule).

## Before every store upload
1. `game/tools/run_tests.sh` → **ALL CHECKS PASSED** (compile check, smoke checks, AI race on every track).
2. `game/tools/visual_check.sh` → **VISUAL OK** (menus at 3 screen sizes).
3. Benchmark + `game/tools/perf_check.py` → within 5 % of `game/tests/perf_baseline.json`.
4. `python3 game/tools/bump_version.py <version>`: raises every build number by one (Play and Apple refuse equal numbers).
5. Add the version to `CHANGELOG.md` and `store-kit/whats-new.md`; commit; tag `csd-v<version>` (on your PC: the cloud session can't push tags).
6. Build: `builds/build_all.sh` (web, desktop, debug APK) and `builds/store_build.sh aab ios` (store builds with crash reporting). See `stores/CRASH_REPORTING.md`.
7. Install the store build on a real Android phone and an iPhone/iPad: play one race, open Settings, check the crash-report question.

## Staged rollout
- **Google Play:** internal test → closed test (≥12 testers for 14 days, required for new personal
  accounts) → production at **10 %**, watch Android vitals for 2–3 days (crash < 1.09 %, ANR < 0.47 %),
  then 50 % → 100 %.
- **App Store:** TestFlight (internal, then external) → release with **phased release** (7 days)
  turned on; it can be paused.
- **Steam / itch.io / GOG:** upload to a beta branch first, then make it the default.

## Rollback
- **Code:** branch `rollback/pre-upgrade-2026-11-27` (and local tag `pre-upgrade-2026-11-27`) is the
  state before this upgrade run. Every change is a separate commit on `upgrade/2026-11-27`, so a single
  feature can be reverted with `git revert <commit>`.
- **Settings:** each new feature is a setting whose default keeps the old behaviour; the review
  prompt has `"enabled": false` in `game/content/review_prompt.json`; crash reporting does nothing
  without its SDK, config and the player's yes.
- **Saves:** the save format is unchanged (version 1); new keys are added with defaults, and old saves
  load (smoke-tested). Going back to an older build keeps working: it ignores the new keys.
- **Google Play:** halt the staged rollout; then ship the previous code with a **higher** build number
  (Play can't go back to a lower one).
- **App Store:** pause the phased release; submit the previous code as a new build number; expedited
  review can be requested for a serious bug.
- **Steam / itch.io:** switch the default branch back to the previous build.

## Signing (never commit keys or passwords)
| Platform | Key | Where it lives | Notes |
|---|---|---|---|
| Google Play | **Upload key** (`.jks`) | Your PC + two backups (e.g. password manager + offline drive) | Play App Signing holds the real app key; a lost upload key can be reset by Google. Godot needs keystore and key passwords to match. Env vars `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD` |
| Side-loaded APK (itch.io, website) | Same or a separate key | Same | From 2027, register the package + key with Android developer verification |
| Apple | Distribution certificate + provisioning profile | Your Mac's keychain / Xcode automatic signing | Team ID goes in the iOS preset (placeholder `ABCDE12345`) |
| macOS outside the App Store | Developer ID certificate, notarization | Mac | Developer ID sub-CA changes 1 Feb 2027: re-sign any .pkg |
| Windows | None (Eddie chose no Azure Artifact Signing) | — | Steam and Microsoft Store builds don't need it; direct downloads show SmartScreen warnings |
| GitHub Actions | Optional secrets `CSD_SENTRY_DSN`, `CSD_FIREBASE_*_BASE64` | Repository secrets | CI signs only with a throwaway debug key |
