class_name HidingSpot
extends Area3D
## A safe spot: under-appliance gaps, wall cracks, deep corners. While safely
## inside, the bug is invisible and hazards cannot reach it.

@export var requires_squeeze: bool = true
## Bug ids that fit (empty = every bug).
@export var allowed_bugs: PackedStringArray = []
@export var hint: String = "Hold SQUEEZE to hide"


func _ready() -> void:
	add_to_group(Phys.GROUP_HIDING)
	collision_layer = Phys.ZONE
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(func(b: Node3D) -> void:
		if b is BugBase:
			(b as BugBase).enter_spot(self))
	body_exited.connect(func(b: Node3D) -> void:
		if b is BugBase:
			(b as BugBase).exit_spot(self))


func fits(bug: BugBase) -> bool:
	# Shrunk by the power-up, any bug fits the roach's gaps.
	return bug.stats.fits(allowed_bugs) or (bug.has_effect(&"shrink") and allowed_bugs.has("cockroach"))


func is_safe_for(bug: BugBase) -> bool:
	return fits(bug) and (not requires_squeeze or bug.is_squeezing or bug.stats.tiny or bug.has_effect(&"shrink"))
