/* ============================================================
   Alien Duel: the rival on screen. Avatar, speech bubble, the
   race (your progress against theirs) and a live miniature of
   the rival's board. Tap it to look at their board full size.
   ============================================================ */

import { h } from './dom.js';
import { SYMBOL_SETS } from '../data/symbols.js';
import { glyphSvg } from './glyphs.js';
import { describeRival } from '../game/rival.js';
import { openModal } from './modal.js';

export function rivalAvatar(look) {
  return (SYMBOL_SETS[look.set] || SYMBOL_SETS.creatures).svgs[look.n - 1];
}

/**
 * @param {object} o
 * @param {object} o.rival     resolved rival config (game/rival.js)
 * @param {number[]} o.puzzle  the starting clues
 * @param {number} o.total     cells to fill
 * @param {string} o.youName   label for the player's race bar
 * @param {() => string} o.setKey  lineup the boards draw with
 */
export function createRivalPanel({ rival, puzzle, total, youName = 'You', setKey }) {
  const boards = [];             // every live view of the rival's board (mini + open full view)
  let current = puzzle.slice();  // the rival's board as last drawn
  let sayTimer = null;

  const bubble = h('span', { class: 'rival-bubble', 'aria-live': 'polite' });
  const youBar = h('b');
  const themBar = h('b');
  const youNum = h('span', { class: 'race-num' }, `0/${total}`);
  const themNum = h('span', { class: 'race-num' }, `0/${total}`);
  const mini = makeBoard('rival-mini', false);
  const who = h('button', {
    class: 'rival-who', type: 'button',
    'aria-label': `${rival.name}, your rival. ${describeRival(rival)}. Open their board.`,
    onclick: () => openPeek(),
  },
  h('span', { class: 'rival-avatar', html: rivalAvatar(rival.look) }),
  h('span', { class: 'rival-id' }, h('b', { class: 'rival-name' }, rival.name), bubble));

  const el = h('section', { class: `rival tone-${rival.tone}`, 'aria-label': `Duel against ${rival.name}` },
    who,
    h('div', { class: 'race' },
      h('div', { class: 'race-row race-you' }, h('span', { class: 'race-name' }, youName), h('i', { class: 'race-bar' }, youBar), youNum),
      h('div', { class: 'race-row race-them' }, h('span', { class: 'race-name' }, rival.name), h('i', { class: 'race-bar' }, themBar), themNum)),
    h('button', { class: 'rival-mini-btn', type: 'button', 'aria-label': `${rival.name}'s board. Open it full size.`, onclick: () => openPeek() }, mini.el));

  function makeBoard(cls, big) {
    const cells = [];
    const boardEl = h('div', { class: `rival-board ${cls}`, role: 'img' });
    for (let i = 0; i < 81; i++) {
      const c = h('i', { class: puzzle[i] ? 'g' : '' });
      cells.push(c);
      boardEl.appendChild(c);
    }
    const b = { el: boardEl, cells, big };
    boards.push(b);
    paint(b);
    return b;
  }

  function filledCount() { return current.reduce((n, v, i) => n + (v && !puzzle[i] ? 1 : 0), 0); }

  /** Draw one view from the rival's current board. */
  function paint(b) {
    const key = setKey();
    for (let i = 0; i < 81; i++) {
      const c = b.cells[i];
      const v = current[i];
      const given = !!puzzle[i];
      c.classList.toggle('f', !!v && !given);
      // Givens are the same on both boards, so the full view always shows them.
      // The rival's own glyphs show only when the duel allows it.
      const show = v && ((given && b.big) || (!given && rival.showGlyphs));
      const want = show ? `${key}:${v}` : '';
      if (c.dataset.k !== want) {
        c.dataset.k = want;
        c.innerHTML = show ? glyphSvg(key, v) : '';
      }
    }
    b.el.setAttribute('aria-label', `${rival.name}'s board: ${filledCount()} of ${total} glyphs placed`);
  }

  function pulse(i, cls, ms) {
    for (const b of boards) {
      const c = b.cells[i];
      c.classList.remove(cls);
      void c.offsetWidth;
      c.classList.add(cls);
      setTimeout(() => c.classList.remove(cls), ms);
    }
  }

  function openPeek() {
    const big = makeBoard('rival-big', true);
    openModal({
      eyebrow: 'Alien Duel · the clock keeps running',
      title: `${rival.name}'s board`,
      className: 'peek-modal',
      body: [
        big.el,
        h('p', { class: 'modal-text' }, rival.showGlyphs
          ? 'Every glyph your rival has placed.'
          : 'Lit cells are the ones your rival has solved. Their glyphs stay hidden in this duel.'),
      ],
      actions: [{ label: 'Back to my board', kind: 'primary', autofocus: true }],
      onClose: () => { const k = boards.indexOf(big); if (k >= 0) boards.splice(k, 1); },
    });
  }

  return {
    el,
    /** Redraw everything from the rival's board (after resume, or a lineup change). */
    sync(board) {
      current = board.slice();
      for (const b of boards) { for (const c of b.cells) c.dataset.k = '\u0000'; paint(b); }
    },
    /** One rival move: a placed glyph, or a fumble. */
    event(e, board) {
      current = board.slice();
      for (const b of boards) paint(b);
      pulse(e.i, e.wrong ? 'x' : 'new', e.wrong ? 600 : 700);
      if (e.wrong) { el.classList.remove('fumbled'); void el.offsetWidth; el.classList.add('fumbled'); }
    },
    setRace(you, them) {
      const pct = (n) => `${total ? Math.round((n / total) * 100) : 0}%`;
      youBar.style.width = pct(you);
      themBar.style.width = pct(them);
      youNum.textContent = `${you}/${total}`;
      themNum.textContent = `${them}/${total}`;
      el.classList.toggle('you-lead', you > them);
      el.classList.toggle('they-lead', them > you);
    },
    /** Show a line in the speech bubble for a few seconds. */
    say(text, hold = 5200) {
      clearTimeout(sayTimer);
      bubble.textContent = text || '';
      bubble.classList.remove('pop');
      if (!text) return;
      void bubble.offsetWidth;
      bubble.classList.add('pop');
      if (hold) sayTimer = setTimeout(() => { bubble.textContent = describeRival(rival); bubble.classList.remove('pop'); }, hold);
    },
    /** Rest text under the name when the rival is not talking. */
    rest() { clearTimeout(sayTimer); bubble.textContent = describeRival(rival); bubble.classList.remove('pop'); },
    setFinished(text) {
      clearTimeout(sayTimer);
      el.classList.add('finished');
      bubble.textContent = text;
    },
    destroy() { clearTimeout(sayTimer); },
  };
}
