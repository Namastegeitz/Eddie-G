extends Node
## Screenshots the glide: lifts the player's saucer into the air over the
## track so the wings unfold, from the chase camera and looking back.
## xvfb-run godot --path . res://tests/glide_shot.tscn --rendering-driver opengl3 -- --out=/tmp/glide [--track=io]

func _ready() -> void:
	Save.disabled = true
	Save.data = Save.defaults()
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var out: String = args.get("out", "/tmp/glide")
	DirAccess.make_dir_recursive_absolute(out)
	Save.data.settings.quality = args.get("quality", "high")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var req := Game.quick_request(args.get("track", "io"), 0, 2)
	req.autopilot = true
	req.fast = true
	Game.request = req
	var race: Race = load("res://scenes/race.tscn").instantiate()
	add_child(race)
	while not race.racing:
		await get_tree().process_frame
	for i in 120:
		await get_tree().process_frame
	var me: Racer = race.racers[0]
	var td := race.td
	for k in [0, 1]:
		# Drive off the skyway ramp (or, on a track without one, a short hop).
		if td.short_glide:
			var path := td.main
			var lane := float(td.short_side) * (td.width * 0.5 - 5.0)
			var i := path.index_at(td.short_a - 20.0)
			me.global_position = path.pts[i] + path.rgt[i] * lane + path.upv[i] * 0.9
			me.heading = path.tan[i]
			me.up = path.upv[i]
			me.track_idx = i
			me.velocity = me.heading * 48.0
			me.controller = null
			me.is_human = true      # the AI never glides; shoot a player's run
			me.auto_glide = true
			me.in_throttle = 1.0
			me.in_steer = 0.0
		else:
			me.is_human = true
			me.auto_glide = true
			me.global_position += me.up * 8.0
			me.velocity = me.heading * 40.0
		me.reset_physics_interpolation()
		me.in_look_back = k == 1
		Engine.time_scale = 0.25
		for i in 140:
			if td.short_glide:
				# Aim at the strip as a player would.
				var aim: Vector3 = td.skyway.to + (td.skyway.dir as Vector3) * 60.0 - me.global_position
				var rgt := me.heading.cross(me.up).normalized()
				me.in_steer = clampf(atan2(aim.dot(rgt), aim.dot(me.heading)) * 2.0, -1.0, 1.0)
			await get_tree().process_frame
			if me.gliding and me.air_time > (0.7 if k == 0 else 1.3):
				break
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/glide_%d.png" % [out, k])
		print("saved glide_%d gliding=%s" % [k, me.gliding])
		Engine.time_scale = 1.0
		me.in_look_back = false
		for i in 150:
			await get_tree().process_frame
		print("after flight: on_shortcut=%s rescues=%d" % [me.on_shortcut, me.stats.hover_count])
	get_tree().quit()
