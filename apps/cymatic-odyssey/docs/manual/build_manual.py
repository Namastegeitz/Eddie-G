#!/usr/bin/env python3
"""Builds docs/CYMATIC_ODYSSEY_Manual.pdf (v2): the complete, high-resolution illustrated manual.

    python3 docs/manual/build_assets.py   # high-resolution pictures (once; needs Blender renders + Playwright)
    python3 docs/manual/build_manual.py   # HTML -> Chromium print -> PDF

Every simulated picture carries a SIMULATION mark, Blender pictures a 3D RENDER mark, and every number
a Measured / Simulated / Estimated / Tradition label (docs/TRANSPARENCY.md).
"""
import html
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
sys.path.insert(0, str(APP / "tools"))
sys.path.insert(0, str(HERE))
from physics_tables import wavelength_mm, faraday_threshold, dish_modes  # noqa: E402
from diagrams import svg_system, svg_model, svg_wiring, svg_chain  # noqa: E402

E = html.escape
HI = HERE / "hires"
STYLES = json.loads((APP / "catalog/styles.json").read_text())
CONTENT = json.loads((APP / "catalog/content.json").read_text())
SHOWS = CONTENT["shows"]
SB = {s["id"]: s for s in STYLES}
CAT = {e["name"]: e for e in json.loads((APP / "catalog/geometry_catalog.json").read_text())}
VOL = {Path(r["file"]).name: r for r in json.loads((APP / "bambu/REPORT.json").read_text())["stl"]}
CONSOLE_URL = "https://claude.ai/artifact/STJTYLCynV5XHA1uNHifMX"
REPO = "github.com/namastegeitz/eddie-g · apps/cymatic-odyssey"


def im(name):
    return (HI / name).as_uri()


def a(t, u):
    return f'<a href="{E(u)}">{E(t)}</a>'


def lbl(kind):
    return {"est": '<span class="lbl est">ESTIMATED</span>', "sim": '<span class="lbl sim">SIMULATED</span>',
            "meas": '<span class="lbl meas">MEASURED</span>', "trad": '<span class="lbl trad">TRADITION</span>'}[kind]


def beat(f, ratio):
    if not ratio:
        return None
    d = abs(f * ratio[0] / ratio[1] - f)
    if 3 <= d <= 60:
        return ("drive", d)
    if 3 <= d / 2 <= 60:
        return ("half", d / 2)
    return None


# ------------------------------------------------------------------ page machinery
PAGES = []          # (html, chapter)
TOC = []            # (number, title, page)


def page(body, cls="", chapter="", foot=True):
    n = len(PAGES) + 1
    f = f'<div class="foot"><span>CYMATIC ODYSSEY · Complete Manual · v2</span><span>{E(chapter)}</span><span class="pn">{n}</span></div>' if foot else ""
    PAGES.append(f'<section class="page {cls}">{body}{f}</section>')
    return n


def chapter(num, title, sub, img=None):
    TOC.append((num, title, len(PAGES) + 1))
    pic = f'<img src="{im(img)}">' if img else ""
    return f'<div class="band">{pic}<div><div class="n">{num}</div><h2>{E(title)}</h2><p>{E(sub)}</p></div></div>'


def band(num, title, sub):
    return f'<div class="band slim"><div><div class="n">{num}</div><h2>{E(title)}</h2><p>{E(sub)}</p></div></div>'


# ------------------------------------------------------------------ charts
def svg_wavelength_chart():
    W, H, L, B, T, R = 640, 300, 56, 40, 18, 20
    xs = list(range(10, 201, 5))
    curves = [("Faraday, 3 mm deep", 0.003, 2, "#7fd4ff", ""), ("Faraday, 5 mm deep", 0.005, 2, "#ffd27a", ""),
              ("Faraday, 10 mm deep", 0.010, 2, "#b48cff", ""), ("Dipper, 5 mm deep", 0.005, 1, "#ff7aa8", "6 4")]
    ymax = 50
    X = lambda f: L + (f - 10) / 190 * (W - L - R)
    Y = lambda v: T + (1 - min(v, ymax) / ymax) * (H - T - B)
    g = [f'<svg viewBox="0 0 {W} {H}" class="chart"><rect width="{W}" height="{H}" fill="#fff"/>']
    for v in range(0, ymax + 1, 10):
        g.append(f'<line x1="{L}" x2="{W - R}" y1="{Y(v):.1f}" y2="{Y(v):.1f}" stroke="#e6e7f0"/><text x="{L - 8}" y="{Y(v) + 4:.1f}" text-anchor="end" font-size="11" fill="#5b5f7a">{v}</text>')
    for f in (10, 50, 100, 150, 200):
        g.append(f'<text x="{X(f):.1f}" y="{H - B + 18}" text-anchor="middle" font-size="11" fill="#5b5f7a">{f}</text>')
    g.append(f'<text x="{(L + W - R) / 2}" y="{H - 4}" text-anchor="middle" font-size="12" fill="#07081a">drive frequency (Hz)</text>')
    g.append(f'<text x="14" y="{(T + H - B) / 2}" text-anchor="middle" font-size="12" fill="#07081a" transform="rotate(-90 14 {(T + H - B) / 2})">wave spacing on the water (mm)</text>')
    for i, (name, h, div, col, dash) in enumerate(curves):
        pts = " ".join(f"{X(f):.1f},{Y(wavelength_mm(f / div, h)):.1f}" for f in xs)
        g.append(f'<polyline points="{pts}" fill="none" stroke="{col}" stroke-width="3" stroke-dasharray="{dash}"/>')
        g.append(f'<line x1="{W - 250}" x2="{W - 226}" y1="{T + 12 + i * 18}" y2="{T + 12 + i * 18}" stroke="{col}" stroke-width="3" stroke-dasharray="{dash}"/><text x="{W - 220}" y="{T + 16 + i * 18}" font-size="12" fill="#07081a">{name}</text>')
    g.append("</svg>")
    return "".join(g)


def svg_flow():
    steps = [("1", "Sound", "a tone from your phone", "#7fd4ff"), ("2", "Shake", "exciters or a dipper move the water", "#ffb347"),
             ("3", "Ripples", "standing waves, 3-20 mm apart", "#36ffb0"), ("4", "Lenses", "every ripple bends the light", "#ffd27a"),
             ("5", "Wall", "bright lines = caustics", "#ff7aa8")]
    w = 128
    out = ['<svg viewBox="0 0 660 150" class="chart">']
    for i, (n, t, d, c) in enumerate(steps):
        x = 8 + i * (w + 4)
        out.append(f'<rect x="{x}" y="10" width="{w - 10}" height="130" rx="14" fill="#07081a"/><circle cx="{x + 24}" cy="36" r="14" fill="{c}"/><text x="{x + 24}" y="41" text-anchor="middle" font-size="14" font-weight="800" fill="#07081a">{n}</text>')
        out.append(f'<text x="{x + 12}" y="78" font-size="17" font-weight="700" fill="#fff">{t}</text>')
        words, line, ly = d.split(), "", 100
        for wd in words:
            if len(line + " " + wd) > 17:
                out.append(f'<text x="{x + 12}" y="{ly}" font-size="11.5" fill="#b9bdd8">{E(line.strip())}</text>'); ly += 15; line = wd
            else:
                line += " " + wd
        out.append(f'<text x="{x + 12}" y="{ly}" font-size="11.5" fill="#b9bdd8">{E(line.strip())}</text>')
        if i < 4:
            out.append(f'<path d="M{x + w - 8},75 l9,0" stroke="#ffd27a" stroke-width="3"/><path d="M{x + w + 1},70 l6,5 l-6,5" fill="#ffd27a"/>')
    out.append("</svg>")
    return "".join(out)


