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
var nitros: Array[Dictionary] = []
var only_item := ""            # daily-challenge modifier: crates give only this
var _rng := RandomNumberGenerator.new()
var _hold := {}                # racer idx -> seconds holding the item
var _badges := {}              # racer idx -> held-shield badge node
## Effect nodes are built once at race load and reused (no mesh building or
## shader compiling mid-race, which caused a hitch the first time each
## power-up fired). Pooled nodes stay in the tree, hidden.
var _pool := {}                # kind -> Array[Node3D]
const POOL_SIZES := {"rocket": 3, "reticle_air": 3, "reticle_ground": 2, "comet": 2, "laser": 3, "tractor": 2,
	"dome": 2, "bolt": 8, "boosters": 2, "mine": MAX_MINES}

const ROCKET_C := Color(1.0, 0.5, 0.2)
const LASER_C := Color(0.3, 1.0, 0.95)
const COMET_C := Color(0.55, 0.85, 1.0)
const EMP_C := Color(1.0, 0.92, 0.35)
const NITRO_C := Color(1.0, 0.35, 0.8)
const SHIELD_C := Color(0.35, 0.8, 1.0)
const MINE_C := Color(1.0, 0.8, 0.2)
const TRACTOR_C := Color(0.45, 1.0, 0.5)


func setup(p_race: Node) -> void:
	race = p_race
	td = race.td
	_rng.seed = hash(td.id) + int(Time.get_ticks_usec())
	for kind in POOL_SIZES:
		_pool[kind] = []
		for k in int(POOL_SIZES[kind]):
			_give(kind, _build(kind))
	for r: Racer in race.racers:
		if not r.is_ghost:
			var b := ItemModels.shield_badge()
			b.visible = false
			r.add_child(b)
			_badges[r.idx] = b


func _build(kind: String) -> Node3D:
	match kind:
		"rocket":
			return ItemModels.rocket(ROCKET_C)
		"reticle_air":
			return ItemModels.reticle(Color(1.0, 0.25, 0.15), 4.2)
		"reticle_ground":
			return ItemModels.reticle(Color(1.0, 0.35, 0.2), 10.0, true)
		"comet":
			return ItemModels.comet()
		"laser":
			return ItemModels.beam_set(LASER_C, 1.0, 14.0)
		"tractor":
			return ItemModels.beam_set(TRACTOR_C, 1.3, -8.0)
		"dome":
			return ItemModels.dome(EMP_C)
		"bolt":
			return ItemModels.bolt(EMP_C)
		"boosters":
			var holder := Node3D.new()
			for sx: float in [-1.0, 1.0]:
				var bst := ItemModels.booster(NITRO_C)
				bst.name = "L" if sx < 0.0 else "R"
				holder.add_child(bst)
			return holder
		"mine":
			return ItemModels.mine(MINE_C)
	return Node3D.new()


## A pooled node of this kind, shown and parented to Items (builds a fresh
## one if the pool ran dry).
func _take(kind: String) -> Node3D:
	var arr: Array = _pool.get(kind, [])
	var node: Node3D = arr.pop_back() if not arr.is_empty() else _build(kind)
	if node.get_parent() == null:
		add_child(node)
	elif node.get_parent() != self:
		node.get_parent().remove_child(node)
		add_child(node)
	node.visible = true
	return node


## Return a node to its pool (hidden, reset).
func _give(kind: String, node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	if node.get_parent() == null:
		add_child(node)
	elif node.get_parent() != self:
		node.get_parent().remove_child(node)
		add_child(node)
	node.visible = false
	node.transform = Transform3D.IDENTITY
	for c in node.get_children():
		if c is CPUParticles3D:
			(c as CPUParticles3D).restart()
			(c as CPUParticles3D).emitting = false
	if not _pool.has(kind):
		_pool[kind] = []
	_pool[kind].append(node)


func pooled(kind: String) -> int:
	return (_pool.get(kind, []) as Array).size()


## Shows one of every effect in front of the camera, tiny, for a couple of
## frames during the countdown so every shader is compiled before the race
## (first use used to stall a phone for a moment).
func warm_up(cam: Camera3D) -> void:
	if cam == null:
		return
	var shown: Array = []
	for kind in POOL_SIZES:
		var node := _take(kind)
		remove_child(node)
		cam.add_child(node)
		node.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.02), Vector3(0, 0, -3.0))
		for c in node.get_children():
			if c is CPUParticles3D:
				(c as CPUParticles3D).emitting = true
		shown.append([kind, node])
	var tree := get_tree()
	for i in 3:
		await tree.process_frame
		if not is_inside_tree():
			return   # the race ended during the warm-up
	for sn in shown:
		_give(sn[0], sn[1])


