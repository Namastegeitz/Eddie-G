class_name Goal
extends Area3D
## The escape hole. Opens once enough crumbs are collected.

signal reached

@export var label: String = "crack in the wall"

var active := false
@onready var _beacon: Node3D = get_node_or_null("Beacon")


func _ready() -> void:
	collision_layer = Phys.PICKUP
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(_on_body_entered)
	set_active(false)


func set_active(on: bool) -> void:
	active = on
	if _beacon:
		_beacon.visible = on
	if on:
		for b in get_overlapping_bodies():
			_on_body_entered(b)


func _process(delta: float) -> void:
	if _beacon and active:
		_beacon.rotate_y(delta * 2.0)


func _on_body_entered(b: Node3D) -> void:
	if active and b is BugBase and not (b as BugBase).dead:
		reached.emit()
