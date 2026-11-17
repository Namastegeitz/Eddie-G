# 00 · Shared store kit

Everything more than one store uses. Made once, pasted everywhere.

| What | File | Used by |
|---|---|---|
| Store text (every field at the right length) | [store-text.md](store-text.md) | all |
| Age-rating answers (Apple, IARC, Steam) | [age-rating.md](age-rating.md) | all |
| App Store icon 1024x1024 (no transparency) | icons/app-store-1024.png | Apple |
| Google Play icon 512x512 | icons/google-play-512.png | Google Play, Samsung, Amazon |
| Desktop icon 256 (transparent) | icons/desktop-256.png | itch.io, Microsoft |
| Play feature graphic 1024x500 | art/play-feature-graphic-1024x500.png | Google Play |
| itch.io cover 630x500 | art/itch-cover-630x500.png | itch.io |
| iPhone 6.9" screenshots 1320x2868 | screenshots/iphone-6.9/ | Apple |
| Android phone screenshots 1080x1920 | screenshots/android-phone/ | Google Play, Samsung, Amazon |
| iPad 13" screenshots 2064x2752 | screenshots/ipad-13/ | Apple (iPad), Google Play (tablet) |
| Desktop screenshots 1920x1080 (PC edition, JPEG) | screenshots/desktop-1080p/ | Steam, GOG, itch.io, Microsoft, Epic |
| Shop screenshot for Apple's purchase review | screenshots/shop-review/ | Apple in-app purchases |
| Privacy policy page | https://namastegeitz.github.io/Eddie-G/privacy.html | all |
| Support page | https://namastegeitz.github.io/Eddie-G/support.html | all |
| In-app product list (26) | ../../docs/STORE_PRODUCTS.md | Apple, Google Play |

## Remake the images

All images are rendered from the real game, so they stay true to it:

```
node scripts/make_store_art.cjs all        # or: icons | art | steam | phone | android | ipad | desktop
node scripts/check_store_text.mjs          # checks every text field's length
```

## Sizes at a glance

| Store | Icon | Screenshots | Banner art |
|---|---|---|---|
| Apple | 1024x1024 PNG, no alpha | 6.9" iPhone 1320x2868 (required); 13" iPad 2064x2752 (if iPad) | none |
| Google Play | 512x512 PNG | 2-8 phone, 16:9 or 9:16, 320-3840 px per side; tablets optional | feature graphic 1024x500 |
| Steam | (from the build) | 5+ at 1920x1080 | see release/06-steam |
| itch.io | (optional) | any, 1280x720 or larger looks best | cover 630x500 |
| GOG | given after acceptance | 1920x1080 | given after acceptance |
| Microsoft Store | 300x300 store logo (from 1024) | 1366x768 or larger | optional hero 1920x1080 |
