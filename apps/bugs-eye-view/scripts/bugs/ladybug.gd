class_name Ladybug
extends GroundBug
## A tough little dome. Primary: Shell Up - tuck in and nothing can hurt you,
## but you can't move (the shell meter runs down and refills). Hold Jump in the
## air to flutter down gently from tables and counters. Lucky: people won't
## swat a ladybug unless the alarm is full (pets don't care).

const FLUTTER_FALL := 3.0
const FLUTTER_SPEED := 1.3

var shelled := false
var shell := 0.0
var fluttering := false
var _flutter := 0.0
var _shell_l: Node3D
var _shell_r: Node3D


func _bug_setup() -> void:
	sprint_on_primary = false
	shell = stats.ability_meter_max
	_flutter = stats.ability_duration
	if visual:
		_shell_l = visual.get_node_or_null("ShellL") as Node3D
		_shell_r = visual.get_node_or_null("ShellR") as Node3D


func get_action_labels() -> Dictionary:
	return {"primary": "Shell up", "secondary": "Squeeze", "jump": "Flutter" if not is_on_floor() else "Hop",
		"dodge": "Run", "interact": "Use", "sense": "Antennae"}


func ability_name() -> String:
	return "SHELL"


func is_spared_by_people() -> bool:
	return true


func _custom_move(delta: float) -> bool:
	shelled = InputRouter.is_held(&"primary") and shell > 0.05 and is_on_floor()
	if shelled:
		shell = maxf(shell - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 60.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 60.0 * delta)
		velocity.y = 0.0 if is_on_floor() else velocity.y - stats.gravity * delta
		move_and_slide()
		if visual:
			visual.scale.y = lerpf(visual.scale.y, 0.8 * size_mult(), clampf(12.0 * delta, 0.0, 1.0))
		return true
	shell = minf(shell + delta * 0.5, stats.ability_meter_max)
	return false


func _ground_tick(delta: float) -> void:
	fluttering = not is_on_floor() and InputRouter.is_held(&"jump") and _flutter > 0.0
	if fluttering:
		_flutter = maxf(_flutter - delta, 0.0)
		velocity.y = maxf(velocity.y, -FLUTTER_FALL)
		var flat := Vector3(velocity.x, 0.0, velocity.z)
		if flat.length() < stats.move_speed * FLUTTER_SPEED:
			velocity += facing * stats.move_speed * 2.0 * delta
	elif is_on_floor():
		_flutter = minf(_flutter + delta * 1.5, stats.ability_duration)
	meter_changed.emit(&"stamina", _flutter, stats.ability_duration)
	# Wing cases lift to flutter, close otherwise.
	var open := 0.9 if fluttering else 0.0
	if _shell_l and _shell_r:
		_shell_l.rotation.z = lerpf(_shell_l.rotation.z, open, clampf(12.0 * delta, 0.0, 1.0))
		_shell_r.rotation.z = lerpf(_shell_r.rotation.z, -open, clampf(12.0 * delta, 0.0, 1.0))


func _move(delta: float) -> void:
	super._move(delta)
	# The ability meter is the shell, not a cooldown.
	meter_changed.emit(&"ability", shell, stats.ability_meter_max)


func take_hit(cause: StringName, from: Vector3) -> bool:
	if shelled:
		AudioManager.play(&"shield", -2.0, 1.4)
		return false
	return super.take_hit(cause, from)


func _extra_visibility_mult() -> float:
	return (0.75 if shelled else 1.0) * super._extra_visibility_mult()
