# **BUG'S-EYE VIEW**

Everything needed to take Bug's-Eye View from a finished game to live store pages - builds, store images, listing text, legal pages, research and a step-by-step checklist.

**Progress: 12 of 55 steps done (22%)**  

`███████░░░░░░░░░░░░░░░░░░░░░░░`

- **Live checklist (tick steps, leave notes, report bugs):** https://claude.ai/artifact/MKiRiENoEXksyyoVYmNkxw
- **Play the web build:** https://claude.ai/artifact/Gmpx6M1Qb9WmCn1BY1Qbh4
- Last synced from the live checklist: 17 Nov 2026

> The live checklist is the real-time version: tick a step there and it turns green on every device. This README is a snapshot Claude refreshes from it with each update (✅ done, ⬜ to do).

## What's in this folder

| Folder | What it holds |
|---|---|
| [Builds/](Builds/) | One folder per platform: Windows, macOS, Linux, Web, Android, iOS - each with the build and a README |
| [Store Assets/](Store%20Assets/) | Icons, key art, logo, screenshots and every store's image sizes, rendered from the game |
| [Store pages/](Store%20pages/) | One folder per store: what to upload where, in order |
| [Listing Text/](Listing%20Text/) | Names, descriptions, keywords and system requirements, checked against each store's limits |
| [Legal/](Legal/) | Privacy policy and the answers for every store's privacy, data and age-rating forms |
| [Research/](Research/) | What each store requires, how long it takes and what it costs (researched 17 Nov 2026) |
| [Checklist/](Checklist/) | The checklist's source (steps.json), its status and the live page |
| [Make Desktop Folder.bat](Make%20Desktop%20Folder.bat) | Copies this whole folder to your Windows Desktop |

## How the feedback loop works

1. **Play** a build from `Builds/` (or the web link above).
2. **Report** anything odd in the live checklist's *Feedback & bugs* tab: where you were, what happened, what you expected. Minor things count.
3. **Ask Claude to "check the tracker".** Claude reads every report and your step notes, fixes what it can, replies on each report and marks it *Fixing* or *Fixed*.
4. **Tick steps** as you finish them. The *Next up* card always shows the next step whose earlier steps are done, with how-to and tips.

## The checklist

### ✅ Phase 0 - Groundwork  (12/12)

_Everything that could be done in the cloud before you touch a store account._

- ✅ **Lighter bugs can push the potted plants**  
  <sub>Claude - done 2026-11-17</sub>
