/* ============================================================
   Alien Duel setup: pick a rival, tune it, pick a difficulty,
   and race it on the same puzzle. Choices are remembered.
   ============================================================ */

import { h, icon } from '../dom.js';
import { settings, setSetting, duelStats } from '../../core/profile.js';
import {
  RIVALS, RIVAL_ORDER, DUEL_DEFAULTS, SPEEDS, ACCURACIES, STYLES, HEAD_STARTS, LOOK_SETS,
  resolveRival, describeRival, estimateRivalMs,
} from '../../game/rival.js';
import { SYMBOL_SETS } from '../../data/symbols.js';
import { THEMES } from '../../data/themes.js';
import { formatTime } from '../../core/time.js';
import { sfx } from '../../audio/audio.js';
import { topbar } from './campaign.js';
import { confirmAbandon } from './menu.js';
import { rivalAvatar } from '../rival-panel.js';

const DIFFS = [['easy', 'Easy'], ['medium', 'Medium'], ['hard', 'Hard'], ['alien', 'Alien']];
const LOOK_LABEL = { softies: 'Soft', creatures: 'Creature', hostile: 'Hostile', gnarly: 'Gnarly' };

/** Duel settings as stored, with every field present. */
export function duelSettings() { return { ...DUEL_DEFAULTS, ...(settings().duel || {}) }; }
function saveDuel(patch) { setSetting('duel', { ...duelSettings(), ...patch }); }

