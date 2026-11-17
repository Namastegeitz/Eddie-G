# **CANOPY CROSSING: itch.io requirements**

Researched 2026-11-17 from official pages (itch.io could not be fetched directly; via search extracts, marked); re-check on the day.
Shared PC-edition decisions: [../steam/requirements.md](../steam/requirements.md#the-pc-edition-applies-to-steam-gog-itchio-epic-microsoft).

## Recent changes
Jul-Aug 2025: NSFW content deindexed under payment-processor pressure (not relevant to this game, but processors can change itch.io policy).

## 1. Account and fees
No listing fee. **Open revenue share**: you choose 0-100% (default 10%); payment processor fees (~$0.30 + 2.9% per sale) on top. (itch.io/docs/creators/payments)

## 2. Tax and bank
- **"Collected by itch.io, paid later"** (recommended): PayPal or Payoneer, **minimum $5**, revenue available **7 days** after each purchase, USD; **mandatory tax interview** (no payouts until validated); non-US sellers 30% withholding by default, reduced by treaty; claim within a year; itch.io handles EU VAT. 2025 forum reports describe payout delays.
- "Direct to you" (PayPal/Stripe): you handle VAT, refunds and complaints; staff call it legacy.

## 3. Legal and content
- **Generative AI disclosure** (since Nov 2024) on every project's edit page: **answer yes and tick Graphics** for the Meshy models; it adds an "AI Generated" tag; strictly enforced for assets/soundtracks, reportedly optional for games **[UNVERIFIED]**; "No AI" is a filter shoppers use. (itch.io/docs/creators/quality-guidelines)
- Selling Steam keys on itch.io: Steam's key-parity rules apply.

## 4. Technical and builds
- **butler**: `butler login` once; in CI set **`BUTLER_API_KEY`** (no trailing newline; revoke if it ever appears in a log). Push: `butler push BUILDS/windows youruser/canopy-crossing:windows --userversion 0.9.0`. **Channel names set the platform tags** (`windows`, `linux`, `mac`, `html5`); keep them stable. (itch.io/docs/butler/pushing.html)
- Push folders, not installers. macOS: a **notarized, stapled** `.app` (browser downloads are quarantined; Gatekeeper blocks unsigned apps). Linux: keep the executable bit.
- **Web build**: itch.io can host the HTML5 version as "playable in browser" (the game's web export is single-threaded, which avoids itch's SharedArrayBuffer option **[UNVERIFIED for 4.7.2]**).

## 5. Store page assets
Cover image 315:250, **min 315x250, recommended 630x500**; ~3-5 screenshots (convention, unofficial); trailer by YouTube/Vimeo embed **[UNVERIFIED]**. (itch.io/docs/creators/getting-started)

## 6. Testing
Keep the page Draft or Restricted, share download keys, test through the itch app and browser downloads.

## 7. Review and indexing
No pre-publication review. **A new seller's first paid project is queued for review before appearing in search/browse** ("usually" a few business days; reports up to weeks). Indexing needs a cover image and downloadable or playable files. Don't recreate pages to dodge the queue. (itch.io/docs/creators/getting-indexed)

## 8. Launch
Set the price; optional sales or bundles; no waiting period. Good for an early release or a demo.

## Open items
Whether AI disclosure is mandatory for games; screenshot and trailer specs.
