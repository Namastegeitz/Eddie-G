/* ============================================================
   GameSession — one puzzle being played. Pure logic, no DOM,
   so it can be unit-tested and saved/restored as JSON.

   Values are 1..9 (glyph index + 1), 0 = empty. Cells are
   indexed 0..80 (row * 9 + col). Notes are 9-bit masks.

   Rules carried over from the original game:
   - A wrong glyph is rejected (never kept) and costs a life.
   - 3 lives; at 0 the game is lost (unless Zen mode).
   - Erasing never costs anything.
   ============================================================ */

import { PEERS, ROWS, COLS, BOXES, computeCandidates } from '../engine/sudoku.js';
import { findSingle } from '../engine/logic.js';

export const MAX_MISTAKES = 3;
export const FREE_HINTS = 3;
const UNDO_LIMIT = 200;

const rowOf = (i) => Math.floor(i / 9);
const colOf = (i) => i % 9;
const boxOf = (i) => Math.floor(rowOf(i) / 3) * 3 + Math.floor(colOf(i) / 3);
const bit = (v) => 1 << (v - 1);

export class GameSession {
  /**
   * @param {object} o
   * @param {number[]} o.puzzle    81 values, 0 = empty
   * @param {number[]} o.solution  81 values
   * @param {string}   o.mode      'quick' | 'campaign' | 'daily' | 'zen'
   * @param {string}   o.difficulty
   */
  constructor(o) {
    this.puzzleId = o.puzzleId || null;
    this.mode = o.mode || 'quick';
    this.difficulty = o.difficulty || 'medium';
    this.sector = o.sector ?? null;
    this.level = o.level ?? null;
    this.date = o.date ?? null;
    this.zen = this.mode === 'zen';
    this.symbolSet = o.symbolSet || null;
    this.bg = o.bg || null;

    this.puzzle = o.puzzle.slice();
    this.solution = o.solution.slice();
    this.board = o.board ? o.board.slice() : o.puzzle.slice();
    this.fixed = o.fixed ? o.fixed.slice() : o.puzzle.map((v) => v !== 0);
    this.hinted = o.hinted ? o.hinted.slice() : new Array(81).fill(false);
    this.notes = o.notes ? o.notes.slice() : new Array(81).fill(0);

    this.mistakes = o.mistakes || 0;
    this.hints = o.hints || 0;
    this.notesPlaced = o.notesPlaced || 0;
    this.revived = !!o.revived;
    this.elapsedMs = o.elapsedMs || 0;
    this.status = o.status || 'playing'; // 'playing' | 'won' | 'lost'
    this.autoRemoveNotes = o.autoRemoveNotes ?? true;
    this.undoStack = [];
    this.completedUnits = new Set(o.completedUnits || []);
    if (!o.completedUnits) this._recomputeCompletedUnits();
  }

  static fromSnapshot(s) { return new GameSession(s); }

  snapshot() {
    return {
      v: 1,
      puzzleId: this.puzzleId, mode: this.mode, difficulty: this.difficulty,
      sector: this.sector, level: this.level, date: this.date,
      symbolSet: this.symbolSet, bg: this.bg,
      puzzle: this.puzzle, solution: this.solution, board: this.board,
      fixed: this.fixed, hinted: this.hinted, notes: this.notes,
      mistakes: this.mistakes, hints: this.hints, notesPlaced: this.notesPlaced,
      revived: this.revived, elapsedMs: Math.round(this.elapsedMs), status: this.status,
      completedUnits: [...this.completedUnits],
    };
  }

  // ---------------- Queries ----------------
  get playing() { return this.status === 'playing'; }
  get livesLeft() { return this.zen ? Infinity : Math.max(0, MAX_MISTAKES - this.mistakes); }
  get freeHintsLeft() { return this.zen ? Infinity : Math.max(0, FREE_HINTS - this.hints); }
  get filledCount() { return this.board.reduce((n, v) => n + (v ? 1 : 0), 0); }
  get hasProgress() { return this.board.some((v, i) => v && !this.puzzle[i]) || this.notes.some((m) => m) || this.mistakes > 0; }

