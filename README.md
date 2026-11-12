# Off-Grid Survival Kit

An installable web app that works with **no internet and no cell signal** once it's on your phone. At its core is a GPS map. It keeps working with no signal because it saves map tiles, uses on-device GPS and compass, and stores your waypoints and tracks locally. Around the map are offline field guides: water, first aid, fire/shelter/knots, foraging, food, off-grid electricity, emergency device tools, and a printable emergency PDF.

- Plain HTML/CSS/JS. No framework and no build step needed to run it.
- Every library is bundled under `assets/vendor/`. There are no CDN, font, analytics or API calls at runtime.
- Everything you create stays on the device (IndexedDB/localStorage). Nothing is uploaded.

> **Safety:** this is a reference that supports training and judgement. It does not replace them. In an emergency, call for help first if you can (911 US, 112 EU). Foraging, first-aid, electrical and food-preservation content carries real risk. Read the safety callouts.

---

**Ready-made zip:** `dist/off-grid-survival-kit.zip` (unzip anywhere, then run the one-liner below inside the folder).

## Open it on any phone (no install, no Python)

**https://namastegeitz.github.io/Eddie-G/** — open it once with signal, wait for "Offline-ready ✓", then *Add to Home Screen* (iPhone: Share button; Android: Install app). After that it works with no signal. To hand it to someone else, use the hub's "Open on another phone" QR code.

## Run it locally (one line)

```bash
cd apps/off-grid-survival-kit && python3 -m http.server 8000
```

Then open **http://localhost:8000**.

**GPS needs a secure context.** Browsers only allow geolocation, the compass, the offline service worker and installation on `https://` addresses or on `http://localhost`. Opening `index.html` directly (`file://`) loads the guides, but GPS, offline caching and install are blocked. An `http://192.168.x.x` address is also blocked. Once the app is installed it keeps working offline from the home screen.

## Install it on a phone

A phone can't open your laptop's `localhost`, so the app needs an HTTPS address once:

1. **Host the folder on any static HTTPS host.** It is just files. GitHub Pages, Netlify Drop and Cloudflare Pages all work. Upload the contents of `apps/off-grid-survival-kit/`.
   - **Android testing without hosting:** connect the phone by USB. In desktop Chrome, open `chrome://inspect` → *Port forwarding* → forward `8000` → `localhost:8000`. Then open `http://localhost:8000` on the phone.
2. Open the address on the phone **while online** and wait for the hub's **"Offline-ready ✓"** chip. The service worker has then saved every page, script, icon and the PDF.
3. Install it:
   - **Android / Chrome:** tap **Install app** on the hub, or ⋮ → *Install app*.
   - **iPhone / iPad / Safari:** Share → **Add to Home Screen**.
   - **Desktop Chrome/Edge:** use the install icon in the address bar.
4. Open it from the home screen once, allow **location** (and on iPhone, the **compass/motion** prompt that appears when you tap *Follow* or the compass).
5. Turn on airplane mode and open it again. It should launch, and every page should open.

On iPhone, Safari can clear website storage after about 7 days without use. That limit doesn't apply to apps added to the Home Screen, so install it. The app also asks the browser for persistent storage (Map → Settings → Storage shows whether it was granted).

## Pre-load offline maps (do this before you lose signal)

1. Map → **Layers** button → pick a base map:
   - **OpenTopoMap:** terrain, contours, trails, peaks. Best for backcountry.
   - **OpenStreetMap:** streets, buildings, place names.
   - **Custom URL:** your own tile server (see below).
2. Pan and zoom to the area. The view sets the area, and the current zoom is the least-detailed level saved.
3. Menu → **Offline maps** → choose **extra zoom levels** (+1 … +5) and keep **Include elevation data** ticked → **Save this area**. A progress bar shows the tile count, the size so far and any failures. Keep the screen on until it finishes.
4. Repeat for each area you need: home, routes, destinations. The **Offline maps** tab lists saved areas, the total stored size, and buttons to clear one base map or all tiles.

Notes:

- **Browsing primes the cache.** Every tile you look at while online is saved automatically. You can turn this off in Settings.
- **Zooming past what you saved** shows the nearest saved tile scaled up. It is blurry rather than blank.
- **No tiles at all and no signal?** The map draws a **lat/lon graticule**: labelled coordinate grid lines on a plain background. Your GPS dot, waypoints, tracks and measurements still sit correctly on it, so the map is never a grey void.
- **Be kind to free tile servers.** OSM and OpenTopoMap are volunteer-run, and their policies forbid heavy bulk downloads. OSM specifically forbids bulk-downloading zoom 17+. The app enforces these limits:
  - a cap of **5,000 tiles per job** (with a warning above 1,000) for those servers;
  - a maximum bulk zoom of **16**;
  - **2 parallel downloads** with a short pause between tiles;
  - it skips tiles you already have and retries failures once.
