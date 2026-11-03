class_name Fly
extends BugBase
## Buzzy free flight with momentum and drift, compound-eye bullet time, and a
## kit of escape tactics:
##   Burst          - Dodge: a quick sideways dart.
##   Evasive loop   - double-tap Dodge: loop up and back over the threat.
##   Dive           - Dodge while holding Down: a fast, silent plunge.
##   Cling          - fly into a wall holding Down, or up into a ceiling holding
##                    Up: perch there (camouflaged, silent, out of a human's
##                    downward gaze, regaining stamina).
##   Jinking        - sharp turns at speed make you hard to track.
##   Silent glide   - out of stamina you glide down quietly instead of dropping.

const LOOP_WINDOW := 0.35
const LOOP_TIME := 0.55
const LOOP_COST := 1.5
const DIVE_TIME := 0.6
const DIVE_SPEED := 24.0
const DIVE_COST := 0.8
const JINK_ANGLE := deg_to_rad(70.0)
const JINK_TIME := 0.7
const JINK_MIN_SPEED := 8.0
const JINK_VISIBILITY := 0.55
const GLIDE_SINK := 3.0
const GLIDE_SPEED_MULT := 0.55

var flying := false
var gliding := false
var clinging := false
var cling_normal := Vector3.UP
var stamina := 0.0
var bullet_time := false
var _wobble_t := 0.0
var _since_dodge := 99.0
var _loop_time := 0.0
var _loop_back := Vector3.ZERO
## Heading when the first Burst of a double-tap started (the loop reverses it).
var _heading_before_burst := Vector3.FORWARD
var _dive_time := 0.0
var _dive_dir := Vector3.ZERO
var _jink_time := 0.0
var _cling_lost := 0.0
var _wing_l: Node3D
var _wing_r: Node3D
var _buzz: AudioStreamPlayer3D


func _setup() -> void:
	stamina = stats.stamina_max
	_wing_l = get_node_or_null("Visual/WingL")
	_wing_r = get_node_or_null("Visual/WingR")
	_buzz = AudioManager.make_loop_emitter(&"buzz", self, -12.0, &"SFX")
	PerceptionSystem.strike_incoming.connect(_on_strike_incoming)


func _exit_tree() -> void:
	if bullet_time:
		_end_bullet_time()


func get_action_labels() -> Dictionary:
	if clinging:
		return {"primary": "Boost", "secondary": "Cling", "jump": "Take off",
			"dodge": "Burst", "interact": "Use", "sense": "Slow-mo"}
	if flying:
		return {"primary": "Boost", "secondary": "Down/Cling", "jump": "Up",
			"dodge": "Burst", "interact": "Use", "sense": "Slow-mo"}
	return {"primary": "Boost", "secondary": "Down/Land", "jump": "Take off",
		"dodge": "Burst", "interact": "Use", "sense": "Slow-mo"}


func is_jinking() -> bool:
	return _jink_time > 0.0


func is_looping() -> bool:
	return _loop_time > 0.0


func is_diving() -> bool:
	return _dive_time > 0.0


# --- State changes ----------------------------------------------------------

func take_off() -> void:
	if flying:
		return
	if stamina < stats.takeoff_stamina:
		show_hint("Too tired to fly - rest a moment")
		return
	var push := cling_normal if clinging else Vector3.UP
	_leave_surface()
	flying = true
	gliding = false
	motion_mode = MOTION_MODE_FLOATING
	up_direction = Vector3.UP
	velocity = push * stats.ascend_speed + Vector3.UP * stats.ascend_speed * 0.5
	AudioManager.start_loop(_buzz)


func land() -> void:
	if not flying and not clinging:
		return
	_leave_surface()
	flying = false
	gliding = false
	motion_mode = MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	AudioManager.stop_loop(_buzz)


## Perch on a wall or ceiling.
func cling(n: Vector3) -> void:
	flying = false
	gliding = false
	clinging = true
	cling_normal = n.normalized()
	_cling_lost = 0.0
	_loop_time = 0.0
	_dive_time = 0.0
	motion_mode = MOTION_MODE_FLOATING
	up_direction = cling_normal
	velocity = Vector3.ZERO
	AudioManager.stop_loop(_buzz)
	AudioManager.play(&"dash", -12.0, 2.0)
	show_hint("Clinging - hold still to blend in")


func _leave_surface() -> void:
	if clinging:
		clinging = false
		if visual:
			visual.rotation = Vector3(0.0, atan2(-facing.x, -facing.z), 0.0)


func _action_pressed(a: StringName) -> void:
	if a == &"jump" and not flying:
		_jump_queued = false
		take_off()


# --- Movement -----------------------------------------------------------------

