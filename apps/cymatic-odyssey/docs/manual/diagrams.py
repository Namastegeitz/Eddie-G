"""SVG diagrams shared by the manual builders (system, models, wiring, show chain)."""
import html
import json
import math
from pathlib import Path

E = html.escape
APP = Path(__file__).resolve().parent.parent.parent
SHOWS = json.loads((APP / "catalog/content.json").read_text())["shows"]
SB = {s["id"]: s for s in json.loads((APP / "catalog/styles.json").read_text())}


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


