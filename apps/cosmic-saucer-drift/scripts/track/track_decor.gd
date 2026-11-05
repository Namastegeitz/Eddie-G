class_name TrackDecor
extends RefCounted
## Backdrop per theme: planets, asteroid fields, alien plants, ice crystals,
## station structures, lava ground. All batched in MultiMeshes.

static var _rock_mesh: ArrayMesh = null


const GROUNDS := {
	"red": [Color(0.45, 0.2, 0.12), Color(0.9, 0.5, 0.3), 0, 0.05],
	"sulphur": [Color(0.55, 0.45, 0.15), Color(1.0, 0.4, 0.05), 1, 0.6],
	"lava": [Color(0.16, 0.07, 0.05), Color(1.0, 0.35, 0.05), 1, 1.0],
	"jungle": [Color(0.10, 0.22, 0.12), Color(0.25, 1.0, 0.6), 0, 0.6],
	"ice": [Color(0.55, 0.65, 0.8), Color(0.6, 0.85, 1.0), 2, 0.6],
	"frost": [Color(0.18, 0.12, 0.16), Color(1.0, 0.4, 0.3), 2, 0.5],
	"clouds": [Color(0.7, 0.5, 0.4), Color(1.0, 0.75, 0.55), 3, 1.0],
	"iron": [Color(0.25, 0.1, 0.06), Color(1.0, 0.6, 0.2), 1, 1.2],
}


static func build(td: TrackData, root: Node3D) -> void:
	var theme := Themes.get_theme(td.theme)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(td.id)
	var holder := Node3D.new()
	holder.name = "Decor"
	root.add_child(holder)
	for p in theme.planets:
		_planet(holder, p, theme)
	var low := _lowest(td)
	var gy := low - 50.0
	var g: String = theme.get("ground", "")
	if GROUNDS.has(g):
		var gd: Array = GROUNDS[g]
		_ground(holder, gy, gd[0], gd[1], gd[2], gd[3])
	match String(theme.get("decor", "")):
		"asteroids":
			_rocks(td, holder, rng, 320, Color(0.34, 0.29, 0.30), Vector2(2.0, 16.0), Vector2(-90.0, 110.0), 260.0)
			_rocks(td, holder, rng, 14, Color(0.28, 0.24, 0.26), Vector2(40.0, 90.0), Vector2(-250.0, 200.0), 700.0, 160.0)
		"rings":
			_rocks(td, holder, rng, 260, Color(0.75, 0.72, 0.68), Vector2(1.0, 6.0), Vector2(-60.0, 40.0), 320.0)
			_buoys(td, holder, rng, theme.neon)
		"canyon":
			_spires(td, holder, rng, gy, Color(0.5, 0.24, 0.14), 160, Vector2(30.0, 95.0), Vector2(14.0, 34.0))
			_rocks(td, holder, rng, 40, Color(0.45, 0.25, 0.18), Vector2(2.0, 6.0), Vector2(-20.0, 10.0), 120.0)
		"lava":
			_spires(td, holder, rng, gy, Color(0.45, 0.38, 0.12), 110, Vector2(25.0, 70.0), Vector2(6.0, 16.0))
		"hot":
			_spires(td, holder, rng, gy, Color(0.2, 0.1, 0.08), 120, Vector2(25.0, 70.0), Vector2(6.0, 16.0))
		"jungle":
			_plants(td, holder, rng, gy)
		"ice":
			_crystals(td, holder, rng, gy, Color(0.6, 0.85, 1.0, 0.85), Color(0.3, 0.6, 1.0))
			_rocks(td, holder, rng, 90, Color(0.7, 0.85, 1.0), Vector2(2.0, 10.0), Vector2(-30.0, 60.0), 240.0)
		"twilight":
			_crystals(td, holder, rng, gy, Color(0.4, 0.25, 0.3, 0.9), Color(1.0, 0.3, 0.25))
			_rocks(td, holder, rng, 60, Color(0.3, 0.22, 0.24), Vector2(2.0, 8.0), Vector2(-20.0, 50.0), 200.0)
		"station":
			_station(td, holder, rng)
		"twinsuns":
			_rocks(td, holder, rng, 240, Color(0.55, 0.45, 0.32), Vector2(2.0, 12.0), Vector2(-80.0, 80.0), 300.0)
			_buoys(td, holder, rng, theme.neon)
		"storm":
			_clouds(td, holder, rng, Color(0.35, 0.55, 1.0, 0.35), 90)
			_crystals(td, holder, rng, low - 30.0, Color(0.7, 0.9, 1.0, 0.6), Color(0.4, 0.7, 1.0), true)
		"diamond":
			_crystals(td, holder, rng, gy, Color(0.95, 0.95, 1.0, 0.85), Color(0.9, 0.9, 1.0))
			_spires(td, holder, rng, gy, Color(0.1, 0.08, 0.1), 60, Vector2(25.0, 60.0), Vector2(6.0, 14.0))
		"gas":
			_clouds(td, holder, rng, Color(1.0, 0.75, 0.6, 0.35), 70)
			_buoys(td, holder, rng, theme.neon)
		"iron":
			_spires(td, holder, rng, gy, Color(0.3, 0.12, 0.08), 120, Vector2(25.0, 70.0), Vector2(6.0, 16.0))


