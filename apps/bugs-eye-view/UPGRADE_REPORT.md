# Bug's-Eye View - Upgrade report (run of 27 Nov 2026)

Run of the *Universal Upgrade & Release Build Prompt*. Rollback point: git tag
`pre-upgrade-2026-11-27` (commit 8ea014e). Work is committed step by step on
branch `claude/nifty-lamport-bfm2ub` (the branch this environment pushes to;
nothing else is touched).

## Project
| | |
|---|---|
| Kind | 3D action-stealth game |
| Engine | Godot 4.7.2 stable, Compatibility renderer (GLES3 / WebGL 2), GDScript |
| Platforms | Web, Android (APK test + AAB for Play), iOS (Xcode project), Windows, macOS, Linux |
| Stores | Google Play, Apple App Store, Steam (+ Steam Deck), GOG, itch.io, Epic, Microsoft Store |
| Backend | None. Offline; saves are one JSON file in `user://` |
| AI agents in the app | None (NPCs are hand-written state machines) |
| Dependencies | Godot 4.7.2 + official export templates. Tools only: Python 3.13, Pillow 12.3.0, requests 2.34.2 (Meshy client, asset scripts). No Godot add-ons before this run |

## Baseline (measured 27 Nov 2026, before any change)
Machine: 4-core cloud container, no GPU (Mesa llvmpipe software rendering), so
rendered numbers are only for before/after comparison, not real-device fps.
Benchmark: `tools/bench/benchmark.tscn` (new) - each room with the cockroach
walking a slow circle for 600 frames with every person, pet and the vacuum active.

| Measure | Kitchen | Living room | Backyard |
|---|---|---|---|
| Game-logic frame time, avg (headless, 3 runs) | 1.05-1.09 ms | 1.16-1.20 ms | 0.98-1.06 ms |
| Game-logic frame time, 1% worst (p99) | 1.66-1.80 ms | 1.72-2.22 ms | 1.78-2.38 ms |
| Worst single frame | 2.6-3.8 ms | 2.5-7.6 ms | 2.6-3.6 ms |
| Frames over 2x budget (33 ms), logic | 0 | 0 | 0 |
| Room load time | 0.72-0.77 s | 0.73-0.77 s | 1.09-1.16 s |
| Memory (static, peak) | 97.5 MB | 97.6 MB | 101 MB |
| Objects in the scene tree | 4,180 | 4,478 | 4,247 |
| Draw calls (medium, rendered) | 92 | 87 | 235 |
| Rendered fps, 1280x720 medium (software GPU) | 2.8 | 4.5 | 3.1 |
| Rendered worst frame, medium (software GPU) | 1,153 ms | 1,157 ms | 690 ms |

| Measure | Value |
|---|---|
| Cold start to main menu | 0.83-0.95 s headless; 1.13-1.23 s rendered |
| Web download | 57 MB (39.5 MB engine + 20.7 MB game data), ~5 s on a fast link |
| Install sizes | Windows zip 47 MB, macOS 69 MB, Linux 37 MB, Web zip 21 MB, Android APK 68 MB |
| Build warnings | 0 (warnings are errors: `tools/check_warnings.sh`) |
| Tests | 165/165 smoke + 464/464 phase audit (project) + 165/165 + 437/437 (exported pack) + 11/11 Meshy client = 100% |
| Crashes / errors seen | 0 engine or script errors in the suites |
| Known vulnerabilities | None found in Godot 4.7.2's release notes or the two Python packages |

