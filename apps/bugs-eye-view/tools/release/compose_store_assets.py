#!/usr/bin/env python3
"""Turns the renders from store_art.gd into every image the stores ask for:
icons, screenshots per device size, key art, a transparent title logo and
each store's capsules/banners, cropped from the 4K key art. Sizes follow the
stores' current specs (see "BUG'S-EYE VIEW/Research/"). Pillow only.

    python3 tools/release/compose_store_assets.py
"""
import pathlib
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "BUG'S-EYE VIEW" / "Store Assets"
REN = OUT / "_renders"
FONT = "/usr/share/fonts/opentype/inter/InterDisplay-Black.otf"
TITLE = "BUG'S-EYE VIEW"
GOLD = (255, 200, 61)
EDGE = (46, 26, 10)


def save(img: Image.Image, rel: str, quality: int = 90) -> None:
    path = OUT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix.lower() in (".jpg", ".jpeg"):
        img.convert("RGB").save(path, quality=quality, optimize=True)
    else:
        img.save(path, optimize=True)
    print(f"{rel}  {img.size[0]}x{img.size[1]}")


def cover(img: Image.Image, size: tuple, focus=(0.55, 0.6)) -> Image.Image:
    """Scale to cover `size`, then crop around the focus point (0-1)."""
    w, h = size
    s = max(w / img.width, h / img.height)
    big = img.resize((max(w, round(img.width * s)), max(h, round(img.height * s))), Image.LANCZOS)
    x = min(max(round(big.width * focus[0] - w / 2), 0), big.width - w)
    y = min(max(round(big.height * focus[1] - h / 2), 0), big.height - h)
    return big.crop((x, y, x + w, y + h))


