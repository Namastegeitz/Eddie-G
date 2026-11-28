"""Pictures and icons for the phone app (apps/web/public), sized for phones.

Every simulated picture carries a burned-in SIMULATION mark, renders carry 3D RENDER (spec: never present a
simulation as real footage). Sources: docs/manual/hires (made by docs/manual/build_assets.py) and the show
posters in marketing/videos.

    python3 apps/web/scripts/build_media.py
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

APP = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(APP / "docs/manual"))
from build_assets import mark  # noqa: E402  (same badge as the manual)

HIRES = APP / "docs/manual/hires"
PUB = APP / "apps/web/public"
MOBILE = APP / "apps/mobile/assets"
Q = dict(quality=80, optimize=True, progressive=True)


def fit(im: Image.Image, w: int) -> Image.Image:
    im = im.convert("RGB")
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)


def styles():
    out = PUB / "media/styles"
    out.mkdir(parents=True, exist_ok=True)
    ids = [s["id"] for s in json.loads((APP / "catalog/styles.json").read_text())]
    for sid in ids:
        # unmarked original preview, marked once at the final size so the badge stays readable
        raw = Image.open(next((APP / "styles").glob(f"{sid}_*/wall_preview.png"))).convert("RGB")
        # the 1300 px manual picture is sharper; its badge sits under the new one at the same spot and scale
        mark(fit(Image.open(HIRES / f"{sid}_wall.jpg"), 760), "SIMULATION").save(out / f"{sid}-wall.jpg", **Q)
        mark(fit(raw, 260), "SIMULATION").save(out / f"{sid}-thumb.jpg", **Q)
        mark(fit(Image.open(HIRES / f"{sid}_water.jpg"), 380), "SIMULATION").save(out / f"{sid}-water.jpg", **Q)
        mark(fit(Image.open(HIRES / f"{sid}_chamber.jpg"), 720), "3D RENDER").save(out / f"{sid}-chamber.jpg", **Q)
    return len(ids)


def shows():
    out = PUB / "media/shows"
    out.mkdir(parents=True, exist_ok=True)
    data = json.loads((APP / "catalog/content.json").read_text())["shows"]
    posters = sorted((APP / "marketing/videos").glob("[0-9][0-9]_*.jpg"))
    assert len(posters) == len(data), (len(posters), len(data))
    for show, p in zip(data, posters):
        mark(fit(Image.open(p), 540), "SIMULATION").save(out / f"{show['id']}.jpg", **Q)
    return len(data)


def emblem(size: int, pad: float = 0.0) -> Image.Image:
    """App icon: a hexagonal standing-wave lattice (three plane waves at 60 degrees) inside a gold ring.
    A drawn graphic, not a picture of water."""
    S = size
    y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    cx = cy = (S - 1) / 2
    r0 = S * (0.5 - pad) * 0.86
    u, v = (x - cx) / r0, (y - cy) / r0
    k = 2 * math.pi * 2.6
    h = sum(np.cos(k * (u * math.cos(a) + v * math.sin(a))) for a in (0, 2 * math.pi / 3, 4 * math.pi / 3))
    rr = np.sqrt(u * u + v * v)
    # bright caustic network along the wave's zero lines, gold nodes at the crests, cool light in the cells
    net = np.exp(-(h / 0.28) ** 2)
    node = np.clip((h - 2.2) / 0.8, 0, 1) ** 1.5
    cell = np.clip((-h - 0.2) / 1.3, 0, 1)
    disc = np.clip((1.0 - rr) * S * 0.02, 0, 1)
    fade = np.clip(1.25 - 0.55 * rr, 0, 1)
    bg = np.zeros((S, S, 3), np.float32)
    bg[..., 0], bg[..., 1], bg[..., 2] = 7, 8, 26
    gold = np.array([255, 214, 140], np.float32)
    cyan = np.array([110, 200, 255], np.float32)
    deep = np.array([18, 30, 78], np.float32)
    col = deep + cyan * (0.85 * net[..., None]) + gold * node[..., None] + np.array([40, 60, 140], np.float32) * (0.35 * cell[..., None])
    col = col * fade[..., None]
    img = bg + (col - bg) * disc[..., None]
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(im)
    w = max(2, int(S * 0.018))
    b = cx - r0 * 1.02, cy - r0 * 1.02, cx + r0 * 1.02, cy + r0 * 1.02
    d.ellipse(b, outline=(255, 210, 122), width=w)
    return im


def icons():
    big = emblem(1024)
    for n in (192, 512):
        big.resize((n, n), Image.LANCZOS).save(PUB / f"icon-{n}.png", optimize=True)
    emblem(1024, pad=0.1).resize((512, 512), Image.LANCZOS).save(PUB / "icon-maskable-512.png", optimize=True)
    big.resize((180, 180), Image.LANCZOS).save(PUB / "apple-touch-icon.png", optimize=True)
    big.resize((32, 32), Image.LANCZOS).save(PUB / "favicon-32.png", optimize=True)
    # social preview card (link previews in texts and chats)
    og = Image.new("RGB", (1200, 630), (7, 8, 26))
    wall = Image.open(PUB / "media/styles/S05-wall.jpg").convert("RGB").resize((560, 560), Image.LANCZOS)
    og.paste(wall, (600, 35))
    og.paste(big.resize((140, 140), Image.LANCZOS), (70, 70))
    d = ImageDraw.Draw(og)
    from build_assets import FONT
    from PIL import ImageFont
    d.text((70, 250), "Cymatic Light Chamber", font=ImageFont.truetype(FONT, 50), fill=(255, 255, 255))
    d.text((70, 320), "Sound shapes water. Water shapes light.", font=ImageFont.truetype(FONT, 28), fill=(185, 189, 216))
    d.text((70, 370), "30 styles · 15 light shows · build manual", font=ImageFont.truetype(FONT, 26), fill=(255, 210, 122))
    og.save(PUB / "og-card.jpg", **Q)
    # store/app icon sources for Capacitor (apps/mobile): 1024 icon, splash
    MOBILE.mkdir(parents=True, exist_ok=True)
    big.save(MOBILE / "icon-only.png")
    emblem(1024, pad=0.17).save(MOBILE / "icon-foreground.png")
    Image.new("RGB", (1024, 1024), (7, 8, 26)).save(MOBILE / "icon-background.png")
    sp = Image.new("RGB", (2732, 2732), (7, 8, 26))
    sp.paste(emblem(900), (916, 916))
    sp.save(MOBILE / "splash.png")
    sp.save(MOBILE / "splash-dark.png")


if __name__ == "__main__":
    n = styles()
    m = shows()
    icons()
    total = sum(f.stat().st_size for f in (PUB / "media").rglob("*.jpg"))
    print(f"styles {n}, shows {m}, media {total / 1e6:.1f} MB, icons written")
