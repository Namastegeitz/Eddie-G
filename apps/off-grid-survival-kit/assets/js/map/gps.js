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
    if (watchId !== null) return;
    App.gps.watching = true;
    watchId = navigator.geolocation.watchPosition(onFix, onErr, { enableHighAccuracy: true, maximumAge: 1000, timeout: 30000 });
    if (fromUser) OGSK.toast('Starting GPS… go outside with a clear view of the sky for the best fix');
  }
  function stop() {
    if (watchId !== null) navigator.geolocation.clearWatch(watchId);
    watchId = null; App.gps.watching = false;
  }
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
      if (dt > 0.5) f.speed = OGGeo.distance(prev.lat, prev.lon, f.lat, f.lon) / dt;
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
    staleTimer = setTimeout(function () { markerEl() && markerEl().classList.add('stale'); paintTelemetry(); }, 30000);
    App.emit('gps', f);
  }
  function onErr(e) {
    App.gps.error = e;
    if (e.code === 1) {
      stop();
      App._gpsErrBanner = true;
      App.banner('<strong>Location permission denied.</strong> Allow location for this app in your browser/phone settings (Settings → Privacy → Location), then tap Follow again.', { danger: true });
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

  /* ---------------- compass / heading ---------------- */
  var compassOn = false, magHeading = null, magT = 0, sx = 0, sy = 0;
  var compassCtl = null;

  function onOrientation(e) {
    var h = null;
    if (typeof e.webkitCompassHeading === 'number' && !isNaN(e.webkitCompassHeading)) h = e.webkitCompassHeading; // iOS (magnetic)
    else if (e.absolute === true && e.alpha != null) h = 360 - e.alpha;                                            // Android absolute
    else if (e.type === 'deviceorientationabsolute' && e.alpha != null) h = 360 - e.alpha;
    if (h == null) return;
    var ang = (screen.orientation && typeof screen.orientation.angle === 'number') ? screen.orientation.angle : (window.orientation || 0);
    h = OGGeo.norm360(h + ang);
    // circular low-pass filter to steady the needle
    var r = h * Math.PI / 180, k = 0.25;
    sx = sx * (1 - k) + Math.sin(r) * k; sy = sy * (1 - k) + Math.cos(r) * k;
    magHeading = OGGeo.norm360(Math.atan2(sx, sy) * 180 / Math.PI); magT = Date.now();
    schedulePaint();
  }
  var paintQueued = false;
  function schedulePaint() {
    if (paintQueued) return;
    paintQueued = true;
    requestAnimationFrame(function () { paintQueued = false; updateHeading(); });
  }
  function updateHeading() {
    var f = App.gps.fix, now = Date.now();
    var deg = null, src = null;
    if (magHeading != null && now - magT < 3000) { deg = App.toTrue(magHeading); src = 'compass'; }
    else if (f && f.course != null && f.speed != null && f.speed > 0.7 && now - f.t < 10000) { deg = f.course; src = 'gps'; }
    App.heading = { deg: deg, src: src, mag: src === 'compass' ? magHeading : null, t: now };
    paintHeading(); paintCone();
    App.emit('heading', App.heading);
  }
  function paintHeading() {
    var h = App.heading;
    $('tl-hdg').textContent = h.deg == null ? '—' : Math.round(h.deg) + '° ' + OGGeo.cardinal(h.deg);
    if (!compassCtl) return;
    var rose = compassCtl.querySelector('.rose'), deg = compassCtl.querySelector('.cmp-deg'), src = compassCtl.querySelector('.cmp-src');
    if (h.deg == null) {
      rose.style.transform = 'rotate(0deg)';
      deg.textContent = '—';
      src.textContent = compassOn ? 'move phone' : 'tap: compass';
    } else {
      rose.style.transform = 'rotate(' + (-h.deg) + 'deg)';
      deg.textContent = String(Math.round(h.deg) % 360).padStart(3, '0') + '° ' + OGGeo.cardinal(h.deg);
      src.textContent = h.src === 'compass' ? ((+App.settings.declination ? 'true · ' : 'magnetic · ') + 'compass') : 'GPS course';
    }
  }
  function enableCompass(fromUser) {
    if (typeof DeviceOrientationEvent === 'undefined') { if (fromUser) OGSK.toast('No compass sensor available in this browser', { error: true }); return; }
    function listen() {
      if (compassOn) return;
      compassOn = true;
      if ('ondeviceorientationabsolute' in window) window.addEventListener('deviceorientationabsolute', onOrientation);
      else window.addEventListener('deviceorientation', onOrientation);
      setTimeout(function () {
        if (magHeading == null && fromUser) OGSK.toast('No compass reading — this device or browser may not expose one. GPS course is used while walking.');
      }, 3000);
      paintHeading();
    }
    if (typeof DeviceOrientationEvent.requestPermission === 'function') {   // iOS 13+
      if (!fromUser) return;  // must come from a tap
      DeviceOrientationEvent.requestPermission().then(function (state) {
        if (state === 'granted') listen(); else OGSK.toast('Compass permission denied', { error: true });
      }).catch(function () { OGSK.toast('Compass permission could not be requested', { error: true }); });
    } else listen();
  }
  App.enableCompass = enableCompass;

  var CompassControl = L.Control.extend({
    options: { position: 'topleft' },
    onAdd: function () {
      var b = L.DomUtil.create('button', 'compass-ctl');
      b.type = 'button';
      b.setAttribute('aria-label', 'Compass. Tap to enable the compass sensor.');
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
        '</g></svg><div class="cmp-deg">—</div><div class="cmp-src">tap: compass</div>';
      L.DomEvent.disableClickPropagation(b);
      L.DomEvent.on(b, 'click', function () {
        if (!compassOn || magHeading == null) enableCompass(true);
        else OGSK.toast('Heading ' + Math.round(App.heading.deg) + '° ' + (App.heading.src === 'compass' ? (+App.settings.declination ? 'true (declination ' + App.settings.declination + '°)' : 'magnetic — set declination in Settings for true') : 'from GPS course'));
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
    $('set-compass').addEventListener('click', function () { enableCompass(true); OGSK.toast('Move the phone in a slow figure-8 to calibrate'); });
    App.on('settings', function (e) {
      if (e.key === 'coordFmt' || e.key === 'units') paintTelemetry();
      if (e.key === 'declination') updateHeading();
    });
    App.on('gps', function () { if (magHeading == null || Date.now() - magT > 3000) updateHeading(); });
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
