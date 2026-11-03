class_name PickupItem
extends Area3D
## Bug food or a crumb gem lying in the level. Touch it to eat / collect it;
## the Level applies its effect (see PowerUps).

signal collected(item: PickupItem)

@export var def: ItemDef

var taken := false
var _t := 0.0
@onready var _visual: Node3D = get_node_or_null("Visual")
@onready var _base_y := _visual.position.y if _visual else 0.0


func _ready() -> void:
	add_to_group(Phys.GROUP_ITEM)
	collision_layer = Phys.PICKUP
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(_on_body_entered)
	_t = randf() * TAU


func is_gem() -> bool:
	return def != null and def.kind == ItemDef.Kind.GEM


func _process(delta: float) -> void:
	if _visual == null or taken:
		return
	_t += delta
	var gem := is_gem()
	_visual.rotate_y(delta * (1.8 if gem else 0.7))
	_visual.position.y = _base_y + sin(_t * (2.4 if gem else 1.6)) * (0.25 if gem else 0.08)
	if gem:
		var s := 1.0 + sin(_t * 5.0) * 0.06
		_visual.scale = Vector3(s, s, s)


func _on_body_entered(b: Node3D) -> void:
	if b is BugBase and not taken and not (b as BugBase).dead:
		collect()


func collect() -> void:
	if taken:
		return
	taken = true
	set_deferred("monitoring", false)
	AudioManager.play_at(&"gem" if is_gem() else &"munch", global_position, 0.0, randf_range(0.95, 1.1))
	collected.emit(self)
	if _visual:
		var tw := create_tween()
		tw.tween_property(_visual, "scale", Vector3.ONE * 1.8, 0.08)
		tw.tween_property(_visual, "scale", Vector3.ZERO, 0.18)
		tw.tween_callback(func() -> void: visible = false)
	else:
		visible = false
