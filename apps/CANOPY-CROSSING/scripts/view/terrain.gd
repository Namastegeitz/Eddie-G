class_name Terrain
extends RefCounted
## High-definition terrain for the bird's-eye view, shared by every map.
##
## Ground and water are shaded per pixel (assets/shaders/ground.gdshader and
## water.gdshader) from two small noise textures built here. On top of that
## each row gets one mesh of plants, stones, fallen leaves and bank dressing
## (`lane_decor`): hundreds of shapes, a single draw call.
##
## `style(map)` reads how wet, mossy and dry a jungle is from its
## "atmosphere" (or an optional "terrain" block in the map file), so each
## map's floor looks like its own: puddles in the Chocó, moss in Monteverde,
## cracked red earth in Masoala.

static var _soft: ImageTexture
static var _fine: ImageTexture
static var _ground: Shader
## Built dressing and roof meshes, reused: rows that share a look (one of
## eight variants, the same obstacles and neighbours) cost nothing after the
## first, so scrolling never stalls on a slow phone.
static var _cache := {}


static func _cached(key: String, build: Callable) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	if _cache.size() > 240:
		_cache.clear()
	var m: ArrayMesh = build.call()
	_cache[key] = m
	return m


## Smooth, cloudy noise: patches of tone, canopy shade, swells on water.
static func soft() -> Texture2D:
	if _soft == null:
		var n := FastNoiseLite.new()
		n.seed = 3
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.018
		n.fractal_octaves = 4
		n.fractal_gain = 0.55
		_soft = _texture(n, 256)
	return _soft


## Fine, crisp noise: grass blades, grit, ripples, the ragged edge of a row.
static func fine() -> Texture2D:
	if _fine == null:
		var n := FastNoiseLite.new()
		n.seed = 19
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 0.11
		n.fractal_octaves = 2
		n.fractal_gain = 0.6
		_fine = _texture(n, 256)
	return _fine


static func _texture(n: FastNoiseLite, size: int) -> ImageTexture:
	var img := n.get_seamless_image(size, size)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func ground_shader() -> Shader:
	if _ground == null:
		_ground = load("res://assets/shaders/ground.gdshader")
	return _ground


## How this jungle's floor looks: {wet, moss, dry, dapple} from 0 to 1.
static func style(map: Dictionary) -> Dictionary:
	var atm: Dictionary = map.get("atmosphere", {})
	var swamp := 0.35 if String(map.get("generator", "")) == "wetlands" else 0.0
	var st := {
		"wet": clampf(float(atm.get("rain", 0.0)) * 1.2 + float(atm.get("steam", 0.0)) * 0.5 + swamp, 0.0, 1.0),
		"moss": clampf(float(atm.get("mist", 0.0)) * 1.5, 0.0, 1.0),
		"dry": clampf(float(atm.get("dust", 0.0)) * 2.2, 0.0, 1.0),
		"dapple": clampf(0.45 + float(atm.get("light_shafts", 0.0)) * 0.7, 0.0, 1.0),
	}
	var over: Dictionary = map.get("terrain", {})
	for k in over:
		st[k] = float(over[k])
	return st


## Flower colours for a map: its accent, white, and the blooms of its
## first-person scenes.
static func flowers(map: Dictionary) -> Array:
	var pal: Dictionary = map.get("palette", {})
	var out := [Color(String(pal.get("accent", "#f6d43a"))), Color("fbf7ee")]
	for sc in map.get("fpv_scenes", []):
		var fc := String(sc.get("colors", {}).get("flower", ""))
		if fc != "" and out.size() < 5:
			out.append(Color(fc))
	return out


# ====================================================================== 2D mesh kit

