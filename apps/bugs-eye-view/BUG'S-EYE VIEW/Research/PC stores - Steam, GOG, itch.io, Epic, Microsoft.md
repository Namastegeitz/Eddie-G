# PC stores - Steam, GOG, itch.io, Epic Games Store, Microsoft Store

Researched 2026-11-17 from partner.steamgames.com, GOG's developer docs,
itch.io docs, dev.epicgames.com, learn.microsoft.com and the Godot docs.
Check the linked page before acting on anything that changes often.

## Recommended order for a solo developer
1. **Week 0:** sign up for **Steam Direct** and pay the $100 first (longest lead time); start Epic onboarding and the Microsoft account in parallel.
2. **Week 0-1:** put up an **itch.io** page with the free web version (same day, real feedback).
3. When the art is ready: **Steam "Coming Soon"** page (2 weeks minimum; months of wishlists is better); optional Epic early-awareness page.
4. **Pitch GOG** once the Steam page and a trailer are live.
5. Decide on **macOS**: notarize it (opens Steam and Epic for Mac) or ship the Mac build only on itch.io and GOG.
6. Launch Steam, itch.io and Epic the same day; GOG when contracted (Release Candidate 3-5 days before); Microsoft Store when the MSIX is ready.

## Steam
- **Steam Direct (you, $100 per game, 15-30 days):** NDA + distribution agreement, $100 fee (refunded after $1,000 gross), bank details in your legal name, company = your legal name with "Sole Proprietorship", tax interview (W-9/W-8BEN), identity check (tax check up to 30 days). [onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding)
- Create the app, upload a build, fill the store page checklist.
- **Store page review 3-5 business days** - submit 7+ business days before you want it live, then "Post as Coming Soon".
- **Two waits:** Coming Soon page public for **at least 2 weeks**; **21 days** between paying and releasing.
- **Build review 3-5 business days** (plan 7) after the page review; the build must launch on every OS listed.
- **You press "Release App"** yourself.
- Valve's share 30% (25% above $10M, 20% above $50M).
- Builds via **SteamPipe** (one depot per OS; steamcmd or SteamPipeGUI). Steamworks SDK/DRM optional. **macOS builds must be notarized by Apple** - don't list Mac until it is. No web builds.
- **Images** ([store](https://partner.steamgames.com/doc/store/assets/standard), [library](https://partner.steamgames.com/doc/store/assets/libraryassets)) - all ready in `Store Assets/Steam/`: header 920x430, small 462x174, main 1232x706, vertical 748x896, library capsule 600x900, library header 920x430, library hero 3840x1240 (no text), library logo 1280x720 transparent, page background 1438x810 (optional), **5+ screenshots 1920x1080** (gameplay; mark 4+ "suitable for all ages"). Capsules may carry only the title/logo.

## GOG (curated)
- **Pitch (free):** the form at [gog.com/submit-your-game](https://www.gog.com/submit-your-game) (~15 questions: developer, title, description, platforms, status, price, DLC/microtransactions). GOG doesn't publish its criteria; quality, fit and visible demand matter - have the Steam page, wishlists, a trailer and an IGDB entry ready. Replies take days to weeks, or "not a good fit", or none.
- If accepted: contract, Developer Portal, **Essentials Checklist** (key art + logo 1920x1080+ as layered PSDs from GOG's templates, description, system requirements, screenshots, trailer with the GOG end slate, price list), build via **Build Creator** (in GOG Galaxy) or Pipeline Builder -> staging branch -> QA (must run offline and without Galaxy, **no links to other stores**) -> GOG publishes.
- 70/30 split (third-party reports). Windows, macOS (single .app), Linux (64-bit, bundled libraries). Cloud saves need saves in their own folder (<= 200 MB).

## itch.io (fastest - same day)
- Free. Create project -> title, short description, **cover 630x500**, screenshots (3-5), upload a zip per platform or the **web build as a zip with index.html** (<= 1,000 files, 500 MB), genre + up to 10 tags, Public.
- Payments: "Collected by itch.io" (they handle VAT; PayPal/Payoneer; you choose their cut, 10% default).
- First paid project from a new seller is reviewed before it shows in search (works by direct link meanwhile).
- Unsigned Windows .exe -> SmartScreen warning; unsigned Mac app -> right-click > Open.

## Epic Games Store
- Onboarding: 18+, Distribution Agreement, **$100 per product**, questionnaire, trader verification, tax profile, payout account (up to ~2 weeks).
- Optional early-awareness page (free IARC rating in the portal, wishlists). Upload with the BuildPatch Tool; final review 3-5 business days; you release it.
- No curation, compliance review only. Windows and macOS (no Linux, no web). Must work offline; achievements required only if you have them elsewhere.
- Keep 100% of the first $1M per product per year, then 88/12.
- **Images** (`Store Assets/Epic Games Store/`): logo 960x540 PNG, offer 2560x1440 + 1200x1600, carousel 1920x1080, social 1200x1200.

## Microsoft Store
- Account at storedeveloper.microsoft.com, **no fee**. Individual = government ID + selfie, meant for non-commercial/hobby; **selling as a business needs a Company account** (DUNS or business documents) and an individual account can't be converted later - decide first.
- Submission: reserve the name, pricing/markets, Games category, IARC questionnaire, package, listing. Certification up to 3 business days.
- **Package:** MSIX (Microsoft signs and hosts; Store payments) - wrap the Godot .exe with the MSIX Packaging Tool / makeappx. (MSI/EXE route needs your own code-signing certificate and hosting.)
- Microsoft takes 12% on games.
- **Images** (`Store Assets/Microsoft Store/`): screenshots 1366x768+ (we use 1920x1080), 2:3 poster 1440x2160, 1:1 box art 2160x2160, tile 300x300, 16:9 super hero 3840x2160 (no text).

## Godot notes
- Windows: Godot can sign at export (SignTool / `GODOT_WINDOWS_CODESIGN_*`); signing matters for direct downloads (itch.io, your site). A code-signing certificate comes from a CA (Microsoft's Artifact Signing only validates individuals in the US/Canada).
- macOS: one Universal .app, exported as a **.zip** (keeps the executable flag). Notarizing without a Mac: Apple Developer ID certificate (Apple Developer Program) + rcodesign + an App Store Connect API key. Without it: right-click > Open.
- Web: Compatibility renderer only (what this game uses).
- Saves: turn on a custom user directory so saves sit in their own %APPDATA% folder (GOG cloud saves).
- GodotSteam is optional; keep it out of the GOG/itch/Epic builds.
