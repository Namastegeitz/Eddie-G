#!/usr/bin/env python3
"""Visual regression: key screens at three screen shapes, compared with
reference pictures in tests/visual/ (small copies, 360 px wide).

    python3 tools/visual_check.py              # compare (fails if a screen changed a lot)
    python3 tools/visual_check.py --record     # make the current pictures the reference
    python3 tools/visual_check.py --out DIR    # also keep full-size pictures in DIR
    python3 tools/visual_check.py --only run_fpv_phone,home   # some screens only

Software OpenGL is slow (first person can take minutes a picture): each
capture may run for CAPTURE_TIMEOUT seconds (default 1500), and one that runs
out before its last frame fails rather than comparing an earlier frame.

Screens: home, settings, a run from above, the same run in first person,
all at Medium graphics (what phones get; High's software anti-aliasing would
take minutes a frame here).
Shapes: phone 9:16 (720x1280), tall phone 19.5:9 (720x1560), tablet 3:4
(1536x2048). A screen fails when more than 4% of its pixels changed clearly
(by more than 40 of 255) or its average change is above 6: enough room for
animation, not for a broken layout or a missing layer."""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
REF = ROOT / "tests" / "visual"
SIZES = {"phone": (720, 1280), "tall": (720, 1560), "tablet": (1536, 2048)}
SCREENS = {
    "home": (40, ["--skip-tutorial", "--screen=home"]),
    "settings": (40, ["--skip-tutorial", "--screen=settings"]),
    "run_bird": (150, ["--skip-tutorial", "--play=journey,amazon,4", "--autoplay"]),
    "run_fpv": (150, ["--skip-tutorial", "--play=journey,amazon,4", "--autoplay", "--fpv"]),
}


def capture(size, frames, args, out):
    w, h = size
    cfg = ROOT / "override.cfg"
    cfg.write_text(f"[display]\n\nwindow/size/window_width_override={w}\nwindow/size/window_height_override={h}\n")
    limit = int(os.environ.get("CAPTURE_TIMEOUT", "1500"))
    try:
        r = subprocess.run([str(ROOT / "tools" / "capture.sh"), str(out), str(frames), f"{w}x{h}", "--", "--no-remote-config", "--graphics=medium", *args],
                           check=False, capture_output=True, text=True, timeout=limit + 120,
                           env={**os.environ, "CAPTURE_TIMEOUT": str(limit)})
    finally:
        cfg.unlink(missing_ok=True)
    if "SHORT" in r.stderr:
        return "timed out before the last frame"
    return "" if out.exists() else "no picture"


def small(img):
    w = 360
    return img.convert("RGB").resize((w, int(img.height * w / img.width)), Image.LANCZOS)


def main():
    record = "--record" in sys.argv
    keep = sys.argv[sys.argv.index("--out") + 1] if "--out" in sys.argv else ""
    only = sys.argv[sys.argv.index("--only") + 1].split(",") if "--only" in sys.argv else []
    REF.mkdir(parents=True, exist_ok=True)
    bad = []
    with tempfile.TemporaryDirectory() as tmp:
        for sname, size in SIZES.items():
            for name, (frames, args) in SCREENS.items():
                key = f"{name}_{sname}"
                if only and key not in only and name not in only and sname not in only:
                    continue
                shot = Path(tmp) / f"{key}.png"
                problem = capture(size, frames, args, shot)
                if problem:
                    print(f"  FAIL {key}: {problem}", flush=True)
                    bad.append(key)
                    continue
                img = Image.open(shot)
                if keep:
                    os.makedirs(keep, exist_ok=True)
                    img.save(Path(keep) / f"{key}.png")
                cur = small(img)
                ref = REF / f"{key}.png"
                if record or not ref.exists():
                    cur.save(ref, optimize=True)
                    print(f"  rec  {key}", flush=True)
                    continue
                a = np.asarray(cur).astype(int)
                b = np.asarray(Image.open(ref).convert("RGB")).astype(int)
                if a.shape != b.shape:
                    print(f"  FAIL {key}: size {a.shape} vs reference {b.shape}")
                    bad.append(key)
                    continue
                d = np.abs(a - b).max(axis=2)
                changed = (d > 40).mean() * 100
                mean = d.mean()
                ok = changed <= 4.0 and mean <= 6.0
                print(f"  {'ok  ' if ok else 'FAIL'} {key}: {changed:.2f}% pixels changed, mean {mean:.2f}", flush=True)
                if not ok:
                    bad.append(key)
                    Image.fromarray(np.clip(d * 3, 0, 255).astype("uint8")).save(ROOT / "build" / f"visual_diff_{key}.png")
    print("VISUAL OK" if not bad else "VISUAL CHANGED: " + ", ".join(bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
