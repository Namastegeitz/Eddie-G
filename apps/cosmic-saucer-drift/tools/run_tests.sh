#!/usr/bin/env bash
# Full validation: parse check, smoke test (data, saves, every mode, ads flow,
# menus) and the AI race simulator on all 18 track layouts.
# Any script or engine error fails the run.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
LAPS="${LAPS:-1}"
fail=0
bad_lines() { grep -E "SCRIPT ERROR|^ERROR:" "$1" | grep -v "resources still in use at exit" | grep -v "Condition \"status < 0\""; }

echo "== parse check"
out=$(tools/check_parse.sh)
echo "$out" | tail -1
if echo "$out" | grep -qE "SCRIPT ERROR|PARSE FAIL"; then echo "$out"; fail=1; fi

echo "== smoke test"
"$GODOT" --headless --path . res://tests/smoke.tscn --fixed-fps 60 > /tmp/csd_smoke.log 2>&1 || fail=1
grep -E "FAIL|SMOKE" /tmp/csd_smoke.log
if bad_lines /tmp/csd_smoke.log; then fail=1; fi

echo "== race simulator ($LAPS lap(s), all tracks, normal/reverse/mirror)"
"$GODOT" --headless --path . res://tests/sim.tscn --fixed-fps 60 -- --laps="$LAPS" --variants=0,1,2 > /tmp/csd_sim.log 2>&1 || fail=1
grep -E "^(OK|FAIL)|SIM DONE" /tmp/csd_sim.log
if bad_lines /tmp/csd_sim.log; then fail=1; fi

[ $fail -eq 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $fail
