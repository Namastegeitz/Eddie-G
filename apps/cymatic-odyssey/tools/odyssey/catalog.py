"""The CYMATIC ODYSSEY shape registry: every printable look, with its maths and sources."""
from __future__ import annotations

from math import pi

import numpy as np
from shapely.geometry import Point, Polygon, box
from shapely.ops import unary_union

from . import curves as C, fractals as F, physics as P, tilings as T, polyhedra as H, polytopes as X
from .core import Design, circle, ngon, poly_region, PHI, TAU

FAMILIES = {
    "polygons": dict(title="Regular polygons", ref="Euclid, Elements Book IV; Gauss (1796) constructible 17-gon",
                     look="Clean n-sided frames; through rippling water the edges shimmer and bow."),
    "stars": dict(title="Star polygons {n/k}", ref="Schlaefli symbols; H.S.M. Coxeter, Regular Polytopes (1973)",
                  look="Pointed stars and compound stars; strong radial beams on the wall."),
    "roses": dict(title="Rose curves r = cos(k theta)", ref="Guido Grandi, 'Flores geometrici' (1728)",
                  look="Petalled flowers; integer k gives k or 2k petals, fractional k weaves overlapping petals."),
    "lissajous": dict(title="Lissajous figures (frequency ratios)", ref="N. Bowditch (1815); J.A. Lissajous (1857)",
                      look="The picture of two frequencies at a ratio - the same ratios the Voyage console plays."),
    "spirographs": dict(title="Hypotrochoids and epitrochoids", ref="Roulette curves; Denys Fisher's Spirograph (1965)",
                        look="Looping gear-drawn lace; dense rings that read as rotating halos."),
    "classical": dict(title="Classical plane curves", ref="Cardioid (Castillon 1741), nephroid (Huygens), deltoid (Euler 1745), astroid (Roemer 1674), lemniscate (J. Bernoulli 1694), Cassini ovals (1680)",
                      look="Single elegant outlines - hearts, kidneys, cusped stars, infinity loops."),
    "superformula": dict(title="Gielis superformula & superellipses", ref="J. Gielis, American Journal of Botany 90(3) 2003; G. Lame (1818); Piet Hein",
                         look="Organic starfish, shells, squircles - one equation, endless natural forms."),
    "harmonographs": dict(title="Harmonographs", ref="Hugh Blackburn (1844); Jules Lissajous",
                          look="Decaying pendulum spirals - feathery, hypnotic, slightly off-symmetric."),
    "knots": dict(title="Torus knots (p,q)", ref="P.G. Tait knot tables (1876); Lord Kelvin's vortex atoms",
                  look="Interwoven loops - trefoil, cinquefoil, star knots."),
    "spirals": dict(title="Spirals & phyllotaxis", ref="Fibonacci (1202); Jakob Bernoulli 'spira mirabilis'; H. Vogel, Mathematical Biosciences 44 (1979)",
                    look="Golden spiral, galaxy arms, sunflower seed heads - natural growth patterns."),
    "sacred": dict(title="Sacred & cultural geometry", ref="Flower of Life (Abydos, Egypt); Metatron's Cube; Borromean rings; taijitu; enneagram (Gurdjieff); yantra & mandala traditions",
                   look="Interlaced circles and lattices with a ceremonial, meditative feel."),
    "number": dict(title="Number patterns", ref="Complete graphs ('mystic rose'); modular times tables (cardioid envelope); L.R. Ford, Am. Math. Monthly (1938); R. Sacks prime spiral (1994)",
                   look="Mathematics made visible - cardioids appearing out of arithmetic, prime spirals."),
    "cosmic": dict(title="Cosmic dance (real planetary periods)", ref="NASA Planetary Fact Sheet sidereal periods; Venus 8-year pentagram (13 Venus orbits in 8 Earth years)",
                   look="Orbital roses traced by real planets - the space-odyssey series."),
    "physics": dict(title="Cymatics & wave physics", ref="E. Chladni (1787); Lord Rayleigh, Theory of Sound (1877); M. Faraday (1831); W.S. Edwards & S. Fauve, Phys. Rev. E 47, R788 (1993); A. Kudrolli, B. Pier, J.P. Gollub, Physica D 123 (1998)",
                    look="The patterns water itself makes - printed so the light can show them even when the water is still."),
    "optics": dict(title="Optical elements", ref="Fresnel zone plate (Fresnel 1818; Soret 1875); moire (Rayleigh 1874)",
                   look="Zone plates focus light into bright rings; line gratings make moire when two are stacked or rotated."),
    "tilings": dict(title="Archimedean tilings", ref="J. Kepler, Harmonices Mundi (1619); Wythoff construction (1918)",
                    look="Endless honeycomb, kagome and octagon floors - wallpaper of light."),
    "islamic": dict(title="Islamic star patterns (Hankin method)", ref="E.H. Hankin (1925); C.S. Kaplan, 'Islamic star patterns from polygons in contact', Graphics Interface (2005)",
                    look="Interlocking rosettes and stars from the girih tradition, generated from tilings."),
    "quasicrystal": dict(title="Quasicrystal tilings (de Bruijn multigrid)", ref="R. Penrose (1974); N.G. de Bruijn, Indagationes Math. 43 (1981); F. Beenker (1982); D. Shechtman (Nobel 2011)",
                         look="Ordered but never repeating - 5-, 7-, 8- and 12-fold symmetry; matches the 12-fold quasipatterns two-frequency driving makes in water."),
    "hyperbolic": dict(title="Hyperbolic tilings {p,q} (Poincare disc)", ref="H. Poincare; H.S.M. Coxeter (1957); M.C. Escher, Circle Limit I-IV (1958-60)",
                       look="Tiles that shrink forever toward the rim - an infinite universe in a circle."),
    "platonic": dict(title="Platonic solids (3 views each)", ref="Plato, Timaeus; Euclid, Elements XIII",
                     look="Wireframe shadows of the five perfect solids, seen down vertex, edge and face axes."),
    "archimedean": dict(title="Archimedean solids", ref="Archimedes (via Pappus); J. Kepler (1619); M. Wenninger, Polyhedron Models (1971)",
                        look="Faceted spheres - soccer ball, snub cube, great rhombicosidodecahedron - as lace."),
    "catalan": dict(title="Catalan solids (Archimedean duals)", ref="E. Catalan (1865)",
                    look="Star-burst duals of the Archimedean solids; dense radiating webs."),
    "stellated": dict(title="Kepler-Poinsot solids & compounds", ref="J. Kepler (1619); L. Poinsot (1809); E. Hess (1876); M.C. Escher 'Waterfall' (1961)",
                      look="Star solids and interpenetrating compounds - sharp, crystalline, cathedral-like."),
    "polytopes4d": dict(title="4D+ polytopes in Coxeter planes", ref="L. Schlaefli (1852); H.S.M. Coxeter, Regular Polytopes (1973); T. Gosset (1900); P. McMullen (E8 drawing)",
                        look="Shadows of higher-dimensional objects - tesseract, 600-cell, 120-cell, and E8's famous 30-fold rose."),
    "fractals": dict(title="Fractals & space-filling curves", ref="H. von Koch (1904); W. Sierpinski (1915-16); D. Hilbert (1891); G. Peano (1890); J. Heighway (1966); P. Levy (1938); W. Gosper (1973); T. Vicsek (1983); A. Lindenmayer (1968); G. Julia (1918); B. Mandelbrot (1980)",
                     look="Self-similar detail at every scale - coastlines, snowflakes, ferns, Julia lace."),
    # inserts + dippers
    "insert": dict(title="Boundary inserts (the water's 'drum shape')", ref="Rayleigh (1877); Bunimovich (1979); Ya. Sinai (1970); M. Robnik (1983); B. Sapoval, fractal drums (1991); M. Kac, 'Can one hear the shape of a drum?' (1966)",
                   look="Changes the standing-wave modes the water can make. Small dishes and low frequencies follow the wall shape; chaotic billiards scramble them into speckle."),
    "dipper": dict(title="Dipper feet (wave sources)", ref="Thomas Young two-source interference (1801); ripple-tank practice",
                   look="Shapes the wave that is pushed into the water: rings pulse outward from a point, two pins interfere, a triangle launches triangular wavefronts."),
}


