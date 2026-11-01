class_name WindZone
extends Area3D
## A fan's air stream. Pushes flying flies hard and airborne bugs a little.

@export var direction: Vector3 = Vector3.FORWARD
@export var strength: float = 60.0
@export var active_events: PackedStringArray = []

var _player: BugBase = null
var _active := true


func _ready() -> void:
	collision_layer = Phys.ZONE
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(func(b: Node3D) -> void:
		if b is BugBase:
			_player = b)
	body_exited.connect(func(b: Node3D) -> void:
		if b == _player:
			_player = null)
	HouseClock.routine_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_active = active_events.is_empty() or HouseClock.any_active(active_events)
	for c in get_children():
		if c is Node3D and c.name.begins_with("Gust"):
			(c as Node3D).visible = _active


func is_active() -> bool:
	return _active


func _physics_process(delta: float) -> void:
	if not _active or _player == null or _player.dead:
		return
	var k := 0.0
	if _player is Fly and (_player as Fly).flying:
		k = 1.0
	elif not _player.is_on_floor():
		k = 0.3
	if k > 0.0:
		_player.apply_force(global_basis * direction.normalized() * strength * k, delta)
