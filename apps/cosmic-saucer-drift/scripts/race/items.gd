class_name Items
extends Node3D
## The eight power-ups: rolling them from crates, using them, and the live
## effects they leave in the world (bolts, mines, meteors, black holes,
## tractor beams). Also answers AI questions about items.

const BOLT_SPEED := 78.0
const BOLT_LIFE := 4.0
const MINE_LIFE := 30.0
const MAX_MINES := 8
const METEOR_WARN := 2.2
const HOLE_LIFE := 4.5
const HOLE_R := 13.0
const TRACTOR_TIME := 1.6
const WARP_DIST := 75.0
const INK_TIME := 3.6

var race: Node
var td: TrackData
var bolts: Array[Dictionary] = []
var mines: Array[Dictionary] = []
var meteors: Array[Dictionary] = []
var holes: Array[Dictionary] = []
var beams: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var only_item := ""            # daily-challenge modifier: crates give only this
var _rng := RandomNumberGenerator.new()
var _hold := {}                # racer idx -> seconds holding the item

var _bolt_mesh: Mesh
var _mine_mesh: Mesh
var _rock_mesh: Mesh
var _ring_mesh: Mesh
var _hole_mesh: Mesh
var _beam_mesh: Mesh
var _flash_mesh: Mesh


func setup(p_race: Node) -> void:
	race = p_race
	td = race.td
	_rng.seed = hash(td.id) + int(Time.get_ticks_usec())
	var s := SphereMesh.new()
	s.radius = 0.6
	s.height = 1.2
	s.radial_segments = 8
	s.rings = 4
	_bolt_mesh = s
	var m := SphereMesh.new()
	m.radius = 0.85
	m.height = 0.9
	m.radial_segments = 10
	m.rings = 4
	_mine_mesh = m
	_rock_mesh = TrackDecor.rock_mesh()
	var t := TorusMesh.new()
	t.inner_radius = 4.2
	t.outer_radius = 5.0
	t.rings = 24
	t.ring_segments = 4
	_ring_mesh = t
	var h := SphereMesh.new()
	h.radius = 3.0
	h.height = 6.0
	_hole_mesh = h
	var c := CylinderMesh.new()
	c.top_radius = 0.35
	c.bottom_radius = 0.9
	c.height = 1.0
	c.radial_segments = 8
	c.rings = 1
	_beam_mesh = c
	var f := SphereMesh.new()
	f.radius = 2.5
	f.height = 5.0
	f.radial_segments = 12
	f.rings = 6
	_flash_mesh = f


