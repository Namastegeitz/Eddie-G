/* Campaign: sector list and the 9-level sector map. */
import { h, icon } from '../dom.js';
import { SECTORS, LEVELS_PER_SECTOR, MAX_STARS } from '../../data/sectors.js';
import { SYMBOL_SETS } from '../../data/symbols.js';
import {
  isSectorUnlocked, isLevelUnlocked, levelRecord, sectorStars, totalStars, nextCampaignLevel, loadSavedGame,
} from '../../core/profile.js';
import { formatTime } from '../../core/time.js';
import { sfx } from '../../audio/audio.js';
import { toast } from '../modal.js';
import { confirmAbandon } from './menu.js';
import { assetUrl } from '../background.js';


function topbar(title, eyebrow, nav) {
  return h('header', { class: 'topbar' },
    h('button', { class: 'icon-btn', type: 'button', 'aria-label': 'Back', onclick: () => nav.back() }, icon('back')),
    h('div', { class: 'topbar-title' }, eyebrow ? h('div', { class: 'eyebrow' }, eyebrow) : null, h('h1', { class: 'topbar-h1' }, title)),
    h('span', { class: 'icon-btn-spacer' }));
}
export { topbar };

async function startLevel(nav, sector, level) {
  const saved = loadSavedGame();
  if (saved && saved.status === 'playing' && saved.mode === 'campaign' && saved.sector === sector && saved.level === level) {
    nav.go('play', { resume: true });
    return;
  }
  if (!(await confirmAbandon())) return;
  nav.go('play', { mode: 'campaign', sector, level });
}

export const campaignScreen = {
  id: 'campaign',
  banner: true,
  bg: 'space/star-cluster.webp',
  create(params, nav) {
    const next = nextCampaignLevel();
    const el = h('div', { class: 'page' },
      topbar('Campaign', `${totalStars()} / ${MAX_STARS} stars`, nav),
      h('div', { class: 'page-body' },
        next ? h('button', {
          class: 'btn btn-primary btn-wide', type: 'button', 'data-autofocus': true,
          onclick: () => { sfx.tap(); startLevel(nav, next.sector, next.level); },
        }, icon('play'), h('span', {}, `Continue: ${SECTORS[next.sector].name} · ${next.level + 1}`)) : h('p', { class: 'page-note' }, 'Every sector cleared. Replay any transmission to earn missing stars.'),
        h('div', { class: 'sector-list' }, SECTORS.map((s) => {
          const unlocked = isSectorUnlocked(s.id);
          const stars = sectorStars(s.id);
          const set = SYMBOL_SETS[s.symbolSet];
          return h('button', {
            class: `sector-card${unlocked ? '' : ' locked'}`,
            type: 'button',
            style: { '--accent': s.accent, backgroundImage: `linear-gradient(90deg, rgba(5,1,15,0.92) 35%, rgba(5,1,15,0.35)), url("${assetUrl(s.bg)}")` },
            'aria-label': `${s.name}${unlocked ? `, ${stars} of 27 stars` : ', locked'}`,
            onclick: () => {
              if (!unlocked) { sfx.reject(); toast(`Finish ${SECTORS[s.id - 1].name} to unlock ${s.name}.`); return; }
              sfx.tap();
              nav.go('sector', { sector: s.id });
            },
          },
          h('span', { class: 'sector-num' }, String(s.id + 1).padStart(2, '0')),
          h('span', { class: 'sector-info' },
            h('span', { class: 'sector-name' }, s.name),
            h('small', {}, `${s.range} · ${set.name}`),
            h('span', { class: 'sector-stars' }, icon('star'), ` ${stars} / ${LEVELS_PER_SECTOR * 3}`)),
          unlocked ? h('span', { class: 'sector-glyphs', html: set.svgs.slice(0, 3).join('') }) : icon('lock', 'sector-lock'));
        }))));
    return { el };
  },
};

export const sectorScreen = {
  id: 'sector',
  banner: true,
  bg: (p) => SECTORS[p.sector]?.bg,
  create(params, nav) {
    const s = SECTORS[params.sector];
    const set = SYMBOL_SETS[s.symbolSet];
    const nodes = [];
    for (let l = 0; l < LEVELS_PER_SECTOR; l++) {
      const rec = levelRecord(s.id, l);
      const unlocked = isLevelUnlocked(s.id, l);
      const isNext = unlocked && !rec;
      nodes.push(h('button', {
        class: `level-node${rec ? ' done' : ''}${unlocked ? '' : ' locked'}${isNext ? ' next' : ''}`,
        type: 'button',
        style: { '--accent': s.accent },
        'data-autofocus': isNext ? true : null,
        'aria-label': `Transmission ${l + 1}${rec ? `, ${rec.stars} stars, best ${formatTime(rec.bestMs)}` : unlocked ? '' : ', locked'}`,
        onclick: () => {
          if (!unlocked) { sfx.reject(); toast('Decode the previous transmission first.'); return; }
          sfx.tap();
          startLevel(nav, s.id, l);
        },
      },
      h('span', { class: 'level-glyph', html: unlocked ? set.svgs[l] : '' }, unlocked ? null : icon('lock')),
      h('span', { class: 'level-num' }, String(l + 1)),
      h('span', { class: 'level-stars' }, [1, 2, 3].map((n) => h('span', { class: `mini-star${rec && rec.stars >= n ? ' on' : ''}` }, icon('star')))),
      rec ? h('small', { class: 'level-time' }, formatTime(rec.bestMs)) : null));
    }
    const el = h('div', { class: 'page', style: { '--accent': s.accent } },
      topbar(s.name, `Sector ${s.id + 1} · ${s.range}`, nav),
      h('div', { class: 'page-body' },
        h('p', { class: 'sector-blurb' }, s.blurb),
        h('div', { class: 'level-grid' }, nodes),
        h('p', { class: 'page-note' }, `Symbols: ${set.name}. Stars: 3 for a clean solve, 2 for one slip (mistake or hint), 1 otherwise.`)));
    return { el };
  },
};
