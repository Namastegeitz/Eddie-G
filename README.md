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
| [Off-Grid Survival Kit](apps/off-grid-survival-kit/) | Offline installable field app (vanilla HTML/CSS/JS PWA): GPS map with saved tiles, waypoints, tracks, MGRS, sun/moon, triangulation, QR/SOS; survival guides; device tools; printable emergency PDF. | Built; offline acceptance test passes (24 checks). Zip in `apps/off-grid-survival-kit/dist/`. |
| [Bug's-Eye View](apps/bugs-eye-view/) | Action-stealth survival game (Godot 4.7) as a tiny bug in a giant house. Android, iOS, Windows, macOS, Linux, Web. | All 6 phases built and tested; placeholder art. |

## Working across devices

Work happens on the `claude/nifty-lamport-bfm2ub` branch and is pushed after
each step, so the latest state is always on GitHub whether you pick up from
desktop or phone. `STATUS.md` records where things left off.
