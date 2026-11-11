"""Auto-tagging: read embedded tags, fall back to a cleaned-up file name.

Tags are only ever READ. Files in OG Bars are never modified; what the app learns
about a song lives in Library.db.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


@dataclass
class TagInfo:
    title: str
    artist: str | None = None
    album: str | None = None
    year: str | None = None
    genre: str | None = None
    duration: float | None = None  # seconds
    from_tags: bool = False  # True if title came from embedded tags


# Junk that download sites and rippers bolt onto file names.
_SITE_JUNK = re.compile(
    r"[-_. ]*(yt ?mp[34]|savetube\.vip|savetube|y2mate(\.com)?|ytmp3\.cc|ssyoutube|"
    r"snapsave(\.app)?|mp3juices|320kbps|128kbps)\b",
    re.I,
)
_COPY_SUFFIX = re.compile(r"([ _-]*(copy|\(\d+\)))+$", re.I)
_HEX_PREFIX = re.compile(r"^[0-9a-f]{6,}[-_ ]+", re.I)
_VIDEO_JUNK = (
    r"official (music )?(video|audio|visuali[sz]er|lyric video)|lyric video|lyrics?|"
    r"visuali[sz]er|audio|hd|hq|4k|explicit|clean"
)
_BRACKETED_JUNK = re.compile(rf"\s*[\(\[]\s*({_VIDEO_JUNK})\s*[\)\]]", re.I)
_TRAILING_JUNK = re.compile(rf"\s+({_VIDEO_JUNK})\s*$", re.I)


def _smart_title(text: str) -> str:
    small = {"a", "an", "and", "the", "of", "in", "on", "x", "vs", "to"}
    words = text.split()
    out = []
    for i, w in enumerate(words):
        lw = w.lower()
        if lw == "feat":
            out.append("feat.")
        elif i and lw in small:
            out.append(lw)
        else:
            out.append(w[:1].upper() + w[1:])
    return " ".join(out)


def guess_from_filename(stem: str) -> tuple[str, str | None]:
    """(title, artist) from a file name stem such as
    'Artist - Title (Official Video)' or '785b22e4-artist-song-official-visualizer-ytmp4.savetube.vip_copy'."""
    s = stem.strip()
    s = _COPY_SUFFIX.sub("", s)
    s = _HEX_PREFIX.sub("", s)
    s = _SITE_JUNK.sub("", s)
    s = _COPY_SUFFIX.sub("", s)
    s = s.replace("_", " ")
    slug = " " not in s.strip() and s.count("-") >= 2
    if slug:  # 'artist-song-title-official-visualizer' -> words
        s = s.replace("-", " ")
    for _ in range(3):
        s = _BRACKETED_JUNK.sub("", s)
        s = _TRAILING_JUNK.sub("", s)
    s = re.sub(r"\s+", " ", s).strip(" -.")
    artist = None
    if not slug and " - " in s:
        artist, s = (part.strip() for part in s.split(" - ", 1))
    if slug or s.islower():
        s = _smart_title(s)
    return (s or stem), (artist or None)


def _first(tags, *keys) -> str | None:
    if not tags:
        return None
    for k in keys:
        try:
            v = tags.get(k)
        except Exception:  # some tag containers raise on odd keys
            v = None
        if v:
            v = v[0] if isinstance(v, (list, tuple)) else v
            v = str(v).strip()
            if v:
                return v
    return None


def read_tags(path: str | Path) -> TagInfo:
    path = Path(path)
    title = artist = album = year = genre = None
    duration = None
    try:
        import mutagen

        f = mutagen.File(path, easy=True)
        if f is not None:
            if getattr(f, "info", None) is not None and getattr(f.info, "length", None):
                duration = float(f.info.length)
            tags = f.tags
            title = _first(tags, "title")
            artist = _first(tags, "artist", "albumartist")
            album = _first(tags, "album")
            year = _first(tags, "date", "year")
            genre = _first(tags, "genre")
            if not title and tags is not None and hasattr(tags, "getall"):
                # WAV/AIFF carry raw ID3 frames that "easy" mode doesn't map
                frame = lambda k: (str(tags.getall(k)[0].text[0]).strip() or None) if tags.getall(k) else None  # noqa: E731
                title, artist = frame("TIT2"), frame("TPE1") or frame("TPE2")
                album, year, genre = frame("TALB"), frame("TDRC"), frame("TCON")
    except Exception:
        pass  # unreadable tags are fine; the file name still gives a title
    if title:
        return TagInfo(title, artist, album, year, genre, duration, from_tags=True)
    g_title, g_artist = guess_from_filename(path.stem)
    return TagInfo(g_title, artist or g_artist, album, year, genre, duration, from_tags=False)
