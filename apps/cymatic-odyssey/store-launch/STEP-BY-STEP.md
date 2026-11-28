# Cymatic Light Chamber: step by step to your phone, Google Play and the App Store

Your path (same as Alien Sudoku): **personal accounts**, an **Android phone** and an **iPhone**, **no Mac**
(the iOS app is built on a cloud Mac). If you already created an account in a step for Alien Sudoku,
skip that part: the accounts, the Codemagic sign-in and the App Store Connect API key are shared by all your apps.

Claude has already prepared:

- the **web app, live** at https://namastegeitz.github.io/Eddie-G/cymatic-light-chamber/ (works on any phone, tablet or computer, installs to the home screen, works offline);
- the signed Android upload file `CymaticLightChamber-1.0.0-play.aab` and an installable `CymaticLightChamber-1.0.0.apk` (sent to you; the APK is also on the website);
- the Android upload key `cymatic-light-chamber-upload.jks` and its passwords (sent to you; **keep them safe**, see G3);
- the cloud iOS build (`codemagic.yaml` at the repository root) that signs and uploads to TestFlight;
- the privacy policy and support pages (on the website), store text (`LISTING.md`), screenshots and graphics.

| | Google Play | App Store |
|---|---|---|
| Cost | $25 once (skip if you already paid for Alien Sudoku) | $99 a year (one membership covers all your apps) |
| Waiting | a **14-day closed test with 12+ testers** for new personal accounts, then review (up to ~7 days) | review, usually under 48 hours |
| Realistic time to live | 3-4 weeks | 1-2 weeks |

---

## Today: on your phones (no store needed)

- **iPhone / iPad:** open the website link in **Safari** → Share → **Add to Home Screen**.
- **Android:** open the link in Chrome → menu → **Install app**. Or install the real Android app: open the APK link on the site's *Share* page (or the APK file Claude sent), and allow Chrome to install apps when Android asks.
- **Other people:** send them the link. It opens on any phone, tablet or computer with nothing to download.

Note: if you sideload the APK and later install from Google Play, uninstall the sideloaded one first (Play signs its copy with Google's key).

---

# Google Play

### G1. Developer account
Skip if you have one from Alien Sudoku. Otherwise: https://play.google.com/console → personal account → pay $25 → ID check.

### G2. Create the app (reserves `com.eddieg.cymaticlightchamber`)
1. Play Console → **Create app**.
2. App name **Cymatic Light Chamber** · Default language **English (United States)** · **App** (not game) · **Free**.
3. Tick the declarations → **Create app**.

### G3. Upload the first build to internal testing
You need `CymaticLightChamber-1.0.0-play.aab`.
1. **Test and release → Testing → Internal testing → Create new release**.
2. App signing: choose **Use Google-generated key** (Play App Signing, the default).
3. Upload the `.aab`. Release name `1.0.0`. Notes: `First internal test.`
4. **Save → Review release → Start rollout to Internal testing**.
5. **Testers** tab: an email list with your own Google account → copy the join link → open it on your Android phone → install from Play.

Keep the upload key safe: `cymatic-light-chamber-upload.jks` plus `cymatic-light-chamber-upload-key.txt`
(its passwords), in a password manager or private cloud folder. Every future update is signed with it.
If it's ever lost, Play support can reset it.

### G4. App content forms (Policy and programs → App content)
Use the answers in `LISTING.md` → *Google Play: Data safety* and *other App content answers*
(privacy policy URL, no ads, full access, content rating, target audience 13+, no health features).

### G5. Main store listing (Grow users → Store presence → Main store listing)
Paste name, short and full description from `LISTING.md`; upload the 512 icon, the 1024 × 500 feature graphic
and the five `google-phone` screenshots. Category **Entertainment**, contact email (your support Gmail), website URL.

### G6. Closed test: 12 testers for 14 days (required for new personal accounts)
**Testing → Closed testing → Create track** → same `.aab` → add 12 or more testers (friends' Google accounts)
→ they join and keep it installed for 14 days. Then **Apply for production** on the Dashboard.

### G7. Production
**Production → Create new release** → add the same build from the library → countries → **Start rollout**.

---

# App Store (iPhone and iPad)

### A1. Apple Developer Program
Skip if you joined for Alien Sudoku. Otherwise https://developer.apple.com/programs/enroll/ (individual, $99/year).

### A2. Register the app's ID
https://developer.apple.com/account/resources/identifiers → **+** → App IDs → App →
Description `Cymatic Light Chamber`, Bundle ID **Explicit** `com.eddieg.cymaticlightchamber` → no extra capabilities → Register.

### A3. Create the app in App Store Connect
https://appstoreconnect.apple.com → Apps → **+ New App** → iOS · Name **Cymatic Light Chamber** ·
English (U.S.) · Bundle ID `com.eddieg.cymaticlightchamber` · SKU `cymatic-light-chamber` · Full access.

### A4. App Store Connect API key
Skip if Codemagic already has the key you made for Alien Sudoku. Otherwise: Users and Access → Integrations →
App Store Connect API → **+** → name `Codemagic`, access **Admin** → download the `.p8` (only possible once),
note the Issuer ID and Key ID → Codemagic → Team settings → Integrations → Developer Portal → add it and name it
exactly **Alien Sudoku ASC key** (the name `codemagic.yaml` uses; one key serves all your apps).

### A5. Build on a cloud Mac (Codemagic)
1. https://codemagic.io → sign in with GitHub → make sure the **Eddie-G** repository is added.
2. Start a new build: branch **`claude/peaceful-babbage-k8oen2`**, workflow **Cymatic Light Chamber iOS (TestFlight)**.
3. About 10-15 minutes later the build is in App Store Connect → TestFlight.

### A6. Test on your iPhone (TestFlight)
Install **TestFlight** from the App Store → App Store Connect → TestFlight → Internal testing → add yourself → install.
Check: Start audio plays (phone not on silent), a style and a show set up in the console, FADE ALL fades out.

### A7. The App Store page
App Store Connect → your app → version 1.0:
- screenshots: `apple-iphone-6.9in` (5) and `apple-ipad-13in` (5);
- subtitle, description, keywords, support and marketing URLs from `LISTING.md`;
- **App Privacy** → Data Not Collected; privacy policy URL;
- **Age rating** → all None → 4+;
- category Entertainment / Music; price Free;
- **App Review Information** → paste the review notes from `LISTING.md`, no sign-in needed.

### A8. Submit
Pick the TestFlight build → **Add for Review → Submit**.

---

## What only you can do, and what Claude does

| You | Claude |
|---|---|
| Accounts, payments, ID checks, agreements | Builds, signing setup, version numbers |
| Creating the app records and the API key | Store text, screenshots, graphics |
| Testers and their feedback | Fixes and updates from feedback |
| Pressing Submit and Release | Answers for every form (this file and `LISTING.md`), review replies |

**Send Claude:** anything that looks wrong on your phone, any rejection message from Apple or Google, and which support email you want on the listing.
