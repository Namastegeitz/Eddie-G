#!/usr/bin/env node
/* Renders a lineup's glyphs as a PNG contact sheet at the sizes the game uses,
   on that lineup's own theme colors, so the art can be judged by eye.

   node tools/glyph-sheet.mjs <lineup> [more lineups...] [--out=dir]
   -> <dir>/glyphs-<lineup>.png   (default dir: ./glyph-sheets)

   Rows: 1) each glyph large (128 px) with its name and color swatch
         2) the palette as on a phone (9 across, 36 px)
         3) a sample board (cells ~40 px, glyph ~29 px) with given/placed/selected
            states and a few notes cells (pencil glyphs ~11 px)
         4) every glyph at 14 px (note size) and 20 px                       */

import { mkdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { chromium } from '@playwright/test';
import { SYMBOL_SETS, spriteMarkup } from '../src/data/glyphs/index.js';
import { THEMES } from '../src/data/themes.js';

const args = process.argv.slice(2);
const outDir = resolve((args.find((a) => a.startsWith('--out=')) || '--out=glyph-sheets').slice(6));
const keys = args.filter((a) => !a.startsWith('--'));
if (!keys.length) { console.error('usage: node tools/glyph-sheet.mjs <lineup...> [--out=dir]'); process.exit(1); }
mkdirSync(outDir, { recursive: true });

// A valid solved grid to sample from (values 1..9).
const SOLVED = '534678912672195348198342567859761423426853791713924856961537284287419635345286179'.split('').map(Number);
const GIVEN = new Set([0, 3, 5, 9, 13, 17, 20, 22, 24, 28, 30, 34, 37, 40, 43, 46, 50, 52, 56, 58, 60, 63, 67, 71, 75, 77, 80]);
const PLACED = new Set([1, 11, 26, 33, 41, 48, 55, 62, 69, 78]);
const NOTES = { 2: [1, 4, 7], 15: [2, 3, 5, 9], 44: [6, 8], 65: [1, 2, 3, 4, 5, 6, 7, 8, 9] };

function page(key) {
  const set = SYMBOL_SETS[key];
  const t = THEMES[key];
  const g = (v, cls = '') => set.svgs[v - 1].replace('class="gsvg"', `class="gsvg ${cls}"`);
  let board = '';
  for (let i = 0; i < 81; i++) {
    const r = Math.floor(i / 9), c = i % 9;
    const cls = ['cell'];
    if (r % 3 === 0) cls.push('bt'); if (c % 3 === 0) cls.push('bl');
    let inner = '';
    if (GIVEN.has(i)) { cls.push('fixed'); inner = g(SOLVED[i]); }
    else if (PLACED.has(i)) { cls.push('user'); inner = g(SOLVED[i]); }
    else if (NOTES[i]) {
      inner = '<div class="notes">' + [1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => `<span>${NOTES[i].includes(n) ? g(n) : ''}</span>`).join('') + '</div>';
    }
    if (i === 41) cls.push('selected');
    board += `<div class="${cls.join(' ')}">${inner}</div>`;
  }
  return `<!doctype html><html><head><meta charset="utf8"><style>
  body { margin: 0; padding: 24px; background: ${t.bg}; color: ${t.text}; font: 14px system-ui, sans-serif; width: 1180px; }
  h1 { margin: 0 0 4px; font-size: 22px; } p { margin: 0 0 16px; color: ${t.textDim}; }
  .row { display: flex; gap: 14px; flex-wrap: wrap; margin-bottom: 22px; align-items: flex-start; }
  .big { width: 112px; display: flex; flex-direction: column; align-items: center; gap: 6px; }
  .tile { width: 112px; height: 112px; border-radius: 12px; background: ${t.cellBg}; display: flex; align-items: center; justify-content: center; border: 1px solid ${t.line}; }
  .tile .gsvg { width: 96px; height: 96px; }
  .big small { font-size: 12px; text-align: center; } .sw { width: 28px; height: 8px; border-radius: 4px; }
  .palette { display: grid; grid-template-columns: repeat(9, 36px); gap: 5px; padding: 10px; background: rgba(${t.rgb.panel}, .9); border-radius: 12px; }
  .pbtn { height: 42px; border-radius: 10px; border: 1px solid rgba(${t.rgb.c2}, .7); background: rgba(${t.rgb.panel}, .9); display: flex; align-items: center; justify-content: center; }
  .pbtn .gsvg { width: 30px; height: 30px; }
  .board { display: grid; grid-template-columns: repeat(9, 40px); grid-template-rows: repeat(9, 40px); border: 2px solid ${t.lineStrong}; border-radius: 8px; padding: 3px; background: rgba(${t.rgb.deep}, .9); }
  .cell { border: 1px solid ${t.line}; background: ${t.cellBg}; display: flex; align-items: center; justify-content: center; position: relative; }
  .cell.bt { border-top: 2px solid ${t.lineStrong}; } .cell.bl { border-left: 2px solid ${t.lineStrong}; }
  .cell.fixed { background: ${t.cellFixed}; } .cell.user { background: ${t.cellUser}; }
  .cell.selected { box-shadow: inset 0 0 0 2px rgb(${t.rgb.c4}); }
  .cell > .gsvg { width: 30px; height: 30px; }
  .notes { position: absolute; inset: 2px; display: grid; grid-template-columns: repeat(3, 1fr); }
  .notes span { display: flex; align-items: center; justify-content: center; } .notes .gsvg { width: 11px; height: 11px; }
  .small { display: flex; gap: 10px; align-items: center; padding: 10px; background: ${t.cellBg}; border-radius: 8px; }
  .s14 .gsvg { width: 14px; height: 14px; } .s20 .gsvg { width: 20px; height: 20px; }
  </style></head><body>${spriteMarkup()}
  <h1>${t.name} <span style="color:${t.textDim};font-size:14px">(${key})</span></h1><p>${t.tagline}</p>
  <div class="row">${set.svgs.map((_, i) => `<div class="big"><div class="tile">${g(i + 1)}</div><small>${i + 1}. ${set.names[i]}</small><span class="sw" style="background:${set.colors[i]}"></span></div>`).join('')}</div>
  <div class="row"><div class="palette">${set.svgs.map((_, i) => `<div class="pbtn">${g(i + 1)}</div>`).join('')}</div>
    <div style="display:flex;flex-direction:column;gap:10px">
      <div class="small s14">${set.svgs.map((_, i) => g(i + 1)).join('')} <span style="color:${t.textDim}">14 px</span></div>
      <div class="small s20">${set.svgs.map((_, i) => g(i + 1)).join('')} <span style="color:${t.textDim}">20 px</span></div>
    </div></div>
  <div class="row"><div class="board">${board}</div></div>
  </body></html>`;
}

const exe = process.env.PW_CHROMIUM || (existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined);
const browser = await chromium.launch(exe ? { executablePath: exe } : {});
const ctx = await browser.newContext({ viewport: { width: 1228, height: 900 }, deviceScaleFactor: 1 });
for (const key of keys) {
  if (!SYMBOL_SETS[key] || !THEMES[key]) { console.error(`unknown lineup ${key}`); continue; }
  const p = await ctx.newPage();
  const errors = [];
  p.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  await p.setContent(page(key));
  const file = join(outDir, `glyphs-${key}.png`);
  await p.screenshot({ path: file, fullPage: true });
  console.log(`${file}${errors.length ? `  (${errors.length} console errors: ${errors[0]})` : ''}`);
  await p.close();
}
await browser.close();
