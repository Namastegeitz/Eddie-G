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
| [Monkey See, Monkey Do](apps/monkey-see-monkey-do/) | Rhythm-memory game: a detailed 3D cartoon monkey (fingers, blinking eyes, springy tail) dances a routine on four rich stages, you copy it. 40 levels in 4 worlds (a new map every level after 3, a Moon world, take-turns duets in levels 2-3), Endless, Free Dance, 100 skins (50 premium, unlocked by play goals or golden bananas), 88 pieces of gear in 8 slots, saved outfits, an optional in-app Shop ($0.99-$9.99 packs, bundles, skin sets; grown-up check and monthly limit), How it works screen built from the rules. Web/PWA (three.js) plus iOS and Android apps (Capacitor). | Built; 507 unit checks, 34-step play-through and 12 phone checks pass. Real store purchases need the products set up in App Store Connect / Play Console. APK/IPA need the Android SDK or a Mac/cloud build ([phones guide](apps/monkey-see-monkey-do/mobile/README.md)). |
| [Canopy Crossing](apps/canopy-crossing/) | Jungle arcade crosser (Godot 4.7, portrait): 50 real animals with signature abilities, 220 maps (22 real rainforests x 10 levels, opening as you play) on a spinning globe, bird's-eye and first-person views, Journey/Endless/Daily modes, Berries + Amber economy, data-driven store, Expedition Pass, tutorial. Everything is content files. Android, iOS, Windows, macOS, Linux, Web. | All 8 phases built, graphics and feel upgrade, 80 themed first-person scenes, digital globe, skill levels, smoother runs; 352-check phase audit passes; the bot beats all 220 levels with the free starter. Sandbox billing/ads; procedural art; [playable web build](https://claude.ai/artifact/NHzAQ2w4jCjWjLkoxLSdB3). |
| [Cosmic Saucer Drift](apps/cosmic-saucer-drift/) | Arcade UFO kart racer (Godot 4.7, landscape) for Google Play, set on real worlds: 14 planet/moon tracks in 4 real star systems (Solar System, TRAPPIST-1, Alpha Centauri, exoplanet extremes) + a Grand Prix, each with real fact cards, real suns in the sky and per-world gravity; reverse/mirror versions (42 layouts). 14 alien spacecraft incl. 4 premium craft with perks, all earnable with Race Credits; 8 power-ups (rockets, lasers, comet, EMP, nitro, shield, mine, tractor) in 5 position lineups; drifting, energy core, cups, time trial, boss races, daily challenge, 2P split-screen. v3: HD procedural craft and pilots with animated faces and moods, detailed worlds, shadows, effects, Low-Ultra graphics tiers. Free, no ads or purchases yet; ads and real-money store layers built in and switched off. | v3 built; 667-check smoke test and AI race sim on all 42 layouts pass. [Debug APK](apps/cosmic-saucer-drift/dist/android/cosmicsaucerdrift-debug.apk), [playable web build](https://claude.ai/artifact/Wjris6Pjst5K54bF6z8MUY), store kit in `docs/`. |
| [Bug's-Eye View](apps/bugs-eye-view/) | Action-stealth survival game (Godot 4.7) as a tiny bug in a giant house. Android, iOS, Windows, macOS, Linux, Web. | All 6 phases built and tested; placeholder art. |

## Working across devices

Work happens on the `claude/nifty-lamport-bfm2ub` branch and is pushed after
each step, so the latest state is always on GitHub whether you pick up from
desktop or phone. `STATUS.md` records where things left off.
