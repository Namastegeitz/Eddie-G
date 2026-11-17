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

/** What the visitors say, by mood: soft (Easy) → normal → hostile → gnarly (Alien). */
const VOICE = {
  soft: {
    question: 'Who are you?',
    thought: 'You ponder in wonder…',
    known: (n) => `${n}! You came back! We missed you.`,
    named: (n) => `${n}! What a lovely name. We like you already.`,
    friend: 'A friend! We hoped you would say that.',
    decoder: 'Ooh, a decoder! Our glyphs like you.',
    unknown: 'That’s okay. Nobody knows at first.',
    gift: 'Here, a little gift. Keep going!',
    noGift: 'We already gave you a gift. Try again!',
  },
  normal: {
    question: 'Who are you?',
    thought: 'You ponder in wonder…',
    known: (n) => `${n}. We remember you.`,
    named: (n) => `${n}… we have heard your mind decoding our signal.`,
    friend: 'A friend… we have waited a long time for one.',
    decoder: 'Then you are the one who reads our glyphs.',
    unknown: 'Neither do we. That is why we search the stars.',
    gift: 'Take our gift, and keep decoding.',
    noGift: 'We have helped you once. Begin again.',
  },
  hostile: {
    question: 'WHO ARE YOU?',
    thought: 'You ponder in wonder… and dread.',
    known: (n) => `${n}. You again.`,
    named: (n) => `${n}. We will remember that name.`,
    friend: 'Friends do not fail our signal.',
    decoder: 'Then decode faster, human.',
    unknown: 'Then you are nothing to us. Yet.',
    gift: 'Take these tries. Do not waste them.',
    noGift: 'No more mercy. Begin again.',
  },
  gnarly: {
    question: 'WHO… ARE… YOU?',
    thought: 'You ponder in wonder… and terror.',
    known: (n) => `${n}… you came back to us.`,
    named: (n) => `${n}… we can taste your name.`,
    friend: 'Friend? We have no friends. Only snacks.',
    decoder: 'Decode us… before we decode you.',
    unknown: 'Then we will find out for you.',
    gift: 'More tries… so the hunt lasts longer.',
    noGift: 'The feast is over. Begin again.',
  },
};

