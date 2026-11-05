class_name Human
extends Threat
## A person walking through the room. Each footstep is a telegraphed stomp.
## The escalation chain decides the weapons: stomps at first, the swatter
## from stage 2, a newspaper sweep (if carried) and bug spray at stage 4.
##
## Activities: at chosen points on their route people stop and do something
## (see `activities`): cook and do the dishes with their back to the room,
## snack and drop crumbs, sit and read behind a newspaper (only glancing up
## now and then), nap (can't see, barely hears, snores), water the flowers (the
## spray washes your scent off but knocks you back), kneel to tend the
## vegetables (low and close: sharp-eyed nearby), and throw the ball for the
## dog. Anything suspicious interrupts them. A fly pestering them makes them
## flail and swat at the air: for a few seconds they can't see you.

@export var route: PackedVector3Array = []
@export var stride: float = 9.0
@export var step_time: float = 0.8
@export var foot_spacing: float = 3.4
@export var has_swatter: bool = true
@export var has_newspaper: bool = false
@export var has_spray: bool = true
## Exterminator: heavier, louder stomps.
@export var heavy_boots: bool = false
@export var spray_interval: float = 5.0
## Stops on the route: {route index: {"kind": &"cook", "time": 10.0, "face": Vector3}}.
## Kinds: cook, dishes, snack, read, nap, water, kneel, fetch.
@export var activities: Dictionary = {}

const SIT_OFFSET := Vector3(0, -20.5, 10.5)
const KNEEL_OFFSET := Vector3(0, -15.0, 3.0)
const PEEK_EVERY := 5.0
const PEEK_TIME := 1.8
const FLUSTER_TIME := 3.5

## The activity under way (&"" when walking).
var activity: StringName = &""
var flustered := 0.0
var _act: Dictionary = {}
var _act_t := 0.0
var _act_clock := 0.0
var _act_drops := 0
var _peek := 0.0
var _pester_cd := 0.0
var _stream: WaterStream
var _ball: PhysicsProp
var _thrown := false
var _snore_cd := 0.0
var _torso_base := Vector3.ZERO
var _paper: Node3D

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

# Body pose (visual only): hip sockets, leg bone lengths, arm/head joints.
const HIP_X := 3.6
const HIP_Y := 37.0
const BODY_Z := 2.0
const THIGH := 17.5
const SHIN := 17.0
const ANKLE := Vector3(0, 3.6, 2.2)
const SHOULDER_Y := 59.5
var _shoulders: Array[Node3D] = []
var _elbows: Array[Node3D] = []
var _head: Node3D
var _legs: Node3D
var _leg_parts: Array = []
var _breath := 0.0
# Lifelike touches: smooth travel, hip sway, blinking, eyes that lead the head.
const BODY_SMOOTH_TIME := 0.16
var _body_vel := Vector3.ZERO
# Each walking step, the body travels at a steady pace from where it was to
# the middle of the new stance (instead of chasing the feet in bursts).
var _glide_from := Vector3.ZERO
var _glide_to := Vector3.ZERO
var _glide_t := 0.0
var _glide_dur := 0.0
var _sway := 0.0
var _lids: Node3D
var _gaze: Node3D
var _blink_cd := 3.0
var _blink_t := 0.0
var _glance := Vector2.ZERO
var _glance_cd := 2.0
var _snap_look := 0.0
var _last_state: int = AlertState.UNAWARE