def logo(width: int, two_lines: bool = False) -> Image.Image:
    """The title in bold capitals: gold, a thick dark edge and a soft shadow,
    on a transparent background, `width` px wide."""
    lines = ["BUG'S-EYE", "VIEW"] if two_lines else [TITLE]
    size = 400
    font = ImageFont.truetype(FONT, size)
    stroke = size // 11
    pad = stroke * 3
    tmp = ImageDraw.Draw(Image.new("RGBA", (10, 10)))
    boxes = [tmp.textbbox((0, 0), l, font=font, stroke_width=stroke) for l in lines]
    tw = max(b[2] - b[0] for b in boxes)
    lh = [b[3] - b[1] for b in boxes]
    th = sum(lh) + (len(lines) - 1) * size // 8
    canvas = Image.new("RGBA", (tw + pad * 2, th + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    ds = ImageDraw.Draw(shadow)
    y = pad
    for l, b, hgt in zip(lines, boxes, lh):
        x = pad + (tw - (b[2] - b[0])) / 2 - b[0]
        ds.text((x + stroke * 0.6, y - b[1] + stroke * 0.9), l, font=font, fill=(0, 0, 0, 170),
                stroke_width=stroke, stroke_fill=(0, 0, 0, 170))
        d.text((x, y - b[1]), l, font=font, fill=GOLD, stroke_width=stroke, stroke_fill=EDGE)
        y += hgt + size // 8
    shadow = shadow.filter(ImageFilter.GaussianBlur(stroke * 0.8))
    shadow.alpha_composite(canvas)
    s = width / shadow.width
    return shadow.resize((width, round(shadow.height * s)), Image.LANCZOS)


def titled(base: Image.Image, where: str = "top", frac: float = 0.62, two_lines: bool = False) -> Image.Image:
    img = base.convert("RGBA")
    lg = logo(round(img.width * frac), two_lines)
    if lg.height > img.height * 0.45:
        lg = lg.resize((round(lg.width * img.height * 0.45 / lg.height), round(img.height * 0.45)), Image.LANCZOS)
    x = (img.width - lg.width) // 2
    y = round(img.height * 0.04) if where == "top" else img.height - lg.height - round(img.height * 0.05)
    if where == "right":
        x = img.width - lg.width - round(img.width * 0.03)
        y = (img.height - lg.height) // 2
    img.alpha_composite(lg, (x, y))
    return img.convert("RGB")


def gradient(size: tuple) -> Image.Image:
    """Warm amber glow fading to dark brown at the corners (icon background)."""
    w, h = size
    base = Image.new("RGB", size, (58, 30, 10))
    glow = Image.new("L", size, 0)
    d = ImageDraw.Draw(glow)
    for i in range(60):
        r = (w * 0.75) * (1 - i / 60)
        v = int(255 * (i / 60) ** 1.4)
        d.ellipse((w / 2 - r, h * 0.48 - r, w / 2 + r, h * 0.48 + r), fill=v)
    glow = glow.filter(ImageFilter.GaussianBlur(w / 30))
    warm = Image.new("RGB", size, (246, 178, 64))
    return Image.composite(warm, base, glow)


def main() -> None:
    key = Image.open(REN / "keyart" / "keyart.png").convert("RGB")
    key_hd = Image.open(REN / "1920x1080" / "keyart.png").convert("RGB")

    # --- Icons -------------------------------------------------------------
    bug = Image.open(REN / "icon" / "icon_rgba.png").convert("RGBA")
    bb = bug.getbbox()
    bug = bug.crop(bb)
    def icon(size: int, bug_frac: float = 0.86, alpha: bool = False) -> Image.Image:
        bg = gradient((size, size)).convert("RGBA")
        if alpha:
            bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        s = size * bug_frac / max(bug.width, bug.height)
        b = bug.resize((round(bug.width * s), round(bug.height * s)), Image.LANCZOS)
        bg.alpha_composite(b, ((size - b.width) // 2, (size - b.height) // 2 + round(size * 0.02)))
        return bg
    app = icon(1024).convert("RGB")
    save(app, "Icons/app-icon-1024.png")                       # Apple (opaque), Steam client
    save(icon(512), "Icons/google-play-icon-512.png")
    save(icon(192).convert("RGB"), "Icons/icon-192.png")
    save(gradient((432, 432)), "Icons/android-adaptive-background-432.png")
    save(icon(432, 0.6, alpha=True), "Icons/android-adaptive-foreground-432.png")
    app.save(OUT / "Icons" / "windows-icon.ico", sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
    print("Icons/windows-icon.ico")

    # --- Key art and the logo ------------------------------------------------
    save(key, "Key Art/key-art-3840x2160-no-text.jpg")
    save(titled(key_hd, "top", 0.6), "Key Art/key-art-1920x1080-titled.jpg")
    lg = logo(1240)
    canvas = Image.new("RGBA", (1280, 720), (0, 0, 0, 0))
    canvas.alpha_composite(lg, ((1280 - lg.width) // 2, (720 - lg.height) // 2))
    save(canvas, "Key Art/logo-1280x720-transparent.png")

    # --- Screenshots -----------------------------------------------------------
    order = ["kitchen", "dominoes", "slap", "fridge", "trap", "bugeye"]
    for folder, label in [("1920x1080", "1920x1080 (Steam, GOG, Google Play, Epic, Microsoft, itch.io)"),
                          ("iphone-6.9", "iPhone 6.9 inch 2868x1320"),
                          ("iphone-6.3", "iPhone 6.3 inch 2622x1206 (required size)"),
                          ("ipad-13", "iPad 13 inch 2752x2064")]:
        for i, name in enumerate(order, 1):
            src = REN / folder / f"{name}.png"
            if src.exists():
                save(Image.open(src).convert("RGB"), f"Screenshots/{label}/{i:02d}-{name}.jpg", 92)

    # --- Steam --------------------------------------------------------------
    save(titled(cover(key, (920, 430)), "right", 0.5), "Steam/header_capsule_920x430.jpg")
    save(titled(cover(key, (462, 174)), "right", 0.55), "Steam/small_capsule_462x174.jpg")
    save(titled(cover(key, (1232, 706)), "top", 0.6), "Steam/main_capsule_1232x706.jpg")
    save(titled(cover(key, (748, 896), (0.42, 0.6)), "top", 0.86, True), "Steam/vertical_capsule_748x896.jpg")
    save(titled(cover(key, (600, 900), (0.42, 0.6)), "top", 0.86, True), "Steam/library_capsule_600x900.jpg")
    save(titled(cover(key, (920, 430)), "right", 0.5), "Steam/library_header_920x430.jpg")
    save(cover(key, (3840, 1240), (0.5, 0.62)), "Steam/library_hero_3840x1240_no_text.jpg")
    save(canvas, "Steam/library_logo_1280x720.png")
    save(cover(key, (1438, 810)), "Steam/page_background_1438x810.jpg")

    # --- Google Play ----------------------------------------------------------
    save(titled(cover(key, (1024, 500)), "right", 0.52), "Google Play/feature_graphic_1024x500.jpg")
    save(icon(512), "Google Play/icon_512.png")

    # --- Apple ----------------------------------------------------------------
    save(app, "Apple App Store/app_icon_1024_opaque.png")

    # --- Epic Games Store ---------------------------------------------------------
    save(titled(cover(key, (2560, 1440)), "top", 0.55), "Epic Games Store/offer_landscape_2560x1440.jpg")
    save(titled(cover(key, (1200, 1600), (0.42, 0.6)), "top", 0.86, True), "Epic Games Store/offer_portrait_1200x1600.jpg")
    elogo = Image.new("RGBA", (960, 540), (0, 0, 0, 0))
    l2 = logo(920)
    elogo.alpha_composite(l2, ((960 - l2.width) // 2, (540 - l2.height) // 2))
    save(elogo, "Epic Games Store/product_logo_960x540.png")
    save(titled(cover(key, (1200, 1200), (0.42, 0.6)), "top", 0.8, True), "Epic Games Store/social_1200x1200.jpg")

    # --- Microsoft Store ------------------------------------------------------------
    save(titled(cover(key, (1440, 2160), (0.42, 0.6)), "top", 0.88, True), "Microsoft Store/poster_art_1440x2160.jpg")
    save(titled(cover(key, (2160, 2160), (0.42, 0.6)), "top", 0.8, True), "Microsoft Store/box_art_2160x2160.jpg")
    save(icon(300).convert("RGB"), "Microsoft Store/tile_300x300.png")
    save(key, "Microsoft Store/super_hero_art_3840x2160_no_text.jpg")

    # --- itch.io and GOG ---------------------------------------------------------------
    save(titled(cover(key, (630, 500), (0.45, 0.6)), "top", 0.85, True), "itch.io/cover_630x500.jpg")
    save(titled(key, "top", 0.6), "GOG/key_art_3840x2160_titled.jpg")
    save(canvas, "GOG/logo_1280x720_transparent.png")

    shutil.rmtree(REN, ignore_errors=True) if (OUT / ".remove_renders").exists() else None


if __name__ == "__main__":
    main()
