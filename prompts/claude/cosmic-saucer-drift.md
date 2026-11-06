# BUILD: "Cosmic Saucer Drift" — an arcade UFO kart racer for Google Play

<!-- v1 = the owner's concept + every add-on they picked (all of them) + an
     ads-ready layer that ships switched off. -->

## Mission
Build a complete, playable, pick-up-and-play arcade kart racer called
"Cosmic Saucer Drift" in Godot 4.7 (GDScript). Players pilot customizable
UFOs around colorful, retro-futuristic space tracks: snappy steering, drifts
that charge a Plasma Boost, power-up chaos, and an energy core that has to be
kept charged. Ship it as an Android app for Google Play first, with Web,
Windows, macOS and Linux presets from the same codebase.

Originality: the game sits in the arcade kart-racer genre, but every name,
pilot, saucer, track, item and piece of art is our own. Don't copy names,
characters, tracks, art or UI from any existing racing game.

## Locked decisions
- Godot 4.7.2, GDScript, Compatibility renderer (runs on older phones and in
  the browser). 3D low-poly art built from code (procedural meshes, flat and
  emissive materials, neon glow). Art sits behind clean references so real
  models can replace it later.
- Landscape. Mobile-first budget: 8 racers, 60 fps on a mid-range phone,
  pooled effects, no per-frame allocations in hot paths, auto quality.
- Tracks are generated from data (a closed spline + width, banking, surface
  and feature lists), so variants (reverse, mirror) and new tracks are cheap.
- Free, no ads, no data collected in v1 — but with an ads-ready layer
  (see "Ads-ready layer") that can be switched on in a later update.

## Core architecture (autoloads)
- InputRouter: per-player game actions (steer, throttle, brake, drift/trick,
  item, look back, pause). Touch buttons, tilt, keyboard, gamepad all feed
  it; gameplay never reads raw input. Supports two local players.
- Game: the race request (mode, track, variant, racers, cup state) and scene
  flow.
- Save: user:// save of Stardust, unlocks, upgrades, cosmetics, stars, best
  times, ghosts, achievements, stats, daily streak, settings.
- Audio: SFX + music buses; engine sound per saucer.
- Ads: provider interface + placements + caps + consent hooks (off in v1).
- Events: local game-event log with a provider hook for future analytics /
  ad-campaign conversion events (no network in v1).

## Handling & physics (the arcade feel)
- Custom hover kinematics (not a wheeled vehicle): hover spring over the
  track, align to the surface, arcade grip model (forward speed + lateral
  slip damped by grip).
- Drifting: hold Drift while turning to slide; the drift charges the Plasma
  Boost meter through three spark levels (blue / orange / purple). Release to
  boost, bigger per level.
- Terrain: metal decking (high grip), moon dust (slower, loose), comet ice
  (very slippery), magnetic neon rails (fast, locked to the line), bouncy
  jungle moss, lava rock. Each changes grip, drag and effects.
- Low-gravity zones and jumps with real air time.

## Dark Matter energy
- The core drains slowly while racing (stat: Energy Efficiency). Energy Pods
  on the track refill it; tricks, near misses and slipstreaming add more.
- Empty core = Emergency Hover: much lower top speed and acceleration until
  you grab a pod. Clear HUD warning; AI follows the same rules.

## Power-ups (8) from glowing space crates
Tractor Beam (drags the racer ahead back), Meteor Strike (falls on the
leader, with a warning shadow), Ion Shield (temporary invulnerability),
Hyperspace Warp (teleport-dash forward), Plasma Bolt (homing shot), Gravity
Mine (dropped behind), Nebula Cloud (smears the screens of racers ahead),
Black Hole (vortex that drags nearby racers in). Item odds depend on race
position. Every hit telegraphs and causes a short spin-out, never a long
stop.

## Pro driving moves
Start-line boost (accelerate right on GO; too early stalls), three-level
drift boosts, slipstream drafting, mid-air trick spins off jumps (land a
trick = boost + energy; land mid-trick = wobble), near-miss energy bonus.

