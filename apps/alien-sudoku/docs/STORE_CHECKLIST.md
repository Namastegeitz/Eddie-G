# Store checklist: Alien Sudoku

| | |
|---|---|
| App name | **Alien Sudoku** |
| Bundle / package id | **com.eddieg.aliensudoku** (permanent once published) |
| Version | 1.0.0 |
| Category | Games → Puzzle |

## 1. Accounts you need

- [ ] **Google Play Console**: one-time $25. <https://play.google.com/console>
- [ ] **Apple Developer Program**: $99/year. <https://developer.apple.com/programs/>
- [ ] **Google AdMob**: free, linked to a Google account. <https://admob.google.com>
- [ ] A public web page for the **privacy policy**. Use `docs/PRIVACY.md` and host it
      anywhere: GitHub Pages, Google Sites, or your own site.

## 2. AdMob

- [ ] Add two apps in AdMob, *Alien Sudoku (Android)* and *Alien Sudoku (iOS)*.
      Leave them "not published yet" and link them to the store listings later.
- [ ] Per app, create ad units: **Banner** (adaptive), **Interstitial**, **Rewarded**.
- [ ] **Privacy & messaging**: create a **GDPR** message (required for EU/UK users)
      and an **IDFA explainer** message for iOS. The app already asks for
      consent through Google's UMP SDK at launch, and Settings has an
      "Ad privacy choices" button whenever the user's region requires it.
- [ ] Put the ids in. Either run them locally:

  ```bash
  ADMOB_ANDROID_APP_ID=… ADMOB_IOS_APP_ID=… node tools/set-admob-ids.mjs
  ```

  Then add the unit ids to `.env`. Or add these GitHub secrets:
  - `ADMOB_ANDROID_APP_ID`, `ADMOB_IOS_APP_ID`
  - `VITE_ADMOB_ANDROID_BANNER`, `VITE_ADMOB_ANDROID_INTERSTITIAL`, `VITE_ADMOB_ANDROID_REWARDED`
  - `VITE_ADMOB_IOS_BANNER`, `VITE_ADMOB_IOS_INTERSTITIAL`, `VITE_ADMOB_IOS_REWARDED`
- [ ] **app-ads.txt**: AdMob shows a line like
      `google.com, pub-XXXXXXXX, DIRECT, f08c47fec0942fa0`. Put it in `app-ads.txt`
      at the root of the website you list as the developer website in both stores.
- [ ] iOS: add the full **SKAdNetwork** list from Google's iOS quick-start guide to
      `ios/App/App/Info.plist`. Google's own id is already there.
- [ ] Never click your own live ads. To test, register your phone as a test
      device (see the AdMob docs) or keep the test ids.

## 3. Google Play

- [ ] **Upload key.** Create it once and back it up. If you lose it, Google Play
      can reset it, but that takes time.

  ```bash
  keytool -genkeypair -v -keystore alien-sudoku-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
  ```

