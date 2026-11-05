class_name Thermal
extends Area3D
## Warm rising air (stove, toaster, heater, lamp, barbecue, sunny patio). A
## flying fly inside is lifted and gets its stamina back; a gliding fly can
## catch it and fly again. Can be tied to routine events (only while cooking).

@export var lift: float = 7.0
@export var active_events: PackedStringArray = []

var _fly: Fly = null
var _active := true
var _t := 0.0
var _h := 10.0


func _ready() -> void:
	# Animated every frame (not by physics): no physics smoothing needed.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	collision_layer = Phys.ZONE
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(func(b: Node3D) -> void:
		if b is Fly:
			_fly = b)
	body_exited.connect(func(b: Node3D) -> void:
		if b == _fly:
			_fly.thermal_lift = 0.0
			_fly = null)
	var cs := get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D:
		_h = (cs.shape as BoxShape3D).size.y
	HouseClock.routine_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_active = active_events.is_empty() or HouseClock.any_active(active_events)
	for c in get_children():
		if c is Node3D and String(c.name).begins_with("Shimmer"):
			(c as Node3D).visible = _active


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active:
		return
	# Shimmer rings drift upward and loop.
	_t += delta
	var h := _h
	var i := 0
	for c in get_children():
		if c is Node3D and String(c.name).begins_with("Shimmer"):
			var y := fmod(_t * 4.0 + i * h / 3.0, h) - h * 0.5
			(c as Node3D).position.y = y
			i += 1


func _physics_process(_delta: float) -> void:
	if _active and _fly and _fly.flying and not _fly.dead:
		_fly.add_thermal_lift(lift)