  isEditable(i) { return !this.fixed[i]; }

  /** How many of glyph v are still missing from the board. */
  remaining(v) {
    let n = 0;
    for (let i = 0; i < 81; i++) if (this.board[i] === v) n++;
    return 9 - n;
  }

  // ---------------- Moves ----------------
  /**
   * Try to place v (1..9) in cell i.
   * Returns { result: 'placed'|'rejected'|'fixed'|'same'|'over', units: [unitKey], won, lost }
   */
  place(i, v) {
    if (!this.playing) return { result: 'over' };
    if (this.fixed[i]) return { result: 'fixed' };
    if (this.board[i] === v) return { result: 'same' };

    if (v !== this.solution[i]) {
      this.mistakes++;
      const lost = !this.zen && this.mistakes >= MAX_MISTAKES;
      if (lost) this.status = 'lost';
      return { result: 'rejected', lost, wrongValue: v };
    }

    const entry = { i, prevValue: this.board[i], prevNotes: this.notes[i], peerNotes: [] };
    this.board[i] = v;
    this.notes[i] = 0;
    if (this.autoRemoveNotes) {
      for (const p of PEERS[i]) {
        if (this.notes[p] & bit(v)) {
          entry.peerNotes.push([p, this.notes[p]]);
          this.notes[p] &= ~bit(v);
        }
      }
    }
    this._pushUndo(entry);
    const units = this._newlyCompletedUnits(i);
    const won = this._checkWin();
    return { result: 'placed', units, won };
  }

  /** Toggle pencil mark v in empty cell i. */
  toggleNote(i, v) {
    if (!this.playing || this.fixed[i] || this.board[i]) return { result: 'blocked' };
    this._pushUndo({ i, prevValue: 0, prevNotes: this.notes[i], peerNotes: [] });
    const had = this.notes[i] & bit(v);
    this.notes[i] ^= bit(v);
    if (!had) this.notesPlaced++;
    return { result: had ? 'removed' : 'added' };
  }

  /** Clear value and notes of cell i. */
  erase(i) {
    if (!this.playing || this.fixed[i]) return { result: 'blocked' };
    if (!this.board[i] && !this.notes[i]) return { result: 'empty' };
    this._pushUndo({ i, prevValue: this.board[i], prevNotes: this.notes[i], peerNotes: [] });
    this.board[i] = 0;
    this.notes[i] = 0;
    this._recomputeCompletedUnits();
    return { result: 'erased' };
  }

  /** Fill every empty cell's notes with its legal candidates. */
  autoNotes() {
    if (!this.playing) return { result: 'over' };
    const cands = computeCandidates(this.board);
    this._pushUndo({ allNotes: this.notes.slice() });
    for (let i = 0; i < 81; i++) this.notes[i] = this.board[i] ? 0 : cands[i];
    return { result: 'filled' };
  }

  clearAllNotes() {
    if (!this.playing || !this.notes.some((m) => m)) return { result: 'empty' };
    this._pushUndo({ allNotes: this.notes.slice() });
    this.notes.fill(0);
    return { result: 'cleared' };
  }

  undo() {
    if (!this.playing) return null;
    const e = this.undoStack.pop();
    if (!e) return null;
    if (e.allNotes) {
      this.notes = e.allNotes;
      return { i: null };
    }
    this.board[e.i] = e.prevValue;
    this.notes[e.i] = e.prevNotes;
    for (const [p, mask] of e.peerNotes) this.notes[p] = mask;
    this._recomputeCompletedUnits();
    return { i: e.i };
  }

  get canUndo() { return this.playing && this.undoStack.length > 0; }

