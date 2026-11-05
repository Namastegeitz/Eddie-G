extends Node3D
## Renders the app icon: deep space with nebula clouds, a ringed gas giant,
## a blue planet with a glowing atmosphere, a cratered moon and a bright
## star, using the game's own sky / planet / ring shaders.
## xvfb-run -a godot --path . res://tools/make_space_icon.tscn --rendering-driver opengl3 -- --out=/tmp/space_icon.png [--size=1024]

const NEBULA := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform vec3 c1 : source_color = vec3(0.95, 0.25, 0.75);
uniform vec3 c2 : source_color = vec3(0.2, 0.55, 1.0);
uniform vec3 c3 : source_color = vec3(0.55, 0.3, 1.0);
uniform float power = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int k = 0; k < 6; k++) { v += a * vnoise(p); p = p * 2.03 + 7.1; a *= 0.5; }
	return v;
}
void fragment() {
	vec2 p = UV * 3.2;
	vec2 w = vec2(fbm(p + 1.7), fbm(p + 9.2));
	float n = fbm(p + w * 2.2);
	float m = fbm(p * 1.7 - w + 4.0);
	float lanes = smoothstep(0.52, 0.7, fbm(p * 2.4 + 13.0));
	vec3 col = mix(c1, c2, smoothstep(0.3, 0.75, m));
	col = mix(col, c3, smoothstep(0.55, 0.85, n) * 0.6);
	float dens = smoothstep(0.38, 0.85, n) * (1.0 - lanes * 0.75);
	float edge = smoothstep(0.0, 0.25, UV.x) * smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.75, UV.x) * smoothstep(1.0, 0.75, UV.y);
	float core = exp(-length(UV - vec2(0.62, 0.38)) * 4.0);
	ALBEDO = (col * dens * 0.9 + vec3(1.0, 0.75, 0.95) * core * dens * 0.8) * edge * power;
}
"""


var _root: Node3D


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var size := int(args.get("size", "1024"))
	var out: String = args.get("out", "/tmp/space_icon.png")
	var sv := SubViewport.new()
	sv.size = Vector2i(size, size)
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.own_world_3d = true
	add_child(sv)
	_root = Node3D.new()
	sv.add_child(_root)
	# Sky: deep purple-blue with nebula and lots of stars.
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/space_sky.gdshader")
	sm.set_shader_parameter("top_color", Color(0.02, 0.01, 0.07))
	sm.set_shader_parameter("bottom_color", Color(0.08, 0.02, 0.14))
	sm.set_shader_parameter("nebula_a", Color(0.85, 0.2, 0.7))
	sm.set_shader_parameter("nebula_b", Color(0.15, 0.4, 0.95))
	sm.set_shader_parameter("nebula_strength", 1.0)
	sm.set_shader_parameter("star_amount", 0.978)
	sm.set_shader_parameter("detail", 1.0)
	sm.set_shader_parameter("sun1_dir", Vector3(-0.42, 0.42, -0.8))
	sm.set_shader_parameter("sun1_color", Color(1.0, 0.92, 0.8))
	sm.set_shader_parameter("sun1_size", 0.012)
	sky.sky_material = sm
	env.sky = sky
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.8
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	_root.add_child(we)
	var cam := Camera3D.new()
	cam.fov = 48.0
	cam.far = 10000.0
	_root.add_child(cam)
	cam.current = true
	var sun_dir := Vector3(-0.55, 0.45, 0.7).normalized()   # light comes from upper left, toward the viewer
	# Nebula clouds on a big quad far behind the planets.
	var neb := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2600, 2600)
	neb.mesh = qm
	var nm := ShaderMaterial.new()
	var ns := Shader.new()
	ns.code = NEBULA
	nm.shader = ns
	nm.set_shader_parameter("power", 1.25)
	neb.material_override = nm
	neb.position = Vector3(0, 0, -2000)
	_root.add_child(neb)
	# Ringed gas giant, lower left.
	_planet(Vector3(-46, -40, -420), 78.0, Color(0.98, 0.78, 0.45), Color(0.82, 0.42, 0.25), Color(1.0, 0.75, 0.5), 13.0, sun_dir, true)
	# Blue world with swirling clouds, upper right.
	_planet(Vector3(92, 88, -440), 34.0, Color(0.35, 0.75, 1.0), Color(0.1, 0.25, 0.75), Color(0.45, 0.85, 1.0), 11.0, sun_dir, false)
	# Small cratered moon.
	_planet(Vector3(40, 18, -330), 10.0, Color(0.82, 0.8, 0.84), Color(0.5, 0.48, 0.55), Color(0.85, 0.85, 1.0), 4.0, sun_dir, false)
	# A tiny far planet for depth.
	_planet(Vector3(-110, 120, -800), 11.0, Color(1.0, 0.5, 0.6), Color(0.6, 0.2, 0.4), Color(1.0, 0.6, 0.8), 5.0, sun_dir, false)
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	img.save_png(out)
	print("saved ", out)
	get_tree().quit()


func _planet(pos: Vector3, r: float, a: Color, b: Color, rim: Color, bands: float, sun_dir: Vector3, ring: bool, atmo := false) -> void:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 96
	sph.rings = 48
	mi.mesh = sph
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/planet.gdshader")
	m.set_shader_parameter("color_a", a)
	m.set_shader_parameter("color_b", b)
	m.set_shader_parameter("rim_color", rim)
	m.set_shader_parameter("bands", bands)
	m.set_shader_parameter("sun_dir", sun_dir)
	m.set_shader_parameter("detail", 1.0)
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = Vector3(18, 30, -14)
	_root.add_child(mi)
	if atmo:
		var sh := MeshInstance3D.new()
		var s2 := SphereMesh.new()
		s2.radius = r * 1.09
		s2.height = r * 2.18
		s2.radial_segments = 96
		s2.rings = 48
		sh.mesh = s2
		var am := ShaderMaterial.new()
		am.shader = preload("res://shaders/atmo.gdshader")
		am.set_shader_parameter("color", rim)
		am.set_shader_parameter("sun_dir", sun_dir)
		am.set_shader_parameter("inner", 1.0 / 1.09)
		sh.material_override = am
		sh.position = pos
		_root.add_child(sh)
	if ring:
		var rg := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(r * 4.6, r * 4.6)
		rg.mesh = pm
		var rm := ShaderMaterial.new()
		rm.shader = preload("res://shaders/ring.gdshader")
		rm.set_shader_parameter("color_a", Color(1.0, 0.9, 0.7))
		rm.set_shader_parameter("color_b", Color(0.75, 0.55, 0.45))
		rg.material_override = rm
		rg.position = pos
		rg.rotation_degrees = Vector3(-13, 0, 20)
		_root.add_child(rg)
