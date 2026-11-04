extends Node
## Sound effects, per-region music, the rainforest ambience and haptics.
## Music files are named in each map's content file ("music.file"); SFX are
## res://assets/audio/sfx/<name>.ogg. Missing files are skipped silently.

const SFX_DIR := "res://assets/audio/sfx/%s.ogg"
const AMBIENT := "res://assets/audio/music/ambience.ogg"
const MENU_MUSIC := "res://assets/audio/music/menu.ogg"

var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _cache := {}
var _current_music := ""
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	_ambient = AudioStreamPlayer.new()
	for p in [_music, _music_b, _ambient]:
		add_child(p)
	apply_volumes()
	Save.changed.connect(apply_volumes)


func apply_volumes() -> void:
	var mv := float(Save.setting("music", 0.7))
	var sv := float(Save.setting("sfx", 0.9))
	_music.volume_db = _db(mv) - 4.0
	_music_b.volume_db = _db(mv) - 4.0
	_ambient.volume_db = _db(mv) - 10.0
	for p in _players:
		p.volume_db = _db(sv)


func _db(v: float) -> float:
	return linear_to_db(maxf(0.0001, v))


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[path] = s
	return s


func play(name: String, pitch := 1.0, vol := 0.0) -> void:
	if float(Save.setting("sfx", 0.9)) <= 0.01:
		return
	var s := _load(SFX_DIR % name)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = _db(float(Save.setting("sfx", 0.9))) + vol
	p.play()


func music(path: String) -> void:
	if path == _current_music:
		return
	_current_music = path
	var s := _load(path)
	var old := _music
	_music = _music_b
	_music_b = old
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_music_b, "volume_db", -40.0, 0.8)
	tw.chain().tween_callback(_music_b.stop)
	if s:
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		_music.stream = s
		_music.volume_db = -40.0
		_music.play()
		create_tween().tween_property(_music, "volume_db", _db(float(Save.setting("music", 0.7))) - 4.0, 1.0)
	if not _ambient.playing:
		var a := _load(AMBIENT)
		if a:
			if a is AudioStreamOggVorbis:
				(a as AudioStreamOggVorbis).loop = true
			_ambient.stream = a
			_ambient.play()


func map_music(map_id: String) -> void:
	music(String(Content.map(map_id).get("music", {}).get("file", MENU_MUSIC)))


func menu_music() -> void:
	music(MENU_MUSIC)


func haptic(ms: int) -> void:
	if bool(Save.setting("haptics", true)) and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
