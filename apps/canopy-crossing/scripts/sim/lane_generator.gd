class_name LaneGenerator
extends RefCounted
## Builds lanes row by row from three pieces of data: the generator file
## (which bands exist and how they stack), the map file (which hazards fill
## each slot, palette, difficulty curve) and the hazard files (sizes, speeds,
## timings). No hazard, map or band is named in this script.

var map: Dictionary = {}
var gen: Dictionary = {}
var mode := "journey"           # journey | endless | tutorial | daily
var stage: Dictionary = {}
var rng := RandomNumberGenerator.new()
var next_row := 0
var goal_row := -1
var end_row := -1
var _queue: Array[Dictionary] = []
var _band_dir := 1
var _last_band := ""
var _tail_bank := true
var _stone_cols: Array = []
var _ridge: Array = []
var _layout: Array = []
var cover: Array[Vector2i] = []   # canopy zones (first row, last row) that need first-person view
var cover_scenes: Array[String] = []   # each zone's first-person scene (map "fpv_scenes" id)
var stage_no := 0


func setup(map_def: Dictionary, run_mode: String, stage_index: int, seed_value: int) -> void:
	map = map_def
	mode = run_mode
	gen = Content.generators.get(String(map.get("generator", "classic")), Content.generators.get("classic", {}))
	rng.seed = seed_value
	stage_no = stage_index
	next_row = 0
	if mode == "tutorial":
		_layout = Content.onboarding.get("tutorial", {}).get("layout", [])
		goal_row = _layout.size() - 2
		end_row = goal_row + 8
	elif mode == "journey":
		var stages: Array = map.get("stages", [])
		stage = stages[clampi(stage_index, 0, stages.size() - 1)] if not stages.is_empty() else {"rows": 30, "difficulty": [0.0, 0.5]}
		goal_row = int(stage.get("rows", 30))
		end_row = goal_row + 8
	_plan_canopy(seed_value)
	_pick_scenes(seed_value)


## Every zone gets a scene from the map's list. Within a level the zones get
## different scenes, and the next level starts further along the list, so a
## region's scenes all come round as you play through it.
func _pick_scenes(seed_value: int) -> void:
	cover_scenes.clear()
	var list: Array = map.get("fpv_scenes", [])
	for z in cover.size():
		if list.is_empty():
			cover_scenes.append("")
			continue
		var i := (stage_no * 3 + z) if mode == "journey" else (absi(seed_value) + z)
		cover_scenes.append(String(list[i % list.size()].get("id", "")))


func zone_at(row: int) -> int:
	for i in cover.size():
		if row >= cover[i].x and row <= cover[i].y:
			return i
	return -1


## Dense-canopy zones come from data: a Journey level's "canopy" block
## ({"zones": n, "rows": [min, max]}) or the endless rule in content/rules.json.
## The lanes underneath are generated as usual; only the view changes.
func _plan_canopy(seed_value: int) -> void:
	cover.clear()
	var zr := RandomNumberGenerator.new()
	zr.seed = seed_value * 31 + 7
	var start := int(gen.get("start_rows", 3))
	if mode == "journey":
		var c: Dictionary = stage.get("canopy", {})
		var zones := int(c.get("zones", 0))
		var rr: Array = c.get("rows", [4, 6])
		if zones <= 0:
			return
		var lo := start + 3
		var hi := goal_row - 3
		var span := float(hi - lo) / zones
		for z in zones:
			var length := zr.randi_range(int(rr[0]), int(rr[1]))
			var center := lo + int((z + 0.5) * span) + zr.randi_range(-2, 2)
			var a := clampi(center - length / 2, lo, maxi(lo, hi - length))
			cover.append(Vector2i(a, a + length - 1))
	elif mode in ["endless", "daily"]:
		var ec: Dictionary = Content.rules.get("endless_canopy", {})
		if ec.is_empty():
			return
		var row := int(ec.get("first", 18))
		var every: Array = ec.get("every", [26, 40])
		var rr2: Array = ec.get("rows", [5, 9])
		while row < 3000:
			var length2 := zr.randi_range(int(rr2[0]), int(rr2[1]))
			cover.append(Vector2i(row, row + length2 - 1))
			row += length2 + zr.randi_range(int(every[0]), int(every[1]))


