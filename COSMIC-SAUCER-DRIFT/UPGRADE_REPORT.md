# **COSMIC SAUCER DRIFT** · Upgrade report (run of 27 Nov 2026)

Run of Eddie's *Universal Upgrade + Release Build Prompt (Apps + Games)*.
- **Branch:** `upgrade/2026-11-27`
- **Start commit tag:** `pre-upgrade-2026-11-27` (roll everything back with
  `git checkout pre-upgrade-2026-11-27`)
- **Rules:** every change is additive, behind a setting where it changes behaviour,
  tested, and committed per step.

No `UPGRADE_LEDGER.md` existed, so this is the first run.

## Baseline (Step 1, measured 27 Nov 2026 before any change)

**What it is.** A game: an arcade UFO kart racer.
- **Engine:** Godot **4.7.2 stable**, GDScript only, no third-party add-ons.
- **Renderer:** Compatibility (OpenGL / WebGL 2) on every platform.
- **Targets:** Android (Google Play, Galaxy Store, Amazon Fire), iOS/iPadOS (App Store),
  Windows/macOS/Linux (Steam, itch.io, GOG, Epic, Microsoft Store) and the web.
- **No backend, no accounts, no ads, no purchases, no analytics.** Saves stay on the device.
- **No AI agents inside the game.** Rival racers are scripted.

**Measured on this build machine.** It's a cloud computer with a *software* GPU (Mesa
llvmpipe), so frame rates are only comparable between runs here, not with phones.

| Measure | Medium graphics | High graphics |
|---|---|---|
| Benchmark | `tests/bench.tscn`, Io, 600 frames, autopilot race | same |
| Average frame time | 70.5 ms (14.2 fps) | 261.3 ms (3.8 fps) |
| 1% low | 10.6 fps | 3.0 fps |
| Worst spike | 186 ms (2 frames over 2× average) | 360 ms (0 over 2×) |
| CPU game logic per frame | process 77 ms, physics 7.3 ms | process 274 ms, physics 2.4 ms |
| Draw calls / objects per frame | 151 / 261 | 349 / 470 |
| Memory | 103 MB static, 57 MB video | 104 MB static, 74 MB video |

| Measure | Value |
|---|---|
| Cold start to the 3rd frame (Linux export) | 2.7–3.1 s (includes ~0.3 s to start the virtual display) |
| Main menu build | 244 ms |
| Race build (CPU) | 381–392 ms. By stage: racers 116, views 107, track 100, systems 26, data 17, decor 9 |
| Automated tests | **1,141 / 1,141** smoke checks pass, plus the AI race sim, 11 asset-pipeline checks and the drive check (0 s in reverse) |
| Build warnings | None while running. At exit: 2 Godot objects and 1 resource still alive (13 objects in the load probe) |
| Build sizes | Android APK 61.6 MB · web 46.6 MB (engine 37.7 + game data 6.9) · Windows 42.3 MB zip · Linux 33.1 MB zip · macOS 64.6 MB zip · iOS Xcode project 100 MB (2 zip parts) |
| Dependencies | Godot 4.7.2 engine and export templates only. Build tools use Python 3 + Pillow (not shipped). No known vulnerabilities in shipped code (no third-party code is shipped) |
| Crash / ANR rate | Unknown: the game isn't live yet and has no crash reporting |

### Top 10 weaknesses, by how much players would feel them

1. **Crashes on real devices would be invisible.** There's no crash reporting, so a crash on
   one phone model would only show up as 1-star reviews.
2. **Real-phone speed is unverified.** Every number above is from a software renderer. There's
   no low/mid/high phone check yet. Dynamic resolution and Auto graphics exist, but nothing
   proves they hold 60 fps.
3. **Accessibility gaps:**
   - no colour-blind option (items, rival markers and energy are told apart by colour)
   - no reduce-motion switch for speed lines and flashes (camera shake has one)
   - no text-size option
   - no control remapping
4. **English only.** All text is written straight into the code, so nothing can be
   translated yet.
5. **No way for players to send feedback or rate the game from inside it.** The checklist
   page collects bugs for Eddie only.
6. **No automatic build and test (CI).** Tests and exports run by hand, and a release can't yet
   be rebuilt automatically from a git tag.
7. **Graphics ceiling.** Compatibility is the only renderer, so High/Ultra can't use upscaling,
   ambient occlusion or screen-space reflections on phones and PCs that could run them.
8. **The web version is a 47 MB first download** (38 MB of it engine), which is slow on mobile data.
9. **Unsigned desktop builds:** Windows SmartScreen and macOS Gatekeeper warnings. The Play
   bundle isn't built yet because it waits on Eddie's upload key.
10. **Objects left alive at exit.** It's harmless today, but it makes real leaks harder to spot
    in tests.

Also open: 9 of the 10 HD Meshy craft are still waiting for credits. That's content, not quality.
