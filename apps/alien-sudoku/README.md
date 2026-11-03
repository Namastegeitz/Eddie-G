# Alien Sudoku

Sudoku with alien glyphs instead of numbers. You decode transmissions from a lost
UFO archive over space photography, with synthesized sci-fi music. Built from the
original *Alien Glyph Sudoku* web page (`assets/original/`). It runs on:

| Platform | How |
|---|---|
| Android | Capacitor app (`android/`). The debug APK is on the GitHub release; Google Play needs a signed AAB. |
| iOS / iPadOS | Capacitor app (`ios/`, Swift Package Manager). A simulator build comes from CI; real iPhones need TestFlight or a Mac. |
| Windows, macOS, Linux | Electron app (`desktop/`). Installers are on the GitHub release. |
| Any browser | Static web build. Installable as an app (PWA) and works offline. |

Ads: the phone apps are free with Google AdMob ads (banner, an occasional
interstitial between puzzles, and optional rewarded videos). Web and desktop
have no ads. Until real AdMob ids are set, Google's **test** ads are shown.

## Game

- **Campaign**: 6 sectors × 9 transmissions (Lunar Outpost → Cluster Core). The
  puzzles get harder as you go. Each sector has its own space background and
  symbol set. You earn 1–3 stars per level, and new symbol sets unlock as you go.
- **Daily Transmission**: one puzzle per day, the same for every player. Difficulty
  follows the day of the week. Streaks are tracked, and a calendar lets you replay
  the last 60 days.
- **Quick Play**: Easy / Medium / Hard / Alien.
- **Zen**: no lives, no timer, unlimited hints.
- **Play features**:
  - Wrong glyphs are rejected and cost a life (3 per puzzle).
  - A second chance after losing (a rewarded video on phones).
  - Notes, auto-notes, undo.
  - Hints that explain *why* (for example, "fits in only one place in this box").
  - Pause that hides the board, and autosave so you can resume.
  - Constellation lines between matching glyphs, and a flash when a row, column or box is complete.
  - Haptics.
  - Keyboard controls on the computer.
- **Progress**: 24 achievements, per-difficulty stats (best and average time, win
  rate, streaks), and 7 symbol sets.
- **Puzzles**: 1,000 pre-graded puzzles, each with exactly one solution. Each is graded by the
  human techniques it needs, from singles up to X-Wing, Swordfish and XY-Wing.
  Random relabelling, row/column swaps and transposition turn them into millions of variations.

## Layout

```
src/
  engine/      solver, logical grader/hint engine, puzzle pool, transforms, seeded RNG
  game/        GameSession: one puzzle's rules, undo, hints, save/restore (no DOM)
  core/        storage (localStorage + native Preferences), profile/stats/achievements, events, time
  audio/       Web Audio sound effects + 7 synthesized music tracks
  platform/    Capacitor glue (back button, lifecycle, haptics, system bars) and AdMob
  ui/          router, modals, screens (menu, play, campaign, daily, stats, achievements, settings, how-to)
  data/        symbol sets, sectors, achievements, puzzle-pool.json
  styles/      base, play, screens
public/        space backgrounds (WebP), icons, favicon
assets/        icon + splash sources for the native projects; the original export's README
android/ ios/  Capacitor native projects
desktop/       Electron wrapper + packaging config
tools/         gen-puzzles.mjs, gen-icons.mjs, set-admob-ids.mjs
tests/         unit tests (engine, game, profile) and Playwright end-to-end tests
```

See [RUN.md](RUN.md) to run, test and build every platform, and
[docs/STORE_CHECKLIST.md](docs/STORE_CHECKLIST.md) to publish to Google Play and the App Store.