func is_covered(row: int) -> bool:
	for z in cover:
		if row >= z.x and row <= z.y:
			return true
	return false


func difficulty(row: int) -> float:
	if mode == "journey":
		var d: Array = stage.get("difficulty", [0.0, 0.5])
		return lerpf(float(d[0]), float(d[1]), clampf(float(row) / maxf(1.0, float(goal_row)), 0.0, 1.0))
	if mode == "tutorial":
		return 0.0
	var diff: Dictionary = map.get("difficulty", {})
	return clampf(float(row) / float(diff.get("rows_to_max", 130)), 0.0, 1.0)


func build(world: World, upto: int) -> void:
	while next_row <= upto:
		if end_row >= 0 and next_row > end_row:
			return
		var lane := _next_lane()
		if mode != "tutorial":
			lane.covered = is_covered(lane.row) and not lane.goal and not lane.start
			if lane.covered:
				lane.zone = zone_at(lane.row)
				lane.scene = cover_scenes[lane.zone] if lane.zone < cover_scenes.size() else ""
		elif lane.covered:
			lane.zone = 0
			var list: Array = map.get("fpv_scenes", [])
			lane.scene = String(list[0].get("id", "")) if not list.is_empty() else ""
		world.add_lane(lane)
		next_row += 1


# ------------------------------------------------------------------ planning

func _next_lane() -> Lane:
	var r := next_row
	var d := difficulty(r)
	if mode == "tutorial":
		return _tutorial_lane(r)
	var start := int(gen.get("start_rows", 3))
	if r < start:
		return _plain(r, true)
	if goal_row >= 0 and r >= goal_row:
		var g := _plain(r, false)
		g.goal = r == goal_row
		return g
	if _queue.is_empty():
		_plan_band(r, d)
	var spec: Dictionary = _queue.pop_front()
	return _make_lane(r, d, spec)


func _plan_band(r: int, d: float) -> void:
	var bands: Array = gen.get("bands", [])
	var weights: Array[float] = []
	var overrides: Dictionary = map.get("band_weights", {})
	var total := 0.0
	for b in bands:
		var w := _lr(b.get("weight", [1.0, 1.0]), d)
		if b.has("slot") and _slot(String(b.slot)).is_empty():
			w = 0.0
		w *= float(overrides.get(b.id, 1.0))
		if b.id == _last_band:
			w *= 0.45 if b.get("repeat", true) else 0.0
		weights.append(w)
		total += w
	var pick: Dictionary = bands[0]
	var roll := rng.randf() * total
	for i in bands.size():
		roll -= weights[i]
		if roll <= 0.0 and weights[i] > 0.0:
			pick = bands[i]
			break
	var lo := 1
	var hi := 1
	if typeof(pick.get("rows")) == TYPE_STRING:
		var br: Array = map.get("difficulty", {}).get("band", [[1, 2], [2, 4]])
		lo = int(roundf(lerpf(float(br[0][0]), float(br[1][0]), d)))
		hi = int(roundf(lerpf(float(br[0][1]), float(br[1][1]), d)))
	else:
		lo = int(pick.rows[0])
		hi = int(pick.rows[1])
	var n := rng.randi_range(lo, maxi(lo, hi))
	if goal_row >= 0:
		n = clampi(n, 1, maxi(1, goal_row - r))
	_band_dir = 1 if rng.randf() < 0.5 else -1
	_ridge = []
	var between: Dictionary = gen.get("between", {})
	var ridge := String(pick.get("layout", "")) == "ridge"
	var plain_bank := {"band": {"id": "bank", "lane": "safe"}, "index": 0, "count": 1, "between": true}
	# Ridges only connect to open, empty banks: any column can reach their
	# narrow path (a snake on the bank could otherwise block the only way on).
	if ridge:
		_queue.append(plain_bank)
	_tail_bank = false
	for i in n:
		_queue.append({"band": pick, "index": i, "count": n})
	_last_band = String(pick.id)
	if ridge:
		_queue.append(plain_bank)
		_tail_bank = true
	elif pick.lane == "safe":
		_tail_bank = true
	elif not between.is_empty():
		if rng.randf() < _chance(between.get("chance", 1.0), d):
			_queue.append({"band": between.merged({"id": "bank"}), "index": 0, "count": 1, "between": true})
			_tail_bank = true


