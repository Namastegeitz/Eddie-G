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

/** Classic rule: 3 tries. Players can choose up to 25 (Settings → Tries per puzzle). */
export const MAX_MISTAKES = 3;
export const TRIES_CHOICES = [3, 5, 10, 25];
export const DEFAULT_TRIES = 25;
/** Tries the visitors give back with their gift (second chance). */
export const reviveTriesFor = (maxTries) => Math.max(1, Math.round(maxTries / 5));
export const FREE_HINTS = 3;
const UNDO_LIMIT = 200;

// Scoring: every correct glyph scores once per cell; quick consecutive correct
// moves build a combo; finished rows/columns/boxes and the win add bonuses.
export const DIFF_MULT = { easy: 1, medium: 1.5, hard: 2, alien: 3 };
export const COMBO_WINDOW_MS = 8000;
export const MAX_COMBO_STEP = 10;
const BASE_POINTS = 10;
const UNIT_POINTS = 50;
const WIN_POINTS = 200;
const PERFECT_POINTS = 300;
const PAR_SECONDS = { easy: 300, medium: 600, hard: 900, alien: 1500 };

const rowOf = (i) => Math.floor(i / 9);
const colOf = (i) => i % 9;
const boxOf = (i) => Math.floor(rowOf(i) / 3) * 3 + Math.floor(colOf(i) / 3);
const bit = (v) => 1 << (v - 1);

export class GameSession {
  /**
   * @param {object} o
   * @param {number[]} o.puzzle    81 values, 0 = empty
   * @param {number[]} o.solution  81 values
   * @param {string}   o.mode      'quick' | 'campaign' | 'daily' | 'zen' | 'duel'
   * @param {object}  [o.duel]     Alien Duel only: { rival (resolved config), seed, clock, outcome }
   *                               outcome: null while racing, then 'player' or 'rival' (who finished first)
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
    this.maxMistakes = Math.min(25, Math.max(1, o.maxMistakes || MAX_MISTAKES));
    this.symbolSet = o.symbolSet || null;
    this.bg = o.bg || null;
    this.duel = this.mode === 'duel' && o.duel ? { clock: 0, outcome: null, ...o.duel } : null;

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

    this.score = o.score || 0;
    this.combo = o.combo || 0;
    this.bestCombo = o.bestCombo || 0;
    this.lastCorrectAt = o.lastCorrectAt ?? null;
    this.scoredCells = new Set(o.scoredCells || []);
    this.scoredUnits = new Set(o.scoredUnits || [...this.completedUnits]);
    this.winBonus = o.winBonus || 0;
  }

  get diffMult() { return DIFF_MULT[this.difficulty] || 1; }
  get comboMult() { return 1 + (Math.min(this.combo, MAX_COMBO_STEP) - 1) * 0.1; }

  static fromSnapshot(s) { return new GameSession(s); }

  snapshot() {
    return {
      v: 1,
      puzzleId: this.puzzleId, mode: this.mode, difficulty: this.difficulty,
      sector: this.sector, level: this.level, date: this.date,
      symbolSet: this.symbolSet, bg: this.bg,
      duel: this.duel ? { ...this.duel } : null,
      puzzle: this.puzzle, solution: this.solution, board: this.board,
      fixed: this.fixed, hinted: this.hinted, notes: this.notes,
      mistakes: this.mistakes, hints: this.hints, notesPlaced: this.notesPlaced,
      revived: this.revived, elapsedMs: Math.round(this.elapsedMs), status: this.status, maxMistakes: this.maxMistakes,
      completedUnits: [...this.completedUnits],
      score: this.score, combo: this.combo, bestCombo: this.bestCombo, lastCorrectAt: this.lastCorrectAt,
      scoredCells: [...this.scoredCells], scoredUnits: [...this.scoredUnits], winBonus: this.winBonus,
    };
  }

  // ---------------- Queries ----------------
  get playing() { return this.status === 'playing'; }
  get livesLeft() { return this.zen ? Infinity : Math.max(0, this.maxMistakes - this.mistakes); }
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
      this.combo = 0;
      this.lastCorrectAt = null;
      const lost = !this.zen && this.mistakes >= this.maxMistakes;
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
    const points = this._scorePlacement(i, units);
    const won = this._checkWin();
    return { result: 'placed', units, won, points, combo: this.combo };
  }

  /** Points for a correct placement (once per cell) plus any newly finished units. */
  _scorePlacement(i, units) {
    let points = 0;
    if (!this.scoredCells.has(i)) {
      this.scoredCells.add(i);
      const quick = this.lastCorrectAt != null && this.elapsedMs - this.lastCorrectAt <= COMBO_WINDOW_MS;
      this.combo = quick ? this.combo + 1 : 1;
      this.bestCombo = Math.max(this.bestCombo, this.combo);
      this.lastCorrectAt = this.elapsedMs;
      points += Math.round(BASE_POINTS * this.diffMult * this.comboMult);
    }
    for (const u of units) {
      if (this.scoredUnits.has(u)) continue;
      this.scoredUnits.add(u);
      points += Math.round(UNIT_POINTS * this.diffMult);
    }
    this.score += points;
    return points;
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
    this.scoredCells.add(i);           // a hinted cell never scores
    this.combo = 0;
    this.lastCorrectAt = null;
    const units = this._newlyCompletedUnits(i);
    for (const u of units) this.scoredUnits.add(u);
    const won = this._checkWin();
    return { i, value, technique, unit, units, won, points: 0 };
  }

  /** Second chance after losing: the visitors' gift of a few tries (a fifth of the limit, at least 1). */
  revive() {
    if (this.status !== 'lost') return false;
    this.mistakes = this.maxMistakes - reviveTriesFor(this.maxMistakes);
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
    this.winBonus = this._winBonus();
    this.score += this.winBonus;
    return true;
  }

  _winBonus() {
    const perfect = this.mistakes === 0 && this.hints === 0 ? PERFECT_POINTS : 0;
    const par = PAR_SECONDS[this.difficulty] || 600;
    const timeBonus = Math.max(0, Math.round((par - this.elapsedMs / 1000) / 2));
    return Math.round((WIN_POINTS + perfect + timeBonus) * this.diffMult);
  }

  unitCells(key) { return this._unitCells(key); }
}

function popcount(m) { let n = 0; while (m) { m &= m - 1; n++; } return n; }

function safeFindSingle(board) {
  try { return findSingle(board); } catch { return null; }
}
