# Detailed models with Meshy

Creatures and scenery in first person, and the starter animals on the home
and animal screens, use detailed models made with Meshy (text to 3D).
Everything else keeps the game's built shapes, and so does the Low graphics
setting, so the game works the same with or without these files.

- `assets.json`: one entry per model (prompt, polygon budget, group). Groups
  have credit budgets (`budgets`), priced with `costs` (a preview is 20
  credits, texturing 10, at the time of writing).
- `generate.py`: makes the models. It records each task's cost against its
  group before sending it and checks the account's live balance, so a run
  never goes over budget, even after a restart (`state.json`). The raw
  download goes to `raw/` (not committed); a phone-friendly copy (textures
  1024 px for animals, 512 for scenery, WebP) goes to `assets/models/`.
- `godot_textures.py`: after Godot imports the models, switches their
  textures to Basis Universal (small download, GPU-compressed on phones),
  1024 px for the starter animals' colour maps and 512 for everything else.
- `content/models.json` says which hazard, prop, landmark and animal uses
  which model (see docs/CONTENT.md).

```bash
python3 tools/meshy/generate.py --balance            # credits left
python3 tools/meshy/generate.py --list               # done / pending, spend per group
python3 tools/meshy/generate.py --only scene_palm    # one model
python3 tools/meshy/generate.py --group scenery      # everything missing in a group
godot --headless --path . --import && python3 tools/meshy/godot_textures.py && godot --headless --path . --import
```

The key comes from `MESHY_API_KEY`, or in a Claude Code cloud session from
the environment's network secret for api.meshy.ai (the session's proxy adds
it). Never put the key in this repo. If Meshy's terms for your plan put
conditions on using generated models in a commercial game, they apply.

Note: other projects may use the same Meshy account at the same time; the
budgets here count only this game's own tasks.
