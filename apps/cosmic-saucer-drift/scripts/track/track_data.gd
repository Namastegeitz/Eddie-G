class_name TrackData
extends RefCounted
## A track definition resolved for one variant (normal / reverse / mirror):
## the sampled main loop, the shortcut, and every feature placed by distance.

var id := ""
var def: Dictionary
var variant := 0
var name := ""
var theme := "asteroid"
var laps := 3
var width := 18.0
var main: TrackPath
var short: TrackPath = null
var short_side := 1
var short_a := 0.0          # distance on main where the shortcut leaves
var short_b := 0.0          # distance on main where it rejoins
var short_lift_start := false
var short_lift_end := false
var short_surface := Catalog.S_METAL
var short_tube := false
var short_skip_l := PackedByteArray()
var short_skip_r := PackedByteArray()
var short_wall_h := PackedFloat32Array()
var wall_h := PackedFloat32Array()   # collision wall height per main sample
const WALL_H := 8.0

var lowg := PackedByteArray()
var gap := PackedByteArray()
var open_l := PackedByteArray()
var open_r := PackedByteArray()
var line := PackedFloat32Array()   # AI racing line (lateral metres)

var feats: Array[Dictionary] = []  # point features with "s" (distance on main)
var ramps: Array[Dictionary] = []  # {s0, s1, h, lane, w}
var tubes: Array[Vector2] = []     # distance ranges with an enclosing tunnel
var shards: Array[Dictionary] = [] # {pos, slot}

var _m := 0  # control point count


static func make(track_id: String, var_id: int) -> TrackData:
	var td := TrackData.new()
	td._build(track_id, var_id)
	return td


func _build(track_id: String, var_id: int) -> void:
	id = track_id
	variant = var_id
	def = TrackDefs.get_def(track_id)
	name = def.name
	theme = def.theme
	laps = def.get("laps", 3)
	width = def.get("width", 18.0)
	var src: Array = def.points
	_m = src.size()
	var ctrl: Array = []
	for i in _m:
		ctrl.append(_pos(src[i]))
	if variant == Catalog.V_REVERSE:
		var rev: Array = [ctrl[0]]
		for i in range(_m - 1, 0, -1):
			rev.append(ctrl[i])
		ctrl = rev
	var widths: Array = []
	var banks: Array = []
	for i in _m:
		widths.append(width)
		banks.append(0.0)
	main = TrackPath.new()
	main.build(ctrl, widths, banks, true, def.get("auto_bank", 0.0))
	var n := main.n
	lowg.resize(n)
	gap.resize(n)
	open_l.resize(n)
	open_r.resize(n)
	lowg.fill(0)
	gap.fill(0)
	wall_h.resize(n)
	wall_h.fill(WALL_H)
	open_l.fill(0)
	open_r.fill(0)
	for f in def.features:
		_add_feature(f)
	if def.has("shortcut"):
		_build_shortcut(def.shortcut)
	for sh in def.get("shards", []):
		_add_shard(sh, shards.size())
	_racing_line()


# ---------------------------------------------------------------- variant maps
func _pos(p: Vector3) -> Vector3:
	if variant == Catalog.V_MIRROR:
		return Vector3(-p.x, p.y, p.z)
	return p


func _lane(l: float) -> float:
	return -l if variant != Catalog.V_NORMAL else l


## Control-point position -> distance on the variant's main loop.
func _s(c: float) -> float:
	if variant == Catalog.V_REVERSE:
		return main.s_of_cp(fposmod(float(_m) - c, float(_m)))
	return main.s_of_cp(c)


## Range [a, b] (control points, normal direction) -> [s0, s1] in race order.
func _range(a: float, b: float) -> Vector2:
	if variant == Catalog.V_REVERSE:
		return Vector2(_s(b), _s(a))
	return Vector2(_s(a), _s(b))


func _each_index(r: Vector2, cb: Callable) -> void:
	var span := fposmod(r.y - r.x, main.length)
	var steps := int(span / main.step)
	var i0 := main.index_at(r.x)
	for k in steps + 1:
		cb.call(main.wi(i0 + k))


