"""BAR 3: the free-text vocal prompt. Stored now; wired into the pipeline in step 5."""

from __future__ import annotations

from PySide6.QtCore import Signal
from PySide6.QtWidgets import QFrame, QHBoxLayout, QLabel, QPlainTextEdit, QVBoxLayout

from bml.ui import theme


class PromptBar(QFrame):
    promptChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("bar")
        lay = QVBoxLayout(self)
        lay.setContentsMargins(16, 12, 16, 14)
        lay.setSpacing(8)
        head = QHBoxLayout()
        t = QLabel("BAR 3")
        t.setObjectName("barTag")
        t.setFont(theme.display_font(13))
        n = QLabel("VOCAL PROMPT")
        n.setObjectName("barName")
        n.setFont(theme.display_font(20))
        hint = QLabel("optional  ·  leave empty to use the real vocals  ·  generation arrives in step 5")
        hint.setObjectName("hint")
        head.addWidget(t)
        head.addSpacing(8)
        head.addWidget(n)
        head.addStretch(1)
        head.addWidget(hint)
        lay.addLayout(head)
        self.edit = QPlainTextEdit()
        self.edit.setObjectName("vocalPrompt")
        self.edit.setPlaceholderText(
            "Style, accent, character, delivery, lyrics, timestamps - e.g. "
            "Borat-style vocals for \"I was born in the mountains\", verse only, enter at 0:42")
        self.edit.setFixedHeight(64)
        self.edit.textChanged.connect(lambda: self.promptChanged.emit(self.text()))
        lay.addWidget(self.edit)

    def text(self) -> str:
        return self.edit.toPlainText().strip()
