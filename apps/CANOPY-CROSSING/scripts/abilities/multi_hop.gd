extends Ability
## Button: an arcing jump `tiles` rows forward, clear of everything below.
## Used by the double-hop frogs, the tree kangaroo, the cassowary's charge.


func has_button() -> bool:
	return true


func _activate() -> bool:
	var n := int(p.get("tiles", 2))
	var kind := "charge" if style == "charge" else "multi_hop"
	return run.leap(n, 0.22 + 0.06 * n, kind)
