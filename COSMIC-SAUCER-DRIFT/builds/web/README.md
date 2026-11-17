# Web build

`index.html` plus the engine (`index.wasm`), the game data (`index.pck`) and helpers.
Built with Godot's no-threads web template, so it needs no special server headers.

- **Play it:** your private Claude page (link in the checklist) runs this build.
- **itch.io:** zip the *contents* of this folder (not the folder itself) and upload as an
  HTML5 game. Set the viewport to 1280 × 720 and tick "Mobile friendly" and "Fullscreen button".
- **Any static host** (GitHub Pages, Netlify): upload the folder as is.
