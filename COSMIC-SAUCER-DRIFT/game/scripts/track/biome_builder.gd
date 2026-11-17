class_name BiomeBuilder
extends RefCounted
## Volcanic biomes (content/biomes.json): colossal ridges on the horizon,
## volcanoes with glowing craters and smoke in the middle distance, basalt
## columns, obsidian shards, crystal clusters and arches beside the road,
## lava rivers on the ground far below, mist, and a fog/light tint. The
## drivable track is never touched: every formation keeps a clearance from
## the road and the shortcuts (a spatial grid of track points).
##
## Each formation variant comes from its import slot (a Meshy GLB at
## f.mesh, imported by Godot with LODs) or else from its procedural recipe
## (Formations.make, built at two detail levels with a distance switch).
## Meshes are cached for the session, so the second race on a biome builds
## nothing. Which biome a track gets: Settings > Volcanic biome (auto uses
## the track's entry in biome_defaults).

const ROCKY_GROUNDS := ["red", "sulphur", "lava", "jungle", "ice", "frost", "iron"]

static var _meshes := {}      # "biome/formation" -> {near, far, norm, source}
static var _mats := {}        # biome id + detail -> ShaderMaterial
static var last_stats := {}   # what the last build placed (tests, docs)


## The biome for this track with the current setting, or {}.
static func pick(td: TrackData) -> Dictionary:
	return pick_for(td.id, td.theme)


static func pick_for(track_id: String, theme_id: String) -> Dictionary:
	var mode := String(Save.setting("biome"))
	var id := ""
	match mode:
		"off":
			return {}
		"eerie", "divine":
			# Forced: every world with solid ground (not the space tracks).
			if String(Themes.get_theme(theme_id).get("ground", "")) in ROCKY_GROUNDS or Content.biome_defaults.has(track_id):
				id = mode
		_:
			id = String(Content.biome_defaults.get(track_id, ""))
	return Content.biome(id)


static func rock_material(biome: Dictionary, detail: int) -> ShaderMaterial:
	var key := "%s|%d" % [biome.id, detail]
	if _mats.has(key):
		return _mats[key]
	var pal: Dictionary = biome.palette
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/biome_rock.gdshader")
	for k in ["rock", "rock_hi", "ash", "lava", "lava_hot"]:
		m.set_shader_parameter(k, pal[k])
	for k in ["crack_width", "crack_glow", "ash_amount", "iridescence", "gloss"]:
		m.set_shader_parameter(k, float(pal[k]))
	m.set_shader_parameter("detail", detail)
	_mats[key] = m
	return m


static func lava_material(biome: Dictionary, radial: bool) -> ShaderMaterial:
	var key := "%s|lava|%s" % [biome.id, radial]
	if _mats.has(key):
		return _mats[key]
	var pal: Dictionary = biome.palette
	var lv: Dictionary = biome.get("lava", {})
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/lava_flow.gdshader")
	m.set_shader_parameter("lava", pal.lava)
	m.set_shader_parameter("lava_hot", pal.lava_hot)
	m.set_shader_parameter("crust_color", Color(pal.rock).darkened(0.4))
	m.set_shader_parameter("glow", float(lv.get("glow", 3.0)))
	m.set_shader_parameter("crust", float(lv.get("crust", 0.6)))
	m.set_shader_parameter("speed", float(lv.get("speed", 0.05)))
	m.set_shader_parameter("radial", 1.0 if radial else 0.0)
	_mats[key] = m
	return m


## Near and far meshes for one formation variant, from the import slot when
## a mesh is there, else from the recipe.
static func formation_meshes(biome: Dictionary, f: Dictionary) -> Dictionary:
	var key := "%s/%s" % [biome.id, f.id]
	if _meshes.has(key):
		return _meshes[key]
	var out := {}
	var path := String(f.get("mesh", ""))
	# A baked slot (tools/meshy/bake_lods: welded, unit space, with LODs)
	# wins; then the raw GLB; then the procedural recipe.
	var baked := path.get_basename() + "_lod.res" if path != "" else ""
	if baked != "" and ResourceLoader.exists(baked):
		var bm: Mesh = load(baked)
		if bm:
			out = {"near": bm, "far": null, "norm": Transform3D.IDENTITY, "source": "asset"}
	if out.is_empty() and path != "" and ResourceLoader.exists(path):
		out = _import(path)
	if out.is_empty():
		var rc: Dictionary = f.recipe
		out = {"near": Formations.make(rc, 2), "far": Formations.make(rc, 0), "norm": Transform3D.IDENTITY, "source": "recipe"}
	_meshes[key] = out
	return out


