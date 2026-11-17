# Meshy asset pipeline (biomes and HD craft)

Two kinds of Meshy assets: rock formations for the volcanic biomes (below)
and the HD craft, exteriors plus first-person cockpits (see "HD craft"
further down).

The volcanic biomes are built from formation variants. Each variant has an
import slot (`mesh` in `content/biomes.json`). All 8 slots now hold
Meshy-generated meshes (see `assets/biomes/meshy_manifest.json` for the
prompts and task ids). An empty slot falls back to the procedural recipe.

## Generate with Meshy

Needs a Meshy API key and network access to `api.meshy.ai` and the
download host it returns (`assets.meshy.ai`).

```sh
export MESHY_API_KEY=...            # never commit it (in the cloud session the key is a
                                    # network secret: use MESHY_API_KEY=proxy-injected)
python3 tools/meshy/generate.py --dry-run --force --only cone   # see the requests
python3 tools/meshy/generate.py --force --only cone             # plan + cost, spends nothing
python3 tools/meshy/generate.py --force --only cone --yes       # generate (20 credits)
```

**Credit guard.** A run prints its plan and estimated cost and spends
nothing without `--yes`. It refuses runs over `--max-credits` (default 60,
three models) and never lets the account drop below `--keep` credits
(default 1000). It reports the credits spent afterwards. Rates measured on
this account: 20 credits per model, 10 per texture pass. Regenerate one
formation at a time and look at it in the game before doing more.

For each formation the script:
1. Creates a Text-to-3D **preview** task from the formation's `prompt`, remeshed to a low-poly triangle mesh (`should_remesh`, `topology: triangle`, `target_polycount`: 6000 for horizon ridges, 4000 for volcanoes, 2500 beside the road, or the formation's `polycount`).
2. **Refines** it (PBR textures) only for formations with `"material": "asset"`. Formations painted with the biome palette (all 8 today) skip it: their textures would never show, and a textured GLB is about 6 MB instead of 150-400 KB. `--texture` forces it.
3. Downloads the GLB into the slot (`assets/biomes/<biome>/<id>.glb`) and records the task ids in `assets/biomes/meshy_manifest.json`.

Existing slots are skipped unless `--force`. Standard library only.

## Import, bake LODs, check

```sh
godot --headless --path . --import
godot --headless --path . res://tools/meshy/bake_lods.tscn
godot --headless --path . res://tools/content_report.tscn
```

Meshy meshes give every face its own vertices, so Godot's import-time LOD
generation finds nothing to collapse. `bake_lods` welds each mesh, moves it
into unit space (base on the ground, footprint radius 1, height 1, long side
along the horizon), builds LODs (5-8 levels) and saves `<slot>_lod.res`
next to the GLB. The game loads the baked mesh first, then the raw GLB,
then the recipe, and scales it to the formation's `scale` and `height`.
Exports ship only the baked meshes (`assets/biomes/*.glb` is excluded). The
biome shader shades every formation as faceted low-poly. The content report
lists each formation's source, triangle count, LOD levels and bounds.

The first run used 170 Meshy credits for all 8 formations (one ridge was
also textured before the texture pass was switched off).

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

## HD craft (exteriors and cockpits)

`content/craft_hd.json` holds the 10 HD craft (`"hd": true`, shape
`"model"`). Each has two slots: `model` (the exterior,
`assets/craft/<id>/exterior.glb`) and `cockpit` (the first-person interior,
`cockpit.glb`).

```sh
export MESHY_API_KEY=proxy-injected
python3 tools/meshy/generate.py --source craft --only lancer             # plan + cost (60), spends nothing
python3 tools/meshy/generate.py --source craft --only lancer/model --yes # one part (30)
python3 -I tools/meshy/extract_textures.py --only lancer                 # albedo / ORM / normal JPEGs
godot --headless --path . --import
python3 -I tools/meshy/extract_textures.py --only lancer --fix-imports   # lossy WebP + mipmaps
godot --headless --path . --import
godot --headless --path . res://tools/meshy/bake_craft.tscn -- --only=lancer
xvfb-run -a godot --path . res://tools/meshy/craft_preview.tscn --rendering-driver opengl3 -- \
    --out=/tmp/views res://assets/craft/lancer/exterior_lod.res,res://assets/craft/lancer/cockpit_lod.res
xvfb-run -a godot --path . res://tests/shots.tscn --rendering-driver opengl3 -- --tracks=ceres --frames=520 --craft=lancer --cockpit
```

