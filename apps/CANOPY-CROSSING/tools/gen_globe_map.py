#!/usr/bin/env python3
"""Builds assets/world/globe_map.png, the texture the digital globe shader
reads (equirectangular, 2048 x 1024, longitude -180..180 left to right,
latitude 90..-90 top to bottom):

  R  land (anti-aliased mask)
  G  coastline glow (a soft band either side of every coast)
  B  country borders (thin lines, inland only)

Input is Natural Earth 1:50m as TopoJSON from the world-atlas npm package
(public domain): `npm pack world-atlas@2.0.2`, files package/land-50m.json
and package/countries-50m.json.

    python3 tools/gen_globe_map.py land-50m.json countries-50m.json assets/world/globe_map.png
"""
import json
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

W, H = 2048, 1024
SS = 2  # draw at 2x and scale down for smooth edges


def decode(topo):
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
    return arcs


def ring(arcs, idx):
    out = []
    for i in idx:
        a = arcs[i] if i >= 0 else list(reversed(arcs[~i]))
        out.extend(a if not out else a[1:])
    return out


def polygons(topo, name):
    arcs = decode(topo)
    polys = []
    for geom in topo["objects"][name]["geometries"]:
        if geom["type"] == "Polygon":
            polys.append([ring(arcs, r) for r in geom["arcs"]])
        elif geom["type"] == "MultiPolygon":
            for p in geom["arcs"]:
                polys.append([ring(arcs, r) for r in p])
    return polys


def unwrap(r):
    """Makes a ring's longitudes continuous where it crosses the 180 degree
    line (Chukotka, Fiji), so it can be drawn shifted by +-360 too. Jumps
    along the poles (Antarctica's closing edge) are left alone."""
    out = [r[0]]
    for lon, lat in r[1:]:
        plon, plat = out[-1]
        if abs(lat) < 89.5 and abs(plat) < 89.5:
            while lon - plon > 180.0:
                lon -= 360.0
            while lon - plon < -180.0:
                lon += 360.0
        out.append((lon, lat))
    return out


def draw_ring(d, r, fill):
    u = unwrap(r)
    for shift in (-360.0, 0.0, 360.0):
        d.polygon([px(lon + shift, lat) for lon, lat in u], fill=fill)


def px(lon, lat):
    return ((lon + 180.0) / 360.0 * W * SS, (90.0 - lat) / 180.0 * H * SS)


def main():
    land_src, countries_src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
    land = polygons(json.load(open(land_src)), "land")
    countries = polygons(json.load(open(countries_src)), "countries")

    mask = Image.new("L", (W * SS, H * SS), 0)
    d = ImageDraw.Draw(mask)
    for poly in land:
        draw_ring(d, poly[0], 255)
    for poly in land:
        for hole in poly[1:]:
            draw_ring(d, hole, 0)

    borders = Image.new("L", (W * SS, H * SS), 0)
    b = ImageDraw.Draw(borders)
    for poly in countries:
        for r in poly:
            pts = [px(*p) for p in r]
            # skip segments that jump across the map (antimeridian cuts)
            for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
                if abs(x1 - x0) < W * SS * 0.5:
                    b.line([(x0, y0), (x1, y1)], fill=255, width=2)

    mask = mask.resize((W, H), Image.LANCZOS)
    borders = borders.resize((W, H), Image.LANCZOS)
    # borders only well inside the land, so coasts are drawn by the glow alone
    inland = mask.filter(ImageFilter.MinFilter(5))
    borders = ImageChops.multiply(borders, inland)
    # coastline glow: the mask's edge, softened
    edge = ImageChops.subtract(mask.filter(ImageFilter.MaxFilter(3)), mask.filter(ImageFilter.MinFilter(3)))
    glow = edge.filter(ImageFilter.GaussianBlur(1.6))
    peak = max(glow.getextrema()[1], 1)
    glow = glow.point(lambda v: min(255, int(v * 255 / peak * 1.3)))

    Image.merge("RGB", (mask, glow, borders)).save(dst, optimize=True)
    print("wrote", dst, W, "x", H)


if __name__ == "__main__":
    main()