## A GLB from the import slot: its first mesh (with the importer's LODs) and
## the transform that maps it into unit space (base y = 0, top y = 1,
## footprint radius 1), so any Meshy model drops in at the right size.
static func _import(path: String) -> Dictionary:
	var res: Resource = load(path)
	var mesh: Mesh = null
	var xf := Transform3D.IDENTITY
	if res is Mesh:
		mesh = res
	elif res is PackedScene:
		var inst: Node = (res as PackedScene).instantiate()
		var mi := _first_mesh(inst)
		if mi:
			mesh = mi.mesh
			xf = _rel_xform(mi, inst)
		inst.free()
	if mesh == null:
		push_warning("biome: no mesh in %s, using the recipe" % path)
		return {}
	# Lay the model's long side along X (ridges then run along the horizon).
	var box0 := xf * mesh.get_aabb()
	if box0.size.z > box0.size.x * 1.2:
		xf = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO) * xf
	var box := xf * mesh.get_aabb()
	var cx := box.get_center()
	var rad := maxf(maxf(box.size.x, box.size.z) * 0.5, 0.001)
	var norm := Transform3D(Basis.from_scale(Vector3(1.0 / rad, 1.0 / maxf(box.size.y, 0.001), 1.0 / rad)),
		Vector3(-cx.x / rad, -box.position.y / maxf(box.size.y, 0.001), -cx.z / rad)) * xf
	return {"near": mesh, "far": null, "norm": norm, "source": "asset"}


static func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return n
	for c in n.get_children():
		var f := _first_mesh(c)
		if f:
			return f
	return null


static func _rel_xform(n: Node3D, root: Node) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != root and p is Node3D:
		xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


## Build the biome under `parent`. ground_y: the ground plane height.
static func build(td: TrackData, biome: Dictionary, parent: Node3D, ground_y: float) -> Node3D:
	var qs := Gfx.q()
	var detail := clampi(int(qs.detail), 0, 2)
	var holder := Node3D.new()
	holder.name = "Biome_" + String(biome.id)
	parent.add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(td.id + String(biome.id))
	var grid := TrackGrid.new(td)
	var density := float(qs.get("decor", 1.0))
	var rock := rock_material(biome, detail)
	rock.set_shader_parameter("ground_y", ground_y)   # shared material: set per build
	var placed: Array = []           # Vector3(x, z, radius) of every formation
	var craters: Array = []          # [world position of the crater, radius]
	var counts := {}
	var lod_dist := float(qs.get("lod", 80.0)) * 4.0
	for f: Dictionary in biome.formations:
		var n := maxi(2, int(round(float(f.count) * (density if String(f.ring) == "near" else 1.0))))
		var ms := formation_meshes(biome, f)
		var mat: Material = rock if (String(f.get("material", "biome")) == "biome" or ms.source == "recipe") else null
		var tfs := _place(td, grid, rng, f, n, ground_y, placed)
		counts[f.id] = tfs.size()
		for tf: Transform3D in tfs:
			var span := maxf(tf.basis.get_scale().x, 1.0)
			_add(holder, ms.near, mat, tf * ms.norm, 0.0, lod_dist + span * 3.0 if ms.far != null else 0.0)
			if ms.far != null:
				_add(holder, ms.far, mat, tf * ms.norm, lod_dist + span * 3.0, 0.0)
			if f.get("crater_glow", false) and ms.source == "recipe":
				var cr := float(f.recipe.get("crater", 0.2)) * 0.8
				var disc := tf * Transform3D(Basis.from_scale(Vector3(cr, 1.0, cr)), Vector3(0, 0.935, 0))
				_add(holder, _disc(), lava_material(biome, true), disc, 0.0, 0.0)
				if f.get("smoke", false):
					craters.append([tf * Vector3(0, 1.0, 0), tf.basis.get_scale().x * cr])
			elif f.get("smoke", false):
				# A Meshy volcano: its crater shape is its own, so only smoke
				# rises from the summit (no lava disc that might float).
				craters.append([tf * Vector3(0, 0.98, 0), tf.basis.get_scale().x * 0.15])
	_rivers(td, biome, holder, rng, grid, ground_y, placed)
	if int(qs.detail) > 0:
		_smoke(biome, holder, craters, float(qs.get("particles", 1.0)))
		_mist(td, biome, holder, rng, grid, ground_y)
	last_stats = {"biome": biome.id, "counts": counts, "craters": craters.size(), "nodes": holder.get_child_count()}
	return holder


