#!/usr/bin/env python3
"""Compares screenshots with approved ones (see tools/visual_check.sh).

  visual_diff.py <new shots dir> <baseline dir>             compare; exit 1 on a failure
  visual_diff.py --approve <new shots dir> <baseline dir>   save new shots as the baseline (half size)
"""
import os
import sys

from PIL import Image, ImageChops

MAX_CHANGED = 5.0   # % of pixels that changed by more than 16/255
MAX_MEAN = 3.0      # mean difference (0-255)


def half(im):
    return im.convert("RGB").resize((max(1, im.width // 2), max(1, im.height // 2)), Image.BILINEAR)


def main(argv):
    approve = "--approve" in argv
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 2:
        sys.exit(__doc__)
    new_dir, base_dir = args
    names = sorted(n for n in os.listdir(new_dir) if n.endswith(".png"))
    if not names:
        sys.exit("no screenshots in %s" % new_dir)
    if approve:
        os.makedirs(base_dir, exist_ok=True)
        for n in names:
            half(Image.open(os.path.join(new_dir, n))).save(os.path.join(base_dir, n), optimize=True)
        print("approved %d screens into %s" % (len(names), base_dir))
        return 0
    bad = 0
    for n in names:
        bp = os.path.join(base_dir, n)
        if not os.path.exists(bp):
            print("NEW  %s (no baseline yet: run with --approve once it looks right)" % n)
            continue
        a = half(Image.open(os.path.join(new_dir, n)))
        b = Image.open(bp).convert("RGB")
        if a.size != b.size:
            print("FAIL %s size %s, baseline %s" % (n, a.size, b.size))
            bad += 1
            continue
        h = ImageChops.difference(a, b).convert("L").histogram()
        tot = float(sum(h))
        changed = sum(h[16:]) / tot * 100.0
        mean = sum(i * c for i, c in enumerate(h)) / tot
        ok = changed <= MAX_CHANGED and mean <= MAX_MEAN
        bad += 0 if ok else 1
        print("%-4s %-34s changed %5.2f%%  mean %.2f" % ("OK" if ok else "FAIL", n, changed, mean))
    print("VISUAL %s" % ("FAILED" if bad else "OK"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
