# FLOWSMITH: Claude Code build prompt

Copy everything in the box below into a new Claude Code session on the `Eddie-G` repo.
If `apps/flowsmith/` already exists, the prompt tells Claude to read it, run the tests, and upgrade
instead of starting over.

````text
You are building FLOWSMITH in my Eddie-G repo: a prompt studio + dashboard that helps me write
better prompts for Google Flow Music (Google Labs' AI music studio), with Claude doing the
prompt engineering. Work in apps/flowsmith/. Keep me posted as you go (rules at the bottom).

IF apps/flowsmith/ ALREADY EXISTS: read apps/flowsmith/CLAUDE.md, run `npm test` and
`npm run smoke` there, tell me what passes, then do only the "Next upgrades" section at the end.

──────────────────────────── 1. WHAT FLOW MUSIC IS (researched Nov 2026) ────────────────────────────
- Google Flow Music = Google Labs' AI music studio at flowmusic.app (web, iPhone/iPad, Android).
  It came from Riffusion → Producer.ai (Aug 2025) → acquired by Google (Feb 2026) → relaunched as
  Flow Music (Apr 2026). Runs DeepMind's Lyria 3.5 since Jul 29 2026. Songs up to ~3 minutes with
  vocals + lyrics, or instrumentals. Text, image and audio prompts; upload your own beats.
- Editing: Compose (change lyrics, sound, details); remix a section with Extend, Cover (restyle,
  keep the melody) or Replace section. Google's own section-edit examples: "Shorten the intro to
  4 bars", "Add a bridge before the final chorus". Spaces = build-your-own tools by describing
  them; stem splitting; Spaces export as VST3/AU plugins (Oct 2026). SynthID + C2PA on all output.
- Google's prompt order (Lyria 3 Pro guide): [Genre & style] + [Mood] + [Instrumentation] +
  [Tempo & rhythm] + [Vocal style & language] + [Lyrics]. Be specific (vague → generic): name era,
  instruments with tone and role, BPM and key. Write "instrumental" for no vocals.
- NO negative prompts in Lyria: never "no drums"; say what to include.
- Lyrics: a block starting "Lyrics:" with [Intro] [Verse 1] [Pre-Chorus] [Chorus] [Bridge] [Outro]
  tags, kept apart from production notes. Timestamp lines "[00:00] ..." can script the arrangement.
- Vocal languages: English, German, Spanish, French, Hindi, Japanese, Korean, Portuguese.
  Describe voices by gender, range, timbre, delivery.
- House rule for my app: never name artists, bands, producers or songs (describe the sound; gear
  names like TR-808 are fine); only original lyrics.
- Pricing/credits differ between sources: tell me to check flowmusic.app, don't hard-code numbers.
Sources: cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-lyria-3-pro,
ai.google.dev/gemini-api/docs/lyria-prompt-guide, ai.google.dev/gemini-api/docs/music-generation,
support.google.com/flow/answer/17084348, blog.google (Lyria 3.5, Flow Music plugins, Believe).
Re-check these with web search at the start; if anything changed, update the app's Flow guide.

──────────────────────────── 2. WHAT I WANT (the product) ────────────────────────────
Usable on my computer, iPhone and Android. Six tabs:
1. STUDIO: a big search bar where I type a few words ("dark trap 140 bpm rainy night 808s female
   vocals") + a mic button. It pulls out BPM, key, length, language, vocals and lights matching
   buttons; the leftover words become the creative brief. Buttons ("pads") for EVERYTHING, grouped
   by Google's order: genre, era, use case, mood, energy, drums & drum machines (TR-808, TR-909,
   TR-505, TR-707, LinnDrum, SP-1200, MPC, breaks...), bass, synths, keys, guitars, orchestral,
   world instruments, tunings, groove, key/scale/mode, vocals, song structure, production & mix.
   BPM slider, key, length, vocals/instrumental, language, lyrics (theme / Claude writes / mine),
   prose vs labeled layout, timestamps toggle, extra notes. "Write it" = Claude writes the prompt;
   "Build" = instant offline build. Show a score card checking the prompt against Google's rules.
   Copy prompt (+ lyrics), Open Flow Music, Save.
2. SONGS: every prompt saves in ITS OWN FOLDER. Every change is a new version in that folder
   (v1, v2, v3...). Tune, change, add, subtract from any version: quick tweaks (BPM ±5, key up/down,
   relative key, darker, brighter, strip back, half/double time, instrumental/vocals, longer/shorter)
   + "what should change?" box → new version with Claude or instantly. Compare any two versions
   (word diff + buttons added/removed). Rate what Flow made (stars, notes, Flow link). Rename,
   copy to new folder, delete (with confirm), check history (hash chain).
3. NEXT: the separate column of ADDITIVE prompts per song: Flow edit moves for this song
   (compose, extend, cover, replace section) and full prompts for the next songs in the series that
   keep the sonic DNA. "Start this song" creates a new folder linked to the parent.
4. LIBRARY: copy-paste folder of prompts per instrument, per drum machine, per tuning, per beat
   (drum patterns drawn as step grids), genre recipes (full ready prompts), Flow edit moves with
   {placeholders} filled from the open song, and my own saved snippets.
5. LEARN: everything about music (theory, scales, modes, chords, progressions, rhythm, tempo by
   genre, instruments, synthesis, drum machines, beats, mixing, songwriting, genres, glossary) and
   a Flow Music guide (workflow, formula, lyrics, timestamps, editing, rules, troubleshooting,
   prompting a series, plans/rights, sources). Every lesson ends with a Flow tip + copyable prompt.
6. SETUP: how Claude is connected, quality, daily call limit, lessons (approve/reject), usage and a
   status light, backup/restore, install.

──────────────────────────── 3. HOW TO BUILD IT ────────────────────────────
One codebase, no build step: vanilla HTML/CSS/JS ES modules + JSON data. Runs two ways:
A) As a CLAUDE ARTIFACT (main way, connects to MY Claude): publish with the claude-artifacts tools
   (read its guide + describe_capabilities first) from files, then declare capabilities
   {sample:{}, db:{}, user:{}, dictation:{}, desktop:{}}.
   - Claude calls: `const sample = await claude.use("sample")`; `sample.json(fullText, {signal,
     cache:false, modelTier})`. It uses my own Claude account. No system prompt: put rules + data +
     JSON format in the input. Handle error codes (not_granted → fall back, rate_limited → tell me).
   - Folders: db per-person private subtree `data/users/<await user.id()>/<songId>`, versions in a
     `versions` subcollection; one write at a time per doc; 10 s load timer; handle empty db.
   - Mic: dictation capability (start() straight from the click). Desktop install button via
     desktop.install.state()/request().
   - Never use #settings as a hash (claude.ai reserves it); use #setup.
