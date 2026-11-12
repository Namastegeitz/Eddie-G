/* Off-Grid Survival Kit — theme bootstrap.
   Loaded synchronously in <head> so the saved theme is applied before the
   first paint (no white flash at night). Themes: dark (default) | day | red. */
(function () {
  var t = 'dark';
  try { t = localStorage.getItem('ogsk.theme') || 'dark'; } catch (e) { /* storage blocked */ }
  if (t !== 'dark' && t !== 'day' && t !== 'red') t = 'dark';
  document.documentElement.setAttribute('data-theme', t);
  var ts = 'normal';
  try { ts = localStorage.getItem('ogsk.textsize') || 'normal'; } catch (e) {}
  if (ts === 'large' || ts === 'xl') document.documentElement.setAttribute('data-textsize', ts);
})();
