# Biome asset pipeline (Meshy)

The volcanic biomes are built from formation variants. Each variant has an
import slot (`mesh` in `content/biomes.json`). An empty slot uses the
procedural recipe; a GLB in the slot replaces it with no code change.

## Generate with Meshy

Needs a Meshy API key and network access to `api.meshy.ai` and the
download host it returns (`assets.meshy.ai`).

```sh
export MESHY_API_KEY=...            # never commit it
python3 tools/meshy/generate.py --dry-run          # see every request first
python3 tools/meshy/generate.py --biome eerie      # or --only ridge,cone, or everything
```

For each formation the script:
1. Creates a Text-to-3D **preview** task from the formation's `prompt`, remeshed to a low-poly triangle mesh (`should_remesh`, `topology: triangle`, `target_polycount`: 6000 for horizon ridges, 4000 for volcanoes, 2500 beside the road, or the formation's `polycount`).
2. **Refines** it (PBR textures) unless `--no-texture`.
3. Downloads the GLB into the slot (`assets/biomes/<biome>/<id>.glb`) and records the task ids in `assets/biomes/meshy_manifest.json`.

Existing slots are skipped unless `--force`. Standard library only.

## Import and LODs

```sh
godot --headless --path . --import
godot --headless --path . res://tools/content_report.tscn
```

Godot imports each GLB with mesh LODs (`meshes/generate_lods=true`, the
default) and the renderer switches them by distance. The game normalises
any model to unit space (base on the ground, footprint radius 1, height 1),
then scales it to the formation's `scale` and `height`, so a Meshy model of
any size or origin drops in correctly. The content report lists each
formation's source (`asset` or `recipe`), triangle count, LOD levels and
normalised bounds.

Procedural recipes are built at two detail levels instead (about 2,000 and
300 triangles for a ridge) and switch by distance.

## Placement rules

- Formations keep a clearance from the road and every shortcut: a 50 m
  cell grid of track points is checked for each spot.
- `far` formations ring the track like a mountain horizon, `mid` ones fill
  the middle distance, `near` ones stand just past the barrier.
- Volcano recipes get a glowing lava crater and, on Medium and up, a smoke
  plume. Lava rivers run on the ground plane 50 m below the road and end in
  pools.

## Tests

- `python3 tools/meshy/test_pipeline.py`: runs the generator against a local
  **mock** of the Meshy API (no network, no key). It checks the requests,
  the polling, the download into the slot and the manifest.
- `tests/fixtures/formation_fixture.glb` is a ridge exported by the game
  itself (`tools/make_fixture_glb.tscn`). The smoke test puts it in a slot to
  check the import path: GLB in place of the recipe, importer LODs, unit
  bounds. It is not a Meshy asset.
