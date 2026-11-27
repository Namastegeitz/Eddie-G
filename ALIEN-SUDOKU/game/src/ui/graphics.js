/* Graphics quality: Auto, Low, Medium, High, Ultra.

   Settings (core/profile.js DEFAULT_SETTINGS):
     graphics     'auto' | 'low' | 'medium' | 'high' | 'ultra'
     renderScale  'auto' | 1 | 0.75 | 0.5   resolution of the animated layers (star field, sparks)
     frameCap     'auto' | 30 | 60 | 120     frame rate of those animated layers
     bgMotion     true | false               slow drift of the space backdrop and nebula
     glowEffects  true | false               glow pulses and frosted-glass blur

   The result is written to <html> as data-gfx="low|medium|high|ultra",
   data-gfx-motion="on|off" and data-gfx-glow="on|off" (styles/graphics.css), and
   read by the star field, the backdrop and the sparks through gfx().

   Auto starts from a guess based on the device, then watches frame times the star
   field reports and steps down one level when frames keep running long (a slow or
   hot phone). It never steps up during a session; the level it settled on is
   remembered and the next launch may try one level higher. */

import { settings } from '../core/profile.js';
import { emit } from '../core/events.js';

export const QUALITY_ORDER = ['low', 'medium', 'high', 'ultra'];

/** What each level draws. dprCap: highest pixel ratio for canvases; density/dust: share
    of stars and fine star dust; fps: animation rate of the canvases; backdrop: which
    picture cut ('sd' = half size). */
export const PRESETS = {
  low: { dprCap: 1, density: 0.5, dust: 0, fps: 30, drift: false, nebula: false, glow: false, blur: false, backdrop: 'sd', sparks: 0.45 },
  medium: { dprCap: 1.5, density: 0.8, dust: 0.5, fps: 30, drift: true, nebula: true, glow: true, blur: false, backdrop: 'hd', sparks: 0.75 },
  high: { dprCap: 2, density: 1, dust: 1, fps: 30, drift: true, nebula: true, glow: true, blur: true, backdrop: 'hd', sparks: 1 },
  ultra: { dprCap: 3, density: 1, dust: 1, fps: 60, drift: true, nebula: true, glow: true, blur: true, backdrop: 'hd', sparks: 1 },
};

const LEARNED_KEY = 'alien-sudoku:gfx-auto';

/** A first guess from what the device reports. Phones without deviceMemory (iPhones)
    rely on the frame-time watch to step down if needed. */
export function guessTier({ cores = 4, memoryGB, coarse = false } = {}) {
  if (!coarse) return cores >= 8 ? 'ultra' : cores >= 4 ? 'high' : 'medium';
  if ((memoryGB != null && memoryGB <= 2) || cores <= 2) return 'low';
  if ((memoryGB != null && memoryGB <= 4) || cores <= 4) return 'medium';
  return 'high';
}

/** The tier a new session starts at: the device guess, but at most one level above the
    level Auto settled on last time. */
export function startTier(guess, learned) {
  if (!learned || !QUALITY_ORDER.includes(learned)) return guess;
  const cap = Math.min(QUALITY_ORDER.length - 1, QUALITY_ORDER.indexOf(learned) + 1);
  return QUALITY_ORDER[Math.min(QUALITY_ORDER.indexOf(guess), cap)];
}

/** Settings + tier -> the numbers the renderers use. */
export function resolveGraphics(s, tier) {
  const p = { ...PRESETS[tier] };
  const scale = s.renderScale === 'auto' || s.renderScale == null ? 1 : Number(s.renderScale);
  const fps = s.frameCap === 'auto' || s.frameCap == null ? p.fps : Number(s.frameCap);
  return {
    tier,
    dprCap: p.dprCap,
    scale,
    density: p.density,
    dust: p.dust,
    fps,
    drift: p.drift && s.bgMotion !== false,
    nebula: p.nebula,
    glow: p.glow && s.glowEffects !== false,
    blur: p.blur && s.glowEffects !== false,
    backdrop: p.backdrop,
    sparks: p.sparks,
  };
}

/** Frame-time watch: true when, over a window of frames, too many ran long. */
export function createFrameWatch({ window = 90, longMs = 28, maxShare = 0.12, strikes = 2 } = {}) {
  let n = 0, long = 0, bad = 0;
  return (dt) => {
    if (!(dt > 0) || dt > 1000) return false; // tab switches and pauses don't count
    n++;
    if (dt > longMs) long++;
    if (n < window) return false;
    const tooSlow = long / n > maxShare;
    n = 0; long = 0;
    bad = tooSlow ? bad + 1 : 0;
    if (bad >= strikes) { bad = 0; return true; }
    return false;
  };
}

let autoTier = null;
let current = null;
let watch = createFrameWatch();

function deviceGuess() {
  const nav = typeof navigator !== 'undefined' ? navigator : {};
  const coarse = typeof matchMedia === 'function' && matchMedia('(pointer: coarse)').matches;
  return guessTier({ cores: nav.hardwareConcurrency || 4, memoryGB: nav.deviceMemory, coarse });
}
function learned() { try { return localStorage.getItem(LEARNED_KEY); } catch { return null; } }
function remember(tier) { try { localStorage.setItem(LEARNED_KEY, tier); } catch { /* private mode */ } }

/** The level Auto is using now (for the Settings label). */
export function autoLevel() { return autoTier; }

/** The resolved graphics config. */
export function gfx() {
  if (!current) applyGraphics();
  return current;
}

/** Recompute from settings and publish to <html> and listeners. */
export function applyGraphics() {
  const s = settings();
  if (!autoTier) autoTier = startTier(deviceGuess(), learned());
  const tier = s.graphics && s.graphics !== 'auto' && PRESETS[s.graphics] ? s.graphics : autoTier;
  current = resolveGraphics(s, tier);
  const root = document.documentElement;
  root.dataset.gfx = tier;
  root.dataset.gfxMotion = current.drift ? 'on' : 'off';
  root.dataset.gfxGlow = current.glow ? 'on' : 'off';
  root.dataset.gfxBlur = current.blur ? 'on' : 'off';
  emit('graphics', current);
  return current;
}

/** The star field calls this with each frame's duration. Only Auto reacts. */
export function reportFrame(dt) {
  if (settings().graphics !== 'auto' && settings().graphics != null) return;
  if (!watch(dt)) return;
  const i = QUALITY_ORDER.indexOf(autoTier);
  if (i <= 0) return;
  autoTier = QUALITY_ORDER[i - 1];
  remember(autoTier);
  watch = createFrameWatch();
  applyGraphics();
}

/** For tests: forget the session's Auto level. */
export function resetAutoForTests() { autoTier = null; current = null; watch = createFrameWatch(); }