static func _lowest(td: TrackData) -> float:
	var y := INF
	for p in td.main.pts:
		y = minf(y, p.y)
	return y


static func _planet(parent: Node3D, p: Dictionary, theme: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = p.r
	sm.height = p.r * 2.0
	var hi := Gfx.tier_index(Game.quality()) >= 2
	sm.radial_segments = 72 if hi else 40
	sm.rings = 36 if hi else 20
	mi.mesh = sm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/planet.gdshader")
	mat.set_shader_parameter("color_a", p.a)
	mat.set_shader_parameter("color_b", p.b)
	mat.set_shader_parameter("rim_color", p.rim)
	mat.set_shader_parameter("sun_dir", -Themes.light_dir(theme))
	# Big backdrop worlds are gas giants (bands + storms); small ones are rocky (craters).
	mat.set_shader_parameter("bands", p.get("bands", 12.0 if float(p.r) >= 850.0 else 9.0))
	mat.set_shader_parameter("detail", 1.0 if int(Gfx.q().detail) > 0 else 0.0)
	mi.material_override = mat
	mi.position = p.pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if int(Gfx.q().detail) > 0:
		var atmo := MeshInstance3D.new()
		var am := SphereMesh.new()
		am.radius = p.r * 1.07
		am.height = p.r * 2.14
		am.radial_segments = 48
		am.rings = 24
		atmo.mesh = am
		var amat := ShaderMaterial.new()
		amat.shader = preload("res://shaders/atmo.gdshader")
		amat.set_shader_parameter("color", Color(p.rim))
		amat.set_shader_parameter("sun_dir", -Themes.light_dir(theme))
		amat.set_shader_parameter("inner", 1.0 / 1.07)
		atmo.material_override = amat
		atmo.position = p.pos
		atmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(atmo)
	if p.get("ring", false):
		var ring := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(p.r * 4.6, p.r * 4.6)
		ring.mesh = pm
		var rm := ShaderMaterial.new()
		rm.shader = preload("res://shaders/ring.gdshader")
		ring.material_override = rm
		ring.position = p.pos
		ring.rotation_degrees = Vector3(16, 0, -12)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(ring)


## Strata/dust rock material for spires, boulders and asteroids.
static func rock_mat(c: Color, strata := 1.0, top := Color(-1, 0, 0)) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/rock.gdshader")
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("top", c.lightened(0.35) if top.r < 0.0 else top)
	m.set_shader_parameter("strata", strata)
	m.set_shader_parameter("detail", 1.0 if int(Gfx.q().detail) > 0 else 0.0)
	return m


static func rock_mesh() -> ArrayMesh:
	if _rock_mesh:
		return _rock_mesh
	var sm := SphereMesh.new()
	sm.radial_segments = 9
	sm.rings = 6
	var arr := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 1.6
	for i in verts.size():
		var v := verts[i]
		verts[i] = v * (1.0 + 0.32 * noise.get_noise_3dv(v * 2.0))
	arr[Mesh.ARRAY_VERTEX] = verts
	var tmp := ArrayMesh.new()
	tmp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var st := SurfaceTool.new()
	st.create_from(tmp, 0)
	st.deindex()
	st.generate_normals()
	_rock_mesh = st.commit()
	return _rock_mesh


## Eroded rock spire: a tapered column with noisy ledges (unit height,
## centred at the origin like a CylinderMesh).
static var _spire_mesh: ArrayMesh = null
static func spire_mesh() -> ArrayMesh:
	if _spire_mesh:
		return _spire_mesh
	var segs := 9 if int(Gfx.q().detail) > 0 else 7
	var rings := 10 if int(Gfx.q().detail) > 0 else 3
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 2.2
	var pts := PackedVector2Array()
	for k in rings + 1:
		var t := float(k) / float(rings)
		var r := lerpf(0.14, 0.62, pow(t, 1.3)) * (1.0 + 0.22 * noise.get_noise_1d(t * 4.0))
		pts.append(Vector2(r, 0.5 - t))
	pts.insert(0, Vector2(0.0, 0.5))
	var lathe := MeshKit.lathe(pts, segs)
	var arr := lathe.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		var v := verts[i]
		var wob := 1.0 + 0.18 * noise.get_noise_3dv(v * 3.0)
		verts[i] = Vector3(v.x * wob, v.y, v.z * wob)
	arr[Mesh.ARRAY_VERTEX] = verts
	var tmp := ArrayMesh.new()
	tmp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_spire_mesh = MeshKit.faceted(tmp)
	return _spire_mesh


## True when p is clear of the main track by `clear` metres.
static func _clear(td: TrackData, p: Vector3, clear: float) -> bool:
	var path := td.main
	for i in range(0, path.n, 4):
		if path.pts[i].distance_squared_to(p) < clear * clear:
			return false
	return true


static func _multimesh(parent: Node3D, mesh: Mesh, tfs: Array[Transform3D], mat: Material, node_name: String, colors: Array[Color] = []) -> void:
	if tfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = tfs.size()
	for k in tfs.size():
		mm.set_instance_transform(k, tfs[k])
		if mm.use_colors:
			mm.set_instance_color(k, colors[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


static func _rocks(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, count: int, color: Color,
		size: Vector2, yrange: Vector2, reach: float, min_clear := 0.0) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	var tries := 0
	while tfs.size() < count and tries < count * 6:
		tries += 1
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lat := side * (td.width * 0.5 + rng.randf_range(14.0, reach))
		var p := path.pts[i] + path.rgt[i] * lat + Vector3.UP * rng.randf_range(yrange.x, yrange.y)
		var r := rng.randf_range(size.x, size.y)
		if not _clear(td, p, td.width * 0.5 + r + 8.0 + min_clear):
			continue
		var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		b = b.scaled(Vector3(r, r * rng.randf_range(0.6, 1.0), r * rng.randf_range(0.7, 1.2)))
		tfs.append(Transform3D(b, p))
	_multimesh(parent, rock_mesh(), tfs, rock_mat(color, 0.35), "Rocks%d" % count)


static func _ground(parent: Node3D, y: float, base: Color, glow_c: Color, mode: int, amount := 0.6) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5000, 5000)
	mi.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ground.gdshader")
	mat.set_shader_parameter("base", base)
	mat.set_shader_parameter("glow_color", glow_c)
	mat.set_shader_parameter("mode", mode)
	mat.set_shader_parameter("glow_amount", amount)
	mi.material_override = mat
	mi.position = Vector3(150, y, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


static func _plants(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, ground_y: float) -> void:
	var trunks: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var cap_cols: Array[Color] = []
	var path := td.main
	var palette := [Color(1.0, 0.35, 0.8), Color(0.3, 1.0, 0.8), Color(1.0, 0.85, 0.2), Color(0.6, 0.4, 1.0)]
	for k in 170:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lat := side * (td.width * 0.5 + rng.randf_range(6.0, 90.0))
		var top := path.pts[i] + path.rgt[i] * lat + Vector3.UP * rng.randf_range(4.0, 26.0)
		if not _clear(td, Vector3(top.x, path.pts[i].y, top.z), td.width * 0.5 + 5.0):
			continue
		var h := top.y - ground_y
		var w := rng.randf_range(0.8, 2.2)
		trunks.append(Transform3D(Basis().scaled(Vector3(w, h, w)), Vector3(top.x, ground_y + h * 0.5, top.z)))
		var cr := rng.randf_range(3.0, 8.0)
		caps.append(Transform3D(Basis().scaled(Vector3(cr, cr * 0.55, cr)), top))
		cap_cols.append(palette[k % palette.size()])
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.9
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.15, 0.32, 0.2)
	_multimesh(parent, cyl, trunks, tm, "Trunks")
	var sph := SphereMesh.new()
	sph.radial_segments = 10
	sph.rings = 5
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.emission_enabled = true
	cm.emission = Color(0.3, 0.3, 0.3)
	cm.emission_energy_multiplier = 0.6
	_multimesh(parent, sph, caps, cm, "Caps", cap_cols)


static func _crystals(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, ground_y: float,
		color := Color(0.6, 0.85, 1.0, 0.85), glow_c := Color(0.3, 0.6, 1.0), floating := false) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	for k in 150:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lat := side * (td.width * 0.5 + rng.randf_range(10.0, 160.0))
		var base := path.pts[i] + path.rgt[i] * lat
		base.y = ground_y if not floating else path.pts[i].y + rng.randf_range(-60.0, 40.0)
		var h := rng.randf_range(20.0, 75.0) * (0.3 if floating else 1.0)
		var w := rng.randf_range(3.0, 9.0) * (0.5 if floating else 1.0)
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.35, 0.35), rng.randf() * TAU, rng.randf_range(-0.35, 0.35))).scaled(Vector3(w, h, w))
		var tip := base + b.y * 0.5
		if not _clear(td, tip, td.width * 0.5 + 8.0):
			continue
		tfs.append(Transform3D(b, base + b.y * 0.5))
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0
	cyl.bottom_radius = 0.6
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.05
	mat.emission_enabled = true
	mat.emission = glow_c
	mat.emission_energy_multiplier = 0.5
	_multimesh(parent, cyl, tfs, mat, "Crystals")


