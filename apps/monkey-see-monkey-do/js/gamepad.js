// Game controllers (browser Gamepad API, "standard" layout: Xbox, PlayStation,
// Switch Pro, Steam Deck and most others).
//   Playing:  LB / RB = Left / Right Arm, LT / RT = Left / Right Leg,
//             Y (top button) = Head Bob, A (bottom button) = Flair.
//             The D-pad plays too: up Head Bob, down Flair, left / right arms.
//   Menus:    D-pad or left stick moves between buttons, A chooses, B goes back,
//             Start / Menu pauses. Left / right on a slider changes it.
// Browsers only report a controller after one of its buttons is pressed.

// standard-mapping button index -> move while playing
export const PLAY_BUTTONS = { 4: 'LA', 5: 'RA', 6: 'LL', 7: 'RL', 3: 'HD', 0: 'FL', 12: 'HD', 13: 'FL', 14: 'LA', 15: 'RA' };
const START = 9;
const BACK_BTN = 1;
const SELECT = 0;
const DIRS = { 12: 'up', 13: 'down', 14: 'left', 15: 'right' };

/** Which button names to show for a controller id string. */
export function padFamily(id = '') {
  const s = id.toLowerCase();
  if (/playstation|dualshock|dualsense|054c/.test(s)) return 'playstation';
  if (/nintendo|switch|057e|joy-con/.test(s)) return 'nintendo';
  return 'xbox';
}

/** The label of the button that plays each move, for the on-screen pad. */
export function glyphFor(move, family = 'xbox') {
  const t = {
    xbox: { LA: 'LB', RA: 'RB', LL: 'LT', RL: 'RT', HD: 'Y', FL: 'A' },
    playstation: { LA: 'L1', RA: 'R1', LL: 'L2', RL: 'R2', HD: '△', FL: '✕' },
    nintendo: { LA: 'L', RA: 'R', LL: 'ZL', RL: 'ZR', HD: 'X', FL: 'B' },
  };
  return (t[family] || t.xbox)[move] || '';
}

/** Pick the element to focus when moving in a direction (simple spatial navigation). */
export function nearestInDirection(from, candidates, dir) {
  const c = (r) => ({ x: r.left + r.width / 2, y: r.top + r.height / 2 });
  const a = c(from);
  let best = null;
  let bestScore = Infinity;
  for (const el of candidates) {
    const r = el.getBoundingClientRect ? el.getBoundingClientRect() : el.rect;
    const b = c(r);
    const dx = b.x - a.x, dy = b.y - a.y;
    const along = dir === 'up' ? -dy : dir === 'down' ? dy : dir === 'left' ? -dx : dx;
    const across = dir === 'up' || dir === 'down' ? Math.abs(dx) : Math.abs(dy);
    if (along <= 4) continue;
    const score = along + across * 2.2;
    if (score < bestScore) { bestScore = score; best = el; }
  }
  return best;
}

export class Gamepads {
  /**
   * fire(moveId): play a move. isPlaying(): moves (true) or menus (false).
   * onPause(), onBack(): pause toggle and back. onActive(family|null): a
   * controller was just used (null = keyboard/touch used again).
   */
  constructor({ fire, isPlaying, onPause, onBack, onActive, enabled }) {
    Object.assign(this, { fire, isPlaying, onPause, onBack, onActive, enabled });
    this.prev = {};
    this.hold = {};
    this.family = null;
    this.supported = typeof navigator !== 'undefined' && typeof navigator.getGamepads === 'function';
    if (typeof window !== 'undefined') {
      const human = () => { if (this.family) { this.family = null; document.body.classList.remove('gp-nav'); this.onActive(null); } };
      window.addEventListener('pointerdown', human, { capture: true, passive: true });
      window.addEventListener('keydown', human, { capture: true, passive: true });
    }
  }

