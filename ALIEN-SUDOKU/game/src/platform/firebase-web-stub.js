/* Stand-in for the Firebase web SDK. The Capacitor Firebase plugins also ship a web
   version that imports 'firebase/*'; Alien Sudoku only uses Firebase on iOS and
   Android (platform/crash.js, platform/remote.js), so web and desktop builds point
   those imports here (vite.config.js) instead of bundling the whole web SDK. */
const unavailable = () => { throw new Error('Firebase is only used in the iOS and Android apps.'); };
export const getApp = unavailable;
export const initializeApp = unavailable;
export const getRemoteConfig = unavailable;
export const activate = unavailable;
export const fetchAndActivate = unavailable;
export const fetchConfig = unavailable;
export const getAll = unavailable;
export const getValue = unavailable;
export const setCustomSignals = unavailable;
export const getCrashlytics = unavailable;
export default {};
