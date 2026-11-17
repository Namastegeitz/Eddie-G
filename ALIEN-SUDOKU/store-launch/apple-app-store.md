# Apple: App Store (iPhone/iPad) and macOS distribution for Alien Sudoku

Researched November 17, 2026 against developer.apple.com (news, App Store Connect Help,
App Review Guidelines, upcoming requirements). Google, GitHub Docs, Codemagic, AWS, Electron
and Steam documentation sites could not be reached from this workspace; where a fact comes
from them it is marked "not re-verified".

---

## 1. Summary

**What it costs**
- Apple Developer Program: **99 USD per membership year** (local currency/sales tax may apply). Same
  membership covers iPhone/iPad App Store, TestFlight, Mac App Store and Developer ID signing +
  notarization for the Electron Mac build sold on Steam/GOG/itch.
- No other Apple fee for a free app with ads. Apple takes nothing from AdMob revenue.
- A Mac to build on: free if GitHub Actions starts working again (the repo is **public**, so
  standard GitHub-hosted macOS runners cost nothing per minute, per GitHub's long-standing
  policy, not re-verified), or Codemagic's free 500 macOS minutes/month (not re-verified), or
  rent a Mac (~1 USD/hour on MacinCloud pay-as-you-go per third-party reports).
- Optional: an LLC (state fees) if you want a company name as the seller; a P.O. box if you
  don't want your home address shown to EU users (DSA).

**How long it takes** (realistic)
- Enrollment: Apple quotes no time. Forum reports in 2026 range from 48 hours to 1-3 weeks for
  individuals. An organization adds up to ~7 business days for a new D-U-N-S number.
- Repo fixes listed below: 1-2 days of Claude work.
- First signed build to TestFlight: same day once a Mac/CI path works.
- TestFlight Beta App Review (external testers only): usually about a day.
- App Review: Apple says at least 50% of submissions are reviewed in under 24 hours and 90% in
  under 48 hours.

**The big risks for this game**
1. **No way to build yet.** There is no Mac, and GitHub Actions jobs don't start on the account.
   Nothing can be uploaded until one of the build paths in section 3.4 works. (Blocker.)
2. **Upload will be refused without a privacy manifest.** `@capacitor/preferences` uses
   `UserDefaults`, a "required reason" API, and there is no `PrivacyInfo.xcprivacy` in the app
   target. App Store Connect has rejected such uploads since May 1, 2024 (ITMS-91053).
