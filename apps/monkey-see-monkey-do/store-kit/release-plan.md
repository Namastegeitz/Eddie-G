# Release plan, staged rollout and rollback

Nothing is uploaded or submitted without Eddie's go-ahead.

## 1. Internal test (about a week)
- Web beta link for the core group; Android internal testing track; TestFlight internal testers.
- Gate to move on: no crash or freeze reports, all automated suites green
  (`node tests/unit.mjs`, `node tests/acceptance.js`, `node tests/devices.js`,
  `node tests/benchmark.js`), store pre-checks clean (Play pre-launch report,
  App Store Connect validation).

## 2. Closed beta (14+ days)
- Google Play closed testing with 12+ testers for 14 days in a row (needed for
  new personal developer accounts); TestFlight external testing.
- Bug reports through the Bug Reports page or Settings > Report a problem.
- Gate: crash-free sessions 99%+ and no ANRs in Play vitals (Google's limits:
  user-perceived crash rate under 1.09%, ANR under 0.47%).

## 3. Staged rollout
| Stage | Google Play | App Store | Hold for | Move on when |
|---|---|---|---|---|
| 1 | 5% | Phased release day 1-2 (1-2%) | 2 days | crash-free 99%+, no new top crash, rating steady |
| 2 | 20% | days 3-4 | 2 days | same |
| 3 | 50% | days 5-6 | 2 days | same |
| 4 | 100% | day 7 | | |

PC stores: Steam beta branch for testers first, then the default branch.
Web: the beta link updates for everyone at once (it is the test channel).

## Rollback
- **Google Play:** halt the staged rollout in Play Console (players who already
  updated keep it); fix forward with a higher build number
  (`node scripts/set_version.mjs`), since Play can't serve an older build.
- **App Store:** pause the phased release; submit a fix, asking for an
  expedited review if it's serious.
- **Steam:** set the previous build live on the default branch in Steamworks.
- **Web beta:** `git revert` the last `monkey-see-monkey-do/` commit on
  `gh-pages` and push; players get the previous version on their next visit.
- **Code:** every release is tagged `monkey-v<version>`; the phone build
  workflow rebuilds exactly from a tag. The pre-upgrade point for this run is
  commit `8ea014e`.
