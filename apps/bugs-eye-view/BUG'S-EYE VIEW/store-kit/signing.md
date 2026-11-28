# Signing keys - what they are and where they live

**Never in the repository.** `.gitignore` blocks `*.keystore`, `*.jks`,
`config/crash_reporting.cfg` and `config/google-services.json`.

| Key / secret | Used for | Lives in | Backup |
|---|---|---|---|
| Android upload keystore (`bugseyeview-upload.keystore`) + password | Signing the Google Play .aab | Your computer + GitHub secret `BUGS_ANDROID_KEYSTORE_BASE64` (with `BUGS_ANDROID_KEY_ALIAS`, `BUGS_ANDROID_KEY_PASSWORD`) | USB stick + password manager. If lost, Play Console can reset it. |
| Apple distribution certificate + App Store Connect API key (.p8) | Signing and uploading the iPhone build | Apple Developer account; CI secrets on the Mac runner | The .p8 downloads once - keep it in the password manager |
| Apple Developer ID certificate (G2) | Notarized Mac builds for Steam/Epic | Apple Developer account | Re-issue on the G2 CA before 1 Feb 2027 |
| Sentry DSN | Crash reports | GitHub secret `SENTRY_DSN` (or local `config/crash_reporting.cfg`) | In Sentry: Project > Client Keys |
| Firebase `google-services.json` | Android crash reports | GitHub secret `FIREBASE_ANDROID_CONFIG` (or local `config/google-services.json`) | Firebase console > Project settings |
| Steam / Epic / Microsoft / GOG logins | Store uploads | Your password manager, with two-factor authentication | |

Windows builds are unsigned (you chose no paid signing on 28 Nov 2026);
Microsoft Store copies are signed by Microsoft for free.
