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

const VERSION = '1.0.0';

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
  setLoading(45, 'Building the monkey...');
  const monkey = new Monkey({ outlines: true });
  stage.scene.add(monkey.root);
  const audio = new AudioEngine();
  const app = { version: VERSION, stage, monkey, audio, THREE };
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
  new Input({
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
  // Payments (apps only; test mode with ?billing=test or #store-test)
  app.billing.init({
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
  const loop = () => {
    const now = audio.now();
    const dt = Math.min(0.05, Math.max(0, now - last));
    last = now;
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
    }
    monkey.update(now, dt, beat);
    stage.update(now, dt, beat, monkey);
    // Auto graphics: if most frames in a 3-second window are slow, step down High -> Medium -> Low
    const wall = performance.now();
    const raw = (wall - probe.wall) / 1000;
    probe.wall = wall;
    if (Save.settings.quality === 'auto' && !probe.done && !document.hidden && raw < 1) {
      if (probe.skip > 0) probe.skip -= raw; // let shaders compile first
      else {
        probe.t += raw;
        probe.n++;
        if (raw > 1 / 38) probe.slow++;
        if (probe.t >= 3) {
          if (probe.slow > probe.n * 0.5 && app.autoLevel !== 'low') {
            app.autoLevel = app.autoLevel === 'high' ? 'medium' : 'low';
            app.setLevel(app.autoLevel);
            if (app.autoLevel === 'low') ui.toast('Graphics set to Low for smoother play. Change it in Settings.');
            probe.skip = 0.5;
          } else probe.done = true;
          probe.t = 0; probe.n = 0; probe.slow = 0;
        }
      }
    }
    requestAnimationFrame(loop);
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
    navigator.serviceWorker.register('sw.js').catch(() => { /* offline install not available here */ });
  }

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
