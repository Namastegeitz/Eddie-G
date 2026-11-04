class_name Ant
extends GroundBug
## Tiny: hidden in any gap without squeezing, and hard to spot. Secondary
## sends a column of decoy ants marching off - they rustle as they go, and
## threats go after them instead of you.


func _bug_setup() -> void:
	squeeze_on_secondary = false


func get_action_labels() -> Dictionary:
	return {"primary": "Sprint", "secondary": "Decoys", "jump": "Hop",
		"dodge": "Dash", "interact": "Use", "sense": "Scout"}


func ability_name() -> String:
	return "DECOYS"


func _action_pressed(a: StringName) -> void:
	if a == &"secondary":
		send_decoys()


func send_decoys() -> AntDecoy:
	if not use_ability():
		return null
	var d := AntDecoy.new()
	d.direction = facing
	d.time_left = stats.ability_duration
	var parent: Node = Level.current if Level.current else get_parent()
	parent.add_child(d)
	d.global_position = global_position - up_direction * 0.25
	AudioManager.play(&"skitter", -2.0, 1.5)
	show_hint("Decoy ants away! Threats will follow them")
	return d
