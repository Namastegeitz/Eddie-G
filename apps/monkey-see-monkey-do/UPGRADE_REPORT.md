# **MONKEY SEE, MONKEY DO** · Upgrade report, 27 Nov 2026

Run of the *Universal Upgrade + Release Build* prompt (apps and games).

- Branch: `upgrade/2026-11-27-monkey-see-monkey-do` (the date alone, `upgrade/2026-11-27`, could clash with other projects in this repository that run the same prompt today).
- Rollback point: commit `8ea014e`, tagged `pre-upgrade-2026-11-27-monkey-see-monkey-do` locally. GitHub refused tag pushes from this environment, so the commit hash is the remote rollback reference.
- Every change below is additive: new behaviour sits behind a setting whose default keeps today's behaviour, unless the line says otherwise.

## Baseline (before any change)

**What it is:** a 3D rhythm and memory game. Plain JavaScript modules, three.js r162 (WebGL 2, with WebGL 1 fallback), bundled with esbuild 0.24.2. Wrappers: Capacitor 8.5.3 (Android, iOS) with cordova-plugin-purchase 13.19.1 for in-app purchases; Electron 36.9.5 + electron-builder 25.1.8 for the PC edition (no purchases). No backend, no accounts, no analytics; saves live on the device. No AI agents inside the app.

**Targets:** App Store, Google Play, Steam, GOG, Microsoft Store, Epic, itch.io, plus the public web beta on GitHub Pages.

**Measured on this machine** (Linux, Chromium with the SwiftShader software renderer, no GPU, phone-sized 390x844 window). Software rendering is 10-50x slower than a phone GPU, so the times are for before/after comparison here, not real-device numbers. Draw calls and triangles are the same on any device.

