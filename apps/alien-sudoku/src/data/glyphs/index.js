/* ============================================================
   Glyph lineups. Each lineup module (encounters.js, fleet.js, ...)
   exports:
     { key, names: [9], colors: [9 '#rrggbb'], defs: '<svg defs markup>',
       symbols: [9 inner-SVG strings for viewBox "0 0 64 64"] }
   All ids inside defs/symbols start with the lineup's prefix
   (e.g. "enc-"), so lineups never clash.

   The game draws a glyph with <svg><use href="#gl-<key>-<n>"/></svg>,
   so every glyph exists once in the page (installGlyphSprite) no matter
   how many cells show it.
   ============================================================ */

import encounters from './encounters.js';
import fleet from './fleet.js';
import planets from './planets.js';
import cosmos from './cosmos.js';
import creatures from './creatures.js';
import ancient from './ancient.js';
import { THEMES } from '../themes.js';

export const LINEUPS = { encounters, fleet, planets, cosmos, creatures, ancient };

/** Cosmic Mix borrows the most iconic glyph of each lineup: [lineup, 1-based index]. */
export const MIXED_REFS = [
  ['encounters', 1], ['encounters', 2], ['ancient', 1], ['fleet', 1], ['creatures', 4],
  ['cosmos', 5], ['creatures', 3], ['encounters', 3], ['planets', 3],
];

export const SYMBOL_SET_ORDER = ['encounters', 'fleet', 'planets', 'cosmos', 'creatures', 'ancient', 'mixed'];

const useSvg = (id, label) =>
  `<svg class="gsvg" viewBox="0 0 64 64" role="img" aria-label="${label}"><use href="#${id}"/></svg>`;

function makeSet(key) {
  if (key === 'mixed') {
    return {
      key,
      name: THEMES.mixed.name,
      names: MIXED_REFS.map(([k, i]) => LINEUPS[k].names[i - 1]),
      colors: MIXED_REFS.map(([k, i]) => LINEUPS[k].colors[i - 1]),
      svgs: MIXED_REFS.map(([k, i]) => useSvg(`gl-${k}-${i}`, LINEUPS[k].names[i - 1])),
    };
  }
  const L = LINEUPS[key];
  return {
    key,
    name: THEMES[key].name,
    names: L.names,
    colors: L.colors,
    svgs: L.symbols.map((_, i) => useSvg(`gl-${key}-${i + 1}`, L.names[i])),
  };
}

export const SYMBOL_SETS = Object.fromEntries(SYMBOL_SET_ORDER.map((k) => [k, makeSet(k)]));

/** One hidden <svg> holding every gradient and glyph symbol. */
export function spriteMarkup() {
  let defs = '';
  let symbols = '';
  for (const [key, L] of Object.entries(LINEUPS)) {
    defs += L.defs || '';
    L.symbols.forEach((body, i) => {
      symbols += `<symbol id="gl-${key}-${i + 1}" viewBox="0 0 64 64">${body}</symbol>`;
    });
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false" style="position:absolute;width:0;height:0;overflow:hidden"><defs>${defs}</defs>${symbols}</svg>`;
}

export function installGlyphSprite(doc = document) {
  if (doc.getElementById('glyph-sprite')) return;
  const holder = doc.createElement('div');
  holder.id = 'glyph-sprite';
  holder.setAttribute('aria-hidden', 'true');
  holder.style.cssText = 'position:absolute;width:0;height:0;overflow:hidden';
  holder.innerHTML = spriteMarkup();
  doc.body.prepend(holder);
}
