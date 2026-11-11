"""Dark, heavy, tawny: the Behemoth's Mountain Lion look."""

from __future__ import annotations

from PySide6.QtGui import QColor, QFont, QPalette
from PySide6.QtWidgets import QApplication

BG = "#0a0b0d"
PANEL = "#121418"
PANEL_2 = "#191c21"
LINE = "#2a2e35"
TEXT = "#ece5d8"
MUTED = "#8c8f96"
ACCENT = "#d4892a"      # mountain-lion tawny
ACCENT_HI = "#f0a643"
ACCENT_LO = "#5c3a12"
GOOD = "#6dbb85"
BAD = "#e0664a"

DISPLAY_FAMILIES = ["Bahnschrift SemiBold Condensed", "Bahnschrift", "Segoe UI Black", "Arial Black",
                    "DejaVu Sans Condensed", "DejaVu Sans"]
BODY_FAMILIES = ["Segoe UI", "Segoe UI Variable Text", "Inter", "DejaVu Sans"]
MONO_FAMILIES = ["Cascadia Mono", "Consolas", "DejaVu Sans Mono"]


def display_font(px: int, weight: QFont.Weight = QFont.Weight.Black) -> QFont:
    f = QFont()
    f.setFamilies(DISPLAY_FAMILIES)
    f.setPixelSize(px)
    f.setWeight(weight)
    return f


def mono_font(px: int) -> QFont:
    f = QFont()
    f.setFamilies(MONO_FAMILIES)
    f.setPixelSize(px)
    return f


QSS = f"""
* {{ color: {TEXT}; }}
QMainWindow, QDialog, QWidget#central {{ background: {BG}; }}
QToolTip {{ background: {PANEL_2}; color: {TEXT}; border: 1px solid {LINE}; padding: 6px; }}

QFrame#bar {{ background: {PANEL}; border: 1px solid {LINE}; border-radius: 10px; }}
QFrame#bar[dragActive="true"] {{ border: 2px dashed {ACCENT}; background: #1a150e; }}
QFrame#bar[loaded="true"] {{ border-left: 4px solid {ACCENT}; }}
QLabel#barTag {{ color: {ACCENT}; letter-spacing: 2px; }}
QLabel#barName {{ color: {TEXT}; }}
QLabel#hint, QLabel.muted {{ color: {MUTED}; }}
QLabel#error {{ color: {BAD}; }}
QLabel#ok {{ color: {GOOD}; }}

QLineEdit, QPlainTextEdit {{
    background: {BG}; border: 1px solid {LINE}; border-radius: 7px;
    padding: 10px 12px; font-size: 16px; selection-background-color: {ACCENT_LO};
}}
QLineEdit:focus, QPlainTextEdit:focus {{ border: 1px solid {ACCENT}; }}

QListView#results {{
    background: {PANEL_2}; border: 1px solid {ACCENT}; border-radius: 6px; outline: 0; padding: 4px;
}}

QLabel#badge {{
    background: {PANEL_2}; border: 1px solid {LINE}; border-radius: 5px; padding: 3px 9px;
    font-weight: 700; color: {MUTED};
}}
QLabel#badge[live="true"] {{ color: {TEXT}; border-color: {ACCENT}; }}

QPushButton {{
    background: {PANEL_2}; border: 1px solid {LINE}; border-radius: 7px; padding: 7px 14px; font-weight: 600;
}}
QPushButton:hover {{ border-color: {ACCENT}; }}
QPushButton:disabled {{ color: #555860; border-color: #1f2228; }}
QPushButton#fuse {{
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 {ACCENT_HI}, stop:1 {ACCENT});
    color: #120b02; border: 0; border-radius: 10px; padding: 14px 40px; letter-spacing: 4px;
}}
QPushButton#fuse:disabled {{ background: #2b2016; color: #6e5536; }}

QCheckBox:disabled, QComboBox:disabled {{ color: #5d6068; }}
QCheckBox {{ spacing: 7px; }}
QCheckBox::indicator {{ width: 15px; height: 15px; border: 1px solid #4a4f58; border-radius: 4px; background: {BG}; }}
QCheckBox::indicator:hover {{ border-color: {ACCENT}; }}
QCheckBox::indicator:checked {{ background: {ACCENT}; border-color: {ACCENT_HI}; }}
QCheckBox::indicator:disabled {{ border-color: #2c3037; }}
QCheckBox::indicator:checked:disabled {{ background: {ACCENT_LO}; border-color: {ACCENT_LO}; }}
QComboBox {{ background: {PANEL_2}; border: 1px solid {LINE}; border-radius: 6px; padding: 5px 10px; }}

QTabWidget::pane {{ border: 1px solid {LINE}; border-radius: 8px; top: -1px; background: {PANEL}; }}
QTabBar::tab {{
    background: transparent; color: {MUTED}; padding: 8px 18px; font-weight: 700; letter-spacing: 1px;
    border-bottom: 2px solid transparent;
}}
QTabBar::tab:selected {{ color: {TEXT}; border-bottom: 2px solid {ACCENT}; }}

QTreeWidget {{ background: {PANEL}; border: 0; alternate-background-color: #15181c; outline: 0; }}
QTreeWidget::item {{ padding: 3px 2px; }}
QTreeWidget::item:selected {{ background: {ACCENT_LO}; color: {TEXT}; }}
QHeaderView::section {{
    background: {PANEL_2}; color: {ACCENT}; border: 0; border-bottom: 1px solid {LINE};
    padding: 6px; font-weight: 800; letter-spacing: 1px;
}}

QStatusBar {{ background: {PANEL}; border-top: 1px solid {LINE}; color: {MUTED}; }}
QStatusBar QLabel {{ color: {MUTED}; padding: 0 8px; }}
QMenuBar {{ background: {BG}; }}
QMenuBar::item:selected, QMenu::item:selected {{ background: {ACCENT_LO}; }}
QMenu {{ background: {PANEL_2}; border: 1px solid {LINE}; }}
QSplitter::handle {{ background: {BG}; }}
QScrollBar:vertical {{ background: transparent; width: 10px; margin: 2px; }}
QScrollBar::handle:vertical {{ background: {LINE}; border-radius: 4px; min-height: 30px; }}
QScrollBar::add-line, QScrollBar::sub-line {{ height: 0; width: 0; }}
"""


def apply(app: QApplication) -> None:
    app.setStyle("Fusion")
    pal = QPalette()
    for role, color in (
        (QPalette.ColorRole.Window, BG), (QPalette.ColorRole.Base, BG),
        (QPalette.ColorRole.AlternateBase, PANEL), (QPalette.ColorRole.Text, TEXT),
        (QPalette.ColorRole.WindowText, TEXT), (QPalette.ColorRole.Button, PANEL_2),
        (QPalette.ColorRole.ButtonText, TEXT), (QPalette.ColorRole.Highlight, ACCENT_LO),
        (QPalette.ColorRole.HighlightedText, TEXT), (QPalette.ColorRole.PlaceholderText, "#6a6d74"),
        (QPalette.ColorRole.ToolTipBase, PANEL_2), (QPalette.ColorRole.ToolTipText, TEXT),
    ):
        pal.setColor(role, QColor(color))
    app.setPalette(pal)
    f = QFont()
    f.setFamilies(BODY_FAMILIES)
    f.setPixelSize(14)
    app.setFont(f)
    app.setStyleSheet(QSS)
