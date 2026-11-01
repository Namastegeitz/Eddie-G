class_name Drain
extends Area3D
## A sink or patio drain. While water runs it pulls bugs toward the center;
## reach the middle and you're washed away (a hit, then you crawl out).

@export var pull_strength: float = 45.0
@export var kill_radius: float = 1.2
@export var respawn_path: NodePath
@export var active_events: PackedStringArray = []

var _player: BugBase = null
var _active := true


func _ready() -> void:
	collision_layer = Phys.HAZARD
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
	var water := get_node_or_null("Water") as Node3D
	if water:
		water.visible = _active


func _physics_process(delta: float) -> void:
	if not _active or _player == null or _player.dead:
		return
	if _player is Fly and (_player as Fly).flying:
		return
	var to := global_position - _player.global_position
	to.y = 0.0
	if to.length() <= kill_radius:
		AudioManager.play_at(&"gurgle", global_position)
		_player.take_hit(&"drained", global_position)
		var spawn := get_node_or_null(respawn_path) as Node3D
		if spawn and not _player.dead:
			_player.teleport_to(spawn.global_transform)
		return
	_player.apply_force(to.normalized() * pull_strength, delta)