static func _spires(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, ground_y: float,
		color := Color(0.2, 0.1, 0.08), count := 120, hrange := Vector2(25.0, 70.0), wrange := Vector2(6.0, 16.0)) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	for k in count:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lat := side * (td.width * 0.5 + rng.randf_range(12.0, 200.0))
		var base := path.pts[i] + path.rgt[i] * lat
		base.y = ground_y
		var h := rng.randf_range(hrange.x, hrange.y) + (path.pts[i].y - ground_y)
		var w := rng.randf_range(wrange.x, wrange.y)
		var tip := base + Vector3.UP * h
		if not _clear(td, tip, td.width * 0.5 + 10.0):
			continue
		tfs.append(Transform3D(Basis().scaled(Vector3(w, h, w)), base + Vector3.UP * h * 0.5))
	_multimesh(parent, spire_mesh(), tfs, rock_mat(color, 1.0), "Spires")


static func _clouds(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, color: Color, count: int) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	for k in count:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var p := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + rng.randf_range(30.0, 260.0)) + Vector3.UP * rng.randf_range(-70.0, 10.0)
		var r := rng.randf_range(18.0, 55.0)
		if not _clear(td, p, td.width * 0.5 + r + 6.0):
			continue
		tfs.append(Transform3D(Basis().scaled(Vector3(r * 1.8, r * 0.6, r)), p))
	var sph := SphereMesh.new()
	sph.radial_segments = 12
	sph.rings = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_multimesh(parent, sph, tfs, mat, "Clouds")


