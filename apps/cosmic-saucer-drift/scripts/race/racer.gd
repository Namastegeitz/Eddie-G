class_name Racer
extends CharacterBody3D
## One saucer in a race: arcade hover physics, drifting + Plasma Boost,
## Dark Matter energy, tricks, slipstream, statuses (spin-out, shield,
## tractor, nebula ink), progress along the track and respawning.
##
## A controller (PlayerDriver or AIDriver) fills the in_* inputs every tick.

signal event(kind: String, data: Dictionary)

# Identity
var idx := 0
var display_name := ""
var pilot: Dictionary
var saucer: Dictionary
var look: Dictionary
var is_human := false
var slot := -1                 # local player slot (0/1), -1 for AI
var controller: Object = null
var race: Node = null          # Race
var is_ghost := false

# Inputs (set by the controller each tick)
var in_steer := 0.0
var in_throttle := 0.0
var in_brake := 0.0
var in_drift := false
var in_item := false
var in_look_back := false
var _prev_drift := false
var _prev_item := false

# Derived stats
var max_speed := 45.0
var accel := 20.0
var steer_rate := 2.0
var grip := 8.0
var drain_mult := 1.0
var weight := 5.0
var drift_mult := 1.0
var speed_mult := 1.0          # AI class / rubber band

# Motion state
var heading := Vector3.FORWARD
var up := Vector3.UP
var ground_n := Vector3.UP
var grounded := false
var air_time := 0.0
var fwd_speed := 0.0
var surface := Catalog.S_METAL
var on_shortcut := false
var _hop_cd := 0.0

# Energy
var energy := 100.0
var emergency := false

# Drift / boost
var drift_dir := 0
var drift_charge := 0.0
var drift_tier := 0
var boost_time := 0.0
var boost_kind := ""

# Tricks
var trick_time := 0.0
var trick_kind := 0
var tricks_in_air := 0

# Statuses
var spin_time := 0.0
var invuln_time := 0.0
var shield_time := 0.0
var tractor_time := 0.0
var ink_time := 0.0
var slow_time := 0.0
var stall_time := 0.0
var wobble_time := 0.0
var rescue_time := 0.0
var slip_charge := 0.0
var slip_cd := 0.0
var near_cd := 0.0
var frozen := true

# Items
var item := ""
var item_roll := 0.0           # > 0 while the roulette spins

# Progress
var track_idx := 0
var prev_s := 0.0
var race_dist := 0.0
var lateral := 0.0
var place := 1
var lap := 1
var finished := false
var finish_time := 0.0
var wrong_way := false
var _wrong_t := 0.0
var last_safe_idx := 0
var last_safe_lat := 0.0
var _start_press := -1.0
var _short_i := 0

var stats := {}

var model: SaucerModel
var T: Tuning


func setup(p_race: Node, p_idx: int, p_look: Dictionary, upgrades: Dictionary) -> void:
	race = p_race
	idx = p_idx
	look = p_look
	T = race.tuning
	pilot = Catalog.pilot(look.get("pilot", "zib"))
	saucer = Catalog.saucer(look.get("saucer", "classic"))
	display_name = pilot.name
	collision_layer = 4
	collision_mask = 2
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.3
	cs.shape = sph
	add_child(cs)
	model = SaucerModel.new()
	model.name = "Model"
	add_child(model)
	model.build(look)
	_apply_stats(upgrades)
	stats = {"pods": 0, "tricks": 0, "hits": 0, "hits_taken": 0, "items": 0, "purple": 0, "slips": 0,
		"shortcuts": 0, "hover_count": 0, "drift_dist": 0.0, "near": 0, "dist": 0.0, "top": 0.0,
		"shards": 0, "lead_laps": 0, "boosts": 0}
	if pilot.passive == "shield_start":
		item = "shield"


func _apply_stats(upgrades: Dictionary) -> void:
	var st := {}
	for k in Catalog.STAT_KEYS:
		st[k] = float(saucer[k]) + float(upgrades.get(k, 0)) * Catalog.UPGRADE_STEP
	max_speed = T.top_speed_base + T.top_speed_per_stat * st.speed
	accel = T.accel_base + T.accel_per_stat * st.accel
	steer_rate = T.steer_rate_base + T.steer_rate_per_stat * st.handling
	grip = T.grip_base + T.grip_per_stat * st.handling
	drain_mult = 1.25 - 0.05 * st.efficiency
	weight = float(saucer.weight)
	drift_mult = 1.0 + saucer.get("drift_bonus", 0.0)
	match pilot.passive:
		"drift":
			drift_mult *= 1.25
		"efficient":
			drain_mult *= 0.75
		"bumper":
			weight += 4.0


