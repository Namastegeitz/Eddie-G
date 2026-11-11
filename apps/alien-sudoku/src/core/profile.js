/* ============================================================
   Player profile: settings, campaign progress, daily streak,
   stats, achievements, unlocked symbol sets, and the saved
   in-progress game. Everything persists through storage.js.
   ============================================================ */

import { load, save, remove, clearAll } from './storage.js';
import { emit } from './events.js';
import { ACHIEVEMENTS } from '../data/achievements.js';
import { SECTORS, STARTER_SETS, OLD_SET_KEYS, levelKey, starsFor, LEVELS_PER_SECTOR } from '../data/sectors.js';
import { SYMBOL_SETS } from '../data/symbols.js';
import { todayStr, addDays } from './time.js';

const PROFILE_KEY = 'profile';
const SAVED_GAME_KEY = 'saved-game';
export const DIFFS = ['easy', 'medium', 'hard', 'alien'];

export const DEFAULT_SETTINGS = {
  sfx: true,
  sfxVolume: 0.8,
  music: true,
  musicVolume: 0.6,
  haptics: true,
  symbolSet: 'encounters',
  sectorSymbols: true,     // campaign uses each sector's own symbol set
  difficultyAliens: true,  // quick/zen/daily use each difficulty's lineup (soft -> gnarly)
  highlightPeers: true,
  highlightSame: true,
  constellation: true,
  showTimer: true,
  autoRemoveNotes: true,
  inputMode: 'cell',       // 'cell' = tap cell then glyph; 'glyph' = arm a glyph then tap cells
  reduceMotion: false,
  quickDifficulty: 'medium',
  tries: 25,               // mistakes allowed per puzzle: 3, 5, 10 or 25
  seenTutorial: false,
  duel: null,              // Alien Duel setup (see DUEL_DEFAULTS in game/rival.js)
};

const emptyDuelStats = () => ({ played: 0, won: 0, streak: 0, bestStreak: 0, flawless: 0, lightning: 0, byRival: {} });
const emptyDiffStats = () => ({ played: 0, won: 0, perfect: 0, bestMs: null, totalWinMs: 0, streak: 0, bestStreak: 0, bestScore: 0 });

function defaultProfile() {
  return {
    version: 1,
    createdAt: Date.now(),
    settings: { ...DEFAULT_SETTINGS },
    campaign: { levels: {} },               // "s-l" -> { stars, bestMs }
    daily: { completed: {}, streak: 0, bestStreak: 0, lastStreakDate: null },
    stats: {
      byDiff: Object.fromEntries(DIFFS.map((d) => [d, emptyDiffStats()])),
      totals: { notes: 0, hints: 0, mistakes: 0, playMs: 0, zenWins: 0, zenPlayed: 0, gamesStarted: 0, bestCombo: 0, encounters: 0 },
      duel: emptyDuelStats(),
    },
    achievements: {},                        // id -> unlocked timestamp
    playerName: '',                          // the answer to the visitors' "Who are you?"
    lastAnswer: '',
    unlockedSets: [...STARTER_SETS],
  };
}

let profile = null;

/** Merge a stored profile over defaults so new fields always exist. */
function hydrate(stored) {
  const base = defaultProfile();
  if (!stored || typeof stored !== 'object') return base;
  const p = { ...base, ...stored };
  p.settings = { ...base.settings, ...(stored.settings || {}) };
  p.campaign = { ...base.campaign, ...(stored.campaign || {}) };
  p.daily = { ...base.daily, ...(stored.daily || {}) };
  p.stats = {
    byDiff: Object.fromEntries(DIFFS.map((d) => [d, { ...emptyDiffStats(), ...(stored.stats?.byDiff?.[d] || {}) }])),
    totals: { ...base.stats.totals, ...(stored.stats?.totals || {}) },
    duel: { ...emptyDuelStats(), ...(stored.stats?.duel || {}), byRival: { ...(stored.stats?.duel?.byRival || {}) } },
  };
  p.achievements = { ...(stored.achievements || {}) };
  const migrate = (k) => OLD_SET_KEYS[k] || k;
  p.unlockedSets = Array.from(new Set([...STARTER_SETS, ...(stored.unlockedSets || []).map(migrate)])).filter((k) => SYMBOL_SETS[k]);
  p.settings.symbolSet = migrate(p.settings.symbolSet);
  syncUnlocks(p);
  if (!SYMBOL_SETS[p.settings.symbolSet] || !p.unlockedSets.includes(p.settings.symbolSet)) p.settings.symbolSet = 'encounters';
  return p;
}

