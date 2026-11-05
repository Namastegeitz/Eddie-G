class_name ItemModels
extends RefCounted
## Detailed models for the power-ups, built from MeshKit parts: the homing
## rocket (panelled body, fins, live flame, smoke trail), the gravity mine
## (spiked core, blinking light, gravity ring), the comet (glowing ice rock
## with a flaming tail), energy beams (laser, tractor), lock-on and impact
## target markers, nitro boosters, the held-shield badge and lightning bolts.

static var _beam_mesh: CylinderMesh = null
static var _bolt_mesh: BoxMesh = null
static var _reticle_shader: Shader = preload("res://shaders/reticle.gdshader")
static var _beam_shader: Shader = preload("res://shaders/beam.gdshader")


static func _xf(pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot * (PI / 180.0)) * Basis.from_scale(scl), pos)


static func _bake(parent: Node3D, m: MeshKit.Merger) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _std(c: Color, metal := 0.6, rough := 0.3, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	m.rim_enabled = true
	m.rim = 0.4
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


static func _glow(c: Color, e := 2.2) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c * e
	return m


## Engine flame pointing down local -Y from the origin (scale x/z = radius,
## y = length). Two layers: coloured outer, white-hot core.
static func flame(c: Color, r: float, length: float) -> Node3D:
	var node := Node3D.new()
	var prof := PackedVector2Array([Vector2(0, 0), Vector2(1.0, 0.0), Vector2(0.95, -0.25), Vector2(0.6, -0.65), Vector2(0, -1.0)])
	var mesh := MeshKit.lathe(prof, 12, PackedInt32Array([1]))
	for core in [false, true]:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = Gfx.flame(c, core)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if core:
			mi.scale = Vector3(0.5, 0.65, 0.5)
		node.add_child(mi)
	node.scale = Vector3(r, length, r)
	return node


static func _smoke(amount: int, size: float, life: float, col := Color(0.55, 0.55, 0.6, 0.55)) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(6, int(amount * float(Gfx.q().particles)))
	p.lifetime = life
	p.local_coords = false
	p.direction = Vector3(0, -1, 0)
	p.spread = 12.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, 1.2, 0)
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.35))
	curve.add_point(Vector2(1, 1.0))
	p.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = Gfx.soft_dot()
	mat.vertex_color_use_as_albedo = true
	mat.disable_fog = true
	qm.material = mat
	p.mesh = qm
	var ramp := Gradient.new()
	ramp.set_color(0, col)
	ramp.set_color(1, Color(col.r, col.g, col.b, 0.0))
	p.color_ramp = ramp
	return p


## Homing rocket, nose along local +Y. Children: "Flame" (scaled per tick).
static func rocket(accent: Color) -> Node3D:
	var root := Node3D.new()
	var m := MeshKit.Merger.new()
	var body := Gfx.hull(Color(0.95, 0.25, 0.15), Color(0.92, 0.92, 0.96), accent, {"panels_u": 6.0, "panels_v": 5.0, "under_v": 0.22, "metal": 0.45, "rough": 0.3})
	var prof := PackedVector2Array([Vector2(0, 1.0), Vector2(0.1, 0.85), Vector2(0.18, 0.6), Vector2(0.22, 0.35), Vector2(0.22, -0.55), Vector2(0.19, -0.75), Vector2(0.15, -0.82), Vector2(0, -0.84)])
	m.add(MeshKit.lathe(prof, 16, PackedInt32Array([5])), body, Transform3D.IDENTITY)
	m.add(MeshKit.lathe(PackedVector2Array([Vector2(0.225, 0.1), Vector2(0.225, -0.05)]), 16), _glow(accent, 2.4), Transform3D.IDENTITY)
	var fin := MeshKit.blob(Vector3(0.025, 0.24, 0.16), 0.5, 0.5, 8, 6, Vector2(0.4, 0.5), 0.0, Vector2(0.0, -0.6))
	var dark := _std(Color(0.15, 0.15, 0.2), 0.7, 0.4)
	for k in 4:
		var a := 90.0 * float(k) + 45.0
		var dir := Vector3(cos(deg_to_rad(a)), 0, sin(deg_to_rad(a)))
		m.add(fin, dark, Transform3D(Basis(Vector3.UP, deg_to_rad(90.0 - a)), dir * 0.3 + Vector3(0, -0.55, 0)))
	_bake(root, m)
	var fl := flame(Color(1.0, 0.55, 0.2), 0.2, 1.4)
	fl.name = "Flame"
	fl.position = Vector3(0, -0.84, 0)
	root.add_child(fl)
	var smoke := _smoke(40, 0.9, 0.9)
	smoke.position = Vector3(0, -1.1, 0)
	root.add_child(smoke)
	return root


