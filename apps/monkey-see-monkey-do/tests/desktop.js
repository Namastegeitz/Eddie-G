// PC edition check: launches the real desktop app (release/05-desktop) in
// Electron and plays a little: 3D works, no Shop, version, keyboard and a game
// controller play moves, F11 full screen, no errors.
//   node scripts/build_release.mjs           (makes release/05-desktop/app)
//   ELECTRON=/path/to/electron node tests/desktop.js
// On Linux without a screen: xvfb-run -a node tests/desktop.js
const { _electron: electron } = require('playwright');
const path = require('path');
const fs = require('fs');

const DESKTOP = path.join(__dirname, '..', 'release', '05-desktop');
const OUT = path.join(__dirname, 'output', 'desktop');
fs.mkdirSync(OUT, { recursive: true });
const EXE = process.env.ELECTRON || path.join(DESKTOP, 'node_modules', 'electron', 'dist', 'electron');
let pass = 0;
let fail = 0;
const expect = (c, m) => { if (!c) throw new Error(m); };

(async () => {
  if (!fs.existsSync(path.join(DESKTOP, 'app', 'index.html'))) throw new Error('release/05-desktop/app is missing: run node scripts/build_release.mjs');
  const app = await electron.launch({
    executablePath: EXE,
    args: [DESKTOP, '--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
  });
  await app.context().addInitScript(() => {
    window.__pad = { id: 'Xbox Wireless Controller (STANDARD GAMEPAD)', index: 0, connected: true, mapping: 'standard', axes: [0, 0, 0, 0], buttons: Array.from({ length: 17 }, () => ({ pressed: false, value: 0 })) };
    navigator.getGamepads = () => [window.__pad];
  });
  const win = await app.firstWindow();
  const errors = [];
  win.on('pageerror', (e) => errors.push(e.message));
  const run = async (name, fn) => {
    try { await fn(); pass++; console.log('✓', name); } catch (e) { fail++; console.log('✗', name, '-', e.message.split('\n')[0]); }
  };

  await run('opens the game in its own window with 3D graphics', async () => {
    await win.reload(); // so the pretend controller is in place
    await win.waitForSelector('html[data-ready="1"]', { timeout: 120000 });
    const r = await win.evaluate(() => ({ v: MSMD.version, gl: MSMD.webgl, pc: document.documentElement.classList.contains('edition-pc'), edition: MSMD.app.edition }));
    const electronVersion = await app.evaluate(({ app: a }) => process.versions.electron);
    console.log('  Electron', electronVersion, '· game', r.v, '· WebGL', r.gl);
    expect(r.gl >= 1 && r.pc && r.edition === 'pc', JSON.stringify(r));
    await win.screenshot({ path: path.join(OUT, 'title.png') });
  });

  await run('PC edition: no Shop, no purchase settings', async () => {
    const r = await win.evaluate(() => {
      const shop = getComputedStyle(document.querySelector('#scr-title .mini[data-go="store"]')).display;
      MSMD.ui.show('settings');
      const text = document.getElementById('settings-body').textContent;
      MSMD.ui.show('title');
      return { shop, purchases: text.includes('Monthly limit'), restore: !!document.querySelector('#act-restore') };
    });
    expect(r.shop === 'none' && !r.purchases && !r.restore, JSON.stringify(r));
  });

  await run('keyboard and game controller play moves', async () => {
    await win.click('#btn-free');
    await win.waitForFunction(() => MSMD.game.mode === 'free', null, { timeout: 30000 });
    await win.keyboard.press('q');
    await win.waitForFunction(() => MSMD.game.run.moves >= 1, null, { timeout: 15000 });
    await win.evaluate(() => { window.__pad.buttons[5] = { pressed: true, value: 1 }; });
    await win.waitForFunction(() => MSMD.game.run.moves >= 2, null, { timeout: 20000 });
    await win.evaluate(() => { window.__pad.buttons[5] = { pressed: false, value: 0 }; });
    await win.screenshot({ path: path.join(OUT, 'free-dance.png') });
  });

  await run('F11 toggles full screen', async () => {
    // send F11 through the browser's own input path, like a real keyboard
    // (Playwright's key presses skip the main process's before-input-event)
    const f11 = () => app.evaluate(({ BrowserWindow }) => BrowserWindow.getAllWindows()[0].webContents.sendInputEvent({ type: 'keyDown', keyCode: 'F11' }));
    await f11();
    await win.waitForTimeout(1500);
    const full = await app.evaluate(({ BrowserWindow }) => BrowserWindow.getAllWindows()[0].isFullScreen());
    await f11();
    await win.waitForTimeout(1500);
    const back = await app.evaluate(({ BrowserWindow }) => BrowserWindow.getAllWindows()[0].isFullScreen());
    expect(full === true && back === false, `full screen after F11: ${full}, back after a second F11: ${!back}`);
  });

  await run('no errors', async () => {
    expect(errors.length === 0, errors.join(' | '));
  });

  await app.close();
  console.log(`\nDesktop (PC edition): ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})();
