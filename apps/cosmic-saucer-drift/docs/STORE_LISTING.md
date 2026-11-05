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

> Race alien spacecraft across real planets: drift, boost and blast rivals!

(73 characters)

## Full description (4000 max)

> Strap into an alien spacecraft and race real worlds astronomers have found!
>
> **Race the real galaxy.** Speed down Mars' Valles Marineris, past Io's
> volcanoes and across Saturn's rings, then leave the Solar System for
> TRAPPIST-1's seven worlds, the nearest stars at Alpha Centauri, and the
> strangest exoplanets known: a cobalt-blue giant with supersonic winds, a
> lava planet, a world with two suns and one where iron may fall as rain.
> Every track comes with real facts about the place you're racing.
>
> **Drift to boost.** Hold DRIFT through a corner and watch your sparks turn
> blue, orange, then purple. Let go for a Plasma Boost: the longer the drift,
> the bigger the blast.
>
> **Keep your core charged.** Your craft runs on Dark Matter. Grab Energy
> Pods, land mid-air tricks, slipstream rivals and dodge hazards by a whisker
> to refill it. Run dry and you'll limp along in Emergency Hover.
>
> **Power-up chaos.** Homing Rockets, Pulse Lasers, Comet Strikes, EMP
> Shockwaves, Nitro Rockets, Ion Shields, Gravity Mines and Tractor Beams.
> The further back you are, the better your comeback tools.
>
> **Fly alien spacecraft.** 14 detailed craft, from classic saucers to a
> living Bio-Ship, a Crystal Shard and premium showpieces like the Solar Sail
> Yacht and the Quasar Dragon, each with its own perk. Earn Race Credits to
> unlock and upgrade them, and customise paint, decals, domes and trails.
>
> **Pilots with personality.** Eight alien pilots who blink, look where
> you steer, grin when they boost, see stars when they're hit and cheer
> when they win.
>
> **Plenty to do.** Galactic Cups across four star systems and a Grand Prix
> finale, Quick Races, Time Trials against your own ghost, boss races to
> recruit eight alien pilots, a new Daily Challenge every day,
> achievements, and 2-player split-screen.
>
> - Plays offline
> - No ads, no in-app purchases
> - No account, no data collected
> - Touch joystick with gas and brake pedals (it drives itself if you
>   like), tilt steering, gamepad and keyboard supported
> - Graphics from Low to Ultra, picked automatically for your phone

## Graphics

| Asset | Size | File |
|---|---|---|
| App icon | 512 x 512 PNG | `docs/store/play_icon_512.png` |
| Feature graphic | 1024 x 500 | `docs/store/feature_graphic_1024x500.png` |
| Phone screenshots (2-8) | 1280 x 720 (16:9) | `docs/store/<world>.png` (mars, trappist1b, alpha_cen, hd189733b, kepler16b, wasp76b), `docs/store/menu_*.png` |

Suggested screenshot order: Saturn's Rings, HD 189733 b, TRAPPIST-1b, the
Galactic Cups screen, the Hangar with a premium craft, Mars.

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
