class_name WorldView3D
extends SubViewportContainer
## First-person view: the same RunSim seen through the animal's eyes, as a
## low-poly 3D scene (1 unit = 1 tile, rows run along -Z). Hazards are built
## from their content files' painter id and colours, so new hazard files
## show up here too. Under dense canopy the light drops and leaves close in
## overhead, but nothing is hidden: this is the view that sees under them.

const AHEAD := 18
const BEHIND := 2
const MID := 4.5                 # centre of the 9 play columns

var sim: RunSim
var map: Dictionary = {}
var pal: Dictionary = {}
var animal: Dictionary = {}
var vp3: SubViewport
var world3: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var eye_h := 0.55
var t := 0.0
var shade := 0.0                 # 0 open sky .. 1 deep under canopy
var _lanes := {}
var _ents := {}
var _preds := {}
var _items := {}
var _swoops := {}
var _mats := {}
var _meshes := {}
var _sky := Color("9ad0e8")
var _walls: Array[Node3D] = []


func setup(run: RunSim, animal_def: Dictionary) -> void:
	sim = run
	map = run.world.map
	pal = map.get("palette", {})
	animal = animal_def
	stretch = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp3 = SubViewport.new()
	vp3.own_world_3d = true
	vp3.msaa_3d = Viewport.MSAA_DISABLED
	vp3.handle_input_locally = false
	vp3.gui_disable_input = true
	add_child(vp3)
	world3 = Node3D.new()
	vp3.add_child(world3)
	var atm: Dictionary = map.get("atmosphere", {})
	_sky = color("sky", "#1a4a2a").lerp(Color("bfe0d8"), 0.55)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.92, 0.82)
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_light_color = Color(String(atm.get("fog_color", _sky.to_html(false))))
	env.fog_density = 0.045 + float(atm.get("mist", 0.0)) * 0.07
	var we := WorldEnvironment.new()
	we.environment = env
	world3.add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 28, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = false
	world3.add_child(sun)
	cam = Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 86.0
	cam.near = 0.05
	cam.far = float(AHEAD) + 6.0
	world3.add_child(cam)
	cam.current = true
	eye_h = 0.62 + 0.3 * float(animal.get("look", {}).get("size", 0.75))
	# two long jungle walls follow the camera and hide where things loop around
	for side in [-1.0, 1.0]:
		var wall := box(Vector3(5.0, 3.2, float(AHEAD + BEHIND + 8)), color("canopy_dark", "#0b3a1a"), Vector3.ZERO, world3)
		wall.set_meta("side", side)
		_walls.append(wall)


func color(key: String, fallback := "#3c9a3a") -> Color:
	return Color(String(pal.get(key, fallback)))


# ------------------------------------------------------------------ frame

