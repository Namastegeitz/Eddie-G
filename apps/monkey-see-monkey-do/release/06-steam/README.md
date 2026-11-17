# 06 · Steam

Cost: **$100 per game** (Steam Direct), then a **30-day wait** before release.
In-game purchases on Steam must use Steam's own payment system, so Steam gets
the **PC edition** (no Shop): sell it at a one-time price instead.

## Art (all exact sizes, in `art/`)

| Asset | Size | File |
|---|---|---|
| Header capsule | 920x430 | header-capsule-920x430.png |
| Small capsule | 462x174 | small-capsule-462x174.png |
| Main capsule | 1232x706 | main-capsule-1232x706.png |
| Vertical capsule | 748x896 | vertical-capsule-748x896.png |
| Library capsule | 600x900 | library-capsule-600x900.png |
| Library header | 920x430 | library-header-920x430.png |
| Library hero (no text) | 3840x1240 | library-hero-3840x1240.jpg |
| Library logo (transparent) | 1280x720 | library-logo-1280x720.png |
| Page background | 1438x810 | page-background-1438x810.jpg |
| Screenshots (5+) | 1920x1080 | ../00-shared/screenshots/desktop-1080p |

Steam rejects images that are even one pixel off; these are rendered at exact
size by `node scripts/make_store_art.cjs steam`.

## Steps

1. Join Steamworks (partner.steamgames.com): identity, tax, bank.
2. Pay the Steam Direct fee (Admin users only). The 30 days start now.
3. Store page: paste `steam-short` and `steam-about` from ../00-shared/store-text.md;
   tags Rhythm, Music, Casual, Family Friendly, Memory, Cute, Singleplayer;
   upload art, 5+ screenshots and the trailer; content survey (no mature content).
4. Turn on **Coming soon** early to collect wishlists.
5. Build: `npm run build:steam` in ../05-desktop gives unpacked folders.
   Depots: one per OS (Windows, macOS, Linux). Upload with the SDK's
   `tools/ContentBuilder` (steamcmd) or the web uploader for small builds.
   Launch option (Windows): `Monkey See, Monkey Do.exe`.
6. Test from a beta branch in your own Steam library.
7. Request build review; once approved and 30 days have passed, Release.

## Optional later

Steam achievements and Steam Deck verification need the Steamworks SDK
(for Electron: the `steamworks.js` package). Claude can add these when you want.