static func _buoys(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, neon: Color) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	for i in range(0, path.n, 14):
		for side: float in [-1.0, 1.0]:
			if rng.randf() < 0.4:
				continue
			var p := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + 8.0) + path.upv[i] * 3.0
			tfs.append(Transform3D(Basis.from_euler(Vector3(0.5, float(i), 0.3)), p))
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 1.2, 1.2)
	_multimesh(parent, bm, tfs, TrackBuilder.glow(neon, 1.8), "Buoys")


static func _station(td: TrackData, parent: Node3D, rng: RandomNumberGenerator) -> void:
	var center := Vector3.ZERO
	for p in td.main.pts:
		center += p
	center /= float(td.main.n)
	# Big slowly turning habitat ring behind the track.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 520.0
	tm.outer_radius = 560.0
	tm.rings = 64
	tm.ring_segments = 8
	ring.mesh = tm
	ring.material_override = TrackBuilder.flat(Color(0.5, 0.52, 0.6), 0.0, 0.7, 0.4)
	ring.position = center + Vector3(0, -120, -900)
	ring.rotation_degrees = Vector3(70, 0, 10)
	ring.set_script(preload("res://scripts/track/spinner.gd"))
	ring.set("speed", 0.03)
	parent.add_child(ring)
	# Modules and solar panels scattered around and below the course.
	var mods: Array[Transform3D] = []
	var panels: Array[Transform3D] = []
	var path := td.main
	for k in 60:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var p := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + rng.randf_range(25.0, 140.0)) + Vector3.UP * rng.randf_range(-60.0, 30.0)
		if not _clear(td, p, td.width * 0.5 + 22.0):
			continue
		var b := Basis.from_euler(Vector3(0, rng.randf() * TAU, PI * 0.5))
		mods.append(Transform3D(b.scaled(Vector3(rng.randf_range(6, 12), rng.randf_range(20, 50), rng.randf_range(6, 12))), p))
		panels.append(Transform3D(Basis.from_euler(Vector3(0.2, rng.randf() * TAU, 0)).scaled(Vector3(40, 0.6, 12)), p + Vector3.UP * 14.0))
	var cyl := CylinderMesh.new()
	cyl.radial_segments = 10
	cyl.rings = 1
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	_multimesh(parent, cyl, mods, TrackBuilder.flat(Color(0.62, 0.62, 0.68), 0.0, 0.8, 0.35), "Modules")
	var bm := BoxMesh.new()
	var pmat := TrackBuilder.flat(Color(0.12, 0.2, 0.55), 0.6, 0.9, 0.2)
	_multimesh(parent, bm, panels, pmat, "Panels")
