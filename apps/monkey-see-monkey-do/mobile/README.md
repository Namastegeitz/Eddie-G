# Monkey See, Monkey Do on phones (iPhone, iPad, Android)

There are three ways to put the game on a phone. They all run the same code
(`dist/www`, built by `node scripts/build_web.mjs`).

| Way | Works on | What you need | Offline | Store |
|---|---|---|---|---|
| **1. Browser + "Add to Home Screen"** | every iPhone (Safari, iOS 14.5+) and Android (Chrome 87+) | the game hosted on any HTTPS site | yes, after the first visit | no |
| **2. Android app** (`mobile/android`) | Android 7.0+ | a PC with Android Studio, or a cloud build | yes | Google Play (optional) |
| **3. iPhone / iPad app** (`mobile/ios`) | iOS 15+ | a Mac with Xcode, or Codemagic (cloud Mac) + Apple Developer account | yes | App Store / TestFlight |

## 1. Browser (fastest; any phone)

1. Host `dist/www` on any HTTPS static host. The public beta already does
   this: `node scripts/build_web.mjs` copies the build to the repository's
   `/docs` folder, and GitHub Pages serves it at
   https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/ once Pages is
   switched on (Settings > Pages > Deploy from a branch >
   `claude/nifty-lamport-bfm2ub`, folder `/docs`). Netlify, Cloudflare Pages
   or surge work too: upload `dist/www`.
2. On the phone, open the link once.
   - **iPhone (Safari):** Share > **Add to Home Screen**.
   - **Android (Chrome):** menu > **Install app** (or Add to Home screen).
3. It opens full screen with its own icon and plays with no connection.

The private Claude artifact link also plays in any phone's browser. To let
other people open it, use the artifact page's **Share** menu.

## 2. Android app

**Build an APK on a PC** (Windows, Mac or Linux):