## Gravity mine. Children: "Light" (blinks), "Ring" (gravity field, scaled
## while arming).
static func mine(owner_color: Color) -> Node3D:
	var root := Node3D.new()
	var m := MeshKit.Merger.new()
	var core := Gfx.hull(Color(0.22, 0.22, 0.28), Color(0.12, 0.12, 0.16), Color(1.0, 0.8, 0.2), {"panels_u": 8.0, "panels_v": 4.0, "metal": 0.7, "rough": 0.3, "lights": 1.0, "light_count": 10.0, "light_v": 0.5, "light_w": 0.06})
	m.add(MeshKit.blob(Vector3.ONE * 0.62, 1.0, 1.0, 18, 12), core, Transform3D.IDENTITY)
	var spike := MeshKit.blob(Vector3(0.08, 0.3, 0.08), 1.0, 1.0, 8, 6, Vector2(0.15, 0.15))
	var metal := _std(Color(0.8, 0.8, 0.85), 0.9, 0.2)
	var dirs := [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK,
		Vector3(1, 1, 1).normalized(), Vector3(-1, 1, 1).normalized(), Vector3(1, 1, -1).normalized(), Vector3(-1, 1, -1).normalized()]
	for d: Vector3 in dirs:
		var x := d.cross(Vector3.FORWARD if absf(d.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		m.add(spike, metal, Transform3D(Basis(x, d, x.cross(d).normalized()), d * 0.75))
	m.add(MeshKit.lathe(PackedVector2Array([Vector2(0.6, 0.06), Vector2(0.68, 0.0), Vector2(0.6, -0.06)]), 24), _glow(owner_color, 1.8), Transform3D.IDENTITY)
	_bake(root, m)
	var light := MeshInstance3D.new()
	light.name = "Light"
	light.mesh = MeshKit.blob(Vector3.ONE * 0.13, 1.0, 1.0, 10, 6)
	light.material_override = _glow(Color(1.0, 0.25, 0.15), 3.0)
	light.position = Vector3(0, 0.66, 0)
	root.add_child(light)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var pm := PlaneMesh.new()
	pm.size = Vector2(4.4, 4.4)
	ring.mesh = pm
	ring.material_override = Gfx.additive(Color(1.0, 0.8, 0.25, 0.8), Gfx.ring_tex())
	ring.position = Vector3(0, -0.55, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	return root


## Comet: glowing ice rock with a flaming tail along local +Y and a trail of
## ice sparkles. Point local +Y away from the direction of travel.
static func comet() -> Node3D:
	var root := Node3D.new()
	var rock := MeshInstance3D.new()
	rock.mesh = MeshKit.faceted(MeshKit.blob(Vector3.ONE * 2.2, 1.0, 1.0, 14, 10, Vector2.ONE, 0.28))
	var ice := StandardMaterial3D.new()
	ice.albedo_color = Color(0.78, 0.9, 1.0)
	ice.roughness = 0.2
	ice.metallic = 0.2
	ice.rim_enabled = true
	ice.rim = 1.0
	ice.emission_enabled = true
	ice.emission = Color(0.4, 0.8, 1.0)
	ice.emission_energy_multiplier = 1.1
	rock.material_override = ice
	rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rock)
	var tail := flame(Color(0.5, 0.85, 1.0), 2.6, 24.0)
	tail.rotation_degrees = Vector3(180, 0, 0)
	root.add_child(tail)
	var glow := MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(12, 12)
	glow.mesh = gq
	glow.material_override = Gfx.additive(Color(0.5, 0.85, 1.0, 0.7), null, true)
	root.add_child(glow)
	var sparkle := _smoke(50, 0.7, 1.0, Color(0.7, 0.95, 1.0, 0.9))
	sparkle.direction = Vector3(0, 1, 0)
	sparkle.spread = 25.0
	sparkle.initial_velocity_min = 4.0
	sparkle.initial_velocity_max = 9.0
	sparkle.gravity = Vector3.ZERO
	(sparkle.mesh.surface_get_material(0) as StandardMaterial3D).blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	root.add_child(sparkle)
	return root


## Unit energy beam along local +Y (height 1, centred): scale x/z = radius.
static func beam(c: Color, r: float, power := 1.0, core := false, flow := 6.0) -> MeshInstance3D:
	if _beam_mesh == null:
		_beam_mesh = CylinderMesh.new()
		_beam_mesh.top_radius = 1.0
		_beam_mesh.bottom_radius = 1.0
		_beam_mesh.height = 1.0
		_beam_mesh.radial_segments = 14
		_beam_mesh.rings = 1
		_beam_mesh.cap_top = false
		_beam_mesh.cap_bottom = false
	var mi := MeshInstance3D.new()
	mi.mesh = _beam_mesh
	var m := ShaderMaterial.new()
	m.shader = _beam_shader
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("power", power)
	m.set_shader_parameter("core", 1.0 if core else 0.0)
	m.set_shader_parameter("flow", flow)
	mi.material_override = m
	mi.scale = Vector3(r, 1.0, r)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Layered beam (haze + glow + core) as one node: set its basis to
## Basis(x, dir * length, z) and position to the midpoint.
static func beam_set(c: Color, width := 1.0, flow := 6.0) -> Node3D:
	var root := Node3D.new()
	root.add_child(beam(c, 1.1 * width, 0.35, false, flow))
	root.add_child(beam(c, 0.45 * width, 1.0, false, flow))
	root.add_child(beam(c, 0.13 * width, 1.6, true, flow))
	return root


## Target marker: spinning dashed ring. flat = lies on the ground (FACE_Y),
## otherwise it faces the camera.
static func reticle(c: Color, size: float, flat := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if flat:
		var pm := PlaneMesh.new()
		pm.size = Vector2(size, size)
		mi.mesh = pm
	else:
		var qm := QuadMesh.new()
		qm.size = Vector2(size, size)
		mi.mesh = qm
	var m := ShaderMaterial.new()
	m.shader = _reticle_shader
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("billboard", not flat)
	m.render_priority = 4
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Strap-on nitro booster, nozzle facing back (+Z), with a flame.
static func booster(c: Color) -> Node3D:
	var root := Node3D.new()
	var m := MeshKit.Merger.new()
	var tube := Gfx.hull(Color(0.85, 0.85, 0.9), Color(0.85, 0.85, 0.9), c, {"panels_u": 4.0, "panels_v": 3.0, "metal": 0.8, "rough": 0.2})
	var prof := PackedVector2Array([Vector2(0, 0.55), Vector2(0.12, 0.45), Vector2(0.17, 0.25), Vector2(0.17, -0.4), Vector2(0.2, -0.5), Vector2(0, -0.5)])
	m.add(MeshKit.lathe(prof, 14, PackedInt32Array([4])), tube, _xf(Vector3.ZERO, Vector3(90, 0, 0)))
	m.add(MeshKit.lathe(PackedVector2Array([Vector2(0.175, 0.0), Vector2(0.175, -0.12)]), 14), _glow(c, 2.4), _xf(Vector3.ZERO, Vector3(90, 0, 0)))
	_bake(root, m)
	var fl := flame(c, 0.17, 2.2)
	fl.name = "Flame"
	fl.position = Vector3(0, 0, 0.5)
	fl.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(fl)
	return root


## Small glowing hex badge that circles a racer holding an Ion Shield.
static func shield_badge() -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = MeshKit.faceted(MeshKit.lathe(PackedVector2Array([Vector2(0, 0.06), Vector2(0.38, 0.06), Vector2(0.38, -0.06), Vector2(0, -0.06)]), 6, PackedInt32Array([1, 2])))
	mi.material_override = _glow(Color(0.35, 0.8, 1.0), 1.8)
	mi.rotation_degrees = Vector3(90, 0, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(2.4, 0.6, 0)
	root.add_child(mi)
	return root


## Lightning bolt of n segments; place it with set_bolt().
static func bolt(c: Color, n := 7) -> Node3D:
	if _bolt_mesh == null:
		_bolt_mesh = BoxMesh.new()
		_bolt_mesh.size = Vector3(1, 1, 1)
	var root := Node3D.new()
	var mat := _glow(c.lerp(Color.WHITE, 0.4), 2.8)
	for k in n:
		var mi := MeshInstance3D.new()
		mi.mesh = _bolt_mesh
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	return root


## Re-shape a bolt from a to b with fresh random kinks (call every few ticks
## so it crackles).
static func set_bolt(node: Node3D, a: Vector3, b: Vector3, rng: RandomNumberGenerator, jag := 1.2) -> void:
	var n := node.get_child_count()
	var d := b - a
	var len := d.length()
	if len < 0.01:
		return
	var dir := d / len
	var side := dir.cross(Vector3.UP)
	if side.length() < 0.01:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(dir).normalized()
	var pts: Array[Vector3] = []
	for k in n + 1:
		var t := float(k) / float(n)
		var off := Vector3.ZERO
		if k > 0 and k < n:
			off = side * rng.randf_range(-jag, jag) + up * rng.randf_range(-jag, jag)
		pts.append(a + d * t + off)
	for k in n:
		var p0 := pts[k]
		var p1 := pts[k + 1]
		var seg := p1 - p0
		var sl := seg.length()
		var y := seg / maxf(sl, 0.001)
		var x := y.cross(Vector3.UP)
		if x.length() < 0.01:
			x = y.cross(Vector3.RIGHT)
		x = x.normalized()
		var z := x.cross(y).normalized()
		var mi := node.get_child(k) as Node3D
		mi.global_transform = Transform3D(Basis(x * 0.12, y * sl, z * 0.12), (p0 + p1) * 0.5)
