import { describe, it, expect, beforeEach, vi } from 'vitest';

// Fresh module state per test (profile + storage keep in-memory caches).
async function loadProfile() {
  vi.resetModules();
  const storage = await import('../../src/core/storage.js');
  await storage.initStorage();
  const profile = await import('../../src/core/profile.js');
  const time = await import('../../src/core/time.js');
  profile.initProfile();
  await profile.resetEverything();
  return { ...profile, ...time };
}

const win = (extra = {}) => ({ mode: 'quick', difficulty: 'easy', won: true, ms: 200_000, mistakes: 0, hints: 0, revived: false, notes: 0, ...extra });

describe('profile', () => {
  let P;
  beforeEach(async () => { P = await loadProfile(); });

  it('records wins, best time and streaks per difficulty', () => {
    P.recordResult(win({ ms: 300_000 }));
    const r = P.recordResult(win({ ms: 250_000 }));
    expect(r.newBest).toBe(true);
    const s = P.getProfile().stats.byDiff.easy;
    expect(s.won).toBe(2);
    expect(s.bestMs).toBe(250_000);
    expect(s.streak).toBe(2);
    P.recordResult(win({ won: false }));
    expect(s.streak).toBe(0);
    expect(s.bestStreak).toBe(2);
    expect(s.played).toBe(3);
  });

  it('records duels per rival, streaks and duel achievements; duel puzzles stay out of difficulty stats', () => {
    let got = P.recordDuel({ rival: 'maw', beat: true, ms: 180_000, speed: 5, clean: true }).map((a) => a.id);
    expect(got).toEqual(expect.arrayContaining(['duel-1', 'duel-flawless', 'duel-lightning', 'duel-maw']));
    expect(got).not.toContain('first-contact'); // beating a rival is not a solved puzzle by itself
    P.recordDuel({ rival: 'zorp', beat: false });
    P.recordDuel({ rival: 'zorp', beat: true, ms: 300_000, speed: 3 });
    P.recordDuel({ rival: 'custom', beat: true, ms: 250_000, speed: 2 });
    got = P.recordDuel({ rival: 'zorp', beat: true, ms: 240_000, speed: 3 }).map((a) => a.id);
    expect(got).toContain('duel-streak');
    const d = P.duelStats();
    expect(d).toMatchObject({ played: 5, won: 4, streak: 3, bestStreak: 3, flawless: 1, lightning: 1 });
    expect(d.byRival.zorp).toEqual({ played: 3, won: 2, bestMs: 240_000 });
    P.recordResult(win({ mode: 'duel', difficulty: 'hard' }));
    expect(P.getProfile().stats.byDiff.hard.played).toBe(0);
  });

  it('first win unlocks achievements (returned, not toasted)', () => {
    const r = P.recordResult(win());
    const ids = r.achievements.map((a) => a.id);
    expect(ids).toContain('first-contact');
    expect(ids).toContain('flawless');
    expect(ids).toContain('light-speed');
  });

  it('campaign: stars, unlock chain, sector reward', () => {
    expect(P.isLevelUnlocked(0, 0)).toBe(true);
    expect(P.isLevelUnlocked(0, 1)).toBe(false);
    const r = P.recordResult(win({ mode: 'campaign', sector: 0, level: 0, mistakes: 1 }));
    expect(r.stars).toBe(2);
    expect(P.isLevelUnlocked(0, 1)).toBe(true);
    // Replay keeps the best stars.
    P.recordResult(win({ mode: 'campaign', sector: 0, level: 0, mistakes: 2 }));
    expect(P.levelRecord(0, 0).stars).toBe(2);
    P.recordResult(win({ mode: 'campaign', sector: 0, level: 0 }));
    expect(P.levelRecord(0, 0).stars).toBe(3);
    for (let l = 1; l < 9; l++) P.recordResult(win({ mode: 'campaign', sector: 0, level: l }));
    expect(P.isSectorUnlocked(1)).toBe(true);
    // Finishing sector 3 (index 2) unlocks sector 4's lineup (Alien Creatures).
    for (let s = 1; s <= 2; s++) for (let l = 0; l < 9; l++) {
      const res = P.recordResult(win({ mode: 'campaign', sector: s, level: l }));
      if (s === 2 && l === 8) expect(res.unlockedSets).toEqual(['creatures']);
    }
    expect(P.isSetUnlocked('creatures')).toBe(true);
    expect(P.nextCampaignLevel()).toEqual({ sector: 3, level: 0 });
    // Reaching the last sector unlocks Ancient Mysteries; finishing it awards the Cosmic Mix.
    for (let s = 3; s <= 4; s++) for (let l = 0; l < 9; l++) P.recordResult(win({ mode: 'campaign', sector: s, level: l }));
    expect(P.isSetUnlocked('ancient')).toBe(true);
    expect(P.isSetUnlocked('mixed')).toBe(false);
    let last;
    for (let l = 0; l < 9; l++) last = P.recordResult(win({ mode: 'campaign', sector: 5, level: l }));
    expect(last.unlockedSets).toEqual(['mixed']);
    expect(last.achievements.map((a) => a.id)).toContain('collector');
  });

  it('daily: streak grows only on consecutive days, played on the day', () => {
    const today = P.todayStr();
    const yesterday = P.addDays(today, -1);
    const prof = P.getProfile();
    // Simulate a streak that was alive yesterday.
    prof.daily.streak = 4;
    prof.daily.lastStreakDate = yesterday;
    const r = P.recordResult(win({ mode: 'daily', date: today }));
    expect(r.streak).toBe(5);
    // Replaying today does not double count.
    P.recordResult(win({ mode: 'daily', date: today }));
    expect(P.currentStreak()).toBe(5);
    // Old days count as completed but not for the streak.
    P.recordResult(win({ mode: 'daily', date: P.addDays(today, -10) }));
    expect(P.currentStreak()).toBe(5);
    expect(P.dailyRecord(P.addDays(today, -10))).toBeTruthy();
  });

  it('a broken streak restarts at 1', () => {
    const today = P.todayStr();
    const prof = P.getProfile();
    prof.daily.streak = 9;
    prof.daily.lastStreakDate = P.addDays(today, -3);
    expect(P.currentStreak()).toBe(0);
    P.recordResult(win({ mode: 'daily', date: today }));
    expect(P.currentStreak()).toBe(1);
    expect(prof.daily.bestStreak).toBe(1); // bestStreak was 0 after reset; 9 was injected without best
  });

  it('zen wins are separate from difficulty stats', () => {
    P.recordResult(win({ mode: 'zen', zen: true }));
    expect(P.getProfile().stats.byDiff.easy.played).toBe(0);
    expect(P.getProfile().stats.totals.zenWins).toBe(1);
  });

  it('settings persist through save/load and survive reset', async () => {
    P.setSetting('symbolSet', 'planets');
    P.setSetting('music', false);
    expect(P.settings().symbolSet).toBe('planets');
    await P.resetEverything();
    expect(P.settings().music).toBe(false);
    expect(P.settings().symbolSet).toBe('encounters');
  });

  it('saved game store/clear', () => {
    P.storeSavedGame({ v: 1, board: [1] });
    expect(P.loadSavedGame()).toEqual({ v: 1, board: [1] });
    P.clearSavedGame();
    expect(P.loadSavedGame()).toBe(null);
  });
});

