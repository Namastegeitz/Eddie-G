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
var web_time := 0.0
var present := true
var player_visible := false
var _forced_present := false
var _sense_timer := 0.0
var _ray := PhysicsRayQueryParameters3D.new()
var _icon: Label3D


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
	web_time = maxf(web_time - delta, 0.0)
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
		var dist := eye_position().distance_to(p.global_position)
		var proximity := 1.0 - clampf(dist / config.sight_range, 0.0, 1.0)
		alert.add_suspicion(config.suspicion_gain * PerceptionSystem.visibility * (0.35 + proximity) * dt,
			p.global_position, true)


func can_see(p: BugBase) -> bool:
	if config.sight_range <= 0.0 or p.is_hidden_safe():
		return false
	if PerceptionSystem.visibility < config.min_visibility:
		return false
	var eye := eye_position()
	var target := p.global_position + p.up_direction * 0.3
	var to := target - eye
	var dist := to.length()
	if dist > config.sight_range or dist < 0.001:
		return false
	var flat_dist := Vector2(to.x, to.z).length()
	if flat_dist > config.near_sense_radius:
		var cos_half := cos(deg_to_rad(config.sight_angle_deg * 0.5))
		if look_direction().dot(to / dist) < cos_half:
			return false
	_ray.from = eye
	_ray.to = target
	return get_world_3d().direct_space_state.intersect_ray(_ray).is_empty()


func hear(pos: Vector3, loudness: float, from_player: bool) -> void:
	if not present or stun_time > 0.0 or config.hearing_radius <= 0.0:
		return
	var reach := config.hearing_radius * loudness * _hearing_mult()
	var d := global_position.distance_to(pos)
	if d > reach:
		return
	var strength := (1.0 - d / reach) * loudness * config.hearing_gain
	alert.add_suspicion(strength, pos, false, not from_player)


func _hearing_mult() -> float:
	return 1.0


# --- Reactions --------------------------------------------------------------

func stun(seconds: float = -1.0) -> void:
	if not present:
		return
	var was_stunned := stun_time > 0.0
	stun_time = config.stun_duration if seconds < 0.0 else seconds
	alert.lose_track()
	velocity = Vector3.ZERO
	if not was_stunned:
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


func force_present(on: bool) -> void:
	_forced_present = on
	_on_routine_changed()


func _on_routine_changed() -> void:
	var now := _forced_present or active_events.is_empty() or HouseClock.any_active(active_events)
	if now == present and is_node_ready():
		return
	present = now
	visible = now
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
	var ts := config.turn_speed if turn_speed < 0.0 else turn_speed
	rotation.y = lerp_angle(rotation.y, yaw, clampf(ts * delta, 0.0, 1.0))


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
