#!/usr/bin/env bash
# Installs the store-build add-ons into a COPY of the game. builds/store_build.sh
# makes that copy; don't run this on game/ itself. The normal web, desktop and
# debug-APK builds stay exactly as they are.
#
#   sentry    Sentry SDK for Godot              crash reports: Android, iOS, Windows, macOS, Linux
#   firebase  Godotx Firebase (Core+Crashlytics) crash reports: Android, iOS
#   review    Godot In-App Review plugin        "rate this game" card: Android, iOS
#
# All three are MIT licensed and free, and so are the Sentry and Firebase free
# plans. Files come from each project's GitHub releases through the `gh` tool,
# signed in (or GH_TOKEN set, as in GitHub Actions).
#
#   tools/store_addons/install_store_addons.sh <project copy> [sentry] [firebase] [review]
#
# Settings come from the environment (never commit them):
#   SENTRY_DSN               your Sentry project's DSN (Sentry stays off without it)
#   FIREBASE_ANDROID_CONFIG  path to google-services.json      (Firebase is skipped without them)
#   FIREBASE_IOS_CONFIG      path to GoogleService-Info.plist
#   GODOT_TEMPLATES          export templates folder (default: ~/.local/share/godot/export_templates/4.7.2.stable)
#
# Versions are pinned. Change them on purpose, then run the tests and a store build.
set -euo pipefail

