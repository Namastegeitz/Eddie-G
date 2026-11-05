#!/usr/bin/env python3
"""Makes every app icon from the rendered space art (assets/icons/space_icon_1024.png,
made by tools/make_space_icon.tscn):

  assets/icons/icon_{1024,512,192,180,152,120}.png  rounded-square app icons
  assets/icons/icon.ico                               Windows (16-256 px)
  assets/icons/adaptive_background.png (432)          Android adaptive icon: full art
  assets/icons/adaptive_foreground.png (432)          Android adaptive icon: empty layer
  assets/icons/adaptive_monochrome.png (432)          Android 13+ themed icon: ringed-planet silhouette
  docs/store/play_icon_512.png                        Google Play (full square; Play rounds it)
  dist/desktop/cosmic-saucer-drift.{ico,png,icns}     desktop shortcut icons

    python3 tools/make_icons.py
"""
import os
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(HERE)
SRC = os.path.join(APP, "assets/icons/space_icon_1024.png")
ICONS = os.path.join(APP, "assets/icons")
DESK = os.path.join(APP, "dist/desktop")


def rounded(img, radius=0.2, rim=True):
    """Rounded-square icon with an anti-aliased edge and a faint bright rim."""
    n = img.width
    ss = 4
    mask = Image.new("L", (n * ss, n * ss), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, n * ss - 1, n * ss - 1], int(n * ss * radius), fill=255)
    mask = mask.resize((n, n), Image.LANCZOS)
    out = img.convert("RGBA").copy()
    if rim and n >= 64:
        edge = Image.new("L", (n * ss, n * ss), 0)
        w = max(2, int(n * ss * 0.012))
        ImageDraw.Draw(edge).rounded_rectangle([w // 2, w // 2, n * ss - 1 - w // 2, n * ss - 1 - w // 2], int(n * ss * radius), outline=255, width=w)
        edge = edge.resize((n, n), Image.LANCZOS).filter(ImageFilter.GaussianBlur(n / 400))
        glow = Image.new("RGBA", (n, n), (190, 150, 255, 0))
        glow.putalpha(edge.point(lambda v: int(v * 0.55)))
        out = Image.alpha_composite(out, glow)
    out.putalpha(mask)
    return out


def monochrome(n=432):
    """White ringed planet and a small moon on transparent, inside the
    adaptive-icon safe zone, for Android's themed (one-colour) icons."""
    ss = 4
    m = Image.new("L", (n * ss, n * ss), 0)
    d = ImageDraw.Draw(m)
    c = n * ss / 2
    r = n * ss * 0.17
    # Ring behind, planet, then the near half of the ring in front.
    ring = Image.new("L", m.size, 0)
    rd = ImageDraw.Draw(ring)
    rw, rh = r * 2.35, r * 0.62
    rd.ellipse([c - rw, c - rh, c + rw, c + rh], outline=255, width=int(r * 0.16))
    ring = ring.rotate(18, resample=Image.BICUBIC, center=(c, c))
    m.paste(255, mask=ring)
    gap = Image.new("L", m.size, 0)
    ImageDraw.Draw(gap).ellipse([c - r * 1.12, c - r * 1.12, c + r * 1.12, c + r * 1.12], fill=255)
    m.paste(0, mask=gap)
    d.ellipse([c - r, c - r, c + r, c + r], fill=255)
    front = ring.copy()
    cut = Image.new("L", m.size, 0)
    ImageDraw.Draw(cut).rectangle([0, 0, m.size[0], c + r * 0.05], fill=255)
    cut = cut.rotate(18, resample=Image.BICUBIC, center=(c, c))
    front.paste(0, mask=cut)
    m.paste(0, mask=front.filter(ImageFilter.MaxFilter(9)))
    m.paste(255, mask=front)
    mr = r * 0.32
    mx, my = c + r * 1.55, c - r * 1.5
    d.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=255)
    m = m.resize((n, n), Image.LANCZOS)
    out = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    out.putalpha(m)
    return out


def small_crop(src):
    """For tiny sizes, zoom in on the ringed planet so it still reads."""
    return src.crop((40, 200, 800, 960))


def main():
    src = Image.open(SRC).convert("RGB")
    os.makedirs(DESK, exist_ok=True)
    for sz in [1024, 512, 192, 180, 152, 120]:
        rounded(src.resize((sz, sz), Image.LANCZOS)).save(os.path.join(ICONS, "icon_%d.png" % sz))
    src.resize((432, 432), Image.LANCZOS).save(os.path.join(ICONS, "adaptive_background.png"))
    Image.new("RGBA", (432, 432), (0, 0, 0, 0)).save(os.path.join(ICONS, "adaptive_foreground.png"))
    monochrome().save(os.path.join(ICONS, "adaptive_monochrome.png"))
    src.resize((512, 512), Image.LANCZOS).save(os.path.join(APP, "docs/store/play_icon_512.png"))
    # Windows .ico: big sizes show the whole scene, small ones the planet.
    sizes = [256, 128, 64, 48, 32, 24, 16]
    frames = []
    for sz in sizes:
        base = src if sz >= 64 else small_crop(src)
        frames.append(rounded(base.resize((sz, sz), Image.LANCZOS), rim=sz >= 64))
    big = rounded(src.resize((256, 256), Image.LANCZOS))
    big.save(os.path.join(ICONS, "icon.ico"), sizes=[(s, s) for s in sizes], append_images=frames[1:])
    big.save(os.path.join(DESK, "cosmic-saucer-drift.ico"), sizes=[(s, s) for s in sizes], append_images=frames[1:])
    rounded(src.resize((512, 512), Image.LANCZOS)).save(os.path.join(DESK, "cosmic-saucer-drift.png"))
    rounded(src.resize((1024, 1024), Image.LANCZOS)).save(os.path.join(DESK, "cosmic-saucer-drift.icns"))
    print("icons written")


if __name__ == "__main__":
    main()
