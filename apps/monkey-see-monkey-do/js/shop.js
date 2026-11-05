// The Wardrobe: gear for every part of the monkey, Flair moves and stages.
// Skins (fur looks) live in js/skins.js. Prices are in bananas, or in golden
// bananas for premium gear (currency: 'golden'). Stages tied to a world are
// free when you reach it. Looks never change difficulty or scores.

export const CATEGORIES = [
  { id: 'skin', name: 'Skins' },
  { id: 'outfits', name: 'Outfits' },
  { id: 'hat', name: 'Hats' },
  { id: 'eyes', name: 'Glasses' },
  { id: 'neck', name: 'Neck' },
  { id: 'back', name: 'Back' },
  { id: 'hands', name: 'Hands' },
  { id: 'feet', name: 'Feet' },
  { id: 'face', name: 'Face' },
  { id: 'aura', name: 'Auras' },
  { id: 'flair', name: 'Flair move' },
  { id: 'stage', name: 'Stages' },
];

// Slots the monkey wears (each holds one item; "none" is always owned)
export const GEAR_SLOTS = ['hat', 'eyes', 'neck', 'back', 'hands', 'feet', 'face', 'aura'];

const I = (cat, id, name, price, desc, extra = {}) => ({ cat, id, name, price, desc, currency: 'banana', ...extra });
const G = (cat, id, name, price, desc, extra = {}) => ({ cat, id, name, price, desc, currency: 'golden', premium: true, ...extra });

