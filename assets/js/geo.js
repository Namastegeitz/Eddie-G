/* =====================================================================
   Off-Grid Survival Kit — geodesy helpers (pure functions, no network)
   ---------------------------------------------------------------------
   - great-circle distance / bearing / destination (spherical, R = 6371 km)
   - coordinate formatting: decimal degrees, DMS, degrees-decimal-minutes
   - UTM forward/inverse on WGS84 (Krüger 6th-order series, sub-mm accuracy
     inside a zone; after C. Veness / Karney 2011)
   - MGRS via the bundled mgrs library (assets/vendor/mgrs.min.js)
   - coordinate text parser (DD, DMS, DDM, MGRS, UTM)
   - resection / triangulation solver (least squares on a local plane)
   - unit formatting (metric / imperial)
   ===================================================================== */
(function () {
  'use strict';

  var R = 6371008.8;            // mean Earth radius (m)
  var D2R = Math.PI / 180, R2D = 180 / Math.PI;

  function norm360(d) { d = d % 360; return d < 0 ? d + 360 : d; }
  function norm180(d) { d = norm360(d); return d > 180 ? d - 360 : d; }

  /* ---------- spherical distance / bearing ---------- */
  function distance(lat1, lon1, lat2, lon2) {
    var p1 = lat1 * D2R, p2 = lat2 * D2R, dp = (lat2 - lat1) * D2R, dl = (lon2 - lon1) * D2R;
    var a = Math.sin(dp / 2) * Math.sin(dp / 2) + Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
    return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
  /* initial true bearing from point 1 to point 2, degrees 0..360 */
  function bearing(lat1, lon1, lat2, lon2) {
    var p1 = lat1 * D2R, p2 = lat2 * D2R, dl = (lon2 - lon1) * D2R;
    var y = Math.sin(dl) * Math.cos(p2);
    var x = Math.cos(p1) * Math.sin(p2) - Math.sin(p1) * Math.cos(p2) * Math.cos(dl);
    return norm360(Math.atan2(y, x) * R2D);
  }
  function destination(lat, lon, brgDeg, distM) {
    var d = distM / R, b = brgDeg * D2R, p1 = lat * D2R, l1 = lon * D2R;
    var p2 = Math.asin(Math.sin(p1) * Math.cos(d) + Math.cos(p1) * Math.sin(d) * Math.cos(b));
    var l2 = l1 + Math.atan2(Math.sin(b) * Math.sin(d) * Math.cos(p1), Math.cos(d) - Math.sin(p1) * Math.sin(p2));
    return [p2 * R2D, norm180(l2 * R2D)];
  }
  function pathLength(pts) { // pts: [[lat,lon],...]
    var s = 0;
    for (var i = 1; i < pts.length; i++) s += distance(pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1]);
    return s;
  }

  var CARD16 = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  function cardinal(deg) { return CARD16[Math.round(norm360(deg) / 22.5) % 16]; }

  /* ---------- coordinate formatting ---------- */
  function pad(n, w) { var s = String(n); while (s.length < w) s = '0' + s; return s; }
  function dms(v, isLat) {
    var h = isLat ? (v >= 0 ? 'N' : 'S') : (v >= 0 ? 'E' : 'W');
    var a = Math.abs(v);
    var d = Math.floor(a), mFull = (a - d) * 60, m = Math.floor(mFull), s = (mFull - m) * 60;
    s = Math.round(s * 10) / 10;
    if (s >= 60) { s = 0; m += 1; }
    if (m >= 60) { m = 0; d += 1; }
    return d + '°' + pad(m, 2) + '′' + (s < 10 ? '0' : '') + s.toFixed(1) + '″' + h;
  }
  function ddm(v, isLat) {
    var h = isLat ? (v >= 0 ? 'N' : 'S') : (v >= 0 ? 'E' : 'W');
    var a = Math.abs(v), d = Math.floor(a), m = Math.round((a - d) * 60 * 1000) / 1000;
    if (m >= 60) { m = 0; d += 1; }
    return h + ' ' + pad(d, isLat ? 2 : 3) + '°' + (m < 10 ? '0' : '') + m.toFixed(3) + '′';
  }
  /* fmt: 'dd' | 'dms' | 'ddm' */
  function formatLatLon(lat, lon, fmt) {
    if (lat == null || lon == null || isNaN(lat) || isNaN(lon)) return '—';
    if (fmt === 'dms') return dms(lat, true) + ' ' + dms(lon, false);
    if (fmt === 'ddm') return ddm(lat, true) + ' ' + ddm(lon, false);
    return lat.toFixed(5) + ', ' + lon.toFixed(5);
  }

  /* ---------- UTM (WGS84) ---------- */
  var WGS_A = 6378137, WGS_F = 1 / 298.257223563, K0 = 0.9996;
  var E = Math.sqrt(WGS_F * (2 - WGS_F));
  var N_ = WGS_F / (2 - WGS_F), n2 = N_ * N_, n3 = n2 * N_, n4 = n3 * N_, n5 = n4 * N_, n6 = n5 * N_;
  var AA = WGS_A / (1 + N_) * (1 + n2 / 4 + n4 / 64 + n6 / 256);
  var ALPHA = [0,
    1 / 2 * N_ - 2 / 3 * n2 + 5 / 16 * n3 + 41 / 180 * n4 - 127 / 288 * n5 + 7891 / 37800 * n6,
    13 / 48 * n2 - 3 / 5 * n3 + 557 / 1440 * n4 + 281 / 630 * n5 - 1983433 / 1935360 * n6,
    61 / 240 * n3 - 103 / 140 * n4 + 15061 / 26880 * n5 + 167603 / 181440 * n6,
    49561 / 161280 * n4 - 179 / 168 * n5 + 6601661 / 7257600 * n6,
    34729 / 80640 * n5 - 3418889 / 1995840 * n6,
    212378941 / 319334400 * n6];
  var BETA = [0,
    1 / 2 * N_ - 2 / 3 * n2 + 37 / 96 * n3 - 1 / 360 * n4 - 81 / 512 * n5 + 96199 / 604800 * n6,
    1 / 48 * n2 + 1 / 15 * n3 - 437 / 1440 * n4 + 46 / 105 * n5 - 1118711 / 3870720 * n6,
    17 / 480 * n3 - 37 / 840 * n4 - 209 / 4480 * n5 + 5569 / 90720 * n6,
    4397 / 161280 * n4 - 11 / 504 * n5 - 830251 / 7257600 * n6,
    4583 / 161280 * n5 - 108847 / 3991680 * n6,
    20648693 / 638668800 * n6];
  var BANDS = 'CDEFGHJKLMNPQRSTUVWXX'; // 8° bands from 80°S; X is 12° (72–84°N)

  function latBand(lat) { return BANDS.charAt(Math.floor(lat / 8 + 10)); }
  function utmZoneFor(lat, lon) {
    var zone = Math.floor((norm180(lon) + 180) / 6) + 1;
    if (zone > 60) zone = 60;
    var band = latBand(lat);
    if (zone === 31 && band === 'V' && lon >= 3) zone++;              // Norway
    if (band === 'X') {                                                // Svalbard
      if (zone === 32) zone = lon < 9 ? 31 : 33;
      if (zone === 34) zone = lon < 21 ? 33 : 35;
      if (zone === 36) zone = lon < 33 ? 35 : 37;
    }
    return zone;
  }
  /* forceZone is optional (used to draw a grid across a zone edge). */
  function toUTM(lat, lon, forceZone) {
    if (lat < -80 || lat > 84) return null; // UTM undefined: polar (UPS) regions
    var zone = forceZone || utmZoneFor(lat, lon);
    var lam0 = ((zone - 1) * 6 - 180 + 3) * D2R;
    var phi = lat * D2R, lam = norm180(lon) * D2R - lam0;
    if (lam > Math.PI) lam -= 2 * Math.PI; if (lam < -Math.PI) lam += 2 * Math.PI;
    var cosl = Math.cos(lam), sinl = Math.sin(lam);
    var tau = Math.tan(phi);
    var sigma = Math.sinh(E * Math.atanh(E * tau / Math.sqrt(1 + tau * tau)));
    var taup = tau * Math.sqrt(1 + sigma * sigma) - sigma * Math.sqrt(1 + tau * tau);
    var xip = Math.atan2(taup, cosl);
    var etap = Math.asinh(sinl / Math.sqrt(taup * taup + cosl * cosl));
    var xi = xip, eta = etap;
    for (var j = 1; j <= 6; j++) {
      xi += ALPHA[j] * Math.sin(2 * j * xip) * Math.cosh(2 * j * etap);
      eta += ALPHA[j] * Math.cos(2 * j * xip) * Math.sinh(2 * j * etap);
    }
    var x = K0 * AA * eta + 500000;
    var y = K0 * AA * xi;
    var hemi = lat >= 0 ? 'N' : 'S';
    if (y < 0) y += 10000000;
    return { zone: zone, band: latBand(lat), hemi: hemi, easting: x, northing: y };
  }
  function fromUTM(zone, hemi, easting, northing) {
    var x = easting - 500000, y = hemi === 'S' ? northing - 10000000 : northing;
    var eta = x / (K0 * AA), xi = y / (K0 * AA);
    var xip = xi, etap = eta;
    for (var j = 1; j <= 6; j++) {
      xip -= BETA[j] * Math.sin(2 * j * xi) * Math.cosh(2 * j * eta);
      etap -= BETA[j] * Math.cos(2 * j * xi) * Math.sinh(2 * j * eta);
    }
    var sinhEtap = Math.sinh(etap), sinXip = Math.sin(xip), cosXip = Math.cos(xip);
    var taup = sinXip / Math.sqrt(sinhEtap * sinhEtap + cosXip * cosXip);
    var taui = taup, dTau, guard = 0;
    do {
      var sigmai = Math.sinh(E * Math.atanh(E * taui / Math.sqrt(1 + taui * taui)));
      var tauip = taui * Math.sqrt(1 + sigmai * sigmai) - sigmai * Math.sqrt(1 + taui * taui);
      dTau = (taup - tauip) / Math.sqrt(1 + tauip * tauip) * (1 + (1 - E * E) * taui * taui) / ((1 - E * E) * Math.sqrt(1 + taui * taui));
      taui += dTau;
    } while (Math.abs(dTau) > 1e-12 && ++guard < 20);
    var lat = Math.atan(taui) * R2D;
    var lon = (Math.atan2(sinhEtap, cosXip) + ((zone - 1) * 6 - 180 + 3) * D2R) * R2D;
    return [lat, norm180(lon)];
  }
  function formatUTM(lat, lon) {
    var u = toUTM(lat, lon);
    if (!u) return 'n/a (polar)';
    return u.zone + u.band + ' ' + Math.floor(u.easting) + 'mE ' + Math.floor(u.northing) + 'mN';
  }

  /* ---------- MGRS (bundled library) ---------- */
  function toMGRS(lat, lon, digits) {
    if (!window.mgrs || lat < -80 || lat > 84) return null;
    try {
      var s = window.mgrs.forward([lon, lat], digits == null ? 5 : digits);
      return s;
    } catch (e) { return null; }
  }
  /* "18TWL8395907523" -> "18T WL 83959 07523" */
  function spaceMGRS(s) {
    if (!s) return 'n/a';
    var m = /^(\d{1,2}[A-Z])([A-Z]{2})(\d*)$/.exec(s);
    if (!m) return s;
    var d = m[3], h = d.length / 2;
    return m[1] + ' ' + m[2] + (d ? ' ' + d.slice(0, h) + ' ' + d.slice(h) : '');
  }

  /* ---------- parse user-typed coordinates ----------
     Accepts:  40.7128, -74.0060   |  40.7128 N 74.0060 W
               40°42'46"N 74°00'22"W  |  N40 42.768 W074 00.360
               18T WL 83959 07523 (MGRS)  |  18T 583959 4507523 (UTM, band letter)
     Returns [lat, lon] or null. */
  function parseCoords(input) {
    if (!input) return null;
    var s = String(input).trim().toUpperCase();
    // MGRS
    var compact = s.replace(/\s+/g, '');
    if (/^\d{1,2}[C-HJ-NP-X][A-HJ-NP-Z]{2}(\d{2}|\d{4}|\d{6}|\d{8}|\d{10})$/.test(compact) && window.mgrs) {
      try { var p = window.mgrs.toPoint(compact); return [p[1], p[0]]; } catch (e) { return null; }
    }
    // UTM: zone + band, easting, northing
    var um = /^(\d{1,2})\s*([C-HJ-NP-X])\s+(\d{5,7}(?:\.\d+)?)\s*M?E?\s*[, ]\s*(\d{6,8}(?:\.\d+)?)\s*M?N?$/.exec(s);
    if (um) {
      var z = +um[1], band = um[2];
      if (z >= 1 && z <= 60) return fromUTM(z, band >= 'N' ? 'N' : 'S', +um[3], +um[4]);
    }
    s = s.replace(/[°º˚]/g, ' ').replace(/[′'’`]/g, ' ').replace(/[″"”]/g, ' ').replace(/\s+/g, ' ');
    function partValue(numStr) {
      var nums = numStr.match(/-?\d+(?:\.\d+)?/g);
      if (!nums || nums.length > 3) return NaN;
      var neg = nums[0].charAt(0) === '-';
      var v = Math.abs(+nums[0]) + (nums[1] ? +nums[1] / 60 : 0) + (nums[2] ? +nums[2] / 3600 : 0);
      if ((nums[1] && +nums[1] >= 60) || (nums[2] && +nums[2] >= 60)) return NaN;
      return neg ? -v : v;
    }
    var lat, lon;
    if (/[NSEW]/.test(s)) {
      var parts = [], m, re;
      if (/^[NSEW]/.test(s)) { re = /([NSEW])\s*([-\d.\s]+)/g; while ((m = re.exec(s))) parts.push({ h: m[1], v: m[2] }); }
      else { re = /([-\d.\s]+?)\s*([NSEW])/g; while ((m = re.exec(s))) parts.push({ h: m[2], v: m[1] }); }
      if (parts.length !== 2) return null;
      parts.forEach(function (pt) {
        var v = Math.abs(partValue(pt.v.replace(/,/g, ' ')));
        if (pt.h === 'S' || pt.h === 'W') v = -v;
        if (pt.h === 'N' || pt.h === 'S') lat = v; else lon = v;
      });
    } else {
      var nums = s.match(/-?\d+(?:\.\d+)?/g);
      if (!nums || [2, 4, 6].indexOf(nums.length) < 0) return null;
      var half = nums.length / 2;
      lat = partValue(nums.slice(0, half).join(' '));
      lon = partValue(nums.slice(half).join(' '));
    }
    if (lat == null || lon == null || isNaN(lat) || isNaN(lon) || Math.abs(lat) > 90 || Math.abs(lon) > 180) return null;
    return [lat, lon];
  }

  /* ---------- resection (triangulation from bearings to known landmarks) ----------
     obs: [{lat, lon, bearing}]  bearing = TRUE bearing FROM you TO the landmark.
     You stand on the back-bearing line from each landmark. Lines are solved by
     least squares on a local flat projection (fine for landmarks within ~30 km).
     Returns { lat, lon, residual (m), triangle:[[lat,lon]...] | null, warnings[] } */
  function resection(obs) {
    if (!obs || obs.length < 2) throw new Error('Need at least 2 landmarks with bearings');
    var lat0 = 0, lon0 = 0;
    obs.forEach(function (o) { lat0 += o.lat; lon0 += o.lon; });
    lat0 /= obs.length; lon0 /= obs.length;
    var kx = Math.cos(lat0 * D2R) * R * D2R, ky = R * D2R;
    function toXY(lat, lon) { return [(lon - lon0) * kx, (lat - lat0) * ky]; }
    function toLL(x, y) { return [lat0 + y / ky, lon0 + x / kx]; }
    var lines = obs.map(function (o) {
      var b = (o.bearing + 180) * D2R;                // back-bearing direction
      var p = toXY(o.lat, o.lon), d = [Math.sin(b), Math.cos(b)];
      return { p: p, d: d, n: [-d[1], d[0]] };
    });
    // normal equations  (Σ n nᵀ) X = Σ n (n·p)
    var a11 = 0, a12 = 0, a22 = 0, b1 = 0, b2 = 0;
    lines.forEach(function (L) {
      var c = L.n[0] * L.p[0] + L.n[1] * L.p[1];
      a11 += L.n[0] * L.n[0]; a12 += L.n[0] * L.n[1]; a22 += L.n[1] * L.n[1];
      b1 += L.n[0] * c; b2 += L.n[1] * c;
    });
    var det = a11 * a22 - a12 * a12;
    if (Math.abs(det) < 0.02 * obs.length) throw new Error('Bearing lines are nearly parallel. Pick landmarks that are 60–120° apart.');
    var X = [(b1 * a22 - b2 * a12) / det, (a11 * b2 - a12 * b1) / det];
    var warnings = [], resid = 0;
    lines.forEach(function (L, i) {
      var t = (X[0] - L.p[0]) * L.d[0] + (X[1] - L.p[1]) * L.d[1];
      if (t < 0) warnings.push('Landmark ' + (i + 1) + ': the fix lies on the wrong side of it — check that bearing (you may have entered a back-bearing).');
      var dist = Math.abs((X[0] - L.p[0]) * L.n[0] + (X[1] - L.p[1]) * L.n[1]);
      resid = Math.max(resid, dist);
    });
    var tri = null;
    if (lines.length === 3) {
      tri = [];
      for (var i = 0; i < 3; i++) {
        var A = lines[i], B = lines[(i + 1) % 3];
        var den = A.d[0] * B.d[1] - A.d[1] * B.d[0];
        if (Math.abs(den) < 1e-9) { tri = null; break; }
        var t = ((B.p[0] - A.p[0]) * B.d[1] - (B.p[1] - A.p[1]) * B.d[0]) / den;
        tri.push(toLL(A.p[0] + t * A.d[0], A.p[1] + t * A.d[1]));
      }
    }
    var ll = toLL(X[0], X[1]);
    return { lat: ll[0], lon: ll[1], residual: resid, triangle: tri, warnings: warnings };
  }

  /* ---------- units ---------- */
  function fmtDist(m, units) {
    if (m == null || isNaN(m)) return '—';
    if (units === 'imperial') {
      var ft = m * 3.28084;
      if (ft < 1000) return Math.round(ft) + ' ft';
      var mi = m / 1609.344;
      return (mi < 10 ? mi.toFixed(2) : mi < 100 ? mi.toFixed(1) : Math.round(mi)) + ' mi';
    }
    if (m < 1000) return Math.round(m) + ' m';
    var km = m / 1000;
    return (km < 10 ? km.toFixed(2) : km < 100 ? km.toFixed(1) : Math.round(km)) + ' km';
  }
  function fmtAlt(m, units) {
    if (m == null || isNaN(m)) return '—';
    return units === 'imperial' ? Math.round(m * 3.28084) + ' ft' : Math.round(m) + ' m';
  }
  function fmtSpeed(ms, units) {
    if (ms == null || isNaN(ms)) return '—';
    return units === 'imperial' ? (ms * 2.236936).toFixed(1) + ' mph' : (ms * 3.6).toFixed(1) + ' km/h';
  }
  function fmtDuration(ms) {
    if (ms == null || isNaN(ms) || ms < 0) return '—';
    var s = Math.round(ms / 1000), h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
    if (h) return h + 'h ' + pad(m, 2) + 'm';
    return m + 'm ' + pad(s % 60, 2) + 's';
  }
  function fmtBearing(deg) {
    if (deg == null || isNaN(deg)) return '—';
    return pad(Math.round(norm360(deg)) % 360, 3) + '° ' + cardinal(deg);
  }

  /* NATO phonetic spelling, for reading a grid reference over a radio. */
  var NATO = { A: 'Alfa', B: 'Bravo', C: 'Charlie', D: 'Delta', E: 'Echo', F: 'Foxtrot', G: 'Golf', H: 'Hotel', I: 'India', J: 'Juliett', K: 'Kilo', L: 'Lima', M: 'Mike', N: 'November', O: 'Oscar', P: 'Papa', Q: 'Quebec', R: 'Romeo', S: 'Sierra', T: 'Tango', U: 'Uniform', V: 'Victor', W: 'Whiskey', X: 'X-ray', Y: 'Yankee', Z: 'Zulu', '0': 'Zero', '1': 'One', '2': 'Two', '3': 'Tree', '4': 'Fower', '5': 'Fife', '6': 'Six', '7': 'Seven', '8': 'Eight', '9': 'Niner', '.': 'Decimal', '-': 'Minus' };
  function phonetic(str) {
    return String(str).toUpperCase().split('').map(function (c) { return NATO[c] || (c === ' ' ? '/' : ''); })
      .filter(Boolean).join(' ').replace(/ \/ /g, ' · ').replace(/(^\/ |\/$)/g, '');
  }

  window.OGGeo = {
    R: R, distance: distance, bearing: bearing, destination: destination, pathLength: pathLength,
    norm360: norm360, norm180: norm180, cardinal: cardinal,
    formatLatLon: formatLatLon, dms: dms, ddm: ddm,
    toUTM: toUTM, fromUTM: fromUTM, utmZoneFor: utmZoneFor, formatUTM: formatUTM,
    toMGRS: toMGRS, spaceMGRS: spaceMGRS, parseCoords: parseCoords, resection: resection,
    fmtDist: fmtDist, fmtAlt: fmtAlt, fmtSpeed: fmtSpeed, fmtDuration: fmtDuration, fmtBearing: fmtBearing,
    phonetic: phonetic
  };
})();
