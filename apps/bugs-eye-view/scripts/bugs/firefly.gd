class_name Firefly
extends Fly
## A fly that glows: lit up while flying (easy to spot in the dark), dark the
## moment it lands or clings. Sense is Flash: it dazzles every person and pet
## close by, and none of them can see you for a few seconds.

var _glow: OmniLight3D


func _setup() -> void:
	super._setup()
	_glow = get_node_or_null("Visual/Glow") as OmniLight3D


func get_action_labels() -> Dictionary:
	var labels := super.get_action_labels()
	labels["sense"] = "Flash"
	return labels


func ability_name() -> String:
	return ""


func is_glowing() -> bool:
	return flying and not gliding


func _move(delta: float) -> void:
	super._move(delta)
	if _glow:
		_glow.visible = is_glowing()


func compute_visibility(light: float, cfg: StealthConfig) -> float:
	# Your own light gives you away in the dark.
	return super.compute_visibility(maxf(light, 0.5) if is_glowing() else light, cfg)


## Sense: flash instead of the fly's slow motion.
func toggle_sense() -> void:
	if sense_meter < stats.bullet_time_cost:
		show_hint("Flash is recharging")
		return
	sense_meter -= stats.bullet_time_cost
	flash()


func flash() -> int:
	var n := 0
	for t in PerceptionSystem.threats:
		if t.present and t.eye_position().distance_to(global_position) <= stats.ability_radius:
			t.dazzle(stats.ability_duration)
			n += 1
	if _glow:
		_glow.visible = true
		var base := _glow.light_energy
		var tw := create_tween()
		tw.tween_property(_glow, "light_energy", base * 6.0, 0.06)
		tw.tween_property(_glow, "light_energy", base, 0.4)
	AudioManager.play(&"gem", -2.0, 1.7)
	show_hint("Flash! %d dazzled" % n if n > 0 else "Flash! Nobody close enough")
	return n


## No automatic slow motion: the firefly's Sense is its flash.
func _on_strike_incoming(_pos: Vector3, _time_to_impact: float, _radius: float) -> void:
	pass
