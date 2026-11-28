"""Physics-derived patterns: Chladni plates, Bessel drum/water modes, Faraday quasipatterns."""
from __future__ import annotations

from math import pi

import numpy as np

from .core import Design, circle, TAU
from .fractals import contour_design


def chladni_square(n, m, sign=-1, res=500):
    xs = np.linspace(0, 1, res)
    X, Y = np.meshgrid(xs, xs)
    F = np.cos(n * pi * X) * np.cos(m * pi * Y) + sign * np.cos(m * pi * X) * np.cos(n * pi * Y)
    d = contour_design(xs, xs, F, [0.0], weight=0.9)
    d.lines.append(np.array([(0, 0), (1, 0), (1, 1), (0, 1), (0, 0)], float))
    return d.centred()


def bessel_mode(m, n, res=600, free_edge=True):
    """Nodal lines of a circular mode J_m(k r) cos(m theta).

    free_edge=True uses zeros of J_m' (Neumann) - the boundary condition of a
    liquid surface meeting a vertical wall.
    """
    from scipy.special import jv, jnp_zeros, jn_zeros
    z = (jnp_zeros(m, n) if (free_edge and m > 0) else
         (np.r_[0.0, jnp_zeros(0, n)][n] if free_edge else jn_zeros(m, n)[-1]))
    k = float(np.atleast_1d(z)[-1])
    xs = np.linspace(-1, 1, res)
    X, Y = np.meshgrid(xs, xs)
    R = np.hypot(X, Y)
    T = np.arctan2(Y, X)
    F = jv(m, k * R) * np.cos(m * T)
    F[R > 1] = np.nan
    d = contour_design(xs, xs, F, [0.0], weight=0.9)
    d.lines.append(circle(1.0))
    return d


def faraday_quasipattern(nwaves, k=26.0, level=0.0, phases=None, res=900, weight=0.7):
    """Sum of nwaves standing plane waves at equal angles -> 2*nwaves-fold pattern.

    nwaves=2 squares, 3 hexagons, 4 eightfold, 5 tenfold, 6 twelvefold quasipattern
    (as seen with two-frequency forcing, Edwards & Fauve 1993).
    """
    xs = np.linspace(-1, 1, res)
    X, Y = np.meshgrid(xs, xs)
    F = np.zeros_like(X)
    ph = phases if phases is not None else np.zeros(nwaves)
    for j in range(nwaves):
        a = pi * j / nwaves
        F += np.cos(k * (X * np.cos(a) + Y * np.sin(a)) + ph[j])
    F[np.hypot(X, Y) > 1] = np.nan
    d = contour_design(xs, xs, F, [level], weight=weight)
    d.lines.append(circle(1.0))
    return d


def superlattice(k1=22.0, ratio=7 / 6, res=900):
    """Two hexagonal wave sets at different wavenumbers (two-frequency 'superlattice')."""
    xs = np.linspace(-1, 1, res)
    X, Y = np.meshgrid(xs, xs)
    F = np.zeros_like(X)
    for kk, rot, w in ((k1, 0, 1.0), (k1 * ratio, pi / 6, 0.7)):
        for j in range(3):
            a = rot + TAU * j / 3
            F += w * np.cos(kk * (X * np.cos(a) + Y * np.sin(a)))
    F[np.hypot(X, Y) > 1] = np.nan
    d = contour_design(xs, xs, F, [0.0], weight=0.7)
    d.lines.append(circle(1.0))
    return d


def interference(sources, k=60.0, res=800):
    """Ripple tank: crests of circular waves from point sources (multi-pin dipper)."""
    xs = np.linspace(-1, 1, res)
    X, Y = np.meshgrid(xs, xs)
    F = np.zeros_like(X)
    for sx, sy in sources:
        R = np.hypot(X - sx, Y - sy) + 1e-6
        F += np.cos(k * R) / np.sqrt(R + 0.05)
    F[np.hypot(X, Y) > 1] = np.nan
    d = contour_design(xs, xs, F, [0.6], weight=0.7)
    d.lines.append(circle(1.0))
    return d


def standing_ring_wave(k=40.0):
    """Axisymmetric ripples from a centre pulse: the 'pulsed outward' look."""
    from scipy.special import j0
    xs = np.linspace(-1, 1, 800)
    X, Y = np.meshgrid(xs, xs)
    R = np.hypot(X, Y)
    F = j0(k * R) * np.sqrt(R + 0.02)
    F[R > 1] = np.nan
    d = contour_design(xs, xs, F, [0.0], weight=0.9)
    d.lines.append(circle(1.0))
    return d
