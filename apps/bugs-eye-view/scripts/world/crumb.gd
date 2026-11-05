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


func _process(delta: float) -> void:
	if _visual and not taken:
		_visual.rotate_y(delta * (2.5 if golden else 1.2))


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
