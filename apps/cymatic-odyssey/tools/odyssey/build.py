"""Turn Designs into printable parts (binary STL via manifold3d) and SVG stencils."""
from __future__ import annotations

import struct
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import manifold3d as mf
from shapely.geometry import LineString, MultiLineString, Point, Polygon, MultiPolygon, box
from shapely.ops import unary_union
from shapely import affinity

mf.set_circular_segments(96)


@dataclass
class Spec:
    # gobo (light stencil, printed lithophane-style in white PLA/PETG)
    gobo_d: float = 110.0        # disc diameter (mm)
    gobo_rim: float = 4.0        # solid rim width
    gobo_base: float = 0.6       # translucent base thickness
    gobo_height: float = 2.4     # total height where lines are (opaque)
    line_w: float = 0.8          # nominal line width (2 x 0.4 nozzle)
    min_line_w: float = 0.45
    # boundary insert (drops into the glass dish)
    dish_id: float = 145.0       # measure your dish's inside diameter!
    insert_clear: float = 2.0
    insert_h: float = 12.0
    cavity_d: float = 112.0
    # dipper feet
    foot_size: float = 28.0
    foot_t: float = 2.0
    stem_d: float = 6.0
    stem_len: float = 45.0


# ---------------------------------------------------------------- geometry helpers
def _rings(geom):
    polys = [geom] if geom.geom_type == "Polygon" else list(getattr(geom, "geoms", []))
    out = []
    for p in polys:
        if p.geom_type != "Polygon" or p.is_empty:
            continue
        out.append(np.asarray(p.exterior.coords)[:-1])
        for h in p.interiors:
            out.append(np.asarray(h.coords)[:-1])
    return [r for r in out if len(r) >= 3]


def extrude(geom, h, z0=0.0):
    rings = _rings(geom)
    if not rings:
        return None
    cs = mf.CrossSection([r.astype(float) for r in rings], mf.FillRule.EvenOdd)
    return cs.extrude(h).translate((0, 0, z0))


def save_stl(man, path: Path):
    mesh = man.to_mesh()
    V = np.asarray(mesh.vert_properties)[:, :3].astype(np.float32)
    F = np.asarray(mesh.tri_verts)
    tri = V[F]
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    n = (n / np.where(ln == 0, 1, ln)).astype(np.float32)
    rec = np.zeros(len(F), dtype=[("n", "<f4", 3), ("v", "<f4", (3, 3)), ("a", "<u2")])
    rec["n"] = n
    rec["v"] = tri
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"CYMATIC ODYSSEY".ljust(80, b" "))
        f.write(struct.pack("<I", len(F)))
        f.write(rec.tobytes())
    return len(F)


def design_to_mm_geometry(design, radius_mm, line_w):
    d = design.normalised(radius_mm)
    w = max(line_w * design.weight, 0.45)
    parts = []
    if d.lines:
        ml = MultiLineString([ln for ln in d.lines if len(ln) > 1])
        ml = ml.simplify(0.05)
        parts.append(ml.buffer(w / 2, quad_segs=2))
    for f in d.fills:
        parts.append(f)
    g = unary_union(parts) if parts else Polygon()
    return g.simplify(0.04)


# ---------------------------------------------------------------- parts
def _raster_rings(design, R, inner, line_w, px=0.05):
    """Dense designs: draw at 0.05 mm/pixel, then trace the outline (even-odd rings)."""
    from PIL import Image, ImageDraw
    import contourpy
    from shapely.geometry import LineString
    n = int(np.ceil(2 * R / px)) + 4
    d = design.normalised(inner - 0.6)
    im = Image.new("L", (n, n), 0)
    dr = ImageDraw.Draw(im)
    c = n / 2
    wpx = max(1, int(round(max(line_w * design.weight, 0.45) / px)))
    for ln in d.lines:
        if len(ln) > 1:
            pts = [(c + x / px, c - y / px) for x, y in ln]
            dr.line(pts, fill=255, width=wpx, joint="curve")
    a = np.asarray(im, float) / 255.0
    yy, xx = np.mgrid[:n, :n]
    rr = np.hypot(xx - c, yy - c) * px
    a[rr > inner] = 0.0
    a[(rr >= inner) & (rr <= R)] = 1.0
    a[rr > R] = 0.0
    gen = contourpy.contour_generator(np.arange(n) * px - c * px, c * px - np.arange(n) * px, a)
    rings = []
    for ln in gen.lines(0.5):
        ln = np.asarray(ln)
        if len(ln) < 4:
            continue
        sl = np.asarray(LineString(ln).simplify(0.04).coords)
        if len(sl) >= 4:
            rings.append(sl[:-1] if np.allclose(sl[0], sl[-1]) else sl)
    return rings


