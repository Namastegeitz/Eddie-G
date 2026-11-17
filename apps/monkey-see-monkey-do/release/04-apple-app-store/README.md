# 04 · Apple App Store (iPhone and iPad)

**Build goes in:** `build/` (an archive is uploaded straight from Xcode; keep a note
of each build number here). Cost: $99 per year. Bundle ID: `com.namastegeitz.monkeydo`.
iOS 15 and up. Uploads must be built with **Xcode 26 / iOS 26 SDK** (since April 2026).

## Why the build isn't here yet

Apple builds need macOS. Options:

- **Your Mac:** install Xcode 26, open `mobile/ios/App/App.xcodeproj`.
- **No Mac:** Codemagic's cloud Macs. The config is ready in
  `mobile/ci/codemagic.yaml`; add an App Store Connect API key in Codemagic and it
  uploads to TestFlight.

## Build and upload

```
cd apps/monkey-see-monkey-do
node scripts/build_web.mjs
cd mobile && npx cap sync ios
```

Xcode: select the App target > Signing & Capabilities > your Team; add the
**In-App Purchase** capability. Product > Archive > Distribute App > App Store
Connect > Upload. Bump the build number for each upload.

Try every purchase first in the Simulator with `mobile/ios/App/MonkeyDo.storekit`
(Scheme > Edit Scheme > Run > Options > StoreKit Configuration).

## App Store Connect, in order

1. Agreements, Tax, and Banking: Paid Apps agreement (needed even for free apps with purchases).
2. New App: iOS, name, English (US), bundle ID, SKU `monkeydo-001`.
3. In-App Purchases: the 26 products in ../../docs/STORE_PRODUCTS.md, with the
   review screenshot ../00-shared/screenshots/shop-review/01-shop.jpg.
4. App Privacy: **Data Not Collected**.
5. Age rating: answers in ../00-shared/age-rating.md (expected 4+).
6. Listing: name 30, subtitle 30, promotional text 170, description 4000,
   keywords 100 (from ../00-shared/store-text.md). Screenshots: iphone-6.9
   (required), ipad-13 (iPad). Support URL and privacy URL from the beta site.
7. TestFlight: internal testers, then external (your beta group).
8. Submit for review with [review-notes.md](review-notes.md).

Decide on the Kids Category before submitting (suggested: not at first; the
game is already rated 4+ and has the parental gate Apple requires for kids' apps).
