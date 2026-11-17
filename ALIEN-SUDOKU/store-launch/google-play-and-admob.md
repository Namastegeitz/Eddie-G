# Google Play + AdMob (+ other Android stores): Alien Sudoku launch guide

Researched 17 November 2026. Store keys: `google` (Google Play), `admob` (AdMob),
`android-other` (Amazon, Samsung, Huawei). Paths refer to the new layout:
`game/...` (the Capacitor app) and `store-launch/...` (listing drafts).

Note on sources: this workspace could fetch developer.android.com directly. Google's
help centers (support.google.com, developers.google.com, play.google.com) were only
reachable through search results. Where a fact rests on search snippets or on
third-party pages, it is flagged "(verify)". Anything marked "could not verify" needs
a check in the console itself.

---

## 1. Summary

**What it costs**

| Item | Cost |
|---|---|
| Google Play Console developer account | **US$25, one time** (no renewal) |
| AdMob account | Free |
| Android developer verification (for Play developers) | Free. Your Play identity check counts, and apps are registered automatically. |
| Samsung Galaxy Store (optional) | Free |
| Website for privacy policy + `app-ads.txt` | Free (GitHub Pages user site, surge.sh, Firebase Hosting). A custom domain is optional, roughly $10-15/year. |
| Optional: business mailing address / second phone number | Only if you declare "trader" for the EU and don't want your home address and phone shown (see 2.4) |

**How long it takes** (realistic, for a brand-new personal account)

| Step | Typical wait |
|---|---|
| Play Console sign-up, ID check, phone/email codes, device check | 1-3 days (ID review can take longer) |
| AdMob account review | Up to 24 hours, rarely up to 2 weeks |
| First upload to internal testing | Minutes |
| Closed test release review | Hours to a few days |
| **Closed test: 12+ testers opted in for 14 days in a row** | **14 days minimum** |
| "Apply for production" review | Usually 7 days or less |
| Production review | Hours to ~7 days for new accounts |
| AdMob app readiness review after store linking | 2-3 days, sometimes longer. Ads are limited until it passes. |
| **Total from sign-up to public launch with full ads** | **About 4-6 weeks** |

**The big risks for this game**

1. **No Android build path yet.** This workspace can't reach `dl.google.com`, so no AAB
   can be built here, and GitHub Actions jobs don't start. Nothing can be uploaded to
   Play until one of these works: (a) fix Actions billing, (b) build in Android Studio
   on your own computer, or (c) allow `dl.google.com` (and `maven.google.com`) in this
   cloud environment's network settings.
2. **The 12-tester / 14-day closed test.** You need 12 real people with Android phones
   and Google accounts who stay opted in for 14 straight days. This is the longest
   part of the launch. Recruit 15-20 to be safe.
3. **Cute aliens and the Families policy.** "Soft Visitors", "cuddly" and "Baby Blip"
   could make Google decide the listing appeals to children. If Google says so, you
   must either put children in your audience (Families policy: age screen,
   child-directed ad tagging, extra review) or change the listing. Choose 13+, keep the
   store listing neutral, and set AdMob's maximum ad content rating to PG or G.
4. **Ad placement.** The banner shows during play, right under the glyph keypad. Ads
   next to tap targets are the classic "accidental clicks" violation in AdMob. Add a
   clear gap, or hide the banner while a puzzle is being played.
5. **EU trader status (new).** Third-party reports say every Play account must declare
   trader or non-trader status by **1 February 2027**. Traders get their address and
   phone number shown to EU users from 1 March 2027. An ad-funded app is likely
   "trader" activity. (verify in the Play Console banner)
6. **Coming deadlines.** From **February 2027**, Play enforces new memory and DEX
   code-optimization thresholds (apps must be shrunk/optimized with R8; the game has
   `minifyEnabled false`). Also from **1 February 2027**, updates must support 16 KB
   pages (very likely already fine: no native code). The ads SDK the Capacitor plugin
   uses (Google Mobile Ads "legacy" v25) becomes **deprecated 30 June 2027** and
   **sunsets 30 June 2028**.
7. **`app-ads.txt` must sit at the root of your developer website** (for example
   `https://example.com/app-ads.txt`). A GitHub Pages *project* site
   (`user.github.io/repo/`) will not work. Use a user site, surge.sh, Firebase Hosting
   or a custom domain.

**Status at a glance**

