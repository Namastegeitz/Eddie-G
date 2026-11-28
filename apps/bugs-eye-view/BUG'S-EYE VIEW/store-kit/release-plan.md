# Release plan and rollback

Nothing is uploaded or submitted without your go-ahead.

## Stages
1. **Internal test** - you and anyone you trust: the release workflow's
   builds, Play internal testing, TestFlight internal. Check the main flows
   on a low, mid and high Android phone, an older and the newest iPhone, a
   low- and a high-spec PC, Chrome/Safari/Firefox.
2. **Closed beta** - Play closed testing (12+ testers for 14 days, required
   for new personal accounts), TestFlight external, an itch.io
   restricted page. Feedback goes into the live checklist's Feedback tab.
3. **Staged rollout** - Google Play 5% -> 20% -> 50% -> 100%; App Store
   phased release (7 days). Between stages, check:
   - crash-free users 99%+ (Sentry release health / Firebase Crashlytics)
   - Play vitals: user-perceived crash rate under 1.09%, ANR rate under
     0.47% (and under 8% on every phone model)
   - no new 1-star reviews about the same problem
4. **PC stores** - Steam (press Release), itch.io, Epic, GOG, Microsoft as each
   is approved.

## Rollback
- **Google Play:** halt the staged rollout (Release > Halt), then ship the
  previous build again with a higher version code (Play never accepts an old
  code).
- **App Store:** pause the phased release; if needed, submit the previous
  code as a new build. Removing the app from sale is the last resort.
- **Steam / itch.io / Epic / GOG:** set the previous build live again
  (Steam: SteamPipe > set the old build on the default branch).
- **Code:** every release is a git tag `bugs-eye-view-vX.Y.Z`; the release
  workflow rebuilds any tag exactly. The pre-upgrade state of 27 Nov 2026 is
  commit 8ea014e (local tag `pre-upgrade-2026-11-27`).
- **Feature switches:** crash reporting (Settings, and it's off until the
  player says yes) and the shader warm-up (`GameManager.shader_warmup_enabled`)
  can each be turned off.
