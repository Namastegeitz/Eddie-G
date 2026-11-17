# Android (Google Play): ⛔ Blocked here

## What's here
- Nothing yet. The Android project is `game/android` (Capacitor 8, target API 36, id `com.eddieg.aliensudoku`).

## How to build it
```bash
cd ALIEN-SUDOKU/game
npm run cap:sync
cd android && ./gradlew bundleRelease     # signed AAB for Google Play (needs the upload key, see RUN.md)
./gradlew assembleDebug                    # debug APK for your own phone
```
This cloud workspace can't reach `dl.google.com`, so the Android SDK can't be installed here. Build on your own computer with Android Studio, fix GitHub Actions (prompt `02-github-actions.md`), or allow `dl.google.com` and `maven.google.com` (prompt `01-android-apk.md`).

## What the store needs
- Upload key (keep a backup), Play Console account, real AdMob ids. See **Google Play** in the checklist and `store-launch/google-play-and-admob.md`.

Live status: the **Launch checklist** in [`../../README.md`](../../README.md) and the Launch Control page.
