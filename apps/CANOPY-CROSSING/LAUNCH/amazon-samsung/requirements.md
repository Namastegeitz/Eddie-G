# **CANOPY CROSSING: Amazon Appstore and Samsung Galaxy Store requirements**

Researched 2026-11-17 from official pages (some via search extracts, marked); re-check on the day.

Labels: **[UNVERIFIED]** = could not be confirmed from an official source. **[SECONDARY]** = only third-party sources say it. developer.amazon.com and developer.samsung.com were not directly reachable from the research session; facts from them come from search-engine extracts of those official pages and are cited by URL.

---

## Changes and deadlines (2025–2026) for these stores

| Topic | Status on 2026-11-17 | Source |
|---|---|---|
| **Amazon** | The Appstore on non-Amazon Android devices ended **Aug 20, 2025**, and Coins ended. On **Oct 8, 2026** Amazon launched **Alexa Tablets** (Android 16 with Google Play), and Amazon says to distribute to them **via Google Play**. The Appstore Billing Compatibility SDK has been unsupported since Sep 15, 2026. | see the Amazon section |
| **Samsung** | **80/20** revenue share since May 15, 2025 (85/15 on subscriptions). IAP SDK 4.x shut down Jul 31, 2026. Registering non-consumable items ended Jan 14, 2026. Vietnam restrictions from Sep 30 and Nov 11, 2026. | see the Samsung section |
| **Android developer verification** (affects Galaxy Store) | Since **Sep 30, 2026**, enforced in **Brazil, Indonesia, Singapore and Thailand** for installs from 7 stores, **including Google Play and Samsung Galaxy Store**, on certified devices running Android 7+. Goes **global in 2027**. Fire OS devices are not Google-certified, so it does not apply to Amazon's Fire devices. | https://developer.android.com/developer-verification ; https://developer.android.com/developer-verification/guides ; https://developer.android.com/developer-verification/guides/faq |

---

## Builds for each store (Godot 4.7.2)

- Make separate export presets with custom feature tags (`play`, `galaxy`, `amazon`) and branch on `OS.has_feature()`.
- Exclude the Play Billing plugin from the Amazon and Samsung builds; Samsung wants **one billing solution per APK**.
- Neither Amazon IAP nor Samsung IAP has a Godot plugin, so each needs a **custom Godot Android v2 plugin** wrapping that store's SDK.
- Use `gradle_build/export_format` = Export APK (or AAB where accepted) for these builds; Gradle build must be on for v2 plugins.

---

## Amazon Appstore (secondary)

**Reach**
- Since Aug 20, 2025 the Appstore runs only on **Fire tablets (Fire OS, up to API 30 / Fire OS 8) and Fire TV**.
- Amazon's new **Alexa Tablets** (launched Oct 8, 2026; Android 16 / API 36 with Google Play) are reached **through Google Play**, except Amazon Kids+ apps. Existing Fire tablets won't get Play.
- A single report says Fire tablet inventory has sold out **[SECONDARY]**.
- **The Appstore is now worth it only for the existing Fire tablet base; lowest priority.**

**Account**
- Free.
- One-time photo-ID identity verification (stated in Amazon docs for all developer accounts; seen on a Ring docs page) **[UNVERIFIED for Appstore]**.
- Tax interview (validation in 7–10 business days; 30% default US withholding for non-US developers, reducible by treaty) and bank details.

**Binary**
- APK or AAB. Amazon **strips your signature and re-signs** with an account-unique Amazon key (certificate hashes are shown on the upload page).
- Device targeting comes from the manifest (minSdk, features).
- Hybrid 32/64-bit builds are accepted; include armeabi-v7a for older Fire devices **[judgment]**.
- The App Submission API doesn't take AABs.

**Billing**
- **Amazon IAP (Appstore SDK) is mandatory for all digital goods, with no exceptions.**
- Play Billing doesn't work on Fire devices (no Google Mobile Services).
- The Billing Compatibility SDK has been unsupported since Sep 15, 2026.
- Item types are consumable, entitlement and subscription **[UNVERIFIED wording]**.
- No Godot plugin exists, so you need a custom one.

**Revenue**
- Historically 70/30.
- The **Small Business Accelerator** (under $1M in the prior year, or a new developer) gives 80/20 plus benefits (AWS credits); the current terms say "benefits up to/equivalent to 20%" **[confirm]**.

**Listing**
- Icons 114×114 and 512×512 PNG.
- **3–10 screenshots** (for example 1280×800), PNG or JPG.
- Optional promo image 1024×500, legible at 300×146.
- Content-rating questionnaire; Amazon may assign the rating itself, and content that doesn't match the rating is a rejection reason.

**Ads**
- AdMob reportedly runs on Fire with the bundled GMS client libraries, but no-fill problems are reported, so test it **[UNVERIFIED]**.

