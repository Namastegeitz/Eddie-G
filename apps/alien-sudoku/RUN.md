# Running and building Alien Sudoku

Everything runs from `apps/alien-sudoku` with Node 22 or newer.

```bash
npm install
```

## Play it on the computer (development)

```bash
npm run dev
```

Open the URL it prints (http://localhost:5173). The same URL works on a phone on
the same Wi-Fi network if you use the "Network" address.

### Keyboard

| Key | Action |
|---|---|
| Arrows / WASD | Move the selection |
| 1–9 | Place a glyph |
| Backspace / Delete / 0 | Erase |
| N | Notes on/off |
| U or Ctrl+Z | Undo |
| H | Hint |
| P | Pause |
| Esc | Back / pause |

## Tests

```bash
npm test
```

Runs the unit tests: engine, game rules, and progress/stats.

```bash
npx playwright install chromium
```

Installs the browser for the end-to-end tests (needed once).

```bash
npm run test:e2e
```

Runs the end-to-end tests. They build the game, then play real games through the
UI on a phone-sized screen and a desktop-sized screen: win, lose plus a second
chance, resume after a reload, daily streak, campaign unlock, keyboard, and settings.

## Web build (any static host, installable PWA)

```bash
npm run build
```

`dist/` can go on any static host (Netlify, Cloudflare Pages, GitHub Pages,
itch.io as an HTML game, or `npx surge dist`). It uses relative paths, so a
sub-folder works too. In Chrome/Edge, the install icon in the address bar
installs it as a desktop app. On iPhone, use Share → Add to Home Screen.

### Playable link and offline file

A private, playable copy is published at
<https://claude.ai/artifact/NdYUzQJYiAGjCra9nF7MHn>. It works on phones and
computers, and progress is saved in that browser.

The same game is also one self-contained file: `play/AlienSudoku.html`.
Download it and double-click it to play in any browser, with no internet needed.

Both come from:

```bash
node tools/package-artifact.mjs /tmp/alien-sudoku-artifact
```

That command builds one bundle and inlines the code, styles, fonts and space
images (about 1.4 MB). It writes two files: `alien-sudoku.html`, a page fragment
for hosts that add their own `<html>` wrapper, and `AlienSudoku.html`, a complete
page for double-click play and the artifacts connector. The artifact viewer's sandbox
doesn't reliably load scripts from separate files, so the page has to be one
file. Copy the result to `play/AlienSudoku.html` and publish it to the same
artifact.

## Automatic builds (GitHub Actions)

> **Status (Nov 3, 2026):** GitHub refused to start any Actions job in this repository.
> Every job failed in about 2 seconds without a runner, including a plain `echo` job. That
> points to an account-level block, usually a billing problem or a spending limit. Check
> GitHub → Settings → Billing and plans (and Settings → Actions → General in the
> repository), then re-run the "Alien Sudoku" workflow from the Actions tab.

Every push that changes `apps/alien-sudoku/` runs `.github/workflows/alien-sudoku.yml`.
The workflow tests everything, builds every platform, and replaces the
**alien-sudoku-latest** GitHub release with fresh files:

| File | Use |
|---|---|
| `AlienSudoku-*-android-debug.apk` | Install on an Android phone: open the release page on the phone, download, open, and allow installs from that source. |
| `AlienSudoku-*-ios-simulator.zip` | Runs in the iOS Simulator on a Mac. |
| `AlienSudoku-*-win-x64.exe` | Windows installer. |
| `AlienSudoku-*-win-portable.exe` | Windows app that runs without installing. |
| `AlienSudoku-*-mac-universal.dmg` | macOS app for Intel and Apple Silicon. |
| `AlienSudoku-*.AppImage`, `*.deb` | Linux. |
| `AlienSudoku-*-web.zip` | The web build. |

**Unsigned apps.**
- **Windows:** SmartScreen says "Windows protected your PC". Click **More info → Run anyway**.
- **macOS:** right-click the app → **Open** the first time.

Code-signing certificates remove these warnings (see the store checklist).

Optional repository secrets turn on real ads and signed store builds. They are
listed at the top of the workflow file and explained in
[docs/STORE_CHECKLIST.md](docs/STORE_CHECKLIST.md).

## Android (local)

Needs Android Studio, which provides the SDK, and Java 21.

```bash
npm run build && npx cap sync android
```

```bash
npx cap open android
```

The second command opens the project in Android Studio. Press Run to install on a
phone or emulator. To build a debug APK from the command line instead:

```bash
cd android && ./gradlew assembleDebug
```

The APK is written to `android/app/build/outputs/apk/debug/app-debug.apk`.

Signed release: create `android/keystore.properties` (never commit it). It holds
`storeFile`, `storePassword`, `keyAlias` and `keyPassword`. Then:

```bash
cd android && ./gradlew bundleRelease
```

## iOS (local, needs a Mac with Xcode 16 or newer)

```bash
npm run build && npx cap sync ios
```

```bash
npx cap open ios
```

In Xcode, select the **App** target. Under **Signing & Capabilities**, pick your
team, then choose an iPhone or a simulator and press Run. The Swift packages
(Capacitor, Google Mobile Ads) download on the first build. No CocoaPods are needed.

## Desktop (local)

```bash
npm run build
```

```bash
cd desktop && npm install
```

```bash
npm start
```

`npm start` runs the desktop app. To build an installer for the current OS:

```bash
npm run dist
```

Installers are written to `desktop/out/`.

To build for other systems from Linux:

```bash
npx electron-builder --win --publish never
```

```bash
npx electron-builder --linux --publish never
```

```bash
npx electron-builder --mac zip --publish never
```

Windows installers built on Linux need Wine with 32-bit support (on Ubuntu:
`dpkg --add-architecture i386 && apt-get install wine64 wine32:i386`). A Mac
`.dmg` and a universal (Intel and Apple Silicon) build need a real Mac or CI; from
Linux you get an Intel `.zip`, which also runs on Apple Silicon through Rosetta.

```bash
npm run smoke
```

Checks that the menu loads with no errors (CI runs this on Linux).

## Ads (AdMob)

1. Create the app twice in AdMob, once for Android and once for iOS. You get an **app id**
   (`ca-app-pub-…~…`) for each.
2. Create 3 ad units per platform: Banner, Interstitial and Rewarded. You get **unit ids** (`ca-app-pub-…/…`).
3. Put the app ids into the native projects:

   ```bash
   ADMOB_ANDROID_APP_ID=ca-app-pub-XXX~YYY ADMOB_IOS_APP_ID=ca-app-pub-XXX~ZZZ node tools/set-admob-ids.mjs
   ```

4. Put the unit ids in `.env` (copy `.env.example`), or into the same-named
   GitHub secrets for CI builds.

Where the ads appear:
- **Banner:** bottom of the screen on phones.
- **Interstitial:** only after a finished puzzle. At most one every 3 minutes, and every 2nd puzzle at most.
- **Rewarded:** always optional. Used for hints beyond the 3 free per puzzle, and for a second chance after losing.

If no rewarded video loads, the player gets the reward anyway.

## Change the game

| What | Where |
|---|---|
| Puzzles | `npm run gen:puzzles` regenerates `src/data/puzzle-pool.json`. Options: `--easy= --medium= --hard= --alien= --seed=`. Changing the pool changes campaign and daily puzzles. |
| Icons and splash | Edit `tools/gen-icons.mjs`, then run `npm run gen:icons` and `npx capacitor-assets generate --ios --android`. |
| Campaign sectors | `src/data/sectors.js` |
| Achievements | `src/data/achievements.js` |
| Glyph lineups | `src/data/glyphs/<lineup>.js`: 9 SVG symbols (viewBox 64×64), names, colors and gradient defs. Check the art with `node tools/glyph-sheet.mjs <lineup>`, which renders a contact sheet at game sizes. |
| Lineup themes | `src/data/themes.js` for colors, fonts, radius, glow and backdrop; `src/styles/themes.css` for each style's extra touches |
| Scoring | `src/game/session.js` (`DIFF_MULT`, `COMBO_WINDOW_MS`, points constants) |
| Lives, free hints | `src/game/session.js` (`MAX_MISTAKES`, `FREE_HINTS`) |
| Ad frequency | `src/platform/ads.js` |
| Version | `package.json`, `desktop/package.json`, `APP_VERSION` in the workflow. Android and iOS build numbers come from the CI run number. |
