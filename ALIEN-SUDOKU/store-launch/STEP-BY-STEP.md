# Alien Sudoku: step by step to Google Play and the App Store

Your path: **personal accounts**, an **Android phone** and an **iPhone**, **no Mac**
(the iOS app is built on a cloud Mac), and a **new Gmail** for player support.

Do the steps in order. Each one says what you need, where to click, what to type,
and what to send Claude when you're done. Google Play and Apple can run side by side
after step 1. Menu names in Play Console and App Store Connect sometimes shift a
little; look for the closest match.

Claude has already prepared:

- the signed Android upload file (`.aab`) and an installable `.apk` at version 1.2.0;
- the Android upload key (sent to you; keep it safe, see G3);
- the cloud iOS build (`codemagic.yaml` in the repository) that signs and uploads to TestFlight;
- the website pages: home, privacy policy and support;
- store text, screenshots for every size, and all graphics (`store-launch/listing`, `store-launch/assets`).

| | Google Play | App Store |
|---|---|---|
| Cost | $25 once | $99 a year |
| Waiting | ID check (a few days), then a **14-day test with 12+ testers**, then review (up to ~7 days) | Enrollment check (1-2 days), then review (usually under 48 hours) |
| Realistic time to live | 3-4 weeks | 1-2 weeks |

---

## Step 1 (both stores): the support Gmail

1. On your phone or computer, create a new Google account, for example
   `aliensudoku.help@gmail.com` (any free name works).
2. Turn on **2-Step Verification**: myaccount.google.com → Security → 2-Step Verification.
3. This address is shown publicly on both stores and in the privacy policy.

**Send Claude:** the new email address. Claude puts it in the game, the privacy
policy, the support page and the store text, then publishes the website.

> Use your **main** Google account (not the new Gmail) to sign up for Play Console
> and AdMob. That account owns the money and the apps; the new Gmail is only for players.

---

# Google Play

### G1. Create your Play Console developer account

You need: your Android phone, a government ID, a card in your name, $25.

1. Go to **play.google.com/console/signup** and sign in with your main Google account.
2. Choose **Yourself** (personal account).
3. Developer name: **Eddie G** (public). Legal name and address: your real ones (private).
4. Contact email and phone: verify both with the codes they send.
5. Developer email (public): the new support Gmail from step 1.
6. Pay the $25 fee.
7. **Verify your identity**: upload a photo of your ID when asked. Approval takes a few days.
8. **Verify your Android phone**: install the **Google Play Console** app from the Play
   Store on your phone, sign in with the same account, and tap **Verify** when asked.

**Send Claude:** "G1 done" (or "waiting on ID check"). You can carry on with G2.

### G2. Create the app (this also reserves the name `com.eddieg.aliensudoku`)

1. Play Console → **Create app**.
2. App name: **Alien Sudoku** · Default language: **English (United States)**
   · App or game: **Game** · Free or paid: **Free**.
3. Tick the declarations (Developer Program Policies, US export laws) → **Create app**.

### G3. Upload the first build to internal testing (try it on your phone)

You need: `AlienSudoku-1.2.0-play.aab` (Claude sent it to you).

1. In your app: **Test and release → Testing → Internal testing → Create new release**.
2. If asked about app signing, choose **Use Google-generated key** (Play App Signing; the default).
3. Upload `AlienSudoku-1.2.0-play.aab`. Release name: `1.2.0`.
   Release notes: `First internal test.`
4. **Save → Review release → Start rollout to Internal testing**.
5. Tab **Testers**: create an email list with your own Google account → **Save**.
   Copy the **join link**, open it on your Android phone, accept, and install from Play.

Keep the upload key safe: `alien-sudoku-upload.jks` plus `alien-sudoku-upload-key.txt`
(its password). Save both in a password manager or private cloud folder. Every future
update must be signed with it. If it's ever lost, Play support can reset it.

**Send Claude:** anything that looks wrong on your phone.

### G4. App content forms (Policy and programs → App content)

Fill in each card with these answers:

| Form | Answer |
|---|---|
| **Privacy policy** | `https://namastegeitz.github.io/Eddie-G/alien-sudoku/privacy.html` |
| **App access** | All functionality is available without special access |
| **Ads** | Yes, my app contains ads |
| **Content rating** | Email: the support Gmail · Category: **Game**. Violence: No. Scary content: **Yes, mild/cartoon (non-realistic monsters)**. Sexual content, language, drugs, crude humor, hate: No. Gambling or simulated gambling: No. Users interact or share content: No. Shares location: No. Digital purchases: No. Unrestricted web: No. |
| **Target audience** | Tick **13-15, 16-17 and 18+** only (no under-13 group). "Could the listing unintentionally appeal to children?" → **Yes** (cute cartoon art); accept the "Not designed for children" label if offered |
| **Data safety** | Collects or shares data: **Yes**. Encrypted in transit: **Yes**. Account creation: **My app does not allow users to create an account**. Deletion request: **No**. Data types, all **collected and shared**, **required**, purposes **Advertising or marketing, Analytics, Fraud prevention/security**: Approximate location · App interactions · Diagnostics (+ Crash logs) · Device or other IDs. Nothing else. |
| **Advertising ID** | Yes. Purposes: Advertising or marketing, Analytics, Fraud prevention/security |
| **Government / financial / health / news apps** | No / No financial features / No health features / No |

