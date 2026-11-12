/* =====================================================================
   Triangulation (resection): estimate your position from compass bearings
   to 2–3 landmarks with known positions. Draws each back-bearing line, the
   "triangle of error" for 3 bearings, and the estimated fix.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var rows = [{}, {}], layer = null, lastFix = null, pickIdx = null;

  function rowHtml(r, i) {
    var wps = App.wp.all().slice().sort(function (a, b) { return (a.cat === 'landmark' ? 0 : 1) - (b.cat === 'landmark' ? 0 : 1) || a.name.localeCompare(b.name); });
    return '<div class="tri-row" data-i="' + i + '"><h4>Landmark ' + (i + 1) + (i === 2 ? ' <button class="btn" type="button" data-rm style="min-height:36px;float:right">Remove</button>' : '') + '</h4>' +
      '<div class="field"><label for="tri-wp-' + i + '">From my waypoints</label><select id="tri-wp-' + i + '" data-wp><option value="">— choose —</option>' +
      wps.map(function (w) { return '<option value="' + w.id + '"' + (r.wpId === w.id ? ' selected' : '') + '>' + App.esc(w.name) + ' (' + OGStore.WAYPOINT_CATS[w.cat].label + ')</option>'; }).join('') + '</select></div>' +
      '<div class="field"><label for="tri-ll-' + i + '">…or its coordinates</label><input type="text" id="tri-ll-' + i + '" data-ll autocomplete="off" spellcheck="false" value="' +
      (r.lat != null ? r.lat.toFixed(6) + ', ' + r.lon.toFixed(6) : '') + '" placeholder="lat, lon or MGRS"></div>' +
      '<div class="row"><button class="btn" type="button" data-pick>Tap on map</button><button class="btn" type="button" data-cross>Use crosshair</button></div>' +
      '<div class="grid" style="margin-top:8px"><div class="field" style="margin:0"><label for="tri-b-' + i + '">Bearing to it (°)</label>' +
      '<input type="number" id="tri-b-' + i + '" data-brg min="0" max="360" step="0.5" inputmode="decimal" value="' + (r.bearing != null ? r.bearing : '') + '"></div>' +
      '<div style="align-self:end"><button class="btn block" type="button" data-compass>Use compass</button></div></div></div>';
  }
  function paintRows() {
    $('tri-rows').innerHTML = rows.map(rowHtml).join('');
    $('tri-add').hidden = rows.length >= 3;
    var unknown = OGCompass.declMode === 'auto' && OGCompass.autoDecl == null;
    $('tri-decl').innerHTML = 'Declination used for magnetic bearings: <strong>' + App.esc(OGCompass.declLabel()) + '</strong>' +
      (unknown ? ' — get a GPS fix or move the map to your area first; a wrong declination puts the fix off by ~17 m per km for every degree.' : '');
  }
  function save() { OGStore.kvSet('map.tri', { rows: rows, type: $('tri-type').value }); }

  function setRowLL(i, lat, lon, name) {
    rows[i].lat = lat; rows[i].lon = lon; rows[i].name = name || null;
    paintRows(); save();
  }

  function solve() {
    var mag = $('tri-type').value === 'mag';
    var obs = [];
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i];
      if (r.lat == null || r.bearing == null || isNaN(r.bearing)) continue;
      obs.push({ lat: r.lat, lon: r.lon, bearing: mag ? App.toTrue(r.bearing) : OGGeo.norm360(r.bearing), name: r.name || 'Landmark ' + (i + 1) });
    }
    layer.clearLayers(); lastFix = null;
    if (obs.length < 2) { $('tri-out').innerHTML = '<div class="callout warn"><p>Enter at least two landmarks, each with a position and a bearing.</p></div>'; return; }
    var res;
    try { res = OGGeo.resection(obs); }
    catch (e) { $('tri-out').innerHTML = '<div class="callout danger"><p>' + App.esc(e.message) + '</p></div>'; return; }
    lastFix = res;
    var maxD = 0;
    obs.forEach(function (o) { maxD = Math.max(maxD, OGGeo.distance(o.lat, o.lon, res.lat, res.lon)); });
    obs.forEach(function (o) {
      var len = Math.max(1000, maxD * 1.4);
      var end = OGGeo.destination(o.lat, o.lon, OGGeo.norm360(o.bearing + 180), len);
      L.polyline([[o.lat, o.lon], end], { color: '#ffb000', weight: 3, dashArray: '8 6', interactive: false }).addTo(layer);
      L.marker([o.lat, o.lon], { icon: L.divIcon({ className: '', html: '<div class="tri-mark"></div>', iconSize: [22, 22], iconAnchor: [11, 11] }), title: o.name }).addTo(layer)
        .bindTooltip(App.esc(o.name) + ' · ' + Math.round(o.bearing) + '° T', { direction: 'top' });
    });
    var triSize = 0;
    if (res.triangle) {
      L.polygon(res.triangle, { color: '#ff2d55', weight: 2, fillOpacity: 0.25, interactive: false }).addTo(layer);
      for (var k = 0; k < 3; k++) triSize = Math.max(triSize, OGGeo.distance(res.triangle[k][0], res.triangle[k][1], res.triangle[(k + 1) % 3][0], res.triangle[(k + 1) % 3][1]));
    }
    L.marker([res.lat, res.lon], { icon: L.divIcon({ className: '', html: '<div class="fix-mark"></div>', iconSize: [26, 26], iconAnchor: [13, 13] }), title: 'Estimated position' }).addTo(layer);
    var html = '<div class="card"><h3>Estimated position</h3><div class="bigread" style="font-size:1.4rem">' + App.esc(App.fmtPos(res.lat, res.lon)) + '</div>' +
      '<p><strong>MGRS</strong> ' + App.esc(App.mgrs(res.lat, res.lon)) + '</p>' +
      (res.triangle ? '<p>Triangle of error: <strong>' + App.fmtDist(triSize) + '</strong> across. ' + (triSize > maxD * 0.1 ? 'That is large — re-take your bearings carefully.' : 'Good agreement.') + ' You are most likely inside the red triangle.</p>'
        : '<p>With two bearings there is no error check — take a third bearing if you can.</p>');
    var f = App.gps.fix;
    if (f) html += '<p class="muted">GPS says you are ' + App.fmtDist(OGGeo.distance(f.lat, f.lon, res.lat, res.lon)) + ' from this fix.</p>';
    res.warnings.forEach(function (w) { html += '<div class="callout warn"><p>' + App.esc(w) + '</p></div>'; });
    html += '<div class="row"><button class="btn primary" type="button" id="tri-save">Save as waypoint</button><button class="btn" type="button" id="tri-zoom">Show on map</button></div>' +
      '<p class="help">Each degree of bearing error moves a line about 17 m per kilometre of distance. Bearings taken with a handheld compass are usually good to ±2–3°.</p></div>';
    $('tri-out').innerHTML = html;
    $('tri-save').onclick = function () { App.wp.edit(null, { lat: res.lat, lon: res.lon }); };
    $('tri-zoom').onclick = function () { App.map.fitBounds(layer.getBounds ? L.featureGroup(layer.getLayers()).getBounds().pad(0.15) : null); if (innerWidth < 800) App.closeDrawer(); };
    App.map.fitBounds(L.featureGroup(layer.getLayers()).getBounds().pad(0.15));
  }

  /* map picking mode (shared helper) */
  App.pickPoint = function (msg, cb) {
    App.mode = 'pick';
    App._pickCb = cb;
    $('pick-msg').textContent = msg;
    $('panel-pick').hidden = false;
    App.closeDrawer();
  };
  App.pickCancel = function () { App.mode = 'normal'; App._pickCb = null; $('panel-pick').hidden = true; };
  function pickDone(ll) {
    var cb = App._pickCb; App.pickCancel();
    if (cb) cb(ll);
  }

  App.triInit = function () {
    layer = L.layerGroup().addTo(App.map);
    App.map.on('click', function (e) { if (App.mode === 'pick') pickDone(e.latlng); });
    $('pick-center').addEventListener('click', function () { pickDone(App.map.getCenter()); });
    $('pick-cancel').addEventListener('click', function () { App.pickCancel(); App.openDrawer('triangulate'); });
    $('tri-add').addEventListener('click', function () { if (rows.length < 3) { rows.push({}); paintRows(); save(); } });
    $('tri-clear').addEventListener('click', function () { rows = [{}, {}]; layer.clearLayers(); $('tri-out').innerHTML = ''; paintRows(); save(); });
    $('tri-solve').addEventListener('click', solve);
    $('tri-type').addEventListener('change', save);
    $('tri-rows').addEventListener('change', function (e) {
      var row = e.target.closest('[data-i]'); if (!row) return;
      var i = +row.getAttribute('data-i');
      if (e.target.hasAttribute('data-wp')) {
        var w = App.wp.get(e.target.value);
        if (w) { rows[i].wpId = w.id; setRowLL(i, w.lat, w.lon, w.name); }
      } else if (e.target.hasAttribute('data-ll')) {
        var p = OGGeo.parseCoords(e.target.value);
        if (p) { rows[i].wpId = null; setRowLL(i, p[0], p[1]); } else OGSK.toast('Coordinates not recognised', { error: true });
      } else if (e.target.hasAttribute('data-brg')) {
        var v = parseFloat(e.target.value);
        rows[i].bearing = isNaN(v) ? null : OGGeo.norm360(v); save();
      }
    });
    $('tri-rows').addEventListener('click', function (e) {
      var row = e.target.closest('[data-i]'); if (!row) return;
      var i = +row.getAttribute('data-i');
      if (e.target.closest('[data-pick]')) {
        App.pickPoint('Tap landmark ' + (i + 1) + ' on the map', function (ll) { rows[i].wpId = null; setRowLL(i, ll.lat, ll.lng); App.openDrawer('triangulate'); });
      } else if (e.target.closest('[data-cross]')) {
        var c = App.map.getCenter(); rows[i].wpId = null; setRowLL(i, c.lat, c.lng);
      } else if (e.target.closest('[data-compass]')) {
        var h = App.heading;
        if (h.deg == null || h.src !== 'compass') { App.enableCompass(true); OGSK.toast('No compass reading yet — point the top of the phone at the landmark, hold it flat, and try again', { error: true }); return; }
        var val = $('tri-type').value === 'mag' ? h.mag : h.deg;
        rows[i].bearing = Math.round(val * 2) / 2; paintRows(); save();
        OGSK.toast('Bearing ' + rows[i].bearing + '° captured');
      } else if (e.target.closest('[data-rm]')) {
        rows.splice(2, 1); paintRows(); save();
      }
    });
    App.on('tab', function (t) { if (t === 'triangulate') paintRows(); });
    App.on('settings', function (e) { if (e.key === 'declination' && App.drawerOpen('triangulate')) paintRows(); });
    return OGStore.kvGet('map.tri', null).then(function (s) {
      if (s && Array.isArray(s.rows) && s.rows.length >= 2) rows = s.rows.slice(0, 3);
      if (s && s.type) $('tri-type').value = s.type;
    });
  };
})();