export const ITEMS = [
  // ---------------------------------------------------------------- hats
  I('hat', 'none', 'No hat', 0, 'Just fur.'),
  I('hat', 'party', 'Party Hat', 40, 'Every day is a party.'),
  I('hat', 'beanie', 'Bobble Beanie', 50, 'Warm ears, cool moves.'),
  I('hat', 'cap', 'Backwards Cap', 50, 'Street style.'),
  I('hat', 'flower', 'Flower Crown', 60, 'Fresh from the jungle.'),
  I('hat', 'beret', 'Beret', 60, 'Très chic.'),
  I('hat', 'chef', 'Chef Hat', 70, 'Cooking up a routine.'),
  I('hat', 'propeller', 'Propeller Cap', 80, 'Spins when you dance.'),
  I('hat', 'safari', 'Safari Hat', 80, 'Ready for an expedition.'),
  I('hat', 'santa', 'Santa Hat', 80, 'Ho ho ho-down.'),
  I('hat', 'headphones', 'Headphones', 90, 'Hear the beat better (it says here).'),
  I('hat', 'cowboy', 'Cowboy Hat', 90, 'Yee-haw on the dance floor.'),
  I('hat', 'bunny', 'Bunny Ears', 90, 'Hop to it.'),
  I('hat', 'catears', 'Cat Ears', 90, 'A monkey in disguise.'),
  I('hat', 'tophat', 'Top Hat', 100, 'Very fancy footwork.'),
  I('hat', 'grad', 'Graduation Cap', 100, 'Top of the dance class.'),
  I('hat', 'pirate', 'Pirate Hat', 120, 'A three-cornered classic.'),
  I('hat', 'wizard', 'Wizard Hat', 140, 'Pointy, starry, magical.'),
  I('hat', 'viking', 'Viking Helmet', 150, 'Horns up!'),
  I('hat', 'pilot', 'Pilot Cap', 150, 'Leather cap and goggles.'),
  I('hat', 'crown', 'Crown', 250, 'King or queen of the dance floor.'),
  G('hat', 'tiara', 'Tiara', 15, 'Sparkling gold with a gem.'),
  G('hat', 'spacehelmet', 'Space Helmet', 25, 'A glass bubble for dancing on the moon.'),

  // ---------------------------------------------------------------- glasses
  I('eyes', 'none', 'No glasses', 0, 'Big eyes, no frames.'),
  I('eyes', 'round', 'Round Specs', 40, 'For studying routines.'),
  I('eyes', 'nerd', 'Square Frames', 40, 'Smart and sharp.'),
  I('eyes', 'shades', 'Shades', 50, 'Too cool.'),
  I('eyes', 'hippie', 'Round Shades', 60, 'Peace, love and dance.'),
  I('eyes', 'cateye', 'Cat-Eye Frames', 70, 'Retro glam.'),
  I('eyes', 'threed', '3D Glasses', 70, 'The moves jump off the screen.'),
  I('eyes', 'stars', 'Star Glasses', 80, 'Superstar status.'),
  I('eyes', 'hearts', 'Heart Glasses', 90, 'Love to dance.'),
  I('eyes', 'aviators', 'Aviators', 110, 'Gold frames, dark lenses.'),
  I('eyes', 'monocle', 'Monocle', 120, 'Quite so.'),
  I('eyes', 'goggles', 'Ski Goggles', 130, 'Fresh powder, fresh moves.'),
  G('eyes', 'visor', 'Cyber Visor', 20, 'A glowing heads-up display.'),

  // ---------------------------------------------------------------- neck
  I('neck', 'none', 'Nothing', 0, 'Keep it simple.'),
  I('neck', 'bowtie', 'Bow Tie', 30, 'Dressed for the show.'),
  I('neck', 'tie', 'Necktie', 40, 'Business on top, party below.'),
  I('neck', 'scarf', 'Scarf', 50, 'Flaps when you jump.'),
  I('neck', 'bandana', 'Bandana', 50, 'Wild West style.'),
  I('neck', 'whistle', 'Coach Whistle', 50, 'Tweet tweet, next move.'),
  I('neck', 'bell', 'Bell Collar', 60, 'Jingle as you jive.'),
  I('neck', 'lei', 'Flower Lei', 70, 'Beach vibes.'),
  I('neck', 'pearls', 'Pearls', 100, 'Elegant and classic.'),
  I('neck', 'chain', 'Banana Chain', 120, 'A gold chain with a gold banana.'),
  I('neck', 'medal', 'Gold Medal', 150, 'First place in moves.'),
  G('neck', 'boa', 'Feather Boa', 12, 'Fluffy, pink, fabulous.'),

  // ---------------------------------------------------------------- back
  I('back', 'none', 'Nothing', 0, 'Skin extras like wings and capes show when your back is free.'),
  I('back', 'backpack', 'Backpack', 80, 'Snacks for the road.'),
  I('back', 'skateboard', 'Skateboard', 120, 'Kickflip after the show.'),
  I('back', 'shell', 'Turtle Shell', 140, 'Slow and steady wins the dance.'),
  I('back', 'cape', 'Hero Cape', 150, 'Swishes with every move.'),
  I('back', 'guitar', 'Guitar', 160, 'Slung over the shoulder, ready to rock.'),
  G('back', 'parrot', 'Parrot Pal', 20, 'Sits on your shoulder and bobs to the beat.'),
  G('back', 'jetpack', 'Turbo Jetpack', 25, 'Gold tanks with blue flames.'),
  G('back', 'angelwings', 'Angel Wings', 30, 'Flap as you dance.'),
  G('back', 'batwings', 'Bat Wings', 30, 'Spooky and swooshy.'),
  G('back', 'butterfly', 'Butterfly Wings', 30, 'See-through and shimmery.'),

  // ---------------------------------------------------------------- hands
  I('hands', 'none', 'Empty hands', 0, 'Free to wave.'),
  I('hands', 'banana', 'Banana', 30, 'A snack for later.'),
  I('hands', 'maracas', 'Maracas', 60, 'Shake shake shake.'),
  I('hands', 'tambourine', 'Tambourine', 70, 'Jingle on the beat.'),
  I('hands', 'drumsticks', 'Drumsticks', 70, 'Ba-dum-tss.'),
  I('hands', 'mic', 'Microphone', 90, 'Sing along.'),
  I('hands', 'candy', 'Candy Bucket', 90, 'Trick or treat.'),
  I('hands', 'spyglass', 'Spyglass', 100, 'Land ho!'),
  I('hands', 'trophy', 'Trophy', 150, 'Champion of the dance floor.'),
  G('hands', 'wand', 'Magic Wand', 15, 'With a twinkling star.'),
  G('hands', 'glowsticks', 'Glow Sticks', 15, 'Pulse with the beat.'),
  G('hands', 'scepter', 'Royal Scepter', 20, 'Gold with a glowing gem.'),

  // ---------------------------------------------------------------- feet
  I('feet', 'none', 'Bare feet', 0, 'Monkeys dance barefoot.'),
  I('feet', 'sneakers', 'Sneakers', 60, 'Light on your feet.'),
  I('feet', 'rainboots', 'Rain Boots', 70, 'Puddle-proof.'),
  I('feet', 'flippers', 'Flippers', 80, 'Flap flap.'),
  I('feet', 'hightops', 'High-Tops', 90, 'Classic court style.'),
  I('feet', 'skates', 'Roller Skates', 140, 'Roll with it.'),
  G('feet', 'rocketboots', 'Rocket Boots', 25, 'Chrome boots with flames.'),

  // ---------------------------------------------------------------- face
  I('face', 'none', 'Nothing', 0, 'Your natural face.'),
  I('face', 'clownnose', 'Clown Nose', 30, 'Honk!'),
  I('face', 'mustache', 'Curly Mustache', 40, 'Distinguished.'),
  I('face', 'whiskers', 'Whiskers', 40, 'Meow?'),
  I('face', 'starpaint', 'Star Face Paint', 50, 'Two stars on the cheek.'),
  I('face', 'heartpaint', 'Heart Face Paint', 50, 'A heart on the cheek.'),
  I('face', 'gum', 'Bubble Gum', 80, 'Blows a bubble, then... pop.'),

  // ---------------------------------------------------------------- auras (replace a skin's own aura while worn)
  I('aura', 'none', 'Skin\'s own', 0, 'Shows the aura that comes with your skin, if it has one.'),
  I('aura', 'bubbles', 'Bubbles', 150, 'Bubbles float around you.', { auraColor: '#bfefff' }),
  I('aura', 'leaves', 'Falling Leaves', 150, 'Leaves drift down around you.', { auraColor: '#7ad05a' }),
  I('aura', 'snow', 'Snowfall', 200, 'Your own little snow cloud.', { auraColor: '#ffffff' }),
  G('aura', 'sparkle', 'Sparkles', 10, 'Twinkling sparkles.', { auraColor: '#ffffff' }),
  G('aura', 'hearts', 'Hearts', 10, 'Floating hearts.', { auraColor: '#ff6fae' }),
  G('aura', 'notes', 'Music Notes', 10, 'Notes rise as you dance.', { auraColor: '#ffd23f' }),
  G('aura', 'stars', 'Stars', 12, 'Golden stars.', { auraColor: '#ffe9a8' }),
  G('aura', 'confetti', 'Confetti', 12, 'A constant party.', { auraColor: '#ffffff' }),
  G('aura', 'embers', 'Embers', 15, 'Glowing sparks fly up.', { auraColor: '#ff9a20' }),
  G('aura', 'pixels', 'Pixels', 15, 'Retro bits float off you.', { auraColor: '#2ae8ff' }),

  // ---------------------------------------------------------------- flair moves
  I('flair', 'wiggle', 'Hip Wiggle', 0, 'The Flair move wiggles the hips.'),
  I('flair', 'shimmy', 'Shoulder Shimmy', 80, 'The Flair move shakes the shoulders.'),
  I('flair', 'spin', 'Spin', 100, 'The Flair move is a full spin.'),
  I('flair', 'robot', 'Robot', 120, 'The Flair move goes beep-boop.'),

  // ---------------------------------------------------------------- stages
  I('stage', 'jungle', 'Jungle Clearing', 0, 'Home sweet home.'),
  I('stage', 'beach', 'Beach Bash', 150, 'Free when you reach World 2.', { unlockWorld: 2 }),
  I('stage', 'disco', 'Temple Disco', 250, 'Free when you reach World 3.', { unlockWorld: 3 }),
  I('stage', 'moon', 'Moon Party', 300, 'Free when you reach World 4.', { unlockWorld: 4 }),
];

export function itemsIn(cat) {
  return ITEMS.filter((i) => i.cat === cat);
}

export function getItem(cat, id) {
  return ITEMS.find((i) => i.cat === cat && i.id === id) || null;
}

export const DEFAULT_OWNED = { skin: ['cocoa'], hat: ['none'], eyes: ['none'], neck: ['none'], back: ['none'], hands: ['none'], feet: ['none'], face: ['none'], aura: ['none'], flair: ['wiggle'], stage: ['jungle'] };
export const DEFAULT_EQUIPPED = { skin: 'cocoa', hat: 'none', eyes: 'none', neck: 'none', back: 'none', hands: 'none', feet: 'none', face: 'none', aura: 'none', flair: 'wiggle', stage: 'auto' };
