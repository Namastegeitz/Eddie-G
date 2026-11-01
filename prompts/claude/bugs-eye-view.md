# BUILD: "Bug's-Eye View" — a cross-platform action-stealth survival game

<!-- v2: adds the stealth & interactivity add-ons and a sixth phase. -->

## Mission
Build a complete, playable action-stealth survival game called "Bug's-Eye View"
in Godot 4.x. The player is a tiny household bug surviving a busy human home —
dodging swatters, feet, rolled newspapers, and patrolling pets while scavenging
crumbs and reaching hiding spots. Ship it as a NATIVE APP on phone (iOS +
Android) AND on computer (Windows, macOS, Linux), from one shared codebase.

You author everything as text: project.godot, .tscn scenes, .gd scripts,
resources, and export_presets.cfg. Use Godot's CLI (headless) to validate the
project boots and to run exports. Don't wait on a human to click through the
editor — build, run `godot --headless --quit` to catch scene/script errors,
fix, repeat.

## Engine & platforms
- Engine: Godot 4.x, latest stable (4.3+). GDScript (not C#).
- Targets: Android (.aab + .apk), iOS (Xcode project / .ipa), Windows, macOS,
  Linux. Add a Web/HTML5 preset too for quick browser testing.
- One codebase, one set of gameplay scenes, platform differences handled at the
  input + UI layer only.

## Locked decisions (tell me if you'd change one, then proceed)
- 3D with LOW-POLY PRIMITIVE placeholder art (boxes, capsules, simple meshes,
  flat materials). 3D is required because the three bugs move in fundamentally
  different dimensions (air, walls/ceilings, ground). No external art needed to
  be playable — I'll swap real assets in later.
- Portrait-friendly but orientation-agnostic; design HUD for both.
- Mobile-first performance budget: keep it running smoothly on a mid-range
  phone. Low-poly, baked/simple lighting, pooled objects, no per-frame allocs.

## Project structure
    /project.godot
    /export_presets.cfg
    /scenes/        (levels, bugs, hazards, UI — .tscn)
    /scripts/       (.gd, organized by system)
    /resources/     (bug stats, level configs as .tres)
    /assets/        (placeholder meshes/materials/sfx)
    /autoload/      (singletons: GameManager, InputRouter, SaveSystem, Audio,
                     PerceptionSystem, HouseClock)
    Initialize a git repo. Commit after every phase with a clear message.

## Core architecture
- InputRouter (autoload): ONE abstraction that emits game actions
  (move_vector, jump, primary, secondary, interact, dodge, sense). Touch controls,
  keyboard/mouse, and gamepad all feed into it. Gameplay code NEVER reads raw
  input — only these actions. This is what makes cross-platform clean.
- GameManager (autoload): game states (menu, playing, paused, caught, win),
  current bug, current level, score.
- SaveSystem (autoload): persist unlocked bugs, level progress, best scores,
  settings. Use user:// so it works on every platform.
- AudioManager (autoload): sfx + music buses, master/sfx/music volume in
  settings.
- PerceptionSystem (autoload): the single source of truth for how detectable
  the player is right now (visibility, noise events, scent trail). Threats read
  the player only through this system plus their own senses. See "Stealth &
  interactivity add-ons".
- HouseClock (autoload): runs the compressed in-game day and fires each level's
  routine events. See "Living house".

## Gameplay — the three bug classes
Each is a selectable character with its own scene, stats resource, and movement
controller. Shared interface so levels/hazards treat them uniformly.

1. THE FLY — erratic high-speed flight, high agility.
   - Full 3D flight; momentum + slight drift so it feels buzzy, not precise.
   - Burst-dodge (short cooldown) for last-second swatter escapes.
   - Can't hover forever: a stamina/landing mechanic so it must perch sometimes.
2. THE SPIDER — stealth, verticality, web.
   - Wall- and ceiling-crawl: stick to surfaces, reorient to surface normal.
   - Shoot a web line to swing/zip to a point; spin a web to briefly trap/slow a
     small threat or bridge a gap.
   - Slow on open ground = vulnerable; rewards staying on walls/corners.
3. THE COCKROACH — resilience, ground speed, squeezing.
   - Fast ground sprint.
   - Squeeze into tight/dark gaps (under appliances, cracks) = temporary safety.
   - Takes a hit and survives where others wouldn't (one extra "life" / brief
     knockdown instead of instant death).

