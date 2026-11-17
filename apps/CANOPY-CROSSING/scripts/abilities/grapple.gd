extends Ability
## Vine Grapple power-up: pull forward `rows` lanes. Limited uses per run.


func has_button() -> bool:
	return true


func _activate() -> bool:
	return run.leap(int(p.get("rows", 2)), 0.42, "grapple")
