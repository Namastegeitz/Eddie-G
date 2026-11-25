#!/usr/bin/env python3
"""Builds CYMATIC_ODYSSEY_Sourcing_Guide.pdf (HTML + CSS -> Chromium print)."""
import html, subprocess, json
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
IMG = APP / "previews/items"
def img(name): return (IMG / name).as_uri()
E = html.escape
def a(text, url): return f'<a href="{E(url)}">{E(text)}</a>'

PICKS = [
 ("The water vessel", "Borosilicate Petri dish, 150 mm", "Flat, thin, clear: the sharpest caustics. Bought one at a time.", "McMaster-Carr", "https://www.mcmaster.com/products/crystallizing-dishes/"),
 ("A geometric vessel", "Hexagonal borosilicate bowl", "About $15.90, 6 x 9 x 12 cm. Its hammered texture softens the lines, so use it as a coloured filter or display piece.", "Zara Home", "https://www.zarahome.com/us/hexagonal-borosilicate-glass-bowl-l48213211"),
 ("Any shape, cut for you", "Waterjet-cut glass plates", "Hexagon, triangle and star plates in borosilicate or optical glass.", "Swift Glass", "https://www.swiftglass.com/glass-cutting-waterjet"),
 ("Custom glassblowing nearby", "Square or hex dishes made to spec", "Vineland, NJ is a scientific-glass town: Chemglass, Ace Glass and Wilmad-LabGlass.", "Chemglass custom orders", "https://chemglass.com/pages/order_custom"),
 ("Clear filament", "Translucent PETG", "Clear PETG prints far more see-through than clear PLA.", "Bambu PETG Translucent", "https://www.bestbuy.com/product/bambu-lab-1-75mm-petg-translucent-filament-clear/CZTZV9ZPZH/sku/6610619/reviews"),
 ("Effect filament", "UV-shift PLA", "Natural colour until a UV LED hits it, then orange: gobos that switch colour.", "Polymaker Panchroma UV Shift", "https://shop.polymaker.com/collections/panchroma/products/uv-shift-pla"),
]

GLASS = [
 ("Borosilicate Petri dishes", "circle", "The main water vessel; borosilicate takes heat and shock.", [("McMaster-Carr (single dishes)", "https://www.mcmaster.com/products/crystallizing-dishes/"), ("Kimble Kimax 150 x 25 mm (case)", "https://www.dwk.com/na/kimble-kimax-petri-dish-150-x-25-mm-23061-15025")], "Lab suppliers sell cases of 12-40."),
 ("Hexagonal borosilicate bowl", "hexagon", "Hex footprint, coloured rim. Use as a filter or display; texture blurs caustics.", [("Zara Home US", "https://www.zarahome.com/us/hexagonal-borosilicate-glass-bowl-l48213211")], "About 6 x 9 x 12 cm; about $15.90 US."),
 ("Crystal cubes and blocks (K9-type crystal)", "cube, cut-corner cube, rectangles", "Put one in the beam: each facet throws its own copy of the pattern.", [("Crystal D cut-corner cube 2 in", "https://www.crystal-d.com/cut-corner-cube-2x2x2-7935"), ("Crystal D cube 4 in", "https://crystal-d.com/colin-cube-4x4x4-7933")], "Sold blank or engraved (see 3D engraving)."),
 ("Platonic-solid crystal sets", "tetrahedron to icosahedron (+ extras)", "Sacred-geometry props; small facets scatter light into sparkles.", [("Shaman's Market 7-piece set", "https://www.shamansmarket.com/products/sacred-geometry-set-crystal-platonic-solids"), ("The Harmony Store quartz set", "https://www.theharmonystore.com/collections/all/products/quartz-platonic-solids")], "Natural quartz, not optical glass: decorative."),
 ("Platonic solids, made to order", "the five Platonic solids", "Order in a range of printed materials; matches the catalogue's polyhedra.", [("Shapeways set of 5", "https://www.shapeways.com/product/EFR3V2TXR/platonic-solids-set-of-5")], "Check material options on the listing."),
 ("Square Fresnel lens", "square, concentric grooves", "A geometric optic in itself; also a projection lens option.", [("Edmund 3 in x 3 in, 7.9 in FL", "https://www.edmundoptics.com/p/30quot-x-30quot-79quot-focal-length-fresnel-lens/2526/")], "Distorts more than a glass lens."),
 ("First-surface mirror", "rectangle", "Folds the beam onto the wall without ghost images.", [("Edmund 76 x 102 mm", "https://www.edmundoptics.com/p/76-x-102mm-4-6lambda-mirror/4614/")], "Skip lambda/10 grades: about $580."),
 ("Art glass and dichroic sheets", "any cut shape", "Colour filters on the gobo carrier; dichroic glass splits colours by angle.", [("Rainbow Art Glass, Wall Twp NJ", "https://www.glassartmagazine.com/industry-directory/436-rainbow-art-glass-inc"), ("Stained Glass Stylists, Waretown NJ", "https://www.delphiglass.com/blog/dealer-spotlight/stained-glass-stylists-nj"), ("David Albert Stained Glass, Phila.", "https://startpage.mapquest.com/us/pennsylvania/david-albert-stained-glass-studio-2319475")], "Rainbow Art Glass lists 2,000+ styles incl. dichroic."),
 ("Everyday glass bowls and plates", "round, square", "Cheap test vessels and display pieces.", [("IKEA South Philadelphia", "https://www.ikea.com/us/en/stores/south-philadelphia/")], "Pick clear, flat, thin bottoms."),
 ("Hand-blown studio glass", "bowls, vases, paperweights", "One-of-a-kind display pieces and coloured filters.", [("WheatonArts shop, Millville NJ", "https://shop.wheatonarts.org/product-category/wheatonarts-crafted/page/2"), ("Antolini Glass, Philadelphia", "https://www.wheatonarts.org/antolini-glass-co")], "Uneven glass: not for the water vessel."),
]

