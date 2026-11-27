// Crash reports, only in builds where a crash service is set up, and only while
// the player leaves Settings > Help and privacy > "Send crash reports" on.
//   - Sentry (web, phone apps and the PC edition): release/config.json "sentryDsn".
//     The build copies js/vendor/sentry.min.js into the game and writes the DSN
//     into the page as window.MSMD_CONFIG.
//   - Firebase Crashlytics (phone apps): release/config.json "firebaseCrashlytics": true
//     plus the Firebase files (google-services.json / GoogleService-Info.plist),
//     see mobile/README.md. Catches native crashes too.
// What is sent: the error message and stack, the game version, the device and
// browser type. Never names, accounts, IP addresses (sendDefaultPii off), save
// codes or anything typed. Without a set-up service nothing is ever sent.
import { onError } from './safety.js';
import { nativeCall, nativeHas } from './native.js';

export const Crash = {
  sentry: false,
  crashlytics: false,
  /** Is any crash service set up in this build? (shows the Settings switch) */
  configured() {
    const c = window.MSMD_CONFIG || {};
    return !!(validDsn(c.sentryDsn) || (c.firebaseCrashlytics && nativeHas('FirebaseCrashlytics')));
  },
  /** Re-read the player's switch (called when settings change). */
  apply() {},
};

function validDsn(dsn) {
  return typeof dsn === 'string' && /^https:\/\/[^@\s]+@[^/\s]+\/\d+$/.test(dsn.trim());
}

function loadScript(src) {
  return new Promise((resolve, reject) => {
    const s = document.createElement('script');
    s.src = src;
    s.async = true;
    s.onload = resolve;
    s.onerror = reject;
    document.head.appendChild(s);
  });
}

/** Strip anything personal-looking from a Sentry event before it leaves the device. */
function scrub(event) {
  delete event.user;
  if (event.request) { delete event.request.cookies; delete event.request.headers; }
  if (event.request && event.request.url) event.request.url = event.request.url.replace(/[?#].*$/, '');
  return event;
}

export async function setupCrashReports(app) {
  const cfg = window.MSMD_CONFIG || {};
  const on = () => app.settings().crashReports !== false;
  const env = app.native ? `${app.platform}-app` : app.edition === 'pc' ? 'pc' : 'web';

  if (validDsn(cfg.sentryDsn)) {
    try {
      await loadScript(cfg.sentryScript || 'vendor/sentry.min.js');
      window.Sentry.init({
        dsn: cfg.sentryDsn.trim(),
        release: `monkey-see-monkey-do@${app.version}`,
        environment: env,
        sendDefaultPii: false,
        sampleRate: 1,
        maxBreadcrumbs: 30,
        beforeSend: (event) => (on() ? scrub(event) : null),
      });
      window.Sentry.setTag('edition', app.edition);
      window.Sentry.setTag('graphics', app.stage.level);
      Crash.sentry = true;
    } catch (e) {
      Crash.sentry = false; // blocked or offline: the on-device log still works
    }
  }

  if (cfg.firebaseCrashlytics && nativeHas('FirebaseCrashlytics')) {
    Crash.crashlytics = true;
    nativeCall('FirebaseCrashlytics', 'setEnabled', { enabled: on() });
  }

  Crash.apply = () => {
    if (Crash.crashlytics) nativeCall('FirebaseCrashlytics', 'setEnabled', { enabled: on() });
  };

  // errors the game catches itself (the main loop, promises) go to both services
  onError((err, entry) => {
    if (!on()) return;
    if (Crash.sentry && entry.where !== 'window' && entry.where !== 'promise') {
      try { window.Sentry.captureException(err, { tags: { where: entry.where } }); } catch { /* ignore */ }
    }
    if (Crash.crashlytics) {
      nativeCall('FirebaseCrashlytics', 'recordException', { message: `${entry.where}: ${entry.msg}`.slice(0, 500) });
    }
  });
}
