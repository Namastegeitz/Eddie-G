# Alien Sudoku: Upgrade Report

Run 1 · started Nov 27, 2026 · prompt: *Universal Upgrade & Release Build (Apps + Games)*

- Starting point: commit `826fc25` (tag `pre-upgrade-2026-11-27`, local). Every step after it is its own commit, so any step can be rolled back with `git revert`.
- Branch: the session's working branch `claude/peaceful-carson-qmcyku`. This environment only pushes there, so the commits stand in for the prompt's `upgrade/2026-11-27` branch.

## Recon

| | |
|---|---|
| What it is | A game: Sudoku with alien glyphs. Campaign (54 levels), Daily, Quick Play, Zen, Alien Duel (computer rival), achievements, 12 synthesized songs |
| Engine / framework | Vanilla JavaScript (ES modules) + Vite 8.3.5; Capacitor 8.6.0 for iOS and Android; Electron 45.2.1 + electron-builder 26.18 for Windows, macOS and Linux; PWA via vite-plugin-pwa 2.0 |
| Platforms and stores | App Store (iPhone, iPad), Google Play, Steam, GOG, itch.io, Epic, Microsoft Store, the web (GitHub Pages) |
| Backend | None. Everything is stored on the device |
| AI agents inside the app | None. The Alien Duel rival is a deterministic, seeded simulation, not an AI model |
| Monetization | Google AdMob on phones (banner, interstitial, rewarded) with Google's UMP consent; no purchases |
| Native code | None of its own; the APK has no `.so` libraries |

## Baseline (before any change)

Measured with `game/tools/perf-bench.mjs` (new): first pass median of 3 runs (the table below); the benchmark was then improved to pool frames over 4 runs of 8 s per scene, and `game/perf/baseline.json` holds that re-measurement of the untouched build. Headless Chromium, headless Chromium drawing on the CPU (pessimistic; real phones draw on the GPU). "Phone" = Pixel 7 screen with the CPU slowed 4x, like a mid-range phone. Raw numbers: `game/perf/baseline.json`.

| | Phone (CPU ÷4) | Desktop |
|---|---|---|
| Cold start to main menu | 1,170 ms | 734 ms |
| JS memory (menu / puzzle / map) | 3.1 / 3.6 / 3.4 MB | same |
| DOM size on the puzzle screen | 3,326 nodes | same |
| Menu: avg frame · fps · 1% low · worst | 16.7 ms · 59.8 · 59.5 fps · 33 ms | 16.7 ms · 60 · 59.5 fps · 17 ms |
| **Puzzle: avg · fps · 1% low · worst** | **17.4 ms · 57.4 · 29.9 fps · 50 ms** | 16.9 ms · 59.2 · **30 fps** · 33 ms |
| **Campaign map: avg · fps · 1% low · worst** | **18.3 ms · 54.8 · 29.9 fps · 33 ms** | 16.7 ms · 59.8 · 59.5 fps · 33 ms |
| Errors during the run | none | none |

What a 4-second trace of the puzzle screen shows (phone profile): **no slow JavaScript at all** (no call over 4 ms). The time goes to drawing: 70 main-thread tasks over 16 ms, led by layer updates and commits, and the starfield canvas being re-uploaded 31 times a second at full screen resolution (up to 9.5 ms each). Glow animations (`box-shadow` pulses) and `backdrop-filter` blurs add paint work.

| Build | Size |
|---|---|
| Android APK (release, R8) | 10.1 MB |
| Android App Bundle | 12.7 MB |
| Web build (`dist/`, offline cache) | 4.5 MB (2.8 MB of it backdrops), 92 cached files |
| One-file web game | 4.4 MB |
| Windows installer / portable | 116.8 / 106.2 MB |
| macOS zip (Intel / Apple Silicon) | 123.2 / 119.1 MB |
| Linux AppImage / deb | 102.9 / 103.3 MB |