SENTRY_REPO=getsentry/sentry-godot
SENTRY_TAG="${SENTRY_TAG:-2.5.1}"
FIREBASE_REPO=godot-x/firebase
FIREBASE_TAG="${FIREBASE_TAG:-3.1.0}"
REVIEW_REPO=godot-mobile-plugins/godot-inapp-review
REVIEW_TAG="${REVIEW_TAG:-v5.3}"
GODOT_TEMPLATES="${GODOT_TEMPLATES:-$HOME/.local/share/godot/export_templates/4.7.2.stable}"

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJ="${1:?usage: install_store_addons.sh <project copy> [sentry] [firebase] [review]}"
PROJ="$(cd "$PROJ" && pwd)"
shift
want=("$@")
[ ${#want[@]} -eq 0 ] && want=(sentry firebase review)

if [ "$PROJ" = "$(cd "$HERE/../.." && pwd)" ]; then
  echo "refusing to install into game/ itself: use builds/store_build.sh (it makes a copy)" >&2
  exit 2
fi
command -v gh >/dev/null || { echo "needs the GitHub CLI (gh)" >&2; exit 2; }
command -v unzip >/dev/null || { echo "needs unzip" >&2; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT
PLUGINS=()

# Downloads the one release file whose name matches the pattern (an ERE).
# Prints the release's file list and stops when none or several match.
fetch() {  # repo tag regex dest_dir
  local repo="$1" tag="$2" re="$3" dest="$4" names pick
  names="$(gh release view "$tag" -R "$repo" --json assets -q '.assets[].name')"
  pick="$(printf '%s\n' "$names" | grep -E "$re" || true)"
  if [ -z "$pick" ] || [ "$(printf '%s\n' "$pick" | wc -l)" -ne 1 ]; then
    echo "$repo $tag: expected one file matching /$re/, the release has:" >&2
    printf '  %s\n' $names >&2
    return 1
  fi
  mkdir -p "$dest"
  gh release download "$tag" -R "$repo" -p "$pick" -D "$dest" --clobber >&2
  echo "$dest/$pick"
}

# Unzips into its own empty folder (downloads are untrusted data: nothing in
# them is run; only the plugin folders are copied into the project).
unpack() {  # zip dest
  rm -rf "${2:?}"; mkdir -p "$2"
  unzip -q -o "$1" -d "$2"
}

for w in "${want[@]}"; do
  case "$w" in
    sentry)
      z="$(fetch "$SENTRY_REPO" "$SENTRY_TAG" "^sentry-godot(-gdextension)?-v?${SENTRY_TAG//./\\.}\\.zip$" "$TMP/dl")"
      unpack "$z" "$TMP/sentry"
      src="$(find "$TMP/sentry" -type f -name 'sentry.gdextension' -path '*addons/sentry/*' | head -1)"
      [ -n "$src" ] || { echo "sentry: no addons/sentry/sentry.gdextension in $z" >&2; exit 1; }
      mkdir -p "$PROJ/addons"
      rm -rf "${PROJ:?}/addons/sentry"
      cp -R "$(dirname "$src")" "$PROJ/addons/sentry"
      # Desktop crash handler (Crashpad), shipped as its own package.
      if cz="$(fetch "$SENTRY_REPO" "$SENTRY_TAG" "^sentry-godot-crash-reporter-v?${SENTRY_TAG//./\\.}\\.zip$" "$TMP/dl" 2>/dev/null)"; then
        unpack "$cz" "$TMP/sentry_cr"
        cr="$(find "$TMP/sentry_cr" -type d -name crash_reporter | head -1)"
        [ -n "$cr" ] && cp -R "$cr" "$PROJ/addons/sentry/"
      else
        echo "sentry: no crash-reporter package in $SENTRY_TAG (desktop native crashes won't be caught)"
      fi
      python3 "$HERE/patch_project.py" dsn "$PROJ"
      python3 "$HERE/patch_project.py" internet "$PROJ"
      echo "installed Sentry $SENTRY_TAG" ;;
    firebase)
      if [ ! -s "${FIREBASE_ANDROID_CONFIG:-}" ] || [ ! -s "${FIREBASE_IOS_CONFIG:-}" ]; then
        echo "firebase: skipped (set FIREBASE_ANDROID_CONFIG and FIREBASE_IOS_CONFIG to your Firebase files)"
        continue
      fi
      z="$(fetch "$FIREBASE_REPO" "$FIREBASE_TAG" '[Ff]irebase.*\.zip$' "$TMP/dl")"
      unpack "$z" "$TMP/firebase"
      cfg="$(find "$TMP/firebase" -type f -path '*addons/godotx_firebase/plugin.cfg' | head -1)"
      [ -n "$cfg" ] || { echo "firebase: no addons/godotx_firebase/plugin.cfg in $z" >&2; exit 1; }
      root="$(dirname "$(dirname "$(dirname "$cfg")")")"
      mkdir -p "$PROJ/addons" "$PROJ/android" "$PROJ/ios/plugins"
      rm -rf "${PROJ:?}/addons/godotx_firebase"
      cp -R "$root/addons/godotx_firebase" "$PROJ/addons/"
      for m in firebase_core firebase_crashlytics; do
        [ -d "$root/android/$m" ] && { rm -rf "${PROJ:?}/android/$m"; cp -R "$root/android/$m" "$PROJ/android/"; }
        [ -d "$root/ios/plugins/$m" ] && { rm -rf "${PROJ:?}/ios/plugins/$m"; cp -R "$root/ios/plugins/$m" "$PROJ/ios/plugins/"; }
      done
      cp "$FIREBASE_ANDROID_CONFIG" "$PROJ/google-services.json"
      cp "$FIREBASE_IOS_CONFIG" "$PROJ/GoogleService-Info.plist"
      PLUGINS+=("res://addons/godotx_firebase/plugin.cfg")
      python3 "$HERE/patch_project.py" firebase "$PROJ"
      python3 "$HERE/patch_project.py" internet "$PROJ"
      # Godot's Android build template, then the two Firebase gradle plugins.
      if [ ! -f "$PROJ/android/build/build.gradle" ]; then
        [ -f "$GODOT_TEMPLATES/android_source.zip" ] || { echo "no android_source.zip in $GODOT_TEMPLATES" >&2; exit 1; }
        mkdir -p "$PROJ/android/build"
        unzip -q -o "$GODOT_TEMPLATES/android_source.zip" -d "$PROJ/android/build"
        cp "$GODOT_TEMPLATES/version.txt" "$PROJ/android/.build_version"
        touch "$PROJ/android/build/.gdignore"
      fi
      python3 "$HERE/patch_project.py" gradle "$PROJ"
      echo "installed Firebase $FIREBASE_TAG (Core + Crashlytics)" ;;
    review)
      z="$(fetch "$REVIEW_REPO" "$REVIEW_TAG" '^InappReviewPlugin-Multi-v.*\.zip$' "$TMP/dl")"
      unpack "$z" "$TMP/review"
      cfg="$(find "$TMP/review" -type f -path '*addons/*/plugin.cfg' | head -1)"
      [ -n "$cfg" ] || { echo "review: no addons/*/plugin.cfg in $z" >&2; exit 1; }
      root="$(dirname "$(dirname "$(dirname "$cfg")")")"
      name="$(basename "$(dirname "$cfg")")"
      mkdir -p "$PROJ/addons"
      rm -rf "${PROJ:?}/addons/$name"
      cp -R "$root/addons/$name" "$PROJ/addons/"
      [ -d "$root/ios" ] && { mkdir -p "$PROJ/ios"; cp -R "$root/ios/." "$PROJ/ios/"; }
      PLUGINS+=("res://addons/$name/plugin.cfg")
      echo "installed In-App Review $REVIEW_TAG ($name)" ;;
    *) echo "unknown add-on: $w (sentry, firebase, review)" >&2; exit 2 ;;
  esac
done

if [ ${#PLUGINS[@]} -gt 0 ]; then
  python3 "$HERE/patch_project.py" plugins "$PROJ" "${PLUGINS[@]}"
fi