func _setup() -> void:
	add_to_group(Phys.GROUP_HUMAN)
	left_foot = get_node_or_null("LeftFoot") as FootHazard
	right_foot = get_node_or_null("RightFoot") as FootHazard
	newspaper = get_node_or_null("Newspaper") as Newspaper
	_torso = get_node_or_null("Torso")
	_paper = get_node_or_null("Torso/ReadingPaper") as Node3D
	if _torso:
		for side in ["L", "R"]:
			var sh := _torso.get_node_or_null("Shoulder" + side) as Node3D
			if sh:
				_shoulders.append(sh)
				_elbows.append(sh.get_node_or_null("Elbow") as Node3D)
		_head = _torso.get_node_or_null("Head") as Node3D
		if _head:
			_lids = _head.get_node_or_null("Lids") as Node3D
			_gaze = _head.get_node_or_null("Gaze") as Node3D
	_legs = get_node_or_null("Legs") as Node3D
	# Posed every frame: ride on the smoothed body (and feet).
	if _torso:
		_torso.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if _legs:
		_legs.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if _legs:
		for side in ["L", "R"]:
			_leg_parts.append([_legs.get_node_or_null("Thigh" + side), _legs.get_node_or_null("Knee" + side),
				_legs.get_node_or_null("Shin" + side)])
	for f in [left_foot, right_foot]:
		if f:
			(f as FootHazard).set_owner_threat(self)
			(f as FootHazard).heavy = heavy_boots
	if newspaper:
		newspaper.owner_threat = self
	_body_pos = global_position
	_plant_feet(global_position, rotation.y)


func _plant_feet(center: Vector3, yaw: float) -> void:
	# Standing somewhere new: no step glide carries over.
	_glide_dur = 0.0
	_body_vel = Vector3.ZERO
	var side := Basis(Vector3.UP, yaw).x * foot_spacing * 0.5
	if left_foot:
		left_foot.plant_at(center - side, yaw)
	if right_foot:
		right_foot.plant_at(center + side, yaw)


func _on_presence_changed(now: bool) -> void:
	end_activity()
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
		_body_vel = Vector3.ZERO
		_glide_dur = 0.0
		reset_physics_interpolation()


func _think(delta: float) -> void:
	_attack_cd -= delta * speed_mult()
	_spray_cd -= delta
	_voice_cd -= delta
	_pester_cd -= delta
	flustered = maxf(flustered - delta, 0.0)
	if activity != &"" and alert.state > AlertState.UNAWARE:
		if activity == &"nap":
			AudioManager.play_at(&"voice_huh", eye_position(), 0.0, 0.8, &"Muffled")
		end_activity()
	match alert.state:
		AlertState.UNAWARE:
			if activity != &"":
				_activity_tick(delta)
			elif flustered <= 0.0:
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
	if _glide_dur > 0.0:
		_glide_t += delta * speed_mult()
		var gk := clampf(_glide_t / _glide_dur, 0.0, 1.0)
		var g := _glide_from.lerp(_glide_to, gk)
		_body_pos = Vector3(g.x, global_position.y, g.z)
		if gk >= 1.0:
			_glide_dur = 0.0
	elif left_foot and right_foot:
		var mid := (left_foot.global_position + right_foot.global_position) * 0.5
		_body_pos = Vector3(mid.x, global_position.y, mid.z)
	# A critically damped follow: the body glides at a steady pace instead of
	# surging with each footfall.
	global_position = smooth_damp(global_position, _body_pos, delta)


func smooth_damp(from: Vector3, to: Vector3, delta: float) -> Vector3:
	var omega := 2.0 / BODY_SMOOTH_TIME
	var x := omega * delta
	var e := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := from - to
	var temp := (_body_vel + omega * change) * delta
	_body_vel = (_body_vel - omega * temp) * e
	return to + (change + temp) * e


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
		if activities.has(_route_i):
			if left_foot and right_foot and (not left_foot.is_planted() or not right_foot.is_planted()):
				return
			start_activity(activities[_route_i])
			_route_i = (_route_i + 1) % route.size()
			return
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
	foot.step_to(land, yaw, cadence * 0.85, true)
	var stance := right_foot if foot == left_foot else left_foot
	_glide_from = _body_pos
	_glide_to = (stance.global_position + land) * 0.5
	_glide_t = 0.0
	_glide_dur = cadence
	_left_next = not _left_next


