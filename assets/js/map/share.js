/* =====================================================================
   Location sharing with no network:
   - QR code (bundled qrcode-generator) of a geo: URI or a text block
     with lat/lon, DMS, MGRS and time — scan with any phone camera.
   - SOS beacon: full-screen, giant high-contrast coordinates that flash
     (slow blink or Morse SOS) for flagging down help or reading over a radio.
   - Position panel: every coordinate format for GPS + map centre, plus
     "go to coordinates".
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var qrSrc = 'gps', qrFmt = 'geo', qrOverride = null;

  function srcPoint(src) {
    if (qrOverride) return qrOverride;
    var f = App.gps.fix;
    if (src === 'gps' && f) return { lat: f.lat, lon: f.lon, acc: f.acc, alt: f.alt, t: f.t, name: 'My position' };
    if (src === 'gps' && App.gps.lastKnown) { var lk = App.gps.lastKnown; return { lat: lk.lat, lon: lk.lon, acc: lk.acc, t: lk.t, name: 'Last known GPS position', stale: true }; }
    var c = App.map.getCenter();
    return { lat: c.lat, lon: c.lng, name: 'Map centre', center: true };
  }
  function qrPayload(p, fmt) {
    var lat = p.lat.toFixed(6), lon = p.lon.toFixed(6);
    if (fmt === 'geo') return 'geo:' + lat + ',' + lon + (p.name && !p.center ? '?q=' + lat + ',' + lon + '(' + encodeURIComponent(p.name).replace(/%20/g, '+') + ')' : '');
    var lines = [(p.name || 'Location') + ':', lat + ', ' + lon, OGGeo.dms(p.lat, true) + ' ' + OGGeo.dms(p.lon, false), 'MGRS ' + App.mgrs(p.lat, p.lon)];
    if (p.acc) lines.push('Accuracy ±' + Math.round(p.acc) + ' m');
    lines.push((p.t ? new Date(p.t) : new Date()).toISOString().replace('T', ' ').slice(0, 16) + ' UTC');
    lines.push('geo:' + lat + ',' + lon);
    return lines.join('\n');
  }
  function renderQR() {
    var p = srcPoint(qrSrc), text = qrPayload(p, qrFmt);
    var qr = qrcode(0, 'M');
    qr.addData(unescape(encodeURIComponent(text)));   // UTF-8 bytes (° ′ ″)
    qr.make();
    $('qr-box').innerHTML = qr.createSvgTag({ cellSize: 6, margin: 4, scalable: true });
    var svg = $('qr-box').querySelector('svg');
    if (svg) { svg.setAttribute('role', 'img'); svg.setAttribute('aria-label', 'QR code: ' + text.split('\n')[0]); }
    $('qr-text').textContent = text + (p.stale ? '\n(last known GPS fix — no live fix right now)' : '') + (p.center && qrSrc === 'gps' ? '\n(no GPS fix — this is the map centre)' : '');
    return text;
  }

  App.share = {
    showQR: function (pt) {
      qrOverride = pt || null;
      App.openDrawer('share');
      renderQR();
      if (pt) OGSK.toast('QR for “' + pt.name + '”');
    }
  };

  /* ---------------- SOS beacon ---------------- */
  var beaconTimer = null, beaconMode = 'slow', beaconOn = false, seqIdx = 0;
  // SOS in Morse: unit 300 ms; on/off durations
  var U = 300, SOS_SEQ = [];
  (function () {
    function sym(on) { SOS_SEQ.push([true, on * U]); SOS_SEQ.push([false, U]); }
    [1, 1, 1].forEach(sym); SOS_SEQ[SOS_SEQ.length - 1][1] = 3 * U;
    [3, 3, 3].forEach(sym); SOS_SEQ[SOS_SEQ.length - 1][1] = 3 * U;
    [1, 1, 1].forEach(sym); SOS_SEQ[SOS_SEQ.length - 1][1] = 7 * U;
  })();
  function beaconPaint() {
    var p = srcPoint('gps');
    $('sos-dd').textContent = p.lat.toFixed(5) + ', ' + p.lon.toFixed(5);
    $('sos-dms').textContent = OGGeo.dms(p.lat, true) + '  ' + OGGeo.dms(p.lon, false);
    var m = App.mgrs(p.lat, p.lon);
    $('sos-mgrs').textContent = 'MGRS ' + m;
    $('sos-phon').textContent = m && m !== 'n/a' ? OGGeo.phonetic(m) : '';
    var meta = [];
    if (p.center) meta.push('⚠ NO GPS FIX — showing the MAP CENTRE, not your position');
    else if (p.stale) meta.push('⚠ Last known GPS fix from ' + new Date(p.t).toLocaleTimeString());
    else meta.push('GPS ±' + Math.round(p.acc) + ' m · ' + new Date(p.t).toLocaleTimeString());
    if (p.alt != null) meta.push('Alt ' + App.fmtAlt(p.alt));
    $('sos-meta').textContent = meta.join(' · ');
  }
  function beaconStep() {
    var el = $('sos-beacon');
    if (beaconMode === 'off') { el.classList.remove('flash'); return; }
    if (beaconMode === 'slow') {
      el.classList.toggle('flash');
      beaconTimer = setTimeout(beaconStep, 1000);
    } else {
      var s = SOS_SEQ[seqIdx % SOS_SEQ.length]; seqIdx++;
      el.classList.toggle('flash', s[0]);
      beaconTimer = setTimeout(beaconStep, s[1]);
    }
  }
  var MODES = ['slow', 'sos', 'off'], MODE_LABEL = { slow: 'Flash: slow', sos: 'Flash: SOS Morse', off: 'Flash: off (steady)' };
  function openBeacon() {
    beaconOn = true;
    var el = $('sos-beacon'); el.hidden = false;
    $('sos-mode').textContent = MODE_LABEL[beaconMode];
    beaconPaint();
    clearTimeout(beaconTimer); seqIdx = 0; beaconStep();
    OGSK.wakeLock.request();
    if (el.requestFullscreen) el.requestFullscreen().catch(function () {});
    $('sos-close').focus();
    if (!App.gps.watching) App.gpsStart(false);
  }
  function closeBeacon() {
    if (!beaconOn) return;
    beaconOn = false;
    clearTimeout(beaconTimer);
    var el = $('sos-beacon'); el.hidden = true; el.classList.remove('flash');
    OGSK.wakeLock.release();
    if (document.fullscreenElement && document.exitFullscreen) document.exitFullscreen().catch(function () {});
  }
  App.openBeacon = openBeacon;

  /* ---------------- position panel ---------------- */
  function paintPosition() {
    if (!App.drawerOpen('position')) return;
    var f = App.gps.fix, c = App.map.getCenter();
    function block(title, lat, lon, extra) {
      var u = OGGeo.toUTM(lat, lon), m = App.mgrs(lat, lon);
      return '<h3>' + title + '</h3><dl class="kv">' +
        '<dt>Decimal</dt><dd>' + lat.toFixed(6) + ', ' + lon.toFixed(6) + '</dd>' +
        '<dt>DMS</dt><dd>' + OGGeo.dms(lat, true) + ' ' + OGGeo.dms(lon, false) + '</dd>' +
        '<dt>DDM</dt><dd>' + OGGeo.ddm(lat, true) + ' ' + OGGeo.ddm(lon, false) + '</dd>' +
        '<dt>UTM</dt><dd>' + (u ? u.zone + u.band + ' ' + Math.floor(u.easting) + ' E ' + Math.floor(u.northing) + ' N' : 'n/a (polar)') + '</dd>' +
        '<dt>MGRS</dt><dd style="font-size:1.15rem">' + App.esc(m) + '</dd>' +
        '<dt>Radio</dt><dd class="muted" style="font-weight:600">' + App.esc(m !== 'n/a' ? OGGeo.phonetic(m) : '') + '</dd>' +
        (extra || '') + '</dl>' +
        '<div class="row"><button class="btn" type="button" data-copy="' + App.esc(lat.toFixed(6) + ', ' + lon.toFixed(6)) + '">Copy lat/lon</button>' +
        '<button class="btn" type="button" data-copy="' + App.esc(m) + '">Copy MGRS</button></div>';
    }
    var html = '';
    if (f) {
      var age = Math.round((Date.now() - f.t) / 1000);
      var extra = '<dt>GPS altitude</dt><dd>' + (f.alt != null ? App.fmtAlt(f.alt) + (f.altAcc ? ' ±' + App.fmtAlt(f.altAcc) : '') : 'not reported') + '</dd>' +
        '<dt>Accuracy</dt><dd>±' + App.fmtDist(f.acc) + ' · ' + age + ' s ago</dd>' +
        '<dt>Terrain</dt><dd id="pos-gps-dem">…</dd>';
      html += block('My GPS position', f.lat, f.lon, extra);
    } else {
      html += '<div class="callout warn" style="margin-top:12px"><p>No GPS fix yet. ' + (window.isSecureContext ? 'Tap Follow on the map and wait under open sky.' : 'GPS needs https:// or http://localhost (see banner).') + '</p></div>';
    }
    var ce = App.centerElev;
    html += block('Map centre (crosshair)', c.lat, c.lng,
      '<dt>Terrain</dt><dd>' + (ce ? App.fmtAlt(ce.elev) + ' · slope ' + App.dem.fmtSlope(ce) : 'no elevation data saved here') + '</dd>');
    html += '<p class="help">Terrain elevation and slope come from saved elevation tiles (about 30 m resolution, typically ±10–20 m). GPS altitude is usually less accurate than horizontal position.</p>';
    $('pos-out').innerHTML = html;
    if (f) App.dem.at(f.lat, f.lon, true).then(function (r) {
      var el = $('pos-gps-dem'); if (el) el.textContent = r ? App.fmtAlt(r.elev) + ' · slope ' + App.dem.fmtSlope(r) : 'no elevation data saved here';
    });
  }
  App.paintPosition = paintPosition;

  function gotoCoords(drop) {
    var p = OGGeo.parseCoords($('goto-in').value);
    if (!p) { $('goto-msg').textContent = 'Not recognised. Examples: 40.7128, -74.0060 · 40°42′46″N 74°00′22″W · N40 42.768 W074 00.360 · 18T WL 83959 07350'; return; }
    $('goto-msg').textContent = 'Going to ' + App.fmtPos(p[0], p[1]) + ' · MGRS ' + App.mgrs(p[0], p[1]);
    App.map.setView(p, Math.max(App.map.getZoom(), 14));
    if (innerWidth < 800) App.closeDrawer();
    if (drop) App.wp.edit(null, { lat: p[0], lon: p[1] });
  }

  App.shareInit = function () {
    App.seg($('qr-src'), 'data-src', qrSrc, function (v) { qrSrc = v; qrOverride = null; renderQR(); });
    App.seg($('qr-fmt'), 'data-fmt', qrFmt, function (v) { qrFmt = v; renderQR(); });
    $('qr-copy').addEventListener('click', function () { App.copy(renderQR()); });
    if (navigator.share) {
      $('qr-share').hidden = false;
      $('qr-share').addEventListener('click', function () { navigator.share({ text: renderQR() }).catch(function () {}); });
    }
    $('fab-sos').addEventListener('click', function () { qrOverride = null; App.openDrawer('share'); });
    $('sos-open').addEventListener('click', function () { App.closeDrawer(); openBeacon(); });
    $('sos-close').addEventListener('click', closeBeacon);
    $('sos-mode').addEventListener('click', function () {
      beaconMode = MODES[(MODES.indexOf(beaconMode) + 1) % MODES.length];
      $('sos-mode').textContent = MODE_LABEL[beaconMode];
      clearTimeout(beaconTimer); seqIdx = 0; $('sos-beacon').classList.remove('flash'); beaconStep();
    });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && beaconOn) closeBeacon(); });
    App.on('tab', function (t) { if (t === 'share') renderQR(); if (t === 'position') paintPosition(); });
    var lastQ = 0;
    App.on('gps', function () {
      if (beaconOn) beaconPaint();
      if (Date.now() - lastQ > 5000) { lastQ = Date.now(); if (App.drawerOpen('share') && qrSrc === 'gps' && !qrOverride) renderQR(); if (App.drawerOpen('position')) paintPosition(); }
    });
    App.on('center:elev', function () { if (App.drawerOpen('position')) paintPosition(); });
    App.map.on('moveend', function () { if (App.drawerOpen('share') && qrSrc === 'center' && !qrOverride) renderQR(); if (App.drawerOpen('position')) paintPosition(); });
    $('pos-out').addEventListener('click', function (e) { var b = e.target.closest('[data-copy]'); if (b) App.copy(b.getAttribute('data-copy')); });
    $('goto-go').addEventListener('click', function () { gotoCoords(false); });
    $('goto-pin').addEventListener('click', function () { gotoCoords(true); });
    $('goto-in').addEventListener('keydown', function (e) { if (e.key === 'Enter') gotoCoords(false); });
  };
})();
