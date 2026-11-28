#!/usr/bin/env bash
# Full validation: every script compiles, then the phase audit (each phase's
# checkpoint from the build brief as checks) in the project and against an
# exported pack. Any script or engine error fails the run.
#   tools/run_tests.sh          # everything (all 30 stages solved by the bot)
#   FAST=1 tools/run_tests.sh   # one stage per region
#   WEB=1 tools/run_tests.sh    # also build the web version and tap-test it in a phone browser
#   VISUAL=1 tools/run_tests.sh # also compare key screens at 3 screen sizes (tools/visual_check.py, ~10 min)
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
EXTRA=""
[ "${FAST:-0}" = "1" ] && EXTRA="--fast"
fail=0
bad_lines() { grep -E "SCRIPT ERROR|^ERROR:" "$1" | grep -v "resources still in use at exit" | grep -v "_free_rids" | grep -v "ObjectDB instances" | grep -v "were leaked at exit"; }
echo "== import"; timeout 300 "$GODOT" --headless --path . --import > /tmp/cc_import.log 2>&1
if grep -E "SCRIPT ERROR|Parse Error" /tmp/cc_import.log; then fail=1; fi
echo "== compile"; tools/parse_check.sh | tee /tmp/cc_parse.log
if ! grep -q "bad=0" /tmp/cc_parse.log; then echo "compile errors: stopping"; exit 1; fi
echo "== first-person render (real GL renderer: every scene must draw a real picture)"
if command -v xvfb-run > /dev/null; then
  timeout 3000 xvfb-run -a -s "-screen 0 800x1400x24" "$GODOT" --path . --rendering-driver opengl3 --audio-driver Dummy \
    --resolution 720x1280 res://tools/fpv_check.tscn -- --no-boot $EXTRA --out=/tmp/cc_fpv_scenes.png > /tmp/cc_fpv.log 2>&1 || fail=1
  grep -E "BAD|fpv check" /tmp/cc_fpv.log
  if bad_lines /tmp/cc_fpv.log; then fail=1; fi
else
  echo "(skipped: needs xvfb-run)"
fi
echo "== performance budget (draw calls, objects, primitives vs tests/perf_baseline.json; fails if >5% worse)"
if command -v xvfb-run > /dev/null; then
  timeout 1800 xvfb-run -a -s "-screen 0 800x1400x24" "$GODOT" --path . --rendering-driver opengl3 --audio-driver Dummy \
    --resolution 720x1280 --fixed-fps 60 res://tools/benchmark.tscn -- --no-boot --graphics=medium --frames=90 --out=/tmp/cc_bench.json > /tmp/cc_bench.log 2>&1 || fail=1
  python3 tools/bench_check.py /tmp/cc_bench.json || fail=1
else
  echo "(skipped: needs xvfb-run)"
fi
echo "== secrets (no keys, DSNs or private keys in tracked files)"
if git ls-files -z . | xargs -0 grep -nIE 'AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----|https://[0-9a-f]{32}@o[0-9]+\.ingest|msy_[A-Za-z0-9]{20,}' 2> /dev/null; then
  echo "found something that looks like a secret"; fail=1
else
  echo "no secrets found"
fi
if [ "${VISUAL:-0}" = "1" ]; then
  echo "== key screens at 3 sizes (visual regression)"
  python3 tools/visual_check.py || fail=1
fi
echo "== calm songs tuned to 528 / 963 Hz (decodes each song, checks its pitches)"
if command -v ffmpeg > /dev/null && python3 -c "import numpy" 2> /dev/null; then
  python3 tools/gen_audio.py --check | tail -1
  python3 tools/gen_audio.py --check > /dev/null || fail=1
else
  echo "(skipped: needs ffmpeg and numpy)"
fi
if [ "${WEB:-0}" = "1" ]; then
  echo "== web build + phone-browser smoke test"
  tools/build_web.sh || fail=1
fi
echo "== phase audit (project)"
timeout 1500 "$GODOT" --headless --path . res://tests/phase_audit.tscn -- --no-boot $EXTRA > /tmp/cc_audit.log 2>&1 || fail=1
grep -E "FAIL|phase audit" /tmp/cc_audit.log
if bad_lines /tmp/cc_audit.log; then fail=1; fi
echo "== phase audit (exported pack)"
cp export_presets.cfg /tmp/cc_presets.cfg
# include the tests in this one pack (whatever else the presets exclude)
sed -i '/^exclude_filter=/s|tests/\*, ||' export_presets.cfg
timeout 300 "$GODOT" --headless --path . --export-pack "Linux" /tmp/cc_test.pck > /tmp/cc_pack.log 2>&1
cp /tmp/cc_presets.cfg export_presets.cfg
(cd /tmp && timeout 1800 "$GODOT" --headless --main-pack /tmp/cc_test.pck res://tests/phase_audit.tscn -- --no-boot --fast > /tmp/cc_audit_pck.log 2>&1) || fail=1
grep -E "FAIL|phase audit" /tmp/cc_audit_pck.log
if bad_lines /tmp/cc_audit_pck.log; then fail=1; fi
[ $fail -eq 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $fail