func _make_lane(r: int, d: float, spec: Dictionary) -> Lane:
	var b: Dictionary = spec.band
	var lane := Lane.new()
	lane.row = r
	lane.band = String(b.get("id", ""))
	lane.type = String(b.get("lane", "safe"))
	lane.deco = rng.randi()
	match lane.type:
		"ground":
			_fill_ground(lane, b, d, spec)
		"water":
			_fill_water(lane, b, d, spec)
		_:
			_fill_safe(lane, b, d, spec)
	# stepping stones carry their reachable columns only into the very next lane
	var stones := false
	for e in lane.ents:
		if e.motion == "static" and e.platform:
			stones = true
	if not stones:
		_stone_cols = []
	_add_items(lane, d)
	return lane


func _plain(r: int, is_start: bool) -> Lane:
	var lane := Lane.new()
	lane.row = r
	lane.type = "safe"
	lane.band = "start" if is_start else "end"
	lane.start = is_start
	lane.deco = rng.randi()
	return lane


# ------------------------------------------------------------------ ground

func _fill_ground(lane: Lane, b: Dictionary, d: float, spec: Dictionary) -> void:
	var hid := _pick(String(b.get("slot", "")))
	if hid == "":
		lane.type = "safe"
		return
	var h: Dictionary = Content.hazards[hid]
	lane.hazard_id = hid
	var dir := _band_dir * (1 if int(spec.index) % 2 == 0 else -1)
	var smul := _lr(map.get("difficulty", {}).get("speed", [1.0, 1.0]), d)
	if String(h.get("motion", "linear")) == "pendulum":
		var count := rng.randi_range(int(h.count[0]), int(h.count[1]))
		var used := []
		for k in count:
			var e := Ent.new()
			e.hazard = hid
			e.motion = "pendulum"
			e.length = _rr(h.length)
			var c := rng.randi_range(2, Lane.COLS - 3)
			while c in used:
				c = rng.randi_range(1, Lane.COLS - 2)
			used.append(c)
			e.offset = c + 0.5 - e.length * 0.5
			e.amp = _rr(h.amplitude)
			e.period = _rr(h.period) / sqrt(smul)
			e.phase = rng.randf() * TAU
			lane.ents.append(e)
	else:
		lane.speed = dir * _rr(h.speed) * smul
		_place_linear(lane, h, hid, d, false)
	if b.has("effects") and rng.randf() < _chance(b.effects.chance, d):
		_add_effect(lane, String(b.effects.slot))


