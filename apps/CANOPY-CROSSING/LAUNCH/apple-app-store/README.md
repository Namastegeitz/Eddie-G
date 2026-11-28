# **CANOPY CROSSING: APPLE APP STORE**

Steps for Apple App Store (and the ones every store needs). Live checklist: https://claude.ai/artifact/W8GbYN7jifz6X6fRE4QSNR

Researched requirements, with sources: [requirements.md](requirements.md)

## Phase 0: Set up the project for launch

- [x] ✅ **Put all of Canopy Crossing in one folder: CANOPY-CROSSING**  
  _Claude_

  **Why:** Everything for the game (source, builds, store paperwork) lives in one place you can find and hand over.

  **How:**
  1. Moved apps/canopy-crossing to apps/CANOPY-CROSSING and updated every link and workflow.
  2. Added BUILDS/ (one folder per platform) and LAUNCH/ (one folder per store).

  **Done when:** apps/CANOPY-CROSSING opens in Godot and every test passes from there.

  **Done ✅** Builds next.

- [x] ✅ **Export the iOS Xcode project into BUILDS/ios**  
  _Claude · Apple App Store_

  **Why:** Godot on Linux can make the Xcode project; turning it into an App Store upload needs a Mac (or a Mac in GitHub Actions).

  **How:**
  1. Exported with Godot 4.7.2: iPhone + iPad, iOS 15.0 and newer, privacy manifest included.

  **Done when:** BUILDS/ios/CanopyCrossing-iOS-XcodeProject.zip exists.

  **Done ✅** Phase 5 turns it into a TestFlight build.

- [x] ✅ **Set up GitHub Actions to build all six platforms (Android too)**  
  _Claude_

  **Why:** This machine can't download Google's Android tools, and store builds should come from one repeatable place.

  **How:**
  1. .github/workflows/canopy-crossing-release.yml builds web, Windows, macOS, Linux, iOS project, Android APK and the Play Store .aab.
  2. Each platform is its own download; a canopy-release-v* tag also makes a draft GitHub Release.

  **Done when:** The workflow file is in the repo.

  **Done ✅** You run it once your Android upload key is in GitHub (Phase 5).

- [x] ✅ **Use one version number everywhere**  
  _Claude_

  **Why:** Android, iOS, Windows and macOS each read the version from a different setting; they disagreed (0.9.0 vs 1.0.0).

  **How:**
  1. tools/set_version.py sets it everywhere at once; now 0.9.0, build 1.

  **Done when:** python3 tools/set_version.py shows the same version for every platform.

  **Done ✅** Set 1.0.0 before the first store upload (Phase 4).

- [x] ✅ **Research every store's current rules (November 2026)**  
  _Claude_

  **Why:** Store rules change every year; several changed in 2026 (Android target API 36, Steam review times, Apple age ratings, Epic revenue share).

  **How:**
  1. Read each store's official pages and the Godot 4.7.2 source; saved per store in LAUNCH/<store>/requirements.md with sources, marking anything unverified.

  **Done when:** Every store folder has a requirements.md.

  **Done ✅** Each step below links the official page to re-check on the day you do it.

- [x] ✅ **Write the store text for every listing**  
  _Claude_

  **Why:** Every store asks for a name, short and long description and keywords, each with its own length limit.

  **How:**
  1. LAUNCH/shared/store-listing.md: name, Apple subtitle (29/30), Play short description (73/80), promotional text, keywords (96/100), Steam short description (283/300), full description (1822/4000).

  **Done when:** Every field fits its limit.

  **Done ✅** Read it once and change anything that doesn't sound like you.

- [x] ✅ **List the 36 in-app products for App Store Connect and Play Console**  
  _Claude · Apple App Store · Google Play_

  **Why:** Both consoles need each product created by hand with the right id, type and price.

  **How:**
  1. LAUNCH/shared/in-app-products.csv: ids, types, prices, and Apple's 45-character descriptions.
  2. The season pass gets a new product id each season (Apple never lets an id be reused).

  **Done when:** The CSV has every product with a description that fits.

  **Done ✅** You'll enter these after the paid-apps agreements are signed.

