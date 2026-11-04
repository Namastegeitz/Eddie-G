// Sound: a beat clock, a small drum machine + bass + chords for each stage,
// one musical note per move (like the old colour-and-tone memory games),
// and the sound effects. All synthesised with Web Audio; no audio files.
//
// Clock: the game runs on performance.now() seconds ("game time"). Sounds
// are scheduled slightly ahead and shifted by the output latency so you hear
// a beat at the same moment the floor flashes for it.
import { MOVES } from './moves.js';

const midi = (n) => 440 * Math.pow(2, (n - 69) / 12);

// 16 sixteenth-notes per bar.  x = hit, o = accent/open, . = rest
// bass: semitones above the bar's root, '-' rest.  prog: 4 bars of [root, chord tones]
const PROG_POP = [
  [48, [60, 64, 67]], // C
  [45, [57, 60, 64]], // Am
  [41, [57, 60, 65]], // F
  [43, [55, 59, 62]], // G
];
const PROG_DISCO = [
  [45, [57, 60, 64]], // Am
  [50, [57, 62, 65]], // Dm
  [43, [55, 59, 62]], // G
  [48, [55, 60, 64]], // C
];

const STYLES = {
  menu: { kick: 'x.......x.......', snare: '....x.......x...', hat: '..x...x...x...x.', perc: 'x..x..x.....x...', bass: [0, '-', '-', '-', '-', '-', 7, '-', 0, '-', '-', '-', 12, '-', 7, '-'], stab: '', prog: PROG_POP, voice: 'marimba', swing: 0.12, hatGain: 0.18 },
  jungle: { kick: 'x.....x...x.....', snare: '....x.......x...', hat: 'x.xxx.xxx.xxx.xx', perc: 'x..x..x...x.x..x', bass: [0, '-', '-', 0, '-', '-', 7, '-', 0, '-', 10, '-', 12, '-', 7, '-'], stab: '......x.......x.', prog: PROG_POP, voice: 'marimba', swing: 0.14, hatGain: 0.12 },
  beach: { kick: 'x.......x.......', snare: '........x.......', hat: '..o...o...o...o.', perc: '...x.......x..x.', bass: [0, '-', '-', 7, '-', '-', 12, '-', '-', '-', 7, '-', 5, '-', 4, '-'], stab: '..x...x...x...x.', prog: PROG_POP, voice: 'steel', swing: 0.08, hatGain: 0.14 },
  disco: { kick: 'x...x...x...x...', snare: '....x.......x...', hat: '..o...o...o...o.', perc: 'x.x.x.x.x.x.x.x.', bass: [0, 12, 0, 12, 0, 12, 0, 12, 0, 12, 0, 12, 0, 12, 7, 12], stab: 'x.....x.....x...', prog: PROG_DISCO, voice: 'pluck', swing: 0, hatGain: 0.16 },
  moon: { kick: 'x.........x.....', snare: '........x.......', hat: '....x.......x...', perc: '', bass: [0, '-', '-', '-', '-', '-', '-', '-', 7, '-', '-', '-', '-', '-', 5, '-'], stab: 'x.......x.......', prog: PROG_POP, voice: 'bell', swing: 0, hatGain: 0.1, arp: true },
};

export class AudioEngine {
  constructor() {
    this.ctx = null;
    this.musicVol = 0.6;
    this.sfxVol = 0.9;
    this.voiceOn = false;
    this.style = 'menu';
    this.pendingStyle = null;
    this.playing = false;
    this.bpm = 90;
    this.tAnchor = this.now();
    this.beatAnchor = 0;
    this.nextSixteenth = 0;
    this.offset = null;
    this.timer = null;
    this.noise = null;
  }

  now() {
    return performance.now() / 1000;
  }