def gobo(design, spec: Spec):
    """Returns (manifold, rings): rings are even-odd outlines of the opaque art (mm)."""
    R = spec.gobo_d / 2
    inner = R - spec.gobo_rim
    if sum(len(l) for l in design.lines) > 30000 or len(design.lines) > 2500:
        rings = _raster_rings(design, R, inner, spec.line_w)
    else:
        art = design_to_mm_geometry(design, inner - 0.6, spec.line_w)
        disc = Point(0, 0).buffer(R, 128)
        rim = disc.difference(Point(0, 0).buffer(inner, 128))
        opaque = unary_union([art.intersection(Point(0, 0).buffer(inner + 0.01, 128)), rim]).simplify(0.04)
        rings = _rings(opaque)
    base = extrude(Point(0, 0).buffer(R, 128), spec.gobo_base)
    cs = mf.CrossSection([r.astype(float) for r in rings], mf.FillRule.EvenOdd)
    top = cs.extrude(spec.gobo_height - spec.gobo_base).translate((0, 0, spec.gobo_base))
    return base + top, rings


def insert(design, spec: Spec):
    reg = design.region
    if reg is None:
        raise ValueError("design has no region")
    # centre and scale the cavity to the cavity circle
    c = reg.centroid
    reg = affinity.translate(reg, -c.x, -c.y)
    x, y = np.asarray(reg.exterior.coords).T
    s = (spec.cavity_d / 2) / np.max(np.hypot(x, y))
    reg = affinity.scale(reg, s, s, origin=(0, 0)).simplify(0.05)
    od = spec.dish_id - spec.insert_clear
    ring = Point(0, 0).buffer(od / 2, 128).difference(reg)
    man = extrude(ring, spec.insert_h)
    # water channels: 1.5 mm tall slots at the bottom
    for a in (90, 210, 330):
        slot = affinity.rotate(box(-2.0, 0, 2.0, od), a - 90, origin=(0, 0))
        cut = extrude(slot, 1.5, -0.01)
        man = man - cut
    return man, reg


def dipper(design, spec: Spec):
    reg = design.region
    c = reg.centroid
    reg = affinity.translate(reg, -c.x, -c.y)
    x, y = np.asarray(reg.exterior.coords).T if reg.geom_type == "Polygon" else np.vstack([np.asarray(g.exterior.coords) for g in reg.geoms]).T
    size = getattr(design, "size", None) or spec.foot_size
    s = (size / 2) / np.max(np.hypot(x, y))
    reg = affinity.scale(reg, s, s, origin=(0, 0))
    foot = extrude(reg, spec.foot_t)
    stem = mf.Manifold.cylinder(spec.stem_len, spec.stem_d / 2, spec.stem_d / 2).translate((0, 0, spec.foot_t - 0.01))
    # bridge from stem to every foot lobe (keeps multi-pin feet one piece)
    if len(getattr(reg, "geoms", [reg])) > 1:
        # spokes from the stem to every pin keep multi-pin feet in one piece
        spokes = unary_union([LineString([(0, 0), (g.centroid.x, g.centroid.y)]).buffer(1.6) for g in reg.geoms]
                             + [Point(0, 0).buffer(spec.stem_d)])
        hub = extrude(spokes, 2.0, spec.foot_t + 3.0)
        legs = [mf.Manifold.cylinder(3.0 + 0.02, 1.4, 1.4).translate((g.centroid.x, g.centroid.y, spec.foot_t - 0.01)) for g in reg.geoms]
        man = foot + stem + hub
        for L in legs:
            man = man + L
    else:
        man = foot + stem
    return man, reg


# ---------------------------------------------------------------- hardware (parametric)
def platform(size=200.0, t=5.0, aperture=128.0, dish_od=152.0, recess=2.0, pad_od=52.0, pad_id=50.5, pad_off=70.0):
    plate = box(-size / 2, -size / 2, size / 2, size / 2).buffer(6, join_style=1).intersection(
        box(-size / 2, -size / 2, size / 2, size / 2))
    plate = plate.difference(Point(0, 0).buffer(aperture / 2, 256))
    man = extrude(plate, t)
    man = man - extrude(Point(0, 0).buffer(dish_od / 2, 256), recess + 0.01, t - recess)
    rings = unary_union([Point(sx * pad_off, sy * pad_off).buffer(pad_od / 2 + 1.6, 128).difference(
        Point(sx * pad_off, sy * pad_off).buffer(pad_id / 2, 128)) for sx in (1, -1) for sy in (1, -1)])
    man = man + extrude(rings, 1.2, -1.2)
    # cable tie slots
    for sx, sy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        man = man - extrude(box(-2, -5, 2, 5) if sx else box(-5, -2, 5, 2), t + 1, -0.5).translate((sx * 88, sy * 88, 0))
    return man


