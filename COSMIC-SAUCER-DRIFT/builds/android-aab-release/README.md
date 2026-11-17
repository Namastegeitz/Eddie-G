# Google Play bundle (AAB): not built yet

This is the file Google Play needs: `cosmicsaucerdrift-release.aab`.

**Why it's empty.** Three things are missing on the cloud computer:
1. The Android SDK platform 36 and its build tools. Google's download server
   (dl.google.com) is blocked in this session's network settings.
2. Your **upload key**: a keystore only you should hold. Never commit it.
3. Godot's Android build template (`Project > Install Android Build Template`).

Already done in the project: target SDK raised to **36** (Google's rule for new apps since
31 Aug 2026), 64-bit (arm64-v8a) on, category Game, no internet permission.

**To build it on your PC** (Godot 4.7.2, JDK 17, Android SDK with platform 36):
```
keytool -genkeypair -v -keystore cosmicsaucerdrift-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/safe/place/cosmicsaucerdrift-upload.jks
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='your password'
bash build_all.sh aab
```
Use the same password for the keystore and the key (Godot needs that). Back the keystore up
in two places. Bump `version/code` in the "Android AAB" preset before every upload.

**Or here:** allow `dl.google.com` in this session's network settings and ask Claude. You'd
still provide the key yourself.