| Check | Result |
|---|---|
| Web build | passes, no warnings |
| Android build | passes; Java "unchecked/deprecated" notes come from the plugins, not the game |
| 16 KB memory pages (Play, from Feb 1, 2027) | passes: no native libraries; `zipalign -c -P 16` OK |
| Unit tests | 116 / 116 pass |
| End-to-end tests (phone + desktop) | 42 pass, 2 skipped (keyboard test on phone); 1 duel test failed once under heavy load, then passed 6/6 |
| `npm audit` (game) | 8 moderate, all in build tools (`@capacitor/assets` → trapeze/xcode/uuid, `vite-plugin-pwa` → workbox-build/glob/minimatch/rimraf); nothing that ships to players |
| `npm audit` (desktop) | 6 moderate, all in `electron-builder` (packaging only) |
| Outdated | Capacitor 8.6.0 → 8.6.3, AdMob plugin 8.3.0 → 8.5.0, Vite 8.3.5 → 8.4.0, Vitest 5.1.0 → 5.1.2, Playwright 1.64.1 → 1.65.1, **Electron 45.2.1 → 45.5.0** (ships Chromium security fixes to desktop players) |

## Top 10 weaknesses (ranked by how much players feel them)

1. **Dropped frames on the puzzle screen and campaign map** at phone speed (1% low 30 fps, worst frame 50 ms = 3x the budget), with no way to lower detail on a weak phone (no graphics setting).
2. **No crash or error reporting.** Once the app is in stores, crashes on real phones are invisible until a player complains or Play's vitals drop.
3. **Desktop app runs an Electron with known-fixed security issues** (45.2.1; 45.5.0 is out).
4. **No in-game way to rate or report a problem.** Store ratings drive ranking; bug reports currently need the Launch Control page, which players never see.
5. **The six space backdrops have no proven license.** Their source is unknown; both stores ask you to confirm you hold the rights.
6. **Text size can't be changed in the game**, and all text is hard-coded English (not ready to translate).
7. **No automatic build and test on each push**: GitHub Actions jobs don't start on this account, so a release can't be rebuilt automatically from its tag.
8. **One flaky end-to-end test** (Alien Duel timing under load) can hide a real failure.
9. **Desktop builds are unsigned**: Windows SmartScreen and macOS Gatekeeper warn players on first launch.
10. **Build-tool advisories** (14 moderate) and small patch updates pending: no player risk today, but they should be cleared before a release build.

## Research (checked Nov 27, 2026)

"Opened" = the official page was read; "search" = the page was blocked here and the finding comes from search results, so re-check it before relying on it.

### a. Store rules

| Rule | Finding | Source |
|---|---|---|
| Play target API | New apps and updates must target API 36 since Aug 31, 2026. **Ours: 36 ✅** | developer.android.com/google/play/requirements/target-sdk (opened) |
| Play 16 KB pages | Updates without 16 KB support can't be released from Feb 1, 2027; apps with only Java/Kotlin code already pass. **Ours: no native libraries, `zipalign -P 16` OK ✅** | developer.android.com/guide/practices/page-sizes (opened) |
| Android vitals | Crash rate < 1.09% and ANR < 0.47% overall (8% per phone model), or Play shows the app less | developer.android.com/topic/performance/vitals (opened) |
| Play in-app review | Ask after real use; no questions before the card ("rate 5 stars?"); quota means calls may show nothing; don't put it behind a button | developer.android.com/guide/playcore/in-app-review (opened) |
| Apple review prompt | Up to 3 times in 365 days; custom review prompts are not allowed (5.6.1); no incentives | developer.apple.com/app-store/ratings-and-reviews, /app-store/review/guidelines (opened) |
| Apple build SDK | Xcode 26 / iOS 26 SDK since Apr 28, 2026; iOS 27 SDK from April 2027. **Ours: Codemagic uses the latest Xcode ✅** | developer.apple.com/news/upcoming-requirements (opened) |
| Apple age rating | New questions "Shared Location" and "Dating and Relationships" from Nov 16, 2026, required for every app by Jan 12, 2027; the social-media question since Sep 2026 | developer.apple.com/news/?id=yxkh08us, ?id=0d2gpmml (opened) |
| Apple Accessibility Nutrition Labels | Still voluntary; claim only what is tested | developer.apple.com/help/app-store-connect/manage-app-accessibility (opened) |
| Apple Kids rules | Only apply to Kids Category apps; not choosing Kids is fine | developer.apple.com/kids (opened) |
| Google Mobile Ads SDK | Android legacy v25 is deprecated Jun 30, 2027 (Next-Gen SDK preferred since Jul 2026); iOS v12 deprecated Q1 2027. Ours: Android 25.4.x, iOS 13.11.0 | developers.google.com/admob/…/deprecation (search) |
| SKAdNetwork | Google asks for cstr6suwn9 **plus** its list of third-party buyer IDs. **Ours: only cstr6suwn9 ⚠️** | developers.google.com/admob/ios/3p-skadnetworks (search; page blocked here) |
| UMP / consent | IAB TCF v2.3 for consent strings from Mar 1, 2026 (current UMP covers it); more US states in 2026–2028: pick "All current and future supported US states" in the AdMob US message | support.google.com/admob (search) |
| Play trader status | Declaration due Feb 1, 2027; news reports say trader address and phone show worldwide from Mar 1, 2027 (not only EU/UK) | Google Oct 29, 2026 announcement + news (search) |
| Microsoft Store | MSIX re-signed free by Microsoft; individual **and company** accounts free (since May 2026) | blogs.windows.com 2026-05-07 (search) |
| Steam | $100 Steam Direct fee unchanged; wait after paying reported as 30 days (our guide says 21); review up to ~12 business days in Nov 2026 | partner.steamgames.com (search) |

