extends Node3D
## Drifts a decoration along a line and loops it back to the start (comets,
## passing freighters).

@export var velocity := Vector3(-40.0, 0.0, 0.0)
@export var span := 3000.0
var _start := Vector3.ZERO


func _ready() -> void:
	_start = position


func _process(dt: float) -> void:
	position += velocity * dt
	if position.distance_to(_start) > span:
		position = _start