| Measure | Baseline |
|---|---|
| Build | `node scripts/build_web.mjs`: OK, no warnings |
| Web build size | dist/www 1.3 MB; app.js 1,004 KB (286 KB gzipped); single-file HTML 1.1 MB; web/itch.io zips 0.47 MB |
| Cold start to playable | 5.6 s (software renderer) |
| JS memory | 21.7 MB after start, 20.4 MB after a level |
| Playing level 1 on Low | 5.6 fps average, 1% low 1.9 fps, worst frame 533 ms, 5 spikes over 2x average (software) |
| Frame draw time, all 4 stages x Low/High | total 1,174 ms; jungle Low 130 / High 332 ms; beach 82 / 147; disco 97 / 160; moon 79 / 147 |
| Draw calls / triangles | Low 94-119 calls, 86k-102k triangles; High 117-143 calls, 130k-199k triangles |
| First time a stage is shown (build + shader compile) | beach 3,486 ms, disco 383 ms, moon 589 ms: a visible freeze when a new map first appears |
| Errors | none in the page during the benchmark or the test runs |
| Tests | rules 767/767; play-through 35/35; device checks 15/15; live beta site 13/13 |
| Dependencies | three r162; @capacitor/* 8.5.3 (app 8.1.2, haptics 8.0.2, splash 8.0.2, keep-awake 8.0.1); cordova-plugin-purchase 13.19.1; electron 36.9.5; electron-builder 25.1.8; esbuild 0.24.2; Playwright 1.63 (test machine) |
| Known vulnerabilities | phone tooling: 3 moderate (`@capacitor/cli` 8.5.0-8.5.3 and its `uuid`, `xcode`); desktop: 18 (1 critical `tar`, 13 high incl. Electron itself and electron-builder's chain, 4 moderate) |

Benchmark: `node tests/benchmark.js` (baseline saved in `tests/benchmark-baseline.json`).

### Top 10 weaknesses, ranked by how much players feel them

1. **A freeze the first time a new map appears.** Building and compiling the beach took 3.5 s here; on phones it is a short but visible hitch at level 4, then again for disco and moon.
2. **No safety net for errors.** No global error handler, no saved error log, and no recovery if the phone's GPU resets (WebGL context loss after backgrounding shows a frozen or black screen).
3. **The PC edition has no controller support**, and the keys can't be changed. Steam and Steam Deck players expect a gamepad to work.
4. **The desktop wrapper runs an end-of-life Electron (36)** with known high-severity security issues, and its build tool pulls a critical `tar` issue.
5. **Graphics settle once and never adapt.** Auto measures only at start, so a phone that heats up and slows down mid-session stays on a level it can no longer hold. There is no frame-rate cap (battery) or resolution-scale option.
6. **The High jungle is heavy** (2.6x Low's draw time here), so mid-range phones depend entirely on Auto stepping down.
7. **Testers can't easily report from inside the game.** Reporting needs the separate claude.ai page and an invite; nothing in the game copies the device details and recent errors for them.
8. **Web beta testers may play an old copy** after an update, because nothing tells an open game that a new version is ready.
9. **Capacitor 8.5.3 misses 8.6.3's security hardening** of its internal proxy routes.
10. **Release paperwork gaps:** no changelog in plain words, a fixed version with no build number, no asset credits list, no accessibility-label answers, no staged-rollout plan, and every on-screen string lives in code (not ready for translation).

## Research (checked 27 Nov 2026)

Three research passes ran in parallel. Some official sites were blocked from this environment (capacitorjs.com, electronjs.org, threejs.org, MDN, GOG); the same facts were read from their GitHub sources or the npm registry instead.

### Store rules for this game

| Store | Rule today | This game | Source |
|---|---|---|---|
| Apple | Build with Xcode 26 / iOS 26 SDK (since 28 Apr 2026) | Applies; needs a Mac or cloud Mac | [Apple](https://developer.apple.com/news/upcoming-requirements/) |
| Apple | New age-rating questions, ratings 4+/9+/13+/16+/18+ (since 31 Jan 2026) | Answers drafted in `release/00-shared/age-rating.md` | [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions) |
| Apple | Privacy manifest for listed SDKs | Capacitor iOS 8.6.3 ships its own; our code uses no required-reason API, so no app-level manifest is needed. Confirm with Xcode's privacy report at build time | [Apple](https://developer.apple.com/support/third-party-SDK-requirements/) |
| Apple | Accessibility Nutrition Labels: voluntary now, "will become required" (no date) | Answers drafted in `store-kit/accessibility-labels.md` | [Apple](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels) |
| Apple | Kids: parental gate before purchases; restore purchases | Already in the game (Settings: parental gate on by default; Restore purchases) | [Guidelines](https://developer.apple.com/app-store/review/guidelines/) |
| Apple | Screenshots: required iPhone set is now 1206x2622 (6.3"); 1320x2868 still accepted; iPad 2064x2752 | We have 1320x2868 and 2064x2752; 1206x2622 set is a next step | [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) |
| Apple + Google | US state age-check laws (Texas from 4 Jun 2026, Utah, Louisiana): age-range APIs and parental consent "where legally required" | **Open question for Eddie: needs legal advice** for a kids game with purchases | [Apple](https://developer.apple.com/news/?id=sg176nne), [Google](https://developer.android.com/google/play/age-signals/overview) |
| Google Play | Target API 36 (since 31 Aug 2026, extensions ended 1 Nov) | Met: targetSdk 36 | [Android](https://developer.android.com/google/play/requirements/target-sdk) |
| Google Play | Play Billing Library 8+ | Met: cordova-plugin-purchase 13.19.1 bundles PBL 9.0.0 | [Android](https://developer.android.com/google/play/billing/deprecation-faq) |
| Google Play | 16 KB memory pages (1 Feb 2027) | Low risk: no native libraries in our packages; check the final bundle | [Android](https://developer.android.com/guide/practices/page-sizes) |
| Google Play | Developer verification (2026-27) | Play-only developers: no new action | [Android](https://developer.android.com/developer-verification/guides/google-play-console) |
| Google Play | New personal accounts: closed test, 12 testers, 14 days | Applies if the account is new | [Play Help](https://support.google.com/googleplay/android-developer/answer/14151465) |
| Google Play | Vitals: crash rate under 1.09%, ANR under 0.47% | Applies; new game memory thresholds from Feb 2027 | [Android](https://developer.android.com/topic/performance/vitals) |
| Google Play | Families policy if children are in the audience: no ad ID, only approved SDKs | Applies; shapes the crash-report add-on question | [Play Help](https://support.google.com/googleplay/android-developer/answer/9893335) |
| Steam | $100 fee, **21-day** wait after paying (our docs said 30), Coming Soon page 2+ weeks | Docs corrected | [Steam](https://partner.steamgames.com/steamdirect) |
| Steam | Deck Verified: default controller config reaches everything, device glyphs, text 9 px+ at 1280x800, 30 fps at 800p | Controller support added this run (see Upgrades) | [Steam](https://partner.steamgames.com/doc/steamdeck/compat) |
| Microsoft | Free individual registration; MSIX re-signed by Microsoft; Electron can be packaged as MSIX | Applies | [Microsoft](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements) |
| itch.io | HTML5 zip: 1,000 files, 500 MB, 200 MB per file | Met: 15 files, 0.47 MB | [itch.io](https://itch.io/docs/creators/html5) |
| Epic | $100 fee, recouped at $1,000; achievements rule only if 5+ on another PC store | Applies | [Epic](https://dev.epicgames.com/docs/epic-games-store/requirements-guidelines/distribution-requirements/requirements-overview) |

### Engine and dependencies

| Dependency | Ours | Latest (date) | Decision | Source |
|---|---|---|---|---|
| three.js | r162 | r187 (30 Oct 2026) | **Pin r162.** r163 removed WebGL 1 (our fallback for older Androids); later releases rewrote the shadow and light shader chunks our patches touch and turned PCFSoft shadows into PCF. r162 already has `compileAsync`, AgX and Neutral tone mapping | [r163](https://github.com/mrdoob/three.js/releases/tag/r163), [migration guide](https://github.com/mrdoob/three.js/wiki/Migration-Guide) |
| Capacitor | 8.5.3 | 8.6.3 (25 Nov 2026) | **Upgrade now** (minor; hardens internal proxy routes; fixes the moderate CLI advisories). Capacitor 9 is still a release candidate | [releases](https://github.com/ionic-team/capacitor/releases) |
| cordova-plugin-purchase | 13.19.1 | 13.20.0 | Later: 13.20.0 changes when purchase errors count as temporary; needs a careful test of entitlement logic on a real store account | [releases](https://github.com/j3k0/cordova-plugin-purchase/releases) |
| Electron | 36.9.5 | 45.5.0 (24 Nov 2026) | **36 is end-of-life; 45 advisories apply (12 high).** Major upgrade: needs Eddie's yes | [timelines](https://raw.githubusercontent.com/electron/electron/main/docs/tutorial/electron-timelines.md) |
| electron-builder | 25.1.8 | 26.18 | Upgrade with Electron (its dependency chain carries the critical `tar` issue) | [releases](https://github.com/electron-userland/electron-builder/releases) |
| esbuild | 0.24.2 | 0.28.2 | Pin: the one advisory affects its dev server, which we never use; 0.25 and 0.27 break compatibility on purpose | [GHSA-67mh-4wv8-2f99](https://github.com/advisories/GHSA-67mh-4wv8-2f99) |

### Techniques worth adopting (from current docs)

- Pre-warm each stage with `compileAsync` and `initTexture` using the real lights, fog and shadows ([three.js r162 docs](https://github.com/mrdoob/three.js/blob/r162/docs/api/en/renderers/WebGLRenderer.html)).
- Frame-rate cap by skipping frames against a time budget; average frame rate over time with bounds so quality doesn't flip back and forth ([react-three-fiber scaling guide](https://raw.githubusercontent.com/pmndrs/react-three-fiber/master/docs/advanced/scaling-performance.mdx)).
- Gamepad API standard mapping; `getGamepads()` is empty until a button is pressed ([W3C Gamepad](https://raw.githubusercontent.com/w3c/gamepad/gh-pages/index.html)). Steam: device glyphs, default config, ship a native Linux build for Deck because Electron + Proton gamepad detection is unreliable ([Proton #8154](https://github.com/ValveSoftware/Proton/issues/8154)).
- Photosensitivity: no more than 3 flashes a second over 20% of the screen ([Xbox guideline 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)).
- Service-worker update prompt for the web build ([vite-pwa guide](https://raw.githubusercontent.com/vite-pwa/docs/main/guide/periodic-sw-updates.md)).
- Store review prompt only after a win; Apple shows it at most 3 times a year; Google forbids asking "do you like it?" first ([Apple HIG](https://developer.apple.com/design/human-interface-guidelines/ratings-and-reviews), [Android](https://developer.android.com/guide/playcore/in-app-review)).

Already in the game before this run: latency calibration, assist mode, slower tempo, relaxed/no timer, reduce motion, captions, key hints, haptics switch, audio sliders, parental gate, monthly spend limit, restore purchases, cloud-free save codes.

## Plan

### Upgrades (changes to the code and build)

| # | What | Why (evidence) | Effort | Risk | How it's tested |
|---|---|---|---|---|---|
| U1 | Get the next map ready ahead (build, upload textures, compile shaders while the results card or level map is up). Setting: Graphics > "Get maps ready ahead", on | Weakness 1: beach first appearance 3.5 s here | M | Low: builds only the map about to be played | Benchmark: first-use time after prepare; play-through |
| U2 | Error safety net: catch every unhandled error, keep the last 20 on the device, recover from a GPU reset (WebGL context loss) instead of a frozen screen | Weakness 2 | S | Low | Acceptance: forced context loss and restore; thrown error is logged |
| U3 | Settings > "Report a problem": version, device details and recent errors, with Copy, and links to the bug page and support page | Weakness 7 | S | None | Acceptance |
| U4 | Controller support (standard gamepad: shoulders = arms, triggers = legs, Y = head, A = flair; D-pad and A/B for menus; Start = pause) and re-mappable keyboard keys | Weakness 3; Steam/Deck rules | M | Low: new input only | Acceptance with a simulated gamepad; key remap round-trip |
| U5 | Graphics: Medium selectable; Frame rate cap (Max / 60 / 30); Sharpness (100 / 85 / 70%); Auto keeps watching and steps down once more if play stays slow for 5 s | Weakness 5; Step 6 | M | Low: defaults keep today's behaviour | Unit + acceptance; benchmark |
| U6 | Web: "a new version is ready" notice with a Reload button | Weakness 8 | S | None | Manual + code review (needs two deploys to see live) |
| U7 | Calmer flashing on the disco floor when Reduce motion is on (3 flashes a second or fewer) | Photosensitivity guideline | S | None | Acceptance check of the pulse rate |
| U8 | Capacitor 8.5.3 to 8.6.3 (phone wrapper) | Weakness 9; audit | S | Low (minor) | `npm audit`; `cap sync` (a full phone build needs Android SDK / a Mac) |
| U9 | Old-save round trip test from the first release's save format | Step 0 "protect data" | S | None | Unit |
| U10 | Release package: CHANGELOG.md, version 1.1.0 with a build number, `store-kit/` (credits and licences, accessibility-label answers, release and rollback plan, screenshot shot list), CI on every push (rules, build, smoke test), Steam 21-day fix | Weakness 10; Step 10 | M | None | CI run; docs review |

Deferred (with reason): moving every on-screen string into translation files (large; no translation planned yet); 1206x2622 iPhone screenshot set (the 1320x2868 set is still accepted); three.js upgrade (pinned, see above); cordova-plugin-purchase 13.20.0 (needs a real store test).

### Add-ons (things installed or connected; each needs Eddie's yes)

| Add-on | Maker | Cost | What it adds here | Alternatives / recommendation |
|---|---|---|---|---|
| Electron 45 + electron-builder 26 (major upgrade, an approval gate rather than an add-on) | OpenJS / electron-userland | Free | Security fixes for the PC edition (36 is end-of-life) | Recommend **yes** before any PC store release |
| Crash reporting: Sentry or Firebase Crashlytics | Sentry / Google | Free tiers | Crash reports from players' devices | Recommend **not yet**: the game promises "nothing collected"; adding it changes the privacy policy, Data safety and Apple labels, and Google's Families policy limits SDKs in kids' apps. U2/U3 give an on-device error log instead |
| In-app review prompt: `@capacitor-community/in-app-review` 8.0.0 | Capacitor Community (open source) | Free | Asks for a store rating after a cleared level, using Apple's and Google's own prompt | Recommend **yes** (Capawesome and Capgo make similar free plugins) |
| Android in-app updates: `@capawesome/capacitor-app-update` | Capawesome (open source) | Free | Prompts players on an old phone version to update | Optional; on iOS it can only open the App Store page |

Not asked this run, because they don't fit yet: PostHog (analytics, not suited to a kids game without a consent plan), Azure Artifact Signing (~$10/month; only for Windows downloads outside the stores, and Microsoft Store MSIX is signed free), fastlane and Maestro (need a Mac or phone emulators; worth it once phone builds start), GdUnit4/GUT (Godot only), EAS (Expo only), Grafana k6 (no backend).
