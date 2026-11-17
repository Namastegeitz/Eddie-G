# **COSMIC SAUCER DRIFT** · itch.io

**The fastest store: free, live the same day.** A good place to collect real player
feedback while the Play test runs.

## Already done
- Web build that fits itch's HTML5 rules (no-threads, so no SharedArrayBuffer) → [`../../builds/web/`](../../builds/web/)
- Windows, Linux, macOS zips and the Android APK → [`../../builds/`](../../builds/)

## Steps
1. Make a free account → *Upload new project* → Kind: **HTML**.
2. Pricing: "No payments" or "$0 or donate" (only paid/donations need the tax interview and payout setup).
3. Upload a zip of the *contents* of `builds/web/` → tick "This file will be played in the browser".
   Embed 1280×720, fullscreen button on, mobile friendly on, SharedArrayBuffer **off**.
4. Add the Windows / Linux / macOS zips (and the APK) as downloads; mark each platform.
5. Cover image 630×500 (Claude can render), screenshots, short text from STORE_LISTING.md → Publish.
6. Later, for one-command updates: `butler push builds/web you/cosmic-saucer-drift:web`
   (butler can't be downloaded on this computer; it works on your PC).

| Limit | Value |
|---|---|
| HTML5 zip | index.html at the root; ≤1,000 files, ≤500 MB unzipped, ≤200 MB per file |
| Revenue share | You choose (default 10%) |
| Payouts | 7–30 days after a sale; $5 minimum; tax interview first |

Sources: https://itch.io/docs/creators/html5 · https://itch.io/docs/creators/pricing ·
https://itch.io/docs/creators/payments · https://itch.io/docs/butler/pushing.html
