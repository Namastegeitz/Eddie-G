/* Modal sheets + toasts. */

import { h, icon } from './dom.js';
import { sfx } from '../audio/audio.js';

const modals = [];
let host = null;
let toastHost = null;

export function initModals(modalRoot, toastRoot) {
  host = modalRoot;
  toastHost = toastRoot;
}

export function hasOpenModal() { return modals.length > 0; }

/**
 * openModal({ title, body: Node|Node[], actions: [{label, kind, onClick, icon}], dismissible, className, onClose })
 * Returns { close, el }.
 */
export function openModal(opts) {
  const { title, body, actions = [], dismissible = true, className = '', onClose, eyebrow } = opts;
  let closed = false;
  const close = (reason = 'action') => {
    if (closed) return;
    closed = true;
    const idx = modals.indexOf(entry);
    if (idx >= 0) modals.splice(idx, 1);
    overlay.classList.add('closing');
    setTimeout(() => overlay.remove(), 180);
    onClose?.(reason);
  };

  const actionEls = actions.map((a) =>
    h('button', {
      class: `btn ${a.kind ? `btn-${a.kind}` : 'btn-ghost'}`,
      type: 'button',
      'data-autofocus': a.autofocus ? true : null,
      onclick: async () => {
        sfx.tap();
        const keepOpen = await a.onClick?.(close);
        if (keepOpen !== true) close('action');
      },
    }, a.icon ? icon(a.icon) : null, h('span', {}, a.label))
  );

  const card = h('div', { class: `modal-card ${className}`, role: 'dialog', 'aria-modal': 'true', 'aria-label': title || 'Dialog' },
    dismissible ? h('button', { class: 'modal-x icon-btn', type: 'button', 'aria-label': 'Close', onclick: () => close('dismiss') }, icon('close')) : null,
    eyebrow ? h('div', { class: 'modal-eyebrow' }, eyebrow) : null,
    title ? h('h2', { class: 'modal-title' }, title) : null,
    h('div', { class: 'modal-body' }, body),
    actionEls.length ? h('div', { class: 'modal-actions' }, actionEls) : null,
  );
  const overlay = h('div', {
    class: 'modal-overlay',
    onclick: (e) => { if (e.target === overlay && dismissible) close('dismiss'); },
  }, card);

  const entry = { close, dismissible: dismissible ? true : false, el: overlay };
  modals.push(entry);
  host.appendChild(overlay);
  requestAnimationFrame(() => {
    const f = card.querySelector('[data-autofocus]') || card.querySelector('.modal-actions .btn');
    f?.focus({ preventScroll: true });
  });
  return { close, el: overlay, card };
}

/** Close the top modal if it can be dismissed. Returns true if one was open. */
export function closeTopModal() {
  const top = modals[modals.length - 1];
  if (!top) return false;
  if (top.dismissible) top.close('dismiss');
  return true;
}

export function closeAllModals() { [...modals].forEach((m) => m.close('dismiss')); }

export function confirmModal({ title, message, confirmLabel = 'OK', cancelLabel = 'Cancel', danger = false }) {
  return new Promise((resolve) => {
    let answered = false;
    openModal({
      title,
      body: h('p', { class: 'modal-text' }, message),
      actions: [
        { label: cancelLabel, kind: 'ghost', onClick: () => { answered = true; resolve(false); } },
        { label: confirmLabel, kind: danger ? 'danger' : 'primary', autofocus: true, onClick: () => { answered = true; resolve(true); } },
      ],
      onClose: () => { if (!answered) resolve(false); },
    });
  });
}

/** Small transient message. kind: 'info' | 'success' | 'error' | 'achievement' */
export function toast(message, { kind = 'info', icon: ico = null, duration = 2600 } = {}) {
  if (!toastHost) return;
  const el = h('div', { class: `toast toast-${kind}`, role: 'status' },
    ico ? h('span', { class: 'toast-icon' }, ico) : null,
    h('span', { class: 'toast-text' }, message));
  toastHost.appendChild(el);
  requestAnimationFrame(() => el.classList.add('show'));
  setTimeout(() => {
    el.classList.remove('show');
    setTimeout(() => el.remove(), 300);
  }, duration);
}
