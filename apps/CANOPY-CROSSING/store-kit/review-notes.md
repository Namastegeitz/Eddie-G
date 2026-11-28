# **CANOPY CROSSING: NOTES FOR APP REVIEW**

Paste into App Store Connect > App Review Information > Notes (and Google
Play's "Instructions for review" if asked).

- No account or login. All modes work offline.
- In-app purchases: Settings > Restore purchases restores non-consumables.
  Amber (currency) never expires. No random rewards for money (no loot boxes):
  every product shows what it contains before purchase.
- To reach the store: Home > Store. The first jungle (Amazon) and five
  animals are free; others unlock by playing or with Berries.
- **Remote switches (guideline 2.5.19)**: the game reads a settings file at
  start-up that can only turn off existing features (first-person view, silly
  faces, detailed terrain, rating prompt, crash reports, between-run ads) or
  show an update reminder. It never enables anything hidden.
- Rating requests use the official StoreKit review API, at most every 120
  days, only after the player clears a level.
- Crash reports are optional (Settings > Send crash reports) and carry no
  personal data.
