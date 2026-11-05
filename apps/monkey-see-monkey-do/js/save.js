// Save data: one JSON object in localStorage on this device only.
// Settings > Your data shows the whole thing, and can copy, load or reset it.
import { DEFAULT_OWNED, DEFAULT_EQUIPPED, getItem } from './shop.js';
import { WORLDS } from './levels.js';
import { SKINS, SETS, getSkin, newlyEarned, setProgress } from './skins.js';
import { RULES } from './rules.js';
import { OWNED_REFUND_GOLDEN, spentThisMonth } from './store.js';

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
  quality: 'auto', // 'auto' | 'low' | 'high' | 'ultra' (auto may use 'medium')
  latencyMs: 0, // rhythm calibration
  parentGate: true, // ask a grown-up question before any real-money purchase
  spendLimit: 0, // monthly real-money limit in the store's currency (0 = no limit)
};

function defaults() {
  return {
    v: 1,
    created: Date.now(),
    bananas: 0,
    earned: 0,
    spent: 0,
    golden: 0, // Golden Bananas (premium-skin currency)
    goldenEarned: 0,
    goldenSpent: 0,
    goldOnce: { threeStar: {}, world: {}, sets: {} }, // one-time golden rewards already paid
    skinEarned: {}, // premium skin id -> time it was unlocked by its play goal
    newSkins: [], // unlocked but not looked at yet (NEW badge)
    outfits: [], // saved looks: [{ name, look, t } or null] x 6
    purchases: [], // real-money purchases: [{ t, id, title, price, micros, currency, test }]
    ownedProducts: [], // one-time products already delivered (bundles, sets, starter)
    processedTx: [], // store transaction ids already delivered (never grant twice)
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
      flawless: 0, // levels cleared without losing a life
      combos: 0,
      reverseRounds: 0,
      speedupRounds: 0,
      buildupRounds: 0,
      freeMoves: 0,
      days: [], // different days played, as YYYY-MM-DD
    },
    tutorialDone: false,
    seenIntro: {},
    ledger: [], // [{ t, amount, reason, cur: 'golden' for golden bananas }]
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

/** Older saves kept fur colours under owned.fur; they are skins now. */
export function migrateRaw(json) {
  if (!json || typeof json !== 'object') return json;
  if (json.owned && Array.isArray(json.owned.fur)) {
    json.owned.skin = [...new Set([...(json.owned.skin || []), ...json.owned.fur])];
    delete json.owned.fur;
  }
  if (json.equipped && json.equipped.fur) {
    if (!json.equipped.skin) json.equipped.skin = json.equipped.fur;
    delete json.equipped.fur;
  }
  return json;
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
        merge(this.data, migrateRaw(JSON.parse(raw)));
      } catch {
        /* corrupt save: start fresh, keep the bad copy for support */
        try { localStorage.setItem(KEY + '.broken', raw); } catch { /* ignore */ }
      }
    }
    this.data.stats.sessions++;
    this.markDay();
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

  addGolden(amount, reason) {
    if (!amount) return;
    this.data.golden += amount;
    if (amount > 0) this.data.goldenEarned += amount;
    else this.data.goldenSpent += -amount;
    this.data.ledger.unshift({ t: Date.now(), amount, reason, cur: 'golden' });
    if (this.data.ledger.length > LEDGER_MAX) this.data.ledger.length = LEDGER_MAX;
    this.persist();
  },

  /** Pay a one-time golden reward (kind: threeStar | world | sets). Returns the amount paid. */
  goldOnce(kind, key, amount, reason) {
    const done = this.data.goldOnce[kind];
    if (done[key]) return 0;
    done[key] = Date.now();
    this.addGolden(amount, reason);
    return amount;
  },

  /** Swap bananas for golden bananas at RULES.exchangeRate. */
  exchange(count) {
    const cost = count * RULES.exchangeRate;
    if (count < 1 || this.data.bananas < cost) return false;
    this.addBananas(-cost, `Swapped for ${count} golden banana${count === 1 ? '' : 's'}`);
    this.addGolden(count, `Swapped ${cost} bananas`);
    return true;
  },

  markDay() {
    const d = new Date();
    const day = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    const days = this.data.stats.days;
    if (!days.includes(day)) {
      days.push(day);
      if (days.length > 400) days.splice(0, days.length - 400);
    }
  },

  /** Buy a skin with its currency (bananas for standard, golden for premium). */
  buySkin(id) {
    const skin = getSkin(id);
    if (!skin || skin.id !== id || this.owns('skin', id)) return false;
    if (skin.currency === 'golden') {
      if (this.data.golden < skin.price) return false;
      this.addGolden(-skin.price, `Unlocked ${skin.name} skin`);
    } else if (!this.spend(skin.price, `Bought ${skin.name} skin`)) return false;
    this.data.owned.skin.push(id);
    this.persist();
    return true;
  },

  /**
   * Give premium skins whose play goal is now reached, and pay set bonuses.
   * Returns { skins: [...newly earned], golden: amount from set bonuses }.
   */
  checkSkinGoals() {
    const earned = newlyEarned(this.data);
    for (const s of earned) {
      this.data.owned.skin.push(s.id);
      this.data.skinEarned[s.id] = Date.now();
      if (!this.data.newSkins.includes(s.id)) this.data.newSkins.push(s.id);
    }
    let golden = 0;
    const sets = [];
    for (const set of SETS) {
      const p = setProgress(set.id, this.data.owned.skin);
      if (p.have === p.total) {
        const paid = this.goldOnce('sets', set.id, RULES.goldSetComplete, `Completed the ${set.name} set`);
        if (paid) { golden += paid; sets.push(set); }
      }
    }
    // a set bonus can't unlock a goal, but owning more skins can (Own 25 skins)
    if (earned.length) {
      const more = this.checkSkinGoals();
      earned.push(...more.skins);
      golden += more.golden;
      sets.push(...more.sets);
    }
    this.persist();
    return { skins: earned, golden, sets };
  },

  /**
   * Give what a purchased product contains (see js/store.js). Safe to call
   * twice for the same transaction. Returns what was added, or null.
   */
  deliverPurchase(p, tx, price) {
    const d = this.data;
    if (d.processedTx.includes(tx)) return null;
    d.processedTx.push(tx);
    if (d.processedTx.length > 300) d.processedTx.splice(0, d.processedTx.length - 300);
    if (p.type === 'nonconsumable' && d.ownedProducts.includes(p.id)) { this.persist(); return null; }
    const got = { bananas: p.grants.bananas, golden: p.grants.golden, skins: [], gear: [], refunded: 0 };
    if (p.grants.bananas) this.addBananas(p.grants.bananas, `Purchased ${p.title}`);
    if (p.grants.golden) this.addGolden(p.grants.golden, `Purchased ${p.title}`);
    for (const id of p.grants.skins) {
      if (this.owns('skin', id)) { got.refunded++; continue; }
      d.owned.skin.push(id);
      if (!d.newSkins.includes(id)) d.newSkins.push(id);
      got.skins.push(id);
    }
    for (const g of p.grants.gear) {
      const [slot, id] = g.split(':');
      if (this.owns(slot, id)) { got.refunded++; continue; }
      if (!d.owned[slot]) d.owned[slot] = ['none'];
      d.owned[slot].push(id);
      got.gear.push(g);
    }
    if (got.refunded) this.addGolden(got.refunded * OWNED_REFUND_GOLDEN, `${p.title}: ${got.refunded} item${got.refunded === 1 ? '' : 's'} you already had`);
    if (p.type === 'nonconsumable') d.ownedProducts.push(p.id);
    d.purchases.unshift({
      t: Date.now(), id: p.id, title: p.title,
      price: price ? price.price : `$${p.usd.toFixed(2)}`,
      micros: price ? price.micros : Math.round(p.usd * 1e6),
      currency: price ? price.currency : 'USD',
      test: String(tx).startsWith('test-'),
    });
    if (d.purchases.length > 200) d.purchases.length = 200;
    this.syncUnlocks();
    this.persist();
    return got;
  },

  /** Would this purchase go over the monthly limit? */
  overLimit(price) {
    const limit = this.data.settings.spendLimit || 0;
    if (!limit || !price) return false;
    const spent = spentThisMonth(this.data.purchases)[price.currency] || 0;
    return spent + price.micros / 1e6 > limit + 1e-6;
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
    if (item.currency === 'golden') {
      if (this.data.golden < item.price) return false;
      this.addGolden(-item.price, `Bought ${item.name}`);
    } else if (!this.spend(item.price, `Bought ${item.name}`)) return false;
    if (!this.data.owned[cat]) this.data.owned[cat] = ['none'];
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
    const json = migrateRaw(JSON.parse(decodeURIComponent(escape(atob(code.trim())))));
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
