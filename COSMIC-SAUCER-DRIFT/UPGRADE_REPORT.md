# **COSMIC SAUCER DRIFT** · Upgrade report (run of 27 Nov 2026)

Run of Eddie's *Universal Upgrade + Release Build Prompt (Apps + Games)*.
- **Branch:** `upgrade/2026-11-27`
- **Start point:** commit `8ea014e`, kept as the branch `rollback/pre-upgrade-2026-11-27` on
  GitHub (the cloud session can't push tags; the tag `pre-upgrade-2026-11-27` exists locally).
  Roll everything back with `git checkout rollback/pre-upgrade-2026-11-27`.
- **Rules:** every change is additive, behind a setting where it changes behaviour,
  tested, and committed per step.

No `UPGRADE_LEDGER.md` existed, so this is the first run.

## Baseline (Step 1, measured 27 Nov 2026 before any change)

**What it is.** A game: an arcade UFO kart racer.
- **Engine:** Godot **4.7.2 stable**, GDScript only, no third-party add-ons.
- **Renderer:** Compatibility (OpenGL / WebGL 2) on every platform.
- **Targets:** Android (Google Play, Galaxy Store, Amazon Fire), iOS/iPadOS (App Store),
  Windows/macOS/Linux (Steam, itch.io, GOG, Epic, Microsoft Store) and the web.
- **No backend, no accounts, no ads, no purchases, no analytics.** Saves stay on the device.
- **No AI agents inside the game.** Rival racers are scripted.

**Measured on this build machine.** It's a cloud computer with a *software* GPU (Mesa
llvmpipe), so frame rates are only comparable between runs here, not with phones.

| Measure | Medium graphics | High graphics |
|---|---|---|
| Benchmark | `tests/bench.tscn`, Io, 600 frames, autopilot race | same |
| Average frame time | 70.5 ms (14.2 fps) | 261.3 ms (3.8 fps) |
| 1% low | 10.6 fps | 3.0 fps |
| Worst spike | 186 ms (2 frames over 2× average) | 360 ms (0 over 2×) |
| CPU game logic per frame | process 77 ms, physics 7.3 ms | process 274 ms, physics 2.4 ms |
| Draw calls / objects per frame | 151 / 261 | 349 / 470 |
| Memory | 103 MB static, 57 MB video | 104 MB static, 74 MB video |

| Measure | Value |
|---|---|
| Cold start to the 3rd frame (Linux export) | 2.7–3.1 s (includes ~0.3 s to start the virtual display) |
| Main menu build | 244 ms |
| Race build (CPU) | 381–392 ms. By stage: racers 116, views 107, track 100, systems 26, data 17, decor 9 |
| Automated tests | **1,141 / 1,141** smoke checks pass, plus the AI race sim, 11 asset-pipeline checks and the drive check (0 s in reverse) |
| Build warnings | None while running. At exit: 2 Godot objects and 1 resource still alive (13 objects in the load probe) |
| Build sizes | Android APK 61.6 MB · web 46.6 MB (engine 37.7 + game data 6.9) · Windows 42.3 MB zip · Linux 33.1 MB zip · macOS 64.6 MB zip · iOS Xcode project 100 MB (2 zip parts) |
| Dependencies | Godot 4.7.2 engine and export templates only. Build tools use Python 3 + Pillow (not shipped). No known vulnerabilities in shipped code (no third-party code is shipped) |
| Crash / ANR rate | Unknown: the game isn't live yet and has no crash reporting |

### Top 10 weaknesses, by how much players would feel them

1. **Crashes on real devices would be invisible.** There's no crash reporting, so a crash on
   one phone model would only show up as 1-star reviews.
2. **Real-phone speed is unverified.** Every number above is from a software renderer. There's
   no low/mid/high phone check yet. Dynamic resolution and Auto graphics exist, but nothing
   proves they hold 60 fps.
3. **Accessibility gaps:**
   - no colour-blind option (items, rival markers and energy are told apart by colour)
   - no reduce-motion switch for speed lines and flashes (camera shake has one)
   - no text-size option
   - no control remapping
4. **English only.** All text is written straight into the code, so nothing can be
   translated yet.
5. **No way for players to send feedback or rate the game from inside it.** The checklist
   page collects bugs for Eddie only.
6. **No automatic build and test (CI).** Tests and exports run by hand, and a release can't yet
   be rebuilt automatically from a git tag.
