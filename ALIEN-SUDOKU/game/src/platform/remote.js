/* Remote switches through Firebase Remote Config (iOS and Android only).

   The defaults below ship in the app. With no Firebase project, no network or a failed
   fetch, the game behaves exactly as it does without this file. Keys (all optional, set in
   the Firebase console → Remote Config):
     disable_ads            true → no banner, interstitial or rewarded ads
     disable_interstitials  true → no between-game ads
     disable_rewarded       true → rewarded videos are skipped (the reward is given)
     min_version            e.g. "1.3.0" → players on an older version see a "new version" note
     force_below_version    e.g. "1.2.0" → older versions must update before playing
     update_message         text for those notes (optional)
   Values are fetched at most every 12 hours and applied on the next launch, never mid-game. */

import { isNative, appVersion } from './native.js';

const FIREBASE = typeof __FIREBASE__ !== 'undefined' && __FIREBASE__ && isNative;

export const REMOTE_DEFAULTS = Object.freeze({
  disable_ads: false,
  disable_interstitials: false,
  disable_rewarded: false,
  min_version: '',
  force_below_version: '',
  update_message: '',
});

let values = { ...REMOTE_DEFAULTS };

/** A switch's current value (the shipped default until a fetch succeeds). */
export function remote(key) { return values[key]; }

/** -1, 0 or 1, comparing "1.2.10" with "1.2.9" correctly. Non-numbers count as 0. */
export function compareVersions(a, b) {
  const pa = String(a).split('.').map((x) => parseInt(x, 10) || 0);
  const pb = String(b).split('.').map((x) => parseInt(x, 10) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] || 0) - (pb[i] || 0);
    if (d) return d < 0 ? -1 : 1;
  }
  return 0;
}

/** What to tell this version: null, { force: false, ... } or { force: true, ... }. */
export function updateNotice(v = values, current = appVersion()) {
  if (!/^\d/.test(current)) return null; // dev builds
  if (v.force_below_version && compareVersions(current, v.force_below_version) < 0) {
    return { force: true, message: v.update_message || 'This version of Alien Sudoku is too old. Please update to keep playing.' };
  }
  if (v.min_version && compareVersions(current, v.min_version) < 0) {
    return { force: false, message: v.update_message || 'A new version of Alien Sudoku is available, with fixes and new features.' };
  }
  return null;
}

/** Read the values activated last time (fast), then fetch new ones for next launch. */
export async function initRemote() {
  if (!FIREBASE) return values;
  try {
    const { FirebaseRemoteConfig } = await import('@capacitor-firebase/remote-config');
    const read = async () => {
      const next = { ...REMOTE_DEFAULTS };
      for (const [key, def] of Object.entries(REMOTE_DEFAULTS)) {
        try {
          // A key that isn't set in the console reads as false / '', the same as our defaults.
          if (typeof def === 'boolean') next[key] = !!(await FirebaseRemoteConfig.getBoolean({ key }))?.value;
          else { const r = await FirebaseRemoteConfig.getString({ key }); if (typeof r?.value === 'string') next[key] = r.value; }
        } catch { /* keep the default */ }
      }
      return next;
    };
    values = await read();
    // Fetch in the background; activated values are used from the next launch on.
    FirebaseRemoteConfig.fetchConfig({ minimumFetchIntervalInSeconds: 12 * 3600 })
      .then(() => FirebaseRemoteConfig.activate())
      .catch(() => {});
  } catch { /* keep defaults */ }
  return values;
}
