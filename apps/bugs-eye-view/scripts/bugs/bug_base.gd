class_name BugBase
extends CharacterBody3D
## Shared bug interface. Levels, hazards and threats treat every bug the same:
## hits/lives, stealth inputs (motion, surface, camouflage), senses, external
## forces (wind, suction, sticky traps) and interaction. Subclasses implement
## _move() and their abilities.

signal hit_taken(hits_left: int)
signal died(cause: StringName)
signal sense_changed(active: bool)
signal meter_changed(meter: StringName, value: float, max_value: float)
signal hint_changed(text: String)

enum Motion { STILL, CREEP, WALK, SPRINT }

const INTERACT_PROP_RADIUS := 3.0
const PROBE_INTERVAL := 0.1
const HINT_INTERVAL := 0.25

@export var stats: BugStats

var hits_left := 1
var motion: int = Motion.STILL
var still_time := 0.0
var surface_id: StringName = &"default"
var camo_tag: StringName = &""
var is_squeezing := false
var dead := false
var invuln := 0.0
var knockdown := 0.0
var stuck_time := 0.0
var slow_mult := 1.0
var external_velocity := Vector3.ZERO
var spray_exposure := 0.0
var wiper_count := 0
var sense_meter := 0.0
var sense_active := false
## Yaw-only basis from the follow camera; movement is camera-relative.
var camera_yaw_basis: Basis = Basis.IDENTITY
var cam: FollowCamera = null
var facing := Vector3.FORWARD

var _spots: Array[HidingSpot] = []
var _interactables: Array[Node] = []
var _noise_timer := 0.0
var _probe_timer := 0.0
var _hint_timer := 0.0
var _probe := PhysicsRayQueryParameters3D.new()
var _dodge_time := 0.0
var _dodge_cd := 0.0
var _dodge_dir := Vector3.ZERO
var _jump_queued := false
var _slow_timer := 0.0
var _hint := ""
var _cfg: StealthConfig

@onready var visual: Node3D = get_node_or_null("Visual")


func _ready() -> void:
	add_to_group(Phys.GROUP_PLAYER)
	collision_layer = Phys.PLAYER
	collision_mask = Phys.WORLD | Phys.PROP | Phys.WEB
	if stats == null:
		stats = BugStats.new()
	hits_left = stats.max_hits
	sense_meter = stats.sense_max
	floor_max_angle = deg_to_rad(stats.floor_max_angle_deg)
	floor_snap_length = 0.3
	_cfg = PerceptionSystem.config
	_probe.collision_mask = Phys.WORLD | Phys.PROP | Phys.WEB
	_probe.exclude = [get_rid()]
	InputRouter.action_pressed.connect(_on_action_pressed)
	InputRouter.action_released.connect(_on_action_released)
	_setup()


## Subclass hook called at the end of _ready().
func _setup() -> void:
	pass


func _physics_process(delta: float) -> void:
	if dead:
		return
	_tick_timers(delta)
	if knockdown > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		velocity.y -= stats.gravity * delta
		move_and_slide()
		return
	_move(delta)
	_push_props()
	_update_motion(delta)
	_probe_timer -= delta
	if _probe_timer <= 0.0:
		_probe_timer = PROBE_INTERVAL
		_probe_surface()
	_emit_noise(delta)
	_update_sense(delta)
	_hint_timer -= delta
	if _hint_timer <= 0.0:
		_hint_timer = HINT_INTERVAL
		_update_hint()
	if global_position.y < -40.0:
		die(&"fell")


## Subclass movement. Must set velocity and call move_and_slide().
func _move(_delta: float) -> void:
	pass


func _tick_timers(delta: float) -> void:
	invuln = maxf(invuln - delta, 0.0)
	knockdown = maxf(knockdown - delta, 0.0)
	_dodge_cd = maxf(_dodge_cd - delta, 0.0)
	_dodge_time = maxf(_dodge_time - delta, 0.0)
	stuck_time = maxf(stuck_time - delta, 0.0)
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			slow_mult = 1.0
	external_velocity = external_velocity.move_toward(Vector3.ZERO, 25.0 * delta)
	spray_exposure = maxf(spray_exposure - _cfg.spray_exposure_decay * delta, 0.0)
	if visual:
		visual.visible = invuln <= 0.0 or fmod(invuln, 0.2) > 0.1


# --- Input helpers ----------------------------------------------------------

func move_input() -> Vector2:
	if stuck_time > 0.0:
		return Vector2.ZERO
	return InputRouter.get_move_vector()


## Camera-relative direction on the ground plane. Length follows the stick.
func flat_dir(v2: Vector2) -> Vector3:
	var fwd := -camera_yaw_basis.z
	var right := camera_yaw_basis.x
	return right * v2.x + fwd * v2.y