REG = []


def add(name, family, fn, math, symmetry="", part="gobo", look="", palette=""):
    REG.append(dict(name=name, family=family, fn=fn, math=math, symmetry=symmetry, part=part,
                    look=look, palette=palette))


def _sym_d(n):
    return f"D{n} (dihedral, {n}-fold)"


# ---------------------------------------------------------------- polygons & stars
POLY_NAMES = {3: "Triangle", 4: "Square", 5: "Pentagon", 6: "Hexagon", 7: "Heptagon", 8: "Octagon",
              9: "Nonagon", 10: "Decagon", 11: "Hendecagon", 12: "Dodecagon", 17: "Heptadecagon (Gauss)"}
for n, nm in POLY_NAMES.items():
    add(f"{nm} nest", "polygons", lambda n=n: C.regular_polygon(n, nested=6), f"Regular {n}-gon, 6 nested rings alternately rotated pi/{n}", _sym_d(n))
for n, k, nm in [(5, 2, "Pentagram"), (6, 2, "Hexagram (Star of David)"), (7, 2, "Heptagram {7/2}"), (7, 3, "Heptagram {7/3}"),
                 (8, 2, "Octagram compound {8/2}"), (8, 3, "Octagram {8/3}"), (9, 2, "Enneagram {9/2}"), (9, 4, "Enneagram {9/4}"),
                 (10, 3, "Decagram {10/3}"), (11, 3, "Hendecagram {11/3}"), (12, 5, "Dodecagram {12/5}"), (12, 4, "Triple square {12/4}"),
                 (16, 7, "Hexadecagram {16/7}"), (24, 11, "Icositetragram {24/11}")]:
    add(nm, "stars", lambda n=n, k=k: C.star_polygon(n, k), f"Star polygon {{{n}/{k}}}: join every {k}th of {n} points", _sym_d(n))

