#!/bin/bash
# Builds every platform into its own folder under BUILDS/:
#   BUILDS/web      the web version (what beta testers play), zipped too
#   BUILDS/windows  CanopyCrossing-Windows-x86_64.zip  (Steam, GOG, itch.io, Epic, Microsoft Store)
#   BUILDS/macos    CanopyCrossing-macOS.zip           (universal .app; unsigned until notarized)
#   BUILDS/linux    CanopyCrossing-Linux-x86_64.zip    (Steam, GOG, itch.io)
#   BUILDS/ios      CanopyCrossing-iOS-XcodeProject.zip (finish on a Mac: Xcode archive -> App Store Connect)
#   BUILDS/android  CanopyCrossing.apk / .aab          (needs the Android SDK; GitHub Actions has it)
# Each folder gets a BUILD_INFO.json (version, commit, files, sizes, sha256).
#
#   tools/build_all.sh                 # every platform this machine can build
#   tools/build_all.sh windows linux   # just these
#
# Needs Godot 4.7.2 and its export templates (Windows, macOS, iOS, Android,
# Linux, Web). GitHub Actions runs this too: .github/workflows/canopy-crossing-release.yml
set -u
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
ALL="web windows macos linux ios android"
WANT=${*:-$ALL}
LOG=build/build_all
mkdir -p "$LOG"
VERSION=$(sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)
BUILD=$(sed -n 's/^version\/code=\([0-9]*\)/\1/p' export_presets.cfg | head -1)
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
status=0

