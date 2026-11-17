# **COSMIC SAUCER DRIFT** · launch checklist

- **Live page:** https://claude.ai/artifact/4MPCACGK7XTCzwTcBbqN1m (private to you; in the
  COSMIC SAUCER DRIFT folder on your Artifacts page)
- The page is the place to tick steps. Each tick, note, bug report and play session is saved in
  the page's own database. Claude reads it from there.
- The project README (`../README.md`) shows the same checklist with ✅ marks. Claude refreshes it
  when syncing.

Files
- `make_checklist.py`: the phases and steps. Edit this, then run it to write `checklist.json`.
- `build.py`: builds `page/index.html` (from `page/template.html`) and `../README.md`.
- `progress.json`: the last synced status of every step.
- `page_url.txt`: the live page's link.

Saved data (in the live page)
- `steps/<id>`: status (todo/doing/blocked/done), note, who changed it and when, last 20 changes.
- `bugs/<id>`: title, what happened, steps to repeat, expected, platform, device, build, area,
  severity, status (new/seen/fixing/fixed/wontfix), Claude's note.
- `playtests/<id>`: platform, device, mode, minutes, fun 1–5, what felt great/off, play again, smoothness.
