/* Campaign: the star chart (six sectors) and each sector's route map
   (nine transmissions on a path across the sector's own artwork). */
import { h, icon } from '../dom.js';
import { SECTORS, LEVELS_PER_SECTOR, MAX_STARS } from '../../data/sectors.js';
import { SYMBOL_SETS } from '../../data/symbols.js';
import {
  isSectorUnlocked, isLevelUnlocked, levelRecord, sectorStars, totalStars, nextCampaignLevel, loadSavedGame,
} from '../../core/profile.js';
import { formatTime } from '../../core/time.js';
import { campaignDifficulty } from '../../engine/pool.js';
import { settings } from '../../core/profile.js';
import { sfx } from '../../audio/audio.js';
import { toast } from '../modal.js';
import { confirmAbandon } from './menu.js';
import { assetUrl, backdropVariant } from '../background.js';
import { lineupForLevel, sectorLineup } from '../glyphs.js';
import { THEMES } from '../../data/themes.js';

const DIFF_LABEL = { easy: 'Easy', medium: 'Medium', hard: 'Hard', alien: 'Alien' };


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

/** How many of a sector's nine transmissions are decoded. */
function sectorDone(sector) {
  let n = 0;
  for (let l = 0; l < LEVELS_PER_SECTOR; l++) if (levelRecord(sector, l)) n++;
  return n;
}

/** Nine small marks, one per transmission, in that level's alien color: full when decoded. */
function levelPips(sector) {
  const pips = [];
  for (let l = 0; l < LEVELS_PER_SECTOR; l++) {
    const rec = levelRecord(sector, l);
    const open = isLevelUnlocked(sector, l);
    pips.push(h('i', {
      class: `pip${rec ? ` done s${rec.stars}` : open ? ' open' : ''}`,
      style: { '--pc': `rgb(${THEMES[lineupForLevel(sector, l)].rgb.c1})` },
    }));
  }
  return h('span', { class: 'sector-pips', 'aria-hidden': 'true' }, pips);
}

/* The route snakes across the map: 1-2-3, down, 6-5-4 (drawn right to left), down, 7-8-9. */
const routeCell = (l) => {
  const row = Math.floor(l / 3);
  return { row, col: row % 2 ? 2 - (l % 3) : l % 3 };
};
const SVG_NS = 'http://www.w3.org/2000/svg';
/** One gently curved leg of the route between two stops, in a 300x300 chart stretched over
    the grid. Each stop's disc sits 29 units below the top of its row (see .level-node in CSS). */
function routeLeg(a, b, on) {
  const ax = 50 + a.col * 100, ay = 29 + a.row * 100, bx = 50 + b.col * 100, by = 29 + b.row * 100;
  const bend = a.row === b.row ? [0, a.row % 2 ? 9 : -9] : [a.col ? 10 : -10, 0];
  const path = document.createElementNS(SVG_NS, 'path');
  path.setAttribute('d', `M${ax} ${ay} Q${(ax + bx) / 2 + bend[0]} ${(ay + by) / 2 + bend[1]} ${bx} ${by}`);
  path.setAttribute('class', `route-leg${on ? ' on' : ''}`);
  return path;
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
          const lineup = sectorLineup(s.id);
          const set = SYMBOL_SETS[lineup];
          const accent = `rgb(${THEMES[lineup].rgb.c1})`;
          const done = sectorDone(s.id);
          const nextUp = unlocked && isSectorUnlocked(s.id + 1) && s.id + 1 < SECTORS.length;
          return h('button', {
            class: `sector-card${unlocked ? '' : ' locked'}${nextUp ? ' linked' : ''}${done === LEVELS_PER_SECTOR ? ' cleared' : ''}`,
            type: 'button',
            style: { '--accent': accent },
            'aria-label': `${s.name}${unlocked ? `, ${done} of ${LEVELS_PER_SECTOR} decoded, ${stars} of 27 stars` : ', locked'}`,
            onclick: () => {
              if (!unlocked) { sfx.reject(); toast(`Finish ${SECTORS[s.id - 1].name} to unlock ${s.name}.`); return; }
              sfx.tap();
              nav.go('sector', { sector: s.id });
            },
          },
          h('span', { class: 'sector-art', 'aria-hidden': 'true', style: { backgroundImage: `url("${assetUrl(s.bg, 'card')}")` } }),
          h('span', { class: 'sector-num' }, String(s.id + 1).padStart(2, '0')),
          h('span', { class: 'sector-info' },
            h('span', { class: 'sector-name' }, s.name),
            h('small', {}, `${s.range} · ${set.name}`),
            levelPips(s.id),
            h('span', { class: 'sector-stars' }, icon('star'), ` ${stars} / ${LEVELS_PER_SECTOR * 3}`,
              h('span', { class: 'sector-count' }, unlocked ? `${done} / ${LEVELS_PER_SECTOR} decoded` : `Finish ${SECTORS[s.id - 1].name}`))),
          unlocked ? h('span', { class: 'sector-glyphs', html: set.svgs.slice(0, 3).join('') }) : icon('lock', 'sector-lock'));
        }))));
    return { el };
  },
};

