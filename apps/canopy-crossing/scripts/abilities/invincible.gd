extends Ability
## Button: untouchable by movers, predators and fire for `duration` seconds.
## "rooted" means you can't move meanwhile (the echidna curls up).


func has_button() -> bool:
	return true


func _activate() -> bool:
	active_left = float(p.get("duration", 1.5))
	return true


func immune(source: String, _cause: String) -> bool:
	return active_left > 0.0 and source in RunSim.SAFE_SOURCES


func rooted() -> bool:
	return active_left > 0.0 and bool(p.get("rooted", false))
