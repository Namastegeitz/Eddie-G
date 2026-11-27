# **MONKEY SEE, MONKEY DO** · Upgrade report, 27 Nov 2026

Run of the *Universal Upgrade + Release Build* prompt (apps and games).

- Branch: `upgrade/2026-11-27-monkey-see-monkey-do` (the date alone, `upgrade/2026-11-27`, could clash with other projects in this repository that run the same prompt today).
- Rollback point: commit `8ea014e`, tagged `pre-upgrade-2026-11-27-monkey-see-monkey-do` locally. GitHub refused tag pushes from this environment, so the commit hash is the remote rollback reference.
- Every change below is additive: new behaviour sits behind a setting whose default keeps today's behaviour, unless the line says otherwise.

## Baseline (before any change)

**What it is:** a 3D rhythm and memory game. Plain JavaScript modules, three.js r162 (WebGL 2, with WebGL 1 fallback), bundled with esbuild 0.24.2. Wrappers: Capacitor 8.5.3 (Android, iOS) with cordova-plugin-purchase 13.19.1 for in-app purchases; Electron 36.9.5 + electron-builder 25.1.8 for the PC edition (no purchases). No backend, no accounts, no analytics; saves live on the device. No AI agents inside the app.

**Targets:** App Store, Google Play, Steam, GOG, Microsoft Store, Epic, itch.io, plus the public web beta on GitHub Pages.

**Measured on this machine** (Linux, Chromium with the SwiftShader software renderer, no GPU, phone-sized 390x844 window). Software rendering is 10-50x slower than a phone GPU, so the times are for before/after comparison here, not real-device numbers. Draw calls and triangles are the same on any device.

| Measure | Baseline |
|---|---|
| Build | `node scripts/build_web.mjs`: OK, no warnings |
| Web build size | dist/www 1.3 MB; app.js 1,004 KB (286 KB gzipped); single-file HTML 1.1 MB; web/itch.io zips 0.47 MB |
| Cold start to playable | 5.6 s (software renderer) |
| JS memory | 21.7 MB after start, 20.4 MB after a level |
| Playing level 1 on Low | 5.6 fps average, 1% low 1.9 fps, worst frame 533 ms, 5 spikes over 2x average (software) |
| Frame draw time, all 4 stages x Low/High | total 1,174 ms; jungle Low 130 / High 332 ms; beach 82 / 147; disco 97 / 160; moon 79 / 147 |
| Draw calls / triangles | Low 94-119 calls, 86k-102k triangles; High 117-143 calls, 130k-199k triangles |
| First time a stage is shown (build + shader compile) | beach 3,486 ms, disco 383 ms, moon 589 ms: a visible freeze when a new map first appears |
| Errors | none in the page during the benchmark or the test runs |
| Tests | rules 767/767; play-through 35/35; device checks 15/15; live beta site 13/13 |
| Dependencies | three r162; @capacitor/* 8.5.3 (app 8.1.2, haptics 8.0.2, splash 8.0.2, keep-awake 8.0.1); cordova-plugin-purchase 13.19.1; electron 36.9.5; electron-builder 25.1.8; esbuild 0.24.2; Playwright 1.63 (test machine) |
| Known vulnerabilities | phone tooling: 3 moderate (`@capacitor/cli` 8.5.0-8.5.3 and its `uuid`, `xcode`); desktop: 18 (1 critical `tar`, 13 high incl. Electron itself and electron-builder's chain, 4 moderate) |

Benchmark: `node tests/benchmark.js` (baseline saved in `tests/benchmark-baseline.json`).

### Top 10 weaknesses, ranked by how much players feel them

1. **A freeze the first time a new map appears.** Building and compiling the beach took 3.5 s here; on phones it is a short but visible hitch at level 4, then again for disco and moon.
2. **No safety net for errors.** No global error handler, no saved error log, and no recovery if the phone's GPU resets (WebGL context loss after backgrounding shows a frozen or black screen).
3. **The PC edition has no controller support**, and the keys can't be changed. Steam and Steam Deck players expect a gamepad to work.
4. **The desktop wrapper runs an end-of-life Electron (36)** with known high-severity security issues, and its build tool pulls a critical `tar` issue.
5. **Graphics settle once and never adapt.** Auto measures only at start, so a phone that heats up and slows down mid-session stays on a level it can no longer hold. There is no frame-rate cap (battery) or resolution-scale option.
6. **The High jungle is heavy** (2.6x Low's draw time here), so mid-range phones depend entirely on Auto stepping down.
7. **Testers can't easily report from inside the game.** Reporting needs the separate claude.ai page and an invite; nothing in the game copies the device details and recent errors for them.
8. **Web beta testers may play an old copy** after an update, because nothing tells an open game that a new version is ready.
9. **Capacitor 8.5.3 misses 8.6.3's security hardening** of its internal proxy routes.
10. **Release paperwork gaps:** no changelog in plain words, a fixed version with no build number, no asset credits list, no accessibility-label answers, no staged-rollout plan, and every on-screen string lives in code (not ready for translation).
