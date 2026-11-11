import os
import stat

import pytest

from bml.library import ImportError_, Library, sha256_file
from bml.workspace import LETTER_FOLDERS, OTHER_FOLDER, ensure_workspace
from conftest import make_wav


def test_workspace_tree(ws, lib):
    for name in ("OG Bars", "Remixed", "Stems"):
        assert (ws.root / name).is_dir()
    assert sorted(p.name for p in ws.og_bars.iterdir()) == sorted(LETTER_FOLDERS + [OTHER_FOLDER])
    assert ws.db_path.is_file()
    ensure_workspace(ws.root)  # idempotent
    assert Library(ws).get_meta("created_at")


def test_import_files_by_title_and_never_touches_the_source(lib, ws, outside):
    src = make_wav(outside / "track01.wav", title="Rebel Heart", artist="Iron Valley", album="Ridge")
    before = sha256_file(src)
    res = lib.import_file(src)
    assert res.status == "imported"
    s = res.song
    assert (s.title, s.artist, s.album, s.letter, s.origin, s.tagged_from) == (
        "Rebel Heart", "Iron Valley", "Ridge", "R", "og", "tags")
    assert s.library_path == "OG Bars/R/Iron Valley - Rebel Heart.wav"
    assert s.abs_path.is_file()
    assert sha256_file(s.abs_path) == before == sha256_file(src)
    assert not os.stat(s.abs_path).st_mode & stat.S_IWUSR  # read-only copy


def test_dedupe_by_content(lib, outside):
    a = make_wav(outside / "a.wav", title="Same Song", artist="X")
    b = outside / "renamed copy.wav"
    b.write_bytes(a.read_bytes())
    first = lib.import_file(a)
    again = lib.import_file(a)
    renamed = lib.import_file(b)
    assert again.status == renamed.status == "duplicate"
    assert again.song.id == renamed.song.id == first.song.id
    assert len(list(first.song.abs_path.parent.iterdir())) == 1


def test_same_title_different_audio_gets_numbered(lib, outside):
    one = lib.import_file(make_wav(outside / "1.wav", title="Echo", freq=200)).song
    two = lib.import_file(make_wav(outside / "2.wav", title="Echo", freq=300)).song
    assert one.id != two.id
    assert one.abs_path.name == "Echo.wav" and two.abs_path.name == "Echo (2).wav"


def test_untagged_file_is_titled_from_its_name(lib, outside):
    src = make_wav(outside / "Cold Front - Embers (Official Video).wav")
    s = lib.import_file(src).song
    assert (s.title, s.artist, s.letter, s.tagged_from) == ("Embers", "Cold Front", "E", "filename")


def test_quoted_windows_style_path_and_errors(lib, outside):
    src = make_wav(outside / "q.wav", title="Quoted")
    assert lib.import_file(f'"{src}"').song.title == "Quoted"
    with pytest.raises(ImportError_):
        lib.import_file(outside / "nope.wav")
    (outside / "notes.txt").write_text("hi")
    with pytest.raises(ImportError_):
        lib.import_file(outside / "notes.txt")


def test_files_already_in_workspace_are_used_in_place(lib, ws, outside):
    s = lib.import_file(make_wav(outside / "x.wav", title="Anthem")).song
    assert lib.import_file(s.abs_path).status == "existing"
    pair = ws.remixed / "Anthem x Other"
    render = make_wav(pair / "A-on-B.wav", freq=500)
    res = lib.import_file(render)
    assert res.status == "indexed" and res.song.origin == "remix"
    assert res.song.library_path == "Remixed/Anthem x Other/A-on-B.wav"
    assert render.is_file()  # second-pass sources stay where they are


def test_reconcile_flags_missing_and_indexes_strays(lib, ws, outside):
    s = lib.import_file(make_wav(outside / "m.wav", title="Lost")).song
    os.chmod(s.abs_path, stat.S_IWUSR | stat.S_IRUSR)
    s.abs_path.unlink()
    make_wav(ws.letter_dir("Z") / "Zenith.wav", title="Zenith")
    stats = lib.reconcile()
    assert stats == {"missing": 1, "indexed": 1}
    assert lib.song(s.id).missing


def test_tree_groups_by_letter(lib, outside):
    for i, t in enumerate(["Alpha", "Amber", "Bravo", "7 Rings"]):
        lib.import_file(make_wav(outside / f"{i}.wav", title=t, freq=100 + i * 50))
    tree = lib.tree()
    assert [s.title for s in tree["A"]] == ["Alpha", "Amber"]
    assert [s.title for s in tree["#"]] == ["7 Rings"]
    assert lib.counts()["og"] == 4
