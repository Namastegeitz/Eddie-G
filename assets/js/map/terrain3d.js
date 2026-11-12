/* =====================================================================
   3D terrain view — raw WebGL 1, no libraries, works offline
   ---------------------------------------------------------------------
   Opens a full-screen 3D model of the area shown on the map:
     1. AREA     the current map view, clamped to 1.5–25 km a side.
     2. HEIGHTS  Terrarium elevation tiles (App.dem.tileData; saved offline
                 at zoom 10–12) at DEM zoom 9–12, bilinear-sampled into a
                 grid of up to 181 × 181 vertices. Missing tiles are filled
                 from other saved zooms; no data at all -> a flat plane and
                 a clear message instead of a failure.
     3. TEXTURE  the base map composed into one canvas (tiles already on
                 screen, saved tiles, online tiles, saved lower-zoom tiles),
                 over an elevation-tint + hillshade fallback; saved tracks,
                 breadcrumb, route, waypoints and GPS drawn on top.
     4. RENDER   triangle grid + solid base ("skirt"), lambert lighting
                 from the real sun direction (SunCalc) when it is up, else
                 a fixed NW light; orbit camera (drag / pinch / wheel /
                 buttons). Frames are drawn ON DEMAND (interaction, spin,
                 animation) — never a constant 60 fps loop.
   World space: local tangent plane in metres around the area centre —
   x = east, z = south, y = up (height above the area minimum × exaggeration).
   Texture space is the Web-Mercator box of the area, so it lines up with
   map tiles exactly.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  if (!App) return;

  var D2R = Math.PI / 180, CIRC = 40075016.686;
  var MIN_SIDE = 1500, MAX_SIDE = 25000;        // metres
  var GRID = 181;                               // vertices along the long side (< 65,536 total: Uint16 indices)
  var TEX_MAX = 2048;                           // texture long side (px)
  var FOV = 50, PITCH_MIN = 10, PITCH_MAX = 89; // degrees
  var ABORT = { abort: true };

  var ui = {}, canvas = null, gl = null, glx = null, scene = null, seq = 0, isOpen = false;
  var cam = { yaw: 0, pitch: 45, dist: 1000, tx: 0, tz: 0 };
  var exag = 1.5, spin = false, raf = 0, lastT = 0, anim = null, ro = null;
  var reduceMotion = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;

  function $(id) { return document.getElementById(id); }
  function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
  function noop() {}

  /* ---------------- Web-Mercator helpers (0..1 world units) ---------------- */
  function mercX(lon) { return (lon + 180) / 360; }
  function mercY(lat) {
    var s = Math.sin(clamp(lat, -85.05112878, 85.05112878) * D2R);
    return 0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI);
  }
  function wrapX(x, n) { return ((x % n) + n) % n; }

  /* The area: the map view, each side clamped to 1.5–25 km. Mercator is conformal,
     so one scale (metres per Mercator unit at the centre latitude) serves both axes. */
  function computeArea() {
    var map = App.map, b = map.getBounds(), c = map.getCenter();
    var mpu = CIRC * Math.cos(c.lat * D2R);
    var cx = mercX(c.lng), cy = mercY(c.lat);
    var w = clamp((mercX(b.getEast()) - mercX(b.getWest())) * mpu, MIN_SIDE, MAX_SIDE);
    var d = clamp((mercY(b.getSouth()) - mercY(b.getNorth())) * mpu, MIN_SIDE, MAX_SIDE);
    var hx = w / 2 / mpu, hy = d / 2 / mpu;
    return { lat: c.lat, lon: c.lng, cx: cx, cy: cy, mpu: mpu, W: w, D: d,
      x0: cx - hx, x1: cx + hx, y0: Math.max(0, cy - hy), y1: Math.min(1, cy + hy) };
  }
  function tileRange(a, z) {
    var n = Math.pow(2, z);
    return { z: z, n: n, x0: Math.floor(a.x0 * n), x1: Math.floor(a.x1 * n - 1e-9),
      y0: Math.floor(a.y0 * n), y1: Math.min(n - 1, Math.floor(a.y1 * n - 1e-9)) };
  }
  function rangeCount(r) { return (r.x1 - r.x0 + 1) * (r.y1 - r.y0 + 1); }

  /* small promise pool: run fn over items, n at a time; errors are swallowed per item */
  function pool(items, n, fn) {
    var i = 0, w = [];
    function next() { if (i >= items.length) return null; var it = items[i++]; return Promise.resolve(it).then(fn).catch(noop).then(next); }
    for (var k = 0; k < Math.min(n, items.length); k++) w.push(next());
    return Promise.all(w);
  }

  /* ======================= 2. ELEVATION ======================= */
  function loadDemLevel(a, z, allowFetch, live, onTile) {
    var r = tileRange(a, z), jobs = [], L = { z: z, n: r.n, tiles: {}, got: 0, total: 0 };
    for (var x = r.x0; x <= r.x1; x++) for (var y = r.y0; y <= r.y1; y++) jobs.push([x, y]);
    L.total = jobs.length;
    return Promise.all(jobs.map(function (j) {
      return App.dem.tileData(z, wrapX(j[0], r.n), j[1], allowFetch).catch(noop).then(function (d) {
        if (d && live()) { L.tiles[j[0] * 4096 + j[1]] = d; L.got++; }   // keyed by unwrapped x
        if (onTile) onTile();
      });
    })).then(function () { return L; });
  }

  /* DEM zoom: the finest of 12..9 at which the area spans at most 4 × 4 tiles.
     That zoom may download (when online); gaps are then filled from whatever
     other zooms are saved on the device (finer first), without the network. */
  function loadDem(a, live, progress) {
    var dz = 9, z;
    for (z = 12; z > 9; z--) { var r = tileRange(a, z); if (r.x1 - r.x0 < 4 && r.y1 - r.y0 < 4) { dz = z; break; } }
    var done = 0, total = rangeCount(tileRange(a, dz));
    return loadDemLevel(a, dz, true, live, function () { progress(++done, total); }).then(function (L) {
      var levels = L.got ? [L] : [];
      if (L.got === L.total) return { dz: dz, levels: levels };
      var others = [12, 11, 10, 9].filter(function (q) { return q !== dz && rangeCount(tileRange(a, q)) <= 36; });
      return others.reduce(function (p, q) {
        return p.then(function (complete) {
          if (complete || !live()) return true;
          return loadDemLevel(a, q, false, live).then(function (M) { if (M.got) levels.push(M); return M.got === M.total; });
        });
      }, Promise.resolve(false)).then(function () { return { dz: dz, levels: levels }; });
    });
  }

  /* Elevation at a Mercator point: bilinear over DEM pixels, across tile seams,
     from the first level that has data there. NaN = no data anywhere. */
  function demSampler(levels) {
    function pix(L, ix, iy) {
      var d = L.tiles[(ix >> 8) * 4096 + (iy >> 8)];
      if (!d) return NaN;
      var v = d[(iy & 255) * 256 + (ix & 255)];
      return v < -11000 || v > 9000 ? NaN : v;          // voids / junk
    }
    return function (mx, my) {
      for (var k = 0; k < levels.length; k++) {
        var L = levels[k], np = L.n * 256, gx = mx * np - 0.5, gy = my * np - 0.5;
        var ix = Math.floor(gx), iy = Math.floor(gy), fx = gx - ix, fy = gy - iy;
        var a = pix(L, ix, iy), b = pix(L, ix + 1, iy), c = pix(L, ix, iy + 1), d = pix(L, ix + 1, iy + 1);
        if (a !== a || b !== b || c !== c || d !== d) {   // a neighbour is missing: average what is there
          var s = 0, m = 0;
          if (a === a) { s += a; m++; } if (b === b) { s += b; m++; } if (c === c) { s += c; m++; } if (d === d) { s += d; m++; }
          if (!m) continue;
          s /= m; if (a !== a) a = s; if (b !== b) b = s; if (c !== c) c = s; if (d !== d) d = s;
        }
        return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy;
      }
      return NaN;
    };
  }

  /* Height grid (row-major, north row first) + slope components for normals/hillshade. */
  function buildGrid(a, sample) {
    var nx = GRID, ny = GRID;
    if (a.W >= a.D) ny = Math.max(3, Math.round((GRID - 1) * a.D / a.W) + 1);
    else nx = Math.max(3, Math.round((GRID - 1) * a.W / a.D) + 1);
    var N = nx * ny, H = new Float32Array(N), have = 0, sum = 0, min = Infinity, max = -Infinity, i, j, k;
    for (j = 0; j < ny; j++) {
      var my = a.y0 + (a.y1 - a.y0) * j / (ny - 1);
      for (i = 0; i < nx; i++) {
        var v = sample ? sample(a.x0 + (a.x1 - a.x0) * i / (nx - 1), my) : NaN;
        H[j * nx + i] = v;
        if (v === v) { have++; sum += v; if (v < min) min = v; if (v > max) max = v; }
      }
    }
    var mean = have ? sum / have : 0, miss = new Uint8Array(N);
    if (have < N) for (k = 0; k < N; k++) if (H[k] !== H[k]) { H[k] = mean; miss[k] = 1; }   // unknown: flat at the mean
    if (!have) min = max = 0;
    var g = { nx: nx, ny: ny, H: H, miss: miss, min: min, max: max, mean: mean, have: have / N, dx: a.W / (nx - 1), dz: a.D / (ny - 1),
      gx: new Float32Array(N), gz: new Float32Array(N) };
    for (j = 0; j < ny; j++) for (i = 0; i < nx; i++) {     // central differences (one-sided at edges)
      var il = Math.max(0, i - 1), ir = Math.min(nx - 1, i + 1), jn = Math.max(0, j - 1), js = Math.min(ny - 1, j + 1);
      g.gx[j * nx + i] = (H[j * nx + ir] - H[j * nx + il]) / ((ir - il) * g.dx);
      g.gz[j * nx + i] = (H[js * nx + i] - H[jn * nx + i]) / ((js - jn) * g.dz);
    }
    return g;
  }
  /* bilinear ground height (metres, unexaggerated) at local x/z metres */
  function groundAt(x, z) {
    var g = scene.grid, a = scene.area, n = g.nx, H = g.H;
    var fi = clamp((x + a.W / 2) / g.dx, 0, g.nx - 1), fj = clamp((z + a.D / 2) / g.dz, 0, g.ny - 1);
    var i = Math.min(g.nx - 2, Math.floor(fi)), j = Math.min(g.ny - 2, Math.floor(fj)), tx = fi - i, tz = fj - j;
    return (H[j * n + i] * (1 - tx) + H[j * n + i + 1] * tx) * (1 - tz) + (H[(j + 1) * n + i] * (1 - tx) + H[(j + 1) * n + i + 1] * tx) * tz;
  }

  /* ======================= 3. TEXTURE ======================= */
  // hypsometric tint: greens -> tan -> browns -> greys -> white
  var RAMP = [[0, 79, 127, 69], [0.18, 120, 163, 90], [0.36, 181, 191, 122], [0.54, 201, 168, 110],
    [0.72, 156, 118, 80], [0.86, 154, 148, 140], [1, 242, 242, 242]];
  function ramp(t, out) {
    t = clamp(t, 0, 1);
    for (var i = 1; i < RAMP.length; i++) if (t <= RAMP[i][0]) break;
    var p = RAMP[i - 1], q = RAMP[Math.min(i, RAMP.length - 1)], f = q[0] > p[0] ? (t - p[0]) / (q[0] - p[0]) : 0;
    for (var c = 1; c < 4; c++) out[c - 1] = p[c] + (q[c] - p[c]) * f;
    return out;
  }

  /* Fallback layer: elevation colours + hillshade (NW light), one pixel per grid vertex,
     upscaled by the canvas' bilinear smoothing so pixel centres land on the vertices. */
  function drawFallback(T, g) {
    var c = document.createElement('canvas'); c.width = g.nx; c.height = g.ny;
    var cx = c.getContext('2d'), img = cx.createImageData(g.nx, g.ny), d = img.data;
    var flat = !g.have, range = Math.max(g.max - g.min, 300), rgb = [0, 0, 0];
    for (var k = 0, N = g.nx * g.ny; k < N; k++) {
      var h = g.H[k], f = 1;
      if (flat || g.miss[k]) { rgb[0] = 167; rgb[1] = 173; rgb[2] = 151; }      // neutral = height unknown
      else {
        if (h <= 0) { rgb[0] = 110; rgb[1] = 160; rgb[2] = 205; }             // sea level and below: water
        else ramp((h - g.min) / range, rgb);
        // hillshade: normal from slope (×2 to read clearly), light from NW 45° up; flat ground = 1
        var nx = -2 * g.gx[k], nz = -2 * g.gz[k];
        f = clamp(1 + 0.9 * ((-0.5 * nx + 0.7071 - 0.5 * nz) / Math.sqrt(nx * nx + 1 + nz * nz) - 0.7071), 0.5, 1.25);
      }
      d[k * 4] = rgb[0] * f; d[k * 4 + 1] = rgb[1] * f; d[k * 4 + 2] = rgb[2] * f; d[k * 4 + 3] = 255;
    }
    cx.putImageData(img, 0, 0);
    var ctx = T.ctx, hx = T.cw / (g.nx - 1) / 2, hz = T.ch / (g.ny - 1) / 2;
    ctx.imageSmoothingEnabled = true;
    ctx.drawImage(c, -hx, -hz, T.cw + 2 * hx, T.ch + 2 * hz);
    if (flat) {    // no heights: a 1 km (or 5 km) grid so the plane still shows scale
      var step = Math.max(T.a.W, T.a.D) > 12000 ? 5000 : 1000, ppm = T.cw / T.a.W;
      ctx.strokeStyle = 'rgba(0,0,0,.22)'; ctx.lineWidth = Math.max(1, T.cw / 600); ctx.beginPath();
      for (var x = step; x < T.a.W; x += step) { ctx.moveTo(x * ppm, 0); ctx.lineTo(x * ppm, T.ch); }
      for (var z = step; z < T.a.D; z += step) { ctx.moveTo(0, z * ppm); ctx.lineTo(T.cw, z * ppm); }
      ctx.stroke();
    }
  }

  function tileRect(T, z, x, y) {
    var a = T.a, s = Math.pow(2, -z), kx = T.cw / (a.x1 - a.x0), ky = T.ch / (a.y1 - a.y0);
    return { x: (x * s - a.x0) * kx, y: (y * s - a.y0) * ky, w: s * kx, h: s * ky };
  }

  /* Map tiles, best first per cell; drawn lowest-detail first so sharper ones win.
     a) canvases the map already shows (skip CORS-tainted 'display' ones: they would
        taint the texture); b) saved tiles; c) online (saved, like the map does);
     d) the 4 saved tiles one zoom finer (areas are often saved above the texture zoom);
     e) a saved tile up to 3 zooms coarser, scaled up. Anything else keeps the elevation colours. */
  function drawTiles(T, live, progress) {
    var a = T.a, src = T.src, tz = T.tz, r = tileRange(a, tz), n = r.n, cells = [], draws = [], parents = {};
    var st = { total: 0, real: 0, net: 0, parent: 0, kids: 0, screen: 0 }, x, y, done = 0;
    for (x = r.x0; x <= r.x1; x++) for (y = r.y0; y <= r.y1; y++) cells.push({ x: x, y: y, cov: -1 });
    st.total = cells.length;
    function cellAt(cx, cy) { return cells[(cx - r.x0) * (r.y1 - r.y0 + 1) + (cy - r.y0)]; }
    var tiles = (App.baseLayer && App.baseLayer.src && App.baseLayer.src.id === src.id && App.baseLayer._tiles) || {};
    Object.keys(tiles).forEach(function (key) {
      var t = tiles[key], el = t.el, k = t.coords;
      if (el && el._og === 'display') st.blocked = true;      // server forbids reuse (no CORS)
      if (!el || !k || !el.width || !/^(cache|net)$/.test(el._og || '')) return;   // not 'parent': maybe 32× blurry
      var rc = tileRect(T, k.z, k.x, k.y);
      if (rc.x > T.cw || rc.y > T.ch || rc.x + rc.w < 0 || rc.y + rc.h < 0) return;
      draws.push({ img: el, z: k.z, x: k.x, y: k.y, rank: k.z });
      if (k.z > tz) return;
      var s = Math.pow(2, tz - k.z);    // texture cells this tile covers completely
      for (var cx = Math.max(r.x0, k.x * s); cx <= Math.min(r.x1, (k.x + 1) * s - 1); cx++)
        for (var cy = Math.max(r.y0, k.y * s); cy <= Math.min(r.y1, (k.y + 1) * s - 1); cy++) cellAt(cx, cy).cov = k.z;
    });
    function tick() { progress(++done, cells.length); }
    return pool(cells, 8, function (c) {
      if (!live()) return;
      return OGStore.tileGet(src.id, tz, wrapX(c.x, n), c.y).then(function (rec) {
        if (rec) return App.decodeBlob(rec.blob).then(function (img) { c.img = img; c.how = 'cache'; tick(); });
      });
    }).then(function () {
      var miss = cells.filter(function (c) { return !c.img; }), stopAt = performance.now() + 8000, dead = false;
      if (!miss.length || !navigator.onLine || !src.url || !live()) return;
      return pool(miss, src.public ? 2 : 6, function (c) {    // "online" but no real signal: give up fast
        if (!live() || dead || performance.now() > stopAt) return;
        return App.fetchBlob(App.tileUrl(src, tz, wrapX(c.x, n), c.y), 8000).then(function (blob) {
          if (App.settings.saveOnView) OGStore.tilePut(src.id, tz, wrapX(c.x, n), c.y, blob).catch(noop);
          return App.decodeBlob(blob).then(function (img) { c.img = img; c.how = 'net'; tick(); });
        }, function (e) { if (!e || !e.http) dead = true; });
      });
    }).then(function () {
      var miss = cells.filter(function (c) { return !c.img && c.cov < 0; });
      if (!live() || tz >= (src.maxNative || 18)) return;
      return pool(miss, 6, function (c) {
        return Promise.all([0, 1, 2, 3].map(function (q) {
          var kx = c.x * 2 + (q & 1), ky = c.y * 2 + (q >> 1);
          return OGStore.tileGet(src.id, tz + 1, wrapX(kx, n * 2), ky).then(function (rec) {
            if (rec) return App.decodeBlob(rec.blob).then(function (img) { c.kids = (c.kids || 0) + 1; draws.push({ img: img, z: tz + 1, x: kx, y: ky, rank: tz + 1, own: true }); });
          }).catch(noop);
        }));
      });
    }).then(function () {
      var miss = cells.filter(function (c) { return !c.img && c.cov < 0 && (c.kids || 0) < 4; });
      if (!live()) return;
      return pool(miss, 6, function (c) {
        return App.findParent(src.id, tz, wrapX(c.x, n), c.y, tz - 3).then(function (p) {   // ≤ 8× zoomed up
          if (!p) return;
          c.how = 'parent';
          var pz = tz - p.dz, px = c.x >> p.dz, key = pz + '/' + px + '/' + p.py;
          if (parents[key]) return;
          parents[key] = 1;
          return App.decodeBlob(p.rec.blob).then(function (img) { draws.push({ img: img, z: pz, x: px, y: p.py, rank: pz, own: true }); });
        });
      });
    }).then(function () {
      cells.forEach(function (c) {
        if (c.img) draws.push({ img: c.img, z: tz, x: c.x, y: c.y, rank: tz, own: true });
        if (c.img || c.kids || c.how === 'parent' || c.cov >= 0) st.real++;
        if (c.how === 'net') st.net++;
        if (c.kids) st.kids++;
        if (c.how === 'parent' && !c.kids) st.parent++;
        if (!c.img && !c.kids && c.how !== 'parent' && c.cov >= 0) st.screen++;
      });
      draws.sort(function (p, q) { return p.rank - q.rank; });
      T.ctx.imageSmoothingEnabled = true;
      draws.forEach(function (d) {
        var rc = tileRect(T, d.z, d.x, d.y);
        try { if (live()) T.ctx.drawImage(d.img, rc.x - 0.5, rc.y - 0.5, rc.w + 1, rc.h + 1); } catch (e) { /* skip */ }
        if (d.own && d.img.close) d.img.close();
      });
      return st;
    });
  }

  /* Saved tracks, breadcrumb, route, waypoints and GPS, drawn into the texture.
     Sizes scale with the texture so they read at roughly map size on screen. */
  function drawOverlays(T) {
    var a = T.a, ctx = T.ctx, k = Math.max(1, Math.min(T.cw, T.ch) / 380);
    var kx = T.cw / (a.x1 - a.x0), ky = T.ch / (a.y1 - a.y0);
    function P(lat, lon) { return [(mercX(lon) - a.x0) * kx, (mercY(lat) - a.y0) * ky]; }
    function inside(p, m) { return p[0] >= -m && p[1] >= -m && p[0] <= T.cw + m && p[1] <= T.ch + m; }
    function line(pts, color, w, dash) {
      if (!pts || pts.length < 2) return;
      ctx.save(); ctx.lineJoin = ctx.lineCap = 'round'; ctx.setLineDash(dash || []);
      ctx.beginPath();
      pts.forEach(function (p, i) { var q = P(p[0], p[1]); if (i) ctx.lineTo(q[0], q[1]); else ctx.moveTo(q[0], q[1]); });
      ctx.strokeStyle = 'rgba(0,0,0,.55)'; ctx.lineWidth = w + 2.5 * k; ctx.stroke();   // dark casing
      ctx.strokeStyle = color; ctx.lineWidth = w; ctx.stroke();
      ctx.restore();
    }
    function dot(p, r, fill, ring) {
      ctx.beginPath(); ctx.arc(p[0], p[1], r + ring + k, 0, 2 * Math.PI); ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.fill();
      ctx.beginPath(); ctx.arc(p[0], p[1], r + ring, 0, 2 * Math.PI); ctx.fillStyle = '#fff'; ctx.fill();
      ctx.beginPath(); ctx.arc(p[0], p[1], r, 0, 2 * Math.PI); ctx.fillStyle = fill; ctx.fill();
    }
    if (App.settings.showTracks !== false && App.tracks) (App.tracks.all() || []).forEach(function (t) {
      if (!t.hidden && t.points && t.points.length > 1) line(t.points, t.color || '#00c7be', 4 * k);
    });
    if (App.bt && App.bt.outing) line(App.bt.outing(), '#7cc0ff', 3.5 * k, [0.1, 7 * k]);
    var nt = App.nav && App.nav.target, fix = App.gps && App.gps.fix;
    if (nt) {
      if (nt.route && nt.route.length > 1) line(nt.route, '#ffb000', 5 * k);
      else if (fix) line([[fix.lat, fix.lon], [nt.lat, nt.lon]], '#ffb000', 4 * k, [12 * k, 9 * k]);
      var tp = P(nt.lat, nt.lon);
      if (inside(tp, 0)) { ctx.beginPath(); ctx.arc(tp[0], tp[1], 13 * k, 0, 2 * Math.PI); ctx.lineWidth = 3.5 * k; ctx.strokeStyle = '#ffb000'; ctx.stroke(); }
    }
    ctx.font = '700 ' + Math.round(13 * k) + 'px system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';
    ctx.textBaseline = 'middle'; ctx.lineJoin = 'round';
    (App.wp ? App.wp.all() : []).slice(0, 500).forEach(function (w) {
      var p = P(w.lat, w.lon);
      if (!inside(p, 20 * k)) return;
      var cat = (OGStore.WAYPOINT_CATS || {})[w.cat] || { color: '#9aa4ae' };
      dot(p, 6.5 * k, cat.color, 2.2 * k);
      if (!w.name) return;
      var tw = ctx.measureText(w.name).width, right = p[0] + 12 * k + tw < T.cw;
      ctx.textAlign = right ? 'left' : 'right';
      var lx = right ? p[0] + 11 * k : p[0] - 11 * k;
      ctx.lineWidth = 4 * k; ctx.strokeStyle = 'rgba(0,0,0,.8)'; ctx.strokeText(w.name, lx, p[1]);
      ctx.fillStyle = '#fff'; ctx.fillText(w.name, lx, p[1]);
    });
    if (fix) {
      var g = P(fix.lat, fix.lon), accPx = (fix.acc || 0) * T.cw / a.W;
      if (inside(g, 0)) {
        if (accPx > 10 * k) {
          ctx.beginPath(); ctx.arc(g[0], g[1], accPx, 0, 2 * Math.PI);
          ctx.fillStyle = 'rgba(30,144,255,.16)'; ctx.fill(); ctx.lineWidth = 1.5 * k; ctx.strokeStyle = 'rgba(30,144,255,.6)'; ctx.stroke();
        }
        dot(g, 7.5 * k, '#1e90ff', 3 * k);
      }
    }
  }

  function pot(v, max) { return clamp(Math.pow(2, Math.round(Math.log(v) / Math.LN2)), 64, max); }

  /* Compose the whole texture. Drawn in "logical" pixels at the area's true aspect,
     stretched (by the canvas transform) to a power-of-two size so WebGL 1 can mipmap it. */
  function composeTexture(a, g, maxTex, live, progress, noTiles) {
    var src = App.currentSource(), span = Math.max(a.x1 - a.x0, a.y1 - a.y0);
    var tz = clamp(Math.floor(Math.log(maxTex / (256 * span)) / Math.LN2), 1, src.maxNative || 18);
    var px = 256 * Math.pow(2, tz), cw = (a.x1 - a.x0) * px, ch = (a.y1 - a.y0) * px;
    var f = Math.min(1, maxTex / Math.max(cw, ch)); cw *= f; ch *= f;
    var c = document.createElement('canvas');
    c.width = pot(cw, maxTex); c.height = pot(ch, maxTex);
    var ctx = c.getContext('2d');
    ctx.setTransform(c.width / cw, 0, 0, c.height / ch, 0, 0);
    var T = { canvas: c, ctx: ctx, cw: cw, ch: ch, tz: tz, a: a, src: src };
    drawFallback(T, g);
    var p = noTiles ? Promise.resolve({ total: 1, real: 0, net: 0, parent: 0, screen: 0 }) : drawTiles(T, live, progress);
    return p.then(function (st) { if (!live()) throw ABORT; T.st = st; drawOverlays(T); return T; });
  }

  /* ======================= 4. MESH ======================= */
  /* Vertex attributes: aPos (x, elevation, z) in metres; aGrad = slope (dh/dx, dh/dz) for terrain,
     outward horizontal normal for the skirt; aUV; aSide 0 = terrain, 1 = skirt. The exaggeration
     is applied in the shader, so the slider only changes a uniform. */
  function buildMesh(a, g) {
    var nx = g.nx, ny = g.ny, nv = nx * ny, nsk = 4 * (nx + ny), NV = nv + nsk;
    var P = new Float32Array(NV * 3), G = new Float32Array(NV * 2), U = new Float32Array(NV * 2), S = new Float32Array(NV);
    var I = new Uint16Array((nx - 1) * (ny - 1) * 6 + (2 * (nx - 1) + 2 * (ny - 1)) * 6), ii = 0, i, j, k;
    for (j = 0; j < ny; j++) for (i = 0; i < nx; i++) {
      k = j * nx + i;
      P[k * 3] = -a.W / 2 + i * g.dx; P[k * 3 + 1] = g.H[k]; P[k * 3 + 2] = -a.D / 2 + j * g.dz;
      G[k * 2] = g.gx[k]; G[k * 2 + 1] = g.gz[k];
      U[k * 2] = i / (nx - 1); U[k * 2 + 1] = j / (ny - 1);
    }
    for (j = 0; j < ny - 1; j++) for (i = 0; i < nx - 1; i++) {
      k = j * nx + i;
      I[ii++] = k; I[ii++] = k + nx; I[ii++] = k + 1;
      I[ii++] = k + 1; I[ii++] = k + nx; I[ii++] = k + nx + 1;
    }
    // skirt: each edge vertex gets a top/bottom pair with a flat outward normal
    var base = g.min - Math.max(30, (g.max - g.min) * 0.12, Math.max(a.W, a.D) * 0.006), v = nv;
    function edge(list, ox, oz) {
      var first = v;
      list.forEach(function (src) {
        for (var b = 0; b < 2; b++) {
          P[v * 3] = P[src * 3]; P[v * 3 + 1] = b ? base : P[src * 3 + 1]; P[v * 3 + 2] = P[src * 3 + 2];
          G[v * 2] = ox; G[v * 2 + 1] = oz; U[v * 2] = 0; U[v * 2 + 1] = b ? 0 : 1; S[v] = 1; v++;
        }
      });
      for (var q = 0; q < list.length - 1; q++) {
        var t0 = first + q * 2;
        I[ii++] = t0; I[ii++] = t0 + 1; I[ii++] = t0 + 2; I[ii++] = t0 + 2; I[ii++] = t0 + 1; I[ii++] = t0 + 3;
      }
    }
    var north = [], south = [], west = [], east = [];
    for (i = 0; i < nx; i++) { north.push(i); south.push((ny - 1) * nx + i); }
    for (j = 0; j < ny; j++) { west.push(j * nx); east.push(j * nx + nx - 1); }
    edge(north, 0, -1); edge(south, 0, 1); edge(west, -1, 0); edge(east, 1, 0);
    return { P: P, G: G, U: U, S: S, I: I, base: base };
  }

  /* ======================= 5. WEBGL ======================= */
  var VS = [
    'attribute vec3 aPos; attribute vec2 aGrad; attribute vec2 aUV; attribute float aSide;',
    'uniform mat4 uMVP; uniform float uExag, uHRef;',
    'varying vec2 vUV; varying vec3 vN; varying float vSide;',
    'void main() {',
    '  vN = aSide > 0.5 ? vec3(aGrad.x, 0.0, aGrad.y) : normalize(vec3(-aGrad.x * uExag, 1.0, -aGrad.y * uExag));',
    '  vUV = aUV; vSide = aSide;',
    '  gl_Position = uMVP * vec4(aPos.x, (aPos.y - uHRef) * uExag, aPos.z, 1.0);',
    '}'].join('\n');
  // lambert, normalised so flat ground is always "1": sun-facing slopes brighter, shaded ones darker
  var FS = [
    'precision mediump float;',
    'uniform sampler2D uTex; uniform vec3 uLight; uniform float uFlat, uAmb;',
    'varying vec2 vUV; varying vec3 vN; varying float vSide;',
    'void main() {',
    '  vec3 base = vSide > 0.5 ? mix(vec3(0.22, 0.18, 0.14), vec3(0.47, 0.39, 0.30), vUV.y) : texture2D(uTex, vUV).rgb;',
    '  float d = clamp(dot(normalize(vN), uLight) / uFlat, 0.0, 1.5);',
    '  gl_FragColor = vec4(min(base * (uAmb + (1.0 - uAmb) * d), vec3(1.0)), 1.0);',
    '}'].join('\n');
  // pins: aP = (x, elevation, z, lift in world metres); drawn as camera-facing quads + round heads
  var MVS = [
    'attribute vec4 aP; attribute vec3 aC;',
    'uniform mat4 uMVP; uniform float uExag, uHRef, uPt;',
    'varying vec3 vC;',
    'void main() { vC = aC; gl_PointSize = uPt;',
    '  gl_Position = uMVP * vec4(aP.x, (aP.y - uHRef) * uExag + aP.w, aP.z, 1.0); }'].join('\n');
  var MFS = [
    'precision mediump float;',
    'uniform float uIsPt; varying vec3 vC;',
    'void main() { vec3 c = vC;',
    '  if (uIsPt > 0.5) { float r = length(gl_PointCoord - 0.5); if (r > 0.5) discard; if (r > 0.34) c = vec3(1.0); if (r > 0.44) c = vec3(0.0); }',
    '  gl_FragColor = vec4(c, 1.0); }'].join('\n');

  function program(vs, fs, attrs, unis) {
    function sh(type, text) {
      var s = gl.createShader(type); gl.shaderSource(s, text); gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS) && !gl.isContextLost()) throw new Error('Shader: ' + gl.getShaderInfoLog(s));
      return s;
    }
    var p = gl.createProgram(), a = sh(gl.VERTEX_SHADER, vs), b = sh(gl.FRAGMENT_SHADER, fs);
    gl.attachShader(p, a); gl.attachShader(p, b); gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS) && !gl.isContextLost()) throw new Error('Link: ' + gl.getProgramInfoLog(p));
    gl.deleteShader(a); gl.deleteShader(b);    // freed once the program is
    var o = { p: p, a: {}, u: {} };
    attrs.forEach(function (n) { o.a[n] = gl.getAttribLocation(p, n); });
    unis.forEach(function (n) { o.u[n] = gl.getUniformLocation(p, n); });
    return o;
  }
  function setupGL() {
    glx = {
      terrain: program(VS, FS, ['aPos', 'aGrad', 'aUV', 'aSide'], ['uMVP', 'uExag', 'uHRef', 'uTex', 'uLight', 'uFlat', 'uAmb']),
      marker: program(MVS, MFS, ['aP', 'aC'], ['uMVP', 'uExag', 'uHRef', 'uPt', 'uIsPt']),
      aniso: gl.getExtension('EXT_texture_filter_anisotropic') || gl.getExtension('WEBKIT_EXT_texture_filter_anisotropic'),
      buf: {}, tex: null, maxTex: Math.min(TEX_MAX, gl.getParameter(gl.MAX_TEXTURE_SIZE) || 2048)
    };
  }
  function upload(mesh) {
    ['P', 'G', 'U', 'S'].forEach(function (n) {
      var b = glx.buf[n] = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, b); gl.bufferData(gl.ARRAY_BUFFER, mesh[n], gl.STATIC_DRAW);
    });
    glx.buf.I = gl.createBuffer(); gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, glx.buf.I); gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, mesh.I, gl.STATIC_DRAW);
    glx.count = mesh.I.length;
    glx.buf.pins = gl.createBuffer();
  }
  function uploadTexture(c) {      // throws SecurityError if the canvas is tainted
    var t = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, t);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
    try { gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, gl.RGB, gl.UNSIGNED_BYTE, c); } catch (e) { gl.deleteTexture(t); throw e; }
    gl.generateMipmap(gl.TEXTURE_2D);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    if (glx.aniso) gl.texParameterf(gl.TEXTURE_2D, glx.aniso.TEXTURE_MAX_ANISOTROPY_EXT, Math.min(8, gl.getParameter(glx.aniso.MAX_TEXTURE_MAX_ANISOTROPY_EXT)));
    if (glx.tex) gl.deleteTexture(glx.tex);
    glx.tex = t;
  }
  function freeGL() {
    if (gl && glx && !gl.isContextLost()) {
      Object.keys(glx.buf).forEach(function (k) { gl.deleteBuffer(glx.buf[k]); });
      if (glx.tex) gl.deleteTexture(glx.tex);
      gl.deleteProgram(glx.terrain.p); gl.deleteProgram(glx.marker.p);
    }
    glx = null;
  }

  /* ---- matrices (column-major, as WebGL wants them) ---- */
  function perspective(fovy, aspect, near, far) {
    var f = 1 / Math.tan(fovy / 2), nf = 1 / (near - far), o = new Float32Array(16);
    o[0] = f / aspect; o[5] = f; o[10] = (far + near) * nf; o[11] = -1; o[14] = 2 * far * near * nf;
    return o;
  }
  function lookAt(e, c) {
    var z = norm([e[0] - c[0], e[1] - c[1], e[2] - c[2]]), x = norm(cross([0, 1, 0], z)), y = cross(z, x);
    return new Float32Array([x[0], y[0], z[0], 0, x[1], y[1], z[1], 0, x[2], y[2], z[2], 0,
      -dot(x, e), -dot(y, e), -dot(z, e), 1]);
  }
  function mul(a, b) {
    var o = new Float32Array(16);
    for (var c = 0; c < 4; c++) for (var r = 0; r < 4; r++) {
      var s = 0; for (var k = 0; k < 4; k++) s += a[k * 4 + r] * b[c * 4 + k]; o[c * 4 + r] = s;
    }
    return o;
  }
  function cross(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
  function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
  function norm(a) { var l = Math.sqrt(dot(a, a)) || 1; return [a[0] / l, a[1] / l, a[2] / l]; }

  /* ======================= 6. CAMERA ======================= */
  function targetY() { return scene ? (scene.grid.mean - scene.grid.min) * exag : 0; }
  function eyePos() {
    var p = cam.pitch * D2R, y = cam.yaw * D2R, d = cam.dist;
    return [cam.tx - Math.sin(y) * Math.cos(p) * d, targetY() + Math.sin(p) * d, cam.tz + Math.cos(y) * Math.cos(p) * d];
  }
  /* Distance at which the whole block (8 corners) fits on screen for a given yaw/pitch. */
  function fitDist(yaw, pitch) {
    var g = scene.grid, a = scene.area, y = yaw * D2R, p = pitch * D2R, ty = targetY();
    var f = [Math.sin(y) * Math.cos(p), -Math.sin(p), -Math.cos(y) * Math.cos(p)], r = [Math.cos(y), 0, Math.sin(y)], u = cross(r, f);
    var tY = Math.tan(FOV * D2R / 2) * 0.94, tX = tY * (canvas && canvas.height ? canvas.width / canvas.height : 0.6), need = 10;
    [-1, 1].forEach(function (sx) { [-1, 1].forEach(function (sz) { [scene.base, g.max].forEach(function (h) {
      var c = [sx * a.W / 2 - cam.tx, (h - g.min) * exag - ty, sz * a.D / 2 - cam.tz], pz = dot(c, f);
      need = Math.max(need, Math.abs(dot(c, r)) / tX - pz, Math.abs(dot(c, u)) / tY - pz);
    }); }); });
    return need;
  }
  function distLimits() { var s = Math.max(scene.area.W, scene.area.D); return [Math.max(120, s * 0.03), s * 4]; }
  function viewFor(kind) {
    var v = { yaw: cam.yaw, pitch: cam.pitch, dist: cam.dist, tx: cam.tx, tz: cam.tz };
    if (kind === 'reset' || kind === 'top') {
      v.yaw = kind === 'top' ? cam.yaw : 0; v.pitch = kind === 'top' ? PITCH_MAX : 45; v.tx = 0; v.tz = 0;
      var keep = [cam.tx, cam.tz]; cam.tx = 0; cam.tz = 0; v.dist = fitDist(v.yaw, v.pitch); cam.tx = keep[0]; cam.tz = keep[1];
    } else if (kind === 'north') v.yaw = 0;
    return v;
  }
  function animateTo(v) {
    if (reduceMotion) { Object.keys(v).forEach(function (k) { cam[k] = v[k]; }); return requestRender(); }
    var from = { yaw: cam.yaw, pitch: cam.pitch, dist: cam.dist, tx: cam.tx, tz: cam.tz };
    from.yaw = v.yaw + ((((from.yaw - v.yaw) % 360) + 540) % 360 - 180);      // shortest way round
    anim = { from: from, to: v, t0: performance.now(), ms: 500 };
    requestRender();
  }
  function panBy(dx, dy) {      // screen px -> metres on the ground, content follows the finger
    var rect = canvas.getBoundingClientRect(), mpp = 2 * cam.dist * Math.tan(FOV * D2R / 2) / Math.max(1, rect.height);
    var y = cam.yaw * D2R, fwd = dy * mpp / Math.max(0.35, Math.sin(cam.pitch * D2R)), a = scene.area;
    cam.tx = clamp(cam.tx - Math.cos(y) * dx * mpp + Math.sin(y) * fwd, -a.W / 2, a.W / 2);
    cam.tz = clamp(cam.tz - Math.sin(y) * dx * mpp - Math.cos(y) * fwd, -a.D / 2, a.D / 2);
  }
  function zoomBy(f) { var L = distLimits(); cam.dist = clamp(cam.dist * f, L[0], L[1]); }

  /* ======================= 7. RENDERING (on demand) ======================= */
  function requestRender() { if (!raf && isOpen) raf = requestAnimationFrame(frame); }
  function frame(t) {
    raf = 0;
    var dt = lastT ? Math.min(100, t - lastT) : 16; lastT = t;
    if (spin) cam.yaw += dt * 0.006;                        // 6°/s: one turn a minute
    if (anim) {
      var q = clamp((t - anim.t0) / anim.ms, 0, 1), e = q < 0.5 ? 2 * q * q : 1 - Math.pow(-2 * q + 2, 2) / 2;
      Object.keys(anim.to).forEach(function (k) { cam[k] = anim.from[k] + (anim.to[k] - anim.from[k]) * e; });
      if (q >= 1) anim = null;
    }
    draw();
    if (spin || anim) requestRender(); else lastT = 0;
  }
  function sizeCanvas() {
    var dpr = Math.min(2, window.devicePixelRatio || 1), w = Math.max(1, Math.round(canvas.clientWidth * dpr)), h = Math.max(1, Math.round(canvas.clientHeight * dpr));
    if (canvas.width !== w || canvas.height !== h) { canvas.width = w; canvas.height = h; }
    return dpr;
  }
  function attribs(prog, list) {            // enable exactly the arrays this program reads
    for (var i = 0; i < 6; i++) gl.disableVertexAttribArray(i);
    list.forEach(function (l) {
      var loc = prog.a[l[0]]; if (loc < 0) return;
      gl.bindBuffer(gl.ARRAY_BUFFER, l[1]); gl.enableVertexAttribArray(loc);
      gl.vertexAttribPointer(loc, l[2], gl.FLOAT, false, l[3] || 0, l[4] || 0);
    });
  }
  function draw() {
    if (!gl || !glx || !scene || gl.isContextLost()) return;
    var dpr = sizeCanvas(), w = canvas.width, h = canvas.height, g = scene.grid, a = scene.area;
    cam.pitch = clamp(cam.pitch, PITCH_MIN, PITCH_MAX);
    var eye = eyePos(), diag = Math.sqrt(a.W * a.W + a.D * a.D) + (g.max - scene.base) * exag;
    var mvp = mul(perspective(FOV * D2R, w / h, Math.max(1, cam.dist * 0.01), cam.dist + diag * 1.5), lookAt(eye, [cam.tx, targetY(), cam.tz]));
    gl.viewport(0, 0, w, h);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.DEPTH_TEST);
    var T = glx.terrain, B = glx.buf, L = scene.light.dir;
    gl.useProgram(T.p);
    attribs(T, [['aPos', B.P, 3], ['aGrad', B.G, 2], ['aUV', B.U, 2], ['aSide', B.S, 1]]);
    gl.uniformMatrix4fv(T.u.uMVP, false, mvp);
    gl.uniform1f(T.u.uExag, exag); gl.uniform1f(T.u.uHRef, g.min);
    gl.uniform3f(T.u.uLight, L[0], L[1], L[2]); gl.uniform1f(T.u.uFlat, Math.max(L[1], 0.25)); gl.uniform1f(T.u.uAmb, 0.42);
    gl.activeTexture(gl.TEXTURE0); gl.bindTexture(gl.TEXTURE_2D, glx.tex); gl.uniform1i(T.u.uTex, 0);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, B.I);
    gl.drawElements(gl.TRIANGLES, glx.count, gl.UNSIGNED_SHORT, 0);
    drawPins(mvp, dpr);
    if (ui.needle) ui.needle.style.transform = 'rotate(' + (-cam.yaw) + 'deg)';
  }
  /* Pins: waypoints / nav target (static) + GPS (live). Sticks scale with distance, so they
     keep roughly the same size on screen; heads are drawn without depth test (seen through hills). */
  function drawPins(mvp, dpr) {
    var pins = scene.pins.slice(), fix = App.gps && App.gps.fix, a = scene.area, you = 0;
    if (fix) {        // GPS last: light stick + bigger head, so it never looks like a (blue) water waypoint
      var gx = (mercX(fix.lon) - a.cx) * a.mpu, gz = (mercY(fix.lat) - a.cy) * a.mpu;
      if (Math.abs(gx) <= a.W / 2 && Math.abs(gz) <= a.D / 2) { pins.push({ x: gx, z: gz, h: groundAt(gx, gz), c: [0.12, 0.56, 1], s: [0.95, 0.97, 1] }); you = 1; }
    }
    if (!pins.length) return;
    var hgt = cam.dist * 0.07, half = cam.dist * 0.0018, y = cam.yaw * D2R, rx = Math.cos(y) * half, rz = Math.sin(y) * half;
    var n = pins.length, buf = new Float32Array(n * 7 * 7), o = 0;
    function put(x, h, z, lift, c) { buf[o++] = x; buf[o++] = h; buf[o++] = z; buf[o++] = lift; buf[o++] = c[0]; buf[o++] = c[1]; buf[o++] = c[2]; }
    pins.forEach(function (p) {
      var top = p.s || p.c, dark = [top[0] * 0.6, top[1] * 0.6, top[2] * 0.6];
      put(p.x - rx, p.h, p.z - rz, 0, dark); put(p.x + rx, p.h, p.z + rz, 0, dark); put(p.x + rx, p.h, p.z + rz, hgt, top);
      put(p.x - rx, p.h, p.z - rz, 0, dark); put(p.x + rx, p.h, p.z + rz, hgt, top); put(p.x - rx, p.h, p.z - rz, hgt, top);
    });
    pins.forEach(function (p) { put(p.x, p.h, p.z, hgt, p.c); });
    var M = glx.marker;
    gl.useProgram(M.p);
    gl.bindBuffer(gl.ARRAY_BUFFER, glx.buf.pins); gl.bufferData(gl.ARRAY_BUFFER, buf, gl.DYNAMIC_DRAW);
    attribs(M, [['aP', glx.buf.pins, 4, 28, 0], ['aC', glx.buf.pins, 3, 28, 16]]);
    gl.uniformMatrix4fv(M.u.uMVP, false, mvp);
    gl.uniform1f(M.u.uExag, exag); gl.uniform1f(M.u.uHRef, scene.grid.min);
    gl.uniform1f(M.u.uIsPt, 0); gl.drawArrays(gl.TRIANGLES, 0, n * 6);
    gl.disable(gl.DEPTH_TEST);
    gl.uniform1f(M.u.uIsPt, 1);
    gl.uniform1f(M.u.uPt, 15 * dpr); if (n > you) gl.drawArrays(gl.POINTS, n * 6, n - you);
    gl.uniform1f(M.u.uPt, 22 * dpr); if (you) gl.drawArrays(gl.POINTS, n * 7 - 1, 1);
    gl.enable(gl.DEPTH_TEST);
  }
  function hexRGB(h) {
    var m = /^#?([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i.exec(h || '');
    return m ? [parseInt(m[1], 16) / 255, parseInt(m[2], 16) / 255, parseInt(m[3], 16) / 255] : [0.6, 0.64, 0.68];
  }
  function staticPins(a) {
    var out = [];
    function add(lat, lon, c) {
      var x = (mercX(lon) - a.cx) * a.mpu, z = (mercY(lat) - a.cy) * a.mpu;
      if (Math.abs(x) <= a.W / 2 && Math.abs(z) <= a.D / 2 && out.length < 80) out.push({ x: x, z: z, h: groundAt(x, z), c: c });
    }
    (App.wp ? App.wp.all() : []).forEach(function (w) { add(w.lat, w.lon, hexRGB(((OGStore.WAYPOINT_CATS || {})[w.cat] || {}).color)); });
    var nt = App.nav && App.nav.target;
    if (nt && !nt.id) add(nt.lat, nt.lon, [1, 0.69, 0]);
    return out;
  }

  /* Light: the real sun for the area centre when it is up, else a fixed NW light. */
  function lightFor(lat, lon) {
    function dir(brg, alt) { var b = brg * D2R, e = alt * D2R; return [Math.sin(b) * Math.cos(e), Math.sin(e), -Math.cos(b) * Math.cos(e)]; }
    var p = window.SunCalc ? SunCalc.getPosition(new Date(), lat, lon) : null;
    if (p && p.altitude > 1 * D2R) {
      var brg = ((p.azimuth / D2R + 180) % 360 + 360) % 360, alt = p.altitude / D2R;
      return { dir: dir(brg, alt), text: 'Light: sun now (az ' + Math.round(brg) + '°, ' + Math.round(alt) + '° up)' };
    }
    return { dir: dir(315, 45), text: p ? 'Light: default, from NW (sun is down)' : 'Light: default, from NW' };
  }

  /* ======================= 8. BUILD ======================= */
  function build(area) {
    var my = ++seq, t0 = performance.now(), st = {};
    function live() { return my === seq && isOpen; }
    scene = null; anim = null;
    busy('Building 3D view…', 'Elevation data');
    return loadDem(area, live, function (d, n) { if (live()) busy(null, 'Elevation tiles ' + d + ' / ' + n); }).then(function (dem) {
      if (!live()) throw ABORT;
      st.dem = dem;
      st.grid = buildGrid(area, dem.levels.length ? demSampler(dem.levels) : null);
      st.tDem = performance.now() - t0;
      busy(null, 'Map tiles');
      return composeTexture(area, st.grid, glx.maxTex, live, function (d, n) { if (live()) busy(null, 'Map tiles ' + d + ' / ' + n); });
    }).then(function (T) {
      if (!live() || !glx) throw ABORT;
      var mesh = buildMesh(area, st.grid);
      upload(mesh);
      try { uploadTexture(T.canvas); } catch (e) {
        // a tainted (non-CORS) tile slipped in: rebuild with elevation colours only
        T.canvas.width = 0;
        return composeTexture(area, st.grid, glx.maxTex, live, noop, true).then(function (T2) { uploadTexture(T2.canvas); return finish(T2, mesh); });
      }
      return finish(T, mesh);
    }).catch(function (e) {
      if (e === ABORT || !live()) return;
      console.error('3D view', e);
      busy('Could not build the 3D view', e && e.message ? e.message : String(e), true);
    });
    function finish(T, mesh) {
      T.canvas.width = T.canvas.height = 0;            // free the 2D copy; the GPU has it now
      scene = { area: area, grid: st.grid, dem: st.dem, base: mesh.base, tex: { tz: T.tz, st: T.st }, light: lightFor(area.lat, area.lon) };
      scene.pins = staticPins(area);
      sizeCanvas();                                  // the fit below needs the real aspect ratio
      var v = viewFor('reset'); Object.keys(v).forEach(function (k) { cam[k] = v[k]; });
      busy(false);
      paintInfo();
      requestRender();
      App.t3d.stats = { ms: Math.round(performance.now() - t0), demMs: Math.round(st.tDem), dz: st.dem.dz, levels: st.dem.levels.map(function (l) { return l.z + ':' + l.got + '/' + l.total; }),
        grid: st.grid.nx + 'x' + st.grid.ny, verts: mesh.P.length / 3, tz: T.tz, tiles: T.st, light: scene.light.text };
      if (!st.grid.have) warn(navigator.onLine
        ? 'Elevation data could not be downloaded for this area right now, so it is shown flat. Try again with a better signal, or Save this area with elevation (Layers → Offline).'
        : 'No elevation data saved for this area — open it online once or Save this area with elevation (Layers → Offline). Showing it flat.');
      else if (st.grid.have < 0.98) warn('Elevation is missing for part of this area (filled in flat). Save this area with elevation to complete it.');
    }
  }

  function paintInfo() {
    var a = scene.area, g = scene.grid, s = scene.tex.st, dem = scene.dem, main = null;
    dem.levels.forEach(function (l) { if (!main || l.got / l.total > main.got / main.total) main = l; });
    var tex = !s.real ? (s.blocked ? 'elevation colours (this map\'s server does not allow its tiles to be reused)' : 'elevation colours (no map tiles here on this device)')
      : (s.net ? 'map tiles (some downloaded now)' : 'map tiles from this device') +
        (s.real < s.total ? ' + elevation colours where missing' : '') + (s.parent ? ', some zoomed up' : '');
    var lo = App.fmtAlt(g.min), hi = App.fmtAlt(g.max), unit = / \D+$/.exec(hi);
    ui.info1.textContent = App.fmtDist(a.W) + ' × ' + App.fmtDist(a.D) +
      (g.have ? ' · ' + (unit && lo.slice(-unit[0].length) === unit[0] ? lo.slice(0, -unit[0].length) : lo) + '–' + hi : ' · flat: no elevation data');
    ui.info2.textContent = scene.light.text + ' · ' + tex.charAt(0).toUpperCase() + tex.slice(1);
    ui.info3.textContent = (main ? 'DEM zoom ' + main.z + (dem.levels.length > 1 ? '+' : '') + ' (grid ≈ ' + App.fmtDist(a.mpu / Math.pow(2, main.z + 8)) + '). ' : '') +
      'Elevation is SRTM-type radar data (≈30 m grid, ±10–20 m): the lie of the land, not exact heights.';
    ui.info.classList.remove('folded'); ui.info.setAttribute('aria-expanded', 'true');
    ui.autoFold = true;              // fold to one line when the user starts exploring
  }

  /* ======================= 9. UI ======================= */
  var ICON = {
    reset: '<path d="M4 12a8 8 0 1 0 2.4-5.7"/><path d="M4 4v4.5h4.5"/>',
    top: '<rect x="4" y="4" width="16" height="16" rx="2"/><circle cx="12" cy="12" r="2.2"/>',
    north: '<path d="M12 3l6 17-6-4-6 4z"/>',
    spin: '<path d="M20 12a8 8 0 1 1-2.6-5.9"/><path d="M19.5 3.5v4h-4"/>',
    me: '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.5"/><path d="M12 1.5v3M12 19.5v3M1.5 12h3M19.5 12h3"/>'
  };
  function btn(act, label, aria, pressed) {
    return '<button class="btn" type="button" data-t3d="' + act + '" aria-label="' + aria + '"' + (pressed != null ? ' aria-pressed="false"' : '') +
      '><svg viewBox="0 0 24 24" aria-hidden="true">' + ICON[act] + '</svg><span>' + label + '</span></button>';
  }
  function ensureUI() {
    var host = $('t3d-host');
    if (!host || ui.host) return !!host;
    host.innerHTML =
      '<div class="t3d-stage">' +
        '<button class="t3d-info" type="button" aria-expanded="true" aria-label="3D view details (tap to fold)"><span class="t3d-i1"></span><span class="t3d-i2"></span><span class="t3d-i3"></span></button>' +
        '<button class="t3d-compass" type="button" aria-label="Compass: north arrow. Tap to turn north up."><svg viewBox="0 0 48 48" aria-hidden="true"><g class="t3d-needle">' +
          '<path d="M24 5l7 19h-14z" fill="#ff3b30"/><path d="M24 43l7-19h-14z" fill="currentColor" opacity=".5"/><text x="24" y="21" text-anchor="middle">N</text></g></svg></button>' +
        '<div class="t3d-busy" role="status" aria-live="polite"><div class="t3d-spinner" aria-hidden="true"></div><p class="t3d-busy-t"></p><p class="t3d-busy-d"></p></div>' +
        '<div class="t3d-warn" role="alert" hidden><span></span><button class="btn" type="button" data-t3d="dismiss">OK</button></div>' +
      '</div>' +
      '<div class="t3d-bar">' +
        '<label class="t3d-exag"><span class="t3d-exag-v">Height ×1.5</span><input type="range" min="1" max="4" step="0.5" value="1.5" aria-label="Vertical exaggeration (height stretch)"></label>' +
        '<div class="t3d-btns" role="toolbar" aria-label="3D view controls">' +
          btn('reset', 'Reset', 'Reset view') + btn('top', 'Top', 'Top-down view') + btn('north', 'North', 'Turn north up') +
          btn('spin', 'Spin', 'Spin slowly', true) + btn('me', 'Me', 'Where am I: centre on my GPS position') +
        '</div>' +
      '</div>';
    ui = { host: host };
    var SEL = { stage: '.t3d-stage', info: '.t3d-info', info1: '.t3d-i1', info2: '.t3d-i2', info3: '.t3d-i3', needle: '.t3d-needle', busy: '.t3d-busy',
      busyT: '.t3d-busy-t', busyD: '.t3d-busy-d', warn: '.t3d-warn', range: '.t3d-exag input', exagV: '.t3d-exag-v', spinBtn: '[data-t3d="spin"]' };
    Object.keys(SEL).forEach(function (k) { ui[k] = host.querySelector(SEL[k]); });
    ui.range.addEventListener('input', function () {
      exag = +ui.range.value || 1.5;
      ui.exagV.textContent = 'Height ×' + exag;
      requestRender();
    });
    host.querySelector('.t3d-compass').addEventListener('click', function () { if (scene) animateTo(viewFor('north')); });
    ui.info.addEventListener('click', function () {
      ui.autoFold = false;
      var folded = ui.info.classList.toggle('folded');
      ui.info.setAttribute('aria-expanded', String(!folded));
    });
    host.querySelector('.t3d-bar').addEventListener('click', onButton);
    ui.warn.addEventListener('click', function (e) { if (e.target.closest('[data-t3d="dismiss"]')) ui.warn.hidden = true; });
    return true;
  }
  function onButton(e) {
    var b = e.target.closest('[data-t3d]'); if (!b || !scene) return;
    var act = b.getAttribute('data-t3d');
    if (act === 'reset' || act === 'top' || act === 'north') animateTo(viewFor(act));
    else if (act === 'spin') setSpin(!spin);
    else if (act === 'me') whereAmI();
  }
  function setSpin(on) {
    spin = !!on; lastT = 0;
    if (ui.spinBtn) ui.spinBtn.setAttribute('aria-pressed', String(spin));
    requestRender();
  }
  function whereAmI() {
    var f = App.gps && App.gps.fix, a = scene.area;
    if (!f) { OGSK.toast('No GPS fix yet — turn on location (Follow on the map) and wait for a fix', { error: true }); return; }
    var x = (mercX(f.lon) - a.cx) * a.mpu, z = (mercY(f.lat) - a.cy) * a.mpu;
    if (Math.abs(x) > a.W / 2 || Math.abs(z) > a.D / 2) { OGSK.toast('You are outside this 3D area (' + App.fmtDist(OGGeo.distance(f.lat, f.lon, a.lat, a.lon)) + ' from its centre)', { error: true }); return; }
    var L = distLimits();
    animateTo({ yaw: cam.yaw, pitch: cam.pitch, tx: x, tz: z, dist: clamp(Math.min(cam.dist, Math.max(a.W, a.D) * 0.45), L[0], L[1]) });
  }
  function busy(title, detail, isError) {     // false = hide; controls only work once a scene is ready
    ui.host.querySelectorAll('.t3d-bar button, .t3d-bar input').forEach(function (b) { b.disabled = title !== false; });
    if (title === false) { ui.busy.hidden = true; return; }
    ui.busy.hidden = false;
    ui.busy.classList.toggle('error', !!isError);
    if (title != null) ui.busyT.textContent = title;
    if (detail != null) ui.busyD.textContent = detail;
  }
  function warn(text) { ui.warn.firstChild.textContent = text; ui.warn.hidden = !text; }

  /* ---- pointer / wheel / keyboard ---- */
  var ptrs = new Map(), gesture = null, lastTap = null;
  function onDown(e) {
    if (!scene) return;
    if (ui.autoFold) { ui.autoFold = false; ui.info.classList.add('folded'); ui.info.setAttribute('aria-expanded', 'false'); }
    try { canvas.setPointerCapture(e.pointerId); } catch (err) { /* synthetic or already gone */ }
    ptrs.set(e.pointerId, { x: e.clientX, y: e.clientY });
    canvas.classList.add('dragging');
    if (ptrs.size === 1) gesture = { mode: (e.button === 2 || e.shiftKey) ? 'pan' : 'orbit', t: performance.now(), x0: e.clientX, y0: e.clientY, moved: 0 };
    else if (ptrs.size === 2) gesture = { mode: 'pinch', moved: 99, d: pinchDist(), m: pinchMid() };
    anim = null;
  }
  function pinchDist() { var v = Array.from(ptrs.values()); return Math.max(1, Math.hypot(v[0].x - v[1].x, v[0].y - v[1].y)); }
  function pinchMid() { var v = Array.from(ptrs.values()); return { x: (v[0].x + v[1].x) / 2, y: (v[0].y + v[1].y) / 2 }; }
  function onMove(e) {
    var p = ptrs.get(e.pointerId); if (!p || !gesture || !scene) return;
    var dx = e.clientX - p.x, dy = e.clientY - p.y;
    p.x = e.clientX; p.y = e.clientY;
    if (gesture.mode === 'pinch' && ptrs.size >= 2) {
      var d = pinchDist(), m = pinchMid();
      zoomBy(gesture.d / d); panBy(m.x - gesture.m.x, m.y - gesture.m.y);
      gesture.d = d; gesture.m = m;
    } else if (gesture.mode === 'pan') panBy(dx, dy);
    else if (gesture.mode === 'orbit') { cam.yaw += dx * 0.35; cam.pitch = clamp(cam.pitch + dy * 0.3, PITCH_MIN, PITCH_MAX); }
    gesture.moved += Math.abs(dx) + Math.abs(dy);
    requestRender();
  }
  function onUp(e) {
    if (!ptrs.has(e.pointerId)) return;
    ptrs.delete(e.pointerId);
    if (gesture && gesture.mode !== 'pinch' && !ptrs.size && gesture.moved < 10 && performance.now() - gesture.t < 300) {
      var now = performance.now();       // double-tap / double-click = reset
      if (lastTap && now - lastTap.t < 350 && Math.hypot(e.clientX - lastTap.x, e.clientY - lastTap.y) < 30) { lastTap = null; animateTo(viewFor('reset')); }
      else lastTap = { t: now, x: e.clientX, y: e.clientY };
    }
    if (ptrs.size === 1) { gesture = { mode: 'orbit', t: 0, moved: 99 }; }    // pinch -> one finger: keep going, no jump
    else if (!ptrs.size) { gesture = null; canvas.classList.remove('dragging'); }
  }
  function onWheel(e) {
    if (!scene) return;
    e.preventDefault();
    var d = e.deltaY * (e.deltaMode === 1 ? 33 : e.deltaMode === 2 ? 400 : 1);
    zoomBy(Math.exp(clamp(d, -300, 300) * 0.0015));
    requestRender();
  }
  function onKey(e) {
    if (!scene) return;
    var k = e.key, done = true;
    if (k === 'ArrowLeft') cam.yaw -= 10; else if (k === 'ArrowRight') cam.yaw += 10;
    else if (k === 'ArrowUp') cam.pitch = clamp(cam.pitch + 5, PITCH_MIN, PITCH_MAX);
    else if (k === 'ArrowDown') cam.pitch = clamp(cam.pitch - 5, PITCH_MIN, PITCH_MAX);
    else if (k === '+' || k === '=') zoomBy(0.8); else if (k === '-' || k === '_') zoomBy(1.25);
    else if (k === '0' || k === 'Home') animateTo(viewFor('reset'));
    else done = false;
    if (done) { e.preventDefault(); requestRender(); }
  }

  /* ---- canvas + context lifecycle ---- */
  function makeCanvas() {
    canvas = document.createElement('canvas');
    canvas.className = 't3d-canvas';
    canvas.tabIndex = 0;
    canvas.setAttribute('role', 'img');
    canvas.setAttribute('aria-label', '3D terrain. Drag to turn and tilt, pinch or scroll to zoom, two fingers or shift-drag to move, double-tap to reset. Arrow keys and + / − also work.');
    ui.stage.insertBefore(canvas, ui.stage.firstChild);
    var opts = { antialias: true, alpha: true, depth: true, premultipliedAlpha: true, preserveDrawingBuffer: false };
    try { gl = canvas.getContext('webgl', opts) || canvas.getContext('experimental-webgl', opts); } catch (e) { gl = null; }
    if (!gl) return false;
    canvas.addEventListener('pointerdown', onDown);
    canvas.addEventListener('pointermove', onMove);
    canvas.addEventListener('pointerup', onUp);
    canvas.addEventListener('pointercancel', onUp);
    canvas.addEventListener('wheel', onWheel, { passive: false });
    canvas.addEventListener('keydown', onKey);
    canvas.addEventListener('contextmenu', function (e) { e.preventDefault(); });
    canvas.addEventListener('webglcontextlost', function (e) {
      e.preventDefault();
      if (!isOpen) return;
      seq++; scene = null; glx = null; anim = null;
      if (raf) cancelAnimationFrame(raf); raf = 0;
      busy('Graphics were reset by the device', 'Rebuilding the 3D view…');
      setTimeout(function () { if (isOpen && !scene && gl && gl.isContextLost()) busy('3D graphics stopped', 'Close the 3D view and open it again.', true); }, 5000);
    });
    canvas.addEventListener('webglcontextrestored', function () {
      if (!isOpen || !gl) return;
      try { setupGL(); } catch (e) { busy('Could not restart 3D graphics', e.message, true); return; }
      build(lastArea);
    });
    if (window.ResizeObserver) { ro = new ResizeObserver(function () { requestRender(); }); ro.observe(ui.stage); }
    return true;
  }

  var lastArea = null;
  App.open3D = function () {
    if (!App.map || !ensureUI()) return;
    if (isOpen) return;
    isOpen = true;
    $('t3d-overlay').hidden = false;
    document.documentElement.classList.add('t3d-open');
    ui.warn.hidden = true;
    setSpin(false);
    $('t3d-close').focus();
    if (!makeCanvas()) {
      busy('3D view is not available', 'This browser or device has WebGL graphics turned off or does not support them. Try another browser, or turn on hardware acceleration. Everything else on the map works without it.', true);
      return;
    }
    try { setupGL(); } catch (e) { busy('3D view is not available', e.message, true); return; }
    window.addEventListener('resize', requestRender);
    lastArea = computeArea();
    build(lastArea);
  };
  function close3D() {
    if (!isOpen) return;
    isOpen = false; seq++;                       // aborts any build in progress
    if (raf) cancelAnimationFrame(raf); raf = 0; anim = null; spin = false; lastT = 0;
    ptrs.clear(); gesture = null;
    if (ro) { ro.disconnect(); ro = null; }
    window.removeEventListener('resize', requestRender);
    freeGL();
    if (gl) { var ext = gl.getExtension('WEBGL_lose_context'); if (ext) ext.loseContext(); }
    gl = null; scene = null;
    if (canvas) { canvas.remove(); canvas = null; }
    $('t3d-overlay').hidden = true;
    document.documentElement.classList.remove('t3d-open');
    var fab = $('fab-3d'); if (fab) fab.focus();
  }
  App.close3D = close3D;

  App.t3dInit = function () {
    if (!ensureUI()) return;
    var fab = $('fab-3d'), x = $('t3d-close');
    if (fab) fab.addEventListener('click', App.open3D);
    if (x) x.addEventListener('click', close3D);
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && isOpen) { e.preventDefault(); close3D(); } });
    App.on('gps', function () { if (isOpen && scene) requestRender(); });
  };

  /* For tests / debugging: draw a frame now and summarise the pixels. */
  App.t3d = {
    stats: null,
    isOpen: function () { return isOpen; },
    ready: function () { return !!scene; },
    camera: function () { return { yaw: cam.yaw, pitch: cam.pitch, dist: cam.dist, tx: cam.tx, tz: cam.tz, exag: exag, spin: spin }; },
    snapshot: function () {
      if (!scene || !gl) return null;
      draw();
      var w = canvas.width, h = canvas.height, px = new Uint8Array(w * h * 4), seen = {}, n = 0, drawn = 0;
      gl.readPixels(0, 0, w, h, gl.RGBA, gl.UNSIGNED_BYTE, px);
      for (var i = 0; i < px.length; i += 4) {
        if (px[i + 3]) drawn++;
        var key = (px[i] >> 4) + ',' + (px[i + 1] >> 4) + ',' + (px[i + 2] >> 4);
        if (!seen[key]) { seen[key] = 1; n++; }
      }
      return { w: w, h: h, colours: n, drawnFraction: +(drawn / (w * h)).toFixed(3) };
    }
  };
})();
