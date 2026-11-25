"""Fractals and space-filling curves."""
from __future__ import annotations

from math import pi

import numpy as np

from .core import Design, circle, ngon, seg, poly_region, TAU


def lsystem(axiom, rules, n, angle_deg, start_deg=0.0):
    s = axiom
    for _ in range(n):
        s = "".join(rules.get(c, c) for c in s)
    a = np.radians(start_deg)
    da = np.radians(angle_deg)
    p = np.zeros(2)
    pts = [p.copy()]
    lines = []
    stack = []
    for c in s:
        if c in "FGAB":
            p = p + np.array([np.cos(a), np.sin(a)])
            pts.append(p.copy())
        elif c == "f":
            lines.append(np.array(pts)); p = p + np.array([np.cos(a), np.sin(a)]); pts = [p.copy()]
        elif c == "+":
            a += da
        elif c == "-":
            a -= da
        elif c == "[":
            stack.append((p.copy(), a))
        elif c == "]":
            lines.append(np.array(pts)); p, a = stack.pop(); pts = [p.copy()]
    lines.append(np.array(pts))
    return [l for l in lines if len(l) > 1]


def koch_snowflake(level=4):
    ls = lsystem("F--F--F", {"F": "F+F--F+F"}, level, 60)
    d = Design(lines=ls)
    d.region = poly_region(ls[0][:-1])
    return d.centred()


def koch_antisnowflake(level=4):
    ls = lsystem("F++F++F", {"F": "F+F--F+F"}, level, 60)
    return Design(lines=ls).centred()


def hilbert(order=5):
    return Design(lines=lsystem("A", {"A": "+BF-AFA-FB+", "B": "-AF+BFB+FA-"}, order, 90), weight=0.8).centred()


def moore(order=4):
    return Design(lines=lsystem("LFL+F+LFL", {"L": "-RF+LFL+FR-", "R": "+LF-RFR-FL+"}, order, 90), weight=0.8).centred()


def dragon(order=12):
    return Design(lines=lsystem("FX", {"X": "X+YF+", "Y": "-FX-Y"}, order, 90), weight=0.7).centred()


def levy_c(order=10):
    return Design(lines=lsystem("F", {"F": "+F--F+"}, order, 45), weight=0.7).centred()


def gosper(order=4):
    return Design(lines=lsystem("A", {"A": "A-B--B+A++AA+B-", "B": "+A-BB--B-A++A+B"}, order, 60), weight=0.7).centred()


def sierpinski_arrowhead(order=6):
    return Design(lines=lsystem("A", {"A": "B-A-B", "B": "A+B+A"}, order, 60), weight=0.8).centred()


def peano(order=3):
    return Design(lines=lsystem("X", {"X": "XFYFX+F+YFXFY-F-XFYFX", "Y": "YFXFY-F-XFYFX+F+YFXFY"}, order, 90), weight=0.8).centred()


