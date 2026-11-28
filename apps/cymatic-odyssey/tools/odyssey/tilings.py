"""Planar & hyperbolic tilings: Wythoff construction, de Bruijn multigrids, Hankin star patterns."""
from __future__ import annotations

from math import pi

import numpy as np
from shapely.geometry import LineString, MultiLineString, Point
from shapely.ops import polygonize, unary_union

from .core import Design, circle, seg, dedupe_segments, TAU


# ---------------------------------------------------------------- Euclidean Wythoff
def _reflect_affine(n, c):
    """Reflection across line n.x = c (|n|=1) as (M, t): x -> M x + t."""
    n = np.asarray(n, float)
    M = np.eye(2) - 2 * np.outer(n, n)
    t = 2 * c * n
    return M, t


def wythoff_planar(p, q, r, rings, radius=5.0):
    """Uniform tiling from triangle (pi/p, pi/q, pi/r) with ringed mirrors.

    rings: tuple of 3 booleans for mirrors opposite vertices A, B, C.
    Returns list of edge segments.
    """
    A = np.array([0.0, 0.0])
    angA, angB = pi / p, pi / q
    angC = pi - angA - angB
    B = np.array([1.0, 0.0])
    # law of sines: AC = sin(B)/sin(C) * AB
    AC = np.sin(angB) / np.sin(angC)
    C = AC * np.array([np.cos(angA), np.sin(angA)])
    verts = [A, B, C]
    mirrors = []
    for i in range(3):  # mirror opposite vertex i: through the other two
        P, Q = verts[(i + 1) % 3], verts[(i + 2) % 3]
        d = Q - P
        n = np.array([-d[1], d[0]]) / np.linalg.norm(d)
        c = n @ P
        if n @ verts[i] - c < 0:
            n, c = -n, -c
        mirrors.append((n, c))
    # generator: n_i . x - c_i = s_i * h, s_i = 1 if ringed else 0 ; inside => positive
    Mx = np.array([[m[0][0], m[0][1], -float(rg)] for m, rg in zip(mirrors, rings)])
    bvec = np.array([m[1] for m in mirrors])
    sol = np.linalg.solve(Mx, bvec)
    g = sol[:2]
    base = []
    for (n, c), rg in zip(mirrors, rings):
        if rg:
            M, t = _reflect_affine(n, c)
            base.append(np.array([g, M @ g + t]))
    gens = [_reflect_affine(n, c) for n, c in mirrors]
    cen = (A + B + C) / 3
    seen = {tuple(np.round(cen, 6))}
    frontier = [(np.eye(2), np.zeros(2))]
    elems = list(frontier)
    while frontier:
        nf = []
        for M, t in frontier:
            for G, u in gens:
                M2, t2 = M @ G, M @ u + t
                cc = M2 @ cen + t2
                key = tuple(np.round(cc, 6))
                if key in seen or np.linalg.norm(cc) > radius + 1:
                    continue
                seen.add(key)
                nf.append((M2, t2)); elems.append((M2, t2))
        frontier = nf
    segs = []
    for M, t in elems:
        for s in base:
            segs.append(s @ M.T + t)
    segs = dedupe_segments(segs, 5)
    return [s for s in segs if np.linalg.norm(s.mean(0)) < radius]


def tiling_faces(segs):
    import shapely
    ml = shapely.set_precision(MultiLineString([LineString(np.round(s, 5)) for s in segs]), 1e-5)
    return list(polygonize(unary_union(ml)))


def hankin(faces, contact_deg=60.0, gap=0.0):
    """Islamic star pattern by Hankin's polygons-in-contact method (Kaplan 2005)."""
    th = np.radians(contact_deg)
    out = []
    for f in faces:
        pts = np.asarray(f.exterior.coords)[:-1]
        if f.exterior.is_ccw is False:
            pts = pts[::-1]
        n = len(pts)
        rays = []
        for i in range(n):
            a, b = pts[i], pts[(i + 1) % n]
            m = (a + b) / 2
            e = (b - a) / np.linalg.norm(b - a)
            inward = np.array([-e[1], e[0]])  # CCW polygon: left is inside
            # two rays from the midpoint, leaning toward each end
            r_fwd = np.cos(th) * e + np.sin(th) * inward
            r_back = -np.cos(th) * e + np.sin(th) * inward
            rays.append((m, r_back, r_fwd))
        for i in range(n):
            m1, _, f1 = rays[i]
            m2, b2, _ = rays[(i + 1) % n]
            # intersect m1 + s f1 with m2 + u b2
            Mx = np.c_[f1, -b2]
            if abs(np.linalg.det(Mx)) < 1e-9:
                # parallel rays: when they are the same line, the motif is the segment m1-m2
                if abs(f1[0] * (m2 - m1)[1] - f1[1] * (m2 - m1)[0]) < 1e-7:
                    out.append(np.array([m1, m2]))
                continue
            s, u = np.linalg.solve(Mx, m2 - m1)
            if s <= 0 or u <= 0:
                continue
            X = m1 + s * f1
            if not f.buffer(1e-6).contains(Point(X)):
                continue
            out.append(np.array([m1, X]))
            out.append(np.array([X, m2]))
    return out