func _move(delta: float) -> void:
	# During bullet time the fly moves at full speed while the world slows.
	var comp := 1.0 / maxf(Engine.time_scale, 0.05) if bullet_time else 1.0
	_since_dodge += delta
	_jink_time = maxf(_jink_time - delta, 0.0)
	if clinging:
		_cling_tick(delta)
	elif flying:
		_fly(delta, comp)
	else:
		stamina = minf(stamina + stats.stamina_regen * delta, stats.stamina_max)
		ground_move(delta, stats.move_speed * speed_scale())
		face_velocity(delta)
	meter_changed.emit(&"stamina", stamina, stats.stamina_max)
	if _wing_l and _wing_r:
		var flap := 0.0
		if flying and not gliding:
			flap = sin(Time.get_ticks_msec() * 0.06) * 0.9
		elif gliding:
			flap = 0.35
		_wing_l.rotation.z = flap
		_wing_r.rotation.z = -flap


func _cling_tick(delta: float) -> void:
	stamina = minf(stamina + stats.stamina_regen * delta, stats.stamina_max)
	velocity = -cling_normal * 2.0
	move_and_slide()
	if get_slide_collision_count() == 0:
		_cling_lost += delta
		if _cling_lost > 0.2:
			# The surface moved away (or never was): drop.
			_leave_surface()
			motion_mode = MOTION_MODE_GROUNDED
			up_direction = Vector3.UP
	else:
		_cling_lost = 0.0
	if visual and clinging:
		var f := facing - cling_normal * facing.dot(cling_normal)
		if f.length_squared() < 0.001:
			f = Vector3.FORWARD - cling_normal * cling_normal.dot(Vector3.FORWARD)
			if f.length_squared() < 0.001:
				f = Vector3.RIGHT - cling_normal * cling_normal.dot(Vector3.RIGHT)
		var s := visual.scale
		visual.global_basis = Basis.looking_at(f.normalized(), cling_normal)
		visual.scale = s


func _fly(delta: float, comp: float) -> void:
	_wobble_t += delta * comp
	var input := move_input()
	var fwd := cam.get_forward() if cam else -camera_yaw_basis.z
	var right := camera_yaw_basis.x
	var wish := fwd * input.y + right * input.x
	if InputRouter.is_held(&"jump") and not gliding:
		wish += Vector3.UP
	if InputRouter.is_held(&"secondary"):
		wish += Vector3.DOWN
	wish = wish.limit_length(1.0)
	_check_jink(wish)
	if _loop_time > 0.0:
		# Evasive loop: climb steeply while reversing, then come down behind.
		_loop_time -= delta * comp
		var k := 1.0 - _loop_time / LOOP_TIME
		velocity = Vector3.UP * cos(k * PI) * 16.0 + _loop_back * 12.0
	elif _dive_time > 0.0:
		_dive_time -= delta * comp
		velocity = Vector3.DOWN * DIVE_SPEED + _dive_dir * 6.0
	elif gliding:
		var g := Vector3(wish.x, 0.0, wish.z) * stats.flight_speed * GLIDE_SPEED_MULT * speed_scale()
		velocity.x = lerpf(velocity.x, g.x, clampf(2.0 * delta, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, g.z, clampf(2.0 * delta, 0.0, 1.0))
		velocity.y = move_toward(velocity.y, -GLIDE_SINK, 10.0 * delta)
	else:
		var speed := (stats.boost_speed if is_sprinting() else stats.flight_speed) * speed_scale()
		# Buzzy drift from layered sines (no allocation, no RNG).
		var t := _wobble_t
		var drift := Vector3(sin(t * 7.3) + sin(t * 3.1) * 0.5, sin(t * 5.7) * 0.6,
			cos(t * 6.1) + sin(t * 2.3) * 0.5) * stats.drift
		velocity = velocity.lerp(wish * speed + drift, clampf(stats.flight_accel * delta * comp, 0.0, 1.0))
		if _dodge_time > 0.0:
			velocity = _dodge_dir * stats.dodge_speed
		if not has_effect(&"wired"):
			stamina -= stats.stamina_drain * (2.0 if is_sprinting() else 1.0) * delta * comp
	var ext := external_velocity
	velocity = (velocity + ext) * comp
	move_and_slide()
	velocity = velocity / comp - ext
	# Touching something: floors land you, walls and ceilings can be clung to.
	if get_slide_collision_count() > 0:
		var n := get_slide_collision(0).get_normal()
		var down := InputRouter.is_held(&"secondary")
		if n.y > 0.7 and (gliding or down or _dive_time > 0.0):
			land()
			return
		# Walls: hold Down into them. Ceilings: fly up into them holding Up.
		if (n.y <= 0.7 and (gliding or down)) or (n.y < -0.7 and InputRouter.is_held(&"jump")):
			cling(n)
			return
	if not gliding and stamina <= 0.0:
		stamina = 0.0
		gliding = true
		AudioManager.stop_loop(_buzz)
		show_hint("Out of stamina - gliding down silently")
	var dir := velocity
	if dir.length() > 0.5 and Vector2(dir.x, dir.z).length() > 0.3:
		facing = Vector3(dir.x, 0.0, dir.z).normalized()
	if visual:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), clampf(stats.turn_speed * delta, 0.0, 1.0))
		visual.rotation.x = lerpf(visual.rotation.x, clampf(-velocity.y * 0.03, -0.5, 0.5), 0.2)
		visual.rotation.z = 0.0


