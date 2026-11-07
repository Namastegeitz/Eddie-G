# Upgrade audit: every system, what changed

Four read-only audits covered the race core, items/effects/audio,
tracks/models/shaders and menus/save/meta. Each finding below was checked
against the code before it was fixed. Data schemas are in
[SCHEMAS.md](SCHEMAS.md); the Meshy asset pipeline is in
[ASSET_PIPELINE.md](ASSET_PIPELINE.md).

## Systems inventory

| System | Files | What it does |
|---|---|---|
| Race core | `scripts/race/race.gd` | Staged load behind the loading screen, physics loop, places, laps, slipstream, bumps, rubber band, pause, results, dynamic resolution. |
| Driving and physics | `scripts/race/racer.gd`, `scripts/data/tuning.gd` | Hover physics, drift and Plasma Boost, tricks, glide, Dark Matter energy, statuses, rescue beam. |
| Technical Wonders (new) | `scripts/race/wonder.gd` | Signature systems of the premium craft: charge, fire, overclock heat, burnout. |
| Input | `autoload/input_router.gd`, `scripts/race/player_driver.gd`, `scripts/ui/touch_controls.gd`, `scripts/ui/desktop_hints.gd` | Keys, pads, mouse stick, touch and tilt per player. |
| AI | `scripts/race/ai_driver.gd` | Racing line, speed planning, drifts, tricks, items, Wonders. |
| Camera and ghost replay | `scripts/race/race_camera.gd`, ghost code in `race.gd` | Chase, cockpit, intro and finish cameras; Time Trial ghost record and playback. There is no full replay system. |
| Items, hazards, pickups | `scripts/race/items.gd`, `hazards.gd`, `pickups.gd` | 20 power-ups with pooled effect nodes, track hazards, pods, crates, pads, shards. |
| Effects | `scripts/gfx/race_fx.gd`, `item_models.gd`, `shader_warmup.gd` | Pooled shockwaves, flashes and bursts; item meshes; shader pre-compile. |
| Audio | `autoload/audio.gd`, `scripts/race/race_audio.gd`, `tools/gen_audio.py` | Sound pools, engine loops, music, and the procedural sound generator. |
| Tracks | `scripts/data/track_defs.gd`, `scripts/track/*.gd` | Track data (there is no level editor: tracks are data), path sampling, road and wall geometry, scenery. |
| Volcanic biomes (new) | `scripts/track/biome_builder.gd`, `formations.gd`, `content/biomes.json` | Eerie and Divine scenery, Meshy import slots. |
| Craft and pilots | `scripts/data/catalog.gd`, `scripts/race/saucer_model.gd`, `scripts/gfx/pilot_model.gd`, `mesh_kit.gd`, `gfx.gd` | 14 craft, 16 pilots, quality tiers. |
| Content packs (new) | `autoload/content.gd`, `scripts/data/effects.gd`, `content/` | JSON content and drop-in packs, effect keys. |
| Super Upgrades (new) | `scripts/data/upgrades.gd`, `content/wonders.json`, `content/upgrades.json` | Stardust, Wonder tiers, mods, sets, overclock, global perks. |
| Scoring and meta | `autoload/game.gd`, `scripts/data/achievements.gd` | Race Credits, Stardust, cups, stars, bosses, medals, daily challenge, achievements. |
| HUD | `scripts/ui/hud.gd`, `minimap.gd`, `item_icon.gd`, `side_tab.gd`, `wonder_meter.gd` | Place, laps, item slot, energy, toasts, Wonder meter. |
| Menus | `scripts/ui/main_menu.gd`, `menu_stage.gd`, `results_screen.gd`, `pause_menu.gd`, `portrait_studio.gd`, `ui_kit.gd` | Every screen, the 3D backdrop, pilot portraits. |
| Save and settings | `autoload/save.gd` | One JSON file, migrations, settings. |
| Store and ads | `autoload/store.gd`, `ads.gd`, `scripts/store`, `scripts/ads` | Off in v1; provider layers. |
| Asset tools | `tools/gen_audio.py`, `tools/meshy/*`, `tools/content_report.*`, `tools/web_artifact/package.py` | Sound generation, Meshy generation, content validation, web packaging. |
| Tests | `tests/smoke.*`, `sim.*`, `bench.*`, `shots.*`, `menu_shots.*`, `craft_shots.*`, `loadtime.*` | Flow tests, race simulator, frame bench, screenshots. |

## Changes, one line each

