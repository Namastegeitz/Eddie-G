class_name AntDecoy
extends Node3D
## A column of decoy ants marching away from the real one. Every beat they
## rustle (a lure noise that threats come to investigate). They turn aside
## when something blocks their way.

var direction := Vector3.FORWARD
var time_left := 6.0
var speed := 4.5
var loudness := 1.8
var _beat := 0.3
var _t := 0.0
var _ants: Array[Node3D] = []
var _ray := PhysicsRayQueryParameters3D.new()


func _ready() -> void:
	direction.y = 0.0
	direction = direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	_ray.collision_mask = Phys.WORLD
	var body := SphereMesh.new()
	body.radius = 0.16
	body.height = 0.32
	body.radial_segments = 6
	body.rings = 3
	var mat: Material = load("res://assets/materials/ant.tres")
	for i in 6:
		var a := MeshInstance3D.new()
		a.mesh = body
		a.material_override = mat
		a.scale = Vector3(1.0, 0.7, 2.2)
		a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(a)
		_ants.append(a)


func _physics_process(delta: float) -> void:
	_t += delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
		return
	# Turn aside before walking into furniture or a wall.
	_ray.from = global_position + Vector3.UP * 0.4
	_ray.to = _ray.from + direction * 1.6
	if not get_world_3d().direct_space_state.intersect_ray(_ray).is_empty():
		direction = direction.rotated(Vector3.UP, PI * 0.5 * (1.0 if randf() > 0.5 else -1.0))
	global_position += direction * speed * delta
	var yaw := atan2(-direction.x, -direction.z)
	for i in _ants.size():
		var a := _ants[i]
		a.position = -direction * (i * 0.75) + Vector3(sin(_t * 9.0 + i) * 0.12, 0.15, 0)
		a.rotation.y = yaw
	_beat -= delta
	if _beat <= 0.0:
		_beat = 0.9
		PerceptionSystem.emit_world_noise(global_position, loudness)