# ------------------------------------------------------------------ content blocks
CSS = (HERE.parent / "sourcing/build_pdf.py").read_text().split('CSS = r"""')[1].split('"""')[0] + r"""
body { font-size: 10.6pt; line-height: 1.5; }
.page { padding: 0.6in 0.62in 0.62in; }
.band { margin: -0.6in -0.62in 16pt; padding: 0.45in 0.62in 0.3in; }
.band.slim { padding: 0.32in 0.62in 0.2in; margin-bottom: 12pt; } .band.slim h2 { font-size: 20pt; } .band.slim .n { font-size: 12pt; letter-spacing: .12em; }
.foot { display: flex; gap: 10pt; } .foot .pn { font-weight: 700; color: #07081a; }
h3 { font-size: 13.5pt; margin: 12pt 0 5pt; }
p { margin: 0 0 7pt; }
.diagram { width: 100%; height: auto; background: #07081a; border-radius: 12pt; }
.chart { width: 100%; height: auto; border: 1pt solid #e4e5ef; border-radius: 10pt; background: #fff; }
.mini-diagram { width: 100%; height: 1.55in; border-radius: 8pt; background: #0b0d1f; }
.models .mini-diagram { height: 1.2in; } .models .card { padding: 9pt 10pt; } .models h4 { margin: 0 0 3pt; font-size: 11pt; }
.models .meta { flex-wrap: nowrap; gap: 5pt; margin: 5pt 0 0; } .models .chip { font-size: 7.8pt; padding: 1.5pt 6pt; white-space: nowrap; }
.two { display: grid; grid-template-columns: 1fr 1fr; gap: 14pt; } .three { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10pt; }
.lbl { display: inline-block; font-size: 6.8pt; font-weight: 800; letter-spacing: .08em; padding: 1pt 5pt; border-radius: 4pt; vertical-align: 1pt; margin-left: 3pt; }
.lbl.est { background: #fff3d6; color: #8a6d1f; } .lbl.sim { background: #efe8ff; color: #6b3fd0; } .lbl.meas { background: #e5fbef; color: #127548; } .lbl.trad { background: #ffe8ef; color: #b02a5a; }
.legend-row { display: grid; grid-template-columns: 1.4in 1fr; gap: 6pt 14pt; align-items: start; font-size: 10pt; }
.card { border: 1pt solid #e4e5ef; border-radius: 10pt; padding: 10pt 12pt; break-inside: avoid; background: #fff; }
.card h4 { margin: 0 0 4pt; font-size: 11.5pt; }
.dark { background: #07081a; color: #e8e9f5; border-color: #07081a; } .dark h4 { color: #ffd27a; } .dark a { color: #7fd4ff; }
.warnbox { border-left: 4pt solid #ff4d5e; background: #fff0f1; padding: 9pt 12pt; border-radius: 0 8pt 8pt 0; font-size: 10pt; }
.okbox { border-left: 4pt solid #2fbf71; background: #ecfbf2; padding: 9pt 12pt; border-radius: 0 8pt 8pt 0; font-size: 10pt; }
.qs { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10pt; }
.qs .card { padding: 0; overflow: hidden; } .qs img { width: 100%; height: 1.55in; object-fit: cover; display: block; }
.qs .txt { padding: 8pt 10pt 10pt; font-size: 9.6pt; } .qs .num { display: inline-block; width: 20pt; height: 20pt; border-radius: 50%; background: #07081a; color: #ffd27a; text-align: center; line-height: 20pt; font-weight: 800; margin-right: 6pt; }
.toc2 { columns: 2; column-gap: 24pt; font-size: 11pt; } .toc2 p { display: flex; gap: 8pt; margin: 0 0 7pt; break-inside: avoid; }
.toc2 b { color: #ffd27a; background: #07081a; padding: 0 6pt; border-radius: 4pt; min-width: 24pt; text-align: center; } .toc2 .dots { flex: 1; border-bottom: 1pt dotted #b9bdd8; transform: translateY(-4pt); } .toc2 .pg { font-weight: 700; }
.step { display: grid; grid-template-columns: 4.1in 1fr; gap: 14pt; } .step img { width: 4.1in; border-radius: 10pt; display: block; }
.step ol { padding-left: 16pt; margin: 4pt 0; } .step li { margin-bottom: 5pt; }
.meta { display: flex; gap: 8pt; flex-wrap: wrap; margin: 4pt 0 8pt; } .chip { font-size: 8.5pt; padding: 2pt 8pt; border-radius: 10pt; background: #eef0fb; color: #2a2f55; }
.big-render { width: 100%; border-radius: 12pt; display: block; }
.annot { position: relative; } .annot img { width: 100%; border-radius: 10pt; display: block; border: 1pt solid #e4e5ef; }
.callout { position: absolute; width: 18pt; height: 18pt; border-radius: 50%; background: #ff4d5e; color: #fff; font-weight: 800; font-size: 9.5pt; text-align: center; line-height: 18pt; border: 2pt solid #fff; transform: translate(-50%, -50%); box-shadow: 0 1pt 4pt rgba(0,0,0,.4); }
.legend-list { columns: 2; font-size: 9.4pt; padding-left: 18pt; margin: 8pt 0; } .legend-list li { margin-bottom: 3pt; }
/* style pages */
.sp-head { display: flex; align-items: baseline; gap: 10pt; margin-bottom: 6pt; } .sp-head .sid { background: #07081a; color: #ffd27a; font-weight: 800; padding: 3pt 9pt; border-radius: 6pt; font-size: 13pt; }
.sp-head h3 { margin: 0; font-size: 22pt; font-family: 'Inter Display'; } .sp-head .mood { color: #6b6f8c; } .sp-head .sw { margin-left: auto; } .sw i { display: inline-block; width: 16pt; height: 16pt; border-radius: 4pt; margin-left: 3pt; border: 1pt solid #0002; }
.sp-grid { display: grid; grid-template-columns: 3.55in 1fr; gap: 12pt; }
.sp-grid .wall { width: 3.55in; height: 3.55in; border-radius: 50%; display: block; }
.sp-side img { width: 100%; display: block; border-radius: 8pt; margin-bottom: 6pt; } .sp-side .water { width: 1.5in; height: 1.5in; border-radius: 50%; }
.cap { font-size: 7.8pt; color: #6b6f8c; margin: -3pt 0 6pt; }
.guard { padding: 6pt 10pt; border-radius: 8pt; font-size: 9pt; margin: 6pt 0; } .guard.ok { background: #ecfbf2; color: #127548; } .guard.bad { background: #fff3d6; color: #7a5a10; }
.band.micro { padding: 0.2in 0.62in 0.12in; margin-bottom: 10pt; } .band.micro h2 { font-size: 12pt; color: #ffd27a; letter-spacing: .06em; }
table.kv { font-size: 8.7pt; } table.kv td { padding: 2.2pt 5pt; border-bottom: .6pt solid #eef; } table.kv td:first-child { color: #6b6f8c; width: 1.05in; }
.parts-strip { width: 100%; height: 0.72in; object-fit: contain; background: #05060d; border-radius: 8pt; display: block; margin-top: 6pt; }
/* show pages */
.tlimg { display: flex; gap: 3pt; margin: 8pt 0 2pt; } .tlimg div { position: relative; } .tlimg img { width: 100%; aspect-ratio: 1; object-fit: cover; border-radius: 6pt; display: block; }
.tlimg span { position: absolute; left: 3pt; top: 3pt; font-size: 7pt; font-weight: 800; background: #fffd; color: #07081a; padding: 0 3pt; border-radius: 3pt; }
.show-grid { display: grid; grid-template-columns: 1fr 2.15in; gap: 14pt; } .poster { width: 2.15in; border-radius: 10pt; display: block; }
table.steps { font-size: 8.8pt; } table.steps td { padding: 3.2pt 5pt; }
.gl dt { font-weight: 700; margin-top: 6pt; } .gl dd { margin: 0 0 0 0; color: #2a2f55; font-size: 9.6pt; } .gl { columns: 2; column-gap: 22pt; } .gl div { break-inside: avoid; }
.gallery6 { display: grid; grid-template-columns: repeat(6, 1fr); gap: 7pt; } .gallery6 figure { margin: 0; text-align: center; font-size: 7.6pt; } .gallery6 img { width: 100%; border-radius: 50%; display: block; margin-bottom: 2pt; }
.equation { display: grid; grid-template-columns: 1fr 14pt 1fr 14pt 1fr; align-items: center; gap: 6pt; } .equation img { width: 100%; } .equation .op { font-size: 22pt; font-weight: 800; color: #ffd27a; text-align: center; }
.role { font-size: 7pt; font-weight: 700; padding: 1pt 5pt; border-radius: 8pt; background: #eef; } .role.opening { background: #e8f4ff; color: #1d5fa8; } .role.guest { background: #f1e8ff; color: #6b3fd0; } .role.bridge { background: #fff3d6; color: #8a6d1f; }
.tlx { display: flex; justify-content: space-between; font-size: 7pt; color: #9a9db6; } td.t { font-variant-numeric: tabular-nums; color: #6b6f8c; }
ol.steps { padding-left: 16pt; margin: 4pt 0; } ol.steps li { margin-bottom: 4pt; }
table.tight td { padding: 2.6pt 6pt; font-size: 9pt; }
.posters { display: grid; grid-template-columns: repeat(8, 1fr); gap: 6pt; } .posters img { width: 100%; border-radius: 6pt; display: block; }
"""

