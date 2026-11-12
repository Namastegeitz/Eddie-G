// Layout check on emulated iPhones, iPads, an Android phone and tablet (portrait + landscape) and with
// Extra-large text: fails if any page scrolls sideways or a control is under 44 px tall.
// Run from the app folder with the app served on :8765:  node tests/devices.js
const { chromium, devices } = require('playwright');
let failures = 0;
const PAGES = ['index.html', 'map/index.html', 'compass/index.html', 'firstaid/index.html', 'plan/index.html'];
const RUNS = [['iPhone SE', 'normal'], ['iPhone 15 Pro Max', 'normal'], ['iPad (gen 7)', 'normal'], ['iPad (gen 7) landscape', 'normal'], ['Galaxy Tab S4', 'normal'], ['Galaxy Tab S4 landscape', 'normal'], ['Pixel 7', 'normal'], ['iPhone SE', 'xl']];
(async () => {
  const b = await chromium.launch();
  for (const [dev, ts] of RUNS) {
    const d = devices[dev];
    if (!d) { console.log('no device', dev); continue; }
    const ctx = await b.newContext({ ...d, serviceWorkers: 'block', geolocation: { latitude: 40.3573, longitude: -74.6672 }, permissions: ['geolocation'] });
    await ctx.addInitScript(t => { try { localStorage.setItem('ogsk.textsize', t); } catch (e) {} }, ts);
    const p = await ctx.newPage();
    const errs = []; p.on('pageerror', e => errs.push(e.message));
    const res = [];
    for (const pg of PAGES) {
      await p.goto('http://127.0.0.1:8765/' + pg); await p.waitForTimeout(pg.startsWith('map') ? 2500 : 700);
      const m = await p.evaluate(() => {
        const W = document.documentElement.clientWidth;
        const over = document.scrollingElement.scrollWidth - W;
        // interactive controls (not inline text links) smaller than 44 CSS px in either dimension
        const small = [...document.querySelectorAll('button, .btn, .fab, .hdr-btn, input[type=checkbox], input[type=radio], select, summary, nav.toc a, .hub-tile')]
          .filter(e => { const r = e.getBoundingClientRect(); const cs = getComputedStyle(e); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && (r.height < 44 || r.width < 24) && !e.closest('[hidden]') && !e.closest('.leaflet-control-attribution'); })
          .map(e => (e.id || e.className || e.tagName).toString().slice(0, 30) + ':' + Math.round(e.getBoundingClientRect().height));
        return { over, small: small.slice(0, 5), nSmall: small.length };
      });
      res.push(`${pg.split('/')[0] || 'hub'} over=${m.over}${m.nSmall ? ' small=' + m.nSmall + ' ' + m.small.join(',') : ''}`);
      if (m.over > 0 || m.nSmall) failures++;
    }
    console.log(`${dev} [${ts}] ${d.viewport.width}x${d.viewport.height}: ` + res.join(' | ') + (errs.length ? ' ERR ' + errs.join(';') : ''));
    await ctx.close();
  }
  await b.close();
  console.log(failures ? failures + ' page checks FAILED' : 'ALL DEVICE CHECKS PASSED');
  process.exit(failures ? 1 : 0);
})();
