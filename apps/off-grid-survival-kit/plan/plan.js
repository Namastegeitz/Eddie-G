/* =====================================================================
   Off-Grid Survival Kit — Trip Plan & Turnaround  (plan/index.html)
   ---------------------------------------------------------------------
   1. Trip plan ("leave a note")   IndexedDB kv "tripplan"
        party, route, times, call-for-help time, vehicle, gear, comms,
        chosen map waypoints → plain-text plan + QR, copy / share / print,
        "back safely" (copies kept in kv "tripplan.history")
   2. Time & turnaround planner    kv "tripplan.planner"
        Naismith's rule × pace + breaks, saved tracks, SunCalc sunset /
        civil dusk → finish margin, turnaround time / latest start
   3. Turnaround alarm             kv "tripplan.alarm"
        countdown with screen wake lock, Web Audio alarm, vibration,
        notification; resumes when the page is reopened
   All times are shown in the device's local time zone.
   Everything runs offline; nothing ever leaves the device unless the
   user copies, shares or prints it.
   Depends on: common.js (OGSK), store.js (OGStore), geo.js (OGGeo),
               vendor/mgrs.min.js, vendor/suncalc.js, vendor/qrcode.js
   ===================================================================== */
(function () {
  'use strict';

  /* =================================================================
     Small helpers
     ================================================================= */
  function $(sel, root) { return (root || document).querySelector(sel); }
  function $$(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  /* Build a DOM element. Children that are strings are inserted as text
     (never parsed as HTML), so user data can't inject markup. */
  function el(tag, attrs, kids) {
    var e = document.createElement(tag);
    if (attrs) Object.keys(attrs).forEach(function (k) {
      var v = attrs[k];
      if (v == null || v === false) return;
      if (k === 'class') e.className = v;
      else if (k === 'text') e.textContent = v;
      else if (k === 'value') e.value = v;
      else if (k === 'checked') e.checked = !!v;
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
  /* Number from an input ("12,5" accepted); NaN if empty/invalid. */
  function num(v) {
    var s = String(v == null ? '' : v).trim().replace(',', '.');
    if (!s) return NaN;
    var n = parseFloat(s);
    return isFinite(n) ? n : NaN;
  }
  /* Round minutes UP (conservative); the epsilon absorbs float noise like 223.99999. */
  function ceilMin(x) { return Math.max(0, Math.ceil(x - 1e-6)); }
  function clip(s, n) { s = String(s || ''); return s.length > n ? s.slice(0, Math.max(0, n - 3)).trim() + '...' : s; }

  var MIN = 60000, HOUR = 3600000;
  var KM_PER_MI = 1.609344, FT_PER_M = 3.28084;

  /* =================================================================
     Dates & times — always the device's local time zone
     ================================================================= */
  var TZ = (function () { try { return Intl.DateTimeFormat().resolvedOptions().timeZone || ''; } catch (e) { return ''; } })();

  function valid(d) { return d instanceof Date && !isNaN(d.getTime()); }
  /* "YYYY-MM-DDTHH:MM[:SS]" (datetime-local value) → local Date, or null */
  function parseLocal(s) {
    var m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?/.exec(s || '');
    if (!m) return null;
    var d = new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +(m[6] || 0));
    return valid(d) ? d : null;
  }
  function toDateInput(d) { return d.getFullYear() + '-' + pad2(d.getMonth() + 1) + '-' + pad2(d.getDate()); }
  function toTimeInput(d) { return pad2(d.getHours()) + ':' + pad2(d.getMinutes()); }
  function toLocalInput(d, secs) { return toDateInput(d) + 'T' + toTimeInput(d) + (secs && d.getSeconds() ? ':' + pad2(d.getSeconds()) : ''); }
  function sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }

  var NBSP = '\u00a0';                // keeps "01:22 PM" / "4 h 22 min" on one line on screen
  function fmtTime(d) {
    var s;
    try { s = d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' }); } catch (e) { s = toTimeInput(d); }
    return s.replace(/\s/g, NBSP);
  }
  function fmtDay(d) { try { return d.toLocaleDateString(undefined, { weekday: 'short', day: 'numeric', month: 'short' }); } catch (e) { return toDateInput(d); } }
  /* Full date + time; with tz=true the zone is named so a contact elsewhere can't misread it. */
  function fmtDT(d, tz) {
    var o = { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' };
    if (tz) o.timeZoneName = 'short';
    try { return d.toLocaleString(undefined, o); } catch (e) { return d.toString(); }
  }
  /* Time of day, prefixed with the day when it isn't on the reference day. */
  function fmtWhen(d, ref) { return ref && sameDay(d, ref) ? fmtTime(d) : fmtDay(d) + ', ' + fmtTime(d); }
  /* 262 → "4 h 22 min" */
  function fmtDur(min) {
    min = Math.round(min);
    var neg = min < 0; min = Math.abs(min);
    var h = Math.floor(min / 60), m = min % 60;
    return (neg ? '−' : '') + (h ? h + NBSP + 'h' + NBSP + pad2(m) + NBSP + 'min' : m + NBSP + 'min');
  }
  function fmtHMS(ms) {
    var s = Math.max(0, Math.ceil(ms / 1000)), h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
    return (h ? h + ':' + pad2(m) : pad2(m)) + ':' + pad2(s % 60);
  }

  /* Copy text to the clipboard (falls back to execCommand on old/insecure pages). */
  function copyText(text, okMsg) {
    function fallback() {
      var ta = el('textarea', { value: text, readonly: true, style: 'position:fixed;top:0;left:0;opacity:0' });
      document.body.appendChild(ta); ta.select();
      var ok = false;
      try { ok = document.execCommand('copy'); } catch (e) { ok = false; }
      ta.remove();
      toast(ok ? (okMsg || 'Copied') : 'Copy failed — select the text and copy it by hand.', { error: !ok });
    }
    if (navigator.clipboard && navigator.clipboard.writeText && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(function () { toast(okMsg || 'Copied'); }, fallback);
    } else fallback();
  }

  /* Native share sheet. Works offline on many phones (Bluetooth / Nearby Share / AirDrop / SMS). */
  function shareText(title, text) {
    if (!navigator.share) { copyText(text); return; }
    navigator.share({ title: title, text: text }).catch(function (err) {
      if (err && err.name === 'AbortError') return;   // user closed the sheet
      toast('Could not open the share sheet — copied the text instead.');
      copyText(text);
    });
  }

  /* Screen wake lock: OGSK.wakeLock is reference counted, so keep one hold per feature. */
  var holds = {};
  function hold(name, on) {
    on = !!on;
    if (!!holds[name] === on) return;
    holds[name] = on;
    if (!window.OGSK || !OGSK.wakeLock) return;
    if (on) OGSK.wakeLock.request(); else OGSK.wakeLock.release();
  }

  function catLabel(cat) {
    var C = (window.OGStore && OGStore.WAYPOINT_CATS) || {};
    return (C[cat] && C[cat].label) || (C.custom && C.custom.label) || 'Waypoint';
  }

  /* =================================================================
     1. TRIP PLAN — kv "tripplan"
     ================================================================= */
  var GEAR = [
    ['shelter', 'Shelter / tent'], ['sleep', 'Sleeping bag'], ['stove', 'Stove'], ['food', 'Extra food'],
    ['water', 'Water filter / purification'], ['firstaid', 'First-aid kit'], ['light', 'Headlamp + spare batteries'],
    ['layers', 'Extra layers / rain gear'], ['map', 'Map + compass'], ['gps', 'GPS / phone + power bank'],
    ['plb', 'PLB / satellite messenger'], ['radio', 'Two-way radio'], ['whistle', 'Whistle'],
    ['mirror', 'Signal mirror'], ['bearspray', 'Bear spray']
  ];
  var ACTIVITY = { hike: 'Day hike', backpack: 'Backpacking (overnight)', hunt: 'Hunting', paddle: 'Paddling', drive: 'Drive / overland', other: 'Other' };
  var DEFAULT_CALL = '911 (US) / 112 (EU)';
  var OVERDUE_SLACK_H = 3;           // default call-for-help time = expected back + 3 h
  var HIST_MAX = 5;                  // completed plans kept as copies
  var QR_MAX_BYTES = 1600;           // ≈ QR version 29 at level L (133 modules) — still scans from a phone screen or A4 print
  var QR_ECC = 'L';                  // screens and fresh prints are clean: favour capacity over damage tolerance

  var tp = null;                     // the plan being edited
  var history = [];                  // [{doneAt, text}]
  var waypoints = [];                // saved map waypoints
  var saveTimer = 0, dirty = false, renderTimer = 0;

  function blankPerson() { return { name: '', age: '', phone: '', medical: '' }; }
  function tpDefault() {
    return {
      party: [blankPerson()], activity: 'hike', activityOther: '', destination: '', trailhead: '', route: '',
      start: '', ret: '', overdue: '', overdueAuto: true, callWho: DEFAULT_CALL, ranger: '',
      vehicle: { make: '', colour: '', plate: '', parked: '' },
      gear: [], gearOther: '', colours: '', phones: '', satId: '', radio: '', checkins: '',
      wps: [],                       // snapshots {id, name, cat, lat, lon} so the plan survives a deleted waypoint
      status: 'active', doneAt: 0, updated: 0
    };
  }

  function getPath(obj, path) { return path.split('.').reduce(function (o, k) { return o == null ? undefined : o[k]; }, obj); }
  function setPath(obj, path, v) {
    var ks = path.split('.'), o = obj;
    for (var i = 0; i < ks.length - 1; i++) { if (!o[ks[i]] || typeof o[ks[i]] !== 'object') o[ks[i]] = {}; o = o[ks[i]]; }
    o[ks[ks.length - 1]] = v;
  }

  /* ---------- saving ---------- */
  function savedStatus(text, cls) {
    var s = $('#tp-saved');
    s.textContent = text;
    s.className = 'saved-ind' + (cls ? ' ' + cls : '');
  }
  function saveSoon() {
    dirty = true;
    savedStatus('Saving…');
    clearTimeout(saveTimer);
    saveTimer = setTimeout(saveNow, 400);
    renderSoon();
  }
  function saveNow() {
    clearTimeout(saveTimer);
    if (!tp || !dirty) return Promise.resolve();
    dirty = false;
    tp.updated = Date.now();
    if (!hasStore()) { savedStatus('Not saved — storage unavailable', 'bad'); return Promise.resolve(); }
    return OGStore.kvSet('tripplan', tp).then(function () {
      savedStatus('Saved ✓ ' + fmtTime(new Date()), 'ok');
    }).catch(function (err) {
      dirty = true;
      savedStatus('Not saved!', 'bad');
      toast('Could not save the plan: ' + (err && err.message || err), { error: true });
    });
  }

  /* ---------- party ---------- */
  function partyField(id, label, key, value, attrs) {
    var a = Object.assign({ type: 'text', id: id, 'data-pk': key, value: value || '', autocomplete: 'off' }, attrs || {});
    return el('div', { class: 'field' }, [el('label', { for: id, text: label }), el('input', a)]);
  }
  function renderParty(focusIdx) {
    var host = $('#party');
    host.textContent = '';
    tp.party.forEach(function (p, i) {
      var id = 'pp' + i;
      host.appendChild(el('div', { class: 'person', 'data-i': String(i) }, [
        el('div', { class: 'person-head' }, [
          el('h4', { text: 'Person ' + (i + 1) }),
          el('button', { class: 'btn', type: 'button', 'data-act': 'del', 'aria-label': 'Remove person ' + (i + 1), text: 'Remove' })
        ]),
        partyField(id + '-name', 'Name', 'name', p.name, { maxlength: '80', placeholder: 'Full name' }),
        el('div', { class: 'pair' }, [
          partyField(id + '-age', 'Age', 'age', p.age, { maxlength: '3', inputmode: 'numeric' }),
          partyField(id + '-phone', 'Phone', 'phone', p.phone, { maxlength: '40', inputmode: 'tel', placeholder: 'e.g. +1 555 0101' })
        ]),
        partyField(id + '-med', 'Medical notes / allergies', 'medical', p.medical, { maxlength: '300', placeholder: 'e.g. Asthma (inhaler in lid pocket), penicillin allergy' })
      ]));
    });
    if (focusIdx != null) { var f = $('#pp' + focusIdx + '-name'); if (f) f.focus(); }
  }
  function people() {
    return tp.party.filter(function (p) { return p && (p.name || p.age || p.phone || p.medical); });
  }

  /* ---------- gear chips ---------- */
  function renderGear() {
    var host = $('#gear');
    host.textContent = '';
    GEAR.forEach(function (g) {
      host.appendChild(el('button', { class: 'btn', type: 'button', 'data-gear': g[0], 'aria-pressed': String(tp.gear.indexOf(g[0]) >= 0), text: g[1] }));
    });
    paintGearRadio();
  }
  function paintGearRadio() { $('#gear-radio-f').hidden = tp.gear.indexOf('radio') < 0; }

  /* ---------- waypoints to include ---------- */
  function wpById(id) { for (var i = 0; i < waypoints.length; i++) if (waypoints[i].id === id) return waypoints[i]; return null; }
  function loadWaypoints() {
    if (!hasStore()) return Promise.resolve();
    return OGStore.all('waypoints').then(function (all) {
      waypoints = (all || []).filter(function (w) { return w && w.id && isFinite(w.lat) && isFinite(w.lon); });
      // camps and rally points first (most useful in a trip plan), then by name
      var rank = { camp: 0, rally: 1 };
      waypoints.sort(function (a, b) {
        var ra = rank[a.cat] != null ? rank[a.cat] : 2, rb = rank[b.cat] != null ? rank[b.cat] : 2;
        if (ra !== rb) return ra - rb;
        return String(a.name || '').localeCompare(String(b.name || ''));
      });
    }).catch(function () { waypoints = []; });
  }
  function snapWp(w) { return { id: w.id, name: w.name || '', cat: w.cat || 'custom', lat: +w.lat, lon: +w.lon }; }
  /* Pick up waypoints that were renamed or moved on the map since they were chosen. */
  function syncWpSnapshots() {
    var changed = false;
    tp.wps = tp.wps.map(function (s) {
      var w = wpById(s.id);
      if (!w) return s;
      var n = snapWp(w);
      if (n.name !== s.name || n.lat !== s.lat || n.lon !== s.lon || n.cat !== s.cat) changed = true;
      return n;
    });
    return changed;
  }
  function renderWps() {
    var ul = $('#wp-pick');
    ul.textContent = '';
    var list = waypoints.slice();
    tp.wps.forEach(function (s) { if (!wpById(s.id)) list.push(Object.assign({ deleted: true }, s)); });
    $('#wp-none').hidden = list.length > 0;
    list.forEach(function (w) {
      var id = 'wp-' + w.id;
      var on = tp.wps.some(function (s) { return s.id === w.id; });
      ul.appendChild(el('li', null, [el('label', { class: 'check' }, [
        el('input', { type: 'checkbox', id: id, 'data-wp': w.id, checked: on }),
        el('span', null, [
          (w.name || 'Unnamed') + (w.deleted ? ' (deleted from map — last known position)' : ''),
          el('span', { class: 'sub', text: catLabel(w.cat) + ' · ' + (window.OGGeo ? OGGeo.formatLatLon(+w.lat, +w.lon, 'dd') : w.lat + ', ' + w.lon) })
        ])
      ])]));
    });
  }

  /* ---------- simple bound fields (data-k="path") ---------- */
  function fillFields() {
    $$('[data-k]').forEach(function (inp) {
      var v = getPath(tp, inp.getAttribute('data-k'));
      inp.value = v == null ? '' : v;
    });
    paintActivity();
    paintTimeErr();
  }
  function paintActivity() { $('#tp-activity-other-f').hidden = tp.activity !== 'other'; }
  function autoOverdue() {
    var r = parseLocal(tp.ret);
    return r ? toLocalInput(new Date(r.getTime() + OVERDUE_SLACK_H * HOUR)) : '';
  }
  /* Sanity-check the three times. */
  function paintTimeErr() {
    var s = parseLocal(tp.start), r = parseLocal(tp.ret), o = parseLocal(tp.overdue), msg = '';
    if (s && r && r <= s) msg = 'Expected back is not after the start time.';
    else if (r && o && o < r) msg = 'The call-for-help time is before the expected return — your contact would call while you are still on schedule.';
    var e = $('#tp-time-err');
    e.textContent = msg;
    e.hidden = !msg;
  }
  function onFieldInput(e) {
    var inp = e.target, k = inp.getAttribute && inp.getAttribute('data-k');
    if (!tp || !k) return;
    if (getPath(tp, k) === inp.value) return;        // input + change both fire: handle once
    setPath(tp, k, inp.value);
    // keep twin fields (radio channel appears twice) in step
    $$('[data-k="' + k + '"]').forEach(function (o) { if (o !== inp) o.value = inp.value; });
    if (k === 'ret' && tp.overdueAuto) { tp.overdue = autoOverdue(); $('#tp-overdue').value = tp.overdue; }
    if (k === 'overdue') tp.overdueAuto = false;     // the user chose their own time
    if (k === 'activity') paintActivity();
    if ((k === 'start' || k === 'ret' || k === 'overdue') && tp.status === 'done' && inp.value) {
      tp.status = 'active'; tp.doneAt = 0;          // new dates = a new trip
      paintDone();
      toast('New trip — the plan is active again.');
    }
    paintTimeErr();
    saveSoon();
  }

  /* ---------- the plain-text plan ---------- */
  function activityText() {
    if (tp.activity === 'other') return (tp.activityOther || '').trim() || 'Trip';
    return ACTIVITY[tp.activity] || 'Trip';
  }
  function callWho() {
    var w = (tp.callWho || '').trim() || DEFAULT_CALL;
    if (tp.ranger && tp.ranger.trim()) w += ' (or local ranger / SAR: ' + tp.ranger.trim() + ')';
    return w;
  }
  function gearText() {
    var g = GEAR.filter(function (x) { return tp.gear.indexOf(x[0]) >= 0; }).map(function (x) {
      return x[0] === 'radio' && tp.radio ? x[1] + ' (' + tp.radio + ')' : x[1];
    });
    if (tp.gearOther && tp.gearOther.trim()) g.push(tp.gearOther.trim());
    return g.join(', ');
  }
  function vehicleText() {
    var v = tp.vehicle || {};
    var s = [v.colour, v.make].filter(function (x) { return x && x.trim(); }).join(' ');
    if (v.plate) s += (s ? ', ' : '') + 'plate ' + v.plate;
    return s;
  }
  function indent(text) { return String(text).split(/\r?\n/).map(function (l) { return '   ' + l; }).join('\n'); }
  function wpLines() {
    return tp.wps.map(function (w) {
      var G = window.OGGeo, mg = G ? G.toMGRS(w.lat, w.lon) : null;
      return '- ' + (w.name || 'Unnamed') + ' (' + catLabel(w.cat) + '): ' +
        (G ? G.formatLatLon(w.lat, w.lon, 'dd') : w.lat + ', ' + w.lon) + (mg ? ', MGRS ' + G.spaceMGRS(mg) : '');
    });
  }
  function overdueText() { var o = parseLocal(tp.overdue); return o ? fmtDT(o, true) : '[TIME NOT SET]'; }

  function buildSummary() {
    var L = [], start = parseLocal(tp.start), ret = parseLocal(tp.ret), done = tp.status === 'done';
    var odText = overdueText(), who = callWho();
    function sec(title, lines) {
      lines = lines.filter(Boolean);
      if (!lines.length) return;
      L.push('', title);
      lines.forEach(function (l) { L.push(l); });
    }
    L.push('TRIP PLAN - ' + activityText() + (tp.destination ? ': ' + tp.destination.trim() : ''));
    if (done) L.push('', '*** TRIP FINISHED - back safely ' + fmtDT(new Date(tp.doneAt), true) + '. No action needed. ***');
    else L.push('', '>>> IF WE ARE NOT BACK BY ' + odText + ', CALL ' + who + ' AND GIVE THEM THIS PLAN. DO NOT WAIT. <<<');

    var ps = people();
    sec('PARTY (' + ps.length + ')', ps.length ? ps.map(function (p, i) {
      var bits = [(p.name || '').trim() || '(name not given)'];
      if (p.age) bits.push('age ' + p.age);
      if (p.phone) bits.push('phone ' + p.phone);
      return (i + 1) + '. ' + bits.join(', ') + (p.medical ? '\n   Medical / allergies: ' + p.medical : '');
    }) : ['(no names given)']);
    sec('WHEN', [
      'Start: ' + (start ? fmtDT(start, true) : '[not set]'),
      'Expected back: ' + (ret ? fmtDT(ret, true) : '[not set]'),
      done ? null : 'Call for help if not back by: ' + odText
    ]);
    sec('WHERE', [
      'Activity: ' + activityText(),
      tp.destination && 'Destination / area: ' + tp.destination,
      tp.trailhead && 'Trailhead / put-in: ' + tp.trailhead,
      tp.route && 'Route (start, planned route, alternates, camps):\n' + indent(tp.route)
    ]);
    sec('VEHICLE', [vehicleText(), tp.vehicle && tp.vehicle.parked && 'Parked at: ' + tp.vehicle.parked]);
    sec('GEAR', [gearText(), tp.colours && 'Colours (clothing / pack / tent): ' + tp.colours]);
    sec('COMMUNICATIONS', [
      tp.phones && 'Phones: ' + tp.phones,
      tp.satId && 'Satellite messenger / PLB: ' + tp.satId,
      tp.radio && 'Radio: ' + tp.radio,
      tp.checkins && 'Check-ins: ' + tp.checkins
    ]);
    sec('MAP POINTS', wpLines());
    if (!done) sec('INSTRUCTIONS FOR OUR CONTACT', [
      'If we are not back by ' + odText + ', call ' + who + ' and give them this plan. Do not wait.',
      'Tell them: our names and medical notes, the route and map points, the vehicle and where it is parked, our gear and colours, and when you last heard from us.',
      'Keep your phone on and nearby until we are found.'
    ]);
    L.push('', 'Plan written ' + fmtDT(new Date(tp.updated || Date.now()), true) + (TZ ? ' (times in ' + TZ + ')' : '') + ' - Off-Grid Survival Kit');
    return L.join('\n');
  }

  /* Shortened plan for the QR code: names, route, vehicle, times, overdue action.
     routeMax limits the route text so it fits. */
  function buildShort(routeMax) {
    var start = parseLocal(tp.start), ret = parseLocal(tp.ret), done = tp.status === 'done', v = tp.vehicle || {};
    var L = ['TRIP PLAN (short version - ask for the full plan)'];
    if (done) L.push('FINISHED: back safely ' + fmtDT(new Date(tp.doneAt), true) + '.');
    else L.push('IF NOT BACK BY ' + overdueText() + ' CALL ' + callWho() + '. DO NOT WAIT.');
    var ps = people();
    L.push('Party: ' + (ps.length ? ps.map(function (p) {
      return ((p.name || '').trim() || '?') + (p.age ? ' (' + p.age + ')' : '') + (p.phone ? ' ' + p.phone : '');
    }).join('; ') : '(no names)'));
    if (routeMax > 150) ps.forEach(function (p) { if (p.medical) L.push('Medical ' + ((p.name || '').trim() || '?') + ': ' + clip(p.medical, 80)); });
    L.push(activityText() + (tp.destination ? ': ' + tp.destination.trim() : ''));
    if (tp.trailhead) L.push('Start point: ' + clip(tp.trailhead, 100));
    if (tp.route && routeMax > 0) L.push('Route: ' + clip(tp.route.replace(/\s+/g, ' '), routeMax));
    L.push('Start ' + (start ? fmtDT(start) : '?') + ' / back ' + (ret ? fmtDT(ret) : '?'));
    var vt = vehicleText();
    if (vt || v.parked) L.push('Vehicle: ' + [vt, v.parked && 'at ' + v.parked].filter(Boolean).join(' '));
    if (tp.phones) L.push('Phones: ' + clip(tp.phones, 120));
    if (tp.satId) L.push('Sat/PLB: ' + clip(tp.satId, 80));
    return L.join('\n');
  }

  /* ---------- QR ---------- */
  function utf8(s) { return unescape(encodeURIComponent(s)); }   // UTF-8 bytes as a binary string (qrcode "Byte" mode)
  function tryQr(text) {
    if (utf8(text).length > QR_MAX_BYTES) return null;
    try { var q = qrcode(0, QR_ECC); q.addData(utf8(text)); q.make(); return q; } catch (e) { return null; }
  }
  function renderQr(full) {
    var box = $('#tp-qr'), note = $('#tp-qr-note');
    box.textContent = '';
    if (!window.qrcode) { box.hidden = true; note.textContent = 'QR code unavailable in this browser.'; return; }
    var text = full, short = false, qr = tryQr(full);
    // Too long: shortened versions with less and less route text, then a hard cut.
    [500, 250, 120, 0].some(function (n) {
      if (qr) return true;
      short = true; text = buildShort(n); qr = tryQr(text);
      return !!qr;
    });
    if (!qr) {
      while (utf8(text).length > QR_MAX_BYTES - 4 && text.length > 20) text = text.slice(0, -20);
      text += '...';
      qr = tryQr(text);
    }
    if (!qr) { box.hidden = true; note.textContent = 'The plan is too long for a QR code — send the text instead.'; return; }
    box.hidden = false;
    box.innerHTML = qr.createSvgTag({ cellSize: 4, margin: 4, scalable: true });   // generated SVG markup, no user HTML
    var svg = box.querySelector('svg');
    if (svg) { svg.setAttribute('role', 'img'); svg.setAttribute('aria-label', 'QR code of the ' + (short ? 'shortened ' : '') + 'trip plan'); }
    box.setAttribute('data-short', short ? '1' : '0');
    note.textContent = short
      ? 'QR code (shortened): the full plan is too long for one QR code, so this holds the names, route, vehicle, times and the call-for-help instruction. Send or print the full text as well.'
      : 'QR code of the whole plan — another phone can scan it with its camera, no internet needed.';
  }

  /* ---------- missing info / status ---------- */
  function paintChecks() {
    var miss = [];
    if (!people().some(function (p) { return p.name && p.name.trim(); })) miss.push('Names of everyone going.');
    if (!(tp.destination || tp.route || '').trim()) miss.push('Destination or route.');
    if (!parseLocal(tp.ret)) miss.push('Expected return time.');
    if (tp.status !== 'done' && !parseLocal(tp.overdue)) miss.push('The “call for help” time.');
    var ul = $('#tp-missing-list');
    ul.textContent = '';
    miss.forEach(function (m) { ul.appendChild(el('li', { text: m })); });
    $('#tp-missing').hidden = !miss.length;
    var od = parseLocal(tp.overdue);
    $('#tp-overdue-now').hidden = !(tp.status !== 'done' && od && od.getTime() < Date.now());
  }
  function paintDone() {
    var done = tp.status === 'done';
    $('#tp-done').hidden = !done;
    if (done) $('#tp-done-text').textContent = 'Marked back safely at ' + fmtDT(new Date(tp.doneAt)) + '. Now tell your contacts you are back, so nobody starts a search.';
    $('#tp-back').disabled = done;
  }

  function renderSummaryNow() {
    clearTimeout(renderTimer);
    if (!tp) return;
    var text = buildSummary();
    $('#tp-text').textContent = text;
    renderQr(text);
    paintChecks();
  }
  function renderSoon() { clearTimeout(renderTimer); renderTimer = setTimeout(renderSummaryNow, 250); }

  /* ---------- back safely ---------- */
  function backMessage() {
    var names = people().map(function (p) { return (p.name || '').trim(); }).filter(Boolean).join(', ');
    return 'We are back safely (' + fmtDT(new Date(tp.doneAt), true) + ').' +
      (tp.destination ? ' Trip: ' + tp.destination.trim() + '.' : '') + ' No need to call for help.' + (names ? ' - ' + names : '');
  }
  function backSafely() {
    if (!tp || tp.status === 'done') return;
    if (!confirm('Mark the trip as finished?\n\nThis clears the call-for-help time and cancels the turnaround alarm. A copy of the plan is kept.')) return;
    var now = Date.now();
    history.unshift({ doneAt: now, text: buildSummary() });    // the plan as it was sent
    history = history.slice(0, HIST_MAX);
    if (hasStore()) OGStore.kvSet('tripplan.history', history).catch(function () {});
    tp.status = 'done'; tp.doneAt = now; tp.overdue = ''; tp.overdueAuto = false;
    $('#tp-overdue').value = '';
    cancelAlarm(true);
    dirty = true; saveNow();
    paintDone(); renderHistory(); paintTimeErr(); renderSummaryNow();
    toast('Marked back safely. Now tell your contacts you are back.');
    $('#tp-done').scrollIntoView({ block: 'center' });
    $('#tp-back-copy').focus({ preventScroll: true });
  }
  function newTrip() {
    tp.status = 'active'; tp.doneAt = 0;
    tp.start = ''; tp.ret = ''; tp.overdue = ''; tp.overdueAuto = true;
    fillFields(); paintDone(); saveSoon();
    toast('Dates cleared. People, vehicle, gear and route are kept — edit what changed.');
    $('#tp-start').focus();
  }
  function renderHistory() {
    var body = $('#tp-hist-body');
    body.textContent = '';
    $('#tp-hist').hidden = !history.length;
    history.forEach(function (h, i) {
      body.appendChild(el('h4', { text: 'Back safely ' + fmtDT(new Date(h.doneAt)) }));
      body.appendChild(el('pre', { class: 'tp-text', text: h.text }));
      body.appendChild(el('button', { class: 'btn', type: 'button', 'data-hcopy': String(i), text: 'Copy this plan' }));
    });
  }

  function initTrip() {
    var main = $('#trip');
    main.addEventListener('input', onFieldInput);
    main.addEventListener('change', onFieldInput);

    // party rows
    var party = $('#party');
    party.addEventListener('input', function (e) {
      var row = e.target.closest('.person'), k = e.target.getAttribute('data-pk');
      if (!tp || !row || !k) return;
      e.stopPropagation();
      tp.party[+row.getAttribute('data-i')][k] = e.target.value;
      saveSoon();
    });
    party.addEventListener('click', function (e) {
      var b = e.target.closest('[data-act="del"]');
      if (!tp || !b) return;
      var i = +b.closest('.person').getAttribute('data-i'), p = tp.party[i];
      if ((p.name || p.phone || p.medical) && !confirm('Remove ' + (p.name || 'this person') + ' from the plan?')) return;
      tp.party.splice(i, 1);
      if (!tp.party.length) tp.party.push(blankPerson());
      renderParty(); saveSoon();
      var focus = $('#party-add'); if (focus) focus.focus();
    });
    $('#party-add').addEventListener('click', function () {
      if (!tp) return;
      if (tp.party.length >= 20) { toast('That is a big group — 20 people is the limit here.'); return; }
      tp.party.push(blankPerson());
      renderParty(tp.party.length - 1); saveSoon();
    });

    // gear chips
    $('#gear').addEventListener('click', function (e) {
      var b = e.target.closest('[data-gear]');
      if (!tp || !b) return;
      var g = b.getAttribute('data-gear'), i = tp.gear.indexOf(g);
      if (i >= 0) tp.gear.splice(i, 1); else tp.gear.push(g);
      b.setAttribute('aria-pressed', String(i < 0));
      paintGearRadio(); saveSoon();
      if (g === 'radio' && i < 0) $('#tp-radio-g').focus({ preventScroll: true });
    });

    // waypoints
    $('#wp-pick').addEventListener('change', function (e) {
      var id = e.target.getAttribute('data-wp');
      if (!tp || !id) return;
      e.stopPropagation();
      tp.wps = tp.wps.filter(function (s) { return s.id !== id; });
      if (e.target.checked) { var w = wpById(id); if (w) tp.wps.push(snapWp(w)); }
      saveSoon();
    });

    $('#tp-overdue-reset').addEventListener('click', function () {
      if (!tp) return;
      if (!parseLocal(tp.ret)) { toast('Set the expected return time first.', { error: true }); $('#tp-ret').focus(); return; }
      tp.overdueAuto = true; tp.overdue = autoOverdue();
      $('#tp-overdue').value = tp.overdue;
      if (tp.status === 'done') { tp.status = 'active'; tp.doneAt = 0; paintDone(); }
      paintTimeErr(); saveSoon();
    });

    // output buttons
    $('#tp-copy').addEventListener('click', function () { saveNow(); renderSummaryNow(); copyText($('#tp-text').textContent, 'Trip plan copied'); });
    if (navigator.share) {
      $('#tp-share').hidden = false;
      $('#tp-back-share').hidden = false;
    } else $('#tp-share-hint').textContent = 'Copy the text into a text message or email, print it, or let someone scan the QR code.';
    $('#tp-share').addEventListener('click', function () { saveNow(); renderSummaryNow(); shareText('Trip plan', $('#tp-text').textContent); });
    $('#tp-print').addEventListener('click', function () { saveNow(); renderSummaryNow(); window.print(); });
    window.addEventListener('beforeprint', renderSummaryNow);

    $('#tp-back').addEventListener('click', backSafely);
    $('#tp-back-copy').addEventListener('click', function () { copyText(backMessage(), '“We\'re back” message copied'); });
    $('#tp-back-share').addEventListener('click', function () { shareText('Back safely', backMessage()); });
    $('#tp-new').addEventListener('click', newTrip);
    $('#tp-hist-body').addEventListener('click', function (e) {
      var b = e.target.closest('[data-hcopy]');
      if (b && history[+b.getAttribute('data-hcopy')]) copyText(history[+b.getAttribute('data-hcopy')].text);
    });

    // flush pending saves when leaving; refresh waypoints when coming back from the map
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'hidden') { saveNow(); savePlannerNow(); }
      else if (tp) loadWaypoints().then(function () { if (syncWpSnapshots()) saveSoon(); renderWps(); fillLocSelect(); renderSummaryNow(); });
    });
    window.addEventListener('pagehide', function () { saveNow(); savePlannerNow(); });
    // keep the "call-for-help time has passed" banner current
    setInterval(function () { if (tp) paintChecks(); }, 30000);
  }

  function applyTrip(saved) {
    var def = tpDefault();
    tp = def;
    if (saved && typeof saved === 'object') {
      Object.keys(def).forEach(function (k) { if (saved[k] !== undefined) tp[k] = saved[k]; });
      tp.vehicle = Object.assign({ make: '', colour: '', plate: '', parked: '' }, saved.vehicle || {});
      tp.party = Array.isArray(saved.party) && saved.party.length ? saved.party.map(function (p) { return Object.assign(blankPerson(), p || {}); }) : [blankPerson()];
      tp.gear = Array.isArray(saved.gear) ? saved.gear.slice() : [];
      tp.wps = Array.isArray(saved.wps) ? saved.wps.filter(function (w) { return w && w.id && isFinite(w.lat) && isFinite(w.lon); }) : [];
      savedStatus(saved.updated ? 'Saved on this phone · last change ' + fmtDT(new Date(saved.updated)) : 'Saved on this phone', 'ok');
    } else savedStatus('Not saved yet — changes save automatically');
    if (syncWpSnapshots()) { dirty = true; saveNow(); }
    renderParty(); renderGear(); renderWps(); fillFields(); paintDone(); renderHistory();
    renderSummaryNow();
  }

  /* =================================================================
     2. TIME & TURNAROUND PLANNER — kv "tripplan.planner"
        Naismith (1892): 1 h per 5 km (3 mi) + 1 h per 600 m (2,000 ft)
        of ascent; × pace factor; + breaks per hour of walking.
     ================================================================= */
  var BUFFER_MIN = 30;               // be out this long before last light
  var COMFORT_MIN = 60;              // finishing ≥ 1 h before sunset counts as comfortable (green)
  var pl = { units: 'metric', distM: null, ascM: null, route: 'oab', pace: 1, breaks: 10, date: '', time: '', trackId: '', loc: 'auto' };
  var tracks = [];
  var gpsNow = null;                 // a fix taken on this page (not persisted)
  var plTimer = 0, liveTimer = 0, lastPlan = null;

  function savePlannerSoon() { clearTimeout(plTimer); plTimer = setTimeout(savePlannerNow, 400); }
  function savePlannerNow() {
    clearTimeout(plTimer);
    if (!hasStore()) return;
    var s = {};
    Object.keys(pl).forEach(function (k) { if (k !== 'units') s[k] = pl[k]; });
    OGStore.kvSet('tripplan.planner', s).catch(function () {});
  }

  /* ---------- units ---------- */
  function imp() { return pl.units === 'imperial'; }
  function distToDisplay(m) { return m == null ? '' : String(Math.round((imp() ? m / 1000 / KM_PER_MI : m / 1000) * 100) / 100); }
  function ascToDisplay(m) { return m == null ? '' : String(Math.round(imp() ? m * FT_PER_M : m)); }
  function paintUnits() {
    $$('[data-units]').forEach(function (b) { b.setAttribute('aria-pressed', String(b.getAttribute('data-units') === pl.units)); });
    $$('.u-dist').forEach(function (s) { s.textContent = imp() ? 'mi' : 'km'; });
    $$('.u-asc').forEach(function (s) { s.textContent = imp() ? 'ft' : 'm'; });
    $('#pl-dist').value = distToDisplay(pl.distM);
    $('#pl-asc').value = ascToDisplay(pl.ascM);
    $('#pl-asc').step = imp() ? '50' : '10';
    fillTrackSelect();
  }

  /* ---------- saved tracks ---------- */
  function loadTracks() {
    if (!hasStore()) return Promise.resolve();
    return OGStore.all('tracks').then(function (all) {
      tracks = (all || []).filter(function (t) { return t && t.id && Array.isArray(t.points) && t.points.length >= 2; });
      tracks.sort(function (a, b) { return (b.created || 0) - (a.created || 0); });
    }).catch(function () { tracks = []; });
  }
  /* Track points are [lat, lon, alt|null, time, acc]; tolerate {lat, lon, alt} objects too. */
  function trackPts(t) {
    return t.points.map(function (p) {
      if (Array.isArray(p)) return [+p[0], +p[1], p[2]];
      if (p && typeof p === 'object') return [+p.lat, +p.lon, p.alt];
      return null;
    }).filter(function (p) { return p && isFinite(p[0]) && isFinite(p[1]); });
  }
  /* Distance (m) and total ascent (m, 3 m hysteresis against GPS altitude noise — same as the map). */
  function trackStats(t) {
    var pts = trackPts(t), dist = window.OGGeo ? OGGeo.pathLength(pts) : 0, gain = 0, last = null, n = 0;
    pts.forEach(function (p) {
      var a = p[2];
      if (a == null || a === '' || !isFinite(a)) return;
      a = +a; n++;
      if (last == null) { last = a; return; }
      var d = a - last;
      if (Math.abs(d) >= 3) { if (d > 0) gain += d; last = a; }
    });
    return { dist: dist, gain: n >= 2 ? gain : null };
  }
  function fillTrackSelect() {
    var sel = $('#pl-track');
    sel.textContent = '';
    sel.appendChild(el('option', { value: '', text: tracks.length ? '— type the numbers below —' : '— no saved tracks yet —' }));
    tracks.forEach(function (t) {
      var s = trackStats(t);
      sel.appendChild(el('option', { value: t.id, text: (t.name || 'Track') + ' — ' + (window.OGGeo ? OGGeo.fmtDist(s.dist, pl.units) : Math.round(s.dist) + ' m') }));
    });
    sel.value = pl.trackId && tracks.some(function (t) { return t.id === pl.trackId; }) ? pl.trackId : '';
  }
  function useTrack(id) {
    var note = $('#pl-track-note');
    pl.trackId = id;
    var t = null;
    tracks.forEach(function (x) { if (x.id === id) t = x; });
    if (!t) { note.textContent = 'Tracks you recorded on the Map appear here.'; return; }
    var s = trackStats(t);
    pl.distM = Math.round(s.dist);
    $('#pl-dist').value = distToDisplay(pl.distM);
    var msg = '“' + (t.name || 'Track') + '”: ' + OGGeo.fmtDist(s.dist, pl.units) + ' along the recorded line';
    if (s.gain != null) {
      pl.ascM = Math.round(s.gain);
      $('#pl-asc').value = ascToDisplay(pl.ascM);
      msg += ', ascent ' + OGGeo.fmtAlt(s.gain, pl.units) + ' from GPS altitudes (rough).';
    } else {
      msg += '. Ascent unknown — this track has no altitude data. Enter the climb from a map (0 underestimates the time).';
    }
    note.textContent = msg + ' If you recorded only the way out of an out-and-back, double the distance.';
  }

  /* ---------- location for sunset ---------- */
  function readJSON(key) { try { return JSON.parse(localStorage.getItem(key) || 'null'); } catch (e) { return null; } }
  function autoLoc() {
    var f = readJSON('ogsk.lastfix');
    if (f && isFinite(f.lat) && isFinite(f.lon)) return { lat: +f.lat, lon: +f.lon, src: 'last GPS fix', when: f.t ? fmtDT(new Date(f.t)) : '' };
    var v = readJSON('ogsk.map.view');
    if (v && isFinite(v.lat) && isFinite(v.lon)) return { lat: +v.lat, lon: +v.lon, src: 'last map view (approximate)' };
    return null;
  }
  function currentLoc() {
    if (pl.loc === 'gps' && gpsNow) return gpsNow;
    if (pl.loc && pl.loc.indexOf('wp:') === 0) {
      var w = wpById(pl.loc.slice(3));
      if (w) return { lat: +w.lat, lon: +w.lon, src: 'waypoint “' + (w.name || 'Unnamed') + '”' };
    }
    return autoLoc();
  }
  function fillLocSelect() {
    var sel = $('#pl-loc'), a = autoLoc();
    sel.textContent = '';
    sel.appendChild(el('option', { value: 'auto', text: a ? 'Automatic — ' + a.src : 'Automatic — no saved position yet' }));
    if (gpsNow) sel.appendChild(el('option', { value: 'gps', text: 'My GPS position (' + fmtTime(new Date(gpsNow.t)) + ')' }));
    waypoints.forEach(function (w) { sel.appendChild(el('option', { value: 'wp:' + w.id, text: 'Waypoint: ' + (w.name || 'Unnamed') + ' (' + catLabel(w.cat) + ')' })); });
    sel.value = pl.loc;
    if (sel.value !== pl.loc) { sel.value = 'auto'; if (pl.loc !== 'gps') pl.loc = 'auto'; }
  }
  function paintLocInfo(loc) {
    var p = $('#pl-loc-info');
    if (!loc) { p.textContent = 'No position known yet. Pick a saved waypoint near your route, tap “Use my GPS position now”, or open the Map once.'; return; }
    p.textContent = 'Using ' + OGGeo.formatLatLon(loc.lat, loc.lon, 'dd') + ' — ' + loc.src + (loc.when ? ' (' + loc.when + ')' : '') + '. If the trip is far from here, pick a waypoint near the route.';
  }

  /* ---------- sun times for the start date ---------- */
  function daylight(start, loc) {
    var noon = new Date(start.getFullYear(), start.getMonth(), start.getDate(), 12, 0, 0);
    var t = SunCalc.getTimes(noon, loc.lat, loc.lon);
    var out = {
      sunrise: valid(t.sunrise) ? t.sunrise : null, sunset: valid(t.sunset) ? t.sunset : null,
      dawn: valid(t.dawn) ? t.dawn : null, dusk: valid(t.dusk) ? t.dusk : null, polar: null
    };
    if (!out.sunset) {                                   // sun never sets or never rises that day
      out.polar = SunCalc.getPosition(valid(t.solarNoon) ? t.solarNoon : noon, loc.lat, loc.lon).altitude > 0 ? 'day' : 'night';
    }
    out.lastLight = out.dusk;                            // civil dusk: sun 6° below the horizon
    out.deadline = out.lastLight ? new Date(out.lastLight.getTime() - BUFFER_MIN * MIN) : null;
    return out;
  }

  /* ---------- the calculation ---------- */
  function startDate() {
    var d = $('#pl-date').value, t = $('#pl-time').value;
    if (!d || !t) return null;
    return parseLocal(d + 'T' + t);
  }
  function computePlan() {
    var dist = num($('#pl-dist').value), asc = num($('#pl-asc').value), brk = num($('#pl-breaks').value);
    if (!(asc >= 0)) asc = 0;
    if (!(brk >= 0)) brk = 0;
    brk = Math.min(brk, 60);
    var r = { ok: false, dist: dist, asc: asc, brk: brk, pace: pl.pace, route: pl.route };
    if (!(dist > 0)) return r;
    var flatRate = imp() ? 3 : 5, climbRate = imp() ? 2000 : 600;  // per hour
    var flatH = dist / flatRate, climbH = asc / climbRate;
    r.flatRate = flatRate; r.climbRate = climbRate;
    r.flatMin = flatH * 60; r.climbMin = climbH * 60;
    r.naisMin = ceilMin((flatH + climbH) * 60);
    r.walkMin = ceilMin((flatH + climbH) * pl.pace * 60);
    r.breakMin = ceilMin(r.walkMin * brk / 60);
    r.totalMin = r.walkMin + r.breakMin;
    r.start = startDate();
    if (r.start) {
      r.finish = new Date(r.start.getTime() + r.totalMin * MIN);
      r.half = new Date(r.start.getTime() + r.totalMin * MIN / 2);   // planned arrival at the far point / halfway
    }
    r.loc = currentLoc();
    if (r.start && r.loc && window.SunCalc) {
      r.sun = daylight(r.start, r.loc);
      var s = r.sun;
      if (s.polar === 'night') r.level = s.deadline && r.finish <= s.deadline ? 'warn' : 'bad';   // twilight only, at best
      else if (!s.deadline) r.level = 'ok';            // no darkness that day (midnight sun / white night)
      else if (s.sunset && r.finish.getTime() <= s.sunset.getTime() - COMFORT_MIN * MIN) r.level = 'ok';
      else if (r.finish <= s.deadline) r.level = 'warn';
      else r.level = 'bad';
      if (s.deadline) {
        // Assumption: the second half (the way back) takes as long as the first half.
        r.latestTurn = new Date(s.deadline.getTime() - r.totalMin * MIN / 2);
        r.latestStart = new Date(s.deadline.getTime() - r.totalMin * MIN);
        r.spareMin = (r.latestTurn - r.half) / MIN;
      }
    }
    r.ok = true;
    return r;
  }

  function kvRow(dl, k, v) { dl.appendChild(el('dt', { text: k })); dl.appendChild(el('dd', null, [v])); }

  function renderPlanner() {
    var out = $('#pl-out'), r = computePlan(), u = imp();
    lastPlan = r;
    out.textContent = '';
    paintLocInfo(r.loc || currentLoc());
    paintAlarmUse(r);
    if (!r.ok) {
      out.appendChild(el('h3', { text: 'Estimate' }));
      out.appendChild(el('p', { class: 'hint', text: 'Enter the total distance to get an estimate.' }));
      setLive('');
      return;
    }
    var dUnit = u ? 'mi' : 'km', aUnit = u ? 'ft' : 'm';
    out.appendChild(el('h3', { text: 'Estimate' }));
    out.appendChild(el('p', { class: 'res-big', id: 'pl-total', 'data-min': String(r.totalMin), text: fmtDur(r.totalMin) }));
    if (r.finish) out.appendChild(el('p', null, ['Start ', el('strong', { text: fmtTime(r.start) }), ' → finish about ', el('strong', { id: 'pl-finish', 'data-t': String(r.finish.getTime()), text: fmtWhen(r.finish, r.start) })]));
    else out.appendChild(el('p', { class: 'hint', text: 'Add a start date and time to see the finish time and daylight.' }));

    var dl = el('dl', { class: 'kv' });
    kvRow(dl, 'Flat', r.dist + ' ' + dUnit + ' ÷ ' + r.flatRate + ' ' + dUnit + '/h = ' + fmtDur(r.flatMin));
    kvRow(dl, 'Climb', r.asc + ' ' + aUnit + ' ÷ ' + r.climbRate.toLocaleString() + ' ' + aUnit + '/h = ' + fmtDur(r.climbMin));
    kvRow(dl, 'Naismith', fmtDur(r.naisMin));
    kvRow(dl, 'Pace ×' + r.pace.toFixed(1), fmtDur(r.walkMin) + ' walking');
    kvRow(dl, 'Breaks', '+ ' + fmtDur(r.breakMin) + ' (' + r.brk + ' min per hour)');
    kvRow(dl, 'Total', fmtDur(r.totalMin));
    out.appendChild(dl);
    if (r.totalMin > 10 * 60) out.appendChild(el('p', { class: 'hint', text: 'That is a very long day. For a multi-day trip, plan each day separately.' }));

    if (r.start && !r.loc) {
      out.appendChild(el('p', { class: 'hint', text: 'Choose a location below to calculate sunset, last light and your turnaround time.' }));
    }
    if (r.sun) renderDaylight(out, r);
    out.appendChild(el('p', { class: 'hint', text: 'Times are in this phone\'s time zone' + (TZ ? ' (' + TZ + ')' : '') + '. Rounded up to the minute.' }));

    var live = 'Estimated ' + fmtDur(r.totalMin) + (r.finish ? ', finish about ' + fmtWhen(r.finish, r.start) : '') +
      (r.latestTurn && r.route === 'oab' ? ', turn around by ' + fmtWhen(r.latestTurn, r.start) : '');
    setLive(live);
  }
  function setLive(text) { clearTimeout(liveTimer); liveTimer = setTimeout(function () { $('#pl-live').textContent = text; }, 1200); }

  function renderDaylight(out, r) {
    var s = r.sun, ref = r.start;
    out.appendChild(el('h3', { text: 'Daylight on ' + fmtDay(r.start) }));
    if (s.polar === 'night' && !s.deadline) {
      out.appendChild(el('p', { class: 'chip margin-chip bad', id: 'pl-margin', 'data-level': 'bad', text: 'The sun does not rise that day here and there is no twilight — the whole trip is in darkness.' }));
      return;
    }
    if (s.polar === 'day') {
      out.appendChild(el('p', { class: 'chip margin-chip ok', id: 'pl-margin', text: 'The sun does not set that day here (midnight sun).' }));
      out.appendChild(el('p', { class: 'hint', text: 'No darkness deadline — still set a turnaround time for weather, fatigue and the rest of your plan.' }));
      return;
    }
    var dl = el('dl', { class: 'kv' });
    if (s.polar === 'night') kvRow(dl, 'First light', fmtWhen(s.dawn, ref) + ' (civil dawn)');
    if (s.sunrise) kvRow(dl, 'Sunrise', fmtWhen(s.sunrise, ref));
    kvRow(dl, 'Sunset', el('span', { id: 'pl-sunset', text: s.sunset ? fmtWhen(s.sunset, ref) : 'the sun does not rise (polar night)' }));
    kvRow(dl, 'Last light', el('span', { id: 'pl-lastlight', text: s.lastLight ? fmtWhen(s.lastLight, ref) + ' (civil dusk)' : 'stays light all night' }));
    if (s.deadline) kvRow(dl, 'Be out by', fmtWhen(s.deadline, ref) + ' (last light − ' + BUFFER_MIN + ' min)');
    out.appendChild(dl);

    // Finish margin: green ≥ 1 h before sunset · amber before (last light − buffer) · red later
    var toSunset = s.sunset ? (s.sunset - r.finish) / MIN : 0, marginTxt;
    if (s.polar === 'night') {
      marginTxt = 'The sun does not rise that day — twilight only, ' + fmtTime(s.dawn) + ' to ' + fmtTime(s.lastLight) + '. ' +
        (r.level === 'warn' ? 'You finish before last light − ' + BUFFER_MIN + ' min, but it is dim all day: carry headlamps.' : 'You would be out in the dark. Start earlier, shorten the route or change the plan.');
    } else if (!s.deadline) {
      marginTxt = 'It stays light all night (civil twilight). Finish ' + (toSunset >= 0 ? fmtDur(toSunset) + ' before' : fmtDur(-toSunset) + ' after') + ' sunset.';
    } else if (r.level === 'ok') {
      marginTxt = 'Finish ' + fmtDur(toSunset) + ' before sunset. Good margin.';
    } else if (r.level === 'warn') {
      marginTxt = (toSunset >= 0 ? 'Finish only ' + fmtDur(toSunset) + ' before sunset' : 'Finish ' + fmtDur(-toSunset) + ' after sunset, before last light') +
        '. Tight — start earlier or shorten the route, and carry headlamps.';
    } else {
      marginTxt = (r.finish > s.lastLight ? 'Finish ' + fmtDur((r.finish - s.lastLight) / MIN) + ' after last light' : 'Finish less than ' + BUFFER_MIN + ' min before last light') +
        ' — you would be out in the dark. Start earlier, shorten the route or change the plan.';
    }
    out.appendChild(el('p', { class: 'chip margin-chip ' + (r.level === 'ok' ? 'ok' : r.level === 'warn' ? 'warn' : 'bad'), id: 'pl-margin', 'data-level': r.level, text: marginTxt }));
    if (s.dawn && r.start < s.dawn) out.appendChild(el('p', { class: 'hint', text: 'You start before first light (' + fmtTime(s.dawn) + ') — the first part is in the dark.' }));
    if (!s.deadline) return;

    // Turnaround (out-and-back) or latest start + halfway check (loop / one-way)
    var bad = r.route === 'oab' ? (r.spareMin < 0 || r.latestTurn <= r.start) : r.latestStart < r.start;
    var box = el('div', { class: 'turn-box' + (bad ? ' bad' : '') });
    if (r.route === 'oab') {
      box.appendChild(el('h3', { text: 'Turnaround time' }));
      box.appendChild(el('p', { class: 'res-big', id: 'pl-turn', 'data-t': String(r.latestTurn.getTime()), text: 'Turn back by ' + fmtWhen(r.latestTurn, ref) }));
      box.appendChild(el('p', { text: 'The latest time to turn around and still be out by ' + fmtWhen(s.deadline, ref) + ' (' + BUFFER_MIN + ' min before last light). It assumes the way back takes as long as the way out: half the total, ' + fmtDur(r.totalMin / 2) + '.' }));
      if (r.latestTurn <= r.start) box.appendChild(el('p', { class: 'err', text: 'Not enough daylight for this trip from this start time. Start earlier or pick a shorter route.' }));
      else if (r.spareMin >= 0) box.appendChild(el('p', { text: 'At your pace you reach the far point about ' + fmtWhen(r.half, ref) + ' — ' + fmtDur(r.spareMin) + ' before your turnaround time.' }));
      else box.appendChild(el('p', { class: 'err', text: 'At your pace you reach the far point about ' + fmtWhen(r.half, ref) + ' — ' + fmtDur(-r.spareMin) + ' AFTER your turnaround time. You won\'t make the goal in daylight: start earlier, shorten the route, or turn back at ' + fmtWhen(r.latestTurn, ref) + ' wherever you are.' }));
      box.appendChild(el('p', { class: 'hint', text: 'Downhill isn\'t always faster: steep, loose or wet ground and tired legs slow you down. Turn back sooner if you are behind schedule.' }));
    } else {
      box.appendChild(el('h3', { text: 'Latest start & halfway check' }));
      box.appendChild(el('p', { class: 'res-big', id: 'pl-turn', 'data-t': String(r.latestStart.getTime()), text: 'Start by ' + fmtWhen(r.latestStart, ref) }));
      box.appendChild(el('p', { text: 'The latest start to finish by ' + fmtWhen(s.deadline, ref) + ' (' + BUFFER_MIN + ' min before last light) at your pace.' + (r.latestStart < r.start ? ' Your planned start is ' + fmtDur((r.start - r.latestStart) / MIN) + ' too late.' : '') }));
      box.appendChild(el('p', null, ['Halfway check: you should be halfway at about ', el('strong', { text: fmtWhen(r.half, ref) }), '. If you are not halfway by ', el('strong', { text: fmtWhen(r.latestTurn, ref) }), ', you will not finish before dark.']));
      box.appendChild(el('p', { text: r.route === 'loop'
        ? 'Point of no return: before halfway, going back the way you came is the shorter way out; after halfway, carrying on is shorter. Decide at halfway — know your bail-out paths.'
        : 'Point of no return: before halfway, turning back is quicker; after halfway, carry on — and make sure your transport is waiting at the end you will reach.' }));
    }
    out.appendChild(box);
  }

  /* Planner inputs → state */
  function onPlannerInput(e) {
    var id = e.target.id;
    if (id === 'pl-dist') { var d = num(e.target.value); pl.distM = d >= 0 ? d * (imp() ? KM_PER_MI : 1) * 1000 : null; clearTrack(); }
    else if (id === 'pl-asc') { var a = num(e.target.value); pl.ascM = a >= 0 ? (imp() ? a / FT_PER_M : a) : null; clearTrack(); }
    else if (id === 'pl-breaks') { var b = num(e.target.value); pl.breaks = b >= 0 ? b : 10; }
    else if (id === 'pl-date') pl.date = e.target.value;
    else if (id === 'pl-time') pl.time = e.target.value;
    else return;
    savePlannerSoon(); renderPlanner();
  }
  function clearTrack() {
    if (!pl.trackId) return;
    pl.trackId = '';
    $('#pl-track').value = '';
    $('#pl-track-note').textContent = 'Using the numbers you typed.';
  }
  function paintSegs() {
    $$('[data-route]').forEach(function (b) { b.setAttribute('aria-pressed', String(b.getAttribute('data-route') === pl.route)); });
    $$('[data-pace]').forEach(function (b) { b.setAttribute('aria-pressed', String(+b.getAttribute('data-pace') === pl.pace)); });
  }
  function useTripStart(quiet) {
    var s = tp && parseLocal(tp.start);
    if (!s) { if (!quiet) toast('Set a start time in the trip plan first.', { error: true }); return false; }
    pl.date = toDateInput(s); pl.time = toTimeInput(s);
    $('#pl-date').value = pl.date; $('#pl-time').value = pl.time;
    return true;
  }

  function initPlanner() {
    var sec = $('#planner');
    sec.addEventListener('input', onPlannerInput);
    sec.addEventListener('change', function (e) {
      if (e.target.id === 'pl-track') { useTrack(e.target.value); savePlannerSoon(); renderPlanner(); }
      else if (e.target.id === 'pl-loc') { pl.loc = e.target.value; savePlannerSoon(); renderPlanner(); }
      else onPlannerInput(e);
    });
    sec.addEventListener('click', function (e) {
      var b = e.target.closest('button');
      if (!b) return;
      if (b.hasAttribute('data-units')) { pl.units = b.getAttribute('data-units'); paintUnits(); renderPlanner(); }
      else if (b.hasAttribute('data-route')) { pl.route = b.getAttribute('data-route'); paintSegs(); savePlannerSoon(); renderPlanner(); }
      else if (b.hasAttribute('data-pace')) { pl.pace = +b.getAttribute('data-pace'); paintSegs(); savePlannerSoon(); renderPlanner(); }
    });
    $('#pl-from-trip').addEventListener('click', function () { if (useTripStart()) { savePlannerSoon(); renderPlanner(); toast('Start time copied from the trip plan.'); } });
    $('#pl-gps').addEventListener('click', function () {
      var btn = this;
      if (!('geolocation' in navigator)) { toast('This browser has no location access.', { error: true }); return; }
      btn.disabled = true; btn.textContent = 'Getting GPS fix…';
      navigator.geolocation.getCurrentPosition(function (pos) {
        btn.disabled = false; btn.textContent = 'Use my GPS position now';
        gpsNow = { lat: pos.coords.latitude, lon: pos.coords.longitude, t: pos.timestamp || Date.now(), src: 'GPS position (±' + Math.round(pos.coords.accuracy) + ' m)' };
        pl.loc = 'gps';
        fillLocSelect(); renderPlanner();
      }, function (err) {
        btn.disabled = false; btn.textContent = 'Use my GPS position now';
        toast(err && err.code === 1 ? 'Location permission denied.' : 'No GPS fix — go outside and try again, or pick a waypoint.', { error: true });
      }, { enableHighAccuracy: true, timeout: 60000, maximumAge: 300000 });
    });
  }

  function applyPlanner(saved, mapSettings) {
    pl.units = mapSettings && mapSettings.units === 'imperial' ? 'imperial' : 'metric';
    if (saved && typeof saved === 'object') Object.keys(pl).forEach(function (k) { if (k !== 'units' && saved[k] !== undefined) pl[k] = saved[k]; });
    if ([0.8, 1, 1.3, 1.5].indexOf(+pl.pace) < 0) pl.pace = 1; else pl.pace = +pl.pace;
    if (['oab', 'loop', 'oneway'].indexOf(pl.route) < 0) pl.route = 'oab';
    if (!(pl.date && pl.time) && !useTripStart(true)) {   // default: trip-plan start, else today 08:00
      pl.date = toDateInput(new Date()); pl.time = '08:00';
    }
    $('#pl-date').value = pl.date; $('#pl-time').value = pl.time;
    $('#pl-breaks').value = pl.breaks;
    paintUnits(); paintSegs(); fillLocSelect();
    if (pl.trackId) {
      if (tracks.some(function (t) { return t.id === pl.trackId; })) useTrack(pl.trackId);
      else pl.trackId = '';                               // track was deleted: keep the numbers
    }
    renderPlanner();
  }

  /* =================================================================
     3. TURNAROUND ALARM — kv "tripplan.alarm" {at, label, set}
        Works only while this page is open and on screen (wake lock).
     ================================================================= */
  var RING_S = 180;                  // ring for up to 3 minutes unless stopped
  var MISSED_WINDOW = 2 * HOUR;      // reopening within 2 h of a missed alarm still shows it
  var al = { at: 0, label: '', timer: 0, ringing: false, ringTimer: 0, ringEnd: 0 };
  var audio = { ctx: null, comp: null, osc: null, gate: null };

  function ensureAudio() {
    var AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    if (!audio.ctx) {
      try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch (e) {}   // Safari: play with the silent switch on
      audio.ctx = new AC();
      var comp = audio.comp = audio.ctx.createDynamicsCompressor();   // loud but not clipped
      comp.threshold.value = -10; comp.knee.value = 2; comp.ratio.value = 20; comp.attack.value = 0.002; comp.release.value = 0.08;
      comp.connect(audio.ctx.destination);
      if (audio.ctx.addEventListener) audio.ctx.addEventListener('statechange', paintAlarm);
    }
    if (audio.ctx.state !== 'running') { try { audio.ctx.resume().then(paintAlarm, function () {}); } catch (e) {} }
    return audio.ctx;
  }
  function audioReady() { return !!(audio.ctx && audio.ctx.state === 'running'); }

  /* Hi-lo two-tone (1500 / 1000 Hz, 0.35 s each) for `secs` seconds, scheduled
     on the audio clock in one go so it keeps going even if timers are throttled. */
  function playAlarmTone(secs) {
    var ctx = ensureAudio();
    if (!ctx) return false;
    stopTone();
    var osc = ctx.createOscillator(), g = ctx.createGain();
    osc.type = 'square';
    var t0 = ctx.currentTime + 0.05, end = t0 + secs, i = 0;
    for (var x = t0; x < end; x += 0.35, i++) osc.frequency.setValueAtTime(i % 2 ? 1000 : 1500, x);
    g.gain.setValueAtTime(0, t0);
    g.gain.linearRampToValueAtTime(0.9, t0 + 0.01);
    g.gain.setValueAtTime(0.9, end - 0.02);
    g.gain.linearRampToValueAtTime(0, end);
    osc.connect(g); g.connect(audio.comp);
    osc.start(t0); osc.stop(end + 0.05);
    osc.onended = function () { try { osc.disconnect(); g.disconnect(); } catch (e) {} if (audio.osc === osc) { audio.osc = audio.gate = null; paintAlarm(); } };
    audio.osc = osc; audio.gate = g;
    paintAlarm();
    return true;
  }
  function stopTone() {
    if (!audio.osc) return;
    var osc = audio.osc, g = audio.gate, now = audio.ctx.currentTime;
    audio.osc = audio.gate = null;
    try {
      g.gain.cancelScheduledValues(now); g.gain.setValueAtTime(g.gain.value, now); g.gain.linearRampToValueAtTime(0, now + 0.03);
      osc.stop(now + 0.05);
    } catch (e) { try { osc.stop(); } catch (e2) {} }
  }
  /* Chrome refuses (and logs) vibration before the user has tapped the page. */
  function canVibrate() { return !!navigator.vibrate && !(navigator.userActivation && !navigator.userActivation.hasBeenActive); }
  function vibrate() { try { if (canVibrate()) navigator.vibrate([600, 200, 600, 200, 600, 200, 1200]); } catch (e) {} }

  function requestNotifyPermission() {
    if (!('Notification' in window) || Notification.permission !== 'default') return;
    try {
      var p = Notification.requestPermission();
      if (p && p.catch) p.catch(function () {});
    } catch (e) {}
  }
  function notify(title, body) {
    if (!('Notification' in window) || Notification.permission !== 'granted') return;
    var opts = { body: body, tag: 'ogsk-turnaround', requireInteraction: true, renotify: true, vibrate: [600, 200, 600, 200, 1200], icon: '../assets/icons/icon-192.png' };
    function plain() { try { new Notification(title, opts); } catch (e) { /* e.g. Android needs the service worker */ } }
    var ready = window.OGSK && OGSK.swReady ? OGSK.swReady : Promise.resolve(null);
    ready.then(function (reg) {
      if (reg && reg.active && reg.showNotification) return reg.showNotification(title, opts);
      plain();
    }).catch(plain);
  }

  function persistAlarm() {
    if (!hasStore()) return;
    OGStore.kvSet('tripplan.alarm', al.at ? { at: al.at, label: al.label, set: Date.now() } : null).catch(function () {});
  }
  function syncWake() { hold('alarm', !!al.at || al.ringing); }

  function startTick() {
    clearInterval(al.timer);
    if (al.at) al.timer = setInterval(tickAlarm, 500);
    syncWake();
    tickAlarm();
  }
  function tickAlarm() {
    if (al.at && Date.now() >= al.at) { fireAlarm(false); return; }
    paintAlarm();
  }
  function fireAlarm(missed) {
    clearInterval(al.timer);
    var at = al.at, label = al.label || 'Turnaround time';
    al.at = 0; persistAlarm();
    al.ringing = true;
    var when = fmtTime(new Date(at));
    $('#al-ring-title').textContent = missed ? 'TURNAROUND TIME PASSED' : 'TURN AROUND NOW';
    $('#al-ring-text').textContent = missed
      ? label + ' was ' + when + ' (this page was closed). If you haven\'t turned back yet, turn back now.'
      : label + ': ' + when + '. Head back now — no matter how close the goal is.';
    $('#al-ring').hidden = false;
    $('#al-ring').setAttribute('data-sound', 'starting');
    playAlarmTone(RING_S);
    vibrate();
    // Autoplay rules can block sound when no tap unlocked it (e.g. after a reload): say so.
    setTimeout(function () {
      if (!al.ringing) return;
      var ok = audioReady() && !!audio.osc;
      $('#al-ring').setAttribute('data-sound', ok ? 'playing' : 'blocked');
      if (!ok && !missed) $('#al-ring-text').textContent += ' (The browser blocked the alarm sound.)';
    }, 700);
    al.ringEnd = Date.now() + RING_S * 1000;
    clearInterval(al.ringTimer);
    al.ringTimer = setInterval(function () {                // keep buzzing while the tone plays
      if (!al.ringing || Date.now() > al.ringEnd) { clearInterval(al.ringTimer); return; }
      vibrate();
    }, 4000);
    notify(missed ? 'Turnaround time passed (' + when + ')' : 'Turn around now (' + when + ')', 'Head back now — no matter how close the goal is.');
    syncWake();
    paintAlarm();
    $('#al-stop').focus({ preventScroll: true });
  }
  function stopRing() {
    al.ringing = false;
    stopTone();
    clearInterval(al.ringTimer);
    try { if (canVibrate()) navigator.vibrate(0); } catch (e) {}
    $('#al-ring').hidden = true;
    syncWake();
    paintAlarm();
  }
  function setAlarm() {
    var d = parseLocal($('#al-time').value);
    if (!d) { toast('Pick an alarm time first.', { error: true }); $('#al-time').focus(); return; }
    if (d.getTime() <= Date.now()) { toast('That time has already passed.', { error: true }); return; }
    ensureAudio();                    // unlock audio inside this tap (iOS / Chrome autoplay rules)
    requestNotifyPermission();
    stopRing();
    al.at = d.getTime();
    al.label = $('#al-time').getAttribute('data-label') || 'Turnaround time';
    persistAlarm();
    startTick();
    toast('Alarm set for ' + fmtWhen(d, new Date()) + '. Set your phone\'s clock alarm too.');
  }
  function cancelAlarm(quiet) {
    var had = !!al.at || al.ringing;
    clearInterval(al.timer);
    al.at = 0; persistAlarm();
    stopRing();
    if (had && !quiet) toast('Turnaround alarm cancelled.');
  }
  function paintAlarm() {
    var clock = $('#al-clock'), sub = $('#al-sub');
    sub.setAttribute('data-audio', audio.ctx ? audio.ctx.state : 'none');
    if (al.at) {
      clock.textContent = fmtHMS(al.at - Date.now());
      sub.textContent = 'Alarm at ' + fmtWhen(new Date(al.at), new Date()) + '. Keep this page open — the screen stays on.' +
        (audioReady() ? '' : ' Tap the screen once so the alarm can make a sound.');
    } else {
      clock.textContent = '--:--:--';
      sub.textContent = al.ringing ? 'Ringing — tap Stop alarm.' : 'No alarm set.';
    }
    $('#al-cancel').disabled = !al.at && !al.ringing;
    $('#al-set').textContent = al.at ? 'Change alarm time' : 'Set turnaround alarm';
  }
  /* "Use the planned turnaround time" button follows the planner. */
  function paintAlarmUse(r) {
    var b = $('#al-use'), t = null, label = 'Turnaround time';
    if (r && r.latestTurn) { t = r.latestTurn; label = r.route === 'oab' ? 'Turnaround time' : 'Halfway check'; }
    b.disabled = !t;
    b.textContent = t ? 'Use the planned ' + label.toLowerCase() + ' (' + fmtWhen(t, new Date()) + ')' : 'Use the planned turnaround time (needs start time and location)';
    b._t = t; b._label = label;
  }

  function initAlarm() {
    $('#al-set').addEventListener('click', setAlarm);
    $('#al-cancel').addEventListener('click', function () { cancelAlarm(false); });
    $('#al-stop').addEventListener('click', stopRing);
    $('#al-use').addEventListener('click', function () {
      var b = this;
      if (!b._t) return;
      $('#al-time').value = toLocalInput(b._t);
      $('#al-time').setAttribute('data-label', b._label);
      if (b._t.getTime() <= Date.now()) toast('That time has already passed.', { error: true });
    });
    $('#al-time').addEventListener('input', function () { this.setAttribute('data-label', 'Turnaround time'); });
    $('#al-test').addEventListener('click', function () {
      if (!playAlarmTone(2)) { toast('Sound is not supported in this browser.', { error: true }); return; }
      vibrate();
      setTimeout(function () { if (!audioReady()) toast('Sound is blocked by the browser. Tap Test again.', { error: true }); }, 800);
    });
    // Any tap unlocks audio for an alarm resumed after a reload (autoplay rules need a gesture).
    document.addEventListener('pointerdown', function () { if (al.at && !audioReady()) { ensureAudio(); } }, true);
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && al.ringing) stopRing(); });
    // Timers are throttled in the background: catch up as soon as the page is visible again.
    document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'visible') tickAlarm(); });
    paintAlarm();
  }
  function resumeAlarm(saved) {
    if (!saved || !saved.at) return;
    al.label = saved.label || 'Turnaround time';
    if (saved.at > Date.now()) {
      al.at = saved.at;
      $('#al-time').value = toLocalInput(new Date(saved.at), true);
      startTick();
      toast('Turnaround alarm resumed: ' + fmtWhen(new Date(saved.at), new Date()) + '.');
    } else if (Date.now() - saved.at < MISSED_WINDOW) {
      al.at = saved.at;
      fireAlarm(true);
    } else {
      persistAlarm();                // long past: forget it
    }
  }

  /* =================================================================
     Boot
     ================================================================= */
  function init() {
    $$('.tz-name').forEach(function (s) { s.textContent = TZ || 'local time'; });
    // polite live region for planner results (announced after typing pauses)
    $('#pl-out').parentNode.insertBefore(el('p', { class: 'sr-only', id: 'pl-live', 'aria-live': 'polite' }), $('#pl-out'));
    initTrip();
    initPlanner();
    initAlarm();

    if (!hasStore()) {
      toast('Storage is not available — the plan cannot be saved in this browser.', { error: true });
      applyTrip(null); applyPlanner(null, null);
      return;
    }
    Promise.all([
      OGStore.kvGet('tripplan', null), OGStore.kvGet('tripplan.history', []), OGStore.kvGet('tripplan.planner', null),
      OGStore.kvGet('map.settings', {}), OGStore.kvGet('tripplan.alarm', null), loadWaypoints(), loadTracks()
    ]).then(function (r) {
      history = Array.isArray(r[1]) ? r[1].filter(function (h) { return h && h.text; }) : [];
      applyTrip(r[0]);
      applyPlanner(r[2], r[3]);
      resumeAlarm(r[4]);
    }).catch(function (err) {
      console.warn(err);
      savedStatus('Storage unavailable — plan will not be saved', 'bad');
      if (!tp) applyTrip(null);
      applyPlanner(null, null);
    });
    if (OGStore.persist) OGStore.persist();   // ask the browser not to evict saved data
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
