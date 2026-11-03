class_name Pet
extends Threat
## Cat, dog or puppy. Patrols (or naps on its routine), investigates noise,
## chases with NavigationAgent3D pathing, pounces with a telegraph, then gives
## up. Dogs follow your scent trail and bark (which alerts the humans); cats see
## sharply and leap onto perches, shoving loose props off the edge.
##
## Moods: CALM, PLAY (batting the toy ball, zoomies, play-pouncing, chasing
## its tail, fetching - distracted, it sees and hears about half as well),
## ALERT (freezes and stares, ears up, tail stiff; the cat stalks low) and
## SLEEP. Animals get sharper in later rooms (LevelConfig.animal_awareness)
## and as the house escalates. A low-flying fly gets snapped at.

enum Pounce { NONE, WINDUP, LEAP, RECOVER }
enum Mood { CALM, PLAY, ALERT, SLEEP }

## Play behaviours by kind of animal.
const PLAY_SEE_MULT := 0.5
const PLAY_TIME := Vector2(5.0, 9.0)
const PLAY_GAP := Vector2(6.0, 14.0)
const TOY_RANGE := 40.0
const SNAP_REACH := 12.0

@export var waypoints: PackedVector3Array = []
## Routine events during which the pet naps (blind, nearly deaf).
@export var nap_events: PackedStringArray = []
@export var pounce_height: float = 5.0
@export var leap_time: float = 0.35
@export var barks: bool = false
@export var uses_perches: bool = false

var boss_speed_mult := 1.0
var attack_cooldown_mult := 1.0
var sleeping := false
var _woken := 0.0
var _wp_i := 0
var _idle := 0.0
var _attack_cd := 0.0
var _pounce := Pounce.NONE
var _pounce_t := 0.0
var _pounce_from := Vector3.ZERO
var _pounce_to := Vector3.ZERO
var _scent_stamp := -1
var _scent_target := Vector3.INF
var _sniff_target := Vector3.INF
var _sniff_timer := 0.0
var _bark_cd := 0.0
var _perch: CatPerch = null
var _perch_state := 0
var _perch_t := 0.0
var _perch_from := Vector3.ZERO
var _agent: NavigationAgent3D
var _ring: MeshInstance3D
var _visual: Node3D

var mood: int = Mood.CALM
## Current play: &"toy", &"zoomies", &"pounce", &"tail", &"fetch", &"snap" or &"".
var play: StringName = &""
var _play_t := 0.0
var _play_cd := 8.0
var _play_point := Vector3.ZERO
var _play_angle := 0.0
var _toy: PhysicsProp = null
var _bat_cd := 0.0
var _fetch_by: Node3D = null
var _carrying := false
var _snaps := 0
var _pester_cd := 0.0
var _snap_cd := 0.0
var _harmless_pounce := false
# Body pose (visual): pivots and a running clock.
var _head: Node3D
var _tail: Node3D
var _tail_tip: Node3D
var _ears: Array[Node3D] = []
var _legs: Array[Node3D] = []
var _tongue: Node3D
var _pose_t := 0.0
var _gait := 0.0


func _setup() -> void:
	add_to_group(Phys.GROUP_PET)
	_agent = get_node_or_null("Agent") as NavigationAgent3D
	_visual = get_node_or_null("Visual")
	_ring = Fx.make_ring(Color(1.0, 0.25, 0.1, 0.85))
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)
	_play_cd = randf_range(PLAY_GAP.x * 0.5, PLAY_GAP.y)
	if _visual:
		_head = _visual.get_node_or_null("Head") as Node3D
		_tail = _visual.get_node_or_null("Tail") as Node3D
		if _tail:
			_tail_tip = _tail.get_node_or_null("Tip") as Node3D
		if _head:
			for e in ["EarL", "EarR"]:
				var ear := _head.get_node_or_null(e) as Node3D
				if ear:
					_ears.append(ear)
			_tongue = _head.get_node_or_null("Tongue") as Node3D
		for l in ["LegFL", "LegFR", "LegBL", "LegBR"]:
			var leg := _visual.get_node_or_null(l) as Node3D
			if leg:
				_legs.append(leg)


func wake_up() -> void:
	_woken = 30.0
	sleeping = false


func _idle_icon() -> String:
	if sleeping:
		return "z"
	return "~" if play != &"" else ""


