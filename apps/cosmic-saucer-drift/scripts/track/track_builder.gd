class_name TrackBuilder
extends RefCounted
## Builds the track's meshes and collision from TrackData: road slab, neon
## barriers, ramps, shortcut, tunnels, start gate. Ground collision is on
## layer 1 (racers raycast it), walls on layer 2 (racers slide along them).

const LAYER_GROUND := 1
const LAYER_WALLS := 2
const BARRIER_H := 0.9
const BARRIER_W := 0.5
const SLAB := 1.4
const WALL_LOW := -2.0
const WALL_HIGH := 8.0


class MeshBuf:
	var v := PackedVector3Array()
	var nrm := PackedVector3Array()
	var uv := PackedVector2Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()

	## Quad a0-b0 (ring i) to a1-b1 (ring i+1), clockwise front faces.
	func quad(a0: Vector3, b0: Vector3, a1: Vector3, b1: Vector3, n0: Vector3, n1: Vector3,
			u0: Vector2, u1: Vector2, u2: Vector2, u3: Vector2, c0: Color, c1: Color) -> void:
		var base := v.size()
		v.append_array([a0, b0, a1, b1])
		nrm.append_array([n0, n0, n1, n1])
		uv.append_array([u0, u1, u2, u3])
		col.append_array([c0, c0, c1, c1])
		idx.append_array([base, base + 2, base + 1, base + 1, base + 2, base + 3])

	func empty() -> bool:
		return v.is_empty()

	func commit(mat: Material) -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = nrm
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_COLOR] = col
		arr[Mesh.ARRAY_INDEX] = idx
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		m.surface_set_material(0, mat)
		return m


## Scale a basis along its own axes.
static func sb(b: Basis, s: Vector3) -> Basis:
	return Basis(b.x * s.x, b.y * s.y, b.z * s.z)


static func _p(path: TrackPath, i: int, a: Vector2) -> Vector3:
	return path.pts[i] + path.rgt[i] * a.x + path.upv[i] * a.y


static func _n(path: TrackPath, i: int, a: Vector2, b: Vector2) -> Vector3:
	var d := b - a
	var n2 := Vector2(-d.y, d.x).normalized()
	return (path.rgt[i] * n2.x + path.upv[i] * n2.y).normalized()


## Sweep profile edges [a, b, u_a, u_b] along a path. include(i, e) filters.
static func sweep(buf: MeshBuf, path: TrackPath, edges: Array, include: Callable, color_of: Callable, v_scale: float, half_w: Callable) -> void:
	var segs := path.n if path.closed else path.n - 1
	for i in segs:
		var j := path.wi(i + 1)
		var v0 := float(i) * path.step * v_scale
		var v1 := float(i + 1) * path.step * v_scale
		var c0: Color = color_of.call(i)
		var c1: Color = color_of.call(j)
		var hw0: float = half_w.call(i)
		var hw1: float = half_w.call(j)
		for e in edges.size():
			if not include.call(i, e):
				continue
			var ed: Array = edges[e]
			var a: Vector2 = ed[0]
			var b: Vector2 = ed[1]
			# Profiles are written for half-width 1: x is scaled by the road
			# half width plus any fixed offset in ed[4].
			var off: Vector2 = ed[4] if ed.size() > 4 else Vector2.ZERO
			var a0 := Vector2(a.x * hw0 + off.x * signf(a.x if a.x != 0.0 else b.x), a.y)
			var b0 := Vector2(b.x * hw0 + off.y * signf(b.x if b.x != 0.0 else a.x), b.y)
			var a1 := Vector2(a.x * hw1 + off.x * signf(a.x if a.x != 0.0 else b.x), a.y)
			var b1 := Vector2(b.x * hw1 + off.y * signf(b.x if b.x != 0.0 else a.x), b.y)
			buf.quad(_p(path, i, a0), _p(path, i, b0), _p(path, j, a1), _p(path, j, b1),
				_n(path, i, a0, b0), _n(path, j, a1, b1),
				Vector2(ed[2], v0), Vector2(ed[3], v0), Vector2(ed[2], v1), Vector2(ed[3], v1), c0, c1)


