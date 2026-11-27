// Keyboard keys for the six moves. Defaults: Q W E on the top row, A S D on the
// bottom row (plus 7 8 9 / 4 5 6 and the numpad). Players can pick their own
// key for each move in Settings > Controls > Keyboard keys.
import { MOVES, PAD_ORDER } from './moves.js';

// Keys that already do something else, or that browsers keep for themselves.
const RESERVED = new Set(['escape', 'p', 'tab', 'enter', ' ', 'f5', 'f11', 'f12', 'meta', 'control', 'alt', 'shift']);

/** The key that plays a move (lower case), honouring the player's choice. */
export function keyFor(id, settings) {
  const custom = settings && settings.keys && settings.keys[id];
  return custom || MOVES[id].key;
}

/** key (lower case) -> move id, for the current settings. */
export function keyMap(settings) {
  const map = {};
  for (const id of PAD_ORDER) {
    // the number-row alternatives stay unless a custom key uses them
    if (MOVES[id].alt) map[MOVES[id].alt] = id;
  }
  for (const id of PAD_ORDER) map[keyFor(id, settings)] = id;
  return map;
}

/** Can this key be used for a move? Returns an error message or ''. */
export function checkKey(key, id, settings) {
  const k = String(key || '').toLowerCase();
  if (!k || k.length !== 1 && !/^f\d+$/.test(k)) return 'Pick a letter, number or symbol key.';
  if (RESERVED.has(k)) return k === 'p' ? 'P pauses the game.' : 'That key is taken by the game or the browser.';
  for (const other of PAD_ORDER) {
    if (other !== id && keyFor(other, settings) === k) return `${k.toUpperCase()} already plays ${MOVES[other].name}.`;
  }
  return '';
}

/** Short summary for the settings screen, e.g. "Q W E / A S D". */
export function keySummary(settings) {
  const k = (id) => keyFor(id, settings).toUpperCase();
  return `${k('LA')} ${k('HD')} ${k('RA')} / ${k('LL')} ${k('FL')} ${k('RL')}`;
}