# ---------------------------------------------------------------- curves
for n, d_ in [(2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1), (3, 2), (5, 2), (7, 3), (5, 4), (8, 5), (9, 7), (11, 6)]:
    add(f"Rose {n}/{d_}", "roses", lambda n=n, d_=d_: C.rose(n, d_), f"r = cos({n}/{d_} theta)",
        _sym_d(n if (n * d_) % 2 else 2 * n))
for a, b in [(1, 2), (2, 3), (3, 4), (3, 5), (4, 5), (5, 6), (5, 8), (6, 7), (7, 9), (8, 13)]:
    add(f"Lissajous {a}:{b}", "lissajous", lambda a=a, b=b: C.lissajous(a, b), f"x = sin({a}t + pi/2), y = sin({b}t)", "D2")
for R, r, d_ in [(5, 3, 5), (7, 3, 2), (8, 5, 5), (9, 4, 6), (11, 7, 8), (13, 8, 6), (17, 11, 9), (24, 7, 10)]:
    add(f"Spirograph R{R} r{r} d{d_}", "spirographs", lambda R=R, r=r, d_=d_: C.hypotrochoid(R, r, d_), f"Hypotrochoid R={R}, r={r}, d={d_}")
for R, r, d_ in [(5, 2, 3), (7, 4, 6), (10, 3, 5), (13, 6, 8)]:
    add(f"Epitrochoid R{R} r{r} d{d_}", "spirographs", lambda R=R, r=r, d_=d_: C.epitrochoid(R, r, d_), f"Epitrochoid R={R}, r={r}, d={d_}")
for k in ["cardioid", "nephroid", "deltoid", "astroid", "limacon", "lemniscate", "heart"]:
    add(k.capitalize(), "classical", lambda k=k: C.cycloid_family(k), f"Classical curve: {k}")
add("Cardioid from circles", "classical", C.envelope_cardioid, "Envelope of 72 circles centred on a circle, all through one point")
add("Cassini ovals", "classical", C.cassini, "|z-1||z+1| = b^2 for six values of b (incl. the lemniscate b=1)", "D2")
for nm, args in [("Starfish 5", (5, 2, 7, 7)), ("Shell 3", (3, 4.5, 10, 10)), ("Blossom 6", (6, 1, 1, 6)), ("Gear 12", (12, 15, 20, 3)),
                 ("Cross 4", (4, 12, 15, 15)), ("Lotus 8", (8, 1, 1, 8)), ("Sea star 7", (7, 0.2, 1.7, 1.7)), ("Clover 3", (3, 1, 1, 1))]:
    add(f"Superformula {nm}", "superformula", lambda args=args: C.superformula(*args), f"Gielis superformula m={args[0]}, n1={args[1]}, n2={args[2]}, n3={args[3]}")
for nn in (0.6, 2.5, 4, 8):
    add(f"Superellipse n={nn}", "superformula", lambda nn=nn: C.superellipse(nn), f"|x|^{nn} + |y|^{nn} = 1")
for f in [(2, 3, 2.01, 3.01), (3, 2, 3.003, 1.997), (4, 5, 4.002, 5.0), (1, 1.5, 1.003, 1.502)]:
    add(f"Harmonograph {f[0]}:{f[1]}", "harmonographs", lambda f=f: C.harmonograph(*f), f"Damped sum of sines, frequencies {f}")
for p, q in [(2, 3), (2, 5), (3, 5), (3, 7), (2, 7), (5, 8)]:
    add(f"Torus knot ({p},{q})", "knots", lambda p=p, q=q: C.torus_knot(p, q), f"r = 2 + cos({q}t), angle = {p}t", _sym_d(p))
