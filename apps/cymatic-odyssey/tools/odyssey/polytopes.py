"""Higher-dimensional polytopes drawn in their Coxeter (Petrie) planes.

* hypercubes / cross-polytopes (B_n, 2n-fold images)
* 24-cell, 600-cell, 120-cell (quaternion groups 2T, 2I)
* root polytopes of F4, E6, E7, E8 (E8 = Gosset 4_21, the famous 30-fold image)
"""
from __future__ import annotations

from itertools import combinations, permutations, product
from math import pi

import numpy as np

from .core import Design, PHI


def _petrie_bn(n):
    j = np.arange(n)
    return np.vstack([np.cos(j * pi / n), np.sin(j * pi / n)])


def _edges_min(V, tol=1e-6):
    from scipy.spatial import cKDTree
    t = cKDTree(V)
    dd, _ = t.query(V, k=2)
    m = dd[:, 1].min()
    pairs = t.query_pairs(m * (1 + tol) + 1e-9)
    return sorted(pairs)


def _draw(V, E, P, weight=None):
    X = V @ P.T
    d = Design(lines=[np.array([X[i], X[j]]) for i, j in E])
    d.weight = weight or (0.9 if len(E) < 300 else 0.6 if len(E) < 2000 else 0.4)
    return d.normalised(1.0)


def hypercube(n):
    V = np.array(list(product((-1.0, 1.0), repeat=n)))
    return _draw(V, _edges_min(V), _petrie_bn(n))


def cross_polytope(n):
    V = np.vstack([np.eye(n), -np.eye(n)])
    return _draw(V, _edges_min(V), _petrie_bn(n))


def demicube(n):
    V = np.array([v for v in product((-1.0, 1.0), repeat=n) if np.prod(v) > 0])
    return _draw(V, _edges_min(V), _petrie_bn(n))


# ---------------------------------------------------------------- quaternions
def qmul(a, b):
    a1, b1, c1, d1 = a
    a2, b2, c2, d2 = b
    return np.array([a1 * a2 - b1 * b2 - c1 * c2 - d1 * d2,
                     a1 * b2 + b1 * a2 + c1 * d2 - d1 * c2,
                     a1 * c2 - b1 * d2 + c1 * a2 + d1 * b2,
                     a1 * d2 + b1 * c2 - c1 * b2 + d1 * a2])


def _even_perms(v):
    out = []
    for p in permutations(range(4)):
        inv = sum(1 for i in range(4) for j in range(i + 1, 4) if p[i] > p[j])
        if inv % 2 == 0:
            out.append(tuple(v[i] for i in p))
    return out


def binary_icosahedral():
    V = set()
    for i in range(4):
        for s in (1, -1):
            e = [0.0] * 4; e[i] = s; V.add(tuple(e))
    for s in product((0.5, -0.5), repeat=4):
        V.add(s)
    for sg in product((1, -1), repeat=3):
        base = (sg[0] * PHI / 2, sg[1] * 0.5, sg[2] / (2 * PHI), 0.0)
        for p in _even_perms(base):
            V.add(tuple(round(x, 12) for x in p))
    V = np.array(sorted(V))
    assert len(V) == 120, len(V)
    return V


def binary_tetrahedral():
    V = [tuple(s * e for e in row) for row in np.eye(4) for s in (1, -1)]
    V += list(product((0.5, -0.5), repeat=4))
    return np.array(V, float)


def _lr_matrix(l, r):
    M = np.zeros((4, 4))
    for k in range(4):
        e = np.zeros(4); e[k] = 1
        M[:, k] = qmul(qmul(l, e), r)
    return M


def coxeter_plane_quaternion(G, h):
    """Find x -> l x r with eigen-rotation 2*pi/h; return its invariant plane (2x4)."""
    target = 2 * pi / h
    for l in G:
        for r in G:
            M = _lr_matrix(l, r)
            w, vec = np.linalg.eig(M)
            ang = np.abs(np.angle(w))
            idx = np.nonzero(np.abs(ang - target) < 1e-6)[0]
            if len(idx) == 2:
                # check the other plane rotates by an allowed exponent (not 0 / pi)
                others = [a for i, a in enumerate(ang) if i not in idx]
                if all(abs(a) > 1e-6 and abs(a - pi) > 1e-6 for a in others):
                    v = vec[:, idx[0]]
                    P = np.vstack([v.real, v.imag])
                    P[0] /= np.linalg.norm(P[0])
                    P[1] -= (P[1] @ P[0]) * P[0]
                    P[1] /= np.linalg.norm(P[1])
                    return P
    raise RuntimeError("no Coxeter element found")


