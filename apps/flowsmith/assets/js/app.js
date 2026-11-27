// FLOWSMITH app: Studio, Songs (folders + versions), Next (additive prompts), Library, Learn, Setup.
import * as E from "./engine.js";
import { AGENTS, API_MODELS, runAgent, statusLight, buildRequest } from "./ai.js";
import { openStore, newId, exportAll, importAll } from "./store.js";

const VERSION = "1.0.0";
const VIEWS = ["studio", "songs", "next", "library", "learn", "setup"];
const IN_ARTIFACT = !!globalThis.claude;
const DEFAULT_SETTINGS = { aiMode: "auto", tier: "default", apiModel: "claude-opus-5-5", apiEffort: "medium", dailyCap: 80, claudeCritic: false, autoLesson: true };

const S = {
  cat: E.makeCatalog([]), beats: { patterns: [] }, recipes: { recipes: [], tunings: [], edits: [] }, learn: { sections: [] }, flow: { sections: [] },
  store: null, storeReady: null, songs: [], songsLoaded: false, songsNote: "",
  settings: { ...DEFAULT_SETTINGS }, lessons: { items: [] }, traces: { days: {}, recent: [] }, snippets: { items: [] },
  st: E.blankState(), out: { title: "", prompt: "", lyrics: "", source: "none", why: "", variations: [], stale: false, critic: null, changeNote: "" },
  edit: null, catId: "genre", padFilter: "", infoId: null, busy: null,
  openId: null, versions: [], vUnsub: null, selN: null, cmpN: null, tweakOps: [], tweakText: "", rate: null,
  lib: { tab: "snippets", q: "", cat: "all", limit: 60 }, learnId: "fl-what", learnQ: "", nextSongId: null,
  ai: { sample: null, sampleBlocked: false, dict: null, desk: null }, installEvt: null, pendingRender: false,
};

