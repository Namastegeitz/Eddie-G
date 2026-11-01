class_name Cockroach
extends BugBase
## Fast on the ground, squeezes flat into gaps, survives one extra hit with a
## knockdown, plays dead near a suspicious threat, smells crumbs with its
## antennae, runs faster in the dark and scatters when a light flicks on.

const SMELL_INTERVAL := 0.25

var _scatter := 0.0
var _prev_light := 0.7
var _smell_timer := 0.0
var _arrow: Node3D
var _playing_dead := false


func _setup() -> void:
	_arrow = get_node_or_null("SenseArrow")
	if _arrow:
		_arrow.visible = false
	_prev_light = PerceptionSystem.light_level


func get_action_labels() -> Dictionary:
	return {"primary": "Sprint", "secondary": "Squeeze", "jump": "Hop",
		"dodge": "Dash", "interact": "Use", "sense": "Smell"}


func _move(delta: float) -> void:
	var light := PerceptionSystem.light_level
	# Real roaches bolt when a light comes on.
	if light - _prev_light > 0.3 and light >= _cfg.light_lit - 0.05:
		_scatter = stats.scatter_duration
		AudioManager.play(&"skitter", -4.0, 1.2)
	_prev_light = light
	_scatter = maxf(_scatter - delta, 0.0)
	is_squeezing = InputRouter.is_held(&"secondary")
	var speed := stats.sprint_speed if is_sprinting() else stats.move_speed
	if light <= _cfg.light_dim + 0.01:
		speed *= 1.0 + stats.dark_speed_bonus
	if _scatter > 0.0:
		speed *= 1.0 + stats.scatter_boost
	if is_squeezing:
		speed *= stats.squeeze_speed_mult
	speed *= slow_mult
	ground_move(delta, speed)
	face_velocity(delta)
	_playing_dead = is_frozen() and _suspicious_threat_near()
	if visual:
		var target_y := 0.5 if is_squeezing else 1.0
		visual.scale.y = lerpf(visual.scale.y, target_y, clampf(12.0 * delta, 0.0, 1.0))
		if knockdown <= 0.0:
			visual.rotation.z = lerpf(visual.rotation.z, PI if _playing_dead else 0.0, clampf(8.0 * delta, 0.0, 1.0))


func is_sprinting() -> bool:
	return InputRouter.is_held(&"primary") and move_input().length() > 0.1 and not is_squeezing


func _extra_visibility_mult() -> float:
	var m := 1.0
	if is_squeezing:
		m *= 0.8
	if _playing_dead:
		m *= _cfg.play_dead_factor
	return m


func _suspicious_threat_near() -> bool:
	for t in PerceptionSystem.threats:
		if t.present and t.alert.state >= AlertState.SUSPICIOUS \
				and t.global_position.distance_to(global_position) < _cfg.play_dead_radius:
			return true
	return false


func is_playing_dead() -> bool:
	return _playing_dead


# --- Smell sense: the antennae point at the nearest crumb ----------------------

func _sense_start() -> void:
	_smell_timer = 0.0
	if _arrow:
		_arrow.visible = true


func _sense_tick(delta: float) -> void:
	_smell_timer -= delta
	if _smell_timer > 0.0 or _arrow == null:
		return
	_smell_timer = SMELL_INTERVAL
	var best: Crumb = null
	var best_d := stats.sense_range
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		var crumb := c as Crumb
		if crumb and not crumb.taken:
			var d := crumb.global_position.distance_to(global_position)
			if d < best_d:
				best = crumb
				best_d = d
	if best == null:
		_arrow.visible = false
		return
	_arrow.visible = true
	var to := best.global_position - global_position
	to.y = 0.0
	if to.length() > 0.1:
		_arrow.global_rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)


func _sense_end() -> void:
	if _arrow:
		_arrow.visible = false