## Busy playing, an animal ignores the thumps of its own toy (and other
## noises that aren't you).
func hear(pos: Vector3, loudness: float, from_player: bool) -> void:
	if is_distracted() and not from_player:
		return
	super.hear(pos, loudness, from_player)


func _hearing_mult() -> float:
	if sleeping:
		return 0.3
	return PLAY_SEE_MULT if is_distracted() else 1.0


## Sharper in later rooms, and sharper again as the household escalates.
func effective_awareness() -> float:
	return awareness * (1.0 + 0.1 * PerceptionSystem.escalation_stage)


func perception_mult() -> float:
	return PLAY_SEE_MULT if is_distracted() else 1.0


## Busy playing (not snapping at a fly, which is very much paying attention).
func is_distracted() -> bool:
	return play != &"" and play != &"snap"


func can_see(p: BugBase) -> bool:
	if sleeping:
		return false
	return super.can_see(p)


func _think(delta: float) -> void:
	_attack_cd -= delta
	_bark_cd -= delta
	_pester_cd -= delta
	_snap_cd -= delta
	_woken = maxf(_woken - delta, 0.0)
	sleeping = _woken <= 0.0 and HouseClock.any_active(nap_events) and alert.state <= AlertState.SUSPICIOUS
	if sleeping:
		mood = Mood.SLEEP
		stop_playing()
	elif alert.state >= AlertState.SUSPICIOUS and play != &"snap":
		mood = Mood.ALERT
		stop_playing()
	else:
		mood = Mood.PLAY if play != &"" else Mood.CALM
	if _pounce != Pounce.NONE:
		_pounce_tick(delta)
		return
	if play != &"":
		_play_tick(delta)
		return
	if mood == Mood.CALM:
		_play_cd -= delta / maxf(effective_awareness(), 0.5)
		if _play_cd <= 0.0:
			start_playing()
			if play != &"":
				return
	if _perch_state != 0:
		_perch_tick(delta)
		return
	match alert.state:
		AlertState.UNAWARE:
			if sleeping:
				_stop(delta)
			else:
				_patrol(delta)
		AlertState.SUSPICIOUS:
			_stop(delta)
			face_towards(alert.last_known, delta)
		AlertState.SEARCHING:
			_search(delta)
		AlertState.ALERT:
			_chase(delta)


# --- Movement ----------------------------------------------------------------

func _move_to(target: Vector3, speed: float, delta: float) -> void:
	var next := target
	if _agent:
		_agent.target_position = target
		if not _agent.is_navigation_finished():
			next = _agent.get_next_path_position()
	var to := next - global_position
	to.y = 0.0
	var v := Vector3.ZERO
	if to.length() > 0.3:
		v = to.normalized() * speed * speed_mult() * boss_speed_mult
		face_towards(global_position + to, delta, config.turn_speed * 2.0)
	velocity.x = v.x
	velocity.z = v.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 30.0 * delta
	move_and_slide()


func _stop(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - 30.0 * delta
	move_and_slide()


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _patrol(delta: float) -> void:
	if waypoints.is_empty():
		_stop(delta)
		return
	if _idle > 0.0:
		_idle -= delta
		_stop(delta)
		return
	var target := waypoints[_wp_i]
	if _flat_dist(target, global_position) < 2.0:
		_wp_i = (_wp_i + 1) % waypoints.size()
		_idle = randf_range(0.5, 2.5)
		return
	_move_to(target, config.patrol_speed, delta)


func _search(delta: float) -> void:
	var target := alert.last_known
	if config.scent_tracking and not alert.target_is_lure:
		var idx := PerceptionSystem.scent.next_point(global_position, config.scent_radius, _scent_stamp)
		if idx < 0 and _scent_stamp < 0:
			idx = PerceptionSystem.scent.strongest_near(global_position, config.scent_radius)
		if idx >= 0:
			_scent_stamp = PerceptionSystem.scent.stamps[idx]
			_scent_target = PerceptionSystem.scent.positions[idx]
		if _scent_target != Vector3.INF:
			target = _scent_target
			if _flat_dist(target, global_position) < 1.5:
				_scent_target = Vector3.INF
	if uses_perches and target.y > global_position.y + 4.0 and _try_perch(target):
		return
	if _flat_dist(target, global_position) > 2.5:
		_move_to(target, config.search_speed, delta)
		return
	# Arrived: sniff around nearby spots.
	_sniff_timer -= delta
	if _sniff_target == Vector3.INF or _sniff_timer <= 0.0 or _flat_dist(_sniff_target, global_position) < 1.5:
		_sniff_timer = 1.5
		_sniff_target = target + Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0))
	_move_to(_sniff_target, config.patrol_speed, delta)


