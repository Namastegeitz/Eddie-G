# Google Play: Data safety form answers

Play Console > Policy > App content > Data safety.

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** while crash reports are not set up (release/config.json `firebaseCrashlytics` false and no `sentryDsn`). **Yes** once they are (see "With crash reports" below) | Progress and the purchase list stay in the app's local storage. |
| Is all of the user data collected by your app encrypted in transit? | (not asked when nothing is collected) | |
| Do you provide a way for users to request that their data is deleted? | (not asked when nothing is collected) | Players can delete everything in Settings > Your data, or uninstall. |

Notes for reviewers who ask:

- Purchases are processed by Google Play Billing. The app receives only the
  product ID and a purchase token, used once to deliver the item; it keeps a
  local list (product, price, date) for the player's Stats screen.
- Google's billing library is part of Google Play; its data handling is
  covered by Google's own policy and doesn't count as the app collecting
  data.
- Permissions in the manifest: `com.android.vending.BILLING` (in-app
  purchases), `VIBRATE` (optional taps), and `INTERNET` /
  `ACCESS_NETWORK_STATE`, added by the built-in Firebase Crashlytics library
  (used only for crash reports, and only once they are set up).

## With crash reports (once Sentry and/or Firebase Crashlytics are set up)

| Question | Answer |
|---|---|
| Data collected | **App info and performance: Crash logs, Diagnostics.** **Device or other IDs** (Crashlytics installation ID) |
| Shared with third parties? | No (Sentry and Firebase process it for us as service providers, which Google doesn't count as sharing) |
| Processed ephemerally? | No |
| Required or optional? | Optional: players can switch it off in Settings > Help and privacy |
| Purpose | App functionality (fixing crashes); also tick Analytics if Play asks, since crash statistics are reviewed |
| Encrypted in transit? | Yes (HTTPS) |
| Deletion requests? | Yes: by email to the support address; reports also expire on the services' retention schedules |

Apple's App Privacy answers then become: **Diagnostics > Crash Data** (and
Performance Data if Sentry performance is ever turned on): not linked to the
user's identity, not used for tracking.

Before turning crash reports on for a children's audience, check Google's
Families policy and COPPA guidance: crash reports without personal
information generally fit "support for internal operations", but confirm.

Ads declaration (App content > Ads): **No, my app does not contain ads.**