info() {  # platform status notes files...
  local plat=$1 st=$2 notes=$3; shift 3
  python3 - "$plat" "$st" "$notes" "$VERSION" "$BUILD" "$COMMIT" "$@" <<'PY'
import hashlib, json, os, sys, datetime
plat, st, notes, ver, build, commit, *files = sys.argv[1:]
out = []
for f in files:
    if os.path.isfile(f):
        h = hashlib.sha256()
        with open(f, "rb") as fh:
            for chunk in iter(lambda: fh.read(1 << 20), b""):
                h.update(chunk)
        out.append({"file": os.path.basename(f), "bytes": os.path.getsize(f), "sha256": h.hexdigest()})
info = {"platform": plat, "status": st, "version": ver, "build": int(build or 0), "commit": commit,
        "built_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "godot": "4.7.2", "files": out, "notes": notes}
json.dump(info, open(f"BUILDS/{plat}/BUILD_INFO.json", "w"), indent=2)
print(f"{plat}: {st} " + ", ".join(f"{o['file']} {o['bytes']/1e6:.1f} MB" for o in out))
PY
}

export_preset() {  # preset output log [extra godot flags]
  "$GODOT" --headless --path . ${4:-} --export-release "$1" "$2" > "$3" 2>&1
  local rc=$?
  if [ $rc -ne 0 ] || grep -q "Project export for preset .* failed" "$3"; then
    grep -E "ERROR|failed|Invalid" "$3" | head -5
    return 1
  fi
  return 0
}

clean() {  # keep the folder's README.md and BUILD_INFO.json, drop old game files
  find "BUILDS/$1" -mindepth 1 ! -name README.md ! -name BUILD_INFO.json -exec rm -rf {} + 2>/dev/null
  mkdir -p "BUILDS/$1"
}

for p in $WANT; do
  echo "== $p"
  case $p in
    web)
      clean web
      if tools/build_web.sh > "$LOG/web.log" 2>&1; then
        cp -r build/web_artifact/. BUILDS/web/
        (cd build/web_artifact && zip -qr ../../BUILDS/web/CanopyCrossing-Web.zip .)
        info web built "Open canopy-crossing.html through a web server (the testers' link serves it). Same files as the live beta link." BUILDS/web/CanopyCrossing-Web.zip
      else
        tail -5 "$LOG/web.log"; info web failed "tools/build_web.sh failed: see build/build_all/web.log"; status=1
      fi ;;
    windows)
      clean windows
      if export_preset "Windows Desktop" BUILDS/windows/CanopyCrossing.exe "$LOG/windows.log"; then
        (cd BUILDS/windows && zip -q CanopyCrossing-Windows-x86_64.zip CanopyCrossing.exe && rm CanopyCrossing.exe)
        info windows built "One file, the game data is inside the .exe. Not code-signed yet (Windows SmartScreen will warn until it is)." BUILDS/windows/CanopyCrossing-Windows-x86_64.zip
      else info windows failed "export failed: see build/build_all/windows.log"; status=1; fi ;;
    macos)
      clean macos
      if export_preset "macOS" BUILDS/macos/CanopyCrossing-macOS.zip "$LOG/macos.log"; then
        info macos built "Universal (Apple silicon + Intel) .app in a zip. Not signed or notarized: macOS will refuse to open it normally until it is (needs an Apple Developer account)." BUILDS/macos/CanopyCrossing-macOS.zip
      else info macos failed "export failed: see build/build_all/macos.log"; status=1; fi ;;
    linux)
      clean linux
      if export_preset "Linux" BUILDS/linux/CanopyCrossing.x86_64 "$LOG/linux.log"; then
        (cd BUILDS/linux && chmod +x CanopyCrossing.x86_64 && zip -q CanopyCrossing-Linux-x86_64.zip CanopyCrossing.x86_64 && rm CanopyCrossing.x86_64)
        info linux built "One file, the game data is inside. Runs on 64-bit Linux with OpenGL 3.3 (and Steam Deck)." BUILDS/linux/CanopyCrossing-Linux-x86_64.zip
      else info linux failed "export failed: see build/build_all/linux.log"; status=1; fi ;;
    ios)
      clean ios
      mkdir -p build/ios_project
      rm -rf build/ios_project/*
      if export_preset "iOS" build/ios_project/CanopyCrossing.ipa "$LOG/ios.log"; then
        (cd build/ios_project && zip -qry ../../BUILDS/ios/CanopyCrossing-iOS-XcodeProject.zip .)
        if ls build/ios_project/*.ipa > /dev/null 2>&1; then
          cp build/ios_project/*.ipa BUILDS/ios/
          info ios built "Signed .ipa built on a Mac, ready for App Store Connect." BUILDS/ios/*.ipa BUILDS/ios/CanopyCrossing-iOS-XcodeProject.zip
        else
          info ios project "Xcode project (built on Linux). Finish on a Mac or a cloud Mac: open CanopyCrossing.xcodeproj, set your Team, Product > Archive, upload to App Store Connect." BUILDS/ios/CanopyCrossing-iOS-XcodeProject.zip
        fi
      else info ios failed "export failed: see build/build_all/ios.log"; status=1; fi ;;
    android)
      clean android
      ok=1
      export_preset "Android" BUILDS/android/CanopyCrossing.apk "$LOG/android.log" || ok=0
      if [ $ok -eq 1 ] && [ -n "${ANDROID_AAB:-}" ]; then
        # the Play Store bundle is a Gradle build: Godot installs its Android build template first
        export_preset "Android AAB" BUILDS/android/CanopyCrossing.aab "$LOG/android_aab.log" --install-android-build-template || ok=0
      fi
      if [ $ok -eq 1 ]; then
        info android built "APK installs directly on phones. Google Play needs the .aab (set ANDROID_AAB=1; GitHub Actions does)." BUILDS/android/CanopyCrossing.apk BUILDS/android/CanopyCrossing.aab
      elif grep -q "Android SDK" "$LOG/android.log"; then
        info android needs-sdk "This machine has no Android SDK (its network can't reach Google's download server). GitHub Actions builds the APK and the Play Store .aab: run 'Canopy Crossing release builds'."
      else info android failed "export failed: see build/build_all/android.log"; status=1; fi ;;
    *) echo "unknown platform $p (one of: $ALL)"; status=1 ;;
  esac
done
exit $status