func place_at(tf: Transform3D) -> void:
	global_transform = Transform3D(Basis.IDENTITY, tf.origin)
	heading = -tf.basis.z
	up = tf.basis.y
	ground_n = up
	velocity = Vector3.ZERO
	var td: TrackData = race.td
	track_idx = td.main.nearest(tf.origin, 0, -1)
	prev_s = td.main.along(track_idx, tf.origin)
	race_dist = td.main.delta(0.0, prev_s)
	if race_dist > 0.0:
		race_dist -= td.main.length
	last_safe_idx = track_idx
	_orient(1.0)


# ---------------------------------------------------------------- per tick
func tick(dt: float) -> void:
	if controller and not is_ghost:
		controller.call("drive", self, dt)
	if frozen:
		_countdown_input()
		_visuals(dt)
		return
	_timers(dt)
	if rescue_time > 0.0:
		rescue_time -= dt
		velocity = Vector3.ZERO
		_visuals(dt)
		return
	_probe_ground(dt)
	_steer_and_drift(dt)
	_tricks(dt)
	_integrate(dt)
	_energy(dt)
	_progress(dt)
	_items_input()
	_visuals(dt)


func _timers(dt: float) -> void:
	boost_time = maxf(0.0, boost_time - dt)
	spin_time = maxf(0.0, spin_time - dt)
	invuln_time = maxf(0.0, invuln_time - dt)
	shield_time = maxf(0.0, shield_time - dt)
	tractor_time = maxf(0.0, tractor_time - dt)
	ink_time = maxf(0.0, ink_time - dt)
	slow_time = maxf(0.0, slow_time - dt)
	stall_time = maxf(0.0, stall_time - dt)
	wobble_time = maxf(0.0, wobble_time - dt)
	slip_cd = maxf(0.0, slip_cd - dt)
	near_cd = maxf(0.0, near_cd - dt)
	if item_roll > 0.0:
		item_roll -= dt
		if item_roll <= 0.0:
			emit_signal("event", "item_ready", {"item": item})


func _probe_ground(dt: float) -> void:
	var was := grounded
	var space := get_world_3d().direct_space_state
	var ray_up := up if grounded else up.lerp(Vector3.UP, 0.5).normalized()
	var from := global_position + ray_up * 1.2
	var to := global_position - ray_up * (T.hover_height + T.snap_range + 0.4)
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := space.intersect_ray(q)
	grounded = false
	if not hit.is_empty():
		var n: Vector3 = hit.normal
		if n.dot(ray_up) < 0.0:
			n = -n
		var hp: Vector3 = hit.position
		var dist := (global_position - hp).dot(n)
		var vn := velocity.dot(n)
		if dist < T.hover_height + T.snap_range and (vn < 2.5 or dist < T.hover_height * 0.7):
			grounded = true
			ground_n = n
			var err: float = T.hover_height - dist
			if err > 0.0:
				global_position += n * err
			else:
				global_position += n * err * minf(1.0, dt * 14.0)
			var col: Object = hit.collider
			var sid: int = col.get_meta("surface", -1) if col else -1
			on_shortcut = col != null and col.name == "ShortcutGround"
			var tdd: TrackData = race.td
			surface = tdd.surface_at(track_idx) if sid < 0 else sid
	if grounded and not was:
		_land()
	if grounded:
		air_time = 0.0
	else:
		air_time += dt


func _land() -> void:
	var impact := -velocity.dot(ground_n)
	# Remove the into-ground part of the velocity.
	velocity -= ground_n * minf(0.0, velocity.dot(ground_n))
	if trick_time > 0.0:
		# Landed mid-trick: wobble and lose speed.
		trick_time = 0.0
		tricks_in_air = 0
		wobble_time = 0.6
		velocity *= 0.7
		emit_signal("event", "sloppy", {})
	elif tricks_in_air > 0:
		var mult := 2.0 if pilot.passive == "tricks" else 1.0
		give_boost(T.trick_boost_time * mult, "trick")
		add_energy(T.trick_energy * mult * float(tricks_in_air))
		stats.tricks += tricks_in_air
		emit_signal("event", "trick", {"count": tricks_in_air})
		tricks_in_air = 0
	if surface == Catalog.S_MOSS and impact > 4.0:
		velocity += ground_n * impact * 0.55
		grounded = false
	emit_signal("event", "land", {"impact": impact})


