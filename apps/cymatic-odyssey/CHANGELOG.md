# Changelog

Every phase appends: what was built, what is stubbed, what is untested, and what couldn't be verified.

## Phone app, store builds and public link (2026-11-27, ahead of P8 at Eddie's request)

Eddie asked to have the project on his phone, built for the iOS and Android app stores, with a public link that works on other phones and tablets, and a folder on his desktop. Audiorective (P1 add-on checkpoint): skipped, revisit only if needed later.

**Built**
- **The Voyage console now runs through the Safety Guardian.** `packages/core-safety` is bundled for the browser (`pnpm console:safety`, checked in CI with `--check`) and injected into `console/index.html`. Volume starts at −18 dBFS (slider max −6 dBFS), fades in over 2 s and out over 3 s (Stop) or 2 s (FADE ALL), a hard ceiling at −1 dBFS follows the limiter, two tones that beat at 3-60 Hz (drive or water beat) get the second tone at 10 % unless Lab mode is switched on behind a warning, pulses are capped at 3 per second, drive tones stay in 5-200 Hz, and the preview and style thumbnails carry a SIMULATION mark. A guard note under the controls says what the guard is doing. This resolves the console conflicts in ARCHITECTURE_NOW §6 (fade 0.4 s, limiter −6 dB, pulse 4/s, missing watermark); the water-beat styles still need re-tuning (P1/P2).
- Deep links into the console (`#style=S05`, `#show=genesis`): the style or show is set up, and audio still starts only when you press Start.
- **App hub** (`apps/web`): Home, Play (the console in a same-origin frame that keeps playing while you browse; FADE ALL reaches it), 30 styles with filters and a page each (wall, water and 3D-render pictures, signal with Setting/Estimated labels, parts, guard status), 15 shows with a page each (video preview, timeline with guarded steps), Build (manual, five models, all downloads, desktop-folder commands), Safety and science, Install and share (home-screen steps, share link, capability table). Hash routes, relative paths, offline service worker that never intercepts downloads, skipped inside the native apps.
- Media for phones (`apps/web/scripts/build_media.py`, 5.3 MB): every simulated picture has a burned-in SIMULATION badge, renders say 3D RENDER. New app icon (a drawn standing-wave lattice, not a picture of water), maskable icon, social preview card.
- Privacy policy and support pages (`/privacy/`, `/support/`), both scanned by the claims linter. The privacy policy says the app collects nothing; it should get a quick review before store submission.
- **Android and iOS apps** (`apps/mobile`, Capacitor 8.6.3, MIT): `com.eddieg.cymaticlightchamber` 1.0.0, Android target SDK 36, release signing from a git-ignored `keystore.properties`. Built here: a signed APK and Play bundle (AAB), signature verified with apksigner. New upload key generated and delivered to Eddie, never committed. iOS: Swift Package Manager project plus `codemagic.yaml` (repository root) that builds and uploads to TestFlight on a cloud Mac.
- Store kit (`store-launch/`): `STEP-BY-STEP.md` (phones today, Google Play G1-G7, App Store A1-A8), `LISTING.md` (names, descriptions, keywords, categories, privacy/data-safety and content-rating answers, review notes), screenshots from the real app at 1290 × 2796, 2064 × 2752 and 1080 × 1920, Play feature graphic and icons, all claims-linted.
- **Public link** on GitHub Pages (`gh-pages` branch, new `cymatic-light-chamber/` folder only, assembled by `store-launch/publish_site.py`): the app plus `files/` (manual, sourcing guide, all zips, 15 videos, the APK).
- **Desktop folder**: one command (Mac `get-desktop-folder.sh`, Windows `get-desktop-folder.ps1`) builds "Cymatic Light Chamber" on the Desktop with 51 files in six numbered folders; re-running fetches only what's missing. The Mac/Linux script was tested end to end against a local copy of the site.
- Tests: 47 Vitest tests (adds console wiring, app data and router tests: 12 guarded styles and 52 guarded show steps, every picture present), `tests/console_guard.cjs` (18 browser checks of the console's fades, beat guard, Lab mode, ceiling and FADE ALL; `pnpm console:check`), app screenshots at 390 × 844, 820 × 1180 and 1440 × 900 with no horizontal scrolling and no console errors.

**Stubbed**
- Native features (BLE, haptics, keep-awake, background audio, camera) are not in the apps yet (P8). The screen can sleep during a long show.

**Untested**
- The Android app on a real phone or emulator (built and signature-checked only). The iOS app has not been built (needs Codemagic's Mac and Eddie's Apple account).
- The Windows desktop-folder script (no PowerShell here). Real iPhone Safari and Android Chrome installs of the PWA.
- External links inside the native apps should open the system browser (Capacitor's default); not checked on devices.

**Couldn't verify**
- Store acceptance: nothing has been submitted (needs Eddie's accounts and his go-ahead).
- Maven Central rate-limits this container (HTTP 429); Android builds here use Google's Maven Central mirror through a machine-local Gradle init script, which is not part of the project.

## P0 - Audit & scaffold (2026-11-27)

**Built**
- `docs/ARCHITECTURE_NOW.md`: audit of the existing project (Python generator, console, styles/shows, Bambu/Blender/video tools), how STLs are made, what the spec can reuse, what's fragile, and the conflicts with the new rules.
- pnpm monorepo inside `apps/cymatic-odyssey/` (`apps/web`, `packages/*`), TypeScript base config, Vitest.
- `packages/core-safety`: Safety Guardian skeleton. Flicker guard (transition budget, ≥333 ms fades, stricter red), periodic-modulation clamp (3-60 Hz → 3 Hz), drive-tone beat guard (limit / shift / lab policies, plus a stricter check of the Faraday half-beat), audio limits (−18 dBFS master, ≥2 s / ≥3 s fades, −1 dBFS hard clip, frequency and binaural ranges), FADE ALL fan-out. 23 tests, including 400 randomized property sequences.
- `packages/content`: seeded claims register (21 claims, sources from spec §17), approved phrase bank, never-say list, and `pnpm claims:lint` (fails on hits; per-line allowlist with reasons). It passes on the current repo; a planted claim makes it fail.
- `packages/core-protocol`: v1 message types and envelope check. `packages/core-geometry`: legacy adapter that exposes the Python generator's 355 looks and 30 styles.
- `apps/web`: React 19 + Vite 8 PWA shell: startup safety notice, always-visible FADE ALL, six mode cards labelled with their phase, runtime capability check with device role, existing-library summary.
- `docs/TRANSPARENCY.md`, `docs/PLATFORM_LIMITS.md`, `docs/DEPENDENCIES.md` (generated by `tools/deps_report.py`), `requirements.txt`.
- CI: `.github/workflows/cymatic-light-chamber-ci.yml` runs the Python tests, a generator smoke test, type-check, Vitest, the claims linter and the web build.
- `tools/generate.py --no-package` so smoke runs can't overwrite the committed zips.

- **Manual v2** (`docs/CYMATIC_ODYSSEY_Manual.pdf`, 77 pages, about 18.6 MB, was 37 pages). Eddie asked for a more detailed, high-resolution manual. Adds a "how to read this manual" page, a contents page, a quick start, a wavelength chart, 7 assembly-step pages rendered in Blender from the real STLs (the parts added in each step are highlighted), Bambu Lab printing, an annotated console guide, one full page per style and per show (with the flicker-guard status of every style and show step), troubleshooting, a glossary and a file index. Every picture carries a burned-in mark: **SIMULATION**, **3D RENDER** or **REAL FOOTAGE** (frames from Eddie's own jar test). Numbers are tagged ESTIMATED. Builders: `docs/manual/build_assets.py` (pictures into the gitignored `docs/manual/hires/`), `docs/manual/diagrams.py` and `docs/manual/build_manual.py`. The v1 picture folder `docs/manual/img/` is removed because nothing uses it now.
- Every page was checked by machine for content running into the footer (none does), and all 77 pages were checked by eye on contact sheets.
- `tools/blender/cymatic_blender.py --stage 1-7`: builds the chamber up to one assembly step and highlights that step's new parts; adds the four support posts to the model.

**Stubbed**
- `packages/core-audio`, `core-physics`, `core-light`, `core-session`, `core-cv`, `ui-kit` (status exports only).
- `apps/desktop`, `apps/mobile`, `firmware/chamber-esp32`, `supabase` (READMEs describing their phase).
- The FADE ALL button logs and notifies listeners, but no real output is registered yet (there's no audio or light engine until P1/P3).

**Untested**
- No real device or browser matrix runs (PLATFORM_LIMITS "verify" cells). The web shell was checked only as a headless Chromium screenshot at three viewport sizes.
- The red-flash rule is a design choice (1 transition per second, 5 % threshold); it isn't calibrated against a published red-flash standard yet.

**Couldn't verify**
- **CI on GitHub.** Both jobs of the new workflow fail in about 3 seconds without ever getting a runner (no logs exist). The same happens to every workflow run in this repo since Nov 17 (Alien Sudoku too), while GitHub Pages deploys still succeed. That points to the account's Actions settings or billing (minutes or spending limit), not to the code. Every CI step passes when run locally.
- Whether the inherent f/2 oscillation of a single-tone Faraday pattern counts as hazardous flicker (needs a photodiode measurement in P5).
- The §17 source links were copied from the spec, not re-opened.
- The installed plugin: Eddie approved `frontend-design`; enabling it happens on his side (install card shown). `Security Guidance` was deferred to P7/P9 at his choice.