## Flat collision faces across [-hw, hw] at height y for included segments.
static func ground_faces(path: TrackPath, include: Callable, y: float, extra_w: float) -> PackedVector3Array:
	var f := PackedVector3Array()
	var segs := path.n if path.closed else path.n - 1
	for i in segs:
		if not include.call(i):
			continue
		var j := path.wi(i + 1)
		var hi := path.wid[i] * 0.5 + extra_w
		var hj := path.wid[j] * 0.5 + extra_w
		var a0 := _p(path, i, Vector2(-hi, y))
		var b0 := _p(path, i, Vector2(hi, y))
		var a1 := _p(path, j, Vector2(-hj, y))
		var b1 := _p(path, j, Vector2(hj, y))
		f.append_array([a0, a1, b0, b0, a1, b1])
	return f


## Vertical wall faces on one side (side = -1 left, +1 right).
static func wall_faces(path: TrackPath, include: Callable, side: float, heights := PackedFloat32Array()) -> PackedVector3Array:
	var f := PackedVector3Array()
	var segs := path.n if path.closed else path.n - 1
	for i in segs:
		if not include.call(i):
			continue
		var j := path.wi(i + 1)
		var xi := side * (path.wid[i] * 0.5 + 0.25)
		var xj := side * (path.wid[j] * 0.5 + 0.25)
		var hi := heights[i] if not heights.is_empty() else WALL_HIGH
		var hj := heights[j] if not heights.is_empty() else WALL_HIGH
		var a0 := _p(path, i, Vector2(xi, WALL_LOW))
		var b0 := _p(path, i, Vector2(xi, hi))
		var a1 := _p(path, j, Vector2(xj, WALL_LOW))
		var b1 := _p(path, j, Vector2(xj, hj))
		f.append_array([a0, a1, b0, b0, a1, b1])
	return f