### Top 10 weaknesses (ranked by how much players would feel them)
1. **Saves are overwritten in place, with no backup.** A crash, power cut or full disk mid-save leaves a broken file and all progress resets to zero.
2. **Desktop saves moved folder on 17 Nov** (custom user dir `BugsEyeView`). Anyone who played an earlier desktop build would start from zero.
3. **No crash reporting.** Crashes on players' devices are invisible.
4. **First-time stutter.** The Compatibility renderer compiles each shader the first time it is drawn (no ubershaders there), so new objects and effects hitch, worst on phones and the web. The software-GPU worst frames above (0.7-1.2 s) are mostly this.
5. **The game keeps running when the window or tab loses focus** on desktop and web, so the bug gets caught while you're away.
6. **Graphics options are coarse.** Low/Medium/High also fix the frame cap (30/60/unlimited) and render scale. There's no Ultra for strong PCs, no 120 fps choice and no separate render scale.
7. **Screen shake can't be turned off** (only rumble/haptics). That's hard on motion-sensitive players, and Apple's *Reduced Motion* label needs it.
8. **Text size is fixed.** The smallest UI text is 13-14 px at the 720 px base size. Apple's *Larger Text* label needs 200%.
9. **No CI.** Tests and builds run by hand, so a broken push isn't caught.
10. **Not translation-ready.** All text is hard-coded English (no string tables).

## Research (checked 27 Nov 2026)
Pages marked "snippet" could only be seen as search results; the rest were opened.

**Engine**
- Latest stable Godot is still **4.7.2** (18 Aug 2026). 4.8 is at beta 5 (24 Nov 2026) with no release date. **Decision: stay on 4.7.2.** 4.8 adds Compatibility-renderer decals and mobile screen readers, but it isn't stable yet. Its breaking changes touching us are a sky-shader `SCREEN_UV` fix, a blocking `OS.alert()` on Android, and a touch double-press fix. https://github.com/godotengine/godot/releases , https://github.com/godotengine/godot-website/blob/master/collections/_article/dev-snapshot-godot-4-8-beta-5.md
- The Compatibility renderer supports MSAA 2x/4x/8x, SSAA (render scale above 1), bilinear render scaling only (no FSR), simplified glow, and simplified SSAO since 4.6 (radius and intensity only). It has **no** FXAA/TAA, SSR, SDFGI, volumetric fog, depth of field, decals or HDR output. https://github.com/godotengine/godot-docs/blob/stable/tutorials/rendering/renderers.rst
- **Shader stutter:** ubershaders and pipeline precompilation don't apply to Compatibility or Web. The docs' fix is to show every material, shader and particle on screen for one frame during loading. https://github.com/godotengine/godot-docs/blob/stable/tutorials/performance/pipeline_compilations.rst
- **Screen readers:** AccessKit works on Windows, macOS and Linux only in 4.7 (Auto mode, on when a screen reader runs). Mobile support comes in 4.8; none on the web. https://github.com/godotengine/godot-docs/blob/stable/classes/class_accessibilityserver.rst

