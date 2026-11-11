class_name MouseTrap
extends Node3D
## A wooden snap trap with a cheese bait. Step onto the plate (or land on it)
## and it clicks; a moment later the bar slams over. Anything still on the
## plate is knocked out cold and loses a big bite of health
## (BugBase.snap_trap): one snap never kills, but a second one back to back
## does. The bar holds a knocked-out bug down until it comes to, then lifts,
## and the trap only re-arms once the plate is clear. The snap is loud.
## Flyers in the air pass over it; a dodge or a shield gets you out of it.

## The click before the snap: quick bugs can still get off.
const ARM_DELAY := 0.22
const RESET_TIME := 2.6
## The bar's angle when set (pulled right back over the spring), when it
## rests on a bug it has caught, and when it has slammed down on bare wood.
const COCKED := -PI * 0.97
const ON_BUG := -0.22
const DOWN := 0.0

var armed := true
var snaps := 0
var _trigger_t := -1.0
var _reset_t := 0.0
var _bar: Node3D
var _area: Area3D
## Bugs the bar is holding down (knocked out).
var _caught: Array[BugBase] = []
var _lifted := false


func _ready() -> void:
	add_to_group(&"mouse_trap")
	_bar = get_node_or_null("Bar") as Node3D
	if _bar:
		_bar.rotation.x = COCKED
	_area = get_node_or_null("Trigger") as Area3D
	if _area:
		_area.collision_layer = 0
		_area.collision_mask = Phys.PLAYER
		_area.monitorable = false


## A bug standing on the plate (not flying over it). With `anyone`, any live
## bug in the trap's space counts (for "is the plate clear?").
func _bug_on_plate(anyone: bool = false) -> BugBase:
	if _area == null or not _area.has_overlapping_bodies():
		return null
	for b in _area.get_overlapping_bodies():
		var bug := b as BugBase
		if bug == null or bug.dead:
			continue
		if anyone:
			return bug
		if bug is Fly and (bug as Fly).flying:
			continue
		if bug.knocked_out_left > 0.0:
			continue
		return bug
	return null


func _physics_process(delta: float) -> void:
	if _trigger_t >= 0.0:
		_trigger_t -= delta
		if _trigger_t < 0.0:
			snap()
		return
	if armed:
		if _bug_on_plate():
			_trigger_t = ARM_DELAY
			AudioManager.play_at(&"clink", global_position, -2.0, 1.6)
		return
	# Sprung: the bar holds down anyone it caught until they come to.
	var held := false
	for bug in _caught:
		if is_instance_valid(bug) and not bug.dead and bug.knocked_out_left > 0.0:
			held = true
	if held:
		_reset_t = RESET_TIME
		return
	if not _caught.is_empty():
		# It came to: the bar lifts straight off it.
		_caught.clear()
		_lifted = true
	_reset_t -= delta
	# A bar that missed lies there a moment, then winds back. Either way the
	# trap only re-arms once the plate is clear, so it can't snap the same
	# bug twice while it climbs off.
	var clear := _bug_on_plate(true) == null
	if _bar:
		var want := DOWN
		if _lifted or _reset_t < 1.0:
			want = COCKED
		_bar.rotation.x = lerpf(_bar.rotation.x, want, clampf(4.0 * delta, 0.0, 1.0))
	if _reset_t <= 0.0 and clear:
		armed = true
		_lifted = false
		if _bar:
			_bar.rotation.x = COCKED


## Slams the bar over; anything on the plate is knocked out. Returns how many
## bugs it caught.
func snap() -> int:
	armed = false
	_trigger_t = -1.0
	_reset_t = RESET_TIME
	snaps += 1
	AudioManager.play_at(&"snap", global_position, 4.0)
	PerceptionSystem.emit_world_noise(global_position, 2.0)
	var hits := 0
	if _area:
		for b in _area.get_overlapping_bodies():
			var bug := b as BugBase
			if bug == null or bug.dead:
				continue
			if bug is Fly and (bug as Fly).flying:
				continue
			if bug.snap_trap(global_position):
				hits += 1
				if not bug.dead:
					_caught.append(bug)
	# The bar whips over the spring and slams down on the plate (resting on
	# the back of anything it caught).
	if _bar:
		var tw := create_tween()
		tw.tween_property(_bar, "rotation:x", ON_BUG if not _caught.is_empty() else DOWN, 0.07)
	return hits


## True while the bar is down on a knocked-out bug.
func is_holding() -> bool:
	for bug in _caught:
		if is_instance_valid(bug) and not bug.dead and bug.knocked_out_left > 0.0:
			return true
	return false
