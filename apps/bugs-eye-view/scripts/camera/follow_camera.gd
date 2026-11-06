class_name FollowCamera
extends Node3D
## Third-person orbit camera on a spring arm (never clips through walls).
## Look input comes only from InputRouter. Adapts FOV to portrait/landscape
## and plays screen shake from Feedback.
##
## Smooth at any frame rate: it follows the bug's interpolated (displayed)
## position, not its last physics step, and when a wall gets in the way it
## pulls in quickly and eases back out instead of snapping.
##
## Bug's-eye view (first person): the camera sits at the bug's sculpted eyes
## (Visual/EyePoint), the body turns with your view, and you see your own
## antennae, mouthparts and front legs move. A gentle bob follows the gait.
## The spider's view follows the wall or ceiling it's on (up is the surface).

@export var distance: float = 8.0
@export var height: float = 1.6
@export var min_pitch: float = -1.25
@export var max_pitch: float = 0.15
@export var follow_speed: float = 12.0
@export var look_scale: float = 0.004

var target: BugBase
var first_person := false
const FP_MIN_PITCH := -1.35
const FP_MAX_PITCH := 1.2
## Gait bob (fraction of a bug body length) and its sway.
const FP_BOB := 0.025
var _fp_basis := Basis.IDENTITY
var _fp_eye: Node3D
var _overlay: CanvasLayer
var _tp_fov := 62.0
## How quickly a touch drag turns the view: lower = smoother and slower.
@export var touch_look_smoothing: float = 9.0
var yaw := 0.0
var _touch_pending := Vector2.ZERO
var pitch := -0.35
## The resting view angle (the fly's look-steering measures tilt from it).
const DEFAULT_PITCH := -0.35
var camera: Camera3D
var arm: SpringArm3D
var _shake := 0.0
var _shake_time := 0.0
## Current camera distance (eases toward what the spring arm allows).
var _len := 8.0
const PULL_IN_RATE := 30.0
const EASE_OUT_RATE := 5.0


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
		camera = get_node_or_null("Camera") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera"
		add_child(camera)
	elif camera.get_parent() == arm:
		# The arm only measures; the camera eases to that distance itself.
		arm.remove_child(camera)
		add_child(camera)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_len = distance
	camera.position = Vector3(0, 0, _len)
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
	_fp_eye = t.visual.get_node_or_null("EyePoint") as Node3D if t.visual else null
	set_first_person(bool(SaveSystem.get_setting("first_person", false)))
	snap()


## The resting look angle: level through the bug's eyes, looking down behind it.
func rest_pitch() -> float:
	return 0.0 if first_person else DEFAULT_PITCH


## Switch between the third-person view and the bug's-eye view.
func set_first_person(on: bool) -> void:
	on = on and _fp_eye != null
	var changed := on != first_person
	first_person = on
	if changed or on:
		pitch = rest_pitch()
	if camera:
		camera.near = 0.015 if on else 0.05
		camera.position = Vector3.ZERO if on else Vector3(0, 0, _len)
	_on_resize()
	_update_overlay()
	if target:
		var arrow := target.get_node_or_null("SenseArrow") as Node3D
		if arrow:
			# The smell arrow floats just ahead of your eyes in first person.
			arrow.position = Vector3(0, 0.5, -1.7) if on else Vector3(0, 1.4, 0)
	_fp_basis = global_basis
	if on and target:
		_place_fp(0.0, true)


func snap() -> void:
	_touch_pending = Vector2.ZERO
	_len = distance
	if first_person and target:
		target.camera_yaw_basis = Basis(Vector3.UP, yaw)
		_place_fp(0.0, true)
		return
	if camera:
		camera.position = Vector3(0, 0, _len)
	if target:
		global_position = target.global_position + Vector3.UP * height
		rotation = Vector3(pitch, yaw, 0.0)
		target.camera_yaw_basis = Basis(Vector3.UP, yaw)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if Input.is_action_just_pressed(InputRouter.PREFIX + "toggle_view") and not get_tree().paused:
		GameManager.toggle_first_person()
	var look := InputRouter.get_look_delta(delta)
	# Touch drags are eased in over a few frames instead of snapping.
	_touch_pending += InputRouter.get_touch_look_delta() + InputRouter.get_touch_stick_look(delta)
	var step := _touch_pending * (1.0 - exp(-touch_look_smoothing * delta))
	_touch_pending -= step
	look += step
	yaw -= look.x * look_scale
	if first_person:
		pitch = clampf(pitch - look.y * look_scale, FP_MIN_PITCH, FP_MAX_PITCH)
		target.camera_yaw_basis = Basis(Vector3.UP, yaw)
		_place_fp(delta, false)
		_shake_tick(delta)
		return
	pitch = clampf(pitch - look.y * look_scale, min_pitch, max_pitch)
	rotation = Vector3(pitch, yaw, 0.0)
	target.camera_yaw_basis = Basis(Vector3.UP, yaw)
	var goal := target.get_global_transform_interpolated().origin + Vector3.UP * height
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
	_update_distance(delta)
	_shake_tick(delta)


