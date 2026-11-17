# **CANOPY CROSSING: STORE LAUNCH CHECKLIST**

**13 of 90 steps done (14%)** · snapshot 2026-11-17

**Live checklist (tick steps, log bugs, see builds):** https://claude.ai/artifact/W8GbYN7jifz6X6fRE4QSNR

Every step to publish Canopy Crossing on the Apple App Store, Google Play, Amazon, Samsung,
Steam, GOG, itch.io and Epic, in order. A ✅ means the step is done. The live page is the
real-time version: tick a step there and it turns green for everyone, with notes; this
file is a snapshot of it (`python3 tools/launch_docs.py` after exporting the page's
progress refreshes it). Each step says why it matters, how to do it, what "done" looks
like, the usual mistakes, and the official page to check.

**Requirements researched:** 17 Nov 2026, from Apple, Google, Amazon, Samsung, Valve, GOG, itch.io, Epic and Microsoft pages, checked against the project as it is today. Store rules change; each step links
the official page to re-check on the day you do it.

> **Next step:** Decide who publishes: you as a person, or a company (e.g. Aethertek)  
> It decides the seller name on every store, the paperwork, and whether your home address is shown.

## Folders

| Folder | What's there |
|---|---|
| [`../BUILDS/`](../BUILDS/) | one folder per platform: android, ios, windows, macos, linux, web |
| [`apple-app-store/`](apple-app-store/) | Apple App Store: its steps and researched requirements |
| [`google-play/`](google-play/) | Google Play: its steps and researched requirements |
| [`amazon-samsung/`](amazon-samsung/) | Amazon Appstore + Samsung Galaxy Store: its steps and researched requirements |
| [`steam/`](steam/) | Steam: its steps and researched requirements |
| [`gog/`](gog/) | GOG: its steps and researched requirements |
| [`itch-io/`](itch-io/) | itch.io: its steps and researched requirements |
| [`epic/`](epic/) | Epic Games Store + Microsoft Store: its steps and researched requirements |
| [`shared/`](shared/) | store text, privacy policy, in-app products, content-rating answers, asset sizes |

## Phases