### Data-driven content
- Pilot passives and craft perks are now `effects` dictionaries; the old `if passive == ...` and `if perk == ...` branches in the racer, race, items and pickups are gone.
- `scripts/data/effects.gd` defines every effect key once with its limits and menu text; anything that has effects (pilot, craft, mod, set, perk, Wonder tier) uses the same keys.
- `autoload/content.gd` loads `content/*.json` and every pack in `content/packs/` and `user://packs/`, validates them, and skips bad entries with a message instead of crashing.
- `Catalog.PILOTS` and `Catalog.SAUCERS` became extendable, so a pack can add pilots and craft; a pack pilot can bring its own face (`look`).
- Starting pilots come from the catalog (`unlock: "start"`), and old saves are granted new ones on load.
- Achievements "every cup", "every boss pilot" and "every Star Shard" now count the content instead of fixed numbers (6 bosses had gone stale at 9).
- Shard totals on the home and stats screens follow the track list instead of a fixed 42.
- `tools/content_report.tscn` prints a validation report; `docs/examples/example_pack.json` is a working example pack, loaded by the smoke test.

### Save system
- Saves are written to a temp file and renamed over the real one, keeping a `.bak`; a half-written file can no longer wipe progress.
- An unreadable save is kept aside (`.corrupt-<time>`) and the backup is loaded instead.
- Settings get their types back after loading (JSON made `30` into `30.0`, so the frame-cap toggle didn't advance).
- Resetting progress re-applies volumes and the frame cap, and clears menu selections (a locked track could still be started).
- The Stardust wallet and Super Upgrades live under `wonders` in the save, apart from the old v1 `stardust` key that the migration renames.

### Driving, race core and AI
- Android Back no longer quits the app mid-race; on the home or title screen it saves and quits.
- Pausing while a race was still loading locked the game; pause now waits for the race to load.
- Dynamic resolution compares against the target frame time, so a 30 fps cap no longer drops the image to 60 %.
- The Time Trial ghost is no longer overwritten by slower runs (wrong save key).
- The ghost racer is no longer simulated, which stopped it from "rescuing" itself every few seconds.
- Finished AI racers cruise: they no longer take crates or fire items at players still racing.
- Aggressive AI still dodges mines and hazards while ramming a rival.
- AI item decisions re-roll 5 times a second instead of 60, so skill affects item use again.
- Geyser shortcuts are counted once, not twice ("Off the Map" unlocked at 5).
- Leading from pole now counts toward "lead a whole lap" on lap 1.
- A bounce off moss starts a new air time, so a drift tap on landing no longer starts a doomed trick.
- Chained rescues no longer throw a racer further and further ahead.
- Craft weight is clamped to at least 1, so effect totals can't make a bump divide by zero.
- On a touchscreen device in 2-player mode, player one no longer auto-accelerates.
- Racer per-stage timing is off unless a test turns it on (about 13 clock reads per racer per tick, each a JavaScript call on the web).
- Places are sorted in one reused array, and each racer reuses its ground ray query.
- The full-track search when far from the road only runs on the ground (it ran, and was thrown away, in the air).

### Items, effects and audio
- The EMP dome now goes back to its pool; from the third EMP each one built a new mesh mid-race.
- Comet Strike targets the leader still racing; once the winner finished it fizzled.
- A new item resets the AI's hold timer, so an item lost to an EMP no longer makes it dump the next one.
- The Energy Leech counts each victim once and drains only its 3 linked victims.
- Rockets and mines are not spent on finished or respawning racers.
- An expired decoy no longer pops when a rocket arrives.
- The repulsor and tractor follow the shield rule of every other item, and "Shield blocked it" only shows for a shield.
- Effect pools are sized for the most the game allows at once (wells, walls, chain bolts, portals, rockets).
- Sparks and dust have fixed pools of their own; switching one pool between them recompiled a shader on the web.
- In split-screen, player two hears their own hits and items (only player one's view has a 3D listener).
- 3D sounds take an idle voice first, and a bump plays one sound, not two.
- The engine loop no longer clicks at its loop point (filter warm-up in `gen_audio.py`).

### Tracks, models and shaders
- Road surfaces change cleanly at boundaries; the blended surface id drew bands of dust, ice and rail between metal and lava.
- In Reverse, the TRAPPIST-1e lift bridge no longer clips the 8 m wall where it comes down.
- The skyway corridor starts from the yawed ramp's real lip (Mars was 11 m off).
- The low wall where a skyway bridge crosses the road is built; the road edge there was open.
- Kepler-16b's skyway was retuned for the real lip: a 40 m landing strip (no hairpin) and a 5 m ramp; every skyway glide now peaks 5-7 m above the lip.
- Billboards are right-handed and their frame sits behind the panel, so they show as framed signs instead of solid slabs.
- Crystals keep their tilt, station modules lie flat and solar panels keep their yaw (scale is now local, not world).
- Rock shading uses proper normals under stretched instances; spires were 75 % "top dust".
- Energy Pods write depth, so far pods no longer paint over near ones.
- The costly planet surface shader runs on High and Ultra only, including the menu planet.
- Scenery placement checks a cell grid of track points instead of scanning the track for every candidate.
- The shortcut wall pass searches near the last match instead of the whole loop for every sample.

### HUD and menus
- Touch buttons are released on pause or focus loss; a finger lifted while paused used to stay "held".
- The HUD changes label colours only when the value changes, and the item icon redraws only on a new item.
- Desktop key hints read the racer's inputs and redraw only on a change (they polled every key again and redrew every frame).
- The Hangar builds the craft once per click instead of twice.
- Menus keep their scroll position and focused button when a screen redraws after a click.
- Lists scroll to follow a pad or keyboard, and screens without buttons focus Back.
- Results stack in portrait instead of pushing rewards and buttons off screen.
- Mid-cup results offer "Quit cup" instead of Garage and Menu, which silently abandoned the cup.
- "Next race" can't be pressed twice during an ad.
- 2-Player mode starts on a real track (a missing track id allowed Ceres' shards to be collected twice).
- The daily streak uses local dates (it broke every evening in the Americas), and the reward shown is the reward paid.

### Tests and tools
- The smoke suite gained tests for content, effects, Super Upgrades, all four Wonders (firing, phasing, pulse, burnout), Stardust, creatures, biomes, the import slot and the example pack (about 1,100 checks).
- The skyway landing test runs on Io, Mars and Kepler-16b, starting lined up with the ramp as a player would.
- `CSD_SMOKE=skyway,wonder` runs just those test groups.
- Item pool tests follow the configured pool sizes; the shockwave test waits real time instead of a frame count (it was flaky on a fast machine).
- `tests/shots.tscn` can fly a premium craft and fire its Wonder (`--wonder=dragon`) or force a biome (`--biome=divine`); `tests/menu_shots.tscn` takes `demo` for Super Upgrades progress.

### New features
- **RACE NOW** on the home screen repeats your last Quick Race in one tap (Enter or pad A).
- A **Racers** page before every race: pilot cards with portraits, a live close-up in the cockpit, the rivals you'll face, and START.
- 8 creature pilots race amongst the field, each with a passive. Two are free, three cost Race Credits and three are boss races.
- **Super Upgrades**: Stardust from clean, long drifts; a Prototype, Refined, Transcendent Wonder track per premium craft; Core, Field and Drive mods with set bonuses; overclock with heat and burnout; global perks for maxed craft.
- **Technical Wonders**: Photon Spinnaker, Lighthouse Cloak, Relativistic Jet and Stellar Harvest, on keys, pads and touch, with a HUD meter, effects and AI use.
- **Volcanic biomes**: Eerie and Divine scenery with formation variants, LODs, lava rivers, smoke, mist and lighting, a Settings switch and per-track defaults.
- **Meshy pipeline**: a generator, import slots, a LOD bake step and a validation report. All 8 biome formations are Meshy-generated (untextured previews, painted by the biome shader) and baked with 5-8 LOD levels.

## Found, not changed yet

These were verified but left for a later pass because they are larger
refactors or need a device to check:
- Items and hazards still dispatch with long `match` blocks; an `ItemDef`/`HazardDef` table would let new items drop in as data.
- The meteor dropper builds a mesh per falling shard.
- AI speed planning on a shortcut reads the main road's curves.
- The AI's roller dodge uses a different reach than the roller itself.
- `InputRouter.controls()` still polls every key and reads settings each tick.
- MeshKit caches template meshes per craft, pilot and tier, and reads them back from the GPU while merging.
- Whole-track MultiMeshes never frustum-cull, cloud spheres overdraw, and each craft is about 40 draw calls.
- `sin()` hashes in the road shader with large coordinates may band on some phone GPUs.
- The Play Billing and AdMob templates never call back on failure; both are off in v1.
- In 2-player mode on one keyboard, left and right Ctrl/Shift are not told apart.