1. Install [Node 22+](https://nodejs.org) and
   [Android Studio](https://developer.android.com/studio) (it brings the
   Android SDK and Java).
2. In a terminal:
   ```
   cd apps/monkey-see-monkey-do/mobile
   npm ci
   npm run sync              # builds dist/www and copies it into the app
   npx cap open android      # opens Android Studio
   ```
3. In Android Studio: plug in your phone (USB debugging on) and press **Run**.
   Or **Build > Build App Bundle(s) / APK(s) > Build APK(s)**, then copy
   `android/app/build/outputs/apk/debug/app-debug.apk` to the phone and open it
   (allow "install unknown apps" for your file manager or browser).

From a terminal with the SDK installed, `scripts/build_mobile.sh` does all of
it and leaves the APK in `dist/android/`.

**Google Play:**

1. Make an upload key once (keep it safe; Play needs the same key for every update):
   ```
   keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Create `mobile/android/keystore.properties` (it's in `.gitignore`):
   ```
   storeFile=/full/path/to/upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
3. `scripts/build_mobile.sh release` writes `dist/android/monkey-see-monkey-do-release.aab`.
4. In [Play Console](https://play.google.com/console) ($25 once): create the app,
   upload the `.aab` to Internal testing first, then Production. See the checklist below.

## 3. iPhone / iPad app

**With a Mac:**

```
cd apps/monkey-see-monkey-do/mobile
npm ci
npm run ios:open        # builds, copies, opens Xcode
```

In Xcode: select the **App** target > Signing & Capabilities > pick your Team
(a free Apple ID works for your own phone for 7 days; the $99/year Apple
Developer Program for TestFlight and the App Store). Plug in the iPhone and
press **Run**.

**Without a Mac:** Codemagic builds on cloud Macs and uploads to TestFlight.
Copy `mobile/ci/codemagic.yaml` to the repository root and follow the setup
notes at the top of that file. You still need the Apple Developer Program.

## Cloud builds on GitHub

`.github/workflows/monkey-see-monkey-do-mobile.yml` builds the APK, the Play
bundle, an iOS Simulator app and an unsigned `.ipa`. It runs only when you
start it (Actions tab > *Monkey See Monkey Do (phones)* > Run workflow) or
push a tag like `monkey-v1.0.0`. At the moment GitHub refuses to start
Actions jobs on this account (every run stops in about 3 seconds with no
log), so check Settings > Billing and plans > Actions first.

## How the phone versions behave

- **Portrait on phones.** The apps lock portrait on phones and rotate on
  tablets. In a browser, turning a phone sideways pauses the game and asks you
  to turn it back.
- **Sound.** The first tap starts the sound (browsers require it). On iPhone,
  Settings > Sound > *Play sound on silent* decides whether the ring/silent
  switch mutes the game. The iPhone app plays with the switch on silent and
  lets your own music keep playing.
- **Android back button:** closes a card, pauses a game, goes back a screen,
  and leaves the app from the title screen.
- **Haptics:** a light tap on each move, a buzz on mistakes, a double tap on
  a cleared round (Settings > Controls > Vibration).
- **Screen stays on** while you play, and sleeps normally on menus.
- **Status bar hidden**, and nothing sits under the notch, Dynamic Island,
  camera hole or gesture bar.
- **Older and cheaper phones:** WebGL 1 is supported (the 3D engine falls
  back by itself), Graphics: Auto drops to Low when frames are slow, and the
  Android app shows an "update Android System WebView" page if the phone's
  WebView is older than version 87.
- **No network of its own.** The Android app doesn't request the Internet
  permission, and the game makes no network requests. The Shop talks only to
  the App Store / Google Play app on the phone. Saves stay on the phone.

## Project facts

| | |
|---|---|
| App name on the home screen | Monkey Do |
| App ID / bundle ID | `com.namastegeitz.monkeydo` (change before the first store upload if you want a different one: `capacitor.config.json`, `android/app/build.gradle`, the Java package folder, and the iOS target's bundle identifier) |
| Version | 1.0.0 (Android versionCode 1, iOS build 1) |
| Minimum OS | Android 7.0 (API 24), iOS 15 |
| Engine | Capacitor 8.5.3 with App, Haptics, Splash Screen, Keep Awake, and cordova-plugin-purchase 13.19.1 (StoreKit 2 / Play Billing 9) |
| Icons and splash | made from `assets/icons/icon.svg` by `node scripts/make_app_icons.js` |

## In-app purchases (the Shop)

The Shop sells 26 products (packs, combo packs, a one-time Starter Pack,
themed bundles and premium skin sets, $0.99 to $9.99). It only takes money in
these apps; the web build shows the same Shop with a note that buying is in
the apps. The list with IDs, types, names and prices is
[`docs/STORE_PRODUCTS.md`](../docs/STORE_PRODUCTS.md) (also as
`docs/store-products.csv`). Both come from `js/store.js`; after changing a
product there, run `node scripts/make_store_files.mjs`.

Every product ID starts with `com.namastegeitz.monkeydo.` (for example
`com.namastegeitz.monkeydo.bananas_1200`). Packs are consumables (can be
bought again); the Starter Pack, bundles and sets are non-consumables (bought
once, brought back by *Restore purchases*).

**Always run `npx cap sync` in `mobile/` after `npm install`.** It recreates
`android/capacitor-cordova-android-plugins` and
`ios/capacitor-cordova-ios-plugins` (not in git), which hold the purchase plugin.

### Try purchases without a store account

- **Browser:** add `?billing=test` to the address (or `#store-test` on the
  artifact link). Purchases are pretend, instant and marked "test" in Stats.
- **iPhone Simulator:** `mobile/ios/App/MonkeyDo.storekit` is an Xcode
  StoreKit file with all 26 products. In Xcode: Product > Scheme > Edit
  Scheme > Run > Options > StoreKit Configuration > `MonkeyDo.storekit`. Then
  buy in the Simulator; Debug > StoreKit > Manage Transactions shows them,
  and you can refund or delete them there.
- **Android:** Play Billing only works with a build installed from Play (an
  internal testing track is enough) and a Google account listed as a
  license tester. Test cards never charge.

### App Store Connect (iPhone)

1. Agreements, Tax, and Banking: accept the **Paid Apps** agreement and fill
   in banking and tax. Products stay "Missing Metadata" until this is done.
2. Your app > Monetization > In-App Purchases: create each product from
   `docs/STORE_PRODUCTS.md` with exactly that Product ID, type, display name
   and description. Pick the price from the US price column and let Apple
   set the other countries. Add a review screenshot (the Shop screen; `node
   tests/devices.js` saves one).
3. In Xcode, Signing & Capabilities > + Capability > **In-App Purchase**.
4. Attach the products to the version you submit (the first products must go
   in with an app version). Test with a Sandbox account (Users and Access >
   Sandbox) or TestFlight.

### Google Play Console (Android)

1. Set up a **payments profile** (Settings > Payments profile) so the
   account can sell.
2. Upload a signed `.aab` with the purchase plugin in it to **Internal
   testing** first. Play only lets you create products once a build that
   uses billing has been uploaded.
3. Monetize > Products > In-app products: create each product from
   `docs/STORE_PRODUCTS.md` with the same ID (the full
   `com.namastegeitz.monkeydo....` text), name, description and price, and
   activate it.
4. Settings > License testing: add the Google accounts that will test.
   Install from the internal testing link (not with `adb install`).

### Rules the Shop already follows

- Prices come from the store, in the buyer's currency, and are shown before
  any tap. The web and test builds show US prices.
- A grown-up question (a times-table sum) comes before every purchase. It is
  on by default and needs the answer to turn off (Settings > Purchases). This
  is the parental gate Apple's Kids Category and Google's Families policy ask for.
- Optional monthly limit (5, 10, 20 or 50 in the store's currency). Raising
  or removing it needs the grown-up answer.
- No timers, no countdown offers, no pop-ups. The Shop opens only from its button.
- "Best value" goes to the pack with the most bananas per dollar, and each
  pack shows its bonus over the smallest pack. Bundles list what the items
  would cost separately in bananas and golden bananas.
- Nothing is only for sale: every skin and item can be earned by playing.
  If a bundle or set includes something already owned, it pays back 5 golden
  bananas per item.
- Every purchase is listed in Stats > Purchases, and the bananas it added are
  in Stats > Banana history. A transaction is never delivered twice.

### Not verified yet

Purchases were tested in the browser test mode only. The real App Store and
Google Play flows (prices loading, buying, *Restore*, refunds, pending
"Ask to Buy" purchases) need the store setup above and a real device.

## Store checklist

Both stores:

- **Privacy:** no data collected or shared, no ads, no accounts, no network.
  Purchases go through Apple and Google, and the purchase record stays on the phone.
  Both stores ask for a privacy policy link; `PRIVACY.md` in the app folder
  is written for that (link to it on GitHub).
- **Age rating:** suitable for everyone (no violence, no chat). Answer "yes"
  to in-app purchases; both stores show "In-app purchases" on the listing.
- **Screenshots:** `node tests/devices.js` saves phone and tablet screenshots in
  `tests/output/devices/`. The App Store wants 6.9" iPhone and 13" iPad sizes;
  Play wants at least 2 phone screenshots.
- **Short description:** "Watch the monkey dance, then copy the moves. A
  rhythm memory game with 40 levels on four maps, Endless mode and a banana wardrobe."

Google Play: Data safety form "No data collected", target audience, content rating questionnaire,
and an app category (Games > Music, or Puzzle).

App Store: App Privacy "Data Not Collected", category Games (Music/Puzzle),
and export compliance "No" (already set in Info.plist).
