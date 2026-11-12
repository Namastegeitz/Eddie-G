/* =====================================================================
   Map core: shared state, settings, a tiny event bus, formatting helpers
   bound to the user's unit/format settings, the menu drawer, dialogs.
   Every other map module hangs off window.MapApp (alias App).
   ===================================================================== */
(function () {
  'use strict';

  var listeners = {};
  var App = window.MapApp = {
    map: null,
    settings: null,
    gps: { fix: null, watching: false, error: null },  // fix: {lat, lon, alt, acc, altAcc, speed, course, t}
    heading: { deg: null, src: null, t: 0 },          // deg: TRUE heading (declination applied)
    mode: 'normal',                                     // normal | measure | pick
    on: function (evt, fn) { (listeners[evt] = listeners[evt] || []).push(fn); },
    off: function (evt, fn) { listeners[evt] = (listeners[evt] || []).filter(function (f) { return f !== fn; }); },
    emit: function (evt, data) { (listeners[evt] || []).slice().forEach(function (fn) { try { fn(data); } catch (e) { console.error(evt, e); } }); }
  };

  /* ---------------- settings ---------------- */
  App.DEFAULTS = {
    source: 'osm', customUrl: '', customName: 'Custom tiles', customMax: 18, customAttr: '',
    units: 'metric', coordFmt: 'dd', grid: 'auto', contours: false, showTracks: true, wpLabels: true, showAreas: false, breadcrumb: true, showCrumbs: false, gpsMode: 'high',
    declination: 0, declMode: 'auto', autoGps: true, wakeLock: true, minAcc: 50, dimTiles: true, crosshair: true, saveOnView: true,
    demUrl: 'https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png'
  };
  App.loadSettings = function () {
    return OGStore.kvGet('map.settings', {}).then(function (s) {
      App.settings = Object.assign({}, App.DEFAULTS, s || {});
      return App.settings;
    });
  };
  var saveTimer = null;
  App.set = function (key, value) {
    App.settings[key] = value;
    clearTimeout(saveTimer);
    saveTimer = setTimeout(function () { OGStore.kvSet('map.settings', App.settings).catch(console.error); }, 250);
    App.emit('settings', { key: key, value: value });
  };

  /* ---------------- formatting bound to settings ---------------- */
  App.fmtPos = function (lat, lon, fmt) { return OGGeo.formatLatLon(lat, lon, fmt || App.settings.coordFmt); };
  App.fmtDist = function (m) { return OGGeo.fmtDist(m, App.settings.units); };
  App.fmtAlt = function (m) { return OGGeo.fmtAlt(m, App.settings.units); };
  App.fmtSpeed = function (ms) { return OGGeo.fmtSpeed(ms, App.settings.units); };
  App.mgrs = function (lat, lon, digits) { return OGGeo.spaceMGRS(OGGeo.toMGRS(lat, lon, digits)); };
  /* true -> magnetic, using the declination setting (E positive) */
  App.decl = function () { return window.OGCompass ? (+OGCompass.declination || 0) : (+App.settings.declination || 0); };
  App.toMag = function (trueDeg) { return OGGeo.norm360(trueDeg - App.decl()); };
  App.toTrue = function (magDeg) { return OGGeo.norm360(magDeg + App.decl()); };
  App.fmtBrg = function (trueDeg) {
    if (trueDeg == null || isNaN(trueDeg)) return '—';
    var s = OGGeo.fmtBearing(trueDeg) + ' T';
    if (App.decl()) s += ' · ' + Math.round(App.toMag(trueDeg)) + '° M';
    return s;
  };
  App.fmtTime = function (d) {
    if (!d || isNaN(d)) return '—';
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };
  App.esc = function (s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  };
  App.$ = function (id) { return document.getElementById(id); };

  /* The point most tools work from: GPS if we have a recent fix, else map centre. */
  App.here = function (preferCenter) {
    var f = App.gps.fix;
    if (!preferCenter && f && Date.now() - f.t < 5 * 60 * 1000) return { lat: f.lat, lon: f.lon, src: 'gps' };
    var c = App.map.getCenter();
    return { lat: c.lat, lon: c.lng, src: 'center' };
  };

  /* ---------------- banner ---------------- */
  App.banner = function (html, opts) {
    var b = App.$('banner');
    if (!html) { b.hidden = true; b.innerHTML = ''; return; }
    b.className = 'map-banner' + (opts && opts.danger ? ' danger' : '');
    b.innerHTML = html + ' <button class="btn" type="button" data-close>Dismiss</button>';
    b.hidden = false;
    b.querySelector('[data-close]').onclick = function () { b.hidden = true; };
  };

  /* ---------------- drawer ---------------- */
  App.openDrawer = function (tab) {
    var d = App.$('drawer');
    d.hidden = false;
    App.showTab(tab || App._lastTab || 'waypoints');
    var sel = d.querySelector('[aria-selected="true"]');
    if (sel) sel.focus();
  };
  App.closeDrawer = function () { App.$('drawer').hidden = true; App.$('fab-menu').focus(); };
  App.showTab = function (tab) {
    App._lastTab = tab;
    document.querySelectorAll('.drawer-tabs [data-tab]').forEach(function (b) {
      b.setAttribute('aria-selected', b.getAttribute('data-tab') === tab ? 'true' : 'false');
    });
    document.querySelectorAll('.drawer-body .pane').forEach(function (p) {
      p.hidden = p.getAttribute('data-pane') !== tab;
    });
    App.$('drawer-title').textContent = (document.querySelector('.drawer-tabs [data-tab="' + tab + '"]') || {}).textContent || 'Map menu';
    var sel = document.querySelector('.drawer-tabs [data-tab="' + tab + '"]');
    if (sel && sel.scrollIntoView) sel.scrollIntoView({ block: 'nearest', inline: 'center' });
    App.emit('tab', tab);
  };
  App.drawerOpen = function (tab) { var d = App.$('drawer'); return !d.hidden && (!tab || App._lastTab === tab); };

  /* ---------------- confirm / prompt dialog ---------------- */
  App.ask = function (opts) {
    var dlg = App.$('dlg-ask');
    App.$('ask-title').textContent = opts.title || 'Confirm';
    App.$('ask-body').innerHTML = opts.html || '';
    var field = App.$('ask-field'), input = App.$('ask-input');
    field.hidden = !opts.prompt;
    if (opts.prompt) { App.$('ask-label').textContent = opts.prompt; input.value = opts.value || ''; input.required = true; }
    else input.required = false;
    App.$('ask-ok').textContent = opts.ok || 'OK';
    App.$('ask-ok').className = 'btn ' + (opts.danger ? 'danger' : 'primary');
    App.$('ask-cancel').hidden = opts.noCancel;
    return new Promise(function (resolve) {
      function done() {
        dlg.removeEventListener('close', done);
        var ok = dlg.returnValue === 'ok';
        resolve(opts.prompt ? (ok ? input.value.trim() : null) : ok);
      }
      dlg.returnValue = '';
      dlg.addEventListener('close', done);
      dlg.showModal();
      if (opts.prompt) setTimeout(function () { input.focus(); input.select(); }, 50);
    });
  };

  /* Save a text/blob as a file the user can keep (works offline). */
  App.download = function (filename, content, mime) {
    var blob = content instanceof Blob ? content : new Blob([content], { type: mime || 'application/octet-stream' });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url; a.download = filename; a.rel = 'noopener';
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(function () { URL.revokeObjectURL(url); }, 4000);
  };
  App.copy = function (text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text).then(function () { OGSK.toast('Copied'); }, fallback);
    }
    fallback();
    function fallback() {
      var ta = document.createElement('textarea'); ta.value = text; ta.style.position = 'fixed'; ta.style.opacity = '0';
      document.body.appendChild(ta); ta.select();
      try { document.execCommand('copy'); OGSK.toast('Copied'); } catch (e) { OGSK.toast('Copy failed — select the text manually', { error: true }); }
      ta.remove();
    }
  };

  /* segmented buttons helper: <div class="seg"><button data-x="..."> */
  App.seg = function (el, attr, value, onPick) {
    function paint(v) {
      el.querySelectorAll('[' + attr + ']').forEach(function (b) { b.setAttribute('aria-pressed', b.getAttribute(attr) === String(v) ? 'true' : 'false'); });
    }
    paint(value);
    el.addEventListener('click', function (e) {
      var b = e.target.closest('[' + attr + ']');
      if (!b) return;
      var v = b.getAttribute(attr);
      paint(v);
      onPick(v);
    });
    return paint;
  };

  /* SVG icons for waypoint categories (24x24, drawn white on the category colour) */
  App.CAT_ICONS = {
    water: '<path d="M12 3c3 4.5 6 7.6 6 11a6 6 0 0 1-12 0c0-3.4 3-6.5 6-11z"/>',
    camp: '<path d="M2.5 20h19M12 4L3.5 20M12 4l8.5 16M12 13l-3.5 7M12 13l3.5 7"/>',
    food: '<path d="M5 19c0-8 5-14 15-14 0 10-6 15-14 15"/><path d="M5 19l8-8"/>',
    cache: '<path d="M3 7.5l9-4 9 4v9l-9 4-9-4z"/><path d="M3 7.5l9 4 9-4M12 11.5v9"/>',
    hazard: '<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 18v.4"/>',
    rally: '<path d="M5 21V3M5 4h12l-2.5 4L17 12H5"/>',
    landmark: '<path d="M2 20l7-12 4 6 3-4 6 10z"/>',
    medical: '<path d="M9.5 3.5h5v6h6v5h-6v6h-5v-6h-6v-5h6z"/>',
    custom: '<path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4l-5.9 3.1 1.2-6.5L2.5 9.4l6.6-.9z"/>'
  };
  App.catIcon = function (cat) {
    var c = OGStore.WAYPOINT_CATS[cat] || OGStore.WAYPOINT_CATS.custom;
    return '<span class="li-icon" style="background:' + c.color + '"><svg viewBox="0 0 24 24" aria-hidden="true">' +
      (App.CAT_ICONS[cat] || App.CAT_ICONS.custom) + '</svg></span>';
  };
})();
