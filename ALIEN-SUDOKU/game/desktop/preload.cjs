/* Exposes a tiny, safe API to the game page. Its presence also tells the
   game it is running as the desktop app (no ads, no service worker). */
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('alienDesktop', {
  platform: process.platform,
  toggleFullscreen: () => ipcRenderer.invoke('toggle-fullscreen'),
});
