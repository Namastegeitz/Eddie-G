# Running Cosmic Saucer Drift

Godot **4.7.2** (standard build, not .NET). Everything below runs from this
folder (`apps/cosmic-saucer-drift`).

## 1. Play it

- **Android phone:** download `dist/android/cosmicsaucerdrift-debug.apk` from
  GitHub on the phone, open it, and allow installs from that source. It's a
  debug build signed with a debug key: fine for testing, not for the store.
- **Browser:** the web build in `build/web` (or the packaged
  `build/web_artifact`) runs from any static web server:
  `python3 -m http.server -d build/web 8000`, then open
  <http://localhost:8000>.
- **Editor:** download Godot 4.7.2 from <https://godotengine.org/download>,
  *Import* `apps/cosmic-saucer-drift/project.godot`, press **F5**.

## 2. Controls

| Action | Keyboard | Gamepad | Touch |
|---|---|---|---|
| Steer | A / D or arrows | Left stick / d-pad | ◀ ▶ buttons, or tilt (Settings) |
| Gas | W / Up | RT or A | Automatic (Settings: Auto-accelerate) |
| Brake / reverse | S / Down | LT or B | BRAKE |
| Drift (in the air: trick) | Space or Shift | RB | DRIFT (shows TRICK in the air) |
| Use item | E, Ctrl or F | X or LB | ITEM |
| Look back | Q or C | Y | - |
| Pause | Esc or P | Start | II (top right), Android back |

**2 players** (split screen, top and bottom): P1 = WASD, Space drift, E item,
Q look back. P2 = arrows, `/` or Right Ctrl drift, `.` or Enter item, `,` look
back. With two gamepads each player gets one; with one gamepad it goes to P2.

## 3. How a race works

- **Drift** with DRIFT + steer. Sparks: blue (34%), orange (67%), purple
  (100%). Let go to boost: 0.55 s / 0.95 s / 1.5 s.
- **Rocket start:** press gas in the last half second before GO. Holding it
  from "3" stalls the engine for a moment.
- **Energy:** the core drains about 1.45/s at full throttle (less with a
  higher Energy Efficiency stat or Gloop). Pods +14, tricks +8, near misses +4,
  slipstream +4. Empty = Emergency Hover (55% top speed) until a pod.
- **Tricks:** press DRIFT while airborne (ramps, geysers, moss hops). Landing
  a finished trick gives a 0.9 s boost and energy; landing mid-spin wobbles.
- **Falling off** a gap or edge brings a rescue beam that puts you back
  (past any gap ahead) after about a second.
- **Shortcuts:** each track has one. TRAPPIST-1e's is a sky bridge: line up
  with the geyser on the straight before the big right-hander.

Unlocks: tracks open with their cup (star systems: Solar System from the
start, then TRAPPIST-1 at 8 stars, Alpha Centauri at 16, Exoplanet Extremes
at 24, the Galactic Grand Prix at 36); Reverse and Mirror open when you win
the Normal track; craft need stars + Race Credits (premium craft 12,000-22,000
credits); boss pilots need stars, then a 1-on-1 win.

Power-ups depend on your place (five lineups: Leader, Front pack, Midfield,
Chasers, Last place). Nitro Rocket comes with 1-3 uses; a held Ion Shield
blocks one hit; the Pulse Laser fires straight ahead, so aim it.

## 4. Tests

```
tools/run_tests.sh
```