## Environment & levels
Oversized, hyper-detailed-from-a-bug-scale human home. Everyday objects are huge
obstacles/hazards. Start with a KITCHEN, then LIVING ROOM, then BACKYARD.
Each level: scavenge targets (crumbs), safe hiding spots, a reachable goal.
Scale everything so the bug feels tiny — a fork is a hazard, a table is terrain.

## Hazards & enemy AI
- Fly swatter: telegraphed descend-and-smack on a target zone.
- Human foot: patrolling/stomping, rumble cue + screen shake before impact.
- Rolled newspaper: sweeping/rolling hazard.
- Pets (cat/dog): patrolling AI with vision/hearing cones, investigate noise,
  chase, give up. Use Godot NavigationAgent for pathing.
- Build a reusable Threat base class; each hazard telegraphs clearly so deaths
  feel fair.

## Stealth & interactivity add-ons
Stealth is the heart of the game. Most threats should be avoidable by staying
unseen, unheard and unsmelled, and being spotted should ESCALATE, not instantly
kill. Every tuning value below lives in a .tres resource.

### Perception model (shared by every threat)
- PerceptionSystem combines three channels:
  - Visibility (0-1): light level x movement x camouflage.
  - Noise events: position + loudness; threats in hearing range react.
  - Scent: a decaying trail the player leaves behind.
- Every Threat has senses that read those channels: sight cone + line-of-sight
  raycast, hearing radius, and (for the dog) scent tracking.

### Core stealth systems
1. LIGHT & SHADOW: authored LightZone volumes (Area3D: shadow / dim / lit /
   bright) instead of sampling real-time lighting, so it stays cheap on phones.
   Lamps, the fridge door, curtains and sunbeams toggle or move zones at
   runtime. HUD shows an eye meter.
2. NOISE SURFACES: tag surfaces with a NoiseSurface resource. Loud: chip bag,
   foil, tile, dishes. Quiet: carpet, paper towel, cloth. Player noise = surface
   x movement (creep < walk < sprint); the fly's buzz scales with airspeed.
   Ambient noise from the routine (TV, dishwasher, vacuum) masks player noise.
   HUD shows a noise ring.
3. ALERT LEVELS + SEARCH: every Threat runs one shared state machine:
   UNAWARE -> SUSPICIOUS (?) -> SEARCHING -> ALERT (!) -> cools back down.
   Suspicion fills from perception. SEARCHING goes to the last known position
   and sweeps nearby. Breaking line of sight and hiding drops them back down.
   Icons float over threats; off-screen threats get edge-of-screen markers.
4. DISTRACTIONS & LURES: lure props emit a noise/light event where they land.
   Knock a pea or bottle cap off a counter edge, run across a phone screen to
   light it up, or have the spider web-trip a spoon so it clatters. Threats
   investigate the lure instead of you.

### Advanced stealth plays
5. FREEZE & BLEND IN: standing still for a short delay drops visibility (no
   extra button, so it works on touch). On a camo-matching surface it drops
   further: roach on dark wood or grout, spider in corners or its own web, fly
   on a dark window frame. Any movement cancels it. The cockroach can also play
   dead while a SUSPICIOUS threat is close.
6. SCENT TRAILS: the player drops pooled scent points that decay over time and
   build up when lingering. The dog follows the trail. Water spills, vinegar and
   the sink wipe it.
7. ESCALATION CHAIN: a human who spots you escalates in stages: shout (nearby
   threats go SUSPICIOUS) -> grab the swatter -> call the pet -> bug-spray area
   denial. Each stage changes which hazards are active. Staying hidden long
   enough de-escalates one stage at a time. This is the main source of rising
   intensity and drives the HUD threat indicator; keep a slow time-based floor.