func _steer_and_drift(dt: float) -> void:
	var steer := in_steer
	if ink_time > 0.0 and not is_human:
		steer += sin(Time.get_ticks_msec() * 0.006 + idx) * 0.35
	var fwd := velocity.dot(heading)
	fwd_speed = fwd
	var ratio := clampf(absf(fwd) / max_speed, 0.0, 1.2)
	var authority := clampf(absf(fwd) / 6.0, 0.0, 1.0) * (1.0 - T.high_speed_steer_loss * minf(ratio, 1.0))
	# Drift start / end.
	if drift_dir == 0:
		if in_drift and grounded and absf(steer) > 0.25 and fwd > T.drift_min_speed and spin_time <= 0.0:
			drift_dir = 1 if steer > 0.0 else -1
			drift_charge = 0.0
			drift_tier = 0
			emit_signal("event", "drift_start", {})
	else:
		var ends: bool = (not in_drift) or fwd < T.drift_min_speed * 0.7 or air_time > 0.5 or spin_time > 0.0
		if ends:
			_end_drift(spin_time <= 0.0 and air_time <= 0.5)
	var turn := steer * steer_rate * authority
	if drift_dir != 0:
		var tight := clampf(steer * float(drift_dir), -1.0, 1.0)
		turn = float(drift_dir) * steer_rate * (0.72 + 0.5 * tight) * clampf(absf(fwd) / 15.0, 0.4, 1.0)
		var pass_rate := T.drift_charge_rate * drift_mult * (0.55 + 0.45 * maxf(tight, 0.0))
		drift_charge = minf(T.drift_tiers[2], drift_charge + pass_rate * dt)
		var tier := 0
		for k in 3:
			if drift_charge >= T.drift_tiers[k]:
				tier = k + 1
		if tier != drift_tier:
			drift_tier = tier
			emit_signal("event", "drift_tier", {"tier": tier})
		stats.drift_dist += absf(fwd) * dt
	if fwd < -0.5:
		turn = -turn
	if not grounded:
		turn *= T.air_steer
	if spin_time > 0.0 or stall_time > 0.0 and fwd < 2.0:
		turn = 0.0
	heading = heading.rotated(up, -turn * dt).normalized()


func _end_drift(award: bool) -> void:
	if award and drift_tier > 0:
		give_boost(T.drift_boost_time[drift_tier - 1], "drift%d" % drift_tier)
		if drift_tier == 3:
			stats.purple += 1
		emit_signal("event", "drift_boost", {"tier": drift_tier})
	drift_dir = 0
	drift_tier = 0
	drift_charge = 0.0


func _tricks(dt: float) -> void:
	var pressed := in_drift and not _prev_drift
	_prev_drift = in_drift
	if not grounded and pressed and air_time > T.trick_min_air and trick_time <= 0.0 and spin_time <= 0.0:
		trick_time = T.trick_time
		trick_kind = (trick_kind + 1 + randi() % 2) % 3
		emit_signal("event", "trick_start", {})
	if trick_time > 0.0:
		trick_time -= dt
		if trick_time <= 0.0:
			tricks_in_air += 1