func _place(node: Node3D, xf: Transform3D) -> Node3D:
	if node.get_parent() == null:
		add_child(node)
	node.visible = true
	node.global_transform = xf
	node.reset_physics_interpolation()
	return node


func _fx() -> RaceFx:
	return race.fx if race and "fx" in race else null


## Fireball, sparks, shockwave and smoke where something blows up.
func _boom(pos: Vector3, c: Color, size := 1.0, up := Vector3.UP) -> void:
	var fx := _fx()
	if fx == null:
		return
	fx.flash(pos + up * 0.5, c.lerp(Color.WHITE, 0.35), 5.0 * size, 0.28)
	fx.sparks(pos + up * 0.4, up, c, int(34 * size), 15.0 * size, 12.0)
	fx.shockwave(pos, up, c, 9.0 * size, 0.45)
	fx.dust(pos, up, Color(0.35, 0.33, 0.36), int(18 * size))


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
			_nitro(r)
		"shield":
			r.shield_time = race.tuning.shield_time
			var fx := _fx()
			if fx:
				fx.flash(r.global_position + r.up * 0.6, SHIELD_C, 6.0, 0.3)
				fx.shockwave(r.global_position, r.up, SHIELD_C, 7.0, 0.4)
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


static func _basis_y(dir: Vector3) -> Basis:
	var x := dir.cross(Vector3.UP).normalized() if absf(dir.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	return Basis(x, dir, x.cross(dir).normalized())


func _rocket(r: Racer) -> void:
	var t := _ahead_of(r, 150.0)
	var pos := r.global_position + r.heading * 3.0 + r.up * 0.5
	var node := _place(_take("rocket"), Transform3D(_basis_y(r.heading).scaled(Vector3.ONE * 1.5), pos))
	for c in node.get_children():
		if c is CPUParticles3D:
			(c as CPUParticles3D).emitting = true
	var ret: Node3D = null
	if t:
		ret = _place(_take("reticle_air"), Transform3D(Basis.IDENTITY, t.global_position + t.up * 2.6))
		t.emit_signal("event", "rocket_lock", {"by": r})
	var fx := _fx()
	if fx:
		fx.flash(pos, ROCKET_C, 2.6, 0.18)
	var spd := maxf(ROCKET_SPEED, r.velocity.length() + 25.0)
	rockets.append({"pos": pos, "vel": r.heading * spd, "owner": r, "target": t, "life": ROCKET_LIFE, "node": node, "reticle": ret, "i": r.track_idx, "near": {}})


## Instant beam along the heading: hits every racer within the beam and
## clears mines in its path.
func _laser(r: Racer) -> void:
	var origin := r.global_position + r.heading * 2.5 + r.up * 0.3
	var dir := r.heading
	var reach := LASER_RANGE
	var fx := _fx()
	for o: Racer in race.racers:
		if o == r or o.is_ghost or o.finished:
			continue
		var d := o.global_position - origin
		var along := d.dot(dir)
		if along < 0.0 or along > LASER_RANGE:
			continue
		if (d - dir * along).length() < LASER_WIDTH:
			if o.hit(r, "laser") and fx:
				fx.sparks(o.global_position + o.up * 0.5, -dir + o.up * 0.5, LASER_C, 28, 12.0)
	for k in range(mines.size() - 1, -1, -1):
		var mn: Dictionary = mines[k]
		var d: Vector3 = mn.pos - origin
		var along := d.dot(dir)
		if along > 0.0 and along < LASER_RANGE and (d - dir * along).length() < LASER_WIDTH + 0.5:
			_boom(mn.pos, MINE_C, 0.6)
			_give("mine", mn.node)
			mines.remove_at(k)
	var node := _take("laser")
	_place(node, Transform3D(Basis.IDENTITY, origin))
	var b := _basis_y(dir)
	node.global_transform = Transform3D(Basis(b.x, dir * reach, b.z), origin + dir * reach * 0.5)
	node.reset_physics_interpolation()
	if fx:
		# Pulses of light along the beam so it reads from the chase camera
		# even when it fires straight ahead.
		fx.flash(origin, LASER_C, 4.2, 0.22)
		for k in 5:
			fx.flash(origin + dir * (9.0 + 13.0 * float(k)), LASER_C.lerp(Color.WHITE, 0.3), 3.0 - 0.3 * float(k), 0.16 + 0.03 * float(k))
	race.shake_near(origin, 0.18)
	beams.append({"node": node, "t": 0.3, "life": 0.3, "kind": "laser", "dir": dir, "reach": reach, "origin": origin})


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
	var ring := _place(_take("reticle_ground"), Transform3D(Basis.IDENTITY, target.global_position))
	var rock := _place(_take("comet"), Transform3D(Basis.IDENTITY, target.global_position + Vector3.UP * 90.0))
	rock.visible = false
	for c in rock.get_children():
		if c is CPUParticles3D:
			(c as CPUParticles3D).emitting = true
	comets.append({"owner": r, "target": target, "t": COMET_WARN, "ring": ring, "rock": rock, "pos": target.global_position})
	target.emit_signal("event", "comet_warning", {})


func _emp(r: Racer) -> void:
	var fx := _fx()
	var hit_list: Array[Racer] = []
	for o: Racer in race.racers:
		if o == r or o.is_ghost or o.finished:
			continue
		if o.global_position.distance_to(r.global_position) < EMP_RADIUS:
			var shielded := o.shield_time > 0.0
			if o.hit(r, "emp"):
				hit_list.append(o)
				if fx:
					fx.sparks(o.global_position + o.up * 0.6, o.up, EMP_C, 22, 9.0)
				if o.item != "" and not shielded:
					o.item = ""
					o.item_uses = 0
					o.emit_signal("event", "item_lost", {})
	# Expanding electric dome, a ground shockwave, and bolts to every victim.
	var dome := _take("dome")
	_place(dome, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.5), r.global_position))
	beams.append({"node": dome, "t": 0.5, "life": 0.5, "kind": "emp", "at": r.global_position})
	if fx:
		fx.shockwave(r.global_position, r.up, EMP_C, EMP_RADIUS * 2.2, 0.5)
		fx.flash(r.global_position + r.up * 0.8, EMP_C, 7.0, 0.25)
	for o in hit_list:
		var bolt := _take("bolt")
		beams.append({"node": bolt, "t": 0.4, "life": 0.4, "kind": "bolt", "from": r, "to": o, "jit": 0.0})
	race.shake_near(r.global_position, 0.35)