add("Golden spiral & Fibonacci squares", "spirals", C.golden_spiral, "Quarter-circle arcs in squares of side 1,1,2,3,5,8,...")
add("Galaxy arms", "spirals", C.log_spiral_arms, "8 logarithmic spirals each way, r = e^(0.18 theta)", "C8")
add("Archimedean spiral x3", "spirals", lambda: C.archimedean_spiral(8, 3), "r = a theta, three arms", "C3")
add("Fermat spiral", "spirals", C.fermat_spiral, "r = +-sqrt(theta)", "C2")
add("Sunflower phyllotaxis", "spirals", C.phyllotaxis, "Vogel model: seed n at r = sqrt(n), angle n x 137.508 degrees (golden angle)")
add("Phyllotaxis 137.3 (off-golden)", "spirals", lambda: C.phyllotaxis(angle_deg=137.3), "Same with a slightly wrong angle: spokes appear")

# ---------------------------------------------------------------- sacred
add("Seed of Life", "sacred", C.seed_of_life, "7 equal circles, 6 centred on the first", "D6")
add("Flower of Life", "sacred", C.flower_of_life, "19 circles on a hexagonal lattice inside a bounding circle", "D6")
add("Fruit of Life", "sacred", lambda: C.fruit_of_life()[0], "13 circles: centre + two hex rings at 2r and 4r", "D6")
add("Metatron's Cube", "sacred", C.metatrons_cube, "Fruit of Life with all 78 centre-to-centre lines", "D6")
add("Vesica Piscis", "sacred", C.vesica_piscis, "Two circles through each other's centres; ratio sqrt(3)", "D2")
add("Borromean rings", "sacred", C.borromean, "Three circles, no two linked, all three inseparable", "D3")
add("Torus of circles", "sacred", C.torus_circles, "24 circles through the centre (the 2D 'torus' figure)", "D24")
add("Enneagram", "sacred", C.enneagram, "Circle, triangle 3-6-9 and the 1-4-2-8-5-7 hexad (1/7 decimal cycle)")
add("Taijitu (yin-yang)", "sacred", C.yin_yang, "Circle split by two semicircles, with two eyes", "C2")
add("Nine-triangle yantra (simplified)", "sacred", C.sri_yantra_style, "Four upward and five downward triangles with lotus rings - simplified, not canonical proportions", "D1")
for n in (8, 12, 16):
    add(f"Petal mandala {n}", "sacred", lambda n=n: C.mandala(n), f"Procedural petal rings, {n}-fold", _sym_d(n))

# ---------------------------------------------------------------- number
for n in (7, 11, 17, 24):
    add(f"Mystic rose K{n}", "number", lambda n=n: C.mystic_rose(n), f"Complete graph on {n} points of a circle (also the Petrie view of the {n - 1}-simplex)", _sym_d(n))
for k in (2, 3, 4, 5, 21, 34, 51, 68):
    add(f"Times table x{k}", "number", lambda k=k: C.times_table(k), f"180 points; join i to {k}*i mod 180 (x2 cardioid, x3 nephroid)")
add("Ford circles", "number", C.ford_circles, "Circle at p/q with radius 1/(2q^2): every rational, all tangent")
add("Sacks prime spiral", "number", C.ulam_rays, "Prime p at radius sqrt(p), angle 2 pi sqrt(p)")

# ---------------------------------------------------------------- cosmic
for a, b in [("Venus", "Earth"), ("Mercury", "Venus"), ("Earth", "Mars"), ("Mercury", "Earth"), ("Mars", "Jupiter"),
             ("Jupiter", "Saturn"), ("Saturn", "Uranus"), ("Uranus", "Neptune")]:
    add(f"Cosmic dance {a}-{b}", "cosmic", lambda a=a, b=b: C.cosmic_dance(a, b), f"Lines between {a} and {b} at equal time steps (circular orbits, real periods)")
for pl, yrs in [("Venus", 8), ("Mercury", 3), ("Mars", 15), ("Jupiter", 12), ("Saturn", 29.5)]:
    add(f"Geocentric {pl}", "cosmic", lambda pl=pl, yrs=yrs: C.geocentric(pl, yrs), f"{pl}'s path as seen from Earth over {yrs} years (retrograde loops)")
add("Saturn's hexagon", "cosmic", C.saturn_hexagon, "Nested hexagonal jet stream at Saturn's north pole (Voyager 1981, Cassini)", "C6")

