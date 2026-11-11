"""Library browser: the OG Bars A-Z tree and the Remixed tree, side by side."""

from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor
from PySide6.QtWidgets import QMenu, QSplitter, QTreeWidget, QTreeWidgetItem

from bml.filing import is_media
from bml.library import Library
from bml.ui import theme
from bml.ui.song_bar import fmt_duration, reveal_in_folder
from bml.workspace import LETTER_FOLDERS, OTHER_FOLDER

SONG_ROLE = Qt.ItemDataRole.UserRole + 1
PATH_ROLE = Qt.ItemDataRole.UserRole + 2


class LibraryBrowser(QSplitter):
    loadRequested = Signal(int, int)  # song id, bar (0 = Song A, 1 = Song B)
    pathLoadRequested = Signal(str, int)  # a Remixed file for a second pass, bar

    def __init__(self, library: Library, parent=None):
        super().__init__(Qt.Orientation.Horizontal, parent)
        self.lib = library
        self.og = self._tree(["OG BARS  ·  A–Z", "ARTIST", "TIME"])
        self.og.setObjectName("ogTree")
        self.remixed = self._tree(["REMIXED  ·  PAIRS", "TYPE"])
        self.remixed.setObjectName("remixedTree")
        self.addWidget(self.og)
        self.addWidget(self.remixed)
        self.setSizes([620, 420])
        self.og.itemDoubleClicked.connect(self._og_double)
        self.og.customContextMenuRequested.connect(self._og_menu)
        self.remixed.customContextMenuRequested.connect(self._remixed_menu)
        self.refresh()

    def _tree(self, headers: list[str]) -> QTreeWidget:
        t = QTreeWidget()
        t.setHeaderLabels(headers)
        t.setAlternatingRowColors(True)
        t.setRootIsDecorated(True)
        t.setUniformRowHeights(True)
        t.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        t.header().setStretchLastSection(False)
        t.header().setSectionResizeMode(0, t.header().ResizeMode.Stretch)
        for col in range(1, len(headers)):
            t.header().setSectionResizeMode(col, t.header().ResizeMode.ResizeToContents)
        return t

    def refresh(self) -> None:
        open_letters = {self.og.topLevelItem(i).text(0)[:1] for i in range(self.og.topLevelItemCount())
                        if self.og.topLevelItem(i).isExpanded()}
        self.og.clear()
        tree = self.lib.tree()
        for letter in LETTER_FOLDERS + [OTHER_FOLDER]:
            songs = tree.get(letter, [])
            top = QTreeWidgetItem([f"{letter}    {len(songs)}" if songs else letter])
            top.setForeground(0, QColor(theme.ACCENT if songs else "#4a4d54"))
            f = top.font(0)
            f.setBold(True)
            top.setFont(0, f)
            self.og.addTopLevelItem(top)
            for s in songs:
                it = QTreeWidgetItem([s.title, s.artist or "", fmt_duration(s.duration)])
                it.setData(0, SONG_ROLE, s.id)
                it.setToolTip(0, s.library_path)
                if s.missing:
                    it.setForeground(0, QColor(theme.BAD))
                top.addChild(it)
            top.setExpanded(letter in open_letters or (bool(songs) and len(tree) <= 6))
        self.og.resizeColumnToContents(2)

        self.remixed.clear()
        pairs = sorted((p for p in self.lib.ws.remixed.iterdir() if p.is_dir()), key=lambda p: p.name.lower()) \
            if self.lib.ws.remixed.exists() else []
        if not pairs:
            empty = QTreeWidgetItem(["Nothing fused yet - renders land here from step 3", ""])
            empty.setForeground(0, QColor(theme.MUTED))
            empty.setForeground(1, QColor(theme.MUTED))
            empty.setFlags(Qt.ItemFlag.NoItemFlags)
            self.remixed.addTopLevelItem(empty)
        for pair in pairs:
            self.remixed.addTopLevelItem(self._pair_item(pair))

    def _pair_item(self, folder: Path) -> QTreeWidgetItem:
        it = QTreeWidgetItem([folder.name, ""])
        it.setForeground(0, QColor(theme.ACCENT))
        it.setData(0, PATH_ROLE, str(folder))
        for child in sorted(folder.iterdir(), key=lambda p: (p.is_dir(), p.name.lower())):
            if child.is_dir():  # second-pass pairs nest under their parent pair
                it.addChild(self._pair_item(child))
            else:
                c = QTreeWidgetItem([child.stem if is_media(child) else child.name, child.suffix.lstrip(".").upper()])
                c.setData(0, PATH_ROLE, str(child))
                it.addChild(c)
        return it

    # ---------------------------------------------------------------- interaction
    def _og_double(self, item: QTreeWidgetItem, _col: int) -> None:
        sid = item.data(0, SONG_ROLE)
        if sid is not None:
            self.loadRequested.emit(int(sid), 0)

    def _og_menu(self, pos) -> None:
        item = self.og.itemAt(pos)
        sid = item.data(0, SONG_ROLE) if item else None
        if sid is None:
            return
        m = QMenu(self)
        m.addAction("Load into Bar 1  (Song A)", lambda: self.loadRequested.emit(int(sid), 0))
        m.addAction("Load into Bar 2  (Song B)", lambda: self.loadRequested.emit(int(sid), 1))
        m.addSeparator()
        s = self.lib.song(int(sid))
        if s:
            m.addAction("Show in folder", lambda: reveal_in_folder(s.abs_path))
        m.exec(self.og.viewport().mapToGlobal(pos))

    def _remixed_menu(self, pos) -> None:
        item = self.remixed.itemAt(pos)
        path = item.data(0, PATH_ROLE) if item else None
        if not path:
            return
        p = Path(path)
        m = QMenu(self)
        if p.is_file() and is_media(p):
            m.addAction("Feed into Bar 1 (second pass)", lambda: self.pathLoadRequested.emit(path, 0))
            m.addAction("Feed into Bar 2 (second pass)", lambda: self.pathLoadRequested.emit(path, 1))
            m.addSeparator()
        m.addAction("Show in folder", lambda: reveal_in_folder(p))
        m.exec(self.remixed.viewport().mapToGlobal(pos))
