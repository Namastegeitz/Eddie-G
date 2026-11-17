# Store export checklist

## Google Play (Android) - the main target

### On your PC, once

- [ ] Install **Godot 4.7.2** and its **export templates** (Editor > Manage
      Export Templates > Download).
- [ ] Install **Android Studio** (or the command-line tools) and, in its SDK
      Manager: *Android SDK Platform 35*, *Android SDK Platform-Tools*,
      *Android SDK Build-Tools 35*, *Android SDK Command-line Tools*,
      *NDK* is not needed.
- [ ] Install a **JDK 17** (Android Studio bundles one).
- [ ] Godot: *Editor Settings > Export > Android*: set *Android SDK Path* and
      *Java SDK Path*. Godot makes a debug keystore by itself.
- [ ] *Project > Install Android Build Template* (needed for the AAB preset,
      which uses a Gradle build).

### Upload key (keep it safe: every update must be signed with it)

- [ ] `keytool -genkeypair -v -keystore cosmicsaucerdrift-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
- [ ] Put it in the *Android AAB* preset (Keystore > Release, user, password),
      or set `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`,
      `GODOT_ANDROID_KEYSTORE_RELEASE_USER`,
      `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` before exporting.
- [ ] Back it up somewhere other than this PC. Never commit it.

### Build

- [ ] Bump *Version Code* (integer, +1 every upload) and *Version Name* in
      both Android presets.
- [ ] `godot --headless --path . --export-release "Android AAB" build/android/cosmicsaucerdrift.aab`
- [ ] Test the APK on a phone first:
      `godot --headless --path . --export-debug "Android" build/android/cosmicsaucerdrift.apk`
      then `adb install -r build/android/cosmicsaucerdrift.apk`.

### Play Console

- [ ] Developer account (one-time fee) and identity verification.
- [ ] Create app: name, default language, Game, Free.
- [ ] *Set up your app*: privacy policy URL, app access, ads (No), content
      rating questionnaire, target audience, data safety: answers in
      `STORE_LISTING.md`.
- [ ] *Main store listing*: short + full description, icon, feature graphic,
      phone screenshots (`docs/store/`).
- [ ] *Play App Signing*: accept (Google holds the app signing key; you keep
      the upload key).
- [ ] New personal accounts must run a **closed test with at least 12
      testers for 14 days** before they can publish to production. Start an
      internal test first, then the closed test.
- [ ] Upload the AAB to the test track, add testers, roll out.
- [ ] After the closed test: apply for production access, then release.

## Web

- [ ] `godot --headless --path . --export-release "Web" build/web/index.html`
- [ ] Any static host works (GitHub Pages, itch.io as an HTML5 game). The web
      build uses the no-threads template, so it needs no special headers.
- [ ] For size-capped hosts: `python3 tools/web_artifact/package.py build/web build/web_artifact`.

## Desktop (optional)

- [ ] Windows: `--export-release "Windows Desktop"`. Unsigned builds show a
      SmartScreen warning; sign with a code-signing certificate to avoid it.
- [ ] macOS: `--export-release "macOS"`; distributing outside the App Store
      needs a Developer ID signature and notarization (from a Mac).
- [ ] Linux: `--export-release "Linux"`.

## iOS (later)

- [ ] Needs a Mac with Xcode, or a cloud Mac (e.g. Codemagic), plus an Apple
      Developer account. Export the Xcode project with the *iOS* preset
      (`application/export_project_only=true`), open it in Xcode, set the
      team, archive and upload. Set the real Team ID in the preset first.
