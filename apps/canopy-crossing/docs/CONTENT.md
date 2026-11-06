# Adding content (no code changes)

Everything the game shows comes from `content/`. Files under
`user://content/` (downloaded packs) are merged on top at launch. After
editing, run `tools/run_tests.sh`: the audit validates every file (unknown
hazards, modules, regions, products or skins are reported) and the bot checks
every Journey stage is still beatable with the free Poison Dart Frog.

## A new animal: `content/animals/<id>.json`

```json
{
  "id": "ocelot", "number": 51, "name": "Ocelot",
  "region": "amazon", "home": "Amazon Basin", "pack": "amazon",
  "rarity": "rare",
  "unlock": {"type": "berries", "price": 600},
  "ability": {"name": "Pounce", "summary": "Sprint dash (2 tiles)",
              "modules": [{"module": "dash", "tiles": 2, "cooldown": 6.0}]},
  "stats": {"hop_time": 0.13, "hitbox": 0.58},
  "look": {"base": "mammal", "head": "cat", "ears": "round", "snout": "cat", "tail": "long",
           "pattern": "rosettes_small", "size": 0.7,
           "colors": {"primary": "#e0b060", "secondary": "#1d1408", "belly": "#f7ead0", "accent": "#d49a2a", "eye": "#c4d65a"}},
  "skins": [],
  "conservation": "Least Concern",
  "fact": "Ocelots are mostly active at night.",
  "sprite": ""
}
```