describe('time helpers', () => {
  it('formats and shifts dates', async () => {
    const t = await import('../../src/core/time.js');
    expect(t.formatTime(0)).toBe('0:00');
    expect(t.formatTime(65_000)).toBe('1:05');
    expect(t.formatTime(3_725_000)).toBe('1:02:05');
    expect(t.addDays('2026-03-01', -1)).toBe('2026-02-28');
    expect(t.addDays('2024-12-31', 1)).toBe('2025-01-01');
  });
});

describe('profile migration', () => {
  it('maps old lineup keys and rebuilds unlocks from campaign progress', async () => {
    vi.resetModules();
    const storage = await import('../../src/core/storage.js');
    await storage.initStorage();
    const levels = {};
    for (let s = 0; s <= 2; s++) for (let l = 0; l < 9; l++) levels[`${s}-${l}`] = { stars: 3, bestMs: 1000 };
    storage.save('profile', { settings: { symbolSet: 'spaceships' }, unlockedSets: ['alien', 'moons', 'spaceships'], campaign: { levels } });
    const P = await import('../../src/core/profile.js');
    P.initProfile();
    expect(P.settings().symbolSet).toBe('creatures');
    expect(P.getProfile().unlockedSets).toEqual(expect.arrayContaining(['encounters', 'fleet', 'planets', 'cosmos', 'creatures']));
    expect(P.isSetUnlocked('ancient')).toBe(false);
    expect(P.getProfile().unlockedSets).not.toContain('alien');
  });

  it('records best score and best combo', async () => {
    const P = await loadProfile();
    P.recordResult(win({ difficulty: 'hard', score: 4200, bestCombo: 12 }));
    const r = P.recordResult(win({ difficulty: 'hard', score: 5100, bestCombo: 3 }));
    expect(r.newHighScore).toBe(true);
    expect(P.getProfile().stats.byDiff.hard.bestScore).toBe(5100);
    expect(P.getProfile().stats.totals.bestCombo).toBe(12);
    expect(r.achievements.map((a) => a.id)).toContain('score-5k');
  });
});

describe('the visitors', () => {
  it('remember the player name and unlock the contact achievement', async () => {
    const P = await loadProfile();
    expect(P.settings().tries).toBe(25);
    const fresh = P.recordEncounter({ name: '  Eddie   G ', answer: 'name' });
    expect(P.playerName()).toBe('Eddie G');
    expect(fresh.map((a) => a.id)).toContain('contact');
    P.recordEncounter({ name: '', answer: 'friend' });
    expect(P.playerName()).toBe('Eddie G');
    expect(P.getProfile().stats.totals.encounters).toBe(2);
  });
});