func _chase(delta: float) -> void:
	var p := PerceptionSystem.player
	if p == null:
		return
	var target := p.global_position
	# A fly just out of reach overhead: leap and snap at it.
	if p is Fly and (p as Fly).flying and _snap_cd <= 0.0 and _can_snap(target):
		_start_snap(target)
		return
	if barks and _bark_cd <= 0.0:
		_bark_cd = 4.0
		AudioManager.play_at(&"bark", eye_position(), 2.0)
		PerceptionSystem.emit_world_noise(global_position, 1.5)
		for h in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
			(h as Threat).force_alert(AlertState.SEARCHING, target)
	if uses_perches and target.y > global_position.y + 4.0 and _try_perch(target):
		return
	var d := _flat_dist(target, global_position)
	if d <= config.attack_range and _attack_cd <= 0.0 and absf(target.y - global_position.y) < pounce_height + 2.0:
		_start_pounce(target)
		return
	_move_to(target, config.chase_speed, delta)


# --- Pounce -----------------------------------------------------------------

func _start_pounce(target: Vector3, harmless: bool = false) -> void:
	_harmless_pounce = harmless
	_pounce = Pounce.WINDUP
	_pounce_t = 0.0
	_pounce_to = target
	velocity = Vector3.ZERO
	if harmless:
		return
	AudioManager.play_at(&"hiss" if not barks else &"growl", eye_position(), 0.0)
	PerceptionSystem.warn_strike(target, config.attack_windup + leap_time, config.attack_radius)


func _pounce_tick(delta: float) -> void:
	_pounce_t += delta * speed_mult() * boss_speed_mult
	match _pounce:
		Pounce.WINDUP:
			face_towards(_pounce_to, delta, 12.0)
			var k := _pounce_t / config.attack_windup
			if not _harmless_pounce:
				_show_ring(_pounce_to, config.attack_radius, k)
			if _visual:
				_visual.scale.y = lerpf(1.0, 0.7, minf(k, 1.0))
			if _pounce_t >= config.attack_windup:
				_pounce = Pounce.LEAP
				_pounce_t = 0.0
				_pounce_from = global_position
		Pounce.LEAP:
			var k2 := minf(_pounce_t / leap_time, 1.0)
			var flat := _pounce_from.lerp(_pounce_to, k2)
			flat.y = lerpf(_pounce_from.y, _pounce_to.y, k2) + sin(k2 * PI) * pounce_height
			global_position = flat
			if _visual:
				_visual.scale.y = 1.0
			if k2 >= 1.0:
				_ring.visible = false
				if _harmless_pounce:
					AudioManager.play_at(&"thud", _pounce_to, -12.0, 1.8)
				else:
					Hazard.apply_strike(_pounce_to, config.attack_radius, &"pounced", self, true)
					Feedback.impact_at(_pounce_to, 0.6)
					AudioManager.play_at(&"thud", _pounce_to, -4.0, 1.4)
				_pounce = Pounce.RECOVER
				_pounce_t = 0.0
		Pounce.RECOVER:
			# Land back on the floor after a leap at something in the air.
			if global_position.y > _pounce_from.y + 0.2:
				global_position.y = move_toward(global_position.y, _pounce_from.y, 40.0 * delta)
			else:
				_stop(delta)
			if _pounce_t > 0.6:
				_pounce = Pounce.NONE
				if not _harmless_pounce:
					_attack_cd = config.attack_cooldown * attack_cooldown_mult


func _show_ring(pos: Vector3, radius: float, progress: float) -> void:
	_ring.visible = true
	var r := radius * lerpf(2.0, 1.0, clampf(progress, 0.0, 1.0))
	_ring.global_transform = Transform3D(Basis.from_scale(Vector3(r, 0.15, r)), pos + Vector3.UP * 0.1)


# --- Perches (cat) ------------------------------------------------------------

