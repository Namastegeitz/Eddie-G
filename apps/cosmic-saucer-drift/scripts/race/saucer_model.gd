class_name SaucerModel
extends Node3D
## Visual saucer built from primitives: hull per chassis shape, glass dome
## with the alien pilot, rim lights, underglow, thruster, drift sparks,
## engine trail and shield bubble. Forward is -Z.

var pivot: Node3D          # tilts/spins for drift, tricks, hits
var thruster: MeshInstance3D
var underglow: MeshInstance3D
var shield: MeshInstance3D
var trail: CPUParticles3D
var sparks: Array[CPUParticles3D] = []
var spin_ring: Node3D = null
var spin_ring2: Node3D = null
var wobble: Array[Node3D] = []       # parts that sway (tendrils, dragon body)
var trail_color := Color(0.3, 0.9, 1.0)
var _spark_mats: Array[StandardMaterial3D] = []
var _mat_cache := {}
static var _soft: ImageTexture = null

const SPARK_COLORS := [Color(0.3, 0.7, 1.0), Color(1.0, 0.55, 0.15), Color(0.85, 0.35, 1.0)]


func _mat(c: Color, metallic := 0.6, rough := 0.3, emission := 0.0) -> StandardMaterial3D:
	var key := "%s|%f|%f|%f" % [c, metallic, rough, emission]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metallic
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	_mat_cache[key] = m
	return m


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _sphere(r: float, h: float, seg := 20, rings := 10, hemi := false) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h
	s.radial_segments = seg
	s.rings = rings
	s.is_hemisphere = hemi
	return s


static func _torus(inner: float, outer: float, seg := 28) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = seg
	t.ring_segments = 6
	return t


