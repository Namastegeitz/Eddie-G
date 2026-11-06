extends Node
## Renders an icon of every showcase piece (treasures and crumb gems) for the
## Showcase screen: assets/icons/items/<id>.png. Needs a display (or xvfb):
##   xvfb-run -a godot --rendering-driver opengl3 --path . res://tools/render_item_icons.tscn

const SIZE := 160


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
	e.ambient_light_color = Color(0.95, 0.92, 0.88)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -30, 0)
	key.light_energy = 1.4
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 150, 0)
	rim.light_energy = 0.7
	vp.add_child(rim)
	var cam := Camera3D.new()
	cam.fov = 30
	vp.add_child(cam)
	cam.current = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/icons/items"))
	for id in Collection.all_ids():
		var item := (load("res://scenes/items/%s.tscn" % id) as PackedScene).instantiate() as Node3D
		item.process_mode = Node.PROCESS_MODE_DISABLED
		vp.add_child(item)
		for extra in ["Halo", "Beam", "Visual/Sparkles", "Visual/Glow", "Visual/Skin"]:
			var n := item.get_node_or_null(extra)
			if n:
				n.get_parent().remove_child(n)
				n.free()
		var visual := item.get_node("Visual") as Node3D
		visual.rotation.y = 0.5
		var box := SkinAnchor.mesh_bounds(visual, item)
		var c := box.get_center()
		var r := box.size.length() * 0.5
		var dist := r / tan(deg_to_rad(cam.fov * 0.5)) * 1.1
		cam.look_at_from_position(c + Vector3(0.0, 0.45, 1.0).normalized() * dist, c)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("res://assets/icons/items/%s.png" % id))
		print("icon ", id)
		item.queue_free()
		await get_tree().process_frame
	get_tree().quit()
