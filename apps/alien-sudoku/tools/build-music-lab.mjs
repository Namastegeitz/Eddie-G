#!/usr/bin/env node
/* Builds the Music Lab listening page from the rendered samples.

   node tools/build-music-lab.mjs                 -> play/MusicLab.html (loads play/music/*.mp3)
   node tools/build-music-lab.mjs --inline <file> -> one self-contained file, MP3s embedded
   --round2  only the styles picked in round one, each with a note on what changed */
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { STYLES } from '../src/audio/music-engine.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const musicDir = join(root, 'play/music');
const inlineAt = process.argv.indexOf('--inline');
const inline = inlineAt >= 0;
const out = inline ? process.argv[inlineAt + 1] : join(root, 'play/MusicLab.html');
const round2 = process.argv.includes('--round2');
const INTRO = round2
  ? 'Round two: <b>your three picks</b>, reworked to your notes. Each sample is <b>48 seconds</b>, played by the game\'s own synthesizer. Listen, tap <b>Like</b> on the ones that are right, and tell me what to change on the others.'
  : 'Ten theme-music styles for the game, <b>40 seconds each</b>, all played by the game\'s own synthesizer. Tap a play button to listen. Tap <b>Like</b> on every style you want to keep; the best ones become the theme songs for each difficulty tier.';
/** Round one picks and what changed for round two. */
const CHANGES = {
  synthwave: 'More hip hop: a sliding 808 bass, swung boom-bap drums with trap hi-hat rolls, synth chord stabs, vinyl crackle and a whining G-funk lead. Slowed to 90 BPM for the head nod.',
  oracle: 'Same sound. The bass (the drone and the low drum strokes) now has only a light touch of reverb, so the low end is tighter and clearer.',
  wardrums: 'Rebuilt as a rise of strength: a lone horn calls the crew, the drummers join, the strings start to flow, the crew shouts back, then everyone plays the anthem together.',
};
const samples = JSON.parse(readFileSync(join(musicDir, 'samples.json'), 'utf8'));

const tracks = STYLES.map((s, k) => [s, k]).filter(([s]) => !round2 || CHANGES[s.id]).map(([s, k]) => {
  const smp = samples[s.id];
  if (!smp) throw new Error(`no sample for ${s.id}: run tools/render-music.mjs first`);
  return {
    id: s.id, n: String(k + 1).padStart(2, '0'), name: s.name, family: s.family, tier: s.tier, mood: s.mood,
    blurb: s.blurb, instruments: s.instruments, bpm: s.bpm, seconds: smp.seconds, peaks: smp.peaks,
    ...(round2 ? { change: CHANGES[s.id] } : {}),
    ...(inline ? { b64: readFileSync(join(musicDir, smp.file)).toString('base64') } : { src: `music/${smp.file}` }),
  };
});
const json = JSON.stringify(tracks).replace(/</g, '\\u003c');
const html = readFileSync(join(root, 'tools/music-lab.html'), 'utf8').replace('__TRACKS__', () => json).replace('__INTRO__', () => INTRO);
writeFileSync(out, html);
console.log(`wrote ${out} (${(html.length / 1024 / 1024).toFixed(2)} MB)`);
