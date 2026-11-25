#!/usr/bin/env python3
"""Builds docs/CYMATIC_ODYSSEY_Manual.pdf - the complete illustrated manual (HTML + CSS -> Chromium)."""
import html, json, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
sys.path.insert(0, str(APP / "tools"))
from physics_tables import wavelength_mm  # noqa: E402

E = html.escape
IMG = HERE / "img"
STYLES = json.loads((APP / "catalog/styles.json").read_text())
CONTENT = json.loads((APP / "catalog/content.json").read_text())
SHOWS = CONTENT["shows"]
SB = {s["id"]: s for s in STYLES}
CONSOLE_URL = "https://claude.ai/artifact/STJTYLCynV5XHA1uNHifMX"
REPO = "https://github.com/namastegeitz/eddie-g/tree/claude/peaceful-babbage-k8oen2/apps/cymatic-odyssey"


def im(name):
    return (IMG / name).as_uri()


def a(t, u):
    return f'<a href="{E(u)}">{E(t)}</a>'


page_no = [0]


def page(body, cls="", foot=True):
    page_no[0] += 1
    f = f'<div class="foot"><span>CYMATIC ODYSSEY · Manual</span><span>{page_no[0]}</span></div>' if foot else ""
    return f'<section class="page {cls}">{body}{f}</section>'


def band(n, title, sub, img=None):
    pic = f'<img src="{im(img)}">' if img else ""
    return f'<div class="band">{pic}<div><div class="n">{n}</div><h2>{E(title)}</h2><p>{E(sub)}</p></div></div>'


# ------------------------------------------------------------------ diagrams (inline SVG)
def svg_system():
    return """<svg viewBox="0 0 640 330" class="diagram">
<defs><linearGradient id="beam" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ffe9b0" stop-opacity=".9"/><stop offset="1" stop-color="#ffe9b0" stop-opacity=".25"/></linearGradient>
<marker id="ar" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#7fd4ff"/></marker></defs>
<rect x="40" y="20" width="300" height="290" rx="14" fill="#0d1020" stroke="#3a4170" stroke-width="2"/>
<text x="52" y="42" fill="#9aa3c7" font-size="12">sealed acrylic chamber (24 V only)</text>
<polygon points="182,270 198,270 250,178 130,178" fill="url(#beam)"/>
<polygon points="130,178 250,178 214,96 166,96" fill="#ffe9b0" opacity=".35"/>
<circle cx="190" cy="276" r="9" fill="#fff6d6"/><rect x="170" y="284" width="40" height="12" fill="#556"/>
<text x="218" y="282" fill="#ffe9b0" font-size="12">1. point LED</text>
<rect x="125" y="196" width="130" height="6" fill="#ffd27a" opacity=".9"/><text x="262" y="203" fill="#ffd27a" font-size="12">2. gobo (stencil)</text>
<rect x="110" y="170" width="160" height="16" rx="3" fill="none" stroke="#bfe9ff" stroke-width="2"/>
<path d="M114,176 q10,-6 20,0 t20,0 t20,0 t20,0 t20,0 t20,0 t20,0 t20,0" stroke="#7fd4ff" stroke-width="2" fill="none"/>
<text x="276" y="176" fill="#7fd4ff" font-size="12">3. water + insert</text>
<rect x="100" y="188" width="180" height="8" fill="#2a2f45"/><rect x="104" y="196" width="14" height="14" fill="#ff9f43"/><rect x="262" y="196" width="14" height="14" fill="#ff9f43"/>
<text x="52" y="230" fill="#ff9f43" font-size="12">4. exciters shake</text>
<path d="M300,120 l-30,0 l0,40" stroke="#ffb347" stroke-width="3" fill="none"/><rect x="292" y="104" width="26" height="22" rx="4" fill="#ffb347"/><text x="270" y="98" fill="#ffb347" font-size="11">or dipper taps</text>
<ellipse cx="190" cy="92" rx="52" ry="7" fill="#9fdcff" opacity=".8"/><text x="250" y="88" fill="#9fdcff" font-size="12">5. lens</text>
<line x1="150" y1="58" x2="230" y2="38" stroke="#e8ebff" stroke-width="5"/><text x="236" y="40" fill="#e8ebff" font-size="12">6. mirror</text>
<polygon points="168,84 212,84 205,50 175,56" fill="#ffe9b0" opacity=".35"/>
<polygon points="200,46 560,10 560,150 205,52" fill="#ffe9b0" opacity=".18"/>
<rect x="560" y="10" width="18" height="300" fill="#1d2138"/><text x="586" y="160" fill="#e8ebff" font-size="13" transform="rotate(90 586 160)">7. wall</text>
<g transform="translate(470 220)"><rect width="120" height="64" rx="8" fill="#16305a"/><text x="10" y="22" fill="#fff" font-size="12">phone / laptop</text><text x="10" y="42" fill="#7fd4ff" font-size="11">Voyage console</text><text x="10" y="58" fill="#9aa3c7" font-size="10">Bluetooth to amp</text></g>
<path d="M470,250 C420,250 360,240 300,212" stroke="#7fd4ff" stroke-width="2" fill="none" marker-end="url(#ar)" stroke-dasharray="5 4"/>
</svg>"""


