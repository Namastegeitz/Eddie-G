"""Render screenshots of the main screen from a throwaway demo library.

    python tools/snapshot.py OUT_DIR [extra media files to drop in the demo "Downloads" folder ...]

Runs headless (QT_QPA_PLATFORM=offscreen). The demo tracks are short generated tones with
invented titles - nothing real is copied anywhere except into the throwaway workspace.
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
import time
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tests"))

from PySide6.QtCore import QPoint, QThreadPool  # noqa: E402
from PySide6.QtGui import QPainter, QPixmap  # noqa: E402
from PySide6.QtTest import QTest  # noqa: E402
from PySide6.QtWidgets import QApplication  # noqa: E402

from bml.library import Library  # noqa: E402
from bml.ui import theme  # noqa: E402
from bml.ui.main_window import MainWindow  # noqa: E402
from bml.ui.notice import RightsNotice  # noqa: E402
from bml.workspace import ensure_workspace  # noqa: E402
from conftest import make_wav  # noqa: E402

DEMO = [  # (title, artist, album) - invented
    ("Rebel Heart", "Iron Valley", "Ridge Lines"), ("Rejoice in the Static", "Halcyon Drift", "Lowlands"),
    ("Red Canyon", "Nightfall Choir", None), ("Afterglow Engine", "Cold Front", "Embers"),
    ("Ashes on the Mesa", "Sierra Vane", None), ("Black Pine", "Iron Valley", "Ridge Lines"),
    ("Born in the Mountains", "Tall Grass Union", "Altitude"), ("Copper Sun", "Halcyon Drift", "Lowlands"),
    ("Dust Devil", "Mara Quill", None), ("Echo Basin", "Nightfall Choir", "Hollow"),
    ("Granite Hymn", "Sierra Vane", "Stone"), ("Lionheart Parade", "The Talus Kids", None),
    ("Midnight Switchback", "Cold Front", "Embers"), ("Rebound", "Mara Quill", "Elastic"),
    ("Rise of the Behemoth", "Tall Grass Union", "Altitude"), ("Timberline", "The Talus Kids", None),
    ("99 Peaks", "Sierra Vane", "Stone"), ("Wildfire Gospel", "Halcyon Drift", "Lowlands"),
]


def wait(cond, timeout=8.0):
    end = time.time() + timeout
    while time.time() < end and not cond():
        QApplication.processEvents()
        QTest.qWait(20)


def grab_with_popups(win, popups) -> QPixmap:
    pm = win.grab()
    p = QPainter(pm)
    for pop in popups:
        if pop.isVisible():
            p.drawPixmap(win.mapFromGlobal(pop.mapToGlobal(QPoint(0, 0))), pop.grab())
    p.end()
    return pm


def main() -> None:
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    extras = [Path(a) for a in sys.argv[2:]]
    tmp = Path(tempfile.mkdtemp(prefix="bml-demo-"))
    music, downloads = tmp / "Music", tmp / "Downloads"
    for i, (t, a, al) in enumerate(DEMO):
        make_wav((music if i % 3 else downloads) / f"track{i:02d}.wav", t, a, al, freq=110 + i * 17, seconds=2.5 + i)
    for e in extras:
        shutil.copy2(e, downloads / e.name)

    app = QApplication([])
    theme.apply(app)
    ws = ensure_workspace(tmp / "Desktop" / "Behemoth's Mountain Lion")
    lib = Library(ws)
    lib.set_meta("rights_notice_accepted_at", "demo")
    for f in (music, downloads):
        lib.add_library_folder(f)
        lib.scan_folder(f)
    for i in (0, 3, 6, 9, 10, 11, 14, 16):  # some already filed in OG Bars
        lib.import_file((music if i % 3 else downloads) / f"track{i:02d}.wav")

    win = MainWindow(lib)
    win.resize(1440, 1040)
    win.show()
    wait(lambda: False, 1.0)

    # 1) typing into Bar 1: live results from OG Bars and the library folders
    win.bar_a.edit.setFocus()
    QTest.keyClicks(win.bar_a.edit, "re", delay=30)
    wait(lambda: win.bar_a.completer.popup().isVisible())
    wait(lambda: False, 0.3)
    grab_with_popups(win, [win.bar_a.completer.popup()]).save(str(out / "1-bar1-live-search.png"))

    # 2) load a hit, then paste a path into Bar 2 (the user's own file if given)
    win.bar_a._activated(win.bar_a.model.index(0, 0))  # top hit
    wait(lambda: win.bar_a.song is not None)
    target = downloads / extras[0].name if extras else music / "track07.wav"
    win.bar_b.edit.setFocus()
    win.bar_b.edit.setText(str(target))
    win.bar_b.refresh_results()
    wait(lambda: False, 0.3)
    grab_with_popups(win, [win.bar_b.completer.popup()]).save(str(out / "2-bar2-paste-path.png"))
    win.bar_b._activated(win.bar_b.model.index(0, 0))
    wait(lambda: win.bar_b.song is not None)
    win.prompt.edit.setPlainText('Borat-style vocals for "I was born in the mountains", verse only, enter at 0:42')
    for i in range(win.browser.og.topLevelItemCount()):
        it = win.browser.og.topLevelItem(i)
        it.setExpanded(it.childCount() > 0)
    win.bar_a.edit.clearFocus()
    win.bar_b.edit.clearFocus()
    wait(lambda: False, 0.4)
    win.grab().save(str(out / "3-both-loaded-library-tree.png"))

    # 3) first-run notice
    dlg = RightsNotice(str(ws.root))
    dlg.show()
    wait(lambda: False, 0.3)
    dlg.grab().save(str(out / "0-first-run-notice.png"))
    dlg.close()

    # folder tree as text
    lines = []
    for p in sorted(ws.root.rglob("*")):
        rel = p.relative_to(ws.root)
        if any(part.startswith("Library.db-") for part in rel.parts):
            continue
        if p.is_dir() and p.parent == ws.og_bars and not any(p.iterdir()):
            continue  # empty letter folders summarised below
        lines.append("    " * len(rel.parts) + rel.parts[-1] + ("/" if p.is_dir() else ""))
    empty = [d.name for d in sorted(ws.og_bars.iterdir()) if d.is_dir() and not any(d.iterdir())]
    (out / "workspace-tree.txt").write_text(
        f"{ws.root.name}/\n" + "\n".join(lines) + f"\n\n(empty letter folders, created and ready: {' '.join(empty)})\n",
        encoding="utf-8")
    print("song A:", win.bar_a.song.display, "|", win.bar_a.song.library_path)
    print("song B:", win.bar_b.song.display, "|", win.bar_b.song.library_path)
    print("counts:", lib.counts())
    win.close()
    QThreadPool.globalInstance().waitForDone(5000)


if __name__ == "__main__":
    main()
