class_name GroundBug
extends BugBase
## Shared walking for the newer ground bugs (ant, cricket, ladybug, stink
## bug): walk or sprint, squeeze into gaps on Secondary, and find crumbs with
## the antennae on Sense (an arrow points to the nearest one). Subclasses add
## a special move and can take over Primary or Secondary for it.

const SMELL_INTERVAL := 0.25

## Secondary squeezes into gaps (false: it's free for a special move).
var squeeze_on_secondary := true
## Primary sprints (false: it's free for a special move).
var sprint_on_primary := true
## Seconds until the special move is ready again.
var ability_cd := 0.0
var _smell_timer := 0.0
var _arrow: Node3D


func _setup() -> void:
	_arrow = get_node_or_null("SenseArrow")
	if _arrow:
		_arrow.visible = false
	_bug_setup()


## Subclass setup.
func _bug_setup() -> void:
	pass


func _move(delta: float) -> void:
	ability_cd = maxf(ability_cd - delta, 0.0)
	is_squeezing = squeeze_on_secondary and InputRouter.is_held(&"secondary")
	if not _custom_move(delta):
		var speed := run_speed() if is_sprinting() or is_running() else stats.move_speed
		if is_squeezing:
			speed *= stats.squeeze_speed_mult
		speed *= speed_scale()
		ground_move(delta, speed)
		face_velocity(delta)
		if visual:
			var target_y := (0.55 if is_squeezing else 1.0) * size_mult()
			visual.scale.y = lerpf(visual.scale.y, target_y, clampf(12.0 * delta, 0.0, 1.0))
	_ground_tick(delta)
	if ability_name() != "":
		meter_changed.emit(&"ability", stats.ability_cooldown - ability_cd, stats.ability_cooldown)


## Return true when the subclass moved the bug itself this frame.
func _custom_move(_delta: float) -> bool:
	return false


func _ground_tick(_delta: float) -> void:
	pass


## Starts the special move's cooldown; false (with a hint) if not ready.
func use_ability() -> bool:
	if ability_cd > 0.0:
		show_hint("%s ready in %ds" % [ability_name().capitalize(), ceili(ability_cd)])
		return false
	ability_cd = stats.ability_cooldown
	return true


func is_sprinting() -> bool:
	return sprint_on_primary and InputRouter.is_held(&"primary") and move_input().length() > 0.1 and not is_squeezing


func _extra_visibility_mult() -> float:
	return 0.8 if is_squeezing else 1.0


# --- Sense: the antennae point at the nearest crumb ---------------------------

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


func _owns_visual_height() -> bool:
	return true
