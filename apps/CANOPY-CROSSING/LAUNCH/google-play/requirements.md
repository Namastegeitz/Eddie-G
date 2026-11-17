# **CANOPY CROSSING: Google Play requirements**

Researched 2026-11-17 from official pages (developer.android.com and the Godot 4.7.2 source were read directly; Play Console Help, AdMob and policy pages via search extracts, marked); re-check on the day.
**[UNVERIFIED]** = not confirmed from an official source. **[SECONDARY]** = only third-party sources.

## 0. Changes and deadlines (2025-2026) that matter today

| Topic | Status on 2026-11-17 | Source |
|---|---|---|
| **Target API** | Since **Aug 31, 2026** new apps and updates must target **API 36 (Android 16)**; the extension to Nov 1, 2026 has expired. Existing apps need ≥35 to stay visible to new users on newer Android. API 37 likely Aug 2027 **[UNVERIFIED, not announced]**. | https://developer.android.com/google/play/requirements/target-sdk · https://support.google.com/googleplay/android-developer/answer/11926878 |
| **Play Billing Library** | New apps/updates: PBL 7 by Aug 31, 2026 (extension expired), PBL 8 by Aug 31, 2027, PBL 9 by Aug 31, 2028. **Ship PBL 8+ now; PBL 9 is the sensible choice** (latest 9.1.0, 2026-06-18). | https://developer.android.com/google/play/billing/deprecation-faq · https://developer.android.com/google/play/billing/release-notes |
| **16 KB page size** | Required for apps targeting API 35+ on 64-bit devices; **from Feb 1, 2027 Play blocks updates without 16 KB support**. | https://developer.android.com/guide/practices/page-sizes |
| **Android developer verification** | Since **Sep 30, 2026** enforced in Brazil, Indonesia, Singapore, Thailand for installs from 7 stores incl. Google Play and Galaxy Store, on certified Android 7+ devices; **global in 2027**. Apps created in Play Console are registered automatically. | https://developer.android.com/developer-verification · https://support.google.com/googleplay/android-developer/answer/16984799 |
| **Testing gate (new personal accounts)** | Accounts created after Nov 13, 2023 need a **closed test with ≥12 testers opted in continuously for 14 days** before applying for production. | https://support.google.com/googleplay/android-developer/answer/14151465 |
| **Trader status (EU DSA)** | Declaration in Play Console from Nov 2026, **deadline Feb 1, 2027** (blocked updates/removal otherwise). Trader contact details shown on the store. | https://support.google.com/googleplay/android-developer/answer/17594752 · …/18100766 |
| **Service fees** | New structure from Jun 30, 2026 (EEA/UK/US) and Sep 30, 2026 (AU/JP): about **20% on IAP for new installs** (15% in Games Level Up programs), 10% on subscriptions, plus a separate ~5% billing fee with Play Billing; other markets on legacy 15% first $1M / 30% above. **Extracts conflict: confirm before pricing.** | https://support.google.com/googleplay/android-developer/answer/112622 · …/16954621 |
| **US alternative billing** | Since Oct 29, 2025 US users can be offered alternative billing / external links; reporting and fees from Oct 1, 2026 (external links: Feb 1, 2027). | https://support.google.com/googleplay/android-developer/answer/15582165 |
| **US age laws** | Texas SB 2420 in effect: Play Age Signals for Texas accounts created after May 28, 2026; Utah May 6, 2027 and Louisiana Jul 1, 2027 **[SECONDARY]**. | https://support.google.com/googleplay/android-developer/answer/16569691 |
| **Policy updates** | Jul 15, 2026: unrated apps not allowed; User Data policy covers third-party AI. Oct 29, 2026: AI/agentic purchase guidance. Feb 2027: technical-quality memory thresholds **[SECONDARY detail]**. | https://support.google.com/googleplay/android-developer/answer/17134731 |
| **Battery vital** | Since Mar 1, 2026 excessive partial wake locks (>5% of sessions over 28 days) can exclude an app from discovery. | developer.android.com blog |
| **App signing** | New apps default to Google-generated hybrid keys (RSA-4096 + ML-DSA-65); key-upgrade prompts at least every 2 years. | https://support.google.com/googleplay/android-developer/answer/9842756 |
| **AI labels** | Per-asset self-declaration checkbox for AI-generated visuals in store listings / promo content. | https://support.google.com/googleplay/android-developer/answer/17262077 |

## Phase 1: Accounts and business

**1.1 Personal or organization account**

