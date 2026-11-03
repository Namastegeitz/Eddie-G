/* =====================================================================
   Tracks: record a GPS breadcrumb trail (drawn live, running distance),
   then save / name / list / show / hide / export / delete. The track being
   recorded is checkpointed to IndexedDB every few points, so a reload or a
   crash doesn't lose it.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var COLORS = ['#ff3b30', '#00c7be', '#ff9f0a', '#bf5af2', '#34c759', '#0a84ff', '#ff375f', '#ffd60a'];
  var rec = null, liveLine = null, savedLayer = null, tracks = [], tick = null, dirty = 0;

  function stats(points) {
    var dist = 0, gain = 0, lastAlt = null;
    for (var i = 1; i < points.length; i++) dist += OGGeo.distance(points[i - 1][0], points[i - 1][1], points[i][0], points[i][1]);
    points.forEach(function (p) {
      if (p[2] == null) return;
      if (lastAlt == null) { lastAlt = p[2]; return; }
      var d = p[2] - lastAlt;
      if (Math.abs(d) >= 3) { if (d > 0) gain += d; lastAlt = p[2]; }   // 3 m hysteresis vs GPS altitude noise
    });
    var dur = points.length > 1 ? points[points.length - 1][3] - points[0][3] : 0;
    return { dist: dist, gain: gain, dur: dur };
  }
  App.trackStats = stats;

  /* ---------------- recording ---------------- */
  function startRec() {
    if (rec) return;
    rec = { id: OGStore.uid(), points: [], startT: Date.now(), paused: false };
    App.gpsStart(true);
    if (App.settings.wakeLock) OGSK.wakeLock.request();
    showPanel();
    var f = App.gps.fix;
    if (f && Date.now() - f.t < 15000) addPoint(f);
    checkpoint();
    OGSK.toast('Recording. Keep the screen on for a continuous track.');
  }
  function addPoint(f) {
    if (!rec || rec.paused) return;
    if (f.acc > (+App.settings.minAcc || 50)) return;
    var pts = rec.points, last = pts[pts.length - 1];
    if (last) {
      var d = OGGeo.distance(last[0], last[1], f.lat, f.lon);
      if (d < Math.max(5, f.acc * 0.5)) return;
    }
    pts.push([+f.lat.toFixed(7), +f.lon.toFixed(7), f.alt != null ? Math.round(f.alt * 10) / 10 : null, f.t, Math.round(f.acc)]);
    var ll = pts.map(function (p) { return [p[0], p[1]]; });
    if (!liveLine) liveLine = L.polyline(ll, { color: '#ff3b30', weight: 5, opacity: 0.95, interactive: false }).addTo(App.map);
    else liveLine.addLatLng([f.lat, f.lon]);
    paintPanel();
    if (++dirty >= 3) checkpoint();
  }
  function checkpoint() { dirty = 0; if (rec) OGStore.kvSet('track.current', rec).catch(function () {}); }
  function showPanel() {
    $('panel-track').hidden = false;
    $('fab-track').setAttribute('aria-pressed', 'true');
    clearInterval(tick); tick = setInterval(paintPanel, 1000);
    paintPanel();
  }
  function hidePanel() {
    $('panel-track').hidden = true;
    $('fab-track').setAttribute('aria-pressed', 'false');
    clearInterval(tick);
  }
  function paintPanel() {
    if (!rec) return;
    var s = stats(rec.points);
    $('trk-dist').textContent = App.fmtDist(s.dist);
    $('trk-time').textContent = OGGeo.fmtDuration(Date.now() - rec.startT);
    $('trk-pts').textContent = rec.points.length;
    $('trk-state').textContent = rec.paused ? 'paused' : 'live';
    $('trk-state').className = 'tag ' + (rec.paused ? 'warn' : 'danger');
    $('trk-pause').textContent = rec.paused ? 'Resume' : 'Pause';
  }
  function endRec(keep) {
    if (!rec) return Promise.resolve();
    var r = rec;
    if (!keep) {
      return App.ask({ title: 'Discard this track?', html: '<p>' + r.points.length + ' points will be lost.</p>', ok: 'Discard', danger: true }).then(function (ok) {
        if (ok) finish();
      });
    }
    if (r.points.length < 2) {
      return App.ask({ title: 'Not enough points', html: '<p>The track has fewer than 2 GPS points (you may not have moved, or GPS accuracy was poor). Discard it?</p>', ok: 'Discard', danger: true })
        .then(function (ok) { if (ok) finish(); });
    }
    var def = 'Track ' + new Date(r.startT).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    return App.ask({ title: 'Save track', prompt: 'Name', value: def, ok: 'Save' }).then(function (name) {
      if (name === null) return;
      var s = stats(r.points);
      var t = { id: r.id, name: name || def, points: r.points, dist: s.dist, created: r.startT, updated: Date.now(), color: COLORS[tracks.length % COLORS.length] };
      return OGStore.put('tracks', t).then(function () { OGSK.toast('Track saved: ' + App.fmtDist(s.dist)); finish(); return reload(); });
    });
    function finish() {
      rec = null;
      OGStore.kvDel('track.current');
      if (liveLine) { App.map.removeLayer(liveLine); liveLine = null; }
      if (App.settings.wakeLock) OGSK.wakeLock.release();
      hidePanel();
    }
  }

  /* ---------------- saved tracks ---------------- */
  function reload() {
    return OGStore.all('tracks').then(function (all) {
      tracks = (all || []).sort(function (a, b) { return (b.created || 0) - (a.created || 0); });
      paintSaved(); paintList();
      return tracks;
    });
  }
  App.tracks = { reload: reload, all: function () { return tracks; } };
  function paintSaved() {
    savedLayer.clearLayers();
    if (!App.settings.showTracks) return;
    tracks.forEach(function (t) {
      if (t.hidden || !t.points || t.points.length < 2) return;
      var pl = L.polyline(t.points.map(function (p) { return [p[0], p[1]]; }), { color: t.color || '#00c7be', weight: 4, opacity: 0.85 });
      pl.bindPopup(function () {
        var s = stats(t.points);
        return '<strong>' + App.esc(t.name) + '</strong><br>' + new Date(t.created).toLocaleString() + '<br>' + App.fmtDist(s.dist) + ' · ' + OGGeo.fmtDuration(s.dur) +
          (s.gain ? ' · ↑' + App.fmtAlt(s.gain) : '');
      });
      pl.addTo(savedLayer);
    });
  }
  function paintList() {
    var ul = $('trk-list'); if (!ul) return;
    if (!tracks.length) { ul.innerHTML = '<li class="empty">No saved tracks yet.</li>'; return; }
    ul.innerHTML = tracks.map(function (t) {
      var s = stats(t.points || []);
      return '<li style="flex-wrap:wrap"><span class="swatch" style="background:' + (t.color || '#00c7be') + '"></span>' +
        '<button class="li-main" type="button" data-zoom="' + t.id + '"><strong>' + App.esc(t.name) + '</strong><small>' +
        new Date(t.created).toLocaleDateString() + ' · ' + App.fmtDist(s.dist) + ' · ' + OGGeo.fmtDuration(s.dur) + (s.gain ? ' · ↑' + App.fmtAlt(s.gain) : '') + '</small></button>' +
        '<div class="row" style="width:100%;justify-content:flex-end">' +
        '<button class="btn" type="button" data-vis="' + t.id + '">' + (t.hidden ? 'Show' : 'Hide') + '</button>' +
        '<button class="btn" type="button" data-gpx="' + t.id + '">GPX</button>' +
        '<button class="btn" type="button" data-ren="' + t.id + '">Rename</button>' +
        '<button class="btn danger" type="button" data-del="' + t.id + '">Delete</button></div></li>';
    }).join('');
  }
  function byId(id) { return tracks.filter(function (t) { return t.id === id; })[0]; }

  App.tracksInit = function () {
    savedLayer = L.layerGroup().addTo(App.map);
    $('fab-track').addEventListener('click', function () {
      if (!rec) startRec();
      else { $('panel-track').hidden = false; OGSK.toast('Already recording — use the panel to pause or save'); }
    });
    $('trk-start2').addEventListener('click', function () { startRec(); App.closeDrawer(); });
    $('trk-pause').addEventListener('click', function () {
      if (!rec) return;
      rec.paused = !rec.paused; checkpoint(); paintPanel();
    });
    $('trk-save').addEventListener('click', function () { endRec(true); });
    $('trk-discard').addEventListener('click', function () { endRec(false); });
    App.on('gps', addPoint);
    $('ov-tracks').checked = App.settings.showTracks !== false;
    $('ov-tracks').addEventListener('change', function () { App.set('showTracks', this.checked); paintSaved(); });
    App.on('settings', function (e) { if (e.key === 'units') { paintList(); paintPanel(); } });
    $('trk-list').addEventListener('click', function (e) {
      var b = e.target.closest('button'); if (!b) return;
      var id = b.getAttribute('data-zoom') || b.getAttribute('data-vis') || b.getAttribute('data-gpx') || b.getAttribute('data-ren') || b.getAttribute('data-del');
      var t = byId(id); if (!t) return;
      if (b.hasAttribute('data-zoom')) {
        if (t.points.length) { App.map.fitBounds(L.latLngBounds(t.points.map(function (p) { return [p[0], p[1]]; })).pad(0.1)); if (innerWidth < 800) App.closeDrawer(); }
      } else if (b.hasAttribute('data-vis')) {
        t.hidden = !t.hidden; OGStore.put('tracks', t).then(reload);
      } else if (b.hasAttribute('data-gpx')) {
        App.data.downloadGpx([], [t], t.name);
      } else if (b.hasAttribute('data-ren')) {
        App.ask({ title: 'Rename track', prompt: 'Name', value: t.name, ok: 'Save' }).then(function (n) { if (n) { t.name = n; t.updated = Date.now(); OGStore.put('tracks', t).then(reload); } });
      } else if (b.hasAttribute('data-del')) {
        App.ask({ title: 'Delete “' + t.name + '”?', ok: 'Delete', danger: true }).then(function (ok) { if (ok) OGStore.del('tracks', t.id).then(reload); });
      }
    });
    // restore an unsaved recording
    return OGStore.kvGet('track.current', null).then(function (cur) {
      if (cur && cur.points) {
        rec = cur; rec.paused = true;
        if (cur.points.length) liveLine = L.polyline(cur.points.map(function (p) { return [p[0], p[1]]; }), { color: '#ff3b30', weight: 5, interactive: false }).addTo(App.map);
        showPanel();
        App.banner('An unsaved track was restored (paused). Resume it, or Stop &amp; save.');
      }
      return reload();
    });
  };
})();
