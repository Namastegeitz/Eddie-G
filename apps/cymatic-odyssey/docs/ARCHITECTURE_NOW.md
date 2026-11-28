# Architecture now (P0 audit, 2026-11-27)

This describes the project **as it exists before the Cymatic Light Chamber upgrade**: what's there, how the STLs are made, what the new spec reuses, and what is fragile or in conflict with the new rules. Nothing below has been changed by the audit.

Project root: `apps/cymatic-odyssey/` inside the `namastegeitz/eddie-g` repo (the repo also holds other apps). Current brand: **CYMATIC ODYSSEY**. The new spec's working name is **Cymatic Light Chamber**; the folder is not renamed, because many links and zips point at it.

## 1. What exists

| Area | Entry point | What it does | Tests |
|---|---|---|---|
| Geometry engine | `tools/odyssey/` (core, curves, fractals, physics, tilings, polyhedra, polytopes, catalog, build) | 355 parametric "looks" (polygons → E8, Penrose/multigrid, hyperbolic, Hankin girih, fractals, Chladni/Bessel/Faraday patterns, real orbital art) as 2D designs → gobos, boundary inserts, dipper feet; 12 parametric hardware parts | `tests/test_tools.py` (solid/root-system counts, catalog uniqueness) |
| STL/SVG generator | `tools/generate.py` | builds every STL/SVG, previews, `catalog/geometry_catalog.{json,csv}`, `docs/GEOMETRY_CATALOG.md`, `downloads/*.zip`; about 2-3 min with 3 workers | run in tests indirectly; full run checked manually |
| Physics tables | `tools/physics_tables.py` | capillary-gravity dispersion, Faraday onset estimate, free-edge Bessel dish modes → `docs/PHYSICS_TABLES.md` | `test_dispersion` |
| Pattern recognition | `tools/pattern_analyzer.py`, `tools/mode_mapper.py` | FFT symmetry order (2-14 fold), wavelength, stability; webcam sweep → atlas CSV | symmetry, rings/noise, wavelength, stability tests |
| Styles | `tools/styles.py`, `tools/render_wall.py` | 30 styles (gobo + insert + foot + signal + palette); kit folders `styles/S##_*`; simulated wall/water/parts previews | `test_styles_and_shows` |
| Shows & content | `tools/content.py` | 11 voyages, 15 intertwined 10-min shows, 40 holiday themes → `catalog/content.json`, docs, injected into the console | `test_styles_and_shows` |
| Voyage console | `console/index.html` (1.36 MB, single file) | Web Audio tone engine (2 tones, pulse, breathe, sweep, L/R split routing), WebGL1 caustic simulator, 30-style gallery with gobo textures, shows + continuous chain, themes, pattern atlas (localStorage) | **no committed tests** (it was checked with throwaway Playwright scripts that live outside the repo) |
| Bambu prep | `tools/bambu_ready.py` | checks/repairs every STL, writes 65 lib3mf-verified 3MF plates (incl. two-colour gobos, A1-mini platform) → `bambu/REPORT.json`, zip | `test_bambu_report` |
| Blender | `tools/blender/cymatic_blender.py` | add-on + CLI: bevel, self-checking engrave, remesh, decimate, chamber assembly + Cycles render | run manually with `bpy` 5.3 (81 parts, all watertight) |
| Videos | `tools/make_videos.py`, `tools/marketing_copy.py` | 15 × 30 s vertical show videos with a synthesized soundtrack; captions | `test_video_soundtrack_shape` |
| PDFs | `docs/manual/build_manual.py`, `docs/sourcing/build_pdf.py` | HTML → Chromium print: 37-page manual, sourcing guide | none |
| Docs | `docs/*.md` | build specs, safety, physics, market, themes, shows, shopping, Bambu, Blender | none |

## 2. Stack