func _place_linear(lane: Lane, h: Dictionary, hid: String, d: float, platform: bool) -> void:
	var dens := _lr(map.get("difficulty", {}).get("density", [0.3, 0.6]), d)
	var t := clampf(inverse_lerp(0.25, 0.7, dens), 0.0, 1.0)
	var gap: Array = h.get("gap", [2.0, 4.0])
	var lens: Array = h.get("length", [1.0, 1.0])
	var grp: Array = h.get("group", [1, 1])
	var spacing := float(h.get("spacing", 0.15))
	var gmin := float(gap[0])
	var gmax := float(gap[1])
	var pos := rng.randf_range(0.0, gmax)
	var first := pos
	var last_end := pos
	var groups := 0
	while groups < 12:
		var n := rng.randi_range(int(grp[0]), int(grp[1]))
		var ln := _rr(lens)
		if platform:
			ln = lerpf(float(lens[1]), float(lens[0]), t * rng.randf_range(0.6, 1.0)) if lens[1] != lens[0] else ln
		var span := n * ln + (n - 1) * spacing
		if groups > 0 and pos + span > first + Lane.WRAP - gmin * 0.85:
			break
		for k in n:
			var e := Ent.new()
			e.hazard = hid
			e.platform = platform
			e.length = ln
			e.offset = pos + k * (ln + spacing)
			lane.ents.append(e)
		last_end = pos + span
		groups += 1
		var g: float
		if platform:
			g = lerpf(gmin, gmax, t) * rng.randf_range(0.8, 1.15)
		else:
			g = lerpf(gmax, gmin, t) * rng.randf_range(0.85, 1.2)
		pos = last_end + maxf(g, gmin * 0.85 if not platform else 0.6)
	if platform:
		# Never leave a long empty stretch of water across the wrap seam.
		var seam := first + Lane.WRAP - last_end
		if seam > gmax * 1.4 and seam > 2.6:
			var e2 := Ent.new()
			e2.hazard = hid
			e2.platform = true
			e2.length = minf(_rr(lens), seam - 1.2)
			e2.offset = last_end + (seam - e2.length) * 0.5
			if e2.length >= 0.9:
				lane.ents.append(e2)


# ------------------------------------------------------------------ water

