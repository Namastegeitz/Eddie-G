#!/usr/bin/env bash
# Builds the phone apps for Monkey See, Monkey Do.
#
#   scripts/build_mobile.sh            web bundle + copy into both apps (+ Android debug APK if the SDK is installed)
#   scripts/build_mobile.sh release    also the Google Play bundle (.aab), signed if keystore.properties exists
#
# Android needs: Node 22+, JDK 21, Android SDK (ANDROID_HOME or android/local.properties).
# iOS needs a Mac with Xcode: after this script, run `npx cap open ios` in mobile/ and press Run,
# or build in the cloud with mobile/ci/codemagic.yaml.
set -euo pipefail
cd "$(dirname "$0")/.."
APP_DIR="$(pwd)"

echo "== tests"
node tests/unit.mjs

echo "== web bundle (dist/www)"
python3 scripts/build_sw.py >/dev/null
node scripts/build_web.mjs

echo "== copy into the iOS and Android projects"
cd mobile
[ -d node_modules ] || npm ci --no-audit --no-fund
npx cap sync

if [ -n "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" ] || [ -f android/local.properties ]; then
  echo "== Android debug APK"
  (cd android && ./gradlew --no-daemon assembleDebug)
  mkdir -p "$APP_DIR/dist/android"
  cp android/app/build/outputs/apk/debug/app-debug.apk "$APP_DIR/dist/android/monkey-see-monkey-do-debug.apk"
  echo "   -> dist/android/monkey-see-monkey-do-debug.apk"
  if [ "${1:-}" = "release" ]; then
    echo "== Android release bundle (Google Play)"
    (cd android && ./gradlew --no-daemon bundleRelease)
    cp android/app/build/outputs/bundle/release/app-release.aab "$APP_DIR/dist/android/monkey-see-monkey-do-release.aab"
    echo "   -> dist/android/monkey-see-monkey-do-release.aab"
  fi
else
  echo "!! Android SDK not found (set ANDROID_HOME). Skipped the APK. The Android project is ready in mobile/android."
fi

if [ "$(uname)" = "Darwin" ]; then
  echo "== iOS: open mobile/ios/App/App.xcodeproj in Xcode (npx cap open ios), pick your team, press Run."
fi
