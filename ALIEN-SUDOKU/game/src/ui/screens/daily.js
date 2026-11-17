/* Daily Transmission: today's card, streak, month calendar. */
import { h, icon, clear } from '../dom.js';
import { dailyRecord, currentStreak, getProfile, loadSavedGame } from '../../core/profile.js';
import { todayStr, parseDateStr, dateStr, prettyDate, formatTime, addDays } from '../../core/time.js';
import { sfx } from '../../audio/audio.js';
import { toast } from '../modal.js';
import { topbar } from './campaign.js';
import { confirmAbandon } from './menu.js';
import { DAILY_DIFFICULTY, weekdayOf } from '../../engine/pool.js';

const DIFF_LABEL = { easy: 'Easy', medium: 'Medium', hard: 'Hard', alien: 'Alien' };
const PLAYABLE_DAYS_BACK = 60;

export const diffForDate = (ds) => DAILY_DIFFICULTY[weekdayOf(ds)];

async function playDate(nav, date) {
  const saved = loadSavedGame();
  if (saved && saved.status === 'playing' && saved.mode === 'daily' && saved.date === date) { nav.go('play', { resume: true }); return; }
  if (!(await confirmAbandon())) return;
  nav.go('play', { mode: 'daily', date });
}

export const dailyScreen = {
  id: 'daily',
  banner: true,
  bg: 'space/galaxy-spiral.webp',
  create(params, nav) {
    const today = todayStr();
    const earliest = addDays(today, -PLAYABLE_DAYS_BACK);
    const todayRec = dailyRecord(today);
    const p = getProfile();
    let view = parseDateStr(today);
    view.setDate(1);

    const calHost = h('div', { class: 'calendar' });

    function renderCalendar() {
      clear(calHost);
      const y = view.getFullYear();
      const m = view.getMonth();
      const first = new Date(y, m, 1, 12);
      const daysInMonth = new Date(y, m + 1, 0, 12).getDate();
      const monthLabel = first.toLocaleDateString(undefined, { month: 'long', year: 'numeric' });
      const prevAllowed = dateStr(new Date(y, m, 0, 12)) >= earliest;
      const nextAllowed = dateStr(new Date(y, m + 1, 1, 12)) <= today;
      calHost.appendChild(h('div', { class: 'cal-head' },
        h('button', { class: 'icon-btn', type: 'button', 'aria-label': 'Previous month', disabled: !prevAllowed, onclick: () => { view = new Date(y, m - 1, 1, 12); renderCalendar(); } }, icon('back')),
        h('span', { class: 'cal-month' }, monthLabel),
        h('button', { class: 'icon-btn flip', type: 'button', 'aria-label': 'Next month', disabled: !nextAllowed, onclick: () => { view = new Date(y, m + 1, 1, 12); renderCalendar(); } }, icon('back'))));
      const grid = h('div', { class: 'cal-grid' });
      // Weekday initials, starting Sunday.
      for (let d = 0; d < 7; d++) {
        grid.appendChild(h('span', { class: 'cal-wd' }, new Date(2024, 0, 7 + d).toLocaleDateString(undefined, { weekday: 'narrow' })));
      }
      for (let k = 0; k < first.getDay(); k++) grid.appendChild(h('span', { class: 'cal-pad' }));
      for (let d = 1; d <= daysInMonth; d++) {
        const ds = dateStr(new Date(y, m, d, 12));
        const rec = dailyRecord(ds);
        const future = ds > today;
        const tooOld = ds < earliest;
        const cls = ['cal-day'];
        if (rec) cls.push('done');
        if (ds === today) cls.push('today');
        if (future || tooOld) cls.push('disabled');
        grid.appendChild(h('button', {
          class: cls.join(' '),
          type: 'button',
          disabled: future || tooOld,
          'aria-label': `${prettyDate(ds, { weekday: 'long', month: 'long', day: 'numeric' })}${rec ? `, decoded in ${formatTime(rec.ms)}` : ''}`,
          onclick: () => { sfx.tap(); playDate(nav, ds); },
        }, h('span', {}, String(d)), rec ? h('span', { class: 'cal-check' }, icon('check')) : h('span', { class: `cal-dot diff-${diffForDate(ds)}` })));
      }
      calHost.appendChild(grid);
    }
    renderCalendar();

    const diff = diffForDate(today);
    const el = h('div', { class: 'page' },
      topbar('Daily Transmission', prettyDate(today, { weekday: 'long', month: 'long', day: 'numeric' }), nav),
      h('div', { class: 'page-body' },
        h('div', { class: 'daily-card' },
          h('div', { class: 'daily-card-top' },
            h('span', { class: `diff-chip diff-${diff}` }, DIFF_LABEL[diff]),
            h('span', { class: 'streak' }, icon('fire'), ` ${currentStreak()} day streak`, h('small', {}, ` · best ${p.daily.bestStreak}`))),
          h('p', { class: 'daily-text' }, todayRec
            ? `Decoded in ${formatTime(todayRec.ms)}. A new signal arrives tomorrow.`
            : 'Everyone receives the same signal today. Decode it to keep your streak alive.'),
          h('button', { class: 'btn btn-primary btn-wide', type: 'button', 'data-autofocus': true, onclick: () => { sfx.tap(); playDate(nav, today); } },
            icon('play'), h('span', {}, todayRec ? 'Play again' : "Play today's signal"))),
        calHost,
        h('p', { class: 'page-note' }, 'Difficulty follows the week: Monday Easy, Tuesday–Wednesday Medium, Thursday–Friday Hard, Saturday Alien, Sunday Hard. Past days in the last two months can be replayed; only today counts toward your streak.')));
    return { el };
  },
};