  poll(nowMs = performance.now()) {
    if (!this.supported || !this.enabled()) return;
    let pads;
    try { pads = navigator.getGamepads(); } catch { return; }
    for (const gp of pads || []) {
      if (!gp || !gp.connected) continue;
      const prev = this.prev[gp.index] || (this.prev[gp.index] = []);
      const btn = (i) => { const b = gp.buttons[i]; return !!b && (b.pressed || b.value > 0.5); };
      // the left stick acts as a D-pad in menus
      const ax = gp.axes || [];
      const stick = { 12: ax[1] < -0.6, 13: ax[1] > 0.6, 14: ax[0] < -0.6, 15: ax[0] > 0.6 };
      const n = Math.max(gp.buttons.length, 16);
      for (let i = 0; i < n; i++) {
        const down = btn(i) || (!this.isPlaying() && !!stick[i]);
        const was = !!prev[i];
        prev[i] = down;
        if (!down) { delete this.hold[`${gp.index}:${i}`]; continue; }
        const key = `${gp.index}:${i}`;
        let press = !was;
        // held D-pad / stick in menus repeats
        if (was && DIRS[i] && !this.isPlaying()) {
          const h = this.hold[key] || (this.hold[key] = { next: nowMs + 380 });
          if (nowMs >= h.next) { press = true; h.next = nowMs + 130; }
        }
        if (!press) continue;
        this.activate(gp.id);
        this.press(i, nowMs);
      }
    }
  }

  activate(id) {
    const fam = padFamily(id);
    if (fam !== this.family) { this.family = fam; this.onActive(fam); }
  }

  press(i, nowMs) {
    if (i === START) { this.onPause(); return; }
    if (this.isPlaying()) {
      const move = PLAY_BUTTONS[i];
      if (move) this.fire(move, nowMs);
      else if (i === BACK_BTN) this.onBack();
      return;
    }
    if (DIRS[i]) this.navigate(DIRS[i]);
    else if (i === SELECT) this.choose();
    else if (i === BACK_BTN) this.onBack();
  }

  /** The part of the page the player is looking at: the top card, or the screen. */
  root() {
    const overlays = [...document.querySelectorAll('.overlay.show')];
    if (overlays.length) return overlays[overlays.length - 1];
    const mistake = document.querySelector('#mistake:not([hidden])');
    if (mistake) return mistake;
    return document.querySelector('.screen.show') || document.body;
  }

  focusables(root) {
    const sel = 'button:not([disabled]), a[href], input:not([disabled]), textarea, [tabindex]:not([tabindex="-1"])';
    return [...root.querySelectorAll(sel)].filter((el) => {
      if (el.closest('[hidden]')) return false;
      const r = el.getBoundingClientRect();
      return r.width > 0 && r.height > 0 && getComputedStyle(el).visibility !== 'hidden';
    });
  }

  navigate(dir) {
    document.body.classList.add('gp-nav');
    const root = this.root();
    const list = this.focusables(root);
    if (!list.length) return;
    const cur = document.activeElement;
    if (!cur || !root.contains(cur) || cur === document.body) {
      (root.querySelector('.btn.primary:not([disabled])') || list[0]).focus();
      return;
    }
    if (cur.matches('input[type=range]') && (dir === 'left' || dir === 'right')) {
      const step = Number(cur.step) || 0.05;
      cur.value = String(Math.max(Number(cur.min), Math.min(Number(cur.max), Number(cur.value) + (dir === 'left' ? -step : step))));
      cur.dispatchEvent(new Event('input', { bubbles: true }));
      return;
    }
    const next = nearestInDirection(cur.getBoundingClientRect(), list.filter((el) => el !== cur), dir);
    if (next) {
      next.focus({ preventScroll: true });
      next.scrollIntoView({ block: 'nearest', inline: 'nearest' });
    }
  }

  choose() {
    document.body.classList.add('gp-nav');
    const root = this.root();
    const cur = document.activeElement;
    if (cur && cur !== document.body && root.contains(cur)) {
      if (typeof cur.click === 'function') cur.click();
      return;
    }
    this.navigate('down');
  }
}
