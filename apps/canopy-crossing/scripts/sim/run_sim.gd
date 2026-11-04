class_name RunSim
extends RefCounted
## One run: the player on a World. Pure logic, no nodes: the game view reads
## it every frame, the tests drive it directly, and the planning bot clones
## it to look ahead. Visual/audio cues go into `fx` for the view to drain.

const HB := 0.6                  # default hitbox width in tiles
const SAFE_SOURCES := ["mover", "predator", "swooper", "fire"]

var world: World
var animal: Dictionary = {}
var abilities: Array[Ability] = []      # animal modules
var powerups: Array[Ability] = []       # in-run consumables (grapple, time-slow)
var mode := "journey"

# time
var t := 0.0
var wt := 0.0                    # world time (hazards); slowed by Time-Slow
var slow_left := 0.0

# player
var row := 0
var x := 4.5
var hopping := false
var hop_t := 0.0
var hop_dur := 0.14
var from_row := 0
var from_x := 4.5
var to_row := 0
var to_x := 4.5
var hop_air := false
var hop_kind := "hop"
var face := Vector2i(0, 1)
var plat := -1
var swimming := false
var swim_streak := 0
var swim_idle := 0.0
var float_grace := 0.0
var sink := 0.0
var invuln := 0.0
var hitbox := HB
var base_hop := 0.14

# run state
var state := "play"              # play | respawn | dead | won | over
var respawn_left := 0.0
var lives := 1
var shields := 0
var max_row := 0
var score := 0
var combo := 0
var combo_timer := 0.0
var berries := 0
var amber := 0
var taken := {}
var checkpoint := 0
var no_progress := 0.0
var move_limit := 0.0
var cam_floor := 0.0
var creep := [0.0, 0.0]
var cause := ""
var cause_text := ""
var cause_hazard := ""
var deaths := 0
var revives := 0
var buffer := Vector2i.ZERO
var fx: Array[Dictionary] = []
var record_fx := true


func setup(w: World, animal_def: Dictionary, opts: Dictionary = {}) -> void:
	world = w
	animal = animal_def
	mode = w.mode
	var stats: Dictionary = animal.get("stats", {})
	base_hop = float(stats.get("hop_time", 0.14))
	hitbox = float(stats.get("hitbox", HB))
	lives = int(opts.get("lives", 3 if mode in ["journey", "tutorial"] else 1))
	shields = int(opts.get("shields", 0))
	move_limit = float(opts.get("move_timer", 0.0))
	creep = opts.get("creep", [0.0, 0.0])
	row = 0
	x = 4.5
	for m in animal.get("ability", {}).get("modules", []):
		var mid := String(m.get("module", "hop"))
		if Ability.exists(mid):
			abilities.append(Ability.create(mid, m, self))
	for pu in opts.get("powerups", []):
		var a := Ability.create(String(pu.module), pu, self)
		a.uses_left = int(pu.get("uses", 1))
		powerups.append(a)


func clone() -> RunSim:
	var c := RunSim.new()
	for prop in ["world", "animal", "mode", "t", "wt", "slow_left", "row", "x", "hopping", "hop_t", "hop_dur",
			"from_row", "from_x", "to_row", "to_x", "hop_air", "hop_kind", "face", "plat", "swimming", "swim_streak",
			"swim_idle", "float_grace", "sink", "invuln", "hitbox", "base_hop", "state", "respawn_left", "lives",
			"shields", "max_row", "score", "combo", "combo_timer", "berries", "amber", "checkpoint", "no_progress",
			"move_limit", "cam_floor", "creep", "cause", "cause_text", "cause_hazard", "deaths", "revives", "buffer"]:
		c.set(prop, get(prop))
	c.taken = taken.duplicate()
	c.record_fx = false
	for a in abilities:
		var b := a.clone()
		b.run = c
		c.abilities.append(b)
	for a in powerups:
		var b2 := a.clone()
		b2.run = c
		c.powerups.append(b2)
	return c


func _fx(kind: String, data: Dictionary = {}) -> void:
	if record_fx:
		data["type"] = kind
		data["row"] = row
		data["x"] = x
		fx.append(data)


# ------------------------------------------------------------------ queries

func all_abilities() -> Array[Ability]:
	var out: Array[Ability] = []
	out.append_array(abilities)
	out.append_array(powerups)
	return out


func button_ability() -> Ability:
	for a in abilities:
		if a.has_button():
			return a
	return null


func is_airborne() -> bool:
	if hopping and hop_air:
		return true
	for a in all_abilities():
		if a.airborne():
			return true
	return false


func is_rooted() -> bool:
	for a in abilities:
		if a.rooted():
			return true
	return false


func swim_params() -> Dictionary:
	for a in abilities:
		var s := a.swim()
		if not s.is_empty():
			return s
	return {}


func reveal_amount() -> float:
	var r := 0.0
	for a in abilities:
		r = maxf(r, a.reveal())
	return r


func reach() -> int:
	var r := 0
	for a in abilities:
		r = maxi(r, a.reach())
	return r


func forages() -> bool:
	for a in abilities:
		if a.forages():
			return true
	return false


func plows() -> bool:
	for a in abilities:
		if a.plows():
			return true
	return false


func knockback_immune() -> bool:
	for a in abilities:
		if a.knockback_immune():
			return true
	return false


func drift_factor() -> float:
	var f := 1.0
	for a in abilities:
		f = minf(f, a.drift())
	return f


func cur_lane() -> Lane:
	return world.lane(row)


func lane_is_water(l: Lane) -> bool:
	if l.type == "water":
		return true
	if l.effect.get("kind", "") == "tide":
		return l.effect_state(wt)[0] == "active"
	return false


func display_pos() -> Vector2:
	## x in tiles, y in rows (float), for drawing.
	if hopping:
		var k := _ease(hop_t)
		return Vector2(lerpf(from_x, to_x, k), lerpf(float(from_row), float(to_row), k))
	return Vector2(x, float(row))


func hop_height() -> float:
	if not hopping:
		return 0.0
	var span := absi(to_row - from_row)
	var h := 0.28 + 0.22 * maxi(0, span - 1)
	if hop_kind in ["dash", "slide", "roll"]:
		h = 0.05
	return sin(hop_t * PI) * h


func _ease(k: float) -> float:
	return k * k * (3.0 - 2.0 * k)


func multiplier() -> float:
	return 1.0 + 0.5 * floorf(minf(20.0, float(combo)) / 5.0)


# ------------------------------------------------------------------ input

func hop(dir: Vector2i) -> bool:
	if state != "play":
		return false
	if hopping:
		buffer = dir
		return false
	if is_rooted():
		return false
	var target_row := row + dir.y
	if target_row < 0 or (mode in ["endless", "daily"] and target_row < int(floorf(cam_floor))):
		_fx("bump")
		return false
	var lt := world.lane(target_row)
	var tx := x
	var in_water_target := lt.type == "water"
	if dir.x != 0:
		tx = x + dir.x
		if not in_water_target or plat < 0:
			tx = floorf(tx) + 0.5 if not in_water_target else tx
		if tx < 0.45 or tx > Lane.COLS - 0.45:
			_fx("bump")
			return false
	elif not in_water_target:
		tx = clampf(floorf(x) + 0.5, 0.5, Lane.COLS - 0.5)
	if not in_water_target:
		var tile := lt.tile_at(int(floorf(tx)))
		if tile.get("kind", "") == "brush" and not plows():
			_fx("bump", {"brush": true})
			return false
	var water_hop := lane_is_water(cur_lane()) or in_water_target
	var scale := 1.0
	for a in abilities:
		scale = minf(scale, a.hop_time_scale(water_hop))
	face = dir
	if dir.y < 0:
		combo = 0
	_start_hop(target_row, tx, base_hop * scale, false, "hop")
	_fx("hop", {"dir": dir})
	return true


## Ability helpers: airborne move forward `rows` rows (multi-hop, glide, dash, swing).
func leap(rows: int, dur: float, kind: String, air := true) -> bool:
	if state != "play" or hopping:
		return false
	var target_row := row + rows
	if world.goal_row >= 0:
		target_row = mini(target_row, world.goal_row)
	if target_row <= row:
		return false
	var lt := world.lane(target_row)
	var tx := x
	if lt.type != "water":
		tx = clampf(floorf(x) + 0.5, 0.5, Lane.COLS - 0.5)
		var tile := lt.tile_at(int(floorf(tx)))
		if tile.get("kind", "") == "brush" and not plows():
			tx = _nearest_open_col(lt, tx)
	face = Vector2i(0, 1)
	_start_hop(target_row, tx, dur, air, kind)
	_fx("leap", {"kind": kind, "rows": rows})
	return true


func _nearest_open_col(l: Lane, tx: float) -> float:
	for d in range(1, Lane.COLS):
		for s in [-1, 1]:
			var c: int = int(floorf(tx)) + d * int(s)
			if c >= 0 and c < Lane.COLS and l.tile_at(c).get("kind", "") != "brush":
				return c + 0.5
	return tx


func use_ability() -> bool:
	if state != "play":
		return false
	var a := button_ability()
	if a and a.use():
		_fx("ability", {"id": a.id, "style": a.style})
		return true
	return false


func use_powerup(module_id: String) -> bool:
	if state != "play":
		return false
	for a in powerups:
		if a.id == module_id and a.use():
			_fx("powerup", {"id": a.id})
			return true
	return false


func _start_hop(target_row: int, tx: float, dur: float, air: bool, kind: String) -> void:
	hopping = true
	hop_t = 0.0
	hop_dur = maxf(0.05, dur)
	from_row = row
	from_x = x
	to_row = target_row
	to_x = tx
	hop_air = air
	hop_kind = kind
	plat = -1
	swimming = false
	sink = 0.0
	float_grace = 0.0


# ------------------------------------------------------------------ step

func step(dt: float) -> void:
	if state in ["won", "over", "dead"]:
		for a in all_abilities():
			a.tick(dt)
		return
	t += dt
	var wdt := dt * (0.45 if slow_left > 0.0 else 1.0)
	slow_left = maxf(0.0, slow_left - dt)
	var wt0 := wt
	wt += wdt
	for a in all_abilities():
		a.tick(dt)
	for l in [world.lane(row - 1), world.lane(row), world.lane(row + 1)]:
		for e in l.ents:
			if e.pushed != 0.0:
				e.pushed = move_toward(e.pushed, 0.0, dt * 0.6)
	if state == "respawn":
		respawn_left -= dt
		if respawn_left <= 0.0:
			_respawn()
		return
	invuln = maxf(0.0, invuln - dt)
	if hopping:
		hop_t += dt / hop_dur
		if hop_t >= 1.0:
			_land()
	else:
		_ride(wt0, wt, dt)
	if state != "play":
		return
	_events(wt0, wt)
	if state != "play":
		return
	_check(dt)
	if state != "play":
		return
	if not hopping:
		_collect()
	combo_timer -= dt
	if combo_timer <= 0.0:
		combo = 0
	if move_limit > 0.0 and max_row > 0:
		no_progress += dt
		if no_progress > move_limit:
			_lethal("timeout", "timer", "", "Out of time — keep moving forward")
	if mode in ["endless", "daily"]:
		_creep(dt)
	if not hopping and state == "play" and buffer != Vector2i.ZERO:
		var b := buffer
		buffer = Vector2i.ZERO
		hop(b)


func _creep(dt: float) -> void:
	if max_row < 4:
		return
	var d := world.difficulty(max_row)
	cam_floor += lerpf(float(creep[0]), float(creep[1]), d) * dt
	cam_floor = maxf(cam_floor, float(max_row) - 7.0)
	if float(row) < cam_floor - 0.6 and not hopping:
		_lethal("swept", "creep", "", "Left behind — the jungle closed in")


func _ride(wt0: float, wt1: float, dt: float) -> void:
	var l := cur_lane()
	if plat >= 0 and plat < l.ents.size():
		var e: Ent = l.ents[plat]
		var a0 := world.ent_x(l, e, wt0)
		var a1 := world.ent_x(l, e, wt1)
		var dx := a1 - a0
		if absf(dx) > Lane.WRAP * 0.5:
			dx -= signf(dx) * Lane.WRAP
		var f := drift_factor()
		if f < 1.0 and absf(dx) > 0.0:
			var nx := x + dx * f
			x = clampf(nx, a1 + 0.3, a1 + e.length - 0.3) if e.length > 0.7 else x + dx
		else:
			x += dx
	elif swimming:
		var sp := swim_params()
		var cur := l.speed
		if cur == 0.0 and not l.ents.is_empty():
			cur = l.ents[0].velocity(l.speed, world.lane_time(l, wt1))
		x += cur * float(sp.get("current", 1.0)) * (wt1 - wt0)
		swim_idle += dt
		var idle_limit := float(sp.get("idle_limit", -1.0))
		if idle_limit > 0.0 and swim_idle > idle_limit:
			_lethal("drowned", "water", "", "Too long in the water")
			return
		var pi := world.platform_at(l, x, wt1)
		if pi >= 0:
			plat = pi
			swimming = false
	elif float_grace > 0.0:
		float_grace -= dt
		var pi2 := world.platform_at(l, x, wt1)
		if pi2 >= 0:
			plat = pi2
			float_grace = 0.0
		elif float_grace <= 0.0:
			_lethal("drowned", "water", l.hazard_id, "Splash! Drifted too long")


func _events(wt0: float, wt1: float) -> void:
	if hopping or is_airborne():
		return
	var g := world.gust_between(wt0, wt1)
	if g != 0:
		_fx("gust", {"dir": g})
		if not knockback_immune():
			_push(Vector2i(g, 0))
			return
	var l := cur_lane()
	if l.effect.get("kind", "") == "mudslide" and l.effect_crossed(wt0, wt1):
		_fx("mudslide")
		if not knockback_immune() and row > 0:
			_push(Vector2i(0, -1))


func _push(dir: Vector2i) -> void:
	var target_row := row + dir.y
	var lt := world.lane(target_row)
	var tx := x + dir.x
	if lt.type != "water":
		tx = clampf(floorf(tx) + 0.5, 0.5, Lane.COLS - 0.5)
		if lt.tile_at(int(floorf(tx))).get("kind", "") == "brush":
			return
	elif tx < 0.2 or tx > Lane.COLS - 0.2:
		tx = clampf(tx, 0.2, Lane.COLS - 0.2)
	if dir.y < 0:
		combo = 0
	_start_hop(target_row, tx, 0.22, false, "slide")


