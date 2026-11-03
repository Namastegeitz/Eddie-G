/* =====================================================================
   Measure: tap points (or add the crosshair) to get cumulative distance
   and each leg's distance + true bearing (magnetic too if declination set).
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var pts = [], layer = null, line = null;

  function enter() {
    App.mode = 'measure';
    $('fab-measure').setAttribute('aria-pressed', 'true');
    $('panel-measure').hidden = false;
    App.map.getContainer().style.cursor = 'crosshair';
    paint();
  }
  function exit() {
    App.mode = 'normal';
    $('fab-measure').setAttribute('aria-pressed', 'false');
    $('panel-measure').hidden = true;
    App.map.getContainer().style.cursor = '';
    pts = []; paint();
  }
  function add(ll) { pts.push([ll.lat, ll.lng]); paint(); }
  function paint() {
    layer.clearLayers(); line = null;
    if (pts.length) {
      line = L.polyline(pts, { color: '#ffb000', weight: 4, dashArray: '2 8', lineCap: 'round', interactive: false }).addTo(layer);
      pts.forEach(function (p) {
        L.marker(p, { icon: L.divIcon({ className: '', html: '<div class="measure-vertex"></div>', iconSize: [14, 14], iconAnchor: [7, 7] }), interactive: false, keyboard: false }).addTo(layer);
      });
    }
    var total = 0, legs = [];
    for (var i = 1; i < pts.length; i++) {
      var d = OGGeo.distance(pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1]);
      var b = OGGeo.bearing(pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1]);
      total += d; legs.push({ d: d, b: b });
      if (pts.length - i <= 12) {
        var mid = [(pts[i - 1][0] + pts[i][0]) / 2, (pts[i - 1][1] + pts[i][1]) / 2];
        L.tooltip({ permanent: true, direction: 'top', className: 'measure-tip', interactive: false })
          .setLatLng(mid).setContent(App.fmtDist(d) + ' · ' + Math.round(b) + '°').addTo(layer);
      }
    }
    var last = legs[legs.length - 1];
    $('ms-total').textContent = App.fmtDist(total);
    $('ms-leg').textContent = last ? App.fmtDist(last.d) : '—';
    $('ms-brg').textContent = last ? Math.round(last.b) + '° ' + OGGeo.cardinal(last.b) : '—';
    $('ms-legs').innerHTML = legs.length ? legs.map(function (l, i) {
      return 'Leg ' + (i + 1) + ': ' + App.fmtDist(l.d) + ' at ' + App.fmtBrg(l.b);
    }).join('<br>') : (pts.length ? 'Tap a second point.' : 'Tap the map, or use “+ Crosshair”, to place the first point.');
  }

  App.measureInit = function () {
    layer = L.layerGroup().addTo(App.map);
    $('fab-measure').addEventListener('click', function () { if (App.mode === 'measure') exit(); else { if (App.mode === 'pick') App.pickCancel(); enter(); } });
    App.map.on('click', function (e) { if (App.mode === 'measure') add(e.latlng); });
    $('ms-center').addEventListener('click', function () { add(App.map.getCenter()); });
    $('ms-undo').addEventListener('click', function () { pts.pop(); paint(); });
    $('ms-clear').addEventListener('click', function () { pts = []; paint(); });
    $('ms-done').addEventListener('click', exit);
    App.on('settings', function (e) { if (e.key === 'units' || e.key === 'declination') paint(); });
  };
})();
