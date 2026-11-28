#!/usr/bin/env bash
# Builds the CanopyCrashlytics Android library into addons/canopy_crashlytics/bin/.
#   tools/build_crashlytics.sh [google-services.json]
# With a Firebase config, the library carries it and Crashlytics starts in the
# app; without one it is built empty and stays off. Needs the Android SDK
# (ANDROID_HOME) and Gradle 8.13+ (or the runner's gradle). Extra Gradle
# arguments can go in GRADLE_ARGS (e.g. an init script for a Maven mirror).
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=android_plugins/crashlytics
RES="$SRC/plugin/src/main/res/values/firebase_config.xml"
rm -f "$RES"
if [ "${1:-}" != "" ]; then
  python3 tools/firebase_values.py "$1" "$RES"
fi
[ -n "${ANDROID_HOME:-}" ] && echo "sdk.dir=$ANDROID_HOME" > "$SRC/local.properties"
# the project's own Gradle wrapper (8.14.3), unless GRADLE names another
GRADLE="${GRADLE:-$SRC/gradlew}"
"$GRADLE" --no-daemon -q -p "$SRC" ${GRADLE_ARGS:-} :plugin:assembleRelease
mkdir -p addons/canopy_crashlytics/bin
cp "$SRC/plugin/build/outputs/aar/plugin-release.aar" addons/canopy_crashlytics/bin/CanopyCrashlytics-release.aar
rm -f "$RES"
echo "CRASHLYTICS LIBRARY OK: addons/canopy_crashlytics/bin/CanopyCrashlytics-release.aar ($( [ -n "${1:-}" ] && echo 'with Firebase config' || echo 'no config: stays off'))"
