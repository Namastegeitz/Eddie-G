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
| Look | Mouse | Right stick | Drag anywhere else (eases in; speed under Settings > Touch look speed) |
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

**Flying.** The stick flies level; Jump climbs and Secondary dives. With
**Fly where you look** on (Settings, on by default) tilting the camera well
up or down while flying forward climbs or dives too. Let go of the stick to
**hover**: you hold your height and it costs a third of the stamina.
**Updrafts** - warm air rising over the stove (while cooking), the toaster,
the radiator and lamps, the barbecue, the sunny patio and the compost heap
(look for the faint rising ring) - lift you and refill stamina in mid-air; a
gliding fly can catch one and fly again.

**Fly moves**

| Move | How | What it does |
|---|---|---|
| Pester | Use, next to a person's or pet's head | People flail and swat at the air (dodge away!) and can't see you for 3.5 s. Pets get playful and leap at you twice. Costs stamina; scores points |
| Burst | Dodge | Quick sideways dart |
| Evasive loop | Dodge twice quickly | Loops up and back the way you came, untouchable for half a second (costs stamina) |
| Dive | Dodge while holding Secondary (Down) | Fast, silent plunge below a threat's sight line |
| Cling | Fly into a wall holding Down, or up into the ceiling holding Up | Perch there: silent, camouflaged on walls, out of a human's downward gaze, stamina refills |
| Jink | Steer hard against your direction at speed | You're much harder to see for a moment |
| Silent glide | Happens when stamina runs out | Glide down quietly instead of dropping |

**The alarm gauge** (top of the screen) fills while a human or pet can see
you, and a little when they hear you. On their own, threats only come to
investigate. At **100% everyone in the room is alerted** and comes after you.
Break line of sight and the gauge drains; it drains three times faster while
you're hidden, and the alarm is called off below 30%. Humans can't see the
floor right under their own feet.

Standing still blends you in. Shadows hide you, bright light and noisy
surfaces (chip bags, foil, dishes, leaves) give you away. Keys can be rebound
in **Settings**.

**Bug food and crumb gems.** Food is common and gives a short boost; gems
are rare (two per room, one always on the floor), glow, and have real powers.
Touch one to use it: its name and what it does stay on screen (6 s for gems,
3.5 s for food). Active effects and their timers show under your crumbs.

| Food | Effect |
|---|---|
| Sugar Cube | Sugar Rush: 35% faster for 8 s, meters topped up |
| Cheese Crumb | One extra shell (one more hit) |
| Mint Leaf | No scent trail for 15 s - dogs lose you |
| Honey Drop | Steps 70% quieter for 12 s |
| Coffee Bean | Wired for 10 s: fast dodges, Sense and stamina don't run out |
| Dog Kibble | Counts as 2 crumbs |

| Gem | Power |
|---|---|
| Amethyst | Shadow Cloak: almost invisible for 12 s |
| Amber | Time Freeze: every person and pet stops for 5 s |
| Emerald | Calm: the alarm empties and stays empty for 12 s |
| Ruby | Iron Shell: nothing can hurt you for 8 s |
| Diamond | Crumb Magnet: nearby crumbs fly to you for 12 s |
| Sapphire | Echo Decoy: a humming shard lures threats to where you stood |

Food and gems add to your score; find two gems in a run you win for the
**Gem Hunter** badge. Gems you find are kept in your save.

**Animals** are playful when calm: they bat their ball around, do zoomies,
play-pounce and (the puppy) chase their tails. While playing they see and
hear about half as well. Anything suspicious ends the game: ears up, tail
stiff, they freeze and stare, and the cat stalks low. A fly hovering just
above a pet gets leapt at. Animals get sharper room by room (kitchen puppy:
relaxed, living-room cat: watchful, backyard dog: sharp; shown on the room
select screen) and sharper again as the household escalates.

**People** stop to do things on their rounds, and anything suspicious
interrupts them:

| Room | Who | Does | What it means for you |
|---|---|---|---|
| Kitchen | The cook | Cooks at the stove, does the dishes, snacks at the table | Back turned while cooking and washing up; cooking and snacking drop crumbs you can grab under their feet |
| Living room | The reader | Reads in the armchair, naps on the couch | Behind the paper they only see what's right in front of them, glancing up now and then; asleep they can't see, barely hear and snore - a loud noise wakes them |
| Backyard | The gardener | Waters the flowers, kneels at the vegetables, throws the ball for the dog | The spray washes your scent off but knocks you back; kneeling they spot anything close, even behind them; the dog chases the ball and forgets about you |

**Places to hide.** Every bug can crawl into the things lying around the
house and be completely hidden (no squeezing needed): a paper cup on its side,
an old sneaker, a tipped-over grocery bag, a recycling box, a folded towel and
a napkin tent on the counters, slippers, a fallen pillow, a shoe, a laundry
basket, an overturned flowerpot, a coiled garden hose, a tipped wheelbarrow.
A stack of mail, a flour sack, a magazine pile, toy blocks, a cat bed, rocks,
a woodpile and a garden gnome block sight lines, and tall grass in the
backyard keeps you in shade. You can also hide under the fridge, the couch,
the armchair, the doghouse and the garden shed. Inside a shelter you can't be seen or hit, and the alarm gauge drains
three times faster.

## 3. Test it

All checks: import, boot, warnings-as-errors, an offline test of the Meshy
client, then the 120-check smoke test and the 276-check phase audit
(`tests/phase_audit.tscn`, one section per build phase plus one per update),
each run in the project **and** against an exported pack. Any script or
engine error fails the run:

```bash
tools/run_tests.sh
```

On Windows run it from Git Bash, or run the pieces in PowerShell:

```powershell
godot --headless --path . --import
godot --headless --path . res://tests/smoke_test.tscn --fixed-fps 60
```

Run one section of the audit with
`godot --headless --path . res://tests/phase_audit.tscn --fixed-fps 60 -- --phase=4`
(1-6 are the build phases, 7 the alarm gauge and fly moves, 8 cover and model
slots, 9 bigger rooms, people, bug detail, food and gems, 10 pickup messages
and touch look, 11 flying, playful/alert animals and people's activities).

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
| Bug food and gem effects (duration, strength, points) | `resources/items/*.tres` |
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

### Generated 3D models (Meshy)

Every bug, threat, pickup, hiding spot and big piece of furniture has a model
slot. Drop `assets/models/<model_id>.glb` into the project and it replaces the
placeholder automatically, fitted to the same space. `tools/meshy/generate.py`
makes all 84 with Meshy's text-to-3D API from the prompts in
`tools/meshy/assets.json`; see [tools/meshy/README.md](tools/meshy/README.md).

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
assets/        materials, sfx, icons (models/ once generated)
tests/         smoke_test.tscn, phase_audit.tscn, check_scripts.tscn
tools/         content generator, asset generator, Meshy model generator,
               test runner, web packager
docs/          store export checklist, screenshots
```