# ---------------------------------------------------------------- features
func _add_feature(f: Dictionary) -> void:
	match f.t:
		"surface":
			var sid: int = f.s
			_each_index(_range(f.a, f.b), func(i: int) -> void: main.surf[i] = sid)
		"rail":
			_each_index(_range(f.a, f.b), func(i: int) -> void: main.surf[i] = Catalog.S_RAIL)
		"lowg":
			_each_index(_range(f.a, f.b), func(i: int) -> void: lowg[i] = 1)
		"tube":
			tubes.append(_range(f.a, f.b))
		"jump":
			var g: float = f.get("gap", 0.0)
			var rl: float = f.get("len", 14.0)
			var s_end := _s(f.at)
			if variant == Catalog.V_REVERSE:
				s_end = fposmod(s_end - g, main.length)
			ramps.append({"s0": s_end - rl, "s1": s_end, "h": f.get("h", 2.4), "lane": 0.0, "w": width - 1.0})
			if g > 0.0:
				_each_index(Vector2(s_end, s_end + g), func(i: int) -> void: gap[i] = 1)
		"pods":
			var s0 := _s(f.at)
			var lane := _lane(f.get("lane", 0.0))
			var cnt: int = f.get("n", 5)
			var h: float = f.get("h", 0.0)
			for k in cnt:
				if f.get("form", "row") == "line":
					feats.append({"t": "pod", "s": fposmod(s0 + (float(k) - float(cnt - 1) * 0.5) * 7.0, main.length), "lane": lane, "h": h})
				else:
					var span := width - 5.0
					var l := -span * 0.5 + span * float(k) / float(maxi(cnt - 1, 1))
					feats.append({"t": "pod", "s": s0, "lane": l, "h": h})
		"crates":
			var s0 := _s(f.at)
			var cnt := 4
			var span := width - 5.0
			for k in cnt:
				feats.append({"t": "crate", "s": s0, "lane": -span * 0.5 + span * float(k) / float(cnt - 1)})
		"boost":
			feats.append({"t": "boost", "s": _s(f.at), "lane": _lane(f.get("lane", 0.0))})
		"snapper":
			feats.append({"t": "snapper", "s": _s(f.at), "side": int(_lane(float(f.side)))})
		"geyser":
			feats.append({"t": "geyser", "s": _s(f.at), "lane": _lane(f.get("lane", 0.0)), "launch": 17.0})
		"dropper":
			var r := _range(f.a, f.b)
			feats.append({"t": "dropper", "s": r.x, "s1": r.y})
		_:
			# roller, flare, laser, eruption: point hazards
			var d := f.duplicate()
			d["s"] = _s(f.at)
			feats.append(d)


func _add_shard(sh: Dictionary, slot: int) -> void:
	if sh.has("shortcut"):
		if short == null:
			return
		var f: float = sh.shortcut
		if variant == Catalog.V_REVERSE:
			f = 1.0 - f
		var i := short.index_at(f * short.length)
		shards.append({"pos": short.pts[i] + short.upv[i] * (1.0 + sh.get("h", 1.5)), "slot": slot})
	else:
		var s := _s(sh.at)
		var i := main.index_at(s)
		var lane := _lane(sh.get("lane", 0.0))
		shards.append({"pos": main.pts[i] + main.rgt[i] * lane + main.upv[i] * (1.0 + sh.get("h", 1.5)), "slot": slot})


