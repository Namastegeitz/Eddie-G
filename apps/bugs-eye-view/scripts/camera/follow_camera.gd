class_name FollowCamera
extends Node3D
## Third-person orbit camera on a spring arm (never clips through walls).
## Look input comes only from InputRouter. Adapts FOV to portrait/landscape
## and plays screen shake from Feedback.

@export var distance: float = 8.0
@export var height: float = 1.6
@export var min_pitch: float = -1.25
@export var max_pitch: float = 0.15
@export var follow_speed: float = 12.0
@export var look_scale: float = 0.004

var target: BugBase
var yaw := 0.0
var pitch := -0.35
var camera: Camera3D
var arm: SpringArm3D
var _shake := 0.0
var _shake_time := 0.0


func _ready() -> void:
	arm = get_node_or_null("Arm") as SpringArm3D
	if arm == null:
		arm = SpringArm3D.new()
		arm.name = "Arm"
		add_child(arm)
	arm.spring_length = distance
	arm.collision_mask = Phys.WORLD
	arm.margin = 0.4
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	arm.shape = sphere
	camera = arm.get_node_or_null("Camera") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera"
		arm.add_child(camera)
	camera.near = 0.05
	camera.far = 800.0
	camera.current = true
	Feedback.shake_requested.connect(_on_shake)
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()


func set_target(t: BugBase) -> void:
	target = t
	t.cam = self
	yaw = t.global_rotation.y
	t.rotation.y = 0.0
	# Start with the bug facing away from the camera.
	t.facing = -Basis(Vector3.UP, yaw).z
	if t.visual:
		t.visual.rotation.y = yaw
	snap()


func snap() -> void:
	if target:
		global_position = target.global_position + Vector3.UP * height
		rotation = Vector3(pitch, yaw, 0.0)
		target.camera_yaw_basis = Basis(Vector3.UP, yaw)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var look := InputRouter.get_look_delta(delta)
	yaw -= look.x * look_scale
	pitch = clampf(pitch - look.y * look_scale, min_pitch, max_pitch)
	rotation = Vector3(pitch, yaw, 0.0)
	target.camera_yaw_basis = Basis(Vector3.UP, yaw)
	var goal := target.global_position + Vector3.UP * height
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
	if _shake_time > 0.0:
		_shake_time -= delta
		var s := _shake * clampf(_shake_time * 4.0, 0.0, 1.0)
		camera.h_offset = randf_range(-s, s) * 0.5
		camera.v_offset = randf_range(-s, s) * 0.5
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func get_forward() -> Vector3:
	return -camera.global_basis.z


func screen_center() -> Vector2:
	return get_viewport().get_visible_rect().size * 0.5


func _on_shake(strength: float, duration: float) -> void:
	_shake = maxf(_shake if _shake_time > 0.0 else 0.0, strength)
	_shake_time = maxf(_shake_time, duration)


func _on_resize() -> void:
	var s := get_viewport().get_visible_rect().size
	if s.y > s.x:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = 72.0
	else:
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.fov = 62.0
