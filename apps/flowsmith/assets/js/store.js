// FLOWSMITH storage. Two backends behind one interface:
//  - "cloud": the Claude artifact's db capability, private per person (data/users/<id>/...),
//    so folders follow the user to every device where they open the artifact.
//  - "device": IndexedDB in this browser (standalone app / PWA), with a memory fallback.
// Layout (both backends):
//   song meta:  <base>/<songId>                 {kind:"song", title, ...}
//   versions:   <base>/<songId>/versions/v0001  {n, prompt, lyrics, chips, state, ...}
//   misc docs:  <base>/_settings, _lessons, _traces, _snippets

const pad = (n) => String(n).padStart(4, "0");
export const newId = (prefix = "s") => `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`;

// One write at a time per document (db rule), coalesced per key.
function writeQueue() {
  const chains = new Map();
  return (key, fn) => {
    const prev = chains.get(key) || Promise.resolve();
    const next = prev.catch(() => {}).then(fn);
    chains.set(key, next);
    return next;
  };
}

// ---------- cloud (artifact db) ----------
async function cloudStore() {
  const C = globalThis.claude;
  if (!C || typeof C.use !== "function") return null;
  const [db, user] = await Promise.all([C.use("db"), C.use("user")]);
  if (!db || !user) return null;
  const uid = await user.id();
  if (!uid) return null;
  const base = `data/users/${uid}`;
  const col = db.collection(base);
  const q = writeQueue();
  const songDoc = (id) => db.doc(`${base}/${id}`);
  const verCol = (id) => songDoc(id).collection("versions");
  const strip = (o) => JSON.parse(JSON.stringify(o)); // plain JSON only

  return {
    kind: "cloud",
    label: "Saved to your Claude account (all your devices)",
    watchSongs(cb, onError) {
      let timer = setTimeout(() => onError && onError({ code: "slow", message: "Your saved songs are taking a while to load." }), 10000);
      return col.where("kind", "==", "song").onSnapshot((snap) => {
        if (!snap.metadata.fromCache) { clearTimeout(timer); timer = null; }
        cb(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      }, (e) => { clearTimeout(timer); onError && onError(e); });
    },
    async getSong(id) { const s = await songDoc(id).get(); return s.exists ? { id: s.id, ...s.data() } : null; },
    putSong(song) { const { id, ...rest } = song; return q(id, () => songDoc(id).set(strip({ ...rest, kind: "song" }))); },
    async deleteSong(id) {
      const vs = await verCol(id).get();
      for (const d of vs.docs) await verCol(id).doc(d.id).delete();
      await q(id, () => songDoc(id).delete());
    },
    async listVersions(id) { const s = await verCol(id).get(); return s.docs.map((d) => d.data()).sort((a, b) => a.n - b.n); },
    watchVersions(id, cb, onError) { return verCol(id).onSnapshot((s) => cb(s.docs.map((d) => d.data()).sort((a, b) => a.n - b.n)), onError); },
    putVersion(id, v) { return q(`${id}/v${pad(v.n)}`, () => verCol(id).doc(`v${pad(v.n)}`).set(strip(v))); },
    async getDoc(name, fallback) { const s = await db.doc(`${base}/_${name}`).get(); return s.exists ? s.data() : fallback; },
    putDoc(name, obj) { return q(`_${name}`, () => db.doc(`${base}/_${name}`).set(strip(obj))); },
  };
}

// ---------- device (IndexedDB, memory fallback) ----------
function idb() {
  return new Promise((resolve, reject) => {
    try {
      const req = indexedDB.open("flowsmith", 1);
      req.onupgradeneeded = () => req.result.createObjectStore("kv");
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    } catch (e) { reject(e); }
  });
}
async function deviceStore() {
  let handle = null;
  try { handle = await idb(); } catch { handle = null; }
  const mem = new Map();
  const tx = (mode, fn) => new Promise((res, rej) => {
    const t = handle.transaction("kv", mode); const s = t.objectStore("kv");
    const r = fn(s); t.oncomplete = () => res(r && r.result); t.onerror = () => rej(t.error);
  });
  const get = async (k) => handle ? tx("readonly", (s) => s.get(k)) : mem.get(k);
  const put = async (k, v) => handle ? tx("readwrite", (s) => s.put(v, k)) : mem.set(k, v);
  const del = async (k) => handle ? tx("readwrite", (s) => s.delete(k)) : mem.delete(k);
  const keys = async () => handle ? tx("readonly", (s) => s.getAllKeys()) : [...mem.keys()];
  const clone = (o) => JSON.parse(JSON.stringify(o));
  const listeners = new Set();
  const verListeners = new Map();
  const listSongs = async () => {
    const ks = (await keys()).filter((k) => k.startsWith("song:"));
    const out = [];
    for (const k of ks) { const v = await get(k); if (v) out.push({ id: k.slice(5), ...v }); }
    return out;
  };
  const emit = async () => { const s = await listSongs(); listeners.forEach((cb) => cb(s)); };
  const listVersions = async (id) => {
    const ks = (await keys()).filter((k) => k.startsWith(`ver:${id}:`));
    const out = []; for (const k of ks) out.push(await get(k));
    return out.filter(Boolean).sort((a, b) => a.n - b.n);
  };
  const emitV = async (id) => { const cbs = verListeners.get(id); if (cbs && cbs.size) { const v = await listVersions(id); cbs.forEach((cb) => cb(v)); } };
  return {
    kind: "device",
    label: handle ? "Saved on this device" : "Not saved (this browser blocks storage); export to keep your work",
    watchSongs(cb) { listeners.add(cb); listSongs().then(cb); return () => listeners.delete(cb); },
    async getSong(id) { const v = await get(`song:${id}`); return v ? { id, ...v } : null; },
    async putSong(song) { const { id, ...rest } = song; await put(`song:${id}`, clone({ ...rest, kind: "song" })); emit(); },
    async deleteSong(id) { for (const k of (await keys()).filter((k) => k.startsWith(`ver:${id}:`))) await del(k); await del(`song:${id}`); emit(); },
    listVersions,
    watchVersions(id, cb) { if (!verListeners.has(id)) verListeners.set(id, new Set()); verListeners.get(id).add(cb); listVersions(id).then(cb); return () => verListeners.get(id).delete(cb); },
    async putVersion(id, v) { await put(`ver:${id}:${pad(v.n)}`, clone(v)); emitV(id); },
    async getDoc(name, fallback) { const v = await get(`doc:${name}`); return v === undefined ? fallback : v; },
    async putDoc(name, obj) { await put(`doc:${name}`, clone(obj)); },
  };
}

/** Pick the best storage this view allows. Resolves within ~10 s even if the host never answers. */
export async function openStore({ preferCloud = true } = {}) {
  if (preferCloud && globalThis.claude) {
    try {
      const s = await Promise.race([cloudStore(), new Promise((r) => setTimeout(() => r(null), 11000))]);
      if (s) return s;
    } catch { /* fall through */ }
  }
  return deviceStore();
}

/** Everything as one JSON object (backup / move between devices). */
export async function exportAll(store, songs) {
  const out = { app: "flowsmith", version: 1, exportedAt: new Date().toISOString(), songs: [], docs: {} };
  for (const s of songs) out.songs.push({ ...s, versions: await store.listVersions(s.id) });
  for (const name of ["settings", "lessons", "snippets"]) out.docs[name] = await store.getDoc(name, null);
  if (out.docs.settings) delete out.docs.settings.apiKey; // never export the key
  return out;
}

/** Merge a backup in. Songs with the same id are skipped unless overwrite is true. */
export async function importAll(store, data, existingIds, { overwrite = false } = {}) {
  if (!data || data.app !== "flowsmith" || !Array.isArray(data.songs)) throw new Error("That isn't a FLOWSMITH backup.");
  let added = 0, skipped = 0;
  for (const s of data.songs) {
    if (!s || !s.id || typeof s.title !== "string") { skipped++; continue; }
    if (existingIds.has(s.id) && !overwrite) { skipped++; continue; }
    const { versions = [], ...meta } = s;
    for (const v of versions) if (v && Number.isInteger(v.n)) await store.putVersion(s.id, v);
    await store.putSong(meta);
    added++;
  }
  if (data.docs?.lessons?.items) {
    const cur = await store.getDoc("lessons", { items: [] });
    const have = new Set(cur.items.map((l) => l.id));
    cur.items.push(...data.docs.lessons.items.filter((l) => l && l.id && !have.has(l.id)));
    await store.putDoc("lessons", cur);
  }
  if (data.docs?.snippets?.items) {
    const cur = await store.getDoc("snippets", { items: [] });
    const have = new Set(cur.items.map((l) => l.id));
    cur.items.push(...data.docs.snippets.items.filter((l) => l && l.id && !have.has(l.id)));
    await store.putDoc("snippets", cur);
  }
  return { added, skipped };
}
