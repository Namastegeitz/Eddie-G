/* =====================================================================
   OGCompass — shared compass engine (used by /compass/ and the map)
   ---------------------------------------------------------------------
   Sensor sources, best first:
     - iOS Safari: deviceorientation + webkitCompassHeading (needs a tap to
       grant permission: OGCompass.start(true) from a click handler)
     - Android Chrome: deviceorientationabsolute (alpha/beta/gamma, earth frame)
   Two holding modes, switched automatically from the tilt (beta):
     - FLAT: heading of the phone's TOP EDGE  (classic baseplate compass)
     - UPRIGHT (|beta| > 65°): heading of the BACK CAMERA (sighting a landmark)
   Readings are smoothed with a circular low-pass filter; a jitter estimate
   (circular standard deviation over ~1.5 s) flags interference/calibration.
   Phone sensors give MAGNETIC north; add the declination (E +, W −) for TRUE.
   With no sensor, GPS course over ground is used while moving (> 0.7 m/s).
   Declination: AUTO by default — computed on the device from the World
   Magnetic Model 2025 (assets/js/wmm.js) at your GPS position (else the last
   fix, else the map view); or a MANUAL value. Shared with the map through
   IndexedDB kv 'map.settings' {declMode: 'auto'|'manual', declination: manual°}.
   ===================================================================== */