/** Lineups earned in the campaign, recomputed from progress (safe after any change to the rules). */
function syncUnlocks(p) {
  const done = (s, l) => !!p.campaign.levels[levelKey(s, l)];
  for (const sec of SECTORS) {
    const reached = sec.id === 0 || done(sec.id - 1, LEVELS_PER_SECTOR - 1);
    if (reached && sec.unlocksSet && !p.unlockedSets.includes(sec.unlocksSet)) p.unlockedSets.push(sec.unlocksSet);
    if (sec.rewardSet && done(sec.id, LEVELS_PER_SECTOR - 1) && !p.unlockedSets.includes(sec.rewardSet)) p.unlockedSets.push(sec.rewardSet);
  }
}

export function initProfile() {
  profile = hydrate(load(PROFILE_KEY));
  persist();
  return profile;
}

export function getProfile() { return profile; }
export function persist() { save(PROFILE_KEY, profile); }

// ---------------- Settings ----------------
export function settings() { return profile.settings; }

export function setSetting(key, value) {
  if (profile.settings[key] === value) return;
  profile.settings[key] = value;
  persist();
  emit('settings', { key, value });
}

// ---------------- Symbol sets ----------------
export function isSetUnlocked(key) { return profile.unlockedSets.includes(key); }

function unlockSet(key, unlocked) {
  if (!key || isSetUnlocked(key)) return;
  profile.unlockedSets.push(key);
  unlocked.push(key);
}

// ---------------- Campaign ----------------
export function levelRecord(sector, level) { return profile.campaign.levels[levelKey(sector, level)] || null; }

export function isLevelUnlocked(sector, level) {
  if (sector === 0 && level === 0) return true;
  if (level > 0) return !!levelRecord(sector, level - 1);
  return isSectorUnlocked(sector);
}

export function isSectorUnlocked(sector) {
  if (sector === 0) return true;
  return !!levelRecord(sector - 1, LEVELS_PER_SECTOR - 1);
}

export function sectorStars(sector) {
  let n = 0;
  for (let l = 0; l < LEVELS_PER_SECTOR; l++) n += levelRecord(sector, l)?.stars || 0;
  return n;
}

export function totalStars() {
  return Object.values(profile.campaign.levels).reduce((n, l) => n + (l.stars || 0), 0);
}

/** The next campaign level the player hasn't finished, for "Continue campaign". */
export function nextCampaignLevel() {
  for (const s of SECTORS) {
    for (let l = 0; l < LEVELS_PER_SECTOR; l++) {
      if (!levelRecord(s.id, l)) return isLevelUnlocked(s.id, l) ? { sector: s.id, level: l } : null;
    }
  }
  return null;
}

// ---------------- Daily ----------------
export function dailyRecord(date) { return profile.daily.completed[date] || null; }

/** Current streak, counting only if it's still alive (finished today or yesterday). */
export function currentStreak() {
  const d = profile.daily;
  if (!d.lastStreakDate) return 0;
  const today = todayStr();
  if (d.lastStreakDate === today || d.lastStreakDate === addDays(today, -1)) return d.streak;
  return 0;
}

// ---------------- Results ----------------
/**
 * Record a finished (won or lost) game.
 * result: { mode: 'quick'|'campaign'|'daily'|'zen', difficulty, won, ms, mistakes, hints,
 *           revived, notes, sector?, level?, date?, abandoned? }
 * Returns { stars, newBest, prevBest, achievements: [def], unlockedSets: [key], streak }.
 */
