#!/usr/bin/env python3
"""Packages build/web (Godot's Web export) for hosts that cap file size at
15 MB and only serve common web file types (e.g. a claude.ai artifact):
splits index.wasm into three parts, renames index.pck to a served
extension (in parts too when it is over 14 MB, as with the detailed
models), and copies the custom page that stitches them back together.

    godot --headless --path . --export-release "Web" build/web/index.html
    python3 tools/web_artifact/package.py build/web build/web_artifact

Then publish build/web_artifact/canopy-crossing.html with the other files
in that folder alongside it. Any static host also works with build/web as-is.

With --site it also builds a public beta site for phone testers (GitHub Pages):

    python3 tools/web_artifact/package.py build/web build/site --site [--apk build/android/canopycrossing.apk]

    build/site/index.html                      -> sends visitors to canopy-crossing/
    build/site/canopy-crossing/index.html      tester page: play, add to home screen, Android APK
    build/site/canopy-crossing/play.html       the game, installable (manifest, icons, iPhone tags)
"""
import json, os, re, shutil, subprocess, sys, time

args = [x for x in sys.argv[1:] if not x.startswith("--")]
site = "--site" in sys.argv
apk = ""
for i, x in enumerate(sys.argv):
    if x == "--apk" and i + 1 < len(sys.argv):
        apk = sys.argv[i + 1]
        args = [y for y in args if y != apk]
src, dst = args[0], args[1]
if site:
    root = dst
    dst = os.path.join(root, "canopy-crossing")
here = os.path.dirname(os.path.abspath(__file__))
os.makedirs(dst, exist_ok=True)
for f in ["index.js", "index.audio.worklet.js", "index.audio.position.worklet.js", "index.png"]:
    shutil.copy(os.path.join(src, f), dst)
pck = open(os.path.join(src, "index.pck"), "rb").read()
LIMIT = 14 * 1024 * 1024
n_pck = max(1, -(-len(pck) // LIMIT))
pck_names = ["index-gamedata.wasm"] if n_pck == 1 else ["index-gamedata%d.wasm" % i for i in range(n_pck)]
psize = -(-len(pck) // n_pck)
for old in os.listdir(dst):
    if old.startswith("index-gamedata"):
        os.remove(os.path.join(dst, old))
for i, nm in enumerate(pck_names):
    open(os.path.join(dst, nm), "wb").write(pck[i * psize:(i + 1) * psize])
wasm = open(os.path.join(src, "index.wasm"), "rb").read()
size = -(-len(wasm) // 3)
for i in range(3):
    open(os.path.join(dst, "index.part%d.wasm" % i), "wb").write(wasm[i * size:(i + 1) * size])
page = open(os.path.join(here, "canopy-crossing.html")).read()
page = re.sub(r'"index\.pck": \[[^\]]*\]', '"index.pck": ' + json.dumps(pck_names), page)
sizes = {"index.pck": os.path.getsize(os.path.join(src, "index.pck")), "index.wasm": len(wasm)}
page = re.sub(r'"fileSizes":\{[^}]*\}', '"fileSizes":' + json.dumps(sizes, separators=(",", ":")), page)
page = re.sub(r'const SIZES = \{[^}]*\};', 'const SIZES = ' + json.dumps(sizes, separators=(",", ":")) + ';', page)
try:
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=here, capture_output=True, text=True).stdout.strip()
except OSError:
    commit = ""
stamp = time.strftime("%Y-%m-%d") + (" - " + commit if commit else "")
page = page.replace('<div id="build">Build dev</div>', '<div id="build">Build ' + stamp + '</div>')
open(os.path.join(dst, "canopy-crossing.html"), "w").write(page)

if site:
    # the game page, installable to a home screen on Android and iPhone
    pwa = ('<link rel="manifest" href="manifest.webmanifest">\n'
           '<link rel="apple-touch-icon" href="icons/icon_180.png">\n'
           '<meta name="theme-color" content="#0c2618">\n'
           '<meta name="mobile-web-app-capable" content="yes">\n'
           '<meta name="apple-mobile-web-app-capable" content="yes">\n'
           '<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">\n'
           '<meta name="apple-mobile-web-app-title" content="Canopy">\n')
    play = page.replace('<meta name="claude:viewport-fit-sides" content="cover">\n', pwa, 1)
    open(os.path.join(dst, "play.html"), "w").write(play)
    shutil.copytree(os.path.join(here, "icons"), os.path.join(dst, "icons"), dirs_exist_ok=True)
    manifest = {
        "name": "Canopy Crossing (beta)", "short_name": "Canopy",
        "description": "Hop real jungle animals across rivers, roads and dense canopy.",
        "start_url": "play.html", "scope": "./", "display": "fullscreen", "orientation": "portrait",
        "background_color": "#0c2618", "theme_color": "#0c2618",
        "icons": [
            {"src": "icons/icon_192.png", "sizes": "192x192", "type": "image/png"},
            {"src": "icons/icon_512.png", "sizes": "512x512", "type": "image/png"},
            {"src": "icons/icon_maskable_512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"},
        ],
    }
    json.dump(manifest, open(os.path.join(dst, "manifest.webmanifest"), "w"), indent=2)
    beta = open(os.path.join(here, "beta.html")).read().replace("{{BUILD}}", stamp)
    if apk:
        shutil.copy(apk, os.path.join(dst, "CanopyCrossing-beta.apk"))
        mb = round(os.path.getsize(apk) / 1048576)
        beta = beta.replace("<!--APK-->", (
            '<a class="btn" href="CanopyCrossing-beta.apk" download>Download the Android app (APK, %d MB)</a>\n'
            '      <ol>\n'
            '        <li>Tap the button above and let the file download.</li>\n'
            '        <li>Open it from your notifications or Downloads. If Android asks, allow your browser to <kbd>Install unknown apps</kbd>.</li>\n'
            '        <li>Tap <kbd>Install</kbd>, then <kbd>Open</kbd>.</li>\n'
            '      </ol>\n'
            '      <p class="small">New beta builds install over the old one. If Android says the app isn\'t installed, uninstall the old Canopy Crossing first.</p>' % mb))
    # opened from a home screen: go straight to the game
    beta = beta.replace("<script>", "<script>\nif ((window.matchMedia && matchMedia('(display-mode: fullscreen), (display-mode: standalone)').matches) || navigator.standalone) location.replace('play.html');\n", 1)
    open(os.path.join(dst, "index.html"), "w").write(beta)
    open(os.path.join(root, "index.html"), "w").write(
        '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
        '<title>Canopy Crossing beta</title><meta http-equiv="refresh" content="0; url=canopy-crossing/">'
        '<a href="canopy-crossing/">Canopy Crossing beta</a>\n')
    open(os.path.join(root, ".nojekyll"), "w").write("")
    print("beta site in", root, "(apk: %s)" % ("yes" if apk else "no"))
print("packaged into", dst)
