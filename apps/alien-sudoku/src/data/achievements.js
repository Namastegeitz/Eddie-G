/* Achievement definitions. `check(ctx)` gets
   { profile, result } where result is the just-finished game (or null when
   evaluating after a non-game event such as unlocking a symbol set). */

import { SECTORS, LEVELS_PER_SECTOR, MAX_STARS } from './sectors.js';
import { SYMBOL_SET_ORDER } from './glyphs/index.js';

const MIN = 60_000;
const won = (r) => r && r.won;
const clean = (r) => won(r) && r.mistakes === 0 && r.hints === 0;
const totalWins = (p) => Object.values(p.stats.byDiff).reduce((n, d) => n + d.won, 0) + p.stats.totals.zenWins;
const totalStars = (p) => Object.values(p.campaign.levels).reduce((n, l) => n + (l.stars || 0), 0);
const sectorDone = (p, s) => {
  for (let l = 0; l < LEVELS_PER_SECTOR; l++) if (!p.campaign.levels[`${s}-${l}`]) return false;
  return true;
};

export const ACHIEVEMENTS = [
  { id: 'first-contact', icon: '🛸', name: 'First Contact', desc: 'Decode your first transmission.', check: ({ result }) => won(result) },
  { id: 'flawless', icon: '💎', name: 'Flawless Decoder', desc: 'Win without a single mistake or hint.', check: ({ result }) => clean(result) },
  { id: 'light-speed', icon: '⚡', name: 'Light Speed', desc: 'Win an Easy puzzle in under 4 minutes.', check: ({ result }) => won(result) && result.difficulty === 'easy' && result.ms < 4 * MIN && !result.zen },
  { id: 'warp-speed', icon: '🌠', name: 'Warp Speed', desc: 'Win a Medium puzzle in under 8 minutes.', check: ({ result }) => won(result) && result.difficulty === 'medium' && result.ms < 8 * MIN && !result.zen },
  { id: 'hyperdrive', icon: '🚀', name: 'Hyperdrive', desc: 'Win a Hard puzzle in under 15 minutes.', check: ({ result }) => won(result) && result.difficulty === 'hard' && result.ms < 15 * MIN && !result.zen },
  { id: 'alien-linguist', icon: '👽', name: 'Alien Linguist', desc: 'Win an Alien puzzle.', check: ({ result }) => won(result) && result.difficulty === 'alien' },
  { id: 'alien-ace', icon: '👑', name: 'Fluent in Alien', desc: 'Win an Alien puzzle with no mistakes or hints.', check: ({ result }) => clean(result) && result.difficulty === 'alien' },
  { id: 'no-help', icon: '🧠', name: 'No Help Needed', desc: 'Win a Hard or Alien puzzle without hints.', check: ({ result }) => won(result) && result.hints === 0 && (result.difficulty === 'hard' || result.difficulty === 'alien') },
  { id: 'comeback', icon: '❤️‍🔥', name: 'Second Wind', desc: 'Win after using a second chance.', check: ({ result }) => won(result) && result.revived },
  { id: 'combo-10', icon: '🔗', name: 'Chain Reaction', desc: 'Reach a ×10 combo.', check: ({ result }) => (result?.bestCombo || 0) >= 10 },
  { id: 'score-5k', icon: '💯', name: 'High Scorer', desc: 'Score 5,000 points in one puzzle.', check: ({ result }) => won(result) && !result.zen && (result.score || 0) >= 5000 },
  { id: 'night-owl', icon: '🦉', name: 'Night Owl', desc: 'Win a puzzle between midnight and 5 AM.', check: ({ result }) => won(result) && new Date().getHours() < 5 },
  { id: 'wins-10', icon: '🎖️', name: 'Decoder Cadet', desc: 'Win 10 puzzles.', check: ({ profile }) => totalWins(profile) >= 10 },
  { id: 'wins-50', icon: '🏅', name: 'Decoder Veteran', desc: 'Win 50 puzzles.', check: ({ profile }) => totalWins(profile) >= 50 },
  { id: 'wins-100', icon: '🏆', name: 'Decoder Legend', desc: 'Win 100 puzzles.', check: ({ profile }) => totalWins(profile) >= 100 },
  { id: 'notes-100', icon: '✎', name: 'Field Notes', desc: 'Pencil in 100 notes.', check: ({ profile }) => profile.stats.totals.notes >= 100 },
  { id: 'zen-10', icon: '🪷', name: 'Zen Master', desc: 'Finish 10 Zen puzzles.', check: ({ profile }) => profile.stats.totals.zenWins >= 10 },
  { id: 'daily-1', icon: '📡', name: 'Tuned In', desc: 'Finish a Daily Transmission.', check: ({ result }) => won(result) && result.mode === 'daily' },
  { id: 'streak-3', icon: '🔥', name: 'On Frequency', desc: 'Reach a 3-day daily streak.', check: ({ profile }) => profile.daily.bestStreak >= 3 },
  { id: 'streak-7', icon: '🌟', name: 'Weekly Watcher', desc: 'Reach a 7-day daily streak.', check: ({ profile }) => profile.daily.bestStreak >= 7 },
  { id: 'streak-30', icon: '🌌', name: 'Deep Space Listener', desc: 'Reach a 30-day daily streak.', check: ({ profile }) => profile.daily.bestStreak >= 30 },
  { id: 'sector-1', icon: '🌙', name: 'Outpost Secured', desc: `Clear ${SECTORS[0].name}.`, check: ({ profile }) => sectorDone(profile, 0) },
  { id: 'sector-all', icon: '🗺️', name: 'Galactic Cartographer', desc: 'Clear all six sectors.', check: ({ profile }) => SECTORS.every((s) => sectorDone(profile, s.id)) },
  { id: 'stars-50', icon: '✨', name: 'Star Collector', desc: 'Earn 50 campaign stars.', check: ({ profile }) => totalStars(profile) >= 50 },
  { id: 'stars-all', icon: '☄️', name: 'Supernova', desc: `Earn all ${MAX_STARS} campaign stars.`, check: ({ profile }) => totalStars(profile) >= MAX_STARS },
  { id: 'collector', icon: '🧩', name: 'Archivist', desc: 'Unlock every symbol set.', check: ({ profile }) => SYMBOL_SET_ORDER.every((k) => profile.unlockedSets.includes(k)) },
];

export const ACHIEVEMENT_BY_ID = Object.fromEntries(ACHIEVEMENTS.map((a) => [a.id, a]));