| | Personal | Organization |
|---|---|---|
| Fee | US$25 one-time (no prepaid cards) | US$25 |
| Identity | Government ID (must match the payments profile exactly) | **D-U-N-S** (free, up to ~30 days), business registration, representative's ID, verified phone, **website verified in Google Search Console** |
| Device check | Verify an Android device in the Play Console app (Android 10+, not rooted) | Not required |
| Testing gate | 12 testers x 14 days | Not required |
| Trader display | Phone required; **address shown publicly** | Business details shown |

Recommendation: if Aethertek is a registered business, an organization account skips the 12-tester gate and keeps a home address off the listing. Pitfalls: name mismatches between D-U-N-S, payments profile and ID; paying "D-U-N-S services" for the free number; Search Console URL not exactly matching.
Sources: https://support.google.com/googleplay/android-developer/answer/6112435 · …/13628312 · …/10841920 · …/14316361

**1.2 Payments profile** (needed before creating any in-app product): legal name and physical address (no PO box), bank account in the same country, tax info, possibly a test deposit. Sources: …/7161426 · …/7163598 · …/7161440

**1.3 Trader declaration (by Feb 1, 2027)**: Manage account > Account details > About you, then per app under App content. Earning from IAP or ads makes you a trader: public contact details, self-certification, **a terms-of-service link per app**. Declaring "non-trader" to avoid verification can get the account suspended.

**1.4 Developer verification**: creating the app registers `com.aethertek.canopycrossing`; check it on the developer verification page. If a Galaxy Store build is signed with a different key (Samsung-managed AAB key), register that key for the package too.

**1.5 AdMob (when leaving the sandbox)**: `app-ads.txt` at the root of the website listed in the Play contact details (required for new AdMob apps since Jan 2025; detection up to 24 h); app readiness review; **a Google-certified consent tool (UMP) for EEA/UK/Switzerland** (else Limited Ads). Sources: https://support.google.com/admob/answer/9363762 · https://developers.google.com/admob/android/privacy/gdpr

## Phase 2: Legal and compliance (Play Console > App content)

**2.1 Privacy policy (mandatory)**: a public, non-geofenced HTTPS page (no PDF, no login) naming the developer/app and covering collection, use and sharing **including by the AdMob and Billing SDKs**; link it in Play Console **and inside the game**. Sources: …/10144311 · …/9859455

**2.2 Data safety form (mandatory even if nothing is collected)**. Data kept on the device is out of scope; SDK data counts as yours. Likely answers once AdMob is live:

| Data type | From | Collected / Shared | Purposes |
|---|---|---|---|
| Approximate location (from IP) **[judgment call]** | Google Mobile Ads SDK | Yes / Yes | Advertising, Analytics, Fraud prevention |
| App interactions | GMA SDK | Yes / Yes | same |
| Diagnostics | GMA SDK | Yes / Yes | same |
| Device or other IDs (advertising ID, app set ID) | GMA SDK | Yes / Yes | same |
| Purchase history | Play Billing | "Not collected" defensible while purchase data only goes to Google **[UNVERIFIED]** | |
| Gameplay events, save file | on device | Not collected; update the form **before** uploading anything | |

Encrypted in transit: yes. No accounts, but answer the deletion questions. Pitfall: the form contradicting the SDKs or the privacy policy. Source: …/10787469 · https://developers.google.com/admob/android/privacy/play-data-disclosure

**2.3 Target audience and Families policy (highest risk for this game)**
- **13+ only**: the listing (icon, screenshots, text) must not primarily appeal to children; if Google judges the art kid-appealing it is rejected until you change it or add under-13 groups.
- **Mixed audience incl. under-13**: Families Self-Certified ad SDKs only (AdMob is), a **neutral age screen**, child-directed tagging with `max_ad_content_rating = G` for children/unknown age (`setAgeRestrictedTreatment`), no personalised ads to children, no `AD_ID` in child-only apps (API 33+), ads closeable after 5 s.
Sources: …/9867159 · …/9893335 · https://support.google.com/admob/answer/6223431

**2.4 Content rating (IARC)**: mandatory (unrated apps not allowed since Jul 2026); category Game; answer honestly about digital purchases ("In-Game Purchases"), ads and cartoon "violence"; retake after content changes. Source: …/9859655

**2.5 Ads declarations**: "Contains ads" = yes (incl. SDK ads; misdeclaring can suspend); **Advertising ID declaration** (GMA merges `AD_ID`). Better Ads rules: no surprise interstitial at level start; full-screen ads closeable within 15 s; interfering ads (incl. rewarded) after 5 s; rewarded only on explicit opt-in, reward disclosed, always delivered, in-app only; banners away from controls. Sources: …/9857753 · …/12271244 · https://support.google.com/admob/answer/7313578

**2.6 Billing policy**: digital goods must use Google Play Billing (except the US/EEA alternative programs).