- **Quality.** Craft use the `latest` Meshy model (20 credits a preview)
  plus a PBR texture pass (10), so 30 credits a part and 60 a craft. A
  `meshy-6-lite` test (15) came out blobby, so it isn't used for craft.
- **Textures.** `extract_textures` pulls the base colour, metal/rough and
  normal maps out of the GLB and downsizes them. Exteriors use 1024 colour
  and normal maps with a 512 ORM. Cockpits get a 2048 colour map because
  they're seen up close. Lossy WebP keeps each map to a few hundred KB.
  The GLB's own images are never imported (`embedded_image_handling=0`).
- **Bake.** `bake_craft` welds the mesh, turns it nose-forward (-Z) by the
  data's `yaw`, scales it to unit size (longest side 1), adds tangents
  (and LODs for exteriors), and saves `<slot>_lod.res` with a
  `<slot>_mat.tres` material (ORM: G = roughness, B = metal).
  `craft_preview` renders top, 3/4 and front views. The green arrow in the
  top view is the game's forward.
- **Git and exports.** Raw craft GLBs (7-9 MB) are in neither git nor the
  exports. The baked meshes, materials and JPEGs are. To get the GLBs back
  for free, while Meshy still keeps the task results:
  `generate.py --source craft --refetch`.
- **Calibrate in the data**, not the mesh:
  - `model.yaw`: turns the nose to -Z.
  - `seat` and `canopy`: unit-space pilot seat and glass size.
  - `engines` and `flame`: flame positions and size.
  - `length`: world size.
  - `cockpit.offset` and `cockpit.width`: the interior's place relative to
    the eye, in metres before it is shrunk.
  - `cockpit.turn`: rotates the interior.
  - `cockpit.frame`: false skips the procedural canopy frame.
  - `cockpit.accent`: colour of the light strips.

**In the game.** An HD craft draws its baked hull and its own PBR material.
A paint job tints a copy of that material. The pilot sits under a
streamlined glass canopy at `seat`, and flames burn at `engines`. A craft
whose hull isn't baked yet flies as the classic saucer.

In first person, every craft has a 3D interior: its own cockpit, or the
`default_cockpit` craft's for the standard fleet. Around the Meshy console
the game adds a canopy frame (side sills, windscreen pillars over the head,
light strips) and a cabin light. The interior:
- is built life-size, then shrunk round the eye (`COCKPIT_SHRINK`), so nearby
  walls can't poke through it
- is placed by the first-person camera every frame, so spins and leans
  don't swing it
- sits on that player's own cockpit render layer (13 or 14), which no other
  camera draws

The player's own exterior goes on their pilot layer and is hidden from the
seat. AI racers never fly HD craft.

**Credits used so far for craft:**
- 15: lite test
- 30: Aurora exterior
- 30: Aurora cockpit

A run now reports its own tasks' cost separately from the change in the
account balance. Another client was generating models on the same account at
the same time, and the balance-only report counted its spend too. Before
each model the run also checks the balance again against the `--keep` reserve.

## Tests

- `python3 tools/meshy/test_pipeline.py`: runs the generator against a local
  **mock** of the Meshy API (no network, no key). It checks the requests,
  the polling, the download into the slot and the manifest.
- `tests/fixtures/formation_fixture.glb` is a ridge exported by the game
  itself (`tools/make_fixture_glb.tscn`). The smoke test puts it in a slot to
  check the import path: GLB in place of the recipe, importer LODs, unit
  bounds. It is not a Meshy asset.
- `CSD_SMOKE=hd` checks the HD fleet. It covers the data, the free grants,
  AI never flying HD craft, and the baked hull with its material and flames.
  It also checks the 3D cockpit's layers, the paint tint copy and the
  classic fallback.
- The race group checks that the 3D cockpit is drawn only by its own
  camera, sits at the eye and faces the camera's way.