- [ ] Add GitHub secrets so CI builds the signed AAB:

  ```bash
  base64 -w0 alien-sudoku-upload.jks
  ```

  Put the output of that command in `ANDROID_KEYSTORE_BASE64`. Also set
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`) and `ANDROID_KEY_PASSWORD`.
  Or build locally with `android/keystore.properties` (see RUN.md).
- [ ] Create the app in Play Console, then go through **App content**:
  - [ ] Privacy policy URL.
  - [ ] **Ads**: Yes, contains ads.
  - [ ] **Target audience**: 13+ (or 18+). Choosing under-13 brings in the Families
        policy, which needs different ad settings.
  - [ ] **Data safety**: the AdMob SDK collects device or other IDs, approximate
        location (IP), app interactions, and diagnostics. These are used for
        advertising and analytics, shared with Google, and encrypted in transit.
        Users can't request deletion through the app (no account). The game
        itself stores progress only on the device.
  - [ ] Content rating questionnaire: puzzle game, no violence, contains ads.
  - [ ] Advertising ID declaration: **Yes** (AdMob uses it).
- [ ] Store listing: use the text in section 5 below, the icon (`assets/icon-only.png`, 512×512 export),
      a feature graphic (1024×500), and phone screenshots (at least 2).
- [ ] Upload `AlienSudoku-*-android-release.aab` to **Internal testing** first, then Production.
      New personal developer accounts must first run a **closed test with at least 12
      testers for 14 days** before Production access.

## 4. Apple App Store

- [ ] In App Store Connect, create the app: bundle id `com.eddieg.aliensudoku`, name *Alien Sudoku*.
- [ ] Signing without a Mac, via CI. Create an **App Store Connect API key**
      (Users and Access → Integrations → App Store Connect API, role *App Manager*)
      and add these GitHub secrets:
  - `APPLE_TEAM_ID`: 10 characters, from developer.apple.com → Membership.
  - `ASC_KEY_ID`
  - `ASC_ISSUER_ID`
  - `ASC_KEY_P8_BASE64`: the output of the command below.

  ```bash
  base64 -i AuthKey_XXXX.p8
  ```

  The iOS job then archives, signs automatically, and uploads each build to **TestFlight**.
- [ ] Or with a Mac: `npx cap open ios`, pick your team, then Product → Archive → Distribute.
- [ ] **App Privacy**:
  - "Data used to track you": Device ID (advertising).
  - "Data linked to you": none.
  - "Data not linked to you": Coarse location, Product interaction, Advertising data, Diagnostics.
  - The app shows the App Tracking Transparency prompt (text is in Info.plist).
- [ ] Age rating: 4+ (or 12+ depending on ad content settings in AdMob).
- [ ] Export compliance: already answered in Info.plist (`ITSAppUsesNonExemptEncryption = NO`).
- [ ] Screenshots: 6.9" and 6.5" iPhone, and 13" iPad (the app supports iPad).
- [ ] Test with TestFlight on your iPhone, then submit for review.

## 5. Store listing text

**Short description (80 characters):**
Decode alien glyph Sudoku: campaign, daily puzzles, zen mode and space music.

**Full description:**

> A transmission from a lost UFO archive has reached Earth, and only you can decode it.
>
> Alien Sudoku is classic Sudoku with glowing alien glyphs instead of numbers. Place
> each glyph exactly once in every row, column and box. Work through puzzles set
> over real space photography, with a soundtrack synthesized for each transmission.
>
> • CAMPAIGN: travel through 6 sectors and 54 transmissions, from Lunar Outpost to the Cluster Core.
> Earn up to 3 stars per level and unlock new symbol sets.
> • DAILY TRANSMISSION: a new puzzle every day, the same for everyone. Build your streak.
> • QUICK PLAY: Easy, Medium, Hard and Alien difficulty.
> • ZEN MODE: no lives, no clock, unlimited hints.
> • SMART HINTS: they don't just fill a cell, they tell you why it works.
> • Notes, auto-notes, undo, pause and autosave.
> • 7 symbol sets: alien glyphs, planets, moons, spaceships, aircraft and rockets, galaxies, and a mixed set.
> • 24 achievements and detailed stats.
> • Every puzzle has exactly one solution and is graded by the techniques it needs.
> • Plays offline.

**Keywords (iOS, 100 characters):**
sudoku,puzzle,alien,space,ufo,logic,brain,daily,glyph,number,zen,offline

## 6. Desktop distribution (optional)

- [ ] Windows: an Authenticode code-signing certificate removes the SmartScreen
      warning. Set `CSC_LINK` and `CSC_KEY_PASSWORD` for electron-builder.
- [ ] macOS: Apple Developer ID certificate plus notarization. Set `CSC_LINK`,
      `CSC_KEY_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD` and `APPLE_TEAM_ID`,
      and remove `"identity": null` from `desktop/package.json`.
- [ ] Storefronts: itch.io (upload `*-web.zip` as an HTML game, or the installers),
      Microsoft Store (needs an MSIX/appx target), Steam (needs Steamworks; $100 fee).
