"""Shared types and helpers."""
from __future__ import annotations

from dataclasses import dataclass, field
from math import gcd, pi

import numpy as np
from shapely.geometry import Polygon, MultiPolygon
from shapely.ops import unary_union

PHI = (1 + 5 ** 0.5) / 2
TAU = 2 * pi


@dataclass
class Design:
    """Linework + optional filled areas, in arbitrary units (normalised later)."""
    lines: list = field(default_factory=list)      # list of (N,2) arrays
    fills: list = field(default_factory=list)      # list of shapely polygons
    weight: float = 1.0                             # line-width multiplier
    region: object = None                           # shapely polygon: boundary for inserts/dippers

    def extend(self, other: "Design"):
        self.lines += other.lines
        self.fills += other.fills
        return self

    # --- normalisation -------------------------------------------------
    def radius(self) -> float:
        r = 0.0
        for ln in self.lines:
            if len(ln):
                r = max(r, float(np.max(np.hypot(ln[:, 0], ln[:, 1]))))
        for f in self.fills:
            if not f.is_empty:
                x, y = np.asarray(f.convex_hull.exterior.coords).T if f.geom_type == "Polygon" else np.asarray(f.convex_hull.exterior.coords).T
                r = max(r, float(np.max(np.hypot(x, y))))
        if self.region is not None:
            x, y = _ext(self.region).T
            r = max(r, float(np.max(np.hypot(x, y))))
        return r or 1.0

    def centred(self) -> "Design":
        """Shift so the bounding-box centre sits at the origin."""
        pts = [ln for ln in self.lines if len(ln)]
        if self.region is not None:
            pts.append(_ext(self.region))
        if not pts:
            return self
        allp = np.vstack(pts)
        c = (allp.min(0) + allp.max(0)) / 2
        return self.transformed(np.eye(2), -c)

    def transformed(self, M, t=(0, 0)) -> "Design":
        from shapely import affinity
        M = np.asarray(M, float)
        t = np.asarray(t, float)
        d = Design(weight=self.weight)
        d.lines = [ln @ M.T + t for ln in self.lines]
        mat = [M[0, 0], M[0, 1], M[1, 0], M[1, 1], t[0], t[1]]
        d.fills = [affinity.affine_transform(f, mat) for f in self.fills]
        d.region = affinity.affine_transform(self.region, mat) if self.region is not None else None
        return d

    def normalised(self, r=1.0) -> "Design":
        s = r / self.radius()
        return self.transformed(np.eye(2) * s)


def _ext(geom):
    return np.vstack([np.asarray(g.exterior.coords) for g in getattr(geom, "geoms", [geom])])


def circle(r=1.0, c=(0.0, 0.0), n=256):
    t = np.linspace(0, TAU, n + 1)
    return np.c_[c[0] + r * np.cos(t), c[1] + r * np.sin(t)]


def ngon(n, r=1.0, rot=pi / 2, c=(0.0, 0.0), closed=True):
    t = rot + TAU * np.arange(n + (1 if closed else 0)) / n
    return np.c_[c[0] + r * np.cos(t), c[1] + r * np.sin(t)]


def seg(a, b):
    return np.array([a, b], float)


def dedupe_segments(segs, nd=6):
    """Remove duplicate undirected segments."""
    seen = {}
    for s in segs:
        a = tuple(np.round(s[0], nd))
        b = tuple(np.round(s[-1], nd))
        k = (a, b) if a <= b else (b, a)
        if k not in seen and a != b:
            seen[k] = np.asarray(s, float)
    return list(seen.values())


def poly_region(pts):
    p = Polygon(pts)
    if not p.is_valid:
        p = p.buffer(0)
    if isinstance(p, MultiPolygon):
        p = max(p.geoms, key=lambda g: g.area)
    return p


def rot2(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s], [s, c]])


__all__ = ["Design", "circle", "ngon", "seg", "dedupe_segments", "poly_region",
           "rot2", "PHI", "TAU", "gcd", "unary_union"]