CUSTOM_PRECISION = [
 ("Swift Glass", "Waterjet cutting, any 2D shape", "Borosilicate, quartz, optical glass, fused silica. Stated precision varies by page (+/-0.01 in to 0.1 mm): confirm.", "https://www.swiftglass.com/glass-cutting-waterjet", "Online / national"),
 ("Chemglass Life Sciences", "Custom scientific glassware to your spec", "Founded 1946 by a Kimble glassblower; custom design, machining and fabrication.", "https://chemglass.com/pages/order_custom", "Vineland, NJ"),
 ("Ace Glass", "Custom lab apparatus", "Founded 1936; in-house custom fabrication team.", "https://photonics.com/Buyers_Guide/Ace_Glass_Inc/c16569", "Vineland, NJ"),
 ("Wilmad-LabGlass", "Custom borosilicate and quartz", "Design and fabrication of custom borosilicate and quartz products.", "https://www.anl.gov/pse/glassblowing-capabilities", "Vineland, NJ"),
 ("Glass Dynamics", "Cutting and fabrication", "Tempered glass and mirrors: enclosure panels, flat plates.", "https://www.iqsdirectory.com/profile/glass-dynamics-70794/", "Vineland, NJ"),
 ("UQG Optics", "Optical machining, waterjet", "Shapes, rings and technical glass, stated tolerance +/-0.10 mm.", "https://uqgoptics.com/grinding-cutting", "UK (ships)"),
]
CUSTOM_ART = [
 ("Pearson Glassworks", "Studio glass incl. large residential projects", "https://www.wheatonarts.org/pearson-glassworks/", "New Jersey"),
 ("SwellColors Glass Studio", "Fused glass, mosaics, backsplashes; free estimates", "https://www.houzz.com/pro/webuser-714126540/swellcolors-glass-studio-and-gallery", "Surf City, NJ"),
 ("Moxie Sorbet Designs", "Fused glass studio", "https://njmonthly.com/?p=79890", "Passaic, NJ"),
 ("Glasslight", "Hand-blown lighting, fused glass tables", "https://www.houzz.com/profesionales/artistas-y-artesanos/glasslight-pfvwus-pf~504216456", "Saint Peter's, PA"),
 ("Moore Custom Art Glass", "Decorative and functional kiln-formed glass", "https://mapquest.com/us/pennsylvania/moore-custom-art-glass-376346792", "Pennsylvania"),
 ("Pittsburgh Glass Center", "Repairs and commissions", "https://www.pittsburghglasscenter.org/repairs-commissions/", "Pittsburgh, PA"),
 ("East Falls Glassworks", "Philadelphia's largest hot-glass studio", "https://whyy.org/articles/glassblowing/", "Philadelphia, PA"),
 ("Bernard Katz Glass", "Hot-glass studio and gallery", "https://whyy.org/articles/mom-and-pop-bernard-katz-glass/", "Manayunk, PA"),
 ("Transparent Images", "Wall-hung panels with matched dichroic colours, up to 500 mm", "https://transparentimages.com/technical_information/commissions/", "UK"),
 ("Mark Ditzler Glass Studio", "Fused panels, sculpture, lighting; commissions", "https://shop.craftcouncil.org/collections/mark-ditzler-glass-studio-llc", "Seattle, WA"),
]
CUSTOM_LASER = [
 ("Crystal D", "150+ crystal pieces with 3D subsurface imprint", "https://crystal-d.com/subsurface"),
 ("Able Recognition", "3D artwork that floats inside clear crystal", "https://ablerecognition.com/crystal-awards/3d-laser-crystal"),
 ("Bennett Awards", "2D surface or 3D subsurface engraving", "https://www.bennettawards.com/custom-crystal-awards"),
 ("ArtPix 3D", "Photo-based 3D crystal", "https://artpix3d.com/contact/"),
]

