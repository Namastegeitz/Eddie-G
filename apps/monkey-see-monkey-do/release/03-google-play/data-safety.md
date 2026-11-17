# Google Play: Data safety form answers

Play Console > Policy > App content > Data safety.

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | The game sends nothing off the phone. Progress and the purchase list stay in the app's local storage. |
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
  purchases) and `VIBRATE` (optional taps). No INTERNET permission.

Ads declaration (App content > Ads): **No, my app does not contain ads.**