8. TURN THREATS ON EACH OTHER: props and hazards can carry a `stuns_threats`
   flag. Lure the cat onto the counter so it knocks a mug onto the human's foot,
   lead a swatter strike into a hanging pan so it rebounds, or trip the human
   with a rolling grape. Stunned threats lose track of you. Award stealth score.

### Living house
9. DAILY HOUSEHOLD ROUTINE: HouseClock runs a compressed day per run (morning
   rush, afternoon nap, cleaning, lights-out). Each level has a RoutineSchedule
   .tres of timed events: which threats are active, light states, ambient noise.
   The same room plays differently by time of day; once unlocked, level select
   lets the player choose a start time.
10. PHYSICS & CHAIN REACTIONS: pushable/knockable props (crumbs, grapes, a row
    of cereal boxes, a spoon catapult) as pooled RigidBody3D with a capped
    active count, sleeping when idle. Props can block a pet's path, form ramps,
    or start a chain that lands on a threat.
11. EXTRA HAZARDS: robot vacuum (patrol + suction pull), bug-spray clouds
    (spreading, timed area denial), sticky traps (slow, then stuck), desk fan
    (wind volume that pushes the fly), sink drain (pull). All extend the
    Threat/Hazard base and telegraph clearly.
12. SECRET ROUTES: vents, wall cracks, under-sink pipes and the gap behind the
    fridge as shortcut passages. Each Passage lists which bugs can use it (roach:
    cracks and low gaps; spider: high vents and ceiling corners; fly: open vents
    and window gaps). Each level hides one route to a bonus area with a Golden
    Crumb.

### Real & fun
13. TRUE BUG SENSES, on the `sense` action, each based on the real animal:
    - Fly: compound-eye perception. When a strike is about to land nearby, time
      slows briefly for a bullet-time dodge window, limited by a recharging
      meter. (Real flies process motion far faster than humans.)
    - Spider: vibration sense. While on a surface or web, footsteps and moving
      threats show as ripples through walls and floors.
    - Cockroach: antennae smell points toward the nearest crumb. Runs faster in
      darkness and gets a scatter burst when a light switches on.
14. COLONY HOME BASE: a nest hub scene between levels. Deposit crumbs to feed
    the colony; it grows and unlocks upgrades (faster legs, longer web, quieter
    wings, longer camo) defined as UpgradeDef .tres. Saved via SaveSystem.
15. CHALLENGES & BOSS CHASES: per-level badges: Ghost (never reached ALERT),
    Speedrun (under par time), Golden Crumb (found the secret route). One boss
    chase per level: Kitchen "Cleaning Day" (robot vacuum + spray), Living Room
    "The Cat" (multi-stage hunt), Backyard "The Exterminator" (fog spreading
    room by room).
16. PHONE FEEL - HAPTICS & SOUND: Input.vibrate_handheld scaled by distance for
    footsteps, stomps and near misses, with a settings toggle (add Android's
    VIBRATE permission only). Gamepad rumble and screen shake carry the same
    cues on desktop. Giant-scale audio: human voices through a low-pass
    "muffled" bus, fridge hum and TV mumble as positional 3D audio, and a
    heartbeat layer that rises with alert level.

## Objectives, game loop & progression
- Per level: collect N crumbs + reach the goal/hiding spot without being caught,
  under rising threat intensity (more/faster hazards over time).
- Scoring: crumbs, time survived, close calls, stealth (never spotted,
  lures used, threats turned on each other), plus per-level badges.
- Progression: start with Cockroach unlocked; unlock Fly and Spider via
  progress. Save it.
