# **CANOPY CROSSING: ITCH.IO**

Steps for itch.io (and the ones every store needs). Live checklist: https://claude.ai/artifact/W8GbYN7jifz6X6fRE4QSNR

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

- [x] ✅ **Build Windows, macOS, Linux and web, each into its own folder**  
  _Claude · Steam · GOG · itch.io · Epic Games Store_

  **Why:** Each store takes a different file; one folder per platform keeps them apart and shows what's ready.

  **How:**
  1. tools/build_all.sh exports each platform into BUILDS/<platform>/ with a BUILD_INFO.json (version, commit, size, checksum).
  2. Checked: the Linux build starts and reaches the home screen; the web build passes phone, tablet, mouse and X-key tests in a real browser.

  **Done when:** BUILDS/windows, macos, linux and web each hold a zip and a BUILD_INFO.json.

  **Done ✅** The builds aren't signed yet: Phase 5.

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

- [ ] **Set up a small website and a support email**  
  _You + Claude_

  **Why:** Needed for the support URL, the privacy policy and terms pages, Google organization verification, and AdMob's app-ads.txt.

  **How:**
  1. A one-page site is enough: about the game, support email, privacy policy, terms.
  2. Claude can make the pages; you own the domain and email.

  **Done when:** The site is live on its own domain with a working support email.

  **Watch out:** Google verifies the site in Search Console: the URL must match exactly.

- [ ] **Decide the PC edition: one price, no ads, no purchases (and its price)**  
  _You · Steam · GOG · itch.io · Epic Games Store_

  **Why:** Steam bans ads (even reward videos); real-money purchases on Steam must use Steam's own system; GOG expects DRM-free premium games.

  **How:**
  1. Recommended: a premium PC edition where everything is earnable by playing.
  2. Pick a price (Valve suggests regional prices).

  **Done when:** Price chosen and noted here.

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

