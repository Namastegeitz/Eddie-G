# **COSMIC SAUCER DRIFT**

Everything for the game in one folder: the Godot project, every build, a kit for each store,
and the launch checklist. Store rules researched **2026-11-17**.

| | |
|---|---|
| ▶ **Live checklist** (tick steps, report bugs, log play sessions) | https://claude.ai/artifact/4MPCACGK7XTCzwTcBbqN1m |
| 🎮 **Play the game in a browser** | https://claude.ai/artifact/Wjris6Pjst5K54bF6z8MUY |
| 📁 [`game/`](game/) | The Godot 4.7 project (source, docs, tests, tools) |
| 📦 [`builds/`](builds/) | One folder per build: web, Android APK, Play bundle, iOS Xcode, Windows, macOS, Linux |
| 🏪 [`stores/`](stores/) | One kit per store: rules, sizes, costs, what's done, what's missing, sources |
| ✅ [`checklist/`](checklist/) | The checklist data and the page it builds |
| 📝 [`prompts/`](prompts/) | The original game brief and the next-feature prompts |

## Progress: 26 of 76 steps done

`███████░░░░░░░░░░░░░` 34%

✅ done · 🔄 doing · ⛔ blocked · ⬜ to do. Ticks you make on the live page are copied here when Claude syncs.
Snapshot: 2026-11-28.

### Phase 1 · Workspace and builds (5/5)

_Everything for the launch in one place, every build in its own folder._

- ✅ **Claude**: [Project folder COSMIC-SAUCER-DRIFT with game, builds, stores and checklist](.) · all stores
- ✅ **Claude**: [Every build in its own folder](builds/README.md) · all stores
- ✅ **Claude**: [Current store rules researched (17 Nov 2026) and a kit per store](stores/) · all stores
- ✅ **Claude**: This live checklist, bug collector and playtest log · all stores
- ✅ **Claude**: COSMIC SAUCER DRIFT folder on your Artifacts page · all stores

### Phase 2 · Decisions (0/7)

_The few choices only you can make. They shape every store form._

- ⬜ **You**: Choose the developer name players will see · all stores · 5 min
- ⬜ **You**: Create a support email for the game · all stores · 10 min
- ⬜ **You**: Free or paid on each store · all stores · 5 min
- ⬜ **Together**: Agree the launch order · all stores · 5 min
- ⬜ **Together**: Make the privacy policy public · Google Play, App Store, Microsoft Store, Epic, Galaxy / Amazon · 5 min
- ⬜ **You**: EU trader status for the App Store · App Store · 5 min
- ⬜ **Together**: Support page (Apple requires a support URL) · App Store, Steam, GOG · 15 min

### Phase 3 · Store accounts (0/9)

_Open the accounts early: identity checks and Steam's 30-day clock take the longest._

- ⬜ **You**: [Open a Google Play Console account](stores/google-play/README.md) · Google Play · $25 once · 30 min + review
- ⬜ **You**: [Join the Apple Developer Program](stores/apple-app-store/README.md) · App Store · $99 / year · 20 min + approval
- ⬜ **You**: [Join Steamworks and pay the Steam Direct fee](stores/steam/README.md) · Steam · $100 per game · 1 h + 15–30 days
- ⬜ **You**: [Create an itch.io account](stores/itch-io/README.md) · itch.io · Free · 5 min
- ⬜ **You**: [Microsoft Store developer account (optional)](stores/microsoft-store/README.md) · Microsoft Store · Free · 20 min
- ⬜ **You**: [Epic Games Store developer account (optional)](stores/epic-games-store/README.md) · Epic · $100 per game · up to 2+ weeks
- ⬜ **You**: [Samsung Galaxy Store seller account (optional)](stores/other-android-stores/README.md) · Galaxy / Amazon · Free · 1 h + review
- ⬜ **You**: [Free Sentry account for crash reports](stores/CRASH_REPORTING.md) · Google Play, App Store, Steam, itch.io, GOG, Microsoft Store · Free · 10 min
- ⬜ **You**: [Free Firebase project for Crashlytics](stores/CRASH_REPORTING.md) · Google Play, App Store · Free · 10 min

### Phase 4 · Release-ready game (11/22)

_The fixes and signed builds each store checks for._

