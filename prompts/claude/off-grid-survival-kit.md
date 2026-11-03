# BUILD: "Off-Grid Survival Kit" — a 100% offline, installable field app

You are building a self-contained web app that runs with NO internet and NO
cell signal once installed. Treat this as a real tool someone's safety may
depend on. Accuracy and offline-reliability matter more than polish.

## ABSOLUTE CONSTRAINTS (do not violate)
- Works fully OFFLINE after first load. ZERO runtime calls to any CDN, font
  service, analytics, or API. Bundle every library locally (install via npm,
  then COPY the dist files into the app; do not <script src> a CDN).
- Vanilla HTML/CSS/JS only. No build step required to run. No React/Vue.
- Installable PWA: web app manifest + service worker that precaches the full
  app shell so it opens offline and installs to a phone home screen.
- All user data (waypoints, tracks, saved map tiles, checklists, settings)
  stored ON-DEVICE via IndexedDB/localStorage. Nothing leaves the device.
- Mobile-first. Large touch targets (min 48px) for cold/gloved/stressed use.
  Dark theme by default (battery + night vision) with a bright "day mode"
  toggle for direct sunlight. High contrast.
- Note the secure-context caveat for GPS: document that the app must be opened
  from http://localhost or an https origin (or installed as a PWA) for
  geolocation to work — file:// blocks it. Include a one-line local launcher
  (e.g. `python3 -m http.server`) in the README.

## APP STRUCTURE
A home hub linking every module. Each major area lives in its OWN folder:
  /                 hub (index.html) + live status chips (GPS, offline-ready)
  /map/             THE MAP — top priority (see below)
  /foraging/        nuts, fruits & wild edibles
  /electricity/     free electricity, old-school methods
  /water/           finding & purifying water
  /firstaid/        first aid & field medicine
  /fireshelter/     fire, shelter & knots
  /food/            trapping, fishing & food preservation
  /tools/           emergency device tools (see below)
  /emergency/       the printable Emergency PDF + scenario reference
  /assets/          local css, js, bundled map engine, icons
Keep a consistent header (back-to-hub, title, day/night toggle) across pages.
Every how-to page: skimmable, step-numbered, with clear SAFETY callouts.

## ===== THE MAP — PRIMARY FOCUS, SPEND THE MOST EFFORT HERE =====
Use Leaflet (install leaflet@1.9.x via npm, copy leaflet.js/.css/images into
/assets/ — no CDN). The map MUST remain useful with no signal. Features:

OFFLINE TILES (critical):
- Custom tile layer that serves each tile from IndexedDB first; if missing and
  online, fetch, display, AND store it so browsing "primes" the cache.
- "Save this area offline" button: downloads every tile in the current view
  across the next few zoom levels into IndexedDB for later no-signal use.
  Show a progress bar, tile count, and estimated size; cap the job with a
  warning to avoid hammering the tile server; respect OSM attribution.
- Show total saved-tile size and a "clear saved tiles" button.
- Tile source selector: OpenStreetMap (streets), OpenTopoMap (terrain), and a
  CUSTOM URL field (so advanced users can point at their own downloaded tile
  server / mbtiles). Default to a sensible one.
- GRACEFUL FALLBACK: if there are zero tiles AND no signal, draw a lat/lon
  coordinate graticule on a blank canvas so GPS position + waypoints are still
  spatially usable. The map is never a blank grey void.

LIVE POSITIONING:
- watchPosition (high accuracy): animated GPS dot + accuracy circle.
- "Locate / follow me" toggle that keeps the map centered on movement.
- Live telemetry bar: latitude/longitude, altitude, speed, GPS accuracy.
- Compass rose + heading using DeviceOrientation (handle iOS permission
  request) with GPS course as fallback; show degrees + cardinal.

WAYPOINTS:
- Drop a pin at map-center or at current GPS. Categorize with clear icons:
  water, camp/shelter, food/forage, cache/supply, hazard/danger, rally point,
  landmark, medical, custom. Name + note each. Persist in IndexedDB.
