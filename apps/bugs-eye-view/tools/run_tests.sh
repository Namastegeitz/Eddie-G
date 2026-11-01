#!/usr/bin/env bash
# Full validation: import, boot, warnings-as-errors, smoke test in the editor
# build AND against an exported pack (catches export-only bugs).
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
fail=0
echo "== import"; "$GODOT" --headless --path . --import > /tmp/bev_import.log 2>&1
if grep -E "SCRIPT ERROR|Parse Error" /tmp/bev_import.log; then fail=1; fi
echo "== boot"; "$GODOT" --headless --path . --quit > /tmp/bev_boot.log 2>&1
if grep -E "SCRIPT ERROR|ERROR:" /tmp/bev_boot.log | grep -v "resources still in use"; then fail=1; fi
echo "== warnings"; tools/check_warnings.sh || fail=1
echo "== smoke test (project)"
"$GODOT" --headless --path . res://tests/smoke_test.tscn --fixed-fps 60 > /tmp/bev_smoke.log 2>&1 || fail=1
grep -E "FAIL|passed" /tmp/bev_smoke.log
if grep -E "SCRIPT ERROR" /tmp/bev_smoke.log; then fail=1; fi
echo "== smoke test (exported pack)"
cp export_presets.cfg /tmp/bev_presets.cfg
sed -i 's|exclude_filter="tools/\*, tests/\*, docs/\*, override.cfg"|exclude_filter="tools/*, docs/*, override.cfg"|' export_presets.cfg
"$GODOT" --headless --path . --export-pack "Linux" /tmp/bev_test.pck > /tmp/bev_pack.log 2>&1
cp /tmp/bev_presets.cfg export_presets.cfg
(cd /tmp && "$GODOT" --headless --main-pack /tmp/bev_test.pck res://tests/smoke_test.tscn --fixed-fps 60 > /tmp/bev_smoke_pck.log 2>&1) || fail=1
grep -E "FAIL|passed" /tmp/bev_smoke_pck.log
if grep -E "SCRIPT ERROR" /tmp/bev_smoke_pck.log; then fail=1; fi
[ $fail -eq 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $fail