B) As a STANDALONE PWA (GitHub Pages / home screen): IndexedDB, service worker, manifest, icons.
   Claude via the OFFICIAL Anthropic SDK (@anthropic-ai/sdk bundled with esbuild into
   vendor/anthropic-sdk.mjs, loaded only in this mode, dangerouslyAllowBrowser with MY key kept in
   localStorage only, never synced or exported). Default model claude-opus-5-5, structured outputs
   (output_config.format json_schema), effort medium, server-side refusal fallback
   (betas ["server-side-fallback-2026-07-01"], fallbacks "default"; not for Haiku). Before writing
   SDK code, load the claude-api skill. Also a copy-and-paste mode (copy request → Claude app →
   paste answer) and an offline engine so it always works.
Design: a drum-machine faceplate. Pads with an LED, colour-coded red/orange/yellow/cream by prompt
slot; Archivo + Inter; light and dark; bottom nav on phones; 44 px targets; no sideways scroll at
360 px.

──────────────────────────── 4. AGENTS (apply my Eddie Agent Kernel skill) ────────────────────────────
Load the eddie-agent-kernel skill. Five agents, one job each, write their spec cards in
apps/flowsmith/CLAUDE.md:
- Composer (words + buttons → Flow prompt + optional original lyrics + 2 variations + chip ids)
- Tweaker (version + change request → next version + changeNote; keeps everything not asked)
- Critic (prompt + rubric → score, issues, improved prompt)
- Next-step writer (song → 2 compose, 1 extend, 1 cover, 2 replace, 3 next-song prompts)
- Librarian (rating + notes → one lesson → QUARANTINE; I approve before it's used)
Hand-off chain; buttons are the router (no LLM router). User text is fenced <<< >>> as data.
Only approved lessons go into prompts. Daily call cap (default 80), stop on the same request 3x in
a row, a trace per call (agent, backend, ok, ms, tokens/cost), status light computed from traces.
Versions are SHA-256 hash-chained receipts. Nothing posts, spends or deletes without my click.
Also write supabase/migrations/0001_flowsmith_bridge.sql (songs, versions append-only, directives,
quarantine, skills_ledger, traces, RLS per user) but DO NOT apply it without asking me.

──────────────────────────── 5. CONTENT ────────────────────────────
All content as JSON in data/ with data/SCHEMA.md and tests/validate-data.mjs (ids, word limits,
no negative words in prompt fragments, no artist names). Aim for 600+ buttons, 30 drum patterns
with step grids, 45+ genre recipes, 12+ tunings, 30+ Flow edit templates, 60+ lessons. Use
parallel subagents for content, each owning one file with a strict schema, each running the
validator until 0 errors.

──────────────────────────── 6. TESTS (block "done" until all pass) ────────────────────────────
- tests/engine.test.mjs: parsing (BPM, key, aliases like 808/505, longest phrase wins), Google
  order, instrumental logic, lyrics tags, timestamps, critic catches negatives/artists/conflicts,
  diff, hash chain + tamper detection, quick tweaks, next steps, JSON parsing, lessons fencing.
- tests/evals/cases.json (20 saved good requests) + run-engine-evals.mjs (free) +
  run-claude-evals.mjs (costs money: ask me before running).
- tests/smoke.mjs (Playwright, preinstalled Chromium): standalone run AND a run with a mocked
  window.claude (sample/db/user) covering write → save → tweak → compare → rate → lesson →
  approve → next steps; zero page errors; no sideways scroll at 360 px on every tab. Look at the
  screenshots yourself.

──────────────────────────── 7. PROMPT ME ALONG THE WAY ────────────────────────────
Work in phases. After EACH phase, write me 2-4 plain lines: what you just built, what it does
for me, what's next. No jargon. Phases:
 1 research check  2 data schema + validator  3 content (parallel)  4 engine + tests
 5 Claude agents + storage  6 screens  7 tests + screenshots  8 publish artifact + docs + push.
Commit on my working branch after each phase and push (git push -u origin <branch>). Update
apps/flowsmith/README.md, the root README.md table and STATUS.md. Ask me before: spending money
(API evals), creating cloud projects (Supabase), or making anything public.

──────────────────────────── 8. NEXT UPGRADES (only if the app already exists) ────────────────────────────
Pick up to three, tell me which and why first:
- Beat grids that PLAY (Web Audio) so I can hear a pattern before prompting it.
- "Image to prompt": attach a photo; Claude describes the vibe as a Flow prompt (sample images).
- A FLOWSMITH MCP server so my other agents (Resonara, Mountain Lion) can read songs and lessons.
- Supabase sync for the standalone app (apply the migration after I say yes).
- Album/EP view: series of linked folders with a shared "sonic DNA" card.
````