| Area | Status |
|---|---|
| targetSdk 36 / compileSdk 36 / minSdk 24 | OK for now (Aug 31, 2026 rule needs 36) |
| AdMob + UMP consent wiring, privacy options button, interstitial cap, opt-in rewarded | OK (in `game/src/platform/ads.js`) |
| Real AdMob ids | Not yet (Google test ids in use) |
| Upload key | Not created |
| AAB build | Blocked (no SDK here; Actions not starting) |
| Privacy policy | Template in `game/docs/PRIVACY.md`, not hosted, name/email blank |
| In-app privacy policy link | Missing (required by Play's User Data policy) |
| Store listing text | Drafts in `store-launch/listing/listing.json` (support email/URL still TODO) |
| Store graphics | Generator exists (`game/tools/store-assets.mjs`), images not produced yet |
| Accounts (Play Console, AdMob) | None yet |

---

## 2. Accounts & business setup

### 2.1 Google Play Console: personal or organization?

| | Personal | Organization |
|---|---|---|
| Who | An individual (you) | A registered business (LLC etc.) |
| Needs | Government ID, legal name and address (taken from your Google payments profile), verified contact email and phone | Everything above **plus a D-U-N-S number** (free from Dun & Bradstreet, can take up to ~28-30 days), verified website (Google Search Console), and the business's legal details |
| 12-tester / 14-day closed test | **Required** (accounts created after 13 Nov 2023) | Not required (verify) |
| Shown on Google Play | Developer name, developer email, your legal name and **country**. The full address is shown once you monetize *on* Google Play (paid app or in-app purchases). AdMob ads alone don't count (verify). EU trader status can make the address and phone public (2.4). | Business name, address, phone, email |
| Fee | $25 | $25 |

**Recommendation:** Eddie G is an individual with no company, so a **personal account**
is the realistic path. An organization account only makes sense if you form an LLC
anyway (it removes the closed-test rule and keeps your home address private), but
getting a D-U-N-S number alone takes weeks. The account type can't be switched
casually later. Moving apps to a new organization account needs an app transfer.

### 2.2 What sign-up asks for (personal)

1. A Google account you'll keep for good. Turn on 2-Step Verification first: Play
   Console has required it since 2020-21.
2. Developer name (public, can differ from your legal name: "Eddie G" is fine).
3. Legal name and address. These come from (or create) a **Google payments profile**.
   Use your real legal name, matching your ID.
4. **Contact email** and **contact phone**, each verified with a one-time code (phone by
   SMS or call, in `+1...` format). They must keep working for the life of the account.
5. A public **developer email** shown on Google Play. Use an address you check, for
   example a dedicated Gmail.
6. The $25 fee, paid by card in your name.
7. **Identity verification**: upload a government ID. Review usually takes a few days.
8. **Android device verification**: new personal accounts must install the **Play
   Console app on a physical, non-rooted Android 10+ phone**, sign in with the same
   account and tap Verify. It takes about a minute, but it's mandatory before you can
   publish. No Android phone means no publishing, so borrow one if needed (the same
   phone can verify several accounts).
9. Questions about your experience and plans (free-text, no wrong answers).

### 2.3 The closed-test rule and production access (personal accounts)

- Personal accounts created after 13 November 2023 must run a **closed test with at
  least 12 testers who have been opted in continuously for at least 14 days**.
  It was 20 testers until December 2024, per third-party reports. Google's help page
  says 12 as of November 2026.
- Testers who opt in and then leave before 14 days don't count. Internal testing and
  open testing don't count.
- **Open testing is also locked** until you get production access.
- Then use **Dashboard → Apply for production**. The form has three parts: your closed
  test (how you recruited testers, how engaged they were, what feedback you got), your
  app (who it's for, what makes it different), and production readiness (what you
  changed, why it's ready). Google says review usually takes **7 days or less**.
- Tips: get testers to actually play (Google can see engagement); ship one or two
  updates during the test in response to feedback, and mention them in the
  application. If the application is rejected, Google says which part to improve,
  and you can reapply.

### 2.4 EU "trader status" (Digital Services Act). New, deadline 1 Feb 2027 (verify)

From November 2026 Play Console asks every developer account to declare "trader" or
"non-trader". Reported details (third-party sources and a Play Console banner;
Google's help page was not reachable here):
- Deadline **1 February 2027**. Missing it may block updates.
- Traders: phone number and address shown to EU/UK users from **1 March 2027**.
  Personal-account traders must verify a public phone number.
- An app that earns ad revenue is normally a "trade" activity, so expect to answer
  **trader** if you distribute in the EEA/UK. Options: (a) declare trader and use a
  business mailing address (PO box or virtual office) and a separate phone number, or
  (b) exclude EEA/UK countries from distribution. Google may still want the
  account-level answer. Don't pick "non-trader" just to avoid disclosure; that risks
  suspension.

### 2.5 Android developer verification (Google's 2026 identity program)

- What it is: from **30 September 2026**, certified Android phones in **Brazil,
  Indonesia, Singapore and Thailand** only install apps from verified developers when
  the install comes from participating stores (Google Play, Samsung Galaxy Store,
  Xiaomi GetApps, OPPO, vivo, HONOR, Transsion). Enforcement goes **global in 2027**.
- What it means for Alien Sudoku: **almost nothing extra if you ship on Google Play.**
  Your Play Console identity check is your developer verification. When you create the
  app in Play Console, Google **automatically registers the package name**
  `com.eddieg.aliensudoku` to your account (it tells you if someone else already uses
  it). With Play App Signing, Google holds the signing key, so ownership is proven
  automatically.
- What to do: create the app in Play Console early to claim the package name, then
  check **Play Console → Android developer verification** shows it as "Registered".
- If you also ship the APK elsewhere (Galaxy Store, your website), the APK is signed
  with a different key than Google's, so **register that extra signing key in Play
  Console** too. Simpler: upload the Play-signed universal APK from App bundle
  explorer to the other store, so it uses the same key.
- Side-loading test builds: `adb install` is always exempt. When enforcement goes
  global in 2027, debug APKs side-loaded onto friends' phones will need registration
  or the user's "advanced flow". Use Play's internal/closed testing tracks instead.
- **Don't lose your keys:** "If you lose your signing key you won't be able to
  register your packages." Play App Signing protects the app signing key. Back up
  the upload key anyway.

### 2.6 AdMob account

- Sign in at admob.google.com with the **same Google account** (or one you'll keep).
  You must be an adult (18+, verify). Choose **Individual** (this can't be changed later; payments go to
  the account holder's name).
- **Account review:** your account must be verified before it can serve ads, and that
  needs your **payment details** (payments profile). Google says review "typically
  takes up to 24 hours, but in rare cases can take up to 2 weeks". One AdMob account
  per person: close any old one first.
- **Payments:** payment goes out around the **21st of the following month** once your
  balance passes the threshold ($100 in the US by default). Before the first payment:
  - US **tax info** (W-9 as an individual) in Payments → Settings. It's needed by the
    20th to be paid that month.
  - A **PIN letter** is mailed to your payments address once you reach the
    verification threshold. It arrives in about 3 weeks. Enter it within 4 months or
    ads stop.
  - Possibly an extra ID verification.
- Add the app before it's on the store (so you get ids now), then **link it to the
  Play listing after the app is live** (see 7.3).

### 2.7 Website, email and privacy policy (needed by both Play and AdMob)

- **Privacy policy URL**: required for every Play app, even ones that collect nothing.
  It must be public, active, not a PDF, not geofenced, clearly titled "Privacy
  policy", and it must name the developer exactly as on the Play listing (or name the
  app). Fill in `game/docs/PRIVACY.md` (name, email) and host it.
- **The app itself must also link to the policy** (Play User Data policy: "a privacy
  policy link or text within the app itself"). Settings → Privacy & data has no
  link yet. **Needs a small code change.**
- **Developer website**: optional for Play, but **required for AdMob app-ads.txt**
  verification. AdMob reads the website from your Play listing, then fetches
  `/app-ads.txt` at the **root of that host**.
- **Support email**: required and public. Pick one you'll check (the listing JSON
  still has `TODO`).

---

## 3. Technical / build requirements (mapped to the game)

| Requirement (as of Nov 2026) | Game today | Verdict |
|---|---|---|
| **Target API level**: new apps and updates must target **API 36 (Android 16)** since **31 Aug 2026** (extension window ended 1 Nov 2026). Existing apps need 35+ to stay visible to new users on newer Android. | `targetSdkVersion = 36` in `game/android/variables.gradle` | **OK.** The next bump hasn't been announced. Google usually raises it each August (expect API 37 around Aug 2027, unconfirmed). |
| compileSdk | 36 | OK |
| minSdk | 24 (Android 7.0). Google Mobile Ads 25.5+ itself requires 24. | OK |
| **Android App Bundle (AAB)** required for new apps (since Aug 2021). Compressed download limit 4 GB. | Gradle can build `bundleRelease`. CI job exists. Nothing can be built here (no SDK: `dl.google.com` blocked). Actions jobs don't start. | **Blocked** until a build path exists |
| **Play App Signing** required for new apps; you sign uploads with an **upload key** | Release signing reads `android/keystore.properties` or `ANDROID_KEYSTORE_*` env vars. No keystore exists yet. | **Needs action.** Generate an upload key (RSA 2048, validity 25+ years; Play needs it valid past 22 Oct 2033). Back it up, and let Google generate the app signing key. |
| **versionCode** must rise with every upload (max 2,100,000,000). versionName is free text. | CI passes `-PversionCode=${{ github.run_number }}`. A local build defaults to **1**. | OK in CI. **Don't mix** local and CI uploads without passing a higher `-PversionCode`. |
| **16 KB memory pages**: apps targeting 35+ must support 16 KB pages on 64-bit devices. From **1 Feb 2027**, updates that don't support it can't be released. | No NDK code. Capacitor and the plugins are Java/Kotlin. AGP 8.13 (8.5.1+ aligns libraries correctly). | **Very likely OK.** Confirm after the first build: APK Analyzer or the Play Console App bundle explorer should show no `lib/*.so` (or only 16 KB-aligned ones). |
| **AD_ID permission**: apps targeting 33+ that use the advertising ID must declare `com.google.android.gms.permission.AD_ID` | Not in `game/android/app/src/main/AndroidManifest.xml`, but play-services-ads merges it automatically | **OK.** Check the merged manifest once. Answer "Yes" to the Advertising ID declaration. |
| **Edge-to-edge**: enforced when targeting 35. Targeting 36 removes the opt-out on Android 16. | Capacitor 8 SystemBars with `insetsHandling: css`. CSS uses `--safe-area-inset-*`, and the banner height is added to bottom padding. | **OK in code.** Test on an Android 15 and an Android 16 device or emulator (gesture and 3-button nav). |
| **Predictive back** (Android 16 + target 36): `onBackPressed` no longer called | Uses the Capacitor App `backButton` listener (OnBackPressedCallback based) | **Probably OK.** Test back on every screen on Android 16. |
| **Large screens** (Android 16 + target 36): orientation/aspect locks ignored on 600dp+ unless the app is a **game** via `android:appCategory="game"` | No orientation lock; no `appCategory` | **Small change:** add `android:appCategory="game"` to `<application>` (also helps Play's categorization). Test on a tablet/foldable emulator. |
| **New Play quality thresholds from Feb 2027**: dynamic memory (RSS+swap), bitmap memory, and **DEX code optimization: at least 25% coverage with R8 or another shrinker**. Failing apps may lose visibility and publishing ability. | `minifyEnabled false` in `game/android/app/build.gradle` | **Needs change before Feb 2027:** enable `minifyEnabled true` + `shrinkResources true`. Capacitor ships consumer ProGuard rules. Test that the AdMob plugin still works. |
| Zero-tap sign-in (April 2027) | No sign-in | Not applicable (games are exempt anyway) |
| **Google Mobile Ads SDK**: legacy v25 is in maintenance. **Deprecated 30 Jun 2027, sunset 30 Jun 2028.** Google now prefers the "GMA Next-Gen SDK". | `@capacitor-community/admob` 8.3.0 → `play-services-ads:25.4.+`, UMP 4.0.0 | **OK for launch.** Plan a plugin upgrade before mid-2027. |
| Ad unit ids | Google **test** ids (`ca-app-pub-3940256099942544/...`). App id in `strings.xml` is the test id. | **Needs real ids** for production (`tools/set-admob-ids.mjs` + `VITE_ADMOB_ANDROID_*`). Keep test ids for internal/closed builds if you like. |
| Consent (GDPR/UK + US states) | UMP `requestConsentInfo` → form if required → `canRequestAds` gate. "Ad privacy choices" button when required. | **OK.** Messages must be created and published in AdMob (6.9). |
| Interstitial placement | After a finished game, when leaving the result screen; every 2 games; at least 3 min apart; none in the first minutes of a session | **OK** (natural break, not on launch, not every action) |
| Rewarded | Optional "Watch video" for an extra hint or second chance. Reward granted only on completion. Granted anyway if no ad loads. | **OK** |
| Banner | Adaptive banner at the bottom on menus **and during play**, right under the keypad | **Risky.** Add a clear gap (16dp+) or hide the banner during active play. |
| Max ad content rating | Not set in code or AdMob | **Set** PG (or G) in AdMob Blocking controls, or `maxAdContentRating` in `AdMob.initialize`, to match the IARC rating and the cute art |
| Permissions | INTERNET, ACCESS_NETWORK_STATE, AD_ID (merged) | OK. Nothing that triggers a permission declaration form. |
| `android:allowBackup="true"` | Progress (and the typed name) can go into the user's own Android backup | OK. Not "collection" by you. Keep it (good for players). |
| AI-generated art/music | Pre-made assets, no generative AI at runtime | Play's AI-Generated Content policy covers apps that *generate* content, so it doesn't apply. No disclosure needed. |
| Space photos (likely NASA/ESA) | Licenses unverified | **Verify before listing.** NASA imagery is generally public domain (no NASA logos/endorsement). ESA images are often CC BY-SA 3.0 IGO, and ESA/Hubble and ESA/Webb images are CC BY 4.0. Both need credit. Add credits to Settings → About and the listing. |

**How to unblock the build (pick one):**
1. **GitHub Actions**: check Settings → Billing → Actions. A private repo with a $0
   spending limit and used-up free minutes, or a failed payment method, stops jobs
   from starting. Public repos run standard runners for free. Once jobs run, add the
   four `ANDROID_KEYSTORE_*` secrets and the workflow outputs a signed AAB.
2. **Your own computer**: install Android Studio, then `npm ci && npm run build && npx
   cap sync android`, then `cd android && ./gradlew bundleRelease -PversionCode=N`
   with `keystore.properties`.
3. **This cloud workspace**: allow `dl.google.com` and `maven.google.com` in the
   environment's network settings. Then Claude can install the SDK and build here.

---

## 4. Store listing & assets (exact specs)

Listing text drafts already exist in `store-launch/listing/listing.json`
(`listing.md` shows the character counts).

| Field | Limit / spec | Alien Sudoku |
|---|---|---|
| App name | **30 characters** max. No emoji, no ALL CAPS, no "best/#1/free/sale" or ranking claims. | "Alien Sudoku" (12) |
| Short description | **80 characters** | Draft: "Sudoku with alien glyphs: 54-level campaign, daily puzzles and AI rival duels." (78) |
| Full description | **4,000 characters** | Draft is 1,390 + the ads line. Avoid fake testimonials, keyword stuffing, and claims of store rank. |
| What's new | 500 characters | Draft (55) |
| **App icon** | **512 × 512 px, 32-bit PNG (alpha allowed), max 1 MB.** Full square: Play applies the rounding and shadow, so don't add your own. No "free"/badges. | `assets/icon-only.png` is 1024², and the generator outputs 512² |
| **Feature graphic** | **1024 × 500 px, JPEG or 24-bit PNG (no alpha)**. Required. Keep key art away from the edges (it's cropped in some places). Don't repeat the icon. | Generator outputs `google-feature-graphic-1024x500` |
| **Phone screenshots** | **2-8**. JPEG or 24-bit PNG, no alpha. Each side **320-3,840 px**, long side no more than **2× the short side**, up to 8 MB (verify). For game promotion, Google recommends **3-4+ screenshots at least 1080 px**: 9:16 portrait **1080 × 1920** or 16:9 landscape 1920 × 1080. Show real gameplay. | Generator: `google-phone` 1080 × 1920 |
| 7" and 10" tablet screenshots | Up to 8 each, same format rules. Recommended so the game is shown properly on tablets (sources disagree on exact minimums; 1080-7680 px per side is often quoted). | Generator: `google-tablet-10in` 1600 × 2560. Add a 7" set (for example 1200 × 1920). |
| Chromebook screenshots | Optional, up to 8, 16:9 or 9:16, 1080-7680 px (verify) | Optional. Reuse the 1920 × 1080 PC shots. |
| Video | Optional. One YouTube URL, public or unlisted, **not** age-restricted, ads off on the video, embedding allowed | Optional (a 30 s gameplay capture helps) |
| Category | Game → **Puzzle** | |
| Tags | Up to 5 from Google's list (for example Sudoku, Logic, Brain games, Casual, Offline) | |
| Contact details | **Email (required, public)**, website (optional, but needed for app-ads.txt), phone (optional) | Fill in |
| Privacy policy URL | Required (App content) | Host first |
| "Contains ads" label | Shown automatically from your Ads declaration | |

**Listing wording that matters for this game**
- **Child appeal:** the draft says "cuddly Soft Visitors" and "sleepy Baby Blip". With a
  13+ audience, Google reviews whether the listing "unintentionally appeals to
  children" from both imagery and wording. For Play, consider wording like "four
  alien lineups, from friendly visitors to the fanged Gnarly Horde". Lead with the
  puzzle and the sci-fi look, not the cutest aliens.
- Use the mobile ads line at the end ("Free to play with ads. Watching a short video
  ... is always optional."). Don't say "no ads".
- Screenshots must show the real game. Don't show test-ad banners ("Test Ad") in them.
- Don't mention other platforms' prices, and don't link to the PC version with a
  "buy" call to action.

---

## 5. Forms & questionnaires (with Alien Sudoku's answers)

All are under **Play Console → your app → Policy and programs → App content**
(older menus: "Policy → App content").

### 5.1 Privacy policy
Paste the hosted URL. It must match what the app does: AdMob + UMP data, on-device
storage only, no accounts, under-13 statement, contact email.

### 5.2 App access
**"All functionality in my app is available without any access restrictions."** (No
login.) Note that the campaign is unlocked by play, not by credentials. That's fine.

### 5.3 Ads
**"Yes, my app contains ads."** The "Contains ads" label appears on the listing.

### 5.4 Content rating (IARC questionnaire)
- Email: the address that should get the IARC certificates.
- Category: **Game**.
- Answer honestly, per section:
  - Violence: **No.** There is no fighting, attacking, injury or death. Monsters with
    fangs that just appear are not violence.
  - Fear / scary content: the Gnarly Horde (fangs, many eyes, slime) and the "ship
    rises and asks who you are" moment are **mild, non-realistic, cartoon scary
    imagery**. If asked whether the game has content that could frighten young
    children, answer **Yes, mild / cartoon / non-realistic** (the questionnaire's
    "scary elements" options typically include non-realistic monsters and mild
    tension). Answering no and being re-rated later is worse.
  - Sexual content, nudity: No. Language/profanity: No. Drugs, alcohol, tobacco: No.
    Crude humor: No. Discrimination/hate: No.
  - Gambling or simulated gambling: **No** (rewarded ads are not loot boxes; nothing
    is bought or won by chance for money).
  - Users interact or exchange content: **No.** The name typed for the aliens stays
    on the device and is never shown to other people.
  - Shares the user's location with other users: **No.**
  - Digital purchases: **No** (no in-app purchases).
  - Unrestricted internet / web browser: **No.** (Tapping an ad opens the browser.
    That isn't an in-app browser feature.)
- Expected result (could not verify the exact mapping): ESRB **Everyone**,
  **PEGI 3 or PEGI 7 ("Fear")**, IARC generic **3+ or 7+**. Redo the questionnaire
  whenever content changes (for example a scarier lineup). PEGI criteria reportedly changed
  with IARC questionnaire v11 in June 2026.

### 5.5 Target audience and content (the important one)
- **Target age groups: tick 13-15, 16-17 and 18+ only. Don't tick any under-13
  group.** This keeps the app out of the Families policy, and `game/docs/PRIVACY.md`
  already says the game isn't directed at under-13s.
- **"Could your store listing unintentionally appeal to children?"** Answer honestly
  after neutralizing the listing (section 4). If cute art remains prominent, "Yes" is
  the defensible answer. Google may then review the app, and can require changes or
  show a **"Not designed for children"** label on the listing.
- If Google decides the app is child-directed, you'll have to either:
  - (a) change the listing art and wording, or
  - (b) add under-13 to the audience and comply with the **Families policy**:
    - a **neutral age screen** (no pre-filled age, no "you must be 13" hint);
    - for kids, ad requests tagged **child-directed** (`tagForChildDirectedTreatment`)
      with **max ad rating G**, and no advertising ID sent;
    - only **Families self-certified ad SDKs** (the Google Mobile Ads SDK is one; the
      program isn't taking new SDKs);
    - a COPPA-style privacy policy;
    - extra review.

  That is real work. Avoid it for v1.
- Either way, set AdMob **max ad content rating to PG** (or G to be safest). Play's
  policy is that ads shown must suit the app's content rating.

### 5.6 Data safety
The game itself sends nothing anywhere (progress, stats and the typed name stay on
the device; "processed only on device" doesn't count as collected). Everything below
comes from the **Google Mobile Ads SDK + UMP**. Google's disclosure page says the SDK
collects and shares this data automatically for advertising, analytics and fraud
prevention, all **encrypted in transit (TLS)**. Before you submit, compare against the
current table at developers.google.com/admob/android/privacy/play-data-disclosure.
That page now covers the "legacy" SDK v25.

| Question | Answer |
|---|---|
| Does your app collect or share any required user data types? | **Yes** |
| Is all user data collected by your app encrypted in transit? | **Yes** |
| Account creation methods | **"My app does not allow users to create an account"** |
| Do you provide a way for users to request deletion? | **No** (no account and no server. Users can reset or delete their advertising ID in Android settings.) |

| Data type (Play category) | Collected | Shared | Optional? | Purposes |
|---|---|---|---|---|
| **Location → Approximate location** (from IP address) | Yes | Yes | Required | Advertising or marketing; Analytics; Fraud prevention, security & compliance |
| **App activity → App interactions** (launches, taps, ad views/clicks) | Yes | Yes | Required | Advertising or marketing; Analytics; Fraud prevention, security & compliance |
| **App info and performance → Diagnostics** (and Crash logs if Google's table lists them) | Yes | Yes | Required | Analytics; Fraud prevention, security & compliance (check whether Google also lists Advertising) |
| **Device or other IDs** (advertising ID, app set ID) | Yes | Yes | Required | Advertising or marketing; Analytics; Fraud prevention, security & compliance |
| Personal info (name, email...), Financial, Health, Messages, Photos/videos, Audio, Files, Calendar, Contacts, Web browsing | **No** | No | | The typed name never leaves the device |

"Required" is right because every phone user gets the ads SDK. Consent only changes
personalization, not whether data is processed. If you ever add analytics, crash
reporting (Firebase etc.) or mediation networks, update this form.

### 5.7 Advertising ID
**"Does your app use advertising ID?" Yes.** Purposes: Advertising or marketing;
Analytics; Fraud prevention, security & compliance. The manifest permission comes
from the SDK.

### 5.8 Other declarations
- Government app: **No**. Financial features: **"My app doesn't provide any financial
  features"**. Health: **no health features**. News app: **No**. COVID: n/a.
- No sensitive permissions (SMS, call log, location, photos, accessibility, exact
  alarm, foreground service, full-screen intent), so none of those forms apply.
- **Age signals (US state laws):** Texas's App Store Accountability Act (SB 2420)
  became enforceable in mid-2026 after the Supreme Court declined to block it. Utah
  and Louisiana dates are disputed. Developer duties as reported:
  - provide an accurate age rating (IARC covers this);
  - tell the store about "significant changes" via **Play Console → Age signals**;
  - never use the age data for ads or analytics.

  Play's **Age Signals API** exists, but for a free game with no accounts and no
  purchases, the extra obligations look minimal. **Could not verify** whether
  integration is expected for apps like this. Re-check before launch, and get legal
  advice if you expand into purchases or accounts.
- **Trader status**: see 2.4.

### 5.9 Store settings
- App or game: **Game**. Free or paid: **Free**. A free app can never become paid
  later; the PC price question doesn't affect this.
- Countries: all, or leave out EEA/UK if you decide against trader disclosure.
- Pricing & distribution: tick the content guideline and US export law declarations.
- Leave "Designed for Families" / Teacher Approved off.

---

## 6. Testing

### 6.1 Tracks

| Track | Who | Review | Use it for |
|---|---|---|---|
| **Internal testing** | Up to 100 testers by email | Available within minutes (lightweight checks) | First upload, Play App Signing setup, checking it installs, pre-launch report |
| **Closed testing** | Email lists or a Google Group, opt-in link | Reviewed (hours to days) | **The required 12-tester / 14-day test** |
| Open testing | Anyone with the link or listing | Reviewed | Locked until production access |
| Production | Everyone in your countries | Reviewed | Launch (use a staged rollout, for example 20% → 100%) |

### 6.2 Running the 12-tester closed test
1. Create a **Google Group** (for example `alien-sudoku-testers@googlegroups.com`) and
   add it as the tester list on the closed track. Testers join the group **and** open
   the opt-in link. Google sends no email, so you share the link yourself. The link
   works only after the closed release is approved.
2. Recruit **15-20** people with Android phones (friends, family, coworkers, a puzzle
   subreddit or Discord). Ask them to install from Play and play a few sessions over
   the two weeks. Paid "12 testers" services exist, but Google looks at engagement.
   Real players give better answers for the application.
3. Track opted-in testers in Play Console. The 14 days must be **continuous**: if the
   count drops below 12, the clock effectively restarts.
4. Ship 1-2 updates during the test (bump versionCode) and keep notes on what changed.

### 6.3 Pre-launch report
Play automatically runs every testing-track upload on real devices (Firebase Test
Lab). It reports crashes, ANRs, accessibility, and security and privacy warnings with
screenshots. Fix crashes; review the accessibility notes (touch target sizes, contrast).

### 6.4 Testing ads safely
- **Never click your own live ads**, even "to test". That's invalid traffic and can
  get the AdMob account disabled.
- Internal and closed builds can keep **Google's test ids** (zero risk, labeled "Test
  Ad"). AdMob can't link to the app until it's public anyway.
- To see your real units on your own phone, add it in **AdMob → Settings → Test
  devices** (up to 250, by advertising ID). Small code option: pass `testingDevices`
  to `AdMob.initialize`.
- Test consent: UMP debug geography (EEA and "regulated US state"). Check the form,
  the "Ad privacy choices" button, and that ads appear only after consent.

### 6.5 Device checklist for this game
- Android 15 and 16 (edge-to-edge, back gesture, banner insets).
- A 16 KB-page emulator image ("16 KB Page Size" system image).
- A tablet or foldable emulator (layout without orientation lock).
- Offline launch (ads fail quietly, game still works).
- Rewarded flows: close early, no fill, success.
- Interstitial after 2 games and at least 3 min.

---

## 7. Submission & review

### 7.1 Order of operations
1. Create app → set up App content (section 5) and store listing (section 4).
2. Upload AAB to **internal testing**. Accept Play App Signing and let Google generate
   the signing key. Your upload key signs future uploads.
3. Promote it to **closed testing**, wait for approval, start the 14-day clock.
4. **Apply for production** (about 7 days).
5. Build the **production release with real AdMob ids** and higher versionCode,
   choose countries, **staged rollout**, submit for review. You can use "Managed
   publishing" to control the exact go-live moment.
6. Once live: **link AdMob to the Play listing**, publish `app-ads.txt`, and wait for
   the app readiness review.

### 7.2 Review times
Google publishes no standard. Updates from established accounts often clear in hours.
For new accounts, expect several days; Google says some accounts get extended
review of "up to seven days or longer in exceptional cases".

### 7.3 AdMob app readiness review
- Add the app in AdMob as "not published" now (to get the app id and unit ids). After
  the Play listing is live, use **App settings → Add app store details** to link it.
- Linking starts the **app readiness review** automatically: app source and policy
  compliance, usually **2-3 days**, sometimes longer. Until it passes, and until
  **app-ads.txt is verified**, the app has **limited ad serving**. Apps added after
  January 2025 that aren't verified face limited serving.
- New ad units can take up to an hour to start serving.

### 7.4 Common rejection and suspension reasons for ad-supported games (and this game's exposure)

| Reason | Exposure |
|---|---|
| Ads too close to buttons ("layout encourages accidental clicks") | **Banner under the keypad during play.** Fix with spacing or by hiding it. |
| Unexpected interstitials (on launch, on exit, during play, every action) | Low: shown at a natural break, capped |
| Full-screen ads that can't be closed after 15 s | Handled by the SDK. Don't add your own blocking overlays. |
| Rewarded ads not opt-in, reward unclear, or reward for clicks/installs | Low: the "Watch video" button is clear and optional |
| Ads not matching the content rating | Set max ad content rating PG/G |
| Target audience mismatch / child appeal | **Medium**: cute aliens. Neutral listing. |
| Data safety form doesn't match SDK behavior | Use the table above. Re-check Google's SDK table. |
| No in-app privacy policy link | **Currently missing.** Add it to Settings. |
| Metadata policy (ranking claims, keyword stuffing, misleading screenshots) | Low with current drafts |
| Advertising ID declaration vs manifest mismatch | Low (SDK merges AD_ID; answer Yes) |
| Broken functionality, crashes in pre-launch report | Test on Android 15/16 |
| Intellectual property (unlicensed images/fonts/music) | **Verify NASA/ESA photo licenses.** Fonts are OFL (OK). |
| Minimum functionality / "webview wrapper" spam | Low: full offline game bundled in the app |
| Closed test application refused (low engagement, too few testers) | Medium: plan recruitment |

---

## 8. After launch

- **Android vitals**: watch the user-perceived crash rate (bad behavior threshold
  1.09% overall, 8% per phone model), ANR rate, and, **from Feb 2027**, the new memory
  and bitmap thresholds and the DEX optimization score (shown per uploaded bundle).
- **AdMob**:
  - Check Policy center and the app-ads.txt tab weekly at first.
  - Enter the PIN when it arrives.
  - Add tax info.
  - Optionally add an interstitial frequency cap in the ad unit settings as a second
    safety net.
  - Watch for "limited ad serving" notices.
- **Deadlines to calendar**:
  - **1 Feb 2027**: trader status declared (verify). Updates must support 16 KB pages.
  - **Feb 2027**: memory and DEX optimization thresholds (R8 enabled).
  - **30 Jun 2027**: GMA legacy SDK v25 deprecated. Update the Capacitor AdMob plugin
    or migrate to the Next-Gen SDK. **Sunset 30 Jun 2028** (ads may stop).
  - **~Aug 2027**: probably target API 37 for updates (watch the Play announcement).
    Android 17 target removes the temporary large-screen opt-out.
  - **2027**: Android developer verification goes global. It's automatic for Play,
    but register any extra keys if you ship APKs elsewhere.
- **Updates**: every upload needs a higher versionCode. Keep the upload key and its
  passwords in a password manager plus an offline backup. If it's lost, request an
  upload key reset in Play Console (takes days).
- **Policy emails**: respond within the deadline. Most issues can be fixed with an
  update plus an appeal.
- **Reviews**: reply to Play reviews. They feed ratings and featuring.

---

## 9. Other Android stores (brief)

| Store | Status (Nov 2026) | Worth it for Alien Sudoku? |
|---|---|---|
| **Amazon Appstore** | **Shut down on Android phones and non-Amazon tablets on 20 Aug 2025.** New submissions for Android mobile devices stopped 20 Feb 2025. Still runs on **Fire tablets and Fire TV** (Fire OS; Vega OS on new Fire TV). | **Skip for now.** Fire tablets have no Google Play services, so AdMob fill and consent behavior on Fire OS are uncertain (could not verify). It would need its own ad setup to earn anything. |
| **Samsung Galaxy Store** | Active. Registration free. You need a Samsung account, Seller Portal, and **commercial seller status (required even for free apps)**. You can import listing data from Play. Official review target is 2-5 business days; forum reports describe much longer waits. A **participating store for Android developer verification**. | **Optional, low effort later.** Samsung phones have Google Play services, so AdMob works. Upload the **Play-signed universal APK** from App bundle explorer, or register your own signing key in Play Console's developer verification page. Add the Galaxy Store app ID in AdMob too, for app-ads.txt/readiness (AdMob mainly supports Play/App Store linking; verify). |
| **Huawei AppGallery** | Active. Registration free, ID check for individuals (1-2 days). Huawei phones sold since 2019-2020 have **no Google Play services**, so the AdMob/UMP stack won't serve properly. **HUAWEI Ads does not accept individual accounts.** | **Skip.** No working ad revenue path for an individual. |
| Xiaomi GetApps, OPPO, vivo, HONOR, Transsion | Active, regional | Skip for v1 |

---

## 10. Sources

| URL | What it confirmed |
|---|---|
| https://developer.android.com/google/play/requirements/target-sdk | From 31 Aug 2026, new apps/updates must target API 36. Existing apps need 35+. Extension to 1 Nov 2026. |
| https://developer.android.com/developer-verification | Developer verification timeline: 30 Sep 2026 in BR/ID/SG/TH, global 2027. Limited distribution accounts (20 devices, no fee). |
| https://developer.android.com/developer-verification/guides | Participating stores list (Google Play, Galaxy Store, Xiaomi, OPPO, vivo, HONOR, Transsion). Full vs limited distribution. |
| https://developer.android.com/developer-verification/guides/google-play-console | Play identity counts. New apps auto-register the package name at creation. 99% auto-registered. |
| https://developer.android.com/developer-verification/guides/faq | $25 fee parity with Play. ADB installs exempt. D-U-N-S up to 28 days. Lost key = can't register. Play App Signing apps auto-claimed. |
| https://developer.android.com/guide/practices/page-sizes | 16 KB requirement for apps targeting 35+. Updates blocked from 1 Feb 2027. No native code = already compatible. AGP 8.5.1+. |
| https://developer.android.com/guide/app-bundle | AAB required for new apps since Aug 2021. 4 GB compressed download limit. |
| https://developer.android.com/studio/publish/app-signing | Play App Signing required for new apps. Upload key vs app signing key. Validity 25+ years, past 22 Oct 2033. Upload key reset. |
| https://developer.android.com/about/versions/16/behavior-changes-16 | Edge-to-edge opt-out disabled. Predictive back default. Large-screen orientation override with a games exemption via `android:appCategory`. |
| https://developer.android.com/blog/posts/elevating-app-quality-reducing-memory-usage-and-improving-device-migration | Feb 2027 memory/bitmap/DEX thresholds. At least 25% R8 optimization coverage. Zero-tap sign-in April 2027 (games exempt). |
| https://support.google.com/googleplay/android-developer/answer/14151465 (via search) | 12 testers, 14 days continuous, personal accounts after 13 Nov 2023. Production application about 7 days. Open testing after production access. |
| https://support.google.com/googleplay/android-developer/answer/14316361 (via search) | Android device verification with the Play Console app on a physical Android 10+ phone |
| https://support.google.com/googleplay/android-developer/answer/13628312 and /14177239 (via search) | Personal account information. Email/phone one-time-code verification. What's shown publicly. |
| https://support.google.com/googleplay/android-developer/answer/10144311 (via search) | Privacy policy required for all apps, in Play Console and inside the app. Non-PDF, public URL. |
| https://support.google.com/googleplay/android-developer/answer/9867159 and /9893335 (via search) | Target audience declaration. Unintended appeal to children. Families policy. Neutral age screen. Self-certified ads SDKs. |
| https://support.google.com/admob/answer/6223431 (via search) | AdMob behavior for Families apps. Child-directed tagging. Mediation limits. |
| https://support.google.com/googleplay/android-developer/answer/9859455 (via search) | Ads declaration and "Contains ads" label |
| https://support.google.com/googleplay/android-developer/answer/12271244 (via search) | Unexpected full-screen ads, 15-second rule, natural breaks allowed |
| https://support.google.com/admob/answer/6201362 (via search) | Interstitial guidance: not after every action, not on launch, not during play |
| https://support.google.com/admob/answer/7562142 (via search) | Max ad content rating G/PG/T/MA and the mapping to Play 3+/7+/12+/16+ |
| https://developers.google.com/admob/android/privacy/play-data-disclosure (via search) | GMA SDK collects and shares IP/approximate location, interactions, diagnostics and device IDs. Encrypted in transit. Page is for the legacy SDK v25.5. |
| https://developers.google.com/admob/android/deprecation and https://developers.google.com/ads/blog/posts/2026/07/announcing-google-mobile-ads-next-gen (via search) | Legacy SDK v24/v25: deprecated 30 Jun 2027, sunset 30 Jun 2028. Next-Gen SDK preferred. |
| https://developers.google.com/admob/android/rel-notes (via search) | GMA 25.5.0 (17 Sep 2026) raises minSdk to 24 |
| https://support.google.com/admob/answer/15948559 (via search) | App readiness review. Limited ad serving for unverified apps added after Jan 2025. |
| https://support.google.com/admob/answer/9363762 and /9679128 (via search) | app-ads.txt: developer website must be in the store listing. Crawled at the root of the host. |
| AdMob help (account/app review pages, via search) | Account review up to 24 h (rarely 2 weeks). Payment details needed. App review 2-3 days. One account per publisher. |
| AdMob payments help (via search) | Paid around the 21st. $100 threshold example. PIN by mail (~3 weeks, 4 months to enter). Tax info by the 20th. |
| https://support.google.com/admob/answer/3342099 and /9691433, https://developers.google.com/admob/android/test-ads (via search) | Invalid traffic. Don't click own ads. Test devices (up to 250). Test ad labels. |
| https://developers.google.com/admob/android/privacy/us-states (via search) | UMP US-states messages. Debug geography for testing. |
| https://support.google.com/googleplay/android-developer/answer/16569691 (via search) plus InfoLawGroup / Hintze Law posts (July 2026) | Play Age Signals API. Texas SB 2420 enforceable after the 6 Jul 2026 Supreme Court order. Developer duties. |
| testerscommunity.com, fdaytalk.com, baijing.cn (third-party, Nov 2026) | Trader status declaration: deadline 1 Feb 2027, public details from 1 Mar 2027. **Not confirmed on a Google page.** |
| androidauthority.com, techtimes.com (2025) | Amazon Appstore on Android discontinued 20 Aug 2025, submissions ended 20 Feb 2025. Fire devices continue. |
| https://developer.samsung.com/galaxy-store/how-to-distribute.html and Samsung forums (via search) | Commercial seller status needed even for free apps. 2-5 business day review target. |
| developer.huawei.com, capgo.app (via search) | AppGallery free registration. HUAWEI Ads not open to individuals. |

**Could not verify (check in the consoles):**
- the exact IARC question wording and the resulting rating;
- whether Google's current GMA data-disclosure table lists Crash logs and an
  "Advertising" purpose for diagnostics;
- exact tablet and Chromebook screenshot minimums;
- the trader-status rules on a Google page;
- whether the 12-tester rule exempts organization accounts (reported, not confirmed);
- AdMob fill on Fire OS;
- whether Play Age Signals integration is expected for no-account, no-purchase games;
- the next target-API deadline (2027).
