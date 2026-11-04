class_name Items
extends Node3D
## The eight power-ups: rolling them from crates (by position lineup), using
## them, and the live effects they leave in the world. Also answers AI
## questions about items.
##   rocket  Homing Rocket - chases the racer just ahead
##   laser   Pulse Laser   - instant beam, hits everything in a line ahead
##   comet   Comet Strike  - falls on the leader (back-of-the-pack only)
##   emp     EMP Shockwave - spins out everyone close and knocks items loose
##   nitro   Nitro Rocket  - 1-3 boosts depending on your lineup
##   shield  Ion Shield    - use: 6 s bubble; hold: blocks one hit
##   mine    Gravity Mine  - dropped behind
##   tractor Tractor Beam  - drags the racer ahead back

const ROCKET_SPEED := 80.0
const ROCKET_LIFE := 4.5
const LASER_RANGE := 130.0
const LASER_WIDTH := 2.4
const MINE_LIFE := 30.0
const MAX_MINES := 8
const COMET_WARN := 2.2
const EMP_RADIUS := 15.0
const TRACTOR_TIME := 1.6
const NITRO_TIME := 1.3

var race: Node
var td: TrackData
var rockets: Array[Dictionary] = []
var mines: Array[Dictionary] = []
var comets: Array[Dictionary] = []
var beams: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var only_item := ""            # daily-challenge modifier: crates give only this
var _rng := RandomNumberGenerator.new()
var _hold := {}                # racer idx -> seconds holding the item

var _rocket_mesh: Mesh
var _mine_mesh: Mesh
var _rock_mesh: Mesh
var _ring_mesh: Mesh
var _beam_mesh: Mesh
var _flash_mesh: Mesh


func setup(p_race: Node) -> void:
	race = p_race
	td = race.td
	_rng.seed = hash(td.id) + int(Time.get_ticks_usec())
	var body := CylinderMesh.new()
	body.top_radius = 0.0
	body.bottom_radius = 0.35
	body.height = 1.8
	body.radial_segments = 8
	body.rings = 1
	_rocket_mesh = body
	var m := SphereMesh.new()
	m.radius = 0.85
	m.height = 0.9
	m.radial_segments = 10
	m.rings = 4
	_mine_mesh = m
	_rock_mesh = TrackDecor.rock_mesh()
	var t := TorusMesh.new()
	t.inner_radius = 0.92
	t.outer_radius = 1.0
	t.rings = 32
	t.ring_segments = 4
	_ring_mesh = t
	var c := CylinderMesh.new()
	c.top_radius = 0.35
	c.bottom_radius = 0.35
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
func lineup_of(r: Racer) -> int:
	var n: int = 0
	for o: Racer in race.racers:
		if not o.is_ghost:
			n += 1
	var pl := r.place
	if r.pilot.passive == "lucky":
		pl = mini(n, pl + 2)
	return Catalog.lineup_for(pl, n)


## Roll an item for a racer and set how many uses it has.
func roll(r: Racer) -> String:
	var lu := lineup_of(r)
	var it := only_item
	if it == "":
		var odds: Dictionary = Catalog.LINEUPS[lu].odds
		var total := 0
		for k in odds:
			total += int(odds[k])
		var pick := _rng.randi_range(1, total)
		it = "rocket"
		for k in odds:
			pick -= int(odds[k])
			if pick <= 0:
				it = k
				break
	r.item_uses = int(Catalog.LINEUPS[lu].nitro) if it == "nitro" else 1
	return it


# ---------------------------------------------------------------- using
func use_item(r: Racer) -> void:
	var it := r.item
	r.item_uses -= 1
	if r.item_uses <= 0:
		r.item = ""
		_hold.erase(r.idx)
	r.stats.items += 1
	match it:
		"rocket":
			_rocket(r)
		"laser":
			_laser(r)
		"comet":
			_comet(r)
		"emp":
			_emp(r)
		"nitro":
			r.give_boost(NITRO_TIME, "nitro")
			_flash(r.global_position - r.heading * 2.0, Color(1.0, 0.35, 0.8), 0.25)
		"shield":
			r.shield_time = race.tuning.shield_time
		"mine":
			_mine(r)
		"tractor":
			_tractor(r)
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


