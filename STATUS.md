# Status

## Bug's-Eye View (`apps/bugs-eye-view`)
- Built end to end from `prompts/claude/bugs-eye-view.md` (all 6 phases, all 16 add-ons).
- Godot 4.7.2 project: 3 bugs, 3 rooms with boss chases, perception-based stealth,
  escalation chain, daily routines, colony upgrades, menus, touch/keyboard/gamepad.
- Tests: `tools/run_tests.sh` - 118-check smoke test + 162-check phase audit pass in the
  project and in an exported build; zero GDScript warnings and engine errors.
- Phase-by-phase audit (all 6 phases) done; fixes it found: human feet were never solid,
  props didn't stun via feet, cereal-box domino layout, spider facing/normal errors, fog strength.
- Android debug APK committed at `apps/bugs-eye-view/dist/android/bugseyeview-debug.apk`.
- Builds made in the cloud session: Android debug APK, Windows, macOS, Linux, Web,
  iOS Xcode project (not committed; rebuild with the commands in RUN.md).
- Playable web build published as a private Claude artifact:
  https://claude.ai/artifact/Gmpx6M1Qb9WmCn1BY1Qbh4
- Next: real art/audio, Google Play AAB (needs Android SDK locally), iOS signing via a
  Mac or Codemagic (`docs/ci/codemagic.yaml`), playtesting and tuning.

## Alien Sudoku (`apps/alien-sudoku`)
- Built from the uploaded `alien-sudoku-export.zip` (original single-page game kept in spirit:
  glyph sets, space art, synthesized music, reject-on-wrong rule).
- Full game: campaign (6 sectors x 9), daily transmission + streak calendar, quick play, zen,
  24 achievements, stats, settings, how-to, autosave/resume, notes/undo/explained hints.
- Puzzle engine: 1,000 graded unique-solution puzzles + transforms; logical hint engine.
- Platforms: Vite web/PWA, Capacitor 8 Android + iOS (SPM), Electron desktop. App id
  `com.eddieg.aliensudoku`. Free with AdMob on phones (Google TEST ids until real ones are set).
- Tests: 86 unit (`npm test`) + 13 Playwright end-to-end on phone and desktop (`npm run test:e2e`).
- Playable private web build: https://claude.ai/artifact/NdYUzQJYiAGjCra9nF7MHn
- CI (`.github/workflows/alien-sudoku.yml`) builds APK, iOS simulator app, Windows/macOS/Linux
  installers and publishes the `alien-sudoku-latest` release. BLOCKED: GitHub would not start
  any Actions job on this account (likely billing/spending limit). Fix it, then re-run.
- Desktop apps built in the cloud session (Electron, smoke-tested) and sent as files:
  Windows installer + portable, Mac Intel zip, Linux AppImage/deb. Too big to commit (100+ MB).
- Not built yet: the Android APK (dl.google.com is blocked by the session's network policy,
  and Actions can't start jobs).
- Next steps are written as approve-when-ready prompts with their prerequisites:
  `prompts/claude/alien-sudoku/README.md` (Android APK, Actions, AdMob, Google Play,
  TestFlight, public website, desktop signing).

## NeuroForge (not in this repo)
- Source on the Windows PC: `C:\Users\edwar\Desktop\AI and ALL\Aethertek\content poster\neuroforge`
- Live web: https://neuroforged.surge.sh and https://neuroforge.surge.sh
- App Store launch board was at step 1 of 22 (surge sign-in).
- Next: push the source to a private GitHub repo so cloud/phone sessions can read it.

## Prompts
- `prompts/claude/bugs-eye-view.md` - v2 with the stealth/interactivity add-ons.
- `prompts/claude/alien-sudoku/` - Alien Sudoku launch board: one prompt per remaining step.
- Next: collect the rest of the new prompt set (Claude + Codex) into `prompts/`.
