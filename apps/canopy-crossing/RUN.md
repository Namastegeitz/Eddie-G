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
tools/run_tests.sh          # compile check, first-person render check, phase audit (project + exported pack)
FAST=1 tools/run_tests.sh   # quicker: fewer levels and 2 scenes a region
WEB=1 tools/run_tests.sh    # also build the web version and tap-test it in a phone browser
```

**First person is checked on every run, three ways:**

1. The phase audit taps the eye button the way the engine really delivers a
   tap (a touch *and* the mouse click emulated from it). It must switch view
   exactly once and must not hop the animal.
2. `tools/fpv_check.tscn` drives the real game into every canopy scene of
   every region with the real GL renderer and fails if any first-person
   frame is blank or flat (needs `xvfb-run` on a server). See them all:

   ```bash
   xvfb-run godot --path . --rendering-driver opengl3 --resolution 720x1280 \
     res://tools/fpv_check.tscn -- --no-boot --out=/tmp/fpv_scenes.png [--map=borneo] [--back=4]
   ```

   The detailed first-person models (logs, caimans, croc jaws, soldier
   ants) render to one picture with
   `xvfb-run godot --path . --rendering-driver opengl3 res://tools/model_sheet.tscn -- --no-boot --out=/tmp/models.png`.

3. `tools/build_web.sh` (below) opens each web build in a phone-sized touch
   browser and checks first person by tapping.

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
- **Web**: always build with `tools/build_web.sh`. It exports, packages
  `build/web_artifact` for a claude.ai artifact (15 MB per file; `build/web`
  works on any static host), then loads the build in a phone-sized touch
  browser, taps the eye button and checks that first person shows a 3D
  scene without hopping, and that a second tap goes back. If any of that
  fails, the script fails and the build should not be published. Needs node
  and Playwright (`npm i -g playwright && npx playwright install chromium`).

### Beta testers on phones (Android and iPhone)

The workflow `.github/workflows/canopy-crossing-beta.yml` builds everything
on GitHub's machines and publishes a beta site to GitHub Pages:
`https://<owner>.github.io/<repo>/canopy-crossing/`. Run it from the Actions
tab (Canopy Crossing beta > Run workflow) or push a tag like `canopy-v0.9.1`.
One-time setup: Settings > Pages > Source: **GitHub Actions**.

The site is a page for testers: **Play in your browser**, how to put it on
the home screen (iPhone: Safari > Share > Add to Home Screen; Android:
Chrome > Add to Home screen), and the **Android APK** to download and
install (Godot's release engine, signed with a beta key kept in the Actions
cache so new builds install over old ones; set the `CANOPY_ANDROID_KEYSTORE_*`
secrets for a permanent key). The game page is installable (manifest,
icons, iPhone tags) and opens full screen from the home screen. Every run
also checks first person by touch in a phone-sized browser before
publishing. A native iPhone app needs an Apple Developer account
(TestFlight); until then iPhone testers use the home-screen version.

Build the same site locally: `tools/build_web.sh`, then
`python3 tools/web_artifact/package.py build/web build/site --site [--apk build/android/canopycrossing.apk]`.

Store billing and ads are sandboxed by default; see [docs/STORE.md](docs/STORE.md)
for switching to Google Play Billing, StoreKit and AdMob.

## 6. Regenerating generated assets

```bash
python3 tools/gen_audio.py          # all music, ambience and SFX (needs numpy + ffmpeg)
python3 tools/gen_audio.py --maps   # just region music, after adding a map
python3 tools/gen_audio.py --calm   # just the calm songs (tuned to each region's 528 / 963 Hz)
python3 tools/gen_audio.py --check  # decode the calm songs and check every strong pitch sits on its tone
python3 tools/gen_globe_map.py land-50m.json countries-50m.json assets/world/globe_map.png   # from npm pack world-atlas@2.0.2
```