func _node(mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos
	return mi


# ---------------------------------------------------------------- rolling
func roll(r: Racer) -> String:
	if only_item != "":
		return only_item
	var n: int = race.racers.size()
	var pl := r.place
	if r.pilot.passive == "lucky":
		pl = mini(n, pl + 2)
	var bucket := 1
	if pl == 1:
		bucket = 0
	elif n <= 2 or float(pl) > float(n) * 0.6:
		bucket = 2
	var odds: Dictionary = Catalog.ITEM_ODDS[bucket]
	var total := 0
	for k in odds:
		total += int(odds[k])
	var pick := _rng.randi_range(1, total)
	for k in odds:
		pick -= int(odds[k])
		if pick <= 0:
			return k
	return "bolt"


# ---------------------------------------------------------------- using
func use_item(r: Racer) -> void:
	var it := r.item
	r.item = ""
	_hold.erase(r.idx)
	r.stats.items += 1
	match it:
		"shield":
			r.shield_time = race.tuning.shield_time
		"warp":
			_warp(r)
		"tractor":
			_tractor(r)
		"meteor":
			_meteor(r)
		"bolt":
			_bolt(r)
		"mine":
			_mine(r)
		"nebula":
			_nebula(r)
		"blackhole":
			_blackhole(r)
	r.emit_signal("event", "item_used", {"item": it})


func _ahead_of(r: Racer, max_dist: float) -> Racer:
	var best: Racer = null
	var best_d := INF
	for o: Racer in race.racers:
		if o == r or o.finished or o.is_ghost:
			continue
		var d: float = o.race_dist - r.race_dist
		if d > 1.0 and d < max_dist and d < best_d:
			best_d = d
			best = o
	return best


func _warp(r: Racer) -> void:
	var path := td.main
	var s := float(r.track_idx) * path.step + WARP_DIST
	var i := path.index_at(s)
	var guard := 0
	while td.gap[i] == 1 and guard < 40:
		i = path.wi(i + 2)
		guard += 1
	_flash(r.global_position, Color(0.85, 0.5, 1.0))
	var lat := clampf(r.lateral, -td.width * 0.3, td.width * 0.3)
	r.global_position = path.pts[i] + path.rgt[i] * lat + path.upv[i] * race.tuning.hover_height
	r.heading = path.tan[i]
	r.up = path.upv[i]
	var spd := maxf(r.velocity.length(), r.max_speed * 0.9)
	r.velocity = path.tan[i] * spd
	r.track_idx = i
	var ns := path.along(i, r.global_position)
	r.race_dist += path.delta(r.prev_s, ns)
	r.prev_s = ns
	r.invuln_time = maxf(r.invuln_time, 0.4)
	r.give_boost(0.6, "warp")
	_flash(r.global_position, Color(0.85, 0.5, 1.0))


func _tractor(r: Racer) -> void:
	var t := _ahead_of(r, 75.0)
	if t == null:
		r.give_boost(0.5, "tractor")
		return
	if not t.can_be_hit():
		t.emit_signal("event", "blocked", {"kind": "tractor"})
		return
	t.tractor_time = TRACTOR_TIME
	t.velocity *= 0.75
	r.stats.hits += 1
	r.emit_signal("event", "hit_landed", {"target": t, "kind": "tractor"})
	t.emit_signal("event", "tractored", {"by": r})
	r.give_boost(0.7, "tractor")
	var node := _node(_beam_mesh, TrackBuilder.ghost(Color(0.4, 1.0, 0.5), 0.45), r.global_position)
	beams.append({"from": r, "to": t, "t": TRACTOR_TIME, "node": node})


func _meteor(r: Racer) -> void:
	var target: Racer = null
	for o: Racer in race.racers:
		if o.place == 1 and not o.finished:
			target = o
	if target == r:
		target = null
		for o: Racer in race.racers:
			if o.place == 2 and not o.finished:
				target = o
	if target == null:
		return
	var ring := _node(_ring_mesh, TrackBuilder.ghost(Color(1.0, 0.3, 0.1), 0.7), target.global_position)
	var rock := _node(_rock_mesh, TrackBuilder.flat(Color(0.9, 0.4, 0.15), 1.5, 0.1, 0.8), target.global_position + Vector3.UP * 90.0)
	rock.scale = Vector3.ONE * 2.2
	meteors.append({"owner": r, "target": target, "t": METEOR_WARN, "ring": ring, "rock": rock, "pos": target.global_position})
	target.emit_signal("event", "meteor_warning", {})


func _bolt(r: Racer) -> void:
	var t := _ahead_of(r, 140.0)
	var pos := r.global_position + r.heading * 3.0 + r.up * 0.4
	var node := _node(_bolt_mesh, TrackBuilder.glow(Color(1.0, 0.3, 0.45), 3.0), pos)
	var spd := maxf(BOLT_SPEED, r.velocity.length() + 25.0)
	bolts.append({"pos": pos, "vel": r.heading * spd, "owner": r, "target": t, "life": BOLT_LIFE, "node": node, "i": r.track_idx, "near": {}})


func _mine(r: Racer) -> void:
	var path := td.main
	var pos := r.global_position - r.heading * 4.0
	var i := path.nearest(pos, r.track_idx, 8)
	pos = path.pts[i] + path.rgt[i] * clampf(path.lateral(i, pos), -td.width * 0.45, td.width * 0.45) + path.upv[i] * 0.7
	var mat := TrackBuilder.flat(Color(1.0, 0.85, 0.2), 1.6, 0.6, 0.3)
	var node := _node(_mine_mesh, mat, pos)
	mines.append({"pos": pos, "s": float(i) * path.step, "lane": path.lateral(i, pos), "owner": r, "arm": 0.5, "life": MINE_LIFE, "node": node, "near": {}})
	while mines.size() > MAX_MINES:
		var old: Dictionary = mines.pop_front()
		old.node.queue_free()


func _nebula(r: Racer) -> void:
	for o: Racer in race.racers:
		if o == r or o.finished or o.is_ghost:
			continue
		if o.race_dist > r.race_dist:
			if o.shield_time > 0.0:
				o.emit_signal("event", "blocked", {"kind": "nebula"})
				continue
			o.ink_time = INK_TIME
			o.emit_signal("event", "inked", {"by": r})
			r.stats.hits += 1
	_flash(r.global_position + r.up * 3.0, Color(0.75, 0.35, 0.95))


func _blackhole(r: Racer) -> void:
	var path := td.main
	var s := float(r.track_idx) * path.step + 32.0
	var i := path.index_at(s)
	var lat := clampf(r.lateral, -td.width * 0.35, td.width * 0.35)
	var pos := path.pts[i] + path.rgt[i] * lat + path.upv[i] * 1.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.0, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.2, 0.9)
	mat.emission_energy_multiplier = 0.3
	mat.rim_enabled = true
	mat.rim = 1.0
	var node := _node(_hole_mesh, mat, pos)
	var ring := _node(_ring_mesh, TrackBuilder.glow(Color(0.7, 0.35, 1.0), 2.2), pos)
	ring.basis = TrackBuilder.sb(Basis(path.rgt[i], path.upv[i], -path.tan[i]), Vector3(1.5, 1.0, 1.5))
	holes.append({"pos": pos, "s": s, "lane": lat, "owner": r, "life": HOLE_LIFE, "node": node, "ring": ring, "near": {}})


