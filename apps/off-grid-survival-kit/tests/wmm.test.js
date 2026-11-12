// Verifies assets/js/wmm.js against the official WMM2025 test values.
// Run: node tests/wmm.test.js
const fs = require('fs'), path = require('path'), vm = require('vm');
const ctx = { window: {}, Math, Date, Array };
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../assets/js/wmm.js'), 'utf8'), ctx);
const W = ctx.window.OGWMM;
const rows = fs.readFileSync(path.join(__dirname, 'wmm2025_test_values.csv'), 'utf8').trim().split('\n');
const hdr = rows.shift().split(',');
let worst = { decl: 0, incl: 0, f: 0 }, fails = 0;
for (const line of rows) {
  const v = Object.fromEntries(line.split(',').map((x, i) => [hdr[i], parseFloat(x)]));
  const r = W.field(v.lat, v.lon, v.alt, v.date);
  const dd = Math.abs(((r.decl - v.decl + 540) % 360) - 180), di = Math.abs(r.incl - v.incl), df = Math.abs(r.f - v.f);
  worst.decl = Math.max(worst.decl, dd); worst.incl = Math.max(worst.incl, di); worst.f = Math.max(worst.f, df);
  if (dd > 0.01 || di > 0.01 || df > 5) { fails++; console.log('FAIL', line, '->', r.decl.toFixed(3), r.incl.toFixed(3), r.f.toFixed(1)); }
}
console.log(rows.length + ' WMM2025 test points; worst |ΔD| ' + worst.decl.toFixed(4) + '°, |ΔI| ' + worst.incl.toFixed(4) + '°, |ΔF| ' + worst.f.toFixed(2) + ' nT');
console.log(fails ? fails + ' FAILED' : 'ALL PASS');
process.exit(fails ? 1 : 0);