def svg_model(kind):
    base = '<svg viewBox="0 0 300 190" class="mini-diagram"><rect width="300" height="190" fill="#0b0d1f" rx="10"/>'
    beam = 'fill="#ffe9b0" opacity=".28"'
    if kind == "A":
        s = f'''<rect x="20" y="20" width="150" height="155" rx="8" fill="none" stroke="#3a4170" stroke-width="2"/>
<polygon points="88,160 102,160 130,100 60,100" {beam}/><circle cx="95" cy="163" r="6" fill="#fff6d6"/>
<rect x="55" y="94" width="80" height="8" rx="2" fill="#7fd4ff"/><rect x="50" y="102" width="90" height="5" fill="#ff9f43"/>
<ellipse cx="95" cy="62" rx="30" ry="4" fill="#9fdcff"/><polygon points="70,100 120,100 112,62 78,62" {beam}/>
<line x1="72" y1="42" x2="118" y2="28" stroke="#e8ebff" stroke-width="4"/><polygon points="112,30 280,8 280,80 115,38" {beam}/>
<rect x="280" y="8" width="10" height="170" fill="#1d2138"/>'''
    elif kind == "B":
        s = f'''<rect x="30" y="120" width="150" height="50" rx="6" fill="#2a2f45"/><text x="40" y="160" fill="#9aa3c7" font-size="10">overhead projector</text>
<rect x="60" y="110" width="90" height="10" rx="2" fill="#7fd4ff"/><rect x="100" y="40" width="8" height="70" fill="#556"/>
<rect x="88" y="28" width="34" height="18" rx="3" fill="#556"/><polygon points="120,34 280,10 280,90 122,42" {beam}/>
<polygon points="70,118 140,118 112,46 96,46" {beam}/><rect x="280" y="8" width="10" height="170" fill="#1d2138"/>'''
    elif kind == "C":
        s = f'''<rect x="20" y="95" width="40" height="22" rx="4" fill="#556"/><circle cx="62" cy="106" r="5" fill="#fff6d6"/>
<polygon points="66,104 140,70 140,140 66,108" {beam}/><rect x="140" y="64" width="60" height="84" rx="10" fill="none" stroke="#bfe9ff" stroke-width="2"/>
<path d="M144,96 q8,-5 16,0 t16,0 t16,0" stroke="#7fd4ff" stroke-width="2" fill="none"/><polygon points="200,70 280,20 280,170 200,140" {beam}/>
<rect x="280" y="8" width="10" height="170" fill="#1d2138"/><text x="24" y="135" fill="#9aa3c7" font-size="10">flashlight</text><text x="146" y="164" fill="#9aa3c7" font-size="10">jar of water</text>'''
    elif kind == "D":
        s = f'''<rect x="40" y="60" width="200" height="115" rx="8" fill="none" stroke="#3a4170" stroke-width="2"/>
<rect x="8" y="2" width="284" height="10" fill="#1d2138"/><text x="100" y="26" fill="#9aa3c7" font-size="10">ceiling / dome</text>
{''.join(f'<circle cx="{x}" cy="165" r="5" fill="#fff6d6"/>' for x in (110, 140, 170))}
<polygon points="105,165 175,165 230,12 50,12" {beam}/><rect x="70" y="104" width="140" height="10" rx="2" fill="#7fd4ff"/>
<rect x="60" y="114" width="160" height="6" fill="#ff9f43"/><ellipse cx="140" cy="76" rx="60" ry="6" fill="#9fdcff"/>'''
    else:
        s = f'''<rect x="70" y="110" width="110" height="10" rx="2" fill="#7fd4ff"/><path d="M74,113 q8,-4 16,0 t16,0 t16,0 t16,0 t16,0 t16,0" stroke="#bfe9ff" stroke-width="1.5" fill="none"/>
<rect x="200" y="96" width="40" height="30" rx="4" fill="#ffb347"/><path d="M200,106 l-60,0 l0,4" stroke="#ffb347" stroke-width="3" fill="none"/>
<rect x="100" y="150" width="50" height="22" rx="4" fill="#556"/><circle cx="125" cy="148" r="4" fill="#fff6d6"/><polygon points="121,146 129,146 175,8 75,8" {beam}/>
<text x="92" y="186" fill="#9aa3c7" font-size="10">phone torch below</text><text x="196" y="90" fill="#ffb347" font-size="10">3" speaker</text>'''
    return base + s + "</svg>"


def svg_wiring():
    return """<svg viewBox="0 0 640 250" class="diagram">
<rect x="250" y="80" width="140" height="90" rx="10" fill="#16305a"/><text x="268" y="105" fill="#fff" font-size="14">amplifier</text><text x="268" y="124" fill="#9aa3c7" font-size="11">TPA3116D2, 24 V</text>
<text x="268" y="150" fill="#7fd4ff" font-size="12">L</text><text x="368" y="150" fill="#ffb347" font-size="12">R</text>
<rect x="20" y="20" width="170" height="100" rx="10" fill="#0d1020" stroke="#7fd4ff"/><text x="34" y="44" fill="#7fd4ff" font-size="13">platform (Faraday)</text>
<g fill="#ff9f43">""" + "".join(f'<rect x="{34 + i * 38}" y="60" width="28" height="28" rx="14"/>' for i in range(4)) + """</g>
<text x="34" y="108" fill="#9aa3c7" font-size="10">(1+2 series) || (3+4 series) = 4 ohm</text>
<path d="M190,70 C230,70 240,145 262,145" stroke="#7fd4ff" stroke-width="3" fill="none"/>
<rect x="450" y="20" width="170" height="100" rx="10" fill="#0d1020" stroke="#ffb347"/><text x="464" y="44" fill="#ffb347" font-size="13">dipper speaker</text><circle cx="535" cy="80" r="22" fill="#2a2f45" stroke="#ffb347"/><text x="464" y="108" fill="#9aa3c7" font-size="10">3-3.5", 8 ohm, right channel</text>
<path d="M450,70 C410,70 400,145 378,145" stroke="#ffb347" stroke-width="3" fill="none"/>
<rect x="20" y="170" width="170" height="60" rx="10" fill="#2a2f45"/><text x="34" y="196" fill="#fff" font-size="13">24 V 5 A brick</text><text x="34" y="214" fill="#9aa3c7" font-size="10">GFCI outlet, 5 A fuse</text>
<path d="M190,200 C220,200 230,170 250,165" stroke="#e8ebff" stroke-width="2" fill="none"/>
<rect x="450" y="170" width="170" height="60" rx="10" fill="#2a2f45"/><text x="464" y="196" fill="#fff" font-size="13">phone (console)</text><text x="464" y="214" fill="#9aa3c7" font-size="10">Bluetooth or AUX</text>
<path d="M450,200 C420,200 410,175 390,165" stroke="#e8ebff" stroke-width="2" fill="none" stroke-dasharray="5 4"/>
<rect x="250" y="190" width="140" height="44" rx="10" fill="#2a2f45"/><text x="262" y="212" fill="#fff" font-size="12">LED driver + LED</text><text x="262" y="227" fill="#9aa3c7" font-size="10">PWM 20 kHz+</text>
<path d="M190,215 L250,212" stroke="#e8ebff" stroke-width="2"/>
</svg>"""


