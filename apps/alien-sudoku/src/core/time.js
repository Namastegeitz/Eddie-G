/* Time and date helpers. Daily puzzles key off the player's LOCAL date. */

const pad = (n) => String(n).padStart(2, '0');

/** "m:ss", or "h:mm:ss" past an hour. */
export function formatTime(ms) {
  if (ms == null || !isFinite(ms)) return '—';
  const total = Math.max(0, Math.floor(ms / 1000));
  const s = total % 60;
  const m = Math.floor(total / 60) % 60;
  const h = Math.floor(total / 3600);
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
}

/** Longer form for stats: "2h 05m", "12m 30s". */
export function formatDuration(ms) {
  const total = Math.max(0, Math.floor((ms || 0) / 1000));
  const h = Math.floor(total / 3600);
  const m = Math.floor(total / 60) % 60;
  const s = total % 60;
  if (h) return `${h}h ${pad(m)}m`;
  if (m) return `${m}m ${pad(s)}s`;
  return `${s}s`;
}

/** Local calendar date as YYYY-MM-DD. */
export function dateStr(d = new Date()) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
export const todayStr = () => dateStr(new Date());

/** Parse YYYY-MM-DD as a local-noon Date (noon avoids DST edge cases). */
export function parseDateStr(s) {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(y, m - 1, d, 12);
}

export function addDays(s, n) {
  const d = parseDateStr(s);
  d.setDate(d.getDate() + n);
  return dateStr(d);
}

export function prettyDate(s, opts = { weekday: 'short', month: 'short', day: 'numeric' }) {
  return parseDateStr(s).toLocaleDateString(undefined, opts);
}
