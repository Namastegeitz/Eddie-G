# 01 · Web beta (any phone, tablet or computer)

**Link for testers:** https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/
(the game itself: https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/play/)

It is live. GitHub Pages serves the `gh-pages` branch: its root is the Off-Grid
Survival Kit, and this game has its own `monkey-see-monkey-do/` folder there.
Nothing to switch on.

| File | What |
|---|---|
| qr.png | QR code that opens the game (scan with a phone camera) |
| monkey-see-monkey-do-web.zip | the same web build, to host anywhere else (Netlify, Cloudflare Pages, your own site) |
| ../../dist/site | the beta website as published: landing page, privacy, support, the game in `play/` |

## How it stays up to date

`node scripts/build_web.mjs` builds the game and the beta website
(`dist/site`, via `scripts/publish_beta.mjs`). `bash scripts/deploy_beta.sh`
puts it in the `monkey-see-monkey-do/` folder of `gh-pages` and pushes; the
beta link shows the new version about a minute later. It never touches the
Off-Grid Survival Kit's files. Testers' saved progress carries over.

## Testers' bug reports

Reports go to the **Monkey Do Bug & Feedback** page in your MONKEY SEE, MONKEY DO
folder on claude.ai. Invite testers there by email (Share > Editor). Claude
reads the reports and fixes the minor bugs.
