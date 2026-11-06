/* ============================================================
   Music engine: theme music synthesized live with Web Audio.
   Ten styles in three families (Cosmos, Spiritual, Alien).
   No audio files ship. Every instrument is built from
   oscillators, noise and filters, so the same code plays in
   the game, in the Music Lab, and renders offline to a file.

   A style schedules one segment (a few bars) at a time. The
   live player keeps the next segment queued a second ahead;
   the offline renderer queues them all up front.
   ============================================================ */

// ---------- pitch and rhythm helpers ----------
const PC = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
export function midi(name) {
  const m = /^([A-G])([#b]?)(-?\d)$/.exec(name);
  if (!m) throw new Error(`bad note ${name}`);
  return 12 * (Number(m[3]) + 1) + PC[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0);
}
export const hz = (m) => 440 * 2 ** ((m - 69) / 12);
const nhz = (name) => hz(midi(name));
const notes = (s) => s.trim().split(/\s+/).map(midi);
/** 'A5:2 C6 | D6:.5 r:.5' -> [[midi or null, beats], ...]; '|' marks bars for reading only. */
function line(s) {
  return s.trim().split(/\s+/).filter((x) => x !== '|').map((tok) => {
    const [nm, len] = tok.split(':');
    return [nm === 'r' ? null : midi(nm), len ? Number(len) : 1];
  });
}
/** Call fn(midi, time, seconds, beats) for each note of a line. Returns the end time. */
function play(seq, t, B, fn) {
  let tn = t;
  for (const [m, d] of seq) { if (m != null) fn(m, tn, d * B, d); tn += d * B; }
  return tn;
}
function mulberry32(seed) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let x = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    x = (x + Math.imul(x ^ (x >>> 7), 61 | x)) ^ x;
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };
}
function hash(s) { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); } return h >>> 0; }
const pick = (r, arr) => arr[Math.floor(r() * arr.length)];

// ---------- mixer: buses, reverb, delay ----------
function impulse(ctx, seconds, decay, dark) {
  const rate = ctx.sampleRate;
  const len = Math.max(1, Math.floor(rate * seconds));
  const buf = ctx.createBuffer(2, len, rate);
  for (let c = 0; c < 2; c++) {
    const d = buf.getChannelData(c);
    let lp = 0;
    for (let i = 0; i < len; i++) {
      const p = i / len;
      const a = Math.min(0.97, dark * p * 1.4); // the tail gets darker as it fades
      lp = lp * a + (Math.random() * 2 - 1) * (1 - a);
      d[i] = lp * (1 - p) ** decay * (i < rate * 0.012 ? i / (rate * 0.012) : 1);
    }
  }
  return buf;
}
function noiseBuffer(ctx) {
  const len = ctx.sampleRate * 2;
  const b = ctx.createBuffer(1, len, ctx.sampleRate);
  const d = b.getChannelData(0);
  for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
  return b;
}
function driveCurve(amount) {
  const n = 2048;
  const c = new Float32Array(n);
  for (let i = 0; i < n; i++) { const x = (i / (n - 1)) * 2 - 1; c[i] = Math.tanh(x * amount) / Math.tanh(amount); }
  return c;
}

export function createMixer(ctx, out, { reverb = 3, decay = 3, dark = 0.6, delay = 0.4, feedback = 0.3, delayTone = 3000, level = 1 } = {}) {
  const bus = ctx.createGain();
  bus.gain.value = level;
  const comp = ctx.createDynamicsCompressor();
  comp.threshold.value = -14;
  comp.knee.value = 10;
  comp.ratio.value = 3;
  comp.attack.value = 0.008;
  comp.release.value = 0.3;
  const limiter = ctx.createDynamicsCompressor();
  limiter.threshold.value = -3;
  limiter.knee.value = 0;
  limiter.ratio.value = 20;
  limiter.attack.value = 0.002;
  limiter.release.value = 0.15;
  bus.connect(comp);
  comp.connect(limiter);
  limiter.connect(out);

  const revIn = ctx.createGain();
  const conv = ctx.createConvolver();
  conv.buffer = impulse(ctx, reverb, decay, dark);
  revIn.connect(conv);
  conv.connect(bus);

  const dlyIn = ctx.createGain();
  const dl = ctx.createDelay(4);
  dl.delayTime.value = delay;
  const fb = ctx.createGain();
  fb.gain.value = feedback;
  const tone = ctx.createBiquadFilter();
  tone.type = 'lowpass';
  tone.frequency.value = delayTone;
  dlyIn.connect(dl);
  dl.connect(tone);
  tone.connect(fb);
  fb.connect(dl);
  tone.connect(bus);
  const dlyRev = ctx.createGain();
  dlyRev.gain.value = 0.35;
  tone.connect(dlyRev);
  dlyRev.connect(revIn);

  const keep = []; // free-running oscillators (LFOs) to stop when the music stops
  const M = { ctx, bus, keep, noise: noiseBuffer(ctx) };

  M.lfo = (freq, depth, target, type = 'sine') => {
    const o = ctx.createOscillator();
    o.type = type;
    o.frequency.value = freq;
    const g = ctx.createGain();
    g.gain.value = depth;
    o.connect(g);
    g.connect(target);
    o.start();
    keep.push(o);
    return o;
  };

  /** An instrument channel: input -> [drive] -> [filters] -> [tremolo] -> [pan] -> dry/reverb/delay sends. */
  M.channel = ({ gain = 1, pan = 0, rev = 0.3, dly = 0, dry = 1, lowpass, highpass, drive, tremolo } = {}) => {
    const input = ctx.createGain();
    input.gain.value = gain;
    let node = input;
    const chain = (n) => { node.connect(n); node = n; };
    if (drive) { const ws = ctx.createWaveShaper(); ws.curve = driveCurve(drive); ws.oversample = '2x'; chain(ws); }
    if (lowpass) { const f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = lowpass; chain(f); }
    if (highpass) { const f = ctx.createBiquadFilter(); f.type = 'highpass'; f.frequency.value = highpass; chain(f); }
    if (tremolo) {
      const g = ctx.createGain();
      g.gain.value = 1 - tremolo.depth / 2;
      M.lfo(tremolo.rate, tremolo.depth / 2, g.gain);
      chain(g);
    }
    if (pan && ctx.createStereoPanner) { const p = ctx.createStereoPanner(); p.pan.value = pan; chain(p); }
    const send = (dest, amt) => { if (amt > 0) { const g = ctx.createGain(); g.gain.value = amt; node.connect(g); g.connect(dest); } };
    send(bus, dry);
    send(revIn, rev);
    send(dlyIn, dly);
    return input;
  };
  return M;
}

// ---------- instruments ----------
// Every instrument is (M, channel, time, ...). Nothing here holds state.

/** FM bell: music box, celesta, glass, toll bell. */
export function bell(M, ch, t, freq, { dur = 2.4, vol = 0.12, ratio = 3.5, index = 1.8, modDecay = 0.3, attack = 0.002, detune = 0, bend = 0 } = {}) {
  const { ctx } = M;
  const end = t + dur;
  const car = ctx.createOscillator();
  car.frequency.value = freq;
  car.detune.setValueAtTime(detune, t);
  if (bend) car.detune.linearRampToValueAtTime(detune + bend, end);
  const mod = ctx.createOscillator();
  mod.frequency.value = freq * ratio;
  const mg = ctx.createGain();
  mg.gain.setValueAtTime(freq * index, t);
  mg.gain.exponentialRampToValueAtTime(Math.max(0.01, freq * index * 0.03), t + dur * modDecay);
  mod.connect(mg);
  mg.connect(car.frequency);
  const g = ctx.createGain();
  g.gain.setValueAtTime(0, t);
  g.gain.linearRampToValueAtTime(vol, t + attack);
  g.gain.exponentialRampToValueAtTime(0.0001, end);
  car.connect(g);
  g.connect(ch);
  car.start(t); mod.start(t);
  car.stop(end + 0.05); mod.stop(end + 0.05);
}