static func _add(parent: Node3D, mesh: Mesh, mat: Material, xf: Transform3D, begin: float, end: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if begin > 0.0:
		mi.visibility_range_begin = begin
		mi.visibility_range_begin_margin = 30.0
	if end > 0.0:
		mi.visibility_range_end = end
		mi.visibility_range_end_margin = 30.0
	parent.add_child(mi)
	return mi


static var _disc_mesh: Mesh
static func _disc() -> Mesh:
	if _disc_mesh == null:
		var pm := PlaneMesh.new()
		pm.size = Vector2(2.0, 2.0)
		_disc_mesh = pm
	return _disc_mesh


## Positions for one formation variant. far: a ring of mountains facing the
## track; mid: anywhere around it; near: just beyond the road edge.
static func _place(td: TrackData, grid: TrackGrid, rng: RandomNumberGenerator, f: Dictionary, count: int, gy: float, placed: Array) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var hw := td.width * 0.5
	var ring := String(f.ring)
	var tries := 0
	while out.size() < count and tries < count * 40:
		tries += 1
		var r := rng.randf_range(float(f.scale[0]), float(f.scale[1]))
		var h := rng.randf_range(float(f.height[0]), float(f.height[1]))
		var yaw := rng.randf() * TAU
		var pos := Vector3.ZERO
		match ring:
			"far":
				var a := TAU * (float(out.size()) + rng.randf_range(-0.35, 0.35)) / float(count)
				var d := grid.radius + 260.0 + r * 0.6 + rng.randf_range(0.0, 420.0)
				pos = grid.center + Vector3(cos(a), 0.0, sin(a)) * d
				yaw = -(a + PI * 0.5)        # the ridge runs along the horizon
			"mid":
				var a2 := rng.randf() * TAU
				pos = grid.center + Vector3(cos(a2), 0.0, sin(a2)) * rng.randf_range(grid.radius * 0.35, grid.radius + 420.0)
			_:
				var i := rng.randi_range(0, td.main.n - 1)
				var side := -1.0 if rng.randf() < 0.5 else 1.0
				pos = td.main.pts[i] + td.main.rgt[i] * side * (hw + r + rng.randf_range(18.0, 110.0))
		pos.y = gy
		if not grid.clear(pos, hw + r * 1.05 + 14.0):
			continue
		var ok := true
		for q: Vector3 in placed:
			if Vector2(q.x - pos.x, q.y - pos.z).length() < (q.z + r) * 0.8:
				ok = false
				break
		if not ok:
			continue
		placed.append(Vector3(pos.x, pos.z, r))
		var b := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(r, h, r))
		out.append(Transform3D(b, pos - Vector3(0, h * 0.03, 0)))
	return out


