#!/usr/bin/env node
/* Renders each music style in src/audio/music-engine.js to an MP3 sample, in a real
   browser (Playwright Chromium, OfflineAudioContext), and checks it: no clipping,
   no silent stretches, loudness close to the others.

   node tools/render-music.mjs [outDir=play/music] [seconds=40]
   -> <outDir>/NN-<id>.mp3 and <outDir>/samples.json (waveform peaks + levels)
   Needs ffmpeg with libmp3lame. Set PW_CHROMIUM to use a preinstalled browser. */
import { createServer } from 'node:http';
import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { chromium } from 'playwright';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = resolve(root, process.argv[2] || 'play/music');
const seconds = Number(process.argv[3] || 40);
mkdirSync(outDir, { recursive: true });

const server = createServer((req, res) => {
  if (req.url === '/') { res.setHeader('content-type', 'text/html'); res.end('<!doctype html><title>render</title>'); return; }
  if (!req.url.startsWith('/src/audio/')) { res.statusCode = 404; res.end(); return; }
  try {
    const body = readFileSync(join(root, req.url));
    res.setHeader('content-type', 'text/javascript');
    res.end(body);
  } catch { res.statusCode = 404; res.end(); }
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const base = `http://127.0.0.1:${server.address().port}`;

const browser = await chromium.launch(process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {});
const page = await browser.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
await page.goto(`${base}/`);

const ids = await page.evaluate(async () => (await import('/src/audio/music-engine.js')).STYLES.map((s) => s.id));
const report = {};
let failed = false;
for (const [k, id] of ids.entries()) {
  const res = await page.evaluate(async ({ id, seconds }) => {
    const m = await import('/src/audio/music-engine.js');
    const buf = await m.renderStyle(id, seconds);
    const L = buf.getChannelData(0);
    const R = buf.getChannelData(1);
    const n = L.length;
    const BARS = 160;
    const per = Math.floor(n / BARS);
    const peaks = new Array(BARS).fill(0);
    let peak = 0; let sum = 0; let clip = 0;
    const win = buf.sampleRate * 2; const wins = []; let ws = 0;
    for (let i = 0; i < n; i++) {
      const a = Math.max(Math.abs(L[i]), Math.abs(R[i]));
      if (a > peak) peak = a;
      if (a >= 0.999) clip++;
      const b = Math.min(BARS - 1, Math.floor(i / per));
      if (a > peaks[b]) peaks[b] = a;
      const e = (L[i] * L[i] + R[i] * R[i]) / 2;
      sum += e; ws += e;
      if ((i + 1) % win === 0) { wins.push(Math.sqrt(ws / win)); ws = 0; }
    }
    const bytes = 44 + n * 4;
    const ab = new ArrayBuffer(bytes);
    const v = new DataView(ab);
    const w = (o, s) => { for (let i = 0; i < s.length; i++) v.setUint8(o + i, s.charCodeAt(i)); };
    w(0, 'RIFF'); v.setUint32(4, bytes - 8, true); w(8, 'WAVEfmt '); v.setUint32(16, 16, true); v.setUint16(20, 1, true); v.setUint16(22, 2, true);
    v.setUint32(24, buf.sampleRate, true); v.setUint32(28, buf.sampleRate * 4, true); v.setUint16(32, 4, true); v.setUint16(34, 16, true);
    w(36, 'data'); v.setUint32(40, n * 4, true);
    for (let i = 0, o = 44; i < n; i++, o += 4) {
      v.setInt16(o, Math.max(-1, Math.min(1, L[i])) * 32767, true);
      v.setInt16(o + 2, Math.max(-1, Math.min(1, R[i])) * 32767, true);
    }
    let bin = '';
    const u8 = new Uint8Array(ab);
    for (let i = 0; i < u8.length; i += 0x8000) bin += String.fromCharCode.apply(null, u8.subarray(i, i + 0x8000));
    const db = (x) => Math.round(200 * Math.log10(x + 1e-9)) / 10;
    return { wav: btoa(bin), peak: db(peak), rms: db(Math.sqrt(sum / n)), clip, quietest: db(Math.min(...wins.slice(0, -2))), peaks: peaks.map((p) => Math.round(p * 100) / 100) };
  }, { id, seconds });

  const file = `${String(k + 1).padStart(2, '0')}-${id}.mp3`;
  const wav = join(outDir, `${id}.wav`);
  writeFileSync(wav, Buffer.from(res.wav, 'base64'));
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', wav, '-codec:a', 'libmp3lame', '-b:a', '128k', join(outDir, file)]);
  rmSync(wav);
  const problems = [];
  if (res.clip > 20) problems.push(`${res.clip} clipped samples`);
  if (res.quietest < -40) problems.push(`a silent stretch (${res.quietest} dB)`);
  if (res.rms < -20 || res.rms > -10) problems.push(`loudness ${res.rms} dB is off the -15 dB target`);
  if (problems.length) failed = true;
  report[id] = { file, seconds, rms: res.rms, peak: res.peak, peaks: res.peaks };
  console.log(`${file.padEnd(18)} rms ${res.rms} dB  peak ${res.peak} dB  quietest 2s ${res.quietest} dB${problems.length ? `  PROBLEM: ${problems.join(', ')}` : ''}`);
}
writeFileSync(join(outDir, 'samples.json'), JSON.stringify(report));
await browser.close();
server.close();
if (errors.length) { console.error(errors.join('\n')); failed = true; }
process.exit(failed ? 1 : 0);