// ---------- tiny DOM helpers ----------
function h(tag, props, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props || {})) {
    if (v === undefined || v === null || v === false) continue;
    if (k === "class") el.className = v;
    else if (k === "text") el.textContent = v;
    else if (k === "style") el.setAttribute("style", v);
    else if (k.startsWith("on") && typeof v === "function") el.addEventListener(k.slice(2), v);
    else if (["value", "checked", "disabled", "hidden", "selected", "open"].includes(k)) el[k] = v;
    else el.setAttribute(k, v === true ? "" : String(v));
  }
  for (const kid of kids.flat(Infinity)) if (kid !== null && kid !== undefined && kid !== false) el.append(kid instanceof Node ? kid : document.createTextNode(String(kid)));
  return el;
}
const $ = (sel, root = document) => root.querySelector(sel);
const put = (el, items) => el && el.replaceChildren(...[items].flat(Infinity).filter((x) => x !== null && x !== undefined && x !== false));
const view = () => $("#view");
const fmtDate = (iso) => { try { return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" }); } catch { return ""; } };
const words = (s) => String(s || "").trim().split(/\s+/).filter(Boolean).length;
const toneOf = (chip) => E.CAT_BY_ID[chip?.cat]?.tone || "cream";
const safeUrl = (u) => (/^https:\/\/[^\s]+$/i.test(String(u || "").trim()) ? String(u).trim() : "");
const ls = { get(k, d) { try { const v = localStorage.getItem(k); return v === null ? d : JSON.parse(v); } catch { return d; } }, set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch {} } };

function linkify(text) {
  const parts = String(text).split(/(https:\/\/[^\s)]+)/g);
  return parts.map((p) => (/^https:\/\//.test(p) ? h("a", { href: p, target: "_blank", rel: "noopener" }, p) : p));
}

let toastTimer;
function toast(msg) {
  document.querySelector(".toast")?.remove();
  const t = h("div", { class: "toast", role: "status" }, msg);
  document.body.append(t);
  clearTimeout(toastTimer); toastTimer = setTimeout(() => t.remove(), 3200);
}

function dialog({ title, body, actions = [{ label: "Close", value: null }] }) {
  return new Promise((resolve) => {
    const prev = document.activeElement;
    const close = (v) => { wrap.remove(); document.removeEventListener("keydown", onKey); prev?.focus?.(); resolve(v); };
    const onKey = (e) => { if (e.key === "Escape") close(null); };
    const box = h("div", { class: "dlgbox", role: "dialog", "aria-modal": "true", "aria-label": title },
      h("h2", { text: title }), body,
      h("div", { class: "acts" }, actions.map((a) => h("button", { class: `btn ${a.primary ? "primary" : a.danger ? "danger" : "soft"}`, onclick: async () => { const r = a.onClick ? await a.onClick() : a.value; if (r !== false) close(a.onClick ? r : a.value); } }, a.label))));
    const wrap = h("div", { class: "dlg", onclick: (e) => { if (e.target === wrap) close(null); } }, box);
    document.body.append(wrap);
    document.addEventListener("keydown", onKey);
    (box.querySelector("textarea,input,button.primary") || box.querySelector("button"))?.focus();
  });
}
const confirmBox = (title, text, yes = "Yes", danger = false) => dialog({ title, body: h("p", { text }), actions: [{ label: "Cancel", value: false }, { label: yes, value: true, primary: !danger, danger }] });

async function copy(text, what = "Copied") {
  try { await navigator.clipboard.writeText(text); toast(`${what} ✓`); return; } catch {}
  try {
    const ta = h("textarea", { style: "position:fixed;opacity:0" }); ta.value = text; document.body.append(ta); ta.select();
    const ok = document.execCommand("copy"); ta.remove(); if (ok) { toast(`${what} ✓`); return; }
  } catch {}
  const ta = h("textarea", { rows: 10, readonly: true }); ta.value = text;
  dialog({ title: "Copy this", body: h("div", {}, h("p", { class: "hint", text: "Your browser blocked copying. Select all and copy by hand." }), ta) });
  setTimeout(() => ta.select(), 50);
}

// ---------- data + boot ----------
async function getJson(path) { const r = await fetch(path, { cache: "no-cache" }); if (!r.ok) throw new Error(`${path}: ${r.status}`); return r.json(); }

async function loadData() {
  const files = ["chips-sound.json", "chips-instruments.json", "chips-voice-mix.json", "beats.json", "recipes.json", "learn.json", "flow-guide.json"];
  const res = await Promise.allSettled(files.map((f) => getJson("data/" + f)));
  const val = (i, d) => (res[i].status === "fulfilled" ? res[i].value : d);
  S.cat = E.makeCatalog([val(0, null), val(1, null), val(2, null)]);
  S.beats = val(3, { patterns: [] }); S.recipes = val(4, { recipes: [], tunings: [], edits: [] });
  S.learn = val(5, { sections: [] }); S.flow = val(6, { sections: [] });
  const failed = res.map((r, i) => (r.status === "rejected" ? files[i] : null)).filter(Boolean);
  if (failed.length) console.warn("FLOWSMITH: could not load", failed);
}

async function boot() {
  S.apiKey = ls.get("flowsmith.apiKey", "");
  const draft = ls.get("flowsmith.draft", null);
  if (draft && draft.st) { S.st = { ...E.blankState(), ...draft.st }; if (draft.out) S.out = { ...S.out, ...draft.out }; if (draft.edit) S.edit = draft.edit; }
  await loadData();
  route();
  window.addEventListener("hashchange", route);
  document.addEventListener("focusout", () => setTimeout(() => { if (S.pendingRender && !isTyping()) { S.pendingRender = false; render(); } }, 0));
  S.storeReady = openStore().then(async (store) => {
    S.store = store;
    S.settings = { ...DEFAULT_SETTINGS, ...(await store.getDoc("settings", {})) };
    S.lessons = await store.getDoc("lessons", { items: [] });
    S.traces = await store.getDoc("traces", { days: {}, recent: [] });
    S.snippets = await store.getDoc("snippets", { items: [] });
    store.watchSongs((songs) => { S.songs = songs; S.songsLoaded = true; S.songsNote = ""; softRender(); }, (e) => { S.songsNote = e.code === "slow" ? "Your saved songs are taking a while to load." : "Couldn't load your songs right now."; softRender(); });
    updateChrome();
    return store;
  });
  if (IN_ARTIFACT) {
    claude.use("sample").then((s) => { S.ai.sample = s; updateChrome(); });
    claude.use("dictation").then((d) => { S.ai.dict = d; wireDictation(); if (current() === "studio") render(); });
    claude.use("desktop").then(async (d) => { S.ai.desk = d; if (d?.app?.dock) d.app.dock.setIcon(drawIcon()).catch(() => {}); if (current() === "setup") render(); });
  } else if ("serviceWorker" in navigator && location.protocol !== "file:") {
    navigator.serviceWorker.register("sw.js").catch(() => {});
  }
  window.addEventListener("beforeinstallprompt", (e) => { e.preventDefault(); S.installEvt = e; });
  updateChrome();
}

function drawIcon() {
  const c = document.createElement("canvas"); c.width = c.height = 256; const g = c.getContext("2d");
  g.fillStyle = "#1c1c20"; g.beginPath(); g.roundRect(0, 0, 256, 256, 56); g.fill();
  ["#d2382b", "#e9782a", "#efbf35", "#e6dcc6"].forEach((col, i) => { g.fillStyle = col; g.beginPath(); g.roundRect(28 + i * 52, 70, 44, 116, 10); g.fill(); });
  g.fillStyle = "#ff3b2f"; g.beginPath(); g.roundRect(38, 52, 24, 8, 4); g.fill();
  return c.toDataURL("image/png");
}

// ---------- AI wiring ----------
function backendFor() {
  const m = S.settings.aiMode || "auto";
  const sampleOk = S.ai.sample && !S.ai.sampleBlocked;
  if (m === "offline") return "offline";
  if (m === "claude") return sampleOk ? "claude" : "bridge";
  if (m === "api") return !IN_ARTIFACT && S.apiKey ? "api" : "bridge";
  if (m === "bridge") return "bridge";
  if (sampleOk) return "claude";
  if (!IN_ARTIFACT && S.apiKey) return "api";
  return "bridge";
}
const BACKEND_LABEL = { claude: "Claude · your account", api: "Claude · API key", bridge: "Claude · copy & paste", offline: "Offline engine" };

function updateChrome() {
  const b = backendFor();
  $("#aiBadge").textContent = BACKEND_LABEL[b];
  $("#storeBadge").textContent = S.store ? (S.store.kind === "cloud" ? "Synced to Claude" : "This device") : "…";
  $("#storeBadge").title = S.store ? S.store.label : "Opening storage";
  const L = statusLight(S.traces, S.settings);
  $("#led").className = "led " + L.color; $("#statusTxt").textContent = L.text; $("#status").title = L.text;
}

function openBridge(fullText) {
  return new Promise((resolve, reject) => {
    const reply = h("textarea", { rows: 8, placeholder: "Paste Claude's whole answer here" });
    const req = h("textarea", { rows: 6, readonly: true }); req.value = fullText;
    dialog({
      title: "Ask Claude in the Claude app",
      body: h("div", {},
        h("p", { text: "1. Copy this request and paste it into a new chat in the Claude app (it uses your Claude plan, no API key needed)." }),
        req, h("div", { class: "row", style: "margin:8px 0 14px" }, h("button", { class: "btn primary sm", onclick: () => copy(fullText, "Request copied") }, "Copy request"), h("a", { class: "btn soft sm", href: "https://claude.ai/new", target: "_blank", rel: "noopener" }, "Open Claude")),
        h("p", { text: "2. Paste Claude's answer below." }), reply),
      actions: [{ label: "Cancel", value: null }, { label: "Use this answer", primary: true, onClick: () => (reply.value.trim() ? reply.value : false) }],
    }).then((v) => (v ? resolve(v) : reject(Object.assign(new Error("Stopped."), { code: "cancelled" }))));
  });
}

async function callAgent(agent, payload, { label } = {}) {
  const backend = backendFor();
  if (backend === "offline") throw Object.assign(new Error("Claude is switched off (Setup → Claude connection). Use Build instead."), { code: "offline" });
  const ctl = new AbortController();
  S.busy = { agent, label: label || `${AGENTS[agent].label} is working…`, ctl, chars: 0 };
  refreshBusy();
  try {
    return await runAgent(agent, { ...payload, catalog: S.cat, lessons: S.lessons.items }, {
      backend, settings: { ...S.settings, apiKey: S.apiKey }, sample: S.ai.sample, bridge: openBridge, signal: ctl.signal,
      onText: ({ text }) => { if (S.busy) { S.busy.chars = text.length; refreshBusy(); } },
      traces: S.traces, saveTraces: (t) => { S.store?.putDoc("traces", t).catch(() => {}); updateChrome(); },
    });
  } catch (e) {
    if (["not_granted", "sampling_disabled", "capability_disabled", "capability_removed", "not_declared"].includes(e.code)) { S.ai.sampleBlocked = true; updateChrome(); }
    throw e;
  } finally { S.busy = null; refreshBusy(); }
}

function refreshBusy() {
  for (const el of document.querySelectorAll("[data-busy]")) {
    el.hidden = !S.busy;
    if (S.busy) el.querySelector("span").textContent = S.busy.chars ? `${S.busy.label} (${S.busy.chars} characters so far)` : S.busy.label;
  }
  for (const el of document.querySelectorAll("[data-needs-idle]")) el.disabled = !!S.busy;
}
const busyBar = () => h("div", { class: "notice", "data-busy": "", hidden: !S.busy }, h("span", { text: S.busy?.label || "" }), " ", h("button", { class: "btn sm soft", onclick: () => S.busy?.ctl.abort() }, "Stop"));

function reportError(e) {
  if (e && e.code === "cancelled") { toast("Stopped"); return; }
  toast(e?.message || "Something went wrong");
}

// ---------- routing ----------
const current = () => { const v = (location.hash || "#studio").slice(1); return VIEWS.includes(v) ? v : "studio"; };
function route() {
  for (const a of document.querySelectorAll(".tabs a, .botnav a")) {
    if (a.getAttribute("href") === "#" + current()) a.setAttribute("aria-current", "page"); else a.removeAttribute("aria-current");
  }
  render();
  window.scrollTo(0, 0);
}
const isTyping = () => { const a = document.activeElement; return a && view().contains(a) && /^(INPUT|TEXTAREA|SELECT)$/.test(a.tagName) && a.type !== "range"; };
function softRender() { if (isTyping()) { S.pendingRender = true; return; } render(); }
function render() {
  const v = current();
  const root = view();
  put(root, ({ studio: Studio, songs: Songs, next: Next, library: Library, learn: Learn, setup: Setup })[v]());
  updateChrome();
}

// ======================================================================
// STUDIO
// ======================================================================
function saveDraft() { ls.set("flowsmith.draft", { st: S.st, out: S.out, edit: S.edit }); }

function rebuildIfEngine() {
  const hasInput = S.st.chips.length || (S.st.brief || S.st.query || "").trim();
  if (S.out.source === "engine" || S.out.source === "none") {
    if (hasInput) { const r = E.buildPrompt(S.st, S.cat); S.out = { ...S.out, prompt: r.prompt, lyrics: r.lyrics, source: "engine", stale: false, variations: [], why: "", critic: null }; }
  } else S.out.stale = true;
}
function studioChanged() { rebuildIfEngine(); saveDraft(); refreshStudio(); }

function toggleChip(id) {
  const i = S.st.chips.indexOf(id);
  if (i >= 0) S.st.chips.splice(i, 1); else S.st.chips.push(id);
  if (id === "vo-instrumental" && i < 0) S.st.vocals = "instrumental";
  else if (id.startsWith("vo-") && i < 0 && S.st.vocals === "instrumental") { S.st.vocals = "auto"; S.st.chips = S.st.chips.filter((x) => x !== "vo-instrumental"); }
  S.infoId = i >= 0 ? null : id;
  studioChanged();
}

function applyQuery() {
  const q = $("#ask")?.value ?? S.st.query;
  const p = E.parseQuery(q, S.cat);
  S.st.query = q; S.st.brief = p.rest;
  if (p.bpm) S.st.bpm = p.bpm;
  if (p.key) S.st.key = p.key;
  if (p.length) S.st.length = p.length;
  if (p.language) S.st.language = p.language;
  if (p.vocals) S.st.vocals = p.vocals;
  for (const id of p.chipIds) if (!S.st.chips.includes(id)) S.st.chips.push(id);
}

function buildOffline() {
  applyQuery();
  if (S.out.source !== "engine") S.out.source = "none";
  rebuildIfEngine();
  if (!S.out.prompt) { toast("Type a few words or tap some buttons first"); return; }
  if (!S.out.title) S.out.title = suggestTitle();
  saveDraft(); render();
}

function suggestTitle() {
  const g = S.st.chips.map((id) => S.cat.byId.get(id)).find((c) => c && c.cat === "genre");
  const m = S.st.chips.map((id) => S.cat.byId.get(id)).find((c) => c && c.cat === "mood");
  const brief = (S.st.brief || "").split(/[,.]/)[0].trim();
  return (brief ? brief.replace(/\b\w/g, (c) => c.toUpperCase()) : [m?.label, g?.label].filter(Boolean).join(" ")).slice(0, 48) || "Untitled song";
}

async function writeWithClaude() {
  applyQuery();
  const draft = E.buildPrompt(S.st, S.cat).prompt;
  try {
    let r;
    if (S.edit && S.out.prompt && S.out.source !== "engine") {
      const base = { prompt: S.out.prompt, lyrics: S.out.lyrics, chips: S.edit.baseChips || S.st.chips, state: S.edit.baseState || S.st };
      r = await callAgent("tweaker", { version: base, request: describeStudioChange() }, { label: "Claude is updating your prompt…" });
    } else {
      r = await callAgent("composer", { state: S.st, draft }, { label: "Claude is writing your prompt…" });
    }
    applySongResult(r);
    if (S.settings.claudeCritic) await runClaudeCritic(true);
  } catch (e) { reportError(e); }
  render();
}

function describeStudioChange() {
  const base = S.edit?.baseState || {};
  const d = E.chipDiff(S.edit?.baseChips || [], S.st.chips);
  const lab = (ids) => ids.map((id) => S.cat.byId.get(id)?.label || id).join(", ");
  const bits = [];
  if ((S.st.query || "").trim()) bits.push(`In their words: ${S.st.query.trim()}`);
  if (d.added.length) bits.push(`Add: ${lab(d.added)}`);
  if (d.removed.length) bits.push(`Remove: ${lab(d.removed)}`);
  if (base.bpm !== S.st.bpm && S.st.bpm) bits.push(`Tempo ${base.bpm || "auto"} → ${S.st.bpm} BPM`);
  if (base.key !== S.st.key && S.st.key) bits.push(`Key ${base.key || "auto"} → ${S.st.key}`);
  if (base.length !== S.st.length) bits.push(`Length → ${E.LENGTHS.find((l) => l.id === S.st.length)?.label}`);
  if (base.vocals !== S.st.vocals) bits.push(`Vocals → ${S.st.vocals}`);
  if (S.st.notes && S.st.notes !== base.notes) bits.push(`Notes: ${S.st.notes}`);
  return bits.join("\n") || "Polish it: same song, clearer and more specific.";
}

function applySongResult(r) {
  if (r.bpm) S.st.bpm = r.bpm;
  if (r.key) S.st.key = r.key;
  if (r.length) S.st.length = r.length;
  if (r.vocals) S.st.vocals = r.vocals;
  S.st.chips = [...new Set([...S.st.chips, ...r.chips])];
  S.out = { title: r.title || S.out.title || suggestTitle(), prompt: r.prompt, lyrics: r.lyrics, source: "claude", why: r.why, variations: r.variations, stale: false, critic: null, changeNote: r.changeNote || "" };
  saveDraft();
}

async function runClaudeCritic(quiet) {
  const c = E.critique(S.out.prompt, S.out.lyrics, S.st, S.cat);
  try {
    S.out.critic = await callAgent("critic", { prompt: S.out.prompt, lyrics: S.out.lyrics, rubric: c.checks }, { label: "Claude is reviewing the prompt…" });
    saveDraft();
  } catch (e) { if (!quiet) reportError(e); }
  render();
}

async function saveOutput(asNew = false) {
  if (!S.out.prompt.trim()) { toast("Nothing to save yet"); return; }
  const store = await S.storeReady;
  const now = new Date().toISOString();
  const crit = E.critique(S.out.prompt, S.out.lyrics, S.st, S.cat);
  const genres = S.st.chips.map((id) => S.cat.byId.get(id)).filter((c) => c && (c.cat === "genre" || c.cat === "mood")).map((c) => c.label).slice(0, 4);
  const settings = { bpm: S.st.bpm, key: S.st.key, length: S.st.length, vocals: E.vocalIntent(S.st), language: S.st.language };
  let song, n, prev = null;
  const editing = S.edit && !asNew && S.songs.some((s) => s.id === S.edit.songId);
  if (editing) {
    song = S.songs.find((s) => s.id === S.edit.songId);
    const vs = await store.listVersions(song.id);
    prev = vs[vs.length - 1] || null;
    n = (prev?.n || 0) + 1;
  } else {
    song = { id: newId("s"), title: S.out.title || suggestTitle(), createdAt: now, next: [], rating: 0, parentId: S.edit?.parentId || null };
    n = 1;
  }
  const changeNote = n === 1 ? "First version" : (S.out.changeNote || autoChangeNote(prev));
  const v = await E.sealVersion({ n, createdAt: now, prompt: S.out.prompt.trim(), lyrics: (S.out.lyrics || "").trim(), chips: [...S.st.chips], settings, state: { ...S.st }, source: S.out.source, changeNote, score: crit.score, grade: crit.grade, title: S.out.title || song.title }, prev?.hash);
  await store.putVersion(song.id, v);
  const meta = { ...song, title: S.out.title || song.title, updatedAt: now, latestN: n, latestHash: v.hash, score: crit.score, grade: crit.grade, tags: genres, preview: v.prompt.slice(0, 160) };
  await store.putSong(meta);
  S.edit = { songId: song.id, baseN: n, baseState: { ...S.st }, baseChips: [...S.st.chips], title: meta.title };
  S.out.changeNote = "";
  saveDraft();
  toast(n === 1 ? `Saved “${meta.title}” as a new song folder (v1)` : `Saved v${n} in “${meta.title}”`);
  S.openId = song.id; S.selN = n;
  render();
}

function autoChangeNote(prev) {
  if (!prev) return "Updated";
  const d = E.chipDiff(prev.chips, S.st.chips);
  const lab = (ids) => ids.map((id) => S.cat.byId.get(id)?.label || id).join(", ");
  const bits = [];
  if (d.added.length) bits.push(`added ${lab(d.added)}`);
  if (d.removed.length) bits.push(`removed ${lab(d.removed)}`);
  const ps = prev.settings || {};
  if (ps.bpm !== S.st.bpm) bits.push(`${S.st.bpm || "auto"} BPM`);
  if (ps.key !== S.st.key) bits.push(`key ${S.st.key || "auto"}`);
  if (!bits.length) bits.push("reworded the prompt");
  return bits.join("; ").replace(/^./, (c) => c.toUpperCase());
}

function newSong() {
  S.st = E.blankState(); S.out = { title: "", prompt: "", lyrics: "", source: "none", why: "", variations: [], stale: false, critic: null, changeNote: "" };
  S.edit = null; S.infoId = null; saveDraft(); location.hash = "#studio"; render();
}

function loadVersionIntoStudio(song, v) {
  S.st = { ...E.blankState(), ...(v.state || {}), chips: [...(v.chips || [])] };
  S.out = { title: song.title, prompt: v.prompt, lyrics: v.lyrics || "", source: v.source === "engine" ? "engine" : "manual", why: "", variations: [], stale: false, critic: null, changeNote: "" };
  S.edit = { songId: song.id, baseN: v.n, baseState: { ...S.st }, baseChips: [...S.st.chips], title: song.title };
  saveDraft(); location.hash = "#studio"; render();
}

let foundTimer;
function Studio() {
  const ask = h("input", { id: "ask", type: "search", value: S.st.query, placeholder: "A few words: dark trap, 140 bpm, rainy night, 808s, female vocals", "aria-label": "Describe your song", autocomplete: "off", enterkeyhint: "go",
    oninput: (e) => { clearTimeout(foundTimer); foundTimer = setTimeout(() => showFound(e.target.value), 140); },
    onkeydown: (e) => { if (e.key === "Enter") { e.preventDefault(); buildOffline(); } } });
  const mic = (S.ai.dict || speechApi()) ? h("button", { class: "mic", id: "mic", type: "button", "aria-label": "Speak your words", title: "Speak your words", onclick: toggleDictation }, "🎙") : null;
  const editing = S.edit && S.songs.find((s) => s.id === S.edit.songId);
  const wrap = h("div", { class: "studio" },
    h("section", { "aria-label": "Describe and pick sounds" },
      editing ? h("div", { class: "notice", style: "margin-bottom:12px" }, `Editing “${editing.title}”. Saving makes v${(editing.latestN || 0) + 1} in the same folder. `, h("button", { class: "btn sm soft", onclick: newSong }, "Start a new song")) : null,
      h("h1", { style: "margin-bottom:12px" }, "What should it sound like?"),
      h("div", { class: "ask" },
        h("div", { class: "askbox" }, ask, mic),
        h("div", { class: "askbtns" },
          h("button", { class: "btn primary", "data-needs-idle": "", onclick: writeWithClaude, disabled: !!S.busy, title: "Claude writes the Flow Music prompt" }, editing && S.out.source !== "engine" && S.out.prompt ? "Update with Claude" : "Write it"),
          h("button", { class: "btn soft", onclick: buildOffline, title: "Build instantly without Claude" }, "Build"))),
      h("p", { class: "found", id: "found" }),
      busyBar(),
      Knobs(),
      h("div", { class: "tray", id: "tray" }),
      Pads()),
    h("aside", { class: "readout", id: "readout", "aria-label": "Your Flow Music prompt" }));
  setTimeout(() => { showFound(S.st.query); refreshStudio(); }, 0);
  return wrap;
}

function showFound(q) {
  const el = $("#found"); if (!el) return;
  const p = E.parseQuery(q, S.cat);
  const bits = [];
  if (p.bpm) bits.push(`${p.bpm} BPM`); if (p.key) bits.push(p.key); if (p.length) bits.push(E.LENGTHS.find((l) => l.id === p.length).label);
  if (p.language) bits.push(p.language); if (p.vocals) bits.push(p.vocals);
  bits.push(...p.chipIds.map((id) => S.cat.byId.get(id)?.label).filter(Boolean));
  put(el, bits.length ? h("span", {}, "Will set: ", h("b", { text: bits.join(" · ") })) : h("span", { text: q ? "Press Enter to build, or Write it to let Claude write it." : "Tip: type BPM, a key (F minor), drum machines (808, 505), moods and genres." }));
}

function Knobs() {
  const st = S.st;
  const bpmNum = h("input", { type: "number", min: 40, max: 220, value: st.bpm ?? "", placeholder: "auto", "aria-label": "BPM", oninput: (e) => { const n = parseInt(e.target.value, 10); st.bpm = n >= 40 && n <= 220 ? n : null; $("#bpmRange").value = st.bpm || 100; studioChanged(); } });
  const range = h("input", { id: "bpmRange", type: "range", min: 40, max: 220, value: st.bpm || 100, "aria-label": "BPM slider", oninput: (e) => { st.bpm = +e.target.value; bpmNum.value = st.bpm; studioChanged(); } });
  const sel = (label, value, opts, on) => h("label", { class: "field" }, h("span", { text: label }), h("select", { onchange: (e) => on(e.target.value) }, opts.map(([v, t]) => h("option", { value: v, selected: v === value }, t))));
  const seg = (label, value, opts, on) => h("div", { class: "field" }, h("span", { text: label }), h("div", { class: "seg", role: "group", "aria-label": label }, opts.map(([v, t]) => h("button", { type: "button", "aria-pressed": String(v === value), onclick: () => { on(v); render(); } }, t))));
  const lyricBox = st.lyricsMode === "mine"
    ? h("label", { class: "field", style: "grid-column:1/-1" }, h("span", { text: "Your lyrics (use Verse/Chorus lines; tags are added for you)" }), h("textarea", { rows: 6, value: st.lyrics, oninput: (e) => { st.lyrics = e.target.value; studioChanged(); } }))
    : h("label", { class: "field", style: "grid-column:1/-1" }, h("span", { text: st.lyricsMode === "write" ? "What should Claude's lyrics be about?" : "Lyric theme (Flow writes the words)" }), h("input", { type: "text", value: st.lyricTheme, placeholder: "e.g. driving home after the last shift", oninput: (e) => { st.lyricTheme = e.target.value; studioChanged(); } }));
  return h("div", { class: "card", style: "margin-top:14px" },
    h("div", { class: "knobs" },
      h("div", { class: "bpm" }, h("b", { text: "BPM" }), range, bpmNum, h("button", { class: "btn sm soft", onclick: () => { st.bpm = null; render(); studioChanged(); } }, "Auto")),
      sel("Key", st.key, [["", "Auto"], ...E.ALL_KEYS.map((k) => [k, k])], (v) => { st.key = v; studioChanged(); }),
      sel("Length", st.length, E.LENGTHS.map((l) => [l.id, l.label]), (v) => { st.length = v; studioChanged(); }),
      seg("Vocals", st.vocals, [["auto", "Auto"], ["vocals", "Vocals"], ["instrumental", "Instr."]], (v) => { st.vocals = v; if (v === "instrumental") st.chips = st.chips.filter((x) => !x.startsWith("vo-") || x === "vo-instrumental"); else st.chips = st.chips.filter((x) => x !== "vo-instrumental"); studioChanged(); }),
      sel("Language", st.language, E.LANGUAGES.map((l) => [l, l]), (v) => { st.language = v; studioChanged(); })),
    h("details", { class: "more", open: st.lyricsMode !== "theme" || !!st.lyricTheme || !!st.notes },
      h("summary", {}, "Lyrics, layout and notes"),
      h("div", { class: "knobs" },
        seg("Lyrics", st.lyricsMode, [["theme", "Theme"], ["write", "Claude writes"], ["mine", "My lyrics"]], (v) => { st.lyricsMode = v; studioChanged(); }),
        seg("Prompt layout", st.format, [["prose", "Prose"], ["labeled", "Labeled"]], (v) => { st.format = v; studioChanged(); }),
        seg("Timestamps", st.timestamps ? "on" : "off", [["off", "Off"], ["on", "On"]], (v) => { st.timestamps = v === "on"; studioChanged(); }),
        lyricBox,
        h("label", { class: "field", style: "grid-column:1/-1" }, h("span", { text: "Extra notes (added at the end)" }), h("input", { type: "text", value: st.notes, placeholder: "e.g. ends on a held piano chord", oninput: (e) => { st.notes = e.target.value; studioChanged(); } })))));
}

function Pads() {
  const counts = {};
  for (const id of S.st.chips) { const c = S.cat.byId.get(id); if (c) counts[c.cat] = (counts[c.cat] || 0) + 1; }
  const cats = E.CATEGORIES.filter((c) => (S.cat.byCat.get(c.id) || []).length);
  if (!cats.length) return h("div", { class: "empty" }, "The sound buttons haven't loaded. Check your connection and reload.");
  if (!cats.some((c) => c.id === S.catId)) S.catId = cats[0].id;
  const filter = h("input", { type: "search", placeholder: "Find a button (e.g. 505, Rhodes, dreamy)", value: S.padFilter, "aria-label": "Find a sound button", oninput: (e) => { S.padFilter = e.target.value; put($("#padgrid"), padGrid()); } });
  return h("section", { "aria-label": "Sound buttons", style: "margin-top:6px" },
    h("div", { class: "cats", role: "group", "aria-label": "Sound categories" }, cats.map((c) => h("button", { class: "cat", "aria-pressed": String(c.id === S.catId), onclick: () => { S.catId = c.id; S.padFilter = ""; render(); } },
      h("span", { class: "dot", style: `background:var(--${c.tone})` }), c.label, counts[c.id] ? h("span", { class: "n", text: `· ${counts[c.id]}` }) : null))),
    filter,
    h("div", { id: "padgrid" }, padGrid()),
    h("div", { class: "info", id: "info" }));
}

function padGrid() {
  const q = S.padFilter.trim().toLowerCase();
  const list = q ? S.cat.chips.filter((c) => (c.label + " " + c.group + " " + c.desc).toLowerCase().includes(q)) : (S.cat.byCat.get(S.catId) || []);
  if (!list.length) return [h("p", { class: "hint", text: "No buttons match." })];
  const groups = new Map();
  for (const c of list) { const g = q ? E.CAT_BY_ID[c.cat]?.label || c.cat : c.group; if (!groups.has(g)) groups.set(g, []); groups.get(g).push(c); }
  const out = [];
  for (const [g, cs] of groups) {
    out.push(h("div", { class: "grp", text: g }));
    out.push(h("div", { class: "pads" }, cs.map((c) => padBtn(c))));
  }
  return out;
}
function padBtn(c) {
  return h("button", { class: `pad ${toneOf(c)}`, "data-chip": c.id, "aria-pressed": String(S.st.chips.includes(c.id)), title: c.desc, onclick: () => toggleChip(c.id) }, c.label);
}

function refreshStudio() {
  for (const b of document.querySelectorAll(".pad[data-chip]")) b.setAttribute("aria-pressed", String(S.st.chips.includes(b.dataset.chip)));
  const tray = $("#tray");
  if (tray) tray.replaceChildren(...(S.st.chips.length ? S.st.chips.map((id) => S.cat.byId.get(id)).filter(Boolean).map((c) => h("button", { class: `tag t-${toneOf(c)}`, title: `Remove ${c.label}`, onclick: () => toggleChip(c.id) }, c.label)) : [h("span", { class: "hint", text: "Your picks show here. Tap a pad below to add it; tap again to remove it." })]));
  const info = $("#info");
  if (info) {
    const c = S.infoId && S.cat.byId.get(S.infoId);
    put(info, (c ? [h("div", { class: "card" }, h("b", { text: c.label }), " ", h("span", { class: "muted small", text: `${c.group}${c.bpm ? ` · ${c.bpm[0]}–${c.bpm[1]} BPM` : ""}` }), h("p", { text: c.desc }), h("p", { class: "small muted" }, "Adds: “", c.prompt, "”"),
      (c.pairs || []).filter((id) => S.cat.byId.has(id)).length ? h("div", {}, h("span", { class: "small muted", text: "Goes well with:" }), h("div", { class: "pairs" }, c.pairs.filter((id) => S.cat.byId.has(id)).map((id) => { const p = S.cat.byId.get(id); return h("button", { class: `chipbtn`, "aria-pressed": String(S.st.chips.includes(id)), onclick: () => toggleChip(id) }, p.label); }))) : null)] : []));
  }
  const ro = $("#readout");
  if (ro) put(ro, Readout());
}

function Readout() {
  const o = S.out;
  if (!o.prompt) return [h("div", { class: "screen" }, h("h2", { text: "Your Flow Music prompt" }), h("p", { class: "hint", text: "Type a few words above and press Write it (Claude) or Build (instant). Tap pads to shape the sound: drum machines, synths, moods, keys." }),
    h("p", { class: "hint" }, "Then copy it into a New session at ", h("a", { href: E.FLOW_URL, target: "_blank", rel: "noopener" }, "Flow Music"), "."))];
  const crit = E.critique(o.prompt, o.lyrics, S.st, S.cat);
  const title = h("input", { class: "title", type: "text", value: o.title || "", placeholder: "Song title", "aria-label": "Song title", oninput: (e) => { o.title = e.target.value; saveDraft(); } });
  const ta = h("textarea", { rows: 9, "aria-label": "Flow Music prompt", value: o.prompt, oninput: (e) => { o.prompt = e.target.value; o.source = "manual"; saveDraft(); $("#wc").textContent = `${words(o.prompt)} words`; } });
  const lyr = o.lyrics || E.vocalIntent(S.st) !== "instrumental" && S.st.lyricsMode !== "theme" ? h("textarea", { rows: 7, "aria-label": "Lyrics", placeholder: "Lyrics:\n[Verse 1]\n…", value: o.lyrics, oninput: (e) => { o.lyrics = e.target.value; o.source = o.source === "engine" ? "manual" : o.source; saveDraft(); } }) : null;
  const editingSong = S.edit && S.songs.find((s) => s.id === S.edit.songId);
  const all = o.lyrics ? `${o.prompt}\n\n${o.lyrics}` : o.prompt;
  return [
    o.stale ? h("div", { class: "notice" }, "Your buttons changed since this was written. ", h("button", { class: "btn sm primary", "data-needs-idle": "", onclick: writeWithClaude }, "Update with Claude"), " ", h("button", { class: "btn sm soft", onclick: () => { S.out.source = "none"; rebuildIfEngine(); saveDraft(); refreshStudio(); } }, "Rebuild instantly")) : null,
    h("div", { class: "screen" }, title, ta,
      h("div", { class: "screenbar" }, h("span", { id: "wc", text: `${words(o.prompt)} words` }), h("span", { text: o.source === "claude" ? "Written by Claude" : o.source === "engine" ? "Built from your buttons" : "Edited by you" }))),
    lyr ? h("div", { class: "screen" }, h("h3", { text: "Lyrics" }), lyr) : null,
    h("div", { class: "row" },
      h("button", { class: "btn primary", onclick: () => copy(all, o.lyrics ? "Prompt and lyrics copied" : "Prompt copied") }, o.lyrics ? "Copy prompt + lyrics" : "Copy prompt"),
      h("a", { class: "btn soft", href: E.FLOW_URL, target: "_blank", rel: "noopener" }, "Open Flow Music"),
      h("button", { class: "btn soft", onclick: () => saveOutput(false) }, editingSong ? `Save as v${(editingSong.latestN || 0) + 1}` : "Save as new song"),
      editingSong ? h("button", { class: "btn ghost", onclick: () => saveOutput(true) }, "Save as a new folder") : null),
    ScoreCard(crit),
    o.why ? h("div", { class: "card" }, h("h3", { text: "Why Claude wrote it this way" }), h("p", { text: o.why })) : null,
    o.variations?.length ? h("div", { class: "card" }, h("h3", { text: "Try these variations" }), h("div", { class: "vars" }, o.variations.map((v) => h("div", { class: "var" }, h("b", { text: v.label }), h("p", { text: v.prompt }), h("div", { class: "row" }, h("button", { class: "btn sm soft", onclick: () => copy(v.prompt) }, "Copy"), h("button", { class: "btn sm soft", onclick: () => { o.prompt = v.prompt; o.source = "claude"; saveDraft(); refreshStudio(); } }, "Use this")))))) : null,
    o.critic ? h("div", { class: "card" }, h("h3", { text: `Claude's review: ${o.critic.score}/100` }), h("ul", {}, o.critic.issues.map((t) => h("li", { text: t }))), o.critic.improved ? h("div", {}, h("p", { class: "prompttext", text: o.critic.improved }), h("button", { class: "btn sm soft", onclick: () => { o.prompt = o.critic.improved; o.source = "claude"; o.critic = null; saveDraft(); refreshStudio(); } }, "Use the improved prompt")) : null) : null,
  ];
}

function ScoreCard(crit) {
  const missing = crit.checks.filter((c) => !c.ok);
  return h("div", { class: "card" },
    h("div", { class: "score" }, h("div", { class: "grade", "aria-label": `Grade ${crit.grade}`, text: crit.grade }),
      h("div", {}, h("b", { text: `Prompt check: ${crit.score}/100` }), h("div", { class: "meter", "aria-hidden": "true" }, h("i", { style: `width:${crit.score}%` })), h("span", { class: "small muted", text: missing.length ? `${missing.length} thing${missing.length > 1 ? "s" : ""} to improve` : "Meets Google's prompting guidance" }))),
    h("details", { open: missing.length > 0 && missing.length <= 3 }, h("summary", { class: "small" }, "Checklist"),
      h("ul", { class: "checks" }, crit.checks.filter((c) => c.weight || !c.ok).map((c) => h("li", {}, h("span", { class: c.ok ? "y" : "n", text: c.ok ? "✓" : "!" }), h("span", {}, c.label, c.detail ? h("span", { class: "muted", text: ` (${c.detail})` }) : null, c.ok ? null : h("div", { class: "muted", text: c.fix })))))),
    h("div", { class: "row", style: "margin-top:8px" }, h("button", { class: "btn sm soft", "data-needs-idle": "", onclick: () => runClaudeCritic(false) }, "Ask Claude to review")));
}

// ---------- dictation ----------
function speechApi() { return !IN_ARTIFACT && (globalThis.SpeechRecognition || globalThis.webkitSpeechRecognition) || null; }
let dictOn = false, rec = null, dictBase = "";
function wireDictation() {
  const d = S.ai.dict; if (!d) return;
  d.onPartial(({ text }) => { const a = $("#ask"); if (a) a.value = (dictBase + " " + text).trim(); });
  d.onFinal(({ text }) => { dictBase = (dictBase + " " + text).trim(); const a = $("#ask"); if (a) { a.value = dictBase; showFound(dictBase); } });
  d.onState(({ state }) => { dictOn = state === "listening"; $("#mic")?.classList.toggle("on", dictOn); });
}
function toggleDictation() {
  const a = $("#ask");
  if (S.ai.dict) {
    if (dictOn) { S.ai.dict.stop().catch(() => {}); return; }
    dictBase = a?.value || "";
    S.ai.dict.start().catch((e) => { if (e?.code === "not_granted") toast("Microphone not allowed. You can still type."); });
    return;
  }
  const SR = speechApi(); if (!SR) return;
  if (rec) { rec.stop(); return; }
  rec = new SR(); rec.interimResults = true; rec.lang = "en-US"; dictBase = a?.value || "";
  rec.onresult = (e) => { let t = ""; for (const r of e.results) t += r[0].transcript; if (a) { a.value = (dictBase + " " + t).trim(); showFound(a.value); } };
  rec.onend = () => { rec = null; $("#mic")?.classList.remove("on"); };
  rec.onerror = () => toast("Couldn't hear that. You can type instead.");
  $("#mic")?.classList.add("on"); rec.start();
}

// ======================================================================
// SONGS (folders + versions)
// ======================================================================
function sortedSongs() { return [...S.songs].sort((a, b) => String(b.updatedAt || "").localeCompare(String(a.updatedAt || ""))); }

function openSong(id) {
  if (S.openId === id && S.vUnsub) return;
  S.vUnsub?.(); S.vUnsub = null; S.versions = []; S.selN = null; S.cmpN = null; S.tweakOps = []; S.tweakText = ""; S.rate = null;
  S.openId = id; S.nextSongId = id;
  if (S.store && id) S.vUnsub = S.store.watchVersions(id, (vs) => { S.versions = vs; if (!S.selN || !vs.some((v) => v.n === S.selN)) S.selN = vs.length ? vs[vs.length - 1].n : null; softRender(); });
}

function Songs() {
  if (S.openId) openSong(S.openId);
  const song = S.songs.find((s) => s.id === S.openId);
  return h("div", { class: "songs" + (song ? " open" : "") },
    h("section", { class: "list", "aria-label": "Song folders" },
      h("div", { class: "row", style: "justify-content:space-between" }, h("h1", { text: "Songs" }), h("button", { class: "btn sm primary", onclick: newSong }, "New song")),
      h("input", { type: "search", placeholder: "Search songs", value: S.songQ || "", "aria-label": "Search songs", oninput: (e) => { S.songQ = e.target.value; const l = $("#folders"); if (l) put(l, folderList()); } }),
      S.songsNote ? h("p", { class: "notice", text: S.songsNote }) : null,
      h("div", { id: "folders", class: "list" }, folderList()),
      h("p", { class: "small muted", text: S.store ? S.store.label : "Opening your storage…" })),
    song ? SongDetail(song) : h("section", { class: "detail" }, S.openId && S.songsLoaded ? h("p", { class: "hint", text: "Opening the folder…" }) : S.songs.length ? h("div", { class: "empty" }, "Open a song folder to see its versions, compare them, change it, rate what Flow made, and get the next prompts.") : null),
    song ? h("section", { class: "nextcol", "aria-label": "Next prompts" }, NextColumn(song)) : null);

  function folderList() {
    const items = sortedSongs().filter((s) => !(S.songQ || "") || (s.title + " " + (s.tags || []).join(" ") + " " + (s.preview || "")).toLowerCase().includes((S.songQ || "").toLowerCase()));
    if (!S.songsLoaded) return [h("p", { class: "hint", text: "Loading your songs…" })];
    if (!items.length) return [h("div", { class: "empty" }, S.songs.length ? "No songs match." : "No songs yet. Write a prompt in the Studio and press Save: each song gets its own folder.")];
    return items.map((s) => h("button", { class: "folder", "aria-current": String(s.id === S.openId), onclick: () => { openSong(s.id); render(); } },
      h("span", { class: "tab", "aria-hidden": "true" }),
      h("span", {}, h("b", { text: s.title }), h("small", { text: `v${s.latestN || 1} · ${fmtDate(s.updatedAt)}${s.grade ? ` · ${s.grade}` : ""}${s.rating ? ` · ${"★".repeat(s.rating)}` : ""}` }), s.tags?.length ? h("small", { style: "display:block", text: s.tags.join(" · ") }) : null)));
  }
}

function SongDetail(song) {
  const vs = S.versions;
  const v = vs.find((x) => x.n === S.selN) || vs[vs.length - 1];
  const head = h("div", { class: "row", style: "justify-content:space-between" },
    h("button", { class: "btn sm ghost", onclick: () => { S.vUnsub?.(); S.vUnsub = null; S.openId = null; render(); } }, "← All songs"),
    h("span", { class: "small muted", text: `Created ${fmtDate(song.createdAt)}` }));
  const title = h("input", { class: "title", type: "text", value: song.title, "aria-label": "Song title", style: "font:800 26px/1.1 var(--disp);border:0;background:transparent;padding:0", onchange: async (e) => { const t = e.target.value.trim(); if (t && t !== song.title) { await S.store.putSong({ ...fresh(song), title: t, updatedAt: new Date().toISOString() }); toast("Renamed"); } } });
  const parent = song.parentId && S.songs.find((s) => s.id === song.parentId);
  if (!v) return h("section", { class: "detail" }, head, title, h("p", { class: "hint", text: "Loading versions…" }));
  const cmp = S.cmpN && vs.find((x) => x.n === S.cmpN);
  const lab = (ids) => ids.map((id) => S.cat.byId.get(id)?.label || id);
  return h("section", { class: "detail", "aria-label": "Song folder" },
    head, title,
    parent ? h("p", { class: "small muted" }, "Next song after ", h("button", { class: "btn sm ghost", onclick: () => { openSong(parent.id); render(); } }, parent.title)) : null,
    h("h3", { style: "margin:12px 0 6px", text: "Versions" }),
    h("div", { class: "vline", role: "group", "aria-label": "Versions" }, vs.map((x) => h("button", { class: "vbtn" + (x.n === S.cmpN ? " cmp" : ""), "aria-pressed": String(x.n === v.n), title: x.changeNote || "", onclick: () => { S.selN = x.n; if (S.cmpN === x.n) S.cmpN = null; S.rate = null; render(); } }, `v${x.n}`))),
    h("p", { class: "small", style: "margin-top:0" }, h("b", { text: `v${v.n}` }), ` · ${fmtDate(v.createdAt)} · ${v.changeNote || ""}`, v.grade ? ` · check ${v.grade}` : "", v.source === "claude" ? " · by Claude" : ""),
    cmp ? CompareView(cmp, v, lab) : h("div", { class: "prompttext", text: v.prompt }),
    !cmp && v.lyrics ? h("details", { style: "margin-top:8px" }, h("summary", {}, "Lyrics"), h("div", { class: "prompttext", text: v.lyrics })) : null,
    h("div", { class: "row", style: "margin:10px 0" },
      h("button", { class: "btn sm primary", onclick: () => copy(v.lyrics ? `${v.prompt}\n\n${v.lyrics}` : v.prompt, "Copied") }, "Copy"),
      h("a", { class: "btn sm soft", href: E.FLOW_URL, target: "_blank", rel: "noopener" }, "Open Flow Music"),
      h("button", { class: "btn sm soft", onclick: () => loadVersionIntoStudio(song, v) }, "Tweak in Studio"),
      vs.length > 1 ? h("select", { "aria-label": "Compare with", class: "btn sm soft", style: "min-height:36px;width:auto", onchange: (e) => { S.cmpN = +e.target.value || null; render(); } }, h("option", { value: "" }, cmp ? "Stop comparing" : "Compare with…"), vs.filter((x) => x.n !== v.n).map((x) => h("option", { value: x.n, selected: x.n === S.cmpN }, `v${x.n}`))) : null),
    (v.chips || []).length ? h("p", { class: "small muted", text: "Buttons: " + lab(v.chips).join(" · ") }) : null,
    ChangeIt(song, v),
    RateIt(song, v),
    h("details", { style: "margin-top:14px" }, h("summary", {}, "Folder tools"),
      h("div", { class: "row", style: "margin-top:8px" },
        h("button", { class: "btn sm soft", onclick: async () => { const r = await E.verifyChain(vs); dialog({ title: r.ok ? "History intact" : "History changed", body: h("p", { text: r.ok ? `All ${vs.length} versions link up: each one's fingerprint matches the one before it, so nothing was edited after saving.` : `The chain breaks at v${r.brokenAt}: that version was changed after it was saved.` }) }); } }, "Check history"),
        h("button", { class: "btn sm soft", onclick: () => branchSong(song, v) }, `Copy v${v.n} to a new folder`),
        h("button", { class: "btn sm soft", onclick: () => copy(JSON.stringify({ ...song, versions: vs }, null, 2), "Song copied as JSON") }, "Copy as JSON"),
        h("button", { class: "btn sm danger", onclick: async () => { if (await confirmBox("Delete this song?", `“${song.title}” and all ${vs.length} versions will be deleted. This can't be undone.`, "Delete", true)) { await S.store.deleteSong(song.id); S.vUnsub?.(); S.vUnsub = null; S.openId = null; if (S.edit?.songId === song.id) S.edit = null; toast("Deleted"); render(); } } }, "Delete song"))));
}

function CompareView(a, b, lab) {
  const d = E.diffWords(a.prompt, b.prompt);
  const cd = E.chipDiff(a.chips, b.chips);
  return h("div", {},
    h("p", { class: "small", text: `Changes from v${a.n} to v${b.n}: green was added, red was removed.` }),
    h("div", { class: "prompttext diff" }, d.map((p) => (p.t === "same" ? p.s : h(p.t === "add" ? "ins" : "del", { class: p.t, text: p.s })))),
    cd.added.length || cd.removed.length ? h("p", { class: "small" }, cd.added.length ? `Buttons added: ${lab(cd.added).join(", ")}. ` : "", cd.removed.length ? `Removed: ${lab(cd.removed).join(", ")}.` : "") : null);
}

function ChangeIt(song, v) {
  const n = (song.latestN || v.n) + 1;
  const ta = h("textarea", { rows: 2, placeholder: "What should change? e.g. harder drums, swap the sax for a muted trumpet, darker chorus", value: S.tweakText, oninput: (e) => { S.tweakText = e.target.value; } });
  return h("div", { class: "card", style: "margin-top:12px" },
    h("h3", { text: `Change it (makes v${n})` }),
    h("p", { class: "small muted", text: `Starts from v${v.n}. Add, subtract or tune; the old versions stay in this folder.` }),
    h("div", { class: "tweakbar", style: "margin:8px 0" }, E.QUICK_TWEAKS.map(([op, label]) => h("button", { class: "chipbtn", "aria-pressed": String(S.tweakOps.includes(op)), onclick: (e) => { S.tweakOps = S.tweakOps.includes(op) ? S.tweakOps.filter((x) => x !== op) : [...S.tweakOps, op]; e.currentTarget.setAttribute("aria-pressed", String(S.tweakOps.includes(op))); } }, label))),
    ta, busyBar(),
    h("div", { class: "row", style: "margin-top:8px" },
      h("button", { class: "btn sm primary", "data-needs-idle": "", disabled: !!S.busy, onclick: () => makeVersion(song, v, true) }, `Make v${n} with Claude`),
      h("button", { class: "btn sm soft", onclick: () => makeVersion(song, v, false) }, `Make v${n} instantly`)));
}

async function makeVersion(song, v, withClaude) {
  const ops = S.tweakOps, text = S.tweakText.trim();
  if (!ops.length && !text) { toast("Pick a quick change or type what should change"); return; }
  let state = { ...E.blankState(), ...(v.state || {}), chips: [...(v.chips || [])] };
  const notes = [];
  for (const op of ops) { const r = E.quickTweak(state, op, S.cat); state = r.state; if (r.note) notes.push(r.note); }
  let prompt, lyrics = v.lyrics || "", changeNote, source;
  try {
    if (withClaude) {
      const r = await callAgent("tweaker", { version: { ...v, state: v.state || state }, request: [text, ...notes].filter(Boolean).join("\n") }, { label: "Claude is making the next version…" });
      prompt = r.prompt; lyrics = r.lyrics || lyrics; changeNote = r.changeNote || [text, ...notes].filter(Boolean).join("; ");
      if (r.bpm) state.bpm = r.bpm; if (r.key) state.key = r.key; if (r.length) state.length = r.length; if (r.vocals) state.vocals = r.vocals;
      state.chips = [...new Set([...state.chips, ...r.chips])];
      source = "claude";
    } else {
      if (text) state.notes = [state.notes, text].filter(Boolean).join(". ");
      const b = E.buildPrompt(state, S.cat);
      prompt = b.prompt; if (state.vocals === "instrumental") lyrics = "";
      changeNote = [...notes, text].filter(Boolean).join("; ");
      source = "engine";
    }
  } catch (e) { reportError(e); render(); return; }
  const vs = await S.store.listVersions(song.id);
  const prev = vs[vs.length - 1];
  const crit = E.critique(prompt, lyrics, state, S.cat);
  const now = new Date().toISOString();
  const nv = await E.sealVersion({ n: (prev?.n || 0) + 1, createdAt: now, prompt, lyrics, chips: state.chips, settings: { bpm: state.bpm, key: state.key, length: state.length, vocals: E.vocalIntent(state), language: state.language }, state, source, changeNote: `From v${v.n}: ${changeNote}`, score: crit.score, grade: crit.grade, title: song.title }, prev?.hash);
  await S.store.putVersion(song.id, nv);
  await S.store.putSong({ ...fresh(song), updatedAt: now, latestN: nv.n, latestHash: nv.hash, score: crit.score, grade: crit.grade, preview: prompt.slice(0, 160) });
  S.tweakOps = []; S.tweakText = ""; S.selN = nv.n;
  toast(`Saved v${nv.n}`);
  render();
}

function RateIt(song, v) {
  const r = S.rate && S.rate.n === v.n ? S.rate : (S.rate = { n: v.n, stars: v.rating || 0, notes: v.resultNotes || "", link: v.flowLink || "" });
  const notes = h("textarea", { rows: 2, placeholder: "What did Flow give you? What worked, what didn't?", value: r.notes, oninput: (e) => { r.notes = e.target.value; } });
  const link = h("input", { type: "url", placeholder: "Link to the song in Flow (optional)", value: r.link, oninput: (e) => { r.link = e.target.value; } });
  const stars = h("span", { class: "stars", role: "group", "aria-label": "Rating" }, [1, 2, 3, 4, 5].map((i) => h("button", { "aria-pressed": String(i <= r.stars), "aria-label": `${i} star${i > 1 ? "s" : ""}`, onclick: (e) => { r.stars = i; for (const [k, b] of [...e.currentTarget.parentNode.children].entries()) b.setAttribute("aria-pressed", String(k < i)); } }, "★")));
  return h("div", { class: "card", style: "margin-top:12px" },
    h("h3", { text: `How did v${v.n} come out in Flow?` }), stars, notes, h("div", { style: "height:8px" }), link,
    safeUrl(v.flowLink) ? h("p", { class: "small" }, h("a", { href: safeUrl(v.flowLink), target: "_blank", rel: "noopener" }, "Open the saved Flow link")) : null,
    h("div", { class: "row", style: "margin-top:8px" }, h("button", { class: "btn sm primary", onclick: () => saveRating(song, v, r) }, "Save rating")));
}

async function saveRating(song, v, r) {
  const link = r.link.trim();
  if (link && !safeUrl(link)) { toast("Links must start with https://"); return; }
  await S.store.putVersion(song.id, { ...v, rating: r.stars, resultNotes: r.notes.trim(), flowLink: link });
  await S.store.putSong({ ...fresh(song), rating: r.stars });
  toast("Rating saved");
  const b = backendFor();
  if (S.settings.autoLesson && r.notes.trim().length > 12 && (b === "claude" || b === "api")) {
    try {
      const L = await callAgent("librarian", { version: v, rating: r.stars, notes: r.notes }, { label: "Claude is looking for a lesson…" });
      if (L.lesson) { await addLesson({ text: L.lesson, scope: L.scope, evidence: L.evidence, status: "pending", songId: song.id }); toast("Claude suggested a lesson. Review it in Setup → Lessons."); }
    } catch { /* lessons are optional */ }
  }
  render();
}

async function branchSong(song, v) {
  const now = new Date().toISOString();
  const id = newId("s");
  const nv = await E.sealVersion({ ...v, n: 1, createdAt: now, changeNote: `Copied from “${song.title}” v${v.n}`, rating: 0, resultNotes: "", flowLink: "" }, null);
  await S.store.putVersion(id, nv);
  await S.store.putSong({ id, title: `${song.title} (copy)`, createdAt: now, updatedAt: now, latestN: 1, latestHash: nv.hash, score: v.score, grade: v.grade, tags: song.tags || [], preview: v.prompt.slice(0, 160), next: [], rating: 0, parentId: song.id });
  openSong(id); toast("Copied to a new folder"); render();
}

// ======================================================================
// NEXT (additive prompts column)
// ======================================================================
function NextColumn(song) {
  const items = song.next || [];
  const kinds = [["next-song", "Next songs in the series"], ["compose", "Edit in Compose"], ["extend", "Extend"], ["cover", "Cover"], ["replace", "Replace a section"], ["stems", "Stems"], ["lyrics", "Lyrics"], ["variation", "Variations"]];
  const children = S.songs.filter((s) => s.parentId === song.id);
  return [
    h("h2", { text: "Next" }),
    h("p", { class: "small muted", text: "Follow-up prompts for this song: Flow edit moves, and the next tracks in the same series." }),
    busyBar(),
    h("div", { class: "row" },
      h("button", { class: "btn sm primary", "data-needs-idle": "", disabled: !!S.busy, onclick: () => addNextClaude(song) }, "Ask Claude for next steps"),
      h("button", { class: "btn sm soft", onclick: () => addNextOffline(song) }, "Use templates")),
    children.length ? h("div", { class: "card" }, h("b", { text: "Already made from this song" }), h("div", { class: "row", style: "margin-top:6px" }, children.map((c) => h("button", { class: "btn sm soft", onclick: () => { openSong(c.id); location.hash = "#songs"; render(); } }, c.title)))) : null,
    items.length ? null : h("div", { class: "empty" }, "Nothing here yet. Ask Claude, or use the templates."),
    ...kinds.filter(([k]) => items.some((i) => i.kind === k)).flatMap(([k, label]) => [
      h("h3", { style: "margin-top:8px", text: label }),
      ...items.filter((i) => i.kind === k).map((it) => h("div", { class: "nitem" + (it.used ? " used" : "") },
        h("div", {}, h("span", { class: `kind k-${it.kind}`, text: it.kind.replace("-", " ") }), h("b", { text: it.label })),
        h("p", { text: it.prompt }), it.why ? h("p", { class: "small muted", text: it.why }) : null,
        h("div", { class: "row" },
          h("button", { class: "btn sm soft", onclick: () => copy(it.prompt) }, "Copy"),
          it.kind === "next-song" ? h("button", { class: "btn sm primary", onclick: () => startNextSong(song, it) }, "Start this song") : h("button", { class: "btn sm soft", onclick: () => updateNext(song, items.map((x) => (x.id === it.id ? { ...x, used: !x.used } : x))) }, it.used ? "Mark unused" : "Mark used"),
          h("button", { class: "btn sm ghost", "aria-label": "Remove", onclick: () => updateNext(song, items.filter((x) => x.id !== it.id)) }, "Remove"))))]),
  ];
}

const fresh = (song) => S.songs.find((s) => s.id === song.id) || song;
async function updateNext(song, items) { await S.store.putSong({ ...fresh(song), next: items.slice(0, 60) }); }

async function addNextClaude(song) {
  const vs = await S.store.listVersions(song.id);
  const v = vs[vs.length - 1]; if (!v) return;
  const history = vs.filter((x) => x.resultNotes).map((x) => `v${x.n} (${x.rating || "?"}★): ${x.resultNotes}`).join("\n");
  try {
    const r = await callAgent("nexter", { song, version: v, history }, { label: "Claude is writing next steps…" });
    const items = r.items.map((x) => ({ ...x, id: newId("n"), createdAt: new Date().toISOString(), source: "claude", fromV: v.n }));
    await updateNext(song, [...items, ...(song.next || [])]);
    toast(`Added ${items.length} next steps`);
  } catch (e) { reportError(e); }
  render();
}

async function addNextOffline(song) {
  const vs = await S.store.listVersions(song.id);
  const v = vs[vs.length - 1]; if (!v) return;
  const have = new Set((song.next || []).map((x) => x.prompt));
  const items = E.offlineNextSteps(v, S.cat, S.recipes).filter((x) => !have.has(x.prompt)).map((x) => ({ ...x, id: newId("n"), createdAt: new Date().toISOString(), source: "template", fromV: v.n }));
  await updateNext(song, [...items, ...(song.next || [])]);
  toast(items.length ? `Added ${items.length} template steps` : "Templates already added");
  render();
}

async function startNextSong(song, it) {
  const vs = await S.store.listVersions(song.id);
  const base = vs[vs.length - 1];
  const now = new Date().toISOString();
  const id = newId("s");
  const state = { ...E.blankState(), ...(base?.state || {}), query: it.label, brief: "" };
  const crit = E.critique(it.prompt, "", state, S.cat);
  const v = await E.sealVersion({ n: 1, createdAt: now, prompt: it.prompt, lyrics: "", chips: [...(base?.chips || [])], settings: base?.settings || {}, state, source: it.source === "claude" ? "claude" : "engine", changeNote: `Started from “${song.title}”: ${it.label}`, score: crit.score, grade: crit.grade, title: it.label }, null);
  await S.store.putVersion(id, v);
  await S.store.putSong({ id, title: it.label.slice(0, 60), createdAt: now, updatedAt: now, latestN: 1, latestHash: v.hash, score: crit.score, grade: crit.grade, tags: song.tags || [], preview: it.prompt.slice(0, 160), next: [], rating: 0, parentId: song.id });
  await updateNext(song, (song.next || []).map((x) => (x.id === it.id ? { ...x, used: true, songId: id } : x)));
  openSong(id); location.hash = "#songs"; toast("New song folder created, linked to the last one"); render();
}

function Next() {
  const songs = sortedSongs();
  if (!S.songsLoaded) return h("p", { class: "hint", text: "Loading your songs…" });
  if (!songs.length) return h("div", {}, h("h1", { text: "Next" }), h("div", { class: "empty", style: "margin-top:12px" }, "Save a song first. Then this column fills with follow-up prompts for it."));
  const id = S.nextSongId && songs.some((s) => s.id === S.nextSongId) ? S.nextSongId : (S.openId || songs[0].id);
  S.nextSongId = id;
  const song = songs.find((s) => s.id === id);
  return h("div", { style: "max-width:820px" },
    h("label", { class: "field", style: "margin-bottom:12px" }, h("span", { text: "Song" }), h("select", { onchange: (e) => { S.nextSongId = e.target.value; render(); } }, songs.map((s) => h("option", { value: s.id, selected: s.id === id }, s.title)))),
    h("div", { class: "nextcol" }, NextColumn(song)));
}

// ======================================================================
// LIBRARY
// ======================================================================
function Library() {
  const L = S.lib;
  const tabs = [["snippets", "Snippets"], ["beats", "Beats"], ["recipes", "Recipes"], ["tunings", "Tunings"], ["moves", "Flow moves"], ["mine", "My snippets"]];
  const body = h("div", { id: "libbody" });
  const fill = () => { put(body, libItems()); };
  const out = h("div", {},
    h("h1", { text: "Library" }),
    h("p", { class: "hint", text: "Copy-paste prompts for every instrument, drum machine, tuning, beat and Flow move. Tap Add to drop one into the Studio." }),
    h("div", { class: "cats", role: "group", "aria-label": "Library sections", style: "margin-top:8px" }, tabs.map(([id, t]) => h("button", { class: "cat", "aria-pressed": String(L.tab === id), onclick: () => { L.tab = id; L.limit = 60; render(); } }, t))),
    h("div", { class: "libtop" },
      h("input", { type: "search", placeholder: "Search the library", value: L.q, "aria-label": "Search the library", oninput: (e) => { L.q = e.target.value; L.limit = 60; fill(); } }),
      L.tab === "snippets" ? h("select", { "aria-label": "Category", style: "width:auto", onchange: (e) => { L.cat = e.target.value; L.limit = 60; fill(); } }, h("option", { value: "all" }, "All categories"), E.CATEGORIES.filter((c) => (S.cat.byCat.get(c.id) || []).length).map((c) => h("option", { value: c.id, selected: L.cat === c.id }, c.label))) : null),
    body);
  fill();
  return out;
}

function matches(q, ...fields) { if (!q) return true; const t = fields.join(" ").toLowerCase(); return q.toLowerCase().split(/\s+/).every((w) => t.includes(w)); }
function more(total, rerender) { return total > S.lib.limit ? h("div", { class: "row", style: "justify-content:center;margin-top:12px" }, h("button", { class: "btn soft", onclick: () => { S.lib.limit += 90; rerender(); } }, `Show more (${total - S.lib.limit} left)`)) : null; }

function libItems() {
  const L = S.lib, q = L.q.trim();
  const rerender = () => put($("#libbody"), libItems());
  if (L.tab === "snippets") {
    const list = S.cat.chips.filter((c) => (L.cat === "all" || c.cat === L.cat) && matches(q, c.label, c.group, c.desc, c.prompt, E.CAT_BY_ID[c.cat]?.label));
    if (!list.length) return [h("div", { class: "empty" }, S.cat.chips.length ? "Nothing matches." : "The snippet library hasn't loaded.")];
    return [h("p", { class: "small muted", text: `${list.length} snippets` }), h("div", { class: "cards" }, list.slice(0, L.limit).map((c) => h("article", { class: "lcard" },
      h("h3", {}, h("span", { class: "dot", style: `background:var(--${toneOf(c)})` }), c.label),
      h("span", { class: "small muted", text: `${E.CAT_BY_ID[c.cat]?.label} · ${c.group}${c.bpm ? ` · ${c.bpm[0]}–${c.bpm[1]} BPM` : ""}` }),
      h("p", { class: "small", text: c.desc }), h("div", { class: "snip", text: c.prompt }),
      h("div", { class: "row" }, h("button", { class: "btn sm soft", onclick: () => copy(c.prompt) }, "Copy"), h("button", { class: "btn sm soft", "aria-pressed": String(S.st.chips.includes(c.id)), onclick: () => { if (!S.st.chips.includes(c.id)) { S.st.chips.push(c.id); studioChanged(); toast(`${c.label} added to the Studio`); } else toast("Already in the Studio"); } }, "Add to Studio"))))), more(list.length, rerender)];
  }
  if (L.tab === "beats") {
    const list = (S.beats.patterns || []).filter((p) => matches(q, p.name, p.genre, p.desc, p.prompt));
    if (!list.length) return [h("div", { class: "empty" }, "No beats match.")];
    return [h("div", { class: "cards" }, list.map((p) => h("article", { class: "lcard" },
      h("h3", { text: p.name }), h("span", { class: "small muted", text: `${p.genre} · ${p.bpm[0]}–${p.bpm[1]} BPM · ${p.timeSig}${p.swing > 52 ? ` · swing ${p.swing}%` : ""}` }),
      StepGrid(p), h("p", { class: "small", text: p.desc }), h("div", { class: "snip", text: p.prompt }),
      h("div", { class: "row" }, h("button", { class: "btn sm soft", onclick: () => copy(p.prompt) }, "Copy"), h("button", { class: "btn sm soft", onclick: () => { S.st.bpm = Math.round((p.bpm[0] + p.bpm[1]) / 2); S.st.notes = [S.st.notes, p.prompt].filter(Boolean).join(". "); studioChanged(); toast(`${p.name} groove added to the Studio`); } }, "Use in Studio")))))];
  }
  if (L.tab === "recipes") {
    const list = (S.recipes.recipes || []).filter((r) => matches(q, r.title, r.genre, r.prompt, (r.tags || []).join(" "), r.why));
    if (!list.length) return [h("div", { class: "empty" }, "No recipes match.")];
    return [h("div", { class: "cards" }, list.map((r) => h("article", { class: "lcard" },
      h("h3", { text: r.title }), h("span", { class: "small muted", text: `${r.genre} · ${r.bpm} BPM · ${r.key} · ${r.vocals ? "vocals" : "instrumental"}` }),
      h("div", { class: "snip", text: r.prompt }), h("p", { class: "small muted", text: r.why }),
      h("div", { class: "row" }, h("button", { class: "btn sm soft", onclick: () => copy(r.prompt) }, "Copy"), h("button", { class: "btn sm soft", onclick: () => loadRecipe(r) }, "Load in Studio")))))];
  }
  if (L.tab === "tunings") {
    const list = (S.recipes.tunings || []).filter((t) => matches(q, t.label, t.instrument, t.notes, t.desc, t.prompt));
    return [h("div", { class: "cards" }, list.map((t) => h("article", { class: "lcard" },
      h("h3", { text: t.label }), h("span", { class: "small muted", text: `${t.instrument} · ${t.notes}` }), h("p", { class: "small", text: t.desc }), h("div", { class: "snip", text: t.prompt }),
      h("div", { class: "row" }, h("button", { class: "btn sm soft", onclick: () => copy(t.prompt) }, "Copy"), h("button", { class: "btn sm soft", onclick: () => { S.st.notes = [S.st.notes, t.prompt].filter(Boolean).join(". "); studioChanged(); toast("Added to the Studio notes"); } }, "Add to Studio")))))];
  }
  if (L.tab === "moves") {
    const song = S.songs.find((s) => s.id === S.openId);
    const v = song && S.versions[S.versions.length - 1];
    const st = v?.state || S.st;
    const ctx = { section: "chorus", style: "acoustic", instrument: "piano", bars: 4, mood: "hopeful", bpm: st.bpm || "", key: st.key || "", genre: (st.chips || []).map((id) => S.cat.byId.get(id)).find((c) => c?.cat === "genre")?.label || "" };
    const list = (S.recipes.edits || []).filter((e) => matches(q, e.label, e.mode, e.template, e.example, e.when));
    const modes = ["new", "compose", "extend", "cover", "replace", "stems", "lyrics"];
    return [h("p", { class: "small muted", text: song ? `Placeholders filled from “${song.title}”. Edit the {words} that remain.` : "Open a song in Songs to fill these in from it. Edit the {words} in braces." }),
      ...modes.filter((m) => list.some((e) => e.mode === m)).flatMap((m) => [h("h2", { style: "margin:16px 0 8px", text: m[0].toUpperCase() + m.slice(1) }), h("div", { class: "cards" }, list.filter((e) => e.mode === m).map((e) => { const t = E.fillTemplate(e.template, ctx); return h("article", { class: "lcard" }, h("h3", { text: e.label }), h("p", { class: "small muted", text: e.when }), h("div", { class: "snip", text: t }), h("p", { class: "small" }, "Example: ", h("i", { text: e.example })), h("div", { class: "row" }, h("button", { class: "btn sm soft", onclick: () => copy(t) }, "Copy"), h("button", { class: "btn sm soft", onclick: () => copy(e.example) }, "Copy example"))); }))])];
  }
  // mine
  const items = (S.snippets.items || []).filter((s) => matches(q, s.title, s.text));
  const t = h("input", { type: "text", placeholder: "Name (e.g. My signature drums)" });
  const x = h("textarea", { rows: 3, placeholder: "The prompt text you want to reuse" });
  return [h("div", { class: "card", style: "margin-bottom:12px" }, h("h3", { text: "Save a snippet" }), t, h("div", { style: "height:8px" }), x,
    h("div", { class: "row", style: "margin-top:8px" }, h("button", { class: "btn sm primary", onclick: async () => { if (!x.value.trim()) return toast("Write the snippet first"); await addSnippet(t.value.trim() || "Snippet", x.value.trim()); rerender(); } }, "Save snippet"), S.out.prompt ? h("button", { class: "btn sm soft", onclick: async () => { await addSnippet(S.out.title || "Studio prompt", S.out.prompt); rerender(); } }, "Save the current Studio prompt") : null)),
    items.length ? h("div", { class: "cards" }, items.map((s) => h("article", { class: "lcard" }, h("h3", { text: s.title }), h("div", { class: "snip", text: s.text }),
      h("div", { class: "row" }, h("button", { class: "btn sm soft", onclick: () => copy(s.text) }, "Copy"), h("button", { class: "btn sm soft", onclick: () => { S.st.notes = [S.st.notes, s.text].filter(Boolean).join(". "); studioChanged(); toast("Added to the Studio notes"); } }, "Add to Studio"),
        h("button", { class: "btn sm ghost", onclick: async () => { S.snippets.items = S.snippets.items.filter((y) => y.id !== s.id); await S.store.putDoc("snippets", S.snippets); rerender(); } }, "Delete"))))) : h("div", { class: "empty" }, "Your own reusable snippets land here.")];
}

async function addSnippet(title, text) {
  await S.storeReady;
  S.snippets.items = [{ id: newId("p"), title: title.slice(0, 80), text, createdAt: new Date().toISOString() }, ...(S.snippets.items || [])].slice(0, 300);
  await S.store.putDoc("snippets", S.snippets); toast("Snippet saved");
}

function loadRecipe(r) {
  S.st = { ...E.blankState(), query: r.title, brief: r.title, bpm: r.bpm, key: E.ALL_KEYS.includes(r.key) ? r.key : "", vocals: r.vocals ? "vocals" : "instrumental", lyricTheme: r.lyricsHint || "" };
  S.out = { title: r.title, prompt: r.prompt, lyrics: "", source: "manual", why: r.why, variations: [], stale: false, critic: null, changeNote: "" };
  S.edit = null; saveDraft(); location.hash = "#studio"; toast("Recipe loaded. Tap pads to shape it, then Update with Claude or edit by hand.");
}

function StepGrid(p) {
  const beatEvery = p.steps === 12 ? 3 : p.steps === 32 ? 8 : 4;
  return h("div", { class: "grid16", role: "img", "aria-label": `${p.name} step pattern` }, p.lanes.map((l) => h("div", { class: "lane" }, h("span", { text: l.inst }),
    h("div", { class: "steps", style: `grid-template-columns:repeat(${p.steps},minmax(0,1fr))` }, [...l.hits].map((c, i) => h("i", { class: (c === "." ? "" : c) + (i % beatEvery === 0 ? " beat" : "") }))))));
}

// ======================================================================
// LEARN
// ======================================================================
function Learn() {
  const sections = [...(S.flow.sections || []), ...(S.learn.sections || [])];
  const q = S.learnQ.trim().toLowerCase();
  const all = sections.flatMap((s) => (s.articles || []).map((a) => ({ s, a })));
  const hit = (a) => !q || JSON.stringify(a).toLowerCase().includes(q);
  const found = all.find((x) => x.a.id === S.learnId) || all[0];
  const toc = h("nav", { class: "toc", "aria-label": "Lessons" },
    h("input", { type: "search", placeholder: "Search lessons", value: S.learnQ, "aria-label": "Search lessons", oninput: (e) => { S.learnQ = e.target.value; const t = $("#toclist"); if (t) put(t, tocItems()); } }),
    h("div", { id: "toclist" }, tocItems()));
  function tocItems() {
    const qq = S.learnQ.trim().toLowerCase();
    return sections.flatMap((s) => { const arts = (s.articles || []).filter((a) => !qq || JSON.stringify(a).toLowerCase().includes(qq)); return arts.length ? [h("h3", { text: s.title }), ...arts.map((a) => h("button", { "aria-current": String(a.id === found?.a.id), onclick: () => { S.learnId = a.id; render(); } }, a.title))] : []; });
  }
  void hit;
  if (!found) return h("div", {}, h("h1", { text: "Learn" }), h("div", { class: "empty" }, "Lessons haven't loaded."));
  return h("div", { class: "learn" }, toc, Article(found.a, found.s));
}

function Article(a, s) {
  return h("article", { class: "article" },
    h("p", { class: "small muted", text: s.title + (S.flow.updated && s.id === "flow" ? ` · checked ${S.flow.updated}` : "") }),
    h("h2", { text: a.title }), h("p", { class: "muted", text: a.summary }),
    (a.body || []).map((b) => {
      if (b.type === "p") return h("p", {}, linkify(b.text));
      if (b.type === "h") return h("h3", { text: b.text });
      if (b.type === "list") return h("ul", {}, b.items.map((t) => h("li", {}, linkify(t))));
      if (b.type === "tip") return h("div", { class: "tip" }, h("b", { text: "Tip " }), linkify(b.text));
      if (b.type === "prompt") return h("div", {}, h("div", { class: "pblock", text: b.text }), h("div", { class: "row" }, h("button", { class: "btn sm soft", onclick: () => copy(b.text) }, "Copy"), h("button", { class: "btn sm soft", onclick: () => { S.st.notes = [S.st.notes, b.text.replace(/\n/g, " ")].filter(Boolean).join(". "); studioChanged(); toast("Added to the Studio notes"); } }, "Add to Studio")));
      if (b.type === "table") return h("div", { class: "scroll" }, h("table", {}, h("thead", {}, h("tr", {}, b.head.map((t) => h("th", { text: t })))), h("tbody", {}, b.rows.map((r) => h("tr", {}, r.map((c) => h("td", { text: String(c) })))))));
      return null;
    }));
}

// ======================================================================
// SETUP
// ======================================================================
async function addLesson(l) {
  await S.storeReady;
  S.lessons.items = [{ id: newId("l"), createdAt: new Date().toISOString(), ...l }, ...(S.lessons.items || [])].slice(0, 200);
  await S.store.putDoc("lessons", S.lessons);
}
async function saveSettings() { await S.storeReady; await S.store.putDoc("settings", S.settings); updateChrome(); }

function Setup() {
  const st = S.settings;
  const b = backendFor();
  const sel = (label, value, opts, on, hint) => h("label", { class: "field" }, h("span", { text: label }), h("select", { onchange: async (e) => { on(e.target.value); await saveSettings(); render(); } }, opts.map(([v, t]) => h("option", { value: v, selected: v === value }, t))), hint ? h("span", { class: "small", text: hint }) : null);
  const modes = [["auto", "Automatic (best available)"], ["claude", "My Claude account (inside Claude)"], ...(IN_ARTIFACT ? [] : [["api", "Anthropic API key"]]), ["bridge", "Copy & paste with the Claude app"], ["offline", "Offline only (no Claude)"]];
  const today = S.traces.days?.[new Date().toISOString().slice(0, 10)] || { calls: 0, ok: 0, fail: 0, ms: 0, costUsd: 0 };
  const L = statusLight(S.traces, st);
  const pending = (S.lessons.items || []).filter((l) => l.status === "pending");
  const approved = (S.lessons.items || []).filter((l) => l.status === "approved");
  const own = h("input", { type: "text", placeholder: "Write your own rule, e.g. Keep intros under 8 bars" });
  return h("div", {},
    h("h1", { style: "margin-bottom:14px", text: "Setup" }),
    h("div", { class: "setup" },
      h("section", { class: "card" }, h("h2", { text: "Claude connection" }),
        h("p", { class: "small" }, "Now using: ", h("b", { text: BACKEND_LABEL[b] })),
        IN_ARTIFACT ? h("p", { class: "small muted", text: S.ai.sample && !S.ai.sampleBlocked ? "Inside Claude, FLOWSMITH asks Claude with your own Claude account. The first time, Claude asks you to allow it." : "Claude access isn't available in this view. Copy & paste with the Claude app still works." })
          : h("p", { class: "small muted", text: "Outside Claude, connect with an Anthropic API key (pay per use, from console.anthropic.com) or use copy & paste with your Claude app (free with your plan)." }),
        sel("How to reach Claude", st.aiMode, modes, (v) => { st.aiMode = v; }),
        IN_ARTIFACT ? sel("Quality", st.tier, [["default", "Balanced"], ["complex", "Best (slower)"], ["quick", "Fast"]], (v) => { st.tier = v; }) : null,
        !IN_ARTIFACT ? h("div", { style: "display:grid;gap:10px;margin-top:10px" },
          h("label", { class: "field" }, h("span", { text: "Anthropic API key (stays on this device, never synced or exported)" }), h("input", { type: "password", value: S.apiKey, autocomplete: "off", placeholder: "sk-ant-…", onchange: (e) => { S.apiKey = e.target.value.trim(); ls.set("flowsmith.apiKey", S.apiKey); updateChrome(); toast(S.apiKey ? "Key saved on this device" : "Key removed"); } })),
          sel("Model", st.apiModel, API_MODELS.map((m) => [m.id, m.label]), (v) => { st.apiModel = v; }),
          sel("Effort", st.apiEffort, [["low", "Low"], ["medium", "Medium"], ["high", "High"]], (v) => { st.apiEffort = v; }, "Higher effort thinks longer and costs more.")) : null,
        h("label", { class: "field", style: "margin-top:10px" }, h("span", { text: "Daily limit on Claude calls (0 = no limit)" }), h("input", { type: "number", min: 0, max: 1000, value: st.dailyCap, onchange: async (e) => { st.dailyCap = Math.max(0, parseInt(e.target.value, 10) || 0); await saveSettings(); } })),
        h("label", { class: "row small", style: "margin-top:10px" }, h("input", { type: "checkbox", checked: st.claudeCritic, onchange: async (e) => { st.claudeCritic = e.target.checked; await saveSettings(); } }), "Ask Claude to review every prompt it writes (uses more)"),
        h("label", { class: "row small" }, h("input", { type: "checkbox", checked: st.autoLesson, onchange: async (e) => { st.autoLesson = e.target.checked; await saveSettings(); } }), "Suggest a lesson when I rate a song")),

      h("section", { class: "card" }, h("h2", { text: "Lessons" }),
        h("p", { class: "small muted", text: "Rules added to every prompt Claude writes. New ones from Claude wait here until you approve them." }),
        pending.length ? h("h3", { text: `Waiting for you (${pending.length})` }) : null,
        pending.map((l) => h("div", { class: "lesson" }, h("b", { text: l.text }), h("div", { class: "small muted", text: `For ${l.scope || "all songs"}. ${l.evidence || ""}` }),
          h("div", { class: "row", style: "margin-top:6px" }, h("button", { class: "btn sm primary", onclick: () => setLesson(l.id, "approved") }, "Approve"), h("button", { class: "btn sm soft", onclick: () => setLesson(l.id, "rejected") }, "Reject")))),
        h("h3", { style: "margin-top:10px", text: `In use (${approved.length})` }),
        approved.length ? approved.map((l) => h("div", { class: "lesson row", style: "justify-content:space-between" }, h("span", { text: l.text }), h("button", { class: "btn sm ghost", onclick: () => setLesson(l.id, "rejected") }, "Remove"))) : h("p", { class: "small muted", text: "None yet." }),
        h("div", { class: "row", style: "margin-top:8px" }, own, h("button", { class: "btn sm soft", onclick: async () => { if (own.value.trim()) { await addLesson({ text: own.value.trim(), scope: "all songs", evidence: "Written by you", status: "approved" }); render(); } } }, "Add rule"))),

      h("section", { class: "card" }, h("h2", { text: "Usage and status" }),
        h("p", {}, h("span", { class: "led " + L.color, style: "display:inline-block;margin-right:8px" }), L.text),
        h("table", { class: "tbl" }, h("tbody", {},
          h("tr", {}, h("td", { text: "Claude calls today" }), h("td", { class: "num", text: `${today.calls}${st.dailyCap ? ` of ${st.dailyCap}` : ""}` })),
          h("tr", {}, h("td", { text: "Worked / failed" }), h("td", { class: "num", text: `${today.ok} / ${today.fail}` })),
          h("tr", {}, h("td", { text: "Average wait" }), h("td", { class: "num", text: today.calls ? `${(today.ms / today.calls / 1000).toFixed(1)} s` : "–" })),
          today.costUsd ? h("tr", {}, h("td", { text: "API cost today (estimate)" }), h("td", { class: "num", text: `$${today.costUsd.toFixed(3)}` })) : null)),
        (S.traces.recent || []).length ? h("details", { style: "margin-top:8px" }, h("summary", { class: "small" }, "Recent calls"),
          h("div", { class: "scroll" }, h("table", { class: "tbl" }, h("thead", {}, h("tr", {}, ["When", "Agent", "How", "Result", "Time"].map((t) => h("th", { text: t })))),
            h("tbody", {}, S.traces.recent.slice(0, 20).map((t) => h("tr", {}, h("td", { text: new Date(t.ts).toLocaleTimeString() }), h("td", { text: AGENTS[t.agent]?.label || t.agent }), h("td", { text: t.backend }), h("td", { text: t.ok ? "ok" : t.err || "failed" }), h("td", { class: "num", text: `${(t.ms / 1000).toFixed(1)} s` }))))))) : null),

      h("section", { class: "card" }, h("h2", { text: "Your songs and backup" }),
        h("p", { class: "small", text: S.store ? S.store.label : "Opening storage…" }),
        h("p", { class: "small muted", text: `${S.songs.length} song folders.` }),
        h("div", { class: "row" },
          h("button", { class: "btn sm soft", onclick: async () => copy(JSON.stringify(await exportAll(S.store, S.songs)), "Backup copied") }, "Copy backup"),
          !IN_ARTIFACT ? h("button", { class: "btn sm soft", onclick: downloadBackup }, "Download backup") : null,
          h("button", { class: "btn sm soft", onclick: importDialog }, "Restore / import")),
        h("p", { class: "small muted", text: "Use a backup to move songs between the Claude version and the standalone app. The API key is never included." })),

      h("section", { class: "card" }, h("h2", { text: "Install" }),
        InstallBits(),
        h("p", { class: "small muted", text: "On iPhone or iPad (standalone app): open it in Safari, tap Share, then Add to Home Screen. On Android: Chrome menu, Install app." })),

      h("section", { class: "card" }, h("h2", { text: "About" }),
        h("p", { class: "small", text: `FLOWSMITH ${VERSION}. A prompt studio for Google Flow Music. Not made by or affiliated with Google.` }),
        h("p", { class: "small" }, "Flow Music: ", h("a", { href: E.FLOW_URL, target: "_blank", rel: "noopener" }, "flowmusic.app"), " · Google Labs: ", h("a", { href: E.LABS_URL, target: "_blank", rel: "noopener" }, "labs.google")),
        h("p", { class: "small muted", text: `${S.cat.chips.length} sound buttons · ${(S.beats.patterns || []).length} beats · ${(S.recipes.recipes || []).length} recipes · ${[...(S.flow.sections || []), ...(S.learn.sections || [])].reduce((n, s) => n + (s.articles || []).length, 0)} lessons` }))));
}

function InstallBits() {
  const out = [];
  const d = S.ai.desk;
  if (d && !d.fs) {
    const btn = h("button", { class: "btn sm primary", hidden: true, onclick: () => d.install.request().then((r) => toast(r === "installed" ? "Installing as a desktop app" : "Not installed")).catch(() => toast("Couldn't install here")) }, "Install as a desktop app");
    d.install.state().then((s) => { btn.hidden = s !== "available"; if (s === "installed") btn.replaceWith(h("p", { class: "small", text: "Installed as a desktop app on this computer." })); }).catch(() => {});
    out.push(btn);
  }
  if (S.installEvt) out.push(h("button", { class: "btn sm primary", onclick: async () => { S.installEvt.prompt(); S.installEvt = null; } }, "Install the app"));
  if (!out.length) out.push(h("p", { class: "small", text: IN_ARTIFACT ? "Open this page in the Claude desktop app to install it as its own app. On phones it opens in the Claude app." : "If your browser offers it, use its Install option." }));
  return out;
}

async function setLesson(id, status) {
  S.lessons.items = S.lessons.items.map((l) => (l.id === id ? { ...l, status } : l));
  await S.store.putDoc("lessons", S.lessons); render();
}

async function downloadBackup() {
  const data = await exportAll(S.store, S.songs);
  const a = h("a", { href: URL.createObjectURL(new Blob([JSON.stringify(data, null, 1)], { type: "application/json" })), download: `flowsmith-backup-${new Date().toISOString().slice(0, 10)}.json` });
  document.body.append(a); a.click(); a.remove();
}

function importDialog() {
  const ta = h("textarea", { rows: 8, placeholder: "Paste a FLOWSMITH backup here, or pick a file" });
  const file = h("input", { type: "file", accept: "application/json,.json", onchange: async (e) => { const f = e.target.files[0]; if (f) ta.value = await f.text(); } });
  dialog({ title: "Restore or import songs", body: h("div", {}, file, h("div", { style: "height:8px" }), ta, h("p", { class: "small muted", text: "Songs already here are kept; matching ones are skipped." })),
    actions: [{ label: "Cancel", value: null }, { label: "Import", primary: true, onClick: async () => {
      try { const r = await importAll(S.store, JSON.parse(ta.value), new Set(S.songs.map((s) => s.id))); S.lessons = await S.store.getDoc("lessons", { items: [] }); S.snippets = await S.store.getDoc("snippets", { items: [] }); toast(`Imported ${r.added} songs${r.skipped ? `, skipped ${r.skipped}` : ""}`); render(); return true; }
      catch (e) { toast(e.message || "That backup couldn't be read"); return false; } } }] });
}

// expose a tiny hook for tests
globalThis.__flowsmith = { S, E, buildRequest };
boot();
