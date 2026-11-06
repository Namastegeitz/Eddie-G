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
var _tp := Vector3.ZERO       # target position this frame (interpolated)
var cockpit := false          # first-person view from the pilot's seat
var pilot_mask := 0           # render layer of the target's own pilot (hidden in cockpit)
var _ck_fwd := Vector3.FORWARD
var _ck_up := Vector3.UP
var _ck_roll := 0.0

const ALL_LAYERS := 0xFFFFF

const NEAR_HIDE := 3.2

var _portrait := false


## A tall screen (phone held upright in the browser) would see only a slit
## of the road with a height-based field of view; keep it across the width
## instead and sit the camera a little higher.
func _fit_orientation() -> void:
	var vs := get_viewport().get_visible_rect().size
	_portrait = vs.y > vs.x
	keep_aspect = Camera3D.KEEP_WIDTH if _portrait else Camera3D.KEEP_HEIGHT


func _ready() -> void:
	# The camera moves every rendered frame, following the racer's smoothed
	# (interpolated) position, so it isn't interpolated itself.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	far = 7000.0
	near = 0.3
	fov = 72.0


## Switch between the chase camera and the cockpit (first person).
func set_cockpit(on: bool) -> void:
	cockpit = on
	if target:
		_ck_fwd = target.heading
		_ck_up = target.up
	if on:
		_restore_hidden()


## World position of the target pilot's eyes this frame.
func eye_position() -> Vector3:
	var xf := target.get_global_transform_interpolated()
	var m := target.model
	if m == null or m.pivot == null:
		return xf.origin + xf.basis.y * 1.0
	# Follow the pivot's bob and lean, but not spins or trick flips.
	# Pivot angles aren't wrapped after spins and tricks (a full turn can be
	# left as 2π), so wrap before taking a fraction of them.
	var lean := Basis.from_euler(Vector3(0.0, wrapf(m.pivot.rotation.y, -PI, PI) * 0.5, wrapf(m.pivot.rotation.z, -PI, PI) * 0.4))
	if target.spin_time > 0.0 or target.trick_time > 0.0:
		lean = Basis.IDENTITY
	return xf.origin + xf.basis * (Vector3(0, m.pivot.position.y, 0) + lean * m.eye)


func snap() -> void:
	if target == null:
		return
	_vel_dir = target.heading
	_up = target.up
	_tp = target.global_position
	global_position = _desired()
	look_at(target.global_position + target.heading * 6.0, _up)


