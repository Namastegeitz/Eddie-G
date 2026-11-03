/* ============================================================
   Audio — every sound is synthesized with the Web Audio API
   (ported from the original game), so the app ships no audio
   files. Separate gain buses for effects and music.
   The AudioContext is created on the first user gesture,
   because browsers and mobile webviews block audio before that.
   ============================================================ */

const H = {
  D2: 73.42, A2: 110.0, B2: 123.47, D3: 146.83, E3: 164.81, Fs3: 185.0,
  G3: 196.0, Ab3: 207.65, A3: 220.0, Bb3: 233.08, B3: 246.94,
  C4: 261.63, Cs4: 277.18, D4: 293.66, Eb4: 311.13, E4: 329.63,
  F4: 349.23, Fs4: 369.99, G4: 392.0, Ab4: 415.3, A4: 440.0,
  Bb4: 466.16, B4: 493.88, C5: 523.25, D5: 587.33, Eb5: 622.25,
  E5: 659.25, F5: 698.46, Fs5: 739.99, G5: 783.99, A5: 880.0, C6: 1046.5,
};

// Each melody note: [freq, startMs, durMs, relVol, oscType]
export const TRACKS = [
  {
    name: 'The Signal', padFreqs: [H.D2, H.A2], loopMs: 8400,
    melody: [
      [H.D4, 0, 350, 0.9, 'triangle'], [H.F4, 900, 280, 0.8, 'triangle'],
      [H.Eb4, 1400, 280, 0.8, 'triangle'], [H.Cs4, 1900, 350, 0.85, 'triangle'],
      [H.D4, 2600, 700, 0.9, 'triangle'], [H.D4, 4300, 350, 0.75, 'triangle'],
      [H.F4, 5200, 280, 0.7, 'triangle'], [H.Eb4, 5700, 280, 0.7, 'triangle'],
      [H.Cs4, 6200, 350, 0.75, 'triangle'], [H.A3, 6900, 900, 0.85, 'triangle'],
    ],
  },
  {
    name: 'Abduction', padFreqs: [H.A2, H.E3, H.A3], loopMs: 3500,
    melody: [
      [H.A3, 0, 200, 0.7, 'sawtooth'], [H.B3, 350, 200, 0.7, 'sawtooth'],
      [H.C4, 700, 200, 0.65, 'sawtooth'], [H.Cs4, 1050, 200, 0.65, 'sawtooth'],
      [H.D4, 1400, 400, 0.8, 'sawtooth'], [H.A3, 2200, 700, 0.7, 'sawtooth'],
    ],
  },
  {
    name: 'Void Drifter', padFreqs: [H.G3, H.D3], loopMs: 9000,
    melody: [[H.G4, 0, 1200, 0.5, 'sine'], [H.C5, 3000, 800, 0.4, 'sine'], [H.E4, 6000, 1000, 0.45, 'sine']],
  },
  {
    name: 'Ancient Runes', padFreqs: [H.D2, H.A2, H.E3], loopMs: 3500,
    melody: [
      [H.D4, 0, 180, 0.8, 'triangle'], [H.F4, 250, 180, 0.75, 'triangle'],
      [H.G4, 500, 180, 0.75, 'triangle'], [H.A4, 750, 180, 0.8, 'triangle'],
      [H.C5, 1000, 180, 0.7, 'triangle'], [H.A4, 1300, 180, 0.7, 'triangle'],
      [H.G4, 1550, 250, 0.75, 'triangle'], [H.F4, 1900, 350, 0.8, 'triangle'],
      [H.D4, 2400, 500, 0.85, 'triangle'],
    ],
  },
  {
    name: 'Close Encounter', padFreqs: [H.D2, H.Ab3], loopMs: 4000,
    melody: [
      [H.D3, 0, 300, 0.7, 'sawtooth'], [H.Ab3, 500, 300, 0.65, 'sawtooth'],
      [H.D3, 1000, 300, 0.7, 'sawtooth'], [H.Ab3, 1500, 500, 0.7, 'sawtooth'],
      [H.E3, 2500, 200, 0.6, 'sawtooth'], [H.Ab3, 2900, 300, 0.65, 'sawtooth'],
    ],
  },
  {
    name: 'Beyond the Stars', padFreqs: [H.G3, H.D3, H.B3], loopMs: 7000,
    melody: [
      [H.G4, 0, 600, 0.55, 'sine'], [H.B4, 800, 500, 0.5, 'sine'],
      [H.D5, 1600, 500, 0.45, 'sine'], [H.Fs5, 2400, 700, 0.4, 'sine'],
      [H.D5, 3500, 500, 0.45, 'sine'], [H.B4, 4200, 500, 0.5, 'sine'],
      [H.G4, 5000, 800, 0.55, 'sine'],
    ],
  },
  {
    name: 'Hieroglyph', padFreqs: [H.E3, H.B3], loopMs: 2500,
    melody: [
      [H.E4, 0, 120, 0.7, 'triangle'], [H.F4, 170, 120, 0.65, 'triangle'],
      [H.A4, 340, 120, 0.7, 'triangle'], [H.Bb4, 510, 120, 0.65, 'triangle'],
      [H.D5, 680, 200, 0.7, 'triangle'], [H.Bb4, 1000, 120, 0.6, 'triangle'],
      [H.A4, 1170, 120, 0.6, 'triangle'], [H.F4, 1340, 150, 0.65, 'triangle'],
      [H.E4, 1600, 300, 0.7, 'triangle'],
    ],
  },
];