func _rocket(r: Racer) -> void:
	var t := _ahead_of(r, 150.0)
	var pos := r.global_position + r.heading * 3.0 + r.up * 0.5
	var node := _node(_rocket_mesh, TrackBuilder.flat(Color(0.85, 0.85, 0.9), 0.3, 0.7, 0.3), pos)
	var flame := _node(_flash_mesh, TrackBuilder.glow(Color(1.0, 0.5, 0.2), 2.5), pos)
	flame.scale = Vector3(0.18, 0.18, 0.35)
	var spd := maxf(ROCKET_SPEED, r.velocity.length() + 25.0)
	rockets.append({"pos": pos, "vel": r.heading * spd, "owner": r, "target": t, "life": ROCKET_LIFE, "node": node, "flame": flame, "i": r.track_idx, "near": {}})


## Instant beam along the heading: hits every racer within the beam and
## clears mines in its path.
func _laser(r: Racer) -> void:
	var origin := r.global_position + r.heading * 2.5 + r.up * 0.3
	var dir := r.heading
	var reach := LASER_RANGE
	for o: Racer in race.racers:
		if o == r or o.is_ghost or o.finished:
			continue
		var d := o.global_position - origin
		var along := d.dot(dir)
		if along < 0.0 or along > LASER_RANGE:
			continue
		if (d - dir * along).length() < LASER_WIDTH:
			o.hit(r, "laser")
	for k in range(mines.size() - 1, -1, -1):
		var mn: Dictionary = mines[k]
		var d: Vector3 = mn.pos - origin
		var along := d.dot(dir)
		if along > 0.0 and along < LASER_RANGE and (d - dir * along).length() < LASER_WIDTH + 0.5:
			_flash(mn.pos, Color(1.0, 0.85, 0.2), 0.3)
			mn.node.queue_free()
			mines.remove_at(k)
	var node := _node(_beam_mesh, TrackBuilder.glow(Color(0.3, 1.0, 0.95), 3.0), origin + dir * reach * 0.5)
	var x := dir.cross(Vector3.UP).normalized() if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var z := x.cross(dir).normalized()
	node.global_basis = Basis(x, dir * reach, z)
	beams.append({"node": node, "t": 0.25, "kind": "laser"})


func _comet(r: Racer) -> void:
	var target: Racer = null
	for o: Racer in race.racers:
		if o.place == 1 and not o.finished and not o.is_ghost:
			target = o
	if target == r:
		target = null
		for o: Racer in race.racers:
			if o.place == 2 and not o.finished and not o.is_ghost:
				target = o
	if target == null:
		return
	var ring := _node(_ring_mesh, TrackBuilder.ghost(Color(0.5, 0.8, 1.0), 0.7), target.global_position)
	ring.scale = Vector3.ONE * 5.0
	var rock := _node(_rock_mesh, TrackBuilder.flat(Color(0.75, 0.88, 1.0), 1.2, 0.2, 0.4), target.global_position + Vector3.UP * 90.0)
	rock.scale = Vector3.ONE * 2.2
	var tail := _node(_beam_mesh, TrackBuilder.ghost(Color(0.6, 0.85, 1.0), 0.5), rock.global_position)
	tail.scale = Vector3(4.0, 30.0, 4.0)
	comets.append({"owner": r, "target": target, "t": COMET_WARN, "ring": ring, "rock": rock, "tail": tail, "pos": target.global_position})
	target.emit_signal("event", "comet_warning", {})


func _emp(r: Racer) -> void:
	for o: Racer in race.racers:
		if o == r or o.is_ghost or o.finished:
			continue
		if o.global_position.distance_to(r.global_position) < EMP_RADIUS:
			var shielded := o.shield_time > 0.0
			if o.hit(r, "emp") and o.item != "" and not shielded:
				o.item = ""
				o.item_uses = 0
				o.emit_signal("event", "item_lost", {})
	var ring := _node(_ring_mesh, TrackBuilder.glow(Color(1.0, 0.95, 0.4), 2.5), r.global_position)
	ring.global_basis = Basis(r.heading.cross(r.up), r.up, -r.heading)
	beams.append({"node": ring, "t": 0.45, "kind": "emp"})
	race.shake_near(r.global_position, 0.35)


