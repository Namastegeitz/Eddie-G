// Monkey See, Monkey Do: PC edition (Steam, GOG, Microsoft Store, Epic, itch.io desktop).
// Opens the web build from ./app in its own window: offline, no Shop (?edition=pc),
// F11 or Alt+Enter for full screen. Saves stay in this app's own storage on the PC.
const { app, BrowserWindow, Menu, shell } = require('electron');
const path = require('path');

// music and move sounds start without waiting for a click
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');

function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 360,
    minHeight: 600,
    backgroundColor: '#0e3527',
    title: 'Monkey See, Monkey Do',
    autoHideMenuBar: true,
    icon: path.join(__dirname, 'build', 'icon.png'),
    webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true, spellcheck: false },
  });
  Menu.setApplicationMenu(null);
  win.loadFile(path.join(__dirname, 'app', 'index.html'), { query: { edition: 'pc' } });

  // F11 or Alt+Enter toggles full screen (Esc stays with the game: it pauses)
  win.webContents.on('before-input-event', (event, input) => {
    if (input.type !== 'keyDown') return;
    if (input.key === 'F11' || (input.alt && input.key === 'Enter')) {
      win.setFullScreen(!win.isFullScreen());
      event.preventDefault();
    }
  });

  // web links (privacy, support) open in the normal browser; the game window never navigates away
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:\/\//.test(url)) shell.openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (event, url) => {
    if (url.startsWith('file://')) return;
    event.preventDefault();
    if (/^https?:\/\//.test(url)) shell.openExternal(url);
  });
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => app.quit());
app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
