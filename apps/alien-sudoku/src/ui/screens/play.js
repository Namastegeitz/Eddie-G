/* ============================================================
   Play screen: board, palette, tools, timer, lives, pause,
   win / lose flow. One GameSession per screen instance.
   ============================================================ */

import { h, icon, clear } from '../dom.js';
import { GameSession, MAX_MISTAKES } from '../../game/session.js';
import { randomPuzzle, getCampaignPuzzle, getDailyPuzzle } from '../../engine/pool.js';
import {
  settings, setSetting, recordResult, loadSavedGame, storeSavedGame, clearSavedGame,
  countGameStarted, getProfile,
} from '../../core/profile.js';
import { SECTORS, LEVELS_PER_SECTOR, starsFor } from '../../data/sectors.js';
import { SYMBOL_SETS } from '../../data/symbols.js';
import { formatTime, prettyDate } from '../../core/time.js';
import { sfx, music } from '../../audio/audio.js';
import { haptic } from '../../platform/native.js';
import { adsSupported, showRewarded, noteGameFinished, maybeShowInterstitial } from '../../platform/ads.js';
import { openModal, confirmModal, toast } from '../modal.js';
import { randomBackground } from '../background.js';
import { setKeyFor, glyphSvg, glyphName, glyphColor } from '../glyphs.js';
import { createParticles } from '../particles.js';
import { THEMES } from '../../data/themes.js';
import { on } from '../../core/events.js';

const DIFF_LABEL = { easy: 'Easy', medium: 'Medium', hard: 'Hard', alien: 'Alien' };
const SVG_NS = 'http://www.w3.org/2000/svg';
const rowOf = (i) => Math.floor(i / 9);
const colOf = (i) => i % 9;
const boxOf = (i) => Math.floor(rowOf(i) / 3) * 3 + Math.floor(colOf(i) / 3);
const sameUnit = (a, b) => rowOf(a) === rowOf(b) || colOf(a) === colOf(b) || boxOf(a) === boxOf(b);

/** Build a new session from route params. */
export function createSession(params) {
  const s = settings();
  let p;
  let extra = {};
  if (params.mode === 'campaign') {
    p = getCampaignPuzzle(params.sector, params.level);
    extra = { sector: params.sector, level: params.level, bg: SECTORS[params.sector].bg };
  } else if (params.mode === 'daily') {
    p = getDailyPuzzle(params.date);
    extra = { date: params.date };
  } else {
    p = randomPuzzle(params.difficulty || s.quickDifficulty || 'medium');
  }
  return new GameSession({
    puzzleId: p.id,
    mode: params.mode || 'quick',
    difficulty: p.difficulty,
    puzzle: p.puzzle,
    solution: p.solution,
    bg: extra.bg || randomBackground(),
    autoRemoveNotes: s.autoRemoveNotes,
    ...extra,
  });
}

export function sessionTitle(session) {
  switch (session.mode) {
    case 'campaign': return { eyebrow: `Campaign · ${SECTORS[session.sector].name}`, title: `Transmission ${session.level + 1} / ${LEVELS_PER_SECTOR}` };
    case 'daily': return { eyebrow: 'Daily Transmission', title: prettyDate(session.date) };
    case 'zen': return { eyebrow: 'Zen Mode', title: DIFF_LABEL[session.difficulty] };
    default: return { eyebrow: 'Quick Play', title: DIFF_LABEL[session.difficulty] };
  }
}

const HINT_TEXT = {
  'full-house': (n, u) => `Last empty cell in this ${u}: it must be ${n}.`,
  'hidden-single': (n, u) => `${n} fits in only one place in this ${u}.`,
  'naked-single': (n) => `Every other glyph already sees this cell: only ${n} fits.`,
  reveal: (n) => `The archive decoded this cell: ${n}.`,
};
const UNIT_WORD = { row: 'row', col: 'column', box: 'box' };

