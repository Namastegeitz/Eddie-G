import { describe, it, expect } from 'vitest';
import { lineupFor, STORY_LINEUP, DIFFICULTY_LINEUP, THEMES } from '../../src/data/themes.js';
import { campaignDifficulty } from '../../src/engine/pool.js';
import { SECTORS } from '../../src/data/sectors.js';
import { SYMBOL_SETS, SYMBOL_SET_ORDER, DIFFICULTY_ONLY_SETS, spriteMarkup } from '../../src/data/glyphs/index.js';
import { songFor, STYLE_BY_ID } from '../../src/audio/music-engine.js';
import { LOOK_SETS } from '../../src/game/rival.js';

describe('mode-aware difficulty lineup', () => {
  it('Campaign, Daily and Quick Play: Creatures, Star Cadets, Hostile, Gnarly', () => {
    for (const mode of ['campaign', 'daily', 'quick']) {
      expect(['easy', 'medium', 'hard', 'alien'].map((d) => lineupFor(mode, d))).toEqual(['creatures', 'cadets', 'hostile', 'gnarly']);
    }
  });

  it('Zen, Duel and anything else keep the original map, Soft Visitors on Easy', () => {
    for (const mode of ['zen', 'duel', undefined, 'something-new']) {
      expect(['easy', 'medium', 'hard', 'alien'].map((d) => lineupFor(mode, d))).toEqual(['softies', 'creatures', 'hostile', 'gnarly']);
    }
    expect(DIFFICULTY_LINEUP).toEqual({ easy: 'softies', medium: 'creatures', hard: 'hostile', alien: 'gnarly' });
    expect(STORY_LINEUP).toEqual({ easy: 'creatures', medium: 'cadets', hard: 'hostile', alien: 'gnarly' });
  });

  it('campaign sectors get the lineups the spec asks for', () => {
    const levels = (name) => {
      const s = SECTORS.find((x) => x.name === name).id;
      return Array.from({ length: 9 }, (_, l) => lineupFor('campaign', campaignDifficulty(s, l)));
    };
    expect(levels('Ring Belt')).toEqual([...Array(4).fill('creatures'), ...Array(5).fill('cadets')]);
    expect(levels('Pink Nebula')).toEqual(Array(9).fill('cadets'));
    expect(levels('Emerald Pillars').slice(0, 4)).toEqual(Array(4).fill('cadets'));
    // Soft Visitors never appear in the campaign.
    for (const s of SECTORS) for (let l = 0; l < 9; l++) expect(lineupFor('campaign', campaignDifficulty(s.id, l))).not.toBe('softies');
  });

  it('theme songs: Cadet Mixtape on Medium in the three modes, Desert Oracle in Zen and Duel', () => {
    expect(['campaign', 'daily', 'quick'].map((m) => songFor(m, 'medium'))).toEqual(['cadet', 'cadet', 'cadet']);
    expect(songFor('zen', 'medium')).toBe('oracle');
    expect(songFor('duel', 'medium')).toBe('oracle');
    expect(['easy', 'hard', 'alien'].map((d) => songFor('quick', d))).toEqual(['lofi', 'synthwave', 'wardrums']);
    expect(STYLE_BY_ID.cadet).toMatchObject({ name: 'Cadet Mixtape', tier: 'medium', family: 'Alien', bpm: 104 });
  });
});

describe('Star Cadets set', () => {
  it('has the roster, colors and theme from the spec', () => {
    const set = SYMBOL_SETS.cadets;
    expect(set.name).toBe('Star Cadets');
    expect(set.names).toEqual(['Boombox Cadet', 'High-Top Cadet', 'Scrunchie Cadet', 'Mixtape Cadet', 'Aviator Cadet', 'Puzzle-Cube Cadet', 'Aerobics Cadet', 'Handheld Cadet', 'Grunge Cadet']);
    expect(set.colors).toEqual(['#FF3FA4', '#22E1FF', '#FFE53D', '#A86BFF', '#FF8A2A', '#7CFF4F', '#FF4D4D', '#3D6BFF', '#E3DCFF']);
    expect(set.svgs).toHaveLength(9);
    expect(THEMES.cadets).toMatchObject({ name: 'Star Cadets', style: 'retro', bg: '#0a0418', backdrop: 'space/ringed-planet.webp' });
    expect(spriteMarkup()).toContain('id="gl-cadets-9"');
  });

  it('stays out of the Settings picker, the symbol-set count and Duel looks', () => {
    expect(DIFFICULTY_ONLY_SETS).toEqual(['cadets']);
    expect(SYMBOL_SET_ORDER).not.toContain('cadets');
    expect(SYMBOL_SET_ORDER).toHaveLength(10);
    expect(LOOK_SETS).not.toContain('cadets');
  });

  it('keeps its gradient ids in its own cad- namespace and never breaks the inline script', () => {
    const markup = spriteMarkup();
    expect(markup).not.toContain('<!--');
    expect(markup).not.toMatch(/<\/script/i);
  });
});

describe('HD backdrops', async () => {
  const { variantPath, backdropVariant, BACKGROUNDS } = await import('../../src/ui/background.js');
  const { existsSync } = await import('node:fs');
  const { fileURLToPath } = await import('node:url');
  const pub = (p) => fileURLToPath(new URL(`../../public/${p}`, import.meta.url));

  it('picks the tall cut for upright screens and the wide one otherwise', () => {
    expect(backdropVariant(412, 915)).toBe('tall');
    expect(backdropVariant(1280, 800)).toBe(null);
    expect(backdropVariant(800, 800)).toBe(null);
    expect(variantPath('space/nebula-pink.webp', 'tall')).toBe('space/nebula-pink.tall.webp');
    expect(variantPath('space/nebula-pink.webp', 'card')).toBe('space/nebula-pink.card.webp');
    expect(variantPath('space/nebula-pink.webp', null)).toBe('space/nebula-pink.webp');
    expect(variantPath('icons/icon-192.png', 'tall')).toBe('icons/icon-192.png');
  });

  it('every scene ships in all three cuts', () => {
    for (const path of BACKGROUNDS) for (const v of [null, 'tall', 'card']) expect(existsSync(pub(variantPath(path, v))), variantPath(path, v)).toBe(true);
  });
});
