# **CANOPY CROSSING: UPGRADE REPORT**

Run of the *Universal Upgrade + Release Build* prompt, 2026-11-27.
Branch `upgrade/2026-11-27-canopy-crossing`, starting point tagged
`pre-upgrade-2026-11-27-canopy-crossing` (commit 8ea014e). Everything here is
additive: new behaviour sits behind a setting or a build-time key, and the
tag rolls it all back. Findings that come from the web are information, with
the source and the date checked.

## Project at a glance

| | |
|---|---|
| Kind | Game: portrait arcade crosser, 50 animals, 22 jungles x 10 levels, bird's-eye 2D + first-person 3D |
| Engine | Godot 4.7.2 stable, GDScript, GL Compatibility renderer on every platform |
| Platforms / stores | Android (Google Play, Amazon, Samsung), iOS (App Store), Windows/macOS/Linux (Steam, GOG, itch.io, Epic, Microsoft Store), Web (beta link, itch.io) |
| Backend | None. Saves, settings and the analytics log stay on the device (`canopy/analytics/endpoint` empty) |
| Network calls | Optional map-pack download (`Store.download_pack`), optional analytics POST (off) |
| AI agents inside the app | None (Meshy was used only at build time to make 3D models) |
| Add-ons before this run | None (no `addons/`); billing and ads are sandboxes |

## Baseline (before any change, tag pre-upgrade-2026-11-27-canopy-crossing)

Measured on this build machine (4 cores, **software** OpenGL: Mesa llvmpipe),
so frame times are far slower than any phone GPU and only compare runs on this
machine. Draw calls, objects and primitives don't depend on the machine.
Benchmark: `tools/benchmark.tscn` (added in this run, also run on the
pre-upgrade copy): Amazon level 5, seed 777, the bot playing, 720x1280.

| Measure (720x1280, Medium = phones, Amazon level 5) | Bird's-eye | First person |
|---|---|---|
| Draw calls a frame (average / worst) | **2,131 / 2,709** | 333 / 359 |
| Objects drawn a frame | 8,074 | 681 |
| Primitives (triangles) a frame | 69,713 | 613,605 |
| Frame time here (average, software GL) | 119 ms (same-session re-run; 88 ms in the first run, when the machine was idler) | 301 ms |
| 1% low / worst frame here | 6.6 fps / 156 ms | 2.7 fps / 378 ms |

| High (computers) | Bird's-eye | First person |
|---|---|---|
| Draw calls / objects / primitives | 2,222 / 8,236 / 81,215 | 544 / 892 / 1,377,702 |

Start-up (engine start to home screen drawn twice): 1.6-2.6 s here (varies with load).
Memory: 107 MB static (CPU side), 67 MB video (Medium), 100 MB (High).

