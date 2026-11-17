# **CANOPY CROSSING: Steam requirements**

Researched 2026-11-17 from official pages (some via search extracts, marked); re-check on the day.
**[UNVERIFIED]** = not confirmed; **[CONFLICTING]** = official pages disagree. partner.steamgames.com could not be fetched directly from the research machine, only through search extracts.

## Recent changes

| When | Change |
|---|---|
| **3 Nov 2026** | Pre-release reviews can take **up to 12 business days** (target 3-5). New build-review rule: someone must **launch the game through Steam and play ≥5 minutes** within the last 7 days or since the latest build upload. Coverage also lists ≥5 gameplay screenshots, declared redistributables, reviewer access to all content, testing on a non-dev PC. (gamedev.net/news/6907, maketecheasier.com coverage) |
| Jan 2026 | AI disclosure in the Content Survey rewritten: covers only AI content that **ships to players**; dev tools such as code assistants are out of scope. |
| Jun 2026 | Verified program extended to **Steam Machine** (target 30 fps at 1080p) and **Steam Frame**; compatibility doc moved to `/doc/steamhardware/compat`. |
| Feb 2025 | Advertising page: **no ad-based business models** (no gating or rewards for watching ads). |
| Nov 2024 | Season-pass DLC rules: list each DLC's content and timing. |
| Aug 2024 | Larger capsule sizes mandatory. |

## The PC edition (applies to Steam, GOG, itch.io, Epic, Microsoft)

**Monetization**: remove ads, rewarded-ad prompts, Amber packs, Remove Ads, the season-pass shop and every "buy" screen from the desktop builds (separate export preset / feature tag). Steam rejects any ad model, rewarded ads included. Any real-money purchase on Steam must use the Steam Wallet API; a premium edition (one price, everything earnable) avoids that. GOG has historically avoided microtransactions **[UNVERIFIED current policy]**.

**Offline / DRM**: fully playable offline, no account (GOG QA checks this with Galaxy removed).

**Portrait on 16:9 / 16:10 screens (Godot)**: `stretch/mode = canvas_items`; aspect `keep` pillarboxes, `expand` uses the width (decorative side art strongly advised). Set a window override (e.g. 540x960; a 1080x1920 window doesn't fit a 1080p monitor). Fullscreen 1920x1080: play area ~608x1080 with ~656 px side bars. **Steam Deck 1280x800**: play area 450x800. Valve's minimum text height **9 px at 1280x800 (12 px recommended)**: from this game's 720x1280 base, fonts need **≥15 px (minimum) / ≥20 px (recommended)** (calculated from Valve's thresholds).

**Input**: tap/swipe mapped to keyboard (arrows/WASD) and gamepad (D-pad/stick); menus fully controller-navigable; Xbox/Deck glyphs when a controller is active; any text entry must open the Steam on-screen keyboard (Steamworks API).

**Saves**: enable a custom user directory so save paths are stable; Steam Auto-Cloud and GOG cloud saves work without code from a dedicated save folder; never write saves inside a macOS `.app`.

**Achievements**: optional; if added on Steam, **Epic requires substantially similar achievements**.

**Meshy (AI) licence**: free-plan outputs are **CC BY 4.0** (commercial use allowed, **credit required**); paid-plan outputs are owned; the plan active **when the model was generated** decides. Audit which models came from which plan. AI disclosure: Steam mandatory; itch.io disclosure field; Epic none for games; GOG no published rule.
Sources: help.meshy.ai/en/articles/16102098-can-i-use-meshy-assets-commercially, meshy.ai/pricing

## Steam: phases

**Realistic minimum timeline from paying the fee: about 6-9 weeks** (paperwork 15-30 days overlapping + store-page review up to 12 business days + ≥2 weeks Coming Soon + build review up to 12 business days + the wait from the fee payment).

