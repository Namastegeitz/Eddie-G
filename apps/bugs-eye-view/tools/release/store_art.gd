extends TestBase
## Renders store art from the real game, at the window size it runs at:
## key art and the app icon (no HUD) and gameplay screenshots (with the HUD).
## Needs a display (xvfb on a server). tools/release/make_store_assets.sh runs
## it at every size the stores ask for, then compose_store_assets.py crops and
## titles the results.
##
##   xvfb-run -a -s "-screen 0 3840x2400x24" godot --path . --resolution 1920x1080 \
##       res://tools/release/store_art.tscn -- --out=/path/to/dir [--only=keyart,trap] [--touch]

const SHOTS := ["keyart", "icon", "kitchen", "dominoes", "slap", "fridge", "trap", "bugeye"]

var out := "user://store_art"
var only: PackedStringArray = []
var touch_ui := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
		elif a == "--touch":
			touch_ui = true
	DirAccess.make_dir_recursive_absolute(out)
	GameManager.guides_enabled = false
	GameManager.auto_quality_enabled = false
	SaveSystem.save_path = "user://store_art_save.json"
	SaveSystem.data = SaveSystem.default_data()
	SaveSystem.set_setting("quality", "high")
	SaveSystem.set_setting("touch_controls", "on" if touch_ui else "off")
	GameManager.apply_quality()
	await get_tree().process_frame
	for s: String in SHOTS:
		if only.is_empty() or only.has(s):
			await call("_shot_" + s)
	get_tree().quit()


func _save(shot: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(out.path_join(shot + ".png"))
	print("STORE_ART ", shot, " ", img.get_width(), "x", img.get_height())


func _hud(lvl: Level, on: bool) -> void:
	var hud := lvl.find_child("HUD", true, false) as CanvasLayer
	if hud:
		hud.visible = on


func _cam(lvl: Level, from: Vector3, at: Vector3, fov: float = 55.0) -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = fov
	lvl.add_child(cam)
	cam.current = true
	lvl.camera.process_mode = Node.PROCESS_MODE_DISABLED
	cam.look_at_from_position(from, at)
	return cam


func _human(lvl: Level) -> Human:
	for n in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
		if lvl.is_ancestor_of(n):
			return n as Human
	return null


func _pets_away(lvl: Level) -> void:
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PET):
		if lvl.is_ancestor_of(n):
			(n as Node3D).global_position = Vector3(95, 0.5, 95)
			(n as Node).process_mode = Node.PROCESS_MODE_DISABLED


func _place(h: Human, pos: Vector3, yaw: float) -> void:
	h.force_present(true)
	h.end_activity()
	h.route = PackedVector3Array()
	h.global_position = pos
	h._body_pos = pos
	h.rotation.y = yaw
	h._plant_feet(pos, yaw)
	h._body_vel = Vector3.ZERO
	h._glide_dur = 0.0
	h.reset_physics_interpolation()


# --- The shots -----------------------------------------------------------------

## The cockroach underfoot as a stomp comes down: the cover image.
func _shot_keyart() -> void:
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(8.2)
	_hud(lvl, false)
	_pets_away(lvl)
	var p := lvl.player
	p.invuln = 1000.0
	var h := _human(lvl)
	_place(h, Vector3(24, 0, -6), 0.0)
	p.teleport_to(Transform3D(Basis(Vector3.UP, PI * 0.12), Vector3(27.5, 0.45, 9.5)))
	await frames(20)
	_cam(lvl, Vector3(28.9, 1.1, 13.4), Vector3(25.8, 6.2, -1), 66.0)
	h._stomp(Vector3(28.0, 0, 8.0), 1.4)
	await frames(48)
	await _save("keyart")
	await unload(lvl)


## The app icon: the cockroach alone, lit like a portrait, on a transparent
## background (compose_store_assets.py puts it on the warm gradient).
func _shot_icon() -> void:
	get_viewport().transparent_bg = true
	var world := Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.92, 0.82)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-42, -35, 0)
	key_light.light_energy = 1.3
	world.add_child(key_light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 150, 0)
	rim.light_energy = 0.8
	rim.light_color = Color(1.0, 0.8, 0.5)
	world.add_child(rim)
	var bug := (load("res://scenes/bugs/cockroach.tscn") as PackedScene).instantiate()
	var vis := bug.get_node("Visual") as Node3D
	bug.remove_child(vis)
	bug.free()
	world.add_child(vis)
	vis.rotation.y = PI * 0.78
	await frames(1)
	# Centre the whole bug (legs and antennae included) and back the camera
	# off until it fits, seen from a three-quarter top view.
	var box := _visual_box(vis)
	vis.position -= box.get_center()
	var radius := box.size.length() * 0.5
	var cam := Camera3D.new()
	cam.fov = 30.0
	world.add_child(cam)
	cam.current = true
	var dist := radius / sin(deg_to_rad(cam.fov * 0.5)) * 0.7
	cam.look_at_from_position(Vector3(0.55, 0.62, 0.56).normalized() * dist, Vector3.ZERO)
	await frames(6)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join("icon_rgba.png"))
	print("STORE_ART icon_rgba ", img.get_width(), "x", img.get_height())
	world.queue_free()
	get_viewport().transparent_bg = false
	await frames(2)