def svg_chain():
    import math
    n = len(SHOWS)
    cx, cy, R = 320, 230, 175
    parts = ['<svg viewBox="-70 0 780 470" class="diagram"><defs><marker id="ar2" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#ffd27a"/></marker></defs>']
    pts = []
    for i, sh in enumerate(SHOWS):
        ang = -math.pi / 2 + 2 * math.pi * i / n
        pts.append((cx + R * math.cos(ang), cy + R * math.sin(ang), ang))
    for i, sh in enumerate(SHOWS):
        g = next(k for k, x in enumerate(SHOWS) if x["id"] == sh["guest_from"])
        x1, y1, _ = pts[i]; x2, y2, _ = pts[g]
        parts.append(f'<line x1="{x1:.0f}" y1="{y1:.0f}" x2="{x2:.0f}" y2="{y2:.0f}" stroke="#7a5cff" stroke-opacity=".35" stroke-width="1.2"/>')
    for i in range(n):
        x1, y1, a1 = pts[i]; x2, y2, a2 = pts[(i + 1) % n]
        parts.append(f'<path d="M{x1:.0f},{y1:.0f} A{R},{R} 0 0 1 {x2:.0f},{y2:.0f}" stroke="#ffd27a" stroke-width="2.5" fill="none" marker-end="url(#ar2)" stroke-dasharray="0 22 200"/>')
    for i, sh in enumerate(SHOWS):
        x, y, ang = pts[i]
        col = SB[sh["steps"][0]["style"]]["pal"][0]
        parts.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="20" fill="{col}" stroke="#07081a" stroke-width="3"/><text x="{x:.0f}" y="{y + 5:.0f}" text-anchor="middle" font-size="13" font-weight="800" fill="#07081a">{i + 1}</text>')
        lx = cx + (R + 46) * math.cos(ang); ly = cy + (R + 40) * math.sin(ang)
        anchor = "middle" if abs(math.cos(ang)) < 0.08 else ("start" if math.cos(ang) > 0 else "end")
        parts.append(f'<text x="{lx:.0f}" y="{ly + 4:.0f}" text-anchor="{anchor}" font-size="12" fill="#e8ebff">{E(sh["name"])}</text>')
    parts.append(f'<text x="{cx}" y="{cy - 8}" text-anchor="middle" font-size="22" font-weight="800" fill="#ffd27a">150 min</text><text x="{cx}" y="{cy + 16}" text-anchor="middle" font-size="12" fill="#b9bdd8">15 shows x 10 min, one loop</text>')
    parts.append('</svg>')
    return "".join(parts)


def timeline(sh):
    segs = []
    for x in sh["steps"]:
        p = SB[x["style"]]["pal"]
        segs.append(f'<div class="seg" style="flex:{x["t"]};background:linear-gradient(90deg,{p[0]},{p[1]})"><span>{x["style"]}</span></div>')
    return f'<div class="tl">{"".join(segs)}</div><div class="tlx"><span>0:00</span><span>2:30</span><span>5:00</span><span>7:30</span><span>10:00</span></div>'


def style_card(s):
    fw = s["f"] / 2 if s["mode"] == "faraday" else s["f"]
    lam = wavelength_mm(fw, 0.005)
    ratio = f'{s["ratio"][0]}:{s["ratio"][1]}' if s["ratio"] else "single tone"
    sw = "".join(f'<i style="background:{c}"></i>' for c in s["pal"])
    shows = [x["name"] for x in SHOWS if any(st["style"] == s["id"] for st in x["steps"])]
    files = " · ".join(E(f.split("_", 1)[0] + ": " + f.split("_", 2)[1]) + (" + svg" if f.startswith("gobo") else "") for f in s["files"] if f.endswith(".stl"))
    return f'''<div class="style">
  <div class="shead"><span class="sid">{s["id"]}</span><h3>{E(s["name"])}</h3><span class="mood">{E(s["mood"])}</span><span class="sw">{sw}</span></div>
  <div class="sgrid">
    <figure class="wall"><img src="{im(s["id"] + "_wall_preview.jpg")}"><figcaption>On the wall (simulated)</figcaption></figure>
    <div class="sright">
      <figure class="water"><img src="{im(s["id"] + "_water_preview.jpg")}"><figcaption>Water only, no gobo</figcaption></figure>
      <table class="kv">
        <tr><td>Drive</td><td>{"Platform (whole dish)" if s["mode"] == "faraday" else "Dipper foot"}, {s["f"]} Hz, {ratio}</td></tr>
        <tr><td>Water</td><td>waves at {fw:g} Hz, about {lam:.1f} mm apart</td></tr>
        <tr><td>Motion</td><td>{("pulse " + str(s["pulse"]) + "/s") if s["pulse"] else "steady"}{(", breathe " + str(s["breathe"]) + " Hz") if s["breathe"] else ""}</td></tr>
        <tr><td>Gobo</td><td>{E(s["gobo"])} ({s["gobo_id"]})</td></tr>
        <tr><td>Insert</td><td>{E(s["insert"])} ({s["insert_id"]})</td></tr>
        <tr><td>Foot</td><td>{E(s["dipper"] or "none (platform)")}</td></tr>
        <tr><td>In shows</td><td>{E(", ".join(shows) or "-")}</td></tr>
      </table>
    </div>
  </div>
  <img class="parts" src="{im(s["id"] + "_parts_preview.jpg")}">
  <p class="how">{E(s["how"])} <b>Best for:</b> {E(s["best"])}.</p>
  <p class="files"><b>STL kit</b> <code>{E(s["folder"])}/</code> · {files}</p>
</div>'''