func _on_action_pressed(a: StringName) -> void:
	if dead or not is_inside_tree():
		return
	if stuck_time > 0.0:
		# Mash any button to tear free of a sticky trap.
		stuck_time = maxf(stuck_time - 0.35, 0.0)
		return
	match a:
		&"interact":
			_do_interact()
		&"dodge":
			_try_dodge()
		&"sense":
			toggle_sense()
		&"jump":
			_jump_queued = true
	_action_pressed(a)


func _on_action_released(a: StringName) -> void:
	if not dead:
		_action_released(a)


func _action_pressed(_a: StringName) -> void:
	pass


func _action_released(_a: StringName) -> void:
	pass


## Labels for the touch buttons and the controls help.
func get_action_labels() -> Dictionary:
	return {"primary": "Sprint", "secondary": "Squeeze", "jump": "Jump",
		"dodge": "Dodge", "interact": "Use", "sense": "Sense"}


# --- Shared ground movement -------------------------------------------------

func ground_move(delta: float, speed: float) -> void:
	var dir := flat_dir(move_input())
	var target := dir * speed
	var accel := stats.acceleration
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	if _dodge_time > 0.0:
		velocity.x = _dodge_dir.x * stats.dodge_speed
		velocity.z = _dodge_dir.z * stats.dodge_speed
	if is_on_floor():
		if _jump_queued:
			velocity.y = stats.jump_velocity
	else:
		velocity.y -= stats.gravity * delta
	_jump_queued = false
	var ext := external_velocity
	velocity += ext
	move_and_slide()
	velocity -= ext


func face_velocity(delta: float) -> void:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > 0.5:
		facing = flat.normalized()
	if visual:
		var yaw := atan2(-facing.x, -facing.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, yaw, clampf(stats.turn_speed * delta, 0.0, 1.0))


func _try_dodge() -> void:
	if _dodge_cd > 0.0:
		return
	var dir := flat_dir(move_input())
	if dir.length() < 0.1:
		dir = facing
	_dodge_dir = dir.normalized()
	_dodge_time = stats.dodge_duration
	_dodge_cd = stats.dodge_cooldown
	invuln = maxf(invuln, stats.dodge_duration + 0.05)
	AudioManager.play(&"dash", -4.0)


func motion_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func is_sprinting() -> bool:
	return false


func _update_motion(delta: float) -> void:
	var input_len := move_input().length()
	if input_len < 0.05 and motion_speed() < 0.6:
		motion = Motion.STILL
		still_time += delta
	else:
		still_time = 0.0
		if is_sprinting():
			motion = Motion.SPRINT
		elif input_len < _cfg.creep_threshold:
			motion = Motion.CREEP
		else:
			motion = Motion.WALK


func _push_props() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var prop := c.get_collider() as PhysicsProp
		if prop:
			prop.freeze = false
			prop.apply_central_impulse(-c.get_normal() * stats.push_force)
			prop.mark_touched()


# --- Stealth ------------------------------------------------------------------

func compute_visibility(light: float, cfg: StealthConfig) -> float:
	if is_hidden_safe():
		return 0.0
	var m := 1.0
	match motion:
		Motion.STILL:
			m = lerpf(1.0, cfg.freeze_factor, clampf(still_time / cfg.freeze_delay, 0.0, 1.0))
		Motion.CREEP:
			m = cfg.creep_visibility
		Motion.SPRINT:
			m = cfg.sprint_visibility
	var camo := 1.0
	if is_frozen() and has_camo():
		camo = cfg.camo_factor / maxf(stats.camo_mult, 0.01)
	return clampf(light * m * camo * stats.visibility_mult * _extra_visibility_mult(), 0.0, 1.5)


func is_frozen() -> bool:
	return motion == Motion.STILL and still_time >= _cfg.freeze_delay


func has_camo() -> bool:
	var tag := current_camo_tag()
	return tag != &"" and stats.camo_tags.has(String(tag))


func current_camo_tag() -> StringName:
	return camo_tag


func _extra_visibility_mult() -> float:
	return 1.0


func _probe_surface() -> void:
	_probe.from = global_position + up_direction * 0.3
	_probe.to = global_position - up_direction * 1.2
	var hit := get_world_3d().direct_space_state.intersect_ray(_probe)
	if hit.is_empty():
		surface_id = &"air"
		camo_tag = &""
		return
	var col: Object = hit["collider"]
	surface_id = StringName(col.get_meta(&"surface", &"default")) if col else &"default"
	camo_tag = StringName(col.get_meta(&"camo", &"")) if col else &""


func current_noise() -> float:
	if motion == Motion.STILL or surface_id == &"air":
		return 0.0
	var mm := _cfg.walk_noise
	if motion == Motion.CREEP:
		mm = _cfg.creep_noise
	elif motion == Motion.SPRINT:
		mm = _cfg.sprint_noise
	return _cfg.loudness_of(surface_id) * mm * stats.noise_mult


func _emit_noise(delta: float) -> void:
	_noise_timer -= delta
	if _noise_timer > 0.0:
		return
	_noise_timer = _cfg.noise_interval
	var l := current_noise()
	if l > 0.01:
		PerceptionSystem.emit_player_noise(global_position, l)


