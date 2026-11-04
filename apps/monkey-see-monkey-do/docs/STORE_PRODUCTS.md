# In-app products

Generated from `js/store.js` by `node scripts/make_store_files.mjs`. Create each
product with exactly this ID in App Store Connect (Monetization > In-App
Purchases) and Google Play Console (Monetize > Products > In-app products).
US prices are listed; let each store fill in the other countries from them.

| Product ID | App Store type | Google Play | Name | Description (max 45) | US price |
|---|---|---|---|---|---|
| `com.namastegeitz.monkeydo.starter` | Non-Consumable | One-time product, non-consumable | Starter Pack | 1,000 bananas, 15 golden + 2 items | $0.99 |
| `com.namastegeitz.monkeydo.combo_party` | Consumable | One-time product, consumable | Party Pack | 1,500 bananas + 20 golden bananas | $2.99 |
| `com.namastegeitz.monkeydo.combo_mega` | Consumable | One-time product, consumable | Mega Party Pack | 5,000 bananas + 70 golden bananas | $7.99 |
| `com.namastegeitz.monkeydo.bananas_500` | Consumable | One-time product, consumable | Handful of Bananas | 500 bananas | $0.99 |
| `com.namastegeitz.monkeydo.bananas_1200` | Consumable | One-time product, consumable | Bunch of Bananas | 1,200 bananas | $1.99 |
| `com.namastegeitz.monkeydo.bananas_3500` | Consumable | One-time product, consumable | Banana Crate | 3,500 bananas | $4.99 |
| `com.namastegeitz.monkeydo.bananas_8000` | Consumable | One-time product, consumable | Banana Truck | 8,000 bananas | $9.99 |
| `com.namastegeitz.monkeydo.golden_12` | Consumable | One-time product, consumable | Pocket of Golden Bananas | 12 golden bananas | $0.99 |
| `com.namastegeitz.monkeydo.golden_30` | Consumable | One-time product, consumable | Pouch of Golden Bananas | 30 golden bananas | $1.99 |
| `com.namastegeitz.monkeydo.golden_85` | Consumable | One-time product, consumable | Chest of Golden Bananas | 85 golden bananas | $4.99 |
| `com.namastegeitz.monkeydo.golden_190` | Consumable | One-time product, consumable | Vault of Golden Bananas | 190 golden bananas | $9.99 |
| `com.namastegeitz.monkeydo.bundle_space` | Non-Consumable | One-time product, non-consumable | Space Explorer | Astronaut skin + 4 matching items | $2.99 |
| `com.namastegeitz.monkeydo.bundle_pirate` | Non-Consumable | One-time product, non-consumable | Pirate Captain | Pirate skin + 4 matching items | $2.99 |
| `com.namastegeitz.monkeydo.bundle_rock` | Non-Consumable | One-time product, non-consumable | Rock Legend | Rock Star skin + 4 matching items | $2.99 |
| `com.namastegeitz.monkeydo.bundle_royal` | Non-Consumable | One-time product, non-consumable | Royal Court | Royal skin + 4 matching items | $2.99 |
| `com.namastegeitz.monkeydo.bundle_beach` | Non-Consumable | One-time product, non-consumable | Beach Day | Ocean skin + 4 matching items | $2.99 |
| `com.namastegeitz.monkeydo.bundle_spooky` | Non-Consumable | One-time product, non-consumable | Spooky Night | Vampire skin + 4 matching items | $2.99 |
| `com.namastegeitz.monkeydo.bundle_party` | Non-Consumable | One-time product, non-consumable | Party Animal | Pop Star skin + 4 matching items | $2.99 |
| `com.namastegeitz.monkeydo.set_metals` | Non-Consumable | One-time product, non-consumable | Precious Metals set | All 5 Precious Metals skins | $4.99 |
| `com.namastegeitz.monkeydo.set_cosmic` | Non-Consumable | One-time product, non-consumable | Cosmic set | All 6 Cosmic skins | $4.99 |
| `com.namastegeitz.monkeydo.set_elements` | Non-Consumable | One-time product, non-consumable | Elements set | All 6 Elements skins | $4.99 |
| `com.namastegeitz.monkeydo.set_mythic` | Non-Consumable | One-time product, non-consumable | Mythic set | All 7 Mythic skins | $4.99 |
| `com.namastegeitz.monkeydo.set_spooky` | Non-Consumable | One-time product, non-consumable | Spooky set | All 6 Spooky skins | $4.99 |
| `com.namastegeitz.monkeydo.set_tech` | Non-Consumable | One-time product, non-consumable | Tech set | All 6 Tech skins | $4.99 |
| `com.namastegeitz.monkeydo.set_party` | Non-Consumable | One-time product, non-consumable | Party & Music set | All 7 Party & Music skins | $4.99 |
| `com.namastegeitz.monkeydo.set_heroes` | Non-Consumable | One-time product, non-consumable | Heroes set | All 7 Heroes skins | $4.99 |

Consumables can be bought again and again (packs). Non-consumables are bought
once and restored with "Restore purchases" (bundles, sets, the Starter Pack).