(function () {
  'use strict';
  var D2R = Math.PI / 180, R2D = 180 / Math.PI;
  function n360(d) { d = d % 360; return d < 0 ? d + 360 : d; }
  function n180(d) { d = n360(d); return d > 180 ? d - 360 : d; }

  var subs = [];
  var sx = 0, sy = 0, hist = [], upright = false, gps = null, queued = false, noSensorTimer = null;
  var listening = false, granted = false;

  var C = window.OGCompass = {
    declination: 0,     // EFFECTIVE declination in use (deg, East +)
    declMode: 'auto',   // 'auto' (WMM2025) | 'manual'
    manualDecl: 0,      // the user's manual value
    autoDecl: null,     // last WMM2025 value, or null if unavailable
    declAt: null,       // {lat, lon, src} the auto value was computed for
    magHeading: null,   // smoothed magnetic heading (deg)
    heading: null,      // TRUE heading (deg) from sensor, or GPS course fallback
    source: null,       // 'compass' | 'gps' | null
    mode: 'flat',       // 'flat' | 'upright'
    beta: null, gamma: null,
    accuracy: null,     // iOS webkitCompassAccuracy (± degrees), else null
    jitter: null,       // circular std dev of recent raw readings (deg)
    status: 'off',      // off | waiting | ok | nosensor | denied | unsupported
    lastSensorT: 0,

    norm360: n360, norm180: n180,
    toTrue: function (mag) { return n360(mag + (+C.declination || 0)); },
    toMag: function (tru) { return n360(tru - (+C.declination || 0)); },

    on: function (fn) { subs.push(fn); return function () { subs = subs.filter(function (f) { return f !== fn; }); }; },

    /* Start listening. Call with fromUser=true inside a click/tap handler so iOS can show its prompt. */
    start: function (fromUser) {
      if (typeof window.DeviceOrientationEvent === 'undefined') { setStatus('unsupported'); return Promise.resolve(false); }
      var needsAsk = typeof DeviceOrientationEvent.requestPermission === 'function';   // iOS 13+ (and some newer Chrome builds)
      listen(needsAsk && !granted);   // attaching listeners is harmless: events only flow once allowed
      if (!needsAsk || granted) return Promise.resolve(true);
      if (!fromUser) return Promise.resolve(!!C.lastSensorT);
      return DeviceOrientationEvent.requestPermission().then(function (st) {
        if (st !== 'granted') { if (!C.lastSensorT) setStatus('denied'); return false; }
        granted = true;
        if (C.status !== 'ok') { setStatus('waiting'); armNoSensor(); }
        return true;
      }, function () { if (!C.lastSensorT) setStatus('denied'); return false; });
    },
    stop: function () {
      window.removeEventListener('deviceorientationabsolute', onOri);
      window.removeEventListener('deviceorientation', onOri);
      listening = false; C.lastSensorT = 0; setStatus('off');
    },

    /* GPS fix {course, speed, t} — used as a heading when no compass reading is available. */
    feedGps: function (fix) { gps = fix; if (!sensorFresh()) emit(); },

    /* Manual declination (switches to manual mode). */
    setDeclination: function (d) {
      d = parseFloat(d); if (isNaN(d) || Math.abs(d) > 90) d = 0;
      C.manualDecl = d; C.declMode = 'manual';
      applyDecl(); saveDecl();
      return d;
    },
    setDeclMode: function (mode) {
      C.declMode = mode === 'manual' ? 'manual' : 'auto';
      applyDecl(); saveDecl();
    },
    /* Tell the engine where you are, for the automatic (WMM2025) declination. */
    setPosition: function (lat, lon, src) {
      if (lat == null || lon == null || !isFinite(lat) || !isFinite(lon)) return;
      var p = C.declAt;
      // the field changes slowly: recompute only after ~5 km or if never computed
      if (p && Math.abs(p.lat - lat) < 0.05 && Math.abs(p.lon - lon) < 0.05 && (p.src === src || src !== 'gps')) return;
      C.declAt = { lat: lat, lon: lon, src: src || 'gps' };
      applyDecl();
    },
    loadDeclination: function () {
      // best guess of position until GPS arrives: last fix, else last map view
      try {
        var lf = JSON.parse(localStorage.getItem('ogsk.lastfix') || 'null');
        var mv = JSON.parse(localStorage.getItem('ogsk.map.view') || 'null');
        if (lf && isFinite(lf.lat)) C.setPosition(lf.lat, lf.lon, 'last fix');
        else if (mv && isFinite(mv.lat)) C.setPosition(mv.lat, mv.lon, 'map view');
      } catch (e) {}
      if (!window.OGStore) { applyDecl(); return Promise.resolve(C.declination); }
      return OGStore.kvGet('map.settings', {}).then(function (s) {
        s = s || {};
        if (isFinite(+s.declination)) C.manualDecl = +s.declination;
        // older saves had only a manual number: keep honouring it
        C.declMode = s.declMode === 'manual' || s.declMode === 'auto' ? s.declMode : (+s.declination ? 'manual' : 'auto');
        applyDecl();
        return C.declination;
      });
    },
    declLabel: function () {
      var d = C.declination, txt = Math.abs(d).toFixed(1) + '° ' + (d >= 0 ? 'E' : 'W');
      if (C.declMode === 'manual') return txt + ' (manual)';
      if (C.autoDecl == null) return '0° (auto: position unknown — get a GPS fix)';
      return txt + ' (auto, WMM2025' + (C.declAt && C.declAt.src !== 'gps' ? ', from ' + C.declAt.src : '') + ')';
    }
  };

  function applyDecl() {
    C.autoDecl = null;
    if (C.declAt && window.OGWMM) {
      try { C.autoDecl = Math.round(OGWMM.declination(C.declAt.lat, C.declAt.lon, 0, new Date()) * 10) / 10; } catch (e) { C.autoDecl = null; }
    }
    C.declination = C.declMode === 'manual' ? C.manualDecl : (C.autoDecl == null ? 0 : C.autoDecl);
    emit();
  }
  function saveDecl() {
    if (!window.OGStore) return;
    OGStore.kvGet('map.settings', {}).then(function (s) {
      s = s || {}; s.declination = C.manualDecl; s.declMode = C.declMode;
      return OGStore.kvSet('map.settings', s);
    }).catch(function () {});
  }

  function setStatus(s) { C.status = s; emit(); }
  function sensorFresh() { return C.lastSensorT && Date.now() - C.lastSensorT < 3000; }

  function listen(waitForPermission) {
    if (listening) return;
    listening = true;
    // Prefer the absolute (earth-referenced) event where it exists (Android/Chrome);
    // listening for it is harmless where it doesn't.
    window.addEventListener('deviceorientationabsolute', onOri);
    window.addEventListener('deviceorientation', onOri);
    if (waitForPermission) { if (!C.lastSensorT) setStatus('off'); return; }   // the user must tap "Enable compass"
    setStatus('waiting');
    armNoSensor();
  }
  function armNoSensor() {
    clearTimeout(noSensorTimer);
    noSensorTimer = setTimeout(function () { if (!C.lastSensorT) setStatus('nosensor'); }, 2500);
  }

  function screenAngle() {
    if (screen.orientation && typeof screen.orientation.angle === 'number') return screen.orientation.angle;
    return typeof window.orientation === 'number' ? window.orientation : 0;
  }

  /* Heading of the vector out of the BACK of the phone (W3C DeviceOrientation spec example). */
  function backHeading(alpha, beta, gamma) {
    var x = beta * D2R, y = gamma * D2R, z = alpha * D2R;
    var cX = Math.cos(x), cY = Math.cos(y), cZ = Math.cos(z), sX = Math.sin(x), sY = Math.sin(y), sZ = Math.sin(z);
    var Vx = -cZ * sY - sZ * sX * cY, Vy = -sZ * sY + cZ * sX * cY;
    return n360(Math.atan2(Vx, Vy) * R2D);
  }

  function onOri(e) {
    var a = e.alpha, b = e.beta, g = e.gamma;
    var isAbs = e.type === 'deviceorientationabsolute' || e.absolute === true;
    var hasIOS = typeof e.webkitCompassHeading === 'number' && !isNaN(e.webkitCompassHeading) && e.webkitCompassHeading >= 0;
    // If the absolute event is flowing, ignore the relative one.
    if (e.type === 'deviceorientation' && !hasIOS && !isAbs) return;
    if (e.type === 'deviceorientation' && !hasIOS && C._absSeen) return;
    if (e.type === 'deviceorientationabsolute') C._absSeen = true;

    C.beta = b; C.gamma = g;
    if (b != null) upright = upright ? Math.abs(b) > 55 : Math.abs(b) > 65;   // hysteresis
    var h = null;
    if (hasIOS) {
      h = e.webkitCompassHeading + (upright ? 0 : screenAngle());
      C.accuracy = typeof e.webkitCompassAccuracy === 'number' ? e.webkitCompassAccuracy : null;
    } else if (isAbs && a != null) {
      h = upright && b != null && g != null ? backHeading(a, b, g) : 360 - a + screenAngle();
      C.accuracy = null;
    }
    if (h == null) return;
    h = n360(h);
    C.mode = upright ? 'upright' : 'flat';
    var now = Date.now();
    // jitter: circular std dev of raw readings over the last 1.5 s
    hist.push([now, h]);
    while (hist.length && now - hist[0][0] > 1500) hist.shift();
    if (hist.length > 4) {
      var cs = 0, ss = 0;
      hist.forEach(function (p) { cs += Math.cos(p[1] * D2R); ss += Math.sin(p[1] * D2R); });
      var Rbar = Math.min(1, Math.sqrt(cs * cs + ss * ss) / hist.length);
      C.jitter = Math.sqrt(-2 * Math.log(Math.max(Rbar, 1e-9))) * R2D;
    }
    // circular low-pass: faster response for big turns, steadier when still
    var r = h * D2R, prev = C.magHeading;
    var k = prev == null ? 1 : Math.min(0.5, Math.max(0.12, Math.abs(n180(h - prev)) / 60));
    sx = sx * (1 - k) + Math.sin(r) * k; sy = sy * (1 - k) + Math.cos(r) * k;
    C.magHeading = n360(Math.atan2(sx, sy) * R2D);
    C.lastSensorT = now;
    if (C.status !== 'ok') C.status = 'ok';
    emit();
  }

  function compute() {
    if (sensorFresh() && C.magHeading != null) { C.heading = C.toTrue(C.magHeading); C.source = 'compass'; return; }
    if (gps && gps.course != null && gps.speed != null && gps.speed > 0.7 && Date.now() - gps.t < 10000) { C.heading = n360(gps.course); C.source = 'gps'; return; }
    C.heading = null; C.source = null;
  }
  function emit() {
    if (queued) return;
    queued = true;
    (window.requestAnimationFrame || setTimeout)(function () {
      queued = false;
      compute();
      subs.slice().forEach(function (fn) { try { fn(C); } catch (err) { console.error(err); } });
    });
  }
  // keep "fresh" status honest when events stop (e.g. sensor sleeps)
  setInterval(function () { if (listening) emit(); }, 2000);
})();
