class_name SmoothMesh
## Smooth, seamless shapes for the characters, built as ArrayMeshes:
##   lathe()  - a body of revolution with an elliptical cross-section that
##              changes along its length (a torso, a dog's barrel, a neck).
##   limb()   - a tapered capsule whose two rounded ends are centred exactly
##              on the joints it spans, so the next limb (with the same
##              radius there) meets it in a smooth ball joint at any angle.
##   toned()  - a copy of any mesh with soft shading baked into its vertex
##              colours (undersides a little darker), so parts blend into
##              each other instead of meeting at hard seams.
## Normals are analytic and the seam column shares its normals, so nothing
## shows a crease.


## rings: [t, rx, rz] or [t, rx, rz, ox, oz] or [t, rx, rz, ox, oz, tone],
## from one end to the other (t increasing). A ring with rx = rz = 0 closes
## that end to a point. Built along +Y; tone (default 1) darkens that ring.
static func lathe(rings: Array, segments: int = 18) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var n := rings.size()
	var t0: float = rings[0][0]
	var t1: float = rings[n - 1][0]
	for i in n:
		var r: Array = rings[i]
		var t: float = r[0]
		var rx: float = r[1]
		var rz: float = r[2]
		var ox: float = r[3] if r.size() > 3 else 0.0
		var oz: float = r[4] if r.size() > 4 else 0.0
		var tone: float = r[5] if r.size() > 5 else 1.0
		# Slope of the radii along t (for the normals): central differences.
		var ia := maxi(i - 1, 0)
		var ib := mini(i + 1, n - 1)
		var dt: float = float(rings[ib][0]) - float(rings[ia][0])
		var drx := (float(rings[ib][1]) - float(rings[ia][1])) / dt if dt > 0.0001 else 0.0
		var drz := (float(rings[ib][2]) - float(rings[ia][2])) / dt if dt > 0.0001 else 0.0
		var dox := (float(rings[ib][3] if rings[ib].size() > 3 else 0.0) - float(rings[ia][3] if rings[ia].size() > 3 else 0.0)) / dt if dt > 0.0001 else 0.0
		var doz := (float(rings[ib][4] if rings[ib].size() > 4 else 0.0) - float(rings[ia][4] if rings[ia].size() > 4 else 0.0)) / dt if dt > 0.0001 else 0.0
		for j in segments + 1:
			var a := TAU * j / segments
			var c := cos(a)
			var s := sin(a)
			verts.append(Vector3(ox + rx * c, t, oz + rz * s))
			var nrm: Vector3
			if rx < 0.0001 and rz < 0.0001:
				nrm = Vector3(0, -1 if i == 0 else 1, 0)
			else:
				# Tangent round the ring and along the length; their cross is the normal.
				var ta := Vector3(-rx * s, 0, rz * c)
				var tt := Vector3(dox + drx * c, 1, doz + drz * s)
				nrm = ta.cross(tt).normalized()
				if nrm.dot(Vector3(c * rz, 0, s * rx)) < 0.0:
					nrm = -nrm
			norms.append(nrm)
			uvs.append(Vector2(float(j) / segments, (t - t0) / maxf(t1 - t0, 0.0001)))
			cols.append(Color(tone, tone, tone))
	var w := segments + 1
	for i in n - 1:
		for j in segments:
			var a0 := i * w + j
			var b0 := a0 + 1
			var a1 := a0 + w
			var b1 := a1 + 1
			idx.append_array([a0, b0, a1, b0, b1, a1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## A tapered capsule along +Y: its -Y end is a hemisphere of radius ra
## centred at y = -length / 2, its +Y end one of radius rb at +length / 2.
## sx/sz squash the shaft's cross-section (1 = round); the two rounded ends
## stay true spheres, so where a limb meets the next one (built with the same
## radius there, its end centred on the same joint) the two ends are one and
## the same ball at any bend angle: the joint reads as one smooth piece with
## no step, seam or flicker. crease darkens the very tips a touch (only the
## free ends, such as fingertips, show it; near the joint the tone is even).
static func limb(ra: float, rb: float, length: float, segments: int = 14, cap_rings: int = 4,
		sx: float = 1.0, sz: float = 1.0, crease: float = 0.92) -> ArrayMesh:
	var rings: Array = []
	var ya := -length * 0.5
	var yb := length * 0.5
	for k in cap_rings + 1:
		var phi := -PI * 0.5 + PI * 0.5 * k / cap_rings
		var r := ra * cos(phi)
		var t := 1.0 - float(k) / cap_rings
		rings.append([ya + ra * sin(phi), r, r, 0.0, 0.0, lerpf(1.0, crease, t * t)])
	# Two rings along the shaft keep the taper smooth when it's stretched; the
	# squash eases in from the round ends.
	for f: float in [0.33, 0.66]:
		var r2 := lerpf(ra, rb, f)
		var q := sin(f * PI)
		rings.append([lerpf(ya, yb, f), r2 * lerpf(1.0, sx, q), r2 * lerpf(1.0, sz, q), 0.0, 0.0, 1.0])
	for k in cap_rings + 1:
		var phi := PI * 0.5 * k / cap_rings
		var r := rb * cos(phi)
		var t := float(k) / cap_rings
		rings.append([yb + rb * sin(phi), r, r, 0.0, 0.0, lerpf(1.0, crease, t * t)])
	return lathe(rings, segments)


## A copy of `m` with soft shading baked into its vertex colours: faces that
## point down (in the space `basis` puts them in) are darker, the way the
## underside of an arm or a belly catches less light. Existing vertex
## colours are multiplied in.
static func toned(m: Mesh, basis: Basis, low: float = 0.8, high: float = 1.0) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in m.get_surface_count():
		var arrays := m.surface_get_arrays(s)
		var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var count := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var src: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var cols := PackedColorArray()
		cols.resize(count)
		var nb := basis.inverse().transposed()
		for i in count:
			var n := (nb * norms[i]).normalized() if i < norms.size() else Vector3.UP
			var k := lerpf(low, high, clampf(n.y * 0.5 + 0.5, 0.0, 1.0))
			var c := src[i] if i < src.size() else Color.WHITE
			cols[i] = Color(c.r * k, c.g * k, c.b * k, c.a)
		arrays[Mesh.ARRAY_COLOR] = cols
		# Tangents and the like aren't needed (triplanar detail maps).
		arrays[Mesh.ARRAY_TANGENT] = null
		var prim := (m as ArrayMesh).surface_get_primitive_type(s) if m is ArrayMesh else Mesh.PRIMITIVE_TRIANGLES
		out.add_surface_from_arrays(prim, arrays)
	return out


## The transform that puts a limb() mesh between joint points a and b.
static func between(a: Vector3, b: Vector3) -> Transform3D:
	var y := b - a
	var length := y.length()
	if length < 0.0001:
		return Transform3D(Basis.IDENTITY, a)
	y /= length
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x, y, z), (a + b) * 0.5)
