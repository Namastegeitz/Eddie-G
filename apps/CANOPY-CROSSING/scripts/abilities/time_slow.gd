extends Ability
## Time-Slow power-up: every hazard runs at half speed for `duration` s.


func has_button() -> bool:
	return true


func _activate() -> bool:
	run.slow_left = float(p.get("duration", 4.0))
	active_left = run.slow_left
	return true
