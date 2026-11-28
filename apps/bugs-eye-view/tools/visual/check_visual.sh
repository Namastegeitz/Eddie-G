#!/usr/bin/env bash
# Screenshots the key screens at three sizes (desktop, phone, Steam Deck)
# plus the phone at 200% text, then compares them with tests/visual/.
#   tools/visual/check_visual.sh [OUT_DIR] [--update]
set -e
cd "$(dirname "$0")/../.."
OUT="${1:-/tmp/bev_visual}"
export MESA_SHADER_CACHE_DISABLE=true
shot() {  # shot <WxH> <name> [extra args]
	mkdir -p "$OUT/$2"
	xvfb-run -a -s "-screen 0 2000x2000x24" godot --path . --resolution "$1" \
		res://tools/visual/visual_shots.tscn -- --out="$OUT/$2" "${@:3}" | grep -E "VISUAL|SCRIPT ERROR" || true
}
shot 1280x720 desktop_1280x720
shot 844x390 phone_844x390
shot 1280x800 steamdeck_1280x800
shot 844x390 phone_text200 --text=2.0 --shots=settings_top,kitchen
python3 tools/visual/compare.py "$OUT" ${2:-}