static func static_body(parent: Node3D, faces: PackedVector3Array, layer: int, body_name: String, surface := -1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = layer
	body.collision_mask = 0
	body.set_meta("surface", surface)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	return body


static func mesh_node(parent: Node3D, mesh: Mesh, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# ---------------------------------------------------------------- materials
static var _detail_mats: Array[ShaderMaterial] = []
static var _detail := 1.0
static var _metal_k := 1.0


## Road/barrier shader detail for the graphics tier (0 low .. 1 high).
## Without sky reflections metal reads as black, so it is toned down.
static func set_quality(detail: float, reflect := true) -> void:
	_detail = detail
	_metal_k = 1.0 if reflect else 0.35
	var keep: Array[ShaderMaterial] = []
	for m in _detail_mats:
		if is_instance_valid(m):
			m.set_shader_parameter("detail", detail)
			m.set_shader_parameter("metal_k", _metal_k)
			keep.append(m)
	_detail_mats = keep


static func _track_detail(m: ShaderMaterial) -> ShaderMaterial:
	m.set_shader_parameter("detail", _detail)
	m.set_shader_parameter("metal_k", _metal_k)
	_detail_mats.append(m)
	if _detail_mats.size() > 24:
		_detail_mats = _detail_mats.slice(_detail_mats.size() - 24)
	return m


static func road_material(neon: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/road.gdshader")
	m.set_shader_parameter("neon", neon)
	return _track_detail(m)


static func barrier_material(c: Color, neon: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/barrier.gdshader")
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("neon", neon)
	return _track_detail(m)


static func flat(c: Color, emission := 0.0, metallic := 0.3, rough := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metallic
	m.roughness = rough
	m.vertex_color_use_as_albedo = false
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


static func glow(c: Color, energy := 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c * energy
	return m


static func ghost(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	return m


# ---------------------------------------------------------------- build
static func build(td: TrackData, root: Node3D) -> void:
	var theme := Themes.get_theme(td.theme)
	var neon: Color = theme.neon
	var road_mat := road_material(neon)
	var barrier_mat := barrier_material(theme.barrier, neon)
	var under_mat := flat(Color(theme.barrier) * 0.55, 0.0, 0.4, 0.8)
	var neon_mat := glow(neon, 2.2)
	_build_path(td, td.main, root, "Main", road_mat, barrier_mat, under_mat, neon_mat, true)
	if td.short:
		_build_path(td, td.short, root, "Shortcut", road_mat, barrier_mat, under_mat, neon_mat, false)
		if td.short_lift_start or td.short_lift_end:
			_pillars(td, root, barrier_mat)
	_build_ramps(td, root)
	_build_tubes(td, root, neon)
	_build_gate(td, root, neon)


static func _build_path(td: TrackData, path: TrackPath, root: Node3D, prefix: String, road_mat: Material,
		barrier_mat: Material, under_mat: Material, neon_mat: Material, is_main: bool) -> void:
	var gap_at := func(i: int) -> bool: return is_main and td.gap[i] == 1
	var seg_gap := func(i: int) -> bool: return gap_at.call(i) or gap_at.call(path.wi(i + 1))
	var open_side := func(i: int, side: int) -> bool:
		if is_main:
			var arr := td.open_r if side > 0 else td.open_l
			return arr[i] == 1 or arr[path.wi(i + 1)] == 1
		var arr2 := td.short_skip_r if side > 0 else td.short_skip_l
		return arr2[i] == 1 or arr2[path.wi(i + 1)] == 1
	var hw := func(i: int) -> float: return path.wid[i] * 0.5
	var surf_color := func(i: int) -> Color:
		var sid: int = path.surf[i]
		var c: Color = Catalog.surface(sid).color
		return Color(c.r, c.g, c.b, float(sid) / 8.0)
	var white := func(_i: int) -> Color: return Color.WHITE
	# Road top.
	var road := MeshBuf.new()
	var road_inc := func(i: int, _e: int) -> bool: return not seg_gap.call(i)
	sweep(road, path, [[Vector2(-1, 0), Vector2(1, 0), 0.0, 1.0]], road_inc, surf_color, 0.125, hw)
	mesh_node(root, road.commit(road_mat), prefix + "Road")
	# Barriers (inner + outer faces) and neon tops; skirt where open.
	var bw := BARRIER_W
	var bar := MeshBuf.new()
	var bar_edges := [
		[Vector2(1, 0), Vector2(1, BARRIER_H), 0.0, 0.3, Vector2.ZERO],             # right inner
		[Vector2(1, BARRIER_H), Vector2(1, -SLAB), 0.3, 1.0, Vector2(bw, bw)],     # right outer
		[Vector2(-1, -SLAB), Vector2(-1, BARRIER_H), 0.0, 0.7, Vector2(bw, bw)],   # left outer
		[Vector2(-1, BARRIER_H), Vector2(-1, 0), 0.7, 1.0, Vector2.ZERO],          # left inner
	]
	var short_ends := func(i: int) -> bool:
		return not is_main and (i < 2 or i > path.n - 4)
	var bar_inc := func(i: int, e: int) -> bool:
		if seg_gap.call(i) or short_ends.call(i):
			return false
		return not open_side.call(i, 1 if e < 2 else -1)
	sweep(bar, path, bar_edges, bar_inc, white, 0.25, hw)
	if not bar.empty():
		mesh_node(root, bar.commit(barrier_mat), prefix + "Barrier")
	var top := MeshBuf.new()
	var top_edges := [
		[Vector2(1, BARRIER_H), Vector2(1, BARRIER_H), 0.0, 1.0, Vector2(0, bw)],
		[Vector2(-1, BARRIER_H), Vector2(-1, BARRIER_H), 0.0, 1.0, Vector2(bw, 0)],
	]
	var top_inc := func(i: int, e: int) -> bool:
		if seg_gap.call(i) or short_ends.call(i):
			return false
		return not open_side.call(i, 1 if e == 0 else -1)
	sweep(top, path, top_edges, top_inc, white, 0.25, hw)
	if not top.empty():
		mesh_node(root, top.commit(neon_mat), prefix + "Neon")
	# Underside + skirts where barriers are open.
	var under := MeshBuf.new()
	var under_edges := [
		[Vector2(1, -SLAB), Vector2(-1, -SLAB), 0.0, 1.0, Vector2(bw, bw)],
		[Vector2(1, 0), Vector2(1, -SLAB), 0.0, 1.0, Vector2.ZERO],
		[Vector2(-1, -SLAB), Vector2(-1, 0), 0.0, 1.0, Vector2.ZERO],
	]
	var under_inc := func(i: int, e: int) -> bool:
		if seg_gap.call(i):
			return false
		if e == 0:
			return true
		return open_side.call(i, 1 if e == 1 else -1) or short_ends.call(i)
	sweep(under, path, under_edges, under_inc, white, 0.1, hw)
	if is_main:
		_gap_caps(td, under)
	mesh_node(root, under.commit(under_mat), prefix + "Under")
	# Collision.
	var surf_meta := -1 if is_main else td.short_surface
	var ground_inc := func(i: int) -> bool: return not seg_gap.call(i)
	static_body(root, ground_faces(path, ground_inc, 0.0, 0.6), LAYER_GROUND, prefix + "Ground", surf_meta)
	var walls := PackedVector3Array()
	for side: int in [-1, 1]:
		var wall_inc := func(i: int) -> bool:
			return not seg_gap.call(i) and not open_side.call(i, side) and not short_ends.call(i)
		var heights := td.short_wall_h
		if is_main:
			heights = td.wall_h_r if side > 0 else td.wall_h_l
		walls.append_array(wall_faces(path, wall_inc, float(side), heights))
	if not walls.is_empty():
		static_body(root, walls, LAYER_WALLS, prefix + "Walls")


static func _gap_caps(td: TrackData, buf: MeshBuf) -> void:
	var path := td.main
	for i in path.n:
		var j := path.wi(i + 1)
		var ring := -1
		var facing := 1.0
		if td.gap[i] == 0 and td.gap[j] == 1:
			ring = i
		elif td.gap[i] == 1 and td.gap[j] == 0:
			ring = j
			facing = -1.0
		if ring < 0:
			continue
		var hw := path.wid[ring] * 0.5 + BARRIER_W
		var p := path.pts[ring]
		var r := path.rgt[ring] * facing
		var u := path.upv[ring]
		var n := path.tan[ring] * facing
		var a0 := p - r * hw
		var b0 := p + r * hw
		var a1 := a0 - u * SLAB
		var b1 := b0 - u * SLAB
		buf.quad(a0, b0, a1, b1, n, n, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Color.WHITE, Color.WHITE)


static func _build_ramps(td: TrackData, root: Node3D) -> void:
	if td.ramps.is_empty():
		return
	var theme := Themes.get_theme(td.theme)
	var mat := road_material(Color(1.0, 0.85, 0.2))
	var side_mat := flat(Color(theme.barrier) * 1.2, 0.0, 0.6, 0.4)
	var top := MeshBuf.new()
	var sides := MeshBuf.new()
	var faces := PackedVector3Array()
	var path := td.main
	var rc := Color(0.12, 0.1, 0.05, 3.0 / 8.0)
	for r in td.ramps:
		var s0: float = r.s0
		var s1: float = r.s1
		var h: float = r.h
		var w: float = r.w * 0.5
		var lane: float = r.get("lane", 0.0)
		var yaw: float = r.get("yaw", 0.0)
		var steps := maxi(2, ceili((s1 - s0) / 1.5))
		for k in steps:
			var sa := s0 + (s1 - s0) * float(k) / float(steps)
			var sb := s0 + (s1 - s0) * float(k + 1) / float(steps)
			var ha := h * float(k) / float(steps) + 0.03
			var hb := h * float(k + 1) / float(steps) + 0.03
			var ia := path.index_at(sa)
			var fa := _frame_at(path, sa)
			var fb := _frame_at(path, sb)
			fa.origin += fa.basis.x * lane
			fb.origin += fb.basis.x * lane
			if yaw != 0.0:
				# A yawed ramp pivots about its foot (the first frame) so it
				# stays on the road where it starts and angles out at the lip.
				var foot := _frame_at(path, s0)
				foot.origin += foot.basis.x * lane
				var rot := Basis(foot.basis.y, -yaw)
				fa.basis = rot * fa.basis
				fb.basis = rot * fb.basis
				fa.origin = foot.origin + rot * (fa.origin - foot.origin)
				fb.origin = foot.origin + rot * (fb.origin - foot.origin)
			var a0 := fa.origin + fa.basis.x * -w + fa.basis.y * ha
			var b0 := fa.origin + fa.basis.x * w + fa.basis.y * ha
			var a1 := fb.origin + fb.basis.x * -w + fb.basis.y * hb
			var b1 := fb.origin + fb.basis.x * w + fb.basis.y * hb
			var nrm := (b0 - a0).cross(a1 - a0).normalized()
			if nrm.dot(path.upv[ia]) < 0.0:
				nrm = -nrm
			top.quad(a0, b0, a1, b1, nrm, nrm, Vector2(0, sa / 8.0), Vector2(1, sa / 8.0), Vector2(0, sb / 8.0), Vector2(1, sb / 8.0), rc, rc)
			faces.append_array([a0, a1, b0, b0, a1, b1])
			# Side walls of the wedge.
			var la0 := fa.origin + fa.basis.x * -w
			var la1 := fb.origin + fb.basis.x * -w
			var ra0 := fa.origin + fa.basis.x * w
			var ra1 := fb.origin + fb.basis.x * w
			sides.quad(la0, a0, la1, a1, -fa.basis.x, -fb.basis.x, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Color.WHITE, Color.WHITE)
			sides.quad(b0, ra0, b1, ra1, fa.basis.x, fb.basis.x, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Color.WHITE, Color.WHITE)
			if k == steps - 1:
				var e := fb
				var bl := e.origin + e.basis.x * -w
				var br := e.origin + e.basis.x * w
				sides.quad(a1, b1, bl, br, -e.basis.z, -e.basis.z, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Color.WHITE, Color.WHITE)
	mesh_node(root, top.commit(mat), "Ramps")
	mesh_node(root, sides.commit(side_mat), "RampSides")
	static_body(root, faces, LAYER_GROUND, "RampGround", Catalog.S_METAL)


## Interpolated frame at a distance on a path (origin on the centre line).
static func _frame_at(path: TrackPath, s: float) -> Transform3D:
	var f := s / path.step
	var i0 := floori(f)
	var t := f - float(i0)
	var a := path.wi(i0)
	var b := path.wi(i0 + 1)
	var o := path.pts[a].lerp(path.pts[b], t)
	var r := path.rgt[a].lerp(path.rgt[b], t).normalized()
	var u := path.upv[a].lerp(path.upv[b], t).normalized()
	var fw := path.tan[a].lerp(path.tan[b], t).normalized()
	return Transform3D(Basis(r, u, -fw), o)


static func _build_tubes(td: TrackData, root: Node3D, neon: Color) -> void:
	var ranges: Array = []
	for r in td.tubes:
		ranges.append([td.main, r.x, r.y])
	if td.short and td.short_tube:
		ranges.append([td.short, 0.0, td.short.length])
	if ranges.is_empty():
		return
	var shell_mat := ghost(neon.lerp(Color(0.6, 0.8, 1.0), 0.5), 0.16)
	var rib_mesh := TorusMesh.new()
	rib_mesh.rings = 24
	rib_mesh.ring_segments = 6
	var rib_tfs: Array[Transform3D] = []
	var shell := MeshBuf.new()
	for rr in ranges:
		var path: TrackPath = rr[0]
		var s0: float = rr[1]
		var s1: float = rr[2]
		var span := fposmod(s1 - s0, path.length) if path.closed else s1 - s0
		var steps := int(span / path.step)
		var segs := 12
		for k in steps:
			var i := path.wi(path.index_at(s0) + k)
			var j := path.wi(i + 1)
			var rad := path.wid[i] * 0.5 + 2.0
			for e in segs:
				var t0 := PI * float(e) / float(segs)
				var t1 := PI * float(e + 1) / float(segs)
				var a := Vector2(cos(t0), sin(t0)) * rad
				var b := Vector2(cos(t1), sin(t1)) * rad
				var n0 := -(path.rgt[i] * a.x + path.upv[i] * a.y).normalized()
				shell.quad(_p(path, i, a), _p(path, i, b), _p(path, j, a), _p(path, j, b), n0, n0,
					Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Color.WHITE, Color.WHITE)
			if k % 5 == 0:
				var y := path.tan[i]
				var x := path.rgt[i]
				var z := x.cross(y).normalized()
				var b := Basis(x * rad, y * 1.6, z * rad)
				rib_tfs.append(Transform3D(b, path.pts[i]))
	mesh_node(root, shell.commit(shell_mat), "TubeShell")
	rib_mesh.inner_radius = 0.94
	rib_mesh.outer_radius = 1.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rib_mesh
	mm.instance_count = rib_tfs.size()
	for k in rib_tfs.size():
		mm.set_instance_transform(k, rib_tfs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "TubeRibs"
	mmi.multimesh = mm
	mmi.material_override = glow(neon, 1.8)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


static func _pillars(td: TrackData, root: Node3D, mat: Material) -> void:
	var path := td.short
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 2.0
	cyl.height = 60.0
	cyl.radial_segments = 8
	for j in range(8, path.n - 8, 18):
		if td.short_skip_l[j] == 1 and td.short_skip_r[j] == 1:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = mat
		mi.position = path.pts[j] - Vector3.UP * (SLAB + 30.0)
		root.add_child(mi)


static func _build_gate(td: TrackData, root: Node3D, neon: Color) -> void:
	var path := td.main
	var hw := path.wid[0] * 0.5
	var gate := Node3D.new()
	gate.name = "StartGate"
	gate.transform = Transform3D(Basis(path.rgt[0], path.upv[0], -path.tan[0]), path.pts[0])
	root.add_child(gate)
	# Checker line on the road.
	var img := Image.create(16, 2, false, Image.FORMAT_RGB8)
	for x in 16:
		for y in 2:
			img.set_pixel(x, y, Color.WHITE if (x + y) % 2 == 0 else Color(0.05, 0.05, 0.08))
	var tex := ImageTexture.create_from_image(img)
	var cm := StandardMaterial3D.new()
	cm.albedo_texture = tex
	cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cm.emission_enabled = true
	cm.emission_texture = tex
	cm.emission_energy_multiplier = 0.4
	var line := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(hw * 2.0, 2.0)
	line.mesh = pm
	line.material_override = cm
	line.position = Vector3(0, 0.04, 0)
	gate.add_child(line)
	var post := BoxMesh.new()
	post.size = Vector3(1.0, 10.0, 1.0)
	var pmat := flat(Color(0.18, 0.18, 0.24), 0.0, 0.8, 0.3)
	for sx: float in [-1.0, 1.0]:
		var p := MeshInstance3D.new()
		p.mesh = post
		p.material_override = pmat
		p.position = Vector3(sx * (hw + 1.4), 5.0, 0)
		gate.add_child(p)
	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(hw * 2.0 + 3.8, 1.4, 1.2)
	beam.mesh = bm
	beam.material_override = pmat
	beam.position = Vector3(0, 10.0, 0)
	gate.add_child(beam)
	var strip := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(hw * 2.0 + 3.8, 0.25, 1.25)
	strip.mesh = sm
	strip.material_override = glow(neon, 2.5)
	strip.position = Vector3(0, 9.2, 0)
	gate.add_child(strip)
