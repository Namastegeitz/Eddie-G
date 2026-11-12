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

## Canopy Crossing (`apps/canopy-crossing`)
- Built from `prompts/claude/canopy-crossing.md` (copied from the Claude doc brief): all 8 phases,
  Godot 4.7.2, portrait 720x1280, GL Compatibility.
- 220 maps: 22 real rainforest scenes x 10 levels (El Yunque and the Cardamom Mountains added). Clearing a
  jungle's last level opens the next one free (rules `open_next_jungle`); packs still open early + bring animals.
  New terrain: waterfall ledges (`falls` slot, 2D animated white water, 3D rushing water + foam), mossy boulders,
  trail wildlife per map (`trail_critters`, both views); new creatures (land crabs with a crab painter, mongoose,
  boa, red-tailed hawk, Asian elephants, dholes, rosewood trucks, Siamese croc, king cobra). Generator: walkable
  bank columns after stepping stones (boulders can't wall off the next stones), no strikers/fallers there. Difficulty curve
  (`content/difficulty.json`): jungles 1-2 Easy (25-60 rows, slow, small bands, 5 lives), 3-5 Medium, 6-10 Hard, 11-20
  Expert (60-130 rows); levels ramp 1 to 10 (challenge stars on the world map); the first five
  jungles introduce hazards level by level (`from_level`). Stepping stones are always reachable
  past gullies/brush on the banks, and banks after stones get no flood/fire timing.
  Two views: bird's-eye (2D) and first person (3D, eye button / V). Every level has dense-canopy
  zones that hide the ground from above, so first person is needed to cross them.
- Data-driven: 50 animals, 97 hazards, 22 maps (all playable), 3 lane generators,
  store catalog, live ops, 2 seasons, onboarding text are JSON under `content/`. Adding an animal
  or region is a file (the audit proves it by adding both at runtime). Guide: `docs/CONTENT.md`.
- Gameplay: grid hops (tap / swipe / keys / gamepad), movers, platforms (logs, lily pads, diving
  caimans, swaying bridges, tidal driftwood, stepping stones), crocs, snakes, tiger ambushes,
  raptor swoops, falling branches, quicksand, gullies, ridges, brush, fire lanes, tides, mudslides,
  gusts, downpours. 18 ability modules + 2 power-ups. Journey (3 stages per region), Endless
  (jungle creeps up), Daily Challenge (same seed for all, rotates regions incl. locked ones).
- Economy/store: Berries + Amber, unlocks, consumables, cosmetics (skins, trails, emotes, goal
  flags), map packs, animal packs, bundles, Remove Ads, Expedition Pass (30 tiers), daily deals,
  weekend 2x, animal of the week, restore purchases, downloadable content-pack zips.
  Billing: sandbox mock by default; Google Play / App Store adapters behind
  `canopy/billing/backend` (not exercised: need plugins + store accounts, see `docs/STORE.md`).
- Water rule: falling into the water restarts the run from the start of the stage (no life used,
  no revive; Berries kept). Other hazards still cost a life. Switch: `content/rules.json`.
- Onboarding: coached tutorial, region intro cards (globe + facts + hazards), revive / milestone /
  last-life / locked-animal prompts, daily reward, first-unlock guide.
  Tutorial hints are a see-through strip under the score (were a dark box over the lanes in
  front of the animal); the "Wait for the gap" hint is gone.
- Graphics upgrade: outline + shading pass for all animals, hazards, predators, tiles and pickups
  (`scripts/view/draw.gd`), glossy two-catch-light eyes, fur/feather strokes, rosettes; lane grain
  texture; water canvas shader (`assets/shaders/water.gdshader`) driven by each lane's clock; 3D
  view renders at screen resolution on High with MSAA, shadows, textured ground and glossy moving
  water. Settings > Graphics (Auto/High/Medium/Low, `scripts/view/gfx.gd`).
- First person fixed: on phones (and with a mouse) a tap reached the eye button twice (touch +
  emulated click), switching to first person and straight back; only V worked. Fixed in
  `Widgets.tap`; guarded by an audit check that taps like a real finger, a GL render check of
  every scene (`tools/fpv_check.tscn`, in run_tests.sh) and a phone-browser tap test run by
  `tools/build_web.sh` on every web build. The 3D view is also built and warmed up (shaders
  compiled) just after a level starts, so the first tap doesn't stall; Medium quality (phones,
  web) renders 3D without MSAA at up to 1.5x instead.
