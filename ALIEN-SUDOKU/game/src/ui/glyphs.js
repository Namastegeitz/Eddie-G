/* Glyph lookup helpers. Values are 1..9. */
import { SYMBOL_SETS } from '../data/symbols.js';
import { SECTORS } from '../data/sectors.js';
import { settings } from '../core/profile.js';
import { DIFFICULTY_LINEUP } from '../data/themes.js';
import { campaignDifficulty } from '../engine/pool.js';

/** Which symbol set a session should draw with right now. */
export function setKeyFor(session) {
  const s = settings();
  // Each difficulty brings its own aliens, soft to gnarly, in every mode (campaign included).
  if (session && s.difficultyAliens !== false && DIFFICULTY_LINEUP[session.difficulty]) {
    return DIFFICULTY_LINEUP[session.difficulty];
  }
  if (session?.mode === 'campaign' && s.sectorSymbols && session.sector != null) {
    return SECTORS[session.sector]?.symbolSet || s.symbolSet;
  }
  return s.symbolSet;
}

/** The lineup a campaign level is played with. */
export function lineupForLevel(sector, level) {
  const s = settings();
  if (s.difficultyAliens !== false) return DIFFICULTY_LINEUP[campaignDifficulty(sector, level)];
  return s.sectorSymbols ? SECTORS[sector]?.symbolSet || s.symbolSet : s.symbolSet;
}

/** The lineup (and theme) a sector is shown with: the one of its middle transmission. */
export const sectorLineup = (sector) => lineupForLevel(sector, 4);

export const glyphSvg = (setKey, v) => (SYMBOL_SETS[setKey] || SYMBOL_SETS.encounters).svgs[v - 1];
export const glyphName = (setKey, v) => (SYMBOL_SETS[setKey] || SYMBOL_SETS.encounters).names[v - 1];
export const glyphColor = (setKey, v) => (SYMBOL_SETS[setKey] || SYMBOL_SETS.encounters).colors[v - 1];
