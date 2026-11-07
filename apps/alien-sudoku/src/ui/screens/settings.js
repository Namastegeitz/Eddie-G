/* Settings screen. */
import { h, icon } from '../dom.js';
import { settings, setSetting, isSetUnlocked, resetEverything } from '../../core/profile.js';
import { SYMBOL_SETS, SYMBOL_SET_ORDER } from '../../data/symbols.js';
import { SECTORS } from '../../data/sectors.js';
import { THEMES } from '../../data/themes.js';
import { topbar } from './campaign.js';
import { confirmModal, toast } from '../modal.js';
import { sfx, music, TIER_SONG, onMusicChange, audioStatus, testSound } from '../../audio/audio.js';

const TIERS = [['easy', 'Easy'], ['medium', 'Medium'], ['hard', 'Hard'], ['alien', 'Alien']];
import { appVersion, isNative, isElectron } from '../../platform/native.js';
import { privacyOptionsAvailable, showPrivacyOptions, adsSupported } from '../../platform/ads.js';

function unlockHint(key) {
  const reach = SECTORS.find((s) => s.unlocksSet === key);
  if (reach) return `Reach ${reach.name}`;
  const finish = SECTORS.find((s) => s.rewardSet === key);
  return finish ? `Finish ${finish.name}` : 'Locked';
}

