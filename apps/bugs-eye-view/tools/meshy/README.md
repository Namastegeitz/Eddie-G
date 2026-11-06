# Generated 3D models with Meshy

The game ships with simple placeholder shapes. Every bug, threat, pickup,
piece of cover and big piece of furniture has a **model slot** (a
`SkinAnchor` node, named `...Skin`). Put a file called
`assets/models/<model_id>.glb` in the project and that slot shows the model
instead of the placeholder: it is turned to face forward, scaled to fit the
slot's box and set on the floor. Gameplay (collisions, hiding spots, light
and shade) never changes, so the game works the same with or without models.

`assets.json` lists all 113 slots with a text-to-3D prompt for each, in three
tiers:

| Tier | What | Count |
|---|---|---|
| 1 | The eight bugs, the human's sneaker, cat, dog, robot vacuum, swatter, crumbs, bug food, crumb gems and power-ups | 32 |
| 2 | Hiding spots (paper cup, sneaker, slipper, flowerpot, gnome, laundry basket, wheelbarrow...), lures, props, and the 18 showcase treasures (lost button to the Golden Acorn) | 50 |
| 3 | Furniture (fridge, stove, island, couch, armchair, aquarium, shed, bird bath...) | 31 |

## Generate them

You need a Meshy account with API access and its API key.

1. Set the key as an environment variable named `MESHY_API_KEY`. Don't put
   it in a file in this repo.
   - Windows PowerShell: `$env:MESHY_API_KEY = "<your key>"` (this window only)
   - macOS / Linux / Git Bash: `export MESHY_API_KEY=<your key>`
   - Claude Code cloud session: add it to the cloud environment's
     environment variables, and add `api.meshy.ai` and `assets.meshy.ai`
     to the environment's allowed network domains. Start a new session
     afterwards so it picks both up.
2. From `apps/bugs-eye-view`:

```bash
python3 tools/meshy/generate.py --list
python3 tools/meshy/generate.py --dry-run --tier 1
python3 tools/meshy/generate.py --tier 1
```

3. Open the project in Godot (or run `godot --headless --path . --import`).
   The models appear in the game straight away.

Each model is two Meshy tasks: a preview (the shape) and a refine (the
textures). `--preview-only` skips the textures and costs less, but the
models come out grey. Check what each task costs on your Meshy plan before
generating everything; start with tier 1 and look at the results first.

| Option | Does |
|---|---|
| `--tier N` | Only tier N (repeat for more: `--tier 1 --tier 2`) |
| `--only a,b` | Only these ids |
| `--force` | Regenerate models that already exist |
| `--preview-only` | Shapes without textures |
| `--parallel N` | Models in flight at once (default 2) |
| `--dry-run` | Print the requests; sends nothing and needs no key |

A run can be stopped and restarted: progress is saved in
`tools/meshy/state.json` after every step, and models already in
`assets/models/` are skipped, so nothing is paid for twice. Thumbnails go to
`tools/meshy/thumbnails/`.

## If a model looks wrong

- **Faces the wrong way**: select its `...Skin` node in the level or actor
  scene and change **Yaw Offset Deg** (try 0, 90 or -90).
- **Shape is off**: edit its prompt in `assets.json` and run
  `generate.py --only <id> --force`.
- **Too big for the web build**: textured models can be several MB each.
  Godot compresses textures on export, but for the web build you may want
  only tier 1 and 2.

## Notes

- The request fields in `assets.json` (`defaults`) follow Meshy's text-to-3D
  API (`/openapi/v2/text-to-3d`) as of when this was written. The session
  that wrote this couldn't reach Meshy, so it was tested against a local
  fake of the API only (`test_generate.py`, run by `tools/run_tests.sh`). If
  Meshy answers a request with a 400 error naming a field, change or remove
  that field in `defaults` and run again.
- If Meshy's terms for your plan put conditions on using generated models
  in a commercial game, they apply to these files.
