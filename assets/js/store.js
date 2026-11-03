/* =====================================================================
   Off-Grid Survival Kit — on-device storage (IndexedDB)
   ---------------------------------------------------------------------
   Everything the user creates stays on this device. Nothing is uploaded.

   Database "ogsk", object stores:
     kv          free-form key/value (settings, in-progress track, rendezvous…)
     waypoints   { id, name, cat, lat, lon, alt?, note, created, updated }
     tracks      { id, name, points:[[lat,lon,alt|null,time,acc]], dist, created, updated, color? }
     checklists  { id, name, items:[{id, text, done}], created, updated }
     tiles       { key:"source/z/x/y", source, z, x, y, blob, size, t }

   Usage (all methods return Promises):
     OGStore.get('waypoints', id)      OGStore.put('waypoints', obj)
     OGStore.all('tracks')             OGStore.del('tracks', id)
     OGStore.kvGet('settings', {})     OGStore.kvSet('settings', obj)
     OGStore.uid()                     -> short unique id string
     OGStore.exportAll() / importAll(data, {replace})
   ===================================================================== */
(function () {
  'use strict';

  var DB_NAME = 'ogsk';
  var DB_VERSION = 1;
  var dbPromise = null;

  function open() {
    if (dbPromise) return dbPromise;
    dbPromise = new Promise(function (resolve, reject) {
      if (!('indexedDB' in window)) { reject(new Error('IndexedDB not available in this browser')); return; }
      var req = indexedDB.open(DB_NAME, DB_VERSION);
      req.onupgradeneeded = function () {
        var db = req.result;
        if (!db.objectStoreNames.contains('kv')) db.createObjectStore('kv');
        if (!db.objectStoreNames.contains('waypoints')) db.createObjectStore('waypoints', { keyPath: 'id' });
        if (!db.objectStoreNames.contains('tracks')) db.createObjectStore('tracks', { keyPath: 'id' });
        if (!db.objectStoreNames.contains('checklists')) db.createObjectStore('checklists', { keyPath: 'id' });
        if (!db.objectStoreNames.contains('tiles')) {
          var t = db.createObjectStore('tiles', { keyPath: 'key' });
          t.createIndex('source', 'source', { unique: false });
        }
      };
      req.onsuccess = function () {
        var db = req.result;
        db.onversionchange = function () { db.close(); dbPromise = null; };
        resolve(db);
      };
      req.onerror = function () { reject(req.error); };
      req.onblocked = function () { console.warn('IndexedDB upgrade blocked by another open tab'); };
    });
    return dbPromise;
  }

  /* Run fn(store) inside a transaction; resolves with the request result. */
  function tx(storeName, mode, fn) {
    return open().then(function (db) {
      return new Promise(function (resolve, reject) {
        var t = db.transaction(storeName, mode);
        var store = t.objectStore(storeName);
        var result;
        var req = fn(store);
        if (req && 'onsuccess' in req) req.onsuccess = function () { result = req.result; };
        t.oncomplete = function () { resolve(result); };
        t.onerror = function () { reject(t.error); };
        t.onabort = function () { reject(t.error || new Error('Transaction aborted')); };
      });
    });
  }

  var OGStore = {
    open: open,
    get: function (store, key) { return tx(store, 'readonly', function (s) { return s.get(key); }); },
    put: function (store, value, key) {
      return tx(store, 'readwrite', function (s) { return key === undefined ? s.put(value) : s.put(value, key); });
    },
    del: function (store, key) { return tx(store, 'readwrite', function (s) { return s.delete(key); }); },
    clear: function (store) { return tx(store, 'readwrite', function (s) { return s.clear(); }); },
    count: function (store) { return tx(store, 'readonly', function (s) { return s.count(); }); },
    all: function (store) { return tx(store, 'readonly', function (s) { return s.getAll(); }); },
    putMany: function (store, values) {
      return tx(store, 'readwrite', function (s) { values.forEach(function (v) { s.put(v); }); return null; });
    },

    kvGet: function (key, fallback) {
      return OGStore.get('kv', key).then(function (v) { return v === undefined ? fallback : v; })
        .catch(function () { return fallback; });
    },
    kvSet: function (key, value) { return OGStore.put('kv', value, key); },
    kvDel: function (key) { return OGStore.del('kv', key); },

    uid: function () {
      return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
    },

    /* ---------- map tiles ---------- */
    tileKey: function (source, z, x, y) { return source + '/' + z + '/' + x + '/' + y; },
    tileGet: function (source, z, x, y) { return OGStore.get('tiles', OGStore.tileKey(source, z, x, y)); },
    tileHas: function (source, z, x, y) {
      return tx('tiles', 'readonly', function (s) { return s.getKey(OGStore.tileKey(source, z, x, y)); })
        .then(function (k) { return k !== undefined; });
    },
    tilePut: function (source, z, x, y, blob) {
      return OGStore.put('tiles', {
        key: OGStore.tileKey(source, z, x, y), source: source, z: z, x: x, y: y,
        blob: blob, size: blob.size || 0, t: Date.now()
      });
    },
    /* Walk every saved tile and total up count + bytes, per source. */
    tileStats: function () {
      return open().then(function (db) {
        return new Promise(function (resolve, reject) {
          var stats = { count: 0, bytes: 0, bySource: {} };
          var t = db.transaction('tiles', 'readonly');
          var req = t.objectStore('tiles').openCursor();
          req.onsuccess = function () {
            var c = req.result;
            if (!c) return;
            var v = c.value;
            stats.count++; stats.bytes += v.size || 0;
            var b = stats.bySource[v.source] || (stats.bySource[v.source] = { count: 0, bytes: 0 });
            b.count++; b.bytes += v.size || 0;
            c.continue();
          };
          t.oncomplete = function () { resolve(stats); };
          t.onerror = function () { reject(t.error); };
        });
      });
    },
    tileClear: function (source) {
      if (!source) return OGStore.clear('tiles');
      return open().then(function (db) {
        return new Promise(function (resolve, reject) {
          var t = db.transaction('tiles', 'readwrite');
          var idx = t.objectStore('tiles').index('source');
          var req = idx.openKeyCursor(IDBKeyRange.only(source));
          req.onsuccess = function () {
            var c = req.result;
            if (!c) return;
            t.objectStore('tiles').delete(c.primaryKey);
            c.continue();
          };
          t.oncomplete = function () { resolve(); };
          t.onerror = function () { reject(t.error); };
        });
      });
    },

    /* ---------- backup / restore (tiles excluded: they can be re-downloaded) ---------- */
    exportAll: function () {
      return Promise.all([OGStore.all('waypoints'), OGStore.all('tracks'), OGStore.all('checklists'), kvEntries()])
        .then(function (r) {
          return {
            app: 'off-grid-survival-kit', format: 1, exported: new Date().toISOString(),
            waypoints: r[0], tracks: r[1], checklists: r[2], kv: r[3]
          };
        });
    },
    importAll: function (data, opts) {
      opts = opts || {};
      if (!data || data.app !== 'off-grid-survival-kit') return Promise.reject(new Error('Not an Off-Grid Survival Kit backup file'));
      var jobs = [];
      ['waypoints', 'tracks', 'checklists'].forEach(function (name) {
        var list = Array.isArray(data[name]) ? data[name].filter(function (v) { return v && v.id; }) : [];
        var p = opts.replace ? OGStore.clear(name) : Promise.resolve();
        jobs.push(p.then(function () { return list.length ? OGStore.putMany(name, list) : null; }));
      });
      if (data.kv && typeof data.kv === 'object') {
        Object.keys(data.kv).forEach(function (k) {
          // never resurrect an old in-progress recording; saved-area records describe tiles,
          // which backups don't contain, so they'd be misleading on another device
          if (k === 'track.current' || k === 'map.areas') return;
          jobs.push(OGStore.kvSet(k, data.kv[k]));
        });
      }
      return Promise.all(jobs).then(function () {
        return {
          waypoints: (data.waypoints || []).length, tracks: (data.tracks || []).length,
          checklists: (data.checklists || []).length
        };
      });
    },

    /* Ask the browser not to evict our data under storage pressure. */
    persist: function () {
      if (navigator.storage && navigator.storage.persist) {
        return navigator.storage.persisted().then(function (p) { return p || navigator.storage.persist(); })
          .catch(function () { return false; });
      }
      return Promise.resolve(false);
    },
    estimate: function () {
      if (navigator.storage && navigator.storage.estimate) return navigator.storage.estimate().catch(function () { return null; });
      return Promise.resolve(null);
    }
  };

  function kvEntries() {
    return open().then(function (db) {
      return new Promise(function (resolve, reject) {
        var out = {};
        var t = db.transaction('kv', 'readonly');
        var req = t.objectStore('kv').openCursor();
        req.onsuccess = function () {
          var c = req.result;
          if (!c) return;
          out[c.key] = c.value;
          c.continue();
        };
        t.oncomplete = function () { resolve(out); };
        t.onerror = function () { reject(t.error); };
      });
    });
  }

  /* Human-readable byte sizes, shared helper */
  OGStore.fmtBytes = function (n) {
    if (!n) return '0 B';
    var u = ['B', 'KB', 'MB', 'GB'], i = 0;
    while (n >= 1024 && i < u.length - 1) { n /= 1024; i++; }
    return (i ? n.toFixed(n < 10 ? 1 : 0) : n) + ' ' + u[i];
  };

  /* Waypoint categories — shared by the map, the tools page (rendezvous) and exports. */
  OGStore.WAYPOINT_CATS = {
    water:    { label: 'Water',          color: '#2f8cff' },
    camp:     { label: 'Camp / shelter', color: '#2fbf71' },
    food:     { label: 'Food / forage',  color: '#8bc34a' },
    cache:    { label: 'Cache / supply', color: '#c58b3c' },
    hazard:   { label: 'Hazard / danger',color: '#ff3b30' },
    rally:    { label: 'Rally point',    color: '#ff9f0a' },
    landmark: { label: 'Landmark',       color: '#a37cff' },
    medical:  { label: 'Medical',        color: '#ff4f9a' },
    custom:   { label: 'Custom',         color: '#9aa4ae' }
  };

  window.OGStore = OGStore;
})();
