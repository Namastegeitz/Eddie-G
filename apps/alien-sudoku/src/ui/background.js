/* Space-photo backdrop with cross-fade between two layers. */

export const BACKGROUNDS = [
  'space/nebula-pink.webp',
  'space/galaxy-spiral.webp',
  'space/ringed-planet.webp',
  'space/pillars-green.webp',
  'space/moon-planet.webp',
  'space/star-cluster.webp',
];

const base = (import.meta.env && import.meta.env.BASE_URL) || './';
let layers = [];
let active = 0;
let currentUrl = null;
let lastRandom = -1;

export function initBackground() {
  layers = [...document.querySelectorAll('.cosmic-bg')];
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
  const url = base + path;
  const img = new Image();
  img.onload = () => {
    if (currentUrl !== path) return;
    const next = layers[1 - active];
    const prev = layers[active];
    next.style.backgroundImage = `url("${url}")`;
    next.classList.add('loaded');
    prev.classList.remove('loaded');
    active = 1 - active;
  };
  img.src = url;
}
