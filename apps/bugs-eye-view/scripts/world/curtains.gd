class_name Curtains
extends Node3D
## Curtains over a window: a person draws them across (the sunbeam on the
## floor goes away) or pulls them open (it comes back).

@export var sunbeam_path: NodePath
@export var width: float = 30.0
var closed := false
var _k := 0.0
var _panel: Node3D


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_panel = get_node_or_null("Panel") as Node3D


func toggle() -> void:
	set_closed(not closed)


func set_closed(on: bool) -> void:
	closed = on
	AudioManager.play_at(&"swoosh", global_position, -6.0, 0.8)
	var z := get_node_or_null(sunbeam_path) as LightZone
	if z:
		z.override(not on, 9999.0)


func _process(delta: float) -> void:
	_k = move_toward(_k, 1.0 if closed else 0.0, delta * 1.5)
	# Bunched at one side when open, drawn right across when closed.
	if _panel:
		var f := lerpf(0.18, 1.0, _k)
		_panel.scale.z = f
		_panel.position.z = width * 0.5 * (1.0 - f)