## Steering hard against your flight at speed is a jink: threats struggle
## to follow you for a moment.
func _check_jink(wish: Vector3) -> void:
	if gliding or _loop_time > 0.0 or _dive_time > 0.0 or wish.length() < 0.5:
		return
	if velocity.length() < JINK_MIN_SPEED:
		return
	if velocity.normalized().angle_to(wish.normalized()) > JINK_ANGLE:
		if _jink_time <= 0.0:
			show_hint("Jink! Hard to track")
		_jink_time = JINK_TIME


func is_sprinting() -> bool:
	return flying and not gliding and InputRouter.is_held(&"primary")


func motion_speed() -> float:
	if clinging:
		return 0.0
	return velocity.length() if flying else super.motion_speed()


func _update_motion(delta: float) -> void:
	super._update_motion(delta)
	# A hovering fly is still buzzing: it can never freeze in the air.
	if flying and motion == Motion.STILL:
		motion = Motion.WALK
		still_time = 0.0


func current_noise() -> float:
	if clinging:
		return 0.0
	if flying and (gliding or _dive_time > 0.0):
		return 0.05
	if flying:
		return (0.3 + velocity.length() / stats.flight_speed) * stats.noise_mult
	return super.current_noise() * 0.5


func current_camo_tag() -> StringName:
	if clinging and cling_normal.y < 0.7:
		return &"wall"
	return camo_tag


func _extra_visibility_mult() -> float:
	return JINK_VISIBILITY if _jink_time > 0.0 else 1.0


func _leaves_scent() -> bool:
	return not flying and not clinging


func _try_dodge() -> void:
	if not flying or gliding:
		if not flying and not clinging:
			super._try_dodge()
		return
	# Dive: Burst while holding Down.
	if InputRouter.is_held(&"secondary") and stamina >= DIVE_COST and _dive_time <= 0.0:
		stamina -= DIVE_COST
		_dive_time = DIVE_TIME
		_dive_dir = facing
		invuln = maxf(invuln, 0.25)
		_dodge_cd = stats.dodge_cooldown * 0.6
		AudioManager.play(&"whoosh", -4.0, 0.8)
		show_hint("Dive!")
		return
	# Evasive loop: a second Burst right after the first.
	if _since_dodge < LOOP_WINDOW and stamina >= LOOP_COST and _loop_time <= 0.0:
		stamina -= LOOP_COST
		_loop_time = LOOP_TIME
		_loop_back = -_heading_before_burst
		facing = -_heading_before_burst
		_dodge_time = 0.0
		invuln = maxf(invuln, LOOP_TIME)
		_since_dodge = 99.0
		AudioManager.play(&"dash", -2.0, 0.9)
		show_hint("Evasive loop!")
		return
	if _dodge_cd > 0.0:
		return
	_heading_before_burst = facing
	var input := move_input()
	var dir := camera_yaw_basis.x * (input.x if absf(input.x) > 0.1 else (1.0 if randf() > 0.5 else -1.0))
	dir += Vector3.UP * 0.3
	_dodge_dir = dir.normalized()
	_dodge_time = stats.dodge_duration
	_dodge_cd = stats.dodge_cooldown
	_since_dodge = 0.0
	invuln = maxf(invuln, stats.dodge_duration + 0.05)
	AudioManager.play(&"dash", -4.0, 1.3)


func teleport_to(xform: Transform3D) -> void:
	_leave_surface()
	_loop_time = 0.0
	_dive_time = 0.0
	if flying:
		gliding = false
	super.teleport_to(xform)


# --- Compound eyes: bullet time ---------------------------------------------

func toggle_sense() -> void:
	if not bullet_time and sense_meter >= stats.bullet_time_cost:
		sense_meter -= stats.bullet_time_cost
		start_bullet_time()


func _on_strike_incoming(pos: Vector3, time_to_impact: float, radius: float) -> void:
	if dead or bullet_time or global_position.distance_to(pos) > radius + 5.0:
		return
	var wait := maxf(time_to_impact - 0.45, 0.0)
	get_tree().create_timer(wait, false, true).timeout.connect(_on_strike_close.bind(pos, radius))


func _on_strike_close(pos: Vector3, radius: float) -> void:
	if not dead and not bullet_time and sense_meter >= stats.bullet_time_cost \
			and global_position.distance_to(pos) <= radius + 5.0:
		sense_meter -= stats.bullet_time_cost
		start_bullet_time()


func start_bullet_time() -> void:
	bullet_time = true
	Engine.time_scale = stats.bullet_time_scale
	AudioServer.playback_speed_scale = 0.7
	sense_changed.emit(true)
	AudioManager.play(&"slowmo", -2.0)
	get_tree().create_timer(stats.bullet_time_duration, true, false, true).timeout.connect(_end_bullet_time)


func _end_bullet_time() -> void:
	if not bullet_time:
		return
	bullet_time = false
	Engine.time_scale = 1.0
	AudioServer.playback_speed_scale = 1.0
	if is_inside_tree():
		sense_changed.emit(false)


func die(cause: StringName) -> void:
	_end_bullet_time()
	land()
	super.die(cause)


func refill() -> void:
	super()
	stamina = stats.stamina_max
