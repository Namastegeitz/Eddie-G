// FLOWSMITH prompt engine: pure functions, no DOM. Runs in the browser and in Node (tests).
// Builds Flow Music prompts in Google's order, critiques them against a written rubric,
// diffs versions, hash-chains history, and fills offline "next step" templates.

export const FLOW_URL = "https://flowmusic.app";
export const LABS_URL = "https://labs.google";

// Google's prompt order (Lyria 3 Pro guide): genre & style, mood, instrumentation,
// tempo & rhythm, vocal style & language, then lyrics. Structure and mix notes follow.
export const SLOTS = ["genre", "mood", "instruments", "tempo", "vocals", "structure", "production"];

export const CATEGORIES = [
  { id: "genre", label: "Genre & style", slot: "genre", tone: "red" },
  { id: "era", label: "Era", slot: "genre", tone: "red" },
  { id: "usecase", label: "Use it for", slot: "genre", tone: "red" },
  { id: "mood", label: "Mood", slot: "mood", tone: "orange" },
  { id: "energy", label: "Energy", slot: "mood", tone: "orange" },
  { id: "drums", label: "Drums & percussion", slot: "instruments", tone: "yellow" },
  { id: "bass", label: "Bass", slot: "instruments", tone: "yellow" },
  { id: "synths", label: "Synths", slot: "instruments", tone: "yellow" },
  { id: "keys", label: "Keys & piano", slot: "instruments", tone: "yellow" },
  { id: "guitars", label: "Guitars", slot: "instruments", tone: "yellow" },
  { id: "orchestral", label: "Strings, brass & choir", slot: "instruments", tone: "yellow" },
  { id: "world", label: "World instruments", slot: "instruments", tone: "yellow" },
  { id: "tuning", label: "Tunings", slot: "instruments", tone: "yellow" },
  { id: "groove", label: "Groove & rhythm", slot: "tempo", tone: "cream" },
  { id: "key", label: "Key, scale & mode", slot: "tempo", tone: "cream" },
  { id: "vocals", label: "Vocals", slot: "vocals", tone: "cream" },
  { id: "structure", label: "Song structure", slot: "structure", tone: "cream" },
  { id: "production", label: "Production & mix", slot: "production", tone: "cream" },
];
export const CAT_BY_ID = Object.fromEntries(CATEGORIES.map((c) => [c.id, c]));

export const LENGTHS = [
  { id: "clip", label: "30-second clip", seconds: 30, text: "a 30-second piece" },
  { id: "1m", label: "About 1 minute", seconds: 60, text: "about 1 minute long" },
  { id: "2m", label: "About 2 minutes", seconds: 120, text: "about 2 minutes long" },
  { id: "full", label: "Full song (~3 min)", seconds: 180, text: "a full song of about 3 minutes" },
];
export const LANGUAGES = ["English", "Spanish", "Portuguese", "French", "German", "Hindi", "Japanese", "Korean"];
export const NOTE_NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
const NOTE_INDEX = { C: 0, "B#": 0, "C#": 1, Db: 1, D: 2, "D#": 3, Eb: 3, E: 4, Fb: 4, F: 5, "E#": 5, "F#": 6, Gb: 6, G: 7, "G#": 8, Ab: 8, A: 9, "A#": 10, Bb: 10, B: 11, Cb: 11 };

// Shorthand people type that should light up a button.
export const ALIASES = {
  "808 drums": "dr-tr808", "909 drums": "dr-tr909", "505 drums": "dr-tr505", "707 drums": "dr-tr707", "606 drums": "dr-tr606",
  "808 drum machine": "dr-tr808", "505 drum machine": "dr-tr505",
  "808": "dr-tr808", "808s": "ba-808-sub", "909": "dr-tr909", "505": "dr-tr505", "707": "dr-tr707",
  "606": "dr-tr606", "303": "ba-acid-303", "sp1200": "dr-sp1200", "sp-1200": "dr-sp1200", "mpc": "dr-mpc",
  "linn": "dr-linndrum", "linndrum": "dr-linndrum", "rhodes": "kb-rhodes", "wurli": "kb-wurlitzer",
  "b3": "kb-hammond-b3", "hammond": "kb-hammond-b3", "dx7": "sy-dx7-epiano", "juno": "sy-juno-pad",
  "supersaw": "sy-supersaw", "lofi": "g-lofi-hiphop", "lo-fi": "g-lofi-hiphop", "boombap": "g-boom-bap",
  "boom bap": "g-boom-bap", "trap": "g-trap", "drill": "g-drill-uk", "dnb": "g-dnb",
  "drum and bass": "g-dnb", "drum n bass": "g-dnb", "rnb": "g-contemporary-rnb",
  "r&b": "g-contemporary-rnb", "neo soul": "g-neo-soul", "neosoul": "g-neo-soul", "house": "g-house",
  "techno": "g-techno", "synthwave": "g-synthwave", "amapiano": "g-amapiano", "afrobeats": "g-afrobeats",
  "reggaeton": "g-reggaeton", "phonk": "g-phonk", "instrumental": "vo-instrumental",
  "50s": "er-1950s", "60s": "er-1960s", "70s": "er-1970s", "80s": "er-1980s", "90s": "er-1990s", "y2k": "er-2000s", "2000s": "er-2000s",
  "female vocals": "vo-solo-female", "female vocal": "vo-solo-female", "female singer": "vo-solo-female", "female voice": "vo-solo-female",
  "male vocals": "vo-solo-male", "male vocal": "vo-solo-male", "male singer": "vo-solo-male", "male voice": "vo-solo-male", "duet": "vo-duet",
};
// Buttons that free text should never light up (ambiguous words, or handled by their own setting).
const NO_TEXT_MATCH = /^(vo-bass-voice|vo-lang-.+)$/;