func _try_perch(target: Vector3) -> bool:
	var best: CatPerch = null
	var best_d := 18.0
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PERCH):
		var perch := n as CatPerch
		if perch:
			var d := perch.top_position().distance_to(target)
			if d < best_d:
				best = perch
				best_d = d
	if best == null:
		return false
	_perch = best
	_perch_state = 1
	return true


func _perch_tick(delta: float) -> void:
	match _perch_state:
		1:
			# Walk to the base of the perch.
			if _flat_dist(_perch.global_position, global_position) > 2.5:
				_move_to(_perch.global_position, config.search_speed, delta)
			else:
				_perch_state = 2
				_perch_t = 0.0
				_perch_from = global_position
		2:
			_perch_t += delta
			var k := minf(_perch_t / 0.5, 1.0)
			var top := _perch.top_position()
			var pos := _perch_from.lerp(top, k)
			pos.y += sin(k * PI) * 4.0
			global_position = pos
			if k >= 1.0:
				var n := _perch.knock_props(global_position)
				if n > 0:
					AudioManager.play_at(&"meow", eye_position())
				_perch_state = 3
				_perch_t = 0.0
		3:
			_perch_t += delta
			face_towards(alert.last_known, delta)
			if _perch_t > 2.5:
				_perch_state = 4
				_perch_t = 0.0
				_perch_from = global_position
		4:
			_perch_t += delta
			var k2 := minf(_perch_t / 0.5, 1.0)
			var down := _perch.global_position
			var pos2 := _perch_from.lerp(down, k2)
			pos2.y += sin(k2 * PI) * 3.0
			global_position = pos2
			if k2 >= 1.0:
				_perch_state = 0
				_perch = null


func _on_stunned() -> void:
	stop_playing()
	_pounce = Pounce.NONE
	_ring.visible = false
	if _perch_state == 2 or _perch_state == 4:
		_perch_state = 0
	AudioManager.play_at(&"yelp" if barks else &"hiss", eye_position())


func _stunned_tick(delta: float) -> void:
	_stop(delta)


# --- Play -----------------------------------------------------------------------

func start_playing(kind: StringName = &"") -> void:
	if kind == &"":
		var options: Array[StringName] = []
		_toy = _nearest_toy()
		if _toy:
			options.append(&"toy")
			options.append(&"toy")
		if barks:
			options.append(&"zoomies")
			if is_puppy():
				options.append(&"tail")
		else:
			options.append(&"pounce")
		kind = options.pick_random()
	play = kind
	_play_t = randf_range(PLAY_TIME.x, PLAY_TIME.y)
	_play_point = global_position
	_play_angle = randf() * TAU
	_bat_cd = 0.0
	if kind == &"toy" and _toy == null:
		_toy = _nearest_toy()
		if _toy == null:
			play = &""
			return
	if barks and kind != &"snap":
		AudioManager.play_at(&"bark", eye_position(), -8.0, 1.3)


func stop_playing() -> void:
	if play == &"":
		return
	if _carrying and _toy:
		_toy.freeze = false
	_carrying = false
	play = &""
	_play_cd = randf_range(PLAY_GAP.x, PLAY_GAP.y)


func is_puppy() -> bool:
	return name.begins_with("Puppy")


## Someone threw a ball: run after it and bring it back to them.
func fetch(ball: PhysicsProp, thrower: Node3D) -> void:
	if sleeping or alert.state > AlertState.SUSPICIOUS:
		return
	if alert.state == AlertState.SUSPICIOUS:
		if not alert.target_is_lure:
			return
		# Only sniffing at a noise: the ball wins.
		alert.reset()
	start_playing(&"fetch")
	_toy = ball
	_fetch_by = thrower
	_carrying = false
	_play_t = 14.0


func _nearest_toy() -> PhysicsProp:
	var best: PhysicsProp = null
	var best_d := TOY_RANGE
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var prop := n as PhysicsProp
		if prop and String(prop.name).begins_with("Ball") and prop.is_inside_tree():
			var d := _flat_dist(prop.global_position, global_position)
			if d < best_d:
				best = prop
				best_d = d
	return best


