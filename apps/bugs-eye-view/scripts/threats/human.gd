class_name Human
extends Threat
## A person walking through the room. Each footstep is a telegraphed stomp.
## The escalation chain decides the weapons: stomps at first, the swatter
## from stage 2, a newspaper sweep (if carried) and bug spray at stage 4.

@export var route: PackedVector3Array = []
@export var stride: float = 9.0
@export var step_time: float = 0.6
@export var foot_spacing: float = 3.4
@export var has_swatter: bool = true
@export var has_newspaper: bool = false
@export var has_spray: bool = true
## Exterminator: heavier, louder stomps.
@export var heavy_boots: bool = false
@export var spray_interval: float = 5.0

var escalation_stage := 0
var _route_i := 1
var _step_timer := 0.0
var _left_next := true
var _attack_cd := 1.5
var _spray_cd := 2.0
var _voice_cd := 0.0
var _pause := 0.0
var _body_pos := Vector3.ZERO
var left_foot: FootHazard
var right_foot: FootHazard
var newspaper: Newspaper
var _torso: Node3D


func _setup() -> void:
	add_to_group(Phys.GROUP_HUMAN)
	left_foot = get_node_or_null("LeftFoot") as FootHazard
	right_foot = get_node_or_null("RightFoot") as FootHazard
	newspaper = get_node_or_null("Newspaper") as Newspaper
	_torso = get_node_or_null("Torso")
	for f in [left_foot, right_foot]:
		if f:
			(f as FootHazard).set_owner_threat(self)
			(f as FootHazard).heavy = heavy_boots
	if newspaper:
		newspaper.owner_threat = self
	_body_pos = global_position
	_plant_feet(global_position, rotation.y)


func _plant_feet(center: Vector3, yaw: float) -> void:
	var side := Basis(Vector3.UP, yaw).x * foot_spacing * 0.5
	if left_foot:
		left_foot.plant_at(center - side, yaw)
	if right_foot:
		right_foot.plant_at(center + side, yaw)


func _on_presence_changed(now: bool) -> void:
	for f in [left_foot, right_foot]:
		if f:
			(f as FootHazard).visible = now
			var body := (f as FootHazard).get_node_or_null("Body") as AnimatableBody3D
			if body:
				body.collision_layer = Phys.WORLD if now else 0
	if now and route.size() > 0 and is_node_ready():
		global_position = route[0]
		_body_pos = route[0]
		_route_i = 1 % route.size()
		_plant_feet(route[0], rotation.y)


func _think(delta: float) -> void:
	_attack_cd -= delta * speed_mult()
	_spray_cd -= delta
	_voice_cd -= delta
	match alert.state:
		AlertState.UNAWARE:
			_patrol(delta)
		AlertState.SUSPICIOUS:
			face_towards(alert.last_known, delta)
			if _voice_cd <= 0.0:
				_voice_cd = 6.0
				AudioManager.play_at(&"voice_huh", eye_position(), 0.0, randf_range(0.9, 1.1), &"Muffled")
		AlertState.SEARCHING:
			_search(delta)
		AlertState.ALERT:
			_attack(delta)
	if escalation_stage >= 4 and has_spray and _spray_cd <= 0.0 \
			and alert.state >= AlertState.SEARCHING:
		_spray_cd = spray_interval
		_spray_at(alert.last_known)
	_update_torso(delta)


func _update_torso(delta: float) -> void:
	if left_foot and right_foot:
		var mid := (left_foot.global_position + right_foot.global_position) * 0.5
		_body_pos = Vector3(mid.x, global_position.y, mid.z)
	global_position = global_position.lerp(_body_pos, clampf(6.0 * delta, 0.0, 1.0))


# --- Walking ----------------------------------------------------------------

func _patrol(delta: float) -> void:
	if route.size() < 2:
		return
	if _pause > 0.0:
		_pause -= delta
		return
	var target := route[_route_i]
	face_towards(target, delta)
	if Vector2(target.x - _body_pos.x, target.z - _body_pos.z).length() < stride * 0.6:
		_route_i = (_route_i + 1) % route.size()
		if randf() < 0.3:
			_pause = randf_range(0.8, 2.0)
		return
	_walk_towards(target, delta, step_time)


