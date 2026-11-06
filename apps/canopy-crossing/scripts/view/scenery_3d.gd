class_name Scenery3D
extends RefCounted
## Themed first-person scenery for dense-canopy zones. Each map lists its
## scenes under "fpv_scenes" (see docs/CONTENT.md): a name, a mix of props,
## an optional landmark, fauna, particles, light and colours. Every covered
## lane is dressed from its zone's scene: plants and trees along both sides,
## a leaf ceiling overhead, hanging lianas, light shafts and mist. Props are
## built from simple shapes with vertex colours and merged into one mesh per
## lane (plus one for glows), so a dense scene stays a handful of draw calls.
## Coordinates are lane-local: x in tiles (play area 0..9), y up, z across
## the lane (-0.5..0.5).

const PROPS := ["giant_tree", "strangler_fig", "banyan", "palm", "walking_palm", "fan_palm", "ravenala",
	"tree_fern", "bamboo", "mangrove", "pneumatophores", "araucaria", "elfin_tree", "nipa",
	"liana", "bromeliad", "heliconia", "pitcher_plant", "rafflesia", "orchid", "fern",
	"moss_rock", "mushroom", "giant_lily", "karst"]
const LANDMARKS := ["", "ruin_temple", "stela", "waterfall", "canopy_walkway", "cave_arch", "clay_cliff",
	"cenote", "giant_ceiba", "karst_tower", "hanging_bridge"]
const PARTICLES := ["fireflies", "rain", "leaves", "motes", "mist", "spray"]
const FAUNA := {
	"macaw": {"kind": "bird", "colors": ["#d8242a", "#2a6ad8", "#f6c83a"], "size": 0.32},
	"scarlet_macaw": {"kind": "bird", "colors": ["#d8242a", "#f6c83a", "#2a6ad8"], "size": 0.32},
	"parrot": {"kind": "bird", "colors": ["#3aa83a", "#e8d43a", "#d83a3a"], "size": 0.24},
	"hornbill": {"kind": "bird", "colors": ["#1a1a1a", "#f2ece0", "#f6a83a"], "size": 0.4},
	"egret": {"kind": "bird", "colors": ["#f6f6f2", "#f6f6f2", "#e8c83a"], "size": 0.34},
	"bird_of_paradise": {"kind": "bird", "colors": ["#f6c83a", "#6a2a1a", "#2ad8a8"], "size": 0.28},
	"hummingbird": {"kind": "bird", "colors": ["#2ad88a", "#1a6a4a", "#d83a8a"], "size": 0.12},
	"toucan": {"kind": "bird", "colors": ["#141414", "#f6f2e0", "#f68a1a"], "size": 0.3},
	"morpho": {"kind": "butterfly", "colors": ["#2a7aff", "#1a3a8a"], "size": 0.16},
	"swallowtail": {"kind": "butterfly", "colors": ["#f6d83a", "#1a1a1a"], "size": 0.15},
	"birdwing": {"kind": "butterfly", "colors": ["#2ad88a", "#141414"], "size": 0.2},
	"glasswing": {"kind": "butterfly", "colors": ["#e8f2f6", "#5a3a2a"], "size": 0.12},
	"owl_butterfly": {"kind": "butterfly", "colors": ["#c88a4a", "#3a2a5a"], "size": 0.18},
	"bats": {"kind": "bird", "colors": ["#2a2228", "#2a2228", "#2a2228"], "size": 0.22},
}

static var _mat: StandardMaterial3D
static var _glow_mat: StandardMaterial3D
static var _grain_tex: ImageTexture
static var _water_mat: StandardMaterial3D
## Built row meshes, reused: rows of the same scene, lane type and variant
## look alike, so a new row coming into view costs nothing after the first.
static var _row_cache := {}


static func _cache_put(key: String, value: Array) -> void:
	if _row_cache.size() > 160:
		_row_cache.clear()
	_row_cache[key] = value


# ====================================================================== mesh kit

## Collects triangles with normals and vertex colours, then becomes one mesh.
class Kit:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var idx := PackedInt32Array()

	func empty() -> bool:
		return v.is_empty()

	func _add(p: Vector3, nn: Vector3, col: Color) -> int:
		v.append(p)
		n.append(nn)
		c.append(col)
		return v.size() - 1

	func quad(a: int, b: int, cc: int, d: int) -> void:
		idx.append_array(PackedInt32Array([a, b, cc, a, cc, d]))

	## Tapered tube along the transform's +Y, bottom colour to top colour.
	func cylinder(xf: Transform3D, r0: float, r1: float, h: float, col0: Color, col1: Color, seg := 8) -> void:
		var base := v.size()
		for i in seg + 1:
			var a := TAU * i / seg
			var ca := cos(a)
			var sa := sin(a)
			var nn := (xf.basis * Vector3(ca, (r0 - r1) / maxf(0.01, h), sa)).normalized()
			_add(xf * Vector3(ca * r0, 0.0, sa * r0), nn, col0)
			_add(xf * Vector3(ca * r1, h, sa * r1), nn, col1)
		for i in seg:
			var k := base + i * 2
			quad(k, k + 1, k + 3, k + 2)

	## A bent tube through a list of points (roots, vines, arching trunks).
	func tube(pts: PackedVector3Array, r0: float, r1: float, col0: Color, col1: Color, seg := 6) -> void:
		if pts.size() < 2:
			return
		var base := v.size()
		var up := Vector3.UP
		for i in pts.size():
			var k := float(i) / (pts.size() - 1)
			var d := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
			if absf(d.dot(up)) > 0.95:
				up = Vector3.RIGHT
			var s1 := d.cross(up).normalized()
			var s2 := d.cross(s1).normalized()
			var r := lerpf(r0, r1, k)
			var col := col0.lerp(col1, k)
			for j in seg + 1:
				var a := TAU * j / seg
				var off := s1 * cos(a) + s2 * sin(a)
				_add(pts[i] + off * r, off, col)
		for i in pts.size() - 1:
			for j in seg:
				var a0 := base + i * (seg + 1) + j
				var b0 := base + (i + 1) * (seg + 1) + j
				quad(a0, b0, b0 + 1, a0 + 1)

	## Ellipsoid, darker underneath (cheap ambient occlusion), optionally lumpy.
	func blob(xf: Transform3D, rad: Vector3, col: Color, seg := 8, lumps := 0.0, shade := 0.35) -> void:
		var rings := maxi(3, seg / 2)
		var base := v.size()
		for i in rings + 1:
			var th := PI * i / rings
			for j in seg + 1:
				var ph := TAU * j / seg
				var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
				var bump := 1.0
				if lumps > 0.0 and i > 0 and i < rings and j < seg:
					bump += lumps * (fposmod(sin(i * 12.9898 + j * 78.233 + rad.x * 7.0) * 43758.5453, 1.0) - 0.5)
				var p := d * rad * bump
				var col2 := col.darkened(shade * (0.5 - d.y * 0.5))
				_add(xf * p, (xf.basis * (d / rad)).normalized(), col2)
		for i in rings:
			for j in seg:
				var a := base + i * (seg + 1) + j
				var b := a + seg + 1
				quad(a, b, b + 1, a + 1)

	func box(xf: Transform3D, size: Vector3, col: Color, top := Color(0, 0, 0, 0)) -> void:
		var h := size * 0.5
		var faces := [
			[Vector3.UP, Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)],
			[Vector3.DOWN, Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z)],
			[Vector3.RIGHT, Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z)],
			[Vector3.LEFT, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z)],
			[Vector3.BACK, Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z)],
			[Vector3.FORWARD, Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z)],
		]
		for f in faces:
			var nn: Vector3 = (xf.basis * Vector3(f[0])).normalized()
			var col2 := top if (f[0] == Vector3.UP and top.a > 0.0) else col.darkened(0.12 if f[0] == Vector3.DOWN else 0.0)
			var a := _add(xf * Vector3(f[1]), nn, col2)
			var b := _add(xf * Vector3(f[2]), nn, col2)
			var cc := _add(xf * Vector3(f[3]), nn, col2)
			var d := _add(xf * Vector3(f[4]), nn, col2)
			quad(a, b, cc, d)

	## A leaf blade along local +Z, pointed at both ends, bending down.
	func blade(xf: Transform3D, length: float, width: float, col0: Color, col1: Color, bend := 0.3, segs := 3) -> void:
		var base := v.size()
		for i in segs + 1:
			var k := float(i) / segs
			var w := width * sin(PI * clampf(k * 0.92 + 0.04, 0.0, 1.0)) * 0.5
			var y := -bend * length * k * k
			var col := col0.lerp(col1, k)
			var nn := (xf.basis * Vector3(0, 1, 2.0 * bend * k)).normalized()
			_add(xf * Vector3(-w, y, k * length), nn, col)
			_add(xf * Vector3(w, y + w * 0.25, k * length), nn, col.lightened(0.06))
		for i in segs:
			var a := base + i * 2
			quad(a, a + 2, a + 3, a + 1)

	## Flat disc (lily pad, fan palm leaf); pleats fold it, rim turns the edge up.
	func disc(xf: Transform3D, r: float, col: Color, seg := 14, pleats := 0.0, rim := 0.0) -> void:
		var center := _add(xf * Vector3.ZERO, (xf.basis * Vector3.UP).normalized(), col.lightened(0.08))
		var first := v.size()
		for i in seg + 1:
			var a := TAU * i / seg
			var y := (pleats if i % 2 == 0 else -pleats) * r
			_add(xf * Vector3(cos(a) * r, y, sin(a) * r), (xf.basis * Vector3.UP).normalized(), col)
		for i in seg:
			idx.append_array(PackedInt32Array([center, first + i, first + i + 1]))
		if rim > 0.0:
			var rb := v.size()
			for i in seg + 1:
				var a2 := TAU * i / seg
				var dir := Vector3(cos(a2), 0, sin(a2))
				_add(xf * (dir * r), (xf.basis * dir).normalized(), col.darkened(0.25))
				_add(xf * (dir * r * 1.03 + Vector3(0, rim, 0)), (xf.basis * dir).normalized(), col.darkened(0.4))
			for i in seg:
				var k := rb + i * 2
				quad(k, k + 1, k + 3, k + 2)

	## A soft beam of light: two crossed planes, clear at both ends and
	## brightest in the middle, so it never shows hard edges.
	func beam(xf: Transform3D, w: float, h: float, col: Color) -> void:
		for rot in [0.0, PI * 0.5]:
			var b := Basis(Vector3.UP, rot)
			var base := v.size()
			for i in 5:
				var k := i / 4.0
				var a := col.a * sin(PI * k)
				var y := -h * 0.5 + h * k
				var nn := (xf.basis * (b * Vector3.BACK)).normalized()
				_add(xf * (b * Vector3(-w * 0.5, y, 0)), nn, Color(col, 0.0))
				_add(xf * (b * Vector3(0.0, y, 0)), nn, Color(col, a))
				_add(xf * (b * Vector3(w * 0.5, y, 0)), nn, Color(col, 0.0))
			for i in 4:
				var r0 := base + i * 3
				var r1 := r0 + 3
				quad(r0, r1, r1 + 1, r0 + 1)
				quad(r0 + 1, r1 + 1, r1 + 2, r0 + 2)

	func mesh() -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_INDEX] = idx
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return m