func _play_tick(delta: float) -> void:
	_play_t -= delta
	_bat_cd -= delta
	if _play_t <= 0.0:
		stop_playing()
		_stop(delta)
		return
	match play:
		&"toy":
			if _toy == null or not is_instance_valid(_toy):
				stop_playing()
				return
			var to := _toy.global_position
			if _flat_dist(to, global_position) > 3.0 + 2.0 * scale.x:
				_move_to(to, config.search_speed * 1.1, delta)
			else:
				_stop(delta)
				face_towards(to, delta, 8.0)
				if _bat_cd <= 0.0:
					# Bat / nose the ball along and go after it again.
					_bat_cd = randf_range(1.0, 2.0)
					var dir := Vector3(to.x - global_position.x, 0, to.z - global_position.z).normalized()
					dir = dir.rotated(Vector3.UP, randf_range(-0.8, 0.8))
					_toy.freeze = false
					_toy.apply_central_impulse((dir * 6.0 + Vector3.UP * 2.0) * _toy.mass)
					_toy.mark_played()
					AudioManager.play_at(&"thud", to, -14.0, 1.6)
		&"zoomies":
			_play_angle += delta * 2.2
			var p := _play_point + Vector3(cos(_play_angle), 0, sin(_play_angle)) * 9.0
			_move_to(p, config.chase_speed * 0.9, delta)
		&"tail":
			_stop(delta)
			rotation.y += delta * 7.0
		&"pounce":
			if _bat_cd <= 0.0:
				_bat_cd = randf_range(1.6, 2.6)
				var spot := global_position - global_basis.z * randf_range(4.0, 7.0)
				spot += global_basis.x * randf_range(-3.0, 3.0)
				_start_pounce(spot, true)
			else:
				_stop(delta)
		&"fetch":
			_fetch_tick(delta)
		&"snap":
			var fly := PerceptionSystem.player as Fly
			if fly == null or _snaps >= 2 or not fly.flying:
				stop_playing()
				return
			face_towards(fly.global_position, delta, 10.0)
			if _snap_cd <= 0.0 and _can_snap(fly.global_position):
				_snaps += 1
				_start_snap(fly.global_position)
			else:
				_move_to(fly.global_position, config.search_speed, delta)


func _fetch_tick(delta: float) -> void:
	if _toy == null or not is_instance_valid(_toy):
		stop_playing()
		return
	if not _carrying:
		if _flat_dist(_toy.global_position, global_position) > 3.0 * scale.x + 2.0:
			_move_to(_toy.global_position, config.chase_speed, delta)
		else:
			_carrying = true
			_toy.freeze = true
	else:
		var home := _fetch_by.global_position if _fetch_by and is_instance_valid(_fetch_by) else _play_point
		if _flat_dist(home, global_position) > 9.0:
			_move_to(home, config.search_speed, delta)
		else:
			_carrying = false
			_toy.freeze = false
			stop_playing()
			return
		if _head:
			_toy.global_position = _head.global_transform * Vector3(0, -1.2, -3.4)


## How far up a pet can snap at a flier.
func _can_snap(target: Vector3) -> bool:
	var up := target.y - global_position.y
	return up > 1.0 and up < SNAP_REACH * (0.7 if barks else 1.0) and _flat_dist(target, global_position) < config.attack_range


func _start_snap(target: Vector3) -> void:
	_snap_cd = 2.2
	_start_pounce(target)


## A fly buzzing around its head: it gets playful and snaps at the fly a
## couple of times (dangerous!), then loses interest.
func pestered(_by: BugBase) -> bool:
	if _pester_cd > 0.0 or stun_time > 0.0 or sleeping:
		return false
	_pester_cd = 5.0
	stop_playing()
	play = &"snap"
	_snaps = 0
	_play_t = 4.0
	AudioManager.play_at(&"meow" if not barks else &"bark", eye_position(), -2.0, 1.4)
	return true


# --- Body pose (visual) ---------------------------------------------------------

func _process(delta: float) -> void:
	if present and is_visible_in_tree():
		pose_body(delta)


