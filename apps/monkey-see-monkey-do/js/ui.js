// Everything on screen that isn't 3D: menus, the level map, the wardrobe,
// settings, How it works, stats, and the in-game HUD and cards.
import { MOVES, PAD_ORDER, CHORDS, moveIcon, moveName, stepName } from './moves.js';
import { RULES, timeLimit } from './rules.js';
import { WORLDS, LEVELS, TWISTS, ENDLESS, getLevel } from './levels.js';
import { CATEGORIES, ITEMS, itemsIn, getItem } from './shop.js';
import { Save } from './save.js';

export const ICON = {
  banana: '<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M6 9c1 9 7 16 18 15 2 0 3-1 3-2-9 0-14-6-16-14-.4-2-5.4-1-5 1z" fill="#ffd23f" stroke="#23160c" stroke-width="2" stroke-linejoin="round"/><path d="M8.5 11c2 6 6 10 13 11" fill="none" stroke="#d29a00" stroke-width="1.6" stroke-linecap="round"/><path d="M5 9l1-3 3 1" fill="#6b4423" stroke="#23160c" stroke-width="1.6" stroke-linejoin="round"/></svg>',
  heart: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 21s-8-5.2-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.8-8 11-8 11z" fill="#ff5d6c" stroke="#23160c" stroke-width="1.8" stroke-linejoin="round"/><circle cx="8.5" cy="9" r="1.6" fill="#fff" opacity=".7"/></svg>',
  star: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5l2.9 6 6.6.8-4.9 4.6 1.3 6.5L12 17.2l-5.9 3.2 1.3-6.5L2.5 9.3l6.6-.8z" fill="#ffd23f" stroke="#23160c" stroke-width="1.6" stroke-linejoin="round"/></svg>',
  starOff: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5l2.9 6 6.6.8-4.9 4.6 1.3 6.5L12 17.2l-5.9 3.2 1.3-6.5L2.5 9.3l6.6-.8z" fill="rgba(255,255,255,.18)" stroke="rgba(255,255,255,.35)" stroke-width="1.4" stroke-linejoin="round"/></svg>',
  lock: '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="5" y="10" width="14" height="11" rx="3" fill="currentColor"/><path d="M8 10V7a4 4 0 0 1 8 0v3" fill="none" stroke="currentColor" stroke-width="2.4"/></svg>',
  back: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 4l-8 8 8 8" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  pause: '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="6" y="5" width="4.2" height="14" rx="1.6" fill="currentColor"/><rect x="13.8" y="5" width="4.2" height="14" rx="1.6" fill="currentColor"/></svg>',
  gear: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7zm8 4.6v-2.2l-2.4-.5a6 6 0 0 0-.7-1.6l1.4-2-1.6-1.6-2 1.4a6 6 0 0 0-1.6-.7L12.6 3h-2.2l-.5 2.4a6 6 0 0 0-1.6.7l-2-1.4-1.6 1.6 1.4 2a6 6 0 0 0-.7 1.6L3 10.4v2.2l2.4.5a6 6 0 0 0 .7 1.6l-1.4 2 1.6 1.6 2-1.4a6 6 0 0 0 1.6.7l.5 2.4h2.2l.5-2.4a6 6 0 0 0 1.6-.7l2 1.4 1.6-1.6-1.4-2a6 6 0 0 0 .7-1.6z" fill="currentColor"/></svg>',
  info: '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9.5" fill="none" stroke="currentColor" stroke-width="2.4"/><rect x="10.7" y="10" width="2.6" height="7.5" rx="1.3" fill="currentColor"/><circle cx="12" cy="7" r="1.6" fill="currentColor"/></svg>',
  chart: '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="4" y="12" width="4" height="8" rx="1.4" fill="currentColor"/><rect x="10" y="7" width="4" height="13" rx="1.4" fill="currentColor"/><rect x="16" y="3.5" width="4" height="16.5" rx="1.4" fill="currentColor"/></svg>',
  hanger: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 8.5V7.6c1.3-.4 2.2-1.4 2.2-2.7a2.2 2.2 0 1 0-4.4 0" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M12 8.5L2.8 15.6c-.8.6-.4 1.9.6 1.9h17.2c1 0 1.4-1.3.6-1.9z" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"/></svg>',
  check: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  eye: '<svg viewBox="0 0 64 40" aria-hidden="true"><path d="M4 20C12 8 22 3 32 3s20 5 28 17c-8 12-18 17-28 17S12 32 4 20z" fill="#fff8e6" stroke="#23160c" stroke-width="3"/><circle cx="32" cy="20" r="10" fill="#23160c"/><circle cx="35" cy="16" r="3" fill="#fff"/></svg>',
};

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
const starsHtml = (n, max = 3) => Array.from({ length: max }, (_, i) => (i < n ? ICON.star : ICON.starOff)).join('');
const inkMove = (id) => id === 'HD';

function swatch(step, size = '') {
  const ids = Array.isArray(step) ? step : [step];
  const bg = ids.length > 1 ? `linear-gradient(135deg, ${MOVES[ids[0]].color} 50%, ${MOVES[ids[1]].color} 50%)` : MOVES[ids[0]].color;
  const col = ids.length === 1 && inkMove(ids[0]) ? '#23160c' : '#fff';
  return `<span class="swatch ${size}" style="background:${bg};color:${col}">${moveIcon(ids)}</span>`;
}

function chordSteps(id) {
  return CHORDS[id].parts;
}

// Small drawings for wardrobe items
function glyph(item) {
  const c = (s) => `<svg viewBox="0 0 40 40" aria-hidden="true">${s}</svg>`;
  const k = `${item.cat}:${item.id}`;
  if (item.cat === 'fur') return c(`<circle cx="20" cy="20" r="15" fill="${item.rainbow ? 'url(#rb)' : item.fur}" stroke="#23160c" stroke-width="2"/><ellipse cx="20" cy="23" rx="9" ry="8" fill="${item.skin}"/>${item.rainbow ? '<defs><linearGradient id="rb"><stop offset="0" stop-color="#ff5a5a"/><stop offset=".33" stop-color="#ffd23f"/><stop offset=".66" stop-color="#2e8bff"/><stop offset="1" stop-color="#9b5cff"/></linearGradient></defs>' : ''}`);
  const G = {
    'hat:none': '<circle cx="20" cy="20" r="13" fill="none" stroke="#cfe0d4" stroke-width="2.5" stroke-dasharray="4 4"/>',
    'hat:party': '<path d="M20 4L29 33H11z" fill="#ff4f9a" stroke="#23160c" stroke-width="2"/><circle cx="20" cy="5" r="4" fill="#ffd23f"/><path d="M14 22h12" stroke="#ffd23f" stroke-width="3"/>',
    'hat:flower': '<path d="M5 26c5-5 25-5 30 0" fill="none" stroke="#3f9a3a" stroke-width="3"/><circle cx="9" cy="23" r="4.5" fill="#ff6fae"/><circle cx="20" cy="20" r="4.5" fill="#ffd23f"/><circle cx="31" cy="23" r="4.5" fill="#b07cff"/><circle cx="14.5" cy="21" r="3" fill="#fff"/><circle cx="25.5" cy="21" r="3" fill="#ff8a1f"/>',
    'hat:propeller': '<path d="M7 30a13 11 0 0 1 26 0z" fill="#2e8bff" stroke="#23160c" stroke-width="2"/><path d="M20 19V12" stroke="#23160c" stroke-width="2"/><path d="M8 11h24" stroke="#ff4f4f" stroke-width="4" stroke-linecap="round"/>',
    'hat:headphones': '<path d="M8 25a12 12 0 0 1 24 0" fill="none" stroke="#2b2b38" stroke-width="4"/><rect x="4" y="22" width="8" height="12" rx="3" fill="#ff4f9a"/><rect x="28" y="22" width="8" height="12" rx="3" fill="#ff4f9a"/>',
    'hat:tophat': '<rect x="12" y="6" width="16" height="22" rx="2" fill="#1f1f2a" stroke="#cfe0d4" stroke-width="1.5"/><rect x="5" y="27" width="30" height="5" rx="2" fill="#1f1f2a" stroke="#cfe0d4" stroke-width="1.5"/><rect x="12" y="21" width="16" height="4" fill="#d33a3a"/>',
    'hat:crown': '<path d="M6 30V12l7 8 7-12 7 12 7-8v18z" fill="#ffc928" stroke="#23160c" stroke-width="2" stroke-linejoin="round"/><circle cx="20" cy="24" r="3" fill="#ff3b5c"/>',
    'eyes:none': '<circle cx="20" cy="20" r="13" fill="none" stroke="#cfe0d4" stroke-width="2.5" stroke-dasharray="4 4"/>',
    'eyes:round': '<circle cx="12" cy="20" r="7" fill="none" stroke="#e8d3b0" stroke-width="2.6"/><circle cx="28" cy="20" r="7" fill="none" stroke="#e8d3b0" stroke-width="2.6"/><path d="M19 19h2" stroke="#e8d3b0" stroke-width="2.6"/>',
    'eyes:shades': '<rect x="4" y="14" width="14" height="10" rx="4" fill="#111122" stroke="#cfe0d4" stroke-width="1.5"/><rect x="22" y="14" width="14" height="10" rx="4" fill="#111122" stroke="#cfe0d4" stroke-width="1.5"/><path d="M18 17h4" stroke="#cfe0d4" stroke-width="2"/>',
    'eyes:stars': '<path d="M11 11l2.2 4.6 5 .6-3.7 3.4 1 5-4.5-2.5-4.5 2.5 1-5-3.7-3.4 5-.6z" fill="#ff4f9a"/><path d="M29 11l2.2 4.6 5 .6-3.7 3.4 1 5-4.5-2.5-4.5 2.5 1-5-3.7-3.4 5-.6z" fill="#ffc926"/>',
    'neck:none': '<circle cx="20" cy="20" r="13" fill="none" stroke="#cfe0d4" stroke-width="2.5" stroke-dasharray="4 4"/>',
    'neck:bowtie': '<path d="M20 20L6 12v16zM20 20l14-8v16z" fill="#e0303f" stroke="#23160c" stroke-width="2" stroke-linejoin="round"/><circle cx="20" cy="20" r="4" fill="#e0303f" stroke="#23160c" stroke-width="2"/>',
    'neck:scarf': '<path d="M6 14c8 5 20 5 28 0v6c-8 5-20 5-28 0z" fill="#2e8bff"/><rect x="22" y="20" width="7" height="15" rx="2" fill="#2e8bff"/><rect x="22" y="30" width="7" height="3" fill="#ffd23f"/>',
    'neck:lei': '<circle cx="8" cy="16" r="4" fill="#ff4f9a"/><circle cx="12" cy="24" r="4" fill="#ffd23f"/><circle cx="20" cy="28" r="4" fill="#ff8a1f"/><circle cx="28" cy="24" r="4" fill="#fff"/><circle cx="32" cy="16" r="4" fill="#b07cff"/>',
    'neck:chain': '<path d="M6 12c4 12 24 12 28 0" fill="none" stroke="#ffc928" stroke-width="2.6" stroke-dasharray="3 2"/><path d="M15 25c2 7 9 9 13 6-5 0-9-2-11-7z" fill="#ffc928" stroke="#23160c" stroke-width="1.5"/>',
    'flair:wiggle': '<path d="M10 8c10 4-10 8 0 12s-10 8 0 12" fill="none" stroke="#ff4f9a" stroke-width="3.5" stroke-linecap="round"/><path d="M24 12l8 8-8 8" fill="none" stroke="#cfe0d4" stroke-width="3" stroke-linecap="round"/>',
    'flair:shimmy': '<path d="M5 22l5-8 5 8 5-8 5 8 5-8 5 8" fill="none" stroke="#ff4f9a" stroke-width="3.5" stroke-linejoin="round" stroke-linecap="round"/>',
    'flair:spin': '<path d="M30 14a12 12 0 1 0 2 10" fill="none" stroke="#ff4f9a" stroke-width="3.5" stroke-linecap="round"/><path d="M26 8l5 6-7 2" fill="none" stroke="#ff4f9a" stroke-width="3.5" stroke-linejoin="round" stroke-linecap="round"/>',
    'flair:robot': '<rect x="10" y="9" width="20" height="18" rx="3" fill="#9aa6b8" stroke="#23160c" stroke-width="2"/><rect x="14" y="14" width="4" height="4" fill="#4fd8ff"/><rect x="22" y="14" width="4" height="4" fill="#4fd8ff"/><path d="M15 22h10" stroke="#23160c" stroke-width="2"/><path d="M20 9V4" stroke="#23160c" stroke-width="2"/><circle cx="20" cy="4" r="2" fill="#ff4f4f"/>',
    'stage:jungle': '<rect x="2" y="2" width="36" height="36" rx="8" fill="#3f9a6a"/><rect x="18" y="18" width="4" height="16" fill="#6b4423"/><circle cx="20" cy="15" r="9" fill="#2d7a3a"/><circle cx="13" cy="19" r="6" fill="#3f9446"/><circle cx="27" cy="19" r="6" fill="#3f9446"/>',
    'stage:beach': '<rect x="2" y="2" width="36" height="36" rx="8" fill="#ff9f7a"/><circle cx="20" cy="22" r="8" fill="#ffe08a"/><rect x="2" y="24" width="36" height="14" rx="0" fill="#2fa6c9"/><path d="M2 33h36v5H2z" fill="#f1d39a"/>',
    'stage:disco': '<rect x="2" y="2" width="36" height="36" rx="8" fill="#2c0f55"/><circle cx="20" cy="17" r="9" fill="#d8d8f0"/><path d="M11 17h18M20 8v18M13 11l14 12M27 11L13 23" stroke="#9aa" stroke-width="1"/><path d="M6 36l6-10M34 36l-6-10" stroke="#ff4fd8" stroke-width="3"/>',
    'stage:moon': '<rect x="2" y="2" width="36" height="36" rx="8" fill="#0b1236"/><path d="M24 8a10 10 0 1 0 8 15 8 8 0 0 1-8-15z" fill="#f4f0d0"/><circle cx="10" cy="10" r="1.3" fill="#fff"/><circle cx="14" cy="28" r="1" fill="#fff"/><circle cx="33" cy="32" r="1.2" fill="#fff"/>',
  };
  return c(G[k] || '<circle cx="20" cy="20" r="12" fill="#cfe0d4"/>');
}

