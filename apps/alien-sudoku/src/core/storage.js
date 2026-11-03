/* ============================================================
   Persistent key/value storage.
   - Web / desktop: localStorage.
   - Native (Capacitor): localStorage for fast synchronous reads,
     mirrored to @capacitor/preferences so iOS can't evict the
     player's progress when the device is low on space.
   All values are JSON. Reads are synchronous from an in-memory
   cache that is hydrated once at boot (initStorage()).
   ============================================================ */

const PREFIX = 'alien-sudoku:';
const cache = new Map();
let prefs = null; // Capacitor Preferences plugin when native

function lsGet(key) {
  try { return localStorage.getItem(PREFIX + key); } catch { return null; }
}
function lsSet(key, raw) {
  try {
    if (raw == null) localStorage.removeItem(PREFIX + key);
    else localStorage.setItem(PREFIX + key, raw);
  } catch { /* storage blocked: keep in memory only */ }
}

/** Load everything we own into memory. Call once before reading. */
export async function initStorage({ native = false } = {}) {
  // 1) localStorage
  try {
    for (let i = 0; i < localStorage.length; i++) {
      const k = localStorage.key(i);
      if (k && k.startsWith(PREFIX)) cache.set(k.slice(PREFIX.length), localStorage.getItem(k));
    }
  } catch { /* ignore */ }

  // 2) Native preferences win over localStorage (they survive eviction).
  if (native) {
    try {
      const mod = await import('@capacitor/preferences');
      prefs = mod.Preferences;
      const { keys } = await prefs.keys();
      for (const full of keys) {
        if (!full.startsWith(PREFIX)) continue;
        const { value } = await prefs.get({ key: full });
        if (value != null) {
          const k = full.slice(PREFIX.length);
          cache.set(k, value);
          lsSet(k, value);
        }
      }
    } catch { prefs = null; }
  }
}

export function load(key, fallback = null) {
  let raw = cache.has(key) ? cache.get(key) : lsGet(key);
  if (raw == null) return fallback;
  try { return JSON.parse(raw); } catch { return fallback; }
}

export function save(key, value) {
  const raw = value === undefined || value === null ? null : JSON.stringify(value);
  if (raw == null) cache.delete(key); else cache.set(key, raw);
  lsSet(key, raw);
  if (prefs) {
    const full = PREFIX + key;
    (raw == null ? prefs.remove({ key: full }) : prefs.set({ key: full, value: raw })).catch(() => {});
  }
}

export function remove(key) { save(key, null); }

/** Wipe every key this game owns (used by Settings → Reset progress). */
export async function clearAll() {
  const keys = [...cache.keys()];
  for (const k of keys) remove(k);
  try {
    const stale = [];
    for (let i = 0; i < localStorage.length; i++) {
      const k = localStorage.key(i);
      if (k && k.startsWith(PREFIX)) stale.push(k);
    }
    stale.forEach((k) => localStorage.removeItem(k));
  } catch { /* ignore */ }
}
