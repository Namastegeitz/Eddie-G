# Monkey See, Monkey Do

A casual rhythm-memory game for phones (and anything with a browser). A
cartoon 3D monkey dances a routine on the beat; you copy it, move for move,
in the same order. Built from `prompts/claude/monkey-see-monkey-do.md`.

![Title, watch phase, your turn, level clear](docs/screenshots/strip.png)

## Play

- **Watch.** The monkey dances. Each move lights its button and its wedge of
  the dance floor and plays its own note (like the old colour-and-tone memory games).
- **Your turn.** Copy the routine before the timer runs out. Tap the buttons,
  tap the monkey's hands, feet, head or belly, swipe on the stage, or use the
  keyboard (`Q W E` / `A S D`, or `7 8 9` / `4 5 6`).
- **Cheer or oops.** Right: cheering, confetti, bananas, and a longer
  routine. Wrong (or out of time): a dizzy stumble, a card showing what the
  move was and what you tapped, one life gone, and the *same* routine again.

| Move | Button | Key | Swipe |
|---|---|---|---|
| Left Arm | orange, top left | Q / 7 | up-left |
| Head Bob | yellow, top middle | W / 8 | up |
| Right Arm | blue, top right | E / 9 | up-right |
| Left Leg | green, bottom left | A / 4 | down-left |
| Flair | pink, bottom middle | S / 5 | down |
| Right Leg | purple, bottom right | D / 6 | down-right |

Combos (from level 4): two moves at once, both within 320 ms (520 ms in Assist).
"Left" means the left of the screen, like a mirror. Settings can switch the
names to the monkey's own sides; the buttons never move.

## What's in it

- **Adventure:** 30 levels in 3 worlds (Jungle Clearing, Beach Bash, Temple
  Disco), 3 lives a level, 3 stars a level, boss levels 10/20/30.
  - Levels 1-3: 2-3 moves, 80-88 BPM. Levels 4-10: 4-6 moves, 95-120 BPM, combos.
  - World 2 adds build-up rounds (each round repeats the last and adds moves),
    cross combos, and speed-up rounds. World 3 adds backwards rounds, up to 10 moves at 142 BPM.
- **Endless:** classic memory loop. Starts at 2 moves, +1 each round, tempo
  rises to 160 BPM, one mistake ends it. Best is saved.
- **Free Dance:** tap anything, no score, no timer. Good for learning the moves.
- **100 skins** in 13 themed sets (see below), **88 pieces of gear** in 8
  slots (see below), 6 saved outfits, 4 Flair moves (wiggle, shimmy, spin,
  robot) and 4 stages. Try anything on before you get it. Looks never change
  difficulty.
- **Bananas:** earned by playing. Spent on standard skins and gear, "Watch
  again" (5) and continuing a level after running out of lives (15, once per
  try). The phone apps' Shop also sells them (see below); you never need to.

## Skins and premium skins

![All 100 skins](docs/screenshots/skins.png)

- **50 standard skins** (Common and Rare, 60-300 bananas) in five sets:
  Classic Fur, Fruit Stand, Wild Things, Pop Art, Candy Shop. Patterns include
  tiger, zebra, leopard, giraffe, camo, plaid, argyle, polka dots, sprinkles,
  watermelon and a colour-cycling rainbow.
- **50 premium skins** (Epic and Legendary) in eight sets: Precious Metals,
  Cosmic, Elements, Mythic, Spooky, Tech, Party & Music, Heroes. They add shiny
  metal, glow-in-the-dark patterns (galaxy, lava, neon circuits, storm), a
  see-through ghost and hologram, glowing eyes, wings (angel, dragon, phoenix,
  fairy), capes, halos, horns, a unicorn horn and mane, antennae, a working
  jetpack, masks, an eyepatch, tail tips, and particle auras (sparkles, stars,
  embers, bubbles, snow, notes, leaves, pixels, smoke).
- **Every premium skin unlocks two ways:** free when you reach its play goal
  (shown on its card with a progress bar: stars, world clears, 3-star bosses,
  Endless rounds, Perfect moves, streaks, combos, flawless levels, days played,
  and more; 50 goals, one per skin), or early with **golden bananas**.
- **Golden bananas** come from playing: +2 the first time a level gets 3 stars,
  +10 for each world cleared, +1 per 10 Endless rounds in a run, +5 per completed
  skin set, or swap 100 bananas for 1 in the Wardrobe. The phone apps' Shop also sells them.
- Rarity frames, set progress with completion bonuses, filters (standard,
  premium, owned, not yet), NEW badges, and an "unlocked!" card when a goal is reached.
- All the numbers live in `js/skins.js` and `js/rules.js`; How it works lists
  every premium skin with its goal and price.
## Graphics

- **Detailed cartoon monkey:** smooth shapes with ink outlines and a bright
  rim light, hands with fingers in four poses (relaxed, open wave, fist,
  pointing), feet with an inner big toe, fluffy cheek and head tufts, eyes
  with painted irises, highlights and eyelids that blink, a curling tail, and
  springy ears, tuft and tail that bounce with the dance.
