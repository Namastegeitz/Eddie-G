class_name SaucerModel
extends Node3D
## A craft built from code in HD: smooth turned hulls with panel seams,
## rivets and running lights (hull shader), chrome trim, nav lights, engine
## nozzles with live flames, a glass cockpit with the animated alien pilot,
## underglow, a soft shadow, drift sparks, engine trail and the Ion Shield.
## Static parts are baked into one mesh per material. Forward is -Z.

var pivot: Node3D          # tilts/spins for drift, tricks, hits
var thruster: Node3D       # first engine flame (kept for older callers)
var thrusters: Array[Node3D] = []
var underglow: MeshInstance3D
var shadow: MeshInstance3D
var shield: MeshInstance3D
var trail: CPUParticles3D
var sparks: Array[CPUParticles3D] = []
var spin_ring: Node3D = null
var spin_ring2: Node3D = null
var wobble: Array[Node3D] = []       # parts that sway (tendrils, dragon body)
var flaps: Array[Node3D] = []        # wings that flap
var pilot_model: PilotModel
var trail_color := Color(0.3, 0.9, 1.0)
var breath: Node3D = null            # Quasar Dragon fire while boosting
var rim_r := 1.9                     # hull radius (for strap-on parts)
var top_y := 0.4                     # height of the hull top

# Set by the racer every frame.
var mood := 0
var steer := 0.0
var grounded := true
var flash := 0.0

var _spark_mats: Array[StandardMaterial3D] = []
var _spark_glow: Array[MeshInstance3D] = []
var _hulls: Array[ShaderMaterial] = []
var _flame_mats: Array[ShaderMaterial] = []
var _merge: MeshKit.Merger
var _seg := 40
var _qs: Dictionary
var _shadows := false
var _t := 0.0
var _boost_k := 0.0
var _last_boost := -1.0
var _flame_r := PackedFloat32Array()
var _flame_len := PackedFloat32Array()
var _pilot_lod := 30.0
var _last_flash := 0.0
var _react := ""
var _react_t := 0.0
var _react_len := 1.0

## How each power-up hit looks on the craft: colour and how long.
const REACT := {
	"rocket": [Color(1.0, 0.55, 0.2), 0.9], "mine": [Color(1.0, 0.8, 0.25), 0.9],
	"comet": [Color(0.6, 0.9, 1.0), 0.85], "laser": [Color(0.35, 1.0, 0.95), 0.6],
	"emp": [Color(1.0, 0.95, 0.4), 1.2], "tractor": [Color(0.45, 1.0, 0.5), 1.4],
	"block": [Color(0.4, 0.85, 1.0), 0.45], "hazard": [Color(1.0, 1.0, 1.0), 0.6],
}
static var _mats := {}

const SPARK_COLORS := [Color(0.3, 0.7, 1.0), Color(1.0, 0.55, 0.15), Color(0.85, 0.35, 1.0)]


static func soft_dot() -> ImageTexture:
	return Gfx.soft_dot()


static func _std(c: Color, metallic := 0.6, rough := 0.3, emission := 0.0, coat := 0.0) -> StandardMaterial3D:
	var key := "%s|%f|%f|%f|%f" % [c, metallic, rough, emission, coat]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metallic
	m.roughness = rough
	if coat > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = coat
		m.clearcoat_roughness = 0.1
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


static func _glow(c: Color, energy := 2.0) -> StandardMaterial3D:
	var key := "glow|%s|%f" % [c, energy]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c * energy
	m.disable_receive_shadows = true
	_mats[key] = m
	return m


static func _xf(pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot * (PI / 180.0)) * Basis.from_scale(scl), pos)


func _add(mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE, into: MeshKit.Merger = null) -> void:
	(into if into else _merge).add(mesh, mat, _xf(pos, rot, scl))


func _bake(parent: Node3D, m: MeshKit.Merger, cast := true) -> MeshInstance3D:
	if m.empty():
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = m.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (cast and _shadows) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _lathe(pts: Array, creases: Array = [], seg := -1) -> ArrayMesh:
	var p := PackedVector2Array()
	for v: Vector2 in pts:
		p.append(v)
	return MeshKit.lathe(p, _seg if seg < 0 else seg, PackedInt32Array(creases))


## Fraction along a profile at point i (for the hull two-tone split).
static func _v_at(pts: Array, i: int) -> float:
	var total := 0.0
	var upto := 0.0
	for k in pts.size() - 1:
		var d: float = (pts[k + 1] - pts[k]).length()
		if k < i:
			upto += d
		total += d
	return upto / maxf(total, 0.0001)


## Torus as a lathe profile (proper UVs for seams/lights).
static func _torus_pts(big_r: float, small_r: float, n := 10) -> Array:
	var out := []
	for k in n + 1:
		var a := deg_to_rad(90.0 - 360.0 * float(k) / float(n))
		out.append(Vector2(big_r + small_r * cos(a), small_r * sin(a)))
	return out


func _hull_mat(paint: Color, under: Color, opts := {}) -> ShaderMaterial:
	var o := {"metal": 0.55 if _qs.reflect else 0.2, "rough": 0.24}
	o.merge(opts, true)
	var m := Gfx.hull(paint, under, trail_color, o)
	_hulls.append(m)
	return m


