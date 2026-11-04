extends Ability
## Button: climb up out of reach for `duration` seconds. Ground traffic
## passes underneath; water, fire and raptors still count.


func has_button() -> bool:
	return true


func _activate() -> bool:
	active_left = float(p.get("duration", 1.6))
	return true


func immune(source: String, _cause: String) -> bool:
	return active_left > 0.0 and source in ["mover", "predator"]
