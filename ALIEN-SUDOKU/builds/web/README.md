# Web (browser): ✅ Built

## What's here
- `AlienSudoku.html`: the whole game in one file (4.4 MB, with the high-definition backdrops). Double-click to play offline in any browser; this is also what the claude.ai artifact and the shareable githack link serve.
- `music-lab/`: the Music Lab page and its MP3 samples (the theme songs, Cadet Mixtape included).

Shareable link for version 1.2.0 (pinned to its commit): https://rawcdn.githack.com/Namastegeitz/Eddie-G/4910aa93116cd52e073d410774a4138e64e6011d/ALIEN-SUDOKU/builds/web/AlienSudoku.html

## How to build it
```bash
cd ALIEN-SUDOKU/game
node tools/package-artifact.mjs /tmp/out && cp /tmp/out/AlienSudoku.html ../builds/web/AlienSudoku.html
npm run build        # the installable web app (PWA) in game/dist/, for a public website
```

## What the store needs
- Public website (GitHub Pages, Netlify): host `game/dist/` with the privacy policy, support page and `app-ads.txt` at the site root (checklist: **Publish a site: privacy, support, press and play**).
- Web game portals (CrazyGames, Poki) need their own ads SDK: see `store-launch/pc-and-web-stores.md`.

Live status: the **Launch checklist** in [`../../README.md`](../../README.md) and the Launch Control page.