# ------------------------------------------------------------------ cover
cover_ids = ["S03", "S05", "S09", "S02", "S11", "S08", "S13", "S19", "S06", "S10", "S26", "S04", "S12", "S21", "S29", "S01"]
page(f'''<div class="mosaic">{"".join(f'<img src="{im(i + "_wall.jpg")}">' for i in cover_ids)}</div><div class="shade"></div>
<div class="text"><div class="kicker">CYMATIC ODYSSEY · THE COMPLETE MANUAL · VERSION 2</div><h1>Sound becomes<br><span>geometry of light</span></h1>
<div class="sub">Every step from your first flashlight test to a 150-minute light show: how it works, safety, five builds, printing on Bambu Lab printers, illustrated assembly, the console, all 30 styles and all 15 shows.</div>
<div class="meta"><div><b>30</b>styles, one page each</div><div><b>15</b>shows, 150 min</div><div><b>7</b>illustrated assembly steps</div><div><b>Nov 2026</b>high-resolution edition</div></div></div>''', "cover", foot=False)

# ------------------------------------------------------------------ how to read
page(band("", "How to read this manual", "Labels, marks and symbols used on every page.") + f'''
<div class="two"><div>
<h3>Every number says where it comes from</h3>
<div class="legend-row"><div>{lbl("meas")}</div><div>Measured on a real chamber with a sensor or camera. <i>(None yet: the chamber hasn't been built and measured. Your calibration creates the first measured numbers.)</i></div>
<div>{lbl("sim")}</div><div>Computed by a physics model and drawn by a computer.</div>
<div>{lbl("est")}</div><div>A calculation with stated assumptions, e.g. wave spacing for 5 mm of 20 °C water.</div>
<div>{lbl("trad")}</div><div>A cultural practice or belief, offered as such, not as science.</div></div>
<h3>Every picture says what it is</h3>
<p><b>SIMULATION</b>: a computer-made picture of what the light should look like. It's never presented as real footage.<br>
<b>3D RENDER</b>: a computer drawing of the hardware made in Blender from the real STL files.<br>
<b>REAL FOOTAGE</b>: a photo or video frame of something that really happened (your first tests).</p>
</div><div>
<h3>Boxes</h3>
<div class="warnbox"><b>Red box: safety.</b> Read it before you do the step.</div><br>
<div class="okbox"><b>Green box: check.</b> What you should see if the step went right.</div><br>
<div class="brief"><b>Gold box: tip.</b> Something that makes the job easier.</div>
<h3>Chips</h3><div class="meta"><span class="chip">⏱ time</span><span class="chip">🔧 tools</span><span class="chip">◎ difficulty</span></div>
<h3>On your phone</h3><p>The Voyage console runs in a browser: <a href="{CONSOLE_URL}">{CONSOLE_URL}</a>. Project files: {E(REPO)}.</p>
</div></div>
<div class="brief" style="margin-top:12pt"><b>Honest status.</b> Everything in this manual is designed, generated and checked by software (watertight meshes, verified 3MF files, physics fixtures). The chamber itself hasn't been built yet, so frequencies are <b>starting points</b>: tune by eye and record what your chamber really does (chapter 7).</div>''', chapter="Read me")

TOC_SLOT = len(PAGES)
page("", chapter="Contents")  # placeholder, filled after all pages exist

# ------------------------------------------------------------------ quick start
qs = [("your_first_test.jpg", "Try it tonight", "Shine a small flashlight through a clear dish of water onto a wall and tap the water. That's Model C; you've already done it."),
      ("S05_wall.jpg", "Pick a style", "Choose one of the 30 styles (chapter 9). S05 Metatron and S01 Orbit Rings are good first prints."),
      ("step2.jpg", "Print the parts", "Print its gobo in white, its insert and foot in PETG (chapter 5). Bambu users: open the ready 3MF plate."),
      ("step3.jpg", "Build the chamber", "Follow the seven illustrated steps (chapter 6), or start with the Desk Dipper mini build."),
      ("console_phone.jpg", "Open the console", "On your phone, open the console, pair the amp's Bluetooth and press Start audio at 10% volume (chapter 8)."),
      ("S03_wall.jpg", "Play a show", "Pick one of 15 shows, tick Continuous, and the light flows for up to 150 minutes (chapter 10).")]
page(chapter("00", "Quick start", "From a flashlight test to a full show, in six steps.") +
     '<div class="qs">' + "".join(f'<div class="card"><img src="{im(f)}"><div class="txt"><span class="num">{i + 1}</span><b>{E(t)}</b><br>{E(d)}</div></div>' for i, (f, t, d) in enumerate(qs)) + "</div>" +
     '<div class="warnbox" style="margin-top:12pt"><b>Before step 4:</b> read chapter 2. Water and electricity share a box; the Tesla coil never goes near the water; and light must never flash quickly.</div>', chapter="Quick start")

# ------------------------------------------------------------------ 1 how it works
page(chapter("01", "How it works", "Five links in a chain: sound, shake, ripples, lenses, wall.") + svg_flow() + '<div style="height:10pt"></div>' + svg_system() +
     '''<div class="two" style="margin-top:10pt"><div class="card"><h4>The idea in one sentence</h4>A rippled water surface acts like thousands of tiny lenses: light passing through it bunches into bright lines (caustics), and sound decides the ripple pattern.</div>
<div class="card"><h4>Three ways to add geometry</h4><b>Gobo:</b> a printed stencil the light passes through. <b>Insert:</b> sets the shape of the water's "drum". <b>Signal:</b> one or two tones choose squares, hexagons or 12-fold patterns.</div></div>''', chapter="How it works")

page(band("01", "Two ways to shake the water", "Faraday (whole dish) makes standing patterns; the dipper launches rings.") + f'''
<div class="two"><div class="card"><h4>Faraday drive: the whole dish moves</h4>
<img src="{im("S18_water.jpg")}" style="width:2.4in;border-radius:50%;display:block;margin:4pt auto">
<p>Four exciters under the platform move the dish up and down by a few hundredths of a millimetre {lbl("est")}. Above a threshold the flat surface becomes unstable and grows <b>standing waves at half the drive frequency</b> (Faraday, 1831). One tone usually gives squares.</p></div>
<div class="card"><h4>Dipper drive: a foot taps the surface</h4>
<img src="{im("S01_water.jpg")}" style="width:2.4in;border-radius:50%;display:block;margin:4pt auto">
<p>A small speaker moves a printed foot that just touches the water. It sends <b>travelling rings at the drive frequency</b>; tone bursts make them pulse outward. Two pins interfere, three pins weave a hexagonal net.</p></div></div>
<h3>How far apart the ripples are {lbl("est")}</h3>{svg_wavelength_chart()}
<p style="font-size:9pt;color:#5b5f7a">From the capillary-gravity dispersion relation, water at 20 °C. It agrees with the spec's reference table within 0.62 %. Above about 30 Hz, depth hardly matters.</p>''', chapter="How it works")

ratios = [("single tone", "squares", "S18"), ("2:3", "hexagons and triangles", "S02"), ("4:5", "12-fold quasipattern", "S03"), ("6:7", "superlattice (hex inside hex)", "S29")]
page(band("01", "Choosing the pattern with two tones", "Ratios between two drive tones select the symmetry (lab results; plain water may not always show them).") +
     '<div class="three" style="grid-template-columns:repeat(4,1fr)">' + "".join(f'<div class="card" style="text-align:center"><img src="{im(s + "_water.jpg")}" style="width:100%;border-radius:50%"><b>{r}</b><br><span style="font-size:9pt">{t}</span></div>' for r, t, s in ratios) + "</div>" +
     f'''<div class="warnbox" style="margin-top:12pt"><b>Flicker rule for two tones.</b> When the two drive tones differ by 3-60 Hz (e.g. 40 Hz + 50 Hz → 10 Hz), the projected light can flicker at that difference, which can trigger seizures in photosensitive people. The new app's Safety Guardian turns the second tone down to 10 % (or moves it) unless Lab mode is switched on with a warning. <b>12 of the 30 styles</b> use such pairs; their pages say so.</div>
<h3>How a style is built: S05 Metatron</h3>
<div class="equation"><div><img src="{im("S05_water.jpg")}" style="border-radius:50%"><p style="text-align:center;font-size:9pt">the water: 36 + 54 Hz (2:3) in a hexagon insert</p></div><div class="op">+</div>
<div><img src="{(APP / "previews/items/G102_metatron_s_cube.png").as_uri()}" style="border-radius:50%"><p style="text-align:center;font-size:9pt">the gobo: Metatron's Cube</p></div><div class="op">=</div>
<div><img src="{im("S05_wall.jpg")}" style="border-radius:50%"><p style="text-align:center;font-size:9pt">the wall: lines bend and breathe with the water</p></div></div>''', chapter="How it works")

