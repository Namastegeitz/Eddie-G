# Canopy Crossing

A mobile-first arcade crosser (Godot 4.7, portrait). Guide a real jungle
animal across rivers, logging trails, swamps and ant highways, one hop at a
time, in ten real rainforests. Built from
[`prompts/claude/canopy-crossing.md`](../../prompts/claude/canopy-crossing.md).

- **50 animals**, each with a signature ability (18 reusable ability modules).
  5 free starters: Poison Dart Frog, Western Gorilla, Orangutan, Southern
  Cassowary, Ring-Tailed Lemur.
- **220 maps: 22 real rainforest scenes x 10 levels.** Amazon is free;
  Congo, Borneo, Daintree, Masoala, Monteverde, Sundarbans, Western Ghats,
  Bwindi, New Guinea, Atlantic Forest, Xishuangbanna, Taman Negara,
  Sinharaja, Yasuní, Chocó, Taï Forest, Palawan, Maya Forest, Khao Sok,
  the Cardamom Mountains and El Yunque follow round the globe. Each scene
  has its own palette, hazards, music and facts. A spinning globe picks
  the scene.
- **Jungles open as you play:** clear a jungle's last level and the next
  one on the globe opens for free ("New jungle open!" on the results card;
  the world map says what opens each one). Map packs in the store still
  open a jungle early and bring its native animals.
- **New terrain and creatures along the trail:** waterfall ledges (a river
  pours over the rock; hop across on the dry, mossy stones), mossy boulders
  to find a way round, and harmless wildlife on the banks of every jungle
  (coquí frogs, hermit crabs, butterflies, birds, lizards, beetles), in
  both views. El Yunque brings marching land crabs, mongooses, tour jeeps,
  Puerto Rican boas and red-tailed hawks; the Cardamom Mountains bring Asian
  elephants, dhole packs, smugglers' rosewood trucks, Siamese crocodiles
  and king cobras, each with four first-person scenes (La Mina Falls,
  Tatai Falls, Gibbon Gorge...).
- **Difficulty curve:** every jungle's levels get longer and harder from
  1 to 10 (a 1-5 challenge rating on each). The first two jungles are
  **Easy** (short, slow levels of 25 to 60 rows, small bands with a safe
  bank after nearly every one, 5 lives), the next three **Medium**,
  jungles 6-10 **Hard** and the rest **Expert** (60 to 130 rows, fast and
  crowded). The first five jungles bring their hazards in one or two at a
  time ("New here: caiman backs"), so early levels go quickly. Tuned in
  `content/difficulty.json`.
- **Two views:** bird's-eye (top-down) and first person (3D, through your
  animal's eyes; a wide view that sees more to the left and right, above
  and further ahead, fitted to the screen's shape: about 93° x 124° on a
  phone, 112° x 80° on a wide screen. Settings > First-person view: Wide,
  Extra wide or Classic). Switch any time with the eye button (or V). Every level
  has 1 to 3 dense-canopy stretches (1 in levels 1-3, 2 in 4-6, 3 in 7-10)
  that hide the ground from above, so you need first person to see the
  traffic, logs and predators under the leaves.
- **80 first-person scenes**, 4 per rainforest, each themed on the real
  place: Kapok Cathedral and Flooded Várzea in the Amazon, Dipterocarp
  Spires and Pitcher Plant Bog in Borneo, Temple in the Trees at the Maya
  Forest, the Underground River cave in Palawan, Bamboo Brake in the Western
  Ghats, Cloud Bridges in Monteverde, and so on. Each has its own trees and
  plants, what hangs over the path (bamboo arches, fig roots, mossy limbs,
  fronds, mangrove roots, cave rock), a landmark (temples, waterfalls,
  canopy walkways, cave arches, karst towers), birds or butterflies,
  fireflies, rain or mist, light and fog. A title card names each scene
  with a real fact as you enter it ("Canopy 2 of 3").
- **Graphics:** inked outlines, soft shading and glossy eyes on every
  animal (fur strokes, feathers, real rosettes up close), outlined hazards
  with headlights, eyes and wood grain, turf and soil grain on every lane,
  shader water that ripples and glints with the current, and a textured,
  anti-aliased 3D first-person view with shadows. Settings > Graphics:
  Auto / High / Medium / Low (Auto: High on desktop, Medium on phones and
  the web player).
