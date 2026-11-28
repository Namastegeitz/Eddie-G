# **CANOPY CROSSING: RELEASE PLAN**

Nothing is uploaded until Eddie says go. Builds come from
*Actions > Canopy Crossing release builds* (or a `canopy-release-vX.Y.Z` tag,
which also makes a draft GitHub Release that rebuilds exactly from the tag).

1. **Internal test** (1-3 days): Play Console internal testing (up to 100
   testers, license testers for purchases) and TestFlight internal. Check:
   start, purchases + restore, both views, pause on leaving, crash report
   arrives (trigger one on a test build), no ANRs.
2. **Closed beta** (14+ days; Google requires 12 testers x 14 days for a
   personal account): Play closed testing + TestFlight external. Watch the
   bug log on the launch page and Sentry/Crashlytics daily.
3. **Production, staged**:
   - Google Play staged rollout: **5% -> 20% -> 50% -> 100%**, at least 24 h
     each, moving on only if: crash-free users >= 99.5%, user-perceived crash
     rate < 1.09% and ANR rate < 0.47% (Play vitals), no new crash group in
     Sentry/Crashlytics with more than 10 users.
   - App Store: phased release (7 days, 1% -> 100%), pause if the same limits are crossed.
   - PC stores: Steam/itch/GOG/Epic ship the PC edition separately (see the launch checklist).
4. **Rollback**:
   - Halt the Play rollout / pause the App Store phased release.
   - Turn the problem feature off with a remote switch (docs/REMOTE_CONFIG.md);
     players get it on their next launch.
   - Ship the previous build again with a higher build number (stores never
     accept a lower one): `git checkout <previous tag>`, run the release
     workflow, upload.
   - The code itself: every upgrade step is a separate commit; the starting
     point of the 2026-11-27 upgrade is commit 8ea014e.

## Signing (where the keys live; never in the repo)

| Key | Where | Backup |
|---|---|---|
| Android upload key | GitHub secrets `CANOPY_ANDROID_KEYSTORE_BASE64`, `CANOPY_ANDROID_KEY_ALIAS`, `CANOPY_ANDROID_KEY_PASSWORD` (not set yet) | Eddie keeps the .keystore and password offline (two places) |
| Apple distribution certificate, App Store Connect API key | Apple Developer account; GitHub secrets for the Mac build job (not set up yet) | Apple account |
| Developer ID (Mac notarization) | Apple Developer account (renew to the G2 certificate before 2027-02-01) | Apple account |
| Windows code signing | Not used (Steam/GOG/Epic/MSIX don't need it) | - |
| Sentry DSN, Firebase config | GitHub secrets `SENTRY_DSN`, `FIREBASE_ANDROID_CONFIG` | Sentry / Firebase consoles |