# ------------------------------------------------------------------ 2 safety
page(chapter("02", "Safety", "Read all of this before building. Full version: docs/SAFETY.md and docs/TRANSPARENCY.md.") + '''
<div class="two"><div class="tip"><h4>The EZ-100 Tesla coil</h4><ul><li>It can't shake water: it's a plasma-arc speaker.</li><li><b>Never</b> in, on or near the water chamber; keep it 50 cm away in its own dry, ventilated bay.</li><li>Arcs cause RF burns, ozone and fire. Keep people with implants away.</li><li>Not part of any business install or sold kit.</li></ul></div>
<div class="tip"><h4>Water and power</h4><ul><li>24 V DC only inside the chamber, from a UL/ETL-listed brick on a GFCI/RCD outlet; 5 A fuse.</li><li>Electronics beside or above the water, never under it; drip tray under the dish; drip loops on every cable.</li><li>Unplug before filling, emptying or cleaning.</li></ul></div>
<div class="tip"><h4>Light and flicker</h4><ul><li>Flashing between about 3 and 60 times a second can trigger seizures.</li><li>No strobe mode, by design. Lights change slowly (no more than 1.5 flashes per second, fades of at least ⅓ s).</li><li>Two-tone beats of 3-60 Hz are turned down or moved (see page before).</li><li>LED dimming at 20 kHz or above; post a notice in public spaces.</li></ul></div>
<div class="tip"><h4>Sound</h4><ul><li>Master volume starts at −18 dBFS; fades last at least 2 s in and 3 s out.</li><li>Headphone modes: not while driving or operating machinery.</li><li>Square waves and high drive frequencies get loud; keep the amp gain low.</li></ul></div>
<div class="tip"><h4>Water and materials</h4><ul><li>Distilled water + 1 drop of dish soap; optional glycerin for thicker water.</li><li><b>Never mercury</b> or other toxic or reactive liquids.</li><li>Borosilicate glass only; PETG or ASA near warm LEDs (PLA softens at 55-60 °C).</li></ul></div>
<div class="tip"><h4>Health claims</h4><ul><li>This is an art and relaxation experience, not therapy or a medical device.</li><li>If you have epilepsy, light or sound sensitivity, tinnitus, or are under medical or mental-health care, check with your clinician first.</li><li>Every wellness sentence must have an evidence-graded claim ID (claims register).</li></ul></div></div>''', chapter="Safety")

# ------------------------------------------------------------------ 3 models
models = [("A", "Compact Chamber (flagship)", "LED below, lens and 45° mirror above; platform + dipper; 300 × 300 × 420 mm.", "Sharp 1-3 m pictures in a dim room. This is the build in chapter 6.", "about $300-450", "2 weekends", "intermediate"),
          ("B", "Overhead Projector", "Platform and dish on a used overhead projector's glass; its head projects the caustics.", "Brightest, simplest optics. Halogen stages warm the water: short sessions or an LED projector.", "about $150 + projector", "1 day", "easy"),
          ("C", "Shadow Caster (starter)", "Flashlight through a jar or dish onto a wall 0.5-1.5 m away; no lens.", "Free, instant, soft and large. Great for trying gobos and inserts.", "$0-30", "10 minutes", "easy"),
          ("D", "Venue Pro", "3 high-power LEDs, 300 mm dish, ceiling or dome projection, sealed IP-rated electronics, DMX input.", "Lobbies, planetariums, events. Assembled units only after an electrical safety review.", "about $500-800 to build", "2-3 weekends", "advanced"),
          ("E", "Desk Dipper (mini)", "Small dish, 3-inch speaker + dipper arm, phone torch underneath, ceiling projection.", "Weekend build; dipper styles only (rings, interference, pulses).", "$40-60", "1 afternoon", "easy")]
page(chapter("03", "Five models to build", "Same physics, different sizes and budgets.") +
     '<div class="three models">' + "".join(f'<div class="card">{svg_model(k)}<p style="font-size:8pt;color:#8a6d1f;font-weight:700;margin:6pt 0 2pt">MODEL {k} · {E(c)}</p><h4>{E(n)}</h4><p style="font-size:9pt;margin:0 0 4pt">{E(d)}</p><p style="font-size:9pt;color:#5b5f7a;margin:0">{E(w)}</p><div class="meta"><span class="chip">⏱ {t}</span><span class="chip">◎ {lv}</span></div></div>' for k, n, d, w, c, t, lv in models) +
     '<div class="card dark"><h4>Which one first?</h4><p style="font-size:9.6pt">Start with <b>C</b> tonight, build <b>E</b> next to learn the dipper styles, then <b>A</b> for the full shows. Choose <b>B</b> if you find a cheap overhead projector, and <b>D</b> for a venue.</p><p style="font-size:9.6pt">Styles marked <i>dipper</i> run on every model; <i>platform</i> styles need A, B or D.</p></div></div>', chapter="Models")

# ------------------------------------------------------------------ 4 parts
parts = [("4", "Exciter", "Dayton DAEX32EP-4 (32 mm, 40 W, 4 Ω)", "Parts Express 295-230"), ("1", "Dipper speaker", "3-3.5\" full range, 15-20 W, 8 Ω", "Dayton CE81PF-8 or ND90-8"),
         ("1", "Amplifier", "TPA3116D2 2 × 50 W, Bluetooth", "Parts Express 320-6051"), ("1", "Power brick", "24 V 5 A, UL listed", "Mean Well GST120A24"),
         ("1", "Light", "10 W single-die LED star + driver + heatsink", "LEDSupply 10W Dynamic kit"), ("1", "Dish", "150 mm borosilicate, flat bottom", "McMaster-Carr"),
         ("1", "Mirror", "first-surface, about 75 × 100 mm", "Edmund Optics #4614"), ("1", "Lens", "75-90 mm glass, ~100 mm focal length", "2.5-3× hand magnifier"),
         ("4", "Isolation feet", "Sorbothane hemispheres 25 mm", "McMaster / Edmund"), ("4", "Support posts", "aluminium tube or M8 rod, 206 mm", "hardware store"),
         ("3", "Optics rods", "M5 threaded rod, 300 mm, with nuts", "McMaster / hardware store"), ("1", "Rainbow film (optional)", "diffraction grating, 500 lines/mm", "Rainbow Symphony"),
         ("1", "Colour (optional)", "ESP32 + 3 colour LEDs, WLED firmware", "any"), ("1 set", "Enclosure", "3 mm acrylic, about 300 × 300 × 420 mm, drip tray", "plastics shop"),
         ("—", "Small parts", "M3 screws, 5 A inline fuse, wire, cable ties, glue", "hardware store"), ("1-2 kg", "Filament", "PETG + white PLA/PETG", "see Sourcing Guide")]
tools = ["3D printer (220 mm bed for the full platform, or an A1 mini with the 4-quarter version)", "soldering iron + heat-shrink", "hex keys, small screwdrivers", "bubble level", "multimeter (check polarity and the 24 V line)", "hot glue or epoxy (dipper arm to dust cap)", "measuring calipers (dish inside diameter)"]
page(chapter("04", "Parts and tools", "For Model A. Links and prices: docs/SHOPPING_LIST.md and the Sourcing Guide PDF.") +
     '<table class="tight"><thead><tr><th>Qty</th><th>Part</th><th>Spec to match</th><th>Suggested source</th></tr></thead><tbody>' +
     "".join(f"<tr><td>{q}</td><td><b>{E(p)}</b></td><td>{E(s)}</td><td>{E(w)}</td></tr>" for q, p, s, w in parts) + '</tbody></table>' +
     f'<div class="two" style="margin-top:8pt"><div class="card"><h4>Tools</h4><div class="meta">{"".join(f"<span class=chip>{E(t)}</span>" for t in tools)}</div></div><div class="brief"><b>Budget</b> {lbl("est")}: about $300-450 for Model A. Measure your dish\'s inside diameter <b>before</b> printing inserts, then run <code>python3 tools/generate.py --dish-id &lt;mm&gt;</code>. Check the platform\'s 50.5 mm exciter rings against the exciter datasheet.</div></div>', chapter="Parts")

