from conftest import make_wav


def _setup(lib, outside):
    make_wav(outside / "a.wav", title="Rebel Yell", artist="Northbound", freq=200)
    make_wav(outside / "b.wav", title="Rejoice", artist="Halcyon Drift", freq=250)
    make_wav(outside / "c.wav", title="Beyoncé Tribute Medley", artist="Cover Band", freq=300)
    make_wav(outside / "sub" / "d.wav", title="Mountain Call", artist="Rebecca Stone", freq=350)
    lib.add_library_folder(outside)
    return lib.scan_folder(outside)


def test_scan_is_incremental(lib, outside):
    assert _setup(lib, outside) == {"found": 4, "added": 4, "updated": 0, "removed": 0}
    assert lib.scan_folder(outside) == {"found": 4, "added": 0, "updated": 0, "removed": 0}
    (outside / "a.wav").unlink()
    assert lib.scan_folder(outside)["removed"] == 1
    assert lib.counts()["files"] == 3


def test_prefix_search_live(lib, outside):
    _setup(lib, outside)
    titles = lambda q: [h.title for h in lib.search(q)]  # noqa: E731
    assert set(titles("re")) == {"Rebel Yell", "Rejoice", "Mountain Call"}  # "Rebecca" matches by artist
    assert titles("rej") == ["Rejoice"]
    assert titles("reb yel") == ["Rebel Yell"]
    assert titles("beyonce") == ["Beyoncé Tribute Medley"]  # accents don't matter
    assert titles("halcyon") == ["Rejoice"]
    assert titles("zzz") == []
    assert titles('"(') == []  # punctuation alone never errors


def test_loaded_file_moves_from_folder_result_to_song(lib, outside):
    _setup(lib, outside)
    hit = lib.search("rejoice")[0]
    assert hit.kind == "file"
    song = lib.import_file(hit.path).song
    hits = lib.search("rejoice")
    assert [(h.kind, h.id) for h in hits] == [("song", song.id)]
    assert hits[0].where == "OG Bars / R"


def test_empty_query_shows_recent_songs(lib, outside):
    _setup(lib, outside)
    s = lib.import_file(outside / "b.wav").song
    lib.mark_loaded(s.id)
    assert [h.title for h in lib.search("")] == ["Rejoice"]


def test_remove_library_folder(lib, outside):
    _setup(lib, outside)
    lib.remove_library_folder(outside.resolve())
    assert lib.search("rebel") == [] and lib.counts()["files"] == 0
