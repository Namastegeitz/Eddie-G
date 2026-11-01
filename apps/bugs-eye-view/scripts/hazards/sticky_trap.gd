class_name StickyTrap
extends Area3D
## Glue trap / fly paper. Slows a bug touching it, then sticks it in place.
## Mash any button to tear free (roaches tear free twice as fast).

@export var slow_mult: float = 0.35
@export var stick_delay: float = 0.6
@export var stuck_seconds: float = 3.0
## Fly paper hangs in the air and only catches flying flies.
@export var catches_flyers: bool = false

var _player: BugBase = null
var _inside := 0.0


func _ready() -> void:
	collision_layer = Phys.HAZARD
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(func(b: Node3D) -> void:
		if b is BugBase:
			_player = b
			_inside = 0.0)
	body_exited.connect(func(b: Node3D) -> void:
		if b == _player:
			_player = null)


func _physics_process(delta: float) -> void:
	if _player == null or _player.dead or _player.is_hidden_safe():
		return
	var flying := _player is Fly and (_player as Fly).flying
	if flying != catches_flyers:
		return
	_inside += delta
	_player.set_slowed(slow_mult, 0.3)
	if _inside >= stick_delay and _player.stuck_time <= 0.0:
		var secs := stuck_seconds * (0.5 if _player is Cockroach else 1.0)
		_player.set_stuck(secs)
		if _player is Fly:
			(_player as Fly).land()
		AudioManager.play_at(&"squelch", global_position)
		_inside = -secs - 1.5