### b. Engine / framework

| Piece | Ours | Latest | Decision |
|---|---|---|---|
| Capacitor | 8.6.0 | 8.6.3 (Nov 25) | Update (patch) |
| AdMob plugin | 8.3.0 | 8.5.0 (Nov 27) | **Stay on 8.3.0**: same Google SDK versions (13.11.0 / 25.4.x), adds native-ad features we don't use and a new iOS dependency from an unfamiliar source (`webview-native-ui/engine`) published today |
| Vite / Vitest | 8.3.5 / 5.1.0 | 8.4.0 / 5.1.2 | Update (minor/patch) |
| Electron | 45.2.1 | 45.5.0 (Nov 24) | Update: ships Chromium security fixes to desktop players |
| electron-builder | 26.18.0 | 26.18.0 | Current |
| vite-plugin-pwa | 2.0.0 | 2.0.0 | Current; its build-time advisories only clear by downgrading to 1.1.0, so stay (inputs are our own files) |
| Playwright | 1.64.1 | 1.65.1 | **Stay**: the preinstalled test browser matches 1.64 |

### c. Dependencies
All on their current major; maintained (releases in the last 2 months). `npm audit`: 14 moderate, build tools only (see Baseline). `npm audit fix` (no breaking changes) clears the `@capacitor/assets` chain.

### d. Techniques for this stack and genre
- **Canvas:** cap the pixel ratio per quality level (1 / 1.5 / 2), draw ambient animation at 30 fps, pause when hidden; iOS caps animation at 30 fps in Low Power Mode anyway. (MDN "Optimizing canvas", opened)
- **CSS:** only `transform` and `opacity` animate on the compositor; animate a pre-drawn glow's opacity instead of `box-shadow`; keep blurs static; drop `backdrop-filter` on weak devices. (web.dev / developer.chrome.com, search)
- **Auto quality:** `deviceMemory` exists only on Android/Chrome; `hardwareConcurrency` is clamped on iOS, so measure frame times and step down at runtime. (MDN compat data, opened)
- **Text size:** the Android WebView follows the system font size by default, but iOS WKWebView ignores Dynamic Type; the official `@capacitor/text-zoom` plugin reads both. (Chromium AwSettings source, opened)
- **What top Sudoku apps have that we don't:** auto-fill all notes (Brainium, Good Sudoku), an optional "check mistakes" toggle (Sudoku.com, Brainium), hints that explain the technique (Good Sudoku), a left-handed layout (Brainium). (store listings via search)

### e. Live feedback
Not live yet: no store reviews to mine.

## Plan

### UPGRADES (code and build)

| # | What | Why (evidence) | Effort | Risk | Test |
|---|---|---|---|---|---|
| U1 | Graphics setting: Auto/Low/Medium/High/Ultra, resolution, frame rate, background motion, glow and blur | Weakness 1; trace shows drawing, not JS, is the cost | M | Low (High = old look) | unit + e2e + benchmark |
| U2 | Glow pulses on the map and the Alien board animate opacity, not `box-shadow` | Compositor-only animation (d) | S | Low | benchmark, screenshots |
| U3 | Half-size backdrops for Low | Memory on small phones | S | Low | e2e |
| U4 | Patch updates: Capacitor 8.6.3, Vite 8.4.0, Vitest 5.1.2, Electron 45.5.0, `npm audit fix` | Weakness 3, 10 | S | Low | full tests, Android build |
| U5 | Crash reporting with **Sentry + Firebase Crashlytics** (Eddie said yes), a "Send crash reports" switch, privacy policy and store-form updates | Weakness 2 | M | Medium (native SDKs) | unit, e2e, Android build; iOS on Codemagic |
| U6 | In-game "Send feedback" (email with version and device, plus recent errors) | Weakness 4 | S | Low | e2e |
| U7 | Text size setting (100–150%) | Weakness 6 | S | Low (layout) | screenshots at 3 sizes |
| U8 | Google's third-party SKAdNetwork IDs | Research (a) | S | Low | needs the list from Google's page (blocked here) |
| U9 | Visual regression screenshots at 3 sizes + benchmark gate (fail if >5% worse) | Step 9 | M | None | itself |
| U10 | Fix the flaky Alien Duel test | Weakness 8 | S | None | repeat-each 10 |
| U11 | Store kit, CHANGELOG, credits, release plan, CLAUDE.md | Step 10–11 | S | None | review |
| Later | Auto-fill notes, mistake-check toggle, explained hints, left-handed layout, translations, gamepad for Steam Deck, Next-Gen Android ads SDK before Jun 2027 | Research (d), (b) | M–L | | |

