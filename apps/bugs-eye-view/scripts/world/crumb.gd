class_name Crumb
extends Area3D
## Scavenge target. Golden crumbs hide at the end of each level's secret route.

signal collected(crumb: Crumb)

@export var golden: bool = false

var taken := false
@onready var _visual: Node3D = get_node_or_null("Visual")


func _ready() -> void:
	# Animated every frame (not by physics): no physics smoothing needed.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_to_group(Phys.GROUP_CRUMB)
	collision_layer = Phys.PICKUP
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(_on_body_entered)


var _home := Vector3.INF
var _back_in := 0.0


func _process(delta: float) -> void:
	if _visual and not taken:
		_visual.rotate_y(delta * (2.5 if golden else 1.2))
	if _back_in > 0.0:
		_back_in -= delta
		if _back_in <= 0.0:
			# Shaken out of the vacuum's bin (or dropped again) back near home.
			taken = false
			visible = true
			global_position = _home
			set_deferred("monitoring", true)


## Sucked up by the robot vacuum: gone for a while, then back.
func suck_up(back_after: float = 25.0) -> void:
	if taken or golden:
		return
	taken = true
	_home = global_position
	visible = false
	set_deferred("monitoring", false)
	_back_in = back_after


func is_sucked_up() -> bool:
	return _back_in > 0.0


func _on_body_entered(b: Node3D) -> void:
	if b is BugBase and not taken and not (b as BugBase).dead:
		collect()


func collect() -> void:
	if taken:
		return
	taken = true
	set_deferred("monitoring", false)
	AudioManager.play_at(&"golden" if golden else &"crunch", global_position, 0.0, randf_range(0.95, 1.1))
	collected.emit(self)
	if _visual:
		var tw := create_tween()
		tw.tween_property(_visual, "scale", Vector3.ONE * 1.6, 0.08)
		tw.tween_property(_visual, "scale", Vector3.ZERO, 0.15)
		tw.tween_callback(func() -> void: visible = false)
	else:
		visible = false
