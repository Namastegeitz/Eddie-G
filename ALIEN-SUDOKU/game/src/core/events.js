/* Tiny app-wide event bus. */
const handlers = new Map();

export function on(type, fn) {
  if (!handlers.has(type)) handlers.set(type, new Set());
  handlers.get(type).add(fn);
  return () => handlers.get(type)?.delete(fn);
}

export function emit(type, payload) {
  const set = handlers.get(type);
  if (!set) return;
  for (const fn of [...set]) {
    try { fn(payload); } catch (err) { console.error(`[events] ${type} handler failed`, err); }
  }
}
