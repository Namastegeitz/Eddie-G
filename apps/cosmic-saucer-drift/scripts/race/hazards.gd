class_name Hazards
extends Node3D
## Moving track hazards. Each one lives at a distance `s` on the main loop
## and is checked against racers in track coordinates (distance + lateral),
## which is cheap and matches what the player sees. Every hazard telegraphs
## before it can hurt you.
##   roller   tumbling asteroid rolling across the road
##   flare    plasma column sweeping across
##   laser    half-road laser gate, alternating sides, flickers first
##   snapper  alien plant lunging in from one edge, shakes first
##   geyser   launches you upward while erupting (bubbles first)
##   dropper  ice shards falling with shadows
##   eruption lava erupting on one half of the road, cracks glow first

var race: Node
var td: TrackData
var list: Array[Dictionary] = []
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_race: Node) -> void:
	race = p_race
	td = race.td
	_rng.seed = hash(td.id) * 31
	var path := td.main
	var k := 0
	for f in td.feats:
		var h := {}
		match f.t:
			"roller", "flare", "laser", "snapper", "geyser", "dropper", "eruption", "wind":
				h = f.duplicate()
			_:
				continue
		h["phase"] = float(k) * 1.37
		h["near"] = {}
		k += 1
		var i := path.index_at(h.s)
		h["i"] = i
		_build(h, i)
		list.append(h)


