extends Ability
## Button: a long, floaty jump `tiles` rows forward. With "soft_landing" a
## water landing floats for that many seconds, waiting for a log to drift by.


func _init_state() -> void:
	extra["soft_landing"] = float(p.get("soft_landing", 0.0))


func has_button() -> bool:
	return true


func _activate() -> bool:
	var n := int(p.get("tiles", 2))
	return run.leap(n, 0.34 + 0.09 * n, "swoop" if style == "swoop" else "glide")
