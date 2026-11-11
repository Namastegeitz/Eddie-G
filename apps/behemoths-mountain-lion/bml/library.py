"""Library.db - the SQLite index behind the bars.

Two kinds of things are searchable:

* songs - files that live in the workspace: copied into OG Bars (filed A-Z, deduped by
  content hash, read-only), or renders in Remixed fed back in for a second pass.
* files - media found in the user's library folders (Music, Downloads, or any folder they
  add). These are only indexed; a file is copied into OG Bars the moment it is loaded
  into Bar 1 or Bar 2.

Every thread gets its own SQLite connection (WAL mode), so background scans and
imports never block the search bars.
"""

from __future__ import annotations

import hashlib
import os
import re
import shutil
import sqlite3
import stat
import threading
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

from bml.filing import MEDIA_EXTS, is_media, letter_for, library_filename, unique_path
from bml.tags import read_tags
from bml.workspace import Workspace

SCHEMA_VERSION = 1

_SCHEMA_V1 = """
CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT);

CREATE TABLE IF NOT EXISTS songs (
    id             INTEGER PRIMARY KEY,
    sha256         TEXT UNIQUE NOT NULL,
    title          TEXT NOT NULL,
    artist         TEXT,
    album          TEXT,
    year           TEXT,
    genre          TEXT,
    duration       REAL,
    size           INTEGER NOT NULL,
    ext            TEXT NOT NULL,
    letter         TEXT NOT NULL,
    library_path   TEXT NOT NULL UNIQUE,  -- relative to the workspace root
    origin         TEXT NOT NULL DEFAULT 'og',  -- 'og' = OG Bars, 'remix' = a render fed back in
    tagged_from    TEXT NOT NULL DEFAULT 'filename',  -- 'tags' or 'filename'
    missing        INTEGER NOT NULL DEFAULT 0,
    added_at       TEXT NOT NULL,
    last_loaded_at TEXT
);
CREATE INDEX IF NOT EXISTS songs_letter ON songs(letter, title);

-- every path a song was imported from (the dedupe record)
CREATE TABLE IF NOT EXISTS song_sources (
    song_id     INTEGER NOT NULL REFERENCES songs(id) ON DELETE CASCADE,
    source_path TEXT NOT NULL,
    imported_at TEXT NOT NULL,
    PRIMARY KEY (song_id, source_path)
);

CREATE TABLE IF NOT EXISTS library_folders (
    path       TEXT PRIMARY KEY,
    added_at   TEXT NOT NULL,
    scanned_at TEXT
);

-- media found in library folders, not copied until it is loaded into a bar
CREATE TABLE IF NOT EXISTS files (
    id       INTEGER PRIMARY KEY,
    path     TEXT UNIQUE NOT NULL,
    folder   TEXT NOT NULL,
    size     INTEGER NOT NULL,
    mtime    REAL NOT NULL,
    title    TEXT NOT NULL,
    artist   TEXT,
    album    TEXT,
    duration REAL,
    ext      TEXT NOT NULL,
    song_id  INTEGER REFERENCES songs(id) ON DELETE SET NULL
);

-- filled in step 2
CREATE TABLE IF NOT EXISTS analysis (
    song_id       INTEGER PRIMARY KEY REFERENCES songs(id) ON DELETE CASCADE,
    bpm           REAL,
    key           TEXT,
    scale         TEXT,
    loudness_lufs REAL,
    downbeats     TEXT,  -- JSON
    sections      TEXT,  -- JSON
    spectral      TEXT,  -- JSON
    analyzer      TEXT,
    analyzed_at   TEXT
);

-- filled in step 3+
CREATE TABLE IF NOT EXISTS renders (
    id          INTEGER PRIMARY KEY,
    song_a_id   INTEGER REFERENCES songs(id),
    song_b_id   INTEGER REFERENCES songs(id),
    perspective TEXT NOT NULL,
    path        TEXT NOT NULL,  -- relative to the workspace root
    recipe_path TEXT,
    created_at  TEXT NOT NULL
);
"""

_FTS = """
CREATE VIRTUAL TABLE IF NOT EXISTS search_fts USING fts5(
    title, artist, album, filename,
    kind UNINDEXED, ref UNINDEXED,
    tokenize = "unicode61 remove_diacritics 2",
    prefix = '1 2 3'
);
"""


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256_file(path: Path, chunk: int = 1 << 20) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