## Lava rivers on the ground: from a volcano (or the horizon) winding toward
## the track and ending in a pool. One mesh for all rivers, one for pools.
static func _rivers(td: TrackData, biome: Dictionary, parent: Node3D, rng: RandomNumberGenerator, grid: TrackGrid, gy: float, placed: Array) -> void:
	var lv: Dictionary = biome.get("lava", {})
	var n := int(lv.get("rivers", 0))
	if n <= 0:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pools := SurfaceTool.new()
	pools.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wr: Array = lv.get("width", [10, 24])
	var y := gy + 0.6
	for k in n:
		var a := TAU * (float(k) + rng.randf_range(0.0, 0.6)) / float(n)
		var start := grid.center + Vector3(cos(a), 0.0, sin(a)) * (grid.radius + rng.randf_range(200.0, 520.0))
		var dir := (grid.center - start).normalized()
		var w := rng.randf_range(float(wr[0]), float(wr[1]))
		var pts: Array[Vector3] = []
		var p := start
		var steps := int(rng.randf_range(40.0, 70.0))
		var wiggle := rng.randf() * 10.0
		for s in steps:
			pts.append(Vector3(p.x, y, p.z))
			var turn := sin(float(s) * 0.21 + wiggle) * 0.5 + rng.randf_range(-0.12, 0.12)
			dir = dir.rotated(Vector3.UP, turn * 0.25).normalized()
			p += dir * 18.0
		var dist := 0.0
		for s in pts.size() - 1:
			var p0 := pts[s]
			var p1 := pts[s + 1]
			var t0 := (p1 - p0).normalized()
			var side := t0.cross(Vector3.UP).normalized()
			var w0 := w * (0.55 + 0.45 * float(s) / pts.size())
			var w1 := w * (0.55 + 0.45 * float(s + 1) / pts.size())
			var seg := p0.distance_to(p1)
			var a0 := p0 - side * w0 * 0.5
			var b0 := p0 + side * w0 * 0.5
			var a1 := p1 - side * w1 * 0.5
			var b1 := p1 + side * w1 * 0.5
			for v: Array in [[a0, Vector2(dist, 0)], [a1, Vector2(dist + seg, 0)], [b1, Vector2(dist + seg, 1)],
					[a0, Vector2(dist, 0)], [b1, Vector2(dist + seg, 1)], [b0, Vector2(dist, 1)]]:
				st.set_normal(Vector3.UP)
				st.set_uv(v[1])
				st.add_vertex(v[0])
			dist += seg
		# A pool where the river ends.
		var e := pts[pts.size() - 1]
		var pr := w * 1.6
		var segs := 18
		for s in segs:
			var t0 := TAU * float(s) / segs
			var t1 := TAU * float(s + 1) / segs
			var q0 := Vector3(cos(t0), 0, sin(t0))
			var q1 := Vector3(cos(t1), 0, sin(t1))
			for v: Array in [[e, Vector2(0.5, 0.5)], [e + q1 * pr, Vector2(0.5 + q1.x * 0.5, 0.5 + q1.z * 0.5)], [e + q0 * pr, Vector2(0.5 + q0.x * 0.5, 0.5 + q0.z * 0.5)]]:
				pools.set_normal(Vector3.UP)
				pools.set_uv(v[1])
				pools.add_vertex(v[0] + Vector3(0, 0.05, 0))
	var mi := MeshInstance3D.new()
	mi.name = "LavaRivers"
	mi.mesh = st.commit()
	mi.material_override = lava_material(biome, false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var pm := MeshInstance3D.new()
	pm.name = "LavaPools"
	pm.mesh = pools.commit()
	pm.material_override = lava_material(biome, true)
	pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pm)


