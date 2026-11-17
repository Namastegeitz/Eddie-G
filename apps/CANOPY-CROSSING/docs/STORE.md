# Store, billing, ads and analytics

## How it fits together

```
content/store/catalog.json ──► Store (autoload) ──► BillingBackend
                                   │                 ├─ mock_billing.gd        (default: sandbox sheet, receipts file)
                                   │                 ├─ google_play_billing.gd (GodotGooglePlayBilling plugin)
                                   │                 └─ app_store_billing.gd   (godot-ios-plugins InAppStore)
                                   └─ grant_product(): animals, maps, Amber, flags, pass, cosmetics
Ads (autoload) ── mock test cards by default, scripts/platform/admob_ads.gd for AdMob
Analytics (autoload) ── user://analytics.jsonl + optional HTTP endpoint
```

Project settings (Project > Project Settings > canopy):

| Setting | Default | Meaning |
|---|---|---|
| `canopy/billing/backend` | `mock` | `platform` uses Google Play / App Store when the plugin is in the build |
| `canopy/ads/backend` | `mock` | `admob` uses the AdMob plugin |
| `canopy/analytics/endpoint` | empty | URL to POST `{"events": [...]}` batches to |

## Sandbox (works today)

Every real-money product opens a sandbox sheet ("no money is charged"). Buy
or cancel; declines can be simulated in tests (`fail_next`). Non-consumables
are written to `user://sandbox_receipts.json`, which stands in for the
store account, so **Restore purchases** works after a reinstall or a reset.

## Google Play Billing (Android)

1. Add the official **GodotGooglePlayBilling** plugin (v2+) to `addons/`
   and enable it in the Android export preset.
2. Set `canopy/billing/backend = platform`.
3. In Play Console, create in-app products whose ids match
   `store_ids.google` in the catalog (defaults to the product id, e.g.
   `map_congo`, `amber_550`). `amber_*` are consumable; the rest are
   one-time (the pass is one-time per season id).
4. Upload a signed AAB to an internal testing track, add license testers,
   and test: buy a map pack, kill and relaunch, reinstall and **Restore**.

## App Store (iOS)

1. Build with the **InAppStore** plugin from godot-ios-plugins.
2. Set `canopy/billing/backend = platform`.
3. In App Store Connect, create products with the ids in
   `store_ids.apple` (`com.aethertek.canopycrossing.<id>`).
4. Test with a Sandbox Apple ID on device (StoreKit sandbox): purchase,
   restore, interrupted purchase.

## Ads

- Rewarded videos are opt-in only: revive, double a run's Berries.
- Interstitials only between runs, every 3rd finished run, never in the
  first 3 runs, never with Remove Ads.
- Nothing is shown during a run (`Ads.in_run`), checked by the tests.
- For AdMob: add an AdMob Godot plugin exposing an `AdMob` singleton, set
  `canopy/ads/backend = admob`, replace the Google test unit ids in
  `scripts/platform/admob_ads.gd` with your own, and add the app id to the
  Android manifest / iOS Info.plist as the plugin's docs describe. The
  "Personalised ads" setting (off by default) is where to pass consent.

## Analytics events

`session_start`, `screen`, `run_start`, `run_end` (mode, map, stage,
animal, rows, score, won, berries, deaths, revives, near_misses, time), `death` (cause,
hazard, map, row), `revive`, `purchase_start`, `purchase`, `purchase_failed`,
`restore`, `unlock`, `currency`, `item`, `item_used`, `ad_shown`,
`ad_reward`, `daily_reward`, `pass_claim`, `prompt`, `store_view`,
`tutorial_step`, `dlc_download`, `view` (bird / fpv switches),
`settings_graphics` (quality picked and what Auto resolved to), and the one-time funnel steps
`first_launch → tutorial_start → tutorial_complete → first_run_end →
first_unlock → first_store_view → first_purchase`.

To use Firebase or GameAnalytics, replace `Analytics._send_batch()`.

## Store listing checklist

- Name: Canopy Crossing. Category: Arcade / Casual. Rating: Everyone.
- Icon: `assets/icons/icon_1024.png` (Android adaptive icon in the same folder).
- Screenshots: `tools/capture.sh` at 1242x2688 / 1080x1920.
- Short description: "Hop real jungle animals across real rainforests."
- Data safety: analytics (optional endpoint), purchases; no account needed.
