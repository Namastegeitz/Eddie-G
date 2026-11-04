"""Top-down plots of every track from tools/dump_tracks.gd output.

Usage: python3 tools/plot_tracks.py <tracks_dump.json> <out.png> [variant 0|1|2]
"""
import json, sys, math
from PIL import Image, ImageDraw

data = json.load(open(sys.argv[1]))
out = sys.argv[2]
var = sys.argv[3] if len(sys.argv) > 3 else "0"
ids = sorted({k.rsplit("_", 1)[0] for k in data})
if len(sys.argv) > 4:
    ids = sys.argv[4].split(",")
W, H = 560, 560
cols = 4
rows = (len(ids) + cols - 1) // cols
img = Image.new("RGB", (W * cols, H * rows), (12, 10, 24))
SURF = {0: (90, 100, 140), 1: (150, 130, 100), 2: (150, 220, 255), 3: (180, 60, 255), 4: (60, 180, 80), 5: (120, 50, 40)}
FEAT = {"pod": (80, 255, 255), "crate": (255, 220, 60), "boost": (255, 80, 220), "roller": (200, 120, 80),
        "flare": (255, 160, 0), "laser": (255, 40, 40), "snapper": (100, 255, 100), "geyser": (120, 200, 255),
        "dropper": (200, 240, 255), "eruption": (255, 90, 0)}
for k, tid in enumerate(ids):
    d = data["%s_%s" % (tid, var)]
    ox, oy = (k % cols) * W, (k // cols) * H
    pts = d["main"]
    xs = [p[0] for p in pts] + [p[0] for p in d["short"]]
    zs = [p[2] for p in pts] + [p[2] for p in d["short"]]
    minx, maxx, minz, maxz = min(xs) - 30, max(xs) + 30, min(zs) - 30, max(zs) + 30
    sc = min((W - 40) / (maxx - minx), (H - 60) / (maxz - minz))
    def tp(x, z):
        return (ox + 20 + (x - minx) * sc, oy + 40 + (z - minz) * sc)
    dr = ImageDraw.Draw(img)
    w = d["width"] / 2
    n = len(pts)
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        if a[7] and b[7]:
            continue
        quad = [tp(a[0] - a[5] * w, a[2] - a[6] * w), tp(a[0] + a[5] * w, a[2] + a[6] * w),
                tp(b[0] + b[5] * w, b[2] + b[6] * w), tp(b[0] - b[5] * w, b[2] - b[6] * w)]
        dr.polygon(quad, fill=SURF.get(a[3], (90, 90, 90)))
    for i in range(n):
        a = pts[i]
        if a[8]:
            dr.ellipse([*[c - 2 for c in tp(a[0] - a[5] * w, a[2] - a[6] * w)], *[c + 2 for c in tp(a[0] - a[5] * w, a[2] - a[6] * w)]], fill=(255, 0, 0))
        if a[9]:
            dr.ellipse([*[c - 2 for c in tp(a[0] + a[5] * w, a[2] + a[6] * w)], *[c + 2 for c in tp(a[0] + a[5] * w, a[2] + a[6] * w)]], fill=(255, 0, 0))
    # racing line
    for i in range(0, n, 2):
        a = pts[i]
        p = tp(a[0] + a[5] * a[4], a[2] + a[6] * a[4])
        dr.point(p, fill=(255, 255, 255))
    sp = d["short"]
    for i in range(len(sp) - 1):
        dr.line([tp(sp[i][0], sp[i][2]), tp(sp[i + 1][0], sp[i + 1][2])], fill=(255, 120, 40), width=max(2, int(10 * sc)))
    for f in d["feats"]:
        c = FEAT.get(f[0], (255, 255, 255))
        x, y = tp(f[1], f[2])
        dr.ellipse([x - 3, y - 3, x + 3, y + 3], fill=c)
    for s in d["shards"]:
        x, y = tp(s[0], s[2])
        dr.polygon([(x, y - 7), (x + 5, y), (x, y + 7), (x - 5, y)], fill=(255, 255, 120))
    # start + direction arrow
    x0, y0 = tp(pts[0][0], pts[0][2])
    x1, y1 = tp(pts[6][0], pts[6][2])
    dr.line([(x0, y0), (x1, y1)], fill=(255, 255, 255), width=4)
    dr.text((ox + 12, oy + 10), "%s  v%s  %.0f m" % (tid, var, d["length"]), fill=(255, 255, 255))
img.save(out)
print("saved", out)