# --- Searching & attacking ----------------------------------------------------

func _search(delta: float) -> void:
	var target := alert.last_known
	face_towards(target, delta)
	var flat := Vector2(target.x - _body_pos.x, target.z - _body_pos.z).length()
	if flat > 10.0:
		_walk_towards(target, delta, step_time * 0.8)
	elif _attack_cd <= 0.0 and not (PerceptionSystem.player and PerceptionSystem.player.is_spared_by_people() \
			and not PerceptionSystem.alarm_active):
		# Stomp around the spot where the noise came from.
		_attack_cd = config.attack_cooldown * 1.1
		var off := Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
		_stomp(target + off, config.attack_windup * 1.1)


func _attack(delta: float) -> void:
	var p := PerceptionSystem.player
	if p == null:
		return
	var target := p.global_position
	if p.is_spared_by_people() and not PerceptionSystem.alarm_active:
		# A ladybug: they watch it, but nobody swats a ladybug... yet.
		face_towards(target, delta)
		return
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
	_glide_dur = 0.0
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


# --- Body pose (visual) -----------------------------------------------------

func _process(delta: float) -> void:
	if present and is_visible_in_tree():
		pose_body(delta)


## Arms swing against the feet, the head turns to whatever it's after, the
## right arm comes up ready to swat when it has spotted you, and the legs bend
## at the knee to reach each foot.
func pose_body(delta: float) -> void:
	if _torso == null:
		return
	_breath += delta
	var fwd := -global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var swing := 0.0
	if left_foot and right_foot:
		var d := (left_foot.global_position - right_foot.global_position).dot(fwd)
		swing = clampf(d / maxf(stride, 1.0), -1.0, 1.0) * 0.5
	var k := clampf(8.0 * delta, 0.0, 1.0)
	var is_stunned := stun_time > 0.0
	var pose := _activity_pose()
	for i in _shoulders.size():
		var sh := _shoulders[i]
		var arm_x := -swing if i == 0 else swing
		var elbow_x := 0.15 + absf(swing) * 0.35
		if not pose.is_empty() and not is_stunned:
			var arm: Vector2 = pose[1 + i]
			arm_x = arm.x
			elbow_x = arm.y
		elif is_stunned:
			arm_x = 2.5 + sin(_breath * 14.0 + i * 2.0) * 0.35
			elbow_x = 0.4
		elif i == 1 and alert.state == AlertState.ALERT:
			arm_x = 1.9
			elbow_x = 0.9
		elif alert.state == AlertState.SEARCHING:
			arm_x *= 0.5
			elbow_x = 0.5
		sh.rotation.x = lerp_angle(sh.rotation.x, arm_x, k)
		if _elbows[i]:
			_elbows[i].rotation.x = lerp_angle(_elbows[i].rotation.x, elbow_x, k)
	if _head:
		_pose_head(delta)
	var base: Vector3 = pose[0] if not pose.is_empty() else Vector3.ZERO
	_torso_base = _torso_base.lerp(base, clampf(4.0 * delta, 0.0, 1.0))
	# Weight goes onto the standing foot: the hips sway over it as the other
	# swings; standing still, the weight drifts slowly from foot to foot.
	var sway_t := 0.0
	var lk := left_foot.swing_progress() if left_foot else -1.0
	var rk := right_foot.swing_progress() if right_foot else -1.0
	if lk >= 0.0:
		sway_t = sin(PI * lk)
	elif rk >= 0.0:
		sway_t = -sin(PI * rk)
	elif pose.is_empty() and alert.state == AlertState.UNAWARE:
		sway_t = sin(_breath * 0.45) * 0.35
	_sway = lerpf(_sway, sway_t, clampf(6.0 * delta, 0.0, 1.0))
	_torso.position = _torso_base + Vector3(_sway * 0.8, sin(_breath * 1.7) * 0.15 - absf(swing) * 1.2, 0)
	# The shoulders twist against the stride; a slight lean over the stance foot.
	_torso.rotation.y = lerp_angle(_torso.rotation.y, swing * 0.18 if pose.is_empty() else 0.0, k)
	if not is_stunned:
		_torso.rotation.z = lerp_angle(_torso.rotation.z, -_sway * 0.035, k)
	# Breathing lifts the shoulders a touch.
	for sh in _shoulders:
		sh.position.y = SHOULDER_Y + sin(_breath * 1.7) * 0.18
	_pose_legs(fwd)


