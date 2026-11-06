# Canopy Crossing: notes for Claude sessions

## Every update goes live for beta testers

The owner has shared the playable web build with beta testers through this
public link, and wants every update to reach them there:

    https://claude.ai/artifact/NHzAQ2w4jCjWjLkoxLSdB3   (artifact slug ac6f0a1e-5e54-4bf4-91c9-f0aaf95bf4ce)

After any change to the game is tested, committed and pushed:

1. `tools/build_web.sh` (web export, packaging, phone-browser tap test; it
   must print `WEB BUILD OK`).
2. Republish to that same artifact (never a new one): read its current
   version, then publish `build/web_artifact/canopy-crossing.html` as
   `index.html` plus whichever of `index-gamedata.wasm`, `index.js`,
   `index.part0/1/2.wasm` changed (compare sha256 with the live files).
   The artifact is shared publicly, so the republish states that it is
   public (shared_live "public", title "Canopy Crossing").
3. Tell the owner the link is updated.

## Checks before a commit

`FAST=1 tools/run_tests.sh` (compile, first-person render, phase audit in
the project and an exported pack) and the 200-level sweep
(`godot --headless --path . res://tools/level_sweep.tscn`). See RUN.md.
