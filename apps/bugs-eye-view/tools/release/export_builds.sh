#!/usr/bin/env bash
# Exports every platform and puts each build in its own folder under
# "BUG'S-EYE VIEW/Builds/<Platform>/". Needs Godot 4.7.2 with export templates;
# the Android APK also needs the Android SDK (ANDROID_HOME) and Java 17+.
#   tools/release/export_builds.sh
set -e
cd "$(dirname "$0")/../.."
OUT="BUG'S-EYE VIEW/Builds"
mkdir -p build/{windows,macos,linux,web,android,ios} "$OUT"/{Windows,macOS,Linux,Web,Android,iOS}
ex() { echo "== $1"; godot --headless --path . "$2" "$1" "$3" > "build/export-${1// /_}.log" 2>&1; ls -la "$3"; }
ex "Windows Desktop" --export-release build/windows/BugsEyeView.exe
ex "Linux" --export-release build/linux/BugsEyeView.x86_64
ex "macOS" --export-release build/macos/BugsEyeView.zip
ex "Web" --export-release build/web/index.html
ex "Android" --export-debug build/android/BugsEyeView-test.apk
rm -f "${OUT:?}/Windows/BugsEyeView-windows.zip" "${OUT:?}/Linux/BugsEyeView-linux.zip" "${OUT:?}/Web/BugsEyeView-web.zip"
(cd build/windows && zip -9 -q "../../$OUT/Windows/BugsEyeView-windows.zip" BugsEyeView.exe)
(cd build/linux && zip -9 -q "../../$OUT/Linux/BugsEyeView-linux.zip" BugsEyeView.x86_64)
cp build/macos/BugsEyeView.zip "$OUT/macOS/BugsEyeView-macos.zip"
(cd build/web && zip -9 -q "../../$OUT/Web/BugsEyeView-web.zip" index.html index.js index.wasm index.pck \
	index.audio.worklet.js index.audio.position.worklet.js index.png index.icon.png index.apple-touch-icon.png)
cp build/android/BugsEyeView-test.apk "$OUT/Android/BugsEyeView-test.apk"
ls -la "$OUT"/*/
# GitHub refuses files over 100 MB.
find "$OUT" -type f -size +95M -exec echo "TOO BIG FOR GITHUB: {}" \;