static func _cyl(top: float, bottom: float, h: float, seg := 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


## look: {saucer, pilot, paint, decal, dome, trail} (ids); paint "stock" = chassis colour.
func build(look: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	sparks.clear()
	_spark_mats.clear()
	wobble.clear()
	spin_ring = null
	spin_ring2 = null
	var chassis := Catalog.saucer(look.get("saucer", "classic"))
	var pilot := Catalog.pilot(look.get("pilot", "zib"))
	var paint_def := Catalog.find(Catalog.PAINTS, look.get("paint", "stock"))
	var paint: Color = chassis.paint if paint_def.id == "stock" else paint_def.color
	var dome_c: Color = Catalog.find(Catalog.DOMES, look.get("dome", "clear")).color
	trail_color = Catalog.find(Catalog.TRAILS, look.get("trail", "cyan")).color
	var decal: String = look.get("decal", "none")
	var gold: bool = paint_def.id == "gold"
	pivot = Node3D.new()
	pivot.name = "Pivot"
	add_child(pivot)
	var hull_mat := _mat(paint, 0.85 if gold else 0.55, 0.22)
	var dark := _mat(paint.darkened(0.55), 0.6, 0.4)
	var accent := _mat(trail_color, 0.2, 0.4, 1.6)
	var shape: String = chassis.shape
	var dome_r := 0.85
	var dome_y := 0.22
	var rim_r := 1.9
	match shape:
		"classic":
			_part(pivot, _sphere(1.95, 0.78), hull_mat)
			_part(pivot, _torus(1.72, 2.02), dark, Vector3(0, -0.02, 0))
		"bubble":
			_part(pivot, _sphere(1.55, 0.62), hull_mat)
			_part(pivot, _torus(1.4, 1.62), dark)
			dome_r = 1.15
			dome_y = 0.12
			rim_r = 1.55
		"rocket":
			_part(pivot, _sphere(1.45, 0.72), hull_mat, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 1.55))
			for sx: float in [-1.0, 1.0]:
				_part(pivot, _box(Vector3(0.14, 1.0, 1.3)), dark, Vector3(sx * 0.95, 0.45, 1.55), Vector3(-20, 0, sx * 18.0))
				_part(pivot, _cyl(0.28, 0.4, 0.8), _mat(Color(0.25, 0.25, 0.3)), Vector3(sx * 0.55, 0.0, 2.2), Vector3(90, 0, 0))
			dome_r = 0.75
			dome_y = 0.18
			rim_r = 1.5
		"ring":
			_part(pivot, _sphere(1.35, 0.72), hull_mat)
			spin_ring = Node3D.new()
			pivot.add_child(spin_ring)
			_part(spin_ring, _torus(1.95, 2.3, 32), dark)
			for k in 3:
				_part(spin_ring, _box(Vector3(0.12, 0.12, 2.1)), dark, Vector3(0, 0, 0).rotated(Vector3.UP, TAU * k / 3.0), Vector3(0, 120.0 * k, 0), Vector3.ONE)
			dome_r = 0.8
			rim_r = 1.35
		"manta":
			_part(pivot, _sphere(2.25, 0.46), hull_mat, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.72))
			_part(pivot, _box(Vector3(0.12, 0.8, 0.9)), dark, Vector3(0, 0.45, 1.2), Vector3(-25, 0, 0))
			dome_r = 0.7
			dome_y = 0.12
			rim_r = 2.1
		"mothership":
			_part(pivot, _sphere(2.15, 0.95), hull_mat)
			_part(pivot, _sphere(1.35, 0.65), dark, Vector3(0, 0.3, 0))
			_part(pivot, _torus(1.95, 2.25), dark)
			dome_r = 0.8
			dome_y = 0.52
			rim_r = 2.1
		"orb":
			_part(pivot, _sphere(1.3, 2.4, 20, 10), hull_mat, Vector3(0, -0.1, 0))
			spin_ring = Node3D.new()
			pivot.add_child(spin_ring)
			_part(spin_ring, _torus(1.75, 1.95, 32), dark, Vector3.ZERO, Vector3(0, 0, 70))
			spin_ring2 = Node3D.new()
			pivot.add_child(spin_ring2)
			_part(spin_ring2, _torus(2.0, 2.15, 32), dark, Vector3.ZERO, Vector3(70, 0, 0))
			dome_r = 0.65
			dome_y = 0.7
			rim_r = 1.35
		"crystal":
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Color(paint.r, paint.g, paint.b, 0.8)
			cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cm.metallic = 0.4
			cm.roughness = 0.05
			cm.emission_enabled = true
			cm.emission = paint
			cm.emission_energy_multiplier = 0.6
			_part(pivot, _sphere(1.0, 2.0, 4, 2), cm, Vector3.ZERO, Vector3(0, 45, 0), Vector3(1.3, 0.55, 2.4))
			for sx: float in [-1.0, 1.0]:
				_part(pivot, _sphere(0.5, 1.0, 4, 2), cm, Vector3(sx * 1.35, 0.0, 0.6), Vector3(0, 45, 0), Vector3(0.6, 0.4, 1.6))
			dome_r = 0.6
			dome_y = 0.3
			rim_r = 1.6
		"bioship":
			_part(pivot, _sphere(1.5, 1.4, 16, 8), hull_mat, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 1.3))
			for k in 5:
				var a := deg_to_rad(-60.0 + 30.0 * k)
				_part(pivot, _sphere(0.35, 0.5, 8, 4), dark, Vector3(sin(a) * 1.1, 0.45, cos(a) * 1.1 - 0.3))
			for k in 4:
				var tnode := Node3D.new()
				tnode.position = Vector3(-0.9 + 0.6 * k, -0.1, 1.5)
				pivot.add_child(tnode)
				_part(tnode, _cyl(0.06, 0.16, 2.2, 6), dark, Vector3(0, 0, 1.0), Vector3(90, 0, 0))
				_part(tnode, _sphere(0.14, 0.28, 6, 3), _mat(trail_color, 0.0, 0.5, 2.0), Vector3(0, 0, 2.1))
				wobble.append(tnode)
			dome_r = 0.7
			dome_y = 0.35
			rim_r = 1.5
		"arrow":
			var pm := PrismMesh.new()
			pm.size = Vector3(3.2, 4.6, 0.45)
			_part(pivot, pm, hull_mat, Vector3(0, 0, -0.2), Vector3(-90, 0, 0))
			for sx: float in [-1.0, 1.0]:
				_part(pivot, _box(Vector3(0.12, 0.8, 1.0)), dark, Vector3(sx * 1.2, 0.35, 1.3), Vector3(-15, 0, sx * -20.0))
			_part(pivot, _cyl(0.25, 0.35, 0.7), _mat(Color(0.25, 0.25, 0.3)), Vector3(0, 0, 2.1), Vector3(90, 0, 0))
			dome_r = 0.6
			dome_y = 0.2
			rim_r = 1.4
		"sail":
			_part(pivot, _sphere(1.0, 0.9, 16, 8), hull_mat, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 2.0))
			var sm := StandardMaterial3D.new()
			sm.albedo_color = Color(1.0, 0.85, 0.45, 0.55)
			sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sm.cull_mode = BaseMaterial3D.CULL_DISABLED
			sm.emission_enabled = true
			sm.emission = Color(1.0, 0.8, 0.4)
			sm.emission_energy_multiplier = 0.9
			for sx: float in [-1.0, 1.0]:
				_part(pivot, _box(Vector3(0.04, 2.4, 3.0)), sm, Vector3(sx * 1.7, 1.0, 0.2), Vector3(0, 0, sx * -35.0))
				_part(pivot, _cyl(0.04, 0.04, 2.6, 4), _mat(Color(0.9, 0.8, 0.6), 0.9, 0.2), Vector3(sx * 0.9, 0.6, 0.2), Vector3(0, 0, sx * -35.0))
			dome_r = 0.65
			dome_y = 0.25
			rim_r = 1.2
		"phantom":
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(paint.r, paint.g, paint.b, 0.55)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.emission_enabled = true
			gm.emission = paint
			gm.emission_energy_multiplier = 0.8
			_part(pivot, _sphere(1.9, 0.7, 24, 10), gm)
			spin_ring = Node3D.new()
			pivot.add_child(spin_ring)
			var beam := _mat(Color(0.8, 0.7, 1.0), 0.0, 0.5, 3.0)
			_part(spin_ring, _cyl(0.0, 0.3, 2.6, 8), beam, Vector3(1.3, 0.2, 0), Vector3(0, 0, -80))
			_part(spin_ring, _cyl(0.0, 0.3, 2.6, 8), beam, Vector3(-1.3, 0.2, 0), Vector3(0, 0, 80))
			dome_r = 0.8
			dome_y = 0.2
			rim_r = 1.9
		"dragon":
			_part(pivot, _sphere(1.1, 1.3, 16, 8), hull_mat, Vector3(0, 0, -0.6), Vector3.ZERO, Vector3(1.0, 0.9, 1.4))
			for sx: float in [-1.0, 1.0]:
				_part(pivot, _cyl(0.0, 0.18, 0.9, 6), _mat(Color(1.0, 0.85, 0.4), 0.5, 0.3), Vector3(sx * 0.5, 0.7, -0.9), Vector3(-30, 0, sx * -20.0))
				_part(pivot, _box(Vector3(1.6, 0.06, 1.0)), dark, Vector3(sx * 1.3, 0.2, 0.0), Vector3(0, sx * 20.0, sx * 15.0))
			var r := 0.85
			for k in 4:
				var seg := Node3D.new()
				seg.position = Vector3(0, 0, 0.6 + k * 0.85)
				pivot.add_child(seg)
				_part(seg, _sphere(r, r * 1.6, 12, 6), hull_mat if k % 2 == 0 else dark)
				wobble.append(seg)
				r *= 0.78
			dome_r = 0.55
			dome_y = 0.35
			rim_r = 1.2
		"dyson":
			_part(pivot, _sphere(0.9, 1.8, 16, 8), _mat(Color(1.0, 0.75, 0.3), 0.0, 0.5, 3.0))
			spin_ring = Node3D.new()
			pivot.add_child(spin_ring)
			_part(spin_ring, _torus(1.6, 1.8, 32), dark)
			for k in 8:
				var a := TAU * k / 8.0
				_part(spin_ring, _box(Vector3(0.7, 0.9, 0.08)), hull_mat, Vector3(cos(a) * 1.7, 0, sin(a) * 1.7), Vector3(0, -rad_to_deg(a) + 90.0, 0))
			dome_r = 0.5
			dome_y = 0.85
			rim_r = 1.8
	# Rim light band and underglow.
	_part(pivot, _torus(rim_r - 0.06, rim_r + 0.06, 32), accent, Vector3(0, 0.05, 0), Vector3.ZERO, Vector3(1, 0.6, 1) if shape != "manta" else Vector3(1, 0.6, 0.72))
	underglow = _part(pivot, _cyl(rim_r * 0.75, rim_r * 0.75, 0.04, 20), _mat(trail_color, 0.0, 1.0, 2.2), Vector3(0, -0.36, 0))
	_decal(decal, paint, rim_r, shape)
	# Glass dome with the pilot.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = dome_c
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.2
	glass.roughness = 0.05
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_build_pilot(pilot, Vector3(0, dome_y, -0.05), dome_r)
	_part(pivot, _sphere(dome_r, dome_r * 2.0, 18, 8, true), glass, Vector3(0, dome_y, 0))
	# Thruster glow at the back.
	var tail_z := rim_r * (1.55 if shape == "rocket" else 1.0) + 0.3
	if shape in ["dragon", "sail"]:
		tail_z = 2.4
	thruster = _part(pivot, _cyl(0.0, 0.32, 1.0, 10), _mat(trail_color, 0.0, 1.0, 1.3), Vector3(0, -0.05, tail_z), Vector3(-90, 0, 0))
	# Shield bubble (hidden until used).
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.4, 0.85, 1.0, 0.28)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	shield = _part(self, _sphere(2.6, 3.2, 20, 10), sm)
	shield.visible = false
	# Engine trail.
	trail = _particles(Vector3(0, 0, rim_r + 0.4), trail_color, 28, 0.5, 0.7)
	# Drift sparks at both rear corners.
	for sx: float in [-1.0, 1.0]:
		var p := _particles(Vector3(sx * rim_r * 0.8, -0.3, rim_r * 0.6), SPARK_COLORS[0], 16, 0.25, 0.22)
		p.emitting = false
		p.spread = 50.0
		p.initial_velocity_min = 4.0
		p.initial_velocity_max = 7.0
		p.direction = Vector3(sx * 0.4, 0.6, 1.0)
		sparks.append(p)
		_spark_mats.append(p.mesh.surface_get_material(0) as StandardMaterial3D)