- 80 themed first-person scenes (4 per region, `fpv_scenes` in each map file, built by
  `scripts/view/scenery_3d.gd`): real plants, overhead dressing, landmarks, fauna, particles,
  light and fog per scene; title card on entry; levels have 1-3 canopy zones (1/2/3 by level
  band). Each dressed row is one merged mesh; moving things are baked to one mesh each, so the
  first-person scene draws ~255 meshes (was ~450). 3D renders at up to 1.5x on Medium, 2x on High.
- World map globe is a shader (`assets/shaders/globe.gdshader`) over a 2048x1024 map built from
  Natural Earth 1:50m (`tools/gen_globe_map.py`): LED land dots, glowing coasts, borders, grid,
  scan sweep, rim/halo; beacon pins (flag / padlock / soon), flight-path arc, coordinates tag,
  orbit ring, drag-to-spin (vertical drags still scroll).
- First-person models (`scripts/view/models_3d.gd`, cached meshes): logs (bark, knots, stubs,
  moss, ringed ends; rolling logs turn), caiman backs (scutes, eyes, nostrils, legs), crocodile
  jaws (teeth, mouth, eyes). The ant highway (Amazon, Yasuní, tutorial) is now giant red soldier
  ants carrying cheese (`red_soldier_ants`, 2-3 ants of 0.9 tiles: same convoy span as before),
  in 3D (walking tripod gait) and bird's-eye. Preview: `tools/model_sheet.tscn`.
- Bird's-eye canopy roof rows are drawn once and swayed (were redrawn leaf by leaf every frame:
  ~3 ms/frame of script in canopy zones); the first-person warm-up no longer waits on
  frame_post_draw (which never fires headless and left the 3D view up). Frame-cost check now
  takes the median of 5 alternating rounds.
- Phones: the web page had no viewport meta, so mobile browsers laid it out 980 px wide and the
  game rendered ~6x the pixels it needed (now 390 px layout, canvas 780 on a 2x phone; the
  phone smoke test checks it). HUD and pause menu draw above the canopy roof (z 20/30). Home
  screen fills tall screens (its box kept its minimum size, left of centre). The unsupported
  2D MSAA setting is gone (GL Compatibility has none).
