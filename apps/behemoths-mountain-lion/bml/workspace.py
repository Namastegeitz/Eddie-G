"""The folder the app owns on the Desktop.

    Behemoth's Mountain Lion/
        OG Bars/      A ... Z, plus "#" for titles that start with a digit or symbol
        Remixed/      one folder per fused pair (step 3+)
        Stems/        cached stems (step 2+)
        Library.db    SQLite index
"""

from __future__ import annotations

import string
from dataclasses import dataclass
from pathlib import Path

LETTER_FOLDERS = list(string.ascii_uppercase)
OTHER_FOLDER = "#"  # "99 Problems", "...Ready For It?" after stripping punctuation still starts with a digit, etc.


@dataclass(frozen=True)
class Workspace:
    root: Path

    @property
    def og_bars(self) -> Path:
        return self.root / "OG Bars"

    @property
    def remixed(self) -> Path:
        return self.root / "Remixed"

    @property
    def stems(self) -> Path:
        return self.root / "Stems"

    @property
    def db_path(self) -> Path:
        return self.root / "Library.db"

    def letter_dir(self, letter: str) -> Path:
        return self.og_bars / letter

    def rel(self, path: Path) -> str:
        """Path relative to the workspace root, with forward slashes (stored in the DB)."""
        return Path(path).resolve().relative_to(self.root.resolve()).as_posix()

    def abs(self, rel: str) -> Path:
        return self.root / Path(rel)

    def contains(self, path: Path, area: Path | None = None) -> bool:
        base = (area or self.root).resolve()
        try:
            Path(path).resolve().relative_to(base)
            return True
        except ValueError:
            return False


def ensure_workspace(root: Path) -> Workspace:
    """Create the folder tree if any part is missing. Safe to call on every start."""
    ws = Workspace(Path(root))
    for d in (ws.root, ws.og_bars, ws.remixed, ws.stems):
        d.mkdir(parents=True, exist_ok=True)
    for letter in LETTER_FOLDERS + [OTHER_FOLDER]:
        ws.letter_dir(letter).mkdir(exist_ok=True)
    return ws
