/* Campaign: 6 sectors x 9 transmissions. Difficulty per level comes from
   engine/pool.js getCampaignPuzzle(); this file only holds presentation
   and unlock rules. */

export const SECTORS = [
  {
    id: 0,
    name: 'Lunar Outpost',
    blurb: 'A quiet relay station on the edge of the moon. The first signals are faint but simple.',
    bg: 'space/moon-planet.webp',
    symbolSet: 'moons',
    accent: '#5ff0ff',
    range: 'Easy',
  },
  {
    id: 1,
    name: 'Ring Belt',
    blurb: 'Ice and rock circle a giant world. The glyphs start to tangle.',
    bg: 'space/ringed-planet.webp',
    symbolSet: 'planets',
    accent: '#ffd36b',
    range: 'Easy → Medium',
  },
  {
    id: 2,
    name: 'Pink Nebula',
    blurb: 'The original alien script, glowing inside a cloud of newborn stars.',
    bg: 'space/nebula-pink.webp',
    symbolSet: 'alien',
    accent: '#ff5cf6',
    range: 'Medium',
  },
  {
    id: 3,
    name: 'Emerald Pillars',
    blurb: 'Towering dust columns hide a fleet of silent ships.',
    bg: 'space/pillars-green.webp',
    symbolSet: 'spaceships',
    accent: '#39ff9c',
    range: 'Medium → Hard',
    unlocksSet: 'spaceships',
  },
  {
    id: 4,
    name: 'Spiral Arm',
    blurb: 'Whole galaxies become letters. Only skilled decoders get this far.',
    bg: 'space/galaxy-spiral.webp',
    symbolSet: 'galaxies',
    accent: '#b46bff',
    range: 'Hard',
    unlocksSet: 'galaxies',
  },
  {
    id: 5,
    name: 'Cluster Core',
    blurb: 'The source of the transmission. Every symbol in the archive, all at once.',
    bg: 'space/star-cluster.webp',
    symbolSet: 'mixed',
    accent: '#ffffff',
    range: 'Hard → Alien',
    unlocksSet: 'mixed',
  },
];

export const LEVELS_PER_SECTOR = 9;
export const TOTAL_LEVELS = SECTORS.length * LEVELS_PER_SECTOR;
export const MAX_STARS = TOTAL_LEVELS * 3;

/** Symbol sets available from the start. The rest unlock by reaching a sector. */
export const STARTER_SETS = ['alien', 'planets', 'moons', 'aircraft'];

export const levelKey = (sector, level) => `${sector}-${level}`;

/** Stars for a finished puzzle: 3 = clean, 2 = one slip, 1 = solved. */
export function starsFor({ mistakes = 0, hints = 0 }) {
  const slips = mistakes + hints;
  return slips === 0 ? 3 : slips === 1 ? 2 : 1;
}