## Head and eyes: the eyes jump to what they're after first, the head follows.
## Calm people glance around now and then and blink; a sudden noise gets a
## quick double take.
func _pose_head(delta: float) -> void:
	if alert.state != _last_state:
		if _last_state == AlertState.UNAWARE and alert.state > AlertState.UNAWARE:
			_snap_look = 0.5
		_last_state = alert.state
	_snap_look = maxf(_snap_look - delta, 0.0)
	var yaw_t := 0.0
	var pitch_t := -0.12
	var calm := alert.state == AlertState.UNAWARE and activity == &"" and flustered <= 0.0 and stun_time <= 0.0
	if alert.state > AlertState.UNAWARE and alert.has_target:
		var local := global_transform.affine_inverse() * alert.last_known
		var from_head := local - Vector3(0, 70, BODY_Z) - _torso.position
		yaw_t = clampf(atan2(-from_head.x, -from_head.z), -0.9, 0.9)
		pitch_t = clampf(atan2(from_head.y, Vector2(from_head.x, from_head.z).length()), -0.8, 0.3)
	elif activity == &"read":
		pitch_t = -0.3 if _peek <= 0.0 else 0.0
		yaw_t = sin(_breath * 2.5) * 0.8 if _peek > 0.0 else 0.0
	elif activity == &"nap":
		pitch_t = -0.65
		yaw_t = 0.25
	elif activity in [&"cook", &"dishes", &"kneel", &"water"]:
		pitch_t = -0.5 + _glance.y * 0.3
		yaw_t = _glance.x * 0.3
	elif flustered > 0.0:
		yaw_t = sin(_breath * 9.0) * 0.7
	elif calm:
		yaw_t = _glance.x
		pitch_t = -0.12 + _glance.y
	# Glances: every few seconds look somewhere else, or back ahead.
	_glance_cd -= delta
	if _glance_cd <= 0.0:
		_glance_cd = randf_range(1.6, 4.0)
		# Look somewhere, then usually back ahead (sometimes straight on to
		# another spot).
		if _glance == Vector2.ZERO or randf() < 0.35:
			var side := -signf(_glance.x) if _glance.x != 0.0 else (1.0 if randf() < 0.5 else -1.0)
			_glance = Vector2(side * randf_range(0.3, 0.8), randf_range(-0.35, 0.08))
		else:
			_glance = Vector2.ZERO
	var rate := 14.0 if _snap_look > 0.0 else 4.5
	_head.rotation.y = lerp_angle(_head.rotation.y, yaw_t, clampf(rate * delta, 0.0, 1.0))
	_head.rotation.x = lerp_angle(_head.rotation.x, pitch_t, clampf(rate * delta, 0.0, 1.0))
	if _gaze:
		# Eyes lead: they're already where the head is still turning to.
		var lead := Vector2(wrapf(yaw_t - _head.rotation.y, -PI, PI), pitch_t - _head.rotation.x)
		var eye := Vector3(clampf(-lead.x * 0.5, -0.22, 0.22), clampf(lead.y * 0.4, -0.16, 0.16), 0)
		_gaze.position = _gaze.position.lerp(eye, clampf(24.0 * delta, 0.0, 1.0))
	if _lids:
		var closed := activity == &"nap" or stun_time > 0.0
		_blink_cd -= delta
		if _blink_cd <= 0.0:
			_blink_t = 0.13
			# Sometimes a double blink.
			_blink_cd = 0.25 if randf() < 0.15 else randf_range(2.0, 5.5)
		_blink_t = maxf(_blink_t - delta, 0.0)
		_lids.visible = closed or _blink_t > 0.0


