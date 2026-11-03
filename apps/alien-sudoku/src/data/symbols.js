/* ================================================================
 symbols.js — All symbol sets for Alien Glyph Sudoku
 ----------------------------------------------------------------
 Each set has exactly 9 SVGs and 9 display names.
 Exported as an ES module (SYMBOL_SETS, SYMBOL_SET_ORDER).

 To add a new set, append an entry to the _sets object below:
   key: { name, svgs: [9 svg strings], names: [9 strings] }
 ================================================================ */


const SVG = (body, extra = '') =>
  `<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" ${extra}>${body}</svg>`;

/* ---- A: Alien Glyphs (original set) ---- */
const alien = {
  name: 'Alien Glyphs',
  names: ['Orbit','Eye','Antenna','Signal','Spiral','Crossorb','Lattice','Crescent','Saucer'],
  svgs: [
    // 1 — Orbit ring with center dot
    SVG(`<ellipse cx="16" cy="16" rx="12" ry="5"/><circle cx="16" cy="16" r="2.2" fill="currentColor"/>`),
    // 2 — Triangle eye
    SVG(`<polygon points="16,4 28,26 4,26"/><circle cx="16" cy="20" r="2.5" fill="currentColor"/>`),
    // 3 — Antenna being
    SVG(`<line x1="10" y1="4" x2="14" y2="12"/><line x1="22" y1="4" x2="18" y2="12"/><circle cx="10" cy="3" r="1.6" fill="currentColor"/><circle cx="22" cy="3" r="1.6" fill="currentColor"/><circle cx="16" cy="20" r="8"/><circle cx="13" cy="19" r="1.4" fill="currentColor"/><circle cx="19" cy="19" r="1.4" fill="currentColor"/>`),
    // 4 — Wave / signal
    SVG(`<path d="M3 11 Q8 3 13 11 T23 11 T33 11"/><path d="M3 21 Q8 13 13 21 T23 21 T33 21"/>`),
    // 5 — Spiral
    SVG(`<path d="M16 16 m-1 0 a1 1 0 1 1 2 0 a3 3 0 1 1-6 0 a5 5 0 1 1 10 0 a7 7 0 1 1-14 0 a9 9 0 1 1 18 0"/>`),
    // 6 — Cross orb
    SVG(`<circle cx="16" cy="16" r="9"/><line x1="16" y1="3" x2="16" y2="29"/><line x1="3" y1="16" x2="29" y2="16"/>`),
    // 7 — Lattice / runes
    SVG(`<line x1="4" y1="6" x2="28" y2="26"/><line x1="28" y1="6" x2="4" y2="26"/><line x1="16" y1="3" x2="16" y2="29"/>`),
    // 8 — Crescent moon with star
    SVG(`<path d="M22 6 a11 11 0 1 0 0 20 a8 8 0 1 1 0-20z"/><polygon points="9,8 10.5,11.5 14,12 11.2,14.5 12,18 9,16 6,18 6.8,14.5 4,12 7.5,11.5" fill="currentColor" stroke="none"/>`),
    // 9 — UFO saucer
    SVG(`<ellipse cx="16" cy="18" rx="12" ry="3.5"/><path d="M8 17 q8-10 16 0"/><circle cx="12" cy="17" r="0.8" fill="currentColor"/><circle cx="16" cy="17" r="0.8" fill="currentColor"/><circle cx="20" cy="17" r="0.8" fill="currentColor"/><line x1="13" y1="22" x2="11" y2="27"/><line x1="19" y1="22" x2="21" y2="27"/>`),
  ],
};