- [ ] **Open an itch.io account and do the tax interview**  
  _You · itch.io · free_

  **Why:** itch.io is the quickest place to publish (no review for free pages), good for an early version or demo.

  **How:**
  1. Payouts: choose 'collected by itch.io, paid later' (PayPal or Payoneer, minimum US$5); do the tax interview.

  **Done when:** The tax interview shows Validated.

  **Official pages:** [Payments](https://itch.io/docs/creators/payments)

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

- [ ] **Add a credits and licences screen**  
  _Claude_

  **Why:** Godot's MIT licence and the fonts' licences require a notice; free-plan Meshy models need credit.

  **How:**
  1. Settings > Credits: Godot notice, font licences, music credit, Meshy credit if the models were free-plan.

  **Done when:** Credits open from Settings.

- [ ] **Answer the age-rating questionnaires (Apple and IARC)**  
  _You_

  **Why:** Unrated games aren't allowed on Google Play or the App Store; IARC also covers Amazon, Samsung, Microsoft and Epic.

  **How:**
  1. Use LAUNCH/shared/content-rating-answers.md.
  2. Apple: also answer the new Shared Location, Dating and social-media questions (all No).

  **Done when:** Both show a rating.

  **Watch out:** Answer honestly about purchases and ads; wrong answers can pull the game later.

  **Official pages:** [Apple age ratings](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/) · [Google content ratings](https://support.google.com/googleplay/android-developer/answer/9859655)

- [ ] **Declare the AI-made 3D models where stores ask**  
  _You · Steam · itch.io · Google Play_

  **Why:** Steam requires it (Content Survey); itch.io has a disclosure field; Google has a per-picture AI label for store art.

  **How:**
  1. Steam: 'Some 3D models were first generated with an AI text-to-3D tool and then adjusted; all other art, audio, code and text were made by people.' (make it accurate)
  2. itch.io: Yes, Graphics.
  3. Epic and Apple don't ask; GOG: tell your Product Manager.

  **Done when:** Each store you use has it declared.

## Phase 4: Game changes the stores require

- [ ] **Build the PC premium edition: no ads, no purchases**  
  _Claude · Steam · GOG · itch.io · Epic Games Store_

  **Why:** Steam bans ads (even reward videos) and real-money purchases outside its own system.

  **How:**
  1. A desktop setting that hides the store's money items and all ads; everything earnable by playing.
  2. Separate from the phone builds.

  **Done when:** The Windows, Mac and Linux builds have no ads and no real-money buttons.

- [ ] **Make it look and play right on monitors and Steam Deck**  
  _Claude · Steam · GOG · itch.io · Epic Games Store_

  **Why:** The game is portrait; on a 16:9 screen it needs side art, and Steam Deck needs text at least 9 px tall at 1280x800 and full controller control.

  **How:**
  1. Side panels or art beside the portrait play area; a sensible default window size.
  2. Fonts at least 20 px on the 720x1280 layout; every menu navigable with a gamepad; Xbox/Deck button icons when a controller is used.

  **Done when:** Playable at 1280x800 with only a controller.

  **Official pages:** [Steam Deck compatibility](https://partner.steamgames.com/doc/steamhardware/compat)

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

- [ ] **Sign and notarize the Mac build**  
  _You + Claude · Steam · GOG · itch.io · Epic Games Store · Mac distribution · needs Apple account_

  **Why:** Steam requires notarized Mac apps, and since macOS 15 people can't easily open un-notarized downloads.

  **How:**
  1. You: a Developer ID Application certificate (.p12) and the API key.
  2. Claude: rcodesign signing and notarization in the release workflow.

  **Done when:** The Mac zip opens on a Mac with no warning.

  **Official pages:** [Notarizing](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

- [ ] **Optional: code-sign the Windows build**  
  _You + Claude · itch.io_

  **Why:** Unsigned downloads from itch.io or your site show 'Windows protected your PC'; Steam, GOG and Epic don't require signing.

  **How:**
  1. A code-signing certificate (max 460 days since Mar 2026) or Azure Artifact Signing; Claude signs with osslsigncode (and stops embedding the game data in the .exe).

  **Done when:** Only if you sell direct downloads.

- [ ] **Upload builds to itch.io (butler)**  
  _You + Claude · itch.io_

  **Why:** butler uploads only what changed and tags the platforms by channel name.

  **How:**
  1. You: create an itch.io API key, add it as the BUTLER_API_KEY secret.
  2. Claude: push windows, mac, linux and html5 channels from the release workflow.

  **Done when:** The itch.io page lists all four.

  **Official pages:** [butler](https://itch.io/docs/butler/pushing.html)

## Phase 6: Store pictures and video

- [ ] **Epic, itch.io and GOG pictures**  
  _Claude · Epic Games Store · itch.io · GOG_

  **Why:** Each store has its own required images.

  **How:**
  1. Epic: 2560x1440 landscape, 1200x1600 portrait, logo 960x540 PNG, 1920x1080 carousel.
  2. itch.io: cover 630x500.
  3. GOG: key art and logo at least 1920x1080 as layered PSD.

  **Done when:** Uploaded where you're publishing.

## Phase 7: Test with real people

- [ ] **Test the PC builds: clean Windows PC, a Mac, Steam Deck size**  
  _You + Claude · Steam · GOG · itch.io · Epic Games Store_

  **Why:** Steam's review now needs 5 minutes of play through Steam and tests on a non-developer PC.

  **How:**
  1. Windows PC without dev tools; a Mac after notarizing; 1280x800 with only a gamepad.
  2. Play 5+ minutes launched from Steam before each build review.

  **Done when:** Works on all three with nothing missing.

- [ ] **Collect bugs and feedback here; Claude fixes them**  
  _You + Claude_

  **Why:** Small bugs found now don't become 1-star reviews later.

  **How:**
  1. Log each report on the Bugs & feedback tab (or forward testers' messages to log).
  2. Claude reads the list, fixes, and you set reports to Fixed after checking.

  **Done when:** No open Crash or Blocks-play reports.

## Phase 8: Submit and get approved

- [ ] **itch.io: publish the page**  
  _You · itch.io_

  **Why:** No review for publishing, but a new seller's first paid game waits in a queue before it shows in search.

  **How:**
  1. Cover image, screenshots, files pushed with butler, price, AI disclosure; set the page Public.

  **Done when:** The page is public and appears in search.

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