func _pose_legs(fwd: Vector3) -> void:
	if _legs == null or _leg_parts.size() < 2:
		return
	var feet := [left_foot, right_foot]
	var body_xf := get_global_transform_interpolated()
	for i in 2:
		var f := feet[i] as FootHazard
		var parts: Array = _leg_parts[i]
		if f == null or parts[0] == null or parts[2] == null:
			continue
		var hip := body_xf * (Vector3((-1.0 if i == 0 else 1.0) * HIP_X, HIP_Y, BODY_Z) + _torso.position)
		var ankle := f.get_global_transform_interpolated() * ANKLE
		var knee := knee_point(hip, ankle, fwd)
		_place_bone(parts[0] as Node3D, hip, knee, 19.5)
		if parts[1]:
			(parts[1] as Node3D).global_position = knee
		_place_bone(parts[2] as Node3D, knee, ankle, 19.0)


## Two-bone IK: where the knee goes for a hip and an ankle (bends forward).
static func knee_point(hip: Vector3, ankle: Vector3, fwd: Vector3) -> Vector3:
	var d := ankle - hip
	var dist := clampf(d.length(), 0.5, THIGH + SHIN - 0.01)
	var dn := d.normalized() if d.length() > 0.001 else Vector3.DOWN
	var a := (THIGH * THIGH - SHIN * SHIN + dist * dist) / (2.0 * dist)
	var h := sqrt(maxf(THIGH * THIGH - a * a, 0.0))
	var bend := fwd - dn * fwd.dot(dn)
	if bend.length() < 0.01:
		bend = Vector3.FORWARD
	return hip + dn * a + bend.normalized() * h


## Stretches a Y-axis mesh (of length `mesh_len`) from a to b.
static func _place_bone(mi: Node3D, a: Vector3, b: Vector3, mesh_len: float) -> void:
	var y := b - a
	var length := y.length()
	if length < 0.01:
		return
	y /= length
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	var z := x.cross(y)
	mi.global_transform = Transform3D(Basis(x, y * (length / mesh_len), z), (a + b) * 0.5)


# --- Activities -------------------------------------------------------------------

func start_activity(act: Dictionary) -> void:
	_act = act
	activity = StringName(act.get("kind", ""))
	_act_t = float(act.get("time", 8.0))
	_act_clock = 0.0
	_act_drops = 0
	_peek = 0.0
	_thrown = false
	_snore_cd = 1.5
	if activity in [&"read", &"nap", &"kneel"] and act.has("face"):
		# Turn to sit down / kneel facing the right way.
		var to: Vector3 = act["face"] - _body_pos
		rotation.y = atan2(-to.x, -to.z)
	_plant_feet(_body_pos, rotation.y)
	if _paper:
		_paper.visible = activity == &"read"
	match activity:
		&"water":
			var face: Vector3 = _act.get("face", global_position)
			var from := global_transform * Vector3(4, 48, -14)
			var to := Vector3(face.x, 0.0, face.z)
			_stream = WaterStream.make(from, to)
			get_parent().add_child(_stream)
			_stream.global_position = to
			AudioManager.play_at(&"sprinkler", to, -6.0)
		&"fetch":
			_ball = _nearest_ball(60.0)


func end_activity() -> void:
	if activity == &"":
		return
	activity = &""
	_act = {}
	if _paper:
		_paper.visible = false
	if _stream and is_instance_valid(_stream):
		_stream.queue_free()
	_stream = null
	_ball = null


func is_sitting() -> bool:
	return activity in [&"read", &"nap"]