/** Struck metal with inharmonic partials and beating pairs: singing bowls, gongs, metallophones. */
export function struck(M, ch, t, freq, { ratios = [1], amps = [1], decays = [1], beats = [], dur = 3, vol = 0.1, attack = 0.003 } = {}) {
  const { ctx } = M;
  ratios.forEach((r, k) => {
    const d = Math.max(attack + 0.05, dur * (decays[k] ?? decays[decays.length - 1]));
    const g = ctx.createGain();
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(vol * (amps[k] ?? 0.1), t + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, t + d);
    g.connect(ch);
    const bt = beats[k] || 0;
    const fs = bt ? [freq * r - bt / 2, freq * r + bt / 2] : [freq * r];
    for (const fq of fs) {
      const o = ctx.createOscillator();
      o.frequency.value = fq;
      const og = ctx.createGain();
      og.gain.value = 1 / fs.length;
      o.connect(og);
      og.connect(g);
      o.start(t);
      o.stop(t + d + 0.05);
    }
  });
}

/** Plucked string (Karplus-Strong), rendered once per pitch and cached. */
const ksCache = new WeakMap();
function ksBuffer(ctx, freq, dur, bright, damp) {
  let cache = ksCache.get(ctx);
  if (!cache) { cache = new Map(); ksCache.set(ctx, cache); }
  const key = `${freq.toFixed(2)}|${dur}|${bright}|${damp}`;
  if (cache.has(key)) return cache.get(key);
  const sr = ctx.sampleRate;
  const len = Math.floor(sr * dur);
  const buf = ctx.createBuffer(1, len, sr);
  const d = buf.getChannelData(0);
  const N = Math.max(2, Math.round(sr / freq - 0.5));
  let lp = 0;
  let mean = 0;
  for (let i = 0; i < N && i < len; i++) { lp += bright * ((Math.random() * 2 - 1) - lp); d[i] = lp; mean += lp; }
  mean /= N;
  for (let i = 0; i < N && i < len; i++) d[i] -= mean;
  for (let i = N; i < len; i++) d[i] = damp * 0.5 * (d[i - N] + d[i - N + 1]);
  cache.set(key, buf);
  return buf;
}
export function pluck(M, ch, t, freq, { dur = 1.6, vol = 0.3, bright = 0.6, damp = 0.994, cutoff = 0, release = 0 } = {}) {
  const { ctx } = M;
  const src = ctx.createBufferSource();
  src.buffer = ksBuffer(ctx, freq, dur, bright, damp);
  const g = ctx.createGain();
  g.gain.setValueAtTime(vol, t);
  if (release) { g.gain.setValueAtTime(vol, t + Math.max(0.01, dur - release)); g.gain.linearRampToValueAtTime(0.0001, t + dur); }
  let node = src;
  if (cutoff) { const f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = cutoff; src.connect(f); node = f; }
  node.connect(g);
  g.connect(ch);
  src.start(t);
  src.stop(t + dur);
}

/** One synth note with a filter envelope: bass, arps, stabs, brass, strings. */
export function synth(M, ch, t, freq, dur, {
  type = 'sawtooth', voices = 1, spread = 8, vol = 0.08, attack = 0.005, decay = 0.2, sustain = 0.6, release = 0.15,
  cutoff = 1200, cutoffPeak, filterDecay = 0.2, q = 1, glideFrom,
} = {}) {
  const { ctx } = M;
  const end = t + Math.max(dur, attack);
  const g = ctx.createGain();
  g.gain.setValueAtTime(0, t);
  g.gain.linearRampToValueAtTime(vol, t + attack);
  g.gain.setTargetAtTime(vol * sustain, t + attack, decay / 3);
  g.gain.setTargetAtTime(0, end, release / 3);
  const lp = ctx.createBiquadFilter();
  lp.type = 'lowpass';
  lp.Q.value = q;
  lp.frequency.setValueAtTime(cutoffPeak ?? cutoff, t);
  lp.frequency.setTargetAtTime(cutoff, t + attack, filterDecay / 3);
  lp.connect(g);
  g.connect(ch);
  for (let v = 0; v < voices; v++) {
    const o = ctx.createOscillator();
    o.type = type;
    if (glideFrom) { o.frequency.setValueAtTime(glideFrom, t); o.frequency.exponentialRampToValueAtTime(freq, t + 0.08); } else o.frequency.value = freq;
    o.detune.value = voices > 1 ? (v / (voices - 1) - 0.5) * 2 * spread : 0;
    const og = ctx.createGain();
    og.gain.value = 1 / Math.sqrt(voices);
    o.connect(og);
    og.connect(lp);
    o.start(t);
    o.stop(end + release * 2 + 0.05);
  }
}

/** A sustained chord: pads, drones, organ, string clusters. */
export function pad(M, ch, t, freqs, dur, {
  type = 'sawtooth', voices = 2, spread = 10, vol = 0.05, attack = 1.5, release = 2, cutoff = 1000, cutoffEnd, q = 0.5, bend = 0,
} = {}) {
  const { ctx } = M;
  const hold = t + Math.max(attack, dur);
  const g = ctx.createGain();
  g.gain.setValueAtTime(0, t);
  g.gain.linearRampToValueAtTime(vol, t + attack);
  g.gain.setValueAtTime(vol, hold);
  g.gain.linearRampToValueAtTime(0, hold + release);
  const lp = ctx.createBiquadFilter();
  lp.type = 'lowpass';
  lp.Q.value = q;
  lp.frequency.setValueAtTime(cutoff, t);
  if (cutoffEnd) lp.frequency.linearRampToValueAtTime(cutoffEnd, hold);
  lp.connect(g);
  g.connect(ch);
  const n = freqs.length * voices;
  for (const f of freqs) {
    for (let v = 0; v < voices; v++) {
      const o = ctx.createOscillator();
      o.type = type;
      o.frequency.value = f;
      const det = voices > 1 ? (v / (voices - 1) - 0.5) * 2 * spread : 0;
      o.detune.setValueAtTime(det + (Math.random() - 0.5) * 3, t);
      if (bend) o.detune.linearRampToValueAtTime(det + bend, hold + release);
      const og = ctx.createGain();
      og.gain.value = 1 / Math.sqrt(n);
      o.connect(og);
      og.connect(lp);
      o.start(t);
      o.stop(hold + release + 0.1);
    }
  }
}

/** Choir: detuned saws through vowel formant filters, with vibrato. */
const VOWEL = {
  a: [[800, 1], [1150, 0.5], [2900, 0.1]],
  o: [[450, 1], [800, 0.4], [2830, 0.06]],
  u: [[325, 1], [700, 0.25], [2530, 0.04]],
  e: [[400, 1], [1700, 0.3], [2600, 0.12]],
};
export function choir(M, ch, t, freqs, dur, { vowel = 'a', vol = 0.06, attack = 1.6, release = 2.2, vibRate = 5.2, vibCents = 12, voices = 3, spread = 11 } = {}) {
  const { ctx } = M;
  const hold = t + Math.max(attack, dur);
  const end = hold + release;
  const g = ctx.createGain();
  g.gain.setValueAtTime(0, t);
  g.gain.linearRampToValueAtTime(vol, t + attack);
  g.gain.setValueAtTime(vol, hold);
  g.gain.linearRampToValueAtTime(0, end);
  g.connect(ch);
  const sum = ctx.createGain();
  sum.gain.value = 1 / Math.sqrt(freqs.length * voices);
  for (const [fq, amp] of VOWEL[vowel] || VOWEL.a) {
    const bp = ctx.createBiquadFilter();
    bp.type = 'bandpass';
    bp.frequency.value = fq;
    bp.Q.value = fq / 90;
    const a = ctx.createGain();
    a.gain.value = amp * 4;
    sum.connect(bp); bp.connect(a); a.connect(g);
  }
  const body = ctx.createBiquadFilter();
  body.type = 'lowpass';
  body.frequency.value = 500;
  const bg = ctx.createGain();
  bg.gain.value = 0.3;
  sum.connect(body); body.connect(bg); bg.connect(g);
  const lfo = ctx.createOscillator();
  lfo.frequency.value = vibRate;
  const lg = ctx.createGain();
  lg.gain.value = vibCents;
  lfo.connect(lg);
  lfo.start(t);
  lfo.stop(end + 0.1);
  for (const f of freqs) {
    for (let v = 0; v < voices; v++) {
      const o = ctx.createOscillator();
      o.type = 'sawtooth';
      o.frequency.value = f;
      o.detune.value = (v - (voices - 1) / 2) * spread + (Math.random() - 0.5) * 6;
      lg.connect(o.detune);
      o.connect(sum);
      o.start(t);
      o.stop(end + 0.1);
    }
  }
}

