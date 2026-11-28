# Alien Sudoku: notes for Claude

Read first: `UPGRADE_LEDGER.md` (what earlier upgrade runs finished; skip those), then
`UPGRADE_REPORT.md` (latest run), `store-launch/STEP-BY-STEP.md` (where the store launch stands).

## The project
- Game in `game/`: vanilla JS + Vite 8, Capacitor 8 (iOS, Android), Electron 45 (desktop), PWA (web).
- Bundle / package id `com.eddieg.aliensudoku`: never change it.
- No backend. Saves live in localStorage / Capacitor Preferences (`core/profile.js`, `core/storage.js`).
  New settings get defaults through `DEFAULT_SETTINGS` merging, so old saves keep loading.
- Owner choices on record: personal/individual store accounts; Sentry + Firebase Crashlytics
  (free) for crash reports; Remote Config, in-app review, Text Zoom: yes; desktop code signing:
  not now; PostHog analytics: no (the policy promises no analytics).

## Build
```bash
cd ALIEN-SUDOKU/game
npm ci
npm run build                                  # web build in dist/ (PWA)
node tools/package-artifact.mjs /tmp/out       # one-file game -> builds/web/AlienSudoku.html
node tools/build-site.mjs                      # website -> builds/site/ (publish to gh-pages /alien-sudoku/)
npx cap sync android && (cd android && ./gradlew bundleRelease assembleRelease)
cd desktop && npm run dist:win && npm run dist:linux   # mac: npx electron-builder --mac zip --x64 / --arm64
```
- Android SDK: the "eddie-g" cloud environment allows dl.google.com; install cmdline-tools,
  `platforms;android-36`, `build-tools;36.0.0` into /opt/android-sdk.
- Android signing: `game/android/keystore.properties` (git-ignored) pointing at the owner's
  `alien-sudoku-upload.jks`. The owner keeps the key and password; ask for them. Never commit either.
- iOS: no Mac. `codemagic.yaml` (repo root) builds, signs through an App Store Connect API key
  and uploads to TestFlight. Codemagic also has an Android workflow.
- Firebase files (`android/app/google-services.json`, `ios/App/App/GoogleService-Info.plist`)
  are git-ignored. When present, the build turns Crashlytics and Remote Config on (`__FIREBASE__`).
  Sentry turns on with `VITE_SENTRY_DSN`.
- Backdrops: `tools/hd/` (upscale + cut); originals in `assets/original/space/`.

## Test
```bash
npx vitest run                                             # unit (130)
PW_CHROMIUM=/opt/pw-browsers/chromium npx playwright test --trace off   # browser, phone + desktop (48 + 3 screenshot tests)
npm run test:visual                                        # screenshots at 3 sizes vs visual.spec.js-snapshots/
npm run bench                                              # fails if >5% worse than perf/baseline.json
```
- Playwright stays on 1.64.x: the preinstalled Chromium matches it.
- After an intended visual change: `npx playwright test visual --update-snapshots`, look at
  the new pictures, commit them.

## Release
1. Bump `version` in `game/package.json` and `game/desktop/package.json`, Android
   `versionCode`/`versionName` in `android/app/build.gradle`, iOS `MARKETING_VERSION` /
   `CURRENT_PROJECT_VERSION` in `ios/App/App.xcodeproj/project.pbxproj`.
2. Add the player-facing note to `CHANGELOG.md` and `store-launch/listing/listing.json` → `whatsNew`.
3. Run every test above; rebuild web, one-file, site, Android, desktop; store screenshots with
   `node tools/store-assets.mjs ../store-launch/assets`.
4. Never upload, submit or publish to a store without the owner's go. Plan: `store-kit/release-plan.md`.

## Roll back
- Code: each upgrade step is one commit; `git revert <commit>`. Run 1 started at commit 826fc25.
- A live release: Play Console → Halt rollout; App Store → Pause phased release. Ship a higher
  build number with the fix.
- Without a release: Remote Config `disable_ads`, `disable_interstitials`, `disable_rewarded`,
  `min_version`, `force_below_version`, `update_message` (see `src/platform/remote.js`).

## Rules that bite
- Apple review prompt: at most 3 per year, system card only, no pre-question, no reward.
- Google Play: target API 36 now; updates need 16 KB page support from Feb 1, 2027 (current
  native libraries are 16 KB-aligned; re-check after adding any native SDK).
- Google Mobile Ads legacy Android SDK v25 is deprecated Jun 30, 2027: move to the Next-Gen SDK before then.
- The space backdrops' rights are unconfirmed (`store-kit/credits.md`).