**Stores (new since the 17 Nov research, see `BUG'S-EYE VIEW/Research/` for the rest)**
- **Apple:** two more age-rating questions (Shared Location; Dating and Relationships) went live 16 Nov 2026 and must be answered for every app by **12 Jan 2027**. Frequent cartoon violence is still **13+**. https://developer.apple.com/news/?id=yxkh08us
- **Apple:** from **April 2027** uploads need the iOS 27 SDK (Xcode 27). https://developer.apple.com/news/?id=k1mtkt1k
- **Apple:** a new screenshot requirement from April 2027. https://developer.apple.com/news/?id=kkphp5qo
- **Apple:** the Developer ID Sub-CA for signed Mac apps expires **1 Feb 2027**. https://developer.apple.com/news/
- **Apple Accessibility Nutrition Labels** are voluntary for now. A game may claim *Larger Text* with its own font-size setting reaching 200%, *Reduced Motion* with an in-game setting, *Differentiate Without Color* with shapes or icons alongside colour, and *Sufficient Contrast* at 4.5:1 text and 3:1 controls. Don't claim VoiceOver. https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels
- **Google Play vitals:** crash rate below 1.09% overall and 8% per phone model; ANR rate below 0.47% overall and 8% per phone model. Memory thresholds count toward visibility from **Feb 2027** (2.25 GB foreground on 4 GB phones). https://developer.android.com/games/optimize/vitals
- **Google Play:** target API 36 now (the extension ended 1 Nov 2026). From **1 Feb 2027**, updates without 16 KB page support are blocked. https://developer.android.com/google/play/requirements/target-sdk , https://developer.android.com/guide/practices/page-sizes
- **Google Play foldables:** from **Apr 2027**, 3 foldable screenshots and 1 phone screenshot. From **Aug 2027**, games must be "Tier 3 Ready": keep game state and touch alignment through fold, rotation and resize. https://developer.android.com/blog/posts/elevating-game-quality-foldables-large-screens-google-play
- **Android developer verification** goes global from **Jan 2027** for every install source, so the itch.io APK needs registering too. https://developer.android.com/blog/posts/android-developer-verification-2027.md.txt
- **Play in-app review:** only after real play, never after a "do you like it?" question or from a "Rate us" button, and no rewards. https://developer.android.com/guide/playcore/in-app-review
- **Steam Deck Verified** (snippet): full controller play with the default config, Xbox/Deck glyphs, smallest text 9 px or more at 1280x800, no launcher. https://partner.steamgames.com/doc/steamdeck/compat
- **Steam** (snippet): stricter pre-release build review since early Nov 2026. You must play the build through Steam for 5+ minutes and tag the screenshots.
- **Microsoft Store** (snippet): declare no MSIX capabilities you don't need, or the privacy-policy question is forced. The IARC questionnaire is mandatory. https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/support-info

**Add-on facts**
- **Sentry Godot SDK** 2.5.1 (12 Nov 2026), MIT, Godot 4.5+. Runs on Windows, Linux, macOS, Android, iOS and Web.
  - Sends device/OS details, crash minidumps and the Godot log. No personal data by default.
  - The free Developer plan is 1 user and 5,000 errors a month (pricing page snippet only; re-check).
  - https://github.com/getsentry/sentry-godot
- **GdUnit4** 6.2.3 (MIT; Godot 4.5-4.7.1; headless needs `--ignoreHeadlessMode`). https://github.com/godot-gdunit-labs/gdUnit4
- **GUT** 9.7.1 (MIT; Godot 4.7). https://github.com/bitwes/Gut
- **In-app review:** no official Godot plugin. Best maintained: `godot-mobile-plugins/godot-inapp-review` v5.3 (MIT), built against 4.7 beta 1. https://github.com/godot-mobile-plugins/godot-inapp-review

## Plan
### UPGRADES (code and build; no add-on needed)
| # | What | Why (evidence) | Effort | Risk | Test |
|---|---|---|---|---|---|
| U1 | Safe saves: write to a temp file, keep the last good save as a backup, load the backup if the main file is broken | Weakness 1 | S | Low | Corrupt-file and backup tests |
| U2 | Move saves from the old desktop folder on first launch | Weakness 2 | S | Low | Migration test with scratch folders |
| U3 | Load test for a save from the first public version | "Protect data" rule | S | None | New test |
| U4 | Pause when the window or tab loses focus (setting, on by default) | Weakness 5 | S | Low | Notification test |
| U5 | Shader warm-up while a room loads | Weakness 4, Godot docs | M | Low | Worst-frame before/after |
| U6 | Graphics: Ultra preset (MSAA 8x, SSAO, 16x filtering), frame-rate cap (incl. 120), render scale; each defaults to today's preset values | Weakness 6 | M | Low | Settings tests + screenshots |
| U7 | Screen shake on/off (reduced motion) | Weakness 7, Apple label | S | None | Test |
| U8 | Text size 100-200% | Weakness 8, Apple label, Steam Deck | M | Medium (layout) | Screenshots at 3 sizes |
| U9 | Benchmark with a 5% gate | Prompt step 9 | S | None | Itself |
| U10 | Screenshot regression of key screens at 3 sizes | Prompt step 9 | M | None | Itself |
| U11 | GitHub Actions: tests on every push to the game, all builds on demand or on a release tag | Weakness 9 | M | None | Workflow lint + local dry run |
| U12 | Version bump script (version + build number in every preset) and a player CHANGELOG | Prompt step 10 | S | None | Script test |
| U13 | `store-kit/`: credits and rights, What's New, video shot list, accessibility answers, release and rollback plan | Prompt step 10 | S | None | Review |

