/* ============================================================
   Screen router: a simple stack. Each screen module exports
   { id, create(params, nav) -> { el, onShow?, onHide?, onBack?, destroy? },
     banner?: boolean, bg?: string | (params) => string, keepAlive?: boolean }
   keepAlive screens are kept in memory (not rebuilt) while another
   screen is pushed on top of them, e.g. Play -> Settings -> back.
   ============================================================ */

import { clear } from './dom.js';
import { setBannerVisible } from '../platform/ads.js';
import { setBackground } from './background.js';
import { closeTopModal, hasOpenModal, closeAllModals } from './modal.js';

const registry = new Map();
const stack = []; // [{ def, params, inst }]
let root = null;
const nav = { go, back, replace, reset };

export function registerScreen(def) { registry.set(def.id, def); }
export function initRouter(el) { root = el; }
export function current() { return stack[stack.length - 1] || null; }
export function currentId() { return current()?.def.id || null; }

function show(entry, dir) {
  const { def, params } = entry;
  if (!entry.inst) entry.inst = def.create(params || {}, nav);
  const el = entry.inst.el;
  el.classList.add('screen', `screen-${def.id}`);
  el.classList.remove('enter', 'enter-back');
  void el.offsetWidth;
  if (dir) el.classList.add(dir === 'back' ? 'enter-back' : 'enter');
  clear(root).appendChild(el);
  setBannerVisible(def.banner !== false);
  const bg = typeof def.bg === 'function' ? def.bg(params || {}, entry.inst) : def.bg;
  if (bg !== undefined) setBackground(bg);
  entry.inst.onShow?.();
  requestAnimationFrame(() => {
    const target = el.querySelector('[data-autofocus]') || el.querySelector('h1, h2');
    if (target && !target.hasAttribute('tabindex')) target.setAttribute('tabindex', '-1');
    target?.focus({ preventScroll: true });
  });
}

/** Hide the top screen. Destroy it unless it is keepAlive and staying in the stack. */
function hideTop(leaving) {
  const top = current();
  if (!top?.inst) return;
  top.inst.onHide?.();
  if (leaving || !top.def.keepAlive) {
    top.inst.destroy?.();
    top.inst = null;
  }
}

export function go(id, params = {}) {
  const def = registry.get(id);
  if (!def) throw new Error(`Unknown screen ${id}`);
  closeAllModals();
  hideTop(false);
  const entry = { def, params };
  stack.push(entry);
  show(entry, 'forward');
}

export function replace(id, params = {}) {
  const def = registry.get(id);
  closeAllModals();
  hideTop(true);
  stack.pop();
  const entry = { def, params };
  stack.push(entry);
  show(entry, 'forward');
}

/** Clear the stack and show `id` as the root. */
export function reset(id = 'menu', params = {}) {
  closeAllModals();
  while (stack.length) { hideTop(true); stack.pop(); }
  const entry = { def: registry.get(id), params };
  stack.push(entry);
  show(entry, 'back');
}

/** Back one screen. Returns false when already at the root. */
export function back() {
  if (stack.length <= 1) return false;
  closeAllModals();
  hideTop(true);
  stack.pop();
  show(current(), 'back');
  return true;
}

/** Hardware back / Escape: modal first, then the screen's own handler, then pop. */
export function handleBack() {
  if (hasOpenModal()) { closeTopModal(); return true; }
  const top = current();
  if (top?.inst?.onBack && top.inst.onBack() === true) return true;
  return back();
}
