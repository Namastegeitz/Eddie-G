extends Node
## Screenshots the loading screen and the first race frame of a normal (not
## fast) start. Needs a display (xvfb-run + opengl3).
## xvfb-run godot --path . res://tests/loading_shot.tscn --rendering-driver opengl3 -- --out=/tmp/loading

func _ready() -> void:
	Save.disabled = true
	Save.data = Save.defaults()
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var out: String = args.get("out", "/tmp/loading")
	DirAccess.make_dir_recursive_absolute(out)
	Save.data.settings.quality = args.get("quality", "high")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var holder := Node.new()
	get_tree().root.add_child.call_deferred(holder)
	await get_tree().process_frame
	get_tree().current_scene = holder
	var req := Game.quick_request(args.get("track", "saturn_rings"), 0, 2)
	req.autopilot = true
	Game.start(req)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/loading_1.png")
	var race: Race = null
	var shots := 0
	for f in 600:
		await get_tree().process_frame
		race = get_tree().current_scene as Race
		if race != null and not race.loaded and shots < 2 and f % 3 == 0:
			await RenderingServer.frame_post_draw
			shots += 1
			get_viewport().get_texture().get_image().save_png("%s/loading_%d.png" % [out, shots + 1])
		if race != null and race.loaded:
			break
	print("loaded after %d frames: %s" % [f_count(), str(race != null and race.loaded)])
	for f in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/race_first.png")
	print("saved")
	get_tree().quit()


func f_count() -> int:
	return Engine.get_process_frames()
