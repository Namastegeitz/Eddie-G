/* Alien Sudoku — Electron main process.
   Serves the web build from a private app:// scheme (stable origin, so saves
   in localStorage persist, and ES modules load without file:// CORS issues). */
const { app, BrowserWindow, protocol, net, shell, Menu, ipcMain } = require('electron');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const SMOKE = process.argv.includes('--smoke-test');
const APP_DIR = path.join(__dirname, 'app');

protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { standard: true, secure: true, supportFetchAPI: true, stream: true } },
]);

if (!SMOKE && !app.requestSingleInstanceLock()) app.quit();

let win = null;

function createWindow() {
  win = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 420,
    minHeight: 640,
    backgroundColor: '#05010f',
    title: 'Alien Sudoku',
    icon: path.join(__dirname, 'build', 'icon.png'),
    autoHideMenuBar: true,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      spellcheck: false,
    },
  });
  win.once('ready-to-show', () => { if (!SMOKE) win.show(); });

  // Keep navigation inside the game; open real links in the browser.
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:/.test(url)) shell.openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (e, url) => {
    if (!url.startsWith('app://')) { e.preventDefault(); if (/^https?:/.test(url)) shell.openExternal(url); }
  });

  // F11 / Cmd+Ctrl+F fullscreen, Ctrl+R reload (handy if something gets stuck).
  win.webContents.on('before-input-event', (e, input) => {
    if (input.type !== 'keyDown') return;
    if (input.key === 'F11' || (input.meta && input.control && input.key.toLowerCase() === 'f')) {
      win.setFullScreen(!win.isFullScreen());
      e.preventDefault();
    }
  });

  win.loadURL('app://game/index.html');

  if (SMOKE) runSmokeTest(win);
}

/** CI check: the menu must render with no page errors. */
function runSmokeTest(w) {
  const errors = [];
  w.webContents.on('console-message', (details) => {
    const level = details.level ?? details;
    if (level === 'error' || level === 3) errors.push(details.message ?? String(details));
  });
  w.webContents.on('did-fail-load', (_e, code, desc) => { console.error('did-fail-load', code, desc); app.exit(1); });
  w.webContents.once('did-finish-load', async () => {
    try {
      const ok = await w.webContents.executeJavaScript(`new Promise((resolve) => {
        const t0 = Date.now();
        (function poll() {
          if (document.querySelector('.screen-menu .menu-campaign')) return resolve(true);
          if (Date.now() - t0 > 15000) return resolve(false);
          setTimeout(poll, 100);
        })();
      })`);
      const desktopFlag = await w.webContents.executeJavaScript('document.documentElement.dataset.platform');
      console.log(`smoke: menu=${ok} platform=${desktopFlag} errors=${errors.length}`);
      errors.forEach((e) => console.log('  page error:', e));
      app.exit(ok && desktopFlag === 'desktop' && errors.length === 0 ? 0 : 1);
    } catch (err) {
      console.error(err);
      app.exit(1);
    }
  });
}

app.whenReady().then(() => {
  protocol.handle('app', (request) => {
    const { pathname } = new URL(request.url);
    const rel = decodeURIComponent(pathname).replace(/^\/+/, '') || 'index.html';
    const file = path.normalize(path.join(APP_DIR, rel));
    if (!file.startsWith(APP_DIR)) return new Response('Forbidden', { status: 403 });
    return net.fetch(pathToFileURL(file).toString());
  });

  if (process.platform === 'darwin') {
    Menu.setApplicationMenu(Menu.buildFromTemplate([
      { role: 'appMenu' },
      { role: 'editMenu' },
      { label: 'View', submenu: [{ role: 'togglefullscreen' }, { role: 'reload' }] },
      { role: 'windowMenu' },
    ]));
  } else {
    Menu.setApplicationMenu(null);
  }

  ipcMain.handle('toggle-fullscreen', () => { if (win) win.setFullScreen(!win.isFullScreen()); });

  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});

app.on('second-instance', () => {
  if (win) { if (win.isMinimized()) win.restore(); win.focus(); }
});

app.on('window-all-closed', () => { if (process.platform !== 'darwin' || SMOKE) app.quit(); });
