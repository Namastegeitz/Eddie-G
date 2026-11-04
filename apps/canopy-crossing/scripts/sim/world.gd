class_name World
extends RefCounted
## All the lanes of one run plus map-wide events (gusts, downpours).
## Every query takes a world time, so the same world can be shared by the
## live run and by a planning bot that looks ahead.

var lanes := {}                         # int row -> Lane
var events: Array[Dictionary] = []      # gusts, downpours
var swoopers: Array[Dictionary] = []    # raptors, indexed with absolute rows
var gen := LaneGenerator.new()
var map: Dictionary = {}
var mode := "journey"
var seed_value := 0
var goal_row := -1
var fixed := false                      # hand-built worlds (tests): no generation
var _empty := Lane.new()


## A world from hand-made lanes, for tests and scripted scenes.
static func from_lanes(list: Array, goal := -1, run_mode := "journey") -> World:
	var w := World.new()
	w.fixed = true
	w.mode = run_mode
	w.goal_row = goal
	w._empty.type = "safe"
	for l in list:
		w.add_lane(l)
	return w


func setup(map_def: Dictionary, run_mode: String, stage_index: int, seed_in: int) -> void:
	map = map_def
	mode = run_mode
	seed_value = seed_in
	gen.setup(map_def, run_mode, stage_index, seed_in)
	goal_row = gen.goal_row
	_empty.type = "safe"
	_empty.band = "edge"
	var erng := RandomNumberGenerator.new()
	erng.seed = seed_in * 7919 + 17
	if run_mode != "tutorial":
		for ev in map.get("hazards", {}).get("events", []):
			var h: Dictionary = Content.hazards.get(String(ev.id), {})
			if h.is_empty():
				continue
			var per := erng.randf_range(float(h.period[0]), float(h.period[1]))
			var dur := 0.0
			if h.has("duration"):
				dur = erng.randf_range(float(h.duration[0]), float(h.duration[1]))
			events.append({"kind": String(h.kind), "hazard": String(ev.id), "period": per,
				"phase": erng.randf_range(0.0, per * 0.5), "warn": float(h.get("warn", 1.5)), "dur": dur,
				"boost": float(h.get("boost", 0.0))})
	ensure(24)


func add_lane(lane: Lane) -> void:
	lanes[lane.row] = lane
	for p in lane.preds:
		if p.kind == "swooper":
			var s := p.duplicate()
			s["lo"] = lane.row + int(p.rows[0])
			s["hi"] = lane.row + int(p.rows[1])
			s["origin"] = lane.row
			swoopers.append(s)


func ensure(row: int) -> void:
	if fixed:
		return
	gen.build(self, row)


func lane(row: int) -> Lane:
	if row < 0:
		return _empty
	if not lanes.has(row) and not fixed:
		ensure(row + 10)
	return lanes.get(row, _empty)


func has_lane(row: int) -> bool:
	return lanes.has(row)


func top_row() -> int:
	if fixed:
		var m := 0
		for r in lanes:
			m = maxi(m, int(r))
		return m
	return gen.next_row - 1


# ------------------------------------------------------------------ time

## Rivers run faster during a downpour: water lanes see extra time.
func water_time(t: float) -> float:
	var extra := 0.0
	for e in events:
		if e.kind != "downpour":
			continue
		extra += float(e.boost) * (_covered(e, t) - _covered(e, 0.0))
	return t + extra


func _covered(e: Dictionary, t: float) -> float:
	var period: float = e.period
	var u := t + float(e.phase)
	var cycles := floorf(u / period)
	var inside := clampf(fposmod(u, period) - float(e.warn), 0.0, float(e.dur))
	return cycles * float(e.dur) + inside


func downpour(t: float) -> float:
	var best := 0.0
	for e in events:
		if e.kind != "downpour":
			continue
		var u := fposmod(t + float(e.phase), float(e.period))
		if u >= float(e.warn) and u < float(e.warn) + float(e.dur):
			var k := (u - float(e.warn)) / float(e.dur)
			best = maxf(best, minf(1.0, minf(k * 5.0, (1.0 - k) * 5.0)))
		elif u < float(e.warn):
			best = maxf(best, u / float(e.warn) * 0.3)
	return best