func _shake_tick(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		var s := _shake * clampf(_shake_time * 4.0, 0.0, 1.0)
		camera.h_offset = randf_range(-s, s) * 0.5
		camera.v_offset = randf_range(-s, s) * 0.5
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


## First person: at the eyes, looking where you look (on the surface the
## bug stands on), with a little bob in step with its legs.
func _place_fp(delta: float, instant: bool) -> void:
	var v := target.visual
	var body := target.get_global_transform_interpolated()
	# The eye point rides on the body, but not on a play-dead roll.
	var vt := v.transform
	if absf(v.rotation.z) > 0.6:
		vt = Transform3D(Basis(Vector3.UP, v.rotation.y).scaled(v.scale), v.position)
	var eye := body * (vt * _fp_eye.transform).origin
	var up := target.fp_up()
	var fwd := target.fp_forward()
	var look_basis := Basis.looking_at(fwd, up)
	var want := look_basis * Basis(Vector3.RIGHT, pitch)
	_fp_basis = want if instant else Basis(Quaternion(_fp_basis.orthonormalized()).slerp(Quaternion(want.orthonormalized()), clampf(16.0 * delta, 0.0, 1.0)))
	# Bob with the gait: down as the legs push off, a slight side-to-side sway.
	var rig := target.get_node_or_null("Rig") as BugRig
	var bob := Vector3.ZERO
	if rig:
		var moving := clampf(target.motion_speed() / 3.0, 0.0, 1.0)
		var size := target.size_mult()
		bob = up * (-absf(sin(rig.phase)) * FP_BOB * moving * size) + look_basis.x * (sin(rig.phase) * FP_BOB * 0.5 * moving * size)
	global_transform = Transform3D(_fp_basis, eye + bob)
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO


## Fly: compound-eye facets at the edge of view; everyone else a soft dark
## vignette (you're looking out from inside a tiny head).
func _update_overlay() -> void:
	if _overlay == null:
		_overlay = CanvasLayer.new()
		_overlay.name = "EyeOverlay"
		_overlay.layer = 1
		var rect := TextureRect.new()
		rect.name = "Tex"
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_overlay.add_child(rect)
		add_child(_overlay)
	var compound := target != null and target is Fly
	var tex := _overlay.get_node("Tex") as TextureRect
	tex.texture = load("res://assets/ui/compound_eye.png" if compound else "res://assets/ui/vignette.png")
	tex.modulate = Color(1, 1, 1, 0.85 if compound else 0.7)
	_overlay.visible = first_person


## Pull in fast when something blocks the view, drift back out gently.
func _update_distance(delta: float) -> void:
	arm.spring_length = distance
	var allowed := arm.get_hit_length()
	if allowed <= 0.0:
		allowed = distance
	var rate := PULL_IN_RATE if allowed < _len else EASE_OUT_RATE
	_len = lerpf(_len, allowed, 1.0 - exp(-rate * delta))
	camera.position = Vector3(0, 0, _len)


func get_forward() -> Vector3:
	return -camera.global_basis.z


func screen_center() -> Vector2:
	return get_viewport().get_visible_rect().size * 0.5


func _on_shake(strength: float, duration: float) -> void:
	_shake = maxf(_shake if _shake_time > 0.0 else 0.0, strength)
	_shake_time = maxf(_shake_time, duration)


func _on_resize() -> void:
	if camera == null:
		return
	var s := get_viewport().get_visible_rect().size
	var fp_fov := target.stats.fp_fov if target and target.stats else 86.0
	if s.y > s.x:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = fp_fov + 10.0 if first_person else 72.0
	else:
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.fov = fp_fov if first_person else 62.0