- **unlock.type**: `free` (starter), `berries`, `amber`, or `pack` (comes with
  its `pack`'s map pack / animal pack; `"amber": 150` sells it alone).
- **pack**: which regional pack bundles it. Packs are store products whose
  grants select animals by field (`{"type": "animals", "where": {"pack": "amazon"}}`),
  so a new animal joins its pack automatically.
- **ability.modules**: any of the modules below, combined freely.
- **look**: drawn procedurally. `base`: mammal, bird, frog, snake, lizard,
  glider. Parts: `head` (round, cat, ape, long, fox, bear, otter, civet,
  elephant, blocky, pointy), `ears` (none, small, round, round_big,
  round_tipped, big, tall, pointed, tufted, huge, elephant), `snout` (short,
  broad, cat, ape, long, fox, bear, otter, trunk, tapir, proboscis, bill,
  beak_long, mandrill, coati), `tail`, `eyes` (big, huge), `pattern` (spots,
  rosettes, stripes, clouds, scales, spines, …), `extras` (beard, brow,
  cheek_pads, crest, casque, wattle, plumes, whiskers, shaggy, long_arms, …).
  Birds also take `beak` and `tail`. Or set `"sprite": "res://…png"` to draw a
  picture instead.

### Ability modules (`scripts/abilities/`)

| Module | Button | Parameters |
|---|---|---|
| hop | no | baseline (uses `stats`) |
| multi_hop | yes | tiles, cooldown, style ("charge") |
| glide | yes | tiles, cooldown, soft_landing (s), style |
| dash | yes | tiles, cooldown, invincible (s), style ("roll") |
| hover | yes | duration, cooldown |
| vine_swing | yes | max_rows, target ("safe" / "non_water"), swings, cooldown |
| climb | yes | duration, cooldown (ground traffic passes underneath) |
| invincible | yes | duration, cooldown, rooted, style ("curl" / "cloak") |
| shield | active/passive | mode, charges, cooldown |
| smash | yes | cooldown (clears a mover or brush ahead) |
| scare | yes | targets ("predators" / "any"), radius, count, duration, push, cooldown |
| swim | no | current, max_streak, idle_limit, water_hop_time |
| anchor | no | knockback (bool), drift (0..1) |
| predator_ward | no | charges, recharge |
| magnet | no | radius |
| forager | no | sees hidden bonus truffles |
| reveal | no | strength (night vision, thins mist) |
| plow | no | walks through brush |

A brand-new mechanic is the only thing that needs code: add
`scripts/abilities/<module>.gd` extending `Ability` and override the hooks
(`has_button`, `_activate`, `absorb`, `immune`, `swim`, `drift`, …).

## A new region: `content/maps/<id>.json`

Copy an existing map and change:

- `id`, `name`, `location`, `lat`, `lon` (pin on the globe), `order`
- `status`: `available` or `coming_soon`
- `access`: `{"type": "free"}` or `{"type": "pack", "product": "map_<id>"}`
  (add the product to `content/store/catalog.json`)
- `flag` (pennant colours + 3-letter code), `palette` (lane, water, canopy
  and UI colours), `atmosphere` (`mist`, `light_shafts`, `rain`, `fog_color`)
- `music`: `file` plus synth settings (`tempo`, `root`, `scale`, `lead`,
  `drums`, `drone`). Run `python3 tools/gen_audio.py --maps`, or point
  `file` at a recorded track.
- `facts` (shown on the intro card), `intro_hazards`, `native_animals`
- `generator`: `classic`, `highlands` or `wetlands` (or your own file)
- `hazards`: slot name → weighted hazard ids. Slots the generators use:
  `ground_movers`, `platforms`, `tidal_platforms`, `bridges`, `ridges`,
  `water_predators`, `safe_specials`, `tiles`, `ground_effects`,
  `safe_effects`, `swoopers`, `events`
- `difficulty`: `speed`, `density`, `band` (lanes per band, easy → hard),
  `safe_chance`, `special_chance`, `rows_to_max`, `move_timer` (seconds, 0 = off)
- `stages`: the scene's 10 levels, `{name, rows, difficulty: [from, to],
  canopy: {zones, rows: [min, max]}}`. `canopy` places that many
  dense-canopy zones (each `rows` long) through the level: the lanes under
  them play as usual, but the bird's-eye view sees only leaves, so the
  player switches to first person to cross them. The shipped levels use 1
  zone (levels 1-3), 2 (4-6) and 3 (7-10).
- `fpv_scenes`: what each canopy zone looks like in first person (3 or
  more; the shipped regions have 4). Zones in one level get different
  scenes, and each level starts further along the list, so all of a region's
  scenes come round. Each scene:
  ```json
  {"id": "kapok_cathedral", "name": "Kapok Cathedral",
   "line": "Kapok trees rise 60 m above the forest floor on great buttress roots.",
   "props": {"giant_tree": 1.2, "fern": 1, "bromeliad": 0.8, "liana": 0.7},
   "landmark": "giant_ceiba", "fauna": ["scarlet_macaw", "morpho"],
   "particles": ["motes"], "shafts": 0.8, "colors": {"light": "#ffe9a8"}}
  ```
  `name` and `line` show on the title card as you enter ("Canopy 1 of 3")
  and on the bird's-eye sign. `props` weights the plants along both sides
  (`liana` is the chance of a vine over the path per row): `giant_tree`,
  `strangler_fig`, `banyan`, `palm`, `walking_palm`, `fan_palm`, `ravenala`,
  `tree_fern`, `bamboo`, `mangrove`, `pneumatophores`, `araucaria`,
  `elfin_tree`, `nipa`, `bromeliad`, `heliconia`, `pitcher_plant`,
  `rafflesia`, `orchid`, `fern`, `moss_rock`, `mushroom`, `giant_lily`,
  `karst`. The main prop also picks what hangs over the path (bamboo arches,
  fig roots, mossy limbs, fronds, mangrove roots, cave rock); set
  `"overhead"` to choose (`bamboo_arch`, `aerial_roots`, `branches`,
  `moss_branches`, `fronds`, `palm_fronds`, `mangrove`, `rock`).
  `landmark` (on the zone's middle row): `ruin_temple`, `stela`, `waterfall`,
  `canopy_walkway`, `hanging_bridge`, `cave_arch`, `clay_cliff`, `cenote`,
  `giant_ceiba`, `karst_tower`. `fauna`: `scarlet_macaw`, `macaw`, `parrot`,
  `hornbill`, `egret`, `bird_of_paradise`, `hummingbird`, `toucan`, `morpho`,
  `swallowtail`, `birdwing`, `glasswing`, `owl_butterfly`, `bats`.
  `particles`: `fireflies`, `rain`, `leaves`, `motes`, `mist`, `spray`.
  `shafts` (0-1): light beams and how bright it is under the leaves.
  `colors` may set `leaf`, `bark`, `flower`, `light`, `fog`.
  Check a new scene's look with `tools/fpv_check.tscn` (see RUN.md).
- `endless.creep`: how fast the jungle closes in (rows/s, easy → hard)
- optional `dlc`: `{"url": "https://…/pack.zip"}` to download the pack's
  files on unlock (zip paths like `content/maps/x.json`, unpacked into `user://`)

