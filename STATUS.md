# Status

## Off-Grid Survival Kit (`apps/off-grid-survival-kit`)
- Built from `prompts/claude/off-grid-survival-kit.md`: hub + map + 8 module folders, PWA (manifest,
  service worker precaching 53 files), everything on-device (IndexedDB/localStorage), no CDN.
- Map: IndexedDB tiles (browse-to-prime, capped "save this area" with elevation, parent-tile fallback,
  graticule when blank), OSM/OpenTopoMap/custom URL, GPS + follow + telemetry, compass (iOS prompt),
  waypoints (9 categories) + navigate-to, tracks, measure, GPX/JSON import-export, sun & moon,
  MGRS/UTM grid, triangulation, elevation/slope + contours, QR share, SOS beacon, NJ/Algarve presets.
- Content: foraging, water, first aid, fire/shelter/knots (SVG knot steps), food, electricity, tools
  (strobe/Morse/tones/checklists/rendezvous), emergency PDF (18 pages, reportlab) + HTML version.
- Tests: `tests/acceptance.js` (Playwright, mock tile server) — 25 checks online→offline all pass;
  Chrome reports no PWA installability errors; print preview checked.
- Not verified on real hardware yet: install + offline launch on a phone, real GPS/compass, torch,
  and whether tile.openstreetmap.org / OpenTopoMap allow CORS saving (sandbox couldn't reach them).
- Live compass: standalone `/compass/` page + full-screen compass from the map's rose (shared engine
  `assets/js/compass.js`): true/magnetic, bearing lock + steering, back bearing, level, sun/moon check,
  point-to-waypoint, camera sighting tape, bearing log, spoken heading; locked bearing drawn on the map.
- Hub has an "Open on another phone" QR (points at https://namastegeitz.github.io/Eddie-G/).
- Hosting: `scripts/publish_pages.sh` pushes the app to a gh-pages branch for GitHub Pages. Not run yet —
  publishing a public site needs the owner's go-ahead (the session's permission check blocked it).
- Zip: `apps/off-grid-survival-kit/dist/off-grid-survival-kit.zip`.
- Next: host it on HTTPS (e.g. GitHub Pages), install on a phone, save NJ/Algarve areas, field test.

## Bug's-Eye View (`apps/bugs-eye-view`)
- Built end to end from `prompts/claude/bugs-eye-view.md` (all 6 phases, all 16 add-ons).
- Godot 4.7.2 project: 8 bugs, 3 rooms with boss chases, perception-based stealth,
  escalation chain, daily routines, colony upgrades, menus, touch/keyboard/gamepad.
- Tests: `tools/run_tests.sh` - 165-check smoke test + 340-check phase audit + offline
  Meshy client test pass in the project and in an exported build; zero GDScript warnings
  and engine errors.
