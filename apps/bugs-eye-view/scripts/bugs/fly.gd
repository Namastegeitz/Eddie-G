class_name Fly
extends BugBase
## Buzzy free flight with momentum and drift, a burst dodge, a stamina budget
## that forces it to perch, and compound-eye bullet time: when a strike is
## about to land nearby the world slows down while the fly keeps full speed.

var flying := false
var stamina := 0.0
var bullet_time := false
var _wobble_t := 0.0
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
	if flying:
		return {"primary": "Boost", "secondary": "Down/Land", "jump": "Up",
			"dodge": "Burst", "interact": "Use", "sense": "Slow-mo"}
	return {"primary": "Boost", "secondary": "Down/Land", "jump": "Take off",
		"dodge": "Burst", "interact": "Use", "sense": "Slow-mo"}


func take_off() -> void:
	if flying:
		return
	if stamina < stats.takeoff_stamina:
		show_hint("Too tired to fly - rest a moment")
		return
	flying = true
	motion_mode = MOTION_MODE_FLOATING
	up_direction = Vector3.UP
	velocity.y = stats.ascend_speed
	AudioManager.start_loop(_buzz)


func land() -> void:
	if not flying:
		return
	flying = false
	motion_mode = MOTION_MODE_GROUNDED
	AudioManager.stop_loop(_buzz)


func _action_pressed(a: StringName) -> void:
	if a == &"jump" and not flying:
		_jump_queued = false
		take_off()


func _move(delta: float) -> void:
	# During bullet time the fly moves at full speed while the world slows.
	var comp := 1.0 / maxf(Engine.time_scale, 0.05) if bullet_time else 1.0
	if flying:
		_fly(delta, comp)
	else:
		stamina = minf(stamina + stats.stamina_regen * delta, stats.stamina_max)
		ground_move(delta, stats.move_speed * slow_mult)
		face_velocity(delta)
	meter_changed.emit(&"stamina", stamina, stats.stamina_max)
	if _wing_l and _wing_r:
		var flap := sin(Time.get_ticks_msec() * 0.06) * 0.9 if flying else 0.0
		_wing_l.rotation.z = flap
		_wing_r.rotation.z = -flap


func _fly(delta: float, comp: float) -> void:
	_wobble_t += delta * comp
	var input := move_input()
	var fwd := cam.get_forward() if cam else -camera_yaw_basis.z
	var right := camera_yaw_basis.x
	var wish := fwd * input.y + right * input.x
	if InputRouter.is_held(&"jump"):
		wish += Vector3.UP
	if InputRouter.is_held(&"secondary"):
		wish += Vector3.DOWN
	wish = wish.limit_length(1.0)
	var speed := (stats.boost_speed if is_sprinting() else stats.flight_speed) * slow_mult
	# Buzzy drift from layered sines (no allocation, no RNG).
	var t := _wobble_t
	var drift := Vector3(sin(t * 7.3) + sin(t * 3.1) * 0.5, sin(t * 5.7) * 0.6,
		cos(t * 6.1) + sin(t * 2.3) * 0.5) * stats.drift
	velocity = velocity.lerp(wish * speed + drift, clampf(stats.flight_accel * delta * comp, 0.0, 1.0))
	if _dodge_time > 0.0:
		velocity = _dodge_dir * stats.dodge_speed
	stamina -= stats.stamina_drain * (2.0 if is_sprinting() else 1.0) * delta * comp
	var ext := external_velocity
	velocity = (velocity + ext) * comp
	move_and_slide()
	velocity = velocity / comp - ext
	if stamina <= 0.0:
		stamina = 0.0
		land()
		show_hint("Out of stamina - perch to rest")
	elif InputRouter.is_held(&"secondary") and get_slide_collision_count() > 0:
		land()
	var dir := velocity
	if dir.length() > 0.5:
		facing = Vector3(dir.x, 0.0, dir.z).normalized() if Vector2(dir.x, dir.z).length() > 0.3 else facing
	if visual:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), clampf(stats.turn_speed * delta, 0.0, 1.0))
		visual.rotation.x = lerpf(visual.rotation.x, clampf(-velocity.y * 0.03, -0.5, 0.5), 0.2)


func is_sprinting() -> bool:
	return flying and InputRouter.is_held(&"primary")


func motion_speed() -> float:
	return velocity.length() if flying else super.motion_speed()


func _update_motion(delta: float) -> void:
	super._update_motion(delta)
	# A hovering fly is still buzzing: it can never freeze in the air.
	if flying and motion == Motion.STILL:
		motion = Motion.WALK
		still_time = 0.0


func current_noise() -> float:
	if flying:
		return (0.3 + velocity.length() / stats.flight_speed) * stats.noise_mult
	return super.current_noise() * 0.5


func _leaves_scent() -> bool:
	return not flying


func _try_dodge() -> void:
	if _dodge_cd > 0.0:
		return
	if not flying:
		super._try_dodge()
		return
	var input := move_input()
	var dir := camera_yaw_basis.x * (input.x if absf(input.x) > 0.1 else (1.0 if randf() > 0.5 else -1.0))
	dir += Vector3.UP * 0.3
	_dodge_dir = dir.normalized()
	_dodge_time = stats.dodge_duration
	_dodge_cd = stats.dodge_cooldown
	invuln = maxf(invuln, stats.dodge_duration + 0.05)
	AudioManager.play(&"dash", -4.0, 1.3)


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
