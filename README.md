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
| [Monkey See, Monkey Do](apps/monkey-see-monkey-do/) | Rhythm-memory game: a 3D cartoon monkey dances a routine, you copy it. 30 levels in 3 worlds, Endless, Free Dance, 100 skins (50 premium, unlocked by play goals or golden bananas), How it works screen built from the rules. Web/PWA (three.js) plus iOS and Android apps (Capacitor). | Built; 464 unit checks, 29-step play-through and 12 phone checks pass. APK/IPA need the Android SDK or a Mac/cloud build ([phones guide](apps/monkey-see-monkey-do/mobile/README.md)). |
| [Canopy Crossing](apps/canopy-crossing/) | Jungle arcade crosser (Godot 4.7, portrait): 50 real animals with signature abilities, 10 real rainforests on a spinning globe, Journey/Endless/Daily modes, Berries + Amber economy, data-driven store, Expedition Pass, tutorial. Everything is content files. Android, iOS, Windows, macOS, Linux, Web. | All 8 phases built; 250-check phase audit passes (bot beats all 30 stages with the free starter). Sandbox billing/ads; procedural art; [playable web build](https://claude.ai/artifact/NHzAQ2w4jCjWjLkoxLSdB3). |
| [Bug's-Eye View](apps/bugs-eye-view/) | Action-stealth survival game (Godot 4.7) as a tiny bug in a giant house. Android, iOS, Windows, macOS, Linux, Web. | All 6 phases built and tested; placeholder art. |

## Working across devices

Work happens on the `claude/nifty-lamport-bfm2ub` branch and is pushed after
each step, so the latest state is always on GitHub whether you pick up from
desktop or phone. `STATUS.md` records where things left off.
