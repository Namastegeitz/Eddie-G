extends Node
## SFX + music buses, pooled players, a heartbeat layer that follows tension,
## and a "Muffled" low-pass bus that makes human voices sound giant and distant.
## Sounds are looked up by key in a SoundLibrary resource so they can be swapped.

const LIBRARY_PATH := "res://resources/audio/sound_library.tres"
const POOL_2D := 10
const POOL_3D := 16

var library: SoundLibrary
var _players_2d: Array[AudioStreamPlayer] = []
var _players_3d: Array[AudioStreamPlayer3D] = []
var _next_2d := 0
var _next_3d := 0
var _music: AudioStreamPlayer
var _heartbeat: AudioStreamPlayer
var _tension := 0.0
var _tension_target := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_buses()
	if ResourceLoader.exists(LIBRARY_PATH):
		library = load(LIBRARY_PATH)
	else:
		library = SoundLibrary.new()
	for i in POOL_2D:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players_2d.append(p)
	for i in POOL_3D:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = &"SFX"
		p3.unit_size = 12.0
		p3.max_distance = 120.0
		add_child(p3)
		_players_3d.append(p3)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
	_heartbeat = AudioStreamPlayer.new()
	_heartbeat.bus = &"SFX"
	_heartbeat.volume_db = -80.0
	add_child(_heartbeat)
	SaveSystem.settings_changed.connect(apply_volumes)
	apply_volumes()


## Stop every player before shutdown so no playback outlives the engine.
func stop_all() -> void:
	for n in get_tree().root.find_children("*", "AudioStreamPlayer3D", true, false):
		(n as AudioStreamPlayer3D).stop()
	_exit_tree()


func _exit_tree() -> void:
	_music.stop()
	_heartbeat.stop()
	for p in _players_2d:
		p.stop()
		p.stream = null
	for p3 in _players_3d:
		p3.stop()
		p3.stream = null
	_music.stream = null
	_heartbeat.stream = null


func _build_buses() -> void:
	for bus_name: StringName in [&"Music", &"SFX", &"Ambience", &"Muffled"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	AudioServer.set_bus_send(AudioServer.get_bus_index(&"Music"), &"Master")
	AudioServer.set_bus_send(AudioServer.get_bus_index(&"SFX"), &"Master")
	AudioServer.set_bus_send(AudioServer.get_bus_index(&"Ambience"), &"SFX")
	var muffled := AudioServer.get_bus_index(&"Muffled")
	AudioServer.set_bus_send(muffled, &"SFX")
	if AudioServer.get_bus_effect_count(muffled) == 0:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 700.0
		AudioServer.add_bus_effect(muffled, lp)
		var rev := AudioEffectReverb.new()
		rev.room_size = 0.6
		rev.wet = 0.25
		AudioServer.add_bus_effect(muffled, rev)


func apply_volumes() -> void:
	_set_bus_linear(&"Master", float(SaveSystem.get_setting("master_volume", 0.9)))
	_set_bus_linear(&"Music", float(SaveSystem.get_setting("music_volume", 0.6)))
	_set_bus_linear(&"SFX", float(SaveSystem.get_setting("sfx_volume", 0.9)))


func _set_bus_linear(bus_name: StringName, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(idx, v <= 0.001)


func get_stream(key: StringName) -> AudioStream:
	return library.sounds.get(key) as AudioStream


func play(key: StringName, volume_db: float = 0.0, pitch: float = 1.0, bus: StringName = &"SFX") -> void:
	var s := get_stream(key)
	if s == null:
		return
	var p := _players_2d[_next_2d]
	_next_2d = (_next_2d + 1) % _players_2d.size()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = bus
	p.play()


func play_at(key: StringName, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0, bus: StringName = &"SFX") -> void:
	var s := get_stream(key)
	if s == null:
		return
	var p := _players_3d[_next_3d]
	_next_3d = (_next_3d + 1) % _players_3d.size()
	p.stream = s
	p.global_position = pos
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = bus
	p.play()


## Creates a looping positional emitter parented to `parent` (fridge hum, TV, vacuum).
func make_loop_emitter(key: StringName, parent: Node3D, volume_db: float = 0.0, bus: StringName = &"Ambience") -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = get_stream(key)
	p.bus = bus
	p.volume_db = volume_db
	p.unit_size = 14.0
	p.max_distance = 140.0
	parent.add_child(p)
	p.finished.connect(func() -> void:
		if p.is_inside_tree() and p.get_meta("looping", false):
			p.play())
	return p


func start_loop(p: AudioStreamPlayer3D) -> void:
	if p and p.stream and not p.playing and p.is_inside_tree():
		p.set_meta("looping", true)
		p.play()


func stop_loop(p: AudioStreamPlayer3D) -> void:
	if p:
		p.set_meta("looping", false)
		p.stop()


func play_music(key: StringName) -> void:
	var s := get_stream(key)
	if s == null or (_music.stream == s and _music.playing):
		return
	_music.stream = s
	_music.play()
	if not _music.finished.is_connected(_music.play):
		_music.finished.connect(_music.play)
	if _heartbeat.stream == null:
		_heartbeat.stream = get_stream(&"heartbeat")
		_heartbeat.finished.connect(_heartbeat.play)


func stop_music() -> void:
	_music.stop()
	set_tension(0.0)


## 0 = calm, 1 = being hunted. Drives the heartbeat layer's volume and pitch.
func set_tension(t: float) -> void:
	_tension_target = clampf(t, 0.0, 1.0)


func _process(delta: float) -> void:
	_tension = move_toward(_tension, _tension_target, delta * 0.8)
	if _heartbeat.stream == null:
		return
	if _tension > 0.02:
		if not _heartbeat.playing:
			_heartbeat.play()
		_heartbeat.volume_db = linear_to_db(_tension) - 2.0
		_heartbeat.pitch_scale = 0.9 + _tension * 0.6
	elif _heartbeat.playing:
		_heartbeat.stop()
