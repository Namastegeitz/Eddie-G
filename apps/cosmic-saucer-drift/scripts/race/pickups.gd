class_name Pickups
extends Node3D
## Energy Pods, item crates, boost pads and Star Shards. Everything is
## drawn with MultiMeshes and collected by distance checks (no physics).

const POD_R := 2.4
const CRATE_R := 2.7
const POD_RESPAWN := 8.0
const CRATE_RESPAWN := 2.5
const PAD_LEN := 7.0
const PAD_W := 3.2

var race: Node
var td: TrackData
var pods: Array[Dictionary] = []
var crates: Array[Dictionary] = []
var pads: Array[Dictionary] = []
var shards: Array[Dictionary] = []
var _pod_mm: MultiMesh
var _crate_mm: MultiMesh
var _t := 0.0


func setup(p_race: Node) -> void:
	race = p_race
	td = race.td
	var path := td.main
	for f in td.feats:
		var i := path.index_at(f.s)
		match f.t:
			"pod":
				var h: float = f.get("h", 0.0)
				pods.append({"pos": path.pts[i] + path.rgt[i] * f.lane + path.upv[i] * (1.2 + h), "s": f.s, "lane": f.lane, "active": true, "t": 0.0})
			"crate":
				if race.req.get("mode", "") == "tt":
					continue
				crates.append({"pos": path.pts[i] + path.rgt[i] * f.lane + path.upv[i] * 1.4, "s": f.s, "lane": f.lane, "active": true, "t": 0.0})
			"boost":
				pads.append({"s": f.s, "lane": f.lane, "i": i})
	if race.req.get("mode", "") != "boss":
		for sh in td.shards:
			shards.append({"pos": sh.pos, "slot": sh.slot, "active": true})
	_build_buckets()
	_build_visuals()


## Pickups indexed by track sample so each racer only checks nearby ones.
var _pod_bucket := []
var _crate_bucket := []
const BUCKET := 8   # samples per bucket (16 m)


func _build_buckets() -> void:
	var nb := td.main.n / BUCKET + 1
	_pod_bucket.resize(nb)
	_crate_bucket.resize(nb)
	for b in nb:
		_pod_bucket[b] = PackedInt32Array()
		_crate_bucket[b] = PackedInt32Array()
	for k in pods.size():
		var b: int = td.main.index_at(pods[k].s) / BUCKET
		_pod_bucket[b].append(k)
	for k in crates.size():
		var b: int = td.main.index_at(crates[k].s) / BUCKET
		_crate_bucket[b].append(k)


func _near(buckets: Array, idx: int) -> PackedInt32Array:
	var nb := buckets.size()
	var b := idx / BUCKET
	var out := PackedInt32Array()
	for d in [-1, 0, 1]:
		out.append_array(buckets[posmod(b + d, nb)])
	return out


func _build_visuals() -> void:
	# Pods: glowing cyan crystals.
	var pod_mesh := MeshKit.faceted(MeshKit.lathe(PackedVector2Array([Vector2(0, 0.8), Vector2(0.38, 0.35), Vector2(0.5, 0.0), Vector2(0.38, -0.35), Vector2(0, -0.8)]), 6, PackedInt32Array([1, 2, 3])))
	var pod_mat := ShaderMaterial.new()
	pod_mat.shader = preload("res://shaders/spin.gdshader")
	_pod_mm = _mm(pod_mesh, pods.size(), pod_mat, "Pods")
	# Crates: glowing cubes.
	var crate_mesh := BoxMesh.new()
	crate_mesh.size = Vector3(1.7, 1.7, 1.7)
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://shaders/spin.gdshader")
	cm.set_shader_parameter("color", Color(0.85, 0.45, 1.0, 0.8))
	cm.set_shader_parameter("energy", 1.3)
	cm.set_shader_parameter("spin", 1.3)
	cm.set_shader_parameter("tumble", 0.7)
	cm.set_shader_parameter("bob", 0.0)
	cm.set_shader_parameter("frame", 1.0)
	_crate_mm = _mm(crate_mesh, crates.size(), cm, "Crates")
	# Inner "?" cores so crates read at a distance.
	var core := SphereMesh.new()
	core.radius = 0.45
	core.height = 0.9
	core.radial_segments = 8
	core.rings = 4
	for c in crates:
		var mi := MeshInstance3D.new()
		mi.mesh = core
		mi.material_override = TrackBuilder.glow(Color(1.0, 0.95, 0.4), 2.0)
		mi.position = c.pos
		add_child(mi)
		c["core"] = mi
	# Boost pads: chevrons on the road.
	var path := td.main
	for p in pads:
		var mi := MeshInstance3D.new()
		mi.mesh = _chevron_mesh()
		var i: int = p.i
		mi.transform = Transform3D(Basis(path.rgt[i], path.upv[i], -path.tan[i]), path.pts[i] + path.rgt[i] * float(p.lane) + path.upv[i] * 0.05)
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/boost_pad.gdshader")
		mi.material_override = m
		add_child(mi)
	# Star Shards.
	var have: Array = Save.shards_for(td.id)
	for sh in shards:
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(1.4, 2.2, 0.5)
		mi.mesh = pm
		var collected: bool = have[sh.slot]
		var col := Color(1.0, 0.85, 0.3) if not collected else Color(0.5, 0.5, 0.6)
		mi.material_override = TrackBuilder.glow(col, 2.6 if not collected else 0.9)
		mi.position = sh.pos
		add_child(mi)
		var mi2 := MeshInstance3D.new()
		mi2.mesh = pm
		mi2.material_override = mi.material_override
		mi2.rotation_degrees = Vector3(0, 0, 180)
		mi2.position = Vector3(0, -0.9, 0)
		mi.add_child(mi2)
		sh["node"] = mi


