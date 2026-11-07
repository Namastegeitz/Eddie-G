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
| Look | Mouse | Right stick | Look stick (right, above the buttons: hold it off-centre to keep turning) or drag anywhere else. The SPEED button beside the stick steps the look speed 0.5x - 2x (also in Settings > Touch look speed) |
| Creep (quieter, harder to see) | Hold C | Click left stick, or push gently | Push the joystick gently |
| Primary | Left click / F | X / right trigger | Big button |
| Secondary | Right click / Q | Y / left trigger | Button |
| Jump | Space | A | Button |
| Dodge / Run | Shift: tap to dash, hold to run | Right shoulder | Run button (tap: dash) |
| Use | E | B | Button |
| Sense | R | Left shoulder | Button |
| Pause | Esc / P | Start | II button (top right) |
| Bug's-eye view | V | Back / Select | EYES button (beside SPEED) |
| Open the add-on revolver | Tab | D-pad up | TOOLS button (under SPEED) |
| Fire the loaded add-on | G | D-pad down | Open TOOLS, tap USE |

What each button does depends on the bug (the touch buttons relabel
themselves). The first time you play a bug, a how-to-play card shows its
buttons and its trick; **Pause > Controls** shows it again.

| | Cockroach | Fly | Spider |
|---|---|---|---|
| Primary | Sprint (hold) | Boost (hold) | Web zip to the reticle; on touch, tap the spot |
| Secondary | Squeeze flat (hold) - hides you in gaps | Fly down / land on a surface | Web trap |
| Jump | Hop | Take off / fly up | Leap off the surface |
| Sense | Smell: antennae point at the nearest crumb | Slow-mo (also triggers by itself when a strike is about to land) | Feel footsteps as ripples through walls |

| | Ant | Cricket | Ladybug | Firefly | Stink bug |
|---|---|---|---|---|---|
| Primary | Sprint | Chirp: throws your voice ahead, threats go to look there | Shell up (hold): can't be hurt, can't move | Boost | Stink cloud: pets bolt, people cough and can't see |
| Secondary | Decoys: a column of ants marches off, threats follow them | Squeeze | Squeeze | Fly down / land | Squeeze |
| Jump | Hop | Hold to charge, let go to leap | Hop; hold in the air to flutter down | Take off / fly up | Hop |
| Sense | Antennae point at the nearest crumb | Antennae | Antennae | Flash: dazzles every person and pet nearby | Antennae |
| Its trick | Tiny: any gap hides it without squeezing | A full charge clears a chair | People won't swat it until the alarm is full (pets will) | Glows while flying - land or cling to go dark | Slow, takes three hits, and its smell lingers (dogs track it) |

**The bugs in the shade.** You start as the cockroach. The others stand in
the shade on the bug select screen - a dark silhouette with what brings them
out - and come out one at a time: escape any room as the bug before them.
Cockroach → Fly → Spider → Ant → Cricket → Ladybug → Firefly → Stink bug. A
new arrival is marked **NEW** until you play it; bugs you've escaped with are
marked **ESCAPED**.

**Finding the way out.** Once you've collected enough crumbs to open the exit,
a gold marker points to it (at the screen edge when it's behind you) with the
distance.

**Bug's-eye view.** Press V (or EYES on a touch screen, or Settings > Bug's-eye
view) to see through your bug's own eyes. The camera sits exactly at the
sculpted eyes of each bug: you see your antennae sway, your mandibles, palps or
fangs below, and your front legs step into the corners of the view, all moved
by the same animation rig as the model. The body faces where you look (you can
still step sideways), the view bobs with the gait, each bug has its own field of
view (the fly's and firefly's compound eyes see widest, with facets at the edge
of view), and the spider's view follows the wall or ceiling it's on. Press V
again to go back behind the bug.

**Running.** Tap Shift to dash out of trouble; keep holding it to run (about
1.5x faster, but louder and easier to spot). In the air the fly flies faster.

