// Writes the files you need to set up the in-app products, from js/store.js:
//   mobile/ios/App/MonkeyDo.storekit   Xcode StoreKit test file (try purchases in the Simulator, no account needed)
//   docs/STORE_PRODUCTS.md             the product list to enter in App Store Connect and Google Play Console
//   docs/store-products.csv            the same list as a spreadsheet
//   node scripts/make_store_files.mjs
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PRODUCTS, PRODUCT_PREFIX } from '../js/store.js';
import { getSkin } from '../js/skins.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const n = (x) => x.toLocaleString('en-US');

/** App Store descriptions are limited to 45 characters. */
function short(p) {
  const g = p.grants;
  const items = g.skins.length + g.gear.length;
  if (p.group === 'sets') return `All ${g.skins.length} ${p.title.replace(/ set$/, '')} skins`.slice(0, 45);
  if (p.group === 'bundles') return `${getSkin(g.skins[0]).name} skin + ${g.gear.length} matching items`.slice(0, 45);
  const parts = [];
  if (g.bananas) parts.push(`${n(g.bananas)} bananas`);
  if (g.golden) parts.push(`${n(g.golden)} golden bananas`);
  let s = parts.join(' + ');
  if (items) s = `${parts.join(', ').replace(' golden bananas', ' golden')} + ${items} items`;
  return s.slice(0, 45);
}

// ---------------------------------------------------------------- Xcode StoreKit configuration
const storekit = {
  identifier: 'C0FFEE00',
  nonRenewingSubscriptions: [],
  products: PRODUCTS.map((p, i) => ({
    displayPrice: p.usd.toFixed(2),
    familyShareable: false,
    internalID: String(6500000000 + i),
    localizations: [{ description: short(p), displayName: p.title.slice(0, 30), locale: 'en_US' }],
    productID: PRODUCT_PREFIX + p.id,
    referenceName: p.title,
    type: p.type === 'consumable' ? 'Consumable' : 'NonConsumable',
  })),
  settings: { _failTransactionsEnabled: false, _locale: 'en_US', _storefront: 'USA', _storeKitErrors: [] },
  subscriptionGroups: [],
  version: { major: 2, minor: 0 },
};
const skPath = join(root, 'mobile/ios/App/MonkeyDo.storekit');
mkdirSync(dirname(skPath), { recursive: true });
writeFileSync(skPath, JSON.stringify(storekit, null, 2) + '\n');

// ---------------------------------------------------------------- product list
const rows = PRODUCTS.map((p) => ({
  id: PRODUCT_PREFIX + p.id,
  apple: p.type === 'consumable' ? 'Consumable' : 'Non-Consumable',
  google: p.type === 'consumable' ? 'One-time product, consumable' : 'One-time product, non-consumable',
  title: p.title,
  short: short(p),
  usd: p.usd.toFixed(2),
}));
const md = `# In-app products

Generated from \`js/store.js\` by \`node scripts/make_store_files.mjs\`. Create each
product with exactly this ID in App Store Connect (Monetization > In-App
Purchases) and Google Play Console (Monetize > Products > In-app products).
US prices are listed; let each store fill in the other countries from them.

| Product ID | App Store type | Google Play | Name | Description (max 45) | US price |
|---|---|---|---|---|---|
${rows.map((r) => `| \`${r.id}\` | ${r.apple} | ${r.google} | ${r.title} | ${r.short} | $${r.usd} |`).join('\n')}

Consumables can be bought again and again (packs). Non-consumables are bought
once and restored with "Restore purchases" (bundles, sets, the Starter Pack).
`;
mkdirSync(join(root, 'docs'), { recursive: true });
writeFileSync(join(root, 'docs/STORE_PRODUCTS.md'), md);
const csv = ['product_id,apple_type,google_type,name,description,usd_price', ...rows.map((r) => [r.id, r.apple, r.google, r.title, r.short, r.usd].map((v) => `"${String(v).replace(/"/g, '""')}"`).join(','))].join('\n') + '\n';
writeFileSync(join(root, 'docs/store-products.csv'), csv);
console.log(`${PRODUCTS.length} products -> mobile/ios/App/MonkeyDo.storekit, docs/STORE_PRODUCTS.md, docs/store-products.csv`);
const long = rows.filter((r) => r.short.length > 45 || r.title.length > 30);
if (long.length) throw new Error('Too long for App Store: ' + long.map((r) => r.id).join(', '));
