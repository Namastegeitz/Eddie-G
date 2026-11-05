/* ============================================================
   The visitors. When the player runs out of tries, an alien ship
   rises from the distant horizon, flies up in front of them and
   asks, telepathically: "Who are you?" The player answers (their
   name or one of three replies), the visitors reply, and offer a
   gift of more tries or a fresh start.

   playEncounter(opts) resolves to { choice, name, answer } where
   choice is 'gift' | 'retry' | 'new' | 'menu'.
   ============================================================ */

import { h } from './dom.js';
import { encounterSfx, duckMusic } from '../audio/audio.js';
import { haptic } from '../platform/native.js';
import { setBannerVisible } from '../platform/ads.js';
import { settings } from '../core/profile.js';

let open = false;
export const isEncounterOpen = () => open;

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const QUICK_ANSWERS = [
  { id: 'friend', label: 'A friend from Earth' },
  { id: 'decoder', label: 'A decoder of your signal' },
  { id: 'unknown', label: 'I… don’t know' },
];

function replyFor({ answer, name, known }) {
  if (answer === 'name') {
    return known && known.toLowerCase() === name.toLowerCase()
      ? `${name}. We remember you.`
      : `${name}… we have heard your mind decoding our signal.`;
  }
  return {
    friend: 'A friend… we have waited a long time for one.',
    decoder: 'Then you are the one who reads our glyphs.',
    unknown: 'Neither do we. That is why we search the stars.',
  }[answer] || 'We see you.';
}

/** The ship: hull, rim lights, glass dome with a visitor looking out. */
const SHIP_SVG = `<svg class="enc-ship-svg" viewBox="0 0 480 300" aria-hidden="true">
  <defs>
    <radialGradient id="encs-glow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#9ff6ff" stop-opacity="0.75"/><stop offset="60%" stop-color="#5ff0ff" stop-opacity="0.18"/><stop offset="100%" stop-color="#5ff0ff" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="encs-hull" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#e9f1ff"/><stop offset="35%" stop-color="#a9b8d6"/><stop offset="60%" stop-color="#5e6c90"/><stop offset="100%" stop-color="#2a3150"/>
    </linearGradient>
    <linearGradient id="encs-band" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#3b4468"/><stop offset="100%" stop-color="#171b33"/>
    </linearGradient>
    <linearGradient id="encs-under" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#3a4266"/><stop offset="100%" stop-color="#11142a"/>
    </linearGradient>
    <radialGradient id="encs-dome" cx="40%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#f4ffff" stop-opacity="0.95"/><stop offset="35%" stop-color="#9df3ff" stop-opacity="0.65"/><stop offset="100%" stop-color="#2a8fb8" stop-opacity="0.55"/>
    </radialGradient>
    <radialGradient id="encs-core" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#ffffff"/><stop offset="45%" stop-color="#b9fbff"/><stop offset="100%" stop-color="#39d8ff" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="encs-alien" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#9dffb8"/><stop offset="100%" stop-color="#3fb36f"/>
    </linearGradient>
  </defs>
  <ellipse cx="240" cy="168" rx="230" ry="110" fill="url(#encs-glow)"/>
  <path d="M152 132 Q156 46 240 40 Q324 46 328 132 Z" fill="url(#encs-dome)" stroke="#d9fbff" stroke-opacity="0.7" stroke-width="3"/>
  <g class="enc-visitor" opacity="0.9">
    <path d="M240 64 C214 64 200 84 202 104 C204 122 222 134 240 140 C258 134 276 122 278 104 C280 84 266 64 240 64 Z" fill="url(#encs-alien)" stroke="#1d5a3a" stroke-width="3"/>
    <path d="M214 98 C220 88 234 90 236 102 C232 112 218 112 214 98 Z" fill="#06140d"/>
    <path d="M266 98 C260 88 246 90 244 102 C248 112 262 112 266 98 Z" fill="#06140d"/>
    <ellipse class="enc-eye-shine" cx="222" cy="97" rx="3.5" ry="2.5" fill="#ffffff"/>
    <ellipse class="enc-eye-shine" cx="252" cy="97" rx="3.5" ry="2.5" fill="#ffffff"/>
    <path d="M232 126 Q240 129 248 126" fill="none" stroke="#1d5a3a" stroke-width="2.5" stroke-linecap="round"/>
  </g>
  <path d="M178 70 Q196 52 222 48" fill="none" stroke="#ffffff" stroke-opacity="0.75" stroke-width="7" stroke-linecap="round"/>
  <ellipse cx="240" cy="150" rx="224" ry="46" fill="url(#encs-hull)" stroke="#0d1024" stroke-width="4"/>
  <path d="M28 150 Q240 214 452 150 Q440 180 240 196 Q40 180 28 150 Z" fill="url(#encs-under)" stroke="#0d1024" stroke-width="3"/>
  <ellipse cx="240" cy="144" rx="196" ry="22" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="3"/>
  <path d="M60 136 Q240 104 420 136" fill="none" stroke="#ffffff" stroke-opacity="0.55" stroke-width="5" stroke-linecap="round"/>
  <path d="M30 152 Q240 206 450 152" fill="none" stroke="url(#encs-band)" stroke-width="12"/>
  <g class="enc-lights">
    <circle cx="70" cy="166" r="8" fill="#ff5cf6"/><circle cx="112" cy="176" r="8" fill="#5ff0ff"/>
    <circle cx="156" cy="183" r="8" fill="#39ff9c"/><circle cx="198" cy="187" r="8" fill="#ffd36b"/>
    <circle cx="240" cy="188" r="8" fill="#ff5cf6"/><circle cx="282" cy="187" r="8" fill="#5ff0ff"/>
    <circle cx="324" cy="183" r="8" fill="#39ff9c"/><circle cx="368" cy="176" r="8" fill="#ffd36b"/>
    <circle cx="410" cy="166" r="8" fill="#ff5cf6"/>
  </g>
  <ellipse class="enc-core" cx="240" cy="200" rx="46" ry="12" fill="url(#encs-core)"/>
</svg>`;

