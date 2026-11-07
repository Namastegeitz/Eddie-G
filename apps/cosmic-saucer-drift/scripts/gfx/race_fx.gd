class_name RaceFx
extends Node3D
## Pooled one-off effects in a race: boost shockwave rings, impact flashes,
## spark bursts (hits, wall scrapes), landing dust and pickup sparkles.
## Nothing is created during the race: every effect reuses a pooled node.

const RINGS := 10
const FLASHES := 16
const SPARK_N := 6
const DUST_N := 4
const BURSTS := SPARK_N + DUST_N

var particles := 1.0     # quality scale for burst particle counts
var _rings: Array[MeshInstance3D] = []
var _ring_t: PackedFloat32Array = PackedFloat32Array()
var _ring_life: PackedFloat32Array = PackedFloat32Array()
var _ring_size: PackedFloat32Array = PackedFloat32Array()
var _flashes: Array[MeshInstance3D] = []
var _flash_t: PackedFloat32Array = PackedFloat32Array()
var _flash_size: PackedFloat32Array = PackedFloat32Array()
var _bursts: Array[CPUParticles3D] = []   # sparks first, then dust
var _next_ring := 0
var _next_flash := 0
var _next_spark := 0
var _next_dust := 0


func _ready() -> void:
	particles = float(Gfx.q().particles)
	for k in RINGS:
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2, 2)
		qm.orientation = PlaneMesh.FACE_Y
		mi.mesh = qm
		mi.material_override = Gfx.additive(Color(1, 1, 1, 1), Gfx.ring_tex())
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_rings.append(mi)
	_ring_t.resize(RINGS)
	_ring_life.resize(RINGS)
	_ring_size.resize(RINGS)
	for k in FLASHES:
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2, 2)
		mi.mesh = qm
		mi.material_override = Gfx.additive(Color(1, 1, 1, 1), null, true)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_flashes.append(mi)
	_flash_t.resize(FLASHES)
	_flash_size.resize(FLASHES)
	# Two fixed pools, each with its own material, mesh and particle count:
	# switching one pool between additive sparks and soft dust changed the
	# material's shader (a recompile on the web) and resizing amount or the
	# quad rebuilt buffers on every burst.
	for k in BURSTS:
		var soft := k >= SPARK_N
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.emitting = false
		p.explosiveness = 0.92
		p.amount = maxi(6, int((18.0 if soft else 28.0) * particles))
		p.lifetime = 0.6
		p.local_coords = false
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.4
		p.spread = 70.0
		p.particle_flag_align_y = not soft
		var curve := Curve.new()
		curve.add_point(Vector2(0, 1))
		curve.add_point(Vector2(1, 0))
		p.scale_amount_curve = curve
		var qm := QuadMesh.new()
		qm.size = Vector2(1.1, 1.1) if soft else Vector2(0.1, 0.55)
		var mat := Gfx.additive(Color(1, 1, 1, 1))
		mat.vertex_color_use_as_albedo = true
		if soft:
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		else:
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		qm.material = mat
		p.mesh = qm
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 1))
		ramp.set_color(1, Color(1, 1, 1, 0))
		p.color_ramp = ramp
		add_child(p)
		_bursts.append(p)


## Shows one ring, one flash and one burst in front of the camera, tiny, for
## a couple of frames so their shaders are compiled before the race.
func warm_up(cam: Camera3D) -> void:
	if cam == null:
		return
	var nodes: Array[Node3D] = [_rings[0], _flashes[0], _bursts[0], _bursts[SPARK_N]]
	var parents: Array[Node] = []
	for n in nodes:
		parents.append(n.get_parent())
		n.get_parent().remove_child(n)
		cam.add_child(n)
		n.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.02), Vector3(0, 0, -3.0))
		n.visible = true
	_take_burst(false).emitting = true
	_take_burst(true).emitting = true
	var tree := get_tree()
	for i in 3:
		await tree.process_frame
		if not is_inside_tree():
			return   # the race ended during the warm-up
	for k in nodes.size():
		var n := nodes[k]
		if not is_instance_valid(n):
			continue
		n.get_parent().remove_child(n)
		parents[k].add_child(n)
		n.visible = false
		n.transform = Transform3D.IDENTITY
		if n is CPUParticles3D:
			(n as CPUParticles3D).emitting = false
	_next_spark = 0
	_next_dust = 0


