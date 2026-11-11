"""Main screen: three bars, the (not yet wired) fuse controls, and the library/batch/discoveries tabs."""

from __future__ import annotations

import threading
from pathlib import Path

from PySide6.QtCore import Qt, QTimer, QUrl
from PySide6.QtGui import QAction, QDesktopServices, QFont, QKeySequence
from PySide6.QtWidgets import (QCheckBox, QComboBox, QFileDialog, QFrame, QGridLayout, QHBoxLayout,
                               QLabel, QMainWindow, QMessageBox, QPushButton, QSizePolicy, QSplitter, QTabWidget,
                               QVBoxLayout, QWidget)

from bml import APP_NAME, __version__
from bml.library import Library
from bml.ui import theme
from bml.ui.library_browser import LibraryBrowser
from bml.ui.prompt_bar import PromptBar
from bml.ui.song_bar import SongBar
from bml.ui.workers import Worker, start

PERSPECTIVES = ["A-on-B", "B-on-A", "Interwoven", "Prompted", "Instrumental fusion",
                "Slowed", "Sped up", "Half-time", "Double-time"]


def _placeholder(title: str, body: str) -> QWidget:
    w = QWidget()
    lay = QVBoxLayout(w)
    lay.setContentsMargins(24, 22, 24, 22)
    t = QLabel(title)
    t.setFont(theme.display_font(18))
    b = QLabel(body)
    b.setObjectName("hint")
    b.setWordWrap(True)
    lay.addWidget(t)
    lay.addWidget(b)
    lay.addStretch(1)
    return w


