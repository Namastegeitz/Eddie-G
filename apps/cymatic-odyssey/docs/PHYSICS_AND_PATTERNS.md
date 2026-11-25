# Physics, light and pattern recognition: the research log

How vibrating water writes geometry in light, how to steer it, and how a computer can recognise what's on the wall. The numbers are in [PHYSICS_TABLES.md](PHYSICS_TABLES.md) (computed by `tools/physics_tables.py`).

## 1. How the water makes shapes

**Cymatics** (Hans Jenny's word, *Kymatik*, 1967) is the study of visible sound patterns. Ernst Chladni (1787) showed them with sand on vibrating plates. On water there are two different mechanisms, and this build uses both.

### 1a. Faraday waves (shake the whole dish)

Michael Faraday (1831) noticed that a liquid layer shaken up and down grows standing waves at **half** the shaking frequency. Benjamin and Ursell (1954) explained it as a parametric instability (a Mathieu equation): above a threshold acceleration, the flat surface becomes unstable and one wavelength wins.

- **Wavelength** comes from the capillary-gravity dispersion relation, omega^2 = (g k + sigma k^3 / rho) tanh(k h). At a 60 Hz drive, water waves are about 8.6 mm long. At 20 Hz they're about 22 mm.
- **Pattern** is chosen by nonlinear competition. Low-viscosity liquids like water favour **squares** (two crossed standing waves) near onset. Viscous liquids and shallow layers can give hexagons, and Binks and van de Water (1997) found 8-fold quasipatterns.
- **Two frequencies** open up much more. Edwards and Fauve (1993/94) drove a fluid with two frequencies in a 4:5 ratio and found a **12-fold quasipattern**: ordered, but never repeating, like a quasicrystal. Kudrolli, Pier and Gollub (1998) found **superlattices** with 6:7 forcing. Arbell and Fineberg (2002) mapped how the ratio and relative phase select squares, hexagons, triangles and more.
- **Threshold.** Patterns appear above a critical acceleration, about 0.1-0.6 g for water at 40-80 Hz. They're sharpest just above it and break into chaos and droplets at 2-3x it. That's why the console starts quiet.

### 1b. Boundary modes (the dish is a drum)

In a small dish at low frequency, the wavelength is comparable to the dish, and the **wall shape** decides the pattern. A circular dish gives Bessel modes J_m(kr)cos(m theta), with m nodal diameters and rings, at frequencies set by zeros of J_m' (the free-edge condition where water meets a vertical wall). Square plates give Chladni-type figures. These are what the **boundary inserts** exploit:

- **Regular polygons and stars** seed n-fold modes.
- **Integrable shapes** (circle, ellipse, rectangle, 30-60-90 triangle) give clean, predictable modes.
- **Chaotic billiards** (Bunimovich stadium 1979, Sinai billiard 1970, Robnik cardioid 1983) scramble modes into speckle with occasional "scars", bright paths along unstable periodic orbits (Heller 1984).
- **Mixed systems** (D-shape, Bunimovich mushroom 2001) mix ordered and chaotic regions in one dish.
- **Fractal drums** (Koch snowflake, Sapoval 1991) localise vibration in the fractal's nooks.
- Mark Kac asked in 1966 "Can one hear the shape of a drum?" Gordon, Webb and Wolpert (1992) proved no: two different shapes can share every frequency. (Their exact pair isn't included yet. The vertex coordinates need checking against the paper before printing.)

### 1c. Dipper waves (tap the surface)

A foot touching the surface radiates travelling waves at the drive frequency. A point gives circular rings: the **"pulsed outward"** look, especially with tone bursts (console *Pulse*). Two pins give Young's two-source interference (1801). Three or six pins give hexagonal lattices. A shaped foot (triangle, star, line) launches wavefronts with that shape. Reflections off the dish wall then mix the outgoing rings with incoming ones.

### 1d. Bonus: walking droplets (deep cut)

Just *below* the Faraday threshold, a droplet of the same liquid can bounce forever and even "walk" across the surface, steered by its own waves. This is the pilot-wave hydrodynamics of Couder, Protiere, Fort and Boudaoud (Nature 2005). It needs **silicone oil** (about 20 cSt) instead of water, at about 70-90 Hz. It's a beautiful extra for a science-centre version.

## 2. How the light makes shapes

A rippled water surface is an array of tiny lenses. Light through it bunches into bright **caustic** lines: the same network you see on a swimming-pool floor. Michael Berry's catastrophe optics (Berry and Upstill, 1980) shows these lines are universal shapes (folds, cusps). That's why the wall shows crisp lines, not soft shading.

Practical rules (all built into [BUILD_SPECS.md](BUILD_SPECS.md)):

1. **Small source = sharp lines.** A 2-3 mm LED die, not a big COB or a frosted bulb.
2. **Caustics focus a short distance above the water** (about 5-15 cm, shorter for bigger or finer waves). Image that plane with a lens (or an overhead projector) for a sharp, large picture.
3. **Brightness:** a few hundred lumens look magical in a dark room; 1000+ lm for a dim room at 2-3 m wide.

The console preview models exactly this: it computes the water height, its curvature (Hessian), and the intensity 1/|det(I + D * Hessian)| of rays bent by the surface. That's the standard small-slope caustic formula, so the preview's line networks behave like the real ones.

### 2a. Spectrum: splitting and intersecting colours

| Method | What it does | How to add it |
|---|---|---|
| **Chromatic parallax** | Three colour LEDs (R, G, B) about 15 mm apart each cast their own copy of the caustic web, slightly shifted. Where copies overlap you get white; where they separate you get coloured fringes that move with the water. | 3 LEDs on the cradle, ESP32 + WLED to set each colour |
| **Diffraction grating film** | Splits every bright line into rainbow spectra: d sin(theta) = m lambda. At 500 lines/mm, red goes to about 19 degrees and blue to about 13 degrees. At 1000 lines/mm, about 40 and 27 degrees. The central (0th) order stays white. | Tape film after the lens; 500 l/mm for a gentle spread |
| **Prism** | One smeared rainbow copy of the whole pattern | Glass prism in the beam after the mirror |
| **Polarisation colour (photoelasticity)** | Stressed clear plastic between two polarisers shows rainbow stress colours. **Print a gobo in clear PETG** and sandwich it: the printed lines glow in colour. Rotating one polariser shifts every colour. | Two polariser sheets + clear-PETG gobo |
| **Thin-film interference** | A soap film on a ring in the beam swirls with interference colours, and it vibrates with sound too | Wire ring + bubble mix, near the lens |
| **Dichroic filters** | Reflect one band and pass the complement: two walls, two colours | Dichroic glass at 45 degrees |
| **Gels** | Simple tints for themes | Rosco/Lee gel squares on the gobo carrier |

Colour should come from **light**, not dyed water. Dye dulls the caustics and stains the dish.

## 3. The geometry catalogue

[GEOMETRY_CATALOG.md](GEOMETRY_CATALOG.md) logs 355 printable looks across 26 families. Each entry has the maths that draws it, its symmetry, its historical or scientific source, and an STL (plus an SVG for the light stencils).

"Every geometrical shape known to man" is infinite: there's a regular polygon for every n, a star for every n/k, and a tiling for every symmetry group. So the catalogue is a **generator**, not a fixed list. Every family is parametric, and `tools/odyssey/catalog.py` takes one line to add a new member. The current set was chosen to span:

- **Classical:** polygons, star polygons, Platonic, Archimedean, Catalan, Kepler-Poinsot solids, compounds.
- **Curves:** roses, Lissajous figures, spirographs, cycloids, Cassini ovals, Gielis superformula, harmonographs, torus knots, spirals, phyllotaxis.
- **Cultural:** Flower/Seed/Fruit of Life, Metatron's Cube, vesica piscis, Borromean rings, enneagram, taijitu, yantra and mandala forms, Islamic girih star patterns (Hankin's polygons-in-contact method, as formalised by Kaplan 2005).
- **Deep cuts:** de Bruijn multigrid quasicrystals (Penrose, Ammann-Beenker, 7-, 9-, 12-fold); hyperbolic tilings in the Poincare disc (Escher's Circle Limit geometry); higher-dimensional polytopes in their Coxeter planes (4-8 dimensional cubes and cross-polytopes, 24-cell, 600-cell, 120-cell, and the root polytopes of F4, E6, E7, E8, including E8's 240-vertex, 6720-edge, 30-fold projection); real planetary orbital "dances" from NASA periods; prime and modular-arithmetic patterns.
- **The water's own patterns:** Chladni figures, free-edge Bessel modes, Faraday squares/hexagons/8-, 10-, 12-, 14-fold quasipatterns, superlattices, interference, Fresnel zone plates.
- **Fractals:** Koch, Sierpinski, Hilbert, Peano, Moore, dragon, Levy, Gosper, Vicsek, H-tree, Pythagoras tree, L-system plants, Apollonian gasket, Julia and Mandelbrot sets.

Computed checks (in `tests/test_tools.py`): all 13 Archimedean solids have the right vertex and edge counts (snubs found by solving for equal edges), the Catalan duals likewise, and the root systems close to exactly 48 (F4), 72 (E6), 126 (E7) and 240 (E8) roots.

**How the gobo and the water combine:** the gobo sits *before* the water, so its geometry is refracted by the moving surface. Straight lines bow, stars breathe, and lattices ripple, while the caustic web is drawn on top. A Faraday pattern seen through a matching gobo (hexagons through *Hankin 6.6.6*, 12-fold quasipattern through *Dodecagonal quasicrystal*) produces moire-like "intersecting geometries" that shift as the water drifts.

## 4. Pattern recognition and generation: the control system

### 4a. Recognising what's on the wall (`tools/pattern_analyzer.py`)

1. Window the camera frame and take its 2D FFT. The bright spots are the pattern's wave vectors.
2. Radial peak = dominant wavelength (in pixels, or millimetres if calibrated).
3. Angular harmonics on that ring: the strongest even harmonic n is the number of equally spaced wave directions. 2 = stripes, 4 = squares, 6 = hexagons, 8/10/12/14 = quasipatterns. A flat angular profile means rings or disorder.
4. Frame-to-frame correlation = stability (a locked standing pattern vs chaos).

The tests confirm it labels synthetic 2-, 4-, 6-, 8-, 10- and 12-fold patterns, rings and noise correctly.

### 4b. Mapping your system (`tools/mode_mapper.py`)

The mapper sweeps the frequency (optionally with a second tone at a fixed ratio), photographs the wall, labels each step and writes a **pattern atlas** CSV. It then reports the best frequency for each look. Your dish, depth, temperature and insert all shift these numbers, so map your own. The console imports the atlas and lets you jump to any logged look.

### 4c. Generating on purpose

| Technique | Effect |
|---|---|
| **Atlas jump** | Go straight to "hexagons" or "12-fold" from your own map |
| **Ratio forcing** (4:5, 6:7, 2:3, 1:2) | Select a symmetry class (Edwards and Fauve; Kudrolli et al.; Arbell and Fineberg) |
| **Detuned ratio** (e.g. tone B at 1.25 x f + 0.05 Hz) | The pattern slowly morphs and rotates at the detuning rate: a "drift" control |
| **Threshold riding** | Keep amplitude just above onset for the sharpest lines. A closed loop can do this automatically: raise the gain until the analyser reports a stable pattern, then back off 5% |
| **Pulse** (tone bursts) | Rings launched on the beat, the "pulsed outward" look |
| **Breathe** (slow swell, 0.1 Hz = 6 per minute) | The whole picture swells and settles on a breathing rhythm |
| **Insert swap** | A new boundary means new modes at low frequency |
| **Gobo + gobo** | Two gobos, one rotating (a small geared motor): live moire |
| **Music quantiser** (next step) | Raw music through an exciter mostly makes messy ripples. Instead, detect the beat and pitch of a song, then *snap* each note to the nearest atlas frequency with a clean pattern. The water then follows the song's rhythm while staying geometric. The console's voyages are hand-written versions of this idea. |
| **Machine learning** (next step) | Train a small classifier on synthetic patterns (the analyser's `synth()` plus the 300+ gobo renders) and labelled real frames. Or cluster FFT descriptors without labels to **discover** pattern classes nobody has named yet |

### 4d. The "space odyssey" voyage design language

Each voyage ([VOYAGES.md](VOYAGES.md)) follows an arc: **departure** (rings, cool colours) → **build** (standing lattices, rising density) → **peak** (quasipatterns, finest wavelength, full spectrum split) → **release** (slow pulses, warm colours) → **return**. Introspective voyages (Inner Mandala) hold the swell at 0.1 Hz (6 breaths a minute), the rate studied in slow-breathing research (see the market doc's health section), with sacred-geometry gobos as a visual anchor.

## 5. References

- Faraday, M. (1831). On a peculiar class of acoustical figures... *Phil. Trans. R. Soc.* 121, 299.
- Chladni, E.F.F. (1787). *Entdeckungen ueber die Theorie des Klanges.*
- Jenny, H. (1967). *Kymatik.*
- Benjamin, T.B. & Ursell, F. (1954). *Proc. R. Soc. A* 225, 505.
- Edwards, W.S. & Fauve, S. (1993). *Phys. Rev. E* 47, R788; (1994) *J. Fluid Mech.* 278, 123.
- Binks, D. & van de Water, W. (1997). *Phys. Rev. Lett.* 78, 4043.
- Kudrolli, A., Pier, B. & Gollub, J.P. (1998). Superlattice patterns in surface waves. *Physica D* 123, 99.
- Arbell, H. & Fineberg, J. (2002). *Phys. Rev. E* 65, 036224.
- Couder, Y., Protiere, S., Fort, E. & Boudaoud, A. (2005). *Nature* 437, 208.
- Berry, M.V. & Upstill, C. (1980). Catastrophe optics. *Progress in Optics* 18.
- Rayleigh, Lord (1877). *The Theory of Sound.*
- Kac, M. (1966). Can one hear the shape of a drum? *Am. Math. Monthly* 73.
- Gordon, C., Webb, D. & Wolpert, S. (1992). *Bull. AMS* 27.
- Bunimovich, L.A. (1979); Sinai, Ya.G. (1970); Robnik, M. (1983); Heller, E.J. (1984), *Phys. Rev. Lett.* 53, 1515.
- de Bruijn, N.G. (1981). *Indagationes Math.* 43; Penrose, R. (1974).
- Kaplan, C.S. (2005). Islamic star patterns from polygons in contact. *Graphics Interface.*
- Lu, P.J. & Steinhardt, P.J. (2007). Decagonal and quasi-crystalline tilings in medieval Islamic architecture. *Science* 315, 1106.
- Coxeter, H.S.M. (1973). *Regular Polytopes.*
- Gielis, J. (2003). *American Journal of Botany* 90(3).
- Vogel, H. (1979). *Mathematical Biosciences* 44.