func _walk_towards(target: Vector3, delta: float, cadence: float) -> void:
	_step_timer -= delta * speed_mult()
	if _step_timer > 0.0:
		return
	var foot := left_foot if _left_next else right_foot
	if foot == null or not foot.is_planted():
		return
	_step_timer = cadence
	var to := target - _body_pos
	to.y = 0.0
	var dist := to.length()
	if dist < 0.5:
		return
	var dir := to / dist
	var yaw := atan2(-dir.x, -dir.z)
	var side := Basis(Vector3.UP, yaw).x * foot_spacing * 0.5 * (-1.0 if _left_next else 1.0)
	var step := minf(stride, dist + stride * 0.5)
	var land := _body_pos + dir * step * 0.75 + side
	land.y = target.y
	foot.step_to(land, yaw, cadence * 0.85)
	_left_next = not _left_next


# --- Searching & attacking ----------------------------------------------------

func _search(delta: float) -> void:
	var target := alert.last_known
	face_towards(target, delta)
	var flat := Vector2(target.x - _body_pos.x, target.z - _body_pos.z).length()
	if flat > 10.0:
		_walk_towards(target, delta, step_time * 0.8)
	elif _attack_cd <= 0.0:
		# Stomp around the spot where the noise came from.
		_attack_cd = config.attack_cooldown * 1.1
		var off := Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
		_stomp(target + off, config.attack_windup * 1.1)


func _attack(delta: float) -> void:
	var p := PerceptionSystem.player
	if p == null:
		return
	var target := p.global_position
	face_towards(target, delta, config.turn_speed * 2.0)
	var flat := Vector2(target.x - _body_pos.x, target.z - _body_pos.z).length()
	if flat > config.attack_range:
		_walk_towards(target, delta, step_time * 0.7)
		return
	if _attack_cd > 0.0:
		return
	_attack_cd = config.attack_cooldown
	var windup := config.attack_windup / speed_mult()
	if has_newspaper and newspaper and not newspaper.busy and flat < newspaper.length and randf() < 0.5:
		newspaper.sweep_at(_body_pos, target, windup)
	elif has_swatter and escalation_stage >= 2 and Level.current:
		var sw := Level.current.swatter_pool.acquire() as Swatter
		sw.strike(target, windup, self, Level.current.swatter_pool)
	else:
		_stomp(target, windup)


func _stomp(target: Vector3, windup: float) -> void:
	var foot := left_foot if _left_next else right_foot
	if foot == null or not foot.is_planted():
		foot = right_foot if _left_next else left_foot
	if foot == null or not foot.is_planted():
		return
	var to := target - _body_pos
	var yaw := atan2(-to.x, -to.z) if to.length() > 0.5 else foot.yaw
	foot.step_to(Vector3(target.x, foot.global_position.y, target.z), yaw, windup)
	_left_next = not _left_next


func _spray_at(target: Vector3) -> void:
	if Level.current == null:
		return
	var cloud := Level.current.spray_pool.acquire() as SprayCloud
	cloud.spawn(target + Vector3.UP * 1.5, Level.current.spray_pool)
	AudioManager.play_at(&"voice_spray", eye_position(), 0.0, 1.0, &"Muffled")


# --- Escalation hooks -------------------------------------------------------

func shout() -> void:
	AudioManager.play_at(&"voice_shout", eye_position(), 4.0, 1.0, &"Muffled")
	Feedback.rumble(0.3, 0.2)


func call_pet() -> void:
	AudioManager.play_at(&"voice_call", eye_position(), 4.0, 1.0, &"Muffled")


func _on_stunned() -> void:
	AudioManager.play_at(&"voice_ow", eye_position(), 2.0, 1.0, &"Muffled")
	_attack_cd = config.stun_duration


func _stunned_tick(delta: float) -> void:
	# Hopping on one foot: a little wobble of the torso.
	if _torso:
		_torso.rotation.z = sin(Time.get_ticks_msec() * 0.012) * 0.15
	_update_torso(delta)