const NEG_RE = /\b(no|not|without|avoid|don't|dont|never|exclude|minus|less of)\b/i;
const ARTIST_HINT_RE = /\b(in the style of|sounds? like|like)\s+([A-Z][\w'.&-]+(?:\s+[A-Z][\w'.&-]+){0,3})/;
const ARTISTS = /\b(drake|beyonc|taylor swift|kanye|dilla|dr\.? dre|metro boomin|travis scott|billie eilish|weeknd|daft punk|skrillex|aphex|zimmer|beatles|michael jackson|madonna|eminem|kendrick|rihanna|adele|ed sheeran|bad bunny|burna|wizkid|bob marley|nirvana|radiohead|tame impala|frank ocean|sza|post malone|calvin harris|avicii|deadmau5|kraftwerk|vangelis|john williams|morricone|pink floyd|led zeppelin|metallica|miles davis|coltrane|ariana|dua lipa|bruno mars|the beatles|bts|blackpink|lil |young thug|future\b|21 savage|playboi carti|juice wrld|xxxtentacion)\b/i;

// ---------- catalog ----------

/** Merge chip files into one catalog with lookup maps. */
export function makeCatalog(chipLists) {
  const chips = [];
  for (const list of chipLists) for (const c of (list && list.chips) || []) chips.push(c);
  const byId = new Map(chips.map((c) => [c.id, c]));
  const byCat = new Map(CATEGORIES.map((c) => [c.id, []]));
  for (const c of chips) (byCat.get(c.cat) || byCat.set(c.cat, []).get(c.cat)).push(c);
  return { chips, byId, byCat };
}

