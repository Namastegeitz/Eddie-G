/* =====================================================================
   Map boot: create the Leaflet map, restore the last view, wire up the
   menu drawer and settings, start every module, handle #wp= / #nav= links.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;

  App.PRESETS = [
    { name: 'Northeast US (New Jersey)', lat: 40.15, lon: -74.65, z: 8 },
    { name: 'Algarve, Portugal', lat: 37.15, lon: -8.25, z: 9 }
  ];

  function lastView() {
    try {
      var v = JSON.parse(localStorage.getItem('ogsk.map.view') || 'null');
      if (v && isFinite(v.lat) && isFinite(v.lon) && isFinite(v.z)) return v;
    } catch (e) {}
    return App.PRESETS[0];
  }

  var scaleCtl = null;
  function setScale() {
    if (scaleCtl) App.map.removeControl(scaleCtl);
    var imp = App.settings.units === 'imperial';
    scaleCtl = L.control.scale({ position: 'bottomleft', metric: !imp, imperial: imp, maxWidth: 140 }).addTo(App.map);
    // keep the bottom stack above the scale bar
    var stack = $('bottom-stack');
    if (stack && stack.parentNode) stack.parentNode.insertBefore(stack, stack.parentNode.firstChild);
  }

  function paintCenter() {
    var c = App.map.getCenter(), e = App.centerElev;
    var s = '<span class="k">⊕</span> ' + App.esc(App.fmtPos(c.lat, c.lng)) + ' · ' + App.esc(App.mgrs(c.lat, c.lng, 4));
    if (e) s += '<br>Elev ' + App.fmtAlt(e.elev) + ' · slope ' + App.dem.fmtSlope(e);
    $('center-readout').innerHTML = s;
  }

  function paintBookmarks() {
    $('preset-row').innerHTML = App.PRESETS.map(function (p, i) {
      return '<button class="btn" type="button" data-preset="' + i + '">' + App.esc(p.name) + '</button>';
    }).join('') + '<button class="btn" type="button" data-preset="me">My position</button>';
    OGStore.kvGet('map.bookmarks', []).then(function (bms) {
      $('bm-list').innerHTML = bms.map(function (b) {
        return '<li><button class="li-main" type="button" data-bm="' + b.id + '"><strong>' + App.esc(b.name) + '</strong><small>' +
          App.esc(App.fmtPos(b.lat, b.lon)) + ' · zoom ' + b.z + '</small></button><button class="btn" type="button" data-bm-del="' + b.id + '" aria-label="Delete bookmark">✕</button></li>';
      }).join('');
    });
  }

  function wireSettings() {
    var s = App.settings;
    App.seg($('set-units'), 'data-v', s.units, function (v) { App.set('units', v); setScale(); });
    var paintFmt = App.seg($('set-fmt'), 'data-v', s.coordFmt, function (v) { App.set('coordFmt', v); });
    App.on('settings', function (e) { if (e.key === 'coordFmt') { paintFmt(e.value); paintCenter(); } if (e.key === 'units') paintCenter(); });
    // magnetic declination: automatic (WMM2025, in the compass engine) or manual
    var paintDeclMode = App.seg($('set-declmode'), 'data-v', OGCompass.declMode, function (v) {
      if (v === 'manual') OGCompass.setDeclination(OGCompass.autoDecl != null ? OGCompass.autoDecl : OGCompass.manualDecl);
      else OGCompass.setDeclMode('auto');
    });
    function paintDecl() {
      paintDeclMode(OGCompass.declMode);
      $('decl-now').textContent = OGCompass.declLabel();
      $('set-decl-wrap').hidden = OGCompass.declMode !== 'manual';
      if (document.activeElement !== $('set-decl')) $('set-decl').value = OGCompass.manualDecl;
    }
    $('set-decl').addEventListener('change', function () { this.value = OGCompass.setDeclination(this.value); });
    App.on('settings', function (e) { if (e.key === 'declination') paintDecl(); });
    App.on('tab', function (t) { if (t === 'settings') paintDecl(); });
    paintDecl();
    [['set-autogps', 'autoGps'], ['set-wake', 'wakeLock'], ['set-dim', 'dimTiles'], ['set-cross', 'crosshair'], ['set-saveview', 'saveOnView']].forEach(function (p) {
      var el = $(p[0]); el.checked = s[p[1]] !== false;
      el.addEventListener('change', function () { App.set(p[1], el.checked); applyDisplay(); });
    });
    // GPS mode + battery (Battery Status API: Chrome/Android; not available on iPhone)
    var paintGpsMode = App.seg($('set-gpsmode'), 'data-v', s.gpsMode || 'high', function (v) {
      App.set('gpsMode', v); App.gpsRestart();
      OGSK.toast(v === 'saver' ? 'Battery saver: one GPS fix a minute' : 'Continuous GPS');
    });
    var lowWarned = false;
    function batteryText(b) {
      return 'Battery: ' + Math.round(b.level * 100) + ' %' + (b.charging ? ' (charging)' : '') + '. GPS is ' + (App.settings.gpsMode === 'saver' ? 'in battery saver mode.' : 'continuous.');
    }
    if (navigator.getBattery) {
      navigator.getBattery().then(function (b) {
        function upd() {
          $('battery-now').textContent = batteryText(b);
          if (!b.charging && b.level <= 0.2 && !lowWarned && App.settings.gpsMode !== 'saver') {
            lowWarned = true;
            App.banner('<strong>Battery ' + Math.round(b.level * 100) + ' %.</strong> Save power: switch GPS to battery saver, turn on airplane mode (GPS still works), dim the screen and keep the phone warm. <button class="btn" type="button" id="use-saver">Use battery saver</button>');
            var u = document.getElementById('use-saver');
            if (u) u.onclick = function () { App.set('gpsMode', 'saver'); paintGpsMode('saver'); App.gpsRestart(); App.banner(null); };
          }
        }
        b.addEventListener('levelchange', upd); b.addEventListener('chargingchange', upd); upd();
      }).catch(function () {});
    } else $('battery-now').textContent = 'This browser does not report battery level (iPhone/Safari). Check it in the status bar.';
    $('set-minacc').value = String(s.minAcc || 50);
    $('set-minacc').addEventListener('change', function () { App.set('minAcc', +this.value); });
  }
  function applyDisplay() {
    document.documentElement.classList.toggle('no-dim', App.settings.dimTiles === false);
    document.body.classList.toggle('hide-crosshair', App.settings.crosshair === false);
  }

  function wireDrawer() {
    document.querySelector('.drawer-tabs').addEventListener('click', function (e) {
      var b = e.target.closest('[data-tab]'); if (b) App.showTab(b.getAttribute('data-tab'));
    });
    $('fab-menu').addEventListener('click', function () { App.openDrawer(); });
    $('fab-layers').addEventListener('click', function () { App.openDrawer('layers'); });
    $('drawer-close').addEventListener('click', App.closeDrawer);
    document.addEventListener('keydown', function (e) {
      if (e.key !== 'Escape') return;
      if (!$('drawer').hidden && !document.querySelector('dialog[open]')) App.closeDrawer();
      else if (App.mode === 'pick') App.pickCancel();
    });
    $('center-readout').addEventListener('click', function () { App.openDrawer('position'); });
    $('center-readout').addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); App.openDrawer('position'); } });
    $('preset-row').addEventListener('click', function (e) {
      var b = e.target.closest('[data-preset]'); if (!b) return;
      var k = b.getAttribute('data-preset');
      if (k === 'me') { App.setFollow(true); if (!App.gps.fix) OGSK.toast('Waiting for GPS…'); }
      else { var p = App.PRESETS[+k]; App.map.setView([p.lat, p.lon], p.z); }
      if (innerWidth < 800) App.closeDrawer();
    });
    $('bm-add').addEventListener('click', function () {
      var c = App.map.getCenter();
      App.ask({ title: 'Bookmark this view', prompt: 'Name', value: 'View ' + App.fmtPos(c.lat, c.lng, 'dd'), ok: 'Save' }).then(function (name) {
        if (!name) return;
        OGStore.kvGet('map.bookmarks', []).then(function (bms) {
          bms.push({ id: OGStore.uid(), name: name, lat: c.lat, lon: c.lng, z: App.map.getZoom() });
          return OGStore.kvSet('map.bookmarks', bms);
        }).then(paintBookmarks);
      });
    });
    $('bm-list').addEventListener('click', function (e) {
      var go = e.target.closest('[data-bm]'), del = e.target.closest('[data-bm-del]');
      OGStore.kvGet('map.bookmarks', []).then(function (bms) {
        if (go) { var b = bms.filter(function (x) { return x.id === go.getAttribute('data-bm'); })[0]; if (b) { App.map.setView([b.lat, b.lon], b.z); if (innerWidth < 800) App.closeDrawer(); } }
        if (del) OGStore.kvSet('map.bookmarks', bms.filter(function (x) { return x.id !== del.getAttribute('data-bm-del'); })).then(paintBookmarks);
      });
    });
  }

  function handleHash() {
    var h = location.hash.replace(/^#/, ''), m;
    if ((m = /^wp=([\w-]+)/.exec(h))) {
      if (!App.wp.focus(m[1])) OGSK.toast('That waypoint no longer exists', { error: true });
    } else if ((m = /^nav=([\w-]+)/.exec(h))) {
      var w = App.wp.get(m[1]);
      if (w) App.nav.start(w); else OGSK.toast('That waypoint no longer exists', { error: true });
    } else if ((m = /^ll=(-?[\d.]+),(-?[\d.]+)(?:,(\d+))?/.exec(h))) {
      App.map.setView([+m[1], +m[2]], m[3] ? +m[3] : 15);
    } else if (h === 'sos') {
      App.openBeacon();
    } else if (h === 'compass') {
      App.openCompass();
    } else if (h === 'backtrack') {
      App.bt.ask();
    } else if (h === '3d') {
      if (App.open3D) App.open3D();
    } else if (h === 'live') {
      if (App.openLive) App.openLive();
    } else if ((m = /^tab=(\w+)/.exec(h))) {
      App.openDrawer(m[1]);
    } else return;
    history.replaceState(null, '', location.pathname + location.search);
  }

  function boot() {
    if (!window.L) { document.getElementById('map').innerHTML = '<p style="padding:16px">Map engine failed to load.</p>'; return; }
    App.loadSettings().then(function () {
      var v = lastView();
      var map = App.map = L.map('map', {
        center: [v.lat, v.lon], zoom: v.z, minZoom: 2, maxZoom: 20, worldCopyJump: true,
        zoomControl: true, attributionControl: true, zoomSnap: 1, wheelPxPerZoomLevel: 90
      });
      map.attributionControl.setPrefix('<a href="https://leafletjs.com" rel="noopener">Leaflet</a>');
      // bottom stack (panels + centre readout) as a Leaflet control so it stacks with the scale bar
      var Stack = L.Control.extend({ options: { position: 'bottomleft' }, onAdd: function () {
        var el = $('bottom-stack'); L.DomEvent.disableClickPropagation(el); L.DomEvent.disableScrollPropagation(el); return el;
      } });
      new Stack().addTo(map);
      setScale();
      applyDisplay();
      App.setBaseLayer();
      App.grid.init();
      App.tiles.init();
      App.dem.init();
      App.gpsInit();
      App.measureInit();
      App.sunInit();
      App.shareInit();
      App.dataInit();
      wireSettings();
      wireDrawer();
      paintBookmarks();
      map.on('move', paintCenter);
      App.on('center:elev', paintCenter);
      map.on('moveend', function () {
        var c = map.getCenter();
        try { localStorage.setItem('ogsk.map.view', JSON.stringify({ lat: +c.lat.toFixed(6), lon: +c.lng.toFixed(6), z: map.getZoom() })); } catch (e) {}
      });
      paintCenter();
      App.dem.updateCenter();
      if (App.t3dInit) App.t3dInit();     // 3D terrain view (terrain3d.js)
      if (App.liveInit) App.liveInit();   // live satellite / radar overlays (live.js)
      return Promise.all([App.wp.init(), App.tracksInit(), App.triInit(), App.btInit()]);
    }).then(function () {
      handleHash();
      window.addEventListener('hashchange', handleHash);
      App.ready = true;
      App.emit('ready');
      document.documentElement.setAttribute('data-map-ready', '1');
    }).catch(function (e) {
      console.error(e);
      App.banner('Something went wrong starting the map: ' + App.esc(e.message), { danger: true });
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
