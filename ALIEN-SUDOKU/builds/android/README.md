# Android (Google Play): ✅ Built (version 1.3.0, versionCode 4)

## What's here
- `files/AlienSudoku-1.3.0-play.aab`: the upload for Google Play (signed with the upload key; Google re-signs it with Play App Signing). Upload it in step G3 of `store-launch/STEP-BY-STEP.md`.
- `files/AlienSudoku-1.3.0.apk`: installs directly on an Android phone for a quick try (same build). Uninstall it before installing from Google Play, because Play's copy is signed with Google's key.
- `files/AlienSudoku-1.3.0-mapping.txt`: R8 map for readable crash reports (also inside the AAB, so Play gets it automatically).
- `files/` is not in git. It exists on the machine that built it; ask Claude to send the files.
- Ads: Google's **test** ads until the real AdMob ids are set (step G6). Crash reports and Remote Config switch on when the Firebase file and Sentry DSN are added (guide C1, C2).
- Size: APK 15.4 MB, AAB 16.9 MB (Sentry and Firebase native SDKs; all native libraries are 16 KB-aligned).

## The upload key
- `alien-sudoku-upload.jks` (alias `upload`), certificate `CN=Alien Sudoku, O=Eddie G`,
  SHA-256 `C3:9A:0C:31:14:D3:72:F5:75:E1:5F:60:4B:82:52:47:1C:87:15:47:12:EA:E0:3E:2C:1D:1F:80:CB:6A:E7:77`.
- The owner keeps the `.jks` and its password; they are **never** committed. To build an update,
  give Claude the `.jks` and password (or put them in `game/android/keystore.properties`, which git ignores).
- If the key is ever lost: Play Console → Test and release → App integrity → request an upload key reset.

## How to build it
```bash
cd ALIEN-SUDOKU/game
npm run build && npx cap sync android
cd android && ./gradlew bundleRelease assembleRelease
# outputs: app/build/outputs/bundle/release/app-release.aab, app/build/outputs/apk/release/app-release.apk
```
Needs the Android SDK (platform 36, build-tools 36) and `android/keystore.properties`
(storeFile, storePassword, keyAlias=upload, keyPassword). In a Claude session, the "eddie-g"
cloud environment allows the SDK download. Release builds use R8 shrinking
(`app/proguard-rules.pro` keeps the Capacitor plugins).

## What the store needs
- Play Console account, the 14-day closed test, real AdMob ids. Follow **Google Play** in
  `store-launch/STEP-BY-STEP.md`.

Live status: the **Launch checklist** in [`../../README.md`](../../README.md) and the Launch Control page.
