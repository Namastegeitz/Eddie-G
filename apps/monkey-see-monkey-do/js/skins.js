// 100 monkey skins: 50 standard (bought with bananas) and 50 premium.
// Every premium skin unlocks two ways:
//   - for free, by reaching its play goal (shown on its card with progress), or
//   - early, with Golden Bananas (earned by playing; see GOLDEN in rules.js).
// Skins are looks only: no skin changes timing, scoring or difficulty.
// Pure data + pure functions (tests/unit.mjs checks it in Node).

export const RARITY = {
  common: { name: 'Common', color: '#4a8a6a' },
  rare: { name: 'Rare', color: '#2e7bd6' },
  epic: { name: 'Epic', color: '#8a4ae0' },
  legendary: { name: 'Legendary', color: '#e0a400' },
};

// ---------------------------------------------------------------- play goals
// value(ctx) reads the player's progress; see goalContext() below.
const G = (text, need, value) => ({ text, need, value });
export const GOALS = {
  stars15: G('Earn 15 stars', 15, (c) => c.stars),
  stars30: G('Earn 30 stars', 30, (c) => c.stars),
  stars45: G('Earn 45 stars', 45, (c) => c.stars),
  stars60: G('Earn 60 stars', 60, (c) => c.stars),
  stars75: G('Earn 75 stars', 75, (c) => c.stars),
  stars90: G('Earn all 90 stars', 90, (c) => c.stars),
  world1: G('Clear World 1 (level 10)', 1, (c) => (c.cleared(10) ? 1 : 0)),
  world2: G('Clear World 2 (level 20)', 1, (c) => (c.cleared(20) ? 1 : 0)),
  world3: G('Clear World 3 (level 30)', 1, (c) => (c.cleared(30) ? 1 : 0)),
  boss10: G('3 stars on level 10', 3, (c) => c.levelStars(10)),
  boss20: G('3 stars on level 20', 3, (c) => c.levelStars(20)),
  boss30: G('3 stars on level 30', 3, (c) => c.levelStars(30)),
  allstars1: G('3 stars on every World 1 level', 30, (c) => c.worldStars(1)),
  allstars2: G('3 stars on every World 2 level', 30, (c) => c.worldStars(2)),
  allstars3: G('3 stars on every World 3 level', 30, (c) => c.worldStars(3)),
  endless5: G('Clear 5 rounds in one Endless run', 5, (c) => c.endlessBest),
  endless10: G('Clear 10 rounds in one Endless run', 10, (c) => c.endlessBest),
  endless15: G('Clear 15 rounds in one Endless run', 15, (c) => c.endlessBest),
  endless20: G('Clear 20 rounds in one Endless run', 20, (c) => c.endlessBest),
  endless25: G('Clear 25 rounds in one Endless run', 25, (c) => c.endlessBest),
  endless30: G('Clear 30 rounds in one Endless run', 30, (c) => c.endlessBest),
  endless40: G('Clear 40 rounds in one Endless run', 40, (c) => c.endlessBest),
  endless50: G('Clear 50 rounds in one Endless run', 50, (c) => c.endlessBest),
  perfect50: G('Tap 50 Perfect moves', 50, (c) => c.perfects),
  perfect200: G('Tap 200 Perfect moves', 200, (c) => c.perfects),
  perfect500: G('Tap 500 Perfect moves', 500, (c) => c.perfects),
  perfect1000: G('Tap 1,000 Perfect moves', 1000, (c) => c.perfects),
  perfect2500: G('Tap 2,500 Perfect moves', 2500, (c) => c.perfects),
  streak15: G('Get a 15-move streak', 15, (c) => c.bestStreak),
  streak25: G('Get a 25-move streak', 25, (c) => c.bestStreak),
  streak40: G('Get a 40-move streak', 40, (c) => c.bestStreak),
  streak60: G('Get a 60-move streak', 60, (c) => c.bestStreak),
  streak100: G('Get a 100-move streak', 100, (c) => c.bestStreak),
  rounds50: G('Clear 50 rounds (any mode)', 50, (c) => c.rounds),
  rounds150: G('Clear 150 rounds (any mode)', 150, (c) => c.rounds),
  rounds300: G('Clear 300 rounds (any mode)', 300, (c) => c.rounds),
  rounds600: G('Clear 600 rounds (any mode)', 600, (c) => c.rounds),
  flawless5: G('Clear 5 levels without losing a life', 5, (c) => c.flawless),
  flawless15: G('Clear 15 levels without losing a life', 15, (c) => c.flawless),
  flawless30: G('Clear 30 levels without losing a life', 30, (c) => c.flawless),
  combos50: G('Hit 50 combos', 50, (c) => c.combos),
  combos200: G('Hit 200 combos', 200, (c) => c.combos),
  reverse10: G('Clear 10 backwards rounds', 10, (c) => c.reverseRounds),
  speedup10: G('Clear 10 speed-up rounds', 10, (c) => c.speedupRounds),
  free500: G('Do 500 moves in Free Dance', 500, (c) => c.freeMoves),
  days3: G('Play on 3 different days', 3, (c) => c.days),
  days7: G('Play on 7 different days', 7, (c) => c.days),
  days14: G('Play on 14 different days', 14, (c) => c.days),
  days30: G('Play on 30 different days', 30, (c) => c.days),
  skins25: G('Own 25 skins', 25, (c) => c.skinsOwned),
};

