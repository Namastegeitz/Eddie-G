# 02 · itch.io (free to publish, plays in the browser)

**Build:** `monkey-see-monkey-do-html5.zip` (PC edition: no Shop; ~0.4 MB, 15 files)
Rebuild: `node scripts/build_web.mjs && node scripts/build_release.mjs`

## Upload, step by step

1. itch.io > Dashboard > **Create new project**.
2. Title: Monkey See, Monkey Do. Kind of project: **HTML**.
3. Uploads: add the zip, tick **This file will be played in the browser**.
4. Embed options:
   - Viewport: 390 x 844 (phone-shaped); tick **Mobile friendly** (orientation: portrait).
   - Tick **Fullscreen button** and **Click to launch in fullscreen** (best on phones).
5. Text: paste `itch-tagline` and `itch-description` from ../00-shared/store-text.md.
6. Cover image: ../00-shared/art/itch-cover-630x500.png. Screenshots: ../00-shared/screenshots/desktop-1080p.
7. Pricing: **$0 or donate** (pay-what-you-want) suggested.
8. Genre: Rhythm. Tags: rhythm, memory, music, casual, family, dance, cute, 3D.
9. Save as draft, open the page, play a level, then set Visibility to **Public**.

## Limits (well within)

500 MB unpacked, 200 MB per file, 1000 files. Ours: 0.4 MB, 15 files.

## Desktop downloads (optional)

Upload the installers from release/05-desktop/dist too, and players can
choose browser or download. The `butler` tool updates them from the command line.
