# **CANOPY CROSSING: Android build**

**Stores:** Google Play (needs the `.aab`), Amazon Appstore and Samsung Galaxy Store (take the `.apk`).

| File | Use |
|---|---|
| `CanopyCrossing.apk` | Install straight onto a phone or tablet (testers, Amazon, Samsung) |
| `CanopyCrossing.aab` | The Android App Bundle Google Play requires for new apps |

**How it's built:** GitHub Actions, workflow *Canopy Crossing release builds*
(this machine can't reach Google's Android SDK download server). Package
name `com.aethertek.canopycrossing`; arm64-v8a + armeabi-v7a; min SDK 24.

**Signing (important):** Google Play remembers the *upload key* of your first
upload forever. Create it once, keep a backup somewhere safe, and give it to
GitHub as the secrets `CANOPY_ANDROID_KEYSTORE_BASE64`,
`CANOPY_ANDROID_KEY_ALIAS`, `CANOPY_ANDROID_KEY_PASSWORD`:

```bash
keytool -genkeypair -v -keystore canopy-upload.keystore -alias canopy-upload \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 canopy-upload.keystore      # paste this into CANOPY_ANDROID_KEYSTORE_BASE64
```

Without the secrets the workflow signs with a throwaway test key: fine for
installing on phones, not for Google Play. Turn on **Play App Signing** in
Play Console (Google keeps the final signing key; you keep the upload key).

**Test it:** install the APK (`adb install CanopyCrossing.apk` or open it on
the phone), play a level in both views, buy something in the sandbox store,
quit and relaunch (progress kept), rotate/lock the screen mid-run.

**Before Google Play accepts it:** real Google Play Billing plugin instead of
the sandbox store, real AdMob ids (or no ads), target API level the current
rule asks for, the upload key above. See `../../LAUNCH/google-play/`.
