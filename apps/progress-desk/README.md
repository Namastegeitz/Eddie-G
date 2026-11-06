# Progress Desk

A single-page dashboard and conversational agent covering the whole Eddie-G
portfolio: everything built, who can actually open it, what each app reports
back, and what to do next.

**Published page:** https://claude.ai/artifact/KxjAMcpniJhvg54EfDapaU

## Why it exists

It answers one question with evidence instead of a guess: *is anyone playing or
using my links?* The answer, as of 2026-11-05, is no — 41 of 42 artifacts are
owner-only, the 42nd exposes no counter, and not one of the five apps sends a
usage event anywhere.

## Layout

```
portfolio.json   the dataset - sharing state of all 42 artifacts, the five apps,
                 the telemetry audit, distribution surfaces, the ranked plan
index.html       the page template, with a __PORTFOLIO_JSON__ placeholder
build.mjs        injects portfolio.json into the template
dist/index.html  the generated single file that gets published
```

## Rebuilding

```
node apps/progress-desk/build.mjs
```

Then republish `dist/index.html` to the artifact above with `publish_files`
(slug `998c62d4-7ed7-4170-ad2a-a6e079257199`), passing the current
`base_version`.

Edit `portfolio.json` — never `dist/index.html` — and rebuild. The build fails
loudly if the placeholder is missing or if the JSON would break out of its
`<script>` tag.

## The agent

The "Ask the agent" tab uses the artifact `sample` capability
(`claude.use("sample")`), declared on the artifact as `{"sample": {}}`. Every
question is sent with the full snapshot plus the last 12 turns of the
conversation, so it answers from verified data rather than memory. It is briefed
never to invent player counts, downloads or revenue, and to repeat the
`honest_caveats` rather than resolve them.

The capability only resolves when the page is opened from its claude.ai link. As
a local file the chat says so plainly; every other tab works offline.

Conversation history is kept in `localStorage` on that one device, capped at 24
messages, and cleared with the button under the composer.

## Checks

The page was rendered in Chromium at 1180x900 and 390x844 and verified: tab
routing, 4 stat tiles, 4 ladder rungs, 5 telemetry rows, 42 link rows, the
sharing and kind filters, 5 chart bars with hover tooltips, 6 plan rows, the
agent composer and its offline fallback, the dark toggle, no horizontal overflow
on a phone, and a clean console. 20 checks, all passing.
