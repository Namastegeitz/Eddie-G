# Release plan and rollback (1.3.0 and later)

Nothing is uploaded or submitted without the owner's go.

## Google Play
1. **Internal testing** (you + a few devices): install from Play, play one puzzle in every
   mode, check ads, consent form, Settings → Graphics, Text size, Send feedback.
2. **Closed testing** (required for new personal accounts): 12+ testers for 14 days.
   Watch Play Console → **Android vitals** and Sentry/Crashlytics daily.
3. **Production, staged rollout**: 5% → 20% → 50% → 100%, at least 2 days per stage.
   Move on only if, for the release: user-perceived crash rate under 1.09% (target under 0.5%),
   ANR rate under 0.47%, crash-free users in Crashlytics at least 99.5%, no new top crash.
4. **Rollback**: Play Console → Production → **Halt rollout** (stops new installs of this
   version). Then fix and ship a higher versionCode; Play can't reinstall an older build.
   For ad problems, use Remote Config first: `disable_interstitials` / `disable_ads`.

## App Store
1. **TestFlight internal** (you): same checks, on iPhone and iPad.
2. **TestFlight external** (optional, up to 10,000 testers; the first build gets a short review).
3. **Release**: choose **Manual release**, then **Phased release for automatic updates**
   (Apple spreads updates over 7 days: 1%, 2%, 5%, 10%, 20%, 50%, 100%).
4. **Rollback**: **Pause phased release** (up to 30 days), fix, submit a new build.
   Remote Config switches work here too.

## Version numbers
`game/package.json` holds the version (1.3.0). Android versionCode and iOS build number
go up by one for every upload (now 4); Codemagic adds its build counter for iOS.
