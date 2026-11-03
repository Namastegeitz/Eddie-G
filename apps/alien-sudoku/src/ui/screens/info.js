/* Stats, Achievements and How-to-play screens. */
import { h, icon, clear } from '../dom.js';
import { getProfile, totalStars, currentStreak, DIFFS } from '../../core/profile.js';
import { ACHIEVEMENTS } from '../../data/achievements.js';
import { MAX_STARS } from '../../data/sectors.js';
import { SYMBOL_SETS } from '../../data/symbols.js';
import { formatTime, formatDuration } from '../../core/time.js';
import { topbar } from './campaign.js';
import { sfx } from '../../audio/audio.js';
import { settings } from '../../core/profile.js';

const DIFF_LABEL = { easy: 'Easy', medium: 'Medium', hard: 'Hard', alien: 'Alien' };

// ---------------- Stats ----------------
export const statsScreen = {
  id: 'stats',
  banner: true,
  bg: 'space/pillars-green.webp',
  create(params, nav) {
    const p = getProfile();
    let tab = params.tab || 'overview';
    const body = h('div', { class: 'stats-body' });
    const tabs = h('div', { class: 'tabs', role: 'tablist' });

    const tabDefs = [['overview', 'Overview'], ...DIFFS.map((d) => [d, DIFF_LABEL[d]])];
    function renderTabs() {
      clear(tabs);
      for (const [k, label] of tabDefs) {
        tabs.appendChild(h('button', {
          class: `tab${tab === k ? ' active' : ''}`, type: 'button', role: 'tab', 'aria-selected': String(tab === k),
          onclick: () => { sfx.tap(); tab = k; renderTabs(); renderBody(); },
        }, label));
      }
    }

    function renderBody() {
      clear(body);
      if (tab === 'overview') {
        const t = p.stats.totals;
        const wins = DIFFS.reduce((n, d) => n + p.stats.byDiff[d].won, 0) + t.zenWins;
        const played = DIFFS.reduce((n, d) => n + p.stats.byDiff[d].played, 0) + t.zenPlayed;
        body.append(statGrid([
          ['Puzzles won', wins],
          ['Puzzles played', played],
          ['Time decoding', formatDuration(t.playMs)],
          ['Campaign stars', `${totalStars()} / ${MAX_STARS}`],
          ['Daily streak', `${currentStreak()} (best ${p.daily.bestStreak})`],
          ['Dailies decoded', Object.keys(p.daily.completed).length],
          ['Achievements', `${Object.keys(p.achievements).length} / ${ACHIEVEMENTS.length}`],
          ['Zen puzzles', t.zenWins],
          ['Notes pencilled', t.notes],
          ['Hints used', t.hints],
          ['Glyphs rejected', t.mistakes],
          ['Symbol sets', `${p.unlockedSets.length} / ${Object.keys(SYMBOL_SETS).length}`],
        ]));
      } else {
        const s = p.stats.byDiff[tab];
        const rate = s.played ? Math.round((s.won / s.played) * 100) : 0;
        body.append(
          h('div', { class: 'winrate', style: { '--rate': `${rate}%` } },
            h('span', { class: 'winrate-num' }, `${rate}%`), h('small', {}, 'win rate')),
          statGrid([
            ['Played', s.played],
            ['Won', s.won],
            ['Perfect wins', s.perfect],
            ['Best time', formatTime(s.bestMs)],
            ['Average time', s.won ? formatTime(s.totalWinMs / s.won) : '—'],
            ['Win streak', `${s.streak} (best ${s.bestStreak})`],
          ]));
      }
    }
    renderTabs();
    renderBody();

    const el = h('div', { class: 'page' }, topbar('Stats', 'Your decoding record', nav), h('div', { class: 'page-body' }, tabs, body));
    return { el };
  },
};

function statGrid(rows) {
  return h('div', { class: 'stat-grid' }, rows.map(([label, value]) =>
    h('div', { class: 'stat-cell' }, h('small', {}, label), h('b', {}, String(value)))));
}

