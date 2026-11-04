# Canopy Crossing

A mobile-first arcade crosser (Godot 4.7, portrait). Guide a real jungle
animal across rivers, logging trails, swamps and ant highways, one hop at a
time, in ten real rainforests. Built from
[`prompts/claude/canopy-crossing.md`](../../prompts/claude/canopy-crossing.md).

- **50 animals**, each with a signature ability (18 reusable ability modules).
  5 free starters: Poison Dart Frog, Western Gorilla, Orangutan, Southern
  Cassowary, Ring-Tailed Lemur.
- **10 real regions** (Amazon free; Congo, Borneo, Daintree, Masoala,
  Monteverde, Sundarbans, Western Ghats, Bwindi, New Guinea as map packs)
  plus 2 "coming soon". Each has its own palette, hazards, music, facts and
  3 Journey stages. A spinning globe picks the region.
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
forward, swipe to hop any direction, the round button uses the ability.
Keyboard: arrows/WASD, Space (ability), Q/E (power-ups), R (restart), Esc.

## Tests

```bash
tools/run_tests.sh          # compile check + phase audit (project and exported pack)
FAST=1 tools/run_tests.sh   # one Journey stage per region instead of all 30
```

The phase audit (`tests/phase_audit.gd`, 250 checks) turns each phase's
checkpoint from the brief into checks: grid hops, every hazard kind, every
ability, all 50 animals, every region generating 200 rows, a path-finding bot
beating **all 30 Journey stages with the free Poison Dart Frog**, adding a map
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
