#!/usr/bin/env python3
"""Pattern recognition for cymatic light: what symmetry is on the wall right now?

Works on any grayscale image (camera frame of the wall or of the dish).
Method:
  1. Window + 2D FFT; the bright spots in |FFT| are the wave vectors of the pattern.
  2. Radial profile of |FFT| -> dominant wavelength (pixels; mm if calibrated).
  3. Angular profile of |FFT| on that ring -> its Fourier harmonics. The strongest
     even harmonic n says how many equally spaced wave vectors there are:
       2 stripes, 4 squares, 6 hexagons, 8/10/12/14 quasipatterns.
     A flat angular profile means rings (axisymmetric) or disorder.
  4. Frame-to-frame correlation -> stability (standing pattern vs. chaos).

    python3 tools/pattern_analyzer.py photo.jpg [--mm-per-px 0.2]
"""
from __future__ import annotations

import argparse
import json

import numpy as np

LABELS = {2: "stripes", 4: "squares", 6: "hexagons/triangles", 8: "8-fold quasipattern",
          10: "10-fold quasipattern", 12: "12-fold quasipattern", 14: "14-fold quasipattern"}


def _prep(img):
    a = np.asarray(img, float)
    if a.ndim == 3:
        a = a[..., :3].mean(-1)
    n = min(a.shape)
    a = a[(a.shape[0] - n) // 2:(a.shape[0] - n) // 2 + n, (a.shape[1] - n) // 2:(a.shape[1] - n) // 2 + n]
    a = (a - a.mean()) / (a.std() + 1e-9)
    y, x = np.mgrid[-1:1:n * 1j, -1:1:n * 1j]
    w = np.clip(1 - (x * x + y * y), 0, None) ** 2  # circular window, kills the frame edge
    return a * w


def spectrum(img):
    a = _prep(img)
    F = np.abs(np.fft.fftshift(np.fft.fft2(a)))
    n = F.shape[0]
    c = n // 2
    y, x = np.mgrid[:n, :n]
    r = np.hypot(x - c, y - c)
    th = np.arctan2(y - c, x - c)
    return F, r, th, n


def analyse(img, mm_per_px=None, max_order=30):
    F, r, th, n = spectrum(img)
    rb = np.arange(3, n // 2 - 2)
    prof = np.array([F[(r >= k - 0.5) & (r < k + 0.5)].mean() for k in rb])
    k_peak = rb[int(np.argmax(prof))]
    from scipy.ndimage import map_coordinates
    bins = 720
    t = np.linspace(-np.pi, np.pi, bins, endpoint=False)
    c = n // 2
    ang = np.zeros(bins)
    for rr in np.linspace(k_peak - 1.0, k_peak + 1.0, 5):
        ang += map_coordinates(F, [c + rr * np.sin(t), c + rr * np.cos(t)], order=1)
    H = np.abs(np.fft.rfft(ang - ang.mean())) / (ang.mean() * bins / 2 + 1e-9)
    # FFT magnitude is centro-symmetric, so only even harmonics carry pattern information
    evens = np.arange(2, max_order + 1, 2)
    strength = H[evens]
    # prefer the fundamental: a harmonic only counts if it is not just an overtone of a lower winner
    order = int(evens[int(np.argmax(strength))])
    for cand in evens:
        if H[cand] > 0.6 * strength.max():
            order = int(cand)
            break
    contrast = float(H[order])
    sharp = float(prof.max() / (np.median(prof) + 1e-9))
    if sharp < 3:
        label = "no clear pattern"
    elif contrast < 0.25:
        label = "rings / axisymmetric" if sharp > 6 else "disordered"
    else:
        label = LABELS.get(order, f"{order}-fold")
    wl_px = n / k_peak
    out = dict(label=label, order=order, angular_contrast=round(contrast, 3), peak_sharpness=round(sharp, 2),
               wavelength_px=round(float(wl_px), 2), harmonics={int(e): round(float(H[e]), 3) for e in evens[:8]})
    if mm_per_px:
        out["wavelength_mm"] = round(float(wl_px * mm_per_px), 2)
    return out


def stability(frames):
    """Mean normalised correlation between consecutive frames (1 = frozen standing pattern)."""
    cs = []
    for a, b in zip(frames, frames[1:]):
        a = _prep(a).ravel(); b = _prep(b).ravel()
        cs.append(float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-9)))
    return float(np.mean(cs)) if cs else 1.0


def synth(nwaves=3, k=40.0, res=256, noise=0.0, rings=False, seed=0, phases=None):
    """Synthetic wall image: |sum of standing waves| like a caustic, for tests and demos."""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[-1:1:res * 1j, -1:1:res * 1j]
    if rings:
        f = np.cos(k * np.hypot(x, y))
    else:
        f = np.zeros_like(x)
        ph = phases if phases is not None else rng.uniform(0, 2 * np.pi, nwaves)
        for j in range(nwaves):
            a = np.pi * j / nwaves
            f += np.cos(k * (x * np.cos(a) + y * np.sin(a)) + ph[j])
    img = np.clip(f, 0, None) ** 2 + noise * rng.standard_normal(f.shape)
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("images", nargs="+")
    ap.add_argument("--mm-per-px", type=float)
    a = ap.parse_args()
    from PIL import Image
    frames = [np.asarray(Image.open(p).convert("L"), float) for p in a.images]
    res = analyse(frames[-1], a.mm_per_px)
    if len(frames) > 1:
        res["stability"] = round(stability(frames), 3)
    print(json.dumps(res, indent=1))


if __name__ == "__main__":
    main()
