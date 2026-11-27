#!/usr/bin/env python3
"""High-resolution assets for the manual (docs/manual/hires/, gitignored).

- style wall pictures re-rendered at 1300 px, water-only at 700 px, with a burned-in SIMULATION mark
- 3D renders (Blender) marked '3D RENDER'
- small thumbnails for show timelines
- console screenshots at 2x pixel density + element boxes for numbered callouts (needs Playwright)
"""
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
APP = HERE.parent.parent
OUT = HERE / "hires"
OUT.mkdir(exist_ok=True)
sys.path.insert(0, str(APP / "tools"))
FONT = "/usr/share/fonts/opentype/inter/Inter-Bold.otf"


def mark(im: Image.Image, text: str, corner="tl") -> Image.Image:
    im = im.convert("RGB")
    W, H = im.size
    size = max(14, int(W * 0.026))
    f = ImageFont.truetype(FONT, size)
    d = ImageDraw.Draw(im, "RGBA")
    tw = d.textlength(text, font=f) + size * 0.12 * len(text)
    pad = size * 0.55
    x = pad if corner[1] == "l" else W - tw - 3 * pad
    y = pad if corner[0] == "t" else H - size - 3 * pad
    d.rounded_rectangle((x, y, x + tw + 2 * pad, y + size + 1.6 * pad), radius=size * 0.5, fill=(5, 6, 13, 200), outline=(255, 210, 122, 230), width=max(1, size // 10))
    cx = x + pad
    for ch in text:
        d.text((cx, y + 0.7 * pad), ch, font=f, fill=(255, 233, 176, 255))
        cx += d.textlength(ch, font=f) + size * 0.12
    return im


def styles():
    from odyssey import catalog
    from render_wall import render
    from styles import STYLES
    ents = {e["name"]: e for e in catalog.entries()}
    for s in STYLES:
        sid = s["id"]
        if (OUT / f"{sid}_wall.jpg").exists():
            continue
        g = ents[s["gobo"]]["fn"]()
        region = ents[s["insert"]]["fn"]().region
        mark(render(s, g, region, res=1300), "SIMULATION").save(OUT / f"{sid}_wall.jpg", quality=86, optimize=True, progressive=True)
        water = render(s, None, region, res=700)
        mark(water, "SIMULATION").save(OUT / f"{sid}_water.jpg", quality=85, optimize=True)
        water.convert("RGB").resize((240, 240), Image.LANCZOS).save(OUT / f"{sid}_thumb.jpg", quality=82)
        folder = next((APP / "styles").glob(sid + "_*"))
        Image.open(folder / "parts_preview.png").convert("RGB").save(OUT / f"{sid}_parts.jpg", quality=88)
        ch = APP / "marketing/renders" / f"chamber_{sid}.jpg"
        if ch.exists():
            mark(Image.open(ch), "3D RENDER", "tl").save(OUT / f"{sid}_chamber.jpg", quality=84, optimize=True)
        print("style", sid, flush=True)


def renders():
    for f in sorted(OUT.glob("step*.png")) + [OUT / "assembled.png", OUT / "exploded.png"]:
        if f.exists():
            mark(Image.open(f), "3D RENDER").save(f.with_suffix(".jpg"), quality=86, optimize=True, progressive=True)
            print("render", f.name)


SHOT_JS = r"""
const { chromium, devices } = require('playwright');
(async () => {
  const out = process.argv[2], url = process.argv[3];
  const b = await chromium.launch({args:['--use-gl=swiftshader','--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
  const p = await b.newPage({viewport:{width:1440,height:900}, deviceScaleFactor:2});
  await p.goto(url); await p.waitForTimeout(800);
  await p.selectOption('#voy','show:quasicrystal'); await p.check('#cont'); await p.click('#voyGo'); await p.waitForTimeout(3500);
  const ids = ['startBtn','panicBtn','fsBtn','mode','f','ratio','pulse','breathe','vol','wiring','depth','sim','gobo','read','voy','cont','steps','theme','gal','seen'];
  const boxes = {};
  for (const id of ids) { const e = await p.$('#'+id); if (e) { const r = await e.boundingBox(); if (r) boxes[id] = r; } }
  await p.screenshot({path: out + '/console_desktop.png'});
  require('fs').writeFileSync(out + '/console_desktop_boxes.json', JSON.stringify({w:1440,h:900,boxes}));
  const m = await b.newPage({...devices['iPhone 13']});
  await m.goto(url); await m.waitForTimeout(800);
  await m.click('#gal button[data-s="S11"]'); await m.waitForTimeout(2500); await m.evaluate(()=>window.scrollTo(0,0));
  await m.screenshot({path: out + '/console_phone.png'});
  await m.evaluate(()=>document.getElementById('gal').scrollIntoView()); await m.waitForTimeout(400);
  await m.screenshot({path: out + '/console_phone_gallery.png'});
  await b.close();
})();
"""


def console():
    js = OUT / "_shot.cjs"
    js.write_text(SHOT_JS)
    subprocess.run(["node", str(js), str(OUT), (APP / "console/index.html").as_uri()], check=True)
    js.unlink()
    for n in ("console_desktop", "console_phone", "console_phone_gallery"):
        Image.open(OUT / f"{n}.png").convert("RGB").save(OUT / f"{n}.jpg", quality=88, optimize=True)
    print("console shots")


if __name__ == "__main__":
    what = sys.argv[1:] or ["styles", "renders", "console"]
    if "styles" in what:
        styles()
    if "renders" in what:
        renders()
    if "console" in what:
        console()