CLEAR = [
 ("Polymaker PolyLite PETG (transparent)", "Very clear", "Very moisture-sensitive: dry it before printing.", "https://all3dp.com/2/clear-petg-filament-buyers-guide/"),
 ("Prusament PETG (clear)", "Clear", "Tight diameter tolerance for even extrusion.", "https://all3dp.com/2/clear-petg-filament-buyers-guide/"),
 ("Bambu Lab PETG Translucent", "Clear-translucent", "Reliable for clear projects (user review); RFID spool.", "https://www.bestbuy.com/product/bambu-lab-1-75mm-petg-translucent-filament-clear/CZTZV9ZPZH/sku/6610619/reviews"),
 ("Overture Transparent PETG", "Clear", "Popular; clear before any post-processing.", "https://3dinsider.com/best-clear-3d-printing-filaments"),
 ("MatterHackers translucent PETG", "Translucent", "Fairly see-through.", "https://www.matterhackers.com/store/c/clear-filament"),
 ("Filaments.ca transparent PETG", "Translucent", "Prints more translucent than clear: good diffuser.", "https://3dinsider.com/best-clear-3d-printing-filaments"),
]

EFFECTS = [
 ("Glow in the dark", "Stores light, releases it in the dark. Stronger after UV charging.", "Polymaker Panchroma Glow, Sunlu, Overture, Hatchbox, Amolen, ColorFabb", [("All3DP comparison", "https://all3dp.com/2/glow-in-the-dark-filament-brands-compared/"), ("MatterHackers range", "https://www.matterhackers.com/store/c/3d-printer-filament-effects/glow-in-the-dark")], "Insert rims and dipper feet keep glowing after the show.", "Abrasive: use a hardened nozzle."),
 ("UV colour-shift", "Natural colour until UV hits it, then coloured.", "Polymaker Panchroma UV Shift (natural to orange)", [("Polymaker UV Shift", "https://shop.polymaker.com/collections/panchroma/products/uv-shift-pla")], "Gobos and props that change when a UV LED channel switches on.", "Effect can fade over many cycles."),
 ("Neon / fluorescent", "Stays the same colour, glows hard under UV.", "Polymaker neon line", [("Polymaker glow + UV range", "https://shop.polymaker.com/en-gb/products/panchroma-glow")], "Hardware accents that light up under a UV channel.", "Needs a UV LED to pop."),
 ("Thermochromic", "Changes colour with temperature (PLA or TPU); the switch point varies.", "Various", [("How it works (3DMag)", "https://www.3dmag.com/3d-wikipedia/color-changing-filament-how-it-works/")], "Touch props, knobs, coil-bay trim.", "Keep away from the LED heatsink."),
 ("Starlight (fine sparkle)", "Very fine powder: tiny sparkles.", "Polymaker Panchroma Starlight", [("Polymaker Starlight", "https://shop.polymaker.com/products/starlight-pla")], "Enclosure corners, base, platform skirt: a night-sky finish.", "Print under 80 mm/s for the best shine."),
 ("Galaxy (glitter)", "Aluminium specks: big sparkles.", "Polymaker Panchroma Galaxy, Bambu PLA Galaxy / Sparkle", [("Polymaker Panchroma range", "https://shop.polymaker.com/pages/panchroma")], "Decorative shells only.", "Glitter can jam a 0.4 mm nozzle; not for thin gobos."),
 ("Silk / metallic look", "Shiny surface, no real metal.", "Many brands", [("Effects overview (BGR)", "https://www.bgr.com/2254225/most-unique-3d-printer-filaments/")], "Lens ring, mirror holder, knobs.", "Real metal-filled filament is abrasive."),
 ("Gradient / rainbow", "Colours already blended along the strand.", "Polymaker Gradient Starlight / Galaxy", [("Gradient Starlight", "https://shop.polymaker.com/products/gradient-starlight-pla")], "Coloured dipper feet; showpiece inserts.", "Colour shift depends on part size."),
]