func _nitro(r: Racer) -> void:
	var fx := _fx()
	if fx:
		fx.shockwave(r.global_position, r.up, NITRO_C, 8.0, 0.4)
		fx.flash(r.global_position - r.heading * 2.2, NITRO_C, 3.0, 0.2)
	if r.model == null or r.model.pivot == null:
		return
	for n in nitros:
		if n.r == r:
			return
	# Strap-on boosters either side of the craft for the length of the boost.
	var holder := _take("boosters")
	remove_child(holder)
	r.model.pivot.add_child(holder)
	holder.transform = Transform3D.IDENTITY
	var rim: float = r.model.rim_r
	for sx: float in [-1.0, 1.0]:
		var bst := holder.get_node("L" if sx < 0.0 else "R") as Node3D
		bst.position = Vector3(sx * rim * 0.62, r.model.top_y + 0.25, 0.5)
		bst.scale = Vector3.ONE * 1.4
	nitros.append({"r": r, "node": holder, "t": 0.0})


func _mine(r: Racer) -> void:
	var path := td.main
	var pos := r.global_position - r.heading * 4.0
	var i := path.nearest(pos, r.track_idx, 8)
	pos = path.pts[i] + path.rgt[i] * clampf(path.lateral(i, pos), -td.width * 0.45, td.width * 0.45) + path.upv[i] * 0.7
	var node := _place(_take("mine"), Transform3D(Basis(path.rgt[i], path.upv[i], -path.tan[i]).scaled(Vector3.ONE * 1.3), pos))
	var ring := node.get_node("Ring") as Node3D
	ring.scale = Vector3.ONE * 0.1
	mines.append({"pos": pos, "s": float(i) * path.step, "lane": path.lateral(i, pos), "owner": r, "arm": 0.5, "life": MINE_LIFE, "node": node, "near": {}, "t": 0.0})
	while mines.size() > MAX_MINES:
		var old: Dictionary = mines.pop_front()
		_give("mine", old.node)


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
	# The beam's energy bands flow from the target back to you.
	var node := _take("tractor")
	_place(node, Transform3D(Basis.IDENTITY, r.global_position))
	var fx := _fx()
	if fx:
		fx.flash(r.global_position + r.up * 0.6, TRACTOR_C, 3.0, 0.25)
		fx.flash(t.global_position + t.up * 0.6, TRACTOR_C, 4.0, 0.3)
	beams.append({"from": r, "to": t, "t": TRACTOR_TIME, "life": TRACTOR_TIME, "node": node, "kind": "tractor"})


