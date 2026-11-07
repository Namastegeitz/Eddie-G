class_name MouseTrap
extends Node3D
## A wooden snap trap with a cheese bait. Step on the plate and a moment later
## the bar slams over: anything still on it takes a hit (and the snap is
## loud). It resets after a couple of seconds. Flyers pass over it.

const ARM_DELAY := 0.22
const RESET_TIME := 2.6

var armed := true
var snaps := 0
var _trigger_t := -1.0
var _reset_t := 0.0
var _bar: Node3D
var _area: Area3D


func _ready() -> void:
	add_to_group(&"mouse_trap")
	_bar = get_node_or_null("Bar") as Node3D
	_area = get_node_or_null("Trigger") as Area3D
	if _area:
		_area.collision_layer = 0
		_area.collision_mask = Phys.PLAYER
		_area.monitorable = false
		_area.body_entered.connect(_on_body_entered)


func _on_body_entered(b: Node3D) -> void:
	var bug := b as BugBase
	if bug == null or bug.dead or not armed or _trigger_t >= 0.0:
		return
	if bug is Fly and (bug as Fly).flying:
		return
	_trigger_t = ARM_DELAY
	AudioManager.play_at(&"clink", global_position, -2.0, 1.6)


func _physics_process(delta: float) -> void:
	if _trigger_t >= 0.0:
		_trigger_t -= delta
		if _trigger_t < 0.0:
			snap()
	elif not armed:
		_reset_t -= delta
		if _bar:
			_bar.rotation.x = lerpf(_bar.rotation.x, 0.0, clampf(3.0 * delta, 0.0, 1.0)) if _reset_t < 1.0 else _bar.rotation.x
		if _reset_t <= 0.0:
			armed = true
			if _bar:
				_bar.rotation.x = 0.0


## Slams the bar over; anything on the plate is hit.
func snap() -> int:
	armed = false
	_trigger_t = -1.0
	_reset_t = RESET_TIME
	snaps += 1
	if _bar:
		var tw := create_tween()
		tw.tween_property(_bar, "rotation:x", -PI * 0.97, 0.07)
	AudioManager.play_at(&"snap", global_position, 4.0)
	PerceptionSystem.emit_world_noise(global_position, 2.0)
	var hits := 0
	if _area:
		for b in _area.get_overlapping_bodies():
			var bug := b as BugBase
			if bug and not bug.dead and bug.take_hit(&"snapped", global_position):
				hits += 1
	return hits