# ---------------------------------------------------------------- physics
for n, m in [(1, 2), (1, 3), (2, 3), (1, 5), (2, 5), (3, 5), (3, 7), (4, 7)]:
    add(f"Chladni square ({n},{m}) anti", "physics", lambda n=n, m=m: P.chladni_square(n, m, -1), f"Nodal lines of cos({n}pi x)cos({m}pi y) - cos({m}pi x)cos({n}pi y)")
for n, m in [(1, 3), (2, 4), (3, 5), (2, 6)]:
    add(f"Chladni square ({n},{m}) sym", "physics", lambda n=n, m=m: P.chladni_square(n, m, +1), f"Nodal lines of cos({n}pi x)cos({m}pi y) + cos({m}pi x)cos({n}pi y)")
for m, n in [(0, 4), (1, 3), (2, 3), (3, 2), (4, 3), (5, 2), (6, 3), (8, 2)]:
    add(f"Water mode J{m} ring {n}", "physics", lambda m=m, n=n: P.bessel_mode(m, n), f"Nodal lines of J_{m}(k r) cos({m} theta), k from the {n}th zero of J_{m}' (free edge)", _sym_d(max(2 * m, 1)))
for nw, nm in [(2, "squares"), (3, "hexagons"), (4, "8-fold quasipattern"), (5, "10-fold quasipattern"), (6, "12-fold quasipattern"), (7, "14-fold quasipattern")]:
    add(f"Faraday {nm}", "physics", lambda nw=nw: P.faraday_quasipattern(nw), f"Zero contour of the sum of {nw} standing plane waves at {180 // nw} degree steps", f"D{2 * nw}")
add("Faraday hexagons (phase-shifted triangles)", "physics", lambda: P.faraday_quasipattern(3, level=0.8), "Contour of 3-wave sum at 0.8 (triangles/hexagon cells)", "D6")
add("Superlattice 6:7", "physics", P.superlattice, "Two hexagonal wave sets at wavenumber ratio 7/6 (two-frequency forcing)")
add("Two-source interference", "physics", lambda: P.interference([(-0.18, 0), (0.18, 0)]), "Crests of circular waves from two pins", "D2")
add("Three-source interference", "physics", lambda: P.interference([(0.2 * np.cos(a), 0.2 * np.sin(a)) for a in pi / 2 + TAU * np.arange(3) / 3]), "Crests from three pins at 120 degrees", "D3")
add("Pulse rings (J0)", "physics", P.standing_ring_wave, "Zero contour of J0(k r): rings radiating from a centre pulse", "O(2)")
add("Fresnel zone plate", "optics", C.fresnel_zone_plate, "Opaque zones between radii sqrt(k/N): focuses light like a lens")
for a in (0, 3, 6):
    add(f"Moire grating {a} deg", "optics", lambda a=a: C.moire_lines(a), f"Parallel lines rotated {a} degrees - stack two for moire")
add("Concentric rings", "optics", C.concentric, "14 equally spaced circles (Newton-ring look)", "O(2)")
add("Sunburst 36", "optics", C.radial, "36 radial spokes", "D36")

# ---------------------------------------------------------------- tilings
for nm in ["4.4.4.4", "3.3.3.3.3.3", "6.6.6", "3.6.3.6", "3.12.12", "3.4.6.4", "4.6.12", "4.8.8"]:
    add(f"Tiling {nm}", "tilings", lambda nm=nm: T.tiling_design(nm), f"Uniform tiling with vertex configuration {nm}, Wythoff construction")
for nm, deg in [("4.4.4.4", 67.5), ("6.6.6", 60), ("3.6.3.6", 60), ("4.8.8", 67.5), ("3.12.12", 60), ("4.6.12", 60), ("3.4.6.4", 60), ("3.12.12", 75)]:
    add(f"Hankin {nm} at {deg} deg", "islamic", lambda nm=nm, deg=deg: T.tiling_design(nm, hankin_deg=deg), f"Hankin rays at {deg} degrees from edge midpoints of tiling {nm}")
for n, nm in [(5, "Penrose rhombus (P3)"), (7, "Heptagonal"), (8, "Ammann-Beenker octagonal"), (9, "Enneagonal"), (12, "Dodecagonal")]:
    add(f"{nm} quasicrystal", "quasicrystal", lambda n=n: T.multigrid_design(n), f"de Bruijn {n}-grid dual tiling (rhombi)", f"{2 * n if n % 2 else n}-fold (statistical)")
for n, deg in [(5, 72), (5, 54), (8, 67.5), (12, 75)]:
    add(f"Quasicrystal girih {n}-fold at {deg} deg", "islamic", lambda n=n, deg=deg: T.multigrid_design(n, hankin_deg=deg), f"Hankin rays at {deg} degrees on the {n}-grid rhombus tiling")