- ✅ **Release folder BUG'S-EYE VIEW made**  
  <sub>Claude - done 2026-11-17</sub>
  - 📁 [BUG'S-EYE VIEW](.)
- ✅ **Store requirements researched (Apple, Google Play, Steam, GOG, itch.io, Epic, Microsoft)**  
  <sub>Claude - done 2026-11-17</sub>
  - 📁 [Research/](Research/)
- ✅ **Machine audit: what the build computer has and lacks**  
  <sub>Claude - done 2026-11-17</sub>
- ✅ **Android build targets API 36 (Google Play's rule since 31 Aug 2026)**  
  <sub>Claude - done 2026-11-17</sub>
- ✅ **Store listing text written, checked against every length limit**  
  <sub>Claude - done 2026-11-17</sub>
  - 📁 [Listing Text/store-listing.md](Listing%20Text/store-listing.md)
- ✅ **Privacy policy drafted (the game collects no data)**  
  <sub>Claude - done 2026-11-17</sub>
  - 📁 [Legal/privacy-policy.md](Legal/privacy-policy.md)
- ✅ **Answers for the stores' privacy, data and age-rating forms**  
  <sub>Claude - done 2026-11-17</sub>
  - 📁 [Legal/store-questionnaire-answers.md](Legal/store-questionnaire-answers.md)
- ✅ **Store art rendered from the real game**  
  <sub>Claude - done 2026-11-17</sub>
  - 📁 [Store Assets/](Store%20Assets/)
- ✅ **Privacy & about section inside the game**  
  <sub>Claude - done 2026-11-17</sub>
- ✅ **Every build in its own folder**  
  <sub>Claude - done 2026-11-17</sub>
  - 📁 [Builds/](Builds/)
- ✅ **This live checklist and the feedback collector**  
  <sub>Claude - done 2026-11-17</sub>

### ⬜ Phase 1 - Your decisions and setup  (0/7)

_A few choices only you can make. Each one unblocks several stores._

- ⬜ **Put the BUG'S-EYE VIEW folder on your Desktop**  
  <sub>You · 5 min · Free</sub>
  1. Pull the latest code from GitHub (or download the repo as a zip).
  2. Open apps/bugs-eye-view/BUG'S-EYE VIEW and double-click "Make Desktop Folder.bat".
  3. A BUG'S-EYE VIEW folder appears on your Desktop with everything in it. Run it again after each update.
  > **Tip:** Windows may ask before running a .bat from the internet: choose More info > Run anyway, or right-click the file > Properties > Unblock.
  - 📁 [Make Desktop Folder.bat](Make%20Desktop%20Folder.bat)
  > **Claude:** The folder is on GitHub on branch claude/nifty-lamport-bfm2ub. On GitHub switch to that branch, choose Code > Download ZIP, unzip it, then run 'Make Desktop Folder.bat' inside apps/bugs-eye-view/BUG'S-EYE VIEW.
- ⬜ **Decide who sells the game: you personally, or a company**  
  <sub>You · 15 min to decide · Free (a company costs money to set up)</sub>
  1. As an individual, Apple shows your legal name as the seller and Google shows your developer name. That's normal for solo developers.
  2. A company (an LLC, for example) lets stores show "Aethertek", but Apple then needs a D-U-N-S number and Microsoft needs a Company account.
  3. Microsoft's Individual account is meant for non-commercial apps: if you plan to sell there, choose Company.
  > **Tip:** If you're unsure, start as an individual on itch.io and Google Play; you can form a company before the paid stores.
- ⬜ **Decide the price: free or paid**  
  <sub>You · 10 min · Free</sub>
  1. Free: no tax or bank forms on most stores, and you're usually a non-trader in the EU.
  2. Paid: you'll fill in tax forms (W-9 in the US, W-8BEN elsewhere), add a bank account, and in the EU your address and phone are shown as a trader.
  3. A common route: free web demo on itch.io, paid full game on Steam.
  > **Tip:** Tell Claude the price and Claude updates the listing text and forms to match.
- ⬜ **Create a support email address for players and stores**  
  <sub>You · 10 min · Free</sub>
  1. Make a separate address for the game (for example a new Gmail or Outlook address). Every store shows it publicly.
  2. Tell Claude the address; Claude puts it in the privacy policy and listing and republishes them.
  > **Tip:** Don't use your personal inbox: store pages are public and get spam.
- ⬜ **Make the privacy policy page public and save its link**  
  <sub>You · 5 min · Free</sub>
  1. Open the privacy policy page Claude published, choose Share, and turn on the public link.
  2. Paste the link into the step's notes here. Every store asks for it.
  3. Any public web page works too (GitHub Pages, your own site): tell Claude the link and it updates the game and listings.
  > **Tip:** Do this after the support email step, so the public page shows the real address.
  > **Claude:** Your page is https://claude.ai/artifact/FTpfni4mRM5NiUvRAvZyoT. Open it, choose Share and turn on the public link. The game's Settings > Privacy & about button already opens this address.
- ⬜ **Make your Android upload key (on your own computer)**  
  <sub>You · 15 min · Free</sub>
  1. Install Java (Temurin 17 or newer) or use the one that comes with Android Studio.
  2. In a terminal run: keytool -genkeypair -v -keystore bugseyeview-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
  3. Use the same password for the store and the key (letters and numbers only - Godot needs that).
  4. Back the file and password up somewhere safe and offline. Never commit it to GitHub.
  > **Tip:** Lose it and Google can reset it, but that takes days. Two backups (a USB stick and a password manager) are enough.
- ⬜ **Play the current builds and report anything odd**  
  <sub>You · 30 min · Free</sub>
  1. Play the web build and the Windows build from Builds/.
  2. Use the Feedback tab for every bug, however small: where you were, what happened, what you expected.
  > **Tip:** Five minutes per bug and room is plenty. Small things count: a clipping chair, a confusing hint, a menu that's hard to tap.

### ⬜ Phase 2 - itch.io - first live page  (0/3)

_Free and live the same day. Real players, real feedback, a link to share._

- ⬜ **Create an itch.io account**  
  <sub>You · 5 min · Free</sub>
  1. Sign up at itch.io and verify your email.
  - 🔗 [itch.io](https://itch.io/register)
- ⬜ **Create the project and upload the builds**  
  <sub>You · 30 min · Free</sub>
  1. Dashboard > Create new project. Kind: HTML. Title: Bug's-Eye View.
  2. Upload Builds/Web/BugsEyeView-web.zip and tick "This file will be played in the browser". Viewport 1280 x 720, tick fullscreen button and mobile friendly.
  3. Also upload the Windows, macOS and Linux zips as downloads.
  4. Cover image: Store Assets/itch.io/cover_630x500.jpg. Screenshots: Store Assets/Screenshots/1920x1080 folder.
  5. Paste the short and full descriptions from Listing Text. Genre Action, tags from the listing file.
  > **Tip:** Set it to Restricted first and play it from the itch page yourself before going Public.
  - 📁 [Store pages/itch.io/README.md](Store%20pages/itch.io/README.md)
  - 🔗 [itch.io creator docs](https://itch.io/docs/creators/html5)
- ⬜ **Make it public and share the link**  
  <sub>You · 5 min · Free</sub>
  1. Visibility: Public. Pricing: free or "No payments" for now.
  2. Paste the itch.io link into this step's notes and share it with friends for feedback.

### ⬜ Phase 3 - Google Play  (0/9)

_About 3-5 weeks, mostly waiting: identity checks, a required 14-day closed test, then review._

- ⬜ **Create a Google Play developer account (Personal)**  
  <sub>You · 20 min, then 1-3 days for checks · US$25 once</sub>
  1. Go to play.google.com/console/signup with the Google account you'll keep for the game.
  2. Choose Personal (unless you made a company in phase 1), pay the $25, upload a government ID.
  3. Your legal name, country and the developer email are shown on the store.
  > **Tip:** Use the exact name on your ID - a mismatch is the most common reason for a failed check, and the fee isn't refunded.
  - 🔗 [Play Console sign-up](https://play.google.com/console/signup)
  - 🔗 [What's required](https://support.google.com/googleplay/android-developer/answer/13628312)
- ⬜ **Verify your phone and email, and an Android device**  
  <sub>You · 15 min · Free</sub>
  1. Enter the codes Google sends.
  2. Install the Play Console app on an Android 10+ phone and sign in - that finishes the device check.
- ⬜ **Create the app in Play Console**  
  <sub>You · 10 min · Free</sub>
  1. Create app: name Bug's-Eye View, language English, Game, Free (or Paid).
  2. The package name com.aethertek.bugseyeview is fixed forever once the first bundle is uploaded.
  3. Accept Play App Signing (Google keeps the app signing key; you keep the upload key).
- ⬜ **Fill in the store listing**  
  <sub>You · 30 min · Free</sub>
  1. Short and full description: Listing Text/store-listing.md.
  2. Icon: Store Assets/Google Play/icon_512.png. Feature graphic: Store Assets/Google Play/feature_graphic_1024x500.jpg.
  3. Phone screenshots: 4-8 from the Store Assets/Screenshots/1920x1080 folder (landscape 16:9 makes the game eligible for recommendations).
  4. Category Action, contact email (phase 1), privacy policy link (phase 1).
  - 📁 [Store pages/Google Play/README.md](Store%20pages/Google%20Play/README.md)
- ⬜ **Complete the App content forms**  
  <sub>You · 30 min · Free</sub>
  1. Use Legal/store-questionnaire-answers.md for every form: privacy policy, ads (No), app access, content rating (cartoon violence), target audience 13+, data safety (no data collected).
  > **Tip:** Choose 13+ for target audience. Picking under-13 brings in the Families policy and slower reviews.
- ⬜ **Build the signed release bundle (.aab)**  
  <sub>You + Claude · 15 min · Free</sub>
  1. Option A (your PC): install Godot 4.7.2 + export templates + Android SDK, open the project, Project > Export > Android AAB, set the release keystore, Export Project.
  2. Option B (cloud): add the keystore as a GitHub Actions secret and Claude sets up a workflow that builds the signed bundle.
  3. Every new upload needs a higher version code - Claude bumps it for each release.
  > **Tip:** Option B means you never need Android tools on your PC.
  - 📁 [Builds/Android/README.md](Builds/Android/README.md)
- ⬜ **Run the closed test: 12 testers for 14 days in a row**  
  <sub>You · 14+ days · Free</sub>
  1. Testing > Closed testing > create a track, upload the .aab, add testers by email list or Google Group.
  2. At least 12 testers must opt in and stay opted in for 14 days in a row.
  3. Collect what they say - the production application asks what you learned and what you changed. Log it in the Feedback tab here.
  > **Tip:** Ask 15-20 people so a few dropping out doesn't reset the clock. Friends, family, a Discord or Reddit playtest thread all work.
  - 🔗 [Testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465)
- ⬜ **Apply for production access**  
  <sub>You · Up to 7 days · Free</sub>
  1. Dashboard > Apply for production. Answer the questions about your test (Claude can draft answers from the Feedback tab).
- ⬜ **Release to production**  
  <sub>You · 1-7 days review · Free</sub>
  1. Production > Create release, upload the .aab, release notes, choose countries, send for review.
  > **Tip:** A staged rollout (20% first) lets you catch a crash before everyone gets it.

### ⬜ Phase 4 - Apple App Store (iPhone and iPad)  (0/8)

_Needs a paid Apple account and a Mac to sign the build - a cloud Mac works._

- ⬜ **Join the Apple Developer Program**  
  <sub>You · 30 min, then 1-2 days · US$99 a year</sub>
  1. Use an Apple Account with two-factor authentication, in your legal name.
  2. Enroll as an Individual (or as an Organization with a D-U-N-S number if you made a company).
  3. When it's approved, find your Team ID under Membership details and paste it in this step's notes.
  - 🔗 [Enroll](https://developer.apple.com/programs/enroll/)
- ⬜ **Choose how to build for iPhone: Mac, cloud Mac or GitHub Actions**  
  <sub>You + Claude · 1 hour · Free to ~US$50/month</sub>
  1. Apple only accepts iPhone builds made with Xcode 26 or newer on macOS. The Xcode project itself is ready: Claude exported it here and it passes Apple's current rules.
  2. Codemagic (free tier with macOS minutes) or GitHub Actions macOS runners can build it from this repo - Claude writes the workflow.
  3. Or borrow or rent a Mac (MacinCloud) for the day of the build.
  > **Tip:** GitHub Actions is the cheapest if the repo stays private and builds are rare.
- ⬜ **Register the bundle ID and certificates**  
  <sub>You + Claude · 20 min · Free</sub>
  1. Certificates, Identifiers & Profiles: register the App ID com.aethertek.bugseyeview.
  2. Create an App Store Connect API key (for automated signing and uploads) and store it as a CI secret.
- ⬜ **Create the app in App Store Connect**  
  <sub>You · 20 min · Free</sub>
  1. My Apps > + > New App: iOS, name Bug's-Eye View, bundle ID, SKU bugseyeview.
  2. Subtitle, keywords, promotional text and description: Listing Text.
  3. App Privacy: Data Not Collected. Age rating: Cartoon violence Frequent (13+). Export compliance: no non-exempt encryption.
  - 📁 [Store pages/Apple App Store/README.md](Store%20pages/Apple%20App%20Store/README.md)
- ⬜ **Upload the icon and screenshots**  
  <sub>You · 20 min · Free</sub>
  1. iPhone: Store Assets/Screenshots/iPhone 6.9 inch and iPhone 6.3 inch folders. iPad: the iPad 13 inch folder.
  2. The app icon comes from the build itself (1024 x 1024, no transparency).
- ⬜ **Build, sign and upload the iPhone build**  
  <sub>You + Claude · 1-2 hours the first time · Free</sub>
  1. Godot exports an Xcode project; Xcode (local or cloud) archives, signs and uploads it to App Store Connect.
  2. Claude fills in the Team ID and checks the export preset first.
  - 📁 [Builds/iOS/README.md](Builds/iOS/README.md)
- ⬜ **Test on your own iPhone with TestFlight**  
  <sub>You · 1-3 days · Free</sub>
  1. Install TestFlight, add yourself as an internal tester, play the build.
  2. Check touch controls, the notch area, and that the game resumes after a phone call.
- ⬜ **Submit for review and release**  
  <sub>You · 1-3 days review · Free</sub>
  1. Choose the build, add review notes ("No login needed; tutorial on first launch"), submit.
  2. If it's rejected, paste Apple's message in this step's notes - Claude fixes what's needed.

### ⬜ Phase 5 - Steam  (0/6)

_The biggest PC store. Start early: a page must be up 2 weeks before launch, and 21 days must pass after paying._

- ⬜ **Join Steamworks (Steam Direct)**  
  <sub>You · 1 hour, then up to 30 days of checks · US$100 per game (refunded after $1,000 in sales)</sub>
  1. partner.steamgames.com: sign the agreements, pay the fee, enter bank details and the tax interview, and verify your identity.
  2. As an individual, the company name is your legal name with "Sole Proprietorship".
  > **Tip:** Do this first of all the PC stores: the tax check can take up to 30 days.
  - 🔗 [Onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding)
- ⬜ **Build the store page**  
  <sub>You · 1-2 hours · Free</sub>
  1. Capsules and library images: Store Assets/Steam (every size is ready).
  2. 5+ screenshots from Store Assets/Screenshots/1920x1080. Descriptions and system requirements from Listing Text.
  3. Content survey: cartoon violence only.
  - 📁 [Store pages/Steam/README.md](Store%20pages/Steam/README.md)
- ⬜ **Make a short trailer (30-60 seconds)**  
  <sub>You + Claude · 2-4 hours · Free</sub>
  1. Record gameplay (Windows: Win+Alt+R or OBS). Show the bug's-eye view, a crash distraction, a slap and an escape in the first 5 seconds.
  2. Claude can plan the shot list.
  > **Tip:** Steam trailers autoplay muted: put the action first, text big and short.
- ⬜ **Submit the page and go "Coming Soon"**  
  <sub>You · 3-5 business days review · Free</sub>
  1. Submit for review at least 7 business days before you want it live.
  2. Once approved, press Publish as Coming Soon. Wishlists start counting.
  > **Tip:** The longer the page is up before launch, the more wishlists - a month or more helps.
- ⬜ **Upload the builds with SteamPipe and pass the build review**  
  <sub>You + Claude · 3-5 business days review · Free</sub>
  1. Upload Builds/Windows and Builds/Linux as depots (steamcmd or SteamPipe GUI).
  2. Only list macOS once the Mac build is notarized by Apple (needs the Apple account from phase 4).
- ⬜ **Press Release**  
  <sub>You · Launch day · Free</sub>
  1. After 2 weeks of Coming Soon and 21 days since paying, the Release button unlocks.

### ⬜ Phase 6 - GOG (curated - by invitation)  (0/2)

_GOG picks the games it sells. Pitch once the Steam page and a trailer are up._

- ⬜ **Send the pitch form**  
  <sub>You · 30 min, reply in days or weeks · Free</sub>
  1. gog.com/submit-your-game: developer, title, description, platforms, status, price, links to the Steam page and trailer.
  2. Claude can draft the answers.
  - 📁 [Store pages/GOG/README.md](Store%20pages/GOG/README.md)
  - 🔗 [Submit your game](https://www.gog.com/submit-your-game)
- ⬜ **If accepted: contract, Developer Portal and builds**  
  <sub>You + Claude · 1-3 weeks · Free</sub>
  1. Fill GOG's Essentials Checklist (key art and logo from Store Assets/GOG, description, screenshots, trailer).
  2. Upload builds with GOG's Build Creator; they must run offline and contain no links to other stores.

### ⬜ Phase 7 - Epic Games Store  (0/2)

_Windows and Mac only. You keep 100% of the first $1M each year._

- ⬜ **Join the Epic Developer Portal and pay the submission fee**  
  <sub>You · 1 hour, then up to 2 weeks · US$100 per game</sub>
  1. dev.epicgames.com/portal: sign the Distribution Agreement, pay the fee, complete trader, tax and payout details.
- ⬜ **Store page, rating and build**  
  <sub>You · 2-3 hours, 3-5 days review · Free</sub>
  1. Images in Store Assets/Epic Games Store. IARC rating inside the portal (same answers as Google Play).
  2. Upload the Windows build with the BuildPatch Tool, then submit for review.
  - 📁 [Store pages/Epic Games Store/README.md](Store%20pages/Epic%20Games%20Store/README.md)

### ⬜ Phase 8 - Microsoft Store  (0/3)

_No fee. Decide Individual or Company first: it can't be changed later._

- ⬜ **Create the Microsoft Store developer account**  
  <sub>You · 30 min, then a few days · Free</sub>
  1. storedeveloper.microsoft.com. Individual: government ID and a selfie. Company: business documents or a D-U-N-S number.
  2. Selling as a business needs a Company account.
- ⬜ **Reserve the name and fill the submission**  
  <sub>You · 1 hour · Free</sub>
  1. Reserve "Bug's-Eye View". Pricing, Games category, IARC questionnaire, listing text and images from Store Assets/Microsoft Store.
  - 📁 [Store pages/Microsoft Store/README.md](Store%20pages/Microsoft%20Store/README.md)
- ⬜ **Package the Windows build as MSIX and submit**  
  <sub>You + Claude · 1-2 hours, 3 days certification · Free</sub>
  1. The Partner Center gives you the identity values; Claude puts them in the package manifest.
  2. Wrap the Windows build with the MSIX Packaging Tool (on Windows) and upload. Microsoft signs it.

### ⬜ Phase 9 - Launch and after  (0/3)

_Keep players happy: fix what they report, ship small updates._

- ⬜ **Add the game to IGDB and press kit pages**  
  <sub>You · 30 min · Free</sub>
  1. IGDB (used by GOG and many sites): add the game with the key art and description.
  2. Optional: a one-page press kit with the key art, logo, screenshots and trailer.
- ⬜ **Launch day**  
  <sub>You · 1 day · Free</sub>
  1. Release on the stores that are ready; post the links where your players are (Reddit, Discord, TikTok, friends).
  2. Watch the Feedback tab and the store reviews.
- ⬜ **First update from player feedback**  
  <sub>You + Claude · Ongoing · Free</sub>
  1. Claude fixes reported bugs, bumps the version numbers and rebuilds every platform into Builds/.
  2. Upload the new builds to each store.
  > **Tip:** Small, frequent updates with clear notes ("Fixed: chair legs blocked the camera") earn better reviews than one big one.

## Costs at a glance

| Store | Fee | Time to live (typical) |
|---|---|---|
| itch.io | Free | Same day |
| Google Play | US$25 once | 3-5 weeks (14-day closed test) |
| Apple App Store | US$99 a year (+ a Mac or cloud Mac) | 1-2 weeks |
| Steam | US$100 per game, refunded after $1,000 | 4-6 weeks (2-week Coming Soon, 21-day wait) |
| GOG | Free (curated) | Weeks to months, if accepted |
| Epic Games Store | US$100 per game | 2-4 weeks |
| Microsoft Store | Free | 1-2 weeks |

## Never put these in git

Signing keys and passwords stay on your computer and in your password manager: the Android upload keystore (`*.keystore`, `*.jks`), Apple certificates (`*.p12`) and API keys (`*.p8`), Steam and store logins. `.gitignore` already blocks the key files.

_Regenerate this file and the tracker page with `python3 tools/release/make_checklist.py`._