- Tap a pin to edit/delete. Scrollable waypoint list in the menu.
- "Navigate to" a waypoint: show live bearing + distance from current GPS and
  draw a guide line. Update as you move.

TRACKS:
- Record a breadcrumb trail (GPS polling), draw it live, show running distance.
  Save/name/list/show/delete tracks. Persist on-device.

MEASURE + GRID:
- Tap points to measure cumulative distance and leg bearing.
- Scale bar. Units toggle (metric/imperial). Coordinate format toggle
  (decimal degrees / DMS).

DATA PORTABILITY:
- Export waypoints + tracks as GPX. Full JSON backup + restore (file import).

MAP ADD-ONS (build all of these):
- SUN & MOON (offline calc, no API): sunrise, sunset, solar noon, daylight
  remaining, civil twilight, moon phase + moonrise/set for the map's current
  position and date. Use a local astronomical algorithm (e.g. bundle SunCalc
  locally or implement the NOAA solar equations). Prominent "daylight left"
  readout for planning.
- MGRS / UTM GRID + TRIANGULATION: show current position as MGRS and UTM in
  addition to lat/lon. Triangulation tool: input 2–3 known landmarks +
  bearings and plot the estimated position (classic resection).
- ELEVATION & CONTOURS: support an offline terrain/contour tile layer
  (OpenTopoMap via the offline cache) and show an elevation readout + simple
  slope/aspect estimate at the cursor/GPS where data allows.
- LOCATION QR SHARE + SOS BEACON: generate an OFFLINE QR code (bundle a local
  QR lib) encoding current coordinates + a geo: URI to hand your position to
  someone else's phone with no network. SOS beacon screen: giant high-contrast
  coordinate display that flashes, for flagging down help / reading over radio.

Default map presets/bookmarks for quick jump: Northeast US (New Jersey) and
the Algarve, Portugal. Remember last view between sessions.

## /foraging/ — NUTS, FRUITS & WILD EDIBLES (how to harvest & pick)
Research-grade, practical content. Cover at minimum:
- NUTS: acorns (incl. tannin leaching), black walnut, hickory, American/
  chestnut, hazelnut/filbert, pecan, beechnut, pine nuts. How to find, when
  they drop, how to pick/shake/collect (pole + tarp method), hull, cure, crack,
  store.
- FRUITS/BERRIES: blackberry, raspberry, mulberry, elderberry (must cook),
  wild grape, serviceberry, pawpaw, persimmon (ripeness!), crabapple, rose hips,
  plus Mediterranean/Iberian: fig, carob, almond, olive (cure before eating),
  prickly pear, arbutus/medronho, loquat.
- Harvesting technique per plant, ripeness cues, tools, and
  processing/storage (drying, cold storage, preserving).
- Seasonality chart (month-by-month) for a temperate NE-US climate AND a
  Mediterranean climate.
- The Universal Edibility Test, written correctly as a LAST resort.
- A strong, repeated SAFETY section on toxic look-alikes (e.g. pokeweed,
  horse chestnut vs sweet chestnut, moonseed vs wild grape, yew, deadly
  nightshade), the "never eat white/unknown berries" rule, and "if not 100%
  identified, do not eat." Include a disclaimer to cross-check with a regional
  field guide; this app is a reference, not a positive ID.

## /electricity/ — FREE ELECTRICITY, OLD-SCHOOL METHODS (how-to's)
Each method = what it is, parts, step-by-step build, realistic power output,
and SAFETY. Cover:
- Micro-hydro / water wheel driving a DC motor/alternator as a generator.
- Wind turbine from a car/truck alternator or a scavenged DC motor.
- Pedal-power and hand-crank generators (bike + motor).
- Thermoelectric (Seebeck/Peltier) off a wood stove.
- Earth battery and voltaic pile / salt-water & coin cells (low power, for
  light/charging comms — set honest expectations).
- Scavenging usable generators from treadmills, drills, fans.
- WIRING BASICS: rectification (AC→DC), a charge controller, storing in a
  battery, fusing. Plain-language and correct.