- [x] ✅ **Draft the privacy policy from what the game really does**  
  _Claude_

  **Why:** Apple, Google, Amazon, Samsung, Steam and Epic all need a privacy policy link.

  **How:**
  1. Checked the code: saves and gameplay events stay on the device; purchases go through the store; ads are still a sandbox.
  2. LAUNCH/shared/privacy-policy.md, with [FILL IN] for your name, email and the ads section.

  **Done when:** The draft exists.

  **Done ✅** Fill it in and host it (Phase 3).

- [x] ✅ **Draft the age-rating answers**  
  _Claude_

  **Why:** Every store asks a rating questionnaire; wrong answers mean a wrong rating or a rejection.

  **How:**
  1. LAUNCH/shared/content-rating-answers.md, from the game's content: cartoon peril, no blood, no loot boxes, purchases yes.
  2. Likely Apple 9+ (13+ if failing a run counts as frequent violence); ESRB Everyone.

  **Done when:** The draft exists.

  **Done ✅** You answer the real questionnaires in Phase 3.

- [x] ✅ **Make the App Store icon opaque**  
  _Claude · Apple App Store_

  **Why:** The 1024 px icon had see-through corners; App Store uploads are rejected for icons with transparency.

  **How:**
  1. assets/icons/icon_ios_1024.png: the same frog icon on the jungle green, no alpha channel; the iOS preset now uses it.

  **Done when:** The iOS export's icons have no transparency.

  **Done ✅** Claude checks it again on the first real archive.

- [x] ✅ **Make this live checklist and bug log**  
  _Claude_

  **Why:** So you can see where things stand, tick steps off, and collect bug reports in one place.

  **How:**
  1. Progress, notes and bug reports are saved for everyone who opens the page; LAUNCH/README.md is the same checklist as a file.

  **Done when:** You can tick a step and see it turn green.

  **Done ✅** Next is yours: Phase 1 decisions.

## Phase 1: Decide