- **Four detailed stages:** jungle (leafy trees, grass that sways, flowers,
  mushrooms, vines, light rays, butterflies, fireflies), beach (animated
  waves and foam, sunset, palms, umbrella, sandcastle, gulls), temple disco
  (light-up floor, fluted pillars with fire bowls, speakers that thump, a
  mirror ball throwing light specks, coloured beams) and moon (craters,
  rocks, Earth with clouds, a ringed planet, twinkling stars, shooting stars).
- **Play feedback:** sparkles burst from the limb on every correct move
  (bigger for Perfect, with a tiny camera kick), a coloured trail follows
  the limb that moves, and the pad lights glow warmer as your streak grows.
- **Graphics levels** (Settings > Graphics): Auto, Low, High, Ultra. Auto
  starts at High and steps down to Medium, then Low, if frames are slow.
  Real soft shadows on High and Ultra; Ultra renders at up to 3x for the
  sharpest phone screens. How it works lists what each level includes.
- Scenery is merged into a few meshes per stage (`js/gfx.js`), so phones
  draw all this in about 100-140 draw calls.

## Gear and outfits

- **8 gear slots, all worn at once:** hats (22: crowns, a tiara, pirate hat,
  cat ears, space helmet...), eyes (12), neck (11: bow tie, feather boa, a
  parrot on the shoulder...), back (10: cape, backpack, guitar, jetpack,
  angel/bat/butterfly wings), hands (11: maracas, microphone, magic wand,
  glow sticks, scepter...), feet (6: sneakers, flippers, rocket boots...),
  face (6) and auras (10 particle effects: sparkles, hearts, notes, stars,
  confetti, embers, pixels, bubbles, leaves, snow).
- Gear moves with the dance: capes and wings flap, jetpacks and rocket boots
  flame, propellers spin, glow sticks pulse with the beat. Trying on a back
  item turns the monkey around; hand items make it wave them.
- 68 items cost bananas, 20 premium ones cost golden bananas. Wardrobe cards
  show a live 3D thumbnail of each item.
- **Outfits:** save up to 6 complete looks (skin + every slot) and put one
  back on with a tap.

## Shop (iPhone and Android apps)

Optional real-money packs, sold only through the App Store and Google Play:

| | Price (US) |
|---|---|
| Starter Pack (once): 1,000 bananas, 15 golden, sneakers, backpack | $0.99 |
| Bananas: 500 / 1,200 / 3,500 / 8,000 | $0.99 / $1.99 / $4.99 / $9.99 |
| Golden bananas: 12 / 30 / 85 / 190 | $0.99 / $1.99 / $4.99 / $9.99 |
| Party Pack: 1,500 bananas + 20 golden | $2.99 |
| Mega Party Pack: 5,000 bananas + 70 golden | $7.99 |
| 7 themed bundles (a premium skin + 3-4 matching items) | $2.99 each |
| 8 premium skin sets (all skins in the set) | $4.99 each |

- Prices show in the buyer's currency. Bigger packs give up to 60% more per
  dollar, and the label says exactly how much; "Best value" is the real best.
- **Grown-up check** before every purchase (on by default), optional monthly
  limit, *Restore purchases*, and a Purchases list in Stats.
- No timers, no pop-up offers, nothing only for sale. Items you already own
  in a bundle pay back 5 golden bananas each.
- The web build shows the Shop but sells nothing. Add `?billing=test` (or
  `#store-test` on the artifact link) to try the whole flow with pretend purchases.