## look: {saucer, pilot, paint, decal, dome, trail} (ids); paint "stock" = chassis colour.
func build(look: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	sparks.clear()
	_spark_mats.clear()
	_spark_glow.clear()
	wobble.clear()
	flaps.clear()
	thrusters.clear()
	_flame_r.clear()
	_flame_len.clear()
	_hulls.clear()
	_flame_mats.clear()
	spin_ring = null
	spin_ring2 = null
	breath = null
	_qs = Gfx.q()
	_seg = int(_qs.seg)
	_shadows = int(_qs.shadows) > 0
	_merge = MeshKit.Merger.new()
	var chassis := Catalog.saucer(look.get("saucer", "classic"))
	var pilot := Catalog.pilot(look.get("pilot", "zib"))
	var paint_def := Catalog.find(Catalog.PAINTS, look.get("paint", "stock"))
	var paint: Color = chassis.paint if paint_def.id == "stock" else paint_def.color
	var dome_c: Color = Catalog.find(Catalog.DOMES, look.get("dome", "clear")).color
	trail_color = Catalog.find(Catalog.TRAILS, look.get("trail", "cyan")).color
	var decal: String = look.get("decal", "none")
	var gold_paint: bool = paint_def.id == "gold"
	pivot = Node3D.new()
	pivot.name = "Pivot"
	add_child(pivot)
	var under := paint.darkened(0.5).lerp(Color(0.12, 0.12, 0.16), 0.35)
	var hull_opts := {"metal": 0.9 if gold_paint else (0.55 if _qs.reflect else 0.2)}
	var chrome := _std(Color(0.78, 0.8, 0.86), 0.9 if _qs.reflect else 0.4, 0.16, 0.0, 1.0)
	var dark := _std(Color(0.09, 0.09, 0.12), 0.7, 0.45)
	var glow := _glow(trail_color, 2.2)
	var shape: String = chassis.shape
	var d := {"dome_r": 0.85, "dome_y": 0.22, "dome_z": 0.0, "rim_r": 1.9, "nav": true, "pilot_k": 1.0}
	match shape:
		"classic":
			_classic(paint, under, hull_opts, chrome, dark, glow, d)
		"bubble":
			_bubble(paint, under, hull_opts, chrome, dark, glow, d)
		"rocket":
			_rocket(paint, under, hull_opts, chrome, dark, glow, d)
		"ring":
			_ring(paint, under, hull_opts, chrome, dark, glow, d)
		"manta":
			_manta(paint, under, hull_opts, chrome, dark, glow, d)
		"mothership":
			_mothership(paint, under, hull_opts, chrome, dark, glow, d)
		"orb":
			_orb(paint, under, hull_opts, chrome, dark, glow, d)
		"crystal":
			_crystal(paint, under, chrome, glow, d)
		"bioship":
			_bioship(paint, under, dark, glow, d)
		"arrow":
			_arrow(paint, under, hull_opts, chrome, dark, glow, d)
		"sail":
			_sail(paint, under, hull_opts, chrome, dark, glow, d)
		"phantom":
			_phantom(paint, chrome, glow, d)
		"dragon":
			_dragon(paint, under, chrome, dark, glow, d)
		"dyson":
			_dyson(paint, under, hull_opts, chrome, dark, glow, d)
		_:
			_classic(paint, under, hull_opts, chrome, dark, glow, d)
	rim_r = d.rim_r
	top_y = d.dome_y
	var dome_r: float = d.dome_r
	var dome_y: float = d.dome_y
	var dome_at := Vector3(0, dome_y, d.dome_z)
	if d.nav:
		_add(MeshKit.blob(Vector3.ONE * 0.07, 1.0, 1.0, 8, 6), _glow(Color(1.0, 0.15, 0.1), 2.5), Vector3(-rim_r - 0.04, 0.0, 0.0))
		_add(MeshKit.blob(Vector3.ONE * 0.07, 1.0, 1.0, 8, 6), _glow(Color(0.2, 1.0, 0.3), 2.5), Vector3(rim_r + 0.04, 0.0, 0.0))
	_decal(decal, paint, rim_r, shape)
	# Cockpit: chrome base ring, pilot, glass.
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(dome_r * 1.02, 0.06 + dome_r * 0.04, 8)), _seg), chrome, dome_at)
	var h := dome_r * 0.4 * float(d.pilot_k)
	pilot_model = PilotModel.new()
	pilot_model.position = dome_at + Vector3(0, dome_r * 0.55, 0)
	pivot.add_child(pilot_model)
	_pilot_lod = float(_qs.lod) * 0.45
	pilot_model.build(pilot, h, bool(_qs.face), _pilot_lod)
	var glass := MeshInstance3D.new()
	var dome_pts := []
	for k in 9:
		var a := deg_to_rad(90.0 * float(k) / 8.0)
		dome_pts.append(Vector2(sin(a), cos(a)) * dome_r)
	glass.mesh = _lathe(dome_pts, [], maxi(16, _seg - 8))
	glass.material_override = Gfx.glass(dome_c)
	glass.position = dome_at
	glass.scale = Vector3(1.0, 1.15, 1.0)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(glass)
	# Bake the static hull.
	_bake(pivot, _merge)
	# Underglow and soft shadow.
	underglow = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(rim_r * 2.6, rim_r * 2.6)
	qm.orientation = PlaneMesh.FACE_Y
	underglow.mesh = qm
	underglow.material_override = Gfx.additive(Color(trail_color.r, trail_color.g, trail_color.b, 0.55))
	underglow.position = Vector3(0, -0.62, 0)
	underglow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(underglow)
	if not _shadows:
		shadow = MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(rim_r * 2.4, rim_r * 2.6)
		sq.orientation = PlaneMesh.FACE_Y
		shadow.mesh = sq
		shadow.material_override = Gfx.blob_shadow_mat()
		shadow.position = Vector3(0, -0.84, 0)
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(shadow)
	# Ion Shield bubble (hidden until used).
	shield = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = maxf(2.6, rim_r + 0.6)
	sph.height = sph.radius * 2.2
	sph.radial_segments = 32
	sph.rings = 16
	shield.mesh = sph
	shield.material_override = Gfx.shield(Color(0.35, 0.8, 1.0))
	shield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shield.visible = false
	add_child(shield)
	# Engine trail.
	var tail_z := rim_r + 0.4
	if not thrusters.is_empty():
		tail_z = thrusters[0].position.z + 0.3
	trail = _particles(Vector3(0, 0.0, tail_z), trail_color, int(30 * float(_qs.particles)), 0.55, 0.75)
	# Drift sparks at both rear corners, with a hot glow while drifting.
	for sx: float in [-1.0, 1.0]:
		var at := Vector3(sx * rim_r * 0.8, -0.35, rim_r * 0.6)
		var p := _particles(at, SPARK_COLORS[0], int(26 * float(_qs.particles)) + 6, 0.32, 0.14)
		p.emitting = false
		p.spread = 40.0
		p.initial_velocity_min = 6.0
		p.initial_velocity_max = 11.0
		p.direction = Vector3(sx * 0.5, 0.7, 1.0)
		p.gravity = Vector3(0, -14, 0)
		p.particle_flag_align_y = true
		var mat: StandardMaterial3D = p.mesh.surface_get_material(0)
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		(p.mesh as QuadMesh).size = Vector2(0.08, 0.5)
		sparks.append(p)
		_spark_mats.append(mat)
		var g := MeshInstance3D.new()
		var gq := QuadMesh.new()
		gq.size = Vector2(1.6, 1.6)
		g.mesh = gq
		g.material_override = Gfx.additive(Color(1, 1, 1, 0.9), null, true)
		g.position = at + Vector3(0, 0.1, 0)
		g.visible = false
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(g)
		_spark_glow.append(g)
	if not thrusters.is_empty():
		thruster = thrusters[0]


# ---------------------------------------------------------------- parts
## Engine nozzle facing backwards (+Z) at pos, with a live flame.
func _nozzle(pos: Vector3, r: float, length: float, chrome: Material, dark: Material, glow: Material, into: MeshKit.Merger = null) -> void:
	var rot := Vector3(90, 0, 0)
	var scl := Vector3(r, length, r)
	_add(_lathe([Vector2(0.9, 1.0), Vector2(1.0, 0.94), Vector2(0.95, 0.5), Vector2(0.8, 0.0), Vector2(0.5, -0.12), Vector2(0, -0.14)], [1], 16), chrome, pos, rot, scl, into)
	_add(_lathe([Vector2(0.78, 0.3), Vector2(0.9, 1.0)], [], 16), dark, pos, rot, scl, into)
	_add(_lathe([Vector2(0, 0.32), Vector2(0.8, 0.32)], [], 16), glow, pos, rot, scl, into)
	_flame(pos + Vector3(0, 0, length * 0.95), r * 0.85, length * 3.0)