func _mine(r: Racer) -> void:
	var path := td.main
	var pos := r.global_position - r.heading * 4.0
	var i := path.nearest(pos, r.track_idx, 8)
	pos = path.pts[i] + path.rgt[i] * clampf(path.lateral(i, pos), -td.width * 0.45, td.width * 0.45) + path.upv[i] * 0.7
	var mat := TrackBuilder.flat(Color(1.0, 0.8, 0.2), 1.6, 0.6, 0.3)
	var node := _node(_mine_mesh, mat, pos)
	mines.append({"pos": pos, "s": float(i) * path.step, "lane": path.lateral(i, pos), "owner": r, "arm": 0.5, "life": MINE_LIFE, "node": node, "near": {}})
	while mines.size() > MAX_MINES:
		var old: Dictionary = mines.pop_front()
		old.node.queue_free()


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
	beams.append({"from": r, "to": t, "t": TRACTOR_TIME, "node": node, "kind": "tractor"})


func _flash(pos: Vector3, c: Color, secs := 0.35) -> void:
	var node := _node(_flash_mesh, TrackBuilder.ghost(c, 0.6), pos)
	flashes.append({"node": node, "t": secs, "life": secs})


# ---------------------------------------------------------------- live effects
func tick(dt: float) -> void:
	_tick_rockets(dt)
	_tick_mines(dt)
	_tick_comets(dt)
	_tick_beams(dt)
	for k in range(flashes.size() - 1, -1, -1):
		var f: Dictionary = flashes[k]
		f.t -= dt
		f.node.scale = Vector3.ONE * (1.0 + (float(f.life) - float(f.t)) * 4.0)
		if f.t <= 0.0:
			f.node.queue_free()
			flashes.remove_at(k)
	for r: Racer in race.racers:
		if r.item != "" and r.item_roll <= 0.0:
			_hold[r.idx] = _hold.get(r.idx, 0.0) + dt


func _tick_rockets(dt: float) -> void:
	var path := td.main
	for k in range(rockets.size() - 1, -1, -1):
		var b: Dictionary = rockets[k]
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
		var dir: Vector3 = b.vel.normalized()
		var x := dir.cross(Vector3.UP).normalized() if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		b.node.global_transform = Transform3D(Basis(x, dir, x.cross(dir).normalized()), b.pos)
		b.flame.global_position = b.pos - dir * 1.2
		var done: bool = b.life <= 0.0
		for r: Racer in race.racers:
			if r == b.owner and b.life > ROCKET_LIFE - 0.5:
				continue
			if r.is_ghost:
				continue
			var d := r.global_position.distance_to(b.pos)
			if d < 2.4:
				r.hit(b.owner, "rocket")
				_flash(b.pos, Color(1.0, 0.5, 0.2))
				done = true
				break
			elif d < 5.0:
				b.near[r.idx] = true
			elif b.near.has(r.idx) and r != b.owner:
				b.near.erase(r.idx)
				r.near_miss()
		if done:
			b.node.queue_free()
			b.flame.queue_free()
			rockets.remove_at(k)


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


func _tick_comets(dt: float) -> void:
	for k in range(comets.size() - 1, -1, -1):
		var m: Dictionary = comets[k]
		m.t -= dt
		var t: Racer = m.target
		if m.t > 0.25:
			m.pos = t.global_position
		m.ring.global_position = m.pos + Vector3.UP * 0.2
		m.ring.scale = Vector3.ONE * (3.0 + 2.0 * m.t / COMET_WARN)
		var fall := clampf(1.0 - m.t / 0.7, 0.0, 1.0)
		var rp: Vector3 = m.pos + Vector3.UP * lerpf(90.0, 0.0, fall) + Vector3(0, 0, lerpf(-40.0, 0.0, fall))
		m.rock.global_position = rp
		m.rock.visible = m.t < 0.7
		m.tail.visible = m.t < 0.7
		m.tail.global_position = rp + Vector3(0, 15.0, -6.0)
		if m.t <= 0.0:
			_flash(m.pos, Color(0.6, 0.85, 1.0))
			for r: Racer in race.racers:
				if r.is_ghost:
					continue
				var d := r.global_position.distance_to(m.pos)
				if d < 6.0:
					r.hit(m.owner, "comet")
				elif d < 10.0:
					r.near_miss()
			m.ring.queue_free()
			m.rock.queue_free()
			m.tail.queue_free()
			comets.remove_at(k)
			race.shake_all(0.5)


