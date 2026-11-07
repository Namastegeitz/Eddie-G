class_name MiniMap
extends RefCounted
## Layout bookkeeping for one mini map while MiniMapBuilder lays it out:
## free floor space (so things don't overlap), spots where gem shards and the
## key can go, the start and the way out. finish() places the shards, the
## key, the way out, traps and the start.

var g: LevelGeo
var rng: RandomNumberGenerator
var entry: Dictionary
## The map's number in its room (1-9, 10 = crawl space): harder as it goes.
var level := 1
var task := "shards"
var extra_shards := 4
var summit_label := ""
var _spots: Array[Vector3] = []
var _high: Array[Vector3] = []
var _rects: Array[Rect2] = []
var _area := Rect2()
var _height := 30.0
var _start := Vector3.ZERO
var _start_yaw := 0.0
var _exit := Vector3.ZERO
var _exit_label := ""
var _summit := Vector3.INF


func _init(geo: LevelGeo, r: RandomNumberGenerator, e: Dictionary) -> void:
	g = geo
	rng = r
	entry = e
	level = int(e.get("index", 1))
	task = String(e.get("task", "shards"))


## The floor is w x d, centred on the origin, `h` high.
func bounds(w: float, h: float, d: float) -> void:
	_area = Rect2(-w * 0.5 + 3.0, -d * 0.5 + 3.0, w - 6.0, d - 6.0)
	_height = h


## Narrow where things get placed (under a sloping roof).
func keep_in(x0: float, x1: float, z0: float, z1: float) -> void:
	_area = Rect2(x0, z0, x1 - x0, z1 - z0)


func block(center: Vector3, w: float, d: float) -> void:
	_rects.append(Rect2(center.x - w * 0.5, center.z - d * 0.5, w, d))


## A free floor spot for something w x d (marked taken), or Vector3.INF.
func place(w: float, d: float) -> Vector3:
	for i in 60:
		var x := rng.randf_range(_area.position.x + w * 0.5, _area.end.x - w * 0.5)
		var z := rng.randf_range(_area.position.y + d * 0.5, _area.end.y - d * 0.5)
		var r := Rect2(x - w * 0.5, z - d * 0.5, w, d)
		var clear := true
		for o in _rects:
			if o.grow(1.0).intersects(r):
				clear = false
				break
		if clear:
			_rects.append(r)
			return Vector3(x, 0, z)
	return Vector3.INF


## Somewhere a shard (or the key) can rest.
func spot(p: Vector3) -> void:
	_spots.append(p)


## A hard-to-reach spot: the key goes on one of these.
func high_spot(p: Vector3) -> void:
	_high.append(p)
	_spots.append(p)


func top_spot() -> Vector3:
	var best := Vector3(0, -1, 0)
	for p in _high + _spots:
		if p.y > best.y:
			best = p
	return best


func start(p: Vector3, yaw: float) -> void:
	_start = p
	_start_yaw = yaw
	block(p, 10, 10)


func exit_floor(p: Vector3, label: String) -> void:
	_exit = p
	_exit_label = label
	block(p, 9, 9)


func set_summit(p: Vector3, label: String) -> void:
	_summit = p
	summit_label = label


## Mouse traps on the floor and glue boards, more on the later maps.
func hazards(_unused: float) -> void:
	for i in 1 + int(level / 3.0):
		var p := place(5, 9)
		if p != Vector3.INF:
			g.mouse_trap(p, rng.randf() * TAU)
	for i in int(level / 3.0):
		var p2 := place(8, 8)
		if p2 != Vector3.INF:
			g.sticky_trap("GlueBoard", p2 + Vector3.UP * 0.5, Vector3(7, 1, 7))


## The map's prowler: the cat, or the robot vacuum.
func threat(at: Vector3) -> void:
	var kind := String(entry.get("threat", ""))
	if kind == "cat":
		var pts: Array = [at]
		for i in 4:
			pts.append(Vector3(rng.randf_range(_area.position.x, _area.end.x), 0, rng.randf_range(_area.position.y, _area.end.y)))
		g.pet("res://scenes/threats/cat.tscn", at, pts, [], [])
	elif kind == "vacuum":
		g.vacuum(at, Vector3(_area.position.x, 0, _area.position.y), Vector3(_area.end.x, 0, _area.end.y), [])


func finish() -> void:
	var need := int(entry.get("need", 0))
	# The way out: at the very top for a summit task.
	var exit_pos := _exit
	var label := _exit_label
	if task == "summit":
		exit_pos = _summit if _summit != Vector3.INF else top_spot()
		label = summit_label if summit_label != "" else "way out at the top"
	g.goal(exit_pos, label)
	if exit_pos.y < 1.0:
		g.deco_box("ExitCrack", exit_pos + Vector3(0, 0.05, 0), Vector3(4, 0.1, 4), "hole", Vector3.ZERO, false)
	# The key: on a high spot, as far from the start as possible.
	var used: Array[Vector3] = []
	if task == "key":
		var best := Vector3.INF
		var best_d := -1.0
		for p in (_high if not _high.is_empty() else _spots):
			var dd := p.distance_to(_start) + p.y
			if dd > best_d:
				best_d = dd
				best = p
		if best != Vector3.INF:
			g.item("brass_key", best)
			used.append(best)
	# Gem shards, spread out over the spots.
	var count := need + extra_shards if need > 0 else 6 + int(level / 2.0)
	var pool := _spots.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Vector3 = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var placed := 0
	for p: Vector3 in pool:
		if placed >= count:
			break
		var near := p.distance_to(_start) < 6.0 or p.distance_to(exit_pos) < 5.0
		for u in used:
			if u.distance_to(p) < 3.0:
				near = true
				break
		if near:
			continue
		g.shard(p)
		used.append(p)
		placed += 1
	# Fill up on open floor if the spots ran out.
	var tries := 0
	while placed < count and tries < 200:
		tries += 1
		var fp := Vector3(rng.randf_range(_area.position.x, _area.end.x), 0, rng.randf_range(_area.position.y, _area.end.y))
		var clear := fp.distance_to(_start) > 6.0
		for o in _rects:
			if o.has_point(Vector2(fp.x, fp.z)):
				clear = false
				break
		if clear:
			g.shard(fp)
			placed += 1
	# A power-up to find.
	var kinds := ["power_turbo", "power_spring", "power_radar", "power_double", "power_shrink"]
	for p: Vector3 in pool:
		if not used.has(p) and p.distance_to(_start) > 10.0:
			g.item(kinds[(level + rng.randi()) % kinds.size()], p)
			break
	g.spawn(_start, _start_yaw)
