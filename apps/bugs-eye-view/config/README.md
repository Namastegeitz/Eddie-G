# config/ - crash-reporting keys (never committed)

| File | What | Where it comes from |
|---|---|---|
| `crash_reporting.cfg` | Sentry DSN | Copy `crash_reporting.example.cfg` and paste the DSN from Sentry (Settings > Projects > Client Keys). The release workflow writes it from the `BUGS_SENTRY_DSN` secret. |
| `google-services.json` | Firebase Android app config | Firebase console > Project settings > Your apps > Android app `com.aethertek.bugseyeview` > download. The release workflow writes it from the `BUGS_GOOGLE_SERVICES_JSON_BASE64` secret. |

Both are git-ignored. Without them the game builds and runs exactly as
before and never sends anything. With them, nothing is sent until the
player says yes to crash reports (asked once; Settings > Privacy & about).