func _desired() -> Vector3:
	var far_cam: bool = Save.setting("camera") == "far"
	var dist := (8.2 if far_cam else 6.0) + _stretch * 1.4
	var height := (3.1 if far_cam else 2.4) - _stretch * 0.35 + (1.1 if _portrait else 0.0)
	var back := -_vel_dir if not target.in_look_back else _vel_dir
	var side := _vel_dir.cross(_up).normalized()
	return _tp + back * dist + _up * (height + _dip) + side * _swing


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
	_fit_orientation()
	_tp = target.get_global_transform_interpolated().origin
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
	# Own pilot hidden only while actually looking out of the cockpit (the
	# countdown sweep and the finish swing show them).
	var first_person := cockpit and intro <= 0.0 and not target.finished
	var mask := (ALL_LAYERS & ~pilot_mask) if first_person else ALL_LAYERS
	if cull_mask != mask:
		cull_mask = mask
		near = 0.05 if first_person else 0.3
	if intro > 0.0:
		intro = maxf(0.0, intro - dt)
		var k := intro / 2.4
		var a := k * PI * 0.9
		var side := target.heading.cross(Vector3.UP).normalized()
		var orbit := _tp + (-target.heading * cos(a) + side * sin(a)) * lerpf(8.0, 14.0, k) + Vector3.UP * lerpf(3.0, 6.0, k)
		global_position = orbit
		look_at(_tp + Vector3.UP * 0.8, Vector3.UP)
		return
	if cockpit and not target.finished:
		_cockpit_process(dt, ratio)
		return
	# After the finish: swing round to the front to see the pilot celebrate.
	if target.finished:
		if _orbit < 0.0:
			_orbit = 0.0
		_orbit = minf(_orbit + dt * 0.55, 2.4)
		var a := _orbit * 1.1
		var sd := target.heading.cross(target.up).normalized()
		var at := _tp + (target.heading * cos(a) * -1.0 + sd * sin(a)) * 6.2 + target.up * 2.0
		global_position = global_position.lerp(at, 1.0 - exp(-5.0 * dt))
		look_at(_tp + target.up * 0.7, target.up)
		fov = lerpf(fov, 62.0, 1.0 - exp(-3.0 * dt))
		h_offset = 0.0
		v_offset = 0.0
		return
	global_position = global_position.lerp(want, 1.0 - exp(-11.0 * dt))
	var look_dir := target.heading if not target.in_look_back else -target.heading
	var side_v := _vel_dir.cross(_up).normalized()
	var look_pt := _tp + look_dir * (7.0 + ratio * 2.0) + _up * 1.0 + side_v * _look_side
	if global_position.distance_to(look_pt) > 0.5:
		look_at(look_pt, _up)
	# Field of view: speed widens it, a boost punches it out then settles.
	var boosting := target.boost_time > 0.0
	if boosting and not _was_boost:
		_kick = 9.0
	_was_boost = boosting
	_kick = maxf(0.0, _kick - dt * 18.0)
	var want_fov := (58.0 if _portrait else 70.0) + ratio * 9.0 + (8.0 if boosting else 0.0)
	fov = lerpf(fov, want_fov, 1.0 - exp(-4.0 * dt)) + _kick * dt * 6.0
	fov = clampf(fov, 50.0, 100.0)
	if shake > 0.0:
		shake = maxf(0.0, shake - dt * 1.8)
		var s := shake * shake * 0.6
		h_offset = _rng.randf_range(-s, s)
		v_offset = _rng.randf_range(-s, s)
	else:
		h_offset = 0.0
		v_offset = 0.0
	_hide_close()


func _cockpit_process(dt: float, ratio: float) -> void:
	# Look where the craft is going, with part of the drift angle so a slide
	# feels like a slide, and bank into turns; level and steady through hits
	# and trick spins.
	var steady := target.spin_time > 0.0 or target.trick_time > 0.0
	var want_fwd := target.heading
	if not steady and target.model and target.model.pivot:
		want_fwd = want_fwd.rotated(target.up.normalized(), wrapf(target.model.pivot.rotation.y, -PI, PI) * 0.5)
	if target.in_look_back:
		want_fwd = -want_fwd
	_ck_fwd = _ck_fwd.lerp(want_fwd, 1.0 - exp(-16.0 * dt)).normalized()
	_ck_up = _ck_up.lerp(target.up, 1.0 - exp(-10.0 * dt)).normalized()
	var roll := 0.0 if steady else (-target.in_steer * 0.07 - float(target.drift_dir) * 0.05)
	_ck_roll = lerpf(_ck_roll, roll, 1.0 - exp(-6.0 * dt))
	var side := _ck_fwd.cross(_ck_up).normalized()
	var up := _ck_up.rotated(_ck_fwd, _ck_roll) if side.length() > 0.1 else _ck_up
	var eye := eye_position()
	if _ck_fwd.cross(up).length() > 0.05:
		global_transform = Transform3D(Basis.looking_at(_ck_fwd, up), eye)
	var boosting := target.boost_time > 0.0
	if boosting and not _was_boost:
		_kick = 9.0
	_was_boost = boosting
	_kick = maxf(0.0, _kick - dt * 18.0)
	var want_fov := (62.0 if _portrait else 76.0) + ratio * 12.0 + (8.0 if boosting else 0.0)
	fov = clampf(lerpf(fov, want_fov, 1.0 - exp(-4.0 * dt)) + _kick * dt * 6.0, 50.0, 105.0)
	if shake > 0.0:
		shake = maxf(0.0, shake - dt * 1.8)
		var s := shake * shake * 0.35
		h_offset = _rng.randf_range(-s, s)
		v_offset = _rng.randf_range(-s, s)
	else:
		h_offset = 0.0
		v_offset = 0.0


func _restore_hidden() -> void:
	for r in _hidden:
		if is_instance_valid(r) and r.model:
			r.model.visible = true
	_hidden.clear()


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