### 1. Account and fees
- Steamworks partner account at partner.steamgames.com, Steam Guard on, **phone number attached** (SMS needed to set builds live on the default branch of a released app; steamcmd can't do that step). (partner.steamgames.com/doc/store/application/builds)
- **Steam Direct fee: $100 per app** (one "app credit"), non-refundable, recouped after **$1,000 Adjusted Gross Revenue**. Demos and Playtests are free child apps. (partner.steamgames.com/doc/gettingstarted/appfee)
- **Wait between paying the fee and release: plan on 30 days** (some pages say 21) **[CONFLICTING: check your Steamworks account]**.
- Revenue: 70/30; 75/25 above $10M; 80/20 above $50M (per product).

### 2. Tax, bank, identity
Legal details (bank holder name must match), tax questionnaire (W-9 US / W-8BEN or W-8BEN-E), verified by a third party; onboarding **15-30 days**; payouts may wait until $100 owed. (partner.steamgames.com/doc/gettingstarted/onboarding)

### 3. Legal and content
- **Content Survey (mandatory)**, AI section: the Meshy models are **Pre-Generated** content: describe what was AI-generated and how it was edited; shown on the store page. Example: "Some 3D models were initially generated with an AI text-to-3D tool and then modified by our team; all other art, audio, code and text were human-made." Make it accurate. (partner.steamgames.com/doc/gettingstarted/contentsurvey)
- **Ads**: "Steam does not contain any paid advertising, nor are advertising models supported." (partner.steamgames.com/doc/marketing/advertising)
- **Microtransactions** must use the Steam microtransaction API / Wallet; build review checks this.
- **Steam keys** may be sold elsewhere (e.g. itch.io) but Steam customers must not get a worse deal.

### 4. Technical and builds
- Upload with **SteamPipe / steamcmd** (works on Linux and GitHub Actions); one depot per OS with a launch option each; a dedicated builder account.
- DRM and the Steamworks API are not required.
- Windows x86_64: GL Compatibility runs natively and under Proton; declare redistributables ("none" is likely right for Godot's templates **[UNVERIFIED: test on a clean PC]**).
- **macOS: new macOS apps must be 64-bit and notarized by Apple** (tick "App Bundles Are Notarized"); the overlay needs entitlements (disable library validation, allow DYLD env vars). So a Mac build on Steam needs the Apple Developer Program. (partner.steamgames.com/doc/store/application/platforms)
- Linux: choose a Steam Linux Runtime under Installation > Linux Runtime.
- Cloud saves: Auto-Cloud (quota + root paths + overrides for macOS/Linux) pointed at Godot's `user://`. (partner.steamgames.com/doc/features/cloud)
- Achievements/leaderboards/on-screen keyboard need the Steamworks API (GodotSteam plugin **[UNVERIFIED for 4.7.2]**).
- **Steam Deck / Steam Machine Verified**: default controller config reaches all content; Deck/Xbox glyphs; on-screen keyboard for text entry; runs at 1280x800 (or 1280x720); **smallest text ≥9 px at 1280x800**; playable framerate by default; controller-navigable launcher; no unsupported anti-cheat. Request the review in Steamworks. Testing without a Deck: set 1280x800 and shrink the window to about 7 inches across. (partner.steamgames.com/doc/steamhardware/compat · …/steamdeck/testing)

### 5. Store page assets (Aug 2024 sizes, mandatory)

| Asset | Size (px) | Required | Notes |
|---|---|---|---|
| Header capsule | 920x430 | Yes | |
| Small capsule | 462x174 | Yes | logo legible when small |
| Main capsule | 1232x706 | Yes | |
| Vertical capsule | 748x896 | Yes | |
| Screenshots | ≥1920x1080, 16:9 | **≥5** | real gameplay; for a portrait game show the real fullscreen presentation with side art |
| Page background | 1438x810 | Optional | |
| Library capsule | 600x900 | Yes | logo + optional subtitle only |
| Library header | 920x430 | Yes | |
| Library hero | 3840x1240 | Yes | no text; safe area 860x380 |
| Library logo | 1280 wide and/or 720 tall PNG | Yes | transparent background |
| Shortcut icon | 256x256 | Yes | |
| Community icon | 184x184 JPG | Yes | |
| Mac icon | .icns | Recommended | |

Rules: base capsules only artwork + name + official subtitle (no review scores, awards, discount text); PG-13 artwork. **Trailer** (recommended): mp4/mov, H.264 + AAC, up to 1920x1080, 30/60 fps, >5,000 kbps, 16:9 **[page is old: re-check]**. Also: description, tags, languages, system requirements, Content Survey, price, release date. (partner.steamgames.com/doc/store/assets …/libraryassets …/rules …/trailer)

### 6. Testing / Playtest
**Steam Playtest**: free child app shown on the main page; keys before the store page is live; can't charge. Beta branches with keys for QA. Test on a Deck (or the no-Deck method) and a non-dev PC.

### 7. Submission and review
**Store page review first, then build review**; each normally 3-5 business days, **currently up to 12**. Build review: starts on every listed OS, every listed feature exists, purchases via Steam Wallet, **≥5 minutes of Steam-launched play within 7 days**, reviewers can reach all content. Only show content that exists at launch. (partner.steamgames.com/doc/store/review_process)

### 8. Coming Soon and launch
**Coming Soon page public ≥2 weeks** before release; within 14 days of release only Valve can change the date. Release manually with the Release button. Optional launch discount 7-14 days, 10-40% (30-day cooldown after). Refund rule: within 14 days and under 2 hours of play, which matters for a short arcade game **[standard policy; not re-verified]**.

## Open items
Fee-to-release wait (30 vs 21 days); exact Nov 2026 checklist wording; payout timing; GodotSteam 4.7.2 support; Godot redistributables.
