# Alien Sudoku: Upgrade Report

Run 1 · started Nov 27, 2026 · prompt: *Universal Upgrade & Release Build (Apps + Games)*

- Starting point: commit `826fc25` (tag `pre-upgrade-2026-11-27`, local). Every step after it is its own commit, so any step can be rolled back with `git revert`.
- Branch: the session's working branch `claude/peaceful-carson-qmcyku`. This environment only pushes there, so the commits stand in for the prompt's `upgrade/2026-11-27` branch.

## Recon

| | |
|---|---|
| What it is | A game: Sudoku with alien glyphs. Campaign (54 levels), Daily, Quick Play, Zen, Alien Duel (computer rival), achievements, 12 synthesized songs |
| Engine / framework | Vanilla JavaScript (ES modules) + Vite 8.3.5; Capacitor 8.6.0 for iOS and Android; Electron 45.2.1 + electron-builder 26.18 for Windows, macOS and Linux; PWA via vite-plugin-pwa 2.0 |
| Platforms and stores | App Store (iPhone, iPad), Google Play, Steam, GOG, itch.io, Epic, Microsoft Store, the web (GitHub Pages) |
| Backend | None. Everything is stored on the device |
| AI agents inside the app | None. The Alien Duel rival is a deterministic, seeded simulation, not an AI model |
| Monetization | Google AdMob on phones (banner, interstitial, rewarded) with Google's UMP consent; no purchases |
| Native code | None of its own; the APK has no `.so` libraries |

## Baseline (before any change)

Measured with `game/tools/perf-bench.mjs` (new): median of 3 runs, headless Chromium drawing on the CPU (pessimistic; real phones draw on the GPU). "Phone" = Pixel 7 screen with the CPU slowed 4x, like a mid-range phone. Raw numbers: `game/perf/baseline.json`.

| | Phone (CPU ÷4) | Desktop |
|---|---|---|
| Cold start to main menu | 1,170 ms | 734 ms |
| JS memory (menu / puzzle / map) | 3.1 / 3.6 / 3.4 MB | same |
| DOM size on the puzzle screen | 3,326 nodes | same |
| Menu: avg frame · fps · 1% low · worst | 16.7 ms · 59.8 · 59.5 fps · 33 ms | 16.7 ms · 60 · 59.5 fps · 17 ms |
| **Puzzle: avg · fps · 1% low · worst** | **17.4 ms · 57.4 · 29.9 fps · 50 ms** | 16.9 ms · 59.2 · **30 fps** · 33 ms |
| **Campaign map: avg · fps · 1% low · worst** | **18.3 ms · 54.8 · 29.9 fps · 33 ms** | 16.7 ms · 59.8 · 59.5 fps · 33 ms |
| Errors during the run | none | none |

What a 4-second trace of the puzzle screen shows (phone profile): **no slow JavaScript at all** (no call over 4 ms). The time goes to drawing: 70 main-thread tasks over 16 ms, led by layer updates and commits, and the starfield canvas being re-uploaded 31 times a second at full screen resolution (up to 9.5 ms each). Glow animations (`box-shadow` pulses) and `backdrop-filter` blurs add paint work.

| Build | Size |
|---|---|
| Android APK (release, R8) | 10.1 MB |
| Android App Bundle | 12.7 MB |
| Web build (`dist/`, offline cache) | 4.5 MB (2.8 MB of it backdrops), 92 cached files |
| One-file web game | 4.4 MB |
| Windows installer / portable | 116.8 / 106.2 MB |
| macOS zip (Intel / Apple Silicon) | 123.2 / 119.1 MB |
| Linux AppImage / deb | 102.9 / 103.3 MB |

| Check | Result |
|---|---|
| Web build | passes, no warnings |
| Android build | passes; Java "unchecked/deprecated" notes come from the plugins, not the game |
| 16 KB memory pages (Play, from Feb 1, 2027) | passes: no native libraries; `zipalign -c -P 16` OK |
| Unit tests | 116 / 116 pass |
| End-to-end tests (phone + desktop) | 42 pass, 2 skipped (keyboard test on phone); 1 duel test failed once under heavy load, then passed 6/6 |
| `npm audit` (game) | 8 moderate, all in build tools (`@capacitor/assets` → trapeze/xcode/uuid, `vite-plugin-pwa` → workbox-build/glob/minimatch/rimraf); nothing that ships to players |
| `npm audit` (desktop) | 6 moderate, all in `electron-builder` (packaging only) |
| Outdated | Capacitor 8.6.0 → 8.6.3, AdMob plugin 8.3.0 → 8.5.0, Vite 8.3.5 → 8.4.0, Vitest 5.1.0 → 5.1.2, Playwright 1.64.1 → 1.65.1, **Electron 45.2.1 → 45.5.0** (ships Chromium security fixes to desktop players) |

## Top 10 weaknesses (ranked by how much players feel them)

1. **Dropped frames on the puzzle screen and campaign map** at phone speed (1% low 30 fps, worst frame 50 ms = 3x the budget), with no way to lower detail on a weak phone (no graphics setting).
2. **No crash or error reporting.** Once the app is in stores, crashes on real phones are invisible until a player complains or Play's vitals drop.
3. **Desktop app runs an Electron with known-fixed security issues** (45.2.1; 45.5.0 is out).
4. **No in-game way to rate or report a problem.** Store ratings drive ranking; bug reports currently need the Launch Control page, which players never see.
5. **The six space backdrops have no proven license.** Their source is unknown; both stores ask you to confirm you hold the rights.
6. **Text size can't be changed in the game**, and all text is hard-coded English (not ready to translate).
7. **No automatic build and test on each push**: GitHub Actions jobs don't start on this account, so a release can't be rebuilt automatically from its tag.
8. **One flaky end-to-end test** (Alien Duel timing under load) can hide a real failure.
9. **Desktop builds are unsigned**: Windows SmartScreen and macOS Gatekeeper warn players on first launch.
10. **Build-tool advisories** (14 moderate) and small patch updates pending: no player risk today, but they should be cleared before a release build.