| Product | Play type | Notes |
|---|---|---|
| Amber packs | One-time, consumable | Consume only after granting |
| Map/animal packs, Remove Ads | One-time, non-consumable | Restore on launch with `query_purchases`; say exactly what Remove Ads removes |
| Expedition Pass | Subscription **or** a one-time product with a **new ID each season** | Subscriptions need clear price/period/renewal/cancel terms |

Show the localized price from product details; never hard-code. Loot boxes would need odds disclosed. Product IDs: lowercase letters, digits, `_` and `.`; cannot be reused after deletion **[UNVERIFIED wording]**. Sources: …/10281818 · …/16430488

**2.7 Other declarations**: App access (no login), Financial features and Health apps ("none", mandatory for every app incl. test tracks), government apps, news. Sources: …/9859455 · …/13849271

**2.8 AI-generated assets (Meshy)**: Play's AI-Generated Content policy covers apps that generate content; a game shipping pre-made models is not a generative-AI app **[judgment]**. Store assets: per-asset AI label checkbox (decide per screenshot). **Meshy licence: free-plan outputs are CC BY 4.0 (credit required); paid-plan outputs are owned.** Don't reference other games in the listing. Sources: …/14094294 · …/17262077 · https://help.meshy.ai/en/articles/9992001-can-i-use-my-generated-assets-for-commercial-projects

**2.9 US age laws**: Play Age Signals API (beta) gives age ranges and parental approval in covered states; integrate if selling IAP to US minors **[legal advice recommended]**.

## Phase 3: Technical and build (Godot 4.7.2, GL Compatibility, portrait)

**3.1 Godot 4.7.2 toolchain** (verified in tag `4.7.2-stable`): compileSdk 36, **targetSdk 36**, minSdk 24, build-tools 36.1.0, NDK 29.0.14206865, AGP 8.6.1, Kotlin 2.1.21. Manifest template: `appCategory="game"`, `isGame="true"`, GLES 3 required, no permissions requested. Install `platform-tools`, `platforms;android-36`, `build-tools;36.1.0`, `ndk;29.0.14206865`, `cmdline-tools;latest`; **OpenJDK 17**. Source: https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/java/app/config.gradle

**3.2 Export preset**

| Option | Set to | Why |
|---|---|---|
| `gradle_build/use_gradle_build` | On | Required for AAB and v2 plugins (Billing, AdMob) |
| `gradle_build/export_format` | AAB for Play; APK for Amazon/Samsung | Play requires AAB for new apps |
| `gradle_build/target_sdk` | empty (=36) or 36 | Must be ≥36 now |
| `gradle_build/min_sdk` | empty (=24) or higher | Can't go below 24 |
| `gradle_build/compress_native_libraries` | Off | 16 KB zip alignment |
| `package/unique_name` | com.aethertek.canopycrossing | Can't change after the first upload |
| `package/app_category` | Game | Exempts portrait lock on large screens (Android 16) |
| `version/code` | +1 every upload | Duplicates rejected |
| Architectures | arm64-v8a (+ armeabi-v7a) | 64-bit rule |
| Keystore | env vars `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD` | keystore and key passwords must match |
| `permissions/*` | all off except what you use (VIBRATE for haptics) | |

**3.3 CI**: `godot --headless --path . --install-android-build-template --export-release "Android AAB" out.aab`; keystore as a base64 secret; upload with the Play Developer Publishing API via a service account to the internal track.

**3.4 Signing**: create an upload key valid past 22 Oct 2033 (25+ years recommended); Play App Signing is mandatory; **to use the same signing key on Galaxy Store, upload your own app signing key at first release**; a lost upload key can be reset, a lost self-managed signing key cannot. Source: https://developer.android.com/studio/publish/app-signing

**3.5 16 KB and size**: Godot ≥4.5 supports 16 KB pages; verify every release with `bundletool dump config ... | grep alignment` (PAGE_ALIGNMENT_16K), `zipalign -c -P 16 -v 4`, and a 16 KB emulator (`getconf PAGE_SIZE` = 16384). AAB base module ≤500 MB compressed. Source: https://developer.android.com/guide/practices/page-sizes

**3.6 Google Play Billing plugin**: GodotGooglePlayBilling **v3.3.0 (27 Jul 2026) bundles PBL 9.1.0** (Godot 4.2+, Gradle build). `BillingClient` is a class you instantiate; `start_connection()`, `query_product_details()` before buying, `purchase()`, `query_purchases()`, `acknowledge_purchase()`, `consume_purchase()`; signal `on_purchase_updated`. **Grant only on PURCHASED (not PENDING); acknowledge or consume within 3 days or Play refunds.** Re-query on start and resume. Source: https://github.com/godot-sdk-integrations/godot-google-play-billing

