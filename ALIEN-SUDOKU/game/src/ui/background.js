/* Space backdrop with cross-fade between two layers.

   Every scene ships in three cuts, all made from the same 4x-upscaled master:
     space/<name>.webp        wide, 2816x1536: desktops, tablets and phones held sideways
     space/<name>.tall.webp   tall, 1728x2304: phones and tablets held upright
     space/<name>.card.webp   1500x500 strip: campaign sector cards and the sector header
   plus half-size cuts for the Low graphics level (less memory on small phones):
     space/<name>.sd.webp      1408x768
     space/<name>.tall-sd.webp 864x1152
   The page asks for a scene by its plain name; the cut is picked here. */
import { on } from '../core/events.js';
import { gfx } from './graphics.js';

export const BACKGROUNDS = [
  'space/nebula-pink.webp',
  'space/galaxy-spiral.webp',
  'space/ringed-planet.webp',
  'space/pillars-green.webp',
  'space/moon-planet.webp',
  'space/star-cluster.webp',
];

const base = (import.meta.env && import.meta.env.BASE_URL) || './';

/** 'space/x.webp' + 'tall' -> 'space/x.tall.webp'. Other files are returned as they are. */
export function variantPath(path, variant) {
  return variant && /^space\/[\w-]+\.webp$/.test(path) ? path.replace(/\.webp$/, `.${variant}.webp`) : path;
}

/** The backdrop cut for a viewport: tall when it is higher than it is wide;
    the half-size versions when the graphics level asks for them (quality 'sd'). */
export const backdropVariant = (width, height, quality = 'hd') => {
  const tall = height > width;
  if (quality === 'sd') return tall ? 'tall-sd' : 'sd';
  return tall ? 'tall' : null;
};

/** URL for a bundled image. Single-file builds embed images in window.__ALIEN_ASSETS__.
    variant: 'tall' | 'card' | null (see the top of this file). */
export function assetUrl(path, variant = null) {
  const embedded = typeof window !== 'undefined' && window.__ALIEN_ASSETS__;
  const wanted = variantPath(path, variant);
  if (embedded) return embedded[wanted] || embedded[path] || base + path;
  return base + wanted;
}
let layers = [];
let active = 0;
let currentUrl = null;
let currentVariant = null;
let lastRandom = -1;

const viewportVariant = () => backdropVariant(window.innerWidth, window.innerHeight, gfx().backdrop);

export function initBackground() {
  layers = [...document.querySelectorAll('.cosmic-bg')];
  // Turning the device swaps to the cut made for the new shape.
  let timer = 0;
  window.addEventListener('resize', () => {
    clearTimeout(timer);
    timer = setTimeout(() => { if (currentUrl && viewportVariant() !== currentVariant) paint(currentUrl); }, 250);
  });
  on('graphics', () => { if (currentUrl && viewportVariant() !== currentVariant) paint(currentUrl); });
}

export function randomBackground() {
  let i = Math.floor(Math.random() * BACKGROUNDS.length);
  if (i === lastRandom) i = (i + 1) % BACKGROUNDS.length;
  lastRandom = i;
  return BACKGROUNDS[i];
}

/** path: a BACKGROUNDS entry, 'random', or null to keep the current one. */
export function setBackground(path) {
  if (!layers.length || path == null) return;
  if (path === 'random') path = currentUrl ? null : randomBackground();
  if (!path || path === currentUrl) return;
  currentUrl = path;
  paint(path);
}

function paint(path) {
  const variant = viewportVariant();
  currentVariant = variant;
  const url = assetUrl(path, variant);
  const img = new Image();
  const show = () => {
    if (currentUrl !== path || currentVariant !== variant) return;
    const next = layers[1 - active];
    const prev = layers[active];
    next.style.backgroundImage = `url("${url}")`;
    next.classList.add('loaded');
    prev.classList.remove('loaded');
    active = 1 - active;
  };
  img.onload = () => {
    // Decode off the main thread first, so a 4-megapixel backdrop never stutters the fade.
    if (img.decode) img.decode().then(show, show); else show();
  };
  img.src = url;
}