// Settings shown on the Settings screen. Every row says what it changes.
const SETTINGS = [
  { group: 'Sound', items: [
    { key: 'music', type: 'range', label: 'Music' },
    { key: 'sfx', type: 'range', label: 'Moves and effects' },
    { key: 'voice', type: 'toggle', label: 'Call out moves', help: 'A voice says each move while the monkey dances (uses your device\'s built-in voice).' },
  ] },
  { group: 'Gameplay', items: [
    { key: 'timer', type: 'seg', label: 'Timer', options: [['normal', 'Normal'], ['relaxed', 'Relaxed'], ['off', 'Off']], help: `Relaxed gives you ${RULES.relaxedTimerMult}x the time. Off removes the timer.` },
    { key: 'speed', type: 'seg', label: 'Game speed', options: [[1, '100%'], [0.85, '85%'], [0.7, '70%']], help: 'Slows the music and the monkey. Timers grow to match.' },
    { key: 'assist', type: 'toggle', label: 'Assist mode', help: `Free "Watch again" (normally ${RULES.replayCost} bananas), a glowing hint on the move you missed, and a wider window for combos (${RULES.assistChordWindowMs} ms instead of ${RULES.chordWindowMs} ms).` },
    { key: 'naming', type: 'seg', label: 'Name sides by', options: [['screen', 'Screen'], ['monkey', 'Monkey']], help: 'Screen: "Left Arm" is the arm on the left of your screen, like a mirror. Monkey: names follow the monkey\'s own left and right. The buttons stay where they are.' },
  ] },
  { group: 'Controls', items: [
    { key: 'swipe', type: 'toggle', label: 'Swipe on the stage', help: 'Swipe up for Head, down for Flair, and diagonally for arms (up-left, up-right) and legs (down-left, down-right).' },
    { key: 'tapMonkey', type: 'toggle', label: 'Tap the monkey', help: 'Tap a hand, a foot, the head or the belly.' },
    { key: 'keyHints', type: 'toggle', label: 'Show keyboard letters', help: 'Q W E on the top row, A S D on the bottom row (or 7 8 9 / 4 5 6).' },
    { key: 'haptics', type: 'toggle', label: 'Vibration', help: 'A short buzz on taps and mistakes, on phones that support it.' },
    { type: 'action', label: 'Rhythm calibration', action: 'calibrate', button: 'Calibrate', help: () => `Adjusts timing for your device's sound delay (useful with Bluetooth headphones). Current: ${Save.settings.latencyMs} ms.` },
  ] },
  { group: 'Display', items: [
    { key: 'captions', type: 'toggle', label: 'Move names during Watch', help: 'Shows the name of each move as the monkey does it.' },
    { key: 'reduceMotion', type: 'toggle', label: 'Reduce motion', help: 'No camera shake, less confetti, calmer menus.' },
    { key: 'quality', type: 'seg', label: 'Graphics', options: [['auto', 'Auto'], ['high', 'High'], ['low', 'Low']], help: 'Low drops outlines and resolution. Easier on older phones and batteries.' },
  ] },
];

export class UI {
  constructor(app) {
    this.app = app;
    this.current = null;
    this.prev = 'title';
    this.world = 1;
    this.shopCat = 'fur';
    this.preview = null;
    this.howtoPage = 0;
  }

  get game() { return this.app.game; }
  get audio() { return this.app.audio; }
  get s() { return Save.settings; }

  // ------------------------------------------------------------ setup

