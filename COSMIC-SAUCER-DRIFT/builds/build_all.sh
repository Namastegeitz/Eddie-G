#!/usr/bin/env bash
# Rebuild every build into its own folder. Run from anywhere:
#   bash COSMIC-SAUCER-DRIFT/builds/build_all.sh [web|windows|linux|macos|ios|apk|aab ...]
# With no arguments it builds everything this computer can build.
# The Play bundle (aab) also needs the Android SDK platform 36 and your upload
# key in GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="$HERE/../game"
GODOT="${GODOT:-godot}"
want=("$@")
[ ${#want[@]} -eq 0 ] && want=(web windows linux macos ios apk)
ex() { "$GODOT" --headless --path "$GAME" "$@"; }
for w in "${want[@]}"; do
  case "$w" in
    web)
      ex --export-release "Web" "$GAME/build/web/index.html"
      mkdir -p "$HERE/web" && cp "$GAME"/build/web/* "$HERE/web/" ;;
    windows)
      tmp="$(mktemp -d)"; ex --export-release "Windows Desktop" "$tmp/CosmicSaucerDrift.exe"
      (cd "$tmp" && zip -q -9 "$HERE/windows/CosmicSaucerDrift-windows-x86_64.zip.new" CosmicSaucerDrift.exe)
      mv "$HERE/windows/CosmicSaucerDrift-windows-x86_64.zip.new" "$HERE/windows/CosmicSaucerDrift-windows-x86_64.zip"; rm -r "$tmp" ;;
    linux)
      tmp="$(mktemp -d)"; ex --export-release "Linux" "$tmp/CosmicSaucerDrift.x86_64"
      (cd "$tmp" && zip -q -9 "$HERE/linux/CosmicSaucerDrift-linux-x86_64.zip.new" CosmicSaucerDrift.x86_64)
      mv "$HERE/linux/CosmicSaucerDrift-linux-x86_64.zip.new" "$HERE/linux/CosmicSaucerDrift-linux-x86_64.zip"; rm -r "$tmp" ;;
    macos)
      ex --export-release "macOS" "$HERE/macos/CosmicSaucerDrift-macos-universal-unsigned.zip" ;;
    ios)
      tmp="$(mktemp -d)"; ex --export-release "iOS" "$tmp/CosmicSaucerDrift.ipa" || true
      rm -f "$HERE/ios-xcode/CosmicSaucerDrift-ios-xcode.zip" "$HERE"/ios-xcode/CosmicSaucerDrift-ios-xcode.z0*
      (cd "$tmp" && zip -q -r -9 -s 60m "$HERE/ios-xcode/CosmicSaucerDrift-ios-xcode.zip" .); rm -r "$tmp" ;;
    apk)
      ex --export-debug "Android" "$HERE/android-apk-debug/cosmicsaucerdrift-debug.apk" ;;
    aab)
      : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?set it to your upload keystore}"
      ex --export-release "Android AAB" "$HERE/android-aab-release/cosmicsaucerdrift-release.aab" ;;
    *) echo "unknown build: $w" >&2; exit 2 ;;
  esac
  echo "built $w"
done
