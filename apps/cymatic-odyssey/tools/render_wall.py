#!/usr/bin/env python3
"""Offline 'how it looks on the wall' renderer (same model as the console preview).

Water height (Faraday standing waves or dipper rings, wavelength from the real dispersion
relation) -> caustic intensity 1/|det(I + D*Hessian)| per colour channel -> gobo refracted
through the moving surface -> clipped to the insert's shape.
"""
from __future__ import annotations

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import map_coordinates, gaussian_filter

from physics_tables import wavelength_mm


def _n_waves(style):
    r = style["ratio"]
    if not r:
        return 2
    q = r[0] / r[1]
    for target, n in ((1.25, 6), (7 / 6, 6), (1.5, 3), (2.0, 3), (4 / 3, 4)):
        if abs(q - target) < 0.02:
            return n
    return 5


def _hex(c):
    return np.array([int(c[i:i + 2], 16) / 255 for i in (1, 3, 5)])


def _region_mask(region, X, Y):
    from matplotlib.path import Path
    from shapely import affinity
    c = region.centroid
    reg = affinity.translate(region, -c.x, -c.y)
    geoms = getattr(reg, "geoms", [reg])
    pts = np.vstack([np.asarray(g.exterior.coords) for g in geoms])
    s = 0.96 / np.max(np.hypot(pts[:, 0], pts[:, 1]))
    reg = affinity.scale(reg, s, s, origin=(0, 0))
    m = np.zeros(X.shape, bool)
    P = np.c_[X.ravel(), Y.ravel()]
    for g in getattr(reg, "geoms", [reg]):
        inside = Path(np.asarray(g.exterior.coords)).contains_points(P).reshape(X.shape)
        for h in g.interiors:
            inside &= ~Path(np.asarray(h.coords)).contains_points(P).reshape(X.shape)
        m |= inside
    return m


def _sources(style):
    d = style.get("dipper") or ""
    if "two pins" in d:
        return [(-0.18, 0), (0.18, 0)]
    if "three pins" in d:
        return [(0.2 * np.cos(a), 0.2 * np.sin(a)) for a in np.pi / 2 + 2 * np.pi * np.arange(3) / 3]
    if "six pins" in d:
        return [(0.25 * np.cos(a), 0.25 * np.sin(a)) for a in 2 * np.pi * np.arange(6) / 6]
    if "ring" in d:
        return [(0.3 * np.cos(a), 0.3 * np.sin(a)) for a in 2 * np.pi * np.arange(24) / 24]
    return [(0.0, 0.0)]


def height_field(style, X, Y, seed=7):
    rng = np.random.default_rng(seed)
    fw = style["f"] / 2 if style["mode"] == "faraday" else style["f"]
    lam = wavelength_mm(fw, 0.005)
    K = min(2 * np.pi / lam * 56, 160)
    A = 0.012 * 0.9 * 40 / max(K, 20)
    R = np.hypot(X, Y)
    if style["mode"] == "faraday":
        N = _n_waves(style)
        ph = rng.uniform(0, 2 * np.pi, N)
        h = np.zeros_like(X)
        for j in range(N):
            a = np.pi * j / N
            h += np.cos(K * (X * np.cos(a) + Y * np.sin(a)) + ph[j])
        h *= 1.15 / (N * K * K)   # peak curvature x D ~ 3: strong but readable caustics
    else:
        h = np.zeros_like(X)
        src = _sources(style)
        for sx, sy in src:
            r = np.hypot(X - sx, Y - sy)
            h += 0.35 * A * np.sin(K * r) / np.sqrt(r + 0.08) / np.sqrt(len(src))
        if style.get("pulse"):
            for front in (0.28, 0.58, 0.86):
                h += A * 1.2 * np.exp(-front * 1.2) * np.exp(-((R - front) * 7) ** 2) * np.cos(K * (R - front))
    h *= 1 - np.clip((R - 0.92) / 0.08, 0, 1)
    return h


def _gobo_mask(design, res):
    d = design.normalised(0.92)
    im = Image.new("L", (res, res), 0)
    dr = ImageDraw.Draw(im)
    w = max(2, int(res * 0.0065 * max(design.weight, 0.6)))
    c = res / 2
    for ln in d.lines:
        if len(ln) > 1:
            dr.line([(c + x * c, c - y * c) for x, y in ln], fill=255, width=w)
    for f in d.fills:
        for g in getattr(f, "geoms", [f]):
            dr.polygon([(c + x * c, c - y * c) for x, y in np.asarray(g.exterior.coords)], fill=255)
            for hole in g.interiors:
                dr.polygon([(c + x * c, c - y * c) for x, y in np.asarray(hole.coords)], fill=0)
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    return np.asarray(im, float) / 255.0