- **Attribution** for each source is shown on the map.

### Your own tiles (MBTiles / large regions)

Under **Layers → Custom URL**, enter any XYZ template, for example `http://192.168.1.20:8080/data/region/{z}/{x}/{y}.png`. It supports `{s}` for a/b/c subdomains and `{-y}` for TMS/MBTiles row order. Serve an `.mbtiles` file from a laptop or Raspberry Pi with any tile server, such as `tileserver-gl-light`, `mbtileserver` or `martin`. The server must send `Access-Control-Allow-Origin: *`, or tiles can be viewed but not saved. Custom sources get higher caps (100,000 tiles per job, up to zoom 22), because you aren't loading a shared public server.

One catch: a page served over HTTPS can't load tiles from a plain-`http://` LAN server (mixed content). Either serve your tiles over HTTPS, or run the app itself from `http://localhost` on the same machine.

### Elevation data

Altitude, slope, aspect and the **contour-line overlay** come from open **Terrain Tiles** in "Terrarium" encoding (SRTM, USGS 3DEP and other public sources, hosted on AWS). They are saved alongside the map when you save an area. The app saves zoom levels 10–12, which is about 30 m resolution: plenty for slope and contours without huge downloads. You can point to your own elevation tile server in Settings. Treat values as terrain-scale estimates (typically ±10–20 m).

## What the map does

| Feature | Details |
|---|---|
| Offline tiles | IndexedDB-first tile layer, browse-to-prime, "Save this area" bulk job with estimate, progress, caps and cancel, parent-tile fallback, per-source clear |
| Base maps | OpenStreetMap, OpenTopoMap, custom URL; dimmed tiles in night mode, red filter in red mode |
| Fallback grid | Lat/lon graticule whenever no tiles are available (Auto), or always on; UTM/MGRS grid with 100 km square letters |
| Live GPS | `watchPosition` high accuracy, pulsing dot, accuracy circle, heading cone, follow-me (stops when you drag), stale-fix greying |
| Telemetry | Lat/lon (tap to cycle DD / DMS / DDM), altitude ± accuracy, speed, accuracy, heading, **daylight left** |
| Full compass | Tap the map's compass rose (or `map/index.html#compass`, or the standalone **/compass/** page): big live heading, true/magnetic toggle, bearing lock with turn-left/right steering, back bearing, level bubble, calibration and interference warnings, sun and moon marks on the dial to check the compass against the sky, point-to-waypoint, camera sighting with a heading tape, bearing log, spoken heading. A locked bearing is drawn on the map |
| Compass | DeviceOrientation (`deviceorientationabsolute` on Android, `webkitCompassHeading` with permission prompt on iOS), smoothed, screen-rotation aware; GPS course used while moving if no compass; **automatic magnetic declination** from the World Magnetic Model 2025 computed on the device for your position (manual override available) → true bearings |
| Waypoints | 9 categories with icons (water, camp, food, cache, hazard, rally, landmark, medical, custom), name + note, at crosshair / GPS / long-press / typed coordinates (DD, DMS, DDM, MGRS, UTM); edit, delete, searchable sortable list |
| Navigate to | Live distance, true (and magnetic) bearing, turn arrow relative to your heading, ETA, guide line, "arrived" alert; survives reloads |
| Backtrack | Automatic breadcrumb trail while GPS is on (a point every ~15 m, kept 48 h, on-device). **Back** button guides you back the way you came to where you started — like Garmin TracBack / Apple Watch Backtrack. Handles out-and-back trails (never sends you back out to the far end), warns when you're off the trail, "Direct" for a straight line; any saved track can be backtracked too |
| Battery | GPS battery saver (one fix a minute) vs continuous; battery level and a low-battery prompt where the browser reports it (Android Chrome); battery tips |
| Tracks | Breadcrumb recording with accuracy filter, live line, distance/time/points, pause, save/name, show/hide, rename, delete, per-track GPX; checkpointed so a crash doesn't lose it; screen wake lock |
| Measure | Tap or add-crosshair points; cumulative distance, every leg's distance + bearing |
| Units & formats | Metric/imperial (scale bar follows), DD / DMS / DDM |
| Data | GPX 1.1 export (waypoints + tracks), GPX import (wpt/trk/rte), full JSON backup + restore (merge or replace) |
| Sun & moon | SunCalc on-device: first light, sunrise (with bearing), solar noon, sunset, last light, day length, sun position, **daylight remaining**, moon phase/illumination, moonrise/set, next full/new moon |
| MGRS / UTM | WGS84 UTM (6th-order Krüger series), MGRS via the bundled `mgrs` library, NATO-phonetic readout for radio |
| Triangulation | 2–3 landmarks (waypoint, tap on map, crosshair or typed) + bearings (type or capture from the compass), magnetic → true correction, least-squares resection, triangle of error, save fix as waypoint |
| Elevation | Elevation + slope + aspect under the crosshair and at your GPS position; locally drawn contour lines |
| QR share | Offline QR of a `geo:` URI or a text block (lat/lon, DMS, MGRS, accuracy, UTC time); copy / system share |
| SOS beacon | Full-screen giant coordinates (DD, DMS, MGRS + phonetic), slow flash / Morse SOS flash / steady; wake lock; warns loudly if showing the map centre instead of a GPS fix |
| Presets | Northeast US (New Jersey), Algarve (Portugal), my position, user bookmarks; last view remembered |

