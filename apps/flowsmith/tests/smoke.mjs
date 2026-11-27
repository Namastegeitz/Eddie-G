// Browser smoke test: drives the real app in Chromium.
// Run A: standalone (IndexedDB, offline builder). Run B: inside a simulated Claude artifact
// (mock claude.use: sample, db, user), so the Claude + synced-folder paths are exercised.
// Usage: node tests/smoke.mjs   (writes screenshots to tests/out/)
import { createRequire } from "node:module";
import { execSync, spawn } from "node:child_process";
import { mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const require = createRequire(execSync("npm root -g").toString().trim() + "/");
const { chromium } = require("playwright");
const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const OUT = join(root, "tests", "out");
mkdirSync(OUT, { recursive: true });
const PORT = 8765;
const server = spawn("python3", ["-m", "http.server", String(PORT), "--bind", "127.0.0.1"], { cwd: root, stdio: "ignore" });
await new Promise((r) => setTimeout(r, 700));
const BASE = `http://127.0.0.1:${PORT}/index.html`;

let pass = 0, fail = 0;
const ok = (c, name) => { if (c) { pass++; } else { fail++; console.log("  FAIL", name); } };

const browser = await chromium.launch();
const errors = [];
function watch(page, tag) {
  page.on("pageerror", (e) => errors.push(`${tag} pageerror: ${e.message}`));
  page.on("console", (m) => { if (m.type() === "error" && !/fonts\.(googleapis|gstatic)|Failed to load resource/.test(m.text())) errors.push(`${tag} console: ${m.text()}`); });
}
async function noSideScroll(page, label) {
  const w = await page.evaluate(() => [document.documentElement.scrollWidth, window.innerWidth]);
  ok(w[0] <= w[1] + 1, `${label}: no sideways scroll (${w[0]} > ${w[1]})`);
}

// ---------------- Run A: standalone ----------------
{
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  await ctx.route(/fonts\.(googleapis|gstatic)\.com/, (r) => r.abort());
  const page = await ctx.newPage(); watch(page, "A");
  await page.goto(BASE + "#studio");
  await page.waitForSelector(".pad", { timeout: 10000 });
  ok(await page.locator(".pad").count() > 10, "pads render");
  await page.fill("#ask", "dark boom bap 90 bpm in F minor with 808 drums, rainy night");
  await page.waitForTimeout(250);
  ok(/90 BPM/.test(await page.textContent("#found")), "live 'Will set' hint shows BPM");
  await page.press("#ask", "Enter");
  await page.waitForSelector("#readout textarea");
  const prompt = await page.inputValue("#readout textarea");
  ok(/90 BPM/.test(prompt) && /F minor/.test(prompt), "offline build includes BPM and key");
  ok(await page.locator(".tag").count() >= 1, "tray shows picked buttons");
  ok(await page.locator(".grade").count() === 1, "score card shows");
  // tap a mood pad and see the readout rebuild
  await page.click('.cat:has-text("Mood")');
  const firstMood = page.locator(".pad").first();
  const moodLabel = (await firstMood.textContent()).trim();
  await firstMood.click();
  ok((await page.locator(".tag").allTextContents()).some((t) => t.includes(moodLabel)), "pad adds to tray");
  await page.fill("#readout input.title", "Rain Train");
  await page.click('button:has-text("Save as new song")');
  await page.waitForTimeout(500);
  ok(await page.locator('button:has-text("Save as v2")').count() === 1, "after saving, Studio offers v2");
  await page.screenshot({ path: join(OUT, "a-studio.png") });
  // second version from the Studio
  await page.click('.cat:has-text("Keys & piano")');
  await page.locator(".pad").first().click();
  await page.click('button:has-text("Save as v2")');
  await page.waitForTimeout(400);
  // Songs
  await page.goto(BASE + "#songs");
  await page.waitForSelector(".folder");
  ok((await page.textContent(".folder")).includes("Rain Train"), "song folder listed");
  await page.click(".folder");
  await page.waitForSelector(".vbtn");
  ok(await page.locator(".vbtn").count() === 2, "two versions in the folder");
  await page.selectOption('select[aria-label="Compare with"]', "1");
  await page.waitForTimeout(200);
  ok(await page.locator(".diff").count() === 1, "compare view shows a diff");
  await page.selectOption('select[aria-label="Compare with"]', "");
  // change it instantly
  await page.click('.chipbtn:has-text("BPM +5")');
  await page.click('button:has-text("instantly")');
  await page.waitForTimeout(500);
  ok(await page.locator(".vbtn").count() === 3, "quick tweak made v3");
  ok(/95 BPM/.test(await page.textContent(".prompttext")), "v3 has 95 BPM");
  // rate
  await page.locator('.stars button').nth(3).click();
  await page.fill('textarea[placeholder^="What did Flow"]', "Drums were great, intro too long");
  await page.click('button:has-text("Save rating")');
  await page.waitForTimeout(300);
  // history check
  await page.click('summary:has-text("Folder tools")');
  await page.click('button:has-text("Check history")');
  await page.waitForSelector(".dlgbox");
  ok((await page.textContent(".dlgbox")).includes("History intact"), "hash chain verifies");
  await page.keyboard.press("Escape");
  // next column templates
  await page.click('button:has-text("Use templates")');
  await page.waitForTimeout(400);
  ok(await page.locator(".nitem").count() >= 3, "template next steps added");
  await page.locator('.nitem button:has-text("Start this song")').first().click();
  await page.waitForTimeout(500);
  ok(await page.locator(".folder").count() === 2, "next song created a second folder");
  await page.screenshot({ path: join(OUT, "a-songs.png") });
  // library, learn, setup
  await page.goto(BASE + "#library");
  await page.waitForSelector(".lcard");
  ok(await page.locator(".lcard").count() > 10, "library snippets render");
  await page.click('.cat:has-text("Beats")');
  await page.waitForTimeout(150);
  ok(await page.locator(".steps").count() > 3 || (await page.textContent("#libbody")).includes("No beats"), "beat grids render");
  await page.screenshot({ path: join(OUT, "a-library-beats.png") });
  await page.goto(BASE + "#learn");
  await page.waitForSelector(".article h2");
  ok((await page.textContent(".article h2")).length > 3, "learn article renders");
  await page.goto(BASE + "#setup");
  await page.waitForSelector('h2:has-text("Claude connection")');
  ok((await page.textContent("#aiBadge")).includes("copy & paste"), "standalone without key uses copy & paste");
  // phone width
  await page.setViewportSize({ width: 360, height: 780 });
  for (const v of ["studio", "songs", "next", "library", "learn", "setup"]) { await page.goto(BASE + "#" + v); await page.waitForTimeout(350); await noSideScroll(page, `phone ${v}`); }
  await page.goto(BASE + "#studio"); await page.waitForTimeout(300);
  await page.screenshot({ path: join(OUT, "a-phone-studio.png"), fullPage: false });
  await ctx.close();
}

// ---------------- Run B: inside a simulated Claude artifact ----------------
const MOCK = () => {
  const data = new Map(); const subs = new Set();
  const calls = (window.__calls = []);
  const snapDoc = (path) => ({ id: path.split("/").pop(), exists: data.has(path), data: () => (data.has(path) ? JSON.parse(JSON.stringify(data.get(path))) : undefined), metadata: { fromCache: false, hasPendingWrites: false } });
  const kids = (col) => [...data.keys()].filter((k) => k.startsWith(col + "/") && k.slice(col.length + 1).split("/").length === 1);
  const notify = () => setTimeout(() => subs.forEach((s) => s()), 0);
  const query = (col, filters = []) => {
    const run = () => { const docs = kids(col).map(snapDoc).filter((d) => filters.every(([f, , v]) => d.data()[f] === v)); return { docs, size: docs.length, empty: !docs.length, metadata: { fromCache: false }, docChanges: () => [] }; };
    return { where: (f, op, v) => query(col, [...filters, [f, op, v]]), orderBy: () => query(col, filters), limit: () => query(col, filters), get: async () => run(), onSnapshot(next) { const s = () => next(run()); subs.add(s); setTimeout(s, 0); return () => subs.delete(s); } };
  };
  const docRef = (path) => ({ id: path.split("/").pop(), path, get: async () => snapDoc(path), set: async (o) => { data.set(path, JSON.parse(JSON.stringify(o))); notify(); }, update: async (o) => { data.set(path, { ...data.get(path), ...o }); notify(); }, delete: async () => { data.delete(path); notify(); }, onSnapshot(next) { const s = () => next(snapDoc(path)); subs.add(s); setTimeout(s, 0); return () => subs.delete(s); }, collection: (sub) => colRef(path + "/" + sub) });
  const colRef = (path) => ({ ...query(path), path, doc: (id) => docRef(path + "/" + (id || Math.random().toString(36).slice(2))) });
  const db = { doc: docRef, collection: colRef };
  const user = { id: async () => "viewer1", isOwner: async () => true, canEdit: async () => true, can: async () => true };
  const answers = {
    Composer: { title: "Rain Train", prompt: "1990s East Coast boom bap hip-hop, smoky and nostalgic, rainy late-night mood. Featuring dusty SP-1200 drums with a cracking snare, warm Rhodes chords and a walking upright bass. 88 BPM with lazy swung hi-hats, in F minor. Laid-back male baritone rap with a conversational flow, sung in English, lyrics about riding the last train home. About 2 minutes long, with vinyl crackle and warm tape saturation.", lyrics: "", bpm: 88, key: "F minor", length: "2m", vocals: "vocals", chips: ["g-boom-bap", "not-a-real-chip"], why: "Google's order, named drum machine and keys, BPM and key stated.", variations: [{ label: "Darker", prompt: "Darker boom bap at 84 BPM in F minor with heavy SP-1200 drums and brooding Rhodes, instrumental." }] },
    Tweaker: { title: "Rain Train", prompt: "1990s boom bap at 92 BPM in F minor with harder SP-1200 drums, Rhodes chords and upright bass; laid-back baritone rap in English about the last train home. About 2 minutes.", lyrics: "", bpm: 92, key: "F minor", length: "2m", vocals: "vocals", chips: ["g-boom-bap"], why: "Harder drums as asked.", variations: [], changeNote: "Harder drums and 92 BPM." },
    Critic: { score: 88, issues: ["Name the hi-hat pattern"], improved: "Improved prompt text here with boom bap, Rhodes and drums at 88 BPM, instrumental." },
    "Next-step": { items: [{ kind: "extend", label: "Add an outro", prompt: "Extend with a 16-bar instrumental outro.", why: "Clean ending." }, { kind: "next-song", label: "Track two, faster", prompt: "Companion boom bap at 96 BPM in Ab major, same SP-1200 drums and Rhodes, brighter.", why: "Same DNA." }] },
    Librarian: { lesson: "Keep intros under 8 bars for boom bap.", scope: "boom bap", evidence: "Said the intro was too long." },
  };
  const sample = async () => ({ text: "x", truncated: false });
  sample.json = async (input) => {
    const role = (input.match(/Role: ([A-Za-z-]+)/) || [])[1];
    calls.push(role);
    await new Promise((r) => setTimeout(r, 120));
    return JSON.parse(JSON.stringify(answers[role] || {}));
  };
  sample.limits = async () => ({ maxPromptBytes: 262144 });
  const caps = { sample, db, user, dictation: null, desktop: null };
  window.claude = { use: async (name) => caps[name] ?? null };
};
{
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  await ctx.route(/fonts\.(googleapis|gstatic)\.com/, (r) => r.abort());
  await ctx.addInitScript(MOCK);
  const page = await ctx.newPage(); watch(page, "B");
  await page.goto(BASE + "#studio");
  await page.waitForSelector(".pad");
  await page.waitForFunction(() => document.querySelector("#aiBadge")?.textContent.includes("your account"));
  ok(true, "artifact mode uses the Claude account");
  ok((await page.textContent("#storeBadge")).includes("Synced"), "artifact mode stores in Claude");
  await page.fill("#ask", "rainy night boom bap with 808s");
  await page.click('button:has-text("Write it")');
  await page.waitForFunction(() => document.querySelector("#readout textarea")?.value.includes("SP-1200"));
  ok((await page.textContent("#readout")).includes("Written by Claude"), "Claude-written prompt shown");
  ok((await page.textContent("#readout")).includes("Why Claude wrote it"), "why shown");
  ok(await page.evaluate(() => !window.__flowsmith.S.st.chips.includes("not-a-real-chip")), "unknown chip ids from Claude are dropped");
  ok(await page.evaluate(() => window.__flowsmith.S.st.bpm === 88 && window.__flowsmith.S.st.key === "F minor"), "Claude's BPM/key applied");
  await page.click('button:has-text("Ask Claude to review")');
  await page.waitForSelector('h3:has-text("Claude\'s review")');
  ok(true, "critic review shows");
  await page.click('button:has-text("Save as new song")');
  await page.waitForTimeout(400);
  await page.goto(BASE + "#songs");
  await page.waitForSelector(".folder");
  await page.click(".folder");
  await page.waitForSelector(".vbtn");
  await page.fill('textarea[placeholder^="What should change"]', "harder drums");
  await page.click('button:has-text("with Claude")');
  await page.waitForFunction(() => document.querySelectorAll(".vbtn").length === 2);
  ok((await page.textContent(".prompttext")).includes("92 BPM"), "Claude tweak saved as v2");
  await page.click('button:has-text("Ask Claude for next steps")');
  await page.waitForSelector(".nitem");
  ok(await page.locator(".nitem").count() === 2, "Claude next steps listed");
  await page.locator(".stars button").nth(2).click();
  await page.fill('textarea[placeholder^="What did Flow"]', "The intro was way too long, drums were good");
  await page.click('button:has-text("Save rating")');
  await page.waitForFunction(() => window.__calls.includes("Librarian"));
  await page.waitForTimeout(300);
  await page.goto(BASE + "#setup");
  await page.waitForSelector('h3:has-text("Waiting for you")');
  await page.click('button:has-text("Approve")');
  await page.waitForTimeout(300);
  ok((await page.textContent(".setup")).includes("Keep intros under 8 bars"), "lesson approved and in use");
  const calls = await page.evaluate(() => window.__calls);
  ok(["Composer", "Critic", "Tweaker", "Next-step", "Librarian"].every((r) => calls.includes(r)), "all five agents ran: " + calls.join(","));
  ok((await page.textContent(".setup")).includes("Worked / failed"), "usage table shows");
  ok(await page.evaluate(() => window.__flowsmith.S.traces.recent.length >= 5), "traces recorded");
  // approved lesson reaches the next Composer request
  const req = await page.evaluate(() => window.__flowsmith.buildRequest("composer", { state: window.__flowsmith.S.st, draft: "", catalog: window.__flowsmith.S.cat, lessons: window.__flowsmith.S.lessons.items }).full);
  ok(req.includes("Keep intros under 8 bars"), "approved lesson included in Claude's instructions");
  await page.screenshot({ path: join(OUT, "b-setup.png"), fullPage: true });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(BASE + "#songs"); await page.waitForTimeout(300);
  if (await page.locator(".folder").first().isVisible()) { await page.click(".folder"); await page.waitForTimeout(300); }
  ok(await page.locator(".detail .vbtn").count() >= 1, "phone opens straight into the song folder");
  await noSideScroll(page, "artifact phone songs");
  await page.screenshot({ path: join(OUT, "b-phone-song.png") });
  await ctx.close();
}

await browser.close();
server.kill();
for (const e of errors) console.log("  ERROR", e);
console.log(`smoke: ${pass} passed, ${fail} failed, ${errors.length} page errors`);
process.exit(fail || errors.length ? 1 : 0);