  /** Must be called from a tap/click (browsers only allow sound after one). */
  unlock() {
    try {
      if (!this.ctx) {
        const AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return false;
        this.ctx = new AC({ latencyHint: 'interactive' });
        const c = this.ctx;
        this.master = c.createDynamicsCompressor();
        this.master.threshold.value = -14;
        this.master.ratio.value = 4;
        this.master.connect(c.destination);
        this.musicBus = c.createGain();
        this.sfxBus = c.createGain();
        this.musicBus.connect(this.master);
        this.sfxBus.connect(this.master);
        // A short echo for the moon stage and some effects
        this.delay = c.createDelay(1);
        this.delay.delayTime.value = 0.28;
        this.delayFb = c.createGain();
        this.delayFb.gain.value = 0.32;
        this.delay.connect(this.delayFb);
        this.delayFb.connect(this.delay);
        this.delayOut = c.createGain();
        this.delayOut.gain.value = 0.5;
        this.delay.connect(this.delayOut);
        this.delayOut.connect(this.musicBus);
        const len = c.sampleRate;
        this.noise = c.createBuffer(1, len, c.sampleRate);
        const d = this.noise.getChannelData(0);
        for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
        this.setVolumes(this.musicVol, this.sfxVol);
      }
      if (this.ctx.state !== 'running') {
        // 'suspended' before the first tap, 'interrupted' after a call or Siri on iPhone
        const p = this.ctx.resume();
        if (p && p.catch) p.catch(() => {});
      }
      if (!this.primed) {
        // Older iPhones only start Web Audio once a sound plays inside the tap itself
        const b = this.ctx.createBuffer(1, 1, 22050);
        const src = this.ctx.createBufferSource();
        src.buffer = b;
        src.connect(this.ctx.destination);
        src.start(0);
        this.primed = true;
      }
      return true;
    } catch {
      return false;
    }
  }

  get ready() {
    return !!this.ctx && this.ctx.state === 'running';
  }

  setVolumes(music, sfx) {
    this.musicVol = music;
    this.sfxVol = sfx;
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    this.musicBus.gain.setTargetAtTime(music * 0.55, t, 0.05);
    this.sfxBus.gain.setTargetAtTime(sfx * 0.9, t, 0.05);
  }

  suspend() {
    if (this.ctx && this.ctx.state === 'running') this.ctx.suspend();
  }

  resume() {
    if (this.ctx && this.ctx.state !== 'running') this.ctx.resume();
  }

  // ------------------------------------------------------------ beat clock

  beatAt(t = this.now()) {
    return this.beatAnchor + ((t - this.tAnchor) * this.bpm) / 60;
  }

  timeOfBeat(b) {
    return this.tAnchor + ((b - this.beatAnchor) * 60) / this.bpm;
  }

  get beatDur() {
    return 60 / this.bpm;
  }

  /** Time of the first whole beat at or after `t` (plus `skip` extra beats). */
  nextBeatTime(t = this.now(), skip = 0) {
    return this.timeOfBeat(Math.ceil(this.beatAt(t) - 1e-3) + skip);
  }

  /** Seconds from the nearest beat (negative = early). */
  beatOffset(t) {
    const b = this.beatAt(t);
    return ((b - Math.round(b)) * 60) / this.bpm;
  }

  setTempo(bpm) {
    const now = this.now();
    this.beatAnchor = this.beatAt(now);
    this.tAnchor = now;
    this.bpm = bpm;
  }

  /** Start (or keep) the groove. The clock always runs, even with music muted. */
  startMusic(style, bpm) {
    if (!STYLES[style]) style = 'jungle';
    if (this.playing && style === this.style) {
      if (bpm && bpm !== this.bpm) this.setTempo(bpm);
      return;
    }
    if (this.playing) {
      this.pendingStyle = style;
      if (bpm && bpm !== this.bpm) this.setTempo(bpm);
      return;
    }
    this.style = style;
    this.bpm = bpm || this.bpm;
    this.tAnchor = this.now() + 0.08;
    this.beatAnchor = 0;
    this.nextSixteenth = 0;
    this.playing = true;
    if (!this.timer) this.timer = setInterval(() => this.schedule(), 25);
  }

