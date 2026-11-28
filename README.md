# Eddie-G

Workspace for a set of new apps, plus the prompts used to build them.

## Layout

```
ALIEN-SUDOKU/    Alien Sudoku: game, builds, store launch kit, live checklist (one folder for everything)
apps/            one folder per app (e.g. apps/<app-name>/)
prompts/
  claude/        prompts for Claude / Claude Code
  codex/         prompts for Codex
STATUS.md        running log of what's done and what's next
```

## Apps

| App | What it is | Status |
|---|---|---|
| [Bug's-Eye View](apps/bugs-eye-view/) | Action-stealth survival game (Godot 4.7) as a tiny bug in a giant house. Android, iOS, Windows, macOS, Linux, Web. | All 6 phases built and tested; placeholder art. |
| [**ALIEN SUDOKU**](ALIEN-SUDOKU/) | Sudoku with alien glyphs: 54-level campaign, daily puzzles, zen mode, Alien Duel, the Star Cadets, a theme song per difficulty, high-definition space maps, graphics setting, crash reporting. Version 1.3.0. Free with AdMob ads on phones. Android, iOS, Windows, macOS, Linux, Web. Everything for it (game, builds per platform, store launch kit, live checklist) is in `ALIEN-SUDOKU/`. | Game complete; store launch in progress: [Launch Control](https://claude.ai/artifact/LzbsCTPkTUsxyLLCUWCgRM) |

## Working across devices

Work happens on the `claude/nifty-lamport-bfm2ub` branch and is pushed after
each step, so the latest state is always on GitHub whether you pick up from
desktop or phone. `STATUS.md` records where things left off.