**3.7 AdMob plugin**: poingstudios/godot-admob-plugin v5.1.0 (13 Sep 2026, "tested through 4.7.2", Next-Gen SDK, UMP) or godot-sdk-integrations/godot-admob. Set the AdMob app id, test units in development, UMP before the first request, a privacy-options entry point. Source: https://github.com/poingstudios/godot-admob-plugin/releases

**3.8 Android 16 behaviour**: edge-to-edge can't be opted out; **predictive back**: test Godot's back handling on an Android 16 device **[UNVERIFIED]**; large screens ignore orientation locks except for apps with `appCategory=game` (Godot's default). Source: https://developer.android.com/about/versions/16/behavior-changes-16

**3.9 Quality bars (Android vitals)**: user-perceived crash rate 1.09% overall / 8% per device; ANR 0.47% / 8%.

**3.10 Per-store builds**: separate presets with feature tags (`play`, `galaxy`, `amazon`); keep Play Billing out of Amazon/Samsung builds (one billing system per APK); Amazon IAP and Samsung IAP need custom Godot Android plugins.

## Phase 4: Store listing assets

| Asset | Requirement | Notes |
|---|---|---|
| App name | ≤30 chars | No "#1", "best", "free", prices, emoji, ALL CAPS, keyword stuffing |
| Short description | ≤80 chars | |
| Full description | ≤4,000 chars | No other games' names, no repeated keywords |
| Release notes | ≤500 chars per language | |
| App icon | **512x512, 32-bit PNG, sRGB, ≤1,024 KB**, full square | Play masks the corners and adds the shadow |
| Feature graphic | **1024x500, JPEG or 24-bit PNG (no alpha), required** | Minimal text, key elements centred |
| Phone screenshots | JPEG/24-bit PNG, shortest side ≥320, longest ≤3,840, ≤2:1; **2-8 per device type** | **Games: ≥3 at 9:16, ≥1080x1920, real gameplay** for promotion eligibility |
| 7"/10" tablet screenshots | up to 8 each, 1,080-7,680 px | In-game UI only, no frames **[UNVERIFIED if mandatory]** |
| Preview video | one YouTube URL, public or unlisted, not age-restricted | |
| Category / tags | Game > Arcade | |
| Contact | **Support email required**; website (needed for app-ads.txt) | |

Sources: https://support.google.com/googleplay/android-developer/answer/9866151 · …/9859152 · https://developer.android.com/distribute/google-play/resources/icon-design-specifications

## Phase 5: Testing tracks

- **Internal testing**: up to 100 testers; add **license testers** (test cards: always approves, always declines, slow, chargeback).
- **Closed testing**: email lists or Google Groups; **≥12 testers opted in for 14 continuous days** (personal accounts), then **Apply for production** (questions on recruiting, engagement, feedback; review ≤7 days typically).
- **Open testing**: unlimited or capped.
- **Pre-launch report**: for an OpenGL game provide a game loop (auto-play intent) to get useful results.
Sources: …/9845334 · …/14151465 · https://developer.android.com/google/play/billing/test

## Phase 6: Submission and review

Order: create the app > every App content declaration > store listing > pricing and countries > products (needs the merchant account) > upload the AAB to a track > send for review. Review: hours to days, **up to 7 days or longer for new accounts**; use managed publishing to control the go-live moment.

Likely rejection reasons for this game: Data safety vs AdMob/privacy policy mismatch; privacy policy missing or not in the game; target audience vs kid-appealing art; ad placement (ad at level start, banners by controls, non-closeable); missing "Contains ads"/Advertising ID declaration; metadata (other games' names, ranking claims); unclear season-pass terms; crashes on Android 16 / edge-to-edge / 16 KB devices; rating answers not matching IAP/ads; unattributed CC-BY Meshy models.

## Phase 7: Launch and after

Choose countries; staged rollout is for updates. Watch Android vitals, reviews, the policy inbox and the policy deadlines page (https://support.google.com/googleplay/android-developer/table/12921780). Upcoming: trader declaration by **Feb 1, 2027**; Feb 2027 quality thresholds; 16 KB block on updates **Feb 1, 2027**; API 37 around Aug 31, 2027 **[UNVERIFIED]**; PBL 8 unsupported for updates after Aug 31, 2027; key-upgrade prompts; update Data safety before any analytics upload.

## Open items

Exact fee percentages; API 37 timing; tag limit and tablet-screenshot requirement; whether the AI-label checkbox applies to in-engine renders; Godot 4.7 predictive-back behaviour; removing `AD_ID` via an export plugin.