  stopMusic() {
    this.playing = false;
  }

  /** game time -> AudioContext time, including output latency. */
  toCtx(t) {
    const c = this.ctx;
    let off;
    const ts = c.getOutputTimestamp ? c.getOutputTimestamp() : null;
    if (ts && ts.performanceTime > 0 && ts.contextTime > 0) off = ts.performanceTime / 1000 - ts.contextTime;
    else off = this.now() - c.currentTime + (c.outputLatency || c.baseLatency || 0);
    // smooth jitter, but follow real jumps (tab sleep, device change)
    if (this.offset === null || Math.abs(off - this.offset) > 0.08) this.offset = off;
    else this.offset += (off - this.offset) * 0.05;
    return t - this.offset;
  }

  schedule() {
    if (!this.playing) return;
    const ahead = this.now() + 0.16;
    const sixteenth = 15 / this.bpm;
    let guard = 0;
    while (guard++ < 32) {
      const b = this.nextSixteenth / 4;
      const t = this.timeOfBeat(b);
      if (t > ahead) break;
      const idx = this.nextSixteenth % 16;
      if (idx === 0 && this.pendingStyle) {
        this.style = this.pendingStyle;
        this.pendingStyle = null;
      }
      if (this.ready && this.musicVol > 0.001 && t > this.now() - 0.05) {
        const st = STYLES[this.style];
        const swing = idx % 2 === 1 ? (st.swing || 0) * sixteenth : 0;
        this.playSixteenth(st, idx, Math.floor(this.nextSixteenth / 16), this.toCtx(t + swing), sixteenth);
      }
      this.nextSixteenth++;
    }
    // If we fell far behind (tab was hidden), jump ahead instead of catching up
    const cur = Math.floor(this.beatAt() * 4);
    if (this.nextSixteenth < cur - 8) this.nextSixteenth = cur;
  }

  playSixteenth(st, i, bar, t, six) {
    const c = this.ctx;
    if (t < c.currentTime) t = c.currentTime;
    const [root, chord] = st.prog[bar % st.prog.length];
    const at = (p) => p && p[i] && p[i] !== '.';
    if (at(st.kick)) this.kick(t, 0.9);
    if (at(st.snare)) (this.style === 'disco' || this.style === 'beach' ? this.clap(t) : this.snare(t));
    if (at(st.hat)) this.hat(t, st.hat[i] === 'o', st.hatGain);
    if (at(st.perc)) this.bongo(t, i % 4 === 0 ? 0 : 1);
    const bn = st.bass[i];
    if (bn !== '-' && bn !== undefined) this.bass(t, root + bn, six * (this.style === 'disco' ? 0.9 : 1.8));
    if (at(st.stab)) this.stab(t, chord, six * (this.style === 'beach' ? 0.9 : 2.5));
    if (st.arp && i % 2 === 0) this.tone(t, midi(chord[(i / 2) % 3] + 12), 'bell', 0.12, this.musicBus, true);
  }

  // ------------------------------------------------------------ voices