func update_view(dt: float) -> void:
	if not is_visible_in_tree():
		return
	t += dt
	var dp := sim.display_pos()
	var lift := sim.hop_height()
	var y := eye_h + lift * 0.7 + sin(t * 2.2) * 0.008
	if sim.state in ["respawn", "dead", "restart", "over"] and sim.cause != "":
		y = lerpf(cam.position.y, 0.05 if sim.cause in ["drowned", "fell"] else 0.18, minf(1.0, dt * 3.0))
	cam.position = Vector3(dp.x, y, -dp.y + 0.8)
	cam.rotation_degrees = Vector3(-27.0 + lift * 6.0, 0.0, 0.0)
	var covered := sim.world.lane(sim.row).covered or sim.world.lane(sim.row + 1).covered
	shade = move_toward(shade, 1.0 if covered else 0.0, dt * 1.5)
	env.ambient_light_energy = lerpf(0.75, 0.42, shade)
	sun.light_energy = lerpf(1.0, 0.3, shade)
	env.background_color = _sky.lerp(color("canopy_dark", "#0b3a1a"), shade * 0.85)
	var lo := sim.row - BEHIND
	var hi := sim.row + AHEAD
	for wall in _walls:
		wall.position = Vector3(MID + float(wall.get_meta("side")) * 8.4, 1.5, -(dp.y + (AHEAD - BEHIND) * 0.5))
	sim.world.ensure(hi + 2)
	for r in _lanes.keys():
		if r < lo or r > hi:
			_lanes[r].queue_free()
			_lanes.erase(r)
	var seen := {}
	var seen_items := {}
	for r in range(lo, hi + 1):
		var l := sim.world.lane(r)
		if not _lanes.has(r):
			_lanes[r] = _build_lane(l, r)
		_update_lane_fx(l, _lanes[r])
		for i in l.ents.size():
			var key := "%d:%d" % [r, i]
			seen[key] = true
			var n: Node3D = _ents.get(key)
			if n == null:
				n = _build_ent(l, l.ents[i])
				world3.add_child(n)
				_ents[key] = n
			_place_ent(n, l, l.ents[i])
		for j in l.preds.size():
			var p: Dictionary = l.preds[j]
			if p.kind == "swooper":
				continue
			var pk := "p%d:%d" % [r, j]
			seen[pk] = true
			var pn: Node3D = _preds.get(pk)
			if pn == null:
				pn = _build_pred(l, p)
				world3.add_child(pn)
				_preds[pk] = pn
			_place_pred(pn, l, p)
		for it in l.items:
			var ik := String(it.key)
			if sim.taken.has(ik) or (it.bonus and not sim.forages()):
				continue
			seen_items[ik] = true
			var inode: Node3D = _items.get(ik)
			if inode == null:
				inode = _build_item(String(it.id))
				world3.add_child(inode)
				_items[ik] = inode
			var ix: float = float(it.col) + 0.5
			if int(it.ent) >= 0:
				ix = sim.world.ent_x(l, l.ents[int(it.ent)], sim.wt) + float(it.rel)
			inode.position = Vector3(ix, 0.35 + sin(t * 3.0 + ix) * 0.05, -r)
			inode.rotation.y = t * 2.0
	_prune(_ents, seen)
	_prune(_preds, seen)
	_prune(_items, seen_items)
	_update_swoops(lo, hi)


func _prune(d: Dictionary, seen: Dictionary) -> void:
	for k in d.keys():
		if not seen.has(k):
			d[k].queue_free()
			d.erase(k)


# ------------------------------------------------------------------ building blocks

func mat(c: Color, emissive := false) -> StandardMaterial3D:
	var key := c.to_html() + ("e" if emissive else "")
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.8
	_mats[key] = m
	return m