func _flame(pos: Vector3, r: float, length: float, forward := false) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	node.rotation_degrees = Vector3(90 if forward else -90, 0, 0)
	pivot.add_child(node)
	var prof := [Vector2(0, 0), Vector2(1.0, 0.0), Vector2(0.95, -0.25), Vector2(0.6, -0.65), Vector2(0, -1.0)]
	var outer := MeshInstance3D.new()
	outer.mesh = _lathe(prof, [1], 14)
	var om := Gfx.flame(trail_color, false)
	outer.material_override = om
	outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(outer)
	var inner := MeshInstance3D.new()
	inner.mesh = outer.mesh
	var im := Gfx.flame(trail_color, true)
	inner.material_override = im
	inner.scale = Vector3(0.5, 0.65, 0.5)
	inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(inner)
	node.set_meta("r", r)
	node.set_meta("len", length)
	node.scale = Vector3(r, length * 0.4, r)
	if not forward:
		thrusters.append(node)
		_flame_r.append(r)
		_flame_len.append(length)
		_flame_mats.append(om)
		_flame_mats.append(im)
	return node


## Trim band with running lights (lathe ring around Y).
func _trim_band(r: float, y: float, hgt: float, out: float, mat: Material, into: MeshKit.Merger = null) -> void:
	_add(_lathe([Vector2(r - 0.02, y + hgt * 0.5), Vector2(r + out, y + hgt * 0.3), Vector2(r + out, y - hgt * 0.3), Vector2(r - 0.02, y - hgt * 0.5)], [1, 2]), mat, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, into)


func _lights_mat(base: Color, count: float, opts := {}) -> ShaderMaterial:
	var o := {"lights": 1.0, "light_count": count, "light_v": 0.5, "light_w": 0.22, "pattern": 3, "metal": 0.8 if _qs.reflect else 0.35, "rough": 0.3}
	o.merge(opts, true)
	return _hull_mat(base, base, o)


# ---------------------------------------------------------------- craft designs
func _classic(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var pts := [Vector2(0, 0.4), Vector2(0.6, 0.39), Vector2(1.05, 0.33), Vector2(1.45, 0.22), Vector2(1.75, 0.11), Vector2(1.95, 0.03),
		Vector2(1.95, -0.05), Vector2(1.75, -0.13), Vector2(1.35, -0.21), Vector2(0.85, -0.27), Vector2(0.62, -0.29), Vector2(0.6, -0.4), Vector2(0, -0.42)]
	var o := {"panels_u": 16.0, "panels_v": 5.0, "under_v": _v_at(pts, 6)}
	o.merge(ho, true)
	var hm := _hull_mat(paint, under, o)
	_add(_lathe(pts, [5, 6, 10, 11]), hm)
	_trim_band(1.95, -0.01, 0.12, 0.09, _lights_mat(Color(0.18, 0.18, 0.24), 24.0))
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(0.6, 0.04, 8)), _seg), glow, Vector3(0, -0.4, 0))
	for k in 3:
		var a := deg_to_rad(90.0 + 120.0 * float(k))
		_add(MeshKit.blob(Vector3(0.2, 0.1, 0.2), 1.0, 1.0, 12, 8), chrome, Vector3(cos(a) * 1.2, -0.27, sin(a) * 1.2))
	_add(MeshKit.blob(Vector3(0.05, 0.3, 0.36), 1.0, 1.0, 12, 10, Vector2(0.6, 0.35), 0.0, Vector2(0.0, 1.2)), hm, Vector3(0, 0.5, 1.15))
	for sx: float in [-1.0, 1.0]:
		_nozzle(Vector3(sx * 0.55, 0.16, 1.45), 0.2, 0.32, chrome, dark, glow)
	d.dome_r = 0.85
	d.dome_y = 0.3
	d.rim_r = 2.0


func _bubble(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var pts := [Vector2(0, 0.05), Vector2(1.0, 0.06), Vector2(1.08, 0.18), Vector2(1.35, 0.2), Vector2(1.56, 0.1), Vector2(1.62, -0.04), Vector2(1.48, -0.2), Vector2(1.0, -0.3), Vector2(0.5, -0.33), Vector2(0, -0.34)]
	var o := {"panels_u": 12.0, "panels_v": 4.0, "under_v": _v_at(pts, 5)}
	o.merge(ho, true)
	var hm := _hull_mat(paint, under, o)
	_add(_lathe(pts, [1, 2, 5]), hm)
	_trim_band(1.6, -0.06, 0.12, 0.08, _lights_mat(Color(0.2, 0.2, 0.26), 20.0))
	for k in 4:
		var a := deg_to_rad(45.0 + 90.0 * float(k))
		_add(MeshKit.blob(Vector3(0.3, 0.22, 0.4), 1.0, 1.0, 14, 10), hm, Vector3(cos(a) * 1.42, -0.16, sin(a) * 1.42), Vector3(0, -rad_to_deg(a) + 90.0, 0))
		_add(MeshKit.blob(Vector3(0.18, 0.04, 0.18), 1.0, 1.0, 10, 6), glow, Vector3(cos(a) * 1.42, -0.37, sin(a) * 1.42))
	for sx: float in [-1.0, 1.0]:
		_nozzle(Vector3(sx * 1.0, -0.14, 1.05), 0.17, 0.28, chrome, dark, glow)
	d.dome_r = 1.12
	d.dome_y = 0.14
	d.rim_r = 1.62


func _rocket(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var pts := [Vector2(0, 2.1), Vector2(0.3, 1.9), Vector2(0.62, 1.45), Vector2(0.88, 0.8), Vector2(1.0, 0.0), Vector2(0.98, -0.9), Vector2(0.85, -1.6), Vector2(0.72, -1.95), Vector2(0, -2.0)]
	var o := {"panels_u": 10.0, "panels_v": 7.0}
	o.merge(ho, true)
	var hm := _hull_mat(paint, under, o)
	var body_scl := Vector3(1.3, 1.0, 0.42)
	_add(_lathe(pts, [7]), hm, Vector3.ZERO, Vector3(-90, 0, 0), body_scl)
	# Nose stripe in the trail colour.
	_add(_lathe([Vector2(0.645, 1.4), Vector2(0.725, 1.2)], []), _glow(trail_color, 1.6), Vector3.ZERO, Vector3(-90, 0, 0), body_scl * Vector3(1.02, 1.0, 1.04))
	for sx: float in [-1.0, 1.0]:
		_add(MeshKit.blob(Vector3(0.8, 0.05, 0.48), 0.6, 0.6, 14, 8), hm, Vector3(sx * 1.35, -0.06, 1.05), Vector3(0, sx * -28.0, sx * -10.0))
		_add(MeshKit.blob(Vector3(0.06, 0.06, 0.06), 1.0, 1.0, 8, 6), _glow(Color(1.0, 0.15, 0.1) if sx < 0.0 else Color(0.2, 1.0, 0.3), 2.5), Vector3(sx * 2.05, -0.06, 1.42))
		_add(MeshKit.blob(Vector3(0.2, 0.13, 0.42), 1.0, 0.7, 12, 8), dark, Vector3(sx * 0.98, 0.04, -0.2))
		_nozzle(Vector3(sx * 0.45, 0.0, 1.78), 0.3, 0.38, chrome, dark, glow)
	_add(MeshKit.blob(Vector3(0.05, 0.42, 0.45), 1.0, 1.0, 12, 10, Vector2(0.5, 0.4), 0.0, Vector2(0.0, 1.3)), hm, Vector3(0, 0.55, 1.4))
	d.dome_r = 0.72
	d.dome_y = 0.3
	d.dome_z = -0.4
	d.rim_r = 1.5
	d.nav = false


func _ring(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var pts := [Vector2(0, 0.42), Vector2(0.55, 0.4), Vector2(1.0, 0.28), Vector2(1.35, 0.06), Vector2(1.35, -0.06), Vector2(1.0, -0.28), Vector2(0.5, -0.4), Vector2(0, -0.42)]
	var o := {"panels_u": 12.0, "panels_v": 4.0, "under_v": _v_at(pts, 4)}
	o.merge(ho, true)
	_add(_lathe(pts, [3, 4]), _hull_mat(paint, under, o))
	spin_ring = Node3D.new()
	pivot.add_child(spin_ring)
	var rm := MeshKit.Merger.new()
	var lm := _lights_mat(paint.darkened(0.35), 30.0, {"light_v": 0.25, "light_w": 0.08})
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(2.12, 0.17, 12)), _seg), lm, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, rm)
	for k in 3:
		var a := TAU * float(k) / 3.0
		_add(MeshKit.blob(Vector3(0.07, 0.07, 0.42), 1.0, 1.0, 8, 6), chrome, Vector3(sin(a), 0, cos(a)) * 1.72, Vector3(0, rad_to_deg(a), 0), Vector3.ONE, rm)
	_bake(spin_ring, rm)
	for sx: float in [-1.0, 1.0]:
		_nozzle(Vector3(sx * 0.42, 0.0, 1.1), 0.18, 0.3, chrome, dark, glow)
	d.dome_r = 0.8
	d.dome_y = 0.32
	d.rim_r = 1.35
	d.nav = false


