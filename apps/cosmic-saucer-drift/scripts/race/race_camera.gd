class_name RaceCamera
extends Camera3D
## Chase camera: trails the saucer and stretches back with speed, swings
## out during drifts and looks into the turn, punches the field of view on
## boosts, dips on hard landings, shakes on hits, looks back on request, and
## sweeps in from the front during the countdown. Rivals that get right up
## against the lens are hidden so they never fill the screen.

var target: Racer
var shake := 0.0
var intro := 0.0
var _vel_dir := Vector3.FORWARD
var _up := Vector3.UP
var _swing := 0.0
var _look_side := 0.0
var _kick := 0.0
var _dip := 0.0
var _dip_v := 0.0
var _stretch := 0.0
var _was_boost := false
var _rng := RandomNumberGenerator.new()
var _hidden: Array[Racer] = []
var _orbit := -1.0

const NEAR_HIDE := 3.2


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
	var dist := (8.2 if far_cam else 6.0) + _stretch * 1.4
	var height := (3.1 if far_cam else 2.4) - _stretch * 0.35
	var back := -_vel_dir if not target.in_look_back else _vel_dir
	var side := _vel_dir.cross(_up).normalized()
	return target.global_position + back * dist + _up * (height + _dip) + side * _swing


func add_shake(amount: float) -> void:
	if Save.setting("shake"):
		shake = maxf(shake, amount)


## Hard landing: the camera dips and springs back.
func land(impact: float) -> void:
	if Save.setting("shake"):
		_dip_v -= clampf(impact * 0.12, 0.0, 2.2)


func _process(dt: float) -> void:
	if target == null:
		return
	# Smoothing below is frame-rate independent, so allow long frames: on a
	# slow phone a tight cap made the camera fall far behind the craft.
	dt = minf(dt, 0.25)
	var hv := target.heading
	var ratio := clampf(target.fwd_speed / maxf(target.max_speed, 1.0), 0.0, 1.4)
	# Faster cars feel faster: tighter follow, a bit more distance.
	_vel_dir = _vel_dir.lerp(hv, 1.0 - exp(-(6.0 + ratio * 2.0) * dt)).normalized()
	_up = _up.lerp(target.up, 1.0 - exp(-4.0 * dt)).normalized()
	_stretch = lerpf(_stretch, clampf(ratio - 0.5, 0.0, 0.8) + (0.35 if target.boost_time > 0.0 else 0.0), 1.0 - exp(-2.5 * dt))
	# Drift swing: slide out to the outside of the turn, look toward the inside.
	var drift := float(target.drift_dir)
	_swing = lerpf(_swing, -drift * 1.3 - target.in_steer * 0.35, 1.0 - exp(-3.0 * dt))
	_look_side = lerpf(_look_side, drift * 1.6 + target.in_steer * 0.9, 1.0 - exp(-4.0 * dt))
	# Landing dip spring.
	var rem := dt
	while rem > 0.0:
		var h := minf(rem, 1.0 / 60.0)
		_dip_v += (-_dip * 60.0 - _dip_v * 9.0) * h
		_dip += _dip_v * h
		rem -= h
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
	# After the finish: swing round to the front to see the pilot celebrate.
	if target.finished:
		if _orbit < 0.0:
			_orbit = 0.0
		_orbit = minf(_orbit + dt * 0.55, 2.4)
		var a := _orbit * 1.1
		var sd := target.heading.cross(target.up).normalized()
		var at := target.global_position + (target.heading * cos(a) * -1.0 + sd * sin(a)) * 6.2 + target.up * 2.0
		global_position = global_position.lerp(at, 1.0 - exp(-5.0 * dt))
		look_at(target.global_position + target.up * 0.7, target.up)
		fov = lerpf(fov, 62.0, 1.0 - exp(-3.0 * dt))
		h_offset = 0.0
		v_offset = 0.0
		return
	global_position = global_position.lerp(want, 1.0 - exp(-11.0 * dt))
	var look_dir := target.heading if not target.in_look_back else -target.heading
	var side_v := _vel_dir.cross(_up).normalized()
	var look_pt := target.global_position + look_dir * (7.0 + ratio * 2.0) + _up * 1.0 + side_v * _look_side
	if global_position.distance_to(look_pt) > 0.5:
		look_at(look_pt, _up)
	# Field of view: speed widens it, a boost punches it out then settles.
	var boosting := target.boost_time > 0.0
	if boosting and not _was_boost:
		_kick = 9.0
	_was_boost = boosting
	_kick = maxf(0.0, _kick - dt * 18.0)
	var want_fov := 70.0 + ratio * 9.0 + (8.0 if boosting else 0.0)
	fov = lerpf(fov, want_fov, 1.0 - exp(-4.0 * dt)) + _kick * dt * 6.0
	fov = clampf(fov, 60.0, 100.0)
	if shake > 0.0:
		shake = maxf(0.0, shake - dt * 1.8)
		var s := shake * shake * 0.6
		h_offset = _rng.randf_range(-s, s)
		v_offset = _rng.randf_range(-s, s)
	else:
		h_offset = 0.0
		v_offset = 0.0
	_hide_close()


## Hide rivals pressed against the lens (single-screen only; in split-screen
## the other camera may need to see them).
func _hide_close() -> void:
	var race := target.race
	if race == null or race.cams.size() != 1:
		return
	for r in _hidden:
		if is_instance_valid(r) and r.model:
			r.model.visible = true
	_hidden.clear()
	var cp := global_position
	for r: Racer in race.racers:
		if r == target or r.model == null:
			continue
		if r.global_position.distance_squared_to(cp) < NEAR_HIDE * NEAR_HIDE:
			r.model.visible = false
			_hidden.append(r)