for p, q in [(7, 3), (3, 7), (5, 4), (4, 5), (6, 4), (4, 6), (8, 3), (5, 5)]:
    add(f"Hyperbolic {{{p},{q}}}", "hyperbolic", lambda p=p, q=q: T.hyperbolic_tiling(p, q), f"Regular tiling by {p}-gons, {q} at each vertex, in the Poincare disc", _sym_d(p))
add("Hyperbolic {7,3} dual net", "hyperbolic", lambda: T.hyperbolic_tiling(3, 7, dual=True), "Centres of {3,7} triangles joined (equivalent to {7,3})", "D7")

# ---------------------------------------------------------------- polyhedra
for nm in ["Tetrahedron", "Cube", "Octahedron", "Dodecahedron", "Icosahedron"]:
    for view in ("vertex", "edge", "face"):
        add(f"{nm} ({view} view)", "platonic", lambda nm=nm, view=view: H.wire_design(*H.platonic(nm), H.symmetry_axes(H.solid_family_base(nm))[view]),
            f"Orthographic wireframe of the {nm.lower()} along a {view}-centre axis")
for nm in H.ARCHIMEDEAN:
    add(nm, "archimedean", lambda nm=nm: H.wire_design(*H.archimedean(nm), H.symmetry_axes(H.solid_family_base(nm))["vertex"]),
        "Wythoff construction (snubs by solving for equal edges); view down the highest-order axis")
for nm in H.CATALAN:
    add(nm, "catalan", lambda nm=nm: H.wire_design(*H.catalan(nm), H.symmetry_axes(H.solid_family_base(nm))["vertex"]),
        f"Polar dual of the {H.CATALAN[nm].lower()}")
for nm in ["Small stellated dodecahedron", "Great stellated dodecahedron", "Great dodecahedron"]:
    add(nm, "stellated", lambda nm=nm: H.wire_design(*H.kepler_poinsot(nm), H.symmetry_axes("icosa")["vertex"]),
        "Kepler-Poinsot star polyhedron edge skeleton (the great icosahedron shares the first's skeleton)")
for nm in ["Stella octangula", "Cube and octahedron", "Dodecahedron and icosahedron", "Compound of five tetrahedra",
           "Compound of ten tetrahedra", "Compound of five cubes", "Compound of five octahedra"]:
    base = "octa" if nm in ("Stella octangula", "Cube and octahedron") else "icosa"
    add(nm, "stellated", lambda nm=nm, base=base: H.wire_design(*H.compound(nm), H.symmetry_axes(base)["face" if base == "octa" else "vertex"]),
        "Polyhedron compound generated by the symmetry group")
add("Merkaba (star tetrahedron, 3-fold)", "stellated", lambda: H.wire_design(*H.compound("Stella octangula"), np.array([1, 1, 1.0])), "Stella octangula seen down a body diagonal", "D6")

# ---------------------------------------------------------------- higher dimensions
for n in range(4, 9):
    add(f"{n}-cube (hypercube)", "polytopes4d", lambda n=n: X.hypercube(n), f"{2 ** n} vertices of the {n}-cube in the B{n} Coxeter plane", f"D{2 * n}")
for n in range(4, 9):
    add(f"{n}-orthoplex (cross-polytope)", "polytopes4d", lambda n=n: X.cross_polytope(n), f"{2 * n} vertices of the {n}-dimensional cross-polytope", f"D{2 * n}")
for n in (5, 6):
    add(f"{n}-demicube", "polytopes4d", lambda n=n: X.demicube(n), f"Alternated {n}-cube", f"D{2 * n}")
add("5-cell (4-simplex)", "polytopes4d", X.cell5, "Regular 4-simplex; Petrie polygon is a pentagon", "D5")
add("24-cell", "polytopes4d", X.cell24, "24 unit Hurwitz quaternions; Coxeter plane of F4 (12-fold)", "D12")
add("600-cell", "polytopes4d", lambda: X.cell600("600"), "120 unit icosians (binary icosahedral group); H4 Coxeter plane (30-fold)", "D30")
add("120-cell", "polytopes4d", lambda: X.cell600("120"), "600 cell-centres of the 600-cell; H4 Coxeter plane", "D30")
for nm, n in [("F4", 48), ("E6", 72), ("E7", 126), ("E8", 240)]:
    add(f"{nm} root polytope", "polytopes4d", lambda nm=nm: X.root_polytope(nm), f"{n} roots of {nm} projected to its Coxeter plane" + (" (Gosset 4_21)" if nm == "E8" else ""))

