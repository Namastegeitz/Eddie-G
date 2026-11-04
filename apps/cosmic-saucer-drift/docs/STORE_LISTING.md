# Google Play store kit

Everything to paste into the Play Console for v1 (free, no ads, no data
collected). Graphics are in `docs/store/`.

## App details

- **App name** (30 max): `Cosmic Saucer Drift`
- **Default language:** English (United States)
- **App or game:** Game. **Category:** Racing.
- **Free or paid:** Free.
- **Tags** (pick up to 5): Arcade, Kart racing, Racing, Casual, Sci-fi.
- **Contact email:** your developer email (shown publicly).

## Short description (80 max)

> Drift UFOs around space tracks, charge Plasma Boost and blast rivals!

(69 characters)

## Full description (4000 max)

> Strap into a flying saucer and race the galaxy's wildest tracks!
>
> **Drift to boost.** Hold DRIFT through a corner and watch your sparks turn
> blue, orange, then purple. Let go for a Plasma Boost: the longer the drift,
> the bigger the blast.
>
> **Keep your core charged.** Your saucer runs on Dark Matter. Grab glowing
> Energy Pods, land mid-air tricks, slipstream rivals and dodge hazards by a
> whisker to refill it. Run dry and you'll limp along in Emergency Hover while
> everyone zips past.
>
> **Power-up chaos.** Smash glowing space crates for eight power-ups: drag
> rivals back with a Tractor Beam, drop a Meteor Strike on the leader, warp
> through hyperspace, fire homing Plasma Bolts, leave Gravity Mines, smear a
> Nebula Cloud over everyone ahead or open a Black Hole in their path. Hide
> behind an Ion Shield when it all comes back at you.
>
> **Six worlds, eighteen tracks.** Tumbling rocks in the Asteroid Belt,
> magnetic rails around a ringed giant, geysers and snapping plants on an
> alien jungle moon, a slippery comet tail, sweeping lasers on an orbital
> station and erupting lava. Every track hides a secret shortcut and three
> Star Shards, and unlocks Reverse and Mirror versions when you win it.
>
> **Build your crew.** Race eight alien pilots with their own abilities, from
> a drift-crazy rookie to a four-armed space captain who loves to bump. Beat
> them in Boss Races to add them to your crew.
>
> **Tune your saucer.** Six saucers, four upgradeable stats, and a garage of
> paints, decals, glass domes and engine trails.
>
> **Plenty to do.** Galactic Cups with stars to earn, Quick Races, Time Trials
> against your own ghost, a new Daily Challenge every day, achievements, and
> 2-player split-screen.
>
> - Plays offline
> - No ads, no in-app purchases
> - No account, no data collected
> - Touch buttons or tilt steering, gamepad and keyboard supported

## Graphics

| Asset | Size | File |
|---|---|---|
| App icon | 512 x 512 PNG | `docs/store/play_icon_512.png` |
| Feature graphic | 1024 x 500 | `docs/store/feature_graphic_1024x500.png` |
| Phone screenshots (2-8) | 1280 x 720 (16:9) | `docs/store/*_f1100.png`, `docs/store/menu_*.png` |

Suggested screenshot order: a race on Neon Ring of Saturn, the Alien Jungle
Moon, the Galactic Cups screen, the Garage, Comet Ice Run, Lava Moon.

## App content answers

- **Privacy policy:** host `docs/privacy-policy.html` (e.g. on GitHub Pages)
  and paste its URL.
- **Ads:** "No, my app does not contain ads."
- **App access:** "All functionality is available without special access."
- **Content rating (IARC questionnaire):** Category *Game*. Violence:
  cartoon/fantasy only (saucers spin out when hit by power-ups; nobody is
  hurt, no blood). No sexual content, language, drugs, gambling, or
  user-to-user interaction. No purchases. Expected result: PEGI 3 / ESRB
  Everyone.
- **Target audience:** choose 13+ (13-15, 16-17, 18+) for v1. Including
  under-13s puts the app under the Families policy; that's fine with no ads,
  but if you add ads later they must come from Families-certified ad SDKs.
  See `docs/ADS_PLAN.md`.
- **News app:** No. **COVID-19 app:** No. **Government app:** No.
- **Data safety** (v1):
  - Does your app collect or share any of the required user data types? **No.**
  - Is all data encrypted in transit? (not applicable, no data leaves the device)
  - Do you provide a way for users to request that their data is deleted?
    Not applicable; progress lives only on the device (Settings > Reset all
    progress, or uninstalling, removes it).
- **Permissions:** VIBRATE only (for haptics).
