/* ============================================================
   Audio — every sound is synthesized with the Web Audio API
   (ported from the original game), so the app ships no audio
   files. Separate gain buses for effects and music.
   The AudioContext is created on the first user gesture,
   because browsers and mobile webviews block audio before that.
   ============================================================ */

import { playStyle, STYLE_BY_ID, TIER_SONG, MENU_SONG } from './music-engine.js';

export { TIER_SONG, MENU_SONG };
/** Music is mastered hot; this sets it under the sound effects at the default volume. */
const MUSIC_TRIM = 2.5;

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

/**
 * iPhone silent switch: by default iOS mutes web audio while the ringer is off.
 * Asking for a "playback" audio session (Safari 17+), and keeping a silent <audio>
 * element playing, lets game sound play like any media app. Browsers only allow
 * play() during a real tap, so a refused attempt is retried on the next one.
 */
let silentEl = null;
let sessionState = 'idle'; // idle -> trying -> playing
export function enablePlaybackSession() {
  try { if (navigator.audioSession && navigator.audioSession.type !== 'playback') navigator.audioSession.type = 'playback'; } catch { /* ignore */ }
  if (sessionState !== 'idle') return;
  try {
    if (!silentEl) {
      const rate = 8000;
      const samples = rate / 2;
      const buf = new ArrayBuffer(44 + samples);
      const v = new DataView(buf);
      const w = (o, str) => { for (let i = 0; i < str.length; i++) v.setUint8(o + i, str.charCodeAt(i)); };
      w(0, 'RIFF'); v.setUint32(4, 36 + samples, true); w(8, 'WAVEfmt '); v.setUint32(16, 16, true);
      v.setUint16(20, 1, true); v.setUint16(22, 1, true); v.setUint32(24, rate, true); v.setUint32(28, rate, true);
      v.setUint16(32, 1, true); v.setUint16(34, 8, true); w(36, 'data'); v.setUint32(40, samples, true);
      for (let i = 0; i < samples; i++) v.setUint8(44 + i, 128);
      silentEl = document.createElement('audio');
      silentEl.src = URL.createObjectURL(new Blob([buf], { type: 'audio/wav' }));
      silentEl.loop = true;
      silentEl.setAttribute('playsinline', '');
      silentEl.setAttribute('aria-hidden', 'true');
      silentEl.volume = 0.01;
    }
    sessionState = 'trying';
    const p = silentEl.play();
    if (p && p.then) p.then(() => { sessionState = 'playing'; }, () => { sessionState = 'idle'; });
    else sessionState = 'playing';
  } catch { sessionState = 'idle'; }
}

/**
 * Call from every tap and key press (main.js listens on pointerdown, pointerup,
 * touchend, click and keydown). On phones only the finger lifting counts as a tap
 * that may start sound, so pointerdown alone is not enough. Safe to call repeatedly.
 */
