/* =====================================================================
   Waypoints (categorised pins, stored in IndexedDB) and "Navigate to"
   with live distance / bearing / relative arrow / ETA and a guide line.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var CATS = OGStore.WAYPOINT_CATS;
  var layer = null, markers = {}, list = [], editing = null, sortBy = 'dist';

  App.wp = {
    all: function () { return list; },
    get: function (id) { return list.filter(function (w) { return w.id === id; })[0]; }
  };

  /* ---------------- markers ---------------- */
  function icon(w, isTarget) {
    var c = CATS[w.cat] || CATS.custom;
    return L.divIcon({
      className: '', iconSize: [34, 34], iconAnchor: [17, 17], popupAnchor: [0, -16],
      html: '<div class="wp-icon' + (isTarget ? ' wp-target' : '') + '"><div class="wp-pin" style="background:' + c.color + '"><svg viewBox="0 0 24 24" aria-hidden="true">' +
        (App.CAT_ICONS[w.cat] || App.CAT_ICONS.custom) + '</svg></div><div class="wp-label">' + App.esc(w.name) + '</div></div>'
    });
  }
  function popupHtml(w) {
    var c = CATS[w.cat] || CATS.custom, here = App.here();
    var d = OGGeo.distance(here.lat, here.lon, w.lat, w.lon), b = OGGeo.bearing(here.lat, here.lon, w.lat, w.lon);
    return '<strong style="font-size:1.05rem">' + App.esc(w.name) + '</strong><br><span class="muted">' + c.label + '</span>' +
      '<div style="margin:6px 0">' + App.esc(App.fmtPos(w.lat, w.lon)) + '<br>' + App.esc(App.mgrs(w.lat, w.lon)) + '</div>' +
      (w.note ? '<div style="margin:6px 0;white-space:pre-wrap">' + App.esc(w.note) + '</div>' : '') +
      '<div class="muted">' + App.fmtDist(d) + ' · ' + App.fmtBrg(b) + ' from ' + (here.src === 'gps' ? 'you' : 'map centre') + '</div>' +
      '<div class="row" style="margin-top:8px"><button class="btn primary" type="button" data-wp-nav="' + w.id + '">Navigate</button>' +
      '<button class="btn" type="button" data-wp-edit="' + w.id + '">Edit</button><button class="btn" type="button" data-wp-qr="' + w.id + '">QR</button></div>';
  }
  function paintMarkers() {
    layer.clearLayers(); markers = {};
    var tgt = App.nav.target && App.nav.target.id;
    list.forEach(function (w) {
      var m = L.marker([w.lat, w.lon], { icon: icon(w, w.id === tgt), title: w.name, riseOnHover: true });
      m.bindPopup(function () { return popupHtml(w); }, { maxWidth: 300 });
      m.addTo(layer);
      markers[w.id] = m;
    });
  }
  function reload() {
    return OGStore.all('waypoints').then(function (all) {
      list = all || [];
      paintMarkers(); paintList();
      App.emit('waypoints', list);
      return list;
    });
  }
  App.wp.reload = reload;
  App.wp.focus = function (id, openPopup) {
    var w = App.wp.get(id); if (!w) return false;
    App.map.setView([w.lat, w.lon], Math.max(App.map.getZoom(), 14));
    if (openPopup !== false && markers[id]) setTimeout(function () { markers[id].openPopup(); }, 300);
    return true;
  };

  /* ---------------- editor ---------------- */
  function buildCatGrid() {
    $('wp-cats').innerHTML = Object.keys(CATS).map(function (k) {
      return '<label><input type="radio" name="wp-cat" value="' + k + '">' + App.catIcon(k) + '<span>' + CATS[k].label + '</span></label>';
    }).join('');
  }
  function setCoordsField(lat, lon) {
    $('wp-coords').value = lat.toFixed(6) + ', ' + lon.toFixed(6);
    checkCoords();
  }
  function checkCoords() {
    var p = OGGeo.parseCoords($('wp-coords').value);
    $('wp-coords-msg').textContent = p ? 'MGRS ' + App.mgrs(p[0], p[1]) + ' · ' + OGGeo.dms(p[0], true) + ' ' + OGGeo.dms(p[1], false) : 'Not recognised — use e.g. 40.7128, -74.0060 or an MGRS grid';
    return p;
  }
  function nextName(cat) {
    var base = (CATS[cat] || CATS.custom).label.split(' /')[0];
    var n = list.filter(function (w) { return w.cat === cat; }).length + 1;
    return base + ' ' + n;
  }
  App.wp.edit = function (w, at) {
    editing = w ? Object.assign({}, w) : null;
    var dlg = $('dlg-wp');
    $('wp-title').textContent = w ? 'Edit waypoint' : 'New waypoint';
    var cat = w ? w.cat : (App._lastCat || 'water');
    var r = dlg.querySelector('input[name="wp-cat"][value="' + cat + '"]'); if (r) r.checked = true;
    $('wp-name').value = w ? w.name : '';
    $('wp-name').placeholder = nextName(cat);
    $('wp-note').value = w ? (w.note || '') : '';
    $('wp-del').hidden = !w; $('wp-nav').hidden = !w; $('wp-qr').hidden = !w;
    var whereBtns = $('wp-where').querySelectorAll('[data-where]');
    whereBtns[0].textContent = w ? 'Move to crosshair' : 'At crosshair';
    whereBtns[1].textContent = w ? 'Move to my GPS' : 'At my GPS';
    if (w) setCoordsField(w.lat, w.lon);
    else if (at) setCoordsField(at.lat, at.lng != null ? at.lng : at.lon);
    else pickWhere(App.gps.fix && Date.now() - App.gps.fix.t < 120000 ? 'gps' : 'center');
    paintWhere(w || at ? null : (App.gps.fix ? 'gps' : 'center'));
    dlg.showModal();
  };
  function paintWhere(v) { $('wp-where').querySelectorAll('[data-where]').forEach(function (b) { b.setAttribute('aria-pressed', b.getAttribute('data-where') === v ? 'true' : 'false'); }); }
  function pickWhere(v) {
    if (v === 'gps') {
      var f = App.gps.fix;
      if (!f) { OGSK.toast('No GPS fix yet — using the crosshair', { error: true }); v = 'center'; }
      else { setCoordsField(f.lat, f.lon); paintWhere('gps'); return; }
    }
    var c = App.map.getCenter(); setCoordsField(c.lat, c.lng); paintWhere('center');
  }
  function save(e) {
    e.preventDefault();
    var p = checkCoords();
    if (!p) { $('wp-coords').focus(); return; }
    var cat = ($('dlg-wp').querySelector('input[name="wp-cat"]:checked') || {}).value || 'custom';
    App._lastCat = cat;
    var now = Date.now();
    var w = editing || { id: OGStore.uid(), created: now };
    w.name = $('wp-name').value.trim() || nextName(cat);
    w.cat = cat; w.lat = p[0]; w.lon = p[1]; w.note = $('wp-note').value.trim(); w.updated = now;
    if (!editing && App.gps.fix && Math.abs(App.gps.fix.lat - w.lat) < 1e-7 && Math.abs(App.gps.fix.lon - w.lon) < 1e-7 && App.gps.fix.alt != null) w.alt = App.gps.fix.alt;
    OGStore.put('waypoints', w).then(function () {
      $('dlg-wp').close();
      OGSK.toast('Saved “' + w.name + '”');
      return reload();
    }).then(function () {
      if (App.nav.target && App.nav.target.id === w.id) App.nav.start(w);
    }).catch(function (err) { OGSK.toast('Could not save: ' + err.message, { error: true }); });
  }
  function del() {
    if (!editing) return;
    var w = editing;
    App.ask({ title: 'Delete “' + w.name + '”?', html: '<p>This removes the waypoint from this device.</p>', ok: 'Delete', danger: true }).then(function (ok) {
      if (!ok) return;
      OGStore.del('waypoints', w.id).then(function () {
        $('dlg-wp').close();
        if (App.nav.target && App.nav.target.id === w.id) App.nav.stop();
        OGSK.toast('Deleted'); reload();
      });
    });
  }

  /* ---------------- list ---------------- */
  function paintList() {
    var ul = $('wp-list'); if (!ul) return;
    var q = ($('wp-filter').value || '').toLowerCase().trim();
    var here = App.here();
    var rows = list.map(function (w) {
      return { w: w, d: OGGeo.distance(here.lat, here.lon, w.lat, w.lon), b: OGGeo.bearing(here.lat, here.lon, w.lat, w.lon) };
    }).filter(function (r) {
      if (!q) return true;
      return (r.w.name + ' ' + (r.w.note || '') + ' ' + (CATS[r.w.cat] || CATS.custom).label).toLowerCase().indexOf(q) >= 0;
    });
    rows.sort(function (a, b) {
      if (sortBy === 'name') return a.w.name.localeCompare(b.w.name);
      if (sortBy === 'new') return (b.w.created || 0) - (a.w.created || 0);
      return a.d - b.d;
    });
    if (!rows.length) { ul.innerHTML = '<li class="empty">' + (list.length ? 'No matches.' : 'No waypoints yet. Use “+ Pin” to mark water, camp, hazards and rally points.') + '</li>'; return; }
    ul.innerHTML = rows.map(function (r) {
      var c = CATS[r.w.cat] || CATS.custom;
      return '<li>' + App.catIcon(r.w.cat) + '<button class="li-main" type="button" data-focus="' + r.w.id + '"><strong>' + App.esc(r.w.name) + '</strong><small>' +
        c.label + ' · ' + App.fmtDist(r.d) + ' ' + OGGeo.cardinal(r.b) + (here.src === 'gps' ? '' : ' (from centre)') + '</small></button>' +
        '<button class="btn" type="button" data-nav="' + r.w.id + '" aria-label="Navigate to ' + App.esc(r.w.name) + '">Go</button>' +
        '<button class="btn" type="button" data-edit="' + r.w.id + '" aria-label="Edit ' + App.esc(r.w.name) + '">Edit</button></li>';
    }).join('');
  }
  App.wp.paintList = paintList;

  /* ---------------- navigate to ---------------- */
  var navLine = null, arrived = false;
  App.nav = {
    target: null,
    start: function (t) {
      App.nav.target = { id: t.id || null, name: t.name || 'Target', lat: t.lat, lon: t.lon };
      arrived = false;
      OGStore.kvSet('map.nav', App.nav.target);
      $('panel-nav').hidden = false;
      $('nav-name').textContent = App.nav.target.name;
      if (App.settings.wakeLock && !App._navWake) { OGSK.wakeLock.request(); App._navWake = true; }
      if (!App.gps.watching) App.gpsStart(true);
      paintMarkers();
      App.nav.update();
      var f = App.gps.fix;
      if (f) App.map.fitBounds(L.latLngBounds([[f.lat, f.lon], [t.lat, t.lon]]).pad(0.25), { maxZoom: 16 });
      else App.map.setView([t.lat, t.lon], Math.max(App.map.getZoom(), 13));
    },
    stop: function () {
      App.nav.target = null;
      OGStore.kvDel('map.nav');
      $('panel-nav').hidden = true;
      if (navLine) { App.map.removeLayer(navLine); navLine = null; }
      if (App._navWake) { OGSK.wakeLock.release(); App._navWake = false; }
      paintMarkers();
    },
    update: function () {
      var t = App.nav.target; if (!t) return;
      var f = App.gps.fix, fresh = f && Date.now() - f.t < 60000;
      var from = fresh ? { lat: f.lat, lon: f.lon } : (function () { var c = App.map.getCenter(); return { lat: c.lat, lon: c.lng }; })();
      var d = OGGeo.distance(from.lat, from.lon, t.lat, t.lon), b = OGGeo.bearing(from.lat, from.lon, t.lat, t.lon);
      $('nav-dist').textContent = App.fmtDist(d);
      $('nav-brg').textContent = App.fmtBrg(b);
      $('nav-from').textContent = fresh ? '' : '(from map centre — no GPS fix)';
      var h = App.heading.deg;
      var rot = h != null && fresh ? b - h : b;
      $('nav-arrow').style.transform = 'rotate(' + rot + 'deg)';
      $('nav-arrow').parentNode.setAttribute('aria-label', h != null ? 'Turn ' + Math.round(OGGeo.norm180(b - h)) + ' degrees' : 'Bearing from north');
      var eta = '';
      if (fresh && f.speed && f.speed > 0.3) eta = 'ETA ' + OGGeo.fmtDuration(d / f.speed * 1000) + ' at ' + App.fmtSpeed(f.speed);
      $('nav-eta').textContent = (h != null && fresh ? 'Arrow = turn this way (relative to your heading)' : 'Arrow is north-up (no heading yet)') + (eta ? ' · ' + eta : '');
      var pts = [[from.lat, from.lon], [t.lat, t.lon]];
      if (!navLine) navLine = L.polyline(pts, { color: '#ffb000', weight: 4, dashArray: '10 8', opacity: 0.9, interactive: false }).addTo(App.map);
      else navLine.setLatLngs(pts);
      if (fresh && !arrived && d < Math.max(12, Math.min(f.acc || 0, 40))) {
        arrived = true;
        OGSK.toast('Arrived at ' + t.name);
        if (navigator.vibrate) navigator.vibrate([200, 100, 200]);
      }
    }
  };

  /* ---------------- long-press to drop a pin ---------------- */
  function initLongPress() {
    var el = App.map.getContainer(), timer = null, start = null, lastFire = 0;
    function cancel() { clearTimeout(timer); timer = null; }
    el.addEventListener('pointerdown', function (e) {
      if (!e.isPrimary || App.mode !== 'normal' || e.target.closest('.leaflet-marker-icon, .leaflet-control, .leaflet-popup')) return;
      start = { x: e.clientX, y: e.clientY };
      cancel();
      timer = setTimeout(function () {
        lastFire = Date.now();
        var r = el.getBoundingClientRect();
        var ll = App.map.containerPointToLatLng([start.x - r.left, start.y - r.top]);
        if (navigator.vibrate) navigator.vibrate(40);
        App.wp.edit(null, ll);
      }, 650);
    });
    el.addEventListener('pointermove', function (e) { if (timer && start && Math.hypot(e.clientX - start.x, e.clientY - start.y) > 10) cancel(); });
    ['pointerup', 'pointercancel', 'pointerleave'].forEach(function (t) { el.addEventListener(t, cancel); });
    App.map.on('zoomstart movestart', cancel);
    App.map.on('contextmenu', function (e) {   // desktop right-click (and Android, de-duplicated)
      if (App.mode !== 'normal' || Date.now() - lastFire < 1000) return;
      App.wp.edit(null, e.latlng);
    });
  }

  /* ---------------- init ---------------- */
  App.wp.init = function () {
    layer = L.layerGroup().addTo(App.map);
    buildCatGrid();
    $('wp-form').addEventListener('submit', save);
    $('wp-cancel').addEventListener('click', function () { $('dlg-wp').close(); });
    $('wp-del').addEventListener('click', del);
    $('wp-nav').addEventListener('click', function () { var w = editing; $('dlg-wp').close(); if (w) { App.nav.start(w); App.closeDrawer(); } });
    $('wp-qr').addEventListener('click', function () { var w = editing; $('dlg-wp').close(); if (w) App.share.showQR({ lat: w.lat, lon: w.lon, name: w.name }); });
    $('wp-coords').addEventListener('input', checkCoords);
    $('wp-cats').addEventListener('change', function (e) { $('wp-name').placeholder = nextName(e.target.value); });
    $('wp-where').addEventListener('click', function (e) { var b = e.target.closest('[data-where]'); if (b) pickWhere(b.getAttribute('data-where')); });
    $('fab-pin').addEventListener('click', function () { App.wp.edit(null); });
    $('wp-add-center').addEventListener('click', function () { var c = App.map.getCenter(); App.wp.edit(null, c); });
    $('wp-add-gps').addEventListener('click', function () {
      var f = App.gps.fix; if (!f) { OGSK.toast('No GPS fix yet', { error: true }); return; }
      App.wp.edit(null, { lat: f.lat, lon: f.lon });
    });
    $('wp-filter').addEventListener('input', paintList);
    App.seg($('wp-sort'), 'data-sort', sortBy, function (v) { sortBy = v; paintList(); });
    $('wp-list').addEventListener('click', function (e) {
      var f = e.target.closest('[data-focus]'), n = e.target.closest('[data-nav]'), ed = e.target.closest('[data-edit]');
      if (f) { App.wp.focus(f.getAttribute('data-focus')); if (innerWidth < 800) App.closeDrawer(); }
      if (n) { App.nav.start(App.wp.get(n.getAttribute('data-nav'))); App.closeDrawer(); }
      if (ed) App.wp.edit(App.wp.get(ed.getAttribute('data-edit')));
    });
    // buttons inside popups
    App.map.getContainer().addEventListener('click', function (e) {
      var n = e.target.closest('[data-wp-nav]'), ed = e.target.closest('[data-wp-edit]'), q = e.target.closest('[data-wp-qr]');
      if (!n && !ed && !q) return;
      var w = App.wp.get((n || ed || q).getAttribute(n ? 'data-wp-nav' : ed ? 'data-wp-edit' : 'data-wp-qr'));
      App.map.closePopup();
      if (!w) return;
      if (n) App.nav.start(w); else if (ed) App.wp.edit(w); else App.share.showQR({ lat: w.lat, lon: w.lon, name: w.name });
    });
    $('nav-stop').addEventListener('click', App.nav.stop);
    $('nav-center').addEventListener('click', function () {
      var t = App.nav.target, f = App.gps.fix; if (!t) return;
      if (f) App.map.fitBounds(L.latLngBounds([[f.lat, f.lon], [t.lat, t.lon]]).pad(0.25), { maxZoom: 17 });
      else App.map.setView([t.lat, t.lon]);
    });
    App.on('gps', function () { App.nav.update(); if (App.drawerOpen('waypoints')) throttledList(); });
    App.on('heading', function () { if (App.nav.target) App.nav.update(); });
    App.map.on('moveend', function () { if (App.nav.target && !App.gps.fix) App.nav.update(); if (App.drawerOpen('waypoints')) paintList(); });
    App.on('settings', function (e) { if (e.key === 'wpLabels') document.body.classList.toggle('hide-wp-labels', !e.value); if (e.key === 'units' || e.key === 'declination') { paintList(); App.nav.update(); } });
    App.on('tab', function (t) { if (t === 'waypoints') paintList(); });
    var lbl = $('ov-wplabels'); lbl.checked = App.settings.wpLabels !== false;
    document.body.classList.toggle('hide-wp-labels', !lbl.checked);
    lbl.addEventListener('change', function () { App.set('wpLabels', lbl.checked); });
    initLongPress();
    var lt = 0;
    function throttledList() { if (Date.now() - lt > 3000) { lt = Date.now(); paintList(); } }
    return reload().then(function () {
      return OGStore.kvGet('map.nav', null).then(function (t) { if (t && t.lat != null) { App.nav.target = t; $('panel-nav').hidden = false; $('nav-name').textContent = t.name; paintMarkers(); App.nav.update(); if (App.settings.wakeLock) { OGSK.wakeLock.request(); App._navWake = true; } } });
    });
  };
})();