func _flash(pos: Vector3, c: Color, secs := 0.35) -> void:
	var fx := _fx()
	if fx:
		fx.flash(pos, c, 4.0, secs)


# ---------------------------------------------------------------- live effects
func tick(dt: float) -> void:
	_tick_rockets(dt)
	_tick_mines(dt)
	_tick_comets(dt)
	_tick_beams(dt)
	_tick_nitros(dt)
	for r: Racer in race.racers:
		if r.item != "" and r.item_roll <= 0.0:
			_hold[r.idx] = _hold.get(r.idx, 0.0) + dt
		_tick_badge(r, dt)


## A held Ion Shield shows as a little hex badge circling the craft.
func _tick_badge(r: Racer, dt: float) -> void:
	var want := r.item == "shield" and r.item_roll <= 0.0 and r.shield_time <= 0.0 and not r.is_ghost
	var b: Node3D = _badges.get(r.idx, null)
	if not want:
		if b:
			b.visible = false
		return
	if b == null or not is_instance_valid(b):
		b = ItemModels.shield_badge()
		r.add_child(b)
		_badges[r.idx] = b
	b.visible = true
	b.rotate_y(dt * 3.0)


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
		var node: Node3D = b.node
		node.global_transform = Transform3D(_basis_y(dir).rotated(dir, b.life * 6.0).scaled(Vector3.ONE * 1.5), b.pos)
		var fl := node.get_node_or_null("Flame") as Node3D
		if fl:
			fl.scale = Vector3(0.2, 1.4 * (0.85 + 0.3 * sin(b.life * 60.0)), 0.2)
		var ret: Node3D = b.reticle
		if ret and t:
			ret.global_position = t.global_position + t.up * 2.6
			ret.visible = t.rescue_time <= 0.0
		var done: bool = b.life <= 0.0
		for r: Racer in race.racers:
			if r == b.owner and b.life > ROCKET_LIFE - 0.5:
				continue
			if r.is_ghost:
				continue
			var d := r.global_position.distance_to(b.pos)
			if d < 2.4:
				r.hit(b.owner, "rocket")
				_boom(b.pos, ROCKET_C, 1.0, r.up)
				race.shake_near(b.pos, 0.4)
				done = true
				break
			elif d < 5.0:
				b.near[r.idx] = true
			elif b.near.has(r.idx) and r != b.owner:
				b.near.erase(r.idx)
				r.near_miss()
		if b.life <= 0.0 and not done:
			_boom(b.pos, ROCKET_C, 0.6)
		if done or b.life <= 0.0:
			_give("rocket", node)
			if ret:
				_give("reticle_air", ret)
			rockets.remove_at(k)


func _tick_mines(dt: float) -> void:
	for k in range(mines.size() - 1, -1, -1):
		var m: Dictionary = mines[k]
		m.arm -= dt
		m.life -= dt
		m.t += dt
		var node: Node3D = m.node
		node.rotate_object_local(Vector3.UP, dt * 2.0)
		# Arming: the gravity field grows; armed: it pulses and the light blinks.
		var ring := node.get_node("Ring") as Node3D
		var armed: bool = m.arm <= 0.0
		ring.scale = Vector3.ONE * (lerpf(0.1, 1.0, clampf(1.0 - float(m.arm) / 0.5, 0.0, 1.0)) if not armed else 1.0 + 0.12 * sin(float(m.t) * 8.0))
		(node.get_node("Light") as Node3D).visible = not armed or int(float(m.t) * 4.0) % 2 == 0
		var gone: bool = m.life <= 0.0
		if armed:
			for r: Racer in race.racers:
				if r.is_ghost or (r == m.owner and m.arm > -0.8):
					continue
				var d := r.global_position.distance_to(m.pos)
				if d < 2.5:
					r.hit(m.owner, "mine")
					_boom(m.pos, MINE_C, 1.0, r.up)
					race.shake_near(m.pos, 0.35)
					gone = true
					break
				elif d < 5.0:
					m.near[r.idx] = true
				elif m.near.has(r.idx):
					m.near.erase(r.idx)
					r.near_miss()
		if gone:
			_give("mine", node)
			mines.remove_at(k)


