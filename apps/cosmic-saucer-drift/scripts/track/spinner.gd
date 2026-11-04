extends Node3D
## Slowly spins a decoration around its local Y axis.

@export var speed := 0.1


func _process(dt: float) -> void:
	rotate_object_local(Vector3.UP, speed * dt)
