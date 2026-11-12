/* =====================================================================
   Backtrack — "get me back the way I came"
   ---------------------------------------------------------------------
   While GPS is on, the map keeps an automatic breadcrumb trail (a point
   every ~15 m, kept for 48 h, on this device only). Backtrack reverses the
   current outing's trail (everything since the last 3-hour gap), simplifies
   it, and guides you back along it to where you started — like Garmin
   TracBack / Apple Watch Backtrack. The way you came is the safest way out:
   you know it is passable. A "Direct" button switches to a straight line.

   Guidance on a route (used by App.nav when the target has a route):
     - find where you are on the trail; where the trail passes you twice
       (out-and-back), take the point FURTHEST along the way home;
     - aim at a point ~25 m further along the trail (smooth arrow);
     - if you are off the trail, aim back at the nearest trail point first.
   Saved tracks can be backtracked the same way (Tracks list → Backtrack).
   ===================================================================== */
(function () {
  'use strict';
  var App = window.MapApp;
  var $ = App.$;
  var D2R = Math.PI / 180;
  var GAP = 3 * 3600e3, KEEP = 48 * 3600e3, MAXPTS = 6000;
  var crumbs = [], dirty = 0, lastSave = 0, layer = null;

  function dist(a, b) { return OGGeo.distance(a[0], a[1], b[0], b[1]); }

  /* ---------------- automatic breadcrumb ---------------- */
  function prune() {
    var cut = Date.now() - KEEP;
    while (crumbs.length && crumbs[0][2] < cut) crumbs.shift();
    if (crumbs.length > MAXPTS) crumbs = crumbs.slice(-MAXPTS);
  }
  function save(force) {
    if (!force && dirty < 5 && Date.now() - lastSave < 30000) return;
    dirty = 0; lastSave = Date.now();
    OGStore.kvSet('breadcrumb', { pts: crumbs }).catch(function () {});
  }
  function record(f) {
    if (App.settings.breadcrumb === false || !f || !(f.acc <= 50)) return;
    var last = crumbs[crumbs.length - 1];
    if (last && f.t - last[2] < GAP && dist(last, [f.lat, f.lon]) < Math.max(15, f.acc * 0.6)) return;
    crumbs.push([+f.lat.toFixed(6), +f.lon.toFixed(6), f.t]);
    dirty++; save(false);
    paint();
  }
  /* the current outing: points since the last gap of more than 3 hours */
  function outing() {
    var i = crumbs.length - 1;
    if (i < 0) return [];
    while (i > 0 && crumbs[i][2] - crumbs[i - 1][2] < GAP) i--;
    return crumbs.slice(i);
  }
  function paint() {
    if (!layer) return;
    layer.clearLayers();
    if (!App.settings.showCrumbs) return;
    var o = outing();
    if (o.length > 1) L.polyline(o.map(function (p) { return [p[0], p[1]]; }), { color: '#7cc0ff', weight: 3, opacity: 0.8, dashArray: '1 7', lineCap: 'round', interactive: false }).addTo(layer);
  }

  /* ---------------- geometry ---------------- */
  /* Douglas–Peucker on a local flat projection; tol in metres. */
  function simplify(pts, tol) {
    if (pts.length < 3) return pts.slice();
    var kx = Math.cos(pts[0][0] * D2R) * 111320, ky = 110574;
    var xy = pts.map(function (p) { return [p[1] * kx, p[0] * ky]; });
    var keep = new Uint8Array(pts.length); keep[0] = keep[pts.length - 1] = 1;
    var stack = [[0, pts.length - 1]];
    while (stack.length) {
      var s = stack.pop(), a = s[0], b = s[1], maxd = 0, idx = -1;
      var ax = xy[a][0], ay = xy[a][1], dx = xy[b][0] - ax, dy = xy[b][1] - ay, L2 = dx * dx + dy * dy;
      for (var i = a + 1; i < b; i++) {
        var u = L2 ? Math.max(0, Math.min(1, ((xy[i][0] - ax) * dx + (xy[i][1] - ay) * dy) / L2)) : 0;
        var d = Math.hypot(xy[i][0] - ax - u * dx, xy[i][1] - ay - u * dy);
        if (d > maxd) { maxd = d; idx = i; }
      }
      if (maxd > tol) { keep[idx] = 1; stack.push([a, idx], [idx, b]); }
    }
    return pts.filter(function (p, i) { return keep[i]; });
  }

  /* Where am I on the route, and which way now?  route: [[lat,lon]...] toward the goal. */
  function guide(from, route, acc) {
    var n = route.length, kx = Math.cos(from.lat * D2R) * 111320, ky = 110574;
    function X(p) { return [(p[1] - from.lon) * kx, (p[0] - from.lat) * ky]; }
    var tol = Math.max(30, (acc || 0) * 1.5), segs = [], minD = Infinity;
    for (var k = 0; k < n - 1; k++) {
      var a = X(route[k]), b = X(route[k + 1]), dx = b[0] - a[0], dy = b[1] - a[1], L2 = dx * dx + dy * dy;
      var u = L2 ? Math.max(0, Math.min(1, -(a[0] * dx + a[1] * dy) / L2)) : 0;
      var d = Math.hypot(a[0] + u * dx, a[1] + u * dy);
      segs.push({ k: k, u: u, d: d }); if (d < minD) minD = d;
    }
    // Out-and-back trails pass you twice. Among the trail pieces about as close as the nearest one,
    // take the one FURTHEST along the way home, so we never send you back out to the far end.
    var reach = Math.max(tol, minD * 1.25 + 15), m = null;
    segs.forEach(function (sg) { if (sg.d <= reach && (!m || sg.k >= m.k)) m = sg; });
    var off = minD > tol;
    var A = route[m.k], B = route[m.k + 1];
    var P = [A[0] + (B[0] - A[0]) * m.u, A[1] + (B[1] - A[1]) * m.u];
    // look ~25 m ahead along the trail for a steady arrow
    var j = m.k + 1, ahead = dist(P, route[j]);
    while (ahead < 25 && j < n - 1) { ahead += dist(route[j], route[j + 1]); j++; }
    var rest = 0;
    for (var q = m.k + 1; q < n - 1; q++) rest += dist(route[q], route[q + 1]);
    return {
      k: m.k, P: P, next: route[j], off: off, offBy: m.d,
      remaining: m.d + dist(P, route[m.k + 1]) + rest
    };
  }

  /* ---------------- start a backtrack ---------------- */
  function start(trail, name) {
    var pts = trail.map(function (p) { return [p[0], p[1]]; });
    var f = App.gps.fix;
    if (f && Date.now() - f.t < 120000) pts.push([f.lat, f.lon]);     // trail ends where you are now
    var route = simplify(pts, 8).reverse();
    if (route.length < 2) { OGSK.toast('Trail too short to backtrack', { error: true }); return; }
    var end = route[route.length - 1];
    App.nav.start({ name: name || 'Start of trail', lat: end[0], lon: end[1], route: route, kind: 'backtrack' });
    App.map.fitBounds(L.latLngBounds(route).pad(0.15), { maxZoom: 17 });
  }
  function hhmm(t) { return new Date(t).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }); }

  function ask() {
    var o = outing();
    if (o.length < 2) {
      App.ask({
        title: 'No breadcrumb trail yet',
        html: '<p>The app records your trail automatically while the map is open with GPS on (a point every ~15 m). Nothing has been recorded for this outing yet.</p>' +
          '<p>To get back to a known place now, use a waypoint: open the Waypoints list and tap <strong>Go</strong>, or a saved track: Tracks → <strong>Backtrack</strong>.</p>',
        ok: 'OK', noCancel: true
      });
      return;
    }
    var walked = OGGeo.pathLength(o), f = App.gps.fix, st = o[0];
    var straight = f ? dist([f.lat, f.lon], st) : null;
    App.ask({
      title: 'Backtrack to where you started?',
      html: '<p>Trail since <strong>' + hhmm(st[2]) + '</strong>: ' + App.fmtDist(walked) + ' walked' +
        (straight != null ? '; the start is ' + App.fmtDist(straight) + ' away in a straight line' : '') + '.</p>' +
        '<p>You will be guided back <strong>along the way you came</strong> — usually the safest way out, because you know it is passable. Tap <em>Direct</em> in the panel for a straight line instead.</p>' +
        '<p class="help">Lost and unsure? STOP: stay put if someone knows your plan, and signal. Backtrack only on ground you are confident you crossed.</p>',
      ok: 'Follow my trail back'
    }).then(function (ok) { if (ok) start(o, 'Start (' + hhmm(st[2]) + ')'); });
  }

  App.bt = { guide: guide, start: start, simplify: simplify, outing: outing, ask: ask, record: record };

  App.btInit = function () {
    layer = L.layerGroup().addTo(App.map);
    App.on('gps', record);
    $('fab-back').addEventListener('click', ask);
    $('bt-start').addEventListener('click', function () { App.closeDrawer(); ask(); });
    $('bt-clear').addEventListener('click', function () {
      App.ask({ title: 'Clear the breadcrumb trail?', html: '<p>Backtrack will start from scratch.</p>', ok: 'Clear', danger: true }).then(function (ok) {
        if (!ok) return;
        crumbs = []; save(true); paint(); paintInfo(); OGSK.toast('Breadcrumb cleared');
      });
    });
    var rec = $('set-crumbs'); rec.checked = App.settings.breadcrumb !== false;
    rec.addEventListener('change', function () { App.set('breadcrumb', rec.checked); paintInfo(); });
    var show = $('ov-crumbs'); show.checked = !!App.settings.showCrumbs;
    show.addEventListener('change', function () { App.set('showCrumbs', show.checked); paint(); });
    function paintInfo() {
      var o = outing();
      $('bt-info').textContent = App.settings.breadcrumb === false ? 'Automatic breadcrumb is off (Settings).' :
        o.length > 1 ? 'Breadcrumb since ' + hhmm(o[0][2]) + ': ' + App.fmtDist(OGGeo.pathLength(o)) + ' (' + o.length + ' points).' :
          'Breadcrumb records automatically while GPS is on.';
    }
    App.on('tab', function (t) { if (t === 'tracks') paintInfo(); });
    window.addEventListener('pagehide', function () { save(true); });
    document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'hidden') save(true); });
    return OGStore.kvGet('breadcrumb', { pts: [] }).then(function (b) {
      crumbs = (b && Array.isArray(b.pts)) ? b.pts : [];
      prune(); paint(); paintInfo();
    });
  };
})();
