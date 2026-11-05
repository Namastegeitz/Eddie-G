class_name SwingDoor
extends AnimatableBody3D
## A door on a hinge (the fridge door): a person opens it, it swings out into
## the room as a solid obstacle, then closes again. Its light zone (the fridge
## light) comes on while it's open.

@export var open_angle: float = -1.9
@export var light_zone_path: NodePath
var angle := 0.0
var _target := 0.0
var _open_time := 0.0


func _ready() -> void:
	collision_layer = Phys.WORLD
	collision_mask = 0
	sync_to_physics = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	set_meta(&"surface", &"metal")


func is_open() -> bool:
	return _target != 0.0


## Opens for `seconds`, then swings shut by itself.
func open_for(seconds: float) -> void:
	if not is_open():
		AudioManager.play_at(&"door", global_position, -2.0)
	_target = open_angle
	_open_time = seconds
	var z := get_node_or_null(light_zone_path) as LightZone
	if z:
		z.flash(seconds + 0.6)


func close() -> void:
	if is_open() and is_inside_tree():
		AudioManager.play_at(&"door", global_position, -4.0, 1.15)
	_target = 0.0
	_open_time = 0.0
	var z := get_node_or_null(light_zone_path) as LightZone if is_inside_tree() else null
	if z:
		z.flash(0.05)


func _physics_process(delta: float) -> void:
	if _open_time > 0.0:
		_open_time -= delta
		if _open_time <= 0.0:
			close()
	angle = move_toward(angle, _target, 2.4 * delta)
	rotation.y = angle
