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
  - Wrong glyphs are rejected and cost a try. You get 25 tries per puzzle by
    default; Settings offers 10, 5 or the classic 3.
  - **The visitors**: when your tries run out, an alien ship rises from the far
    horizon, flies up in front of you and asks telepathically, *"Who are you?"*,
    while you ponder in wonder. Answer with your name or one of three replies.
    They remember you (the menu greets you by name). They then offer a gift of
    more tries, once per puzzle (a rewarded video on phones), or a fresh start.
    The scene has its own hum, telepathic chimes and departure.
  - Notes, auto-notes, undo.
  - Hints that explain *why* (for example, "fits in only one place in this box").
  - Pause that hides the board, and autosave so you can resume.
  - Constellation lines between matching glyphs, and a flash when a row, column or box is complete.
  - Haptics.
  - Keyboard controls on the computer.
- **Difficulty aliens**: each difficulty has its own lineup and theme, getting
  rougher as it gets harder:
  - Easy: *Soft Visitors*, super soft and cute, on a light pastel theme.
  - Medium: *Alien Creatures*, playful troublemakers, on a neon green theme.
  - Hard: *Hostile Visitors*, menacing, on dark crimson with chiseled corners and
    hazard stripes.
  - Alien: *Gnarly Horde*, fanged, many-eyed and slimy, on near-black with a
    heartbeat-pulsing board.

  The visitors who come when you run out of tries match the difficulty too:
  sweet, neutral, hostile or gnarly. This applies to Quick Play, Zen and Daily
  (the campaign keeps its sector lineups), and it can be switched off in Settings.
- **Lineups and themes**: 10 glyph lineups of detailed, full-color pictures. Each
  glyph has its own color and silhouette:
  - Close Encounters: alien head, saucer, tic-tac UAP, black triangle, pyramid,
    crop circle, ray gun, cow abduction, radio dish.
  - Space Fleet, Planets, Deep Cosmos, and Alien Creatures (characters with faces).
  - Ancient Mysteries: pyramid, sphinx, Eye of Horus, moai, Stonehenge and more.
  - Cosmic Mix: the best of the other lineups.

  Every lineup has its own theme: colors, display font, board frame, backdrop and
  star colors. Each campaign sector is played in its own lineup.
- **Score**: points for every correct glyph, with harder puzzles worth more. Quick
  consecutive moves build a ×10 combo. Finishing a unit or the puzzle adds a bonus.
  High scores are kept per difficulty.
- **Effects**: particle bursts in the glyph's color, a shower when a row, column or
  box is finished, and win fireworks. The animated starfield has shooting stars
  and a rare UFO flyby. All of it is off when "Reduce motion" is on.
- **Progress**: 27 achievements, per-difficulty stats (best and average time, high
  score, win rate, streaks), and 7 lineups.
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
  data/        glyphs/ (one SVG lineup module each), themes, sectors, achievements, puzzle-pool.json
  styles/      base, play, screens
public/        space backgrounds (WebP), icons, favicon
assets/        icon + splash sources for the native projects; the original export's README
android/ ios/  Capacitor native projects
desktop/       Electron wrapper + packaging config
tools/         gen-puzzles.mjs, gen-icons.mjs, glyph-sheet.mjs (lineup contact sheets), set-admob-ids.mjs, package-artifact.mjs
tests/         unit tests (engine, game, profile) and Playwright end-to-end tests
```

See [RUN.md](RUN.md) to run, test and build every platform, and
[docs/STORE_CHECKLIST.md](docs/STORE_CHECKLIST.md) to publish to Google Play and the App Store.
