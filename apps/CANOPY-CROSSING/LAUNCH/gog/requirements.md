# **CANOPY CROSSING: GOG requirements**

Researched 2026-11-17 from official pages (some via search extracts, marked); re-check on the day.
The PC-edition decisions shared by every PC store (no ads or real-money purchases, offline, portrait on wide screens, controllers, saves, Meshy licence) are in [../steam/requirements.md](../steam/requirements.md#the-pc-edition-applies-to-steam-gog-itchio-epic-microsoft).

## Recent changes
- **Dec 2025 / Jan 2026**: CD Projekt sold GOG to co-founder Michał Kiciński (~$25M); GOG says DRM-free is "more central than ever" and 70/30 is the "starting point", contracts assessed individually (managing director interview, seen via secondary coverage). Jan 2026: controversy over AI art in GOG's own sale banner.
- **5 Nov 2026**: GOG Galaxy for Linux announced for 2027; today Linux games on GOG are offline-installer only.

## 1. Getting in (curated)
- Submit via the form at **gog.com/indie** (lp.gog.com/submit-your-game/en): ~15 questions (description, status, expected date, planned price, stage). Free; **acceptance curated and not guaranteed**; GOG can't give feedback on very early projects, so submit near completion.
- No published response time **[UNVERIFIED]**: treat GOG as an add-on, not a launch dependency.
- Revenue: 70/30 "starting point"; **get the split in writing**.

## 2. Tax and bank
Through the contract and partner process after acceptance **[UNVERIFIED specifics]**.

## 3. Legal and content
- **DRM-free**: playable offline and without the Galaxy client; QA tests this. (docs.gog.com/quality-assurance/)
- Microtransactions: no current written policy found; historically avoided **[UNVERIFIED]**; ship the premium edition.
- AI: no GOG disclosure rule found **[UNVERIFIED]**; given the audience's reaction in Jan 2026, tell your Product Manager about the Meshy models and consider stating it on the page.
- Refunds: 30 days regardless of playtime (2020 policy) **[not re-verified]**.

## 4. Technical and builds
- **Build Creator** (GUI, Windows/macOS/Linux) or **Pipeline Builder** (CLI, for CI): `build-game` with a `project.json`; it publishes only to **private branches**; master/public publishing is in the Developer Portal. (docs.gog.com/pb-quick-start/ …/pb-publish-build/)
- Windows and macOS ship through Galaxy plus offline installers that GOG generates after publishing to Master (hours); the game name can't contain `~ # % *`. (docs.gog.com/offline-installers/)
- **Linux**: offline `.sh` installers from the website only (no Galaxy, no Galaxy SDK); keep executables marked executable. (docs.gog.com/bc-linux/ …/linux-guidelines/)
- **macOS**: ship a `.app`; notarized apps may not work with the App Bundle install structure; GOG suggests the "Normal folder" option (older page: ask your Product Manager). Don't save inside the `.app`.
- Cloud saves without code via `saveFolders` (own subfolder, under **200 MB** total) **[old doc: confirm]**. Achievements need the Galaxy SDK (C++; no official Godot binding **[UNVERIFIED]**).

## 5. Store page assets
Through the Assets Manager / Asset Rendering Tool: **key art and logo ≥1920x1080 as layered .PSD**; screenshots (no published count/size); **trailer with the GOG.com logo on the end slate**; description (checklist lists EN, DE, FR, CN, PL, RU); system requirements, languages, genres, tags; optional ratings. (docs.gog.com/basic-game-assets/)

## 6. Testing
Test the Release Candidate on a Beta/Staging branch via Galaxy, and from the offline installers.

## 7. Submission and review
Upload the Release Candidate, tell your Product Manager; QA checks crashes, major bugs **and DRM** (with Galaxy removed). **Deliver the RC at least 3-5 days before launch.** (docs.gog.com/build-delivery/ …/release-flow/)

## 8. Launch
Date coordinated with your Product Manager; offline installers must be live on day one.

## Open items
Response time, current split and payouts, microtransaction stance, AI policy, notarization vs App Bundle, 200 MB cloud quota.