## Tracks (6) + variants
1. Asteroid Belt — tight turns, tumbling space rocks, low-gravity jumps.
2. Neon Ring of Saturn — high-speed magnetic rail sections, planet backdrop.
3. Alien Jungle Moon — bouncy moss, snapping alien plants, geysers that
   launch you onto a shortcut.
4. Comet Ice Run — slippery ice trail, ice shards, crystal tunnel.
5. Orbital Station — metal decking, low-gravity tubes, sweeping lasers.
6. Lava Moon — dust dunes and eruptions that close lanes in turn.
Living tracks: moving hazards per track, one hidden shortcut per track,
3 hidden Star Shards per track. Reverse and Mirror versions of every track
unlock after you win on it.

## Pilots (8) — passive ability + driving personality
Each pilot has a passive (e.g. faster drift charge, free shield at the start,
slower energy drain, item luck, pod magnet, trick bonus, slipstream pro,
heavy bumper) and an AI personality (aggressive rammer, item hoarder, clean
racing line). Two pilots to start; beat the others in 1-on-1 boss races.

## Saucers, upgrades & cosmetics
- Six chassis: Classic Saucer, Bubble Pod, Rocket Fin, Ring Racer, Manta,
  Mothership Jr. Stats: Top Speed, Acceleration, Handling, Energy
  Efficiency (+ hidden weight).
- Upgrades: five levels per stat per saucer, bought with Stardust.
- Cosmetic garage: paints, decals, dome tints, engine trails (looks only).

## Modes
Quick Race, Galactic Cups (4 cups x 4 races, points, 3 stars per race: top 3,
win, and a race challenge), Time Trial with a ghost of your best run and
bronze/silver/gold medals, Boss Races, Daily Challenge (date-seeded, works
offline, streak reward), local 2-player split-screen.

## Achievements & stats
In-game achievements (drift distance, wins, tricks, energy feats...) with
Stardust rewards and a career stats page.

## Ads-ready layer (off in v1)
- Ads autoload with an AdProvider interface: Null (v1), Debug (fake ad screen
  for testing flows in debug builds), and a documented AdMob template.
- Placements wired into the UI but hidden while disabled: rewarded "double
  Stardust" on the results screen, rewarded "free item at the start" before a
  race, interstitial between cup races (frequency capped, never in the first
  session or the first N races).
- Consent/UMP hook, child-directed and max-content-rating settings, a
  "remove ads" entitlement flag for a later purchase.
- Events autoload: race_start, race_finish, cup_complete, tutorial_complete,
  unlocks, purchases — for future analytics and campaign conversion events.
- Docs: how to switch ads on, Play Data safety answers now and after ads.

## UI
Title, main menu, mode select, track select (with variants), garage, pilot
select, cups, results, achievements, stats, settings (volume, steering mode
touch/tilt, auto-accelerate, sensitivity, haptics, quality, camera), pause.
HUD: position, lap, time, energy cells, plasma meter, item slot, minimap,
countdown, wrong-way, emergency warning, toasts. Touch controls show on
touchscreens only.

## Ship prep
Icons, splash, Android APK (debug) + AAB preset, Web build, store kit (listing
text, feature graphic, screenshots, privacy policy, Data safety answers,
content rating notes), RUN.md, automated tests (boot, race sim with AI
finishing every track and variant, items, energy, save round trip, ads flow).

## Phases (commit and push after each)
1. Driving slice: project, input, saucer physics, drift + boost, surfaces,
   energy, one track, AI racers, laps/positions, camera, basic HUD.
2. Combat: crates + all 8 items, hits, shields, AI item use, pro moves.
3. Tracks: all 6 tracks, hazards, shortcuts, Star Shards, variants, minimap.
4. Pilots & modes: pilots, personalities, boss races, cups, time trial +
   ghost, daily challenge, split-screen.