MAP = [
 ("Gobos (light stencils)", "White PLA or PETG", "Lithophane principle: 0.6 mm base passes light, 2.4 mm lines block it."),
 ("Rainbow gobos", "Clear PETG + two polariser sheets", "Printing stress turns into rainbow colours between polarisers."),
 ("Colour filters", "Translucent coloured PETG, 1-2 mm", "A cheap gel alternative on the gobo carrier."),
 ("Boundary inserts", "PETG (plain or glow)", "PETG handles water better than PLA long-term."),
 ("Dipper feet", "PETG or resin, 100% infill", "Glow PETG makes the wave source visible in the dark."),
 ("Platform", "Plain PETG, 4 walls, 40% infill", "Stiffness first: no glitter or silk."),
 ("Enclosure trim, coil bay", "Starlight, silk, galaxy", "All the sparkle lives here, outside the light path."),
]

def picks_html():
    out = []
    for i, (h, t, d, s, u) in enumerate(PICKS):
        out.append(f'<div class="pick"><div class="pnum">{i+1}</div><h4>{E(h)}</h4><p class="pt">{E(t)}</p><p>{E(d)}</p><p class="go">{a(s+" →", u)}</p></div>')
    return "".join(out)

def glass_rows():
    return "".join(f'<tr><td><b>{E(n)}</b><span class="shape">{E(sh)}</span></td><td>{E(why)}</td><td>{"<br>".join(a(t,u) for t,u in links)}</td><td class="note">{E(note)}</td></tr>' for n, sh, why, links, note in GLASS)

def prec_rows():
    return "".join(f'<tr><td><b>{a(n,u)}</b><span class="shape">{E(loc)}</span></td><td>{E(what)}</td><td>{E(d)}</td></tr>' for n, what, d, u, loc in CUSTOM_PRECISION)

def art_cards():
    return "".join(f'<div class="mini"><b>{a(n,u)}</b><span>{E(loc)}</span><p>{E(d)}</p></div>' for n, d, u, loc in CUSTOM_ART)

def laser_cards():
    return "".join(f'<div class="mini dark"><b>{a(n,u)}</b><p>{E(d)}</p></div>' for n, d, u in CUSTOM_LASER)

def clear_rows():
    return "".join(f'<tr><td><b>{a(n,u)}</b></td><td><span class="pill">{E(c)}</span></td><td>{E(d)}</td></tr>' for n, c, d, u in CLEAR)

def effect_cards():
    out = []
    for n, how, brands, links, use, warn in EFFECTS:
        out.append(f'<div class="fx"><h4>{E(n)}</h4><p>{E(how)}</p><p class="br">{E(brands)}</p><p class="use"><b>In the chamber:</b> {E(use)}</p><p class="warn">{E(warn)}</p><p class="go">{" · ".join(a(t,u) for t,u in links)}</p></div>')
    return "".join(out)

def map_rows():
    return "".join(f'<tr><td><b>{E(p)}</b></td><td>{E(m)}</td><td>{E(w)}</td></tr>' for p, m, w in MAP)

