class_name Threat
extends CharacterBody3D
## Base for every perceiving enemy: shared senses (sight cone + line of sight,
## hearing, optional scent), the alert state machine, stuns, web slowdowns,
## routine-driven presence and the floating ? / ! icon.

signal stunned(threat: Threat)

@export var config: ThreatConfig
@export var display_name: String = "Threat"
## Present only during these routine events (empty = always present).
@export var active_events: PackedStringArray = []
@export var icon_height: float = 6.0

var alert := AlertState.new()
var stun_time := 0.0
## How sharp this threat is (1 = normal). Rooms set it for animals
## (LevelConfig.animal_awareness): it speeds up suspicion, stretches sight and
## hearing a little, and makes them turn faster.
var awareness := 1.0
## Dazzled (a firefly's flash) or coughing (a stink cloud): can't see.
var blind_time := 0.0
var web_time := 0.0
var present := true
var player_visible := false
var _forced_present := false
var _sense_timer := 0.0
var _ray := PhysicsRayQueryParameters3D.new()
var _icon: Label3D
## Their routine says go, but they're busy with you: they leave once calm.
var leave_pending := false
var _calm_t := 0.0
## Turning has momentum: it eases into a turn and out of it.
const TURN_ACCEL := 9.0
var _turn_rate := 0.0
var _turn_frame := -10


func _ready() -> void:
	add_to_group(Phys.GROUP_THREAT)
	collision_layer = Phys.THREAT
	collision_mask = Phys.WORLD
	if config == null:
		config = ThreatConfig.new()
	alert.setup(config)
	_ray.collision_mask = Phys.WORLD
	_ray.exclude = [get_rid()]
	_icon = Fx.make_icon_label()
	_icon.position = Vector3.UP * icon_height
	add_child(_icon)
	PerceptionSystem.register_threat(self)
	HouseClock.routine_changed.connect(_on_routine_changed)
	_setup()
	_on_routine_changed()


func _exit_tree() -> void:
	PerceptionSystem.unregister_threat(self)


func _setup() -> void:
	pass


func _physics_process(delta: float) -> void:
	if not present:
		return
	if leave_pending:
		if _routine_wants_present():
			leave_pending = false
		elif _too_busy_to_leave():
			_calm_t = 0.0
		else:
			_calm_t += delta
			if _calm_t > 1.5:
				leave_pending = false
				_begin_leave()
				if not present:
					return
	web_time = maxf(web_time - delta, 0.0)
	blind_time = maxf(blind_time - delta, 0.0)
	if stun_time > 0.0:
		stun_time -= delta
		_stunned_tick(delta)
		_update_icon()
		return
	_sense_timer -= delta
	if _sense_timer <= 0.0:
		_sense_timer = config.sense_interval
		_sense(config.sense_interval)
	alert.tick(delta)
	_think(delta)
	_update_icon()


## Subclass behavior for the current alert state.
func _think(_delta: float) -> void:
	pass


func _stunned_tick(_delta: float) -> void:
	pass


# --- Senses -------------------------------------------------------------------

func eye_position() -> Vector3:
	return global_position + Vector3.UP * config.eye_height


func look_direction() -> Vector3:
	var fwd := -global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	if config.gaze_pitch_deg != 0.0:
		fwd = fwd.rotated(fwd.cross(Vector3.UP).normalized(), -deg_to_rad(config.gaze_pitch_deg))
	return fwd


func ground_position() -> Vector3:
	return global_position


func _sense(dt: float) -> void:
	var p := PerceptionSystem.player
	if p == null or p.dead:
		player_visible = false
		return
	player_visible = can_see(p)
	if player_visible:
		var flat := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
		var proximity := 1.0 - clampf(flat / config.sight_range, 0.0, 1.0)
		var amount := config.suspicion_gain * PerceptionSystem.visibility * (0.35 + proximity) * dt \
			* effective_awareness() * perception_mult()
		alert.add_suspicion(amount, p.global_position, true)
		PerceptionSystem.add_alarm_from_sight(amount)


func can_see(p: BugBase) -> bool:
	if config.sight_range <= 0.0 or p.is_hidden_safe() or blind_time > 0.0:
		return false
	if PerceptionSystem.visibility < config.min_visibility:
		return false
	var eye := eye_position()
	var target := p.global_position + p.up_direction * 0.3
	var to := target - eye
	var dist := to.length()
	# Range is measured across the floor: a human's eyes are ~60 units up, so a
	# straight-line range would leave the whole floor out of sight.
	var flat_dist := Vector2(to.x, to.z).length()
	var aware := effective_awareness()
	var sight := config.sight_range * (1.0 + (aware - 1.0) * 0.4) * lerpf(1.0, perception_mult(), 0.5)
	if flat_dist > sight or dist < 0.001:
		return false
	if flat_dist > config.near_sense_radius:
		var cos_half := cos(deg_to_rad(config.sight_angle_deg * 0.5))
		if look_direction().dot(to / dist) < cos_half:
			return false
	_ray.from = eye
	_ray.to = target
	return get_world_3d().direct_space_state.intersect_ray(_ray).is_empty()


## A firefly's flash: can't see for a few seconds.
func dazzle(seconds: float) -> void:
	if not present:
		return
	blind_time = maxf(blind_time, seconds)
	_on_dazzled()


func _on_dazzled() -> void:
	pass


