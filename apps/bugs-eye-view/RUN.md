# Running Bug's-Eye View

Godot **4.7.2** (standard build, not .NET). Everything below runs from this
folder (`apps/bugs-eye-view`).

## 1. Open it in the editor

1. Download Godot 4.7.2 from <https://godotengine.org/download> and unzip it.
2. Start Godot, choose **Import**, and pick `apps/bugs-eye-view/project.godot`.
3. Press **F5** to play from the main menu, or open a level in
   `scenes/levels/` and press **F6** to jump straight into it.

The first import takes a minute while Godot processes the sounds and icons.

## 2. Controls

| Action | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| Move | WASD / arrows | Left stick | Joystick (left side, appears where you touch) |
| Look | Mouse | Right stick | Drag anywhere else |
| Creep (quieter, harder to see) | Hold C | Click left stick, or push gently | Push the joystick gently |
| Primary | Left click / F | X / right trigger | Big button |
| Secondary | Right click / Q | Y / left trigger | Button |
| Jump | Space | A | Button |
| Dodge | Shift | Right shoulder | Button |
| Use | E | B | Button |
| Sense | R | Left shoulder | Button |
| Pause | Esc / P | Start | II button (top right) |

What each button does depends on the bug (the touch buttons relabel themselves):

| | Cockroach | Fly | Spider |
|---|---|---|---|
| Primary | Sprint (hold) | Boost (hold) | Web zip to the reticle; on touch, tap the spot |
| Secondary | Squeeze flat (hold) - hides you in gaps | Fly down / land on a surface | Web trap |
| Jump | Hop | Take off / fly up | Leap off the surface |
| Sense | Smell: antennae point at the nearest crumb | Slow-mo (also triggers by itself when a strike is about to land) | Feel footsteps as ripples through walls |

Standing still blends you in. Shadows hide you, bright light and noisy
surfaces (chip bags, foil, dishes, leaves) give you away. Keys can be rebound
in **Settings**.

## 3. Test it

All checks: import, boot, warnings-as-errors, then the 118-check smoke test
and the 162-check phase audit (`tests/phase_audit.tscn`, one section per
build phase), each run in the project **and** against an exported pack. Any
script or engine error fails the run:

```bash
tools/run_tests.sh
```

On Windows run it from Git Bash, or run the pieces in PowerShell:

```powershell
godot --headless --path . --import
godot --headless --path . res://tests/smoke_test.tscn --fixed-fps 60
```

Run one phase of the audit with
`godot --headless --path . res://tests/phase_audit.tscn --fixed-fps 60 -- --phase=4`.

`godot` means the Godot executable, e.g.
`C:\Godot\Godot_v4.7.2-stable_win64_console.exe`. The smoke test prints
`== N passed, 0 failed ==` and exits with code 0 when everything passes.

## 4. Export

Presets for every platform are in `export_presets.cfg`. Install the export
templates once: **Editor > Manage Export Templates > Download and Install**.

```bash
godot --headless --path . --export-debug   "Android"         build/android/bugseyeview.apk
godot --headless --path . --export-release "Android AAB"     build/android/bugseyeview.aab
godot --headless --path . --export-release "iOS"             build/ios/BugsEyeView.ipa
godot --headless --path . --export-release "Windows Desktop" build/windows/BugsEyeView.exe
godot --headless --path . --export-release "macOS"           build/macos/BugsEyeView.zip
godot --headless --path . --export-release "Linux"           build/linux/BugsEyeView.x86_64
godot --headless --path . --export-release "Web"             build/web/index.html
```

Create the `build/<platform>/` folder first. `build/` is ignored by Godot
(`build/.gdignore`) and by git. What each store needs (SDKs, accounts,
signing) is in [docs/STORE_EXPORT_CHECKLIST.md](docs/STORE_EXPORT_CHECKLIST.md).

### Web

`build/web` runs on any static host: itch.io (zip the folder and upload it as
an HTML game), Netlify, or `npx surge build/web`. It is a single-threaded build,
so it needs no special server headers. For hosts with a 15 MB file limit,
`tools/web_artifact/package.py build/web build/web_artifact` splits the engine
into parts and adds a page that stitches them back together.

### Android test app

A debug-signed APK of the current build is in
`dist/android/bugseyeview-debug.apk`. On an Android phone, download it from
GitHub, open it, and allow installs from that source. For Google Play you
need the AAB from the *Android AAB* preset instead (see the checklist).

## 5. Change the game

| To change | Edit |
|---|---|
| Bug speeds, stealth, abilities | `resources/bugs/*.tres` |
| Human / cat / dog / vacuum senses and attacks | `resources/threats/*.tres` |
| Light levels, noise per surface, scent, escalation timing | `resources/config/stealth_config.tres` |
| Points | `resources/config/scoring_config.tres` |
| Daily routine per room (when the human, TV, sprinklers... are on) | `resources/routines/*.tres` |
| Crumb targets, par time, unlocks | `resources/levels/*.tres` |
| Colony upgrades | `resources/upgrades/*.tres` |
| Level layouts | open `scenes/levels/*.tscn` in the editor |

All of these open in the Godot inspector.

### Swapping in real art and audio

- Every bug, threat, prop and pickup scene keeps its look under a node named
  `Visual`. Replace that node with an imported model; gameplay code never
  touches it.
- Level geometry uses the shared materials in `assets/materials/`; change a
  material and every surface using it updates.
- Sounds are looked up by name in `resources/audio/sound_library.tres`.
  Replace a file in `assets/sfx/` with one of the same name, or point the
  library at a new file. Looping sounds use WAV loop points.
- App icons and the splash are in `assets/icons/`.

### Regenerating content from code

The levels, actors and `.tres` files were generated by
`tools/build_all.tscn`, and the placeholder sounds and icons by
`tools/generate_assets.py`. After generation, the files are the source of
truth, so edit them directly. Regenerating with `--force` **overwrites** your
edits:

```bash
python3 tools/generate_assets.py
godot --headless --path . res://tools/build_all.tscn -- --force --only=res
godot --headless --path . res://tools/build_all.tscn -- --force --only=actors
godot --headless --path . res://tools/build_all.tscn -- --force --only=levels
```

Without `--force` it only creates files that are missing.

## Project layout

```
autoload/      GameManager, InputRouter, SaveSystem, AudioManager, Feedback,
               PerceptionSystem (stealth), HouseClock (daily routine)
scripts/       bugs/ threats/ hazards/ stealth/ world/ camera/ ui/ fx/ core/ data/
scenes/        levels/ bugs/ threats/ hazards/ props/ world/ ui/ hub/ fx/ camera/
resources/     tunable .tres data (see table above)
assets/        materials, sfx, icons
tests/         smoke_test.tscn, check_scripts.tscn
tools/         content generator, asset generator, test runner, web packager
docs/          store export checklist, screenshots
```