## Collects coloured triangles (plants, stones, leaves) and becomes one mesh,
## so a row's dressing is a single draw call however much there is of it.
class Kit2:
	var v := PackedVector2Array()
	var c := PackedColorArray()
	var idx := PackedInt32Array()

	func empty() -> bool:
		return v.is_empty()

	func tri(a: Vector2, b: Vector2, d: Vector2, ca: Color, cb: Color, cd: Color) -> void:
		var k := v.size()
		v.append(a)
		v.append(b)
		v.append(d)
		c.append(ca)
		c.append(cb)
		c.append(cd)
		idx.append(k)
		idx.append(k + 1)
		idx.append(k + 2)

	## A filled ellipse; `rim` (if given) fades the colour towards the edge,
	## which makes soft shadows (rim alpha 0) and rounded shading.
	func ellipse(ctr: Vector2, rx: float, ry: float, col: Color, rot := 0.0, n := 10, rim := Color(0, 0, 0, -1.0), off := Vector2.ZERO) -> void:
		var k := v.size()
		var rc := col if rim.a < 0.0 else rim
		v.append(ctr + off)
		c.append(col)
		var cr := cos(rot)
		var sr := sin(rot)
		for i in n:
			var a := TAU * i / n
			var p := Vector2(cos(a) * rx, sin(a) * ry)
			v.append(ctr + Vector2(p.x * cr - p.y * sr, p.x * sr + p.y * cr))
			c.append(rc)
		for i in n:
			idx.append(k)
			idx.append(k + 1 + i)
			idx.append(k + 1 + (i + 1) % n)

	## A tapering blade of grass from `base` to `tip`.
	func blade(base: Vector2, tip: Vector2, w: float, c0: Color, c1: Color) -> void:
		var d := tip - base
		if d.length_squared() < 0.01:
			return
		var side := Vector2(-d.y, d.x).normalized() * w * 0.5
		var mid := base + d * 0.55 + side * 0.5
		tri(base - side, base + side, mid, c0, c0, c0.lerp(c1, 0.6))
		tri(base - side, mid, tip, c0, c0.lerp(c1, 0.6), c1)

	## A leaf with a midrib: two halves in two shades, pointed at both ends.
	func leaf(base: Vector2, dir: Vector2, length: float, width: float, c_a: Color, c_b: Color) -> void:
		var n := dir.normalized()
		var side := Vector2(-n.y, n.x) * width
		var tip := base + n * length
		var mid := base + n * length * 0.42
		tri(base, mid + side, tip, c_a.darkened(0.12), c_a, c_a.lightened(0.1))
		tri(base, mid - side, tip, c_b.darkened(0.12), c_b, c_b.lightened(0.06))

	func line(a: Vector2, b: Vector2, w: float, col: Color, col_b := Color(0, 0, 0, -1.0)) -> void:
		var d := b - a
		if d.length_squared() < 0.01:
			return
		var side := Vector2(-d.y, d.x).normalized() * w * 0.5
		var cb := col if col_b.a < 0.0 else col_b
		tri(a - side, a + side, b + side, col, col, cb)
		tri(a - side, b + side, b - side, col, cb, cb)

	## A stone: soft shadow, a body darker at the rim and lit at the upper
	## left, an optional cap of moss.
	func stone(ctr: Vector2, rx: float, ry: float, col: Color, rot := 0.0, moss := Color(0, 0, 0, 0)) -> void:
		ellipse(ctr + Vector2(rx * 0.22, ry * 0.4), rx * 1.25, ry * 1.2, Color(0, 0, 0, 0.3), rot, 10, Color(0, 0, 0, 0.0))
		ellipse(ctr, rx, ry, col.lightened(0.14), rot, 10, col.darkened(0.3), Vector2(-rx * 0.3, -ry * 0.34))
		ellipse(ctr + Vector2(-rx * 0.32, -ry * 0.36), rx * 0.34, ry * 0.26, Color(1, 1, 1, 0.3), rot - 0.4, 8, Color(1, 1, 1, 0.0))
		if moss.a > 0.0:
			ellipse(ctr + Vector2(rx * 0.1, -ry * 0.28), rx * 0.7, ry * 0.5, moss.lightened(0.1), rot + 0.3, 9, Color(moss.darkened(0.15), 0.9))

	## A flower seen from above: petals round a centre, with a soft shadow.
	func flower(ctr: Vector2, r: float, col: Color, petals := 5, turn := 0.0) -> void:
		ellipse(ctr + Vector2(1.5, 2.5), r * 1.3, r * 1.3, Color(0, 0, 0, 0.22), 0.0, 8, Color(0, 0, 0, 0.0))
		for i in petals:
			var a := turn + TAU * i / petals
			var d := Vector2(cos(a), sin(a))
			ellipse(ctr + d * r * 0.62, r * 0.52, r * 0.34, col.lightened(0.1), a, 7, col.darkened(0.12))
		ellipse(ctr, r * 0.3, r * 0.3, Color("ffd23a"), 0.0, 7, Color("d8901a"))

	func mesh() -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_INDEX] = idx
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return m


