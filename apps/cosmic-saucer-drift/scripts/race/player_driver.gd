class_name PlayerDriver
extends RefCounted
## Feeds a local player's controls into their racer.

var slot := 0
var _steer := 0.0


func _init(p_slot: int) -> void:
	slot = p_slot


func drive(r: Racer, dt: float) -> void:
	var c: InputRouter.Controls = InputRouter.controls(slot)
	# Keys and touch buttons are all-or-nothing: ease them in (about 0.13 s
	# to full lock, quicker back to centre) so taps make small corrections.
	# Analogue sticks and tilt pass straight through.
	var want := c.steer
	if want == 0.0 or absf(want) == 1.0:
		var rate := 7.5 if (absf(want) > absf(_steer) and signf(want) == signf(_steer)) or _steer == 0.0 else 12.0
		_steer = move_toward(_steer, want, rate * dt)
	else:
		_steer = want
	r.in_steer = _steer
	# On the grid only a real press of GAS counts (auto-drive used to hold
	# it from the first second of the countdown, which always stalled).
	r.in_throttle = c.gas if r.frozen else c.throttle
	r.in_brake = c.brake
	r.in_drift = c.drift
	r.in_item = c.item
	r.in_look_back = c.look_back