- ✅ **Claude**: Play bundle targets Android 16 (API 36) · Google Play, Galaxy / Amazon
- ✅ **Claude**: Store icons fixed for Apple and Google · App Store, Google Play
- ✅ **Claude**: Automated game tests pass · all stores
- ✅ **Claude**: Version 1.0.0 (build 1) in every export · all stores
- ✅ **Claude**: Keep the HUD clear of notches and rounded corners · Google Play, App Store, Galaxy / Amazon · 1 h
- ⬜ **Together**: Back button and pause on Android 16 · Google Play, Galaxy / Amazon · 5 min
- ⬜ **You**: [Create the Android upload key and back it up twice](builds/android-aab-release/README.md) · Google Play, Galaxy / Amazon · 10 min
- ⬜ **Together**: [Build the signed Play bundle (AAB)](builds/android-aab-release/README.md) · Google Play, Galaxy / Amazon · 30 min
- ⬜ **Claude**: Put your Apple Team ID in the iOS export · App Store · 5 min
- ⬜ **You**: [Archive and upload the iOS build from a Mac](builds/ios-xcode/README.md) · App Store · 1 h
- ⬜ **Together**: [Sign and notarize the Mac build](builds/macos/README.md) · Steam, GOG, itch.io, Epic · 1 h
- ⬜ **You**: [Sign the Windows build for direct downloads (optional)](builds/windows/README.md) · itch.io, Microsoft Store · $10/month or ~$65–440/year
- ✅ **Claude**: Privacy policy button inside the game · App Store, Google Play · 20 min
- ✅ **Claude**: Write the AI-content disclosure · Steam, itch.io · 15 min
- ⬜ **Together**: Finish the other 9 HD craft (optional before launch) · all stores · ~540 Meshy credits
- ✅ **Claude**: [Accessibility settings: colour-blind filter, reduce motion, interface size](store-kit/accessibility.md) · all stores
- ✅ **Claude**: [Credits & licences screen (Godot MIT, fonts, Meshy)](store-kit/credits.md) · all stores
- ✅ **Claude**: [Crash reporting (Sentry + Firebase Crashlytics), opt-in, in store builds](stores/CRASH_REPORTING.md) · Google Play, App Store, Steam, itch.io, GOG, Microsoft Store
- ✅ **Claude**: [Store rating prompt after podium finishes](stores/IN_APP_REVIEW.md) · Google Play, App Store
- ⬜ **Together**: GitHub Actions: tests and builds on every change · all stores · Free minutes
- ⬜ **You**: [Confirm which Meshy plan made the HD craft and rocks](store-kit/credits.md) · all stores · 2 min
- ⬜ **You**: [Say go to republish the privacy policy with the crash-report section](game/docs/privacy-policy.html) · Google Play, App Store

### Phase 5 · Store pages and art (10/13)

_Text, screenshots, art and rating answers at each store's exact sizes._

- ✅ **Claude**: [Google Play text, tags and content answers](game/docs/STORE_LISTING.md) · Google Play
- ✅ **Claude**: Google Play icon, feature graphic and screenshots · Google Play
- ✅ **Claude**: 1920×1080 gameplay screenshots · Google Play, Steam, GOG, Epic, Microsoft Store, itch.io · 30 min
- ✅ **Claude**: App Store screenshots (iPhone and iPad sizes) · App Store · 30 min
- ✅ **Claude**: App Store text and keywords · App Store · 20 min
- ⬜ **Claude**: Steam capsules and library art · Steam · 1 h
- ✅ **Claude**: App Review notes · App Store · 10 min
- ✅ **Claude**: Gameplay trailer (30–60 s) · Steam, Google Play, App Store, GOG, itch.io · 2 h
- ⬜ **Claude**: itch.io cover (630×500) and page text · itch.io · 20 min
- ✅ **Claude**: Age-rating answers for every store · Google Play, App Store, Steam, Epic, Microsoft Store · 20 min
- ✅ **Claude**: "Data not collected" answers for Play and Apple · Google Play, App Store
- ✅ **Claude**: [Privacy answers for store builds with crash reporting](stores/CRASH_REPORTING.md) · Google Play, App Store
- ⬜ **Claude**: [2027 screenshots: iPhone Duo (Apple) and foldables (Play)](store-kit/shot-list.md) · App Store, Google Play

### Phase 6 · Testing (0/6)

_Real people on real devices. Google requires 12 testers for 14 days._

- ⬜ **You**: [Play a full cup on your own phone](builds/android-apk-debug/README.md) · Google Play, Galaxy / Amazon, App Store · 20 min
- ⬜ **You**: Report every glitch in the bug form · all stores
- ⬜ **You**: Google Play closed test: 12+ testers for 14 days · Google Play · 14 days
- ⬜ **You**: TestFlight on an iPhone or iPad · App Store · 1–3 days
- ⬜ **You**: Check speed on a cheap or older phone · Google Play, Galaxy / Amazon
- ⬜ **You**: Steam Deck / gamepad check (optional) · Steam

### Phase 7 · Submit and launch (0/10)

_One store at a time, cheapest and fastest first._

- ⬜ **Together**: [Publish on itch.io](stores/itch-io/README.md) · itch.io · 1 h
- ⬜ **You**: Apply for production and release on Google Play · Google Play · 1–2 weeks
- ⬜ **You**: Steam Coming Soon page live (14+ days before release) · Steam · 7–10 days
- ⬜ **Together**: Upload builds and release on Steam · Steam · 1–2 weeks
- ⬜ **You**: Submit for App Review and release · App Store · 1–3 days
- ⬜ **You**: Microsoft Store release (optional) · Microsoft Store
- ⬜ **You**: Galaxy Store / Amazon Fire release (optional) · Galaxy / Amazon
- ⬜ **You**: Epic Games Store release (optional) · Epic
- ⬜ **You**: [Newgrounds and Game Jolt (optional)](stores/web-portals/README.md) · Web portals · 30 min
- ⬜ **You**: [Apply to GOG](stores/gog/README.md) · GOG

### Phase 8 · After launch (0/4)

_Keep players happy: crashes, reviews and updates._

- ⬜ **Together**: Check crash reports weekly · Google Play, App Store, Steam
- ⬜ **You**: Reply to reviews · Google Play, App Store, Steam, itch.io
- ⬜ **Claude**: Ship the first update · all stores
- ⬜ **Together**: Review the bug and playtest data together monthly · all stores

## How the live checklist works

- Tick the circle next to a step and it turns into a green check. The tick is saved, and every
  device with the page open updates within seconds.
- Each step tells you how to do it, why it matters, what to watch out for, what it unlocks next,
  and what's already on the computer.
- Notes on a step, **bug reports** and **play-session logs** are stored with the page. Claude reads them
  ("check the checklist" in the chat), fixes bugs, marks them Fixed, and ticks its own steps.
- The page is private to you. To let testers report bugs there, share it from its page on claude.ai.