/* ---- B: Planets ---- */
const planets = {
  name: 'Planets',
  names: ['Mercury','Venus','Earth','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto'],
  svgs: [
    // Mercury — tiny, sun-baked, with radial heat-rays
    SVG(`<circle cx="16" cy="16" r="5"/><line x1="16" y1="4" x2="16" y2="8"/><line x1="24" y1="8" x2="21" y2="11"/><line x1="28" y1="16" x2="24" y2="16"/><line x1="24" y1="24" x2="21" y2="21"/>`),
    // Venus — cloud-shrouded globe, ♀ cross below
    SVG(`<circle cx="16" cy="11" r="8"/><line x1="16" y1="19" x2="16" y2="28"/><line x1="11" y1="24" x2="21" y2="24"/>`),
    // Earth — globe with equator + prime meridian
    SVG(`<circle cx="16" cy="16" r="11"/><ellipse cx="16" cy="16" rx="11" ry="5"/><line x1="16" y1="5" x2="16" y2="27"/>`),
    // Mars — circle + ♂ arrow top-right
    SVG(`<circle cx="12" cy="19" r="8"/><line x1="18" y1="13" x2="27" y2="4"/><polyline points="22,4 27,4 27,9"/>`),
    // Jupiter — large with cloud bands + Great Red Spot
    SVG(`<circle cx="16" cy="16" r="12"/><line x1="4" y1="11" x2="28" y2="11"/><line x1="4" y1="21" x2="28" y2="21"/><circle cx="10" cy="16" r="2.5"/>`),
    // Saturn — ring planet (most distinctive silhouette)
    SVG(`<circle cx="16" cy="16" r="7"/><ellipse cx="16" cy="16" rx="14" ry="5"/>`),
    // Uranus — ice giant, ring tilted 90° (vertical ellipse)
    SVG(`<circle cx="16" cy="16" r="7"/><ellipse cx="16" cy="16" rx="5" ry="12"/>`),
    // Neptune — stormy, with Great Dark Spot + faint ring
    SVG(`<circle cx="16" cy="16" r="10"/><path d="M6 12 Q11 9 16 11 Q21 13 26 11"/><circle cx="12" cy="17" r="3"/>`),
    // Pluto — tiny world with Tombaugh Regio heart
    SVG(`<circle cx="16" cy="15" r="7"/><path d="M16 20 Q10 18 11 14 Q12 9 16 12 Q20 9 21 14 Q22 18 16 20z" fill="currentColor" stroke="none"/>`),
  ],
};

/* ---- C: Moons ---- */
const moons = {
  name: 'Moons',
  names: ['Moon','Europa','Titan','Ganymede','Io','Callisto','Triton','Enceladus','Charon'],
  svgs: [
    // Earth's Moon — classic crescent
    SVG(`<path d="M21 6 a11 11 0 1 0 0 20 a8 8 0 1 1 0-20z"/>`),
    // Europa — icy surface with crack lines
    SVG(`<circle cx="16" cy="16" r="11"/><path d="M9 8 Q12 13 10 20"/><path d="M14 5 Q16 12 20 14"/><path d="M20 7 Q18 14 23 22"/>`),
    // Titan — thick haze atmosphere (dashed outer ring)
    SVG(`<circle cx="16" cy="16" r="8"/><circle cx="16" cy="16" r="12" stroke-dasharray="4,2"/>`),
    // Ganymede — largest moon, grooved terrain (three parallel arcs)
    SVG(`<circle cx="16" cy="16" r="11"/><path d="M5 11 Q16 9 27 11"/><path d="M5 16 Q16 14 27 16"/><path d="M5 21 Q16 23 27 21"/>`),
    // Io — volcanic, calderas as filled circles
    SVG(`<circle cx="16" cy="16" r="11"/><circle cx="9" cy="11" r="2.5" fill="currentColor"/><circle cx="22" cy="10" r="2" fill="currentColor"/><circle cx="23" cy="21" r="2.5" fill="currentColor"/><circle cx="10" cy="22" r="2" fill="currentColor"/>`),
    // Callisto — most heavily cratered (rings within rings)
    SVG(`<circle cx="16" cy="16" r="11"/><circle cx="10" cy="11" r="3"/><circle cx="21" cy="13" r="2"/><circle cx="13" cy="22" r="2.5"/><circle cx="22" cy="22" r="1.5"/>`),
    // Triton — retrograde orbit (arrow curving backward)
    SVG(`<circle cx="16" cy="16" r="8"/><path d="M16 6 Q28 6 28 16 Q28 26 16 26 Q4 26 4 16"/><polyline points="4,12 4,16 8,16"/>`),
    // Enceladus — ice jets spraying from south pole
    SVG(`<circle cx="16" cy="14" r="9"/><line x1="11" y1="23" x2="8" y2="30"/><line x1="16" y1="23" x2="16" y2="30"/><line x1="21" y1="23" x2="24" y2="30"/>`),
    // Charon — large moon of Pluto, dark polar cap (Mordor Macula)
    SVG(`<circle cx="16" cy="16" r="9"/><path d="M7 11 Q16 7 25 11 Q22 15 16 15 Q10 15 7 11z" fill="currentColor" stroke="none"/>`),
  ],
};

