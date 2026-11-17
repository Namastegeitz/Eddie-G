# 05 · PC edition (Windows, macOS, Linux)

The desktop app used by Steam, GOG, Microsoft Store, Epic and itch.io downloads.
It's an Electron app that opens the game full screen and offline, as the **PC
edition**: no Shop and no purchases; every skin and item is earned by playing.

- F11 or Alt+Enter: full screen. Esc: pause (in game).
- Keyboard: Q W E / A S D (or 7 8 9 / 4 5 6), mouse clicks, or the buttons.
- Saves live in the app's own storage on the computer (no account, no internet).

## Build

Needs Node.js 18+ on the computer you build on.

```
cd apps/monkey-see-monkey-do
node scripts/build_web.mjs          # build the game
cd release/05-desktop
npm install
npm start                           # try it in a window
npm run build:win                   # Windows installer + zip   (run on Windows)
npm run build:mac                   # macOS .dmg + zip          (run on a Mac)
npm run build:linux                 # AppImage + tar.gz
npm run build:steam                 # unpacked folders for Steam / GOG depots
```

Output goes to `dist/` (not committed). Builds for a system are best made on
that system, especially for signing.

Why not built here: the Electron download comes from github.com release files,
which this cloud project can't reach. Allowing `github.com` and
`objects.githubusercontent.com` in the project's environment would let Claude
build the Linux and Windows versions here.

## Signing

- **macOS:** required. Developer ID certificate + notarization (uses the $99 Apple
  account). Add `"mac": { "notarize": true }` and set `APPLE_ID`,
  `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` when building.
- **Windows:** optional. Unsigned installers show a SmartScreen warning when
  downloaded directly; Steam and GOG installs mostly avoid it, and the Microsoft
  Store signs packages for you.

## Files

| File | What |
|---|---|
| package.json | app name, version, build targets |
| main.js | the window: size, full screen keys, links open in the browser |
| scripts/copy-app.mjs | copies the game's web build into app/ |
| build/icon.png | 1024 px icon (rendered from the game's icon) |
