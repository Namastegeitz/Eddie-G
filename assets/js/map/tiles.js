/* =====================================================================
   Offline tiles
   ---------------------------------------------------------------------
   OfflineTileLayer (a Leaflet GridLayer drawing into <canvas> tiles):
     1. look the tile up in IndexedDB  -> draw it          (works offline)
     2. else, if online, fetch it      -> draw it AND save it ("priming")
        (if the server blocks CORS, show it display-only; it can't be saved)
     3. else draw the best saved PARENT tile, scaled up (zoomed past what
        you saved = slightly blurry instead of blank)
     4. else leave the tile transparent -> the graticule shows through.
   Bulk "save this area": counts tiles for the view across zoom levels,
   estimates size, enforces caps, downloads with limited concurrency,
   skips tiles already saved, retries failures once, and records the area.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;

  /* ---------- tile sources ---------- */
  var OSM_ATTR = '&copy; <a href="https://www.openstreetmap.org/copyright" rel="noopener">OpenStreetMap</a> contributors';
  App.SOURCES = {
    osm: {
      id: 'osm', name: 'Streets', long: 'OpenStreetMap (streets)',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', maxNative: 19, bulkMax: 16, conc: 2, avgKB: 18, public: true,
      attr: OSM_ATTR,
      note: 'OpenStreetMap standard tiles: roads, trails, buildings, place names. Bulk saving limited to zoom ≤ 16 by OSM policy.'
    },
    topo: {
      id: 'topo', name: 'Terrain', long: 'OpenTopoMap (terrain + contours)',
      url: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', subdomains: 'abc', maxNative: 17, bulkMax: 16, conc: 2, avgKB: 32, public: true,
      attr: 'Map data: ' + OSM_ATTR + ', SRTM | Map style: &copy; OpenTopoMap (CC-BY-SA)',
      note: 'OpenTopoMap: contour lines, hill shading, trails and peaks — the best choice for backcountry use. Max detail zoom 17.'
    }
  };
  App.DEM = { id: 'dem', maxNative: 15, avgKB: 60 };

  function hash(s) { var h = 0; for (var i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0; return (h >>> 0).toString(36); }
  App.customSource = function () {
    var s = App.settings;
    return {
      id: 'custom-' + hash(s.customUrl || ''), name: 'Custom', long: s.customName || 'Custom tiles',
      url: s.customUrl, subdomains: 'abc', maxNative: Math.max(1, Math.min(22, +s.customMax || 18)),
      bulkMax: Math.max(1, Math.min(22, +s.customMax || 18)), conc: 6, avgKB: 25, public: false,
      attr: App.esc(s.customAttr || s.customName || 'Custom tiles'),
      note: 'Your own tile server. Larger download caps apply because you are not using a shared public server.'
    };
  };
  App.currentSource = function () {
    if (App.settings.source === 'custom' && App.settings.customUrl) return App.customSource();
    return App.SOURCES[App.settings.source] || App.SOURCES.osm;
  };

  function tileUrl(src, z, x, y) {
    var subs = src.subdomains || 'abc';
    return src.url
      .replace('{s}', subs.charAt(Math.abs(x + y) % subs.length))
      .replace('{z}', z).replace('{x}', x)
      .replace('{-y}', (Math.pow(2, z) - 1 - y))
      .replace('{y}', y).replace('{r}', '');
  }
  App.tileUrl = tileUrl;

  /* ---------- small helpers ---------- */
  var corsBlocked = {};          // source id -> true if fetch() fails but <img> works
  function fetchBlob(url, ms) {
    var ctl = window.AbortController ? new AbortController() : null;
    var timer = setTimeout(function () { if (ctl) ctl.abort(); }, ms || 12000);
    return fetch(url, { mode: 'cors', credentials: 'omit', signal: ctl ? ctl.signal : undefined })
      .then(function (r) {
        clearTimeout(timer);
        if (!r.ok) { var e = new Error('HTTP ' + r.status); e.http = r.status; throw e; }
        return r.blob();
      })
      .then(function (b) {
        if (!b.size || /text\/html|application\/json/.test(b.type)) throw new Error('Not an image');
        return b;
      }, function (e) { clearTimeout(timer); throw e; });
  }
  App.fetchBlob = fetchBlob;
  function decode(blob) {
    if (window.createImageBitmap) {
      return createImageBitmap(blob).catch(function () { return decodeImg(blob); });
    }
    return decodeImg(blob);
  }
  function decodeImg(blob) {
    return new Promise(function (resolve, reject) {
      var u = URL.createObjectURL(blob), im = new Image();
      im.onload = function () { URL.revokeObjectURL(u); resolve(im); };
      im.onerror = function () { URL.revokeObjectURL(u); reject(new Error('decode failed')); };
      im.src = u;
    });
  }
  App.decodeBlob = decode;
  function loadImgDirect(url) {      // display-only, no CORS needed
    return new Promise(function (resolve, reject) {
      var im = new Image();
      im.onload = function () { resolve(im); };
      im.onerror = function () { reject(new Error('img failed')); };
      im.src = url;
    });
  }

  /* Find the closest saved ancestor tile (up to 8 levels up). */
  function findParent(srcId, z, x, y, minZ) {
    var dz = 1;
    function next() {
      if (dz > 8 || z - dz < (minZ || 0)) return Promise.resolve(null);
      var pz = z - dz, px = x >> dz, py = y >> dz, d = dz;
      return OGStore.tileGet(srcId, pz, px, py).then(function (rec) {
        if (rec) return { rec: rec, dz: d, px: px, py: py };
        dz++; return next();
      });
    }
    return next();
  }
  App.findParent = findParent;

  /* ---------- the Leaflet layer ---------- */
  var OfflineTileLayer = L.GridLayer.extend({
    options: { tileSize: 256, updateWhenIdle: false, keepBuffer: 3 },
    initialize: function (src, opts) {
      this.src = src;
      L.GridLayer.prototype.initialize.call(this, L.extend({
        maxNativeZoom: src.maxNative, maxZoom: 20, attribution: src.attr, className: 'og-tiles'
      }, opts || {}));
    },
    createTile: function (coords, done) {
      var c = document.createElement('canvas');
      c.width = c.height = 256;
      c.setAttribute('role', 'presentation');
      var self = this;
      this._fill(c, coords).then(function (st) {
        c._og = st; done(null, c);
      }, function (err) { c._og = 'none'; done(err, c); });
      return c;
    },
    _fill: function (c, k) {
      var src = this.src, z = k.z, x = k.x, y = k.y;
      var ctx = c.getContext('2d');
      function draw(img) { ctx.drawImage(img, 0, 0, 256, 256); if (img.close) img.close(); }
      function drawParent() {
        return findParent(src.id, z, x, y).then(function (p) {
          if (!p) return 'none';
          return decode(p.rec.blob).then(function (img) {
            var s = 1 << p.dz, size = 256 / s;
            var sx = (x - p.px * s) * size, sy = (y - p.py * s) * size;
            ctx.imageSmoothingEnabled = true;
            ctx.drawImage(img, sx, sy, size, size, 0, 0, 256, 256);
            if (img.close) img.close();
            return 'parent';
          });
        });
      }
      return OGStore.tileGet(src.id, z, x, y).catch(function () { return null; }).then(function (rec) {
        if (rec) return decode(rec.blob).then(function (img) { draw(img); return 'cache'; });
        if (!navigator.onLine) return drawParent();
        var url = tileUrl(src, z, x, y);
        if (corsBlocked[src.id]) {
          return loadImgDirect(url).then(function (img) { draw(img); return 'display'; }, drawParent);
        }
        return fetchBlob(url).then(function (blob) {
          return decode(blob).then(function (img) {
            draw(img);
            if (App.settings.saveOnView) OGStore.tilePut(src.id, z, x, y, blob).then(function () { App.emit('tiles:changed'); }).catch(function () {});
            return 'net';
          });
        }, function (err) {
          if (err && err.http) return drawParent();          // 404 etc: no tile here
          // fetch failed: maybe offline-on-WiFi, maybe CORS. Show a parent now, then try plain <img>.
          return drawParent().then(function (st) {
            return loadImgDirect(url).then(function (img) {
              corsBlocked[src.id] = true;
              App.emit('tiles:cors', src);
              ctx.clearRect(0, 0, 256, 256); draw(img); return 'display';
            }, function () { return st; });
          });
        });
      });
    },
    /* How many tiles in view actually show something? */
    coverage: function () {
      var n = 0, shown = 0;
      for (var key in this._tiles) {
        var t = this._tiles[key];
        if (!t.current) continue;
        n++;
        if (t.el._og && t.el._og !== 'none') shown++;
      }
      return { total: n, shown: shown };
    }
  });
  App.OfflineTileLayer = OfflineTileLayer;

  /* ---------- base layer management ---------- */
  App.tiles = {};
  App.setBaseLayer = function () {
    var map = App.map, src = App.currentSource();
    if (App.baseLayer) map.removeLayer(App.baseLayer);
    App.baseLayer = new OfflineTileLayer(src, { pane: 'tilePane' });
    App.baseLayer.on('load', checkCoverage);
    App.baseLayer.on('tileerror', function () { setTimeout(checkCoverage, 50); });
    App.baseLayer.addTo(map);
    // tiles beyond the source's real max zoom are upscaled from maxNative
    App.emit('base', src);
    paintSourceUI();
  };
  var covTimer = null;
  function checkCoverage() {
    clearTimeout(covTimer);
    covTimer = setTimeout(function () {
      if (!App.baseLayer) return;
      var c = App.baseLayer.coverage();
      App.tiles.empty = c.total > 0 && c.shown === 0;
      App.emit('tiles:coverage', c);
    }, 120);
  }
  App.on('tiles:cors', function (src) {
    App.banner('This tile server does not allow its tiles to be stored, so <strong>' + App.esc(src.long) +
      '</strong> can be viewed online but not saved offline. Pick another base map for offline use.');
  });
  window.addEventListener('online', function () { if (App.baseLayer) App.baseLayer.redraw(); });

  /* ---------- tile maths ---------- */
  function lon2x(lon, z) { return Math.floor((lon + 180) / 360 * Math.pow(2, z)); }
  function lat2y(lat, z) {
    lat = Math.max(-85.05112878, Math.min(85.05112878, lat));
    var r = lat * Math.PI / 180;
    return Math.floor((1 - Math.log(Math.tan(r) + 1 / Math.cos(r)) / Math.PI) / 2 * Math.pow(2, z));
  }
  App.tile2lat = function (y, z) { var n = Math.PI - 2 * Math.PI * y / Math.pow(2, z); return 180 / Math.PI * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n))); };
  App.tile2lon = function (x, z) { return x / Math.pow(2, z) * 360 - 180; };
  App.lon2x = lon2x; App.lat2y = lat2y;

  function ranges(b, zooms) {
    var out = [];
    zooms.forEach(function (z) {
      var max = Math.pow(2, z) - 1;
      var x0 = Math.max(0, lon2x(b.west, z)), x1 = Math.min(max, lon2x(b.east, z));
      var y0 = Math.max(0, lat2y(b.north, z)), y1 = Math.min(max, lat2y(b.south, z));
      if (x1 < x0 || y1 < y0) return;
      out.push({ z: z, x0: x0, x1: x1, y0: y0, y1: y1, n: (x1 - x0 + 1) * (y1 - y0 + 1) });
    });
    return out;
  }
  function range(a, b) { var r = []; for (var i = a; i <= b; i++) r.push(i); return r; }

  /* Plan a "save this area" job for the current view. */
  App.tiles.plan = function (levels, withDem) {
    var map = App.map, src = App.currentSource();
    var bb = map.getBounds();
    var b = { west: Math.max(-180, bb.getWest()), east: Math.min(180, bb.getEast()), north: bb.getNorth(), south: bb.getSouth() };
    var zFrom = Math.max(0, Math.floor(map.getZoom()));
    var zWant = zFrom + levels;
    var zTo = Math.min(zWant, src.bulkMax);
    zFrom = Math.min(zFrom, zTo);
    var base = ranges(b, range(zFrom, zTo));
    var dem = [];
    if (withDem) {
      var dz = zTo < 10 ? [zTo] : range(Math.max(10, Math.min(zFrom, 12)), Math.min(zTo, 12));
      dem = ranges(b, dz);
    }
    var nBase = base.reduce(function (s, r) { return s + r.n; }, 0);
    var nDem = dem.reduce(function (s, r) { return s + r.n; }, 0);
    var caps = src.public ? { warn: 1000, max: 5000 } : { warn: 20000, max: 100000 };
    return {
      src: src, bounds: b, zFrom: zFrom, zTo: zTo, clipped: zWant > zTo, base: base, dem: dem,
      nBase: nBase, nDem: nDem, total: nBase + nDem,
      bytes: nBase * (App.tiles.avgBytes(src) || src.avgKB * 1024) + nDem * App.DEM.avgKB * 1024,
      caps: caps
    };
  };
  var measuredAvg = {};
  App.tiles.avgBytes = function (src) { return measuredAvg[src.id]; };

  /* ---------- bulk downloader ---------- */
  var job = null;
  App.tiles.run = function (plan, onProgress) {
    if (job) return Promise.reject(new Error('A download is already running'));
    var cancelled = false;
    job = { cancel: function () { cancelled = true; } };
    var demSrc = { id: App.DEM.id, url: App.settings.demUrl };
    var queue = [];
    plan.base.forEach(function (r) { queue.push({ src: plan.src, r: r }); });
    plan.dem.forEach(function (r) { queue.push({ src: demSrc, r: r }); });
    // lazy iterator over all tiles
    var qi = 0, x = null, y = null;
    function nextTile() {
      while (qi < queue.length) {
        var q = queue[qi], r = q.r;
        if (x === null) { x = r.x0; y = r.y0; }
        if (y > r.y1) { x++; y = r.y0; }
        if (x > r.x1) { qi++; x = null; continue; }
        var t = { src: q.src, z: r.z, x: x, y: y };
        y++;
        return t;
      }
      return null;
    }
    var st = { done: 0, total: plan.total, saved: 0, skipped: 0, failed: 0, bytes: 0, failedList: [] };
    var conc = plan.src.public ? plan.src.conc : plan.src.conc;
    var pause = plan.src.public ? 60 : 0;   // be gentle with volunteer servers

    function one(t) {
      return OGStore.tileHas(t.src.id, t.z, t.x, t.y).then(function (has) {
        if (has) { st.skipped++; return; }
        return fetchBlob(tileUrl(t.src, t.z, t.x, t.y), 20000).then(function (blob) {
          st.bytes += blob.size; st.saved++;
          return OGStore.tilePut(t.src.id, t.z, t.x, t.y, blob);
        }, function (err) {
          if (err && err.http === 404) { st.skipped++; return; } // e.g. ocean / outside coverage
          st.failed++; st.failedList.push(t);
        });
      });
    }
    function worker() {
      if (cancelled) return Promise.resolve();
      var t = nextTile();
      if (!t) return Promise.resolve();
      return one(t).then(function () {
        st.done++;
        onProgress && onProgress(st);
        return pause ? new Promise(function (r) { setTimeout(r, pause); }) : null;
      }).then(worker);
    }
    var workers = [];
    for (var i = 0; i < conc; i++) workers.push(worker());
    return Promise.all(workers).then(function () {
      // one retry pass for failures
      if (cancelled || !st.failedList.length) return;
      var retry = st.failedList.splice(0); st.failed = 0;
      return retry.reduce(function (p, t) { return p.then(function () { return cancelled ? null : one(t); }); }, Promise.resolve());
    }).then(function () {
      job = null;
      if (st.saved) measuredAvg[plan.src.id] = null; // recompute from stats next time
      st.cancelled = cancelled;
      App.emit('tiles:changed');
      return st;
    }, function (e) { job = null; throw e; });
  };
  App.tiles.cancel = function () { if (job) job.cancel(); };
  App.tiles.running = function () { return !!job; };

  /* ---------- Offline tab UI ---------- */
  var $ = App.$;
  function refreshEstimate() {
    if (!App.drawerOpen('offline')) return;
    var levels = +$('dl-levels').value, dem = $('dl-dem').checked;
    var p = App.tiles.plan(levels, dem);
    var tooBig = p.total > p.caps.max;
    var html = '<strong>' + App.esc(p.src.long) + '</strong><br>' +
      'Zoom ' + p.zFrom + ' → ' + p.zTo + ': <strong>' + p.nBase.toLocaleString() + '</strong> map tiles' +
      (p.nDem ? ' + ' + p.nDem.toLocaleString() + ' elevation tiles' : '') +
      '<br>Estimated size: <strong>~' + OGStore.fmtBytes(p.bytes) + '</strong>' +
      (p.clipped ? '<br><span class="muted">Capped at zoom ' + p.zTo + ' for this source.</span>' : '');
    if (tooBig) html += '<div class="callout danger" style="margin:8px 0 0"><strong class="callout-title">Too large</strong>' +
      p.total.toLocaleString() + ' tiles is over the ' + p.caps.max.toLocaleString() + '-tile limit per job. Zoom in, or choose fewer levels, and save the area in parts.</div>';
    else if (p.total > p.caps.warn) html += '<div class="callout warn" style="margin:8px 0 0"><strong class="callout-title">Large job</strong>This will take a while and use a lot of the tile server\'s bandwidth. Only continue if you need all of it.</div>';
    $('dl-estimate').innerHTML = html;
    $('dl-start').disabled = tooBig || p.total === 0 || App.tiles.running();
  }
  App.tiles.refreshEstimate = refreshEstimate;

  function startDownload() {
    var plan = App.tiles.plan(+$('dl-levels').value, $('dl-dem').checked);
    if (!navigator.onLine) { OGSK.toast('No connection — connect to download tiles', { error: true }); return; }
    if (plan.total > plan.caps.max) return;
    var confirmP = plan.total > plan.caps.warn
      ? App.ask({ title: 'Download ' + plan.total.toLocaleString() + ' tiles?', html: '<p>About ' + OGStore.fmtBytes(plan.bytes) + '. Keep this screen open until it finishes.</p>', ok: 'Download' })
      : Promise.resolve(true);
    confirmP.then(function (ok) {
      if (!ok) return;
      OGStore.persist().then(paintStorage);
      $('dl-progress').hidden = false; $('dl-cancel').hidden = false; $('dl-start').disabled = true;
      OGSK.wakeLock.request();
      var t0 = Date.now();
      App.tiles.run(plan, function (st) {
        var pct = Math.round(st.done / st.total * 100);
        $('dl-bar').style.width = pct + '%';
        $('dl-bar').parentNode.setAttribute('aria-valuenow', pct);
        $('dl-status').textContent = st.done.toLocaleString() + ' / ' + st.total.toLocaleString() + ' tiles · ' +
          st.saved + ' new, ' + st.skipped + ' already saved' + (st.failed ? ', ' + st.failed + ' failed' : '') +
          ' · ' + OGStore.fmtBytes(st.bytes);
      }).then(function (st) {
        OGSK.wakeLock.release();
        $('dl-cancel').hidden = true;
        var secs = Math.round((Date.now() - t0) / 1000);
        $('dl-status').textContent = (st.cancelled ? 'Cancelled. ' : 'Done. ') + st.saved + ' tiles saved (' + OGStore.fmtBytes(st.bytes) + '), ' +
          st.skipped + ' already saved' + (st.failed ? ', ' + st.failed + ' failed (try again later)' : '') + ' in ' + secs + ' s.';
        OGSK.toast(st.cancelled ? 'Download cancelled' : 'Area saved for offline use');
        if (st.saved || st.skipped) {
          return OGStore.kvGet('map.areas', []).then(function (areas) {
            var b = plan.bounds;
            areas.push({ id: OGStore.uid(), source: plan.src.id, sourceName: plan.src.long, bounds: [b.south, b.west, b.north, b.east],
              zFrom: plan.zFrom, zTo: plan.zTo, dem: plan.nDem > 0, tiles: st.saved + st.skipped, bytes: st.bytes, date: Date.now(), partial: !!(st.cancelled || st.failed) });
            return OGStore.kvSet('map.areas', areas);
          });
        }
      }).catch(function (e) {
        OGSK.wakeLock.release();
        $('dl-status').textContent = 'Error: ' + e.message;
      }).then(function () { refreshStats(); refreshEstimate(); App.emit('areas:changed'); });
    });
  }

  function refreshStats() {
    $('tile-stats').innerHTML = '<dt>Counting…</dt><dd></dd>';
    OGStore.tileStats().then(function (s) {
      var src = App.currentSource();
      var mine = s.bySource[src.id] || { count: 0, bytes: 0 };
      var dem = s.bySource.dem || { count: 0, bytes: 0 };
      if (mine.count) measuredAvg[src.id] = mine.bytes / mine.count;
      if (dem.count) App.DEM.avgKB = Math.max(5, dem.bytes / dem.count / 1024);
      $('tile-stats').innerHTML =
        '<dt>All saved tiles</dt><dd>' + s.count.toLocaleString() + ' · ' + OGStore.fmtBytes(s.bytes) + '</dd>' +
        '<dt>' + App.esc(src.long) + '</dt><dd>' + mine.count.toLocaleString() + ' · ' + OGStore.fmtBytes(mine.bytes) + '</dd>' +
        '<dt>Elevation data</dt><dd>' + dem.count.toLocaleString() + ' · ' + OGStore.fmtBytes(dem.bytes) + '</dd>';
      App.tiles.stats = s;
    }).catch(function (e) { $('tile-stats').innerHTML = '<dt>Error</dt><dd>' + App.esc(e.message) + '</dd>'; });
    OGStore.kvGet('map.areas', []).then(function (areas) {
      var ul = $('area-list');
      if (!areas.length) { ul.innerHTML = '<li class="empty">No areas saved yet.</li>'; return; }
      ul.innerHTML = areas.slice().reverse().map(function (a) {
        return '<li><button class="li-main" type="button" data-go="' + a.id + '"><strong>' + App.esc(a.sourceName) + ' · z' + a.zFrom + '–' + a.zTo +
          (a.partial ? ' (partial)' : '') + '</strong><small>' + new Date(a.date).toLocaleDateString() + ' · ' + a.tiles.toLocaleString() + ' tiles' +
          (a.dem ? ' + elevation' : '') + '</small></button><button class="btn" type="button" data-forget="' + a.id + '" aria-label="Remove from list">✕</button></li>';
      }).join('');
    });
  }
  App.tiles.refreshStats = refreshStats;

  function paintStorage() {
    Promise.all([OGStore.estimate(), navigator.storage && navigator.storage.persisted ? navigator.storage.persisted() : Promise.resolve(null)])
      .then(function (r) {
        var est = r[0], persisted = r[1];
        $('storage-info').innerHTML =
          (est ? '<dt>Used</dt><dd>' + OGStore.fmtBytes(est.usage || 0) + ' of ~' + OGStore.fmtBytes(est.quota || 0) + ' available</dd>' : '') +
          '<dt>Protected from cleanup</dt><dd>' + (persisted === null ? 'unknown' : persisted ? 'Yes' : 'No — install the app to the home screen to make storage persistent') + '</dd>';
      });
  }
  App.tiles.paintStorage = paintStorage;

  /* saved-area outlines */
  var areaLayer = null;
  function paintAreas() {
    if (areaLayer) { App.map.removeLayer(areaLayer); areaLayer = null; }
    if (!App.settings.showAreas) return;
    OGStore.kvGet('map.areas', []).then(function (areas) {
      areaLayer = L.layerGroup(areas.map(function (a) {
        return L.rectangle([[a.bounds[0], a.bounds[1]], [a.bounds[2], a.bounds[3]]],
          { color: '#ffb000', weight: 2, dashArray: '6 6', fill: false, interactive: false });
      })).addTo(App.map);
    });
  }
  App.on('areas:changed', paintAreas);

  /* source selector in the Layers tab */
  function paintSourceUI() {
    var seg = $('src-seg'), cur = App.settings.source;
    seg.innerHTML = ['osm', 'topo', 'custom'].map(function (id) {
      var name = id === 'custom' ? 'Custom URL' : App.SOURCES[id].long;
      return '<button class="btn" type="button" role="radio" data-src="' + id + '" aria-pressed="' + (cur === id) + '" aria-checked="' + (cur === id) + '">' + App.esc(name) + '</button>';
    }).join('');
    $('src-custom').hidden = cur !== 'custom';
    $('src-note').textContent = App.currentSource().note || '';
  }

  App.tiles.init = function () {
    $('src-seg').addEventListener('click', function (e) {
      var b = e.target.closest('[data-src]');
      if (!b) return;
      var id = b.getAttribute('data-src');
      if (id === 'custom') {
        $('src-custom').hidden = false;
        if (!App.settings.customUrl) { paintSourceUIPressed('custom'); $('custom-url').focus(); return; }
      }
      App.set('source', id);
      App.setBaseLayer();
    });
    function paintSourceUIPressed(id) {
      $('src-seg').querySelectorAll('[data-src]').forEach(function (b) { b.setAttribute('aria-pressed', b.getAttribute('data-src') === id); });
    }
    $('custom-url').value = App.settings.customUrl || '';
    $('custom-name').value = App.settings.customName || '';
    $('custom-max').value = App.settings.customMax || 18;
    $('custom-attr').value = App.settings.customAttr || '';
    $('custom-apply').addEventListener('click', function () {
      var u = $('custom-url').value.trim();
      if (!/^https?:\/\/.+\{z\}.*\{x\}.*(\{y\}|\{-y\})/i.test(u)) {
        OGSK.toast('URL must start with http(s):// and contain {z}, {x} and {y}', { error: true }); return;
      }
      App.set('customUrl', u);
      App.set('customName', $('custom-name').value.trim() || 'Custom tiles');
      App.set('customMax', +$('custom-max').value || 18);
      App.set('customAttr', $('custom-attr').value.trim());
      App.set('source', 'custom');
      App.setBaseLayer();
      OGSK.toast('Custom tiles in use');
    });

    $('dl-levels').addEventListener('change', refreshEstimate);
    $('dl-dem').addEventListener('change', refreshEstimate);
    $('dl-start').addEventListener('click', startDownload);
    $('dl-cancel').addEventListener('click', function () { App.tiles.cancel(); });
    $('tiles-refresh').addEventListener('click', function () { refreshStats(); paintStorage(); });
    $('tiles-clear').addEventListener('click', function () {
      App.ask({ title: 'Delete ALL saved map tiles?', html: '<p>Every saved map and elevation tile will be removed from this device. Waypoints and tracks are not affected. You will need a connection to download them again.</p>', ok: 'Delete all tiles', danger: true })
        .then(function (ok) {
          if (!ok) return;
          OGStore.tileClear().then(function () { return OGStore.kvSet('map.areas', []); }).then(function () {
            OGSK.toast('All saved tiles deleted'); refreshStats(); App.baseLayer.redraw(); App.emit('tiles:changed'); App.emit('areas:changed');
          });
        });
    });
    $('tiles-clear-src').addEventListener('click', function () {
      var src = App.currentSource();
      App.ask({ title: 'Delete saved tiles for ' + src.long + '?', html: '<p>Other base maps and elevation data are kept.</p>', ok: 'Delete', danger: true })
        .then(function (ok) {
          if (!ok) return;
          OGStore.tileClear(src.id).then(function () { return OGStore.kvGet('map.areas', []); }).then(function (areas) {
            return OGStore.kvSet('map.areas', areas.filter(function (a) { return a.source !== src.id; }));
          }).then(function () { OGSK.toast('Deleted'); refreshStats(); App.baseLayer.redraw(); App.emit('areas:changed'); });
        });
    });
    $('area-list').addEventListener('click', function (e) {
      var go = e.target.closest('[data-go]'), forget = e.target.closest('[data-forget]');
      OGStore.kvGet('map.areas', []).then(function (areas) {
        if (go) {
          var a = areas.filter(function (x) { return x.id === go.getAttribute('data-go'); })[0];
          if (a) { App.map.fitBounds([[a.bounds[0], a.bounds[1]], [a.bounds[2], a.bounds[3]]]); if (innerWidth < 800) App.closeDrawer(); }
        } else if (forget) {
          OGStore.kvSet('map.areas', areas.filter(function (x) { return x.id !== forget.getAttribute('data-forget'); }))
            .then(function () { refreshStats(); App.emit('areas:changed'); });
        }
      });
    });
    $('ov-areas').checked = !!App.settings.showAreas;
    $('ov-areas').addEventListener('change', function () { App.set('showAreas', this.checked); paintAreas(); });

    App.on('tab', function (t) {
      if (t === 'offline') { refreshEstimate(); refreshStats(); }
      if (t === 'settings') paintStorage();
    });
    App.map.on('moveend', refreshEstimate);
    paintAreas();
  };
})();