func _flash(pos: Vector3, c: Color) -> void:
	var node := _node(_flash_mesh, TrackBuilder.ghost(c, 0.6), pos)
	flashes.append({"node": node, "t": 0.35})


# ---------------------------------------------------------------- live effects
func tick(dt: float) -> void:
	_tick_bolts(dt)
	_tick_mines(dt)
	_tick_meteors(dt)
	_tick_holes(dt)
	_tick_beams(dt)
	for k in range(flashes.size() - 1, -1, -1):
		var f: Dictionary = flashes[k]
		f.t -= dt
		f.node.scale = Vector3.ONE * (1.0 + (0.35 - f.t) * 4.0)
		if f.t <= 0.0:
			f.node.queue_free()
			flashes.remove_at(k)
	for r: Racer in race.racers:
		if r.item != "" and r.item_roll <= 0.0:
			_hold[r.idx] = _hold.get(r.idx, 0.0) + dt


func _tick_bolts(dt: float) -> void:
	var path := td.main
	for k in range(bolts.size() - 1, -1, -1):
		var b: Dictionary = bolts[k]
		b.life -= dt
		var t: Racer = b.target
		var aim: Vector3
		if t and not t.finished and t.rescue_time <= 0.0:
			aim = t.global_position
		else:
			b.i = path.nearest(b.pos, b.i, 12)
			aim = path.pts[path.wi(b.i + 10)] + path.upv[path.wi(b.i + 10)] * 1.2
		var spd: float = b.vel.length()
		var want: Vector3 = (aim - b.pos).normalized() * spd
		b.vel = b.vel.lerp(want, 1.0 - exp(-5.0 * dt))
		b.pos += b.vel * dt
		b.node.global_position = b.pos
		var done: bool = b.life <= 0.0
		for r: Racer in race.racers:
			if r == b.owner and b.life > BOLT_LIFE - 0.5:
				continue
			if r.is_ghost:
				continue
			var d := r.global_position.distance_to(b.pos)
			if d < 2.4:
				r.hit(b.owner, "bolt")
				_flash(b.pos, Color(1.0, 0.35, 0.45))
				done = true
				break
			elif d < 5.0:
				b.near[r.idx] = true
			elif b.near.has(r.idx) and r != b.owner:
				b.near.erase(r.idx)
				r.near_miss()
		if done:
			b.node.queue_free()
			bolts.remove_at(k)


func _tick_mines(dt: float) -> void:
	for k in range(mines.size() - 1, -1, -1):
		var m: Dictionary = mines[k]
		m.arm -= dt
		m.life -= dt
		m.node.rotation.y += dt * 3.0
		var gone: bool = m.life <= 0.0
		if m.arm <= 0.0:
			for r: Racer in race.racers:
				if r.is_ghost or (r == m.owner and m.arm > -0.8):
					continue
				var d := r.global_position.distance_to(m.pos)
				if d < 2.5:
					r.hit(m.owner, "mine")
					_flash(m.pos, Color(1.0, 0.85, 0.2))
					gone = true
					break
				elif d < 5.0:
					m.near[r.idx] = true
				elif m.near.has(r.idx):
					m.near.erase(r.idx)
					r.near_miss()
		if gone:
			m.node.queue_free()
			mines.remove_at(k)


func _tick_meteors(dt: float) -> void:
	for k in range(meteors.size() - 1, -1, -1):
		var m: Dictionary = meteors[k]
		m.t -= dt
		var t: Racer = m.target
		if m.t > 0.25:
			m.pos = t.global_position
		m.ring.global_position = m.pos + Vector3.UP * 0.2
		m.ring.scale = Vector3.ONE * (0.6 + 0.4 * m.t / METEOR_WARN)
		var fall := clampf(1.0 - m.t / 0.7, 0.0, 1.0)
		m.rock.global_position = m.pos + Vector3.UP * lerpf(90.0, 0.0, fall)
		m.rock.visible = m.t < 0.7
		if m.t <= 0.0:
			_flash(m.pos, Color(1.0, 0.5, 0.15))
			for r: Racer in race.racers:
				if r.is_ghost:
					continue
				var d := r.global_position.distance_to(m.pos)
				if d < 6.0:
					r.hit(m.owner, "meteor")
				elif d < 10.0:
					r.near_miss()
			m.ring.queue_free()
			m.rock.queue_free()
			meteors.remove_at(k)
			race.shake_all(0.5)


