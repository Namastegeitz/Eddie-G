import { describe, it, expect } from 'vitest';
import { compareVersions, updateNotice, REMOTE_DEFAULTS } from '../../src/platform/remote.js';
import { shouldAskForReview, REVIEW_RULES } from '../../src/platform/review.js';
import { resolveTextScale, clampScale } from '../../src/platform/textsize.js';
import { DEFAULT_SETTINGS } from '../../src/core/profile.js';

const DAY = 86_400_000;

describe('remote switches', () => {
  it('defaults change nothing: ads on, no update notice', () => {
    expect(REMOTE_DEFAULTS).toEqual({ disable_ads: false, disable_interstitials: false, disable_rewarded: false, min_version: '', force_below_version: '', update_message: '' });
    expect(updateNotice(REMOTE_DEFAULTS, '1.2.0')).toBe(null);
  });
  it('compares versions number by number', () => {
    expect(compareVersions('1.2.10', '1.2.9')).toBe(1);
    expect(compareVersions('1.2.0', '1.2')).toBe(0);
    expect(compareVersions('1.1.9', '1.2.0')).toBe(-1);
  });
  it('soft notice below min_version, forced below force_below_version, nothing for dev builds', () => {
    expect(updateNotice({ ...REMOTE_DEFAULTS, min_version: '1.3.0' }, '1.2.0')).toMatchObject({ force: false });
    expect(updateNotice({ ...REMOTE_DEFAULTS, min_version: '1.3.0', force_below_version: '1.2.5' }, '1.2.0')).toMatchObject({ force: true });
    expect(updateNotice({ ...REMOTE_DEFAULTS, min_version: '1.3.0' }, '1.3.0')).toBe(null);
    expect(updateNotice({ ...REMOTE_DEFAULTS, min_version: '9.0.0' }, 'dev')).toBe(null);
    expect(updateNotice({ ...REMOTE_DEFAULTS, min_version: '1.3.0', update_message: 'Hi' }, '1.0.0').message).toBe('Hi');
  });
});

describe('store rating card', () => {
  const now = Date.UTC(2027, 5, 1);
  const base = { wins: 5, installedAt: now - 10 * DAY, asks: [], now };
  it('asks after the 3rd win and the 2nd day', () => {
    expect(shouldAskForReview(base)).toBe(true);
    expect(shouldAskForReview({ ...base, wins: 2 })).toBe(false);
    expect(shouldAskForReview({ ...base, installedAt: now - 1 * DAY })).toBe(false);
  });
  it('waits 120 days between asks and never more than 3 a year (Apple limit)', () => {
    expect(shouldAskForReview({ ...base, asks: [now - 30 * DAY] })).toBe(false);
    expect(shouldAskForReview({ ...base, asks: [now - 121 * DAY] })).toBe(true);
    expect(shouldAskForReview({ ...base, asks: [now - 360 * DAY, now - 240 * DAY, now - 121 * DAY] })).toBe(false);
    expect(REVIEW_RULES.maxPerYear).toBeLessThanOrEqual(3);
  });
});

describe('text size', () => {
  it('defaults to Auto (the phone setting) and stays between 100% and 150%', () => {
    expect(DEFAULT_SETTINGS.textSize).toBe('auto');
    expect(resolveTextScale('auto', 1.3)).toBe(1.3);
    expect(resolveTextScale('auto', 2.4)).toBe(1.5);
    expect(resolveTextScale('auto', 0.8)).toBe(1);
    expect(resolveTextScale(1.15, 2)).toBe(1.15);
    expect(clampScale('nonsense')).toBe(1);
  });
});

describe('crash reports', () => {
  it('the switch exists and defaults to on', () => {
    expect(DEFAULT_SETTINGS.crashReports).toBe(true);
  });
});
