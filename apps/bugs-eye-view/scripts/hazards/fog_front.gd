class_name FogFront
extends Node3D
## The exterminator's fog: a wall of spray that sweeps across the yard along
## its local -Z axis. Anything behind the front breathes it in.

@export var travel: float = 120.0
@export var duration: float = 70.0
@export var width: float = 200.0
@export var exposure_rate: float = 1.6

var running := false
var _t := 0.0
var _start := Vector3.ZERO
var _mesh: Node3D


func _ready() -> void:
	_mesh = get_node_or_null("Mesh")
	_start = global_position
	visible = false


func start() -> void:
	running = true
	_t = 0.0
	visible = true
	AudioManager.play_at(&"spray", global_position, 6.0, 0.6)


func front_position() -> Vector3:
	return _start + (-global_basis.z) * travel * clampf(_t / duration, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if not running:
		return
	_t += delta
	global_position = front_position()
	var p := PerceptionSystem.player
	if p == null or p.dead:
		return
	# Behind the front = the side it came from (+Z local).
	var local := global_transform.affine_inverse() * p.global_position
	if local.z > 0.0 and absf(local.x) < width * 0.5:
		p.add_spray_exposure(exposure_rate * delta)