7. **Graphics ceiling.** Compatibility is the only renderer, so High/Ultra can't use upscaling,
   ambient occlusion or screen-space reflections on phones and PCs that could run them.
8. **The web version is a 47 MB first download** (38 MB of it engine), which is slow on mobile data.
9. **Unsigned desktop builds:** Windows SmartScreen and macOS Gatekeeper warnings. The Play
   bundle isn't built yet because it waits on Eddie's upload key.
10. **Objects left alive at exit.** It's harmless today, but it makes real leaks harder to spot
    in tests.

Also open: 9 of the 10 HD Meshy craft are still waiting for credits. That's content, not quality.

## Research (Step 2, all checked 27 Nov 2026)

**[S]** marks findings read from a search snippet of the official page because the page itself
was blocked in this cloud session. Unconfirmed items are marked *unverified*.

### a. Store rules today (new since the 17 Nov kits in bold)
| Area | Requirement | When | Source |
|---|---|---|---|
| Apple SDK | Xcode 26 + iOS 26 SDK; minimum target iOS 13. **Next: iOS 27 SDK (Xcode 27) and minimum iOS 15** | Since 28 Apr 2026; **Apr 2027** | https://developer.apple.com/news/upcoming-requirements/ |
| Apple age rating | Updated questionnaire. **Two new questions ("Shared Location", "Dating and Relationships"); both "No" here** | Since 31 Jan 2026; **answer by 12 Jan 2027** | https://developer.apple.com/news/?id=yxkh08us |
| Apple privacy manifest | Required-reason APIs declared; Godot generates the manifest | Since May 2024 | https://developer.apple.com/support/third-party-SDK-requirements/ |
| Apple accessibility labels | Optional; "required over time", no date | — | https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels |
| **Apple iPhone Duo screenshots** | Every submission needs them | **Apr 2027** | https://developer.apple.com/news/?id=kkphp5qo |
| **Apple Developer ID CA** | Original sub-CA expires; re-sign .pkg files (notarized + timestamped apps keep working) | **1 Feb 2027** | https://developer.apple.com/news/ |
| Play target API | API 36 for new apps/updates. **API 37 required Aug 2027** | Since 31 Aug 2026 | https://developer.android.com/google/play/requirements/target-sdk |
| Play 16 KB pages | Updates without 16 KB support blocked | 1 Feb 2027 | https://developer.android.com/guide/practices/page-sizes |
| Android developer verification | 4 countries since 30 Sep 2026. **Global rollout starts Jan 2027** (Play, Galaxy Store and 5 more stores first) | Jan 2027 | https://developer.android.com/blog/posts/android-developer-verification-2027 |
| Android vitals | Crash < 1.09%, ANR < 0.47% (8% per model). **Memory vitals added (games: e.g. 2.25 GB foreground on 4 GB phones); from Feb 2027 they can cut visibility** | Ongoing; Feb 2027 | https://developer.android.com/topic/performance/vitals |
| **Play games on foldables** | ≥3 foldable screenshots + 1 phone screenshot (Apr 2027); "Tier 3 Ready" large-screen quality (Aug 2027) | **Apr / Aug 2027** | https://developer.android.com/blog/posts/elevating-game-quality-foldables-large-screens-google-play |
| Windows signing | Artifact Signing $9.99/month; individuals only in the US or Canada; MSIX in the Microsoft Store signed free | Ongoing | https://azure.microsoft.com/en-us/pricing/details/artifact-signing/ [S] |
| Account deletion | Only for apps with accounts: doesn't apply | — | https://developer.apple.com/support/offering-account-deletion-in-your-app/ |

### b. Engine
- Godot **4.7.2** (18 Aug 2026) is the newest stable release. There is no official 4.7.3.
- 4.8 is in **beta 5** (24 Nov 2026), with breaking changes in GDScript and input.
- 16 KB page support has been built in since 4.5.
- **Decision: stay on 4.7.2.** Try 4.8 on a branch once it's stable, using the 1,141-check
  harness and the benchmark.
- Sources: https://godotengine.org/article/maintenance-release-godot-4-7-2/ [S],
  https://github.com/godotengine/godot-builds/releases/tag/4.8-beta5 [S]

### c. Dependencies
None ship with the game: no third-party code. The build tools use Python 3 + Pillow.
Nothing to update or patch.

