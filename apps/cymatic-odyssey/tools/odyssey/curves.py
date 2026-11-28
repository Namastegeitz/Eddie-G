"""Plane curves, polygons, sacred geometry, number patterns and orbital art."""
from __future__ import annotations

from math import gcd, pi

import numpy as np

from .core import Design, circle, ngon, seg, dedupe_segments, poly_region, PHI, TAU

N = 4000  # samples for smooth curves


def _closed(x, y):
    return np.c_[x, y]


# ---------------------------------------------------------------- polygons
def regular_polygon(n, nested=1):
    d = Design()
    for i in range(nested):
        d.lines.append(ngon(n, 1 - i * 0.14, rot=pi / 2 + (i % 2) * pi / n))
    d.region = poly_region(ngon(n, 1)[:-1])
    return d


def star_polygon(n, k):
    """Schlaefli star polygon {n/k}; compounds when gcd(n,k)>1."""
    g = gcd(n, k)
    v = ngon(n, 1, closed=False)
    d = Design()
    for s in range(g):
        idx = [(s + i * k) % n for i in range(n // g + 1)]
        d.lines.append(v[idx])
    d.lines.append(circle(1.0))
    rin = np.cos(pi * k / n) / np.cos(pi * (k - 1) / n)
    pts = []
    for i in range(n):
        a = pi / 2 + TAU * i / n
        pts.append((np.cos(a), np.sin(a)))
        a2 = a + pi / n
        pts.append((rin * np.cos(a2), rin * np.sin(a2)))
    d.region = poly_region(pts)
    return d


def reuleaux(n):
    v = ngon(n, 1, closed=False)
    w = np.linalg.norm(v[0] - v[n // 2])  # width = distance to opposite vertex
    pts = []
    for i in range(n):
        c = v[(i + n // 2) % n]  # arc centre: opposite vertex
        a0 = np.arctan2(*(v[i] - c)[::-1])
        a1 = np.arctan2(*(v[(i + 1) % n] - c)[::-1])
        if a1 < a0:
            a1 += TAU
        if a1 - a0 > pi:
            a1 -= TAU
        t = np.linspace(a0, a1, 120)
        pts.append(np.c_[c[0] + w * np.cos(t), c[1] + w * np.sin(t)])
    p = np.vstack(pts)
    d = Design(lines=[np.vstack([p, p[:1]])])
    d.region = poly_region(p)
    return d


# ---------------------------------------------------------------- classical curves
def rose(n, dd=1):
    k = n / dd
    period = pi * dd if (n * dd) % 2 == 1 else TAU * dd
    t = np.linspace(0, period, N)
    r = np.cos(k * t)
    d = Design(lines=[_closed(r * np.cos(t), r * np.sin(t)), circle(1.0)])
    return d


def lissajous(a, b, delta=pi / 2):
    t = np.linspace(0, TAU, N)
    return Design(lines=[_closed(np.sin(a * t + delta), np.sin(b * t))])


def hypotrochoid(R, r, dist):
    t = np.linspace(0, TAU * r / gcd(R, r), N * 2)
    x = (R - r) * np.cos(t) + dist * np.cos((R - r) / r * t)
    y = (R - r) * np.sin(t) - dist * np.sin((R - r) / r * t)
    return Design(lines=[_closed(x, y)])


def epitrochoid(R, r, dist):
    t = np.linspace(0, TAU * r / gcd(R, r), N * 2)
    x = (R + r) * np.cos(t) - dist * np.cos((R + r) / r * t)
    y = (R + r) * np.sin(t) - dist * np.sin((R + r) / r * t)
    return Design(lines=[_closed(x, y)])


def cycloid_family(kind):
    t = np.linspace(0, TAU, N)
    if kind == "cardioid":
        r = 1 - np.cos(t); x, y = r * np.cos(t), r * np.sin(t)
    elif kind == "nephroid":
        x = 3 * np.cos(t) - np.cos(3 * t); y = 3 * np.sin(t) - np.sin(3 * t)
    elif kind == "deltoid":
        x = 2 * np.cos(t) + np.cos(2 * t); y = 2 * np.sin(t) - np.sin(2 * t)
    elif kind == "astroid":
        x = np.cos(t) ** 3; y = np.sin(t) ** 3
    elif kind == "limacon":
        r = 0.5 + np.cos(t); x, y = r * np.cos(t), r * np.sin(t)
    elif kind == "lemniscate":
        s = 1 + np.sin(t) ** 2; x = np.cos(t) / s; y = np.sin(t) * np.cos(t) / s
    elif kind == "heart":
        x = 16 * np.sin(t) ** 3
        y = 13 * np.cos(t) - 5 * np.cos(2 * t) - 2 * np.cos(3 * t) - np.cos(4 * t)
    else:
        raise ValueError(kind)
    d = Design(lines=[_closed(x, y)])
    if kind in ("cardioid", "deltoid", "astroid", "heart", "nephroid"):
        d.region = poly_region(np.c_[x, y][:-1])
    return d


def envelope_cardioid(n=72):
    """Cardioid as an envelope of circles centred on a circle through a fixed point."""
    d = Design()
    p = np.array([1.0, 0.0])
    for i in range(n):
        a = TAU * i / n
        c = np.array([np.cos(a), np.sin(a)])
        d.lines.append(circle(np.linalg.norm(c - p), c, 128))
    return d


def cassini(levels=(0.6, 0.9, 1.0, 1.05, 1.2, 1.5)):
    d = Design()
    a = 1.0
    t = np.linspace(0, TAU, N)
    for b in levels:
        # r^4 - 2 a^2 r^2 cos 2t + a^4 - b^4 = 0
        c2 = np.cos(2 * t)
        disc = a ** 4 * c2 ** 2 - (a ** 4 - b ** 4)
        for sgn in (1, -1):
            r2 = a * a * c2 + sgn * np.sqrt(np.clip(disc, 0, None))
            ok = (disc >= 0) & (r2 > 0)
            r = np.sqrt(np.where(ok, r2, np.nan))
            pts = np.c_[r * np.cos(t), r * np.sin(t)]
            d.lines += _split_nan(pts)
    return d


def _split_nan(pts):
    out, cur = [], []
    for p in pts:
        if np.isnan(p).any():
            if len(cur) > 2:
                out.append(np.array(cur))
            cur = []
        else:
            cur.append(p)
    if len(cur) > 2:
        out.append(np.array(cur))
    return out


def superformula(m, n1, n2, n3, a=1, b=1, turns=1):
    t = np.linspace(0, TAU * turns, N * 2)
    r = (np.abs(np.cos(m * t / 4) / a) ** n2 + np.abs(np.sin(m * t / 4) / b) ** n3) ** (-1 / n1)
    r = r / np.max(r)
    d = Design(lines=[_closed(r * np.cos(t), r * np.sin(t))])
    if turns == 1:
        d.region = poly_region(np.c_[r * np.cos(t), r * np.sin(t)][:-1])
    return d


def superellipse(n, aspect=1.0):
    t = np.linspace(0, TAU, N)
    x = np.sign(np.cos(t)) * np.abs(np.cos(t)) ** (2 / n)
    y = aspect * np.sign(np.sin(t)) * np.abs(np.sin(t)) ** (2 / n)
    d = Design(lines=[_closed(x, y)])
    d.region = poly_region(np.c_[x, y][:-1])
    return d


def harmonograph(f1, f2, f3, f4, p=(0, pi / 2, pi / 4, 0), decay=0.004, T=200):
    t = np.linspace(0, T, 30000)
    e = np.exp(-decay * t)
    x = e * (np.sin(f1 * t + p[0]) + np.sin(f3 * t + p[2]))
    y = e * (np.sin(f2 * t + p[1]) + np.sin(f4 * t + p[3]))
    return Design(lines=[_closed(x, y)], weight=0.7)


def torus_knot(p, q):
    t = np.linspace(0, TAU, N * 2)
    r = 2 + np.cos(q * t)
    return Design(lines=[_closed(r * np.cos(p * t), r * np.sin(p * t))])


# ---------------------------------------------------------------- spirals
def golden_spiral(n=10):
    """Fibonacci squares with quarter-circle arcs (the classic golden-spiral approximation)."""
    fib = [1, 1]
    while len(fib) < n:
        fib.append(fib[-1] + fib[-2])
    minx, miny, maxx, maxy = 0.0, 0.0, 1.0, 1.0
    lines = [np.array([(0, 0), (1, 0), (1, 1), (0, 1), (0, 0)], float)]
    arcs = [((1.0, 1.0), 1.0, pi, 1.5 * pi)]
    for i, f in enumerate(fib[1:], start=1):
        k = (i - 1) % 4
        if k == 0:
            x0, y0 = maxx, miny; cen, a0 = (maxx, miny + f), 1.5 * pi; maxx += f
        elif k == 1:
            x0, y0 = minx, maxy; cen, a0 = (minx, maxy), 0.0; maxy += f
        elif k == 2:
            x0, y0 = minx - f, maxy - f; cen, a0 = (minx, maxy - f), 0.5 * pi; minx -= f
        else:
            x0, y0 = maxx - f, miny - f; cen, a0 = (maxx, miny), pi; miny -= f
        lines.append(np.array([(x0, y0), (x0 + f, y0), (x0 + f, y0 + f), (x0, y0 + f), (x0, y0)], float))
        arcs.append((cen, f, a0, a0 + pi / 2))
    for (c, r, a0, a1) in arcs:
        t = np.linspace(a0, a1, 90)
        lines.append(np.c_[c[0] + r * np.cos(t), c[1] + r * np.sin(t)])
    allp = np.vstack(lines)
    c = (allp.min(0) + allp.max(0)) / 2
    return Design(lines=[l - c for l in lines])


def log_spiral_arms(arms=8, b=0.18, turns=2.5):
    d = Design()
    t = np.linspace(-turns * TAU, 0, 1200)
    r = np.exp(b * t)
    for k in range(arms):
        a = TAU * k / arms
        for s in (1, -1):
            d.lines.append(np.c_[r * np.cos(s * t + a), r * np.sin(s * t + a)])
    return d


def archimedean_spiral(turns=10, arms=1):
    d = Design()
    t = np.linspace(0, turns * TAU, N * 2)
    r = t / t[-1]
    for k in range(arms):
        a = TAU * k / arms
        d.lines.append(np.c_[r * np.cos(t + a), r * np.sin(t + a)])
    return d


def fermat_spiral(turns=6):
    t = np.linspace(0, turns * TAU, N)
    r = np.sqrt(t / t[-1])
    return Design(lines=[np.c_[r * np.cos(t), r * np.sin(t)], np.c_[-r * np.cos(t), -r * np.sin(t)]])


def phyllotaxis(n=520, angle_deg=137.50776405, dot=0.022):
    d = Design()
    ga = np.radians(angle_deg)
    for i in range(1, n):
        r = np.sqrt(i / n)
        a = i * ga
        d.lines.append(circle(dot * (0.5 + r), (r * np.cos(a), r * np.sin(a)), 24))
    d.weight = 0.6
    return d


# ---------------------------------------------------------------- sacred / cultural geometry
def _circles(centres, r):
    return [circle(r, c, 192) for c in centres]


def hex_centres(rings, s):
    out = {(0.0, 0.0)}
    frontier = [(0.0, 0.0)]
    for _ in range(rings):
        new = []
        for (x, y) in frontier:
            for k in range(6):
                a = TAU * k / 6 + pi / 2
                p = (round(x + s * np.cos(a), 9), round(y + s * np.sin(a), 9))
                if p not in out:
                    out.add(p); new.append(p)
        frontier = new
    return sorted(out)


def seed_of_life():
    cs = [(0, 0)] + [(np.cos(a), np.sin(a)) for a in pi / 2 + TAU * np.arange(6) / 6]
    return Design(lines=_circles(cs, 1.0) + [circle(2.0)])


def flower_of_life():
    cs = hex_centres(2, 1.0)
    return Design(lines=_circles(cs, 1.0) + [circle(3.0), circle(3.08)])


def fruit_of_life():
    dirs = [(np.cos(a), np.sin(a)) for a in pi / 2 + TAU * np.arange(6) / 6]
    cs = [(0, 0)] + [(2 * x, 2 * y) for x, y in dirs] + [(4 * x, 4 * y) for x, y in dirs]
    return Design(lines=_circles(cs, 1.0)), cs


def metatrons_cube():
    d, cs = fruit_of_life()
    cs = np.array(cs, float)
    for i in range(len(cs)):
        for j in range(i + 1, len(cs)):
            d.lines.append(seg(cs[i], cs[j]))
    d.weight = 0.8
    return d


def vesica_piscis():
    return Design(lines=[circle(1, (-0.5, 0)), circle(1, (0.5, 0)),
                         seg((0, -3 ** 0.5 / 2), (0, 3 ** 0.5 / 2)), seg((-1.5, 0), (1.5, 0))])


def borromean():
    cs = [(np.cos(a) * 0.55, np.sin(a) * 0.55) for a in pi / 2 + TAU * np.arange(3) / 3]
    return Design(lines=_circles(cs, 0.9))


def torus_circles(n=24):
    return Design(lines=[circle(0.5, (0.5 * np.cos(a), 0.5 * np.sin(a)), 192)
                         for a in TAU * np.arange(n) / n], weight=0.7)


def enneagram():
    v = ngon(9, 1, closed=False)
    d = Design(lines=[circle(1.0)])
    # numbering 9 at top (index 0), going clockwise: point k at index (9-k)%9 reversed
    def P(k):
        return v[(-k) % 9]
    d.lines.append(np.array([P(3), P(6), P(9), P(3)]))
    d.lines.append(np.array([P(1), P(4), P(2), P(8), P(5), P(7), P(1)]))
    return d


def yin_yang():
    t = np.linspace(0, pi, 300)
    upper = np.c_[0.5 * np.cos(t + pi / 2) * 1, 0.5 + 0.5 * np.sin(t + pi / 2)]
    s1 = np.c_[0.5 * np.cos(np.linspace(pi / 2, 3 * pi / 2, 200)), 0.5 + 0.5 * np.sin(np.linspace(pi / 2, 3 * pi / 2, 200))]
    s2 = np.c_[0.5 * np.cos(np.linspace(pi / 2, -pi / 2, 200)), -0.5 + 0.5 * np.sin(np.linspace(pi / 2, -pi / 2, 200))]
    return Design(lines=[circle(1.0), s1, s2, circle(0.12, (0, 0.5)), circle(0.12, (0, -0.5))])


def sri_yantra_style():
    """Nine interlocking triangles (simplified proportions, not the traditional canon)."""
    d = Design(lines=[circle(1.0), circle(1.08)])
    ups = [(-0.95, 0.62), (-0.55, 0.78), (-0.25, 0.55), (0.05, 0.40)]
    downs = [(0.95, -0.70), (0.62, -0.80), (0.38, -0.60), (0.15, -0.50), (-0.12, -0.38)]
    for base, apex in ups:   # upward triangles: base y, apex y
        hw = np.sqrt(max(1 - base ** 2, 0.02))
        d.lines.append(np.array([(-hw, base), (hw, base), (0, apex), (-hw, base)]))
    for base, apex in downs:
        hw = np.sqrt(max(1 - base ** 2, 0.02))
        d.lines.append(np.array([(-hw, base), (hw, base), (0, apex), (-hw, base)]))
    d.lines.append(circle(0.03, (0, 0.02), 24))
    # lotus petals
    for ring, (n, r0, r1) in enumerate([(8, 1.08, 1.32), (16, 1.32, 1.52)]):
        for k in range(n):
            a = TAU * k / n
            a0, a1 = a - pi / n, a + pi / n
            tt = np.linspace(0, 1, 40)
            ang = a0 + (a1 - a0) * tt
            rr = r0 + (r1 - r0) * np.sin(pi * tt) ** 0.6
            d.lines.append(np.c_[rr * np.cos(ang), rr * np.sin(ang)])
    d.lines.append(circle(1.52))
    return d


def mandala(n=12, layers=5):
    """Procedural petal mandala built from rose arcs and polygon rings."""
    d = Design()
    for L in range(layers):
        r0 = 0.15 + L * 0.17
        r1 = r0 + 0.17
        k = n * (1 + L % 2)
        for i in range(k):
            a = TAU * i / k + (pi / k if L % 2 else 0)
            tt = np.linspace(-1, 1, 60)
            ang = a + tt * pi / k
            rr = r0 + (r1 - r0) * (1 - tt ** 2) ** 0.7
            d.lines.append(np.c_[rr * np.cos(ang), rr * np.sin(ang)])
        d.lines.append(circle(r0, n=256))
    d.lines.append(circle(0.15 + layers * 0.17))
    return d


# ---------------------------------------------------------------- number patterns
def mystic_rose(n):
    v = ngon(n, 1, closed=False)
    d = Design(lines=[seg(v[i], v[j]) for i in range(n) for j in range(i + 1, n)])
    d.weight = 0.6 if n > 14 else 0.9
    return d


def times_table(k, n=180):
    v = ngon(n, 1, closed=False, rot=pi)
    d = Design(lines=[seg(v[i], v[(i * k) % n]) for i in range(n) if (i * k) % n != i] + [circle(1.0)])
    d.weight = 0.5
    return d


def ford_circles(qmax=14):
    from fractions import Fraction
    d = Design()
    fr = set()
    for q in range(1, qmax + 1):
        for p in range(0, q + 1):
            if gcd(p, q) == 1:
                fr.add(Fraction(p, q))
    for f in fr:
        r = 1 / (2 * f.denominator ** 2)
        if r > 0.0012:
            d.lines.append(circle(r, (float(f) - 0.5, r - 0.25), 96))
    d.lines.append(seg((-0.5, -0.25), (0.5, -0.25)))
    d.weight = 0.6
    return d


def ulam_rays(n=1600):
    """Prime-only polar plot (Sacks-like) - primes p at radius sqrt(p), angle 2*pi*sqrt(p)."""
    sieve = np.ones(n + 1, bool); sieve[:2] = False
    for i in range(2, int(n ** 0.5) + 1):
        if sieve[i]:
            sieve[i * i::i] = False
    d = Design()
    for p in np.nonzero(sieve)[0]:
        r = np.sqrt(p) / np.sqrt(n)
        a = TAU * np.sqrt(p)
        d.lines.append(circle(0.008, (r * np.cos(a), r * np.sin(a)), 12))
    d.weight = 0.6
    return d


# ---------------------------------------------------------------- orbital art (real periods)
PLANETS = {  # sidereal period (days), semi-major axis (AU)
    "Mercury": (87.969, 0.387), "Venus": (224.701, 0.723), "Earth": (365.256, 1.0),
    "Mars": (686.980, 1.524), "Jupiter": (4332.59, 5.203), "Saturn": (10759.22, 9.537),
    "Uranus": (30688.5, 19.19), "Neptune": (60182.0, 30.07),
}


def cosmic_dance(p1, p2, years=None, lines=360):
    T1, a1 = PLANETS[p1]
    T2, a2 = PLANETS[p2]
    syn = 1 / abs(1 / T1 - 1 / T2)
    if years is None:
        years = 8 if {p1, p2} == {"Venus", "Earth"} else max(T1, T2) * 2.2 / 365.256
    t = np.linspace(0, years * 365.256, lines)
    A = np.c_[a1 * np.cos(TAU * t / T1), a1 * np.sin(TAU * t / T1)]
    B = np.c_[a2 * np.cos(TAU * t / T2), a2 * np.sin(TAU * t / T2)]
    d = Design(lines=[seg(A[i], B[i]) for i in range(lines)] + [circle(a1), circle(a2)])
    d.weight = 0.55
    return d


def geocentric(planet, years):
    Tp, ap = PLANETS[planet]
    Te, ae = PLANETS["Earth"]
    t = np.linspace(0, years * 365.256, 20000)
    x = ap * np.cos(TAU * t / Tp) - ae * np.cos(TAU * t / Te)
    y = ap * np.sin(TAU * t / Tp) - ae * np.sin(TAU * t / Te)
    return Design(lines=[np.c_[x, y], circle(0.03, n=24)])


def saturn_hexagon():
    d = Design()
    for i, r in enumerate(np.linspace(1.0, 0.25, 7)):
        p = ngon(6, r, rot=pi / 2 + i * 0.05)
        # rounded hexagon jet stream
        d.lines.append(p)
    d.lines.append(circle(1.15))
    return d


# ---------------------------------------------------------------- misc optics
def fresnel_zone_plate(n=18):
    """Alternate zones as filled rings: r_k proportional to sqrt(k)."""
    from shapely.geometry import Point
    d = Design()
    rs = np.sqrt(np.arange(n + 1) / n)
    for k in range(0, n, 2):
        ring = Point(0, 0).buffer(rs[k + 1], 128).difference(Point(0, 0).buffer(rs[k], 128)) if k else Point(0, 0).buffer(rs[1], 128)
        d.fills.append(ring)
    d.lines.append(circle(1.0))
    return d


def moire_lines(angle_deg=0.0, pitch=0.06):
    d = Design()
    a = np.radians(angle_deg)
    u = np.array([np.cos(a), np.sin(a)]); v = np.array([-u[1], u[0]])
    for k in np.arange(-1, 1 + 1e-9, pitch):
        h = np.sqrt(max(1 - k * k, 0))
        d.lines.append(np.array([k * v - h * u, k * v + h * u]))
    d.lines.append(circle(1.0))
    return d


def concentric(n=14):
    return Design(lines=[circle(r) for r in np.linspace(0.07, 1, n)])


def radial(n=36):
    d = Design(lines=[seg((0, 0), (np.cos(a), np.sin(a))) for a in TAU * np.arange(n) / n])
    d.lines.append(circle(1.0))
    return d