# ------------------------------------------------------------------ 5 printing
page(chapter("05", "Printing the parts", "Every part was checked watertight; 65 Bambu Studio plates were verified with the official 3MF library.") + '''
<table><thead><tr><th>Part</th><th>Material</th><th>Settings</th><th>Why</th></tr></thead><tbody>
<tr><td><b>Gobo</b> (110 mm)</td><td>white PLA or PETG</td><td>0.20 mm layers, 100 % infill, flat, no supports</td><td>0.6 mm base lets light through; 2.4 mm lines block it (lithophane principle)</td></tr>
<tr><td><b>Two-colour gobo</b> (AMS)</td><td>base white/translucent, lines black</td><td>open <code>S##_..._gobo_2color.3mf</code>; assign filament per part</td><td>black lines block far more light: much sharper stencil</td></tr>
<tr><td><b>Gobo on film</b></td><td>laser-printer transparency</td><td>print the SVG at 100 %</td><td>sharpest of all; tint with colour gels</td></tr>
<tr><td><b>Rainbow gobo</b></td><td>clear PETG</td><td>as gobo</td><td>between two polarisers, printing stress glows in rainbow colours</td></tr>
<tr><td><b>Boundary insert</b></td><td>PETG (water-safe)</td><td>3 walls, 30 % infill, sand bottom flat</td><td>three slots let water equalise under the ring</td></tr>
<tr><td><b>Dipper foot</b></td><td>PETG or resin</td><td>0.16 mm, 100 % infill, brim</td><td>stiff, so the wave isn't absorbed</td></tr>
<tr><td><b>Platform</b> (200 mm)</td><td>plain PETG</td><td>4 walls, 40 % gyroid</td><td>stiffness first; A1 mini: print the quarter 4 times</td></tr>
<tr><td><b>Other hardware</b></td><td>PETG (sparkle/silk OK)</td><td>defaults</td><td>outside the light path</td></tr></tbody></table>
<div class="brief" style="margin-top:8pt"><b>Shortcut:</b> every style has a ready kit (<code>downloads/CYMATIC_ODYSSEY_30_style_kits.zip</code>) and a ready Bambu Studio plate; you don't have to pick files one by one.</div>''', chapter="Printing")
page(band("05", "Printing on Bambu Lab printers", "Open a ready plate, pick filament, print.") + '''<h3 style="margin-top:0">Bambu Studio in five clicks</h3>
<ol class="steps" style="padding-left:16pt"><li>Unzip <code>downloads/CYMATIC_ODYSSEY_Bambu_Studio.zip</code>.</li><li>File → Open Project → <code>bambu/styles/S05_metatron.3mf</code> (or any style).</li><li>If asked whether to <b>load geometry only</b>, answer <b>Yes</b>: the insert, gobo and foot arrive arranged on the plate with their names.</li><li>Pick printer, filament and process; for two-colour gobos, set the filament on each part.</li><li>Slice, check the preview, print.</li></ol>
<div class="two"><div class="card"><h4>A1 mini (180 mm bed)</h4>Everything fits except the 200 mm platform. Print <code>a1mini_platform_x2.3mf</code> twice (2 quarters + 2 splice plates per plate), then join the 4 quarters with 16 × M3×12 screws and nuts.</div>
<div class="card"><h4>Print order, first evening</h4>1) gobo S05 or S01 (about 1 h each) · 2) circle insert + point foot · 3) dipper arm + gobo carrier: try them on Model C right away · 4) then the platform, cups, LED cradle, lens ring and mirror holder.</div></div>
<h3>What a style kit looks like</h3>''' + f'<img class="parts-strip" style="height:1.3in" src="{im("S05_parts.jpg")}">' + '''<p style="font-size:9.6pt;margin-top:6pt">Left to right: the gobo (light stencil), the boundary insert for the dish, and the wave source (here the whole dish shakes, so no foot). In the <b>two-colour</b> gobo the round base is one part and the lines + rim are a second part, so the AMS can print the lines in black.</p>
<div class="brief" style="margin-top:8pt"><b>Not tested:</b> the files were checked with the 3MF library, but not opened in the Bambu Studio app itself (no desktop app was available while building them).</div>''', chapter="Printing")

# ------------------------------------------------------------------ 6 assembly
steps = [
 ("Base, light and amplifier", "step1.jpg", ["LED cradle + 40 mm heatsink + 10 W LED star", "amplifier board", "acrylic base plate + drip tray"], "45 min", ["Screw the LED cradle to the centre of the base plate, LED pointing up.", "Mount the heatsink and LED star (thermal paste or pad).", "Place the amplifier to the side, near the back; keep every electrical part out of the area under the dish.", "Fit the drip tray at dish level later (step 4)."], "The LED sits exactly under where the dish centre will be, 150-250 mm below it."),
 ("Gobo carrier", "step2.jpg", ["gobo carrier ring", "your first gobo (e.g. G102 Metatron)"], "10 min", ["The carrier sits just under the platform aperture (it hangs from the platform in the final build).", "Drop the gobo into the carrier's 2 mm ledge, print side up.", "The beam from the LED now passes through the stencil."], "With the LED on in a dark room you see a soft shadow of the gobo on the ceiling."),
 ("Platform, exciters and supports", "step3.jpg", ["platform (or 4 A1-mini quarters + splice plates)", "4 × DAEX32EP-4 exciters", "4 foot cups + 4 Sorbothane hemispheres", "4 support posts"], "1.5 h", ["Bond the four exciters to the rings under the platform with their adhesive pads; all the <b>same polarity</b>.", "Stand the four posts at the corners; put a foot cup with a Sorbothane hemisphere on each.", "Rest the platform on the four hemispheres so it floats.", "Wire exciters 1+2 in series and 3+4 in series, then the two pairs in parallel (4 Ω), to the amp's <b>left</b> channel."], "Tapping a corner, the platform rocks gently and settles; it isn't screwed down."),
 ("Dish, insert and water", "step4.jpg", ["150 mm borosilicate dish", "boundary insert", "distilled water + 1 drop of soap"], "15 min", ["Set the dish into the platform's 152 mm recess and level it with a bubble level (shim the feet).", "Drop the insert into the dish.", "Fill to 5 mm with distilled water and one drop of dish soap.", "Fit the drip tray under the dish."], "Water is level: the depth is the same all round the insert."),
 ("Dipper", "step5.jpg", ["3-3.5\" speaker", "dipper arm", "dipper foot", "M3 set screw"], "40 min", ["Mount the speaker facing up on the fixed frame beside the dish (not on the platform).", "Glue the arm's round pad to the speaker's dust cap.", "Slide a foot's stem through the far end until the foot just kisses the water; lock it with the set screw.", "Wire the speaker to the amp's <b>right</b> channel."], "A gentle tone makes rings travel outward from the foot."),
 ("Optics: lens and mirror", "step6.jpg", ["3 × M5 rods + nuts", "lens ring + 80 mm lens", "mirror holder + first-surface mirror"], "45 min", ["Fix three M5 rods to the frame (not the moving platform).", "Thread the lens ring onto the rods 10-20 cm above the water.", "Put the 45° mirror holder above; slide the mirror in, silver side facing down toward the lens.", "Turn the LED on and move the lens up or down until the lines on the wall are crisp."], "A sharp, bright pattern on a wall 2-3 m away, about 1-3 m wide."),
 ("Enclosure", "step7.jpg", ["acrylic panels", "panel corners (8-12)", "M3 screws"], "1 h", ["Join the panels with the printed corners; leave the front open or windowed for the beam.", "Vent the back panel.", "Route every cable with a drip loop; fuse the 24 V line (5 A).", "Plug the brick into a GFCI/RCD outlet outside the splash zone."], "Nothing electrical can be reached by a spill; the chamber stands steady."),
]
page(chapter("06", "Assembly", "Model A in seven illustrated steps. Gold parts are the ones added in each step.", None) +
     f'<img src="{im("exploded.jpg")}" class="big-render" style="max-height:6.1in;object-fit:cover">' +
     '<div class="two" style="margin-top:10pt"><div class="card"><h4>Total</h4>about 5-6 hours of assembly after printing {0}. Do steps 1-4 first and you can already make Faraday patterns.</div><div class="warnbox"><b>Before you power on:</b> check the 24 V polarity with a multimeter, make sure nothing electrical sits under the dish, and plug into a GFCI/RCD outlet.</div></div>'.format(lbl("est")), chapter="Assembly")
for i, (t, img, plist, tm, ins, check) in enumerate(steps, 1):
    page(band("06", f"Step {i} of 7 · {t}", "Gold = new in this step.") +
         f'<img src="{im(img)}" class="big-render" style="max-height:5.2in;object-fit:cover;margin-bottom:10pt">' +
         f'<div class="two"><div><h3 style="margin-top:0">You need</h3><ul style="padding-left:16pt;margin:0">{"".join(f"<li>{p}</li>" for p in plist)}</ul><div class="meta" style="margin-top:8pt"><span class="chip">⏱ {tm} {lbl("est")}</span></div></div>'
         f'<div><h3 style="margin-top:0">Do this</h3><ol style="padding-left:16pt;margin:0">{"".join(f"<li>{x}</li>" for x in ins)}</ol></div></div>'
         f'<div class="okbox" style="margin-top:10pt"><b>Check:</b> {check}</div>', chapter="Assembly")

