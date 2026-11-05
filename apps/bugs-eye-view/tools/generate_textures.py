#!/usr/bin/env python3
"""Generates Bug's-Eye View surface textures: tileable detail maps (albedo)
and matching normal maps for wood, tiles, flagstones, grass, fabric, denim,
fur, bug shell, carpet, stone, plaster, skin, hair, leaves, metal and soil.

The albedo maps are near-white detail (grain, grout, weave, fur strands): the
material's own colour tints them, so recolouring a material still works.
Every map tiles seamlessly (all noise is made periodic with FFT filtering).

Run from the project root:  python3 tools/generate_textures.py
Then import (godot --headless --path . --import); tools/builders/res_builder.gd
wires the maps into the materials. Replace any PNG with real art of the same
name to reskin a surface.
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "textures")
rng = np.random.default_rng(11)


# --- Periodic noise ------------------------------------------------------------

def noise(n, scale, aspect=(1.0, 1.0), seed=None):
    """Tileable smooth noise in [0, 1]. `scale` ~ feature size in pixels;
    `aspect` stretches features (x, y) for grain and strands."""
    r = np.random.default_rng(seed) if seed is not None else rng
    white = r.standard_normal((n, n))
    fy = np.fft.fftfreq(n)[:, None] * aspect[1]
    fx = np.fft.fftfreq(n)[None, :] * aspect[0]
    sigma = 1.0 / max(scale, 1e-3)
    filt = np.exp(-(fx * fx + fy * fy) / (2 * sigma * sigma))
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * filt))
    out -= out.min()
    return out / max(out.max(), 1e-9)


def fbm(n, scale, octaves=4, aspect=(1.0, 1.0), gain=0.5):
    total = np.zeros((n, n))
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        total += noise(n, scale / (2 ** o), aspect) * amp
        norm += amp
        amp *= gain
    return total / norm


def normal_map(height, strength):
    """OpenGL-style (green up) normal map from a periodic height field."""
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5
    nx = -dx * strength
    ny = dy * strength
    nz = np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / length, ny / length, nz / length], axis=-1) * 0.5 + 0.5
    return rgb


def save(name, albedo, height, strength):
    os.makedirs(OUT, exist_ok=True)
    a = np.clip(albedo, 0.0, 1.0)
    if a.ndim == 2:
        a = np.stack([a, a, a], axis=-1)
    Image.fromarray((a * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(OUT, name + ".png"), optimize=True)
    # Bump detail needs less resolution than colour: big maps get a half-size
    # normal map (keeps the download small; the colour map carries the lines).
    if height.shape[0] > 256:
        f = height.shape[0] // 256
        height = height.reshape(256, f, 256, f).mean(axis=(1, 3))
        strength /= f
    nm = normal_map(height, strength)
    Image.fromarray((nm * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(OUT, name + "_n.png"), optimize=True)
    print("  %-8s %dpx  mean %.2f" % (name, a.shape[0], a.mean()))


def detail(base, amount, mean=0.93):
    """Map a 0..1 pattern to near-white detail around `mean`."""
    return mean + (base - base.mean()) * amount


# --- Surfaces -----------------------------------------------------------------

def wood(n=512):
    planks = 4
    w = n // planks
    y, x = np.mgrid[0:n, 0:n]
    grain_n = noise(n, 40, aspect=(0.08, 1.0))
    rings = np.sin((y % w) / w * 2 * np.pi * 3.0 + grain_n * 14.0) * 0.5 + 0.5
    fine = noise(n, 3, aspect=(0.15, 1.0))
    tone = np.zeros((n, n))
    seam = np.zeros((n, n))
    for p in range(planks):
        rows = slice(p * w, (p + 1) * w)
        tone[rows] = rng.uniform(-0.06, 0.06)
        # A butt joint somewhere along each plank.
        cut = int(rng.uniform(0, n))
        cols = (np.arange(n) - cut) % n
        seam[rows, :] = np.maximum(seam[rows, :], (cols < 2)[None, :] * 1.0)
    seam = np.maximum(seam, ((y % w) < 2) * 1.0)
    base = 0.55 * rings + 0.45 * fine
    alb = detail(base, 0.22) + tone - seam * 0.35
    h = base * 0.5 - seam * 1.5
    save("wood", alb, h, 3.0)


def tile(n=512):
    tiles = 4
    w = n // tiles
    y, x = np.mgrid[0:n, 0:n]
    gx = np.minimum(x % w, w - 1 - (x % w))
    gy = np.minimum(y % w, w - 1 - (y % w))
    edge = np.minimum(gx, gy)
    grout = edge < 4
    bevel = np.clip(edge / 9.0, 0.0, 1.0)
    speck = fbm(n, 6, 3)
    tone = np.zeros((n, n))
    for i in range(tiles):
        for j in range(tiles):
            tone[j * w:(j + 1) * w, i * w:(i + 1) * w] = rng.uniform(-0.035, 0.035)
    alb = detail(speck, 0.12, 0.96) + tone
    alb = np.where(grout, 0.62 + speck * 0.08, alb)
    h = np.where(grout, 0.0, 0.6 + 0.4 * bevel) + speck * 0.05
    save("tile", alb, h, 6.0)


def patio(n=512):
    # Flagstones: periodic Voronoi cells with mortar gaps.
    pts = rng.uniform(0, n, (14, 2))
    y, x = np.mgrid[0:n, 0:n].astype(float)
    d1 = np.full((n, n), 1e9)
    d2 = np.full((n, n), 1e9)
    idx = np.zeros((n, n), int)
    for k, (px, py) in enumerate(pts):
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d = np.hypot(x - px - ox, y - py - oy)
                closer = d < d1
                d2 = np.where(closer, d1, np.minimum(d2, d))
                idx = np.where(closer, k, idx)
                d1 = np.where(closer, d, d1)
    gap = (d2 - d1) < 5.0
    tones = rng.uniform(-0.13, 0.13, len(pts))
    grit = fbm(n, 10, 4)
    alb = detail(grit, 0.4, 0.9) + tones[idx]
    alb = np.where(gap, 0.45 + grit * 0.1, alb)
    h = np.where(gap, 0.0, np.clip((d2 - d1) / 14.0, 0, 1)) + grit * 0.25
    save("patio", alb, h, 5.0)


def grass(n=512):
    base = fbm(n, 30, 3)
    h = np.zeros((n, n))
    alb = detail(base, 0.5, 0.8)
    count = 6000
    for _ in range(count):
        x0, y0 = rng.uniform(0, n, 2)
        length = rng.uniform(8, 22)
        ang = rng.uniform(-0.5, 0.5) - np.pi / 2
        shade = rng.uniform(-0.25, 0.2)
        for t in np.linspace(0, 1, int(length)):
            xi = int(x0 + np.cos(ang) * length * t) % n
            yi = int(y0 + np.sin(ang) * length * t) % n
            alb[yi, xi] = 0.8 + shade * (0.5 + 0.5 * t)
            h[yi, xi] = max(h[yi, xi], 0.4 + 0.6 * t)
    save("grass", alb, h + base * 0.3, 2.5)


def fabric(n=256):
    y, x = np.mgrid[0:n, 0:n]
    period = 8
    warp = np.sin(x / period * 2 * np.pi) * 0.5 + 0.5
    weft = np.sin(y / period * 2 * np.pi) * 0.5 + 0.5
    over = ((x // period + y // period) % 2) == 0
    weave = np.where(over, warp * 0.7 + 0.3, weft * 0.7 + 0.3)
    fuzz = noise(n, 2)
    alb = detail(weave * 0.7 + fuzz * 0.3, 0.16, 0.95)
    save("fabric", alb, weave + fuzz * 0.2, 2.0)


def denim(n=256):
    y, x = np.mgrid[0:n, 0:n]
    twill = np.sin((x + y) / 6.0 * 2 * np.pi) * 0.5 + 0.5
    slub = noise(n, 18, aspect=(1.0, 0.1))
    speck = (rng.random((n, n)) > 0.985) * 0.25
    alb = detail(twill * 0.5 + slub * 0.5, 0.2, 0.92) + speck
    save("denim", alb, twill + slub * 0.4, 2.0)


def fur(n=256):
    strands = noise(n, 1.6, aspect=(1.0, 0.06))
    clumps = noise(n, 22, aspect=(1.0, 0.35))
    base = strands * 0.6 + clumps * 0.4
    alb = detail(base, 0.32, 0.93)
    save("fur", alb, base, 3.5)


def chitin(n=256):
    mottle = fbm(n, 24, 3)
    pits = noise(n, 1.5)
    ridges = np.sin(np.mgrid[0:n, 0:n][0] / n * 2 * np.pi * 9 + mottle * 6) * 0.5 + 0.5
    alb = detail(mottle * 0.7 + ridges * 0.3, 0.22, 0.94)
    save("chitin", alb, ridges * 0.5 + pits * 0.3 + mottle * 0.4, 2.5)


def carpet(n=256):
    loops = noise(n, 1.4)
    tufts = noise(n, 5)
    base = loops * 0.6 + tufts * 0.4
    alb = detail(base, 0.3, 0.92)
    save("carpet", alb, base, 3.0)


def stone(n=256):
    base = fbm(n, 14, 4)
    flecks = (noise(n, 1.2) > 0.72) * 0.18 - (noise(n, 1.3) > 0.75) * 0.22
    alb = detail(base, 0.25, 0.92) + flecks
    save("stone", alb, base * 0.6, 1.5)


def plaster(n=256):
    base = fbm(n, 20, 4)
    alb = detail(base, 0.07, 0.97)
    save("plaster", alb, base, 1.2)


def skin(n=256):
    pores = noise(n, 1.3)
    blotch = fbm(n, 30, 2)
    alb = detail(blotch * 0.7 + pores * 0.3, 0.06, 0.97)
    save("skin", alb, pores * 0.4 + blotch * 0.2, 1.0)


def hair(n=256):
    strands = noise(n, 1.2, aspect=(1.0, 0.04))
    locks = noise(n, 14, aspect=(1.0, 0.2))
    base = strands * 0.65 + locks * 0.35
    alb = detail(base, 0.4, 0.9)
    save("hair", alb, base, 3.0)


def leaf(n=256):
    y, x = np.mgrid[0:n, 0:n].astype(float)
    cell = 64
    lx = (x % cell) - cell / 2
    ly = (y % cell)
    mid = np.exp(-(lx ** 2) / 3.0)
    side = np.exp(-((np.abs(lx) * 0.8 - (ly % 16)) ** 2) / 3.0) * (np.abs(lx) < cell * 0.45)
    veins = np.clip(mid + side * 0.6, 0, 1)
    cells = noise(n, 2.5)
    alb = detail(cells, 0.14, 0.92) + veins * 0.08
    save("leaf", alb, veins * 0.6 + cells * 0.2, 2.0)


def metal(n=256):
    brushed = noise(n, 1.4, aspect=(0.03, 1.0))
    smudge = fbm(n, 40, 2)
    alb = detail(brushed * 0.6 + smudge * 0.4, 0.12, 0.95)
    save("metal", alb, brushed * 0.3, 1.0)


def soil(n=256):
    clumps = fbm(n, 10, 4)
    pebbles = (noise(n, 3) > 0.78) * 0.2
    alb = detail(clumps, 0.35, 0.88) + pebbles
    save("soil", alb, clumps + pebbles * 2.0, 3.0)


if __name__ == "__main__":
    print("Generating textures into", OUT)
    for f in (wood, tile, patio, grass, fabric, denim, fur, chitin, carpet, stone, plaster, skin, hair, leaf, metal, soil):
        f()