func _manta(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var o := {"panels_u": 14.0, "panels_v": 6.0, "under_v": 0.55}
	o.merge(ho, true)
	var hm := _hull_mat(paint, under, o)
	_add(MeshKit.blob(Vector3(2.25, 0.24, 1.6), 0.6, 1.35, maxi(24, _seg), 14), hm, Vector3(0, 0, 0.1))
	for sx: float in [-1.0, 1.0]:
		_add(MeshKit.blob(Vector3(0.16, 0.07, 0.45), 1.0, 1.0, 10, 8, Vector2(0.6, 0.6)), hm, Vector3(sx * 0.55, -0.04, -1.5), Vector3(-12, sx * 12.0, 0))
		_add(MeshKit.blob(Vector3(0.5, 0.03, 0.12), 1.0, 1.0, 12, 6), glow, Vector3(sx * 1.1, -0.2, 0.15))
		_nozzle(Vector3(sx * 0.5, 0.06, 1.3), 0.18, 0.3, chrome, dark, glow)
	_add(MeshKit.blob(Vector3(0.07, 0.07, 1.1), 1.0, 1.0, 10, 8), dark, Vector3(0, 0.02, 2.4))
	_add(MeshKit.blob(Vector3.ONE * 0.1, 1.0, 1.0, 8, 6), glow, Vector3(0, 0.02, 3.5))
	d.dome_r = 0.7
	d.dome_y = 0.14
	d.rim_r = 2.2


func _mothership(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var pts := [Vector2(0, 0.56), Vector2(0.85, 0.56), Vector2(0.95, 0.46), Vector2(1.35, 0.4), Vector2(1.46, 0.26), Vector2(2.0, 0.1),
		Vector2(2.2, 0.02), Vector2(2.2, -0.08), Vector2(1.9, -0.2), Vector2(1.2, -0.4), Vector2(0.5, -0.5), Vector2(0, -0.52)]
	var o := {"panels_u": 20.0, "panels_v": 7.0, "under_v": _v_at(pts, 7)}
	o.merge(ho, true)
	_add(_lathe(pts, [1, 2, 3, 4, 5, 7]), _hull_mat(paint, under, o))
	_trim_band(1.4, 0.32, 0.12, 0.08, _lights_mat(Color(0.15, 0.15, 0.2), 30.0))
	_trim_band(2.2, -0.03, 0.12, 0.08, _lights_mat(Color(0.18, 0.18, 0.24), 36.0))
	for k in 4:
		var a := deg_to_rad(45.0 + 90.0 * float(k))
		_add(MeshKit.blob(Vector3(0.2, 0.06, 0.2), 1.0, 1.0, 10, 6), glow, Vector3(cos(a) * 1.2, -0.43, sin(a) * 1.2))
	for k in 3:
		var a := deg_to_rad(-30.0 + 120.0 * float(k))
		var p := Vector3(cos(a) * 1.15, 0.6, sin(a) * 1.15)
		_add(MeshKit.blob(Vector3(0.05, 0.22, 0.05), 1.0, 1.0, 8, 6), chrome, p)
		_add(MeshKit.blob(Vector3.ONE * 0.07, 1.0, 1.0, 8, 6), _glow(Color(1.0, 0.3, 0.25), 2.5), p + Vector3(0, 0.24, 0))
	for x: float in [-0.7, 0.0, 0.7]:
		_nozzle(Vector3(x, -0.05, 1.75), 0.2, 0.3, chrome, dark, glow)
	d.dome_r = 0.82
	d.dome_y = 0.56
	d.rim_r = 2.25


func _orb(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var pts := []
	for k in 13:
		var a := deg_to_rad(180.0 * float(k) / 12.0)
		pts.append(Vector2(sin(a), cos(a)) * 1.3)
	var o := {"panels_u": 10.0, "panels_v": 6.0, "under_v": 0.62}
	o.merge(ho, true)
	_add(_lathe(pts, []), _hull_mat(paint, under, o), Vector3(0, -0.1, 0))
	_trim_band(1.3, -0.1, 0.2, 0.07, _lights_mat(Color(0.16, 0.16, 0.22), 22.0))
	_add(MeshKit.blob(Vector3(0.32, 0.32, 0.12), 1.0, 1.0, 16, 10), _glow(trail_color, 2.6), Vector3(0, -0.15, -1.3))
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(0.36, 0.05, 8)), _seg), chrome, Vector3(0, -0.15, -1.3), Vector3(90, 0, 0))
	for k in 4:
		var a := deg_to_rad(90.0 * float(k) + 45.0)
		_add(MeshKit.blob(Vector3(0.15, 0.06, 0.15), 1.0, 1.0, 10, 6), dark, Vector3(cos(a) * 0.75, -1.25, sin(a) * 0.75))
	var lm := _lights_mat(paint.darkened(0.4), 26.0, {"light_v": 0.25, "light_w": 0.1})
	spin_ring = Node3D.new()
	pivot.add_child(spin_ring)
	var r1 := MeshKit.Merger.new()
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(1.85, 0.08, 8)), _seg), lm, Vector3.ZERO, Vector3(0, 0, 70), Vector3.ONE, r1)
	_bake(spin_ring, r1)
	spin_ring2 = Node3D.new()
	pivot.add_child(spin_ring2)
	var r2 := MeshKit.Merger.new()
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(2.05, 0.07, 8)), _seg), lm, Vector3.ZERO, Vector3(70, 0, 0), Vector3.ONE, r2)
	_bake(spin_ring2, r2)
	_nozzle(Vector3(0, -0.45, 1.05), 0.22, 0.3, chrome, dark, glow)
	d.dome_r = 0.65
	d.dome_y = 1.0
	d.rim_r = 1.35
	d.nav = false