# ====================================================================== dressing

## A tuft of grass: blades fanned upward from one root, dark at the base.
static func tuft(k: Kit2, p: Vector2, rng: RandomNumberGenerator, g: Color, s := 1.0, lean := 0.0) -> void:
	k.ellipse(p + Vector2(1.0, 1.5), 7.0 * s, 3.2 * s, Color(0, 0, 0, 0.2), 0.0, 8, Color(0, 0, 0, 0.0))
	var n := 5 + rng.randi() % 3
	for i in n:
		var a := (float(i) / (n - 1) - 0.5) * 1.7 + rng.randf_range(-0.15, 0.15) + lean
		var ln := rng.randf_range(9.0, 15.0) * s * (1.0 - absf(a) * 0.25)
		var tip := p + Vector2(sin(a) * ln * 0.75, -cos(a) * ln)
		k.blade(p + Vector2((i - n * 0.5) * 0.9 * s, 0.0), tip, 3.4 * s, g.darkened(0.3), g.lightened(rng.randf_range(0.12, 0.34)))


## A low plant seen from above: a rosette of broad leaves.
static func rosette(k: Kit2, p: Vector2, rng: RandomNumberGenerator, col: Color, r: float, leaves := 7) -> void:
	k.ellipse(p + Vector2(2.0, 3.0), r * 0.95, r * 0.85, Color(0, 0, 0, 0.24), 0.0, 10, Color(0, 0, 0, 0.0))
	var turn := rng.randf() * TAU
	for i in leaves:
		var a := turn + TAU * i / leaves + rng.randf_range(-0.12, 0.12)
		var ln := r * rng.randf_range(0.8, 1.05)
		var shade := 0.12 * sin(a + 0.8)
		k.leaf(p, Vector2(cos(a), sin(a)), ln, r * 0.24, col.lightened(0.1 + shade), col.darkened(0.12 - shade))
	k.ellipse(p, r * 0.13, r * 0.13, col.lightened(0.3), 0.0, 6)


## The dressing of one row as a single mesh (null if there is none): tufts,
## rosettes, flowers, stones, fallen leaves and twigs on grass; edge grass
## and stones on a road; reeds and shore stones where water meets a bank.
## `up` / `down`: the type of the rows above and below ("water", "ground",
## "safe"). Nothing is put on a tile that holds an obstacle.
static func lane_decor(lane: Lane, up: String, down: String, map: Dictionary, detail: int, x0: float, w: float, T: float) -> ArrayMesh:
	if detail <= 0 or lane.covered:
		return null
	var variant := lane.deco % 8
	var key := "d|%s|%s|%s|%d|%d|%s|%s|%d|%s|%d|%d" % [String(map.get("id", "")), lane.type, lane.layout, lane.row % 2, variant, up, down, detail, str(lane.tiles.keys()), int(x0), int(w)]
	return _cached(key, func(): return _lane_decor(lane, up, down, map, detail, x0, w, T, variant))


