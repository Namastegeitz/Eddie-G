#!/usr/bin/env python3
"""Performance budget check: compares tests/bench.tscn results with
tests/perf_baseline.json and fails if anything got more than 5% worse.

  # run the bench (needs a display), then check its output:
  xvfb-run -a godot --path . --rendering-driver opengl3 res://tests/bench.tscn -- --quality=medium --track=io > /tmp/b.txt
  python3 tools/perf_check.py /tmp/b.txt [more bench outputs...]
  python3 tools/perf_check.py --counts-only /tmp/b.txt   # other computers: skip frame times

Node count and memory are the same on any computer; frame times only
compare on the computer the baseline was measured on, so use --counts-only
anywhere else. Single runs of the same code differ by up to about 8% in
frame time, so give it 3 runs per tier: it compares the median.
Draw calls are shown but not judged: they depend on where the AI race is
when the bench samples it (151 to 298 across runs of the same code).
"""
import json
import os
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(HERE, "..", "tests", "perf_baseline.json")
LOWER_IS_BETTER = ["avg_ms", "nodes", "mem_static_mb", "video_mem_mb"]
INFO_ONLY = ["draw_calls"]
HIGHER_IS_BETTER = ["low1_fps"]
TIMING = {"avg_ms", "low1_fps"}


def main(argv):
    counts_only = "--counts-only" in argv
    files = [a for a in argv if not a.startswith("--")]
    if not files:
        sys.exit(__doc__)
    base = json.load(open(BASE))
    pct = float(base.get("budget_pct", 5.0))
    runs = {}
    for f in files:
        for line in open(f, errors="replace"):
            if line.startswith("BENCHJSON "):
                r = json.loads(line[len("BENCHJSON "):])
                runs.setdefault(r.get("tier"), []).append(r)
    bad = 0
    for tier, rs in runs.items():
        ref = base.get(tier)
        if not isinstance(ref, dict):
            print("no baseline for tier %r, skipped" % tier)
            continue
        # median of each number over the runs given for this tier
        run = {k: statistics.median(float(r[k]) for r in rs) for k in rs[0] if isinstance(rs[0][k], (int, float))}
        print("%s: median of %d run(s)" % (tier, len(rs)))
        for k in INFO_ONLY:
            if k in ref and k in run:
                print("INFO %-6s %-14s baseline %8.2f  now %8.2f  (not judged: depends on the race)" % (tier, k, float(ref[k]), run[k]))
        for k in LOWER_IS_BETTER + HIGHER_IS_BETTER:
            if k not in ref or k not in run or (counts_only and k in TIMING):
                continue
            b, a = float(ref[k]), run[k]
            worse = ((a - b) if k in LOWER_IS_BETTER else (b - a)) / b * 100.0 if b else 0.0
            ok = worse <= pct
            bad += 0 if ok else 1
            note = "same" if abs(worse) < 0.05 else ("%.1f%% %s" % (abs(worse), "worse" if worse > 0 else "better"))
            print("%-4s %-6s %-14s baseline %8.2f  now %8.2f  (%s)" % ("OK" if ok else "FAIL", tier, k, b, a, note))
    print("PERF %s (budget %.0f%%)" % ("FAILED" if bad else "OK", pct))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
