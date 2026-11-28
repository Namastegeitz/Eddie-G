# **CANOPY CROSSING: CRASH REPORTING**

Two free services, both off until you add their keys:

| Service | Covers | Free plan (checked 2026-11-27) | Made by |
|---|---|---|---|
| **Sentry** (official Godot SDK 2.5.1, MIT) | Android (.aab), iPhone/iPad, Windows, macOS, Linux | Developer plan: 1 user, about 5,000 errors a month | Functional Software, Inc. |
| **Firebase Crashlytics** (21.1.0, with native crashes) | Android (.aab) | Free, no limit on crash reports (Spark plan) | Google |

The web version and the plain test APK have neither: Sentry needs Gradle on
Android and GDExtension support on the web, which those two builds don't use.

## How it works in the game

- `autoload/crash_report.gd` (`CrashReport`) talks to both services. Without
  them (local builds, tests, the beta link) it does nothing.
- Reports carry: the error, where it happened in the game's scripts, the game
  version and build number, platform, device model, graphics setting, and the
  last steps (screen, jungle, level, view, purchases started/failed). Never a
  name, email, account, advertising ID or location.
- **Settings > Send crash reports** (on by default). Off: Crashlytics is told
  at once and remembers it; Sentry drops every report before sending
  (`before_send`), and doesn't start at all on the next launch.
- Script errors go to Crashlytics as non-fatal reports, once per different
  error and at most 25 per session. Sentry catches engine and script errors
  itself.
- Sentry options: no personal data (`send_default_pii` off), no screenshots,
  no scene dumps, no performance tracing; release `canopy-crossing@<version>+<build>`.

## What you do (once, about 15 minutes)

### Sentry

1. Sign up at https://sentry.io/signup/ (free Developer plan; no card needed).
2. Create a project: platform **Godot Engine**, name `canopy-crossing`.
3. Copy the project's **DSN** (Settings > Projects > canopy-crossing > Client
   Keys (DSN)). It looks like `https://abc123@o456.ingest.sentry.io/789`.
4. Settings > Security & Privacy: turn on **Prevent Storing of IP Addresses**
   (the privacy policy says so).
5. GitHub: repository **Settings > Secrets and variables > Actions > New
   repository secret**: name `SENTRY_DSN`, value the DSN.

### Firebase Crashlytics (Android)

1. Go to https://console.firebase.google.com/ and **Add project**
   (`canopy-crossing`; Google Analytics: **off**; it isn't needed).
2. Add an **Android app** with package name `com.aethertek.canopycrossing`.
3. Download **google-services.json** (skip the Gradle steps Firebase shows;
   the build does them).
4. In the Firebase console open **Crashlytics** and click **Enable**.
5. GitHub: new repository secret `FIREBASE_ANDROID_CONFIG`, value: the whole
   contents of google-services.json (open it in a text editor, copy all).
6. Don't put google-services.json in the repository (it's git-ignored).

### Then

Run **Actions > Canopy Crossing release builds**. The log says "SENTRY OK" and
"CRASHLYTICS LIBRARY OK (with Firebase config)". Install the .apk/.aab build
(internal testing on Google Play) or a desktop build; the first real crash
shows up in Sentry and in Firebase > Crashlytics. To see Crashlytics work
before then, Firebase's console shows "waiting for first crash" until a
report arrives (non-fatal errors count too).

## Store paperwork this changes

- **Google Play, Data safety**: Data collected: *App info and performance:
  Crash logs, Diagnostics*. Not shared (the services process it for us).
  Processed for: *App functionality*. Users can choose: *Yes, collection is
  optional* (Settings switch). Encrypted in transit: yes.
- **Apple, App Privacy**: *Diagnostics: Crash Data, Other Diagnostic Data*.
  Not linked to the user, not used for tracking, purpose: App Functionality.
  The build's privacy manifest declares the same (tools/install_sentry.sh adds
  it to the iOS export only when Sentry is built in).
- **Privacy policy**: the *Crash reports* section in
  `LAUNCH/shared/privacy-policy.md`.

## Not yet

- **Crashlytics on iPhone**: needs the iOS build made on a Mac (the planned
  macOS job). Sentry already covers iPhone crashes. When the Mac job exists,
  the godot-x/firebase iOS Crashlytics module (MIT) is the ready-made option.
- **Readable native stack traces**: the engine's official builds ship without
  debug symbols, so engine (C++) crashes show addresses, not function names.
  Script errors and Kotlin/Java crashes are fully readable.
- **Uploading debug symbols to Sentry** (`SENTRY_AUTH_TOKEN`): optional, for
  readable traces of Sentry's own native parts.
