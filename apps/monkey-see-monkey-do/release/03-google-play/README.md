# 03 · Google Play (Android)

**Build goes in:** `build/` (signed `app-release.aab`). Cost: $25 once.
App ID: `com.namastegeitz.monkeydo` · targets Android 16 (API 36), runs on Android 7.0+.

## Why the build isn't here yet

This cloud project can't download Google's Android tools (dl.google.com is
blocked). Two ways round it:

- **Your computer:** install Android Studio, open `mobile/android`, build there.
- **This project:** allow `dl.google.com` and `maven.google.com` in the
  project's environment; Claude then builds and tests the .aab itself.

## Build the release bundle

```
cd apps/monkey-see-monkey-do
node scripts/build_web.mjs
cd mobile && npx cap sync android
```

Create the upload key once and keep it safe (two places: a password manager and
an offline copy). Losing it means a support request to Google.

```
keytool -genkeypair -v -keystore monkeydo-upload.jks -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Put the details in `mobile/android/keystore.properties` (never commit it):

```
storeFile=/full/path/monkeydo-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Then in Android Studio: Build > Generate Signed App Bundle, or
`cd mobile/android && ./gradlew bundleRelease`. Copy
`app/build/outputs/bundle/release/app-release.aab` into `build/` here.

Bump `versionCode` (mobile/android/app/build.gradle) by 1 for every upload.

## Play Console, in order

1. Create the app: Game, Free, English (US).
2. Store listing: text from ../00-shared/store-text.md (title 30 / short 80 / full 4000),
   icon ../00-shared/icons/google-play-512.png, feature graphic
   ../00-shared/art/play-feature-graphic-1024x500.png, screenshots
   ../00-shared/screenshots/android-phone and ipad-13 (as tablet).
3. App content: [data-safety.md](data-safety.md), ads = none, content rating
   (../00-shared/age-rating.md), target audience (all ages; Families policy applies).
4. Internal testing: upload the .aab, add yourself, install from the link.
5. In-app products: payments profile, then the 26 products in
   ../../docs/STORE_PRODUCTS.md with the same IDs. Add yourself as a license tester.
6. Closed testing: 12+ testers opted in for 14 days in a row (new personal accounts).
7. Apply for production, then roll out.

The live checklist (claude.ai > MONKEY SEE, MONKEY DO > Launch Checklist) tracks each step.
