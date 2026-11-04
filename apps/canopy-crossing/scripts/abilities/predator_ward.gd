extends Ability
## Predators (snakes, crocs, raptors, tigers) miss you. mode "passive": the
## first `charges` attacks miss, optionally recharging every `recharge` s
## (camouflage, stealth, the loris's toxins).


func _init_state() -> void:
	charges = int(p.get("charges", 1))


func absorb(source: String, _cause: String) -> bool:
	if charges > 0 and source in ["predator", "swooper"]:
		charges -= 1
		if p.has("recharge"):
			extra["recharge_left"] = float(p.recharge)
		return true
	return false


func tick(dt: float) -> void:
	super.tick(dt)
	if extra.has("recharge_left"):
		extra.recharge_left = float(extra.recharge_left) - dt
		if float(extra.recharge_left) <= 0.0:
			extra.erase("recharge_left")
			charges = mini(int(p.get("charges", 1)), charges + 1)


func is_active() -> bool:
	return charges > 0


func badge() -> String:
	return str(charges) if charges > 0 and charges < 10 else ""
