"""Drives the real widgets headless (QT_QPA_PLATFORM=offscreen)."""

import os
import time

import pytest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
QtWidgets = pytest.importorskip("PySide6.QtWidgets")

from PySide6.QtCore import QMimeData, QPointF, Qt, QThreadPool, QUrl  # noqa: E402
from PySide6.QtGui import QDropEvent  # noqa: E402
from PySide6.QtTest import QTest  # noqa: E402

from bml.ui import theme  # noqa: E402
from bml.ui.main_window import MainWindow  # noqa: E402
from bml.ui.song_bar import HIT_ROLE  # noqa: E402
from conftest import make_wav  # noqa: E402


@pytest.fixture(scope="module")
def app():
    a = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])
    theme.apply(a)
    return a


def wait_until(cond, timeout=5.0):
    end = time.time() + timeout
    while time.time() < end:
        QtWidgets.QApplication.processEvents()
        if cond():
            return True
        QTest.qWait(20)
    return cond()


@pytest.fixture
def win(app, lib, outside):
    make_wav(outside / "a.wav", title="Rebel Yell", artist="Northbound", freq=200)
    make_wav(outside / "b.wav", title="Rejoice", artist="Halcyon Drift", freq=260)
    make_wav(outside / "c.wav", title="Mountain Call", artist="Stone Ridge", freq=330)
    lib.add_library_folder(outside)
    lib.scan_folder(outside)
    w = MainWindow(lib)
    w.show()
    yield w
    w.close()
    QThreadPool.globalInstance().waitForDone(5000)


def rows(bar):
    return [bar.model.index(i, 0).data(HIT_ROLE) for i in range(bar.model.rowCount())]


def test_typing_filters_live_and_loading_files_into_og_bars(win, lib):
    bar = win.bar_a
    bar.edit.setFocus()
    QTest.keyClicks(bar.edit, "re")
    assert wait_until(lambda: bar.model.rowCount() == 2)
    assert bar.completer.popup().isVisible()
    QTest.keyClicks(bar.edit, "j")
    assert wait_until(lambda: [r["title"] for r in rows(bar)] == ["Rejoice"])
    bar._activated(bar.model.index(0, 0))
    assert wait_until(lambda: bar.song is not None)
    assert bar.song.title == "Rejoice" and bar.song.library_path == "OG Bars/R/Halcyon Drift - Rejoice.wav"
    assert bar.card.isVisible() and bar.title.text() == "Rejoice"
    assert "Copied into OG Bars / R" in bar.status.text()
    # the library tree shows it under R
    og = win.browser.og
    r_item = [og.topLevelItem(i) for i in range(og.topLevelItemCount()) if og.topLevelItem(i).text(0).startswith("R")][0]
    assert r_item.childCount() == 1 and r_item.child(0).text(0) == "Rejoice"
    assert "OG Bars 1" in win.status_counts.text()


def test_paste_a_path_into_bar_b(win, outside):
    bar = win.bar_b
    p = outside / "c.wav"
    bar.edit.setText(f'"{p}"')  # Windows "Copy as path" style
    bar.refresh_results()
    first = rows(bar)[0]
    assert first["kind"] == "path"
    bar._activated(bar.model.index(0, 0))
    assert wait_until(lambda: bar.song is not None)
    assert bar.song.title == "Mountain Call" and bar.song.letter == "M"
    assert "Ready to pair" not in win.fuse_note.text()


def test_drop_a_file_onto_a_bar(win, outside):
    bar = win.bar_a
    md = QMimeData()
    md.setUrls([QUrl.fromLocalFile(str(outside / "a.wav"))])
    ev = QDropEvent(QPointF(10, 10), Qt.DropAction.CopyAction, md, Qt.MouseButton.NoButton,
                    Qt.KeyboardModifier.NoModifier)
    bar.dropEvent(ev)
    assert wait_until(lambda: bar.song is not None)
    assert bar.song.title == "Rebel Yell"


def test_both_bars_loaded_and_tree_loads_into_bars(win, lib, outside):
    s1 = lib.import_file(outside / "a.wav").song
    s2 = lib.import_file(outside / "b.wav").song
    win.library_changed()
    win._load_song_into_bar(s1.id, 0)
    win._load_song_into_bar(s2.id, 1)
    assert win.bar_a.song.id == s1.id and win.bar_b.song.id == s2.id
    assert "Ready to pair:  Rebel Yell  ×  Rejoice" in win.fuse_note.text()
    win.bar_a.clear()
    assert win.bar_a.song is None and not win.bar_a.card.isVisible()


def test_no_match_message(win):
    bar = win.bar_a
    bar.edit.setText("qqqzzz")
    bar.refresh_results()
    assert bar.model.rowCount() == 0
    assert 'No matches for "qqqzzz"' in bar.status.text()