### ADD-ONS (installed or connected)

| Add-on | Maker | Cost | Adds | Alternatives | Decision |
|---|---|---|---|---|---|
| Sentry (`@sentry/capacitor`, `@sentry/browser`) | Sentry | Free Developer plan (1 user, about 5k errors/month) | Crash and error reports for phone, web and desktop, readable stack traces | Crashlytics only | **Yes** (Eddie, Nov 27) |
| Firebase Crashlytics (`@capacitor-firebase/crashlytics`) | Google (plugin by Capawesome) | Free | Native crash reports on iPhone and Android, crash-free rate | Sentry only | **Yes** (Eddie, Nov 27) |
| In-app review (`@capawesome/capacitor-app-review` 8.1.0) | Capawesome | Free, open source | The store's own rating card at a happy moment | Link to the store page only | **Yes** (Eddie, Nov 27) |
| Text zoom (`@capacitor/text-zoom` 8.0.1) | Ionic (official) | Free | Follows the phone's text-size setting on iPhone too | In-game setting only | **Yes** (Eddie, Nov 27) |
| Firebase Remote Config (`@capacitor-firebase/remote-config`) | Google / Capawesome | Free | Switch features off or show "please update" without a store release | None | **Yes** (Eddie, Nov 27) |
| Azure Artifact Signing | Microsoft | $9.99/month | Signed Windows installer (no "unknown publisher" warning over time) | Microsoft Store only (free signing) | **Not now** (Eddie, Nov 27) |
| rcodesign | Gregory Szorc (open source) | Free; needs the Apple membership | Sign and notarize the Mac app from Linux | Codemagic Mac build | **Not now** (Eddie, Nov 27) |
| PostHog analytics | PostHog | Free to 1M events/month | Funnels and A/B tests | None | **Not recommended**: breaks the "no analytics" promise in the privacy policy |

## Progress log

### Step 5-6: performance and graphics (U1-U3)
Graphics setting added (Settings → Graphics): Quality Auto/Low/Medium/High/Ultra, Resolution, Frame rate, Background motion, Glow and blur effects. High looks exactly like before; Auto starts from the device and steps down if frames keep running long. The map and Alien-board pulses now animate opacity only. Low uses new half-size backdrops (12 files, 1.2 MB).

Old build vs new build, alternating runs on the same machine (pooled frames, 4 runs x 8 s per scene; desktop: two extra 3-run pairs):

| Phone (CPU ÷4) | Before (2 runs) | After (2 runs, Auto) |
|---|---|---|
| Puzzle fps | 58.3 / 58.3 | **59.6 / 59.0** |
| Puzzle frames over 2x budget | 0.48% / 0.59% | **0.21% / 0.27%** |
| Map fps | 57.5 / 55.1 | **59.9 / 59.8** |
| Map frames over 2x budget | 0.82% / 1.93% | **0.10% / 0.10%** |
| Menu fps | 59.8 / 59.9 | 59.7 / 59.9 |

| Desktop | Before (2 runs) | After (2 runs) |
|---|---|---|
| Menu fps | 60.0 / 60.0 | 60.0 / 59.9 |
| Puzzle fps | 59.6 / 59.6 | 59.3 / 59.0 (within noise, under 1%) |
| Map fps | 59.9 / 59.8 | 59.7 / 60.0 |

Cold start and memory: unchanged within noise (1.1-1.4 s phone, 0.7-0.8 s desktop; 3.1-3.7 MB heap).
