"""Start-up: workspace on the Desktop, Library.db, first-run notice, main window."""

from __future__ import annotations

import sys
from datetime import datetime, timezone

from PySide6.QtWidgets import QApplication, QDialog, QMessageBox

from bml import APP_NAME
from bml.library import Library
from bml.paths import default_library_folders, workspace_root
from bml.ui import theme
from bml.ui.main_window import MainWindow
from bml.ui.notice import RightsNotice
from bml.workspace import ensure_workspace


def main(argv: list[str] | None = None) -> int:
    app = QApplication(argv if argv is not None else sys.argv)
    app.setApplicationName(APP_NAME)
    app.setOrganizationName("Eddie-G")
    theme.apply(app)

    root = workspace_root()
    try:
        ws = ensure_workspace(root)
        lib = Library(ws)
    except OSError as e:
        QMessageBox.critical(None, APP_NAME, f"Couldn't create the workspace at\n{root}\n\n{e}")
        return 1

    if not lib.get_meta("rights_notice_accepted_at"):
        if RightsNotice(str(ws.root)).exec() != QDialog.DialogCode.Accepted:
            return 0
        lib.set_meta("rights_notice_accepted_at", datetime.now(timezone.utc).isoformat(timespec="seconds"))

    if not lib.get_meta("library_folders_initialised"):
        for f in default_library_folders():  # Music + Downloads: searchable, nothing copied until used
            lib.add_library_folder(f)
        lib.set_meta("library_folders_initialised", "1")

    win = MainWindow(lib)
    win.showMaximized()
    return app.exec()
