// Error safety net. Catches errors from anywhere in the game, keeps the last
// 20 on this device (Settings > Report a problem shows them, ready to copy into
// a bug report), and hands each one to the crash services when a build has one
// set up (crash.js). Nothing here ever throws.
const KEY = 'msmd-errors';
const MAX = 20;
let log = null;
const listeners = [];

function load() {
  if (log) return log;
  try { log = JSON.parse(localStorage.getItem(KEY) || '[]'); } catch { log = []; }
  if (!Array.isArray(log)) log = [];
  return log;
}

function persist() {
  try { localStorage.setItem(KEY, JSON.stringify(log)); } catch { /* storage blocked: keep in memory */ }
}

/** The recent errors, oldest first: [{ at, where, msg, stack, v }]. */
export function errorLog() {
  return load().slice();
}

export function clearErrors() {
  log = [];
  persist();
}

/** Call fn(error, entry) for every recorded error (used by the crash services). */
export function onError(fn) {
  listeners.push(fn);
}

let version = '';
/** Record an error. where: 'window' | 'promise' | 'loop' | anything short. */
export function recordError(err, where = 'game') {
  try {
    const e = err instanceof Error ? err : new Error(typeof err === 'string' ? err : (err && err.message) || JSON.stringify(err));
    const entry = {
      at: new Date().toISOString(),
      where,
      msg: String(e.message || e).slice(0, 300),
      stack: String(e.stack || '').split('\n').slice(0, 8).join('\n').slice(0, 1500),
      v: version,
    };
    const list = load();
    // the same error repeating every frame is logged once, with a count
    const last = list[list.length - 1];
    if (last && last.msg === entry.msg && last.where === entry.where) {
      last.n = (last.n || 1) + 1;
      last.at = entry.at;
    } else {
      list.push(entry);
      while (list.length > MAX) list.shift();
    }
    persist();
    for (const fn of listeners) { try { fn(e, entry); } catch { /* a reporter failing must not loop */ } }
    return entry;
  } catch {
    return null;
  }
}

/** Catch everything the game didn't: uncaught errors and rejected promises. */
export function installSafetyNet(appVersion) {
  version = appVersion || '';
  window.addEventListener('error', (ev) => {
    // ignore failed image/script loads (they have a target element, not an error)
    if (ev.target && ev.target !== window) return;
    recordError(ev.error || ev.message || 'Unknown error', 'window');
  });
  window.addEventListener('unhandledrejection', (ev) => recordError(ev.reason || 'Promise rejected', 'promise'));
}

/** Device details for bug reports (no personal information). */
export function deviceDetails(app) {
  let gl = 'none';
  try {
    gl = app && app.stage ? `WebGL ${app.stage.webgl}` : 'unknown';
    const ctx = app && app.stage && app.stage.renderer.getContext();
    const dbg = ctx && ctx.getExtension('WEBGL_debug_renderer_info');
    if (dbg) gl += `, ${ctx.getParameter(dbg.UNMASKED_RENDERER_WEBGL)}`;
  } catch { /* fine */ }
  return [
    `Monkey See, Monkey Do ${app ? app.version : ''}${app && app.edition === 'pc' ? ' (PC edition)' : ''}`,
    `Platform: ${app && app.native ? app.platform + ' app' : 'browser'}`,
    `Browser: ${navigator.userAgent}`,
    `Screen: ${screen.width}x${screen.height} at ${window.devicePixelRatio || 1}x, window ${innerWidth}x${innerHeight}`,
    `3D: ${gl}`,
    `Graphics: ${app && app.stage ? app.stage.level : '?'}${app && app.settings && app.settings().quality === 'auto' ? ' (Auto)' : ''}`,
  ].join('\n');
}