/* ---- D: Spaceships & UFOs ---- */
const spaceships = {
  name: 'Spaceships & UFOs',
  names: ['Flying Saucer','Starship','Rocket','X-Wing','Shuttle','Freighter','TIE Fighter','Scout Ship','Star Destroyer'],
  svgs: [
    // Flying saucer — dome on flat disc with portal lights
    SVG(`<ellipse cx="16" cy="20" rx="13" ry="4"/><path d="M7 19 Q10 10 16 10 Q22 10 25 19"/><ellipse cx="16" cy="14" rx="5" ry="3"/>`),
    // Starship (Enterprise-style) — saucer + neck + nacelles
    SVG(`<circle cx="16" cy="10" r="6"/><line x1="16" y1="16" x2="16" y2="21"/><path d="M4 24 Q10 19 16 21 Q22 19 28 24"/><ellipse cx="6" cy="25" rx="3.5" ry="2"/><ellipse cx="26" cy="25" rx="3.5" ry="2"/>`),
    // Rocket — classic pointed finned rocket
    SVG(`<path d="M16 3 Q22 12 21 22 L16 26 L11 22 Q10 12 16 3z"/><circle cx="16" cy="13" r="3"/><path d="M11 22 L7 29"/><path d="M21 22 L25 29"/>`),
    // X-Wing — body + 4 swept wings in X
    SVG(`<ellipse cx="16" cy="16" rx="5" ry="2.5"/><line x1="14" y1="14" x2="4" y2="5"/><line x1="18" y1="14" x2="28" y2="5"/><line x1="14" y1="18" x2="4" y2="27"/><line x1="18" y1="18" x2="28" y2="27"/>`),
    // Space Shuttle — delta-winged orbiter
    SVG(`<path d="M16 3 Q21 10 21 22 L16 27 L11 22 Q11 10 16 3z"/><path d="M11 14 L3 25 L11 21"/><path d="M21 14 L29 25 L21 21"/>`),
    // Freighter (Falcon-style) — round hull + offset cockpit
    SVG(`<path d="M3 16 Q5 8 14 7 Q22 6 28 13 Q30 18 26 24 Q20 28 14 25 Q5 23 3 16z"/><circle cx="14" cy="16" r="4"/><path d="M20 8 Q26 6 28 10"/><circle cx="25" cy="11" r="2.5"/>`),
    // TIE Fighter — ball cockpit + twin solar panels
    SVG(`<circle cx="16" cy="16" r="4.5"/><line x1="11.5" y1="16" x2="3" y2="16"/><line x1="20.5" y1="16" x2="29" y2="16"/><rect x="1" y="9" width="3" height="14" rx="0.5"/><rect x="28" y="9" width="3" height="14" rx="0.5"/>`),
    // Scout Ship — aerodynamic teardrop
    SVG(`<path d="M16 4 Q27 12 25 24 L16 28 L7 24 Q5 12 16 4z"/><circle cx="16" cy="16" r="4"/><line x1="9" y1="22" x2="23" y2="22"/>`),
    // Star Destroyer — triangular wedge
    SVG(`<polygon points="16,4 29,26 16,22 3,26"/><line x1="16" y1="4" x2="16" y2="22"/><line x1="5" y1="22" x2="27" y2="22"/><circle cx="16" cy="19" r="2" fill="currentColor"/>`),
  ],
};

