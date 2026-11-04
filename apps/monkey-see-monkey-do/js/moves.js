// The six moves the monkey can do, and the combos (two moves at the same time).
// "Left" and "Right" mean the side of the SCREEN by default, like a mirror,
// so the Left Arm button sits under the arm on the left of the screen.
// Settings > "Name sides by" can switch the names to the monkey's own sides.

export const MOVES = {
  LA: { id: 'LA', side: 'L', part: 'arm', name: 'Left Arm', verb: 'Arm up', color: '#FF8A1F', key: 'q', alt: '7', swipe: 'up-left', noteName: 'E4', freq: 329.63 },
  HD: { id: 'HD', side: 'C', part: 'head', name: 'Head Bob', verb: 'Nod', color: '#FFC926', key: 'w', alt: '8', swipe: 'up', noteName: 'C5', freq: 523.25 },
  RA: { id: 'RA', side: 'R', part: 'arm', name: 'Right Arm', verb: 'Arm up', color: '#2E8BFF', key: 'e', alt: '9', swipe: 'up-right', noteName: 'G4', freq: 392.0 },
  LL: { id: 'LL', side: 'L', part: 'leg', name: 'Left Leg', verb: 'Stomp', color: '#1FB57A', key: 'a', alt: '4', swipe: 'down-left', noteName: 'G3', freq: 196.0 },
  FL: { id: 'FL', side: 'C', part: 'flair', name: 'Flair', verb: 'Show off', color: '#FF4F9A', key: 's', alt: '5', swipe: 'down', noteName: 'A4', freq: 440.0 },
  RL: { id: 'RL', side: 'R', part: 'leg', name: 'Right Leg', verb: 'Stomp', color: '#9B5CFF', key: 'd', alt: '6', swipe: 'down-right', noteName: 'C4', freq: 261.63 },
};

// Pad layout, read left to right, top row then bottom row.
export const PAD_ORDER = ['LA', 'HD', 'RA', 'LL', 'FL', 'RL'];

// Combos: both moves within a short window count as one step.
export const CHORDS = {
  BA: { id: 'BA', parts: ['LA', 'RA'], name: 'Hooray!', hint: 'Both arms at once' },
  BL: { id: 'BL', parts: ['LL', 'RL'], name: 'Jump!', hint: 'Both legs at once' },
  XL: { id: 'XL', parts: ['LA', 'RL'], name: 'Disco Point', hint: 'Left arm + right leg' },
  XR: { id: 'XR', parts: ['RA', 'LL'], name: 'Crab Step', hint: 'Right arm + left leg' },
};

export const ALL_MOVE_IDS = Object.keys(MOVES);

/** Sort a step's moves into pad order so steps compare equal regardless of tap order. */
export function normStep(step) {
  return [...step].sort((a, b) => PAD_ORDER.indexOf(a) - PAD_ORDER.indexOf(b));
}

export function sameStep(a, b) {
  if (!a || !b || a.length !== b.length) return false;
  const x = normStep(a), y = normStep(b);
  return x.every((v, i) => v === y[i]);
}

export function chordFor(step) {
  if (step.length < 2) return null;
  return Object.values(CHORDS).find((c) => sameStep(c.parts, step)) || null;
}

/** Move name, honouring the "Name sides by" setting ('screen' or 'monkey'). */
export function moveName(id, naming = 'screen') {
  const m = MOVES[id];
  if (!m) return id;
  if (naming !== 'monkey' || m.side === 'C') return m.name;
  return m.name.replace(/^(Left|Right)/, (s) => (s === 'Left' ? 'Right' : 'Left'));
}

export function stepName(step, naming = 'screen') {
  const c = chordFor(step);
  if (c) return c.name;
  return step.map((id) => moveName(id, naming)).join(' + ');
}

/**
 * A tiny monkey outline with the active body parts filled in. Used on the pad,
 * in results, and on the How it works page, so every move has a shape as well
 * as a colour (works for colour-blind players).
 */
export function moveIcon(ids, opts = {}) {
  const on = new Set(Array.isArray(ids) ? ids : [ids]);
  const dim = opts.dim ?? 0.32;
  const fg = opts.color || 'currentColor';
  const o = (id) => (on.has(id) ? 1 : dim);
  // Raised arm for the active arms, resting arm otherwise, so the icon shows the move.
  const armL = on.has('LA') ? 'M19 25 L11 15 L9 7' : 'M19 26 L13 33 L12 39';
  const armR = on.has('RA') ? 'M37 25 L45 15 L47 7' : 'M37 26 L43 33 L44 39';
  const legL = on.has('LL') ? 'M24 41 L16 41 L15 50' : 'M24 42 L22 50 L21 55';
  const legR = on.has('RL') ? 'M32 41 L40 41 L41 50' : 'M32 42 L34 50 L35 55';
  const headY = on.has('HD') ? 15 : 13;
  return `<svg viewBox="0 0 56 58" class="mv-icon" aria-hidden="true" focusable="false">
  <g fill="none" stroke="${fg}" stroke-linecap="round" stroke-linejoin="round">
    <path d="${armL}" stroke-width="5.5" opacity="${o('LA')}"/>
    <path d="${armR}" stroke-width="5.5" opacity="${o('RA')}"/>
    <path d="${legL}" stroke-width="6" opacity="${o('LL')}"/>
    <path d="${legR}" stroke-width="6" opacity="${o('RL')}"/>
  </g>
  <g fill="${fg}">
    <ellipse cx="28" cy="33" rx="9.5" ry="11" opacity="${on.has('FL') ? 1 : Math.max(dim, 0.55)}"/>
    <circle cx="28" cy="${headY}" r="9" opacity="${o('HD')}"/>
    <circle cx="18.5" cy="${headY - 1}" r="3.6" opacity="${o('HD')}"/>
    <circle cx="37.5" cy="${headY - 1}" r="3.6" opacity="${o('HD')}"/>
  </g>
  ${on.has('FL') ? `<g fill="none" stroke="${fg}" stroke-width="2.6" stroke-linecap="round"><path d="M8 30 q-3 3 0 6"/><path d="M48 30 q3 3 0 6"/><path d="M4 28 q-4 5 0 10"/><path d="M52 28 q4 5 0 10"/></g>` : ''}
  ${on.has('HD') ? `<g fill="none" stroke="${fg}" stroke-width="2.6" stroke-linecap="round"><path d="M14 4 q-3 -1 -5 1"/><path d="M42 4 q3 -1 5 1"/></g>` : ''}
</svg>`;
}
