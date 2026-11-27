"""App icons and splash screens for the Android and iOS projects, from apps/mobile/assets
(made by apps/web/scripts/build_media.py). Replaces the Capacitor placeholders at the same sizes.

    python3 apps/mobile/scripts/native_assets.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

M = Path(__file__).resolve().parents[1]
A = M / "assets"
BG = (7, 8, 26)
icon = Image.open(A / "icon-only.png").convert("RGB")
fg = Image.open(A / "icon-foreground.png").convert("RGB")


def splash(w: int, h: int) -> Image.Image:
    im = Image.new("RGB", (w, h), BG)
    s = int(min(w, h) * 0.36)
    e = icon.resize((s, s), Image.LANCZOS)
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, s - 1, s - 1), fill=255)
    im.paste(e, ((w - s) // 2, (h - s) // 2), mask)
    return im


# Android launcher icons (legacy, round, adaptive foreground) and splash screens
res = M / "android/app/src/main/res"
for d, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    out = res / f"mipmap-{d}"
    sq = icon.resize((px, px), Image.LANCZOS)
    sq.save(out / "ic_launcher.png")
    mask = Image.new("L", (px, px), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, px - 1, px - 1), fill=255)
    rnd = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    rnd.paste(sq, (0, 0), mask)
    rnd.save(out / "ic_launcher_round.png")
    f = int(px * 108 / 48)
    fg.resize((f, f), Image.LANCZOS).save(out / "ic_launcher_foreground.png")
(res / "values/ic_launcher_background.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#07081A</color>\n</resources>\n'
)
for p in res.glob("drawable*/splash.png"):
    w, h = Image.open(p).size
    splash(w, h).save(p)

# iOS: one 1024 px icon (no transparency, as the App Store requires) and the 2732 px splash
ios = M / "ios/App/App/Assets.xcassets"
icon.save(ios / "AppIcon.appiconset/AppIcon-512@2x.png")
sp = splash(2732, 2732)
for p in (ios / "Splash.imageset").glob("*.png"):
    sp.save(p)
print("native icons and splash screens written")