## Reading with the paper up: only what's right in front of them, until they
## glance over it.
func is_reading_blind() -> bool:
	return activity == &"read" and _peek <= 0.0


func _activity_tick(delta: float) -> void:
	_act_t -= delta
	_act_clock += delta
	var face: Vector3 = _act.get("face", global_position - global_basis.z * 10.0)
	if not is_sitting() and activity != &"kneel":
		face_towards(face, delta)
	match activity:
		&"cook", &"snack":
			# Crumbs fall from the pan / the plate: grab them under their feet.
			if _act_clock > 2.5 * (_act_drops + 1) and _act_drops < 2 and Level.current:
				_act_drops += 1
				# Behind and beside them (in front is the stove or the table), on
				# open floor: try a few spots.
				for attempt in 8:
					var spot := global_transform * Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(3.0, 8.0))
					spot.y = global_position.y + 0.6
					if Level.current.spawn_crumb(spot):
						break
		&"read":
			_peek -= delta
			if fmod(_act_clock, PEEK_EVERY) > PEEK_EVERY - delta * 1.5 and _peek <= 0.0:
				_peek = PEEK_TIME
		&"nap":
			_snore_cd -= delta
			if _snore_cd <= 0.0:
				_snore_cd = 2.6
				AudioManager.play_at(&"snore", eye_position(), -6.0, randf_range(0.9, 1.05), &"Muffled")
		&"fetch":
			if not _thrown and _act_clock > 1.0:
				_thrown = true
				_throw_ball()
	if _act_t <= 0.0:
		end_activity()


func _nearest_ball(radius: float) -> PhysicsProp:
	var best: PhysicsProp = null
	var best_d := radius
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var prop := n as PhysicsProp
		if prop and String(prop.name).begins_with("Ball"):
			var d := prop.global_position.distance_to(global_position)
			if d < best_d:
				best = prop
				best_d = d
	return best


func _throw_ball() -> void:
	if _ball == null or not is_instance_valid(_ball):
		return
	var dog: Pet = null
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PET):
		var pet := n as Pet
		if pet and pet.present and not pet.sleeping and get_parent().is_ancestor_of(pet):
			dog = pet
			break
	var hand := global_transform * Vector3(8, 50, -8)
	_ball.freeze = false
	_ball.global_position = hand
	_ball.linear_velocity = Vector3.ZERO
	# A gentle lob that rolls to a stop, so the dog can catch up with it.
	_ball.linear_damp = 1.2
	_ball.angular_damp = 2.0
	# Aim for open lawn: a ball behind a hedge or under the shed is no game.
	var dir := (-global_basis.z).rotated(Vector3.UP, randf_range(-0.6, 0.6))
	for attempt in 8:
		var tryd := (-global_basis.z).rotated(Vector3.UP, randf_range(-0.6, 0.6) if attempt < 6 else (attempt - 6.5) * 0.4)
		tryd.y = 0.0
		tryd = tryd.normalized()
		if _clear_throw(tryd):
			dir = tryd
			break
	dir.y = 0.0
	_ball.apply_central_impulse((dir.normalized() * 13.0 + Vector3.UP * 4.0) * _ball.mass)
	_ball.mark_played(4.0)
	AudioManager.play_at(&"voice_call", eye_position(), 0.0, 1.2, &"Muffled")
	if dog:
		dog.fetch(_ball, self)


## Open floor all along where a thrown ball would roll.
func _clear_throw(dir: Vector3) -> bool:
	var lvl := Level.current
	if lvl == null or not is_instance_valid(lvl):
		return true
	var ground := Vector3(global_position.x, global_position.y, global_position.z)
	for d in [8.0, 12.0, 16.0, 20.0]:
		if not lvl.is_open_floor(ground + dir * d + Vector3.UP * 0.3):
			return false
	return true


## The head is lower when sitting or kneeling.
func eye_position() -> Vector3:
	var off := _torso.position if _torso else Vector3.ZERO
	return global_transform * (Vector3(0, config.eye_height, 0) + off)


