// The Shop: everything that can be bought with real money, in the iPhone
// and Android apps (through Apple's and Google's own payment systems).
// Pure data + pure helpers (tests/unit.mjs checks prices and contents).
//
// Ground rules (shown in How it works):
//  - Prices from $0.99 to $9.99 (US prices; the stores convert for each country).
//  - Nothing is only for money: every skin and item can also be earned or
//    bought with bananas / golden bananas from playing.
//  - No timers, no "limited time", no random boxes. You see exactly what you get.
//  - A grown-up check and an optional monthly limit (Settings > Purchases).

export const PRODUCT_PREFIX = 'com.namastegeitz.monkeydo.';

// grants: { bananas, golden, skins: [ids], gear: ['slot:id'] }
const P = (id, group, type, usd, title, grants, desc, extra = {}) => ({ id, group, type, usd, title, grants: { bananas: 0, golden: 0, skins: [], gear: [], ...grants }, desc, ...extra });

export const PRODUCTS = [
  // ---------------------------------------------------------------- deals
  P('starter', 'deals', 'nonconsumable', 0.99, 'Starter Pack', { bananas: 1000, golden: 15, gear: ['feet:sneakers', 'back:backpack'] }, 'A head start: bananas, golden bananas, sneakers and a backpack. Once per player.', { once: true }),
  P('combo_party', 'deals', 'consumable', 2.99, 'Party Pack', { bananas: 1500, golden: 20 }, 'Bananas and golden bananas together.'),
  P('combo_mega', 'deals', 'consumable', 7.99, 'Mega Party Pack', { bananas: 5000, golden: 70 }, 'A big mix of both.'),

  // ---------------------------------------------------------------- bananas
  P('bananas_500', 'bananas', 'consumable', 0.99, 'Handful of Bananas', { bananas: 500 }, '500 bananas.'),
  P('bananas_1200', 'bananas', 'consumable', 1.99, 'Bunch of Bananas', { bananas: 1200 }, '1,200 bananas.'),
  P('bananas_3500', 'bananas', 'consumable', 4.99, 'Banana Crate', { bananas: 3500 }, '3,500 bananas.'),
  P('bananas_8000', 'bananas', 'consumable', 9.99, 'Banana Truck', { bananas: 8000 }, '8,000 bananas.'),

  // ---------------------------------------------------------------- golden bananas
  P('golden_12', 'golden', 'consumable', 0.99, 'Pocket of Golden Bananas', { golden: 12 }, '12 golden bananas.'),
  P('golden_30', 'golden', 'consumable', 1.99, 'Pouch of Golden Bananas', { golden: 30 }, '30 golden bananas.'),
  P('golden_85', 'golden', 'consumable', 4.99, 'Chest of Golden Bananas', { golden: 85 }, '85 golden bananas.'),
  P('golden_190', 'golden', 'consumable', 9.99, 'Vault of Golden Bananas', { golden: 190 }, '190 golden bananas.'),

  // ---------------------------------------------------------------- themed bundles (skin + gear)
  P('bundle_space', 'bundles', 'nonconsumable', 2.99, 'Space Explorer', { skins: ['astronaut'], gear: ['hat:spacehelmet', 'feet:rocketboots', 'back:jetpack', 'aura:stars'] }, 'Astronaut skin, space helmet, rocket boots, jetpack and a star aura.'),
  P('bundle_pirate', 'bundles', 'nonconsumable', 2.99, 'Pirate Captain', { skins: ['pirate'], gear: ['hat:pirate', 'back:parrot', 'hands:spyglass', 'neck:bandana'] }, 'Pirate skin, pirate hat, parrot pal, spyglass and bandana.'),
  P('bundle_rock', 'bundles', 'nonconsumable', 2.99, 'Rock Legend', { skins: ['rockstar'], gear: ['back:guitar', 'eyes:aviators', 'hands:mic', 'aura:notes'] }, 'Rock Star skin, guitar, aviators, microphone and a music-note aura.'),
  P('bundle_royal', 'bundles', 'nonconsumable', 2.99, 'Royal Court', { skins: ['royal'], gear: ['hat:crown', 'neck:pearls', 'hands:scepter', 'back:cape'] }, 'Royal skin, crown, pearls, scepter and hero cape.'),
  P('bundle_beach', 'bundles', 'nonconsumable', 2.99, 'Beach Day', { skins: ['ocean'], gear: ['eyes:hippie', 'neck:lei', 'feet:flippers', 'aura:bubbles'] }, 'Ocean skin, round shades, flower lei, flippers and a bubble aura.'),
  P('bundle_spooky', 'bundles', 'nonconsumable', 2.99, 'Spooky Night', { skins: ['vampire'], gear: ['back:batwings', 'hands:candy', 'hat:wizard', 'aura:embers'] }, 'Vampire skin, bat wings, candy bucket, wizard hat and an ember aura.'),
  P('bundle_party', 'bundles', 'nonconsumable', 2.99, 'Party Animal', { skins: ['popstar'], gear: ['hat:party', 'hands:glowsticks', 'eyes:stars', 'aura:confetti'] }, 'Pop Star skin, party hat, glow sticks, star glasses and a confetti aura.'),

  // ---------------------------------------------------------------- premium skin sets
  P('set_metals', 'sets', 'nonconsumable', 4.99, 'Precious Metals set', { skins: ['bronze', 'silver', 'rosegold', 'chrome', 'gold'] }, 'All 5 Precious Metals skins.'),
  P('set_cosmic', 'sets', 'nonconsumable', 4.99, 'Cosmic set', { skins: ['galaxy', 'nebula', 'moonbeam', 'sunburst', 'alien', 'astronaut'] }, 'All 6 Cosmic skins.'),
  P('set_elements', 'sets', 'nonconsumable', 4.99, 'Elements set', { skins: ['lava', 'frost', 'storm', 'ocean', 'forest', 'crystal'] }, 'All 6 Elements skins.'),
  P('set_mythic', 'sets', 'nonconsumable', 4.99, 'Mythic set', { skins: ['dragon', 'phoenix', 'unicorn', 'angel', 'imp', 'mermonkey', 'fairy'] }, 'All 7 Mythic skins.'),
  P('set_spooky', 'sets', 'nonconsumable', 4.99, 'Spooky set', { skins: ['ghost', 'skeleton', 'vampire', 'zombie', 'pumpkin', 'shadow'] }, 'All 6 Spooky skins.'),
  P('set_tech', 'sets', 'nonconsumable', 4.99, 'Tech set', { skins: ['robot', 'neon', 'pixel', 'hologram', 'mecha', 'glitch'] }, 'All 6 Tech skins.'),
  P('set_party', 'sets', 'nonconsumable', 4.99, 'Party & Music set', { skins: ['disco', 'dj', 'rockstar', 'popstar', 'jazz', 'superstar', 'goldrecord'] }, 'All 7 Party & Music skins.'),
  P('set_heroes', 'sets', 'nonconsumable', 4.99, 'Heroes set', { skins: ['superhero', 'ninja', 'knight', 'pirate', 'wizard', 'samurai', 'royal'] }, 'All 7 Heroes skins.'),
];