# ---------------------------------------------------------------- fractals
for lv in (2, 3, 5):
    add(f"Koch snowflake L{lv}", "fractals", lambda lv=lv: F.koch_snowflake(lv), f"Koch curve x3, {lv} iterations; perimeter grows (4/3)^n", "D6")
add("Koch anti-snowflake", "fractals", F.koch_antisnowflake, "Koch curve folded inward", "D6")
add("Sierpinski triangle", "fractals", F.sierpinski_triangle, "6 levels of triangle subdivision (dimension log3/log2)", "D3")
add("Sierpinski arrowhead", "fractals", F.sierpinski_arrowhead, "L-system arrowhead curve, order 6", "D3")
add("Sierpinski carpet", "fractals", F.sierpinski_carpet, "Remove the centre ninth, 4 levels", "D4")
add("Vicsek cross", "fractals", F.vicsek, "Keep the centre and corners, 4 levels", "D4")
add("Hilbert curve", "fractals", F.hilbert, "Space-filling curve, order 5")
add("Moore curve", "fractals", F.moore, "Closed Hilbert variant, order 4")
add("Peano curve", "fractals", F.peano, "Original space-filling curve, order 3")
add("Heighway dragon", "fractals", F.dragon, "Paper-folding dragon, 12 folds")
add("Levy C curve", "fractals", F.levy_c, "Levy C curve, order 10")
add("Gosper flowsnake", "fractals", F.gosper, "Peano-Gosper curve, order 4")
add("H-tree", "fractals", F.h_tree, "Each segment branches into two at 1/sqrt(2) length", "D2")
add("Pythagoras tree", "fractals", F.pythagoras_tree, "Squares on right isosceles triangles, 9 levels")
add("Fractal plant (L-system)", "fractals", F.fractal_plant, "Lindenmayer fern-like plant, 5 generations")
add("Apollonian gasket", "fractals", F.apollonian, "Descartes circle theorem (complex form) recursion", "D3")
for nm, c in [("Douady rabbit", -0.123 + 0.745j), ("Dendrite", 1j), ("San Marco", -0.75 + 0j), ("Siegel disc", -0.391 - 0.587j), ("Spiral", 0.285 + 0.01j)]:
    add(f"Julia set - {nm}", "fractals", lambda c=c: F.julia(c), f"Escape-time contours of z -> z^2 + ({c.real:+.3f}{c.imag:+.3f}i)")
add("Mandelbrot set", "fractals", F.mandelbrot, "Escape-time contours of z -> z^2 + c")


# ---------------------------------------------------------------- boundary inserts
def _ins(name, fn, math):
    add(name, "insert", fn, math, part="insert")


for n in range(3, 13):
    _ins(f"Insert {POLY_NAMES[n].lower()}", lambda n=n: C.regular_polygon(n), f"Regular {n}-gon cavity")
for n, k in [(5, 2), (6, 2), (7, 3), (8, 3)]:
    _ins(f"Insert star {{{n}/{k}}}", lambda n=n, k=k: C.star_polygon(n, k), f"Star {{{n}/{k}}} outline cavity")
for n in (3, 5, 7):
    _ins(f"Insert Reuleaux {n}", lambda n=n: C.reuleaux(n), f"Reuleaux {n}-gon: constant width")


def _region_design(poly):
    d = Design(lines=[np.asarray(poly.exterior.coords)])
    d.region = poly
    return d


_ins("Insert circle (reference)", lambda: _region_design(Point(0, 0).buffer(1, 256)), "Circle: clean Bessel modes")
for a in (1.5, 2.0):
    _ins(f"Insert ellipse {a}:1", lambda a=a: _region_design(Polygon(np.c_[a * np.cos(np.linspace(0, TAU, 400)), np.sin(np.linspace(0, TAU, 400))])), f"Ellipse with axis ratio {a} (integrable billiard)")
