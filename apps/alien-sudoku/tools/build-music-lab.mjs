#!/usr/bin/env node
/* Builds the Music Lab listening page from the rendered samples.

   node tools/build-music-lab.mjs                 -> play/MusicLab.html (loads play/music/*.mp3)
   node tools/build-music-lab.mjs --inline <file> -> one self-contained file, MP3s embedded */
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { STYLES } from '../src/audio/music-engine.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const musicDir = join(root, 'play/music');
const inlineAt = process.argv.indexOf('--inline');
const inline = inlineAt >= 0;
const out = inline ? process.argv[inlineAt + 1] : join(root, 'play/MusicLab.html');
const samples = JSON.parse(readFileSync(join(musicDir, 'samples.json'), 'utf8'));

const tracks = STYLES.map((s, k) => {
  const smp = samples[s.id];
  if (!smp) throw new Error(`no sample for ${s.id}: run tools/render-music.mjs first`);
  return {
    id: s.id, n: String(k + 1).padStart(2, '0'), name: s.name, family: s.family, tier: s.tier, mood: s.mood,
    blurb: s.blurb, instruments: s.instruments, bpm: s.bpm, seconds: smp.seconds, peaks: smp.peaks,
    ...(inline ? { b64: readFileSync(join(musicDir, smp.file)).toString('base64') } : { src: `music/${smp.file}` }),
  };
});
const json = JSON.stringify(tracks).replace(/</g, '\\u003c');
const html = readFileSync(join(root, 'tools/music-lab.html'), 'utf8').replace('__TRACKS__', () => json);
writeFileSync(out, html);
console.log(`wrote ${out} (${(html.length / 1024 / 1024).toFixed(2)} MB)`);
