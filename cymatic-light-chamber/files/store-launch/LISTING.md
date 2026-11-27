# Store listing: Cymatic Light Chamber

Copy-paste text for Google Play and the App Store. Everything here passes the claims linter (`pnpm claims:lint`): no health claims, every picture called a simulation.

| Field | Value |
|---|---|
| App name (both stores) | **Cymatic Light Chamber** |
| Name under the icon | Light Chamber |
| Package / bundle ID | `com.eddieg.cymaticlightchamber` |
| Version | 1.0.0 (Android versionCode 1; iOS build number set by Codemagic) |
| Apple subtitle (30 max) | Sound shapes water and light |
| Google short description (80 max) | Tones make water draw geometric light: 30 styles, 15 light shows, build guide |
| Apple keywords (100 max) | cymatics,water,light,sound,frequency,tone generator,caustics,geometry,3D printing,light show,DIY |
| Category | Google Play: **Entertainment**. App Store: primary **Entertainment**, secondary **Music** |
| Price | Free, no in-app purchases, no ads |
| Website | https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber/ |
| Privacy policy URL | https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber/privacy/ |
| Support URL | https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber/support/ |
| Support email | **You choose** (Google Play shows it publicly; a separate Gmail is a good idea, as for Alien Sudoku) |

## Full description (both stores)

```
Sound shapes water. Water shapes light.

Cymatic Light Chamber is the companion app for a small water-and-light chamber you can build yourself. A thin layer of water sits in a dish; a speaker shakes it with tones, and the rippling surface bends light into geometric patterns on your wall: hexagons, rings, stars, quasicrystals and more.

WHAT'S INSIDE
• Voyage console: a tone engine for your amplifier and exciters, with a live simulated preview of the light. Single tones, two-tone ratios, gentle pulses and slow "breathe" swells, sweeps, and a pattern atlas to log what your own dish does.
• 30 styles: each one is a printable gobo, a dish insert, a wave source and a signal, with pictures of the expected look.
• 15 light shows: ten minutes each, and every show flows into the next for one 150-minute journey.
• Build guide: a 77-page illustrated manual, five chamber designs from a $0 flashlight test to a venue build, and ready-to-print STL and Bambu Studio files.
• Works offline once installed.

SAFE BY DESIGN
• No strobe mode. Light changes are slow and limited, and two tones that would make the light flicker at 3 to 60 times a second are turned down automatically.
• Sound starts quietly, fades in and out, and a FADE ALL button is always on screen.

HONEST BY DESIGN
• Every pattern picture and video in the app is a simulation from a physics model, and is labelled SIMULATION.
• This is an art and relaxation experience. It is not a medical device and makes no health claims.
• No account, no ads, no tracking. Nothing you do leaves your phone.

The chamber itself is a do-it-yourself build: low-voltage electronics, a glass dish and 3D-printed parts. The app is fully usable without it as a tone console and pattern explorer.
```

## What's new (1.0.0)

```
First release: the Voyage console, 30 styles, 15 light shows and the build guide.
```

## App Store: App Privacy

**Data Not Collected.** (No data is collected from this app.)

## App Store: age rating

Answer **None** / **No** to every question → **4+**. No web browsing inside the app (external files open in the browser), no user-generated content, no gambling, no contests.

## App Store: review notes

```
No account or login is needed.

The app is a companion for a do-it-yourself water cymatics light chamber, but every feature works on its own:
- Play tab: the Voyage console. Tap "Start audio" (sound starts quietly and fades in). Pick a style or show; the preview draws a simulated light pattern.
- Styles and Shows tabs: 30 styles and 15 shows with pictures, settings and timelines.
- Build tab: the manual and printable files (they open in Safari from our website).

All pattern pictures are labelled SIMULATION. There is no strobe or flashing mode; a flicker guard limits light changes. The app makes no health claims.
```

## Google Play: Data safety

- Does your app collect or share any of the required user data types? **No.**
- (Everything else follows from that answer. The app stores two settings on the device only: that the safety notice was accepted, and the optional pattern atlas.)

## Google Play: other App content answers

| Form | Answer |
|---|---|
| Privacy policy | the privacy URL above |
| Ads | No, the app does not contain ads |
| App access | All functionality is available without special access |
| Content rating (IARC questionnaire) | Category **Entertainment**; answer **No** to violence, sexuality, language, controlled substances, gambling, user interaction and sharing location → rated Everyone / PEGI 3 |
| Target audience | **13-15, 16-17 and 18+** (not designed for children) |
| News app | No |
| Health apps declaration | The app has **no health features** |
| Government app | No |
| Financial features | None |

## Graphics

| Asset | File |
|---|---|
| Google Play icon 512 × 512 | `store-launch/graphics/google-icon-512x512.png` |
| Google Play feature graphic 1024 × 500 | `store-launch/graphics/google-feature-graphic-1024x500.jpg` |
| Google Play phone screenshots 1080 × 1920 | `store-launch/screenshots/google-phone/*.jpg` (5) |
| App Store iPhone 6.9" screenshots 1290 × 2796 | `store-launch/screenshots/apple-iphone-6.9in/*.jpg` (5) |
| App Store iPad 13" screenshots 2064 × 2752 | `store-launch/screenshots/apple-ipad-13in/*.jpg` (5) |
| App Store icon 1024 × 1024 | built into the app (`apps/mobile/ios/App/App/Assets.xcassets`); copy in `store-launch/graphics/apple-icon-1024x1024.png` |

Screenshots are made from the real app by `store-launch/make_store_assets.cjs`; the patterns in them are simulations and are labelled SIMULATION on screen.
