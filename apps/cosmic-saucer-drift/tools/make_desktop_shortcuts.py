#!/usr/bin/env python3
"""Desktop shortcuts that open the game in the browser, with the space icon.
Writes dist/desktop/ and a zip of it. Run tools/make_icons.py first.

    python3 tools/make_desktop_shortcuts.py [GAME_URL]
"""
import os, stat, sys, zipfile

URL = sys.argv[1] if len(sys.argv) > 1 else "https://claude.ai/artifact/Wjris6Pjst5K54bF6z8MUY"
NAME = "Cosmic Saucer Drift"
APP = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(APP, "dist/desktop")

WIN_BAT = r"""@echo off
rem Puts a "Cosmic Saucer Drift" shortcut with the space icon on your desktop.
rem Double-click the shortcut to open the game in your browser.
set "URL=%s"
set "DIR=%%LOCALAPPDATA%%\Cosmic Saucer Drift"
if not exist "%%DIR%%" mkdir "%%DIR%%"
copy /Y "%%~dp0cosmic-saucer-drift.ico" "%%DIR%%\cosmic-saucer-drift.ico" >nul
for /f "usebackq delims=" %%%%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESK=%%%%D"
if not defined DESK set "DESK=%%USERPROFILE%%\Desktop"
> "%%DESK%%\Cosmic Saucer Drift.url" (
  echo [InternetShortcut]
  echo URL=%%URL%%
  echo IconFile=%%DIR%%\cosmic-saucer-drift.ico
  echo IconIndex=0
)
echo.
echo Done: "Cosmic Saucer Drift" is on your desktop.
echo (If it shows a plain icon for a moment, Windows is still refreshing its icon cache.)
pause
""" % URL

MAC_PLIST = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>%s</string>
	<key>CFBundleDisplayName</key><string>%s</string>
	<key>CFBundleIdentifier</key><string>com.cosmicsaucerdrift.launcher</string>
	<key>CFBundleShortVersionString</key><string>1.0</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleExecutable</key><string>play</string>
	<key>CFBundleIconFile</key><string>AppIcon</string>
	<key>LSUIElement</key><true/>
</dict>
</plist>
""" % (NAME, NAME)

MAC_RUN = """#!/bin/sh
# Opens Cosmic Saucer Drift in the default browser.
open "%s"
""" % URL

LINUX_DESKTOP = """[Desktop Entry]
Type=Application
Name=%s
Comment=Arcade UFO kart racing across real planets and star systems
Exec=xdg-open %s
Icon=cosmic-saucer-drift
Terminal=false
Categories=Game;
""" % (NAME, URL)

LINUX_SH = """#!/bin/sh
# Adds Cosmic Saucer Drift (opens in your browser) to your app menu and desktop.
set -e
cd "$(dirname "$0")"
mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps" "$HOME/.local/share/applications"
cp cosmic-saucer-drift.png "$HOME/.local/share/icons/hicolor/512x512/apps/cosmic-saucer-drift.png"
cp cosmic-saucer-drift.desktop "$HOME/.local/share/applications/"
DESK="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
if [ -d "$DESK" ]; then
  cp cosmic-saucer-drift.desktop "$DESK/"
  chmod +x "$DESK/cosmic-saucer-drift.desktop"
  gio set "$DESK/cosmic-saucer-drift.desktop" metadata::trusted true 2>/dev/null || true
fi
echo "Done: Cosmic Saucer Drift is in your app menu and on your desktop."
"""

README = """COSMIC SAUCER DRIFT - desktop shortcut
=====================================

The game:  %s

Windows
  1. Unzip this folder.
  2. Double-click "Install desktop shortcut (Windows).bat".
  A "Cosmic Saucer Drift" icon (space, planets and nebulas) appears on your
  desktop. Double-click it to play in your browser.

Mac
  1. Unzip "Cosmic Saucer Drift (Mac).zip" and drag "Cosmic Saucer Drift.app"
     to your Desktop or Applications.
  2. The first time, right-click it and choose Open (it isn't from the App
     Store, so macOS asks once). After that, double-click to play.

Linux
  Run:  sh install-linux.sh

Phones
  Android: install the game's APK (dist/android/cosmicsaucerdrift-debug.apk);
  its home-screen icon is the same space picture.
  iPhone: open the link in Safari, tap Share, then "Add to Home Screen".

The link opens a private Claude page, so sign in to claude.ai in that
browser first (or share the page from claude.ai to let others play).
""" % URL


def write(path, text, exe=False, crlf=False):
    data = text.replace("\n", "\r\n") if crlf else text
    with open(path, "w", newline="") as f:
        f.write(data)
    if exe:
        os.chmod(path, os.stat(path).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def main():
    os.makedirs(OUT, exist_ok=True)
    write(os.path.join(OUT, "Install desktop shortcut (Windows).bat"), WIN_BAT, crlf=True)
    write(os.path.join(OUT, "cosmic-saucer-drift.desktop"), LINUX_DESKTOP, exe=True)
    write(os.path.join(OUT, "install-linux.sh"), LINUX_SH, exe=True)
    write(os.path.join(OUT, "README.txt"), README, crlf=True)
    # Mac: a tiny .app that opens the link, zipped with its executable bit.
    mac_zip = os.path.join(OUT, "Cosmic Saucer Drift (Mac).zip")
    app = NAME + ".app/Contents/"
    with zipfile.ZipFile(mac_zip, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr(app + "Info.plist", MAC_PLIST)
        info = zipfile.ZipInfo(app + "MacOS/play")
        info.external_attr = (0o755 | stat.S_IFREG) << 16
        z.writestr(info, MAC_RUN)
        z.write(os.path.join(OUT, "cosmic-saucer-drift.icns"), app + "Resources/AppIcon.icns")
    # Everything in one download.
    bundle = os.path.join(APP, "dist/Cosmic-Saucer-Drift-desktop-shortcut.zip")
    with zipfile.ZipFile(bundle, "w", zipfile.ZIP_DEFLATED) as z:
        for fn in sorted(os.listdir(OUT)):
            p = os.path.join(OUT, fn)
            info = zipfile.ZipInfo("Cosmic Saucer Drift shortcut/" + fn)
            mode = os.stat(p).st_mode
            info.external_attr = (mode & 0o777 | stat.S_IFREG) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            with open(p, "rb") as f:
                z.writestr(info, f.read())
    print("shortcuts written to", OUT, "and", bundle)


if __name__ == "__main__":
    main()
