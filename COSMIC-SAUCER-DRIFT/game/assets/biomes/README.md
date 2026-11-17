# Biome import slots

`content/biomes.json` names one GLB slot per formation variant:

| Biome | Slots |
|---|---|
| Eerie Caldera | `eerie/ridge.glb`, `eerie/cone.glb`, `eerie/columns.glb`, `eerie/shard.glb` |
| Divine Summit | `divine/peaks.glb`, `divine/cone.glb`, `divine/crystals.glb`, `divine/arch.glb` |

An empty slot uses the procedural low-poly recipe. Fill the slots with
`tools/meshy/generate.py` (Meshy Text-to-3D, remeshed low-poly), then run
`godot --headless --path . --import` so Godot imports them with LODs. See
`docs/ASSET_PIPELINE.md`.
