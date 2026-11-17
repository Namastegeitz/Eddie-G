class_name MeshKit
extends RefCounted
## Procedural mesh toolkit for the HD craft and pilots:
## - lathe(): turned shapes from a 2D profile (saucer hulls, nozzles, domes)
##   with smooth normals and sharp creases where the profile says so.
## - blob(): superellipsoids, i.e. anything from a sphere to a rounded box,
##   with optional taper, for fins, pods, heads and wings.
## - arc(), star(): mouths, eyebrows and decals.
## - Merger: bakes many static parts into one mesh per material so a
##   detailed craft still costs only a handful of draw calls.
## Meshes are cached by their parameters, so 8 racers share them.

static var _cache := {}


## profile: points (radius, y) from the top of the axis down to the bottom.
## creases: indices of profile points that get a hard edge.
## Returns a closed turned mesh around +Y. UV.x = around, UV.y = along profile.
static func lathe(profile: PackedVector2Array, seg: int, creases: PackedInt32Array = PackedInt32Array()) -> ArrayMesh:
	var key := "lathe|%s|%d|%s" % [profile, seg, creases]
	if _cache.has(key):
		return _cache[key]
	var np := profile.size()
	var seg_n: Array[Vector2] = []
	var cum: Array[float] = [0.0]
	for i in np - 1:
		var d := profile[i + 1] - profile[i]
		seg_n.append(Vector2(-d.y, d.x).normalized())
		cum.append(cum[i] + d.length())
	var total := maxf(cum[np - 1], 0.0001)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for i in np - 1:
		# Normals at both ends of this band: shared with the neighbour unless creased.
		var n0: Vector2 = seg_n[i]
		var n1: Vector2 = seg_n[i]
		if i > 0 and not (i in creases):
			n0 = (seg_n[i - 1] + seg_n[i]).normalized()
		if i < np - 2 and not ((i + 1) in creases):
			n1 = (seg_n[i] + seg_n[i + 1]).normalized()
		var a := profile[i]
		var b := profile[i + 1]
		var base := verts.size()
		for k in seg + 1:
			var t := TAU * float(k) / float(seg)
			var c := cos(t)
			var s := sin(t)
			verts.append(Vector3(a.x * c, a.y, a.x * s))
			norms.append(Vector3(n0.x * c, n0.y, n0.x * s).normalized())
			uvs.append(Vector2(float(k) / float(seg), cum[i] / total))
			verts.append(Vector3(b.x * c, b.y, b.x * s))
			norms.append(Vector3(n1.x * c, n1.y, n1.x * s).normalized())
			uvs.append(Vector2(float(k) / float(seg), cum[i + 1] / total))
		for k in seg:
			var p := base + k * 2
			idx.append_array([p, p + 1, p + 2, p + 1, p + 3, p + 2])
	var mesh := _arrays_mesh(verts, norms, uvs, idx)
	_cache[key] = mesh
	return mesh