- **Python 3.13**: numpy, scipy, shapely 2.2, trimesh 5.2, **manifold3d 3.5** (Python bindings), mapbox_earcut, matplotlib, contourpy, Pillow, lib3mf 2.5. Optional: `bpy` 5.3 (Blender as a module, ~400 MB), ffmpeg (videos).
- **Browser**: one hand-written HTML file, vanilla JS, Web Audio, WebGL1. No bundler, no framework, no package.json.
- **PDF builds** call `node -e "require('playwright')..."`: they depend on a **globally installed Playwright/Chromium** that exists in this cloud container, not on a normal PC.
- No CI for this app (the repo's `.github/workflows/` only covers other apps).

## 3. How STLs are generated today

```
catalog.py  add(name, family, fn, math, ...)       355 registry entries (lambdas)
   │  fn() -> Design(lines=[(N,2) arrays], fills=[shapely], region=shapely)   (unit disc)
   ▼
build.py
   gobo:    lines -> shapely buffer/union (vector) or 0.05 mm raster + contour (dense art)
            -> manifold3d CrossSection(EvenOdd).extrude: 0.6 mm base + 2.4 mm lines (lithophane)
   insert:  disc(dish_id - 2) minus region -> extrude 12 mm, 3 water slots
   dipper:  region -> 2 mm foot + 6 mm stem (+ spokes for multi-pin)
   save_stl: man.simplify(0.01) -> binary STL (header "CYMATIC ODYSSEY")
   ▼
generate.py (ProcessPool) -> stl/, svg/, previews/, catalog/*.json|csv, docs/GEOMETRY_CATALOG.md, downloads/*.zip
styles.py   -> copies kit parts + renders previews -> styles/S##_*/, downloads/..._30_style_kits.zip
bambu_ready.py -> trimesh checks + lib3mf 3MF plates -> bambu/, REPORT.json
```

Loose gobo STLs/SVGs, kit STLs and enhanced STLs are **gitignored**; the committed artifacts are the zips.

## 4. What the new spec can reuse directly

| Spec feature | Existing piece |
|---|---|
| §5.2 dispersion fixtures | `physics_tables.wavelength_mm` matches the spec's λ table within **0.62 %** (spec allows ±1 %) |
| §5.3 Bessel zeros | `scipy.special.jnp_zeros`, all 9 spec fixtures exact to 3 decimals |
| §5.5 two-frequency forcing | ratio presets 4:5, 6:7, 2:3, 1:2 in the console and shows |
| §5.6 N-wave simulator | console WebGL shader + `render_wall.py` (caustic model, gobo refraction) |
| §5.7-5.8 Bowl Fingerprint / Symmetry Score | `mode_mapper.py` + `pattern_analyzer.py` (angular FFT, radial FFT, stability) |
| §6.1 shape families | nearly every family exists in Python (star polygons, roses, superformula, phyllotaxis, golden spiral, Lissajous, Chladni, Faraday, Penrose multigrid, Flower/Seed/Metatron, Sri-Yantra-style, Platonic projections, torus knots); **missing**: Voronoi, 3D lanterns (dome/cylinder/torus/Platonic shells), captured-cymatics contour plates, pendants |
| §6.3 printability | manifold output + watertight checks exist; min-feature checks do not |
| §4.12 Headphone Check, §4.2 8-layer stack, §4.3-4.6 binaural/isochronic/hemispheric | **not present** (console has 2 tones only) |

## 5. What's fragile

1. **Repo size.** `.git` is already about **947 MB packed**: STL zips, videos (113 MB), images and PDFs are committed. GitHub warns above 1 GB and blocks files over 100 MB. Large binaries should move to GitHub Releases or Git LFS (Eddie's decision; LFS has storage/bandwidth quotas).
2. **Console is a 1.36 MB single file** edited by string replacement, with JSON and base64 images injected between `/*CONTENT*/` and `/*ASSETS*/` markers. No build step, no unit tests.
3. **PDF builders depend on a global Playwright** install that only exists in this container.
4. **Two physics constants**: the Python code uses σ = 0.072 N/m; the spec says 0.0728 with a temperature model. Both pass the fixtures, but the TS port should take the spec's σ(T) and keep the fixture test.
5. **Generated data duplicated in three places** (`catalog/content.json`, the console's injected copy, docs), kept in sync only by re-running `tools/content.py`.
6. `bpy` and lib3mf are optional and heavy; the Blender tool isn't covered by automated tests.

## 6. Conflicts with the new spec's rules (must be resolved, not hidden)

| Rule | Current state | Severity |
|---|---|---|
| §9.1 water-beat flicker: two drive tones must not differ by 3-60 Hz | **12 of 30 styles, 52 of 120 show steps and 16 voyage steps** use two tones whose difference is 6-24 Hz (e.g. S03 40 Hz + 50 Hz → 10 Hz) | **High.** These need re-tuning or a Lab-only opt-in. Re-tuning ideas for P1/P2: keep the ratio but move Δ below 3 Hz is impossible at these frequencies, so either drop the second tone to a separate low-amplitude layer, or mark them Lab/experimental |
| §9.1 periodic modulation 3-60 Hz | the console's *Pulse* slider goes to **4 per second**; dipper pulses modulate the projected light at that rate | Medium: clamp to ≤3 Hz |
| §9.1 inherent water motion | any Faraday pattern oscillates at f/2 (5-100 Hz). Mean brightness stays roughly constant (caustics redistribute light), but **local** contrast oscillates in the 3-60 Hz band | **Not verified.** Needs measurement (photodiode or high-speed camera) in P5; the §9.1 projection contrast/area cap is the mitigation |
| §4.1 / §9.2 audio: master −18 dBFS, fade-in ≥2 s, fade-out ≥3 s | console: volume up to 0.8 (≈ −2 dBFS), fade-in 0.4 s, limiter threshold −6 dB | Medium: fix in the new audio engine (P1) |
| §1 / §5.6 "SIMULATION" watermark on every simulated image | videos carry a small footer "Simulated preview…"; the console says it below the canvas; **style previews, the manual's images and the Blender wall picture have no watermark** | Medium: add watermarks (the manual rebuild does this now) |
| §9.5 claims register | none exists; existing docs make no health claims, and the never-say hits are all critical discussion (allowlist) | Low |
| §10 trademarks | no Hemi-Sync, CymaScope, HeartMath or Dispenza usage found | OK |
| §3.1 reference hardware | existing build is a **transmission/projection** chamber (light through a glass dish → lens → wall; 4 exciters + dipper). The spec's v1 is a **reflection** chamber (dark bowl, RGBW ring 15-30° above, overhead camera, one transducer) | Design decision for Eddie: support both as "Projection" and "Reflection" chamber profiles |
| §3.3 liquids | docs already say water + a drop of soap; spec adds optional glycerin; no toxic liquids anywhere | OK |
| EZ-100 Tesla coil | documented as optional, dry, ≥50 cm away, not in sold products | OK, consistent with §3.3 |

## 7. Migration plan (keep the old generator working)

- The Python generator stays where it is and stays the batch/CI source of truth. CI runs its tests plus a one-family generation smoke test on every push.
- `packages/core-geometry` gets a **legacy adapter** that reads `catalog/geometry_catalog.json` and `catalog/styles.json`, so the new app can list and download existing parts on day one.
- Families are ported to TypeScript + manifold-3d (WASM) one at a time in P4, each with a parity test against the Python output (same polygon area within tolerance, manifold mesh).
- The console keeps working until the new web app covers its features; then it's frozen as `console/` (legacy).
