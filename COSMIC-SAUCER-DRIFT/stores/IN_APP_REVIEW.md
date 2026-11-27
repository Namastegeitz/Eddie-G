# Store rating prompt (In-App Review)

Added 27 Nov 2026 ("Yes, add it now").

- **What:** after a podium finish (1st to 3rd), once the player has done at least 5 races and 2 podiums,
  the game asks the store to show its own "rate this game" card: Google Play In-App Review on
  Android, Apple's review request on iPhone/iPad. At most 3 asks, 30 days apart. Never from a
  button: both stores forbid that.
- **The stores decide** whether the card really appears and how often. Google shows it only in
  copies installed from Google Play, and both stores cap it per year.
- **Plugin:** Godot In-App Review v5.3 (MIT, Godot Mobile Plugins), installed into the store
  build only by `builds/store_build.sh`. Normal builds don't have it, and there the prompt does nothing.
- **Settings:** `game/content/review_prompt.json` (`enabled`, `min_races`, `min_podiums`,
  `days_between`, `max_asks`). Set `"enabled": false` to switch it off without a code change.
- **Code:** `game/scripts/platform/review_prompt.gd`, called from the results screen. Its
  record is kept in the save file under `review`; older saves get it automatically.
- **Test:** Google's internal app sharing or an internal-testing track shows the card, but a
  side-loaded APK never does. On iPhone, a development build always shows it; TestFlight never does.
