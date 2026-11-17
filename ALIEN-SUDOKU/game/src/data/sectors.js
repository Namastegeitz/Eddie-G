/* Campaign: 6 sectors x 9 transmissions. Difficulty per level comes from
   engine/pool.js getCampaignPuzzle(); this file only holds presentation
   and unlock rules. Each sector is played with its own glyph lineup and theme. */

import { THEMES } from './themes.js';

const accent = (set) => `rgb(${THEMES[set].rgb.c1})`;

export const SECTORS = [
  {
    id: 0,
    name: 'Lunar Outpost',
    blurb: 'Mission control has picked up a faint signal near the moon. Suit up and decode it with the Space Fleet.',
    bg: 'space/moon-planet.webp',
    symbolSet: 'fleet',
    accent: accent('fleet'),
    range: 'Easy',
  },
  {
    id: 1,
    name: 'Ring Belt',
    blurb: 'The signal bounces between the planets. Follow it across the solar system.',
    bg: 'space/ringed-planet.webp',
    symbolSet: 'planets',
    accent: accent('planets'),
    range: 'Easy → Medium',
  },
  {
    id: 2,
    name: 'Pink Nebula',
    blurb: 'Saucers, tic-tacs and black triangles. The visitors are close now.',
    bg: 'space/nebula-pink.webp',
    symbolSet: 'encounters',
    accent: accent('encounters'),
    range: 'Medium',
  },
  {
    id: 3,
    name: 'Emerald Pillars',
    blurb: 'Behind the dust columns live the creatures who sent the message. They want to meet you.',
    bg: 'space/pillars-green.webp',
    symbolSet: 'creatures',
    accent: accent('creatures'),
    range: 'Medium → Hard',
    unlocksSet: 'creatures',
  },
  {
    id: 4,
    name: 'Spiral Arm',
    blurb: 'Galaxies, black holes and supernovas become letters. Only skilled decoders get this far.',
    bg: 'space/galaxy-spiral.webp',
    symbolSet: 'cosmos',
    accent: accent('cosmos'),
    range: 'Hard',
  },
  {
    id: 5,
    name: 'Cluster Core',
    blurb: 'The source of the transmission: the builders of the pyramids. Their oldest secrets are written here.',
    bg: 'space/star-cluster.webp',
    symbolSet: 'ancient',
    accent: accent('ancient'),
    range: 'Hard → Alien',
    unlocksSet: 'ancient',
    rewardSet: 'mixed',
  },
];

export const LEVELS_PER_SECTOR = 9;
export const TOTAL_LEVELS = SECTORS.length * LEVELS_PER_SECTOR;
export const MAX_STARS = TOTAL_LEVELS * 3;

/** Symbol sets available from the start. The rest unlock by reaching a sector. */
export const STARTER_SETS = ['encounters', 'fleet', 'planets', 'cosmos', 'softies', 'hostile', 'gnarly'];

/** Lineup keys from before the redesign, mapped to their replacements. */
export const OLD_SET_KEYS = { alien: 'encounters', moons: 'fleet', aircraft: 'fleet', spaceships: 'creatures', galaxies: 'cosmos' };

export const levelKey = (sector, level) => `${sector}-${level}`;

/** Stars for a finished puzzle: 3 = clean, 2 = one slip, 1 = solved. */
export function starsFor({ mistakes = 0, hints = 0 }) {
  const slips = mistakes + hints;
  return slips === 0 ? 3 : slips === 1 ? 2 : 1;
}
