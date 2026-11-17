# 08 · More stores (optional)

| Store | Cost | Build | Notes |
|---|---|---|---|
| **Microsoft Store** (Windows) | Free for individuals (since 2025) | PWABuilder.com from the beta link, or the Electron build as MSIX | Sign up at storedeveloper.microsoft.com (ID check). The Store signs the package. IARC rating in Partner Center. |
| **Epic Games Store** (PC) | $100 per game, 12% fee | release/05-desktop | Epic Developer Portal. Achievements required for new games; IARC rating free during setup. |
| **Samsung Galaxy Store** | Free | the Android build | seller.samsungapps.com. Samsung needs its own purchase setup: launch free-only first if simpler. |
| **Amazon Appstore** (Fire tablets) | Free | the Android build | developer.amazon.com. Now focused on Fire devices; popular with families. |

## Microsoft Store, the quick way

1. Switch on GitHub Pages so the beta link is live.
2. Open pwabuilder.com, enter https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/play/
3. Package for Windows (MSIX); upload in Partner Center.

The PWA package uses the standard web edition. For a Shop-free Windows version,
upload the Electron build as MSIX instead (electron-builder target `appx`).