## Expanding glowing ring on the ground plane given by `up`.
func shockwave(pos: Vector3, up: Vector3, c: Color, size := 7.0, life := 0.45) -> void:
	var k := _next_ring
	_next_ring = (_next_ring + 1) % RINGS
	var mi := _rings[k]
	mi.global_transform = Transform3D(_basis_up(up), pos + up * 0.25)
	(mi.material_override as StandardMaterial3D).albedo_color = Color(c.r, c.g, c.b, 1.0)
	mi.scale = Vector3.ONE * 0.5
	mi.visible = true
	_ring_t[k] = life
	_ring_life[k] = life
	_ring_size[k] = size


## Bright flash sprite that pops and fades.
func flash(pos: Vector3, c: Color, size := 3.5, secs := 0.22) -> void:
	var k := _next_flash
	_next_flash = (_next_flash + 1) % FLASHES
	var mi := _flashes[k]
	mi.global_position = pos
	(mi.material_override as StandardMaterial3D).albedo_color = Color(c.r, c.g, c.b, 1.0)
	mi.scale = Vector3.ONE * size * 0.6
	mi.visible = true
	_flash_t[k] = secs
	_flash_size[k] = size


## Burst of streaking sparks.
func sparks(pos: Vector3, dir: Vector3, c: Color, count := 24, speed := 10.0, grav := 12.0) -> void:
	var p := _take_burst()
	p.global_position = pos
	p.direction = dir.normalized() if dir.length() > 0.01 else Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3.DOWN * grav
	p.lifetime = 0.55
	p.color = Color(c.r * 1.6, c.g * 1.6, c.b * 1.6, 1.0)
	p.restart()
	p.emitting = true


## Soft puff of dust/vapour (landings, skids).
func dust(pos: Vector3, up: Vector3, c: Color, count := 18) -> void:
	var p := _take_burst(true)
	p.global_position = pos
	p.direction = up
	p.spread = 85.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	p.gravity = -up * 3.0
	p.lifetime = 0.8
	p.color = Color(c.r, c.g, c.b, 0.55)
	p.restart()
	p.emitting = true


## Next pooled emitter, set up as streaking additive sparks or soft dust.
func _take_burst(soft := false) -> CPUParticles3D:
	if soft:
		_next_dust = (_next_dust + 1) % DUST_N
		return _bursts[SPARK_N + _next_dust]
	_next_spark = (_next_spark + 1) % SPARK_N
	return _bursts[_next_spark]


static func _basis_up(up: Vector3) -> Basis:
	var u := up.normalized()
	var x := u.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = u.cross(Vector3.RIGHT)
	x = x.normalized()
	return Basis(x, u, x.cross(u).normalized())


func _process(dt: float) -> void:
	for k in RINGS:
		if _ring_t[k] <= 0.0:
			continue
		_ring_t[k] -= dt
		var mi := _rings[k]
		if _ring_t[k] <= 0.0:
			mi.visible = false
			continue
		var f := 1.0 - _ring_t[k] / _ring_life[k]
		mi.scale = Vector3.ONE * lerpf(0.5, _ring_size[k], 1.0 - pow(1.0 - f, 2.5))
		var m := mi.material_override as StandardMaterial3D
		m.albedo_color.a = (1.0 - f) * 1.2
	for k in FLASHES:
		if _flash_t[k] <= 0.0:
			continue
		_flash_t[k] -= dt
		var mi := _flashes[k]
		if _flash_t[k] <= 0.0:
			mi.visible = false
			continue
		var m := mi.material_override as StandardMaterial3D
		m.albedo_color.a = clampf(_flash_t[k] * 5.0, 0.0, 1.0)
		mi.scale = Vector3.ONE * _flash_size[k] * (1.1 - _flash_t[k] * 1.5)
