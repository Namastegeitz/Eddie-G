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

## ALIEN SUDOKU (`ALIEN-SUDOKU/`)
- Everything for the game now lives in `ALIEN-SUDOKU/`: `game/` (source), `builds/<platform>/`,
  `store-launch/` (store guides, listing text, screenshots and art, privacy policy), `checklist/`,
  `feedback/`, `prompts/`. On claude.ai, the **ALIEN SUDOKU** artifacts folder holds the game,
  the Music Lab and Launch Control.
- Game: campaign (6 x 9), Daily, Quick Play, Zen, Alien Duel (computer rival you can customize),
  33 achievements, a theme song per difficulty, 10 glyph lineups. 107 unit + 30 end-to-end tests.
- Nov 17: store launch kit. In-depth research (Apple, Google Play + AdMob, Steam, GOG, itch.io,
  Epic, Microsoft Store, web portals) turned into a 118-task live checklist in 7 phases:
  **Launch Control** https://claude.ai/artifact/LzbsCTPkTUsxyLLCUWCgRM (tick tasks, green checks,
  bug and feedback reports stored on the page). README checklist: `ALIEN-SUDOKU/README.md`.
- Store-readiness fixes made Nov 17: in-app privacy policy, Report an ad, iOS privacy manifest,
  no banner during play, ads capped at PG, wider iPad layout, "computer rival" wording.
- Version 1.1.0 (Nov 18): **Star Cadets**. New mode-aware difficulty lineup in Campaign, Daily and
  Quick Play: Easy Alien Creatures, Medium Star Cadets (new set: academy recruits raised on Earth's
  '80s and '90s broadcasts; retro theme, Bungee font, synthwave grid), Hard Hostile, Alien Gnarly.
  Zen and Alien Duel keep the original lineup. New visitor tone "cadet", new song "Cadet Mixtape".
  Android versionCode 2, iOS build 2.
  Shareable web link (1.1.0): https://rawcdn.githack.com/Namastegeitz/Eddie-G/cff49a00f7e25606123decf9bb2d81e2a99e7a61/ALIEN-SUDOKU/builds/web/AlienSudoku.html
- Version 1.3.0 (Nov 28): **Universal Upgrade run 1**. Graphics setting (Auto/Low-Ultra; phone-profile
  stutter on the puzzle and map screens cut to near zero), crash reporting with Sentry + Firebase
  Crashlytics (off until the owner sets up the free accounts), Firebase Remote Config switches, the
  store rating card, text size, Send feedback, patch updates (Electron 45.5.0), visual regression and
  benchmark gates, Codemagic iOS + Android workflows, store-kit/. Report: ALIEN-SUDOKU/UPGRADE_REPORT.md;
  ledger: ALIEN-SUDOKU/UPGRADE_LEDGER.md. Android versionCode 4, iOS build 4.
- Nov 20-27: **store prep**. Android release builds work in the session (eddie-g cloud environment):
  signed 1.2.0 AAB + APK, R8 shrinking, upload key held by the owner. iOS builds on a Codemagic cloud
  Mac (codemagic.yaml). Step-by-step guide: ALIEN-SUDOKU/store-launch/STEP-BY-STEP.md. Owner chose
  personal/individual accounts. Website live: https://namastegeitz.github.io/Eddie-G/alien-sudoku/
  (privacy, support, play/).
- Version 1.2.0 (Nov 18): **maps and levels in high definition**. The six space backdrops are
  remade at 4x detail (Real-ESRGAN upscale, 2816x1536) with tall cuts for upright phones and strip
  cuts for the sector cards. The campaign list is a star chart (sector art, nine progress marks per
  sector, flight path between sectors); each sector is a route map with nine stops along a snaking
  path over the sector's artwork. Boards gain fine detail (shaded tiles, alternating box tint, a
  weave on given cells, studs where box lines cross); the starfield draws at full device
  resolution with fine dust and tapered flares. Android versionCode 3, iOS build 3.
  Shareable web link (1.2.0): https://rawcdn.githack.com/Namastegeitz/Eddie-G/4910aa93116cd52e073d410774a4138e64e6011d/ALIEN-SUDOKU/builds/web/AlienSudoku.html
- Nov 17 (later): Easy difficulty is now neutral instead of pastel pink, with six color schemes in
  Settings > Easy colors (Moonstone default, Graphite, Sage, Ocean, Sand, Paper). The Alien Duel
  rookie "Baby Blip" is now "Cadet Xel" (classic alien head, calm lines).
- Builds made Nov 17: web single file, itch.io HTML5 zip (committed); Windows installer + portable,
  Linux AppImage + deb, macOS Intel + Apple Silicon zips (unsigned; in `builds/<platform>/files/`,
  not in git).
- Blocked here: Android (dl.google.com), iOS (no Mac), GitHub Actions (jobs don't start).
- Next: the owner's tasks in Launch Control (accounts, support email, PC price, licenses).

## NeuroForge (not in this repo)
- Source on the Windows PC: `C:\Users\edwar\Desktop\AI and ALL\Aethertek\content poster\neuroforge`
- Live web: https://neuroforged.surge.sh and https://neuroforge.surge.sh
- App Store launch board was at step 1 of 22 (surge sign-in).
- Next: push the source to a private GitHub repo so cloud/phone sessions can read it.

## Prompts
- `prompts/claude/bugs-eye-view.md` - v2 with the stealth/interactivity add-ons.
- `prompts/claude/alien-sudoku/` - Alien Sudoku launch board: one prompt per remaining step.
- Next: collect the rest of the new prompt set (Claude + Codex) into `prompts/`.