func _integrate(dt: float) -> void:
	var surf := Catalog.surface(surface)
	var top: float = max_speed * speed_mult * float(surf.speed) * float(race.mod_speed)
	if emergency:
		top *= T.emergency_speed
	if boost_time > 0.0:
		top *= T.boost_speed_mult
	if tractor_time > 0.0:
		top *= 0.6
	if slow_time > 0.0:
		top *= 0.6
	if spin_time > 0.0:
		top *= 0.35
	var acc := accel * (T.emergency_accel if emergency else 1.0)
	if stall_time > 0.0:
		acc *= 0.1
	var td: TrackData = race.td
	var g: float = T.gravity * float(race.mod_gravity) * (0.38 if td.is_lowg(track_idx) else 1.0)
	if grounded:
		up = up.lerp(ground_n, 1.0 - exp(-14.0 * dt)).normalized()
		heading = (heading - up * heading.dot(up)).normalized()
		var right := heading.cross(up).normalized()
		var fwd := velocity.dot(heading)
		var lat := velocity.dot(right)
		var vn := velocity.dot(up)
		var throttle := 0.0 if spin_time > 0.0 else in_throttle
		if boost_time > 0.0:
			fwd = move_toward(fwd, top, T.boost_accel * dt)
		elif in_brake > 0.1 and spin_time <= 0.0:
			if fwd > 0.5:
				fwd = move_toward(fwd, 0.0, T.brake_decel * in_brake * dt)
			else:
				fwd = move_toward(fwd, -T.reverse_speed, acc * 0.6 * dt)
		elif throttle > 0.05:
			var target: float = top * throttle
			if fwd < target:
				fwd = move_toward(fwd, target, acc * dt * (1.0 - 0.5 * clampf(fwd / maxf(top, 1.0), 0.0, 1.0)))
			else:
				fwd = move_toward(fwd, target, T.coast_decel * 2.0 * dt)
		else:
			fwd = move_toward(fwd, 0.0, T.coast_decel * dt)
		var g_eff: float = grip * float(surf.grip) * float(race.mod_grip) * (T.drift_grip if drift_dir != 0 else 1.0)
		if wobble_time > 0.0:
			g_eff *= 0.5
		lat *= exp(-g_eff * dt)
		if surface == Catalog.S_RAIL and not on_shortcut and drift_dir == 0:
			# Magnetic rails pull you onto the nearest of three lanes.
			var lw: float = td.width / 3.0
			var target_lat: float = clampf(roundf(lateral / lw), -1.0, 1.0) * lw
			if absf(in_steer) < 0.3:
				lat = lerpf(lat, (target_lat - lateral) * 2.5, 1.0 - exp(-6.0 * dt))
		# Small hops on bouncy moss.
		if surface == Catalog.S_MOSS and fwd > 20.0:
			_hop_cd -= dt
			if _hop_cd <= 0.0:
				vn = 4.6
				_hop_cd = 0.95
		# Only a real upward kick (moss hop, bounce) leaves the ground; the
		# rest of the normal speed is soaked up by the hover.
		if vn > 1.5:
			grounded = false
		else:
			vn = 0.0
		velocity = heading * fwd + right * lat + up * vn
		if surface != Catalog.S_MOSS:
			_hop_cd = 0.4
	else:
		up = up.lerp(Vector3.UP, 1.0 - exp(-2.5 * dt)).normalized()
		heading = (heading - up * heading.dot(up)).normalized()
		velocity += Vector3.DOWN * g * dt
		if boost_time > 0.0:
			var hv := Vector3(velocity.x, 0, velocity.z)
			if hv.length() < top:
				velocity += Vector3(heading.x, 0, heading.z).normalized() * T.boost_accel * 0.4 * dt
		# Gently swing the travel direction toward the heading in the air.
		var hv2 := Vector3(velocity.x, 0, velocity.z)
		var hd := Vector3(heading.x, 0, heading.z).normalized()
		if hv2.length() > 1.0:
			var nh := hv2.normalized().lerp(hd, 1.0 - exp(-1.5 * dt)).normalized() * hv2.length()
			velocity = Vector3(nh.x, velocity.y, nh.z)
	var before := velocity
	move_and_slide()
	for k in get_slide_collision_count():
		var c := get_slide_collision(k)
		var n := c.get_normal()
		var into := -before.dot(n)
		if into > 6.0:
			velocity *= 0.8
			# Turn the nose along the wall so you don't grind to a stop.
			var along := (heading - n * heading.dot(n)).normalized()
			if along.length() > 0.1:
				heading = heading.lerp(along, 0.5).normalized()
			emit_signal("event", "wall", {"impact": into})
	stats.dist += velocity.length() * dt
	stats.top = maxf(stats.top, velocity.length())
	_orient(dt)


func _orient(dt: float) -> void:
	var right := heading.cross(up).normalized()
	if right.length() < 0.5:
		return
	var fwd := up.cross(right).normalized()
	var b := Basis(right, up, -fwd)
	global_transform.basis = global_transform.basis.slerp(b, 1.0 - exp(-20.0 * dt)) if dt < 1.0 else b


