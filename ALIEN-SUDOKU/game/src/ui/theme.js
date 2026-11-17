/* Applies a lineup theme (data/themes.js) to the whole page as CSS custom
   properties plus <html data-theme="...">. */

import { THEMES, DEFAULT_THEME } from '../data/themes.js';
import { emit } from '../core/events.js';

let current = null;

export const themeFor = (key) => THEMES[key] || THEMES[DEFAULT_THEME];
export const currentTheme = () => current;

export function applyTheme(key) {
  if (!THEMES[key]) key = DEFAULT_THEME;
  if (current === key) return;
  current = key;
  const t = THEMES[key];
  const root = document.documentElement;
  const set = (k, v) => root.style.setProperty(k, v);
  const g = t.glow;

  set('--c1-rgb', t.rgb.c1);
  set('--c2-rgb', t.rgb.c2);
  set('--c3-rgb', t.rgb.c3);
  set('--c4-rgb', t.rgb.c4);
  set('--panel-rgb', t.rgb.panel);
  set('--deep-rgb', t.rgb.deep);
  set('--bg-deep', t.bg);
  set('--text', t.text);
  set('--text-dim', t.textDim);
  set('--on-accent', t.onAccent || t.bg);
  set('--cell-bg', t.cellBg);
  set('--cell-fixed', t.cellFixed);
  set('--cell-user', t.cellUser);
  set('--grid-line', t.line);
  set('--grid-line-strong', t.lineStrong);
  // Box separators: the theme's own color if it has one, else its strong line made nearly opaque.
  set('--box-line', t.boxLine || t.lineStrong.replace(/rgba\(([^)]*?),\s*[\d.]+\)$/, 'rgba($1, 0.95)'));
  set('--r-board', t.radius.board);
  set('--r-btn', t.radius.btn);
  set('--font-display', t.font);
  set('--overlay', t.overlay);
  set('--glow', String(g));
  // Glow strength is baked into ready-made shadows (no calc() inside colors, for older WebViews).
  set('--shadow-board', `0 0 ${Math.round(22 * g)}px rgba(${t.rgb.c1}, ${(0.35 * g).toFixed(2)}), 0 0 ${Math.round(60 * g)}px rgba(${t.rgb.c2}, ${(0.22 * g).toFixed(2)}), inset 0 0 30px rgba(${t.rgb.c2}, 0.12)`);
  set('--shadow-accent', `0 0 ${Math.round(16 * g)}px rgba(${t.rgb.c1}, ${(0.55 * g).toFixed(2)})`);
  set('--text-glow-1', `0 0 ${Math.round(8 * g)}px rgba(${t.rgb.c1}, ${(0.8 * g).toFixed(2)}), 0 0 ${Math.round(24 * g)}px rgba(${t.rgb.c1}, ${(0.5 * g).toFixed(2)})`);
  set('--text-glow-2', `0 0 ${Math.round(8 * g)}px rgba(${t.rgb.c2}, ${(0.8 * g).toFixed(2)}), 0 0 ${Math.round(24 * g)}px rgba(${t.rgb.c2}, ${(0.5 * g).toFixed(2)})`);
  root.dataset.theme = key;
  root.dataset.tone = t.light ? 'light' : 'dark';
  root.style.colorScheme = t.light ? 'light' : 'dark';

  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', t.bg);
  emit('theme', key);
}
