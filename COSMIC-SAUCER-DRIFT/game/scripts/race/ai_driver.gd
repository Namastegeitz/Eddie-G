class_name AIDriver
extends RefCounted
## Computer pilot. Follows the racing line with a personal offset, plans
## speed from upcoming curvature, drifts long corners, grabs pods when low,
## crates when empty-handed, dodges hazards and mines, takes shortcuts,
## tricks off jumps and uses items according to its style:
##   clean      - best line, uses items when they're sure to land
##   aggressive - bumps and fires early, chases rivals
##   hoarder    - keeps defensive items, collects every pod

var style := "clean"
var skill := 0.7
var lane_bias := 0.0
var cruise := false            # after a human finishes: drive calmly

var _short_lap := -1
var _want_short := false
var _on_short_last := false
var _short_i := 0
var _drift_hold := false
var _target_tier := 2
var _press_at := 0.3
var _trick_pressed := false
var _item_wait := 0.0
var _wobble := 0.0
var _rng := RandomNumberGenerator.new()
var _tick := 0
var _lane_cache := 0.0
var _need_cache := 0.0


func _init(p_style: String, p_skill: float, seed_v: int) -> void:
	style = p_style
	skill = clampf(p_skill, 0.0, 1.0)
	_rng.seed = seed_v
	lane_bias = _rng.randf_range(-2.5, 2.5)
	_target_tier = 3 if skill > 0.8 and _rng.randf() < 0.6 else 2
	_press_at = lerpf(_rng.randf_range(0.0, 1.6), _rng.randf_range(0.05, 0.45), skill)


func drive(r: Racer, dt: float) -> void:
	var race := r.race
	var td: TrackData = race.td
	var path := td.main
	var T: Tuning = r.T
	if r.frozen:
		r.in_throttle = 1.0 if race.countdown_left <= _press_at else 0.0
		r.in_steer = 0.0
		r.in_drift = false
		return
	var speed := maxf(r.fwd_speed, 0.0)
	var hw := td.width * 0.5
	if r.rescue_time > 0.0:
		# Fell off: don't try the shortcut again this lap.
		_want_short = false
	var s_here := float(r.track_idx) * path.step
	# ------------------------------------------------ shortcut decision (once per lap)
	if td.short and r.lap != _short_lap:
		_short_lap = r.lap
		var chance := 0.15 + skill * 0.55
		if style == "aggressive":
			chance += 0.1
		_want_short = _rng.randf() < chance and not cruise
	var to_entry := path.delta(s_here, td.short_a) if td.short else 9999.0
	var use_short := false
	if td.short and (r.on_shortcut or (_want_short and not td.short_lift_start and not td.short_glide and to_entry < 22.0 and to_entry > -45.0 and not r.emergency)):
		use_short = true
	# ------------------------------------------------ target point
	var look := 10.0 + speed * 0.42
	var target := Vector3.ZERO
	var lat_target := 0.0
	var ahead_i := path.index_at(s_here + look)
	if use_short:
		var sp := td.short
		# Landing on a ribbon part-way along (a glide onto a landing strip):
		# find the place on it from scratch, not from its start.
		_short_i = sp.nearest(r.global_position, _short_i, 20 if _on_short_last else -1)
		var j := sp.index_at(float(_short_i) * sp.step + look)
		if j >= sp.n - 1:
			use_short = false
		else:
			target = sp.pts[j]
	if not use_short:
		_short_i = 0
		var line_w := lerpf(0.35, 1.0, skill)
		lat_target = td.line[ahead_i] * line_w + lane_bias * (1.0 - skill * 0.5)
		lat_target += sin(Time.get_ticks_msec() * 0.0011 + float(r.idx) * 1.7) * (1.0 - skill) * 2.5
		# Lined up for the shortcut / geyser.
		if td.short and _want_short and not td.short_glide and to_entry > 0.0 and to_entry < 70.0:
			lat_target = float(td.short_side) * (hw - 4.0) if not td.short_lift_start else float(td.short_side) * (hw - 5.0)
		else:
			# Lane decisions (pods, crates, rivals, mines, hazards) are re-planned
			# about seven times a second, staggered across the field.
			if (_tick + r.idx) % 8 == 0:
				var lt := _pickup_goal(r, s_here, lat_target)
				_lane_cache = _avoid(r, s_here, lt, hw) - lat_target
			lat_target += _lane_cache
		lat_target = clampf(lat_target, -(hw - 3.5), hw - 3.5)
		target = path.pts[ahead_i] + path.rgt[ahead_i] * lat_target
	# ------------------------------------------------ steering
	var right := r.heading.cross(r.up).normalized()
	var v := target - r.global_position
	var ang := atan2(v.dot(right), v.dot(r.heading))
	var steer := clampf(ang * 2.4, -1.0, 1.0)
	if r.ink_time > 0.0:
		_wobble += dt * 5.0
		steer += sin(_wobble) * 0.4
	# ------------------------------------------------ speed planning
	_tick += 1
	var need := _need_cache
	if _tick % 3 == 0:
		need = 0.0
		var horizon := int((look + speed * speed / (2.0 * T.brake_decel)) / path.step)
		for k in range(2, maxi(horizon, 6), 3):
			need = maxf(need, absf(path.curv[path.wi(r.track_idx + k)]))
		_need_cache = need
	var avail := r.steer_rate * (1.0 - T.high_speed_steer_loss * minf(speed / r.max_speed, 1.0))
	var drift_avail := r.steer_rate * 1.05
	var can_drift := skill > 0.35
	var v_safe := (drift_avail if can_drift else avail) / maxf(need, 0.0001) * 0.95
	var throttle := 1.0
	var brake := 0.0
	# A gap jump ahead: line up in the middle and keep the gas down.
	var gap_ahead := false
	for k in range(0, 40, 2):
		if td.gap[path.wi(r.track_idx + k)] == 1:
			gap_ahead = true
			break
	if gap_ahead and not use_short:
		v_safe = INF
		var gi := path.wi(r.track_idx + 8)
		target = path.pts[gi]
		ang = atan2((target - r.global_position).dot(right), (target - r.global_position).dot(r.heading))
		steer = clampf(ang * 2.4, -1.0, 1.0)
	if speed > v_safe * 1.05 and r.grounded:
		throttle = 0.0
		if speed > v_safe * 1.25:
			brake = 0.6
	# ------------------------------------------------ drifting
	var here_k := path.curv[path.wi(r.track_idx + 6)]
	if r.drift_dir == 0:
		_drift_hold = false
		if can_drift and r.grounded and speed > T.drift_min_speed + 4.0 and absf(here_k) * speed > avail * 0.7 and not use_short and not gap_ahead:
			if _rng.randf() < 0.05 + skill * 0.25:
				_drift_hold = true
				steer = signf(here_k) * maxf(absf(steer), 0.6)
	else:
		var corner_on := absf(here_k) > 0.006 and signf(here_k) == float(r.drift_dir)
		_drift_hold = corner_on or r.drift_tier < 1
		if r.drift_tier >= _target_tier and absf(here_k) < 0.012:
			_drift_hold = false
		steer = clampf(ang * 3.0, -1.0, 1.0)
	# ------------------------------------------------ tricks in the air
	var drift_btn := _drift_hold
	if not r.grounded:
		drift_btn = false
		if r.air_time > T.trick_min_air + 0.03 and not _trick_pressed and r.velocity.y > -2.0 and _rng.randf() < 0.1 + skill * 0.5:
			drift_btn = true
			_trick_pressed = true
	else:
		_trick_pressed = false
	if cruise:
		throttle = minf(throttle, 0.75)
	r.in_steer = steer
	r.in_throttle = throttle
	r.in_brake = brake
	r.in_drift = drift_btn
	# ------------------------------------------------ items
	_on_short_last = r.on_shortcut
	r.in_item = false
	if r.item != "" and r.item_roll <= 0.0 and not cruise:
		_item_wait -= dt
		if _item_wait <= 0.0:
			if r.race.items.ai_should_use(r, style, skill):
				r.in_item = true
				_item_wait = _rng.randf_range(0.3, 1.0)
			else:
				# Ask again shortly, not every tick (chance rolls used to be
				# re-rolled 60 times a second, so skill made no difference).
				_item_wait = 0.2
	# ------------------------------------------------ Technical Wonder
	r.in_wonder = false
	if r.wonder and not cruise and r.wonder.ready():
		r.in_wonder = r.wonder.ai_wants(_need_cache < 0.004, _rival_near(r, 12.0))