// ---------------------------------------------------------------- the catalogue
// look: fur, skin (face/hands/feet/belly), dark (brows), pattern [type, colours..., density],
// finish (toon | metal | glow | ghost), eyes { white, pupil, glow }, extras, aura.
const pat = (type, ...rest) => {
  const n = typeof rest[rest.length - 1] === 'number' ? rest.pop() : 0;
  return { type, c: rest, n };
};

function std(set, list) {
  return list.map(([id, name, rarity, price, look]) => ({
    id, name, set, tier: 'standard', rarity, price, currency: 'banana', dark: '#3a2010', eyes: {}, extras: [], ...look,
  }));
}

function prem(set, list) {
  return list.map(([id, name, rarity, price, goal, look]) => ({
    id, name, set, tier: 'premium', rarity, price, currency: 'golden', goal, dark: '#2a1608', eyes: {}, extras: [], ...look,
  }));
}

export const SETS = [
  { id: 'classic', name: 'Classic Fur', tier: 'standard' },
  { id: 'fruit', name: 'Fruit Stand', tier: 'standard' },
  { id: 'wild', name: 'Wild Things', tier: 'standard' },
  { id: 'pop', name: 'Pop Art', tier: 'standard' },
  { id: 'candy', name: 'Candy Shop', tier: 'standard' },
  { id: 'metals', name: 'Precious Metals', tier: 'premium' },
  { id: 'cosmic', name: 'Cosmic', tier: 'premium' },
  { id: 'elements', name: 'Elements', tier: 'premium' },
  { id: 'mythic', name: 'Mythic', tier: 'premium' },
  { id: 'spooky', name: 'Spooky', tier: 'premium' },
  { id: 'tech', name: 'Tech', tier: 'premium' },
  { id: 'party', name: 'Party & Music', tier: 'premium' },
  { id: 'heroes', name: 'Heroes', tier: 'premium' },
];