**Climbing.** Every bug climbs. Push into a wall, a cupboard, a table leg, a
box or a stack of books for a moment and you start up it; at the top you walk
over the edge onto it. Small lips (a counter's overhang, the edge of a table
top) are clambered round on the way up. Pull back on the stick to climb down
(at the floor you're walking again) and press Jump to leap off, away from the
wall. Leap or fall at a wall while pushing towards it and you grab on. Each
bug climbs at its own pace (ants fastest, crickets slowest); loose things you
can push, like a grape, are pushed rather than climbed. Through the bug's
eyes the view turns with the wall. The spider still crawls its own way,
across ceilings too.

**Jump-up routes.** Each room has a tower of stacked junk, a spiral staircase
of steps that each rise a little higher, with small gaps to hop across.
The kitchen's is boxes and tins by the east window, the living room's is
piles of books, the backyard's is flowerpots and bricks. Treasures and
power-ups sit on the steps and the summit. Springy **bounce pads** fling you
up in an arc (steer a little in the air) onto high places:

| Room | Bounce pad | Lands you on |
|---|---|---|
| Kitchen | Sponge on the floor | The counter |
| Kitchen | Sponge on the counter | The top of the fridge |
| Kitchen | Pot holder by the island | The island top |
| Living room | Cushion by the bookshelf | The top of the bookshelf |
| Living room | Cushion by the aquarium | The aquarium lid |
| Living room | Cushion by the cat tree | The top of the cat tree |
| Backyard | Mushroom by the shed | The shed roof |
| Backyard | Mushroom by the bird bath | The bird bath |
| Backyard | Mushroom by the picnic table | The picnic table |

**Treasures and the showcase.** Lost trinkets are hidden all over the house,
mostly up high: six per room, from common to legendary, plus the crumb gems.
Each glows in its rarity's colour (common silver, rare blue, epic purple,
legendary gold); epic and legendary ones send a beam of light up so you can
spot them from across the room. Whatever you find goes into your
**showcase**: the home screen has a trophy shelf with your rarest finds, a
Showcase button for the full collection (24 pieces, room by room; the ones
you haven't found are dark silhouettes with a hint), and a line with your
count. Treasures score 75 / 200 / 450 / 1000 points by rarity, and a
legendary find earns the Treasure Hunter badge.

| Room | Common | Rare | Epic | Legendary |
|---|---|---|---|---|
| Kitchen | Lost Button, Glass Bead | Doll's Teaspoon, Sea Glass, Amber Gem | Golden Thimble | The Lost Wedding Ring (top of the fridge), Diamond Gem |
| Living room | Toy Brick, Cat's-Eye Marble | Loose Pearl, Watch Gear, Amethyst Gem | Crystal Earring, Sapphire Gem | Grandma's Star Brooch (top of the bookshelf) |
| Backyard | Acorn Cap, Spiral Snail Shell | Old Coin, Jewel Beetle Shell | Four-Leaf Clover, Ruby Gem, Emerald Gem | The Golden Acorn (on the shed roof) |

**Mini maps.** Behind every room are ten small levels, each with a small
task: inside the walls (studs with drilled holes, fire blocks to get round,
wires, a copper pipe, pink insulation to hide in, drafts and cobwebs), under
the sink (the drain's U-bend, supply lines, bottles of cleaner, a bucket and
a drip), the basement (stairs up to the door, washer and dryer, the water
heater and furnace, shelving with paint cans, box stacks, a workbench) and
the attic (boxes under the sloping roof, a trunk, suitcases, a rolled rug, an
attic fan on the harder ones). They're on the room list under each room you
can play: number 1 is open, and each one you finish opens the next.

| Task | What to do |
|---|---|
| Shards | Gather the gem shards, then get out |
| Timed | Gather the shards before the clock runs out |
| Key | Find the brass key: it opens the way out (shards are a bonus) |
| Climb | The way out is at the very top |

Mouse traps (step on the cheese plate and the bar slams over a moment later)
get more common as the numbers go up, and some maps have the cat or the robot
vacuum prowling. **The crawl space** is the tenth map, and it's hidden: after
you finish a mini map there's a chance (about 1 in 3) that a draught opens it
up. It's low and dark, packed with shards that pay double, two crumb gems,
and a bug-bomb fog rolling in. Once you've played it, it seals up again until
the next lucky draught.

**Credits and the Armory.** Every gem shard you take out of a mini map is a
credit, finishing the task pays a bonus (more for later maps, 40 for a crawl
space), and crumb gems and treasures in the rooms pay credits too. Spend them
in the **Armory** (main menu, room list or the result screen) on add-ons, and
raise each to level 3 for more uses per run and a stronger effect:

| Add-on | Kind | What it does |
|---|---|---|
| Power Legs | Strength | Jump twice as high and climb fast |
| Dash Burst | Strength | A long untouchable dash, then a burst of Turbo |
| Ground Pound | Strength | Stomp: stuns pets and the vacuum nearby, knocks props flying |
| Iron Shell | Defense | Nothing can hurt you for a while |
| Spiky Armor | Defense | Blocks the next hits (1-3) and stuns whoever struck |
| Shadow Cloak | Defense | Almost invisible for a while |
| Second Wind | Defense | One more shell and every meter refilled |
| Smoke Bomb | Tactics | A cloud ahead: people and pets inside can't see |
| Decoy Chirp | Tactics | A noise where you look: threats go and check |
| Flash Bead | Tactics | Dazzles every person and pet close by |
| Silk Grapple | Tactics | Zip to the spot you aim at (and cling on) |
| Crumb Magnet | Tactics | Pulls crumbs and gem shards to you |

You start with Decoy Chirp and Iron Shell. **The revolver** has six chambers:
load add-ons into them in the Armory (a new one goes into an empty chamber by
itself). In play, open it (TOOLS / Tab / D-pad up) and the cylinder swings
out while the game holds still; tap a chamber (or arrows, mouse wheel, 1-6,
D-pad) to turn it to the top, then tap USE in the middle (Enter, Space, F, A)
to fire it. Brass pips show the uses left this run; G (D-pad down) fires the
loaded chamber without opening.

**Power-ups.** Glowing power-up tokens are tucked into the hidden corners of
every room (under the fridge, couch and armchair, inside shelters, in the
secret-route cavities, behind the woodpile, up on the cat tree...) and up on
the high places (the fridge top, the island, the bookshelf, the shed roof, the
tower steps...): sixteen per room, of five kinds:

| Power-up | Does |
|---|---|
| Turbo | 60% faster for 12 s |
| Spring Legs | Much higher jumps and leaps for 15 s |
| Bug Radar | Crumbs and power-ups show on screen for 20 s |
| Double Crumbs | Every crumb counts twice for 25 s |
| Shrink | Tiny for 15 s: any gap hides you and you're hard to see |

The count found shows under your crumbs; finding ten in one run earns the
Power Hunter badge.

**People keep to their routine - but not mid-chase.** They come in through
the room's door when their part of the day starts. When it ends they leave,
but not while they're onto you: they finish with you, calm down, then walk out
through the door.

**Smooth at any frame rate.** Movement is interpolated between physics
steps, so the camera, your bug, the people and the pets glide on 90/120 Hz
screens and when the frame rate wobbles. The camera eases in when a wall gets
behind it and drifts back out. Jumps are forgiving: you can still jump a
moment after running off an edge, and a jump pressed just before landing
happens when you land.

**People and pets that feel alive.** People walk heel-to-toe in a smooth
arc, glide along between steps, sway their hips over the standing foot and
ease into turns. They breathe, blink, glance around when calm, look with
their eyes first and then turn their head, and do a quick double take at a
sudden noise. Pets build up to a run and slow down, breathe (and pant after
running or playing), blink, flick an ear, and their heads bob with each
stride.

**Graphics.** Surfaces have high-resolution texture and bump detail: floor
tiles with grout, wood grain and planks, flagstones, grass, carpet, plaster,
stone counters, fabric weave and denim on clothes, fur on the pets, and
shells on the bugs. Models are rounder, and people have moving eyes,
eyelids, cheeks and lips. **Quality** in Settings: *High* adds 4x
anti-aliasing, a soft glow and crisper two-cascade shadows; *Medium* is full
resolution with 2x anti-aliasing; *Low* drops bump maps and shadows for speed. A light
haze gives the big rooms depth.

**Smoother on slow phones.** If the game runs slower than about 24 frames a
second for a few seconds, it steps the graphics quality down by itself
(high → medium → low, at most once every 20 s) and says so. Turn **Auto
quality** off in Settings to keep your own choice. On a phone browser the
game starts on low quality. Small far-away things (crumbs, pickups, props)
stop drawing at a distance.

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

**Animals.** The kitchen has a playful puppy; the living room and the
backyard each have a cat *and* a dog. Calm animals play: they bat their ball
around, do zoomies, play-pounce, the puppy chases its tail - and the cat and
the dog play chase together, tagging and swapping who's "it". While playing
they see and hear about half as well. Anything suspicious ends the game: ears
up, tail stiff, they freeze and stare, the cat stalks low - and if one of a
playing pair spots something, the other is on guard too. A fly hovering just
above a pet gets leapt at. The backyard cat leaps onto the picnic table, the
doghouse and the shed.

Dogs sniff along with their nose to the ground. Hide near one and it sniffs
you out: it stands barking at your hiding spot, the alarm climbs and the
people come to look. You're still safe in there, but move before it fills.

Animals get sharper room by room (relaxed in the kitchen, watchful in the
living room, sharp in the backyard; shown on the room select screen) and
sharper again as the household escalates.

**People** stop to do things on their rounds, and anything suspicious
interrupts them:

| Room | Who | Does | What it means for you |
|---|---|---|---|
| Kitchen | The cook | Cooks at the stove, does the dishes, snacks at the table, opens the fridge, sweeps the floor | Back turned while cooking and washing up; cooking and snacking drop crumbs you can grab under their feet. At the fridge the door swings out into the room (a wall you can't pass for a few seconds), the fridge light spills out and their head is in the fridge: they can't see. The broom sweeps crumbs along and shoves you out from under it - they notice a moment later |
| Living room | The reader | Reads in the armchair (switching the lamp on), naps on the couch, draws or opens the curtains | Behind the paper they only see what's right in front of them, glancing up now and then; asleep they can't see, barely hear and snore - a loud noise wakes them. The reading lamp lights the reading corner; drawn curtains take the sunbeam away |
| Backyard | The gardener | Waters the flowers, kneels at the vegetables, rakes the leaves, throws the ball for the dog | The spray washes your scent off but knocks you back; kneeling they spot anything close, even behind them; the rake sweeps like the broom; the dog chases the ball and forgets about you |

On their rounds people also stop now and then to **check their phone**
(eyes down: they only notice what's close), stretch, scratch their head or
glance at their watch, and they **crouch to pet a calm pet** (it sits, wags
and stops watching for a bit). Their feet knock small things out of the way.

**Pets go about their day too.** At stops on their rounds they sit, lie down,
stretch, groom a paw (cats) or scratch an ear (dogs), and wander over to the
**water bowl** for a drink - a sloppy drinker leaves a puddle that washes
your scent away. A wet dog shakes itself off; a cat runs out of any water.
Running pets bump toys out of the way. Everyone keeps clear of the robot
vacuum, which **hoovers up crumbs** in its path (they turn up again a little
later) and shoves toys aside. In the backyard the dog **digs holes** in the
lawn: a mound of dirt you have to go round, and a dark hollow any bug can
hide in without squeezing.

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
client, then the 165-check smoke test and the 416-check phase audit
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
and touch look, 11 flying, playful/alert animals and people's activities, 12 the
touch look stick, 13 the upgraded dog and cat-and-dog rooms, 14 the five new
bugs, the unlock chain, the how-to-play cards and auto quality, 15 smooth
motion, lifelike people and pets, textures and quality tiers, 16 new NPC
movements, chores, pet habits and the obstacles they create, 17 the bug's-eye
view, Shift to run, power-ups and people finishing the chase, 18 climbing for
every bug, the junk towers, bounce pads, treasures and the showcase, 19 the
mini maps, credits, the Armory's add-ons and the revolver).

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
`tools/build_all.tscn`, the placeholder sounds and icons by
`tools/generate_assets.py`, and the surface textures (`assets/textures/`,
tileable detail + normal maps, tinted by each material's colour) by
`tools/generate_textures.py`. After generation, the files are the source of
truth, so edit them directly. Regenerating with `--force` **overwrites** your
edits:

```bash
python3 tools/generate_assets.py
python3 tools/generate_textures.py
godot --headless --path . res://tools/build_all.tscn -- --force --only=res
godot --headless --path . res://tools/build_all.tscn -- --force --only=actors
godot --headless --path . res://tools/build_all.tscn -- --force --only=levels
godot --headless --path . res://tools/build_all.tscn -- --force --only=minis
```

The mini maps (`scenes/levels/minis/`) are laid out by
`tools/builders/mini_map_builder.gd` from `scripts/data/mini_maps.gd` (each
room's ten maps: theme, name, task, shards, time limit, prowler).

Without `--force` it only creates files that are missing.

The showcase icons (`assets/icons/items/`) are rendered from the item scenes
and need a display (or `xvfb-run -a` in front):

```bash
godot --rendering-driver opengl3 --path . res://tools/render_item_icons.tscn
```

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
