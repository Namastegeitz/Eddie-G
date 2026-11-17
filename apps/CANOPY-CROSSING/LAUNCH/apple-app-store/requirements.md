# **CANOPY CROSSING: Apple App Store requirements**

Researched 2026-11-17 from Apple's official pages; [UNVERIFIED] marks items to re-check.

**Method.** Apple's own pages were read directly: Upcoming Requirements, Developer News, the App Review Guidelines (last updated 2026-10-16), App Store Connect Help, the developer documentation, the HIG and the Submitting page. Godot 4.7 behaviour was checked against the 4.7 branch source code and docs on GitHub. Items marked **[UNVERIFIED]** come from memory or from secondary sources.

**Sites that could not be reached** (the research session's network blocked them): docs.godotengine.org, godotengine.org, developers.google.com (AdMob docs), docs.github.com (runner pricing) and meshy.ai.

---

## 0. Deadlines and recent changes

| Date | What | Effect on Canopy Crossing |
|---|---|---|
| **In force since 2026-04-28** | Uploads must be built with **Xcode 26+ and the iOS 26 SDK**. | GitHub `macos-26` runners carry Xcode 26.0.1–26.6. |
| **In force since 2026-09-09** | Apps must target **iOS 13+**. | Godot 4.7's default is iOS 15.0, so this is met. |
| **In force since 2026-11-16; all apps by 2027-01-12** | The age-rating questionnaire has two new descriptors: **Shared Location** and **Dating and Relationships**. You must answer them on every new submission. Dating sets the rating to 18+. | Answer "No" to both. |
| **In force since Sept 2026** | **Social-media questions** in the age-rating questionnaire are required for new apps and updates. They feed the new Time Allowances parental feature. | Answer "No". |
| **April 2027** | Uploads must use the **iOS/iPadOS 27 SDK (Xcode 27)** and **target iOS 15+**. | Plan to switch the CI image before this date. |
| **April 2027** | **iPhone Duo screenshots** become required. The screenshot spec page says this applies to apps built with the iOS 27.1 SDK or later. | Add a Duo screenshot set. |
| **April 2027 (via the iOS 27 SDK)** | Apps built with the iOS 27 SDK **must use the UIScene life cycle or they fail to launch**. Apple's tech note TN3187 covers this. | Godot 4.6+/4.7 already writes a `UIApplicationSceneManifest` and uses a SwiftUI app life cycle. Re-test every native plugin. |
| 2026-01-31 (passed) | All apps had to answer the new age-rating questionnaire (4+/9+/13+/16+/18+). | Required at your first submission. |
| 2025-02-17 (in force) | **EU DSA trader status** is mandatory, or the app is removed from EU storefronts. | Declare it before you submit. |
| 2024-05-01 (in force) | A **privacy manifest with required-reason APIs** is needed for uploads. | Godot generates `PrivacyInfo.xcprivacy`. |
| 2026-04-22 (passed) | The amended FTC COPPA Rule had to be complied with (Federal Register 2025-04-22). | Matters because the game appeals to kids. |
| US state age-assurance laws in force | Utah (new accounts from 2026-05-06), Texas SB 2420 (reinstated from 2026-06-04) and Louisiana (2026-07-01). | See Phase 2. |
| 2026-02-24 | Apple blocks 18+ apps for unconfirmed adults in Australia, Brazil and Singapore. **Loot boxes now mean an 18+ rating in Brazil.** | Do not add paid random items. |
| 2026-06-18 | Australia dropped 15+ (loot boxes now 16+). Vietnam has its own ratings, and **games need a licence to stay on the Vietnam store**. | Leave Vietnam out unless you are licensed. |
| Apple says "over time" (no date) | **Accessibility Nutrition Labels** are voluntary now and will become mandatory. | Optional for now. |
| Guideline changes, 2025-11 to 2026-10 | 2025-11-13: new 4.1(c) (no other developer's icon, brand or name); 5.1.2(i) (disclose sharing with third-party AI); 2.5.10 deleted (test or empty ads no longer a stated rejection reason). 2026-06-08: 4.3(a)/(b) spam rules clarified, plus kid/teen safety text in the intro. 2026-10-16: new 2.3.14 (creative assets) and 2.5.19 (hidden or dormant features mean removal). | See the pitfalls in Phase 6. |
| Commissions | China mainland: 25%, or 12% for Small Business (since 2026-03-15). Taiwan: 26% (since 2026-10-31). | Pricing input. |
| Other 2025–26 changes | Promo codes for IAPs ended 2026-03-26; offer codes now cover every IAP type. You can have 70 custom product pages, each with keywords. New creative assets, an Asset Library and a preview tool arrived 2026-10-05. Metadata can be localised in 50 languages (2026-03-31). From iOS 27.2 there is an alternative ATT prompt in the EU, mandatory in DE, FR, IT, PL and RO. | |
| Godot templates | `UIRequiresFullScreen` (still in Godot's Info.plist) is **deprecated since iOS/iPadOS 26.0**. | Test resizable iPad windows. |

Sources:
- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/news/
- https://developer.apple.com/app-store/submitting/
- https://developer.apple.com/iphone-duo/prepare/
- https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule

---

## Phase 1: Accounts and business

**1.1 Apple Account.** Turn on two-factor authentication and use your legal first and last name; aliases delay approval. No Mac needed.

**1.2 Enrol in the Apple Developer Program.** It costs **99 USD per membership year**, with local prices varying.
- **Individual:** your legal name appears as the seller. A street address is required; P.O. boxes are refused.
- **Organization:** needs a legal entity (DBAs and trade names are refused), a **D-U-N-S number**, a work email on the company domain, and a public, functional website.
- To sell as "Aethertek", enrol as an organization.
- No Mac needed. You can enrol on the web or in the Apple Developer app.
- Source: https://developer.apple.com/programs/enroll/

**1.3 Agreements, tax and banking.** All of these are in App Store Connect under Business.
- The Free Apps terms come with membership. **IAP requires the Account Holder to sign the Paid Apps Agreement.**
- Then add bank details and tax forms:
  - US developers: W-9.
  - Non-US developers: W-8BEN, W-8BEN-E or W-8ECI. Every developer must complete a US tax form.
  - Some countries need extra forms. For example, Australia needs an ABN with GST registration.
- When Apple publishes a new agreement version, you cannot create new apps or IAPs until you accept it. The latest DPLA updates were 2026-10-13 and 2026-10-29.
- Sources: https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/ and https://developer.apple.com/help/app-store-connect/manage-tax-information/provide-tax-information/

**1.4 App Store Small Business Program.** Commission drops to **15%** (standard is 30%) if proceeds were ≤1M USD in the prior calendar year; new developers qualify.
- You enrol after signing the Paid Apps Agreement, and must list any associated developer accounts.
- The new rate starts 15 days after the end of the fiscal month in which you are approved.
- Source: https://developer.apple.com/app-store/small-business-program/

**1.5 DSA trader status.** Go to Business > Agreements > Compliance > Digital Services Act. Declaring is mandatory even if you don't sell in the EU.
- A game with IAP and ads almost certainly makes you a "trader".
- Traders must publish an address, phone and email on the EU product page. Individuals can use a P.O. box, but must upload proof of it.
- Apple verifies the email and phone with 2FA and asks for a business/legal document.
- Without this, the app is removed from all 27 EU storefronts.
- Source: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/

**1.6 Register the bundle ID.** In Certificates, Identifiers & Profiles, create an explicit App ID `com.aethertek.canopycrossing`.
- In-App Purchase is part of explicit App IDs [UNVERIFIED wording]. Add Game Center only if you use it.
- The bundle ID cannot change after the first build is uploaded.

**1.7 Create the app record.** In App Store Connect: Apps > + > New App. Enter platform iOS, name, primary language, bundle ID, SKU and user access.
- The SKU allows letters, digits, `- . _`, cannot start with `- . _`, and is permanent.
- Source: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/

**1.8 App Store Connect API key (for CI).** Go to Users and Access > Integrations > App Store Connect API > Team Keys. You need the Admin role.
- The `.p8` private key can be **downloaded once only**.
- **Individual keys cannot use the provisioning endpoints**, so use a Team key for creating certificates and profiles.
- Source: https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api

**1.9 Pricing and availability.**
- Set the app to Free.
- IAP prices come from **900 price points, 0.29 to 10,000 USD**, across **175 storefronts and 43 currencies**.
- **Leave out China mainland** (games need an NPPA approval number/ISBN, and an ICP filing).
- **Leave out Vietnam** unless the game is licensed there.
- Korea gets an automatic regional rating; a GRAC rating number (RCN) is only needed for 19+-type content.
- Sources: https://developer.apple.com/app-store/pricing/ and https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/

---

## Phase 2: Legal and compliance

**2.1 Privacy policy (guideline 5.1.1(i)).**
- You need a URL in App Store Connect **and** a link inside the app.
- The policy must list:
  - all data collected and its uses;
  - every third party (AdMob/UMP), with confirmation that they give equal protection;
  - retention and deletion;
  - how to revoke consent or request deletion.
- The repo's `LAUNCH/shared/privacy-policy.md` still has `[FILL IN]` placeholders, and its ads section must be completed once AdMob is live.
- Source: https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage

**2.2 App Privacy details (the "nutrition label").** Required for every submission.
- "Collect" means data sent off the device. **Analytics that stay on the device are not "collected".**
- With AdMob you cannot claim "Data Not Collected". The likely declarations, per Google's own disclosure guidance [UNVERIFIED, Google docs unreachable], are:
  - Device ID
  - Advertising Data
  - Product Interaction
  - Coarse Location (from IP)
  - Crash, Performance and Other Diagnostic data
- Mark these "Used to Track You" only if you request ATT and track.
- Source: https://developer.apple.com/app-store/app-privacy-details/

**2.3 App Tracking Transparency (ATT).**
- You need ATT permission before using the IDFA or "tracking" (linking data with other companies' data for ads or measurement).
- The purpose string `NSUserTrackingUsageDescription` is required if you ask.
- **You may not gate features behind ATT or reward users for allowing it.**
- **A common rejection:** the label says you track but no ATT prompt ever appears.
- From iOS 27.2 there is an EU "alternative" ATT prompt (mandatory in DE, FR, IT, PL, RO), with a Markdown usage-description key and an optional "Additional Information" button. EU users can be re-prompted after one year.
- **Option:** ship without ATT (no IDFA, so contextual/non-personalised ads). This lowers revenue but is simpler and safer for a kid-appealing game.
- Source: https://developer.apple.com/app-store/user-privacy-and-data-use/

**2.4 Privacy manifest and required-reason APIs** (`PrivacyInfo.xcprivacy`, required since 2024-05-01).
- Godot 4.7 generates one with these defaults:
  - FileTimestamp `DDA9.1` + `C617.1`
  - SystemBootTime `35F9.1`
  - DiskSpace `E174.1` + `85F4.1`
  - UserDefaults none
- Also set `privacy/tracking_enabled` / `privacy/tracking_domains` if you track.
- The Google Mobile Ads SDK and its UMP dependency must bring their own manifests; use current SDK versions.
- Apple's list of SDKs that must ship a manifest and signature includes several Google dependency libraries (e.g. GoogleUtilities, nanopb, FBLPromises), but not GoogleMobileAds itself.
- Sources: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files, https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api and https://developer.apple.com/support/third-party-SDK-requirements/

**2.5 Export compliance.**
- Godot 4.7's Info.plist template already sets `ITSAppUsesNonExemptEncryption = false`. That is correct only if the app (including linked libraries) uses no encryption or only exempt encryption, such as OS HTTPS.
- If you turn on Godot's PCK/script encryption (`encrypt_pck`, currently `false`), re-assess.
- Exempt users may owe a yearly US self-classification report.
- If documentation is needed, Apple reviews it in about **2 business days**. France has extra import controls.
- Sources: https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations and https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/

**2.6 Age rating** (App Information > Age Ratings; required; applies to all platforms).

The questionnaire sections are:
- In-App Controls (Parental Controls, Age Assurance)
- Capabilities (Unrestricted Web, UGC, Social Media, Messaging/Chat, Advertising)
- Mature Themes
- Medical/Wellness
- Sexuality/Nudity
- Violence
- Chance-Based (Gambling, Simulated Gambling, Contests, **Loot Boxes**)
- New since 2026-11-16: Shared Location, Dating and Relationships

Possible ratings are 4+, 9+, 13+, 16+, 18+ and Unrated; an Unrated app cannot be on the App Store.

Rules that matter for this game:

| Your answer | Global rating | Regional effects |
|---|---|---|
| Advertising | 4+ | **Brazil A12**; Korea All; Vietnam 00+ |
| Cartoon/fantasy violence, infrequent | 9+ | Brazil A6, Vietnam 12+ |
| Cartoon/fantasy violence, **frequent** | **13+** | Brazil A12 |
| Horror/fear, infrequent | 9+ | Brazil A10 |
| Loot boxes | 9+ | **Australia 16+, Brazil 18+**, Vietnam 12+ |
| Frequent contests | 13+ | |

- **Realistic result for Canopy Crossing: 9+ globally, A12 in Brazil.** It becomes 13+ if being "snapped/squashed" (the core fail state) counts as frequent; answer honestly.
- Making deaths non-violent (a puff or bonk) is the design lever to keep it lower.
- Answer **No** to the loot-box question. "Daily deals" pick items at random, but the contents are shown before purchase, so they are not loot boxes.
- "Made for Kids" is only available at 4+/9+ and **cannot be undone after approval**. You may override the rating upward.
- Sources: https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/ and https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/

**2.7 Kids category: recommendation is do NOT select it.**
- Kids-category apps (1.3, 5.1.4) need parental gates for purchases and links. They cannot use third-party analytics or ads, except contextual ads from networks with documented kids policies and human review of ad creatives.
- But the game still appeals to kids, so:
  - Never use "for kids" or "for children" in the name, subtitle, icon, screenshots or description (2.3.8 and 5.1.4).
  - All metadata must be suitable for 4+ (2.3.8).
  - Treat it as a **mixed-audience** app: use a neutral age screen or the Declared Age Range API (iOS 26+). For under-13 users, use AdMob's child-directed treatment, a G content ceiling, non-personalised ads and no ATT prompt. This is how COPPA compliance is usually done [UNVERIFIED, legal advice; consult counsel].
- The amended COPPA Rule (in force 2025-06-23, compliance by 2026-04-22) applies.
- Source: https://developer.apple.com/app-store/review/guidelines/#kids-category

**2.8 US state and other age-assurance laws** (Texas SB 2420, Utah, Louisiana; Brazil, Australia, Singapore).
- Apple offers these tools:
  - Declared Age Range API
  - Significant Change API (PermissionKit)
  - an age-rating property in StoreKit
  - App Store Server Notifications for consent revocation
- Godot has no built-in support, so this needs a native Swift plugin [UNVERIFIED that any Godot plugin exists].
- An offline app cannot receive server notifications. Get legal advice.
- Sources: https://developer.apple.com/news/?id=f5zj08ey and the 2026-06-03 Texas item on https://developer.apple.com/news/

**2.9 IP, AI-generated assets and licences.**
- **Apple has no rule requiring disclosure of AI-generated game art.** The guidelines mention AI only in 1.2 (AI content-creation apps, nonconsensual intimate imagery) and 5.1.2(i) (sharing personal data with third-party AI).
- What applies instead:
  - 5.2.1: you must own or license all IP.
  - 2.3.9: you need rights to everything in the icon, screenshots and previews.
  - The **Content Rights** answer in App Store Connect.
- Meshy terms [secondary sources; meshy.ai unreachable]:
  - Free-plan outputs are **CC BY 4.0**, so commercial use is allowed but credit is required, e.g. "Model created with Meshy – CC BY 4.0".
  - Paid-plan outputs are private and owned, with no attribution required.
  - Rights follow the plan you were on when you generated the model.
- Include Godot's MIT licence text, plus credits for fonts and other assets.
- Copycat and spam risk in a crowded lane-crossing genre:
  - 4.1(a): don't just copy a popular app.
  - 4.1(c): no other developer's brand or name in your name or icon.
  - 4.3(b): not "indistinguishable" from what's widely available.
  - Keep competitor names (Crossy Road, Frogger) out of keywords (2.3.7).
- Sources: https://developer.apple.com/app-store/review/guidelines/#intellectual-property, https://help.meshy.ai/en/articles/9992001-can-i-use-my-generated-assets-for-commercial-projects and https://raw.githubusercontent.com/godotengine/godot-docs/4.7/about/complying_with_licenses.rst

**2.10 Ads compliance (guideline 2.5.18).**
- Ads must be suitable for the app's age rating.
- Users must be able to see the targeting information.
- **No ads based on kids' data.**
- Interstitials must be clearly marked, not deceptive, and have **visible, large close/skip buttons**.
- **You must offer a way to report inappropriate or age-inappropriate ads.** Add an in-app "Report an ad" link or email.
- Ads may only appear in the main app binary.
- Rewarded ads that give in-game rewards are explicitly allowed (3.2.2(x)). Apps "designed predominantly for the display of ads" are not (3.2.2(iii)).
- Google requires a certified consent tool (UMP) for the EEA, UK and Switzerland [UNVERIFIED, Google policy].

---

## Phase 3: Technical and build requirements

**3.1 Toolchain minimums.**
- Today: build with Xcode 26.x and the iOS 26 SDK; target iOS ≥13.
- From April 2027: Xcode 27 / iOS 27 SDK and iOS ≥15.
- App Store Connect accepts iOS builds **built with Xcode 26+** and **uploaded with Xcode 14+, Transporter or altool**.
- Size limits: 4 GB uncompressed app; 500 MB main executable (iOS 9+ targets).
- Sources: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/ and https://developer.apple.com/help/app-store-connect/reference/app-uploads/maximum-build-file-sizes/

**3.2 Godot export reality** (checked in the Godot 4.7 source).
- Godot docs say "export for iOS from a computer running macOS with Xcode installed."
- **On Linux**, Godot 4.7 writes the **Xcode project only** and warns ".ipa can only be built on macOS". The `.ipa` and `.xcarchive` are built by `xcodebuild` on macOS.
- **Export-plugin hooks (`end_generate_apple_embedded_project`) and dylib signing run only on a macOS host.**
- **Recommendation:** run the Godot export itself headless on the macOS CI runner, rather than exporting on Linux and copying the project over.
- Sources: https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/export/exporting_for_ios.rst and https://raw.githubusercontent.com/godotengine/godot/4.7/editor/export/editor_export_platform_apple_embedded.cpp

**3.3 Building, signing and uploading without owning a Mac.**

| Option | Notes |
|---|---|
| **GitHub Actions macOS runners** | `macos-26` / `macos-latest` (arm64) carries Xcode 26.0.1–26.6 (default 26.6) and iOS SDKs 26.0–26.5. **`xcode-27` / `xcode-27-xlarge` (public preview)** carries Xcode 27.0, 27.1 (default) and 27.2. `macos-15` is also available. macOS 14 images were retired 2026-11-02. Pricing per minute: [UNVERIFIED, docs.github.com blocked]. Source: https://github.com/actions/runner-images |
| **Xcode Cloud** | 25 compute hours per month are included with membership. Workflows are first configured from Xcode, so you need a Mac at least once. Source: https://developer.apple.com/xcode-cloud/ |
| Rented cloud Mac (MacinCloud, AWS EC2 Mac, Scaleway, etc.) | [UNVERIFIED pricing/terms]. Useful for Simulator screenshots, Icon Composer and Instruments. |
| **Upload paths** | Xcode; `xcrun altool --upload-app` (macOS); Transporter (macOS app); **App Store Connect API `POST /v1/buildUploads` (API 4.1), which works from any OS**. |

Pipeline on a macOS runner:
1. Install the Godot 4.7.2 macOS editor and matching export templates.
2. Import the **Apple Distribution** `.p12` into a temporary keychain.
3. Install the **App Store** provisioning profile.
4. Set `GODOT_IOS_PROVISIONING_PROFILE_UUID_RELEASE`.
5. Run `godot --headless --export-release "iOS" out.ipa` with `application/export_project_only=false`. Alternatively export the project only, then run `xcodebuild archive` and `xcodebuild -exportArchive` with method app-store-connect yourself.
6. Upload with altool using API-key auth, or fastlane `upload_to_testflight` with `app_store_connect_api_key`, or the Build Uploads API.

Certificates without a Mac:
- Generate the CSR with `openssl` on Linux, upload it, download the `.cer`, and build the `.p12` with openssl [standard practice; not an Apple-documented flow].
- Or use the ASC API provisioning endpoints (Team key), or fastlane `match`.
- fastlane docs were not fetched [UNVERIFIED].

**What still needs a Mac** (cloud Mac counts):
- `xcodebuild`, code signing, Simulator, Instruments and device debugging
- Icon Composer
- Transporter
- the first Xcode Cloud setup

**What does not:** App Store Connect web tasks, TestFlight testing on a real iPhone or iPad, and API uploads.

**3.4 Required Info.plist and capability items.**
- Godot 4.7's template sets:
  - `ITSAppUsesNonExemptEncryption=false`
  - `UIRequiresFullScreen=true` (deprecated in iPadOS 26: the app is scaled in a compatibility mode rather than resized)
  - a single-scene `UIApplicationSceneManifest` (ready for the iOS 27 UIScene requirement)
  - `UILaunchStoryboardName`
  - `CADisableMinimumFrameDurationOnPhone=true`
  - `UIRequiredDeviceCapabilities`: arm64, plus **`iphone-ipad-minimum-performance-a12` only if you use the Mobile or Forward+ renderer**. GL Compatibility keeps the device range wide.
  - Camera, photo and microphone usage-description keys, written even when empty [check: remove them if unused].
- AdMob additionally needs `GADApplicationIdentifier`, `SKAdNetworkItems`, and `NSUserTrackingUsageDescription` if you use ATT [UNVERIFIED from Google docs]. Add these through the plugin's `.gdip` `[plist]` section or `application/additional_plist_content`.
- Sources: https://raw.githubusercontent.com/godotengine/godot/4.7/misc/dist/apple_embedded_xcode/godot_apple_embedded/godot_apple_embedded-Info.plist and https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen

**3.5 StoreKit, IAP and season pass design.**

Product types are consumable, non-consumable, auto-renewable subscription and non-renewing subscription.
- **A restore mechanism is mandatory** for restorable items: Remove Ads, packs, passes (3.1.1).
- **Purchased currency (Amber) must never expire** (3.1.1). Consumables are not restored by Apple, so a lost local save means lost currency. Consider iCloud key-value storage.
- **Season pass:** do **not** reuse one product ID per season. A non-consumable is owned forever, and product IDs **can never be reused**, even after deletion. Use one non-consumable per season, e.g. `…expedition_pass.s2027_1`, or a non-renewing subscription.
- Avoid an auto-renewing pass unless you accept 3.1.2: at least 7 days per period, ongoing value, works on all devices, clear terms shown before purchase, and Terms of Use and privacy links required.
- Use **StoreKit 2**. Apple's 2026-09-16 news tells developers to "make sure your apps use StoreKit 2".
- IAP metadata limits:
  - Reference name ≤64 characters
  - Product ID ≤100 characters, from `A-Z a-z 0-9 - . _`
  - **Display name 2–30 characters; description ≤45 characters**
  - Review screenshot required
  - Optional 1024×1024 promotional image (JPG/PNG, 72 dpi, RGB, flattened, no rounded corners)
- Sources: https://developer.apple.com/in-app-purchase/ and https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/

**3.6 iPad and iPhone Duo layout.**
- Portrait-only with `canvas_items` + `expand` stretch is a good base. `project.godot` already has this.
- iPadOS 26 windowing: the deprecated key gives a scaled compatibility mode. Test in Stage Manager and Windowed Apps modes.
- On iPhone Duo, apps built with the iOS 26 SDK are centred with empty space around them. Apps built with the iOS 27 SDK resize dynamically. Apple warns that "fixed orientations … can break layouts".
- How Godot 4.7 behaves on Duo is unknown [UNVERIFIED]. Test in Xcode 27.1's iPhone Duo simulator before the April 2027 cutover.
- Source: https://developer.apple.com/iphone-duo/prepare/

**3.7 Deprecated renderer API.**
- The GL Compatibility renderer uses OpenGL (ES) on iOS. Apple deprecated OpenGL ES years ago; no removal date was found [UNVERIFIED].
- Guideline 2.5.1 asks you to phase out deprecated technologies. Keep the Mobile (Metal) renderer as a fallback.
- Switching renderer later adds the A12 device requirement, which drops older devices [UNVERIFIED: whether that is allowed in an update].

---

## Phase 4: Store listing assets

**4.1 Text fields** (sources: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/ and https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)

| Field | Limit and rules |
|---|---|
| Name | 2–30 characters. Unique per localisation. Editable until submitted, then only with a new version. |
| Subtitle | 30 characters. No other apps' names, no unverifiable claims, no prices. |
| Keywords | **100 bytes** (multibyte scripts use more). Each keyword >2 characters, comma-separated. Don't repeat the app or company name. No other apps' or companies' names. |
| Promotional text | 170 characters. Editable without review. |
| Description | 4000 characters, plain text, no HTML. Must state which featured items need IAP (2.3.2). |
| What's New | 4000 characters. **Not shown for version 1.0**, required afterwards. Must describe significant changes (2.3.12). |
| Support URL | Required. Must lead to real contact info. |
| Marketing URL | Optional. |
| Privacy Policy URL | Required. |
| Copyright | Required, e.g. "2026 Aethertek". |
| Review notes | ≤4000 bytes. Phone number in + international format. |
| Category | Games, plus up to 2 subcategories (e.g. Arcade, Casual). Secondary category optional. |
| Localisations | Up to 50 languages. |

**4.2 Asset table** (sources: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/, https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/ and https://developer.apple.com/design/human-interface-guidelines/app-icons)

| Asset | Exact spec |
|---|---|
| **App icon** | **1024×1024 px** square. Unmasked; the system rounds the corners. Provide a layered Icon Composer file (recommended; needs a Mac) or a bitmap PNG, which the system auto-segments for Liquid Glass. Appearances: default, dark, clear, tinted (Godot 4.7 has `icons/app_store_1024x1024` plus `_dark` and `_tinted`; no `.icon` option for iOS). Colour spaces: sRGB, Gray Gamma 2.2, Display P3. **No alpha in the App Store icon** (validation error ITMS-90717) [UNVERIFIED on the current page]. The icon comes from the build's asset catalog, not an upload. |
| **iPhone required set** | The page says the required set is "**iPhone with Dynamic Island (medium display)**". The same page also lists 6.9"→6.5" fallback rules. To be safe, upload **6.9" and 6.3"**, plus **6.5" if you skip 6.9"**. |
| iPhone 6.9" (Air, 18/17/16 Pro Max, 16/15 Plus, 15/14 Pro Max) | **1320×2868, 1290×2796 or 1260×2736** portrait; swap for landscape. |
| iPhone 6.5" (14 Plus … XR) | **1284×2778 or 1242×2688**. Required if no 6.9" set. |
| iPhone 6.3" (18 Pro, 17, 17 Pro, 16, 16 Pro, 15, 15 Pro, 14 Pro) | **1206×2622 or 1179×2556**. |
| **iPhone Duo** (from April 2027) | Outer display **1398×2034**; inner display **2007×2853** (landscape variants swapped). |
| **iPad 13"** (required if iPad is supported) | **2064×2752 or 2048×2732** portrait. |
| Screenshot rules | 1–10 per device size per localisation. .jpeg/.jpg/.png. **No alpha.** Must show the app in use (2.3.3). Suitable for 4+ (2.3.8). **No Android or other-platform imagery** (2.3.10): don't reuse Android captures with Android status bars. No prices in screenshots or previews (2.3.7). |
| **App preview video** (optional) | Up to 3 per device size per language. **15–30 s**, **≤500 MB**. H.264 (.mov/.m4v/.mp4) at 10–12 Mbps, progressive, High Profile Level 4.0, ≤30 fps; or ProRes 422 HQ (.mov). Audio: stereo AAC 256 kbps at 44.1/48 kHz, all tracks enabled. **iPhone (all modern models including Duo): 886×1920 portrait. iPad: 1200×1600 portrait.** Poster frame defaults to 5 s. Processing takes up to 24 h. Previews play before screenshots. **Only screen captures of the app** (2.3.4). `docs/gameplay.mp4` must be re-encoded to these specs. |
| Creative assets (new, optional) | Product page header 21:9 at **3840×1646** (safe area 1646×661). Search result 3:2, 1920×1280 to 3840×2560. Universal asset 16:9 at 5244×2950, PNG. Video 5–30 s at 30/60 fps. No alpha. Subject to 2.3.14. Source: https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications |
| IAP promotional image | 1024×1024 JPG/PNG. |

**4.3 Accessibility Nutrition Labels (optional now).** Possible labels: VoiceOver, Voice Control, Larger Text, Dark Interface, Differentiate Without Color, Sufficient Contrast, Reduced Motion, Captions, Audio Descriptions.
- Only claim a feature if **all common tasks** can be completed with it. Labels show on iOS 26+.
- Source: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/

---

## Phase 5: Testing

**5.1 TestFlight.**
- Up to **100 internal testers** (App Store Connect users, no review) and **10,000 external testers** per app (by email or public link).
- The first external build needs **TestFlight App Review**. You can submit up to **6 builds per 24 h**. Builds expire after **90 days**.
- You must create an internal group before an external one.
- IAPs in TestFlight use the sandbox and are free.
- No Mac is needed to test; install the TestFlight app on the iPhone or iPad.
- Sources: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/ and https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/

**5.2 Test matrix.**
- Devices: a small iPhone, a 6.9" iPhone and an iPad 13". The app supports iOS 15+, so iPhone 6s-class devices and up.
- iPad windowing.
- IPv6-only networks (2.5.5). The game must survive ads failing to load or being offline.
- IAP cases: buy, restore, interrupted purchase, Ask to Buy (deferred), refund.
- Remove Ads must actually remove the promised ads.
- ATT allow and deny paths.
- UMP consent with the EEA debug geography.
- Real (non-test) AdMob units in the release build.
- The Apple-silicon-Mac and Vision Pro listings, which are on by default (see Phase 8); test them or opt out.
- iPhone Duo once you build with the iOS 27 SDK.

---

## Phase 6: Submission and review

**6.1 Before you press Submit:**
- Paid Apps Agreement, tax and bank done.
- DSA trader status done.
- App Information complete: rating, category, content rights, privacy URL.
- App Privacy answers complete.
- Version page complete: screenshots, text, support URL, copyright, build.
- Pricing and availability set.
- Export compliance answered.
- App Review contact details and notes. No demo account is needed (no login).
- **The first IAP of each type** (consumable, non-consumable) must be added to the **same submission as an app version**. Each IAP needs its metadata and review screenshot. Up to 200 items per submission.
- Source: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/

**6.2 Review notes to include:**
- How to reach the store.
- What each IAP unlocks; that Amber never expires; how restore works.
- Season pass mechanics.
- Rewarded vs between-run ads, and what Remove Ads covers ("reward videos stay").
- ATT/UMP behaviour.
- That there are no loot boxes.

**6.3 Review times:** at least **50% within 24 h and 90% within 48 h**. Notifications come by email and in the App Review section of App Store Connect. You can also submit items without a new version (since 2025-10-29).
- Source: https://developer.apple.com/distribute/app-review/

**6.4 Rejection risks specific to this game:**
- **2.1:** crashes; IAPs not found or not working in sandbox (`billing/backend="mock"` and `ads/backend="mock"` must be real); placeholder content.
- **3.1.1:** no restore button; purchased currency that expires; paid randomised items without odds shown before purchase.
- **3.1.2:** if you make the pass a subscription without disclosures, Terms of Use and privacy links.
- **2.3.x:** misleading metadata; "for kids" wording; prices or Android imagery in screenshots; competitor names in keywords; "What's New" too vague.
- **2.5.18:** ads unsuitable for the rating; no ad-report mechanism; small close buttons.
- **5.1.1 / 5.1.2:** no in-app privacy link; the label says tracking but there is no ATT prompt; ATT incentivised.
- **5.1.4 / 1.3:** reviewer judges the app "primarily for kids" while it carries third-party ads.
- **4.1 / 4.3:** seen as a lane-crossing clone.
- **5.2.1:** asset rights (Meshy attribution).
- **2.5.19:** hidden or remotely enabled features. If you use content files or remote config for live ops, describe them.
- **5.6.1:** custom review prompts are not allowed; use the system review API.

---

## Phase 7: Launch and after

- **Release options:** manual, automatic, or automatic no earlier than a date. **Phased release over 7 days** (updates only). You can reset the rating summary with an update.
- **After launch:**
  - Respond to reviews (5.6.1).
  - Keep the DPLA and Paid Apps Agreement current, or you cannot create apps or IAPs.
  - Renew membership every year.
  - Use App Store Connect Analytics (100+ new metrics since 2026-03-25).
  - Optional extras: In-App Events, up to 70 custom product pages (with keywords), product page optimisation tests, offer codes (all IAP types), featuring nominations.
  - Games appear automatically in Apple's Games app.
- **Recurring obligations:**
  - Answer the new age-rating descriptors (deadline **2027-01-12**).
  - Rebuild with Xcode 27 / iOS 27 SDK and add iPhone Duo screenshots **by April 2027**.
  - Update App Privacy when analytics start leaving the device. "Product Interaction" etc. become collected; the privacy policy says so in brackets.
- Sources: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/ and https://developer.apple.com/news/

---

## Phase 8: What the Mac App Store would add

**Option A: iPhone/iPad app on Apple-silicon Macs.**
- **This is on by default.** Mac users on macOS 11+ get your iOS app, with no port and the same metadata.
- Opt out, or "Verify Compatibility", in Pricing and Availability. Apple Vision Pro availability is also automatic by default.
- How AdMob and ATT behave there is [UNVERIFIED].
- Source: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon/

**Option B: native macOS build from Godot**, as a macOS platform on the same app record (universal purchase).
- Guideline 2.4.5 rules: App Sandbox required (Godot: `codesign/entitlements/app_sandbox/enabled`), Xcode-provided packaging (.pkg), no third-party installers, updates only through the Mac App Store, no licence keys or custom copy protection, one self-contained bundle.
- Godot settings: `export/distribution_type` = App Store; signing identity; installer identity "3rd Party Mac Developer Installer"; macOS provisioning profile; `application/app_category` (LSApplicationCategoryType).
- Official templates are **universal** (arm64 + x86_64). macOS 27 is the last release with Rosetta and is Apple-silicon only.
- Godot's macOS-only `application/liquid_glass_icon` option needs a macOS host with Xcode 26+.
- **Mac screenshots are required**: 16:10 at **1280×800, 1440×900, 2560×1600 or 2880×1800**. Mac previews: **1920×1080, landscape only**.
- Files must not carry the `com.apple.quarantine` attribute (enforced since 2025-02-18).
- Releasing a native macOS app **replaces** the iOS-on-Mac listing.
- Google Mobile Ads is iOS-only [UNVERIFIED], so a native Mac build needs different monetisation.
- Developer ID builds (e.g. for Steam) must be re-signed against the new G2 Sub-CA before **2027-02-01**. This does not affect the Mac App Store.
- Sources: https://developer.apple.com/app-store/review/guidelines/#hardware-compatibility and https://raw.githubusercontent.com/godotengine/godot/4.7/platform/macos/doc_classes/EditorExportPlatformMacOS.xml

---

## Phase 9: Godot 4.x-specific notes

- **Godot 4.7.2-stable** was released on 2026-08-18 (GitHub release page).
- iOS export defaults:
  - min iOS **15.0**
  - device family iPhone & iPad
  - arm64
  - export method App Store
  - generates PrivacyInfo.xcprivacy and a launch storyboard
  - Game Center and increased-memory entitlements default off; push notifications "Disabled"
- **UIScene:** PR #116395 ("Add UIScene lifecycle events") was merged into 4.7 and cherry-picked to 4.6.2. #119547 (URL events) was merged on 2026-05-18. The older approach (#107615) was closed as no longer relevant after the SwiftUI change. **Re-test native plugins that grab `keyWindow` or `rootViewController`.**
- **Known 4.7.x iOS issues:**
  - #122549: a link error (`_SDL_IsIPad`) appears only with dead stripping off, `LD_EXPORT_GLOBAL_SYMBOLS` or `ENABLE_TESTABILITY`. Default export settings link fine. Fixed by PR #123903 (milestone 4.8).
  - #124919: a Simulator-only crash in self-built engines compiled with Xcode 27's Swift 6.4. Official templates and device builds are unaffected.
  - Simulator supports only the Compatibility renderer.
- **Plugin system:** iOS plugins use `.gdip` + `.a`/`.xcframework` in `res://ios/plugins`, called through `Engine.get_singleton()`. The 4.7 docs page is flagged as outdated. GDExtension plugins are the modern route.
- **StoreKit plugins:**
  - The official `godot-ios-plugins` InAppStore is StoreKit 1 (deprecated API).
  - `hyochan/godot-iap` (StoreKit 2, Godot 4.3+) is archived and moved to the OpenIAP monorepo.
  - `migueldeicaza/GodotApplePlugins` covers StoreKit 2, Game Center and Sign in with Apple, but **requires iOS 17**.
  - Whether any of these work on 4.7 is [UNVERIFIED]. Test one in a spike before committing.
- **AdMob:** `poingstudios/godot-admob-ios` was **archived 2026-03-18**. Use the monorepo `poingstudios/godot-admob-plugin`, which lists Godot 4.5+, a v4.3.1 badge and built-in UMP; ATT is not mentioned.
  - The Google Mobile Ads SPM package declares a minimum of **iOS 13**.
  - You will likely need your own small ATT call (ATTrackingManager) plus the plist string.
- **Export environment variables:** `GODOT_IOS_PROVISIONING_PROFILE_UUID_DEBUG/RELEASE`, `GODOT_SCRIPT_ENCRYPTION_KEY`.

---

## Phase 10: Things to fix in the repo

These are tracked on the live checklist in `LAUNCH/README.md`.

---

## Not verified / could not fetch

- Google AdMob iOS requirements: GADApplicationIdentifier, SKAdNetwork list, UMP/certified-CMP policy, data-disclosure mapping.
- GitHub runner pricing; fastlane docs.
- Full Meshy terms of use.
- Godot docs site and blog (GitHub raw copies were used instead).
- Whether Godot 4.7 behaves correctly on iPhone Duo or in iPad windowing.
- Whether any Godot plugin supports the Declared Age Range API, the EU alternative ATT prompt, or StoreKit 2 on 4.7.
- The App Store icon no-alpha rule (ITMS-90717).
- Openssl CSR / .p12 flow on Linux.
- Whether adding UIRequiredDeviceCapabilities in an update is allowed.
- Cloud-Mac vendor terms.
- Legal conclusions on COPPA and the US state laws; get counsel.
- Apple's screenshot page contradicts itself: "required: Dynamic Island (medium)" versus the 6.9"→6.5" fallback notes.

---

## Key sources

- **Requirements and news:** https://developer.apple.com/news/upcoming-requirements/ · https://developer.apple.com/news/ · https://developer.apple.com/app-store/submitting/
- **Review:** https://developer.apple.com/app-store/review/guidelines/ · https://developer.apple.com/distribute/app-review/
- **Age ratings:** https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/ · https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/
- **Listing assets:** https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/ · https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/ · https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/ · https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/ · https://developer.apple.com/design/human-interface-guidelines/app-icons
- **Privacy:** https://developer.apple.com/app-store/app-privacy-details/ · https://developer.apple.com/app-store/user-privacy-and-data-use/ · https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- **Compliance:** https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/ · https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
- **Builds, TestFlight, IAP:** https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/ · https://developer.apple.com/documentation/appstoreconnectapi/post-v1-builduploads · https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/ · https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/
- **Business:** https://developer.apple.com/programs/enroll/ · https://developer.apple.com/app-store/small-business-program/
- **Devices:** https://developer.apple.com/iphone-duo/prepare/
- **Godot and CI:** https://github.com/actions/runner-images · https://raw.githubusercontent.com/godotengine/godot/4.7/editor/export/editor_export_platform_apple_embedded.cpp · https://raw.githubusercontent.com/godotengine/godot/4.7/platform/ios/doc_classes/EditorExportPlatformIOS.xml · https://github.com/godotengine/godot/pull/116395
- **Legal:** https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule
