class_name Items
extends Node3D
## The fourteen power-ups: rolling them from crates (by position lineup),
## using them, and the live effects they leave in the world. Also answers AI
## questions about items.
##   rocket     Homing Rocket - chases the racer just ahead
##   laser      Pulse Laser   - instant beam, hits everything in a line ahead
##   comet      Comet Strike  - falls on the leader (back-of-the-pack only)
##   emp        EMP Shockwave - spins out everyone close and knocks items loose
##   nitro      Nitro Rocket  - 1-3 boosts depending on your lineup
##   shield     Ion Shield    - use: 6 s bubble; hold: blocks one hit
##   mine       Gravity Mine  - dropped behind
##   tractor    Tractor Beam  - drags the racer ahead back
##   warp       Warp Jump     - teleports 40-80 m down the track (more from the back)
##   decoy      Decoy Drone   - hologram behind you; rockets and tractors take it
##   leech      Energy Leech  - 5 s aura draining nearby racers' Dark Matter to you
##   well       Gravity Well  - vortex dropped behind: drags racers in, slows them
##   frost      Frost Trail   - 4 s of comet ice behind you; anyone on it slides
##   overcharge Overcharge    - burns 60% of your core for up to 3 s of boost
##   flare      Solar Flare   - blinds every racer ahead within 70 m for 2 s
##   chain      Chain Lightning - bolt hops racer to racer, up to three hits
##   plasma     Plasma Wall   - wall across half the road behind you for 6 s
##   stasis     Stasis Field  - 3 s: everyone within 22 m held near half speed
##   cloak      Phase Cloak   - 5 s untouchable, untargetable, through traps
##   repulsor   Repulsor Pulse - shoves everyone within 12 m away, hard

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
const WARP_MIN := 40.0
const WARP_MAX := 80.0
const DECOY_TIME := 8.0
const LEECH_TIME := 5.0
const LEECH_RADIUS := 14.0
const LEECH_RATE := 9.0        # Dark Matter per second taken from each victim
const WELL_TIME := 7.0
const WELL_RADIUS := 11.0
const WELL_PULL := 16.0
const FROST_TIME := 4.0
const FROST_GAP := 3.0         # metres between ice patches
const ICE_LIFE := 9.0
const ICE_RADIUS := 2.3
const MAX_ICE := 64
const OVERCHARGE_MAX := 3.0
const FLARE_RANGE := 70.0
const FLARE_TIME := 2.4
const CHAIN_RANGE := 60.0
const CHAIN_HOP := 40.0
const CHAIN_MAX := 3
const PLASMA_TIME := 6.0
const PLASMA_HITS := 3         # bounces a wall takes before it shatters
const STASIS_TIME := 3.0
const STASIS_RADIUS := 22.0
const CLOAK_TIME := 5.0
const REPULSOR_RADIUS := 12.0
const REPULSOR_KICK := 26.0

var race: Node
var td: TrackData
var rockets: Array[Dictionary] = []
var mines: Array[Dictionary] = []
var comets: Array[Dictionary] = []
var beams: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var nitros: Array[Dictionary] = []
var decoys: Array[Dictionary] = []
var leeches: Array[Dictionary] = []
var wells: Array[Dictionary] = []
var frosts: Array[Dictionary] = []   # trails still being laid
var ice: Array[Dictionary] = []      # ice patches on the road
var _ice_mm: MultiMeshInstance3D = null
var _ice_free: Array[int] = []
var _frost_cd := {}            # racer idx -> seconds until the next ICE toast
var plasmas: Array[Dictionary] = []
var stases: Array[Dictionary] = []
var _wall_cd := {}             # racer idx -> seconds before a plasma wall can bounce them again
var only_item := ""            # daily-challenge modifier: crates give only this
var _rng := RandomNumberGenerator.new()
var _hold := {}                # racer idx -> seconds holding the item
var _badges := {}              # racer idx -> held-shield badge node
## Effect nodes are built once at race load and reused (no mesh building or
## shader compiling mid-race, which caused a hitch the first time each
## power-up fired). Pooled nodes stay in the tree, hidden.
var _pool := {}                # kind -> Array[Node3D]
## Sized for the most the game allows at once (smaller pools built new
## nodes mid-race: a hitch on phones).
const POOL_SIZES := {"rocket": 6, "reticle_air": 6, "reticle_ground": 2, "comet": 2, "laser": 3, "tractor": 2,
	"dome": 3, "bolt": 8, "boosters": 2, "mine": MAX_MINES,
	"portal": 4, "decoy": 2, "leech_aura": 2, "leech_beam": 6, "well": 4, "charge_dome": 2,
	"flare_orb": 2, "chain_bolt": 6, "plasma_wall": 4, "stasis_dome": 2, "repulsor_dome": 2}

const ROCKET_C := Color(1.0, 0.5, 0.2)
const LASER_C := Color(0.3, 1.0, 0.95)
const COMET_C := Color(0.55, 0.85, 1.0)
const EMP_C := Color(1.0, 0.92, 0.35)
const NITRO_C := Color(1.0, 0.35, 0.8)
const SHIELD_C := Color(0.35, 0.8, 1.0)
const MINE_C := Color(1.0, 0.8, 0.2)
const TRACTOR_C := Color(0.45, 1.0, 0.5)
const WARP_C := Color(0.6, 0.45, 1.0)
const DECOY_C := Color(0.5, 0.95, 1.0)
const LEECH_C := Color(0.72, 0.3, 1.0)
const WELL_C := Color(0.55, 0.3, 1.0)
const FROST_C := Color(0.75, 0.95, 1.0)
const OVERCHARGE_C := Color(1.0, 0.6, 0.15)
const FLARE_C := Color(1.0, 0.95, 0.6)
const CHAIN_C := Color(0.6, 0.9, 1.0)
const PLASMA_C := Color(1.0, 0.3, 0.75)
const STASIS_C := Color(0.3, 0.95, 0.85)
const CLOAK_C := Color(0.8, 0.7, 1.0)
const REPULSOR_C := Color(1.0, 0.45, 0.2)


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
	_build_ice()


## Frost Trail ice patches share one MultiMesh; free slots are scaled away.
func _build_ice() -> void:
	_ice_mm = MultiMeshInstance3D.new()
	_ice_mm.name = "Ice"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ItemModels.ice_mesh()
	mm.instance_count = MAX_ICE
	_ice_free.clear()
	for k in MAX_ICE:
		mm.set_instance_transform(k, _ice_hidden())
		_ice_free.append(k)
	_ice_mm.multimesh = mm
	_ice_mm.material_override = ItemModels.ice_material()
	_ice_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ice_mm)


static func _ice_hidden() -> Transform3D:
	return Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -50.0, 0))


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
		"portal":
			return ItemModels.portal()
		"decoy":
			return ItemModels.decoy()
		"leech_aura":
			return ItemModels.dome(LEECH_C)
		"leech_beam":
			return ItemModels.beam_set(LEECH_C, 0.8, -10.0)
		"well":
			return ItemModels.well()
		"charge_dome":
			return ItemModels.dome(OVERCHARGE_C)
		"flare_orb":
			return ItemModels.orb(FLARE_C, 4.0)
		"chain_bolt":
			return ItemModels.bolt(CHAIN_C, 8)
		"plasma_wall":
			return ItemModels.plasma_wall(PLASMA_C)
		"stasis_dome":
			return ItemModels.dome(STASIS_C)
		"repulsor_dome":
			return ItemModels.dome(REPULSOR_C)
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


## Remove every live effect and return its nodes to the pools (tests,
## restarts).
func clear_effects() -> void:
	for b in rockets:
		_give("rocket", b.node)
		if b.reticle:
			_give("reticle_air", b.reticle)
	rockets.clear()
	for m in mines:
		_give("mine", m.node)
	mines.clear()
	for m in comets:
		_give("reticle_ground", m.ring)
		_give("comet", m.rock)
	comets.clear()
	for b in beams:
		_give(String(b.get("pool", b.kind)), b.node)
	beams.clear()
	for n in nitros:
		_give("boosters", n.node)
	nitros.clear()
	for d in decoys:
		_give("decoy", d.node)
	decoys.clear()
	for L in leeches:
		for idx in L.links:
			_give("leech_beam", L.links[idx])
		_give("leech_aura", L.aura)
	leeches.clear()
	for w in wells:
		_give("well", w.node)
	wells.clear()
	for pw in plasmas:
		_give("plasma_wall", pw.node)
	plasmas.clear()
	for st in stases:
		_give("stasis_dome", st.node)
	stases.clear()
	_wall_cd.clear()
	frosts.clear()
	for p in ice:
		_ice_mm.multimesh.set_instance_transform(int(p.slot), _ice_hidden())
		_ice_free.append(int(p.slot))
	ice.clear()
	_frost_cd.clear()


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
	if _ice_mm:
		_ice_mm.multimesh.set_instance_transform(0, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.02), cam.global_position - cam.global_transform.basis.z * 3.0))
	var tree := get_tree()
	for i in 3:
		await tree.process_frame
		if not is_inside_tree():
			return   # the race ended during the warm-up
	for sn in shown:
		_give(sn[0], sn[1])
	if _ice_mm and ice.is_empty():
		_ice_mm.multimesh.set_instance_transform(0, _ice_hidden())


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
	if r.crate_luck > 0:
		pl = mini(n, pl + r.crate_luck)
	return Catalog.lineup_for(pl, n)


## Roll an item for a racer and set how many uses it has.
func roll(r: Racer) -> String:
	# A fresh item starts a fresh hold timer (an item lost to an EMP or a
	# rocket left the old one running, so the AI dumped its next item).
	_hold.erase(r.idx)
	var lu := lineup_of(r)
	var it := only_item
	if OS.get_environment("CSD_ONLY") != "":
		it = OS.get_environment("CSD_ONLY")   # test hook: every crate gives this item
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
			r.shield_time = race.tuning.shield_time * r.shield_time_mult
			var fx := _fx()
			if fx:
				fx.flash(r.global_position + r.up * 0.6, SHIELD_C, 6.0, 0.3)
				fx.shockwave(r.global_position, r.up, SHIELD_C, 7.0, 0.4)
		"mine":
			_mine(r)
		"tractor":
			_tractor(r)
		"warp":
			_warp(r)
		"decoy":
			_decoy(r)
		"leech":
			_leech(r)
		"well":
			_well(r)
		"frost":
			_frost(r)
		"overcharge":
			_overcharge(r)
		"flare":
			_flare(r)
		"chain":
			_chain(r)
		"plasma":
			_plasma(r)
		"stasis":
			_stasis(r)
		"cloak":
			_cloak(r)
		"repulsor":
			_repulsor(r)
	r.emit_signal("event", "item_used", {"item": it})


func _ahead_of(r: Racer, max_dist: float) -> Racer:
	var best: Racer = null
	var best_d := INF
	for o: Racer in race.racers:
		if o == r or o.finished or o.is_ghost or o.cloak_time > 0.0:
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
	var dec := _decoy_of(t)
	if t:
		ret = _place(_take("reticle_air"), Transform3D(Basis.IDENTITY, (dec.pos if not dec.is_empty() else t.global_position) + t.up * 2.6))
		if dec.is_empty():
			t.emit_signal("event", "rocket_lock", {"by": r})
	var fx := _fx()
	if fx:
		fx.flash(pos, ROCKET_C, 2.6, 0.18)
	var spd := maxf(ROCKET_SPEED, r.velocity.length() + 25.0)
	rockets.append({"pos": pos, "vel": r.heading * spd, "owner": r, "target": t, "decoy": dec, "life": ROCKET_LIFE, "node": node, "reticle": ret, "i": r.track_idx, "near": {}})


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
	for k in range(wells.size() - 1, -1, -1):
		var w: Dictionary = wells[k]
		var d: Vector3 = w.pos - origin
		var along := d.dot(dir)
		if along > 0.0 and along < LASER_RANGE and (d - dir * along).length() < 3.5:
			_boom(w.pos, WELL_C, 1.0)
			_give("well", w.node)
			wells.remove_at(k)
	for k in range(plasmas.size() - 1, -1, -1):
		var pw: Dictionary = plasmas[k]
		var d: Vector3 = pw.pos - origin
		var along := d.dot(dir)
		if along > 0.0 and along < LASER_RANGE and (d - dir * along).length() < float(pw.half) + 1.0:
			_boom(pw.pos, PLASMA_C, 1.0, pw.up)
			_give("plasma_wall", pw.node)
			plasmas.remove_at(k)
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
	# The leader among racers still racing (once the winner has finished,
	# "place 1" was a finished racer and the strike fizzled).
	var target: Racer = null
	for o: Racer in race.racers:
		if o == r or o.finished or o.is_ghost:
			continue
		if target == null or o.place < target.place:
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
	beams.append({"node": dome, "t": 0.5, "life": 0.5, "kind": "emp", "pool": "dome", "at": r.global_position})
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
	var dec := _decoy_of(t)
	if not dec.is_empty():
		# The beam grabs the hologram instead and pops it.
		var dn := _take("tractor")
		_place(dn, Transform3D(Basis.IDENTITY, r.global_position))
		beams.append({"from": r, "to_pos": dec.pos, "t": 0.35, "life": 0.35, "node": dn, "kind": "tractor"})
		_pop_decoy(dec)
		r.give_boost(0.5, "tractor")
		return
	if not t.can_be_hit():
		if t.shield_time > 0.0:
			t.emit_signal("event", "blocked", {"kind": "tractor"})   # "Shield blocked it" only for a shield
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


## Warp Jump: 40 m from the front, 80 m from the back, with a portal at
## each end.
func _warp(r: Racer) -> void:
	var n := 0
	for o: Racer in race.racers:
		if not o.is_ghost:
			n += 1
	var metres := lerpf(WARP_MIN, WARP_MAX, clampf(float(r.place - 1) / maxf(1.0, float(n - 1)), 0.0, 1.0))
	var from := r.global_position + r.up * 1.2
	beams.append({"node": _place(_take("portal"), Transform3D(Basis.IDENTITY, from)), "kind": "portal", "t": 0.55, "life": 0.55})
	r.warp_ahead(metres)
	beams.append({"node": _place(_take("portal"), Transform3D(Basis.IDENTITY, r.global_position + r.up * 1.2)), "kind": "portal", "t": 0.7, "life": 0.7})
	race.shake_near(from, 0.2)


## Decoy Drone: a hologram trails you for 8 s; rockets already locked on
## you switch to it.
func _decoy(r: Racer) -> void:
	var pos := r.global_position - r.heading * 7.0 + r.up * 0.3
	var node := _place(_take("decoy"), Transform3D(Basis(r.heading.cross(r.up).normalized(), r.up, -r.heading), pos))
	var dec := {"owner": r, "node": node, "pos": pos, "t": DECOY_TIME, "live": true}
	decoys.append(dec)
	for b in rockets:
		if b.target == r and (b.decoy as Dictionary).is_empty():
			b.decoy = dec
	var fx := _fx()
	if fx:
		fx.flash(pos + r.up * 0.6, DECOY_C, 4.0, 0.25)
		fx.sparks(pos + r.up * 0.4, r.up, DECOY_C, 16, 6.0, 2.0)


## The live decoy guarding this racer, or {}.
func _decoy_of(r: Racer) -> Dictionary:
	if r == null:
		return {}
	for d in decoys:
		if d.owner == r and d.live:
			return d
	return {}


func _pop_decoy(dec: Dictionary) -> void:
	if not dec.get("live", false):
		return
	dec.live = false
	dec.t = 0.0
	var owner: Racer = dec.owner
	_boom(dec.pos, DECOY_C, 0.8, owner.up)
	owner.emit_signal("event", "decoy_popped", {"pos": dec.pos})


## Energy Leech: a 5 s aura; beams latch on to up to three racers in range
## and pour their Dark Matter into your core.
func _leech(r: Racer) -> void:
	var aura := _place(_take("leech_aura"), Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 2.6), r.global_position + r.up * 0.5))
	(aura as MeshInstance3D).material_override.set_shader_parameter("power", 0.9)
	leeches.append({"r": r, "t": LEECH_TIME, "aura": aura, "links": {}})
	var fx := _fx()
	if fx:
		fx.shockwave(r.global_position, r.up, LEECH_C, 9.0, 0.4)
		fx.flash(r.global_position + r.up * 0.6, LEECH_C, 4.5, 0.25)
	if r.model:
		r.model.react("leech")


## Gravity Well: a vortex dropped on the road behind you.
func _well(r: Racer) -> void:
	var path := td.main
	var pos := r.global_position - r.heading * 6.0
	var i := path.nearest(pos, r.track_idx, 8)
	var lane := clampf(path.lateral(i, pos), -td.width * 0.4, td.width * 0.4)
	pos = path.pts[i] + path.rgt[i] * lane + path.upv[i] * 0.3
	var node := _place(_take("well"), Transform3D(Basis(path.rgt[i], path.upv[i], -path.tan[i]).scaled(Vector3.ONE * 0.2), pos))
	wells.append({"pos": pos, "s": float(i) * path.step, "lane": lane, "up": path.upv[i], "owner": r, "t": WELL_TIME, "age": 0.0, "node": node, "near": {}})
	var fx := _fx()
	if fx:
		fx.shockwave(pos, path.upv[i], WELL_C, 12.0, 0.5)
		fx.flash(pos + path.upv[i] * 0.8, WELL_C, 4.0, 0.3)
	while wells.size() > 4:
		var old: Dictionary = wells.pop_front()
		_give("well", old.node)


## Frost Trail: ice patches are laid behind you for 4 s as you drive.
func _frost(r: Racer) -> void:
	for f in frosts:
		if f.r == r:
			f.t = FROST_TIME
			return
	frosts.append({"r": r, "t": FROST_TIME, "last": r.race_dist - FROST_GAP})
	var fx := _fx()
	if fx:
		fx.dust(r.global_position - r.up * 0.5, r.up, FROST_C, 20)


func _lay_ice(r: Racer) -> void:
	var path := td.main
	var pos := r.global_position - r.heading * 2.5
	var i := path.nearest(pos, r.track_idx, 6)
	if td.gap[i] == 1:
		return
	var lane := clampf(path.lateral(i, pos), -td.width * 0.48, td.width * 0.48)
	pos = path.pts[i] + path.rgt[i] * lane + path.upv[i] * 0.12
	if _ice_free.is_empty():
		var old: Dictionary = ice.pop_front()
		_ice_free.append(int(old.slot))
	var slot: int = _ice_free.pop_back()
	var b := Basis(path.rgt[i], path.upv[i], -path.tan[i]).rotated(path.upv[i], _rng.randf() * TAU)
	var xf := Transform3D(b.scaled(Vector3(2.6, 1.1, 2.6)), pos)
	_ice_mm.multimesh.set_instance_transform(slot, xf)
	ice.append({"pos": pos, "s": float(i) * path.step, "lane": lane, "owner": r, "life": ICE_LIFE, "age": 0.0, "slot": slot, "xf": xf})
	var fx := _fx()
	if fx and _rng.randf() < 0.5:
		fx.dust(pos, path.upv[i], FROST_C, 8)


## Overcharge: burn 60% of the core for a boost that lasts longer the fuller
## the core was (0.5-3 s).
func _overcharge(r: Racer) -> void:
	var frac := clampf(r.energy / maxf(r.T.energy_max, 1.0), 0.0, 1.0)
	var secs := 0.5 + (OVERCHARGE_MAX - 0.5) * frac
	r.energy = maxf(0.0, r.energy * 0.4)
	r.give_boost(secs, "overcharge")
	var dome := _place(_take("charge_dome"), Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 2.4), r.global_position + r.up * 0.4))
	beams.append({"node": dome, "kind": "charge_dome", "t": secs, "life": secs, "r": r})
	r.emit_signal("event", "overcharge", {"secs": secs})


## Solar Flare: blinds everyone ahead of you (in front, within range).
func _flare(r: Racer) -> void:
	var fx := _fx()
	var origin := r.global_position + r.up * 1.8 + r.heading * 2.0
	if fx:
		fx.flash(origin, FLARE_C.lerp(Color.WHITE, 0.5), 16.0, 0.5)
		fx.shockwave(r.global_position, r.up, FLARE_C, 14.0, 0.5)
	var orb := _place(_take("flare_orb"), Transform3D(Basis.IDENTITY, origin))
	beams.append({"node": orb, "kind": "flare_orb", "t": 0.7, "life": 0.7})
	for o: Racer in race.racers:
		if o == r or o.is_ghost or o.finished:
			continue
		var d := o.global_position - r.global_position
		if d.dot(r.heading) < 0.0 or d.length() > FLARE_RANGE:
			continue
		if not o.can_be_hit():
			if o.shield_time > 0.0:
				o.emit_signal("event", "blocked", {"kind": "flare"})
			continue
		o.flare_time = FLARE_TIME
		o.emit_signal("event", "flared", {"by": r})
		r.stats.hits += 1
		r.emit_signal("event", "hit_landed", {"target": o, "kind": "flare"})
	race.shake_near(r.global_position, 0.2)


## Chain Lightning: hits the racer ahead, then leaps on to whoever is
## nearest them, up to three hits.
func _chain(r: Racer) -> void:
	var fx := _fx()
	var cur: Racer = r
	var t := _ahead_of(r, CHAIN_RANGE)
	var struck: Array[Racer] = []
	var hops := 0
	while t != null and hops < CHAIN_MAX:
		var bolt := _take("chain_bolt")
		ItemModels.set_bolt(bolt, cur.global_position + cur.up * 0.8, t.global_position + t.up * 0.8, _rng, 1.3)
		bolt.reset_physics_interpolation()
		beams.append({"node": bolt, "t": 0.45, "life": 0.45, "kind": "chain_bolt", "from": cur, "to": t, "jit": 0.0, "fresh": false})
		if t.hit(r, "chain") and fx:
			fx.sparks(t.global_position + t.up * 0.6, t.up, CHAIN_C, 24, 10.0)
		t.emit_signal("event", "chained", {"by": r})
		struck.append(t)
		cur = t
		hops += 1
		# Next hop: the nearest racer to the last one struck, not yet hit.
		t = null
		var best := CHAIN_HOP
		for o: Racer in race.racers:
			if o == r or o.is_ghost or o.finished or o.cloak_time > 0.0 or o in struck:
				continue
			var d := o.global_position.distance_to(cur.global_position)
			if d < best:
				best = d
				t = o
	if hops == 0 and fx:
		# Nothing in reach: the bolt crackles off the nose.
		var bolt := _take("chain_bolt")
		var tip := r.global_position + r.heading * 14.0 + r.up * 0.8
		ItemModels.set_bolt(bolt, r.global_position + r.up * 0.8, tip, _rng, 1.3)
		bolt.reset_physics_interpolation()
		beams.append({"node": bolt, "t": 0.3, "life": 0.3, "kind": "chain_bolt", "from": r, "to_pos": tip, "jit": 0.0, "fresh": false})
		fx.flash(r.global_position + r.heading * 3.0 + r.up * 0.8, CHAIN_C, 3.0, 0.2)


## Plasma Wall: a shield slab across your half of the road, behind you.
func _plasma(r: Racer) -> void:
	var path := td.main
	var pos := r.global_position - r.heading * 7.0
	var i := path.nearest(pos, r.track_idx, 8)
	var half := td.width * 0.27
	var lane := clampf(path.lateral(i, pos), -td.width * 0.5 + half, td.width * 0.5 - half)
	pos = path.pts[i] + path.rgt[i] * lane + path.upv[i] * 1.6
	var node := _take("plasma_wall")
	var frame := Basis(path.rgt[i], path.upv[i], -path.tan[i])
	_place(node, Transform3D(TrackBuilder.sb(frame, Vector3(half * 2.0, 3.4 * 0.05, 0.5)), pos))
	plasmas.append({"pos": pos, "s": float(i) * path.step, "lane": lane, "half": half, "fwd": path.tan[i], "rgt": path.rgt[i], "up": path.upv[i], "frame": frame, "owner": r, "t": PLASMA_TIME, "age": 0.0, "node": node, "hp": PLASMA_HITS})
	var fx := _fx()
	if fx:
		fx.flash(pos, PLASMA_C, 6.0, 0.3)
		fx.sparks(pos, path.upv[i], PLASMA_C, 20, 8.0, 4.0)
	while plasmas.size() > 4:
		var old: Dictionary = plasmas.pop_front()
		_give("plasma_wall", old.node)


## Stasis Field: a dome around you that holds everyone inside it slow.
func _stasis(r: Racer) -> void:
	var dome := _place(_take("stasis_dome"), Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.5), r.global_position + r.up * 0.5))
	stases.append({"r": r, "t": STASIS_TIME, "node": dome, "near": {}})
	var fx := _fx()
	if fx:
		fx.shockwave(r.global_position, r.up, STASIS_C, STASIS_RADIUS * 2.0, 0.6)
		fx.flash(r.global_position + r.up * 0.8, STASIS_C, 6.0, 0.3)


## Phase Cloak: out of phase for five seconds; locked rockets lose you.
func _cloak(r: Racer) -> void:
	r.cloak_time = CLOAK_TIME
	for b in rockets:
		if b.target == r:
			b.target = null
			if b.reticle:
				_give("reticle_air", b.reticle)
				b.reticle = null
	r.emit_signal("event", "cloaked", {})


## Repulsor Pulse: a hard shove on everyone close by.
func _repulsor(r: Racer) -> void:
	var fx := _fx()
	for o: Racer in race.racers:
		if o == r or o.is_ghost or o.finished or o.cloak_time > 0.0 or o.rescue_time > 0.0:
			continue
		var dv := o.global_position - r.global_position
		var d := dv.length()
		if d >= REPULSOR_RADIUS:
			continue
		# Same rule as every other item: a raised shield blocks it, and a
		# racer already spinning or briefly invulnerable isn't hit again
		# (it used to shove them and count a hit anyway).
		if not o.can_be_hit():
			if o.shield_time > 0.0:
				o.emit_signal("event", "blocked", {"kind": "repulsor"})
			continue
		dv -= o.up * dv.dot(o.up)
		if dv.length() < 0.2:
			dv = o.up.cross(r.heading)
		var away := dv.normalized()
		var kick := REPULSOR_KICK * (1.0 - 0.5 * d / REPULSOR_RADIUS) * (0.5 if o.shield_time > 0.0 else 1.0)
		o.velocity += away * kick
		o.wobble_time = maxf(o.wobble_time, 0.6)
		o.emit_signal("event", "repulsed", {"by": r})
		r.stats.hits += 1
		r.emit_signal("event", "hit_landed", {"target": o, "kind": "repulsor"})
	var dome := _take("repulsor_dome")
	_place(dome, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.5), r.global_position))
	beams.append({"node": dome, "t": 0.4, "life": 0.4, "kind": "repulsor_dome", "at": r.global_position})
	if fx:
		fx.shockwave(r.global_position, r.up, REPULSOR_C, REPULSOR_RADIUS * 2.2, 0.4)
		fx.flash(r.global_position + r.up * 0.8, REPULSOR_C, 6.0, 0.25)
	race.shake_near(r.global_position, 0.3)


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
	_tick_decoys(dt)
	_tick_leeches(dt)
	_tick_wells(dt)
	_tick_frost(dt)
	_tick_plasma(dt)
	_tick_stasis(dt)
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
		var dec: Dictionary = b.decoy
		var on_decoy: bool = not dec.is_empty() and bool(dec.live)
		var aim: Vector3
		if on_decoy:
			aim = dec.pos
		elif t and not t.finished and t.rescue_time <= 0.0:
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
			ret.global_position = (dec.pos if on_decoy else t.global_position) + t.up * 2.6
			ret.visible = on_decoy or t.rescue_time <= 0.0
		var done: bool = b.life <= 0.0
		if on_decoy and b.pos.distance_to(dec.pos) < 2.8:
			_pop_decoy(dec)
			race.shake_near(b.pos, 0.3)
			done = true
		for r: Racer in race.racers:
			if done:
				break
			if r == b.owner and b.life > ROCKET_LIFE - 0.5:
				continue
			if r.is_ghost or r.cloak_time > 0.0 or r.finished or r.rescue_time > 0.0:
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
				if r.is_ghost or r.cloak_time > 0.0 or r.finished or r.rescue_time > 0.0 or (r == m.owner and m.arm > -0.8):
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
				var c: Vector3 = (b.to.global_position + b.to.up * 0.4) if b.has("to") else (b.to_pos as Vector3)
				var len := a.distance_to(c)
				if len > 0.5:
					var y := (c - a) / len
					var bb := _basis_y(y)
					var w := 0.6 + 0.4 * sin(float(b.t) * 18.0)
					node.global_transform = Transform3D(Basis(bb.x * w, y * len, bb.z * w), (a + c) * 0.5)
					if b.get("fresh", true):
						b.fresh = false
						node.reset_physics_interpolation()
				if b.has("to") and b.to.tractor_time <= 0.0:
					b.t = 0.0
			"portal":
				var s := maxf(0.05, sin((1.0 - f) * PI))
				node.scale = Vector3.ONE * s
			"flare_orb":
				node.scale = Vector3.ONE * lerpf(1.0, 7.0, 1.0 - f)
				((node as MeshInstance3D).material_override as StandardMaterial3D).albedo_color.a = f
			"repulsor_dome":
				var rs := lerpf(REPULSOR_RADIUS, 0.5, f)
				node.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(rs, rs * 0.7, rs)), b.at)
				(node as MeshInstance3D).material_override.set_shader_parameter("power", f * 1.4)
			"charge_dome":
				var cr: Racer = b.r
				node.global_position = cr.global_position + cr.up * 0.4
				node.scale = Vector3.ONE * 2.4 * (1.0 + 0.08 * sin(float(b.t) * 30.0))
				(node as MeshInstance3D).material_override.set_shader_parameter("power", 0.5 + 0.9 * f)
				if cr.boost_time <= 0.0 or cr.finished:
					b.t = 0.0
			"emp":
				var s := lerpf(EMP_RADIUS, 0.5, f)
				node.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(s, s * 0.6, s)), b.at)
				var m := (node as MeshInstance3D).material_override as ShaderMaterial
				m.set_shader_parameter("power", f * 1.6)
			"bolt", "chain_bolt":
				b.jit -= dt
				if b.jit <= 0.0:
					b.jit = 0.05
					var bto: Vector3 = (b.to.global_position + b.to.up * 0.8) if b.has("to") else (b.to_pos as Vector3)
					ItemModels.set_bolt(node, b.from.global_position + b.from.up * 0.8, bto, _rng, 1.1)
					if b.get("fresh", true):
						b.fresh = false
						node.reset_physics_interpolation()
				node.visible = int(float(b.t) * 30.0) % 3 != 0
			"laser":
				var w := clampf(f * 1.2, 0.05, 1.0)
				var bb := _basis_y(b.dir)
				node.global_transform = Transform3D(Basis(bb.x * w, b.dir * float(b.reach), bb.z * w), b.origin + b.dir * float(b.reach) * 0.5)
		if b.t <= 0.0:
			_give(String(b.get("pool", b.kind)), node)
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


## The hologram trails its owner, flickering; it pops when something hits it.
func _tick_decoys(dt: float) -> void:
	for k in range(decoys.size() - 1, -1, -1):
		var d: Dictionary = decoys[k]
		var r: Racer = d.owner
		d.t -= dt
		var node: Node3D = d.node
		if d.t <= 0.0 or not d.live or r.finished:
			d.live = false
			_give("decoy", node)
			decoys.remove_at(k)
			continue
		var want := r.global_position - r.heading * 7.0 + r.up * (0.3 + 0.15 * sin(float(d.t) * 5.0))
		d.pos = (d.pos as Vector3).lerp(want, 1.0 - exp(-5.0 * dt))
		var side := r.heading.cross(r.up).normalized()
		if side.length() > 0.5:
			node.global_transform = Transform3D(Basis(side, r.up, -r.heading).rotated(r.up, float(d.t) * 0.6), d.pos)
		node.visible = int(float(d.t) * 24.0) % 7 != 0


## Leech aura follows its owner; beams latch on to victims in range.
func _tick_leeches(dt: float) -> void:
	for k in range(leeches.size() - 1, -1, -1):
		var L: Dictionary = leeches[k]
		var r: Racer = L.r
		L.t -= dt
		var links: Dictionary = L.links
		if L.t <= 0.0 or r.finished:
			for idx in links:
				_give("leech_beam", links[idx])
			_give("leech_aura", L.aura)
			leeches.remove_at(k)
			continue
		var aura: Node3D = L.aura
		aura.global_position = r.global_position + r.up * 0.5
		aura.scale = Vector3.ONE * 2.6 * (1.0 + 0.1 * sin(float(L.t) * 14.0))
		(aura as MeshInstance3D).material_override.set_shader_parameter("power", 0.5 + 0.4 * clampf(float(L.t), 0.0, 1.0))
		for o: Racer in race.racers:
			if o == r or o.is_ghost:
				continue
			var in_range := not o.finished and o.rescue_time <= 0.0 and o.shield_time <= 0.0 and o.cloak_time <= 0.0 and o.global_position.distance_to(r.global_position) < LEECH_RADIUS
			if in_range:
				if not links.has(o.idx):
					if links.size() >= 3:
						continue
					var bn := _take("leech_beam")
					_place(bn, Transform3D(Basis.IDENTITY, o.global_position))
					links[o.idx] = bn
					# Count (and announce) each victim once per leech, even if
					# they drift out of range and back.
					var seen: Dictionary = L.get("seen", {})
					if not seen.has(o.idx):
						seen[o.idx] = true
						L["seen"] = seen
						o.emit_signal("event", "leeched", {"by": r})
						r.stats.hits += 1
						r.emit_signal("event", "leech_hit", {"target": o, "kind": "leech"})
				var taken := o.drain_energy(LEECH_RATE * dt)
				r.add_energy(taken)
				var a: Vector3 = o.global_position + o.up * 0.4
				var c: Vector3 = r.global_position + r.up * 0.4
				var len := a.distance_to(c)
				if len > 0.5:
					var y := (c - a) / len
					var bb := _basis_y(y)
					var w := 0.7 + 0.3 * sin(float(L.t) * 22.0)
					(links[o.idx] as Node3D).global_transform = Transform3D(Basis(bb.x * w, y * len, bb.z * w), (a + c) * 0.5)
			elif links.has(o.idx):
				_give("leech_beam", links[o.idx])
				links.erase(o.idx)


## Gravity wells drag racers toward the centre and slow them.
func _tick_wells(dt: float) -> void:
	for k in range(wells.size() - 1, -1, -1):
		var w: Dictionary = wells[k]
		w.t -= dt
		w.age += dt
		var node: Node3D = w.node
		var grow := clampf(float(w.age) / 0.5, 0.0, 1.0)
		var shrink := clampf(float(w.t) / 0.6, 0.0, 1.0)
		node.scale = Vector3.ONE * maxf(0.05, minf(grow, shrink))
		(node.get_child(0) as Node3D).rotate_y(dt * 4.0)
		(node.get_child(2) as Node3D).scale = Vector3.ONE * (1.0 + 0.08 * sin(float(w.age) * 6.0))
		if w.t <= 0.0:
			_give("well", node)
			wells.remove_at(k)
			continue
		var up: Vector3 = w.up
		for r: Racer in race.racers:
			if r.is_ghost or r.finished or r.rescue_time > 0.0 or r.cloak_time > 0.0 or (r == w.owner and w.age < 1.2):
				continue
			var dv: Vector3 = w.pos - r.global_position
			var d := dv.length()
			if d >= WELL_RADIUS or r.shield_time > 0.0:
				continue
			dv -= up * dv.dot(up)
			if dv.length() > 0.3:
				r.velocity += dv.normalized() * WELL_PULL * (0.4 + (1.0 - d / WELL_RADIUS)) * dt
			r.slow_time = maxf(r.slow_time, 0.25)
			if not w.near.has(r.idx):
				w.near[r.idx] = true
				r.emit_signal("event", "welled", {"by": w.owner})
				if r != w.owner:
					(w.owner as Racer).stats.hits += 1
					(w.owner as Racer).emit_signal("event", "hit_landed", {"target": r, "kind": "well"})


## Trails lay ice as their owner drives; ice patches melt away after 9 s and
## make any craft on them slide.
func _tick_frost(dt: float) -> void:
	for k in range(frosts.size() - 1, -1, -1):
		var f: Dictionary = frosts[k]
		var r: Racer = f.r
		f.t -= dt
		if f.t <= 0.0 or r.finished:
			frosts.remove_at(k)
			continue
		if r.race_dist - float(f.last) >= FROST_GAP and r.grounded:
			f.last = r.race_dist
			_lay_ice(r)
	for idx in _frost_cd.keys():
		_frost_cd[idx] = float(_frost_cd[idx]) - dt
		if float(_frost_cd[idx]) <= 0.0:
			_frost_cd.erase(idx)
	for k in range(ice.size() - 1, -1, -1):
		var p: Dictionary = ice[k]
		p.life -= dt
		p.age += dt
		if p.life <= 0.0:
			_ice_mm.multimesh.set_instance_transform(int(p.slot), _ice_hidden())
			_ice_free.append(int(p.slot))
			ice.remove_at(k)
			continue
		if p.life < 1.0:
			var xf: Transform3D = p.xf
			_ice_mm.multimesh.set_instance_transform(int(p.slot), Transform3D(xf.basis.scaled(Vector3.ONE * maxf(0.05, float(p.life))), xf.origin))
		for r: Racer in race.racers:
			if r.is_ghost or r.finished or r.shield_time > 0.0 or r.cloak_time > 0.0 or (r == p.owner and p.age < 1.0):
				continue
			if r.global_position.distance_to(p.pos) < ICE_RADIUS:
				r.slick_time = maxf(r.slick_time, 0.5)
				if not _frost_cd.has(r.idx):
					_frost_cd[r.idx] = 2.5
					r.emit_signal("event", "frosted", {"by": p.owner})
					if r != p.owner:
						(p.owner as Racer).emit_signal("event", "hit_landed", {"target": r, "kind": "frost"})


## Plasma walls bounce racers that run into them.
func _tick_plasma(dt: float) -> void:
	for idx in _wall_cd.keys():
		_wall_cd[idx] = float(_wall_cd[idx]) - dt
		if float(_wall_cd[idx]) <= 0.0:
			_wall_cd.erase(idx)
	for k in range(plasmas.size() - 1, -1, -1):
		var pw: Dictionary = plasmas[k]
		pw.t -= dt
		pw.age += dt
		var node: Node3D = pw.node
		var grow := clampf(float(pw.age) / 0.3, 0.05, 1.0) * clampf(float(pw.t) / 0.4, 0.05, 1.0)
		(node.get_child(0) as MeshInstance3D).material_override.set_shader_parameter("power", 0.6 + 0.6 * grow + 0.15 * sin(float(pw.age) * 12.0))
		# Rebuild the whole basis (setting `scale` on a sheared frame would
		# throw the wall's size away).
		node.global_transform = Transform3D(TrackBuilder.sb(pw.frame, Vector3(float(pw.half) * 2.0, 3.4 * grow, 0.5)), pw.pos)
		if pw.t <= 0.0:
			_give("plasma_wall", node)
			plasmas.remove_at(k)
			continue
		var fwd: Vector3 = pw.fwd
		var rgt: Vector3 = pw.rgt
		for r: Racer in race.racers:
			if r.is_ghost or r.finished or r == pw.owner or r.cloak_time > 0.0 or r.rescue_time > 0.0 or _wall_cd.has(r.idx):
				continue
			var d: Vector3 = r.global_position - pw.pos
			if absf(d.dot(rgt)) > float(pw.half) + 0.8:
				continue
			var along := d.dot(fwd)
			var reach := 1.4 + absf(r.velocity.dot(fwd)) * dt
			if absf(along) > reach:
				continue
			# Bounce back the way they came and stand them off the wall.
			var side := 1.0 if along >= 0.0 else -1.0
			var v_in := r.velocity.dot(fwd)
			r.velocity -= fwd * v_in * 1.45
			r.global_position = pw.pos + fwd * side * 2.4 + rgt * d.dot(rgt) + (pw.up as Vector3) * (r.T.hover_height - 1.6)
			r.reset_physics_interpolation()
			r.wobble_time = maxf(r.wobble_time, 0.6)
			_wall_cd[r.idx] = 0.5
			r.emit_signal("event", "walled", {"by": pw.owner})
			(pw.owner as Racer).stats.hits += 1
			(pw.owner as Racer).emit_signal("event", "hit_landed", {"target": r, "kind": "plasma"})
			race.shake_near(r.global_position, 0.3)
			pw.hp -= 1
			if int(pw.hp) <= 0:
				# Third hit shatters it (so a wall can never pin anyone for long).
				_boom(pw.pos, PLASMA_C, 1.0, pw.up)
				pw.t = 0.0
				break


## Stasis domes follow their owner and hold everyone inside slow.
func _tick_stasis(dt: float) -> void:
	for k in range(stases.size() - 1, -1, -1):
		var st: Dictionary = stases[k]
		var r: Racer = st.r
		st.t -= dt
		var node: Node3D = st.node
		if st.t <= 0.0 or r.finished:
			_give("stasis_dome", node)
			stases.remove_at(k)
			continue
		var grow := clampf((STASIS_TIME - float(st.t)) / 0.35, 0.05, 1.0) * clampf(float(st.t) / 0.3, 0.05, 1.0)
		node.global_position = r.global_position + r.up * 0.5
		node.scale = Vector3.ONE * STASIS_RADIUS * grow * (1.0 + 0.03 * sin(float(st.t) * 9.0))
		(node as MeshInstance3D).material_override.set_shader_parameter("power", 0.35 + 0.2 * grow)
		for o: Racer in race.racers:
			if o == r or o.is_ghost or o.finished or o.cloak_time > 0.0 or o.shield_time > 0.0:
				continue
			if o.global_position.distance_to(r.global_position) < STASIS_RADIUS * grow:
				o.slow_time = maxf(o.slow_time, 0.2)
				if not st.near.has(o.idx):
					st.near[o.idx] = true
					o.emit_signal("event", "stasis", {"by": r})
					r.stats.hits += 1
					r.emit_signal("event", "hit_landed", {"target": o, "kind": "stasis"})


# ---------------------------------------------------------------- AI helpers
## Shift a lane choice away from mines ahead.
func avoid_lane(s0: float, s1: float, lat: float, hw: float) -> float:
	var path := td.main
	var out := lat
	for m in mines:
		var ds := path.delta(s0, m.s)
		if ds >= 0.0 and ds <= s1 - s0 and absf(float(m.lane) - out) < 3.5:
			out = float(m.lane) + (4.5 if float(m.lane) < 0.0 else -4.5)
	for w in wells:
		var ds := path.delta(s0, w.s)
		if ds >= 0.0 and ds <= s1 - s0 and absf(float(w.lane) - out) < WELL_RADIUS * 0.7:
			out = float(w.lane) + (WELL_RADIUS * 0.8 if float(w.lane) < 0.0 else -WELL_RADIUS * 0.8)
	for p in ice:
		var ds := path.delta(s0, p.s)
		if ds >= 0.0 and ds <= s1 - s0 and absf(float(p.lane) - out) < 3.0:
			out = float(p.lane) + (4.0 if float(p.lane) < 0.0 else -4.0)
	for pw in plasmas:
		var ds := path.delta(s0, pw.s)
		if ds >= -14.0 and ds <= s1 - s0 and absf(float(pw.lane) - out) < float(pw.half) + 2.0:
			out = float(pw.lane) + (float(pw.half) + 3.0) * (1.0 if float(pw.lane) < 0.0 else -1.0)
	return clampf(out, -hw + 2.0, hw - 2.0)


func threatened(r: Racer) -> bool:
	for b in rockets:
		if b.target == r and b.pos.distance_to(r.global_position) < 40.0 and not ((b.decoy as Dictionary).get("live", false)):
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
		"warp":
			return held > 0.5
		"decoy":
			return threatened(r) or held > 7.0
		"leech":
			var near := 0
			for o: Racer in race.racers:
				if o != r and not o.is_ghost and o.global_position.distance_to(r.global_position) < LEECH_RADIUS * 0.8:
					near += 1
			return near >= 1 or held > 6.0
		"well", "frost":
			for o: Racer in race.racers:
				var d: float = r.race_dist - o.race_dist
				if o != r and d > 3.0 and d < 40.0:
					return true
			return (style == "aggressive" and held > 1.0) or held > 4.0
		"overcharge":
			var path := td.main
			var curve := 0.0
			for k in range(0, 30, 3):
				curve = maxf(curve, absf(path.curv[path.wi(r.track_idx + k)]))
			return (curve < 0.012 and r.energy > 45.0 and held > 0.5) or held > 6.0
		"flare", "chain":
			var t := _ahead_of(r, FLARE_RANGE * 0.8 if r.item == "flare" else CHAIN_RANGE * 0.9)
			return t != null and (style == "aggressive" or skill > 0.4 or held > 2.0)
		"plasma":
			for o: Racer in race.racers:
				var d: float = r.race_dist - o.race_dist
				if o != r and d > 3.0 and d < 35.0:
					return true
			return (style == "aggressive" and held > 1.0) or held > 4.0
		"stasis", "repulsor":
			var near := 0
			var rad := STASIS_RADIUS * 0.7 if r.item == "stasis" else REPULSOR_RADIUS * 0.8
			for o: Racer in race.racers:
				if o != r and not o.is_ghost and o.global_position.distance_to(r.global_position) < rad:
					near += 1
			return near >= 1 or held > 6.0
		"cloak":
			return threatened(r) or r.emergency or held > 7.0
	return held > 2.0
