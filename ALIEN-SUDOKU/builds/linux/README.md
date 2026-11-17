# Linux: ✅ Built

## What's here
- `files/AlienSudoku-1.0.0-linux-x86_64.AppImage`: runs on most distributions.
- `files/AlienSudoku-1.0.0-linux-amd64.deb`: installer for Debian and Ubuntu.

## How to build it
```bash
cd ALIEN-SUDOKU/game && npm run build
cd desktop && npm install && npm run dist:linux
```

## What the store needs
- For Steam, upload a plain folder build (`npx electron-builder --linux dir`) and launch it with `--no-sandbox`. See the Steam tasks.

Live status: the **Launch checklist** in [`../../README.md`](../../README.md) and the Launch Control page.
