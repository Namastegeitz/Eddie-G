"""BAR 1 / BAR 2: live library search, path paste, drag-and-drop, loaded-song card."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import QModelIndex, QRect, QSize, Qt, QTimer, QUrl, Signal
from PySide6.QtGui import (QColor, QDesktopServices, QFont, QPainter, QPen, QStandardItem,
                           QStandardItemModel)
from PySide6.QtWidgets import (QCompleter, QFrame, QHBoxLayout, QLabel, QLineEdit, QPushButton,
                               QSizePolicy, QStyle, QStyledItemDelegate, QStyleOptionViewItem,
                               QVBoxLayout, QWidget)

from bml.filing import is_media
from bml.library import ImportResult, Library, SearchHit, Song
from bml.ui import theme
from bml.ui.workers import Worker, start

HIT_ROLE = Qt.ItemDataRole.UserRole + 1
HINT = "type to search  ·  paste a path  ·  drop a file"


def fmt_duration(sec: float | None) -> str:
    if not sec:
        return ""
    sec = int(round(sec))
    return f"{sec // 3600}:{sec // 60 % 60:02d}:{sec % 60:02d}" if sec >= 3600 else f"{sec // 60}:{sec % 60:02d}"


def clean_path_text(text: str) -> Path | None:
    """A typed/pasted path (Windows 'Copy as path' adds quotes), if the text looks like one."""
    t = text.strip().strip('"').strip("'")
    if not t:
        return None
    looks_like_path = ("/" in t or "\\" in t or (len(t) > 2 and t[1] == ":") or t.startswith("~"))
    if not looks_like_path:
        return None
    if t.startswith("file:"):
        t = QUrl(t).toLocalFile()
    return Path(t).expanduser()


def reveal_in_folder(path: Path) -> None:
    if sys.platform == "win32":
        subprocess.Popen(f'explorer /select,"{os.path.normpath(path)}"')
    elif sys.platform == "darwin":
        subprocess.Popen(["open", "-R", str(path)])
    else:
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(path.parent)))


class ResultDelegate(QStyledItemDelegate):
    """Two-line result rows: title / artist - album, with a source badge and duration."""

    def sizeHint(self, option, index) -> QSize:
        return QSize(option.rect.width(), 50)

    def paint(self, p: QPainter, opt: QStyleOptionViewItem, index: QModelIndex) -> None:
        item = index.data(HIT_ROLE) or {}
        p.save()
        r = opt.rect.adjusted(4, 2, -4, -2)
        selected = bool(opt.state & QStyle.StateFlag.State_Selected) or bool(opt.state & QStyle.StateFlag.State_MouseOver)
        if selected:
            p.setPen(Qt.PenStyle.NoPen)
            p.setBrush(QColor(theme.ACCENT_LO))
            p.drawRoundedRect(r, 6, 6)
        # badge
        badge = item.get("badge", "")
        bf = QFont(opt.font)
        bf.setPixelSize(11)
        bf.setBold(True)
        p.setFont(bf)
        bw = p.fontMetrics().horizontalAdvance(badge) + 16
        brect = QRect(r.right() - bw - 8, r.top() + 8, bw, 18)
        if badge:
            accent = item.get("kind") in ("song", "path", "folder")
            p.setPen(QPen(QColor(theme.ACCENT if accent else theme.LINE), 1))
            p.setBrush(QColor(theme.BG))
            p.drawRoundedRect(brect, 4, 4)
            p.setPen(QColor(theme.ACCENT_HI if accent else theme.MUTED))
            p.drawText(brect, Qt.AlignmentFlag.AlignCenter, badge)
        dur = item.get("duration", "")
        if dur:
            p.setPen(QColor(theme.MUTED))
            p.drawText(QRect(brect.left() - 70, r.top() + 8, 62, 18),
                       Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter, dur)
        text_right = brect.left() - (78 if dur else 10)
        # title
        tf = QFont(opt.font)
        tf.setPixelSize(15)
        tf.setBold(True)
        p.setFont(tf)
        p.setPen(QColor(theme.TEXT))
        title_rect = QRect(r.left() + 10, r.top() + 4, text_right - r.left() - 10, 22)
        p.drawText(title_rect, Qt.AlignmentFlag.AlignVCenter,
                   p.fontMetrics().elidedText(item.get("title", ""), Qt.TextElideMode.ElideRight, title_rect.width()))
        sf = QFont(opt.font)
        sf.setPixelSize(12)
        p.setFont(sf)
        p.setPen(QColor(theme.MUTED))
        sub_rect = QRect(r.left() + 10, r.top() + 25, r.width() - 20, 18)
        p.drawText(sub_rect, Qt.AlignmentFlag.AlignVCenter,
                   p.fontMetrics().elidedText(item.get("sub", ""), Qt.TextElideMode.ElideMiddle, sub_rect.width()))
        p.restore()


class WaveformSlot(QWidget):
    """Placeholder strip where the waveform is drawn once analysis lands (step 2)."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedHeight(46)

    def paintEvent(self, _e) -> None:
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        r = self.rect().adjusted(0, 0, -1, -1)
        p.setPen(QPen(QColor(theme.LINE), 1))
        p.setBrush(QColor(theme.BG))
        p.drawRoundedRect(r, 6, 6)
        p.setPen(QPen(QColor(theme.ACCENT_LO), 1, Qt.PenStyle.DashLine))
        p.drawLine(r.left() + 12, r.center().y(), r.right() - 12, r.center().y())
        p.setPen(QColor(theme.MUTED))
        f = QFont(self.font())
        f.setPixelSize(12)
        p.setFont(f)
        p.drawText(r, Qt.AlignmentFlag.AlignCenter, "Waveform, BPM and key appear here once analysis is built (step 2)")