/* ---- E: Aircraft & Rockets ---- */
const aircraft = {
  name: 'Aircraft & Rockets',
  names: ['Airliner','Fighter Jet','Space Shuttle','Saturn V','Biplane','Balloon','Helicopter','Concorde','Zeppelin'],
  svgs: [
    // Commercial airliner — tubular fuselage, swept wings, T-tail
    SVG(`<path d="M2 17 Q12 13 22 14 L30 16 L22 18 Q12 19 2 17z"/><path d="M9 14 L7 7 L14 13"/><path d="M22 15 L24 10 L27 14"/><line x1="29" y1="14" x2="29" y2="18"/>`),
    // Fighter jet — delta-wing planform (top-down)
    SVG(`<path d="M29 16 L5 9 L9 16 L5 23z"/><path d="M9 14 Q15 10 19 12 L22 15 L19 18 Q15 20 9 18z"/>`),
    // Space Shuttle — orbiter + double wing (same as spaceship set, different context)
    SVG(`<path d="M16 3 Q21 10 21 22 L16 27 L11 22 Q11 10 16 3z"/><path d="M11 14 L3 25 L11 21"/><path d="M21 14 L29 25 L21 21"/><line x1="10" y1="27" x2="22" y2="27"/>`),
    // Saturn V — tall multi-stage rocket with fins
    SVG(`<path d="M13 4 L19 4 L20 13 L19 25 L16 29 L13 25 L12 13z"/><line x1="12" y1="13" x2="20" y2="13"/><line x1="12" y1="20" x2="20" y2="20"/><path d="M12 25 Q8 27 8 30"/><path d="M20 25 Q24 27 24 30"/>`),
    // Biplane — double-decker wings with struts between them
    SVG(`<line x1="3" y1="11" x2="29" y2="11"/><line x1="5" y1="18" x2="27" y2="18"/><line x1="12" y1="11" x2="12" y2="18"/><line x1="20" y1="11" x2="20" y2="18"/><path d="M24 11 Q28 14 30 16 Q28 18 24 18"/><path d="M3 11 Q3 8 6 8"/><path d="M5 18 Q3 21 5 23"/>`),
    // Hot air balloon — envelope + basket + suspension lines
    SVG(`<path d="M16 3 Q28 6 28 16 Q28 27 16 27 Q4 27 4 16 Q4 6 16 3z"/><rect x="11" y="25" width="10" height="5" rx="1.5"/><line x1="11" y1="25" x2="8" y2="18"/><line x1="21" y1="25" x2="24" y2="18"/>`),
    // Helicopter — teardrop body + main rotor + tail rotor
    SVG(`<path d="M6 17 Q12 12 18 14 L24 14 L26 17 L24 19 Q18 21 12 19z"/><line x1="2" y1="10" x2="24" y2="10"/><circle cx="13" cy="10" r="1.5" fill="currentColor"/><line x1="6" y1="18" x2="3" y2="15"/><line x1="2" y1="12" x2="2" y2="18"/>`),
    // Concorde / supersonic — needle nose, ogival delta wings
    SVG(`<path d="M30 16 L4 10 L6 16 L4 22z"/><path d="M6 14 Q14 9 20 10 Q24 12 27 15"/><path d="M6 18 Q14 23 20 22 Q24 20 27 17"/>`),
    // Zeppelin — blimp envelope + gondola car
    SVG(`<path d="M4 16 Q6 8 16 8 Q26 8 28 16 Q26 24 16 24 Q6 24 4 16z"/><rect x="10" y="22" width="12" height="5" rx="1.5"/><line x1="12" y1="22" x2="12" y2="27"/><line x1="20" y1="22" x2="20" y2="27"/><line x1="16" y1="8" x2="16" y2="24"/>`),
  ],
};

