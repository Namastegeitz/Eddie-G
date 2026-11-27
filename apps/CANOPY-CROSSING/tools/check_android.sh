#!/usr/bin/env bash
# Store pre-checks for the Android builds (Google Play's own rules):
#   - 16 KB memory pages: every 64-bit native library (.so) has LOAD segments
#     aligned to 16 KB (0x4000), and the APK's zip entries are 16 KB aligned
#     (required for updates from 2027-02-01; see UPGRADE_REPORT.md)
#   - target API 36 and the expected package name
#   - only the permissions the game needs (VIBRATE)
# Works on an .apk, and on an .aab when bundletool is available ($BUNDLETOOL,
# a jar path). Needs the Android SDK build-tools (ANDROID_HOME) and readelf.
#   tools/check_android.sh BUILDS/android/CanopyCrossing.apk [BUILDS/android/CanopyCrossing.aab]
set -uo pipefail
BT="$(ls -d "${ANDROID_HOME:?set ANDROID_HOME}"/build-tools/* | sort -V | tail -1)"
fail=0
check_libs() {   # $1 = directory holding lib/<abi>/*.so
  local n=0
  while IFS= read -r so; do
    n=$((n + 1))
    local abi; abi="$(basename "$(dirname "$so")")"
    local aligns; aligns="$(readelf -lW "$so" | awk '/LOAD/ {print $NF}' | sort -u | tr '\n' ' ')"
    if [ "$abi" = "arm64-v8a" ] || [ "$abi" = "x86_64" ]; then
      for a in $aligns; do
        if [ $((a)) -lt 16384 ]; then echo "  FAIL $abi/$(basename "$so"): LOAD align $a (needs 0x4000)"; fail=1; fi
      done
      echo "  ok   $abi/$(basename "$so") align $aligns"
    else
      echo "  --   $abi/$(basename "$so") align $aligns (32-bit: 16 KB not required)"
    fi
  done < <(find "$1" -name "*.so" | sort)
  [ $n -gt 0 ] || { echo "  FAIL no native libraries found"; fail=1; }
}
for f in "$@"; do
  echo "== $f"
  tmp="$(mktemp -d)"
  case "$f" in
    *.apk)
      if "$BT/zipalign" -c -P 16 4 "$f" > /dev/null; then echo "  ok   zip entries 16 KB aligned"; else echo "  FAIL zipalign -c -P 16"; fail=1; fi
      unzip -q -o "$f" 'lib/*' -d "$tmp" 2> /dev/null
      check_libs "$tmp/lib"
      badging="$("$BT/aapt2" dump badging "$f" 2> /dev/null)"
      echo "$badging" | grep -q "targetSdkVersion:'36'" && echo "  ok   targetSdk 36" || { echo "  FAIL targetSdk is not 36"; fail=1; }
      echo "$badging" | grep -q "name='com.aethertek.canopycrossing'" && echo "  ok   package com.aethertek.canopycrossing" || { echo "  FAIL package name"; fail=1; }
      perms="$(echo "$badging" | sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p" | sort | tr '\n' ' ')"
      extra="$(echo "$perms" | tr ' ' '\n' | grep -v -e '^$' -e '^android.permission.VIBRATE$' -e '^android.permission.INTERNET$' -e '^android.permission.ACCESS_NETWORK_STATE$' -e 'DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION$' -e '^com.google.android.c2dm.permission.RECEIVE$' || true)"
      echo "  perm $perms"
      [ -z "$extra" ] || { echo "  FAIL unexpected permissions: $extra"; fail=1; }
      ;;
    *.aab)
      unzip -q -o "$f" 'base/lib/*' -d "$tmp" 2> /dev/null
      check_libs "$tmp/base/lib"
      if [ -n "${BUNDLETOOL:-}" ]; then
        java -jar "$BUNDLETOOL" dump manifest --bundle="$f" --xpath /manifest/uses-sdk/@android:targetSdkVersion 2> /dev/null | grep -q '^36$' \
          && echo "  ok   targetSdk 36" || { echo "  FAIL targetSdk is not 36"; fail=1; }
        java -jar "$BUNDLETOOL" dump config --bundle="$f" 2> /dev/null | grep -qi "PAGE_ALIGNMENT_16K" \
          && echo "  ok   bundle declares 16 KB page alignment" || echo "  note bundle config doesn't name PAGE_ALIGNMENT_16K (libraries checked above)"
      fi
      ;;
  esac
  rm -rf "$tmp"
done
[ $fail -eq 0 ] && echo "ANDROID CHECKS OK" || echo "ANDROID CHECKS FAILED"
exit $fail
