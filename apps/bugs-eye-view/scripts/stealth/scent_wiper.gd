class_name ScentWiper
extends Area3D
## Spilled water, vinegar, sprinkler spray: wipes the scent trail inside it,
## and the player leaves no new scent while standing in it.

@export var wipe_radius: float = 4.0
@export var active_events: PackedStringArray = []

var _player: BugBase = null
var _active := true


func _ready() -> void:
	add_to_group(&"water")
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
	HouseClock.routine_changed.connect(_refresh)
	_refresh()


func is_wet() -> bool:
	return _active


## Whether a point (a pet's paws) is in the water.
func covers(pos: Vector3) -> bool:
	for c in get_children():
		var cs := c as CollisionShape3D
		if cs and cs.shape is BoxShape3D:
			var local := (cs.global_transform.affine_inverse() * pos)
			var half := (cs.shape as BoxShape3D).size * 0.5
			return absf(local.x) <= half.x and absf(local.z) <= half.z and absf(local.y) <= half.y + 1.5
	return false


func _refresh() -> void:
	_active = active_events.is_empty() or HouseClock.any_active(active_events)


func _physics_process(_delta: float) -> void:
	if _active and _player:
		PerceptionSystem.scent.wipe_sphere(_player.global_position, wipe_radius)
