/* =====================================================================
   Coordinate grid overlay (canvas, redrawn on every move)
   - Lat/Lon graticule with labels in the user's coordinate format
   - UTM / MGRS grid (100 km / 10 km / 1 km / 100 m lines + 100 km square IDs)
   - "Blank map" fallback: when grid = Auto and no tiles are available for
     the view (no signal + nothing saved), the graticule is drawn on a plain
     background so GPS position and waypoints stay spatially meaningful.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;

  var LL_STEPS = [45, 30, 20, 10, 5, 2, 1, 30 / 60, 20 / 60, 10 / 60, 5 / 60, 2 / 60, 1 / 60,
    30 / 3600, 15 / 3600, 10 / 3600, 5 / 3600, 2 / 3600, 1 / 3600];

  function pickStep(spanDeg, px, minPx) {
    var best = LL_STEPS[0];
    for (var i = 0; i < LL_STEPS.length; i++) {
      if (LL_STEPS[i] / spanDeg * px >= minPx) best = LL_STEPS[i]; else break;
    }
    return best;
  }
  function labelFor(v, isLat, step) {
    var fmt = App.settings.coordFmt;
    var h = isLat ? (v >= 0 ? 'N' : 'S') : (v >= 0 ? 'E' : 'W');
    var a = Math.abs(v);
    if (fmt === 'dd') {
      var dec = step >= 1 ? 0 : step >= 0.1 ? 1 : step >= 0.01 ? 2 : step >= 0.001 ? 3 : 4;
      if (step < 1 && step * Math.pow(10, dec) % 1 > 1e-6) dec++;
      return (v < 0 ? '-' : '') + a.toFixed(dec) + '°';
    }
    var d = Math.floor(a + 1e-9), mf = (a - d) * 60, m = Math.floor(mf + 1e-6), s = Math.round((mf - m) * 60);
    if (s === 60) { s = 0; m++; } if (m === 60) { m = 0; d++; }
    var out = d + '°';
    if (step < 1) out += (m < 10 ? '0' : '') + m + '′';
    if (step < 1 / 60) out += (s < 10 ? '0' : '') + s + '″';
    return out + h;
  }

  var GridLayer = L.Layer.extend({
    onAdd: function (map) {
      this._map = map;
      var pane = map.getPane('gridPane') || map.createPane('gridPane');
      pane.style.zIndex = 350; pane.style.pointerEvents = 'none';
      this._c = L.DomUtil.create('canvas', 'og-grid', pane);
      map.on('move resize viewreset zoomend', this.redraw, this);
      map.on('zoomstart', this._hide, this);
      this.redraw();
    },
    onRemove: function (map) {
      map.off('move resize viewreset zoomend', this.redraw, this);
      map.off('zoomstart', this._hide, this);
      L.DomUtil.remove(this._c);
    },
    _hide: function () { this._c.style.opacity = 0; },
    redraw: function () {
      var map = this._map; if (!map) return;
      var c = this._c, size = map.getSize(), dpr = Math.min(window.devicePixelRatio || 1, 2);
      c.style.opacity = 1;
      if (c.width !== size.x * dpr || c.height !== size.y * dpr) {
        c.width = size.x * dpr; c.height = size.y * dpr;
        c.style.width = size.x + 'px'; c.style.height = size.y + 'px';
      }
      L.DomUtil.setPosition(c, map.containerPointToLayerPoint([0, 0]));
      var ctx = c.getContext('2d');
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, size.x, size.y);
      var css = getComputedStyle(document.documentElement);
      this.col = {
        line: css.getPropertyValue('--map-grid').trim() || 'rgba(255,255,255,.35)',
        strong: css.getPropertyValue('--map-grid-strong').trim() || '#fc0',
        text: css.getPropertyValue('--text').trim() || '#fff',
        bg: css.getPropertyValue('--map-bg').trim() || '#1a222c'
      };
      var mode = App.settings.grid, blank = App.tiles && App.tiles.empty;
      var drawLL = mode === 'latlon' || (mode === 'auto' && blank);
      var drawUTM = mode === 'utm';
      if (blank && mode !== 'off') {
        ctx.fillStyle = this.col.bg; ctx.fillRect(0, 0, size.x, size.y);
        if (mode === 'auto' || mode === 'latlon') drawLL = true;
      }
      if (drawLL) this._latlon(ctx, size, blank);
      if (drawUTM) this._utm(ctx, size);
      if (blank && mode !== 'off') this._note(ctx, size);
    },
    _text: function (ctx, s, x, y, align, big) {
      ctx.font = (big ? '800 13px' : '700 12px') + ' system-ui, sans-serif';
      ctx.textAlign = align || 'left'; ctx.textBaseline = 'middle';
      ctx.lineWidth = 4; ctx.strokeStyle = this.col.bg; ctx.strokeText(s, x, y);
      ctx.fillStyle = this.col.text; ctx.fillText(s, x, y);
    },
    _latlon: function (ctx, size, blank) {
      var map = this._map, b = map.getBounds();
      var south = Math.max(-85, b.getSouth()), north = Math.min(85, b.getNorth());
      var west = b.getWest(), east = b.getEast();
      var latStep = pickStep(north - south, size.y, 90);
      var lonStep = pickStep(east - west, size.x, 90);
      ctx.lineWidth = blank ? 1.2 : 1; ctx.strokeStyle = this.col.line; ctx.setLineDash([]);
      var lat, lon, p, i, n;
      // latitude lines (straight in Web Mercator)
      for (lat = Math.ceil(south / latStep) * latStep, n = 0; lat <= north && n < 200; lat += latStep, n++) {
        p = map.latLngToContainerPoint([lat, west]);
        var major = Math.abs(lat) < 1e-9;
        ctx.strokeStyle = major ? this.col.strong : this.col.line;
        ctx.beginPath(); ctx.moveTo(0, p.y); ctx.lineTo(size.x, p.y); ctx.stroke();
        this._text(ctx, labelFor(lat, true, latStep), 112, p.y - 9);
      }
      for (lon = Math.ceil(west / lonStep) * lonStep, n = 0; lon <= east && n < 200; lon += lonStep, n++) {
        p = map.latLngToContainerPoint([south, lon]);
        var wrapped = ((lon + 540) % 360) - 180;
        ctx.strokeStyle = Math.abs(wrapped) < 1e-9 ? this.col.strong : this.col.line;
        ctx.beginPath(); ctx.moveTo(p.x, 0); ctx.lineTo(p.x, size.y); ctx.stroke();
        if (p.x > 100 && p.x < size.x - 120) this._text(ctx, labelFor(wrapped, false, lonStep), p.x + 4, 12, 'left');
      }
    },
    _utm: function (ctx, size) {
      var map = this._map, z = map.getZoom(), center = map.getCenter();
      if (z < 6) { this._text(ctx, 'Zoom in to see the UTM grid', size.x / 2, 32, 'center', true); return; }
      if (center.lat > 84 || center.lat < -80) { this._text(ctx, 'UTM is not defined in polar regions', size.x / 2, 32, 'center', true); return; }
      var zone = OGGeo.utmZoneFor(center.lat, center.lng);
      var mpp = 40075016.686 * Math.cos(center.lat * Math.PI / 180) / Math.pow(2, z + 8);
      var steps = [100000, 10000, 1000, 100], step = 100000;
      for (var i = 0; i < steps.length; i++) if (steps[i] / mpp >= 55) step = steps[i];
      // UTM extent of the view (sample the edges)
      var minE = Infinity, maxE = -Infinity, minN = Infinity, maxN = -Infinity;
      for (var sx = 0; sx <= 4; sx++) for (var sy = 0; sy <= 4; sy++) {
        var ll = map.containerPointToLatLng([size.x * sx / 4, size.y * sy / 4]);
        var u = OGGeo.toUTM(Math.max(-80, Math.min(84, ll.lat)), ll.lng, zone);
        if (!u) continue;
        // continuous northing: negative south of the equator (so a view can straddle it)
        var nn = ll.lat < 0 ? u.northing - 10000000 : u.northing;
        minE = Math.min(minE, u.easting); maxE = Math.max(maxE, u.easting);
        minN = Math.min(minN, nn); maxN = Math.max(maxN, nn);
      }
      if (!isFinite(minE)) return;
      var self = this;
      function pt(E, N) {
        var ll = N < 0 ? OGGeo.fromUTM(zone, 'S', E, N + 10000000) : OGGeo.fromUTM(zone, 'N', E, N);
        return map.latLngToContainerPoint(ll);
      }
      function line(E0, N0, E1, N1, strong) {
        ctx.strokeStyle = strong ? self.col.strong : self.col.line;
        ctx.lineWidth = strong ? 2 : 1;
        ctx.beginPath();
        for (var k = 0; k <= 16; k++) {
          var p = pt(E0 + (E1 - E0) * k / 16, N0 + (N1 - N0) * k / 16);
          if (k) ctx.lineTo(p.x, p.y); else ctx.moveTo(p.x, p.y);
        }
        ctx.stroke();
      }
      function lab(v) {
        if (step >= 100000) return Math.round(v / 1000) + 'k';
        if (step === 10000) return String(Math.floor(v / 10000) % 10);
        if (step === 1000) { var s = String(Math.floor(v / 1000) % 100); return s.length < 2 ? '0' + s : s; }
        var t = String(Math.floor(v / 100) % 1000); while (t.length < 3) t = '0' + t; return t;
      }
      var E, N, count = 0;
      for (E = Math.ceil(minE / step) * step; E <= maxE && count < 300; E += step, count++) {
        line(E, minN, E, maxN, E % 100000 === 0);
        var pTop = pt(E, maxN - (maxN - minN) * 0.02);
        if (pTop.x > 100 && pTop.x < size.x - 100) this._text(ctx, lab(E), pTop.x + 3, 12, 'left', true);
      }
      for (N = Math.ceil(minN / step) * step, count = 0; N <= maxN && count < 300; N += step, count++) {
        line(minE, N, maxE, N, N % 100000 === 0);
        var pL = pt(minE + (maxE - minE) * 0.01, N);
        this._text(ctx, lab(N < 0 ? N + 10000000 : N), 112, pL.y - 9, 'left');
      }
      // 100 km square identifiers (MGRS letters)
      if (step <= 10000 && window.mgrs) {
        ctx.globalAlpha = 0.55;
        for (E = Math.floor(minE / 100000) * 100000; E <= maxE; E += 100000) {
          for (N = Math.floor(minN / 100000) * 100000; N <= maxN; N += 100000) {
            var cE = Math.min(Math.max(E + 50000, minE + (maxE - minE) * 0.15), maxE - (maxE - minE) * 0.15);
            var cN = Math.min(Math.max(N + 50000, minN + (maxN - minN) * 0.15), maxN - (maxN - minN) * 0.15);
            if (cE < E || cE > E + 100000 || cN < N || cN > N + 100000) continue;
            var cll = cN < 0 ? OGGeo.fromUTM(zone, 'S', cE, cN + 10000000) : OGGeo.fromUTM(zone, 'N', cE, cN);
            var m = OGGeo.toMGRS(cll[0], cll[1], 0);
            var cp = map.latLngToContainerPoint(cll);
            if (m) { ctx.font = '900 30px system-ui, sans-serif'; ctx.textAlign = 'center'; ctx.fillStyle = this.col.strong; ctx.fillText(m.slice(-2), cp.x, cp.y); }
          }
        }
        ctx.globalAlpha = 1;
      }
      var stepTxt = step >= 1000 ? (step / 1000) + ' km' : step + ' m';
      this._text(ctx, 'UTM ' + zone + OGGeo.toUTM(center.lat, center.lng).band + ' · ' + stepTxt + ' grid', size.x / 2, 32, 'center', true);
    },
    _note: function (ctx, size) {
      var lines = navigator.onLine ? ['Loading map…', '(no saved tiles here yet)'] : ['No signal and no saved map here', 'Coordinate grid shown — GPS & waypoints still work'];
      var y = Math.round(size.y * 0.5) + 44;
      this._text(ctx, lines[0], size.x / 2, y, 'center', true);
      this._text(ctx, lines[1], size.x / 2, y + 18, 'center', false);
    }
  });

  App.grid = {
    init: function () {
      App.gridLayer = new GridLayer().addTo(App.map);
      App.on('tiles:coverage', function () { App.gridLayer.redraw(); });
      App.on('settings', function (e) { if (e.key === 'grid' || e.key === 'coordFmt') App.gridLayer.redraw(); });
      document.addEventListener('ogsk:theme', function () { App.gridLayer.redraw(); });
      window.addEventListener('online', function () { App.gridLayer.redraw(); });
      window.addEventListener('offline', function () { App.gridLayer.redraw(); });
      var paint = App.seg(App.$('grid-seg'), 'data-grid', App.settings.grid, function (v) { App.set('grid', v); });
      App.on('settings', function (e) { if (e.key === 'grid') paint(e.value); });
    }
  };
})();
