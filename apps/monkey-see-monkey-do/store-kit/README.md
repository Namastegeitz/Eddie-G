# Store kit · Monkey See, Monkey Do

Everything a store submission needs, in one place. Text and images that
already existed stay where they are (the store-by-store folders in
[`../release/`](../release/)); this folder indexes them and adds what was
missing.

| What | Where |
|---|---|
| Title, subtitle, short and long description, keywords, What's New (all within each store's limits) | [`../release/00-shared/store-text.md`](../release/00-shared/store-text.md) (check: `node scripts/check_store_text.mjs`) |
| What's New for 1.1.0 | [`../CHANGELOG.md`](../CHANGELOG.md) |
| Privacy policy URL | https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/privacy.html (generated to match the build's crash-report setting) |
| Support URL | https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/support.html |
| Age-rating answers | [`../release/00-shared/age-rating.md`](../release/00-shared/age-rating.md) |
| Google Play Data safety and Apple App Privacy answers | [`../release/03-google-play/data-safety.md`](../release/03-google-play/data-safety.md) |
| Icons, banners, Steam art, screenshots | [`../release/00-shared/`](../release/00-shared/), [`../release/06-steam/art/`](../release/06-steam/art/) |
| Screenshot and preview-video shot list | [`shot-list.md`](shot-list.md) |
| Accessibility label answers (Apple) | [`accessibility-labels.md`](accessibility-labels.md) |
| Credits and licences | [`credits.md`](credits.md) |
| Release plan, staged rollout and rollback | [`release-plan.md`](release-plan.md) |

Every claim in the store text must stay true and checkable: no health,
learning-outcome or "brain training" claims.