func _crystal(paint: Color, _under: Color, chrome: Material, glow: Material, d: Dictionary) -> void:
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(paint.r, paint.g, paint.b, 0.72)
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.metallic = 0.25
	cm.roughness = 0.04
	cm.rim_enabled = true
	cm.rim = 0.8
	cm.rim_tint = 0.2
	cm.emission_enabled = true
	cm.emission = paint
	cm.emission_energy_multiplier = 0.55
	var gem := MeshKit.faceted(_lathe([Vector2(0, 1.0), Vector2(0.55, 0.45), Vector2(0.62, 0.0), Vector2(0.5, -0.45), Vector2(0, -1.0)], [1, 2, 3], 6))
	var core := MeshKit.blob(Vector3(0.35, 0.25, 0.95), 1.0, 1.0, 14, 8)
	_add(core, _glow(trail_color, 2.4), Vector3(0, 0, 0.1))
	_add(gem, cm, Vector3.ZERO, Vector3(-90, 30, 0), Vector3(1.35, 2.2, 0.6))
	for sx: float in [-1.0, 1.0]:
		_add(gem, cm, Vector3(sx * 1.3, -0.05, 0.55), Vector3(-90, 30, sx * 12.0), Vector3(0.42, 1.1, 0.32))
		_add(gem, cm, Vector3(sx * 0.7, 0.25, 1.2), Vector3(-75, 0, sx * 30.0), Vector3(0.25, 0.6, 0.2))
	spin_ring = Node3D.new()
	pivot.add_child(spin_ring)
	var rm := MeshKit.Merger.new()
	for k in 3:
		var a := TAU * float(k) / 3.0
		_add(gem, cm, Vector3(cos(a), 0.0, sin(a)) * 2.0, Vector3(0, 0, 0), Vector3(0.18, 0.4, 0.18), rm)
	_bake(spin_ring, rm, false)
	_flame(Vector3(0, 0, 2.2), 0.35, 1.1)
	d.dome_r = 0.6
	d.dome_y = 0.3
	d.rim_r = 1.6
	d.nav = false


func _bioship(paint: Color, under: Color, dark: Material, glow: Material, d: Dictionary) -> void:
	var hm := _hull_mat(paint, paint.darkened(0.45), {"pattern": 1, "metal": 0.05, "rough": 0.45, "coat": 0.6})
	_add(MeshKit.blob(Vector3(1.5, 0.7, 1.95), 1.0, 1.0, maxi(24, _seg), 16, Vector2.ONE, 0.12), hm)
	for k in 5:
		var a := deg_to_rad(-60.0 + 30.0 * float(k))
		_add(MeshKit.blob(Vector3.ONE * 0.2, 1.0, 1.0, 10, 6), glow, Vector3(sin(a) * 1.0, 0.5, cos(a) * 1.0 - 0.3))
	var um := _hull_mat(under, under.darkened(0.3), {"pattern": 1, "metal": 0.0, "rough": 0.6})
	for sx: float in [-1.0, 1.0]:
		_add(MeshKit.blob(Vector3(0.9, 0.04, 0.6), 1.0, 1.0, 14, 8, Vector2.ONE, 0.15), um, Vector3(sx * 1.35, 0.05, 0.4), Vector3(0, sx * 20.0, sx * 22.0))
		_add(MeshKit.blob(Vector3(0.1, 0.1, 0.42), 1.0, 1.0, 10, 8, Vector2(0.4, 0.4)), dark, Vector3(sx * 0.42, -0.15, -1.9), Vector3(0, sx * -20.0, 0))
	for k in 4:
		var tnode := Node3D.new()
		tnode.position = Vector3(-0.9 + 0.6 * float(k), -0.1, 1.55)
		pivot.add_child(tnode)
		var tm := MeshKit.Merger.new()
		for s in 3:
			var rr := 0.16 - 0.04 * float(s)
			_add(MeshKit.blob(Vector3(rr, rr, 0.45), 1.0, 1.0, 10, 8, Vector2(0.8, 0.8)), hm, Vector3(0, -0.04 * float(s), 0.4 + 0.75 * float(s)), Vector3(8.0 * float(s), 0, 0), Vector3.ONE, tm)
		_add(MeshKit.blob(Vector3.ONE * 0.12, 1.0, 1.0, 8, 6), glow, Vector3(0, -0.12, 2.3), Vector3.ZERO, Vector3.ONE, tm)
		_bake(tnode, tm)
		wobble.append(tnode)
	_flame(Vector3(0, 0.0, 1.95), 0.45, 1.0)
	d.dome_r = 0.7
	d.dome_y = 0.5
	d.rim_r = 1.5
	d.nav = false