func _visual_box(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in root.find_children("*", "VisualInstance3D", true, false):
		var vi := n as VisualInstance3D
		var b := vi.global_transform * vi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## Spotted in the kitchen: the cook turns, a stomp's shadow closes in.
func _shot_kitchen() -> void:
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(8.2)
	_pets_away(lvl)
	var p := lvl.player
	p.invuln = 1000.0
	var h := _human(lvl)
	_place(h, Vector3(24, 0, -8), 0.1)
	p.teleport_to(Transform3D(Basis(Vector3.UP, PI * 0.1), Vector3(27, 0.45, 8)))
	await frames(20)
	h.alert.force(AlertState.ALERT, p.global_position)
	_cam(lvl, Vector3(33, 7, 24), Vector3(25, 9, -2), 58.0)
	h._stomp(Vector3(27.5, 0, 6.0), 1.4)
	await frames(45)
	await _save("kitchen")
	await unload(lvl)


## A row of toy dominoes going down: CRASH, everyone looks.
func _shot_dominoes() -> void:
	var lvl := await load_level(&"living_room", &"cockroach")
	HouseClock.set_hour(10.0)
	var p := lvl.player
	p.invuln = 1000.0
	p.global_position = Vector3(-26, 17.5, -9)
	_cam(lvl, Vector3(-12, 27, 10), Vector3(-12, 17, -9), 52.0)
	var run := lvl.find_child("Dominoes", true, false) as DominoRun
	await frames(10)
	var first := run.get_child(0) as PhysicsProp
	for i in 8:
		first.push_by_bug(Vector3.RIGHT * 0.25)
		await get_tree().physics_frame
	await frames(70)
	await _save("dominoes")
	await unload(lvl)


## Up on the picnic table: the gardener leans over to slap at you.
func _shot_slap() -> void:
	var lvl := await load_level(&"backyard", &"cockroach")
	HouseClock.set_hour(10.0)
	_pets_away(lvl)
	var p := lvl.player
	p.invuln = 1000.0
	var g := _human(lvl)
	for n in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
		if lvl.is_ancestor_of(n) and String((n as Node).name).begins_with("Gardener"):
			g = n
	_place(g, Vector3(6, 0, 15), PI * 0.5)
	p.teleport_to(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-6, 27.4, 15)))
	await frames(10)
	_cam(lvl, Vector3(-16, 44, 62), Vector3(-4, 31, 15), 50.0)
	g._attack_cd = 0.0
	g._throw_cd = 999.0
	g.alert.force(AlertState.ALERT, p.global_position)
	await frames(44)
	await _save("slap")
	await unload(lvl)


## The fridge open from the floor: glass shelves of food overhead.
func _shot_fridge() -> void:
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	_pets_away(lvl)
	var p := lvl.player
	p.invuln = 1000.0
	for n in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
		if lvl.is_ancestor_of(n):
			(n as Node).process_mode = Node.PROCESS_MODE_DISABLED
			(n as Node3D).visible = false
	p.teleport_to(Transform3D(Basis(Vector3.UP, PI), Vector3(40, 0.45, -8)))
	var door := lvl.find_child("FridgeDoor", true, false) as SwingDoor
	door.open_for(30.0)
	await frames(70)
	_cam(lvl, Vector3(35, 4.5, 8), Vector3(43, 28, -24), 62.0)
	await frames(4)
	await _save("fridge")
	await unload(lvl)


## Snapped in a mouse trap in the walls: knocked out, the bar on your back.
func _shot_trap() -> void:
	var lvl := await load_level(&"kitchen_m1", &"cockroach")
	var p := lvl.player
	p.invuln = 0.0
	var trap := first_in_group(&"mouse_trap", lvl) as MouseTrap
	p.teleport_to(Transform3D(Basis.IDENTITY, trap.to_global(Vector3(0, 0.8, 1.4))))
	lvl.camera.pitch = -0.6
	await frames(50)
	await _save("trap")
	await unload(lvl)


## The bug's-eye view: looking up at a person from the floor.
func _shot_bugeye() -> void:
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(8.2)
	_pets_away(lvl)
	var p := lvl.player
	p.invuln = 1000.0
	var h := _human(lvl)
	_place(h, Vector3(25, 0, -6), 0.0)
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(26, 0.45, 9)))
	await frames(10)
	lvl.camera.yaw = 0.0
	lvl.camera.set_first_person(true)
	lvl.camera.pitch = 0.35
	lvl.camera.snap()
	await frames(30)
	await _save("bugeye")
	await unload(lvl)