/** Distant hills and the glow of the horizon. */
const HORIZON_SVG = `<svg viewBox="0 0 1200 220" preserveAspectRatio="none" aria-hidden="true">
  <defs><linearGradient id="ench-land" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#0b0718"/><stop offset="100%" stop-color="#020106"/></linearGradient></defs>
  <path d="M0 120 C120 90 200 118 300 104 C420 86 470 60 560 74 C640 86 700 112 790 100 C900 84 960 54 1060 70 C1120 80 1170 96 1200 92 L1200 220 L0 220 Z" fill="url(#ench-land)"/>
  <path d="M0 120 C120 90 200 118 300 104 C420 86 470 60 560 74 C640 86 700 112 790 100 C900 84 960 54 1060 70 C1120 80 1170 96 1200 92" fill="none" stroke="#7fe9ff" stroke-opacity="0.35" stroke-width="1.5" vector-effect="non-scaling-stroke"/>
  <path d="M0 150 C160 128 260 150 380 140 C520 128 600 148 720 142 C860 134 980 150 1200 136 L1200 220 L0 220 Z" fill="#020106"/>
</svg>`;

/** Write a telepathic line one letter at a time. */
async function speak(el, text, { fast = false } = {}) {
  el.textContent = '';
  el.classList.add('speaking');
  const letters = [...text];
  // Letters are grouped into words so lines only wrap between words.
  let i = 0;
  text.split(' ').forEach((word, w) => {
    if (w > 0) { el.appendChild(document.createTextNode(' ')); i++; }
    const wordEl = h('span', { class: 'tw' });
    for (const ch of word) {
      wordEl.appendChild(h('span', { class: 'tl', style: { animationDelay: `${fast ? 0 : i * 55}ms, ${i * 120}ms` } }, ch));
      i++;
    }
    el.appendChild(wordEl);
  });
  el.setAttribute('aria-label', text);
  if (!fast) {
    for (let i = 0; i < letters.length; i += 3) {
      encounterSfx.letter();
      await wait(165);
    }
  }
}

/**
 * @param {object} o
 * @param {string} o.knownName   name the player gave before ('' if none)
 * @param {boolean} o.canGift    the visitors can still give extra tries
 * @param {number} o.giftTries   how many tries the gift restores
 * @param {boolean} o.giftNeedsAd  gift is a rewarded video (mobile)
 * @param {boolean} o.allowNew   offer "New signal"
 * @param {(choice) => Promise<boolean>} [o.beforeChoice]  e.g. play the rewarded ad; false keeps the panel open
 */
