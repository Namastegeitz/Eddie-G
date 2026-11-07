# Data schemas

All game content below is data. Shipped files live in `content/`; drop-in
packs go in `content/packs/` (shipped) or `user://packs/` (one device).
JSON has no colours: write them as `"#rrggbb"` or `"#rrggbbaa"`. Whole
numbers come back as integers. Run `godot --headless --path .
res://tools/content_report.tscn` to validate everything (exit code 1 on
problems); a bad entry is skipped with a message, never a crash.

## Effects (shared by everything)

Pilots, craft, mods, set bonuses, global perks and Wonder tiers carry an
`effects` object. Values add up across sources, then clamp. Defined in
`scripts/data/effects.gd` (`KEYS`): the only list to edit to add a key.

| Key | Kind | Range | Meaning |
|---|---|---|---|
| `top_speed_pct` | % | -30..15 | Top speed |
| `accel_pct` | % | -30..25 | Acceleration |
| `handling_pct` | % | -30..25 | Steering rate and grip |
| `drain_pct` | % | -60..100 | Dark Matter drain |
| `regen` | add | 0..1.2 | Core refill per second |
| `boost_energy` | add | 0..5 | Core refill per second while boosting |
| `drift_charge_pct` | % | -50..80 | Drift charge speed |
| `drift_boost_pct` | % | -50..80 | Drift boost length |
| `boost_time_pct` | % | -50..60 | Every boost's length |
| `trick_pct` | % | 0..150 | Trick boost and energy |
| `slip_charge_pct` / `slip_range_pct` | % | 0..150 | Slipstream charge speed / reach |
| `pod_pct` / `pod_magnet_pct` | % | 0..100 / 0..300 | Pod energy / pickup range |
| `near_energy_pct` | % | 0..300 | Near-miss energy |
| `spin_time_pct` | % | -60..50 | Spin-out length |
| `wall_keep_pct` | % | 0..80 | Share of wall-hit speed loss avoided |
| `weight_add` | add | -3..6 | Weight (bumps) |
| `bump_pct` | % | 0..100 | Bump shove |
| `low_grip_pct` | % | 0..60 | Grip on slippery surfaces |
| `rough_pct` | % | -100..0 | Slowdown on dust, moss and lava |
| `glide_sink_pct` | % | -50..0 | Glide sink rate |
| `shield_time_pct` | % | 0..80 | Ion Shield length |
| `crate_luck` | add | 0..3 | Crates roll as if N places back |
| `start_item` | item id | | Start each race holding this item |
| `stardust_pct` | % | 0..100 | Stardust from drifts |
| `wonder_charge_pct` / `wonder_power_pct` | % | -50..100 | Wonder charge speed / strength |
| `heat_pct` | % | -60..100 | Overclock heat |

## Craft (`saucers` in a pack; `Catalog.SAUCERS`)

```json
{"id": "comet_skiff", "name": "Comet Skiff", "blurb": "...",
 "speed": 6, "accel": 7, "handling": 6, "efficiency": 5, "weight": 3,
 "price": 3200, "stars": 12, "shape": "manta", "paint": "#bfe9ff",
 "effects": {"drift_charge_pct": 10},
 "premium": false, "perk_text": "optional line for the Hangar", "product": "optional store id"}
```
- Stats are 1..10 (clamped). `price` is in Race Credits; `stars` must be earned before buying.
- `shape` must be one of the 14 built-in hulls: classic, bubble, rocket, ring, orb, manta, crystal, bioship, mothership, arrow, sail, phantom, dragon, dyson.

## Pilots (`pilots`; `Catalog.PILOTS`)

