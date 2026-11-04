class_name Passage
extends Area3D
## Secret route entrance (vent, wall crack, pipe, gap behind the fridge).
## Only some bugs fit: roaches take cracks and low gaps, spiders take high
## vents and ceiling corners, flies take open vents and window gaps.

@export var allowed_bugs: PackedStringArray = []
@export var exit_path: NodePath
@export var label: String = "crack"


func _ready() -> void:
	add_to_group(Phys.GROUP_INTERACTABLE)
	collision_layer = Phys.PICKUP
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(func(b: Node3D) -> void:
		if b is BugBase:
			(b as BugBase).add_interactable(self))
	body_exited.connect(func(b: Node3D) -> void:
		if b is BugBase:
			(b as BugBase).remove_interactable(self))


func can_interact(bug: BugBase) -> bool:
	return bug.stats.fits(allowed_bugs)


func hint_text(bug: BugBase) -> String:
	if can_interact(bug):
		return "USE: crawl through the %s" % label
	return "This %s doesn't fit a %s" % [label, bug.stats.display_name.to_lower()]


func interact(bug: BugBase) -> void:
	if not can_interact(bug):
		return
	var exit := get_node_or_null(exit_path) as Node3D
	if exit == null:
		return
	AudioManager.play(&"skitter", -2.0, 0.8)
	bug.teleport_to(exit.global_transform)
