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
	for k in [0, 1]:
		me.global_position += me.up * 26.0
		me.velocity = me.heading * 40.0
		me.reset_physics_interpolation()
		me.in_look_back = k == 1
		Engine.time_scale = 0.25
		for i in 40:
			await get_tree().process_frame
			if me.gliding and i > 12:
				break
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/glide_%d.png" % [out, k])
		print("saved glide_%d gliding=%s" % [k, me.gliding])
		Engine.time_scale = 1.0
		me.in_look_back = false
		for i in 90:
			await get_tree().process_frame
	get_tree().quit()