func _fill_water(lane: Lane, b: Dictionary, d: float, spec: Dictionary) -> void:
	var hid := _pick(String(b.get("slot", "")))
	if hid == "":
		lane.type = "safe"
		return
	var h: Dictionary = Content.hazards[hid]
	lane.hazard_id = hid
	lane.fast = bool(h.get("fast_water", false))
	var dir := _band_dir * (1 if int(spec.index) % 2 == 0 else -1)
	var smul := _lr(map.get("difficulty", {}).get("speed", [1.0, 1.0]), d)
	match String(h.get("motion", "linear")):
		"tidal":
			var count := rng.randi_range(int(h.count[0]), int(h.count[1]))
			var amp := _rr(h.amplitude)
			var per := _rr(h.period) / sqrt(smul)
			var ph := rng.randf() * TAU
			var width := Lane.COLS + amp * 2.0
			var step := width / count
			for k in count:
				var e := Ent.new()
				e.hazard = hid
				e.platform = true
				e.motion = "pendulum"
				e.length = _rr(h.length)
				e.offset = -amp + k * step + rng.randf_range(0.0, maxf(0.0, step - e.length))
				e.amp = amp
				e.period = per
				e.phase = ph
				lane.ents.append(e)
		"pendulum":
			var ln := _rr(h.length)
			var amp2 := _rr(h.amplitude)
			var per2 := _rr(h.period) / sqrt(smul)
			var ph2 := rng.randf() * TAU
			var left := (Lane.COLS - ln) * 0.5 + rng.randf_range(-0.6, 0.6)
			var holes := int(h.get("holes", 0))
			var segs: Array = [[0.0, ln]]
			if holes > 0 and ln > 3.5:
				var hp := rng.randf_range(1.4, ln - 2.3)
				segs = [[0.0, hp], [hp + 0.9, ln]]
			var first_index := lane.ents.size()
			for s in segs:
				var e := Ent.new()
				e.hazard = hid
				e.platform = true
				e.motion = "pendulum"
				e.offset = left + float(s[0])
				e.length = float(s[1]) - float(s[0])
				e.amp = amp2
				e.period = per2
				e.phase = ph2
				e.segment_of = first_index
				lane.ents.append(e)
		"static":
			var count2 := rng.randi_range(int(h.count[0]), int(h.count[1]))
			var cols := []
			if not _stone_cols.is_empty():
				var keep: int = _stone_cols[rng.randi() % _stone_cols.size()]
				cols.append(keep)
				var near := clampi(keep + (1 if rng.randf() < 0.5 else -1), 0, Lane.COLS - 1)
				if not near in cols:
					cols.append(near)
			while cols.size() < count2:
				var c := rng.randi_range(0, Lane.COLS - 1)
				if not c in cols:
					cols.append(c)
			var dive: Dictionary = h.get("dive", {})
			var steady := []
			for i in cols.size():
				var e := Ent.new()
				e.hazard = hid
				e.platform = true
				e.motion = "static"
				e.length = 1.0
				e.offset = float(cols[i])
				if i >= 2 and not dive.is_empty() and rng.randf() < float(dive.chance):
					_set_dive(e, dive)
				else:
					steady.append(cols[i])
				lane.ents.append(e)
			# Only stones you can actually stand on: reached from below (or from
			# the bank) and then by hopping sideways between neighbouring stones.
			var reach := []
			for c in steady:
				if _stone_cols.is_empty() or c in _stone_cols:
					reach.append(c)
			var grew := true
			while grew:
				grew = false
				for c in steady:
					if not c in reach and (c - 1 in reach or c + 1 in reach):
						reach.append(c)
						grew = true
			_stone_cols = reach
		_:
			lane.speed = dir * _rr(h.speed) * smul
			_place_linear(lane, h, hid, d, true)
			var dv: Dictionary = h.get("dive", {})
			if not dv.is_empty():
				var safe_one := rng.randi() % maxi(1, lane.ents.size())
				for i in lane.ents.size():
					if float(dv.chance) >= 1.0 or (i != safe_one and rng.randf() < float(dv.chance)):
						_set_dive(lane.ents[i], dv)
	if b.has("predators") and rng.randf() < _chance(b.predators.chance, d):
		var pid := _pick(String(b.predators.slot))
		if pid != "":
			var ph: Dictionary = Content.hazards[pid]
			var per3 := _rr(ph.period)
			lane.preds.append({"kind": "surfacer", "hazard": pid, "x": rng.randi_range(1, Lane.COLS - 2) + 0.5,
				"span": float(ph.get("span", 1.2)), "period": per3, "phase": rng.randf() * per3,
				"warn": float(ph.warn), "active": float(ph.get("up", 1.0))})


func _set_dive(e: Ent, dv: Dictionary) -> void:
	e.dive_period = _rr(dv.period)
	e.dive_phase = rng.randf() * e.dive_period
	e.dive_warn = float(dv.warn)
	e.dive_under = float(dv.under)


# ------------------------------------------------------------------ safe

