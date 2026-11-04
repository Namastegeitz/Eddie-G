extends Ability
## A one-hit shield against movers, predators and fire. mode "passive": start
## each run with `charges`; mode "active": the button grants one (max one).


func _init_state() -> void:
	charges = int(p.get("charges", 1)) if String(p.get("mode", "active")) == "passive" else 0


func has_button() -> bool:
	return String(p.get("mode", "active")) == "active"


func _ready_extra() -> bool:
	return charges == 0


func _activate() -> bool:
	charges = 1
	return true


func absorb(source: String, _cause: String) -> bool:
	if charges > 0 and source in RunSim.SAFE_SOURCES:
		charges -= 1
		return true
	return false


func is_active() -> bool:
	return charges > 0