  /**
   * Hint. If `selected` is an empty editable cell, reveal it. Otherwise find
   * the easiest logical single on the board and reveal that, with the reason.
   * Returns { i, value, technique, unit, units, won } or null.
   */
  hint(selected = null) {
    if (!this.playing) return null;
    let i = null;
    let technique = 'reveal';
    let unit = null;

    if (selected != null && !this.fixed[selected] && !this.board[selected]) {
      i = selected;
      // If the selected cell happens to be a logical single, explain it.
      const step = safeFindSingle(this.board);
      if (step && step.placement && step.placement.idx === i) { technique = step.technique; unit = step.unit; }
    } else {
      const step = safeFindSingle(this.board);
      if (step && step.placement) {
        i = step.placement.idx;
        technique = step.technique;
        unit = step.unit;
      } else {
        // No single available: reveal the empty cell with the fewest candidates.
        const cands = computeCandidates(this.board);
        let best = 10;
        for (let k = 0; k < 81; k++) {
          if (this.board[k]) continue;
          const n = popcount(cands[k]);
          if (n < best) { best = n; i = k; }
        }
      }
    }
    if (i == null) return null;

    const value = this.solution[i];
    this.board[i] = value;
    this.notes[i] = 0;
    this.fixed[i] = true;
    this.hinted[i] = true;
    this.hints++;
    if (this.autoRemoveNotes) for (const p of PEERS[i]) this.notes[p] &= ~bit(value);
    // Undo history can't step back over a locked hint cell.
    this.undoStack = this.undoStack.filter((e) => e.i !== i);
    const units = this._newlyCompletedUnits(i);
    const won = this._checkWin();
    return { i, value, technique, unit, units, won };
  }

  /** Second chance after losing: one life back. */
  revive() {
    if (this.status !== 'lost') return false;
    this.mistakes = MAX_MISTAKES - 1;
    this.status = 'playing';
    this.revived = true;
    return true;
  }

  /** Back to the starting clues (keeps time, mistakes and hints). */
  restart() {
    this.board = this.puzzle.slice();
    this.notes.fill(0);
    for (let i = 0; i < 81; i++) if (this.hinted[i]) this.board[i] = this.solution[i];
    this.undoStack = [];
    this._recomputeCompletedUnits();
  }

  tick(ms) { if (this.playing) this.elapsedMs += ms; }

  // ---------------- Internals ----------------
  _pushUndo(e) {
    this.undoStack.push(e);
    if (this.undoStack.length > UNDO_LIMIT) this.undoStack.shift();
  }

  _unitCells(key) {
    const [type, n] = key.split(':');
    return (type === 'row' ? ROWS : type === 'col' ? COLS : BOXES)[Number(n)];
  }

  _unitDone(cells) { return cells.every((c) => this.board[c] === this.solution[c]); }

  _newlyCompletedUnits(i) {
    const fresh = [];
    for (const key of [`row:${rowOf(i)}`, `col:${colOf(i)}`, `box:${boxOf(i)}`]) {
      if (this.completedUnits.has(key)) continue;
      if (this._unitDone(this._unitCells(key))) { this.completedUnits.add(key); fresh.push(key); }
    }
    return fresh;
  }

  _recomputeCompletedUnits() {
    this.completedUnits = new Set();
    for (let n = 0; n < 9; n++) {
      if (this._unitDone(ROWS[n])) this.completedUnits.add(`row:${n}`);
      if (this._unitDone(COLS[n])) this.completedUnits.add(`col:${n}`);
      if (this._unitDone(BOXES[n])) this.completedUnits.add(`box:${n}`);
    }
  }

  _checkWin() {
    for (let i = 0; i < 81; i++) if (this.board[i] !== this.solution[i]) return false;
    this.status = 'won';
    return true;
  }

  unitCells(key) { return this._unitCells(key); }
}

function popcount(m) { let n = 0; while (m) { m &= m - 1; n++; } return n; }

function safeFindSingle(board) {
  try { return findSingle(board); } catch { return null; }
}