/** A gliding, singing line: theremin, ney flute, glass lead, synth lead, horn. */
export function glideLine(M, ch, t, seq, B, {
  wave = 'sine', vol = 0.1, vibRate = 5.8, vibCents = 25, vibDelay = 0.25, glide = 0.07, attack = 0.08, release = 0.25,
  cutoff = 5000, breath = 0, octave = 0,
} = {}) {
  const { ctx } = M;
  const o = ctx.createOscillator();
  if (wave === 'theremin') o.setPeriodicWave(ctx.createPeriodicWave(new Float32Array([0, 0, 0, 0, 0]), new Float32Array([0, 1, 0.3, 0.12, 0.05])));
  else o.type = wave;
  const vib = ctx.createOscillator();
  vib.frequency.value = vibRate;
  const vg = ctx.createGain();
  vg.gain.value = 0;
  vib.connect(vg);
  vg.connect(o.detune);
  const lp = ctx.createBiquadFilter();
  lp.type = 'lowpass';
  lp.frequency.value = cutoff;
  const g = ctx.createGain();
  g.gain.setValueAtTime(0, t);
  o.connect(lp); lp.connect(g); g.connect(ch);
  let bp = null;
  let src = null;
  if (breath) {
    src = ctx.createBufferSource();
    src.buffer = M.noise;
    src.loop = true;
    bp = ctx.createBiquadFilter();
    bp.type = 'bandpass';
    bp.Q.value = 12;
    const bg = ctx.createGain();
    bg.gain.value = breath * 3;
    src.connect(bp); bp.connect(bg); bg.connect(g);
  }
  let tn = t;
  let fromSilence = true;
  for (const [m, beats] of seq) {
    if (m == null) { g.gain.setTargetAtTime(0, tn, 0.05); fromSilence = true; tn += beats * B; continue; }
    const fq = hz(m + octave * 12);
    if (fromSilence) {
      o.frequency.setValueAtTime(fq, tn);
      if (bp) bp.frequency.setValueAtTime(fq, tn);
      g.gain.setTargetAtTime(vol, tn, attack / 3);
      fromSilence = false;
    } else {
      o.frequency.setTargetAtTime(fq, tn, glide / 3);
      if (bp) bp.frequency.setTargetAtTime(fq, tn, glide / 3);
      g.gain.setTargetAtTime(vol * 0.8, tn, 0.02);
      g.gain.setTargetAtTime(vol, tn + 0.06, 0.12);
    }
    vg.gain.setTargetAtTime(vibCents * 0.15, tn, 0.03);
    vg.gain.setTargetAtTime(vibCents, tn + vibDelay, 0.3);
    tn += beats * B;
  }
  g.gain.setTargetAtTime(0, tn, release / 3);
  const stop = tn + release * 2 + 0.1;
  o.start(t); vib.start(t);
  o.stop(stop); vib.stop(stop);
  if (src) { src.start(t, Math.random()); src.stop(stop); }
  return tn;
}

function noiseSrc(M, t, dur) {
  const s = M.ctx.createBufferSource();
  s.buffer = M.noise;
  s.loop = true;
  s.start(t, Math.random() * 1.5);
  s.stop(t + dur + 0.05);
  return s;
}
/** Filtered noise burst: hats, shakers, teks, brushes, scrapes, whispers. */
export function noiseHit(M, ch, t, { type = 'bandpass', freq = 2000, freqEnd, q = 1, attack = 0.001, decay = 0.1, vol = 0.2 } = {}) {
  const { ctx } = M;
  const f = ctx.createBiquadFilter();
  f.type = type;
  f.Q.value = q;
  f.frequency.setValueAtTime(freq, t);
  if (freqEnd) f.frequency.exponentialRampToValueAtTime(freqEnd, t + attack + decay);
  const g = ctx.createGain();
  g.gain.setValueAtTime(0, t);
  g.gain.linearRampToValueAtTime(vol, t + attack);
  g.gain.exponentialRampToValueAtTime(0.0001, t + attack + decay);
  noiseSrc(M, t, attack + decay).connect(f);
  f.connect(g);
  g.connect(ch);
}
/** Noise that swells in and out: wind, breath, rumble, air. */
export function swell(M, ch, t, dur, { type = 'bandpass', from = 400, to = 1200, q = 3, vol = 0.05 } = {}) {
  const { ctx } = M;
  const f = ctx.createBiquadFilter();
  f.type = type;
  f.Q.value = q;
  f.frequency.setValueAtTime(from, t);
  f.frequency.exponentialRampToValueAtTime(to, t + dur);
  const g = ctx.createGain();
  g.gain.setValueAtTime(0, t);
  g.gain.linearRampToValueAtTime(vol, t + dur * 0.5);
  g.gain.linearRampToValueAtTime(0, t + dur);
  noiseSrc(M, t, dur).connect(f);
  f.connect(g);
  g.connect(ch);
}
export function kick(M, ch, t, { vol = 0.8, from = 150, to = 48, pitchTime = 0.07, decay = 0.45, click = 0.15 } = {}) {
  const { ctx } = M;
  const o = ctx.createOscillator();
  o.frequency.setValueAtTime(from, t);
  o.frequency.exponentialRampToValueAtTime(to, t + pitchTime);
  const g = ctx.createGain();
  g.gain.setValueAtTime(vol, t);
  g.gain.exponentialRampToValueAtTime(0.0001, t + decay);
  o.connect(g);
  g.connect(ch);
  o.start(t);
  o.stop(t + decay + 0.05);
  if (click) noiseHit(M, ch, t, { type: 'highpass', freq: 2500, decay: 0.015, vol: click * vol });
}
export function taiko(M, ch, t, { vol = 0.9, pitch = 60, decay = 0.9 } = {}) {
  kick(M, ch, t, { vol, from: pitch * 2.4, to: pitch, pitchTime: 0.05, decay, click: 0 });
  kick(M, ch, t, { vol: vol * 0.3, from: pitch * 3.4, to: pitch * 1.52, pitchTime: 0.04, decay: decay * 0.5, click: 0 });
  noiseHit(M, ch, t, { type: 'lowpass', freq: 900, q: 0.7, decay: 0.14, vol: vol * 0.55 });
}
export function snare(M, ch, t, { vol = 0.4, tone = 190, decay = 0.16, bright = 1800 } = {}) {
  kick(M, ch, t, { vol: vol * 0.5, from: tone * 1.4, to: tone, pitchTime: 0.03, decay: 0.08, click: 0 });
  noiseHit(M, ch, t, { type: 'highpass', freq: bright, q: 0.7, decay, vol });
}
export const hat = (M, ch, t, { vol = 0.08, decay = 0.04, open = false } = {}) =>
  noiseHit(M, ch, t, { type: 'highpass', freq: 7500, q: 0.7, decay: open ? 0.3 : decay, vol });

// ---------- partial recipes ----------
const BOWL = { ratios: [1, 2.71, 5.15, 8.6], amps: [1, 0.5, 0.22, 0.1], decays: [1, 0.72, 0.45, 0.28], beats: [0.6, 1.3, 2.1, 3.2] };
const TINGSHA = { ratios: [1, 2.32, 4.25], amps: [1, 0.4, 0.2], decays: [1, 0.6, 0.3], beats: [7, 9, 12] };
const METAL = { ratios: [1, 2.92, 4.95, 7.1], amps: [1, 0.3, 0.12, 0.05], decays: [1, 0.35, 0.2, 0.1], beats: [4.5, 3] };
const KOTEKAN = { ratios: [1, 2.92, 4.95], amps: [1, 0.3, 0.1], decays: [1, 0.35, 0.2], beats: [4.5] };
const KETTLE = { ratios: [1, 2.0, 3.0, 4.2], amps: [1, 0.25, 0.1, 0.05], decays: [1, 0.5, 0.3, 0.2], beats: [1.2, 0.5, 0.5, 0.5] };
const GONG = { ratios: [1, 2, 2.98, 4.1, 5.4], amps: [1, 0.6, 0.35, 0.2, 0.1], decays: [1, 0.7, 0.5, 0.3, 0.2], beats: [0.9, 1.4, 2, 3, 4], attack: 0.02 };
const ZILL = { ratios: [1, 2.1, 3.7], amps: [1, 0.5, 0.25], decays: [1, 0.6, 0.35], beats: [6, 8, 10] };