## Walk cycle, tail, ears, head and posture from mood and motion.
func pose_body(delta: float) -> void:
	if _visual == null:
		return
	_pose_t += delta
	var k := clampf(10.0 * delta, 0.0, 1.0)
	var speed := Vector2(velocity.x, velocity.z).length()
	var moving := clampf(speed / 4.0, 0.0, 1.0)
	_gait += delta * (4.0 + speed * 0.7) * moving
	var lying := mood == Mood.SLEEP
	var stalking := mood == Mood.ALERT and not barks and alert.state == AlertState.SEARCHING
	var crouch := 0.0
	if lying:
		crouch = 0.45
	elif stalking or _pounce == Pounce.WINDUP:
		crouch = 0.25
	_visual.position.y = lerpf(_visual.position.y, -crouch * 6.0 * scale.x, k)
	# Play bow at the start of a play session.
	var bow := 0.25 if play != &"" and play != &"snap" and fmod(_pose_t, 3.0) < 0.6 and speed < 1.0 else 0.0
	_visual.rotation.x = lerp_angle(_visual.rotation.x, bow, k)
	for i in _legs.size():
		var leg := _legs[i]
		var front := bool(leg.get_meta(&"front"))
		var phase := _gait + (PI if i in [1, 2] else 0.0)
		var swing := sin(phase) * 0.6 * moving
		var fold := 1.3 if lying else crouch * 2.0
		leg.rotation.x = lerp_angle(leg.rotation.x, swing + (fold if front else -fold), k)
		var knee := leg.get_node_or_null("Knee") as Node3D
		if knee:
			var bend := maxf(0.0, -sin(phase)) * 0.9 * moving + (1.4 if lying else crouch * 2.4)
			knee.rotation.x = lerp_angle(knee.rotation.x, -bend if front else bend, k)
	if _tail:
		var tx := -0.7 if barks else -0.5
		var ty := 0.0
		var tip := 0.0
		match mood:
			Mood.PLAY:
				tx = -0.9
				ty = sin(_pose_t * (18.0 if barks else 9.0)) * (0.7 if barks else 0.35)
			Mood.ALERT:
				tx = -1.2 if barks else (0.15 if stalking else -0.9)
				ty = sin(_pose_t * (10.0 if barks else 4.5)) * (0.12 if barks else 0.45)
				tip = sin(_pose_t * 6.0) * 0.5 if not barks else 0.0
			Mood.SLEEP:
				tx = 0.9
				ty = 0.9
			_:
				ty = sin(_pose_t * (6.0 if barks else 1.6)) * (0.3 if barks else 0.25)
				tip = sin(_pose_t * 1.6 + 1.0) * 0.4
		_tail.rotation = _tail.rotation.lerp(Vector3(tx, ty, 0), k)
		if _tail_tip:
			_tail_tip.rotation.x = lerp_angle(_tail_tip.rotation.x, (-0.6 if not barks else 0.0) + tip, k)
	for ear in _ears:
		var side := float(ear.get_meta(&"side"))
		var ex := 0.0
		var ez := 0.0
		if _pounce == Pounce.WINDUP or (not barks and mood == Mood.ALERT and alert.state == AlertState.ALERT):
			ex = 0.5
			ez = side * (-0.8 if not barks else -0.3)
		elif mood == Mood.ALERT:
			ex = -0.25
			ez = side * (0.5 if barks else -0.05)
		elif barks:
			ez = side * (0.2 + sin(_gait * 2.0) * 0.25 * moving)
		ear.rotation = ear.rotation.lerp(Vector3(ex, 0, ez), k)
	if _head:
		var hy := 0.0
		var hx := 0.0
		var look := Vector3.INF
		if alert.state > AlertState.UNAWARE and alert.has_target:
			look = alert.last_known
		elif play == &"snap" and PerceptionSystem.player:
			look = PerceptionSystem.player.global_position
		elif _toy and play in [&"toy", &"fetch"]:
			look = _toy.global_position
		if look != Vector3.INF:
			var local := global_transform.affine_inverse() * look - _head.position
			hy = clampf(atan2(-local.x, -local.z), -0.9, 0.9)
			hx = clampf(atan2(local.y, Vector2(local.x, local.z).length()), -0.6, 0.8)
		if lying:
			hx = -0.5
		elif mood == Mood.CALM and play == &"" and speed < 1.0:
			hy = sin(_pose_t * 0.7) * 0.4
			hx = -0.2 if barks and fmod(_pose_t, 5.0) < 2.0 else 0.0
		_head.rotation = _head.rotation.lerp(Vector3(hx, hy, 0), k)
	if _tongue:
		_tongue.visible = barks and (mood == Mood.PLAY or speed > config.patrol_speed * 1.2)