static func _lane_decor(lane: Lane, up: String, down: String, map: Dictionary, detail: int, x0: float, w: float, T: float, variant: int) -> ArrayMesh:
	var pal: Dictionary = map.get("palette", {})
	var st := style(map)
	var k := Kit2.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 7919 + (lane.row % 2) * 977 + 5
	var rich := 1.0 if detail > 1 else 0.6
	var g := Color(String(pal.get("safe_alt" if lane.row % 2 == 0 else "safe", "#3c9a3a")))
	var leafc := Color(String(pal.get("canopy", "#1e5a2a"))).lightened(0.12)
	var soil := Color(String(pal.get("ground", "#8a6a44")))
	var moss := Color("4f8a3a")
	var rock := Color("8a8a80").lerp(soil, 0.25)
	var litter := [Color("b08a3a"), Color("8a5a2a"), Color("c4a24a"), leafc.lerp(Color("9a7a2a"), 0.5)]
	var straw := g.lerp(Color("c8b860"), 0.5 * float(st.dry))
	match lane.type:
		"water":
			for bank: float in [-1.0, 1.0]:
				if (up if bank < 0.0 else down) == "water":
					continue
				var by := bank * T * 0.5
				# reeds leaning out over the water, thickest in swamps
				var reeds := int((5.0 + 6.0 * float(st.wet)) * rich * w / 720.0)
				for i in reeds:
					var p := Vector2(x0 + rng.randf() * w, by)
					var n := 3 + rng.randi() % 3
					for j in n:
						var a := rng.randf_range(-0.6, 0.6)
						var ln := rng.randf_range(9.0, 19.0)
						var tip := p + Vector2(sin(a) * ln * 0.6 + (j - n * 0.5) * 2.0, -bank * ln)
						k.blade(p + Vector2((j - n * 0.5) * 2.2, bank * 1.0), tip, 3.0, leafc.darkened(0.25), leafc.lightened(rng.randf_range(0.1, 0.3)))
					if rng.randf() < 0.3:
						# a cattail head
						var top := p + Vector2(rng.randf_range(-3.0, 3.0), -bank * 15.0)
						k.line(p, top, 1.6, leafc.darkened(0.1))
						k.ellipse(top, 2.2, 4.6, Color("6a4326"), 0.0, 7, Color("4a2e1a"))
				# small stones along the waterline, half in the water
				for i in int(7.0 * rich * w / 720.0):
					var p2 := Vector2(x0 + rng.randf() * w, by - bank * rng.randf_range(1.0, 5.0))
					k.stone(p2, rng.randf_range(3.0, 6.0), rng.randf_range(2.4, 4.4), rock.darkened(rng.randf_range(0.0, 0.25)), rng.randf() * TAU,
						Color(moss, 1.0) if rng.randf() < float(st.moss) + 0.2 else Color(0, 0, 0, 0))
		"ground":
			# grass creeping in from the verges, a few bigger stones, fallen leaves
			for edge: float in [-1.0, 1.0]:
				if (up if edge < 0.0 else down) != "safe":
					continue
				for i in int(6.0 * rich * w / 720.0):
					var p := Vector2(x0 + rng.randf() * w, edge * T * rng.randf_range(0.38, 0.47))
					tuft(k, p, rng, straw, rng.randf_range(0.7, 0.95), -edge * 0.0)
			for i in int(3.0 * rich * w / 720.0):
				var px := x0 + rng.randf() * w
				var py := (1.0 if rng.randf() < 0.5 else -1.0) * T * rng.randf_range(0.34, 0.44)
				k.stone(Vector2(px, py), rng.randf_range(5.0, 8.5), rng.randf_range(4.0, 6.5), rock.lightened(rng.randf_range(-0.1, 0.12)), rng.randf() * TAU,
					Color(moss, 1.0) if rng.randf() < float(st.moss) else Color(0, 0, 0, 0))
			for i in int(4.0 * rich * w / 720.0):
				var p3 := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.42, T * 0.42))
				var a3 := rng.randf() * TAU
				k.leaf(p3, Vector2(cos(a3), sin(a3)), rng.randf_range(8.0, 12.0), rng.randf_range(2.6, 3.8), litter[i % 4], Color(litter[(i + 1) % 4]).darkened(0.15))
		_:
			if lane.layout == "falls":
				return null
			var blooms := flowers(map)
			var cols := Lane.COLS
			var free := func(x: float) -> bool:
				var col := int(floorf(x / T))
				return not (col >= 0 and col < cols and lane.tiles.has(col))
			# fallen leaves and twigs first (they lie flat, under the plants)
			for i in int(7.0 * rich * w / 720.0):
				var p := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.44, T * 0.44))
				if not free.call(p.x):
					continue
				var a := rng.randf() * TAU
				k.ellipse(p + Vector2(1.5, 2.0), 6.0, 3.0, Color(0, 0, 0, 0.14), a, 6, Color(0, 0, 0, 0.0))
				k.leaf(p, Vector2(cos(a), sin(a)), rng.randf_range(8.0, 13.0), rng.randf_range(2.6, 4.2), litter[i % 4], Color(litter[(i + 2) % 4]).darkened(0.12))
			for i in int(2.0 * rich * w / 720.0):
				var p4 := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.4, T * 0.4))
				if not free.call(p4.x):
					continue
				var a4 := rng.randf() * TAU
				var d4 := Vector2(cos(a4), sin(a4))
				var ln4 := rng.randf_range(14.0, 24.0)
				var twig := Color("6a4a2a").lightened(rng.randf_range(0.0, 0.15))
				k.line(p4 + Vector2(1.5, 2.0), p4 + d4 * ln4 + Vector2(1.5, 2.0), 3.0, Color(0, 0, 0, 0.16))
				k.line(p4, p4 + d4 * ln4, 2.4, twig, twig.lightened(0.15))
				k.line(p4 + d4 * ln4 * 0.55, p4 + d4 * ln4 * 0.55 + d4.rotated(0.7) * ln4 * 0.35, 1.8, twig)
			# stones, mossy where the air is misty
			for i in int(3.0 * rich * w / 720.0):
				var p5 := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.4, T * 0.4))
				if not free.call(p5.x):
					continue
				k.stone(p5, rng.randf_range(4.5, 8.0), rng.randf_range(3.6, 6.0), rock.lightened(rng.randf_range(-0.12, 0.1)), rng.randf() * TAU,
					Color(moss, 1.0) if rng.randf() < float(st.moss) + 0.25 else Color(0, 0, 0, 0))
			# tufts of grass everywhere
			for i in int(14.0 * rich * w / 720.0):
				var p6 := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.36, T * 0.46))
				if not free.call(p6.x):
					continue
				tuft(k, p6, rng, straw if rng.randf() < float(st.dry) else g, rng.randf_range(0.75, 1.1))
			# low plants and ferns
			for i in int(3.0 * rich * w / 720.0):
				var p7 := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.34, T * 0.34))
				if not free.call(p7.x):
					continue
				rosette(k, p7, rng, leafc.lerp(g, rng.randf_range(0.2, 0.6)), rng.randf_range(9.0, 14.0), 6 + rng.randi() % 3)
			# flowers in the map's own colours
			for i in int(4.0 * rich * w / 720.0):
				var p8 := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.38, T * 0.38))
				if not free.call(p8.x):
					continue
				var bc: Color = blooms[rng.randi() % blooms.size()]
				var cluster := 1 + rng.randi() % 3
				for j in cluster:
					k.flower(p8 + Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(-7.0, 7.0)) * float(mini(j, 1)), rng.randf_range(3.6, 5.4), bc, 5 + rng.randi() % 2, rng.randf() * TAU)
			# mushrooms in the damp
			if float(st.wet) + float(st.moss) > 0.3:
				for i in int(2.0 * rich * w / 720.0):
					var p9 := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.38, T * 0.38))
					if not free.call(p9.x):
						continue
					for j in 2 + rng.randi() % 2:
						var q := p9 + Vector2(j * 7.0 - 6.0, (j % 2) * 5.0 - 2.0)
						var cap := Color("d8b88a").darkened(rng.randf_range(0.0, 0.25))
						k.ellipse(q + Vector2(1.5, 2.0), 5.0, 4.4, Color(0, 0, 0, 0.22), 0.0, 8, Color(0, 0, 0, 0.0))
						k.ellipse(q, 4.2 - j * 0.5, 3.8 - j * 0.5, cap.lightened(0.2), 0.0, 9, cap.darkened(0.2), Vector2(-1.0, -1.0))
						k.ellipse(q + Vector2(-0.8, -0.8), 1.0, 0.9, Color(1, 1, 1, 0.55), 0.0, 5)
	return k.mesh() if not k.empty() else null