export function playEncounter(o) {
  const reduced = settings().reduceMotion || window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  open = true;
  setBannerVisible(false);
  duckMusic(true);
  haptic('heavy');

  return new Promise((resolve) => {
    const ship = h('div', { class: 'enc-ship' }, h('div', { class: 'enc-beam' }), h('div', { class: 'enc-ship-body', html: SHIP_SVG }));
    const question = h('p', { class: 'enc-line enc-question', role: 'heading', 'aria-level': '2' });
    const thought = h('p', { class: 'enc-line enc-thought' });
    const reply = h('p', { class: 'enc-line enc-reply' });
    const panel = h('div', { class: 'enc-panel', hidden: true });
    const skip = h('button', { class: 'enc-skip', type: 'button' }, 'Skip');
    const root = h('div', { class: `encounter${reduced ? ' reduced' : ''}`, role: 'dialog', 'aria-modal': 'true', 'aria-label': 'The visitors' },
      h('div', { class: 'enc-sky' }, h('div', { class: 'enc-stars enc-stars-a' }), h('div', { class: 'enc-stars enc-stars-b' })),
      h('div', { class: 'enc-horizon', html: HORIZON_SVG }),
      h('div', { class: 'enc-horizon-glow' }),
      h('div', { class: 'enc-stage' }, ship),
      h('div', { class: 'enc-voice', 'aria-live': 'polite' }, question, thought, reply),
      panel,
      skip);
    document.body.appendChild(root);

    let stopHum = () => {};
    let skipped = false;
    let finished = false;

    const onKey = (e) => {
      if (e.key === 'Escape') { e.stopImmediatePropagation(); e.preventDefault(); skipped = true; }
    };
    window.addEventListener('keydown', onKey, true);

    function finish(result) {
      if (finished) return;
      finished = true;
      window.removeEventListener('keydown', onKey, true);
      ship.classList.remove('arrive', 'hover');
      ship.classList.add('leave');
      encounterSfx.depart();
      stopHum(1.2);
      duckMusic(false);
      root.classList.add('closing');
      setTimeout(() => {
        root.remove();
        open = false;
        setBannerVisible(true);
        resolve(result);
      }, reduced ? 250 : 1300);
    }

    function showOffers({ name, answer }) {
      panel.replaceChildren();
      const btn = (label, cls, onClick, extra) => h('button', { class: `btn ${cls}`, type: 'button', onclick: onClick, ...extra }, label);
      const actions = [];
      if (o.canGift) {
        actions.push(btn(`Accept the gift · +${o.giftTries} ${o.giftTries === 1 ? 'try' : 'tries'}${o.giftNeedsAd ? ' (video)' : ''}`, 'btn-primary', async () => {
          if (o.beforeChoice && !(await o.beforeChoice('gift'))) return;
          encounterSfx.gift();
          root.classList.add('gifted');
          finish({ choice: 'gift', name, answer });
        }, { 'data-autofocus': true }));
      }
      actions.push(btn('Begin this signal again', o.canGift ? 'btn-ghost' : 'btn-primary', () => finish({ choice: 'retry', name, answer })));
      if (o.allowNew) actions.push(btn('Receive a new signal', 'btn-ghost', () => finish({ choice: 'new', name, answer })));
      actions.push(btn('Return to the menu', 'btn-ghost', () => finish({ choice: 'menu', name, answer })));
      panel.append(h('div', { class: 'enc-actions' }, actions));
      panel.hidden = false;
      panel.querySelector('.btn')?.focus({ preventScroll: true });
    }

    async function answered({ name = '', answer }) {
      panel.hidden = true;
      thought.classList.add('fade');
      encounterSfx.telepathy();
      haptic('medium');
      const known = o.knownName || '';
      await speak(reply, replyFor({ answer, name, known }), { fast: reduced });
      await wait(reduced ? 0 : 700);
      const offer = h('p', { class: 'enc-line enc-offer' });
      reply.after(offer);
      await speak(offer, o.canGift ? 'Take our gift, and keep decoding.' : 'We have helped you once. Begin again.', { fast: reduced });
      await wait(reduced ? 0 : 400);
      showOffers({ name, answer });
    }

    function showQuestion() {
      panel.replaceChildren();
      const input = h('input', {
        class: 'enc-input', type: 'text', maxlength: '24', autocomplete: 'nickname', enterkeyhint: 'send',
        placeholder: 'Tell them your name', 'aria-label': 'Your name', value: o.knownName || '',
      });
      const send = () => {
        const name = input.value.replace(/\s+/g, ' ').trim();
        if (!name) { input.focus(); input.classList.add('nudge'); setTimeout(() => input.classList.remove('nudge'), 400); return; }
        answered({ name, answer: 'name' });
      };
      input.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); send(); } });
      panel.append(
        h('div', { class: 'enc-name-row' }, input, h('button', { class: 'btn btn-primary', type: 'button', onclick: send }, 'Answer')),
        h('div', { class: 'enc-quick' }, QUICK_ANSWERS.map((a) =>
          h('button', { class: 'enc-chip', type: 'button', onclick: () => answered({ answer: a.id }) }, a.label))));
      panel.hidden = false;
      skip.hidden = true;
      setTimeout(() => input.focus({ preventScroll: true }), 50);
    }

    // ---------- the scene ----------
    skip.addEventListener('click', () => { skipped = true; });
    (async () => {
      const t = (ms) => (skipped || reduced ? Promise.resolve() : wait(ms));
      requestAnimationFrame(() => root.classList.add('in'));
      await t(500);
      stopHum = encounterSfx.hum(3.6);
      ship.classList.add('arrive');            // a light on the horizon rises and comes closer
      await t(3900);
      ship.classList.add('hover');
      root.classList.add('beam-on');
      haptic('heavy');
      await t(500);
      encounterSfx.telepathy();
      await speak(question, 'Who are you?', { fast: skipped || reduced });
      await t(900);
      await speak(thought, 'You ponder in wonder…', { fast: skipped || reduced });
      await t(700);
      if (skipped) { ship.classList.add('arrive', 'hover'); root.classList.add('beam-on', 'in'); }
      showQuestion();
    })();
  });
}