## Superellipsoid with half-sizes `size`. e1 shapes the profile top to bottom,
## e2 the cross-section (1 = round, 0.2 = boxy, 2 = diamond).
## taper scales x/z at the top (y = +size.y) relative to the bottom.
## lump > 0 adds organic noise (bio parts).
static func blob(size: Vector3, e1 := 1.0, e2 := 1.0, seg := 20, rings := 12,
		taper := Vector2.ONE, lump := 0.0, shift := Vector2.ZERO) -> ArrayMesh:
	var key := "blob|%s|%f|%f|%d|%d|%s|%f|%s" % [size, e1, e2, seg, rings, taper, lump, shift]
	if _cache.has(key):
		return _cache[key]
	var noise: FastNoiseLite = null
	if lump > 0.0:
		noise = FastNoiseLite.new()
		noise.seed = 11
		noise.frequency = 1.3
	var pos := func(th: float, ph: float) -> Vector3:
		var ct := _sp(cos(th), e1)
		var p := Vector3(size.x * ct * _sp(cos(ph), e2), size.y * _sp(sin(th), e1), size.z * ct * _sp(sin(ph), e2))
		var k := (p.y / size.y + 1.0) * 0.5
		p.x *= lerpf(1.0, taper.x, k)
		p.z *= lerpf(1.0, taper.y, k)
		p.x += shift.x * k * size.y
		p.z += shift.y * k * size.y
		if noise:
			p *= 1.0 + lump * noise.get_noise_3dv(p * 1.5)
		return p
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var eps := 0.002
	for r in rings + 1:
		var th := lerpf(-PI * 0.5, PI * 0.5, float(r) / float(rings))
		var thn := clampf(th, -PI * 0.5 + 0.01, PI * 0.5 - 0.01)
		for k in seg + 1:
			var ph := lerpf(-PI, PI, float(k) / float(seg))
			var p: Vector3 = pos.call(th, ph)
			var dph: Vector3 = pos.call(thn, ph + eps) - pos.call(thn, ph - eps)
			var dth: Vector3 = pos.call(thn + eps, ph) - pos.call(thn - eps, ph)
			var n := dph.cross(dth).normalized()
			var c: Vector3 = pos.call(thn, ph)
			if n.dot(c - Vector3(0, c.y * 0.5, 0)) < 0.0:
				n = -n
			if r == 0:
				n = Vector3.DOWN
			elif r == rings:
				n = Vector3.UP
			verts.append(p)
			norms.append(n)
			uvs.append(Vector2(float(k) / float(seg), 1.0 - float(r) / float(rings)))
	var row := seg + 1
	for r in rings:
		for k in seg:
			var a := r * row + k
			var b := a + row
			idx.append_array([a, a + 1, b, b, a + 1, b + 1])
	var mesh := _arrays_mesh(verts, norms, uvs, idx)
	_cache[key] = mesh
	return mesh


static func _sp(v: float, e: float) -> float:
	return signf(v) * pow(absf(v), e)


## A round tube bent along an arc in the XY plane, from angle a0 to a1
## (degrees, 0 = +X, 90 = +Y). Used for smiles, frowns and eyebrows.
static func arc(radius: float, thick: float, a0: float, a1: float, seg := 12, sides := 6) -> ArrayMesh:
	var key := "arc|%f|%f|%f|%f|%d|%d" % [radius, thick, a0, a1, seg, sides]
	if _cache.has(key):
		return _cache[key]
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for i in seg + 1:
		var a := deg_to_rad(lerpf(a0, a1, float(i) / float(seg)))
		var c := Vector3(cos(a), sin(a), 0.0) * radius
		var out := Vector3(cos(a), sin(a), 0.0)
		# Taper the ends so the stroke looks drawn.
		var tk := thick * (0.45 + 0.55 * sin(PI * float(i) / float(seg)))
		for k in sides + 1:
			var b := TAU * float(k) / float(sides)
			var n := out * cos(b) + Vector3(0, 0, 1) * sin(b)
			verts.append(c + n * tk)
			norms.append(n)
			uvs.append(Vector2(float(i) / float(seg), float(k) / float(sides)))
	var row := sides + 1
	for i in seg:
		for k in sides:
			var p := i * row + k
			idx.append_array([p, p + 1, p + row, p + 1, p + row + 1, p + row])
	var mesh := _arrays_mesh(verts, norms, uvs, idx)
	_cache[key] = mesh
	return mesh