  init() {
    const fill = (cls, svg) => $$(cls).forEach((el) => { el.innerHTML = svg; });
    fill('.i-banana', ICON.banana);
    fill('.i-gear', ICON.gear);
    fill('.i-info', ICON.info);
    fill('.i-chart', ICON.chart);
    fill('.i-hanger', ICON.hanger);
    fill('.icon-btn.back', ICON.back);
    fill('.icon-btn.pause', ICON.pause);
    this.buildPad();

    $$('[data-go]').forEach((b) => b.addEventListener('click', () => {
      this.audio.unlock();
      this.click();
      const to = b.dataset.go;
      if (to === 'back') this.show(this.prev || 'title');
      else this.show(to);
    }));
    $('#btn-play').addEventListener('click', () => {
      this.audio.unlock();
      this.click();
      if (!Save.data.tutorialDone && !Save.levelInfo(1).clears) this.showHowto(() => this.game.openLevel(1));
      else this.show('map');
    });
    $('#btn-endless').addEventListener('click', () => { this.audio.unlock(); this.click(); this.game.startEndless(); });
    $('#btn-free').addEventListener('click', () => { this.audio.unlock(); this.click(); this.game.startFree(); });
    $('#btn-pause').addEventListener('click', () => {
      this.click();
      if (this.game.mode === 'free') this.game.pause();
      else this.game.pause();
    });
    $('#btn-replay').addEventListener('click', () => this.game.replay());
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        if ($('#ov-confirm').classList.contains('show')) return this.closeConfirm(false);
        if (this.game.paused) return this.game.resume();
      }
    });
    this.updateBananas();
  }

  click() {
    this.audio.sfx('pop');
  }

  buildPad() {
    const pad = $('#pad');
    pad.innerHTML = PAD_ORDER.map((id) => {
      const m = MOVES[id];
      const ink = inkMove(id);
      return `<button class="pad-btn${ink ? ' ink' : ''}" data-move="${id}" style="--c:${m.color};--fg:${ink ? '#23160c' : '#fff'}" aria-label="${esc(moveName(id, this.s.naming))} (${m.key.toUpperCase()})">${moveIcon(id, { dim: 0.42 })}<span class="pad-label">${esc(moveName(id, this.s.naming))}</span><kbd>${m.key.toUpperCase()}</kbd></button>`;
    }).join('');
    this.applyPadPrefs();
  }

  /** Re-label the pad after the naming setting changes (buttons keep their listeners). */
  relabelPad() {
    for (const btn of $$('#pad [data-move]')) {
      const id = btn.dataset.move;
      btn.querySelector('.pad-label').textContent = moveName(id, this.s.naming);
      btn.setAttribute('aria-label', `${moveName(id, this.s.naming)} (${MOVES[id].key.toUpperCase()})`);
    }
    this.applyPadPrefs();
  }

  applyPadPrefs() {
    $('#pad').classList.toggle('nokeys', !this.s.keyHints);
  }

  // ------------------------------------------------------------ screens

  show(name) {
    if (this.current === 'shop' && name !== 'shop') this.endPreview();
    if (name !== this.current && ['title', 'map', 'hud', 'shop'].includes(this.current)) this.prev = this.current;
    if (['title', 'map', 'shop', 'stats'].includes(name) && this.game.mode !== 'menu' && !this.game.paused) this.game.toMenu();
    if (['title', 'map', 'shop', 'stats'].includes(name) && this.game.paused) { this.game.paused = false; this.game.toMenu(); }
    $$('.screen').forEach((s) => s.classList.toggle('show', s.id === (name === 'hud' ? 'hud' : 'scr-' + name)));
    this.current = name;
    if (name !== 'hud') this.hideOverlays(['ov-pause']);
    if (name === 'hud' && this.game.paused) $('#ov-pause').classList.add('show');
    if (name === 'map') this.renderMap();
    if (name === 'shop') this.renderShop();
    if (name === 'settings') this.renderSettings();
    if (name === 'help') this.renderHelp();
    if (name === 'stats') this.renderStats();
    if (name === 'title') this.updateBananas();
    this.reframe();
    const focus = $(`#${name === 'hud' ? 'hud' : 'scr-' + name} .panel-head .back, #${name === 'hud' ? 'hud' : 'scr-' + name} .btn.primary`);
    if (focus && name !== 'hud' && matchMedia('(pointer: fine)').matches) focus.focus({ preventScroll: true });
  }

  /** Tell the 3D stage which strip of the screen the monkey should fill. */
  reframe() {
    requestAnimationFrame(() => {
      const H = window.innerHeight;
      let top = 60, bottom = 60;
      const ov = $$('.overlay.bottom.show .card')[0];
      if (this.current === 'title') {
        top = $('#scr-title .tagline').getBoundingClientRect().bottom + 4;
        bottom = H - $('#scr-title .title-actions').getBoundingClientRect().top + 8;
      } else if (this.current === 'shop') {
        top = $('#scr-shop .topbar').getBoundingClientRect().bottom;
        bottom = H - $('#scr-shop .sheet').getBoundingClientRect().top + 4;
      } else if (this.current === 'hud') {
        top = $('#hud .hud-mid').getBoundingClientRect().bottom + 2;
        bottom = H - $('#hud .hud-bottom').getBoundingClientRect().top + 6;
      } else {
        top = H * 0.08;
        bottom = H * 0.08;
      }
      if (ov) {
        const hudTop = this.current === 'hud' ? $('#hud .hud-top').getBoundingClientRect().bottom : 30;
        top = Math.min(top, hudTop + 8);
        bottom = Math.max(bottom, H - ov.getBoundingClientRect().top + 6);
      }
      this.app.stage.setFrame(top, bottom, !this.framedOnce);
      this.framedOnce = true;
    });
  }

  updateBananas(bump = false) {
    for (const el of $$('.banana-count')) el.textContent = Save.data.bananas;
    if (bump) for (const el of $$('.chip.bananas')) { el.classList.remove('bump'); void el.offsetWidth; el.classList.add('bump'); }
  }

  toast(msg, ms = 2400) {
    const t = $('#toast');
    t.textContent = msg;
    t.classList.add('show');
    clearTimeout(this.toastT);
    this.toastT = setTimeout(() => t.classList.remove('show'), ms);
  }

  announce(msg) {
    const el = $('#sr-live');
    el.textContent = '';
    setTimeout(() => { el.textContent = msg; }, 30);
  }

  // ------------------------------------------------------------ level map

  renderMap() {
    const reached = Save.worldReached();
    if (this.world > reached) this.world = reached;
    if (!this.mapVisited) { this.world = reached; this.mapVisited = true; }
    $('#world-tabs').innerHTML = WORLDS.map((w) => {
      const locked = w.id > reached;
      return `<button class="tab" role="tab" data-world="${w.id}" aria-selected="${w.id === this.world}" ${locked ? 'aria-disabled="true"' : ''}>${locked ? `<span class="lock">${ICON.lock}</span>` : ''}World ${w.id}</button>`;
    }).join('');
    $$('#world-tabs .tab').forEach((b) => b.addEventListener('click', () => {
      const id = Number(b.dataset.world);
      if (id > reached) {
        this.toast(`Clear level ${(id - 1) * 10} to open World ${id}.`);
        return;
      }
      this.click();
      this.world = id;
      this.renderMap();
    }));
    const w = WORLDS[this.world - 1];
    const levels = LEVELS.filter((l) => l.world === w.id);
    const stars = levels.reduce((s, l) => s + Save.levelInfo(l.id).stars, 0);
    $('#world-card').innerHTML = `<div><h3>${esc(w.name)}</h3><p>${esc(w.blurb)}</p></div><div class="world-stars">${ICON.star}<span>${stars}/${levels.length * 3}</span></div>`;
    const unlocked = Save.unlockedLevel();
    $('#level-grid').innerHTML = levels.map((l) => {
      const info = Save.levelInfo(l.id);
      const locked = l.id > unlocked;
      const isNext = l.id === unlocked && !info.clears;
      const label = locked ? `Level ${l.id}, locked` : `Level ${l.id}, ${l.name}, ${info.stars} of 3 stars`;
      return `<button class="level${l.boss ? ' boss' : ''}${isNext ? ' next' : ''}" data-level="${l.id}" ${locked ? 'disabled' : ''} aria-label="${esc(label)}">${locked ? `<span class="lock">${ICON.lock}</span>` : ''}<span class="num">${l.id}</span>${locked ? '' : `<span class="stars">${starsHtml(info.stars)}</span>`}</button>`;
    }).join('');
    $$('#level-grid .level').forEach((b) => b.addEventListener('click', () => {
      this.click();
      this.game.openLevel(Number(b.dataset.level));
    }));
  }

  // ------------------------------------------------------------ level intro

  showIntro(level, { bpm, timers, news, info }) {
    this.show('hud');
    this.hudSetup('adventure', { level, round: 0, lives: RULES.startLives, score: 0 });
    this.setPhase('ready');
    this.setSteps(0);
    this.padMode('off', level.moves);
    const minL = Math.min(...level.rounds), maxL = Math.max(...level.rounds);
    const tmin = Math.min(...timers), tmax = Math.max(...timers);
    const timerText = Number.isFinite(tmin) ? (tmin === tmax ? `Timer ${tmin} s` : `Timer ${tmin}-${tmax} s`) : 'No timer';
    const twistNames = [...new Set((Array.isArray(level.twist) ? level.twist : [level.twist]).filter(Boolean))].map((t) => TWISTS[t].name);
    const facts = [
      `${level.rounds.length} rounds`,
      minL === maxL ? `${minL} moves each` : `${minL}-${maxL} moves`,
      `${bpm} BPM`,
      timerText,
      ...twistNames.map((n) => `Twist: ${n}`),
      ...(level.chords.length ? [`Combos: ${level.chords.map((c) => CHORDS[c].name).join(', ')}`] : []),
    ];
    const newsHtml = news.map((n) => {
      if (n.kind === 'move') {
        const m = MOVES[n.id];
        return `<div class="new-item" data-new="${n.id}">${swatch(n.id)}<div><b><span class="badge-new">NEW</span>${esc(moveName(n.id, this.s.naming))}</b><small>${esc(m.verb)}. Button: ${esc(moveName(n.id, this.s.naming))} · key ${m.key.toUpperCase()} · swipe ${m.swipe}</small></div></div>`;
      }
      if (n.kind === 'chord') {
        const parts = chordSteps(n.id);
        return `<div class="new-item" data-new="${n.id}">${swatch(parts)}<div><b><span class="badge-new">NEW COMBO</span>${esc(CHORDS[n.id].name)}</b><small>${esc(parts.map((p) => moveName(p, this.s.naming)).join(' + '))}. Tap both buttons together (within ${this.s.assist ? RULES.assistChordWindowMs : RULES.chordWindowMs} ms).</small></div></div>`;
      }
      if (n.kind === 'twist') {
        return `<div class="new-item" data-new="${n.id}"><span class="swatch" style="background:#23160c;color:#ffd23f">${ICON.info}</span><div><b><span class="badge-new">NEW TWIST</span>${esc(TWISTS[n.id].name)}</b><small>${esc(TWISTS[n.id].text)}</small></div></div>`;
      }
      return '';
    }).join('');
    const w = WORLDS[level.world - 1];
    $('#intro-card').innerHTML = `
      <div class="eyebrow">World ${w.id} · ${esc(w.name)} · Level ${level.id}${level.boss ? ' · Boss' : ''}</div>
      <h2 id="intro-title">${esc(level.name)}</h2>
      <div class="facts">${facts.map((f) => `<span class="fact">${esc(f)}</span>`).join('')}</div>
      ${newsHtml ? `<div class="news">${newsHtml}</div>` : ''}
      ${info.clears ? `<p class="note">Your best: ${info.stars} star${info.stars === 1 ? '' : 's'}, ${info.best.toLocaleString()} points.</p>` : ''}
      <div class="actions">
        <button class="btn primary big" id="intro-go">Let's dance!</button>
        <button class="btn ghost" id="intro-back">Back to levels</button>
      </div>`;
    this.openOverlay('ov-intro');
    $('#intro-go').addEventListener('click', () => {
      this.audio.unlock();
      this.click();
      this.closeOverlay('ov-intro');
      this.game.startRun();
    });
    $('#intro-back').addEventListener('click', () => { this.click(); this.closeOverlay('ov-intro'); this.show('map'); });
    if (matchMedia('(pointer: fine)').matches) $('#intro-go').focus({ preventScroll: true });
  }

  introDemo(id) {
    $$('#intro-card .new-item').forEach((el) => el.classList.toggle('on', el.dataset.new === id));
  }

  // ------------------------------------------------------------ first-run how-to

  showHowto(then) {
    this.howtoThen = then;
    this.howtoPage = 0;
    this.renderHowto();
    this.openOverlay('ov-howto');
  }

  renderHowto() {
    const pages = [
      { art: `<div style="display:flex;gap:10px;align-items:center">${ICON.eye}</div>`, title: 'Monkey see...', text: 'The monkey dances a routine. Each move lights up its button and plays its own note. Watch the order.' },
      { art: `<div style="display:flex;gap:8px">${swatch('LA')}${swatch('RL')}${swatch('HD')}</div>`, title: '...monkey do!', text: 'When it says YOUR TURN, copy the moves in the same order. Tap the buttons, tap the monkey, swipe on the stage, or use the keys Q W E / A S D.' },
      { art: `<div style="display:flex;gap:6px">${ICON.heart}${ICON.heart}${ICON.heart}</div>`, title: 'Lives and the beat', text: `You have ${RULES.startLives} lives per level. A wrong move costs one and the routine plays again. Getting the order right is what counts. Tapping on the beat earns bonus points.` },
    ];
    const p = pages[this.howtoPage];
    const last = this.howtoPage === pages.length - 1;
    $('#howto-card').innerHTML = `
      <div class="howto-art">${p.art}</div>
      <div class="eyebrow">How to play · ${this.howtoPage + 1} of ${pages.length}</div>
      <h2>${esc(p.title)}</h2>
      <p>${esc(p.text)}</p>
      <div class="dots-nav">${pages.map((_, i) => `<i class="${i === this.howtoPage ? 'on' : ''}"></i>`).join('')}</div>
      <div class="actions"><button class="btn primary big" id="howto-next">${last ? 'Start Level 1' : 'Next'}</button>${this.howtoPage === 0 ? '<button class="btn ghost" id="howto-skip">Skip</button>' : ''}</div>`;
    $('.howto-art svg', $('#howto-card')) && ($('.howto-art', $('#howto-card')).querySelectorAll('svg').forEach((s) => { s.style.height = '64px'; s.style.width = 'auto'; }));
    $('#howto-next').addEventListener('click', () => {
      this.click();
      if (last) { this.closeOverlay('ov-howto'); this.howtoThen && this.howtoThen(); }
      else { this.howtoPage++; this.renderHowto(); }
    });
    const skip = $('#howto-skip');
    if (skip) skip.addEventListener('click', () => { this.closeOverlay('ov-howto'); this.howtoThen && this.howtoThen(); });
  }

  // ------------------------------------------------------------ HUD

  showHud(mode, run) {
    this.hideOverlays();
    this.show('hud');
    this.hudSetup(mode, run);
  }

  hudSetup(mode, run) {
    const lvl = $('#hud-level');
    const rnd = $('#hud-round');
    if (mode === 'adventure') {
      lvl.textContent = `Level ${run.level.id} · ${run.level.name}`;
      rnd.textContent = `Round ${run.round + 1} of ${run.level.rounds.length}`;
      this.lives(run.lives, RULES.startLives);
    } else if (mode === 'endless') {
      lvl.textContent = 'Endless';
      rnd.textContent = `Best: ${Save.data.endless.bestRounds} rounds`;
      this.lives(run.lives, 1);
    } else {
      lvl.textContent = 'Free Dance';
      rnd.textContent = 'Tap anything. No score, no timer.';
      $('#hud-lives').innerHTML = '';
    }
    $('#score').textContent = mode === 'free' ? '0 moves' : '0';
    $('#streak').textContent = '';
    $('#mistake').hidden = true;
    $('#coach').hidden = true;
    this.timer(null);
    this.replayButton(false);
    this.caption('');
    $('#twist').hidden = true;
    this.updateBananas();
    this.reframe();
  }

  hudRound(mode, run) {
    if (mode === 'adventure') $('#hud-round').textContent = `Round ${run.round + 1} of ${run.level.rounds.length}`;
    else if (mode === 'endless') $('#hud-round').textContent = `Round ${run.round + 1} · ${run.steps.length} moves · best ${Save.data.endless.bestRounds}`;
  }

  lives(n, max) {
    const el = $('#hud-lives');
    const prev = el.querySelectorAll('.heart:not(.lost)').length;
    el.innerHTML = Array.from({ length: max }, (_, i) => `<span class="heart${i >= n ? ' lost' : ''}${i === n && prev > n ? ' pop' : ''}">${ICON.heart}</span>`).join('');
    el.setAttribute('aria-label', `${n} of ${max} lives`);
  }

  score(n, streak) {
    $('#score').textContent = n.toLocaleString();
    const m = streak >= RULES.streakTiers[2].at ? 3 : streak >= RULES.streakTiers[1].at ? 2 : 1;
    $('#streak').textContent = streak >= 3 ? `streak ${streak}${m > 1 ? ` · x${m}` : ''}` : '';
  }

  freeCount(n) {
    $('#score').textContent = `${n} move${n === 1 ? '' : 's'}`;
  }

  setPhase(kind, twist) {
    const el = $('#phase');
    const text = { watch: 'WATCH!', respond: 'YOUR TURN!', free: 'FREE DANCE', oops: 'OOPS!', clear: 'NICE!', ready: 'GET READY' }[kind] || '';
    el.className = 'phase ' + (kind === 'ready' ? 'watch' : kind);
    el.textContent = text;
    void el.offsetWidth;
    el.classList.add('enter');
    const tw = $('#twist');
    if (twist && TWISTS[twist] && (kind === 'watch' || kind === 'respond')) {
      tw.hidden = false;
      tw.textContent = kind === 'respond' && twist === 'reverse' ? 'BACKWARDS: LAST MOVE FIRST' : TWISTS[twist].short;
    } else tw.hidden = true;
    if (kind === 'watch') this.announce('Watch');
  }

  nudge() {
    const el = $('#phase');
    el.classList.remove('shake');
    void el.offsetWidth;
    el.classList.add('shake');
  }

  setSteps(n) {
    $('#steps').innerHTML = Array.from({ length: n }, (_, i) => `<span class="dot" data-i="${i}"></span>`).join('');
  }

  countIn(k) {
    const dots = $$('#steps .dot');
    dots.forEach((d) => d.classList.toggle('count', k === 0));
    if (k === 1) dots.forEach((d) => d.classList.remove('count'));
  }

  watchStep(i, step) {
    const dots = $$('#steps .dot');
    dots.forEach((d, k) => {
      if (k < i) { d.className = 'dot seen'; d.innerHTML = ''; d.style.removeProperty('--c'); }
    });
    const d = dots[i];
    if (!d) return;
    d.className = 'dot now' + (step.length === 1 && inkMove(step[0]) ? ' ink' : '');
    d.style.setProperty('--c', MOVES[step[0]].color);
    if (step.length > 1) d.style.background = `linear-gradient(135deg, ${MOVES[step[0]].color} 50%, ${MOVES[step[1]].color} 50%)`;
    else d.style.background = '';
    d.innerHTML = moveIcon(step);
  }

  partialStep(i, ids) {
    const d = $$('#steps .dot')[i];
    if (!d) return;
    d.className = 'dot half';
    d.style.setProperty('--c', MOVES[ids[0]].color);
  }

  fillStep(i, step) {
    const d = $$('#steps .dot')[i];
    if (!d) return;
    d.className = 'dot done' + (step.length === 1 && inkMove(step[0]) ? ' ink' : '');
    d.style.setProperty('--c', MOVES[step[0]].color);
    d.style.background = step.length > 1 ? `linear-gradient(135deg, ${MOVES[step[0]].color} 50%, ${MOVES[step[1]].color} 50%)` : '';
    d.innerHTML = moveIcon(step);
  }

  caption(text) {
    $('#caption').textContent = text || '';
  }

  padMode(mode, allowed) {
    const pad = $('#pad');
    pad.className = 'pad ' + mode + (this.s.keyHints ? '' : ' nokeys');
    const allow = new Set(allowed || PAD_ORDER);
    for (const b of $$('#pad [data-move]')) {
      b.disabled = !allow.has(b.dataset.move);
      b.classList.remove('lit');
    }
  }

  /** Light the buttons for one Watch step (and switch off any still lit from the last one). */
  padLightStep(step) {
    for (const b of $$('#pad .pad-btn.lit')) if (!step.includes(b.dataset.move)) b.classList.remove('lit');
    for (const id of step) this.padLight(id);
  }

  padLight(id, short = false) {
    const b = $(`#pad [data-move="${id}"]`);
    if (!b) return;
    b.classList.add('lit');
    clearTimeout(b._lt);
    b._lt = setTimeout(() => b.classList.remove('lit'), short ? 160 : 380);
  }

  hintPad(step, guided = false) {
    $$('#pad .pad-btn').forEach((b) => b.classList.toggle('hint', !!step && step.includes(b.dataset.move)));
    const coach = $('#coach');
    if (step && guided) {
      coach.hidden = false;
      coach.textContent = step.length > 1 ? 'Tap both glowing buttons together' : 'Tap the glowing button';
    } else if (step) {
      coach.hidden = false;
      coach.textContent = 'Hint: this is the move you missed';
    } else coach.hidden = true;
  }

  timer(frac, secs) {
    const t = $('#timer');
    if (frac === null || frac === undefined) { t.classList.remove('on', 'low'); return; }
    t.classList.add('on');
    t.classList.toggle('low', frac < 0.25);
    $('#timer-fill').style.transform = `scaleX(${Math.max(0, Math.min(1, frac))})`;
    t.setAttribute('aria-label', `${Math.max(0, secs).toFixed(1)} seconds left`);
  }

  replayButton(show, cost = 0, enabled = true) {
    const b = $('#btn-replay');
    b.hidden = !show;
    if (!show) return;
    b.disabled = !enabled;
    b.innerHTML = enabled ? `Watch again${cost ? ` <span class="cost">${ICON.banana}${cost}</span>` : ' (free)'}` : 'Watched again';
  }

  pop(html, cls) {
    const box = $('#pops');
    const el = document.createElement('div');
    el.className = 'pop ' + cls;
    el.innerHTML = html;
    box.appendChild(el);
    setTimeout(() => el.remove(), 950);
  }

  grade(grade, pts, mult, label, offset) {
    const text = label || { perfect: 'Perfect!', great: 'Great!', good: 'Good', combo: 'Combo!' }[grade];
    const sub = pts ? `+${pts}${mult > 1 ? ` (x${mult})` : ''}` : '';
    let timing = '';
    if (grade === 'good' && typeof offset === 'number') timing = offset < 0 ? ' · early' : ' · late';
    this.pop(`${esc(text)}${sub || timing ? `<small>${esc(sub + timing)}</small>` : ''}`, grade);
  }

  bananaBurst(n) {
    this.pop(`<span style="width:30px;height:30px;display:inline-block">${ICON.banana}</span>+${n}`, 'bananas');
    const chip = $('#hud .chip.bananas');
    if (!chip || Save.settings.reduceMotion) { this.updateBananas(true); return; }
    const to = chip.getBoundingClientRect();
    const count = Math.min(6, n);
    for (let i = 0; i < count; i++) {
      const el = document.createElement('div');
      el.className = 'fly-banana';
      el.innerHTML = ICON.banana;
      el.style.left = `${window.innerWidth / 2 - 15 + (Math.random() - 0.5) * 80}px`;
      el.style.top = `${window.innerHeight * 0.42 + (Math.random() - 0.5) * 40}px`;
      document.body.appendChild(el);
      setTimeout(() => {
        const r = el.getBoundingClientRect();
        el.style.transform = `translate(${to.left - r.left}px, ${to.top - r.top}px) scale(0.6) rotate(200deg)`;
        el.style.opacity = '0.3';
      }, 60 + i * 70);
      setTimeout(() => el.remove(), 900 + i * 70);
    }
    setTimeout(() => this.updateBananas(true), 700);
  }

  roundClear(text) {
    this.setPhase('clear');
    this.caption(text);
    this.announce(text);
  }

  mistake(info, onGo, seconds) {
    const el = $('#mistake');
    const naming = this.s.naming;
    const exp = info.expected;
    let title = 'Oops!';
    let body = '';
    if (info.kind === 'timeout') {
      title = "Time's up!";
      body = `<p>Move ${info.index + 1} of ${info.total} was:</p><div class="compare"><div>${swatch(exp)}${esc(stepName(exp, naming))}</div></div>`;
    } else if (info.kind === 'combo') {
      title = 'Both at once!';
      body = `<p>Move ${info.index + 1} was a combo. Tap both buttons together:</p><div class="compare"><div>${swatch(exp)}${esc(stepName(exp, naming))}</div></div>`;
    } else {
      body = `<p>Move ${info.index + 1} of ${info.total}${info.twist === 'reverse' ? ' (backwards)' : ''}:</p><div class="compare"><div>${swatch(exp)}It was ${esc(stepName(exp, naming))}</div><span class="x">vs</span><div>${swatch(info.tapped)}You tapped ${esc(moveName(info.tapped, naming))}</div></div>`;
    }
    let btn;
    if (info.mode === 'endless') btn = 'See results';
    else if (info.lives > 0) btn = `Watch again (${info.lives} ${info.lives === 1 ? 'life' : 'lives'} left)`;
    else btn = 'Out of lives';
    el.innerHTML = `<h3>${title}</h3>${body}<button class="btn primary" id="mistake-go">${btn}<span class="fill" style="animation-duration:${seconds}s"></span></button>`;
    el.hidden = false;
    this.setPhase('oops');
    this.caption('');
    $('#mistake-go').addEventListener('click', () => { this.click(); onGo(); });
    this.announce(`${title} ${stepName(exp, naming)} was next.`);
  }

  hideMistake() {
    $('#mistake').hidden = true;
  }

  // ------------------------------------------------------------ results

  showResult(r) {
    const w = WORLDS[r.level.world - 1];
    const onBeatPct = r.steps ? Math.round((r.onBeat / r.steps) * 100) : 0;
    const rows = r.items.map((it, i) => `<tr><td>${esc(it.label)}${i === 0 ? ' <span class="note">(added during play)</span>' : ''}</td><td>+${it.amount}</td></tr>`).join('');
    const seeds = r.seeds.map((s) => s.toString(16).padStart(8, '0').slice(0, 6)).join(' · ');
    const starWhy = r.stars === 3 ? 'No lives lost and on the beat.' : r.stars === 2 ? (r.livesLost === 0 ? `For 3 stars: tap at least ${Math.round(RULES.threeStarOnBeat * 100)}% of moves Perfect or Great.` : 'For 3 stars: no lives lost, and on the beat.') : 'For 2 stars: lose at most 1 life.';
    $('#result-card').innerHTML = `
      <div class="eyebrow">World ${w.id} · Level ${r.level.id}</div>
      <h2>${esc(r.level.name)} cleared!</h2>
      <div class="big-stars">${[0, 1, 2].map((i) => `<span class="star${i < r.stars ? '' : ' off'}" style="animation-delay:${0.25 + i * 0.3}s">${i < r.stars ? ICON.star : ICON.starOff}</span>`).join('')}</div>
      <p class="note" style="text-align:center;margin:0">${esc(starWhy)}</p>
      <div class="result-stats">
        <div><b>${r.score.toLocaleString()}</b><span>${r.score > r.prevBest && r.prevBest ? 'New best!' : 'Points'}</span></div>
        <div><b>${onBeatPct}%</b><span>On the beat</span></div>
        <div><b>${r.livesLost}</b><span>Lives lost</span></div>
      </div>
      <table class="breakdown"><tbody>${rows}<tr class="total"><td>Bananas earned</td><td>+${r.total}</td></tr></tbody></table>
      ${r.newWorld ? `<div class="new-world">World ${r.newWorld.id} is open: ${esc(r.newWorld.name)}! Its stage is now in your wardrobe for free.</div>` : ''}
      <div class="seedline">Routine codes: ${seeds}. Each round's routine comes from its code, so the same code always makes the same dance.</div>
      <div class="actions">
        ${r.next ? '<button class="btn primary big" id="res-next">Next level</button>' : '<button class="btn primary big" id="res-endless">Try Endless</button>'}
        <div class="btn-row"><button class="btn" id="res-again">Play again</button><button class="btn" id="res-map">Levels</button></div>
      </div>`;
    this.openOverlay('ov-result');
    for (let i = 0; i < r.stars; i++) setTimeout(() => this.audio.sfx('star', null, i), 250 + i * 300);
    const next = $('#res-next');
    if (next) next.addEventListener('click', () => { this.click(); this.closeOverlay('ov-result'); this.game.openLevel(r.next.id); });
    const endless = $('#res-endless');
    if (endless) endless.addEventListener('click', () => { this.click(); this.closeOverlay('ov-result'); this.game.startEndless(); });
    $('#res-again').addEventListener('click', () => { this.click(); this.closeOverlay('ov-result'); this.game.openLevel(r.level.id); });
    $('#res-map').addEventListener('click', () => { this.click(); this.closeOverlay('ov-result'); this.show('map'); });
    this.updateBananas(true);
    this.announce(`Level cleared with ${r.stars} stars. ${r.total} bananas.`);
  }

  showFail(f) {
    const can = f.canContinue && f.bananas >= f.cost;
    const why = !f.canContinue ? 'You already used your continue on this try.' : f.bananas < f.cost ? `You have ${f.bananas} bananas; a continue costs ${f.cost}.` : `Spends ${f.cost} of your ${f.bananas} bananas. You keep your progress in this level.`;
    $('#result-card').innerHTML = `
      <div class="eyebrow">Level ${f.level.id} · ${esc(f.level.name)}</div>
      <h2>Out of lives</h2>
      <p>You reached round ${f.round} of ${f.rounds}, with ${f.score.toLocaleString()} points.</p>
      <div class="actions">
        <button class="btn primary" id="fail-cont" ${can ? '' : 'disabled'}>Continue with 1 life <span class="cost">${ICON.banana}${f.cost}</span></button>
        <p class="note" style="margin:-4px 0 0;font-size:13px;color:var(--cream-dim)">${esc(why)}</p>
        <div class="btn-row"><button class="btn" id="fail-retry">Start over</button><button class="btn" id="fail-map">Levels</button></div>
      </div>`;
    this.openOverlay('ov-result');
    $('#fail-cont').addEventListener('click', () => { this.click(); if (!this.game.continueRun()) this.toast('Not enough bananas.'); else this.updateBananas(true); });
    $('#fail-retry').addEventListener('click', () => { this.click(); this.closeOverlay('ov-result'); this.game.openLevel(f.level.id); });
    $('#fail-map').addEventListener('click', () => { this.click(); this.closeOverlay('ov-result'); this.show('map'); });
    this.announce('Out of lives');
  }

  showEndless(e) {
    const rows = e.items.map((it) => `<tr><td>${esc(it.label)}</td><td>+${it.amount}</td></tr>`).join('');
    $('#result-card').innerHTML = `
      <div class="eyebrow">Endless</div>
      <h2>${e.newBest ? 'New best!' : 'Nice dancing!'}</h2>
      <div class="result-stats">
        <div><b>${e.rounds}</b><span>Rounds</span></div>
        <div><b>${e.score.toLocaleString()}</b><span>Points</span></div>
        <div><b>${e.bestRounds}</b><span>Best rounds</span></div>
      </div>
      <p class="note">The last routine was ${e.longest} moves long. Longest streak: ${e.bestStreak}.</p>
      <table class="breakdown"><tbody>${rows}<tr class="total"><td>Bananas earned</td><td>+${e.total}</td></tr></tbody></table>
      <div class="seedline">Run code: ${e.seed.toString(16).padStart(8, '0').slice(0, 6)}</div>
      <div class="actions">
        <button class="btn primary big" id="end-again">Play again</button>
        <button class="btn" id="end-menu">Menu</button>
      </div>`;
    this.openOverlay('ov-result');
    $('#end-again').addEventListener('click', () => { this.click(); this.closeOverlay('ov-result'); this.game.startEndless(); });
    $('#end-menu').addEventListener('click', () => { this.click(); this.closeOverlay('ov-result'); this.show('title'); });
    this.updateBananas(true);
  }

  // ------------------------------------------------------------ pause

  showPause(mode) {
    $('#pause-card').innerHTML = `
      <h2 id="pause-title">Paused</h2>
      <p>${mode === 'adventure' ? 'If you pause while the monkey is dancing, the routine starts again from the top when you come back.' : mode === 'free' ? 'Free Dance has no score.' : 'Your run is waiting.'}</p>
      <div class="row" style="border:0;padding-bottom:0"><div class="label"><b>Music</b></div><input type="range" id="p-music" min="0" max="1" step="0.05" value="${this.s.music}" aria-label="Music volume"></div>
      <div class="row" style="border:0"><div class="label"><b>Moves and effects</b></div><input type="range" id="p-sfx" min="0" max="1" step="0.05" value="${this.s.sfx}" aria-label="Effects volume"></div>
      <div class="actions">
        <button class="btn primary big" id="p-resume">Resume</button>
        <div class="btn-row">${mode === 'adventure' ? '<button class="btn" id="p-restart">Restart level</button>' : mode === 'endless' ? '<button class="btn" id="p-restart">Restart run</button>' : '<span></span>'}<button class="btn" id="p-settings">Settings</button></div>
        <button class="btn ghost" id="p-quit">Quit to menu</button>
      </div>`;
    this.openOverlay('ov-pause');
    $('#p-music').addEventListener('input', (e) => { Save.setSetting('music', Number(e.target.value)); this.app.applySettings(); });
    $('#p-sfx').addEventListener('input', (e) => { Save.setSetting('sfx', Number(e.target.value)); this.app.applySettings(); });
    $('#p-resume').addEventListener('click', () => { this.click(); this.game.resume(); });
    const rs = $('#p-restart');
    if (rs) rs.addEventListener('click', () => {
      this.click();
      this.game.paused = false;
      this.closeOverlay('ov-pause');
      if (mode === 'adventure') this.game.openLevel(this.game.run.level.id);
      else this.game.startEndless();
    });
    $('#p-settings').addEventListener('click', () => { this.click(); this.closeOverlay('ov-pause'); this.show('settings'); this.prev = 'hud'; });
    $('#p-quit').addEventListener('click', () => { this.click(); this.game.quit(); this.show('title'); });
    if (matchMedia('(pointer: fine)').matches) $('#p-resume').focus({ preventScroll: true });
  }

  hidePause() {
    this.closeOverlay('ov-pause');
  }

  // ------------------------------------------------------------ overlays

  openOverlay(id) {
    $('#' + id).classList.add('show');
    this.reframe();
  }

  closeOverlay(id) {
    $('#' + id).classList.remove('show');
    this.reframe();
  }

  hideOverlays(only) {
    const ids = only || ['ov-intro', 'ov-result', 'ov-pause', 'ov-howto', 'ov-calibrate'];
    for (const id of ids) $('#' + id).classList.remove('show');
    $('#mistake').hidden = true;
    this.reframe();
  }

  confirm({ title, text, ok = 'OK', cancel = 'Cancel', danger = false }) {
    return new Promise((resolve) => {
      this.confirmResolve = resolve;
      $('#confirm-card').innerHTML = `<h2>${esc(title)}</h2><p>${esc(text)}</p><div class="actions"><button class="btn ${danger ? 'danger' : 'primary'}" id="cf-ok">${esc(ok)}</button><button class="btn ghost" id="cf-cancel">${esc(cancel)}</button></div>`;
      this.openOverlay('ov-confirm');
      $('#cf-ok').addEventListener('click', () => this.closeConfirm(true));
      $('#cf-cancel').addEventListener('click', () => this.closeConfirm(false));
    });
  }

  closeConfirm(v) {
    this.closeOverlay('ov-confirm');
    if (this.confirmResolve) this.confirmResolve(v);
    this.confirmResolve = null;
  }

  // ------------------------------------------------------------ wardrobe

  renderShop() {
    $('#shop-tabs').innerHTML = CATEGORIES.map((c) => `<button class="tab" role="tab" data-cat="${c.id}" aria-selected="${c.id === this.shopCat}">${esc(c.name)}</button>`).join('');
    $$('#shop-tabs .tab').forEach((b) => b.addEventListener('click', () => {
      this.click();
      this.shopCat = b.dataset.cat;
      this.endPreview();
      this.renderShop();
    }));
    const eq = Save.data.equipped;
    const reached = Save.worldReached();
    const items = itemsIn(this.shopCat);
    const extra = this.shopCat === 'stage' ? [{ id: 'auto', cat: 'stage', name: 'Match the world', price: 0, desc: 'Levels use their world\'s stage; menus use the jungle.' }] : [];
    const list = [...extra, ...items];
    const pv = this.preview && this.preview.cat === this.shopCat ? this.preview.id : null;
    $('#shop-grid').innerHTML = list.map((it) => {
      const owned = it.id === 'auto' || Save.owns(it.cat, it.id);
      const equipped = eq[it.cat] === it.id;
      let state;
      if (equipped) state = `<span class="state">${ICON.check}Wearing</span>`;
      else if (owned) state = '<span class="state">Owned</span>';
      else if (it.unlockWorld && reached < it.unlockWorld) state = `<span class="state price">${ICON.banana}${it.price} <span style="color:var(--cream-dim);font-weight:600">or reach World ${it.unlockWorld}</span></span>`;
      else state = `<span class="state price">${ICON.banana}${it.price}</span>`;
      const g = it.id === 'auto' ? glyph({ cat: 'stage', id: 'jungle' }) : glyph(it);
      return `<button class="item${equipped ? ' equipped' : ''}${pv === it.id ? ' previewing' : ''}" data-id="${it.id}" aria-label="${esc(it.name)}"><span class="glyph">${g}</span><span class="name">${esc(it.name)}</span>${state}</button>`;
    }).join('');
    $$('#shop-grid .item').forEach((b) => b.addEventListener('click', () => { this.click(); this.tryOn(this.shopCat, b.dataset.id); }));
    this.renderShopAction();
    this.updateBananas();
  }

  tryOn(cat, id) {
    this.preview = { cat, id };
    const look = { ...Save.data.equipped, [cat]: id };
    this.app.applyLook(look, true);
    if (cat === 'flair') this.app.monkey.play('FL', 1.0);
    else if (cat === 'stage') { /* environment changes in applyLook */ }
    else this.app.monkey.play('HOP', 0.5);
    $$('#shop-grid .item').forEach((b) => b.classList.toggle('previewing', b.dataset.id === id));
    this.renderShopAction();
  }

  endPreview() {
    if (!this.preview) return;
    this.preview = null;
    this.app.applyLook(Save.data.equipped);
  }

  renderShopAction() {
    let bar = $('#shop-action');
    if (!bar) {
      bar = document.createElement('div');
      bar.id = 'shop-action';
      bar.className = 'shop-action';
      $('#scr-shop .sheet').insertBefore(bar, $('#shop-tabs'));
    }
    const pv = this.preview;
    if (!pv) {
      bar.innerHTML = '<p>Tap anything to try it on. Nothing is bought until you press Buy.</p>';
      return;
    }
    const item = pv.id === 'auto' ? { id: 'auto', cat: 'stage', name: 'Match the world', price: 0, desc: 'Levels use their world\'s stage.' } : getItem(pv.cat, pv.id);
    const owned = pv.id === 'auto' || Save.owns(pv.cat, pv.id);
    const equipped = Save.data.equipped[pv.cat] === pv.id;
    const have = Save.data.bananas;
    let btn, text;
    if (equipped) { text = `${item.name}: ${item.desc}`; btn = `<button class="btn small" disabled>Wearing</button>`; }
    else if (owned) { text = `${item.name}: ${item.desc}`; btn = `<button class="btn small primary" id="shop-equip">Wear it</button>`; }
    else if (have >= item.price) { text = `${item.desc} You have ${have}; ${have - item.price} left after.`; btn = `<button class="btn small primary" id="shop-buy">Buy <span class="cost">${ICON.banana}${item.price}</span></button>`; }
    else { text = `${item.desc} You need ${item.price - have} more bananas.`; btn = `<button class="btn small" disabled>Buy <span class="cost">${ICON.banana}${item.price}</span></button>`; }
    bar.innerHTML = `<p>${esc(text)}</p>${btn}`;
    const eq = $('#shop-equip');
    if (eq) eq.addEventListener('click', () => {
      this.click();
      Save.equip(pv.cat, pv.id);
      this.preview = null;
      this.app.applyLook(Save.data.equipped);
      this.renderShop();
      this.toast(`Now wearing ${item.name}.`);
    });
    const buy = $('#shop-buy');
    if (buy) buy.addEventListener('click', () => {
      if (Save.buy(pv.cat, pv.id)) {
        Save.equip(pv.cat, pv.id);
        this.audio.sfx('buy');
        this.preview = null;
        this.app.applyLook(Save.data.equipped);
        this.app.monkey.play('CHEER', 1.4);
        this.renderShop();
        this.updateBananas(true);
        this.toast(`Bought ${item.name} for ${item.price} bananas.`);
      }
    });
  }

  // ------------------------------------------------------------ settings

  renderSettings() {
    const s = this.s;
    const rowHtml = (it) => {
      const help = typeof it.help === 'function' ? it.help() : it.help;
      const label = `<div class="label"><b id="lbl-${it.key || it.action}">${esc(it.label)}</b>${help ? `<small>${esc(help)}</small>` : ''}</div>`;
      if (it.type === 'toggle') return `<div class="row">${label}<button class="toggle" role="switch" id="set-${it.key}" data-key="${it.key}" aria-checked="${!!s[it.key]}" aria-labelledby="lbl-${it.key}"></button></div>`;
      if (it.type === 'range') return `<div class="row">${label}<input type="range" id="set-${it.key}" data-key="${it.key}" min="0" max="1" step="0.05" value="${s[it.key]}" aria-labelledby="lbl-${it.key}"></div>`;
      if (it.type === 'seg') return `<div class="row">${label}<div class="seg" role="group" aria-labelledby="lbl-${it.key}">${it.options.map(([v, t]) => `<button data-key="${it.key}" data-val="${v}" aria-pressed="${String(s[it.key]) === String(v)}">${esc(t)}</button>`).join('')}</div></div>`;
      if (it.type === 'action') return `<div class="row">${label}<button class="btn small" id="act-${it.action}">${esc(it.button)}</button></div>`;
      return '';
    };
    const groups = SETTINGS.map((g) => `<div class="group"><h3>${esc(g.group)}</h3>${g.items.map(rowHtml).join('')}</div>`).join('');
    const d = Save.data;
    const dataGroup = `<div class="group"><h3>Your data</h3>
      <p class="note" style="margin:0 0 8px;color:var(--cream-dim);font-size:14px;line-height:1.45">Everything is saved on this device only${Save.storageOk ? '' : ' (this browser is blocking storage, so progress will be lost when you close it)'}. Nothing is sent anywhere: no account, no ads, no tracking. Saved: ${Object.keys(d.levels).length} levels played, ${d.bananas} bananas, ${Object.values(d.owned).reduce((n, a) => n + a.length, 0)} wardrobe items, your settings and stats.</p>
      <div class="btn-line"><button class="btn small" id="data-view">Show saved data</button><button class="btn small" id="data-copy">Copy save code</button><button class="btn small" id="data-load">Load save code</button><button class="btn small danger" id="data-reset">Reset everything</button></div>
      <div id="data-out"></div></div>`;
    const about = `<div class="group"><h3>About</h3><p class="note" style="margin:0;color:var(--cream-dim);font-size:14px;line-height:1.45">Monkey See, Monkey Do · version ${esc(this.app.version)}. Made with three.js (MIT licence). Fonts: Lilita One and Baloo 2 (SIL Open Font Licence). All music and sounds are generated live by the game.</p></div>`;
    $('#settings-body').innerHTML = groups + dataGroup + about;
    const body = $('#settings-body');
    $$('.toggle', body).forEach((b) => b.addEventListener('click', () => {
      const v = b.getAttribute('aria-checked') !== 'true';
      b.setAttribute('aria-checked', String(v));
      Save.setSetting(b.dataset.key, v);
      this.app.applySettings();
      this.click();
    }));
    $$('input[type=range]', body).forEach((r) => r.addEventListener('input', () => {
      Save.setSetting(r.dataset.key, Number(r.value));
      this.app.applySettings();
    }));
    $$('.seg button', body).forEach((b) => b.addEventListener('click', () => {
      const key = b.dataset.key;
      const raw = b.dataset.val;
      const v = isNaN(Number(raw)) ? raw : Number(raw);
      Save.setSetting(key, v);
      $$(`.seg button[data-key="${key}"]`, body).forEach((x) => x.setAttribute('aria-pressed', String(x === b)));
      this.app.applySettings();
      this.click();
    }));
    $('#act-calibrate').addEventListener('click', () => { this.audio.unlock(); this.showCalibrate(); });
    $('#data-view').addEventListener('click', () => {
      $('#data-out').innerHTML = `<pre class="save-view">${esc(JSON.stringify(Save.data, null, 2))}</pre>`;
    });
    $('#data-copy').addEventListener('click', async () => {
      const code = Save.exportCode();
      $('#data-out').innerHTML = `<p class="note" style="font-size:13px;color:var(--cream-dim)">Your save code (keep it somewhere safe to move progress to another device):</p><textarea id="code-out" readonly>${esc(code)}</textarea>`;
      try { await navigator.clipboard.writeText(code); this.toast('Save code copied.'); } catch { $('#code-out').select(); this.toast('Select the code and copy it.'); }
    });
    $('#data-load').addEventListener('click', () => {
      $('#data-out').innerHTML = `<p class="note" style="font-size:13px;color:var(--cream-dim)">Paste a save code. This replaces your current progress.</p><textarea id="code-in" placeholder="Paste save code here"></textarea><div class="btn-line"><button class="btn small primary" id="code-apply">Load it</button></div>`;
      $('#code-apply').addEventListener('click', async () => {
        const ok = await this.confirm({ title: 'Replace your progress?', text: 'Your current bananas, levels and wardrobe on this device will be replaced by the pasted save.', ok: 'Replace', danger: true });
        if (!ok) return;
        try {
          Save.importCode($('#code-in').value);
          this.app.applySettings();
          this.app.applyLook(Save.data.equipped);
          this.updateBananas();
          this.renderSettings();
          this.toast('Save loaded.');
        } catch (e) {
          this.toast(e.message && e.message.includes('Monkey') ? e.message : 'That code did not work. Check it was copied completely.');
        }
      });
    });
    $('#data-reset').addEventListener('click', async () => {
      const ok = await this.confirm({ title: 'Reset everything?', text: 'This deletes your bananas, stars, wardrobe, stats and settings on this device. It cannot be undone.', ok: 'Reset', danger: true });
      if (!ok) return;
      Save.reset();
      this.app.applySettings();
      this.app.applyLook(Save.data.equipped);
      this.relabelPad();
      this.updateBananas();
      this.renderSettings();
      this.toast('Everything was reset.');
    });
  }

  // ------------------------------------------------------------ rhythm calibration

  showCalibrate() {
    const card = $('#calibrate-card');
    const render = (state, result) => {
      card.innerHTML = `
        <div class="eyebrow">Rhythm calibration</div>
        <h2>Tap with the beat</h2>
        <p>You'll hear 12 clicks. Tap the big button on each click. We measure how late or early your taps land and adjust the timing grades to match your device.</p>
        <div class="beat-lamp" id="cal-lamp"></div>
        <button class="tap-target" id="cal-tap" ${state === 'run' ? '' : 'disabled'}>${state === 'run' ? 'TAP' : state === 'done' ? 'Done' : 'Ready'}</button>
        ${result ? `<p id="cal-result"><b>${result}</b></p>` : ''}
        <div class="actions">
          ${state === 'idle' ? '<button class="btn primary" id="cal-start">Start</button>' : ''}
          ${state === 'done' && this.calValue !== null ? `<button class="btn primary" id="cal-save">Use ${this.calValue} ms</button>` : ''}
          ${state === 'done' ? '<button class="btn" id="cal-again">Try again</button>' : ''}
          <div class="btn-row"><button class="btn ghost" id="cal-zero">Set to 0</button><button class="btn ghost" id="cal-close">Close</button></div>
        </div>`;
      const st = $('#cal-start');
      if (st) st.addEventListener('click', run);
      const ag = $('#cal-again');
      if (ag) ag.addEventListener('click', run);
      const sv = $('#cal-save');
      if (sv) sv.addEventListener('click', () => { Save.setSetting('latencyMs', this.calValue); this.toast(`Timing adjusted by ${this.calValue} ms.`); this.closeOverlay('ov-calibrate'); if (this.current === 'settings') this.renderSettings(); });
      $('#cal-zero').addEventListener('click', () => { Save.setSetting('latencyMs', 0); this.toast('Timing adjustment set to 0 ms.'); this.closeOverlay('ov-calibrate'); if (this.current === 'settings') this.renderSettings(); });
      $('#cal-close').addEventListener('click', () => { this.calRunning = false; this.closeOverlay('ov-calibrate'); });
    };
    const run = () => {
      this.audio.unlock();
      render('run');
      this.calRunning = true;
      const period = 0.6;
      const t0 = this.audio.now() + 0.8;
      const ticks = Array.from({ length: 12 }, (_, k) => t0 + k * period);
      const taps = [];
      ticks.forEach((t) => {
        this.audio.sfx('tick', t);
        setTimeout(() => {
          const lamp = $('#cal-lamp');
          if (!lamp) return;
          lamp.classList.add('on');
          setTimeout(() => lamp.classList.remove('on'), 120);
        }, Math.max(0, (t - this.audio.now()) * 1000));
      });
      const tap = $('#cal-tap');
      tap.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        const t = e.timeStamp / 1000;
        let best = Infinity;
        for (const tk of ticks) if (Math.abs(t - tk) < Math.abs(best)) best = t - tk;
        if (Math.abs(best) < period / 2) taps.push(best);
        tap.classList.add('flash');
        setTimeout(() => tap.classList.remove('flash'), 80);
      });
      setTimeout(() => {
        if (!this.calRunning) return;
        this.calRunning = false;
        const use = taps.slice(2).sort((a, b) => a - b); // ignore the first two taps while you find the beat
        if (use.length < 5) {
          this.calValue = null;
          render('done', `Only ${taps.length} taps were close to the beat. Try again and tap on every click.`);
          return;
        }
        const med = use[Math.floor(use.length / 2)];
        this.calValue = Math.round(med * 1000);
        render('done', `Your taps land ${Math.abs(this.calValue)} ms ${this.calValue >= 0 ? 'late' : 'early'} on average.`);
      }, (t0 + 12 * period - this.audio.now() + 0.6) * 1000);
    };
    this.calValue = null;
    render('idle');
    this.openOverlay('ov-calibrate');
  }

  // ------------------------------------------------------------ how it works

  renderHelp() {
    const n = this.s.naming;
    const moveRows = ['LA', 'RA', 'LL', 'RL', 'HD', 'FL'].map((id) => {
      const m = MOVES[id];
      return `<tr><td><div class="move-cell">${swatch(id)}<b>${esc(moveName(id, n))}</b></div></td><td>${esc(m.verb)}</td><td><kbd>${m.key.toUpperCase()}</kbd> or <kbd>${m.alt}</kbd></td><td>${esc(m.swipe)}</td><td>${m.noteName}</td></tr>`;
    }).join('');
    const chordRows = Object.values(CHORDS).map((c) => {
      const first = LEVELS.find((l) => l.chords.includes(c.id));
      return `<tr><td><div class="move-cell">${swatch(c.parts)}<b>${esc(c.name)}</b></div></td><td>${esc(c.parts.map((p) => moveName(p, n)).join(' + '))}</td><td>Level ${first ? first.id : '-'}</td></tr>`;
    }).join('');
    const levelRows = LEVELS.map((l) => {
      const bpm = Math.round(l.bpm * (this.s.speed || 1));
      const t = l.rounds.map((k) => timeLimit(k, bpm, this.s.timer));
      const tt = Number.isFinite(t[0]) ? `${Math.min(...t)}-${Math.max(...t)} s` : 'off';
      const tw = [...new Set((Array.isArray(l.twist) ? l.twist : [l.twist]).filter(Boolean))].map((x) => TWISTS[x].name).join(', ');
      const news = (l.intro || []).map((id) => (MOVES[id] ? moveName(id, n) : CHORDS[id] ? CHORDS[id].name : TWISTS[id] ? TWISTS[id].name : id)).join(', ');
      return `<tr><td>${l.id}${l.boss ? ' (boss)' : ''}</td><td>${esc(l.name)}</td><td>${l.rounds.join(', ')}</td><td>${bpm}</td><td>${tt}</td><td class="wrap">${esc([news && 'New: ' + news, tw && 'Twist: ' + tw].filter(Boolean).join('. '))}</td></tr>`;
    }).join('');
    const tiers = RULES.streakTiers.map((t) => `${t.at}+ in a row: x${t.mult}`).join(', ');
    const shopRows = CATEGORIES.map((c) => `<tr><td>${esc(c.name)}</td><td class="wrap">${itemsIn(c.id).map((i) => `${esc(i.name)} (${i.price ? i.price : 'free'}${i.unlockWorld ? `, or free at World ${i.unlockWorld}` : ''})`).join(', ')}</td></tr>`).join('');
    $('#help-body').innerHTML = `
      <h3>The game in one minute</h3>
      <ol>
        <li><b>Watch.</b> The monkey dances a routine on the beat. Each move lights up its button and the dance floor, and plays its own note.</li>
        <li><b>Your turn.</b> Copy the routine in the same order before the timer runs out.</li>
        <li><b>Cheer or oops.</b> Get it right and the next round is longer. A wrong move or running out of time costs a life, and the same routine plays again so you can learn it.</li>
      </ol>
      <p>Each level has ${RULES.startLives} lives and 3 or 4 rounds. Clear a level to open the next one. Clear level 10 to open World 2, and level 20 to open World 3.</p>

      <h3>The moves</h3>
      <p class="note">Left and right are ${n === 'monkey' ? "the monkey's own sides (Settings > Name sides by)" : 'the sides of your screen, like a mirror (change in Settings > Name sides by)'}. Buttons never move.</p>
      <div class="table-wrap"><table><thead><tr><th>Move</th><th>What it does</th><th>Keys</th><th>Swipe</th><th>Note</th></tr></thead><tbody>${moveRows}</tbody></table></div>
      <p class="note">You can also tap the monkey itself: a hand for an arm, a foot for a leg, the head, or the belly for Flair.</p>

      <h3>Combos</h3>
      <p>Some steps are two moves at once. Tap both within ${RULES.chordWindowMs} ms (${RULES.assistChordWindowMs} ms in Assist mode). The order of the two taps doesn't matter.</p>
      <div class="table-wrap"><table><thead><tr><th>Combo</th><th>Moves</th><th>First seen</th></tr></thead><tbody>${chordRows}</tbody></table></div>

      <h3>Twists</h3>
      <ul>${Object.values(TWISTS).map((t) => `<li><b>${esc(t.name)}:</b> ${esc(t.text)}</li>`).join('')}</ul>

      <h3>Timer</h3>
      <p>Time to copy a routine = ${RULES.timerBase} s + ${RULES.timerPerStep} s per move x (100 / tempo in BPM). Faster songs give a little less time. Relaxed timer gives ${RULES.relaxedTimerMult}x; you can also turn it off. A combo you start must be finished inside its window.</p>

      <h3>Points</h3>
      <ul>
        <li>${RULES.pointsPerStep} points for each move you copy.</li>
        <li>Timing bonus: <b>Perfect</b> (within ${RULES.perfectMs} ms of a beat) +${RULES.perfectBonus}; <b>Great</b> (within ${RULES.greatMs} ms) +${RULES.greatBonus}; <b>Good</b> (any other time) +0.</li>
        <li>Streak multiplier on move points: ${tiers}. A mistake resets the streak.</li>
        <li>+${RULES.roundBonus} for each round cleared.</li>
      </ul>
      <p class="note">Timing never decides whether a move counts: the right move at any time is correct. Timing only adds points and the third star.</p>

      <h3>Stars</h3>
      <ul>
        <li>1 star: clear the level.</li>
        <li>2 stars: lose at most 1 life.</li>
        <li>3 stars: lose no lives, and tap at least ${Math.round(RULES.threeStarOnBeat * 100)}% of moves Perfect or Great.</li>
      </ul>

      <h3>Bananas</h3>
      <ul>
        <li>Levels: ${RULES.bananasPerStep} banana per move in each round you clear (added right away), plus ${RULES.bananasPerStar} per star when you clear the level, plus ${RULES.firstClearBananas} the first time you clear it. Replaying a level earns bananas again.</li>
        <li>Endless: ${RULES.endlessPerRound} per round, ${RULES.endlessMilestoneBananas} extra for every ${RULES.endlessMilestoneEvery} rounds, and ${RULES.endlessBestBonus} for a new best.</li>
        <li>Spend them in the Wardrobe, on "Watch again" during your turn (${RULES.replayCost}, free in Assist mode), or to continue a level with 1 life after running out (${RULES.continueCost}, once per try).</li>
        <li>Bananas can't be bought with money. There are no ads and nothing to buy for real money anywhere in the game.</li>
      </ul>
      <p class="note">Every banana you earn or spend is listed under Stats > Banana history.</p>

      <h3>Endless</h3>
      <p>The classic memory loop: the routine starts at ${ENDLESS.startLength} moves and gains ${ENDLESS.addPerRound} each round. Tempo starts at ${ENDLESS.startBpm} BPM and rises ${ENDLESS.bpmPerRound} BPM a round, up to ${ENDLESS.maxBpm}. Combos join from round ${ENDLESS.chordsFromRound + 1}. One mistake ends the run.</p>

      <h3>How routines are made</h3>
      <ul>
        <li>Routines are random, drawn from the moves the level allows.</li>
        <li>The same move never shows up three times in a row, and two combos never follow each other.</li>
        <li>Once combos are unlocked, about ${Math.round(0.22 * 100)}% of moves are combos (30% on levels 19 and 28).</li>
        <li>A level that teaches something new always uses it in its first round.</li>
        <li>After a mistake you get the same routine again, not a new one.</li>
        <li>The results screen shows each round's code. The same code always makes the same routine.</li>
      </ul>

      <h3>All 30 levels</h3>
      <p class="note">Tempos and timers below use your current speed and timer settings.</p>
      <div class="table-wrap"><table><thead><tr><th>#</th><th>Name</th><th>Moves per round</th><th>BPM</th><th>Timer</th><th>What's new</th></tr></thead><tbody>${levelRows}</tbody></table></div>

      <h3>Wardrobe prices</h3>
      <div class="table-wrap"><table><thead><tr><th>Type</th><th>Items (bananas)</th></tr></thead><tbody>${shopRows}</tbody></table></div>
      <p class="note">Looks are just for fun: nothing in the wardrobe changes scores, timers or difficulty.</p>

      <h3>Your privacy</h3>
      <p>The game runs entirely on your device. Progress is saved in this browser's storage. No account, no ads, no analytics, no data sent anywhere. Settings > Your data shows exactly what is saved, and lets you copy it or delete it.</p>`;
  }

  // ------------------------------------------------------------ stats

  renderStats() {
    const st = Save.data.stats;
    const d = Save.data;
    const totalStars = Save.totalStars();
    const acc = st.stepsCorrect + st.mistakes + st.timeouts ? Math.round((st.stepsCorrect / (st.stepsCorrect + st.mistakes + st.timeouts)) * 100) : 0;
    const onBeat = st.stepsCorrect ? Math.round(((st.perfects + st.greats) / st.stepsCorrect) * 100) : 0;
    const tiles = [
      [d.bananas, 'Bananas now'],
      [d.earned, 'Bananas earned'],
      [`${totalStars}/90`, 'Stars'],
      [Object.values(d.levels).filter((l) => l.clears).length + '/30', 'Levels cleared'],
      [d.endless.bestRounds, 'Endless best (rounds)'],
      [st.roundsCleared, 'Rounds cleared'],
      [`${acc}%`, 'Moves right'],
      [`${onBeat}%`, 'On the beat'],
      [st.bestStreak, 'Longest streak'],
    ];
    const moveBars = ['LA', 'RA', 'LL', 'RL', 'HD', 'FL'].map((id) => {
      const pm = st.perMove[id] || { ok: 0, miss: 0 };
      const tot = pm.ok + pm.miss;
      const pct = tot ? Math.round((pm.ok / tot) * 100) : 0;
      return `<div class="bar-row"><span>${esc(moveName(id, this.s.naming))}</span><div class="bar"><i style="width:${pct}%;background:${MOVES[id].color}"></i></div><span>${tot ? pct + '%' : '-'}</span></div>`;
    }).join('');
    const mix = Object.entries(st.mixups).sort((a, b) => b[1] - a[1]).slice(0, 3);
    const mixHtml = mix.length ? `<ul class="ledger">${mix.map(([k, v]) => { const [a, b] = k.split('>'); return `<li><span>Expected ${esc(moveName(a, this.s.naming))}, tapped ${esc(moveName(b, this.s.naming))}</span><span>${v}x</span></li>`; }).join('')}</ul>` : '<p class="note" style="color:var(--cream-dim)">No mix-ups yet.</p>';
    const ledger = d.ledger.length ? `<ul class="ledger">${d.ledger.map((e) => `<li><span>${esc(e.reason)}<br><small style="color:var(--cream-dim)">${new Date(e.t).toLocaleString()}</small></span><span class="${e.amount >= 0 ? 'plus' : 'minus'}">${e.amount >= 0 ? '+' : ''}${e.amount}</span></li>`).join('')}</ul>` : '<p class="note" style="color:var(--cream-dim)">Nothing yet. Play a level to earn bananas.</p>';
    $('#stats-body').innerHTML = `
      <div class="tiles">${tiles.map(([v, l]) => `<div class="tile"><b>${v}</b><span>${esc(l)}</span></div>`).join('')}</div>
      <div class="group"><h3>Moves you get right</h3>${moveBars}</div>
      <div class="group"><h3>Most common mix-ups</h3>${mixHtml}</div>
      <div class="group"><h3>Banana history</h3><p class="note" style="margin:0 0 6px;color:var(--cream-dim);font-size:13px">The last ${d.ledger.length} changes. Earned in total: ${d.earned}. Spent: ${d.spent}.</p>${ledger}</div>`;
  }
}
