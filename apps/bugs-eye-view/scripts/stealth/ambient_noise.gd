class_name AmbientNoise
extends Node3D
## A household noise source (fridge hum, TV, dishwasher, vacuum, sprinkler).
## While active it masks the player's noise inside its radius.

@export var radius: float = 30.0
@export var level: float = 0.6
@export var sound_key: StringName = &""
@export var volume_db: float = -8.0
@export var muffled: bool = false
@export var active_events: PackedStringArray = []
@export var inactive_events: PackedStringArray = []

var _active := true
var _emitter: AudioStreamPlayer3D
var _boost := 0.0
var _base_level := 0.0


func _ready() -> void:
	_base_level = level
	PerceptionSystem.register_noise_source(self)
	if sound_key != &"":
		_emitter = AudioManager.make_loop_emitter(sound_key, self, volume_db, &"Muffled" if muffled else &"Ambience")
	HouseClock.routine_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	PerceptionSystem.unregister_noise_source(self)


func is_active() -> bool:
	return _active or _boost > 0.0


## Temporarily louder (TV remote turned up): masks more, and is itself a lure.
func boost(extra_level: float, seconds: float) -> void:
	_boost = seconds
	level = _base_level + extra_level
	AudioManager.start_loop(_emitter)
	if _emitter:
		_emitter.volume_db = volume_db + 8.0
	set_process(true)


func _process(delta: float) -> void:
	if _boost > 0.0:
		_boost -= delta
		if _boost <= 0.0:
			level = _base_level
			if _emitter:
				_emitter.volume_db = volume_db
			_refresh()
			set_process(false)


func _refresh() -> void:
	if not is_inside_tree():
		return
	_active = (active_events.is_empty() or HouseClock.any_active(active_events)) \
		and not HouseClock.any_active(inactive_events)
	if _active or _boost > 0.0:
		AudioManager.start_loop(_emitter)
	else:
		AudioManager.stop_loop(_emitter)
