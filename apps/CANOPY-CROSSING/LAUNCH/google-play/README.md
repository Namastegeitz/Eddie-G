# **CANOPY CROSSING: GOOGLE PLAY**

Steps for Google Play (and the ones every store needs). Live checklist: https://claude.ai/artifact/W8GbYN7jifz6X6fRE4QSNR

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

- [x] ✅ **Target Android API 36 for Google Play**  
  _Claude · Google Play_

  **Why:** Since 31 Aug 2026 Google Play only accepts new apps and updates that target API 36; the Play Store build was set to 35.

  **How:**
  1. Set the Android AAB preset's target SDK to 36 (Godot 4.7.2 builds with SDK 36).

  **Done when:** export_presets.cfg says target_sdk 36.

  **Done ✅** Google will raise it again around August 2027.

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

- [ ] **Open a Google Play developer account**  
  _You · Google Play · US$25 once_

  **Why:** Needed to publish on Google Play (and to register the package for Android developer verification).

  **How:**
  1. Personal (ID check, verify an Android phone) or Organization (D-U-N-S, website verified in Search Console).
  2. The names on the account, payments profile and ID must match exactly.

  **Done when:** Play Console opens and the account is verified.

  **Watch out:** Personal accounts must run a closed test with 12 testers for 14 days before going public.

  **Official pages:** [Sign up](https://support.google.com/googleplay/android-developer/answer/6112435)

- [ ] **Set up Google's payments profile (merchant account)**  
  _You · Google Play_

  **Why:** You can't create in-app products without it.

  **How:**
  1. Play Console > Monetize with Play > Products: legal name, address (no P.O. box), bank in the same country, tax info.

  **Done when:** The products page lets you create an in-app product.

  **Official pages:** [Payments profile](https://support.google.com/googleplay/android-developer/answer/7161426)

- [ ] **Declare trader status in Play Console (deadline 1 Feb 2027)**  
  _You · Google Play_

  **Why:** Every account must declare it by 1 Feb 2027 or updates get blocked; a game that sells purchases is a trader.

  **How:**
  1. Account details > About you, then per app under App content; traders add contact details and a terms-of-service link per app.

  **Done when:** Declared.

  **Watch out:** Declaring 'non-trader' to skip verification can get the account suspended.

  **Official pages:** [Trader status](https://support.google.com/googleplay/android-developer/answer/17594752)

- [ ] **Create the app in Play Console**  
  _You · Google Play_

  **Why:** Registers com.aethertek.canopycrossing to you (Android developer verification) and opens all the App content forms.

  **How:**
  1. Create app: name, default language, Game, Free.
  2. Check the package shows as registered on the developer verification page.

  **Done when:** The app's dashboard opens.

  **Official pages:** [Developer verification](https://developer.android.com/developer-verification)

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

- [ ] **Add a credits and licences screen**  
  _Claude_

  **Why:** Godot's MIT licence and the fonts' licences require a notice; free-plan Meshy models need credit.

  **How:**
  1. Settings > Credits: Godot notice, font licences, music credit, Meshy credit if the models were free-plan.

  **Done when:** Credits open from Settings.

- [ ] **Fill in Google's Data safety form**  
  _You · Google Play_

  **Why:** Mandatory even if nothing is collected; it must match the privacy policy and every SDK.

  **How:**
  1. Use the table in LAUNCH/google-play/requirements.md, section 2.2.

  **Done when:** Data safety shows Completed.

  **Watch out:** A mismatch with AdMob's real data collection is a classic rejection.

  **Official pages:** [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)

- [ ] **Answer the age-rating questionnaires (Apple and IARC)**  
  _You_

  **Why:** Unrated games aren't allowed on Google Play or the App Store; IARC also covers Amazon, Samsung, Microsoft and Epic.

  **How:**
  1. Use LAUNCH/shared/content-rating-answers.md.
  2. Apple: also answer the new Shared Location, Dating and social-media questions (all No).

  **Done when:** Both show a rating.

  **Watch out:** Answer honestly about purchases and ads; wrong answers can pull the game later.

  **Official pages:** [Apple age ratings](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/) · [Google content ratings](https://support.google.com/googleplay/android-developer/answer/9859655)

- [ ] **If children may play: age question, child-safe ads, legal check**  
  _You + Claude · Apple App Store · Google Play_

  **Why:** Google's Families policy and the amended US COPPA rule apply to games children play.

  **How:**
  1. Claude adds a neutral age question and child-directed ad settings (G-rated, no personalised ads) if you use ads.
  2. Get legal advice before turning ads on.

  **Done when:** Done, or not needed because you chose 13+ or no ads.

- [ ] **Declare the AI-made 3D models where stores ask**  
  _You · Steam · itch.io · Google Play_

  **Why:** Steam requires it (Content Survey); itch.io has a disclosure field; Google has a per-picture AI label for store art.

  **How:**
  1. Steam: 'Some 3D models were first generated with an AI text-to-3D tool and then adjusted; all other art, audio, code and text were made by people.' (make it accurate)
  2. itch.io: Yes, Graphics.
  3. Epic and Apple don't ask; GOG: tell your Product Manager.

  **Done when:** Each store you use has it declared.

## Phase 4: Game changes the stores require

- [ ] **Real Google Play purchases instead of the sandbox**  
  _Claude · Google Play_

  **Why:** Today purchases open a sandbox sheet; Google rejects games whose purchases don't work, and needs Play Billing Library 8 or newer.

  **How:**
  1. Add GodotGooglePlayBilling 3.3.0 (Play Billing 9.1) to the Android build.
  2. Grant items only when paid, confirm each purchase within 3 days, restore on start.
  3. Test with license testers (Phase 7).

  **Done when:** A license tester buys a map pack, reinstalls, and Restore brings it back.

  **Watch out:** Unconfirmed purchases are refunded automatically after 3 days.

  **Official pages:** [Billing plugin](https://github.com/godot-sdk-integrations/godot-google-play-billing)

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

## Phase 6: Store pictures and video

- [ ] **Google Play icon, feature graphic and screenshots**  
  _Claude · Google Play_

  **Why:** The 1024x500 feature graphic is required; 3+ portrait screenshots at 1080x1920 make games eligible for promotion.

  **How:**
  1. Icon 512x512 PNG (no rounded corners: Play adds them).
  2. Feature graphic 1024x500, no transparency.
  3. Phone screenshots 1080x1920 (3-8); 7- and 10-inch tablet screenshots.

  **Done when:** The store listing page shows no missing items.

  **Official pages:** [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151)

## Phase 7: Test with real people

- [ ] **Google Play internal testing with license testers**  
  _You + Claude · Google Play_

  **Why:** The only way to test real Play purchases with test cards, before strangers see the game.

  **How:**
  1. Upload the .aab to Internal testing; add up to 100 testers.
  2. Setup > License testing: add testers so purchases use test cards.

  **Done when:** A tester buys and restores something.

- [ ] **Google Play closed test: 12 testers for 14 days (personal accounts)**  
  _You · Google Play · 14 days minimum_

  **Why:** New personal accounts can't go public until 12 testers have stayed opted in for 14 days straight.

  **How:**
  1. Closed testing track with an email list or Google Group; recruit at least 12 (aim for 15+ in case some drop).
  2. Ask them to play a few times and log feedback on this page.
  3. Then Apply for production (questions about your testing).

  **Done when:** Production access granted.

  **Watch out:** A tester dropping out restarts the count.

  **Official pages:** [Testing requirement](https://support.google.com/googleplay/android-developer/answer/14151465)

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

- [ ] **Google Play: send for review and go live**  
  _You · Google Play · up to 7 days_

  **Why:** Reviews are usually hours to days, up to 7+ for new accounts.

  **How:**
  1. All App content forms done, store listing done, countries chosen, products active, .aab on the production track.
  2. Turn on managed publishing to choose the exact go-live moment.

  **Done when:** Status: Published.

  **Official pages:** [Publishing overview](https://support.google.com/googleplay/android-developer/answer/9859751)

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