def fractal_plant(order=5):
    return Design(lines=lsystem("X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, order, 25, start_deg=90), weight=0.7).centred()


def sierpinski_triangle(level=6):
    tris = [np.array([(0, 0), (1, 0), (0.5, 3 ** 0.5 / 2)])]
    for _ in range(level):
        nt = []
        for t in tris:
            a, b, c = t
            ab, bc, ca = (a + b) / 2, (b + c) / 2, (c + a) / 2
            nt += [np.array([a, ab, ca]), np.array([ab, b, bc]), np.array([ca, bc, c])]
        tris = nt
    return Design(lines=[np.vstack([t, t[:1]]) for t in tris], weight=0.7).centred()


def sierpinski_carpet(level=4):
    sq = []

    def rec(x, y, s, L):
        if L == 0:
            return
        s3 = s / 3
        sq.append((x + s3, y + s3, s3))
        for i in range(3):
            for j in range(3):
                if (i, j) != (1, 1):
                    rec(x + i * s3, y + j * s3, s3, L - 1)
    rec(0, 0, 1, level)
    d = Design(lines=[np.array([(0, 0), (1, 0), (1, 1), (0, 1), (0, 0)], float)])
    for x, y, s in sq:
        d.lines.append(np.array([(x, y), (x + s, y), (x + s, y + s), (x, y + s), (x, y)]))
    d.weight = 0.7
    return d.centred()


def vicsek(level=4):
    sq = []

    def rec(x, y, s, L):
        if L == 0:
            sq.append((x, y, s)); return
        s3 = s / 3
        for i, j in [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)]:
            rec(x + i * s3, y + j * s3, s3, L - 1)
    rec(0, 0, 1, level)
    return Design(lines=[np.array([(x, y), (x + s, y), (x + s, y + s), (x, y + s), (x, y)]) for x, y, s in sq], weight=0.7).centred()


def h_tree(level=9):
    lines = []

    def rec(x, y, L, horiz, n):
        if n == 0:
            return
        if horiz:
            a, b = (x - L / 2, y), (x + L / 2, y)
        else:
            a, b = (x, y - L / 2), (x, y + L / 2)
        lines.append(seg(a, b))
        for p in (a, b):
            rec(p[0], p[1], L / 2 ** 0.5, not horiz, n - 1)
    rec(0, 0, 1, True, level)
    return Design(lines=lines, weight=0.8)


def pythagoras_tree(level=9, angle=45):
    lines = []
    th = np.radians(angle)

    def rec(p0, p1, n):
        v = p1 - p0
        w = np.array([-v[1], v[0]])
        p2, p3 = p1 + w, p0 + w
        lines.append(np.array([p0, p1, p2, p3, p0]))
        if n == 0:
            return
        # apex of right triangle on top edge p3->p2
        e = p2 - p3
        L = np.linalg.norm(e)
        u = e / L
        nrm = np.array([-u[1], u[0]])
        apex = p3 + u * (L * np.cos(th) ** 2) + nrm * (L * np.cos(th) * np.sin(th))
        rec(p3, apex, n - 1)
        rec(apex, p2, n - 1)
    rec(np.array([0.0, 0.0]), np.array([1.0, 0.0]), level)
    return Design(lines=lines, weight=0.7).centred()


def apollonian(depth=6, min_r=0.006):
    """Apollonian gasket via Descartes' complex theorem."""
    out = []
    # start: outer circle curvature -1 radius 1, three equal inner circles
    k_in = 1 + 2 / 3 ** 0.5   # curvature of the 3 inner circles when outer radius 1
    r_in = 1 / k_in
    d0 = 1 - r_in
    circles = [(-1.0, 0j)]
    for a in pi / 2 + TAU * np.arange(3) / 3:
        circles.append((k_in, d0 * np.exp(1j * a)))
    for k, z in circles:
        out.append((abs(1 / k), z))

    def solve(c1, c2, c3, avoid):
        (k1, z1), (k2, z2), (k3, z3) = c1, c2, c3
        k4 = k1 + k2 + k3 + 2 * np.sqrt(abs(k1 * k2 + k2 * k3 + k3 * k1))
        kz = k1 * z1 + k2 * z2 + k3 * z3
        root = 2 * np.sqrt(k1 * k2 * z1 * z2 + k2 * k3 * z2 * z3 + k1 * k3 * z1 * z3)
        cands = [(kz + root) / k4, (kz - root) / k4]
        best = None
        for z4 in cands:
            if avoid is not None and abs(z4 - avoid[1]) < 1e-7 and abs(k4 - avoid[0]) < 1e-6:
                continue
            ok = all(abs(abs(z4 - z) - ((1 / k4 + 1 / k) if k > 0 else (1 / abs(k) - 1 / k4))) < 1e-6 for k, z in (c1, c2, c3))
            if ok:
                best = z4
        return (k4, best) if best is not None else None

    import collections
    q = collections.deque()
    o, a, b, c = circles
    q += [((o, a, b), c), ((o, b, c), a), ((o, c, a), b), ((a, b, c), o)]
    # centre circle
    while q:
        (c1, c2, c3), avoid = q.popleft()
        res = solve(c1, c2, c3, avoid)
        if res is None:
            continue
        k4, z4 = res
        r4 = 1 / k4
        if r4 < min_r:
            continue
        out.append((r4, z4))
        c4 = (k4, z4)
        q += [((c1, c2, c4), c3), ((c2, c3, c4), c1), ((c1, c3, c4), c2)]
        if len(out) > 4000:
            break
    return Design(lines=[circle(r, (z.real, z.imag), max(24, int(400 * r))) for r, z in out], weight=0.6)


def escape_field(c=None, mandel=False, res=700, it=80, span=1.6, center=(0, 0)):
    xs = np.linspace(center[0] - span, center[0] + span, res)
    ys = np.linspace(center[1] - span, center[1] + span, res)
    X, Y = np.meshgrid(xs, ys)
    Z = X + 1j * Y
    C = Z.copy() if mandel else np.full_like(Z, c)
    if mandel:
        Z = np.zeros_like(Z)
    nu = np.zeros(Z.shape)
    alive = np.ones(Z.shape, bool)
    for i in range(it):
        Z[alive] = Z[alive] ** 2 + C[alive]
        esc = alive & (np.abs(Z) > 4)
        nu[esc] = i + 1 - np.log2(np.log(np.abs(Z[esc])))
        alive &= ~esc
    nu[alive] = it
    return xs, ys, nu


def contour_design(xs, ys, F, levels, weight=0.7):
    import contourpy
    gen = contourpy.contour_generator(xs, ys, F)
    d = Design(weight=weight)
    for lv in levels:
        for ln in gen.lines(lv):
            if len(ln) > 4:
                d.lines.append(np.asarray(ln))
    return d


def julia(c, levels=(4, 6, 9, 14, 22)):
    xs, ys, nu = escape_field(c=c)
    return contour_design(xs, ys, nu, levels).centred()


def mandelbrot(levels=(3, 5, 7, 10, 16, 30)):
    xs, ys, nu = escape_field(mandel=True, center=(-0.6, 0), span=1.5, res=800)
    return contour_design(xs, ys, nu, levels).centred()
