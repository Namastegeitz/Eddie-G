class_name CatPerch
extends Node3D
## A spot the cat can leap onto (counter, side table, cat tree). Landing here
## shoves loose props within `knock_radius` off the edge.

@export var top_offset: Vector3 = Vector3(0, 10, 0)
@export var knock_radius: float = 5.0


func _ready() -> void:
	add_to_group(Phys.GROUP_PERCH)


func top_position() -> Vector3:
	return global_position + top_offset


func knock_props(from: Vector3) -> int:
	var n := 0
	var top := top_position()
	for p in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var prop := p as PhysicsProp
		if prop and prop.global_position.distance_to(top) <= knock_radius:
			prop.freeze = false
			prop.sleeping = false
			var dir := prop.global_position - from
			dir.y = 0.0
			prop.apply_central_impulse((dir.normalized() * 6.0 + Vector3.UP * 2.0) * prop.mass)
			n += 1
	return n
