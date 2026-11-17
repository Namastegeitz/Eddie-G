"""Make the rendered screenshots store-ready: flatten to RGB (no alpha, which
Apple and Google refuse), give them plain names, and make the 2622x1206 iPhone set
from the 2868x1320 one (same shape). Run after the renders:  python3 finish.py"""
import glob, os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
NAMES = {"saturn_rings": "01-saturn-rings", "mars": "02-mars-aurora", "io": "03-io-cockpit",
         "hd189733b": "04-hd189733b", "kepler16b": "05-kepler16b", "trappist1b": "06-trappist1b",
         "wasp76b": "07-wasp76b"}
done = 0
for folder in ("1920x1080", "iphone-2868x1320", "ipad-2752x2064"):
    for f in sorted(glob.glob(os.path.join(HERE, folder, "*.png"))):
        base = os.path.basename(f)
        if "_" not in base:
            continue   # already finished (plain name)
        track = next((t for t in NAMES if "_" + t + "_" in "_" + base.split("_", 1)[1]), None)
        if track is None:
            continue   # already finished (plain name)
        im = Image.open(f).convert("RGB")
        out = os.path.join(HERE, folder, NAMES[track] + ".png")
        im.save(out, optimize=True)
        os.remove(f)
        if folder == "iphone-2868x1320":
            small = os.path.join(HERE, "iphone-2622x1206")
            os.makedirs(small, exist_ok=True)
            im.resize((2622, 1206), Image.LANCZOS).save(os.path.join(small, NAMES[track] + ".png"), optimize=True)
        done += 1
print("finished", done, "screenshots")