CSS = r"""
@page { size: Letter; margin: 0; }
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { font-family: 'Inter', sans-serif; color: #1a1c2e; font-size: 10.5pt; line-height: 1.5; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
a { color: #1d5fa8; text-decoration: none; border-bottom: 0.6pt solid #9cc3ec; }
.page { width: 8.5in; height: 11in; position: relative; overflow: hidden; page-break-after: always; padding: 0.55in 0.6in 0.6in; }
.page:last-child { page-break-after: auto; }
.cover { background: #07081a; color: #f3f0e6; padding: 0; }
.cover .mosaic { position: absolute; inset: 0; display: grid; grid-template-columns: repeat(4, 1fr); grid-auto-rows: 2.75in; opacity: 0.55; }
.cover .mosaic img { width: 100%; height: 100%; object-fit: cover; }
.cover .shade { position: absolute; inset: 0; background: linear-gradient(180deg, rgba(7,8,26,0.15) 0%, rgba(7,8,26,0.55) 40%, rgba(7,8,26,0.97) 72%); }
.cover .text { position: absolute; left: 0.7in; right: 0.7in; bottom: 0.8in; }
.cover .kicker { font-size: 10pt; letter-spacing: 0.28em; color: #ffd27a; font-weight: 600; }
.cover h1 { font-family: 'Inter Display', 'Inter', sans-serif; font-weight: 800; font-size: 50pt; line-height: 0.98; margin: 10pt 0 14pt; letter-spacing: -0.01em; }
.cover h1 span { color: #7fd4ff; }
.cover .sub { font-size: 13pt; color: #c9cbe0; max-width: 5.6in; }
.cover .meta { margin-top: 22pt; display: flex; gap: 22pt; font-size: 9pt; color: #9aa0c4; }
.cover .meta b { display: block; color: #fff; font-size: 11pt; }
.band { display: flex; align-items: center; gap: 14pt; margin: -0.55in -0.6in 18pt; padding: 0.42in 0.6in 0.3in; background: #07081a; color: #fff; }
.band img { width: 0.95in; height: 0.95in; border-radius: 50%; }
.band .n { font-family: 'Inter Display'; font-size: 34pt; font-weight: 800; color: #ffd27a; line-height: 1; }
.band h2 { font-family: 'Inter Display'; font-size: 24pt; margin: 0; line-height: 1.05; }
.band p { margin: 4pt 0 0; color: #b9bdd8; font-size: 10pt; }
h3 { font-family: 'Inter Display'; font-size: 13.5pt; margin: 14pt 0 6pt; color: #07081a; }
h3 small { font-family: 'Inter'; font-weight: 500; color: #6b6f8c; font-size: 9pt; margin-left: 6pt; }
.lead { font-size: 10.5pt; color: #3b3e58; margin: 0 0 10pt; }
.picks { display: grid; grid-template-columns: 1fr 1fr; gap: 10pt; }
.pick { position: relative; border: 1pt solid #e4e5ef; border-radius: 10pt; padding: 12pt 12pt 10pt 46pt; background: #fbfbfe; break-inside: avoid; }
.pick .pnum { position: absolute; left: 12pt; top: 12pt; width: 24pt; height: 24pt; border-radius: 50%; background: #07081a; color: #ffd27a; font-weight: 800; text-align: center; line-height: 24pt; }
.pick h4 { margin: 0; font-size: 8.5pt; letter-spacing: 0.05em; color: #6b6f8c; font-weight: 600; }
.pick .pt { font-family: 'Inter Display'; font-size: 13pt; font-weight: 700; margin: 2pt 0 4pt; color: #07081a; }
.pick p { margin: 0 0 4pt; }
.go { font-weight: 600; }
table { width: 100%; border-collapse: collapse; font-size: 9.3pt; }
th { text-align: left; font-size: 8pt; color: #6b6f8c; font-weight: 600; border-bottom: 1.2pt solid #07081a; padding: 4pt 6pt; }
td { vertical-align: top; padding: 5.5pt 6pt; border-bottom: 0.6pt solid #e4e5ef; }
tr { break-inside: avoid; }
.shape { display: block; color: #8a6d1f; font-size: 7.8pt; margin-top: 1pt; }
.note { color: #5b5f7a; font-size: 8.5pt; }
.minis { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8pt; }
.mini { border: 1pt solid #e4e5ef; border-radius: 8pt; padding: 9pt 10pt; break-inside: avoid; background: #fff; }
.mini b { font-size: 9.5pt; } .mini span { display: block; font-size: 8pt; color: #8a6d1f; margin-top: 1pt; }
.mini p { margin: 4pt 0 0; font-size: 8.8pt; color: #3b3e58; }
.mini.dark { background: #07081a; border-color: #07081a; color: #e8e9f5; } .mini.dark a { color: #7fd4ff; border-color: #335; } .mini.dark p { color: #b9bdd8; }
.brief { margin-top: 12pt; border-left: 3pt solid #ffd27a; background: #fff9ea; padding: 9pt 12pt; border-radius: 0 8pt 8pt 0; font-size: 9pt; }
.brief b { color: #07081a; }
.brief ol { margin: 4pt 0 0 14pt; padding: 0; }
.pill { display: inline-block; padding: 1pt 7pt; border-radius: 10pt; background: #e8f4ff; color: #1d5fa8; font-size: 8pt; font-weight: 600; white-space: nowrap; }
.fxs { display: grid; grid-template-columns: 1fr 1fr; gap: 8pt; }
.fx { border: 1pt solid #e4e5ef; border-radius: 9pt; padding: 9pt 12pt; break-inside: avoid; background: #fff; }
.fx h4 { margin: 0 0 3pt; font-family: 'Inter Display'; font-size: 11.5pt; color: #07081a; }
.fx p { margin: 0 0 3pt; font-size: 8.9pt; }
.fx .br { color: #6b6f8c; } .fx .use { color: #1a1c2e; } .fx .warn { color: #a4471f; font-weight: 600; }
.tips { display: grid; grid-template-columns: 1fr 1fr; gap: 10pt; margin-top: 8pt; }
.tip { background: #07081a; color: #e8e9f5; border-radius: 10pt; padding: 13pt 15pt; font-size: 9.3pt; }
.tip h4 { margin: 0 0 4pt; color: #ffd27a; font-size: 10.5pt; }
.tip ul { margin: 0; padding-left: 13pt; } .tip li { margin-bottom: 2pt; }
.foot { position: absolute; left: 0.6in; right: 0.6in; bottom: 0.3in; display: flex; justify-content: space-between; font-size: 7.5pt; color: #9a9db6; }
.disclaim { font-size: 8pt; color: #6b6f8c; margin-top: 10pt; }
.back { background: #07081a; color: #e8e9f5; }
.back .art { display: flex; gap: 14pt; justify-content: center; margin: 0.9in 0 0.4in; }
.back .art img { width: 1.6in; height: 1.6in; border-radius: 50%; }
.back h2 { font-family: 'Inter Display'; text-align: center; font-size: 22pt; color: #fff; }
.back p { text-align: center; color: #b9bdd8; max-width: 5.4in; margin: 6pt auto; }
"""

