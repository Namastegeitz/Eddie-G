extends Node
## Renders screenshots of races (needs a display: xvfb-run + opengl3).
## godot --path . res://tests/shots.tscn --rendering-driver opengl3 -- --tracks=a,b --frames=420,900 --out=docs/screenshots

func _ready() -> void:
	Save.disabled = true
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var tracks: PackedStringArray = args.get("tracks", ",".join(Catalog.TRACK_IDS)).split(",")
	var frames: PackedStringArray = args.get("frames", "420").split(",")
	var out: String = args.get("out", "docs/screenshots")
	var variant := int(args.get("variant", "0"))
	if args.has("quality"):
		Save.data.settings.quality = args.quality
	DisplayServer.window_set_size(Vector2i(720, 1280) if args.has("portrait") else Vector2i(1280, 720))
	await get_tree().process_frame
	Game.fit_orientation()
	for t in tracks:
		var req := Game.quick_request(t, variant, 2)
		req.autopilot = true
		if args.get("mode", "") == "versus":
			req = Game.versus_request(t, variant, 2)
			req.bot_humans = true
			InputRouter.two_player = true
		req.laps = 3
		Game.request = req
		var race: Race = load("res://scenes/race.tscn").instantiate()
		add_child(race)
		if args.has("cockpit"):
			race._set_cockpit(race.racers[0], true)
		if args.has("hints"):
			InputRouter.touch_seen = false
			var dh := DesktopHints.new()
			dh.racer = race.racers[0]
			race.ui_layer.add_child(dh)
			if args.has("mouse"):
				InputRouter.mouse_active = true
				InputRouter.mouse_stick = Vector2(0.6, 0.7)
		if args.has("touch"):
			InputRouter.touch_seen = true
			var tc := TouchControls.new()
			tc.racer = race.racers[0]
			race.ui_layer.add_child(tc)
			race.touch = tc
			race.huds[0].add_pause(race._pause_button())
		var f := 0
		for target in frames:
			while f < int(target):
				await get_tree().process_frame
				f += 1
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var path := "%s/%s_v%d_f%s%s%s%s%s%s.png" % [out, t, variant, target, ("_" + str(args.quality)) if args.has("quality") else "", "_ck" if args.has("cockpit") else "", "_portrait" if args.has("portrait") else "", "_touch" if args.has("touch") else "", ("_mouse" if args.has("mouse") else "_keys") if args.has("hints") else ""]
			img.save_png(ProjectSettings.globalize_path("res://" + path) if not path.begins_with("/") else path)
			print("saved ", path)
		race.queue_free()
		await get_tree().process_frame
	get_tree().quit()
