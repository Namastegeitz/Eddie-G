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
- 200 maps: 20 real rainforest scenes x 10 levels (40 to 130 rows each), plus 2 coming soon.
  Two views: bird's-eye (2D) and first person (3D, eye button / V). Every level has dense-canopy
  zones that hide the ground from above, so first person is needed to cross them.
- Data-driven: 50 animals, 87 hazards, 22 maps (20 playable + 2 coming soon), 3 lane generators,
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
- Art/audio: procedural chibi animals and hazards, per-region palettes and canopy framing, dot
  globe from Natural Earth, synthesised per-region music + ambience + 26 SFX (`tools/gen_audio.py`).
- Ads: opt-in rewarded + between-run interstitial (mock; AdMob adapter scaffold). Analytics: events
  + onboarding funnel to `user://analytics.jsonl`, optional HTTP endpoint.
- Tests: `tools/run_tests.sh` - compile check + 309-check phase audit (one section per phase's
  checkpoint) in the project and an exported pack, all passing. A path-finding bot beats all 200
  levels (tools/level_sweep.tscn, ~2 min) and the first 50 Endless rows on every scene with the free Poison Dart Frog.
  Frame cost 0.9 ms (sim + view + draw recording) on the cloud CPU.
- Playable web build (private artifact): https://claude.ai/artifact/NHzAQ2w4jCjWjLkoxLSdB3
  Gameplay clip: `apps/canopy-crossing/docs/gameplay.mp4`.
- Not done here: signed Android/iOS builds (need Android SDK + keystore, Mac/Xcode), real store
  sandbox purchases, real ads, on-device 60 fps check (Settings > Show FPS counter), playtesting.
- Next: playtest difficulty with people, real art pass (sprites drop in via `"sprite"` in files),
  Android AAB + Play internal track with GodotGooglePlayBilling, iOS via a Mac or Codemagic.

## Cosmic Saucer Drift (`apps/cosmic-saucer-drift`)
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
- Power-ups (8): Homing Rocket, Pulse Laser, Comet Strike, EMP Shockwave, Nitro Rocket (1-3 uses), Ion
  Shield (use or hold to block one hit), Gravity Mine, Tractor Beam, in 5 lineups by place.
- Real-money store layer (`Store` autoload, debug + Play Billing template, products for premium craft,
  fleet bundle, credit packs, remove ads) built and switched off: `docs/STORE_PLAN.md`. Ads layer as
  before: `docs/ADS_PLAN.md`. v1 listing stays "no ads, no purchases, no data collected".
- Tests: `tools/run_tests.sh` - parse check, smoke test (~600 checks incl. live power-up tests, perks,
  store flow, save migration) and the AI race sim on all 42 layouts.
- Builds: debug APK in `dist/android/` (signed with `tools/android/apksigner`, a small APK Signature
  Scheme v2 signer, because Google's build-tools download is blocked here); web build published as a
  private artifact: https://claude.ai/artifact/Wjris6Pjst5K54bF6z8MUY
- Store kit: `docs/STORE_LISTING.md`, feature graphic, icon and screenshots in `docs/store/`,
  `docs/privacy-policy.html`, `docs/STORE_EXPORT_CHECKLIST.md`.
- Not done here: Play Store AAB (needs the real Android SDK + Gradle on the PC), testing on a real
  phone, real 3D models/music. Next prompts: `prompts/claude/cosmic-saucer-drift-next.md`.

## Bug's-Eye View (`apps/bugs-eye-view`)
- Built end to end from `prompts/claude/bugs-eye-view.md` (all 6 phases, all 16 add-ons).
- Godot 4.7.2 project: 8 bugs, 3 rooms with boss chases, perception-based stealth,
  escalation chain, daily routines, colony upgrades, menus, touch/keyboard/gamepad.
- Tests: `tools/run_tests.sh` - 165-check smoke test + 359-check phase audit + offline
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
- Graphics and motion upgrade: generated high-res surface textures with bump maps (tiles,
  wood, flagstones, grass, carpet, fabric, denim, fur, bug shells; `tools/generate_textures.py`),
  rounder models, eyes that move and blink; motion smoothed between physics steps; people walk
  heel-to-toe and glide, sway, breathe, glance, double-take; pets ease into runs, pant, blink;
  forgiving jumps; camera eases around walls; High/Medium/Low rendering tiers.
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
- Not verified on real hardware yet: touch feel and audio latency on an actual phone, install to home screen.
- Next: pick add-ons from `prompts/claude/monkey-see-monkey-do-next.md` (prompt 15 is done; replay review, Daily
  Dance, choreographer + share codes, accessibility pack, grown-up panel, stickers, World 4, pass-and-play,
  real music, GitHub Pages, Android/iOS builds, opt-in leaderboard, Spanish/Portuguese) and
  `prompts/codex/monkey-see-monkey-do-tasks.md` (10 small tasks).

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
