// Phone features, used when they exist:
// - Inside the iOS / Android app (Capacitor): haptics, the Android back
//   button, keeping the screen on, hiding the status bar and splash, and
//   pausing when the app goes to the background.
// - In a phone browser: vibration (Android), Wake Lock (screen stays on
//   while you play), and iPhone's silent switch (Settings > Sound).
// Plugins are called through the Capacitor bridge that the app injects,
// so the web build needs no extra libraries.

function bridge() {
  const C = window.Capacitor;
  if (!C || typeof C.nativePromise !== 'function') return null;
  const platform = typeof C.getPlatform === 'function' ? C.getPlatform() : 'web';
  return platform === 'web' ? null : C;
}

function has(C, name) {
  return !!(C.PluginHeaders && C.PluginHeaders.some((h) => h.name === name));
}

function call(C, plugin, method, options = {}) {
  if (!has(C, plugin)) return Promise.resolve(null);
  return C.nativePromise(plugin, method, options).catch(() => null);
}

export function isIOS() {
  const ua = navigator.userAgent || '';
  return /iPad|iPhone|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1);
}

export function setupPlatform(app) {
  const C = bridge();
  const platform = C ? C.getPlatform() : 'web';
  app.platform = platform; // 'ios' | 'android' | 'web'
  app.native = !!C;
  document.documentElement.dataset.platform = platform;
  if (isIOS()) document.documentElement.classList.add('ios');

  // ---------------------------------------------------------- haptics
  app.haptic = (kind) => {
    if (!app.settings().haptics) return;
    if (C && has(C, 'Haptics')) {
      if (kind === 'error') call(C, 'Haptics', 'notification', { type: 'ERROR' });
      else if (kind === 'success') call(C, 'Haptics', 'notification', { type: 'SUCCESS' });
      else call(C, 'Haptics', 'impact', { style: 'LIGHT' });
      return;
    }
    if (navigator.vibrate) {
      try { navigator.vibrate(kind === 'error' ? [60, 40, 60] : kind === 'success' ? [20, 30, 20] : 8); } catch { /* not allowed */ }
    }
  };

  // ---------------------------------------------------------- keep the screen on while playing
  let wakeLock = null;
  let wantAwake = false;
  const requestWake = async () => {
    if (!wantAwake || document.hidden) return;
    if (C && has(C, 'KeepAwake')) { call(C, 'KeepAwake', 'keepAwake'); return; }
    if ('wakeLock' in navigator && !wakeLock) {
      try {
        wakeLock = await navigator.wakeLock.request('screen');
        wakeLock.addEventListener('release', () => { wakeLock = null; });
      } catch { wakeLock = null; }
    }
  };
  app.keepAwake = (on) => {
    wantAwake = on;
    if (on) requestWake();
    else if (C && has(C, 'KeepAwake')) call(C, 'KeepAwake', 'allowSleep');
    else if (wakeLock) { wakeLock.release().catch(() => {}); wakeLock = null; }
  };
  document.addEventListener('visibilitychange', () => { if (!document.hidden) requestWake(); });

  // ---------------------------------------------------------- iPhone silent switch
  // 'playback' lets the game's sound play with the ring/silent switch on (Safari 16.4+).
  app.applySilentMode = (playOnSilent) => {
    try {
      if (navigator.audioSession) navigator.audioSession.type = playOnSilent ? 'playback' : 'ambient';
    } catch { /* not supported */ }
  };

  if (!C) return;

  // ---------------------------------------------------------- native app only
  call(C, 'SystemBars', 'hide', { bar: 'StatusBar' });
  setTimeout(() => call(C, 'SplashScreen', 'hide', { fadeOutDuration: 250 }), 150);
  if (has(C, 'App') && typeof C.addListener === 'function') {
    C.addListener('App', 'backButton', () => {
      if (!app.ui.handleBack()) call(C, 'App', 'minimizeApp');
    });
    C.addListener('App', 'pause', () => {
      app.game.pause();
      app.audio.suspend();
    });
    C.addListener('App', 'resume', () => {
      app.audio.resume();
      requestWake();
      call(C, 'SystemBars', 'hide', { bar: 'StatusBar' });
    });
  }
}
