extends Ability
## Button: take off for `duration` seconds. While hovering, nothing on the
## ground or in the water can touch you (raptors still can); you land wherever
## you are when it runs out.


func has_button() -> bool:
	return true


func _activate() -> bool:
	if run.hopping:
		return false
	active_left = float(p.get("duration", 1.6))
	return true


func airborne() -> bool:
	return active_left > 0.0


func tick(dt: float) -> void:
	var was := active_left > 0.0
	super.tick(dt)
	if was and active_left <= 0.0:
		run.call("_hover_landed")