const SLENDRO = [0, 240, 480, 720, 960];
const sl = (d, base = 261.63) => base * 2 ** (Math.floor(d / 5) + SLENDRO[((d % 5) + 5) % 5] / 1200);

// ============================================================
// The ten styles
// ============================================================
// seg(M, channels, startTime, segmentIndex, random, secondsPerBeat)

const LULLABY_CHORDS = {
  F: ['F2', 'F4 A4 C5'], Dm: ['D2', 'D4 F4 A4'], Bb: ['Bb2', 'Bb3 D4 F4'], C: ['C2', 'C4 E4 G4'],
  Am: ['A2', 'A3 C4 E4'], Gm7: ['G2', 'G3 Bb3 D4 F4'], C7: ['C2', 'C4 E4 G4 Bb4'],
};
const LULLABY_MELODY = [
  line('A5:2 C6 | D6 C6 A5 | Bb5 D6 F6 | E6:2 C6 | A5 C6 F6 | E6:2 C6 | D6 Bb5 G5 | E6:1.5 D6:.5 C6'),
  line('F6:2 E6 | D6 C6 A5 | Bb5 D6 G6 | E6:3 | F6 A6 G6 | E6:2 C6 | Bb5 D6 C6 | F6:3'),
];

const CELESTIAL = [
  { bass: 'D2', choir: 'D3 A3 C#4 E4', top: 'F#5:4 A5:4', bells: 'D5 E5 F#5 A5 C#6 E6' },
  { bass: 'D2', choir: 'E3 G#3 B3 E4', top: 'G#5:4 B5:4', bells: 'E5 G#5 B5 D6 E6' },
  { bass: 'B1', choir: 'D3 F#3 A3 D4', top: 'F#5:6 D5:2', bells: 'B4 D5 F#5 A5 B5' },
  { bass: 'G1', choir: 'D3 F#3 B3 C#4', top: 'B4:4 C#5:4', bells: 'G5 B5 C#6 D6 F#6' },
];

const GAMELAN_BAL = [
  [1, 2, 1, 0, 2, 3, 2, 1, 3, 2, 3, 4, 3, 2, 1, 2],
  [3, 4, 3, 2, 4, 5, 4, 3, 2, 3, 2, 1, 0, 1, 0, 2],
];

const NEBULA = [
  { bass: 'E2', pad: 'E3 B3 D4 F#4 G4' },
  { bass: 'C2', pad: 'C3 G3 B3 D4 E4' },
  { bass: 'A1', pad: 'A2 E3 G3 B3 C4' },
  { bass: 'B1', pad: 'B2 F#3 A3 E4' },
];
const NEBULA_STARS = notes('E5 G5 A5 B5 D6 E6 G6');
const NEBULA_LEAD = line('B4:6 A4:2 | G4:8 | E4:4 F#4:4 | E4:8');

const THEREMIN_BARS = [
  { root: 'D2', third: 3, vib: 'F4 A4 B4 E5' }, { root: 'D2', third: 3, vib: 'F4 A4 C5 E5' },
  { root: 'G2', third: 3, vib: 'Bb3 D4 E4 G4' }, { root: 'A2', third: 4, vib: 'C#4 G4 Bb4' },
  { root: 'D2', third: 3, vib: 'F4 A4 B4 E5' }, { root: 'Bb2', third: 4, vib: 'Ab3 D4 F4' },
  { root: 'A2', third: 4, vib: 'C#4 G4 Bb4' }, { root: 'D2', third: 3, vib: 'D4 F4 A4 C#5' },
];
const THEREMIN_MELODY = [
  line('A4:2 D5:2 | F5:3 E5:1 | D5:2 Bb4:2 | C#5:4 | A4:1 D5:1 F5:2 | Ab5:2 F5:2 | E5:2 C#5:2 | D5:2.5 D4:1.5'),
  line('F5:2 A5:2 | Bb5:2 A5:1 G5:1 | Bb5:3 G5:1 | A5:2 E5:2 | F5:1 E5:1 D5:2 | Ab5:3 F5:1 | E5:1 G5:1 C#5:2 | D5:3 r:1'),
];

const SYNTHWAVE = [
  { bass: 'A1', arp: 'A3 C4 E4 A4' }, { bass: 'F1', arp: 'F3 A3 C4 F4' },
  { bass: 'C2', arp: 'G3 C4 E4 G4' }, { bass: 'G1', arp: 'G3 B3 D4 G4' },
];
const SYNTHWAVE_LEAD = line('E5:1.5 D5:.5 C5:1 B4:1 | A4:2 C5:1 D5:1 | E5:1.5 G5:.5 E5:1 D5:1 | D5:3 B4:1');
const ARP_ORDER = [0, 1, 2, 3, 2, 1];

const OUD_LINE = line('D4:.5 Eb4:.5 F#4:1 G4:.5 A4:.5 Bb4:.5 A4:.5 | G4:1 F#4:.5 Eb4:.5 D4:2 | A4:.5 Bb4:.5 C5:1 Bb4:.5 A4:.5 G4:.5 A4:.5 | Bb4:.5 A4:.5 G4:.5 F#4:.5 Eb4:.5 F#4:.5 D4:1');
const NEY_LINE = line('A5:2 Bb5:1 A5:1 | G5:2 F#5:2 | D6:2 C6:1 Bb5:1 | A5:3 r:1');
const OUD_PEDAL = notes('D3 A3 D4 A3 Eb4 D4 A3 F#3');
const HIJAZ = notes('D4 Eb4 F#4 G4 A4 Bb4 C5 D5');

const WAR_BARS = [
  { root: 'D3', brass: 'D3 A3 D4 F4', power: 'D4 A4' },
  { root: 'Bb2', brass: 'Bb2 F3 Bb3 D4', power: 'Bb3 F4' },
  { root: 'C3', brass: 'C3 G3 C4 E4', power: 'C4 G4' },
  { root: 'A2', brass: 'A2 E3 A3 C#4', power: 'A3 E4' },
];
const WAR_HOOK = line('A4:2 D5:1 F5:1 | F5:2 E5:1 D5:1 | E5:2 G5:1 E5:1 | C#5:3 A4:1');
const WAR_OSTINATO = [0, 12, 0, 7, 0, 12, 0, 10];

