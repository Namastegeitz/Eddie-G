class_name PlayerDriver
extends RefCounted
## Feeds a local player's controls into their racer.

var slot := 0


func _init(p_slot: int) -> void:
	slot = p_slot


func drive(r: Racer, _dt: float) -> void:
	var c: InputRouter.Controls = InputRouter.controls(slot)
	r.in_steer = c.steer
	r.in_throttle = c.throttle
	r.in_brake = c.brake
	r.in_drift = c.drift
	r.in_item = c.item
	r.in_look_back = c.look_back