page(band("06", "Wiring", "Split channels let the shows switch between platform and dipper by themselves.") + svg_wiring() + f'''
<div class="two" style="margin-top:10pt"><div><h3>Connections</h3><table class="kv"><tbody>
<tr><td>Amp LEFT</td><td>platform: exciters (1+2 series) ∥ (3+4 series) = 4 Ω</td></tr>
<tr><td>Amp RIGHT</td><td>dipper speaker, 8 Ω</td></tr>
<tr><td>Amp power</td><td>24 V brick → 5 A inline fuse → amp + LED driver</td></tr>
<tr><td>Audio in</td><td>phone over Bluetooth (or AUX cable)</td></tr>
<tr><td>Console</td><td><i>Wiring: Split</i> (automatic mode switching)</td></tr></tbody></table>
<p style="font-size:9pt;margin-top:6pt"><b>Alternative:</b> the same signal on both channels with a DPDT switch box; set the console to <i>Wiring: Both</i>.</p></div>
<div><div class="warnbox"><b>Polarity:</b> all four exciters must push the same way. If the pattern leans or drifts to one side, swap the wires on one exciter and test again.</div><br>
<div class="warnbox"><b>Tesla coil:</b> it never shares this wiring or this box. If you use it, it sits on its own base at least 50 cm away, fed by its own Bluetooth.</div></div></div>''', chapter="Wiring")

# ------------------------------------------------------------------ 7 first light
rows = []
for fd in (20, 30, 40, 50, 60, 80):
    a_, d_ = faraday_threshold(fd, 0.005, 3.0)
    rows.append(f"<tr><td>{fd} Hz</td><td>{fd / 2:g} Hz</td><td>{wavelength_mm(fd / 2, 0.005):.1f} mm</td><td>{112 / wavelength_mm(fd / 2, 0.005):.1f}</td><td>{a_ / 9.81:.2f} g / {d_ * 1e6:.0f} µm</td></tr>")
modes = dish_modes(0.056, 0.005, 10)
page(chapter("07", "First light and calibration", "From switch-on to your own pattern map in 20 minutes.") + f'''
<div class="two"><div><h3 style="margin-top:0">First light</h3><ol class="steps" style="padding-left:16pt">
<li>Fill 5 mm of distilled water + 1 drop of soap; dim the room.</li>
<li>Open the console on your phone; pair it with the amp's Bluetooth.</li>
<li>Press <b>Start audio</b> at 10 % volume. Tap style <b>S18 Chladni Plate</b>.</li>
<li>Raise the volume slowly until squares appear, then stop just above that point: that's where lines are sharpest.</li>
<li>Set <b>Wiring: Split</b> and tap <b>S01 Orbit Rings</b>: the dipper should take over.</li></ol>
<div class="okbox"><b>Check:</b> squares at 30-50 Hz, rings from the dipper, no droplets or splashing.</div></div>
<div><h3 style="margin-top:0">Build your pattern atlas</h3><ol class="steps" style="padding-left:16pt">
<li>Try S02 (hexagons) and S03 (12-fold). Nudge the frequency with ±0.1 / ±1 until each locks.</li>
<li>Press <b>Log what I see</b> on good looks: these become your first {lbl("meas")} numbers.</li>
<li>Optional: point a webcam at the wall and run <code>tools/mode_mapper.py</code>: it sweeps, recognises each pattern and writes an atlas.</li>
<li>Re-run when the water level or room temperature changes.</li></ol></div></div>
<h3>Starting points for 5 mm of water {lbl("est")}</h3>
<table><thead><tr><th>Drive</th><th>Water answers at</th><th>Wave spacing</th><th>Waves across 112 mm</th><th>Shake needed (onset)</th></tr></thead><tbody>{"".join(rows)}</tbody></table>
<h3>Natural modes of a 112 mm insert {lbl("est")}</h3><p style="font-size:9.4pt">{" · ".join(f"({m},{n}) {f:.1f} Hz" for f, m, n, k in modes)} (dipper at this frequency, or Faraday at twice it).</p>''', chapter="First light")

# ------------------------------------------------------------------ 8 console
bx = json.loads((HI / "console_desktop_boxes.json").read_text())
call = [("startBtn", "Start audio (always first; browsers need a tap)"), ("panicBtn", "Stop: fades everything out"), ("fsBtn", "Projector mode: full-screen preview"),
        ("mode", "Drive mode: Faraday (platform) or Dipper"), ("f", "Drive frequency, with ±0.1 / ±1 nudges"), ("ratio", "Second tone ratio (2:3, 4:5, 6:7...)"),
        ("pulse", "Pulse: tone bursts that launch rings"), ("breathe", "Breathe: slow swell, 0.1 Hz = 6 breaths a minute"), ("vol", "Volume: start at 10 %"),
        ("wiring", "Wiring: Split = automatic platform/dipper switching"), ("sim", "Live preview (SIMULATION), the same physics model as this manual"),
        ("gobo", "Gobo shown in the preview"), ("read", "Readout: water frequency, wave spacing (ESTIMATED)"), ("voy", "Shows and voyages"),
        ("cont", "Continuous: one show flows into the next"), ("theme", "Holiday and observance themes"), ("gal", "30-style gallery: tap to load a style")]
W = bx["w"]
marks = "".join(f'<div class="callout" style="left:{(b["x"] + min(b["width"], 60) / 2) / W * 100:.2f}%;top:{(b["y"] + b["height"] / 2) / bx["h"] * 100:.2f}%">{i + 1}</div>' for i, (k, _) in enumerate(call) if (b := bx["boxes"].get(k)))
page(chapter("08", "The Voyage console", "Runs in any browser, on your phone too. Desktop view while a show plays.") +
     f'<div class="annot"><img src="{im("console_desktop.jpg")}">{marks}</div><ol class="legend-list">' + "".join(f"<li>{E(t)}</li>" for k, t in call) + '</ol>', chapter="Console")
page(band("08", "The console on your phone", "Same app, stacked for one hand: preview on top, controls below.") + f'''
<div class="two" style="grid-template-columns:1fr 1fr 1.25fr"><img src="{im("console_phone.jpg")}" style="width:100%;border-radius:14pt;border:1pt solid #e4e5ef"><img src="{im("console_phone_gallery.jpg")}" style="width:100%;border-radius:14pt;border:1pt solid #e4e5ef">
<div><h3 style="margin-top:0">Playing a show</h3><ol class="steps" style="padding-left:16pt"><li>Open <a href="{CONSOLE_URL}">the console link</a>.</li><li>Tap <b>Start audio</b>; pair with the amp over Bluetooth first.</li><li>Choose a show, tick <b>Continuous</b>, tap <b>Play</b>.</li><li>Gold "optional cue" lines tell you when a gobo or foot change fits; you can ignore them.</li><li><b>Stop</b> fades everything out.</li></ol>
<div class="brief"><b>Turn off silent mode</b> on iPhone, or Web Audio stays quiet. Keep the screen awake for long shows (iOS may pause audio when the screen locks).</div></div></div>''', chapter="Console")

# ------------------------------------------------------------------ 9 styles
page(chapter("09", "The 30 styles", "One complete look each: gobo + insert + wave source + signal + colours. One page per style follows.") +
     '<div class="gallery6">' + "".join(f'<figure><img src="{im(s["id"] + "_wall.jpg")}">{s["id"]} {E(s["name"])}</figure>' for s in STYLES) + "</div>" +
     '<p style="font-size:9pt;color:#5b5f7a;margin-top:8pt">All pictures are SIMULATIONS from the console\'s physics model; your real wall will be sharper or softer depending on the LED, lens and room.</p>', chapter="Styles")

