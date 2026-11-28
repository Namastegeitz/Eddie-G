# Answers for the stores' forms

What to pick on each store's privacy, data and age-rating forms for
Bug's-Eye View as it is today: no accounts, ads, purchases or analytics;
saves only on the device; **optional crash reports** (asked once, off until
the player says yes) through Sentry (all platforms but the web) and Firebase
Crashlytics (Android). Updated 28 Nov 2026. If a build is made WITHOUT the
crash-reporting keys, the older "no data collected" answers apply instead.

## Google Play - App content
| Form | Answer |
|---|---|
| Privacy policy | The URL of the published privacy policy page (see checklist) |
| Ads | **No**, the app does not contain ads |
| App access | All functionality is available without special access |
| Content rating (IARC) | Category **Game**. Violence: **cartoon / fantasy violence** (insects are swatted, stomped, sprayed; no blood, no humans hurt). No sexual content, language, drugs, gambling, user interaction or sharing of location. Expected result: ESRB E or E10+, PEGI 7 |
| Target audience | **13 and over** (avoids the Families policy) |
| News app | No |
| Data safety | **Collects data: Yes. Shares data: No** (Sentry and Firebase are service providers). Data types: **App info and performance > Crash logs** and **Diagnostics**; **Device or other IDs** (Crashlytics' random installation ID). For each: collected, not shared, not processed ephemerally, **optional** (the player can turn it off), purpose **App functionality** (fixing crashes) - check Google's Firebase disclosure page: https://firebase.google.com/docs/android/play-data-disclosure . Encrypted in transit: **Yes**. Deletion requests: **Yes**, by email to the support address |
| Permissions | The Android build with Crashlytics adds INTERNET and ACCESS_NETWORK_STATE (only to send crash reports) |
| Government app / financial / health | No |

## Apple - App Store Connect
| Form | Answer |
|---|---|
| App Privacy | **"Yes, we collect data"** -> **Diagnostics: Crash Data** and **Other Diagnostic Data**. For both: **not linked** to the user's identity, **not used for tracking**, purpose **App Functionality**. Shows *Data Not Linked to You* |
| Encryption (export compliance) | Uses no non-exempt encryption -> `ITSAppUsesNonExemptEncryption = NO` (Godot writes it into the build's Info.plist) |
| Age rating (new questions, answer by 12 Jan 2027) | Shared Location: **No**. Dating and Relationships: **No** |
| Age rating | Cartoon or Fantasy Violence: **Frequent** -> 13+ (Infrequent would be 9+; bugs get swatted on most failures, so Frequent is the honest answer). Everything else: None / No. Not "Made for Kids" |
| Content rights | Contains no third-party content (all art, sound and code made for the game; Meshy-generated models used under your Meshy plan's terms) |

## Steam
- Content survey: **cartoon violence**, nothing else. Mark at least 4 screenshots "suitable for all ages".
- Steamworks / DRM: none.

## Microsoft Store / Epic
- IARC questionnaire: same answers as Google Play.

## EU trader status (Apple, Google, Epic)
- Free game, no money involved -> usually **non-trader**. If you sell the game or have VAT registration -> **trader** (your address/phone/email are verified and shown in the EU). Decide before you set a price.

## Sentry project settings (do once)
- Security & Privacy: turn on **Prevent Storing of IP Addresses** and **Data Scrubber**.
- Data retention: 90 days (the privacy policy says so).
