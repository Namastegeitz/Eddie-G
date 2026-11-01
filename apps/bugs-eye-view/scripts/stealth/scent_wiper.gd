class_name ScentWiper
extends Area3D
## Spilled water, vinegar, sprinkler spray: wipes the scent trail inside it,
## and the player leaves no new scent while standing in it.

@export var wipe_radius: float = 4.0
@export var active_events: PackedStringArray = []

var _player: BugBase = null
var _active := true


func _ready() -> void:
	collision_layer = Phys.ZONE
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(func(b: Node3D) -> void:
		if b is BugBase:
			_player = b
			_player.wiper_count += 1)
	body_exited.connect(func(b: Node3D) -> void:
		if b is BugBase:
			(b as BugBase).wiper_count -= 1
			_player = null)
	HouseClock.routine_changed.connect(func() -> void:
		_active = active_events.is_empty() or HouseClock.any_active(active_events))


func _physics_process(_delta: float) -> void:
	if _active and _player:
		PerceptionSystem.scent.wipe_sphere(_player.global_position, wipe_radius)
