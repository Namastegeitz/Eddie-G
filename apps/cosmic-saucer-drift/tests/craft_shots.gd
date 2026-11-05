extends Node3D
## Renders every craft (3/4 view) and close-ups of every pilot's face, for
## checking the HD models and for the store/docs screenshots.
## xvfb-run godot --path . res://tests/craft_shots.tscn --rendering-driver opengl3 -- --out=docs/screenshots/craft [--only=classic,orb] [--quality=ultra]

func _ready() -> void:
	Save.disabled = true
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var out: String = args.get("out", "docs/screenshots/craft")
	Save.data.settings.quality = args.get("quality", "ultra")
	DirAccess.make_dir_recursive_absolute(_abs(out))
	DisplayServer.window_set_size(Vector2i(int(args.get("w", "960")), int(args.get("h", "640"))))
	var stage := MenuStage.new()
	add_child(stage)
	stage.frame(0.0)
	await get_tree().process_frame
	var only: PackedStringArray = String(args.get("only", "")).split(",", false)
	var mode: String = args.get("mode", "craft")
	if mode == "craft" or mode == "all":
		for s in Catalog.SAUCERS:
			if not only.is_empty() and not (s.id in only):
				continue
			stage.show_look({"saucer": s.id, "pilot": "zib", "paint": "stock", "decal": "none", "dome": "clear", "trail": "cyan"})
			stage.turntable.rotation.y = deg_to_rad(-35.0)
			stage.cam.position = Vector3(0, 2.6, 7.2)
			stage.cam.look_at(Vector3(0, 0.0, 0))
			await _settle(stage)
			await _save("%s/craft_%s.png" % [out, s.id])
	if mode == "pilots" or mode == "all":
		for p in Catalog.PILOTS:
			if not only.is_empty() and not (p.id in only):
				continue
			stage.show_look({"saucer": "bubble", "pilot": p.id, "paint": "stock", "decal": "none", "dome": "clear", "trail": "cyan"})
			stage.turntable.rotation.y = 0.0
			var head := stage.model.pilot_model.global_position
			stage.cam.position = head + Vector3(0.35, 0.35, -3.0)
			stage.cam.look_at(head)
			var moods := [PilotModel.Mood.NEUTRAL, PilotModel.Mood.GRIN, PilotModel.Mood.DIZZY, PilotModel.Mood.FOCUS]
			for m in moods:
				stage.model.mood = m
				await _settle(stage)
				await _save("%s/pilot_%s_%d.png" % [out, p.id, m])
	get_tree().quit()


func _settle(stage: MenuStage) -> void:
	stage.set_process(false)
	for i in 30:
		stage.model.animate(1.0 / 60.0, 0.4, false, 0, false, 0.3)
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


static func _abs(p: String) -> String:
	return p if p.begins_with("/") else ProjectSettings.globalize_path("res://" + p)


func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(_abs(path))
	print("saved ", path)