def show_block(i, sh):
    rows, t = [], 0
    for x in sh["steps"]:
        s = SB[x["style"]]
        rt = f'{x["ratio"][0]}:{x["ratio"][1]}' if x["ratio"] else "-"
        rows.append(f'<tr><td class="t">{t // 60}:{t % 60:02d}</td><td><span class="role {x["role"]}">{x["role"]}</span></td><td><b>{x["style"]} {E(s["name"])}</b></td><td>{x["mode"]}</td><td>{x["f"]} Hz</td><td>{rt}</td><td>{x["pulse"] or "-"}</td><td>{x["breathe"] or "-"}</td></tr>')
        t += x["t"]
    nxt = next(x["name"] for x in SHOWS if x["id"] == sh["next"])
    guest = next(x["name"] for x in SHOWS if x["id"] == sh["guest_from"])
    return f'''<div class="show"><div class="showhead"><span class="snum">{i + 1}</span><div><h3>{E(sh["name"])}</h3><p>{E(sh["mood"])} · 10:00 · insert: {E(sh["insert"])} · guest from {E(guest)} · flows into <b>{E(nxt)}</b></p></div></div>
{timeline(sh)}
<table class="steps"><thead><tr><th>time</th><th>role</th><th>style</th><th>mode</th><th>drive</th><th>2nd</th><th>pulse</th><th>breathe</th></tr></thead><tbody>{"".join(rows)}</tbody></table></div>'''


CSS = (HERE.parent / "sourcing/build_pdf.py").read_text().split('CSS = r"""')[1].split('"""')[0] + r"""
.diagram { width: 100%; height: auto; background: #07081a; border-radius: 12pt; }
.mini-diagram { width: 100%; height: 1.25in; border-radius: 8pt; background:#0b0d1f; }
.twocol { display: grid; grid-template-columns: 1fr 1fr; gap: 12pt; }
.threecol { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8pt; }
.threecol figure { margin: 0; text-align: center; font-size: 8.5pt; color: #3b3e58; }
.threecol img { width: 100%; border-radius: 50%; display: block; margin-bottom: 4pt; }
.equation { display: grid; grid-template-columns: 1fr 14pt 1fr 14pt 1fr; align-items: center; gap: 6pt; }
.equation img { width: 100%; border-radius: 8pt; } .equation .op { font-size: 22pt; font-weight: 800; color: #ffd27a; text-align: center; }
.models { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 9pt; }
.model { border: 1pt solid #e4e5ef; border-radius: 10pt; padding: 8pt 10pt; break-inside: avoid; }
.model h3 { margin: 5pt 0 2pt; font-size: 12pt; } .model p { margin: 2pt 0; font-size: 8.8pt; } .model .tag { font-size: 8pt; color: #8a6d1f; font-weight: 600; }
ol.steps { padding-left: 16pt; margin: 4pt 0; } ol.steps li { margin-bottom: 5pt; font-size: 9.6pt; }
.style { break-inside: avoid; border-bottom: 1pt solid #e4e5ef; padding-bottom: 6pt; margin-bottom: 6pt; height: 4.3in; overflow: hidden; }
.style:last-child { border-bottom: 0; }
.shead { display: flex; align-items: baseline; gap: 8pt; }
.shead h3 { margin: 0; font-size: 15pt; } .sid { background: #07081a; color: #ffd27a; font-weight: 800; padding: 2pt 7pt; border-radius: 6pt; font-size: 10pt; }
.mood { color: #6b6f8c; font-size: 9pt; } .sw { margin-left: auto; } .sw i { display: inline-block; width: 12pt; height: 12pt; border-radius: 3pt; margin-left: 3pt; }
.sgrid { display: grid; grid-template-columns: 2.1in 1fr; gap: 10pt; margin-top: 6pt; }
.sgrid figure { margin: 0; } .sgrid figcaption { font-size: 7.5pt; color: #6b6f8c; text-align: center; }
.wall img { width: 2.1in; height: 2.1in; border-radius: 50%; display: block; }
.sright { display: grid; grid-template-columns: 1.05in 1fr; gap: 8pt; align-items: start; }
.water img { width: 1.05in; height: 1.05in; border-radius: 50%; }
table.kv td { padding: 2.4pt 4pt; font-size: 8.4pt; border-bottom: 0.5pt solid #eef; } table.kv td:first-child { color: #6b6f8c; width: 0.6in; }
img.parts { width: 100%; height: 0.8in; object-fit: contain; background: #05060d; border-radius: 8pt; margin-top: 6pt; }
.how { font-size: 9pt; margin: 5pt 0 2pt; }
.files { font-size: 7.6pt; color: #3b3e58; margin: 0; } .files ul { display: inline; padding: 0; margin: 0; } .files li { display: inline; margin-right: 8pt; list-style: none; } .files code { font-size: 7.6pt; }
.gallery { display: grid; grid-template-columns: repeat(6, 1fr); gap: 7pt; }
.gallery figure { margin: 0; text-align: center; font-size: 7.6pt; color: #3b3e58; } .gallery img { width: 100%; border-radius: 50%; display: block; margin-bottom: 2pt; }
.show { break-inside: avoid; margin-bottom: 14pt; }
.showhead { display: flex; gap: 10pt; align-items: center; } .showhead h3 { margin: 0; font-size: 15pt; } .showhead p { margin: 1pt 0 0; font-size: 8.6pt; color: #5b5f7a; }
.snum { width: 30pt; height: 30pt; border-radius: 50%; background: #07081a; color: #ffd27a; font-weight: 800; display: flex; align-items: center; justify-content: center; font-size: 13pt; flex: none; }
.tl { display: flex; height: 22pt; border-radius: 6pt; overflow: hidden; margin: 8pt 0 2pt; } .seg { display: flex; align-items: center; justify-content: center; border-right: 1.5pt solid #fff; }
.seg span { font-size: 7.5pt; font-weight: 800; color: #07081a; background: rgba(255,255,255,.65); padding: 0 3pt; border-radius: 3pt; }
.tlx { display: flex; justify-content: space-between; font-size: 7pt; color: #9a9db6; }
table.steps { font-size: 8.4pt; margin-top: 4pt; } table.steps td { padding: 2.6pt 5pt; } td.t { font-variant-numeric: tabular-nums; color: #6b6f8c; }
.role { font-size: 7pt; font-weight: 700; padding: 1pt 5pt; border-radius: 8pt; background: #eef; } .role.opening { background: #e8f4ff; color: #1d5fa8; } .role.guest { background: #f1e8ff; color: #6b3fd0; } .role.bridge { background: #fff3d6; color: #8a6d1f; }
.shots { display: grid; grid-template-columns: 2.1fr 1fr 1fr; gap: 10pt; align-items: start; } .shots img { width: 100%; border-radius: 10pt; border: 1pt solid #e4e5ef; }
.toc { columns: 2; font-size: 10.5pt; } .toc p { margin: 0 0 6pt; break-inside: avoid; } .toc b { color: #ffd27a; background: #07081a; padding: 0 5pt; border-radius: 4pt; margin-right: 6pt; }
.callout { background: #07081a; color: #e8e9f5; border-radius: 12pt; padding: 12pt 14pt; } .callout a { color: #7fd4ff; border-color: #335; } .callout h4 { margin: 0 0 4pt; color: #ffd27a; }
"""

