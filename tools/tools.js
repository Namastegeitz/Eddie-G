/* =====================================================================
   Off-Grid Survival Kit — Emergency Device Tools  (tools/index.html)
   ---------------------------------------------------------------------
   1. Light   SOS strobe, Morse message light, steady screen torch,
              optional phone flashlight (camera "torch" constraint)
   2. Sound   whistle, 3-blast distress, SOS audio, siren, two-tone alarm
              (Web Audio oscillators — no audio files)
   3. Gear & inventory checklists   (IndexedDB store "checklists")
   4. Group rendezvous plan          (IndexedDB kv key "rendezvous")
   5. Stopwatch / countdown timer
   6. GPS position card
   7. Lightning flash-to-bang distance + 30-minute all-clear
                                     (IndexedDB kv key "tools.lightning")
   Settings for the light/sound tools live in kv key "tools.prefs".
   Everything runs offline; nothing ever leaves the device.
   Depends on: common.js (OGSK), store.js (OGStore), geo.js (OGGeo),
               vendor/mgrs.min.js (MGRS inside OGGeo).
   ===================================================================== */
(function () {
  'use strict';

  /* =================================================================
     Small helpers
     ================================================================= */
  function $(sel, root) { return (root || document).querySelector(sel); }
  function $$(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  /* Build a DOM element. attrs: class, text, value, checked, on<event>
     handlers, anything else becomes an attribute. Children may be
     strings (inserted as text — never as HTML) or nodes. User data is
     therefore never parsed as HTML. */
  function el(tag, attrs, kids) {
    var e = document.createElement(tag);
    if (attrs) Object.keys(attrs).forEach(function (k) {
      var v = attrs[k];
      if (v == null || v === false) return;
      if (k === 'class') e.className = v;
      else if (k === 'text') e.textContent = v;
      else if (k === 'value') e.value = v;
      else if (k === 'checked') e.checked = !!v;
      else if (k === 'html') e.innerHTML = v;            // only ever used with static icon markup
      else if (k.slice(0, 2) === 'on' && typeof v === 'function') e.addEventListener(k.slice(2), v);
      else e.setAttribute(k, v === true ? '' : v);
    });
    (kids || []).forEach(function (c) {
      if (c == null || c === false) return;
      e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c);
    });
    return e;
  }

  function toast(msg, opts) {
    if (window.OGSK && OGSK.toast) OGSK.toast(msg, opts);
    else console.log(msg);
  }
  function hasStore() { return !!window.OGStore; }
  function pad2(n) { return (n < 10 ? '0' : '') + n; }
  function clockTime(d) { d = d || new Date(); return pad2(d.getHours()) + ':' + pad2(d.getMinutes()); }
  function currentTheme() { return (window.OGSK && OGSK.theme) ? OGSK.theme() : (document.documentElement.getAttribute('data-theme') || 'dark'); }

  /* Static SVG icons (stroke = currentColor via .btn svg rules in app.css). */
  var ICON = {
    edit: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 20h4L19 9l-4-4L4 16v4z"/><path d="M13.5 6.5l4 4"/></svg>',
    del: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg>'
  };

  /* Screen wake lock, one "hold" per feature so each can release safely.
     OGSK.wakeLock is reference counted. */
  var holds = {};
  function hold(name, on) {
    on = !!on;
    if (!!holds[name] === on) return;
    holds[name] = on;
    if (!window.OGSK || !OGSK.wakeLock) return;
    if (on) OGSK.wakeLock.request(); else OGSK.wakeLock.release();
  }

  /* =================================================================
     Preferences (light + sound settings), kv key "tools.prefs"
     ================================================================= */
  var prefs = {
    unit: 250,        // Morse unit (one dot) in ms
    color: 'white',   // light colour in the dark/day themes ('white' | 'red')
    colorRed: 'red',  // light colour in the red night theme — red unless the user picks white
    torch: false,     // also flash the camera LED where supported
    msg: '',          // last Morse message
    repeat: true,     // repeat Morse message
    wave: 'square',   // oscillator wave for tones
    vol: 100          // tone volume, percent
  };
  var prefsTimer = 0;
  function savePrefs() {
    clearTimeout(prefsTimer);
    prefsTimer = setTimeout(function () {
      if (hasStore()) OGStore.kvSet('tools.prefs', prefs).catch(function () { /* non-critical */ });
    }, 300);
  }

  /* =================================================================
     1. MORSE  (ITU-R M.1677-1)
     ================================================================= */
  var MORSE = {
    A: '.-', B: '-...', C: '-.-.', D: '-..', E: '.', F: '..-.', G: '--.', H: '....', I: '..', J: '.---',
    K: '-.-', L: '.-..', M: '--', N: '-.', O: '---', P: '.--.', Q: '--.-', R: '.-.', S: '...', T: '-',
    U: '..-', V: '...-', W: '.--', X: '-..-', Y: '-.--', Z: '--..',
    '0': '-----', '1': '.----', '2': '..---', '3': '...--', '4': '....-',
    '5': '.....', '6': '-....', '7': '--...', '8': '---..', '9': '----.',
    '.': '.-.-.-', ',': '--..--', '?': '..--..', '/': '-..-.', '=': '-...-', '+': '.-.-.',
    '-': '-....-', '@': '.--.-.', "'": '.----.', '"': '.-..-.', '(': '-.--.', ')': '-.--.-',
    ':': '---...', ';': '-.-.-.'
  };
  var SOS_PROSIGN = '...---...';

  /* Pretty dots/dashes for display: • and — separated by thin spaces. */
  function prettyCode(code) {
    return code.split('').map(function (c) { return c === '.' ? '•' : '—'; }).join(' ');
  }

  /* Normalise typed text: curly quotes → straight, upper case. */
  function normText(text) {
    return String(text || '').replace(/[‘’`]/g, "'").replace(/[“”]/g, '"').toUpperCase();
  }

  /* Turn text into display tokens and an on/off timing schedule.
     Returns { tokens: [{ch, code} | {sep:true}], segs: [{on, u, ci}], skipped: [chars] }
       u  = length in Morse units, ci = index of the token being sent (−1 = none).
     Timing: dot 1, dash 3, gap inside a character 1, between characters 3,
     between words 7. The word "SOS" is sent as the prosign ...---... (no letter gaps).
     A trailing 7-unit gap is added so repeats are separated like words. */
  function morseSchedule(text) {
    var tokens = [], segs = [], skipped = [];
    var words = normText(text).trim().split(/\s+/).filter(Boolean).map(function (w) {
      if (w === 'SOS') return [{ ch: 'SOS', code: SOS_PROSIGN }];
      return w.split('').filter(function (c) {
        if (MORSE[c]) return true;
        if (skipped.indexOf(c) < 0) skipped.push(c);
        return false;
      }).map(function (c) { return { ch: c, code: MORSE[c] }; });
    }).filter(function (w) { return w.length; });

    function off(u, ci) {
      var last = segs[segs.length - 1];
      if (last && !last.on) { if (u > last.u) last.u = u; }    // merge gaps: the longer one wins
      else segs.push({ on: false, u: u, ci: ci == null ? -1 : ci });
    }
    words.forEach(function (letters, wi) {
      if (wi) { tokens.push({ sep: true }); off(7); }
      letters.forEach(function (L, li) {
        if (li) off(3);
        var ci = tokens.length;
        tokens.push(L);
        L.code.split('').forEach(function (sym, si) {
          if (si) off(1, ci);
          segs.push({ on: true, u: sym === '.' ? 1 : 3, ci: ci });
        });
      });
    });
    if (segs.length) off(7);
    return { tokens: tokens, segs: segs, skipped: skipped };
  }

  /* Render tokens as chips (character over its code). Returns the container. */
  function renderTokens(host, tokens) {
    host.textContent = '';
    tokens.forEach(function (t, i) {
      if (t.sep) { host.appendChild(el('span', { class: 'mtok sep', 'aria-hidden': 'true' }, [el('b', { text: '/' }), el('span', { class: 'code', text: ' ' })])); return; }
      host.appendChild(el('span', { class: 'mtok', 'data-ci': i }, [el('b', { text: t.ch }), el('span', { class: 'code', text: prettyCode(t.code) })]));
    });
    return host;
  }

  /* Reference grid of letters & numbers (inside the <details>). */
  function buildMorseRef() {
    var host = $('#morse-ref');
    if (!host) return;
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('').forEach(function (c) {
      host.appendChild(el('div', null, [el('b', { text: c }), el('span', { text: prettyCode(MORSE[c]) })]));
    });
  }

  /* =================================================================
     1b. PHONE FLASHLIGHT (torch) — Android Chrome only, best effort.
     getUserMedia on the rear camera, then applyConstraints({torch}).
     Only one applyConstraints call is in flight at a time; the latest
     wanted state is applied when the previous call settles.
     ================================================================= */
  var torch = { stream: null, track: null, state: false, want: false, busy: false, opening: null };

  function torchSupportedAtAll() {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
  }
  function torchOpen() {
    if (torch.track) return Promise.resolve(true);
    if (torch.opening) return torch.opening;
    if (!torchSupportedAtAll()) return Promise.reject(new Error('unsupported'));
    torch.opening = navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false })
      .then(function (stream) {
        var track = stream.getVideoTracks()[0];
        function hasTorch() {
          try { var c = track.getCapabilities ? track.getCapabilities() : {}; return !!(c && c.torch); } catch (e) { return false; }
        }
        // Some phones only report the torch capability once frames flow: check twice.
        var ready = hasTorch() ? Promise.resolve(true) : new Promise(function (r) { setTimeout(function () { r(hasTorch()); }, 600); });
        return ready.then(function (ok) {
          if (!ok) { stream.getTracks().forEach(function (t) { t.stop(); }); throw new Error('no-torch'); }
          torch.stream = stream; torch.track = track; torch.state = false;
          return true;
        });
      })
      .finally(function () { torch.opening = null; });
    return torch.opening;
  }
  function torchSet(on) {
    torch.want = !!on;
    torchPump();
  }
  function torchPump() {
    var track = torch.track;
    if (!track || torch.busy || torch.state === torch.want) return;
    torch.busy = true;
    var target = torch.want;
    var p;
    try { p = track.applyConstraints({ advanced: [{ torch: target }] }); } catch (e) { p = Promise.reject(e); }
    p.then(function () { torch.state = target; }, function () { torch.state = target; /* ignore, keep going */ })
      .then(function () { torch.busy = false; if (torch.track === track) torchPump(); });
  }
  function torchClose() {
    var t = torch.track, s = torch.stream;
    torch.track = null; torch.stream = null; torch.want = false; torch.state = false; torch.busy = false;
    if (!t) return;
    var stopped = false;
    function stopAll() { if (stopped) return; stopped = true; s.getTracks().forEach(function (x) { try { x.stop(); } catch (e) {} }); }
    try { t.applyConstraints({ advanced: [{ torch: false }] }).then(stopAll, stopAll); } catch (e) { stopAll(); }
    setTimeout(stopAll, 800); // never leave the camera running
  }

  /* =================================================================
     1c. LIGHT OVERLAY  (strobe / Morse message / steady)
     A precomputed schedule is played with a setTimeout chain timed
     against performance.now() (no drift, no CSS animation — the
     reduced-motion rule in app.css would kill animations).
     ================================================================= */
  var light = {
    active: false, mode: null, segs: null, tokens: null, idx: 0, tNext: 0, timer: 0,
    repeat: true, startedAt: 0, pushed: false, fs: false, returnFocus: null, curCi: -1
  };
  var ignorePops = 0;

  /* The colour choice is remembered per theme: picking white in day mode
     never makes the red night theme flash white. */
  function lightColor() { return currentTheme() === 'red' ? prefs.colorRed : prefs.color; }

  function setLit(on) {
    var ov = $('#strobe');
    ov.classList.toggle('lit', !!on);
    ov.setAttribute('data-lit', on ? '1' : '0');
    if (prefs.torch) torchSet(on);
  }

  function highlight(ci) {
    if (ci === light.curCi) return;
    light.curCi = ci;
    $$('#strobe-morse .mtok.cur').forEach(function (n) { n.classList.remove('cur'); });
    var n = $('#strobe-morse .mtok[data-ci="' + ci + '"]');
    if (n) {
      n.classList.add('cur');
      // Keep the current character visible in long messages. Scroll only the
      // info box (its offsetParent) — scrollIntoView could move the page.
      var box = $('#strobe-info');
      if (box.scrollHeight > box.clientHeight) box.scrollTop = Math.max(0, n.offsetTop - box.clientHeight / 2);
    }
  }

  /* mode: 'sos' | 'morse' | 'steady' */
  function startLight(mode, trigger) {
    if (light.active) stopLight();
    var plan = null;
    if (mode === 'sos') plan = morseSchedule('SOS');
    else if (mode === 'morse') {
      plan = morseSchedule(prefs.msg);
      if (!plan.segs.length) { toast('Type a message first (letters, numbers or . , ? / = + - @ \' " ( ) : ;).', { error: true }); $('#morse-text').focus(); return; }
    }

    var ov = $('#strobe');
    light.active = true;
    light.mode = mode;
    light.segs = plan ? plan.segs : null;
    light.tokens = plan ? plan.tokens : null;
    light.repeat = mode === 'sos' ? true : (mode === 'morse' ? prefs.repeat : true);
    light.idx = 0;
    light.curCi = -1;
    light.startedAt = Date.now();
    light.returnFocus = trigger || null;

    ov.classList.toggle('red', lightColor() === 'red');
    ov.setAttribute('data-mode', mode);
    var info = $('#strobe-info');
    if (mode === 'steady') {
      info.hidden = true;
    } else {
      info.hidden = false;
      $('#strobe-mode').textContent = mode === 'sos' ? 'SOS · repeating' : ('Morse message' + (light.repeat ? ' · repeating' : ''));
      renderTokens($('#strobe-morse'), plan.tokens);
    }
    ov.hidden = false;
    document.body.classList.add('strobe-open');
    try { ov.focus({ preventScroll: true }); } catch (e) { ov.focus(); }

    // Back button closes the light: push a history entry we can pop.
    try { history.pushState({ ogskLight: 1 }, ''); light.pushed = true; } catch (e) { light.pushed = false; }

    // Full screen hides the browser bars = more light. Must run inside the tap.
    light.fs = false;
    var de = document.documentElement;
    if (de.requestFullscreen && !document.fullscreenElement) {
      light.fsReq = true;
      try {
        var p = de.requestFullscreen({ navigationUI: 'hide' });
        if (p && p.catch) p.catch(function () { light.fsReq = false; /* not allowed here: fine */ });
      } catch (e) { light.fsReq = false; }
    }

    hold('light', true);

    // Optional phone flashlight: joins in when ready; screen works meanwhile.
    if (prefs.torch) {
      var startedAt = light.startedAt;
      torchOpen().then(function () {
        if (!light.active || light.startedAt !== startedAt) { torchClose(); return; }
        torchSet($('#strobe').classList.contains('lit'));
        setTorchHint('ok');
      }).catch(function (err) {
        setTorchHint(err && err.message === 'no-torch' ? 'none' : 'denied');
        if (light.active) toast('Phone flashlight not available here — using the screen only.');
      });
    }

    if (mode === 'steady') {
      setLit(true);
    } else {
      setLit(false);
      light.tNext = performance.now() + 150;
      light.timer = setTimeout(runSeg, 150);
    }
  }

  /* Play the next schedule segment, then schedule the one after. */
  function runSeg() {
    if (!light.active) return;
    if (light.idx >= light.segs.length) {
      if (light.repeat) light.idx = 0;
      else { stopLight(); toast('Message sent.'); return; }
    }
    var s = light.segs[light.idx++];
    setLit(s.on);
    if (s.ci >= 0) highlight(s.ci);
    var now = performance.now();
    if (now - light.tNext > 1000) light.tNext = now;   // we were paused (tab hidden): resync, don't race
    light.tNext += s.u * prefs.unit;
    light.timer = setTimeout(runSeg, Math.max(0, light.tNext - performance.now()));
  }

  function stopLight() {
    if (!light.active) return;
    light.active = false;
    clearTimeout(light.timer);
    var ov = $('#strobe');
    setLit(false);
    ov.hidden = true;
    ov.classList.remove('lit');
    document.body.classList.remove('strobe-open');
    torchClose();
    hold('light', false);
    // Leave full screen. If our request hasn't landed yet, fsReq stays set and
    // the fullscreenchange handler exits as soon as it does.
    if (document.fullscreenElement && document.exitFullscreen) {
      light.fsReq = false;
      try { var p = document.exitFullscreen(); if (p && p.catch) p.catch(function () {}); } catch (e) {}
    }
    if (light.pushed) { light.pushed = false; ignorePops++; try { history.back(); } catch (e) { ignorePops--; } }
    if (light.returnFocus && document.contains(light.returnFocus)) { try { light.returnFocus.focus({ preventScroll: true }); } catch (e) {} }
  }

  function setTorchHint(state) {
    var h = $('#torch-hint');
    if (!h) return;
    var base = h.getAttribute('data-base') || h.textContent;
    h.setAttribute('data-base', base);
    var extra = {
      ok: ' ✓ Flashlight working on this phone.',
      none: ' ✗ This phone/browser does not offer flashlight control — screen only.',
      denied: ' ✗ Camera permission was refused or the camera is busy — screen only.',
      unsupported: ' ✗ Not available in this browser — screen only.'
    }[state] || '';
    h.textContent = base + extra;
  }

  /* Update the colour toggle buttons to show the effective colour. */
  function paintColorButtons() {
    var c = lightColor();
    $$('[data-color]').forEach(function (b) { b.setAttribute('aria-pressed', String(b.getAttribute('data-color') === c)); });
  }
  function paintUnit() {
    var u = prefs.unit;
    $('#unit').value = u;
    // PARIS standard word = 50 units → words per minute = 1200 / unit(ms)
    $('#unit-val').textContent = u + ' ms per dot · about ' + (1200 / u).toFixed(1) + ' words/min';
  }
  function paintMorsePreview() {
    var plan = morseSchedule(prefs.msg);
    var host = $('#morse-preview');
    if (!plan.tokens.length) {
      host.textContent = '';
      host.appendChild(el('span', { class: 'hint', text: 'Dots and dashes appear here as you type.' }));
    } else renderTokens(host, plan.tokens);
    var sk = $('#morse-skip');
    if (plan.skipped.length) {
      sk.hidden = false;
      sk.textContent = 'Not in Morse, will be skipped: ' + plan.skipped.join(' ');
    } else sk.hidden = true;
    // Rough duration of one pass
    var units = plan.segs.reduce(function (a, s) { return a + s.u; }, 0);
    if (units) host.setAttribute('title', 'One pass ≈ ' + Math.round(units * prefs.unit / 1000) + ' s');
  }

  function initLight() {
    buildMorseRef();
    $('#sos-start').addEventListener('click', function (e) { startLight('sos', e.currentTarget); });
    $('#steady-start').addEventListener('click', function (e) { startLight('steady', e.currentTarget); });
    $('#morse-start').addEventListener('click', function (e) { startLight('morse', e.currentTarget); });

    // Stop: tap anywhere on the overlay (ignore the ghost tap that opened it).
    var ov = $('#strobe');
    ov.addEventListener('click', function () { if (Date.now() - light.startedAt > 400) stopLight(); });
    ov.addEventListener('contextmenu', function (e) { e.preventDefault(); });
    document.addEventListener('keydown', function (e) {
      if (!light.active) return;
      if (e.key === 'Escape' || e.key === 'Backspace') { e.preventDefault(); stopLight(); }
      else if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        if (Date.now() - light.startedAt > 400) stopLight();   // ignore the key press that started it
      }
    });
    window.addEventListener('popstate', function () {
      if (ignorePops) { ignorePops--; return; }
      if (light.active) { light.pushed = false; stopLight(); }
    });
    document.addEventListener('fullscreenchange', function () {
      if (!light.active) {
        // Full screen arrived after the light was already stopped: undo it.
        if (document.fullscreenElement && light.fsReq) { light.fsReq = false; try { document.exitFullscreen().catch(function () {}); } catch (e) {} }
        return;
      }
      if (document.fullscreenElement) light.fs = true;
      else if (light.fs) stopLight();          // user left full screen (Esc / Back) = stop
    });

    // Colour
    $$('[data-color]').forEach(function (b) {
      b.addEventListener('click', function () {
        var c = b.getAttribute('data-color');
        if (currentTheme() === 'red') prefs.colorRed = c; else prefs.color = c;
        paintColorButtons(); savePrefs();
      });
    });
    document.addEventListener('ogsk:theme', paintColorButtons);

    // Speed
    $('#unit').addEventListener('input', function (e) {
      var v = Math.max(120, Math.min(600, +e.target.value || 250));
      prefs.unit = v; paintUnit(); paintMorsePreview(); savePrefs();
    });

    // Flashlight option
    var tc = $('#torch-on');
    if (!torchSupportedAtAll()) { tc.disabled = true; setTorchHint('unsupported'); }
    tc.addEventListener('change', function () { prefs.torch = tc.checked; savePrefs(); });

    // Message
    var mt = $('#morse-text');
    mt.addEventListener('input', function () { prefs.msg = mt.value; paintMorsePreview(); savePrefs(); });
    mt.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { e.preventDefault(); e.stopPropagation(); startLight('morse', $('#morse-start')); }
    });
    $('#morse-repeat').addEventListener('change', function (e) { prefs.repeat = e.target.checked; savePrefs(); });

    paintColorButtons(); paintUnit(); paintMorsePreview();
  }
  function applyLightPrefs() {
    $('#torch-on').checked = !!prefs.torch && torchSupportedAtAll();
    $('#morse-text').value = prefs.msg || '';
    $('#morse-repeat').checked = prefs.repeat !== false;
    paintColorButtons(); paintUnit(); paintMorsePreview();
  }

  /* =================================================================
     2. SOUND — Web Audio tone generator
     Graph: Oscillator → gate Gain (on/off envelope) → DynamicsCompressor
            → volume Gain → speakers.
     Patterns are lists of steps {on, d (s), f (Hz), f2 (Hz, sweep end)}
     that repeat. A look-ahead scheduler queues ~0.6 s of steps on the
     audio clock every 50 ms (sample-accurate, survives UI jank).
     ================================================================= */
  var WHISTLE_HZ = 3150;   // human hearing is most sensitive ~2–4 kHz
  var LEVEL = 0.9;         // gate level into the compressor
  var RAMP = 0.006;        // 6 ms fades avoid clicks
  var SOUND_NAMES = { whistle: 'Whistle', blasts: '3 blasts (distress)', sos: 'SOS in Morse', siren: 'Siren', alarm: 'Two-tone alarm' };
  var audio = { ctx: null, comp: null, vol: null, osc: null, gate: null, pattern: null, step: 0, next: 0, timer: 0, name: null, lastOn: false, events: [] };

  function ensureAudio() {
    var AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    if (!audio.ctx) {
      // Safari 17+: let web audio play even when the Ring/Silent switch is on silent.
      try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch (e) {}
      var ctx = audio.ctx = new AC();
      var comp = audio.comp = ctx.createDynamicsCompressor();
      comp.threshold.value = -10; comp.knee.value = 2; comp.ratio.value = 20;
      comp.attack.value = 0.002; comp.release.value = 0.08;
      audio.vol = ctx.createGain();
      audio.vol.gain.value = prefs.vol / 100;
      comp.connect(audio.vol);
      audio.vol.connect(ctx.destination);
      ctx.addEventListener && ctx.addEventListener('statechange', paintSound);
    }
    // iOS/Chrome start contexts "suspended" until a user gesture: resume inside the tap.
    if (audio.ctx.state !== 'running') { try { audio.ctx.resume().then(paintSound, function () {}); } catch (e) {} }
    return audio.ctx;
  }

  function soundPattern(name) {
    var W = WHISTLE_HZ;
    switch (name) {
      case 'whistle':
        return [{ on: true, d: 1, f: W }];                          // continuous
      case 'blasts':                                                // ~1 s blasts, ~1 s gaps, pause, repeat
        return [
          { on: true, d: 1, f: W, label: 'Blast 1 of 3' }, { on: false, d: 1 },
          { on: true, d: 1, f: W, label: 'Blast 2 of 3' }, { on: false, d: 1 },
          { on: true, d: 1, f: W, label: 'Blast 3 of 3' },
          { on: false, d: 6, label: 'Pause — listen for a reply…' }
        ];
      case 'sos':
        return morseSchedule('SOS').segs.map(function (s) { return { on: s.on, d: s.u * prefs.unit / 1000, f: W }; });
      case 'siren':                                                 // slow wail up and down
        return [{ on: true, d: 1.4, f: 600, f2: 1400 }, { on: true, d: 1.4, f: 1400, f2: 600 }];
      case 'alarm':                                                 // hi-lo two-tone
        return [{ on: true, d: 0.4, f: 1500 }, { on: true, d: 0.4, f: 1000 }];
    }
    return null;
  }

  /* Queue steps until ~0.6 s ahead of the audio clock. */
  function scheduleSound() {
    var ctx = audio.ctx, now = ctx.currentTime, p = audio.pattern;
    if (!p || !audio.osc) return;
    if (audio.next < now) audio.next = now + 0.02;                 // fell behind (tab throttled): resync
    var g = audio.gate.gain, f = audio.osc.frequency;
    while (audio.next < now + 0.6) {
      var s = p[audio.step], nxt = p[(audio.step + 1) % p.length], t = audio.next;
      if (s.on) {
        f.setValueAtTime(s.f, t);
        if (s.f2) f.linearRampToValueAtTime(s.f2, t + s.d);
        if (!audio.lastOn) { g.setValueAtTime(0, t); g.linearRampToValueAtTime(LEVEL, t + RAMP); }
        if (!nxt.on) { g.setValueAtTime(LEVEL, t + s.d - RAMP); g.linearRampToValueAtTime(0, t + s.d); }
      }
      audio.lastOn = s.on;
      audio.events.push({ t: t, on: s.on, label: s.label || null });
      audio.next += s.d;
      audio.step = (audio.step + 1) % p.length;
    }
  }

  /* 50 ms tick: schedule ahead and update the on-screen "tone on" dot/label. */
  function soundTick() {
    if (!audio.osc) return;
    scheduleSound();
    var now = audio.ctx.currentTime, ev = null;
    while (audio.events.length && audio.events[0].t <= now) ev = audio.events.shift();
    if (ev) {
      $('#tone-dot').classList.toggle('on', ev.on);
      if (ev.label) setSoundStatus('Playing: ' + SOUND_NAMES[audio.name] + ' — ' + ev.label);
    }
  }

  function playSound(name) {
    var same = audio.name === name;
    stopSound();
    if (same) return;                                             // tapping the active sound = stop
    var ctx = ensureAudio();
    if (!ctx) { toast('Sound is not supported in this browser.', { error: true }); return; }
    var pattern = soundPattern(name);
    if (!pattern) return;
    audio.osc = ctx.createOscillator();
    audio.osc.type = prefs.wave;
    audio.gate = ctx.createGain();
    audio.gate.gain.value = 0;
    audio.osc.connect(audio.gate);
    audio.gate.connect(audio.comp);
    audio.pattern = pattern; audio.step = 0; audio.lastOn = false; audio.events = [];
    audio.next = ctx.currentTime + 0.05;
    audio.osc.start();
    audio.name = name;
    scheduleSound();
    audio.timer = setInterval(soundTick, 50);
    hold('sound', true);
    setSoundStatus('Playing: ' + SOUND_NAMES[name]);
    paintSound();
    checkAudioBlocked(name);
  }

  function stopSound() {
    if (!audio.osc) { audio.name = null; return; }
    clearInterval(audio.timer);
    var ctx = audio.ctx, now = ctx.currentTime, osc = audio.osc, gate = audio.gate;
    try {
      gate.gain.cancelScheduledValues(now);
      gate.gain.setValueAtTime(gate.gain.value, now);
      gate.gain.linearRampToValueAtTime(0, now + 0.03);
      osc.frequency.cancelScheduledValues(now);
      osc.stop(now + 0.06);
    } catch (e) { try { osc.stop(); } catch (e2) {} }
    osc.onended = function () { try { osc.disconnect(); gate.disconnect(); } catch (e) {} };
    audio.osc = audio.gate = audio.pattern = null; audio.name = null; audio.events = [];
    hold('sound', false);
    $('#tone-dot').classList.remove('on');
    setSoundStatus('Not playing.');
    paintSound();
  }

  function setSoundStatus(text) { $('#snd-status').textContent = text; }
  function paintSound() {
    $$('[data-sound]').forEach(function (b) { b.setAttribute('aria-pressed', String(b.getAttribute('data-sound') === audio.name)); });
    $$('[data-wave]').forEach(function (b) { b.setAttribute('aria-pressed', String(b.getAttribute('data-wave') === prefs.wave)); });
    $('#vol').value = prefs.vol;
    $('#vol-val').textContent = prefs.vol + '%';
    var st = $('#snd-status');
    st.setAttribute('data-audio', audio.ctx ? audio.ctx.state : 'none');
    st.setAttribute('data-playing', audio.name || '');
    if (audio.name && audio.ctx && audio.ctx.state === 'running' && /blocked/.test(st.textContent)) {
      setSoundStatus('Playing: ' + SOUND_NAMES[audio.name]);
    }
  }
  /* If the browser still hasn't started audio a second after the tap, say so. */
  function checkAudioBlocked(name) {
    setTimeout(function () {
      if (audio.name === name && audio.ctx && audio.ctx.state !== 'running') {
        setSoundStatus('Sound blocked by the browser — tap Stop, then tap the sound again.');
      }
    }, 1000);
  }

  /* Short beeps for the countdown alarm (separate from the patterns). */
  function beep(times) {
    var ctx = ensureAudio();
    if (!ctx) return;
    var t = ctx.currentTime + 0.05;
    for (var i = 0; i < times; i++) {
      var o = ctx.createOscillator(), g = ctx.createGain();
      o.type = 'square'; o.frequency.value = 2000;
      g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(LEVEL, t + RAMP);
      g.gain.setValueAtTime(LEVEL, t + 0.25); g.gain.linearRampToValueAtTime(0, t + 0.26);
      o.connect(g); g.connect(audio.comp);
      o.start(t); o.stop(t + 0.3);
      t += 0.45;
    }
  }

  function initSound() {
    $$('[data-sound]').forEach(function (b) {
      b.addEventListener('click', function () { playSound(b.getAttribute('data-sound')); });
    });
    $('#snd-stop').addEventListener('click', stopSound);
    $('#vol').addEventListener('input', function (e) {
      prefs.vol = Math.max(10, Math.min(100, +e.target.value || 100));
      if (audio.vol) audio.vol.gain.setTargetAtTime(prefs.vol / 100, audio.ctx.currentTime, 0.02);
      paintSound(); savePrefs();
    });
    $$('[data-wave]').forEach(function (b) {
      b.addEventListener('click', function () {
        prefs.wave = b.getAttribute('data-wave');
        if (audio.osc) audio.osc.type = prefs.wave;
        paintSound(); savePrefs();
      });
    });
    paintSound();
  }

  /* =================================================================
     3. CHECKLISTS — store "checklists" {id, name, items:[{id,text,done}], created, updated}
     ================================================================= */
  var TEMPLATES = [
    {
      name: 'Bug-out bag (72-hour)', sub: 'One per person',
      items: [
        'Water: 2–3 L (2–3 qt) in bottles or a bladder',
        'Collapsible bottle or bag to carry more water',
        'Water filter (note: filters do not stop viruses)',
        'Water purification tablets (chlorine dioxide)',
        'Metal cup or pot for boiling water',
        'Food: 3 days, no-cook, high-calorie (bars, nuts, jerky)',
        'Spoon / spork',
        'Small stove + fuel (outdoors only — carbon monoxide)',
        'Tarp or lightweight tent + cord/stakes',
        'Emergency bivvy bag or 2 space blankets',
        'Sleeping bag or quilt for the season + sleeping pad',
        'Rain jacket and rain trousers',
        'Warm layer (wool or fleece), hat and gloves',
        'Spare socks (2 pairs) and underwear',
        'Sturdy, broken-in footwear',
        '2 lighters + waterproof matches + ferro rod',
        'Tinder in a waterproof bag (e.g. cotton balls + petroleum jelly)',
        'Headlamp + spare batteries',
        'Phone, charging cable and charged power bank',
        'Battery / hand-crank radio (NOAA weather band in the US)',
        'Pea-less whistle (on the shoulder strap)',
        'Signal mirror',
        'Paper map of the area + baseplate compass',
        'First-aid kit + personal medicines (at least 1 week)',
        'Knife or multi-tool',
        'Duct tape + 15 m (50 ft) paracord',
        'Work gloves',
        'N95 / FFP2 masks (2–3) for smoke and dust',
        'Copies of ID, insurance and contact list in a waterproof bag',
        'Cash in small bills + spare keys',
        'Notepad and pencil',
        'Hand sanitiser, soap, toilet paper, small trowel',
        'Toothbrush, toothpaste, small towel, menstrual products',
        'Sunscreen, insect repellent, lip balm',
        '2–3 heavy-duty rubbish bags (rain cover, ground sheet)'
      ]
    },
    {
      name: 'Car emergency kit', sub: 'Stays in the vehicle',
      items: [
        'Water: 4 L (1 gal) per person — replace every 6 months',
        'Non-perishable snacks / energy bars for 1–2 days',
        'Jumper cables or charged lithium jump starter',
        '12 V tyre inflator + tyre pressure gauge',
        'Spare tyre checked + jack + wheel wrench',
        'Tyre sealant or plug kit',
        'Warning triangles (2) and/or road flares',
        'Hi-vis reflective vest (one per seat)',
        'Flashlight or headlamp + spare batteries',
        'First-aid kit',
        'Fire extinguisher (vehicle-rated), secured',
        'Blankets or sleeping bag + space blankets',
        'Warm clothes, hat, gloves and walking shoes',
        'Rain poncho',
        'Phone charging cable + 12 V adapter + power bank',
        'Paper road map / atlas',
        'Seatbelt cutter + window breaker within the driver\'s reach',
        'Multi-tool + basic tools (screwdrivers, pliers, adjustable wrench)',
        'Duct tape, zip ties, paracord',
        'Rated tow strap',
        'Work gloves',
        'Ice scraper + snow brush (winter)',
        'Small folding shovel (winter)',
        'Sand, cat litter or traction mats (winter)',
        'Whistle',
        'Emergency contacts + insurance and registration copies',
        'Cash and coins',
        'Toilet paper, wet wipes, hand sanitiser, rubbish bags',
        'Spare fuses and bulbs for this vehicle',
        'Engine oil (1 L / 1 qt), coolant, washer fluid',
        'Personal medicines',
        'Habit: keep the fuel tank at least half full'
      ]
    },
    {
      name: 'First-aid kit (compact)', sub: 'Pocket or pack size',
      items: [
        'Tourniquet (genuine CAT or SOF-T, not a copy) — know how to use it',
        'Pressure / trauma bandage',
        'Gauze for wound packing (plain or haemostatic)',
        'Sterile gauze pads, assorted',
        'Adhesive bandages / plasters, assorted',
        'Medical tape',
        'Elastic (crepe) bandage',
        'Triangular bandages / sling (2)',
        'Malleable splint (e.g. SAM splint)',
        'Wound closure strips',
        'Antiseptic wipes (chlorhexidine or iodine)',
        'Irrigation syringe (clean wounds with drinkable water)',
        'Non-stick dressings + cling film (burns)',
        'Blister dressings / moleskin',
        'Nitrile gloves (several pairs)',
        'Trauma shears',
        'Fine tweezers + tick remover',
        'CPR face shield or pocket mask',
        'Space / emergency blanket',
        'Pain relievers: paracetamol (acetaminophen) and ibuprofen — follow the label',
        'Antihistamine tablets',
        'Oral rehydration salts sachets',
        'Anti-diarrhoea tablets (loperamide)',
        'Personal prescription medicines',
        'Epinephrine auto-injector (if prescribed)',
        'Saline eye wash',
        'Safety pins',
        'Permanent marker + notepad (write down times, e.g. tourniquet)',
        'Hand sanitiser',
        'First-aid instruction card'
      ]
    },
    {
      name: 'Home power-outage kit', sub: 'Blackout at home',
      items: [
        'Water: 4 L (1 gal) per person per day, at least 3 days',
        'Food that needs no cooking for 3+ days + manual can opener',
        'Flashlight or headlamp for each person',
        'Battery lanterns (safer than candles)',
        'Spare batteries in every size you use',
        'Battery / hand-crank radio (NOAA weather radio in the US)',
        'Charged power banks + car phone charger',
        'Carbon monoxide alarm with battery backup',
        'Smoke alarms tested',
        'Fire extinguisher',
        'Cooler + ice packs / frozen water bottles',
        'Fridge and freezer thermometers',
        'Rule: keep fridge and freezer closed (fridge ≈ 4 h, full freezer ≈ 48 h)',
        'Rule: throw out chilled food above 40 °F (4 °C) for over 2 hours',
        'Warm blankets, sleeping bags, warm clothes',
        'Camp stove or grill — OUTDOORS ONLY (carbon monoxide)',
        'Generator ≥ 20 ft (6 m) from doors and windows, exhaust pointed away',
        'Transfer switch or interlock — never back-feed through an outlet',
        'Fuel stored safely in approved cans',
        'Medicines + backup power for medical devices',
        'Cash in small bills (card machines and ATMs may be down)',
        'Vehicle fuel tank kept at least half full',
        'Surge protectors / unplug electronics until power is stable',
        'Know how to open the garage door by hand',
        'Know where the gas, water and main electric shut-offs are',
        'Printed list of important phone numbers',
        'Toilet backup: bucket, heavy bags, cat litter',
        'Hand sanitiser, wet wipes, rubbish bags',
        'Pet food and water',
        'Books, cards or games',
        'Plan to check on elderly or disabled neighbours'
      ]
    }
  ];

  var lists = [];                 // in-memory copies of saved lists (sorted by created)
  var openIds = {};               // which lists are expanded
  var undo = null;                // { listId, item, index, timer } — last deleted item
  var editing = null;             // { listId, itemId } — item being edited
  var renaming = null;            // listId being renamed

  function findList(id) { for (var i = 0; i < lists.length; i++) if (lists[i].id === id) return lists[i]; return null; }

  function saveList(list) {
    list.updated = Date.now();
    if (!hasStore()) return Promise.resolve();
    return OGStore.put('checklists', list).catch(function (err) {
      toast('Could not save the list: ' + (err && err.message || err), { error: true });
    });
  }

  function loadLists() {
    if (!hasStore()) { renderLists(); return Promise.resolve(); }
    return OGStore.all('checklists').then(function (all) {
      lists = (all || []).filter(function (l) { return l && l.id; });
      lists.forEach(function (l) { if (!Array.isArray(l.items)) l.items = []; });
      lists.sort(function (a, b) { return (a.created || 0) - (b.created || 0); });
      renderLists();
    }).catch(function (err) {
      toast('Could not load saved lists: ' + (err && err.message || err), { error: true });
      renderLists();
    });
  }

  function uniqueName(name) {
    var names = lists.map(function (l) { return l.name; });
    if (names.indexOf(name) < 0) return name;
    for (var n = 2; ; n++) if (names.indexOf(name + ' (' + n + ')') < 0) return name + ' (' + n + ')';
  }

  function createList(name, items) {
    var now = Date.now();
    var list = {
      id: OGStore.uid(), name: uniqueName(name),
      items: (items || []).map(function (t) { return { id: OGStore.uid(), text: t, done: false }; }),
      created: now, updated: now
    };
    lists.push(list);
    openIds[list.id] = true;
    renderLists();
    saveList(list);
    return list;
  }

  /* Count of packed items. */
  function progress(list) {
    var done = 0;
    list.items.forEach(function (it) { if (it.done) done++; });
    return { done: done, total: list.items.length };
  }
  function progressText(list) {
    var p = progress(list);
    return p.done + ' / ' + p.total + ' packed';
  }
  function paintProgress(node, list) {
    var p = progress(list);
    $('.cl-prog', node).textContent = progressText(list);
    var bar = $('.meter', node);
    bar.setAttribute('aria-valuenow', String(p.done));
    bar.setAttribute('aria-valuemax', String(p.total));
    $('.meter > span', node).style.width = (p.total ? Math.round(p.done / p.total * 100) : 0) + '%';
  }

  function renderLists() {
    var host = $('#cl-lists');
    host.textContent = '';
    $('#cl-empty').hidden = lists.length > 0;
    $('#cl-print-all').hidden = lists.length === 0;
    lists.forEach(function (l) { host.appendChild(buildList(l)); });
  }
  /* Replace one list's DOM (keeps the rest untouched). Half-typed text in
     the "Add an item" box survives unless clearAdd is set (after adding). */
  function rerenderList(list, focusSel, clearAdd) {
    var old = $('#cl-lists .cl-list[data-id="' + list.id + '"]');
    var oldAdd = old && $('.cl-add-input', old);
    var keep = oldAdd && !clearAdd ? oldAdd.value : '';
    var node = buildList(list);
    if (keep) $('.cl-add-input', node).value = keep;
    if (old) old.replaceWith(node); else $('#cl-lists').appendChild(node);
    if (focusSel) { var f = $(focusSel, node); if (f) { try { f.focus({ preventScroll: true }); } catch (e) { f.focus(); } } }
    return node;
  }

  function buildItem(list, it) {
    if (editing && editing.listId === list.id && editing.itemId === it.id) {
      return el('li', { class: 'cl-item', 'data-iid': it.id }, [
        el('form', { class: 'cl-edit', 'data-act': 'edit-save' }, [
          el('label', { class: 'sr-only', for: 'edit-' + it.id, text: 'Item text' }),
          el('input', { type: 'text', id: 'edit-' + it.id, value: it.text, maxlength: '200', autocomplete: 'off' }),
          el('button', { class: 'btn primary', type: 'submit', text: 'Save' }),
          el('button', { class: 'btn', type: 'button', 'data-act': 'edit-cancel', text: 'Cancel' })
        ])
      ]);
    }
    var id = 'chk-' + it.id;
    return el('li', { class: 'cl-item' + (it.done ? ' done' : ''), 'data-iid': it.id }, [
      el('label', { class: 'check', for: id }, [
        el('input', { type: 'checkbox', id: id, checked: it.done, 'data-act': 'toggle' }),
        el('span', { class: 'cl-text', text: it.text })
      ]),
      el('button', { class: 'btn icon-btn no-print', type: 'button', 'data-act': 'edit', 'aria-label': 'Edit: ' + it.text, title: 'Edit', html: ICON.edit }),
      el('button', { class: 'btn icon-btn danger no-print', type: 'button', 'data-act': 'del', 'aria-label': 'Delete: ' + it.text, title: 'Delete', html: ICON.del })
    ]);
  }

  function buildList(list) {
    var p = progress(list);
    var d = el('details', { class: 'item cl-list', 'data-id': list.id, open: !!openIds[list.id] }, [
      el('summary', null, [list.name, el('span', { class: 'sub cl-prog', text: progressText(list) })])
    ]);
    var body = el('div', { class: 'body' });
    body.appendChild(el('div', { class: 'meter', role: 'progressbar', 'aria-label': 'Packed', 'aria-valuemin': '0', 'aria-valuenow': String(p.done), 'aria-valuemax': String(p.total) }, [el('span')]));
    $('span', body.firstChild).style.width = (p.total ? Math.round(p.done / p.total * 100) : 0) + '%';

    if (undo && undo.listId === list.id) {
      body.appendChild(el('div', { class: 'cl-undo no-print', role: 'status' }, [
        el('span', { text: 'Deleted “' + undo.item.text + '”' }),
        el('button', { class: 'btn', type: 'button', 'data-act': 'undo', text: 'Undo' })
      ]));
    }

    var ul = el('ul', { class: 'cl-items' });
    list.items.forEach(function (it) { ul.appendChild(buildItem(list, it)); });
    if (!list.items.length) ul.appendChild(el('li', { class: 'hint', text: 'No items yet — add one below.' }));
    body.appendChild(ul);

    var addId = 'add-' + list.id;
    body.appendChild(el('form', { class: 'cl-add no-print', 'data-act': 'add' }, [
      el('label', { class: 'sr-only', for: addId, text: 'Add an item to ' + list.name }),
      el('input', { type: 'text', id: addId, class: 'cl-add-input', maxlength: '200', placeholder: 'Add an item…', autocomplete: 'off', enterkeyhint: 'done' }),
      el('button', { class: 'btn primary', type: 'submit', text: 'Add' })
    ]));

    if (renaming === list.id) {
      var rnId = 'rn-' + list.id;
      body.appendChild(el('form', { class: 'cl-rename no-print', 'data-act': 'rename-save' }, [
        el('label', { class: 'sr-only', for: rnId, text: 'New list name' }),
        el('input', { type: 'text', id: rnId, value: list.name, maxlength: '80', autocomplete: 'off' }),
        el('button', { class: 'btn primary', type: 'submit', text: 'Save name' }),
        el('button', { class: 'btn', type: 'button', 'data-act': 'rename-cancel', text: 'Cancel' })
      ]));
    }

    body.appendChild(el('div', { class: 'row no-print' }, [
      el('button', { class: 'btn', type: 'button', 'data-act': 'rename', text: 'Rename' }),
      el('button', { class: 'btn', type: 'button', 'data-act': 'reset', text: 'Uncheck all' }),
      el('button', { class: 'btn', type: 'button', 'data-act': 'print', text: 'Print list' }),
      el('button', { class: 'btn danger', type: 'button', 'data-act': 'delete-list', text: 'Delete list' })
    ]));
    d.appendChild(body);
    d.addEventListener('toggle', function () { openIds[list.id] = d.open; });
    return d;
  }

  function addItem(list, text) {
    text = String(text || '').trim();
    if (!text) return false;
    list.items.push({ id: OGStore.uid(), text: text, done: false });
    saveList(list);
    return true;
  }

  function initChecklists() {
    // Template buttons
    var tg = $('#cl-templates');
    TEMPLATES.forEach(function (t, i) {
      tg.appendChild(el('button', { class: 'btn', type: 'button', 'data-tpl': String(i) }, [
        el('span', null, ['+ ' + t.name, el('small', { text: t.sub + ' · ' + t.items.length + ' items' })])
      ]));
    });
    tg.addEventListener('click', function (e) {
      var b = e.target.closest('[data-tpl]');
      if (!b || !hasStore()) return;
      var t = TEMPLATES[+b.getAttribute('data-tpl')];
      var list = createList(t.name, t.items);
      toast('Added “' + list.name + '” — edit it to fit your gear.');
      var node = $('#cl-lists .cl-list[data-id="' + list.id + '"]');
      if (node && node.scrollIntoView) node.scrollIntoView({ block: 'start' });
    });

    // New blank list
    $('#cl-new').addEventListener('submit', function (e) {
      e.preventDefault();
      if (!hasStore()) { toast('Storage is not available in this browser.', { error: true }); return; }
      var inp = $('#cl-new-name');
      var name = inp.value.trim();
      if (!name) { toast('Type a name for the list first.', { error: true }); inp.focus(); return; }
      var list = createList(name, []);
      inp.value = '';
      var node = $('#cl-lists .cl-list[data-id="' + list.id + '"]');
      var add = node && $('.cl-add-input', node);
      if (add) add.focus();
    });

    $('#cl-print-all').addEventListener('click', function () {
      printScope($('#checklists'), function () { $$('#cl-lists details').forEach(function (d) { d.open = true; }); });
    });

    var host = $('#cl-lists');

    // Check / uncheck: update in place (keeps focus, no re-render)
    host.addEventListener('change', function (e) {
      var cb = e.target;
      if (cb.getAttribute('data-act') !== 'toggle') return;
      var node = cb.closest('.cl-list'), list = findList(node.getAttribute('data-id'));
      var li = cb.closest('.cl-item'), iid = li.getAttribute('data-iid');
      var it = list && list.items.filter(function (x) { return x.id === iid; })[0];
      if (!it) return;
      it.done = cb.checked;
      li.classList.toggle('done', it.done);
      paintProgress(node, list);
      saveList(list);
    });

    // Forms: add item, save edit, save rename
    host.addEventListener('submit', function (e) {
      var form = e.target, act = form.getAttribute('data-act');
      e.preventDefault();
      var node = form.closest('.cl-list'), list = findList(node.getAttribute('data-id'));
      if (!list) return;
      if (act === 'add') {
        var inp = $('input', form);
        if (addItem(list, inp.value)) rerenderList(list, '.cl-add-input', true);
        else inp.focus();
      } else if (act === 'edit-save') {
        var iid = form.closest('.cl-item').getAttribute('data-iid');
        var it = list.items.filter(function (x) { return x.id === iid; })[0];
        var val = $('input', form).value.trim();
        if (it && val) { it.text = val; saveList(list); }
        editing = null;
        rerenderList(list, '.cl-item[data-iid="' + iid + '"] [data-act="edit"]');
      } else if (act === 'rename-save') {
        var nm = $('input', form).value.trim();
        if (nm) { list.name = nm; saveList(list); }
        renaming = null;
        rerenderList(list, '[data-act="rename"]');
      }
    });

    // Buttons
    host.addEventListener('click', function (e) {
      var b = e.target.closest('button[data-act]');
      if (!b) return;
      var act = b.getAttribute('data-act');
      var node = b.closest('.cl-list'), list = findList(node.getAttribute('data-id'));
      if (!list) return;
      var li = b.closest('.cl-item'), iid = li && li.getAttribute('data-iid');
      if (act === 'edit') {
        editing = { listId: list.id, itemId: iid };
        var n = rerenderList(list, '#edit-' + iid);
        var inp = $('#edit-' + iid, n); if (inp) inp.select();
      } else if (act === 'edit-cancel') {
        editing = null;
        rerenderList(list, '.cl-item[data-iid="' + iid + '"] [data-act="edit"]');
      } else if (act === 'del') {
        var idx = -1;
        list.items.forEach(function (x, i) { if (x.id === iid) idx = i; });
        if (idx < 0) return;
        if (undo) clearTimeout(undo.timer);
        var removed = list.items.splice(idx, 1)[0];
        // Offer "Undo" for 8 s; when it expires just remove the bar (no re-render, so typing isn't disturbed).
        undo = { listId: list.id, item: removed, index: idx, timer: setTimeout(function () { undo = null; $$('#cl-lists .cl-undo').forEach(function (n) { n.remove(); }); }, 8000) };
        saveList(list);
        rerenderList(list, '[data-act="undo"]');
      } else if (act === 'undo') {
        if (!undo || undo.listId !== list.id) return;
        clearTimeout(undo.timer);
        list.items.splice(Math.min(undo.index, list.items.length), 0, undo.item);
        undo = null;
        saveList(list);
        rerenderList(list, '.cl-add-input');
      } else if (act === 'rename') {
        renaming = list.id;
        var rn = rerenderList(list, '#rn-' + list.id);
        var ri = $('#rn-' + list.id, rn); if (ri) ri.select();
      } else if (act === 'rename-cancel') {
        renaming = null;
        rerenderList(list, '[data-act="rename"]');
      } else if (act === 'reset') {
        if (!list.items.some(function (x) { return x.done; })) { toast('Nothing is checked.'); return; }
        if (!confirm('Uncheck every item in “' + list.name + '”?')) return;
        list.items.forEach(function (x) { x.done = false; });
        saveList(list);
        rerenderList(list, '[data-act="reset"]');
      } else if (act === 'print') {
        printScope($('#checklists'), function () {
          document.body.classList.add('print-one');
          node.classList.add('print-this');
          node.open = true;
        });
      } else if (act === 'delete-list') {
        if (!confirm('Delete the list “' + list.name + '” and all ' + list.items.length + ' items? This cannot be undone.')) return;
        lists = lists.filter(function (l) { return l.id !== list.id; });
        delete openIds[list.id];
        if (undo && undo.listId === list.id) { clearTimeout(undo.timer); undo = null; }
        if (hasStore()) OGStore.del('checklists', list.id).catch(function (err) { toast('Could not delete: ' + err.message, { error: true }); });
        renderLists();
        toast('List deleted.');
      }
    });

    // Escape cancels an edit / rename
    host.addEventListener('keydown', function (e) {
      if (e.key !== 'Escape') return;
      var node = e.target.closest('.cl-list'), list = node && findList(node.getAttribute('data-id'));
      if (!list) return;
      if (editing || renaming === list.id) { editing = null; renaming = null; rerenderList(list); }
    });
  }

  /* =================================================================
     Printing just one section ("Print plan", "Print list")
     body.print-scope + .print-target → CSS shows only that section.
     ================================================================= */
  function clearPrintScope() {
    document.body.classList.remove('print-scope', 'print-one');
    $$('.print-target').forEach(function (n) { n.classList.remove('print-target'); });
    $$('.print-this').forEach(function (n) { n.classList.remove('print-this'); });
  }
  function printScope(section, prep) {
    clearPrintScope();
    document.body.classList.add('print-scope');
    section.classList.add('print-target');
    if (prep) prep();
    window.print();
  }
  window.addEventListener('afterprint', clearPrintScope);

  /* =================================================================
     4. RENDEZVOUS PLAN — kv "rendezvous"
     { points:[{name, mode:'wp'|'coords', wpId, coords, lat, lon, wpName, wpCat, note} ×3],
       muster, wait, contact, radio, checkin, code, separated, updated }
     ================================================================= */
  var RV_LABELS = ['Primary', 'Secondary', 'Tertiary'];
  var RV_SUGGESTED = [
    '1. If you are lost or hurt: STOP and stay where you are. Stay visible, keep warm and dry, and signal — 3 whistle blasts, pause, repeat.',
    '2. If you can travel safely: go to the PRIMARY point at the next muster time.',
    '3. If the primary is unsafe or can\'t be reached, go to the SECONDARY, then the TERTIARY.',
    '4. Before leaving any point, leave a note or mark in the agreed spot: date, time, names, where you went.',
    '5. Text the out-of-area contact: who you are with, where you are, where you are going. Texts often get through when calls don\'t.',
    '6. Radio: listen on the agreed channel at the check-in times. Use the code word. Turn the radio off between check-ins to save battery.',
    '7. Never go back into danger (fire, flood, damaged building) to look for someone. Tell rescuers instead.'
  ].join('\n');

  var rv = null;          // plan being edited
  var waypoints = [];     // from the map, for the dropdowns
  var rvTimer = 0, rvDirty = false;

  function rvBlankPoint() { return { name: '', mode: null, wpId: '', coords: '', lat: null, lon: null, wpName: '', wpCat: '', note: '' }; }
  function rvDefault() {
    return { points: [rvBlankPoint(), rvBlankPoint(), rvBlankPoint()], muster: '', wait: '', contact: '', radio: '', checkin: '', code: '', separated: RV_SUGGESTED, updated: 0 };
  }

  function catLabel(cat) {
    var C = (window.OGStore && OGStore.WAYPOINT_CATS) || {};
    return (C[cat] && C[cat].label) || C.custom && C.custom.label || 'Waypoint';
  }
  function wpById(id) { for (var i = 0; i < waypoints.length; i++) if (waypoints[i].id === id) return waypoints[i]; return null; }

  function loadWaypoints() {
    if (!hasStore()) return Promise.resolve();
    return OGStore.all('waypoints').then(function (all) {
      waypoints = (all || []).filter(function (w) { return w && w.id && isFinite(w.lat) && isFinite(w.lon); });
      // Rally points first, then by category label, then by name
      waypoints.sort(function (a, b) {
        var ra = a.cat === 'rally' ? 0 : 1, rb = b.cat === 'rally' ? 0 : 1;
        if (ra !== rb) return ra - rb;
        var ca = catLabel(a.cat), cb = catLabel(b.cat);
        if (ca !== cb) return ca < cb ? -1 : 1;
        return String(a.name || '').localeCompare(String(b.name || ''));
      });
    }).catch(function () { waypoints = []; });
  }

  /* Status line next to "Print plan". */
  function rvStatus(text, cls) {
    var s = $('#rv-saved');
    s.textContent = text;
    s.className = 'saved-ind' + (cls ? ' ' + cls : '');
  }
  function rvSaveSoon() {
    rvDirty = true;
    rvStatus('Saving…');
    clearTimeout(rvTimer);
    rvTimer = setTimeout(rvSaveNow, 500);
  }
  function rvSaveNow() {
    clearTimeout(rvTimer);
    if (!rv || !rvDirty) return Promise.resolve();
    rvDirty = false;
    rv.updated = Date.now();
    if (!hasStore()) { rvStatus('Not saved — storage unavailable', 'bad'); return Promise.resolve(); }
    return OGStore.kvSet('rendezvous', rv).then(function () {
      rvStatus('Saved ✓ ' + clockTime(), 'ok');
    }).catch(function (err) {
      rvDirty = true;
      rvStatus('Not saved!', 'bad');
      toast('Could not save the plan: ' + (err && err.message || err), { error: true });
    });
  }

  /* Which input a point uses. An explicit choice wins; otherwise whatever has
     data, otherwise "waypoint" if the map has any. */
  function ptMode(pt) {
    if (pt.mode === 'wp' || pt.mode === 'coords') return pt.mode;
    if (pt.coords) return 'coords';
    if (pt.wpId) return 'wp';
    return waypoints.length ? 'wp' : 'coords';
  }

  /* Resolve a point's position: returns {lat, lon} or null (+ error for bad text). */
  function rvResolve(pt) {
    if (pt.mode === 'wp') {
      var w = wpById(pt.wpId);
      if (w) return { lat: +w.lat, lon: +w.lon, wp: w };
      if (pt.wpId && pt.lat != null) return { lat: pt.lat, lon: pt.lon, missing: true };
      return null;
    }
    if (!pt.coords || !pt.coords.trim()) return null;
    var ll = window.OGGeo ? OGGeo.parseCoords(pt.coords) : null;
    return ll ? { lat: ll[0], lon: ll[1] } : { error: true };
  }

  function fmtPos(lat, lon) {
    var G = window.OGGeo;
    var mg = G.toMGRS(lat, lon);
    return { dd: G.formatLatLon(lat, lon, 'dd'), ddm: G.formatLatLon(lat, lon, 'ddm'), mgrs: mg ? G.spaceMGRS(mg) : 'n/a' };
  }

  function buildPointCard(i) {
    var p = 'rv' + i;
    var card = el('div', { class: 'card rv-point', 'data-i': String(i) }, [
      el('h3', null, [el('span', { class: 'num', 'aria-hidden': 'true', text: String(i + 1) }), RV_LABELS[i] + ' meeting point']),
      el('div', { class: 'field' }, [
        el('label', { for: p + '-name', text: 'Place name' }),
        el('input', { type: 'text', id: p + '-name', 'data-f': 'name', maxlength: '120', placeholder: i === 0 ? 'e.g. Front gate of Lincoln School' : (i === 1 ? 'e.g. Church car park on Main St' : 'e.g. Ranger station, Hwy 9') })
      ]),
      el('p', { id: p + '-how', class: 'hint', text: 'Location:' }),
      el('div', { class: 'seg', role: 'group', 'aria-labelledby': p + '-how' }, [
        el('button', { class: 'btn', type: 'button', 'data-mode': 'wp', 'aria-pressed': 'false', text: 'Pick a map waypoint' }),
        el('button', { class: 'btn', type: 'button', 'data-mode': 'coords', 'aria-pressed': 'false', text: 'Type coordinates' })
      ]),
      el('div', { class: 'field rv-wp' }, [
        el('label', { for: p + '-wp', text: 'Waypoint (rally points first)' }),
        el('select', { id: p + '-wp', 'data-f': 'wpId' }),
        el('p', { class: 'hint rv-nowp', hidden: true, text: 'No waypoints saved yet. Add them on the Map page, or type coordinates instead.' })
      ]),
      el('div', { class: 'field rv-co' }, [
        el('label', { for: p + '-co', text: 'Coordinates' }),
        el('input', { type: 'text', id: p + '-co', 'data-f': 'coords', autocomplete: 'off', spellcheck: 'false', autocapitalize: 'characters', placeholder: '40.7128, -74.0060  or  18T WL 83959 07523' }),
        el('p', { class: 'hint', text: 'Decimal degrees, degrees-minutes-seconds, MGRS or UTM.' }),
        el('div', { class: 'row' }, [
          el('button', { class: 'btn', type: 'button', 'data-act': 'here', text: 'Use my GPS position' }),
          el('button', { class: 'btn primary', type: 'button', 'data-act': 'savewp', text: 'Save as map waypoint' })
        ])
      ]),
      el('div', { class: 'rv-loc', 'aria-live': 'polite' }),
      el('div', { class: 'field' }, [
        el('label', { for: p + '-note', text: 'How to find it / notes' }),
        el('input', { type: 'text', id: p + '-note', 'data-f': 'note', maxlength: '200', placeholder: 'e.g. Wait under the big oak, north side' })
      ])
    ]);
    return card;
  }

  /* Fill one point card's dropdown with the current waypoints. */
  function fillWpSelect(sel, pt) {
    sel.textContent = '';
    sel.appendChild(el('option', { value: '', text: waypoints.length ? '— choose a waypoint —' : '— no waypoints saved —' }));
    var found = false;
    waypoints.forEach(function (w) {
      var o = el('option', { value: w.id, text: catLabel(w.cat) + ' — ' + (w.name || 'Unnamed') });
      if (w.id === pt.wpId) { o.selected = true; found = true; }
      sel.appendChild(o);
    });
    if (pt.wpId && !found) {
      var o2 = el('option', { value: pt.wpId, text: (pt.wpName || 'Waypoint') + ' (deleted from map)' });
      o2.selected = true;
      sel.appendChild(o2);
    }
  }

  /* Paint a point card from data (mode buttons, dropdown, location readout). */
  function paintPoint(i) {
    var card = $('.rv-point[data-i="' + i + '"]'), pt = rv.points[i];
    if (!card) return;
    var mode = ptMode(pt);
    $$('[data-mode]', card).forEach(function (b) { b.setAttribute('aria-pressed', String(b.getAttribute('data-mode') === mode)); });
    $('.rv-wp', card).hidden = mode !== 'wp';
    $('.rv-co', card).hidden = mode !== 'coords';
    fillWpSelect($('select', card), pt);
    $('.rv-nowp', card).hidden = waypoints.length > 0;
    paintLoc(i);
  }

  function paintLoc(i) {
    var card = $('.rv-point[data-i="' + i + '"]'), pt = rv.points[i];
    var loc = $('.rv-loc', card), co = $('[data-f="coords"]', card);
    var mode = ptMode(pt);
    var r = rvResolve({ mode: mode, wpId: pt.wpId, coords: pt.coords, lat: pt.lat, lon: pt.lon });
    loc.textContent = '';
    co.removeAttribute('aria-invalid');
    $('[data-act="savewp"]', card).disabled = !(r && !r.error && mode === 'coords');
    if (!r) return;
    if (r.error) {
      co.setAttribute('aria-invalid', 'true');
      loc.appendChild(el('p', { class: 'err', text: 'Can\'t read these coordinates. Try 40.7128, -74.0060 or an MGRS grid like 18T WL 83959 07523.' }));
      return;
    }
    var f = fmtPos(r.lat, r.lon);
    loc.appendChild(el('p', { class: 'okmsg', text: r.missing ? '⚠ Waypoint was deleted from the map — last known position:' : '✓ Location' }));
    loc.appendChild(el('p', { class: 'big', text: f.dd }));
    loc.appendChild(el('p', { class: 'mono', text: f.ddm }));
    loc.appendChild(el('p', { class: 'mono', text: 'MGRS ' + f.mgrs }));
    if (r.wp) {
      loc.appendChild(el('p', { class: 'hint', text: catLabel(r.wp.cat) + ': ' + (r.wp.name || 'Unnamed') }));
      loc.appendChild(el('div', { class: 'row' }, [
        el('a', { class: 'btn', href: '../map/index.html#wp=' + encodeURIComponent(r.wp.id), text: 'Show on map' }),
        el('a', { class: 'btn', href: '../map/index.html#nav=' + encodeURIComponent(r.wp.id), text: 'Navigate' })
      ]));
    }
  }

  /* Copy the resolved position into the point so the plan still prints
     (and shows a last-known position) if the waypoint is later deleted. */
  function rvSyncPoint(pt) {
    var mode = ptMode(pt);
    var r = rvResolve({ mode: mode, wpId: pt.wpId, coords: pt.coords, lat: pt.lat, lon: pt.lon });
    if (r && !r.error) {
      pt.lat = r.lat; pt.lon = r.lon;
      if (r.wp) { pt.wpName = r.wp.name || ''; pt.wpCat = r.wp.cat || ''; }
    } else if (!r || r.error) {
      if (!(mode === 'wp' && pt.wpId)) { pt.lat = null; pt.lon = null; }
    }
  }

  function paintRvAll() {
    rv.points.forEach(function (pt, i) {
      var card = $('.rv-point[data-i="' + i + '"]');
      $('[data-f="name"]', card).value = pt.name || '';
      $('[data-f="coords"]', card).value = pt.coords || '';
      $('[data-f="note"]', card).value = pt.note || '';
      paintPoint(i);
    });
    $$('[data-rv]').forEach(function (inp) { inp.value = rv[inp.getAttribute('data-rv')] || ''; });
    growTextarea();
  }

  /* Let the "If separated" box grow to fit its text (no inner scrolling). */
  function growTextarea() {
    var t = $('#rv-separated');
    if (!t) return;
    t.style.height = 'auto';
    t.style.height = (t.scrollHeight + 4) + 'px';
  }

  /* Save typed coordinates as a 'rally' waypoint, then link the point to it. */
  function rvSaveAsWaypoint(i) {
    var pt = rv.points[i];
    var r = rvResolve({ mode: 'coords', coords: pt.coords });
    if (!r || r.error) { toast('Type valid coordinates first.', { error: true }); return; }
    var now = Date.now();
    var w = {
      id: OGStore.uid(),
      name: (pt.name && pt.name.trim()) || ('Rendezvous: ' + RV_LABELS[i]),
      cat: 'rally', lat: r.lat, lon: r.lon,
      note: RV_LABELS[i] + ' meeting point (group rendezvous plan)' + (pt.note ? ' — ' + pt.note : ''),
      created: now, updated: now
    };
    OGStore.put('waypoints', w).then(function () {
      waypoints.push(w);
      return loadWaypoints();
    }).then(function () {
      pt.mode = 'wp'; pt.wpId = w.id; pt.wpName = w.name; pt.wpCat = 'rally';
      pt.lat = w.lat; pt.lon = w.lon;
      rv.points.forEach(function (_, j) { paintPoint(j); });
      rvSaveSoon();
      toast('Saved “' + w.name + '” as a rally point on the map.');
      var link = $('.rv-point[data-i="' + i + '"] .rv-loc a');
      if (link) link.focus();
    }).catch(function (err) {
      toast('Could not save the waypoint: ' + (err && err.message || err), { error: true });
    });
  }

  /* Fill typed coordinates from the phone's GPS. */
  function rvUseHere(i, btn) {
    if (!('geolocation' in navigator)) { toast('This browser has no location access.', { error: true }); return; }
    btn.disabled = true;
    var old = btn.textContent;
    btn.textContent = 'Getting GPS fix…';
    navigator.geolocation.getCurrentPosition(function (pos) {
      btn.disabled = false; btn.textContent = old;
      var pt = rv.points[i];
      pt.coords = pos.coords.latitude.toFixed(6) + ', ' + pos.coords.longitude.toFixed(6);
      pt.mode = 'coords';
      $('.rv-point[data-i="' + i + '"] [data-f="coords"]').value = pt.coords;
      rvSyncPoint(pt); paintLoc(i); rvSaveSoon();
      toast('Position filled in (±' + Math.round(pos.coords.accuracy) + ' m).');
    }, function (err) {
      btn.disabled = false; btn.textContent = old;
      toast(geoErrorText(err), { error: true });
    }, { enableHighAccuracy: true, timeout: 60000, maximumAge: 30000 });
  }

  /* Plain-text sheet for printing (form fields don't print well). */
  function buildRvSheet() {
    var host = $('#rv-sheet');
    host.textContent = '';
    if (!rv) return;
    host.appendChild(el('p', { class: 'hint', text: 'Printed ' + new Date().toLocaleString() }));
    rv.points.forEach(function (pt, i) {
      rvSyncPoint(pt);   // pick up waypoints moved on the map since
      host.appendChild(el('h3', { text: (i + 1) + '. ' + RV_LABELS[i] + ': ' + (pt.name || '(not set)') }));
      if (pt.lat != null && pt.lon != null && window.OGGeo) {
        var f = fmtPos(pt.lat, pt.lon);
        host.appendChild(el('p', { class: 'mono', text: f.dd + '   ·   ' + f.ddm }));
        host.appendChild(el('p', { class: 'mono', text: 'MGRS ' + f.mgrs }));
        if (ptMode(pt) === 'wp' && pt.wpName) host.appendChild(el('p', { text: 'Map waypoint: ' + pt.wpName + (pt.wpCat ? ' (' + catLabel(pt.wpCat) + ')' : '') }));
      } else host.appendChild(el('p', { text: 'Location: (not set)' }));
      if (pt.note) host.appendChild(el('p', { text: 'How to find it: ' + pt.note }));
    });
    function line(label, v) { host.appendChild(el('p', null, [el('strong', { text: label + ': ' }), v || '—'])); }
    host.appendChild(el('h3', { text: 'When to meet' }));
    line('Muster times', rv.muster);
    line('Wait before moving on', rv.wait);
    host.appendChild(el('h3', { text: 'Contacts & radio' }));
    line('Out-of-area contact', rv.contact);
    line('Radio channel', rv.radio);
    line('Radio check-in times', rv.checkin);
    line('Code word', rv.code);
    host.appendChild(el('h3', { text: 'If separated' }));
    host.appendChild(el('p', { class: 'pre', text: rv.separated || '—' }));
  }

  function initRendezvous() {
    var host = $('#rv-points');
    for (var i = 0; i < 3; i++) host.appendChild(buildPointCard(i));

    // Typing in point fields
    host.addEventListener('input', function (e) {
      if (!rv) return;
      var card = e.target.closest('.rv-point'), f = e.target.getAttribute('data-f');
      if (!card || !f) return;
      var i = +card.getAttribute('data-i'), pt = rv.points[i];
      pt[f] = e.target.value;
      if (f === 'coords' || f === 'wpId') {
        pt.mode = f === 'wpId' ? 'wp' : 'coords';
        rvSyncPoint(pt); paintLoc(i);
      }
      rvSaveSoon();
    });
    host.addEventListener('change', function (e) {   // <select> fires change (and input in most browsers)
      if (!rv || e.target.tagName !== 'SELECT') return;
      var i = +e.target.closest('.rv-point').getAttribute('data-i'), pt = rv.points[i];
      pt.wpId = e.target.value; pt.mode = 'wp';
      rvSyncPoint(pt); paintLoc(i); rvSaveSoon();
    });
    host.addEventListener('click', function (e) {
      if (!rv) return;
      var b = e.target.closest('button');
      if (!b) return;
      var i = +b.closest('.rv-point').getAttribute('data-i'), pt = rv.points[i];
      if (b.hasAttribute('data-mode')) {
        pt.mode = b.getAttribute('data-mode');
        rvSyncPoint(pt); paintPoint(i); rvSaveSoon();
        var target = $('.rv-point[data-i="' + i + '"] ' + (pt.mode === 'wp' ? 'select' : '[data-f="coords"]'));
        if (target) target.focus();
      } else if (b.getAttribute('data-act') === 'savewp') rvSaveAsWaypoint(i);
      else if (b.getAttribute('data-act') === 'here') rvUseHere(i, b);
    });

    // Plan-wide fields
    $$('[data-rv]').forEach(function (inp) {
      inp.addEventListener('input', function () { if (!rv) return; rv[inp.getAttribute('data-rv')] = inp.value; rvSaveSoon(); growTextarea(); });
    });
    $('#rv-reset-text').addEventListener('click', function () {
      if (!rv) return;
      if (rv.separated && rv.separated !== RV_SUGGESTED && !confirm('Replace your “If separated” text with the suggested text?')) return;
      rv.separated = RV_SUGGESTED;
      $('#rv-separated').value = RV_SUGGESTED;
      growTextarea();
      rvSaveSoon();
    });

    $('#rv-print').addEventListener('click', function () {
      rvSaveNow();
      buildRvSheet();
      printScope($('#rendezvous'));
    });
    // Whole-page print also gets an up-to-date sheet.
    window.addEventListener('beforeprint', buildRvSheet);
    // Flush a pending save when the page is hidden/closed.
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'hidden') rvSaveNow();
      else if (rv) loadWaypoints().then(function () { rv.points.forEach(function (_, j) { paintPoint(j); }); });   // came back from the map
    });
    window.addEventListener('pagehide', rvSaveNow);
  }

  function loadRendezvous() {
    var get = hasStore() ? OGStore.kvGet('rendezvous', null) : Promise.resolve(null);
    return Promise.all([get, loadWaypoints()]).then(function (r) {
      var saved = r[0], def = rvDefault();
      rv = def;
      if (saved && typeof saved === 'object') {
        Object.keys(def).forEach(function (k) { if (k !== 'points' && saved[k] !== undefined) rv[k] = saved[k]; });
        if (Array.isArray(saved.points)) saved.points.slice(0, 3).forEach(function (p, i) {
          rv.points[i] = Object.assign(rvBlankPoint(), p || {});
        });
        rvStatus(saved.updated ? 'Saved on this phone · last change ' + new Date(saved.updated).toLocaleString() : 'Saved on this phone', 'ok');
      } else rvStatus('Not saved yet — changes save automatically');
      paintRvAll();
    }).catch(function (err) {
      rv = rvDefault();
      paintRvAll();
      rvStatus('Storage unavailable — plan will not be saved', 'bad');
      console.warn(err);
    });
  }

  /* =================================================================
     5. STOPWATCH & COUNTDOWN (wall-clock based, so accurate even if
        the page was throttled for a while)
     ================================================================= */
  function fmtClock(ms, tenths) {
    ms = Math.max(0, ms);
    var totalS = Math.floor(ms / 1000), h = Math.floor(totalS / 3600), m = Math.floor((totalS % 3600) / 60), s = totalS % 60;
    var out = (h ? h + ':' + pad2(m) : pad2(m)) + ':' + pad2(s);
    if (tenths) out += '.' + Math.floor((ms % 1000) / 100);
    return out;
  }

  var sw = { running: false, start: 0, acc: 0, timer: 0, startedAt: null };
  function swElapsed() { return sw.acc + (sw.running ? Date.now() - sw.start : 0); }
  function swPaint() {
    $('#sw-clock').textContent = fmtClock(swElapsed(), true);
    $('#sw-start').textContent = sw.running ? 'Pause' : (sw.acc ? 'Resume' : 'Start');
    $('#sw-sub').textContent = sw.startedAt ? 'Started at ' + clockTime(sw.startedAt) + (sw.running ? '' : ' · paused') : '';
  }

  var cd = { running: false, end: 0, remain: 300000, total: 300000, timer: 0, done: false, flash: 0 };
  function cdSetFromInputs() {
    var m = Math.max(0, Math.min(999, parseInt($('#cd-min').value, 10) || 0));
    var s = Math.max(0, Math.min(59, parseInt($('#cd-sec').value, 10) || 0));
    cd.total = cd.remain = (m * 60 + s) * 1000;
    cd.done = false;
  }
  function cdRemaining() { return cd.running ? cd.end - Date.now() : cd.remain; }
  function cdPaint() {
    var rem = cdRemaining();
    $('#cd-clock').textContent = cd.done ? '00:00' : fmtClock(Math.ceil(Math.max(0, rem) / 1000) * 1000, false);
    $('#cd-start').textContent = cd.running ? 'Pause' : (cd.remain < cd.total && cd.remain > 0 ? 'Resume' : 'Start');
    if (cd.done) $('#cd-sub').textContent = 'Time is up — ' + clockTime();
    else if (cd.running) $('#cd-sub').textContent = 'Ends at ' + clockTime(new Date(cd.end));
    else $('#cd-sub').textContent = '';
  }
  function cdTick() {
    if (cd.running && cdRemaining() <= 0) cdFinish();
    cdPaint();
  }
  function cdFinish() {
    cd.running = false; cd.done = true; cd.remain = 0;
    clearInterval(cd.timer);
    hold('timer', false);
    beep(3);
    try { if (navigator.vibrate) navigator.vibrate([400, 200, 400, 200, 800]); } catch (e) {}
    toast('Countdown finished.');
    // Blink the display a few times (JS-driven, not a CSS animation)
    var n = 0, c = $('#cd-clock');
    clearInterval(cd.flash);
    cd.flash = setInterval(function () { c.classList.toggle('alarm'); if (++n >= 10) { clearInterval(cd.flash); c.classList.add('alarm'); } }, 400);
  }
  function cdStopFlash() { clearInterval(cd.flash); $('#cd-clock').classList.remove('alarm'); }

  function initTimer() {
    $('#sw-start').addEventListener('click', function () {
      if (sw.running) { sw.acc += Date.now() - sw.start; sw.running = false; clearInterval(sw.timer); }
      else {
        if (!sw.startedAt) sw.startedAt = new Date();
        sw.start = Date.now(); sw.running = true;
        clearInterval(sw.timer); sw.timer = setInterval(swPaint, 100);
      }
      swPaint();
    });
    $('#sw-reset').addEventListener('click', function () {
      sw.running = false; sw.acc = 0; sw.startedAt = null; clearInterval(sw.timer); swPaint();
    });

    $('#cd-start').addEventListener('click', function () {
      ensureAudio();                                   // unlock audio inside the tap (iOS) for the end beep
      cdStopFlash();
      if (cd.running) {
        cd.remain = cd.end - Date.now(); cd.running = false; clearInterval(cd.timer); hold('timer', false);
      } else {
        if (cd.done || cd.remain <= 0 || cd.remain === cd.total) cdSetFromInputs();
        if (cd.remain <= 0) { toast('Set a time first.', { error: true }); return; }
        cd.end = Date.now() + cd.remain; cd.running = true; cd.done = false;
        clearInterval(cd.timer); cd.timer = setInterval(cdTick, 250);
        hold('timer', true);
      }
      cdPaint();
    });
    $('#cd-reset').addEventListener('click', function () {
      cd.running = false; clearInterval(cd.timer); hold('timer', false); cdStopFlash();
      cdSetFromInputs(); cdPaint();
    });
    ['#cd-min', '#cd-sec'].forEach(function (s) {
      $(s).addEventListener('input', function () { if (!cd.running) { cdStopFlash(); cdSetFromInputs(); cdPaint(); } });
    });
    $('#cd-presets').addEventListener('click', function (e) {
      var b = e.target.closest('[data-min]');
      if (!b || cd.running) { if (b) toast('Pause or reset the countdown first.'); return; }
      $('#cd-min').value = b.getAttribute('data-min'); $('#cd-sec').value = 0;
      cdStopFlash(); cdSetFromInputs(); cdPaint();
    });
    // Coming back to the page: catch up immediately.
    document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'visible') { swPaint(); cdTick(); } });
    swPaint(); cdSetFromInputs(); cdPaint();
  }

  /* =================================================================
     6. GPS POSITION CARD
     ================================================================= */
  var lastFix = null;
  function geoErrorText(err) {
    if (!err) return 'Could not get a position.';
    if (err.code === 1) return 'Location permission denied. Allow location for this app in the browser or phone settings.';
    if (err.code === 2) return 'No GPS fix. Go outside, away from buildings and tree cover, and try again.';
    if (err.code === 3) return 'GPS timed out. Stay still outdoors with a clear view of the sky and try again.';
    return 'Could not get a position: ' + (err.message || err);
  }
  function showFix(pos) {
    var c = pos.coords, G = window.OGGeo;
    lastFix = { lat: c.latitude, lon: c.longitude, acc: c.accuracy, alt: c.altitude, t: pos.timestamp || Date.now() };
    var mg = G.toMGRS(c.latitude, c.longitude);
    $('#gps-mgrs').textContent = mg ? 'MGRS ' + G.spaceMGRS(mg) : G.formatLatLon(c.latitude, c.longitude, 'dd');
    var dl = $('#gps-dl');
    dl.textContent = '';
    function row(k, v) { dl.appendChild(el('dt', { text: k })); dl.appendChild(el('dd', { text: v })); }
    row('Lat, lon', G.formatLatLon(c.latitude, c.longitude, 'dd'));
    row('Deg-min', G.formatLatLon(c.latitude, c.longitude, 'ddm'));
    row('Deg-min-sec', G.formatLatLon(c.latitude, c.longitude, 'dms'));
    row('UTM', G.formatUTM(c.latitude, c.longitude));
    row('Accuracy', '± ' + Math.round(c.accuracy) + ' m (' + Math.round(c.accuracy * 3.28084) + ' ft)');
    if (c.altitude != null && !isNaN(c.altitude)) row('Altitude', Math.round(c.altitude) + ' m (' + Math.round(c.altitude * 3.28084) + ' ft) — GPS altitude is rough');
    row('Time', new Date(lastFix.t).toLocaleString());
    $('#gps-phon').textContent = mg ? 'Say it: ' + G.phonetic(G.spaceMGRS(mg)) : '';
    $('#gps-card').hidden = false;
    $('#gps-map').hidden = true;
    $('#gps-save').disabled = false;
    $('#gps-status').textContent = c.accuracy > 100 ? 'Rough fix (± ' + Math.round(c.accuracy) + ' m). Wait outdoors and tap again for a better one.' : 'Position found.';
  }
  function initGps() {
    var btn = $('#gps-get');
    if (!window.isSecureContext) $('#gps-status').textContent = 'This page is not on a secure address, so the browser may block location.';
    btn.addEventListener('click', function () {
      if (!('geolocation' in navigator)) { $('#gps-status').textContent = 'This browser has no location access.'; return; }
      btn.disabled = true;
      $('#gps-status').textContent = 'Getting a GPS fix… this can take a minute outdoors.';
      navigator.geolocation.getCurrentPosition(function (pos) {
        btn.disabled = false; btn.textContent = 'Update my position';
        showFix(pos);
      }, function (err) {
        btn.disabled = false;
        $('#gps-status').textContent = geoErrorText(err);
      }, { enableHighAccuracy: true, timeout: 90000, maximumAge: 0 });
    });
    $('#gps-save').addEventListener('click', function () {
      if (!lastFix || !hasStore()) return;
      var now = Date.now();
      var w = { id: OGStore.uid(), name: 'My position ' + clockTime(new Date(lastFix.t)), cat: 'custom', lat: lastFix.lat, lon: lastFix.lon, note: 'Saved from GPS position card (± ' + Math.round(lastFix.acc) + ' m)', created: now, updated: now };
      if (lastFix.alt != null && !isNaN(lastFix.alt)) w.alt = lastFix.alt;
      OGStore.put('waypoints', w).then(function () {
        toast('Saved “' + w.name + '” to the map.');
        $('#gps-save').disabled = true;
        var a = $('#gps-map'); a.href = '../map/index.html#wp=' + encodeURIComponent(w.id); a.hidden = false;
        loadWaypoints().then(function () { if (rv) rv.points.forEach(function (_, j) { paintPoint(j); }); });
      }).catch(function (err) { toast('Could not save: ' + (err && err.message || err), { error: true }); });
    });
  }

  /* =================================================================
     7. LIGHTNING — flash-to-bang distance + 30-minute all-clear
        (US National Weather Service: "When thunder roars, go indoors";
        under 30 s flash-to-bang = close enough to strike; wait 30 min
        after the LAST thunder). kv "tools.lightning" {log, lastThunder}
     ================================================================= */
  var LTG_S_PER_MI = 5, LTG_S_PER_KM = 3;   // rule of thumb: ~5 s per mile, ~3 s per km
  var LTG_DANGER_S = 30;                    // under 30 s: shelter now
  var LTG_CLEAR_MS = 30 * 60000;            // all-clear 30 min after the last thunder
  var LTG_MAX_S = 120;                      // no thunder 2 min after a flash: drop the count
  var LTG_LOG_MAX = 10;
  var LTG_TREND_S = 2;                      // hand timing is ±1 s: need a 2 s change to call a trend
  var ltg = { flashAt: 0, timer: 0, log: [], lastThunder: 0, clearTimer: 0, clearDone: false };

  function ltgFmt(x) { return x < 10 ? x.toFixed(1) : String(Math.round(x)); }
  function ltgSave() {
    if (hasStore()) OGStore.kvSet('tools.lightning', { log: ltg.log, lastThunder: ltg.lastThunder }).catch(function () { /* non-critical */ });
  }
  function ltgClearRunning() { return !!ltg.lastThunder && Date.now() < ltg.lastThunder + LTG_CLEAR_MS; }
  /* One wake-lock hold covers both the flash count and the all-clear countdown. */
  function ltgWake() { hold('lightning', !!ltg.flashAt || ltgClearRunning()); }

  function ltgFlash() {
    ensureAudio();                             // unlock audio inside the tap, for the all-clear beep
    ltg.flashAt = Date.now();
    clearInterval(ltg.timer);
    ltg.timer = setInterval(ltgTick, 100);
    $('#ltg-flash').setAttribute('aria-pressed', 'true');
    $('#ltg-res').textContent = 'Counting… tap THUNDER when you hear it.';
    ltgTick();
    ltgWake();
  }
  function ltgStopCount() {
    ltg.flashAt = 0;
    clearInterval(ltg.timer);
    $('#ltg-flash').setAttribute('aria-pressed', 'false');
    ltgWake();
  }
  function ltgTick() {
    if (!ltg.flashAt) return;
    var s = (Date.now() - ltg.flashAt) / 1000;
    if (s > LTG_MAX_S) {
      ltgStopCount();
      $('#ltg-count').textContent = '0.0 s';
      $('#ltg-res').textContent = 'No thunder within 2 minutes — count cancelled. Tap FLASH at the next lightning.';
      return;
    }
    $('#ltg-count').textContent = s.toFixed(1) + ' s';
  }

  function ltgThunder() {
    ensureAudio();
    var now = Date.now();
    if (ltg.flashAt) {
      var s = Math.round((now - ltg.flashAt) / 100) / 10;
      ltgStopCount();
      ltg.log.unshift({ t: now, s: s });
      ltg.log = ltg.log.slice(0, LTG_LOG_MAX);
      $('#ltg-count').textContent = s.toFixed(1) + ' s';
      $('#ltg-res').textContent = s.toFixed(1) + ' s ≈ ' + ltgFmt(s / LTG_S_PER_MI) + ' mi / ' + ltgFmt(s / LTG_S_PER_KM) + ' km away';
      ltgVerdict(s);
    } else {
      $('#ltg-res').textContent = 'Thunder heard — the 30-minute clock restarted. Tap FLASH at the next lightning to measure the distance.';
      ltgVerdict(null);
    }
    // Every thunder (measured or not) restarts the 30-minute all-clear.
    ltg.lastThunder = now;
    ltg.clearDone = false;
    ltgStartClear();
    ltgPaintLog();
    ltgSave();
  }

  /* s = flash-to-bang seconds, or null when thunder was heard without a count. */
  function ltgVerdict(s) {
    var v = $('#ltg-verdict'), danger = s != null && s < LTG_DANGER_S;
    v.className = 'callout ' + (danger ? 'danger' : 'warn');
    v.setAttribute('data-level', danger ? 'danger' : 'warn');
    v.textContent = '';
    v.appendChild(el('strong', { class: 'callout-title', text: danger ? 'Danger — get to safety now' : 'Storm in range — prepare to move to shelter' }));
    v.appendChild(el('p', { text: danger
      ? 'Under 30 seconds: the storm is close enough to strike you. Get inside a building or a hard-topped metal vehicle now.'
      : 'Any thunder you can hear means you are within striking distance — lightning can strike 10 miles (16 km) from a storm. Start moving to shelter now; don\'t wait for it to get closer.' }));
    v.hidden = false;
  }

  function ltgStartClear() {
    clearInterval(ltg.clearTimer);
    ltg.clearTimer = setInterval(ltgClearTick, 500);
    ltgClearTick();
    ltgWake();
  }
  function ltgClearTick() {
    var clock = $('#ltg-clear'), sub = $('#ltg-clear-sub');
    if (!ltg.lastThunder) {
      clearInterval(ltg.clearTimer);
      clock.textContent = '--:--';
      sub.textContent = 'Starts with the first THUNDER tap and restarts with every thunder.';
      return;
    }
    var end = ltg.lastThunder + LTG_CLEAR_MS, rem = end - Date.now();
    if (rem > 0) {
      clock.textContent = fmtClock(Math.ceil(rem / 1000) * 1000, false);
      clock.classList.remove('alarm');
      sub.textContent = 'Safe to resume at ' + clockTime(new Date(end)) + ' — restarts with each thunder. Last thunder ' + clockTime(new Date(ltg.lastThunder)) + '.';
      return;
    }
    clearInterval(ltg.clearTimer);
    clock.textContent = '00:00';
    sub.textContent = '30 minutes since the last thunder (' + clockTime(new Date(ltg.lastThunder)) + '). If you have heard no thunder since, you can go back outside.';
    if (!ltg.clearDone) {
      ltg.clearDone = true;
      beep(2);
      try { if (navigator.vibrate) navigator.vibrate([300, 150, 300]); } catch (e) {}
      toast('Lightning all-clear: 30 minutes since the last thunder.');
    }
    ltgWake();
  }

  /* Compare the newest count with the previous one or two. */
  function ltgTrend() {
    var L = ltg.log;
    if (L.length < 2 || L[0].t - L[1].t > LTG_CLEAR_MS) return '';
    var prev = L.slice(1, 3), avg = prev.reduce(function (a, x) { return a + x.s; }, 0) / prev.length;
    if (L[0].s <= avg - LTG_TREND_S) return 'Getting closer — the counts are going down. Get to shelter now.';
    if (L[0].s >= avg + LTG_TREND_S) return 'Moving away — the counts are going up. Stay sheltered until 30 minutes after the last thunder.';
    return 'About the same distance as before.';
  }
  function ltgPaintLog() {
    var ol = $('#ltg-log');
    ol.textContent = '';
    ltg.log.forEach(function (x) {
      ol.appendChild(el('li', null, [
        el('span', { text: clockTime(new Date(x.t)) }),
        el('b', { text: x.s.toFixed(1) + ' s' }),
        el('span', { text: '≈ ' + ltgFmt(x.s / LTG_S_PER_MI) + ' mi / ' + ltgFmt(x.s / LTG_S_PER_KM) + ' km' })
      ]));
    });
    var tr = ltgTrend(), p = $('#ltg-trend');
    p.textContent = tr || (ltg.log.length ? 'Measure a few more strikes to see if the storm is coming closer.' : 'Each FLASH → THUNDER count is listed here, newest first.');
    p.className = tr && /closer/.test(tr) ? 'err' : 'hint';
  }

  function initLightning() {
    $('#ltg-flash').addEventListener('click', ltgFlash);
    $('#ltg-thunder').addEventListener('click', ltgThunder);
    $('#ltg-reset').addEventListener('click', function () {
      if (ltgClearRunning() && !confirm('Stop the 30-minute all-clear timer and clear the counts?')) return;
      ltgStopCount();
      ltg.log = []; ltg.lastThunder = 0; ltg.clearDone = false;
      $('#ltg-count').textContent = '0.0 s';
      $('#ltg-res').textContent = 'Tap FLASH when you see lightning.';
      $('#ltg-verdict').hidden = true;
      ltgClearTick(); ltgPaintLog(); ltgWake(); ltgSave();
    });
    // Timers are throttled while hidden: catch up when the page comes back.
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') { ltgTick(); if (ltg.lastThunder) ltgClearTick(); }
    });
    ltgPaintLog();
    if (!hasStore()) return;
    // Resume a running all-clear after a reload (no beep if it already ended while closed).
    OGStore.kvGet('tools.lightning', null).then(function (d) {
      if (!d || typeof d !== 'object') return;
      ltg.log = Array.isArray(d.log) ? d.log.filter(function (x) { return x && isFinite(x.t) && isFinite(x.s); }).slice(0, LTG_LOG_MAX) : [];
      ltg.lastThunder = +d.lastThunder || 0;
      ltg.clearDone = !ltgClearRunning();
      if (ltgClearRunning()) ltgStartClear(); else ltgClearTick();
      ltgPaintLog();
    });
  }

  /* =================================================================
     Boot
     ================================================================= */
  function init() {
    initLight();
    initSound();
    initChecklists();
    initRendezvous();
    initTimer();
    initLightning();
    initGps();

    // The page "Print this page" button prints everything: drop any single-section scope first.
    $$('[data-print]').forEach(function (b) { b.addEventListener('click', clearPrintScope, true); });

    if (!hasStore()) {
      toast('Storage is not available — lists and plans cannot be saved in this browser.', { error: true });
      renderLists();
      loadRendezvous();
      return;
    }
    OGStore.kvGet('tools.prefs', null).then(function (p) {
      if (p && typeof p === 'object') Object.keys(prefs).forEach(function (k) { if (p[k] !== undefined) prefs[k] = p[k]; });
      if (['square', 'sawtooth', 'sine'].indexOf(prefs.wave) < 0) prefs.wave = 'square';
      if (prefs.color !== 'white' && prefs.color !== 'red') prefs.color = 'white';
      if (prefs.colorRed !== 'white' && prefs.colorRed !== 'red') prefs.colorRed = 'red';
      prefs.unit = Math.max(120, Math.min(600, +prefs.unit || 250));
      prefs.vol = Math.max(10, Math.min(100, +prefs.vol || 100));
      applyLightPrefs();
      paintSound();
    });
    loadLists();
    loadRendezvous();
    if (OGStore.persist) OGStore.persist();   // ask the browser not to evict saved data
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