  env(g, t, peak, attack, decay) {
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, t + attack + decay);
  }

  osc(type, f, t, dur, dest) {
    const o = this.ctx.createOscillator();
    o.type = type;
    o.frequency.setValueAtTime(f, t);
    o.connect(dest);
    o.start(t);
    o.stop(t + dur + 0.05);
    return o;
  }

  noiseSrc(t, dur, dest) {
    const s = this.ctx.createBufferSource();
    s.buffer = this.noise;
    s.connect(dest);
    s.start(t, Math.random() * 0.5);
    s.stop(t + dur + 0.05);
    return s;
  }

  kick(t, v) {
    const c = this.ctx;
    const g = c.createGain();
    g.connect(this.musicBus);
    this.env(g, t, v, 0.003, 0.28);
    const o = this.osc('sine', 150, t, 0.3, g);
    o.frequency.exponentialRampToValueAtTime(44, t + 0.12);
  }

  snare(t) {
    const c = this.ctx;
    const f = c.createBiquadFilter();
    f.type = 'bandpass';
    f.frequency.value = 1900;
    f.Q.value = 0.8;
    const g = c.createGain();
    f.connect(g);
    g.connect(this.musicBus);
    this.env(g, t, 0.42, 0.002, 0.16);
    this.noiseSrc(t, 0.2, f);
    const g2 = c.createGain();
    g2.connect(this.musicBus);
    this.env(g2, t, 0.25, 0.002, 0.08);
    this.osc('triangle', 190, t, 0.1, g2);
  }

  clap(t) {
    const c = this.ctx;
    const f = c.createBiquadFilter();
    f.type = 'bandpass';
    f.frequency.value = 1300;
    f.Q.value = 1.2;
    f.connect(this.musicBus);
    for (let k = 0; k < 3; k++) {
      const g = c.createGain();
      g.connect(f);
      this.env(g, t + k * 0.012, 0.5, 0.001, k === 2 ? 0.14 : 0.02);
      this.noiseSrc(t + k * 0.012, 0.16, g);
    }
  }

  hat(t, open, gain = 0.15) {
    const c = this.ctx;
    const f = c.createBiquadFilter();
    f.type = 'highpass';
    f.frequency.value = 7200;
    const g = c.createGain();
    f.connect(g);
    g.connect(this.musicBus);
    this.env(g, t, gain, 0.001, open ? 0.18 : 0.035);
    this.noiseSrc(t, 0.22, f);
  }

  bongo(t, hi) {
    const g = this.ctx.createGain();
    g.connect(this.musicBus);
    this.env(g, t, 0.3, 0.002, 0.16);
    const f0 = hi ? 390 : 270;
    const o = this.osc('sine', f0, t, 0.2, g);
    o.frequency.exponentialRampToValueAtTime(f0 * 0.72, t + 0.08);
  }

  bass(t, note, dur) {
    const c = this.ctx;
    const f = c.createBiquadFilter();
    f.type = 'lowpass';
    f.frequency.setValueAtTime(this.style === 'disco' ? 900 : 520, t);
    f.frequency.exponentialRampToValueAtTime(220, t + dur);
    const g = c.createGain();
    f.connect(g);
    g.connect(this.musicBus);
    this.env(g, t, 0.5, 0.008, dur);
    this.osc(this.style === 'disco' ? 'sawtooth' : 'triangle', midi(note), t, dur + 0.05, f);
  }

  stab(t, notes, dur) {
    const c = this.ctx;
    const f = c.createBiquadFilter();
    f.type = 'lowpass';
    f.frequency.value = this.style === 'disco' ? 2400 : 1500;
    const g = c.createGain();
    f.connect(g);
    g.connect(this.style === 'moon' ? this.delay : this.musicBus);
    this.env(g, t, 0.09, 0.012, dur);
    for (const n of notes) {
      this.osc('sawtooth', midi(n) * 1.003, t, dur + 0.05, f);
      this.osc(this.style === 'beach' ? 'square' : 'sawtooth', midi(n) * 0.997, t, dur + 0.05, f);
    }
  }

  /** Melodic voices used for move notes and jingles. */
  tone(t, f, voice, vol = 0.35, bus = this.sfxBus, echo = false) {
    const c = this.ctx;
    const g = c.createGain();
    g.connect(bus);
    if (echo) g.connect(this.delay);
    if (voice === 'steel') {
      this.env(g, t, vol, 0.004, 0.7);
      this.osc('sine', f, t, 0.8, g);
      const g2 = c.createGain();
      g2.gain.value = 0.35;
      g2.connect(g);
      this.osc('sine', f * 2.01, t, 0.5, g2);
      const g3 = c.createGain();
      g3.gain.value = 0.18;
      g3.connect(g);
      this.osc('sine', f * 3.02, t, 0.3, g3);
    } else if (voice === 'pluck') {
      const fl = c.createBiquadFilter();
      fl.type = 'lowpass';
      fl.frequency.setValueAtTime(f * 8, t);
      fl.frequency.exponentialRampToValueAtTime(f * 1.2, t + 0.25);
      fl.connect(g);
      this.env(g, t, vol * 0.8, 0.003, 0.4);
      this.osc('sawtooth', f, t, 0.45, fl);
      this.osc('square', f * 0.5, t, 0.45, fl);
    } else if (voice === 'bell') {
      this.env(g, t, vol * 0.8, 0.003, 1.1);
      this.osc('sine', f, t, 1.2, g);
      const g2 = c.createGain();
      g2.gain.value = 0.3;
      g2.connect(g);
      this.osc('sine', f * 2.76, t, 0.6, g2);
    } else {
      // marimba: fundamental + a quick bright overtone
      this.env(g, t, vol, 0.003, 0.5);
      this.osc('sine', f, t, 0.55, g);
      const g2 = c.createGain();
      g2.connect(g);
      this.env(g2, t, 0.5, 0.002, 0.07);
      this.osc('sine', f * 4, t, 0.1, g2);
    }
  }

  voiceForStyle() {
    return (STYLES[this.style] || STYLES.jungle).voice;
  }

  /** The note for a move (or a combo: both notes). `when` is game time. */
  playMove(ids, when) {
    if (!this.ready || this.sfxVol < 0.001) return;
    const t = when ? Math.max(this.ctx.currentTime, this.toCtx(when)) : this.ctx.currentTime;
    const list = Array.isArray(ids) ? ids : [ids];
    for (const id of list) {
      const m = MOVES[id];
      if (m) this.tone(t, m.freq, this.voiceForStyle(), list.length > 1 ? 0.28 : 0.38);
    }
  }

  sfx(name, when, arg) {
    if (!this.ready || this.sfxVol < 0.001) return;
    const c = this.ctx;
    const t = when ? Math.max(c.currentTime, this.toCtx(when)) : c.currentTime;
    const bus = this.sfxBus;
    switch (name) {
      case 'tick':
      case 'go': {
        const g = c.createGain();
        g.connect(bus);
        this.env(g, t, 0.3, 0.001, 0.06);
        this.osc('sine', name === 'go' ? 1760 : 1175, t, 0.08, g);
        break;
      }
      case 'pop': {
        const g = c.createGain();
        g.connect(bus);
        this.env(g, t, 0.18, 0.002, 0.07);
        const o = this.osc('sine', 520, t, 0.09, g);
        o.frequency.exponentialRampToValueAtTime(900, t + 0.06);
        break;
      }
      case 'wrong': {
        const f = c.createBiquadFilter();
        f.type = 'lowpass';
        f.Q.value = 8;
        f.frequency.setValueAtTime(300, t);
        f.frequency.linearRampToValueAtTime(1400, t + 0.12);
        f.frequency.linearRampToValueAtTime(300, t + 0.24);
        f.frequency.linearRampToValueAtTime(1200, t + 0.36);
        f.frequency.linearRampToValueAtTime(250, t + 0.6);
        const g = c.createGain();
        f.connect(g);
        g.connect(bus);
        this.env(g, t, 0.35, 0.01, 0.62);
        const o = this.osc('sawtooth', 233, t, 0.65, f);
        o.frequency.linearRampToValueAtTime(175, t + 0.6);
        break;
      }
      case 'fail': {
        const notes = [67, 66, 65, 64];
        notes.forEach((n, k) => {
          const st = t + k * 0.42;
          const dur = k === 3 ? 1.1 : 0.36;
          const f = c.createBiquadFilter();
          f.type = 'lowpass';
          f.frequency.value = 900;
          const g = c.createGain();
          f.connect(g);
          g.connect(bus);
          this.env(g, st, 0.28, 0.03, dur);
          const o = this.osc('sawtooth', midi(n - 12), st, dur + 0.05, f);
          if (k === 3) {
            const lfo = this.osc('sine', 6, st, dur, c.createGain());
            const lg = c.createGain();
            lg.gain.value = 6;
            lfo.disconnect();
            lfo.connect(lg);
            lg.connect(o.frequency);
          }
        });
        break;
      }
      case 'round': {
        [72, 76, 79, 84].forEach((n, k) => this.tone(t + k * 0.075, midi(n), 'marimba', 0.32));
        break;
      }
      case 'level': {
        [[60, 64, 67], [65, 69, 72], [67, 71, 74], [72, 76, 79, 84]].forEach((ch, k) => {
          ch.forEach((n) => this.tone(t + k * 0.16, midi(n), k === 3 ? 'bell' : 'marimba', 0.2));
        });
        const f = c.createBiquadFilter();
        f.type = 'highpass';
        f.frequency.value = 5000;
        const g = c.createGain();
        f.connect(g);
        g.connect(bus);
        this.env(g, t + 0.48, 0.18, 0.01, 1.2);
        this.noiseSrc(t + 0.48, 1.3, f);
        break;
      }
      case 'coin': {
        this.tone(t, midi(88), 'marimba', 0.22);
        this.tone(t + 0.06, midi(95), 'marimba', 0.22);
        break;
      }
      case 'star': {
        const k = arg || 0;
        this.tone(t, midi(79 + k * 4), 'bell', 0.3);
        this.tone(t + 0.05, midi(86 + k * 4), 'bell', 0.18);
        break;
      }
      case 'buy': {
        [84, 88, 91, 96].forEach((n, k) => this.tone(t + k * 0.05, midi(n), 'bell', 0.2));
        break;
      }
      case 'cheer': {
        const f = c.createBiquadFilter();
        f.type = 'bandpass';
        f.Q.value = 0.7;
        f.frequency.setValueAtTime(700, t);
        f.frequency.linearRampToValueAtTime(1800, t + 0.5);
        const g = c.createGain();
        f.connect(g);
        g.connect(bus);
        g.gain.setValueAtTime(0.0001, t);
        g.gain.exponentialRampToValueAtTime(0.22, t + 0.15);
        g.gain.exponentialRampToValueAtTime(0.0001, t + 1.1);
        this.noiseSrc(t, 1.2, f);
        for (let k = 0; k < 3; k++) {
          const gw = c.createGain();
          gw.connect(bus);
          const st = t + 0.1 + k * 0.17 + Math.random() * 0.05;
          this.env(gw, st, 0.07, 0.02, 0.22);
          const o = this.osc('sine', 1500 + Math.random() * 600, st, 0.26, gw);
          o.frequency.exponentialRampToValueAtTime(2600 + Math.random() * 500, st + 0.2);
        }
        break;
      }
      case 'whoosh': {
        const f = c.createBiquadFilter();
        f.type = 'bandpass';
        f.Q.value = 2;
        f.frequency.setValueAtTime(400, t);
        f.frequency.exponentialRampToValueAtTime(2400, t + 0.35);
        const g = c.createGain();
        f.connect(g);
        g.connect(bus);
        this.env(g, t, 0.2, 0.1, 0.3);
        this.noiseSrc(t, 0.45, f);
        break;
      }
      case 'stomp': {
        const g = c.createGain();
        g.connect(bus);
        this.env(g, t, 0.35, 0.002, 0.15);
        const o = this.osc('sine', 110, t, 0.18, g);
        o.frequency.exponentialRampToValueAtTime(50, t + 0.12);
        break;
      }
      default:
        break;
    }
  }

  // ------------------------------------------------------------ voice callouts

  speak(text) {
    if (!this.voiceOn || !('speechSynthesis' in window)) return;
    try {
      window.speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(text);
      u.rate = 1.35;
      u.pitch = 1.2;
      u.volume = Math.min(1, this.sfxVol + 0.1);
      window.speechSynthesis.speak(u);
    } catch {
      /* no voices on this device */
    }
  }
}
