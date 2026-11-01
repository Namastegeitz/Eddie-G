# Bug's-Eye View

An action-stealth survival game in Godot 4.7. You are a tiny household bug
in a giant human home: scavenge crumbs, stay unseen, unheard and unsmelled,
and escape. One codebase for Android, iOS, Windows, macOS, Linux and the web.

![Kitchen on a phone](docs/screenshots/kitchen_phone.jpg)

- How to open, play, test and export: [RUN.md](RUN.md)
- What each store needs: [docs/STORE_EXPORT_CHECKLIST.md](docs/STORE_EXPORT_CHECKLIST.md)
- The prompt this was built from: [../../prompts/claude/bugs-eye-view.md](../../prompts/claude/bugs-eye-view.md)

## What's in the game

**Three bugs**
- **Cockroach** (unlocked from the start): fast, squeezes flat into gaps to
  hide, survives one extra hit with a knockdown, plays dead near a suspicious
  threat, smells crumbs with its antennae, runs faster in the dark and bolts
  when a light flicks on.
- **Fly** (escape the Kitchen): buzzy 3D flight with momentum and drift,
  burst dodge, stamina that forces it to perch, and compound-eye slow motion
  when a strike is about to land.
- **Spider** (escape the Living Room): walks on walls and ceilings, zips on
  web lines that stay behind as bridges, spins web traps, feels footsteps as
  ripples through walls.

**Three rooms, each with a boss chase when the exit opens**
- **Kitchen**: the human's feet and swatter, a sink drain, a glue trap, the
  fridge light. Boss: *Cleaning Day* (the robot vacuum hunts your noise,
  then the spray comes out).
- **Living Room**: the TV masks your noise but its glow exposes you, a fan
  blows flyers off course, the cat leaps onto furniture and knocks things
  over. Boss: *The Cat*.
- **Backyard**: open sky, a dog that follows your scent trail, sprinklers and
  puddles that wash it away, crunchy leaf piles. Boss: *The Exterminator*,
  a fog front that sweeps the yard.

**Stealth systems**
- Light and shadow zones, noisy and quiet surfaces, ambient noise that masks
  you, freezing in place and camouflage on matching surfaces.
- Every threat goes unaware > suspicious (?) > searching > alert (!), checks
  where it last noticed you, and calms down if you stay hidden.
- Escalation chain: a human who spots you shouts, grabs the swatter, calls the
  pet, then brings out the bug spray.
- Lures (phone, spoon, TV remote, knocked-off peas) and turning threats on
  each other (a swatter clanging off a pan, a foot on a grape, a mug knocked
  onto a foot).

**A living house**: each room runs a compressed daily routine (breakfast,
nap, dishes, cleaning, lights out) that changes who is there and what is lit.
Pick morning, afternoon or night once you've escaped a room.

**Progress**: crumbs feed your colony, which grows and unlocks upgrades.
Badges per room: Ghost (never spotted), Speedrun, Golden Crumb (found at the
end of each room's secret route).

**Feel**: phone vibration and gamepad rumble on footsteps and near misses,
giant muffled human voices, a heartbeat that rises when you're hunted.

## Status

All six build phases from the prompt are done. Placeholder art and sound
throughout (generated primitives and synthesized audio), ready to swap.

- 118-check headless smoke test passes in the project and in an exported
  build (`tools/run_tests.sh`), with zero GDScript warnings.
- Builds produced and checked: Android debug APK (signed), Windows, macOS,
  Linux, Web, and the iOS Xcode project. The web build was played in a
  browser at desktop and phone sizes.
- Not done here: the Google Play AAB (needs the Android SDK on your machine)
  and the signed iOS build (needs a Mac or a cloud Mac). See the checklist.

| | |
|---|---|
| ![Menu](docs/screenshots/menu_desktop.jpg) | ![Bug select](docs/screenshots/bug_select.jpg) |
| ![Kitchen](docs/screenshots/kitchen_desktop.jpg) | ![Pause](docs/screenshots/pause_desktop.jpg) |