export const sectorScreen = {
  id: 'sector',
  banner: true,
  bg: (p) => SECTORS[p.sector]?.bg,
  theme: (p) => sectorLineup(p.sector),
  create(params, nav) {
    const s = SECTORS[params.sector];
    const set = SYMBOL_SETS[sectorLineup(s.id)];
    const accent = `rgb(${THEMES[sectorLineup(s.id)].rgb.c1})`;
    const nodes = [];
    const route = document.createElementNS(SVG_NS, 'svg');
    route.setAttribute('class', 'route');
    route.setAttribute('viewBox', '0 0 300 300');
    route.setAttribute('preserveAspectRatio', 'none');
    route.setAttribute('aria-hidden', 'true');
    for (let l = 0; l < LEVELS_PER_SECTOR; l++) {
      const rec = levelRecord(s.id, l);
      const unlocked = isLevelUnlocked(s.id, l);
      const isNext = unlocked && !rec;
      const at = routeCell(l);
      if (l + 1 < LEVELS_PER_SECTOR) route.appendChild(routeLeg(at, routeCell(l + 1), !!rec));
      nodes.push(h('button', {
        class: `level-node${rec ? ' done' : ''}${unlocked ? '' : ' locked'}${isNext ? ' next' : ''}`,
        type: 'button',
        style: { '--accent': `rgb(${THEMES[lineupForLevel(s.id, l)].rgb.c1})`, gridColumn: String(at.col + 1), gridRow: String(at.row + 1) },
        title: `${DIFF_LABEL[campaignDifficulty(s.id, l)]} · ${SYMBOL_SETS[lineupForLevel(s.id, l)].name}`,
        'data-autofocus': isNext ? true : null,
        'aria-label': `Transmission ${l + 1}${rec ? `, ${rec.stars} stars, best ${formatTime(rec.bestMs)}` : unlocked ? '' : ', locked'}`,
        onclick: () => {
          if (!unlocked) { sfx.reject(); toast('Decode the previous transmission first.'); return; }
          sfx.tap();
          startLevel(nav, s.id, l);
        },
      },
      h('span', { class: 'level-disc' },
        h('span', { class: 'level-glyph', html: unlocked ? SYMBOL_SETS[lineupForLevel(s.id, l)].svgs[l] : '' }, unlocked ? null : icon('lock')),
        h('span', { class: 'level-num' }, String(l + 1))),
      h('span', { class: 'level-tag' },
        h('small', { class: 'level-diff' }, DIFF_LABEL[campaignDifficulty(s.id, l)]),
        h('span', { class: 'level-stars' }, [1, 2, 3].map((n) => h('span', { class: `mini-star${rec && rec.stars >= n ? ' on' : ''}` }, icon('star')))),
        rec ? h('small', { class: 'level-time' }, formatTime(rec.bestMs)) : null)));
    }
    const done = sectorDone(s.id);
    const stars = sectorStars(s.id);
    const el = h('div', { class: 'page', style: { '--accent': accent } },
      topbar(s.name, `Sector ${s.id + 1} · ${s.range}`, nav),
      h('div', { class: 'page-body' },
        h('p', { class: 'sector-blurb' }, s.blurb),
        h('div', { class: 'sector-progress' },
          h('span', { class: 'sector-stars' }, icon('star'), ` ${stars} / ${LEVELS_PER_SECTOR * 3}`),
          h('span', { class: 'progress-bar', role: 'img', 'aria-label': `${done} of ${LEVELS_PER_SECTOR} transmissions decoded` },
            h('i', { style: { width: `${(done / LEVELS_PER_SECTOR) * 100}%` } })),
          h('span', { class: 'sector-count' }, `${done} / ${LEVELS_PER_SECTOR} decoded`)),
        h('div', { class: 'level-map' },
          h('span', { class: 'level-map-art', 'aria-hidden': 'true', style: { backgroundImage: `url("${assetUrl(s.bg, backdropVariant(window.innerWidth, window.innerHeight))}")` } }),
          h('span', { class: 'level-map-chart', 'aria-hidden': 'true' }),
          h('span', { class: 'level-map-label', 'aria-hidden': 'true' }, `Sector ${String(s.id + 1).padStart(2, '0')} chart`),
          h('div', { class: 'level-grid' }, route, nodes)),
        h('p', { class: 'page-note' }, `${settings().difficultyAliens !== false ? 'Each transmission brings the aliens of its difficulty, from the Alien Creatures to the Gnarly Horde.' : `Symbols: ${set.name}.`} Stars: 3 for a clean solve, 2 for one slip (mistake or hint), 1 otherwise.`)));
    return { el };
  },
};