def archimedean_tiling(name, radius=5.0):
    table = {
        "4.4.4.4": (4, 4, 2, (True, False, False)),
        "3.3.3.3.3.3": (6, 3, 2, (True, False, False)),
        "6.6.6": (6, 3, 2, (False, True, False)),
        "3.6.3.6": (6, 3, 2, (False, False, True)),
        "3.12.12": (6, 3, 2, (False, True, True)),
        "3.4.6.4": (6, 3, 2, (True, True, False)),
        "4.6.12": (6, 3, 2, (True, True, True)),
        "4.8.8": (4, 4, 2, (True, False, True)),
    }
    p, q, r, rings = table[name]
    return wythoff_planar(p, q, r, rings, radius)


def clip_to_disc(segs, R):
    disc = Point(0, 0).buffer(R, 256)
    out = []
    for s in segs:
        g = LineString(s).intersection(disc)
        if g.is_empty:
            continue
        geoms = getattr(g, "geoms", [g])
        for gg in geoms:
            if gg.geom_type == "LineString" and gg.length > 0:
                out.append(np.asarray(gg.coords))
    return out


def tiling_design(name, radius=4.0, hankin_deg=None):
    segs = archimedean_tiling(name, radius + 2)
    if hankin_deg is not None:
        faces = [f for f in tiling_faces(segs) if f.centroid.distance(Point(0, 0)) < radius + 1]
        segs = hankin(faces, hankin_deg)
    d = Design(lines=clip_to_disc(segs, radius) + [circle(radius)])
    d.weight = 0.8
    return d


# ---------------------------------------------------------------- de Bruijn multigrid (Penrose etc.)
def multigrid(n, K=7, radius=6.0, seed=3):
    rng = np.random.default_rng(seed)
    gam = rng.uniform(0.05, 0.95, n)
    if n == 5:
        gam = gam - gam.mean() + 0.2  # sum = 1 -> Penrose rhombus (P3) tiling
        gam[-1] = 1.0 - gam[:-1].sum()
    E = np.c_[np.cos(TAU * np.arange(n) / n), np.sin(TAU * np.arange(n) / n)]
    faces = []
    for r in range(n):
        for s in range(r + 1, n):
            Mx = np.vstack([E[r], E[s]])
            if abs(np.linalg.det(Mx)) < 1e-9:
                continue
            Minv = np.linalg.inv(Mx)
            for kr in range(-K, K + 1):
                for ks in range(-K, K + 1):
                    x = Minv @ np.array([kr - gam[r], ks - gam[s]])
                    kk = np.ceil(E @ x + gam)
                    kk[r], kk[s] = kr, ks
                    base = kk @ E
                    quad = np.array([base, base + E[r], base + E[r] + E[s], base + E[s]])
                    faces.append(quad)
    faces = [f for f in faces if np.linalg.norm(f.mean(0)) < radius]
    return faces


def multigrid_design(n, radius=5.5, hankin_deg=None):
    from shapely.geometry import Polygon
    faces = multigrid(n, K=int(radius * 1.3) + 2, radius=radius + 2)
    if hankin_deg is not None:
        polys = [Polygon(f) for f in faces]
        segs = hankin(polys, hankin_deg)
    else:
        segs = []
        for f in faces:
            for i in range(4):
                segs.append(np.array([f[i], f[(i + 1) % 4]]))
        segs = dedupe_segments(segs, 5)
    d = Design(lines=clip_to_disc(segs, radius) + [circle(radius)])
    d.weight = 0.75
    return d


# ---------------------------------------------------------------- hyperbolic {p,q} in the Poincare disc
def hyperbolic_tiling(p, q, max_edges=12000, min_len=0.006, dual=False):
    assert 1 / p + 1 / q < 0.5
    d = np.cos(pi / q) / np.sqrt(np.cos(pi / q) ** 2 - np.sin(pi / p) ** 2)
    r = np.sqrt(d * d - 1)
    cc = complex(d, 0)
    u = np.exp(1j * pi / p)

    def refl_x(z):
        return np.conj(z)

    def refl_u(z):
        return u * u * np.conj(z)

    def inv(z):
        return cc + r * r / np.conj(z - cc)

    # vertex V: intersection of circle with ray at angle pi/p
    # |t u - cc| = r  -> t^2 - 2 t d cos(pi/p) + d^2 - r^2 = 0
    cp = np.cos(pi / p)
    t = d * cp - np.sqrt(d * d * cp * cp - (d * d - r * r))
    V = t * u
    if not dual:
        a0, a1 = np.angle(V - cc), np.angle(np.conj(V) - cc)
        if a1 - a0 > pi:
            a1 -= TAU
        elif a0 - a1 > pi:
            a1 += TAU
        ang = np.linspace(a0, a1, 32)
        base = cc + r * np.exp(1j * ang)
    else:
        base = np.linspace(0, 1 / d, 32).astype(complex)
    gens = (refl_x, refl_u, inv)
    def key(e):
        a = (round(e[0].real, 5), round(e[0].imag, 5))
        b = (round(e[-1].real, 5), round(e[-1].imag, 5))
        return (a, b) if a <= b else (b, a)
    seen = {key(base)}
    edges = [base]
    frontier = [base]
    while frontier and len(edges) < max_edges:
        nf = []
        for e in frontier:
            for g in gens:
                e2 = g(e)
                k = key(e2)
                if k in seen:
                    continue
                seen.add(k)
                if abs(e2[0] - e2[-1]) < min_len:
                    continue
                edges.append(e2); nf.append(e2)
        frontier = nf
    D = Design(lines=[np.c_[e.real, e.imag] for e in edges] + [circle(1.0, n=512)])
    D.weight = 0.6
    return D
