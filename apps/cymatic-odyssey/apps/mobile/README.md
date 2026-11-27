# apps/mobile: Android and iOS apps (Capacitor 8)

The store apps wrap the same build as the web app (`apps/web/dist`), so the phone app, the website and the
installable PWA are one codebase. Native features (BLE, haptics, keep-awake, background audio, camera) arrive in P8.

```bash
# 1. build the web app (repo: apps/cymatic-odyssey)
pnpm install && pnpm build
# 2. copy it into the native projects
cd apps/mobile && npm ci && npx cap sync
# 3. Android: signed release APK and Play bundle (needs Android SDK 36 + JDK 21, and android/keystore.properties)
cd android && ./gradlew assembleRelease bundleRelease
# 4. iOS: built on a cloud Mac by Codemagic (codemagic.yaml at the repository root)
```

- App ID: `com.eddieg.cymaticlightchamber`, name under the icon "Light Chamber", version 1.0.0 (versionCode 1).
- Release signing reads `android/keystore.properties` (storeFile, storePassword, keyAlias, keyPassword) or the
  `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` environment
  variables. The key and passwords are never committed (`.gitignore`).
- Icons and splash screens: `python3 apps/web/scripts/build_media.py` then `python3 apps/mobile/scripts/native_assets.py`.
- The service worker is skipped inside the apps (they already carry every file); big downloads open from the website.
- Store steps: `store-launch/STEP-BY-STEP.md`; listing text and form answers: `store-launch/LISTING.md`.

Not verified yet: the Android app on a physical phone or emulator, and the iOS build (needs Codemagic's Mac).
