/* =====================================================================
   Sun & Moon — computed on the device with the bundled SunCalc library
   (no network). Sunrise/sunset, solar noon, civil twilight, daylight
   remaining, sun position now, moon phase/illumination, moonrise/set,
   next full and new moon. Shown for your GPS position or the map centre.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var where = 'gps';

  function valid(d) { return d instanceof Date && !isNaN(d); }
  function t(d) { return valid(d) ? App.fmtTime(d) : '—'; }
  function sunAz(date, lat, lon) { var p = SunCalc.getPosition(date, lat, lon); return { az: OGGeo.norm360(p.azimuth * 180 / Math.PI + 180), alt: p.altitude * 180 / Math.PI }; }
  function dur(ms) {
    if (ms == null || ms < 0) return '—';
    var m = Math.round(ms / 60000), h = Math.floor(m / 60);
    return h ? h + 'h ' + String(m % 60).padStart(2, '0') + 'm' : m + ' min';
  }
  function phaseName(p) {
    if (p < 0.0339 || p > 0.9661) return 'New moon';
    if (p < 0.216) return 'Waxing crescent';
    if (p < 0.284) return 'First quarter';
    if (p < 0.466) return 'Waxing gibbous';
    if (p < 0.534) return 'Full moon';
    if (p < 0.716) return 'Waning gibbous';
    if (p < 0.784) return 'Last quarter';
    return 'Waning crescent';
  }
  function moonSvg(p, southern) {
    var r = 28, cx = 32, cy = 32, rx = Math.abs(Math.cos(2 * Math.PI * p)) * r, d;
    if (p <= 0.5) d = 'M' + cx + ' ' + (cy - r) + ' A' + r + ' ' + r + ' 0 0 1 ' + cx + ' ' + (cy + r) + ' A' + rx.toFixed(2) + ' ' + r + ' 0 0 ' + (p < 0.25 ? 0 : 1) + ' ' + cx + ' ' + (cy - r) + 'Z';
    else d = 'M' + cx + ' ' + (cy - r) + ' A' + r + ' ' + r + ' 0 0 0 ' + cx + ' ' + (cy + r) + ' A' + rx.toFixed(2) + ' ' + r + ' 0 0 ' + (p > 0.75 ? 1 : 0) + ' ' + cx + ' ' + (cy - r) + 'Z';
    return '<svg class="moon-svg" viewBox="0 0 64 64" role="img" aria-label="' + phaseName(p) + '"' + (southern ? ' style="transform:scaleX(-1)"' : '') + '>' +
      '<circle cx="32" cy="32" r="28" fill="currentColor" opacity=".18" stroke="currentColor" stroke-width="1.5"/>' +
      '<path d="' + d + '" fill="currentColor"/></svg>';
  }
  /* next time the moon phase crosses `target` (0 = new, 0.5 = full) */
  function nextPhase(from, target) {
    var prev = SunCalc.getMoonIllumination(from).phase;
    for (var h = 6; h <= 24 * 32; h += 6) {
      var d = new Date(from.getTime() + h * 3600000), p = SunCalc.getMoonIllumination(d).phase;
      var crossed = target === 0 ? (p < prev) : (prev < target && p >= target);
      if (crossed) return d;
      prev = p;
    }
    return null;
  }

  /* Core daylight calculation used by the telemetry chip and the panel. */
  function daylight(lat, lon, now) {
    var noon = new Date(now); noon.setHours(12, 0, 0, 0);
    var tm = SunCalc.getTimes(noon, lat, lon);
    var res = { times: tm, now: now };
    if (!valid(tm.sunrise) || !valid(tm.sunset)) {
      var alt = sunAz(tm.solarNoon, lat, lon).alt;
      res.polar = alt > 0 ? 'day' : 'night';
      return res;
    }
    if (now < tm.sunrise) { res.state = 'before'; res.until = tm.sunrise - now; }
    else if (now < tm.sunset) { res.state = 'day'; res.left = tm.sunset - now; res.usable = valid(tm.dusk) ? tm.dusk - now : null; }
    else {
      res.state = 'after';
      var tom = new Date(noon.getTime() + 86400000), tt = SunCalc.getTimes(tom, lat, lon);
      res.until = valid(tt.sunrise) ? tt.sunrise - now : null; res.nextRise = tt.sunrise;
      res.usable = valid(tm.dusk) && now < tm.dusk ? tm.dusk - now : null;
    }
    return res;
  }

  function paintChip() {
    if (!window.SunCalc || !App.map) return;
    var h = App.here(), d = daylight(h.lat, h.lon, new Date());
    var el = $('tl-daylight'), cell = $('tl-sun');
    cell.classList.remove('low');
    if (d.polar) { el.textContent = d.polar === 'day' ? 'Sun up all day' : 'Sun down all day'; return; }
    if (d.state === 'day') {
      el.textContent = dur(d.left);
      if (d.left < 3600000) cell.classList.add('low');
    } else if (d.state === 'before') el.textContent = 'Sunrise ' + t(d.times.sunrise);
    else el.textContent = d.usable ? 'Twilight ' + dur(d.usable) : 'Dark · rise ' + t(d.nextRise);
  }

  function paintPanel() {
    if (!App.drawerOpen('sun') || !window.SunCalc) return;
    var h = where === 'gps' && App.gps.fix ? { lat: App.gps.fix.lat, lon: App.gps.fix.lon, src: 'gps' } : App.here(true);
    var ds = $('sun-date').value;
    var base = ds ? new Date(ds + 'T12:00:00') : new Date();
    var now = new Date();
    var isToday = !ds || base.toDateString() === now.toDateString();
    var tm = SunCalc.getTimes(base, h.lat, h.lon);
    var html = '<p class="help">' + (h.src === 'gps' ? 'At your GPS position' : 'At the map centre') + ' · ' + App.esc(App.fmtPos(h.lat, h.lon)) +
      (where === 'gps' && !App.gps.fix ? ' <strong>(no GPS fix — using map centre)</strong>' : '') + '</p>';
    if (isToday) {
      var d = daylight(h.lat, h.lon, now);
      if (d.polar) html += '<div class="bigread">' + (d.polar === 'day' ? 'Midnight sun — no sunset today' : 'Polar night — no sunrise today') + '</div>';
      else if (d.state === 'day') html += '<div class="muted">Daylight left (until sunset)</div><div class="bigread">' + dur(d.left) + '</div>' +
        (d.usable ? '<p>Usable light until <strong>' + t(tm.dusk) + '</strong> (civil dusk) — ' + dur(d.usable) + ' from now.</p>' : '');
      else if (d.state === 'before') html += '<div class="muted">Before sunrise</div><div class="bigread">Sunrise in ' + dur(d.until) + '</div>';
      else html += '<div class="muted">The sun has set</div><div class="bigread">' + (d.usable ? 'Twilight left ' + dur(d.usable) : 'Dark') + '</div><p>Next sunrise ' + t(d.nextRise) + ' (in ' + dur(d.until) + ').</p>';
    }
    var rise = valid(tm.sunrise) ? sunAz(tm.sunrise, h.lat, h.lon) : null, set = valid(tm.sunset) ? sunAz(tm.sunset, h.lat, h.lon) : null;
    var noonPos = sunAz(tm.solarNoon, h.lat, h.lon);
    var dayLen = valid(tm.sunrise) && valid(tm.sunset) ? tm.sunset - tm.sunrise : null;
    html += '<h3>Sun · ' + base.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' }) + '</h3><dl class="kv">' +
      '<dt>First light</dt><dd>' + t(tm.dawn) + ' <span class="muted">civil dawn</span></dd>' +
      '<dt>Sunrise</dt><dd>' + t(tm.sunrise) + (rise ? ' <span class="muted">toward ' + Math.round(rise.az) + '° ' + OGGeo.cardinal(rise.az) + '</span>' : '') + '</dd>' +
      '<dt>Solar noon</dt><dd>' + t(tm.solarNoon) + ' <span class="muted">sun due ' + (h.lat >= 0 ? 'S' : 'N') + ', ' + Math.round(noonPos.alt) + '° high</span></dd>' +
      '<dt>Sunset</dt><dd>' + t(tm.sunset) + (set ? ' <span class="muted">toward ' + Math.round(set.az) + '° ' + OGGeo.cardinal(set.az) + '</span>' : '') + '</dd>' +
      '<dt>Last light</dt><dd>' + t(tm.dusk) + ' <span class="muted">civil dusk</span></dd>' +
      '<dt>Day length</dt><dd>' + (dayLen ? dur(dayLen) : '—') + '</dd>';
    if (isToday) { var sp = sunAz(now, h.lat, h.lon); html += '<dt>Sun now</dt><dd>' + Math.round(sp.az) + '° ' + OGGeo.cardinal(sp.az) + ', ' + Math.round(sp.alt) + '° ' + (sp.alt >= 0 ? 'above' : 'below') + ' horizon</dd>'; }
    html += '</dl>';
    // Moon
    var mDate = isToday ? now : base;
    var ill = SunCalc.getMoonIllumination(mDate);
    var dayStart = new Date(base); dayStart.setHours(0, 0, 0, 0);
    var mt = SunCalc.getMoonTimes(dayStart, h.lat, h.lon);
    var nf = nextPhase(mDate, 0.5), nn = nextPhase(mDate, 0);
    html += '<h3>Moon</h3><div class="sun-row">' + moonSvg(ill.phase, h.lat < 0) + '<div><strong>' + phaseName(ill.phase) + '</strong><br>' +
      Math.round(ill.fraction * 100) + '% illuminated</div></div><dl class="kv">' +
      '<dt>Moonrise</dt><dd>' + (mt.alwaysUp ? 'Up all day' : mt.alwaysDown ? 'Down all day' : t(mt.rise)) + '</dd>' +
      '<dt>Moonset</dt><dd>' + (mt.alwaysUp || mt.alwaysDown ? '—' : t(mt.set)) + '</dd>' +
      '<dt>Next full</dt><dd>' + (nf ? nf.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' }) : '—') + '</dd>' +
      '<dt>Next new</dt><dd>' + (nn ? nn.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' }) : '—') + '</dd></dl>';
    var off = -new Date().getTimezoneOffset(), oh = Math.floor(Math.abs(off) / 60), om = Math.abs(off) % 60;
    html += '<p class="help">Times are in this device\'s time zone (UTC' + (off >= 0 ? '+' : '−') + oh + (om ? ':' + String(om).padStart(2, '0') : '') +
      '). Computed on the device; accurate to about a minute (terrain and refraction can shift actual rise/set by a few minutes).</p>' +
      '<div class="callout info"><strong class="callout-title">No watch? Hand method</strong><p>Hold your arm out straight, hand flat and sideways. Each finger-width between the sun and the horizon is roughly 15 minutes of sunlight left (a full hand ≈ 1 hour). It is a rough guide — less reliable far from the equator and in winter.</p></div>' +
      '<div class="callout warn"><strong class="callout-title">Plan for dark</strong><p>Turn around early enough to reach camp or the trailhead before civil dusk. Moonlight from a full moon helps; a new moon night is very dark.</p></div>';
    $('sun-out').innerHTML = html;
  }

  App.sunInit = function () {
    var today = new Date();
    $('sun-date').value = today.getFullYear() + '-' + String(today.getMonth() + 1).padStart(2, '0') + '-' + String(today.getDate()).padStart(2, '0');
    $('sun-date').addEventListener('change', paintPanel);
    App.seg($('sun-where'), 'data-where', where, function (v) { where = v; paintPanel(); });
    $('tl-sun').addEventListener('click', function () { App.openDrawer('sun'); });
    App.on('tab', function (tb) { if (tb === 'sun') paintPanel(); });
    var lastGps = 0;
    App.on('gps', function () { if (Date.now() - lastGps > 30000) { lastGps = Date.now(); paintChip(); } });
    App.map.on('moveend', function () { if (!App.gps.fix) paintChip(); if (where === 'center') paintPanel(); });
    App.on('settings', function (e) { if (e.key === 'coordFmt') paintPanel(); });
    setInterval(function () { paintChip(); paintPanel(); }, 60000);
    paintChip();
  };
  App.daylight = daylight;
})();
