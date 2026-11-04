# Canopy Crossing

A mobile-first arcade crosser (Godot 4.7, portrait). Guide a real jungle
animal across rivers, logging trails, swamps and ant highways, one hop at a
time, in ten real rainforests. Built from
[`prompts/claude/canopy-crossing.md`](../../prompts/claude/canopy-crossing.md).

- **50 animals**, each with a signature ability (18 reusable ability modules).
  5 free starters: Poison Dart Frog, Western Gorilla, Orangutan, Southern
  Cassowary, Ring-Tailed Lemur.
- **200 maps: 20 real rainforest scenes x 10 levels.** Amazon is free;
  Congo, Borneo, Daintree, Masoala, Monteverde, Sundarbans, Western Ghats,
  Bwindi, New Guinea, Atlantic Forest, Xishuangbanna, Taman Negara,
  Sinharaja, Yasuní, Chocó, Taï Forest, Palawan, Maya Forest and Khao Sok
  are map packs, plus 2 "coming soon". Each scene has its own palette,
  hazards, music and facts. Levels grow from 40 to 130 rows. A spinning
  globe picks the scene.
- **Two views:** bird's-eye (top-down) and first person (3D, through your
  animal's eyes). Switch any time with the eye button (or V). Every level
  has dense-canopy stretches that hide the ground from above, so you need
  first person to see the traffic, logs and predators under the leaves.
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
FAST=1 tools/run_tests.sh   # levels 1 and 10 of each scene instead of all 200
```

The phase audit (`tests/phase_audit.gd`, 309 checks) turns each phase's
checkpoint from the brief into checks: grid hops, every hazard kind, every
ability, all 50 animals, every region generating 200 rows, a path-finding bot
beating **all 200 levels with the free Poison Dart Frog**, adding a map
and an animal by file, earning/unlocking/relaunching, sandbox purchases and
restore, a downloadable content pack, the tutorial funnel, prompts, daily
reward, deals, the pass, ads only between runs, analytics events, and the
frame cost.

## Layout

```
content/      animals/ maps/ hazards/ generators/ store/ season/ world/ + onboarding, rarities, collectibles
autoload/     Content, Save, Analytics, Economy, Progress, Store, Ads, Sfx, Game
scripts/sim/  World, Lane, Ent, LaneGenerator, RunSim, PathBot (pure logic, no nodes)
scripts/abilities/  one file per ability module
scripts/view/ painters (animals, hazards), world view, player, fx, atmosphere
scripts/ui/   screens and widgets
scripts/platform/  billing backends (sandbox, Google Play, App Store), AdMob adapter
tools/        run_tests.sh, capture.sh, gen_audio.py, gen_globe.py, web_artifact/
docs/         CONTENT.md, STORE.md
```