class MainWindow(QMainWindow):
    def __init__(self, library: Library):
        super().__init__()
        self.lib = library
        self._scan_cancel = threading.Event()
        self._scanning = False
        self.setWindowTitle(f"{APP_NAME}  {__version__}")
        self.resize(1320, 940)

        central = QWidget()
        central.setObjectName("central")
        root = QVBoxLayout(central)
        root.setContentsMargins(22, 16, 22, 10)
        root.setSpacing(12)

        # header
        head = QHBoxLayout()
        name = QLabel("BEHEMOTH'S MOUNTAIN LION")
        name.setFont(theme.display_font(34))
        name.setStyleSheet(f"color: {theme.TEXT}; letter-spacing: 3px;")
        tag = QLabel("two becometh one")
        tag.setObjectName("barTag")
        tag.setFont(theme.display_font(15, QFont.Weight.DemiBold))
        head.addWidget(name)
        head.addSpacing(14)
        head.addWidget(tag, 0, Qt.AlignmentFlag.AlignBottom)
        head.addStretch(1)
        root.addLayout(head)

        # the three bars
        self.bar_a = SongBar(library, "BAR 1", "SONG A")
        self.bar_b = SongBar(library, "BAR 2", "SONG B")
        self.prompt = PromptBar()
        for b in (self.bar_a, self.bar_b):
            b.libraryChanged.connect(self.library_changed)
            b.folderDropped.connect(self.add_library_folder)
            b.songChanged.connect(lambda _s: self._update_fuse_state())

        top = QWidget()
        tl = QVBoxLayout(top)
        tl.setContentsMargins(0, 0, 0, 0)
        tl.setSpacing(10)
        tl.addWidget(self.bar_a)
        tl.addWidget(self.bar_b)
        tl.addWidget(self.prompt)
        tl.addWidget(self._fuse_row())

        # tabs: library / batch / discoveries
        self.browser = LibraryBrowser(library)
        self.browser.loadRequested.connect(self._load_song_into_bar)
        self.browser.pathLoadRequested.connect(lambda p, i: self._bar(i).load_path(Path(p)))
        self.tabs = QTabWidget()
        self.tabs.addTab(self.browser, "LIBRARY")
        self.tabs.addTab(_placeholder("Batch queue", "Point it at a folder (or two) and every pairing is queued, "
                                                     "resumable, with progress per job. Arrives in step 6."), "BATCH")
        self.tabs.addTab(_placeholder("Discoveries", "The scout agent's catalog of free, open-source separation, "
                                                     "voice and mastering tools, with one-click approved swaps. "
                                                     "Arrives in step 7."), "DISCOVERIES")

        split = QSplitter(Qt.Orientation.Vertical)
        split.addWidget(top)
        split.addWidget(self.tabs)
        split.setStretchFactor(0, 0)
        split.setStretchFactor(1, 1)
        split.setChildrenCollapsible(False)
        self.tabs.setMinimumHeight(240)
        root.addWidget(split, 1)
        self.setCentralWidget(central)

        self._build_menu()
        self.status_counts = QLabel()
        self.statusBar().addPermanentWidget(self.status_counts)
        self.statusBar().showMessage(f"Workspace: {library.ws.root}")
        self.refresh_counts()
        QTimer.singleShot(300, self.startup_tasks)

    # ---------------------------------------------------------------- layout pieces
    def _fuse_row(self) -> QWidget:
        box = QFrame()
        box.setObjectName("bar")
        g = QGridLayout(box)
        g.setContentsMargins(16, 12, 16, 12)
        g.setHorizontalSpacing(14)
        g.setVerticalSpacing(8)
        self.fuse_btn = QPushButton("FUSE")
        self.fuse_btn.setObjectName("fuse")
        self.fuse_btn.setFont(theme.display_font(26))
        self.fuse_btn.setEnabled(False)
        self.fuse_btn.setToolTip("The fusion engine is built in step 3")
        g.addWidget(self.fuse_btn, 0, 0, 2, 1)

        persp = QHBoxLayout()
        persp.setSpacing(16)
        lab = QLabel("PERSPECTIVES")
        lab.setObjectName("barTag")
        persp.addWidget(lab)
        self.persp_boxes = []
        for p in PERSPECTIVES:
            cb = QCheckBox(p)
            cb.setChecked(p in ("A-on-B", "B-on-A", "Interwoven"))
            cb.setEnabled(False)
            self.persp_boxes.append(cb)
            persp.addWidget(cb)
        persp.addStretch(1)
        g.addLayout(persp, 0, 1)

        row2 = QHBoxLayout()
        hl = QLabel("HOST")
        hl.setObjectName("barTag")
        self.host = QComboBox()
        self.host.addItems(["Auto - stronger bed", "Song A is the body", "Song B is the body"])
        self.host.setEnabled(False)
        self.play_btn = QPushButton("▶  Preview")
        self.play_btn.setEnabled(False)
        self.fuse_note = QLabel()
        self.fuse_note.setObjectName("hint")
        self.fuse_note.setSizePolicy(QSizePolicy.Policy.Ignored, QSizePolicy.Policy.Preferred)
        row2.addWidget(hl)
        row2.addWidget(self.host)
        row2.addSpacing(12)
        row2.addWidget(self.play_btn)
        row2.addWidget(self.fuse_note, 1)
        g.addLayout(row2, 1, 1)
        self._update_fuse_state()
        return box

    def _update_fuse_state(self) -> None:
        a, b = self.bar_a.song, self.bar_b.song
        if a and b:
            self.fuse_note.setText(f"Ready to pair:  {a.title}  ×  {b.title}    ·    "
                                   "analysis, preview and FUSE are built in steps 2-3")
        else:
            need = " and ".join(x for x, s in (("Song A", a), ("Song B", b)) if not s)
            self.fuse_note.setText(f"Load {need} to pair them    ·    fusion engine arrives in step 3")

    def _build_menu(self) -> None:
        m = self.menuBar().addMenu("&Library")
        act = QAction("Add music folder…", self)
        act.triggered.connect(self._choose_folder)
        m.addAction(act)
        act = QAction("Rescan library folders", self)
        act.setShortcut(QKeySequence("F5"))
        act.triggered.connect(self.scan_all)
        m.addAction(act)
        self.folders_menu = m.addMenu("Library folders")
        self.folders_menu.aboutToShow.connect(self._fill_folders_menu)
        m.addSeparator()
        act = QAction("Open workspace folder", self)
        act.triggered.connect(lambda: QDesktopServices.openUrl(QUrl.fromLocalFile(str(self.lib.ws.root))))
        m.addAction(act)
        m.addSeparator()
        act = QAction("Quit", self)
        act.setShortcut(QKeySequence.StandardKey.Quit)
        act.triggered.connect(self.close)
        m.addAction(act)
        h = self.menuBar().addMenu("&Help")
        h.addAction("About", lambda: QMessageBox.about(
            self, APP_NAME, f"<b>{APP_NAME}</b> {__version__}<br>Free and local. Two becometh one.<br><br>"
                            f"Workspace: {self.lib.ws.root}"))

    def _fill_folders_menu(self) -> None:
        self.folders_menu.clear()
        folders = self.lib.library_folders()
        if not folders:
            a = self.folders_menu.addAction("No folders yet")
            a.setEnabled(False)
        for f in folders:
            sub = self.folders_menu.addMenu(str(f))
            sub.addAction("Remove from library", lambda f=f: self._remove_folder(f))

    # ---------------------------------------------------------------- bars
    def _bar(self, i: int) -> SongBar:
        return self.bar_a if i == 0 else self.bar_b

    def _load_song_into_bar(self, song_id: int, bar: int) -> None:
        s = self.lib.song(song_id)
        if s:
            self._bar(bar).set_song(s, "In the library")

    # ---------------------------------------------------------------- library folders + scanning
    def startup_tasks(self) -> None:
        w = Worker(self.lib.reconcile)
        w.signals.done.connect(lambda _r: self.library_changed())
        start(w)
        self.scan_all()

    def _choose_folder(self) -> None:
        d = QFileDialog.getExistingDirectory(self, "Add a music folder to the library")
        if d:
            self.add_library_folder(Path(d))

    def add_library_folder(self, path: Path) -> None:
        if self.lib.ws.contains(path):
            self.statusBar().showMessage("That folder is inside the workspace - it is already part of the library.", 6000)
            return
        p = self.lib.add_library_folder(path)
        self.statusBar().showMessage(f"Added {p} to your library folders", 4000)
        self.scan_all()

    def _remove_folder(self, path: Path) -> None:
        self.lib.remove_library_folder(path)
        self.refresh_counts()

    def scan_all(self) -> None:
        if self._scanning:
            return
        folders = self.lib.library_folders()
        if not folders:
            return
        self._scanning = True

        def run(progress):
            total = 0
            for f in folders:
                if self._scan_cancel.is_set():
                    break
                if not Path(f).is_dir():
                    continue
                total += self.lib.scan_folder(f, progress=lambda n, name, f=f: progress(n, f"{Path(f).name}: {name}"),
                                              cancel=self._scan_cancel)["found"]
            return total

        w = Worker(run, with_progress=True)
        w.signals.progress.connect(self._scan_progress)
        w.signals.done.connect(self._scan_done)
        w.signals.failed.connect(self._scan_done)
        start(w)

    def _scan_progress(self, n: int, name: str) -> None:
        if n % 25 == 0:
            self.statusBar().showMessage(f"Scanning library folders… {n:,} files  ·  {name}")

    def _scan_done(self, _r) -> None:
        self._scanning = False
        self.statusBar().showMessage(f"Workspace: {self.lib.ws.root}")
        self.refresh_counts()
        for b in (self.bar_a, self.bar_b):  # results typed during the scan now include new files
            if b.edit.hasFocus() and b.edit.text() and not b.song:
                b.refresh_results()

    def library_changed(self) -> None:
        self.browser.refresh()
        self.refresh_counts()

    def refresh_counts(self) -> None:
        c = self.lib.counts()
        self.status_counts.setText(f"OG Bars {c['og']:,}   ·   Remixed {c['remix']:,}   ·   "
                                   f"in your folders {c['files']:,}")

    def closeEvent(self, e) -> None:
        self._scan_cancel.set()
        super().closeEvent(e)