export const settingsScreen = {
  id: 'settings',
  keepSong: true,
  banner: true,
  bg: null,
  create(params, nav) {
    const s = settings();

    const toggle = (key, label, sub) => h('label', { class: 'set-row' },
      h('span', { class: 'set-text' }, h('span', {}, label), sub ? h('small', {}, sub) : null),
      h('input', { class: 'switch', type: 'checkbox', role: 'switch', checked: !!s[key], onchange: (e) => { setSetting(key, e.target.checked); sfx.tap(); } }));

    const slider = (key, label) => h('label', { class: 'set-row' },
      h('span', { class: 'set-text' }, h('span', {}, label)),
      h('input', { class: 'slider', type: 'range', min: 0, max: 100, step: 5, value: Math.round((s[key] ?? 0.8) * 100),
        oninput: (e) => setSetting(key, Number(e.target.value) / 100), onchange: () => sfx.place() }));

    const setGrid = h('div', { class: 'set-grid', role: 'radiogroup', 'aria-label': 'Symbol set' });
    function renderSets() {
      setGrid.replaceChildren(...SYMBOL_SET_ORDER.map((k) => {
        const set = SYMBOL_SETS[k];
        const t = THEMES[k];
        const unlocked = isSetUnlocked(k);
        const active = settings().symbolSet === k;
        return h('button', {
          class: `set-card${active ? ' active' : ''}${unlocked ? '' : ' locked'}`,
          style: {
            '--card-c1': `rgb(${t.rgb.c1})`,
            background: `radial-gradient(circle at 30% 20%, rgba(${t.rgb.c2}, 0.28), transparent 60%), linear-gradient(160deg, ${t.cellUser}, ${t.bg})`,
            fontFamily: t.font,
            color: t.text,
            '--card-dim': t.textDim,
          },
          type: 'button', role: 'radio', 'aria-checked': String(active),
          'aria-label': `${set.name}${unlocked ? '' : `, locked: ${unlockHint(k)}`}`,
          onclick: () => {
            if (!unlocked) { sfx.reject(); toast(`${set.name}: ${unlockHint(k)} in the campaign to unlock.`); return; }
            setSetting('symbolSet', k);
            sfx.select();
            renderSets();
          },
        },
        h('span', { class: 'set-preview', html: set.svgs.join('') }),
        h('span', { class: 'set-name', style: { color: `rgb(${t.rgb.c1})` } }, unlocked ? set.name : h('span', {}, icon('lock'), ` ${set.name}`)),
        h('small', {}, unlocked ? t.tagline : unlockHint(k)));
      }));
    }
    renderSets();

    const triesSel = h('select', { class: 'select', 'aria-label': 'Tries per puzzle', onchange: (e) => setSetting('tries', Number(e.target.value)) },
      [[25, '25 · Explorer'], [10, '10 · Relaxed'], [5, '5 · Focused'], [3, '3 · Classic']].map(([v, label]) =>
        h('option', { value: String(v), selected: (s.tries || 25) === v }, label)));

    // Theme songs: tap one to hear it right here.
    const musicToggle = toggle('music', 'Theme music', 'A theme song for each difficulty');
    const songList = h('div', { class: 'song-list', role: 'group', 'aria-label': 'Theme songs' });
    function renderSongs(playing = music.current) {
      songList.replaceChildren(...TIERS.map(([tier, label]) => {
        const id = TIER_SONG[tier];
        const on = playing === id;
        return h('button', {
          class: `song-row${on ? ' on' : ''}`, type: 'button', 'aria-pressed': String(on),
          'aria-label': `${label} theme: ${music.songName(id)}${on ? ', playing' : ', tap to play'}`,
          onclick: () => {
            if (!settings().music) {
              setSetting('music', true);
              const box = musicToggle.querySelector('input');
              if (box) box.checked = true;
            }
            music.play(id);
          },
        },
        h('span', { class: 'song-eq', 'aria-hidden': 'true' }, h('i'), h('i'), h('i')),
        h('span', { class: 'song-text' }, h('small', {}, label), h('span', {}, music.songName(id))),
        h('span', { class: 'song-state' }, on ? 'Playing' : 'Play'));
      }));
    }
    renderSongs();
    const offMusic = onMusicChange((id) => renderSongs(id));

    const soundStatus = h('p', { class: 'set-note', 'aria-live': 'polite' });
    const soundCheck = h('div', { class: 'sound-check' },
      h('button', {
        class: 'btn btn-ghost', type: 'button',
        onclick: () => {
          testSound();
          setTimeout(() => {
            const st = audioStatus();
            soundStatus.textContent = st === 'running'
              ? `Sound is on${music.current ? `, now playing ${music.songName(music.current)}` : ''}. If you still hear nothing, turn up the device volume.`
              : `Sound is ${st}. Tap anywhere in the game, then try again. Some in-app browsers block sound; if so, open the game in Safari or Chrome.`;
          }, 350);
        },
      }, 'Test sound'),
      soundStatus);

    const inputSel = h('select', { class: 'select', onchange: (e) => setSetting('inputMode', e.target.value) },
      h('option', { value: 'cell', selected: s.inputMode === 'cell' }, 'Cell first (tap cell, then glyph)'),
      h('option', { value: 'glyph', selected: s.inputMode === 'glyph' }, 'Glyph first (pick glyph, then tap cells)'));

    const el = h('div', { class: 'page' },
      topbar('Settings', null, nav),
      h('div', { class: 'page-body settings' },
        group('Glyph lineup & theme', [
          setGrid,
          toggle('difficultyAliens', 'Each difficulty brings its own aliens', 'Easy: Soft Visitors · Medium: Alien Creatures · Hard: Hostile Visitors · Alien: Gnarly Horde. In every mode, campaign included.'),
          toggle('sectorSymbols', 'Otherwise, campaign uses each sector\'s lineup', 'Only when difficulty aliens are off. Off = always use your lineup.'),
        ]),
        group('Sound', [
          toggle('sfx', 'Sound effects'),
          slider('sfxVolume', 'Effects volume'),
          musicToggle,
          slider('musicVolume', 'Music volume'),
          songList,
          soundCheck,
          isNative ? toggle('haptics', 'Vibration', 'Haptic feedback on taps and mistakes') : null,
        ]),
        group('Board', [
          h('label', { class: 'set-row' },
            h('span', { class: 'set-text' }, h('span', {}, 'Tries per puzzle'), h('small', {}, 'Wrong glyphs you can make before the visitors arrive. Applies to new puzzles.')),
            triesSel),
          h('label', { class: 'set-row' }, h('span', { class: 'set-text' }, h('span', {}, 'Input style')), inputSel),
          toggle('highlightPeers', 'Highlight row, column and box'),
          toggle('highlightSame', 'Highlight matching glyphs'),
          toggle('constellation', 'Constellation lines', 'Connect matching glyphs on the board'),
          toggle('autoRemoveNotes', 'Auto-clear notes', 'Placing a glyph removes it from nearby notes'),
          toggle('showTimer', 'Show timer'),
          toggle('reduceMotion', 'Reduce motion', 'Calmer animations and background'),
        ]),
        group('Privacy & data', [
          adsSupported ? h('p', { class: 'set-note' }, 'Alien Sudoku is free and shows ads from Google AdMob. Rewarded videos are always optional.') : null,
          privacyOptionsAvailable() ? h('button', { class: 'btn btn-ghost btn-wide', type: 'button', onclick: () => showPrivacyOptions() }, 'Ad privacy choices') : null,
          h('button', {
            class: 'btn btn-danger btn-wide', type: 'button',
            onclick: async () => {
              const ok = await confirmModal({ title: 'Reset all progress?', message: 'Campaign stars, daily streak, stats, achievements and unlocked symbol sets will be erased. This cannot be undone.', confirmLabel: 'Erase everything', danger: true });
              if (!ok) return;
              await resetEverything();
              toast('Progress reset.');
              nav.reset('menu');
            },
          }, 'Reset all progress'),
        ]),
        h('div', { class: 'about' },
          h('b', {}, 'Alien Sudoku'),
          h('small', {}, `Version ${appVersion()}${isElectron ? ' · desktop' : isNative ? '' : ' · web'}`),
          h('small', {}, 'Space photography, glyph art and synthesized music from the original Alien Glyph Sudoku. Fonts: Orbitron and Space Grotesk (SIL Open Font License).'))));
    return { el, destroy: offMusic };
  },
};

function group(title, rows) {
  return h('section', { class: 'set-group' }, h('h2', {}, title), h('div', { class: 'set-rows' }, rows));
}