func _land() -> void:
	hopping = false
	var prev_row := row
	row = to_row
	x = to_x
	var air := hop_air
	hop_air = false
	var l := cur_lane()
	plat = -1
	swimming = false
	if lane_is_water(l):
		var pi := world.platform_at(l, x, wt)
		if pi >= 0:
			plat = pi
			swim_streak = 0
			_fx("land", {"surface": "platform"})
		elif _airborne_abilities():
			pass
		else:
			var sp := swim_params()
			var soft := _soft_landing()
			if not sp.is_empty() and (int(sp.get("max_streak", 0)) <= 0 or swim_streak < int(sp.get("max_streak", 0))):
				swimming = true
				swim_streak += 1
				swim_idle = 0.0
				_fx("swim")
			elif soft > 0.0:
				float_grace = soft
				_fx("float")
			else:
				_fx("splash")
				_lethal("drowned", "water", l.hazard_id, "Splash! No log to land on")
				return
	else:
		swim_streak = 0
		var tile := l.tile_at(int(floorf(x)))
		if tile.get("kind", "") == "gap" and not _airborne_abilities():
			_lethal("fell", "tile", String(tile.hazard), _cause_text(String(tile.hazard), "Fell into a gully"))
			return
		if tile.get("kind", "") == "brush" and plows():
			l.tiles.erase(int(floorf(x)))
			_fx("plow")
		_fx("land", {"surface": l.type, "air": air})
	if row > max_row:
		var gained := row - max_row
		combo = combo + gained if combo_timer > 0.0 else gained
		combo_timer = 1.4
		score += int(roundf(gained * multiplier()))
		max_row = row
		no_progress = 0.0
		_fx("progress", {"gained": gained, "mult": multiplier()})
	elif row < prev_row:
		combo = 0
	if l.type == "safe" and l.effect.is_empty() and l.tiles.size() < Lane.COLS - 1:
		checkpoint = row
	_collect()
	if world.goal_row >= 0 and row >= world.goal_row:
		state = "won"
		score += 50
		_fx("goal")


## Hover ran out: come down wherever we are and face the lane.
func _hover_landed() -> void:
	if state != "play" or hopping:
		return
	from_row = row
	from_x = x
	to_row = row
	to_x = x
	hop_air = false
	_land()


func _soft_landing() -> float:
	var best := 0.0
	for a in abilities:
		best = maxf(best, float(a.extra.get("soft_landing", 0.0)))
	return best


func _airborne_abilities() -> bool:
	for a in all_abilities():
		if a.airborne():
			return true
	return false


func _check(dt: float) -> void:
	var r := row
	var px := x
	if hopping:
		var k := _ease(hop_t)
		px = lerpf(from_x, to_x, k)
		r = from_row if hop_t < 0.5 else to_row
	var col := int(floorf(px))
	var air := is_airborne()
	# raptors hit anything in their column, even fliers
	var sw := world.swooper_hit(r, col, wt)
	if not sw.is_empty():
		_lethal("eaten", "swooper", String(sw.hazard), _cause_text(String(sw.hazard), "Snatched from above"))
		if state != "play":
			return
	if air:
		return
	var l := world.lane(r)
	if not l.ents.is_empty():
		var e := world.mover_hit(l, px - hitbox * 0.5, px + hitbox * 0.5, wt)
		if e != null:
			var h: Dictionary = Content.hazards.get(e.hazard, {})
			_lethal(String(h.get("cause", "crushed")), "predator" if h.get("predator", false) else "mover", e.hazard,
				_cause_text(e.hazard, "Flattened"))
			if state != "play":
				return
	var pr := world.pred_hit(l, px, col, wt)
	if not pr.is_empty():
		_lethal(String(Content.hazards.get(String(pr.hazard), {}).get("cause", "eaten")), "predator", String(pr.hazard),
			_cause_text(String(pr.hazard), "Eaten"))
		if state != "play":
			return
	var eff := l.effect_state(wt)
	if eff[0] == "active":
		match String(l.effect.kind):
			"fire":
				_lethal("burned", "fire", String(l.effect.hazard), _cause_text(String(l.effect.hazard), "Burned"))
			"tide":
				if not hopping and plat < 0 and not swimming and swim_params().is_empty():
					_lethal("drowned", "water", String(l.effect.hazard), _cause_text(String(l.effect.hazard), "Washed away"))
				elif not hopping and not swim_params().is_empty():
					swimming = true
		if state != "play":
			return
	if hopping:
		return
	if l.type == "water":
		if plat >= 0:
			var e2: Ent = l.ents[plat]
			if world.ent_dive(l, e2, wt) == "under":
				_lethal("drowned", "water", e2.hazard, _cause_text(e2.hazard, "It dived — and so did you"))
				return
			var ex := world.ent_x(l, e2, wt)
			if x < ex - 0.25 or x > ex + e2.length + 0.25:
				plat = -1
				if swim_params().is_empty():
					_lethal("drowned", "water", e2.hazard, "Slipped into the water")
					return
				swimming = true
		elif not swimming and float_grace <= 0.0:
			_lethal("drowned", "water", l.hazard_id, "Splash!")
			return
	else:
		var tile := l.tile_at(col)
		if tile.get("kind", "") == "quicksand":
			sink += dt
			if sink > float(tile.get("sink", 1.0)):
				_lethal("drowned", "tile", String(tile.hazard), _cause_text(String(tile.hazard), "Swallowed by quicksand"))
				return
		else:
			sink = 0.0
	if x < 0.08 or x > Lane.COLS - 0.08:
		_lethal("swept", "swept", l.hazard_id, "Swept off the edge of the map")