func _fill_safe(lane: Lane, b: Dictionary, d: float, spec: Dictionary) -> void:
	if String(b.get("layout", "")) == "ridge":
		_make_ridge(lane, b, d, spec)
		return
	var used := {}
	if b.has("specials") and rng.randf() < _chance(b.specials.chance, d):
		var sid := _pick(String(b.specials.slot))
		if sid != "":
			var h: Dictionary = Content.hazards[sid]
			match String(h.kind):
				"striker":
					var col := rng.randi_range(0, Lane.COLS - 1)
					var dirs := 1 if col < Lane.COLS / 2 else -1
					var per := _rr(h.period)
					lane.preds.append({"kind": "striker", "hazard": sid, "col": col, "dir": dirs, "span": int(h.get("span", 2)),
						"period": per, "phase": rng.randf() * per, "warn": float(h.warn), "active": float(h.get("strike", 0.45)),
						"hidden": bool(h.get("hidden", false))})
					used[col] = true
				"faller":
					var n := 1 + (1 if rng.randf() < d else 0)
					for k in n:
						var c2 := rng.randi_range(0, Lane.COLS - 1)
						if used.has(c2):
							continue
						var per2 := _rr(h.period)
						lane.preds.append({"kind": "faller", "hazard": sid, "col": c2, "period": per2, "phase": rng.randf() * per2,
							"warn": float(h.warn), "active": float(h.get("impact", 0.35))})
						used[c2] = true
	if b.has("tiles") and rng.randf() < _chance(b.tiles.chance, d):
		var tid := _pick(String(b.tiles.slot))
		if tid != "":
			var th: Dictionary = Content.hazards[tid]
			var n2 := rng.randi_range(1, 2 + int(roundf(d * 2.0)))
			for k in n2:
				var c3 := rng.randi_range(0, Lane.COLS - 1)
				if used.has(c3) or lane.tiles.size() >= 4:
					continue
				lane.tiles[c3] = {"kind": String(th.kind), "hazard": tid, "hidden": false, "sink": float(th.get("sink", 1.0))}
				used[c3] = true
	if b.has("effects") and rng.randf() < _chance(b.effects.chance, d):
		_add_effect(lane, String(b.effects.slot))
	if b.has("swoopers") and rng.randf() < _chance(b.swoopers.chance, d):
		var wid := _pick(String(b.swoopers.slot))
		if wid != "":
			var wh: Dictionary = Content.hazards[wid]
			var per4 := _rr(wh.period)
			lane.preds.append({"kind": "swooper", "hazard": wid, "rows": wh.get("rows", [-1, 3]), "period": per4,
				"phase": rng.randf() * per4, "warn": float(wh.warn), "active": float(wh.get("swoop", 0.55)), "salt": rng.randi()})


func _make_ridge(lane: Lane, b: Dictionary, d: float, spec: Dictionary) -> void:
	var hid := _pick(String(b.get("slot", "")))
	if hid == "":
		return
	lane.layout = "ridge"
	var width := clampi(int(roundf(lerpf(3.6, 2.0, d))), 2, 4)
	var start: int
	if _ridge.is_empty():
		start = rng.randi_range(0, Lane.COLS - width)
	else:
		start = clampi(int(_ridge[0]) + rng.randi_range(-1, 1), 0, Lane.COLS - width)
	var cols := []
	for c in range(start, start + width):
		cols.append(c)
	for c in Lane.COLS:
		if not c in cols:
			lane.tiles[c] = {"kind": "gap", "hazard": hid, "hidden": false}
	_ridge = cols


func _add_effect(lane: Lane, slot: String) -> void:
	var hid := _pick(slot)
	if hid == "":
		return
	var h: Dictionary = Content.hazards[hid]
	var per := _rr(h.period)
	var dur := 0.4
	if h.has("flood"):
		dur = _rr(h.flood)
	elif h.has("burn"):
		dur = _rr(h.burn)
	lane.effect = {"kind": String(h.kind), "hazard": hid, "period": per, "phase": rng.randf() * per, "warn": float(h.warn), "dur": dur}
	if lane.effect.kind == "tide":
		lane.tiles.clear()


# ------------------------------------------------------------------ items

func _add_items(lane: Lane, d: float) -> void:
	if lane.goal or lane.start:
		return
	var cc: Dictionary = gen.get("collectibles", {})
	match lane.type:
		"safe":
			if rng.randf() < _lr(cc.get("safe", [0.4, 0.3]), d):
				var n := 1 + (1 if rng.randf() < 0.35 else 0)
				for k in n:
					var c := _free_col(lane)
					if c >= 0:
						lane.items.append({"id": _pick_item(), "col": c, "ent": -1, "bonus": false})
			if rng.randf() < float(cc.get("bonus", 0.25)):
				var c2 := _free_col(lane)
				if c2 >= 0:
					lane.items.append({"id": String(Content.collectibles.get("bonus", {}).get("id", "truffle")), "col": c2, "ent": -1, "bonus": true})
		"ground":
			if rng.randf() < float(cc.get("ground", 0.05)):
				lane.items.append({"id": _pick_item(), "col": rng.randi_range(0, Lane.COLS - 1), "ent": -1, "bonus": false})
		"water":
			for i in lane.ents.size():
				var e := lane.ents[i]
				if e.platform and e.dive_period <= 0.0 and rng.randf() < float(cc.get("platform", 0.12)):
					lane.items.append({"id": _pick_item(), "col": -1, "ent": i, "rel": e.length * 0.5, "bonus": false})
	for i in lane.items.size():
		lane.items[i]["key"] = "%d:%d" % [lane.row, i]


