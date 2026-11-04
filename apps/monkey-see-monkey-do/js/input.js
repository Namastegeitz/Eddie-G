// Every way to make a move: the on-screen pad, the keyboard (Q W E / A S D or
// 7 8 9 / 4 5 6), swiping on the stage, and tapping the monkey's body.
import { MOVES, PAD_ORDER } from './moves.js';

const KEYMAP = {};
for (const id of PAD_ORDER) {
  KEYMAP[MOVES[id].key] = id;
  KEYMAP[MOVES[id].alt] = id;
}
const NUMPAD = { Numpad7: 'LA', Numpad8: 'HD', Numpad9: 'RA', Numpad4: 'LL', Numpad5: 'FL', Numpad6: 'RL' };

export function swipeToMove(dx, dy) {
  const ang = (Math.atan2(dy, dx) * 180) / Math.PI; // screen coords: up is -90
  if (Math.abs(ang + 90) <= 25) return 'HD';
  if (Math.abs(ang - 90) <= 25) return 'FL';
  if (dy <= 0) return dx < 0 ? 'LA' : 'RA';
  return dx < 0 ? 'LL' : 'RL';
}

export class Input {
  constructor({ pad, surface, settings, onMove, onPause, pick, onLook }) {
    this.settings = settings;
    this.onMove = onMove;
    this.enabled = true;
    // Pad: pointerdown for the lowest latency; several fingers at once are fine.
    for (const btn of pad.querySelectorAll('[data-move]')) {
      const id = btn.dataset.move;
      btn.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        if (btn.disabled) return;
        btn.classList.add('down');
        try { btn.setPointerCapture(e.pointerId); } catch { /* ignore */ }
        this.fire(id, e.timeStamp, 'pad');
      });
      const up = () => btn.classList.remove('down');
      btn.addEventListener('pointerup', up);
      btn.addEventListener('pointercancel', up);
      btn.addEventListener('lostpointercapture', up);
      // keyboard users tabbing to a pad button
      btn.addEventListener('keydown', (e) => {
        if ((e.key === 'Enter' || e.key === ' ') && !e.repeat) {
          e.preventDefault();
          e.stopPropagation();
          this.fire(id, e.timeStamp, 'pad');
        }
      });
      btn.addEventListener('contextmenu', (e) => e.preventDefault());
    }

    window.addEventListener('keydown', (e) => {
      if (e.repeat || e.ctrlKey || e.metaKey || e.altKey) return;
      const tag = (e.target && e.target.tagName) || '';
      if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;
      if (e.key === 'Escape' || e.key === 'p' || e.key === 'P') {
        onPause && onPause();
        return;
      }
      const id = NUMPAD[e.code] || KEYMAP[e.key.toLowerCase()];
      if (id) {
        e.preventDefault();
        this.fire(id, e.timeStamp, 'key');
        const btn = pad.querySelector(`[data-move="${id}"]`);
        if (btn) {
          btn.classList.add('down');
          setTimeout(() => btn.classList.remove('down'), 120);
        }
      }
    });

    // Stage: swipe or tap the monkey
    let start = null;
    surface.addEventListener('pointerdown', (e) => {
      if (e.button > 0) return;
      start = { x: e.clientX, y: e.clientY, t: e.timeStamp, id: e.pointerId };
      onLook && onLook(e.clientX, e.clientY);
    });
    surface.addEventListener('pointermove', (e) => {
      if (e.pointerType === 'mouse') onLook && onLook(e.clientX, e.clientY, true);
    });
    surface.addEventListener('pointerup', (e) => {
      if (!start || start.id !== e.pointerId) return;
      const dx = e.clientX - start.x, dy = e.clientY - start.y;
      const dist = Math.hypot(dx, dy);
      const quick = e.timeStamp - start.t < 700;
      if (dist > 36 && quick && this.settings().swipe) {
        this.fire(swipeToMove(dx, dy), e.timeStamp, 'swipe');
      } else if (dist <= 14 && this.settings().tapMonkey) {
        const id = pick(start.x, start.y);
        if (id) this.fire(id, start.t, 'tap');
      }
      start = null;
    });
    surface.addEventListener('pointercancel', () => { start = null; });
  }

  fire(id, timeStampMs, source) {
    if (!this.enabled) return;
    // event.timeStamp shares performance.now()'s clock in current browsers
    let t = timeStampMs / 1000;
    const now = performance.now() / 1000;
    if (!(t > now - 1 && t <= now + 0.01)) t = now;
    this.onMove(id, t, source);
  }
}