5. Meta & shell: save, garage, upgrades, cosmetics, achievements, stats,
   menus, settings, audio, haptics, ads-ready layer, events.
6. Ship: icons, store kit, exports, performance pass, tests, APK + web build.

---

## v2: real planets, alien spacecraft, premium craft, power-up lineups

The owner's follow-up: "Create this around different planets and solar
systems that we found in real life. Use different alien spacecraft and add
premium vehicles for purchase and to gain enough race credits to unlock.
Add power-ups like rockets, lasers etc. 5-7 line-ups of power-ups to help
you become first." Choices made:

- **Systems = cups, planets = tracks**, each with real fact cards, the real
  star(s) in the sky and gravity tuned per world:
  - Our Solar System: Mars (Valles Marineris), Ceres & the Asteroid Belt,
    Io, Saturn's Rings.
  - TRAPPIST-1: 1b (scorched inner world), 1e (habitable-zone world with
    imagined alien life), 1h (frozen outer world).
  - Alpha Centauri: Proxima b (flare star), Proxima Station, Twin Suns
    circuit (Alpha Centauri A & B).
  - Exoplanet extremes: HD 189733 b (blue, supersonic winds, possible glass
    rain), 55 Cancri e (lava world), Kepler-16b (two suns), WASP-76 b
    (possible iron rain).
  - Galactic Grand Prix finale cup (reverse/mirror mix).
- **Spacecraft:** 14 craft = the 6 saucers + 4 new alien designs (Orb Drone,
  Crystal Shard, Bio-Ship, Arrowhead Interceptor) + 4 premium craft (Solar
  Sail Yacht, Pulsar Phantom, Quasar Dragon, Dyson Racer) with unique perks.
- **Race Credits** replace Stardust. Premium craft: earnable with credits now;
  a real-money store layer (Google Play Billing) is built in and switched
  off, like the ads layer.
- **Power-ups (20):** Homing Rocket, Pulse Laser, Comet Strike, EMP
  Shockwave, Nitro Rocket (1-3 uses), Ion Shield (also blocks one hit while
  held), Gravity Mine, Tractor Beam, Warp Jump, Decoy Drone, Energy Leech,
  Gravity Well, Frost Trail, Overcharge, Solar Flare, Chain Lightning,
  Plasma Wall, Stasis Field, Phase Cloak, Repulsor Pulse. Arranged into **5 lineups by race
  position** (Leader, Front pack, Midfield, Chasers, Last place): the
  further back you are, the stronger the comeback items; leaders get the
  traps and decoys.

---

## v3: HD graphics, characters and gameplay fine-tune

The owner's follow-up: "Upgrade all graphics, gameplay and detail in
characters with high resolution and fine tuning the detail." Choices made:
all four upgrade packs, automatic graphics tiers, polished cartoon style.

- **Craft & pilots in HD:** rebuild all 14 craft with smooth bevelled hulls,
  panel seams, lights, vents and engine glow. Every alien pilot gets its own
  face (eyes that blink and look around), expressions (grin on boost, dizzy
  when hit, cheer on a win) and a suit/helmet or accessories.
- **Worlds & lighting:** real-time shadows, high-detail procedural surfaces
  (plated road, rock, ice, lava), detailed scenery per planet, richer skies
  (nebulae, glowing atmospheres), haze.
- **Effects & camera feel:** engine flames, brighter drift sparks, boost
  shockwave, speed lines, impact flashes, landing dust, a tuned chase camera
  with speed-based field of view.
- **Gameplay fine-tune:** handling and drift timing, AI difficulty per class
  with fairer catch-up, power-up balance, smoother respawns, a better start
  and finish.
- **Phones:** Low/Medium/High/Ultra tiers; Auto picks from the device and
  steps down live; Ultra/High add anti-aliasing, shadows and reflections.
- **Style:** polished cartoon: bright and friendly, with more detail and
  shine.
