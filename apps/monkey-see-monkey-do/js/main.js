// Boot: load the save, build the 3D stage and the monkey, wire input and UI,
// then run one animation loop for everything.
import * as THREE from './vendor/three.module.min.js';
import { Save } from './save.js';
import { AudioEngine } from './audio.js';
import { Monkey } from './monkey.js';
import { Stage, QUALITY } from './stage.js';
import { UI } from './ui.js';
import { Game } from './game.js';
import { Input } from './input.js';
import { setupPlatform } from './native.js';
import { Billing } from './billing.js';
import { purchaseDone } from './storeui.js';
import { installSafetyNet, recordError } from './safety.js';
import { setupCrashReports, Crash } from './crash.js';
import { Gamepads } from './gamepad.js';
import { nativeCall, nativeHas } from './native.js';

const VERSION = '1.1.0';
// PC edition (desktop stores): no real-money Shop; everything is earned by playing.
const EDITION = (typeof window !== 'undefined' && (window.MSMD_EDITION === 'pc' || /[?&]edition=pc\b/.test(location.search))) ? 'pc' : 'standard';
if (EDITION === 'pc') document.documentElement.classList.add('edition-pc');

function setLoading(pct, text) {
  const f = document.getElementById('loading-fill');
  if (f) f.style.width = pct + '%';
  if (text) {
    const t = document.getElementById('loading-text');
    if (t) t.textContent = text;
  }
}

function fail(msg) {
  setLoading(100, msg);
  const t = document.getElementById('loading-text');
  if (t) t.style.color = '#ffb3b3';
}