function replyFor({ answer, name, known, voice }) {
  if (answer === 'name') {
    return known && known.toLowerCase() === name.toLowerCase() ? voice.known(name) : voice.named(name);
  }
  return voice[answer] || voice.unknown;
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
    <linearGradient id="encs-hull-soft" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#fff4fb"/><stop offset="45%" stop-color="#ffc6e4"/><stop offset="100%" stop-color="#b98ad9"/>
    </linearGradient>
    <linearGradient id="encs-hull-hostile" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#9aa0aa"/><stop offset="40%" stop-color="#4a4f5a"/><stop offset="100%" stop-color="#16181d"/>
    </linearGradient>
    <linearGradient id="encs-hull-gnarly" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#7a2a33"/><stop offset="45%" stop-color="#3d0f16"/><stop offset="100%" stop-color="#120305"/>
    </linearGradient>
    <radialGradient id="encs-skin-soft" cx="40%" cy="35%" r="70%"><stop offset="0%" stop-color="#ffe3f1"/><stop offset="100%" stop-color="#ff9cc9"/></radialGradient>
    <linearGradient id="encs-skin-hostile" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#b8c0cc"/><stop offset="100%" stop-color="#5d6676"/></linearGradient>
    <linearGradient id="encs-skin-gnarly" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#8fae5a"/><stop offset="100%" stop-color="#3c4f22"/></linearGradient>
  </defs>
  <ellipse cx="240" cy="168" rx="230" ry="110" fill="url(#encs-glow)"/>
  <path d="M152 132 Q156 46 240 40 Q324 46 328 132 Z" fill="url(#encs-dome)" stroke="#d9fbff" stroke-opacity="0.7" stroke-width="3"/>
  <g class="enc-visitor v v-normal" opacity="0.9">
    <path d="M240 64 C214 64 200 84 202 104 C204 122 222 134 240 140 C258 134 276 122 278 104 C280 84 266 64 240 64 Z" fill="url(#encs-alien)" stroke="#1d5a3a" stroke-width="3"/>
    <path d="M214 98 C220 88 234 90 236 102 C232 112 218 112 214 98 Z" fill="#06140d"/>
    <path d="M266 98 C260 88 246 90 244 102 C248 112 262 112 266 98 Z" fill="#06140d"/>
    <ellipse class="enc-eye-shine" cx="222" cy="97" rx="3.5" ry="2.5" fill="#ffffff"/>
    <ellipse class="enc-eye-shine" cx="252" cy="97" rx="3.5" ry="2.5" fill="#ffffff"/>
    <path d="M232 126 Q240 129 248 126" fill="none" stroke="#1d5a3a" stroke-width="2.5" stroke-linecap="round"/>
  </g>
  <g class="enc-visitor v v-soft">
    <circle cx="240" cy="102" r="38" fill="url(#encs-skin-soft)" stroke="#c45a8f" stroke-width="3"/>
    <circle cx="224" cy="98" r="9" fill="#3a2040"/><circle cx="256" cy="98" r="9" fill="#3a2040"/>
    <circle cx="227" cy="94" r="3.5" fill="#fff"/><circle cx="259" cy="94" r="3.5" fill="#fff"/>
    <ellipse cx="212" cy="114" rx="7" ry="4" fill="#ff7fb2" opacity="0.7"/><ellipse cx="268" cy="114" rx="7" ry="4" fill="#ff7fb2" opacity="0.7"/>
    <path d="M232 116 Q240 124 248 116" fill="none" stroke="#7a2d55" stroke-width="3" stroke-linecap="round"/>
    <path d="M226 66 Q220 52 212 50 M254 66 Q260 52 268 50" fill="none" stroke="#c45a8f" stroke-width="3" stroke-linecap="round"/>
    <circle cx="211" cy="49" r="5" fill="#ff8fc8"/><circle cx="269" cy="49" r="5" fill="#ff8fc8"/>
  </g>
  <g class="enc-visitor v v-hostile">
    <path d="M240 62 C212 62 198 84 200 106 C202 124 222 136 240 142 C258 136 278 124 280 106 C282 84 268 62 240 62 Z" fill="url(#encs-skin-hostile)" stroke="#20242c" stroke-width="3"/>
    <path d="M208 90 L234 100 L232 108 Q218 108 210 98 Z" fill="#ff2a2a"/><path d="M272 90 L246 100 L248 108 Q262 108 270 98 Z" fill="#ff2a2a"/>
    <path d="M204 84 L236 96 M276 84 L244 96" stroke="#20242c" stroke-width="5" stroke-linecap="round"/>
    <path d="M226 128 Q240 120 254 128" fill="none" stroke="#20242c" stroke-width="3" stroke-linecap="round"/>
  </g>
  <g class="enc-visitor v v-gnarly">
    <path d="M240 60 C206 60 194 86 198 110 C202 130 222 142 240 146 C258 142 278 130 282 110 C286 86 274 60 240 60 Z" fill="url(#encs-skin-gnarly)" stroke="#1a2208" stroke-width="3"/>
    <circle cx="222" cy="86" r="6" fill="#ff2a2a"/><circle cx="258" cy="86" r="6" fill="#ff2a2a"/><circle cx="240" cy="78" r="5" fill="#ff2a2a"/>
    <circle cx="212" cy="102" r="4" fill="#ffe23b"/><circle cx="268" cy="102" r="4" fill="#ffe23b"/><circle cx="240" cy="96" r="4.5" fill="#ff2a2a"/>
    <path d="M214 116 Q240 142 266 116 Q240 126 214 116 Z" fill="#1a0306"/>
    <path d="M220 118 l4 8 l4 -7 l4 9 l4 -9 l4 10 l4 -10 l4 9 l4 -9 l4 8 l4 -7" fill="#f2ead2" stroke="#1a0306" stroke-width="1.2"/>
  </g>
  <path d="M178 70 Q196 52 222 48" fill="none" stroke="#ffffff" stroke-opacity="0.75" stroke-width="7" stroke-linecap="round"/>
  <ellipse class="hull" cx="240" cy="150" rx="224" ry="46" fill="url(#encs-hull)" stroke="#0d1024" stroke-width="4"/>
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
 * @param {string} [o.tone]      'soft' | 'normal' | 'hostile' | 'gnarly' (follows the difficulty's lineup)
 * @param {(choice) => Promise<boolean>} [o.beforeChoice]  e.g. play the rewarded ad; false keeps the panel open
 */
export function playEncounter(o) {
  const reduced = settings().reduceMotion || window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  const tone = VOICE[o.tone] ? o.tone : 'normal';
  const voice = VOICE[tone];
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
    const root = h('div', { class: `encounter tone-${tone}${reduced ? ' reduced' : ''}`, role: 'dialog', 'aria-modal': 'true', 'aria-label': 'The visitors' },
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
      await speak(reply, replyFor({ answer, name, known, voice }), { fast: reduced });
      await wait(reduced ? 0 : 700);
      const offer = h('p', { class: 'enc-line enc-offer' });
      reply.after(offer);
      await speak(offer, o.canGift ? voice.gift : voice.noGift, { fast: reduced });
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
      await speak(question, voice.question, { fast: skipped || reduced });
      await t(900);
      await speak(thought, voice.thought, { fast: skipped || reduced });
      await t(700);
      if (skipped) { ship.classList.add('arrive', 'hover'); root.classList.add('beam-on', 'in'); }
      showQuestion();
    })();
  });
}