// ---------------- Achievements ----------------
export const achievementsScreen = {
  id: 'achievements',
  banner: true,
  bg: 'space/nebula-pink.webp',
  create(params, nav) {
    const p = getProfile();
    const got = ACHIEVEMENTS.filter((a) => p.achievements[a.id]).length;
    const el = h('div', { class: 'page' },
      topbar('Achievements', `${got} of ${ACHIEVEMENTS.length} unlocked`, nav),
      h('div', { class: 'page-body' },
        h('div', { class: 'ach-progress' }, h('span', { style: { width: `${(got / ACHIEVEMENTS.length) * 100}%` } })),
        h('div', { class: 'ach-grid' }, ACHIEVEMENTS.map((a) => {
          const when = p.achievements[a.id];
          return h('div', { class: `ach-card${when ? ' got' : ''}` },
            h('span', { class: 'ach-ico' }, when ? a.icon : icon('lock')),
            h('span', { class: 'ach-text' },
              h('b', {}, a.name),
              h('small', {}, a.desc),
              when ? h('small', { class: 'ach-date' }, new Date(when).toLocaleDateString()) : null));
        }))));
    return { el };
  },
};

// ---------------- How to play ----------------
export const howtoScreen = {
  id: 'howto',
  banner: true,
  bg: 'space/moon-planet.webp',
  create(params, nav) {
    const set = SYMBOL_SETS[settings().symbolSet] || SYMBOL_SETS.alien;
    const g = (v) => h('span', { class: 'inline-glyph', html: set.svgs[v - 1] });

    const miniBox = h('div', { class: 'mini-box' }, [1, 2, 3, 4, 5, 6, 7, 8, 9].map((v) =>
      h('span', { class: v === 5 ? 'empty' : '', html: v === 5 ? '?' : set.svgs[v - 1] })));

    const sections = [
      ['The rule', [
        h('p', {}, 'The board is 9 rows, 9 columns and nine 3×3 boxes. Fill every empty cell so that each of the 9 glyphs appears exactly once in every row, every column and every box.'),
        h('div', { class: 'howto-figure' }, miniBox, h('p', {}, 'This box already has eight glyphs, so the empty cell must be ', g(5), ' — the only one missing.')),
      ]],
      ['Placing glyphs', [
        h('ul', {},
          h('li', {}, 'Tap a cell, then tap a glyph in the palette. Numbers on the palette show how many of each glyph are still missing.'),
          h('li', {}, 'Prefer to pick the glyph first? Turn on “Glyph-first input” in Settings or the pause menu, then tap cells to fill them.'),
          h('li', {}, 'A wrong glyph is rejected and costs a life. Three lives per puzzle (Zen mode has no limit).'),
          h('li', {}, 'Tapping a placed glyph lights up every copy of it and draws a constellation between them.'),
        ),
      ]],
      ['Tools', [
        h('ul', {},
          h('li', {}, h('b', {}, 'Notes: '), 'pencil small candidate glyphs into a cell. Placing a glyph clears it from notes in the same row, column and box.'),
          h('li', {}, h('b', {}, 'Undo: '), 'step back through your moves (mistakes still count).'),
          h('li', {}, h('b', {}, 'Hint: '), 'reveals a cell and tells you why it works. Select an empty cell first to reveal that one. Hints lower your star rating.'),
          h('li', {}, h('b', {}, 'Pause menu: '), 'fill in all notes automatically, clear notes or restart.'),
        ),
      ]],
      ['Modes', [
        h('ul', {},
          h('li', {}, h('b', {}, 'Campaign: '), '6 sectors × 9 transmissions of rising difficulty. Earn up to 3 stars each and unlock new symbol sets.'),
          h('li', {}, h('b', {}, 'Daily Transmission: '), 'one puzzle a day, the same for everyone. Keep your streak going.'),
          h('li', {}, h('b', {}, 'Quick Play: '), 'a fresh puzzle at the difficulty you choose.'),
          h('li', {}, h('b', {}, 'Zen: '), 'no lives, no clock, unlimited hints.'),
        ),
      ]],
      ['Keyboard (computer)', [
        h('div', { class: 'keys' },
          key('Arrows / WASD', 'move'), key('1–9', 'place glyph'), key('Backspace / 0', 'erase'),
          key('N', 'notes on/off'), key('U / Ctrl+Z', 'undo'), key('H', 'hint'), key('P / Esc', 'pause')),
      ]],
    ];

    const el = h('div', { class: 'page' },
      topbar('How to play', 'Decoder training', nav),
      h('div', { class: 'page-body howto' }, sections.map(([title, content]) =>
        h('section', { class: 'howto-section' }, h('h2', {}, title), content)),
      h('button', { class: 'btn btn-primary btn-wide', type: 'button', onclick: () => nav.back() }, icon('check'), h('span', {}, 'Got it'))));
    return { el };
  },
};

function key(k, what) {
  return h('div', { class: 'key-row' }, h('kbd', {}, k), h('span', {}, what));
}