const audio = {
  ctx: null,
  master: null,
  sfxBus: null,
  musicBus: null,
  unlocked: false,
  sfxOn: true,
  musicOn: true,
  sfxVolume: 0.8,
  musicVolume: 0.6,
  suspendedByApp: false,
};

function ensureCtx() {
  if (audio.ctx) return audio.ctx;
  const Ctx = window.AudioContext || window.webkitAudioContext;
  if (!Ctx) return null;
  audio.ctx = new Ctx();
  audio.master = audio.ctx.createGain();
  audio.master.gain.value = 0.22;
  audio.master.connect(audio.ctx.destination);
  audio.sfxBus = audio.ctx.createGain();
  audio.sfxBus.gain.value = audio.sfxVolume;
  audio.sfxBus.connect(audio.master);
  audio.musicBus = audio.ctx.createGain();
  audio.musicBus.gain.value = audio.musicVolume;
  audio.musicBus.connect(audio.master);
  return audio.ctx;
}

/** Call from the first pointer/key event. Safe to call repeatedly. */
export function unlockAudio() {
  const ctx = ensureCtx();
  if (!ctx) return;
  if (ctx.state === 'suspended' && !audio.suspendedByApp) ctx.resume().catch(() => {});
  if (!audio.unlocked) {
    audio.unlocked = true;
    if (audio.musicOn) music.start();
  }
}

export function configureAudio({ sfx, sfxVolume, music: musicOn, musicVolume }) {
  if (sfx != null) audio.sfxOn = sfx;
  if (sfxVolume != null) audio.sfxVolume = sfxVolume;
  if (musicVolume != null) audio.musicVolume = musicVolume;
  if (audio.sfxBus) audio.sfxBus.gain.setTargetAtTime(audio.sfxVolume, audio.ctx.currentTime, 0.05);
  if (audio.musicBus) audio.musicBus.gain.setTargetAtTime(audio.musicVolume, audio.ctx.currentTime, 0.1);
  if (musicOn != null && musicOn !== audio.musicOn) {
    audio.musicOn = musicOn;
    if (musicOn) { if (audio.unlocked) music.start(); } else music.stop();
  }
}

/** App went to background / came back. */
export function setAudioSuspended(suspended) {
  audio.suspendedByApp = suspended;
  if (!audio.ctx) return;
  if (suspended) audio.ctx.suspend().catch(() => {});
  else if (audio.unlocked) audio.ctx.resume().catch(() => {});
}

// ---------------------------------------------------------
// Sound effects
// ---------------------------------------------------------
function tone({ freq, dur = 0.18, type = 'sine', vol = 1, slideTo = null, delay = 0 }) {
  if (!audio.sfxOn || !audio.unlocked) return;
  const ctx = ensureCtx();
  if (!ctx || ctx.state !== 'running') return;
  const t0 = ctx.currentTime + delay;
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, t0);
  if (slideTo != null) osc.frequency.exponentialRampToValueAtTime(slideTo, t0 + dur);
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(vol, t0 + 0.012);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  osc.connect(g).connect(audio.sfxBus);
  osc.start(t0);
  osc.stop(t0 + dur + 0.05);
}

export const sfx = {
  place() { tone({ freq: 660, slideTo: 880, dur: 0.12, type: 'triangle', vol: 0.9 }); },
  note() { tone({ freq: 990, dur: 0.06, type: 'sine', vol: 0.4 }); },
  erase() { tone({ freq: 320, slideTo: 180, dur: 0.1, type: 'sine', vol: 0.6 }); },
  select() { tone({ freq: 1320, dur: 0.05, type: 'sine', vol: 0.35 }); },
  tap() { tone({ freq: 880, dur: 0.04, type: 'sine', vol: 0.3 }); },
  reject() {
    tone({ freq: 220, slideTo: 90, dur: 0.22, type: 'sawtooth', vol: 0.8 });
    tone({ freq: 110, dur: 0.22, type: 'square', vol: 0.4 });
  },
  complete() {
    tone({ freq: 880, dur: 0.18, type: 'triangle', vol: 0.7 });
    tone({ freq: 1320, dur: 0.22, type: 'triangle', vol: 0.6, delay: 0.08 });
  },
  hint() {
    tone({ freq: 880, dur: 0.3, type: 'sine', vol: 0.5, slideTo: 1760 });
    tone({ freq: 1320, dur: 0.3, type: 'sine', vol: 0.35, slideTo: 2640, delay: 0.06 });
  },
  win() {
    [523, 659, 784, 1046].forEach((f, i) => tone({ freq: f, dur: 0.22, type: 'triangle', vol: 0.8, delay: i * 0.1 }));
    tone({ freq: 1568, dur: 0.6, type: 'sine', vol: 0.4, delay: 0.45 });
  },
  gameOver() {
    tone({ freq: 440, slideTo: 110, dur: 0.55, type: 'sawtooth', vol: 0.8 });
    tone({ freq: 220, slideTo: 55, dur: 0.55, type: 'square', vol: 0.5 });
  },
  achievement() {
    [784, 988, 1175, 1568].forEach((f, i) => tone({ freq: f, dur: 0.16, type: 'sine', vol: 0.55, delay: i * 0.07 }));
  },
  unlock() {
    tone({ freq: 440, slideTo: 1320, dur: 0.45, type: 'triangle', vol: 0.6 });
  },
};

