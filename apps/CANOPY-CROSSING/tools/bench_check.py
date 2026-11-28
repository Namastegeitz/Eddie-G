#!/usr/bin/env python3
"""Performance gate: compares a benchmark run (tools/benchmark.tscn) with the
recorded baseline (tests/perf_baseline.json) and fails if anything the GPU is
asked to do got more than 5% worse.

    python3 tools/bench_check.py build/bench/check.json            # check
    python3 tools/bench_check.py build/bench/check.json --record   # make it the new baseline

Gated (machine-independent): draw calls (average and worst frame), objects
drawn and primitives, in the bird's-eye and first-person views. Timings are
printed for information only: this machine renders in software, so they
compare runs here, not phones."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / "tests" / "perf_baseline.json"
GATED = ["draw_calls", "draw_calls_max", "objects", "primitives"]
TOL = 0.05


def main() -> int:
    run = json.loads(Path(sys.argv[1]).read_text())
    if "--record" in sys.argv:
        keep = {v: {k: run[v][k] for k in GATED} for v in ("bird", "fpv") if v in run}
        keep["setup"] = {k: run.get(k) for k in ("graphics", "window", "map", "stage", "engine")}
        BASE.write_text(json.dumps(keep, indent=2) + "\n")
        print(f"recorded {BASE.relative_to(ROOT)}")
        return 0
    base = json.loads(BASE.read_text())
    bad = []
    for view in ("bird", "fpv"):
        if view not in base or view not in run:
            continue
        for k in GATED:
            b, r = float(base[view][k]), float(run[view][k])
            worse = (r - b) / b if b > 0 else 0.0
            flag = "FAIL" if worse > TOL else "ok"
            print(f"  {flag:4} {view:4} {k:15} {r:>12.1f}  (baseline {b:.1f}, {worse:+.1%})")
            if worse > TOL:
                bad.append(f"{view}.{k}")
        print(f"       {view:4} avg {run[view]['avg_ms']} ms, 1% low {run[view]['low1_fps']} fps, worst {run[view]['worst_ms']} ms (this machine, information only)")
    print("PERF OK" if not bad else "PERF WORSE: " + ", ".join(bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
