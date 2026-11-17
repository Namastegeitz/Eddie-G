# macOS: ✅ Built (unsigned)

## What's here
- `files/AlienSudoku-1.0.0-mac-x64.zip` (Intel) and `files/AlienSudoku-1.0.0-mac-arm64.zip` (Apple Silicon).
- Not signed or notarized, so macOS blocks them until you right-click > Open. Fine for testing, not for stores.

## How to build it
```bash
cd ALIEN-SUDOKU/game && npm run build
cd desktop && npm install && npx electron-builder --mac zip --x64 --arm64
```
A universal build, signing and notarization need a Mac and your Apple Developer account (checklist: **Sign and notarize the Mac desktop build**).

## What the store needs
- Steam requires notarized Mac builds.

Live status: the **Launch checklist** in [`../../README.md`](../../README.md) and the Launch Control page.