Deep links: `map/index.html#sos`, `#wp=<id>`, `#nav=<id>`, `#ll=lat,lon,zoom`, `#tab=offline`.

## Other modules

- **/water/**: finding water, boiling times, chemical dosing table, SODIS, improvised filter (clarity only!), solar still, rain capture, chemical contamination.
- **/firstaid/**: bleeding/tourniquet, wounds, burns, fractures, cold and heat illness, shock, CPR, choking, bites and stings, common OTC meds, a few medicinal plants.
- **/fireshelter/**: fire without matches, tinder and fire lays, shelters, knots with step diagrams.
- **/foraging/**: nuts and fruits (NE US + Mediterranean/Algarve), harvesting, processing, month-by-month charts, toxic look-alikes, the universal edibility test (last resort).
- **/food/**: trapping legality, fishing without a rod, cleaning game and fish, smoking, drying, salting, root cellar, water-bath canning with botulism safety.
- **/electricity/**: micro-hydro, wind, pedal/crank, thermoelectric, earth/voltaic cells, scavenged motors, wiring basics with honest power numbers and safety.
- **Search (hub box + /search/)**: offline search across every guide — type "bleeding", "boil water", "bowline", "snake bite", "lightning" and jump straight to the right card on the right page (synonyms and typo-tolerant; index built by `scripts/build_search.py`).
- **/plan/**: **Trip plan & turnaround** — leave-a-note trip plan (party, route, vehicle, gear, clothing colours, comms, waypoints) with an explicit "if we're not back by …, call …" instruction, shareable as text, print or QR; a Naismith's-rule time estimate (pace and breaks) checked against sunset and last light, the turnaround time for out-and-back routes, and a turnaround alarm.
- **/compass/**: the full live compass on its own page (same engine and features as the map's compass; works with no GPS and no signal).
- **/tools/**: lightning flash-to-bang distance with the NWS 30-30 rule (30-minute all-clear timer that restarts with each thunder), SOS strobe + text-to-Morse light (optional real flashlight on Android), whistle/alarm tones (WebAudio), editable gear checklists with templates, group rendezvous plan linked to map waypoints, timers.
- **/emergency/**: the printable **Emergency PDF** (scenarios, reference cards, fill-in pages) and the same content as an HTML page.

The how-to pages have a **Print this page** button and a print stylesheet (black on white, all sections expanded).

## Data & privacy

Waypoints, tracks, checklists, the rendezvous plan, settings and saved map tiles are stored **only on this device** in IndexedDB and localStorage. The app has no accounts, server, analytics or tracking. The only network requests it makes are:

- map and elevation tiles, while you are online;
- the first download of the app itself.

Uninstalling the app or clearing site data deletes everything, so use **Map → Import/Export → Full backup** to keep a copy.

## Choices made (and why)

- **Leaflet 1.9.4** (bundled), with a custom canvas tile layer for IndexedDB tiles, rather than relying on the service worker's HTTP cache. This gives explicit control over size, counting, clearing and fallbacks.
- **Tiles live in IndexedDB; app files live in the service worker cache.** The service worker never intercepts tile requests.
- **Elevation from Terrarium tiles at zoom 10–12** (≈30 m). This roughly matches the SRTM source resolution while keeping downloads small. Contours are computed on the device with marching squares.
- **Map is always north-up.** Leaflet doesn't rotate maps. The compass rose, heading cone and navigation arrow show direction instead.
- **Magnetic declination is automatic.** The app bundles NOAA's World Magnetic Model 2025 coefficients (`assets/js/wmm.js`, valid 2025–2030) and computes declination on the device for your GPS position (or the map view before the first fix): about 12.1° W in central New Jersey and 0.5–0.7° W in the Algarve in late 2026. It matches all 100 official WMM2025 test values to within 0.005° (`node tests/wmm.test.js`). A manual value can still be entered to match a specific paper map.
- **Three themes:** dark (default), day (high-contrast for sunlight), and **red** for night vision.
- **Conservative content:** canonical figures (boil times, bleach dosing, CPR rate/depth, tourniquet placement, canning rules, OTC limits) are kept identical across pages and the PDF.
- **QR codes are always black on white,** because scanners need contrast.
- **GPS starts automatically on the map** (can be turned off in Settings), since a map without a position is of little use in the field.

## Known limits

- **Trip-plan and turnaround alarms only ring while the app is open** (a web app can't wake a sleeping phone) — also set the phone's own clock alarm.
- **Browsers pause GPS when the screen is off or the app is in the background.** The app requests a screen wake lock while recording or navigating. Keep the screen on, or expect gaps.
- **iOS needs a tap to allow the compass.** Some desktop and Android browsers have no absolute compass; the app then uses GPS course while you're moving.
- **No offline place search or routing.** Use waypoints, coordinates and bookmarks.
- **Whether OpenTopoMap allows saving depends on its server sending CORS headers.** If it doesn't, the app says so and the layer works online only. Use OSM or a custom source offline.

## Folder structure

```
index.html            hub + live status chips (signal, offline-ready, GPS, saved map)
manifest.webmanifest  PWA manifest (icons, shortcuts: Map, SOS, Tools)
sw.js                 service worker (precache list generated by scripts/build_sw.py)
map/                  the map page
compass/ plan/ search/ foraging/ electricity/ water/ firstaid/ fireshelter/ food/ tools/ emergency/
assets/
  css/app.css         shared theme + components + print styles
  css/map.css         map page
  js/theme.js         applies saved theme before first paint
  js/common.js        header toggle, service worker, print, toasts, wake lock
  js/store.js         IndexedDB wrapper (kv, waypoints, tracks, checklists, tiles)
  js/geo.js           distance/bearing, DMS/DDM, UTM, MGRS, coordinate parser, resection
  js/wmm.js           World Magnetic Model 2025 (automatic magnetic declination)
  js/search.js        offline search engine (index: assets/data/search-index.json)
  js/hub.js           hub status + install + "open on another phone" QR
  js/compass.js       compass engine (sensor, iOS permission, tilt modes, smoothing, declination)
  js/compass-ui.js    full compass interface (standalone page + map overlay)
  js/map/*.js         map modules: core, tiles, grid, dem, gps, waypoints, tracks,
                      backtrack, measure, sunmoon, triangulate, share, data, main
  vendor/             leaflet 1.9.4, suncalc 1.9.0, qrcode-generator 1.4.4, mgrs 2.1.0 (+ licences)
  icons/              app icons (SVG + PNG + maskable)
scripts/
  build_sw.py         regenerate sw.js precache list + version hash (run after any change)
  build_search.py     regenerate the offline search index (run after changing any guide page)
  publish_pages.sh    publish the app to GitHub Pages (gh-pages branch)
  build_emergency.py  regenerate emergency/off-grid-emergency-guide.pdf + emergency/index.html
  emergency_content.py  the emergency guide's text (single source for PDF + HTML)
tests/
  acceptance.js       Playwright end-to-end test (online prime → offline checks)
  mocktiles.py        local mock tile + elevation server used by the test
  wmm.test.js         checks wmm.js against the 100 official WMM2025 test values
  wmm2025_test_values.csv
```

### After editing

```bash
python3 scripts/build_emergency.py   # if you changed the emergency content (needs: pip install reportlab)
python3 scripts/build_search.py      # if you changed any guide page
python3 scripts/build_sw.py          # always: new version hash → installed apps update on next launch
bash scripts/publish_pages.sh        # publish to https://namastegeitz.github.io/Eddie-G/
```

### Run the acceptance test

```bash
python3 -m http.server 8765 --bind 127.0.0.1 &   # from this folder
python3 tests/mocktiles.py 8790 &                  # needs Pillow
node tests/acceptance.js                           # needs Playwright + Chromium
node tests/wmm.test.js                             # magnetic model check (Node only)
```

The test:

1. Points the map at the mock tile server and primes tiles by browsing.
2. Saves an area (map + elevation), adds waypoints, navigates, measures, records a track and exports GPX/JSON.
3. **Goes offline** and reloads. It checks cached tiles render, parent-tile fallback, data persistence, elevation, the graticule fallback, the UTM grid, QR, the SOS beacon and triangulation.
4. Opens every page offline.

## Credits & licences

- Map data © OpenStreetMap contributors (ODbL).
- OpenTopoMap style © OpenTopoMap (CC-BY-SA).
- Elevation: Terrain Tiles (Mapzen/AWS Open Data; SRTM, USGS 3DEP and others).
- Libraries, each under its own licence (see `assets/vendor/LICENSE-*`):
  - Leaflet (BSD-2-Clause)
  - SunCalc (BSD-2-Clause)
  - qrcode-generator (MIT, © Kazuhiko Arase)
  - mgrs (MIT)