### d. Techniques for this stack and genre
- **4.7's HDR output, AreaLight3D, FSR 1/2 upscaling and TAA all need the Forward+ or Mobile
  renderer.** This game uses Compatibility everywhere, which is what lets it run on the web and
  on older phones.
  - Switching renderer is a major change, so it's gated: deferred.
  - Sources: https://docs.godotengine.org/en/4.7/tutorials/rendering/hdr_output.html [S],
    https://docs.godotengine.org/en/4.6/tutorials/3d/resolution_scaling.html [S]
- **120 Hz:**
  - Android 15+ runs games at 60 Hz unless they ask for more.
  - iPhones need the Info.plist key `CADisableMinimumFrameDurationOnPhone` for ProMotion.
  - Sources: https://developer.android.com/games/optimize/display-refresh-rate-change [S],
    https://developer.apple.com/forums/thread/690806 [S]
- **Accessibility common in racers:**
  - steering assist and auto-accelerate (the game has both)
  - difficulty (has)
  - vibration off (has)
  - camera-shake off (has)
  - colour-blind modes and motion-blur/effects toggles (EA's Need for Speed Unbound)
  - remapping and text size
  - Source: https://www.ea.com/en-ca/able/resources/need-for-speed-unbound [S]
- **Test frameworks:**
  - GdUnit4 v6.2.3 and GUT 9.7.1 are both MIT and both support 4.7.
  - They add unit tests and JUnit reports, which is only modest value next to the existing
    harness.
  - Sources: https://github.com/godot-gdunit-labs/gdUnit4, https://github.com/bitwes/Gut
- **CI:** chickensoft-games/setup-godot@v2 and firebelley/godot-export v8 (both MIT) run headless
  Godot on GitHub's Linux runners. iOS needs a macOS runner.
  - Sources: https://github.com/chickensoft-games/setup-godot, https://github.com/firebelley/godot-export

### e. Live reviews
Not live yet, so there are no reviews.

### Rights (assets)
- **Godot (MIT) plus its bundled FreeType, ENet and mbed TLS:** the licence text must be visible
  to players (a credits screen or a file). **Missing today.**
  - Source: https://docs.godotengine.org/en/stable/about/complying_with_licenses.html [S]
- **DejaVu font:** free to embed, but its licence must ship with it. **The project's copy is
  Debian's packaging file, not the upstream licence:** to fix.
- **Meshy models** (HD Aurora, cockpit, volcanic rocks):
  - Paid-plan outputs are yours, with commercial use allowed.
  - Free-plan outputs are **CC BY 4.0 and need the credit line "Model created with Meshy – CC BY
    4.0 License"**.
  - Rights follow the plan you were on when the model was made.
  - Never post the game's models to the Meshy Community: that makes them CC0.
  - Sources: https://help.meshy.ai/en/articles/10137554-what-is-the-ownership-of-the-generated-models [S],
    https://docs.meshy.ai/en/webapp/pricing [S]
- **Music and sounds:** generated by the game's own tools, so they're the developer's own work.

## Plan

### UPGRADES (changes to the code and build; no add-on needed)
| # | What | Why (evidence) | Effort | Risk | How it's tested |
|---|---|---|---|---|---|
| U1 | **Credits & licences** screen in Settings + `store-kit/credits.md`; ship the correct DejaVu licence; credit Meshy | Rights research above: Godot's MIT/FreeType notices are legally required and missing | S | Low | Smoke check: screen opens and shows Godot's licence text |
| U2 | **Colour-blind filter** setting: Off / Deuteranopia / Protanopia / Tritanopia (default Off) | Weakness #3; standard in racers | M | Low (post-process, off by default) | Smoke: filter on/off; screenshots |
| U3 | **Reduce motion** setting: no speed lines, flashes or boost FOV kick (default Off) | Weakness #3 | S | Low | Smoke: effects suppressed when on |
| U4 | **Interface size** setting: 100 / 115 / 130 % (default 100) | Weakness #3 | S–M | Medium (layouts at 130%) | Menu screenshots at 3 screen sizes |
| U5 | **Frame-rate option** gains 60 and 120 (default unchanged); iOS ProMotion plist key | Step 5 target; research above | S | Low (default unchanged) | Smoke: Engine.max_fps follows the setting |
| U6 | **Clean exit:** free what's still alive at quit | Weakness #10 | S | Low | Exit leak count goes to 0 |
| U7 | **Performance regression check** (`tools/perf_check.py`): benchmark vs the saved baseline, fail if over 5% worse | Step 9 | S | None | Runs against the baseline |
| U8 | **Visual regression check** of key screens at 3 screen sizes | Step 9 | M | None | Its own baseline images |
| U9 | **Store kits updated** with the new 2027 rules (Apple age questions, iOS 15, iPhone Duo, foldable screenshots, verification, Developer ID CA) | Research a | S | None | Review |
| U10 | **Release package:** `store-kit/` (shot list, accessibility answers, What's New, credits), `CHANGELOG.md`, version-bump script, release and rollback plan, signing notes | Step 10 | M | None | Review; scripts dry-run |

**Deferred (with reasons):**
- **Forward+/Mobile renderer** for HDR, AreaLight3D and upscaling: a major change, and
  approval-gated.
- **Godot 4.8:** still in beta.
- **Translation-ready strings:** large (hundreds of strings). Next run.
- **Key remapping:** medium; next run.

### ADD-ONS (asked before anything is installed)
| Add-on | Maker | Cost today | What it adds here | If no |
|---|---|---|---|---|
| Sentry Godot SDK 2.5.1 | Sentry (MIT SDK) | Free Developer plan, 5k errors/month (third-party figure) | Crash reports from every platform | Use the stores' free built-in crash reports (Play vitals, App Store Connect) and keep "no data collected" |
| GitHub Actions CI (setup-godot + godot-export) | GitHub / open source (MIT) | Free minutes (private repos get a monthly free allowance) | Every push: tests + web/Windows/Linux/Android builds kept as downloads | Tests and builds stay manual |
| In-app review plugin (godot-inapp-review v5.3) | Cengiz (cengiz-pz), MIT | Free | Store-approved "Rate this game" prompt after a good race | No prompt; players rate from the store page |
| Azure Artifact Signing | Microsoft | $9.99/month (individuals: US/Canada) | Signed Windows downloads (fewer SmartScreen warnings) | Ship Windows through Steam/MS Store, which don't need it |
| Not recommended now | — | — | GdUnit4/GUT (harness already covers it), fastlane (after store accounts exist), Firebase/PostHog (would end "no data collected"; Eddie later chose Firebase Crashlytics, opt-in, store builds only) | — |

### Eddie's answers (27 Nov 2026)
- **Crash reporting: Yes, Sentry AND Firebase Crashlytics, free.** The first answer was "No, use
  store reports"; Eddie then wrote "add both sentry and firebase crashlytics. free of course."
  - Both are opt-in for players and live only in store builds (see Results below).
  - Store privacy answers change from "no data collected" for those builds
    (`stores/CRASH_REPORTING.md`).
- **GitHub Actions CI: Yes.**
- **In-app review prompt: Yes, add it now.**
  - Cloud-session limit: GitHub's download pages are blocked here and the native libraries need
    the Android SDK and Xcode, so the plugin's *binaries* can't be fetched or built on this machine.
  - The game side is added: a review prompt at a happy moment. It's on in its settings file but
    does nothing until the plugin is in the build (store builds only).
  - Also added: a pinned installer for the release zip (`InappReviewPlugin-Multi-v5.3.zip`,
    MIT, Godot Mobile Plugins) that runs on Eddie's PC or in CI (`builds/store_build.sh`).
- **Azure Artifact Signing: No.**

## Results (Steps 4–11, finished 28 Nov 2026)

### What was done
| # | Upgrade | Status | Evidence |
|---|---|---|---|
| U1 | Credits & licences screen, upstream DejaVu licence, Meshy credit, `store-kit/credits.md` | ✅ | smoke: Godot licence, FreeType, Bitstream, CC BY found on screen; `upgrade-shots/after/menu_credits*.png` |
| U2 | Colour-blind filter (3 types), default Off | ✅ | smoke: on / mode / off; `menu_home_deutan.png` |
| U3 | Reduce motion, default Off | ✅ | smoke: no shake or landing dip when on; shake still works when off |
| U4 | Interface size 100/115/130 %, default 100 % | ✅ | smoke; `menu_settings_ui130.png`; layouts checked at 720×1280, 1280×720, 2048×1536 |
| U5 | Frame cap adds 60 and 120; iOS ProMotion key; "Off" stays 60 on iPhone | ✅ | smoke: `Engine.max_fps` follows each choice |
| U6 | Clean exit | ❌ not done | The one object left at exit is the menu music playback inside Godot's dummy audio driver (test machines only). Two fixes didn't change it, so it's left as a known test-only artefact |
| U7 | `tools/perf_check.py` + `tests/perf_baseline.json` | ✅ | passes on the after runs (below) |
| U8 | `tools/visual_check.sh`: 5 screens × 3 sizes | ✅ | VISUAL OK; a wrong screen scores 34 % and fails |
| U9 | 2027 store rules in the Apple and Play kits | ✅ | `stores/apple-app-store/README.md`, `stores/google-play/README.md` |
| U10 | `store-kit/`, `CHANGELOG.md`, `tools/bump_version.py`, release/rollback/signing plan | ✅ | bump script dry-run |
| Add-on | Sentry + Firebase Crashlytics, opt-in, store builds only (`builds/store_build.sh`) | ✅ code / ⏳ accounts | consent smoke tests; installer tested offline with a stand-in `gh` and fake release zips; idempotent; refuses to touch `game/` |
| Add-on | In-App Review prompt, store builds only | ✅ code / ⏳ plugin | rule smoke tests (races, podiums, spacing, max asks) |
| Add-on | GitHub Actions workflow | ✅ written / ❌ not running | GitHub started no runner for **any** workflow in the repo (all stop in 2–3 s): account billing or minutes |

**Also fixed:** two tests that passed or failed by machine speed. Both failed the same way on the
pre-upgrade code:
- the Lighthouse Wonder beat check (the music clock follows the wall clock);
- the safe-area check (headless runs have a 0×0 window).

### Before → after
| Measure | Before (27 Nov) | After (28 Nov) | |
|---|---|---|---|
| Medium: avg frame / 1 % low / worst | 70.5 ms / 10.6 fps / 186 ms | 67.7 ms / 10.1 fps / 135 ms | within 5 % ✅ |
| High: avg frame / 1 % low / worst | 261.3 ms / 3.0 fps / 360 ms | 242.9 ms / 3.2 fps / 356 ms | within 5 % ✅ |
| Memory, Medium (static / video) | 103.2 / 57.4 MB | 103.4 / 57.5 MB | ✅ |
| Nodes in a race | 1,071 | 1,075 | ✅ |
| Smoke checks | 1,141 pass | **1,180 pass, 0 fail** | ✅ |
| AI race on every track and layout | pass | pass (one rare flaky "stuck racer" seen once, passed on re-run) | ✅ |
| Build sizes | APK 61.6 · Win 42.3 · Linux 33.1 · macOS 64.6 · iOS 100.1 MB | same | ✅ |
| Linux build launch | starts and quits cleanly | same (300 frames, no errors) | ✅ |
| Crash reporting | none | Sentry + Crashlytics ready (opt-in), needs Eddie's free accounts | ⏳ |

Frame times are from the cloud computer's software GPU, measured alone. Single runs of the same
code differ by up to about 8 %. Draw calls aren't compared: the bench samples wherever the AI
race happens to be, and the pre-upgrade code alone gave 151, 257 and 272 in three runs.

### Store-readiness checklist
| Item | Pass/Fail |
|---|---|
| Builds: web, Windows, Linux, macOS (unsigned), iOS Xcode project, debug APK | ✅ |
| Google Play AAB (needs upload key + Android SDK 36) | ❌ Eddie |
| Target API 36, 64-bit, edge-to-edge safe area | ✅ |
| 16 KB pages (Godot 4.5+ templates; check in Play's bundle explorer) | ⚠️ unverified |
| Privacy policy public URL | ❌ Eddie (page is private) |
| Privacy policy covers crash reports | ✅ local text / ❌ live page waits for Eddie's go |
| Data safety / App Privacy answers (both variants) | ✅ |
| Age-rating answers incl. Apple's 2 new questions | ✅ |
| Screenshots and previews for today's rules | ✅ |
| 2027 screenshots (iPhone Duo, foldables) | ⏳ Apr 2027 |
| Credits and licences in-game | ✅ |
| Every asset licensed for commercial use | ⚠️ Meshy plan to confirm |
| Accessibility features + Apple label answers | ✅ |
| Crash reporting live | ❌ Eddie: free Sentry + Firebase accounts |
| Automatic tests/builds (CI) | ❌ GitHub isn't starting runners |
| Store accounts, Apple Team ID, signing keys | ❌ Eddie |
| All tests pass | ✅ |

### Next 3 upgrades
1. **Translation-ready strings**, then the first languages (Spanish, Portuguese, German): the
   biggest reach gain.
2. **Control remapping** for keyboard and gamepad: the last big accessibility gap.
3. **Real-phone performance pass:** Play's pre-launch report or a device farm on a low, mid and high
   phone; then decide on the Mobile renderer for High/Ultra (approval-gated).
