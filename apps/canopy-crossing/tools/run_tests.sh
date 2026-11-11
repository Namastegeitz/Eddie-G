#!/usr/bin/env bash
# Full validation: every script compiles, then the phase audit (each phase's
# checkpoint from the build brief as checks) in the project and against an
# exported pack. Any script or engine error fails the run.
#   tools/run_tests.sh          # everything (all 30 stages solved by the bot)
#   FAST=1 tools/run_tests.sh   # one stage per region
#   WEB=1 tools/run_tests.sh    # also build the web version and tap-test it in a phone browser
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
sed -i 's|exclude_filter="tools/\*, tests/\*, docs/\*, override.cfg, build/\*"|exclude_filter="tools/*, docs/*, override.cfg, build/*"|' export_presets.cfg
timeout 300 "$GODOT" --headless --path . --export-pack "Linux" /tmp/cc_test.pck > /tmp/cc_pack.log 2>&1
cp /tmp/cc_presets.cfg export_presets.cfg
(cd /tmp && timeout 1800 "$GODOT" --headless --main-pack /tmp/cc_test.pck res://tests/phase_audit.tscn -- --no-boot --fast > /tmp/cc_audit_pck.log 2>&1) || fail=1
grep -E "FAIL|phase audit" /tmp/cc_audit_pck.log
if bad_lines /tmp/cc_audit_pck.log; then fail=1; fi
[ $fail -eq 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $fail