func _arrow(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var o := {"panels_u": 8.0, "panels_v": 9.0}
	o.merge(ho, true)
	var hm := _hull_mat(paint, under, o)
	_add(MeshKit.blob(Vector3(1.75, 2.5, 0.22), 0.7, 0.45, maxi(24, _seg), 16, Vector2(0.1, 1.0)), hm, Vector3(0, 0, 0.1), Vector3(-90, 0, 0))
	_add(MeshKit.blob(Vector3(0.55, 1.6, 0.14), 0.7, 0.6, 16, 12, Vector2(0.2, 1.0)), _hull_mat(under, under, {"pattern": 3, "metal": 0.7, "rough": 0.3}), Vector3(0, 0.12, 0.3), Vector3(-90, 0, 0))
	for sx: float in [-1.0, 1.0]:
		_add(MeshKit.blob(Vector3(0.05, 0.38, 0.42), 1.0, 1.0, 12, 10, Vector2(0.6, 0.4), 0.0, Vector2(0.0, 1.3)), hm, Vector3(sx * 0.75, 0.38, 1.7), Vector3(0, 0, sx * -12.0))
		_add(MeshKit.blob(Vector3(0.03, 0.02, 1.3), 1.0, 1.0, 6, 4), glow, Vector3(sx * 0.9, 0.12, 0.9), Vector3(0, sx * -22.0, 0))
		_add(MeshKit.blob(Vector3.ONE * 0.07, 1.0, 1.0, 8, 6), _glow(Color(1.0, 0.15, 0.1) if sx < 0.0 else Color(0.2, 1.0, 0.3), 2.5), Vector3(sx * 1.72, 0.0, 2.3))
		_nozzle(Vector3(sx * 0.55, 0.0, 2.25), 0.15, 0.24, chrome, dark, glow)
	_nozzle(Vector3(0, 0.02, 2.4), 0.3, 0.36, chrome, dark, glow)
	d.dome_r = 0.6
	d.dome_y = 0.24
	d.dome_z = -0.2
	d.rim_r = 1.4
	d.nav = false


func _sail(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var pts := [Vector2(0, 1.9), Vector2(0.35, 1.6), Vector2(0.7, 0.9), Vector2(0.85, 0.0), Vector2(0.8, -0.9), Vector2(0.6, -1.6), Vector2(0, -1.75)]
	var o := {"panels_u": 8.0, "panels_v": 6.0}
	o.merge(ho, true)
	var scl := Vector3(1.0, 1.0, 0.6)
	_add(_lathe(pts, [5]), _hull_mat(paint, under, o), Vector3.ZERO, Vector3(-90, 0, 0), scl)
	var gold := _std(Color(1.0, 0.78, 0.3), 0.9 if _qs.reflect else 0.45, 0.2, 0.0, 1.0)
	_add(_lathe([Vector2(0.86, 0.2), Vector2(0.9, 0.1), Vector2(0.9, -0.1), Vector2(0.86, -0.2)], [1, 2]), gold, Vector3.ZERO, Vector3(-90, 0, 0), scl * Vector3(1.01, 1.0, 1.01))
	var sail := _hull_mat(Color(1.0, 0.82, 0.42), Color(1.0, 0.82, 0.42), {"pattern": 4, "panels_u": 6.0, "panels_v": 6.0, "metal": 0.6, "rough": 0.2})
	for sx: float in [-1.0, 1.0]:
		_add(MeshKit.blob(Vector3(0.025, 1.15, 1.45), 0.25, 0.25, 16, 12), sail, Vector3(sx * 1.75, 1.0, 0.2), Vector3(0, 0, sx * -35.0))
		_add(MeshKit.blob(Vector3(0.04, 1.35, 0.04), 1.0, 1.0, 6, 6), gold, Vector3(sx * 0.95, 0.65, 0.2), Vector3(0, 0, sx * -35.0))
		_add(MeshKit.blob(Vector3(0.03, 0.03, 1.4), 1.0, 1.0, 6, 4), gold, Vector3(sx * 2.4, 1.92, 0.2), Vector3(0, 0, 0))
	_nozzle(Vector3(0, 0.0, 1.62), 0.25, 0.32, chrome, dark, glow)
	d.dome_r = 0.62
	d.dome_y = 0.42
	d.rim_r = 1.2
	d.nav = false


func _phantom(paint: Color, _chrome: Material, glow: Material, d: Dictionary) -> void:
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(paint.r, paint.g, paint.b, 0.42)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.emission_enabled = true
	gm.emission = paint
	gm.emission_energy_multiplier = 0.9
	gm.rim_enabled = true
	gm.rim = 1.0
	gm.rim_tint = 0.0
	gm.roughness = 0.1
	var pts := [Vector2(0, 0.38), Vector2(0.7, 0.36), Vector2(1.3, 0.24), Vector2(1.85, 0.05), Vector2(1.9, -0.04), Vector2(1.4, -0.18), Vector2(0.6, -0.28), Vector2(0, -0.3)]
	_add(_lathe(pts, [3, 4]), gm)
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(1.35, 0.05, 8)), _seg), _glow(paint.lightened(0.3), 2.2), Vector3(0, 0.02, 0))
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(0.8, 0.04, 8)), _seg), _glow(paint.lightened(0.3), 2.2), Vector3(0, 0.05, 0))
	spin_ring = Node3D.new()
	pivot.add_child(spin_ring)
	var rm := MeshKit.Merger.new()
	var beam := _glow(Color(0.8, 0.7, 1.0), 2.8)
	for sx: float in [-1.0, 1.0]:
		_add(MeshKit.blob(Vector3(0.12, 1.2, 0.12), 1.0, 1.0, 8, 8, Vector2(0.1, 0.1)), beam, Vector3(sx * 1.3, 0.2, 0), Vector3(0, 0, sx * -80.0), Vector3.ONE, rm)
	_bake(spin_ring, rm, false)
	for k in 3:
		var tnode := Node3D.new()
		tnode.position = Vector3(-0.6 + 0.6 * float(k), -0.05, 1.5)
		pivot.add_child(tnode)
		var tm := MeshKit.Merger.new()
		_add(MeshKit.blob(Vector3(0.22, 0.08, 0.9), 1.0, 1.0, 10, 8, Vector2(0.3, 0.3)), gm, Vector3(0, 0, 0.8), Vector3.ZERO, Vector3.ONE, tm)
		_bake(tnode, tm, false)
		wobble.append(tnode)
	_flame(Vector3(0, 0.0, 1.9), 0.4, 1.0)
	d.dome_r = 0.8
	d.dome_y = 0.3
	d.rim_r = 1.9


