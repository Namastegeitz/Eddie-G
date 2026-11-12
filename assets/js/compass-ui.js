/* =====================================================================
   OGCompassUI — the full compass interface, mounted into any container.
   Used by the standalone /compass/ page and by the map's compass overlay.

   Features: rotating dial (true or magnetic), big heading readout,
   bearing lock with "turn left/right" steering + back bearing, level
   bubble (hold flat), calibration / interference warnings, sun & moon
   markers on the dial (check the compass against the sky), navigate to a
   saved waypoint (bearing from GPS), camera sighting mode with a heading
   tape, bearing log, and spoken heading (offline text-to-speech).

   OGCompassUI.mount(root, {
     getFix:  () => {lat, lon, acc, speed, course, t} | null,   // live GPS
     onLock:  (trueBearing | null, info) => {}                  // optional
   }) -> { setActive(bool) }
   Needs: compass.js (OGCompass), store.js, geo.js; suncalc.js optional.
   ===================================================================== */
(function () {
  'use strict';
  var C = window.OGCompass;
  var CARD16 = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  var CARD_WORD = { N: 'north', NNE: 'north-north-east', NE: 'north-east', ENE: 'east-north-east', E: 'east', ESE: 'east-south-east', SE: 'south-east', SSE: 'south-south-east', S: 'south', SSW: 'south-south-west', SW: 'south-west', WSW: 'west-south-west', W: 'west', WNW: 'west-north-west', NW: 'north-west', NNW: 'north-north-west' };
  function card(d) { return CARD16[Math.round(C.norm360(d) / 22.5) % 16]; }
  function p3(d) { return String(Math.round(C.norm360(d)) % 360).padStart(3, '0'); }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function toast(m, o) { if (window.OGSK && OGSK.toast) OGSK.toast(m, o); }

  /* ---------- dial SVG (built once; the card group rotates) ---------- */
  function dialSvg() {
    var s = '<svg class="cmp-dial" viewBox="0 0 400 400" role="img" aria-label="Compass dial">';
    s += '<g class="cmp-card">';
    s += '<circle cx="200" cy="200" r="188" class="cmp-face"/>';
    for (var a = 0; a < 360; a += 5) {
      var r2 = a % 30 === 0 ? 160 : a % 10 === 0 ? 170 : 177, rad = a * Math.PI / 180;
      s += '<line x1="' + (200 + 186 * Math.sin(rad)).toFixed(1) + '" y1="' + (200 - 186 * Math.cos(rad)).toFixed(1) + '" x2="' + (200 + r2 * Math.sin(rad)).toFixed(1) + '" y2="' + (200 - r2 * Math.cos(rad)).toFixed(1) + '" class="cmp-tick' + (a % 30 === 0 ? ' big' : '') + '"/>';
    }
    for (a = 30; a < 360; a += 30) {
      if (a % 90 === 0) continue;
      s += '<text x="200" y="58" class="cmp-num" transform="rotate(' + a + ' 200 200)">' + a + '</text>';
    }
    [['N', 0], ['E', 90], ['S', 180], ['W', 270]].forEach(function (c) {
      s += '<text x="200" y="74" class="cmp-cardinal' + (c[0] === 'N' ? ' north' : '') + '" transform="rotate(' + c[1] + ' 200 200)">' + c[0] + '</text>';
    });
    [['NE', 45], ['SE', 135], ['SW', 225], ['NW', 315]].forEach(function (c) {
      s += '<text x="200" y="76" class="cmp-inter" transform="rotate(' + c[1] + ' 200 200)">' + c[0] + '</text>';
    });
    // markers (each rotated to its bearing on the card)
    s += '<g class="cmp-mk cmp-mk-target" hidden><path d="M200 6 L212 26 L200 21 L188 26 Z"/><circle cx="200" cy="36" r="5"/></g>';
    s += '<g class="cmp-mk cmp-mk-lock" hidden><path d="M200 2 L216 30 L184 30 Z"/></g>';
    s += '<g class="cmp-mk cmp-mk-back" hidden><path d="M200 2 L210 20 L190 20 Z"/></g>';
    s += '<g class="cmp-mk cmp-mk-sun" hidden><circle cx="200" cy="104" r="11"/><g class="rays">' + rays(200, 104) + '</g></g>';
    s += '<g class="cmp-mk cmp-mk-moon" hidden><circle cx="200" cy="104" r="10"/><circle cx="205" cy="101" r="9" class="cut"/></g>';
    // N needle on the card
    s += '<path d="M200 92 L214 200 L200 188 L186 200 Z" class="cmp-needle-n"/><path d="M200 308 L214 200 L200 212 L186 200 Z" class="cmp-needle-s"/>';
    s += '</g>';
    // fixed: lubber line (direction of travel) + centre
    s += '<path d="M200 0 L211 22 L189 22 Z" class="cmp-lubber"/><line x1="200" y1="22" x2="200" y2="58" class="cmp-lubber-line"/>';
    s += '<circle cx="200" cy="200" r="9" class="cmp-hub"/>';
    s += '</svg>';
    return s;
  }
  function rays(cx, cy) {
    var s = '';
    for (var a = 0; a < 360; a += 45) { var r = a * Math.PI / 180; s += '<line x1="' + (cx + 14 * Math.sin(r)).toFixed(1) + '" y1="' + (cy - 14 * Math.cos(r)).toFixed(1) + '" x2="' + (cx + 19 * Math.sin(r)).toFixed(1) + '" y2="' + (cy - 19 * Math.cos(r)).toFixed(1) + '"/>'; }
    return s;
  }

  function mount(root, opts) {
    opts = opts || {};
    var ref = localStorage.getItem('ogsk.compass.ref') || 'true';   // declination is automatic (WMM2025), so TRUE is a safe default
    var lock = null;          // TRUE bearing or null
    var target = null;        // waypoint {id,name,lat,lon} (lock follows it)
    var sight = false, stream = null, active = false, unsub = null, onCourse = false;
    var sunPos = null, moonPos = null, sunT = 0;

    root.classList.add('cmp');
    root.innerHTML =
      '<div class="cmp-top">' +
      '  <div class="cmp-read" role="status" aria-live="off"><span class="cmp-deg">---°</span><span class="cmp-cardtxt">—</span></div>' +
      '  <div class="cmp-meta"><button class="btn cmp-ref" type="button" aria-label="Switch true or magnetic north">TRUE</button><span class="cmp-src"></span></div>' +
      '</div>' +
      '<div class="cmp-steer" aria-live="polite" hidden></div>' +
      '<div class="cmp-stage">' +
      '  <video class="cmp-video" playsinline muted autoplay hidden></video>' +
      '  <div class="cmp-dialwrap">' + dialSvg() + '</div>' +
      '  <svg class="cmp-tape" viewBox="0 0 400 76" hidden aria-hidden="true"></svg>' +
      '  <div class="cmp-level" title="Level: keep the bubble in the centre"><div class="cmp-bubble"></div></div>' +
      '</div>' +
      '<div class="cmp-warn" role="status"></div>' +
      '<div class="cmp-btns">' +
      '  <button class="btn primary cmp-enable" type="button">Enable compass</button>' +
      '  <button class="btn cmp-lock" type="button" aria-pressed="false">Lock bearing</button>' +
      '  <button class="btn cmp-set" type="button">Set bearing…</button>' +
      '  <button class="btn cmp-target" type="button">Go to waypoint…</button>' +
      '  <button class="btn cmp-sight" type="button" aria-pressed="false">Sight with camera</button>' +
      '  <button class="btn cmp-capture" type="button">Capture bearing</button>' +
      '  <button class="btn cmp-say" type="button">Say heading</button>' +
      '</div>' +
      '<div class="cmp-panel cmp-setbox" hidden>' +
      '  <label>Bearing to follow (°, <span class="cmp-setref">true</span>)<input type="number" class="cmp-setin" min="0" max="360" step="1" inputmode="numeric"></label>' +
      '  <div class="row"><button class="btn primary cmp-setok" type="button">Lock it</button><button class="btn cmp-setcancel" type="button">Cancel</button></div>' +
      '</div>' +
      '<div class="cmp-panel cmp-tgtbox" hidden>' +
      '  <label>Waypoint<select class="cmp-tgtsel"></select></label>' +
      '  <p class="muted cmp-tgtmsg"></p>' +
      '  <div class="row"><button class="btn primary cmp-tgtok" type="button">Point me there</button><button class="btn cmp-tgtcancel" type="button">Cancel</button></div>' +
      '</div>' +
      '<dl class="cmp-info"></dl>' +
      '<details class="item cmp-logbox"><summary>Bearing log <span class="sub cmp-logcount"></span></summary><div class="body"><ul class="cmp-log"></ul>' +
      '  <div class="row"><button class="btn cmp-logcopy" type="button">Copy all</button><button class="btn danger cmp-logclear" type="button">Clear log</button></div></div></details>' +
      '<details class="item"><summary>How to use &amp; calibrate</summary><div class="body">' +
      '  <ol class="steps">' +
      '    <li><strong>Hold the phone flat</strong> in front of you, top edge pointing where you want to go. Keep the level bubble near the centre.</li>' +
      '    <li>The number at the top is the direction the <strong>top of the phone</strong> points. The red needle points north.</li>' +
      '    <li><strong>Walk a bearing:</strong> face the way you need to go and tap <em>Lock bearing</em> (or <em>Set bearing…</em>). Follow the “turn left / turn right” prompt until it says <em>On bearing</em>. Pick a landmark on that line, walk to it, repeat.</li>' +
      '    <li><strong>Take a bearing to a landmark:</strong> tap <em>Sight with camera</em>, hold the phone upright, put the landmark on the centre line and tap <em>Capture bearing</em>. Use 2–3 of these in Map → Triangulate.</li>' +
      '    <li><strong>Calibrate</strong> if readings jump or disagree with the sun marker: move the phone slowly in a figure-8 a few times.</li>' +
      '  </ol>' +
      '  <div class="callout warn"><strong class="callout-title">Phone compasses can be wrong</strong><p>Metal, magnets (phone cases with magnetic clasps), vehicles, power lines and speakers bend the reading by tens of degrees. Step away from them. Check against the sun marker when the sun is out, and carry a real baseplate compass for anything that matters.</p></div>' +
      '  <p class="muted">Phones measure <strong>magnetic</strong> north. Map grid and GPS bearings are <strong>true</strong>. The app works out the difference (declination) for your position automatically from the World Magnetic Model 2025, so TRUE readings match the map. You can enter your own value with <em>Manual</em> (e.g. from a current topo map).</p>' +
      '</div></details>';

    var $ = function (sel) { return root.querySelector(sel); };
    var cardG = $('.cmp-card'), mk = {
      lock: $('.cmp-mk-lock'), back: $('.cmp-mk-back'), target: $('.cmp-mk-target'), sun: $('.cmp-mk-sun'), moon: $('.cmp-mk-moon')
    };

    function dispFromTrue(t) { return ref === 'true' ? C.norm360(t) : C.toMag(t); }
    function trueFromDisp(d) { return ref === 'true' ? C.norm360(d) : C.toTrue(d); }
    function setMk(el, trueBrg) {
      if (trueBrg == null) { el.setAttribute('hidden', ''); return; }
      el.removeAttribute('hidden');
      el.setAttribute('transform', 'rotate(' + dispFromTrue(trueBrg).toFixed(1) + ' 200 200)');
    }

    /* sun & moon azimuths (true) for the best known position */
    function knownPos() {
      var f = opts.getFix && opts.getFix();
      if (f) return f;
      try { var lf = JSON.parse(localStorage.getItem('ogsk.lastfix') || 'null'); if (lf) return lf; } catch (e) {}
      try { var v = JSON.parse(localStorage.getItem('ogsk.map.view') || 'null'); if (v) return { lat: v.lat, lon: v.lon, approx: true }; } catch (e2) {}
      return null;
    }
    function updateSky() {
      if (!window.SunCalc || Date.now() - sunT < 30000) return;
      sunT = Date.now();
      var p = knownPos(); if (!p) { sunPos = moonPos = null; return; }
      var s = SunCalc.getPosition(new Date(), p.lat, p.lon), m = SunCalc.getMoonPosition(new Date(), p.lat, p.lon);
      sunPos = { az: C.norm360(s.azimuth * 180 / Math.PI + 180), alt: s.altitude * 180 / Math.PI };
      moonPos = { az: C.norm360(m.azimuth * 180 / Math.PI + 180), alt: m.altitude * 180 / Math.PI };
    }

    function steer(h) {
      var el = $('.cmp-steer');
      if (lock == null || h == null) { el.hidden = true; onCourse = false; return; }
      var d = C.norm180(lock - h);
      el.hidden = false;
      var was = onCourse;
      onCourse = Math.abs(d) <= 3;
      el.className = 'cmp-steer ' + (onCourse ? 'ok' : Math.abs(d) > 30 ? 'far' : 'near');
      var tgt = p3(dispFromTrue(lock)) + '°';
      el.textContent = onCourse ? 'ON BEARING ✓  ' + tgt :
        d > 0 ? 'Turn RIGHT ' + Math.round(d) + '° →  (' + tgt + ')' : '← Turn LEFT ' + Math.round(-d) + '°  (' + tgt + ')';
      if (onCourse && !was && navigator.vibrate) navigator.vibrate(60);
    }

    function paintTape(H) {
      var t = $('.cmp-tape'), s = '', ppd = 400 / 70;
      for (var d = Math.floor((H - 36) / 5) * 5; d <= H + 36; d += 5) {
        var x = 200 + (d - H) * ppd, big = d % 15 === 0;
        s += '<line x1="' + x.toFixed(1) + '" y1="' + (big ? 30 : 40) + '" x2="' + x.toFixed(1) + '" y2="58" class="cmp-tick' + (big ? ' big' : '') + '"/>';
        if (big) { var lbl = C.norm360(d); s += '<text x="' + x.toFixed(1) + '" y="24" class="cmp-tapenum">' + (lbl % 90 === 0 ? ['N', 'E', 'S', 'W'][lbl / 90] : lbl) + '</text>'; }
      }
      if (lock != null) { var lx = 200 + C.norm180(dispFromTrue(lock) - H) * ppd; if (lx > 0 && lx < 400) s += '<path d="M' + lx.toFixed(1) + ' 76 l-9 -14 h18 z" class="cmp-tapelock"/>'; }
      s += '<line x1="200" y1="0" x2="200" y2="76" class="cmp-lubber-line"/>';
      t.innerHTML = s;
    }

    function paint() {
      if (!active) return;
      updateSky();
      var h = C.heading;                        // TRUE (sensor or GPS course)
      if (target) {
        var f = opts.getFix && opts.getFix();
        if (f) lock = OGGeo.bearing(f.lat, f.lon, target.lat, target.lon);
      }
      var H = h == null ? null : dispFromTrue(h);
      $('.cmp-deg').textContent = H == null ? '---°' : p3(H) + '°';
      $('.cmp-cardtxt').textContent = H == null ? '' : card(H);
      $('.cmp-ref').textContent = ref === 'true' ? 'TRUE' : 'MAG';
      $('.cmp-ref').setAttribute('aria-pressed', ref === 'true' ? 'true' : 'false');
      $('.cmp-src').textContent = C.source === 'compass' ? (C.mode === 'upright' ? 'compass · upright (camera direction)' : 'compass · flat (top edge)') :
        C.source === 'gps' ? 'GPS course (direction of travel)' : '';
      cardG.setAttribute('transform', 'rotate(' + (H == null ? 0 : -H).toFixed(1) + ' 200 200)');
      setMk(mk.lock, target ? null : lock); setMk(mk.back, lock == null ? null : lock + 180);
      setMk(mk.target, target ? lock : null);
      setMk(mk.sun, sunPos && sunPos.alt > -2 ? sunPos.az : null);
      setMk(mk.moon, moonPos && moonPos.alt > 0 ? moonPos.az : null);
      if (sight && H != null) paintTape(H);
      steer(h);
      // level bubble (flat mode only)
      var lv = $('.cmp-level'), bub = $('.cmp-bubble');
      if (C.beta == null || C.mode === 'upright' || sight) lv.hidden = true;
      else {
        lv.hidden = false;
        var bx = Math.max(-1, Math.min(1, (C.gamma || 0) / 30)), by = Math.max(-1, Math.min(1, (C.beta || 0) / 30));
        bub.style.transform = 'translate(' + (bx * 22).toFixed(1) + 'px,' + (by * 22).toFixed(1) + 'px)';
        lv.classList.toggle('off', Math.abs(C.beta) > 12 || Math.abs(C.gamma) > 12);
      }
      paintWarn();
      paintInfo(h);
      $('.cmp-enable').hidden = C.status === 'ok' || C.status === 'unsupported';
    }

    function paintWarn() {
      var w = [], el = $('.cmp-warn');
      if (C.status === 'off') w.push('Tap <strong>Enable compass</strong> to start the compass sensor.');
      if (C.status === 'waiting') w.push('Starting compass… move the phone a little.');
      if (C.status === 'denied') w.push('Compass permission was refused. On iPhone: close and reopen this page, then allow Motion &amp; Orientation access.');
      if (C.status === 'unsupported' || C.status === 'nosensor') w.push('No compass sensor found on this device/browser. ' + (C.source === 'gps' ? 'Showing GPS direction of travel.' : 'Start walking with GPS on and your direction of travel will show here.'));
      if (C.status === 'ok') {
        if (C.accuracy != null && (C.accuracy < 0 || C.accuracy > 25)) w.push('Low compass accuracy' + (C.accuracy > 0 ? ' (±' + Math.round(C.accuracy) + '°)' : '') + ' — move the phone slowly in a figure-8 to calibrate.');
        else if (C.jitter != null && C.jitter > 8) w.push('Unsteady reading (±' + Math.round(C.jitter) + '°) — hold still, step away from metal, cars and magnets, or calibrate with a figure-8.');
        if (C.mode === 'flat' && !sight && C.beta != null && (Math.abs(C.beta) > 20 || Math.abs(C.gamma) > 20)) w.push('Hold the phone flat for an accurate reading.');
        if (sight && C.mode !== 'upright') w.push('Hold the phone upright to sight with the camera.');
      }
      el.innerHTML = w.join('<br>');
      el.hidden = !w.length;
    }

    var infoT = 0, infoHold = false, infoLast = '';
    function paintInfo(h) {
      if (Date.now() - infoT < 500) return; infoT = Date.now();
      var f = opts.getFix && opts.getFix(), html = '';
      if (lock != null) html += '<dt>' + (target ? 'To ' + esc(target.name) : 'Locked bearing') + '</dt><dd>' + p3(dispFromTrue(lock)) + '° ' + card(dispFromTrue(lock)) +
        ' · back bearing ' + p3(dispFromTrue(lock + 180)) + '°' + (target && f ? ' · ' + OGGeo.fmtDist(OGGeo.distance(f.lat, f.lon, target.lat, target.lon), unitsPref()) : '') +
        (target && !f ? ' · <em>needs a GPS fix</em>' : '') + '</dd>';
      if (h != null) html += '<dt>Back bearing</dt><dd>' + p3(dispFromTrue(h + 180)) + '° ' + card(dispFromTrue(h + 180)) + '</dd>';
      if (h != null && +C.declination) html += '<dt>True / magnetic</dt><dd>' + p3(h) + '° T · ' + p3(C.toMag(h)) + '° M</dd>';
      if (C.declMode === 'manual') html += '<dt>Declination</dt><dd><input class="cmp-decl" type="number" step="0.1" min="-90" max="90" value="' + (+C.manualDecl || 0) + '" aria-label="Manual magnetic declination, degrees, east positive"> ° <span class="muted">(E +, W −)</span> <button class="btn cmp-declauto" type="button">Use auto</button></dd>';
      else html += '<dt>Declination</dt><dd>' + esc(C.declLabel()) + ' <button class="btn cmp-declman" type="button">Manual…</button></dd>';
      if (f) html += '<dt>GPS</dt><dd>' + f.lat.toFixed(5) + ', ' + f.lon.toFixed(5) + ' ±' + Math.round(f.acc || 0) + ' m' + (f.speed != null ? ' · ' + OGGeo.fmtSpeed(f.speed, unitsPref()) : '') + '</dd>';
      if (sunPos) html += '<dt>Sun</dt><dd>' + p3(dispFromTrue(sunPos.az)) + '° ' + (sunPos.alt > 0 ? Math.round(sunPos.alt) + '° up — check: point the top of the phone at the sun; the ☀ mark should sit under the top line' : 'below the horizon') + '</dd>';
      if (moonPos && moonPos.alt > 0) html += '<dt>Moon</dt><dd>' + p3(dispFromTrue(moonPos.az)) + '° · ' + Math.round(moonPos.alt) + '° up</dd>';
      var dl = $('.cmp-info');
      var focused = document.activeElement && document.activeElement.classList.contains('cmp-decl');
      // don't rebuild while a finger is on the panel (a rebuild would swallow the tap) or nothing changed
      if (!focused && !infoHold && html !== infoLast) { dl.innerHTML = html; infoLast = html; }
    }
    var units = 'metric';
    if (window.OGStore) OGStore.kvGet('map.settings', {}).then(function (st) { if (st && st.units) units = st.units; });
    function unitsPref() { return units; }

    /* ---------- actions ---------- */
    function setLock(trueBrg, tgt) {
      lock = trueBrg == null ? null : C.norm360(trueBrg);
      target = tgt || null;
      $('.cmp-lock').setAttribute('aria-pressed', lock != null ? 'true' : 'false');
      $('.cmp-lock').textContent = lock != null ? 'Unlock' : 'Lock bearing';
      try { localStorage.setItem('ogsk.compass.lock', JSON.stringify({ lock: lock, target: target })); } catch (e) {}
      if (opts.onLock) opts.onLock(lock, { target: target });
      infoT = 0; paint();
    }
    function enable() {
      C.start(true).then(function (ok) {
        if (!ok && C.status === 'denied') toast('Compass permission denied', { error: true });
        else if (!ok && C.status === 'unsupported') toast('This browser has no compass sensor access', { error: true });
      });
    }
    function capture() {
      var h = C.heading;
      if (h == null) { toast('No heading yet — enable the compass or start walking with GPS', { error: true }); return; }
      var f = opts.getFix && opts.getFix();
      var e = { t: Date.now(), tru: Math.round(h * 10) / 10, mag: Math.round(C.toMag(h) * 10) / 10, src: C.source, mode: C.mode, lat: f ? +f.lat.toFixed(6) : null, lon: f ? +f.lon.toFixed(6) : null };
      var p = window.OGStore ? OGStore.kvGet('compass.log', []) : Promise.resolve([]);
      p.then(function (log) {
        log.unshift(e); log = log.slice(0, 50);
        return window.OGStore ? OGStore.kvSet('compass.log', log).then(function () { return log; }) : log;
      }).then(function (log) { paintLog(log); toast('Captured ' + p3(dispFromTrue(h)) + '° ' + (ref === 'true' ? 'true' : 'magnetic')); if (navigator.vibrate) navigator.vibrate(40); });
    }
    function logLine(e) {
      return new Date(e.t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) + '  ' + String(Math.round(e.tru)).padStart(3, '0') + '° T / ' +
        String(Math.round(e.mag)).padStart(3, '0') + '° M' + (e.src === 'gps' ? ' (GPS course)' : '') + (e.lat != null ? '  from ' + e.lat + ', ' + e.lon : '');
    }
    function paintLog(log) {
      $('.cmp-logcount').textContent = log.length ? log.length + ' saved' : '';
      $('.cmp-log').innerHTML = log.length ? log.map(function (e, i) {
        return '<li><span class="mono">' + esc(logLine(e)) + '</span> <button class="btn" type="button" data-del="' + i + '" aria-label="Delete">✕</button></li>';
      }).join('') : '<li class="muted">No bearings captured yet.</li>';
    }
    function loadLog() { if (window.OGStore) OGStore.kvGet('compass.log', []).then(paintLog); else paintLog([]); }
    function say() {
      var h = C.heading;
      if (!('speechSynthesis' in window)) { toast('Speech is not available on this device', { error: true }); return; }
      var txt = h == null ? 'No heading yet.' :
        'Heading ' + String(Math.round(dispFromTrue(h)) % 360).split('').join(' ') + ' degrees ' + (ref === 'true' ? 'true' : 'magnetic') + ', ' + CARD_WORD[card(dispFromTrue(h))] + '.';
      if (lock != null && h != null) {
        var d = C.norm180(lock - h);
        txt += Math.abs(d) <= 3 ? ' On bearing.' : ' Turn ' + (d > 0 ? 'right ' : 'left ') + Math.round(Math.abs(d)) + ' degrees.';
      }
      speechSynthesis.cancel();
      speechSynthesis.speak(new SpeechSynthesisUtterance(txt));
    }
    function toggleSight() {
      sight = !sight;
      $('.cmp-sight').setAttribute('aria-pressed', sight ? 'true' : 'false');
      root.classList.toggle('sighting', sight);
      if (sight) $('.cmp-tape').removeAttribute('hidden'); else $('.cmp-tape').setAttribute('hidden', '');   // SVG: no .hidden property
      var v = $('.cmp-video');
      if (sight) {
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) { v.hidden = true; toast('Camera not available — sight along the phone\'s top edge instead'); return; }
        navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false }).then(function (s) {
          if (!sight) { s.getTracks().forEach(function (t) { t.stop(); }); return; }
          stream = s; v.srcObject = s; v.hidden = false; root.classList.add('has-video'); v.play().catch(function () {});
        }).catch(function () { v.hidden = true; toast('Camera unavailable — hold the phone upright and sight along its back'); });
      } else stopCamera();
      paint();
    }
    function stopCamera() {
      if (stream) { stream.getTracks().forEach(function (t) { t.stop(); }); stream = null; }
      var v = $('.cmp-video'); v.srcObject = null; v.hidden = true; root.classList.remove('has-video');
    }
    function openTarget() {
      var box = $('.cmp-tgtbox'), sel = $('.cmp-tgtsel');
      $('.cmp-setbox').hidden = true;
      if (!window.OGStore) return;
      OGStore.all('waypoints').then(function (wps) {
        wps.sort(function (a, b) { return a.name.localeCompare(b.name); });
        sel.innerHTML = wps.length ? wps.map(function (w) { return '<option value="' + esc(w.id) + '">' + esc(w.name) + '</option>'; }).join('') : '<option value="">No waypoints saved yet</option>';
        $('.cmp-tgtmsg').textContent = (opts.getFix && opts.getFix()) ? 'The bearing updates as you move.' : 'Waiting for a GPS fix — the bearing appears once you have one.';
        box.hidden = false; sel.focus();
        box._wps = wps;
      });
    }

    /* ---------- wire up ---------- */
    $('.cmp-enable').addEventListener('click', enable);
    $('.cmp-ref').addEventListener('click', function () {
      ref = ref === 'true' ? 'mag' : 'true';
      try { localStorage.setItem('ogsk.compass.ref', ref); } catch (e) {}
      if (ref === 'true' && C.autoDecl == null && C.declMode === 'auto') toast('Declination unknown until the first GPS fix — TRUE equals magnetic for now');
      infoT = 0; paint();
    });
    $('.cmp-lock').addEventListener('click', function () {
      if (lock != null) { setLock(null); return; }
      if (C.heading == null) { toast('No heading yet', { error: true }); return; }
      setLock(C.heading);
      toast('Locked ' + p3(dispFromTrue(lock)) + '°');
    });
    $('.cmp-set').addEventListener('click', function () {
      $('.cmp-tgtbox').hidden = true;
      $('.cmp-setref').textContent = ref === 'true' ? 'true' : 'magnetic';
      $('.cmp-setin').value = lock != null ? Math.round(dispFromTrue(lock)) : '';
      $('.cmp-setbox').hidden = false; $('.cmp-setin').focus();
    });
    $('.cmp-setok').addEventListener('click', function () {
      var v = parseFloat($('.cmp-setin').value);
      if (isNaN(v) || v < 0 || v > 360) { toast('Enter 0–360', { error: true }); return; }
      setLock(trueFromDisp(v)); $('.cmp-setbox').hidden = true;
    });
    $('.cmp-setin').addEventListener('keydown', function (e) { if (e.key === 'Enter') $('.cmp-setok').click(); });
    $('.cmp-setcancel').addEventListener('click', function () { $('.cmp-setbox').hidden = true; });
    $('.cmp-target').addEventListener('click', openTarget);
    $('.cmp-tgtcancel').addEventListener('click', function () { $('.cmp-tgtbox').hidden = true; });
    $('.cmp-tgtok').addEventListener('click', function () {
      var box = $('.cmp-tgtbox'), id = $('.cmp-tgtsel').value;
      var w = (box._wps || []).filter(function (x) { return x.id === id; })[0];
      if (!w) { box.hidden = true; return; }
      var f = opts.getFix && opts.getFix();
      setLock(f ? OGGeo.bearing(f.lat, f.lon, w.lat, w.lon) : null, { id: w.id, name: w.name, lat: w.lat, lon: w.lon });
      box.hidden = true;
    });
    $('.cmp-sight').addEventListener('click', toggleSight);
    $('.cmp-capture').addEventListener('click', capture);
    $('.cmp-say').addEventListener('click', say);
    $('.cmp-log').addEventListener('click', function (e) {
      var b = e.target.closest('[data-del]'); if (!b || !window.OGStore) return;
      OGStore.kvGet('compass.log', []).then(function (log) { log.splice(+b.getAttribute('data-del'), 1); return OGStore.kvSet('compass.log', log).then(function () { paintLog(log); }); });
    });
    $('.cmp-logcopy').addEventListener('click', function () {
      if (!window.OGStore) return;
      OGStore.kvGet('compass.log', []).then(function (log) {
        var txt = log.map(logLine).join('\n');
        if (navigator.clipboard) navigator.clipboard.writeText(txt).then(function () { toast('Copied'); }, function () { toast('Copy failed', { error: true }); });
      });
    });
    $('.cmp-logclear').addEventListener('click', function () {
      if (!window.OGStore || !confirm('Clear all captured bearings?')) return;
      OGStore.kvSet('compass.log', []).then(function () { paintLog([]); });
    });
    var infoEl = $('.cmp-info');
    infoEl.addEventListener('pointerdown', function () { infoHold = true; });
    ['pointerup', 'pointercancel', 'pointerleave'].forEach(function (t) { infoEl.addEventListener(t, function () { setTimeout(function () { infoHold = false; }, 400); }); });
    root.addEventListener('click', function (e) {
      if (e.target.closest('.cmp-declman')) { C.setDeclination(C.autoDecl != null ? C.autoDecl : C.manualDecl); infoT = 0; paint(); setTimeout(function () { var i = $('.cmp-decl'); if (i) { i.focus(); i.select(); } }, 50); }
      if (e.target.closest('.cmp-declauto')) { C.setDeclMode('auto'); infoT = 0; toast('Declination: ' + C.declLabel()); }
    });
    root.addEventListener('change', function (e) {
      if (e.target.classList.contains('cmp-decl')) { C.setDeclination(e.target.value); infoT = 0; toast('Declination: ' + C.declLabel()); }
    });

    // restore a saved lock / target
    try {
      var saved = JSON.parse(localStorage.getItem('ogsk.compass.lock') || 'null');
      if (saved) { lock = saved.lock; target = saved.target; if (lock != null || target) { $('.cmp-lock').setAttribute('aria-pressed', 'true'); $('.cmp-lock').textContent = 'Unlock'; } }
    } catch (e) {}
    loadLog();

    var api = {
      setActive: function (on) {
        if (on === active) return;
        active = on;
        if (on) {
          unsub = C.on(paint);
          C.start(false);
          if (window.OGSK && OGSK.wakeLock) OGSK.wakeLock.request();
          sunT = 0; infoT = 0; paint();
        } else {
          if (unsub) unsub(); unsub = null;
          if (sight) { sight = false; root.classList.remove('sighting'); $('.cmp-tape').setAttribute('hidden', ''); $('.cmp-sight').setAttribute('aria-pressed', 'false'); }
          stopCamera();
          if (window.OGSK && OGSK.wakeLock) OGSK.wakeLock.release();
        }
      },
      enable: enable,
      getLock: function () { return lock; }
    };
    if (opts.onLock && lock != null) setTimeout(function () { opts.onLock(lock, { target: target }); }, 0);
    return api;
  }

  window.OGCompassUI = { mount: mount };
})();
