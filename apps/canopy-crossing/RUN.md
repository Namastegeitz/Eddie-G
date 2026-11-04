# Running Canopy Crossing

Godot **4.7.2** (standard build, not .NET). Commands run from this folder
(`apps/canopy-crossing`).

## 1. Open and play

1. Download Godot 4.7.2 from <https://godotengine.org/download>.
2. **Import** `apps/canopy-crossing/project.godot`, then press **F5**.

A first launch starts the tutorial. The desktop window is portrait
(450x800); drag it bigger, the playfield stays centred with jungle on the
sides.

## 2. Handy launch options

Anything after `--` goes to the game:

```bash
godot --path . -- --fresh                     # wipe the save first
godot --path . -- --skip-tutorial --give=500  # skip the tutorial, +500 Berries
godot --path . -- --screen=store              # open a screen: home animals world store pass settings
godot --path . -- --play=journey,borneo,2,orangutan   # straight into a run
godot --path . -- --play=endless,amazon,0 --autoplay  # the bot plays (demo / capture)
godot --path . -- --play=journey,yasuni,4 --fpv       # start in first-person view
godot --path . -- --day=20500                 # pretend it's another day (deals, daily reward)
```

## 3. Tests

```bash
tools/run_tests.sh          # ~10 min: compile check + 309-check phase audit, project and exported pack
FAST=1 tools/run_tests.sh   # ~3 min
```

To check that every level can be beaten with the free Poison Dart Frog
(about 2 minutes for all 200):

```bash
godot --headless --path . res://tools/level_sweep.tscn -- --no-boot [--map=amazon]
```

## 4. Screenshots and clips

`tools/capture.sh` renders under Xvfb with Godot's movie writer:

```bash
tools/capture.sh /tmp/store.png 45 720x1280 -- --skip-tutorial --screen=store
KEEP_ALL=1 tools/capture.sh /tmp/frames 300 720x1280 -- --skip-tutorial --play=journey,amazon,0 --autoplay
```

## 5. Export

Presets for every platform are in `export_presets.cfg`. Install export
templates once (**Editor > Manage Export Templates > Download and Install**).

```bash
godot --headless --path . --export-debug   "Android"         build/android/canopycrossing.apk
godot --headless --path . --export-release "Android AAB"     build/android/canopycrossing.aab
godot --headless --path . --export-release "iOS"             build/ios/CanopyCrossing.ipa
godot --headless --path . --export-release "Windows Desktop" build/windows/CanopyCrossing.exe
godot --headless --path . --export-release "macOS"           build/macos/CanopyCrossing.zip
godot --headless --path . --export-release "Linux"           build/linux/CanopyCrossing.x86_64
godot --headless --path . --export-release "Web"             build/web/index.html
```

- **Android** needs the Android SDK + a keystore (Editor Settings > Export >
  Android). For the store, sign the AAB with your upload key.
- **iOS** needs a Mac with Xcode (or a cloud Mac such as Codemagic) and an
  Apple Developer team id in the iOS preset.
- **Web**: `build/web` works on any static host. To publish as a single
  claude.ai artifact (15 MB per file), run
  `python3 tools/web_artifact/package.py build/web build/web_artifact`.

Store billing and ads are sandboxed by default; see [docs/STORE.md](docs/STORE.md)
for switching to Google Play Billing, StoreKit and AdMob.

## 6. Regenerating generated assets

```bash
python3 tools/gen_audio.py          # all music, ambience and SFX (needs numpy + ffmpeg)
python3 tools/gen_audio.py --maps   # just region music, after adding a map
python3 tools/gen_globe.py land-110m.json content/world/globe_dots.json
```