func _dragon(paint: Color, under: Color, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var hm := _hull_mat(paint, under, {"pattern": 2, "panels_u": 22.0, "panels_v": 14.0, "metal": 0.35 if _qs.reflect else 0.15, "rough": 0.3})
	var gold := _std(Color(1.0, 0.8, 0.35), 0.9 if _qs.reflect else 0.45, 0.2, 0.0, 1.0)
	var eyes := _glow(Color(1.0, 0.85, 0.2), 3.0)
	# Body and head.
	_add(MeshKit.blob(Vector3(0.95, 0.62, 1.15), 1.0, 1.0, maxi(20, _seg), 14), hm, Vector3(0, 0, 0))
	_add(MeshKit.blob(Vector3(0.62, 0.5, 0.75), 1.0, 1.0, 20, 12), hm, Vector3(0, 0.15, -1.45))
	_add(MeshKit.blob(Vector3(0.42, 0.28, 0.6), 1.0, 1.0, 16, 10, Vector2(0.8, 0.9)), hm, Vector3(0, 0.0, -2.1))
	_add(MeshKit.blob(Vector3(0.38, 0.1, 0.5), 1.0, 1.0, 14, 8), _std(under.darkened(0.2), 0.2, 0.5), Vector3(0, -0.24, -2.0))
	for sx: float in [-1.0, 1.0]:
		_add(MeshKit.blob(Vector3(0.09, 0.42, 0.09), 1.0, 1.0, 8, 8, Vector2(0.15, 0.15), 0.0, Vector2(0.0, 0.9)), gold, Vector3(sx * 0.35, 0.65, -1.25), Vector3(-25, 0, sx * -18.0))
		_add(MeshKit.blob(Vector3(0.13, 0.09, 0.08), 1.0, 1.0, 10, 6), eyes, Vector3(sx * 0.4, 0.3, -1.85), Vector3(0, sx * -25.0, 0))
		_add(MeshKit.blob(Vector3(0.05, 0.04, 0.04), 1.0, 1.0, 6, 4), dark, Vector3(sx * 0.14, 0.1, -2.66))
		for k in 3:
			_add(MeshKit.blob(Vector3(0.035, 0.08, 0.035), 1.0, 1.0, 6, 4, Vector2(0.2, 0.2)), _std(Color(1, 1, 1), 0.0, 0.3), Vector3(sx * (0.12 + 0.1 * float(k)), -0.16, -2.45 + 0.12 * float(k)), Vector3(180, 0, 0))
		# Wings.
		var wing := Node3D.new()
		wing.position = Vector3(sx * 0.75, 0.35, -0.1)
		pivot.add_child(wing)
		var wm := MeshKit.Merger.new()
		_add(MeshKit.blob(Vector3(1.3, 0.04, 0.7), 1.0, 1.4, 16, 8, Vector2.ONE, 0.0), _hull_mat(under, under.darkened(0.3), {"pattern": 1, "metal": 0.0, "rough": 0.6}), Vector3(sx * 1.2, 0.0, 0.2), Vector3(0, sx * 15.0, 0), Vector3.ONE, wm)
		_add(MeshKit.blob(Vector3(1.3, 0.05, 0.05), 1.0, 1.0, 8, 6), gold, Vector3(sx * 1.2, 0.02, -0.4), Vector3(0, sx * 15.0, 0), Vector3.ONE, wm)
		_bake(wing, wm)
		flaps.append(wing)
	# Tail segments.
	var r := 0.72
	for k in 4:
		var seg := Node3D.new()
		seg.position = Vector3(0, 0, 1.0 + float(k) * 0.72)
		pivot.add_child(seg)
		var sm := MeshKit.Merger.new()
		_add(MeshKit.blob(Vector3(r, r * 0.8, r * 0.75), 1.0, 1.0, 16, 10), hm, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, sm)
		_add(MeshKit.blob(Vector3(0.04, r * 0.5, r * 0.4), 1.0, 1.0, 8, 8, Vector2(0.3, 0.3), 0.0, Vector2(0, 1.0)), gold, Vector3(0, r * 0.8, 0), Vector3.ZERO, Vector3.ONE, sm)
		if k == 3:
			_add(MeshKit.blob(Vector3(0.05, 0.5, 0.45), 1.0, 1.0, 10, 8, Vector2(0.5, 0.4), 0.0, Vector2(0.0, 1.2)), gold, Vector3(0, 0.15, 0.4), Vector3.ZERO, Vector3.ONE, sm)
		_bake(seg, sm)
		wobble.append(seg)
		r *= 0.8
	_flame(Vector3(0, -0.1, 3.4), 0.35, 1.0)
	breath = _flame(Vector3(0, -0.05, -2.75), 0.3, 1.6, true)
	breath.visible = false
	d.dome_r = 0.55
	d.dome_y = 0.5
	d.dome_z = -0.05
	d.rim_r = 1.2
	d.nav = false


func _dyson(paint: Color, under: Color, ho: Dictionary, chrome: Material, dark: Material, glow: Material, d: Dictionary) -> void:
	var star := Gfx.hull(Color(1.0, 0.62, 0.2), Color(0.9, 0.25, 0.05), Color(1.0, 0.95, 0.5), {"pattern": 1, "metal": 0.0, "rough": 0.8, "coat": 0.0, "rim_amt": 1.0})
	_hulls.append(star)
	var core := MeshKit.blob(Vector3.ONE * 0.9, 1.0, 1.0, maxi(20, _seg), 14)
	_add(core, star)
	var corona := MeshInstance3D.new()
	var cq := QuadMesh.new()
	cq.size = Vector2(3.6, 3.6)
	corona.mesh = cq
	corona.material_override = Gfx.additive(Color(1.0, 0.65, 0.25, 0.7), null, true)
	corona.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(corona)
	spin_ring = Node3D.new()
	pivot.add_child(spin_ring)
	var rm := MeshKit.Merger.new()
	var o := {"panels_u": 3.0, "panels_v": 3.0}
	o.merge(ho, true)
	var pm := _hull_mat(paint, under, o)
	_add(MeshKit.lathe(PackedVector2Array(_torus_pts(1.72, 0.07, 8)), _seg), _lights_mat(Color(0.2, 0.2, 0.25), 24.0, {"light_v": 0.25, "light_w": 0.1}), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, rm)
	for k in 8:
		var a := TAU * float(k) / 8.0
		_add(MeshKit.blob(Vector3(0.38, 0.46, 0.05), 0.35, 0.35, 12, 8), pm, Vector3(cos(a) * 1.72, 0, sin(a) * 1.72), Vector3(0, -rad_to_deg(a) + 90.0, 0), Vector3.ONE, rm)
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		_add(MeshKit.blob(Vector3(0.04, 0.04, 0.5), 1.0, 1.0, 6, 4), chrome, Vector3(cos(a), 0, sin(a)) * 1.25, Vector3(0, -rad_to_deg(a) + 90.0, 0), Vector3.ONE, rm)
	_bake(spin_ring, rm)
	_add(_lathe([Vector2(0, 0.95), Vector2(0.55, 0.92), Vector2(0.6, 0.84), Vector2(0.38, 0.72), Vector2(0, 0.7)], [1, 2]), chrome)
	for sx: float in [-1.0, 1.0]:
		_nozzle(Vector3(sx * 0.5, -0.55, 1.0), 0.18, 0.28, chrome, dark, glow)
	d.dome_r = 0.5
	d.dome_y = 0.94
	d.rim_r = 1.8
	d.nav = false


func _decal(decal: String, paint: Color, rim_r: float, shape: String) -> void:
	var white := _std(Color(0.95, 0.95, 1.0), 0.3, 0.35, 0.0, 1.0)
	var zs := 1.55 if shape == "rocket" else (0.72 if shape == "manta" else 1.0)
	var y0 := 0.36 if shape in ["classic", "mothership"] else 0.3
	match decal:
		"stripes":
			for sx: float in [-0.35, 0.35]:
				_add(MeshKit.blob(Vector3(0.1, 0.025, rim_r * 0.8 * zs), 0.4, 0.4, 8, 6), white, Vector3(sx, y0, 0))
		"checker":
			var c := _checker_mat(paint)
			_add(MeshKit.lathe(PackedVector2Array(_torus_pts(rim_r * 0.88, 0.06, 6)), _seg), c, Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(1, 0.5, zs))
		"flames":
			var f := _glow(Color(1.0, 0.45, 0.1), 1.8)
			for k in 5:
				var a := deg_to_rad(-50.0 + 25.0 * float(k))
				_add(MeshKit.blob(Vector3(0.09, 0.03, 0.55), 1.0, 1.0, 8, 6, Vector2(0.3, 0.3)), f, Vector3(sin(a) * rim_r * 0.6, y0 - 0.04, cos(a) * rim_r * 0.6 * zs), Vector3(0, rad_to_deg(a), 0))
		"stars":
			var s := _glow(Color(1.0, 0.95, 0.5), 2.0)
			for k in 7:
				var a := TAU * float(k) / 7.0
				_add(MeshKit.star(0.13, 0.06, 0.04), s, Vector3(cos(a) * rim_r * 0.7, y0 - 0.06, sin(a) * rim_r * 0.7 * zs), Vector3(-90, 0, 0))
		"zigzag":
			var z := _glow(Color(0.3, 1.0, 0.9), 1.8)
			for k in 10:
				var a := TAU * float(k) / 10.0
				_add(MeshKit.blob(Vector3(0.05, 0.025, 0.35), 0.6, 0.6, 6, 4), z, Vector3(cos(a) * rim_r * 0.78, 0.2, sin(a) * rim_r * 0.78 * zs), Vector3(0, rad_to_deg(-a) + (35.0 if k % 2 == 0 else -35.0), 0))


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


func _particles(pos: Vector3, c: Color, amount: int, life: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(4, amount)
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
	mat.albedo_color = Color(c.r, c.g, c.b, 0.85)
	mat.albedo_texture = Gfx.soft_dot()
	mat.vertex_color_use_as_albedo = true
	mat.disable_fog = true
	qm.material = mat
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	p.mesh = qm
	pivot.add_child(p)
	return p


## Show a hit: rockets and mines throw the craft up, a comet squashes it,
## a laser jolts it sideways, an EMP makes its lights flicker, a tractor beam
## pulses it green, a blocked hit flashes the shield colour.
func react(kind: String) -> void:
	var d: Array = REACT.get(kind, REACT.hazard)
	_react = kind if REACT.has(kind) else "hazard"
	_react_len = float(d[1])
	_react_t = _react_len
	flash = 1.0
	_last_flash = 1.0
	for m in _hulls:
		m.set_shader_parameter("flash_color", d[0])


func _react_tick(dt: float) -> void:
	if _react_t <= 0.0 or pivot == null:
		return
	_react_t = maxf(0.0, _react_t - dt)
	var k := 1.0 - _react_t / _react_len
	match _react:
		"rocket", "mine":
			pivot.position.y += sin(PI * clampf(k * 1.5, 0.0, 1.0)) * 1.5
			pivot.rotation.x += sin(PI * clampf(k * 1.5, 0.0, 1.0)) * 0.5
		"comet":
			var s := (1.0 - k) * (1.0 - k)
			pivot.scale = Vector3(1.0 + 0.4 * s, 1.0 - 0.5 * s, 1.0 + 0.4 * s)
		"laser":
			pivot.position.x = sin(k * 34.0) * 0.35 * (1.0 - k)
		"emp":
			flash = 0.7 if int(k * 24.0) % 2 == 0 else 0.0
		"tractor":
			flash = 0.3 + 0.25 * sin(k * 26.0)
	if _react_t <= 0.0:
		pivot.scale = Vector3.ONE
		pivot.position.x = 0.0
		flash = 0.0


## Per-frame visual state from the racer.
func animate(dt: float, throttle: float, boosting: bool, drift_tier: int, drifting: bool, speed_ratio: float) -> void:
	_t += dt
	if spin_ring:
		spin_ring.rotate_y(dt * (3.0 + speed_ratio * 12.0))
	if spin_ring2:
		spin_ring2.rotate_y(-dt * (2.0 + speed_ratio * 8.0))
	for k in wobble.size():
		wobble[k].rotation.y = sin(_t * 5.0 + float(k) * 0.8) * (0.14 + 0.05 * float(k)) - steer * 0.12 * float(k + 1) * 0.3
	for k in flaps.size():
		var sx := -1.0 if k == 0 else 1.0
		flaps[k].rotation.z = sx * (sin(_t * (5.0 + speed_ratio * 4.0)) * 0.35 + 0.1)
	_boost_k = move_toward(_boost_k, 1.0 if boosting else 0.0, dt * 4.0)
	var power := 0.35 + throttle * 0.55 + _boost_k * 0.9
	var flick := 0.88 + 0.12 * sin(_t * 47.0) + 0.06 * sin(_t * 23.0)
	var wide := 1.0 + 0.3 * _boost_k
	for k in thrusters.size():
		var r := _flame_r[k]
		thrusters[k].scale = Vector3(r * wide, _flame_len[k] * power * flick * 0.5, r * wide)
	if absf(_boost_k - _last_boost) > 0.01:
		_last_boost = _boost_k
		for m in _flame_mats:
			m.set_shader_parameter("power", 0.6 + 0.6 * _boost_k)
		for m in _hulls:
			m.set_shader_parameter("chase", _boost_k)
	if breath:
		breath.visible = _boost_k > 0.05
		if breath.visible:
			var br: float = breath.get_meta("r")
			var bl: float = breath.get_meta("len")
			breath.scale = Vector3(br, bl * _boost_k * flick, br)
	if underglow:
		var pulse := 0.92 + 0.08 * sin(_t * 6.0)
		underglow.scale = Vector3.ONE * pulse * (1.0 + 0.25 * _boost_k)
	if shadow:
		shadow.visible = grounded
	trail.emitting = speed_ratio > 0.15
	var on := drifting and drift_tier > 0
	for k in sparks.size():
		sparks[k].emitting = on
		_spark_glow[k].visible = on
		if on:
			var sc: Color = SPARK_COLORS[clampi(drift_tier - 1, 0, 2)]
			_spark_mats[k].albedo_color = sc * 1.8
			(_spark_glow[k].material_override as StandardMaterial3D).albedo_color = Color(sc.r, sc.g, sc.b, 0.5 + 0.2 * sin(_t * 30.0 + float(k)))
			_spark_glow[k].scale = Vector3.ONE * (0.6 + 0.25 * float(drift_tier))
	_react_tick(dt)
	if flash > 0.0 or _last_flash > 0.0:
		if _react_t <= 0.0 or not (_react in ["emp", "tractor"]):
			flash = maxf(0.0, flash - dt * 3.0)
		_last_flash = flash
		for m in _hulls:
			m.set_shader_parameter("flash", flash)
	if pilot_model:
		# Faces are only animated when close enough to be seen.
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		var near := cam == null or cam.global_position.distance_squared_to(global_position) < _pilot_lod * _pilot_lod * 1.44
		if near or mood != pilot_model.mood:
			pilot_model.animate(dt, mood, steer, speed_ratio)
