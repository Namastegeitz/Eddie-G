/* The store's own rating card ("Enjoying Alien Sudoku?"), asked at a happy moment.

   Store rules this follows:
   - Apple shows the card at most 3 times in 365 days, and only the system card is allowed.
   - Google: ask after real use, never after a question like "do you like it?", never behind a
     button (its quota may silently show nothing), never with a reward.
   Our rules on top: only right after a won puzzle, never right after an ad, not before the 3rd
   win and the 2nd day of play, at least 120 days between asks, at most 3 asks a year.
   Neither store says whether the card appeared, so every ask counts. */

import { isNative, platform } from './native.js';
import { getProfile } from '../core/profile.js';
import { PUBLISHER } from '../data/publisher.js';

const KEY = 'alien-sudoku:review-asks';
const DAY = 86_400_000;

export const REVIEW_RULES = Object.freeze({ minWins: 3, minDaysSinceInstall: 2, minDaysBetween: 120, maxPerYear: 3 });

/** Pure decision, for tests. */
export function shouldAskForReview({ wins, installedAt, asks = [], now = Date.now(), rules = REVIEW_RULES }) {
  if (wins < rules.minWins) return false;
  if (now - installedAt < rules.minDaysSinceInstall * DAY) return false;
  const lastYear = asks.filter((t) => now - t < 365 * DAY);
  if (lastYear.length >= rules.maxPerYear) return false;
  const last = Math.max(0, ...asks);
  return now - last >= rules.minDaysBetween * DAY;
}

function loadAsks() { try { return JSON.parse(localStorage.getItem(KEY) || '[]'); } catch { return []; } }

function totalWins() {
  const p = getProfile();
  const byDiff = Object.values(p.stats.byDiff || {}).reduce((n, d) => n + (d.won || 0), 0);
  return byDiff + (p.stats.duel?.won || 0);
}

/** Call after a won puzzle (and not right after an ad). */
export async function maybeAskForReview() {
  if (!isNative) return false;
  const asks = loadAsks();
  if (!shouldAskForReview({ wins: totalWins(), installedAt: getProfile().createdAt || Date.now(), asks })) return false;
  try {
    const { AppReview } = await import('@capawesome/capacitor-app-review');
    localStorage.setItem(KEY, JSON.stringify([...asks, Date.now()].slice(-6)));
    await AppReview.requestReview();
    return true;
  } catch { return false; }
}

/** Can "Rate Alien Sudoku" open the store page here? (iOS needs the App Store id first.) */
export const canOpenStorePage = () => platform === 'android' || (platform === 'ios' && !!PUBLISHER.appStoreId);

/** Opens the game's store page (Settings → Rate Alien Sudoku, and update notices). */
export async function openStorePage() {
  try {
    const { AppReview } = await import('@capawesome/capacitor-app-review');
    await AppReview.openAppStore(platform === 'ios' ? { appId: PUBLISHER.appStoreId } : undefined);
  } catch { /* ignore */ }
}