export const SKINS = [
  // ===================================================== STANDARD (50)
  ...std('classic', [
    ['cocoa', 'Cocoa', 'common', 0, { fur: '#8a5230', skin: '#f3c9a0', dark: '#4a2a17', desc: 'The classic.' }],
    ['golden', 'Honey', 'common', 60, { fur: '#d99a2b', skin: '#ffe2b5', dark: '#7a4e0c', desc: 'Warm as a summer afternoon.' }],
    ['snowy', 'Snowy', 'common', 80, { fur: '#e8eef3', skin: '#ffd2cf', dark: '#8796a3', desc: 'A mountain monkey on holiday.' }],
    ['midnight', 'Midnight', 'rare', 100, { fur: '#2e3047', skin: '#d6c2ae', dark: '#14152a', desc: 'Cool and mysterious.' }],
    ['bubblegum', 'Bubblegum', 'common', 120, { fur: '#ff8fc6', skin: '#ffe3f0', dark: '#b8467f', desc: 'Pop!' }],
    ['mossy', 'Mossy', 'common', 120, { fur: '#5f9140', skin: '#efe6b8', dark: '#2f4e1d', desc: 'Blends in with the trees.' }],
    ['ginger', 'Ginger', 'common', 70, { fur: '#c8641e', skin: '#ffd9b0', dark: '#6a2e0a', desc: 'Bright and spicy.' }],
    ['ash', 'Ash Grey', 'common', 70, { fur: '#8d8f96', skin: '#e9e3dc', dark: '#3d3f45', desc: 'Calm, cool, collected.' }],
    ['chestnut', 'Chestnut', 'common', 80, { fur: '#6b3420', skin: '#e8b98e', dark: '#3a1a0e', desc: 'Deep and glossy.' }],
    ['charcoal', 'Charcoal', 'rare', 150, { fur: '#33302e', skin: '#c9a98c', dark: '#111111', desc: 'Smoky and sharp.' }],
  ]),
  ...std('fruit', [
    ['banana', 'Banana Split', 'common', 90, { fur: '#ffd23f', skin: '#fff3c4', pattern: pat('specks', '#ffd23f', '#8a6a1a', 90), desc: 'Ripe, with the right number of spots.' }],
    ['strawberry', 'Strawberry', 'rare', 160, { fur: '#e8333f', skin: '#ffd6d6', pattern: pat('seeds', '#e8333f', '#ffe27a'), desc: 'Sweet, with seeds.' }],
    ['blueberry', 'Blueberry', 'common', 100, { fur: '#4a5bd6', skin: '#e0e4ff', pattern: pat('glitter', '#4a5bd6', '#7f8fff'), desc: 'Fresh from the bush.' }],
    ['lime', 'Lime', 'common', 100, { fur: '#8bd13a', skin: '#f3ffd8', pattern: pat('stripes', '#8bd13a', '#a6e35a', 6), desc: 'Zesty.' }],
    ['grape', 'Grape', 'common', 100, { fur: '#7b3fb8', skin: '#efe0ff', pattern: pat('spots', '#7b3fb8', '#9a62d6', 7), desc: 'A whole bunch of fun.' }],
    ['orangezest', 'Orange Zest', 'common', 100, { fur: '#ff8a1f', skin: '#fff0dc', pattern: pat('specks', '#ff8a1f', '#ffb066', 160), desc: 'Squeeze the day.' }],
    ['watermelon', 'Watermelon', 'rare', 180, { fur: '#2fa34a', skin: '#ff8a98', pattern: pat('vstripes', '#2fa34a', '#1d7a33', 12), desc: 'Green outside, pink inside.' }],
    ['peach', 'Peach', 'common', 90, { fur: '#ffb08a', skin: '#fff0e6', pattern: pat('gradient', '#ffcfa8', '#ff8a6a'), desc: 'Soft and fuzzy.' }],
  ]),
  ...std('wild', [
    ['tiger', 'Tiger', 'rare', 200, { fur: '#f28a1f', skin: '#fff4e0', pattern: pat('tiger', '#f28a1f', '#2a1608'), desc: 'Roar, but make it dance.' }],
    ['zebra', 'Zebra', 'rare', 200, { fur: '#f4f4f4', skin: '#e8e0d8', dark: '#111', pattern: pat('zebra', '#f4f4f4', '#1a1a1a'), desc: 'Black and white and groovy all over.' }],
    ['leopard', 'Leopard', 'rare', 220, { fur: '#e8b04a', skin: '#fff2d8', pattern: pat('leopard', '#e8b04a', '#3a2410', '#c08030'), desc: 'Spotted on the dance floor.' }],
    ['cheetah', 'Cheetah', 'common', 150, { fur: '#e8b84a', skin: '#fff4dc', pattern: pat('dots', '#e8b84a', '#2a1a0a', 60), desc: 'Fastest feet in the jungle.' }],
    ['giraffe', 'Giraffe', 'rare', 200, { fur: '#f4e4c0', skin: '#fff6e4', pattern: pat('giraffe', '#f4e4c0', '#c0702a'), desc: 'Head and shoulders above.' }],
    ['panda', 'Panda', 'rare', 220, { fur: '#f4f4f4', skin: '#ffffff', dark: '#111', pattern: pat('patches', '#f4f4f4', '#1a1a1a', 6), extras: ['mask:#1a1a1a'], desc: 'Bamboo optional.' }],
    ['dalmatian', 'Dalmatian', 'common', 150, { fur: '#f8f8f8', skin: '#ffe4e4', dark: '#111', pattern: pat('dots', '#f8f8f8', '#1a1a1a', 34), desc: '101 moves.' }],
    ['cow', 'Moo Cow', 'common', 140, { fur: '#f8f8f8', skin: '#ffc0c8', dark: '#222', pattern: pat('patches', '#f8f8f8', '#2a2a2a', 8), desc: 'Udderly groovy.' }],
    ['camo', 'Jungle Camo', 'rare', 180, { fur: '#5a7a3a', skin: '#d8d0a8', pattern: pat('camo', '#5a7a3a', '#3a4a20', '#8a9a5a', '#2a2a18'), desc: 'Now you see me...' }],
    ['snowleopard', 'Snow Leopard', 'rare', 240, { fur: '#e8e8ee', skin: '#f4f0f0', dark: '#4a4a55', pattern: pat('leopard', '#e8e8ee', '#4a4a55', '#a0a0ac'), desc: 'Cool cat, warm heart.' }],
    ['redpanda', 'Red Panda', 'rare', 220, { fur: '#c4521e', skin: '#fff2e8', dark: '#3a1205', pattern: pat('stripes', '#c4521e', '#7a2a0a', 10), desc: 'Ringed tail, big smile.' }],
    ['raccoon', 'Raccoon', 'common', 160, { fur: '#8a8a90', skin: '#e8e4e0', dark: '#222', pattern: pat('stripes', '#8a8a90', '#4a4a50', 10), extras: ['mask:#2a2a2e'], desc: 'Masked bandit of the beat.' }],
  ]),
  ...std('pop', [
    ['polka', 'Polka Dot', 'common', 100, { fur: '#ff4f9a', skin: '#ffe3f0', pattern: pat('spots', '#ff4f9a', '#ffffff', 6), desc: 'Dotty about dancing.' }],
    ['beachstripes', 'Beach Stripes', 'common', 100, { fur: '#2e8bff', skin: '#fff0dc', pattern: pat('stripes', '#2e8bff', '#ffffff', 10), desc: 'Ready for the boardwalk.' }],
    ['checkers', 'Checkers', 'common', 120, { fur: '#1a1a1a', skin: '#f4e8d8', dark: '#000', pattern: pat('checker', '#1a1a1a', '#f4f4f4', 8), desc: 'Your move.' }],
    ['zigzag', 'Zigzag', 'common', 120, { fur: '#ffd23f', skin: '#fff6dc', pattern: pat('zigzag', '#ffd23f', '#ff4f9a', 7), desc: 'Zig, zag, zig.' }],
    ['plaid', 'Plaid', 'rare', 160, { fur: '#c8302a', skin: '#ffe8d8', pattern: pat('plaid', '#c8302a', '#1a3a6a', '#ffd23f', 4), desc: 'Cosy and cool.' }],
    ['argyle', 'Argyle', 'rare', 160, { fur: '#2e5a8a', skin: '#ffecd8', pattern: pat('argyle', '#2e5a8a', '#e8c040', '#ffffff', 4), desc: 'Dressed for the golf course.' }],
    ['sweetheart', 'Sweetheart', 'common', 130, { fur: '#ffb3d0', skin: '#fff0f6', pattern: pat('hearts', '#ffb3d0', '#ff3b6a', '#ffffff', 5), desc: 'Love to dance.' }],
    ['starry', 'Starry', 'common', 130, { fur: '#1e2a6a', skin: '#e8ecff', pattern: pat('stars', '#1e2a6a', '#ffd23f', '#ffffff', 5), desc: 'A sky full of moves.' }],
    ['confettiparty', 'Confetti Party', 'rare', 170, { fur: '#ffffff', skin: '#fff4e0', pattern: pat('confetti', '#ffffff', '#ff4f9a', '#ffd23f', '#2e8bff', '#1fb57a', 150), desc: 'Every day is a party.' }],
    ['rainbow', 'Rainbow', 'rare', 300, { fur: '#ff5a5a', skin: '#fff1d6', dark: '#552222', rainbow: true, desc: 'Fur that slowly cycles through every colour.' }],
  ]),
  ...std('candy', [
    ['mintchip', 'Mint Chip', 'common', 110, { fur: '#9be8c8', skin: '#f0fff8', pattern: pat('specks', '#9be8c8', '#3a2416', 120), desc: 'Two scoops, please.' }],
    ['cottoncandy', 'Cotton Candy', 'rare', 170, { fur: '#ffb3e0', skin: '#fff6fb', pattern: pat('gradient', '#ffb3e0', '#9fd8ff'), desc: 'Light, fluffy, sweet.' }],
    ['licorice', 'Licorice', 'common', 110, { fur: '#1a1a1a', skin: '#e8d8d0', dark: '#000', pattern: pat('swirl', '#1a1a1a', '#3a3a3a', 8), desc: 'Twisty.' }],
    ['caramel', 'Caramel', 'common', 110, { fur: '#d9a050', skin: '#fff0d8', pattern: pat('swirl', '#d9a050', '#b87830', 8), desc: 'Smooth moves.' }],
    ['sprinkles', 'Sprinkle Donut', 'rare', 180, { fur: '#ff9fcc', skin: '#e8b070', pattern: pat('sprinkles', '#ff9fcc', '#ffffff', '#ffd23f', '#2e8bff', '#1fb57a', 160), desc: 'Glazed and amazed.' }],
    ['lollipop', 'Lollipop', 'rare', 180, { fur: '#ff3b5c', skin: '#fff0f2', pattern: pat('swirl', '#ff3b5c', '#ffffff', 10), desc: 'Swirly and sticky.' }],
    ['chocolate', 'Chocolate', 'common', 90, { fur: '#5a2e18', skin: '#c88a5a', dark: '#2a1208', desc: 'Rich and smooth.' }],
    ['vanilla', 'Vanilla', 'common', 90, { fur: '#fff3d6', skin: '#ffe0b8', dark: '#a08060', desc: 'A classic for a reason.' }],
    ['gumdrop', 'Gumdrop', 'common', 120, { fur: '#3fd08a', skin: '#e8fff2', pattern: pat('glitter', '#3fd08a', '#bff5d8'), desc: 'Sugar-coated.' }],
    ['blueraspberry', 'Blue Raspberry', 'common', 120, { fur: '#2ec4e8', skin: '#e8fbff', pattern: pat('glitter', '#2ec4e8', '#a8f0ff'), desc: 'A flavour no fruit has.' }],
  ]),

  // ===================================================== PREMIUM (50)
  ...prem('metals', [
    ['bronze', 'Bronze', 'epic', 25, 'stars15', { fur: '#c07a3a', skin: '#f0d0b0', finish: 'metal', desc: 'Your first medal.' }],
    ['silver', 'Silver', 'epic', 30, 'stars45', { fur: '#d0d6e0', skin: '#f4f0ee', finish: 'metal', desc: 'Shiny and sharp.' }],
    ['rosegold', 'Rose Gold', 'epic', 35, 'stars60', { fur: '#f0a8a0', skin: '#fff0ec', finish: 'metal', desc: 'Pink and precious.' }],
    ['chrome', 'Chrome', 'legendary', 50, 'stars75', { fur: '#e2ecff', skin: '#f8f8ff', finish: 'metal', aura: 'sparkle', auraColor: '#ffffff', desc: 'Mirror-polished. Sparkles as it moves.' }],
    ['gold', 'Solid Gold', 'legendary', 60, 'stars90', { fur: '#ffc928', skin: '#fff4cc', finish: 'metal', aura: 'sparkle', auraColor: '#ffe680', desc: 'For the monkey with every star.' }],
  ]),
  ...prem('cosmic', [
    ['galaxy', 'Galaxy', 'legendary', 55, 'endless30', { fur: '#120a30', skin: '#d8c8ff', pattern: pat('galaxy', '#120a30', '#7a3fff', '#ff4fd8', '#ffe9a8', 110), eyes: { pupil: '#b07cff', glow: true }, aura: 'stars', auraColor: '#ffe9a8', desc: 'A universe of moves. Glows in the dark.' }],
    ['nebula', 'Nebula', 'epic', 30, 'endless15', { fur: '#0a1a3a', skin: '#c8e8ff', pattern: pat('galaxy', '#0a1a3a', '#2ec4e8', '#9b5cff', '#ffffff', 80), desc: 'Swirling star clouds.' }],
    ['moonbeam', 'Moonbeam', 'epic', 35, 'endless20', { fur: '#e4e6ff', skin: '#ffffff', finish: 'metal', extras: ['halo'], aura: 'sparkle', auraColor: '#dfe6ff', desc: 'Soft silver light.' }],
    ['sunburst', 'Sunburst', 'epic', 35, 'endless25', { fur: '#ffb020', skin: '#fff4d8', pattern: pat('gradient', '#ffe060', '#ff6a00'), finish: 'glow', glowColor: '#ff9a20', aura: 'embers', auraColor: '#ffb020', desc: 'Hot moves, warm glow.' }],
    ['alien', 'Little Alien', 'epic', 30, 'skins25', { fur: '#7be05a', skin: '#c8ff9a', dark: '#2a6a1a', eyes: { white: '#101810', pupil: '#7bff5a', glow: true }, extras: ['antenna:#7bff5a'], desc: 'Came in peace, stayed for the dancing.' }],
    ['astronaut', 'Astronaut', 'legendary', 50, 'endless40', { fur: '#f4f4f8', skin: '#ffe0c8', dark: '#3a3a4a', pattern: pat('stripes', '#f4f4f8', '#e0e2ea', 12), extras: ['jetpack'], desc: 'Moonwalking, literally. With a working jetpack.' }],
  ]),
  ...prem('elements', [
    ['lava', 'Lava', 'legendary', 55, 'days30', { fur: '#2a1410', skin: '#ffcc99', pattern: pat('lava', '#2a1410', '#ff5a1a', '#4a2418'), eyes: { pupil: '#ff7a1a', glow: true }, aura: 'embers', auraColor: '#ff7a1a', desc: 'Rock with glowing cracks. Hot, hot, hot.' }],
    ['frost', 'Frost', 'epic', 30, 'speedup10', { fur: '#bfe8ff', skin: '#f0fbff', dark: '#4a8ab0', pattern: pat('glitter', '#bfe8ff', '#ffffff', '#8fd0ff', 300), aura: 'snow', auraColor: '#ffffff', desc: 'Cool under pressure.' }],
    ['storm', 'Storm', 'epic', 35, 'combos200', { fur: '#2a3450', skin: '#d8e0f0', pattern: pat('lightning', '#2a3450', '#9fd8ff'), eyes: { pupil: '#9fd8ff', glow: true }, desc: 'Lightning in every limb.' }],
    ['ocean', 'Ocean', 'epic', 30, 'allstars2', { fur: '#1e7ab8', skin: '#e0f4ff', pattern: pat('waves', '#1e7ab8', '#4fc0e8', '#ffffff'), extras: ['fin:#1e7ab8'], aura: 'bubbles', auraColor: '#bfefff', desc: 'Deep blue grooves.' }],
    ['forest', 'Forest Spirit', 'epic', 30, 'world1', { fur: '#3a8a3a', skin: '#e8f4c8', pattern: pat('leaves', '#3a8a3a', '#7ad05a', '#2a6a2a', 6), eyes: { pupil: '#2f6a1a' }, aura: 'leaves', auraColor: '#7ad05a', desc: 'The jungle dances with you.' }],
    ['crystal', 'Crystal', 'legendary', 50, 'flawless15', { fur: '#c79bff', skin: '#f6eeff', finish: 'metal', aura: 'sparkle', auraColor: '#e6d0ff', desc: 'Clear, bright and flawless.' }],
  ]),
  ...prem('mythic', [
    ['dragon', 'Dragon', 'legendary', 60, 'streak100', { fur: '#2a8a4a', skin: '#e8f0b0', dark: '#123a1a', pattern: pat('scales', '#2a8a4a', '#123a1a', '#3aa85a', 10), eyes: { pupil: '#ffb020', glow: true }, extras: ['wings:dragon:#1a5a2a', 'horns:#f4e4c0', 'tailtip:arrow:#1a5a2a'], desc: 'Scales, wings and horns. Earned by the longest streak.' }],
    ['phoenix', 'Phoenix', 'legendary', 60, 'endless50', { fur: '#ff7a1a', skin: '#fff0c8', pattern: pat('flames', '#ffe060', '#ff7a1a', '#d8201a'), finish: 'glow', glowColor: '#ff6a1a', extras: ['wings:phoenix', 'tailtip:flame'], aura: 'embers', auraColor: '#ffb020', desc: 'Rises from every mistake.' }],
    ['unicorn', 'Unicorn', 'legendary', 55, 'flawless30', { fur: '#fbf6ff', skin: '#ffe6f4', dark: '#b07cff', eyes: { pupil: '#8a4ae0' }, extras: ['unihorn', 'mane'], aura: 'sparkle', auraColor: '#ffb3e6', desc: 'Pure magic, flawless moves.' }],
    ['angel', 'Angel', 'epic', 40, 'flawless5', { fur: '#fffaf0', skin: '#ffe8d0', dark: '#c8a060', extras: ['wings:angel', 'halo'], desc: 'Heavenly footwork.' }],
    ['imp', 'Little Imp', 'epic', 35, 'combos50', { fur: '#d8302a', skin: '#ffb0a0', dark: '#5a0a0a', eyes: { pupil: '#ffd23f', glow: true }, extras: ['horns:#3a0a0a', 'tailtip:arrow:#d8302a'], desc: 'Mischief in motion.' }],
    ['mermonkey', 'Mer-Monkey', 'epic', 35, 'world2', { fur: '#1ec8b8', skin: '#e8fff8', pattern: pat('scales', '#1ec8b8', '#128a80', '#8af0e0', 10), extras: ['fin:#128a80', 'tailtip:fin:#128a80'], aura: 'bubbles', auraColor: '#bfefff', desc: 'Half monkey, half fish, all rhythm.' }],
    ['fairy', 'Fairy', 'epic', 35, 'allstars1', { fur: '#ffd0f0', skin: '#fff4fb', pattern: pat('glitter', '#ffd0f0', '#ffffff', '#ffb3e6', 300), extras: ['wings:fairy'], aura: 'sparkle', auraColor: '#ffe6f8', desc: 'Light as air.' }],
  ]),
  ...prem('spooky', [
    ['ghost', 'Ghost', 'epic', 30, 'days3', { fur: '#e8f0ff', skin: '#ffffff', dark: '#6a7a9a', finish: 'ghost', eyes: { white: '#222233', pupil: '#9fd8ff', glow: true }, desc: 'See-through and spooky.' }],
    ['skeleton', 'Skeleton', 'epic', 35, 'days7', { fur: '#1a1a1e', skin: '#f4f4e8', dark: '#000', pattern: pat('bones', '#1a1a1e', '#f4f4e8', 5), eyes: { white: '#111', pupil: '#ff3b3b', glow: true }, desc: 'Bones that glow in the dark.' }],
    ['vampire', 'Vampire', 'legendary', 45, 'days14', { fur: '#2a1a2e', skin: '#f0e8f4', dark: '#000', eyes: { pupil: '#ff2a3a', glow: true }, extras: ['cape:#7a0a1a'], aura: 'smoke', auraColor: '#6a4a7a', desc: 'Dances only at night.' }],
    ['zombie', 'Zombie', 'epic', 25, 'endless5', { fur: '#7a9a5a', skin: '#b8d098', dark: '#2a3a1a', pattern: pat('patches', '#7a9a5a', '#5a7a3a', 9), extras: ['bolts'], desc: 'Shuffles to the beat.' }],
    ['pumpkin', 'Pumpkin', 'epic', 25, 'endless10', { fur: '#ff8a1f', skin: '#ffd88a', dark: '#3a1a0a', pattern: pat('vstripes', '#ff8a1f', '#e06a10', 14), eyes: { pupil: '#ffd23f', glow: true }, extras: ['tailtip:leaf'], desc: 'Carved for the dance floor.' }],
    ['shadow', 'Shadow', 'legendary', 50, 'reverse10', { fur: '#1a1424', skin: '#3a3048', dark: '#000', finish: 'glow', glowColor: '#5a3a8a', eyes: { white: '#1a1424', pupil: '#b07cff', glow: true }, aura: 'smoke', auraColor: '#5a3a8a', desc: 'Only the eyes give it away.' }],
  ]),
  ...prem('tech', [
    ['robot', 'Robo-Monkey', 'epic', 35, 'stars30', { fur: '#b8c0cc', skin: '#e8ecf2', dark: '#3a4250', finish: 'metal', eyes: { pupil: '#4fd8ff', glow: true }, extras: ['antenna:#ff3b3b', 'bolts'], desc: 'Beep boop, bust a move.' }],
    ['neon', 'Neon Cyber', 'legendary', 50, 'streak40', { fur: '#120a20', skin: '#2a2040', dark: '#ff2ad8', pattern: pat('circuit', '#120a20', '#ff2ad8', 26), eyes: { pupil: '#2ae8ff', glow: true }, aura: 'pixels', auraColor: '#2ae8ff', desc: 'Circuits that glow in the dark.' }],
    ['pixel', 'Pixel Monkey', 'epic', 30, 'streak15', { fur: '#3fd08a', skin: '#e8fff2', pattern: pat('pixels', '#3fd08a', '#2a9a5a', '#8af0b0', 10), desc: 'Retro, 8 bits at a time.' }],
    ['hologram', 'Hologram', 'legendary', 55, 'perfect2500', { fur: '#4fd8ff', skin: '#bff4ff', dark: '#1a6a8a', finish: 'ghost', pattern: pat('scanlines', '#4fd8ff', '#bff4ff', 40), eyes: { pupil: '#ffffff', glow: true }, aura: 'pixels', auraColor: '#4fd8ff', desc: 'A projection with perfect timing.' }],
    ['mecha', 'Mecha Gold', 'epic', 40, 'streak60', { fur: '#ffb020', skin: '#fff0c8', dark: '#5a3a0a', finish: 'metal', eyes: { pupil: '#ff3b3b', glow: true }, extras: ['jetpack'], desc: 'Armoured, boosted, unstoppable.' }],
    ['glitch', 'Glitch', 'epic', 30, 'streak25', { fur: '#ff2ad8', skin: '#f0e8ff', pattern: pat('pixels', '#ff2ad8', '#2ae8ff', '#1a1a2a', '#ffffff', 14), aura: 'pixels', auraColor: '#ff2ad8', desc: 'Something went wonderfully wrong.' }],
  ]),
  ...prem('party', [
    ['disco', 'Disco Fever', 'legendary', 50, 'world3', { fur: '#e0e0ff', skin: '#fff4ff', finish: 'metal', pattern: pat('checker', '#f4f4ff', '#c8c8e8', 14), aura: 'sparkle', auraColor: '#ffffff', desc: 'A walking mirror ball.' }],
    ['dj', 'DJ Spin', 'epic', 30, 'perfect500', { fur: '#1a1a2a', skin: '#e8e0f0', pattern: pat('stripes', '#1a1a2a', '#2ae8ff', 12), aura: 'notes', auraColor: '#2ae8ff', desc: 'Drops the beat, never the routine.' }],
    ['rockstar', 'Rock Star', 'epic', 35, 'rounds150', { fur: '#1a1a1a', skin: '#f3c9a0', dark: '#000', pattern: pat('lightning', '#1a1a1a', '#ffd23f'), desc: 'Turned up to eleven.' }],
    ['popstar', 'Pop Star', 'epic', 35, 'perfect50', { fur: '#ff4fd8', skin: '#ffe8fa', pattern: pat('glitter', '#ff4fd8', '#ffd0f4', '#ffffff', 340), aura: 'stars', auraColor: '#ffd0f4', desc: 'Sparkles on every beat.' }],
    ['jazz', 'Jazz Cat', 'epic', 30, 'perfect200', { fur: '#1e2a4a', skin: '#f0e0c8', pattern: pat('pinstripe', '#1e2a4a', '#c0c8e0', 14), aura: 'notes', auraColor: '#ffd23f', desc: 'Smooth, swinging, on time.' }],
    ['superstar', 'Superstar', 'legendary', 60, 'perfect1000', { fur: '#ffd23f', skin: '#fff8dc', pattern: pat('stars', '#ffd23f', '#ffffff', '#fff2a8', 5), finish: 'glow', glowColor: '#ffd23f', aura: 'stars', auraColor: '#fff2a8', desc: 'A thousand perfect moves. Shines bright.' }],
    ['goldrecord', 'Golden Record', 'epic', 40, 'free500', { fur: '#ffc928', skin: '#fff4cc', finish: 'metal', aura: 'notes', auraColor: '#ffe680', desc: 'Certified gold.' }],
  ]),
  ...prem('heroes', [
    ['superhero', 'Super Monkey', 'epic', 35, 'boss10', { fur: '#2e5ad8', skin: '#ffe0c8', extras: ['cape:#e0303f', 'mask:#e0303f'], desc: 'Saves the day, one move at a time.' }],
    ['ninja', 'Ninja', 'epic', 30, 'rounds50', { fur: '#1a1a22', skin: '#f3c9a0', dark: '#000', extras: ['mask:#c8302a'], desc: 'Silent, swift, precise.' }],
    ['knight', 'Knight', 'legendary', 45, 'rounds300', { fur: '#c8ccd4', skin: '#f3c9a0', finish: 'metal', extras: ['cape:#2e5ad8'], desc: 'Shining armour, noble moves.' }],
    ['pirate', 'Pirate', 'epic', 30, 'boss20', { fur: '#ffffff', skin: '#f3c9a0', pattern: pat('stripes', '#ffffff', '#c8302a', 10), extras: ['eyepatch'], desc: 'Arr, dance the plank.' }],
    ['wizard', 'Wizard', 'legendary', 50, 'rounds600', { fur: '#3a2a8a', skin: '#ffe8d8', pattern: pat('stars', '#3a2a8a', '#ffd23f', '#c8b8ff', 5), extras: ['cape:#2a1a6a'], aura: 'sparkle', auraColor: '#ffe680', desc: 'Casts spells with every step.' }],
    ['samurai', 'Samurai', 'epic', 35, 'boss30', { fur: '#b81a1a', skin: '#f3c9a0', pattern: pat('lacquer', '#b81a1a', '#ffd23f', '#8a1010', 6), desc: 'Disciplined, bold, exact.' }],
    ['royal', 'Royal', 'legendary', 60, 'allstars3', { fur: '#6a2a8a', skin: '#ffe8d8', pattern: pat('velvet', '#6a2a8a', '#8a3aaa', '#ffd23f'), extras: ['cape:#8a1a2a'], aura: 'sparkle', auraColor: '#ffd23f', desc: 'Every star in the Temple. Long live the king (or queen).' }],
  ]),
];