for s in STYLES:
    sid = s["id"]
    fw = s["f"] / 2 if s["mode"] == "faraday" else s["f"]
    lam = wavelength_mm(fw, 0.005)
    ratio = f'{s["ratio"][0]}:{s["ratio"][1]} → {s["f"] * s["ratio"][0] / s["ratio"][1]:.1f} Hz' if s["ratio"] else "single tone"
    b = beat(s["f"], s["ratio"])
    guard = (f'<div class="guard bad"><b>Flicker guard:</b> the two tones differ by {b[1]:.1f} Hz ({"drive" if b[0] == "drive" else "half of the drive difference, the water\'s own beat"}). The new app plays the second tone at 10 % (or moves it); full strength only in Lab mode with a warning.</div>'
             if b else '<div class="guard ok"><b>Flicker guard:</b> no two-tone beat in the 3-60 Hz band. Plays as designed.</div>')
    shows_in = [(x["name"], sum(st["t"] for st in x["steps"][:k])) for x in SHOWS for k, st in enumerate(x["steps"]) if st["style"] == sid]
    gobo_file = next((f for f in s["files"] if f.startswith("gobo_") and f.endswith(".stl")), "")
    grams = VOL.get(gobo_file, {}).get("volume_cm3")
    ins_file = next((f for f in s["files"] if f.startswith("insert_")), "")
    slug = Path(s["folder"]).name
    sig_rows = [("Drive", f'{"Platform (whole dish)" if s["mode"] == "faraday" else "Dipper foot"}, {s["f"]} Hz'), ("2nd tone", ratio),
                ("Water", f"answers at {fw:g} Hz {lbl('est')}"), ("Spacing", f"about {lam:.1f} mm, {112 / lam:.0f} waves across the insert {lbl('est')}")]
    if s["mode"] == "faraday":
        a_, d_ = faraday_threshold(s["f"], 0.005, 3.0)
        sig_rows.append(("Shake", f"onset about {a_ / 9.81:.2f} g / {d_ * 1e6:.0f} µm {lbl('est')}"))
    sig_rows.append(("Motion", (f'pulse {s["pulse"]}/s' if s["pulse"] else "steady") + (f', breathe {s["breathe"]} Hz' if s["breathe"] else "")))
    part_rows = [("Gobo", f'{E(s["gobo"])} ({s["gobo_id"]})' + (f" · about {grams * 1.25:.0f} g at 100 % {lbl('est')}" if grams else "")),
                 ("Insert", f'{E(s["insert"])} ({s["insert_id"]})'), ("Foot", E(s["dipper"] or "none (platform style)")),
                 ("Bambu", f"<code>bambu/styles/{slug}.3mf</code> + <code>{slug}_gobo_2color.3mf</code>"),
                 ("Blender+", f"<code>blender_enhanced/{slug}/</code> (bevelled, ID engraved)"),
                 ("In shows", E(", ".join(f"{n} ({t // 60}:{t % 60:02d})" for n, t in shows_in)) or "-")]
    sw = "".join(f'<i style="background:{c}"></i>' for c in s["pal"])
    side = f'<img class="water" src="{im(sid + "_water.jpg")}"><p class="cap">Water only, no gobo (SIMULATION)</p>'
    if (HI / f"{sid}_chamber.jpg").exists():
        side += f'<img src="{im(sid + "_chamber.jpg")}"><p class="cap">Model A with this style (3D RENDER)</p>'
    page(f'<div class="band micro"><div><h2>The 30 styles · {sid[1:]} of 30</h2></div></div>' +
         f'''<div class="sp-head"><span class="sid">{sid}</span><h3>{E(s["name"])}</h3><span class="mood">{E(s["mood"])}</span><span class="sw">{sw}</span></div>
<div class="sp-grid"><div><img class="wall" src="{im(sid + "_wall.jpg")}"><p class="cap" style="text-align:center;margin-top:3pt">On the wall (SIMULATION)</p></div><div class="sp-side">{side}</div></div>
<p style="font-size:10.4pt;margin:4pt 0">{E(s["how"])} <b>Best for:</b> {E(s["best"])}.</p>{guard}
<div class="two"><table class="kv"><tbody>{"".join(f"<tr><td>{k}</td><td>{v}</td></tr>" for k, v in sig_rows)}</tbody></table>
<table class="kv"><tbody>{"".join(f"<tr><td>{k}</td><td>{v}</td></tr>" for k, v in part_rows)}</tbody></table></div>
<img class="parts-strip" src="{im(sid + "_parts.jpg")}">''', chapter=f"Style {sid}")

# ------------------------------------------------------------------ 10 shows
page(chapter("10", "The 15 light shows", "Ten minutes each. The last minute of every show becomes the next one's opening; each borrows a guest style from the show six places ahead.") +
     svg_chain() + '''<div class="two" style="margin-top:10pt"><div class="brief"><b>Anatomy of a show (600 s):</b> opening 1:00 → five core styles, 1:24 each → guest 1:00 → bridge 1:00. Gold arrows = play order; violet threads = guest borrowings.</div>
<div class="brief"><b>Hardware during a show:</b> drive mode switches automatically with split wiring. Each show keeps one insert. Gobo and foot changes appear as optional cues; leaving one gobo in all show long is fine.</div></div>''', chapter="Shows")
for i, sh in enumerate(SHOWS):
    total = 600
    thumbs = "".join(f'<div style="flex:{x["t"]}"><img src="{im(x["style"] + "_thumb.jpg")}"><span>{x["style"]}</span></div>' for x in sh["steps"])
    rows, t = [], 0
    for x in sh["steps"]:
        st = SB[x["style"]]
        rt = f'{x["ratio"][0]}:{x["ratio"][1]}' if x["ratio"] else "-"
        bb = beat(x["f"], x["ratio"])
        g = f'<span class="lbl est">GUARDED {bb[1]:.0f} Hz</span>' if bb else '<span style="color:#127548">✓</span>'
        cue = f'gobo {st["gobo_id"]}' + (f', foot {E(st["dipper"])}' if x["mode"] == "dipper" and st["dipper"] else "")
        rows.append(f'<tr><td class="t">{t // 60}:{t % 60:02d}</td><td><span class="role {x["role"]}">{x["role"]}</span></td><td><b>{x["style"]} {E(st["name"])}</b></td><td>{x["mode"]}</td><td>{x["f"]} Hz</td><td>{rt}</td><td>{x["pulse"] or "-"}</td><td>{x["breathe"] or "-"}</td><td>{g}</td><td style="font-size:8pt">{cue}</td></tr>')
        t += x["t"]
    nxt = next(x["name"] for x in SHOWS if x["id"] == sh["next"])
    guest = next(x["name"] for x in SHOWS if x["id"] == sh["guest_from"])
    poster = APP / "marketing/videos" / f"{i + 1:02d}_{sh['id']}.jpg"
    page(band("10", f"Show {i + 1} of 15 · {sh['name']}", f"{sh['mood']} · 10:00 · flows into {nxt}") +
         f'''<div class="show-grid"><div><div class="meta"><span class="chip">Insert all show: {E(sh["insert"])}</span><span class="chip">Guest from: {E(guest)}</span><span class="chip">Next: {E(nxt)}</span></div>
<div class="tlimg">{thumbs}</div><div class="tlx"><span>0:00</span><span>2:30</span><span>5:00</span><span>7:30</span><span>10:00</span></div>
<p style="font-size:9.6pt;margin-top:8pt">{E(sh["steps"][0]["text"])}</p>
<p style="font-size:9.6pt">Marketing video: <code>marketing/videos/{i + 1:02d}_{sh["id"]}.mp4</code> (30 s, SIMULATION).</p></div>
<div>{f'<img class="poster" src="{poster.as_uri()}">' if poster.exists() else ""}</div></div>
<table class="steps"><thead><tr><th>time</th><th>role</th><th>style</th><th>mode</th><th>drive</th><th>2nd</th><th>pulse</th><th>breathe</th><th>flicker</th><th>optional cue</th></tr></thead><tbody>{"".join(rows)}</tbody></table>
<p style="font-size:8.6pt;color:#5b5f7a;margin-top:6pt">GUARDED = a two-tone beat in the 3-60 Hz band; the new app limits the second tone there (Lab mode can override with a warning). The v1 console plays these steps as written.</p>''', chapter=f"Show {i + 1}")

# ------------------------------------------------------------------ 11 blender, 12 videos
page(chapter("11", "Blender toolkit", "Enhance any STL and assemble the chamber: tools/blender/cymatic_blender.py (Blender 4.2+ / 5.x).") + f'''
<img src="{im("assembled.jpg")}" class="big-render" style="max-height:4.4in;object-fit:cover">
<div class="two" style="margin-top:10pt"><div><h3 style="margin-top:0">Inside Blender</h3><ol class="steps" style="padding-left:16pt"><li>Edit → Preferences → Add-ons → Install from Disk → <code>cymatic_blender.py</code>.</li><li>3D View → press <b>N</b> → <b>Cymatic</b> tab.</li><li>Set the project folder and a style; press <b>Build chamber</b> or <b>Build exploded view</b>.</li><li>Select a part, set bevel / engrave text / remesh / decimate, press <b>Enhance selected</b>, then <b>Export STL for Bambu Studio</b>.</li></ol></div>
<div><h3 style="margin-top:0">From the command line</h3><p style="font-size:9pt"><code>blender -b -P cymatic_blender.py -- enhance --in insert.stl --out insert_plus.stl --bevel 0.6 --label S05</code></p>
<p style="font-size:9pt"><code>... -- build --root . --style S07 --stage 3 --render step3.png</code> renders one assembly step (that's how the pictures in chapter 6 were made).</p>
<div class="okbox">All 81 enhanced kit and hardware parts were checked watertight after bevelling and engraving.</div></div></div>''', chapter="Blender")
posters = sorted((APP / "marketing/videos").glob("*.jpg"))
page(chapter("12", "Marketing videos", "One 30-second vertical video per show, with a soundtrack built from the show's own tones.") +
     '<div class="posters">' + "".join(f'<img src="{p.as_uri()}">' for p in posters) + "</div>" + '''
<div class="two" style="margin-top:12pt"><div class="card"><h4>Posting rules</h4><ul style="padding-left:16pt;margin:0;font-size:9.6pt"><li>Say <b>simulated preview</b> until you have real footage; every video carries the mark on screen.</li><li>Captions come from <code>marketing/VIDEOS.md</code> and the approved phrase bank; no health claims.</li><li>When the chamber works, film it and swap in real footage.</li></ul></div>
<div class="card dark"><h4>Approved phrases</h4>"See your sound." · "Physics you can watch." · "A calm, beautiful focal point for meditation." · "Explore frequencies in real water." · "An immersive group sound experience."</div></div>''', chapter="Videos")