- **World map:** a digital globe built from Natural Earth coastlines: LED
  dots light up the land, coasts glow, country borders and a lat/long grid
  show faintly, a scan sweeps round, and region beacons pulse (gold with
  the region's flag when owned, a padlock when locked). Picking a region
  flies an arc to it and shows a tag with its coordinates; drag to spin.
- **Detailed creatures and logs in first person:** logs with bark grooves,
  knots, broken branch stubs, moss and ringed ends (rolling logs turn);
  caimans with armour scutes, raised eyes and nostrils; crocodile jaws full
  of teeth; and **giant red soldier ants hauling wedges of cheese** on the
  Amazon and Yasuní ant highways, legs walking in a tripod gait.
- **Skill levels:** every animal's ability upgrades from Lv 1 to Lv 5 with
  Berries on the animal screen (shorter cooldowns, longer effects, more
  distance or charges, quicker hops), shown as pips with what the next
  level adds. Rules in `content/skills.json`.
- **Smooth runs:** the game steps at a fixed 60 Hz but draws hops, logs and
  traffic between steps, so motion stays smooth on 90/120 Hz screens and
  when a frame runs late. First person pre-builds what's coming (canopy
  rows, landmark rows and the logs, ants and caimans about to come into
  view) a little each frame and reuses them, so hopping forward doesn't
  stall.
- **Detailed 3D models (made with Meshy):** in first person, the creatures
  are detailed, textured models: giant red soldier ants with their cheese,
  land crabs, crocodiles and floating caiman backs, elephants, wild pigs,
  wild dogs, gaur, coiled vipers and cobras, harpy eagles, cassowaries,
  monitor lizards and tigers (one model per kind, tinted per species), with
  a stride bounce as they walk. The scenery is too: giant buttressed trees,
  strangler figs, palms, tree ferns, bamboo, heliconias, ferns, bromeliads,
  monsteras and mossy rocks line the trail, with model logs, lily pads,
  stepping stones and landmarks (temple ruins, stelae, waterfall cliffs,
  karst towers). The free starter animals turn and breathe in 3D on the home
  and animal screens. Graphics Low keeps the light built shapes.
  Pipeline and credit budgets: `tools/meshy/`.
- **Trade roads:** the roads are working trade routes: wheel ruts worn
  into the dirt with a grassy hump between, gravel shoulders, potholes;
  crates of fruit, coffee and cacao sacks, barrels, banana bunches, market
  stalls and signposts ("PORT 3 km") wait on the banks beside them, and
  jeeps and logging trucks drive facing the way they go.
- **Giraffes, kangaroos, macaws and bees:** kangaroo mobs bound down the
  roads of Daintree and New Guinea (from level 2-3), and giraffes amble
  along those of the Congo, Taï and Bwindi (from level 2-3), swinging their
  long necks; both are new hazards in both views. Flocks of scarlet and
  blue-and-gold macaws fly over the open rows, and honeybees work the
  fruit at roadside market stalls (High graphics). The giraffe, bee, macaws and
  hibiscus are built in the game with moving joints (`scripts/view/critters_3d.gd`);
  the kangaroo is a Meshy model with a fur coat.