| Other baseline facts | |
|---|---|
| Build | Web, Windows, macOS, Linux, iOS Xcode project: build clean (Nov 17-18). Android: could not build on this machine before (Google's SDK host was blocked); built in this run for the first time (see after) |
| Install size | Web download 39.3 MB game data + 39.5 MB engine; Windows zip 74 MB, Linux 70 MB, macOS 158 MB (Nov 17 builds) |
| Tests | Phase audit 423/423 (exported pack 422/422), 44 first-person scenes, 220/220 levels beaten by the bot, 23 calm songs in tune, web phone/tablet/mouse smoke test: all passing |
| Errors seen | No script errors in tests. Level sweep: "790090 ObjectDB instances were leaked at exit" (see weakness 1) |
| Memory leak probe | Each finished run left **146 objects** alive (its whole level) and the bot's planning copies leaked the same way |

## Top 10 weaknesses (ranked by how much players would feel them)

1. **Every finished run leaked its level** (a reference cycle between a run and its animal's abilities, and every copy the bot plans with). Memory grows through a session; Google Play will rate games on memory use from Feb 2027. **Fixed in this run.**
2. **No crash reporting**: a crash on a real phone is invisible to us. **Adding Sentry + Firebase Crashlytics (Eddie: yes, free tiers).**
3. **Never measured on a real phone GPU**: no frame-rate cap or 120 Hz option, no automatic quality drop when a phone runs hot or slow.
4. **The run doesn't pause when the app goes to the background** (a call, a notification, switching tabs on the web): coming back drops the player straight into play.
5. **CI would fail today**: both workflows use GitHub Actions on Node 20, which GitHub removed on 2026-09-23; the release workflow has never been run end to end.
6. **Purchases and ads are sandboxes** (store blockers already on the launch checklist; they wait for Eddie's Phase 1 decisions).
7. **Network calls have no time-outs or retries** (map-pack download, analytics upload): a weak connection can hang a download forever.
8. **Accessibility gaps**: screen-reader names only on the eye button, no text-size option, no gamepad navigation in menus.
9. **English only**: every string is in code, nothing is ready for translation.
10. **Store paperwork gaps**: no credits/licences list, no accessibility-label answers, no What's New text, no CHANGELOG, build numbers set by hand; Apple's required iPhone screenshot size changed.

## Research (checked 2026-11-27)

### a. Store rules (changes since the LAUNCH research of 2026-11-17)

Sources: developer.apple.com and developer.android.com read directly; items
marked [UNVERIFIED] were seen only through search results.

- **Apple, age rating**: three waves, not one. Jul 2025 tiers and questions (deadline 31 Jan 2026, now a precondition for any update); social-media questions required since Sep 2026; **Shared Location and Dating questions live since 16 Nov 2026, all apps by 12 Jan 2027**. https://developer.apple.com/news/?id=yxkh08us
- **Apple, SDK**: Xcode 26 / iOS 26 SDK since 28 Apr 2026; **from April 2027 the iOS 27 SDK and a minimum target of iOS 15** (ours is 15.0). https://developer.apple.com/app-store/submissions/
- **Apple, screenshots (corrects the earlier research)**: the required iPhone set is now **6.1-6.3" (1206x2622 or 1179x2556)**; 6.9" is optional; iPad 13" 2064x2752 required for iPad apps; **iPhone Duo (foldable) screenshots required from April 2027** (outer 1398x2034, inner 2007x2853). https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- **Apple, Accessibility Nutrition Labels**: voluntary today, "mandatory over time" with no date; a label counts only if every common task works with it. Criteria per label recorded in `store-kit/accessibility-labels.md`. https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels
- **Apple, guidelines** (last revised 16 Oct 2026): no prices in screenshots (2.3.14); no hidden or dormant features: remotely switched features must be declared to App Review (2.5.19). Developer ID Sub-CA expires 1 Feb 2027 (re-sign Mac builds). https://developer.apple.com/news/?id=ey6d8onl
- **Google Play**: target API 36 confirmed (extension ended 1 Nov 2026); 16 KB pages required for updates from 1 Feb 2027; vitals thresholds confirmed (crash 1.09%, ANR 0.47%, 8% per device) and **new memory thresholds may affect visibility from Feb 2027**; developer verification global in 2027; Play Billing Library 8 sunsets 31 Aug 2027 (plan for 9). https://developer.android.com/topic/performance/vitals · https://developer.android.com/16kb-page-size · https://developer.android.com/google/play/billing/deprecation-faq
- **Google Play** [UNVERIFIED]: 29 Oct 2026 policy update (Age Signals API, families ad-SDK certification); trader contact details shown publicly from 1 Mar 2027.
- **Steam**: no change after 17 Nov; build review currently up to 12 business days; the checklist now also asks for declared redistributables and working Steam Cloud if advertised [secondary sources].
- **Microsoft Store**: no change; company accounts also free since May 2026 [UNVERIFIED].

### b. Engine

Sources: the godotengine/godot and godot-docs repositories (4.7 branch and
tags), godot-builds release files; checked 2026-11-27.

- **Version**: 4.7.2 (2026-08-18) is the latest stable. 4.7.3 is in RC in the
  4.7 branch (a FreeType security fix, CVE-2026-95512, plus Compatibility
  fixes for AreaLight3D and particles): **take 4.7.3 when it ships** (drop-in
  patch). **4.8** is at beta 5 (2026-11-24): adds Compatibility decals and
  the Android screen reader, but rejects scripts that inherit their own inner
  classes and warns on class-level string comments. **Decision: pin 4.7.2**,
  test 4.8 in a branch at RC. https://github.com/godotengine/godot/compare/4.7.2-stable...4.7
- **Compatibility renderer (ours, on every platform)**: MSAA 3D yes; FXAA,
  SMAA, TAA, FSR no (bilinear scaling only); **SSAO yes since 4.6** (now used
  by Ultra); glow yes; soft-shadow filter quality respected (5/13-tap PCF);
  HDR output **no** (Mobile/Forward+ only); AreaLight3D yes but without
  shadows; no shader precompilation (ubershaders are Forward+/Mobile only):
  the game already warms first person up at level start, and the GLES3 shader
  cache helps from the second launch. https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- **Frame rate**: `Engine.max_fps` everywhere; iOS 120 Hz already on
  (`allow_high_refresh_rate`). Android 15+ holds games at 60 Hz unless the app
  calls `Surface.setFrameRate()`, which Godot 4.7/4.8 doesn't: deferred (needs
  a small Android plugin). No thermal API in Godot.
- **Accessibility**: AccessKit screen reader since 4.5, desktop only in 4.7
  (Android in 4.8). `accessibility_name` is set on the new Settings buttons
  and the eye button.
- **Tests**: GdUnit4 6.2.3 / GUT 9.7.1 support 4.7. Not added: the project's
  own phase audit (451 checks), level sweep, render checks and benchmark
  already cover what they would (see Add-ons).
- **Crash reporting**: Sentry SDK for Godot 2.5.1 (MIT, Godot 4.5+, all six
  platforms; Android needs Gradle builds, Web needs GDExtension support).
  Firebase Crashlytics has no official Godot plugin (godot-x/firebase 3.1.0 is
  a third-party option); we built a small Android plugin of our own.
- **Store compliance**: Godot 4.7.2's Android build uses NDK 29 (16 KB pages
  by default) and targets API 36: **verified on our APK** (64-bit libraries
  aligned 0x4000, zip aligned, target 36, only the VIBRATE permission). The iOS
  export writes a privacy manifest with required reasons (file timestamp,
  boot time, disk space); crash data is added when Sentry is built in.

### c. Dependencies

| Dependency | Pin | Latest (2026-11-27) | Action |
|---|---|---|---|
| actions/checkout | v4 (Node 20) | v7.0.1 (Node 24) | bump (Node 20 removed from Actions 2026-09-23) |
| actions/setup-java | v4 (Node 20) | v6.3.0 | bump, keep Temurin 17 |
| actions/cache | v4 (Node 20) | v6.1.0 | bump |
| actions/upload-artifact | v4 (Node 20) | v7.0.2 | bump |
| actions/upload-pages-artifact | v3 | v5.0.0 | bump (keep dotfiles with include-hidden-files) |
| actions/deploy-pages | v4 | v5.0.1 | bump |
| softprops/action-gh-release | v2 (unsupported) | v3.0.4 | bump |
| ubuntu-latest | floating | Ubuntu 26.04, default JDK 25 | keep, with explicit Java 17 (Godot 4.7.2's Gradle 8.11.1 can't run on 25) |
| Playwright (web smoke test) | 1.63.0 | 1.65.1 | keep for now (1.64/1.65 have breaking changes, no CVE forces it) |
| Godot Android build | AGP 8.6.1, Gradle 8.11.1, SDK 36, build-tools 36.1.0, NDK 29, Java 17 | (set by the engine) | keep; install platform 36 + build-tools 36.1.0 |
| Firebase Crashlytics (new) | 21.1.0 (+ NDK 21.1.0), BOM 35.2.0 | read from Google's Maven today | new |
| Pillow (tools only) | system | 13.0.0 (many 2026 CVEs fixed) | use >= 13 where tools install it |
| numpy (tools only) | system | 2.5.5 | no CVE; keep |
| Meshy (build-time models) | API v2/v1 | free-plan output is CC BY 4.0 (credit Meshy); paid-plan output is owned | credits list says which applies |

Sources: action.yml of each tag; https://github.blog/changelog/2026-09-23-node-20-is-no-longer-available-in-github-actions/ ;
https://github.com/actions/runner-images ; https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/java/app/config.gradle ;
https://dl.google.com/android/maven2/ (Firebase metadata) ; https://pypi.org/project/pillow/ ; https://www.meshy.ai/pricing

### d. Techniques and what the genre leaders do

Players notice most (sources: Crossy Road case studies, Apple Arcade reviews, store reviews, Google's Play Games Level Up guidelines):
1. Fair ads: rewarded and opt-in only (Crossy Road's model) - **we plan exactly this**.
2. Instant, fair hop controls and readable lanes - have it (contrast-checked lanes, colour-blind markers).
3. A big collectible roster with no duplicate rolls - have it (50 animals, no gacha).
4. Free gifts on a timer, daily rewards, quests - have daily rewards and daily challenge.
5. Live events and limited-time characters - season pass exists; events are content.
6. Reliable saves with cloud sync - local only today (deferred: needs Play Games / Game Center).
7. Leaderboards and achievements (Play Games wants 10+ achievements) - not yet (deferred, needs accounts).
8. Local co-op with controllers - not planned.
Most common complaints to avoid: ad frequency, pay-to-win, crashes after updates, lost progress, unfair deaths, sound while muted.

### e. Live feedback

The game is in a private beta (web link). The launch page's bug log has no reports yet; no store reviews exist.

## Plan

### UPGRADES (code and build)

| # | Upgrade | Why (evidence) | Effort | Risk | Tested by | Status |
|---|---|---|---|---|---|---|
| 1 | Fix the run/ability reference cycle | 146 objects leaked per run; 790k at the end of a level sweep | S | Low | audit: 4 runs + bot plans leave <= 2 objects | **Done** |
| 2 | Crash reporting (Sentry + Crashlytics) | No visibility of crashes on devices | M | Low (off without keys) | 9 audit checks with a stand-in plugin; plugin builds; install scripts dry-run | **Done** |
| 3 | CI on Node 24 actions; build number = commit count; SDK installs; Play pre-checks | Node 20 removed 2026-09-23; build numbers by hand | M | Medium (needs a run on GitHub) | YAML lint; scripts dry-run locally | **Done** (first GitHub run pending) |
| 4 | Remote switches + update prompts | No way to switch a broken feature off without a release | M | Low | 6 audit checks | **Done** |
| 5 | Store rating card | Genre leaders ask at happy moments | S | Low | 4 audit checks on timing | **Done** (plugin installed by CI) |
| 6 | Pause when the app loses focus | Players dropped back into play after a call | S | Low | audit check | **Done** |
| 7 | Network time-outs, analytics retry with backoff | Downloads could hang forever; failed batches were lost | S | Low | parse + run | **Done** |
| 8 | One draw call per figure (2D batching) | Profile: 2,131 draw calls a frame from the moving figures | M | Medium (drawing core) | pixel diff on/off (0.2%), perf gate, frame-cost check | **Done** |
| 9 | Graphics: Ultra, frame-rate cap, 3D resolution | Prompt step 6; SSAO available in Compatibility since 4.6 | S | Low | 3 audit checks | **Done** |
| 10 | Settings page fits the screen | It was a little wider than phones (and more so with new rows) | S | Low | screenshot | **Done** |
| 11 | Perf gate, secret scan, visual regression | Prompt step 9 | M | Low | repeat runs within 0.3% | **Done** |
| 12 | Store kit, CHANGELOG, release plan, signing notes | Prompt step 10 | M | None | review | **Done** |
| 13 | Android 120 Hz (`Surface.setFrameRate`) | Android 15+ holds games at 60 Hz | M | Medium | needs a phone | Deferred |
| 14 | Thermal quality step-down | Prompt step 5 | M | Medium | needs a phone | Deferred |
| 15 | Translations (strings to files) | English only | L | Medium | - | Deferred |
| 16 | Screen-reader names on every control, text-size option, gamepad menus | Accessibility | M | Low | - | Deferred (partly: new Settings rows are named) |
| 17 | Achievements + cloud saves | Play Games Level Up expects them | L | Medium | - | **Eddie: yes, after store accounts exist** |
| 18 | Godot 4.7.3 | Security fix in FreeType | S | Low | full tests | When released |

### ADD-ONS (installed or connected)

| Add-on | Maker | Cost (checked 2026-11-27) | What it adds | Eddie | Status |
|---|---|---|---|---|---|
| Sentry SDK for Godot 2.5.1 | Sentry (Functional Software) | Free Developer plan (about 5k errors/month) | Crash and error reports on every store build | **Yes** | Wired in; needs the free account + `SENTRY_DSN` |
| Firebase Crashlytics 21.1.0 | Google | Free (Spark) | Android crash reports incl. native crashes | **Yes** | Own plugin built; needs the Firebase project + `FIREBASE_ANDROID_CONFIG` |
| In-app Review plugin 5.3 | Godot Mobile Plugins (MIT) | Free | Store rating card | **Yes** | Installed by the release workflow |
| Remote switches | (none: a file on GitHub Pages) | Free | Kill switches, update prompts | **Yes (Pages file)** | Done; Pages must be switched on once |
| Play Games Services / Game Center | Google / Apple | Free | Achievements, cloud saves | **Yes, later** | Plan only |
| GdUnit4 / GUT | open source (MIT) | Free | Unit-test framework | not asked | Not needed: the phase audit covers it |
| Firebase Remote Config / PostHog | Google / PostHog | Free tiers | Remote config, analytics funnels | not needed | GitHub Pages file chosen instead |
| Azure Artifact Signing | Microsoft | ~$10/month | Signed Windows downloads | not asked | Not needed: Steam/GOG/Epic/MSIX don't require it |
| fastlane | open source | Free | Automated screenshots and uploads | not asked | Later, with the Mac build job |
| Maestro | mobile.dev | Free CLI | Tap-through tests on a phone | not asked | Later (needs devices or emulators) |

## Before / after

Measured back to back on 2026-11-28: the pre-upgrade copy (8ea014e) and
this branch, the same benchmark run twice each (240 frames, Amazon level 5,
seed 777, 720x1280, software OpenGL). Where the two runs differ, both are
shown. Frame times on this machine only compare with each other; draw calls,
objects and primitives are the same on any machine.

| Measure | Before | After | Change |
|---|---|---|---|
| Bird's-eye draw calls a frame, Medium (average / worst) | 2,131 / 2,710 | 347 / 383 | **-84%** |
| Bird's-eye objects drawn a frame, Medium | 8,074 | 2,727 | -66% |
| Bird's-eye primitives a frame, Medium | 69,722 | 55,600 | -20% (anti-aliased edges are now part of each figure's batch) |
| Bird's-eye frame time here, Medium (two runs) | 108.5 / 111.2 ms | 98.1 / 100.9 ms | **-9%** |
| Bird's-eye CPU time a frame here, Medium | 119.9 / 125.8 ms | 107.5 / 112.8 ms | -10% |
| Bird's-eye 1% low here, Medium | 6.6 / 6.7 fps | 7.7 / 6.9 fps | better or equal |
| Bird's-eye draw calls, High (computers) | 2,222 | 355 | -84% |
| Bird's-eye frame time here, High | 115.9 ms | 108.7 ms | -6% |
| First person, Medium: draw calls / objects / primitives | 332 / 680 / 612k | 332 / 680 / 610k | same (identical when started from the same spot) |
| First-person frame time here, Medium (two runs) | 359.7 / 359.8 ms | 380.5 / 356.9 ms | same within this machine's noise |
| Start-up to home screen here (two runs) | 1.93 / 1.86 s | 1.80 / 1.98 s | same |
| Memory, CPU side (static) | 106.8 MB | 108.3 MB | +1.5 MB (crash reporting, remote switches, batch buffers) |
| Video memory, Medium / High | 66.7 / 98.1 MB | 67.9 / 99.4 MB | +1.2 / +1.3 MB |
| Objects left behind by each finished run | 146 (the whole level) | 0 | **leak fixed** |
| Level sweep: objects leaked at exit | 790,090 | none reported | **fixed** |
| Level sweep: bot moves on all 220 levels | (reference) | identical, 220/220 beaten | gameplay unchanged |
| Phase audit checks | 423 (exported pack 422) | 451 (exported pack 450) | +28 (stability, crash reports, remote switches, review timing, graphics, credits) |
| Other test gates | first-person render, songs, level sweep | + performance gate (5%), secret scan, visual check at 3 sizes | +3 gates |
| Settings page width on a 720 px phone | wider than the screen (rows cut off) | fits at phone, tall-phone and tablet sizes | fixed (`upgrade-shots/settings_*.jpg`) |
| Crash reports | none | Sentry (all store builds) + Crashlytics (Android), switched on by 2 GitHub secrets | new |
| CI | Node 20 actions (removed by GitHub 2026-09-23), build numbers by hand | Node 24 actions, build number = commit count, Play pre-checks | fixed |
| Web download: game data + engine | 39.2 + 39.5 MB | 39.2 + 39.5 MB | same (+26 KB of code); now gated by `tests/size_budget.json` |
| Desktop zips: Windows / Linux / macOS (universal) | 74 / 70 / 158 MB (Nov 17 builds) | 75.6 / 66.0 / 97.3 MB | same engine and the same 39.2 MB game data inside |
| Android APK (arm64 + armv7) | could not be built here (no Android SDK) | 90.8 MB; passes the 16 KB page, target API 36, package and permission checks | new |

Caught during this run: the first web build after adding `upgrade-shots/`
packed those 12 pictures into the game (+8.6 MB on the web and in the APK).
Both picture folders now carry a `.gdignore`, and `tools/build_web.sh` fails
if the game data grows more than 5% over `tests/size_budget.json`.

Before/after pictures of 4 screens at 3 screen sizes: `upgrade-shots/`. They
match except Settings (new rows, and it now fits the screen); an ant pulling
a face in one first-person picture is the game's random silly-faces feature.

## Store readiness (2026-11-28)

PASS = done and checked in this run. FAIL = not ready yet, with who fixes it.
Nothing was uploaded to any store.

| # | Item | Result | Evidence / who fixes it |
|---|---|---|---|
| 1 | Google Play: target API 36 | PASS | `tools/check_android.sh` on the local APK (aapt2) |
| 2 | Google Play: 16 KB memory pages | PASS | zipalign `-P 16`; arm64 libraries aligned 0x4000 |
| 3 | Google Play: smallest permissions | PASS | Only VIBRATE |
| 4 | Google Play: release `.aab` | FAIL | Built by the release workflow, which has not run on GitHub yet (Eddie starts it; needs item 5) |
| 5 | Android upload key | FAIL | Eddie creates it and adds the 3 GitHub secrets (`LAUNCH`, step b-upload-key) |
| 6 | Version name and build number set automatically | PASS | Build number = commit count (`tools/set_version.py`, release workflow) |
| 7 | Version 1.0.0 for the first upload | FAIL | Still 0.9.0 (beta); set when Eddie says go |
| 8 | Data safety (Play) and App Privacy (Apple) answers | PASS | Drafted in `store-kit/data-safety.md`, crash reports included; Eddie types them in |
| 9 | Privacy policy at a public web address, linked in the game | FAIL | Draft ready (`LAUNCH/shared/privacy-policy.md`); needs Eddie's website, then a Settings link |
| 10 | Age-rating answers (IARC, Apple) | PASS | `LAUNCH/shared/content-rating-answers.md` |
| 11 | Store texts and What's New | PASS | `LAUNCH/shared/store-listing.md`, `store-kit/whats-new.md` |
| 12 | Credits and licences | PASS | `store-kit/credits.md` and the new Settings > Credits and licences screen (audit check) |
| 13 | Accessibility answers (Apple) | PASS | `store-kit/accessibility-labels.md` (honest: VoiceOver not yet supported in game) |
| 14 | Notes for App Review | PASS | `store-kit/review-notes.md` |
| 15 | Screenshots, feature graphic, preview video | FAIL | Shot list and sizes ready (`store-kit/screenshots.md`); pictures made after the store builds |
| 16 | Real purchases (Play Billing, StoreKit 2) | FAIL | Still the sandbox; waits on Eddie's Phase 1 money decision |
| 17 | Ads with consent screens, or ads off | FAIL | Same decision (between-run ads can be switched off remotely already) |
| 18 | Crash reporting | PASS (code) | Sentry + Crashlytics wired, 23 stability checks; reports start once Eddie adds `SENTRY_DSN` and `FIREBASE_ANDROID_CONFIG` |
| 19 | iOS Xcode project | PASS | Exported by `tools/build_all.sh ios` (signing and upload need Apple's account) |
| 20 | iOS privacy manifest | PASS | Written by Godot; `tools/install_sentry.sh` adds the crash-data entries |
| 21 | Apple export compliance | FAIL | Answer is "standard encryption only (HTTPS)": Eddie answers it at the first upload |
| 22 | Developer accounts (Apple, Google) | FAIL | Eddie (Phase 2 of the launch checklist) |
| 23 | Tests | PASS | Phase audit, exported pack, first person, performance gate, secret scan, level sweep, visual check |
| 24 | Roll-back plan | PASS | `store-kit/release-plan.md`, step commits, remote switches |

## Next 3 upgrades worth doing

1. **Smooth on every phone**: a small Android plugin that asks for 90/120 Hz
   (`Surface.setFrameRate`; Android 15+ holds games at 60 Hz otherwise), and a
   frame-time watchdog that drops one quality step when a phone runs hot or
   slow, then steps back up. Measure on 2-3 real phones first (Play Console's
   pre-launch report gives free ones).
2. **Achievements and cloud saves** (Eddie: yes, once the store accounts
   exist): Play Games Services v2 and Game Center, saves behind the existing
   `Save` format with a version field so nothing old breaks.
3. **Reach more players**: every string into translation files (Spanish and
   Portuguese first: the Amazon countries), screen-reader names on every
   control (Android screen reader arrives with Godot 4.8), a text-size
   setting, and following the phone's own Reduce Motion setting. That turns
   three Apple accessibility labels from No to Yes.
