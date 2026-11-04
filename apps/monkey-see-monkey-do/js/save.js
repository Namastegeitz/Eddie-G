// Save data: one JSON object in localStorage on this device only.
// Settings > Your data shows the whole thing, and can copy, load or reset it.
import { DEFAULT_OWNED, DEFAULT_EQUIPPED, getItem } from './shop.js';
import { WORLDS } from './levels.js';

const KEY = 'msmd.save.v1';
const LEDGER_MAX = 60;

export const DEFAULT_SETTINGS = {
  music: 0.6,
  sfx: 0.9,
  voice: false, // speak each move during Watch
  silentOk: true, // iPhone: play sound with the ring/silent switch on
  haptics: true,
  naming: 'screen', // 'screen' | 'monkey'
  timer: 'normal', // 'normal' | 'relaxed' | 'off'
  speed: 1, // 1 | 0.85 | 0.7  (tempo multiplier)
  assist: false, // free Watch again, hint after a mistake, wider combo window
  swipe: true,
  tapMonkey: true,
  keyHints: true,
  captions: true, // show move names during Watch
  reduceMotion: false,
  quality: 'auto', // 'auto' | 'high' | 'low'
  latencyMs: 0, // rhythm calibration
};

function defaults() {
  return {
    v: 1,
    created: Date.now(),
    bananas: 0,
    earned: 0,
    spent: 0,
    levels: {}, // id -> { stars, best, clears }
    endless: { bestRounds: 0, bestScore: 0, plays: 0 },
    owned: JSON.parse(JSON.stringify(DEFAULT_OWNED)),
    equipped: JSON.parse(JSON.stringify(DEFAULT_EQUIPPED)),
    settings: { ...DEFAULT_SETTINGS },
    stats: {
      sessions: 0,
      levelsPlayed: 0,
      roundsCleared: 0,
      stepsCorrect: 0,
      mistakes: 0,
      timeouts: 0,
      perfects: 0,
      greats: 0,
      bestStreak: 0,
      playSeconds: 0,
      perMove: {}, // id -> { ok, miss }
      mixups: {}, // "expected>tapped" -> count
    },
    tutorialDone: false,
    seenIntro: {},
    ledger: [], // [{ t, amount, reason }]
  };
}

function merge(base, extra) {
  if (!extra || typeof extra !== 'object' || Array.isArray(extra)) return base;
  for (const k of Object.keys(base)) {
    if (!(k in extra)) continue;
    const b = base[k];
    const e = extra[k];
    if (b && typeof b === 'object' && !Array.isArray(b) && e && typeof e === 'object' && !Array.isArray(e)) {
      // Plain maps (levels, perMove, mixups, seenIntro) keep every key.
      base[k] = Object.keys(b).length === 0 ? { ...e } : merge(b, e);
    } else if (typeof b === typeof e || b === null) {
      base[k] = e;
    }
  }
  return base;
}

let memoryCopy = null; // used when storage is blocked (private mode, sandboxed previews)

export const Save = {
  data: defaults(),
  storageOk: true,

  load() {
    let raw = null;
    try {
      raw = localStorage.getItem(KEY);
    } catch {
      this.storageOk = false;
      raw = memoryCopy;
    }
    this.data = defaults();
    if (raw) {
      try {
        merge(this.data, JSON.parse(raw));
      } catch {
        /* corrupt save: start fresh, keep the bad copy for support */
        try { localStorage.setItem(KEY + '.broken', raw); } catch { /* ignore */ }
      }
    }
    this.data.stats.sessions++;
    this.syncUnlocks();
    this.persist();
    return this.data;
  },

  persist() {
    const raw = JSON.stringify(this.data);
    memoryCopy = raw;
    try {
      localStorage.setItem(KEY, raw);
      this.storageOk = true;
    } catch {
      this.storageOk = false;
    }
  },

  get settings() {
    return this.data.settings;
  },

  setSetting(key, value) {
    this.data.settings[key] = value;
    this.persist();
  },

  addBananas(amount, reason) {
    if (!amount) return;
    this.data.bananas += amount;
    if (amount > 0) this.data.earned += amount;
    else this.data.spent += -amount;
    this.data.ledger.unshift({ t: Date.now(), amount, reason });
    if (this.data.ledger.length > LEDGER_MAX) this.data.ledger.length = LEDGER_MAX;
    this.persist();
  },

  spend(amount, reason) {
    if (this.data.bananas < amount) return false;
    this.addBananas(-amount, reason);
    return true;
  },

  levelInfo(id) {
    return this.data.levels[id] || { stars: 0, best: 0, clears: 0 };
  },

  /** Highest level the player may start (the one after their furthest clear). */
  unlockedLevel() {
    let max = 1;
    for (const k of Object.keys(this.data.levels)) {
      if (this.data.levels[k].clears > 0) max = Math.max(max, Number(k) + 1);
    }
    return max;
  },

  worldReached() {
    return Math.min(WORLDS.length, Math.ceil(this.unlockedLevel() / 10));
  },

  totalStars() {
    return Object.values(this.data.levels).reduce((s, l) => s + (l.stars || 0), 0);
  },

  recordLevel(id, stars, score) {
    const prev = this.levelInfo(id);
    const firstClear = prev.clears === 0;
    this.data.levels[id] = { stars: Math.max(prev.stars, stars), best: Math.max(prev.best, score), clears: prev.clears + 1 };
    this.syncUnlocks();
    this.persist();
    return { firstClear, prevStars: prev.stars, prevBest: prev.best };
  },

  /** Stages tied to a world become owned when that world is reached. */
  syncUnlocks() {
    const reached = this.worldReached();
    const stages = this.data.owned.stage;
    for (const [id, world] of [['beach', 2], ['disco', 3]]) {
      if (reached >= world && !stages.includes(id)) stages.push(id);
    }
  },

  owns(cat, id) {
    return (this.data.owned[cat] || []).includes(id);
  },

  buy(cat, id) {
    const item = getItem(cat, id);
    if (!item || this.owns(cat, id)) return false;
    if (!this.spend(item.price, `Bought ${item.name}`)) return false;
    this.data.owned[cat].push(id);
    this.persist();
    return true;
  },

  equip(cat, id) {
    if (!this.owns(cat, id) && !(cat === 'stage' && id === 'auto')) return false;
    this.data.equipped[cat] = id;
    this.persist();
    return true;
  },

  stat(key, delta = 1) {
    this.data.stats[key] = (this.data.stats[key] || 0) + delta;
  },

  moveResult(expectedIds, tappedId, ok) {
    const pm = this.data.stats.perMove;
    for (const id of expectedIds) {
      pm[id] = pm[id] || { ok: 0, miss: 0 };
      if (ok) pm[id].ok++;
      else pm[id].miss++;
    }
    if (!ok && tappedId && expectedIds.length === 1 && tappedId !== expectedIds[0]) {
      const k = `${expectedIds[0]}>${tappedId}`;
      this.data.stats.mixups[k] = (this.data.stats.mixups[k] || 0) + 1;
    }
  },

  exportCode() {
    return btoa(unescape(encodeURIComponent(JSON.stringify(this.data))));
  },

  importCode(code) {
    const json = JSON.parse(decodeURIComponent(escape(atob(code.trim()))));
    if (!json || json.v !== 1) throw new Error('This is not a Monkey See, Monkey Do save code.');
    this.data = merge(defaults(), json);
    this.syncUnlocks();
    this.persist();
  },

  reset() {
    this.data = defaults();
    this.persist();
  },
};
