#!/usr/bin/env node
/* Generates every icon and splash image from one SVG design.
   Outputs:
     public/favicon.svg, public/icons/*.png         (web / PWA)
     assets/icon-only.png, icon-foreground.png, icon-background.png,
     assets/splash.png, splash-dark.png             (input for `npx capacitor-assets generate`)
     desktop/build/icon.png                         (electron-builder)
   Run: npm run gen:icons */

import sharp from 'sharp';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = (p) => { const f = join(root, p); mkdirSync(dirname(f), { recursive: true }); return f; };

// Deterministic star field
function stars(n, size, seed = 7) {
  let s = seed;
  const rnd = () => ((s = (s * 16807) % 2147483647) / 2147483647);
  let svg = '';
  for (let i = 0; i < n; i++) {
    const x = (rnd() * size).toFixed(1);
    const y = (rnd() * size).toFixed(1);
    const r = (rnd() * 2.2 + 0.6).toFixed(2);
    const o = (rnd() * 0.6 + 0.3).toFixed(2);
    const c = ['#ffffff', '#7cffc4', '#d9a7ff', '#5ff0ff'][Math.floor(rnd() * 4)];
    svg += `<circle cx="${x}" cy="${y}" r="${r}" fill="${c}" opacity="${o}"/>`;
  }
  return svg;
}

const DEFS = `
  <defs>
    <radialGradient id="bg" cx="50%" cy="38%" r="75%">
      <stop offset="0%" stop-color="#3a1478"/>
      <stop offset="45%" stop-color="#160634"/>
      <stop offset="100%" stop-color="#05010f"/>
    </radialGradient>
    <radialGradient id="neb" cx="70%" cy="80%" r="50%">
      <stop offset="0%" stop-color="#39ff9c" stop-opacity="0.22"/>
      <stop offset="100%" stop-color="#39ff9c" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="neb2" cx="20%" cy="15%" r="45%">
      <stop offset="0%" stop-color="#ff5cf6" stop-opacity="0.22"/>
      <stop offset="100%" stop-color="#ff5cf6" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="beam" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#5ff0ff" stop-opacity="0.55"/>
      <stop offset="100%" stop-color="#5ff0ff" stop-opacity="0"/>
    </linearGradient>
    <filter id="glow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="14" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <filter id="softglow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="8" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>`;

/** The logo itself, drawn in a 1024 box. */
function logo() {
  // Board: rounded square 200..824, 3x3 grid.
  const a = 214, b = 810, s = (b - a) / 3;
  return `
  <g filter="url(#softglow)">
    <rect x="${a}" y="${a}" width="${b - a}" height="${b - a}" rx="64" fill="#0a0420" fill-opacity="0.72" stroke="#b46bff" stroke-opacity="0.55" stroke-width="6"/>
    <path d="M${a + s} ${a + 18}V${b - 18}M${a + 2 * s} ${a + 18}V${b - 18}M${a + 18} ${a + s}H${b - 18}M${a + 18} ${a + 2 * s}H${b - 18}" stroke="#b46bff" stroke-opacity="0.55" stroke-width="6" stroke-linecap="round"/>
  </g>
  <rect x="${a}" y="${a}" width="${b - a}" height="${b - a}" rx="64" fill="none" stroke="#39ff9c" stroke-width="14" filter="url(#glow)"/>
  <!-- corner glyphs (dimmed) -->
  <g fill="none" stroke="#5ff0ff" stroke-opacity="0.55" stroke-width="12" stroke-linecap="round" stroke-linejoin="round">
    <ellipse cx="${a + s / 2}" cy="${a + s / 2}" rx="62" ry="26"/><circle cx="${a + s / 2}" cy="${a + s / 2}" r="10" fill="#5ff0ff" fill-opacity="0.55"/>
    <polygon points="${b - s / 2},${a + s / 2 - 58} ${b - s / 2 + 60},${a + s / 2 + 46} ${b - s / 2 - 60},${a + s / 2 + 46}"/>
    <path d="M${a + s / 2 + 34} ${b - s / 2 - 54} a58 58 0 1 0 0 108 a44 44 0 1 1 0 -108z"/>
    <circle cx="${b - s / 2}" cy="${b - s / 2}" r="50"/><path d="M${b - s / 2} ${b - s / 2 - 66}V${b - s / 2 + 66}M${b - s / 2 - 66} ${b - s / 2}H${b - s / 2 + 66}"/>
  </g>
  <!-- tractor beam -->
  <path d="M440 560 L360 800 L664 800 L584 560 Z" fill="url(#beam)"/>
  <!-- UFO -->
  <g filter="url(#glow)" fill="none" stroke="#39ff9c" stroke-width="26" stroke-linecap="round" stroke-linejoin="round">
    <path d="M372 520 q140 -190 280 0"/>
    <ellipse cx="512" cy="540" rx="230" ry="62"/>
  </g>
  <g fill="#39ff9c">
    <circle cx="408" cy="540" r="17"/><circle cx="512" cy="550" r="17"/><circle cx="616" cy="540" r="17"/>
  </g>
  <path d="M455 452 q57 -62 114 0" fill="none" stroke="#d9a7ff" stroke-opacity="0.8" stroke-width="10" stroke-linecap="round"/>`;
}