func _energy(dt: float) -> void:
	if finished or not race.racing:
		return
	var drain: float = T.energy_drain * drain_mult * float(race.mod_drain) * (T.energy_idle_share + (1.0 - T.energy_idle_share) * in_throttle)
	energy -= drain * dt
	if energy <= 0.0:
		energy = 0.0
		if not emergency:
			emergency = true
			stats.hover_count += 1
			emit_signal("event", "emergency", {})


func add_energy(amount: float) -> void:
	energy = minf(T.energy_max, energy + amount)
	if emergency and energy > 6.0:
		emergency = false
		emit_signal("event", "recharged", {})


func give_boost(time: float, kind: String) -> void:
	boost_time = maxf(boost_time, time)
	boost_kind = kind
	stats.boosts += 1
	emit_signal("event", "boost", {"kind": kind})


func _progress(dt: float) -> void:
	var td: TrackData = race.td
	var path := td.main
	# Fell off the track or stuck in the air too long: rescue beam.
	if not grounded and (global_position.y < path.pts[track_idx].y - 24.0 or air_time > 6.0):
		respawn("fell" if air_time <= 6.0 else "air", global_position)
		return
	if on_shortcut and not grounded and air_time > 0.6:
		on_shortcut = false
	if on_shortcut and td.short:
		# Map progress along the shortcut onto the main loop so positions
		# keep updating while you're on it.
		_short_i = td.short.nearest(global_position, _short_i, 16)
		var f := float(_short_i) / float(maxi(td.short.n - 1, 1))
		var sm := td.short_a + f * path.delta(td.short_a, td.short_b)
		var im := path.index_at(sm)
		track_idx = im
		race_dist += path.delta(prev_s, sm)
		prev_s = sm
		lateral = 0.0
		_wrong_t = 0.0
		wrong_way = false
		return
	_short_i = 0
	var i := path.nearest(global_position, track_idx, 24)
	if path.pts[i].distance_to(global_position) > td.width * 1.5 + 12.0:
		# Lost the local match (shortcut, big jump). Only re-sync to another
		# part of the loop once we're actually driving on the road there, so
		# flying over a different section never counts as progress.
		var g := path.nearest(global_position, track_idx, -1)
		if grounded and absf(path.lateral(g, global_position)) < td.width * 0.5 + 3.0 and absf(path.height(g, global_position)) < 3.0:
			i = g
	track_idx = i
	var s := path.along(i, global_position)
	race_dist += path.delta(prev_s, s)
	prev_s = s
	lateral = path.lateral(i, global_position)
	if grounded and not on_shortcut and absf(lateral) < td.width * 0.5 and absf(path.height(i, global_position)) < 3.0 and td.gap[i] == 0:
		last_safe_idx = i
		last_safe_lat = lateral
	if fwd_speed > 6.0 and heading.dot(path.tan[i]) < -0.4 and grounded:
		_wrong_t += dt
	else:
		_wrong_t = 0.0
	wrong_way = _wrong_t > 1.2


func respawn(reason := "", from := Vector3.ZERO) -> void:
	var td: TrackData = race.td
	var path := td.main
	var i := path.wi(last_safe_idx - 4)
	while td.gap[i] == 1:
		i = path.wi(i - 3)
	# Never drop a saucer just before a gap with no run-up: put it past it.
	for k in 45:
		if td.gap[path.wi(i + k)] == 1:
			var j := path.wi(i + k)
			while td.gap[j] == 1:
				j = path.wi(j + 1)
			i = path.wi(j + 3)
			break
	var lat := clampf(last_safe_lat, -td.width * 0.25, td.width * 0.25)
	global_position = path.pts[i] + path.rgt[i] * lat + path.upv[i] * T.hover_height
	heading = path.tan[i]
	up = path.upv[i]
	ground_n = up
	velocity = heading * 8.0
	track_idx = i
	var s := path.along(i, global_position)
	race_dist += path.delta(prev_s, s)
	prev_s = s
	rescue_time = 0.9
	invuln_time = 2.4
	spin_time = 0.0
	trick_time = 0.0
	tricks_in_air = 0
	_end_drift(false)
	_orient(2.0)
	emit_signal("event", "respawn", {"reason": reason, "from": from})