3. **Two in-app items Apple requires are missing:** a link to the privacy policy inside the app
   (Guideline 5.1.1(i)) and a way to **report inappropriate ads** (Guideline 2.5.18, current text:
   "Apps that contain ads must also include the ability for users to report any inappropriate or
   age-inappropriate ads").
4. **Ads vs. age rating.** Ads must fit the age rating (2.5.18). The game will likely rate **9+**
   (infrequent mild horror from the "gnarly" monsters). Set AdMob's maximum ad content rating to
   G or PG. Never choose "Made for Kids": AdMob behavioral ads are not allowed in the Kids
   Category (1.3), and the choice can't be undone after approval.
5. **CI signing will fail as documented.** The repo docs say to create the App Store Connect API
   key with the **App Manager** role. Cloud signing through `xcodebuild -allowProvisioningUpdates`
   with an API key works only with an **Admin** key (Apple forum reports; API keys cannot be given
   the "cloud-managed distribution certificate" permission).
6. **Still on Google test ads,** only 1 of Google's SKAdNetwork ids, no `maxAdContentRating`.
7. **EU DSA trader status:** an ad-supported app is a listed "trader" factor. As a trader your
   address (or P.O. box), phone and email are shown to EU users. Without a declared status the
   app is not offered in the EU.
8. **Deadlines coming:** Jan 12, 2027 (new age-rating declarations: Shared Location, Dating and
   Relationships); Feb 1, 2027 (old Developer ID Sub-CA expires: Mac signing certs must come
   from G2); **April 2027** (uploads must use the iOS/iPadOS 27 SDK, and apps built with the
   iOS 27.1 SDK or later must include **iPhone Duo screenshots**).

---

## 2. Accounts & business setup

### 2.1 Individual or organization?

| | Individual | Organization (e.g., an LLC) |
|---|---|---|
| Fee | 99 USD/year | 99 USD/year |
| Seller name on the App Store | **Your personal legal name** (not "Eddie G" unless that is your legal name) | The legal entity name |
| Needs | Apple Account with two-factor auth, legal first/last name, age of majority, real address (P.O. boxes not accepted for enrollment) | Legal entity (DBAs/trade names not accepted), **D-U-N-S number** (free; up to 5 business days from D&B, then up to 2 business days before Apple sees it), public website on the company's domain, work email on that domain, authority to sign |
| EU DSA display | Address or P.O. box, phone, email you enter | D-U-N-S address shown automatically, plus phone and email |
| Sole proprietor | Must enroll as an individual | n/a |
| Switch later | "Contact us" to convert individual to organization (no timeline given) | n/a |

**Recommendation:** enroll as an **individual** now unless you want a company name as the seller
or already have an LLC. It is the fastest path. If privacy matters, plan a P.O. box and a
dedicated email/phone for the DSA display (section 2.4).

### 2.2 Enrollment steps (owner)
1. Apple Account: legal first and last name, two-factor authentication on, real address.
2. Enroll on the web (developer.apple.com/programs/enroll) or in the **Apple Developer app**
   (iPhone/iPad/Mac). The app enrolls as an auto-renewing subscription. Pay with **your own** card;
   paying with someone else's card triggers a government photo ID request and delays.
3. Accept the Apple Developer Program License Agreement. It was updated again on **Oct 13, 2026**;
   the Account Holder must accept updates when prompted or submissions get blocked.
4. Note your **Team ID** (Membership page), needed for CI (`APPLE_TEAM_ID`).

If the membership lapses, the app disappears from the App Store (installed copies keep working).
Free apps come back within 24 hours after renewal.

### 2.3 Agreements, tax and banking
- **Free apps need only the Apple Developer Program License Agreement** (free distribution is
  covered by it and is active by default).
- The **Paid Apps Agreement** is required only to sell apps or offer In-App Purchases. Banking and
  tax forms can only be added after signing it. **A free app whose income comes from AdMob does
  not need the Paid Apps Agreement, banking or Apple tax forms.** Ad income, tax forms (W-9) and
  payouts go through **Google AdMob**, not Apple.
- You would need the Paid Apps Agreement + US tax form + bank account only if you later sell the
  Mac version on the Mac App Store, add IAP (e.g., "remove ads"), or charge for the iOS app.
  In that case also enroll in the **App Store Small Business Program** (15% commission instead of
  30% under 1M USD/year proceeds).

### 2.4 EU Digital Services Act (DSA) trader status
- Asked the first time you submit a new app (App Store Connect > Business / App Compliance >
  Digital Services Act). Apps without a status are not available in the EU (since Feb 17, 2025).
- Trader = acting for your trade/business. Apple's listed factors include "Revenue from the app,
  such as ... a paid or **ad-sponsored** app". A hobbyist with no plan to commercialize is
  "unlikely" to be a trader. **With AdMob ads, assume trader.** Apple says to consult a lawyer if
  unsure.
- Trader verification: confirm email and phone with codes (manual check if the phone can't get
  codes), upload a document proving the name and address (business/legal records; for a P.O. box,
  a receipt or bill showing your link to it), and certify compliance with EU law.
- What EU users see on the product page: your **address or P.O. box, phone number and email**.
- If you declare "not a trader", EU users are told consumer-protection rights don't apply to you.
  Alternative: remove the EU from availability (not recommended; large market).

### 2.5 Other compliance checks before launch
- **US age-assurance laws.** Apple says Texas SB 2420 applies to new Texas Apple Accounts from
  **June 4, 2026**: parent consent for minors' downloads, and developers can use the Declared Age
  Range API, the Significant Change API and the `RESCIND_CONSENT` notification. Apple's FAQ says
  "In those regions, you must check the age of the people using your app" and to ask counsel.
  Utah/Louisiana are mentioned in Apple's 2025 news as following in 2026. **Could not verify**
  what a free, no-account game must do under each law; Capacitor has no official plugin for these
  APIs. Ask a lawyer or decide consciously; App Review does not currently test this.
- **Children/COPPA.** Cute cartoon aliens can make an app look child-directed under US FTC
  factors. The privacy policy says "not directed at children under 13". Keep marketing aimed at
  teens/adults, never use "for kids" wording (reserved for the Kids Category, 2.3.8/5.1.4), and
  consider a neutral age question that sends `tagForChildDirectedTreatment` for under-13 players
  if you expect many young players. (Legal judgment; not an App Review requirement.)
- **Content rights** (App Store Connect asks): the space photos "likely NASA/ESA" must be
  verified. NASA imagery is generally usable with credit; ESA images are often CC BY-SA 3.0 IGO
  (attribution + share-alike). Add credits in the About screen. OFL fonts are fine with notices.
  AI-assisted art is not restricted by Apple; you must own or license it (5.2.1).

---

## 3. Technical / build requirements, mapped to the game

### 3.1 Requirements in force now (Nov 2026) and what the repo has

| Requirement (source) | Game today (`game/ios`) | Status |
|---|---|---|
| Build with **Xcode 26+ and iOS/iPadOS 26 SDK** (since Apr 28, 2026) | No Mac. CI `runs-on: macos-latest` = macOS 26 arm64 image with **Xcode 26.6** default | OK once CI or a Mac works |
| **iOS 27 SDK (Xcode 27) from April 2027** | Not yet. GitHub has Xcode 27.0-27.2 only on the `xcode-27` preview image | Plan before April 2027 |
| Minimum deployment target iOS 13+ (since Sep 9, 2026) | `IPHONEOS_DEPLOYMENT_TARGET = 15.0` (Capacitor 8 and the AdMob plugin also need 15) | OK |
| UIScene life cycle (required when building with the iOS 27 SDK, TN3187) | `SceneDelegate.swift` + `UIApplicationSceneManifest` present | OK |
| Privacy manifest with approved reasons for "required reason" APIs (since May 1, 2024) | **No `PrivacyInfo.xcprivacy` in the App target.** `@capacitor/preferences` calls `UserDefaults.standard` and its README says to declare `NSPrivacyAccessedAPICategoryUserDefaults` with reason **`CA92.1`** in the app's manifest | **Needs change (upload blocker)** |
| Third-party SDK privacy manifests + signatures (Apple's list includes **Capacitor** and **Cordova**) | Capacitor 8.6 `Capacitor` and `CapacitorCordova` ship `PrivacyInfo.xcprivacy` (empty API list, no tracking). GoogleMobileAds/UMP are not on Apple's list; Google says GMA SDK ships a manifest since 11.2.0 (plugin pins GMA 13.11.0, UMP 3.1.x) | OK; check Xcode's privacy report and the upload email for ITMS-91061/91065 |
| App Tracking Transparency before tracking (5.1.2) | `NSUserTrackingUsageDescription` set; `ads.js` runs UMP consent, then `requestTrackingAuthorization()`, then `AdMob.initialize()` | OK. Test on a fresh install that the system prompt really appears |
| EU ATT alternative prompt (iOS/iPadOS 27.2+, Sep 16, 2026 news) | Optional; Germany, France, Italy, Poland, Romania get only the alternative prompt | No action; system handles it |
| SKAdNetwork ids (Google's full list) | Only `cstr6suwn9.skadnetwork` | **Needs change** |
| AdMob app id / ad units | Google **test** ids (`ca-app-pub-3940256099942544~1458002511` etc.) | **Needs change** before submitting |
| Ads appropriate for the age rating (2.5.18) | `AdMob.initialize()` without `maxAdContentRating` | **Needs change** (set `ParentalGuidance` or `General`; mirror in AdMob blocking controls) |
| Users can report inappropriate ads (2.5.18) | Nothing in Settings | **Needs change** |
| Privacy policy link inside the app (5.1.1(i)) | Settings has only "Ad privacy choices" (shown only where required) | **Needs change** |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` (only HTTPS through the OS) | OK |
| iPad (universal app, `TARGETED_DEVICE_FAMILY = 1,2`) | All four iPad orientations declared (needed for multitasking). iPadOS 26 ignores `UIRequiresFullScreen`; windows are freely resizable (TN3192) | OK in config; **test layout** at small iPad window sizes and 13" |
| iPhone landscape | Portrait + landscape left/right declared | Test landscape or drop it |
| Launch screen | `LaunchScreen.storyboard` with full-bleed `Splash` image | OK |
| App icon | Single 1024x1024 PNG, RGB, **no alpha** in `AppIcon.appiconset` | OK. Layered Icon Composer `.icon` (Liquid Glass, dark/clear/tinted) is optional; needs macOS Tahoe 26.4+ |
| `GADIsAdManagerApp = true` | Present (copied from the plugin README) | Low priority: harmless for AdMob in practice; remove if Google warns |
| Version/build | `MARKETING_VERSION 1.0.0`, build 1; CI sets build = run number | OK (build number must increase each upload) |
| Hidden features (2.5.19, new Oct 16, 2026) | No debug/cheat menus found in `game/src` | OK |
| Self-contained code (2.5.2), WebKit (2.5.6) | All web assets bundled; service worker skipped on native (`main.js`); Capacitor uses WKWebView; no remote code | OK |

### 3.2 Privacy manifest to add (Claude can do it)
Create `game/ios/App/App/PrivacyInfo.xcprivacy` and add it to the App target's resources:
- `NSPrivacyTracking` = false (the app's own code doesn't track; Google's SDK declares its own).
- `NSPrivacyTrackingDomains` = empty.
- `NSPrivacyCollectedDataTypes` = empty (data is collected by Google's SDK, which ships its own manifest).
- `NSPrivacyAccessedAPITypes` = one entry: `NSPrivacyAccessedAPICategoryUserDefaults`, reasons `["CA92.1"]`.
After the first archive, open Xcode's privacy report (Organizer > archive > Generate Privacy
Report) or read the upload email to confirm nothing else is flagged.

### 3.3 Capacitor/web-view apps and App Review 4.2 / 4.3
- 4.2 rejects apps that are "a repackaged website". Alien Sudoku is a full offline game with all
  assets bundled, native haptics, splash screen, rewarded/interstitial ads, 5 modes, 54 levels and
  achievements: **low risk.** Make sure nothing looks web-like on device (no browser-style
  scrollbars, text selection, pull-to-refresh bounce, "install app"/PWA prompts, or links to the
  web version).
- 4.3(b) "spam": Sudoku is a crowded category. Not on Apple's named list (dating, flashlight,
  fortune telling...), but say in the review notes what is different (glyph symbols, campaign,
  Alien Duel rival, smart hints that explain the technique).
- 4.7 (HTML5 mini games) does **not** apply: the game is inside the app binary, not downloaded.
- 2.3.10: no mention of Android, Google Play or the web/PWA version in the app or metadata.

### 3.4 Building without a Mac

| Option | Cost | What it needs | Fit |
|---|---|---|---|
| **GitHub Actions** (workflow already exists: simulator build, archive, upload to TestFlight) | Repo is public: standard macOS runners are free for public repos (GitHub policy, not re-verified). Private repo minutes count at a higher rate | Fix the account-level block (jobs die in ~2 s: billing/spending limit or account flag). Secrets `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`. **API key must be Admin role** for cloud signing. `macos-latest` = macOS 26 + Xcode 26.6 now; switch to `xcode-27` (preview) or the macOS 27 image before April 2027 | Best: already built |
| **Codemagic** | Personal accounts: 500 free macOS M2 minutes/month, then ~0.095 USD/min (Codemagic docs via search, not re-verified) | `codemagic.yaml` (npm ci, build, `npx cap sync ios`, xcodebuild), App Store Connect API key in Codemagic, automatic signing via its CLI tools | Good fallback if GitHub stays blocked |
| **Xcode Cloud** | 25 compute hours/month included in the membership | Apple: "Use Xcode to initially configure your project" (needs a Mac once). Needs `ci_scripts/ci_post_clone.sh` to install Node, `npm ci`, `npm run build`, `npx cap sync ios` (web assets and `node_modules` are not in git) | Only after a one-time Mac session |
| **Rent a Mac** | MacinCloud pay-as-you-go ~1 USD/hour (third-party reports; billing rounds up per hour); AWS EC2 Mac dedicated hosts have a 24-hour minimum (not re-verified) | Remote desktop, install/sign in to Xcode, clone repo, `npm ci && npm run cap:sync`, open `ios/App/App.xcodeproj`, Archive, Distribute | Good for a first manual upload, simulator screenshots, Icon Composer |
| Borrow a Mac | Free | Same as renting | Fine for one session |

You still need a **real iPhone** (and ideally an iPad) to test the TestFlight build: ATT prompt,
consent form, banner placement, rewarded videos.

### 3.5 Signing details for CI
- The workflow uses automatic signing with `-allowProvisioningUpdates` and an API key. Xcode then
  creates a cloud-managed Apple Distribution certificate. Reports on Apple's forums show this
  fails with "Cloud signing permission error" for Developer/App Manager keys and works with an
  **Admin** team key. Update `docs/STORE_CHECKLIST.md` and `prompts/.../05-ios-testflight.md`.
- Team keys require an Admin account to generate; the private `.p8` downloads **once**.
- Alternative: manual signing with an exported distribution `.p12` + App Store provisioning
  profile stored as secrets (needs a Mac or `openssl` to make the CSR/p12).

---

## 4. Store listing & assets (exact specs)

### 4.1 App record (App Store Connect > Apps > + > New App)
| Field | Value for Alien Sudoku | Rule |
|---|---|---|
| Platform | iOS | |
| Name | **Alien Sudoku** | 2-30 characters, must be unique on the store (no App Store listing with this name found on Nov 17, 2026). Creating the record reserves it |
| Primary language | English (U.S.) | changeable later |
| Bundle ID | `com.eddieg.aliensudoku` | must match Xcode; **cannot change after a build is uploaded**. Register it first under Certificates, Identifiers & Profiles (no capabilities needed) |
| SKU | `alien-sudoku-ios` | letters, numbers, `-` `.` `_`; can't start with `-` `.` `_`; can't change |
| User access | Full access | |

### 4.2 Text fields (limits from App Store Connect Help)
| Field | Limit | Suggested text |
|---|---|---|
| Name | 30 chars | Alien Sudoku |
| Subtitle | 30 chars | Decode glyph logic puzzles (26) |
| Promotional text | 170 chars, editable any time without review | Race a rival alien in Alien Duel, play the Daily Transmission, and keep your streak alive across 54 campaign levels. |
| Description | 4000 chars, plain text | Use `docs/STORE_CHECKLIST.md` section 5 text. Keep "Plays offline" but don't mention other platforms |
| Keywords | **100 bytes**, each keyword > 2 chars; don't repeat the app name or company name, no other apps' names | `puzzle,logic,brain,daily,space,ufo,glyph,number,zen,offline,classic,grid,cosmic,mind,streak,duel` (96 bytes). The repo's list repeats "sudoku" and "alien", which are already indexed from the name |
| What's New | 4000 chars; not shown for version 1.0; required for every later version (2.3.12: list significant changes) | |
| Support URL | required; must lead to real contact info | e.g. `https://<your-site>/alien-sudoku/support` |
| Marketing URL | optional for Apple, **needed for AdMob app-ads.txt** (Google reads the developer website from this field on iOS) | the site whose **domain root** hosts `app-ads.txt` |
| Privacy Policy URL | required for iOS | hosted `docs/PRIVACY.md` (filled in) |
| User Privacy Choices URL | optional | can point to a page explaining Ad privacy choices + iOS Tracking setting |
| Copyright | required; "year + owner"; © added automatically | `2026 <your legal name>` (or the LLC) |
| Category | Games; up to two Games subcategories | **Games > Puzzle**, second subcategory **Board**. Secondary category optional (e.g., Entertainment). Not Kids |
| App Review notes | 4000 bytes | see section 7.2 |

Note `app-ads.txt` must be at the **root** of the domain (`https://example.com/app-ads.txt`). A
GitHub Pages project site (`user.github.io/repo/`) doesn't work; use a user site
(`user.github.io`) or a custom domain.

### 4.3 Screenshots (current Apple spec page)
JPEG/PNG, **no alpha/transparency**, 1-10 per size, at least one. Apple's page header says you
must provide **iPhone with Dynamic Island (medium display)** and, because the app supports iPad,
**iPad 13-inch**. The row notes also say the 6.5" class is "required ... if [6.9"] screenshots
aren't provided". Safest set:

| Size class | Portrait px (accepted) | Landscape px | Need |
|---|---|---|---|
| iPhone 6.9" (Dynamic Island, large) | **1320 x 2868**, 1290 x 2796, 1260 x 2736 | 2868 x 1320, 2796 x 1290, 2736 x 1260 | Provide (covers the 6.5" fallback) |
| iPhone 6.3"/6.1" (Dynamic Island, medium) | **1206 x 2622**, 1179 x 2556 | 2622 x 1206, 2556 x 1179 | **Required** per page header |
| iPhone 6.5" (Face ID, large) | 1284 x 2778, 1242 x 2688 | 2778 x 1284, 2688 x 1242 | Only if no 6.9" set |
| iPad 13" | **2064 x 2752**, 2048 x 2732 | 2752 x 2064, 2732 x 2048 | **Required** (universal app) |
| iPhone Duo, inner display | 2007 x 2853 | 2853 x 2007 | Optional now (adds "made for iPhone Duo" badge); **required from April 2027 for builds using the iOS 27.1 SDK or later** |
| iPhone Duo, outer display | 1398 x 2034 | 2034 x 1398 | Same as above |
| Smaller iPhones/iPads | scaled down automatically | | Optional |

Content rules: show the app in use, not just title art/splash (2.3.3); keep everything 4+
appropriate even though the app is 9+ (2.3.8), so prefer Soft Visitors / glyph sets over the
gnarliest monsters; no prices, no "for kids", no other platforms; no test-ad banners in shots.
Suggested 6-8 shots: campaign board mid-solve, Alien Duel race, Daily Transmission + streak, smart
hint explaining a technique, symbol sets/themes, achievements/stats, Zen mode.

Claude can render these from the web build with Playwright at exact sizes (CSS viewport x device
pixel ratio, e.g. 440x956 @3x = 1320x2868, 402x874 @3x = 1206x2622, 1032x1376 @2x = 2064x2752),
hiding the ad banner. Check a couple against a real device or simulator so they are accurate.

### 4.4 App preview video (optional)
- Up to **3** per device size per language; **15-30 seconds**; max **500 MB**; poster frame default at 5 s.
- `.mov`, `.m4v`, `.mp4` (H.264, 10-12 Mbps, up to High Profile 4.0, max 30 fps) or `.mov` ProRes 422 HQ.
- Audio: stereo, 256 kbps AAC, 44.1 or 48 kHz.
- Resolutions: all iPhone classes incl. iPhone Duo **886 x 1920** portrait / **1920 x 886**
  landscape; iPad 13"/11" **1200 x 1600** portrait / **1600 x 1200** landscape.
- Only screen captures of the app itself (2.3.4); narration/overlays allowed.

### 4.5 New optional creative assets (Oct 5, 2026; Guideline 2.3.14)
Product page header 3840 x 1646 (21:9); search results 3:2 (1920x1280 to 3840x2560); or one
universal 16:9 PNG 5244 x 2950. Videos 5-30 s, 30/60 fps, loop muted. No alpha. Optional; must
be relevant, all-audiences, no pricing.

### 4.6 App icon
1024 x 1024 PNG with no transparency (present). Apple's HIG accepts a non-layered PNG; the system
segments it for dark/tinted looks. A layered Icon Composer file gives better Liquid Glass results
(optional, needs a Mac with macOS Tahoe 26.4+).

---

## 5. Forms & questionnaires (answers for this game)

### 5.1 Age rating (App Information > Age Ratings; new system since 2025, tiers 4+, 9+, 13+, 16+, 18+)

| Section | Question | Answer |
|---|---|---|
| In-App Controls | Parental Controls | No |
| | Age Assurance | No |
| Capabilities | Unrestricted Web Access | No |
| | User-Generated Content | No (the name typed for the alien ship stays on the device) |
| | Messaging and Chat | No |
| | Social Media (added Jul 2026; required since Sep 2026) | No |
| | Social Media Disabled for Users Under 13 | No / not applicable |
| | **Advertising** | **Yes** (banner, interstitial, rewarded) |
| | Shared Location (new from Nov 16, 2026; all apps by Jan 12, 2027) | No |
| | Dating and Relationships (same dates; forces 18+) | No |
| Mature Themes | Profanity or Crude Humor | None |
| | **Horror/Fear Themes** | **Infrequent/Mild** (cartoon monsters with fangs, many eyes, slime; spooky "out of tries" encounter) |
| | Alcohol, Tobacco, or Drug Use or References | None |
| Medical or Wellness | Medical or Treatment Information | None |
| | Health or Wellness Topics | No |
| Sexuality or Nudity | all three | None |
| Violence | Cartoon or Fantasy Violence | None (no physical conflict; the duel is a race) |
| | Realistic Violence / Prolonged Graphic or Sadistic | None |
| | Guns or Other Weapons | None |
| Chance-Based | Gambling | No |
| | Simulated Gambling | None |
| | Contests | None (daily streaks are not contests) |
| | Loot Boxes | No (rewarded ads give a fixed hint/second chance) |
| Age Categories and Override | | **Not Applicable**. Do **not** choose "Made for Kids" |

Result: **9+** (Apple lists infrequent horror/fear as 9+; advertising alone is 4+). If the gnarly
lineup is the default or appears on most screens, "Frequent" would make it 13+. Korea shows the
"All" GRAC pictogram for 9+ (Games category triggers the GRAC display). Answer honestly (2.3.6);
mismatches between rating and in-app content (or ads) are a rejection reason.

### 5.2 App Privacy ("nutrition label")
"Do you or your third-party partners collect data from this app?" **Yes** (Google Mobile Ads + UMP).
Google's disclosure guide (via search; page not reachable here) lists IP address, crash logs,
performance data, device ID, advertising data and product interactions.

| Data type | Purposes | Linked to the user? | Used for tracking? |
|---|---|---|---|
| Location > **Coarse Location** (from IP) | Third-Party Advertising, Analytics | Yes (conservative, see note) | Yes |
| Identifiers > **Device ID** (IDFA when allowed, IDFV) | Third-Party Advertising, Analytics | Yes (conservative) | **Yes** |
| Usage Data > **Product Interaction** | Third-Party Advertising, Analytics | Yes (conservative) | Yes |
| Usage Data > **Advertising Data** | Third-Party Advertising, Analytics | Yes (conservative) | Yes |
| Diagnostics > **Crash Data, Performance Data, Other Diagnostic Data** | Analytics | No | No |
| Everything else (contact info, name, user content, gameplay, purchases, health...) | Not collected (progress and the typed name never leave the device) | | |

Note on "linked": Apple says personal data under privacy laws is treated as linked unless
de-identified before collection; IDFA and IP are personal data under GDPR, so "Yes" is the safe
answer. Many AdMob apps instead declare these as "not linked" (that is what the repo checklist
says). Over-declaring never causes a rejection; under-declaring can get the app removed.
Re-check against Google's iOS data-disclosure page when you can reach it.

Consistency rules: because data is used for tracking, the ATT prompt must appear before any
tracking (it does). Don't reward users for allowing tracking (5.1.2(i)).

### 5.3 Other forms
- **Export compliance:** answered by `ITSAppUsesNonExemptEncryption = false` (HTTPS only).
- **Content rights:** "Does your app contain, show, or access third-party content?" **Yes**, and
  confirm you have the rights (space photos, OFL fonts). Verify image licenses first.
- **Sign-in required:** No. No demo account.
- **Advertising:** declared via age rating "Advertising" + App Privacy. (The old IDFA questions are gone.)
- **DSA trader status:** Trader (section 2.4).
- **Accessibility Nutrition Labels** (VoiceOver, Voice Control, Larger Text, Dark Interface,
  Differentiate Without Color Alone, Sufficient Contrast, Reduced Motion, Captions, Audio
  Descriptions): **voluntary** for now, mandatory "over time" (no date). Claim only what you
  tested end to end. One May 2026 forum report says an empty "App Accessibility" section held an
  app in "Processing" until filled, so fill it (even with "none claimed").
- **Pricing and availability:** Free. All territories **except China mainland** (needs an ICP
  filing and likely a game approval number) and **Vietnam** (Apple: games must be licensed; offline
  games need at least a government notification). Under "iPhone and iPad Apps on Apple Silicon
  Mac", deselect "Make this app available" so the ad-supported iOS app doesn't compete with the
  paid desktop build. Check the Apple Vision Pro availability toggle too.

---

## 6. Testing (TestFlight)
- **Internal testers:** up to **100** App Store Connect users on your team (you count). No Beta App
  Review. Builds appear minutes after processing.
- **External testers:** up to **10,000** by email or public link (optionally with criteria). The
  **first build added to a group goes to Beta App Review**; later builds may not need a full review.
  Required test info: Beta App Description (plus feedback email, what to test).
- **Builds expire after 90 days.** Upload a new build for longer tests.
- To install: TestFlight app from the App Store, accept the invite.
- Test checklist on a real iPhone and iPad: fresh install shows UMP consent (EEA/UK via VPN or
  debug geography) then the **ATT system prompt**; banner never covers the board; interstitials only
  between games with a visible close button; rewarded ads grant the hint/second chance; "Ad
  privacy choices", privacy policy and "Report an ad" links work; airplane mode (ads fail
  gracefully); iPad in portrait/landscape and small Stage Manager windows; resume after
  background; no crash on first launch.
- Register your device as an AdMob **test device** before using real ad ids. Never tap your own
  live ads.

---

## 7. Submission & review

### 7.1 Guidelines most likely to bite this game
| Guideline | Risk for Alien Sudoku | Fix |
|---|---|---|
| 2.1 completeness | Crash, blank screen while splash waits (`launchAutoHide: false`), test-ad banners | Test release build via TestFlight; real ad ids |
| 2.3.3 / 2.3.7 / 2.3.8 / 2.3.10 metadata | Scary screenshots, keyword stuffing, "for kids", mentions of Android/web | Section 4 |
| 2.3.6 age rating | Rating that doesn't match the monsters or the ads | 9+, max ad rating G/PG |
| **2.5.18 ads** | Ads not fitting 9+; no "report an ad"; interstitial close button | Set `maxAdContentRating`; add Report link; keep AdMob formats |
| 1.3 / 5.1.4 Kids | Choosing Made for Kids with AdMob | Don't |
| **5.1.1(i) privacy policy** | No in-app link; policy lacks retention/deletion/revoke-consent info, placeholders "[Your name]" | Add link; finish `docs/PRIVACY.md` |
| 5.1.2 tracking | ATT prompt not seen by reviewer; label says tracking | Mention in notes where it appears; make sure it isn't swallowed by the splash/consent flow |
| 4.2 / 4.3 | Web wrapper or "another sudoku" | Notes explaining features |
| 2.5.19 | Hidden/dormant features | None found |

### 7.2 App Review notes (draft)
"Alien Sudoku is an offline Sudoku game with alien glyph symbols. No account or login. All
progress is stored on the device. Ads: Google AdMob banner, interstitial between finished games
(never in the first 3 minutes, at most every 2 games), and optional rewarded videos for an extra
hint or a second chance. On first launch the Google consent message appears where required, then
the App Tracking Transparency prompt. Settings > Privacy & data has the privacy policy, Ad
privacy choices and Report an ad. Not designed for children; rated 9+ for mild cartoon monster
imagery."

### 7.3 Submitting
1. Select the build on the version page, fill all metadata, App Privacy, age rating, pricing.
2. Choose **Manual release** for 1.0 (lets you link AdMob and check the listing first).
3. Add for Review > Submit. Statuses: Waiting for Review > In Review > Pending Developer Release.
4. Timing: at least 50% of submissions reviewed in < 24 h, 90% in < 48 h (Apple). Expedited
   review only for critical bug fixes or event deadlines.

### 7.4 Rejections
- Read the message in the app's **App Review** section in App Store Connect; it cites the exact
  guideline. Reply there to clarify or ask questions; fix, then resubmit (metadata-only issues
  can usually be fixed without a new build).
- If you think the reviewer misunderstood: appeal to the **App Review Board**, with specific
  reasons, one appeal per rejected submission.
- Typical first-time AdMob rejections: 5.1.2 (ATT prompt not found or label/prompt mismatch),
  2.1 (crash or placeholder/test content), 5.1.1 (privacy policy link/content), 2.5.18 (ads).

---

## 8. After launch
- Link the iOS app in AdMob (App settings > add store listing) and wait for `app-ads.txt` to verify
  (Google crawls the Marketing URL domain; third-party reports say up to ~7 days for App Store apps).
- Set promotional text and respond to reviews. Watch crashes in App Store Connect / Xcode Organizer.
- **Jan 12, 2027:** answer the new Shared Location and Dating questions (No/No) if not done.
- **Before April 2027:** build with Xcode 27 / iOS 27 SDK (CI: `runs-on: xcode-27` preview or the
  GA macOS 27 image), test on iPhone Duo in Device Hub, add iPhone Duo screenshots.
- Every update needs What's New text; TestFlight builds expire after 90 days; renew the
  membership yearly (auto-renew available in the US).
- Re-check App Privacy when the GMA SDK or ad settings change.

---

## 9. macOS: the Electron desktop build (sold on Steam/GOG/itch)

### 9.1 Developer ID signing + notarization (same 99 USD membership)
- Current state: `desktop/package.json` has `"identity": null`; builds are unsigned; mac targets
  are universal `dmg` + `zip`. Universal is right: macOS 27 is the last release with Rosetta, and
  Intel-only apps stop running on Apple silicon after it.
- Unsigned/un-notarized downloads get blocked by Gatekeeper. (Recent macOS no longer offers the
  simple right-click > Open bypass; users must go to System Settings > Privacy & Security > Open
  Anyway. Apple support page not reachable here; `prompts/.../07-desktop-signing.md` still
  describes right-click.) For itch.io/GOG direct downloads, signing + notarization is effectively
  required. Steam's own docs could not be reached; signing + notarizing is the safe default.
- Only the **Account Holder** can create a **Developer ID Application** certificate. Create it
  from the **G2 Sub-CA**: the original Developer ID Sub-CA expires **Feb 1, 2027** (old-cert .pkg
  files stop installing; already notarized .app files with a secure timestamp keep working).
- electron-builder 26 (local source): hardened runtime on by default for non-MAS builds; default
  entitlements allow JIT, unsigned executable memory and disable library validation (what
  Electron needs). It notarizes automatically with `notarytool` when either `APPLE_ID` +
  `APPLE_APP_SPECIFIC_PASSWORD` + `APPLE_TEAM_ID`, or `APPLE_API_KEY` (path to .p8) +
  `APPLE_API_KEY_ID` + `APPLE_API_ISSUER`, or `APPLE_KEYCHAIN_PROFILE` are set. Signing needs
  `CSC_LINK` (base64 .p12) + `CSC_KEY_PASSWORD` and removing `"identity": null`.
- Needs macOS to sign with electron-builder (GitHub macOS runner, Codemagic, rented Mac). Linux
  alternative: `rcodesign` (apple-codesign) can sign and notarize from Linux; untested here.
- Notarize the `.app`, staple the ticket, then ship the dmg (stapled) and zip.

### 9.2 Is a Mac App Store release worth it?
- Requirements (2.4.5): App Sandbox, packaged as a signed installer (Apple Distribution + Mac
  Installer Distribution certificates, provisioning profile), no other updater, no license
  screen, no downloaded code. electron-builder's `mas` target turns hardened runtime off and needs
  sandbox entitlements for the app and its helpers. The game only uses local storage, so
  sandboxing is easy.
- Extra work/costs: separate App Store Connect macOS app (use a **different bundle id**, e.g.
  `com.eddieg.aliensudoku.mac`; the desktop `appId` currently equals the iOS bundle id, and
  adding macOS to the iOS record would make it a free universal purchase), Mac screenshots
  (16:10: 1280x800, 1440x900, 2560x1600 or 2880x1800), App Review, Paid Apps Agreement + tax +
  banking for a paid app, Small Business Program for 15% commission.
- Verdict: **not for launch.** Do Developer ID + notarization first (needed for itch/GOG). Revisit
  the Mac App Store after the PC price is decided and the iOS launch is done; it is mostly
  packaging work, not a rewrite.

---

## 10. Sources (URL: what it confirmed)
- https://developer.apple.com/news/upcoming-requirements/ : Xcode 26/iOS 26 SDK since Apr 28, 2026; iOS 13 minimum target since Sep 9, 2026; age rating answers by Jan 31, 2026; DSA removal since Feb 17, 2025; required reason APIs since May 1, 2024; notarytool only since Nov 1, 2023.
- https://developer.apple.com/news/ : 2026 news list (iPhone Duo, age rating changes, ATT EU, Developer ID Sub-CA, Rosetta, guideline updates).
- https://developer.apple.com/news/?id=k1mtkt1k : submissions open for OS 27 (Sep 9, 2026); iOS 27 SDK required starting April 2027.
- https://developer.apple.com/news/?id=kkphp5qo : iPhone Duo ships Oct 23, 2026; Xcode 27.1; Duo screenshots required from April 2027.
- https://developer.apple.com/news/?id=tlur8uvi : social media age-rating questions; required from September 2026.
- https://developer.apple.com/news/?id=yxkh08us : Shared Location and Dating descriptors from Nov 16, 2026; all apps by Jan 12, 2027; Dating = 18+.
- https://developer.apple.com/news/?id=idsft9ai : EU alternative ATT prompt from iOS/iPadOS 27.2.
- https://developer.apple.com/news/?id=92th7e5i and https://developer.apple.com/news/?id=a233fmpw : guideline changes (2.3.14 creative assets, 2.5.19 hidden features, 4.3 examples).
- https://developer.apple.com/news/?id=w4atic4c : Developer ID Sub-CA expires Feb 1, 2027; use G2.
- https://developer.apple.com/news/?id=w5ngl9k2 : macOS 27 is the last release with Rosetta; ship universal.
- https://developer.apple.com/news/?id=sg176nne and https://developer.apple.com/support/age-assurance/ : Texas SB 2420 effective Jun 4, 2026; Declared Age Range / Significant Change APIs; developers responsible.
- https://developer.apple.com/news/?id=06h4gf33 : Vietnam game licensing.
- https://developer.apple.com/app-store/review/guidelines/ : texts of 1.3, 2.1, 2.3.x, 2.4.1, 2.4.5, 2.5.2, 2.5.6, 2.5.18 (incl. report-ads requirement), 2.5.19, 4.1-4.3, 4.7, 5.1.1, 5.1.2, 5.1.4, 5.2.
- https://developer.apple.com/distribute/app-review/ : review times (50% < 24 h, 90% < 48 h), expedited review, App Review Board appeals, common rejections.
- https://developer.apple.com/programs/enroll/ , https://developer.apple.com/support/enrollment/ , https://developer.apple.com/support/D-U-N-S/ , https://developer.apple.com/support/renewal/ : fee, individual vs organization, D-U-N-S timing, seller name, expiry effects.
- https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements : trader factors (ad-sponsored), displayed info, verification.
- https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements and .../manage-banking-information/enter-banking-information (via search): free apps under the DPLA; Paid Apps Agreement needed for paid apps/IAP, before tax/banking.
- https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions and https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating : categories, tiers, Made for Kids, overrides.
- https://developer.apple.com/tutorials/data/documentation/appstoreconnectapi/ageratingdeclaration/attributes-data.dictionary.json : full list of questionnaire fields and values.
- https://developer.apple.com/app-store/app-privacy-details/ : definitions of collect, tracking, linked; third-party SDK responsibility; on-device data not collected.
- https://developer.apple.com/support/third-party-SDK-requirements/ : SDK list (includes Capacitor, Cordova; not GoogleMobileAds/UMP).
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications : all screenshot sizes, required sizes, iPhone Duo.
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications : preview specs.
- https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications : header/search assets.
- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information and .../app-information : field limits.
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview : 100 internal, 10,000 external, Beta App Review, 90-day expiry.
- https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon : iOS apps on Mac by default; opt-out steps.
- https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels : labels voluntary for now.
- https://developer.apple.com/forums/thread/827270 : anecdote, empty accessibility section delayed availability.
- https://developer.apple.com/design/human-interface-guidelines/app-icons : PNG or Icon Composer; 1024 px; appearances.
- https://developer.apple.com/icon-composer/ : requires macOS Tahoe 26.4+.
- https://developer.apple.com/xcode-cloud/ and https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow : 25 compute hours/month; first setup in Xcode.
- https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api : team keys need Admin to generate; one-time download.
- https://developer.apple.com/forums/thread/698117 (+ search results incl. thread 810658) : cloud signing with API key works only with Admin keys.
- https://developer.apple.com/developer-id/ : Account Holder creates Developer ID certs; notarytool; stapler.
- https://developer.apple.com/app-store/small-business-program/ : 15% commission, needs Paid Apps Agreement.
- https://github.com/actions/runner-images (README, macos-26-arm64 and xcode-27 readmes) : `macos-latest` = macOS 26 arm64 with Xcode 26.6; Xcode 27 on `xcode-27` preview; macOS 14 retired Nov 2, 2026.
- Repo files: `game/ios/App/App/Info.plist`, `project.pbxproj`, `CapApp-SPM/Package.swift`, `node_modules/@capacitor/preferences/README.md` (UserDefaults CA92.1), `node_modules/@capacitor/ios/**/PrivacyInfo.xcprivacy`, `node_modules/@capacitor-community/admob/Package.swift` (GMA 13.11.0, UMP 3.1), `src/platform/ads.js`, `desktop/node_modules/app-builder-lib/out/mac/MacTargetHelper.js` (notarization env vars, hardened runtime defaults).
- Search snippets only (sites unreachable): Google AdMob iOS data disclosure (developers.google.com/admob/ios/privacy/data-disclosure), AdMob app-ads.txt uses Marketing URL (support.google.com/admob/answer/9363762), Codemagic pricing (docs.codemagic.io/billing/pricing), GitHub Actions pricing, MacinCloud pricing, enrollment wait times (Apple forum threads).

**Could not verify:** Google's exact App Privacy table for GMA SDK 13.x and full SKAdNetwork list
(developers.google.com blocked); GitHub Actions free-minute rules (docs.github.com blocked);
Codemagic, AWS EC2 Mac and MacinCloud prices; Steam's macOS signing rules; Electron's MAS guide;
current macOS Gatekeeper bypass steps (support.apple.com blocked); the exact developer duties
under Texas/Utah/Louisiana age-assurance laws for a no-account free game; China mainland rules for
free ad-supported games in 2026.
