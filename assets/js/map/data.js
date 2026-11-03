/* =====================================================================
   Data portability: GPX 1.1 export/import (waypoints + tracks) and a full
   JSON backup/restore (everything except map tiles). Files are created and
   read on the device; nothing is uploaded anywhere.
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;

  function x(s) { return String(s == null ? '' : s).replace(/[<>&'"]/g, function (c) { return { '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' }[c]; }); }
  function iso(t) { try { return new Date(t).toISOString(); } catch (e) { return ''; } }
  function stamp() { var d = new Date(); return d.getFullYear() + String(d.getMonth() + 1).padStart(2, '0') + String(d.getDate()).padStart(2, '0') + '-' + String(d.getHours()).padStart(2, '0') + String(d.getMinutes()).padStart(2, '0'); }

  function buildGpx(wps, trks, name) {
    var out = ['<?xml version="1.0" encoding="UTF-8"?>',
      '<gpx version="1.1" creator="Off-Grid Survival Kit" xmlns="http://www.topografix.com/GPX/1/1">',
      '<metadata><name>' + x(name || 'Off-Grid Survival Kit export') + '</name><time>' + iso(Date.now()) + '</time></metadata>'];
    wps.forEach(function (w) {
      out.push('<wpt lat="' + w.lat.toFixed(7) + '" lon="' + w.lon.toFixed(7) + '">' +
        (w.alt != null ? '<ele>' + (+w.alt).toFixed(1) + '</ele>' : '') +
        '<time>' + iso(w.created || Date.now()) + '</time><name>' + x(w.name) + '</name>' +
        (w.note ? '<desc>' + x(w.note) + '</desc>' : '') +
        '<sym>' + x((OGStore.WAYPOINT_CATS[w.cat] || OGStore.WAYPOINT_CATS.custom).label) + '</sym><type>' + x(w.cat) + '</type></wpt>');
    });
    trks.forEach(function (t) {
      out.push('<trk><name>' + x(t.name) + '</name><trkseg>');
      (t.points || []).forEach(function (p) {
        out.push('<trkpt lat="' + p[0].toFixed(7) + '" lon="' + p[1].toFixed(7) + '">' + (p[2] != null ? '<ele>' + p[2] + '</ele>' : '') + (p[3] ? '<time>' + iso(p[3]) + '</time>' : '') + '</trkpt>');
      });
      out.push('</trkseg></trk>');
    });
    out.push('</gpx>');
    return out.join('\n');
  }

  function parseGpx(text) {
    var doc = new DOMParser().parseFromString(text, 'application/xml');
    if (doc.getElementsByTagName('parsererror').length) throw new Error('Not a valid GPX/XML file');
    function child(el, tag) { var c = el.getElementsByTagNameNS('*', tag)[0] || el.getElementsByTagName(tag)[0]; return c ? c.textContent.trim() : ''; }
    function all(el, tag) { var l = el.getElementsByTagNameNS('*', tag); return l.length ? l : el.getElementsByTagName(tag); }
    var now = Date.now(), wps = [], trks = [];
    Array.prototype.forEach.call(all(doc, 'wpt'), function (el) {
      var lat = parseFloat(el.getAttribute('lat')), lon = parseFloat(el.getAttribute('lon'));
      if (isNaN(lat) || isNaN(lon)) return;
      var type = child(el, 'type').toLowerCase(), ele = parseFloat(child(el, 'ele'));
      wps.push({ id: OGStore.uid(), name: child(el, 'name') || 'Imported point', cat: OGStore.WAYPOINT_CATS[type] ? type : 'custom',
        lat: lat, lon: lon, alt: isNaN(ele) ? undefined : ele, note: child(el, 'desc') || child(el, 'cmt'), created: now, updated: now });
    });
    function pts(nodes) {
      return Array.prototype.map.call(nodes, function (p) {
        var ele = parseFloat(child(p, 'ele')), tm = Date.parse(child(p, 'time'));
        return [parseFloat(p.getAttribute('lat')), parseFloat(p.getAttribute('lon')), isNaN(ele) ? null : ele, isNaN(tm) ? null : tm, null];
      }).filter(function (p) { return !isNaN(p[0]) && !isNaN(p[1]); });
    }
    Array.prototype.forEach.call(all(doc, 'trk'), function (el) {
      var p = pts(el.getElementsByTagNameNS('*', 'trkpt').length ? el.getElementsByTagNameNS('*', 'trkpt') : el.getElementsByTagName('trkpt'));
      if (p.length > 1) trks.push({ id: OGStore.uid(), name: child(el, 'name') || 'Imported track', points: p, dist: OGGeo.pathLength(p), created: p[0][3] || now, updated: now });
    });
    Array.prototype.forEach.call(all(doc, 'rte'), function (el) {
      var p = pts(el.getElementsByTagNameNS('*', 'rtept').length ? el.getElementsByTagNameNS('*', 'rtept') : el.getElementsByTagName('rtept'));
      if (p.length > 1) trks.push({ id: OGStore.uid(), name: (child(el, 'name') || 'Imported route') + ' (route)', points: p, dist: OGGeo.pathLength(p), created: now, updated: now });
    });
    return { waypoints: wps, tracks: trks };
  }

  App.data = {
    buildGpx: buildGpx, parseGpx: parseGpx,
    downloadGpx: function (wps, trks, name) {
      App.download((name || 'ogsk').replace(/[^\w\- ]+/g, '').trim().replace(/\s+/g, '-') + '-' + stamp() + '.gpx', buildGpx(wps, trks, name), 'application/gpx+xml');
    }
  };

  function importFile(file) {
    var msg = $('import-msg');
    msg.textContent = 'Reading ' + file.name + '…';
    file.text().then(function (text) {
      var trimmed = text.trim();
      if (trimmed.charAt(0) === '{') {
        var data = JSON.parse(trimmed);
        var replace = $('restore-replace').checked;
        return App.ask({ title: replace ? 'Replace all data with this backup?' : 'Merge this backup?',
          html: '<p>' + (data.waypoints || []).length + ' waypoints, ' + (data.tracks || []).length + ' tracks, ' + (data.checklists || []).length + ' checklists.' +
            (replace ? ' <strong>Existing waypoints, tracks and checklists will be deleted first.</strong>' : ' Items with the same ID are overwritten.') + '</p>',
          ok: replace ? 'Replace' : 'Merge', danger: replace }).then(function (ok) {
          if (!ok) { msg.textContent = 'Cancelled.'; return; }
          return OGStore.importAll(data, { replace: replace }).then(function (r) {
            msg.textContent = 'Restored ' + r.waypoints + ' waypoints, ' + r.tracks + ' tracks, ' + r.checklists + ' checklists. Reloading…';
            setTimeout(function () { location.reload(); }, 900);
          });
        });
      }
      var g = parseGpx(text);
      if (!g.waypoints.length && !g.tracks.length) throw new Error('No waypoints or tracks found in the file');
      return OGStore.putMany('waypoints', g.waypoints).then(function () { return OGStore.putMany('tracks', g.tracks); }).then(function () {
        msg.textContent = 'Imported ' + g.waypoints.length + ' waypoints and ' + g.tracks.length + ' tracks.';
        App.wp.reload(); App.tracks.reload();
        var all = g.waypoints.map(function (w) { return [w.lat, w.lon]; });
        g.tracks.forEach(function (t) { t.points.forEach(function (p) { all.push([p[0], p[1]]); }); });
        if (all.length) App.map.fitBounds(L.latLngBounds(all).pad(0.1), { maxZoom: 15 });
      });
    }).catch(function (e) { msg.textContent = 'Import failed: ' + e.message; })
      .then(function () { $('file-in').value = ''; });
  }

  App.dataInit = function () {
    $('gpx-export').addEventListener('click', function () {
      var w = App.wp.all(), t = App.tracks.all();
      if (!w.length && !t.length) { OGSK.toast('Nothing to export yet', { error: true }); return; }
      App.data.downloadGpx(w, t, 'Off-Grid Survival Kit');
      OGSK.toast('GPX saved: ' + w.length + ' waypoints, ' + t.length + ' tracks');
    });
    $('json-export').addEventListener('click', function () {
      OGStore.exportAll().then(function (data) {
        App.download('ogsk-backup-' + stamp() + '.json', JSON.stringify(data, null, 1), 'application/json');
        OGSK.toast('Backup saved');
      });
    });
    $('file-in').addEventListener('change', function () { if (this.files && this.files[0]) importFile(this.files[0]); });
  };
})();