_ins("Insert Bunimovich stadium", lambda: _region_design(box(-0.5, -0.5, 0.5, 0.5).union(Point(-0.5, 0).buffer(0.5, 128)).union(Point(0.5, 0).buffer(0.5, 128))), "Two semicircles joined by straight sides (fully chaotic billiard)")
_ins("Insert cardioid billiard", lambda: C.cycloid_family("cardioid"), "Cardioid (Robnik billiard, chaotic)")
_ins("Insert Sinai billiard", lambda: _region_design(box(-1, -1, 1, 1).difference(Point(0, 0).buffer(0.38, 128))), "Square with a central disc obstacle (the post prints as a loose piece: glue it down)")
_ins("Insert annulus", lambda: _region_design(Point(0, 0).buffer(1, 256).difference(Point(0, 0).buffer(0.35, 128))), "Ring channel (loose centre post)")
_ins("Insert D-billiard", lambda: _region_design(Point(0, 0).buffer(1, 256).intersection(box(-1, -1, 1, 0.55))), "Circle with a flat cut (mixed regular/chaotic)")
_ins("Insert mushroom billiard", lambda: _region_design(Point(0, 0.2).buffer(1, 256).intersection(box(-1, 0.2, 1, 1.3)).union(box(-0.3, -0.9, 0.3, 0.21))), "Bunimovich mushroom: semicircle cap on a stem (separated chaos)")
for nn in (4, 0.7):
    _ins(f"Insert superellipse n={nn}", lambda nn=nn: C.superellipse(nn), f"|x|^{nn} + |y|^{nn} = 1")
_ins("Insert Koch snowflake", lambda: F.koch_snowflake(3), "Koch level 3 fractal drum (Sapoval)")
for n in (5, 6, 8, 12):
    _ins(f"Insert wavy {n}", lambda n=n: _region_design(Polygon(np.c_[(1 + 0.12 * np.cos(n * np.linspace(0, TAU, 600))) * np.cos(np.linspace(0, TAU, 600)), (1 + 0.12 * np.cos(n * np.linspace(0, TAU, 600))) * np.sin(np.linspace(0, TAU, 600))])), f"r = 1 + 0.12 cos({n} theta): seeds {n}-fold modes")
_ins("Insert heart", lambda: C.cycloid_family("heart"), "Heart curve")
_ins("Insert 30-60-90 triangle", lambda: _region_design(Polygon([(0, 0), (3 ** 0.5, 0), (0, 1)])), "Hemi-equilateral triangle (integrable, modes known exactly)")
_ins("Insert golden rectangle", lambda: _region_design(box(-PHI / 2, -0.5, PHI / 2, 0.5)), "Rectangle with ratio phi")
_ins("Insert superformula starfish", lambda: C.superformula(5, 2, 7, 7), "Gielis starfish outline")


# ---------------------------------------------------------------- dippers
def _dip(name, region, math, size=None):
    def fn(region=region):
        d = Design(lines=[np.zeros((0, 2))])
        d.region = region() if callable(region) else region
        d.size = size
        return d
    add(name, "dipper", fn, math, part="dipper")


_dip("Dipper point", lambda: Point(0, 0).buffer(1, 64), "6 mm disc: a single point source - rings pulse outward", 6)
_dip("Dipper disc 25", lambda: Point(0, 0).buffer(1, 128), "25 mm disc: stronger, smoother rings", 25)
_dip("Dipper ring", lambda: Point(0, 0).buffer(1, 128).difference(Point(0, 0).buffer(0.75, 128)), "Ring: launches inward and outward waves that focus at the centre", 30)
_dip("Dipper line", lambda: box(-1, -0.06, 1, 0.06), "Bar: plane waves to both sides", 30)
_dip("Dipper cross", lambda: box(-1, -0.08, 1, 0.08).union(box(-0.08, -1, 0.08, 1)), "Cross: four plane-wave fronts", 30)
for n in (3, 4, 6):
    _dip(f"Dipper {POLY_NAMES[n].lower()}", lambda n=n: poly_region(ngon(n, 1)[:-1]), f"{POLY_NAMES[n]} foot: {n}-sided wavefronts", 26)
_dip("Dipper star 5", lambda: C.star_polygon(5, 2).region, "Pentagram foot", 28)
_dip("Dipper two pins", lambda: unary_union([Point(-1, 0).buffer(0.22, 48), Point(1, 0).buffer(0.22, 48)]), "Two 4 mm pins 18 mm apart: Young's two-source interference", 22)
_dip("Dipper three pins", lambda: unary_union([Point(np.cos(a), np.sin(a)).buffer(0.2, 48) for a in pi / 2 + TAU * np.arange(3) / 3]), "Three pins at 120 degrees: hexagonal interference", 24)
_dip("Dipper six pins", lambda: unary_union([Point(np.cos(a), np.sin(a)).buffer(0.16, 48) for a in TAU * np.arange(6) / 6]), "Six-pin ring: focused hexagonal standing waves", 30)


def entries():
    out = []
    counters = {"gobo": 0, "insert": 0, "dipper": 0}
    prefix = {"gobo": "G", "insert": "B", "dipper": "D"}
    for e in REG:
        counters[e["part"]] += 1
        e = dict(e)
        e["id"] = f"{prefix[e['part']]}{counters[e['part']]:03d}"
        out.append(e)
    return out
