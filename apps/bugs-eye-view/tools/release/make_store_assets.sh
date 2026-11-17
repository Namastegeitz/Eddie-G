#!/usr/bin/env bash
# Renders every store image from the real game, then crops, titles and sizes
# them for each store (compose_store_assets.py). Needs Godot 4.7.2, xvfb-run
# and Python with Pillow. Output: "BUG'S-EYE VIEW/Store Assets/".
#   tools/release/make_store_assets.sh
set -e
cd "$(dirname "$0")/../.."
OUT="BUG'S-EYE VIEW/Store Assets/_renders"
mkdir -p "$OUT"
render() {  # render <WxH> <subdir> [--only=...]
	mkdir -p "$OUT/$2"
	xvfb-run -a -s "-screen 0 3840x2400x24" godot --path . --resolution "$1" \
		res://tools/release/store_art.tscn -- --out="$PWD/$OUT/$2" $3 | grep STORE_ART || true
}
GAMEPLAY="--only=kitchen,dominoes,slap,fridge,trap,bugeye"
render 3840x2160 keyart --only=keyart
render 1024x1024 icon --only=icon
render 1920x1080 1920x1080 "$GAMEPLAY,keyart"
render 2868x1320 iphone-6.9 "$GAMEPLAY"
render 2622x1206 iphone-6.3 "$GAMEPLAY"
render 2752x2064 ipad-13 "$GAMEPLAY"
python3 tools/release/compose_store_assets.py
