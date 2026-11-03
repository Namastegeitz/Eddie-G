/* Hub page: live status chips (signal, offline copy, GPS permission/last fix,
   saved map tiles) and the install button. */
(function () {
  'use strict';
  function chip(id, cls, text) { var el = document.getElementById(id); if (!el) return; el.className = 'chip ' + cls; el.textContent = text; }

  function net() { chip('chip-net', navigator.onLine ? 'ok' : 'warn', navigator.onLine ? 'Signal: online' : 'Signal: offline'); }
  window.addEventListener('online', net); window.addEventListener('offline', net);

  /* Offline copy: ask the service worker how many precached files it holds. */
  function offlineStatus() {
    if (!('serviceWorker' in navigator)) { chip('chip-offline', 'bad', 'Offline copy: not supported here'); return; }
    if (location.protocol === 'file:') { chip('chip-offline', 'bad', 'Offline copy: open via http://localhost or https'); return; }
    navigator.serviceWorker.ready.then(function (reg) {
      var sw = navigator.serviceWorker.controller || reg.active;
      if (!sw) return;
      var ch = new MessageChannel();
      ch.port1.onmessage = function (e) {
        var s = e.data || {};
        if (s.total && s.cached >= s.total) chip('chip-offline', 'ok', 'Offline-ready ✓');
        else chip('chip-offline', 'warn', 'Saving offline copy… ' + (s.cached || 0) + '/' + (s.total || '?'));
        var v = document.getElementById('version'); if (v) v.textContent = 'App version ' + s.version + ' · ' + s.total + ' files cached for offline use';
        if (!(s.total && s.cached >= s.total)) setTimeout(offlineStatus, 1500);
      };
      sw.postMessage({ type: 'status' }, [ch.port2]);
    });
    chip('chip-offline', 'warn', 'Offline copy: installing…');
  }

  function gps() {
    var lf = null;
    try { lf = JSON.parse(localStorage.getItem('ogsk.lastfix') || 'null'); } catch (e) {}
    var last = lf ? ' · last fix ' + ago(lf.t) : '';
    if (!window.isSecureContext) { chip('chip-gps', 'bad', 'GPS: blocked (needs https/localhost)'); return; }
    if (!('geolocation' in navigator)) { chip('chip-gps', 'bad', 'GPS: not available'); return; }
    if (navigator.permissions && navigator.permissions.query) {
      navigator.permissions.query({ name: 'geolocation' }).then(function (st) {
        var map = { granted: ['ok', 'GPS: allowed'], prompt: ['warn', 'GPS: will ask on the map'], denied: ['bad', 'GPS: permission denied'] };
        var m = map[st.state] || ['warn', 'GPS: unknown'];
        chip('chip-gps', m[0], m[1] + last);
      }, function () { chip('chip-gps', 'warn', 'GPS: ready' + last); });
    } else chip('chip-gps', 'warn', 'GPS: ready' + last);
  }
  function ago(t) {
    var s = Math.round((Date.now() - t) / 1000);
    if (s < 90) return s + ' s ago';
    if (s < 5400) return Math.round(s / 60) + ' min ago';
    if (s < 172800) return Math.round(s / 3600) + ' h ago';
    return Math.round(s / 86400) + ' days ago';
  }

  function tiles() {
    if (!window.OGStore) return;
    OGStore.tileStats().then(function (s) {
      chip('chip-tiles', s.count ? 'ok' : 'warn', s.count ? 'Saved map: ' + s.count.toLocaleString() + ' tiles · ' + OGStore.fmtBytes(s.bytes) : 'Saved map: none yet');
    }).catch(function () { chip('chip-tiles', 'bad', 'Storage unavailable'); });
  }

  /* Install prompt (Chrome/Edge/Android). iOS has no prompt: instructions are shown instead. */
  var deferred = null;
  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault(); deferred = e;
    var b = document.getElementById('install-btn'); b.hidden = false;
    document.getElementById('install-state').textContent = 'This browser can install the app to your home screen.';
  });
  window.addEventListener('appinstalled', function () {
    document.getElementById('install-state').textContent = 'Installed. Open it from your home screen.';
    document.getElementById('install-btn').hidden = true;
  });
  function installState() {
    var standalone = window.matchMedia('(display-mode: standalone)').matches || navigator.standalone;
    var el = document.getElementById('install-state');
    if (standalone) { el.textContent = 'Running as an installed app ✓'; document.getElementById('install-card').classList.add('installed'); }
    else if (!deferred) el.textContent = /iphone|ipad|ipod/i.test(navigator.userAgent) ? 'On iPhone/iPad: Share → Add to Home Screen.' : 'Use your browser menu → Install app / Add to Home screen.';
  }

  /* "Open on another phone": QR code of this app's public address. */
  var PUBLIC_URL = 'https://namastegeitz.github.io/Eddie-G/';
  function shareApp() {
    var local = /^(localhost|127\.|192\.168\.|10\.|\[?::1)/.test(location.hostname) || location.protocol === 'file:';
    var url = local ? PUBLIC_URL : new URL('./', location.href).href;
    document.getElementById('app-url').textContent = url;
    if (window.qrcode) {
      var qr = qrcode(0, 'M'); qr.addData(url); qr.make();
      document.getElementById('app-qr').innerHTML = qr.createSvgTag({ cellSize: 6, margin: 4, scalable: true });
    }
    document.getElementById('app-url-copy').addEventListener('click', function () {
      if (navigator.clipboard) navigator.clipboard.writeText(url).then(function () { OGSK.toast('Link copied'); }, function () { OGSK.toast(url); });
      else OGSK.toast(url);
    });
    if (navigator.share) {
      var b = document.getElementById('app-url-share'); b.hidden = false;
      b.addEventListener('click', function () { navigator.share({ title: 'Off-Grid Survival Kit', url: url }).catch(function () {}); });
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    shareApp();
    document.getElementById('install-btn').addEventListener('click', function () {
      if (!deferred) return;
      deferred.prompt();
      deferred.userChoice.finally(function () { deferred = null; document.getElementById('install-btn').hidden = true; });
    });
    net(); gps(); tiles(); installState(); offlineStatus();
    if (window.OGStore) OGStore.persist();
  });
})();
