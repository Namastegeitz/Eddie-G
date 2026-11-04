# Store plan: Race Credits now, real money later

Every craft, including the four premium ones, is unlocked with **Race
Credits** earned by racing. v1 has no real-money purchases: the Play listing
says "no in-app purchases" and nothing about payments is collected.

The real-money layer is already built and switched off, so a later update
only adds the billing plugin and flips a switch.

## What's built

| Piece | Where | What it does |
|---|---|---|
| `Store` autoload | `autoload/store.gd` | `enabled()`, `can_buy(id)`, `price_text(id)`, `buy(id, done)`, `restore(done)`. Grants happen here, the same for every backend. Logs `purchase_start` / `purchase` events |
| Products | `Store.PRODUCTS` | `craft_sail`, `craft_phantom`, `craft_dragon`, `craft_dyson` (one premium craft each), `premium_fleet` (all four), `credits_5k`, `credits_30k` (consumable credit packs), `remove_ads` (entitlement, turns ads off for good). Prices there are placeholders; the real ones come from the Play Console |
| Config | `resources/store_config.tres` | `enabled` (false), `provider` (none / debug / play_billing), `show_store_button` |
| Providers | `scripts/store/` | `StoreProvider` (does nothing: v1), `DebugStoreProvider` (shows a "TEST PURCHASE" card then succeeds, debug builds only), `PlayBillingStoreProvider` (template for the Godot Google Play Billing plugin, reached through `Engine.get_singleton`, so the game builds without it) |
| UI | Hangar, Store screen | Premium craft show "Unlock for N CR" always and "Buy now $X" only when the store is on. A Store screen with every product and "Restore purchases" appears on the home screen only when the store is on |

## Try it today (no billing)

Set `enabled = true` and `provider = "debug"` in
`resources/store_config.tres`, run a debug build: buy buttons appear and
show a fake purchase. The smoke test does this (`_ads()` in
`tests/smoke.gd`). Switch it back off before a release export.

## Switching real purchases on (a later update)

1. **Play Console:** set up a payments profile (merchant account). In
   *Monetize > Products > In-app products*, create the product ids above
   (managed products; `credits_5k` / `credits_30k` are consumable, the rest
   one-time). Set prices per country.
2. **Plugin:** add the Godot Google Play Billing plugin (Godot 4 version),
   enable it, and use the *Android AAB* preset (Gradle build).
3. **Wire the template:** in `scripts/store/play_billing_store_provider.gd`,
   connect the plugin's signals (connected, product details, purchases
   updated), query details for `Store.PRODUCTS` to fill real prices
   (`on_price`), acknowledge one-time products and consume credit packs, and
   call `on_purchase_result`. Check method names against the plugin version.
4. **Switch on:** `enabled = true`, `provider = "play_billing"`.
5. **Test** with license testers (Play Console > Settings > License testing)
   on an internal test track before going live.
6. **Play Console updates:** the listing shows "Contains in-app purchases";
   in Data safety, Google Play handles the payment, but declare "Purchase
   history" (App activity / Financial info as Google's guidance says for your
   setup). Update `docs/privacy-policy.html`.

## Keeping it fair

Premium craft are stronger on paper but balanced by perks rather than raw
speed alone, and every one can be earned with credits (roughly 30-50 race
wins plus stars). Real money is a shortcut, never the only way.
