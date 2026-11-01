# Store export checklist

What you need to install or provide before each platform's export works on
your machine. The presets are already configured; nothing below blocks a
normal build or test run.

Bundle / package id everywhere: **com.aethertek.bugseyeview** (placeholder;
change it in `export_presets.cfg` before your first store upload, because it
can't change afterwards).

## Android (APK for testing, AAB for Google Play)

Install:
- [ ] **JDK 17 or newer** (e.g. Eclipse Temurin).
- [ ] **Android SDK**: install Android Studio, then in SDK Manager add
      *Android SDK Platform-Tools*, *Android SDK Build-Tools 35*,
      *Android SDK Platform 35* and *Android SDK Command-line Tools*.
- [ ] In Godot: **Editor > Editor Settings > Export > Android**: set
      *Android SDK Path* (usually `C:\Users\<you>\AppData\Local\Android\Sdk`)
      and *Java SDK Path*. Godot creates a debug keystore by itself.

Test build:
- [ ] Export the **Android** preset (debug APK) and install it on a phone with
      `adb install build/android/bugseyeview.apk`, or copy the APK over and
      open it (allow installs from unknown sources).

Google Play:
- [ ] **Project > Install Android Build Template** (once). The *Android AAB*
      preset uses a Gradle build with min SDK 24 and target SDK 35.
- [ ] Create an upload keystore (keep it safe; you need it for every update):
      `keytool -genkeypair -v -keystore bugseyeview-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
- [ ] Put it in the *Android AAB* preset (Keystore > Release, user, password),
      or set `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `..._USER` and
      `..._PASSWORD` environment variables so passwords stay out of the repo.
- [ ] Raise `version/code` for every upload.
- [ ] Google Play Console developer account (one-time fee), store listing,
      screenshots, content rating, data safety form. The game collects no data
      and requests one permission: `VIBRATE` (haptics).

## iOS (App Store / TestFlight)

The *iOS* preset exports an **Xcode project** (`build/ios/`), not an `.ipa`.
Building, signing and uploading need macOS and Xcode.

- [ ] **Apple Developer Program** membership (yearly fee).
- [ ] Register the bundle id `com.aethertek.bugseyeview` and create the app in
      App Store Connect.
- [ ] Put your 10-character **Team ID** in the *iOS* preset
      (`application/app_store_team_id`). It is currently the placeholder
      `ABCDE12345`, which Godot requires before it will export at all.
- [ ] Build route, pick one:
  - **A Mac with Xcode 16+**: open `build/ios/BugsEyeView.xcodeproj`, pick
    your team under Signing, then Product > Archive > Distribute.
  - **No Mac (you're on Windows): Codemagic's cloud Macs**. Push this repo to
    GitHub, connect it at codemagic.io, add an App Store Connect API key, and
    use the workflow in [ci/codemagic.yaml](ci/codemagic.yaml). It installs
    Godot, exports the Xcode project, archives it and uploads to TestFlight.
- [ ] App Store listing, screenshots (6.9" and 6.5" iPhone, 13" iPad), App
      Privacy answers (no data collected), age rating.

## Windows

- [ ] Nothing extra: the export embeds the icon and game data into one `.exe`.
- [ ] Optional: code-sign the `.exe` (signtool + a code-signing certificate)
      so Windows SmartScreen doesn't warn players.
- [ ] Stores: itch.io (zip the folder), Steam (Steamworks partner account).

## macOS

- [ ] Exports an unsigned universal `.zip`. Players can run it with
      right-click > Open.
- [ ] To distribute without warnings: Apple Developer ID certificate plus
      notarization. Set `codesign/codesign` and `notarization/notarization` in
      the *macOS* preset; this needs a Mac (or `rcodesign` on other systems).

## Linux

- [ ] Nothing extra. `chmod +x BugsEyeView.x86_64` and run it.

## Web

- [ ] Nothing extra. Upload `build/web` to any static host (see RUN.md). The
      build is single-threaded, so it needs no cross-origin isolation headers.
