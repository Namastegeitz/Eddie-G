/* =====================================================================
   Elevation (offline-capable)
   ---------------------------------------------------------------------
   Uses "Terrarium" elevation tiles (PNG, height = R*256 + G + B/256 - 32768 m),
   stored in the same IndexedDB tile store under source "dem". They are saved
   when you "Save this area" (zoom 10–12) and whenever they are looked up online.
   Provides:
     App.dem.at(lat, lon)  -> {elev, slope, aspect, z} (bilinear, ~30 m data)
     a contour-line overlay drawn locally with marching squares.
   Accuracy: source data are mostly SRTM (≈30 m, ±~10–20 m vertical) and
   USGS 3DEP in the US. Treat slope as a terrain-scale estimate, not a
   measurement of the ground under your boots.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var D2R = Math.PI / 180;
  var LOOKUP_ZOOMS = [12, 11, 10];
  var mem = new Map();                  // "z/x/y" -> Float32Array | null (LRU-ish)
  var pending = new Map();
  var MEM_MAX = 48;

  function demSrc() { return { id: 'dem', url: App.settings.demUrl, subdomains: 'abc' }; }

  function decodeTerrarium(img) {
    var c = document.createElement('canvas'); c.width = c.height = 256;
    var ctx = c.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(img, 0, 0, 256, 256);
    if (img.close) img.close();
    var d = ctx.getImageData(0, 0, 256, 256).data, out = new Float32Array(65536);
    for (var i = 0, j = 0; i < 65536; i++, j += 4) out[i] = d[j] * 256 + d[j + 1] + d[j + 2] / 256 - 32768;
    return out;
  }
  function remember(key, val) {
    if (mem.size >= MEM_MAX) mem.delete(mem.keys().next().value);
    mem.set(key, val);
  }

  /* Get decoded elevation data for one tile. allowFetch: may use the network (and saves the tile). */
  function tileData(z, x, y, allowFetch) {
    var key = z + '/' + x + '/' + y;
    if (mem.has(key) && (mem.get(key) || !allowFetch)) return Promise.resolve(mem.get(key));
    if (pending.has(key)) return pending.get(key);
    var p = OGStore.tileGet('dem', z, x, y).catch(function () { return null; }).then(function (rec) {
      if (rec) return App.decodeBlob(rec.blob).then(decodeTerrarium);
      if (!allowFetch || !navigator.onLine || !App.settings.demUrl) return null;
      return App.fetchBlob(App.tileUrl(demSrc(), z, x, y), 12000).then(function (blob) {
        OGStore.tilePut('dem', z, x, y, blob).catch(function () {});
        return App.decodeBlob(blob).then(decodeTerrarium);
      }, function () { return null; });
    }).then(function (data) {
      pending.delete(key);
      if (data || !allowFetch) remember(key, data);
      return data;
    }, function () { pending.delete(key); return null; });
    pending.set(key, p);
    return p;
  }

  function sample(data, fx, fy) {   // bilinear at fractional pixel coords (pixel centres at .5)
    fx = Math.max(0, Math.min(255, fx - 0.5)); fy = Math.max(0, Math.min(255, fy - 0.5));
    var x0 = Math.floor(fx), y0 = Math.floor(fy), x1 = Math.min(255, x0 + 1), y1 = Math.min(255, y0 + 1);
    var tx = fx - x0, ty = fy - y0;
    var a = data[y0 * 256 + x0], b = data[y0 * 256 + x1], c = data[y1 * 256 + x0], d = data[y1 * 256 + x1];
    return a * (1 - tx) * (1 - ty) + b * tx * (1 - ty) + c * (1 - tx) * ty + d * tx * ty;
  }
  function globalPx(lat, lon, z) {
    var n = Math.pow(2, z) * 256;
    lat = Math.max(-85.05, Math.min(85.05, lat));
    var r = lat * Math.PI / 180;
    return { x: (lon + 180) / 360 * n, y: (1 - Math.log(Math.tan(r) + 1 / Math.cos(r)) / Math.PI) / 2 * n };
  }

  function computeAt(data, z, tx, ty, g, lat) {
    var fx = g.x - tx * 256, fy = g.y - ty * 256;
    var e = sample(data, fx, fy);
    var mpp = 40075016.686 * Math.cos(lat * Math.PI / 180) / Math.pow(2, z + 8);
    var h = 1.5; // sample ±1.5 px (~±45 m at z12, 40°N)
    var dzdx = (sample(data, fx + h, fy) - sample(data, fx - h, fy)) / (2 * h * mpp);
    var dzdy = (sample(data, fx, fy - h) - sample(data, fx, fy + h)) / (2 * h * mpp); // north positive
    var slope = Math.atan(Math.sqrt(dzdx * dzdx + dzdy * dzdy)) * 180 / Math.PI;
    var aspect = slope < 1 ? null : OGGeo.norm360(Math.atan2(-dzdx, -dzdy) * 180 / Math.PI);
    return { elev: e, slope: slope, aspect: aspect, z: z };
  }

  App.dem = {
    /* Elevation, slope and aspect at a point. Uses saved data; fetches (and saves) if online. */
    at: function (lat, lon, allowFetch) {
      if (lat > 85 || lat < -85) return Promise.resolve(null);
      var i = 0;
      function tryNext() {
        if (i >= LOOKUP_ZOOMS.length) {
          if (allowFetch === false || !navigator.onLine) return Promise.resolve(null);
          var z = LOOKUP_ZOOMS[0], g = globalPx(lat, lon, z), tx = Math.floor(g.x / 256), ty = Math.floor(g.y / 256);
          return tileData(z, tx, ty, true).then(function (d) { return d ? computeAt(d, z, tx, ty, g, lat) : null; });
        }
        var z2 = LOOKUP_ZOOMS[i++], g2 = globalPx(lat, lon, z2), tx2 = Math.floor(g2.x / 256), ty2 = Math.floor(g2.y / 256);
        return tileData(z2, tx2, ty2, false).then(function (d) { return d ? computeAt(d, z2, tx2, ty2, g2, lat) : tryNext(); });
      }
      return tryNext();
    },
    fmtSlope: function (r) {
      if (!r) return '';
      var s = Math.round(r.slope) + '°';
      if (r.aspect != null) s += ' ' + OGGeo.cardinal(r.aspect) + '-facing';
      else s += ' (flat)';
      return s;
    },
    tileData: tileData
  };

  /* ---------------- contour overlay ---------------- */
  function interval(z) {
    if (App.settings.units === 'imperial') {
      var ft = z <= 10 ? 500 : z === 11 ? 250 : z === 12 ? 200 : z === 13 ? 100 : z === 14 ? 40 : 20;
      return ft * 0.3048;
    }
    return z <= 10 ? 200 : z === 11 ? 100 : z === 12 ? 50 : z <= 14 ? 20 : 10;
  }
  function contourColor() {
    var t = OGSK.theme();
    return t === 'day' ? '#8a3f0f' : t === 'red' ? '#ff4a3d' : '#ffa94d';
  }

  var ContourLayer = L.GridLayer.extend({
    options: { minZoom: 10, maxZoom: 20, tileSize: 256, pane: 'contourPane', updateWhenIdle: true },
    createTile: function (k, done) {
      var c = document.createElement('canvas'); c.width = c.height = 256;
      var demZ = Math.min(k.z, 12);
      var self = this;
      (function find(z, triesLeft) {
        var dz = k.z - z, px = k.x >> dz, py = k.y >> dz;
        return tileData(z, px, py, z === demZ).then(function (d) {
          if (d) return { d: d, dz: dz, px: px, py: py };
          if (triesLeft <= 0 || z <= 8) return null;
          return find(z - 1, triesLeft - 1);
        });
      })(demZ, 3).then(function (r) {
        if (r) self._draw(c, k, r);
        done(null, c);
      }, function (e) { done(e, c); });
      return c;
    },
    _draw: function (c, k, r) {
      var N = 64, step = 256 / N, s = 1 << r.dz, size = 256 / s;
      var ox = (k.x - r.px * s) * size, oy = (k.y - r.py * s) * size;
      var G = new Float32Array((N + 1) * (N + 1)), min = Infinity, max = -Infinity;
      for (var j = 0; j <= N; j++) for (var i = 0; i <= N; i++) {
        var v = sample(r.d, ox + (i * step) * size / 256 + 0.5, oy + (j * step) * size / 256 + 0.5);
        G[j * (N + 1) + i] = v; if (v < min) min = v; if (v > max) max = v;
      }
      var iv = interval(k.z);
      if (max - min < 1e-3) return;
      var ctx = c.getContext('2d');
      ctx.strokeStyle = contourColor(); ctx.lineCap = 'round';
      var first = Math.ceil(min / iv) * iv;
      for (var L = first; L <= max; L += iv) {
        var idxLine = Math.round(L / iv) % 5 === 0;
        ctx.lineWidth = idxLine ? 2 : 1; ctx.globalAlpha = idxLine ? 0.95 : 0.7;
        ctx.beginPath();
        for (j = 0; j < N; j++) for (i = 0; i < N; i++) {
          var a = G[j * (N + 1) + i], b = G[j * (N + 1) + i + 1], cc = G[(j + 1) * (N + 1) + i + 1], d = G[(j + 1) * (N + 1) + i];
          var idx = (a > L ? 8 : 0) | (b > L ? 4 : 0) | (cc > L ? 2 : 0) | (d > L ? 1 : 0);
          if (idx === 0 || idx === 15) continue;
          var x0 = i * step, y0 = j * step;
          var T = [x0 + step * (L - a) / (b - a), y0];
          var R = [x0 + step, y0 + step * (L - b) / (cc - b)];
          var B = [x0 + step * (L - d) / (cc - d), y0 + step];
          var Lf = [x0, y0 + step * (L - a) / (d - a)];
          var segs;
          switch (idx) {
            case 1: case 14: segs = [Lf, B]; break;
            case 2: case 13: segs = [B, R]; break;
            case 3: case 12: segs = [Lf, R]; break;
            case 4: case 11: segs = [T, R]; break;
            case 6: case 9: segs = [T, B]; break;
            case 7: case 8: segs = [Lf, T]; break;
            case 5: segs = ((a + b + cc + d) / 4 > L) ? [Lf, T, B, R] : [Lf, B, T, R]; break;
            case 10: segs = ((a + b + cc + d) / 4 > L) ? [T, R, Lf, B] : [Lf, T, B, R]; break;
          }
          for (var q = 0; q < segs.length; q += 2) { ctx.moveTo(segs[q][0], segs[q][1]); ctx.lineTo(segs[q + 1][0], segs[q + 1][1]); }
        }
        ctx.stroke();
      }
    }
  });

  /* ---------------- relief shading (hillshade) ----------------
     Computed on the device from the same elevation tiles (SRTM — measured by
     radar from the Space Shuttle — and USGS 3DEP). Light from the north-west,
     45° up (the cartographic convention); shadows darken, sunlit slopes lighten. */
  var ReliefLayer = L.GridLayer.extend({
    options: { minZoom: 8, maxZoom: 20, tileSize: 256, pane: 'reliefPane', updateWhenIdle: true },
    createTile: function (k, done) {
      var c = document.createElement('canvas'); c.width = c.height = 128;
      var demZ = Math.min(k.z, 12);
      (function find(z, triesLeft) {
        var dz = k.z - z, px = k.x >> dz, py = k.y >> dz;
        return tileData(z, px, py, z === demZ).then(function (d) {
          if (d) return { d: d, dz: dz, px: px, py: py };
          if (triesLeft <= 0 || z <= 8) return null;
          return find(z - 1, triesLeft - 1);
        });
      })(demZ, 3).then(function (r) { if (r) shade(c, k, r); done(null, c); }, function (e) { done(e, c); });
      return c;
    }
  });
  function shade(c, k, r) {
    var N = 128, s = 1 << r.dz, size = 256 / s;
    var ox = (k.x - r.px * s) * size, oy = (k.y - r.py * s) * size;
    var G = new Float32Array((N + 2) * (N + 2));
    for (var j = 0; j < N + 2; j++) for (var i = 0; i < N + 2; i++) {
      G[j * (N + 2) + i] = sample(r.d, ox + ((i - 0.5) / N) * size, oy + ((j - 0.5) / N) * size);
    }
    var latC = App.tile2lat(k.y + 0.5, k.z);
    var cell = 40075016.686 * Math.cos(latC * D2R) / Math.pow(2, k.z + 8) * (256 / N);   // metres per grid cell
    var zf = k.z < 11 ? 2 : 1.4;                        // a little vertical exaggeration so gentle relief still reads
    var az = 315 * D2R, alt = 45 * D2R;
    var Lx = Math.sin(az) * Math.cos(alt), Ly = Math.cos(az) * Math.cos(alt), Lz = Math.sin(alt), flat = Lz;
    var red = OGSK.theme() === 'red';
    var ctx = c.getContext('2d'), img = ctx.createImageData(N, N), px = img.data;
    for (j = 0; j < N; j++) for (i = 0; i < N; i++) {
      var w = N + 2, at = (j + 1) * w + (i + 1);
      var dzdx = (G[at + 1] - G[at - 1]) * zf / (2 * cell);
      var dzdy = (G[at - w] - G[at + w]) * zf / (2 * cell);   // north positive
      var nl = Math.sqrt(dzdx * dzdx + dzdy * dzdy + 1);
      var sh = (-dzdx * Lx - dzdy * Ly + Lz) / nl;
      var o = (j * N + i) * 4;
      if (sh < flat) { px[o] = px[o + 1] = px[o + 2] = 0; px[o + 3] = Math.min(200, (flat - sh) * 330); }
      else if (!red) { px[o] = px[o + 1] = px[o + 2] = 255; px[o + 3] = Math.min(110, (sh - flat) * 260); }
    }
    ctx.putImageData(img, 0, 0);
  }
  var reliefLayer = null;
  function applyRelief() {
    if (reliefLayer) { App.map.removeLayer(reliefLayer); reliefLayer = null; }
    if (App.settings.relief) {
      reliefLayer = new ReliefLayer().addTo(App.map);
      if (App.map.getZoom() < 8) OGSK.toast('Relief shading appears at zoom 8 and closer');
    }
  }

  var contourLayer = null;
  function applyContours() {
    if (contourLayer) { App.map.removeLayer(contourLayer); contourLayer = null; }
    if (App.settings.contours) {
      contourLayer = new ContourLayer().addTo(App.map);
      if (App.map.getZoom() < 10) OGSK.toast('Contours appear at zoom 10 and closer');
    }
  }

  /* centre readout: elevation + slope under the crosshair */
  var seq = 0;
  App.dem.updateCenter = function () {
    var c = App.map.getCenter(), my = ++seq;
    return App.dem.at(c.lat, c.lng, true).then(function (r) {
      if (my !== seq) return;
      App.centerElev = r;
      App.emit('center:elev', r);
    });
  };

  App.dem.init = function () {
    var pane = App.map.createPane('contourPane');
    pane.style.zIndex = 300; pane.style.pointerEvents = 'none';
    var cb = App.$('ov-contours');
    cb.checked = !!App.settings.contours;
    cb.addEventListener('change', function () { App.set('contours', cb.checked); applyContours(); });
    App.on('settings', function (e) { if (e.key === 'units' && contourLayer) contourLayer.redraw(); if (e.key === 'demUrl') { mem.clear(); applyContours(); } });
    document.addEventListener('ogsk:theme', function () { if (contourLayer) contourLayer.redraw(); });
    var demIn = App.$('set-dem');
    demIn.value = App.settings.demUrl;
    demIn.addEventListener('change', function () { App.set('demUrl', demIn.value.trim() || App.DEFAULTS.demUrl); });
    applyContours();
    var rp = App.map.createPane('reliefPane'); rp.style.zIndex = 260; rp.style.pointerEvents = 'none'; rp.style.opacity = '0.75';
    var rb = App.$('ov-relief');
    rb.checked = !!App.settings.relief;
    rb.addEventListener('change', function () { App.set('relief', rb.checked); applyRelief(); });
    document.addEventListener('ogsk:theme', function () { if (reliefLayer) reliefLayer.redraw(); });
    applyRelief();
    var t = null;
    App.map.on('moveend', function () { clearTimeout(t); t = setTimeout(App.dem.updateCenter, 250); });
    // new DEM tiles may have been saved: forget cached "not found" results
    App.on('tiles:changed', function () { mem.forEach(function (v, k) { if (!v) mem.delete(k); }); });
  };
})();
