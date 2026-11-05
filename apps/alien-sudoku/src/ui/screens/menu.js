/* Main menu. */
import { h, icon } from '../dom.js';
import {
  loadSavedGame, clearSavedGame, totalStars, currentStreak, dailyRecord, settings, setSetting, getProfile, playerName,
} from '../../core/profile.js';
import { MAX_STARS } from '../../data/sectors.js';
import { ACHIEVEMENTS } from '../../data/achievements.js';
import { todayStr, formatTime } from '../../core/time.js';
import { openModal, confirmModal } from '../modal.js';
import { sfx } from '../../audio/audio.js';
import { appVersion, isElectron, isNative } from '../../platform/native.js';
import { sessionTitle } from './play.js';
import { GameSession } from '../../game/session.js';
import { SYMBOL_SETS } from '../../data/symbols.js';
import { THEMES, DIFFICULTY_LINEUP } from '../../data/themes.js';

const DIFFS = [
  { key: 'easy', label: 'Easy', clues: '≈38 clues', blurb: 'Warm up. Every move can be found by looking.' },
  { key: 'medium', label: 'Medium', clues: '≈32 clues', blurb: 'A steady signal with a few tricky spots.' },
  { key: 'hard', label: 'Hard', clues: '≈26 clues', blurb: 'Pairs and pointing glyphs. Notes help.' },
  { key: 'alien', label: 'Alien', clues: '≈22 clues', blurb: 'Advanced patterns. For fluent decoders.' },
];
/** Who you meet at each difficulty, from super soft to gnarly. */
const DIFF_MOOD = { easy: 'Cuddly and harmless', medium: 'Playful troublemakers', hard: 'They mean business', alien: 'Fangs. Eyes. Slime.' };

/** Ask before replacing an in-progress game. Resolves true to continue. */
export async function confirmAbandon() {
  const snap = loadSavedGame();
  if (!snap || snap.status !== 'playing') return true;
  const s = GameSession.fromSnapshot(snap);
  if (!s.hasProgress) return true;
  const t = sessionTitle(s);
  const ok = await confirmModal({
    title: 'Start a new puzzle?',
    message: `Your ${t.eyebrow} game (${t.title}, ${formatTime(s.elapsedMs)}) will be discarded.`,
    confirmLabel: 'Start new',
    danger: true,
  });
  if (ok) clearSavedGame();
  return ok;
}

export function pickDifficulty({ mode, nav }) {
  const best = getProfile().stats.byDiff;
  const close = openModal({
    eyebrow: mode === 'zen' ? 'Zen mode · no lives, no clock' : 'Quick play',
    title: 'Signal strength',
    className: 'diff-modal',
    body: h('div', { class: 'diff-list' }, DIFFS.map((d) => {
      const lineupKey = settings().difficultyAliens !== false ? DIFFICULTY_LINEUP[d.key] : settings().symbolSet;
      const t = THEMES[lineupKey];
      const set = SYMBOL_SETS[lineupKey];
      return h('button', {
        class: `diff-option diff-${d.key}${settings().quickDifficulty === d.key ? ' current' : ''}`,
        type: 'button',
        style: {
          '--opt-c1': `rgb(${t.rgb.c1})`,
          '--opt-dim': t.textDim,
          color: t.text,
          borderColor: `rgb(${t.rgb.c1})`,
          background: `radial-gradient(circle at 85% 50%, rgba(${t.rgb.c1}, 0.22), transparent 55%), linear-gradient(135deg, ${t.cellUser}, ${t.bg})`,
        },
        onclick: async () => {
          sfx.tap();
          close.close();
          if (!(await confirmAbandon())) return;
          setSetting('quickDifficulty', d.key);
          nav.go('play', { mode, difficulty: d.key });
        },
      },
      h('span', { class: 'diff-name', style: { fontFamily: t.font } }, d.label, h('small', {}, d.clues)),
      h('span', { class: 'diff-blurb' }, d.blurb),
      h('span', { class: 'diff-lineup' }, `${t.name} · ${settings().difficultyAliens !== false ? DIFF_MOOD[d.key] : 'your lineup'}`),
      h('span', { class: 'diff-glyphs', html: [0, 1, 2].map((k) => set.svgs[(t.hero - 1 + k * 3) % 9]).join('') }),
      mode !== 'zen' && best[d.key]?.bestMs != null ? h('span', { class: 'diff-best' }, `Best ${formatTime(best[d.key].bestMs)}`) : null);
    })),
  });
}