- SAFETY callouts throughout: shock, short-circuit/fire, battery gas/acid,
  never back-feed house mains, DC vs AC cautions.

## OTHER SURVIVAL MODULES (own folders, solid how-to content)
- /water/: finding water, boiling times, filtration (improvised charcoal/sand
  filter), solar still, rainwater capture, when purification isn't enough
  (chemical contamination). Clear "boil if in doubt" guidance.
- /firstaid/: severe bleeding/tourniquet, wound care, burns, fractures/splints,
  hypothermia & heat illness, shock, CPR basics, choking, common meds, a few
  well-attested medicinal plants. Prominent disclaimer: not a substitute for
  professional care; get to real help when possible.
- /fireshelter/: fire without matches (ferro rod, bow drill, lens, battery +
  steel wool), tinder, fire lays; shelters (debris hut, lean-to, snow, tarp
  configs); essential knots (bowline, taut-line, clove hitch, square,
  prusik) with step diagrams.
- /food/: snares/traps legality note, fishing without a rod, cleaning fish &
  small game, and PRESERVATION (smoking, drying/jerky, salting, root cellar,
  water-bath canning basics with botulism safety warnings).

## /tools/ — EMERGENCY DEVICE TOOLS (offline, on-device)
- SOS strobe + Morse light: full-screen white flash repeating ...---... and a
  text-to-Morse light mode. Keep screen awake while active.
- Whistle & alarm tones: generate loud attention/alarm tones via WebAudio
  (no audio files needed) for signaling.
- Gear & inventory checklists: editable, add/check/delete items, saved
  on-device, with a few starter templates (bug-out bag, car kit, first-aid).
- Group rendezvous plan: set primary/secondary/tertiary meetup points (link to
  map waypoints), a muster time, and simple "if separated" notes. Saved locally.

## /emergency/ — PRINTABLE EMERGENCY PDF + SCENARIOS
Generate a real, multi-page PDF (use a local generator such as reportlab) that
works printed, with no device at all. Include:
- Quick-action index + priorities (the survival rule-of-3s).
- USE-CASE SCENARIOS with step-by-step response: lost while hiking; vehicle
  breakdown in remote area; power grid down (multi-day); severe storm/flood;
  wildfire evacuation; winter stranded; water contamination; injury far from
  help; separated from group.
- Reference cards: water purification table, signaling (ground-to-air codes,
  whistle/light codes), knots, first-aid quick steps, a blank waypoint/ICE
  contacts page to fill in by hand.
Also surface the PDF for viewing/printing inside the app, and add a
print-friendly stylesheet to the key how-to pages.

## CONTENT ACCURACY & SAFETY (applies everywhere)
- Be correct and conservative. Where getting it wrong could hurt someone
  (foraging IDs, dosing, canning, electricity), state the risk plainly and tell
  the user when to stop and seek expert help / a regional guide.
- Include concise disclaimers; don't bury them, don't overdo them.

## TECH / QUALITY BAR
- Clean folder structure, commented code, a README (what it is, how to run
  locally, how to install as a PWA, how to pre-load offline map tiles, data/
  privacy note that everything stays on-device).
- Service worker precaches the shell and the bundled map engine; app opens with
  network disabled.
- Accessible: semantic HTML, focus states, readable at arm's length.

## ACCEPTANCE TEST (verify before you finish)
1. Serve locally, load once, then DISABLE network (airplane mode / devtools
   offline): hub + every page + the map still open.
2. Prime a map area while online, go offline: those tiles still render; GPS dot,
   waypoints, tracks, measure, grid, sun/moon, MGRS, QR, SOS all still work.
3. Add a waypoint and a checklist item, reload offline: data persists.
4. Install as a PWA to a phone home screen and confirm it launches offline.
5. Open the Emergency PDF and print-preview a how-to page.
Fix anything that fails, then give me a short run/install guide and zip the app.

Build the MAP first and most thoroughly — it's the centerpiece — then the
content modules, then the PDF. Ask me nothing; make reasonable choices and
note them in the README.