const BY_ID = new Map(SKINS.map((s) => [s.id, s]));
export function getSkin(id) {
  return BY_ID.get(id) || BY_ID.get('cocoa');
}
export function skinsInSet(setId) {
  return SKINS.filter((s) => s.set === setId);
}

// ---------------------------------------------------------------- progress

/** Everything the goals read, from save data. */
export function goalContext(d) {
  const lv = (id) => d.levels[id] || { stars: 0, clears: 0 };
  const st = d.stats || {};
  return {
    stars: Object.values(d.levels).reduce((s, l) => s + (l.stars || 0), 0),
    cleared: (id) => lv(id).clears > 0,
    levelStars: (id) => lv(id).stars || 0,
    worldStars: (w) => { let s = 0; for (let i = (w - 1) * 10 + 1; i <= w * 10; i++) s += lv(i).stars || 0; return s; },
    endlessBest: (d.endless && d.endless.bestRounds) || 0,
    perfects: st.perfects || 0,
    bestStreak: st.bestStreak || 0,
    rounds: st.roundsCleared || 0,
    flawless: st.flawless || 0,
    combos: st.combos || 0,
    reverseRounds: st.reverseRounds || 0,
    speedupRounds: st.speedupRounds || 0,
    freeMoves: st.freeMoves || 0,
    days: (st.days || []).length,
    skinsOwned: ((d.owned && d.owned.skin) || []).length,
  };
}

/** { have, need, done, text } for a premium skin's goal. */
export function goalProgress(skin, ctx) {
  const g = GOALS[skin.goal];
  if (!g) return null;
  const have = Math.min(g.need, g.value(ctx));
  return { have, need: g.need, done: have >= g.need, text: g.text };
}

/** Premium skins whose goal is reached but which aren't owned yet. */
export function newlyEarned(d) {
  const ctx = goalContext(d);
  const owned = new Set((d.owned && d.owned.skin) || []);
  return SKINS.filter((s) => s.tier === 'premium' && !owned.has(s.id) && goalProgress(s, ctx).done);
}

export function setProgress(setId, ownedList) {
  const all = skinsInSet(setId);
  const owned = new Set(ownedList);
  return { have: all.filter((s) => owned.has(s.id)).length, total: all.length };
}
