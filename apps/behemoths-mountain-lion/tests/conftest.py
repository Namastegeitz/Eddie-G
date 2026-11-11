import math
import struct
import sys
import wave
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from bml.library import Library  # noqa: E402
from bml.workspace import ensure_workspace  # noqa: E402


def make_wav(path: Path, title: str | None = None, artist: str | None = None, album: str | None = None,
             freq: float = 220.0, seconds: float = 0.25) -> Path:
    """A short sine-tone WAV, optionally with ID3 tags (so tests need no ffmpeg)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    sr = 8000
    n = int(sr * seconds)
    frames = b"".join(struct.pack("<h", int(8000 * math.sin(2 * math.pi * freq * i / sr))) for i in range(n))
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(frames)
    if title or artist or album:
        from mutagen.id3 import TALB, TIT2, TPE1
        from mutagen.wave import WAVE

        f = WAVE(str(path))
        f.add_tags()
        if title:
            f.tags.add(TIT2(encoding=3, text=title))
        if artist:
            f.tags.add(TPE1(encoding=3, text=artist))
        if album:
            f.tags.add(TALB(encoding=3, text=album))
        f.save()
    return path


@pytest.fixture
def ws(tmp_path):
    return ensure_workspace(tmp_path / "Behemoth's Mountain Lion")


@pytest.fixture
def lib(ws):
    lib = Library(ws)
    yield lib
    lib.close()


@pytest.fixture
def outside(tmp_path):
    d = tmp_path / "my music"
    d.mkdir()
    return d
