"""A-Z filing rules and Windows-safe file names."""

from __future__ import annotations

import re
import unicodedata
from pathlib import Path

from bml.workspace import OTHER_FOLDER

AUDIO_EXTS = {
    ".mp3", ".wav", ".flac", ".m4a", ".aac", ".ogg", ".oga", ".opus",
    ".aif", ".aiff", ".wma", ".alac", ".ape", ".wv",
}
# Videos are accepted too: their audio track is what gets used (e.g. a downloaded visualizer).
VIDEO_EXTS = {".mp4", ".m4v", ".mov", ".mkv", ".webm"}
MEDIA_EXTS = AUDIO_EXTS | VIDEO_EXTS

_WINDOWS_RESERVED = {"CON", "PRN", "AUX", "NUL"} | {f"COM{i}" for i in range(1, 10)} | {
    f"LPT{i}" for i in range(1, 10)
}
_BAD_CHARS = re.compile(r'[<>:"/\\|?*\x00-\x1f]')


def is_media(path: str | Path) -> bool:
    return Path(path).suffix.lower() in MEDIA_EXTS


def _fold(text: str) -> str:
    """'Évora' -> 'Evora' (strip accents so it files under E)."""
    return "".join(c for c in unicodedata.normalize("NFKD", text) if not unicodedata.combining(c))


def letter_for(title: str) -> str:
    """The OG Bars subfolder for a title: first letter A-Z, or '#' for digits/symbols/other scripts."""
    for ch in _fold(title or ""):
        if ch.isalnum():
            up = ch.upper()
            return up if "A" <= up <= "Z" else OTHER_FOLDER
    return OTHER_FOLDER


def safe_filename(stem: str, max_len: int = 150) -> str:
    """A file name stem that is valid on Windows (and everywhere else)."""
    s = _BAD_CHARS.sub(" ", stem or "")
    s = re.sub(r"\s+", " ", s).strip().rstrip(". ")
    if not s:
        s = "Untitled"
    if s.split(".")[0].upper() in _WINDOWS_RESERVED:
        s = "_" + s
    if len(s) > max_len:
        s = s[:max_len].rstrip(". ")
    return s


def library_filename(title: str, artist: str | None, ext: str) -> str:
    stem = f"{artist} - {title}" if artist else title
    return safe_filename(stem) + ext.lower()


def unique_path(folder: Path, filename: str) -> Path:
    """folder/filename, or 'name (2).ext', 'name (3).ext' ... if taken."""
    candidate = folder / filename
    stem, ext = Path(filename).stem, Path(filename).suffix
    n = 2
    while candidate.exists():
        candidate = folder / f"{stem} ({n}){ext}"
        n += 1
    return candidate
