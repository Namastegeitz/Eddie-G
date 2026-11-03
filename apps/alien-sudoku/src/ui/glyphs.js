/* Glyph lookup helpers. Values are 1..9. */
import { SYMBOL_SETS } from '../data/symbols.js';
import { SECTORS } from '../data/sectors.js';
import { settings } from '../core/profile.js';

/** Which symbol set a session should draw with right now. */
export function setKeyFor(session) {
  const s = settings();
  if (session?.mode === 'campaign' && s.sectorSymbols && session.sector != null) {
    return SECTORS[session.sector]?.symbolSet || s.symbolSet;
  }
  return s.symbolSet;
}

export const glyphSvg = (setKey, v) => (SYMBOL_SETS[setKey] || SYMBOL_SETS.alien).svgs[v - 1];
export const glyphName = (setKey, v) => (SYMBOL_SETS[setKey] || SYMBOL_SETS.alien).names[v - 1];