- Beta for phones: `.github/workflows/canopy-crossing-beta.yml` builds web + Android APK (release
  engine, beta key) on GitHub, tap-tests first person in a phone browser, and publishes a tester
  site to GitHub Pages (`/canopy-crossing/`: play, add to home screen on iPhone/Android, APK).
  Not live yet: GitHub refuses every Actions job on this account (all runs since Nov 3 fail in
  seconds, both apps); the owner needs to clear that (Settings > Billing and plans / the failed
  run's message) and set Settings > Pages > Source: GitHub Actions, then run the workflow.
  Meanwhile the claude.ai artifact can be shared publicly from claude.ai (Share).
- Skill levels: every animal's ability upgrades Lv 1-5 with Berries (120/260/480/800) on the animal
  screen (pips + what the next level adds); runs use the level. Rules per ability parameter in
  `content/skills.json` (`scripts/sim/skills.gd`): shorter cooldowns, longer effects, more distance /
  charges / swings, quicker hops for animals with nothing else to scale.
- Meshy models (`apps/canopy-crossing/tools/meshy/`, budget-capped pipeline; 480 credits fauna + 690 scenery of the
  account's 1,255; 55 left, shared with another project): 16 creatures/starter animals and 23 scenery pieces,
  mapped by `content/models.json`. First person uses them for movers (tinted per species, stride bounce), caiman
  backs, surfacing crocs, striking snakes/tigers, swooping eagles, logs/lily pads/stones/trucks/jeeps/boats, canopy
  props and landmarks, open-row trees/plants/undergrowth walls, boulder tiles; Low graphics keeps built shapes.
  Starters turn in 3D on the home and animal screens (ModelView). Textures Basis Universal (1024 colour / 512
  others), ~0.4-1.2 MB per model in the game. Bird's-eye 2D art is unchanged.
- First-person light: procedural sky (closes in under canopy), ACES tone mapping, contrast/saturation, bloom on
  High, normal-mapped ground. Jumps: arc by landing surface, eye rides on logs/pads/stones, landing dip, per-surface
  landing sounds (timing unchanged). Live mini-map (both views, tap to resize, Settings > Mini-map).
- First-person view widened (Settings > First-person view: Wide default / Extra wide / Classic): the field of
  view fits the screen's shape (at least ~93 deg side to side on a phone and 80 deg top to bottom on a wide screen,
  was 86 x 55 there), the eye sits a little higher and further back, 22 rows drawn ahead (was 18), lighter fog.
- Smoother runs: the fixed 60 Hz sim is drawn at an interpolated time (`RunSim.set_lead`/`vt`), so
  hops, logs and traffic glide on 90/120 Hz screens and late frames. First person caches canopy rows
  (4 looks per scene + landmark rows; waterfalls keep their sheet), pre-builds rows up to 60 ahead
  and the logs/ants/caimans about to come into view one per frame (`warm_step`), reuses moving
  things from a pool, and builds at most one far row a frame. Cloud CPU, hopping every 14 frames:
  first-person hitches over 3 ms down from 5-7 a run to 0-2, bird's-eye none (worst frame ~2 ms).
- Feel: log carry during sideways hops, magnetic landing onto log ends (0.2 tile), vehicle hit
  edges 0.1 tile forgiving, Close call! +2 for movers brushing past, swipe threshold 36 px.
- Art/audio: procedural chibi animals and hazards, per-region palettes and canopy framing, dot
  globe from Natural Earth, synthesised per-region music + ambience + 26 SFX (`tools/gen_audio.py`).
  Calm songs (default): one per region + menu, ~1 min seamless loops, tuned to 528 Hz or 963 Hz
  (alternating by globe order; just-intonation ratios of the tone, drone on the tone, tuned pluck,
  heartbeat and bowl, reverb fed only above 260 Hz); `gen_audio.py --check` decodes each and checks
  its 12 strongest pitches sit on the tone (in run_tests.sh). Settings > Music style > Classic.
- Ads: opt-in rewarded + between-run interstitial (mock; AdMob adapter scaffold). Analytics: events
  + onboarding funnel to `user://analytics.jsonl`, optional HTTP endpoint.
- Tests: `tools/run_tests.sh` - compile check + first-person GL render check + 376-check phase audit (one section per phase's
  checkpoint) in the project and an exported pack, all passing. A path-finding bot beats all 220
  levels (tools/level_sweep.tscn, ~2 min) and the first 50 Endless rows on every scene with the free Poison Dart Frog.
  Frame cost 0.9 ms (sim + view + draw recording) on the cloud CPU.
- Playable web build (private artifact): https://claude.ai/artifact/NHzAQ2w4jCjWjLkoxLSdB3
  Gameplay clip: `apps/canopy-crossing/docs/gameplay.mp4`.
- Not done here: signed Android/iOS builds (need Android SDK + keystore, Mac/Xcode), real store
  sandbox purchases, real ads, on-device 60 fps check (Settings > Show FPS counter), playtesting.
- Next: playtest difficulty with people, real art pass (sprites drop in via `"sprite"` in files),
  Android AAB + Play internal track with GodotGooglePlayBilling, iOS via a Mac or Codemagic.

## Cosmic Saucer Drift (`apps/cosmic-saucer-drift`)
- Upgrade pass (docs/UPGRADE_AUDIT.md): four audits of every system; verified bugs fixed (atomic save + backup,
  Android Back, ghost, finished AI, pause during load, dynamic resolution at 30 fps, EMP pool leak, leech/comet/
  repulsor rules, split-screen sound, road surface bands, skyway lip/wall, billboards, rock normals, touch after
  pause, HUD/hint redraws, daily streak dates, achievements that follow content) plus perf fixes.
- Data-driven: effects keys (scripts/data/effects.gd) replace passive/perk branches; content/*.json + drop-in
  packs (autoload/content.gd) for pilots, craft, mods, sets, Wonders, biomes; schemas in docs/SCHEMAS.md.
- RACE NOW (one tap) + Racers page before every race (portraits, live close-up, rivals, START); 8 creature pilots.
- Super Upgrades: Stardust from clean drifts, 3-tier Technical Wonder per premium craft (Photon Spinnaker,
  Lighthouse Cloak, Relativistic Jet, Stellar Harvest; R / R3 / D-pad down / touch WONDER), Core/Field/Drive mods
  with set bonuses, overclock heat + burnout, global perks; Super Upgrades screen + Hangar Wonder/Mods tab.
- Volcanic biomes Eerie and Divine (content/biomes.json): procedural low-poly formations with LODs, lava rivers,
  smoke, mist, lighting; Settings > Volcanic biome. Meshy pipeline (tools/meshy/generate.py) + import slots +
  LOD bake (tools/meshy/bake_lods.tscn): all 8 formations generated with Meshy (170 credits), welded, unit space,
  5-8 LODs; exports ship only the baked meshes. Mock-API test (tools/meshy/test_pipeline.py) kept for offline runs.
- HD fleet and 3D cockpits:
  - content/craft_hd.json defines 10 realistic craft from Meshy, each with an exterior and a first-person interior.
  - Pipeline: --source craft, extract_textures, bake_craft, craft_preview, --refetch.
  - Aurora is done inside and out; every craft shows a 3D cockpit in first person.
  - The other 9 are waiting for credits (about 60 each) and stay hidden until baked.
  - Meshy spend for craft: 75 credits.
  - The account is shared with the Canopy Crossing session, which was generating animals at the same time.
- v1 built from `prompts/claude/cosmic-saucer-drift.md` (concept + every add-on: extra weapons, pro
  moves, living tracks + secrets, rivals + boss races, cups, time trial + ghost, daily, 2P split-screen,
  cosmetics, reverse/mirror, achievements; free/no ads with an ads layer switched off).
- v2 (same prompt file, "v2" section): real places. 14 tracks in 4 real systems + a Grand Prix: Mars,
  Ceres & the belt, Io, Saturn's rings | TRAPPIST-1 b, e, h | Proxima b, Proxima Station, Alpha Centauri
  twin suns | HD 189733 b, 55 Cancri e, Kepler-16b, WASP-76 b. 3 real facts per track (track select,
  countdown, pause, results), real suns drawn in the sky (red dwarfs, twin suns), per-world gravity,
  new scenery per world, new hazards (dust devils, supersonic wind gusts, glass/iron/plasma rain).
- Spacecraft: 14 craft = 6 saucers + Orb Drone, Crystal Shard, Bio-Ship, Arrowhead Interceptor + premium
  Solar Sail Yacht, Pulsar Phantom, Quasar Dragon, Dyson Racer (perks). Stardust renamed Race Credits
  (old saves migrate). Premium craft 12,000-22,000 credits + stars.
- Power-ups (20): Homing Rocket, Pulse Laser, Comet Strike, EMP Shockwave, Nitro Rocket (1-3 uses), Ion
  Shield (use or hold to block one hit), Gravity Mine, Tractor Beam, Warp Jump, Decoy Drone,
  Energy Leech, Gravity Well, Frost Trail, Overcharge, Solar Flare, Chain Lightning, Plasma Wall,
  Stasis Field, Phase Cloak and Repulsor Pulse, in 5 lineups by place (leaders defend, the back
  of the pack gets comeback tools). Roads 25% wider; wall scrapes cost little speed.
- Scenery v4: moons orbiting the backdrop planets, asteroid belts, satellites, holo gates and neon
  lamp posts along the road, floating billboards, a comet crossing the sky, aurora curtains and
  shooting stars in the sky shader; every world now has a backdrop planet.
- Glide: energy wings unfold while airborne (hold Shift / D-pad up; automatic on touch and for AI):
  soft sink, no climb, full air steering, brake flares; wing meshes on every craft. Skyways
  (`"glide"` shortcuts on Io, Mars, Kepler-16b): yawed tall ramp on the road edge, a corridor of air
  with shard/pillar markers, a hidden landing strip 85 m out that returns as a bridge over the road;
  AI never glides and avoids the ramp lane; `TrackData.def_overrides` lets tools try placements.
- Opens and runs smooth: loading screen (track, progress, tip) with the race built in stages across
  frames (`Race._build`, `load_ms` per stage, `tests/loadtime`), race shaders compiled behind the
  menu (`ShaderWarmup`), two pre-draw frames behind the overlay, dynamic 3D render scale before
  Auto quality drops a tier, and a 30 fps cap setting.
- Real-money store layer (`Store` autoload, debug + Play Billing template, products for premium craft,
  fleet bundle, credit packs, remove ads) built and switched off: `docs/STORE_PLAN.md`. Ads layer as
  before: `docs/ADS_PLAN.md`. v1 listing stays "no ads, no purchases, no data collected".
- Tests: `tools/run_tests.sh` - parse check, smoke test (667 checks incl. live power-up tests, perks,
  store flow, save migration, v3 graphics) and the AI race sim on all 42 layouts.
- Builds: debug APK in `dist/android/` (signed with `tools/android/apksigner`, a small APK Signature
  Scheme v2 signer, because Google's build-tools download is blocked here); web build published as a
  private artifact: https://claude.ai/artifact/Wjris6Pjst5K54bF6z8MUY
- Store kit: `docs/STORE_LISTING.md`, feature graphic, icon and screenshots in `docs/store/`,
  `docs/privacy-policy.html`, `docs/STORE_EXPORT_CHECKLIST.md`.
- v3 (same prompt file, "v3" section): HD graphics, characters and feel. All 14 craft rebuilt from
  code in high detail (bevelled turned hulls, panel seams, chrome, running/nav lights, nozzles with
  live flames, glass cockpits, hex shield) and baked per material; 8 pilots with their own faces,
  outfits and accessories, blinking eyes that follow the steering, and moods (focus, grin, dizzy,
  shock, cheer, sad) plus arms on the yoke. Worlds: HD road surfaces with bump detail and kerbs,
  lit barrier panels, eroded strata spires, layered skies with a galaxy band, planets with craters or
  storms and atmospheres, sky reflections, real-time shadows. Effects: boost shockwaves, impact
  flashes and sparks, landing dust, drift glows, speed lines; chase camera with drift swing, boost
  FOV kick, landing dip and a slow-motion finish swing to your cheering pilot. Low/Medium/High/Ultra
  graphics tiers (Auto picks from the device and steps down live). Tuning: eased digital steering,
  fairer AI catch-up per difficulty (none in the last half lap), running start after rescues.
- v3 tests: smoke test 667 checks (71 new for v3) and the AI race sim on all 42 layouts pass; game
  logic per physics tick about 6% heavier than v2 on this machine (faces only animate when close).
  A racer that stops making progress (pinned on a wall or hazard) now gets the rescue beam.
- Not done here: Play Store AAB (needs the real Android SDK + Gradle on the PC), testing on a real
  phone (especially the graphics tiers and frame rate), music. Next prompts:
  `prompts/claude/cosmic-saucer-drift-next.md`.

## Bug's-Eye View (`apps/bugs-eye-view`)
- Built end to end from `prompts/claude/bugs-eye-view.md` (all 6 phases, all 16 add-ons).
- Godot 4.7.2 project: 8 bugs, 3 rooms with boss chases, perception-based stealth,
  escalation chain, daily routines, colony upgrades, menus, touch/keyboard/gamepad.
- Tests: `tools/run_tests.sh` - 165-check smoke test + 463-check phase audit + offline
  Meshy client test pass in the project and in an exported build; zero GDScript warnings
  and engine errors.
- Updates after the build: alarm gauge (threats only investigate until it's full), slower
  and less sharp-eyed humans/pets, fly escape moves (loop, dive, cling, jink, glide),
  20 new places to hide (11 shelters, 7 sight blockers, 2 tall-grass patches), then bigger
  rooms (kitchen 170x125, living room 180x100, backyard 194x164) with 7 more hiding spots,
  full human bodies (faces, hands, outfits, knee-bending legs), detailed jointed bugs with a
  walk cycle, 6 bug foods and 6 crumb gems with effects. 95 model slots.
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
- Graphics and motion upgrade: generated high-res surface textures with bump maps (tiles,
  wood, flagstones, grass, carpet, fabric, denim, fur, bug shells; `tools/generate_textures.py`),
  rounder models, eyes that move and blink; motion smoothed between physics steps; people walk
  heel-to-toe and glide, sway, breathe, glance, double-take; pets ease into runs, pant, blink;
  forgiving jumps; camera eases around walls; High/Medium/Low rendering tiers.
- NPC update: people check phones, stretch, pet the pets, kick toys aside, sweep (broom pushes
  you and crumbs), rake, open the fridge (door swings out as an obstacle, light on), switch on the
  reading lamp, draw the curtains; pets sit, lie, groom, scratch, stretch, drink at water bowls
  (puddles), shake off water, push toys, flee the vacuum; the dog digs holes (mound + hiding
  hollow); the robot vacuum eats crumbs (they return) and bumps toys.
- Bug's-eye view (first person through each bug's sculpted eyes, own antennae/mouthparts/legs in
  view, per-bug FOV, compound-eye facets for flies, spider view follows walls); Shift taps to dash
  and holds to run; 10 power-ups hidden in each room (Turbo, Spring Legs, Bug Radar, Double
  Crumbs, Shrink); people no longer vanish mid-chase when their routine ends (they finish, calm
  down and walk out through the door; they also walk in through it).
- Climb and collect: every bug climbs walls, cupboards, table legs and props (clambers round
  counter lips, walks over the top, Jump leaps off); a junk-tower staircase in each room
  (groceries, books, flowerpots) and 3 bounce pads per room (sponges, cushions, mushrooms)
  that fling you onto the counter, fridge, bookshelf, shed roof; 18 treasures (common to
  legendary) plus the crumb gems collected into a showcase on the home screen (trophy shelf +
  Showcase screen of all 24); 16 power-ups per room.
- Mini maps and add-ons: 10 mini maps behind each room (30; inside the walls, under the sink,
  basement, attic) with tasks (shards, timed, key, climb), mouse traps, drafts, cobwebs, a cat
  or vacuum on some, and a hidden crawl space that opens now and then; credits from shards,
  gems and treasures buy 12 add-ons (strength, defense, tactics, 3 levels each) in the Armory,
  loaded into a six-chamber revolver that swings open in play to choose and fire.
- Smooth characters and colour: tapered limbs meeting at rounded joints for people, pets and
  bugs (elbows, knees, wrists, tails, bug legs and antennae), one-piece torso, head and pet
  bodies, rounded sneakers, soft shading baked into vertex colours, sheen on fur/cloth/shells,
  cream belly and bibs on pets, gentler skin, a little more saturation and contrast.
- Health and live snap traps: a health bar (100) that regenerates 4 s after the last hurt;
  stomps/swats still cost a whole hit; crumbs +6, gems +12, food +20, power-ups +40. Snap traps
  trigger on anyone standing or landing on the plate, knock you out for 3 s under the bar and
  take 65 health; one snap never kills, two back to back do (HUD shows DAZED meanwhile).
- Crashes make everyone look: glasses and teacups that shatter, potted plants whose pots break,
  mugs and cereal boxes, and a row of toy dominoes on the coffee table (one multimesh). A crash
  makes every person and pet stop, stare (seeing x0.2) and go check; a crash mid-chase buys a
  moment. New Meshy fridge (door cut off the model, stretched to the box) with Meshy groceries on
  its shelves, shown only while the door is open; models made phone-sized (gltf-transform WebP,
  Basis textures; raw downloads kept in tools/meshy/raw).
- Up on the furniture: people no longer step up onto tables to stomp (feet stay on the floor,
  and they won't walk under furniture). Within reach they lean over and slap with their own hand
  (arm IK, lean and crouch; swatter/newspaper too); out of reach they throw a sponge, slipper or
  ball of paper in a telegraphed arc. Fetch throws now find open lawn (the lane check was broken).
- Phase-by-phase audit (all 6 phases) done; fixes it found: human feet were never solid,
  props didn't stun via feet, cereal-box domino layout, spider facing/normal errors, fog strength.
- Android debug APK committed at `apps/bugs-eye-view/dist/android/bugseyeview-debug.apk`.
- Builds made in the cloud session: Android debug APK, Windows, macOS, Linux, Web,
  iOS Xcode project (not committed; rebuild with the commands in RUN.md).
- Playable web build published as a private Claude artifact:
  https://claude.ai/artifact/Gmpx6M1Qb9WmCn1BY1Qbh4
- Meshy: `apps/bugs-eye-view/tools/meshy/generate.py` + `assets.json` (113 prompts) are ready
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
- Playable as a private Claude artifact: https://claude.ai/artifact/6ARndyKdPDcqbRxZ7ohyMY
- Phones (second pass): runs on iPhone/iPad/Android in the browser (installable, offline) and as native apps.
  - Compatibility: three.js r162 (falls back to WebGL 1; every toon material has a gradient map so WebGL 1
    compiles), bundle targets Chrome 87 / Safari 14, no color-mix/structuredClone, iOS audio unlock + "Play
    sound on silent", touch/zoom fixes, portrait prompt when a phone is sideways, wake lock, haptics.
  - `mobile/`: Capacitor 8.5.3 iOS (SPM, iOS 15+) and Android (API 24+, WebView 87+ with an update page)
    projects, app id com.namastegeitz.monkeydo, "Monkey Do" on the home screen, icons/splash from icon.svg,
    portrait on phones, status bar hidden, back button, no INTERNET permission, release signing via
    keystore.properties. `dist/www` is what both apps load and what to host.
  - Not built yet: the APK (dl.google.com, where the Android SDK comes from, is blocked by this environment's
    network policy) and the iOS app (needs a Mac, or Codemagic: `mobile/ci/codemagic.yaml`). GitHub Actions
    workflow `.github/workflows/monkey-see-monkey-do-mobile.yml` (manual/tag only) is ready, but Actions jobs are
    refused at the account level (runs stop in ~3 s with no log).
  - Tests: `tests/devices.js` (12 checks: simulated app bridge, WebGL 1, 320 px to iPad, sideways) pass on dist/www.
- Skins (third pass): 100 skins in 13 sets (js/skins.js). 50 standard (bananas) and 50 premium (Epic/Legendary):
  pattern textures (js/patterns.js), metal/glow/ghost finishes, glowing eyes, wings, capes, halos, horns, jetpack,
  masks, tail tips and particle auras (js/skinlook.js). Each premium skin unlocks free at its play goal (50 goals)
  or early with golden bananas (earned by playing: first 3 stars +2, world clear +10, Endless +1/10 rounds, set
  complete +5, or swap 100 bananas for 1). No real money. Old fur saves migrate to skins. Wardrobe Skins tab with
  rarity frames, set progress, filters, goal progress bars, lazy-painted portraits, unlock card; How it works lists
  every premium skin with goal and price. Tests: 464 unit checks, 29-step play-through.
- Gear and Shop (fourth pass): 88 gear items in 8 slots (hat, eyes, neck, back, hands, feet, face, aura; js/gear.js
  builds and animates them, 3D wardrobe thumbnails), 20 premium gear items for golden bananas, 6 saved outfits.
  Real-money Shop in the phone apps only (js/store.js, js/billing.js, js/storeui.js; cordova-plugin-purchase 13.19.1):
  Starter Pack $0.99 (once), banana packs 500-8,000 and golden packs 12-190 at $0.99/$1.99/$4.99/$9.99, Party $2.99
  and Mega Party $7.99 combos, 7 bundles $2.99, 8 premium skin sets $4.99. Grown-up check, monthly limit, Restore,
  Purchases list, honest bonus labels, no timers, nothing only for sale. Web build shows the Shop, sells nothing;
  `?billing=test` / `#store-test` = pretend purchases. Store setup: mobile/README.md, docs/STORE_PRODUCTS.md,
  mobile/ios/App/MonkeyDo.storekit. Tests: 507 unit checks, 33-step play-through (incl. test-mode purchases).
  Not verified: real App Store / Google Play purchases (need developer accounts, products created, a device).
- Graphics upgrade (fifth pass): detailed monkey (fingers with 4 hand poses, big toe, cheek/head tufts, painted irises,
  blinking eyelids, smooth tube tail, springy ears/tuft/tail, rim light), four rebuilt stages (js/stage.js) with painted
  skies and ground textures, swaying grass, flowers, light rays, butterflies, animated sea, disco mirror-ball specks,
  moon craters/Earth/ringed planet/shooting stars; real soft shadows; play feedback (limb sparkles by grade, Perfect
  camera kick, move trails, streak-warm pad lights). Graphics levels Low / Medium (Auto only) / High / Ultra (up to 3x);
  Auto is time-based (3 s windows). Static scenery merged per material (js/gfx.js). Sharper Wardrobe portraits and gear
  thumbnails, 512 px fur patterns. Tests: 507 unit checks, 34-step play-through (new graphics-levels step) on source
  and dist/www, 12 phone checks; all four stages render on WebGL 1 with no shader errors.
- Levels and maps (sixth pass): levels 2 and 3 are "Take turns" rounds (monkey adds a move, you copy and add one, the
  monkey copies you and adds another, until the dance is 3 long; adding can't be wrong; add-timer timeout = monkey
  picks, no life lost; +50 points per added move). New World 4 Moon Base (levels 31-40, up to 12 moves at 148 BPM,
  take turns returns at 33 and 37 starting from 3 and 5 moves). Every level after 3 moves to the next map (beach,
  disco, moon, jungle...), showdowns on the world's home map; level card, How it works table and results explain it.
  Moon stage free at World 4. Tests: 767 unit checks; play-through clears level 2 by taking turns.
- Public beta link: `/docs` at the repo root is a GitHub Pages site (landing page with Play button, QR code, tester notes,
  "copy my device details"; game at docs/monkey-see-monkey-do = dist/www), refreshed by scripts/build_web.mjs via
  scripts/publish_beta.mjs. Tested from a sub-folder: loads, offline cache installs, reopens offline. Needs Pages switched
  on once (Settings > Pages > Deploy from a branch > claude/nifty-lamport-bfm2ub, /docs); then
  https://namastegeitz.github.io/Eddie-G/
- Not verified on real hardware yet: touch feel and audio latency on an actual phone, install to home screen, and frame
  rate of the new graphics on older phones (Auto steps down if needed).
- Next: pick add-ons from `prompts/claude/monkey-see-monkey-do-next.md` (prompt 15 is done; replay review, Daily
  Dance, choreographer + share codes, accessibility pack, grown-up panel, stickers, World 4, pass-and-play,
  real music, GitHub Pages, Android/iOS builds, opt-in leaderboard, Spanish/Portuguese) and
  `prompts/codex/monkey-see-monkey-do-tasks.md` (10 small tasks).

## Behemoth's Mountain Lion (`apps/behemoths-mountain-lion`)
- Built from `prompts/claude/behemoths-mountain-lion.md` (8-step build order).
- Step 1 done: Desktop workspace (`OG Bars/A-Z + #`, `Remixed`, `Stems`, `Library.db`),
  SQLite index with FTS5 live search, A-Z filing (SHA-256 dedupe, verified read-only copies,
  tag + file-name auto-tagging), Bar 1/Bar 2 with type/paste-path/drag-drop, library browser,
  one-time rights notice. Bar 3, FUSE, Batch and Discoveries are laid out but not wired.
- Tests: `python -m pytest` - 24 pass (core + headless UI). Run on Windows with `run.bat`.
- Not yet run on a real Windows machine; screenshots are from a headless Linux render.
- Next: step 2 - analysis (BPM/key/sections), Demucs stems, waveforms.

## NeuroForge (not in this repo)
- Source on the Windows PC: `C:\Users\edwar\Desktop\AI and ALL\Aethertek\content poster\neuroforge`
- Live web: https://neuroforged.surge.sh and https://neuroforge.surge.sh
- App Store launch board was at step 1 of 22 (surge sign-in).
- Next: push the source to a private GitHub repo so cloud/phone sessions can read it.

## Prompts
- `prompts/claude/cosmic-saucer-drift.md` - the concept + all chosen add-ons + ads-ready layer, then
  the v2 section (real systems, alien/premium craft, power-up lineups); `cosmic-saucer-drift-next.md` -
  10 next-build prompts (phone playtest, tutorial race, 3D models, music, online leaderboards, more
  real worlds, rewarded ads, real-money purchases, online multiplayer, accessibility).
- `prompts/claude/monkey-see-monkey-do.md` - the brief + what was filled in; `monkey-see-monkey-do-next.md` -
  14 add-on/next-build prompts; `prompts/codex/monkey-see-monkey-do-tasks.md` - 10 small tasks.
- `prompts/claude/bugs-eye-view.md` - v2 with the stealth/interactivity add-ons.
- `prompts/claude/bugs-eye-view-next.md` - 10 prompts for the next features (Meshy run,
  Gem Shrine, Bathroom level, living humans, skins, debug overlay, playtest bot, sound, CI,
  store kit).
- `prompts/codex/bugs-eye-view-tasks.md` - 10 small Codex tasks.
- Tool ideas: `apps/bugs-eye-view/docs/TOOL_IDEAS.md`.
- Next: collect the rest of the new prompt set (Claude + Codex) into `prompts/`.