static func soft_dot() -> ImageTexture:
	if _soft:
		return _soft
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for x in n:
		for y in n:
			var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	_soft = ImageTexture.create_from_image(img)
	return _soft


func _particles(pos: Vector3, c: Color, amount: int, life: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.position = pos
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2
	p.direction = Vector3(0, 0, 1)
	p.spread = 12.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.5
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(c.r, c.g, c.b, 0.8)
	mat.albedo_texture = soft_dot()
	mat.vertex_color_use_as_albedo = true
	qm.material = mat
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	p.mesh = qm
	pivot.add_child(p)
	return p


func _build_pilot(pilot: Dictionary, at: Vector3, dome_r: float) -> void:
	var head_r := dome_r * 0.5
	var skin := _mat(pilot.color, 0.0, 0.7)
	var head := Node3D.new()
	head.position = at + Vector3(0, head_r * 0.6, 0)
	pivot.add_child(head)
	_part(head, _sphere(head_r, head_r * 2.0, 14, 7), skin)
	var eyes: int = pilot.get("eyes", 2)
	var white := _mat(Color(1, 1, 1), 0.0, 0.3)
	var black := _mat(Color(0.03, 0.02, 0.05), 0.0, 0.2)
	var er := head_r * (0.42 if eyes == 1 else 0.3)
	for k in eyes:
		var x := 0.0 if eyes == 1 else lerpf(-head_r * 0.45, head_r * 0.45, float(k) / float(eyes - 1))
		var y := head_r * 0.15 + (0.0 if eyes < 3 else (head_r * 0.25 if k % 2 == 1 else 0.0))
		var ep := Vector3(x, y, -head_r * 0.78)
		_part(head, _sphere(er, er * 2.0, 10, 5), white, ep)
		_part(head, _sphere(er * 0.5, er, 8, 4), black, ep + Vector3(0, 0, -er * 0.7))
	# Antennae for everyone but the robot (who gets a dish) and the pup (ears).
	match pilot.id:
		"bleep":
			_part(head, _cyl(0.02, 0.02, head_r), _mat(Color(0.7, 0.7, 0.75)), Vector3(0, head_r * 1.3, 0))
			_part(head, _sphere(head_r * 0.2, head_r * 0.4, 8, 4), _mat(Color(1, 0.2, 0.2), 0.0, 0.5, 2.0), Vector3(0, head_r * 1.8, 0))
		"comet":
			for sx: float in [-1.0, 1.0]:
				_part(head, _sphere(head_r * 0.35, head_r * 1.1, 8, 4), _mat(Color(0.55, 0.38, 0.25), 0.0, 0.8), Vector3(sx * head_r * 0.85, head_r * 0.2, 0), Vector3(0, 0, sx * 30.0))
		_:
			for sx: float in [-1.0, 1.0]:
				_part(head, _cyl(0.025, 0.025, head_r * 0.9), skin, Vector3(sx * head_r * 0.4, head_r * 1.2, 0), Vector3(0, 0, -sx * 20.0))
				_part(head, _sphere(head_r * 0.14, head_r * 0.28, 8, 4), _mat(pilot.color, 0.0, 0.5, 1.5), Vector3(sx * head_r * 0.58, head_r * 1.62, 0))


func _decal(decal: String, paint: Color, rim_r: float, shape: String) -> void:
	var white := _mat(Color(0.95, 0.95, 1.0), 0.3, 0.4)
	var zs := 1.55 if shape == "rocket" else (0.72 if shape == "manta" else 1.0)
	match decal:
		"stripes":
			for sx: float in [-0.35, 0.35]:
				_part(pivot, _box(Vector3(0.22, 0.05, rim_r * 1.7 * zs)), white, Vector3(sx, 0.33, 0))
		"checker":
			var c := _checker_mat(paint)
			_part(pivot, _torus(rim_r * 0.82, rim_r * 0.98, 32), c, Vector3(0, 0.18, 0), Vector3.ZERO, Vector3(1, 0.4, zs))
		"flames":
			var f := _mat(Color(1.0, 0.45, 0.1), 0.0, 0.5, 2.0)
			for k in 5:
				var a := deg_to_rad(-50.0 + 25.0 * k)
				_part(pivot, _box(Vector3(0.18, 0.06, 1.1)), f, Vector3(sin(a) * rim_r * 0.6, 0.3, cos(a) * rim_r * 0.6 * zs), Vector3(0, rad_to_deg(a), 0))
		"stars":
			var s := _mat(Color(1.0, 0.95, 0.5), 0.0, 0.5, 2.5)
			for k in 7:
				var a := TAU * k / 7.0
				_part(pivot, _sphere(0.1, 0.2, 6, 3), s, Vector3(cos(a) * rim_r * 0.7, 0.3, sin(a) * rim_r * 0.7 * zs))
		"zigzag":
			var z := _mat(Color(0.3, 1.0, 0.9), 0.0, 0.5, 2.0)
			for k in 10:
				var a := TAU * k / 10.0
				_part(pivot, _box(Vector3(0.1, 0.05, 0.7)), z, Vector3(cos(a) * rim_r * 0.78, 0.22, sin(a) * rim_r * 0.78 * zs), Vector3(0, rad_to_deg(-a) + (35.0 if k % 2 == 0 else -35.0), 0))


func _checker_mat(paint: Color) -> StandardMaterial3D:
	var img := Image.create(16, 2, false, Image.FORMAT_RGB8)
	for x in 16:
		for y in 2:
			img.set_pixel(x, y, Color.WHITE if (x + y) % 2 == 0 else paint.darkened(0.7))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_scale = Vector3(4, 1, 1)
	return m


## Per-frame visual state from the racer.
func animate(dt: float, throttle: float, boosting: bool, drift_tier: int, drifting: bool, speed_ratio: float) -> void:
	if spin_ring:
		spin_ring.rotate_y(dt * (3.0 + speed_ratio * 12.0))
	if spin_ring2:
		spin_ring2.rotate_y(-dt * (2.0 + speed_ratio * 8.0))
	if not wobble.is_empty():
		var t := Time.get_ticks_msec() * 0.001
		for k in wobble.size():
			wobble[k].rotation.y = sin(t * 5.0 + k * 0.8) * (0.18 + 0.05 * k)
	var flame := 0.3 + throttle * 0.5 + (0.8 if boosting else 0.0)
	thruster.scale = Vector3(1.0 + (0.35 if boosting else 0.0), 0.4 + flame * 0.9, 1.0 + (0.35 if boosting else 0.0))
	underglow.scale = Vector3.ONE * (0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.01))
	trail.emitting = speed_ratio > 0.15
	var on := drifting and drift_tier > 0
	for k in sparks.size():
		sparks[k].emitting = on
		if on:
			_spark_mats[k].albedo_color = SPARK_COLORS[clampi(drift_tier - 1, 0, 2)] * 1.6