// ---------------------------------------------------------
// Music: pad drones + looping melody, cross-fading between tracks.
// ---------------------------------------------------------
export const music = {
  trackIdx: -1,
  padGain: null,
  loopTimer: null,
  trackName: '',

  _scheduleLoop(def, ctx, tStart) {
    if (!this.padGain) return;
    const masterVol = 0.12;
    for (const [freq, ms, dur, relVol, type] of def.melody) {
      const t0 = tStart + ms / 1000;
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.type = type;
      o.frequency.value = freq;
      g.gain.setValueAtTime(0.0001, t0);
      g.gain.exponentialRampToValueAtTime(relVol * masterVol, t0 + 0.025);
      g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur / 1000);
      o.connect(g).connect(this.padGain);
      o.start(t0);
      o.stop(t0 + dur / 1000 + 0.06);
    }
    const loopSec = def.loopMs / 1000;
    const msToReschedule = (tStart + loopSec - ctx.currentTime) * 1000 - 200;
    this.loopTimer = setTimeout(() => {
      if (!this.padGain) return;
      // If the context was suspended (app in background), restart the loop from "now".
      const next = Math.max(tStart + loopSec, ctx.currentTime + 0.05);
      this._scheduleLoop(def, ctx, next);
    }, Math.max(50, msToReschedule));
  },

  _stopActive(fadeDur = 2.0) {
    if (this.loopTimer) { clearTimeout(this.loopTimer); this.loopTimer = null; }
    const ctx = audio.ctx;
    if (!ctx || !this.padGain) { this.padGain = null; return; }
    const pg = this.padGain;
    const oscs = pg._oscs || [];
    this.padGain = null;
    const now = ctx.currentTime;
    pg.gain.cancelScheduledValues(now);
    pg.gain.setValueAtTime(Math.max(0.0001, pg.gain.value), now);
    pg.gain.exponentialRampToValueAtTime(0.0001, now + fadeDur);
    setTimeout(() => {
      for (const o of oscs) { try { o.stop(); } catch { /* already stopped */ } }
      try { pg.disconnect(); } catch { /* ignore */ }
    }, (fadeDur + 0.3) * 1000);
  },

  _startTrack(def, fadeInDur = 3.0) {
    const ctx = ensureCtx();
    if (!ctx) return;
    const padGain = ctx.createGain();
    padGain.gain.value = 0.0001;
    padGain.gain.exponentialRampToValueAtTime(0.14, ctx.currentTime + fadeInDur);
    padGain.connect(audio.musicBus);
    this.padGain = padGain;

    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = 900;
    filter.Q.value = 4;
    const lfo = ctx.createOscillator();
    const lfoGain = ctx.createGain();
    lfo.type = 'sine';
    lfo.frequency.value = 0.05;
    lfoGain.gain.value = 320;
    lfo.connect(lfoGain).connect(filter.frequency);
    lfo.start();
    filter.connect(padGain);

    const oscs = [lfo];
    for (const f of def.padFreqs) {
      for (const detune of [-9, 9]) {
        const o = ctx.createOscillator();
        o.type = 'sine';
        o.frequency.value = f;
        o.detune.value = detune;
        o.connect(filter);
        o.start();
        oscs.push(o);
      }
    }
    padGain._oscs = oscs;
    this.trackName = def.name;
    this._scheduleLoop(def, ctx, ctx.currentTime + 0.8);
  },

  /** Start, or cross-fade to a different random track. */
  start() {
    if (!audio.musicOn || !audio.unlocked) return;
    const ctx = ensureCtx();
    if (!ctx) return;
    let idx;
    do { idx = Math.floor(Math.random() * TRACKS.length); } while (idx === this.trackIdx && TRACKS.length > 1);
    this.trackIdx = idx;
    if (this.padGain) {
      this._stopActive(2.2);
      setTimeout(() => { if (audio.musicOn) this._startTrack(TRACKS[idx], 2.5); }, 300);
    } else {
      this._startTrack(TRACKS[idx], 3.0);
    }
  },

  /** Cross-fade only if music is already playing (e.g. on new puzzle). */
  next() { if (this.padGain) this.start(); },

  stop() { this._stopActive(2.0); },
};
