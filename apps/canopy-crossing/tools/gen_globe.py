#!/usr/bin/env python3
"""Builds content/world/globe_dots.json: land dots for the spinning globe.

Input is Natural Earth 1:110m land as TopoJSON, from the world-atlas npm
package (`npm pack world-atlas@2.0.2`, file package/land-110m.json).

    python3 tools/gen_globe.py path/to/land-110m.json content/world/globe_dots.json

Dots sit on a roughly equal-area grid (2.4 degrees of latitude apart) so the
globe looks even from every side.
"""
import json, math, sys

src, dst = sys.argv[1], sys.argv[2]
topo = json.load(open(src))
sx, sy = topo["transform"]["scale"]
tx, ty = topo["transform"]["translate"]

arcs = []
for arc in topo["arcs"]:
    x = y = 0
    pts = []
    for dx, dy in arc:
        x += dx
        y += dy
        pts.append((x * sx + tx, y * sy + ty))
    arcs.append(pts)

def ring(idx):
    out = []
    for i in idx:
        a = arcs[i] if i >= 0 else list(reversed(arcs[~i]))
        out.extend(a if not out else a[1:])
    return out

polys = []
for geom in topo["objects"]["land"]["geometries"]:
    if geom["type"] == "Polygon":
        polys.append([ring(r) for r in geom["arcs"]])
    elif geom["type"] == "MultiPolygon":
        for p in geom["arcs"]:
            polys.append([ring(r) for r in p])

def inside(lon, lat, rng):
    c = False
    n = len(rng)
    j = n - 1
    for i in range(n):
        xi, yi = rng[i]
        xj, yj = rng[j]
        if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / (yj - yi + 1e-12) + xi:
            c = not c
        j = i
    return c

bboxes = []
for p in polys:
    xs = [q[0] for q in p[0]]
    ys = [q[1] for q in p[0]]
    bboxes.append((min(xs), max(xs), min(ys), max(ys)))

dots = []
step = 2.4
lat = -84.0
while lat <= 84.0:
    n = max(1, int(round(360.0 * math.cos(math.radians(lat)) / step)))
    for k in range(n):
        lon = -180.0 + (k + 0.5) * 360.0 / n
        for p, (x0, x1, y0, y1) in zip(polys, bboxes):
            if x0 <= lon <= x1 and y0 <= lat <= y1 and inside(lon, lat, p[0]):
                if not any(inside(lon, lat, h) for h in p[1:]):
                    dots.append([round(lat, 1), round(lon, 1)])
                    break
    lat += step

json.dump({"source": "Natural Earth 1:110m land via world-atlas 2.0.2 (public domain)", "step_deg": step, "dots": dots},
          open(dst, "w"), separators=(",", ":"))
print(len(dots), "dots")