func is_scent_active() -> bool:
	return wiper_count <= 0 and not is_hidden_safe() and _leaves_scent()


func _leaves_scent() -> bool:
	return true


# --- Senses ---------------------------------------------------------------

func toggle_sense() -> void:
	if sense_active:
		_end_sense()
	elif sense_meter > 0.5:
		sense_active = true
		_sense_start()
		sense_changed.emit(true)
		AudioManager.play(&"sense_on", -6.0)


func _end_sense() -> void:
	if not sense_active:
		return
	sense_active = false
	_sense_end()
	sense_changed.emit(false)


func _update_sense(delta: float) -> void:
	if sense_active:
		sense_meter -= delta
		_sense_tick(delta)
		if sense_meter <= 0.0:
			sense_meter = 0.0
			_end_sense()
	else:
		sense_meter = minf(sense_meter + stats.sense_regen * delta, stats.sense_max)
	meter_changed.emit(&"sense", sense_meter, stats.sense_max)


func _sense_start() -> void:
	pass


func _sense_tick(_delta: float) -> void:
	pass


func _sense_end() -> void:
	pass


# --- Damage & forces --------------------------------------------------------

## Returns true if the hit landed.
func take_hit(cause: StringName, from: Vector3) -> bool:
	if dead or invuln > 0.0 or is_hidden_safe():
		return false
	hits_left -= 1
	Feedback.rumble(1.0, 0.4)
	AudioManager.play(&"hit")
	if hits_left <= 0:
		die(cause)
		return true
	invuln = stats.invuln_time
	knockdown = stats.knockdown_time
	var away := global_position - from
	away.y = 0.0
	if away.length() > 0.01:
		velocity = away.normalized() * 10.0 + Vector3.UP * 6.0
	hit_taken.emit(hits_left)
	if visual:
		var tw := create_tween()
		tw.tween_property(visual, "rotation:z", PI, 0.15)
		tw.tween_interval(maxf(stats.knockdown_time - 0.3, 0.05))
		tw.tween_property(visual, "rotation:z", 0.0, 0.15)
	return true


func die(cause: StringName) -> void:
	if dead:
		return
	dead = true
	hits_left = 0
	velocity = Vector3.ZERO
	is_squeezing = false
	_end_sense()
	AudioManager.play(&"squish")
	if visual:
		visual.visible = true
		var tw := create_tween()
		tw.tween_property(visual, "scale", Vector3(1.4, 0.12, 1.4), 0.1)
	died.emit(cause)


func add_spray_exposure(amount: float) -> void:
	spray_exposure += amount
	if spray_exposure >= _cfg.spray_exposure_to_hit:
		spray_exposure = 0.0
		take_hit(&"sprayed", global_position)


func apply_force(force: Vector3, delta: float) -> void:
	external_velocity = (external_velocity + force * delta).limit_length(40.0)


func set_slowed(mult: float, seconds: float) -> void:
	slow_mult = mult
	_slow_timer = seconds


func set_stuck(seconds: float) -> void:
	stuck_time = maxf(stuck_time, seconds)


func is_on_ground_surface() -> bool:
	return is_on_floor()


# --- Hiding & interaction ---------------------------------------------------

func enter_spot(s: HidingSpot) -> void:
	if not _spots.has(s):
		_spots.append(s)


func exit_spot(s: HidingSpot) -> void:
	_spots.erase(s)


func is_hidden_safe() -> bool:
	for s in _spots:
		if s.is_safe_for(self):
			return true
	return false


func add_interactable(n: Node) -> void:
	if not _interactables.has(n):
		_interactables.append(n)


func remove_interactable(n: Node) -> void:
	_interactables.erase(n)


func _do_interact() -> void:
	for n in _interactables:
		if is_instance_valid(n) and n.call(&"can_interact", self):
			n.call(&"interact", self)
			return
	var best: PhysicsProp = null
	var best_d := INTERACT_PROP_RADIUS
	for p in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var prop := p as PhysicsProp
		if prop:
			var d := prop.global_position.distance_to(global_position)
			if d < best_d:
				best = prop
				best_d = d
	if best:
		best.nudge(global_position)
		AudioManager.play(&"push", -6.0)


func _update_hint() -> void:
	var text := ""
	for n in _interactables:
		if is_instance_valid(n):
			text = String(n.call(&"hint_text", self))
			break
	if text == "":
		for s in _spots:
			if s.fits(self):
				text = "Hidden" if s.is_safe_for(self) else s.hint
				break
	if stuck_time > 0.0:
		text = "Stuck! Mash any button"
	if text != _hint:
		_hint = text
		hint_changed.emit(text)


func show_hint(text: String) -> void:
	_hint = text
	hint_changed.emit(text)


func teleport_to(xform: Transform3D) -> void:
	global_position = xform.origin
	velocity = Vector3.ZERO
	_interactables.clear()
	if cam:
		cam.snap()
