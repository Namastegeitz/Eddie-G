/* =====================================================================
   Off-Grid Survival Kit — shared page behaviour (loaded on every page)
   - day / night / red theme toggle  (button[data-theme-toggle])
   - online/offline dot in the header (.net-dot)
   - service-worker registration (offline support + install)
   - print helpers: [data-print] buttons, open all <details> when printing
   - OGSK.toast(msg) small notifications
   - OGSK.wakeLock helpers (keep screen on for strobe / SOS / tracking)
   The app root is given by <html data-root="../"> on sub-pages ("./" on hub).
   ===================================================================== */
(function () {
  'use strict';

  var root = document.documentElement.getAttribute('data-root') || './';
  var OGSK = window.OGSK = window.OGSK || {};
  OGSK.root = root;

  /* ---------------- theme ---------------- */
  var THEMES = ['dark', 'day', 'red'];
  var THEME_LABEL = { dark: 'Night', day: 'Day', red: 'Red' };
  var THEME_NEXT_HINT = { dark: 'Switch to day mode (bright, for sunlight)', day: 'Switch to red night-vision mode', red: 'Switch to dark mode' };
  var ICON = {
    dark: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>',
    day: '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4.5"/><path d="M12 1.5v3M12 19.5v3M1.5 12h3M19.5 12h3M4.6 4.6l2.1 2.1M17.3 17.3l2.1 2.1M4.6 19.4l2.1-2.1M17.3 6.7l2.1-2.1"/></svg>',
    red: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>'
  };

  function currentTheme() { return document.documentElement.getAttribute('data-theme') || 'dark'; }
  function setTheme(t) {
    document.documentElement.setAttribute('data-theme', t);
    try { localStorage.setItem('ogsk.theme', t); } catch (e) {}
    paintThemeButtons();
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', t === 'day' ? '#ffffff' : '#000000');
    document.dispatchEvent(new CustomEvent('ogsk:theme', { detail: t }));
  }
  function paintThemeButtons() {
    var t = currentTheme();
    document.querySelectorAll('[data-theme-toggle]').forEach(function (b) {
      b.innerHTML = ICON[t] + '<span class="theme-label">' + THEME_LABEL[t] + '</span>';
      b.setAttribute('aria-label', 'Theme: ' + THEME_LABEL[t] + '. ' + THEME_NEXT_HINT[t]);
      b.title = THEME_NEXT_HINT[t];
    });
  }
  OGSK.setTheme = setTheme;
  OGSK.theme = currentTheme;

  /* ---------------- toast ---------------- */
  OGSK.toast = function (msg, opts) {
    opts = opts || {};
    var host = document.querySelector('.toast-host');
    if (!host) {
      host = document.createElement('div');
      host.className = 'toast-host';
      host.setAttribute('role', 'status');
      host.setAttribute('aria-live', 'polite');
      document.body.appendChild(host);
    }
    var el = document.createElement('div');
    el.className = 'toast' + (opts.error ? ' error' : '');
    el.textContent = msg;
    host.appendChild(el);
    while (host.children.length > 2) host.firstChild.remove();   // never pile up over the screen
    setTimeout(function () { el.remove(); }, opts.ms || 3500);
  };

  /* ---------------- screen wake lock ----------------
     Keeps the display on while a strobe / SOS beacon / track is running.
     Re-acquired automatically when the page becomes visible again. */
  var wakeSentinel = null, wakeWanted = 0;
  async function acquireWake() {
    if (!('wakeLock' in navigator) || wakeSentinel || document.visibilityState !== 'visible') return;
    try {
      wakeSentinel = await navigator.wakeLock.request('screen');
      wakeSentinel.addEventListener('release', function () { wakeSentinel = null; });
    } catch (e) { /* denied or unsupported (e.g. low battery) */ }
  }
  OGSK.wakeLock = {
    supported: 'wakeLock' in navigator,
    request: function () { wakeWanted++; acquireWake(); },
    release: function () {
      wakeWanted = Math.max(0, wakeWanted - 1);
      if (!wakeWanted && wakeSentinel) { wakeSentinel.release().catch(function () {}); wakeSentinel = null; }
    }
  };
  document.addEventListener('visibilitychange', function () { if (wakeWanted) acquireWake(); });

  /* ---------------- online / offline dot ---------------- */
  function paintNet() {
    var on = navigator.onLine;
    document.querySelectorAll('.net-dot').forEach(function (d) {
      d.classList.toggle('offline', !on);
      d.title = on ? 'Online (signal available)' : 'Offline — using saved data';
      d.setAttribute('aria-label', d.title);
    });
  }
  window.addEventListener('online', paintNet);
  window.addEventListener('offline', paintNet);

  /* ---------------- service worker ---------------- */
  OGSK.swReady = new Promise(function (resolve) {
    if (!('serviceWorker' in navigator) || location.protocol === 'file:') { resolve(null); return; }
    window.addEventListener('load', function () {
      navigator.serviceWorker.register(root + 'sw.js', { scope: root })
        .then(function (reg) { resolve(reg); })
        .catch(function (err) { console.warn('Service worker registration failed:', err); resolve(null); });
    });
  });

  /* ---------------- printing ---------------- */
  var reopened = [];
  window.addEventListener('beforeprint', function () {
    reopened = [];
    document.querySelectorAll('details:not([open])').forEach(function (d) { d.open = true; reopened.push(d); });
  });
  window.addEventListener('afterprint', function () { reopened.forEach(function (d) { d.open = false; }); reopened = []; });

  /* ---------------- deep links: page#section (search results, TOC chips) ----------------
     When a page opens with #id (or the hash changes):
       1. find the target; search results may add ?find=<exact heading text>
          for headings without an id of their own — then we land on the first
          h2/h3/h4/<summary> inside #id whose text matches;
       2. open every closed <details> around it (a <summary> target opens its card);
       3. scroll it to the top, just below the sticky header (an explicit offset,
          so it is the same on every page whatever its own scroll-margin CSS);
       4. flash an outline for ~2 s so the eye finds it.
     Hashes that are not element ids (the map's #tab=…, #sos, #wp=…) are ignored. */
  (function () {
    var style = document.createElement('style');
    style.textContent = '.ogsk-flash{outline:3px solid var(--accent);outline-offset:3px;border-radius:8px}' +
      '@media print{.ogsk-flash{outline:0}}';
    document.head.appendChild(style);

    function norm(s) { return (s || '').replace(/\s+/g, ' ').trim(); }

    /** Space the sticky header covers at the top of the viewport (+8 px air). */
    function headerPad() {
      var hdr = document.querySelector('.app-header');
      var cs = hdr && getComputedStyle(hdr);
      return cs && (cs.position === 'sticky' || cs.position === 'fixed') ? Math.ceil(hdr.getBoundingClientRect().height) + 8 : 0;
    }
    function scrollToEl(el) {
      var y = el.getBoundingClientRect().top + window.pageYOffset - headerPad();
      window.scrollTo(0, Math.max(0, y));
    }

    function target() {
      var id = location.hash.slice(1), find = null, base = null;
      try { id = decodeURIComponent(id); } catch (e) { /* keep raw */ }
      if (id) base = document.getElementById(id);
      try { find = new URLSearchParams(location.search).get('find'); } catch (e) { /* old browser */ }
      if (find) {
        var want = norm(find), scope = base || document.querySelector('main') || document.body;
        var cands = scope.querySelectorAll('h2, h3, h4, summary'), hit = null, i;
        for (i = 0; i < cands.length && !hit; i++) if (norm(cands[i].textContent) === want) hit = cands[i];
        for (i = 0; i < cands.length && !hit; i++) if (norm(cands[i].textContent).indexOf(want) === 0) hit = cands[i];
        if (hit) return hit.tagName === 'SUMMARY' ? hit.parentElement : hit;
      }
      if (!base || base.tagName === 'MAIN' || base === document.body) return null;   // skip-link etc.
      return base;
    }

    var flashTimer = null;
    function reveal(flash) {
      var el = target();
      if (!el) return null;
      for (var d = el.closest('details'); d; d = d.parentElement && d.parentElement.closest('details')) d.open = true;
      scrollToEl(el);
      if (flash) {
        document.querySelectorAll('.ogsk-flash').forEach(function (x) { x.classList.remove('ogsk-flash'); });
        el.classList.add('ogsk-flash');
        clearTimeout(flashTimer);
        flashTimer = setTimeout(function () { el.classList.remove('ogsk-flash'); }, 2000);
      }
      return el;
    }

    OGSK.revealHash = reveal;
    window.addEventListener('hashchange', function () { reveal(true); });
    // Run after the page's own DOMContentLoaded handlers (registered earlier),
    // so a page script that also scrolls to the hash can't undo ours.
    function onReady() {
      if (!location.hash && location.search.indexOf('find=') < 0) return;
      var el = reveal(true);
      if (!el) return;
      // ?find= has done its job: drop it so later TOC jumps aren't re-targeted.
      if (location.search.indexOf('find=') >= 0) {
        try {
          var u = new URL(location.href);
          u.searchParams.delete('find');
          history.replaceState(history.state, '', u.pathname + u.search + u.hash);
        } catch (e) { /* file:// on some browsers */ }
      }
      // The browser's own #anchor scroll can land after ours once the page has
      // fully loaded; put the target back on top unless the user has moved.
      var moved = false;
      ['touchstart', 'wheel', 'keydown'].forEach(function (t) { window.addEventListener(t, function () { moved = true; }, { once: true, passive: true }); });
      window.addEventListener('load', function () {
        if (!moved && Math.abs(el.getBoundingClientRect().top - headerPad()) > 4) scrollToEl(el);
      });
    }
    if (document.readyState === 'complete') onReady();
    else document.addEventListener('DOMContentLoaded', onReady);
  })();

  /* ---------------- wire-up ---------------- */
  function init() {
    document.querySelectorAll('[data-theme-toggle]').forEach(function (b) {
      b.addEventListener('click', function () {
        var i = THEMES.indexOf(currentTheme());
        setTheme(THEMES[(i + 1) % THEMES.length]);
      });
    });
    document.querySelectorAll('[data-print]').forEach(function (b) {
      b.addEventListener('click', function () { window.print(); });
    });
    /* "Expand all / collapse all" for long reference pages */
    document.querySelectorAll('[data-expand-all]').forEach(function (b) {
      b.addEventListener('click', function () {
        var scope = document.querySelector(b.getAttribute('data-expand-all')) || document;
        var ds = scope.querySelectorAll('details');
        var anyClosed = Array.prototype.some.call(ds, function (d) { return !d.open; });
        ds.forEach(function (d) { d.open = anyClosed; });
        b.textContent = anyClosed ? 'Collapse all' : 'Expand all';
      });
    });
    paintThemeButtons();
    paintNet();
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', currentTheme() === 'day' ? '#ffffff' : '#000000');
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
