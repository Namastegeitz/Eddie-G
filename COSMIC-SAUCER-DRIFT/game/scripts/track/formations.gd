class_name Formations
extends RefCounted
## Procedural volcanic rock formations for the biomes (the fallback when no
## Meshy mesh sits in a formation's import slot). Every mesh is low-poly and
## flat shaded, in "unit" space: base at y = 0, top at y = 1, footprint
## radius about 1. The biome scales each instance to its size in metres.
##
## make(recipe, detail): detail 2 = near LOD, 0 = far LOD.
## Recipe types: ridge, cone, columns, shard, crystals, arch.


static func make(recipe: Dictionary, detail: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(recipe.get("seed", 1))
	var noise := FastNoiseLite.new()
	noise.seed = int(recipe.get("seed", 1))
	noise.frequency = 1.0
	var tris := PackedVector3Array()
	match String(recipe.get("type", "cone")):
		"ridge":
			tris = _ridge(recipe, detail, rng, noise)
		"columns":
			tris = _columns(recipe, detail, rng, false)
		"crystals":
			tris = _columns(recipe, detail, rng, true)
		"shard":
			tris = _shard(recipe, detail, rng, noise)
		"arch":
			tris = _arch(recipe, detail, rng, noise)
		_:
			tris = _cone(recipe, detail, rng, noise)
	return _commit(_normalise(tris))


## Triangles (3 points each) -> flat-shaded mesh.
static func _commit(tris: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in range(0, tris.size(), 3):
		var a := tris[i]
		var b := tris[i + 1]
		var c := tris[i + 2]
		if (b - a).cross(c - a).length_squared() < 1e-12:
			continue
		for p: Vector3 in [a, b, c]:
			st.set_uv(Vector2(p.x + p.z, p.y))
			st.add_vertex(p)
	st.generate_normals()
	return st.commit()


## Base to y = 0, top to y = 1, widest footprint to radius 1.
static func _normalise(tris: PackedVector3Array) -> PackedVector3Array:
	if tris.is_empty():
		return tris
	var ymin := INF
	var ymax := -INF
	var rmax := 0.0
	for p in tris:
		ymin = minf(ymin, p.y)
		ymax = maxf(ymax, p.y)
		rmax = maxf(rmax, Vector2(p.x, p.z).length())
	var hy := maxf(ymax - maxf(ymin, -0.05 * (ymax - ymin)), 0.001)
	var out := PackedVector3Array()
	out.resize(tris.size())
	for i in tris.size():
		var p := tris[i]
		out[i] = Vector3(p.x / rmax, (p.y - maxf(ymin, -0.05 * (ymax - ymin))) / hy, p.z / rmax)
	return out


static func _quad(out: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	# a-b-c-d clockwise seen from outside (Godot's front faces, as MeshKit).
	out.append_array([a, b, c, a, c, d])


## A long jagged mountain ridge along X with a few peaks.
static func _ridge(rc: Dictionary, detail: int, rng: RandomNumberGenerator, noise: FastNoiseLite) -> PackedVector3Array:
	var nx := 72 if detail >= 2 else (40 if detail == 1 else 26)
	var nz := 14 if detail >= 2 else (8 if detail == 1 else 6)
	var zw := 0.32
	var sharp := float(rc.get("sharp", 1.5))
	var jag := float(rc.get("jag", 0.5))
	var peaks: Array = []
	for k in int(rc.get("peaks", 5)):
		peaks.append(Vector3(rng.randf_range(-0.85, 0.85), rng.randf_range(0.55, 1.0), rng.randf_range(0.1, 0.28)))
	var grid: Array = []
	for i in nx + 1:
		var x := lerpf(-1.0, 1.0, float(i) / nx)
		var prof := 0.3 * (1.0 - x * x)
		for pk: Vector3 in peaks:
			var t := (x - pk.x) / pk.z
			prof = maxf(prof, pk.y * exp(-t * t * sharp))
		prof *= 1.0 - pow(absf(x), 6.0)
		var row: Array = []
		for j in nz + 1:
			var zf := lerpf(-1.0, 1.0, float(j) / nz)
			var cross := maxf(0.0, 1.0 - pow(absf(zf), 1.5))
			var rn := 1.0 - absf(noise.get_noise_2d(x * 5.0, zf * 2.5))
			var y := prof * cross * (1.0 - jag * 0.5 + jag * rn * 0.9) - 0.03
			var z := zf * zw * (1.0 + 0.25 * noise.get_noise_2d(x * 3.0, 40.0)) + 0.06 * noise.get_noise_2d(x * 4.0, zf * 3.0)
			row.append(Vector3(x, y, z))
		grid.append(row)
	var out := PackedVector3Array()
	for i in nx:
		for j in nz:
			var a: Vector3 = grid[i][j]
			var b: Vector3 = grid[i + 1][j]
			var c: Vector3 = grid[i + 1][j + 1]
			var d: Vector3 = grid[i][j + 1]
			_quad(out, a, b, c, d)
	return out


## Volcano: concave flanks with ribs and gullies, a crater rim and floor.
static func _cone(rc: Dictionary, detail: int, rng: RandomNumberGenerator, noise: FastNoiseLite) -> PackedVector3Array:
	var na := 44 if detail >= 2 else (26 if detail == 1 else 16)
	var nr := 14 if detail >= 2 else (8 if detail == 1 else 5)
	var crater := float(rc.get("crater", 0.22))
	var ribs := float(rc.get("ribs", 9))
	var rough := float(rc.get("rough", 0.08))
	var rings: Array = []
	for r in nr + 1:
		var t := float(r) / nr
		var rad := 1.0 - (1.0 - crater) * pow(t, 0.55)
		var ring: Array = []
		for a in na:
			var ang := TAU * float(a) / na
			var rib := sin(ang * ribs + noise.get_noise_2d(ang * 2.0, t * 3.0) * 2.0) * 0.07 * (1.0 - t)
			var n := noise.get_noise_2d(cos(ang) * 3.0 + t * 4.0, sin(ang) * 3.0) * rough
			var rr := rad * (1.0 + rib + n)
			ring.append(Vector3(cos(ang) * rr, t + n * 0.3 * (1.0 - t), sin(ang) * rr))
		rings.append(ring)
	# Crater: rim drops to a floor.
	var inner: Array = []
	for a in na:
		var ang := TAU * float(a) / na
		inner.append(Vector3(cos(ang) * crater * 0.72, 0.93, sin(ang) * crater * 0.72))
	rings.append(inner)
	var out := PackedVector3Array()
	for r in rings.size() - 1:
		for a in na:
			var b := (a + 1) % na
			_quad(out, rings[r][a], rings[r][b], rings[r + 1][b], rings[r + 1][a])
	var floor_c := Vector3(0, 0.9, 0)
	for a in na:
		out.append_array([floor_c, inner[a], inner[(a + 1) % na]])
	return out


## Cluster of hexagonal prisms: basalt columns, or (crystal) tilted prisms
## with pointed tips on a low rock mound.
static func _columns(rc: Dictionary, detail: int, rng: RandomNumberGenerator, crystal: bool) -> PackedVector3Array:
	var n := int(rc.get("count", 12))
	if detail == 0:
		n = maxi(4, int(n * 0.6))
	var out := PackedVector3Array()
	var golden := PI * (3.0 - sqrt(5.0))
	for k in n:
		var d := 0.82 * sqrt((float(k) + 0.5) / n)
		var a := float(k) * golden + rng.randf_range(-0.2, 0.2)
		var c := Vector3(cos(a) * d, 0.0, sin(a) * d)
		var rad := rng.randf_range(0.13, 0.2) if not crystal else rng.randf_range(0.1, 0.17)
		var h := (0.35 + 0.65 * (1.0 - d / 0.9)) * rng.randf_range(0.7, 1.0)
		var axis := Vector3.UP
		if crystal:
			axis = (Vector3.UP + Vector3(c.x, 0, c.z) * rng.randf_range(0.6, 1.4)).normalized()
		var side := axis.cross(Vector3.FORWARD if absf(axis.z) < 0.9 else Vector3.RIGHT).normalized()
		var fwd := axis.cross(side).normalized()
		var tilt := rng.randf_range(-0.12, 0.12)
		var base: Array = []
		var top: Array = []
		var rot := rng.randf() * TAU
		for s in 6:
			var ang := rot + TAU * float(s) / 6.0
			var off := (side * cos(ang) + fwd * sin(ang)) * rad
			base.append(c + off - axis * 0.1)
			top.append(c + off + axis * h + Vector3.UP * (tilt * off.x * 3.0 if not crystal else 0.0))
		for s in 6:
			var t := (s + 1) % 6
			_quad(out, base[s], top[s], top[t], base[t])
		var tip := c + axis * (h + (0.22 * h if crystal else 0.0))
		for s in 6:
			out.append_array([top[(s + 1) % 6], top[s], tip])
	if crystal:
		# A low rough mound the crystals grow from.
		var mound := _cone({"crater": 0.0, "ribs": 5, "rough": 0.15}, maxi(detail - 1, 0), rng, FastNoiseLite.new())
		for p in mound:
			out.append(Vector3(p.x * 0.95, p.y * 0.18 - 0.02, p.z * 0.95))
	return out


## A tall leaning obsidian spire with two smaller shards at its foot.
static func _shard(rc: Dictionary, detail: int, rng: RandomNumberGenerator, noise: FastNoiseLite) -> PackedVector3Array:
	var out := PackedVector3Array()
	var lean := deg_to_rad(float(rc.get("lean", 12)))
	for s in 3:
		var scale := 1.0 if s == 0 else rng.randf_range(0.35, 0.55)
		var base := Vector3.ZERO if s == 0 else Vector3(cos(s * 2.3), 0, sin(s * 2.3)) * 0.55
		var sides := 5
		var segs := 6 if detail >= 2 else 3
		var dir := Vector3(sin(lean) * (1.0 if s != 2 else -1.0), cos(lean), 0.0).rotated(Vector3.UP, rng.randf() * TAU)
		var prev: Array = []
		for g in segs + 1:
			var t := float(g) / segs
			var rad := 0.42 * pow(1.0 - t, 0.85) * scale + 0.002
			var ring: Array = []
			for k in sides:
				var ang := TAU * float(k) / sides + t * 0.6
				var j := 1.0 + noise.get_noise_2d(float(k) * 3.0 + s * 10.0, t * 4.0) * 0.3
				ring.append(base + dir * t * scale + Vector3(cos(ang), 0, sin(ang)) * rad * j)
			if g > 0:
				for k in sides:
					var nk := (k + 1) % sides
					_quad(out, prev[k], prev[nk], ring[nk], ring[k])
			prev = ring
	return out


## A natural stone arch: a lumpy tube bent over a half circle.
static func _arch(rc: Dictionary, detail: int, rng: RandomNumberGenerator, noise: FastNoiseLite) -> PackedVector3Array:
	var out := PackedVector3Array()
	var thick := float(rc.get("thick", 0.22))
	var segs := 20 if detail >= 2 else 10
	var sides := 7 if detail >= 2 else 5
	var rings: Array = []
	for g in segs + 1:
		var t := float(g) / segs
		var ang := PI * t
		var ctr := Vector3(-cos(ang) * 0.75, sin(ang) * 0.95 - 0.08, 0.0)
		var tan := Vector3(sin(ang) * 0.75, cos(ang) * 0.95, 0.0).normalized()
		var nrm := Vector3(0, 0, 1)
		var bin := tan.cross(nrm).normalized()
		var rad := thick * (1.0 + 0.35 * (1.0 - sin(ang))) * (1.0 + noise.get_noise_2d(t * 6.0, 3.0) * 0.25)
		var ring: Array = []
		for k in sides:
			var a := TAU * float(k) / sides
			var j := 1.0 + noise.get_noise_2d(float(k) * 2.0, t * 8.0) * 0.18
			ring.append(ctr + (bin * cos(a) + nrm * sin(a)) * rad * j)
		rings.append(ring)
	for g in segs:
		for k in sides:
			var nk := (k + 1) % sides
			_quad(out, rings[g][k], rings[g][nk], rings[g + 1][nk], rings[g + 1][k])
	return out