func _mm(mesh: Mesh, count: int, mat: Material, node_name: String) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mm


static func _chevron_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := PAD_W * 0.5
	var l := PAD_LEN
	# A flat quad; the shader draws animated chevrons in it.
	var a := Vector3(-w, 0, l * 0.5)
	var b := Vector3(w, 0, l * 0.5)
	var c := Vector3(-w, 0, -l * 0.5)
	var d := Vector3(w, 0, -l * 0.5)
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0, 0)); st.add_vertex(a)
	st.set_uv(Vector2(0, 1)); st.add_vertex(c)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b)
	st.set_uv(Vector2(0, 1)); st.add_vertex(c)
	st.set_uv(Vector2(1, 1)); st.add_vertex(d)
	return st.commit()


func tick(dt: float) -> void:
	_t += dt
	var path := td.main
	for p in pods:
		if not p.active:
			p.t -= dt
			if p.t <= 0.0:
				p.active = true
	for c in crates:
		if not c.active:
			c.t -= dt
			if c.t <= 0.0:
				c.active = true
	for r: Racer in race.racers:
		if r.rescue_time > 0.0 or r.is_ghost or r.finished:
			continue
		var rp := r.global_position
		var pod_r := POD_R * r.pod_magnet_mult
		var near_crates := _near(_crate_bucket, r.track_idx)
		for pk in _near(_pod_bucket, r.track_idx):
			var p: Dictionary = pods[pk]
			if p.active and rp.distance_squared_to(p.pos) < pod_r * pod_r:
				p.active = false
				p.t = POD_RESPAWN
				r.add_energy(race.tuning.pod_energy * race.mod_pod * r.pod_mult)
				r.stats.pods += 1
				r.emit_signal("event", "pod", {})
		if r.item == "" and r.item_roll <= 0.0:
			for ck in near_crates:
				var c: Dictionary = crates[ck]
				if c.active and rp.distance_squared_to(c.pos) < CRATE_R * CRATE_R:
					c.active = false
					c.t = CRATE_RESPAWN
					r.item = race.items.roll(r)
					r.item_roll = 0.9
					r.emit_signal("event", "item_roll", {})
					break
		else:
			for ck in near_crates:
				var c: Dictionary = crates[ck]
				if c.active and rp.distance_squared_to(c.pos) < CRATE_R * CRATE_R:
					c.active = false
					c.t = CRATE_RESPAWN
					r.emit_signal("event", "crate_smash", {})
		if r.grounded:
			for p in pads:
				var ds := path.delta(p.s, float(r.track_idx) * path.step)
				if ds > -PAD_LEN * 0.5 - 1.0 and ds < PAD_LEN * 0.5 + 1.0 and absf(r.lateral - float(p.lane)) < PAD_W * 0.5 + 1.0:
					if r.boost_time < 0.3:
						r.give_boost(race.tuning.pad_boost_time, "pad")
		if r.is_human:
			for sh in shards:
				if sh.active and rp.distance_squared_to(sh.pos) < 3.2 * 3.2:
					sh.active = false
					sh.node.visible = false
					r.stats.shards += 1
					var new_one: bool = race.on_shard(r, sh.slot)
					r.emit_signal("event", "shard", {"new": new_one})
	_update_visuals()


func _update_visuals() -> void:
	# Spin and bob happen in the shader; only collected/respawned state changes here.
	for k in pods.size():
		var p: Dictionary = pods[k]
		var shown: bool = p.active
		if p.get("shown", null) != shown:
			p["shown"] = shown
			_pod_mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ONE * (1.0 if shown else 0.001)), p.pos))
	for k in crates.size():
		var c: Dictionary = crates[k]
		var s := 1.0
		if not c.active:
			s = clampf(1.0 - c.t / 0.4, 0.001, 1.0) if c.t < 0.4 else 0.001
		if c.get("shown", -1.0) != s:
			c["shown"] = s
			_crate_mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ONE * s), c.pos))
			c.core.visible = c.active
	for sh in shards:
		if sh.active:
			sh.node.rotation.y = _t * 2.0


## AI helper: the best active pickup of `kind` between s0 and s1 near `lat`.
func next_target(kind: String, s0: float, s1: float, lat: float) -> Dictionary:
	var list := pods if kind == "pod" else crates
	var best := {}
	var best_score := INF
	var path := td.main
	for p in list:
		if not p.active:
			continue
		var ds := path.delta(s0, p.s)
		if ds < 0.0 or ds > s1 - s0:
			continue
		var score := absf(float(p.lane) - lat) + ds * 0.04
		if score < best_score:
			best_score = score
			best = p
	return best
