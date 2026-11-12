/* =====================================================================
   Off-Grid Survival Kit — offline search engine (window.OGSearch)
   ---------------------------------------------------------------------
   Searches every guide page from a prebuilt index
   (assets/data/search-index.json, made by scripts/build_search.py and
   precached by the service worker, so it works with no signal).

   How matching works (kept simple and predictable for a stressed user):
   - The query is lower-cased, accents stripped, split into words, and
     filler words ("how", "to", "the", "for"…) are dropped.
   - Light stemming: plurals and -ing / -ed endings are removed on both sides,
     so "bleeding" = "bleed", "berries" = "berry", "boiled" = "boil".
   - Every remaining word must match somewhere in a section (AND). If that
     leaves fewer than 5 sections, sections matching all but one word are
     added below them ("how do I take a bearing" still finds the compass).
     A word also matches: the start of a longer word ("tourn" → tourniquet,
     "snake" → snakebite), a built-in survival SYNONYM ("cold" → hypothermia),
     and, only if nothing else matches, a near spelling ("hypotermia").
   - Score: a match in the section heading is worth far more than one in the
     body text; exact words beat prefixes and synonyms; the whole phrase in
     order earns a bonus; shorter sections are slightly preferred.

   API
     OGSearch.load()            → Promise, fetches + indexes once (idempotent)
     OGSearch.ready             → true once loaded
     OGSearch.search(q, limit)  → { results:[…], total, exact, partial,
                                    fuzzy:{word:match} }
                                  each result: { entry, score, url, all,
                                  headHtml, ctxHtml, subHtml, snippetHtml }
     OGSearch.esc(s)            → HTML-escape helper
   ===================================================================== */