# ------------------------------------------------------------------ pages
P = []
cover_ids = ["S03", "S05", "S09", "S02", "S11", "S08", "S13", "S19", "S06", "S10", "S26", "S04", "S12", "S21", "S29", "S01"]
P.append(page(f'''<div class="mosaic">{"".join(f'<img src="{im(i + "_wall_preview.jpg")}">' for i in cover_ids)}</div><div class="shade"></div>
<div class="text"><div class="kicker">CYMATIC ODYSSEY · THE COMPLETE MANUAL</div><h1>Sound becomes<br><span>geometry of light</span></h1>
<div class="sub">How it works, five ways to build it, step-by-step instructions, 30 styles with previews and STL kits, and 15 ten-minute light shows that flow into one another.</div>
<div class="meta"><div><b>30</b>styles</div><div><b>15</b>shows, 150 min</div><div><b>5</b>build models</div><div><b>355</b>printable looks</div></div></div>''', "cover", foot=False))

toc = [("01", "How it works"), ("02", "How a style is built"), ("03", "Safety first"), ("04", "Five models to build"),
       ("05", "Parts list"), ("06", "Printing the parts"), ("07", "Assembly and wiring"), ("08", "First light, calibration and your phone"),
       ("09", "The 30 styles: gallery"), ("10", "The 30 styles: one by one"), ("11", "The 15 light shows"), ("12", "STL index and troubleshooting")]
P.append(page(band("", "Contents", "Everything you need, from the first print to a 150-minute show.") +
              '<div class="toc">' + "".join(f"<p><b>{n}</b>{E(t)}</p>" for n, t in toc) + "</div>" +
              f'''<div class="callout" style="margin-top:18pt"><h4>On your phone</h4>The Voyage console runs in your phone's browser: open <a href="{CONSOLE_URL}">{CONSOLE_URL}</a>.
It plays every style and show, and switches between the platform and the dipper by itself when wired as in section 07.
All files (this PDF, STL kits, docs) are in the project folder: <a href="{REPO}">GitHub: apps/cymatic-odyssey</a>.</div>
<div class="brief" style="margin-top:12pt"><b>A note on the pictures.</b> The wall images in this manual are computer simulations from the same physics model as the console (real water wave lengths, ray-traced caustics, the gobo refracted by the water). They show the character of each look. Your real wall will be sharper or softer depending on your LED, lens and room. The chamber hasn't been built and measured yet, so treat every frequency as a starting point and tune by eye.</div>'''))

P.append(page(band("01", "How it works", "Seven parts, one idea: sound shapes water, water shapes light.") + svg_system() +
              '''<div class="twocol" style="margin-top:10pt"><div><h3>The idea in three lines</h3><ol class="steps">
<li><b>Sound shakes a thin layer of water</b> (3-6 mm in a glass dish). Either the whole dish shakes (Faraday waves, at half the drive frequency), or a small foot taps the surface (rings, at the drive frequency).</li>
<li><b>The rippled surface acts like thousands of tiny lenses.</b> Light from a single small LED is focused into bright lines called caustics, the same thing you see on a pool floor.</li>
<li><b>Geometry is added three ways:</b> the <i>gobo</i> (a printed stencil the light passes through), the <i>insert</i> (it sets the shape of the water's "drum"), and the <i>signal</i> (one or two tones choose squares, hexagons or 12-fold quasicrystals).</li></ol></div>
<div><h3>What the water does by itself</h3><div class="threecol" style="grid-template-columns:1fr 1fr"><figure><img src="''' + im("S18_water_preview.jpg") + '''">one tone: squares</figure><figure><img src="''' + im("S02_water_preview.jpg") + '''">2:3 tones: hexagons</figure><figure><img src="''' + im("S03_water_preview.jpg") + '''">4:5 tones: 12-fold</figure><figure><img src="''' + im("S01_water_preview.jpg") + '''">dipper: rings</figure></div></div></div>'''))