- Store setup (product IDs, App Store Connect, Play Console, Xcode StoreKit
  testing): [mobile/README.md](mobile/README.md#in-app-purchases-the-shop) and
  [docs/STORE_PRODUCTS.md](docs/STORE_PRODUCTS.md).

- **Music:** generated live per stage (marimba jungle groove, steel-drum beach,
  four-on-the-floor disco, echoey moon). No audio files.

## On phones

Plays on every current iPhone, iPad and Android phone, three ways (details
in [mobile/README.md](mobile/README.md)):

- **In the browser, installed to the home screen**: host `dist/www` on any
  HTTPS site, open it, then *Add to Home Screen* (iPhone) or *Install app*
  (Android). Full screen and offline. Safari on iOS 14.5+, Chrome 87+.
- **Android app** (`mobile/android`, Capacitor): Android 7.0+. Build an APK
  in Android Studio or with `scripts/build_mobile.sh`; Play-ready `.aab` with your upload key.
- **iPhone/iPad app** (`mobile/ios`, Capacitor): iOS 15+. Build in Xcode on a Mac,
  or on Codemagic's cloud Macs (`mobile/ci/codemagic.yaml`) for TestFlight.

Phone details: portrait lock on phones, Android back button, haptics, screen
kept awake while playing, notch and gesture-bar safe areas, iPhone silent-switch
setting, WebGL 1 support for older GPUs, no network permission in the Android app.

## Transparency and friendliness (built in)

- **How it works** screen generated from the game's own rule file
  (`js/rules.js`, `js/levels.js`, `js/shop.js`): every timer formula, timing
  window, point value, star rule, banana rule, price, and a table of all 30
  levels. It can't drift from what the game does.
- **Results show the maths:** itemised bananas that match the ledger, why you
  got the stars you got, and each round's routine code (same code, same dance).
- **Banana history** (Stats): every banana earned or spent, with the reason.
- **Mistake cards** show the move you missed next to the one you tapped.
  Stats track your most common mix-ups.
- **No ads, no tracking, no network.** Settings > Your data shows the
  exact saved JSON, lets you copy a save code to another device, load one, or reset.
- **Honest Shop:** prices before any tap, bonus percentages that are the real
  maths, "separately it would cost" on bundles, a grown-up check, a monthly
  limit and a Purchases list. Everything can still be earned by playing.
- **Comfort options:** timer Normal / Relaxed (2x) / Off; game speed 100 / 85 / 70%;
  Assist mode (free Watch again, hint on the missed move, wider combo window);
  voice call-outs; move captions; reduce motion; vibration; graphics quality;
  rhythm calibration for Bluetooth headphones.
- **Accessible moves:** each move has a colour, a shape (a tiny monkey icon
  with that limb highlighted), a fixed position, a key, and its own note.
- First-run 3-card how-to, a guided first round that glows the right button,
  and a level card before each level listing rounds, moves, tempo, timer and anything new.

## Choices I made where the brief was open

The design document stopped at "Players earn bananas/coins". I filled in:
bananas per move/star/first clear, a wardrobe with prices from 30 to 300 (and
later 100 skins with golden bananas for premium ones), stages unlocked free by reaching their world, a paid "Watch again" and
one paid continue per try. Real-money packs came later, on request, in the
phone apps only and with nothing locked behind them. Timing is a
bonus (points and the third star) and never decides whether a move counts, so
the game stays a memory game first. All of these numbers live in
`js/rules.js` and `js/shop.js` if you want to tune them.

## Files

```
index.html            app shell (all screens)
css/game.css          styles
js/main.js            boot + the one animation loop
js/game.js            Watch -> Your turn -> cheer/oops, modes, scoring, lives
js/levels.js          30 levels, Endless, twists, seeded routine generator (pure)
js/rules.js           every number for points, stars, bananas, timers (pure)
js/moves.js           the 6 moves, 4 combos, names, icons
js/monkey.js          the 3D monkey: parts, hands, eyes and lids, tail, faces, moves, springs
js/stage.js           renderer, graphics levels, shadows, camera, 4 stages, dance pad, effects
js/gfx.js             mesh merging, painted textures, rim light and wind shaders
js/audio.js           beat clock, synth music per stage, move notes, effects
js/input.js           pad, keyboard, swipe, tap-the-monkey
js/ui.js              menus, map, wardrobe, settings, How it works, stats, HUD
js/save.js            local save, ledger, export/import
js/shop.js            gear in 8 slots, Flair moves, stages (prices)
js/gear.js            builds each gear item in 3D, its animation, wardrobe thumbnails
js/store.js           Shop products, prices, bonuses (pure)
js/billing.js         App Store / Google Play purchases (cordova-plugin-purchase), test mode
js/storeui.js         Shop screen, grown-up check, thank-you card
js/skins.js           the 100 skins, 13 sets, 50 play goals (pure)
js/patterns.js        fur pattern painter + 2D skin portraits
js/skinlook.js        puts a skin on the 3D monkey (finishes, extras, auras)
js/wardrobe.js        Skins and Outfits tabs, golden banana swap, unlock card
js/native.js          phone features: app bridge (haptics, back button, keep awake), wake lock, silent switch
js/vendor/            three.js r162 (MIT; the last version that also runs on WebGL 1 phones)
sw.js                 offline cache (list generated by scripts/build_sw.py)
manifest.webmanifest  install as an app
tests/unit.mjs        507 checks on the rules, generator, skins, gear and Shop (Node)
tests/acceptance.js   34-step play-through in Chromium (Playwright), incl. Shop test mode and graphics levels
tests/devices.js      12 phone checks: simulated iOS/Android app shell, WebGL 1, 320 px to tablet, sideways
scripts/              icons, service-worker list, web/phone/single-file builds
mobile/               iOS + Android app projects (Capacitor 8), CI configs, phone guide
dist/www/             the phone/web build (host it, or the apps load it)
dist/                 single-file builds (see RUN.md)
PRIVACY.md            privacy policy for the stores (nothing is collected)
docs/STORE_PRODUCTS.md  the 26 in-app products to create in each store
scripts/make_store_files.mjs  writes that list and the Xcode StoreKit test file
```

See [RUN.md](RUN.md) for running, testing, building and installing on a phone.