const norm = (s) => String(s || "").toLowerCase().replace(/[^a-z0-9&#+ -]+/g, " ").replace(/\s+/g, " ").trim();

/** Pull BPM, key, length, language and matching chips out of the words someone typed. */
export function parseQuery(q, catalog) {
  const text = String(q || "");
  const out = { bpm: null, key: null, chipIds: [], length: null, language: null, vocals: null, rest: "" };
  let rest = " " + text + " ";
  const bpm = text.match(/\b(\d{2,3})\s*(?:bpm|beats per minute)\b/i);
  if (bpm) { const n = +bpm[1]; if (n >= 40 && n <= 220) { out.bpm = n; rest = rest.replace(bpm[0], " "); } }
  const key = text.match(/\b([A-G])\s?(#|b|sharp|flat)?\s?(major|minor|maj|min|m)\b/);
  if (key) {
    const acc = key[2] === "sharp" ? "#" : key[2] === "flat" ? "b" : key[2] || "";
    const q2 = /^(minor|min|m)$/.test(key[3]) ? "minor" : "major";
    out.key = `${key[1]}${acc} ${q2}`;
    rest = rest.replace(key[0], " ");
  }
  const len = text.match(/\b(30\s*(?:s|sec|second)s?|1\s*min(?:ute)?|2\s*min(?:ute)?s?|3\s*min(?:ute)?s?|full song)\b/i);
  if (len) {
    const t = len[1].toLowerCase();
    out.length = t.startsWith("30") ? "clip" : t.startsWith("1") ? "1m" : t.startsWith("2") ? "2m" : "full";
    rest = rest.replace(len[0], " ");
  }
  for (const L of LANGUAGES) if (new RegExp(`\\b(in\\s+)?${L}\\b`, "i").test(text) && L !== "English") { out.language = L; rest = rest.replace(new RegExp(`\\b(in\\s+)?${L}\\b`, "i"), " "); }
  if (/\binstrumental\b/i.test(text)) out.vocals = "instrumental";
  else if (/\b(vocals?|singer|singing|sung|rap|rapper|lyrics)\b/i.test(text)) out.vocals = "vocals";

  const found = new Set();
  let lower = " " + norm(rest) + " "; // BPM, key, length and language are already taken out
  const esc = (s) => s.replace(/[.*+?^${}()|[\]\\&]/g, "\\$&");
  // Button labels and typed shorthand, longest phrase first, so "deep house" wins over "house".
  const phrases = Object.entries(ALIASES).filter(([, id]) => !catalog || catalog.byId.has(id)).map(([l, id]) => ({ id, l }));
  if (catalog) phrases.push(...catalog.chips.filter((c) => !NO_TEXT_MATCH.test(c.id)).map((c) => ({ id: c.id, l: norm(c.label) })).filter((x) => x.l.length >= 3));
  phrases.sort((a, b) => b.l.length - a.l.length);
  for (const { id, l } of phrases) {
    if (!lower.includes(" " + l + " ")) continue;
    found.add(id);
    lower = lower.replace(" " + l + " ", "  ");
    rest = rest.replace(new RegExp(`(^|[^a-z0-9])${esc(l)}(?=$|[^a-z0-9])`, "i"), "$1 ");
  }
  out.chipIds = [...found];
  out.rest = tidyRest(rest);
  return out;
}

// Little words left dangling once BPM, keys and buttons are pulled out ("in", "with", "and"...).
const GLUE = new Set(["in", "with", "and", "at", "a", "an", "the", "of", "on", "for", "plus", "&", "some", "using", "featuring", "feat", "w/", "to", "by", "around", "about"]);
export function tidyRest(text) {
  return String(text || "").split(/[,;]+/).map((seg) => {
    let w = seg.trim().split(/\s+/).filter(Boolean);
    w = w.filter((x, i) => !(GLUE.has(x.toLowerCase()) && i + 1 < w.length && GLUE.has(w[i + 1].toLowerCase())));
    while (w.length && GLUE.has(w[0].toLowerCase())) w.shift();
    while (w.length && GLUE.has(w[w.length - 1].toLowerCase())) w.pop();
    if (w.length === 1 && /^(drums?|beats?|music|song|track|vibes?|bpm|key)$/i.test(w[0])) return "";
    return w.join(" ");
  }).filter(Boolean).join(", ");
}

// ---------- keys ----------

export function parseKey(k) {
  const m = String(k || "").match(/^([A-G])(#|b)?\s*(major|minor)$/i);
  if (!m) return null;
  return { root: m[1].toUpperCase() + (m[2] || ""), minor: /minor/i.test(m[3]) };
}
export function transposeKey(k, semis) {
  const p = parseKey(k); if (!p) return k;
  const i = (NOTE_INDEX[p.root] + semis + 120) % 12;
  return `${NOTE_NAMES[i]} ${p.minor ? "minor" : "major"}`;
}
export function relativeKey(k) {
  const p = parseKey(k); if (!p) return k;
  return p.minor ? transposeKey(`${p.root} major`, 3) : transposeKey(`${p.root} minor`, -3);
}
export const ALL_KEYS = NOTE_NAMES.flatMap((n) => [`${n} major`, `${n} minor`]);

// ---------- building ----------

/** A Studio state. Everything optional except chips (array of ids). */
export function blankState() {
  return {
    query: "", brief: null, chips: [], bpm: null, key: "", length: "2m", vocals: "auto", language: "English",
    lyricsMode: "theme", lyricTheme: "", lyrics: "", format: "prose", timestamps: false, notes: "",
  };
}

const cap = (s) => (s ? s.charAt(0).toUpperCase() + s.slice(1) : s);
const joinList = (xs) => xs.length <= 1 ? xs.join("") : xs.slice(0, -1).join(", ") + " and " + xs[xs.length - 1];
const end = (s) => (/[.!?]$/.test(s) ? s : s + ".");

/** Group the chosen chips into Google's slots, in catalog order. */
export function slotFragments(state, catalog) {
  const by = Object.fromEntries(SLOTS.map((s) => [s, []]));
  const cats = Object.fromEntries(CATEGORIES.map((c) => [c.id, []]));
  for (const id of state.chips || []) {
    const c = catalog.byId.get(id); if (!c) continue;
    const cat = CAT_BY_ID[c.cat]; if (!cat) continue;
    cats[c.cat].push(c.prompt.trim().replace(/\.$/, ""));
  }
  for (const c of CATEGORIES) by[c.slot].push(...cats[c.id]);
  return { by, cats };
}

/** Vocal intent after looking at chips: "instrumental" | "vocals" | "auto". */
export function vocalIntent(state) {
  if (state.vocals === "instrumental" || (state.chips || []).includes("vo-instrumental")) return "instrumental";
  if (state.vocals === "vocals") return "vocals";
  if ((state.chips || []).some((id) => id.startsWith("vo-") && id !== "vo-instrumental")) return "vocals";
  return state.vocals || "auto";
}

/** Build the Flow Music prompt (and a separate lyrics block) from a Studio state. */
export function buildPrompt(state, catalog) {
  const { by, cats } = slotFragments(state, catalog);
  // `brief` = the typed words left after BPM/key/buttons were pulled out; Claude still gets `query`.
  const brief = String(state.brief ?? state.query ?? "").trim();
  const voc = vocalIntent(state);
  const len = LENGTHS.find((l) => l.id === state.length);
  const parts = {};

  // 1 genre & style (+ era, use case)
  const genre = [...cats.genre, ...cats.era, ...cats.usecase];
  parts.genre = genre.length ? genre.join(", ") : "";
  // 2 mood
  parts.mood = by.mood.join(", ");
  // 3 instrumentation
  parts.instruments = by.instruments.length ? by.instruments.join("; ") : "";
  // 4 tempo & rhythm
  const tempoBits = [];
  if (state.bpm) tempoBits.push(`${state.bpm} BPM`);
  tempoBits.push(...cats.groove);
  if (state.key) tempoBits.push(`in ${state.key}`);
  tempoBits.push(...cats.key);
  parts.tempo = tempoBits.join(", ");
  // 5 vocals & language
  if (voc === "instrumental") parts.vocals = "instrumental";
  else {
    const v = [...by.vocals.filter((f) => !/^instrumental/i.test(f))];
    const lang = state.language && state.language !== "English" ? `sung in ${state.language}` : (v.length ? "sung in English" : "");
    if (lang) v.push(lang);
    if (state.lyricsMode === "theme" && state.lyricTheme) v.push(`lyrics about ${state.lyricTheme.trim().replace(/\.$/, "")}`);
    parts.vocals = v.join(", ");
  }
  // 6 structure & length
  const st = [...by.structure];
  if (len) st.push(len.text);
  parts.structure = st.join(", ");
  // 7 production & mix
  parts.production = by.production.join(", ");

  let lines;
  if (state.format === "labeled") {
    const L = { genre: "Genre & style", mood: "Mood", instruments: "Instruments", tempo: "Tempo & rhythm", vocals: "Vocals", structure: "Structure", production: "Production" };
    lines = [];
    if (brief) lines.push(end(cap(brief)));
    for (const s of SLOTS) if (parts[s]) lines.push(`${L[s]}: ${end(parts[s])}`);
  } else {
    lines = [];
    if (brief && parts.genre) lines.push(end(`${cap(parts.genre)}, inspired by: ${brief}`));
    else if (brief) lines.push(end(cap(brief)));
    else if (parts.genre) lines.push(end(cap(parts.genre)));
    if (parts.mood) lines.push(end(`The mood is ${parts.mood}`));
    if (parts.instruments) lines.push(end(`Featuring ${parts.instruments}`));
    if (parts.tempo) lines.push(end(cap(parts.tempo)));
    if (parts.vocals) lines.push(end(voc === "instrumental" ? "Instrumental, with the lead melody carried by the instruments" : cap(parts.vocals)));
    if (parts.structure) lines.push(end(cap(parts.structure)));
    if (parts.production) lines.push(end(`Production: ${parts.production}`));
  }
  if (state.timestamps) {
    const tl = timeline(state, catalog);
    if (tl) lines.push(tl);
  }
  if (state.notes) lines.push(end(cap(state.notes.trim())));
  const prompt = lines.join(state.format === "labeled" ? "\n" : " ").replace(/\s+\./g, ".").trim();

  let lyrics = "";
  if (voc !== "instrumental" && state.lyricsMode === "mine" && state.lyrics.trim()) lyrics = formatLyrics(state.lyrics);
  return { prompt, lyrics, parts };
}

/** Make sure pasted lyrics sit under a "Lyrics:" header with [Section] tags. */
export function formatLyrics(text) {
  let t = String(text || "").replace(/\r/g, "").trim();
  if (!t) return "";
  t = t.replace(/^lyrics:\s*/i, "");
  // "Verse 1:" or "(Chorus)" on their own line become [Verse 1] / [Chorus]
  t = t.replace(/^[(\[]?\s*(intro|verse(?:\s*\d+)?|pre-?chorus|chorus|hook|post-?chorus|bridge|outro|breakdown|drop|refrain)\s*[)\]:]?\s*$/gim,
    (_, s) => `[${s.replace(/\b\w/g, (c) => c.toUpperCase()).replace(/Pre-?chorus/i, "Pre-Chorus").replace(/Post-?chorus/i, "Post-Chorus")}]`);
  if (!/^\[/.test(t)) t = "[Verse 1]\n" + t;
  return "Lyrics:\n" + t;
}

/** Section plan in bars for a length, used for timestamp prompts. */
const PLANS = {
  clip: [["Intro", 2], ["Hook", 8], ["Ending", 2]],
  "1m": [["Intro", 4], ["Verse", 8], ["Chorus", 8], ["Outro", 4]],
  "2m": [["Intro", 4], ["Verse 1", 8], ["Chorus", 8], ["Verse 2", 8], ["Chorus", 8], ["Outro", 4]],
  full: [["Intro", 8], ["Verse 1", 16], ["Pre-Chorus", 4], ["Chorus", 8], ["Verse 2", 16], ["Pre-Chorus", 4], ["Chorus", 8], ["Bridge", 8], ["Final chorus", 8], ["Outro", 8]],
};
export function timeline(state, catalog) {
  const bpm = state.bpm || 100;
  const plan = PLANS[state.length] || PLANS["2m"];
  const barSec = (60 / bpm) * 4;
  const len = LENGTHS.find((l) => l.id === state.length) || LENGTHS[2];
  const total = plan.reduce((s, [, b]) => s + b, 0) * barSec;
  const scale = total > len.seconds * 1.25 ? len.seconds / total : 1; // squeeze slow songs into the target length
  let t = 0;
  const fmt = (s) => `${String(Math.floor(s / 60)).padStart(2, "0")}:${String(Math.round(s % 60)).padStart(2, "0")}`;
  const lines = [];
  for (const [name, bars] of plan) {
    const what = /intro/i.test(name) ? "sparse intro, main motif enters" : /verse/i.test(name) ? "verse, groove settles, room for the vocal" : /pre/i.test(name) ? "pre-chorus lift, tension builds" : /chorus|hook/i.test(name) ? "full chorus, biggest energy and the hook" : /bridge/i.test(name) ? "bridge, new chords and a change of texture" : "outro, elements drop away to a clean ending";
    lines.push(`[${fmt(t)}] ${name}: ${what}`);
    t += bars * barSec * scale;
  }
  return lines.join("\n");
}

// ---------- critic (deterministic rubric) ----------

export const RUBRIC = [
  { id: "genre", label: "Names a genre and style", weight: 16, fix: "Add a genre button (Genre & style) or name the style in your words." },
  { id: "mood", label: "Sets a mood with clear adjectives", weight: 12, fix: "Pick a Mood button, e.g. melancholic or euphoric." },
  { id: "instruments", label: "Names at least two instruments", weight: 16, fix: "Pick drums plus one more instrument so Lyria doesn't fall back on genre defaults." },
  { id: "tempo", label: "Gives a tempo (BPM or feel)", weight: 12, fix: "Set the BPM slider or pick a Groove button." },
  { id: "vocals", label: "Says vocals or instrumental", weight: 10, fix: "Choose Vocals or Instrumental, and describe the voice." },
  { id: "positive", label: "Describes what to include (no negatives)", weight: 12, fix: "Lyria has no negative prompts. Rewrite 'no drums' as what you want, e.g. 'only piano and strings'." },
  { id: "artists", label: "Describes sounds, not artist names", weight: 10, fix: "Swap the name for what you like about it: era, instruments, voice, mood." },
  { id: "lyricsApart", label: "Keeps lyrics apart from production notes", weight: 6, fix: "Put lyrics under a 'Lyrics:' header with [Verse]/[Chorus] tags." },
  { id: "length", label: "Detailed but focused (25-220 words)", weight: 6, fix: "Very short prompts sound generic; very long ones blur. Aim for 40-150 words." },
  { id: "conflicts", label: "No clashing instructions", weight: 0, fix: "Two BPMs, two keys, or 'instrumental' plus a singer confuse the model." },
];

const GENRE_WORDS = /\b(hip[- ]?hop|trap|drill|r&b|rnb|soul|funk|disco|pop|house|techno|trance|dubstep|drum (?:&|and) bass|dnb|jungle|garage|ambient|synthwave|lo-?fi|jazz|blues|rock|metal|punk|indie|folk|country|reggae|reggaeton|dancehall|afrobeats?|amapiano|gospel|classical|orchestral|cinematic|score|ballad|edm|electronic|bossa|salsa|cumbia|phonk|grunge|shoegaze|chiptune|k-pop|j-pop|hyperpop|bluegrass|trip-hop|idm|breakbeat|electro)\b/i;
const MOOD_WORDS = /\b(happy|sad|dark|bright|melanchol\w*|euphoric|dreamy|moody|calm|peaceful|aggressive|angry|romantic|nostalgic|uplifting|epic|eerie|haunting|chill|relaxed|energetic|intense|playful|hopeful|brooding|mysterious|tense|joyful|bittersweet|wistful|triumphant|menacing|cozy|warm|lonely|gritty|sensual|smooth|emotional|anthemic|hypnotic|uneasy|somber|soulful)\b/i;
const INSTRUMENT_WORDS = /\b(drums?|kick|snare|hi-?hats?|808s?|909|505|percussion|bass|sub|synths?|pads?|leads?|arp\w*|piano|keys|rhodes|organ|guitars?|strings?|violin|cello|viola|brass|horns?|trumpet|trombone|sax\w*|flute|clarinet|choir|harp|bells?|marimba|vibraphone|sitar|tabla|kalimba|banjo|mandolin|ukulele|accordion|harmonica|congas?|bongos?|shaker|claps?|wurlitzer|mellotron|moog|juno|dx7|303|log drum|steel pan|orchestra)\b/gi;
const TEMPO_WORDS = /\b(\d{2,3}\s*bpm|slow|mid-?tempo|uptempo|up-tempo|fast|driving|laid-?back|half-?time|double-?time|swing\w*|shuffle|groove|four-on-the-floor|waltz|6\/8|3\/4|tempo)\b/i;

/** Score a prompt against the rubric. Returns {score, grade, checks}. */
export function critique(prompt, lyrics = "", state = null, catalog = null) {
  const text = String(prompt || "");
  const body = text.split(/\n\s*lyrics:/i)[0];
  const chips = new Set((state && state.chips) || []);
  const hasCat = (cat) => catalog ? [...chips].some((id) => catalog.byId.get(id)?.cat === cat) : false;
  const words = body.trim().split(/\s+/).filter(Boolean).length;
  const instruments = new Set((body.match(INSTRUMENT_WORDS) || []).map((w) => w.toLowerCase().replace(/s$/, "")));
  const checks = [];
  const add = (id, ok, detail = "") => { const r = RUBRIC.find((x) => x.id === id); checks.push({ id, label: r.label, ok: !!ok, weight: r.weight, fix: ok ? "" : r.fix, detail }); };

  add("genre", hasCat("genre") || GENRE_WORDS.test(body));
  add("mood", hasCat("mood") || MOOD_WORDS.test(body));
  add("instruments", instruments.size >= 2, `${instruments.size} found`);
  add("tempo", (state && state.bpm) || hasCat("groove") || TEMPO_WORDS.test(body));
  add("vocals", /\binstrumental\b/i.test(body) || /\b(vocal|voice|sung|sing|singer|rap|rapper|choir|falsetto|croon|belt|harmonies)\w*/i.test(body) || !!String(lyrics).trim());
  const neg = body.match(NEG_RE);
  add("positive", !neg, neg ? `found "${neg[0]}"` : "");
  const art = body.match(ARTISTS) || (body.match(ARTIST_HINT_RE) && !/\b(TR|SP|MPC|DX|Juno|Moog|Prophet|Rhodes|Hammond|Roland|Yamaha|Korg)\b/.test(body.match(ARTIST_HINT_RE)[2]) ? body.match(ARTIST_HINT_RE) : null);
  add("artists", !art, art ? `found "${(art[2] || art[0]).trim()}"` : "");
  add("lyricsApart", !/\[(verse|chorus|bridge|hook|pre-chorus)[^\]]*\]/i.test(body) || /^\s*\[\d{1,2}:\d{2}\]/m.test(body));
  add("length", words >= 25 && words <= 220, `${words} words`);
  // conflicts
  const conflicts = [];
  const bpms = [...new Set((body.match(/\b(\d{2,3})\s*bpm/gi) || []).map((s) => parseInt(s, 10)))];
  if (bpms.length > 1) conflicts.push(`${bpms.length} different BPMs (${bpms.join(", ")})`);
  const keys = [...new Set((body.match(/\bin [A-G](?:#|b)? (?:major|minor)\b/g) || []))];
  if (keys.length > 1) conflicts.push(`${keys.length} keys`);
  if (/\binstrumental\b/i.test(body) && (/\b(sung in|singer|rapper|vocals? (?:are|with)|female vocal|male vocal)\b/i.test(body) || String(lyrics).trim())) conflicts.push("instrumental plus a singer");
  add("conflicts", !conflicts.length, conflicts.join("; "));

  const total = RUBRIC.reduce((s, r) => s + r.weight, 0);
  let score = Math.round((checks.reduce((s, c) => s + (c.ok ? c.weight : 0), 0) / total) * 100);
  if (conflicts.length) score = Math.max(0, score - 10 * conflicts.length);
  const grade = score >= 90 ? "A" : score >= 75 ? "B" : score >= 60 ? "C" : score >= 40 ? "D" : "E";
  return { score, grade, checks, words };
}

// ---------- diff ----------

/** Word-level diff (LCS). Returns [{t:"same"|"add"|"del", s}] */
export function diffWords(a, b) {
  const A = String(a || "").split(/(\s+)/).filter((x) => x !== "");
  const B = String(b || "").split(/(\s+)/).filter((x) => x !== "");
  const n = A.length, m = B.length;
  if (n * m > 4_000_000) return [{ t: "del", s: a }, { t: "add", s: b }];
  const dp = Array.from({ length: n + 1 }, () => new Uint16Array(m + 1));
  for (let i = n - 1; i >= 0; i--) for (let j = m - 1; j >= 0; j--) dp[i][j] = A[i] === B[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]);
  const out = [];
  const push = (t, s) => { const last = out[out.length - 1]; if (last && last.t === t) last.s += s; else out.push({ t, s }); };
  let i = 0, j = 0;
  while (i < n && j < m) {
    if (A[i] === B[j]) { push("same", A[i]); i++; j++; }
    else if (dp[i + 1][j] >= dp[i][j + 1]) push("del", A[i++]);
    else push("add", B[j++]);
  }
  while (i < n) push("del", A[i++]);
  while (j < m) push("add", B[j++]);
  return out;
}
export function chipDiff(aIds, bIds) {
  const A = new Set(aIds || []), B = new Set(bIds || []);
  return { added: [...B].filter((x) => !A.has(x)), removed: [...A].filter((x) => !B.has(x)) };
}

// ---------- history chain (tamper-evident) ----------

export async function sha256Hex(str) {
  const data = new TextEncoder().encode(str);
  const buf = await globalThis.crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(buf)].map((x) => x.toString(16).padStart(2, "0")).join("");
}
const canon = (v) => JSON.stringify({ n: v.n, prompt: v.prompt || "", lyrics: v.lyrics || "", chips: [...(v.chips || [])].sort(), settings: v.settings || {}, createdAt: v.createdAt || "" });
export async function sealVersion(version, prevHash) {
  const prev = prevHash || "genesis";
  return { ...version, prevHash: prev, hash: await sha256Hex(prev + "|" + canon(version)) };
}
/** Returns {ok, brokenAt} — brokenAt is the version number where the chain stops matching. */
export async function verifyChain(versions) {
  let prev = "genesis";
  for (const v of [...versions].sort((a, b) => a.n - b.n)) {
    if (v.prevHash !== prev) return { ok: false, brokenAt: v.n };
    const h = await sha256Hex(prev + "|" + canon(v));
    if (h !== v.hash) return { ok: false, brokenAt: v.n };
    prev = v.hash;
  }
  return { ok: true, brokenAt: null };
}

// ---------- quick tweaks (offline) ----------

/** Deterministic one-tap tweaks. Returns a new state and a change note. */
export function quickTweak(state, op, catalog) {
  const s = { ...state, chips: [...(state.chips || [])] };
  const has = (id) => s.chips.includes(id);
  const addChip = (id) => { if (catalog.byId.has(id) && !has(id)) s.chips.push(id); };
  const dropCat = (cat) => { s.chips = s.chips.filter((id) => catalog.byId.get(id)?.cat !== cat); };
  let note = "";
  switch (op) {
    case "bpm+5": s.bpm = Math.min(220, (s.bpm || 100) + 5); note = `Tempo up to ${s.bpm} BPM`; break;
    case "bpm-5": s.bpm = Math.max(40, (s.bpm || 100) - 5); note = `Tempo down to ${s.bpm} BPM`; break;
    case "halftime": s.bpm = s.bpm ? Math.max(40, Math.round(s.bpm / 2)) : s.bpm; addChip("gr-half-time"); note = "Half-time feel"; break;
    case "doubletime": s.bpm = s.bpm ? Math.min(220, s.bpm * 2) : s.bpm; addChip("gr-double-time"); note = "Double-time feel"; break;
    case "key+1": s.key = transposeKey(s.key || "C minor", 1); note = `Key up a half step to ${s.key}`; break;
    case "key-1": s.key = transposeKey(s.key || "C minor", -1); note = `Key down a half step to ${s.key}`; break;
    case "relative": s.key = relativeKey(s.key || "A minor"); note = `Switched to the relative key, ${s.key}`; break;
    case "instrumental": s.vocals = "instrumental"; s.chips = s.chips.filter((id) => !id.startsWith("vo-")); note = "Made it instrumental"; break;
    case "vocals": s.vocals = "vocals"; s.chips = s.chips.filter((id) => id !== "vo-instrumental"); note = "Added vocals"; break;
    case "darker": dropCat("mood"); ["mo-brooding", "mo-menacing", "mo-haunting"].some((id) => catalog.byId.has(id) && (addChip(id), true)); if (s.key && !parseKey(s.key)?.minor) s.key = relativeKey(s.key); note = "Darker mood"; break;
    case "brighter": dropCat("mood"); ["mo-euphoric", "mo-hopeful", "mo-playful"].some((id) => catalog.byId.has(id) && (addChip(id), true)); if (s.key && parseKey(s.key)?.minor) s.key = relativeKey(s.key); note = "Brighter mood"; break;
    case "stripback": s.chips = s.chips.filter((id) => !["synths", "orchestral", "world"].includes(catalog.byId.get(id)?.cat)); note = "Stripped back to the core instruments"; break;
    case "longer": { const order = ["clip", "1m", "2m", "full"]; s.length = order[Math.min(3, order.indexOf(s.length) + 1)] || "full"; note = "Longer"; break; }
    case "shorter": { const order = ["clip", "1m", "2m", "full"]; s.length = order[Math.max(0, order.indexOf(s.length) - 1)] || "clip"; note = "Shorter"; break; }
    default: note = "";
  }
  return { state: s, note };
}
export const QUICK_TWEAKS = [
  ["bpm+5", "BPM +5"], ["bpm-5", "BPM −5"], ["halftime", "Half-time"], ["doubletime", "Double-time"],
  ["key+1", "Key up"], ["key-1", "Key down"], ["relative", "Relative key"], ["darker", "Darker"],
  ["brighter", "Brighter"], ["stripback", "Strip back"], ["instrumental", "Instrumental"], ["vocals", "Add vocals"],
  ["longer", "Longer"], ["shorter", "Shorter"],
];

// ---------- next steps (offline templates) ----------

/** Fill {placeholders} in an edit template from a song/version. */
export function fillTemplate(tpl, ctx) {
  return String(tpl || "").replace(/\{(\w+)\}/g, (m, k) => (ctx[k] !== undefined && ctx[k] !== "" ? String(ctx[k]) : m));
}

/** Offline additive prompts for a song: Flow edits plus next songs in the series. */
export function offlineNextSteps(version, catalog, recipes) {
  const st = version.state || blankState();
  const labels = (cat) => (st.chips || []).map((id) => catalog.byId.get(id)).filter((c) => c && c.cat === cat).map((c) => c.label);
  const genre = labels("genre")[0] || "the same style";
  const inst = [...labels("drums"), ...labels("synths"), ...labels("keys")].slice(0, 3).join(", ") || "the same core instruments";
  const ctx = { section: "chorus", style: "acoustic", instrument: labels("keys")[0] || labels("synths")[0] || "piano", bars: 4, mood: labels("mood")[0] || "hopeful", genre, bpm: st.bpm || "", key: st.key || "" };
  const items = [];
  for (const e of (recipes && recipes.edits) || []) {
    if (["extend", "cover", "replace", "compose", "stems", "lyrics"].includes(e.mode)) items.push({ kind: e.mode, label: e.label, prompt: fillTemplate(e.template, ctx), why: e.when });
  }
  const bpm = st.bpm || 100;
  const rel = st.key ? relativeKey(st.key) : "";
  const base = version.prompt || "";
  items.push({ kind: "next-song", label: "Next track, same world, more energy", prompt: `Companion track to the last song: ${genre} with ${inst}, same sonic palette and mix character, pushed to ${bpm + 8} BPM${rel ? ` in ${rel}` : ""} with a bigger, more driving chorus and a hookier lead melody.`, why: "Keeps the sound of the series while the energy rises, like track 2 of an EP." });
  items.push({ kind: "next-song", label: "Next track, the slow one", prompt: `Slow companion piece in the same world: ${genre} textures with ${inst}, around ${Math.max(60, bpm - 25)} BPM, sparse arrangement, more space and reverb, intimate and reflective, building gently to one emotional peak.`, why: "Every EP needs a breather; reusing the palette keeps it cohesive." });
  items.push({ kind: "next-song", label: "Interlude / intro track", prompt: `Short 30-second interlude built from the same palette: ${inst}, free-time ambient intro that hints at the main melody, field-recording texture, ending on a sustained chord.`, why: "Ties the songs together and gives Flow a short, cheap generation to test the palette." });
  if (base) items.push({ kind: "variation", label: "Same prompt, different era", prompt: base.replace(/\b(19\d0s|20\d0s|modern|futuristic)\b/i, "1980s") + (/(1980s)/.test(base) ? "" : " Reimagined with 1980s analog synths and gated reverb drums."), why: "Era swaps keep the song idea but change every sound choice." });
  return items;
}

// ---------- house rules for Claude ----------

export const HOUSE_RULES = [
  "Write for Google Flow Music (Google Labs, running DeepMind's Lyria 3.5).",
  "Order the prompt the way Google's Lyria guide does: genre and style (with era), then mood, then instrumentation, then tempo and rhythm (BPM, groove, key), then vocal style and language. Arrangement/length and mix notes may follow.",
  "Be specific and descriptive: vivid adjectives, named instruments with tone and playing style, BPM and key. Vague prompts get generic songs.",
  "Lyria has no negative prompts. Never write 'no X', 'without X' or 'avoid X'; describe what to include instead. For no vocals, write 'instrumental'.",
  "Never name artists, bands, producers, or songs. Translate any reference into era, instruments, production, voice and mood. Gear names (TR-808, Rhodes, Juno-60) are fine.",
  "Write only original lyrics. Never reproduce or closely paraphrase existing lyrics.",
  "Lyrics go in a separate block that starts with 'Lyrics:' and uses section tags like [Intro], [Verse 1], [Pre-Chorus], [Chorus], [Bridge], [Outro]. Keep production notes out of the lyrics.",
  "Vocals: describe gender, range, timbre and delivery (e.g. 'warm female alto, breathy, close-mic, conversational phrasing'). Supported vocal languages: English, Spanish, Portuguese, French, German, Hindi, Japanese, Korean.",
  "Songs run up to about 3 minutes. State the length; timestamp lines like '[00:00] ...' can script the arrangement.",
  "Keep the main prompt between 50 and 160 words.",
];