export const STYLES = [
  {
    id: 'stardust', name: 'Stardust Lullaby', family: 'Cosmos', tier: 'easy',
    mood: 'Gentle, cute, twinkling',
    blurb: 'A music box spinning in zero gravity. Waltzing star chimes over a warm hum, with sparkles drifting past.',
    instruments: 'Music box, star chimes, warm pad, soft bass',
    bpm: 76, beats: 24, level: 1.5,
    mix: { reverb: 3.2, decay: 2.6, dark: 0.5, delayBeats: 0.5, feedback: 0.22, delayTone: 3500 },
    setup: (M) => ({
      box: M.channel({ rev: 0.4, dly: 0.12, pan: 0.08 }),
      arp: M.channel({ rev: 0.35, dly: 0.05, pan: -0.2, gain: 0.8 }),
      pad: M.channel({ rev: 0.6, lowpass: 2200 }),
      bass: M.channel({ rev: 0.15 }),
      spark: M.channel({ rev: 0.7, dly: 0.45, pan: 0.45 }),
    }),
    seg(M, c, t, i, r, B) {
      const A = i % 2 === 0;
      const prog = A ? ['F', 'Dm', 'Bb', 'C', 'F', 'Am', 'Gm7', 'C7'] : ['F', 'Dm', 'Bb', 'C', 'F', 'Am', 'Gm7', 'F'];
      prog.forEach((name, bar) => {
        const tb = t + bar * 3 * B;
        const [bass, tonesStr] = LULLABY_CHORDS[name];
        const tones = notes(tonesStr);
        const pat = tones.length === 4 ? [0, 1, 2, 3, 2, 1] : [0, 1, 2, -1, 2, 1];
        pat.forEach((k, j) => {
          const m = k < 0 ? tones[0] + 12 : tones[k];
          bell(M, c.arp, tb + (j * B) / 2 + r() * 0.01, hz(m), { vol: j === 0 ? 0.06 : 0.04, ratio: 4, index: 1.1, dur: 1.6, modDecay: 0.2 });
        });
        synth(M, c.bass, tb, nhz(bass), 2.6 * B, { type: 'triangle', vol: 0.2, attack: 0.02, decay: 0.6, sustain: 0.5, release: 0.4, cutoff: 700 });
        pad(M, c.pad, tb, tones.map((m) => hz(m)), 3 * B, { type: 'triangle', voices: 2, spread: 6, vol: 0.05, attack: 0.8, release: 1.2, cutoff: 1600 });
        if (r() < 0.7) bell(M, c.spark, tb + Math.floor(r() * 6) * (B / 2), hz(pick(r, [77, 79, 81, 84, 86]) + 12), { vol: 0.022, ratio: 3.5, index: 0.6, dur: 2.5 });
      });
      play(LULLABY_MELODY[A ? 0 : 1], t, B, (m, tn, d) => bell(M, c.box, tn, hz(m), { vol: 0.12, ratio: 4, index: 1.6, dur: Math.max(1.6, d + 1), modDecay: 0.25 }));
    },
  },
  {
    id: 'celestial', name: 'Celestial Choir', family: 'Spiritual', tier: 'easy',
    mood: 'Heavenly, open, uplifting',
    blurb: 'A choir of distant voices singing in a cathedral of stars. Slow, bright chords and glass bells that hang in the air.',
    instruments: 'Choir, soprano line, glass bells, deep organ',
    bpm: 60, beats: 32, level: 0.75,
    mix: { reverb: 5.5, decay: 2.4, dark: 0.45, delayBeats: 0.75, feedback: 0.35, delayTone: 3200 },
    setup: (M) => ({
      choir: M.channel({ rev: 0.75, gain: 1 }),
      top: M.channel({ rev: 0.8, dly: 0.1, gain: 1 }),
      bells: M.channel({ rev: 0.6, dly: 0.3, pan: 0.3 }),
      bells2: M.channel({ rev: 0.6, dly: 0.3, pan: -0.3 }),
      organ: M.channel({ rev: 0.5, lowpass: 900 }),
    }),
    seg(M, c, t, i, r, B) {
      CELESTIAL.forEach((cd, k) => {
        const tk = t + k * 8 * B;
        choir(M, c.choir, tk, notes(cd.choir).map(hz), 8 * B, { vowel: i % 2 ? 'o' : 'a', vol: 0.12, attack: 2, release: 2.5 });
        const root = midi(cd.bass);
        pad(M, c.organ, tk, [hz(root), hz(root + 12), hz(root + 19)], 8 * B, { type: 'sine', voices: 1, vol: 0.16, attack: 2, release: 3, cutoff: 900 });
        const pool = notes(cd.bells);
        const count = 3 + Math.floor(r() * 3);
        for (let j = 0; j < count; j++) {
          bell(M, j % 2 ? c.bells : c.bells2, tk + Math.floor(r() * 14) * (B / 2), hz(pick(r, pool)), { vol: 0.04, ratio: 3.5, index: 0.9, dur: 3.2, modDecay: 0.3 });
        }
      });
      const top = CELESTIAL.map((cd) => cd.top).join(' ');
      glideLine(M, c.top, t, line(top), B, { wave: 'sine', vol: 0.06, vibRate: 5, vibCents: 18, vibDelay: 0.6, glide: 0.25, attack: 1.2, release: 2.5 });
    },
  },
  {
    id: 'bowls', name: 'Singing Bowls', family: 'Spiritual', tier: 'easy',
    mood: 'Meditative, still, breathing',
    blurb: 'Tibetan bowls struck and rubbed in a quiet temple on a far moon. Long shimmering tones, slow breath and a low earth drone.',
    instruments: 'Singing bowls, tingsha cymbals, breath, drone',
    bpm: 60, beats: 24, level: 1.6,
    mix: { reverb: 6, decay: 2.2, dark: 0.55, delayBeats: 1.5, feedback: 0.25, delayTone: 2400 },
    setup: (M) => ({
      bowlL: M.channel({ rev: 0.55, pan: -0.35 }),
      bowlR: M.channel({ rev: 0.55, pan: 0.35 }),
      big: M.channel({ rev: 0.5 }),
      rub: M.channel({ rev: 0.6 }),
      drone: M.channel({ rev: 0.4, lowpass: 600 }),
      air: M.channel({ rev: 0.7 }),
      ting: M.channel({ rev: 0.7, dly: 0.2, pan: 0.15 }),
    }),
    seg(M, c, t, i, r, B) {
      const segDur = 24 * B;
      const pool = notes('A3 E4 F#4 A4 B4').map(hz);
      struck(M, c.big, t + r() * 0.3, nhz('D3'), { ...BOWL, dur: 16, vol: 0.2 });
      [5, 9.5, 13, 17.5, 21].forEach((b, k) => {
        if (k === 4 && r() < 0.4) return;
        struck(M, k % 2 ? c.bowlR : c.bowlL, t + (b + (r() - 0.5) * 1.2) * B, pick(r, pool), { ...BOWL, dur: 11 - k, vol: 0.1 + r() * 0.04 });
      });
      pad(M, c.rub, t, [nhz('D3') - 0.3, nhz('D3') + 0.3, nhz('D3') * 2.71], segDur + 4, { type: 'sine', voices: 1, vol: 0.035, attack: 6, release: 5, cutoff: 3000 });
      pad(M, c.drone, t, [nhz('D2'), nhz('A2')], segDur + 4, { type: 'triangle', voices: 2, spread: 4, vol: 0.09, attack: 5, release: 5, cutoff: 500 });
      swell(M, c.air, t + 8 * B, 10, { from: 300, to: 900, q: 3, vol: 0.06 });
      if (i % 2 === 1) {
        struck(M, c.ting, t + 0.2, 2380, { ...TINGSHA, dur: 7, vol: 0.04 });
        struck(M, c.ting, t + 1.1, 2395, { ...TINGSHA, dur: 6, vol: 0.03 });
      }
    },
  },
  {
    id: 'gamelan', name: 'Gamelan Starlight', family: 'Spiritual', tier: 'medium',
    mood: 'Hypnotic, shimmering, ritual',
    blurb: 'A bronze orchestra on a temple ship. Interlocking metallophones ripple around a five-note scale, with a great gong at every cycle.',
    instruments: 'Metallophones, interlocking chimes, gongs, hand drum',
    bpm: 84, beats: 16, level: 2.0,
    mix: { reverb: 4, decay: 2.8, dark: 0.55, delayBeats: 0.5, feedback: 0.2, delayTone: 3000 },
    setup: (M) => ({
      saron: M.channel({ rev: 0.4 }),
      kotL: M.channel({ rev: 0.35, pan: -0.45, gain: 0.9 }),
      kotR: M.channel({ rev: 0.35, pan: 0.45, gain: 0.9 }),
      gong: M.channel({ rev: 0.5 }),
      kenong: M.channel({ rev: 0.45, pan: 0.2 }),
      kendang: M.channel({ rev: 0.2, pan: -0.1 }),
      star: M.channel({ rev: 0.7, dly: 0.3 }),
    }),
    seg(M, c, t, i, r, B) {
      const bal = GAMELAN_BAL[i % 2];
      struck(M, c.gong, t, 65.4, { ...GONG, dur: 10, vol: 0.24 });
      if (i % 2 === 0) pad(M, c.star, t, [sl(5), sl(7)], 32 * B, { type: 'sine', voices: 2, spread: 5, vol: 0.03, attack: 4, release: 4, cutoff: 4000 });
      bal.forEach((d, k) => {
        const tk = t + k * B;
        struck(M, c.saron, tk, sl(d), { ...METAL, dur: 1.8, vol: 0.12 });
        if (k % 4 === 3) struck(M, c.kenong, tk, sl(d), { ...KETTLE, dur: 3, vol: 0.09 });
        if (k === 6 || k === 10 || k === 14) struck(M, c.gong, tk, sl(d, 130.8), { ...GONG, dur: 4, vol: 0.12 });
        if (i > 0) {
          const target = bal[(k + 1) % 16];
          const P = k % 8 < 4 ? [1, 0, -1, 0] : [0, 1, 0, 2];
          P.forEach((p, j) => struck(M, j % 2 ? c.kotR : c.kotL, tk + (j * B) / 4, sl(target + 5 + p), { ...KOTEKAN, dur: 0.7, vol: 0.045 }));
        }
        const g = k % 4;
        if (g === 0 || (g === 2 && r() < 0.5)) kick(M, c.kendang, tk + (g === 2 ? B / 2 : 0), { vol: 0.32, from: 170, to: 95, decay: 0.3, click: 0.05 });
        if (g === 1 || g === 3) noiseHit(M, c.kendang, tk + B / 2, { freq: 2600, q: 1.2, decay: 0.05, vol: 0.1 });
      });
    },
  },
  {
    id: 'nebula', name: 'Nebula Drift', family: 'Cosmos', tier: 'medium',
    mood: 'Dreamy, vast, floating',
    blurb: 'Floating through glowing gas clouds. Wide evolving pads, a deep pulse of sub bass and star pings echoing into the distance.',
    instruments: 'Evolving pads, sub bass, echoing star pings, glass lead',
    bpm: 66, beats: 32, level: 0.88,
    mix: { reverb: 6, decay: 2.2, dark: 0.5, delayBeats: 0.75, feedback: 0.5, delayTone: 2800 },
    setup: (M) => ({
      pad: M.channel({ rev: 0.65, dly: 0.12 }),
      sub: M.channel({ rev: 0.1 }),
      pingL: M.channel({ rev: 0.5, dly: 0.6, pan: -0.5 }),
      pingR: M.channel({ rev: 0.5, dly: 0.6, pan: 0.5 }),
      air: M.channel({ rev: 0.8 }),
      lead: M.channel({ rev: 0.7, dly: 0.35 }),
    }),
    seg(M, c, t, i, r, B) {
      NEBULA.forEach((cd, k) => {
        const tk = t + k * 8 * B;
        pad(M, c.pad, tk, notes(cd.pad).map(hz), 8 * B, { type: 'sawtooth', voices: 3, spread: 12, vol: 0.09, attack: 3, release: 4, cutoff: 500, cutoffEnd: 1500 });
        synth(M, c.sub, tk, nhz(cd.bass), 8 * B, { type: 'sine', vol: 0.22, attack: 1.2, decay: 2, sustain: 0.8, release: 2, cutoff: 400 });
        const n = 3 + Math.floor(r() * 3);
        for (let j = 0; j < n; j++) {
          bell(M, j % 2 ? c.pingR : c.pingL, tk + Math.floor(r() * 16) * (B / 2), hz(pick(r, NEBULA_STARS)), { ratio: 2, index: 0.5, dur: 1.2, vol: 0.05, modDecay: 0.2 });
        }
        swell(M, c.air, tk + 2 * B, 6 * B, { from: 3000, to: 7000, q: 1, vol: 0.02 });
      });
      if (i % 2 === 1) glideLine(M, c.lead, t, NEBULA_LEAD, B, { wave: 'sine', vol: 0.08, vibCents: 10, vibRate: 4.5, glide: 0.3, attack: 0.8, release: 2 });
    },
  },
  {
    id: 'theremin', name: 'Theremin Invaders', family: 'Alien', tier: 'medium',
    mood: 'Retro, spooky, playful',
    blurb: 'A 1950s flying-saucer movie. A wobbling theremin sings over walking bass, brushed drums and a cool vibraphone.',
    instruments: 'Theremin, upright bass, vibraphone, brushes',
    bpm: 96, beats: 32, level: 0.98,
    mix: { reverb: 2.4, decay: 3, dark: 0.5, delayBeats: 0.5, feedback: 0.25, delayTone: 2500 },
    setup: (M) => ({
      ther: M.channel({ rev: 0.45, dly: 0.2 }),
      bass: M.channel({ rev: 0.12, lowpass: 1600 }),
      vib: M.channel({ rev: 0.4, pan: -0.25, tremolo: { rate: 5.2, depth: 0.5 } }),
      kit: M.channel({ rev: 0.2, pan: 0.2 }),
    }),
    seg(M, c, t, i, r, B) {
      const sw = 0.64; // swing
      THEREMIN_BARS.forEach((bar, k) => {
        const tb = t + k * 4 * B;
        const root = midi(bar.root);
        const next = midi(THEREMIN_BARS[(k + 1) % 8].root);
        const walk = [root, root + bar.third, root + 7, next - 1 === root + 7 ? next + 1 : next - 1];
        walk.forEach((m, q) => pluck(M, c.bass, tb + q * B, hz(m), { dur: 1.2, vol: 0.5, bright: 0.45, damp: 0.995 }));
        notes(bar.vib).forEach((m, j) => bell(M, c.vib, tb + j * 0.012, hz(m), { ratio: 4, index: 0.8, dur: 2.6, vol: 0.05 }));
        if (k % 2 === 1) notes(bar.vib).forEach((m, j) => bell(M, c.vib, tb + (2 + sw) * B + j * 0.01, hz(m), { ratio: 4, index: 0.6, dur: 1.2, vol: 0.03 }));
        for (let q = 0; q < 4; q++) {
          noiseHit(M, c.kit, tb + q * B, { type: 'highpass', freq: 5000, decay: 0.22, vol: 0.035 });
          if (q % 2 === 1) {
            noiseHit(M, c.kit, tb + q * B, { freq: 3800, q: 0.8, attack: 0.03, decay: 0.16, vol: 0.06 });
            noiseHit(M, c.kit, tb + (q + sw) * B, { type: 'highpass', freq: 5000, decay: 0.12, vol: 0.025 });
          } else kick(M, c.kit, tb + q * B, { vol: 0.25, from: 110, to: 50, decay: 0.25, click: 0 });
        }
      });
      glideLine(M, c.ther, t, THEREMIN_MELODY[i % 2], B, { wave: 'theremin', vol: 0.12, vibRate: 6, vibCents: 30, vibDelay: 0.2, glide: 0.14, attack: 0.15, release: 0.6, cutoff: 3500 });
    },
  },
  {
    id: 'synthwave', name: 'Synthwave Odyssey', family: 'Cosmos', tier: 'hard',
    mood: 'Driving, neon, heroic',
    blurb: 'Racing a neon starship past Saturn. Pulsing bass, sparkling arpeggios, punchy drums and a soaring lead.',
    instruments: 'Arpeggiator, pulse bass, poly pads, drums, lead synth',
    bpm: 104, beats: 16, level: 1.6,
    mix: { reverb: 2.2, decay: 3, dark: 0.5, delayBeats: 0.75, feedback: 0.35, delayTone: 3200 },
    setup: (M) => ({
      arp: M.channel({ rev: 0.25, dly: 0.3, pan: 0.2 }),
      bass: M.channel({ rev: 0.05 }),
      pad: M.channel({ rev: 0.4, pan: -0.15 }),
      drums: M.channel({ rev: 0.12 }),
      snare: M.channel({ rev: 0.55 }),
      lead: M.channel({ rev: 0.35, dly: 0.25 }),
    }),
    seg(M, c, t, i, r, B) {
      SYNTHWAVE.forEach((cd, k) => {
        const tb = t + k * 4 * B;
        const tones = notes(cd.arp);
        for (let j = 0; j < 16; j++) {
          synth(M, c.arp, tb + (j * B) / 4, hz(tones[ARP_ORDER[(k * 16 + j) % 6]] + 12), B / 4, { vol: 0.05, cutoff: 700, cutoffPeak: 3200, filterDecay: 0.12, decay: 0.1, sustain: 0.3, release: 0.08 });
        }
        const root = midi(cd.bass);
        for (let j = 0; j < 8; j++) synth(M, c.bass, tb + (j * B) / 2, hz(root + (j % 2 ? 12 : 0)), B / 2.2, { vol: 0.13, cutoff: 380, cutoffPeak: 1100, filterDecay: 0.1, decay: 0.15, sustain: 0.5, release: 0.05 });
        pad(M, c.pad, tb, tones.map((m) => hz(m + 12)), 4 * B, { type: 'sawtooth', voices: 2, spread: 9, vol: 0.05, attack: 0.3, release: 0.8, cutoff: 2000 });
        if (i > 0) {
          kick(M, c.drums, tb, { vol: 0.85 });
          kick(M, c.drums, tb + 2 * B, { vol: 0.85 });
          if (k % 2) kick(M, c.drums, tb + 2.75 * B, { vol: 0.6 });
          snare(M, c.snare, tb + B, { vol: 0.32 });
          snare(M, c.snare, tb + 3 * B, { vol: 0.32 });
          for (let j = 0; j < 8; j++) hat(M, c.drums, tb + (j * B) / 2, { vol: j % 2 ? 0.07 : 0.035, open: j === 7 });
        }
      });
      if (i % 4 >= 2) glideLine(M, c.lead, t, SYNTHWAVE_LEAD, B, { wave: 'sawtooth', vol: 0.07, cutoff: 2400, vibRate: 5.5, vibCents: 12, vibDelay: 0.3, glide: 0.06, attack: 0.02, release: 0.3 });
    },
  },
  {
    id: 'oracle', name: 'Desert Oracle', family: 'Spiritual', tier: 'medium',
    mood: 'Ancient, mysterious, rhythmic',
    blurb: 'Night over the pyramids as the stars align. An oud and a breathy ney flute trade an old scale over hand drums and a desert drone.',
    instruments: 'Oud, ney flute, doumbek, finger cymbals, drone',
    bpm: 92, beats: 16, level: 1.8,
    mix: { reverb: 3, decay: 2.8, dark: 0.55, delayBeats: 0.75, feedback: 0.25, delayTone: 2600 },
    setup: (M) => ({
      oud: M.channel({ rev: 0.35, pan: -0.15 }),
      ney: M.channel({ rev: 0.55, dly: 0.15, pan: 0.15 }),
      drum: M.channel({ rev: 0.2 }),
      riq: M.channel({ rev: 0.2, pan: 0.3 }),
      drone: M.channel({ rev: 0.4 }),
      zill: M.channel({ rev: 0.5, pan: 0.35 }),
    }),
    seg(M, c, t, i, r, B) {
      pad(M, c.drone, t, notes('D2 A2 D3').map(hz), 16 * B + 1, { type: 'sawtooth', voices: 2, spread: 6, vol: 0.07, attack: 2, release: 2, cutoff: 450 });
      struck(M, c.zill, t, 2650, { ...ZILL, dur: 2.5, vol: 0.035 });
      struck(M, c.zill, t + B / 2, 2680, { ...ZILL, dur: 2, vol: 0.025 });
      for (let k = 0; k < 4; k++) {
        const tb = t + k * 4 * B;
        for (const b of [0, 2]) kick(M, c.drum, tb + b * B, { vol: 0.5, from: 140, to: 85, decay: 0.35, click: 0.05 });
        const teks = k === 3 ? [0.5, 1.5, 3, 3.25, 3.5, 3.75] : [0.5, 1.5, 3];
        for (const b of teks) noiseHit(M, c.drum, tb + b * B, { freq: 3300, q: 1.5, decay: 0.06, vol: 0.16 });
        for (const b of [2.5, 3.5]) if (k !== 3) noiseHit(M, c.drum, tb + b * B, { freq: 3000, q: 1.5, decay: 0.04, vol: 0.06 });
        for (let j = 0; j < 8; j++) noiseHit(M, c.riq, tb + (j * B) / 2, { type: 'highpass', freq: 6000, decay: 0.05, vol: j % 2 ? 0.018 : 0.035 });
      }
      if (i % 2 === 0) {
        play(OUD_LINE, t, B, (m, tn, d, beats) => {
          if (r() < 0.25 && beats >= 0.5) {
            const up = HIJAZ.find((x) => x > m) ?? m + 1;
            pluck(M, c.oud, tn - 0.05, hz(up), { dur: 0.3, vol: 0.18, bright: 0.65, damp: 0.99 });
          }
          pluck(M, c.oud, tn, hz(m), { dur: 1.6, vol: 0.34, bright: 0.65, damp: 0.993 });
          if (beats >= 2) for (let s = 0.25; s < beats; s += 0.25) pluck(M, c.oud, tn + s * B, hz(m), { dur: 0.6, vol: 0.16, bright: 0.6, damp: 0.99 });
        });
      } else {
        glideLine(M, c.ney, t, NEY_LINE, B, { wave: 'triangle', vol: 0.1, breath: 0.35, vibRate: 5, vibCents: 14, vibDelay: 0.3, glide: 0.08, attack: 0.15, release: 0.4, cutoff: 2500 });
        for (let k = 0; k < 4; k++) {
          OUD_PEDAL.forEach((m, j) => pluck(M, c.oud, t + (k * 4 + j / 2) * B, hz(k === 3 && j === 7 ? midi('D3') : m), { dur: 0.9, vol: j % 2 ? 0.16 : 0.24, bright: 0.6, damp: 0.99 }));
        }
      }
    },
  },
  {
    id: 'wardrums', name: 'War Drums of Orion', family: 'Alien', tier: 'hard',
    mood: 'Epic, powerful, menacing',
    blurb: 'The Orion war fleet arrives. Thundering taiko, driving strings, brass blasts and a massive alien horn.',
    instruments: 'Taiko ensemble, strings, brass, choir, alien horn',
    bpm: 108, beats: 16, level: 0.55,
    mix: { reverb: 2.6, decay: 2.8, dark: 0.55, delayBeats: 0.5, feedback: 0.2, delayTone: 2200 },
    setup: (M) => ({
      taiko: M.channel({ rev: 0.3, drive: 1.6 }),
      rim: M.channel({ rev: 0.25, pan: 0.25 }),
      strings: M.channel({ rev: 0.3, pan: -0.2 }),
      brass: M.channel({ rev: 0.35, pan: 0.1 }),
      choir: M.channel({ rev: 0.6 }),
      braam: M.channel({ rev: 0.4, drive: 2.5, lowpass: 2500 }),
      horn: M.channel({ rev: 0.45, dly: 0.12 }),
    }),
    seg(M, c, t, i, r, B) {
      if (i % 2 === 0) pad(M, c.braam, t, notes('D2 A2 D3').map(hz), 2.5 * B, { type: 'sawtooth', voices: 3, spread: 18, vol: 0.14, attack: 0.12, release: 1.5, cutoff: 250, cutoffEnd: 1800 });
      WAR_BARS.forEach((bar, k) => {
        const tb = t + k * 4 * B;
        const root = midi(bar.root);
        taiko(M, c.taiko, tb, { vol: 1, pitch: 55, decay: 1 });
        taiko(M, c.taiko, tb + 2 * B, { vol: 0.9, pitch: 55, decay: 0.9 });
        for (const b of [1, 1.5, 3, 3.25, 3.5]) taiko(M, c.taiko, tb + b * B, { vol: 0.45, pitch: 95, decay: 0.35 });
        if (k === 3) for (let s = 0; s < 8; s++) taiko(M, c.taiko, tb + (2 + s / 4) * B, { vol: 0.3 + s * 0.06, pitch: 80, decay: 0.3 });
        for (const b of [1, 3]) noiseHit(M, c.rim, tb + b * B, { freq: 1800, q: 2, decay: 0.04, vol: 0.12 });
        WAR_OSTINATO.forEach((o, j) => synth(M, c.strings, tb + (j * B) / 2, hz(root + o), 0.4 * B, { voices: 2, spread: 7, vol: 0.06, cutoff: 1800, cutoffPeak: 3000, decay: 0.1, sustain: 0.25, release: 0.08 }));
        notes(bar.brass).forEach((m) => synth(M, c.brass, tb, hz(m), 1.5 * B, { voices: 2, spread: 6, vol: 0.05, attack: 0.04, cutoff: 900, cutoffPeak: 2600, filterDecay: 0.3, sustain: 0.7, release: 0.25 }));
        if (i % 2 === 1) choir(M, c.choir, tb, notes(bar.power).map(hz), 4 * B, { vowel: 'o', vol: 0.09, attack: 0.3, release: 0.8 });
      });
      if (i % 2 === 1) glideLine(M, c.horn, t, WAR_HOOK, B, { wave: 'sawtooth', vol: 0.08, cutoff: 1600, vibRate: 4, vibCents: 8, vibDelay: 0.4, glide: 0.06, attack: 0.06, release: 0.4 });
    },
  },
  {
    id: 'abyss', name: 'Abyssal Horror', family: 'Alien', tier: 'alien',
    mood: 'Dread, gnarly, heart-pounding',
    blurb: 'Something vast is awake in the dark between stars. A slow heartbeat, grinding drones, metal scraping and voices that should not be there.',
    instruments: 'Heartbeat, grinding drone, scrapes, toll bell, growls, whispers',
    bpm: 54, beats: 16, level: 0.97,
    mix: { reverb: 5, decay: 2, dark: 0.8, delayBeats: 0.66, feedback: 0.35, delayTone: 1800 },
    setup: (M) => ({
      drone: M.channel({ rev: 0.35, drive: 2 }),
      heart: M.channel({ rev: 0.15, lowpass: 400 }),
      strings: M.channel({ rev: 0.6, highpass: 900, tremolo: { rate: 9, depth: 0.8 } }),
      scrapeL: M.channel({ rev: 0.6, dly: 0.2, pan: -0.6 }),
      scrapeR: M.channel({ rev: 0.6, dly: 0.2, pan: 0.6 }),
      bell: M.channel({ rev: 0.6 }),
      voice: M.channel({ rev: 0.5, drive: 3, tremolo: { rate: 14, depth: 0.7 } }),
      whisper: M.channel({ rev: 0.6, dly: 0.3, pan: -0.4 }),
      sting: M.channel({ rev: 0.45, drive: 2.5 }),
      rumble: M.channel({ rev: 0.2 }),
    }),
    seg(M, c, t, i, r, B) {
      const segDur = 16 * B;
      pad(M, c.drone, t, notes('C2 Db2 F#2').map(hz), segDur + 3, { type: 'sawtooth', voices: 2, spread: 15, vol: 0.11, attack: 4, release: 5, cutoff: 220, cutoffEnd: 420 });
      swell(M, c.rumble, t, segDur, { type: 'lowpass', from: 140, to: 70, q: 1, vol: 0.18 });
      for (let b = i === 0 ? 4 : 0; b < 16; b++) {
        kick(M, c.heart, t + b * B, { vol: 0.6, from: 90, to: 42, decay: 0.3, click: 0 });
        kick(M, c.heart, t + b * B + 0.3, { vol: 0.38, from: 80, to: 40, decay: 0.25, click: 0 });
      }
      if (i % 2 === 1) pad(M, c.strings, t, notes('E5 F5 Bb5').map(hz), 12 * B, { type: 'sawtooth', voices: 1, vol: 0.035, attack: 6, release: 4, cutoff: 5000, bend: -120 });
      for (let s = 0; s < 2; s++) {
        noiseHit(M, s ? c.scrapeR : c.scrapeL, t + (2 + r() * 12) * B, { freq: 3500, freqEnd: 700, q: 18, attack: 0.4, decay: 1.6, vol: 0.35 });
      }
      if (i % 2 === 0) {
        bell(M, c.bell, t, nhz('C3'), { ratio: 1.41, index: 3.5, dur: 6, vol: 0.09, modDecay: 0.6, bend: -150 });
        bell(M, c.bell, t + 8 * B, nhz('F#2'), { ratio: 1.41, index: 3.5, dur: 6, vol: 0.08, modDecay: 0.6, bend: -150 });
      }
      const tg = t + (4 + r() * 6) * B;
      synth(M, c.voice, tg, 55, 2.2, { voices: 2, spread: 25, vol: 0.12, attack: 0.4, sustain: 1, decay: 1, release: 0.8, cutoff: 900, q: 6, glideFrom: 70 });
      if (i % 2 === 1) {
        let tw = t + (2 + r() * 8) * B;
        for (let w = 0; w < 7; w++) {
          const d = 0.06 + r() * 0.16;
          noiseHit(M, c.whisper, tw, { freq: 2500 + r() * 2000, q: 3, attack: 0.03, decay: d, vol: 0.09 });
          tw += d + 0.08 + r() * 0.2;
        }
      }
      if (i % 3 === 2) {
        const ts = t + 12 * B;
        taiko(M, c.sting, ts, { vol: 1, pitch: 40, decay: 1.4 });
        notes('C3 Db3 F#3 G3').forEach((m) => synth(M, c.sting, ts, hz(m), 1.5, { voices: 2, spread: 12, vol: 0.045, cutoff: 600, cutoffPeak: 3000, filterDecay: 0.5, sustain: 0.6, release: 1 }));
      }
    },
  },
];

