# **ANDROID** build

| | |
|---|---|
| File | `BugsEyeView-test.apk` (68 MB) - **test build**, debug-signed |
| Version | 1.0.0 (build 1), exported 28 Nov 2026 |
| Runs on | Android 7.0+ (API 24), arm64 and armv7; targets API 36 |
| Package | `com.aethertek.bugseyeview` |

## Install the test build on a phone
1. Download `BugsEyeView-test.apk` on the phone (from GitHub, or copy it over USB).
2. Open it and allow installs from that app when Android asks.

## Crash reports on Android
The Google Play bundle (.aab) gets Firebase Crashlytics and Sentry when the
release workflow has your `FIREBASE_ANDROID_CONFIG` and `SENTRY_DSN` secrets
(both off until the player says yes). This test APK is built from Godot's
prebuilt template and has neither - it never goes online.

## The Google Play build (.aab) - needs your upload key
Google Play only takes a release-signed **Android App Bundle**. The project is ready (preset *Android AAB*, target API 36, 16 KB page alignment); it only needs your upload key from checklist step *Make your Android upload key*. Then either:
- **On your PC:** Godot 4.7.2 + export templates + Android SDK > Project > Export > *Android AAB* > set *Release* keystore, user and password > Export Project.
- **In the cloud (recommended):** add the keystore (base64) and its password as GitHub Actions secrets; Claude adds a workflow that builds the signed `.aab` for each release.

Keep the keystore and password out of git (`.gitignore` blocks `*.keystore` and `*.jks`).