# ------------------------------------------------------------------ 13 troubleshooting + glossary + files
trouble = [("Pattern lopsided or drifting", "Level the dish; check that all exciters share the same polarity."), ("Nothing appears", "More volume; onset rises with frequency. Try 30-50 Hz first."),
           ("Chaos, droplets, splashing", "Too much drive: back off until the pattern locks."), ("Blurry wall", "Refocus the lens; use a smaller LED die; move the wall farther away."),
           ("Gobo invisible", "Put the gobo closer to the dish; print in white (not clear), use the two-colour version, or film."), ("Dull colours", "Use colour LEDs or gels (light), not dye; add diffraction film."),
           ("Mode doesn't switch in shows", "Console Wiring: Split; platform on LEFT, speaker on RIGHT."), ("No sound from the phone", "Tap Start audio; turn off silent mode; check the Bluetooth pairing."),
           ("Insert floats or lets water pass", "Sand its bottom flat; a few drops of water under it are normal (slots equalise the level)."), ("Platform buzzes", "Lower the volume; check the foot cups sit on the Sorbothane; tighten loose screws."),
           ("Water stains or film", "Distilled water; change it weekly; wipe the dish."), ("Bambu Studio warns about the 3MF", "Answer Yes to 'load geometry only'; then pick printer, filament and process."),
           ("A1 mini: platform too big", "Print the 4-quarter version (a1mini_platform_x2.3mf, twice)."), ("Light flickers", "Stop. Check the LED driver dims at 20 kHz or more; avoid two-tone styles marked GUARDED in public.")]
page(chapter("13", "Troubleshooting", "Most problems are level, volume, focus or wiring.") + '<table><thead><tr><th style="width:32%">Symptom</th><th>Fix</th></tr></thead><tbody>' +
     "".join(f"<tr><td><b>{E(a_)}</b></td><td>{E(b_)}</td></tr>" for a_, b_ in trouble) + "</tbody></table>", chapter="Troubleshooting")
gloss = [("Caustic", "A bright line or web of light made when a curved surface (here, ripples) focuses light."), ("Faraday wave", "A standing wave on a liquid shaken up and down; it answers at half the shaking frequency."),
         ("Dipper", "A printed foot on a small speaker that taps the water and launches rings."), ("Exciter", "A speaker without a cone; it shakes whatever it's glued to."),
         ("Gobo", "A stencil the light passes through, putting a shape into the beam."), ("Boundary insert", "A printed ring with a shaped hole; it sets the shape of the water's 'drum'."),
         ("Dispersion relation", "The physics formula linking a wave's frequency to its spacing on the water."), ("Bessel mode", "A natural vibration pattern of a round dish (rings and petals)."),
         ("Chladni figure", "Nodal-line patterns on a vibrating plate (Chladni, 1787)."), ("Quasipattern", "A pattern with 8-, 10- or 12-fold order that never repeats exactly."),
         ("Subharmonic", "A response at a fraction (here, half) of the driving frequency."), ("Beat", "A slow throb at the difference between two nearby frequencies."),
         ("Flicker guard", "The safety code that stops light from flashing 3-60 times a second."), ("Lithophane", "A thin print that lets more light through where it's thinner."),
         ("3MF", "A 3D-print file format that keeps several parts, names and layout together."), ("AMS", "Bambu Lab's automatic material system for multi-colour prints."),
         ("Split wiring", "Platform on one amp channel, dipper on the other, so software can choose."), ("SIMULATION", "A computer-made picture, never presented as real footage."),
         ("Estimated", "A calculated number with stated assumptions."), ("Measured", "A number from a sensor or camera on your own chamber.")]
page(band("13", "Glossary", "The words used in this manual.") + '<dl class="gl">' + "".join(f"<div><dt>{E(t)}</dt><dd>{E(d)}</dd></div>" for t, d in gloss) + "</dl>", chapter="Glossary")
files = [("docs/CYMATIC_ODYSSEY_Manual.pdf", "this manual"), ("docs/CYMATIC_ODYSSEY_Sourcing_Guide.pdf", "glass, makers and filament"), ("docs/SHOPPING_LIST.md", "parts with links"),
         ("downloads/CYMATIC_ODYSSEY_30_style_kits.zip", "30 style kits (STL + SVG + previews) + hardware"), ("downloads/CYMATIC_ODYSSEY_Bambu_Studio.zip", "65 verified 3MF plates"),
         ("downloads/CYMATIC_ODYSSEY_Blender_enhanced.zip", "bevelled + engraved parts and the Blender add-on"), ("downloads/gobos_*.zip", "the full library: 306 gobos in 26 families"),
         ("console/index.html", "the Voyage console (also online)"), ("marketing/videos/", "15 show videos + posters"), ("docs/SHOWS.md, docs/VOYAGES.md, docs/THEMES.md", "shows, voyages, 40 holiday themes"),
         ("docs/BUILD_SPECS.md, docs/SAFETY.md", "specs and safety in full"), ("docs/TRANSPARENCY.md", "labels, evidence grades, data, AI, sources"), ("tools/", "the generator and every tool that made these files")]
page(band("13", "Where everything is", REPO) + '<table><tbody>' + "".join(f"<tr><td><code>{E(f)}</code></td><td>{E(d)}</td></tr>" for f, d in files) + "</tbody></table>" +
     f'<div class="callout-box card dark" style="margin-top:14pt"><h4>On your phone</h4>Console: <a href="{CONSOLE_URL}">{CONSOLE_URL}</a></div>', chapter="Files")
page(f'''<div class="art"><img src="{im("S10_wall.jpg")}"><img src="{im("S05_wall.jpg")}"><img src="{im("S03_wall.jpg")}"></div>
<h2>Build the chamber. Light the wall.</h2><p>Console: {CONSOLE_URL}</p><p>{E(REPO)}</p>
<p style="margin-top:20pt;font-size:8.5pt;color:#8a8eb0">Wall images are SIMULATIONS; numbers marked ESTIMATED are calculated starting points. Art and relaxation experience, not a medical device.</p>''', "back", foot=False)

# ------------------------------------------------------------------ contents (filled now that page numbers are known)
toc_html = band("", "Contents", "Chapters and the page each starts on.") + '<div class="toc2">' + "".join(
    f'<p><b>{E(n)}</b><span>{E(t)}</span><span class="dots"></span><span class="pg">{p}</span></p>' for n, t, p in TOC) + "</div>" + \
    f'<div class="brief" style="margin-top:14pt"><b>In this edition:</b> one page per style with high-resolution pictures, seven illustrated assembly steps rendered from the real STL files, an annotated console guide, Bambu Studio and A1-mini printing, the flicker-guard status of every style and show step, a glossary and a file index.</div>'
PAGES[TOC_SLOT] = f'<section class="page">{toc_html}<div class="foot"><span>CYMATIC ODYSSEY · Complete Manual · v2</span><span>Contents</span><span class="pn">{TOC_SLOT + 1}</span></div></section>'

HTML = f'<!DOCTYPE html><html><head><meta charset="utf-8"><title>CYMATIC ODYSSEY Manual v2</title><style>{CSS}</style></head><body>{"".join(PAGES)}</body></html>'
out_html = HERE / "manual.html"
out_html.write_text(HTML)
out_pdf = APP / "docs/CYMATIC_ODYSSEY_Manual.pdf"
js = f"""const {{ chromium }} = require('playwright');
(async () => {{ const b = await chromium.launch(); const p = await b.newPage();
  await p.goto({json.dumps(out_html.as_uri())}, {{waitUntil: 'load', timeout: 120000}});
  await p.pdf({{ path: {json.dumps(str(out_pdf))}, format: 'Letter', printBackground: true, preferCSSPageSize: true }});
  await b.close(); }})();"""
subprocess.run(["node", "-e", js], check=True)
print("pages", len(PAGES), "->", out_pdf, out_pdf.stat().st_size // 1024, "KB")
