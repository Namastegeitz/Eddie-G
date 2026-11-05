class_name Models3D
extends RefCounted
## Detailed first-person models for the things you meet most: logs (bark
## grooves, knots, broken branch stubs, moss, ringed ends), caimans and
## crocodiles (armoured scutes, long snouts, raised eyes, nostrils, teeth),
## and giant red soldier ants hauling wedges of cheese. Built from simple
## shapes with vertex colours into one mesh each, cached per hazard and
## size, so a lane full of them still draws cheaply.
## Axes: x along the lane (+x = the way it faces / moves), y up, z across.

static var _cache := {}
static var _gloss: StandardMaterial3D
static var _matte: StandardMaterial3D


static func gloss() -> StandardMaterial3D:
	if _gloss == null:
		_gloss = StandardMaterial3D.new()
		_gloss.vertex_color_use_as_albedo = true
		_gloss.vertex_color_is_srgb = true
		_gloss.roughness = 0.32
		_gloss.metallic_specular = 0.7
		_gloss.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _gloss


static func matte() -> StandardMaterial3D:
	if _matte == null:
		_matte = StandardMaterial3D.new()
		_matte.vertex_color_use_as_albedo = true
		_matte.vertex_color_is_srgb = true
		_matte.roughness = 0.9
		_matte.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _matte


