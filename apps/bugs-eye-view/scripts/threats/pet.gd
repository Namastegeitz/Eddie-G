class_name Pet
extends Threat
## Cat or dog. Patrols (or naps on its routine), investigates noise, chases
## with NavigationAgent3D pathing, pounces with a telegraph, then gives up.
## Dogs follow your scent trail and bark (which alerts the humans); cats see
## sharply and leap onto perches, shoving loose props off the edge.

enum Pounce { NONE, WINDUP, LEAP, RECOVER }

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


func _setup() -> void:
	add_to_group(Phys.GROUP_PET)
	_agent = get_node_or_null("Agent") as NavigationAgent3D
	_visual = get_node_or_null("Visual")
	_ring = Fx.make_ring(Color(1.0, 0.25, 0.1, 0.85))
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)


func wake_up() -> void:
	_woken = 30.0
	sleeping = false


func _idle_icon() -> String:
	return "z" if sleeping else ""


func _hearing_mult() -> float:
	return 0.3 if sleeping else 1.0


func can_see(p: BugBase) -> bool:
	if sleeping:
		return false
	return super.can_see(p)


func _think(delta: float) -> void:
	_attack_cd -= delta
	_bark_cd -= delta
	_woken = maxf(_woken - delta, 0.0)
	sleeping = _woken <= 0.0 and HouseClock.any_active(nap_events) and alert.state <= AlertState.SUSPICIOUS
	if _pounce != Pounce.NONE:
		_pounce_tick(delta)
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

func _start_pounce(target: Vector3) -> void:
	_pounce = Pounce.WINDUP
	_pounce_t = 0.0
	_pounce_to = target
	velocity = Vector3.ZERO
	AudioManager.play_at(&"hiss" if not barks else &"growl", eye_position(), 0.0)
	PerceptionSystem.warn_strike(target, config.attack_windup + leap_time, config.attack_radius)


func _pounce_tick(delta: float) -> void:
	_pounce_t += delta * speed_mult() * boss_speed_mult
	match _pounce:
		Pounce.WINDUP:
			face_towards(_pounce_to, delta, 12.0)
			var k := _pounce_t / config.attack_windup
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
				Hazard.apply_strike(_pounce_to, config.attack_radius, &"pounced", self, true)
				Feedback.impact_at(_pounce_to, 0.6)
				AudioManager.play_at(&"thud", _pounce_to, -4.0, 1.4)
				_pounce = Pounce.RECOVER
				_pounce_t = 0.0
		Pounce.RECOVER:
			_stop(delta)
			if _pounce_t > 0.6:
				_pounce = Pounce.NONE
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
	_pounce = Pounce.NONE
	_ring.visible = false
	if _perch_state == 2 or _perch_state == 4:
		_perch_state = 0
	AudioManager.play_at(&"yelp" if barks else &"hiss", eye_position())


func _stunned_tick(delta: float) -> void:
	_stop(delta)