- Updates after the build: alarm gauge (threats only investigate until it's full), slower
  and less sharp-eyed humans/pets, fly escape moves (loop, dive, cling, jink, glide),
  20 new places to hide (11 shelters, 7 sight blockers, 2 tall-grass patches), then bigger
  rooms (kitchen 170x125, living room 180x100, backyard 194x164) with 7 more hiding spots,
  full human bodies (faces, hands, outfits, knee-bending legs), detailed jointed bugs with a
  walk cycle, 6 bug foods and 6 crumb gems with effects. 90 model slots.
- Then: fly flight fixed (level flight, hover, look-to-climb) plus updrafts and pestering;
  animals playful/alert with moods and body language, a puppy in the kitchen, sharper each
  room; people do activities (cooking, dishes, snacking, reading, napping, watering, kneeling,
  fetch).
- Then: touch look stick with a speed button; beagle dog upgrade, cat and dog playing chase in
  the living room and backyard.
- Latest: 5 new bugs (ant, cricket, ladybug, firefly, stink bug), each in the shade (a dark
  silhouette on bug select) until you escape a room as the bug before it; a how-to-play card
  the first time you play each bug (also under Pause > Controls); a gold exit marker; auto
  quality that steps graphics down on slow phones; far-away small things stop drawing.
- Phase-by-phase audit (all 6 phases) done; fixes it found: human feet were never solid,
  props didn't stun via feet, cereal-box domino layout, spider facing/normal errors, fog strength.
- Android debug APK committed at `apps/bugs-eye-view/dist/android/bugseyeview-debug.apk`.
- Builds made in the cloud session: Android debug APK, Windows, macOS, Linux, Web,
  iOS Xcode project (not committed; rebuild with the commands in RUN.md).
- Playable web build published as a private Claude artifact:
  https://claude.ai/artifact/Gmpx6M1Qb9WmCn1BY1Qbh4
- Meshy: `apps/bugs-eye-view/tools/meshy/generate.py` + `assets.json` (90 prompts) are ready
  but not run yet. The cloud session couldn't reach api.meshy.ai; to run it here, allow
  api.meshy.ai and assets.meshy.ai in the environment's network settings and add
  MESHY_API_KEY as an environment variable, or run it on the PC.
- Next: generate the Meshy models (tier 1 first), real audio, Google Play AAB (needs Android SDK locally), iOS signing via a
  Mac or Codemagic (`docs/ci/codemagic.yaml`), playtesting and tuning.

## Monkey See, Monkey Do (`apps/monkey-see-monkey-do`)
- Built from `prompts/claude/monkey-see-monkey-do.md` (the brief stopped at "Players earn bananas/coins";
  the economy, wardrobe and transparency features were filled in and are listed at the end of that file).
- Web game (three.js r180 vendored, vanilla JS modules, no build step), installable PWA, offline service worker,
  plus a one-file build: `dist/monkey-see-monkey-do.html` (opens from disk) and `dist/artifact/index.html`.
- Cel-shaded 3D monkey built in code: jointed arms/legs, curly tail, 6 mouths, blinking eyes that follow taps,
  brows, moves + reactions (cheer, dizzy oops with stars, sad slump, point-and-wink, idle fidgets),
  hats/glasses/neckwear, 7 furs. 4 stages (jungle, beach, temple disco, moon) with a light-up dance pad.
- Play: Watch -> Your turn on a beat clock; 6 moves + 4 combos; pad, tap-the-monkey, swipe, keyboard.
  30 levels / 3 worlds (levels 1-10 per the brief; build-up, speed-up, backwards twists later), 3 lives,
  3 stars, Endless (best saved), Free Dance. Synth music per stage, one note per move.
- Transparency: How it works generated from js/rules.js + js/levels.js + js/shop.js; itemised results that match
  the banana ledger; routine codes; mistake cards (missed vs tapped); mix-up stats; local-only save with
  view / copy code / load / reset. Comfort: timer Normal/Relaxed/Off, speed 100/85/70%, Assist mode,
  voice call-outs, captions, reduce motion, rhythm calibration.
- Tests: `node tests/unit.mjs` (443 checks) and `node tests/acceptance.js` (25-step Playwright play-through,
  incl. offline reload) pass.
- Not verified on real hardware yet: touch feel and audio latency on an actual phone, install to home screen.
- Next: pick add-ons from `prompts/claude/monkey-see-monkey-do-next.md` (14 prompts: replay review, Daily
  Dance, choreographer + share codes, accessibility pack, grown-up panel, stickers, World 4, pass-and-play,
  real music, GitHub Pages, Android/iOS builds, opt-in leaderboard, Spanish/Portuguese) and
  `prompts/codex/monkey-see-monkey-do-tasks.md` (10 small tasks).

## NeuroForge (not in this repo)
- Source on the Windows PC: `C:\Users\edwar\Desktop\AI and ALL\Aethertek\content poster\neuroforge`
- Live web: https://neuroforged.surge.sh and https://neuroforge.surge.sh
- App Store launch board was at step 1 of 22 (surge sign-in).
- Next: push the source to a private GitHub repo so cloud/phone sessions can read it.

## Prompts
- `prompts/claude/monkey-see-monkey-do.md` - the brief + what was filled in; `monkey-see-monkey-do-next.md` -
  14 add-on/next-build prompts; `prompts/codex/monkey-see-monkey-do-tasks.md` - 10 small tasks.
- `prompts/claude/bugs-eye-view.md` - v2 with the stealth/interactivity add-ons.
- `prompts/claude/bugs-eye-view-next.md` - 10 prompts for the next features (Meshy run,
  Gem Shrine, Bathroom level, living humans, skins, debug overlay, playtest bot, sound, CI,
  store kit).
- `prompts/codex/bugs-eye-view-tasks.md` - 10 small Codex tasks.
- Tool ideas: `apps/bugs-eye-view/docs/TOOL_IDEAS.md`.
- Next: collect the rest of the new prompt set (Claude + Codex) into `prompts/`.