func can_see(p: BugBase) -> bool:
	if flustered > 0.0 or activity == &"nap":
		return false
	if is_reading_blind():
		return global_position.distance_to(p.global_position) < 10.0 and super.can_see(p)
	if activity == &"kneel" and Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length() < 14.0:
		# Kneeling close to the ground: anything near is easy to spot, wherever
		# they're looking.
		if not p.is_hidden_safe() and PerceptionSystem.visibility >= config.min_visibility * 0.5 and has_line_of_sight(p):
			return true
	return super.can_see(p)


func _hearing_mult() -> float:
	return 0.4 if activity == &"nap" else 1.0


func _on_dazzled() -> void:
	end_activity()
	AudioManager.play_at(&"voice_huh", eye_position(), 2.0, 1.25, &"Muffled")


## A stink cloud: they cough and splutter, eyes watering - can't see, and
## stop what they're doing.
func stink(_from: Vector3, seconds: float) -> bool:
	if not present or stun_time > 0.0:
		return false
	end_activity()
	stun(seconds, true)
	blind_time = maxf(blind_time, seconds + 1.0)
	AudioManager.play_at(&"voice_huh", eye_position(), 3.0, 1.45, &"Muffled")
	return true


## A fly buzzing at their face: they flail and swat at the air, and can't see
## a thing for a few seconds.
func pestered(by: BugBase) -> bool:
	if _pester_cd > 0.0 or stun_time > 0.0:
		return false
	_pester_cd = 5.0
	end_activity()
	flustered = FLUSTER_TIME
	AudioManager.play_at(&"voice_huh", eye_position(), 2.0, 1.3, &"Muffled")
	var at := by.global_position
	if has_swatter and Level.current and Level.current.swatter_pool:
		var sw := Level.current.swatter_pool.acquire() as Swatter
		sw.strike(at, 0.75, self, Level.current.swatter_pool)
	else:
		get_tree().create_timer(0.6, false).timeout.connect(func() -> void:
			if is_inside_tree():
				Hazard.apply_strike(at, 2.5, &"swatted", self, false))
	return true


## Pose offsets and arm targets for the current activity: [torso offset,
## left arm (shoulder, elbow), right arm (shoulder, elbow)] or empty.
func _activity_pose() -> Array:
	var t := _act_clock
	if flustered > 0.0:
		var wave := sin(_breath * 16.0) * 0.5
		return [Vector3.ZERO, Vector2(2.2 + wave, 1.0), Vector2(2.2 - wave, 1.0)]
	match activity:
		&"cook", &"dishes":
			var stir := sin(t * 6.0) * 0.35
			return [Vector3.ZERO, Vector2(0.8, 1.2), Vector2(0.9, 1.3 + stir)]
		&"snack":
			var bite := 2.3 if fmod(t, 2.4) < 0.7 else 1.0
			return [Vector3.ZERO, Vector2(0.4, 0.6), Vector2(0.6, bite)]
		&"read":
			if _peek > 0.0:
				return [SIT_OFFSET, Vector2(0.6, 1.0), Vector2(0.6, 1.0)]
			return [SIT_OFFSET, Vector2(1.35, 1.5), Vector2(1.35, 1.5)]
		&"nap":
			return [SIT_OFFSET, Vector2(0.15, 0.6), Vector2(0.15, 0.6)]
		&"water":
			return [Vector3.ZERO, Vector2(0.2, 0.3), Vector2(1.0, 0.3)]
		&"kneel":
			return [KNEEL_OFFSET, Vector2(0.9, 0.6), Vector2(1.0, 0.7 + sin(t * 3.0) * 0.3)]
		&"fetch":
			var arm := -0.9 if t < 1.0 else 2.4
			return [Vector3.ZERO, Vector2(0.2, 0.3), Vector2(arm, 0.4)]
	return []
