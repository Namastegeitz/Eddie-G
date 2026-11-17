# 01 · Web beta (any phone, tablet or computer)

**Link for testers:** https://namastegeitz.github.io/Eddie-G/
(the game itself: https://namastegeitz.github.io/Eddie-G/monkey-see-monkey-do/)

It goes live once GitHub Pages is switched on (one time):
Settings > Pages > Deploy from a branch > `claude/nifty-lamport-bfm2ub`, folder `/docs`.
Direct link: https://github.com/Namastegeitz/Eddie-G/settings/pages

| File | What |
|---|---|
| qr.png | QR code that opens the game (scan with a phone camera) |
| monkey-see-monkey-do-web.zip | the same web build, to host anywhere else (Netlify, Cloudflare Pages, your own site) |
| /docs (repository root) | what GitHub Pages serves: landing page, privacy, support, the game |

## How it stays up to date

`node scripts/build_web.mjs` builds the game and copies it to `/docs`
(`scripts/publish_beta.mjs`). Commit and push, and the beta link shows the new
version a minute later. Testers' saved progress carries over.

## Testers' bug reports

Reports go to the **Monkey Do Bug & Feedback** page in your MONKEY SEE, MONKEY DO
folder on claude.ai. Invite testers there by email (Share > Editor). Claude
reads the reports and fixes the minor bugs.
