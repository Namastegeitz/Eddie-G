/* =====================================================================
   Live positioning: GPS (watchPosition, high accuracy), animated position
   dot + accuracy circle, follow mode, telemetry strip, and the compass
   (DeviceOrientation with the iOS permission prompt, GPS course fallback).
   GPS works with NO network — it is a satellite receiver. The browser only
   needs a secure context (https:// or http://localhost, or the installed app).
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var SAVER_MS = 60000, pollTimer = null;
  var watchId = null, marker = null, accCircle = null, staleTimer = null, follow = false;
  var lastSaved = 0;

  /* ---------------- GPS ---------------- */
  function start(fromUser) {
    if (!('geolocation' in navigator)) { App.banner('This browser has no GPS/geolocation support.', { danger: true }); return; }
    if (!window.isSecureContext) {
      App.banner('<strong>GPS is blocked</strong> because this page was opened from <code>' + App.esc(location.protocol + '//' + location.host) +
        '</code>. Open it from <code>http://localhost</code>, an <code>https://</code> address, or the installed app. (Opening the file directly, file://, never allows GPS.)', { danger: true });
      return;
    }
    if (watchId !== null || pollTimer !== null) return;
    App.gps.watching = true;
    if (App.settings.gpsMode === 'saver') {
      // Battery saver: one fresh fix a minute instead of continuous tracking
      var poll = function () { navigator.geolocation.getCurrentPosition(onFix, onErr, { enableHighAccuracy: true, maximumAge: 15000, timeout: 50000 }); };
      poll(); pollTimer = setInterval(poll, SAVER_MS);
    } else {
      watchId = navigator.geolocation.watchPosition(onFix, onErr, { enableHighAccuracy: true, maximumAge: 1000, timeout: 30000 });
    }
    if (fromUser) OGSK.toast('Starting GPS… go outside with a clear view of the sky for the best fix');
  }
  function stop() {
    if (watchId !== null) navigator.geolocation.clearWatch(watchId);
    if (pollTimer !== null) clearInterval(pollTimer);
    watchId = null; pollTimer = null; App.gps.watching = false;
  }
  function restart() { var was = App.gps.watching; stop(); if (was || App.settings.autoGps) start(false); }
  App.gpsRestart = restart;
  App.gpsStart = start; App.gpsStop = stop;

  function onFix(p) {
    var c = p.coords;
    var f = {
      lat: c.latitude, lon: c.longitude, acc: c.accuracy,
      alt: c.altitude, altAcc: c.altitudeAccuracy,
      speed: (c.speed != null && !isNaN(c.speed)) ? c.speed : null,
      course: (c.heading != null && !isNaN(c.heading)) ? c.heading : null,
      t: p.timestamp || Date.now()
    };
    // derive speed if the device doesn't report it
    var prev = App.gps.fix;
    if (f.speed == null && prev) {
      var dt = (f.t - prev.t) / 1000;
      if (dt > 0.5) {
        var v = OGGeo.distance(prev.lat, prev.lon, f.lat, f.lon) / dt;
        f.speed = v < 90 ? v : null;   // ignore GPS jumps (> ~320 km/h) — not real movement
      }
    }
    App.gps.fix = f; App.gps.error = null;
    if (App._gpsErrBanner) { App.banner(null); App._gpsErrBanner = false; }
    paintMarker(f);
    paintTelemetry();
    if (follow) App.map.panTo([f.lat, f.lon], { animate: true });
    if (Date.now() - lastSaved > 10000) {
      lastSaved = Date.now();
      try { localStorage.setItem('ogsk.lastfix', JSON.stringify(f)); } catch (e) {}
    }
    clearTimeout(staleTimer);
    staleTimer = setTimeout(function () { markerEl() && markerEl().classList.add('stale'); paintTelemetry(); }, App.settings.gpsMode === 'saver' ? SAVER_MS + 30000 : 30000);
    App.emit('gps', f);
  }
  function onErr(e) {
    App.gps.error = e;
    if (e.code === 1) {
      stop();
      App._gpsErrBanner = true;
      var ua = navigator.userAgent, how;
      if (/iPhone|iPad|iPod/.test(ua)) how = 'iPhone: <em>Settings → Privacy &amp; Security → Location Services</em> → turn it on, then <em>Safari Websites</em> (or this app) → <em>While Using</em>. Also tap <strong>aA</strong> in Safari\'s address bar → <em>Website Settings → Location → Allow</em>.';
      else if (/Android/.test(ua)) how = 'Android: tap the <strong>lock / ⓘ icon</strong> left of the address → <em>Permissions → Location → Allow</em>, and make sure the phone\'s Location is switched on.';
      else how = 'Computer: click the <strong>lock / ⓘ icon</strong> left of the address → <em>Site settings → Location → Allow</em>, then reload. (A computer without GPS uses Wi-Fi location, which can be far off.)';
      App.banner('<strong>Location is blocked for this app.</strong> ' + how +
        ' <button class="btn primary" type="button" id="gps-retry">Try again</button>', { danger: true });
      var rb = document.getElementById('gps-retry');
      if (rb) rb.onclick = function () { App.banner(null); App._gpsErrBanner = false; start(true); };
    } else if (e.code === 2) {
      App._gpsErrBanner = true;
      App.banner('No GPS position yet. Go outside, away from tall buildings and dense canopy, and hold still for a minute. Make sure Location is turned on.');
    } else if (e.code === 3 && !App.gps.fix) {
      App._gpsErrBanner = true;
      App.banner('Still waiting for a GPS fix… a first fix with no data connection can take 1–5 minutes under open sky.');
    }
    paintTelemetry();
  }

  function markerEl() { return marker && marker.getElement() && marker.getElement().querySelector('.gps-icon'); }
  function paintMarker(f) {
    var ll = [f.lat, f.lon];
    if (!marker) {
      marker = L.marker(ll, {
        icon: L.divIcon({ className: '', html: '<div class="gps-icon"><div class="gps-cone" hidden></div><div class="gps-pulse"></div><div class="gps-dot"></div></div>', iconSize: [0, 0] }),
        keyboard: false, interactive: true, zIndexOffset: 1000, title: 'My position'
      }).addTo(App.map);
      marker.on('click', function () { App.openDrawer('position'); });
      accCircle = L.circle(ll, { radius: f.acc || 0, color: '#1e90ff', weight: 1, fillOpacity: 0.12, interactive: false }).addTo(App.map);
    } else {
      marker.setLatLng(ll);
      accCircle.setLatLng(ll).setRadius(f.acc || 0);
    }
    var el = markerEl(); if (el) el.classList.remove('stale');
    paintCone();
  }
  function paintCone() {
    var el = markerEl(); if (!el) return;
    var cone = el.querySelector('.gps-cone');
    var h = App.heading.deg;
    if (h == null) { cone.hidden = true; return; }
    cone.hidden = false;
    cone.style.transform = 'rotate(' + h + 'deg)';
  }

  /* ---------------- telemetry strip ---------------- */
  var FMT_NAMES = { dd: 'DD', dms: 'DMS', ddm: 'DDM' };
  function paintTelemetry() {
    var f = App.gps.fix, s = App.settings;
    $('tl-pos-k').textContent = 'GPS · ' + FMT_NAMES[s.coordFmt];
    if (!f) {
      $('tl-pos').textContent = App.gps.watching ? 'Searching for satellites…' : (window.isSecureContext ? 'GPS off — tap Follow' : 'GPS blocked (see banner)');
      $('tl-alt').textContent = $('tl-spd').textContent = $('tl-acc').textContent = '—';
    } else {
      var age = (Date.now() - f.t) / 1000;
      $('tl-pos').textContent = App.fmtPos(f.lat, f.lon) + (age > 30 ? ' (' + Math.round(age) + ' s old)' : '');
      $('tl-alt').textContent = f.alt != null ? App.fmtAlt(f.alt) + (f.altAcc ? ' ±' + App.fmtAlt(f.altAcc).replace(/ .*/, '') : '') : 'n/a';
      $('tl-spd').textContent = f.speed != null ? App.fmtSpeed(f.speed) : '—';
      $('tl-acc').textContent = '±' + App.fmtDist(f.acc);
    }
    paintHeading();
  }
  App.paintTelemetry = paintTelemetry;

  /* ---------------- compass / heading ----------------
     The sensor work (iOS permission, Android absolute orientation, tilt modes,
     smoothing) lives in the shared engine assets/js/compass.js (OGCompass). */
  var compassCtl = null;

  function updateHeading() {
    var f = App.gps.fix, now = Date.now();
    var deg = null, src = null;
    if (OGCompass.source === 'compass' && OGCompass.magHeading != null) { deg = App.toTrue(OGCompass.magHeading); src = 'compass'; }
    else if (f && f.course != null && f.speed != null && f.speed > 0.7 && now - f.t < 10000) { deg = f.course; src = 'gps'; }
    App.heading = { deg: deg, src: src, mag: src === 'compass' ? OGCompass.magHeading : null, t: now };
    paintHeading(); paintCone();
    App.emit('heading', App.heading);
  }
  function paintHeading() {
    var h = App.heading;
    $('tl-hdg').textContent = h.deg == null ? '—' : Math.round(h.deg) + '° ' + OGGeo.cardinal(h.deg);
    if (!compassCtl) return;
    var rose = compassCtl.querySelector('.rose'), deg = compassCtl.querySelector('.ctl-deg'), src = compassCtl.querySelector('.ctl-src');
    if (h.deg == null) {
      rose.style.transform = 'rotate(0deg)';
      deg.textContent = '—';
      src.textContent = OGCompass.status === 'ok' || OGCompass.status === 'waiting' ? 'move phone' : 'tap: compass';
    } else {
      rose.style.transform = 'rotate(' + (-h.deg) + 'deg)';
      deg.textContent = String(Math.round(h.deg) % 360).padStart(3, '0') + '° ' + OGGeo.cardinal(h.deg);
      src.textContent = h.src === 'compass' ? ((App.decl() || OGCompass.declMode === 'manual' ? 'true' : 'magnetic') + ' · tap') : 'GPS course';
    }
  }
  function enableCompass(fromUser) {
    return OGCompass.start(fromUser).then(function (ok) {
      if (!fromUser) return ok;
      if (OGCompass.status === 'denied') OGSK.toast('Compass permission denied', { error: true });
      else if (OGCompass.status === 'unsupported') OGSK.toast('No compass sensor available in this browser', { error: true });
      else setTimeout(function () {
        if (OGCompass.status === 'nosensor') OGSK.toast('No compass reading — this device or browser may not expose one. GPS course is used while walking.');
      }, 3000);
      return ok;
    });
  }
  App.enableCompass = enableCompass;

  /* ---------------- full compass overlay (shared UI from compass-ui.js) ---------------- */
  var cmpUI = null, bearingLine = null, lockBrg = null;
  function liveFix() { var f = App.gps.fix; return f && Date.now() - f.t < 120000 ? f : null; }
  function drawBearing() {
    if (bearingLine) { App.map.removeLayer(bearingLine); bearingLine = null; }
    if (lockBrg == null) return;
    var f = liveFix(), c = App.map.getCenter();
    var from = f ? [f.lat, f.lon] : [c.lat, c.lng];
    var end = OGGeo.destination(from[0], from[1], lockBrg, 5000);
    bearingLine = L.polyline([from, end], { color: '#2fbf71', weight: 4, dashArray: '4 9', lineCap: 'round', interactive: false }).addTo(App.map);
  }
  App.openCompass = function () {
    if (!cmpUI) cmpUI = OGCompassUI.mount($('cmp-host'), { getFix: liveFix, onLock: function (b) { lockBrg = b; drawBearing(); } });
    $('cmp-overlay').hidden = false;
    cmpUI.setActive(true);
    $('cmp-close').focus();
  };
  App.closeCompass = function () {
    if ($('cmp-overlay').hidden) return;
    $('cmp-overlay').hidden = true;
    if (cmpUI) cmpUI.setActive(false);
    if (lockBrg != null && bearingLine) App.map.fitBounds(bearingLine.getBounds().pad(0.1), { maxZoom: 15 });
  };

  var CompassControl = L.Control.extend({
    options: { position: 'topleft' },
    onAdd: function () {
      var b = L.DomUtil.create('button', 'compass-ctl');
      b.type = 'button';
      b.setAttribute('aria-label', 'Compass. Tap to open the full compass.');
      b.innerHTML =
        '<svg viewBox="0 0 100 100" aria-hidden="true">' +
        '<path d="M50 2 L46 10 L54 10 Z" fill="var(--accent)"/>' +  // fixed lubber mark (phone's top)
        '<g class="rose">' +
        '<circle cx="50" cy="54" r="38" fill="none" stroke="currentColor" stroke-width="2.5"/>' +
        ticks() +
        '<path d="M50 20 L57 54 L50 49 L43 54 Z" fill="#ff3b30"/><path d="M50 88 L57 54 L50 59 L43 54 Z" fill="currentColor" opacity=".55"/>' +
        '<text x="50" y="33" text-anchor="middle" font-size="12" font-weight="900" fill="currentColor">N</text>' +
        '<text x="81" y="58" text-anchor="middle" font-size="10" font-weight="800" fill="currentColor">E</text>' +
        '<text x="50" y="84" text-anchor="middle" font-size="10" font-weight="800" fill="currentColor">S</text>' +
        '<text x="19" y="58" text-anchor="middle" font-size="10" font-weight="800" fill="currentColor">W</text>' +
        '</g></svg><div class="ctl-deg">—</div><div class="ctl-src">tap: compass</div>';
      L.DomEvent.disableClickPropagation(b);
      L.DomEvent.on(b, 'click', function () {
        enableCompass(true);     // inside the tap, so iOS can ask for permission
        App.openCompass();
      });
      compassCtl = b;
      return b;
    }
  });
  function ticks() {
    var s = '';
    for (var a = 0; a < 360; a += 30) {
      var r1 = 38, r2 = a % 90 === 0 ? 31 : 34, rad = a * Math.PI / 180;
      s += '<line x1="' + (50 + r1 * Math.sin(rad)).toFixed(1) + '" y1="' + (54 - r1 * Math.cos(rad)).toFixed(1) +
        '" x2="' + (50 + r2 * Math.sin(rad)).toFixed(1) + '" y2="' + (54 - r2 * Math.cos(rad)).toFixed(1) + '" stroke="currentColor" stroke-width="2"/>';
    }
    return s;
  }

  /* ---------------- follow mode ---------------- */
  function setFollow(on) {
    follow = on;
    $('fab-locate').setAttribute('aria-pressed', on ? 'true' : 'false');
    if (on) {
      start(true);
      var f = App.gps.fix;
      if (f) App.map.setView([f.lat, f.lon], Math.max(App.map.getZoom(), 15));
    }
  }
  App.setFollow = setFollow;

  App.gpsInit = function () {
    compassCtl = null;
    new CompassControl().addTo(App.map);
    $('fab-locate').addEventListener('click', function () {
      if (!follow) setFollow(true); else setFollow(false);
      enableCompass(true);  // a tap is a good moment to ask iOS for compass permission
    });
    App.map.on('dragstart', function () { if (follow) setFollow(false); });
    $('tl-coords').addEventListener('click', function () {
      var order = ['dd', 'dms', 'ddm'];
      App.set('coordFmt', order[(order.indexOf(App.settings.coordFmt) + 1) % 3]);
    });
    $('cmp-close').addEventListener('click', App.closeCompass);
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') App.closeCompass(); });
    App.on('gps', function () { if (lockBrg != null) drawBearing(); });
    $('set-compass').addEventListener('click', function () { enableCompass(true); OGSK.toast('Move the phone in a slow figure-8 to calibrate'); });
    App.on('settings', function (e) {
      if (e.key === 'coordFmt' || e.key === 'units') paintTelemetry();
      if (e.key === 'declination') updateHeading();
    });
    App.on('gps', function (f) { OGCompass.feedGps(f); OGCompass.setPosition(f.lat, f.lon, 'gps'); if (OGCompass.source !== 'compass') updateHeading(); });
    // automatic declination follows the map view until there is a GPS fix
    App.map.on('moveend', function () { if (!App.gps.fix) { var c = App.map.getCenter(); OGCompass.setPosition(c.lat, c.lng, 'map view'); } });
    var lastDecl = null, lastMode = null;
    OGCompass.on(function () {
      updateHeading();
      if (OGCompass.declination !== lastDecl || OGCompass.declMode !== lastMode) {
        lastDecl = OGCompass.declination; lastMode = OGCompass.declMode;
        App.settings.declination = OGCompass.manualDecl; App.settings.declMode = OGCompass.declMode;   // keep in-memory settings in step (engine saves them)
        App.emit('settings', { key: 'declination', value: lastDecl });
      }
    });
    OGCompass.loadDeclination();
    setInterval(function () { if (App.gps.fix) paintTelemetry(); }, 5000);
    // restore last known fix (shown grey/stale until a live one arrives)
    try {
      var lf = JSON.parse(localStorage.getItem('ogsk.lastfix') || 'null');
      if (lf && lf.lat != null) { App.gps.lastKnown = lf; }
    } catch (e) {}
    enableCompass(false);   // Android/desktop: no prompt needed
    paintTelemetry();
    if (App.settings.autoGps) {
      if (navigator.permissions && navigator.permissions.query) {
        navigator.permissions.query({ name: 'geolocation' }).then(function (st) {
          if (st.state !== 'denied') start(false);
          else onErr({ code: 1 });
        }, function () { start(false); });
      } else start(false);
    }
  };
})();
