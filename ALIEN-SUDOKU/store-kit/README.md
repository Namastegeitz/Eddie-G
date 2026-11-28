# Store kit: everything a store submission needs, in one place

Most of it already lives in `store-launch/`; this page points to each piece and adds
what was missing (shot lists, accessibility answers, credits, release plan).
The step-by-step guide for submitting is `store-launch/STEP-BY-STEP.md`.

| Item | Where |
|---|---|
| Title, subtitle, short and full description, keywords, promo text | `store-launch/listing/listing.md` (checked against each store's limits by `listing/check-listing.mjs`) |
| What's New (1.3.0) | `store-launch/listing/listing.json` → `whatsNew` (367 characters; Play limit 500) |
| Privacy policy URL | https://namastegeitz.github.io/Eddie-G/alien-sudoku/privacy.html |
| Support URL | https://namastegeitz.github.io/Eddie-G/alien-sudoku/support.html |
| Marketing site | https://namastegeitz.github.io/Eddie-G/alien-sudoku/ |
| Support email | **To do**: the new support Gmail (guide step 1) |
| Screenshots | `store-launch/assets/screenshots/<device>/` (7 scenes × 5 sizes) · shot list: [shot-list.md](shot-list.md) |
| Store graphics | `store-launch/assets/graphics/` (Play feature graphic, icons, Steam capsules, covers) |
| Data safety / App Privacy / age rating answers | `store-launch/STEP-BY-STEP.md` (G4, A8) |
| Accessibility label answers (Apple) | [accessibility.md](accessibility.md) |
| Credits and rights | [credits.md](credits.md) |
| Release plan and rollback | [release-plan.md](release-plan.md) |
| Changelog for players | `../CHANGELOG.md` |

Every claim in the store text is checkable in the game: no health, income or energy claims.