@dataclass
class Song:
    id: int
    title: str
    artist: str | None
    album: str | None
    year: str | None
    genre: str | None
    duration: float | None
    size: int
    ext: str
    letter: str
    library_path: str
    origin: str
    tagged_from: str
    missing: bool
    added_at: str
    sha256: str
    abs_path: Path

    @property
    def display(self) -> str:
        return f"{self.artist} - {self.title}" if self.artist else self.title


@dataclass
class ImportResult:
    song: Song
    status: str  # 'imported' | 'duplicate' | 'existing' | 'indexed'
    note: str = ""


@dataclass
class SearchHit:
    kind: str  # 'song' (in the workspace) or 'file' (in a library folder, not copied yet)
    id: int
    title: str
    artist: str | None
    album: str | None
    duration: float | None
    ext: str
    path: Path
    where: str  # 'OG Bars / S', 'Remixed', 'Music', 'Downloads', ...


class ImportError_(Exception):
    pass


class Library:
    def __init__(self, workspace: Workspace):
        self.ws = workspace
        self._local = threading.local()
        self._write_lock = threading.Lock()  # serialise imports so two bars can't race on one file
        self.has_fts = True
        self._migrate()

    # ------------------------------------------------------------------ connection
    def conn(self) -> sqlite3.Connection:
        c = getattr(self._local, "conn", None)
        if c is None:
            c = sqlite3.connect(self.ws.db_path, timeout=10)
            c.row_factory = sqlite3.Row
            c.execute("PRAGMA journal_mode=WAL")
            c.execute("PRAGMA foreign_keys=ON")
            c.execute("PRAGMA busy_timeout=10000")
            self._local.conn = c
        return c

    def close(self) -> None:
        c = getattr(self._local, "conn", None)
        if c is not None:
            c.close()
            self._local.conn = None

    def _migrate(self) -> None:
        c = self.conn()
        ver = c.execute("PRAGMA user_version").fetchone()[0]
        if ver < 1:
            c.executescript(_SCHEMA_V1)
            c.execute(f"PRAGMA user_version={SCHEMA_VERSION}")
            c.execute("INSERT OR IGNORE INTO meta(key, value) VALUES('created_at', ?)", (_now(),))
            c.commit()
        try:
            c.executescript(_FTS)
        except sqlite3.OperationalError:
            self.has_fts = False  # SQLite built without FTS5: search falls back to LIKE

    # ------------------------------------------------------------------ meta
    def get_meta(self, key: str) -> str | None:
        row = self.conn().execute("SELECT value FROM meta WHERE key=?", (key,)).fetchone()
        return row[0] if row else None

    def set_meta(self, key: str, value: str) -> None:
        c = self.conn()
        c.execute("INSERT INTO meta(key, value) VALUES(?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
                  (key, value))
        c.commit()

    # ------------------------------------------------------------------ songs
    def _song(self, row: sqlite3.Row) -> Song:
        return Song(
            id=row["id"], title=row["title"], artist=row["artist"], album=row["album"],
            year=row["year"], genre=row["genre"], duration=row["duration"], size=row["size"],
            ext=row["ext"], letter=row["letter"], library_path=row["library_path"],
            origin=row["origin"], tagged_from=row["tagged_from"], missing=bool(row["missing"]),
            added_at=row["added_at"], sha256=row["sha256"], abs_path=self.ws.abs(row["library_path"]),
        )

    def song(self, song_id: int) -> Song | None:
        row = self.conn().execute("SELECT * FROM songs WHERE id=?", (song_id,)).fetchone()
        return self._song(row) if row else None

    def songs(self, origin: str | None = None) -> list[Song]:
        sql = "SELECT * FROM songs"
        args: tuple = ()
        if origin:
            sql += " WHERE origin=?"
            args = (origin,)
        sql += " ORDER BY letter, title COLLATE NOCASE, artist COLLATE NOCASE"
        return [self._song(r) for r in self.conn().execute(sql, args)]

    def counts(self) -> dict[str, int]:
        c = self.conn()
        return {
            "og": c.execute("SELECT COUNT(*) FROM songs WHERE origin='og'").fetchone()[0],
            "remix": c.execute("SELECT COUNT(*) FROM songs WHERE origin='remix'").fetchone()[0],
            "files": c.execute("SELECT COUNT(*) FROM files WHERE song_id IS NULL").fetchone()[0],
        }

    def mark_loaded(self, song_id: int) -> None:
        c = self.conn()
        c.execute("UPDATE songs SET last_loaded_at=? WHERE id=?", (_now(), song_id))
        c.commit()

    def recent_songs(self, limit: int = 12) -> list[Song]:
        rows = self.conn().execute(
            "SELECT * FROM songs ORDER BY COALESCE(last_loaded_at, added_at) DESC LIMIT ?", (limit,))
        return [self._song(r) for r in rows]

    # ------------------------------------------------------------------ search index
    def _fts_add(self, c, kind: str, ref: int, title, artist, album, filename) -> None:
        if self.has_fts:
            c.execute("INSERT INTO search_fts(title, artist, album, filename, kind, ref) VALUES(?,?,?,?,?,?)",
                      (title or "", artist or "", album or "", filename or "", kind, str(ref)))

    def _fts_remove(self, c, kind: str, ref: int) -> None:
        if self.has_fts:
            c.execute("DELETE FROM search_fts WHERE kind=? AND ref=?", (kind, str(ref)))

    # ------------------------------------------------------------------ import
    def import_file(self, path: str | Path) -> ImportResult:
        """Bring a file into the workspace so a bar can use it.

        * outside the workspace -> copied into OG Bars/<letter>/, read-only, deduped by content
        * already in OG Bars    -> used in place
        * in Remixed            -> indexed in place as a second-pass source (origin 'remix')
        """
        src = Path(str(path).strip().strip('"')).expanduser()
        if not src.is_file():
            raise ImportError_(f"File not found: {src}")
        if not is_media(src):
            raise ImportError_(f"Not an audio or video file: {src.name}")
        src = src.resolve()

        with self._write_lock:
            c = self.conn()
            in_og = self.ws.contains(src, self.ws.og_bars)
            in_remixed = self.ws.contains(src, self.ws.remixed)
            if in_og or in_remixed:
                rel = self.ws.rel(src)
                row = c.execute("SELECT * FROM songs WHERE library_path=?", (rel,)).fetchone()
                if row:
                    return ImportResult(self._song(row), "existing")

            digest = sha256_file(src)
            row = c.execute("SELECT * FROM songs WHERE sha256=?", (digest,)).fetchone()
            if row:
                c.execute("INSERT OR IGNORE INTO song_sources VALUES(?,?,?)", (row["id"], str(src), _now()))
                self._link_file(c, src, row["id"])
                c.commit()
                return ImportResult(self._song(row), "duplicate", "Already in the library - using the existing copy.")

            info = read_tags(src)
            letter = letter_for(info.title)
            if in_og or in_remixed:
                dest = src  # the app's own folders: index in place
                origin = "remix" if in_remixed else "og"
                status = "indexed"
            else:
                folder = self.ws.letter_dir(letter)
                folder.mkdir(parents=True, exist_ok=True)
                dest = unique_path(folder, library_filename(info.title, info.artist, src.suffix))
                self._copy_verified(src, dest, digest)
                origin, status = "og", "imported"

            cur = c.execute(
                """INSERT INTO songs(sha256, title, artist, album, year, genre, duration, size, ext, letter,
                                     library_path, origin, tagged_from, added_at)
                   VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (digest, info.title, info.artist, info.album, info.year, info.genre, info.duration,
                 dest.stat().st_size, src.suffix.lower(), letter, self.ws.rel(dest), origin,
                 "tags" if info.from_tags else "filename", _now()),
            )
            song_id = cur.lastrowid
            c.execute("INSERT OR IGNORE INTO song_sources VALUES(?,?,?)", (song_id, str(src), _now()))
            self._fts_add(c, "song", song_id, info.title, info.artist, info.album, dest.stem)
            self._link_file(c, src, song_id)
            c.commit()
            return ImportResult(self.song(song_id), status)  # type: ignore[arg-type]

    def _link_file(self, c, src: Path, song_id: int) -> None:
        """A library-folder file that has been copied in stops showing as a separate result."""
        row = c.execute("SELECT id FROM files WHERE path=?", (str(src),)).fetchone()
        if row:
            c.execute("UPDATE files SET song_id=? WHERE id=?", (song_id, row["id"]))
            self._fts_remove(c, "file", row["id"])

    @staticmethod
    def _copy_verified(src: Path, dest: Path, digest: str) -> None:
        tmp = dest.with_name(dest.name + ".part")
        try:
            shutil.copy2(src, tmp)
            if sha256_file(tmp) != digest:
                raise ImportError_(f"Copy of {src.name} did not match the original - not filed.")
            os.replace(tmp, dest)
        finally:
            if tmp.exists():
                tmp.unlink()
        # OG Bars is the untouched original library: make the copy read-only.
        os.chmod(dest, stat.S_IREAD | stat.S_IRGRP | stat.S_IROTH)

    # ------------------------------------------------------------------ library folders
    def add_library_folder(self, path: str | Path) -> Path:
        p = Path(path).expanduser().resolve()
        c = self.conn()
        c.execute("INSERT OR IGNORE INTO library_folders(path, added_at) VALUES(?, ?)", (str(p), _now()))
        c.commit()
        return p

    def remove_library_folder(self, path: str | Path) -> None:
        p = str(Path(path))
        c = self.conn()
        ids = [r[0] for r in c.execute("SELECT id FROM files WHERE folder=?", (p,))]
        for i in ids:
            self._fts_remove(c, "file", i)
        c.execute("DELETE FROM files WHERE folder=?", (p,))
        c.execute("DELETE FROM library_folders WHERE path=?", (p,))
        c.commit()

    def library_folders(self) -> list[Path]:
        return [Path(r[0]) for r in self.conn().execute("SELECT path FROM library_folders ORDER BY path")]

    def scan_folder(
        self,
        folder: str | Path,
        progress: Callable[[int, str], None] | None = None,
        cancel: threading.Event | None = None,
    ) -> dict[str, int]:
        """Index media in a library folder. Incremental: unchanged files are skipped."""
        folder = Path(folder).resolve()
        c = self.conn()
        known = {r["path"]: (r["id"], r["size"], r["mtime"]) for r in
                 c.execute("SELECT id, path, size, mtime FROM files WHERE folder=?", (str(folder),))}
        seen: set[str] = set()
        stats = {"found": 0, "added": 0, "updated": 0, "removed": 0}
        skip_dirs = {"$recycle.bin", "system volume information", "appdata", "node_modules", ".git"}
        pending = 0
        for dirpath, dirnames, filenames in os.walk(folder):
            if cancel is not None and cancel.is_set():
                break
            dp = Path(dirpath)
            # never index the app's own workspace as a "library folder"
            dirnames[:] = [d for d in dirnames
                           if d.lower() not in skip_dirs and not d.startswith(".")
                           and not self.ws.contains(dp / d)]
            for name in filenames:
                if Path(name).suffix.lower() not in MEDIA_EXTS:
                    continue
                p = dp / name
                try:
                    st = p.stat()
                except OSError:
                    continue
                key = str(p)
                seen.add(key)
                stats["found"] += 1
                prev = known.get(key)
                if prev and prev[1] == st.st_size and abs(prev[2] - st.st_mtime) < 1e-6:
                    continue
                info = read_tags(p)
                if prev:
                    c.execute("UPDATE files SET size=?, mtime=?, title=?, artist=?, album=?, duration=? WHERE id=?",
                              (st.st_size, st.st_mtime, info.title, info.artist, info.album, info.duration, prev[0]))
                    self._fts_remove(c, "file", prev[0])
                    fid = prev[0]
                    stats["updated"] += 1
                else:
                    fid = c.execute(
                        """INSERT INTO files(path, folder, size, mtime, title, artist, album, duration, ext)
                           VALUES(?,?,?,?,?,?,?,?,?)""",
                        (key, str(folder), st.st_size, st.st_mtime, info.title, info.artist, info.album,
                         info.duration, p.suffix.lower()),
                    ).lastrowid
                    stats["added"] += 1
                linked = c.execute("SELECT song_id FROM files WHERE id=?", (fid,)).fetchone()[0]
                if linked is None:
                    self._fts_add(c, "file", fid, info.title, info.artist, info.album, p.stem)
                pending += 1
                if pending >= 200:
                    c.commit()
                    pending = 0
                if progress:
                    progress(stats["found"], name)
        if not (cancel is not None and cancel.is_set()):
            for key, (fid, _s, _m) in known.items():
                if key not in seen:
                    self._fts_remove(c, "file", fid)
                    c.execute("DELETE FROM files WHERE id=?", (fid,))
                    stats["removed"] += 1
            c.execute("UPDATE library_folders SET scanned_at=? WHERE path=?", (_now(), str(folder)))
        c.commit()
        return stats

    # ------------------------------------------------------------------ housekeeping
    def reconcile(self) -> dict[str, int]:
        """Flag songs whose file disappeared; index stray media dropped into OG Bars or Remixed by hand."""
        c = self.conn()
        stats = {"missing": 0, "indexed": 0}
        for row in c.execute("SELECT id, library_path, missing FROM songs").fetchall():
            exists = self.ws.abs(row["library_path"]).exists()
            if exists == bool(row["missing"]):
                c.execute("UPDATE songs SET missing=? WHERE id=?", (0 if exists else 1, row["id"]))
            stats["missing"] += 0 if exists else 1
        c.commit()
        known = {r[0] for r in c.execute("SELECT library_path FROM songs")}
        for area in (self.ws.og_bars, self.ws.remixed):
            for p in area.rglob("*"):
                if p.is_file() and is_media(p) and not p.name.endswith(".part") and self.ws.rel(p) not in known:
                    try:
                        self.import_file(p)
                        stats["indexed"] += 1
                    except ImportError_:
                        pass
        return stats

    # ------------------------------------------------------------------ search
    @staticmethod
    def _fts_query(text: str) -> str | None:
        tokens = re.findall(r"\w+", text, re.UNICODE)
        if not tokens:
            return None
        return " ".join(f'"{t}"*' for t in tokens)

    def search(self, text: str, limit: int = 40) -> list[SearchHit]:
        """Live search across OG Bars, Remixed and the library folders. Every word is a prefix."""
        text = (text or "").strip()
        c = self.conn()
        if not text:
            return [self._song_hit(s) for s in self.recent_songs(limit)]
        refs: list[tuple[str, int]] = []
        q = self._fts_query(text) if self.has_fts else None
        if q:
            try:
                rows = c.execute(
                    "SELECT kind, ref, bm25(search_fts, 10.0, 6.0, 2.0, 1.0) AS r FROM search_fts "
                    "WHERE search_fts MATCH ? ORDER BY r LIMIT ?", (q, limit * 2)).fetchall()
                # songs already in the workspace rank just ahead of equally good folder files
                rows = sorted(rows, key=lambda r: (r["r"] - (0.25 if r["kind"] == "song" else 0.0)))
                refs = [(r["kind"], int(r["ref"])) for r in rows]
            except sqlite3.OperationalError:
                refs = []
        if not refs:
            like = f"%{text}%"
            refs = [("song", r[0]) for r in c.execute(
                "SELECT id FROM songs WHERE title LIKE ? OR artist LIKE ? OR album LIKE ? LIMIT ?",
                (like, like, like, limit))]
            refs += [("file", r[0]) for r in c.execute(
                "SELECT id FROM files WHERE song_id IS NULL AND (title LIKE ? OR artist LIKE ? OR path LIKE ?) LIMIT ?",
                (like, like, like, limit))]
        hits: list[SearchHit] = []
        for kind, ref in refs:
            hit = self._hit(kind, ref)
            if hit:
                hits.append(hit)
            if len(hits) >= limit:
                break
        return hits

    def _song_hit(self, s: Song) -> SearchHit:
        where = f"OG Bars / {s.letter}" if s.origin == "og" else "Remixed"
        return SearchHit("song", s.id, s.title, s.artist, s.album, s.duration, s.ext, s.abs_path, where)

    def _hit(self, kind: str, ref: int) -> SearchHit | None:
        if kind == "song":
            s = self.song(ref)
            return self._song_hit(s) if s else None
        row = self.conn().execute("SELECT * FROM files WHERE id=? AND song_id IS NULL", (ref,)).fetchone()
        if not row:
            return None
        return SearchHit("file", row["id"], row["title"], row["artist"], row["album"], row["duration"],
                         row["ext"], Path(row["path"]), Path(row["folder"]).name or row["folder"])

    def tree(self) -> dict[str, list[Song]]:
        """OG Bars songs grouped by letter folder, for the library browser."""
        out: dict[str, list[Song]] = {}
        for s in self.songs("og"):
            out.setdefault(s.letter, []).append(s)
        return out