static func xf(pos: Vector3, yaw := 0.0, pitch := 0.0, roll := 0.0, s := 1.0) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(pitch, yaw, roll)).scaled(Vector3.ONE * s), pos)


# ====================================================================== materials

static func grain() -> ImageTexture:
	if _grain_tex:
		return _grain_tex
	var nz := FastNoiseLite.new()
	nz.seed = 11
	nz.frequency = 0.08
	nz.fractal_octaves = 3
	var src := nz.get_seamless_image(128, 128)
	var img := Image.create(128, 128, true, Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var g := 0.72 + src.get_pixel(x, y).r * 0.28
			img.set_pixel(x, y, Color(g, g, g))
	img.generate_mipmaps()
	_grain_tex = ImageTexture.create_from_image(img)
	return _grain_tex


static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.vertex_color_use_as_albedo = true
		_mat.vertex_color_is_srgb = true
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat.roughness = 0.82
		_mat.albedo_color = Color(1.12, 1.12, 1.12)
		if Draw.detail > 0:
			_mat.albedo_texture = grain()
			_mat.uv1_triplanar = true
			_mat.uv1_world_triplanar = true
			_mat.uv1_scale = Vector3.ONE * 1.3
			_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return _mat


static func glow_material() -> StandardMaterial3D:
	if _glow_mat == null:
		_glow_mat = StandardMaterial3D.new()
		_glow_mat.vertex_color_use_as_albedo = true
		_glow_mat.vertex_color_is_srgb = true
		_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_glow_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_glow_mat.disable_fog = true
	return _glow_mat


## The waterfall's moving sheet of water (its own node so it can scroll).
static func _falls_sheet(spec: Dictionary) -> MeshInstance3D:
	var sheet := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.1, 3.8)
	sheet.mesh = qm
	sheet.material_override = falling_water_material()
	sheet.position = spec.pos
	sheet.rotation.y = spec.rot
	sheet.set_meta("falls", true)
	return sheet


static func falling_water_material() -> StandardMaterial3D:
	if _water_mat == null:
		_water_mat = StandardMaterial3D.new()
		_water_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.82)
		_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_water_mat.roughness = 0.1
		_water_mat.metallic_specular = 0.9
		_water_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_water_mat.albedo_texture = grain()
		_water_mat.uv1_scale = Vector3(1.0, 3.0, 1.0)
	return _water_mat


# ====================================================================== scenes

## The scene a lane belongs to, from its map's "fpv_scenes" (or {}).
static func scene_def(map: Dictionary, id: String) -> Dictionary:
	var list: Array = map.get("fpv_scenes", [])
	for sc in list:
		if String(sc.get("id", "")) == id:
			return sc
	return list[0] if not list.is_empty() and id != "" else {}


static func col(sc: Dictionary, pal: Dictionary, key: String, fallback: String) -> Color:
	var cols: Dictionary = sc.get("colors", {})
	if cols.has(key):
		return Color(String(cols[key]))
	return Color(String(pal.get(key, fallback)))


