# Credits and rights

Every asset must allow commercial use in app stores. ⚠️ = needs the owner's action before release.

| Asset | Source | License / rights | Status |
|---|---|---|---|
| Glyph art (10 lineups, 90+ aliens) | Drawn as SVG for this game (AI-assisted) | Original work of the game | ✅ |
| Music (12 songs) and sound effects | Synthesized in code at play time (`src/audio/`) | Original work of the game | ✅ |
| **Six space backdrops** (`public/space/`, originals in `assets/original/space/`) | Came with the original "Alien Glyph Sudoku" prototype; source unknown. They look generated rather than NASA/ESA photographs | **Unclear** | ⚠️ Confirm where they came from and that commercial use is allowed, or replace them with images we know are free to use (Claude can do either) |
| HD versions of the backdrops | Upscaled with Real-ESRGAN x4plus (BSD-3-Clause model, Xintao Wang et al.) | Same rights as the originals | depends on the row above |
| Fonts: Orbitron, Space Grotesk, Audiowide, Black Ops One, Bungee, Cinzel, Creepster, Exo 2, Fredoka, Quicksand | Google Fonts via Fontsource | SIL Open Font License 1.1 | ✅ (credit in Settings → About) |
| App icon, store graphics | Made from the game's own glyphs and backdrops | Same as their sources | depends on the backdrops |
| Capacitor, Electron, Vite and the other libraries | Open source | MIT / Apache-2.0 / BSD | ✅ |
| Sentry SDK | Sentry | MIT | ✅ |
| Firebase Crashlytics and Remote Config SDKs, Capawesome plugins | Google, Capawesome | Apache-2.0 / MIT | ✅ |
| Google Mobile Ads SDK, UMP | Google | Google's SDK terms | ✅ |

To do in the game: Settings → About lists only two fonts today; expand it to all ten and the
backdrop credit once their source is known.