func _build_shortcut(sc: Dictionary) -> void:
	var r := _range(sc.a, sc.b)
	short_a = r.x
	short_b = r.y
	var via: Array = []
	for v in sc.via:
		via.append(_pos(v))
	if variant == Catalog.V_REVERSE:
		via.reverse()
	var lift: float = sc.get("lift", 0.0)
	short_lift_start = lift > 0.0 and variant != Catalog.V_REVERSE
	short_lift_end = lift > 0.0 and variant == Catalog.V_REVERSE
	# Side of the road (normal direction) from the def; reverse and mirror
	# both flip it.
	short_side = int(_lane(float(sc.get("side", 1))))
	short_surface = sc.get("surface", Catalog.S_METAL)
	short_tube = sc.get("tube", false)
	var hw := width * 0.5
	var sd := float(short_side)
	var c: Array = []
	if short_lift_start:
		# The bridge starts straight ahead of the geyser so launched saucers
		# fly onto it even when the road below turns away.
		var ig := main.index_at(short_a)
		var g0 := main.pts[ig] + main.rgt[ig] * sd * (hw - 5.0)
		c.append(g0 + main.tan[ig] * 18.0 + Vector3.UP * lift)
		c.append(g0 + main.tan[ig] * 40.0 + Vector3.UP * (lift + 0.3))
	else:
		c.append(main.point_at(short_a - 14.0, sd * (hw - 5.0), -0.06))
		c.append(main.point_at(short_a + 8.0, sd * (hw + 5.0), 0.0))
	c.append_array(via)
	if short_lift_end:
		c.append(main.point_at(short_b - 34.0, sd * (hw + 2.0), lift + 0.5))
		c.append(main.point_at(short_b - 16.0, sd * (hw - 5.0), lift))
	else:
		c.append(main.point_at(short_b - 8.0, sd * (hw + 5.0), 0.0))
		c.append(main.point_at(short_b + 14.0, sd * (hw - 5.0), -0.06))
	var sw: float = sc.get("width", 10.0)
	var ws: Array = []
	var bs: Array = []
	for i in c.size():
		ws.append(sw + (8.0 if short_lift_start and i < 2 else 0.0))
		bs.append(0.0)
	short = TrackPath.new()
	short.build(c, ws, bs, false)
	short.surf.fill(short_surface)
	if short_lift_start:
		feats.append({"t": "geyser", "s": short_a, "lane": sd * (hw - 5.0), "launch": 24.0, "shortcut": true})
		# Low collision walls under the bridge so launched saucers clear them.
		_each_index(Vector2(short_a - 4.0, short_a + 90.0), func(i: int) -> void: wall_h[i] = 2.5)
	# Open the main barrier only where the shortcut ribbon actually covers the
	# road edge, and drop the shortcut's wall on the side facing the main road
	# while that wall would stand on the main road. Together this leaves no
	# gap between the two ribbons to fall through.
	var shw := sw * 0.5
	short_skip_l.resize(short.n)
	short_skip_r.resize(short.n)
	short_skip_l.fill(0)
	short_skip_r.fill(0)
	for j in short.n:
		var p := short.pts[j]
		var i := main.nearest(p, 0, -1)
		var lat := main.lateral(i, p)
		var h := main.height(i, p)
		if absf(h) > 3.0 or absf(lat) > hw + shw + 3.0:
			continue
		if absf(lat) > hw - shw - 2.5 and absf(lat) < hw + shw - 1.0:
			var op := open_r if lat > 0.0 else open_l
			for k in range(-2, 3):
				op[main.wi(i + k)] = 1
		# Side of the shortcut that faces the main road's centre line.
		var toward := (main.pts[i] - p)
		var facing_right := toward.dot(short.rgt[j]) > 0.0
		if absf(lat) < hw + shw + 0.5:
			if facing_right:
				short_skip_r[j] = 1
			else:
				short_skip_l[j] = 1
		if absf(lat) < shw:
			short_skip_l[j] = 1
			short_skip_r[j] = 1
	short_wall_h.resize(short.n)
	short_wall_h.fill(WALL_H)
	if short_lift_start:
		# Wide landing pad with knee-high walls: you can land over them from
		# above, but they still stop you driving off the edge.
		for j in mini(short.n, int(70.0 / short.step)):
			short_wall_h[j] = 1.5


## AI racing line: lean toward the inside of upcoming corners.
func _racing_line() -> void:
	var n := main.n
	var raw := PackedFloat32Array()
	raw.resize(n)
	for i in n:
		var acc := 0.0
		for k in range(-4, 17):
			acc += main.curv[main.wi(i + k)]
		var k_avg := acc / 21.0
		raw[i] = clampf(k_avg * 130.0, -1.0, 1.0) * (width * 0.5 - 3.0)
	line.resize(n)
	for i in n:
		var acc := 0.0
		for k in range(-8, 9):
			acc += raw[main.wi(i + k)]
		line[i] = acc / 17.0


# ---------------------------------------------------------------- queries
func is_lowg(i: int) -> bool:
	return lowg[main.wi(i)] == 1


func surface_at(i: int) -> int:
	return main.surf[main.wi(i)]


## Where racer `slot` lines up on the grid (2 columns, behind the line).
func grid_transform(slot: int) -> Transform3D:
	@warning_ignore("integer_division")
	var row := slot / 2
	var col := slot % 2
	var s := main.length - 8.0 - float(row) * 9.0 - float(col) * 4.5
	var i := main.index_at(s)
	var lat := (-1.0 if col == 0 else 1.0) * width * 0.22
	var pos := main.pts[i] + main.rgt[i] * lat + main.upv[i] * 0.9
	var b := Basis(main.rgt[i], main.upv[i], -main.tan[i])
	return Transform3D(b, pos)