## Builds the scenery for one covered lane: a Node3D with one merged opaque
## mesh, one merged glow mesh, and any animated fauna / particles (listed in
## its "anim" meta for animate()).
static func build_lane(lane: Lane, sc: Dictionary, pal: Dictionary, detail: int, zone_rows: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.name = "Scenery"
	var mid := (zone_rows.x + zone_rows.y) / 2
	var key := _row_key(lane, sc, pal, detail, mid)
	var meshes: Array = _row_cache.get(key, [])
	if meshes.is_empty():
		meshes = _row_meshes(lane, sc, pal, detail, mid)
		_cache_put(key, meshes)
	if meshes[0] != null:
		var mi := MeshInstance3D.new()
		mi.mesh = meshes[0]
		mi.material_override = material()
		root.add_child(mi)
	if meshes[1] != null:
		var gi := MeshInstance3D.new()
		gi.mesh = meshes[1]
		gi.material_override = glow_material()
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(gi)
	for spec in meshes[2]:
		if spec.get("falls", false):
			root.add_child(_falls_sheet(spec))
	# fauna and particles live on the zone's first and middle rows
	var anim: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = lane.row * 131 + 7
	var parts: Array = sc.get("particles", [])
	if detail > 0 and (lane.row == zone_rows.x or lane.row == mid):
		var fauna: Array = sc.get("fauna", [])
		if not fauna.is_empty():
			var fid := String(fauna[(lane.row / 2) % fauna.size()])
			if FAUNA.has(fid):
				anim.append(_fauna_node(root, fid, rng))
		for p in parts:
			if String(p) in ["fireflies", "rain", "leaves", "motes", "spray"]:
				anim.append(_particle_node(root, String(p), rng, col(sc, pal, "light", "#fff2b0")))
	root.set_meta("anim", anim)
	return root


## Builds (and caches) one row's meshes ahead of time, without making nodes.
## True if it did any work, so callers can do one per frame.
static func warm_row(lane: Lane, sc: Dictionary, pal: Dictionary, detail: int, zone_rows: Vector2i) -> bool:
	if lane.covered:
		var mid := (zone_rows.x + zone_rows.y) / 2
		var key := _row_key(lane, sc, pal, detail, mid)
		if _row_cache.has(key):
			return false
		_cache_put(key, _row_meshes(lane, sc, pal, detail, mid))
		return true
	if lane.type == "safe" and not lane.goal:
		var variant := lane.row % 6
		var key2 := "open|%s|%s|%s|%d|%d|%s" % [String(pal.get("safe", "")), String(pal.get("canopy", "")), lane.type, detail, variant, str(lane.tiles.keys())]
		if _row_cache.has(key2):
			return false
		_cache_put(key2, [_open_mesh(lane, pal, detail, variant)])
		return true
	return false


## Cache key for a canopy row's meshes. Rows share one of four looks per
## scene; the zone's middle row (with its landmark) is keyed by itself.
static func _row_key(lane: Lane, sc: Dictionary, pal: Dictionary, detail: int, mid: int) -> String:
	var variant := ("lm%d" % lane.row) if lane.row == mid else str(lane.row % 4)
	return "%s|%s|%s|%d|%s|%s" % [String(sc.get("id", "")), String(pal.get("canopy", "")), lane.type, detail, variant, str(lane.tiles.keys())]


## The static part of a canopy row: [opaque mesh or null, glow mesh or null,
## specs for the few parts that need their own node (a waterfall's sheet)].
static func _row_meshes(lane: Lane, sc: Dictionary, pal: Dictionary, detail: int, mid: int) -> Array:
	var landmark := lane.row == mid
	var k := Kit.new()
	var g := Kit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = (lane.row if landmark else lane.row % 4) * 7349 + 17
	var seg := 6 if detail <= 0 else (8 if detail == 1 else 11)
	var leaf := col(sc, pal, "leaf", String(pal.get("canopy", "#2a7a3a"))).lightened(0.05)
	var dark := col(sc, pal, "canopy_dark", "#0b3a1a")
	var bark := col(sc, pal, "bark", "#5a4230")
	var flower := col(sc, pal, "flower", String(pal.get("accent", "#e8443a")))
	var ctx := {"k": k, "g": g, "rng": rng, "seg": seg, "leaf": leaf, "dark": dark, "bark": bark, "flower": flower,
		"detail": detail, "lane": lane, "sc": sc, "nodes": []}
	_ceiling(ctx)
	_overhead(ctx, overhead_style(sc))
	# side dressing, weighted by the scene's prop mix and what suits the lane
	var props: Dictionary = sc.get("props", {"fern": 1.0, "giant_tree": 0.4, "liana": 0.6})
	for side in [-1.0, 1.0]:
		var budget := 2 if lane.type == "safe" else 1
		for i in budget:
			var kind := _pick(props, rng, lane.type, i > 0)
			if kind == "":
				continue
			var x := -0.95 - rng.randf_range(0.0, 0.35) if side < 0.0 else 9.95 + rng.randf_range(0.0, 0.35)
			_prop(ctx, kind, Vector3(x, 0.0, rng.randf_range(-0.3, 0.3)), side)
		# a low fringe so the side never reads as a bare wall
		for j in (3 if detail > 0 else 1):
			var fx := (-1.3 if side < 0.0 else 10.3) + rng.randf_range(-0.15, 0.15)
			_fern(ctx, Vector3(fx, 0.0, -0.4 + j * 0.4), rng.randf_range(0.5, 0.8))
	# leaf litter on the forest floor: flat, so it never hides a hazard
	if detail > 0 and lane.type != "water":
		var litter := [leaf.darkened(0.35), Color("7a5a2a"), Color("8a6a32"), leaf.darkened(0.15).lerp(Color("6a5a2a"), 0.5)]
		for i in (14 if detail > 1 else 7):
			var lp := Vector3(rng.randf_range(-0.4, 9.4), 0.006 + i * 0.0004, rng.randf_range(-0.47, 0.47))
			k.blade(xf(lp, rng.randf() * TAU), rng.randf_range(0.12, 0.22), rng.randf_range(0.06, 0.1), litter[i % 4], Color(litter[(i + 1) % 4]).darkened(0.1), 0.0, 1)
		# small plants tucked along the lane's edges
		for i in 2:
			var ex := rng.randf_range(0.2, 8.8)
			var ez := -0.47 if i == 0 else 0.47
			if lane.type == "safe" and lane.tiles.is_empty():
				_fern(ctx, Vector3(ex, 0.0, ez), 0.28)
	# fronds and branches arching in over the edges of the path
	if detail > 0:
		for side2 in [-1.0, 1.0]:
			var sx2 := -1.0 if side2 < 0.0 else 10.0
			var z2 := rng.randf_range(-0.3, 0.3)
			_frond(ctx, Vector3(sx2, 2.35, z2), Vector3(-side2, 0.15, rng.randf_range(-0.3, 0.3)), rng.randf_range(1.5, 2.1), leaf.lightened(0.04))
			if rng.randf() < 0.5:
				_frond(ctx, Vector3(sx2, 1.9, -z2), Vector3(-side2, 0.25, rng.randf_range(-0.3, 0.3)), rng.randf_range(1.1, 1.5), leaf.darkened(0.08))
	# lianas hanging over the play area (high enough to see under)
	var lianas := float(props.get("liana", 0.4))
	if rng.randf() < lianas:
		_liana(ctx, Vector3(rng.randf_range(0.5, 8.5), 2.55, rng.randf_range(-0.3, 0.3)), rng.randf_range(0.55, 1.0))
	# light shafts and mist
	var shafts := float(sc.get("shafts", 0.4))
	if detail > 0 and rng.randf() < shafts:
		var lc := col(sc, pal, "light", "#fff2b0")
		var sx := rng.randf_range(0.0, 9.0)
		# beams come down from the leaves and fade out above eye height, so
		# they light the scene without ever covering the path ahead
		var beam := xf(Vector3(sx, 2.15, 0.0), rng.randf_range(-0.3, 0.3), 0.0, -0.3)
		g.beam(beam, rng.randf_range(0.5, 0.9), 1.5, Color(lc, 0.2))
		g.beam(beam, 0.25, 1.5, Color(lc, 0.14))
	# the zone's landmark sits on its middle row
	if landmark:
		_landmark(ctx, String(sc.get("landmark", "")))
	return [k.mesh() if not k.empty() else null, g.mesh() if not g.empty() else null, ctx.nodes]


## An open (not covered) row: grass tufts and flowers on grassy rows, kept
## off tiles that hold something, and a tree on each side every third row.
## One merged mesh, or null when there is nothing to draw.
static func open_lane(lane: Lane, pal: Dictionary, detail: int) -> MeshInstance3D:
	var variant := lane.row % 6         # covers both the trees (every 3rd row) and the two grass colours
	var key := "open|%s|%s|%s|%d|%d|%s" % [String(pal.get("safe", "")), String(pal.get("canopy", "")), lane.type, detail, variant, str(lane.tiles.keys())]
	var entry: Array = _row_cache.get(key, [])
	if entry.is_empty():
		entry = [_open_mesh(lane, pal, detail, variant)]
		_cache_put(key, entry)
	var mesh: Mesh = entry[0]
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = "Open"
	mi.mesh = mesh
	mi.material_override = material()
	return mi


static func _open_mesh(lane: Lane, pal: Dictionary, detail: int, variant: int) -> Mesh:
	var k := Kit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 977 + 5
	var g := Color(String(pal.get("safe_alt" if lane.row % 2 == 0 else "safe", "#3c9a3a")))
	var accent := Color(String(pal.get("accent", "#f6d43a")))
	var leaf := Color(String(pal.get("canopy", "#1e5a2a")))
	var seg := 6 if detail <= 0 else (8 if detail == 1 else 10)
	if lane.row % 3 == 0:
		for side in [-1.0, 1.0]:
			var p := Vector3(-1.2 if side < 0.0 else 10.2, 0.0, rng.randf_range(-0.2, 0.2))
			k.cylinder(xf(p), 0.2, 0.14, 2.7, Color("4a3422"), Color("5a3e26"), seg)
			for j in 4:
				var c := leaf.lightened(0.05 * j).darkened(rng.randf_range(0.0, 0.15))
				k.blob(xf(p + Vector3(rng.randf_range(-0.35, 0.35), 2.45 + j * 0.25, rng.randf_range(-0.25, 0.25))), Vector3(0.75 - j * 0.1, 0.42, 0.62 - j * 0.08), c, seg, 0.3)
	var n := 0 if lane.type != "safe" or detail <= 0 else (16 if detail > 1 else 8)
	for i in n:
		var x := rng.randf_range(-1.2, 10.2)
		if lane.tiles.has(int(floorf(x))):
			continue
		var p := Vector3(x, 0.0, rng.randf_range(-0.45, 0.45))
		for b in 5:
			var a := TAU * b / 5.0 + rng.randf() * 0.5
			k.blade(xf(p, a, -1.2 + rng.randf_range(-0.2, 0.2)), rng.randf_range(0.12, 0.2), 0.035, g.darkened(0.25), g.lightened(0.18), -0.3, 2)
		if rng.randf() < 0.25:
			var fp := p + Vector3(0.06, 0.12, 0.0)
			k.cylinder(xf(p + Vector3(0.06, 0, 0)), 0.006, 0.006, 0.12, g.darkened(0.2), g, 3)
			for j in 5:
				var a2 := TAU * j / 5.0
				k.blob(xf(fp + Vector3(cos(a2) * 0.025, 0, sin(a2) * 0.025)), Vector3(0.022, 0.008, 0.022), accent.lerp(Color.WHITE, 0.3 * (i % 2)), 4)
	return k.mesh() if not k.empty() else null


static func _pick(props: Dictionary, rng: RandomNumberGenerator, lane_type: String, second: bool) -> String:
	var ok := {}
	for kind in props:
		var w := float(props[kind])
		if kind == "liana" or w <= 0.0:
			continue
		var big: bool = kind in ["giant_tree", "strangler_fig", "banyan", "araucaria", "karst", "mangrove", "walking_palm", "palm", "ravenala", "fan_palm", "bamboo", "tree_fern", "elfin_tree"]
		if lane_type == "water":
			if not kind in ["giant_lily", "mangrove", "pneumatophores", "nipa", "walking_palm", "fern"]:
				continue
		elif lane_type == "ground":
			if big:
				w *= 0.35
		if second and big:
			w *= 0.3
		ok[kind] = w
	var total := 0.0
	for kk in ok:
		total += float(ok[kk])
	if total <= 0.0:
		return "fern" if lane_type != "water" else ""
	var r := rng.randf() * total
	for kk in ok:
		r -= float(ok[kk])
		if r <= 0.0:
			return String(kk)
	return String(ok.keys()[0])


# ====================================================================== the canopy overhead

static func _ceiling(ctx: Dictionary) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var leaf: Color = ctx.leaf
	var dark: Color = ctx.dark
	var seg: int = ctx.seg
	k.box(xf(Vector3(4.5, 3.25, 0.0)), Vector3(16.0, 0.4, 1.04), dark.darkened(0.3))
	var n := 7 if int(ctx.detail) > 0 else 4
	for i in n:
		var x := -1.5 + (i + rng.randf_range(0.1, 0.9)) * 12.0 / n
		var c := leaf.darkened(rng.randf_range(0.05, 0.4)).lerp(dark, rng.randf_range(0.0, 0.3))
		k.blob(xf(Vector3(x, rng.randf_range(2.6, 2.95), rng.randf_range(-0.25, 0.25))), Vector3(rng.randf_range(0.9, 1.4), rng.randf_range(0.28, 0.42), 0.62), c, seg, 0.35, 0.5)
	# hanging leaf tips under the ceiling
	if int(ctx.detail) > 0:
		for i in 5:
			var p := Vector3(rng.randf_range(-1.0, 10.0), 2.55, rng.randf_range(-0.4, 0.4))
			k.blade(xf(p, rng.randf() * TAU, -1.2), 0.45, 0.16, leaf.darkened(0.2), leaf.lightened(0.1), 0.4, 2)


## What hangs over the path in this scene. A scene may name it ("overhead");
## otherwise it follows the scene's main plants.
static func overhead_style(sc: Dictionary) -> String:
	if sc.has("overhead"):
		return String(sc.overhead)
	var props: Dictionary = sc.get("props", {})
	var best := ""
	var bw := 0.0
	for kind in props:
		if kind == "liana":
			continue
		if float(props[kind]) > bw:
			bw = float(props[kind])
			best = String(kind)
	if String(sc.get("landmark", "")) == "cave_arch":
		return "rock"
	match best:
		"bamboo":
			return "bamboo_arch"
		"strangler_fig", "banyan":
			return "aerial_roots"
		"mangrove", "pneumatophores", "nipa":
			return "mangrove"
		"palm", "fan_palm", "ravenala", "walking_palm":
			return "palm_fronds"
		"tree_fern", "fern":
			return "fronds"
		"elfin_tree", "moss_rock", "orchid":
			return "moss_branches"
		"karst":
			return "rock"
	return "branches"


## Overhead dressing that spans the path, kept above about 1.6 so the way
## ahead stays clear. This is what you see up close in first person.
static func _overhead(ctx: Dictionary, style: String) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var leaf: Color = ctx.leaf
	var bark: Color = ctx.bark
	var detail := int(ctx.detail)
	var z := rng.randf_range(-0.3, 0.3)
	match style:
		"bamboo_arch":
			for zz in [z - 0.18, z + 0.18]:
				for side in [-1.0, 1.0]:
					var x0 := -0.7 if side < 0.0 else 9.7
					var pts := PackedVector3Array()
					for i in 9:
						var t := i / 8.0
						pts.append(Vector3(lerpf(x0, 4.5 + side * 0.4, t), sin(t * PI * 0.5) * 2.55, zz + side * 0.04))
					var c := Color("7aa83a").darkened(rng.randf_range(0.0, 0.25))
					k.tube(pts, 0.05, 0.035, c.darkened(0.15), c, 6)
					if detail > 0:
						for j in range(1, 8, 2):
							k.cylinder(xf(pts[j], 0.0, 0.0, (pts[j + 1] - pts[j]).angle_to(Vector3.UP) * -side), 0.056, 0.055, 0.03, c.darkened(0.35), c.darkened(0.35), 6)
						for j in range(4, 9):
							for s in 2:
								k.blade(xf(pts[j] + Vector3(0, -0.05, 0), rng.randf() * TAU, 0.9), 0.3, 0.06, leaf.lightened(0.15), leaf.lightened(0.25), 0.45, 2)
		"aerial_roots":
			var pts2 := PackedVector3Array()
			for i in 7:
				var t2 := i / 6.0
				pts2.append(Vector3(lerpf(-1.0, 10.0, t2), 2.55 + sin(t2 * PI) * 0.12, z + sin(t2 * 5.0) * 0.12))
			k.tube(pts2, 0.13, 0.1, bark.lightened(0.1), bark.lightened(0.18), 7)
			for i in (9 if detail > 0 else 5):
				var rx := rng.randf_range(-0.6, 9.6)
				var top := Vector3(rx, 2.5, z + rng.randf_range(-0.1, 0.1))
				var reach := 0.6 if rx > 0.4 and rx < 8.6 else 2.5
				var len := rng.randf_range(0.4, reach)
				k.tube(PackedVector3Array([top, top + Vector3(rng.randf_range(-0.05, 0.05), -len * 0.5, 0.02), top + Vector3(0, -len, 0)]), 0.025, 0.012, bark.lightened(0.15), bark.lightened(0.3), 4)
		"branches", "moss_branches":
			var a := Vector3(-1.0, rng.randf_range(2.2, 2.5), z - 0.3)
			var b := Vector3(10.0, rng.randf_range(2.3, 2.6), z + 0.3)
			var mid := (a + b) * 0.5 + Vector3(0, 0.15, 0)
			k.tube(PackedVector3Array([a, (a + mid) * 0.5 + Vector3(0, 0.08, 0), mid, (mid + b) * 0.5 + Vector3(0, 0.05, 0), b]), 0.12, 0.08, bark, bark.lightened(0.08), 7)
			var moss := Color("6a9a3a")
			for i in 5:
				var t3 := (i + 0.5) / 5.0
				var p := a.lerp(b, t3) + Vector3(0, 0.12 + sin(t3 * PI) * 0.15, 0)
				k.blob(xf(p), Vector3(0.18, 0.08, 0.14), moss.darkened(rng.randf_range(0.0, 0.25)), 6, 0.4)
				if style == "moss_branches" and detail > 0:
					for j in 3:
						var hp := p + Vector3(rng.randf_range(-0.12, 0.12), -0.05, rng.randf_range(-0.08, 0.08))
						k.tube(PackedVector3Array([hp, hp + Vector3(0.01, -0.22, 0), hp + Vector3(-0.01, -0.45, 0.01)]), 0.018, 0.006, Color("9ab86a"), Color("b8c88a"), 3)
			var epi := rng.randi_range(0, 2)
			var ep := a.lerp(b, rng.randf_range(0.2, 0.8)) + Vector3(0, 0.25, 0)
			if epi == 0:
				_bromeliad(ctx, ep, 0.8)
			elif epi == 1:
				_orchids(ctx, ep)
			else:
				_fern(ctx, ep, 0.45)
		"fronds", "palm_fronds":
			for side2 in [-1.0, 1.0]:
				var root := Vector3(-0.9 if side2 < 0.0 else 9.9, rng.randf_range(2.1, 2.5), z + rng.randf_range(-0.2, 0.2))
				for f in (2 if detail > 0 else 1):
					var len2 := rng.randf_range(2.6, 3.6) if style == "palm_fronds" else rng.randf_range(2.2, 3.0)
					_frond(ctx, root, Vector3(-side2, 0.35, rng.randf_range(-0.25, 0.25)), len2, leaf.lightened(0.05 * f))
		"mangrove":
			for i in (10 if detail > 0 else 5):
				var mx := rng.randf_range(-0.8, 9.8)
				var top2 := Vector3(mx, 2.45, rng.randf_range(-0.45, 0.45))
				var len3 := rng.randf_range(0.3, 0.7) if mx > 0.4 and mx < 8.6 else 2.4
				k.tube(PackedVector3Array([top2, top2 + Vector3(0.05, -len3 * 0.5, 0), top2 + Vector3(0.0, -len3, 0.05)]), 0.03, 0.02, Color("5a4a3a"), Color("6a5a42"), 4)
			for i in 3:
				k.blob(xf(Vector3(rng.randf_range(0.0, 9.0), 2.4, rng.randf_range(-0.3, 0.3))), Vector3(0.9, 0.25, 0.5), leaf.darkened(rng.randf_range(0.1, 0.3)), int(ctx.seg), 0.35)
		"rock":
			var stone := Color("8a8478")
			k.box(xf(Vector3(4.5, 2.95, 0.0)), Vector3(16.0, 0.7, 1.04), stone.darkened(0.35))
			for i in 5:
				k.blob(xf(Vector3(rng.randf_range(-1.0, 10.0), 2.55, rng.randf_range(-0.3, 0.3)), rng.randf() * TAU), Vector3(rng.randf_range(0.8, 1.4), 0.3, 0.6), stone.darkened(rng.randf_range(0.0, 0.3)), int(ctx.seg), 0.35, 0.3)
			for i in (6 if detail > 0 else 3):
				k.cylinder(xf(Vector3(rng.randf_range(0.0, 9.0), 2.45, rng.randf_range(-0.4, 0.4)), 0.0, 0.0, PI), rng.randf_range(0.05, 0.1), 0.0, rng.randf_range(0.25, 0.6), stone.darkened(0.1), stone.lightened(0.15), 6)


# ====================================================================== props

static func _prop(ctx: Dictionary, kind: String, p: Vector3, side: float) -> void:
	match kind:
		"giant_tree":
			_giant_tree(ctx, p, side, 1.0)
		"strangler_fig":
			_strangler(ctx, p)
		"banyan":
			_banyan(ctx, p, side)
		"palm":
			_palm(ctx, p, side, false)
		"walking_palm":
			_palm(ctx, p, side, true)
		"fan_palm":
			_fan_palm(ctx, p)
		"ravenala":
			_ravenala(ctx, p)
		"tree_fern":
			_tree_fern(ctx, p)
		"bamboo":
			_bamboo(ctx, p)
		"mangrove":
			_mangrove(ctx, p)
		"pneumatophores":
			_pneumatophores(ctx, p)
		"araucaria":
			_araucaria(ctx, p)
		"elfin_tree":
			_elfin(ctx, p, side)
		"nipa":
			_nipa(ctx, p)
		"bromeliad":
			_bromeliad(ctx, p + Vector3(0, 0, 0), 1.0)
		"heliconia":
			_heliconia(ctx, p)
		"pitcher_plant":
			_pitchers(ctx, p)
		"rafflesia":
			_rafflesia(ctx, p)
		"orchid":
			_orchids(ctx, p)
		"fern":
			_fern(ctx, p, 1.0)
		"moss_rock":
			_moss_rock(ctx, p)
		"mushroom":
			_mushrooms(ctx, p)
		"giant_lily":
			_giant_lily(ctx, p)
		"karst":
			_karst(ctx, p, side, 1.0)


static func _giant_tree(ctx: Dictionary, p: Vector3, side: float, s: float) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var bark: Color = ctx.bark
	var seg: int = ctx.seg
	var r := 0.34 * s
	k.cylinder(xf(p), r * 1.25, r * 0.8, 3.6, bark.darkened(0.35), bark.lightened(0.05), seg + 2)
	# buttress fins
	var fins := 5 if int(ctx.detail) > 0 else 3
	for i in fins:
		var a := TAU * i / fins + rng.randf() * 0.4
		var d := Vector3(cos(a), 0, sin(a))
		var pts := PackedVector3Array([p + d * r * 0.6 + Vector3(0, 1.1 * s, 0), p + d * r * 1.5 + Vector3(0, 0.45 * s, 0), p + d * r * 2.4 + Vector3(0, 0.02, 0)])
		k.tube(pts, 0.07 * s, 0.11 * s, bark.lightened(0.04), bark.darkened(0.3), 4)
	# bark ridges and moss
	if int(ctx.detail) > 1:
		for i in 4:
			var a2 := TAU * i / 4.0 + 0.4
			k.cylinder(xf(p + Vector3(cos(a2), 0, sin(a2)) * r * 0.95), 0.035, 0.025, 2.6, bark.darkened(0.45), bark.darkened(0.2), 4)
	for i in 3:
		var a3 := rng.randf() * TAU
		k.blob(xf(p + Vector3(cos(a3) * r, rng.randf_range(0.6, 2.4), sin(a3) * r)), Vector3(0.16, 0.1, 0.16), Color(ctx.leaf).darkened(0.25), 6, 0.3)
	# an epiphyte on a branch
	var bp := p + Vector3(-side * 0.25, 2.1, 0.0)
	k.tube(PackedVector3Array([p + Vector3(0, 1.9, 0), bp + Vector3(-side * 0.5, 0.25, 0)]), 0.08, 0.05, bark, bark.darkened(0.1), 5)
	_bromeliad(ctx, bp + Vector3(-side * 0.5, 0.3, 0), 0.7)


static func _strangler(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var bark: Color = Color(ctx.bark).lightened(0.12)
	for i in 7:
		var a0 := TAU * i / 7.0
		var pts := PackedVector3Array()
		for j in 7:
			var y := j * 0.55
			var a := a0 + j * 0.5 * (1.0 if i % 2 == 0 else -1.0)
			pts.append(p + Vector3(cos(a) * 0.3, y, sin(a) * 0.3))
		k.tube(pts, 0.07, 0.045, bark.darkened(0.2), bark, 5)
	# the old host tree's dark heart showing through the lattice
	k.cylinder(xf(p), 0.18, 0.15, 3.2, Color("1a1410"), Color("2a2018"), 6)
	for i in 3:
		var a2 := rng.randf() * TAU
		k.tube(PackedVector3Array([p + Vector3(cos(a2) * 0.3, 0.4, sin(a2) * 0.3), p + Vector3(cos(a2) * 0.7, 0.0, sin(a2) * 0.7)]), 0.06, 0.04, bark, bark.darkened(0.2), 4)


static func _banyan(ctx: Dictionary, p: Vector3, side: float) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var bark: Color = Color(ctx.bark).lightened(0.15)
	k.cylinder(xf(p), 0.42, 0.32, 3.4, bark.darkened(0.3), bark, int(ctx.seg) + 2)
	var arm := p + Vector3(-side * 1.6, 2.45, 0.0)
	k.tube(PackedVector3Array([p + Vector3(0, 2.2, 0), p + Vector3(-side * 0.8, 2.5, 0), arm]), 0.16, 0.09, bark, bark.lightened(0.05), 6)
	# a curtain of aerial roots
	for i in 9:
		var x := lerpf(p.x, arm.x, (i + 0.5) / 9.0)
		var len := rng.randf_range(1.6, 2.5)
		var top := Vector3(x, 2.45 - absf(x - p.x) * 0.05, p.z + rng.randf_range(-0.2, 0.2))
		k.tube(PackedVector3Array([top, top + Vector3(rng.randf_range(-0.05, 0.05), -len * 0.5, 0), top + Vector3(0, -len, 0)]), 0.03, 0.02, bark.darkened(0.1), bark.darkened(0.25), 4)


static func _palm(ctx: Dictionary, p: Vector3, side: float, stilts: bool) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var trunk := Color("8a7a5a")
	var lean := -side * rng.randf_range(0.15, 0.4)
	var h := rng.randf_range(2.2, 2.9)
	var pts := PackedVector3Array()
	var base := p + (Vector3(0, 0.7, 0) if stilts else Vector3.ZERO)
	for i in 6:
		var t := i / 5.0
		pts.append(base + Vector3(lean * t * t, t * h, 0))
	k.tube(pts, 0.1, 0.075, trunk.darkened(0.2), trunk, 6)
	if int(ctx.detail) > 0:
		for i in 5:
			var t2 := (i + 0.5) / 6.0
			k.cylinder(xf(base + Vector3(lean * t2 * t2, t2 * h, 0)), 0.11, 0.105, 0.04, trunk.darkened(0.35), trunk.darkened(0.35), 6)
	if stilts:
		for i in 6:
			var a := TAU * i / 6.0
			k.tube(PackedVector3Array([base + Vector3(0, 0.15, 0), p + Vector3(cos(a) * 0.45, 0.0, sin(a) * 0.35)]), 0.04, 0.035, trunk.darkened(0.1), trunk.darkened(0.3), 4)
	var top := pts[pts.size() - 1]
	var fronds := 9 if int(ctx.detail) > 0 else 6
	for i in fronds:
		var a2 := TAU * i / fronds + rng.randf() * 0.3
		_frond(ctx, top, Vector3(cos(a2), 0.3, sin(a2)), rng.randf_range(1.0, 1.4), Color(ctx.leaf).lightened(0.05))


## A palm/fern frond: an arching spine with leaflets either side.
static func _frond(ctx: Dictionary, base: Vector3, dir: Vector3, length: float, c: Color) -> void:
	var k: Kit = ctx.k
	var n := 6 if int(ctx.detail) > 1 else 4
	var d := Vector3(dir.x, 0, dir.z).normalized()
	var yaw := atan2(d.x, d.z)
	var prev := base
	for i in n:
		var t := (i + 1.0) / n
		var pt := base + d * length * t + Vector3(0, dir.y * length * t - 0.55 * length * t * t, 0)
		var mid := (prev + pt) * 0.5
		var shade := c.darkened(0.15 * (1.0 - t))
		for s in [-1.0, 1.0]:
			k.blade(xf(mid, yaw + s * 1.1, 0.25 + t * 0.4), 0.38 * length * (1.0 - t * 0.5), 0.09, shade, c.lightened(0.08), 0.25, 2)
		prev = pt
	k.tube(PackedVector3Array([base, base + d * length * 0.5 + Vector3(0, dir.y * length * 0.5 - 0.14 * length, 0), prev]), 0.02, 0.01, c.darkened(0.3), c.darkened(0.2), 3)


static func _fan_palm(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	k.cylinder(xf(p), 0.06, 0.05, 2.0, Color("5a4a32"), Color("6a5a3a"), 5)
	for i in 7:
		var a := TAU * i / 7.0 + rng.randf() * 0.4
		var stem_top := p + Vector3(cos(a) * 0.55, 1.6 + rng.randf_range(0.0, 0.7), sin(a) * 0.4)
		k.tube(PackedVector3Array([p + Vector3(0, 1.4, 0), stem_top]), 0.015, 0.012, Color("5a6a3a"), Color("5a6a3a"), 3)
		k.disc(xf(stem_top, a, -0.9 + rng.randf_range(-0.2, 0.2)), rng.randf_range(0.4, 0.55), Color(ctx.leaf).lightened(0.08), 16, 0.12)


static func _ravenala(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	k.cylinder(xf(p), 0.16, 0.13, 1.5, Color("6a6a5a"), Color("7a7a6a"), 7)
	for i in 11:
		var a := lerpf(-1.2, 1.2, i / 10.0)
		var top := p + Vector3(0, 1.5, 0) + Vector3(0, cos(a) * 1.1, 0) + Vector3(0, 0, sin(a) * 1.1)
		k.tube(PackedVector3Array([p + Vector3(0, 1.5, 0), top]), 0.03, 0.02, Color("6a7a4a"), Color("6a8a4a"), 3)
		k.blade(xf(top, 0.0, -a - PI * 0.5), 0.9, 0.3, Color(ctx.leaf), Color(ctx.leaf).lightened(0.1), 0.05, 3)


static func _tree_fern(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var h := rng.randf_range(1.4, 2.1)
	k.cylinder(xf(p), 0.13, 0.11, h, Color("3a2a1e"), Color("4a3a24"), 7)
	var top := p + Vector3(0, h, 0)
	for i in 10:
		var a := TAU * i / 10.0 + rng.randf() * 0.2
		_frond(ctx, top, Vector3(cos(a), 0.55, sin(a)), rng.randf_range(0.9, 1.2), Color(ctx.leaf).lightened(0.12))
	# fiddleheads
	if int(ctx.detail) > 1:
		for i in 3:
			var a2 := rng.randf() * TAU
			k.blob(xf(top + Vector3(cos(a2) * 0.08, 0.12, sin(a2) * 0.08)), Vector3(0.04, 0.05, 0.04), Color("8a7a3a"), 5)


static func _bamboo(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var green := Color("7aa83a")
	for i in 7:
		var q := p + Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))
		var h := rng.randf_range(2.6, 3.4)
		var lean := Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.1, 0.1))
		var c := green.darkened(rng.randf_range(0.0, 0.3))
		k.tube(PackedVector3Array([q, q + lean * 0.3 + Vector3(0, h * 0.5, 0), q + lean + Vector3(0, h, 0)]), 0.045, 0.035, c.darkened(0.15), c, 6)
		if int(ctx.detail) > 0:
			for j in 5:
				var t := (j + 1.0) / 6.0
				k.cylinder(xf(q + lean * t * t + Vector3(0, h * t, 0)), 0.052, 0.05, 0.03, c.darkened(0.35), c.darkened(0.35), 6)
		for j in 3:
			var t2 := rng.randf_range(0.55, 0.95)
			var lp := q + lean * t2 * t2 + Vector3(0, h * t2, 0)
			for s in 3:
				k.blade(xf(lp, rng.randf() * TAU, 0.6), 0.32, 0.06, Color(ctx.leaf).lightened(0.1), Color(ctx.leaf).lightened(0.2), 0.4, 2)


static func _mangrove(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var bark := Color("5a4a3a")
	var hub := p + Vector3(0, 0.8, 0)
	k.cylinder(xf(hub), 0.12, 0.09, 1.6, bark, bark.lightened(0.1), 6)
	# arching prop roots
	for i in 8:
		var a := TAU * i / 8.0 + rng.randf() * 0.3
		var d := Vector3(cos(a), 0, sin(a))
		var pts := PackedVector3Array([hub + Vector3(0, 0.2, 0), hub + d * 0.35 + Vector3(0, 0.15, 0), hub + d * 0.65 + Vector3(0, -0.25, 0), p + d * 0.8 + Vector3(0, -0.15, 0)])
		k.tube(pts, 0.035, 0.03, bark.lightened(0.05), bark.darkened(0.3), 4)
	for i in 4:
		k.blob(xf(hub + Vector3(rng.randf_range(-0.5, 0.5), 1.5 + rng.randf_range(0.0, 0.4), rng.randf_range(-0.3, 0.3))), Vector3(0.6, 0.35, 0.5), Color(ctx.leaf).darkened(rng.randf_range(0.0, 0.25)), int(ctx.seg), 0.3)


static func _pneumatophores(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	for i in 12:
		var q := p + Vector3(rng.randf_range(-0.45, 0.45), -0.05, rng.randf_range(-0.45, 0.45))
		k.cylinder(xf(q), 0.025, 0.008, rng.randf_range(0.15, 0.35), Color("4a3a2a"), Color("8a7a5a"), 4)


static func _araucaria(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var h := 3.0
	k.cylinder(xf(p), 0.16, 0.1, h, Color("6a4a32"), Color("7a5a3a"), 7)
	# candelabra crown: whorls of upturned branches
	for w in 2:
		var y := h - 0.5 + w * 0.35
		for i in 6:
			var a := TAU * i / 6.0 + w * 0.5
			var d := Vector3(cos(a), 0, sin(a))
			var tip := p + Vector3(0, y, 0) + d * (0.9 - w * 0.3) + Vector3(0, 0.35, 0)
			k.tube(PackedVector3Array([p + Vector3(0, y, 0), p + Vector3(0, y + 0.05, 0) + d * 0.5, tip]), 0.035, 0.02, Color("6a4a32"), Color("6a4a32"), 4)
			k.blob(xf(tip), Vector3(0.22, 0.12, 0.22), Color(ctx.leaf).darkened(0.2), 6, 0.2)


static func _elfin(ctx: Dictionary, p: Vector3, side: float) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var moss := Color("6a9a3a")
	var pts := PackedVector3Array([p, p + Vector3(side * -0.2, 0.6, 0.1), p + Vector3(side * 0.1, 1.2, -0.1), p + Vector3(side * -0.4, 1.7, 0.0)])
	k.tube(pts, 0.14, 0.08, Color("4a3a2a"), Color("5a4a2a"), 6)
	for q in pts:
		k.blob(xf(q + Vector3(rng.randf_range(-0.05, 0.05), 0.05, 0)), Vector3(0.18, 0.12, 0.18), moss.darkened(rng.randf_range(0.0, 0.25)), 6, 0.45)
	k.blob(xf(pts[3] + Vector3(0, 0.2, 0)), Vector3(0.7, 0.35, 0.55), Color(ctx.leaf).darkened(0.1), int(ctx.seg), 0.4)
	_orchids(ctx, pts[2] + Vector3(0, 0.1, 0))


static func _nipa(ctx: Dictionary, p: Vector3) -> void:
	var rng: RandomNumberGenerator = ctx.rng
	for i in 6:
		var a := TAU * i / 6.0 + rng.randf() * 0.4
		_frond(ctx, p + Vector3(0, 0.05, 0), Vector3(cos(a), 1.6, sin(a)), rng.randf_range(1.2, 1.7), Color(ctx.leaf).lightened(0.1))


static func _bromeliad(ctx: Dictionary, p: Vector3, s: float) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var c := Color(ctx.leaf).lightened(0.15).lerp(Color("a8b83a"), 0.3)
	for i in 10:
		var a := TAU * i / 10.0 + rng.randf() * 0.2
		k.blade(xf(p, a, -0.9 + (i % 2) * 0.3), 0.32 * s, 0.09 * s, c.darkened(0.2), c.lerp(Color("c83a3a"), 0.35), 0.35, 2)
	k.blob(xf(p + Vector3(0, 0.08 * s, 0)), Vector3(0.05, 0.12, 0.05) * s, Color(ctx.flower), 6)


static func _heliconia(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	for i in 4:
		var q := p + Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
		var h := rng.randf_range(0.9, 1.5)
		k.cylinder(xf(q), 0.025, 0.02, h, Color("4a7a2a"), Color("5a8a2a"), 4)
		k.blade(xf(q + Vector3(0, h, 0), rng.randf() * TAU, -0.6), 0.75, 0.24, Color(ctx.leaf), Color(ctx.leaf).lightened(0.1), 0.15, 3)
	# hanging zig-zag bracts, red tipped with yellow
	var stem := p + Vector3(0, 1.3, 0)
	for j in 6:
		var bp := stem + Vector3((j % 2 - 0.5) * 0.12, -j * 0.09, 0)
		k.blob(xf(bp, 0.0, 0.0, (j % 2 - 0.5) * 1.2), Vector3(0.09, 0.03, 0.04), Color("e8242a").lerp(Color("f6d83a"), 0.15 if j % 2 == 0 else 0.0), 6)
		k.blob(xf(bp + Vector3((j % 2 - 0.5) * 0.14, 0.01, 0)), Vector3(0.025, 0.02, 0.02), Color("f6d83a"), 4)


static func _pitchers(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	for i in 4:
		var a := TAU * i / 4.0 + rng.randf() * 0.5
		var q := p + Vector3(cos(a) * 0.3, 0.0, sin(a) * 0.3)
		var c := Color("8a3a2a").lerp(Color("6a9a2a"), rng.randf())
		k.cylinder(xf(q), 0.06, 0.08, 0.28, c.darkened(0.2), c, 7)
		k.cylinder(xf(q + Vector3(0, 0.28, 0)), 0.09, 0.095, 0.03, Color("c83a3a"), Color("e85a3a"), 7)
		k.disc(xf(q + Vector3(0, 0.36, -0.06), 0.0, -0.9), 0.08, c.lightened(0.1), 8)
		k.blade(xf(q + Vector3(0, 0.02, 0), a + PI, -0.2), 0.3, 0.08, Color(ctx.leaf), Color(ctx.leaf), 0.2, 2)


static func _rafflesia(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var red := Color("c8442a")
	for i in 5:
		var a := TAU * i / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		k.blob(xf(p + d * 0.26 + Vector3(0, 0.06, 0), -a), Vector3(0.2, 0.06, 0.17), red, 8, 0.15)
		for j in 3:
			k.blob(xf(p + d * (0.18 + j * 0.08) + Vector3(cos(a + j) * 0.04, 0.12, sin(a + j) * 0.04)), Vector3(0.025, 0.012, 0.025), Color("f2e2c8"), 4)
	k.cylinder(xf(p + Vector3(0, 0.04, 0)), 0.15, 0.13, 0.14, red.darkened(0.25), red.darkened(0.1), 10)
	k.disc(xf(p + Vector3(0, 0.17, 0)), 0.11, Color("4a1a14"), 10)


static func _orchids(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var f: Color = Color(ctx.flower).lerp(Color("e87ad8"), 0.4)
	for i in 3:
		var stem := p + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		var top := stem + Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(0.35, 0.6), 0)
		k.tube(PackedVector3Array([stem, (stem + top) * 0.5 + Vector3(0.05, 0, 0), top]), 0.012, 0.008, Color("4a6a2a"), Color("4a6a2a"), 3)
		for j in 5:
			var a := TAU * j / 5.0
			k.blob(xf(top + Vector3(cos(a) * 0.05, sin(a) * 0.05, 0), 0.0, 0.0, a), Vector3(0.045, 0.02, 0.01), f.lightened(0.1 * (j % 2)), 5)
		k.blob(xf(top), Vector3(0.02, 0.02, 0.02), Color("f6e05a"), 4)


static func _fern(ctx: Dictionary, p: Vector3, s: float) -> void:
	var rng: RandomNumberGenerator = ctx.rng
	var n := 6 if int(ctx.detail) > 0 else 4
	for i in n:
		var a := TAU * i / n + rng.randf() * 0.4
		_frond(ctx, p, Vector3(cos(a), 0.9, sin(a)), rng.randf_range(0.5, 0.75) * s, Color(ctx.leaf).lightened(rng.randf_range(0.0, 0.18)))


static func _moss_rock(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var rock := Color("7a7a72")
	var rad := Vector3(rng.randf_range(0.35, 0.55), rng.randf_range(0.25, 0.4), rng.randf_range(0.3, 0.45))
	k.blob(xf(p + Vector3(0, rad.y * 0.5, 0), rng.randf() * TAU), rad, rock, int(ctx.seg), 0.3)
	k.blob(xf(p + Vector3(0, rad.y * 1.05, 0)), Vector3(rad.x * 0.8, rad.y * 0.35, rad.z * 0.8), Color("5a8a2a"), int(ctx.seg), 0.4)
	_fern(ctx, p + Vector3(rad.x * 0.6, 0, 0), 0.5)


static func _mushrooms(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var g: Kit = ctx.g
	var rng: RandomNumberGenerator = ctx.rng
	var glow := "fireflies" in Array(Dictionary(ctx.sc).get("particles", []))
	for i in 5:
		var q := p + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
		var h := rng.randf_range(0.08, 0.2)
		k.cylinder(xf(q), 0.02, 0.018, h, Color("e8e0c8"), Color("f2ece0"), 5)
		var cap := Color("e8a83a") if not glow else Color("b8f0c8")
		k.blob(xf(q + Vector3(0, h, 0)), Vector3(0.07, 0.035, 0.07), cap, 7)
		if glow:
			g.blob(xf(q + Vector3(0, h, 0)), Vector3(0.14, 0.08, 0.14), Color(0.5, 1.0, 0.7, 0.25), 6, 0.0, 0.0)


static func _giant_lily(ctx: Dictionary, p: Vector3) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	for i in 2:
		var q := p + Vector3(rng.randf_range(-0.3, 0.3), 0.02, rng.randf_range(-0.25, 0.25))
		k.disc(xf(q), rng.randf_range(0.45, 0.6), Color("4a8a2a"), 18, 0.0, 0.07)
	if rng.randf() < 0.6:
		var fp := p + Vector3(0.2, 0.08, 0.1)
		for j in 8:
			var a := TAU * j / 8.0
			k.blob(xf(fp + Vector3(cos(a) * 0.06, 0.03, sin(a) * 0.06), -a, 0.0, 0.6), Vector3(0.07, 0.025, 0.035), Color("f2c8d8"), 5)
		k.blob(xf(fp + Vector3(0, 0.05, 0)), Vector3(0.04, 0.04, 0.04), Color("f6e05a"), 5)


static func _karst(ctx: Dictionary, p: Vector3, side: float, s: float) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var stone := Color("b8b4a4")
	var y := 0.0
	var r := 0.7 * s
	for i in 5:
		var h := rng.randf_range(0.7, 1.1) * s
		var c := stone.darkened(rng.randf_range(0.0, 0.25))
		k.blob(xf(p + Vector3(side * 0.3, y + h * 0.5, 0), rng.randf() * TAU), Vector3(r, h * 0.62, r * 0.8), c, int(ctx.seg), 0.25, 0.25)
		# green ledges
		k.blob(xf(p + Vector3(side * 0.3 - side * r * 0.4, y + h * 0.95, 0)), Vector3(r * 0.5, 0.12, r * 0.5), Color(ctx.leaf).darkened(0.1), 6, 0.4)
		y += h * 0.85
		r *= 0.82
	# dark streaks of rain-wash
	for i in 3:
		k.box(xf(p + Vector3(-side * 0.25, y * 0.4, rng.randf_range(-0.3, 0.3))), Vector3(0.03, y * 0.7, 0.08), stone.darkened(0.45))


# ====================================================================== landmarks

static func _landmark(ctx: Dictionary, kind: String) -> void:
	var k: Kit = ctx.k
	var g: Kit = ctx.g
	var rng: RandomNumberGenerator = ctx.rng
	var lane: Lane = ctx.lane
	var side := -1.0 if lane.row % 2 == 0 else 1.0
	var sx := -1.3 if side < 0.0 else 10.3
	match kind:
		"ruin_temple":
			var stone := Color("a89a82")
			var moss := Color("5a7a3a")
			for i in 5:
				var w := 2.6 - i * 0.42
				var c := stone.darkened(0.05 * (i % 2))
				k.box(xf(Vector3(sx + side * (0.9 - i * 0.12), 0.3 + i * 0.6, 0.0)), Vector3(w, 0.6, 2.4 - i * 0.35), c, moss.lerp(stone, 0.4))
			# stairs facing the play area
			for j in 8:
				k.box(xf(Vector3(sx - side * 0.75 + side * j * 0.1, 0.1 + j * 0.34, 0.0)), Vector3(0.3, 0.12, 0.7), stone.lightened(0.08))
			k.box(xf(Vector3(sx + side * 0.6, 3.4, 0.0)), Vector3(0.9, 0.9, 0.9), stone.darkened(0.1))
			k.box(xf(Vector3(sx + side * 0.15, 3.3, 0.0)), Vector3(0.05, 0.5, 0.35), Color("1a1410"))
			for i in 6:
				k.blob(xf(Vector3(sx + side * rng.randf_range(0.0, 1.2), rng.randf_range(0.6, 3.0), rng.randf_range(-0.9, 0.9))), Vector3(0.3, 0.15, 0.25), moss.darkened(rng.randf_range(0.0, 0.2)), 6, 0.4)
				_liana(ctx, Vector3(sx + side * rng.randf_range(0.0, 0.8), 3.4, rng.randf_range(-0.8, 0.8)), 0.6)
		"stela":
			var stone2 := Color("9a9078")
			for i in 3:
				var q := Vector3(sx - side * 0.1 * i, 0.0, -0.6 + i * 0.6)
				k.box(xf(q + Vector3(0, 0.75, 0), rng.randf_range(-0.2, 0.2)), Vector3(0.35, 1.5, 0.55), stone2, stone2.lightened(0.1))
				for b in 4:
					k.box(xf(q + Vector3(-side * 0.18, 0.3 + b * 0.32, 0)), Vector3(0.03, 0.16, 0.42), stone2.darkened(0.3))
			k.blob(xf(Vector3(sx - side * 0.5, 0.15, 0.0)), Vector3(0.45, 0.18, 0.45), stone2.darkened(0.1), 10, 0.1)
		"waterfall", "cenote":
			var rock := Color("6a6a5e")
			if kind == "waterfall":
				k.box(xf(Vector3(sx + side * 0.5, 2.0, 0.0)), Vector3(1.0, 4.2, 2.6), rock, Color(ctx.leaf).darkened(0.2))
				(ctx.nodes as Array).append({"falls": true, "pos": Vector3(sx - side * 0.02, 2.0, 0.0), "rot": PI * 0.5 * side})
				for i in 5:
					g.blob(xf(Vector3(sx - side * 0.3, 0.2 + i * 0.05, rng.randf_range(-0.5, 0.5))), Vector3(0.5, 0.25, 0.4), Color(1, 1, 1, 0.08), 6, 0.2, 0.0)
			k.disc(xf(Vector3(sx - side * 0.3, 0.03, 0.0)), 0.9, Color("2a5a6a"), 16, 0.0, 0.06)
			for i in 6:
				var a := TAU * i / 6.0
				k.blob(xf(Vector3(sx - side * 0.3, 0.06, 0.0) + Vector3(cos(a), 0, sin(a)) * 0.95), Vector3(0.25, 0.14, 0.2), rock.lightened(0.1), 6, 0.3)
			if kind == "cenote":
				for i in 5:
					_liana(ctx, Vector3(sx - side * rng.randf_range(0.0, 0.6), 2.6, rng.randf_range(-0.6, 0.6)), 0.9)
		"canopy_walkway", "hanging_bridge":
			var rope := Color("c8b88a")
			var plank := Color("8a6a42")
			var y := 2.15
			for side2 in [-1.3, 10.3]:
				k.cylinder(xf(Vector3(side2, 0.0, 0.0)), 0.35, 0.28, 3.2, Color(ctx.bark).darkened(0.3), Color(ctx.bark), 9)
				k.box(xf(Vector3(side2, y - 0.05, 0.0)), Vector3(0.9, 0.08, 0.9), plank.darkened(0.2))
			var n := 24
			for i in n:
				var t := (i + 0.5) / n
				var x := lerpf(-0.9, 9.9, t)
				var sag := sin(t * PI) * 0.35
				k.box(xf(Vector3(x, y - sag, 0.0)), Vector3(0.36, 0.04, 0.5), plank.lightened(0.06 * (i % 3)))
			for zz in [-0.28, 0.28]:
				var pts := PackedVector3Array()
				for i in 9:
					var t2 := i / 8.0
					pts.append(Vector3(lerpf(-1.1, 10.1, t2), y + 0.45 - sin(t2 * PI) * 0.35, zz))
				k.tube(pts, 0.018, 0.018, rope, rope, 4)
				for i in 9:
					var t3 := i / 8.0
					var px := lerpf(-1.1, 10.1, t3)
					var py := y - sin(t3 * PI) * 0.35
					k.cylinder(xf(Vector3(px, py, zz)), 0.01, 0.01, 0.45, rope.darkened(0.2), rope.darkened(0.2), 3)
		"cave_arch":
			var stone3 := Color("a8a294")
			for side3 in [-1.0, 1.0]:
				var bx := -1.0 if side3 < 0.0 else 10.0
				_karst(ctx, Vector3(bx, 0.0, 0.0), side3, 0.9)
			var pts2 := PackedVector3Array()
			for i in 11:
				var t4 := i / 10.0
				pts2.append(Vector3(lerpf(-1.2, 10.2, t4), 2.2 + sin(t4 * PI) * 0.6, 0.0))
			k.tube(pts2, 0.55, 0.55, stone3, stone3.darkened(0.1), int(ctx.seg))
			# stalactites
			for i in 9:
				var sxp := rng.randf_range(0.0, 9.0)
				var top := 2.0 + sin(sxp / 9.0 * PI) * 0.6
				k.cylinder(xf(Vector3(sxp, top, rng.randf_range(-0.3, 0.3)), 0.0, 0.0, PI), 0.08, 0.0, rng.randf_range(0.25, 0.5), stone3.darkened(0.15), stone3.lightened(0.1), 5)
		"clay_cliff":
			var clay := Color("c8784a")
			for i in 4:
				k.box(xf(Vector3(sx + side * 0.6, 0.6 + i * 0.9, rng.randf_range(-0.2, 0.2)), rng.randf_range(-0.1, 0.1)), Vector3(1.2, 0.95, 2.6), clay.darkened(0.08 * (i % 2)), Color(ctx.leaf).darkened(0.1))
			for i in 7:
				k.blob(xf(Vector3(sx - side * 0.02, rng.randf_range(0.5, 3.0), rng.randf_range(-1.0, 1.0))), Vector3(0.05, 0.08, 0.08), Color("6a3a22"), 5)
		"giant_ceiba", "karst_tower":
			if kind == "giant_ceiba":
				_giant_tree(ctx, Vector3(sx + side * 0.3, 0.0, 0.0), side, 1.7)
				for i in 4:
					_liana(ctx, Vector3(sx - side * rng.randf_range(0.2, 0.9), 2.7, rng.randf_range(-0.6, 0.6)), 1.0)
			else:
				_karst(ctx, Vector3(sx + side * 0.6, 0.0, 0.0), side, 1.6)


static func _liana(ctx: Dictionary, top: Vector3, s: float) -> void:
	var k: Kit = ctx.k
	var rng: RandomNumberGenerator = ctx.rng
	var len := rng.randf_range(0.9, 1.4) * s
	var pts := PackedVector3Array()
	for i in 6:
		var t := i / 5.0
		pts.append(top + Vector3(sin(t * 4.0 + top.x) * 0.06, -len * t, cos(t * 3.0) * 0.05))
	k.tube(pts, 0.022, 0.014, Color("4a5a2a"), Color("5a7a2a"), 4)
	if int(ctx.detail) > 0:
		for i in range(1, 6, 2):
			k.blade(xf(pts[i], rng.randf() * TAU, 0.4), 0.18, 0.08, Color(ctx.leaf), Color(ctx.leaf).lightened(0.1), 0.2, 2)


# ====================================================================== fauna and particles

static func _fauna_node(root: Node3D, fid: String, rng: RandomNumberGenerator) -> Dictionary:
	var f: Dictionary = FAUNA[fid]
	var cols: Array = f.colors
	var sz := float(f.size)
	var k := Kit.new()
	if String(f.kind) == "butterfly":
		for s in [-1.0, 1.0]:
			k.disc(xf(Vector3(s * sz * 0.5, 0, 0), 0.0, 0.0, 0.0, 1.0), sz * 0.5, Color(String(cols[0])), 10)
			k.disc(xf(Vector3(s * sz * 0.35, 0.002, sz * 0.35)), sz * 0.3, Color(String(cols[1])), 8)
		k.blob(xf(Vector3.ZERO), Vector3(0.02, 0.02, sz * 0.4), Color("1a1a1a"), 5)
	else:
		k.blob(xf(Vector3.ZERO), Vector3(sz * 0.25, sz * 0.22, sz * 0.6), Color(String(cols[0])), 8)
		k.blob(xf(Vector3(0, sz * 0.05, sz * 0.55)), Vector3(sz * 0.18, sz * 0.18, sz * 0.2), Color(String(cols[0])).lightened(0.05), 6)
		k.blob(xf(Vector3(0, 0.0, sz * 0.75)), Vector3(sz * 0.05, sz * 0.06, sz * 0.15), Color(String(cols[2])), 5)
		for s in [-1.0, 1.0]:
			k.blade(xf(Vector3(s * sz * 0.15, sz * 0.05, sz * 0.1), s * PI * 0.5), sz * 1.1, sz * 0.55, Color(String(cols[1])), Color(String(cols[0])), 0.05, 2)
		k.blade(xf(Vector3(0, 0, -sz * 0.5), PI), sz * 0.9, sz * 0.25, Color(String(cols[0])), Color(String(cols[1])), 0.0, 2)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var count := 4 if String(f.kind) == "butterfly" else 2
	mm.instance_count = count
	mm.mesh = k.mesh()
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
	var seeds := []
	for i in count:
		seeds.append(rng.randf() * 100.0)
	return {"node": mmi, "kind": String(f.kind), "seeds": seeds}


static func _particle_node(root: Node3D, kind: String, rng: RandomNumberGenerator, light: Color) -> Dictionary:
	var k := Kit.new()
	var count := 0
	var mat := glow_material()
	match kind:
		"fireflies":
			k.blob(xf(Vector3.ZERO), Vector3(0.025, 0.025, 0.025), Color(0.9, 1.0, 0.5, 0.95), 8, 0.0, 0.0)
			k.blob(xf(Vector3.ZERO), Vector3(0.08, 0.08, 0.08), Color(0.7, 1.0, 0.4, 0.14), 8, 0.0, 0.0)
			count = 14
		"motes", "spray":
			k.blob(xf(Vector3.ZERO), Vector3(0.025, 0.025, 0.025), Color(light, 0.55) if kind == "motes" else Color(1, 1, 1, 0.4), 4, 0.0, 0.0)
			count = 20
		"rain":
			k.beam(xf(Vector3.ZERO), 0.012, 0.4, Color(0.8, 0.88, 0.95, 0.3))
			count = 40
		"leaves":
			k.blade(xf(Vector3.ZERO), 0.12, 0.07, Color("8a9a3a"), Color("a8a83a"), 0.1, 1)
			count = 10
			mat = material()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = k.mesh()
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
	var seeds := []
	for i in count:
		seeds.append(Vector3(rng.randf_range(-1.0, 10.0), rng.randf(), rng.randf_range(-0.5, 0.5)))
	return {"node": mmi, "kind": kind, "seeds": seeds}


## Moves fauna and particles. Called each frame for lanes in view.
static func animate(root: Node3D, t: float) -> void:
	for ch in root.get_children():
		if ch.has_meta("falls"):
			(ch as MeshInstance3D).material_override.set("uv1_offset", Vector3(0.0, -t * 1.6, 0.0))
	var anim: Array = root.get_meta("anim", [])
	for a in anim:
		var mmi: MultiMeshInstance3D = a.node
		if not is_instance_valid(mmi):
			continue
		var mm := mmi.multimesh
		var seeds: Array = a.seeds
		match String(a.kind):
			"butterfly":
				for i in seeds.size():
					var s := float(seeds[i])
					var p := Vector3(4.5 + sin(t * 0.35 + s) * 5.5, 0.9 + sin(t * 1.3 + s * 2.0) * 0.45, sin(t * 0.5 + s) * 0.45)
					var flap := 0.25 + 0.75 * absf(sin(t * 14.0 + s))
					var b := Basis.from_euler(Vector3(0, cos(t * 0.35 + s) * 1.5, 0)).scaled(Vector3(flap, 1.0, 1.0))
					mm.set_instance_transform(i, Transform3D(b, p))
			"bird":
				for i in seeds.size():
					var s2 := float(seeds[i])
					var u := fposmod(t * 0.12 + s2, 1.0)
					var p2 := Vector3(lerpf(-3.0, 12.0, u) if i % 2 == 0 else lerpf(12.0, -3.0, u), 2.0 + sin(u * PI) * 0.4, sin(s2) * 0.3)
					var flap2 := 0.35 + 0.65 * absf(sin(t * 9.0 + s2))
					var yaw := PI * 0.5 if i % 2 == 0 else -PI * 0.5
					mm.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(0, yaw, 0)).scaled(Vector3(flap2, 1.0, 1.0)), p2))
			"fireflies", "motes", "spray":
				for i in seeds.size():
					var sd: Vector3 = seeds[i]
					var p3 := Vector3(sd.x + sin(t * 0.6 + sd.y * 9.0) * 0.4, 0.3 + fposmod(sd.y * 2.0 + t * 0.05, 1.0) * 1.8, sd.z + cos(t * 0.5 + sd.y * 7.0) * 0.2)
					var pulse := 0.4 + 0.6 * absf(sin(t * 2.0 + sd.y * 20.0)) if String(a.kind) == "fireflies" else 1.0
					mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * pulse), p3))
			"rain":
				for i in seeds.size():
					var sd2: Vector3 = seeds[i]
					var y := 2.6 - fposmod(sd2.y * 2.6 + t * 6.0, 2.6)
					mm.set_instance_transform(i, Transform3D(Basis(), Vector3(sd2.x, y, sd2.z)))
			"leaves":
				for i in seeds.size():
					var sd3: Vector3 = seeds[i]
					var y2 := 2.5 - fposmod(sd3.y * 2.5 + t * 0.4, 2.5)
					var b2 := Basis.from_euler(Vector3(t * 2.0 + sd3.y * 9.0, t + sd3.x, sin(t * 3.0 + sd3.x)))
					mm.set_instance_transform(i, Transform3D(b2, Vector3(sd3.x + sin(t + sd3.y * 6.0) * 0.3, y2, sd3.z)))