## The bird's-eye roof over one row of dense canopy, as one mesh: a dark
## understorey, then three layers of leafy crowns (deepest first), each a
## shaded mound with leaves fanned over it, two-tone across the midrib and
## lit from the upper left, and a few glossy leaves catching the sun on top.
## `edge_below`: this is the zone's nearest row, so its crowns spill over the
## edge in a scalloped fringe.
static func canopy_roof(row: int, x0: float, w: float, T: float, leaf: Color, dark: Color, edge_below: bool, edge_above: bool) -> ArrayMesh:
	var key := "r|%d|%s|%s|%s|%s|%d|%d|%d" % [row % 8, leaf.to_html(), dark.to_html(), edge_below, edge_above, int(x0), int(w), Draw.detail]
	return _cached(key, func(): return _canopy_roof(row % 8, x0, w, T, leaf, dark, edge_below, edge_above))


static func _canopy_roof(variant: int, x0: float, w: float, T: float, leaf: Color, dark: Color, edge_below: bool, edge_above: bool) -> ArrayMesh:
	var k := Kit2.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 7919 + 3
	var y0 := -T * 0.5 - (0.0 if not edge_above else 10.0)
	var y1 := T * 0.5 + (0.0 if not edge_below else 10.0)
	k.tri(Vector2(x0 - 8.0, y0), Vector2(x0 + w + 8.0, y0), Vector2(x0 + w + 8.0, y1), dark, dark, dark)
	k.tri(Vector2(x0 - 8.0, y0), Vector2(x0 + w + 8.0, y1), Vector2(x0 - 8.0, y1), dark, dark, dark)
	var layers := [[58.0, 0.34, 34.0, 8], [44.0, 0.16, 27.0, 7], [36.0, 0.0, 21.0, 6]] if Draw.detail > 1 else [[54.0, 0.26, 34.0, 6], [40.0, 0.04, 25.0, 6]]
	for li in layers.size():
		var spacing: float = layers[li][0]
		var dk: float = layers[li][1]
		var r: float = layers[li][2]
		var nleaf: int = layers[li][3]
		var x := x0 - rng.randf_range(0.0, spacing)
		while x < x0 + w + spacing:
			var c := Vector2(x + rng.randf_range(-8.0, 8.0), rng.randf_range(-T * 0.36, T * 0.36))
			var rr := r * rng.randf_range(0.82, 1.15)
			var tint := leaf.darkened(dk + rng.randf_range(-0.04, 0.08)).lerp(Color("6aa83a"), rng.randf_range(0.0, 0.12))
			k.ellipse(c + Vector2(rr * 0.25, rr * 0.35), rr * 1.15, rr * 1.0, Color(0, 0, 0, 0.32), 0.0, 12, Color(0, 0, 0, 0.0))
			k.ellipse(c, rr, rr * 0.86, tint.lightened(0.08), rng.randf() * TAU, 12, tint.darkened(0.3), Vector2(-rr * 0.25, -rr * 0.3))
			var turn := rng.randf() * TAU
			for j in nleaf:
				var a := turn + TAU * j / nleaf + rng.randf_range(-0.2, 0.2)
				var d := Vector2(cos(a), sin(a))
				var lit := 0.14 * -(d.x + d.y) * 0.7
				var base := c + d * rr * 0.25
				k.leaf(base, d, rr * rng.randf_range(0.8, 1.05), rr * 0.27, tint.lightened(0.06 + lit), tint.darkened(0.08 - lit))
			if li == layers.size() - 1 and rng.randf() < 0.55:
				var a2 := rng.randf_range(-2.6, -0.8)
				var d2 := Vector2(cos(a2), sin(a2))
				k.leaf(c + d2 * rr * 0.1, d2, rr * 0.85, rr * 0.24, tint.lightened(0.32), tint.lightened(0.2))
				k.ellipse(c + d2 * rr * 0.5, rr * 0.14, rr * 0.06, Color(1, 1, 0.85, 0.35), a2, 6, Color(1, 1, 0.85, 0.0))
			x += spacing * rng.randf_range(0.8, 1.15)
	if edge_below:
		var x2 := x0
		while x2 < x0 + w + 40.0:
			var c2 := Vector2(x2 + rng.randf_range(-6.0, 6.0), T * 0.5 + rng.randf_range(2.0, 8.0))
			var t2 := leaf.darkened(0.12 + rng.randf_range(0.0, 0.1))
			k.ellipse(c2 + Vector2(4.0, 9.0), 26.0, 12.0, Color(0, 0, 0, 0.3), 0.0, 10, Color(0, 0, 0, 0.0))
			for j in 4:
				var a3 := PI * 0.5 + (j - 1.5) * 0.45 + rng.randf_range(-0.12, 0.12)
				var d3 := Vector2(cos(a3), sin(a3))
				k.leaf(c2 - d3 * 6.0, d3, rng.randf_range(20.0, 28.0), 7.0, t2.lightened(0.08), t2.darkened(0.1))
			x2 += rng.randf_range(30.0, 42.0)
	return k.mesh()


