#!/usr/bin/env python3
"""Turns a Firebase google-services.json into the Android string resources
Firebase reads at start-up (what Google's google-services Gradle plugin
generates), for the CanopyCrashlytics library. Also adds the Crashlytics
build id that the Crashlytics Gradle plugin would add.

    python3 tools/firebase_values.py google-services.json OUT_DIR/values/firebase_config.xml [package]

The output holds the project's Firebase identifiers (not secrets, but keep
them out of git: the release workflow writes it from a GitHub secret).
"""
import json
import sys
import uuid
from xml.sax.saxutils import escape


def main() -> int:
    src, out = sys.argv[1], sys.argv[2]
    package = sys.argv[3] if len(sys.argv) > 3 else "com.aethertek.canopycrossing"
    cfg = json.load(open(src))
    info = cfg.get("project_info", {})
    client = next((c for c in cfg.get("client", [])
                   if c.get("client_info", {}).get("android_client_info", {}).get("package_name") == package), None)
    if client is None:
        print(f"no Android app for {package} in {src}", file=sys.stderr)
        return 1
    key = (client.get("api_key") or [{}])[0].get("current_key", "")
    values = {
        "google_app_id": client["client_info"]["mobilesdk_app_id"],
        "gcm_defaultSenderId": info.get("project_number", ""),
        "project_id": info.get("project_id", ""),
        "google_storage_bucket": info.get("storage_bucket", ""),
        "google_api_key": key,
        "google_crash_reporting_api_key": key,
        "com.google.firebase.crashlytics.mapping_file_id": uuid.uuid4().hex,
    }
    lines = ['<?xml version="1.0" encoding="utf-8"?>', "<resources>"]
    for k, v in values.items():
        if v:
            lines.append(f'    <string name="{k}" translatable="false">{escape(str(v))}</string>')
    lines.append("</resources>")
    import os
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "w").write("\n".join(lines) + "\n")
    print(f"wrote {out} ({len(values)} values for {package})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
