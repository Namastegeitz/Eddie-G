#!/usr/bin/env bash
# Store builds WITH crash reporting (Sentry + Firebase Crashlytics) and the
# store rating prompt. Copies the game to COSMIC-SAUCER-DRIFT/store-build/game
# (git-ignored), installs the add-ons there, and exports from that copy, so
# game/ and the normal builds (build_all.sh) never change.
#
#   bash COSMIC-SAUCER-DRIFT/builds/store_build.sh [aab] [ios] [windows] [linux] [macos]
#
# Needs: Godot 4.7.2 + export templates, gh (signed in), unzip, zip, python3.
# For aab: JDK 17, the Android SDK (platform 36) and your upload key in
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD.
# Settings (environment only, never commit them):
#   SENTRY_DSN, FIREBASE_ANDROID_CONFIG, FIREBASE_IOS_CONFIG
#   (see stores/CRASH_REPORTING.md). Missing ones just leave that service off.
# STORE_DEBUG=1 exports with the debug key instead (CI uses it to check that
# the gradle build works without your upload key).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="$(cd "$HERE/../game" && pwd)"
STAGE="$HERE/../store-build/game"
GODOT="${GODOT:-godot}"
want=("$@")
[ ${#want[@]} -eq 0 ] && want=(aab ios)

echo "== copying the game to store-build/game"
mkdir -p "$STAGE"
# A fresh copy each time, keeping only the installed add-ons. The import
# cache comes along so the copy doesn't re-import everything.
python3 - "$GAME" "$STAGE" <<'PY'
import fnmatch, os, shutil, sys
src, dst = sys.argv[1], sys.argv[2]
KEEP = ["build", "addons/sentry", "addons/godotx_firebase", "addons/InappReview*", "android", "ios",
        "google-services.json", "GoogleService-Info.plist"]
kept = lambda rel: any(fnmatch.fnmatch(rel, k) for k in KEEP)
for name in os.listdir(dst):
    p = os.path.join(dst, name)
    if name == "addons":
        for sub in os.listdir(p):
            if not kept("addons/" + sub):
                q = os.path.join(p, sub)
                shutil.rmtree(q) if os.path.isdir(q) and not os.path.islink(q) else os.remove(q)
    elif not kept(name):
        shutil.rmtree(p) if os.path.isdir(p) and not os.path.islink(p) else os.remove(p)
def ignore(d, names):
    rel = os.path.relpath(d, src)
    return [n for n in names if kept(n if rel == "." else os.path.join(rel, n).replace(os.sep, "/"))]
shutil.copytree(src, dst, ignore=ignore, dirs_exist_ok=True, symlinks=True)
PY

echo "== installing store add-ons"
addons=(sentry review)
case " ${want[*]} " in *" aab "*|*" ios "*) addons+=(firebase) ;; esac
bash "$GAME/tools/store_addons/install_store_addons.sh" "$STAGE" "${addons[@]}"

ex() { "$GODOT" --headless --path "$STAGE" "$@"; }
mode="--export-release"
[ "${STORE_DEBUG:-0}" = "1" ] && mode="--export-debug"
timeout 900 "$GODOT" --headless --path "$STAGE" --import >/dev/null 2>&1 || true
mkdir -p "$HERE/store"
for w in "${want[@]}"; do
  case "$w" in
    aab)
      [ "$mode" = "--export-release" ] && : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?set it to your upload keystore (or STORE_DEBUG=1)}"
      ex $mode "Android AAB" "$HERE/store/cosmicsaucerdrift-store.aab" ;;
    ios)
      tmp="$(mktemp -d)"; ex $mode "iOS" "$tmp/CosmicSaucerDrift.ipa" || true
      (cd "$tmp" && zip -q -r -9 "$HERE/store/CosmicSaucerDrift-ios-xcode-store.zip" .); rm -rf "${tmp:?}" ;;
    windows)
      tmp="$(mktemp -d)"; ex $mode "Windows Desktop" "$tmp/CosmicSaucerDrift.exe"
      (cd "$tmp" && zip -q -r -9 "$HERE/store/CosmicSaucerDrift-windows-x86_64-store.zip" .); rm -rf "${tmp:?}" ;;
    linux)
      tmp="$(mktemp -d)"; ex $mode "Linux" "$tmp/CosmicSaucerDrift.x86_64"
      (cd "$tmp" && zip -q -r -9 "$HERE/store/CosmicSaucerDrift-linux-x86_64-store.zip" .); rm -rf "${tmp:?}" ;;
    macos)
      ex $mode "macOS" "$HERE/store/CosmicSaucerDrift-macos-universal-store-unsigned.zip" ;;
    *) echo "unknown store build: $w (aab ios windows linux macos)" >&2; exit 2 ;;
  esac
  echo "built store $w"
done
ls -la "$HERE/store"