export function recordResult(result) {
  const out = { stars: 0, newBest: false, prevBest: null, newHighScore: false, achievements: [], unlockedSets: [], streak: null };
  const t = profile.stats.totals;
  t.bestCombo = Math.max(t.bestCombo || 0, result.bestCombo || 0);
  t.notes += result.notes || 0;
  t.hints += result.hints || 0;
  t.mistakes += result.mistakes || 0;
  t.playMs += result.ms || 0;

  if (result.mode === 'zen') {
    t.zenPlayed++;
    if (result.won) t.zenWins++;
  } else if (result.mode !== 'duel') {
    const s = profile.stats.byDiff[result.difficulty];
    if (s) {
      s.played++;
      if (result.won) {
        s.won++;
        s.totalWinMs += result.ms;
        s.streak++;
        s.bestStreak = Math.max(s.bestStreak, s.streak);
        if (result.mistakes === 0 && result.hints === 0) s.perfect++;
        out.prevBest = s.bestMs;
        if (s.bestMs == null || result.ms < s.bestMs) { s.bestMs = result.ms; out.newBest = true; }
        if ((result.score || 0) > (s.bestScore || 0)) { out.newHighScore = (s.bestScore || 0) > 0; s.bestScore = result.score; }
      } else {
        s.streak = 0;
      }
    }
  }

  if (result.won) {
    out.stars = starsFor(result);
    if (result.mode === 'campaign') {
      const key = levelKey(result.sector, result.level);
      const prev = profile.campaign.levels[key];
      profile.campaign.levels[key] = {
        stars: Math.max(prev?.stars || 0, out.stars),
        bestMs: prev?.bestMs != null ? Math.min(prev.bestMs, result.ms) : result.ms,
      };
      // Finishing the last level of a sector opens the next one and its lineup;
      // the final sector also awards the Cosmic Mix.
      if (result.level === LEVELS_PER_SECTOR - 1) {
        const next = SECTORS[result.sector + 1];
        if (next) unlockSet(next.unlocksSet, out.unlockedSets);
        unlockSet(SECTORS[result.sector]?.rewardSet, out.unlockedSets);
      }
    }
    if (result.mode === 'daily' && result.date) {
      const prev = profile.daily.completed[result.date];
      profile.daily.completed[result.date] = {
        ms: prev ? Math.min(prev.ms, result.ms) : result.ms,
        stars: Math.max(prev?.stars || 0, out.stars),
      };
      // Streaks only grow when the puzzle is finished on its own day.
      const d = profile.daily;
      if (result.date === todayStr()) {
        if (d.lastStreakDate === result.date) { /* already counted today */ }
        else if (d.lastStreakDate === addDays(result.date, -1)) d.streak++;
        else d.streak = 1;
        d.lastStreakDate = result.date;
        d.bestStreak = Math.max(d.bestStreak, d.streak);
      }
      out.streak = currentStreak();
    }
  }

  out.achievements = evaluateAchievements(result);
  persist();
  if (out.unlockedSets.length) emit('sets-unlocked', out.unlockedSets);
  return out;
}

/** Check every locked achievement; unlock and return the new ones. */
export function evaluateAchievements(result = null) {
  const fresh = [];
  for (const a of ACHIEVEMENTS) {
    if (profile.achievements[a.id]) continue;
    let ok = false;
    try { ok = !!a.check({ profile, result }); } catch { ok = false; }
    if (ok) {
      profile.achievements[a.id] = Date.now();
      fresh.push(a);
    }
  }
  if (fresh.length) {
    persist();
    // Wins list new achievements on the result card; everything else gets a toast.
    if (!result?.won) emit('achievements', fresh);
  }
  return fresh;
}

// ---------------- Alien Duel ----------------
/**
 * Record how a duel ended, once per duel: when the player or the rival finishes
 * first (or the player gives up).
 * duel: { rival: id ('blip'|'zorp'|'vex'|'maw'|'custom'), beat: boolean, ms, speed, clean }
 * Returns the achievements it unlocked.
 */
export function recordDuel(duel) {
  const d = profile.stats.duel;
  const r = d.byRival[duel.rival] || (d.byRival[duel.rival] = { played: 0, won: 0, bestMs: null });
  d.played++;
  r.played++;
  if (duel.beat) {
    d.won++;
    r.won++;
    d.streak++;
    d.bestStreak = Math.max(d.bestStreak, d.streak);
    if (duel.ms != null && (r.bestMs == null || duel.ms < r.bestMs)) r.bestMs = duel.ms;
    if (duel.clean) d.flawless++;
    if (duel.speed >= 5) d.lightning++;
  } else {
    d.streak = 0;
  }
  persist();
  // A win shows its achievements on the result card (no toast), like any other win.
  return evaluateAchievements(duel.beat ? { won: true, duelOnly: true } : null);
}
export function duelStats() { return profile.stats.duel; }

// ---------------- The visitors ----------------
export function playerName() { return profile.playerName || ''; }

/** Remember how the player answered "Who are you?". */
export function recordEncounter({ name, answer }) {
  const clean = String(name || '').replace(/\s+/g, ' ').trim().slice(0, 24);
  if (clean) profile.playerName = clean;
  profile.lastAnswer = answer || (clean ? 'name' : '');
  profile.stats.totals.encounters = (profile.stats.totals.encounters || 0) + 1;
  persist();
  return evaluateAchievements(null);
}

export function countGameStarted() {
  profile.stats.totals.gamesStarted++;
  persist();
}

// ---------------- Saved game ----------------
export function loadSavedGame() { return load(SAVED_GAME_KEY); }
export function storeSavedGame(snapshot) { save(SAVED_GAME_KEY, snapshot); }
export function clearSavedGame() { remove(SAVED_GAME_KEY); }

// ---------------- Reset ----------------
export async function resetEverything() {
  const keepSettings = { ...profile.settings, seenTutorial: true };
  await clearAll();
  profile = defaultProfile();
  profile.settings = { ...profile.settings, ...keepSettings, symbolSet: 'encounters' };
  persist();
  emit('profile-reset');
}
