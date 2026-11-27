/* Crash reporting: Sentry on every platform, Firebase Crashlytics on iOS and Android.

   Both stay off until they are set up, and only run while Settings → Privacy & data →
   "Send crash reports" is on (on by default):
     Sentry       VITE_SENTRY_DSN at build time (game/.env.local, or the build service's variables)
     Crashlytics  google-services.json (Android) and GoogleService-Info.plist (iOS) in the native
                  projects; the build sees them and sets __FIREBASE__ (vite.config.js)

   What a report holds: the error message and stack trace, app version, platform, device model
   and OS version, the graphics level, and a random install id (Crashlytics). No names, no game
   progress, no IP address stored (sendDefaultPii: false). The privacy policy says the same.

   The last few errors are also kept in memory for the in-game "Send feedback" email, so a player
   can choose to send them even when crash reporting is off. */

import { settings } from '../core/profile.js';
import { on } from '../core/events.js';
import { isNative, platform, isElectron, appVersion } from './native.js';

const DSN = (import.meta.env && import.meta.env.VITE_SENTRY_DSN) || '';
const FIREBASE = typeof __FIREBASE__ !== 'undefined' && __FIREBASE__ && isNative;

let sentry = null;
let crashlytics = null;
const recent = [];

const allowed = () => settings().crashReports !== false;

/** Is Sentry / Crashlytics set up in this build? (Settings shows the switch only if one is.) */
export const crashReportingAvailable = () => !!DSN || FIREBASE;

/** The last few errors (newest last), for the feedback email. */
export function recentErrors() { return recent.slice(); }

function remember(err) {
  const msg = err && (err.stack || err.message) ? String(err.stack || err.message) : String(err);
  recent.push(`${new Date().toISOString().slice(11, 19)} ${msg.slice(0, 400)}`);
  if (recent.length > 5) recent.shift();
}

export async function initCrashReporting() {
  window.addEventListener('error', (e) => { remember(e.error || e.message); forwardToCrashlytics(e.error || e.message); });
  window.addEventListener('unhandledrejection', (e) => { remember(e.reason); forwardToCrashlytics(e.reason); });
  on('settings', ({ key }) => { if (key === 'crashReports') applyChoice(); });
  if (!allowed()) { await applyChoice(); return; }
  await Promise.allSettled([startSentry(), startCrashlytics()]);
}

async function startSentry() {
  if (!DSN || sentry) return;
  const options = {
    dsn: DSN,
    release: `alien-sudoku@${appVersion()}`,
    environment: import.meta.env?.MODE === 'production' ? 'production' : 'development',
    sendDefaultPii: false,
    // Crash reports only: no tracing, no session replay, no breadcrumbs of what the player typed.
    tracesSampleRate: 0,
    maxBreadcrumbs: 20,
    beforeSend: (event) => (allowed() ? event : null),
    initialScope: { tags: { platform: isElectron ? 'desktop' : platform } },
  };
  try {
    if (isNative) {
      const [Sentry, SentryBrowser] = await Promise.all([import('@sentry/capacitor'), import('@sentry/browser')]);
      Sentry.init(options, SentryBrowser.init);
      sentry = Sentry;
    } else {
      const SentryBrowser = await import('@sentry/browser');
      SentryBrowser.init(options);
      sentry = SentryBrowser;
    }
  } catch (err) { remember(err); }
}

async function startCrashlytics() {
  if (!FIREBASE || crashlytics) return;
  try {
    const { FirebaseCrashlytics } = await import('@capacitor-firebase/crashlytics');
    // Collection is off in the native config until the player's choice is applied here,
    // so a player who turned it off sends nothing, even right after a crash.
    await FirebaseCrashlytics.setEnabled({ enabled: allowed() });
    await FirebaseCrashlytics.setCustomKey({ key: 'app_version', value: appVersion(), type: 'string' });
    crashlytics = FirebaseCrashlytics;
  } catch (err) { remember(err); }
}

async function applyChoice() {
  if (allowed()) { await Promise.allSettled([startSentry(), startCrashlytics()]); }
  if (crashlytics) { try { await crashlytics.setEnabled({ enabled: allowed() }); } catch { /* ignore */ } }
  else if (FIREBASE && !allowed()) {
    // Make sure native collection is off even if this launch never started Crashlytics.
    try { const { FirebaseCrashlytics } = await import('@capacitor-firebase/crashlytics'); await FirebaseCrashlytics.setEnabled({ enabled: false }); } catch { /* ignore */ }
  }
  // Sentry checks the switch in beforeSend, so nothing more is needed when it is turned off.
}

function forwardToCrashlytics(err) {
  if (!crashlytics || !allowed() || !err) return;
  const message = String(err && err.message ? err.message : err).slice(0, 500);
  crashlytics.recordException({ message }).catch(() => {});
}

/** Extra context for both services (e.g. the graphics level). */
export function setCrashContext(key, value) {
  try { sentry?.setTag?.(key, String(value)); } catch { /* ignore */ }
  crashlytics?.setCustomKey({ key, value: String(value), type: 'string' }).catch(() => {});
}
