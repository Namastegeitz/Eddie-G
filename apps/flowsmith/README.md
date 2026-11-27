# FLOWSMITH

A prompt studio for **Google Flow Music**. Type a few words, tap pads (TR-808, TR-505, Rhodes,
Juno pad, moods, keys, grooves...), and Claude writes the Flow Music prompt in the order Google's
Lyria guide recommends. Every song gets its own folder of versions you can tune, add to, subtract
from and compare; a Next column writes the follow-up prompts; the Library holds copy-paste
snippets; Learn teaches the music theory and Flow Music itself.

Not made by or affiliated with Google.

## Ways to use it

| Where | How Claude is reached | Where songs are saved |
|---|---|---|
| **Claude artifact** (computer browser, Claude desktop app, Claude iPhone/Android app) | Your own Claude account (Claude asks you to allow it the first time) | Your Claude account, so the same folders appear on every device |
| **Standalone app** (open `index.html` from any static host, then Add to Home Screen) | Your Anthropic API key, or copy & paste with the Claude app | This device (back up / restore in Setup to move songs) |
| **Offline** | The built-in engine builds prompts from your buttons | This device |

## The tabs

- **Studio**: search bar + mic, BPM / key / length / vocals / language, 600+ sound pads in 18 groups,
  Write it (Claude) or Build (instant). Score card checks the prompt against Google's guidance.
- **Songs**: one folder per song; versions v1, v2, v3...; quick tweaks; "what should change?";
  compare two versions; rate what Flow made; history check (each version is fingerprinted).
- **Next**: additive prompts per song: Compose / Extend / Cover / Replace moves for Flow, and the
  next songs in the series ("Start this song" makes a linked folder).
- **Library**: snippets per instrument, drum machine, tuning, beat (step grids), genre recipes,
  Flow edit moves, your own snippets.
- **Learn**: theory, instruments, synths, drums, mixing, songwriting, genres, glossary, Flow guide.
- **Setup**: Claude connection, daily limit, lessons to approve, usage + status light, backup.

## Develop

```
npm install          # SDK + esbuild (only needed to rebuild vendor/ or run the Claude evals)
npm test             # data validator + engine tests + 20 eval cases (free)
npm run smoke        # Chromium: standalone + mocked Claude artifact, phone widths, screenshots
npm run vendor       # rebuild vendor/anthropic-sdk.mjs from @anthropic-ai/sdk
ANTHROPIC_API_KEY=... node tests/evals/run-claude-evals.mjs   # costs money; asks Claude 20 times
python3 -m http.server -d . 8000   # then open http://localhost:8000
```

Content lives in `data/*.json` (schema: `data/SCHEMA.md`). Agent spec cards and the kernel checklist:
`CLAUDE.md`. Build prompt: `../../prompts/claude/flowsmith.md`. Optional Supabase sync schema:
`supabase/migrations/0001_flowsmith_bridge.sql` (not applied).