## A stink bug's cloud: humans cough, pets bolt. Returns true if it worked.
func stink(_from: Vector3, _seconds: float) -> bool:
	return false


func has_line_of_sight(p: BugBase) -> bool:
	_ray.from = eye_position()
	_ray.to = p.global_position + p.up_direction * 0.3
	return get_world_3d().direct_space_state.intersect_ray(_ray).is_empty()


func hear(pos: Vector3, loudness: float, from_player: bool) -> void:
	if not present or stun_time > 0.0 or config.hearing_radius <= 0.0:
		return
	var aware := effective_awareness()
	var reach := config.hearing_radius * loudness * _hearing_mult() * (1.0 + (aware - 1.0) * 0.5)
	var d := global_position.distance_to(pos)
	if d > reach:
		return
	var strength := (1.0 - d / reach) * loudness * config.hearing_gain * aware
	alert.add_suspicion(strength, pos, false, not from_player)
	if from_player:
		PerceptionSystem.add_alarm_from_sound(strength)


func _hearing_mult() -> float:
	return 1.0


func effective_awareness() -> float:
	return awareness


## Sight multiplier for moods (a playing pet, a flustered person): 1 = normal.
func perception_mult() -> float:
	return 1.0


# --- Reactions --------------------------------------------------------------

## `quiet`: frozen by a gem rather than tricked, so it doesn't count as a
## threat you turned.
func stun(seconds: float = -1.0, quiet: bool = false) -> void:
	if not present:
		return
	var was_stunned := stun_time > 0.0
	stun_time = config.stun_duration if seconds < 0.0 else seconds
	alert.lose_track()
	velocity = Vector3.ZERO
	if not was_stunned and not quiet:
		stunned.emit(self)
		PerceptionSystem.notify_stunned(self)
		AudioManager.play_at(&"stun", eye_position(), 0.0)
	_on_stunned()


func _on_stunned() -> void:
	pass


func apply_web(seconds: float) -> void:
	web_time = maxf(web_time, seconds)


func speed_mult() -> float:
	var m := 0.3 if web_time > 0.0 else 1.0
	if Level.current:
		m *= Level.current.hazard_speed()
	return m


func force_alert(state: int, pos: Vector3) -> void:
	if present and stun_time <= 0.0:
		alert.force(state, pos)


## A direct order (bosses, tests): takes effect at once.
func force_present(on: bool) -> void:
	_forced_present = on
	leave_pending = false
	_set_present(_routine_wants_present())


func _routine_wants_present() -> bool:
	return _forced_present or active_events.is_empty() or HouseClock.any_active(active_events)


## Busy with you (suspicious, searching, chasing, hopping on one foot): their
## routine can wait - nobody vanishes mid-chase.
func _too_busy_to_leave() -> bool:
	return alert.state > AlertState.UNAWARE or stun_time > 0.0


func _on_routine_changed() -> void:
	var now := _routine_wants_present()
	if not now and present and is_node_ready() and _too_busy_to_leave():
		leave_pending = true
		_calm_t = 0.0
		return
	leave_pending = false
	_set_present(now)


## Time to go, and calm: leave (people walk out of the room; see Human).
func _begin_leave() -> void:
	_set_present(false)


func _set_present(now: bool) -> void:
	if now == present and is_node_ready():
		return
	present = now
	visible = now
	reset_physics_interpolation()
	process_mode = Node.PROCESS_MODE_INHERIT
	collision_layer = Phys.THREAT if now else 0
	if not now:
		alert.reset()
		stun_time = 0.0
	_on_presence_changed(now)


func _on_presence_changed(_now: bool) -> void:
	pass


func face_towards(target: Vector3, delta: float, turn_speed: float = -1.0) -> void:
	var to := target - global_position
	to.y = 0.0
	if to.length_squared() < 0.01:
		return
	var yaw := atan2(-to.x, -to.z)
	var ts := (config.turn_speed if turn_speed < 0.0 else turn_speed) * clampf(effective_awareness(), 0.5, 2.0)
	var frame := Engine.get_physics_frames()
	if frame - _turn_frame > 2:
		_turn_rate = 0.0
	_turn_frame = frame
	var diff := wrapf(yaw - rotation.y, -PI, PI)
	# Same pace as before once under way, but it builds up instead of jerking.
	_turn_rate = move_toward(_turn_rate, diff * ts, ts * TURN_ACCEL * delta)
	var step := _turn_rate * delta
	if absf(step) > absf(diff) and signf(step) == signf(diff):
		step = diff
		_turn_rate = 0.0
	rotation.y = wrapf(rotation.y + step, -PI, PI)


func _update_icon() -> void:
	if _icon == null:
		return
	if stun_time > 0.0:
		_icon.text = "*"
		_icon.modulate = Color(0.7, 0.8, 1.0)
		return
	match alert.state:
		AlertState.SUSPICIOUS:
			_icon.text = "?"
			_icon.modulate = Color(1.0, 0.9, 0.2)
		AlertState.SEARCHING:
			_icon.text = "?"
			_icon.modulate = Color(1.0, 0.55, 0.1)
		AlertState.ALERT:
			_icon.text = "!"
			_icon.modulate = Color(1.0, 0.15, 0.1)
		_:
			_icon.text = _idle_icon()
			_icon.modulate = Color(0.7, 0.8, 1.0)


func _idle_icon() -> String:
	return ""
