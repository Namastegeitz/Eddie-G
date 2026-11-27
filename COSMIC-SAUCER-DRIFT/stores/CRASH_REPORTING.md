# Crash reporting: Sentry + Firebase Crashlytics (both free)

Added 27 Nov 2026 at Eddie's request ("add both sentry and firebase crashlytics. free of course").

## How it works in the game
- **Opt-in only.** The game sends nothing until the player says yes, either to a one-time question
  on the home screen or with Settings > Send crash reports. Saying no, or never answering, sends nothing.
- **Only in store builds.** The SDKs are installed into a copy of the game by
  `builds/store_build.sh`. The normal web, desktop and debug-APK builds (`builds/build_all.sh`) are
  unchanged and contain no crash reporter. That copy and its builds are git-ignored, because
  your DSN and Firebase files are baked into them.
- **What a report holds:** the crash (stack trace, the error message), device model, OS
  version, game version, and short notes like "race finished: quick mars, place 2". Sentry
  is set to send no personal data, no screenshots, no scene tree and no log file. Firebase
  starts with collection off ("privacy-safe defaults") and turns it on only after the player says yes.
- **Where:** Sentry on Android, iPhone/iPad, Windows, macOS and Linux. Firebase Crashlytics on
  Android and iPhone/iPad. Not on the web build. Sentry's web support needs a special engine
  build, so the web build stays without one.
- Code: `game/scripts/platform/crash_reporting.gd` (autoload `Crash`), settings in
  `game/content/crash_reporting.json`. Every call does nothing when the SDK is missing.

## One-time setup (Eddie). Free accounts, about 20 minutes
Nothing here costs money. Don't paste keys or files into chat.

### 1. Sentry (free Developer plan: 1 user, about 5,000 errors a month; check sentry.io/pricing)
1. Sign up at sentry.io and pick the **Developer** (free) plan.
2. Create a project, platform **Godot**, name `cosmic-saucer-drift`.
3. Copy the project's **DSN** (Settings > Projects > cosmic-saucer-drift > Client Keys).
4. Settings > Security & Privacy: turn on **Prevent Storing of IP Addresses**; keep **Data Scrubber** on.
5. Keep the DSN out of git:
   - for builds on your PC, set it in the terminal: `export SENTRY_DSN='…'`;
   - for GitHub Actions, add the repository secret `CSD_SENTRY_DSN`.

### 2. Firebase Crashlytics (free Spark plan)
1. console.firebase.google.com > **Add project** `cosmic-saucer-drift`. When asked about
   **Google Analytics, turn it off** (Crashlytics works without it, and less data leaves the phone).
2. Add an **Android** app with package `com.aethertek.cosmicsaucerdrift`, download `google-services.json`.
3. Add an **Apple (iOS)** app with bundle ID `com.aethertek.cosmicsaucerdrift`, download `GoogleService-Info.plist`.
4. Open **Crashlytics** in the console and click **Enable**.
5. Put both files in `COSMIC-SAUCER-DRIFT/private/` (git-ignored) and point the build at them:
   `export FIREBASE_ANDROID_CONFIG=…/private/google-services.json FIREBASE_IOS_CONFIG=…/private/GoogleService-Info.plist`.
   For GitHub Actions add the secrets `CSD_FIREBASE_ANDROID_CONFIG_BASE64` and
   `CSD_FIREBASE_IOS_CONFIG_BASE64` (base64 of each file).

### 3. Build
```
bash COSMIC-SAUCER-DRIFT/builds/store_build.sh aab ios windows linux macos
```
Needs Godot 4.7.2 with export templates, `gh` (signed in), `unzip`, `zip` and `python3`. For
`aab` you also need JDK 17, Android SDK platform 36 and your upload key, as in `build_all.sh`.
The add-on versions are pinned in `game/tools/store_addons/install_store_addons.sh`:
Sentry 2.5.1, Firebase 3.1.0, In-App Review v5.3. Results go to `builds/store/`, which is git-ignored.
In GitHub Actions: Actions > "Cosmic Saucer Drift (tests + builds)" > Run workflow makes a
debug-signed store AAB, to check the gradle build works. It never uploads anywhere.

### 4. Test it once
Install the store build on a phone, say **Yes** to crash reports, then make it crash, e.g.
with a debug-only button you add for the test, or Firebase's `crash()` test call. Restart the
game: the crash shows up in Sentry within a minute and in Crashlytics after the next launch.

## Before shipping a store build with crash reporting
1. **Privacy policy:** the updated text is in `game/docs/privacy-policy.html` ("Crash reports"
   section). The live policy page must show it before release. Republishing it needs Eddie's go.
2. **Google Play > Data safety.** Change from "No data collected" to:
   - Data collected: **Yes**. Shared: **No** (Sentry and Google process it for you as service providers).
   - Types: **App info and performance > Crash logs** and **Diagnostics**; **Device or other IDs**
     (Crashlytics installation UUID and Firebase installation ID).
   - Optional for users: **Yes**, players choose. Purpose: **App functionality** (fixing crashes).
   - Encrypted in transit: **Yes**. Deletion requests: by email to the support address.
     Crashlytics deletes crash data after 90 days.
   - Permissions: the store AAB adds **INTERNET** and **ACCESS_NETWORK_STATE**.
3. **App Store Connect > App Privacy.** Change from "Data Not Collected" to:
   - **Diagnostics > Crash Data** (and **Performance Data** / **Other Diagnostic Data** if you
     turn on more in Sentry), and **Identifiers > Device ID** (installation IDs).
   - Linked to the user: **No**. Used for tracking: **No**. Purpose: **App Functionality**.
   - Both SDKs ship their own Apple privacy manifests.
4. **Children:** if the Play target audience includes under-13s, crash SDKs must follow the
   Families policy (no ad ID, data minimised, disclosed). This setup collects no ad ID and is
   opt-in, but recheck the policy then. Don't put the game in Apple's **Kids** category with these SDKs.

Sources: Firebase "Prepare for Google Play's data disclosure requirements" and "App Store data
collection" pages; Firebase privacy page (Crashlytics identifiers, 90-day retention); Sentry
"Data Privacy for Mobile" and "Data Collected" docs; Apple "App privacy details on the App Store".