def foot_cup(od=30.0, id_=25.5, depth=6.0, base=2.0, flange=38.0):
    cup = extrude(Point(0, 0).buffer(od / 2, 128), depth + base)
    cup = cup - extrude(Point(0, 0).buffer(id_ / 2, 128), depth + 0.01, base)
    cup = cup + extrude(Point(0, 0).buffer(flange / 2, 128), 1.6)
    return cup


def dipper_arm(length=110.0, w=10.0, h=6.0, pad_d=30.0, stem_d=6.2):
    bar = box(0, -w / 2, length, w / 2)
    pad = Point(0, 0).buffer(pad_d / 2, 128)
    boss = Point(length, 0).buffer(stem_d / 2 + 4, 96)
    shape = unary_union([bar, pad, boss])
    man = extrude(shape, h)
    man = man + extrude(Point(length, 0).buffer(stem_d / 2 + 4, 96), 14, h - 0.01)
    man = man - extrude(Point(length, 0).buffer(stem_d / 2, 96), 40, -1)
    # M3 set-screw hole through the boss
    screw = mf.Manifold.cylinder(30, 1.3, 1.3).rotate((0, 90, 0)).translate((length - 15, 0, h + 7))
    man = man - screw
    # lightening holes
    for x in np.arange(30, length - 20, 18):
        man = man - extrude(Point(x, 0).buffer(2.5, 48), h + 2, -1)
    return man


def led_cradle(sink=40.5, pocket=4.0, plate=56.0, t=8.0):
    p = box(-plate / 2, -plate / 2, plate / 2, plate / 2)
    man = extrude(p, t)
    man = man - extrude(box(-sink / 2, -sink / 2, sink / 2, sink / 2), pocket + 0.01, t - pocket)
    man = man - extrude(Point(0, 0).buffer(14, 96), t + 2, -1)       # airflow / wire hole
    man = man - extrude(box(-3, sink / 2 - 1, 3, plate / 2 + 1), t + 2, -1)  # wire slot
    for sx in (1, -1):
        for sy in (1, -1):
            man = man - extrude(Point(sx * 24, sy * 24).buffer(1.7, 32), t + 2, -1)
    return man


def mirror_holder(mirror=100.0, base_w=112.0, depth=80.0, cheek_t=8.0):
    """Base with two 45-degree cheeks; the mirror rests on the slopes against a bottom lip."""
    man = extrude(box(-base_w / 2, 0, base_w / 2, depth + 6), 4)
    tri = Polygon([(0, 0), (depth, 0), (0, depth)])
    lip = box(depth - 4, 0, depth + 6, 10)
    for x in (-base_w / 2, base_w / 2 - cheek_t):
        cheek = extrude(unary_union([tri, lip]), cheek_t).rotate((90, 0, 90)).translate((x, 0, 0))
        man = man + cheek
    return man


def gobo_carrier(od=134.0, gobo_d=110.6, aperture=102.0, h=6.0, ledge=2.0):
    ring = Point(0, 0).buffer(od / 2, 256).difference(Point(0, 0).buffer(aperture / 2, 256))
    man = extrude(ring, h)
    man = man - extrude(Point(0, 0).buffer(gobo_d / 2, 256), h - ledge + 0.01, ledge)
    # finger notches to lift the gobo out
    for a in (0, 180):
        man = man - extrude(Point(gobo_d / 2 * np.cos(np.radians(a)), gobo_d / 2 * np.sin(np.radians(a))).buffer(6, 48), h, ledge)
    return man


