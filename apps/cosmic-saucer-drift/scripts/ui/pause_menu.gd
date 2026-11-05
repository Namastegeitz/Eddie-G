class_name PauseMenu
extends RefCounted
## Pause overlay: resume, restart, quick settings, quit.


static func make(race: Node) -> Control:
	var root := Control.new()
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.06, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var v := UiKit.vbox(14)
	center.add_child(UiKit.panel(v))
	v.add_child(UiKit.label("PAUSED", 56, UiKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	var td: TrackData = race.td
	v.add_child(UiKit.label("%s %s" % [td.name, Catalog.VARIANT_NAMES[td.variant]], 22, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var facts: Array = td.def.get("facts", [])
	if not facts.is_empty():
		var fl := UiKit.label(str(facts[randi() % facts.size()]), 17, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fl.custom_minimum_size = Vector2(560, 0)
		v.add_child(fl)
	var resume := UiKit.button("Resume", func() -> void: race.toggle_pause(), 28, 360)
	v.add_child(resume)
	if race.req.mode != "cup" or race.req.cup_race > 0 or true:
		v.add_child(UiKit.button("Restart race", func() -> void: Game.restart(), 26, 360))
	var opts := UiKit.hbox(10)
	v.add_child(opts)
	var steer := UiKit.button("Steer: %s" % Save.setting("steering"), func() -> void: pass, 20, 175)
	steer.pressed.connect(func() -> void:
		var modes := ["joystick", "buttons", "tilt"]
		Save.set_setting("steering", modes[(modes.find(Save.setting("steering")) + 1) % modes.size()])
		steer.text = "Steer: %s" % Save.setting("steering")
		InputRouter.calibrate_tilt())
	opts.add_child(steer)
	var cam := UiKit.button("Camera: %s" % Save.setting("camera"), func() -> void: pass, 20, 175)
	cam.pressed.connect(func() -> void:
		Save.set_setting("camera", "near" if Save.setting("camera") == "far" else "far")
		cam.text = "Camera: %s" % Save.setting("camera"))
	opts.add_child(cam)
	var help := UiKit.label(_help_text(), 18, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(560, 0)
	v.add_child(help)
	var quit_text := "Quit cup" if race.req.mode == "cup" else "Quit to menu"
	v.add_child(UiKit.button(quit_text, func() -> void: Game.go_menu(), 24, 360))
	UiKit.focus_later(resume)
	return root


static func _help_text() -> String:
	if InputRouter.touch_seen:
		return "Hold DRIFT while steering to slide and charge Plasma Boost; let go to boost. In the air, DRIFT does a TRICK. Grab Energy Pods to keep your core charged."
	return "Steer A/D or arrows · Gas W/Up · Brake S/Down · Drift Space/Shift (in the air: trick) · Item E/Ctrl · Look back Q/C · Pause Esc. Gamepad: RT gas, LT brake, RB drift, X/LB item."