Deferred, with the reason:
- **Translation string tables** (L): a big refactor with no translation planned yet.
- **Screen-reader names** (desktop only in 4.7): do this with 4.8.
- **Assist mode**: a gameplay balance change; it needs your input on the game's difficulty.
- **Godot 4.8**: not stable yet.

### ADD-ONS (installed or connected)
| # | Add-on | Maker | Cost | Adds | Decision |
|---|---|---|---|---|---|
| A1 | Sentry Godot SDK 2.5.1 + Sentry.io | Sentry (SDK MIT) | Free Developer plan (5k errors/mo) | Crash and error reports on every platform | **Yes** (Eddie, 27 Nov) |
| A2 | Firebase Crashlytics | Google | Free (Spark plan) | Android crash reports in the Firebase console | **Yes** (Eddie, 27 Nov) |
| A3 | GdUnit4 or GUT | Open source (MIT) | Free | Unit-test framework inside Godot | **Not now** (Eddie, 28 Nov): existing suites cover it |
| A4 | In-app review prompt plugin | Community, MIT | Free | Play/App Store rating card at a happy moment | **Later, after launch** (Eddie, 28 Nov) |
| A5 | fastlane | Open source | Free | Scripted store uploads and screenshot frames | **Later, once accounts exist** (Eddie, 28 Nov) |
| A6 | Azure Artifact Signing | Microsoft | About $10/mo (US/Canada individuals) | Signed Windows downloads for itch.io | **No, stay free** (Eddie, 28 Nov) |
| - | PostHog / Firebase Analytics / Remote Config | - | Free tiers | Analytics and remote switches | Not proposed: the game is offline and collects no usage data |

Crash reporting changes what the game collects, so it ships with:
- a one-time consent card (nothing is sent before *Yes*);
- a Settings switch;
- no personal data (`send_default_pii` off);
- an updated privacy policy and Data safety / App Privacy answers.

## Results (after the upgrade, 28 Nov 2026)
### Before / after
| Measure | Before | After | Change |
|---|---|---|---|
| Game-logic frame time, all three rooms (median of 3, headless) | 3.295 ms | 3.091 ms | **6.2% faster** (gate: 5% slower fails) |
| 1% worst logic frame (p99) - kitchen / living room / backyard | 1.68 / 1.96 / 2.11 ms | 2.07 / 1.70 / 1.54 ms | Within run-to-run noise |
| Worst rendered frame, software GPU - backyard | 685 ms | 376 ms | **45% shorter** (shader warm-up) |
| Worst rendered frame, software GPU - kitchen | 1,014 ms | 610 ms | **40% shorter** |
| Worst rendered frame, software GPU - living room | 980 ms | 256 ms | **74% shorter** |
| Average rendered frame, software GPU | 299 / 339 / 211 ms | 289 / 332 / 199 ms | 2-6% faster |
| Room load time, software GPU | 5.1-7.6 s | 7.4-10.1 s | +2.4-3.3 s, all under the black loading fade (the shader compiling moved out of play) |
| Memory (static peak) | 97.4-101.0 MB | 97.7-101.1 MB | Same |
| Cold start to main menu (headless) | 0.83-0.95 s | 0.73-0.74 s | Same or better |
| Crash-free rate | Unknown (no reporting) | Measured once players opt in | New |
| Lost-progress risk on a crash mid-save | Whole save | None (backup + temp-file swap) | Fixed |
| Tests | 1,242 checks (165 + 464 project, 165 + 437 pack, 11 Meshy) | 1,312 checks (165 + 500, 165 + 471, 11) + benchmark gate + 14 screenshot comparisons | +70 checks, all passing |
| Build warnings | 0 | 0 | |
| Install sizes | Win 47.0 / Mac 68.7 / Linux 37.4 / Web 21.1 / APK 67.7 MB | Win 46.9 / Mac 68.7 / Linux 37.4 / Web 21.1 / APK 67.7 MB | Same (crash-report SDKs are only added to store builds by the release workflow) |

