/* =====================================================================
   Live sky — the newest real pictures of the area (needs signal)
   ---------------------------------------------------------------------
   No satellite streams public live video, so this shows the closest thing:
   - "Satellite now": geostationary weather-satellite pictures every 10–15 min,
     played as a loop of the last ~1.5–2 h. The satellite is picked from the
     map centre:  GOES-West / GOES-East (NOAA, via NASA GIBS) for the Americas,
     Meteosat 0° (EUMETSAT) for Europe/Africa/Portugal, Meteosat Indian Ocean
     for the Middle East/Saudi Arabia, Himawari (JMA, via GIBS) for Asia/
     Pacific. Natural colour by day, infrared at night for Meteosat/Himawari.
   - "Rain radar": RainViewer composite, every 10 min, past 2 h (where radar
     networks exist).
   - "Today's photo": NASA GIBS NOAA-20 VIIRS true colour, once a day, sharper.
   These are display-only overlays (not saved offline). Sources verified:
   all serve CORS-enabled tiles; NASA returns 404 for frames not yet
   available, which are skipped automatically.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var GIBS = 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/';
  var EUM = 'https://view.eumetsat.int/geoserver/wms';
  var sat = null, radar = null, daily = null;     // {layers:[{layer,time,bad}], info}
  var timeline = [], idx = 0, timer = null, playing = true, opacity = 0.85;
  var dayOffset = 0;

  function pad(n) { return String(n).padStart(2, '0'); }
  function iso(d) { return d.getUTCFullYear() + '-' + pad(d.getUTCMonth() + 1) + '-' + pad(d.getUTCDate()) + 'T' + pad(d.getUTCHours()) + ':' + pad(d.getUTCMinutes()) + ':00Z'; }
  function ymd(d) { return d.getUTCFullYear() + '-' + pad(d.getUTCMonth() + 1) + '-' + pad(d.getUTCDate()); }
  function hm(t) { return new Date(t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }); }
  function ago(t) {
    var m = Math.round((Date.now() - t) / 60000);
    return m < 60 ? m + ' min ago' : Math.floor(m / 60) + ' h ' + pad(m % 60) + ' min ago';
  }

  /* Which satellite sees the map centre best, and day or night there? */
  function pickSat() {
    var c = App.map.getCenter(), lon = ((c.lng + 540) % 360) - 180, now = new Date();
    // natural-colour pictures are dark around dawn/dusk: if the sun is low (< 8°) at any time in the
    // ~2-hour loop, use infrared for the whole loop (works day and night, no flicker between products)
    var night = false;
    if (window.SunCalc) for (var m = 0; m <= 150; m += 30) {
      if (SunCalc.getPosition(new Date(now.getTime() - m * 60000), c.lat, lon).altitude * 180 / Math.PI < 8) night = true;
    }
    if (lon < -105) return { kind: 'gibs', key: 'goesw', name: 'GOES-West (NOAA)', layer: 'GOES-West_ABI_GeoColor', tms: 'GoogleMapsCompatible_Level7', z: 7, step: 10, frames: 6, every: 2, attr: 'Satellite: NOAA GOES-West GeoColor via NASA GIBS' };
    if (lon < -25) return { kind: 'gibs', key: 'goese', name: 'GOES-East (NOAA)', layer: 'GOES-East_ABI_GeoColor', tms: 'GoogleMapsCompatible_Level7', z: 7, step: 10, frames: 6, every: 2, attr: 'Satellite: NOAA GOES-East GeoColor via NASA GIBS' };
    if (lon < 30) return { kind: 'eum', key: 'fes' + night, name: 'Meteosat 0° (EUMETSAT)' + (night ? ' · infrared (low sun / night)' : ''), layer: night ? 'msg_fes:ir108' : 'msg_fes:rgb_naturalenhncd', step: 15, frames: 6, every: 1, night: night, attr: 'Satellite: © EUMETSAT Meteosat' };
    if (lon < 85) return { kind: 'eum', key: 'iodc' + night, name: 'Meteosat Indian Ocean (EUMETSAT)' + (night ? ' · infrared (low sun / night)' : ''), layer: night ? 'msg_iodc:ir108' : 'msg_iodc:rgb_naturalenhncd', step: 15, frames: 6, every: 1, night: night, attr: 'Satellite: © EUMETSAT Meteosat (IODC)' };
    return night ?
      { kind: 'gibs', key: 'himn', name: 'Himawari (JMA) · infrared (low sun / night)', layer: 'Himawari_AHI_Band13_Clean_Infrared', tms: 'GoogleMapsCompatible_Level6', z: 6, step: 10, frames: 6, every: 2, attr: 'Satellite: JMA Himawari via NASA GIBS' } :
      { kind: 'gibs', key: 'himd', name: 'Himawari (JMA)', layer: 'Himawari_AHI_Band3_Red_Visible_1km', tms: 'GoogleMapsCompatible_Level7', z: 7, step: 10, frames: 6, every: 2, attr: 'Satellite: JMA Himawari via NASA GIBS' };
  }

  function makeFrame(set, layer, t) {
    var f = { layer: layer, time: t, loaded: 0, failed: 0, bad: false };
    layer.on('tileload', function () { f.loaded++; if (f.bad) { f.bad = false; rebuildTimeline(); } });
    layer.on('tileerror', function () { f.failed++; });
    // once every tile in view has settled: a frame with nothing but errors isn't available (yet) — skip it
    layer.on('load', function () { if (!f.loaded && f.failed && !f.bad) { f.bad = true; rebuildTimeline(); } });
    layer.addTo(App.map);
    set.frames.push(f);
    return f;
  }

  function buildSat() {
    removeSet(sat);
    var info = pickSat(), now = Date.now(), stepMs = info.step * 60000;
    sat = { frames: [], info: info };
    // newest frame we can expect: ~30 min processing delay; then go back in steps
    var t0 = Math.floor((now - 30 * 60000) / stepMs) * stepMs;
    for (var k = info.frames - 1; k >= 0; k--) {
      var t = t0 - k * stepMs * info.every, layer;
      if (info.kind === 'gibs') {
        layer = L.tileLayer(GIBS + info.layer + '/default/{time}/' + info.tms + '/{z}/{y}/{x}.png', {
          time: iso(new Date(t)), maxNativeZoom: info.z, maxZoom: 20, opacity: 0, pane: 'livePane', attribution: info.attr
        });
      } else {
        layer = L.tileLayer.wms(EUM, {
          layers: info.layer, styles: '', format: 'image/jpeg', transparent: false, version: '1.3.0',
          time: iso(new Date(t)), maxNativeZoom: 7, maxZoom: 20, opacity: 0, pane: 'livePane', attribution: info.attr
        });
      }
      makeFrame(sat, layer, t);
    }
    $('live-sat-info').textContent = info.name + ' · a new picture every ' + info.step + ' min, shown ' + (info.step * info.every) + ' min apart.';
  }

  function buildRadar() {
    removeSet(radar);
    radar = { frames: [], info: null };
    $('live-radar-info').textContent = 'Loading radar frames…';
    fetch('https://api.rainviewer.com/public/weather-maps.json', { cache: 'no-store' }).then(function (r) { return r.json(); }).then(function (d) {
      if (!radar) return;
      (d.radar && d.radar.past || []).forEach(function (fr) {
        var layer = L.tileLayer(d.host + fr.path + '/256/{z}/{x}/{y}/2/1_1.png', { maxNativeZoom: 7, maxZoom: 20, opacity: 0, pane: 'radarPane', attribution: 'Radar: <a href="https://www.rainviewer.com" rel="noopener">RainViewer</a>' });
        makeFrame(radar, layer, fr.time * 1000);
      });
      $('live-radar-info').textContent = radar.frames.length ? 'Rain and snow from ground radar, every 10 min. Blank areas: no rain, or no radar coverage (many deserts and oceans have none).' : 'No radar frames available right now.';
      rebuildTimeline();
    }).catch(function () { $('live-radar-info').textContent = 'Could not load radar (no signal?).'; });
  }

  function buildDaily() {
    if (daily) { App.map.removeLayer(daily); daily = null; }
    var d = new Date(Date.now() - dayOffset * 86400000);
    daily = L.tileLayer(GIBS + 'VIIRS_NOAA20_CorrectedReflectance_TrueColor/default/{time}/GoogleMapsCompatible_Level9/{z}/{y}/{x}.jpeg', {
      time: ymd(d), maxNativeZoom: 9, maxZoom: 20, opacity: opacity, pane: 'liveDailyPane',
      attribution: 'Daily photo: NASA GIBS, NOAA-20 VIIRS'
    }).addTo(App.map);
    $('live-daily-info').textContent = 'NASA true-colour photo for ' + d.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' }) +
      ' (taken around early afternoon local time; ~375 m detail). Black stripes = gaps between satellite passes' + (dayOffset === 0 ? '; if today is empty, pick Yesterday.' : '.');
  }

  function removeSet(set) {
    if (!set) return;
    set.frames.forEach(function (f) { App.map.removeLayer(f.layer); });
    set.frames = [];
  }

  /* One shared timeline: every frame time of the enabled sets, oldest first. */
  function rebuildTimeline() {
    var times = [];
    [sat, radar].forEach(function (set) { if (set) set.frames.forEach(function (f) { if (!f.bad) times.push(f.time); }); });
    times.sort(function (a, b) { return a - b; });
    timeline = times.filter(function (t, i) { return i === 0 || t - times[i - 1] > 60000; });
    if (idx >= timeline.length) idx = Math.max(0, timeline.length - 1);
    $('live-frame').max = Math.max(0, timeline.length - 1);
    show();
  }
  /* For a set, the newest good frame at or before time T (else its first good one). */
  function frameAt(set, T) {
    var best = null;
    set.frames.forEach(function (f) { if (!f.bad && f.time <= T + 60000 && (!best || f.time > best.time)) best = f; });
    if (!best) set.frames.forEach(function (f) { if (!f.bad && !best) best = f; });
    return best;
  }
  function show() {
    var T = timeline[idx];
    [sat, radar].forEach(function (set) {
      if (!set) return;
      var cur = T != null ? frameAt(set, T) : null;
      set.frames.forEach(function (f) { f.layer.setOpacity(f === cur ? opacity : 0); });
      set.current = cur;
    });
    $('live-frame').value = idx;
    var chip = $('live-chip');
    if (T == null) { chip.hidden = !(sat || radar || daily); chip.textContent = daily ? 'NASA daily photo' : 'Loading live pictures…'; $('live-time').textContent = '—'; return; }
    var label = hm(T) + ' · ' + ago(T) + (idx === timeline.length - 1 ? ' (newest)' : '');
    $('live-time').textContent = label;
    chip.hidden = false;
    chip.innerHTML = '<span class="k">●</span> LIVE ' + App.esc((sat ? sat.info.name.split(' (')[0] : 'Radar') + (sat && radar ? ' + radar' : '')) + ' · ' + App.esc(label) + (playing ? ' ▶' : ' ⏸');
  }
  function tick() {
    if (!timeline.length) return;
    idx = (idx + 1) % timeline.length;
    show();
    timer = setTimeout(tick, idx === timeline.length - 1 ? 2000 : 800);
  }
  function play(on) {
    playing = on;
    clearTimeout(timer);
    $('live-play').textContent = on ? 'Pause' : 'Play';
    if (on && !document.hidden) timer = setTimeout(tick, 800);
    show();
  }
  function anyOn() { return !!(sat || radar || daily); }
  function syncFab() { $('fab-live').setAttribute('aria-pressed', anyOn() ? 'true' : 'false'); if (!anyOn()) { $('live-chip').hidden = true; clearTimeout(timer); } }

  function setSat(on) {
    $('live-sat').checked = on;
    if (on) { if (!navigator.onLine) OGSK.toast('Live pictures need signal', { error: true }); buildSat(); idx = sat.frames.length - 1; }
    else { removeSet(sat); sat = null; $('live-sat-info').textContent = ''; }
    rebuildTimeline(); idx = Math.max(0, timeline.length - 1); show(); syncFab(); if (on) play(true);
  }
  function setRadar(on) {
    $('live-radar').checked = on;
    if (on) buildRadar(); else { removeSet(radar); radar = null; $('live-radar-info').textContent = ''; }
    rebuildTimeline(); syncFab(); if (on) play(true);
  }
  function setDaily(on) {
    $('live-daily').checked = on;
    if (on) buildDaily(); else { if (daily) App.map.removeLayer(daily); daily = null; $('live-daily-info').textContent = ''; }
    syncFab(); show();
  }

  App.openLive = function () { App.openDrawer('live'); };

  App.liveInit = function () {
    var p1 = App.map.createPane('liveDailyPane'); p1.style.zIndex = 240; p1.style.pointerEvents = 'none';
    var p2 = App.map.createPane('livePane'); p2.style.zIndex = 250; p2.style.pointerEvents = 'none';
    var p3 = App.map.createPane('radarPane'); p3.style.zIndex = 320; p3.style.pointerEvents = 'none';
    $('fab-live').addEventListener('click', function () {
      if (anyOn()) { setSat(false); setRadar(false); setDaily(false); OGSK.toast('Live pictures off'); return; }
      if (!navigator.onLine) { OGSK.toast('Live pictures need signal — showing the saved map', { error: true }); App.openDrawer('live'); return; }
      setSat(true);
      OGSK.toast('Live satellite: ' + sat.info.name + ' — tap the LIVE strip for radar and options');
      if (App.map.getZoom() > 9) App.map.setZoom(8);   // weather pictures are ~1–3 km per pixel: zoom out to see the clouds
    });
    $('live-chip').addEventListener('click', App.openLive);
    $('live-sat').addEventListener('change', function () { setSat(this.checked); });
    $('live-radar').addEventListener('change', function () { setRadar(this.checked); });
    $('live-daily').addEventListener('change', function () { setDaily(this.checked); });
    App.seg($('live-day'), 'data-d', '0', function (v) { dayOffset = +v; if (daily) buildDaily(); });
    $('live-play').addEventListener('click', function () { play(!playing); });
    $('live-frame').addEventListener('input', function () { play(false); idx = +this.value; show(); });
    $('live-opacity').addEventListener('input', function () {
      opacity = +this.value / 100; if (daily) daily.setOpacity(opacity); show();
    });
    $('live-refresh').addEventListener('click', function () { if (sat) setSat(true); if (radar) setRadar(true); if (daily) buildDaily(); OGSK.toast('Refreshed'); });
    // follow the map: a different region may need a different satellite (or day/night product)
    App.map.on('moveend', function () { if (sat && pickSat().key !== sat.info.key) { buildSat(); rebuildTimeline(); idx = Math.max(0, timeline.length - 1); show(); } });
    document.addEventListener('visibilitychange', function () { if (document.hidden) clearTimeout(timer); else if (playing && anyOn()) play(true); });
    function net() { $('live-offline').hidden = navigator.onLine; }
    window.addEventListener('online', net); window.addEventListener('offline', net); net();
    // refresh every 10 minutes while on
    setInterval(function () { if (!document.hidden && navigator.onLine) { if (sat) buildSat(); if (radar) buildRadar(); rebuildTimeline(); } }, 10 * 60000);
  };
})();
