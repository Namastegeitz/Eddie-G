# itch.io (and other HTML5 stores): ✅ Built

## What's here
- `alien-sudoku-html5.zip`: one `index.html`, no service worker. Upload as **"This file will be played in the browser"**. Suggested embed size 1280×800, with the fullscreen button on.
- Desktop downloads for itch.io are the files in `../windows`, `../macos` and `../linux`.

## How to build it
```bash
cd ALIEN-SUDOKU/builds/itch-io
mkdir pkg && cp ../web/AlienSudoku.html pkg/index.html && (cd pkg && zip -9 ../alien-sudoku-html5.zip index.html) && rm -r pkg
```
Uploads with the `butler` command line tool must run on your own computer (itch.io is blocked from this cloud workspace).

## What the store needs
- itch.io account, payout settings, AI disclosure on the page (see the itch.io tasks in the checklist).

Live status: the **Launch checklist** in [`../../README.md`](../../README.md) and the Launch Control page.
