extends Node
## A human-driven lap with only the gas key held (and a mouse nudge back), logging
## forward speed: a craft must never sit in reverse while gas is held.
##   xvfb-run -a godot --path . res://tests/drive_check.tscn --rendering-driver opengl3 -- --track=mars [--touch]

func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Save.disabled = true
	Save.data.settings.mouse_controls = true
	Save.data.settings.quality = "low"
	var req := Game.quick_request(String(args.get("track", "mars")), int(args.get("variant", "0")), 0)
	req.autopilot = false
	req.laps = 1
	Game.request = req
	var race: Race = load("res://scenes/race.tscn").instantiate()
	add_child(race)
	while not race.loaded:
		await get_tree().process_frame
	var me: Racer = race.racers[0]
	var w := InputEventKey.new()
	w.physical_keycode = KEY_W
	w.keycode = KEY_W
	w.pressed = true
	Input.parse_input_event(w)
	var back := 0.0
	var worst := 0.0
	var air := 0
	var glide := 0
	var t := 0.0
	var nudged := false
	while t < 75.0 and not me.finished:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		if not nudged and t > 6.0:
			nudged = true
			# A palm on the touchpad: the mouse lever goes 60 px back.
			Input.parse_input_event(w)   # keep W held
			for k in 2:
				var mm := InputEventMouseMotion.new()
				mm.relative = Vector2(0, 40)
				InputRouter._input(mm)
		if race.countdown_left > 0.0:
			continue
		var fwd := me.velocity.dot(me.heading)
		if not me.grounded:
			air += 1
		if me.gliding:
			glide += 1
		if fwd < -1.0:
			back += dt
			worst = minf(worst, fwd)
	print("DRIVE track=%s finished=%s t=%.1f reverse_s=%.2f worst=%.1f air_frames=%d glide_frames=%d lap=%d" % [
		args.get("track", "mars"), me.finished, t, back, worst, air, glide, me.lap])
	get_tree().quit()
