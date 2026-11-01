class_name SprayCloud
extends Node3D
## Bug-spray cloud: spreads, lingers, fades. Breathing it builds exposure;
## a full dose counts as a hit. Pooled.

@export var max_radius: float = 6.0
@export var grow_time: float = 0.8
@export var life: float = 6.0
@export var exposure_rate: float = 1.0

var _t := 0.0
var _pool: NodePool
var _radius := 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = get_node_or_null("Mesh") as MeshInstance3D


func spawn(pos: Vector3, pool: NodePool, radius: float = -1.0) -> void:
	_pool = pool
	_t = 0.0
	if radius > 0.0:
		max_radius = radius
	global_position = pos
	AudioManager.play_at(&"spray", pos)


func _physics_process(delta: float) -> void:
	_t += delta
	_radius = max_radius * minf(_t / grow_time, 1.0)
	if _mesh:
		_mesh.scale = Vector3.ONE * maxf(_radius, 0.01)
		_mesh.transparency = clampf((_t - (life - 1.0)) / 1.0, 0.0, 1.0) * 0.9 + 0.1
	var p := PerceptionSystem.player
	if p and not p.dead and p.global_position.distance_to(global_position) < _radius:
		p.add_spray_exposure(exposure_rate * delta)
	if _t >= life and _pool:
		_pool.release(self)


func contains(pos: Vector3) -> bool:
	return pos.distance_to(global_position) < _radius