func _mi(mesh: Mesh, c: Color, pos: Vector3, parent: Node3D, rot := Vector3.ZERO, emissive := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(c, emissive)
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func box(size: Vector3, c: Color, pos: Vector3, parent: Node3D, rot := Vector3.ZERO, emissive := false) -> MeshInstance3D:
	var key := "b%s" % size
	if not _meshes.has(key):
		var m := BoxMesh.new()
		m.size = size
		_meshes[key] = m
	return _mi(_meshes[key], c, pos, parent, rot, emissive)


func sph(r: float, c: Color, pos: Vector3, parent: Node3D, scale := Vector3.ONE) -> MeshInstance3D:
	var key := "s%.2f" % r
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = 10
		m.rings = 6
		_meshes[key] = m
	var mi := _mi(_meshes[key], c, pos, parent)
	mi.scale = scale
	return mi


func cyl(r: float, h: float, c: Color, pos: Vector3, parent: Node3D, rot := Vector3.ZERO, top := -1.0) -> MeshInstance3D:
	var key := "c%.2f:%.2f:%.2f" % [r, h, top]
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = r if top < 0.0 else top
		m.bottom_radius = r
		m.height = h
		m.radial_segments = 10
		_meshes[key] = m
	return _mi(_meshes[key], c, pos, parent, rot)


func torus(inner: float, outer: float, c: Color, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var key := "t%.2f:%.2f" % [inner, outer]
	if not _meshes.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = 16
		m.ring_segments = 6
		_meshes[key] = m
	return _mi(_meshes[key], c, pos, parent)


static func hc(cl: Dictionary, key: String, fallback := "#888888") -> Color:
	return Color(String(cl.get(key, fallback)))


# ------------------------------------------------------------------ lanes

func _build_lane(l: Lane, r: int) -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(0, 0, -r)
	world3.add_child(n)
	var alt := r % 2 == 0
	var rng := RandomNumberGenerator.new()
	rng.seed = l.deco + r * 13
	match l.type:
		"water":
			box(Vector3(26, 0.3, 1.0), color("water"), Vector3(MID, -0.27, 0), n)
		"ground":
			box(Vector3(26, 0.3, 1.0), color("ground_alt" if alt else "ground"), Vector3(MID, -0.15, 0), n)
			box(Vector3(26, 0.02, 0.06), color("ground").darkened(0.2), Vector3(MID, 0.005, -0.25), n)
		_:
			var g := color("safe_alt" if alt else "safe")
			if l.goal:
				box(Vector3(26, 0.3, 1.0), color("goal", "#9cf06a"), Vector3(MID, -0.15, 0), n, Vector3.ZERO, true)
			else:
				box(Vector3(26, 0.3, 1.0), g, Vector3(MID, -0.15, 0), n)
			for k in 2:
				var gx := rng.randf_range(-0.5, 9.5)
				if l.tiles.has(int(floorf(gx))):
					continue
				cyl(0.05, 0.16, g.lightened(0.25), Vector3(gx, 0.08, rng.randf_range(-0.4, 0.4)), n, Vector3.ZERO, 0.0)
	for col in l.tiles:
		var tile: Dictionary = l.tiles[col]
		var hz := Content.hazard(String(tile.hazard))
		var tc: Dictionary = hz.get("art", {}).get("colors", {})
		var x := float(col) + 0.5
		match String(tile.kind):
			"gap":
				box(Vector3(0.98, 0.04, 0.98), hc(tc, "body").darkened(0.5), Vector3(x, 0.01, 0), n)
				box(Vector3(1.0, 0.03, 0.06), hc(tc, "edge"), Vector3(x, 0.02, -0.48), n)
			"brush":
				for k in 3:
					sph(0.3, hc(tc, "body").lightened(0.06 * k), Vector3(x - 0.2 + k * 0.2, 0.25 + (k % 2) * 0.1, rng.randf_range(-0.15, 0.15)), n)
			"quicksand":
				cyl(0.44, 0.02, hc(tc, "body"), Vector3(x, 0.01, 0), n)
				torus(0.15, 0.22, hc(tc, "swirl"), Vector3(x, 0.025, 0), n)
	if r % 3 == 0:
		cyl(0.18, 3.0, Color("5a3e26"), Vector3(-1.2, 1.4, 0), n)
		cyl(0.18, 3.0, Color("5a3e26"), Vector3(10.2, 1.4, 0), n)
		sph(0.7, color("canopy"), Vector3(-1.2, 2.9, 0), n, Vector3(1.2, 0.7, 1.0))
		sph(0.7, color("canopy"), Vector3(10.2, 2.9, 0), n, Vector3(1.2, 0.7, 1.0))
	if l.covered:
		var cnp := color("canopy")
		box(Vector3(14.0, 0.5, 1.02), cnp.darkened(0.35), Vector3(MID, 2.4, 0), n)
		for k in 2:
			sph(0.55, cnp.lightened(0.08 * (k % 2)), Vector3(rng.randf_range(-0.5, 9.5), 2.05, rng.randf_range(-0.4, 0.4)), n, Vector3(1.6, 0.6, 1.3))
		cyl(0.02, 1.4, Color("3a6a2a"), Vector3(rng.randf_range(0.0, 9.0), 1.6, 0), n)
	if not l.effect.is_empty():
		_build_lane_fx(l, n)
	return n


func _build_lane_fx(l: Lane, n: Node3D) -> void:
	var fx := Node3D.new()
	fx.name = "Fx"
	n.add_child(fx)
	var hz := Content.hazard(String(l.effect.hazard))
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	match String(l.effect.kind):
		"fire":
			for i in 5:
				sph(0.3, Color(0.4, 0.4, 0.4, 0.5), Vector3(i * 2.0 + 0.5, 0.5, 0), fx).set_meta("smoke", true)
			for i in 10:
				cyl(0.18, 0.7, hc(cl, "body"), Vector3(i + 0.5, 0.35, sin(i * 2.1) * 0.2), fx, Vector3.ZERO, 0.0).set_meta("flame", i)
		"tide":
			box(Vector3(14.0, 0.06, 1.0), Color(hc(cl, "body"), 0.85), Vector3(MID, -0.2, 0), fx).set_meta("water", true)
		"mudslide":
			box(Vector3(14.0, 0.05, 1.0), hc(cl, "body"), Vector3(MID, 0.02, 0), fx).set_meta("mud", true)


func _update_lane_fx(l: Lane, n: Node3D) -> void:
	if l.effect.is_empty():
		return
	var fx: Node3D = n.get_node_or_null("Fx")
	if fx == null:
		return
	var st := l.effect_state(sim.wt)
	var k := float(st[1])
	for c in fx.get_children():
		var mi := c as Node3D
		if mi.has_meta("smoke"):
			mi.visible = st[0] == "warn"
			mi.scale = Vector3.ONE * (0.6 + k * 0.6)
			mi.position.y = 0.3 + k * 0.6
		elif mi.has_meta("flame"):
			mi.visible = st[0] == "active"
			mi.scale = Vector3(1.0, 0.7 + 0.35 * sin(t * 14.0 + int(mi.get_meta("flame")) * 1.7), 1.0)
		elif mi.has_meta("water"):
			mi.visible = st[0] in ["warn", "active"]
			mi.position.y = -0.2 + (0.22 * k if st[0] == "warn" else 0.22)
		elif mi.has_meta("mud"):
			mi.visible = st[0] == "active"
			mi.position.z = 0.5 * k - 0.25


# ------------------------------------------------------------------ moving things

func _build_ent(l: Lane, e: Ent) -> Node3D:
	var hz := Content.hazard(e.hazard)
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	var L := e.length
	var n := Node3D.new()
	var body := hc(cl, "body")
	match String(hz.get("art", {}).get("painter", "")):
		"truck":
			box(Vector3(L * 0.68, 0.5, 0.62), body, Vector3(-L * 0.15, 0.36, 0), n)
			box(Vector3(L * 0.26, 0.68, 0.6), hc(cl, "cab"), Vector3(L * 0.36, 0.45, 0), n)
			box(Vector3(0.04, 0.25, 0.46), Color("9fd0e8"), Vector3(L * 0.49, 0.6, 0), n)
			for k in 2:
				cyl(0.13, L * 0.62, hc(cl, "cargo").lightened(0.08 * k), Vector3(-L * 0.15, 0.7, -0.13 + k * 0.26), n, Vector3(0, 0, 90))
		"jeep":
			box(Vector3(L, 0.42, 0.62), body, Vector3(0, 0.3, 0), n)
			box(Vector3(L * 0.5, 0.26, 0.56), hc(cl, "roof"), Vector3(-L * 0.08, 0.62, 0), n)
			box(Vector3(0.04, 0.22, 0.5), Color("9fd0e8"), Vector3(L * 0.18, 0.6, 0), n)
		"tractor":
			box(Vector3(L * 0.55, 0.4, 0.62), hc(cl, "cargo").darkened(0.35), Vector3(-L * 0.2, 0.3, 0), n)
			for k2 in 6:
				sph(0.1, hc(cl, "cargo"), Vector3(-L * 0.4 + k2 * L * 0.08, 0.55, sin(k2) * 0.15), n)
			box(Vector3(L * 0.32, 0.6, 0.5), body, Vector3(L * 0.3, 0.42, 0), n)
			cyl(0.3, 0.14, Color("1a1a1a"), Vector3(L * 0.22, 0.3, -0.33), n, Vector3(90, 0, 0))
			cyl(0.3, 0.14, Color("1a1a1a"), Vector3(L * 0.22, 0.3, 0.33), n, Vector3(90, 0, 0))
		"cart":
			box(Vector3(L * 0.5, 0.4, 0.6), body, Vector3(-L * 0.2, 0.35, 0), n)
			sph(0.22, hc(cl, "animal"), Vector3(L * 0.3, 0.4, 0), n, Vector3(1.6, 1.0, 1.0))
			sph(0.12, hc(cl, "animal").darkened(0.1), Vector3(L * 0.48, 0.5, 0), n)
		"scooter":
			box(Vector3(L * 0.9, 0.25, 0.22), body, Vector3(0, 0.3, 0), n)
			sph(0.15, hc(cl, "rider"), Vector3(0, 0.62, 0), n)
		"herd", "runner", "lizard", "elephant":
			var big := 1.0
			if hz.art.painter == "elephant":
				big = 1.8
			var bc := body
			var hcol := body.darkened(0.08)
			if hz.art.painter == "runner":
				hcol = hc(cl, "neck")
			sph(0.24 * big, bc, Vector3(0, 0.3 * big, 0), n, Vector3(L * 0.9 / (0.48 * big), 0.9, 1.0))
			sph(0.13 * big, hcol, Vector3(L * 0.45, (0.4 if hz.art.painter != "runner" else 0.65) * big, 0), n)
			if hz.art.painter == "elephant":
				for ez in [-0.3, 0.3]:
					sph(0.2, hc(cl, "ear"), Vector3(L * 0.38, 0.6, ez), n, Vector3(0.3, 1.0, 1.0))
				cyl(0.06, 0.5, body, Vector3(L * 0.55, 0.3, 0), n)
			box(Vector3(L * 0.6, 0.2 * big, 0.3 * big), bc.darkened(0.3), Vector3(0, 0.1 * big, 0), n)
		"ants":
			sph(0.08, body, Vector3(0, 0.08, 0), n, Vector3(2.0, 1.0, 1.0))
			box(Vector3(0.18, 0.02, 0.12), hc(cl, "leaf"), Vector3(0.05, 0.22, 0), n, Vector3(0, 0, 25))
		"roll_log", "log":
			cyl(0.3, L, body, Vector3(0, 0.12 if hz.kind == "platform" else 0.3, 0), n, Vector3(0, 0, 90))
			cyl(0.31, 0.04, hc(cl, "ring"), Vector3(L * 0.5, 0.12 if hz.kind == "platform" else 0.3, 0), n, Vector3(0, 0, 90))
			if cl.has("moss"):
				sph(0.12, hc(cl, "moss"), Vector3(-L * 0.2, 0.4, 0), n, Vector3(2.0, 0.5, 1.2))
		"boulder":
			sph(minf(L, 1.0) * 0.45, body, Vector3(0, 0.42, 0), n)
		"vine":
			cyl(0.03, 2.4, Color("3a6a2a"), Vector3(0, 1.7, 0), n)
			sph(0.3, hc(cl, "leaf"), Vector3(0, 0.5, 0), n, Vector3(1.0, 1.3, 1.0))
		"lilypad":
			cyl(0.46, 0.04, body, Vector3(0, 0.0, 0), n)
		"caiman_back":
			box(Vector3(L, 0.16, 0.48), body, Vector3(0, 0.0, 0), n)
			for ez2 in [-0.12, 0.12]:
				sph(0.06, hc(cl, "eye"), Vector3(L * 0.42, 0.1, ez2), n)
		"branch":
			cyl(0.1, L, body, Vector3(0, 0.05, 0), n, Vector3(0, 0, 90))
			for k3 in 3:
				sph(0.18, hc(cl, "leaf"), Vector3(-L * 0.3 + k3 * L * 0.3, 0.15, (k3 % 2 - 0.5) * 0.4), n, Vector3(1.4, 0.5, 1.0))
		"boat":
			box(Vector3(L, 0.28, 0.7), body, Vector3(0, 0.02, 0), n)
			for tz in [-0.36, 0.36]:
				box(Vector3(L * 0.98, 0.1, 0.06), hc(cl, "trim"), Vector3(0, 0.2, tz), n)
			for k5 in 2:
				cyl(0.03, 0.45, Color("5a3a22"), Vector3(-L * 0.15 + k5 * L * 0.3, 0.38, 0), n)
			box(Vector3(L * 0.35, 0.05, 0.6), hc(cl, "canopy"), Vector3(0, 0.6, 0), n)
		"bridge":
			var nplank := maxi(1, int(L / 0.25))
			for k4 in nplank:
				box(Vector3(0.2, 0.06, 0.64), hc(cl, "plank").lightened(0.05 * (k4 % 3)), Vector3(-L * 0.5 + (k4 + 0.5) * L / nplank, 0.0, 0), n)
			for rz in [-0.34, 0.34]:
				cyl(0.025, L, hc(cl, "rope"), Vector3(0, 0.45, rz), n, Vector3(0, 0, 90))
		"stones":
			sph(0.42, body, Vector3(0, -0.06, 0), n, Vector3(1.0, 0.45, 0.9))
			sph(0.2, hc(cl, "moss"), Vector3(0.1, 0.08, 0), n, Vector3(1.2, 0.4, 1.0))
		_:
			box(Vector3(L, 0.5, 0.6), body, Vector3(0, 0.3, 0), n)
	n.set_meta("platform", e.platform)
	return n


func _place_ent(n: Node3D, l: Lane, e: Ent) -> void:
	var x := sim.world.ent_x(l, e, sim.wt)
	var dir := 1.0 if l.speed >= 0.0 else -1.0
	if e.motion == "pendulum":
		dir = 1.0 if e.velocity(0.0, sim.wt) >= 0.0 else -1.0
	n.position = Vector3(x + e.length * 0.5, 0.0, -l.row)
	n.rotation_degrees.y = 0.0 if dir > 0 else 180.0
	n.visible = e.active(sim.wt) and x > -4.0 and x < 13.0
	if e.platform and e.dive_period > 0.0:
		match sim.world.ent_dive(l, e, sim.wt):
			"warn":
				n.position.y = sin(t * 30.0) * 0.02 - 0.03
			"under":
				n.position.y = -0.45
	elif e.platform:
		n.position.y = sin(t * 2.0 + x) * 0.015


# ------------------------------------------------------------------ predators

func _build_pred(_l: Lane, p: Dictionary) -> Node3D:
	var hz := Content.hazard(String(p.hazard))
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	var n := Node3D.new()
	match String(p.kind):
		"surfacer":
			var head := Node3D.new()
			head.name = "Head"
			n.add_child(head)
			var span := float(p.get("span", 1.2))
			box(Vector3(span, 0.14, 0.5), hc(cl, "body"), Vector3(0, 0.0, 0), head)
			var upper := Node3D.new()
			upper.name = "Upper"
			upper.position = Vector3(-span * 0.5, 0.08, 0)
			head.add_child(upper)
			box(Vector3(span, 0.12, 0.5), hc(cl, "body").lightened(0.05), Vector3(span * 0.5, 0.06, 0), upper)
			for ez in [-0.15, 0.15]:
				sph(0.07, hc(cl, "eye"), Vector3(-span * 0.35, 0.2, ez), upper)
			var ring := torus(0.3, 0.38, Color(1, 1, 1, 0.6), Vector3.ZERO, n)
			ring.name = "Ring"
		"striker":
			var tiger := String(hz.get("art", {}).get("painter", "")) == "tiger"
			if tiger:
				for k in 5:
					cyl(0.06, 0.7, Color("8a9a4a").darkened(0.1 * (k % 3)), Vector3(-0.3 + k * 0.15, 0.35, sin(k * 1.7) * 0.2), n, Vector3.ZERO, 0.0)
			else:
				torus(0.12, 0.26, hc(cl, "body"), Vector3(0, 0.08, 0), n)
			var strike := Node3D.new()
			strike.name = "Strike"
			n.add_child(strike)
			if tiger:
				sph(0.3, hc(cl, "body"), Vector3(0, 0.35, 0), strike, Vector3(2.0, 1.0, 1.0))
			else:
				sph(0.12, hc(cl, "body"), Vector3(0, 0.15, 0), strike, Vector3(4.0, 1.0, 1.0))
			var head2 := sph(0.13, hc(cl, "body").darkened(0.1), Vector3(0, 0.28, 0), n)
			head2.name = "Head"
		"faller":
			var sh := cyl(0.4, 0.01, Color(0, 0, 0, 0.35), Vector3(0, 0.01, 0), n)
			sh.name = "Shadow"
			var drop := Node3D.new()
			drop.name = "Drop"
			n.add_child(drop)
			if String(hz.get("art", {}).get("painter", "")) == "fruit_fall":
				sph(0.22, hc(cl, "body"), Vector3.ZERO, drop)
			else:
				cyl(0.08, 0.9, hc(cl, "body"), Vector3.ZERO, drop, Vector3(0, 0, 90))
				sph(0.2, hc(cl, "leaf", "#4a9a3a"), Vector3(0.35, 0.05, 0), drop, Vector3(1.3, 0.6, 1.0))
	return n


func _place_pred(n: Node3D, l: Lane, p: Dictionary) -> void:
	var st := l.pred_state(p, sim.wt)
	var k := float(st[1])
	match String(p.kind):
		"surfacer":
			n.position = Vector3(float(p.x), 0.0, -l.row)
			var head: Node3D = n.get_node("Head")
			var ring: Node3D = n.get_node("Ring")
			ring.visible = st[0] == "warn"
			ring.scale = Vector3.ONE * (0.6 + k * 1.5)
			head.visible = st[0] == "active"
			if st[0] == "active":
				var rise := sin(minf(1.0, k * 3.0) * PI * 0.5)
				head.position.y = -0.3 + rise * 0.32
				(head.get_node("Upper") as Node3D).rotation_degrees.z = -sin(minf(1.0, k) * PI) * 35.0
		"striker":
			var col := int(p.col)
			n.position = Vector3(col + 0.5, 0.0, -l.row)
			var hidden := bool(p.get("hidden", false))
			var strike: Node3D = n.get_node("Strike")
			var head2: Node3D = n.get_node("Head")
			head2.visible = not hidden or st[0] == "warn"
			head2.position.y = 0.28 + (sin(t * 40.0) * 0.03 + k * 0.12 if st[0] == "warn" else 0.0)
			strike.visible = st[0] == "active"
			if st[0] == "active":
				var ext := sin(minf(1.0, k) * PI) * float(p.span)
				strike.position.x = int(p.dir) * ext * 0.5
				strike.scale = Vector3(maxf(0.2, ext), 1.0, 1.0)
		"faller":
			n.position = Vector3(int(p.col) + 0.5, 0.0, -l.row)
			var sh: Node3D = n.get_node("Shadow")
			var drop: Node3D = n.get_node("Drop")
			sh.visible = st[0] in ["warn", "active"]
			sh.scale = Vector3.ONE * (0.4 + (k if st[0] == "warn" else 1.0) * 0.8)
			drop.visible = st[0] == "active" or st[0] == "warn"
			if st[0] == "warn":
				drop.position = Vector3(sin(t * 30.0) * 0.03, 2.6, 0)
			else:
				drop.position = Vector3(0, lerpf(2.6, 0.12, minf(1.0, k * 3.0)), 0)


func _update_swoops(lo: int, hi: int) -> void:
	var w := sim.world
	var seen := {}
	for i in w.swoopers.size():
		var s: Dictionary = w.swoopers[i]
		if int(s.hi) < lo or int(s.lo) > hi:
			continue
		seen[i] = true
		var n: Node3D = _swoops.get(i)
		if n == null:
			n = Node3D.new()
			world3.add_child(n)
			var hz := Content.hazard(String(s.hazard))
			var cl: Dictionary = hz.get("art", {}).get("colors", {})
			var bird := Node3D.new()
			bird.name = "Bird"
			n.add_child(bird)
			box(Vector3(1.6, 0.04, 0.4), hc(cl, "wing", "#2a2a30"), Vector3.ZERO, bird)
			sph(0.16, hc(cl, "body", "#55565e"), Vector3(0, 0.02, 0), bird, Vector3(1.0, 0.8, 2.0))
			var sh := cyl(0.5, 0.01, Color(0, 0, 0, 0.35), Vector3.ZERO, n)
			sh.name = "Shadow"
			_swoops[i] = n
		var st := w.pred_state(s, sim.wt)
		var col := w.swoop_col(s, sim.wt)
		var bird2: Node3D = n.get_node("Bird")
		var sh2: Node3D = n.get_node("Shadow")
		n.position = Vector3(col + 0.5, 0, 0)
		bird2.visible = st[0] == "active"
		sh2.visible = st[0] in ["warn", "active"]
		var k := float(st[1])
		if st[0] == "warn":
			sh2.position = Vector3(0, 0.02, -float(s.hi))
			sh2.scale = Vector3.ONE * (0.5 + k)
		elif st[0] == "active":
			var z := -lerpf(float(s.hi), float(s.lo), k)
			bird2.position = Vector3(0, lerpf(2.4, 0.5, minf(1.0, k * 2.0)), z)
			sh2.position = Vector3(0, 0.02, z)
	for k2 in _swoops.keys():
		if not seen.has(k2):
			_swoops[k2].queue_free()
			_swoops.erase(k2)


# ------------------------------------------------------------------ items

func _build_item(id: String) -> Node3D:
	var def := Content.collectible(id)
	var cl: Dictionary = def.get("art", {}).get("colors", {})
	var n := Node3D.new()
	match String(def.get("art", {}).get("painter", "")):
		"berry":
			for k in 3:
				sph(0.08, Color("e8343a").darkened(0.1 * k), Vector3(-0.06 + k * 0.06, (k % 2) * 0.06, 0), n)
		"beetle":
			sph(0.1, hc(cl, "body"), Vector3.ZERO, n, Vector3(1.0, 0.7, 1.4))
		"fruit":
			sph(0.13, hc(cl, "body"), Vector3.ZERO, n)
		"amber":
			box(Vector3(0.18, 0.18, 0.18), hc(cl, "body"), Vector3.ZERO, n, Vector3(45, 0, 45), true)
		_:
			sph(0.11, hc(cl, "body", "#6a4a32"), Vector3.ZERO, n)
	return n