s5 = SB["S05"]
P.append(page(band("02", "How a style is built", "Gobo + insert + signal = the look on the wall. Example: S05 Metatron.") +
              f'''<img src="{im("S05_parts_preview.jpg")}" style="width:100%;border-radius:10pt;background:#05060d">
<div class="equation" style="margin-top:12pt"><div><img src="{im("S05_water_preview.jpg")}" style="border-radius:50%"><p style="text-align:center;font-size:9pt">the water: 36 Hz + 54 Hz (2:3) in a hexagon insert</p></div><div class="op">+</div>
<div><img src="{(APP / "previews/items" / "G102_metatron_s_cube.png").as_uri()}" style="border-radius:50%"><p style="text-align:center;font-size:9pt">the gobo: Metatron's Cube</p></div><div class="op">=</div>
<div><img src="{im("S05_wall_preview.jpg")}" style="border-radius:50%"><p style="text-align:center;font-size:9pt">the wall: lines bend and breathe with the water</p></div></div>
<div class="twocol" style="margin-top:12pt"><div class="brief"><b>Change one thing, get a new look.</b> The same gobo over a different signal (5:4 instead of 2:3) turns hexagons into a 12-fold quasipattern. The same signal in a pentagon insert bends the pattern into five-fold arcs. That's why 30 styles come from a handful of parts.</div>
<div class="brief"><b>Colour comes from light, not dye.</b> Each style lists three light colours. Three LEDs slightly apart each cast their own copy of the pattern, so where the copies separate you get coloured fringes ("spectrum split" in the console).</div></div>'''))

P.append(page(band("03", "Safety first", "Read before building. Full version: docs/SAFETY.md.") + '''
<div class="twocol"><div class="tip"><h4>The EZ-100 Tesla coil</h4><ul><li>It can't shake water: it's a plasma-arc speaker.</li><li><b>Never</b> in, on or near the water chamber. Keep it 50 cm away in its own dry, ventilated bay.</li><li>Arcs cause RF burns, ozone and fire; keep implants away.</li><li>Leave it out of any business install.</li></ul></div>
<div class="tip"><h4>Water and power</h4><ul><li>24 V DC only inside the chamber; a UL/ETL brick on a GFCI outlet.</li><li>Electronics beside or above the water, never under it; drip tray under the dish.</li><li>5 A fuse; unplug before filling or cleaning.</li></ul></div>
<div class="tip"><h4>Light and flicker</h4><ul><li>Flashing between 3 and 60 per second can trigger seizures.</li><li>The system uses steady light; the console keeps motion slow.</li><li>No strobe effects in public; LED dimming at 20 kHz+.</li></ul></div>
<div class="tip"><h4>Sound, water and health claims</h4><ul><li>Start at low volume; the limiter is a backstop only.</li><li>Distilled water + one drop of soap; borosilicate glass only.</li><li>Sell it as ambience and relaxation, never as treatment.</li></ul></div></div>'''))

models = [("A", "Compact Chamber (flagship)", "LED below, lens and 45-degree mirror above; platform + dipper; 300 x 300 x 420 mm.", "Sharp 1-3 m pictures in a dim room. Everything in this manual.", "about $300-450"),
          ("B", "Overhead Projector", "Platform and dish on a used overhead projector's glass; its head projects the caustics.", "Brightest and simplest optics; the classic 1960s light-show tool. Halogen stages warm the water: short sessions or an LED projector.", "about $150 + projector"),
          ("C", "Shadow Caster (starter)", "Flashlight through a jar or dish of water onto a wall 0.5-1.5 m away; no lens. (Your first test.)", "Free, instant, soft and large. Good for trying gobos and inserts.", "about $0-30"),
          ("D", "Venue Pro", "3 x high-power LEDs, 300 mm dish, ceiling or dome projection, sealed IP-rated electronics, DMX input.", "Lobbies, planetariums, events; projects up instead of onto a wall.", "about $500-800 to build"),
          ("E", "Desk Dipper (mini)", "Small dish, 3-inch speaker + dipper arm, phone torch underneath, ceiling projection.", "Weekend build; rings, interference and pulse styles only (no platform).", "about $40-60")]
P.append(page(band("04", "Five models to build", "Same physics, different sizes and budgets. Pick one to start; the styles work on all of them.") +
              '<div class="models">' + "".join(f'<div class="model">{svg_model(k)}<span class="tag">MODEL {k} · {E(c)}</span><h3>{E(n)}</h3><p>{E(d)}</p><p style="color:#5b5f7a">{E(w)}</p></div>' for k, n, d, w, c in models) +
              '<div class="model" style="background:#07081a;color:#e8e9f5"><h3 style="color:#ffd27a">Which one?</h3><p>Start with <b>C</b> tonight (it costs nothing), build <b>E</b> next to learn the dipper styles, then <b>A</b> for the full show. Choose <b>B</b> if you find a cheap overhead projector, and <b>D</b> for a venue.</p><p style="margin-top:8pt">Styles marked <i>dipper</i> run on every model. Styles marked <i>platform</i> need A, B or D.</p></div></div>'))

parts = [("4", "Dayton DAEX32EP-4 exciter (32 mm, 40 W, 4 ohm)", "Parts Express 295-230"), ("1", "3-3.5\" full-range speaker (dipper)", "Dayton CE81PF-8 or ND90-8"),
         ("1", "TPA3116D2 2 x 50 W amplifier, Bluetooth", "Parts Express 320-6051"), ("1", "24 V 5 A power brick, UL listed", "Mean Well GST120A24"),
         ("1", "10 W LED star kit with driver", "LEDSupply 10W Dynamic kit"), ("1", "150 mm borosilicate dish", "McMaster-Carr"),
         ("1", "First-surface mirror about 75 x 100 mm", "Edmund Optics #4614"), ("1", "Glass lens 75-90 mm, about 100 mm focal length", "2.5-3x hand magnifier"),
         ("4", "Sorbothane hemispheres", "McMaster / Edmund"), ("1", "Diffraction film 500 lines/mm (optional)", "Rainbow Symphony"),
         ("1", "ESP32 + 3 colour LEDs (optional)", "any + WLED firmware"), ("1 set", "3 mm acrylic, M3/M5 hardware, 5 A fuse, wire", "hardware store"),
         ("1-2 kg", "PETG + white PLA/PETG filament", "see the Sourcing Guide PDF")]