**Review**
- No SLA. Amazon says to contact them if still in review after 6 days; going live after approval takes a few hours.
- Android developer verification doesn't apply (Fire devices aren't certified).

**Sources:**
- https://developer.amazon.com/apps-and-games/blogs/2025/02/upcoming-changes-to-amazon-appstore-for-android-devices-and-coins-program
- https://developer.amazon.com/docs/device-specs/alexa-tablet-devices-faq.html
- https://developer.amazon.com/docs/app-submission/understanding-submission.html
- https://developer.amazon.com/docs/app-submission/upload-app-file.html
- https://developer.amazon.com/docs/app-submission/appstore-details.html
- https://developer.amazon.com/docs/app-submission/target-app.html
- https://developer.amazon.com/docs/app-submission/faq-submission.html
- https://developer.amazon.com/docs/policy-center/monetization.html
- https://developer.amazon.com/docs/in-app-purchasing/iap-faqs.html
- https://developer.amazon.com/docs/in-app-purchasing/iap-whats-new.html
- https://developer.amazon.com/docs/in-app-purchasing/migrate-google-billing-appstore-sdk-iap.html
- https://developer.amazon.com/docs/reports-promo/small-business-accelerator.html
- https://developer.amazon.com/docs/reports-promo/setup-tax.html
- https://developer.amazon.com/docs/fire-tablets/fire-os-8.html

---

## Samsung Galaxy Store (secondary)

**Account**
- Samsung account plus Seller Portal (https://seller.samsungapps.com); no sign-up or annual fee.
- **Commercial seller status** is needed to sell paid apps or IAP. Samsung's FAQ wording suggests it may be needed even to distribute free apps **[confirm]**.
  - Bank verification takes up to 10 business days.
  - Corporate sellers need a D-U-N-S number (up to 10 business days), or a DBA document if they can't get one.

**Revenue share**
- **80/20** for paid apps and IAP, **85/15** for subscriptions (since May 15, 2025), when sales go through Samsung's own payment system (Samsung Checkout / Samsung IAP).

**Billing**
- Samsung IAP is *recommended*; Samsung says it supports third-party payment systems.
- Use **one billing solution per APK**. Samsung IAP plus a unique package name may qualify for "instant review" **[detail UNVERIFIED]**.
- **Samsung IAP SDK 6.5.2** (May 18, 2026) is on Maven Central. SDK 4.x was terminated Jul 31, 2026.
- **Registering non-consumable item types ended Jan 14, 2026** (unified item types): your code decides what is re-purchasable, which affects map packs and Remove Ads.
- No Godot plugin exists, so you need a custom one.

**Binary**
- APK or AAB. **For AAB, Galaxy Store manages the signing key**, so register that certificate for developer verification (Play Console).
- The FAQ says target API ≥33 and at least one 64-bit binary (the page is about 1.5 years old) **[confirm current]**.
- Galaxy Store has been an **enforcing store for Android developer verification** in Brazil, Indonesia, Singapore and Thailand since Sep 30, 2026, and globally in 2027.

**Listing**
- Icon 512×512 PNG ≤1,024 KB; title ≤100 bytes; description ≤4,000 bytes (Content Publish API).
- Screenshot count and sizes **[UNVERIFIED]**; an old notice says 1080×1920 portrait.
- Age rating is mandatory. A Korean GRAC certificate is only needed for 18+/19+ games in Korea.

**Review**
- The FAQ is quoted as "2–5 business days"; developers often report weeks, and Samsung posts holiday-delay notices **[UNVERIFIED official wording]**.

**Region**
- **Exclude Vietnam.** From Sep 30, 2026 no new or updated apps can be distributed there, and the Games tab was removed on Nov 11, 2026.

**Sources:**
- https://developer.samsung.com/galaxy-store/faq.html
- https://developer.samsung.com/galaxy-store/distribution-guide.html
- https://developer.samsung.com/galaxy-store/prepare.html
- https://developer.samsung.com/sdp/news/en/2025/03/13/new-revenue-share-model-for-galaxy-store
- https://developer.samsung.com/iap/release-note.html
- https://developer.samsung.com/galaxy-store/recommendations-to-bring-your-game.html
- https://developer.samsung.com/galaxy-store/galaxy-store-developer-api/content-publish-api/reference.html
- https://developer.android.com/developer-verification/guides (Galaxy Store as participating store)

---

## Could not verify / open items
- Amazon's identity-verification specifics, IAP item-type wording and current Small Business Accelerator terms.
- Whether AdMob fills reliably on current Fire OS devices.
- Samsung's current target-API floor, screenshot rules and official review times.
- Whether Samsung commercial seller status is required for free apps without IAP.