func _tick_beams(dt: float) -> void:
	for k in range(beams.size() - 1, -1, -1):
		var b: Dictionary = beams[k]
		b.t -= dt
		var node: MeshInstance3D = b.node
		match String(b.kind):
			"tractor":
				var a: Vector3 = b.from.global_position
				var c: Vector3 = b.to.global_position
				var mid := (a + c) * 0.5
				var len := a.distance_to(c)
				if len > 0.5:
					var y := (c - a).normalized()
					var x := y.cross(Vector3.UP).normalized() if absf(y.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
					var z := x.cross(y).normalized()
					node.global_transform = Transform3D(Basis(x, y * len, z), mid)
				if b.to.tractor_time <= 0.0:
					b.t = 0.0
			"emp":
				var s := (0.45 - float(b.t)) / 0.45 * EMP_RADIUS
				node.scale = Vector3(s, 1.5, s)
			"laser":
				var w := clampf(float(b.t) / 0.25, 0.05, 1.0)
				var bs := node.global_basis
				node.global_basis = Basis(bs.x.normalized() * w, bs.y, bs.z.normalized() * w)
		if b.t <= 0.0:
			node.queue_free()
			beams.remove_at(k)


# ---------------------------------------------------------------- AI helpers
## Shift a lane choice away from mines ahead.
func avoid_lane(s0: float, s1: float, lat: float, hw: float) -> float:
	var path := td.main
	var out := lat
	for m in mines:
		var ds := path.delta(s0, m.s)
		if ds >= 0.0 and ds <= s1 - s0 and absf(float(m.lane) - out) < 3.5:
			out = float(m.lane) + (4.5 if float(m.lane) < 0.0 else -4.5)
	return clampf(out, -hw + 2.0, hw - 2.0)


func threatened(r: Racer) -> bool:
	for b in rockets:
		if b.target == r and b.pos.distance_to(r.global_position) < 40.0:
			return true
	for m in comets:
		if m.target == r:
			return true
	return false


func _in_laser_line(r: Racer) -> bool:
	var origin := r.global_position + r.heading * 2.5
	for o: Racer in race.racers:
		if o == r or o.is_ghost or o.finished:
			continue
		var d := o.global_position - origin
		var along := d.dot(r.heading)
		if along > 3.0 and along < LASER_RANGE * 0.8 and (d - r.heading * along).length() < LASER_WIDTH * 0.8:
			return true
	return false


func ai_should_use(r: Racer, style: String, skill: float) -> bool:
	var held: float = _hold.get(r.idx, 0.0)
	if held > (14.0 if style == "hoarder" else 8.0) and r.item != "shield":
		return true
	match r.item:
		"shield":
			# Held, it already blocks one hit; pop the bubble when something's coming.
			if threatened(r):
				return true
			return style == "aggressive" and held > 6.0
		"mine":
			for o: Racer in race.racers:
				var d: float = r.race_dist - o.race_dist
				if o != r and d > 3.0 and d < 30.0:
					return true
			return style == "aggressive" and held > 1.0
		"rocket", "tractor":
			var t := _ahead_of(r, 100.0 if r.item == "rocket" else 60.0)
			return t != null and (style == "aggressive" or skill > 0.5 or held > 2.0)
		"laser":
			return (_in_laser_line(r) and _rng.randf() < 0.3 + skill * 0.5) or held > 6.0
		"emp":
			var near := 0
			for o: Racer in race.racers:
				if o != r and not o.is_ghost and o.global_position.distance_to(r.global_position) < EMP_RADIUS * 0.85:
					near += 1
			return near >= (1 if style == "aggressive" else 2) or held > 6.0
		"nitro":
			var path := td.main
			var curve := 0.0
			for k in range(0, 30, 3):
				curve = maxf(curve, absf(path.curv[path.wi(r.track_idx + k)]))
			return (curve < 0.012 and held > 0.5) or held > 4.0 or r.emergency
		"comet":
			return held > 0.8
	return held > 2.0
