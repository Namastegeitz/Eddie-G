# **CANOPY CROSSING: PRIVACY ANSWERS FOR THE STORES**

What the game sends, as of the 2026-11-27 upgrade. Keep in step with
`LAUNCH/shared/privacy-policy.md` and `docs/CRASH_REPORTING.md`.

| Data | Sent? | When | To |
|---|---|---|---|
| Crash logs and diagnostics (error, device model, OS, game version, graphics level, recent steps) | Yes, unless the player turns it off | Store builds with Sentry/Crashlytics set up | Sentry; Firebase Crashlytics (Android) |
| Purchases | Handled by the store | When buying | Google Play / Apple |
| Gameplay analytics | **No** (stays on the device; the upload endpoint is empty) | - | - |
| Advertising ID / ads | **No** while ads are sandboxed (Phase 1 decision pending) | - | - |
| Remote switches | The game *downloads* a settings file; nothing about the player is sent beyond the normal web request | Start-up | GitHub Pages |
| Map packs (if any are made downloadable) | Normal web request | On unlock | The pack's host |

## Google Play: Data safety

- Collects: **App info and performance > Crash logs; Diagnostics**.
- Shared with third parties: **No** (Sentry and Google process it for us).
- Purpose: **App functionality**.
- Optional: **Yes** (Settings > Send crash reports).
- Encrypted in transit: **Yes**. Deletion request: not applicable (no account; nothing linked to the player).

## Apple: App Privacy

- **Diagnostics: Crash Data, Other Diagnostic Data**. Linked to the user: **No**. Used for tracking: **No**. Purpose: **App Functionality**.
- The iOS build's privacy manifest declares the same when Sentry is built in.
- Tracking (ATT): **No**.

## Without crash reporting set up

"No data collected" on both stores (as before the upgrade).
