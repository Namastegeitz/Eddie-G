// The Wardrobe: everything bananas can buy. No real money anywhere in the game.
// `unlock` items can also be earned for free by reaching a world.

export const CATEGORIES = [
  { id: 'fur', name: 'Fur' },
  { id: 'hat', name: 'Hats' },
  { id: 'eyes', name: 'Glasses' },
  { id: 'neck', name: 'Neck' },
  { id: 'flair', name: 'Flair move' },
  { id: 'stage', name: 'Stages' },
];

export const ITEMS = [
  // Fur colours: fur, skin (face, hands, feet, belly), and the darker detail colour
  { id: 'cocoa', cat: 'fur', name: 'Cocoa', price: 0, fur: '#8a5230', skin: '#f3c9a0', dark: '#4a2a17', desc: 'The classic.' },
  { id: 'golden', cat: 'fur', name: 'Golden', price: 60, fur: '#d99a2b', skin: '#ffe2b5', dark: '#7a4e0c', desc: 'Shines under the lights.' },
  { id: 'snowy', cat: 'fur', name: 'Snowy', price: 80, fur: '#e8eef3', skin: '#ffd2cf', dark: '#8796a3', desc: 'A mountain monkey on holiday.' },
  { id: 'midnight', cat: 'fur', name: 'Midnight', price: 100, fur: '#2e3047', skin: '#d6c2ae', dark: '#14152a', desc: 'Cool and mysterious.' },
  { id: 'bubblegum', cat: 'fur', name: 'Bubblegum', price: 120, fur: '#ff8fc6', skin: '#ffe3f0', dark: '#b8467f', desc: 'Pop!' },
  { id: 'mossy', cat: 'fur', name: 'Mossy', price: 120, fur: '#5f9140', skin: '#efe6b8', dark: '#2f4e1d', desc: 'Blends in with the trees.' },
  { id: 'rainbow', cat: 'fur', name: 'Rainbow', price: 300, fur: '#ff5a5a', skin: '#fff1d6', dark: '#552222', rainbow: true, desc: 'Fur that slowly cycles through every colour.' },

  { id: 'none', cat: 'hat', name: 'No hat', price: 0, desc: 'Just fur.' },
  { id: 'party', cat: 'hat', name: 'Party Hat', price: 40, desc: 'Every day is a party.' },
  { id: 'flower', cat: 'hat', name: 'Flower Crown', price: 60, desc: 'Fresh from the jungle.' },
  { id: 'propeller', cat: 'hat', name: 'Propeller Cap', price: 80, desc: 'Spins when you dance.' },
  { id: 'headphones', cat: 'hat', name: 'Headphones', price: 90, desc: 'Hear the beat better (it says here).' },
  { id: 'tophat', cat: 'hat', name: 'Top Hat', price: 100, desc: 'Very fancy footwork.' },
  { id: 'crown', cat: 'hat', name: 'Crown', price: 250, desc: 'King or queen of the dance floor.' },

  { id: 'none', cat: 'eyes', name: 'No glasses', price: 0, desc: 'Big eyes, no frames.' },
  { id: 'round', cat: 'eyes', name: 'Round Specs', price: 40, desc: 'For studying routines.' },
  { id: 'shades', cat: 'eyes', name: 'Shades', price: 50, desc: 'Too cool.' },
  { id: 'stars', cat: 'eyes', name: 'Star Glasses', price: 80, desc: 'Superstar status.' },

  { id: 'none', cat: 'neck', name: 'Nothing', price: 0, desc: 'Keep it simple.' },
  { id: 'bowtie', cat: 'neck', name: 'Bow Tie', price: 30, desc: 'Dressed for the show.' },
  { id: 'scarf', cat: 'neck', name: 'Scarf', price: 50, desc: 'Flaps when you jump.' },
  { id: 'lei', cat: 'neck', name: 'Flower Lei', price: 70, desc: 'Beach vibes.' },
  { id: 'chain', cat: 'neck', name: 'Banana Chain', price: 120, desc: 'A gold chain with a gold banana.' },

  { id: 'wiggle', cat: 'flair', name: 'Hip Wiggle', price: 0, desc: 'The Flair move wiggles the hips.' },
  { id: 'shimmy', cat: 'flair', name: 'Shoulder Shimmy', price: 80, desc: 'The Flair move shakes the shoulders.' },
  { id: 'spin', cat: 'flair', name: 'Spin', price: 100, desc: 'The Flair move is a full spin.' },
  { id: 'robot', cat: 'flair', name: 'Robot', price: 120, desc: 'The Flair move goes beep-boop.' },

  { id: 'jungle', cat: 'stage', name: 'Jungle Clearing', price: 0, desc: 'Home sweet home.' },
  { id: 'beach', cat: 'stage', name: 'Beach Bash', price: 150, unlockWorld: 2, desc: 'Free when you reach World 2.' },
  { id: 'disco', cat: 'stage', name: 'Temple Disco', price: 250, unlockWorld: 3, desc: 'Free when you reach World 3.' },
  { id: 'moon', cat: 'stage', name: 'Moon Party', price: 300, desc: 'Low gravity, high energy.' },
];

export function itemsIn(cat) {
  return ITEMS.filter((i) => i.cat === cat);
}

export function getItem(cat, id) {
  return ITEMS.find((i) => i.cat === cat && i.id === id) || null;
}

/** Changing flair changes what the Flair move looks like everywhere. */
export const DEFAULT_OWNED = { fur: ['cocoa'], hat: ['none'], eyes: ['none'], neck: ['none'], flair: ['wiggle'], stage: ['jungle'] };
export const DEFAULT_EQUIPPED = { fur: 'cocoa', hat: 'none', eyes: 'none', neck: 'none', flair: 'wiggle', stage: 'auto' };