```json
{"id": "glimmer", "name": "Glimmer Wisp", "color": "#9ef7ff", "eyes": 3, "kind": "creature",
 "effects": {"near_energy_pct": 80},
 "passive_name": "Will-o'-the-Wisp", "passive_text": "...",
 "style": "clean", "unlock": "credits", "price": 700, "stars": 0, "home": "trappist1h",
 "blurb": "...", "look": {...}}
```
- `style`: `clean`, `aggressive` or `hoarder` (how the AI drives them).
- `unlock`: `start` (everyone has them), `credits` (bought, `price`) or `boss` (beat them on `home`, needs `stars`).
- `eyes`: 1..4. `kind: "creature"` styles their card.
- `look` (optional; without it the pilot uses the built-in look of the same id or Zib's): `head` (`round`, `egg`, `drop`, `wide`, `box`, `dog`, `gem`, `mantle`, `bell`, `insect`), `iris`, `suit`, `trim`, `acc` (one of the built-in accessory sets: antennae, goggles, bubbles, captain, crest, robot, scarf, ears, horns, moth, crystals, tentacles, jelly, hood, troll, hive), and optional `sclera`, `iris_glow`, `eye_scale`, `skin_glow`, `lump`, `fangs`, `brows`, `lashes`, `blush`, `spots`, `spot_color`, `spot_glow`, `slime`, `robot`.

## Wonders (`content/wonders.json`, or `wonders` in a pack)

```json
{"overclock": {"levels": [{"pct": 100, "name": "Stock", "power": 1.0, "heat": 0.0}, ...],
               "heat_decay": 3.0, "burnout_time": 5.0, "burnout_speed": 0.88,
               "burnout_slow_time": 2.5, "cool_to": 35},
 "wonders": [{"id": "photon_spinnaker", "craft": "sail", "name": "...", "tagline": "...", "text": "...",
   "mechanic": "spinnaker", "color": "#ffe08a", "heat_per_use": 22, "heat_per_second": 0,
   "tiers": [{"name": "Prototype", "cost": 250, "text": "...", "params": {...}, "effects": {}}, x3],
   "global_perk": {"id": "solar_wind", "name": "Solar Wind", "text": "...", "effects": {...}}}]}
```
- One Wonder per craft id; exactly 3 tiers. A tier's `params` override the previous tier's, so later tiers list only changes. Tier `effects` apply while flying that craft; the `global_perk` applies to every craft once the track is Transcendent.
- Overclock: `power` multiplies the Wonder's strength; `heat` multiplies `heat_per_use` (and `heat_per_second` while active). At 100 heat the Wonder burns out for `burnout_time` seconds and top speed drops to `burnout_speed` for `burnout_slow_time`.
- `mechanic` and its params:

| Mechanic | Params |
|---|---|
| `spinnaker` (charge by drifting, faster tacking into the stellar wind; fire = slingshot) | `charge_drift`, `charge_tack` (per s), `tack_turn` (extra turn at full tack), `min_charge`, `burst_time`, `burst_speed`, `impulse` |
| `lighthouse` (charge over time; fire = magnetar pulse, then phase on the music's beat) | `charge_rate`, `beats` (beats per blink), `blink` (s), `active_time`, `pulse_radius`, `pulse_push`, `pulse_slow`, `min_charge` |
| `jet` (charge by drifting and flat-out speed; fire = straight-line burst) | `charge_drift`, `charge_speed`, `min_charge`, `jet_time`, `jet_speed`, `jet_accel`, `jet_steer`, `impulse` |
| `harvest` (clean drifts feed the swarm; fire = overdrive) | `per_clean_second`, `min_drift`, `min_charge`, `overdrive_time`, `overdrive_speed`, `overdrive_accel`, `energy` |

## Super Upgrades (`content/upgrades.json`, or `sets`/`mods` in a pack)

```json
{"stardust": {"min_drift_time": 1.0, "per_second": 3.0, "per_meter": 0.025,
              "tier_bonus": [1.0, 1.2, 1.45, 1.75], "finish_bonus": [30, 20, 14, 10, 8, 6, 5, 4]},
 "slots": [{"id": "core", "name": "Core", "text": "..."}, {"id": "field", ...}, {"id": "drive", ...}],
 "sets": [{"id": "helios", "name": "Helios", "color": "#ffc94d", "bonus_name": "Solar Flow", "bonus_text": "...", "effects": {...}}],
 "mods": [{"id": "fusion_heart", "slot": "core", "set": "helios", "name": "Fusion Heart", "cost": 180, "effects": {...}}]}
```
- Stardust per clean drift = (`per_second` x seconds + `per_meter` x metres) x `tier_bonus[drift tier]` x `stardust_pct`. A drift is clean with no wall hit, spin-out or long jump during it. `finish_bonus[place-1]` is added after each race (not in Time Trial).
- A mod is bought once and fits any craft, one per slot. Three mods of one `set` on a craft add the set's `effects`. `set: ""` means no set.

## Biomes (`content/biomes.json`, or `biomes` in a pack)

```json
{"biome_defaults": {"io": "eerie", "cancri_e": "divine"},
 "biomes": [{"id": "eerie", "name": "...", "text": "...",
   "palette": {"rock", "rock_hi", "ash", "lava", "lava_hot", "crack_width", "crack_glow",
               "ash_amount", "iridescence", "gloss", "ground", "ground_glow"},
   "env": {"fog_color", "fog_density", "sun_tint", "sun_mix", "ambient_tint", "ambient_mix"},
   "lava": {"rivers", "width": [min, max], "glow", "crust", "speed"},
   "smoke": {"color", "alpha", "height": [min, max]},
   "mist": {"color", "alpha", "layers"},
   "formations": [{"id": "ridge", "kind": "ridge", "ring": "far", "count": 9,
                   "scale": [220, 420], "height": [180, 420],
                   "mesh": "res://assets/biomes/eerie/ridge.glb", "material": "biome",
                   "prompt": "...Meshy prompt...", "polycount": 6000,
                   "crater_glow": false, "smoke": false,
                   "recipe": {"type": "ridge", "peaks": 7, "jag": 0.6, "sharp": 1.4, "seed": 11}}]}]}
```
- 3 or 4 formation variants per biome. `ring`: `far` (horizon), `mid` or `near` (beside the road). `scale` is the footprint radius and `height` the height above the ground plane, both in metres.
- `mesh` is the import slot: when a GLB is there it replaces the `recipe`. `material: "biome"` paints it with the palette; `"asset"` keeps the GLB's own materials.
- Recipe types: `ridge` (`peaks`, `jag`, `sharp`), `cone` (`ribs`, `crater`, `rough`), `columns` (`count`), `crystals` (`count`), `shard` (`lean`), `arch` (`thick`); all take `seed`.
- Which biome a track gets: Settings > Volcanic biome. `auto` uses `biome_defaults`; `eerie` or `divine` applies to every world with solid ground; `off` keeps the classic scenery.

## Save data added

```json
"wonders": {"stardust": 0, "earned": 0, "tiers": {"sail": 2}, "mods": ["fusion_heart"],
            "fit": {"sail": {"core": "fusion_heart", "field": "", "drive": ""}},
            "overclock": {"sail": 1}, "perks": ["solar_wind"]},
"last_race": {"track": "mars", "variant": 0, "class": -1},
"settings": {"biome": "auto", ...}
```
A race request's player entries carry `"kit": {"effects": {...}, "wonder": {"craft", "tier", "overclock"}}`
from `Upgrades.kit_for(craft)`, so a race never reads the save directly.
