import { describe, it, expect } from 'vitest';
import { GameSession, MAX_MISTAKES, FREE_HINTS } from '../../src/game/session.js';
import { getPuzzle } from '../../src/engine/pool.js';
import { PEERS } from '../../src/engine/sudoku.js';

function fresh(mode = 'quick', difficulty = 'easy', seed = 'test') {
  const p = getPuzzle({ difficulty, seed });
  return new GameSession({ puzzleId: p.id, mode, difficulty, puzzle: p.puzzle, solution: p.solution });
}
const firstEmpty = (s) => s.board.findIndex((v) => v === 0);
const wrongFor = (s, i) => (s.solution[i] % 9) + 1;

describe('GameSession', () => {
  it('places correct glyphs and rejects wrong ones', () => {
    const s = fresh();
    const i = firstEmpty(s);
    const bad = s.place(i, wrongFor(s, i));
    expect(bad.result).toBe('rejected');
    expect(s.board[i]).toBe(0);
    expect(s.mistakes).toBe(1);
    const good = s.place(i, s.solution[i]);
    expect(good.result).toBe('placed');
    expect(s.board[i]).toBe(s.solution[i]);
  });

  it('never lets clue cells change', () => {
    const s = fresh();
    const clue = s.puzzle.findIndex((v) => v !== 0);
    expect(s.place(clue, 1).result).toBe('fixed');
    expect(s.erase(clue).result).toBe('blocked');
  });

  it('loses after MAX_MISTAKES, revive gives one life back', () => {
    const s = fresh();
    const i = firstEmpty(s);
    let r;
    for (let k = 0; k < MAX_MISTAKES; k++) r = s.place(i, wrongFor(s, i));
    expect(r.lost).toBe(true);
    expect(s.status).toBe('lost');
    expect(s.place(i, s.solution[i]).result).toBe('over');
    expect(s.revive()).toBe(true);
    expect(s.status).toBe('playing');
    expect(s.livesLeft).toBe(1);
    expect(s.revive()).toBe(false);
  });

  it('zen mode never loses', () => {
    const s = fresh('zen');
    const i = firstEmpty(s);
    for (let k = 0; k < 10; k++) s.place(i, wrongFor(s, i));
    expect(s.status).toBe('playing');
    expect(s.livesLeft).toBe(Infinity);
  });

  it('notes toggle, auto-clear from peers, and undo restores them', () => {
    const s = fresh();
    const i = firstEmpty(s);
    const v = s.solution[i];
    const peer = PEERS[i].find((p) => s.board[p] === 0);
    s.toggleNote(peer, v);
    expect(s.notes[peer] & (1 << (v - 1))).toBeTruthy();
    s.place(i, v);
    expect(s.notes[peer] & (1 << (v - 1))).toBe(0);
    s.undo();
    expect(s.board[i]).toBe(0);
    expect(s.notes[peer] & (1 << (v - 1))).toBeTruthy();
    s.undo();
    expect(s.notes[peer]).toBe(0);
    expect(s.notesPlaced).toBe(1);
  });

  it('autoNotes fills legal candidates and can be undone', () => {
    const s = fresh();
    s.autoNotes();
    const i = firstEmpty(s);
    expect(s.notes[i] & (1 << (s.solution[i] - 1))).toBeTruthy();
    s.undo();
    expect(s.notes.every((m) => m === 0)).toBe(true);
  });

  it('hint reveals a cell, locks it, counts and explains', () => {
    const s = fresh();
    const r = s.hint();
    expect(r).toBeTruthy();
    expect(s.board[r.i]).toBe(s.solution[r.i]);
    expect(s.fixed[r.i]).toBe(true);
    expect(s.hinted[r.i]).toBe(true);
    expect(s.hints).toBe(1);
    expect(['full-house', 'hidden-single', 'naked-single', 'reveal']).toContain(r.technique);
    expect(s.freeHintsLeft).toBe(FREE_HINTS - 1);
  });

  it('hint on a selected empty cell reveals that cell', () => {
    const s = fresh();
    const target = s.board.lastIndexOf(0);
    const r = s.hint(target);
    expect(r.i).toBe(target);
  });

  it('solving every cell wins and reports completed units', () => {
    const s = fresh();
    let last;
    let units = 0;
    for (let i = 0; i < 81; i++) {
      if (s.board[i]) continue;
      last = s.place(i, s.solution[i]);
      units += last.units.length;
    }
    expect(last.won).toBe(true);
    expect(s.status).toBe('won');
    expect(units).toBeGreaterThan(0);
    expect(s.completedUnits.size).toBe(27);
  });

  it('hints alone can finish every difficulty', () => {
    for (const d of ['easy', 'medium', 'hard', 'alien']) {
      const s = fresh('zen', d, `hints-${d}`);
      let guard = 0;
      while (s.status === 'playing' && guard++ < 81) s.hint();
      expect(s.status).toBe('won');
    }
  });

  it('snapshot round-trips', () => {
    const s = fresh('campaign');
    s.sector = 2; s.level = 4;
    const i = firstEmpty(s);
    s.place(i, s.solution[i]);
    s.toggleNote(firstEmpty(s), 3);
    s.tick(12_345);
    const json = JSON.parse(JSON.stringify(s.snapshot()));
    const t = GameSession.fromSnapshot(json);
    expect(t.board).toEqual(s.board);
    expect(t.notes).toEqual(s.notes);
    expect(t.elapsedMs).toBe(12_345);
    expect(t.sector).toBe(2);
    expect(t.level).toBe(4);
    expect([...t.completedUnits]).toEqual([...s.completedUnits]);
  });

  it('restart keeps clues and hinted cells, clears the rest', () => {
    const s = fresh();
    const h = s.hint();
    const i = firstEmpty(s);
    s.place(i, s.solution[i]);
    s.restart();
    expect(s.board[i]).toBe(0);
    expect(s.board[h.i]).toBe(s.solution[h.i]);
    expect(s.canUndo).toBe(false);
  });

  it('remaining() counts missing copies', () => {
    const s = fresh();
    const total = [1, 2, 3, 4, 5, 6, 7, 8, 9].reduce((n, v) => n + s.remaining(v), 0);
    expect(total).toBe(s.board.filter((v) => v === 0).length);
  });
});

