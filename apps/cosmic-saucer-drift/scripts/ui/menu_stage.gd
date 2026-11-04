class_name MenuStage
extends Node3D
## 3D backdrop for the menus: space sky, a planet, and the player's saucer
## turning on a glowing pad. Also the live preview in the Garage.

var turntable: Node3D
var model: SaucerModel
var cam: Camera3D
var _look := {}
var _t := 0.0


func _ready() -> void:
	var theme := Themes.get_theme("saturn")
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/space_sky.gdshader")
	Themes.apply_sky(sm, theme)
	sm.set_shader_parameter("sun1_size", 0.0)
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.4, 0.6)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = Game.quality() != "low"
	env.glow_intensity = 0.8
	env.glow_hdr_threshold = 0.95
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)
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


## Shift the saucer sideways so it sits beside the menu panel.
func frame(offset_x: float) -> void:
	var tw := create_tween()
	tw.tween_property(turntable, "position:x", offset_x, 0.35).set_trans(Tween.TRANS_SINE)


func _process(dt: float) -> void:
	_t += dt
	turntable.rotation.y += dt * 0.6
	if model and model.pivot:
		model.pivot.position.y = sin(_t * 2.0) * 0.15
		model.pivot.rotation.z = sin(_t * 1.3) * 0.06
		model.animate(dt, 0.4, false, 0, false, 0.3)
