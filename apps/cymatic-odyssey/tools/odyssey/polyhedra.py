"""Polyhedra: Platonic, Archimedean (Wythoff + snubs), Catalan duals, Kepler-Poinsot, compounds.

All are produced as (vertices, edges) and drawn as orthographic wireframes.
"""
from __future__ import annotations

from functools import lru_cache
from itertools import combinations
from math import pi

import numpy as np

from .core import Design, PHI, circle

# ---------------------------------------------------------------- base solids
def tetra_v():
    return np.array([(1, 1, 1), (1, -1, -1), (-1, 1, -1), (-1, -1, 1)], float)


def octa_v():
    return np.array([(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)], float)


def icosa_v():
    v = []
    for a in (1, -1):
        for b in (PHI, -PHI):
            v += [(0, a, b), (a, b, 0), (b, 0, a)]
    return np.array(v, float)


def min_edges(V, tol=1e-6):
    D = np.linalg.norm(V[:, None] - V[None], axis=2)
    np.fill_diagonal(D, np.inf)
    m = D.min()
    return [(i, j) for i, j in zip(*np.nonzero(np.abs(D - m) < tol * max(1, m) * 10)) if i < j]


def edges_at_distance_rank(V, rank):
    D = np.round(np.linalg.norm(V[:, None] - V[None], axis=2), 6)
    vals = sorted(set(D.ravel()) - {0.0})
    d = vals[rank]
    return [(i, j) for i, j in zip(*np.nonzero(D == d)) if i < j]


@lru_cache(None)
def sym_group(base):
    """All orthogonal matrices mapping the base solid's vertex set to itself."""
    V = {"tetra": tetra_v, "octa": octa_v, "icosa": icosa_v}[base]()
    V = V / np.linalg.norm(V[0])
    E = min_edges(V)
    adj = {i: set() for i in range(len(V))}
    for i, j in E:
        adj[i].add(j); adj[j].add(i)
    v0 = 0
    v1 = sorted(adj[v0])[0]
    v2 = sorted(adj[v0] & adj[v1])[0]
    S = np.c_[V[v0], V[v1], V[v2]]
    Sinv = np.linalg.inv(S)
    mats = []
    for a in range(len(V)):
        for b in adj[a]:
            for c in adj[a] & adj[b]:
                M = np.c_[V[a], V[b], V[c]] @ Sinv
                if np.allclose(M @ M.T, np.eye(3), atol=1e-8):
                    mats.append(M)
    return tuple(map(lambda m: tuple(map(tuple, m)), mats))


def group(base):
    return [np.array(m) for m in sym_group(base)]


def chamber(base):
    """Fundamental triangle (vertex, edge-midpoint, face-centre) of the base solid."""
    V = {"tetra": tetra_v, "octa": octa_v, "icosa": icosa_v}[base]()
    V = V / np.linalg.norm(V[0])
    E = min_edges(V)
    adj = {i: set() for i in range(len(V))}
    for i, j in E:
        adj[i].add(j); adj[j].add(i)
    a = 0; b = sorted(adj[a])[0]; c = sorted(adj[a] & adj[b])[0]
    A = V[a]
    M = (V[a] + V[b]) / 2
    F = (V[a] + V[b] + V[c]) / 3
    return [x / np.linalg.norm(x) for x in (A, M, F)]


def wythoff_solid(base, which):
    """which in 'A','M','F','AM','MF','AF','AMF' -> generator point in the chamber.

    For octa base: A=octahedron, F=cube, M=cuboctahedron, AM=truncated octahedron,
    MF=truncated cube, AF=rhombicuboctahedron, AMF=truncated cuboctahedron.
    """
    A, M, F = chamber(base)
    pts = {"A": A, "M": M, "F": F}
    if len(which) == 1:
        g = pts[which]
    else:
        # mirrors of the chamber: planes through pairs of corners
        corners = [A, M, F]
        normals = []
        for i in range(3):
            P, Q = corners[(i + 1) % 3], corners[(i + 2) % 3]
            n = np.cross(P, Q); n /= np.linalg.norm(n)
            if n @ corners[i] < 0:
                n = -n
            normals.append(n)  # mirror opposite corner i
        # ringed mirror = mirror opposite a corner NOT in `which`?  The generator lies on
        # the mirror opposite each corner absent from `which` (it lies on the edge between
        # the corners named in `which`).
        names = "AMF"
        rows, rhs = [], []
        active = [names[i] in which for i in range(3)]
        # active means generator is off the mirror opposite that corner
        N = np.array(normals)
        d = np.array([1.0 if act else 0.0 for act in active])
        g = np.linalg.lstsq(N, d, rcond=None)[0]
        g /= np.linalg.norm(g)
    G = group(base)
    V = np.array([m @ g for m in G])
    V = np.unique(np.round(V, 9), axis=0)
    return V