export const STYLE_BY_ID = Object.fromEntries(STYLES.map((s) => [s.id, s]));
export const segSeconds = (style) => (style.beats * 60) / style.bpm;

function mixerFor(ctx, out, style) {
  const B = 60 / style.bpm;
  return createMixer(ctx, out, { ...style.mix, delay: (style.mix.delayBeats || 0.5) * B, level: style.level });
}

/**
 * Play a style live. Returns { stop(fadeSeconds), output }.
 * The style's notes are scheduled a segment at a time, about a second ahead.
 */
export function playStyle(ctx, dest, styleOrId, { fadeIn = 1.2, seed = 1 } = {}) {
  const style = typeof styleOrId === 'string' ? STYLE_BY_ID[styleOrId] : styleOrId;
  const out = ctx.createGain();
  out.gain.setValueAtTime(0, ctx.currentTime);
  out.gain.linearRampToValueAtTime(1, ctx.currentTime + fadeIn);
  out.connect(dest);
  const M = mixerFor(ctx, out, style);
  const ch = style.setup(M);
  const B = 60 / style.bpm;
  const segDur = segSeconds(style);
  let next = ctx.currentTime + 0.15;
  let i = 0;
  let stopped = false;
  const tick = () => {
    if (stopped) return;
    if (next < ctx.currentTime) next = ctx.currentTime + 0.05; // came back from a suspend
    while (next < ctx.currentTime + 1.2) {
      style.seg(M, ch, next, i, mulberry32(hash(style.id) + seed * 7919 + i), B);
      i++;
      next += segDur;
    }
  };
  tick();
  const timer = setInterval(tick, 300);
  return {
    output: out,
    style,
    stop(fade = 1) {
      if (stopped) return;
      stopped = true;
      clearInterval(timer);
      const now = ctx.currentTime;
      out.gain.cancelScheduledValues(now);
      out.gain.setValueAtTime(out.gain.value, now);
      out.gain.linearRampToValueAtTime(0, now + fade);
      setTimeout(() => {
        for (const o of M.keep) { try { o.stop(); } catch { /* already stopped */ } }
        try { out.disconnect(); } catch { /* ignore */ }
      }, (fade + 0.3) * 1000);
    },
  };
}

/** Render a style offline to an AudioBuffer (for samples and tests). */
export async function renderStyle(styleOrId, seconds = 40, { sampleRate = 44100, seed = 1, fadeOut = 3 } = {}) {
  const style = typeof styleOrId === 'string' ? STYLE_BY_ID[styleOrId] : styleOrId;
  const Offline = globalThis.OfflineAudioContext || globalThis.webkitOfflineAudioContext;
  const ctx = new Offline(2, Math.ceil(seconds * sampleRate), sampleRate);
  const out = ctx.createGain();
  out.gain.setValueAtTime(1, 0);
  out.gain.setValueAtTime(1, Math.max(0, seconds - fadeOut));
  out.gain.linearRampToValueAtTime(0, seconds);
  out.connect(ctx.destination);
  const M = mixerFor(ctx, out, style);
  const ch = style.setup(M);
  const B = 60 / style.bpm;
  const segDur = segSeconds(style);
  for (let t = 0.05, i = 0; t < seconds; t += segDur, i++) style.seg(M, ch, t, i, mulberry32(hash(style.id) + seed * 7919 + i), B);
  return ctx.startRendering();
}