func _rival_near(r: Racer, dist: float) -> bool:
	for o: Racer in r.race.racers:
		if o != r and not o.is_ghost and not o.finished and o.global_position.distance_squared_to(r.global_position) < dist * dist:
			return true
	return false


## Steer toward pods when low on energy, crates when empty-handed.
func _pickup_goal(r: Racer, s_here: float, lat: float) -> float:
	var pk = r.race.pickups
	if pk == null:
		return lat
	var want_pod := r.energy < (70.0 if style == "hoarder" else 48.0)
	if want_pod:
		var p: Dictionary = pk.next_target("pod", s_here + 15.0, s_here + 80.0, lat)
		if not p.is_empty():
			return p.lane
	if r.item == "" and r.item_roll <= 0.0:
		var c: Dictionary = pk.next_target("crate", s_here + 15.0, s_here + 70.0, lat)
		if not c.is_empty():
			return c.lane
	return lat


## Sidestep racers, mines and hazards ahead (aggressive pilots aim at rivals);
## then always stay off a skyway ramp's lane.
func _avoid(r: Racer, s_here: float, lat: float, hw: float) -> float:
	var out := _avoid_inner(r, s_here, lat, hw)
	var td: TrackData = r.race.td
	if td.short_glide:
		# The ramp launches whoever hits it, and the barrier past it is open.
		var to_ramp := td.main.delta(s_here, td.short_a)
		var to_bridge := td.main.delta(s_here, td.short_b)
		if (to_ramp > -12.0 and to_ramp < 70.0) or (to_bridge > -20.0 and to_bridge < 70.0):
			var ramp_lane := float(td.short_side) * (hw - 5.0)
			if absf(out - ramp_lane) < 8.5:
				out = ramp_lane - signf(ramp_lane) * 9.0
	return out


func _avoid_inner(r: Racer, s_here: float, lat: float, hw: float) -> float:
	var race := r.race
	var out := lat
	var td: TrackData = race.td
	for o: Racer in race.racers:
		if o == r or o.finished:
			continue
		var ds: float = td.main.delta(s_here, float(o.track_idx) * td.main.step)
		if ds > 2.0 and ds < 14.0:
			var dl: float = o.lateral - r.lateral
			if style == "aggressive" and absf(dl) < 5.0 and _rng.randf() < 0.5 * skill:
				# Ram them, but still dodge mines and hazards below (this used
				# to return here and drive straight through traps).
				out = o.lateral
				break
			if absf(dl) < 2.6:
				out = o.lateral + (3.6 if o.lateral < 0.0 else -3.6)
	if race.items:
		out = race.items.avoid_lane(s_here + 6.0, s_here + 45.0, out, hw)
	if race.hazards:
		out = race.hazards.avoid_lane(r, s_here + 4.0, s_here + 40.0, out, hw)
	return out
