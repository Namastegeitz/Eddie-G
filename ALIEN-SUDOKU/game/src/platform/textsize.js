/* Text size. Settings → Board → "Text size": Auto follows the phone's own text size
   (iPhone Dynamic Type and Android font size, through @capacitor/text-zoom), or pick
   100%-150%. The game scales its own text with a CSS variable (--text-scale on <html>),
   so the Android WebView's built-in zoom is set to 100% to avoid scaling twice. The board's
   glyphs already scale with the screen. Clamped to 100-150% so every screen still fits. */

import { settings } from '../core/profile.js';
import { isNative } from './native.js';

export const TEXT_SCALES = [1, 1.15, 1.3, 1.5];
export const clampScale = (x) => Math.min(1.5, Math.max(1, Number(x) || 1));

let phoneScale = 1;

/** Settings value + the phone's preference -> the scale to use. */
export function resolveTextScale(setting, phone = 1) {
  if (setting === 'auto' || setting == null) return clampScale(phone);
  return clampScale(setting);
}

export function applyTextSize() {
  const scale = resolveTextScale(settings().textSize, phoneScale);
  document.documentElement.style.setProperty('--text-scale', String(scale));
  document.documentElement.dataset.textScale = String(scale);
  return scale;
}

/** Read the phone's text size (native) and keep following it when the app comes back. */
export async function initTextSize() {
  applyTextSize();
  if (!isNative) return;
  try {
    const { TextZoom } = await import('@capacitor/text-zoom');
    const read = async () => {
      const { value } = await TextZoom.getPreferred();
      phoneScale = value || 1;
      await TextZoom.set({ value: 1 }); // the game scales its own text
      applyTextSize();
    };
    await read();
    document.addEventListener('visibilitychange', () => { if (!document.hidden) read().catch(() => {}); });
  } catch { /* keep 100% */ }
}
