class_name RaceCamera
extends Camera3D
## Chase camera: trails the saucer, widens on boost, shakes on hits,
## looks back on request, and sweeps in from the front during the countdown.

var target: Racer
var shake := 0.0
var intro := 0.0
var _vel_dir := Vector3.FORWARD
var _up := Vector3.UP
var _offset := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	far = 7000.0
	near = 0.3
	fov = 72.0


func snap() -> void:
	if target == null:
		return
	_vel_dir = target.heading
	_up = target.up
	global_position = _desired()
	look_at(target.global_position + target.heading * 6.0, _up)


func _desired() -> Vector3:
	var far_cam: bool = Save.setting("camera") == "far"
	var dist := 8.2 if far_cam else 6.0
	var height := 3.1 if far_cam else 2.4
	var back := -_vel_dir if not target.in_look_back else _vel_dir
	return target.global_position + back * dist + _up * height


func add_shake(amount: float) -> void:
	if Save.setting("shake"):
		shake = maxf(shake, amount)


func _process(dt: float) -> void:
	if target == null:
		return
	dt = minf(dt, 0.05)
	var hv := target.heading
	_vel_dir = _vel_dir.lerp(hv, 1.0 - exp(-6.0 * dt)).normalized()
	_up = _up.lerp(target.up, 1.0 - exp(-4.0 * dt)).normalized()
	var want := _desired()
	if intro > 0.0:
		intro = maxf(0.0, intro - dt)
		var k := intro / 2.4
		var a := k * PI * 0.9
		var side := target.heading.cross(Vector3.UP).normalized()
		var orbit := target.global_position + (-target.heading * cos(a) + side * sin(a)) * lerpf(8.0, 14.0, k) + Vector3.UP * lerpf(3.0, 6.0, k)
		global_position = orbit
		look_at(target.global_position + Vector3.UP * 0.8, Vector3.UP)
		return
	global_position = global_position.lerp(want, 1.0 - exp(-11.0 * dt))
	var look_dir := target.heading if not target.in_look_back else -target.heading
	var look_pt := target.global_position + look_dir * 7.0 + _up * 1.0
	if global_position.distance_to(look_pt) > 0.5:
		look_at(look_pt, _up)
	var ratio := clampf(target.fwd_speed / maxf(target.max_speed, 1.0), 0.0, 1.4)
	var want_fov := 70.0 + ratio * 8.0 + (10.0 if target.boost_time > 0.0 else 0.0)
	fov = lerpf(fov, want_fov, 1.0 - exp(-4.0 * dt))
	if shake > 0.0:
		shake = maxf(0.0, shake - dt * 1.8)
		var s := shake * shake * 0.6
		h_offset = _rng.randf_range(-s, s)
		v_offset = _rng.randf_range(-s, s)
	else:
		h_offset = 0.0
		v_offset = 0.0
