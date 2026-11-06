class_name StinkBug
extends GroundBug
## Slow but tough: takes three hits. Primary releases a stink cloud - pets
## bolt from it, people cough and can't see while it lasts. You smell strong
## enough that dogs pick up your trail easily, though.


func _bug_setup() -> void:
	sprint_on_primary = false


func get_action_labels() -> Dictionary:
	return {"primary": "Stink", "secondary": "Squeeze", "jump": "Hop",
		"dodge": "Run", "interact": "Use", "sense": "Antennae"}


func ability_name() -> String:
	return "STINK"


## Your trail lingers: dogs pick it up easily.
func scent_strength() -> float:
	return 2.0


func _action_pressed(a: StringName) -> void:
	if a == &"primary":
		release_stink()


func release_stink() -> StinkCloud:
	if not use_ability():
		return null
	var c := StinkCloud.new()
	c.radius = stats.ability_radius
	c.time_left = stats.ability_duration
	var parent: Node = Level.current if Level.current else get_parent()
	parent.add_child(c)
	c.global_position = global_position
	AudioManager.play(&"hiss", -2.0, 0.55)
	show_hint("Pfff! Stink cloud")
	return c