class SongBar(QFrame):
    songChanged = Signal(object)        # Song | None
    libraryChanged = Signal()           # a file was copied into OG Bars
    folderDropped = Signal(object)      # Path of a folder to add to the library

    def __init__(self, library: Library, tag: str, name: str, parent=None):
        super().__init__(parent)
        self.lib = library
        self.song: Song | None = None
        self._busy = False
        self.setObjectName("bar")
        self.setAcceptDrops(True)
        self.setProperty("dragActive", False)
        self.setProperty("loaded", False)

        lay = QVBoxLayout(self)
        lay.setContentsMargins(16, 12, 16, 14)
        lay.setSpacing(8)

        head = QHBoxLayout()
        t = QLabel(tag)
        t.setObjectName("barTag")
        t.setFont(theme.display_font(13))
        n = QLabel(name)
        n.setObjectName("barName")
        n.setFont(theme.display_font(20))
        self.status = QLabel(HINT)  # the hint; also shows what happened ("Copied into OG Bars / R")
        self.status.setObjectName("hint")
        self.status.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        self.status.setSizePolicy(QSizePolicy.Policy.Ignored, QSizePolicy.Policy.Preferred)
        head.addWidget(t)
        head.addSpacing(8)
        head.addWidget(n)
        head.addSpacing(16)
        head.addWidget(self.status, 1)
        lay.addLayout(head)

        self.edit = QLineEdit()
        self.edit.setObjectName(f"search{name.replace(' ', '')}")
        self.edit.setPlaceholderText("Search your library, paste a file path, or drop a song here")
        self.edit.setClearButtonEnabled(True)
        lay.addWidget(self.edit)

        # live results
        self.model = QStandardItemModel(self)
        self.completer = QCompleter(self.model, self)
        self.completer.setWidget(self.edit)
        self.completer.setCompletionMode(QCompleter.CompletionMode.UnfilteredPopupCompletion)
        self.completer.setCaseSensitivity(Qt.CaseSensitivity.CaseInsensitive)
        self.completer.setMaxVisibleItems(8)
        popup = self.completer.popup()
        popup.setObjectName("results")
        popup.setItemDelegate(ResultDelegate(popup))
        popup.setMouseTracking(True)
        popup.setUniformItemSizes(True)
        self.completer.activated[QModelIndex].connect(self._activated)

        self._debounce = QTimer(self, singleShot=True, interval=70)
        self._debounce.timeout.connect(self.refresh_results)
        self.edit.textEdited.connect(lambda _t: self._debounce.start())
        self.edit.returnPressed.connect(self._enter)
        self.edit.installEventFilter(self)

        # loaded-song card
        self.card = QWidget()
        cl = QVBoxLayout(self.card)
        cl.setContentsMargins(0, 4, 0, 0)
        cl.setSpacing(6)
        top = QHBoxLayout()
        self.title = QLabel()
        self.title.setFont(theme.display_font(24))
        self.title.setSizePolicy(QSizePolicy.Policy.Ignored, QSizePolicy.Policy.Preferred)
        top.addWidget(self.title, 1)
        self.badges = {k: self._badge(v) for k, v in
                       (("bpm", "BPM —"), ("key", "KEY —"), ("dur", ""), ("fmt", ""))}
        self.badges["bpm"].setToolTip("Tempo detection arrives in step 2")
        self.badges["key"].setToolTip("Key detection arrives in step 2")
        for b in self.badges.values():
            top.addWidget(b)
        top.addSpacing(10)
        self.reveal_btn = QPushButton("Show in folder")
        self.reveal_btn.clicked.connect(lambda: self.song and reveal_in_folder(self.song.abs_path))
        self.clear_btn = QPushButton("Clear")
        self.clear_btn.clicked.connect(self.clear)
        top.addWidget(self.reveal_btn)
        top.addWidget(self.clear_btn)
        cl.addLayout(top)
        self.meta = QLabel()
        self.meta.setObjectName("hint")
        self.meta.setSizePolicy(QSizePolicy.Policy.Ignored, QSizePolicy.Policy.Preferred)
        self.meta.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        cl.addWidget(self.meta)
        self.wave = WaveformSlot()
        cl.addWidget(self.wave)
        self.card.hide()
        lay.addWidget(self.card)

    # ---------------------------------------------------------------- helpers
    @staticmethod
    def _badge(text: str) -> QLabel:
        b = QLabel(text)
        b.setObjectName("badge")
        return b

    def _set_status(self, text: str, kind: str = "hint") -> None:
        self.status.setObjectName(kind if text else "hint")  # hint / ok / error colours come from the stylesheet
        self.status.style().unpolish(self.status)
        self.status.style().polish(self.status)
        self.status.setText(text or HINT)
        self.status.setToolTip(text)

    def _repolish(self) -> None:
        self.style().unpolish(self)
        self.style().polish(self)

    # ---------------------------------------------------------------- results
    def eventFilter(self, obj, event):
        if obj is self.edit and event.type() == event.Type.FocusIn and not self.edit.text() and not self.song:
            QTimer.singleShot(0, self.refresh_results)  # recent songs on focus
        return super().eventFilter(obj, event)

    def _row(self, data: dict) -> QStandardItem:
        it = QStandardItem(data["title"])
        it.setData(data, HIT_ROLE)
        it.setEditable(False)
        return it

    def _hit_row(self, h: SearchHit) -> QStandardItem:
        who = " · ".join(x for x in (h.artist, h.album) if x)
        badge = h.where.upper()[:20]
        return self._row({"kind": h.kind, "id": h.id, "title": h.title, "path": str(h.path),
                          "sub": f"{who}   —   {h.path}" if who else str(h.path), "badge": badge,
                          "duration": fmt_duration(h.duration)})

    def refresh_results(self) -> None:
        text = self.edit.text()
        self.model.clear()
        p = clean_path_text(text)
        if p is not None:
            if p.is_file() and is_media(p):
                self.model.appendRow(self._row({"kind": "path", "title": f"Load {p.name}", "path": str(p),
                                                "sub": str(p), "badge": "FROM PATH"}))
            elif p.is_dir():
                self.model.appendRow(self._row({"kind": "folder", "title": f"Add folder to library: {p.name}",
                                                "path": str(p), "sub": str(p), "badge": "FOLDER"}))
        for h in self.lib.search(text, limit=40):
            self.model.appendRow(self._hit_row(h))
        if self.model.rowCount() == 0:
            if text.strip():
                self.completer.popup().hide()
                self._set_status(f'No matches for "{text.strip()}" in OG Bars or your library folders.')
            else:
                self.completer.popup().hide()
            return
        self._set_status("")
        self.completer.setCompletionPrefix("")
        self.completer.complete(self.edit.rect())
        self.completer.popup().setCurrentIndex(self.model.index(0, 0))

    def _enter(self) -> None:
        if self.completer.popup().isVisible():
            return  # the popup handles Enter itself
        p = clean_path_text(self.edit.text())
        if p is not None and p.is_file():
            self.load_path(p)
        elif self.model.rowCount():
            self._activated(self.model.index(0, 0))

    def _activated(self, index: QModelIndex) -> None:
        data = index.data(HIT_ROLE) or {}
        kind = data.get("kind")
        if kind == "song":
            s = self.lib.song(data["id"])
            if s:
                self.set_song(s, "In the library")
        elif kind in ("file", "path"):
            self.load_path(Path(data["path"]))
        elif kind == "folder":
            self.folderDropped.emit(Path(data["path"]))
            self._set_status(f"Adding {data['path']} to your library folders…")

    # ---------------------------------------------------------------- loading
    def load_path(self, path: Path) -> None:
        if self._busy:
            return
        self._busy = True
        self.completer.popup().hide()
        self._set_status(f"Filing {path.name} into OG Bars…")
        w = Worker(self.lib.import_file, path)
        w.signals.done.connect(self._imported)
        w.signals.failed.connect(self._import_failed)
        start(w)

    def _imported(self, res: ImportResult) -> None:
        self._busy = False
        notes = {
            "imported": f"Copied into OG Bars / {res.song.letter} (read-only original)",
            "duplicate": "Already in the library - using the existing copy",
            "existing": "In the library",
            "indexed": "Second-pass source from Remixed" if res.song.origin == "remix" else "Indexed in place",
        }
        self.set_song(res.song, notes.get(res.status, ""))
        self.libraryChanged.emit()

    def _import_failed(self, msg: str) -> None:
        self._busy = False
        self._set_status(msg, "error")

    def set_song(self, song: Song, note: str = "") -> None:
        self.song = song
        self.lib.mark_loaded(song.id)
        self.completer.popup().hide()
        self.edit.setText(song.display)
        self.edit.setCursorPosition(0)
        self.title.setText(song.title)
        self.title.setToolTip(song.display)
        bits = [song.artist or "Unknown artist"]
        if song.album:
            bits.append(song.album)
        bits.append(song.library_path.replace("/", " / "))
        self.meta.setText("   ·   ".join(bits))
        self.meta.setToolTip(str(song.abs_path))
        self.badges["dur"].setText(fmt_duration(song.duration) or "--:--")
        self.badges["fmt"].setText(song.ext.lstrip(".").upper())
        for k in ("dur", "fmt"):
            self.badges[k].setProperty("live", True)
            self.badges[k].style().polish(self.badges[k])
        self.card.show()
        self.setProperty("loaded", True)
        self._repolish()
        self._set_status(("Missing on disk - " if song.missing else "") + note, "error" if song.missing else "ok")
        self.songChanged.emit(song)

    def clear(self) -> None:
        self.song = None
        self.edit.clear()
        self.card.hide()
        self._set_status("")
        self.setProperty("loaded", False)
        self._repolish()
        self.songChanged.emit(None)
        self.edit.setFocus()

    # ---------------------------------------------------------------- drag and drop
    def _dropped_paths(self, event) -> list[Path]:
        md = event.mimeData()
        if not md.hasUrls():
            return []
        return [Path(u.toLocalFile()) for u in md.urls() if u.isLocalFile()]

    def dragEnterEvent(self, event) -> None:
        paths = self._dropped_paths(event)
        if any(p.is_dir() or is_media(p) for p in paths):
            event.acceptProposedAction()
            self.setProperty("dragActive", True)
            self._repolish()
        else:
            event.ignore()

    def dragLeaveEvent(self, event) -> None:
        self.setProperty("dragActive", False)
        self._repolish()

    def dropEvent(self, event) -> None:
        self.setProperty("dragActive", False)
        self._repolish()
        paths = self._dropped_paths(event)
        media = [p for p in paths if p.is_file() and is_media(p)]
        folders = [p for p in paths if p.is_dir()]
        if media:
            self.load_path(media[0])
            if len(media) > 1:
                self._set_status(f"Loaded the first of {len(media)} dropped files - batch mode (step 6) takes many", "ok")
        for f in folders:
            self.folderDropped.emit(f)
        event.acceptProposedAction()