/* ---- F: Galaxies ---- */
const galaxies = {
  name: 'Galaxies',
  names: ['Spiral','Elliptical','Barred Spiral','Lenticular','Irregular','Ring Galaxy','Colliding','Dwarf','Quasar'],
  svgs: [
    // Spiral galaxy — two-arm logarithmic spiral, bright nucleus
    SVG(`<circle cx="16" cy="16" r="3" fill="currentColor"/><path d="M16 16 Q22 10 26 8 Q30 8 28 12 Q24 16 16 16 Q8 16 4 20 Q2 24 6 26 Q10 28 14 16"/>`),
    // Elliptical galaxy — nested concentric ellipses, bright core
    SVG(`<ellipse cx="16" cy="16" rx="13" ry="9"/><ellipse cx="16" cy="16" rx="8" ry="5.5"/><circle cx="16" cy="16" r="2" fill="currentColor"/>`),
    // Barred spiral — central bar + spiral arms off ends of bar
    SVG(`<line x1="5" y1="16" x2="27" y2="16"/><path d="M5 16 Q3 10 6 6 Q10 3 13 8 Q16 14 16 16"/><path d="M27 16 Q29 22 26 26 Q22 29 19 24 Q16 18 16 16"/><circle cx="16" cy="16" r="2.5" fill="currentColor"/>`),
    // Lenticular (S0) — edge-on flat disc, no spiral arms
    SVG(`<ellipse cx="16" cy="16" rx="13" ry="3.5"/><ellipse cx="16" cy="16" rx="8" ry="6"/><circle cx="16" cy="16" r="2" fill="currentColor"/>`),
    // Irregular — asymmetric scatter of star-knots
    SVG(`<circle cx="12" cy="12" r="2" fill="currentColor"/><circle cx="19" cy="10" r="2.5" fill="currentColor"/><circle cx="23" cy="16" r="1.8" fill="currentColor"/><circle cx="16" cy="20" r="2.8" fill="currentColor"/><circle cx="9" cy="20" r="1.5" fill="currentColor"/><circle cx="22" cy="23" r="1.8" fill="currentColor"/><circle cx="7" cy="14" r="1.2" fill="currentColor"/>`),
    // Ring galaxy (Hoag's Object) — outer ring, compact nucleus, gap in between
    SVG(`<circle cx="16" cy="16" r="12"/><circle cx="16" cy="16" r="4"/><circle cx="16" cy="16" r="2" fill="currentColor"/>`),
    // Colliding galaxies (Antennae) — two merging ellipses with tidal tails
    SVG(`<ellipse cx="12" cy="13" rx="7" ry="4" transform="rotate(-20 12 13)"/><ellipse cx="21" cy="20" rx="6" ry="4" transform="rotate(20 21 20)"/><path d="M10 8 Q13 3 21 5"/><path d="M23 24 Q25 29 20 31"/>`),
    // Dwarf galaxy — sparse cloud, dashed boundary, loose nucleus
    SVG(`<ellipse cx="16" cy="16" rx="12" ry="8" stroke-dasharray="3,3"/><circle cx="16" cy="16" r="2" fill="currentColor"/><circle cx="10" cy="14" r="1" fill="currentColor"/><circle cx="22" cy="15" r="1.2" fill="currentColor"/><circle cx="13" cy="20" r="0.9" fill="currentColor"/><circle cx="21" cy="20" r="0.9" fill="currentColor"/>`),
    // Quasar — blazing nucleus + bipolar relativistic jets
    SVG(`<circle cx="16" cy="16" r="4" fill="currentColor"/><circle cx="16" cy="16" r="8"/><line x1="16" y1="8" x2="16" y2="2"/><line x1="16" y1="24" x2="16" y2="30"/><line x1="20" y1="12" x2="26" y2="7"/><line x1="12" y1="20" x2="6" y2="25"/>`),
  ],
};

/* ---- G: Mixed Space Set ---- */
// Picks the most visually iconic symbol from each of B–F so a player
// gets variety in one set. References are by index into the arrays above.
const mixed = {
  name: 'Mixed Space',
  names: ['Saturn','Jupiter','Moon','Europa','Enceladus','Flying Saucer','Rocket','Spiral Galaxy','Saturn V'],
  svgs: [
    planets.svgs[5],     // Saturn  (ring planet — instantly iconic)
    planets.svgs[4],     // Jupiter (bands + red spot)
    moons.svgs[0],       // Earth's Moon (crescent)
    moons.svgs[1],       // Europa (ice cracks)
    moons.svgs[7],       // Enceladus (south-pole jets)
    spaceships.svgs[0],  // Flying Saucer (dome + disc)
    spaceships.svgs[2],  // Rocket (finned)
    galaxies.svgs[0],    // Spiral Galaxy
    aircraft.svgs[3],    // Saturn V (multi-stage)
  ],
};

export const SYMBOL_SETS = { alien, planets, moons, spaceships, aircraft, galaxies, mixed };
export const SYMBOL_SET_ORDER = ['alien','planets','moons','spaceships','aircraft','galaxies','mixed'];
