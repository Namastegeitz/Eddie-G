# Cosmic Saucer Drift: next build prompts (Claude Code)

Copy one prompt at a time into a Claude Code session on this repo. Each is
self-contained. They build on the game as it is now (Godot 4.7,
`apps/cosmic-saucer-drift`), roughly in the order players would feel them.

Rules that apply to every prompt (paste once at the top of a session, or keep
them in a `CLAUDE.md`):

```
You're working on Cosmic Saucer Drift in apps/cosmic-saucer-drift (Godot 4.7, GDScript).
- Content is data: saucers/pilots/items/cups in scripts/data/catalog.gd, tracks in
  scripts/data/track_defs.gd (features placed by control-point index), driving
  numbers in resources/tuning.tres. Art is generated from code.
- Every new feature gets checks in tests/smoke.gd; tools/run_tests.sh must stay
  green (parse check, smoke test, AI race sim on all 18 track layouts).
- Phones first: keep game logic under ~1.5 ms per physics tick on this machine
  (sim --prof), pooled effects, no per-frame allocations in hot paths.
- Keep the game original: no names, characters, tracks or art from other racing games.
- Ads stay behind the Ads autoload; v1 promises "no ads, no data collected".
- Update RUN.md / README.md / docs for anything players or I need to know.
```

---

## 1. Playtest pass on a real phone (do this first)

```
I installed dist/android/cosmicsaucerdrift-debug.apk on my phone. Here's what
felt off: <list>. Tune the driving model (resources/tuning.tres), the touch
button sizes and the camera from my notes, then add a "Handling" section to
Settings with steering sensitivity and drift assist (auto-drift when you hold a
corner) for younger players. Re-run the sim so the AI still finishes everywhere.
```

## 2. A proper first-race tutorial

```
Replace the how-to-play card with a guided first race on the Asteroid Belt:
short prompts appear at the right moments (first corner: "Hold DRIFT"; first
pod row: "Grab Energy Pods"; first crate; first ramp: "Press DRIFT in the air
to trick"), the AI is slowed, and the race can't be lost. Fire
Events "tutorial_complete" at the end. Skippable, and replayable from Settings.
```

## 3. Real 3D models

```
Swap the primitive saucers, pilots, crates, pods and hazards for real low-poly
models. Add a model slot per piece (like SaucerModel parts) that falls back to
the current primitives when no model file exists, so the game always runs.
Write prompts for a text-to-3D tool for each slot in tools/models/assets.json,
keep every model under 3k triangles, and add screenshots of each next to its
placeholder.
```

## 4. Music and sound with more character

```
The sounds are synthesised placeholders (tools/gen_audio.py). Add one music
track per world (6) that loops cleanly, an announcer-style voice line set
("3, 2, 1, GO!", "Final lap!", "Purple boost!") made with a TTS tool, and
per-saucer engine sounds. Keep the web build under 60 MB.
```

## 5. Online leaderboards and ghost sharing

```
Add optional online time-trial leaderboards (per track and variant) and
downloadable ghosts of the top times, using Supabase. Players pick a
nickname; nothing else is collected. Everything must still work offline. Add
a "connect" toggle (default off), update docs/privacy-policy.html and the
Data safety answers in docs/STORE_LISTING.md, and keep the server key out of
the repo.
```

## 6. Season pass of new tracks

```
Add three tracks built with the track_defs format: a "Black Hole Rim" with
gravity that pulls you toward the inside lane, a "Space Carnival" with spinning
loop-the-loops and bumpers, and a "Meteor Highway" with a moving convoy of
asteroids. Each needs its hazards, shortcut, 3 Star Shards and a new fifth
cup. Plot each with tools/plot_tracks.py and make the AI finish all variants.
```

## 7. Turn on rewarded ads (when you're ready)

```
Follow docs/ADS_PLAN.md: add the Godot AdMob plugin, wire
scripts/ads/admob_ad_provider.gd to it with Google's test IDs, add the UMP
consent flow and a "Privacy options" button in Settings, switch the AAB preset
on, and update the privacy policy and Data safety answers. Rewarded only at
first (double Stardust, free item); keep the cup interstitial off.
```

## 8. "Remove ads" and a Stardust starter pack

```
Add Google Play Billing with a Godot billing plugin: a non-consumable
"Remove ads" (calls Ads.set_removed(true), restores on reinstall) and an
optional one-time "Starter pack" (Stardust + a cosmetic). Purchases go through
a Store autoload that stays a no-op on web/desktop. Log Events "purchase".
```

## 9. Online multiplayer (big)

```
Add online races for up to 8 players using Godot's high-level multiplayer
(ENet or WebRTC) with a small relay/lobby server. Host-authoritative racing,
client-side prediction for your own saucer, interpolation for others, items
resolved by the host. Start with private lobbies by code, then quick match.
Keep split-screen and offline modes untouched.
```

## 10. Accessibility and comfort

```
Add: colour-blind friendly item and drift-spark colours (shape cues too),
larger HUD option, reduced-motion option (no screen shake, softer FOV kick,
no speed streaks), one-button mode (auto-steer along the racing line; the
player only drifts and fires items), and subtitles for any voice lines.
```
