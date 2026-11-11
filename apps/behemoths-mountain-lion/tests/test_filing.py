from bml.filing import is_media, letter_for, library_filename, safe_filename, unique_path
from bml.tags import guess_from_filename


def test_letters():
    assert letter_for("Rejoice") == "R"
    assert letter_for("the mountain") == "T"
    assert letter_for("Évora") == "E"
    assert letter_for("...Ready For It?") == "R"
    assert letter_for("99 Problems") == "#"
    assert letter_for("") == "#"
    assert letter_for("夜に駆ける") == "#"


def test_safe_filenames():
    assert safe_filename('AC/DC: "Back" <In> Black?') == "AC DC Back In Black"
    assert safe_filename("CON") == "_CON"
    assert safe_filename("trailing dots...") == "trailing dots"
    assert safe_filename("   ") == "Untitled"
    assert len(safe_filename("x" * 400)) == 150
    assert library_filename("Song", "Band", ".MP3") == "Band - Song.mp3"
    assert library_filename("Song", None, ".flac") == "Song.flac"


def test_unique_path(tmp_path):
    (tmp_path / "a.wav").write_bytes(b"1")
    (tmp_path / "a (2).wav").write_bytes(b"2")
    assert unique_path(tmp_path, "a.wav").name == "a (3).wav"
    assert unique_path(tmp_path, "b.wav").name == "b.wav"


def test_media_types():
    assert is_media("x.MP3") and is_media("clip.mp4") and not is_media("notes.txt")


def test_filename_guessing():
    t, a = guess_from_filename(
        "785b22e4-steve-angello-rejoice-still-young-remix-feat-t-d-jakes-official-visualizer-ytmp4.savetube.vip_copy")
    assert t == "Steve Angello Rejoice Still Young Remix feat. T D Jakes"
    assert a is None
    assert guess_from_filename("Nightfall Choir - Iron Valley (Official Video)") == ("Iron Valley", "Nightfall Choir")
    assert guess_from_filename("Cold Front - Embers [HD] (1)") == ("Embers", "Cold Front")
    assert guess_from_filename("just_a_title") == ("Just a Title", None)