def foot(n): return f'<div class="foot"><span>CYMATIC ODYSSEY · Glass, Makers &amp; Filament</span><span>{n}</span></div>'

cover_imgs = ["G102_metatron_s_cube.png", "G277_600_cell.png", "G164_faraday_12_fold_quasipattern.png", "G202_hyperbolic_7_3.png",
              "G238_snub_dodecahedron.png", "G193_penrose_rhombus_p3_quasicrystal.png", "G100_flower_of_life.png", "G282_e8_root_polytope.png",
              "G188_hankin_4_8_8_at_67_5_deg.png", "G126_cosmic_dance_venus_earth.png", "G210_hyperbolic_7_3_dual_net.png", "G102_metatron_s_cube.png",
              "G277_600_cell.png", "G100_flower_of_life.png", "G164_faraday_12_fold_quasipattern.png", "G238_snub_dodecahedron.png"]

HTML = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><title>CYMATIC ODYSSEY Sourcing Guide</title><style>{CSS}</style></head><body>

<section class="page cover">
  <div class="mosaic">{''.join(f'<img src="{img(n)}">' for n in cover_imgs)}</div>
  <div class="shade"></div>
  <div class="text">
    <div class="kicker">CYMATIC ODYSSEY · SOURCING GUIDE</div>
    <h1>Glass, Makers<br>&amp; <span>Filament</span></h1>
    <div class="sub">Geometric glass to buy, companies that make custom glass to your design, and transparent, translucent and special-effect 3D-printing filament for the water-light chamber.</div>
    <div class="meta"><div><b>10</b>kinds of geometric glass</div><div><b>20</b>custom makers</div><div><b>14</b>filaments &amp; effects</div><div><b>Nov 2026</b>South Jersey · Philadelphia · online</div></div>
  </div>
</section>

