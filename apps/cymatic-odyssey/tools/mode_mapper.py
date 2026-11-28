#!/usr/bin/env python3
"""Mode mapper: sweep the drive frequency, photograph the wall, log what pattern appears.

Builds a 'pattern atlas' for YOUR dish, water depth and insert - the lookup table the
Voyage console uses to jump straight to a look (e.g. 'hexagons' -> 47.5 Hz).

Hardware run (laptop audio out -> amplifier -> exciters, USB webcam aimed at the wall):
    pip install sounddevice opencv-python numpy scipy pillow
    python3 tools/mode_mapper.py --start 20 --stop 120 --step 0.5 --camera 0 --out atlas.csv

Dry run without hardware (synthetic frames, shows the output format):
    python3 tools/mode_mapper.py --simulate --out atlas_demo.csv

Safety: keep the amplifier volume low at first; the console's level limiter is not
in this script. Never point the camera rig's cables near the Tesla coil bay.
"""
from __future__ import annotations

import argparse
import csv
import sys
import time
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pattern_analyzer as PA  # noqa: E402


def tone(freq, seconds, sr=48000, amp=0.3, second=None, ratio_amp=0.6):
    t = np.arange(int(sr * seconds)) / sr
    y = amp * np.sin(2 * np.pi * freq * t)
    if second:
        y += amp * ratio_amp * np.sin(2 * np.pi * second * t)
    fade = np.minimum(1, np.minimum(t, t[::-1]) / 0.05)
    return (y * fade).astype(np.float32)


def simulated_frames(freq, n=4):
    # crude stand-in: order depends on frequency band, wavelength on dispersion
    from physics_tables import wavelength_mm
    wl = wavelength_mm(freq / 2, 0.005)
    k = 2 * np.pi / (wl / 60)  # 120 mm field of view mapped to [-1,1]
    band = int(freq // 15) % 4
    nw = [2, 3, 2, 6][band]
    rng = np.random.default_rng(int(freq * 10))
    ph = rng.uniform(0, 2 * np.pi, nw)
    return [PA.synth(nw, k=k, noise=0.15, phases=ph + 0.02 * i) for i in range(n)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", type=float, default=20)
    ap.add_argument("--stop", type=float, default=120)
    ap.add_argument("--step", type=float, default=1.0)
    ap.add_argument("--second-ratio", type=str, help="e.g. 5/4 to add a second tone at 1.25 x f")
    ap.add_argument("--settle", type=float, default=2.5, help="seconds for the pattern to settle")
    ap.add_argument("--camera", type=int, default=0)
    ap.add_argument("--mm-per-px", type=float)
    ap.add_argument("--simulate", action="store_true")
    ap.add_argument("--out", default="atlas.csv")
    a = ap.parse_args()

    ratio = None
    if a.second_ratio:
        p, q = a.second_ratio.split("/")
        ratio = float(p) / float(q)

    cam = None
    if not a.simulate:
        import cv2
        import sounddevice as sd
        cam = cv2.VideoCapture(a.camera)
        if not cam.isOpened():
            sys.exit("camera not found")

    rows = []
    for f in np.arange(a.start, a.stop + 1e-9, a.step):
        if a.simulate:
            frames = simulated_frames(f)
        else:
            y = tone(f, a.settle + 1.5, second=f * ratio if ratio else None)
            sd.play(y, 48000)
            time.sleep(a.settle)
            frames = []
            for _ in range(4):
                ok, fr = cam.read()
                if ok:
                    frames.append(cv2.cvtColor(fr, cv2.COLOR_BGR2GRAY).astype(float))
                time.sleep(0.08)
            sd.wait()
        res = PA.analyse(frames[-1], a.mm_per_px)
        res["stability"] = round(PA.stability(frames), 3)
        row = dict(freq_hz=round(float(f), 2), second_hz=round(float(f * ratio), 2) if ratio else "",
                   label=res["label"], order=res["order"], contrast=res["angular_contrast"],
                   sharpness=res["peak_sharpness"], wavelength_px=res["wavelength_px"],
                   wavelength_mm=res.get("wavelength_mm", ""), stability=res["stability"])
        rows.append(row)
        print(row, flush=True)
    with open(a.out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)
    # summary: best frequency for each look
    best = {}
    for r in rows:
        if r["label"] in ("no clear pattern", "disordered"):
            continue
        score = r["contrast"] * r["stability"]
        if r["label"] not in best or score > best[r["label"]][0]:
            best[r["label"]] = (score, r["freq_hz"])
    print("\nbest frequency per look:")
    for lab, (sc, fq) in sorted(best.items(), key=lambda x: x[1][1]):
        print(f"  {lab:24s} {fq:7.2f} Hz  (score {sc:.2f})")
    if cam is not None:
        cam.release()


if __name__ == "__main__":
    main()
