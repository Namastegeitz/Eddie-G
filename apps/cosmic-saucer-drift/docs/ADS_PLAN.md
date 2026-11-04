# Ads plan: free + no ads now, ads layer ready for later

v1 ships with ads **off**: no ad SDK in the build, no network calls, nothing
collected, and the Play Console answers in `STORE_LISTING.md` are "no ads"
and "no data collected". Everything needed to switch ads on later is already
in the code, so a future update only has to add the network and flip a switch.

## What's already built

| Piece | Where | What it does |
|---|---|---|
| `Ads` autoload | `autoload/ads.gd` | The only thing the game talks to. `enabled()`, `can_offer(placement)`, `show_rewarded(placement, done)`, `maybe_interstitial(where, then)`, `set_removed()` |
| Config | `resources/ads_config.tres` (`scripts/ads/ads_config.gd`) | `enabled`, `provider` (none / debug / admob), ad unit IDs (Google's public test IDs for now), frequency caps, child-directed flag, max content rating, consent requirement |
| Providers | `scripts/ads/` | `AdProvider` (does nothing: v1), `DebugAdProvider` (full-screen "TEST AD" cards so you can try every flow without an SDK, debug builds only), `AdMobAdProvider` (template that talks to an AdMob plugin through `Engine.get_singleton`, so the game builds without it) |
| Remove-ads flag | `Save.data.ads.removed`, `Ads.set_removed()` | Turns every ad off for players who buy "remove ads" later |
| Session/race counters | `Save.data.ads` | sessions, races, races since the last interstitial: used by the caps |
| Events log | `autoload/events.gd` | Logs `first_open`, `tutorial_complete`, `race_start`, `race_finish`, `cup_complete`, `daily_complete`, `unlock`, `purchase`, `achievement`, `ad_*`. In v1 they stay in memory only. A provider (e.g. Firebase Analytics) can forward them later; these are the conversion events an app campaign (Google Ads App campaigns) optimises for |

### Placements wired into the UI (hidden while ads are off)

1. **`double_stardust` (rewarded)** - results screen: "Watch ad: +N Stardust"
   doubles that race's Stardust. Player's choice, never forced.
2. **`free_item` (rewarded)** - Quick Race screen: "Watch an ad: start
   holding a free item".
3. **`cup_interstitial` (interstitial)** - only between cup races, after the
   results screen, never during a race. Capped: not before session 2, not
   before 5 finished races, then at most one every 3 races. Players who own
   "remove ads" never see it.

Every check returns "no" while `enabled = false`, so v1 shows no ad buttons.

## Trying the flows today (no SDK)

In `resources/ads_config.tres` set `enabled = true` and `provider = "debug"`,
run a debug build: the ad buttons appear and show a fake ad card. The smoke
test does exactly this (`_ads()` in `tests/smoke.gd`). Set it back to
`enabled = false` before exporting a release.

## Turning real ads on (a later update)

1. **AdMob account:** create the app in AdMob, get the app ID and a rewarded
   and an interstitial ad unit ID. Keep the test IDs in the config until the
   build is approved.
2. **Plugin:** add a Godot 4 AdMob Android plugin (for example the
   community "Godot AdMob" plugin by Poing Studios) through the AssetLib or
   its GitHub release, enable it in Project Settings > Plugins, and use the
   *Android AAB* preset (Gradle build). Put the AdMob app ID where the plugin
   asks for it (Android manifest meta-data).
3. **Wire the template:** in `scripts/ads/admob_ad_provider.gd`, check the
   method and signal names against the plugin version you installed (load,
   show, earned-reward, closed) and connect its signals to
   `on_rewarded_earned`, `on_rewarded_closed_without_reward` and
   `on_interstitial_closed`. Nothing else in the game changes.
4. **Consent (GDPR/UK/EEA):** use Google's User Messaging Platform (UMP),
   usually exposed by the same plugin, inside
   `AdMobAdProvider.request_consent()`. `Ads` only loads ads after consent
   comes back. Add a "Privacy options" button to Settings that reopens the
   consent form (required by UMP).
5. **Switch on:** `enabled = true`, `provider = "admob"`, real unit IDs.
6. **Play Console updates** (before publishing that version):
   - Ads declaration: "Yes, my app contains ads".
   - Data safety: AdMob collects device identifiers (advertising ID), app
     interactions and diagnostics, shared with Google for advertising; declare
     them as Google's AdMob data-disclosure page describes for the SDK version.
   - Android 13+: add the `com.google.android.gms.permission.AD_ID`
     permission (the plugin usually adds it).
   - Update `docs/privacy-policy.html` to name AdMob and link Google's policy.
   - Target audience: if you include under-13s, you must use
     Families-certified ad SDKs, set `child_directed = true`, and keep
     `max_ad_content_rating = "G"`.
7. **Optional "Remove ads" purchase:** add Google Play Billing (a Godot
   billing plugin), sell a non-consumable, and call `Ads.set_removed(true)`
   when it's owned (and on restore).

## Ad campaigns to grow installs

To advertise the game with Google Ads App campaigns, link the Play listing
to Google Ads and (for better optimisation) Firebase Analytics. Plug a
provider into `Events.provider` that forwards `log_event` calls to Firebase;
the events above are already fired at the right moments. `tutorial_complete`
and `race_finish` make good in-app conversion actions. This also needs a
Data safety update (analytics data collected).