func _cause_text(hid: String, fallback: String) -> String:
	return String(Content.hazards.get(hid, {}).get("cause_text", fallback))


func _lethal(c: String, source: String, hazard_id: String, text: String) -> void:
	if state != "play":
		return
	if invuln > 0.0 and source in SAFE_SOURCES:
		return
	for a in all_abilities():
		if a.immune(source, c):
			return
	for a in all_abilities():
		if a.absorb(source, c):
			invuln = 1.0
			_fx("absorb", {"id": a.id, "style": a.style})
			return
	if shields > 0 and source in SAFE_SOURCES:
		shields -= 1
		invuln = 1.2
		_fx("shield_break")
		return
	_die(c, source, hazard_id, text)


func _die(c: String, _source: String, hazard_id: String, text: String) -> void:
	cause = c
	cause_text = text
	cause_hazard = hazard_id
	deaths += 1
	lives -= 1
	hopping = false
	plat = -1
	swimming = false
	_fx("die", {"cause": c, "hazard": hazard_id})
	if lives > 0:
		state = "respawn"
		respawn_left = 1.1
	else:
		state = "dead"


func _respawn() -> void:
	state = "play"
	row = checkpoint
	if mode in ["endless", "daily"]:
		row = maxi(row, int(ceilf(cam_floor)))
		while row < world.top_row() and world.lane(row).type != "safe":
			row += 1
	x = 4.5
	var l := cur_lane()
	if l.tile_at(4).get("kind", "") != "":
		for c in Lane.COLS:
			if l.tile_at(c).is_empty():
				x = c + 0.5
				break
	invuln = 2.0
	combo = 0
	no_progress = 0.0
	_fx("respawn")


## Continue after the last life is gone (Revive item, Amber or an ad).
func revive() -> void:
	if state != "dead":
		return
	revives += 1
	lives = 1
	cam_floor = minf(cam_floor, float(row) - 2.0)
	checkpoint = row
	while checkpoint > 0 and world.lane(checkpoint).type != "safe":
		checkpoint -= 1
	if mode in ["endless", "daily"]:
		cam_floor = minf(cam_floor, float(checkpoint) - 1.0)
	_respawn()


func finish() -> void:
	if state in ["dead", "play", "respawn"]:
		state = "over"


# ------------------------------------------------------------------ items

func _collect() -> void:
	var rad := reach()
	for dr in range(-rad, rad + 1):
		var l := world.lane(row + dr)
		for it in l.items:
			if taken.has(it.key):
				continue
			if it.bonus and not forages():
				continue
			var ix: float
			if int(it.ent) >= 0:
				var e: Ent = l.ents[int(it.ent)]
				ix = world.ent_x(l, e, wt) + float(it.rel)
			else:
				ix = float(it.col) + 0.5
			if absf(ix - x) <= 0.55 + rad:
				taken[it.key] = true
				var def := Content.collectible(String(it.id))
				var rw: Dictionary = def.get("reward", {})
				berries += int(rw.get("berries", 0))
				amber += int(rw.get("amber", 0))
				_fx("collect", {"id": String(it.id), "ix": ix, "irow": row + dr})
