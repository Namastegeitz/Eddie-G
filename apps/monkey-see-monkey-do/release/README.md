# **MONKEY SEE, MONKEY DO** · Launch checklist

From beta to the App Store, Google Play, Steam, GOG, itch.io and more.

| | |
|---|---|
| **Live checklist** (tick steps, see tips, progress log) | https://claude.ai/artifact/Kz4xL5JoZfgC9bDzBAtQ1Y |
| **Bug & feedback reports** (testers write here) | https://claude.ai/artifact/NiybkudZiDL75qvRyHvHuC |
| **Playable game** (private) | https://claude.ai/artifact/6ARndyKdPDcqbRxZ7ohyMY |
| **Public beta link** (after GitHub Pages is on) | https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/ |

All three pages are in the **MONKEY SEE, MONKEY DO** folder on your claude.ai Artifacts screen.

> This file mirrors the live checklist. You tick steps on the live page; Claude
> ticks its own and copies the progress here (ask Claude to *sync the checklist*).
> Last synced: 2026-11-17.

## Progress

**26% done** 🟩🟩🟩⬜⬜⬜⬜⬜⬜⬜ · 17 of 72 steps
(65 required, 7 optional) · waiting on you: **22** · Claude's queue: **9**

| Phase | Progress | Cost | Folder |
|---|---|---|---|
| [Project home](#project-home) | ✅ 5/5 | Free | `release/01-web-beta` |
| [Beta test](#beta-test) | 0/6 | Free | `release/01-web-beta` |
| [Store kit (used by every store)](#store-kit-used-by-every-store) | 6/11 | Free | `release/00-shared` |
| [Google Play (Android)](#google-play-android) | 1/11 | $25 once | `release/03-google-play` |
| [Apple App Store (iPhone and iPad)](#apple-app-store-iphone-and-ipad) | 0/12 | $99 per year | `release/04-apple-app-store` |
| [itch.io (web and PC, fastest store)](#itchio-web-and-pc-fastest-store) | 1/4 | Free | `release/02-itch-io` |
| [PC edition (Windows, Mac, Linux)](#pc-edition-windows-mac-linux) | 2/4 | Free (signing optional) | `release/05-desktop` |
| [Steam](#steam) | 1/6 | $100 per game (Steam Direct) | `release/06-steam` |
| [GOG](#gog) | 1/3 | Free to submit (GOG takes a revenue share if accepted) | `release/07-gog` |
| [More stores (optional)](#more-stores-optional) | 0/4 (optional) | Microsoft free, Epic $100, Samsung and Amazon free | `release/08-more-stores` |
| [Launch and after](#launch-and-after) | 0/3 | Free | `release` |

Legend: ✅ done · 🔄 working on it · ⬜ to do · ⏭️ skipped. Owner: **You**, **Claude**, or **You + Claude**.

## Up next

**Your next steps**
- ⬜ **Recruit 12 or more testers** (Beta test). Ask 15-16 people: some always drop out, and Google counts only testers who stay opted in for all 14 days.
- ⬜ **Send testers the beta link** (Beta test). Give them three concrete asks: finish levels 1-5, play with a game controller or keyboard if they have one, open the Wardrobe.
- ⬜ **Invite testers to the Bug & Feedback page** (Beta test). If a tester has no Claude account, ask them to text you instead and type their report in yourself: it takes 30 seconds.
- ⬜ **Real-device pass: iPhone, Android, tablet, computer** (Beta test). On older phones, check Settings > Graphics: Auto should drop to Medium or Low by itself within a few seconds.

**Claude's next steps**
- 🔄 **Support page and contact** (Store kit (used by every store))
- 🔄 **Store text: names, descriptions, keywords** (Store kit (used by every store))
- 🔄 **Age-rating answers** (Store kit (used by every store))

## Project home

Everything for the game in one place, and a link anyone can play.

**5/5** 🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩 · Cost: Free · Folder: [`release/01-web-beta`](./01-web-beta)

- [x] ✅ **Project folder on your Artifacts screen** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** One place for the game, this checklist and the bug reports.

  1. Folder MONKEY SEE, MONKEY DO on claude.ai > Artifacts.
  2. The playable game, this checklist and the Bug & Feedback page live inside it.

  **Tip:** Keep new pages for this game in the same folder so nothing gets lost.

  **Done when:** The folder exists and holds the game.
  </details>

- [x] ✅ **Playable game link (Claude page)** · Claude · done by Claude 2026-11-06
  <details><summary>How to do it</summary>

  **Why:** A private link you can open on any device right now.

  1. Open the 'Monkey See, Monkey Do' page in the folder.
  2. Add #store-test to the end of its link to try the Shop with pretend purchases.

  **Tip:** This one is private to you. Testers use the public beta link below.

  **Done when:** The page opens and plays.
  </details>

- [x] ✅ **Public beta website built** · Claude · done by Claude 2026-11-17
  - Note: Rebuilt for its own folder on the GitHub Pages site; 13 checks pass on iPhone, Android and desktop.
  <details><summary>How to do it</summary>

  **Why:** Testers need a normal web link: no account, works on every phone and computer, plays offline, can be added to the home screen.

  1. Every web build makes the beta website in dist/site: the game in play/, with a landing page (Play button, QR code, tester notes) in front of it.
  2. Privacy and support pages come with it.

  **Tip:** Nothing to do here: it updates itself whenever the game is rebuilt.

  **Done when:** dist/site holds the landing page and the game, tested offline.
  </details>

- [x] ✅ **Put the beta website on GitHub Pages** · Claude · done by Claude 2026-11-17
  - Note: Live at https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/ (its own folder on the GitHub Pages site; the Off-Grid Survival Kit is unchanged).
  <details><summary>How to do it</summary>

  **Why:** A free public web address that works on every phone and computer.

  1. GitHub Pages was already on for this repository: it serves the gh-pages branch, home of the Off-Grid Survival Kit.
  2. The game gets its own monkey-see-monkey-do/ folder there. bash scripts/deploy_beta.sh publishes it and never touches the Off-Grid files.

  **Tip:** Nothing to switch on. (GitHub's Pages settings page shows a 404 unless you are signed in as the repository owner.)

  **Done when:** https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/ shows the landing page.

  **Links:** [Beta link](https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/)
  </details>

- [x] ✅ **Claude checks the live beta link** · Claude · done by Claude 2026-11-17
  - Note: 13/13 on the live link as iPhone, Android and desktop: landing, QR, Play, a round of level 1, privacy, support, reopens offline; Off-Grid still works.
  <details><summary>How to do it</summary>

  **Why:** So you never send testers a broken link.

  1. Claude opens the link as an iPhone, an Android phone and a desktop browser.
  2. Checks the game starts, a level plays and it reopens offline.

  **Tip:** Claude re-checks the link after each new beta build.

  **Done when:** All three pass.
  </details>

## Beta test

Real people on real phones find the small bugs before any store reviewer does.

**0/6** ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜ · Cost: Free · Folder: [`release/01-web-beta`](./01-web-beta)

- [ ] ⬜ **Recruit 12 or more testers** · You
  <details><summary>How to do it</summary>

  **Why:** Google Play makes new personal accounts run a closed test with at least 12 testers for 14 days in a row. Recruit them now and use the same group for both.

  1. Aim for a mix: iPhone, Android (including an older one), a tablet, a computer.
  2. Include at least two kids in the target age, with a parent present.
  3. Write down each tester's Google account email (needed for the Play closed test later).

  **Tip:** Ask 15-16 people: some always drop out, and Google counts only testers who stay opted in for all 14 days.

  **Done when:** 12+ people said yes and you have their emails.
  </details>

- [ ] ⬜ **Send testers the beta link** · You
  <details><summary>How to do it</summary>

  **Why:** One link works on every device, no install.

  1. Send https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/ (or the QR code in release/01-web-beta/qr.png).
  2. Ask them to play for 15 minutes on two different days.

  **Tip:** Give them three concrete asks: finish levels 1-5, play with a game controller or keyboard if they have one, open the Wardrobe.

  **Done when:** Everyone has the link.
  </details>

- [ ] ⬜ **Invite testers to the Bug & Feedback page** · You
  <details><summary>How to do it</summary>

  **Why:** Reports land in one place, with the device details filled in, and Claude can read them and fix bugs.

  1. Open 'Monkey Do Bug & Feedback' in the project folder.
  2. Share > invite each tester by email as Editor (the only level that lets people outside an organization write).
  3. Testers can only add to their own reports; only you change a report's status.

  **Tip:** If a tester has no Claude account, ask them to text you instead and type their report in yourself: it takes 30 seconds.

  **Done when:** At least 3 reports are in.
  </details>

- [ ] ⬜ **Real-device pass: iPhone, Android, tablet, computer** · You
  <details><summary>How to do it</summary>

  **Why:** Touch feel, sound timing and speed can only be judged on real hardware.

  1. On each device: play levels 1-3, a beach and a moon level, Endless for 5 rounds.
  2. Try Add to Home Screen, then play with Wi-Fi off.
  3. Note anything that feels slow, laggy or confusing as a report.

  **Tip:** On older phones, check Settings > Graphics: Auto should drop to Medium or Low by itself within a few seconds.

  **Done when:** Each of the four device types played a full session.
  </details>

- [ ] ⬜ **Fix the minor bugs from reports** · Claude
  - After: Invite testers to the Bug & Feedback page
  <details><summary>How to do it</summary>

  **Why:** Small fixes now avoid one-star reviews later.

  1. Claude reads the Bug & Feedback page, reproduces each bug, fixes it, runs all tests, and marks it Fixed with a note.

  **Tip:** Ask Claude 'check the bug reports' any time; it reads them directly.

  **Done when:** No open Minor or Major reports older than a week.
  </details>

- [ ] ⬜ **Beta sign-off** · You
  - After: Fix the minor bugs from reports; Real-device pass: iPhone, Android, tablet, computer
  <details><summary>How to do it</summary>

  **Why:** A clear go/no-go before paying any store fees.

  1. No open Crash or Major reports.
  2. Average fun rating 4 or higher.
  3. You'd be happy for a stranger to download it today.

  **Tip:** If the fun rating is low, read the 'Confusing' reports first: they usually point at one unclear screen.

  **Done when:** You tick this box.
  </details>

## Store kit (used by every store)

Write it once, paste it everywhere: icons, screenshots, text, policies, ratings.

**6/11** 🟩🟩🟩🟩🟩⬜⬜⬜⬜⬜ · Cost: Free · Folder: [`release/00-shared`](./00-shared)

- [ ] ⬜ **Check the name is free to use** · You
  <details><summary>How to do it</summary>

  **Why:** A name clash can get the app pulled after launch.

  1. Search 'Monkey See Monkey Do' on the App Store, Google Play, Steam and itch.io.
  2. Search the US trademark database (tmsearch.uspto.gov) for game titles.
  3. If crowded, keep 'Monkey See, Monkey Do' as the title and use 'Monkey Do' as the short name (already the home-screen name).

  **Tip:** Store titles can add a short tag that also helps search, e.g. 'Monkey See, Monkey Do: Dance' (30 characters max on both mobile stores).

  **Done when:** You picked the final title.

  **Links:** [USPTO trademark search](https://tmsearch.uspto.gov/)
  </details>

- [x] ✅ **Public privacy policy page** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** Apple, Google, Steam and Microsoft all ask for a privacy policy link.

  1. Published with the beta site (from PRIVACY.md).

  **Tip:** Live: https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/privacy.html

  **Done when:** The page is online.
  </details>

- [ ] 🔄 **Support page and contact** · You + Claude · in progress
  - Note: Support page built (support.html on the beta site). Choose a contact email (release/config.json).
  <details><summary>How to do it</summary>

  **Why:** Apple requires a support URL; every store shows a contact.

  1. Claude built /support.html (FAQ + how to report a problem).
  2. You choose a contact email to show on it (a new address just for the game is a good idea).

  **Tip:** Use a dedicated address, e.g. monkeydo.support@gmail.com, so store mail doesn't flood your personal inbox.

  **Done when:** The support page shows your chosen contact.
  </details>

- [x] ✅ **Store icons (1024 and 512 px)** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** Apple needs 1024x1024 without transparency; Google Play needs 512x512.

  1. Generated into release/00-shared/icons from the game's icon.

  **Tip:** Don't add words or a border: stores round the corners themselves.

  **Done when:** Both PNGs exist at exact sizes.
  </details>

- [x] ✅ **Phone screenshots at store sizes** · Claude · done by Claude 2026-11-17
  - Note: iPhone 6.9" x6, Android x5, Shop review shot
  <details><summary>How to do it</summary>

  **Why:** Apple needs 6.9-inch iPhone (1320x2868); Google Play needs 2-8 phone shots.

  1. Rendered from the real game into release/00-shared/screenshots (title, watch, your turn, moon, disco, wardrobe).

  **Tip:** The first two screenshots sell the game: they show the dancing monkey and the copy buttons.

  **Done when:** Six phone shots at 1320x2868 and 1080x1920.
  </details>

- [x] ✅ **Tablet screenshots** · Claude · done by Claude 2026-11-17
  - Note: iPad 13" x4
  <details><summary>How to do it</summary>

  **Why:** The iPad app needs 13-inch iPad shots (2064x2752); Play shows tablet shots on tablets.

  1. Rendered into release/00-shared/screenshots/ipad-13.

  **Tip:** If you ever turn off iPad support, Apple stops asking for these.

  **Done when:** Three tablet shots at 2064x2752.
  </details>

- [x] ✅ **Desktop screenshots (1920x1080)** · Claude · done by Claude 2026-11-17
  - Note: Desktop 1080p x6
  <details><summary>How to do it</summary>

  **Why:** Steam, GOG, itch.io, Microsoft and Epic use landscape shots.

  1. Rendered into release/00-shared/screenshots/desktop-1080p.

  **Tip:** Steam wants at least 5; show different maps so the page looks varied.

  **Done when:** Five 1920x1080 shots.
  </details>

- [ ] 🔄 **Store text: names, descriptions, keywords** · You + Claude · in progress
  - Note: Claude drafted release/00-shared/store-text.md; all 14 fields fit their limits. Read it and tick when you're happy.
  <details><summary>How to do it</summary>

  **Why:** Each store has its own limits; drafts that fit are ready to paste.

  1. Claude drafted release/00-shared/store-text.md with every field at the right length.
  2. You read it and change anything that doesn't sound like you.

  **Tip:** Lead with what you do in the first 5 seconds: 'Watch the monkey dance. Copy the moves.'

  **Done when:** You approve the text.
  </details>

- [x] ✅ **Google Play feature graphic and itch.io cover** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** Play requires a 1024x500 feature graphic; itch.io uses a 630x500 cover.

  1. Rendered into release/00-shared/art.

  **Tip:** Keep important parts away from the edges: Play crops it on some screens.

  **Done when:** Both images exist at exact sizes.
  </details>

- [ ] 🔄 **Age-rating answers** · You + Claude · in progress
  - Note: Answers ready in release/00-shared/age-rating.md. Tick once submitted.
  <details><summary>How to do it</summary>

  **Why:** Every store asks the same kinds of questions (violence, purchases, chat...).

  1. Claude prepared release/00-shared/age-rating.md with honest answers for IARC (Google, Microsoft, Epic), Apple's questionnaire and Steam's content survey.
  2. You submit them in each store.

  **Tip:** Answer 'yes' to in-app purchases on mobile. Expect 4+ / Everyone everywhere.

  **Done when:** You submitted ratings in each store you launch on.
  </details>

- [ ] ⬜ **Decide price per store** · You
  <details><summary>How to do it</summary>

  **Why:** Mobile and PC players expect different models.

  1. Suggested: free with optional packs on iPhone and Android (already built).
  2. PC stores (Steam, GOG, itch.io desktop): a one-time price ($4.99 suggested) and no in-game Shop. Steam requires its own payment system for in-game purchases.
  3. itch.io web: free or pay-what-you-want.

  **Tip:** A small PC price with no extra purchases suits GOG best: it's the type of game it curates.

  **Done when:** You wrote down the price for each store.
  </details>

- [ ] ⬜ **Short trailer (optional)** · You + Claude · optional
  <details><summary>How to do it</summary>

  **Why:** Steam and GOG pages convert much better with a 30-60 second video.

  1. Record the screen while playing: title, a watch round, a copy round with Perfect sparkles, three maps, the wardrobe.
  2. Claude can script the shots and add captions.

  **Tip:** Show gameplay in the first 3 seconds; no logos first.

  **Done when:** An MP4 at 1920x1080 is in release/00-shared/art.
  </details>

## Google Play (Android)

Free app with optional packs, live on Google Play.

**1/11** 🟩⬜⬜⬜⬜⬜⬜⬜⬜⬜ · Cost: $25 once · Folder: [`release/03-google-play`](./03-google-play)

- [x] ✅ **Meets Google's current Android requirement (API 36)** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** Since 31 Aug 2026, new apps and updates must target Android 16 (API level 36).

  1. The Android project targets and compiles with API 36; minimum is Android 7.0 (API 24).

  **Tip:** Each August Google raises this again; Claude can bump it with one change.

  **Done when:** targetSdkVersion = 36.
  </details>

- [ ] ⬜ **Create a Google Play Console account** · You
  <details><summary>How to do it</summary>

  **Why:** Needed to publish anything on Google Play.

  1. play.google.com/console > sign up ($25 one-time).
  2. Personal account: ID verification, then the 12-tester rule applies.
  3. Organization account: needs a D-U-N-S number, skips the 12-tester rule.

  **Tip:** Personal is fine for one person; the 14-day test is your beta group anyway.

  **Done when:** You can open Play Console.

  **Links:** [Play Console](https://play.google.com/console)
  </details>

- [ ] ⬜ **Get a machine that can build Android** · You
  <details><summary>How to do it</summary>

  **Why:** This cloud project can't download Google's Android tools (dl.google.com is not allowed here).

  1. Easiest: install Android Studio on your computer and open mobile/android.
  2. Or: allow dl.google.com in this project's environment and Claude builds it here.

  **Tip:** Allowing dl.google.com lets Claude build and test the APK and AAB itself, with no setup on your side.

  **Done when:** An Android build runs somewhere.
  </details>

- [ ] ⬜ **Create the upload key and back it up** · You + Claude
  - After: Get a machine that can build Android
  <details><summary>How to do it</summary>

  **Why:** Google needs every update signed with the same key. Lose it and you need Google support to reset it.

  1. keytool command is in release/03-google-play/README.md.
  2. Save the .jks file and both passwords in a password manager and one offline place.

  **Tip:** Use Play App Signing (the default): Google keeps the real signing key, you keep only the upload key.

  **Done when:** Keystore saved in two places.
  </details>

- [ ] ⬜ **Build the signed release bundle (.aab)** · You + Claude
  - After: Create the upload key and back it up
  <details><summary>How to do it</summary>

  **Why:** Google Play only accepts Android App Bundles.

  1. cd apps/monkey-see-monkey-do && node scripts/build_web.mjs && cd mobile && npx cap sync android
  2. Android Studio: Build > Generate Signed App Bundle, or ./gradlew bundleRelease with keystore.properties.
  3. Copy the .aab into release/03-google-play/build/.

  **Tip:** Bump versionCode by 1 for every upload, even test ones.

  **Done when:** app-release.aab is in release/03-google-play/build.
  </details>

- [ ] ⬜ **Create the app in Play Console** · You
  - After: Create a Google Play Console account
  <details><summary>How to do it</summary>

  **Why:** Holds the listing, tests and releases.

  1. Create app > name, default language English (US), Game, Free.
  2. Package name comes from the first upload: com.namastegeitz.monkeydo.

  **Tip:** Choose 'Free': a free app can never be changed to paid on Google Play (packs are still allowed).

  **Done when:** The app appears in your Play Console list.
  </details>

- [ ] ⬜ **Fill in the store listing** · You
  - After: Create the app in Play Console; Store text: names, descriptions, keywords
  <details><summary>How to do it</summary>

  **Why:** What players see before they install.

  1. Paste from release/00-shared/store-text.md (title 30, short 80, full 4000 characters).
  2. Icon 512x512, feature graphic 1024x500, 2-8 phone screenshots, tablet screenshots.
  3. Category: Music or Puzzle. Contact email. Privacy policy URL.

  **Tip:** Play shows the first 3 screenshots in search: put the dancing monkey first.

  **Done when:** Store listing shows no warnings.
  </details>

- [ ] ⬜ **App content: data safety, ads, rating, audience** · You
  - After: Create the app in Play Console
  <details><summary>How to do it</summary>

  **Why:** Google won't release an app until every App content section is done.

  1. Data safety: no data collected or shared (answers in release/03-google-play/data-safety.md).
  2. Ads: no ads.
  3. Content rating: IARC questionnaire (answers in release/00-shared/age-rating.md).
  4. Target audience: if you include under-13s, the Families policy applies: parental gate before purchases is already built.

  **Tip:** Choosing age groups under 13 adds a review step but opens the 'Kids' area of Play. The game already meets the rules (no ads, no data, grown-up check).

  **Done when:** App content page shows all green.
  </details>

- [ ] ⬜ **Payments profile and 26 in-app products** · You
  - After: Build the signed release bundle (.aab)
  <details><summary>How to do it</summary>

  **Why:** The Shop's packs, bundles and sets must exist in Play with the exact IDs.

  1. Set up a payments profile (Settings > Payments profile).
  2. Upload a build with billing first (internal testing), then Monetize > Products > In-app products.
  3. Create each product from docs/STORE_PRODUCTS.md with the same ID and price.

  **Tip:** Add yourself as a license tester (Settings > License testing) so test purchases never charge.

  **Done when:** 26 products active.
  </details>

- [ ] ⬜ **Closed test: 12 testers for 14 days** · You + Claude
  - After: Build the signed release bundle (.aab); Recruit 12 or more testers
  <details><summary>How to do it</summary>

  **Why:** Required for new personal accounts before production access.

  1. Testing > Closed testing > create track, upload the .aab.
  2. Add your testers' Google emails, share the opt-in link.
  3. Keep at least 12 opted in for 14 days straight; Claude fixes what they find.

  **Tip:** The 14 days only count while 12 or more are opted in, so start with extra testers.

  **Done when:** 14 days passed with 12+ opted in.
  </details>

- [ ] ⬜ **Apply for production and release** · You
  - After: Closed test: 12 testers for 14 days; Fill in the store listing; App content: data safety, ads, rating, audience
  <details><summary>How to do it</summary>

  **Why:** The final step to go live.

  1. Dashboard > Apply for production (answer the questions about your test).
  2. Create a production release, roll out to 100% (or 20% first to be careful).

  **Tip:** First reviews usually take 1-7 days. Answer every review with the fix version number.

  **Done when:** The game is on Google Play.
  </details>

## Apple App Store (iPhone and iPad)

Free app with optional packs, live on the App Store.

**0/12** ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜ · Cost: $99 per year · Folder: [`release/04-apple-app-store`](./04-apple-app-store)

- [ ] ⬜ **Join the Apple Developer Program** · You
  <details><summary>How to do it</summary>

  **Why:** Required to publish on the App Store (and to sign Mac builds).

  1. developer.apple.com/programs/enroll, $99/year.
  2. Individual: your legal name shows as the seller. Organization: needs a D-U-N-S number.

  **Tip:** Enroll from the Apple Developer app on an iPhone: ID verification is often faster there.

  **Done when:** You can sign in to App Store Connect.

  **Links:** [Enroll](https://developer.apple.com/programs/enroll/)
  </details>

- [ ] ⬜ **A Mac with Xcode 26, or Codemagic** · You
  <details><summary>How to do it</summary>

  **Why:** Apple builds need Xcode 26 and the iOS 26 SDK (required since April 2026), which only run on macOS.

  1. Your own Mac: install Xcode from the App Store, open mobile/ios/App/App.xcodeproj.
  2. No Mac: Codemagic's cloud Macs (config ready in mobile/ci/codemagic.yaml, free tier for small apps).

  **Tip:** Codemagic can upload straight to TestFlight once you add an App Store Connect API key.

  **Done when:** An iOS build runs on a Mac or Codemagic.
  </details>

- [ ] ⬜ **Paid Apps agreement, tax and banking** · You
  - After: Join the Apple Developer Program
  <details><summary>How to do it</summary>

  **Why:** In-app purchases don't work until this is complete, even for free apps.

  1. App Store Connect > Business: accept Paid Apps, add bank account and tax forms.

  **Tip:** Do this early: approval can take a few days.

  **Done when:** Agreement shows Active.
  </details>

- [ ] ⬜ **Create the app in App Store Connect** · You
  - After: Join the Apple Developer Program
  <details><summary>How to do it</summary>

  **Why:** Holds the build, listing and purchases.

  1. Register bundle ID com.namastegeitz.monkeydo (Identifiers).
  2. My Apps > + > New App: iOS, name, English (US), the bundle ID, SKU monkeydo-001.

  **Tip:** The name must be unique on the App Store; have a backup ready from the name check.

  **Done when:** The app appears in My Apps.
  </details>

- [ ] ⬜ **Create the 26 in-app purchases** · You
  - After: Paid Apps agreement, tax and banking; Create the app in App Store Connect
  <details><summary>How to do it</summary>

  **Why:** The Shop needs each product to exist with the exact ID.

  1. Monetization > In-App Purchases: create each from docs/STORE_PRODUCTS.md (type, ID, name, description, price).
  2. Add a review screenshot of the Shop (release/00-shared/screenshots/shop-review/01-shop.jpg).

  **Tip:** Try every purchase first in the iPhone Simulator with MonkeyDo.storekit: no account needed.

  **Done when:** 26 products 'Ready to Submit'.
  </details>

- [ ] ⬜ **Build and upload with Xcode 26** · You + Claude
  - After: A Mac with Xcode 26, or Codemagic; Create the app in App Store Connect
  <details><summary>How to do it</summary>

  **Why:** The binary Apple reviews.

  1. node scripts/build_web.mjs && cd mobile && npx cap sync ios
  2. Xcode: set your Team, add the In-App Purchase capability, Product > Archive > Distribute > App Store Connect.

  **Tip:** Bump the build number for each upload; the version stays 1.0.0 until release.

  **Done when:** The build shows in App Store Connect > TestFlight.
  </details>

- [ ] ⬜ **TestFlight beta** · You
  - After: Build and upload with Xcode 26
  <details><summary>How to do it</summary>

  **Why:** Real iPhones with real (sandbox) purchases before review.

  1. Add yourself as an internal tester; invite beta testers by email for external testing (short Apple review first).

  **Tip:** External testing reuses the same testers as the web beta: just send them the TestFlight link.

  **Done when:** At least 3 people played the TestFlight build.
  </details>

- [ ] ⬜ **App Privacy: Data Not Collected** · You
  - After: Create the app in App Store Connect
  <details><summary>How to do it</summary>

  **Why:** Shown on the App Store page; must match what the app does.

  1. App Privacy > Get Started > 'No, we do not collect data from this app'.

  **Tip:** True for this game: purchases are handled by Apple, and the save stays on the phone.

  **Done when:** Privacy label published.
  </details>

- [ ] ⬜ **Age rating questionnaire** · You
  - After: Create the app in App Store Connect
  <details><summary>How to do it</summary>

  **Why:** Apple's 2025 ratings (4+, 9+, 13+, 16+, 18+) need the updated questions answered.

  1. Use the Apple section of release/00-shared/age-rating.md. Expected result: 4+.

  **Tip:** 'In-app purchases: yes' doesn't raise the rating.

  **Done when:** Rating shows 4+.
  </details>

- [ ] ⬜ **Decide: Kids Category or not** · You
  <details><summary>How to do it</summary>

  **Why:** The Kids Category puts the game in front of parents but adds strict rules.

  1. Kids Category needs: no third-party ads or analytics (none here) and a parental gate before purchases and outside links (already built: the grown-up check).

  **Tip:** Suggested: not Kids Category at first (simpler review); age rating 4+ already makes it family-friendly.

  **Done when:** You chose.
  </details>

- [ ] ⬜ **App Store listing** · You
  - After: Create the app in App Store Connect; Store text: names, descriptions, keywords
  <details><summary>How to do it</summary>

  **Why:** What people see in the App Store.

  1. Paste from release/00-shared/store-text.md: name 30, subtitle 30, promotional text 170, description 4000, keywords 100 (commas, no spaces).
  2. Screenshots: 6.9-inch iPhone (1320x2868) and 13-inch iPad (2064x2752).
  3. Support URL and privacy policy URL from the beta site.

  **Tip:** Keywords: don't repeat words already in the name or subtitle; Apple indexes those already.

  **Done when:** No missing-field warnings.
  </details>

- [ ] ⬜ **Submit for App Review** · You
  - After: App Store listing; Create the 26 in-app purchases; Build and upload with Xcode 26; App Privacy: Data Not Collected; Age rating questionnaire
  <details><summary>How to do it</summary>

  **Why:** Apple checks every app before release.

  1. Add the build to version 1.0, attach the in-app purchases, write review notes (draft in release/04-apple-app-store/review-notes.md), submit.

  **Tip:** Most reviews finish in 1-2 days. If rejected, Claude can fix and you resubmit the same day.

  **Done when:** Status: Ready for Distribution.
  </details>

## itch.io (web and PC, fastest store)

Playable in the browser on itch.io this week, free or pay-what-you-want.

**1/4** 🟩🟩🟩⬜⬜⬜⬜⬜⬜⬜ · Cost: Free · Folder: [`release/02-itch-io`](./02-itch-io)

- [x] ✅ **HTML5 upload zip** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** itch.io plays a zip with index.html at its root right in the page.

  1. release/02-itch-io/monkey-see-monkey-do-html5.zip (rebuilt by scripts/build_release.mjs).

  **Tip:** Well under itch.io's limits (500 MB unpacked, 200 MB per file).

  **Done when:** The zip exists and plays when unzipped.
  </details>

- [ ] ⬜ **itch.io account and payouts** · You
  <details><summary>How to do it</summary>

  **Why:** Free to join; payouts only matter if you charge.

  1. itch.io > Register > 'I'm interested in distributing content on itch.io'.
  2. Payment settings: PayPal or Stripe if you want tips.

  **Tip:** Pay-what-you-want with $0 minimum gets the most players and still allows tips.

  **Done when:** Account ready.
  </details>

- [ ] ⬜ **Create the project page** · You
  - After: itch.io account and payouts
  <details><summary>How to do it</summary>

  **Why:** Where people play.

  1. Dashboard > Create new project: kind HTML.
  2. Upload the zip, tick 'This file will be played in the browser'.
  3. Embed: 'Click to launch in fullscreen' and 'Mobile friendly' (portrait).
  4. Paste the itch.io text from store-text.md; cover 630x500; screenshots.

  **Tip:** Fullscreen launch avoids a small embedded box on phones.

  **Done when:** The page plays the game in draft.
  </details>

- [ ] ⬜ **Publish on itch.io** · You
  - After: Create the project page
  <details><summary>How to do it</summary>

  **Why:** Your first public store release.

  1. Visibility: Public. Add tags: rhythm, memory, music, casual, family, dance.

  **Tip:** Post the link in the itch.io 'Release Announcements' forum and add it to a few jams' showcases.

  **Done when:** The page is public.
  </details>

## PC edition (Windows, Mac, Linux)

A desktop app for Steam, GOG, Microsoft Store and Epic: one-time price, no in-game Shop.

**2/4** 🟩🟩🟩🟩🟩⬜⬜⬜⬜⬜ · Cost: Free (signing optional) · Folder: [`release/05-desktop`](./05-desktop)

- [x] ✅ **Desktop app project (Electron)** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** PC stores need an installed app, not a web page.

  1. release/05-desktop: Electron app that opens the game full screen, offline, with its own window and icon.

  **Tip:** Electron runs on Windows, macOS and Linux from one project.

  **Done when:** Project files ready.
  </details>

- [x] ✅ **PC edition: hide the real-money Shop** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** Steam requires in-game purchases to go through Steam; a one-time price with no Shop is simpler and suits GOG.

  1. The desktop app runs the game with ?edition=pc: no Shop button and no 'buy in the apps' text; everything is earned by playing.

  **Tip:** Skins and gear stay earnable with bananas and golden bananas, so nothing is lost.

  **Done when:** PC edition shows no Shop.
  </details>

- [ ] ⬜ **Build Windows, macOS and Linux apps** · You + Claude
  <details><summary>How to do it</summary>

  **Why:** The files you upload to Steam, GOG and the others.

  1. On a computer with Node.js: cd apps/monkey-see-monkey-do/release/05-desktop && npm install && npm run build:win (or :mac / :linux).
  2. Or allow github.com downloads here and Claude builds the Linux and Windows versions.

  **Tip:** Build on Windows for the Windows app and on a Mac for the Mac app; signing works best on its own system.

  **Done when:** Installers in release/05-desktop/dist.
  </details>

- [ ] ⬜ **Code signing (Mac required, Windows recommended)** · You · optional
  - After: Build Windows, macOS and Linux apps
  <details><summary>How to do it</summary>

  **Why:** Unsigned Mac apps won't open; unsigned Windows apps show a warning (Steam and GOG installs avoid most of it).

  1. Mac: Developer ID certificate + notarization (uses the $99 Apple account).
  2. Windows: optional code-signing certificate; Microsoft Store signs for you.

  **Tip:** For Steam-only Windows release you can skip a Windows certificate at first.

  **Done when:** Mac build notarized.
  </details>

- [ ] ⬜ **Test the PC builds** · You
  - After: Build Windows, macOS and Linux apps
  <details><summary>How to do it</summary>

  **Why:** Keyboard play, window resizing and offline start need a real PC check.

  1. Play with the keyboard (Q W E / A S D), resize the window, go full screen (F11), start with Wi-Fi off.

  **Tip:** Also try a laptop with only integrated graphics: Auto graphics should keep it smooth.

  **Done when:** Played 15 minutes on Windows (and Mac if you sell there).
  </details>

## Steam

A Steam store page collecting wishlists, then release.

**1/6** 🟩🟩⬜⬜⬜⬜⬜⬜⬜⬜ · Cost: $100 per game (Steam Direct) · Folder: [`release/06-steam`](./06-steam)

- [ ] ⬜ **Steamworks partner account** · You
  <details><summary>How to do it</summary>

  **Why:** Steam's developer side.

  1. partner.steamgames.com > join; identity, tax and bank details.

  **Tip:** Takes a few days to verify: start before the build is finished.

  **Done when:** You can sign in to Steamworks.

  **Links:** [Steamworks](https://partner.steamgames.com/)
  </details>

- [ ] ⬜ **Pay the Steam Direct fee ($100)** · You
  - After: Steamworks partner account
  <details><summary>How to do it</summary>

  **Why:** One fee per game; there is a 21-day wait after paying before you can release.

  1. Steamworks > Pay the fee (Admin users only).

  **Tip:** Pay early: the 30-day wait runs while you build the store page.

  **Done when:** App ID created.
  </details>

- [x] ✅ **Steam capsule images (exact sizes)** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** Steam rejects images that are even one pixel off.

  1. Rendered into release/06-steam/art: header 920x430, small 462x174, main 1232x706, vertical 748x896, library capsule 600x900, library header 920x430, library hero 3840x1240 (no text), library logo 1280x720 (transparent), page background 1438x810.

  **Tip:** The small capsule must stay readable at 120 px wide: big logo, nothing else.

  **Done when:** All images exist at exact sizes.
  </details>

- [ ] ⬜ **Store page: text, tags, screenshots, trailer** · You
  - After: Pay the Steam Direct fee ($100)
  <details><summary>How to do it</summary>

  **Why:** Steam reviews the page before 'Coming soon' goes live.

  1. Paste the Steam text from store-text.md; tags: Rhythm, Music, Casual, Family Friendly, Memory, Cute, Singleplayer.
  2. Upload 5+ desktop screenshots and the trailer.
  3. Content survey: no mature content.

  **Tip:** Turn on 'Coming soon' as early as possible: every wishlist notifies a player on release day.

  **Done when:** Coming-soon page approved and public.
  </details>

- [ ] ⬜ **Upload the build (SteamPipe)** · You
  - After: Build Windows, macOS and Linux apps; Pay the Steam Direct fee ($100)
  <details><summary>How to do it</summary>

  **Why:** Steam installs from depots you upload.

  1. Steamworks SDK > tools/ContentBuilder, or the web uploader for small builds. Depot layout notes in release/06-steam/README.md.

  **Tip:** Set the launch option to the .exe and test with a Steam beta branch before release.

  **Done when:** The build installs and runs from your Steam library.
  </details>

- [ ] ⬜ **Build review and release** · You
  - After: Store page: text, tags, screenshots, trailer; Upload the build (SteamPipe)
  <details><summary>How to do it</summary>

  **Why:** Valve checks the build before the release button unlocks.

  1. Request build review; once approved and 30 days have passed since paying, press Release.

  **Tip:** Release on a Tuesday-Thursday morning US time; avoid big sale weeks.

  **Done when:** The game is on Steam.
  </details>

## GOG

Pitch the PC edition to GOG's curators.

**1/3** 🟩🟩🟩⬜⬜⬜⬜⬜⬜⬜ · Cost: Free to submit (GOG takes a revenue share if accepted) · Folder: [`release/07-gog`](./07-gog)

- [x] ✅ **DRM-free, offline PC build** · Claude · done by Claude 2026-11-17
  <details><summary>How to do it</summary>

  **Why:** GOG only sells games that run with no launcher or account.

  1. The PC edition needs no internet, account or launcher; saves stay on the computer.

  **Tip:** This is already true of the game's design.

  **Done when:** Confirmed in the PC build.
  </details>

- [ ] 🔄 **Write the GOG pitch** · You + Claude · in progress
  - Note: Draft in release/07-gog/pitch.md; fill in price, release plan and links.
  <details><summary>How to do it</summary>

  **Why:** GOG curates: a clear pitch matters as much as the game.

  1. Draft in release/07-gog/pitch.md: what it is, who it's for, what's special (pure watch-and-copy, 40 levels, 4 maps, 100 skins, no ads, no tracking), links.

  **Tip:** GOG favors polished single-player games; mention the family angle and that everything is earnable by playing.

  **Done when:** You're happy with the pitch.
  </details>

- [ ] ⬜ **Submit to GOG** · You
  - After: Write the GOG pitch; Build Windows, macOS and Linux apps
  <details><summary>How to do it</summary>

  **Why:** GOG reviews every submission.

  1. gog.com 'Submit your game' form: pitch, trailer, screenshots, a build or key.

  **Tip:** Stronger after a Steam or itch.io launch with good reviews; GOG often asks about sales elsewhere.

  **Done when:** Submission sent.
  </details>

- [ ] ⬜ **If accepted: contract and builds** · You · optional
  - After: Submit to GOG
  <details><summary>How to do it</summary>

  **Why:** GOG sets up the store page and installers with you.

  1. Sign the agreement, get Developer Portal access, upload Windows (and Mac/Linux) builds.

  **Tip:** GOG Galaxy features (achievements) are optional.

  **Done when:** Release date agreed.
  </details>

## More stores (optional)

Extra reach once the main stores are live.

**0/4** ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜ · Cost: Microsoft free, Epic $100, Samsung and Amazon free · Folder: [`release/08-more-stores`](./08-more-stores)

- [ ] ⬜ **Microsoft Store (Windows)** · You + Claude · optional
  <details><summary>How to do it</summary>

  **Why:** Free for individual developers since 2025; the Store signs the app for you.

  1. Sign up at storedeveloper.microsoft.com (ID check).
  2. Package: PWABuilder.com from the beta link (fastest) or the Electron build as MSIX.
  3. Age rating via IARC in Partner Center.

  **Tip:** PWABuilder needs only the public beta link: no build machine required.

  **Done when:** Live on the Microsoft Store.
  </details>

- [ ] ⬜ **Epic Games Store** · You · optional
  - After: Build Windows, macOS and Linux apps
  <details><summary>How to do it</summary>

  **Why:** Another big PC store; 12% fee.

  1. Epic Developer Portal, $100 per game, IARC rating, achievements set up, builds uploaded.

  **Tip:** Epic requires achievements for new games; Claude can add a simple achievement set.

  **Done when:** Live on Epic.
  </details>

- [ ] ⬜ **Samsung Galaxy Store** · You · optional
  - After: Build the signed release bundle (.aab)
  <details><summary>How to do it</summary>

  **Why:** Preinstalled on Samsung phones; free to publish.

  1. seller.samsungapps.com, upload the Android build, reuse the Play listing.

  **Tip:** Samsung needs its own in-app purchase setup; launch it free-only at first if that's simpler.

  **Done when:** Live on Galaxy Store.
  </details>

- [ ] ⬜ **Amazon Appstore (Fire tablets)** · You · optional
  - After: Build the signed release bundle (.aab)
  <details><summary>How to do it</summary>

  **Why:** Fire tablets are popular with families.

  1. developer.amazon.com, upload the Android build, reuse the Play listing.

  **Tip:** Amazon Appstore now targets Fire devices only; test on a Fire tablet if you can.

  **Done when:** Live on Amazon Appstore.
  </details>

## Launch and after

Launch smoothly, then keep players happy.

**0/3** ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜ · Cost: Free · Folder: [`release`](./)

- [ ] ⬜ **Version 1.0.0 freeze and release notes** · Claude
  <details><summary>How to do it</summary>

  **Why:** Every store asks 'What's new'.

  1. Claude writes release notes per store and tags the release in git.

  **Tip:** Keep notes short and player-facing: new levels, fixes, nothing technical.

  **Done when:** Notes in release/RELEASE_NOTES.md.
  </details>

- [ ] ⬜ **Launch day** · You
  <details><summary>How to do it</summary>

  **Why:** The first week decides store rankings.

  1. Post the store links to friends, family, social media and your testers.
  2. Ask happy testers for an honest review in the first week.

  **Tip:** Launch on one or two stores first, then add the others a week apart: each launch is a new reason to post.

  **Done when:** Links posted.
  </details>

- [ ] ⬜ **Weekly review of reviews and bug reports** · You + Claude
  <details><summary>How to do it</summary>

  **Why:** Quick fixes earn better ratings.

  1. Once a week: you skim reviews; Claude reads the Bug & Feedback page and fixes what it can; one update per store.

  **Tip:** Reply to every 1-3 star review with what you fixed.

  **Done when:** Ongoing: tick after your first weekly review.
  </details>

## What's in each folder

| Folder | What's inside |
|---|---|
| [00-shared](00-shared/) | Store text, age-rating answers, icons, banner art, screenshots for every store |
| [01-web-beta](01-web-beta/) | Beta link, QR code, web build zip (published to GitHub Pages by `scripts/deploy_beta.sh`) |
| [02-itch-io](02-itch-io/) | HTML5 upload zip (PC edition) and upload steps |
| [03-google-play](03-google-play/) | Android build steps, signing key steps, data-safety answers, `build/` for the .aab |
| [04-apple-app-store](04-apple-app-store/) | iPhone/iPad build steps, reviewer notes, `build/` log |
| [05-desktop](05-desktop/) | PC edition desktop app (Electron) for Steam, GOG, Microsoft, Epic |
| [06-steam](06-steam/) | Steam capsule art at exact sizes, store and upload steps |
| [07-gog](07-gog/) | GOG requirements and submission pitch |
| [08-more-stores](08-more-stores/) | Microsoft Store, Epic, Samsung Galaxy Store, Amazon |

## Bug reports and progress data

- **Testers** report bugs, confusing bits, ideas and a 1-5 fun rating on the
  Bug & Feedback page. Device details fill in by themselves. Invite testers by
  email as Editors (the only level that lets people outside an organization
  write). Each tester can only add to their own reports; only you change a
  report's status (New, Confirmed, Fixed, Won't fix) and reply.
- **Claude** reads the reports directly, fixes the minor bugs, runs all tests,
  and marks them Fixed with a reply.
- **Progress log:** every tick on the live checklist is recorded with who and
  when, and charted as steps done over time.

## Rebuild everything

```
cd apps/monkey-see-monkey-do
node scripts/build_web.mjs            # game + public beta site (dist/site)
bash scripts/deploy_beta.sh           # publish the beta site to GitHub Pages
node scripts/build_release.mjs        # web zip, itch.io zip, desktop app folder
node scripts/make_store_art.cjs all   # icons, banners, Steam art, screenshots
node scripts/check_store_text.mjs     # store text lengths
node scripts/release_readme.mjs       # this file
```