- Lose = caught/swatted/stomped (respect Cockroach's extra-hit rule).

## UI / menus / HUD
Main menu, bug select (locked/unlocked states), level select, in-game HUD
(health/lives, crumbs, objective, threat indicator, eye meter, noise ring,
alert icons, off-screen threat markers, sense meter), pause, win/lose screens,
settings (volume, controls, quality). HUD and menus must scale and be
touch-usable on phone and mouse/gamepad-usable on desktop.

## Controls
- Mobile: on-screen virtual joystick (move) + context action buttons (primary /
  secondary / dodge / interact). Fly = drag-to-steer feel; Spider = tap target
  to web/zip; Cockroach = hold to squeeze. A `sense` button per bug; freeze
  is just letting go of the stick. Touch controls auto-show on touchscreens,
  hidden on desktop.
- Desktop: WASD/arrows + mouse, full gamepad support. Rebindable where feasible.
- All of it routes through InputRouter actions.

## Cross-platform export setup
- Write export_presets.cfg with presets for Android, iOS, Windows, macOS,
  Linux, Web.
- Configure Android: package id (use com.aethertek.bugseyeview as placeholder),
  min/target SDK, portrait+landscape, required permissions minimal, both .apk
  (sideload/test) and .aab (store).
- Configure iOS: bundle id, portrait+landscape, generate the Xcode project.
- Set app name, icons (generate simple placeholder icons), and a splash.
- In the handoff doc, list exactly what I must install/provide for each store
  export (Android SDK + build tools; for iOS: a Mac, Xcode, Apple Developer
  account + signing). Don't block the build on these — set presets up so I can
  export once I supply them.
- I work on Windows with no Mac. In the handoff doc, include a cloud-Mac route
  for iOS builds (e.g. Codemagic) alongside the local-Mac route.

## Art & audio
Generate/boot with placeholders only: primitive meshes, flat colored materials,
simple procedural or free-tier-style beep/thud SFX stubs. Keep all art behind
clean references so I can replace it without touching gameplay code.

## Build & test workflow (do this every phase)
- Validate: `godot --headless --path . --quit` and fix all errors/warnings.
- Smoke-test core loop by running the main scene headless where possible.
- Test an Android debug export early to prove the mobile pipeline works:
  `godot --headless --export-debug "Android" build/bugseyeview.apk`
- Keep a RUN.md explaining how I open it in the editor, play on desktop, and
  export per platform.

## Phased milestones — STOP after each and tell me how to test it
Phase 1 — Vertical slice + stealth foundation (prove it works end to end):
  Cockroach only, Kitchen only. Foot + swatter hazards driven by a human
  presence that uses alert levels + search. Crumbs + goal. Full InputRouter
  with touch AND keyboard. PerceptionSystem with light & shadow zones, noise
  surfaces, and freeze & blend in. Cockroach senses (smell + light aversion).
  Footstep haptics. Runs on desktop, exports to Android .apk.
Phase 2 — Full bug roster: add Fly and Spider with their movement, abilities
  and senses (bullet-time, vibration), per-bug camo, fly buzz noise, spider
  web-trip lure, bug select + unlock/save.
Phase 3 — Content & AI: Living Room + Backyard levels, pets with sight, hearing
  and scent + NavigationAgent chase, scent trails, distractions & lures,
  escalation chain, newspaper hazard, threat escalation, scoring + badges.
Phase 4 — Living house: HouseClock + routines, physics props and chain
  reactions, turning threats on each other, extra hazards, secret routes +
  Golden Crumbs, the three boss chases.
Phase 5 — Shell & UX: all menus, settings (incl. haptics toggle), HUD polish
  (eye meter, noise ring, alert icons, off-screen markers), pause/win/lose,
  colony home base, full audio pass.
Phase 6 — Ship prep: icons/splash, all export presets configured and test-built,
  performance pass for mobile, RUN.md + store-export checklist.

## Coding standards
Typed GDScript, small single-purpose scripts, signals over tight coupling,
object pooling for hazards/particles, no hardcoded magic numbers (use the .tres
stat/config resources). Comment the non-obvious.

## If blocked
If a decision is genuinely ambiguous or a choice is hard to reverse, ask me ONE
concise question and keep going on everything else. Otherwise take the most
reasonable path, note it, and proceed.

Start with Phase 1 now.
