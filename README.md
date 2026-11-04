# Eddie-G

Workspace for a set of new apps, plus the prompts used to build them.

## Layout

```
apps/            one folder per app (e.g. apps/<app-name>/)
prompts/
  claude/        prompts for Claude / Claude Code
  codex/         prompts for Codex
STATUS.md        running log of what's done and what's next
```

## Apps

| App | What it is | Status |
|---|---|---|
| [Off-Grid Survival Kit](apps/off-grid-survival-kit/) | Offline installable field app (vanilla HTML/CSS/JS PWA): GPS map with saved tiles, waypoints, tracks, MGRS, sun/moon, triangulation, QR/SOS; survival guides; device tools; printable emergency PDF. | Built; offline acceptance test passes (25 checks). Zip in `apps/off-grid-survival-kit/dist/`. |
| [Monkey See, Monkey Do](apps/monkey-see-monkey-do/) | Rhythm-memory game: a 3D cartoon monkey dances a routine, you copy it. 30 levels in 3 worlds, Endless, Free Dance, 100 skins (50 premium, unlocked by play goals or golden bananas), 88 pieces of gear in 8 slots, saved outfits, an optional in-app Shop ($0.99-$9.99 packs, bundles, skin sets; grown-up check and monthly limit), How it works screen built from the rules. Web/PWA (three.js) plus iOS and Android apps (Capacitor). | Built; 507 unit checks, 33-step play-through and 12 phone checks pass. Real store purchases need the products set up in App Store Connect / Play Console. APK/IPA need the Android SDK or a Mac/cloud build ([phones guide](apps/monkey-see-monkey-do/mobile/README.md)). |
| [Canopy Crossing](apps/canopy-crossing/) | Jungle arcade crosser (Godot 4.7, portrait): 50 real animals with signature abilities, 200 maps (20 real rainforests x 10 levels) on a spinning globe, bird's-eye and first-person views, Journey/Endless/Daily modes, Berries + Amber economy, data-driven store, Expedition Pass, tutorial. Everything is content files. Android, iOS, Windows, macOS, Linux, Web. | All 8 phases built; 250-check phase audit passes (bot beats all 30 stages with the free starter). Sandbox billing/ads; procedural art; [playable web build](https://claude.ai/artifact/NHzAQ2w4jCjWjLkoxLSdB3). |
| [Cosmic Saucer Drift](apps/cosmic-saucer-drift/) | Arcade UFO kart racer (Godot 4.7, landscape) for Google Play: hover drifting with 3-level Plasma Boost, Dark Matter energy + Emergency Hover, 8 power-ups, 6 tracks x Normal/Reverse/Mirror with hazards, hidden shortcuts and Star Shards, 8 pilots with passives and boss races, 6 upgradeable saucers + cosmetic garage, Galactic Cups, Time Trial with ghost, Daily Challenge, 2-player split-screen, achievements. Free with no ads; ads layer built in and switched off. | Built; 291-check smoke test and AI race sim on all 18 layouts pass. [Debug APK](apps/cosmic-saucer-drift/dist/android/cosmicsaucerdrift-debug.apk), [playable web build](https://claude.ai/artifact/Wjris6Pjst5K54bF6z8MUY), store kit in `docs/`. |
| [Bug's-Eye View](apps/bugs-eye-view/) | Action-stealth survival game (Godot 4.7) as a tiny bug in a giant house. Android, iOS, Windows, macOS, Linux, Web. | All 6 phases built and tested; placeholder art. |

## Working across devices

Work happens on the `claude/nifty-lamport-bfm2ub` branch and is pushed after
each step, so the latest state is always on GitHub whether you pick up from
desktop or phone. `STATUS.md` records where things left off.