describe('scoring', () => {
  const fresh2 = (d = 'medium') => {
    const p = getPuzzle({ difficulty: d, seed: 'score' });
    return new GameSession({ mode: 'quick', difficulty: d, puzzle: p.puzzle, solution: p.solution });
  };
  const empties = (s) => s.board.map((v, i) => (v ? -1 : i)).filter((i) => i >= 0);

  it('quick correct moves build a combo; slow ones reset it', () => {
    const s = fresh2();
    const [a, b, c] = empties(s);
    const r1 = s.place(a, s.solution[a]);
    expect(r1.combo).toBe(1);
    expect(r1.points).toBe(15); // 10 x 1.5
    s.tick(2000);
    const r2 = s.place(b, s.solution[b]);
    expect(r2.combo).toBe(2);
    expect(r2.points).toBeGreaterThanOrEqual(Math.round(10 * 1.5 * 1.1));
    s.tick(9000);
    const r3 = s.place(c, s.solution[c]);
    expect(r3.combo).toBe(1);
  });

  it('a mistake resets the combo', () => {
    const s = fresh2();
    const [a, b] = empties(s);
    s.place(a, s.solution[a]);
    s.place(b, (s.solution[b] % 9) + 1);
    expect(s.combo).toBe(0);
  });

  it('undo and replace cannot farm points', () => {
    const s = fresh2();
    const [a] = empties(s);
    s.place(a, s.solution[a]);
    const after = s.score;
    s.undo();
    const r = s.place(a, s.solution[a]);
    expect(r.points).toBe(0);
    expect(s.score).toBe(after);
  });

  it('winning adds a bonus and the score survives a snapshot', () => {
    const s = fresh2('easy');
    for (const i of empties(s)) s.place(i, s.solution[i]);
    expect(s.status).toBe('won');
    expect(s.winBonus).toBeGreaterThan(0);
    expect(s.bestCombo).toBeGreaterThan(5);
    const t = GameSession.fromSnapshot(JSON.parse(JSON.stringify(s.snapshot())));
    expect(t.score).toBe(s.score);
    expect(t.bestCombo).toBe(s.bestCombo);
  });

  it('hints score nothing', () => {
    const s = fresh2();
    const r = s.hint();
    expect(r.points).toBe(0);
    expect(s.score).toBe(0);
  });
});

describe('tries', () => {
  it('a 25-try puzzle survives 24 mistakes, ends on the 25th, and the gift returns 5', () => {
    const p = getPuzzle({ difficulty: 'easy', seed: 'tries' });
    const s = new GameSession({ mode: 'quick', difficulty: 'easy', puzzle: p.puzzle, solution: p.solution, maxMistakes: 25 });
    const i = s.board.findIndex((v) => v === 0);
    const wrong = (s.solution[i] % 9) + 1;
    for (let k = 0; k < 24; k++) expect(s.place(i, wrong).lost).toBe(false);
    expect(s.livesLeft).toBe(1);
    expect(s.place(i, wrong).lost).toBe(true);
    expect(s.revive()).toBe(true);
    expect(s.livesLeft).toBe(5);
    const t = GameSession.fromSnapshot(JSON.parse(JSON.stringify(s.snapshot())));
    expect(t.maxMistakes).toBe(25);
    expect(t.livesLeft).toBe(5);
  });

  it('old saves without a tries limit keep the classic 3', () => {
    const p = getPuzzle({ difficulty: 'easy', seed: 'old' });
    const s = new GameSession({ mode: 'quick', difficulty: 'easy', puzzle: p.puzzle, solution: p.solution });
    expect(s.maxMistakes).toBe(3);
  });
});