export const playScreen = {
  id: 'play',
  keepAlive: true,
  banner: true,
  bg: (params, inst) => inst?.session?.bg || null,
  theme: (params, inst) => (inst?.session ? setKeyFor(inst.session) : null),

  create(params, nav) {
    // ---------- Session ----------
    let session;
    if (params.resume) {
      const snap = loadSavedGame();
      session = snap ? GameSession.fromSnapshot(snap) : createSession({ mode: 'quick' });
    } else if (params.snapshot) {
      session = GameSession.fromSnapshot(params.snapshot);
      countGameStarted();
    } else {
      session = createSession(params);
      countGameStarted();
    }
    let firstShow = true;
    session.autoRemoveNotes = settings().autoRemoveNotes;
    // Test hook: end-to-end tests open the app with #e2e to read the solution.
    if (typeof location !== 'undefined' && location.hash.includes('e2e')) window.__alienSession = session;

    let selected = null;        // cell index
    let armed = null;           // glyph armed in glyph-first input mode
    let notesMode = false;
    let paused = false;
    let finished = false;       // result already recorded
    let lastTick = performance.now();
    let timerId = null;
    let saveTimer = null;
    const flashing = new Map(); // cell -> class (transient animations)
    const cellCache = new Array(81).fill('');
    const unsubs = [];

    // ---------- DOM ----------
    const t = sessionTitle(session);
    const timerEl = h('span', { class: 'hud-timer-value' }, '0:00');
    const scoreVal = h('b', {}, '0');
    const comboEl = h('span', { class: 'combo-badge', hidden: true });
    const scoreEl = h('span', { class: 'hud-score', 'aria-label': 'Score' }, scoreVal, comboEl);
    const livesEl = h('div', { class: 'hud-lives', 'aria-label': 'Lives' });
    const statusEl = h('div', { class: 'status-line', role: 'status', 'aria-live': 'polite' });
    const boardEl = h('div', { class: 'board', role: 'grid', 'aria-label': 'Sudoku board' });
    const constEl = document.createElementNS(SVG_NS, 'svg');
    constEl.setAttribute('class', 'constellation');
    constEl.setAttribute('viewBox', '0 0 9 9');
    constEl.setAttribute('preserveAspectRatio', 'none');
    constEl.setAttribute('aria-hidden', 'true');
    const pauseCover = h('div', { class: 'pause-cover', hidden: true },
      h('div', { class: 'pause-cover-text' }, 'Transmission paused'),
      h('button', { class: 'btn btn-primary', type: 'button', onclick: () => resume() }, icon('play'), h('span', {}, 'Resume')));
    const fxLayer = h('div', { class: 'fx-layer', 'aria-hidden': 'true' });
    const boardWrap = h('div', { class: 'board-wrap' }, boardEl, constEl, fxLayer, pauseCover);
    const fx = createParticles(boardWrap);
    fx.setEnabled(!settings().reduceMotion);
    const boardArea = h('div', { class: 'board-area' }, boardWrap);

    const cells = [];
    for (let i = 0; i < 81; i++) {
      const r = rowOf(i), c = colOf(i);
      const cell = h('div', {
        class: `cell${r % 3 === 0 ? ' bt' : ''}${c % 3 === 0 ? ' bl' : ''}${c === 8 ? ' br' : ''}${r === 8 ? ' bb' : ''}`,
        role: 'gridcell',
        dataset: { i },
      });
      cells.push(cell);
      boardEl.appendChild(cell);
    }
    boardEl.addEventListener('pointerdown', (e) => {
      const cell = e.target.closest('.cell');
      if (!cell) return;
      e.preventDefault();
      onCellTap(Number(cell.dataset.i));
    });

    const btnUndo = toolBtn('undo', 'Undo', () => doUndo());
    const btnErase = toolBtn('erase', 'Erase', () => doErase());
    const btnNotes = toolBtn('notes', 'Notes', () => toggleNotes());
    const notesBadge = h('span', { class: 'tool-badge' }, 'OFF');
    btnNotes.appendChild(notesBadge);
    const btnHint = toolBtn('hint', 'Hint', () => doHint());
    const hintBadge = h('span', { class: 'tool-badge' });
    btnHint.appendChild(hintBadge);
    const tools = h('div', { class: 'tools' }, btnUndo, btnErase, btnNotes, btnHint);

    const paletteBtns = [];
    const palette = h('div', { class: 'palette', role: 'toolbar', 'aria-label': 'Glyphs' });
    for (let v = 1; v <= 9; v++) {
      const b = h('button', { class: 'glyph-btn', type: 'button', dataset: { v } },
        h('span', { class: 'glyph-svg' }), h('span', { class: 'glyph-count' }));
      b.addEventListener('click', () => onGlyph(v));
      paletteBtns.push(b);
      palette.appendChild(b);
    }

    const el = h('div', { class: 'play-layout' },
      h('header', { class: 'topbar' },
        h('button', { class: 'icon-btn', type: 'button', 'aria-label': 'Back to menu', onclick: () => leave() }, icon('back')),
        h('div', { class: 'topbar-title' },
          h('div', { class: 'eyebrow' }, t.eyebrow),
          h('h1', { class: 'topbar-h1' }, t.title)),
        h('button', { class: 'icon-btn', type: 'button', 'aria-label': 'Pause', onclick: () => openPauseMenu() }, icon('pause'))),
      h('div', { class: 'play-main' },
        h('div', { class: 'hud-row' },
          h('span', { class: `diff-chip diff-${session.difficulty}` }, DIFF_LABEL[session.difficulty]),
          livesEl,
          scoreEl,
          h('span', { class: 'hud-timer' }, icon('bolt', 'hud-timer-ico'), timerEl)),
        boardArea,
        statusEl,
        tools,
        palette));

    // ---------- Board sizing ----------
    const ro = new ResizeObserver(() => fitBoard());
    ro.observe(boardArea);
    function fitBoard() {
      const r = boardArea.getBoundingClientRect();
      const size = Math.floor(Math.max(180, Math.min(r.width, r.height)));
      boardWrap.style.setProperty('--board', `${size}px`);
      fx.resize();
    }

    /** Center of a cell in board-wrap pixels (for particles and score pops). */
    function cellCenter(i) {
      const wr = boardWrap.getBoundingClientRect();
      const cr = cells[i].getBoundingClientRect();
      return [cr.left - wr.left + cr.width / 2, cr.top - wr.top + cr.height / 2];
    }

    function scorePop(i, points, combo) {
      if (!points || session.zen) return;
      const [x, y] = cellCenter(i);
      const pop = h('span', { class: 'score-pop', style: { left: `${x}px`, top: `${y}px` } }, `+${points}`, combo >= 2 ? h('small', {}, `×${combo}`) : null);
      pop.style.setProperty('--gc', glyphColor(setKeyFor(session), session.board[i] || 1));
      fxLayer.appendChild(pop);
      setTimeout(() => pop.remove(), 1000);
    }

    // ---------- Rendering ----------
    function render() {
      const setKey = setKeyFor(session);
      const s = settings();
      const selVal = selected != null ? session.board[selected] : 0;
      const focusVal = armed || selVal || 0;
      const completedCells = new Set();
      for (const key of session.completedUnits) for (const c of session.unitCells(key)) completedCells.add(c);

      for (let i = 0; i < 81; i++) {
        const v = session.board[i];
        const notes = session.notes[i];
        const cls = [];
        if (session.fixed[i]) cls.push(session.hinted[i] ? 'hinted' : 'fixed');
        else if (v) cls.push('user');
        if (selected === i) cls.push('selected');
        else if (selected != null && s.highlightPeers && sameUnit(selected, i)) cls.push('peer');
        if (s.highlightSame && focusVal && v === focusVal && selected !== i) cls.push('same');
        if (completedCells.has(i)) cls.push('unit-complete');
        if (flashing.has(i)) cls.push(flashing.get(i));

        const key = `${setKey}|${v}|${notes}|${v ? '' : focusVal}|${cls.join(' ')}`;
        if (cellCache[i] === key) continue;
        cellCache[i] = key;

        const cell = cells[i];
        cell.className = cell.className.split(' ').filter((c) => c === 'cell' || c === 'bt' || c === 'bl' || c === 'br' || c === 'bb').concat(cls).join(' ');
        if (v) {
          cell.style.setProperty('--gc', glyphColor(setKey, v));
          cell.innerHTML = `<span class="cell-glyph">${glyphSvg(setKey, v)}</span>`;
          cell.setAttribute('aria-label', `Row ${rowOf(i) + 1}, column ${colOf(i) + 1}: ${glyphName(setKey, v)}`);
        } else if (notes) {
          let html = '<div class="notes-grid">';
          for (let n = 1; n <= 9; n++) {
            const has = notes & (1 << (n - 1));
            html += `<span class="note${has && n === focusVal ? ' note-hl' : ''}">${has ? glyphSvg(setKey, n) : ''}</span>`;
          }
          cell.innerHTML = html + '</div>';
          cell.setAttribute('aria-label', `Row ${rowOf(i) + 1}, column ${colOf(i) + 1}: notes`);
        } else {
          cell.innerHTML = '';
          cell.setAttribute('aria-label', `Row ${rowOf(i) + 1}, column ${colOf(i) + 1}: empty`);
        }
      }
      renderConstellation(focusVal);
      renderPalette(setKey);
      renderTools();
      renderLives();
      renderScore();
      renderTimer();
    }

    let lastCombo = 0;
    function renderScore() {
      scoreEl.hidden = session.zen;
      scoreVal.textContent = session.score.toLocaleString();
      const combo = session.status === 'playing' ? session.combo : 0;
      comboEl.hidden = combo < 2;
      comboEl.textContent = `×${combo}`;
      if (combo >= 2 && combo !== lastCombo) { comboEl.classList.remove('bump'); void comboEl.offsetWidth; comboEl.classList.add('bump'); }
      lastCombo = combo;
    }

    function renderConstellation(v) {
      constEl.replaceChildren();
      if (!settings().constellation || !v || session.status !== 'playing') return;
      const pts = [];
      for (let i = 0; i < 81; i++) if (session.board[i] === v) pts.push([colOf(i) + 0.5, rowOf(i) + 0.5]);
      if (pts.length < 2) return;
      for (let a = 0; a < pts.length; a++) {
        for (let b = a + 1; b < pts.length; b++) {
          const line = document.createElementNS(SVG_NS, 'line');
          line.setAttribute('x1', pts[a][0]); line.setAttribute('y1', pts[a][1]);
          line.setAttribute('x2', pts[b][0]); line.setAttribute('y2', pts[b][1]);
          constEl.appendChild(line);
        }
      }
      for (const [x, y] of pts) {
        const dot = document.createElementNS(SVG_NS, 'circle');
        dot.setAttribute('cx', x); dot.setAttribute('cy', y); dot.setAttribute('r', 0.07);
        constEl.appendChild(dot);
      }
    }

    let paletteSetKey = null;
    function renderPalette(setKey) {
      const set = SYMBOL_SETS[setKey];
      for (let v = 1; v <= 9; v++) {
        const b = paletteBtns[v - 1];
        if (paletteSetKey !== setKey) {
          b.querySelector('.glyph-svg').innerHTML = set.svgs[v - 1];
          b.style.setProperty('--gc', set.colors[v - 1]);
          b.setAttribute('aria-label', `${notesMode ? 'Note' : 'Place'} ${set.names[v - 1]}`);
          b.title = set.names[v - 1];
        }
        const left = session.remaining(v);
        b.querySelector('.glyph-count').textContent = left > 0 ? left : '';
        b.classList.toggle('done', left === 0);
        b.classList.toggle('armed', armed === v);
        b.classList.toggle('notes-on', notesMode);
      }
      paletteSetKey = setKey;
    }

    function renderTools() {
      btnUndo.disabled = !session.canUndo;
      notesBadge.textContent = notesMode ? 'ON' : 'OFF';
      btnNotes.classList.toggle('active', notesMode);
      btnNotes.setAttribute('aria-pressed', String(notesMode));
      if (session.zen || !adsSupported) {
        hintBadge.textContent = session.zen ? '∞' : '';
        hintBadge.hidden = !session.zen;
      } else {
        hintBadge.hidden = false;
        const left = session.freeHintsLeft;
        hintBadge.innerHTML = '';
        if (left > 0) hintBadge.textContent = left;
        else hintBadge.appendChild(icon('ad', 'badge-ico'));
      }
    }

    function renderLives() {
      if (session.zen) {
        livesEl.innerHTML = '<span class="lives-zen">∞ Zen</span>';
        return;
      }
      if (livesEl.dataset.m === String(session.mistakes)) return;
      livesEl.dataset.m = String(session.mistakes);
      clear(livesEl);
      for (let k = 0; k < MAX_MISTAKES; k++) {
        livesEl.appendChild(h('span', { class: `life${k < MAX_MISTAKES - session.mistakes ? '' : ' lost'}` }));
      }
      livesEl.setAttribute('aria-label', `${session.livesLeft} lives left`);
    }

    function renderTimer() {
      const show = settings().showTimer && !session.zen;
      timerEl.parentElement.hidden = !show;
      timerEl.textContent = formatTime(session.elapsedMs);
    }

    function setStatus(msg, kind = 'info') {
      statusEl.textContent = msg || '';
      statusEl.className = `status-line${kind ? ` ${kind}` : ''}`;
    }

    function flash(cellsToFlash, cls, ms) {
      for (const c of cellsToFlash) flashing.set(c, cls);
      render();
      setTimeout(() => {
        for (const c of cellsToFlash) if (flashing.get(c) === cls) flashing.delete(c);
        render();
      }, ms);
    }

    // ---------- Input ----------
    function onCellTap(i) {
      if (paused || session.status !== 'playing') return;
      if (settings().inputMode === 'glyph' && armed && !session.fixed[i] && !session.board[i]) {
        selected = i;
        applyGlyph(i, armed);
        return;
      }
      selected = i;
      sfx.select();
      haptic('select');
      const v = session.board[i];
      if (v) {
        const setKey = setKeyFor(session);
        const left = session.remaining(v);
        setStatus(`${glyphName(setKey, v)}${left ? ` · ${left} still hidden` : ' · all found'}`, 'name');
      } else if (statusEl.classList.contains('name')) setStatus('');
      render();
    }

    function onGlyph(v) {
      if (paused || session.status !== 'playing') return;
      if (settings().inputMode === 'glyph') {
        armed = armed === v ? null : v;
        sfx.select();
        haptic('select');
        if (armed) setStatus(`${glyphName(setKeyFor(session), v)} ready: tap empty cells to place it`, 'name');
        else setStatus('');
        if (armed && selected != null && !session.fixed[selected] && !session.board[selected]) {
          applyGlyph(selected, v);
          return;
        }
        render();
        return;
      }
      if (selected == null) { setStatus('Select a cell first.'); return; }
      applyGlyph(selected, v);
    }

    function applyGlyph(i, v) {
      if (session.fixed[i]) { setStatus('Sealed glyph — it cannot be changed.'); haptic('warning'); return; }
      if (notesMode) {
        if (session.board[i]) { setStatus('Erase the cell first to add notes.'); return; }
        const r = session.toggleNote(i, v);
        if (r.result === 'added' || r.result === 'removed') { sfx.note(); haptic('select'); }
        setStatus('');
        render();
        scheduleSave();
        return;
      }
      const r = session.place(i, v);
      if (r.result === 'same') return;
      if (r.result === 'rejected') {
        const setKey = setKeyFor(session);
        sfx.reject();
        haptic('error');
        // Show the wrong glyph briefly, then clear.
        cellCache[i] = '';
        cells[i].innerHTML = `<span class="cell-glyph">${glyphSvg(setKey, v)}</span>`;
        cells[i].classList.add('reject');
        setTimeout(() => { cells[i].classList.remove('reject'); cellCache[i] = ''; render(); }, 560);
        renderLives();
        livesEl.classList.remove('shake'); void livesEl.offsetWidth; livesEl.classList.add('shake');
        if (r.lost) {
          setStatus('Signal lost.', 'error');
          scheduleSave(true);
          setTimeout(onLose, 750);
        } else if (session.zen) {
          setStatus(`${glyphName(setKey, v)} doesn't belong there.`, 'error');
        } else {
          const left = session.livesLeft;
          setStatus(`Glyph rejected — ${left} ${left === 1 ? 'life' : 'lives'} left.`, 'error');
        }
        scheduleSave();
        return;
      }
      if (r.result === 'placed') {
        sfx.place();
        haptic('light');
        setStatus('');
        if (session.remaining(v) === 0 && armed === v) armed = null;
        afterPlacement(r, i);
      }
    }

    function afterPlacement(r, i) {
      const setKey = setKeyFor(session);
      const color = glyphColor(setKey, session.board[i]);
      flashing.set(i, 'pop');
      setTimeout(() => { if (flashing.get(i) === 'pop') { flashing.delete(i); cellCache[i] = ''; render(); } }, 650);
      const [x, y] = cellCenter(i);
      fx.burst(x, y, color, r.combo >= 5 ? 22 : 14);
      scorePop(i, r.points, r.combo);
      if (r.units?.length) {
        const unitCells = new Set();
        for (const k of r.units) for (const c of session.unitCells(k)) unitCells.add(c);
        if (!r.won) { sfx.complete(); haptic('medium'); }
        fx.shower([...unitCells].map(cellCenter), `rgb(${THEMES[setKey]?.rgb.c1 || '57, 255, 156'})`);
        flash([...unitCells].filter((c) => c !== i), 'complete-flash', 1500);
      } else {
        render();
      }
      scheduleSave();
      if (r.won) onWin();
    }

    function doErase() {
      if (paused || selected == null || session.status !== 'playing') return;
      const r = session.erase(selected);
      if (r.result === 'erased') { sfx.erase(); haptic('light'); render(); scheduleSave(); }
      else if (r.result === 'blocked' && session.fixed[selected]) setStatus('Sealed glyph — it cannot be changed.');
    }

    function doUndo() {
      if (paused) return;
      const r = session.undo();
      if (!r) return;
      sfx.erase();
      haptic('light');
      if (r.i != null) selected = r.i;
      render();
      scheduleSave();
    }

    function toggleNotes() {
      if (paused) return;
      notesMode = !notesMode;
      sfx.select();
      haptic('select');
      setStatus(notesMode ? 'Notes ON — glyphs go in as small candidates.' : 'Notes OFF — glyphs go in as answers.');
      paletteSetKey = null; // refresh aria labels
      render();
    }

    async function doHint() {
      if (paused || session.status !== 'playing') return;
      const needsAd = adsSupported && !session.zen && session.freeHintsLeft <= 0;
      if (needsAd) {
        pauseTimer();
        const ok = await new Promise((resolve) => {
          openModal({
            title: 'Out of free hints',
            eyebrow: 'Incoming transmission',
            body: h('p', { class: 'modal-text' }, 'Watch a short video to decode one more cell?'),
            actions: [
              { label: 'Not now', kind: 'ghost', onClick: () => resolve(false) },
              { label: 'Watch video', kind: 'primary', icon: 'ad', autofocus: true, onClick: () => resolve(true) },
            ],
            onClose: (why) => { if (why === 'dismiss') resolve(false); },
          });
        });
        if (!ok) { resumeTimer(); return; }
        const res = await showRewarded();
        resumeTimer();
        if (res === 'cancelled') { toast('Video closed early — no hint this time.'); return; }
        if (res === 'unavailable') toast('No video available right now — this one is on us.');
      }
      const target = selected != null && !session.fixed[selected] && !session.board[selected] ? selected : null;
      const r = session.hint(target);
      if (!r) return;
      selected = r.i;
      const setKey = setKeyFor(session);
      const name = glyphName(setKey, r.value);
      const textFn = HINT_TEXT[r.technique] || HINT_TEXT.reveal;
      setStatus(textFn(name, UNIT_WORD[r.unit?.type] || 'unit'), 'hint');
      sfx.hint();
      haptic('medium');
      if (r.unit) {
        const key = `${r.unit.type}:${r.unit.index}`;
        flash(session.unitCells(key).filter((c) => c !== r.i), 'hint-unit', 1600);
      }
      flash([r.i], 'hint-reveal', 1300);
      afterPlacement(r, r.i);
    }

    // ---------- Keyboard ----------
    function onKey(e) {
      if (document.querySelector('.modal-overlay:not(.closing)')) return;
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLSelectElement) return;
      const k = e.key;
      if ((e.ctrlKey || e.metaKey) && (k === 'z' || k === 'Z')) { doUndo(); e.preventDefault(); return; }
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      if (k === 'p' || k === 'P' || k === ' ' && paused) { paused ? resume() : openPauseMenu(); e.preventDefault(); return; }
      if (paused) return;
      const move = { ArrowUp: [-1, 0], ArrowDown: [1, 0], ArrowLeft: [0, -1], ArrowRight: [0, 1], w: [-1, 0], s: [1, 0], a: [0, -1], d: [0, 1], W: [-1, 0], S: [1, 0], A: [0, -1], D: [0, 1] }[k];
      if (move) {
        const cur = selected ?? 40;
        const r = (rowOf(cur) + move[0] + 9) % 9;
        const c = (colOf(cur) + move[1] + 9) % 9;
        selected = r * 9 + c;
        render();
        e.preventDefault();
        return;
      }
      if (/^[1-9]$/.test(k)) {
        if (selected == null) { setStatus('Select a cell first (arrow keys or click).'); return; }
        applyGlyph(selected, Number(k));
        e.preventDefault();
        return;
      }
      if (k === 'Backspace' || k === 'Delete' || k === '0' || k === 'x' || k === 'X') { doErase(); e.preventDefault(); return; }
      if (k === 'n' || k === 'N') { toggleNotes(); e.preventDefault(); return; }
      if (k === 'u' || k === 'U') { doUndo(); e.preventDefault(); return; }
      if (k === 'h' || k === 'H') { doHint(); e.preventDefault(); return; }
    }

    // ---------- Timer / saving ----------
    function tick() {
      const now = performance.now();
      const dt = now - lastTick;
      lastTick = now;
      if (!paused && session.status === 'playing' && !document.hidden && dt < 5000) {
        session.tick(dt);
        renderTimer();
      }
    }
    function startTimer() { stopTimer(); lastTick = performance.now(); timerId = setInterval(tick, 250); }
    function stopTimer() { if (timerId) clearInterval(timerId); timerId = null; }
    let timerHeld = 0;
    function pauseTimer() { timerHeld++; tick(); stopTimer(); }
    function resumeTimer() { timerHeld = Math.max(0, timerHeld - 1); if (!timerHeld && !paused) startTimer(); }

    function scheduleSave(now = false) {
      if (finished) return;
      clearTimeout(saveTimer);
      const doSave = () => { if (!finished) storeSavedGame(session.snapshot()); };
      if (now) doSave(); else saveTimer = setTimeout(doSave, 400);
    }

    // ---------- Pause ----------
    function pause() {
      if (paused || session.status !== 'playing') return;
      tick();
      paused = true;
      stopTimer();
      boardWrap.classList.add('paused');
      pauseCover.hidden = false;
      scheduleSave(true);
    }
    function resume() {
      if (!paused) return;
      paused = false;
      boardWrap.classList.remove('paused');
      pauseCover.hidden = true;
      startTimer();
    }

    function openPauseMenu() {
      if (session.status !== 'playing') return;
      pause();
      const s = settings();
      openModal({
        title: 'Paused',
        eyebrow: `${t.eyebrow} · ${formatTime(session.elapsedMs)}`,
        className: 'pause-menu',
        body: h('div', { class: 'pause-grid' },
          pauseItem('notes', 'Fill in all notes', 'Auto-candidates for every empty cell', () => { session.autoNotes(); sfx.hint(); render(); scheduleSave(); }),
          pauseItem('erase', 'Clear all notes', null, () => { session.clearAllNotes(); render(); scheduleSave(); }),
          pauseItem('restart', 'Restart puzzle', 'Back to the starting glyphs (time and lives stay)', async () => {
            if (await confirmModal({ title: 'Restart puzzle?', message: 'All glyphs and notes you placed will be cleared.', confirmLabel: 'Restart' })) {
              session.restart(); selected = null; render(); scheduleSave(); resume();
            }
          }),
          pauseItem('settings', 'Settings', null, () => nav.go('settings')),
          pauseItem('help', 'How to play', null, () => nav.go('howto')),
          h('label', { class: 'pause-toggle' },
            h('input', { type: 'checkbox', checked: s.inputMode === 'glyph', onchange: (e) => { setSetting('inputMode', e.target.checked ? 'glyph' : 'cell'); armed = null; render(); } }),
            h('span', {}, 'Glyph-first input (pick a glyph, then tap cells)'))),
        actions: [
          { label: 'Quit to menu', kind: 'ghost', onClick: () => leave() },
          { label: 'Resume', kind: 'primary', icon: 'play', autofocus: true, onClick: () => resume() },
        ],
        onClose: (why) => { if (why === 'dismiss') resume(); },
      });
    }

    function pauseItem(ico, label, sub, fn) {
      return h('button', { class: 'pause-item', type: 'button', onclick: (e) => { e.currentTarget.closest('.modal-overlay')?.querySelector('.modal-x')?.click(); fn(); } },
        icon(ico), h('span', { class: 'pause-item-text' }, h('span', {}, label), sub ? h('small', {}, sub) : null));
    }

    // ---------- Win / lose ----------
    function resultPayload(won) {
      return {
        mode: session.mode, difficulty: session.difficulty, won, ms: Math.round(session.elapsedMs),
        mistakes: session.mistakes, hints: session.hints, revived: session.revived, notes: session.notesPlaced,
        zen: session.zen, sector: session.sector, level: session.level, date: session.date,
        score: session.score, bestCombo: session.bestCombo,
      };
    }

    function onWin() {
      tick();
      stopTimer();
      finished = true;
      clearTimeout(saveTimer);
      clearSavedGame();
      selected = null;
      armed = null;
      const res = recordResult(resultPayload(true));
      noteGameFinished();
      sfx.win();
      haptic('success');
      boardWrap.classList.add('won');
      render();
      const wr = boardWrap.getBoundingClientRect();
      fx.fireworks(SYMBOL_SETS[setKeyFor(session)].colors, wr.width, wr.height);
      setStatus('Transmission decoded!', 'success');
      setTimeout(() => showWinModal(res), 1100);
    }

    function showWinModal(res) {
      const stars = session.zen ? 0 : starsFor(session);
      const best = session.zen ? null : getProfile().stats.byDiff[session.difficulty]?.bestMs;
      const body = [
        !session.zen ? h('div', { class: 'stars-row', 'aria-label': `${stars} of 3 stars` },
          [1, 2, 3].map((n) => h('span', { class: `big-star${n <= stars ? ' on' : ''}`, style: { animationDelay: `${n * 0.18}s` } }, icon('star')))) : null,
        !session.zen ? h('div', { class: 'result-score' },
          h('small', {}, 'Score'),
          h('b', {}, session.score.toLocaleString()),
          h('span', {}, `includes +${session.winBonus.toLocaleString()} finish bonus · best combo ×${session.bestCombo}`),
          res.newHighScore ? h('span', { class: 'badge-new' }, 'New high score!') : null) : null,
        h('div', { class: 'result-grid' },
          resultStat('Time', formatTime(session.elapsedMs), res.newBest ? 'New best!' : null),
          !session.zen ? resultStat('Best', formatTime(best)) : null,
          resultStat('Mistakes', String(session.mistakes)),
          resultStat('Hints', String(session.hints))),
        res.streak ? h('div', { class: 'result-streak' }, icon('fire'), ` ${res.streak}-day streak`) : null,
        res.unlockedSets.length ? h('div', { class: 'result-unlocks' },
          res.unlockedSets.map((k) => h('div', { class: 'unlock-row' },
            h('span', { class: 'unlock-glyphs', html: SYMBOL_SETS[k].svgs.slice(0, 3).join('') }),
            h('span', {}, `New symbol set: ${SYMBOL_SETS[k].name}`)))) : null,
        res.achievements.length ? h('div', { class: 'result-achievements' },
          res.achievements.map((a) => h('div', { class: 'ach-row' }, h('span', { class: 'ach-ico' }, a.icon), h('span', {}, h('b', {}, a.name), h('small', {}, a.desc))))) : null,
      ];

      let actions;
      if (session.mode === 'campaign') {
        const next = nextLevelAfter(session.sector, session.level);
        actions = [
          { label: 'Sector map', kind: 'ghost', onClick: () => afterResult(() => nav.replace('sector', { sector: session.sector })) },
          next
            ? { label: next.sector !== session.sector ? `Enter ${SECTORS[next.sector].name}` : 'Next transmission', kind: 'primary', icon: 'play', autofocus: true,
                onClick: () => afterResult(() => nav.replace('play', { mode: 'campaign', ...next })) }
            : { label: 'Campaign complete!', kind: 'primary', icon: 'trophy', autofocus: true, onClick: () => afterResult(() => nav.replace('campaign')) },
        ];
      } else if (session.mode === 'daily') {
        actions = [
          { label: 'Menu', kind: 'ghost', onClick: () => afterResult(() => nav.reset('menu')) },
          { label: 'Daily calendar', kind: 'primary', icon: 'calendar', autofocus: true, onClick: () => afterResult(() => nav.replace('daily')) },
        ];
      } else {
        actions = [
          { label: 'Menu', kind: 'ghost', onClick: () => afterResult(() => nav.reset('menu')) },
          { label: 'New puzzle', kind: 'primary', icon: 'play', autofocus: true, onClick: () => afterResult(() => nav.replace('play', { mode: session.mode, difficulty: session.difficulty })) },
        ];
      }
      openModal({
        eyebrow: sessionTitle(session).eyebrow,
        title: 'Transmission decoded',
        className: 'win-modal',
        body,
        actions,
        dismissible: false,
      });
    }

    function onLose() {
      stopTimer();
      sfx.gameOver();
      haptic('error');
      boardWrap.classList.add('lost');
      const canRevive = !session.revived;
      const actions = [];
      if (canRevive) {
        actions.push({
          label: adsSupported ? 'Second chance (video)' : 'Second chance', kind: 'primary', icon: adsSupported ? 'ad' : 'restart', autofocus: true,
          onClick: async () => {
            const res = await showRewarded();
            if (res === 'cancelled') { toast('Video closed early.'); onLose(); return; }
            session.revive();
            boardWrap.classList.remove('lost');
            setStatus('Second chance — one life restored.', 'success');
            startTimer();
            render();
            scheduleSave(true);
          },
        });
      }
      actions.push(
        { label: 'Retry puzzle', kind: canRevive ? 'ghost' : 'primary', onClick: () => { recordLoss(); afterResult(() => nav.replace('play', retryParams())); } },
        session.mode === 'quick' ? { label: 'New puzzle', kind: 'ghost', onClick: () => { recordLoss(); afterResult(() => nav.replace('play', { mode: 'quick', difficulty: session.difficulty })); } } : null,
        { label: 'Menu', kind: 'ghost', onClick: () => { recordLoss(); afterResult(() => nav.reset('menu')); } },
      );
      openModal({
        eyebrow: sessionTitle(session).eyebrow,
        title: 'Signal lost',
        className: 'lose-modal',
        body: h('p', { class: 'modal-text' }, canRevive
          ? `Three glyphs were rejected. Take a second chance with one life restored, or try again.`
          : 'The transmission is lost. Try again, Decoder.'),
        actions: actions.filter(Boolean),
        dismissible: false,
      });
    }

    function recordLoss() {
      if (finished) return;
      finished = true;
      clearSavedGame();
      recordResult(resultPayload(false));
      noteGameFinished();
    }

    function retryParams() {
      if (session.mode === 'campaign') return { mode: 'campaign', sector: session.sector, level: session.level };
      if (session.mode === 'daily') return { mode: 'daily', date: session.date };
      return { mode: session.mode, snapshot: freshSnapshot() };
    }

    function freshSnapshot() {
      const s = new GameSession({ ...session.snapshot(), board: null, fixed: null, hinted: null, notes: null, mistakes: 0, hints: 0, revived: false, elapsedMs: 0, status: 'playing', completedUnits: null, notesPlaced: 0 });
      return s.snapshot();
    }

    async function afterResult(navigate) {
      await maybeShowInterstitial();
      navigate();
    }

    function leave() {
      if (session.status === 'playing') scheduleSave(true);
      nav.reset('menu');
    }

    // ---------- Lifecycle ----------
    unsubs.push(on('settings', ({ key }) => {
      if (key === 'autoRemoveNotes') session.autoRemoveNotes = settings().autoRemoveNotes;
      if (key === 'reduceMotion') fx.setEnabled(!settings().reduceMotion);
      cellCache.fill('');
      paletteSetKey = null;
      render();
    }));
    unsubs.push(on('app-pause', () => { if (session.status === 'playing') { pause(); } }));

    if (session.status === 'lost') setTimeout(onLose, 300);
    if (session.status === 'won') { finished = true; clearSavedGame(); }
    else if (!params.resume) scheduleSave(true);

    return {
      el,
      session,
      onShow() {
        document.addEventListener('keydown', onKey);
        cellCache.fill('');
        paletteSetKey = null;
        fitBoard();
        render();
        if (!paused && session.status === 'playing') startTimer();
        if (firstShow) { firstShow = false; music.next(); }
        if (!settings().seenTutorial) {
          setSetting('seenTutorial', true);
          setStatus('Tap a cell, then tap a glyph. Each glyph appears once per row, column and box.', 'hint');
        }
      },
      onHide() {
        document.removeEventListener('keydown', onKey);
        tick();
        stopTimer();
        if (session.status === 'playing') scheduleSave(true);
      },
      onBack() {
        if (session.status === 'playing' && !paused) { openPauseMenu(); return true; }
        leave();
        return true;
      },
      destroy() {
        fx.destroy();
        ro.disconnect();
        unsubs.forEach((u) => u());
        clearTimeout(saveTimer);
        stopTimer();
      },
    };
  },
};

function toolBtn(ico, label, fn) {
  return h('button', { class: 'tool-btn', type: 'button', 'aria-label': label, onclick: fn }, icon(ico), h('span', { class: 'tool-label' }, label));
}

function resultStat(label, value, badge) {
  return h('div', { class: 'result-stat' }, h('small', {}, label), h('b', {}, value), badge ? h('span', { class: 'badge-new' }, badge) : null);
}

export function nextLevelAfter(sector, level) {
  if (level + 1 < LEVELS_PER_SECTOR) return { sector, level: level + 1 };
  if (sector + 1 < SECTORS.length) return { sector: sector + 1, level: 0 };
  return null;
}
