// Off-Grid Survival Kit — end-to-end acceptance test (Playwright + Chromium).
// 1) online: point the map at the mock tile server, prime tiles, save an area, add waypoints,
//    navigate, measure, record a track, export GPX/JSON;
// 2) OFFLINE: reload and check tiles, parent fallback, persistence, elevation, graticule,
//    UTM grid, QR, SOS beacon, triangulation, and that every page opens.
// Run (from the app folder):
//   python3 -m http.server 8765 --bind 127.0.0.1 &
//   python3 tests/mocktiles.py 8790 &
//   node tests/acceptance.js            (screenshots go to ./tests/output/)
const { chromium } = require('playwright');
const path = require('path');
const S = path.join(__dirname, 'output') + path.sep;
require('fs').mkdirSync(S, { recursive: true });
const BASE = process.env.BASE || 'http://127.0.0.1:8765/';
let failures = 0;
(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, geolocation: { latitude: 40.3573, longitude: -74.6672, accuracy: 8 }, permissions: ['geolocation'], serviceWorkers: 'allow' });
  const page = await ctx.newPage();
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push('PAGEERROR ' + e.message));
  const step = async (name, fn) => { try { await fn(); console.log('✓', name); } catch (e) { failures++; console.log('✗', name, '—', e.message.split('\n')[0]); } };

  await page.goto(BASE + 'map/index.html');
  await page.waitForSelector('html[data-map-ready="1"]', { timeout: 15000 });
  await step('switch to custom (mock) tile source + mock DEM', async () => {
    await page.evaluate(() => { MapApp.set('demUrl', 'http://127.0.0.1:8790/dem/{z}/{x}/{y}.png'); });
    await page.click('#fab-layers');
    await page.click('[data-src="custom"]');
    await page.fill('#custom-url', 'http://127.0.0.1:8790/{z}/{x}/{y}.png');
    await page.fill('#custom-name', 'Mock tiles');
    await page.fill('#custom-max', '18');
    await page.click('#custom-apply');
    await page.click('#drawer-close');
    await page.evaluate(() => MapApp.map.setView([40.3573, -74.6672], 13));
    await page.waitForTimeout(2500);
    const cov = await page.evaluate(() => MapApp.baseLayer.coverage());
    if (!cov.shown) throw new Error('no tiles shown ' + JSON.stringify(cov));
    const n = await page.evaluate(() => OGStore.count('tiles'));
    console.log('   tiles in view', JSON.stringify(cov), 'saved while browsing:', n);
  });
  await step('GPS fix + telemetry', async () => {
    await page.waitForFunction(() => MapApp.gps.fix, null, { timeout: 8000 });
    const t = await page.textContent('#tl-pos');
    console.log('   telemetry:', t, '| acc', await page.textContent('#tl-acc'), '| daylight', await page.textContent('#tl-daylight'));
  });
  await step('save area offline (+2 levels, with elevation)', async () => {
    await page.click('#fab-menu');
    await page.click('[data-tab="offline"]');
    await page.selectOption('#dl-levels', '2');
    await page.waitForTimeout(300);
    console.log('   estimate:', (await page.textContent('#dl-estimate')).replace(/\s+/g, ' ').trim());
    await page.click('#dl-start');
    await page.waitForFunction(() => /Done|Cancelled|Error/.test(document.getElementById('dl-status').textContent), null, { timeout: 60000 });
    console.log('   status:', await page.textContent('#dl-status'));
    await page.waitForTimeout(500);
    console.log('   stats:', (await page.textContent('#tile-stats')).replace(/\s+/g, ' '));
  });
  await step('add waypoint via editor', async () => {
    await page.click('#drawer-close');
    await page.click('#fab-pin');
    await page.fill('#wp-name', 'Spring by the oak');
    await page.check('input[name="wp-cat"][value="water"]', { force: true });
    await page.fill('#wp-note', 'flows year-round; filter + boil');
    await page.click('#wp-save');
    await page.waitForTimeout(500);
    const n = await page.evaluate(() => MapApp.wp.all().length);
    if (n < 1) throw new Error('waypoint not saved');
  });
  await step('second waypoint via coordinates + navigate', async () => {
    await page.click('#fab-pin');
    await page.fill('#wp-name', 'Rally A');
    await page.check('input[name="wp-cat"][value="rally"]', { force: true });
    await page.fill('#wp-coords', '40.3700, -74.6500');
    await page.click('#wp-save');
    await page.waitForTimeout(400);
    const id = await page.evaluate(() => MapApp.wp.all().find(w => w.name === 'Rally A').id);
    await page.evaluate((id) => MapApp.nav.start(MapApp.wp.get(id)), id);
    await page.waitForTimeout(400);
    console.log('   nav:', await page.textContent('#nav-dist'), '|', await page.textContent('#nav-brg'));
    await page.screenshot({ path: S + 'map-nav.png' });
  });
  await step('measure tool', async () => {
    await page.click('#fab-measure');
    const box = await page.locator('#map').boundingBox();
    await page.mouse.click(box.x + 200, box.y + 60);
    await page.mouse.click(box.x + 260, box.y + 110);
    await page.mouse.click(box.x + 170, box.y + 160);
    const total = await page.textContent('#ms-total'); if (/^0 m$/.test(total)) throw new Error('measure did not register taps');
    console.log('   measure total', await page.textContent('#ms-total'), 'leg', await page.textContent('#ms-leg'), await page.textContent('#ms-brg'));
    await page.screenshot({ path: S + 'map-measure.png' });
    await page.click('#ms-done');
  });
  await step('record a track (simulated walk)', async () => {
    await page.click('#fab-track');
    for (let i = 1; i <= 6; i++) {
      await ctx.setGeolocation({ latitude: 40.3573 + i * 0.0004, longitude: -74.6672 + i * 0.0003, accuracy: 6 });
      await page.waitForTimeout(450);
    }
    console.log('   track', await page.textContent('#trk-dist'), 'pts', await page.textContent('#trk-pts'));
    await page.click('#trk-save');
    await page.fill('#ask-input', 'Test walk');
    await page.click('#ask-ok');
    await page.waitForTimeout(500);
    const n = await page.evaluate(() => MapApp.tracks.all().length);
    if (!n) throw new Error('track not saved');
  });
  await step('contours overlay', async () => {
    await page.evaluate(() => { document.getElementById('ov-contours').click(); });
    await page.waitForTimeout(2500);
    await page.screenshot({ path: S + 'map-contours.png' });
  });
  await step('sun & moon panel', async () => {
    await page.click('#tl-sun');
    await page.waitForTimeout(300);
    console.log('   sun:', (await page.textContent('#sun-out')).replace(/\s+/g, ' ').slice(0, 300));
    await page.screenshot({ path: S + 'map-sun.png' });
  });
  await step('position / MGRS panel', async () => {
    await page.click('[data-tab="position"]');
    await page.waitForTimeout(800);
    console.log('   pos:', (await page.textContent('#pos-out')).replace(/\s+/g, ' ').slice(0, 400));
  });
  await step('export GPX + JSON', async () => {
    await page.click('[data-tab="data"]');
    const [dl] = await Promise.all([page.waitForEvent('download'), page.click('#gpx-export')]);
    const p = await dl.path(); const fs = require('fs'); const txt = fs.readFileSync(p, 'utf8');
    console.log('   gpx bytes', txt.length, 'wpt', (txt.match(/<wpt/g) || []).length, 'trkpt', (txt.match(/<trkpt/g) || []).length);
    const [dl2] = await Promise.all([page.waitForEvent('download'), page.click('#json-export')]);
    const j = JSON.parse(fs.readFileSync(await dl2.path(), 'utf8'));
    console.log('   json waypoints', j.waypoints.length, 'tracks', j.tracks.length, 'kv keys', Object.keys(j.kv).join(','));
  });

  // ---------------- OFFLINE ----------------
  await page.waitForTimeout(1500);
  const swOk = await page.evaluate(async () => { const r = await navigator.serviceWorker.ready; return !!r.active; });
  console.log('service worker active:', swOk);
  await ctx.setOffline(true);
  await step('reload map OFFLINE', async () => {
    await page.reload();
    await page.waitForSelector('html[data-map-ready="1"]', { timeout: 15000 });
    await page.evaluate(() => MapApp.map.setView([40.3573, -74.6672], 14));
    await page.waitForTimeout(2000);
    const cov = await page.evaluate(() => MapApp.baseLayer.coverage());
    const st = await page.evaluate(() => { const s = {}; for (const k in MapApp.baseLayer._tiles) { const t = MapApp.baseLayer._tiles[k]; if (t.current) s[t.el._og] = (s[t.el._og] || 0) + 1; } return s; });
    console.log('   offline coverage', JSON.stringify(cov), JSON.stringify(st), 'empty?', await page.evaluate(() => MapApp.tiles.empty));
    if (!cov.shown) throw new Error('no tiles offline');
    await page.screenshot({ path: S + 'map-offline.png' });
  });
  await step('offline: zoom past saved levels uses parent tiles', async () => {
    await page.evaluate(() => MapApp.map.setZoom(17));
    await page.waitForTimeout(1500);
    const st = await page.evaluate(() => { const s = {}; for (const k in MapApp.baseLayer._tiles) { const t = MapApp.baseLayer._tiles[k]; if (t.current) s[t.el._og] = (s[t.el._og] || 0) + 1; } return s; });
    console.log('   z17 statuses', JSON.stringify(st));
  });
  await step('offline: waypoints, tracks persisted', async () => {
    const r = await page.evaluate(() => ({ w: MapApp.wp.all().map(w => w.name), t: MapApp.tracks.all().map(t => t.name), nav: MapApp.nav.target && MapApp.nav.target.name }));
    console.log('   ', JSON.stringify(r));
    if (r.w.length < 2 || r.t.length < 1) throw new Error('data missing');
  });
  await step('offline: elevation at centre', async () => {
    await page.evaluate(() => MapApp.map.setZoom(13));
    await page.waitForTimeout(1200);
    console.log('   centre readout:', await page.textContent('#center-readout'));
  });
  await step('offline: graticule fallback where nothing saved', async () => {
    await page.evaluate(() => MapApp.map.setView([10, 20], 9));
    await page.waitForTimeout(1500);
    const e = await page.evaluate(() => MapApp.tiles.empty);
    console.log('   tiles.empty =', e);
    if (!e) throw new Error('not flagged empty');
    await page.screenshot({ path: S + 'map-graticule.png' });
    await page.evaluate(() => MapApp.map.setView([40.3573, -74.6672], 13));
  });
  await step('offline: UTM grid', async () => {
    await page.evaluate(() => MapApp.set('grid', 'utm'));
    await page.waitForTimeout(800);
    await page.screenshot({ path: S + 'map-utm.png' });
    await page.evaluate(() => MapApp.set('grid', 'auto'));
  });
  await step('offline: QR code', async () => {
    await page.click('#fab-sos');
    await page.waitForTimeout(300);
    const svg = await page.$('#qr-box svg');
    if (!svg) throw new Error('no QR');
    console.log('   qr text:', (await page.textContent('#qr-text')).slice(0, 80));
    await page.screenshot({ path: S + 'map-qr.png' });
  });
  await step('offline: SOS beacon', async () => {
    await page.click('#sos-open');
    await page.waitForTimeout(1300);
    console.log('   beacon:', await page.textContent('#sos-dd'), '|', await page.textContent('#sos-mgrs'));
    await page.screenshot({ path: S + 'map-sos.png' });
    await page.click('#sos-close');
  });
  await step('offline: triangulation', async () => {
    await page.click('#fab-menu'); await page.click('[data-tab="triangulate"]');
    await page.selectOption('#tri-type', 'true');
    await page.fill('#tri-ll-0', '40.3800, -74.6400'); await page.press('#tri-ll-0', 'Tab');
    await page.fill('#tri-b-0', '42'); await page.press('#tri-b-0', 'Tab');
    await page.fill('#tri-ll-1', '40.3400, -74.7000'); await page.press('#tri-ll-1', 'Tab');
    await page.fill('#tri-b-1', '232'); await page.press('#tri-b-1', 'Tab');
    await page.click('#tri-add');
    await page.fill('#tri-ll-2', '40.3300, -74.6500'); await page.press('#tri-ll-2', 'Tab');
    await page.fill('#tri-b-2', '153'); await page.press('#tri-b-2', 'Tab');
    await page.click('#tri-solve');
    await page.waitForTimeout(400);
    console.log('   tri:', (await page.textContent('#tri-out')).replace(/\s+/g, ' ').slice(0, 260));
    await page.screenshot({ path: S + 'map-tri.png' });
  });
  await step('offline: checklist item added and persists across an offline reload', async () => {
    await page.goto(BASE + 'tools/index.html');
    await page.click('#cl-templates [data-tpl="0"]');
    await page.waitForSelector('.cl-add-input');
    const input = page.locator('.cl-add-input').first();
    await input.fill('Offline test item');
    await input.press('Enter');
    await page.waitForTimeout(600);
    await page.reload();
    await page.waitForTimeout(800);
    const found = await page.evaluate(() => OGStore.all('checklists').then(ls => ls.some(l => l.items.some(i => i.text === 'Offline test item'))));
    const shown = await page.locator('text=Offline test item').count();
    console.log('   in IndexedDB:', found, '| on screen:', shown);
    if (!found || !shown) throw new Error('checklist item did not persist');
  });
  await step('offline: emergency PDF is available', async () => {
    await page.goto(BASE + 'emergency/index.html');
    const r = await page.evaluate(async () => { const res = await fetch('off-grid-emergency-guide.pdf'); const b = await res.arrayBuffer(); return [res.status, res.headers.get('content-type'), b.byteLength, String.fromCharCode(...new Uint8Array(b.slice(0, 5)))]; });
    console.log('   PDF:', JSON.stringify(r));
    if (r[0] !== 200 || r[3] !== '%PDF-') throw new Error('PDF not cached');
  });
  await step('offline: other pages open', async () => {
    for (const p of ['index.html', 'tools/index.html', 'water/index.html', 'foraging/index.html', 'firstaid/index.html', 'fireshelter/index.html', 'food/index.html', 'electricity/index.html', 'emergency/index.html']) {
      const r = await page.goto(BASE + p).catch(e => null);
      const title = await page.title().catch(() => '?');
      console.log('   ', p, r ? r.status() : 'FAILED', title);
      if (!r || r.status() !== 200) throw new Error(p + ' did not open offline');
      if (p !== 'index.html' && title === 'Off-Grid Survival Kit') throw new Error(p + ' fell back to the hub (not precached?)');
    }
  });
  // tile requests to public servers fail in sandboxes without internet — ignore those
  const real = errors.filter(e => !/ERR_TUNNEL|ERR_INTERNET_DISCONNECTED|ERR_PROXY|ERR_NAME_NOT_RESOLVED|tile\.openstreetmap|opentopomap/.test(e));
  console.log('console errors:', real.length ? real : 'none');
  await browser.close();
  console.log(failures ? failures + ' check(s) FAILED' : 'ALL CHECKS PASSED');
  process.exit(failures ? 1 : 0);
})();
