extends Node3D
## Renders baked HD craft meshes for checking orientation and quality:
## a top view (green arrow = the game's forward, -Z) and a 3/4 view each.
## xvfb-run godot --path . res://tools/meshy/craft_preview.tscn --rendering-driver opengl3 -- --out=DIR res://a_lod.res,res://b_lod.res

func _ready() -> void:
	var out := "res://"
	var meshes := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		else:
			meshes = a.split(",", false)
	DisplayServer.window_set_size(Vector2i(900, 600))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.6)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 210, 0)
	fill.light_energy = 0.5
	add_child(fill)
	var cam := Camera3D.new()
	cam.fov = 35.0
	add_child(cam)
	cam.current = true
	var arrow := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(0.03, 0.01, 0.4)
	arrow.mesh = am
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(0.2, 1, 0.3)
	amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow.material_override = amat
	arrow.position = Vector3(0, 0.25, -0.75)
	add_child(arrow)
	for path in meshes:
		var mi := MeshInstance3D.new()
		mi.mesh = load(path)
		var mat_path := path.replace("_lod.res", "_mat.tres")
		if ResourceLoader.exists(mat_path):
			mi.material_override = load(mat_path)
		add_child(mi)
		var name := path.get_file().get_basename() + "_" + path.get_base_dir().get_file()
		for view in [["top", Vector3(0, 2.2, 0.001), Vector3.ZERO], ["34", Vector3(1.1, 0.7, 1.3), Vector3.ZERO], ["front", Vector3(0.0, 0.25, -1.9), Vector3.ZERO]]:
			cam.position = view[1]
			cam.look_at(view[2], Vector3.FORWARD if view[0] == "top" else Vector3.UP)
			arrow.visible = view[0] == "top"
			for i in 6:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var dst: String = "%s/%s_%s.png" % [out, name, view[0]]
			get_viewport().get_texture().get_image().save_png(dst)
			print("saved ", dst)
		mi.queue_free()
	get_tree().quit()