(function () {
  'use strict';

  /* ---------------- vocabulary helpers ---------------- */

  // Filler words ignored in queries (and not indexed).
  var STOP = {};
  ('a an and are as at be but by can could do does for from had has have how i if in into is it its ' +
   'me my no not of on or our so than that the their them then there these they this those to too ' +
   'up us was we were what when where which who why will with without would you your get got need ' +
   'should').split(' ').forEach(function (w) { STOP[w] = 1; });

  // Built-in synonyms for survival terms. Keys and values are plain words or
  // short phrases; both are stemmed at load. A phrase matches when all of its
  // words appear in the same field of a section.
  var SYNONYMS = {
    bleed: ['bleeding', 'hemorrhage', 'haemorrhage', 'tourniquet', 'wound packing', 'blood'],
    blood: ['bleeding'],
    hemorrhage: ['bleeding', 'tourniquet'], haemorrhage: ['bleeding', 'tourniquet'],
    tourniquet: ['bleeding'],
    cut: ['wound', 'laceration', 'bleeding'], wound: ['bleeding', 'cut'],
    cpr: ['resuscitation', 'compressions', 'chest compressions', 'aed', 'rescue breaths'],
    resuscitation: ['cpr'], aed: ['cpr', 'defibrillator'],
    cardiac: ['cpr'], heart: ['cpr', 'cardiac'],
    unconscious: ['unresponsive', 'recovery position', 'cpr'], unresponsive: ['unconscious', 'recovery position'],
    purify: ['purification', 'disinfect', 'disinfection', 'boil', 'bleach', 'treatment', 'filter', 'sodis'],
    purification: ['purify', 'disinfect', 'boil', 'bleach', 'treatment'],
    disinfect: ['purify', 'purification', 'bleach', 'chlorine', 'boil'],
    snake: ['snakebite', 'viper', 'venom', 'rattlesnake'],
    snakebite: ['snake', 'venom', 'viper'],
    venom: ['snakebite', 'sting'],
    bite: ['snakebite', 'bites', 'rabies', 'tick'],
    sting: ['bee', 'wasp', 'stings'], bee: ['sting'], wasp: ['sting'],
    cold: ['hypothermia', 'frostbite', 'winter'],
    freezing: ['hypothermia', 'frostbite', 'cold'],
    hypothermia: ['cold', 'hypothermic'], hypothermic: ['hypothermia'],
    frostbite: ['frostnip', 'cold'],
    heat: ['heatstroke', 'heat stroke', 'heat exhaustion', 'hyperthermia'],
    hot: ['heat'], heatstroke: ['heat stroke', 'heat exhaustion'], sunstroke: ['heat stroke'],
    fire: ['tinder', 'ferro', 'bow drill', 'kindling', 'char cloth', 'campfire'],
    ferro: ['ferrocerium', 'ferro rod'], flint: ['ferro', 'ferrocerium', 'flint steel'],
    tinder: ['char cloth', 'kindling'], match: ['ferro', 'lighter'],
    knot: ['bowline', 'hitch', 'prusik', 'clove', 'reef', 'lashing'],
    rope: ['knot', 'cord', 'paracord', 'bowline', 'hitch'], cord: ['rope', 'paracord'],
    lost: ['stop', 'stay put', 'signal', 'separated', 'backtrack'],
    water: ['drink', 'drinking', 'dehydration'],
    drink: ['water', 'drinking'], thirst: ['dehydration', 'water'], thirsty: ['dehydration', 'water'],
    dehydration: ['rehydration', 'dehydrated'], dehydrated: ['dehydration'],
    poison: ['toxic', 'poisonous', 'look-alike', 'lookalike', 'poisoning'],
    poisonous: ['toxic', 'poison', 'look-alike'], toxic: ['poison', 'poisonous', 'look-alike'],
    lightning: ['thunder', 'thunderstorm', 'storm'], thunder: ['lightning', 'thunderstorm', 'storm'],
    storm: ['thunderstorm', 'flood', 'lightning'],
    burn: ['burns', 'scald', 'scalds'], scald: ['burn'],
    choke: ['choking', 'heimlich', 'abdominal thrusts', 'back blows'],
    heimlich: ['choking', 'abdominal thrusts'],
    shelter: ['debris hut', 'lean-to', 'tarp', 'quinzhee', 'snow trench'],
    tent: ['tarp', 'shelter'],
    signal: ['mirror', 'whistle', 'sos', 'ground-to-air', 'strobe', 'morse', 'signalling'],
    sos: ['signal', 'beacon', 'morse', 'strobe', 'mayday'],
    help: ['signal', 'sos', 'rescue', 'emergency'],
    rescue: ['signal', 'sos', 'evacuate', 'evacuation'],
    whistle: ['signal'], mirror: ['signal mirror'], morse: ['sos'],
    nut: ['acorn', 'walnut', 'hickory', 'chestnut', 'hazelnut', 'pecan', 'beechnut', 'pine nut', 'almond'],
    edible: ['forage', 'foraging', 'food'], eat: ['edible', 'food'],
    forage: ['foraging', 'edible', 'wild food'],
    berry: ['blackberry', 'raspberry', 'elderberry', 'mulberry', 'serviceberry', 'fruit'],
    fruit: ['berry', 'berries'],
    acorn: ['oak', 'tannin'], tannin: ['acorn', 'leach'], leach: ['tannin'],
    fracture: ['broken', 'splint', 'sprain'], broken: ['fracture', 'splint'], splint: ['fracture'],
    sprain: ['rice', 'fracture'],
    allergy: ['anaphylaxis', 'epinephrine', 'allergic'], allergic: ['anaphylaxis', 'allergy'],
    anaphylaxis: ['allergic', 'epinephrine'], epipen: ['epinephrine', 'anaphylaxis'],
    tick: ['lyme', 'tick removal'],
    baby: ['infant'], infant: ['baby'], kid: ['child', 'children'], child: ['children', 'kid'],
    pain: ['ibuprofen', 'acetaminophen', 'paracetamol', 'medicines'],
    painkiller: ['ibuprofen', 'acetaminophen', 'paracetamol'],
    tylenol: ['acetaminophen', 'paracetamol'], advil: ['ibuprofen'], motrin: ['ibuprofen'],
    paracetamol: ['acetaminophen'], acetaminophen: ['paracetamol'],
    medicine: ['medicines', 'medication', 'ibuprofen', 'acetaminophen'], meds: ['medicines', 'medicine'],
    diarrhea: ['diarrhoea', 'rehydration'], diarrhoea: ['diarrhea', 'rehydration'],
    vomit: ['vomiting', 'rehydration'], ors: ['oral rehydration'],
    concussion: ['head injury'],
    co: ['carbon monoxide'], monoxide: ['carbon monoxide'],
    generator: ['carbon monoxide', 'power'],
    power: ['electricity', 'generator', 'battery'], electricity: ['power', 'generator', 'battery'],
    battery: ['batteries'], solar: ['sodis', 'solar still', 'panel'],
    flood: ['floodwater', 'storm'], wildfire: ['evacuation', 'smoke'],
    evacuate: ['evacuation', 'go-bag'], evacuation: ['evacuate'],
    car: ['vehicle'], vehicle: ['car'], stranded: ['vehicle', 'stuck'],
    snow: ['winter', 'quinzhee', 'snow shelter'], winter: ['snow', 'cold'],
    compass: ['bearing', 'declination'], bearing: ['compass', 'triangulate'],
    north: ['compass', 'declination'], navigate: ['navigation', 'waypoint', 'compass'],
    navigation: ['navigate', 'compass', 'waypoint'],
    gps: ['coordinates', 'position', 'mgrs'], coordinates: ['gps', 'mgrs', 'utm', 'position'],
    location: ['gps', 'coordinates', 'position'],
    map: ['offline maps', 'waypoint'], offline: ['offline maps'],
    trap: ['snare', 'deadfall', 'trapping'], snare: ['trap', 'trapping'],
    fish: ['fishing', 'hook'], fishing: ['fish', 'hook'], hunt: ['trapping', 'snare', 'game'],
    preserve: ['preserving', 'canning', 'drying', 'jerky', 'salting', 'smoking', 'pickling'],
    jerky: ['drying'], canning: ['botulism', 'pressure canning'], botulism: ['canning'],
    rabies: ['animal bite'], insect: ['insects', 'bugs'], bug: ['insect'],
    plan: ['trip plan', 'turnaround'], turnaround: ['trip plan', 'turnaround time'],
    sunset: ['sun', 'daylight'], dark: ['sunset', 'night'],
    // irregular forms the stemmer can't reach
    bitten: ['bite', 'snakebite'], stung: ['sting'], frozen: ['freeze', 'frostbite', 'hypothermia'],
    broke: ['broken', 'fracture'], burnt: ['burn'], drank: ['drink'], fell: ['fall']
  };

  // Weights: where a word is found (heading, keywords, card sub-line,
  // parent heading, page title, body) …
  var FIELD = { h: 10, k: 6, s: 5, c: 4, pt: 4, t: 1 };
  var MASK = { h: 1, k: 2, s: 4, c: 8, pt: 16, t: 32 };
  var STRONG = MASK.h | MASK.k | MASK.s | MASK.c | MASK.pt;   // anything but body text
  // Tie-breaker: when results are otherwise close, life-safety pages first
  // ("burn" → burn injuries before "what to burn" in a smoker).
  var PAGE_PRIOR = { 'firstaid/index.html': 1.5, 'emergency/index.html': 1, 'water/index.html': 0.5 };
  // … and how it matched.
  var W_EXACT = 1, W_PREFIX = 0.7, W_SYN = 0.6, W_FUZZY = 0.5;

  /** Lower-case, strip accents ("amêndoa" → "amendoa"). */
  function fold(s) {
    s = String(s || '').toLowerCase();
    return s.normalize ? s.normalize('NFD').replace(/[̀-ͯ]/g, '') : s;
  }
  /** Split into folded words (letters/digits). */
  function words(s) { return fold(s).match(/[a-z0-9]+/g) || []; }

  function undouble(w) { return /([^aeiouylsz])\1$/.test(w) ? w.slice(0, -1) : w; }
  // Nouns that only look like -ing forms ("bearing" is not "bear").
  var KEEP_ING = { bearing: 1, heading: 1, evening: 1, ceiling: 1, awning: 1, nothing: 1, something: 1, anything: 1, everything: 1 };
  /** Light English stemmer: plurals, -ing, -ed, final -e. Same rules on both sides. */
  function stem(w) {
    if (w.length <= 3 || /^\d/.test(w)) return w;
    if (/ies$/.test(w) && w.length > 4) w = w.slice(0, -3) + 'y';
    else if (/(ches|shes|sses|xes|zes)$/.test(w)) w = w.slice(0, -2);
    else if (/[^su]s$/.test(w)) w = w.slice(0, -1);
    if (KEEP_ING[w]) return w;
    if (/ing$/.test(w) && w.length >= 7) w = undouble(w.slice(0, -3));
    else if (/[^e]ed$/.test(w) && w.length >= 6) w = undouble(w.slice(0, -2));
    if (w.length > 3 && /e$/.test(w)) w = w.slice(0, -1);
    return w;
  }
  /** Words worth indexing / searching for. */
  function keep(w) { return !STOP[w] && (w.length > 1 || /\d/.test(w)); }

  /** Escape text for safe insertion as HTML. */
  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  /* ---------------- index ---------------- */
  var entries = null;     // array from search-index.json
  var postings = null;    // Map stem → Map(entryIndex → field mask)
  var rawVocab = null;    // Map folded word → stem (for prefix + typo matching)
  var bodyTf = null;      // per entry: Map stem → count in body text
  var syn = null;         // Map stem → array of stem-arrays
  var loading = null;

  function addWord(i, field, w) {
    if (!keep(w)) return;
    var s = stem(w);
    if (!rawVocab.has(w)) rawVocab.set(w, s);
    var m = postings.get(s);
    if (!m) { m = new Map(); postings.set(s, m); }
    m.set(i, (m.get(i) || 0) | MASK[field]);
    if (field === 't') bodyTf[i].set(s, (bodyTf[i].get(s) || 0) + 1);
  }

  function build(data) {
    entries = data;
    postings = new Map(); rawVocab = new Map(); bodyTf = [];
    entries.forEach(function (e, i) {
      bodyTf[i] = new Map();
      words(e.h).forEach(function (w) { addWord(i, 'h', w); });
      words(e.s).forEach(function (w) { addWord(i, 's', w); });
      words(e.c).forEach(function (w) { addWord(i, 'c', w); });
      words(e.pt).forEach(function (w) { addWord(i, 'pt', w); });
      words(e.k).forEach(function (w) { addWord(i, 'k', w); });
      words(e.t).forEach(function (w) { addWord(i, 't', w); });
      words(e.x).forEach(function (w) { addWord(i, 't', w); });
    });
    syn = new Map();
    Object.keys(SYNONYMS).forEach(function (k) {
      var key = stem(fold(k));
      var list = syn.get(key) || [];
      SYNONYMS[k].forEach(function (phrase) {
        var st = words(phrase).filter(keep).map(stem);
        if (st.length) list.push(st);
      });
      syn.set(key, list);
    });
    OGSearch.ready = true;
  }

  function indexUrl() {
    var root = (window.OGSK && OGSK.root) || document.documentElement.getAttribute('data-root') || './';
    return root + 'assets/data/search-index.json';
  }

  function load() {
    if (!loading) {
      loading = fetch(indexUrl())
        .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); })
        .then(build)
        .catch(function (err) { loading = null; throw err; });   // allow a retry
    }
    return loading;
  }

  /* ---------------- matching ---------------- */

  /** Entries + field masks where every stem of `st` appears in one same field. */
  function phraseHits(st) {
    var first = postings.get(st[0]);
    if (!first) return null;
    if (st.length === 1) return first;
    var out = new Map();
    first.forEach(function (mask, i) {
      var m = mask;
      for (var j = 1; j < st.length && m; j++) {
        var p = postings.get(st[j]);
        m &= p ? (p.get(i) || 0) : 0;
      }
      if (m) out.set(i, m);
    });
    return out.size ? out : null;
  }

  /** Bounded edit distance (Damerau-lite): returns > max as soon as it can. */
  function editDist(a, b, max) {
    if (Math.abs(a.length - b.length) > max) return max + 1;
    var prevPrev = null, prev = [], cur, rowMin, cost, i, j;
    for (j = 0; j <= b.length; j++) prev[j] = j;
    for (i = 1; i <= a.length; i++) {
      cur = [i];
      rowMin = i;
      for (j = 1; j <= b.length; j++) {
        cost = a[i - 1] === b[j - 1] ? 0 : 1;
        cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
        // swapped neighbours ("hte" → "the") count as one edit
        if (prevPrev && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) cur[j] = Math.min(cur[j], prevPrev[j - 2] + 1);
        if (cur[j] < rowMin) rowMin = cur[j];
      }
      if (rowMin > max) return max + 1;     // can only grow from here
      prevPrev = prev;
      prev = cur;
    }
    return prev[b.length];
  }

  /** Expand one query word into weighted alternatives: [{st:[stems], w, hits}] */
  function expand(word, isLast) {
    var s = stem(word), alts = [], seen = {};
    function add(st, w, kind) {
      var key = st.join(' ');
      if (seen[key] && seen[key] >= w) return;
      var hits = phraseHits(st);
      if (!hits) return;
      seen[key] = w;
      alts.push({ st: st, w: w, hits: hits, syn: kind === 'syn' });
    }
    add([s], W_EXACT);
    // Start of a longer word: "tourn" → tourniquet, "snake" → snakebite.
    // Needs 3+ letters (2 for the word still being typed).
    if (word.length >= 3 || (isLast && word.length >= 2)) {
      rawVocab.forEach(function (st, raw) {
        if (raw.length > word.length && raw.indexOf(word) === 0 && st !== s) add([st], W_PREFIX, 'prefix');
      });
    }
    (syn.get(s) || []).forEach(function (st) { add(st, W_SYN, 'syn'); });
    var fuzzy = null;
    if (!alts.length && word.length >= 4) {
      // Nothing at all: try near spellings ("tourniqet", "hypotermia").
      var max = word.length >= 8 ? 2 : 1, best = max + 1;
      rawVocab.forEach(function (st, raw) {
        if (raw.length < 3) return;
        var d = editDist(word, raw, max);
        if (d <= max) { add([st], W_FUZZY - 0.1 * (d - 1), 'fuzzy'); if (d < best) { best = d; fuzzy = raw; } }
      });
    }
    return { word: word, stem: s, alts: alts, fuzzy: fuzzy };
  }

  /** Stems in order, for phrase checks (cached per entry). */
  var seqCache = new Map();
  function seq(i, field) {
    var key = i + field, v = seqCache.get(key);
    if (!v) {
      var e = entries[i];
      v = ' ' + words(e[field]).filter(keep).map(stem).join(' ') + ' ';
      seqCache.set(key, v);
    }
    return v;
  }

  function search(q, limit) {
    limit = limit || 20;
    if (!entries) return null;
    var raw = words(q);
    var toks = raw.filter(keep);
    if (!toks.length) toks = raw.filter(function (w) { return w.length > 1; });
    toks = toks.filter(function (w, i) { return toks.indexOf(w) === i; });   // de-duplicate
    if (!toks.length) return { results: [], total: 0, fuzzy: {}, terms: [] };

    var terms = toks.map(function (w, i) { return expand(w, i === toks.length - 1); });
    var fuzzy = {};
    terms.forEach(function (t) { if (t.fuzzy) fuzzy[t.word] = t.fuzzy; });

    // How many query words each section matches (and how many of those are
    // real matches rather than spelling guesses).
    var nMatched = new Map(), nReal = new Map();
    terms.forEach(function (t) {
      var set = new Set();
      t.alts.forEach(function (a) { a.hits.forEach(function (m, i) { set.add(i); }); });
      set.forEach(function (i) {
        nMatched.set(i, (nMatched.get(i) || 0) + 1);
        if (!t.fuzzy) nReal.set(i, (nReal.get(i) || 0) + 1);
      });
    });
    // AND first; if that is thin, also take sections missing just one word
    // (as long as what they do match isn't only a spelling guess).
    var cand = new Set(), full = 0;
    nMatched.forEach(function (n, i) { if (n === terms.length) { cand.add(i); full++; } });
    var partial = false;
    if (full < 5 && terms.length >= 2) {
      nMatched.forEach(function (n, i) { if (n === terms.length - 1 && nReal.get(i)) { cand.add(i); partial = true; } });
    }

    var qSeq = ' ' + terms.map(function (t) { return t.stem; }).join(' ') + ' ';
    var scored = [];
    cand.forEach(function (i) {
      var e = entries[i], score = 0, inHead = 0, inStrong = 0;
      terms.forEach(function (t) {
        var best = 0, head = false, strong = false, onPage = false, curated = false;
        t.alts.forEach(function (a) {
          var m = a.hits.get(i);
          if (!m) return;
          var f = 0;
          if (m & MASK.h) { f = FIELD.h; head = true; }
          else if (m & MASK.k) f = FIELD.k;
          else if (m & MASK.s) f = FIELD.s;
          else if (m & MASK.c) f = FIELD.c;
          else if (m & MASK.pt) f = FIELD.pt;
          else if (m & MASK.t) {
            var tf = bodyTf[i].get(a.st[0]) || 1;      // repeated mentions count a little
            f = FIELD.t + Math.min(1.5, Math.log(1 + tf) / Math.LN2 * 0.5);
          }
          if (f * a.w > best) best = f * a.w;
          if (m & STRONG) strong = true;
          // also in the page title, on top of a better field
          if ((m & MASK.pt) && (m & (MASK.h | MASK.k | MASK.s | MASK.c | MASK.t))) onPage = true;
          // curated keyword on top of a heading match ("the" section for this word)
          if ((m & MASK.k) && (m & MASK.h)) curated = true;
        });
        score += best + (onPage ? 2 : 0) + (curated ? 3 : 0);
        if (head) inHead++;
        if (strong) inStrong++;
      });
      if (inHead === terms.length) score += 4;                       // every word in the heading
      else if (terms.length > 1 && inStrong === terms.length) score += 4;   // … or heading + page/section title
      if (seq(i, 'h').trim() === qSeq.trim()) score += 10;           // heading IS the query
      if (terms.length > 1) {                                         // exact phrase, in order
        if (seq(i, 'h').indexOf(qSeq) >= 0 || seq(i, 'k').indexOf(qSeq) >= 0) score += 12;
        else if (seq(i, 's').indexOf(qSeq) >= 0) score += 6;
        else if (seq(i, 't').indexOf(qSeq) >= 0) score += 4;
      }
      score += PAGE_PRIOR[e.p] || 0;
      score *= 1 - 0.15 * Math.min(1, (e.t || '').length / 1500);    // prefer shorter sections
      var all = nMatched.get(i) === terms.length;
      if (!all) score *= 0.5;                                          // close match only
      scored.push({ i: i, score: score, all: all });
    });
    scored.sort(function (a, b) { return b.score - a.score || a.i - b.i; });

    /* Stems to highlight in one result: the word itself (or its prefix / near
       spelling) where the section has it; synonyms only when it doesn't, so
       the user sees why it matched without a wall of yellow. */
    function hlFor(i) {
      var hl = new Set();
      terms.forEach(function (t) {
        var here = t.alts.filter(function (a) { return a.hits.has(i); });
        var direct = here.filter(function (a) { return !a.syn; });
        (direct.length ? direct : here).forEach(function (a) { a.st.forEach(function (s) { hl.add(s); }); });
      });
      return hl;
    }

    return {
      total: scored.length,
      exact: full,                 // sections matching every word
      partial: partial && scored.length > full,
      fuzzy: fuzzy,
      terms: toks,
      results: scored.slice(0, limit).map(function (r) {
        var e = entries[r.i], hl = hlFor(r.i);
        return {
          entry: e, score: Math.round(r.score * 100) / 100, url: urlFor(e), all: r.all,
          headHtml: mark(e.h, hl), ctxHtml: e.c ? mark(e.c, hl) : '', subHtml: e.s ? mark(e.s, hl) : '',
          snippetHtml: snippet(e.t || '', hl)
        };
      })
    };
  }

  /** Link to the section: page#anchor, plus ?find=<heading> when the heading has no id. */
  function urlFor(e) {
    var root = (window.OGSK && OGSK.root) || './';
    return root + e.p + (e.f ? '?find=' + encodeURIComponent(e.f) : '') + (e.a ? '#' + e.a : '');
  }

  /* ---------------- highlighting ---------------- */
  var WORD_RE = /[A-Za-z0-9À-ɏ]+/g;

  /** Positions [start, end] of words in `text` whose stem is in `hl`. */
  function hitsIn(text, hl) {
    var out = [], m;
    WORD_RE.lastIndex = 0;
    while ((m = WORD_RE.exec(text))) {
      var f = fold(m[0]);
      if (keep(f) && hl.has(stem(f))) out.push([m.index, m.index + m[0].length]);
    }
    return out;
  }
  /** Escape `text` and wrap hits in <mark>. `from`/`to` limit the range. */
  function render(text, hits, from, to) {
    var html = '', pos = from;
    hits.forEach(function (h) {
      if (h[0] < from || h[1] > to) return;
      html += esc(text.slice(pos, h[0])) + '<mark>' + esc(text.slice(h[0], h[1])) + '</mark>';
      pos = h[1];
    });
    return html + esc(text.slice(pos, to));
  }
  function mark(text, hl) { return render(text, hitsIn(text, hl), 0, text.length); }

  /** ~170 characters around the first match, cut at word boundaries. */
  function snippet(text, hl, size) {
    size = size || 170;
    if (!text) return '';
    var hits = hitsIn(text, hl);
    var start = 0;
    if (hits.length && hits[0][0] > 60) {
      start = text.lastIndexOf(' ', hits[0][0] - 50);
      start = start < 0 ? 0 : start + 1;
    }
    var end = Math.min(text.length, start + size);
    if (end < text.length) { var sp = text.lastIndexOf(' ', end); if (sp > start + size / 2) end = sp; }
    return (start > 0 ? '… ' : '') + render(text, hits, start, end) + (end < text.length ? ' …' : '');
  }

  var OGSearch = window.OGSearch = {
    ready: false,
    load: load,
    search: search,
    esc: esc,
    /* exposed for tests */
    _stem: stem, _words: words
  };
})();
