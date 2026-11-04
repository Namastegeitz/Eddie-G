#!/usr/bin/env bash
# Full validation: every script compiles, then the phase audit (each phase's
# checkpoint from the build brief as checks) in the project and against an
# exported pack. Any script or engine error fails the run.
#   tools/run_tests.sh          # everything (all 30 stages solved by the bot)
#   FAST=1 tools/run_tests.sh   # one stage per region
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
