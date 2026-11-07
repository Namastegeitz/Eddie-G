class_name MenuStage
extends Node3D
## 3D backdrop for the menus: space sky, a planet, and the player's saucer
## turning on a glowing pad. Also the live preview in the Garage.

var turntable: Node3D
var model: SaucerModel
var cam: Camera3D
var _look := {}
var _t := 0.0
var _pilot_focus := false      # Racers page: turn the craft to face us, zoom onto the pilot
var _cam_pos := Vector3(0, 3.0, 12.5)
var _cam_aim := Vector3(0, -0.2, 0)


func _ready() -> void:
	var theme := Themes.get_theme("saturn")
	var qs := Gfx.q()
	Gfx.apply_viewport(get_viewport(), qs)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/space_sky.gdshader")
	Themes.apply_sky(sm, theme)
	sm.set_shader_parameter("sun1_size", 0.0)
	sky.sky_material = sm
	sm.set_shader_parameter("detail", float(qs.sky_detail))
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.4, 0.6)
	env.ambient_light_energy = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY if bool(qs.reflect) else Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = bool(qs.glow)
	env.glow_intensity = 0.8
	env.glow_hdr_threshold = 0.95
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	Gfx.apply_sun(sun, qs)
	if sun.shadow_enabled:
		sun.directional_shadow_max_distance = 30.0
	# Studio rim lights: cyan from behind-left, magenta from behind-right.
	for l in [[Vector3(-6, 3, -5), Color(0.3, 0.85, 1.0), 2.2], [Vector3(6, 2, -4), Color(1.0, 0.35, 0.85), 1.6]]:
		var o := OmniLight3D.new()
		o.position = l[0]
		o.light_color = l[1]
		o.light_energy = l[2]
		o.omni_range = 14.0
		add_child(o)
	var planet := MeshInstance3D.new()
	var ps := SphereMesh.new()
	ps.radius = 60.0
	ps.height = 120.0
	ps.radial_segments = 48
	ps.rings = 24
	planet.mesh = ps
	var pm := ShaderMaterial.new()
	pm.shader = preload("res://shaders/planet.gdshader")
	pm.set_shader_parameter("color_a", theme.planets[0].a)
	pm.set_shader_parameter("color_b", theme.planets[0].b)
	pm.set_shader_parameter("rim_color", theme.planets[0].rim)
	pm.set_shader_parameter("detail", 1.0 if int(qs.detail) > 1 else 0.0)   # full-cost surface only on High/Ultra
	pm.set_shader_parameter("bands", 12.0)
	pm.set_shader_parameter("sun_dir", Vector3(0.6, 0.5, 0.4))
	planet.material_override = pm
	planet.position = Vector3(-90, 18, -160)
	add_child(planet)
	var ring := MeshInstance3D.new()
	var rp := PlaneMesh.new()
	rp.size = Vector2(280, 280)
	ring.mesh = rp
	var rm := ShaderMaterial.new()
	rm.shader = preload("res://shaders/ring.gdshader")
	ring.material_override = rm
	ring.position = planet.position
	ring.rotation_degrees = Vector3(14, 0, -10)
	add_child(ring)
	var pad := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 3.4
	cyl.bottom_radius = 3.8
	cyl.height = 0.4
	cyl.radial_segments = 40
	pad.mesh = cyl
	pad.material_override = TrackBuilder.flat(Color(0.12, 0.1, 0.22), 0.0, 0.8, 0.3)
	pad.position = Vector3(0, -1.4, 0)
	add_child(pad)
	var glow_ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 3.45
	tm.outer_radius = 3.65
	tm.rings = 48
	glow_ring.mesh = tm
	glow_ring.material_override = TrackBuilder.glow(UiKit.CYAN, 2.2)
	glow_ring.position = Vector3(0, -1.2, 0)
	add_child(glow_ring)
	turntable = Node3D.new()
	add_child(turntable)
	cam = Camera3D.new()
	cam.fov = 40.0
	cam.far = 1000.0
	add_child(cam)
	cam.position = Vector3(0, 3.0, 12.5)
	cam.look_at(Vector3(0, -0.2, 0))
	cam.current = true
	# Compile the race's shaders now, behind the menu, so the first race
	# doesn't stutter on each material's first draw.
	ShaderWarmup.run(cam)
	show_look(Save.player_look())


func show_look(look: Dictionary) -> void:
	if look == _look:
		return
	_look = look.duplicate()
	if model:
		model.queue_free()
	model = SaucerModel.new()
	turntable.add_child(model)
	model.build(look)


## Close-up on the pilot in the cockpit (Racers page) or back to the craft.
func focus_pilot(on: bool) -> void:
	_pilot_focus = on


## Shift the saucer sideways so it sits beside the menu panel.
func frame(offset_x: float) -> void:
	var tw := create_tween()
	tw.tween_property(turntable, "position:x", offset_x, 0.35).set_trans(Tween.TRANS_SINE)


func _process(dt: float) -> void:
	_t += dt
	var want_pos := Vector3(0, 3.0, 12.5)
	var want_aim := Vector3(0, -0.2, 0)
	if _pilot_focus and model and model.pilot_model:
		# Face the camera with a slow sway, and frame the pilot to the right
		# of the menu panel.
		turntable.rotation.y = lerp_angle(turntable.rotation.y, PI + sin(_t * 0.7) * 0.35, 1.0 - exp(-3.0 * dt))
		var head := model.pilot_model.global_position
		want_pos = head + Vector3(-0.9, 0.7, 4.2)
		want_aim = head + Vector3(-1.6, -0.1, 0)
	else:
		turntable.rotation.y += dt * 0.6
	var k := 1.0 - exp(-5.0 * dt)
	_cam_pos = _cam_pos.lerp(want_pos, k)
	_cam_aim = _cam_aim.lerp(want_aim, k)
	if cam.position.distance_squared_to(_cam_pos) > 1e-6 or _pilot_focus:
		cam.position = _cam_pos
		cam.look_at(_cam_aim)
	if model and model.pivot:
		model.pivot.position.y = sin(_t * 2.0) * 0.15
		model.pivot.rotation.z = sin(_t * 1.3) * 0.06
		model.animate(dt, 0.4, false, 0, false, 0.3)