def lens_ring(lens_d=80.0, lip=2.5, h=10.0, rod_d=5.4, arm=16.0):
    """Holds an 80 mm projection lens (magnifier / Fresnel) on three M5 threaded rods; nuts set the focus."""
    R = lens_d / 2
    ring = Point(0, 0).buffer(R + 4, 256).difference(Point(0, 0).buffer(R - lip, 256))
    tabs = unary_union([affinity.rotate(box(R, -7, R + arm + 6, 7), a, origin=(0, 0)) for a in (90, 210, 330)])
    man = extrude(unary_union([ring, tabs]), h)
    man = man - extrude(Point(0, 0).buffer(R + 0.3, 256), h - 2 + 0.01, 2)   # seat for the lens
    for a in (90, 210, 330):
        t = np.radians(a)
        man = man - extrude(Point((R + arm) * np.cos(t), (R + arm) * np.sin(t)).buffer(rod_d / 2, 48), h + 2, -1)
    return man


def panel_corner(leg=30.0, t=4.0, hole=3.4):
    a = extrude(box(0, 0, leg, t), leg)
    b = extrude(box(0, 0, t, leg), leg)
    gus = extrude(Polygon([(t, t), (t + 12, t), (t, t + 12)]), leg)
    man = a + b + gus
    for z in (leg * 0.3, leg * 0.75):
        man = man - mf.Manifold.cylinder(t + 2, hole / 2, hole / 2).rotate((-90, 0, 0)).translate((leg * 0.65, -1, z))
        man = man - mf.Manifold.cylinder(t + 2, hole / 2, hole / 2).rotate((0, 90, 0)).translate((-1, leg * 0.65, z))
    return man


def coil_bay_base(w=130.0, d=130.0, margin=12.0, t=4.0, stop_h=8.0):
    """Base plate for the EZ-100 (measure your unit and pass w/d). Keeps it in a
    separate dry bay, raised off the bench, with a cable notch."""
    W, D = w + 2 * margin, d + 2 * margin
    man = extrude(box(-W / 2, -D / 2, W / 2, D / 2), t)
    for sx in (1, -1):
        for sy in (1, -1):
            stop = box(0, 0, 14, 3).union(box(0, 0, 3, 14))
            stop = affinity.scale(stop, sx, sy, origin=(0, 0))
            stop = affinity.translate(stop, sx * (w / 2 + 0.6) - (3 if sx < 0 else 0) * 0, sy * (d / 2 + 0.6))
            man = man + extrude(stop, stop_h, t - 0.01)
    man = man - extrude(box(-8, -D / 2 - 1, 8, -D / 2 + 8), t + 1, -0.5)
    for x in np.linspace(-W / 2 + 20, W / 2 - 20, 4):
        for y in np.linspace(-D / 2 + 20, D / 2 - 20, 4):
            man = man - extrude(Point(x, y).buffer(4, 32), t + 1, -0.5)
    return man


HARDWARE = {
    "platform_4x_exciter": (platform, "Square vibration platform: 4 x Dayton DAEX32EP-4 exciters bond to the rings underneath; 128 mm light aperture; 152 mm recess for the glass dish."),
    "platform_foot_cup": (foot_cup, "Cup for a 25 mm Sorbothane hemisphere; print 4. Lets the platform float so it can move."),
    "dipper_arm": (dipper_arm, "Offset arm: the 30 mm pad glues to a 3-4 in speaker's dust cap; the dipper stem drops through the far boss (M3 set screw)."),
    "led_cradle": (led_cradle, "Holds a 40 x 40 mm heatsink with a 20 mm star LED, pointing up at the dish."),
    "mirror_holder_45": (mirror_holder, "Holds a 100 x 100 mm first-surface mirror at 45 degrees to throw the pattern onto a wall."),
    "gobo_carrier": (gobo_carrier, "Ring that sits under the dish and holds a 110 mm gobo or printed film."),
    "lens_ring_80mm": (lens_ring, "Holds an 80 mm, ~100 mm focal-length lens on three M5 rods above the dish; it images the caustics onto the wall (focus with the nuts)."),
    "panel_corner": (panel_corner, "L-bracket for 3-5 mm acrylic enclosure panels (M3 screws). Print 8-12."),
    "coil_bay_base": (coil_bay_base, "Separate dry bay base for the EZ-100 Tesla coil (default 130 x 130 mm: measure yours)."),
}


# ---------------------------------------------------------------- SVG
def svg_from_rings(rings, path: Path, diameter: float):
    R = diameter / 2
    dstr = " ".join("M " + " L ".join(f"{x + R:.3f},{R - y:.3f}" for x, y in r) + " Z" for r in rings)
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{diameter}mm" height="{diameter}mm" '
           f'viewBox="0 0 {diameter} {diameter}"><path fill="#000" fill-rule="evenodd" d="{dstr}"/></svg>')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(svg)