export function unlockAudio() {
  enablePlaybackSession();
  const ctx = ensureCtx();
  if (!ctx) return;
  if ((ctx.state === 'suspended' || ctx.state === 'interrupted') && !audio.suspendedByApp) {
    ctx.resume().catch(() => {});
    // Older iOS also needs a sound started inside the tap itself.
    try {
      const src = ctx.createBufferSource();
      src.buffer = ctx.createBuffer(1, 1, 22050);
      src.connect(ctx.destination);
      src.start(0);
    } catch { /* ignore */ }
  }
  audio.unlocked = true;
  if (audio.musicOn) music.start(); // no-op when the right song is already playing
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
  /** Alien Duel: the rival placed a glyph (quiet, lower than your own), fumbled, or won. */
  rivalPlace() { tone({ freq: 330, slideTo: 392, dur: 0.09, type: 'triangle', vol: 0.3 }); },
  rivalFumble() { tone({ freq: 196, slideTo: 130, dur: 0.14, type: 'square', vol: 0.18 }); },
  duelLost() {
    [392, 330, 262, 196].forEach((f, i) => tone({ freq: f, dur: 0.24, type: 'triangle', vol: 0.7, delay: i * 0.13 }));
    tone({ freq: 98, dur: 0.7, type: 'sawtooth', vol: 0.35, delay: 0.5 });
  },
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
let wantSong = MENU_SONG;
let player = null;
let playingId = null;
let trim = null;

/**
 * Theme music. Screens ask for a song with music.play(id); the player cross-fades
 * when the song changes and does nothing when it is already playing.
 */
export const music = {
  get current() { return playingId; },
  get wanted() { return wantSong; },
  songName: (id) => STYLE_BY_ID[id]?.name || '',
  play(id) {
    if (STYLE_BY_ID[id]) wantSong = id;
    this.start();
  },
  /** Start (or cross-fade to) the wanted song, once audio is allowed. */
  start() {
    if (!audio.musicOn || !audio.unlocked || audio.suspendedByApp) return;
    const ctx = ensureCtx();
    if (!ctx) return;
    if (player && playingId === wantSong) return;
    if (!trim) { trim = ctx.createGain(); trim.gain.value = MUSIC_TRIM; trim.connect(audio.musicBus); }
    if (player) player.stop(1.6);
    player = playStyle(ctx, trim, wantSong, { fadeIn: player ? 2 : 2.5 });
    playingId = wantSong;
    emitMusic();
  },
  /** Kept for older callers: a new puzzle keeps its tier's song. */
  next() {},
  stop() {
    if (player) player.stop(1.5);
    player = null;
    playingId = null;
    emitMusic();
  },
};
const musicListeners = new Set();
/** Called with the playing song id (or null) whenever it changes. Returns an unsubscribe. */
export function onMusicChange(fn) { musicListeners.add(fn); return () => musicListeners.delete(fn); }
function emitMusic() { for (const fn of musicListeners) { try { fn(playingId); } catch { /* ignore */ } } }

/** A short chime that plays even when sound effects are switched off (Settings, Test sound). */
export function testSound() {
  unlockAudio();
  const was = audio.sfxOn;
  audio.sfxOn = true;
  sfx.achievement();
  audio.sfxOn = was;
}

/** For the settings screen: is sound actually able to play right now? */
export function audioStatus() {
  if (!audio.ctx) return audio.unlocked ? 'starting' : 'waiting for a tap';
  return audio.ctx.state;
}

// ---------------------------------------------------------
// The visitors: sounds for the alien encounter.
// ---------------------------------------------------------

/** Lower the music while the visitors are here (true), then restore it. */
export function duckMusic(on) {
  if (!audio.musicBus || !audio.ctx) return;
  const target = on ? audio.musicVolume * 0.18 : audio.musicVolume;
  audio.musicBus.gain.setTargetAtTime(target, audio.ctx.currentTime, on ? 0.4 : 1.2);
}

export const encounterSfx = {
  /** A deep, slowly swelling hum as the ship approaches. Returns stop(). */
  hum(riseSeconds = 3.5) {
    if (!audio.sfxOn || !audio.unlocked) return () => {};
    const ctx = ensureCtx();
    if (!ctx || ctx.state !== 'running') return () => {};
    const out = ctx.createGain();
    out.gain.setValueAtTime(0.0001, ctx.currentTime);
    out.gain.exponentialRampToValueAtTime(0.5, ctx.currentTime + riseSeconds);
    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(180, ctx.currentTime);
    filter.frequency.exponentialRampToValueAtTime(900, ctx.currentTime + riseSeconds);
    filter.connect(out).connect(audio.sfxBus);
    const oscs = [];
    for (const [f, type, det] of [[55, 'sawtooth', -6], [55, 'sawtooth', 7], [110, 'sine', 0], [82.4, 'triangle', 3]]) {
      const o = ctx.createOscillator();
      o.type = type;
      o.frequency.value = f;
      o.detune.value = det;
      o.connect(filter);
      o.start();
      oscs.push(o);
    }
    // slow wobble, like the ship breathing
    const lfo = ctx.createOscillator();
    const lfoGain = ctx.createGain();
    lfo.frequency.value = 0.6;
    lfoGain.gain.value = 140;
    lfo.connect(lfoGain).connect(filter.frequency);
    lfo.start();
    oscs.push(lfo);
    return (fade = 1.5) => {
      const now = ctx.currentTime;
      out.gain.cancelScheduledValues(now);
      out.gain.setValueAtTime(Math.max(0.0001, out.gain.value), now);
      out.gain.exponentialRampToValueAtTime(0.0001, now + fade);
      setTimeout(() => { oscs.forEach((o) => { try { o.stop(); } catch { /* ignore */ } }); try { out.disconnect(); } catch { /* ignore */ } }, (fade + 0.2) * 1000);
    };
  },
  /** The shimmer of a voice inside your head. */
  telepathy() {
    [1046.5, 1318.5, 1568, 2093].forEach((f, i) => {
      tone({ freq: f, dur: 1.4, type: 'sine', vol: 0.22, delay: i * 0.09, slideTo: f * 1.01 });
    });
    tone({ freq: 523.25, dur: 1.8, type: 'triangle', vol: 0.25, slideTo: 530 });
  },
  /** One soft tick per telepathic letter. */
  letter() { tone({ freq: 1760 + Math.random() * 600, dur: 0.05, type: 'sine', vol: 0.06 }); },
  /** The ship leaves: a rising whoosh. */
  depart() {
    tone({ freq: 120, slideTo: 1400, dur: 1.2, type: 'sawtooth', vol: 0.25 });
    tone({ freq: 240, slideTo: 2600, dur: 1.0, type: 'sine', vol: 0.2, delay: 0.1 });
  },
  /** The visitors' gift. */
  gift() {
    [659, 880, 1175, 1568, 2093].forEach((f, i) => tone({ freq: f, dur: 0.35, type: 'triangle', vol: 0.45, delay: i * 0.08 }));
  },
};
