# Bug's-Eye View: next build prompts (Claude Code)

Copy one prompt at a time into a Claude Code session on this repo. Each is
self-contained: it says where to look, what to build, and how to know it's
done. They build on the game as it is now (Godot 4.7, `apps/bugs-eye-view`).

Rules that apply to every prompt (paste them once at the top of a session, or
keep them in a `CLAUDE.md`):

```
You're working on Bug's-Eye View in apps/bugs-eye-view (Godot 4.7, GDScript).
- Content is generated from code: tools/builders/*.gd -> scenes and .tres via
  `godot --headless --path . res://tools/build_all.tscn -- --force --only=res|actors|levels`.
  Change the builders, regenerate, and commit both.
- Tunable numbers live in resources/ (.tres); gameplay code reads them.
- Every new feature gets checks in tests/phase_audit.gd (new section) and must
  keep tools/run_tests.sh green: warnings-as-errors, smoke test and phase audit
  in the project AND an exported pack.
- Keep phones in mind: under 160 visible meshes per room (merge static parts per
  material with ActorBuilder.merge_meshes), under 4 ms of logic per frame.
- Every new visible object gets a SkinAnchor model slot and a prompt in
  tools/meshy/assets.json.
- Update RUN.md / README.md for anything a player or I would need to know.
```

---

## 1. Generate the 3D models with Meshy (tier 1 first)

```
Generate the tier-1 models (bugs, threats, food, gems) with
tools/meshy/generate.py. My MESHY_API_KEY is set in this environment and
api.meshy.ai / assets.meshy.ai are allowed. Run --dry-run first and show me
the cost estimate from Meshy's current pricing page, then run --tier 1.
After download: import, render each model in its slot next to its placeholder
(xvfb + opengl3 screenshot like tools/_shot.gd did), and fix any that face the
wrong way (yaw_offset_deg) or float/sink (fit box). Report models that look
wrong so I can rewrite their prompts. Keep the web build under 60 MB.
```

## 2. Gem Shrine: spend gems on permanent powers

```
Crumb gems are collected and saved (SaveSystem.gems_found()) but do nothing
after the run. Add a Gem Shrine screen to the colony hub: each gem type unlocks
a permanent, small perk when you've found 3 of it (Amethyst: start levels with
5 s of Shadow Cloak; Amber: freezes last 1 s longer; Emerald: alarm drains 15%
faster; Ruby: +1 shell once per level; Diamond: magnet radius +5; Sapphire:
decoys last 3 s longer). Data-driven (resources/upgrades or a new GemPerk
resource), shown with progress bars, applied at level start. Add audit checks
for each perk.
```

## 3. A new room: the Bathroom

```
Add a fourth level, the Bathroom, unlocked by escaping the Backyard. Ideas to
build on: a slippery tub (low friction), a dripping tap whose drips are
noise cover, shower steam that hides you (light zone 0) but fogs over time,
a toothbrush cup shelter, a bath mat (quiet), a hair dryer gust hazard, a
toilet you must not fall into, a drain secret route to the Golden Crumb.
Threat: a human brushing teeth who looks in the mirror (sight cone reflected
behind them). Boss: Bath Time (the tub fills and water level rises). Follow
the existing layout builder pattern (tools/builders/*_layout.gd), add a
routine, LevelConfig, 2 gems, 4-6 foods, cover, model slots, and tests.
```

## 4. People who live in the house

```
Humans walk a route but don't *do* anything. Give each routine event a visible
activity: cooking at the stove (stands, arms move, drops crumbs you can grab),
reading in the armchair (sits: legs bend, newspaper up, vision cone narrows),
watering plants in the backyard, washing dishes (back turned, sink noise). Use
the human.gd pose system (pose_body, knee IK) for sitting and reaching. Add a
"look around" idle where the head sweeps and they can catch you mid-move.
Tests: each activity changes the pose and the sight cone as described.
```

## 5. Bug skins and evolutions

```
Let players unlock cosmetic skins per bug with colony crumbs: e.g. Cockroach
(German, Oriental, Albino), Fly (Bluebottle, Fruit fly - smaller and faster
turn), Spider (Jumping spider - fuzzy, big eyes; Daddy longlegs - very long
legs). Skins are material + proportion presets applied to the existing
jointed rigs (ActorBuilder _leg/_antenna parameters and BugRig). A preview
turntable in the bug-select screen. Some may change small stats; keep them in
BugStats so balance stays in .tres files.
```

## 6. Debug overlay for tuning stealth

```
Add a developer overlay (toggle with F3, hidden in release builds) that draws:
every threat's sight cone and hearing radius, the player's live visibility,
noise and scent values, the alarm gauge internals, light-zone levels, and pet
navmesh paths. Use ImmediateMesh/lines, one draw per frame, no per-frame
allocations. Document it in RUN.md. This is for me to tune
resources/config/stealth_config.tres while playing.
```

## 7. Playtest bot and balance report

```
Write tools/playtest_bot.tscn: a headless bot that plays each room with each
bug many times (random seeds, simple goal-seeking: go to nearest crumb, hide
when the alarm is above 50%, use food/gems when it helps) and writes a CSV:
win rate, time, times spotted, which hazard caused each death, which crumbs
and items were never reached. Then summarise the CSV into a balance report
(markdown) with the 5 changes you'd make to the .tres numbers and why. Don't
apply them; I'll decide.
```

## 8. Real sound

```
The sounds are synthesized placeholders (tools/generate_assets.py). Replace
the most-heard ones with better effects: footsteps (giant, muffled, by floor
type), the swatter whoosh, cat purr/hiss, dog sniff, vacuum, fridge hum, gem
chime, munch. If an ElevenLabs (or similar) API key is available in this
environment, generate them with its sound-effects API and keep the prompts in
tools/audio/sfx_prompts.json like the Meshy manifest; otherwise give me the
prompts to run myself. Keep file names so AudioManager needs no changes.
```

## 9. GitHub Actions: test, build and publish on every push

```
Add .github/workflows/bugs-eye-view.yml: on push and PR, install Godot 4.7.2
and export templates (cache them), run apps/bugs-eye-view/tools/run_tests.sh,
then export Web, Android debug APK, Windows and Linux, and upload them as
artifacts. On pushes to main, also deploy the web build to GitHub Pages (or
surge with a SURGE_TOKEN secret). Fail the job on any test failure.
```

## 10. Store launch kit

```
Prepare store assets: render marketing screenshots at the exact phone/tablet
sizes Google Play and the App Store require (use the xvfb + opengl3 render
approach, staged shots of each room, the gems, a boss chase), a 30-second
trailer storyboard, store description, keywords, privacy answers (no data
collected), and an age-rating questionnaire draft. Put them in
apps/bugs-eye-view/docs/store/ and update docs/STORE_EXPORT_CHECKLIST.md.
```