export const menuScreen = {
  id: 'menu',
  banner: true,
  bg: () => (THEMES[settings().symbolSet] || THEMES.encounters).backdrop,
  create(params, nav) {
    const saved = loadSavedGame();
    const resumable = saved && saved.status !== 'won' ? GameSession.fromSnapshot(saved) : null;
    const today = todayStr();
    const dailyDone = !!dailyRecord(today);
    const streak = currentStreak();
    const stars = totalStars();
    const p = getProfile();
    const achCount = Object.keys(p.achievements).length;

    const big = (cls, ico, label, sub, onclick, extra = {}) =>
      h('button', { class: `menu-btn ${cls}`, type: 'button', onclick: () => { sfx.tap(); onclick(); }, ...extra },
        h('span', { class: 'menu-btn-ico' }, icon(ico)),
        h('span', { class: 'menu-btn-text' }, h('span', { class: 'menu-btn-label' }, label), sub ? h('small', {}, sub) : null),
        icon('back', 'chev'));

    const continueBtn = resumable ? (() => {
      const t = sessionTitle(resumable);
      return big('menu-continue', 'play', 'Continue', `${t.eyebrow} · ${t.title} · ${formatTime(resumable.elapsedMs)}`, () => nav.go('play', { resume: true }), { 'data-autofocus': true });
    })() : null;

    const lineupKey = settings().symbolSet;
    const lineup = SYMBOL_SETS[lineupKey] || SYMBOL_SETS.encounters;
    const theme = THEMES[lineupKey] || THEMES.encounters;
    const heroIdx = theme.hero - 1;
    const el = h('div', { class: 'menu-layout' },
      h('header', { class: 'menu-hero' },
        h('div', { class: 'hero-stage', 'aria-hidden': 'true' },
          h('div', { class: 'hero-glyph hero-side hero-left', html: lineup.svgs[(heroIdx + 3) % 9] }),
          h('div', { class: 'hero-glyph hero-main', html: lineup.svgs[heroIdx] }),
          h('div', { class: 'hero-glyph hero-side hero-right', html: lineup.svgs[(heroIdx + 6) % 9] })),
        h('h1', { class: 'game-title' }, h('span', { class: 'title-glow' }, 'ALIEN'), ' ', h('span', { class: 'title-accent' }, 'SUDOKU')),
        h('p', { class: 'subtitle' }, 'Decode the hieroglyphs of the lost UFO archive'),
        playerName() ? h('p', { class: 'greeting' }, `The visitors remember you, ${playerName()}.`) : null,
        h('button', { class: 'lineup-chip', type: 'button', onclick: () => { sfx.tap(); nav.go('settings'); } },
          h('span', { class: 'lineup-dots' }, lineup.colors.map((c) => h('i', { style: { background: c } }))),
          h('span', {}, `Lineup: ${theme.name}`), icon('back', 'chev'))),
      h('nav', { class: 'menu-list', 'aria-label': 'Main menu' },
        continueBtn,
        big('menu-campaign', 'map', 'Campaign', `${stars} / ${MAX_STARS} stars · 6 sectors`, () => nav.go('campaign'), resumable ? {} : { 'data-autofocus': true }),
        big('menu-daily', 'calendar', 'Daily Transmission',
          dailyDone ? `Today's signal decoded ✓${streak ? ` · 🔥 ${streak}` : ''}` : `New signal today${streak ? ` · 🔥 ${streak}-day streak` : ''}`,
          () => nav.go('daily')),
        big('menu-quick', 'bolt', 'Quick Play', 'Pick a difficulty, play instantly', () => pickDifficulty({ mode: 'quick', nav })),
        big('menu-zen', 'zen', 'Zen Mode', 'No lives, no clock, unlimited hints', () => pickDifficulty({ mode: 'zen', nav }))),
      h('div', { class: 'menu-icons' },
        iconTile('trophy', 'Achievements', `${achCount}/${ACHIEVEMENTS.length}`, () => nav.go('achievements')),
        iconTile('stats', 'Stats', null, () => nav.go('stats')),
        iconTile('settings', 'Settings', null, () => nav.go('settings')),
        iconTile('help', 'How to play', settings().seenTutorial ? null : 'New', () => nav.go('howto'))),
      h('footer', { class: 'menu-footer' },
        h('span', {}, 'Transmission origin: ▽◊ Sector 9 ◊▽'),
        h('span', { class: 'version' }, `v${appVersion()}${isElectron ? ' · desktop' : isNative ? '' : ' · web'}`)));

    return { el };
  },
};

function iconTile(ico, label, badge, onclick) {
  return h('button', { class: 'icon-tile', type: 'button', onclick: () => { sfx.tap(); onclick(); } },
    icon(ico), h('span', {}, label), badge ? h('span', { class: 'tile-badge' }, badge) : null);
}

const UFO_SVG = `<svg viewBox="0 0 120 70" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
  <path class="ufo-beam" d="M44 46 L30 70 L90 70 L76 46 Z" fill="currentColor" stroke="none" opacity="0.14"/>
  <path d="M38 30 q22 -30 44 0" />
  <ellipse cx="60" cy="36" rx="46" ry="11" />
  <circle class="ufo-light" cx="36" cy="36" r="2.4" fill="currentColor"/>
  <circle class="ufo-light" cx="60" cy="38" r="2.4" fill="currentColor"/>
  <circle class="ufo-light" cx="84" cy="36" r="2.4" fill="currentColor"/>
</svg>`;