def snub(base):
    from scipy.optimize import minimize
    G = [m for m in group(base) if np.linalg.det(m) > 0]
    A, M, F = chamber(base)

    def orbit(g):
        return np.array([m @ g for m in G])

    def cost(x):
        g = x[0] * A + x[1] * M + (1 - x[0] - x[1]) * F
        g /= np.linalg.norm(g)
        O = orbit(g)
        D = np.sort(np.linalg.norm(O - g, axis=1))[1:6]
        return (D.max() - D.min()) ** 2 / D.mean() ** 2

    best = None
    for x0 in [(0.3, 0.3), (0.2, 0.5), (0.5, 0.2), (0.33, 0.2), (0.15, 0.35)]:
        r = minimize(cost, x0, method="Nelder-Mead", options={"xatol": 1e-12, "fatol": 1e-16, "maxiter": 4000})
        if best is None or r.fun < best.fun:
            best = r
    x = best.x
    g = x[0] * A + x[1] * M + (1 - x[0] - x[1]) * F
    g /= np.linalg.norm(g)
    return np.unique(np.round(orbit(g), 9), axis=0)


ARCHIMEDEAN = {
    "Truncated tetrahedron": ("tetra", "AM"),
    "Cuboctahedron": ("octa", "M"),
    "Truncated octahedron": ("octa", "AM"),
    "Truncated cube": ("octa", "MF"),
    "Rhombicuboctahedron": ("octa", "AF"),
    "Truncated cuboctahedron": ("octa", "AMF"),
    "Snub cube": ("octa", "snub"),
    "Icosidodecahedron": ("icosa", "M"),
    "Truncated icosahedron": ("icosa", "AM"),
    "Truncated dodecahedron": ("icosa", "MF"),
    "Rhombicosidodecahedron": ("icosa", "AF"),
    "Truncated icosidodecahedron": ("icosa", "AMF"),
    "Snub dodecahedron": ("icosa", "snub"),
}

CATALAN = {
    "Triakis tetrahedron": "Truncated tetrahedron",
    "Rhombic dodecahedron": "Cuboctahedron",
    "Tetrakis hexahedron": "Truncated octahedron",
    "Triakis octahedron": "Truncated cube",
    "Deltoidal icositetrahedron": "Rhombicuboctahedron",
    "Disdyakis dodecahedron": "Truncated cuboctahedron",
    "Pentagonal icositetrahedron": "Snub cube",
    "Rhombic triacontahedron": "Icosidodecahedron",
    "Pentakis dodecahedron": "Truncated icosahedron",
    "Triakis icosahedron": "Truncated dodecahedron",
    "Deltoidal hexecontahedron": "Rhombicosidodecahedron",
    "Disdyakis triacontahedron": "Truncated icosidodecahedron",
    "Pentagonal hexecontahedron": "Snub dodecahedron",
}


def platonic(name):
    if name == "Tetrahedron":
        V = tetra_v()
    elif name == "Octahedron":
        V = octa_v()
    elif name == "Cube":
        V = np.array([(x, y, z) for x in (1, -1) for y in (1, -1) for z in (1, -1)], float)
    elif name == "Icosahedron":
        V = icosa_v()
    elif name == "Dodecahedron":
        V = wythoff_solid("icosa", "F")
    return V / np.linalg.norm(V[0]), min_edges(V / np.linalg.norm(V[0]))


def archimedean(name):
    base, which = ARCHIMEDEAN[name]
    V = snub(base) if which == "snub" else wythoff_solid(base, which)
    return V, min_edges(V)


def hull_edges(V):
    """Edges of the convex hull, merging coplanar facets."""
    import trimesh
    m = trimesh.convex.convex_hull(V)
    ang = m.face_adjacency_angles
    E = m.face_adjacency_edges[ang > 1e-4]
    return np.asarray(m.vertices), [tuple(sorted(e)) for e in E]


def catalan(name):
    import trimesh
    V, _ = archimedean(CATALAN[name])
    m = trimesh.convex.convex_hull(V)
    # one dual vertex per facet (merge coplanar triangles)
    normals = []
    for fac in m.facets:
        normals.append(m.face_normals[fac[0]])
    facet_faces = set(np.concatenate(m.facets)) if len(m.facets) else set()
    for i in range(len(m.faces)):
        if i not in facet_faces:
            normals.append(m.face_normals[i])
    DV = []
    for n in normals:
        d = n @ V[np.argmax(V @ n)]
        DV.append(n / d)
    DV = np.unique(np.round(np.array(DV), 9), axis=0)
    return hull_edges(DV)