def cell600(which="600"):
    G = binary_icosahedral()
    P = coxeter_plane_quaternion(G, 30)
    if which == "600":
        return _draw(G, _edges_min(G), P)
    # 120-cell: centres of the 600 tetrahedral cells
    E = _edges_min(G)
    adj = {i: set() for i in range(len(G))}
    for i, j in E:
        adj[i].add(j); adj[j].add(i)
    cells = set()
    for i in range(len(G)):
        for j in adj[i]:
            if j <= i:
                continue
            for k in adj[i] & adj[j]:
                if k <= j:
                    continue
                for l in adj[i] & adj[j] & adj[k]:
                    if l > k:
                        cells.add((i, j, k, l))
    C = np.array([G[list(c)].mean(0) for c in cells])
    assert len(C) == 600, len(C)
    return _draw(C, _edges_min(C), P, weight=0.4)


def cell24():
    G = binary_tetrahedral()
    P = coxeter_plane_quaternion(G, 12)
    return _draw(G, _edges_min(G), P)


def cell5():
    # simplex: vertices of a regular 4-simplex in R^5 (permutations of e_i), Petrie = pentagon
    V = np.eye(5)
    j = np.arange(5)
    P = np.vstack([np.cos(2 * pi * j / 5), np.sin(2 * pi * j / 5)])
    return _draw(V, _edges_min(V), P)


# ---------------------------------------------------------------- root systems
def roots_from_simple(S, limit=400):
    S = [np.asarray(s, float) for s in S]
    roots = {tuple(np.round(s, 9)) for s in S}
    frontier = list(S)
    while frontier:
        nf = []
        for r in frontier:
            for s in S:
                r2 = r - 2 * (r @ s) / (s @ s) * s
                k = tuple(np.round(r2, 9))
                if k not in roots:
                    roots.add(k); nf.append(r2)
        frontier = nf
        if len(roots) > limit:
            raise RuntimeError("root closure exploded")
    return np.array(sorted(roots))


def coxeter_plane(S, h):
    S = [np.asarray(s, float) for s in S]
    n = len(S[0])
    C = np.eye(n)
    for s in S:
        C = C @ (np.eye(n) - 2 * np.outer(s, s) / (s @ s))
    w, vec = np.linalg.eig(C)
    ang = np.angle(w)
    idx = np.argmin(np.abs(ang - 2 * pi / h))
    assert abs(ang[idx] - 2 * pi / h) < 1e-6, (ang, h)
    v = vec[:, idx]
    P = np.vstack([v.real, v.imag])
    P[0] /= np.linalg.norm(P[0])
    P[1] -= (P[1] @ P[0]) * P[0]
    P[1] /= np.linalg.norm(P[1])
    return P


E8_SIMPLE = [
    [0.5, -0.5, -0.5, -0.5, -0.5, -0.5, -0.5, 0.5],
    [1, 1, 0, 0, 0, 0, 0, 0],
    [-1, 1, 0, 0, 0, 0, 0, 0],
    [0, -1, 1, 0, 0, 0, 0, 0],
    [0, 0, -1, 1, 0, 0, 0, 0],
    [0, 0, 0, -1, 1, 0, 0, 0],
    [0, 0, 0, 0, -1, 1, 0, 0],
    [0, 0, 0, 0, 0, -1, 1, 0],
]
F4_SIMPLE = [[0, 1, -1, 0], [0, 0, 1, -1], [0, 0, 0, 1], [0.5, -0.5, -0.5, -0.5]]

ROOT_SYSTEMS = {  # name: (simple roots, Coxeter number, expected #roots)
    "E8": (E8_SIMPLE, 30, 240),
    "E7": (E8_SIMPLE[:7], 18, 126),
    "E6": (E8_SIMPLE[:6], 12, 72),
    "F4": (F4_SIMPLE, 12, 48),
}


def root_polytope(name):
    S, h, count = ROOT_SYSTEMS[name]
    R = roots_from_simple(S)
    assert len(R) == count, (name, len(R))
    P = coxeter_plane(S, h)
    return _draw(R, _edges_min(R), P)
