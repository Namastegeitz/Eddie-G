# Cosmic Saucer Drift

Arcade UFO kart racing across real planets and star systems. Android
(Google Play first), plus Web, Windows, macOS and Linux from the same Godot
4.7 project. Pick-up-and-play handling, drifts that charge a Plasma Boost,
eight power-ups, alien spacecraft, and a Dark Matter core you have to keep
charged.

Built from [`prompts/claude/cosmic-saucer-drift.md`](../../prompts/claude/cosmic-saucer-drift.md)
(v1 concept + every add-on chosen, then v2: real systems, alien spacecraft,
premium craft, power-up lineups). Next steps:
[`prompts/claude/cosmic-saucer-drift-next.md`](../../prompts/claude/cosmic-saucer-drift-next.md).

![Real worlds](docs/screenshots/worlds.png)

## Real places

Each cup is a real star system and each track a real planet or moon, with
three fact cards (shown on track select, during the countdown, in pause and
on the results screen), the real star(s) drawn in the sky and gravity tuned
per world (Mars and Io float you further off jumps; 55 Cancri e is heavier).
Where science is unsure, the game says "may"; where the game makes things up
(TRAPPIST-1e's plants, Proxima Station) it says so.

| Cup | Tracks |
|---|---|
| Our Solar System | Mars: Valles Marineris · Ceres & the Asteroid Belt · Io: Volcano Moon · Saturn's Rings |
| TRAPPIST-1 (40 ly) | 1b Scorched World · 1e Twilight Garden · 1h Frozen Edge |
| Alpha Centauri (4.2-4.4 ly) | Proxima b: Flare Run · Proxima Station · Twin Suns circuit |
| Exoplanet Extremes | HD 189733 b: Blue Storm (supersonic winds, glass rain) · 55 Cancri e: Lava Planet · Kepler-16b: Two Sunsets · WASP-76 b: Iron Rain |
| Galactic Grand Prix | finale: reverse and mirror tracks from every system |

Every track has moving hazards (tumbling asteroids, Martian dust devils and
dust storms, solar flares, station lasers, snapping alien plants, geysers,
falling ice/glass/iron, lava eruptions, supersonic gusts), one hidden
shortcut, three Star Shards, and Reverse + Mirror versions that unlock when
you win it: 14 tracks, 42 layouts.

## Power-ups and lineups

Eight power-ups from glowing crates: **Homing Rocket**, **Pulse Laser**
(instant beam that hits everything in a line and clears mines), **Comet
Strike** (falls on the leader), **EMP Shockwave** (spins out everyone near you
and knocks their items loose), **Nitro Rocket** (1-3 boosts), **Ion Shield**
(use it for 6 s of protection, or just hold it to block one hit), **Gravity
Mine** and **Tractor Beam**.

What you can pull depends on your place, in five lineups: Leader (mostly
defence and mines), Front pack, Midfield, Chasers, Last place (Nitro x3,
Comet Strike, EMP). The further back you are, the stronger the comeback
items. Listed in-game under How to Play.

## Spacecraft

14 craft: the Classic Saucer, Bubble Pod, Rocket Fin, Ring Racer, Manta and
Mothership Jr, four new alien designs (Orb Drone, Crystal Shard, Bio-Ship
that slowly heals its core, Arrowhead Interceptor), and four **premium**
craft with perks: Solar Sail Yacht (boosting recharges your core), Pulsar
Phantom (shorter spin-outs), Quasar Dragon (longer drift boosts), Dyson Racer
(pods refill 50% more). Everything is unlocked with **Race Credits** earned
in races (premium craft cost 12,000-22,000 and need stars). Four stats to
upgrade per craft, plus paints, decals, domes and trails.

A **real-money store** is built in and switched off (premium craft, a
premium fleet bundle, credit packs, remove ads), ready for Google Play
Billing in an update: [`docs/STORE_PLAN.md`](docs/STORE_PLAN.md). Ads are
built in and switched off too: [`docs/ADS_PLAN.md`](docs/ADS_PLAN.md). v1
has no ads, no purchases and collects no data.

## Also

Drifting with blue/orange/purple Plasma Boosts, rocket starts, slipstream,
tricks off ramps/geysers/bouncy moss, near-miss energy, 8 alien pilots with
passives and boss races, Galactic Cups with 3 stars per race, Quick Race,
Time Trial with your ghost and medals, Daily Challenge with streaks (works
offline), 2-player split-screen, 26 achievements, career stats, touch/tilt/
gamepad/keyboard controls, automatic graphics step-down on slow phones.

## Folders

```
project.godot, export_presets.cfg
autoload/        Save, InputRouter, Events, Ads, Store, Audio, Game
scripts/data/    Catalog (craft, pilots, items, lineups, systems, cups, cosmetics), TrackDefs, Tuning, Achievements
scripts/track/   TrackPath, TrackData (variants, features), TrackBuilder (meshes), TrackDecor, Themes (skies, suns)
scripts/race/    Race, Racer (physics), AIDriver, PlayerDriver, Items, Pickups, Hazards, RaceCamera, SaucerModel, RaceAudio
scripts/ui/      MainMenu, MenuStage, Hud, TouchControls, Minimap, ResultsScreen, PauseMenu, UiKit, ItemIcon
scripts/ads/     AdProvider, DebugAdProvider, AdMobAdProvider (template), AdsConfig
scripts/store/   StoreProvider, DebugStoreProvider, PlayBillingStoreProvider (template), StoreConfig
shaders/         road, sky (with suns), planet, ring, ground, boost pad, spin
resources/       tuning.tres, ads_config.tres, store_config.tres
assets/          audio (generated), icons
tests/           sim (AI races on all 42 layouts), smoke (~600 checks), shots, menu_shots
tools/           run_tests.sh, gen_audio.py, dump/plot tracks, android/apksigner, web_artifact
docs/            store kit, ads + store plans, privacy policy, checklist, screenshots
dist/android/    debug APK to sideload
```

How to run, test and export: [RUN.md](RUN.md).
