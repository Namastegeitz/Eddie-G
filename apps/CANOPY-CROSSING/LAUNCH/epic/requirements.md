# **CANOPY CROSSING: Epic Games Store requirements**

Researched 2026-11-17 from official pages (some via search extracts, marked); re-check on the day.
Shared PC-edition decisions: [../steam/requirements.md](../steam/requirements.md#the-pc-edition-applies-to-steam-gog-itchio-epic-microsoft).

## Recent changes
**Jun 2025**: developers keep **100% of the first $1M net revenue per product per calendar year**, then 88/12 (resets 1 January).

## 1. Account and fees
Epic account + organization in the Developer Portal; **$100 submission fee per product** (plus tax), non-refundable, recouped once the product earns ≥$1,000; a legal signatory accepts the **Distribution Agreement**. (dev.epicgames.com/docs/epic-games-store/get-started/get-started-steps/onboarding)

## 2. Tax and bank
Trader verification, tax interview (W-9/W-8; up to 5 business days), then **Hyperwallet** payouts. **Organization verification can take 2+ weeks, and you can't submit for final review until it's done.**

## 3. Legal and content
- **Achievement parity**: products onboarded after 9 Mar 2023 with achievements on other PC stores must offer similar EGS achievements via EOS (macOS reportedly exempt: confirm).
- **Update parity**: Epic must receive patches **no later than** any other store (don't patch Steam first).
- Ratings: unrated products are treated as highest maturity; Germany, Australia, Brazil, Russia need IARC or a regional rating: use the free **IARC** questionnaire in the portal (3-hour limit once started).
- **AI: no disclosure requirement for games on EGS**; you still need rights to the content (Meshy licence).

## 4. Technical and builds
- **Platforms: Windows and Mac only (no Linux).** Upload with **BuildPatch Tool** (1.7.x); BuildVersion unique per artifact across platforms; Mac AppLaunch `Game.app/Contents/MacOS/Game`.
- Mac notarization requirement **[UNVERIFIED]**: notarize anyway. EOS SDK only for achievements (community Godot plugin **[UNVERIFIED]**).

## 5. Store page assets

| Asset | Spec |
|---|---|
| Landscape offer image | **2560x1440** jpg/png |
| Portrait offer image | **1200x1600** jpg/png |
| Product logo | **960x540 PNG**, ≤1 MB |
| Carousel images/videos | **1920x1080**; images ≤4 MB; MP4 ≤300 MB, 30/60 fps, AAC stereo; **≥5 items recommended incl. ≥1 video** |
| About-section images | ≥700 px wide, ≤4 MB |
| Additional images | 1920x1080 jpg, ≤1 MB, up to 20 |
| Social preview (optional) | 1200x1200 jpg |

(dev.epicgames.com/docs/epic-games-store/sales-and-marketing/marketing/storefront-media-guide)

## 6. Testing
Stage sandbox and dev/test artifacts before submitting.

## 7. Submission and review
Onboarding > publish the product home page (early awareness; ~1 week, review 2+ days) > offers and binaries > submit for final review (locked while "In Review"). **The offer needs an available date and an attached binary at least 1 week before that date.**

## 8. Launch
Release from the Live sandbox (base offer, store settings, home page, artifact); staged changes must pass review before the publish time.

---

# **Microsoft Store for PC (brief)**

- Account **free for individuals since 10 Sep 2025** (storedeveloper.microsoft.com; ID + selfie check); company fee **[UNVERIFIED]**.
- **12% fee for PC games** (App Developer Agreement v8.11, 17 Mar 2026).
- Packaging: **MSIX** (the Store re-signs and handles commerce: the practical route for a Godot game); MSI/EXE (you Authenticode-sign everything, host a versioned HTTPS installer, silent install, no Store updates); GDK/MSIXVC (PC-only self-service; docs conflict on concept approval).
- IARC rating in Partner Center. **Low priority.**
- Sources: blogs.windows.com/windowsdeveloper/2025/09/10/free-developer-registration-for-individual-developers-on-microsoft-store/ · learn.microsoft.com/en-us/windows/apps/publish/

## Open items
Mac notarization on Epic; macOS achievement exemption; Godot EOS plugin; Microsoft company fee and EXE/MSI billing; GDK prerequisites.