func _free_col(lane: Lane) -> int:
	for attempt in 8:
		var c := rng.randi_range(0, Lane.COLS - 1)
		if lane.tiles.has(c):
			continue
		var clash := false
		for p in lane.preds:
			if p.get("col", -99) == c:
				clash = true
		for it in lane.items:
			if it.col == c:
				clash = true
		if not clash:
			return c
	return -1


func _pick_item() -> String:
	var items: Array = Content.collectibles.get("items", [])
	var total := 0.0
	for it in items:
		total += float(it.weight)
	var roll := rng.randf() * total
	for it in items:
		roll -= float(it.weight)
		if roll <= 0.0:
			return String(it.id)
	return "berry"


# ------------------------------------------------------------------ tutorial

func _tutorial_lane(r: int) -> Lane:
	if r >= _layout.size():
		var g := _plain(r, false)
		g.goal = r == goal_row
		return g
	var spec: Dictionary = _layout[r]
	var lane := Lane.new()
	lane.row = r
	lane.type = String(spec.get("lane", "safe"))
	lane.band = "tutorial"
	lane.deco = rng.randi()
	lane.start = r < 3
	lane.goal = r == goal_row
	lane.covered = bool(spec.get("covered", false))
	if spec.has("hazard"):
		var hid := String(spec.hazard)
		var h: Dictionary = Content.hazards[hid]
		lane.hazard_id = hid
		lane.speed = float(spec.get("speed", 1.0)) * float(spec.get("dir", 1))
		for en in spec.get("entities", []):
			var grp: Array = h.get("group", [1, 1])
			var n := int(grp[0])
			var ln := float(spec.get("length", float(h.get("length", [1.0, 1.0])[0])))
			for k in n:
				var e := Ent.new()
				e.hazard = hid
				e.platform = String(h.kind) == "platform"
				e.length = ln
				e.offset = float(en[0]) + k * (ln + float(h.get("spacing", 0.15)))
				lane.ents.append(e)
	for ci in spec.get("collectibles", []):
		lane.items.append({"id": String(ci[1]), "col": int(ci[0]), "ent": -1, "bonus": false})
	for i in lane.items.size():
		lane.items[i]["key"] = "%d:%d" % [lane.row, i]
	return lane


# ------------------------------------------------------------------ helpers

func _slot(slot: String) -> Array:
	if slot == "":
		return []
	return map.get("hazards", {}).get(slot, [])


func _pick(slot: String) -> String:
	var list := _slot(slot)
	if list.is_empty():
		return ""
	var total := 0.0
	for it in list:
		total += float(it.get("weight", 1.0))
	var roll := rng.randf() * total
	for it in list:
		roll -= float(it.get("weight", 1.0))
		if roll <= 0.0:
			return String(it.id)
	return String(list[-1].id)


func _chance(spec, d: float) -> float:
	if typeof(spec) == TYPE_STRING:
		return _lr(map.get("difficulty", {}).get(spec, [1.0, 1.0]), d)
	if typeof(spec) == TYPE_ARRAY:
		return _lr(spec, d)
	return float(spec)


func _lr(r, d: float) -> float:
	if typeof(r) != TYPE_ARRAY:
		return float(r)
	return lerpf(float(r[0]), float(r[1]), d)


func _rr(r) -> float:
	if typeof(r) != TYPE_ARRAY:
		return float(r)
	return rng.randf_range(float(r[0]), float(r[1]))
