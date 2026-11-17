# Windows: ✅ Built (unsigned)

## What's here
- `files/AlienSudoku-1.1.0-win-x64.exe`: installer (NSIS).
- `files/AlienSudoku-1.1.0-win-portable.exe`: runs without installing.
- `files/` is not in git (about 100 MB each). It exists on the machine that built it; ask Claude to send the files.

## How to build it
```bash
cd ALIEN-SUDOKU/game && npm run build
cd desktop && npm install && npm run dist:win
```

## What the store needs
- Unsigned builds show a SmartScreen warning. Steam, GOG and Epic don't need your own signature; for direct downloads see the code-signing task. Microsoft Store wants an MSIX package, which must be built on a Windows PC.

Live status: the **Launch checklist** in [`../../README.md`](../../README.md) and the Launch Control page.
