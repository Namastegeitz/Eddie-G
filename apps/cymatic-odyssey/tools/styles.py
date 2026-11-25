#!/usr/bin/env python3
"""The 30 CYMATIC ODYSSEY styles: complete looks = gobo + insert + wave source + signal + colours.

    python3 tools/styles.py     -> styles/S##_name/ (STL, SVG, previews), downloads/style_kits.zip,
                                   catalog/styles.json, console assets
"""
from __future__ import annotations

import json
import shutil
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

DEEP = ["#2b6cff", "#7fd4ff", "#b48cff"]
GOLD = ["#ffd27a", "#ff9f43", "#fff3d6"]
NEB = ["#ff5fa2", "#7a5cff", "#36e2ff"]
AUR = ["#36ffb0", "#2bd1ff", "#9b6bff"]
EMB = ["#ff6b3d", "#ffb347", "#ffe3a3"]
ICE = ["#bfe9ff", "#ffffff", "#8fb8ff"]
ROSE = ["#ff7aa8", "#ffd1dc", "#ffb347"]
LANT = ["#36e2ff", "#ffd27a", "#7a5cff"]
WHITE = ["#ffffff", "#cfe6ff", "#fff1d6"]
HALLO = ["#ff7a00", "#7a5cff", "#36ff6b"]
LEAF = ["#9bff6b", "#ffd27a", "#36ffb0"]


def S(id, name, gobo, insert, dipper, mode, f, ratio, pulse, breathe, pal, mood, how, best):
    return dict(id=id, name=name, gobo=gobo, insert=insert, dipper=dipper, mode=mode, f=f, ratio=ratio,
                pulse=pulse, breathe=breathe, pal=pal, mood=mood, how=how, best=best)