export const GROUPS = [
  { id: 'deals', name: 'Deals' },
  { id: 'bundles', name: 'Themed bundles' },
  { id: 'bananas', name: 'Bananas' },
  { id: 'golden', name: 'Golden bananas' },
  { id: 'sets', name: 'Premium skin sets' },
];

/** For items you already own in a bundle or set, you get this many golden bananas instead. */
export const OWNED_REFUND_GOLDEN = 5;

export const SPEND_LIMITS = [0, 5, 10, 20, 50]; // 0 = no limit (local currency units per calendar month)

export function getProduct(id) {
  return PRODUCTS.find((p) => p.id === id) || null;
}

export function productsIn(group) {
  return PRODUCTS.filter((p) => p.group === group);
}

/** Honest "+N% more" against the smallest pack of the same kind. */
export function bonusPercent(p) {
  const kind = p.group === 'bananas' ? 'bananas' : p.group === 'golden' ? 'golden' : null;
  if (!kind) return 0;
  const base = PRODUCTS.filter((x) => x.group === p.group).sort((a, b) => a.usd - b.usd)[0];
  const rate = (x) => x.grants[kind] / x.usd;
  return Math.round((rate(p) / rate(base) - 1) * 100);
}

/** The pack with the most per dollar in its group (the only one labelled Best value). */
export function bestValueId(group) {
  const list = PRODUCTS.filter((p) => p.group === group && (group === 'bananas' || group === 'golden'));
  if (!list.length) return null;
  return list.reduce((a, b) => (bonusPercent(b) > bonusPercent(a) ? b : a)).id;
}

/** What buying the same things separately would cost in game currency. */
export function separateValue(p, skinPrice, itemPrice) {
  let golden = 0;
  let bananas = 0;
  for (const id of p.grants.skins) golden += skinPrice(id).golden;
  for (const g of p.grants.gear) {
    const v = itemPrice(g);
    golden += v.golden;
    bananas += v.bananas;
  }
  return { golden, bananas };
}

/** Money spent in the current calendar month, per currency, from the purchase log. */
export function spentThisMonth(purchases, now = new Date()) {
  const out = {};
  for (const p of purchases || []) {
    const d = new Date(p.t);
    if (d.getFullYear() !== now.getFullYear() || d.getMonth() !== now.getMonth()) continue;
    const cur = p.currency || 'USD';
    out[cur] = (out[cur] || 0) + (p.micros || 0) / 1e6;
  }
  return out;
}
