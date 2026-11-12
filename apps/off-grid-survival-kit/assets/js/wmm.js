/* =====================================================================
   World Magnetic Model 2025 (WMM2025) — magnetic declination on the device
   ---------------------------------------------------------------------
   NOAA NCEI / British Geological Survey model, valid 2025.0 – 2030.0.
   Coefficients: WMM2025 (degree/order 12), indexed n(n+1)/2 + m.
   Implementation: spherical-harmonic synthesis with Schmidt semi-normalised
   Legendre functions, geodetic <-> geocentric conversion on WGS84.
   Verified against the official WMM2025 test values (see tests/wmm.test.js).
   Public domain model data (US Government work).

   OGWMM.declination(lat, lon, altKm?, date?) -> degrees, East positive
   OGWMM.field(lat, lon, altKm?, date?)       -> {x, y, z, h, f, incl, decl, year, valid}
   ===================================================================== */
(function () {
  'use strict';
  var EPOCH = 2025.0, NMAX = 12;
  var G = [0,-29351.8,-1410.8,-2556.6,2951.1,1649.3,1361,-2404.1,1243.8,453.6,895,799.5,55.7,-281.1,12.1,-233.2,368.9,187.2,-138.7,-142,20.9,64.4,63.8,76.9,-115.7,-40.9,14.9,-60.7,79.5,-77,-8.8,59.3,15.8,2.5,-11.1,14.2,23.2,10.8,-17.5,2,-21.7,16.9,15,-16.8,0.9,4.6,7.8,3,-0.2,-2.5,-13.1,2.4,8.6,-8.7,-12.9,-1.3,-6.4,0.2,2,-1,-0.6,-0.9,1.5,0.9,-2.7,-3.9,2.9,-1.5,-2.5,2.4,-0.6,-0.1,-0.6,-0.1,1.1,-1,-0.2,2.6,-2,-0.2,0.3,1.2,-1.3,0.6,0.6,0.5,-0.1,-0.4,-0.2,-1.3,-0.7];
  var H = [0,0,4545.4,0,-3133.6,-815.1,0,-56.6,237.5,-549.5,0,278.6,-133.9,212,-375.6,0,45.4,220.2,-122.9,43,106.1,0,-18.4,16.8,48.8,-59.8,10.9,72.7,0,-48.9,-14.4,-1,23.4,-7.4,-25.1,-2.3,0,7.1,-12.6,11.4,-9.7,12.7,0.7,-5.2,3.9,0,-24.8,12.2,8.3,-3.3,-5.2,7.2,-0.6,0.8,10,0,3.3,0,2.4,5.3,-9.1,0.4,-4.2,-3.8,0.9,-9.1,0,0,2.9,-0.6,0.2,0.5,-0.3,-1.2,-1.7,-2.9,-1.8,-2.3,0,-1.3,0.7,1,-1.4,0,0.6,-0.1,0.8,0.1,-1,0.1,0.2];
  var GD = [0,12,9.7,-11.6,-5.2,-8,-1.3,-4.2,0.4,-15.6,-1.6,-2.4,-6,5.6,-7,0.6,1.4,0,0.6,2.2,0.9,-0.2,-0.4,0.9,1.2,-0.9,0.3,0.9,0,-0.1,-0.1,0.5,-0.1,-0.8,-0.8,0.8,-0.1,0.2,0,0.5,-0.1,0.3,0.2,0,0.2,0,-0.1,0.1,0.3,-0.3,0,0.3,-0.1,0.1,-0.1,0.1,0,0.1,0.1,0,-0.3,0,-0.1,-0.1,0,0,0,0,0,0,0,-0.1,0,0,-0.1,-0.1,-0.1,-0.1,0,0,0,0,0,0,0.1,0,0,0,-0.1,0,-0.1];
  var HD = [0,0,-21.5,0,-27.7,-12.1,0,4,-0.3,-4.1,0,-1.1,4.1,1.6,-4.4,0,-0.5,2.2,0.4,1.7,1.9,0,0.3,-1.6,-0.4,0.9,0.7,0.9,0,0.6,0.5,-0.8,0,-1,0.6,-0.2,0,-0.2,0.5,-0.4,0.4,-0.5,-0.6,0.3,0.2,0,-0.3,0.3,-0.3,0.3,0.2,-0.1,-0.2,0.4,0.1,0,0,0,-0.2,0.1,-0.1,0.1,0,-0.1,0.2,0,0,0,0.1,0,0.1,0,0,0.1,0,0,0,0,0,0,0,-0.1,0.1,0,0,0,0,0,0,0,-0.1];
  var A = 6378.137, F = 1 / 298.257223563, E2 = F * (2 - F), RE = 6371.2;
  var D2R = Math.PI / 180, R2D = 180 / Math.PI;

  function decimalYear(date) {
    var d = date || new Date(), y = d.getUTCFullYear();
    var start = Date.UTC(y, 0, 1), end = Date.UTC(y + 1, 0, 1);
    return y + (d.getTime() - start) / (end - start);
  }

  function field(lat, lon, altKm, date) {
    var year = typeof date === 'number' ? date : decimalYear(date);
    var dt = year - EPOCH;
    var phi = lat * D2R, lam = lon * D2R, h = altKm || 0;
    // geodetic -> geocentric spherical
    var sphi = Math.sin(phi), cphi = Math.cos(phi);
    var Rc = A / Math.sqrt(1 - E2 * sphi * sphi);
    var p = (Rc + h) * cphi, z = (Rc * (1 - E2) + h) * sphi;
    var r = Math.sqrt(p * p + z * z);
    var phic = Math.asin(z / r);
    var ct = Math.sin(phic), st = Math.cos(phic);   // theta = colatitude
    if (st < 1e-10) st = 1e-10;                     // pole guard
    // Schmidt semi-normalised P and dP/dtheta
    var P = [], dP = [];
    for (var n = 0; n <= NMAX; n++) { P.push(new Array(n + 1).fill(0)); dP.push(new Array(n + 1).fill(0)); }
    P[0][0] = 1; dP[0][0] = 0;
    for (n = 1; n <= NMAX; n++) {
      for (var m = 0; m <= n; m++) {
        if (n === m) {
          if (n === 1) { P[1][1] = st; dP[1][1] = ct; }
          else {
            var k = Math.sqrt((2 * n - 1) / (2 * n));
            P[n][n] = k * st * P[n - 1][n - 1];
            dP[n][n] = k * (ct * P[n - 1][n - 1] + st * dP[n - 1][n - 1]);
          }
        } else {
          var a1 = 2 * n - 1, a2 = n >= 2 && m <= n - 2 ? Math.sqrt((n - 1) * (n - 1) - m * m) : 0, den = Math.sqrt(n * n - m * m);
          var p2 = n >= 2 && m <= n - 2 ? P[n - 2][m] : 0, dp2 = n >= 2 && m <= n - 2 ? dP[n - 2][m] : 0;
          P[n][m] = (a1 * ct * P[n - 1][m] - a2 * p2) / den;
          dP[n][m] = (a1 * (ct * dP[n - 1][m] - st * P[n - 1][m]) - a2 * dp2) / den;
        }
      }
    }
    var X = 0, Y = 0, Z = 0, ratio = RE / r, rn = ratio * ratio;   // (Re/r)^(n+2), starting at n=0
    for (n = 1; n <= NMAX; n++) {
      rn *= ratio;
      for (m = 0; m <= n; m++) {
        var i = n * (n + 1) / 2 + m;
        var g = G[i] + dt * GD[i], hh = H[i] + dt * HD[i];
        var cm = Math.cos(m * lam), sm = Math.sin(m * lam);
        X += rn * (g * cm + hh * sm) * dP[n][m];
        Y += rn * m * (g * sm - hh * cm) * P[n][m];
        Z -= rn * (n + 1) * (g * cm + hh * sm) * P[n][m];
      }
    }
    Y /= st;
    // rotate from geocentric to geodetic
    var psi = phic - phi, cps = Math.cos(psi), sps = Math.sin(psi);
    var x = X * cps - Z * sps, zz = X * sps + Z * cps, y = Y;
    var hor = Math.sqrt(x * x + y * y);
    return {
      x: x, y: y, z: zz, h: hor, f: Math.sqrt(hor * hor + zz * zz),
      incl: Math.atan2(zz, hor) * R2D, decl: Math.atan2(y, x) * R2D,
      year: year, valid: year >= 2025 && year < 2030
    };
  }

  window.OGWMM = {
    model: 'WMM2025', validFrom: 2025.0, validTo: 2030.0,
    field: field,
    declination: function (lat, lon, altKm, date) { return field(lat, lon, altKm, date).decl; },
    decimalYear: decimalYear
  };
})();