export const duelScreen = {
  id: 'duel',
  banner: true,
  bg: 'space/star-cluster.webp',
  theme: () => {
    const r = resolveRival(duelSettings());
    return r.look.set;
  },
  create(params, nav) {
    const body = h('div', { class: 'page-body duel-setup' });
    const el = h('div', { class: 'page' }, topbar('Alien Duel', 'Race a rival on the same puzzle', nav), body);
    let lookOpen = false;

    function render() {
      const s = duelSettings();
      const r = resolveRival(s);
      const base = RIVALS[r.base];
      const stats = duelStats();
      const t = THEMES[r.look.set];
      el.style.setProperty('--rival-c', `rgb(${t.rgb.c1})`);

      // ----- Rival cards -----
      const cards = h('div', { class: 'rival-cards', role: 'radiogroup', 'aria-label': 'Rival' }, RIVAL_ORDER.map((id) => {
        const b = RIVALS[id];
        const bt = THEMES[b.look.set];
        const rec = stats.byRival?.[id];
        const on = r.base === id;
        return h('button', {
          class: `rival-card${on ? ' on' : ''}`, type: 'button', role: 'radio', 'aria-checked': String(on),
          style: { '--card-c': `rgb(${bt.rgb.c1})`, fontFamily: bt.font },
          onclick: () => {
            sfx.select();
            // A new rival starts from its own name, look and strengths.
            saveDuel({ rival: id, name: '', look: null, speed: null, accuracy: null, style: null });
            render();
          },
        },
        h('span', { class: 'rival-card-ico', html: rivalAvatar(b.look) }),
        h('b', {}, b.name),
        h('small', {}, b.tagline),
        h('span', { class: 'rival-card-rec' }, rec?.played ? `You ${rec.won} · ${b.name.split(' ').pop()} ${rec.played - rec.won}` : 'Not faced yet'));
      }));

      // ----- Customize -----
      const nameInput = h('input', {
        class: 'text-input', id: 'duel-name', type: 'text', maxlength: 16, placeholder: base.name, value: s.name || '',
        autocomplete: 'off', spellcheck: 'false',
        onchange: (e) => { saveDuel({ name: e.target.value }); render(); },
      });

      const lookSet = s.look?.set || r.look.set;
      const looks = h('div', { class: 'look-picker', hidden: !lookOpen },
        h('div', { class: 'look-tabs', role: 'tablist' }, LOOK_SETS.map((k) => h('button', {
          class: `look-tab${lookSet === k ? ' on' : ''}`, type: 'button', role: 'tab', 'aria-selected': String(lookSet === k),
          onclick: () => { saveDuel({ look: { set: k, n: k === r.look.set ? r.look.n : 1 } }); render(); },
        }, LOOK_LABEL[k]))),
        h('div', { class: 'look-grid' }, SYMBOL_SETS[lookSet].svgs.map((svg, k) => {
          const on = r.look.set === lookSet && r.look.n === k + 1;
          return h('button', {
            class: `look-opt${on ? ' on' : ''}`, type: 'button', 'aria-pressed': String(on),
            'aria-label': SYMBOL_SETS[lookSet].names[k], title: SYMBOL_SETS[lookSet].names[k], html: svg,
            onclick: () => { sfx.select(); saveDuel({ look: { set: lookSet, n: k + 1 } }); render(); },
          });
        })));

      const scale = (key, label, list, value, sub) => h('div', { class: 'set-row scale-row' },
        h('span', { class: 'set-text' }, h('label', { for: `duel-${key}` }, label), h('small', {}, sub)),
        h('span', { class: 'scale' },
          h('input', {
            class: 'slider', id: `duel-${key}`, type: 'range', min: 1, max: 5, step: 1, value,
            'aria-valuetext': list[value - 1].label,
            oninput: (e) => { e.target.nextSibling.textContent = list[Number(e.target.value) - 1].label; },
            onchange: (e) => { sfx.select(); saveDuel({ [key]: Number(e.target.value) }); render(); },
          }),
          h('b', { class: 'scale-val' }, list[value - 1].label)));

      const toggle = (key, label, sub) => h('label', { class: 'set-row' },
        h('span', { class: 'set-text' }, h('span', {}, label), sub ? h('small', {}, sub) : null),
        h('input', { class: 'switch', type: 'checkbox', role: 'switch', checked: !!s[key], onchange: (e) => { sfx.tap(); saveDuel({ [key]: e.target.checked }); render(); } }));

      const styleSel = h('select', { class: 'select', id: 'duel-style', onchange: (e) => { saveDuel({ style: e.target.value }); render(); } },
        Object.entries(STYLES).map(([k, st]) => h('option', { value: k, selected: r.style === k }, st.label)));
      const headSel = h('select', { class: 'select', id: 'duel-head', onchange: (e) => { saveDuel({ headStart: Number(e.target.value) }); render(); } },
        HEAD_STARTS.map((sec) => h('option', { value: String(sec), selected: r.headStart === sec }, sec ? `${sec} seconds` : 'None')));

      const customize = h('section', { class: 'set-group' }, h('h2', {}, `Customize ${r.name}`), h('div', { class: 'set-rows' },
        h('div', { class: 'set-row' },
          h('span', { class: 'set-text' }, h('label', { for: 'duel-name' }, 'Name'), h('small', {}, 'What your rival is called in this duel')),
          nameInput),
        h('div', { class: 'set-row look-row' },
          h('span', { class: 'set-text' }, h('span', {}, 'Look'), h('small', {}, `${SYMBOL_SETS[r.look.set].names[r.look.n - 1]} · ${THEMES[r.look.set].name}`)),
          h('button', {
            class: 'look-current', type: 'button', 'aria-expanded': String(lookOpen), 'aria-label': 'Change look',
            onclick: () => { lookOpen = !lookOpen; render(); },
          }, h('span', { html: rivalAvatar(r.look) }), h('small', {}, lookOpen ? 'Done' : 'Change'))),
        looks,
        scale('speed', 'Speed', SPEEDS, r.speed, 'How fast your rival places glyphs'),
        scale('accuracy', 'Accuracy', ACCURACIES, r.accuracy, 'Fewer fumbles: wrong glyphs cost your rival time'),
        h('label', { class: 'set-row' }, h('span', { class: 'set-text' }, h('span', {}, 'Play style'), h('small', {}, STYLES[r.style].blurb)), styleSel),
        h('label', { class: 'set-row' }, h('span', { class: 'set-text' }, h('span', {}, 'Your head start'), h('small', {}, 'Your rival waits this long before its first glyph')), headSel),
        toggle('adaptive', 'Keeps pace with you', 'Speeds up when you lead, slows down when you fall behind'),
        toggle('showGlyphs', "Show the rival's glyphs", 'Off: you only see which cells it has solved'),
        toggle('chatter', 'Rival talks', 'Taunts and cheers in a speech bubble'),
        r.tuned || s.name || s.look ? h('button', {
          class: 'btn btn-ghost btn-wide', type: 'button',
          onclick: () => { sfx.tap(); saveDuel({ name: '', look: null, speed: null, accuracy: null, style: null, headStart: 0, adaptive: false }); render(); },
        }, icon('restart'), h('span', {}, `Reset to ${base.name}`)) : null));

      // ----- Difficulty + start -----
      const diffRow = h('div', { class: 'duel-diffs', role: 'radiogroup', 'aria-label': 'Puzzle difficulty' }, DIFFS.map(([k, label]) => h('button', {
        class: `duel-diff diff-${k}${s.difficulty === k ? ' on' : ''}`, type: 'button', role: 'radio', 'aria-checked': String(s.difficulty === k),
        onclick: () => { sfx.select(); saveDuel({ difficulty: k }); render(); },
      }, label)));

      const est = estimateRivalMs(r, s.difficulty);
      const summary = h('div', { class: 'duel-summary' },
        h('span', { class: 'duel-face', html: rivalAvatar(r.look) }),
        h('span', { class: 'duel-summary-text' },
          h('b', {}, `You vs ${r.name}`),
          h('small', {}, describeRival(r)),
          h('small', {}, `${r.name} finishes a ${s.difficulty === 'alien' ? 'Alien' : DIFFS.find(([k]) => k === s.difficulty)[1]} puzzle in about ${formatTime(est)}${r.adaptive ? ', and keeps pace with you' : ''}.`),
          r.id === 'custom' ? h('small', { class: 'duel-note' }, `Made easier than usual: wins count as a custom rival, not as ${base.name}.`) : null));

      const start = h('button', {
        class: 'btn btn-primary btn-wide duel-start', type: 'button', 'data-autofocus': true,
        onclick: async () => {
          sfx.tap();
          if (!(await confirmAbandon())) return;
          nav.go('play', { mode: 'duel' });
        },
      }, icon('duel'), h('span', {}, `Start duel vs ${r.name}`));

      const record = stats.played ? h('p', { class: 'page-note' }, `Duels: ${stats.won} won of ${stats.played} · best streak ${stats.bestStreak}`) : null;

      body.replaceChildren(...[
        h('p', { class: 'page-note' }, 'You and your rival get the same puzzle on separate boards. First to fill every cell wins.'),
        h('section', { class: 'set-group' }, h('h2', {}, 'Choose your rival'), cards),
        h('section', { class: 'set-group' }, h('h2', {}, 'Puzzle'), diffRow),
        customize,
        summary,
        start,
        record,
      ].filter(Boolean));
    }
    render();
    return { el };
  },
};