async function boot() {
  installSafetyNet(VERSION);
  setLoading(20, 'Loading your save...');
  Save.load();
  const s = Save.settings;
  const canvas = document.getElementById('scene');
  let stage;
  try {
    const forceWebGL1 = /[?&]gl=1\b/.test(location.search);
    stage = new Stage(canvas, { quality: s.quality, forceWebGL1 });
  } catch (e) {
    fail("This browser can't show 3D graphics (WebGL is off or not supported). Try Chrome, Safari or Firefox, or turn on hardware acceleration.");
    return;
  }
  // The GPU can reset (a phone waking up, a driver update): pause, say so, and
  // carry on when it comes back instead of showing a frozen picture.
  canvas.addEventListener('webglcontextlost', (e) => {
    e.preventDefault();
    if (app.game) app.game.pause();
    if (app.ui) app.ui.gpuLost(true);
    recordError(new Error('WebGL context lost'), 'gpu');
  });
  canvas.addEventListener('webglcontextrestored', () => {
    if (app.ui) app.ui.gpuLost(false);
  });
  setLoading(45, 'Building the monkey...');
  const monkey = new Monkey({ outlines: true });
  stage.scene.add(monkey.root);
  const audio = new AudioEngine();
  const app = { version: VERSION, edition: EDITION, stage, monkey, audio, THREE };
  const ui = new UI(app);
  app.ui = ui;
  const game = new Game({ audio, monkey, stage, ui });
  app.game = game;
  app.settings = () => Save.settings;
  setupPlatform(app);
  game.onHaptic = app.haptic;
  game.onAwake = app.keepAwake;
  app.billing = new Billing();

  let lastQuality = null;
  app.applySettings = () => {
    const st = Save.settings;
    audio.setVolumes(st.music, st.sfx);
    audio.voiceOn = st.voice;
    app.applySilentMode(st.silentOk !== false);
    document.body.classList.toggle('reduce-motion', !!st.reduceMotion);
    stage.reduceMotion = !!st.reduceMotion || matchMedia('(prefers-reduced-motion: reduce)').matches;
    monkey.danceAmp = st.reduceMotion ? 0.5 : 1;
    if (st.quality !== lastQuality) {
      lastQuality = st.quality;
      app.setLevel(st.quality === 'auto' ? app.autoLevel : st.quality);
    }
    stage.setRenderScale(st.renderScale || 1);
    Crash.apply();
    ui.relabelPad();
  };

  // Graphics level actually in use (Auto starts at High and steps down if frames are slow)
  app.autoLevel = 'high';
  app.setLevel = (level) => {
    stage.setQuality(level);
    monkey.setQuality(stage.level, QUALITY[stage.level]);
  };
  app.applyLook = (look) => {
    monkey.applyLook(look);
    monkey.setQuality(stage.level, QUALITY[stage.level]);
    if (game.mode === 'menu') {
      const env = look.stage && look.stage !== 'auto' ? look.stage : 'jungle';
      stage.setEnvironment(env);
      audio.startMusic(env === 'jungle' ? 'menu' : stage.musicFor(env), 96);
    }
  };

  ui.init();
  const onResize = () => {
    stage.resize();
    ui.reframe();
  };
  window.addEventListener('resize', onResize);
  window.addEventListener('orientationchange', () => setTimeout(onResize, 250));
  const input = new Input({
    pad: document.getElementById('pad'),
    surface: canvas,
    settings: () => Save.settings,
    onMove: (id, t) => game.onInput(id, t),
    onPause: () => (game.paused ? game.resume() : game.pause()),
    pick: (x, y) => monkey.pick(x, y, stage.camera, stage.width, stage.height),
    onLook: (x, y) => {
      const head = monkey.j.head.getWorldPosition(new THREE.Vector3()).project(stage.camera);
      const hx = (head.x * 0.5 + 0.5) * stage.width;
      const hy = (-head.y * 0.5 + 0.5) * stage.height;
      monkey.setLook((x - hx) / (stage.width * 0.4), -(y - hy) / (stage.height * 0.4));
    },
  });
  app.input = input;
  // Game controllers: moves while playing, D-pad / A / B in the menus
  app.gamepads = new Gamepads({
    enabled: () => Save.settings.gamepad !== false,
    fire: (id, ms) => { input.fire(id, ms, 'gamepad'); ui.flashPad(id); },
    isPlaying: () => ui.current === 'hud' && !document.querySelector('.overlay.show') && document.getElementById('mistake').hidden && !game.paused,
    onPause: () => { if (ui.current === 'hud') { if (game.paused) game.resume(); else game.pause(); } },
    onBack: () => ui.handleBack(),
    onActive: (family) => ui.setPadGlyphs(family),
  });
  // Phone apps: maybe show the store's own rating box after a good level
  // (never on the first day, at most 3 times a year, 60+ days apart)
  app.maybeAskRating = (level, stars) => {
    if (!app.native || Save.settings.askRating === false || !nativeHas('InAppReview')) return false;
    const d = Save.data;
    const now = Date.now();
    const day = 864e5;
    const asks = (d.ratingAsks || []).filter((t) => now - t < 365 * day);
    if (!level || level.id < 4 || stars < 2 || asks.length >= 3) return false;
    if (asks.length && now - asks[asks.length - 1] < 60 * day) return false;
    if (now - (d.created || now) < day) return false;
    d.ratingAsks = [...asks, now];
    Save.persist();
    setTimeout(() => nativeCall('InAppReview', 'requestReview'), 1800);
    return true;
  };
  // First tap anywhere unlocks sound (browsers need a gesture). Kept on for
  // later taps too: iPhones pause audio after calls and Siri ("interrupted").
  let unlocked = false;
  const unlock = () => {
    if (!unlocked) app.applySilentMode(Save.settings.silentOk !== false);
    audio.unlock();
    if (!unlocked && audio.ctx) {
      unlocked = true;
      app.applySettings();
    }
  };
  for (const ev of ['pointerdown', 'touchend', 'click', 'keydown']) window.addEventListener(ev, unlock, { capture: true, passive: true });
  // iOS Safari: stop pinch-zoom and double-tap zoom from moving the game around
  document.addEventListener('gesturestart', (e) => e.preventDefault());
  document.addEventListener('dblclick', (e) => e.preventDefault());
  // Phone turned sideways in a browser: pause and show "turn upright" (the apps lock portrait)
  const sideways = matchMedia('(orientation: landscape) and (max-height: 500px) and (pointer: coarse)');
  const onSideways = () => { if (sideways.matches) game.pause(); };
  if (sideways.addEventListener) sideways.addEventListener('change', onSideways);
  else if (sideways.addListener) sideways.addListener(onSideways);

  app.applySettings();
  app.applyLook(Save.data.equipped);
  game.toMenu();
  setLoading(80, 'Tuning the bongos...');

  // Wait briefly for fonts so the logo doesn't jump.
  try {
    await Promise.race([document.fonts && document.fonts.ready, new Promise((r) => setTimeout(r, 1500))]);
  } catch { /* fine */ }
  ui.show('title');
  setLoading(100, 'Ready!');
  // Payments (apps only; test mode with ?billing=test or #store-test). The PC edition has none.
  if (EDITION !== 'pc') app.billing.init({
    onDeliver: (product, tx, price) => {
      const got = Save.deliverPurchase(product, tx, price);
      if (got) purchaseDone(ui, product, got);
    },
    onChange: () => { if (ui.current === 'store') import('./storeui.js').then((m) => m.renderStore(ui)); },
    onError: (msg) => ui.toast(msg, 4000),
  });
  document.getElementById('loading').classList.remove('show');

  // ------------------------------------------------------------ main loop
  let last = audio.now();
  let lastBeat = Math.floor(audio.beatAt(last));
  // Auto graphics probe: 3-second windows of real frame times
  const probe = { t: 0, n: 0, slow: 0, wall: performance.now(), done: false, skip: 1 };
  app.gfxProbe = probe; // visible in the console for checking
  // Auto keeps watching while you play: if frames stay slow for 10 seconds
  // (a phone heating up), step down one more level, at most every 30 seconds.
  const watch = { t: 0, n: 0, slowWindows: 0, cooldown: 0 };
  app.gfxWatch = watch;
  let lastDraw = 0;
  const frame = () => {
    const now = audio.now();
    const wall = performance.now();
    const beat = audio.beatAt(now);
    const bi = Math.floor(beat);
    if (bi !== lastBeat) {
      lastBeat = bi;
      stage.onBeat(bi);
      game.onBeat(bi);
    }
    try {
      game.update(now);
    } catch (e) {
      console.error(e);
      recordError(e, 'game');
    }
    app.gamepads.poll(wall);
    // Frame-rate cap (Settings > Display): game timing runs every frame; only drawing is skipped
    const cap = Save.settings.fpsCap || 0;
    if (cap && wall - lastDraw < 1000 / cap - 2) return;
    lastDraw = wall;
    const dt = Math.min(0.05, Math.max(0, now - last));
    last = now;
    monkey.update(now, dt, beat);
    stage.update(now, dt, beat, monkey);
    // Auto graphics: if a 3-second window averages under 38 frames a second (or well under
    // the frame-rate cap), step down High -> Medium -> Low, but only while stepping down helps
    const target = cap ? Math.min(38, cap * 0.8) : 38;
    const raw = (wall - probe.wall) / 1000;
    probe.wall = wall;
    if (Save.settings.quality === 'auto' && !probe.done && !document.hidden && raw < 1) {
      if (probe.skip > 0) probe.skip -= raw; // let shaders compile first
      else {
        probe.t += raw;
        probe.n++;
        if (raw > 1 / 38) probe.slow++;
        if (probe.t >= 3) {
          // average frame rate over the window (frames can arrive in bursts, so count them, don't time each one)
          probe.fps = probe.n / probe.t;
          if (probe.prev && probe.prev.fps >= 20 && probe.fps < probe.prev.fps * 1.05) {
            // a lower level didn't help: the browser is capping the frame rate
            // (battery saver, a 30 Hz screen), not the graphics. Go back up and stay.
            app.autoLevel = probe.prev.level;
            app.setLevel(app.autoLevel);
            probe.capped = true;
            probe.done = true;
          } else if (probe.fps < target && app.autoLevel !== 'low') {
            probe.prev = { level: app.autoLevel, fps: probe.fps };
            app.autoLevel = app.autoLevel === 'high' ? 'medium' : 'low';
            app.setLevel(app.autoLevel);
            probe.skip = 1.2; // let the new level's shaders compile before measuring
          } else {
            probe.done = true;
            if (app.autoLevel === 'low') ui.toast('Graphics set to Low for smoother play. Change it in Settings.');
          }
          probe.t = 0; probe.n = 0; probe.slow = 0;
        }
      }
    } else if (Save.settings.quality === 'auto' && probe.done && !probe.capped && !document.hidden && raw < 1
      && game.mode !== 'menu' && !game.paused && app.autoLevel !== 'low') {
      if (watch.cooldown > 0) watch.cooldown -= raw;
      else {
        watch.t += raw;
        watch.n++;
        if (watch.t >= 5) {
          watch.fps = watch.n / watch.t;
          watch.slowWindows = watch.fps < (cap ? cap * 0.75 : 24) ? watch.slowWindows + 1 : 0;
          if (watch.slowWindows >= 2) {
            app.autoLevel = app.autoLevel === 'high' || app.autoLevel === 'ultra' ? 'medium' : 'low';
            app.setLevel(app.autoLevel);
            ui.toast(`Graphics lowered to ${app.autoLevel === 'medium' ? 'Medium' : 'Low'} to keep play smooth.`);
            watch.slowWindows = 0;
            watch.cooldown = 30;
          }
          watch.t = 0; watch.n = 0;
        }
      }
    }
  };
  // Schedule the next frame first, so an error in one frame can never stop the game
  const loop = () => {
    requestAnimationFrame(loop);
    try {
      frame();
    } catch (e) {
      console.error(e);
      recordError(e, 'loop');
    }
  };
  requestAnimationFrame(loop);

  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      game.pause();
      audio.suspend();
    } else {
      audio.resume();
    }
  });
  window.addEventListener('pagehide', () => Save.persist());

  // Offline support when served from a web host (not inside a sandboxed preview).
  if (!window.MSMD_NO_SW && !app.native && 'serviceWorker' in navigator && /^https?:$/.test(location.protocol)) {
    const hadController = !!navigator.serviceWorker.controller;
    navigator.serviceWorker.register('sw.js').then((reg) => {
      // a new version finished installing while the game is open: offer a reload
      reg.addEventListener('updatefound', () => {
        const w = reg.installing;
        if (!w) return;
        w.addEventListener('statechange', () => {
          if (w.state === 'activated' && hadController) ui.updateReady();
        });
      });
      // look for a new version every hour while the game stays open
      setInterval(() => { if (navigator.onLine !== false) reg.update().catch(() => {}); }, 60 * 60 * 1000);
    }).catch(() => { /* offline install not available here */ });
  }
  // Crash reports: only in builds with a crash service set up (see crash.js)
  setupCrashReports(app).catch((e) => recordError(e, 'crash-setup'));

  // Handy for tests and for curious players poking around in the console.
  window.MSMD = { version: VERSION, app, game, Save, audio, monkey, stage, ui, webgl: stage.webgl, platform: app.platform };
  document.documentElement.dataset.ready = '1';
}

const hot = window.claude && window.claude.hot;
if (hot && typeof hot.snapshot === 'function') {
  try { hot.snapshot(() => ({ v: VERSION })); } catch { /* not in a viewer */ }
}
if (hot && typeof hot.ready === 'function') hot.ready(() => boot());
else boot();
