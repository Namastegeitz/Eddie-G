#!/usr/bin/env python3
"""Edits a STORE-BUILD COPY of the game for the store add-ons.

Called by install_store_addons.sh; never point it at game/ itself.

  patch_project.py plugins  <proj> res://addons/x/plugin.cfg ...   enable editor plugins
  patch_project.py firebase <proj>                                  Firebase options on the Android AAB + iOS presets
  patch_project.py internet <proj>                                  INTERNET permission on the Android AAB preset
  patch_project.py dsn      <proj>                                  Sentry DSN from $SENTRY_DSN into content/crash_reporting.json
  patch_project.py gradle   <proj>                                  Firebase gradle plugins in android/build/build.gradle

The DSN is read from the environment, never from the command line, so it
doesn't show up in process lists or logs.
"""
import json
import os
import re
import sys

MARK = "// cosmic-saucer-drift: firebase crashlytics"


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def write(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)


def plugins(proj, paths):
    p = os.path.join(proj, "project.godot")
    s = read(p)
    m = re.search(r'^\[editor_plugins\]\n\nenabled=PackedStringArray\((.*)\)$', s, re.M)
    have = re.findall(r'"([^"]+)"', m.group(1)) if m else []
    for x in paths:
        if x not in have:
            have.append(x)
    line = "enabled=PackedStringArray(%s)" % ", ".join('"%s"' % x for x in have)
    if m:
        s = s[:m.start()] + "[editor_plugins]\n\n" + line + s[m.end():]
    else:
        s = s.rstrip("\n") + "\n\n[editor_plugins]\n\n" + line + "\n"
    write(p, s)
    print("enabled plugins:", ", ".join(have))


def _set_options(proj, preset_name, values):
    p = os.path.join(proj, "export_presets.cfg")
    s = read(p)
    m = re.search(r'^\[preset\.(\d+)\]\n\nname="%s"' % re.escape(preset_name), s, re.M)
    if not m:
        sys.exit("no export preset named %s" % preset_name)
    head = "[preset.%s.options]\n" % m.group(1)
    start = s.index(head) + len(head)
    nxt = s.find("\n[preset.", start)
    end = len(s) if nxt < 0 else nxt + 1
    block = s[start:end]
    for k, v in values.items():
        line = "%s=%s" % (k, v)
        if re.search(r"^%s=.*$" % re.escape(k), block, re.M):
            block = re.sub(r"^%s=.*$" % re.escape(k), line, block, flags=re.M)
        else:
            block = block.rstrip("\n") + "\n" + line + "\n"
    if nxt >= 0 and not block.endswith("\n\n"):
        block = block.rstrip("\n") + "\n\n"
    write(p, s[:start] + block + s[end:])


def _add_excludes(proj, preset_name, patterns):
    p = os.path.join(proj, "export_presets.cfg")
    s = read(p)
    m = re.search(r'^\[preset\.\d+\]\n\nname="%s"(.*?)^exclude_filter="([^"]*)"' % re.escape(preset_name), s, re.M | re.S)
    if not m:
        sys.exit("no exclude_filter for preset %s" % preset_name)
    cur = [x.strip() for x in m.group(2).split(",") if x.strip()]
    for x in patterns:
        if x not in cur:
            cur.append(x)
    s = s[:m.start(2)] + ", ".join(cur) + s[m.end(2):]
    write(p, s)


def firebase(proj):
    # Only Core + Crashlytics; Analytics and Messaging stay off. Privacy-safe
    # defaults: collection starts off and the game turns it on only after
    # the player says yes (scripts/platform/crash_reporting.gd).
    _set_options(proj, "Android AAB", {
        "firebase/android_config_file": '"res://google-services.json"',
        "firebase/enable_core": "true",
        "firebase/enable_analytics": "false",
        "firebase/enable_crashlytics": "true",
        "firebase/enable_messaging": "false",
        "firebase/privacy_safe_defaults": "true",
    })
    _set_options(proj, "iOS", {
        "firebase/ios_config_file": '"res://GoogleService-Info.plist"',
        "firebase/privacy_safe_defaults": "true",
    })
    for name in ("Android AAB", "iOS"):
        _add_excludes(proj, name, ["ios/*", "android/*", "addons/godotx_firebase/*", "build/*"])
    print("firebase export options set (Android AAB, iOS)")


def internet(proj):
    _set_options(proj, "Android AAB", {"permissions/internet": "true", "permissions/access_network_state": "true"})
    print("Android AAB: INTERNET permission on (crash reports need it)")


def dsn(proj):
    value = os.environ.get("SENTRY_DSN", "").strip()
    p = os.path.join(proj, "content", "crash_reporting.json")
    d = json.loads(read(p))
    d.setdefault("sentry", {})["dsn"] = value
    write(p, json.dumps(d, indent="\t", ensure_ascii=False) + "\n")
    print("Sentry DSN:", "set" if value else "EMPTY (Sentry stays off in this build)")


def gradle(proj):
    p = os.path.join(proj, "android", "build", "build.gradle")
    s = read(p)
    if MARK in s:
        print("build.gradle already patched")
        return
    top = (MARK + "\n"
           "buildscript {\n"
           "    repositories {\n"
           "        google()\n"
           "        mavenCentral()\n"
           "    }\n"
           "    dependencies {\n"
           "        classpath 'com.google.gms:google-services:4.4.4'\n"
           "        classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.6'\n"
           "    }\n"
           "}\n\n")
    tail = ("\n" + MARK + "\n"
            "apply plugin: 'com.google.gms.google-services'\n"
            "apply plugin: 'com.google.firebase.crashlytics'\n")
    write(p, top + s.rstrip("\n") + "\n" + tail)
    print("build.gradle patched for Firebase Crashlytics")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    cmd, proj = sys.argv[1], sys.argv[2]
    {"plugins": lambda: plugins(proj, sys.argv[3:]),
     "firebase": lambda: firebase(proj),
     "internet": lambda: internet(proj),
     "dsn": lambda: dsn(proj),
     "gradle": lambda: gradle(proj)}[cmd]()
