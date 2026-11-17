/* ============================================================
   Platform glue: Capacitor (iOS/Android), Electron, plain web.
   Everything native is loaded lazily and guarded so the same
   bundle runs in a browser, an installed PWA, and Electron.
   ============================================================ */

import { Capacitor, SystemBars, SystemBarsStyle } from '@capacitor/core';

export const isNative = Capacitor.isNativePlatform();
export const platform = Capacitor.getPlatform(); // 'ios' | 'android' | 'web'
export const isElectron = typeof window !== 'undefined' && !!window.alienDesktop;
export const isStandalonePwa = typeof window !== 'undefined' &&
  (window.matchMedia?.('(display-mode: standalone)').matches || window.navigator.standalone === true);

let hapticsMod = null;
let hapticsOn = true;

export function setHapticsEnabled(on) { hapticsOn = on; }

/**
 * Wire up app lifecycle and hardware back button.
 * @param {object} h { onBack: () => boolean (true = handled), onPause, onResume }
 */
export async function initPlatform(h) {
  document.documentElement.dataset.platform = isElectron ? 'desktop' : platform;

  // Works everywhere, including Capacitor webviews.
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) h.onPause?.(); else h.onResume?.();
  });
  window.addEventListener('pagehide', () => h.onPause?.());

  if (!isNative) return;

  try {
    const { App } = await import('@capacitor/app');
    App.addListener('backButton', () => {
      const handled = h.onBack?.();
      if (!handled) App.minimizeApp().catch(() => App.exitApp());
    });
    App.addListener('appStateChange', ({ isActive }) => {
      if (isActive) h.onResume?.(); else h.onPause?.();
    });
  } catch (err) { console.warn('[native] App plugin unavailable', err); }

  try { await SystemBars.setStyle({ style: SystemBarsStyle.Dark }); } catch { /* older shells */ }

  try { hapticsMod = await import('@capacitor/haptics'); } catch { hapticsMod = null; }
}

export async function hideSplash() {
  if (!isNative) return;
  try {
    const { SplashScreen } = await import('@capacitor/splash-screen');
    await SplashScreen.hide({ fadeOutDuration: 300 });
  } catch { /* ignore */ }
}

/** kind: 'light' | 'medium' | 'heavy' | 'success' | 'warning' | 'error' | 'select' */
export function haptic(kind = 'light') {
  if (!hapticsOn) return;
  if (hapticsMod) {
    const { Haptics, ImpactStyle, NotificationType } = hapticsMod;
    let p;
    if (kind === 'select') p = Haptics.selectionChanged?.() ?? Haptics.impact({ style: ImpactStyle.Light });
    else if (kind === 'success' || kind === 'warning' || kind === 'error') {
      p = Haptics.notification({ type: { success: NotificationType.Success, warning: NotificationType.Warning, error: NotificationType.Error }[kind] });
    } else {
      p = Haptics.impact({ style: { light: ImpactStyle.Light, medium: ImpactStyle.Medium, heavy: ImpactStyle.Heavy }[kind] || ImpactStyle.Light });
    }
    p?.catch?.(() => {});
    return;
  }
  // Web fallback (Android Chrome supports vibrate; iOS Safari ignores it).
  const ms = { light: 8, select: 5, medium: 15, heavy: 25, success: [10, 40, 20], warning: [20, 40, 20], error: [30, 50, 30] }[kind] || 8;
  try { navigator.vibrate?.(ms); } catch { /* ignore */ }
}

export function appVersion() {
  return typeof __APP_VERSION__ !== 'undefined' ? __APP_VERSION__ : 'dev';
}