## The jungle wall down one side of the bird's-eye playfield, as one mesh:
## solid shade beyond the field, then crowns of leaves along the edge with
## fronds reaching a little way in (never more than ~44 px, so nothing in
## the outer columns is hidden). It repeats every `period` pixels down the
## screen, so it can scroll with the camera by just moving it.
## `side`: -1 left, 1 right; `edge`: the field's edge in screen pixels.
static func side_foliage(side: float, edge: float, vp_w: float, height: float, period: float, leaf: Color, dark: Color) -> ArrayMesh:
	var k := Kit2.new()
	var outer := 0.0 if side < 0.0 else vp_w
	var solid := edge + side * 30.0
	if absf(solid - outer) > 1.0:
		var a := minf(outer, solid)
		var b := maxf(outer, solid)
		k.tri(Vector2(a, -period), Vector2(b, -period), Vector2(b, height + period), dark, dark, dark)
		k.tri(Vector2(a, -period), Vector2(b, height + period), Vector2(a, height + period), dark, dark, dark)
	var inward := -side
	var reps := int(ceilf((height + 2.0 * period) / period))
	for rep in reps:
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242 + int(side) * 17
		var oy := -period + rep * period
		# back crowns, outside the field
		for i in 5:
			var c := Vector2(edge + side * rng.randf_range(26.0, 60.0), oy + period * (i + rng.randf_range(-0.3, 0.3)) / 5.0)
			var rr := rng.randf_range(30.0, 42.0)
			var tint := leaf.darkened(rng.randf_range(0.18, 0.34))
			k.ellipse(c + Vector2(inward * 6.0, 8.0), rr * 1.1, rr, Color(0, 0, 0, 0.3), 0.0, 12, Color(0, 0, 0, 0.0))
			k.ellipse(c, rr, rr * 0.9, tint.lightened(0.06), 0.0, 12, tint.darkened(0.28), Vector2(-rr * 0.2, -rr * 0.25))
			for j in 7:
				var a2 := TAU * j / 7.0 + rng.randf() * 0.5
				var d := Vector2(cos(a2), sin(a2))
				k.leaf(c + d * rr * 0.2, d, rr * rng.randf_range(0.8, 1.0), rr * 0.26, tint.lightened(0.05 - 0.1 * d.y), tint.darkened(0.1 + 0.05 * d.y))
		# fronds reaching in over the edge, lit from the upper left
		for i in 6:
			var base := Vector2(edge + side * rng.randf_range(8.0, 18.0), oy + period * (i + rng.randf_range(-0.25, 0.25)) / 6.0)
			var ang := rng.randf_range(-0.55, 0.55)
			var d2 := Vector2(inward * cos(ang), sin(ang) * 0.8 - 0.15).normalized()
			var ln := rng.randf_range(40.0, 56.0)
			var tint2 := leaf.lerp(Color("6aa83a"), rng.randf_range(0.0, 0.18)).darkened(rng.randf_range(-0.04, 0.12))
			k.ellipse(base + d2 * ln * 0.5 + Vector2(4.0, 7.0), ln * 0.5, 9.0, Color(0, 0, 0, 0.22), d2.angle(), 10, Color(0, 0, 0, 0.0))
			k.leaf(base, d2, ln, rng.randf_range(10.0, 14.0), tint2.lightened(0.1), tint2.darkened(0.08))
			k.line(base, base + d2 * ln * 0.92, 1.4, tint2.darkened(0.3), tint2.darkened(0.1))
			if rng.randf() < 0.5:
				var d3 := d2.rotated(rng.randf_range(0.4, 0.7) * (1.0 if rng.randf() < 0.5 else -1.0))
				k.leaf(base + d2 * 6.0, d3, ln * 0.7, 9.0, tint2.lightened(0.18), tint2)
	return k.mesh()