runs: parse check of every script, the **smoke test** (`tests/smoke.tscn`:
data integrity for all 42 track layouts, facts, lineups, craft and store
products, the power-ups in a live race (laser, EMP, held shield, nitro uses,
homing rocket), premium perks, the store layer with the debug provider, the
Stardust-to-Race-Credits save migration, the v3 graphics (all four quality
tiers, the mesh toolkit, all 14 craft built and animated at every tier, every
pilot's eyes, lids, mouths and moods, pooled effects, per-race quality
switching, camera landing dip, AI catch-up bands), save round trip, unlock rules, every
challenge and daily goal, the ads layer with the debug provider, achievements,
full races in every mode including a 4-race cup, time trial ghost, boss,
daily, 2-player split-screen, mirror, pause, and every menu screen), and the
**race simulator** (`tests/sim.tscn`: 8 AI saucers race every track in all
three variants (42 layouts); fails if anyone doesn't finish or gets stuck).

Other tools:

```
# AI races with logic timing per subsystem
godot --headless --path . res://tests/sim.tscn --fixed-fps 60 -- --laps=3 --variants=0,1,2 --prof
# Screenshots (needs a display; on a server use xvfb-run)
xvfb-run -a godot --path . res://tests/shots.tscn --rendering-driver opengl3 -- --frames=600 --out=docs/screenshots
xvfb-run -a godot --path . res://tests/menu_shots.tscn --rendering-driver opengl3 -- docs/screenshots [garage,pilots,settings]
# Every craft (3/4 view) and every pilot's face in four moods; --quality=low|medium|high|ultra
xvfb-run -a godot --path . res://tests/craft_shots.tscn --rendering-driver opengl3 -- --out=docs/screenshots/craft --mode=all
# Race shots at a given graphics tier
xvfb-run -a godot --path . res://tests/shots.tscn --rendering-driver opengl3 -- --tracks=mars --frames=300 --quality=ultra
# Top-down maps of every track layout
godot --headless --path . --script res://tools/dump_tracks.gd
python3 tools/plot_tracks.py "<user data dir>/tracks_dump.json" tracks.png 0
# Regenerate the sounds and music
python3 tools/gen_audio.py
# Regenerate icons from icon.svg
godot --headless --path . --script res://tools/make_icons.gd
```

Before publishing a web build, also run `tools/web_tap_test.sh` (after
packaging it, see Export): it opens the build in headless Chromium as a
phone, taps the title screen and checks the menu opened. It caught a bug the
engine-level tests can't see: real taps on the title were swallowed by the
menu's controls, so the game never started on phones.

## 5. Export

```
godot --headless --path . --export-debug   "Android"         build/android/cosmicsaucerdrift.apk
godot --headless --path . --export-release "Android AAB"     build/android/cosmicsaucerdrift.aab
godot --headless --path . --export-release "Web"             build/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/windows/CosmicSaucerDrift.exe
godot --headless --path . --export-release "macOS"           build/macos/CosmicSaucerDrift.zip
godot --headless --path . --export-release "Linux"           build/linux/CosmicSaucerDrift.x86_64
godot --headless --path . --export-release "iOS"             build/ios/CosmicSaucerDrift.ipa
```

- Android (APK, debug or release): Godot needs a JDK (17+) and an Android
  SDK with `build-tools` in *Editor Settings > Export > Android*. On a
  machine that can't download Google's build-tools, `tools/android/apksigner`
  is a small stand-in signer (APK Signature Scheme v2): put it at
  `<sdk>/build-tools/35.0.0/apksigner` and an empty `<sdk>/platform-tools/`.
  That's how the debug APK in `dist/` was made.
- **Google Play needs the AAB** from the *Android AAB* preset, which uses a
  Gradle build and the real Android SDK: see
  [docs/STORE_EXPORT_CHECKLIST.md](docs/STORE_EXPORT_CHECKLIST.md).
- Web for size-capped hosts: `python3 tools/web_artifact/package.py build/web build/web_artifact`
  splits the engine into three parts and adds a loader page.

## 6. Change the game

- Driving numbers: `resources/tuning.tres` (open in the editor's inspector).
- Craft, pilots, power-ups, lineups, star systems, cups, challenges,
  cosmetics, rewards: `scripts/data/catalog.gd`.
- Tracks: `scripts/data/track_defs.gd`. Points are a closed loop; features
  are placed by control-point index (`"at": 10.5` = halfway between points 10
  and 11) so they stay put when you move points, and flip automatically for
  Reverse and Mirror. Plot the result with `tools/plot_tracks.py`, then run
  the simulator to check the AI can race it.
- Looks per world (sky, suns, planets, scenery): `scripts/track/themes.gd`.
  Real facts per track: `facts` in `track_defs.gd`.
- Real-money store: `resources/store_config.tres` and [docs/STORE_PLAN.md](docs/STORE_PLAN.md).
- Ads: `resources/ads_config.tres` and [docs/ADS_PLAN.md](docs/ADS_PLAN.md).
- Graphics tiers (what Low/Medium/High/Ultra turn on, how Auto picks):
  `scripts/gfx/gfx.gd`. Craft designs: `scripts/race/saucer_model.gd` (one
  function per craft, built from `MeshKit` lathe profiles and rounded
  shapes). Pilot faces, outfits and moods: `scripts/gfx/pilot_model.gd`
  (`LOOKS` per pilot). Check changes with `tests/craft_shots.tscn`.
- AI difficulty and catch-up: `AI_CLASSES` in `scripts/data/catalog.gd`
  (`band` = how much the AI eases off when ahead of you / speeds up when
  behind).
