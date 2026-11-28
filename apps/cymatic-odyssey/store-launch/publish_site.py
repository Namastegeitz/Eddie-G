"""Assembles the GitHub Pages folder for the app: the built web app (apps/web/dist) plus the big files the app
links to (manual, zips, videos, Android APK, desktop-folder scripts). Output: site-out/cymatic-light-chamber/

    pnpm build && python3 store-launch/publish_site.py [path/to/CymaticLightChamber-1.0.0.apk]
"""
import shutil
import sys
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
OUT = APP / "site-out/cymatic-light-chamber"
FILES = OUT / "files"

if OUT.exists():
    shutil.rmtree(OUT)
shutil.copytree(APP / "apps/web/dist", OUT)
FILES.mkdir()
for pdf in ("CYMATIC_ODYSSEY_Manual.pdf", "CYMATIC_ODYSSEY_Sourcing_Guide.pdf"):
    shutil.copy2(APP / "docs" / pdf, FILES / pdf)
for z in sorted((APP / "downloads").glob("*.zip")):
    shutil.copy2(z, FILES / z.name)
(FILES / "videos").mkdir()
for v in sorted((APP / "marketing/videos").glob("*.mp4")):
    shutil.copy2(v, FILES / "videos" / v.name)
(FILES / "store-launch").mkdir()
for md in ("STEP-BY-STEP.md", "LISTING.md"):
    shutil.copy2(APP / "store-launch" / md, FILES / "store-launch" / md)
for f in (APP / "store-launch/desktop-folder").iterdir():
    shutil.copy2(f, FILES / f.name)
apk = Path(sys.argv[1]) if len(sys.argv) > 1 else APP / "apps/mobile/release/CymaticLightChamber-1.0.0.apk"
if apk.exists():
    (FILES / "android").mkdir()
    shutil.copy2(apk, FILES / "android" / apk.name)
else:
    print("warning: no APK found, the Android download link will be broken")

# every file the desktop-folder manifest lists must exist
missing = [l.split("\t")[0] for l in (FILES / "manifest.txt").read_text().splitlines() if l and not (FILES / l.split("\t")[0]).exists()]
assert not missing, missing
size = sum(f.stat().st_size for f in OUT.rglob("*") if f.is_file())
big = [f for f in OUT.rglob("*") if f.is_file() and f.stat().st_size > 95e6]
assert not big, f"files over GitHub's 100 MB limit: {big}"
print(f"{OUT}: {sum(1 for f in OUT.rglob('*') if f.is_file())} files, {size / 1e6:.0f} MB")