static func _mi(mesh: Mesh, mat: Material, parent: Node3D, name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if name != "":
		mi.name = name
	parent.add_child(mi)
	return mi


static func _seg() -> int:
	return 14 if Draw.detail > 1 else (10 if Draw.detail == 1 else 7)


## A tube along a path whose radius changes point by point. `flat` squashes
## the cross-section's height (crocodile bodies are wide and low); colours
## go from `belly` underneath to `top` on the back, and `groove` darkens
## stripes along it (bark).
static func body(k: Scenery3D.Kit, pts: PackedVector3Array, radii: PackedFloat32Array, flat: float, top: Color, belly: Color, seg: int, groove := 0.0, salt := 0.0) -> void:
	var base := k.v.size()
	for i in pts.size():
		var d := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var side := d.cross(Vector3.UP).normalized()
		if side.length() < 0.5:
			side = Vector3.BACK
		var up := side.cross(d).normalized()
		for j in seg + 1:
			var a := TAU * j / seg
			var ca := cos(a)
			var sa := sin(a)
			var g := 1.0
			if groove > 0.0:
				g = 1.0 - groove * (0.5 + 0.5 * sin(a * 9.0 + sin(i * 1.7 + salt) * 0.8)) * (0.6 + 0.4 * sin(i * 3.1 + j + salt))
			var off := side * ca * radii[i] * g + up * sa * radii[i] * flat * g
			var c := belly.lerp(top, clampf(sa * 0.5 + 0.5, 0.0, 1.0))
			if groove > 0.0:
				c = c.darkened((1.0 - g) * 2.2)
			k._add(pts[i] + off, (side * ca + up * sa / maxf(flat, 0.2)).normalized(), c)
	for i in pts.size() - 1:
		for j in seg:
			var a0 := base + i * (seg + 1) + j
			var b0 := base + (i + 1) * (seg + 1) + j
			k.quad(a0, b0, b0 + 1, a0 + 1)


## A flat ring of colour facing along `normal` (log end grain).
static func ring(k: Scenery3D.Kit, c: Vector3, normal: Vector3, r0: float, r1: float, col: Color, seg: int) -> void:
	var side := normal.cross(Vector3.UP).normalized()
	if side.length() < 0.5:
		side = Vector3.BACK
	var up := side.cross(normal).normalized()
	var base := k.v.size()
	for j in seg + 1:
		var a := TAU * j / seg
		var dir := side * cos(a) + up * sin(a)
		k._add(c + dir * r0, normal, col)
		k._add(c + dir * r1, normal, col)
	for j in seg:
		var i := base + j * 2
		k.quad(i, i + 2, i + 3, i + 1)


# ====================================================================== logs

## A log lying along x, `L` long, centred on the origin. Floating logs sit
## low with moss on top; rolling logs are rounder and cleaner.
static func log_mesh(hid: String, L: float, cl: Dictionary, floating: bool) -> ArrayMesh:
	var key := "log:%s:%.2f" % [hid, L]
	if _cache.has(key):
		return _cache[key]
	var k := Scenery3D.Kit.new()
	var seg := _seg() + 4
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var bark := Color(String(cl.get("body", "#6a4a2a")))
	var ring_c := Color(String(cl.get("ring", "#c8a070")))
	var moss := Color(String(cl.get("moss", "#5a8a32")))
	var R := 0.3
	var n := 9
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in n:
		var f := float(i) / (n - 1)
		pts.append(Vector3(-L * 0.5 + f * L, sin(f * 2.4 + rng.randf()) * 0.012, sin(f * 1.9) * 0.02))
		radii.append(R * (1.04 - f * 0.1) * (0.96 + rng.randf() * 0.07))
	body(k, pts, radii, 0.97, bark.lightened(0.06), bark.darkened(0.25), seg, 0.22, rng.randf() * 10.0)
	# ends: bark rim, pale sapwood, ringed heartwood, dark pith, a crack or two
	for e in [0, n - 1]:
		var c: Vector3 = pts[e]
		var nrm := Vector3(-1, 0, 0) if e == 0 else Vector3(1, 0, 0)
		var r: float = radii[e]
		var face := c + nrm * 0.002
		ring(k, face, nrm, r * 0.86, r * 1.0, bark.darkened(0.35), seg)
		ring(k, face + nrm * 0.001, nrm, r * 0.7, r * 0.86, ring_c.lightened(0.12), seg)
		var rings := 4 if Draw.detail > 0 else 2
		for q in rings:
			var r_out := r * 0.7 * (1.0 - float(q) / rings)
			var r_in := r * 0.7 * (1.0 - float(q + 1) / rings)
			ring(k, face + nrm * (0.0015 + q * 0.0005), nrm, r_in, r_out, ring_c.darkened(0.05 + 0.12 * (q % 2)), seg)
		k.blob(Scenery3D.xf(face + nrm * 0.004), Vector3(0.004, r * 0.08, r * 0.08), ring_c.darkened(0.5), 6)
		for cr in 2:
			var a := rng.randf() * TAU
			k.box(Scenery3D.xf(face + nrm * 0.004 + Vector3(0, sin(a), cos(a)) * r * 0.35, 0.0, -a), Vector3(0.006, r * 0.55, 0.012), ring_c.darkened(0.45))
	# knots
	for i in (4 if Draw.detail > 0 else 2):
		var f2 := rng.randf_range(0.15, 0.85)
		var a2 := rng.randf_range(-1.2, 1.4)
		var p := Vector3(-L * 0.5 + f2 * L, 0, 0)
		var dir := Vector3(0, sin(a2), cos(a2))
		var rr := R * 0.95
		k.blob(Scenery3D.xf(p + dir * rr), Vector3(0.06, 0.045, 0.06) * (1.0 if i % 2 == 0 else 0.7), bark.darkened(0.45), 7)
		k.blob(Scenery3D.xf(p + dir * (rr + 0.01)), Vector3(0.03, 0.02, 0.03), ring_c.darkened(0.2), 6)
	# broken branch stubs
	for i in (2 if L > 1.6 else 1):
		var f3 := rng.randf_range(0.25, 0.75)
		var a3 := rng.randf_range(0.2, 1.1) * (1.0 if i % 2 == 0 else -1.0)
		var base3 := Vector3(-L * 0.5 + f3 * L, 0, 0)
		var dir3 := Vector3(rng.randf_range(-0.3, 0.3), sin(a3) + 0.3, cos(a3)).normalized()
		var tip := base3 + dir3 * (R + rng.randf_range(0.12, 0.22))
		k.tube(PackedVector3Array([base3 + dir3 * R * 0.8, tip]), 0.055, 0.04, bark, bark.lightened(0.05), 7)
		ring(k, tip, dir3, 0.0, 0.04, ring_c, 7)
	# moss and a few leaves on floating logs; bark flakes on rolling ones
	if floating:
		for i in (6 if Draw.detail > 0 else 3):
			var f4 := rng.randf_range(0.08, 0.92)
			var a4 := rng.randf_range(-0.6, 0.6)
			var mp := Vector3(-L * 0.5 + f4 * L, cos(a4) * R * 0.92, sin(a4) * R * 0.92)
			k.blob(Scenery3D.xf(mp, rng.randf() * TAU, 0.0, a4), Vector3(rng.randf_range(0.08, 0.16), 0.03, rng.randf_range(0.06, 0.12)), moss.darkened(rng.randf_range(0.0, 0.2)), 7, 0.4)
		if Draw.detail > 1:
			for i in 2:
				var lp := Vector3(rng.randf_range(-L * 0.4, L * 0.4), R * 0.97, rng.randf_range(-0.1, 0.1))
				k.blade(Scenery3D.xf(lp, rng.randf() * TAU), 0.14, 0.07, Color("8a7a3a"), Color("a8883a"), 0.0, 1)
	_cache[key] = k.mesh()
	return _cache[key]


# ====================================================================== caimans

## A caiman floating as a platform: only the armoured back, the top of the
## head and the eyes show above the water. Faces +x. Top at about y = 0.09.
static func caiman_back(hid: String, L: float, cl: Dictionary) -> ArrayMesh:
	var key := "caiman:%s:%.2f" % [hid, L]
	if _cache.has(key):
		return _cache[key]
	var k := Scenery3D.Kit.new()
	var seg := _seg()
	var hide := Color(String(cl.get("body", "#4a5a32")))
	var ridge := Color(String(cl.get("ridge", "#3a4a26")))
	var eye := Color(String(cl.get("eye", "#e8c83a")))
	var belly := hide.lightened(0.25).lerp(Color("c8c088"), 0.3)
	# body profile from tail tip (-x) to snout tip (+x)
	var prof := [[-0.5, 0.015], [-0.4, 0.06], [-0.26, 0.12], [-0.12, 0.2], [0.02, 0.25], [0.15, 0.24], [0.24, 0.18], [0.3, 0.16], [0.38, 0.13], [0.46, 0.085], [0.5, 0.04]]
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	for pr in prof:
		var x: float = float(pr[0]) * L
		pts.append(Vector3(x, -0.03 + float(pr[1]) * 0.2, 0.0))
		radii.append(float(pr[1]) * 1.15)
	body(k, pts, radii, 0.5, hide.lightened(0.08), belly, seg)
	# armour: rows of keeled scutes down the back, one crest down the tail
	var rows := [[-0.09, 0.04, 0.32], [-0.035, 0.0, 0.34], [0.035, 0.0, 0.34], [0.09, 0.04, 0.32]]
	for rw in rows:
		var zz := float(rw[0])
		for i in 9:
			var x2 := lerpf(-0.12, 0.22, i / 8.0) * L
			k.blob(Scenery3D.xf(Vector3(x2, 0.075 - float(rw[1]), zz * (1.0 + 0.6 * sin(i / 8.0 * PI)))), Vector3(0.035, 0.022, 0.022), ridge.darkened(0.1 * (i % 2)), 5)
	for i in 10:
		var x3 := lerpf(-0.48, -0.14, i / 9.0) * L
		var h := lerpf(0.02, 0.05, i / 9.0)
		for s in [-1.0, 1.0]:
			k.blob(Scenery3D.xf(Vector3(x3, 0.03 + h, s * lerpf(0.004, 0.03, i / 9.0))), Vector3(0.028, h * 0.6, 0.008), ridge, 4)
	# head: raised eyes with slit pupils, nostril bumps at the snout tip
	for s2 in [-1.0, 1.0]:
		var ep := Vector3(0.29 * L, 0.085, s2 * 0.07)
		k.blob(Scenery3D.xf(ep), Vector3(0.055, 0.04, 0.045), hide.darkened(0.1), 8)
		k.blob(Scenery3D.xf(ep + Vector3(0.01, 0.018, s2 * 0.01)), Vector3(0.032, 0.026, 0.028), eye, 8)
		k.blob(Scenery3D.xf(ep + Vector3(0.03, 0.024, s2 * 0.016)), Vector3(0.005, 0.018, 0.01), Color("111111"), 5)
		k.blob(Scenery3D.xf(Vector3(0.485 * L, 0.035, s2 * 0.014)), Vector3(0.016, 0.012, 0.012), hide.darkened(0.2), 5)
	# legs paddling just under the surface
	for lx in [-0.12, 0.16]:
		for s3 in [-1.0, 1.0]:
			var hip := Vector3(lx * L, -0.03, s3 * 0.17)
			k.tube(PackedVector3Array([hip, hip + Vector3(-0.04, -0.03, s3 * 0.1), hip + Vector3(0.02, -0.05, s3 * 0.16)]), 0.03, 0.02, hide.darkened(0.1), hide.darkened(0.2), 5)
	_cache[key] = k.mesh()
	return _cache[key]


## A crocodile's head bursting out of the water. Lower jaw in `head`, the
## upper jaw on a hinge node "Upper" at the back (rotated to snap). Span
## along x; snout towards +x.
static func croc_head(head: Node3D, span: float, cl: Dictionary) -> void:
	var hide := Color(String(cl.get("body", "#4a5a32")))
	var eye := Color(String(cl.get("eye", "#e8c83a")))
	var mouth := Color("c86a6a")
	var tooth := Color("f2ecd8")
	var seg := _seg()
	var lower := Scenery3D.Kit.new()
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in 7:
		var f := i / 6.0
		pts.append(Vector3(lerpf(-span * 0.5, span * 0.5, f), -0.02, 0))
		radii.append(lerpf(0.24, 0.07, f))
	body(lower, pts, radii, 0.3, hide.lightened(0.05), hide.lightened(0.3).lerp(Color("d8d0a0"), 0.4), seg)
	lower.blob(Scenery3D.xf(Vector3(0.05 * span, 0.04, 0)), Vector3(span * 0.4, 0.015, 0.14), mouth, seg)
	for i in 8:
		var f2 := (i + 0.5) / 8.0
		var tx := lerpf(-span * 0.3, span * 0.46, f2)
		var tz := lerpf(0.2, 0.06, f2)
		for s in [-1.0, 1.0]:
			lower.cylinder(Scenery3D.xf(Vector3(tx, 0.035, s * tz)), 0.014, 0.0, 0.05 + 0.02 * (i % 2), tooth, tooth.lightened(0.1), 5)
	_mi(lower.mesh(), gloss(), head, "Lower")
	var upper_node: Node3D = head.get_node("Upper")
	var up := Scenery3D.Kit.new()
	var pts2 := PackedVector3Array()
	var radii2 := PackedFloat32Array()
	for i in 8:
		var f3 := i / 7.0
		pts2.append(Vector3(f3 * span, 0.05 + sin(f3 * PI) * 0.02, 0))
		radii2.append(lerpf(0.26, 0.075, f3))
	body(up, pts2, radii2, 0.36, hide, hide.lightened(0.15), seg)
	up.blob(Scenery3D.xf(Vector3(span * 0.55, 0.0, 0)), Vector3(span * 0.4, 0.014, 0.13), mouth.darkened(0.1), seg)
	for i in 9:
		var f4 := (i + 0.5) / 9.0
		var tx2 := lerpf(span * 0.18, span * 0.97, f4)
		var tz2 := lerpf(0.21, 0.065, f4)
		for s2 in [-1.0, 1.0]:
			up.cylinder(Scenery3D.xf(Vector3(tx2, 0.02, s2 * tz2), 0.0, 0.0, PI), 0.015, 0.0, 0.055 + 0.025 * (i % 2), tooth, tooth.lightened(0.1), 5)
	for s3 in [-1.0, 1.0]:
		var ep := Vector3(span * 0.18, 0.15, s3 * 0.1)
		up.blob(Scenery3D.xf(ep), Vector3(0.06, 0.05, 0.05), hide.darkened(0.15), 8)
		up.blob(Scenery3D.xf(ep + Vector3(0.02, 0.02, s3 * 0.015)), Vector3(0.032, 0.028, 0.03), eye, 8)
		up.blob(Scenery3D.xf(ep + Vector3(0.045, 0.026, s3 * 0.02)), Vector3(0.005, 0.02, 0.012), Color("111111"), 5)
		up.blob(Scenery3D.xf(Vector3(span * 0.95, 0.1, s3 * 0.025)), Vector3(0.022, 0.018, 0.018), hide.darkened(0.25), 6)
	for i in 6:
		up.blob(Scenery3D.xf(Vector3(lerpf(-0.02, span * 0.12, i / 5.0), 0.14 + 0.01 * (i % 2), (i % 2 - 0.5) * 0.08)), Vector3(0.03, 0.02, 0.02), hide.darkened(0.25), 5)
	_mi(up.mesh(), gloss(), upper_node, "UpperJaw")


# ====================================================================== soldier ants

## A giant red soldier ant (about L long) hauling a wedge of cheese, as
## three meshes: body + cheese, and two sets of three legs ("LegsA",
## "LegsB") that swing in turn as it walks (WorldView3D animates them).
static func soldier_ant(root: Node3D, L: float, cl: Dictionary) -> void:
	var key := "ant:%.2f" % L
	if not _cache.has(key):
		var red := Color(String(cl.get("body", "#c8281e")))
		var dark := red.darkened(0.45)
		var cheese := Color(String(cl.get("cheese", "#f6c83a")))
		var s := L / 0.9
		var seg := _seg()
		var k := Scenery3D.Kit.new()
		# gaster (abdomen) with darker bands, petiole nodes, thorax, big head
		k.blob(Scenery3D.xf(Vector3(-0.27, 0.3, 0) * s, 0.0, 0.0, 0.25), Vector3(0.21, 0.16, 0.17) * s, red, seg)
		for b in 3:
			k.cylinder(Scenery3D.xf(Vector3(-0.2 - b * 0.07, 0.3 + b * 0.012, 0) * s, 0.0, 0.0, PI * 0.5 + 0.25), (0.165 - b * 0.03) * s, (0.165 - b * 0.03) * s, 0.012 * s, dark, dark, seg)
		k.blob(Scenery3D.xf(Vector3(-0.08, 0.3, 0) * s), Vector3(0.045, 0.05, 0.04) * s, red.darkened(0.15), 7)
		k.blob(Scenery3D.xf(Vector3(-0.02, 0.31, 0) * s), Vector3(0.04, 0.045, 0.04) * s, red.darkened(0.15), 7)
		k.blob(Scenery3D.xf(Vector3(0.09, 0.33, 0) * s, 0.0, 0.0, -0.2), Vector3(0.13, 0.075, 0.075) * s, red.darkened(0.05), seg)
		k.blob(Scenery3D.xf(Vector3(0.29, 0.38, 0) * s), Vector3(0.12, 0.11, 0.135) * s, red.darkened(0.08), seg)
		# eyes, mandibles, elbowed antennae
		for side in [-1.0, 1.0]:
			k.blob(Scenery3D.xf(Vector3(0.33, 0.42, side * 0.105) * s), Vector3(0.025, 0.03, 0.02) * s, Color("140a08"), 7)
			var mb := Vector3(0.39, 0.33, side * 0.06) * s
			k.tube(PackedVector3Array([mb, mb + Vector3(0.09, 0.0, side * 0.035) * s, mb + Vector3(0.17, -0.01, side * 0.01) * s, mb + Vector3(0.2, -0.02, -side * 0.045) * s]), 0.032 * s, 0.006 * s, dark, dark.darkened(0.3), 7)
			var ab := Vector3(0.36, 0.46, side * 0.05) * s
			k.tube(PackedVector3Array([ab, ab + Vector3(0.04, 0.14, side * 0.06) * s, ab + Vector3(0.16, 0.16, side * 0.12) * s]), 0.01 * s, 0.006 * s, dark, dark, 5)
		# the cheese: a wedge with a rind and holes, held up over the head
		var cx := Scenery3D.xf(Vector3(0.3, 0.47, 0) * s, 0.2, 0.0, -0.12)
		var w := 0.34 * s
		var tri := [Vector3(-w * 0.7, 0, -w * 0.5), Vector3(-w * 0.7, 0, w * 0.5), Vector3(w * 0.8, 0, 0)]
		var hgt := 0.15 * s
		for i in 3:
			var a: Vector3 = tri[i]
			var b2: Vector3 = tri[(i + 1) % 3]
			var nrm := (cx.basis * (b2 - a).cross(Vector3.UP)).normalized() * -1.0
			var sc := cheese.darkened(0.08) if i != 0 else cheese.darkened(0.25).lerp(Color("d88a2a"), 0.4)
			var i0 := k._add(cx * a, nrm, sc)
			var i1 := k._add(cx * b2, nrm, sc)
			var i2 := k._add(cx * (b2 + Vector3(0, hgt, 0)), nrm, sc)
			var i3 := k._add(cx * (a + Vector3(0, hgt, 0)), nrm, sc)
			k.quad(i0, i1, i2, i3)
		for ylev in [0.0, hgt]:
			var nn := (cx.basis * (Vector3.UP if ylev > 0.0 else Vector3.DOWN)).normalized()
			var t0 := k._add(cx * (tri[0] + Vector3(0, ylev, 0)), nn, cheese.lightened(0.06))
			var t1 := k._add(cx * (tri[1] + Vector3(0, ylev, 0)), nn, cheese.lightened(0.06))
			var t2 := k._add(cx * (tri[2] + Vector3(0, ylev, 0)), nn, cheese.lightened(0.06))
			k.idx.append_array(PackedInt32Array([t0, t1, t2]))
		for hp in [Vector2(-0.05, 0.04), Vector2(0.06, -0.015), Vector2(-0.13, -0.07), Vector2(-0.14, 0.08)]:
			k.blob(Scenery3D.xf(cx * Vector3(hp.x * s, hgt + 0.002, hp.y * s)), Vector3(0.026, 0.008, 0.026) * s, cheese.darkened(0.35), 7)
		var legs := []
		for half in 2:
			var lk := Scenery3D.Kit.new()
			for li in 3:
				for side2 in [-1.0, 1.0]:
					if (li + (1 if side2 > 0.0 else 0)) % 2 != half:
						continue
					var hip := Vector3(0.05 + (li - 1) * 0.07, 0.0, side2 * 0.05) * s
					var knee := hip + Vector3((li - 1) * 0.11, 0.07, side2 * 0.17) * s
					var foot := knee + Vector3((li - 1) * 0.09, -0.37, side2 * 0.09) * s
					var mid := hip.lerp(knee, 0.5) + Vector3(0, 0.02, 0) * s
					lk.tube(PackedVector3Array([hip, mid, knee, knee.lerp(foot, 0.5), foot]), 0.034 * s, 0.014 * s, dark, dark.darkened(0.3), 6)
					lk.blob(Scenery3D.xf(knee), Vector3(0.03, 0.03, 0.03) * s, dark, 6)
			legs.append(lk.mesh())
		_cache[key] = [k.mesh(), legs[0], legs[1]]
	var parts: Array = _cache[key]
	_mi(parts[0], gloss(), root, "Body")
	for i in 2:
		var hipn := Node3D.new()
		hipn.name = "LegsA" if i == 0 else "LegsB"
		hipn.position = Vector3(0.05, 0.31, 0) * (L / 0.9)
		root.add_child(hipn)
		_mi(parts[1 + i], gloss(), hipn)
	root.set_meta("walk", true)
