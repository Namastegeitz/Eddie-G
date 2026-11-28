#!/usr/bin/env python3
"""Performance gate (upgrade step 9): runs the headless benchmark 3 times and
fails if game-logic frame time is more than 5% worse than the baseline in
tests/bench_baseline.json (median of 3 runs, summed over the rooms), or if
memory grew more than 10%.

  python3 tools/bench/check_perf.py               # check
  python3 tools/bench/check_perf.py --rebaseline  # record a new baseline
"""
import json, os, statistics, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "tests" / "bench_baseline.json"
GODOT = os.environ.get("GODOT", "godot")
RUNS = 3


def run_once(out: str) -> dict:
    subprocess.run([GODOT, "--headless", "--path", str(ROOT), "res://tools/bench/benchmark.tscn",
                    "--fixed-fps", "60", "--", f"--out={out}"], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=900)
    return json.loads(Path(out).read_text())["rooms"]


def main() -> int:
    runs = []
    with tempfile.TemporaryDirectory() as tmp:
        for i in range(RUNS):
            runs.append(run_once(os.path.join(tmp, f"b{i}.json")))
    rooms = list(runs[0].keys())
    med = {k: {r: statistics.median(run[r][k] for run in runs) for r in rooms}
           for k in ("frame_ms_avg", "frame_ms_p99", "memory_static_mb")}
    if "--rebaseline" in sys.argv:
        base = json.loads(BASE.read_text()) if BASE.exists() else {}
        base.update({k: {r: round(v, 3) for r, v in med[k].items()} for k in med})
        BASE.write_text(json.dumps(base, indent=2) + "\n")
        print("new baseline:", json.dumps(med))
        return 0
    base = json.loads(BASE.read_text())
    ok = True
    for r in rooms:
        print(f"{r:12s} frame {med['frame_ms_avg'][r]:.3f} ms (base {base['frame_ms_avg'][r]:.3f})"
              f"  p99 {med['frame_ms_p99'][r]:.3f} (base {base['frame_ms_p99'][r]:.3f})"
              f"  mem {med['memory_static_mb'][r]:.1f} MB (base {base['memory_static_mb'][r]:.1f})")
    now = sum(med["frame_ms_avg"].values())
    was = sum(base["frame_ms_avg"][r] for r in rooms)
    change = (now - was) / was * 100
    print(f"total frame time {now:.3f} ms vs {was:.3f} ms baseline ({change:+.1f}%)")
    if change > 5.0:
        print("PERF FAIL: more than 5% slower than the baseline")
        ok = False
    for r in rooms:
        if med["memory_static_mb"][r] > base["memory_static_mb"][r] * 1.10:
            print(f"PERF FAIL: {r} memory grew more than 10%")
            ok = False
    print("PERF OK" if ok else "PERF FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
