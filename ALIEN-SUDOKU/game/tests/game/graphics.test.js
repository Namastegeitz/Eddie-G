import { describe, it, expect } from 'vitest';
import { guessTier, startTier, resolveGraphics, createFrameWatch, PRESETS, QUALITY_ORDER } from '../../src/ui/graphics.js';
import { backdropVariant, variantPath } from '../../src/ui/background.js';
import { DEFAULT_SETTINGS } from '../../src/core/profile.js';

const defaults = { ...DEFAULT_SETTINGS };

describe('graphics quality', () => {
  it('new settings default to Auto with every effect on', () => {
    expect(defaults).toMatchObject({ graphics: 'auto', renderScale: 'auto', frameCap: 'auto', bgMotion: true, glowEffects: true });
  });

  it('High keeps the look from before the upgrade, Ultra adds 60 fps, Low and Medium only take effects away', () => {
    expect(PRESETS.high).toMatchObject({ density: 1, dust: 1, fps: 30, drift: true, nebula: true, glow: true, blur: true, backdrop: 'hd' });
    expect(PRESETS.ultra).toMatchObject({ dprCap: 3, fps: 60 });
    for (const k of ['density', 'dust', 'sparks', 'dprCap']) {
      expect(PRESETS.low[k]).toBeLessThanOrEqual(PRESETS.medium[k]);
      expect(PRESETS.medium[k]).toBeLessThanOrEqual(PRESETS.high[k]);
    }
    expect(PRESETS.low.backdrop).toBe('sd');
  });

  it('guesses a level from the device', () => {
    expect(guessTier({ cores: 12, coarse: false })).toBe('ultra');
    expect(guessTier({ cores: 4, coarse: false })).toBe('high');
    expect(guessTier({ cores: 8, memoryGB: 8, coarse: true })).toBe('high');
    expect(guessTier({ cores: 6, coarse: true })).toBe('high');          // iPhone: no deviceMemory
    expect(guessTier({ cores: 4, memoryGB: 4, coarse: true })).toBe('medium');
    expect(guessTier({ cores: 8, memoryGB: 2, coarse: true })).toBe('low');
  });

  it('a new session starts at most one level above where Auto settled last time', () => {
    expect(startTier('ultra', null)).toBe('ultra');
    expect(startTier('ultra', 'low')).toBe('medium');
    expect(startTier('medium', 'high')).toBe('medium');
    expect(startTier('high', 'nonsense')).toBe('high');
  });

  it('settings override resolution, frame rate and effects', () => {
    const g = resolveGraphics({ ...defaults, renderScale: 0.5, frameCap: 120, bgMotion: false, glowEffects: false }, 'ultra');
    expect(g).toMatchObject({ tier: 'ultra', scale: 0.5, fps: 120, drift: false, glow: false, blur: false });
    expect(resolveGraphics(defaults, 'medium')).toMatchObject({ scale: 1, fps: 30, drift: true, glow: true, blur: false });
  });

  it('the frame watch only trips after two slow windows in a row, and ignores pauses', () => {
    const watch = createFrameWatch({ window: 10, longMs: 28, maxShare: 0.2, strikes: 2 });
    const feed = (dts) => dts.map((d) => watch(d)).some(Boolean);
    expect(feed(Array(10).fill(16.7))).toBe(false);                    // smooth
    expect(feed([...Array(6).fill(16.7), ...Array(4).fill(40)])).toBe(false); // one slow window
    expect(feed([...Array(6).fill(16.7), ...Array(4).fill(40)])).toBe(true);  // second in a row
    expect(feed(Array(10).fill(5000))).toBe(false);                    // a paused tab is not a slow frame
  });

  it('Low loads the half-size backdrop cuts', () => {
    expect(backdropVariant(400, 900, 'sd')).toBe('tall-sd');
    expect(backdropVariant(1280, 800, 'sd')).toBe('sd');
    expect(backdropVariant(400, 900, 'hd')).toBe('tall');
    expect(variantPath('space/moon-planet.webp', 'tall-sd')).toBe('space/moon-planet.tall-sd.webp');
    expect(QUALITY_ORDER).toEqual(['low', 'medium', 'high', 'ultra']);
  });
});