def kepler_poinsot(name):
    if name == "Small stellated dodecahedron":   # same skeleton as the great icosahedron
        V = icosa_v(); E = edges_at_distance_rank(V, 1)
    elif name == "Great stellated dodecahedron":
        V = wythoff_solid("icosa", "F"); E = edges_at_distance_rank(V, 3)
    elif name == "Great dodecahedron":           # same skeleton as the icosahedron
        V = icosa_v(); E = min_edges(V)
    else:
        raise ValueError(name)
    return V / np.linalg.norm(V[0]), E


def compound(name):
    G = group("icosa")
    Grot = [m for m in G if np.linalg.det(m) > 0]
    # in icosa_v coordinates the cube (+-1,+-1,+-1)*k is inscribed in the dodecahedron
    D = wythoff_solid("icosa", "F")
    # find 8 dodecahedron vertices forming a cube: those with |x|=|y|=|z|
    cube = D[np.isclose(np.abs(D[:, 0]), np.abs(D[:, 1])) & np.isclose(np.abs(D[:, 1]), np.abs(D[:, 2]))]
    segs = []
    if name == "Compound of five cubes":
        E = min_edges(cube); mats = Grot; base = cube
    elif name == "Compound of five tetrahedra":
        base = cube[np.prod(np.sign(cube), axis=1) > 0]; E = min_edges(base); mats = Grot
    elif name == "Compound of ten tetrahedra":
        base = cube[np.prod(np.sign(cube), axis=1) > 0]; E = min_edges(base); mats = G
    elif name == "Compound of five octahedra":
        I = wythoff_solid("icosa", "M")  # icosidodecahedron vertices
        ax = I[(np.sum(np.abs(I) > 1e-6, axis=1) == 1)]
        base = ax; E = min_edges(base); mats = Grot
    elif name == "Stella octangula":
        c = np.array([(x, y, z) for x in (1, -1) for y in (1, -1) for z in (1, -1)], float)
        t1 = c[np.prod(c, axis=1) > 0]; t2 = -t1
        V = np.vstack([t1, t2])
        return V, min_edges(t1) + [(i + 4, j + 4) for i, j in min_edges(t2)]
    elif name == "Cube and octahedron":
        c = np.array([(x, y, z) for x in (1, -1) for y in (1, -1) for z in (1, -1)], float)
        o = octa_v() * 1.5
        V = np.vstack([c, o])
        return V, min_edges(c) + [(i + 8, j + 8) for i, j in min_edges(o)]
    elif name == "Dodecahedron and icosahedron":
        d = wythoff_solid("icosa", "F"); d = d / np.linalg.norm(d[0])
        i = icosa_v()
        ed, ei = min_edges(d)[0], min_edges(i)[0]
        rd = np.linalg.norm((d[ed[0]] + d[ed[1]]) / 2)
        ri = np.linalg.norm((i[ei[0]] + i[ei[1]]) / 2)
        i = i * rd / ri  # dual pair: edges cross at their midpoints
        V = np.vstack([d, i])
        return V, min_edges(d) + [(a + len(d), b + len(d)) for a, b in min_edges(i)]
    else:
        raise ValueError(name)
    allv, alle = [], []
    seen = set()
    for m in mats:
        B = base @ m.T
        key = tuple(sorted(map(tuple, np.round(B, 6))))
        if key in seen:
            continue
        seen.add(key)
        off = len(allv)
        allv += list(B)
        alle += [(i + off, j + off) for i, j in E]
    return np.array(allv), alle


# ---------------------------------------------------------------- drawing
def view_matrix(axis, up_hint=None):
    z = np.asarray(axis, float); z /= np.linalg.norm(z)
    t = np.array([1.0, 0, 0]) if abs(z[0]) < 0.9 else np.array([0, 1.0, 0])
    x = np.cross(t, z); x /= np.linalg.norm(x)
    y = np.cross(z, x)
    return np.vstack([x, y, z])


def wire_design(V, E, axis, spin=0.0, depth_cue=False):
    R = view_matrix(axis)
    P = V @ R.T
    c, s = np.cos(spin), np.sin(spin)
    P2 = P[:, :2] @ np.array([[c, -s], [s, c]]).T
    d = Design(lines=[np.array([P2[i], P2[j]]) for i, j in E])
    d.weight = 0.9 if len(E) < 200 else 0.6
    return d.normalised(1.0)


def symmetry_axes(base):
    A, M, F = chamber(base)
    return {"vertex": A, "edge": M, "face": F}


def solid_family_base(name):
    if name in ("Tetrahedron",):
        return "tetra"
    if name in ("Cube", "Octahedron"):
        return "octa"
    if name in ("Icosahedron", "Dodecahedron"):
        return "icosa"
    if name in ARCHIMEDEAN:
        return ARCHIMEDEAN[name][0]
    if name in CATALAN:
        return ARCHIMEDEAN[CATALAN[name]][0]
    return "icosa"