Rendered numbers come from a software GPU (no graphics card in the cloud
machine), so only the direction and size of a change carry over to real
devices, not the absolute fps.

### What was added
See the plan table above (U1-U13, A1-A2). Every change sits behind a
setting or flag whose default keeps the game as it was, except two:
- the shader warm-up, which is invisible and has a code flag;
- the safe-save swap, which is invisible and loads old saves unchanged (tested).

### Deferred, and why
- **Translation tables:** a large refactor with no translation planned yet.
- **Screen-reader names:** desktop only in Godot 4.7; do it with 4.8.
- **Assist mode:** needs your call on difficulty.
- **Crashlytics on iOS:** needs the Firebase iOS SDK in a Mac build; Sentry covers iOS in the meantime.
- **Readable native stack traces:** need Godot export templates built with debug symbols. GDScript errors already arrive with script stack traces.
- **Auto text size for phones.**

### Open questions for Eddie
- Was the Meshy plan paid when the fridge models were made (17 Nov)? If it was free, the models need a CC BY credit (`store-kit/credits.md`).
- The test workflow runs on every push that changes the game, about 15 minutes each. That's fine on a public repo; on a private repo it uses Actions minutes (2,000 a month free). Say if you'd rather it run only on demand.

## Store readiness (28 Nov 2026)
| Item | Status |
|---|---|
| Google Play target API 36 | PASS (AAB preset) |
| 16 KB page alignment (Godot + Crashlytics libraries) | PASS (checked with readelf) |
| Google Play signed release bundle | WAITING ON YOU (upload key) |
| Google Play Data safety / content rating answers | PASS (updated for optional crash reports) |
| Privacy policy reachable on the web and in the game | PARTLY: written and linked in game; WAITING ON YOU to make the page public |
| Support email in policy and listings | FAIL - not created yet (checklist phase 1) |
| Apple: Xcode 26 / iOS 26 SDK build | WAITING (needs a Mac or Mac CI runner) |
| Apple: UIScene manifest, privacy manifest, encryption flag | PASS |
| Apple: new age-rating questions (due 12 Jan 2027) | PASS (answers written; enter them in App Store Connect) |
| Apple: Team ID in the iOS preset | FAIL - placeholder ABCDE12345 |
| Apple accessibility labels | Answers ready; claim Reduced Motion / Larger Text after an iPhone check |
| Screenshots for every store size | PASS |
| Steam: Windows + Linux builds, capsules, Deck text size (9 px+ at 1280x800) | PASS |
| macOS notarization (Steam/Epic Mac) | WAITING (Apple account; Developer ID G2 certificate) |
| Microsoft Store MSIX | WAITING (Partner Center identity) |
| itch.io web zip | PASS |
| Crash reporting live | WAITING ON YOU (free Sentry + Firebase accounts, two GitHub secrets) |
| Asset rights | PASS except the Meshy models (check your plan) |
| All tests, perf gate, screenshot check | PASS |

## Next 3 upgrades worth doing
1. **Phone-first readability:** default text size by screen size (HUD text is about 7 px on a phone at 100%), then claim Apple's *Larger Text* label after a device check.
2. **Readable native crash traces and iOS Crashlytics:** Godot export templates with debug symbols uploaded to Sentry, and Firebase in the iOS build on a Mac runner.
3. **Godot 4.8 when stable:** Compatibility-renderer decals for richer rooms, screen readers on mobile, then translation-ready text.