## A new hazard: `content/hazards/<id>.json`

`kind` picks the behaviour; everything else is data:

| kind | lane | key fields |
|---|---|---|
| mover | ground | length, speed, gap, group, spacing, motion ("pendulum": amplitude, period, count) |
| platform | water | length, speed, gap, group, dive {chance, period, warn, under}, motion ("tidal", "pendulum", "static"), holes, fast_water |
| surfacer | water | period, warn, up, span (crocs) |
| striker | safe | period, warn, strike, span, hidden (snakes, ambushers) |
| swooper | safe | period, warn, swoop, rows (raptors sweep a column) |
| faller | safe | period, warn, impact (branches, fruit) |
| quicksand / gap / brush | safe | tiles: sink time / fall / blocks movement |
| tide / fire / mudslide | lane effect | period, warn, flood / burn |
| gust / downpour | map event | period, warn, duration, boost |

`art.painter` picks a drawing (truck, jeep, tractor, cart, scooter, herd,
ants, soldier_ant, roll_log, elephant, runner, vine, boulder, lizard, log, lilypad,
caiman_back, branch, boat, bridge, stones, croc, snake, tiger, raptor,
branch_fall, fruit_fall, quicksand, gully, roots, bush, fire, tide, mud) and
`art.colors` recolours it (`soldier_ant` also takes `cheese` and `rind`);
or set `"sprite"`. In first person, logs, rolling logs, caimans, crocodile
jaws and soldier ants use detailed models (`scripts/view/models_3d.gd`)
coloured from the same `art.colors`; check them with
`tools/model_sheet.tscn` (see RUN.md). `predator: true` makes
camouflage, stealth, toxins and intimidation apply. `cause_text` is what the
results card says.

## Game rules: `content/rules.json`

- `water_restarts_run` (default `true`): falling into the water (open water,
  a platform that dives, slipping off, a flooding tide) starts the run over
  from the beginning of the same stage. No life is used and there's no
  revive offer; Berries collected so far are kept and the run is recorded.
  Other hazards (traffic, predators, quicksand, gullies, being carried
  off-screen) still cost a life. Set it to `false` for the old behaviour.
- `restart_delay`: seconds of splash before the restart (default 1.2).
- `endless_canopy`: canopy zones in Endless and the Daily Challenge:
  `{"first": 18, "every": [26, 40], "rows": [5, 9]}`.
- `levels_per_scene`: 10 (documentation; each map's `stages` list is what counts).

## Skill levels: `content/skills.json`

Every animal's signature ability levels up from 1 to `max_level` (5) with
Berries (`cost`: Berries to reach each level). Runs use the animal's level.
`rules` says how each ability-module parameter changes per level; a module
parameter with no rule never changes. Rule fields:

- `mul`: fraction added per level after the first (`-0.08` = 8% shorter a
  level), with an optional `min` factor so it never goes below that.
- `add_at`: `{"4": 1}` adds 1 from level 4 on (whole-number parameters stay
  whole). `add_per`: added every level after the first, up to `max`.
- `skip_above`: leave the parameter alone when it's already above this
  (e.g. charges of 99 mean "unlimited").
- `label` and `unit`: what the animal screen shows ("Cooldown 2.8 s -> 2.6 s").

An animal whose ability has nothing to scale gets `"hop_scale": 1.0` on its
first module, which the `hop_scale` rule shortens a little each level
(quicker hops).

## Store, live ops, seasons, onboarding

- `content/store/catalog.json`: real-money `products` (type, price_usd,
  store ids, `grants`), Berry/Amber `consumables`, `cosmetics`, `exchange`.
  Grant types: flag, amber, berries, animal, animals (by filter), map, maps,
  pass_premium, item, cosmetic.
- `content/store/live_ops.json`: daily deal pool, weekend multiplier, animal
  of the week rules, seasons (dates, featured region, pass file).
- `content/store/daily_rewards.json`: the 7-day cycle.
- `content/season/<pass>.json`: 30 tiers, XP rules, free/premium rewards.
- `content/onboarding.json`: tutorial lanes and steps, store prompt texts
  and cooldowns, nudges.
