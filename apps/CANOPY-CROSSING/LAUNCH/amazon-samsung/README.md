# **CANOPY CROSSING: AMAZON APPSTORE + SAMSUNG GALAXY STORE**

Steps for Amazon Appstore + Samsung Galaxy Store (and the ones every store needs). Live checklist: https://claude.ai/artifact/W8GbYN7jifz6X6fRE4QSNR

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

- [ ] **Optional: Amazon Appstore and Samsung Galaxy Store accounts**  
  _You · Amazon Appstore_

  **Why:** Amazon now only reaches existing Fire tablets (new Alexa tablets use Google Play); Samsung reaches Galaxy phones. Each needs its own payment system in the game.

  **How:**
  1. Amazon: free account, tax interview, bank.
  2. Samsung Seller Portal: commercial seller status (bank verification up to 10 business days).

  **Done when:** Accounts open, or you've decided to skip them.

  **Watch out:** Both need a custom payment plugin; leave them until Google and Apple are live.

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

- [ ] **Create a free Firebase project for Crashlytics (Android)**  
  _You · Google Play · Amazon Appstore · free (Spark plan)_

  **Why:** Crashlytics is Google's crash reporter: it catches Android crashes, including the engine's own, and shows them next to Play's vitals.

  **How:**
  1. console.firebase.google.com > Add project (Google Analytics off).
  2. Add an Android app with package com.aethertek.canopycrossing; download google-services.json.
  3. Crashlytics > Enable.
  4. GitHub secret FIREBASE_ANDROID_CONFIG = the whole contents of google-services.json.

  **Done when:** The release builds' log says CRASHLYTICS LIBRARY OK (with Firebase config).

  **Watch out:** Don't commit google-services.json; it's git-ignored on purpose.

  **Official pages:** [Firebase console](https://console.firebase.google.com/)

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

- [x] ✅ **Add a credits and licences screen**  
  _Claude_

  **Why:** Godot's MIT licence and the fonts' licences require a notice; free-plan Meshy models need credit.

  **How:**
  1. Settings > Credits: Godot notice, font licences, music credit, Meshy credit if the models were free-plan.

  **Done when:** Credits open from Settings.

  **Done ✅** Then the privacy questionnaires.

- [ ] **Answer the age-rating questionnaires (Apple and IARC)**  
  _You_

  **Why:** Unrated games aren't allowed on Google Play or the App Store; IARC also covers Amazon, Samsung, Microsoft and Epic.

  **How:**
  1. Use LAUNCH/shared/content-rating-answers.md.
  2. Apple: also answer the new Shared Location, Dating and social-media questions (all No).

  **Done when:** Both show a rating.

  **Watch out:** Answer honestly about purchases and ads; wrong answers can pull the game later.

  **Official pages:** [Apple age ratings](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/) · [Google content ratings](https://support.google.com/googleplay/android-developer/answer/9859655)

## Phase 4: Game changes the stores require

- [ ] **Check Android 16 behaviour and 16 KB pages**  
  _You + Claude · Google Play · Amazon Appstore_

  **Why:** Android 16 changed the back gesture and edge-to-edge drawing; Google blocks updates without 16 KB page support from 1 Feb 2027.

  **How:**
  1. Claude verifies the .aab's 16 KB alignment in CI.
  2. You test the back gesture and screen edges on an Android 16 phone.

  **Done when:** Back exits/pauses correctly; nothing is hidden under the screen edges; alignment check passes.

- [ ] **Set version 1.0.0 before the first store upload**  
  _Claude_

  **Why:** The stores show this version; the build number must go up with every upload.

  **How:**
  1. python3 tools/set_version.py 1.0.0 1

  **Done when:** Every platform shows 1.0.0 (build 1).

- [ ] **Optional: separate Android builds for Amazon and Samsung**  
  _Claude · Amazon Appstore_

  **Why:** Each Android store needs its own payment system (one per APK); neither has a Godot plugin.

  **How:**
  1. Write small Android plugins for Amazon IAP and Samsung IAP; a build per store.

  **Done when:** Only if you chose those stores.

## Phase 5: Signing and store builds

- [ ] **Create the Android upload key and give it to GitHub**  
  _You · Google Play · Amazon Appstore_

  **Why:** Google Play remembers the key of your first upload forever; it must be yours and backed up.

  **How:**
  1. Run the keytool command in BUILDS/android/README.md.
  2. Back the .keystore and password up somewhere safe (not in git).
  3. Add CANOPY_ANDROID_KEYSTORE_BASE64, CANOPY_ANDROID_KEY_ALIAS, CANOPY_ANDROID_KEY_PASSWORD as GitHub secrets.

  **Done when:** The three secrets exist.

  **Watch out:** Make it valid for 25+ years (past 22 Oct 2033 at least).

  **Official pages:** [App signing](https://developer.android.com/studio/publish/app-signing)

- [ ] **Run 'Canopy Crossing release builds' on GitHub**  
  _You_

  **Why:** Makes all six platforms (including the Play Store .aab) on GitHub's machines.

  **How:**
  1. GitHub > Actions > Canopy Crossing release builds > Run workflow.
  2. Download each platform from the run page; tell Claude if anything fails.

  **Done when:** The run is green and has six downloads.

## Phase 7: Test with real people

- [ ] **Collect bugs and feedback here; Claude fixes them**  
  _You + Claude_

  **Why:** Small bugs found now don't become 1-star reviews later.

  **How:**
  1. Log each report on the Bugs & feedback tab (or forward testers' messages to log).
  2. Claude reads the list, fixes, and you set reports to Fixed after checking.

  **Done when:** No open Crash or Blocks-play reports.

## Phase 8: Submit and get approved

- [ ] **Optional: Amazon and Samsung submissions**  
  _You · Amazon Appstore_

  **Why:** Only after their payment plugins are built.

  **How:**
  1. Amazon: APK upload, 3-10 screenshots, rating questionnaire.
  2. Samsung: Seller Portal, exclude Vietnam, age rating.

  **Done when:** Live, or skipped.

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

- [ ] **Yearly upkeep**  
  _You_

  **Why:** Accounts and agreements lapse quietly.

  **How:**
  1. Renew Apple's membership; accept new agreements when stores publish them.
  2. Ship patches to Epic no later than other stores.
  3. Update the privacy policy and Data safety before any new data leaves the device.

  **Done when:** A full year with nothing lapsed.