- [Phase 0: Set up the project for launch](#phase-0-set-up-the-project-for-launch): 13/13
- [Phase 1: Decide](#phase-1-decide): 0/8
- [Phase 2: Accounts, contracts and money](#phase-2-accounts-contracts-and-money): 0/16
- [Phase 3: Legal and privacy](#phase-3-legal-and-privacy): 0/10
- [Phase 4: Game changes the stores require](#phase-4-game-changes-the-stores-require): 0/11
- [Phase 5: Signing and store builds](#phase-5-signing-and-store-builds): 0/8
- [Phase 6: Store pictures and video](#phase-6-store-pictures-and-video): 0/6
- [Phase 7: Test with real people](#phase-7-test-with-real-people): 0/6
- [Phase 8: Submit and get approved](#phase-8-submit-and-get-approved): 0/8
- [Phase 9: Launch and keep it running](#phase-9-launch-and-keep-it-running): 0/4

## Phase 0: Set up the project for launch

_13 of 13 done._ One folder for everything, builds for every platform, the research and the paperwork drafts. Claude did these today.

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

- [x] ✅ **Target Android API 36 for Google Play**  
  _Claude · Google Play_

  **Why:** Since 31 Aug 2026 Google Play only accepts new apps and updates that target API 36; the Play Store build was set to 35.

  **How:**
  1. Set the Android AAB preset's target SDK to 36 (Godot 4.7.2 builds with SDK 36).

  **Done when:** export_presets.cfg says target_sdk 36.

  **Done ✅** Google will raise it again around August 2027.

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

_0 of 8 done._ A few choices that change everything after them. Decide these first; Claude can explain any of them.

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

_0 of 16 done._ Open each store account, sign the paid agreements, and add tax and bank details. Only you can do these.

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

- [ ] **Open a Steamworks account and pay the app fee**  
  _You · Steam · US$100 per game · 15-30 days paperwork_

  **Why:** The fee starts Steam's waiting clock (about 30 days before you can release), so start early.

  **How:**
  1. partner.steamgames.com with a Steam account that has Steam Guard and a phone number.
  2. Pay the Steam Direct fee; it's paid back after US$1,000 in sales.

  **Done when:** You have an app id.

  **Watch out:** Without a phone on the account you can't set builds live later.

  **Official pages:** [Steam Direct fee](https://partner.steamgames.com/doc/gettingstarted/appfee)

- [ ] **Complete Steam's tax and bank forms**  
  _You · Steam_

  **Why:** Steam won't release a game or pay you until these are verified.

  **How:**
  1. Legal details, bank (holder name must match), tax questionnaire (W-9 or W-8BEN).

  **Done when:** Steamworks shows onboarding complete.

  **Official pages:** [Onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding)

- [ ] **Open an itch.io account and do the tax interview**  
  _You · itch.io · free_

  **Why:** itch.io is the quickest place to publish (no review for free pages), good for an early version or demo.

  **How:**
  1. Payouts: choose 'collected by itch.io, paid later' (PayPal or Payoneer, minimum US$5); do the tax interview.

  **Done when:** The tax interview shows Validated.

  **Official pages:** [Payments](https://itch.io/docs/creators/payments)

- [ ] **Open an Epic Games Store publisher account**  
  _You · Epic Games Store · US$100 per game · verification 2+ weeks_

  **Why:** Epic pays 100% of the first US$1M each year, but verification takes weeks and blocks final review.

  **How:**
  1. Developer Portal: organization, Distribution Agreement, tax interview, Hyperwallet payouts.

  **Done when:** Organization verified.

  **Watch out:** Epic needs every patch no later than other stores.

  **Official pages:** [Onboarding](https://dev.epicgames.com/docs/epic-games-store/get-started/get-started-steps/onboarding)

- [ ] **Submit Canopy Crossing to GOG for consideration (when nearly finished)**  
  _You · GOG_

  **Why:** GOG is curated: they decide whether to sign the game, and want to see it close to finished.

  **How:**
  1. Fill in the form at gog.com/indie (about 15 questions, free).
  2. If accepted, agree the revenue split in writing (70/30 is their starting point).

  **Done when:** GOG replies with a Product Manager and contract.

  **Official pages:** [Submit your game](https://www.gog.com/indie)

- [ ] **Optional: Amazon Appstore and Samsung Galaxy Store accounts**  
  _You · Amazon Appstore_

  **Why:** Amazon now only reaches existing Fire tablets (new Alexa tablets use Google Play); Samsung reaches Galaxy phones. Each needs its own payment system in the game.

  **How:**
  1. Amazon: free account, tax interview, bank.
  2. Samsung Seller Portal: commercial seller status (bank verification up to 10 business days).

  **Done when:** Accounts open, or you've decided to skip them.

  **Watch out:** Both need a custom payment plugin; leave them until Google and Apple are live.

## Phase 3: Legal and privacy

_0 of 10 done._ The pages, answers and in-game links every store checks before approving.

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

- [ ] **Answer Apple's App Privacy questions**  
  _You · Apple App Store_

  **Why:** Required for every submission; shown as the privacy label on the store page.

  **How:**
  1. Without ads: Data Not Collected (everything stays on the device).
  2. With AdMob: Device ID, Advertising Data, Product Interaction, Coarse Location, Diagnostics.

  **Done when:** App Privacy shows Published.

  **Watch out:** Saying you track without ever showing Apple's tracking prompt is a common rejection.

  **Official pages:** [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)

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

- [ ] **Declare the AI-made 3D models where stores ask**  
  _You · Steam · itch.io · Google Play_

  **Why:** Steam requires it (Content Survey); itch.io has a disclosure field; Google has a per-picture AI label for store art.

  **How:**
  1. Steam: 'Some 3D models were first generated with an AI text-to-3D tool and then adjusted; all other art, audio, code and text were made by people.' (make it accurate)
  2. itch.io: Yes, Graphics.
  3. Epic and Apple don't ask; GOG: tell your Product Manager.

  **Done when:** Each store you use has it declared.

## Phase 4: Game changes the stores require

_0 of 11 done._ Things the stores check inside the game. Claude does these once you've made the Phase 1 decisions.

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

- [ ] **Use a stable save folder (for Steam and GOG cloud saves)**  
  _Claude · Steam · GOG_

  **Why:** Cloud saves work without code if saves sit in their own fixed folder.

  **How:**
  1. Turn on Godot's custom user directory (e.g. CanopyCrossing).

  **Done when:** Saves land in the same named folder on Windows, Mac and Linux.

- [ ] **Check Android 16 behaviour and 16 KB pages**  
  _You + Claude · Google Play · Amazon Appstore_

  **Why:** Android 16 changed the back gesture and edge-to-edge drawing; Google blocks updates without 16 KB page support from 1 Feb 2027.

  **How:**
  1. Claude verifies the .aab's 16 KB alignment in CI.
  2. You test the back gesture and screen edges on an Android 16 phone.

  **Done when:** Back exits/pauses correctly; nothing is hidden under the screen edges; alignment check passes.

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

- [ ] **Optional: separate Android builds for Amazon and Samsung**  
  _Claude · Amazon Appstore_

  **Why:** Each Android store needs its own payment system (one per APK); neither has a Godot plugin.

  **How:**
  1. Write small Android plugins for Amazon IAP and Samsung IAP; a build per store.

  **Done when:** Only if you chose those stores.

## Phase 5: Signing and store builds

_0 of 8 done._ Turn the builds into ones each store accepts: signed, notarized, uploaded.

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

- [ ] **Build and upload iOS from GitHub (no Mac needed)**  
  _You + Claude · Apple App Store · needs Apple account_

  **Why:** The .ipa must be built and signed on macOS; GitHub's Mac machines can do it.

  **How:**
  1. You: create an Apple Distribution certificate and App Store provisioning profile (or let the CI create them with the API key); add the secrets.
  2. Claude: a macOS job that exports with Godot, archives with Xcode 26, and uploads to TestFlight.

  **Done when:** A build appears in TestFlight.

  **Watch out:** Uploads must be built with Xcode 26 now and Xcode 27 from April 2027.

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

- [ ] **Upload builds to Steam (SteamPipe)**  
  _You + Claude · Steam_

  **Why:** Steam takes builds through steamcmd depots.

  **How:**
  1. Claude writes the app/depot scripts (Windows, Mac, Linux) and a CI step.
  2. You add a builder account's login as a secret, and set builds live in Steamworks (needs SMS).

  **Done when:** A build shows in Steamworks on a test branch.

  **Official pages:** [Uploading](https://partner.steamgames.com/doc/sdk/uploading)

- [ ] **Upload builds to itch.io (butler)**  
  _You + Claude · itch.io_

  **Why:** butler uploads only what changed and tags the platforms by channel name.

  **How:**
  1. You: create an itch.io API key, add it as the BUTLER_API_KEY secret.
  2. Claude: push windows, mac, linux and html5 channels from the release workflow.

  **Done when:** The itch.io page lists all four.

  **Official pages:** [butler](https://itch.io/docs/butler/pushing.html)

- [ ] **Upload to GOG (Pipeline Builder) and Epic (BuildPatch Tool)**  
  _You + Claude · GOG · Epic Games Store_

  **Why:** Each has its own upload tool; Epic takes Windows and Mac only.

  **How:**
  1. GOG: after acceptance, Pipeline Builder to a private branch.
  2. Epic: BuildPatch Tool with a unique BuildVersion per upload.

  **Done when:** Builds show in each portal.

## Phase 6: Store pictures and video

_0 of 6 done._ Screenshots, icons, capsules and trailers at each store's exact sizes. Claude can render most of them from the game; you approve.

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

- [ ] **Google Play icon, feature graphic and screenshots**  
  _Claude · Google Play_

  **Why:** The 1024x500 feature graphic is required; 3+ portrait screenshots at 1080x1920 make games eligible for promotion.

  **How:**
  1. Icon 512x512 PNG (no rounded corners: Play adds them).
  2. Feature graphic 1024x500, no transparency.
  3. Phone screenshots 1080x1920 (3-8); 7- and 10-inch tablet screenshots.

  **Done when:** The store listing page shows no missing items.

  **Official pages:** [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151)

- [ ] **Steam capsules, library art and 5+ screenshots**  
  _Claude · Steam_

  **Why:** Steam requires the full set before the store page review.

  **How:**
  1. Header 920x430, small 462x174, main 1232x706, vertical 748x896, library 600x900, library header 920x430, hero 3840x1240 (no text), logo PNG 1280 wide, icons 256x256 and 184x184.
  2. At least 5 gameplay screenshots at 1920x1080 showing the real wide-screen layout.

  **Done when:** Steamworks shows every graphic uploaded.

  **Watch out:** No review scores, awards or discount text on capsules.

  **Official pages:** [Store graphics](https://partner.steamgames.com/doc/store/assets)

- [ ] **A 16:9 trailer for Steam, Epic and GOG**  
  _Claude · Steam · Epic Games Store · GOG_

  **Why:** Trailers sell PC games; Epic wants at least one video; GOG wants its logo on the end card.

  **How:**
  1. 1920x1080, H.264 + AAC, 30 or 60 fps: gameplay first, plus moments from 'The Bee and the Giraffe'.
  2. A GOG version with the GOG.com logo at the end.

  **Done when:** Uploaded where needed.

- [ ] **Epic, itch.io and GOG pictures**  
  _Claude · Epic Games Store · itch.io · GOG_

  **Why:** Each store has its own required images.

  **How:**
  1. Epic: 2560x1440 landscape, 1200x1600 portrait, logo 960x540 PNG, 1920x1080 carousel.
  2. itch.io: cover 630x500.
  3. GOG: key art and logo at least 1920x1080 as layered PSD.

  **Done when:** Uploaded where you're publishing.

## Phase 7: Test with real people

_0 of 6 done._ Catch problems before the reviewers do, and meet Google's testing rule.

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

_0 of 8 done._ Send each store the finished listing and build, and answer their reviewers.

- [ ] **Google Play: send for review and go live**  
  _You · Google Play · up to 7 days_

  **Why:** Reviews are usually hours to days, up to 7+ for new accounts.

  **How:**
  1. All App content forms done, store listing done, countries chosen, products active, .aab on the production track.
  2. Turn on managed publishing to choose the exact go-live moment.

  **Done when:** Status: Published.

  **Official pages:** [Publishing overview](https://support.google.com/googleplay/android-developer/answer/9859751)

- [ ] **App Store: submit the app and its first in-app purchases**  
  _You · Apple App Store · usually 24-48 h_

  **Why:** The first purchase of each type must go in the same submission as the app.

  **How:**
  1. Version page complete; add the in-app products (each needs a review screenshot).
  2. Review notes: how to reach the store, what each purchase unlocks, that Amber never expires, how Restore works, no loot boxes.

  **Done when:** Status: Ready for Distribution.

  **Watch out:** Common rejections: purchases not working, no in-app privacy link, metadata naming other games.

  **Official pages:** [App Review](https://developer.apple.com/distribute/app-review/)

- [ ] **Steam: store page review, then Coming Soon for 2+ weeks**  
  _You · Steam · up to 12 business days + 2 weeks_

  **Why:** Steam reviews the page first, and it must be public as Coming Soon for at least 2 weeks before release.

  **How:**
  1. Submit the page (description, tags, languages, system requirements, Content Survey, price, art).
  2. Once approved, publish it as Coming Soon; optionally open a Playtest.

  **Done when:** The Coming Soon page is live.

  **Official pages:** [Review process](https://partner.steamgames.com/doc/store/review_process)

- [ ] **Steam: build review and release**  
  _You · Steam · up to 12 business days_

  **Why:** Valve checks the build starts on every listed system and that everything on the page exists.

  **How:**
  1. Play at least 5 minutes launched from Steam within 7 days before submitting.
  2. After approval and the waiting periods, press Release (optional launch discount 10-40%).

  **Done when:** Released on Steam.

- [ ] **GOG: deliver the release candidate 3-5 days before launch**  
  _You · GOG_

  **Why:** GOG's QA tests every build, including without the Galaxy client.

  **How:**
  1. Upload the release candidate and tell your Product Manager; agree the date together.

  **Done when:** Live on GOG with offline installers.

- [ ] **itch.io: publish the page**  
  _You · itch.io_

  **Why:** No review for publishing, but a new seller's first paid game waits in a queue before it shows in search.

  **How:**
  1. Cover image, screenshots, files pushed with butler, price, AI disclosure; set the page Public.

  **Done when:** The page is public and appears in search.

- [ ] **Epic: product page, then final review**  
  _You · Epic Games Store_

  **Why:** Epic needs the page reviewed first and a build attached at least a week before the release date.

  **How:**
  1. Publish the product home page (about a week); set up the offer and binaries; submit for final review.

  **Done when:** Released on Epic.

- [ ] **Optional: Amazon and Samsung submissions**  
  _You · Amazon Appstore_

  **Why:** Only after their payment plugins are built.

  **How:**
  1. Amazon: APK upload, 3-10 screenshots, rating questionnaire.
  2. Samsung: Seller Portal, exclude Vietnam, age rating.

  **Done when:** Live, or skipped.

## Phase 9: Launch and keep it running

_0 of 4 done._ Launch day, then the recurring deadlines that keep the game on sale.

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

## Bugs and feedback

Log bugs and how the game feels on the live page's **Bugs & feedback** tab (kind, how bad,
device, view, where, steps). Claude reads that list to fix them; set a report to *Fixed* once
you've checked the fix. Testers who aren't on the page can send reports to you to log.