func _tick_holes(dt: float) -> void:
	for k in range(holes.size() - 1, -1, -1):
		var h: Dictionary = holes[k]
		h.life -= dt
		var pulse := 1.0 + 0.15 * sin(h.life * 12.0)
		h.node.scale = Vector3.ONE * pulse * clampf(h.life * 2.0, 0.05, 1.0)
		h.ring.rotate_object_local(Vector3.UP, dt * 4.0)
		for r: Racer in race.racers:
			if r == h.owner or r.is_ghost or r.rescue_time > 0.0:
				continue
			var to: Vector3 = h.pos - r.global_position
			var d := to.length()
			if d < HOLE_R:
				var pull := (1.0 - d / HOLE_R) * 26.0
				var flat := to - r.up * to.dot(r.up)
				r.velocity += flat.normalized() * pull * dt
				if r.can_be_hit():
					r.slow_time = 0.15
				h.near[r.idx] = true
				if d < 2.8:
					r.hit(h.owner, "blackhole")
			elif h.near.has(r.idx):
				h.near.erase(r.idx)
				r.near_miss()
		if h.life <= 0.0:
			h.node.queue_free()
			h.ring.queue_free()
			holes.remove_at(k)


func _tick_beams(dt: float) -> void:
	for k in range(beams.size() - 1, -1, -1):
		var b: Dictionary = beams[k]
		b.t -= dt
		var a: Vector3 = b.from.global_position
		var c: Vector3 = b.to.global_position
		var mid := (a + c) * 0.5
		var len := a.distance_to(c)
		var node: MeshInstance3D = b.node
		if len > 0.5:
			var y := (c - a).normalized()
			var x := y.cross(Vector3.UP).normalized() if absf(y.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
			var z := x.cross(y).normalized()
			node.global_transform = Transform3D(Basis(x, y * len, z), mid)
		if b.t <= 0.0 or b.to.tractor_time <= 0.0:
			node.queue_free()
			beams.remove_at(k)


# ---------------------------------------------------------------- AI helpers
## Shift a lane choice away from mines and black holes ahead.
func avoid_lane(s0: float, s1: float, lat: float, hw: float) -> float:
	var path := td.main
	var out := lat
	for m in mines:
		var ds := path.delta(s0, m.s)
		if ds >= 0.0 and ds <= s1 - s0 and absf(float(m.lane) - out) < 3.5:
			out = float(m.lane) + (4.5 if float(m.lane) < 0.0 else -4.5)
	for h in holes:
		var ds := path.delta(s0, h.s)
		if ds >= 0.0 and ds <= s1 - s0 and absf(float(h.lane) - out) < HOLE_R * 0.7:
			out = float(h.lane) + (HOLE_R if float(h.lane) < 0.0 else -HOLE_R)
	return clampf(out, -hw + 2.0, hw - 2.0)


func threatened(r: Racer) -> bool:
	for b in bolts:
		if b.target == r and b.pos.distance_to(r.global_position) < 40.0:
			return true
	for m in meteors:
		if m.target == r:
			return true
	return false


func ai_should_use(r: Racer, style: String, skill: float) -> bool:
	var held: float = _hold.get(r.idx, 0.0)
	if held > (14.0 if style == "hoarder" else 8.0):
		return true
	match r.item:
		"shield":
			if threatened(r):
				return true
			return style != "hoarder" and held > 3.0 and r.place <= 2
		"mine":
			for o: Racer in race.racers:
				var d: float = r.race_dist - o.race_dist
				if o != r and d > 3.0 and d < 30.0:
					return true
			return style == "aggressive" and held > 1.0
		"bolt", "tractor":
			var t := _ahead_of(r, 90.0 if r.item == "bolt" else 60.0)
			return t != null and (style == "aggressive" or skill > 0.5 or held > 2.0)
		"blackhole":
			return _ahead_of(r, 45.0) != null or held > 4.0
		"warp":
			var path := td.main
			var curve := 0.0
			for k in range(0, 36, 3):
				curve = maxf(curve, absf(path.curv[path.wi(r.track_idx + k)]))
			return curve < 0.012 or held > 5.0
		"meteor", "nebula":
			return held > 0.8
	return held > 2.0