# ---------------------------------------------------------------- start line
func _countdown_input() -> void:
	var t_to_go: float = race.countdown_left
	if in_throttle > 0.5:
		if _start_press < 0.0:
			_start_press = t_to_go
	else:
		_start_press = -1.0


func on_go() -> void:
	frozen = false
	if _start_press >= 0.0 and _start_press <= T.start_boost_window:
		give_boost(T.start_boost_time, "start")
		emit_signal("event", "start_boost", {})
	elif _start_press > 1.4:
		stall_time = T.stall_time
		emit_signal("event", "stall", {})


# ---------------------------------------------------------------- items & hits
func _items_input() -> void:
	var pressed := in_item and not _prev_item
	_prev_item = in_item
	if pressed and item != "" and item_roll <= 0.0 and spin_time <= 0.0:
		race.items.use_item(self)


func can_be_hit() -> bool:
	return shield_time <= 0.0 and invuln_time <= 0.0 and spin_time <= 0.0 and rescue_time <= 0.0 and not finished


## Returns true when the hit landed.
func hit(by: Racer, kind: String) -> bool:
	if not can_be_hit():
		if shield_time > 0.0:
			emit_signal("event", "blocked", {"kind": kind})
		return false
	spin_time = T.spin_time
	invuln_time = T.spin_time + T.invuln_after_hit
	velocity *= T.spin_speed_keep
	trick_time = 0.0
	tricks_in_air = 0
	_end_drift(false)
	stats.hits_taken += 1
	if by and by != self:
		by.stats.hits += 1
		by.emit_signal("event", "hit_landed", {"target": self, "kind": kind})
	emit_signal("event", "hit", {"kind": kind, "by": by})
	return true


func near_miss() -> void:
	if near_cd > 0.0 or not race.racing:
		return
	near_cd = 1.2
	add_energy(T.near_miss_energy)
	stats.near += 1
	emit_signal("event", "near_miss", {})


## Slipstream: `close` when tucked behind another saucer this tick.
func update_slip(dt: float, close: bool) -> void:
	if slip_cd > 0.0:
		return
	if close and fwd_speed > 25.0 and grounded:
		slip_charge += dt * (2.0 if pilot.passive == "draft" else 1.0)
		if slip_charge >= T.slip_charge_time:
			slip_charge = 0.0
			slip_cd = 2.5
			give_boost(T.slip_boost_time, "slip")
			add_energy(T.slip_energy)
			stats.slips += 1
			emit_signal("event", "slipstream", {})
	else:
		slip_charge = maxf(0.0, slip_charge - dt * 1.5)


# ---------------------------------------------------------------- visuals
func _visuals(dt: float) -> void:
	if model == null:
		return
	var pv := model.pivot
	var t := Time.get_ticks_msec() * 0.001
	var target_yaw := -0.42 * float(drift_dir)
	var yaw := lerp_angle(pv.rotation.y, target_yaw, 1.0 - exp(-8.0 * dt))
	var roll := lerpf(pv.rotation.z, -in_steer * 0.22 - float(drift_dir) * 0.12, 1.0 - exp(-8.0 * dt))
	var pitch := lerpf(pv.rotation.x, 0.0, 1.0 - exp(-8.0 * dt))
	if spin_time > 0.0:
		yaw = pv.rotation.y + 15.0 * dt
	if trick_time > 0.0:
		var k := 1.0 - trick_time / T.trick_time
		match trick_kind:
			0:
				roll = TAU * k
			1:
				yaw = TAU * k
			_:
				pitch = -TAU * k
	if wobble_time > 0.0 or emergency:
		roll += sin(t * 18.0) * (0.12 if wobble_time > 0.0 else 0.05)
	pv.rotation = Vector3(pitch, yaw, roll)
	pv.position.y = sin(t * 3.0 + float(idx)) * 0.07
	model.shield.visible = shield_time > 0.0
	model.visible = rescue_time <= 0.0 and not (invuln_time > 0.0 and spin_time <= 0.0 and int(t * 12.0) % 2 == 0 and invuln_time < 2.0)
	model.animate(dt, in_throttle, boost_time > 0.0, drift_tier, drift_dir != 0, clampf(fwd_speed / max_speed, 0.0, 1.5))