<section class="page">
  <div class="band"><div class="n">01</div><div><h2>Start here: six picks</h2><p>If you buy nothing else, these cover the vessel, the geometry and the effects.</p></div></div>
  <div class="picks">{picks_html()}</div>
  <div class="brief"><b>How to use this guide.</b> Every name is a clickable link, checked by web search in November 2026. Prices, stock, hours and lead times change: confirm on each page or call before driving. Natural quartz, decorative crystal and hand-blown glass are for display and filters. The water itself belongs in flat, clear borosilicate.</div>
  {foot(2)}
</section>

<section class="page">
  <div class="band"><img src="{img('G238_snub_dodecahedron.png')}"><div><div class="n">02</div><h2>Geometric glass to buy</h2><p>Vessels, crystal solids, optics and art glass, with what each does in the light chamber.</p></div></div>
  <table><thead><tr><th style="width:24%">Glass</th><th style="width:30%">Use in the chamber</th><th style="width:28%">Where</th><th>Notes</th></tr></thead><tbody>{glass_rows()}</tbody></table>
  {foot(3)}
</section>

<section class="page">
  <div class="band"><img src="{img('G193_penrose_rhombus_p3_quasicrystal.png')}"><div><div class="n">03</div><h2>Custom glass: precision makers</h2><p>Exact shapes for vessels and plates: hexagon, triangle, star, any SVG from the catalogue.</p></div></div>
  <table><thead><tr><th style="width:26%">Company</th><th style="width:28%">What they make</th><th>Details</th></tr></thead><tbody>{prec_rows()}</tbody></table>
  <h3>3D laser-engraved crystal <small>geometry floating inside a glass block</small></h3>
  <div class="minis">{laser_cards()}</div>
  <p class="disclaim">Idea: engrave the 600-cell or E8 point cloud inside a crystal cube. Placed in the beam, every engraved point scatters its own spark of light. Ask the maker whether they can work from a 3D point file.</p>
  <div class="brief"><b>What to send a custom maker</b>
    <ol><li>The shape: an SVG from <i>downloads/gobos_*.zip</i> or an outline from the catalogue.</li>
    <li>Size and thickness, and the tolerance you need (a flat, even bottom matters most).</li>
    <li>Material: borosilicate 3.3 for water vessels; optical or float glass for plates.</li>
    <li>Edge finish (seamed, polished) and whether it needs tempering.</li>
    <li>Quantity, budget and deadline. Ask for a quote and a lead time.</li></ol></div>
  {foot(4)}
</section>

<section class="page">
  <div class="band"><img src="{img('G100_flower_of_life.png')}"><div><div class="n">04</div><h2>Custom glass: art studios</h2><p>Commissioned panels, vessels and sculpture: fused, kiln-formed, blown and dichroic.</p></div></div>
  <div class="minis">{art_cards()}</div>
  <div class="brief"><b>Commission tips.</b> Studios usually ask for a design deposit, which goes toward the final price. Ask for a proposal before paying in full, and get the lead time in writing (one artist quotes 5-6 weeks). For a geometric dichroic piece, look for a studio that works in fused or kiln-formed glass. Send the matching catalogue preview so they can see the geometry.</div>
  <h3>Local glass towns worth a visit</h3>
  <table><tbody>
   <tr><td style="width:28%"><b>Vineland &amp; Millville, NJ</b></td><td>Scientific glass (Chemglass, Ace, Wilmad-LabGlass) and {a('WheatonArts', 'https://wheatonarts.org')}: museum, studio glass shop, live glassblowing (856-825-6800, open April-December).</td></tr>
   <tr><td><b>Philadelphia, PA</b></td><td>Hot-glass studios in East Falls, Manayunk and Kensington; stained-glass supply at {a('David Albert', 'https://startpage.mapquest.com/us/pennsylvania/david-albert-stained-glass-studio-2319475')}; maker directory at {a('CraftNOW', 'https://www.craftnowphila.org/artistsandmakers/glass/')}.</td></tr>
   <tr><td><b>Mullica Hill, NJ</b></td><td>Antique strip for vintage and Depression glass: {a('Old Mill Antique Mall', 'https://www.antiquetrader.com/directory-antique-businesses/the-old-mill-antique-mall')}, {a('The Parsonage', 'https://parsonage-site.pages.dev/')}.</td></tr>
  </tbody></table>
  {foot(5)}
