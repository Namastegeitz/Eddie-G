extends Node
## Renders a portrait of every bug (transparent PNG) for the bug select
## screen: assets/icons/bugs/<id>.png. Needs a display (GPU or xvfb):
##   xvfb-run -a godot --rendering-driver opengl3 --path . res://tools/render_portraits.tscn

const SIZE := 320


func _ready() -> void:
	await get_tree().process_frame
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.88, 0.85)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -35, 0)
	key.light_energy = 1.3
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 150, 0)
	rim.light_energy = 0.6
	vp.add_child(rim)
	var cam := Camera3D.new()
	cam.fov = 30
	vp.add_child(cam)
	cam.current = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/icons/bugs"))
	for id in GameManager.BUG_IDS:
		var stats := GameManager.get_bug_stats(id)
		var bug := (load(stats.scene_path) as PackedScene).instantiate() as Node3D
		bug.process_mode = Node.PROCESS_MODE_DISABLED
		vp.add_child(bug)
		var arrow := bug.get_node_or_null("SenseArrow") as Node3D
		if arrow:
			arrow.visible = false
		var line := bug.get_node_or_null("ZipLine") as Node3D
		if line:
			line.visible = false
		var visual := bug.get_node("Visual") as Node3D
		visual.rotation.y = 0.7
		if id == &"fly" or id == &"firefly":
			for w in ["WingL", "WingR"]:
				var wing := visual.get_node_or_null(w) as Node3D
				if wing:
					wing.rotation.z = 0.35 * (1.0 if w == "WingL" else -1.0)
		var box := SkinAnchor.mesh_bounds(visual, bug)
		var c := box.get_center()
		var r := box.size.length() * 0.5
		var dist := r / tan(deg_to_rad(cam.fov * 0.5)) * 1.05
		cam.look_at_from_position(c + Vector3(0.0, 0.6, -1.0).normalized() * dist, c)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("res://assets/icons/bugs/%s.png" % id))
		print("portrait ", id)
		bug.queue_free()
		await get_tree().process_frame
	get_tree().quit()