func _mesh_node(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _frame(i: int) -> Basis:
	var path := td.main
	return Basis(path.rgt[i], path.upv[i], -path.tan[i])


func _build(h: Dictionary, i: int) -> void:
	var path := td.main
	var hw := td.width * 0.5
	match h.t:
		"roller":
			if h.get("style", "") == "devil":
				var cone := CylinderMesh.new()
				cone.top_radius = 1.0
				cone.bottom_radius = 0.15
				cone.height = 4.0
				cone.radial_segments = 10
				var n := _mesh_node(cone, TrackBuilder.ghost(Color(0.85, 0.6, 0.4), 0.45))
				n.scale = Vector3.ONE * float(h.get("size", 4.0))
				h["node"] = n
			else:
				var n := _mesh_node(TrackDecor.rock_mesh(), TrackBuilder.flat(Color(0.45, 0.36, 0.33), 0.0, 0.1, 0.9))
				n.scale = Vector3.ONE * float(h.get("size", 4.0))
				h["node"] = n
		"wind":
			var a := path.index_at(float(h.s))
			var span := path.delta(float(h.s), float(h.s1))
			var mid := path.index_at(float(h.s) + span * 0.5)
			var pc := CPUParticles3D.new()
			pc.amount = 70
			pc.lifetime = 0.7
			pc.local_coords = false
			pc.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			pc.emission_box_extents = Vector3(hw + 6.0, 2.5, span * 0.5)
			pc.direction = Vector3(1, 0, 0)
			pc.spread = 4.0
			pc.gravity = Vector3.ZERO
			pc.initial_velocity_min = 40.0
			pc.initial_velocity_max = 55.0
			var qm := QuadMesh.new()
			qm.size = Vector2(3.5, 0.12)
			var qmat := StandardMaterial3D.new()
			qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			qmat.albedo_color = Color(1, 1, 1, 0.45)
			qm.material = qmat
			pc.mesh = qm
			pc.emitting = false
			add_child(pc)
			pc.global_transform = Transform3D(_frame(mid), path.pts[mid] + path.upv[mid] * 2.0)
			h["fx"] = pc
			h["i"] = a
		"flare":
			var c := CylinderMesh.new()
			c.top_radius = 1.6
			c.bottom_radius = 2.2
			c.height = 26.0
			var n := _mesh_node(c, TrackBuilder.ghost(Color(1.0, 0.6, 0.15), 0.75))
			h["node"] = n
		"laser", "eruption":
			var bm := BoxMesh.new()
			var length: float = 2.0 if h.t == "laser" else float(h.get("len", 30.0))
			bm.size = Vector3(hw, 1.0, length)
			var col := Color(1.0, 0.15, 0.15) if h.t == "laser" else Color(1.0, 0.4, 0.05)
			var n := _mesh_node(bm, TrackBuilder.ghost(col, 0.6))
			h["node"] = n
			h["mat"] = n.material_override
			if h.t == "laser":
				var post := BoxMesh.new()
				post.size = Vector3(0.8, 4.0, 0.8)
				for sx: float in [-1.0, 1.0]:
					var p := _mesh_node(post, TrackBuilder.flat(Color(0.3, 0.3, 0.35), 0.0, 0.8, 0.3))
					p.global_position = path.pts[i] + path.rgt[i] * sx * (hw + 1.0) + path.upv[i] * 2.0
					p.global_basis = _frame(i)
				var mid := _mesh_node(post, TrackBuilder.flat(Color(0.3, 0.3, 0.35), 0.0, 0.8, 0.3))
				mid.global_position = path.pts[i] + path.upv[i] * 6.0
				mid.global_basis = TrackBuilder.sb(_frame(i), Vector3(td.width * 1.25, 0.25, 1.0))
		"snapper":
			var stem := CylinderMesh.new()
			stem.top_radius = 0.6
			stem.bottom_radius = 1.0
			stem.height = 1.0
			var head := SphereMesh.new()
			head.radius = 2.2
			head.height = 3.2
			var root := Node3D.new()
			add_child(root)
			var side := float(h.side)
			root.global_position = path.pts[i] + path.rgt[i] * side * (hw + 2.5) + path.upv[i] * 1.5
			root.global_basis = _frame(i)
			var sn := _mesh_node(stem, TrackBuilder.flat(Color(0.2, 0.55, 0.25)))
			remove_child(sn)
			root.add_child(sn)
			var hn := _mesh_node(head, TrackBuilder.flat(Color(0.85, 0.2, 0.45), 0.6, 0.1, 0.6))
			remove_child(hn)
			root.add_child(hn)
			var jaw := SphereMesh.new()
			jaw.radius = 1.0
			jaw.height = 1.2
			var mouth := _mesh_node(jaw, TrackBuilder.glow(Color(1.0, 0.9, 0.3), 1.5))
			remove_child(mouth)
			hn.add_child(mouth)
			mouth.position = Vector3(-side * 1.8, 0, 0)
			h["root"] = root
			h["stem"] = sn
			h["head"] = hn
		"geyser":
			var base := CylinderMesh.new()
			base.top_radius = 2.6
			base.bottom_radius = 3.0
			base.height = 0.4
			var b := _mesh_node(base, TrackBuilder.flat(Color(0.25, 0.4, 0.3), 0.0, 0.2, 0.8))
			b.global_position = path.pts[i] + path.rgt[i] * float(h.lane) + path.upv[i] * 0.15
			b.global_basis = _frame(i)
			var col := CylinderMesh.new()
			col.top_radius = 2.4
			col.bottom_radius = 1.8
			col.height = 1.0
			var jet := _mesh_node(col, TrackBuilder.ghost(Color(0.55, 0.95, 1.0), 0.55))
			h["jet"] = jet
			h["base"] = b
		"dropper":
			h["shards"] = []
			h["spawn"] = 0.0
			h["pos"] = path.pts[i]


## Hazard state at time t: 0 idle, 1 warning, 2 active.
func _cycle(h: Dictionary, period: float, warn: float, active: float) -> Array:
	var t := fposmod(_t + float(h.phase), period)
	var rest := period - warn - active
	if t < rest:
		return [0, t / maxf(rest, 0.01)]
	if t < rest + warn:
		return [1, (t - rest) / warn]
	return [2, (t - rest - warn) / active]


func tick(dt: float) -> void:
	_t += dt
	var path := td.main
	var hw := td.width * 0.5
	for h in list:
		var i: int = h.i
		match h.t:
			"roller":
				var period: float = h.get("period", 5.5)
				var size: float = h.get("size", 4.0)
				var lat := sin((_t + float(h.phase)) * TAU / period) * (hw + size + 3.0)
				var pos := path.pts[i] + path.rgt[i] * lat + path.upv[i] * size * 0.8
				if h.get("style", "") == "devil":
					h.node.global_position = path.pts[i] + path.rgt[i] * lat + path.upv[i] * size * 1.8
					h.node.global_basis = TrackBuilder.sb(_frame(i), Vector3.ONE * size).rotated(path.upv[i].normalized(), _t * 6.0)
				else:
					h.node.global_position = pos
					h.node.rotate(path.tan[i].normalized(), -cos((_t + float(h.phase)) * TAU / period) * dt * 3.0)
				_check(h, i, lat, size + 0.8, size * 0.8 + 1.0, true, "roller")
			"flare":
				var period: float = h.get("period", 4.5)
				var lat := sin((_t + float(h.phase)) * TAU / period * 1.3) * (hw + 2.0)
				h.node.global_position = path.pts[i] + path.rgt[i] * lat + path.upv[i] * 12.0
				h.node.global_basis = _frame(i)
				_check(h, i, lat, 2.6, 2.6, true, "flare")
			"laser":
				var period: float = h.get("period", 4.0)
				var st := _cycle(h, period, 0.8, 1.5)
				var cycle_n := int((_t + float(h.phase)) / period)
				var side := 1.0 if cycle_n % 2 == 0 else -1.0
				var lat := side * hw * 0.5
				h.node.visible = st[0] != 0 and (st[0] == 2 or int(_t * 14.0) % 2 == 0)
				h.node.global_position = path.pts[i] + path.rgt[i] * lat + path.upv[i] * 1.2
				h.node.global_basis = TrackBuilder.sb(_frame(i), Vector3(1.0, 0.25 if st[0] == 2 else 0.08, 1.0))
				_check(h, i, lat, hw * 0.5, 1.6, st[0] == 2, "laser")
			"eruption":
				var st := _cycle(h, 3.8, 1.2, 1.6)
				var cycle_n := int((_t + float(h.phase)) / 3.8)
				var side := 1.0 if cycle_n % 2 == 0 else -1.0
				var lat := side * hw * 0.5
				var length: float = h.get("len", 30.0)
				var mid := path.index_at(float(h.s) + 0.0)
				h.node.visible = st[0] != 0
				var height := 0.15 if st[0] == 1 else 7.0 * sin(PI * clampf(st[1] * 1.2, 0.0, 1.0)) + 0.3
				h.node.global_position = path.pts[mid] + path.rgt[mid] * lat + path.upv[mid] * height * 0.5
				h.node.global_basis = TrackBuilder.sb(_frame(mid), Vector3(1.0, height, 1.0))
				var mc: Color = h.mat.albedo_color
				mc.a = 0.35 if st[0] == 1 else 0.8
				h.mat.albedo_color = mc
				_check(h, i, lat, hw * 0.5, length * 0.5, st[0] == 2, "eruption")
			"snapper":
				var st := _cycle(h, 3.6, 0.8, 0.9)
				var side := float(h.side)
				var reach := 0.0
				if st[0] == 1:
					h.head.position = Vector3(sin(_t * 40.0) * 0.3, 2.0, 0)
				elif st[0] == 2:
					reach = sin(PI * st[1]) * td.width * 0.55
					h.head.position = Vector3(-side * reach, 1.2, 0)
				else:
					h.head.position = Vector3(0, 2.5 + sin(_t * 2.0) * 0.3, 0)
				h.stem.position = h.head.position * 0.5
				h.stem.scale = Vector3(1.0, maxf(1.0, h.head.position.length()), 1.0)
				var tip := side * (hw + 2.5) - side * reach
				_check(h, i, tip, 2.6, 2.8, st[0] == 2 and reach > 2.0, "snapper")
			"geyser":
				var st := _cycle(h, 3.7, 0.6, 2.0)
				var lane: float = h.lane
				var jh := 0.0
				if st[0] == 1:
					jh = 1.2 + sin(_t * 30.0) * 0.4
				elif st[0] == 2:
					jh = 16.0 * sin(PI * minf(st[1] * 1.3, 1.0)) + 1.0
				h.jet.visible = jh > 0.0
				h.jet.global_position = path.pts[i] + path.rgt[i] * lane + path.upv[i] * jh * 0.5
				h.jet.global_basis = TrackBuilder.sb(_frame(i), Vector3(1.0, maxf(jh, 0.1), 1.0))
				if st[0] == 2:
					_geyser_launch(h, i, lane)
			"dropper":
				_tick_dropper(h, dt)
			"wind":
				_tick_wind(h, dt)


## Hit any racer inside the hazard box (lateral half-width lw, length ls).
func _check(h: Dictionary, i: int, lat: float, lw: float, ls: float, active: bool, kind: String) -> void:
	var path := td.main
	for r: Racer in race.racers:
		if r.is_ghost or r.rescue_time > 0.0 or r.on_shortcut:
			continue
		var ds := path.delta(float(h.s), float(r.track_idx) * path.step)
		if absf(ds) > ls + 6.0:
			h.near.erase(r.idx)
			continue
		var ht := path.height(r.track_idx, r.global_position)
		if ht > 5.5:
			continue
		var dl := absf(r.lateral - lat)
		if active and absf(ds) < ls and dl < lw + 1.0:
			if r.hit(null, kind):
				race.shake_near(r.global_position, 0.4)
			h.near.erase(r.idx)
		elif active and absf(ds) < ls + 4.0 and dl < lw + 4.0:
			h.near[r.idx] = true
		elif h.near.has(r.idx) and absf(ds) > ls + 4.0:
			h.near.erase(r.idx)
			r.near_miss()


func _geyser_launch(h: Dictionary, i: int, lane: float) -> void:
	var path := td.main
	for r: Racer in race.racers:
		if r.is_ghost or r.rescue_time > 0.0:
			continue
		var ds := path.delta(float(h.s), float(r.track_idx) * path.step)
		if absf(ds) < 3.6 and absf(r.lateral - lane) < 3.4 and path.height(i, r.global_position) < 3.0:
			var launch: float = h.get("launch", 17.0)
			if r.velocity.dot(path.upv[i]) < launch * 0.5:
				r.velocity += path.upv[i] * (launch - maxf(r.velocity.dot(path.upv[i]), 0.0))
				r.grounded = false
				r.global_position += path.upv[i] * 0.4
				if h.get("shortcut", false):
					r.stats.shortcuts += 1
				r.emit_signal("event", "geyser", {})


func _tick_dropper(h: Dictionary, dt: float) -> void:
	var path := td.main
	h.spawn -= dt
	var shards: Array = h.shards
	if h.spawn <= 0.0:
		h.spawn = _rng.randf_range(0.5, 1.0)
		var span := path.delta(float(h.s), float(h.s1))
		var s := float(h.s) + _rng.randf_range(0.0, span)
		# Aim some shards at the leader's lane so they feel alive.
		var lane := _rng.randf_range(-td.width * 0.42, td.width * 0.42)
		var i := path.index_at(s)
		var shadow := TorusMesh.new()
		shadow.inner_radius = 2.2
		shadow.outer_radius = 2.8
		shadow.rings = 16
		shadow.ring_segments = 3
		var sn := _mesh_node(shadow, TrackBuilder.ghost(Color(0.6, 0.85, 1.0), 0.6))
		sn.global_position = path.pts[i] + path.rgt[i] * lane + path.upv[i] * 0.15
		sn.global_basis = _frame(i)
		var style: String = h.get("style", "ice")
		var ice: MeshInstance3D
		if style == "iron" or style == "plasma":
			var blob := SphereMesh.new()
			blob.radius = 1.3
			blob.height = 3.4
			blob.radial_segments = 10
			blob.rings = 5
			var c := Color(1.0, 0.55, 0.15) if style == "iron" else Color(1.0, 0.3, 0.45)
			ice = _mesh_node(blob, TrackBuilder.glow(c, 2.4))
		else:
			var cone := CylinderMesh.new()
			cone.top_radius = 1.2
			cone.bottom_radius = 0.0
			cone.height = 4.5
			cone.radial_segments = 6
			var mat: Material = TrackBuilder.flat(Color(0.75, 0.9, 1.0), 0.6, 0.2, 0.1)
			if style == "glass":
				mat = TrackBuilder.ghost(Color(0.6, 0.9, 1.0), 0.55)
			ice = _mesh_node(cone, mat)
		shards.append({"s": s, "lane": lane, "i": i, "t": 1.3, "shadow": sn, "ice": ice, "near": {}})
	for k in range(shards.size() - 1, -1, -1):
		var d: Dictionary = shards[k]
		d.t -= dt
		var i: int = d.i
		var fall := clampf(1.0 - d.t / 0.55, 0.0, 1.0)
		d.ice.global_position = path.pts[i] + path.rgt[i] * float(d.lane) + path.upv[i] * lerpf(45.0, 2.0, fall)
		d.ice.visible = d.t < 0.55
		d.shadow.scale = Vector3.ONE * (0.5 + 0.5 * (1.0 - d.t / 1.3))
		if d.t <= 0.0:
			for r: Racer in race.racers:
				if r.is_ghost or r.on_shortcut:
					continue
				var ds := path.delta(float(d.s), float(r.track_idx) * path.step)
				if absf(ds) < 3.0 and absf(r.lateral - float(d.lane)) < 3.0:
					r.hit(null, String(h.get("style", "ice")))
				elif absf(ds) < 8.0 and absf(r.lateral - float(d.lane)) < 7.0:
					r.near_miss()
			d.shadow.queue_free()
			d.ice.queue_free()
			shards.remove_at(k)


## Sideways gusts: a streaky warning, then a push to one side (alternating).
func _tick_wind(h: Dictionary, dt: float) -> void:
	var path := td.main
	var period: float = h.get("period", 6.0)
	var st := _cycle(h, period, 1.0, 1.8)
	var cyc := int((_t + float(h.phase)) / period)
	var side := 1.0 if cyc % 2 == 0 else -1.0
	var fx: CPUParticles3D = h.fx
	fx.emitting = st[0] != 0
	fx.direction = Vector3(side, 0, 0)
	if st[0] != 2:
		return
	# Mostly a sideways force (grip and a little counter-steer beat it) with
	# a small direct drift, so the gust is felt but never takes the wheel.
	var push := float(h.get("strength", 10.0)) * 0.32
	var span := path.delta(float(h.s), float(h.s1))
	for r: Racer in race.racers:
		if r.is_ghost or r.rescue_time > 0.0 or r.on_shortcut:
			continue
		var ds := path.delta(float(h.s), float(r.track_idx) * path.step)
		if ds < 0.0 or ds > span:
			continue
		var rg := path.rgt[r.track_idx]
		r.global_position += rg * side * push * 0.3 * dt
		r.velocity += rg * side * push * 2.4 * dt


## AI helper: move a lane choice out of hazards between s0 and s1.
func avoid_lane(r: Racer, s0: float, s1: float, lat: float, hw: float) -> float:
	var path := td.main
	var out := lat
	var spd := maxf(r.fwd_speed, 10.0)
	for h in list:
		var ds := path.delta(s0, float(h.s))
		if ds < 0.0 or ds > s1 - s0:
			continue
		var arrive := (ds + s0 - float(r.track_idx) * path.step) / spd
		match h.t:
			"roller", "flare":
				var period: float = h.get("period", 5.0)
				var mul := 1.3 if h.t == "flare" else 1.0
				var future := sin((_t + arrive + float(h.phase)) * TAU / period * mul) * (hw + 3.0)
				if absf(future - out) < 5.5:
					out = future + (6.0 if future < 0.0 else -6.0)
			"laser", "eruption":
				var period := 4.0 if h.t == "laser" else 3.8
				var cyc := int((_t + arrive + float(h.phase)) / float(h.get("period", period)))
				var side := 1.0 if cyc % 2 == 0 else -1.0
				if signf(out) == side or absf(out) < 2.0:
					out = -side * hw * 0.5
			"snapper":
				out = minf(absf(out), hw * 0.25) * signf(out) if signf(out) == float(h.side) else out
	return clampf(out, -hw + 2.0, hw - 2.0)
