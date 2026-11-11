"""One-time first-run notice about rights and local-only processing."""

from __future__ import annotations

from PySide6.QtWidgets import QCheckBox, QDialog, QDialogButtonBox, QLabel, QVBoxLayout

from bml import APP_NAME
from bml.ui import theme

NOTICE = (
    "<p>Only load audio you own or have the rights to use: your own recordings, music you "
    "have licensed for remixing, or tracks whose license allows it.</p>"
    "<p>Everything runs on this computer. Songs, stems and renders stay in the "
    "<b>Behemoth's Mountain Lion</b> folder on your Desktop. Nothing is uploaded.</p>"
)


class RightsNotice(QDialog):
    def __init__(self, workspace_path: str, parent=None):
        super().__init__(parent)
        self.setWindowTitle(APP_NAME)
        self.setMinimumWidth(520)
        lay = QVBoxLayout(self)
        lay.setContentsMargins(28, 24, 28, 20)
        lay.setSpacing(14)
        h = QLabel("BEFORE YOU START")
        h.setFont(theme.display_font(24))
        h.setObjectName("barTag")
        lay.addWidget(h)
        body = QLabel(NOTICE + f"<p style='color:{theme.MUTED}'>Workspace: {workspace_path}</p>")
        body.setWordWrap(True)
        lay.addWidget(body)
        self.check = QCheckBox("I'll only process audio I own or have the rights to use")
        lay.addWidget(self.check)
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        self.ok = buttons.button(QDialogButtonBox.StandardButton.Ok)
        self.ok.setText("Continue")
        self.ok.setEnabled(False)
        buttons.button(QDialogButtonBox.StandardButton.Cancel).setText("Quit")
        self.check.toggled.connect(self.ok.setEnabled)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        lay.addWidget(buttons)