const iconSvg = (size = 1024, { maskable = false, transparent = false } = {}) => {
  const scale = maskable ? 0.78 : 1;
  const off = (1024 - 1024 * scale) / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">${DEFS}
  ${transparent ? '' : `<rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#neb)"/><rect width="1024" height="1024" fill="url(#neb2)"/>${stars(90, 1024)}`}
  <g transform="translate(${off} ${off}) scale(${scale})">${logo()}</g>
</svg>`;
};

const backgroundSvg = (size = 1024) => `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">${DEFS}
  <rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#neb)"/><rect width="1024" height="1024" fill="url(#neb2)"/>${stars(90, 1024)}</svg>`;

const splashSvg = (size = 2732) => `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 2732 2732">${DEFS}
  <radialGradient id="sbg" cx="50%" cy="45%" r="60%"><stop offset="0%" stop-color="#2a0d5c"/><stop offset="60%" stop-color="#0c0420"/><stop offset="100%" stop-color="#05010f"/></radialGradient>
  <rect width="2732" height="2732" fill="url(#sbg)"/>${stars(260, 2732, 11)}
  <g transform="translate(1066 1066) scale(0.586)">${logo()}</g>
</svg>`;

async function png(svg, file, size, { flatten = false } = {}) {
  let img = sharp(Buffer.from(svg), { density: 72 * (size / 1024) * 1.0 }).resize(size, size);
  if (flatten) img = img.flatten({ background: '#05010f' });
  await img.png({ compressionLevel: 9 }).toFile(out(file));
  console.log('wrote', file);
}

// Web
writeFileSync(out('public/favicon.svg'), iconSvg(64));
await png(iconSvg(), 'public/icons/icon-192.png', 192);
await png(iconSvg(), 'public/icons/icon-512.png', 512);
await png(iconSvg(1024, { maskable: true }), 'public/icons/icon-maskable-512.png', 512);
await png(iconSvg(), 'public/icons/apple-touch-icon.png', 180, { flatten: true });

// Capacitor assets input
await png(iconSvg(), 'assets/icon-only.png', 1024, { flatten: true });
await png(iconSvg(1024, { maskable: true, transparent: true }), 'assets/icon-foreground.png', 1024);
await png(backgroundSvg(), 'assets/icon-background.png', 1024, { flatten: true });
await png(splashSvg(), 'assets/splash.png', 2732, { flatten: true });
await png(splashSvg(), 'assets/splash-dark.png', 2732, { flatten: true });

// Desktop
await png(iconSvg(), 'desktop/build/icon.png', 1024);
