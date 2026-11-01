# BUILD: "Bug's-Eye View" — a cross-platform action-stealth survival game

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
    /autoload/      (singletons: GameManager, InputRouter, SaveSystem, Audio)
    Initialize a git repo. Commit after every phase with a clear message.

## Core architecture
- InputRouter (autoload): ONE abstraction that emits game actions
  (move_vector, jump, primary, secondary, interact, dodge). Touch controls,
  keyboard/mouse, and gamepad all feed into it. Gameplay code NEVER reads raw
  input — only these actions. This is what makes cross-platform clean.
- GameManager (autoload): game states (menu, playing, paused, caught, win),
  current bug, current level, score.
- SaveSystem (autoload): persist unlocked bugs, level progress, best scores,
  settings. Use user:// so it works on every platform.
- AudioManager (autoload): sfx + music buses, master/sfx/music volume in
  settings.

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

## Objectives, game loop & progression
- Per level: collect N crumbs + reach the goal/hiding spot without being caught,
  under rising threat intensity (more/faster hazards over time).
- Scoring: crumbs, time survived, close calls.
- Progression: start with Cockroach unlocked; unlock Fly and Spider via
  progress. Save it.
- Lose = caught/swatted/stomped (respect Cockroach's extra-hit rule).

## UI / menus / HUD
Main menu, bug select (locked/unlocked states), level select, in-game HUD
(health/lives, crumbs, objective, threat indicator), pause, win/lose screens,
settings (volume, controls, quality). HUD and menus must scale and be
touch-usable on phone and mouse/gamepad-usable on desktop.

## Controls
- Mobile: on-screen virtual joystick (move) + context action buttons (primary /
  secondary / dodge / interact). Fly = drag-to-steer feel; Spider = tap target
  to web/zip; Cockroach = hold to squeeze. Touch controls auto-show on
  touchscreens, hidden on desktop.
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
Phase 1 — Vertical slice (prove it works end to end):
  Cockroach only, Kitchen only, foot + swatter hazards, crumbs + goal, full
  InputRouter with touch AND keyboard, runs on desktop, exports to Android .apk.
Phase 2 — Full bug roster: add Fly and Spider with their movement + abilities,
  bug select + unlock/save.
Phase 3 — Content: Living Room + Backyard levels, pets with vision/chase AI,
  newspaper hazard, threat escalation, scoring.
Phase 4 — Shell & UX: all menus, settings, HUD polish, pause/win/lose, audio.
Phase 5 — Ship prep: icons/splash, all export presets configured and test-built,
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