def render(style, gobo_design=None, insert_region=None, res=600, D=2.2, chroma=0.18):
    xs = np.linspace(-1, 1, res)
    X, Y = np.meshgrid(xs, -xs)
    dx = xs[1] - xs[0]
    h = height_field(style, X, Y)
    inside = np.ones_like(X, bool) if insert_region is None else _region_mask(insert_region, X, Y)
    soft = gaussian_filter(inside.astype(float), 2.0)
    h *= soft
    hy, hx = np.gradient(h, dx)
    hxy, hxx = np.gradient(hx, dx)
    hyy, _ = np.gradient(hy, dx)
    # gradient wrt image rows is -y: np.gradient axis0 follows rows (top->bottom = +y down)
    hy = -hy; hyy = hyy; hxy = -hxy
    mask = _gobo_mask(gobo_design, res) if gobo_design is not None else None
    col = np.zeros(X.shape + (3,))
    for c, k in zip(style["pal"], (-1, 0, 1)):
        dd = D * (1 + k * chroma)
        det = (1 + dd * hxx) * (1 + dd * hyy) - (dd * hxy) ** 2
        I = 0.15 + np.minimum(1 / np.maximum(np.abs(det), 0.05), 9)   # direct light + caustics
        if mask is not None:
            px = (X + dd * hx * 0.35 + 1) / 2 * (res - 1)
            py = (1 - (Y + dd * hy * 0.35)) / 2 * (res - 1)
            g = map_coordinates(mask, [py, px], order=1, mode="constant")
            I = I * (1 - 0.95 * g)
        col += I[..., None] * _hex(c)[None, None, :]
    col = col / 3.0
    col = col / (1 + col) * 1.35
    R = np.hypot(X, Y)
    col *= np.clip((1 - R) / 0.04, 0, 1)[..., None]
    col *= (0.06 + 0.94 * soft)[..., None]
    col = np.clip(col, 0, 1) ** 0.85
    bg = np.array([5, 6, 13]) / 255
    out = np.where((R <= 1)[..., None], col, bg)
    return Image.fromarray((out * 255).astype(np.uint8))


def render_style(style, gobo_design, path, ents=None):
    from odyssey import catalog
    e = {x["name"]: x for x in catalog.entries()}
    region = e[style["insert"]]["fn"]().region
    render(style, gobo_design, region).save(path, optimize=True)
    render(style, None, region).save(path.with_name("water_preview.png"), optimize=True)


def render_parts(style, ents, path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.collections import LineCollection
    fig, axs = plt.subplots(1, 3, figsize=(6, 2), dpi=150)
    fig.patch.set_facecolor("#05060d")
    titles = ["gobo (light stencil)", "boundary insert", "wave source"]
    for ax, t in zip(axs, titles):
        ax.set_facecolor("#05060d"); ax.set_aspect("equal"); ax.axis("off")
        ax.set_title(t, color="#9aa3c7", fontsize=7)
    g = ents[style["gobo"]]["fn"]().normalised(1)
    axs[0].add_collection(LineCollection([l for l in g.lines if len(l) > 1], colors="#ffe9b0", linewidths=0.35 * g.weight))
    for f in g.fills:
        for gg in getattr(f, "geoms", [f]):
            axs[0].fill(*gg.exterior.xy, color="#ffe9b0")
    axs[0].add_patch(plt.Circle((0, 0), 1.0, fill=False, color="#ffe9b0", lw=1.2))
    axs[0].set_xlim(-1.1, 1.1); axs[0].set_ylim(-1.1, 1.1)
    reg = ents[style["insert"]]["fn"]().normalised(1).region
    axs[1].add_patch(plt.Circle((0, 0), 1.25, color="#2a2f45"))
    for gg in getattr(reg, "geoms", [reg]):
        axs[1].fill(*gg.exterior.xy, color="#7fd4ff")
        for hh in gg.interiors:
            axs[1].fill(*hh.xy, color="#2a2f45")
    axs[1].set_xlim(-1.35, 1.35); axs[1].set_ylim(-1.35, 1.35)
    if style["dipper"]:
        dreg = ents[style["dipper"]]["fn"]().normalised(1).region
        for gg in getattr(dreg, "geoms", [dreg]):
            axs[2].fill(*gg.exterior.xy, color="#ffb347")
        axs[2].set_xlim(-1.3, 1.3); axs[2].set_ylim(-1.3, 1.3)
        axs[2].text(0, -1.25, style["dipper"], color="#ffb347", ha="center", fontsize=6)
    else:
        axs[2].text(0, 0.15, "whole dish shakes", color="#7fd4ff", ha="center", fontsize=8)
        axs[2].text(0, -0.2, "4 exciters, platform", color="#9aa3c7", ha="center", fontsize=6)
        axs[2].set_xlim(-1, 1); axs[2].set_ylim(-1, 1)
    fig.savefig(path, facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