Why "collected and shared": the game itself sends nothing, but Google's ad SDK does.

### G5. Main store listing (Grow users → Store presence → Main store listing)

All text is in `store-launch/listing/listing.md` (copy-paste). Graphics in `store-launch/assets`:

| Field | Use |
|---|---|
| App name | Alien Sudoku |
| Short description | from listing.md (80 characters max) |
| Full description | from listing.md + the "ads line" at the end |
| App icon | `assets/graphics/google-icon-512x512.png` |
| Feature graphic | `assets/graphics/google-feature-graphic-1024x500.jpg` |
| Phone screenshots | the 7 files in `assets/screenshots/google-phone/` |
| 10-inch tablet screenshots | the 7 files in `assets/screenshots/google-tablet-10in/` |
| Category | Game → **Puzzle** |
| Contact email | the support Gmail |
| Website | `https://namastegeitz.github.io/Eddie-G/alien-sudoku/` |

### G6. AdMob (the ads that pay you)

You need: your main Google account, payment details (for verification).

1. Go to **admob.google.com** → sign up as an **Individual** (can't change later).
2. **Apps → Add app → Android →** "Is the app listed on a supported app store?" **No**
   → name **Alien Sudoku** → **Add**.
3. Create three ad units in that app: **Banner**, **Interstitial**, **Rewarded**
   (names: `Alien Sudoku banner`, `... interstitial`, `... rewarded`). Defaults are fine.
4. **Privacy & messaging → GDPR → Create message** (pick the app, default options, publish);
   then **US states regulations message** the same way.
5. **Blocking controls → Content → Maximum ad content rating: PG** (or G).

**Send Claude:** the Android **App ID** (`ca-app-pub-…~…`) and the three **ad unit IDs**
(`ca-app-pub-…/…`). Claude builds 1.2.1 with your real ads and sends the new `.aab`.
These IDs aren't secret, but don't tap your own live ads.

### G7. The 14-day closed test (required for new personal accounts)

You need: **12 or more testers** with Android phones who stay opted in for **14 days**.

1. Create a Google Group (groups.google.com), e.g. `alien-sudoku-testers`, and invite
   friends and family (ask 15-20; some drop out).
2. **Testing → Closed testing → Create track** (or use **Alpha**) → **Testers**: add the
   Google Group email → copy the join link and send it to them.
3. **Create new release** with the latest `.aab` from Claude → roll out.
   Countries: all.
4. Ask testers to play a few times over the two weeks. Collect feedback; Claude can ship
   an update mid-test (Google likes to see that).

**Send Claude:** tester feedback any time; "day 14 reached" when done.

### G8. Production

1. **Dashboard → Apply for production**. Answer the three parts (Claude can draft
   them from your test notes). Review usually takes 7 days or less.
2. When approved: **Production → Create new release** with the latest `.aab` →
   countries → **Send for review**.
3. **EU trader status** (Play Console asks, due 1 Feb 2027): an ad-supported app counts
   as trading. Declaring **trader** shows a contact address and phone to EU/UK users, so
   use a PO box or a separate number if you want privacy. The other option is to leave
   EU/UK countries out.

### G9. After it's live

1. AdMob → your app → **App settings → Link to app store** → pick the Play listing.
2. **app-ads.txt**: AdMob checks `https://namastegeitz.github.io/app-ads.txt`. Claude
   can set that up once you send your AdMob publisher ID (`pub-…`). It needs a small
   extra repository named `namastegeitz.github.io`.

---

# App Store (iPhone and iPad)

### A1. Join the Apple Developer Program (individual)

You need: your iPhone, your Apple Account with two-factor authentication, a card in your name, $99.

1. On your iPhone install the **Apple Developer** app (App Store) → sign in.
2. **Account → Enroll now** → **Individual**. Use your **legal name** (Apple shows it as
   the seller on the App Store) and real address.
3. Verify with your ID when the app asks, then pay $99 (auto-renews yearly).
4. Wait for the welcome email (usually within 48 hours).
5. Find your **Team ID**: developer.apple.com/account → **Membership details**.

**Send Claude:** "A1 done" (the Team ID isn't needed with the cloud build).

### A2. Register the app's ID

1. developer.apple.com/account → **Certificates, Identifiers & Profiles → Identifiers → +**.
2. **App IDs → App** → Description: `Alien Sudoku` → **Explicit** Bundle ID:
   `com.eddieg.aliensudoku` → no extra capabilities → **Register**.

### A3. Create the app in App Store Connect

1. appstoreconnect.apple.com → **Apps → + → New App**.
2. Platform **iOS** · Name **Alien Sudoku** · Primary language **English (U.S.)** ·
   Bundle ID **com.eddieg.aliensudoku** · SKU `alien-sudoku-ios` · User access **Full**.

### A4. Create the App Store Connect API key (lets the cloud Mac sign and upload)

1. App Store Connect → **Users and Access → Integrations → App Store Connect API →
   Team Keys → +** (request access first if asked).
2. Name `Codemagic`, Access **Admin** (needed for cloud signing) → **Generate**.
3. **Download the `.p8` file** (only possible once). Note the **Key ID** and the **Issuer ID**
   shown above the list.

Keep the `.p8` private: never send it in chat or put it in the repository.

### A5. Build the iOS app on a cloud Mac (Codemagic)

1. Go to **codemagic.io** → **Sign up with GitHub** → personal account.
2. **Add application** → GitHub → **Namastegeitz/Eddie-G** → project type **Other**
   (it then uses the `codemagic.yaml` Claude added).
3. **Team settings → Integrations → Developer Portal → Connect**: name it exactly
   `Alien Sudoku ASC key`, enter the Issuer ID and Key ID, upload the `.p8` → Save.
4. Open the app → **Start new build** → branch `claude/peaceful-carson-qmcyku` →
   workflow **Alien Sudoku iOS (TestFlight)** → **Start**. It takes about 15 minutes.
5. When it turns green, the build appears in App Store Connect → **TestFlight** after a few
   minutes of processing.

Free plan: 500 Mac minutes a month (about 30 builds).

**Send Claude:** "A5 green", or the error text if it fails (Claude fixes it).

### A6. Test on your iPhone (TestFlight)

1. App Store Connect → **TestFlight → Internal Testing → +** group `Me` → add yourself.
2. Install the **TestFlight** app on your iPhone, accept the invite, install Alien Sudoku.
3. Check: the tracking question shows on first launch, ads never cover the board,
   music plays, Settings links work, and iPad if you have one.

### A7. AdMob for iOS

1. AdMob → **Apps → Add app → iOS** → not listed yet → **Alien Sudoku**.
2. Three ad units again: Banner, Interstitial, Rewarded.
3. Add the iOS app to the GDPR and US states messages from G6 (edit each message → apps).

**Send Claude:** the iOS App ID and the three iOS ad unit IDs. Claude turns them on for
the cloud build, and you start one more Codemagic build.

### A8. Fill in the App Store page (App Store Connect → your app)

| Where | What |
|---|---|
| **App Information** | Subtitle, category **Games → Puzzle** (secondary **Board**), from listing.md. Content Rights: **contains third-party content: Yes**, you have the rights |
| **Age Rating** | Advertising **Yes** · Horror/Fear Themes **Infrequent/Mild** · everything else **No/None** · **don't** choose Made for Kids → result **9+** |
| **App Privacy** | Data collected: **Yes**. Coarse Location, Device ID, Product Interaction, Advertising Data → purposes **Third-Party Advertising, Analytics** → linked: **Yes** → used for tracking: **Yes**. Crash Data, Performance Data, Other Diagnostic Data → **Analytics**, not linked, not tracking. Privacy Policy URL: `https://namastegeitz.github.io/Eddie-G/alien-sudoku/privacy.html` |
| **Pricing and Availability** | Free · all countries **except China mainland and Vietnam** · turn **off** "available on Apple Silicon Mac" |
| **Version 1.2 page** | Promotional text, description, keywords (listing.md) · Support URL `https://namastegeitz.github.io/Eddie-G/alien-sudoku/support.html` · Marketing URL: leave empty · Screenshots: `assets/screenshots/apple-iphone-6.9in/` (7) and `assets/screenshots/apple-ipad-13in/` (7) · Copyright `© 2026 Eddie G` · pick the TestFlight build |
| **App Review Information** | Sign-in required: **No**. Notes: the text below |
| **Accessibility** | Leave all unclaimed (or only what you tested) and save |
| **Digital Services Act** | **Trader** (ad-supported); verify email, phone and an address document (PO box allowed) |

App Review notes (copy-paste):

> Alien Sudoku is an offline Sudoku game that uses alien glyph symbols. No account or login;
> all progress is stored on the device. Ads: Google AdMob banner, an interstitial between
> finished games (never in the first 3 minutes, at most every 2 games), and optional rewarded
> videos for an extra hint or a second chance. On first launch the Google consent message
> appears where required, then the App Tracking Transparency prompt. Settings has the
> privacy policy, Ad privacy choices and Report an ad. Not designed for children; rated 9+
> for mild cartoon monster imagery.

### A9. Submit

1. Version page → **Add for Review → Submit**. Choose **Manually release this version**.
2. Most reviews finish within 48 hours. If it's rejected, copy the message to Claude.
3. Approved → **Release this version**.
4. AdMob → iOS app → **Link to app store**.

---

## What only you can do, and what Claude does

| You | Claude |
|---|---|
| Accounts, payments, ID checks, agreements | Builds, signing setup, version numbers |
| Creating the app records and API key | Store text, screenshots, graphics |
| Testers and their feedback | Fixes and updates from feedback |
| Pressing Submit and Release | Answers for every form (this file), review replies |
