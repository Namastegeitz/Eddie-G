#!/usr/bin/env python3
"""Visual regression check: compares fresh screenshots with the stored
baselines in tests/visual/<size>/ and fails if a screen changed a lot.
Small differences (the turning menu diorama, people moving) are allowed.

  python3 tools/visual/compare.py NEW_DIR [--update]
NEW_DIR holds <size>/<shot>.png from tools/visual/check_visual.sh.
--update stores NEW_DIR as the new baselines (after a deliberate change).
"""
import shutil, sys
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "tests" / "visual"
LIMIT = 8.0   # mean absolute difference, 0-255, on a 320 px wide copy
WIDTH = 640   # baselines are stored at this width to keep the repo small


def small(p: Path, w: int) -> Image.Image:
    im = Image.open(p).convert("RGB")
    return im.resize((w, round(im.height * w / im.width)), Image.BILINEAR)


def main() -> int:
    new = Path(sys.argv[1])
    if "--update" in sys.argv:
        for f in sorted(new.glob("*/*.png")):
            dst = BASE / f.parent.name / f.name
            dst.parent.mkdir(parents=True, exist_ok=True)
            small(f, WIDTH).save(dst, optimize=True)
        print("baselines updated")
        return 0
    fails = 0
    for b in sorted(BASE.glob("*/*.png")):
        f = new / b.parent.name / b.name
        if not f.exists():
            print(f"MISSING {b.parent.name}/{b.name}")
            fails += 1
            continue
        a, c = small(b, 320), small(f, 320)
        if a.size != c.size:
            print(f"FAIL {b.parent.name}/{b.name}: aspect changed {a.size} vs {c.size}")
            fails += 1
            continue
        diff = sum(ImageStat.Stat(ImageChops.difference(a, c)).mean) / 3
        status = "ok  " if diff <= LIMIT else "FAIL"
        fails += diff > LIMIT
        print(f"{status} {b.parent.name}/{b.name}: difference {diff:.1f} (limit {LIMIT})")
    print("VISUAL OK" if not fails else f"VISUAL FAILED ({fails})")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