P.append(page(band("05", "Parts list", "For Model A. Links and prices: docs/SHOPPING_LIST.md and the Sourcing Guide PDF.") +
              '<table><thead><tr><th>Qty</th><th>Part</th><th>Suggested source</th></tr></thead><tbody>' +
              "".join(f"<tr><td>{q}</td><td><b>{E(p)}</b></td><td>{E(w)}</td></tr>" for q, p, w in parts) + '</tbody></table>' +
              '<div class="brief" style="margin-top:12pt"><b>Budget:</b> about $300-450 for Model A. Measure your dish\'s inside diameter before printing inserts, then run <code>python3 tools/generate.py --dish-id &lt;mm&gt;</code> to refit them. Check the platform\'s 50.5 mm exciter rings against the exciter datasheet.</div>'))

P.append(page(band("06", "Printing the parts", "Every style kit is in downloads/CYMATIC_ODYSSEY_30_style_kits.zip.") + '''
<table><thead><tr><th>Part</th><th>Material</th><th>Settings</th><th>Why</th></tr></thead><tbody>
<tr><td><b>Gobos</b> (110 mm)</td><td>white PLA or PETG</td><td>0.2 mm layers, 100% infill, flat, no supports</td><td>0.6 mm base lets light through; 2.4 mm lines block it (lithophane principle)</td></tr>
<tr><td><b>Gobos, sharpest</b></td><td>transparency film</td><td>print the SVG on a laser printer</td><td>crisper lines than any 3D print; tint with gels</td></tr>
<tr><td><b>Rainbow gobos</b></td><td>clear PETG</td><td>same as gobos</td><td>between two polarisers, print stress shows as rainbow colours</td></tr>
<tr><td><b>Boundary inserts</b></td><td>PETG</td><td>3 walls, 30% infill; sand the bottom flat</td><td>water-safe; three bottom slots let water equalise</td></tr>
<tr><td><b>Dipper feet</b></td><td>PETG or resin</td><td>100% infill</td><td>stiff, so the wave isn't absorbed</td></tr>
<tr><td><b>Platform</b> (200 mm)</td><td>plain PETG</td><td>4 walls, 40% gyroid; 220 mm bed</td><td>stiffness first; laser-cut 5 mm acrylic is even better</td></tr>
<tr><td><b>Hardware</b></td><td>PETG; sparkle/silk OK</td><td>defaults</td><td>outside the light path</td></tr></tbody></table>
<h3>Print order for your first evening</h3><ol class="steps"><li>One gobo: <b>S05 Metatron</b> (G102) or <b>S01 Orbit Rings</b>: about 1 hour each.</li><li>The circle insert (B021) and the dipper point foot (D001).</li><li>The dipper arm and gobo carrier. Try them on Model C (flashlight + dish) right away.</li><li>Then the platform, foot cups, LED cradle, lens ring and mirror holder for Model A.</li></ol>'''))

P.append(page(band("07", "Assembly and wiring", "Model A, in eight steps. Split-channel wiring lets the shows switch drive modes by themselves.") + svg_wiring() + '''
<ol class="steps" style="margin-top:8pt">
<li><b>Enclosure:</b> acrylic panels + printed corners; drip tray at dish level; vented back; open or windowed front for the beam.</li>
<li><b>Light:</b> LED star on its heatsink in the LED cradle, centred 150-250 mm below the dish; driver and ESP32 to the side.</li>
<li><b>Platform:</b> bond the 4 exciters to the rings underneath (same polarity). Pairs 1+2 and 3+4 in series, the two pairs in parallel, on the amp's <b>left</b> channel. Float it on 4 Sorbothane feet.</li>
<li><b>Dish:</b> into the platform recess; level it with a bubble level; gobo carrier under the aperture.</li>
<li><b>Dipper:</b> 3-inch speaker facing up on the fixed frame; glue the arm to its dust cap; foot just touching the water; speaker on the amp's <b>right</b> channel.</li>
<li><b>Optics:</b> three M5 rods from the frame; lens ring 10-20 cm above the water; mirror holder above; focus by moving the lens.</li>
<li><b>Colour (optional):</b> three colour LEDs about 15 mm apart, or diffraction film after the lens.</li>
<li><b>Storm Bay (optional):</b> the EZ-100 on its base at least 50 cm away, outside the enclosure, ventilated.</li></ol>'''))

P.append(page(band("08", "First light, calibration and your phone", "From switch-on to your own pattern map in 20 minutes.") +
              f'''<div class="shots"><img src="{im("console_desktop.jpg")}"><img src="{im("console_phone.jpg")}"><img src="{im("console_phone_gallery.jpg")}"></div>
<div class="twocol" style="margin-top:10pt"><div><h3>First light</h3><ol class="steps"><li>Fill 5 mm of distilled water + 1 drop of soap. Dim the room.</li>
<li>On your phone open the console: <a href="{CONSOLE_URL}">claude.ai/artifact/STJTY...</a>. Pair the phone with the amp's Bluetooth.</li>
<li>Press <b>Start audio</b> at 10% volume. Tap style <b>S18 Chladni Plate</b>. Raise the volume until squares appear, then stop just above that point.</li>
<li>Set <b>Wiring: Split</b>. Tap <b>S01 Orbit Rings</b>: the dipper should take over.</li></ol></div>
<div><h3>Calibrate and play</h3><ol class="steps"><li>Try S02 (hexagons) and S03 (12-fold). Nudge the frequency with the plus/minus buttons until each locks.</li>
<li>Press <b>Log what I see</b> on good looks: the console builds your own pattern atlas.</li>
<li>Optional: webcam + <code>tools/mode_mapper.py</code> maps everything automatically.</li>
<li>Pick a show, tick <b>Continuous</b>, press <b>Play</b>. <b>Projector mode</b> fills a TV or projector with the live preview.</li></ol></div></div>'''))

