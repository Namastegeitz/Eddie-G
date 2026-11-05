extends Node3D
## Renders the detailed first-person models (log, rolling log, caiman back,
## crocodile jaws, giant red soldier ant) to one picture for checking.
##   xvfb-run godot --path . --rendering-driver opengl3 res://tools/model_sheet.tscn -- --no-boot --out=/tmp/models.png

func _ready() -> void:
	var out := "user://models.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	Draw.detail = 2
	var vp := SubViewport.new()
	vp.size = Vector2i(1400, 900)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var root := Node3D.new()
	vp.add_child(root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("2a4a3a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.92, 0.82)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 0.9
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.position = Vector3(0.2, 1.7, 3.1)
	cam.rotation_degrees = Vector3(-27, 0, 0)
	cam.fov = 60
	root.add_child(cam)
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 1.4)
	water.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color("3a7a78")
	wm.roughness = 0.2
	water.material_override = wm
	water.position = Vector3(0, -0.1, 0.4)
	root.add_child(water)
	var log_hz := Content.hazard("floating_log")
	var lg := Node3D.new()
	Models3D._mi(Models3D.log_mesh("floating_log", 2.0, log_hz.art.colors, true), Models3D.matte(), lg)
	lg.position = Vector3(-1.6, 0.05, 0.4)
	root.add_child(lg)
	var cb_hz := Content.hazard("caiman_back")
	var cb := Node3D.new()
	Models3D._mi(Models3D.caiman_back("caiman_back", 1.9, cb_hz.art.colors), Models3D.gloss(), cb)
	cb.position = Vector3(1.3, 0.0, 0.4)
	cb.rotation_degrees.y = -20
	root.add_child(cb)
	var croc_hz := Content.hazard("caiman")
	var head := Node3D.new()
	var upper := Node3D.new()
	upper.name = "Upper"
	upper.position = Vector3(-0.6, 0.08, 0)
	head.add_child(upper)
	Models3D.croc_head(head, 1.2, croc_hz.art.colors)
	upper.rotation_degrees.z = -30
	head.position = Vector3(-0.2, 0.0, 1.1)
	head.rotation_degrees.y = 25
	root.add_child(head)
	var ant_hz := Content.hazard("red_soldier_ants")
	for i in 2:
		var ant := Node3D.new()
		Models3D.soldier_ant(ant, 0.9, ant_hz.art.colors)
		ant.position = Vector3(-1.0 + i * 1.9, 0.0, -0.75)
		ant.rotation_degrees.y = 30 if i == 0 else -150
		root.add_child(ant)
	var rl_hz := Content.hazard("rolling_log")
	var rl := Node3D.new()
	Models3D._mi(Models3D.log_mesh("rolling_log", 1.6, rl_hz.art.colors, false), Models3D.matte(), rl)
	rl.position = Vector3(0.0, 0.3, -1.9)
	root.add_child(rl)
	for f in 4:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
