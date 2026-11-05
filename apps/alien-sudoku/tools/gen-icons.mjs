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
import { LINEUPS } from '../src/data/glyphs/index.js';

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
    <radialGradient id="halo" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#39ff9c" stop-opacity="0.32"/>
      <stop offset="100%" stop-color="#39ff9c" stop-opacity="0"/>
    </radialGradient>
    <filter id="softglow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="8" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>`;
const LINEUP_DEFS = `<defs>${Object.values(LINEUPS).map((L) => L.defs || '').join('')}</defs>`;

/** A glyph from a lineup as a nested SVG (uses the lineup's own gradients). */
const glyph = (L, n, x, y, size, extra = '') =>
  `<svg x="${x}" y="${y}" width="${size}" height="${size}" viewBox="0 0 64 64" ${extra}>${L.symbols[n - 1]}</svg>`;

/** The logo itself, drawn in a 1024 box: a glowing 3x3 board with the
    Close Encounters alien head in front and other glyphs in the corners. */
function logo() {
  const E = LINEUPS.encounters;
  const a = 214, b = 810, s = (b - a) / 3;
  const cell = (cx, cy) => [a + s * cx + 24, a + s * cy + 24, s - 48];
  return `
  <g filter="url(#softglow)">
    <rect x="${a}" y="${a}" width="${b - a}" height="${b - a}" rx="64" fill="#0a0420" fill-opacity="0.78" stroke="#b46bff" stroke-opacity="0.55" stroke-width="6"/>
    <path d="M${a + s} ${a + 18}V${b - 18}M${a + 2 * s} ${a + 18}V${b - 18}M${a + 18} ${a + s}H${b - 18}M${a + 18} ${a + 2 * s}H${b - 18}" stroke="#b46bff" stroke-opacity="0.5" stroke-width="6" stroke-linecap="round"/>
  </g>
  <rect x="${a}" y="${a}" width="${b - a}" height="${b - a}" rx="64" fill="none" stroke="#39ff9c" stroke-width="14" filter="url(#glow)"/>
  ${glyph(E, 2, ...cell(0, 0))}
  ${glyph(E, 5, ...cell(2, 0))}
  ${glyph(E, 9, ...cell(0, 2))}
  ${glyph(E, 3, ...cell(2, 2))}
  <circle cx="512" cy="540" r="250" fill="url(#halo)"/>
  ${glyph(E, 1, 262, 262, 500)}`;
}

const iconSvg = (size = 1024, { maskable = false, transparent = false } = {}) => {
  const scale = maskable ? 0.78 : 1;
  const off = (1024 - 1024 * scale) / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">${DEFS}${LINEUP_DEFS}
  ${transparent ? '' : `<rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#neb)"/><rect width="1024" height="1024" fill="url(#neb2)"/>${stars(90, 1024)}`}
  <g transform="translate(${off} ${off}) scale(${scale})">${logo()}</g>
</svg>`;
};

const backgroundSvg = (size = 1024) => `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">${DEFS}
  <rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#neb)"/><rect width="1024" height="1024" fill="url(#neb2)"/>${stars(90, 1024)}</svg>`;

const splashSvg = (size = 2732) => `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 2732 2732">${DEFS}${LINEUP_DEFS}
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
