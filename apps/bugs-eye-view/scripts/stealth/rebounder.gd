class_name Rebounder
extends Node3D
## A hard object (hanging pan, metal pot). A strike that lands within `radius`
## clangs off it and stuns the threat that swung it.

@export var radius: float = 4.0


func _ready() -> void:
	add_to_group(Phys.GROUP_REBOUNDER)