## Flat 5-point star (or n points) with depth, facing +Z.
static func star(r_out: float, r_in: float, depth: float, points := 5) -> ArrayMesh:
	var key := "star|%f|%f|%f|%d" % [r_out, r_in, depth, points]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector2] = []
	for k in points * 2:
		var a := PI * 0.5 + PI * float(k) / float(points)
		var r := r_out if k % 2 == 0 else r_in
		ring.append(Vector2(cos(a), sin(a)) * r)
	var hz := depth * 0.5
	for k in ring.size():
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		# Front and back faces as fans from a raised centre.
		for f: float in [1.0, -1.0]:
			var c := Vector3(0, 0, hz * 1.8 * f)
			var pa := Vector3(a.x, a.y, hz * f)
			var pb := Vector3(b.x, b.y, hz * f)
			if f > 0.0:
				st.add_vertex(c)
				st.add_vertex(pb)
				st.add_vertex(pa)
			else:
				st.add_vertex(c)
				st.add_vertex(pa)
				st.add_vertex(pb)
		# Side wall.
		var a0 := Vector3(a.x, a.y, hz)
		var b0 := Vector3(b.x, b.y, hz)
		var a1 := Vector3(a.x, a.y, -hz)
		var b1 := Vector3(b.x, b.y, -hz)
		st.add_vertex(a0)
		st.add_vertex(b0)
		st.add_vertex(a1)
		st.add_vertex(a1)
		st.add_vertex(b0)
		st.add_vertex(b1)
	st.generate_normals()
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


## Same shape with flat (per-face) normals: gems and rocks.
static func faceted(mesh: Mesh) -> ArrayMesh:
	var key := "facet|%d" % mesh.get_instance_id()
	if _cache.has(key):
		return _cache[key]
	var arr := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var ouv := PackedVector2Array()
	var oi := PackedInt32Array()
	for k in range(0, ind.size(), 3):
		var a := v[ind[k]]
		var b := v[ind[k + 1]]
		var c := v[ind[k + 2]]
		var n := (c - a).cross(b - a)
		if n.length_squared() < 1e-12:
			continue
		n = n.normalized()
		for j in 3:
			oi.append(ov.size())
			ov.append(v[ind[k + j]])
			on.append(n)
			ouv.append(uv[ind[k + j]] if uv.size() > 0 else Vector2.ZERO)
	var out := _arrays_mesh(ov, on, ouv, oi)
	_cache[key] = out
	return out


static func _arrays_mesh(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array, idx: PackedInt32Array) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## Bakes static parts (mesh + material + transform) into one ArrayMesh with
## a surface per material.
class Merger:
	var _mats: Array[Material] = []
	var _v: Array[PackedVector3Array] = []
	var _n: Array[PackedVector3Array] = []
	var _uv: Array[PackedVector2Array] = []
	var _i: Array[PackedInt32Array] = []

	func add(mesh: Mesh, mat: Material, xf: Transform3D) -> void:
		var slot := _mats.find(mat)
		if slot < 0:
			slot = _mats.size()
			_mats.append(mat)
			_v.append(PackedVector3Array())
			_n.append(PackedVector3Array())
			_uv.append(PackedVector2Array())
			_i.append(PackedInt32Array())
		var nb := Transform3D(xf.basis.inverse().transposed(), Vector3.ZERO)
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			var ind: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var base := _v[slot].size()
			_v[slot].append_array(xf * v)
			var tn := nb * n
			for k in tn.size():
				tn[k] = tn[k].normalized()
			_n[slot].append_array(tn)
			if uv.size() == v.size():
				_uv[slot].append_array(uv)
			else:
				var z := PackedVector2Array()
				z.resize(v.size())
				_uv[slot].append_array(z)
			var flip := xf.basis.determinant() < 0.0
			if ind.is_empty():
				for k in range(0, v.size(), 3):
					if flip:
						_i[slot].append_array([base + k, base + k + 2, base + k + 1])
					else:
						_i[slot].append_array([base + k, base + k + 1, base + k + 2])
			else:
				for k in range(0, ind.size(), 3):
					if flip:
						_i[slot].append_array([base + ind[k], base + ind[k + 2], base + ind[k + 1]])
					else:
						_i[slot].append_array([base + ind[k], base + ind[k + 1], base + ind[k + 2]])

	func empty() -> bool:
		return _mats.is_empty()

	func commit() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		for s in _mats.size():
			var arr := []
			arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = _v[s]
			arr[Mesh.ARRAY_NORMAL] = _n[s]
			arr[Mesh.ARRAY_TEX_UV] = _uv[s]
			arr[Mesh.ARRAY_INDEX] = _i[s]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			mesh.surface_set_material(s, _mats[s])
		return mesh
