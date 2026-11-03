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
| [Bug's-Eye View](apps/bugs-eye-view/) | Action-stealth survival game (Godot 4.7) as a tiny bug in a giant house. Android, iOS, Windows, macOS, Linux, Web. | All 6 phases built and tested; placeholder art. |
| [Alien Sudoku](apps/alien-sudoku/) | Sudoku with alien glyphs: 54-level campaign, daily puzzles, zen mode, achievements, synthesized space music. Free with AdMob ads on phones. Android, iOS, Windows, macOS, Linux, Web/PWA. | Complete; 86 unit + 13 end-to-end tests; CI builds every platform. |

## Working across devices

Work happens on the `claude/nifty-lamport-bfm2ub` branch and is pushed after
each step, so the latest state is always on GitHub whether you pick up from
desktop or phone. `STATUS.md` records where things left off.