func _tick_comets(dt: float) -> void:
	for k in range(comets.size() - 1, -1, -1):
		var m: Dictionary = comets[k]
		m.t -= dt
		var t: Racer = m.target
		if m.t > 0.25:
			m.pos = t.global_position
		var ring: Node3D = m.ring
		ring.global_transform = Transform3D(Basis(t.heading.cross(t.up).normalized(), t.up, -t.heading).scaled(Vector3.ONE * (0.6 + 0.6 * float(m.t) / COMET_WARN)), m.pos + t.up * 0.3)
		var fall := clampf(1.0 - m.t / 0.7, 0.0, 1.0)
		var rp: Vector3 = m.pos + Vector3.UP * lerpf(90.0, 0.0, fall) + Vector3(0, 0, lerpf(-40.0, 0.0, fall))
		var rock: Node3D = m.rock
		var showing: bool = m.t < 0.7
		if showing and not rock.visible:
			rock.visible = true
			rock.global_position = rp
			rock.reset_physics_interpolation()
		var vel := Vector3(0, -90.0, 40.0).normalized()
		rock.global_transform = Transform3D(_basis_y(-vel), rp)
		if m.t <= 0.0:
			_boom(m.pos, COMET_C, 1.7)
			var fx := _fx()
			if fx:
				fx.sparks(m.pos + Vector3.UP, Vector3.UP, Color(0.85, 0.95, 1.0), 40, 18.0, 16.0)
			for r: Racer in race.racers:
				if r.is_ghost:
					continue
				var d := r.global_position.distance_to(m.pos)
				if d < 6.0:
					r.hit(m.owner, "comet")
				elif d < 10.0:
					r.near_miss()
			_give("reticle_ground", ring)
			_give("comet", rock)
			comets.remove_at(k)
			race.shake_all(0.5)


func _tick_beams(dt: float) -> void:
	for k in range(beams.size() - 1, -1, -1):
		var b: Dictionary = beams[k]
		b.t -= dt
		var node: Node3D = b.node
		var f := clampf(float(b.t) / float(b.life), 0.0, 1.0)
		match String(b.kind):
			"tractor":
				var a: Vector3 = b.from.global_position + b.from.up * 0.4
				var c: Vector3 = b.to.global_position + b.to.up * 0.4
				var len := a.distance_to(c)
				if len > 0.5:
					var y := (c - a) / len
					var bb := _basis_y(y)
					var w := 0.6 + 0.4 * sin(float(b.t) * 18.0)
					node.global_transform = Transform3D(Basis(bb.x * w, y * len, bb.z * w), (a + c) * 0.5)
					if b.get("fresh", true):
						b.fresh = false
						node.reset_physics_interpolation()
				if b.to.tractor_time <= 0.0:
					b.t = 0.0
			"emp":
				var s := lerpf(EMP_RADIUS, 0.5, f)
				node.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(s, s * 0.6, s)), b.at)
				var m := (node as MeshInstance3D).material_override as ShaderMaterial
				m.set_shader_parameter("power", f * 1.6)
			"bolt":
				b.jit -= dt
				if b.jit <= 0.0:
					b.jit = 0.05
					ItemModels.set_bolt(node, b.from.global_position + b.from.up * 0.8, b.to.global_position + b.to.up * 0.8, _rng, 1.1)
					if b.get("fresh", true):
						b.fresh = false
						node.reset_physics_interpolation()
				node.visible = int(float(b.t) * 30.0) % 3 != 0
			"laser":
				var w := clampf(f * 1.2, 0.05, 1.0)
				var bb := _basis_y(b.dir)
				node.global_transform = Transform3D(Basis(bb.x * w, b.dir * float(b.reach), bb.z * w), b.origin + b.dir * float(b.reach) * 0.5)
		if b.t <= 0.0:
			_give(String(b.kind), node)
			beams.remove_at(k)


## Nitro boosters stay strapped on while the nitro boost lasts.
func _tick_nitros(dt: float) -> void:
	for k in range(nitros.size() - 1, -1, -1):
		var n: Dictionary = nitros[k]
		var r: Racer = n.r
		n.t += dt
		var live := is_instance_valid(r) and r.boost_time > 0.0 and r.boost_kind == "nitro"
		if not live:
			_give("boosters", n.node)
			nitros.remove_at(k)
			continue
		for bst in (n.node as Node3D).get_children():
			var fl := (bst as Node3D).get_node_or_null("Flame") as Node3D
			if fl:
				fl.scale = Vector3(0.17, 2.2 * (0.8 + 0.35 * sin(float(n.t) * 55.0 + float(k))), 0.17)


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