STYLES = [
 S("S01", "Orbit Rings", "Concentric rings", "Insert circle (reference)", "Dipper point", "dipper", 24, None, 1.0, 0.0, DEEP,
   "calm, launch", "A single point taps the water once a second; each ring travels out through printed orbit circles.", "openings, bedrooms"),
 S("S02", "Saturn Storm", "Hexagon nest", "Insert hexagon", None, "faraday", 48, [3, 2], 0, 0.0, GOLD,
   "bold, geometric", "Two tones at 2:3 make the water choose hexagons; the hexagon wall and gobo lock them in place.", "bars, parties"),
 S("S03", "Quasicrystal Nebula", "Dodecagonal quasicrystal", "Insert circle (reference)", None, "faraday", 40, [5, 4], 0, 0.0, NEB,
   "mysterious", "4:5 forcing grows a 12-fold quasipattern; a 12-fold tiling gobo echoes it.", "lounges, galleries"),
 S("S04", "Penrose Gate", "Penrose rhombus (P3) quasicrystal", "Insert pentagon", None, "faraday", 44, [5, 4], 0, 0.05, AUR,
   "ordered chaos", "Penrose rhombi refracted through a five-walled dish: order that never repeats.", "science centres"),
 S("S05", "Metatron", "Metatron's Cube", "Insert hexagon", None, "faraday", 36, [3, 2], 0, 0.08, GOLD,
   "sacred, centred", "Metatron's lines bend over a hexagonal standing wave, breathing slowly.", "yoga, meditation"),
 S("S06", "Flower of Life Bloom", "Flower of Life", "Insert wavy 6", "Dipper point", "dipper", 20, None, 0.5, 0.1, GOLD,
   "gentle, blooming", "Rings bloom through 19 interlaced circles at a breathing pace.", "spas, bedrooms"),
 S("S07", "Venus Rose", "Cosmic dance Venus-Earth", "Insert pentagon", "Dipper star 5", "dipper", 22, None, 0.6, 0.0, ROSE,
   "romantic", "The real 8-year Venus-Earth rose, pulsed by a star-shaped foot.", "date nights, weddings"),
 S("S08", "Hyperbolic Abyss", "Hyperbolic {7,3}", "Insert heptagon", None, "faraday", 70, None, 0, 0.05, AUR,
   "deep, infinite", "Escher-style heptagons shrinking to the rim over fine square waves.", "lounges, art spaces"),
 S("S09", "E8 Singularity", "E8 root polytope", "Insert circle (reference)", None, "faraday", 60, [5, 4], 0, 0.0, ["#ffffff", "#ff5fa2", "#36e2ff"],
   "peak, intense", "E8's 30-fold shadow over a 12-fold quasipattern: the densest look.", "finales"),
 S("S10", "600-Cell Halo", "600-cell", "Insert decagon", None, "faraday", 50, [5, 4], 0, 0.04, DEEP,
   "cosmic halo", "A 4D polytope's 30-fold halo inside a ten-sided dish.", "planetariums"),
 S("S11", "Girih Lantern", "Hankin 4.8.8 at 67.5 deg", "Insert octagon", None, "faraday", 40, [3, 2], 0, 0.0, LANT,
   "night garden", "Eight-point girih stars rippling like lantern light.", "restaurants, Ramadan/Eid"),
 S("S12", "Star of Twelve", "Dodecagram {12/5}", "Insert dodecagon", None, "faraday", 45, [5, 4], 0, 0.0, GOLD,
   "radiant", "A twelve-point star over twelve-fold water.", "celebrations"),
 S("S13", "Koch Snowfall", "Koch snowflake L5", "Insert Koch snowflake", None, "faraday", 30, None, 0, 0.08, ICE,
   "winter hush", "A fractal snowflake in a snowflake-shaped dish; the jagged wall traps waves in its corners.", "winter, solstice"),
 S("S14", "Julia Bloom", "Julia set - Douady rabbit", "Insert Bunimovich stadium", None, "faraday", 34, None, 0, 0.0, HALLO,
   "eerie, chaotic", "Julia lace over a chaotic stadium dish: speckled, restless water.", "Halloween, escape rooms"),
 S("S15", "Dragon Fold", "Heighway dragon", "Insert square", None, "faraday", 28, None, 0, 0.0, EMB,
   "fiery", "The paper-folding dragon over square Faraday waves.", "bars, game rooms"),
 S("S16", "Sunflower Spiral", "Sunflower phyllotaxis", "Insert wavy 8", "Dipper point", "dipper", 21, None, 0.618, 0.0, LEAF,
   "growth", "Golden-angle seeds pulsed at 0.618 per second.", "spring, garden centres"),
 S("S17", "Galaxy Arms", "Galaxy arms", "Insert circle (reference)", "Dipper disc 25", "dipper", 26, None, 0.4, 0.0, NEB,
   "spiral, drifting", "Logarithmic arms with soft rings rolling outward.", "space nights"),
 S("S18", "Chladni Plate", "Chladni square (3,5) anti", "Insert square", None, "faraday", 36, None, 0, 0.0, WHITE,
   "scientific, crisp", "Chladni's 1787 nodal lines in a square dish of Faraday squares.", "classrooms, museums"),
 S("S19", "Water Drum", "Water mode J4 ring 3", "Insert circle (reference)", None, "faraday", 32, None, 0, 0.0, ["#36e2ff", "#ffffff", "#2b6cff"],
   "pure physics", "The dish's own 8-petal Bessel mode drawn on the gobo; tune until water and print agree.", "demos"),
 S("S20", "Twin Source", "Two-source interference", "Insert circle (reference)", "Dipper two pins", "dipper", 30, None, 0, 0.0, ["#36e2ff", "#7fd4ff", "#ffffff"],
   "clean, scientific", "Young's two-source fringes made by two pins on one foot.", "science centres"),
 S("S21", "Triple Lattice", "Three-source interference", "Insert hexagon", "Dipper three pins", "dipper", 34, None, 0, 0.0, AUR,
   "lattice", "Three pins at 120 degrees weave a hexagonal interference net.", "lounges"),
 S("S22", "Lissajous Weave", "Lissajous 3:4", "Insert circle (reference)", None, "faraday", 40, [4, 3], 0, 0.0, ["#ffe9b0", "#7fd4ff", "#ff5fa2"],
   "musical", "The 3:4 figure is the picture of the two tones being played.", "music events"),
 S("S23", "Knotwork", "Torus knot (3,7)", "Insert heptagon", None, "faraday", 42, None, 0, 0.06, ["#b48cff", "#ffd27a", "#36e2ff"],
   "woven", "A (3,7) torus knot rippling over a seven-walled dish.", "galleries"),
 S("S24", "Fibonacci Gold", "Golden spiral & Fibonacci squares", "Insert golden rectangle", "Dipper point", "dipper", 21, None, 0.618, 0.0, GOLD,
   "harmonic", "The golden spiral in a golden-rectangle dish, pulsed at 1/phi.", "studios, offices"),
 S("S25", "Sacred Yantra", "Nine-triangle yantra (simplified)", "Insert triangle", None, "faraday", 33, [3, 2], 0, 0.1, ["#ffd27a", "#ff6b3d", "#ff3dd2"],
   "devotional", "Nine interlocking triangles over hexagon-triangle water, breathing at 6/min.", "Diwali, meditation"),
 S("S26", "Hypercube Dream", "8-cube (hypercube)", "Insert octagon", None, "faraday", 64, None, 0, 0.0, ["#7a5cff", "#36e2ff", "#ffffff"],
   "4D, hypnotic", "256 corners of an 8-dimensional cube in a 16-fold rose.", "lounges, clubs"),
 S("S27", "Snub Cosmos", "Snub dodecahedron", "Insert pentagon", None, "faraday", 52, [5, 4], 0, 0.0, NEB,
   "crystalline", "The snub dodecahedron's lace over 12-fold water.", "galleries"),
 S("S28", "Apollonian Pearls", "Apollonian gasket", "Insert circle (reference)", "Dipper ring", "dipper", 18, None, 0.3, 0.08, ["#ffffff", "#ffd1dc", "#bfe9ff"],
   "soft, pearly", "Circles within circles; a ring foot sends waves inward to focus at the centre.", "weddings, spas"),
 S("S29", "Moire Drift", "Moire grating 3 deg", "Insert ellipse 2.0:1", None, "faraday", 38, [7, 6], 0, 0.0, ["#36ffb0", "#ff5fa2", "#ffffff"],
   "op-art", "Grating lines bent by slowly beating 6:7 water: moire bands crawl across the wall.", "retail windows"),
 S("S30", "Fresnel Sun", "Fresnel zone plate", "Insert circle (reference)", "Dipper point", "dipper", 24, None, 1.2, 0.0, EMB,
   "solar", "A zone plate focuses light into bright rings while ripples pulse through them.", "summer, solstice"),
]


