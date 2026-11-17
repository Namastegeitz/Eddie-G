# Shared brief: Alien Sudoku store launch research

You are researching what it takes, AS OF TODAY (November 2026), to publish one game on
specific stores, and mapping every requirement onto the game's current state. Your output
feeds a live launch checklist the owner will work through step by step.

## The game
- Name: **Alien Sudoku**. Sudoku with alien glyph pictures instead of digits. Modes: 54-level
  campaign (6 sectors x 9), Daily puzzle with streaks, Quick Play, Zen (no lives), Alien Duel
  (race an AI rival on the same puzzle), achievements, stats. No accounts, no login, no
  in-app purchases, no analytics, no cloud saves. All progress is stored on the device.
- Content: cartoon aliens. Four difficulty lineups from cute (Soft Visitors) to "gnarly"
  (cartoon monsters with fangs, many eyes, slime; mild cartoon horror, no blood, no violence).
  When the player runs out of tries, an alien ship "asks who you are" and the player can type
  a name; it is stored only on the device. No user-to-user contact, no chat, no UGC.
- Art: glyph art (SVG) and themes were created with AI assistance (Claude). Music and sound
  effects are synthesized in code (also AI-assisted). Space background photos came with the
  original prototype (likely NASA/ESA imagery; licenses must be verified). Fonts: SIL OFL
  (Orbitron, Space Grotesk, Quicksand, Black Ops One, Creepster, etc.).
- Monetization: phones (Android/iOS) are free with Google AdMob ads (adaptive banner,
  interstitial between games, optional rewarded video for an extra hint or a second chance).
  Google UMP consent message at launch; iOS App Tracking Transparency prompt. Currently uses
  Google's TEST ad unit ids. Desktop and web builds have NO ads (PC price not decided).
- Developer: an individual ("Eddie G"), US-based (assume; flag where business vs individual matters).

## The tech, and what exists right now
Repository: /home/user/Eddie-G (read-only for you). Game source: apps/alien-sudoku
(it is about to move to ALIEN-SUDOKU/game; in your output refer to paths as `game/...`).
- Vite web app + PWA. Single-file playable HTML build exists.
- Capacitor 8. Android: compileSdk 36, targetSdk 36, minSdk 24, applicationId
  com.eddieg.aliensudoku, versionCode 1, versionName 1.0.0 (game/android).
  iOS: deployment target 15.0, iPhone + iPad (TARGETED_DEVICE_FAMILY 1,2), bundle id
  com.eddieg.aliensudoku, MARKETING_VERSION 1.0.0, build 1, Swift Package Manager (game/ios).
  Info.plist has GADApplicationIdentifier (test id), NSUserTrackingUsageDescription and one
  SKAdNetwork id (Google's). No PrivacyInfo.xcprivacy file found in the app target.
  Plugins: @capacitor-community/admob 8, app, haptics, preferences, splash-screen.
- Electron 45 + electron-builder 26 desktop app (game/desktop): Windows NSIS installer +
  portable exe, macOS zip, Linux AppImage + deb. Not code-signed.
- Existing docs you may read: apps/alien-sudoku/docs/STORE_CHECKLIST.md, docs/PRIVACY.md,
  prompts/claude/alien-sudoku/*.md, .github/workflows/alien-sudoku.yml, apps/alien-sudoku/RUN.md.
- Current blockers: this cloud workspace cannot reach dl.google.com (no Android SDK, so no
  APK/AAB can be built here); there is no Mac/Xcode (iOS must be built on a Mac or a cloud
  Mac CI); GitHub Actions jobs do not start on the owner's account (likely billing). The owner
  has no store accounts yet as far as we know (assume none; mark them as owner tasks).
  Windows and Linux desktop builds CAN be produced in this workspace.

## How to research
- Use WebSearch and WebFetch. Prefer official sources (developer.apple.com, support.google.com,
  partner.steamgames.com, etc.). Check that what you report is current as of late 2026: look
  for dates, recent policy announcements and deadlines. Where you cannot verify something,
  say so explicitly ("could not verify; check X"). Never invent fees, sizes or deadlines.
- Be in depth: every requirement, every account step, every form/questionnaire the owner will
  meet, asset specs with exact pixel sizes and counts, build/technical requirements, review
  times, common rejection reasons, costs, and anything specific to THIS game (ads, AI-made art,
  cute-but-scary aliens and children/family policies, a web game in a native wrapper, etc.).

## What to write (do NOT modify the repository)
Write two files into /tmp/claude-0/-home-user-Eddie-G/11915a35-6179-503d-9814-183023fa0ffd/scratchpad/research/ :

1. `<name>.md`: an in-depth guide in plain, direct English. Sections: Summary (what it costs,
   how long it takes, the big risks for this game) · Accounts & business setup · Technical/build
   requirements (mapped to the game's current settings: OK / needs change / blocked) · Store
   listing & assets (exact specs) · Forms & questionnaires (with the answers to give for THIS
   game) · Testing · Submission & review · After launch · Sources (URL + what it confirmed).

2. `<name>.tasks.json`: a JSON array of checklist tasks, in the order the owner should do them:
   {
     "id": "kebab-case, prefixed with the store key (e.g. apple-enroll)",
     "phase": one of "ready" | "accounts" | "builds" | "listing" | "testing" | "review" | "launch",
     "store": the store key you were given,
     "title": "imperative, at most 60 characters",
     "owner": "you" (only the owner can do it: accounts, payments, legal, devices) | "claude" (can be done in the repo) | "both",
     "status": "done" | "todo" | "blocked"  (based on the CURRENT state above; done only if it truly is),
     "statusNote": "one sentence on why, grounded in the repo state",
     "cost": "e.g. $99/year" or null,
     "time": "rough effort or wait, e.g. 30 min, 1-2 days review",
     "steps": ["short imperative steps, enough to actually do it"],
     "feedback": ["constructive tips, watch-outs, common rejection reasons for this step"],
     "doneMessage": "one encouraging sentence on what this unlocks / what to do next",
     "links": [{"label": "...", "url": "official URL"}],
     "depends": ["ids of tasks that must come first (may reference other stores' ids only if given)"]
   }
   Aim for thorough coverage (typically 15-30 tasks per store group). Keep each string short.

When finished, reply with a short summary: the 5-8 most important findings (with deadlines or
fees), anything that blocks this game specifically, and anything you could not verify.