</section>

<section class="page">
  <div class="band"><img src="{img('G164_faraday_12_fold_quasipattern.png')}"><div><div class="n">05</div><h2>Transparent &amp; translucent filament</h2><p>For light paths, filters, diffusers and rainbow (polariser) gobos.</p></div></div>
  <p class="lead">Clear PETG prints much more see-through than clear PLA, so use it wherever light passes through a print.</p>
  <table><thead><tr><th style="width:36%">Filament</th><th style="width:16%">Prints</th><th>Notes</th></tr></thead><tbody>{clear_rows()}</tbody></table>
  <div class="tips">
   <div class="tip"><h4>Printing for clarity</h4><ul><li>Dry the spool first (PETG soaks up moisture).</li><li>100% infill, slower and a little hotter, wide extrusion, so the layers fuse with no air gaps.</li><li>Flat on the bed, few walls; sand and clear-coat for glass-like faces.</li><li>Single-wall vase mode makes even diffusers.</li></ul></div>
   <div class="tip"><h4>The rainbow trick</h4><ul><li>Print a gobo in clear PETG.</li><li>Sandwich it between two polariser sheets in the beam.</li><li>Stress frozen in by printing shows as rainbow colours (photoelasticity).</li><li>Rotate one polariser and every colour shifts.</li></ul></div>
  </div>
  {foot(6)}
</section>

<section class="page">
  <div class="band"><img src="{img('G282_e8_root_polytope.png')}"><div><div class="n">06</div><h2>Effect filaments</h2><p>Glow, UV, heat, sparkle and shine: what each does, and where it belongs.</p></div></div>
  <div class="fxs">{effect_cards()}</div>
  {foot(7)}
</section>

<section class="page">
  <div class="band"><img src="{img('G202_hyperbolic_7_3.png')}"><div><div class="n">07</div><h2>Which material for which part</h2><p>Matched to the CYMATIC ODYSSEY parts list.</p></div></div>
  <table><thead><tr><th style="width:26%">Part</th><th style="width:30%">Material</th><th>Why</th></tr></thead><tbody>{map_rows()}</tbody></table>
  <div class="tips">
   <div class="tip"><h4>Hardware for effects</h4><ul><li>Hardened-steel nozzle for glow, glitter and metal-filled filament.</li><li>0.6 mm nozzle if you print a lot of galaxy or glitter.</li><li>A 365-395 nm UV LED channel to charge glow and trigger UV-shift and neon.</li></ul></div>
   <div class="tip"><h4>Keep out of the light path</h4><ul><li>Glitter, silk and metal fill: they scatter and block light.</li><li>Thermochromic near the LED heatsink.</li><li>PLA in water for weeks: use PETG for anything wet.</li></ul></div>
  </div>
  <p class="disclaim">Brand claims about clarity, glow strength and colour-change come from manufacturer, retailer and review pages. Test a small print from each spool before committing to a large part.</p>
  {foot(8)}
</section>

<section class="page back">
  <div class="art"><img src="{img('G277_600_cell.png')}"><img src="{img('G102_metatron_s_cube.png')}"><img src="{img('G126_cosmic_dance_venus_earth.png')}"></div>
  <h2>Build the chamber, light the wall.</h2>
  <p>Parts list with links: docs/SHOPPING_LIST.md · Build specs and safety: docs/BUILD_SPECS.md, docs/SAFETY.md · 355 printable looks: docs/GEOMETRY_CATALOG.md</p>
  <p style="margin-top:20pt;font-size:8.5pt;color:#8a8eb0">Links checked by web search, November 2026. Confirm prices, stock and hours with each business.</p>
</section>
</body></html>"""

out_html = HERE / "sourcing_guide.html"
out_html.write_text(HTML)
out_pdf = APP / "docs/CYMATIC_ODYSSEY_Sourcing_Guide.pdf"
js = f"""
const {{ chromium }} = require('playwright');
(async () => {{
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto({json.dumps(out_html.as_uri())}, {{waitUntil: 'load'}});
  await p.pdf({{ path: {json.dumps(str(out_pdf))}, format: 'Letter', printBackground: true, preferCSSPageSize: true }});
  await b.close();
}})();
"""
subprocess.run(["node", "-e", js], check=True)
print("wrote", out_pdf)
