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

BASELINE_TABLE

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

ENGINE_RESEARCH

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

PLAN_UPGRADES

### ADD-ONS (installed or connected)

PLAN_ADDONS

## Before / after

AFTER_TABLE
