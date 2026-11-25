"""Checks for the geometry engine, physics tables and pattern analyzer.

    python3 -m pytest apps/cymatic-odyssey/tests -q     (or: python3 tests/test_tools.py)
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import pattern_analyzer as PA  # noqa: E402
import physics_tables as PT  # noqa: E402
from odyssey import polyhedra as H, polytopes as X, catalog  # noqa: E402


def test_symmetry_detection():
    for nw, order in [(1, 2), (2, 4), (3, 6), (4, 8), (5, 10), (6, 12)]:
        r = PA.analyse(PA.synth(nw, k=40, noise=0.2, seed=nw))
        assert r["order"] == order, (nw, r)


def test_rings_and_noise():
    assert PA.analyse(PA.synth(rings=True))["label"].startswith("rings")
    assert PA.analyse(np.random.default_rng(1).standard_normal((256, 256)))["label"] == "no clear pattern"


def test_wavelength_estimate():
    r = PA.analyse(PA.synth(3, k=40))
    assert abs(r["wavelength_px"] - (2 * np.pi / 40) / 2 * 256) < 1.5


def test_stability():
    a = PA.synth(3, k=40, seed=2)
    assert PA.stability([a, a, a]) > 0.99
    b = [PA.synth(3, k=40, seed=s) for s in range(4)]
    assert PA.stability(b) < 0.6


def test_dispersion():
    # deep water, 30 Hz capillary-gravity wave: wavelength ~ 8.6 mm
    assert abs(PT.wavelength_mm(30, 0.05) - 8.6) < 0.2
    # long gravity wave in shallow water approaches sqrt(g h)
    f = 0.5
    lam = PT.wavelength_mm(f, 0.005) / 1000
    assert abs(lam * f - np.sqrt(9.81 * 0.005)) / np.sqrt(9.81 * 0.005) < 0.02


def test_solid_counts():
    expect = {"Truncated icosahedron": (60, 90), "Snub cube": (24, 60), "Snub dodecahedron": (60, 150),
              "Truncated icosidodecahedron": (120, 180)}
    for nm, (v, e) in expect.items():
        V, E = H.archimedean(nm)
        assert (len(V), len(E)) == (v, e), nm


def test_root_systems():
    for nm, (S, h, count) in X.ROOT_SYSTEMS.items():
        assert len(X.roots_from_simple(S)) == count


def test_catalog_unique():
    es = catalog.entries()
    assert len({e["id"] for e in es}) == len(es)
    assert len({e["name"] for e in es}) == len(es)
    assert len(es) > 300


if __name__ == "__main__":
    for k, f in list(globals().items()):
        if k.startswith("test_"):
            f(); print("ok", k)