def build():
    from odyssey import catalog
    from render_wall import render_style, render_parts
    ents = {e["name"]: e for e in catalog.entries()}
    meta = json.loads((ROOT / "catalog/geometry_catalog.json").read_text())
    files = {m["name"]: m for m in meta}
    out = ROOT / "styles"
    out.mkdir(exist_ok=True)
    rows = []
    for s in STYLES:
        d = out / f"{s['id']}_{s['name'].lower().replace(' ', '_').replace('-', '_')}"
        d.mkdir(exist_ok=True)
        kit = []
        for role in ("gobo", "insert", "dipper"):
            nm = s[role]
            if not nm:
                continue
            m = files[nm]
            src = ROOT / m["stl"]
            dst = d / f"{role}_{src.name}"
            shutil.copy(src, dst); kit.append(dst.name)
            if m.get("svg"):
                sv = ROOT / m["svg"]; shutil.copy(sv, d / f"{role}_{sv.name}"); kit.append(f"{role}_{sv.name}")
        render_style(s, ents[s["gobo"]]["fn"](), d / "wall_preview.png")
        render_parts(s, ents, d / "parts_preview.png")
        rows.append(dict(s, folder=str(d.relative_to(ROOT)), files=kit,
                         gobo_id=ents[s["gobo"]]["id"], insert_id=ents[s["insert"]]["id"],
                         dipper_id=ents[s["dipper"]]["id"] if s["dipper"] else ""))
        print("style", s["id"], s["name"], len(kit), "files")
    (ROOT / "catalog/styles.json").write_text(json.dumps(rows, indent=1))
    # one zip with every kit + hardware
    z = ROOT / "downloads/CYMATIC_ODYSSEY_30_style_kits.zip"
    with zipfile.ZipFile(z, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for f in sorted(out.rglob("*")):
            if f.is_file():
                zf.write(f, f"styles/{f.relative_to(out)}")
        for f in sorted((ROOT / "stl/hardware").glob("*.stl")):
            zf.write(f, f"hardware/{f.name}")
    print("zip", z, z.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    build()
