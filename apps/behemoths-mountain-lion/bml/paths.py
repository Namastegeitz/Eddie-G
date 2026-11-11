"""Where things live on the user's machine.

On Windows the Desktop, Music and Downloads folders are looked up through the shell
(SHGetKnownFolderPath), so a Desktop redirected to OneDrive is found correctly.
Set BML_WORKSPACE to put the workspace somewhere else (used by the tests).
"""

from __future__ import annotations

import os
import re
import sys
import uuid
from pathlib import Path

from bml import APP_NAME

_FOLDER_IDS = {
    "Desktop": "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}",
    "Music": "{4BD8D571-6D19-48D3-BE97-422220080E43}",
    "Downloads": "{374DE290-123F-4565-9164-39C4925E467B}",
}
_XDG_KEYS = {"Desktop": "DESKTOP", "Music": "MUSIC", "Downloads": "DOWNLOAD"}


def _windows_known_folder(guid: str) -> str:
    import ctypes
    from ctypes import wintypes

    class GUID(ctypes.Structure):
        _fields_ = [
            ("Data1", wintypes.DWORD),
            ("Data2", wintypes.WORD),
            ("Data3", wintypes.WORD),
            ("Data4", ctypes.c_ubyte * 8),
        ]

    u = uuid.UUID(guid)
    g = GUID()
    g.Data1, g.Data2, g.Data3 = u.fields[0], u.fields[1], u.fields[2]
    for i, b in enumerate(u.bytes[8:]):
        g.Data4[i] = b
    out = ctypes.c_wchar_p()
    shell32 = ctypes.windll.shell32  # type: ignore[attr-defined]
    shell32.SHGetKnownFolderPath.argtypes = [
        ctypes.POINTER(GUID), wintypes.DWORD, wintypes.HANDLE, ctypes.POINTER(ctypes.c_wchar_p)
    ]
    hr = shell32.SHGetKnownFolderPath(ctypes.byref(g), 0, None, ctypes.byref(out))
    if hr != 0:
        raise OSError(f"SHGetKnownFolderPath failed: {hr:#x}")
    try:
        return out.value or ""
    finally:
        ctypes.windll.ole32.CoTaskMemFree(out)  # type: ignore[attr-defined]


def _xdg_user_dir(key: str) -> Path | None:
    cfg = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "user-dirs.dirs"
    try:
        text = cfg.read_text(encoding="utf-8")
    except OSError:
        return None
    m = re.search(rf'^XDG_{key}_DIR="(.+)"', text, re.M)
    if not m:
        return None
    return Path(m.group(1).replace("$HOME", str(Path.home())))


def known_folder(name: str) -> Path:
    """The user's Desktop / Music / Downloads folder."""
    if sys.platform == "win32":
        try:
            p = _windows_known_folder(_FOLDER_IDS[name])
            if p:
                return Path(p)
        except (OSError, AttributeError):
            pass
    else:
        p = _xdg_user_dir(_XDG_KEYS[name])
        if p:
            return p
    return Path.home() / name


def workspace_root() -> Path:
    override = os.environ.get("BML_WORKSPACE")
    if override:
        return Path(override)
    return known_folder("Desktop") / APP_NAME


def default_library_folders() -> list[Path]:
    """Folders searched by the bars before anything is copied into OG Bars."""
    return [p for p in (known_folder("Music"), known_folder("Downloads")) if p.is_dir()]