func lane_time(l: Lane, t: float) -> float:
	return water_time(t) if l.type == "water" else t


func ent_x(l: Lane, e: Ent, t: float) -> float:
	return e.x_left(l.speed, lane_time(l, t))


func ent_dive(l: Lane, e: Ent, t: float) -> String:
	return e.dive_state(lane_time(l, t))


# ------------------------------------------------------------------ queries

func mover_hit(l: Lane, x0: float, x1: float, t: float) -> Ent:
	for e in l.ents:
		if e.platform or not e.active(t):
			continue
		var ex := ent_x(l, e, t)
		if x1 > ex + 0.06 and x0 < ex + e.length - 0.06:
			return e
	return null


func platform_at(l: Lane, x: float, t: float, margin := 0.06) -> int:
	for i in l.ents.size():
		var e: Ent = l.ents[i]
		if not e.platform or ent_dive(l, e, t) == "under":
			continue
		var ex := ent_x(l, e, t)
		if x >= ex + margin and x <= ex + e.length - margin:
			return i
	return -1


## The predator in this lane that would hit a player at (x, col), or {}.
func pred_hit(l: Lane, x: float, col: int, t: float) -> Dictionary:
	for p in l.preds:
		var st: Array = l.pred_state(p, t)
		match String(p.kind):
			"surfacer":
				if st[0] == "active" and absf(x - float(p.x)) < float(p.span) * 0.5 + 0.22:
					return p
			"striker":
				if st[0] == "distracted":
					continue
				if col == int(p.col) and not bool(p.get("hidden", false)):
					return p
				if st[0] == "active":
					var a := int(p.col)
					var b := int(p.col) + int(p.dir) * int(p.span)
					if col >= mini(a, b) and col <= maxi(a, b):
						return p
			"faller":
				if st[0] == "active" and col == int(p.col):
					return p
	return {}


func swoop_col(s: Dictionary, t: float) -> int:
	var cycle := int(floorf((t + float(s.phase) + float(s.get("shift", 0.0))) / float(s.period)))
	var h := hash([seed_value, int(s.origin), int(s.salt), cycle])
	return absi(h) % Lane.COLS


func swooper_hit(row: int, col: int, t: float) -> Dictionary:
	for s in swoopers:
		if row < int(s.lo) or row > int(s.hi):
			continue
		var st := _pred_state_generic(s, t)
		if st[0] == "active" and swoop_col(s, t) == col:
			return s
	return {}


func swoopers_near(row: int, reach: int) -> Array:
	var out := []
	for s in swoopers:
		if int(s.hi) >= row - reach and int(s.lo) <= row + reach:
			out.append(s)
	return out


func _pred_state_generic(p: Dictionary, t: float) -> Array:
	return _empty.pred_state(p, t)


func pred_state(p: Dictionary, t: float) -> Array:
	return _empty.pred_state(p, t)


## Direction (-1/+1) if a gust fires between t0 and t1, else 0.
func gust_between(t0: float, t1: float) -> int:
	for e in events:
		if e.kind != "gust":
			continue
		var period: float = e.period
		var a := t0 + float(e.phase)
		var b := t1 + float(e.phase)
		var k := floorf((b - float(e.warn)) / period)
		var cross := k * period + float(e.warn)
		if cross > a and cross <= b:
			return 1 if int(k) % 2 == 0 else -1
	return 0


## [warning 0..1, direction] for the next gust, for visuals.
func gust_warning(t: float) -> Array:
	for e in events:
		if e.kind != "gust":
			continue
		var period: float = e.period
		var u := fposmod(t + float(e.phase), period)
		var k := int(floorf((t + float(e.phase)) / period))
		if u < float(e.warn):
			return [u / float(e.warn), 1 if k % 2 == 0 else -1]
		if u < float(e.warn) + 0.5:
			return [1.0 - (u - float(e.warn)) / 0.5, 1 if k % 2 == 0 else -1]
	return [0.0, 0]


func difficulty(row: int) -> float:
	return gen.difficulty(row)