- [ ] **Decide who publishes: you as a person, or a company (e.g. Aethertek)**  
  _You_

  **Why:** It decides the seller name on every store, the paperwork, and whether your home address is shown.

  **How:**
  1. Company: Apple needs a D-U-N-S number and a website; Google skips the 12-tester rule and shows the business address.
  2. Individual: faster to start, but Google requires 12 testers for 14 days and shows a personal trader's address in the EU.
  3. The builds currently say Aethertek (bundle id com.aethertek.canopycrossing).

  **Done when:** You've picked one and written the legal name in this step's notes.

  **Watch out:** The bundle/package id can't change after the first upload: confirm com.aethertek.canopycrossing now.

  **Official pages:** [Apple enrollment](https://developer.apple.com/programs/enroll/) · [Google account types](https://support.google.com/googleplay/android-developer/answer/13628312)

- [ ] **Get a free D-U-N-S number (company only)**  
  _You · Apple App Store · Google Play · Amazon Appstore · up to 30 days_

  **Why:** Apple and Google both require it for organization accounts.

  **How:**
  1. Request it free from Dun & Bradstreet (Apple has a lookup tool on its site).
  2. Make the legal name match exactly everywhere.

  **Done when:** You have the 9-digit number.

  **Watch out:** Don't pay a third-party 'D-U-N-S service'; it's free.

  **Official pages:** [Apple D-U-N-S lookup](https://developer.apple.com/enroll/duns-lookup/)

- [ ] **Set up a small website and a support email**  
  _You + Claude_

  **Why:** Needed for the support URL, the privacy policy and terms pages, Google organization verification, and AdMob's app-ads.txt.

  **How:**
  1. A one-page site is enough: about the game, support email, privacy policy, terms.
  2. Claude can make the pages; you own the domain and email.

  **Done when:** The site is live on its own domain with a working support email.

  **Watch out:** Google verifies the site in Search Console: the URL must match exactly.

- [ ] **Decide the audience: everyone (incl. children) or 13 and older**  
  _You · Apple App Store · Google Play_

  **Why:** The game looks kid-friendly. Including under-13s brings Google's Families policy and US COPPA rules; choosing 13+ means the listing can't look like it's mainly for children.

  **How:**
  1. Read LAUNCH/shared/content-rating-answers.md, Audience section.
  2. Recommendation: mixed audience with a neutral age question, and no personalised ads for children.

  **Done when:** You've chosen, and noted it here.

  **Watch out:** Never write 'for kids' in the listing unless you choose the Kids/Families route on purpose.

- [ ] **Decide how the phone version makes money: purchases only, or purchases + ads**  
  _You · Apple App Store · Google Play_

  **Why:** Ads add the most paperwork: consent screens, Apple's tracking prompt, Data safety answers, ad-report links, and stricter rules for children.

  **How:**
  1. Purchases only: simplest, fastest approval.
  2. Purchases + ads: Claude adds AdMob with Google's consent screen; you create an AdMob account.

  **Done when:** Chosen and noted here.

- [ ] **Pick your stores and the order**  
  _You_

  **Why:** Each store costs time and sometimes money; some have long waiting periods that should start early.

  **How:**
  1. Suggested: Google Play + Apple first; itch.io any time (instant); Steam early because of its 30-day and 2-week waits; GOG when nearly finished (curated); Epic optional (2+ weeks verification); Amazon and Samsung last (each needs its own payment plugin).

  **Done when:** Your list is in this step's notes.

- [ ] **Check which Meshy plan made the 3D models**  
  _You_

  **Why:** Models made on Meshy's free plan are CC BY 4.0 (free to sell, but you must credit Meshy); paid-plan models are yours outright. The plan at the time each model was made is what counts.

  **How:**
  1. Check your Meshy account history for the date of the subscription vs the models (made on 10-12 Nov 2026).
  2. Tell Claude: credit Meshy in the credits screen, or nothing needed.

  **Done when:** You know which, noted here.

  **Official pages:** [Meshy commercial use](https://help.meshy.ai/en/articles/9992001-can-i-use-my-generated-assets-for-commercial-projects)

## Phase 2: Accounts, contracts and money

- [ ] **Join the Apple Developer Program**  
  _You · Apple App Store · Mac distribution · US$99/year_

  **Why:** Needed to publish on iPhone and iPad, and to notarize the Mac build for Steam, GOG and itch.io.

  **How:**
  1. Sign in with an Apple Account that has two-factor authentication, in your legal name.
  2. Enroll as an individual, or as an organization with the D-U-N-S number and website.
  3. No Mac needed for this step.

  **Done when:** You can sign in to App Store Connect.

  **Watch out:** Aliases and P.O. boxes delay approval.

  **Official pages:** [Enroll](https://developer.apple.com/programs/enroll/)

- [ ] **Sign Apple's Paid Apps Agreement, add tax forms and bank**  
  _You · Apple App Store_

  **Why:** In-app purchases can't be created until the Account Holder signs it.

  **How:**
  1. App Store Connect > Business: Paid Apps Agreement, then bank, then the US tax form (W-9 in the US, W-8BEN or W-8BEN-E elsewhere).

  **Done when:** Business shows the agreement as Active.

  **Watch out:** When Apple publishes a new agreement version you can't add apps or products until you accept it.

  **Official pages:** [Agreements](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/)

- [ ] **Join Apple's Small Business Program (15% instead of 30%)**  
  _You · Apple App Store_

  **Why:** Halves Apple's commission while you earn under US$1M a year.

  **How:**
  1. Apply after the Paid Apps Agreement is signed.

  **Done when:** Approval email received.

  **Official pages:** [Small Business Program](https://developer.apple.com/app-store/small-business-program/)

- [ ] **Declare EU trader status in App Store Connect**  
  _You · Apple App Store_

  **Why:** Mandatory since Feb 2025, or the game is removed from all 27 EU storefronts. Selling purchases makes you a trader.

  **How:**
  1. Business > Agreements > Compliance > Digital Services Act: address, phone and email shown on the EU page, verified by Apple.

  **Done when:** Status shows Verified.

  **Official pages:** [DSA trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)

- [ ] **Register the bundle id and create the app in App Store Connect**  
  _You · Apple App Store_

  **Why:** Builds, products and the listing all hang off this record.

  **How:**
  1. Certificates, Identifiers & Profiles: explicit App ID com.aethertek.canopycrossing.
  2. App Store Connect > Apps > New App: iOS, name Canopy Crossing, the bundle id, a SKU (permanent).

  **Done when:** The app appears in App Store Connect.

  **Watch out:** The bundle id and SKU can never change after the first build.

  **Official pages:** [Add a new app](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)

- [ ] **Create an App Store Connect API team key for automatic uploads**  
  _You · Apple App Store_

  **Why:** Lets GitHub Actions sign, build and upload iOS builds without you owning a Mac.

  **How:**
  1. Users and Access > Integrations > App Store Connect API > Team Keys (Admin role).
  2. Download the .p8 (only once!), note the Key ID and Issuer ID; add them as GitHub secrets (Claude will say the names).

  **Done when:** The three values are saved as GitHub secrets.

  **Watch out:** Use a Team key: individual keys can't create certificates and profiles.

  **Official pages:** [API keys](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)

- [ ] **Create a free Sentry project for crash reports**  
  _You · free (Developer plan)_

  **Why:** The game is ready to send crash and error reports from the Android .aab, iPhone, Windows, Mac and Linux builds; it needs your project's DSN to know where.

  **How:**
  1. Sign up at sentry.io (free Developer plan), create a project with platform Godot Engine.
  2. Copy the DSN (Settings > Projects > Client Keys).
  3. Settings > Security & Privacy: turn on Prevent Storing of IP Addresses.
  4. GitHub > Settings > Secrets and variables > Actions: new secret SENTRY_DSN.

  **Done when:** The release builds' log says SENTRY OK.

  **Watch out:** Keep the free plan's 5,000 errors a month in mind: one bad bug can use them up; Sentry stops accepting new ones until next month.

  **Official pages:** [Setup steps](https://sentry.io/signup/)

## Phase 3: Legal and privacy

- [ ] **Finish the privacy policy and put it on your website**  
  _You + Claude_

  **Why:** Every store needs a public link; Google rejects PDFs, logins and pages blocked by country.

  **How:**
  1. Fill in the [FILL IN] parts of LAUNCH/shared/privacy-policy.md (Claude can fill what it knows).
  2. Keep or delete the ads section to match Phase 1.
  3. Publish it as a normal web page on your site.

  **Done when:** The policy opens at a public https:// address.

  **Watch out:** Update it before the game ever sends data anywhere (ads, analytics, crash reports).

- [ ] **Add a privacy policy link inside the game**  
  _Claude · Apple App Store · Google Play_

  **Why:** Apple (guideline 5.1.1) and Google both require the policy to be reachable inside the app, not only on the store page.

  **How:**
  1. Settings gets 'Privacy policy' and 'Terms of use' buttons that open the pages.

  **Done when:** Tapping the button in Settings opens your policy.

- [ ] **Write terms of use**  
  _You + Claude · Google Play · Apple App Store_

  **Why:** Google traders need a terms link per app; Apple needs one for any subscription.

  **How:**
  1. Claude drafts them; you check them and host them next to the privacy policy.

  **Done when:** Terms are live on your site.

- [x] ✅ **Add a credits and licences screen**  
  _Claude_

  **Why:** Godot's MIT licence and the fonts' licences require a notice; free-plan Meshy models need credit.

  **How:**
  1. Settings > Credits: Godot notice, font licences, music credit, Meshy credit if the models were free-plan.

  **Done when:** Credits open from Settings.

  **Done ✅** Then the privacy questionnaires.

- [ ] **Answer Apple's App Privacy questions**  
  _You · Apple App Store_

  **Why:** Required for every submission; shown as the privacy label on the store page.

  **How:**
  1. Without ads: Data Not Collected (everything stays on the device).
  2. With AdMob: Device ID, Advertising Data, Product Interaction, Coarse Location, Diagnostics.
  3. With crash reporting on: Diagnostics > Crash Data and Other Diagnostic Data; not linked to the user, not tracking, App Functionality.

  **Done when:** App Privacy shows Published.

  **Watch out:** Saying you track without ever showing Apple's tracking prompt is a common rejection.

  **Official pages:** [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)

- [ ] **Answer the age-rating questionnaires (Apple and IARC)**  
  _You_

  **Why:** Unrated games aren't allowed on Google Play or the App Store; IARC also covers Amazon, Samsung, Microsoft and Epic.

  **How:**
  1. Use LAUNCH/shared/content-rating-answers.md.
  2. Apple: also answer the new Shared Location, Dating and social-media questions (all No).

  **Done when:** Both show a rating.

  **Watch out:** Answer honestly about purchases and ads; wrong answers can pull the game later.

  **Official pages:** [Apple age ratings](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/) · [Google content ratings](https://support.google.com/googleplay/android-developer/answer/9859655)

- [ ] **Answer Apple's export compliance question**  
  _You · Apple App Store_

  **Why:** Apple asks every build whether it uses encryption.

  **How:**
  1. Answer that it uses no non-exempt encryption (the game only uses the system's HTTPS). Godot already sets this in the build.

  **Done when:** Answered once; later builds remember it.

- [ ] **If children may play: age question, child-safe ads, legal check**  
  _You + Claude · Apple App Store · Google Play_

  **Why:** Google's Families policy and the amended US COPPA rule apply to games children play.

  **How:**
  1. Claude adds a neutral age question and child-directed ad settings (G-rated, no personalised ads) if you use ads.
  2. Get legal advice before turning ads on.

  **Done when:** Done, or not needed because you chose 13+ or no ads.

## Phase 4: Game changes the stores require

- [ ] **Real Apple purchases (StoreKit 2) instead of the sandbox**  
  _Claude · Apple App Store_

  **Why:** Apple rejects games whose purchases don't work, and requires a Restore button and currency that never expires.

  **How:**
  1. Add a StoreKit 2 plugin to the iOS build (test it first: Godot plugins vary).
  2. Restore purchases already exists in Settings.

  **Done when:** A TestFlight sandbox purchase works and restores.

- [ ] **Ads: real AdMob with consent screens, or turn ads off**  
  _Claude · Apple App Store · Google Play_

  **Why:** Ads are a sandbox today. Real ads need Google's consent screen in Europe, Apple's tracking prompt if personalised, and a way to report a bad ad.

  **How:**
  1. If ads: AdMob plugin (poingstudios 5.1.0) with UMP consent, your ad unit ids, a 'Report an ad' link, app-ads.txt on your site.
  2. If no ads: remove the ad code paths and the Remove Ads product.

  **Done when:** Matches your Phase 1 choice and the privacy answers.

  **Watch out:** Interstitials must have a clear close button; rewarded videos must be opt-in.

- [ ] **Give the season pass a new product id each season**  
  _Claude · Apple App Store · Google Play_

  **Why:** The game uses one id for every season, but Apple never allows an id to be reused and a one-time purchase is owned forever.

  **How:**
  1. Product ids like expedition_pass.expedition_amazon, one per season, in the store catalog.

  **Done when:** Buying the pass in season 2 is a different product from season 1.

- [ ] **Check iPad windows and the new iPhone Duo**  
  _You + Claude · Apple App Store_

  **Why:** iPadOS 26 lets apps run in windows (Godot's full-screen flag is deprecated); iPhone Duo screenshots become required in April 2027.

  **How:**
  1. Test on an iPad in Stage Manager / windowed mode.
  2. Before April 2027, test in Xcode 27's iPhone Duo simulator.

  **Done when:** The game stays usable in an iPad window.

- [ ] **Set version 1.0.0 before the first store upload**  
  _Claude_

  **Why:** The stores show this version; the build number must go up with every upload.

  **How:**
  1. python3 tools/set_version.py 1.0.0 1

  **Done when:** Every platform shows 1.0.0 (build 1).

## Phase 5: Signing and store builds

- [ ] **Run 'Canopy Crossing release builds' on GitHub**  
  _You_

  **Why:** Makes all six platforms (including the Play Store .aab) on GitHub's machines.

  **How:**
  1. GitHub > Actions > Canopy Crossing release builds > Run workflow.
  2. Download each platform from the run page; tell Claude if anything fails.

  **Done when:** The run is green and has six downloads.

- [ ] **Build and upload iOS from GitHub (no Mac needed)**  
  _You + Claude · Apple App Store · needs Apple account_

  **Why:** The .ipa must be built and signed on macOS; GitHub's Mac machines can do it.

  **How:**
  1. You: create an Apple Distribution certificate and App Store provisioning profile (or let the CI create them with the API key); add the secrets.
  2. Claude: a macOS job that exports with Godot, archives with Xcode 26, and uploads to TestFlight.

  **Done when:** A build appears in TestFlight.

  **Watch out:** Uploads must be built with Xcode 26 now and Xcode 27 from April 2027.

## Phase 6: Store pictures and video

- [ ] **App Store screenshots: iPhone and iPad**  
  _Claude · Apple App Store_

  **Why:** Required; they're most of what people see before installing.

  **How:**
  1. iPhone 6.9-inch 1320x2868 and 6.3-inch 1206x2622 (6.5-inch 1284x2778 if no 6.9-inch).
  2. iPad 13-inch 2064x2752.
  3. Up to 10 per size; real gameplay; no Android status bars; no prices.

  **Done when:** Uploaded for each size.

  **Official pages:** [Screenshot sizes](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)

- [ ] **App Store preview video (optional, recommended)**  
  _Claude · Apple App Store_

  **Why:** Previews autoplay before the screenshots.

  **How:**
  1. 15-30 seconds of real gameplay capture, 886x1920 (iPhone) and 1200x1600 (iPad), H.264, up to 30 fps.

  **Done when:** Uploaded and processed.

  **Watch out:** Only captures of the app itself: no cinematic made outside it.

## Phase 7: Test with real people

- [ ] **TestFlight on iPhone and iPad**  
  _You + Claude · Apple App Store_

  **Why:** Testers install the real App Store build; the first external build needs a quick Apple review.

  **How:**
  1. Internal group first (up to 100), then external testers by email or public link (up to 10,000).
  2. Purchases in TestFlight are free sandbox purchases.

  **Done when:** External testers are playing.

  **Official pages:** [TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)

- [ ] **Test on a spread of real devices**  
  _You + Claude · Apple App Store · Google Play_

  **Why:** Crashes on one popular phone are enough for a bad review or a rejection.

  **How:**
  1. A small and a large iPhone, an iPad; a cheap and a recent Android phone, an Android 16 phone, a tablet.
  2. Buy, restore, interrupt a purchase, play offline, switch views, rotate, lock the screen mid-run.

  **Done when:** No crashes or blockers left in the bug list.

- [ ] **Collect bugs and feedback here; Claude fixes them**  
  _You + Claude_

  **Why:** Small bugs found now don't become 1-star reviews later.

  **How:**
  1. Log each report on the Bugs & feedback tab (or forward testers' messages to log).
  2. Claude reads the list, fixes, and you set reports to Fixed after checking.

  **Done when:** No open Crash or Blocks-play reports.

## Phase 8: Submit and get approved

- [ ] **App Store: submit the app and its first in-app purchases**  
  _You · Apple App Store · usually 24-48 h_

  **Why:** The first purchase of each type must go in the same submission as the app.

  **How:**
  1. Version page complete; add the in-app products (each needs a review screenshot).
  2. Review notes: how to reach the store, what each purchase unlocks, that Amber never expires, how Restore works, no loot boxes.

  **Done when:** Status: Ready for Distribution.

  **Watch out:** Common rejections: purchases not working, no in-app privacy link, metadata naming other games.

  **Official pages:** [App Review](https://developer.apple.com/distribute/app-review/)

## Phase 9: Launch and keep it running

- [ ] **Pick launch day and line the stores up**  
  _You_

  **Why:** Steam and GOG dates are hard to move late; launching everywhere at once concentrates attention.

  **How:**
  1. Phones: managed publishing (Google) and manual release (Apple) let you press go on the same day.
  2. Steam: date set 2+ weeks ahead; GOG: agreed with your Product Manager.

  **Done when:** Live everywhere you chose.

- [ ] **Watch crashes, reviews and store messages for the first two weeks**  
  _You + Claude_

  **Why:** Google ranks games down when crash rates pass 1.09% overall; fast replies to reviews help ratings.

  **How:**
  1. Play Console vitals, App Store Connect, Steam reviews; log anything new as a bug here.

  **Done when:** Two weeks with no open crash reports.

- [ ] **Meet the 2027 deadlines**  
  _You + Claude · Apple App Store · Google Play · Mac distribution_

  **Why:** Missing these blocks updates or removes the game.

  **How:**
  1. 12 Jan 2027: Apple's new age-rating questions answered.
  2. 1 Feb 2027: Google trader declaration; Google 16 KB rule for updates; Mac Developer ID builds re-signed under Apple's new certificate.
  3. April 2027: Xcode 27 / iOS 27 SDK, iOS 15+ minimum, iPhone Duo screenshots.
  4. Aug 2027: Google's next target API (likely 37) and Play Billing 8 minimum.

  **Done when:** Each date passed with nothing blocked.

- [ ] **Yearly upkeep**  
  _You_

  **Why:** Accounts and agreements lapse quietly.

  **How:**
  1. Renew Apple's membership; accept new agreements when stores publish them.
  2. Ship patches to Epic no later than other stores.
  3. Update the privacy policy and Data safety before any new data leaves the device.

  **Done when:** A full year with nothing lapsed.