P.append(page(band("09", "The 30 styles", "Tap any of these in the console's style gallery. Pages that follow show each one in detail.") +
              '<div class="gallery">' + "".join(f'<figure><img src="{im(s["id"] + "_wall_preview.jpg")}">{s["id"]} {E(s["name"])}</figure>' for s in STYLES) + "</div>"))

for k in range(0, 30, 2):
    P.append(page(band("10", f"Styles {STYLES[k]['id']}-{STYLES[k + 1]['id']}", "Left: simulated wall. Small circle: the water alone. Strip: the three parts to print.") +
                  style_card(STYLES[k]) + style_card(STYLES[k + 1])))

P.append(page(band("11", "The 15 light shows", "Ten minutes each. Every show ends in a bridge that becomes the next show's opening, and borrows a guest style from the show six places ahead.") +
              svg_chain() + '''<div class="twocol" style="margin-top:10pt"><div class="brief"><b>Anatomy of a show (600 s):</b> opening 1:00 → five core styles 1:24 each → guest 1:00 → bridge 1:00. The gold arrows are the play order; the violet threads are the guest borrowings that tie the shows together.</div>
<div class="brief"><b>Running them:</b> choose a show in the console and press Play. Tick <b>Continuous</b> to flow through all 15 (150 minutes). Each show keeps one insert. Gobo and foot changes appear as <i>optional cues</i>: swap them by hand, or leave one gobo in and let the water and colours carry the show.</div></div>'''))
for k in range(0, 15, 2):
    blocks = show_block(k, SHOWS[k]) + (show_block(k + 1, SHOWS[k + 1]) if k + 1 < 15 else "")
    P.append(page(band("11", f"Shows {k + 1}" + (f"-{k + 2}" if k + 1 < 15 else ""), "Times are minutes:seconds into the show. Drive Hz is tone A; 2nd = ratio of tone B.") + blocks))

P.append(page(band("12", "STL index and troubleshooting", "What's in the download and what to do when the wall looks wrong.") + '''
<div class="twocol"><div><h3>downloads/CYMATIC_ODYSSEY_30_style_kits.zip</h3><p style="font-size:9pt">One folder per style (<code>styles/S01_orbit_rings/</code> ...), each with:</p><ul style="font-size:9pt"><li><b>gobo_*.stl</b> + <b>gobo_*.svg</b>: the light stencil (print, or SVG on film)</li><li><b>insert_*.stl</b>: the boundary insert for the dish</li><li><b>dipper_*.stl</b>: the wave-source foot (dipper styles)</li><li><b>wall_preview.png</b>, <b>water_preview.png</b>, <b>parts_preview.png</b></li></ul>
<p style="font-size:9pt">Plus <b>hardware/</b>: platform, foot cup, dipper arm, LED cradle, lens ring, mirror holder, gobo carrier, panel corner, Tesla-coil bay base.</p>
<p style="font-size:9pt">The full library of 355 looks (306 gobos, 37 inserts, 12 feet) is in <code>downloads/gobos_*.zip</code>, <code>inserts.zip</code>, <code>dippers.zip</code>. It's catalogued in <code>docs/GEOMETRY_CATALOG.md</code>.</p></div>
<div><h3>Troubleshooting</h3><table><tbody>
<tr><td><b>Lopsided pattern</b></td><td>Level the dish; check exciter polarity</td></tr>
<tr><td><b>Nothing appears</b></td><td>More volume; try 30-50 Hz first</td></tr>
<tr><td><b>Chaos, droplets</b></td><td>Too much drive: back off until it locks</td></tr>
<tr><td><b>Blurry wall</b></td><td>Refocus the lens; smaller LED die; wall farther away</td></tr>
<tr><td><b>Gobo invisible</b></td><td>Gobo closer to the dish; white (not clear) filament; or film</td></tr>
<tr><td><b>Mode doesn't switch</b></td><td>Console Wiring: Split; platform on L, speaker on R</td></tr>
<tr><td><b>No sound on phone</b></td><td>Tap Start audio; turn off silent mode; check Bluetooth</td></tr>
<tr><td><b>Dull colours</b></td><td>Colour LEDs, not dye; add grating film</td></tr></tbody></table></div></div>'''))

P.append(page(f'''<div class="art"><img src="{im("S10_wall_preview.jpg")}"><img src="{im("S05_wall_preview.jpg")}"><img src="{im("S03_wall_preview.jpg")}"></div>
<h2>Build the chamber. Light the wall.</h2><p>Console on your phone: {CONSOLE_URL}</p><p>Project files: github.com/namastegeitz/eddie-g · apps/cymatic-odyssey</p>
<p style="margin-top:20pt;font-size:8.5pt;color:#8a8eb0">Wall images are simulations; frequencies are calculated starting points. Tune on your own system.</p>''', "back", foot=False))

HTML = f'<!DOCTYPE html><html><head><meta charset="utf-8"><title>CYMATIC ODYSSEY Manual</title><style>{CSS}</style></head><body>{"".join(P)}</body></html>'
out_html = HERE / "manual.html"
out_html.write_text(HTML)
out_pdf = APP / "docs/CYMATIC_ODYSSEY_Manual.pdf"
js = f"""const {{ chromium }} = require('playwright');
(async () => {{ const b = await chromium.launch(); const p = await b.newPage();
  await p.goto({json.dumps(out_html.as_uri())}, {{waitUntil: 'load'}});
  await p.pdf({{ path: {json.dumps(str(out_pdf))}, format: 'Letter', printBackground: true, preferCSSPageSize: true }});
  await b.close(); }})();"""
subprocess.run(["node", "-e", js], check=True)
print("pages", page_no[0], "->", out_pdf)
