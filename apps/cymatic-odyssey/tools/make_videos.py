#!/usr/bin/env python3
"""One 30-second vertical marketing video per light show (1080x1920, H.264 + AAC).

    python3 tools/make_videos.py              # all 15 -> marketing/videos/
    python3 tools/make_videos.py --only genesis --jobs 1

Picture: the same water/caustic/gobo model as the console, animated (standing waves breathe,
dipper rings travel outward), one 3-second scene per show segment, titles and end card.
Sound: an ambient pad built from each segment's drive tones, raised into the audible range,
plus soft plucks on the dipper pulses. Everything is labelled as a simulation.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.io import wavfile
from scipy.ndimage import map_coordinates, gaussian_filter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))
from physics_tables import wavelength_mm  # noqa: E402
from render_wall import _gobo_mask, _region_mask, _sources, _n_waves, _hex  # noqa: E402

W, H, FPS = 1080, 1920, 24
DISC = 900          # displayed circle diameter
RES = 640           # simulation resolution (upscaled to DISC)
SEG = 3.0           # seconds per show segment
TITLE, END = 3.0, 3.5
FONT = "/usr/share/fonts/opentype/inter/"
BG = (5, 6, 13)


def font(name, size):
    return ImageFont.truetype(FONT + name, size)


class Scene:
    """Precomputed arrays for one style; frame(t) returns an RGB disc image."""

    def __init__(self, style, ents, seed=3):
        xs = np.linspace(-1, 1, RES)
        self.X, self.Y = np.meshgrid(xs, -xs)
        self.dx = xs[1] - xs[0]
        self.R = np.hypot(self.X, self.Y)
        self.style = style
        fw = style["f"] / 2 if style["mode"] == "faraday" else style["f"]
        lam = wavelength_mm(fw, 0.005)
        self.K = min(2 * np.pi / lam * 56, 160)
        rng = np.random.default_rng(seed)
        self.N = _n_waves(style)
        self.ph = rng.uniform(0, 2 * np.pi, self.N)
        self.drift = rng.uniform(-0.25, 0.25, self.N)
        self.src = _sources(style)
        region = ents[style["insert"]]["fn"]().region
        inside = _region_mask(region, self.X, self.Y)
        self.soft = gaussian_filter(inside.astype(float), 2.0)
        self.mask = _gobo_mask(ents[style["gobo"]]["fn"](), RES)
        self.pal = [_hex(c) for c in style["pal"]]
        self.rim = 1 - np.clip((self.R - 0.92) / 0.08, 0, 1)

    def height(self, t):
        X, Y, R, K = self.X, self.Y, self.R, self.K
        s = self.style
        if s["mode"] == "faraday":
            h = np.zeros_like(X)
            for j in range(self.N):
                a = np.pi * j / self.N + 0.01 * t * self.drift[j]
                h += np.cos(K * (X * np.cos(a) + Y * np.sin(a)) + self.ph[j] + 0.3 * t * self.drift[j])
            h *= 1.15 / (self.N * K * K) * (0.55 + 0.45 * np.cos(2 * np.pi * 0.45 * t))
        else:
            A = 0.012 * 0.9 * 40 / max(K, 20)
            h = np.zeros_like(X)
            for sx, sy in self.src:
                r = np.hypot(X - sx, Y - sy)
                h += 0.35 * A * np.sin(K * r - 2 * np.pi * 0.55 * t) / np.sqrt(r + 0.08) / np.sqrt(len(self.src))
            rate = s.get("pulse") or 0.5
            for k in range(4):
                front = ((t * 0.32 * max(rate, 0.4)) + k / 4) % 1.15
                h += A * 1.2 * np.exp(-front * 1.2) * np.exp(-((R - front) * 7) ** 2) * np.cos(K * (R - front))
        return h * self.rim * self.soft

    def frame(self, t, D=2.2, chroma=0.2):
        h = self.height(t)
        hy, hx = np.gradient(h, self.dx)
        hxy, hxx = np.gradient(hx, self.dx)
        hyy, _ = np.gradient(hy, self.dx)
        hy, hxy = -hy, -hxy
        col = np.zeros(self.X.shape + (3,))
        res = RES
        for c, k in zip(self.pal, (-1, 0, 1)):
            dd = D * (1 + k * chroma)
            det = (1 + dd * hxx) * (1 + dd * hyy) - (dd * hxy) ** 2
            I = 0.15 + np.minimum(1 / np.maximum(np.abs(det), 0.05), 9)
            px = (self.X + dd * hx * 0.35 + 1) / 2 * (res - 1)
            py = (1 - (self.Y + dd * hy * 0.35)) / 2 * (res - 1)
            g = map_coordinates(self.mask, [py, px], order=1, mode="constant")
            col += (I * (1 - 0.95 * g))[..., None] * c[None, None, :]
        col = col / 3.0
        col = col / (1 + col) * 1.35
        col *= np.clip((1 - self.R) / 0.03, 0, 1)[..., None]
        col *= (0.06 + 0.94 * self.soft)[..., None]
        col = np.clip(col, 0, 1) ** 0.85
        bg = np.array(BG) / 255
        out = np.where((self.R <= 1)[..., None], col, bg)
        return Image.fromarray((out * 255).astype(np.uint8)).resize((DISC, DISC), Image.BICUBIC)


def wrap(draw, text, fnt, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        test = (cur + " " + w).strip()
        if draw.textlength(test, font=fnt) <= width:
            cur = test
        else:
            lines.append(cur); cur = w
    if cur:
        lines.append(cur)
    return lines


def centered(draw, y, text, fnt, fill, spacing=0):
    tw = draw.textlength(text, font=fnt) + spacing * max(len(text) - 1, 0)
    if spacing:
        x = (W - tw) / 2
        for ch in text:
            draw.text((x, y), ch, font=fnt, fill=fill)
            x += draw.textlength(ch, font=fnt) + spacing
    else:
        draw.text(((W - tw) / 2, y), text, font=fnt, fill=fill)


def compose(disc, show, idx, style, caption, sub, alpha_text=1.0, accent=(255, 210, 122), end=False, nxt=""):
    im = Image.new("RGB", (W, H), BG)
    # soft halo behind the disc in the style colour
    halo = Image.new("RGB", (W, H), BG)
    hd = ImageDraw.Draw(halo)
    c = tuple(int(v * 255) for v in _hex(style["pal"][1]))
    for r, a in ((520, 0.10), (480, 0.16), (455, 0.22)):
        hd.ellipse((W / 2 - r, 980 - r, W / 2 + r, 980 + r), fill=tuple(int(BG[i] + (c[i] - BG[i]) * a) for i in range(3)))
    from PIL import ImageFilter
    halo = halo.filter(ImageFilter.GaussianBlur(40))
    im.paste(halo, (0, 0))
    mask = Image.new("L", (DISC, DISC), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, DISC - 1, DISC - 1), fill=255)
    im.paste(disc, ((W - DISC) // 2, 980 - DISC // 2), mask)
    d = ImageDraw.Draw(im)
    fa = lambda col: tuple(int(BG[i] + (col[i] - BG[i]) * alpha_text) for i in range(3))
    centered(d, 120, "CYMATIC ODYSSEY", font("Inter-SemiBold.otf", 34), fa(accent), spacing=10)
    centered(d, 176, f"LIGHT SHOW {idx + 1} OF 15", font("Inter-Medium.otf", 28), fa((154, 163, 199)), spacing=6)
    big = font("InterDisplay-ExtraBold.otf", 104)
    lines = wrap(d, show["name"], big, W - 120)
    y = 250
    for ln in lines:
        centered(d, y, ln, big, fa((255, 255, 255))); y += 112
    centered(d, y + 6, show["mood"], font("Inter-Regular.otf", 36), fa((201, 203, 224)))
    if end:
        yy = 1470
        for ln, f, col in (("Real water. Real sound.", font("InterDisplay-Bold.otf", 60), (255, 255, 255)),
                           ("Geometry of light.", font("InterDisplay-Bold.otf", 60), accent),
                           (f"10-minute show  ·  flows into {nxt}", font("Inter-Regular.otf", 34), (201, 203, 224)),
                           ("30 styles  ·  15 shows  ·  build your own", font("Inter-SemiBold.otf", 34), (127, 212, 255))):
            centered(d, yy, ln, f, fa(col)); yy += 78 if f.size > 50 else 56
    else:
        centered(d, 1475, caption, font("InterDisplay-Bold.otf", 58), fa((255, 255, 255)))
        lines = wrap(d, sub, font("Inter-Regular.otf", 34), W - 160)[:3]
        yy = 1560
        for ln in lines:
            centered(d, yy, ln, font("Inter-Regular.otf", 34), fa((201, 203, 224))); yy += 48
    centered(d, H - 80, "Simulated preview of the CYMATIC ODYSSEY water-light chamber", font("Inter-Regular.otf", 24), (110, 116, 150))
    return im


def soundtrack(show, styles, dur, sr=44100):
    t = np.arange(int(sr * dur)) / sr
    out = np.zeros_like(t)
    segs = [(TITLE, show["steps"][0])] + [(SEG, s) for s in show["steps"]]
    start = 0.0
    for k, (length, step) in enumerate(segs):
        st = styles[step["style"]]
        f = step["f"]
        while f < 110:
            f *= 2
        ratio = step["ratio"][0] / step["ratio"][1] if step["ratio"] else 1.5
        notes = [f, f * ratio, f * 2, f / 2]
        seg_len = length + 1.2
        i0, i1 = int(start * sr), min(int((start + seg_len) * sr), len(t))
        tt = t[i0:i1] - start
        env = np.minimum(1, tt / 0.9) * np.minimum(1, (seg_len - tt) / 1.0)
        tone = sum(a * np.sin(2 * np.pi * n * tt + 0.3 * np.sin(2 * np.pi * 0.2 * tt)) for n, a in zip(notes, (0.32, 0.22, 0.12, 0.18)))
        tone *= 1 + 0.25 * np.sin(2 * np.pi * (step["breathe"] or 0.15) * tt)
        out[i0:i1] += tone * env
        if step["mode"] == "dipper":
            rate = max(step["pulse"] or 0.8, 0.5)
            for p0 in np.arange(0.2, length, 1 / rate):
                j0 = i0 + int(p0 * sr); n = int(0.9 * sr)
                if j0 + n < len(out):
                    pt = np.arange(n) / sr
                    out[j0:j0 + n] += 0.18 * np.sin(2 * np.pi * f * 4 * pt) * np.exp(-pt * 6)
        start += length
    # end card: resolve to the first chord
    i0 = int((dur - END) * sr)
    tt = t[i0:] - (dur - END)
    f = show["steps"][0]["f"]
    while f < 110:
        f *= 2
    out[i0:] += (0.3 * np.sin(2 * np.pi * f * tt) + 0.2 * np.sin(2 * np.pi * f * 1.5 * tt)) * np.minimum(1, tt / 0.5) * np.clip((END - tt) / 1.5, 0, 1)
    # gentle reverb-ish smear + master
    k = np.exp(-np.arange(int(0.35 * sr)) / (0.12 * sr)); k /= k.sum()
    from scipy.signal import fftconvolve
    wet = fftconvolve(out, k, mode="same")
    mix = 0.7 * out + 0.6 * wet
    mix /= np.max(np.abs(mix)) + 1e-9
    mix *= 0.6
    fade = np.minimum(1, np.minimum(t / 0.6, (dur - t) / 0.8))
    stereo = np.c_[mix * fade, np.roll(mix, int(0.012 * sr)) * fade]
    return (stereo * 32767).astype(np.int16)


def make(show_id, outdir, tmpbase):
    from odyssey import catalog
    from styles import STYLES
    content = json.loads((ROOT / "catalog/content.json").read_text())
    shows = content["shows"]
    idx = next(i for i, s in enumerate(shows) if s["id"] == show_id)
    show = shows[idx]
    styles = {s["id"]: s for s in STYLES}
    ents = {e["name"]: e for e in catalog.entries()}
    nxt = next(s["name"] for s in shows if s["id"] == show["next"])
    tmp = Path(tmpbase) / show_id
    tmp.mkdir(parents=True, exist_ok=True)
    plan = [("title", show["steps"][0], TITLE)] + [("seg", s, SEG) for s in show["steps"]] + [("end", show["steps"][0], END)]
    total = sum(p[2] for p in plan)
    scenes = {}
    fno = 0
    prev_img = None
    for kind, step, length in plan:
        st = styles[step["style"]]
        if st["id"] not in scenes:
            scenes[st["id"]] = Scene(st, ents)
        sc = scenes[st["id"]]
        nfr = int(round(length * FPS))
        role = {"opening": "Opening", "core": "", "guest": "Guest style", "bridge": "Bridge to " + nxt}.get(step.get("role", ""), "")
        cap = st["name"]
        sub = (role + " · " if role else "") + st["how"]
        for i in range(nfr):
            tt = fno / FPS
            if (tmp / f"f{fno:05d}.jpg").exists() and (tmp / f"f{fno + 1:05d}.jpg").exists():
                fno += 1
                if i == nfr - 1:
                    prev_img = Image.open(tmp / f"f{fno - 1:05d}.jpg").convert("RGB")
                continue
            disc = sc.frame(tt * 1.0)
            if kind == "title":
                a = min(1, i / (0.6 * FPS))
                img = compose(disc, show, idx, st, "Real water. Real sound.", "A 10-minute light show for the CYMATIC ODYSSEY chamber.", alpha_text=a)
                img = Image.blend(Image.new("RGB", (W, H), BG), img, min(1, i / (0.5 * FPS)))
            elif kind == "end":
                img = compose(disc, show, idx, st, "", "", end=True, nxt=nxt)
            else:
                img = compose(disc, show, idx, st, cap, sub)
            if prev_img is not None and i < int(0.4 * FPS):
                img = Image.blend(prev_img, img, (i + 1) / (0.4 * FPS))
            if i == nfr - 1:
                prev_img = img
            img.save(tmp / f"f{fno:05d}.jpg", quality=92)
            fno += 1
    wavfile.write(tmp / "audio.wav", 44100, soundtrack(show, styles, total))
    out = Path(outdir) / f"{idx + 1:02d}_{show_id}.mp4"
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-framerate", str(FPS), "-i", str(tmp / "f%05d.jpg"), "-i", str(tmp / "audio.wav"),
                    "-c:v", "libx264", "-preset", "slow", "-crf", "27", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k",
                    "-shortest", "-movflags", "+faststart", str(out)], check=True)
    # poster frame
    Image.open(tmp / f"f{int((TITLE + SEG * 2.5) * FPS):05d}.jpg").save(out.with_suffix(".jpg"), quality=88)
    shutil.rmtree(tmp, ignore_errors=True)
    return str(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only")
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--out", default=str(ROOT / "marketing/videos"))
    ap.add_argument("--tmp", default="/tmp/cymatic_frames")
    a = ap.parse_args()
    shows = json.loads((ROOT / "catalog/content.json").read_text())["shows"]
    ids = [s["id"] for s in shows if not a.only or s["id"] in a.only.split(",")]
    with ProcessPoolExecutor(a.jobs) as ex:
        for r in ex.map(make, ids, [a.out] * len(ids), [a.tmp] * len(ids)):
            print("wrote", r, flush=True)


if __name__ == "__main__":
    main()