- **Film: "The Bee and the Giraffe"** (home screen > Watch): a half-minute
  short on a trade road. Macaws fly over a honeybee working a hibiscus; the
  camera zooms into the bee as time slows 12x; it rides along as the bee
  climbs and zips past a giraffe's eye; the annoyed giraffe hammers its
  neck down at a kangaroo, which leaps clear by a whisker in slow motion,
  then bounds off down the road with its mob (Skip button). Rendered to a
  video with `tools/render_film.sh` (Godot's movie writer + ffmpeg).
- **More lifelike first person:** a real sky with a hazy horizon that
  closes in under the canopy, film-like tone mapping, soft bloom on High,
  fine bumps on soil, turf and water that catch the light.
- **Jumps follow the ground:** a real leap onto a log, lily pad or
  waterfall stone, a quick low skip across a road; in first person the eye
  rides on top of what you stand on (up on a log's back, low on a lily pad
  or swimming), landings dip the view a little, and each surface sounds
  different (a hollow thunk on a log, a click on stone). Hop timing is the
  same everywhere, so difficulty doesn't change.
- **Live mini-map:** in the corner of every run, in both views: a zoomed-in
  map of the rows around you with lanes, logs, traffic and creatures moving
  in real time, canopy patches, waterfall ledges and the goal, and a gauge
  for the whole level (where you are, the canopy zones, the part shown).
  Tap it to make it bigger. Settings > Mini-map turns it off.
- **Calm music tuned to 528 Hz and 963 Hz:** every jungle and the menu
  has a slow, soothing song (about a minute, looping seamlessly): soft
  pads, a sparse melody on the jungle's own instrument, a gentle kalimba
  arpeggio and light percussion. Each is tuned to 528 Hz or 963 Hz
  (alternating along the globe): every note is a pure ratio of that tone,
  and the tone itself hums softly underneath. `tools/gen_audio.py --check`
  decodes each song and checks its pitches. Settings > Music style >
  Classic brings back the original livelier songs.
- **Feel:** hops along a moving log keep pace with it, landing just short
  of a log's end still lands on it, vehicles' hit edges are a touch
  forgiving, and a mover brushing past is a **Close call!** (+2).
- **Water rule:** fall into the water and the run starts over from the
  beginning (no lives, no revive). Other hazards cost a life. Switch it in
  `content/rules.json`.
- **Modes:** Journey (fixed stages, rising difficulty), Endless (procedural,
  the jungle creeps up behind you), Daily Challenge (same seed for everyone,
  rotates through regions, even locked ones).
- **Economy:** Berries (earned) and Amber (premium). Store with map packs,
  regional animal packs, Amber packs, Starter/Mega bundles, Remove Ads,
  power-ups, cosmetics (skins, hop trails, emotes, goal flags) and the
  30-tier Expedition Pass. Daily deals, weekend 2x Berries, animal of the
  week, seasons themed on a region.
- **Onboarding:** coached tutorial, region intro cards, contextual store
  prompts (revive, milestone, last life, locked animal), daily reward.
- **Accessibility:** colour-blind hazard markers, left/right-hand toggle,
  haptics on/off, reduce motion, instant restart (R / Restart).

**Everything is content files.** Animals, maps, hazards, lane generators, the
store catalog, live ops, seasons and onboarding text live under `content/`.
A new animal or region is a new JSON file. See [docs/CONTENT.md](docs/CONTENT.md).

## Run it

See [RUN.md](RUN.md): open in Godot 4.7.2, press F5. Controls: tap to hop
forward, swipe to hop any direction, the round button uses the ability, the
eye button switches view. Keyboard: arrows/WASD, Space (ability), V (view),
Q/E (power-ups), R (restart), Esc.

## Tests

```bash
tools/run_tests.sh          # compile check + phase audit (project and exported pack)
FAST=1 tools/run_tests.sh   # levels 1 and 10 of each scene instead of all 220
```

The phase audit (`tests/phase_audit.gd`, 393 checks) turns each phase's
checkpoint from the brief into checks: grid hops, every hazard kind, every
ability, all 50 animals, every region generating 200 rows, a path-finding bot
beating **all 220 levels with the free Poison Dart Frog**, adding a map
and an animal by file, earning/unlocking/relaunching, sandbox purchases and
restore, a downloadable content pack, the tutorial funnel, prompts, daily
reward, deals, the pass, ads only between runs, analytics events, and the
frame cost.

First person is checked on every run: the audit taps the eye button the
way a real finger does, `tools/fpv_check.tscn` renders every scene with
the real renderer and fails on a blank frame, and `tools/build_web.sh`
tap-tests each web build in a phone-sized browser.

## Layout

```
content/      animals/ maps/ hazards/ generators/ store/ season/ world/ + onboarding, rarities, collectibles
autoload/     Content, Save, Analytics, Economy, Progress, Store, Ads, Sfx, Game
scripts/sim/  World, Lane, Ent, LaneGenerator, RunSim, PathBot (pure logic, no nodes)
scripts/abilities/  one file per ability module
scripts/view/ painters (animals, hazards), world view, player, fx, atmosphere
scripts/ui/   screens and widgets
scripts/platform/  billing backends (sandbox, Google Play, App Store), AdMob adapter
tools/        run_tests.sh, capture.sh, gen_audio.py, gen_globe_map.py, fpv_check, build_web.sh, render_film.sh, web_artifact/, meshy/
docs/         CONTENT.md, STORE.md
```