## Smoke rising from the craters (a few big soft particles each).
static func _smoke(biome: Dictionary, parent: Node3D, craters: Array, particles: float) -> void:
	var sm: Dictionary = biome.get("smoke", {})
	if craters.is_empty() or float(sm.get("alpha", 0.0)) <= 0.0:
		return
	var c: Color = sm.get("color", Color(0.3, 0.28, 0.27))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = Gfx.soft_dot()
	mat.disable_receive_shadows = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var ramp := Gradient.new()
	ramp.set_color(0, Color(c, 0.0))
	ramp.set_color(1, Color(c, 0.0))
	ramp.add_point(0.2, Color(c, float(sm.alpha)))
	ramp.add_point(0.7, Color(c, float(sm.alpha) * 0.6))
	var hr: Array = sm.get("height", [70, 150])
	for cr: Array in craters:
		var p := CPUParticles3D.new()
		p.name = "Smoke"
		p.mesh = quad
		p.material_override = mat
		p.amount = maxi(3, int(9 * particles))
		p.lifetime = 10.0
		p.preprocess = 10.0
		p.local_coords = false
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = maxf(float(cr[1]) * 0.6, 4.0)
		p.direction = Vector3.UP
		p.spread = 12.0
		p.gravity = Vector3(1.5, 0.0, 0.6)
		var rise := (float(hr[0]) + float(hr[1])) * 0.5 / 10.0
		p.initial_velocity_min = rise * 0.8
		p.initial_velocity_max = rise * 1.2
		p.scale_amount_min = float(cr[1]) * 1.6
		p.scale_amount_max = float(cr[1]) * 2.6
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0.4))
		curve.add_point(Vector2(1, 1.6))
		p.scale_amount_curve = curve
		p.color_ramp = ramp
		p.position = cr[0]
		p.visibility_range_end = 2600.0
		parent.add_child(p)


## Soft glowing mist banks low over the ground (Divine).
static func _mist(td: TrackData, biome: Dictionary, parent: Node3D, rng: RandomNumberGenerator, grid: TrackGrid, gy: float) -> void:
	var mt: Dictionary = biome.get("mist", {})
	var layers := int(mt.get("layers", 0))
	if layers <= 0 or float(mt.get("alpha", 0.0)) <= 0.0:
		return
	var tfs: Array[Transform3D] = []
	for k in layers:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, grid.radius + 300.0)
		var s := rng.randf_range(220.0, 420.0)
		var pos := grid.center + Vector3(cos(a), 0, sin(a)) * d
		pos.y = gy + rng.randf_range(12.0, 45.0)
		tfs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(s, 1.0, s * rng.randf_range(0.5, 1.0))), pos))
	var mat := Gfx.additive(Color(mt.color, float(mt.alpha)))
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = pm
	mm.instance_count = tfs.size()
	for k in tfs.size():
		mm.set_instance_transform(k, tfs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Mist"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


## Fog, sun and ambient tint for the biome's mood.
static func apply_env(env: Environment, sun: DirectionalLight3D, biome: Dictionary) -> void:
	var e: Dictionary = biome.get("env", {})
	if e.is_empty():
		return
	env.fog_light_color = e.get("fog_color", env.fog_light_color)
	env.fog_density = float(e.get("fog_density", env.fog_density))
	if sun:
		sun.light_color = sun.light_color.lerp(e.get("sun_tint", sun.light_color), float(e.get("sun_mix", 0.0)))
	env.ambient_light_color = env.ambient_light_color.lerp(e.get("ambient_tint", env.ambient_light_color), float(e.get("ambient_mix", 0.0)))


## Track points (road and shortcuts) bucketed in 50 m cells, for cheap
## "is this spot clear of the road?" checks.
class TrackGrid:
	const CELL := 50.0
	var cells := {}
	var center := Vector3.ZERO
	var radius := 0.0

	func _init(td: TrackData) -> void:
		var sum := Vector3.ZERO
		for i in range(0, td.main.n, 2):
			_add(td.main.pts[i])
			sum += td.main.pts[i]
		center = sum / maxf(float((td.main.n + 1) / 2), 1.0)
		center.y = 0.0
		for i in range(0, td.main.n, 2):
			var p := td.main.pts[i]
			radius = maxf(radius, Vector2(p.x - center.x, p.z - center.z).length())
		if td.short != null:
			for i in range(0, td.short.n, 2):
				_add(td.short.pts[i])

	func _add(p: Vector3) -> void:
		var k := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
		if not cells.has(k):
			cells[k] = PackedVector2Array()
		(cells[k] as PackedVector2Array).append(Vector2(p.x, p.z))

	func clear(p: Vector3, d: float) -> bool:
		var r := int(ceil(d / CELL))
		var k0 := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
		var q := Vector2(p.x, p.z)
		var d2 := d * d
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var arr: Variant = cells.get(k0 + Vector2i(dx, dz))
				if arr == null:
					continue
				for v: Vector2 in arr:
					if v.distance_squared_to(q) < d2:
						return false
		return true
