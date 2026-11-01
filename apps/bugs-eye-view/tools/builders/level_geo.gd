class_name LevelGeo
extends RefCounted
## Level-building vocabulary used by the layout scripts: static geometry with
## surface/camo tags, light zones, hiding spots, pickups, lures, props,
## passages, hazards, threats, lighting. Produces an editable .tscn.

var root: Node3D
var nav: NavigationRegion3D
var geo: Node3D
var zones: Node3D
var pickups: Node3D
var props: Node3D
var actors: Node3D
var lights: Node3D
var decor: Node3D
var _names: Dictionary = {}


func _init(level_name: String) -> void:
	root = Node3D.new()
	root.name = level_name
	nav = NavigationRegion3D.new()
	nav.name = "NavRegion"
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = Phys.WORLD
	nm.agent_radius = 2.0
	nm.agent_height = 8.0
	nm.agent_max_climb = 1.0
	nm.agent_max_slope = 30.0
	nm.cell_size = 0.5
	nm.cell_height = 0.25
	nav.navigation_mesh = nm
	root.add_child(nav)
	geo = _group("Geometry", nav)
	zones = _group("Zones", root)
	pickups = _group("Pickups", root)
	props = _group("Props", root)
	actors = _group("Actors", root)
	lights = _group("Lights", root)
	decor = _group("Decor", root)


func _group(n: String, parent: Node) -> Node3D:
	var g := Node3D.new()
	g.name = n
	parent.add_child(g)
	return g


func uniq(n: String) -> String:
	var i: int = _names.get(n, 0) + 1
	_names[n] = i
	return n if i == 1 else "%s%d" % [n, i]


static func mat(n: String) -> Material:
	return load("res://assets/materials/%s.tres" % n)


func _mesh_child(parent: Node, m: Mesh, material: String, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = m
	mi.material_override = mat(material)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# --- Geometry -----------------------------------------------------------------

func box(n: String, center: Vector3, size: Vector3, material: String, surface: StringName = &"default",
		camo: StringName = &"", rot_y: float = 0.0, shadow: bool = true, parent: Node = null) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = uniq(n)
	b.collision_layer = Phys.WORLD
	b.collision_mask = 0
	b.position = center
	b.rotation.y = rot_y
	b.set_meta(&"surface", surface)
	if camo != &"":
		b.set_meta(&"camo", camo)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var bm := BoxMesh.new()
	bm.size = size
	_mesh_child(b, bm, material, shadow)
	(parent if parent else geo).add_child(b)
	return b


## A sloped board from `a` to `b` (points on its top surface).
func ramp(n: String, a: Vector3, b: Vector3, width: float, material: String,
		surface: StringName = &"wood", camo: StringName = &"") -> StaticBody3D:
	var thickness := 0.8
	var dir := (b - a).normalized()
	var length := a.distance_to(b)
	var basis := Basis.looking_at(dir, Vector3.UP)
	var center := (a + b) * 0.5 - basis.y * thickness * 0.5
	var body := box(n, center, Vector3(width, thickness, length), material, surface, camo)
	body.transform = Transform3D(basis, center)
	return body


func cylinder(n: String, center: Vector3, radius: float, height: float, material: String,
		surface: StringName = &"default", camo: StringName = &"", collide: bool = true) -> Node3D:
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 16
	cm.rings = 1
	if not collide:
		var mi := MeshInstance3D.new()
		mi.name = uniq(n)
		mi.mesh = cm
		mi.material_override = mat(material)
		mi.position = center
		decor.add_child(mi)
		return mi
	var b := StaticBody3D.new()
	b.name = uniq(n)
	b.collision_layer = Phys.WORLD
	b.position = center
	b.set_meta(&"surface", surface)
	if camo != &"":
		b.set_meta(&"camo", camo)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	b.add_child(cs)
	_mesh_child(b, cm, material)
	geo.add_child(b)
	return b


func deco(n: String, m: Mesh, material: String, pos: Vector3, rot: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = uniq(n)
	mi.mesh = m
	mi.material_override = mat(material)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decor.add_child(mi)
	return mi


func deco_box(n: String, pos: Vector3, size: Vector3, material: String, rot: Vector3 = Vector3.ZERO, shadow: bool = true) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return deco(n, bm, material, pos, rot, Vector3.ONE, shadow)


## Floor, four walls and (optionally) a ceiling for a room.
func room(size: Vector3, floor_mat: String, floor_surface: StringName, wall_mat: String, ceiling: bool) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	box("Floor", Vector3(0, -1, 0), Vector3(size.x + 4, 2, size.z + 4), floor_mat, floor_surface)
	box("WallBack", Vector3(0, size.y * 0.5, -hz - 1), Vector3(size.x + 4, size.y, 2), wall_mat, &"default", &"", 0.0, false)
	box("WallFront", Vector3(0, size.y * 0.5, hz + 1), Vector3(size.x + 4, size.y, 2), wall_mat, &"default", &"", 0.0, false)
	box("WallLeft", Vector3(-hx - 1, size.y * 0.5, 0), Vector3(2, size.y, size.z + 4), wall_mat, &"default", &"", 0.0, false)
	box("WallRight", Vector3(hx + 1, size.y * 0.5, 0), Vector3(2, size.y, size.z + 4), wall_mat, &"default", &"", 0.0, false)
	if ceiling:
		box("Ceiling", Vector3(0, size.y + 1, 0), Vector3(size.x + 4, 2, size.z + 4), "ceiling", &"default", &"", 0.0, false)


## Collision-only boundary (keeps flyers inside open levels).
func invisible_wall(n: String, center: Vector3, size: Vector3) -> void:
	var b := box(n, center, size, "glass")
	(b.get_node("Mesh") as Node3D).visible = false


# --- Zones --------------------------------------------------------------------

func _area(node: Area3D, n: String, center: Vector3, size: Vector3, parent: Node = null) -> Area3D:
	node.name = uniq(n)
	node.position = center
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	node.add_child(cs)
	(parent if parent else zones).add_child(node)
	return node


## level: 0 shadow, 1 dim, 2 lit, 3 bright. Adds a floor tint so it reads visually.
func light_zone(n: String, center: Vector3, size: Vector3, level: int, priority: int = 1,
		active: Array = [], inactive: Array = [], tint: bool = true, light_energy: float = 0.0) -> LightZone:
	var z := LightZone.new()
	_area(z, n, center, size)
	z.light_level = level
	z.zone_priority = priority
	z.active_events = PackedStringArray(active)
	z.inactive_events = PackedStringArray(inactive)
	var links: Array[NodePath] = []
	if tint:
		var t := MeshInstance3D.new()
		t.name = "Tint"
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x, 0.05, size.z)
		t.mesh = bm
		t.material_override = mat("shadow_tint" if level <= 1 else "light_tint")
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		t.position = Vector3(0, -size.y * 0.5 + 0.06, 0)
		z.add_child(t)
		links.append(NodePath("Tint"))
	if light_energy > 0.0:
		var l := OmniLight3D.new()
		l.name = "Light"
		l.light_energy = light_energy
		l.omni_range = maxf(size.x, size.z) * 0.9
		l.light_color = Color(1.0, 0.92, 0.75)
		l.position = Vector3(0, size.y * 0.5, 0)
		z.add_child(l)
		links.append(NodePath("Light"))
	z.linked_nodes = links
	return z


func hiding_spot(n: String, center: Vector3, size: Vector3, squeeze: bool = true,
		allowed: Array = ["cockroach"], hint: String = "Hold SQUEEZE to hide") -> HidingSpot:
	var h := HidingSpot.new()
	_area(h, n, center, size)
	h.requires_squeeze = squeeze
	h.allowed_bugs = PackedStringArray(allowed)
	h.hint = hint
	return h


func scent_wiper(n: String, center: Vector3, size: Vector3, active: Array = [], visual: bool = true) -> ScentWiper:
	var w := ScentWiper.new()
	_area(w, n, center, size)
	w.active_events = PackedStringArray(active)
	if visual:
		var mi := MeshInstance3D.new()
		mi.name = "Water"
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x, 0.08, size.z)
		mi.mesh = bm
		mi.material_override = mat("water")
		mi.position = Vector3(0, -size.y * 0.5 + 0.05, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.add_child(mi)
	return w


func sticky_trap(n: String, center: Vector3, size: Vector3, flyers: bool = false) -> StickyTrap:
	var s := StickyTrap.new()
	_area(s, n, center, size)
	s.catches_flyers = flyers
	var mi := MeshInstance3D.new()
	mi.name = "Visual"
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.1, size.z) if not flyers else size
	mi.mesh = bm
	mi.material_override = mat("chip_bag")
	mi.position = Vector3(0, -size.y * 0.5 + 0.05, 0) if not flyers else Vector3.ZERO
	s.add_child(mi)
	return s


func wind(n: String, center: Vector3, size: Vector3, dir: Vector3, strength: float, active: Array) -> WindZone:
	var w := WindZone.new()
	_area(w, n, center, size)
	w.direction = dir
	w.strength = strength
	w.active_events = PackedStringArray(active)
	for i in 3:
		var g := MeshInstance3D.new()
		g.name = "Gust%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x * 0.9, 0.1, 0.6) if absf(dir.x) > 0.5 else Vector3(0.6, 0.1, size.z * 0.9)
		g.mesh = bm
		g.material_override = mat("gust")
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.position = Vector3(0, -size.y * 0.3 + i * size.y * 0.3, (i - 1) * size.z * 0.25)
		w.add_child(g)
	return w


func drain(n: String, center: Vector3, radius: float, respawn: Vector3, active: Array) -> Drain:
	var d := Drain.new()
	_area(d, n, center, Vector3(radius * 2, 2.0, radius * 2))
	d.active_events = PackedStringArray(active)
	var grate := MeshInstance3D.new()
	grate.name = "Grate"
	var cm := CylinderMesh.new()
	cm.top_radius = 1.4
	cm.bottom_radius = 1.4
	cm.height = 0.1
	grate.mesh = cm
	grate.material_override = mat("dark_metal")
	grate.position = Vector3(0, -0.95, 0)
	d.add_child(grate)
	var water := MeshInstance3D.new()
	water.name = "Water"
	var wm := CylinderMesh.new()
	wm.top_radius = radius
	wm.bottom_radius = radius
	wm.height = 0.08
	water.mesh = wm
	water.material_override = mat("water")
	water.position = Vector3(0, -0.9, 0)
	d.add_child(water)
	var sp := Marker3D.new()
	sp.name = "Respawn"
	sp.position = respawn - center
	d.add_child(sp)
	d.respawn_path = NodePath("Respawn")
	return d


func ambient(n: String, pos: Vector3, radius: float, level: float, sound: String, active: Array = [],
		inactive: Array = [], volume: float = -8.0) -> AmbientNoise:
	var a := AmbientNoise.new()
	a.name = uniq(n)
	a.position = pos
	a.radius = radius
	a.level = level
	a.sound_key = StringName(sound)
	a.volume_db = volume
	a.active_events = PackedStringArray(active)
	a.inactive_events = PackedStringArray(inactive)
	zones.add_child(a)
	return a


func rebounder(n: String, pos: Vector3, radius: float) -> Rebounder:
	var r := Rebounder.new()
	r.name = uniq(n)
	r.position = pos
	r.radius = radius
	zones.add_child(r)
	return r


func perch(n: String, base: Vector3, top_offset: Vector3, knock_radius: float = 7.0) -> CatPerch:
	var p := CatPerch.new()
	p.name = uniq(n)
	p.position = base
	p.top_offset = top_offset
	p.knock_radius = knock_radius
	zones.add_child(p)
	return p


# --- Pickups, goal, spawn -------------------------------------------------------

func crumb(pos: Vector3, golden: bool = false) -> Node3D:
	var c := (load("res://scenes/world/%s.tscn" % ("golden_crumb" if golden else "crumb")) as PackedScene).instantiate() as Node3D
	c.name = uniq("GoldenCrumb" if golden else "Crumb")
	c.position = pos
	pickups.add_child(c)
	return c


func goal(pos: Vector3, label: String, rot_y: float = 0.0) -> Node3D:
	var g := (load("res://scenes/world/goal.tscn") as PackedScene).instantiate() as Node3D
	g.name = "Goal"
	g.position = pos
	g.rotation.y = rot_y
	g.set("label", label)
	pickups.add_child(g)
	return g


func spawn(pos: Vector3, yaw: float) -> void:
	var m := Marker3D.new()
	m.name = "PlayerSpawn"
	m.position = pos
	m.rotation.y = yaw
	root.add_child(m)


# --- Interactables --------------------------------------------------------------

func lure(n: String, kind: int, pos: Vector3, size: Vector3, material: String, loud: float = 2.5) -> LureProp:
	var l := LureProp.new()
	_area(l, n, pos, size + Vector3(2.0, 2.0, 2.0), props)
	l.kind = kind as LureProp.Kind
	l.loudness = loud
	var mi := MeshInstance3D.new()
	mi.name = "Visual"
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(material)
	l.add_child(mi)
	if kind == LureProp.Kind.PHONE:
		var glow := MeshInstance3D.new()
		glow.name = "Glow"
		var gm := BoxMesh.new()
		gm.size = Vector3(size.x * 0.85, 0.05, size.z * 0.85)
		glow.mesh = gm
		glow.material_override = mat("screen_glow")
		glow.position = Vector3(0, size.y * 0.5 + 0.03, 0)
		l.add_child(glow)
		var light := OmniLight3D.new()
		light.name = "GlowLight"
		light.light_color = Color(0.7, 0.85, 1.0)
		light.omni_range = 10.0
		light.light_energy = 2.0
		glow.add_child(light)
		l.glow_path = NodePath("Glow")
	return l


func prop(kind: String, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> RigidBody3D:
	var p := (load("res://scenes/props/%s.tscn" % kind) as PackedScene).instantiate() as RigidBody3D
	p.name = uniq(kind.capitalize().replace(" ", ""))
	p.position = pos
	p.rotation = rot
	props.add_child(p)
	return p


func passage(n: String, entry: Vector3, exit: Vector3, allowed: Array, label: String,
		exit_up: Vector3 = Vector3.UP, size: Vector3 = Vector3(4, 4, 4)) -> Passage:
	var p := Passage.new()
	_area(p, n, entry, size, props)
	p.allowed_bugs = PackedStringArray(allowed)
	p.label = label
	var m := Marker3D.new()
	m.name = "Exit"
	var up := exit_up.normalized()
	var fwd := Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT
	var x := fwd.cross(up).normalized()
	m.transform = Transform3D(Basis(x, up, x.cross(up)), exit - entry)
	p.add_child(m)
	p.exit_path = NodePath("Exit")
	var mark := MeshInstance3D.new()
	mark.name = "Marker"
	var tm := TorusMesh.new()
	tm.inner_radius = 1.0
	tm.outer_radius = 1.3
	mark.mesh = tm
	mark.material_override = mat("hole")
	mark.scale = Vector3(1, 0.3, 1)
	p.add_child(mark)
	return p


# --- Threats & directors --------------------------------------------------------

func human(scene: String, route: Array, active: Array, opts: Dictionary = {}) -> Node3D:
	var h := (load(scene) as PackedScene).instantiate() as Node3D
	h.name = uniq(String(opts.get("name", "Human")))
	var pts := PackedVector3Array()
	for p: Vector3 in route:
		pts.append(p)
	h.set("route", pts)
	h.set("active_events", PackedStringArray(active))
	for k: String in opts.keys():
		if k != "name":
			h.set(k, opts[k])
	h.position = route[0] if not route.is_empty() else Vector3.ZERO
	actors.add_child(h)
	return h


func pet(scene: String, pos: Vector3, waypoints: Array, nap: Array, active: Array = []) -> Node3D:
	var p := (load(scene) as PackedScene).instantiate() as Node3D
	p.name = uniq(p.name)
	p.position = pos
	var pts := PackedVector3Array()
	for w: Vector3 in waypoints:
		pts.append(w)
	p.set("waypoints", pts)
	p.set("nap_events", PackedStringArray(nap))
	p.set("active_events", PackedStringArray(active))
	actors.add_child(p)
	return p


func vacuum(pos: Vector3, bmin: Vector3, bmax: Vector3, active: Array) -> Node3D:
	var v := (load("res://scenes/threats/robot_vacuum.tscn") as PackedScene).instantiate() as Node3D
	v.name = "RobotVacuum"
	v.position = pos
	v.set("bounds_min", bmin)
	v.set("bounds_max", bmax)
	v.set("active_events", PackedStringArray(active))
	actors.add_child(v)
	return v


func fog(pos: Vector3, yaw: float, travel: float, duration: float, width: float) -> Node3D:
	var f := (load("res://scenes/hazards/fog_front.tscn") as PackedScene).instantiate() as Node3D
	f.name = "FogFront"
	f.position = pos
	f.rotation.y = yaw
	f.set("travel", travel)
	f.set("duration", duration)
	f.set("width", width)
	actors.add_child(f)
	return f


func boss(kind: int, boss_name: String, subtitle: String, targets: Dictionary) -> BossDirector:
	var b := BossDirector.new()
	b.name = "BossDirector"
	b.kind = kind as BossDirector.Kind
	b.boss_name = boss_name
	b.subtitle = subtitle
	root.add_child(b)
	for k: String in targets.keys():
		b.set(k, NodePath("../" + String(root.get_path_to(targets[k] as Node))))
	return b


func escalation() -> void:
	var e := EscalationDirector.new()
	e.name = "EscalationDirector"
	root.add_child(e)


# --- Lighting -------------------------------------------------------------------

func environment(bg: Color, ambient_color: Color, energy: float = 0.8) -> void:
	var we := WorldEnvironment.new()
	we.name = "Environment"
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = bg
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambient_color
	e.ambient_light_energy = energy
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	lights.add_child(we)


func sun(rot_deg: Vector3, energy: float, color: Color = Color(1.0, 0.94, 0.82)) -> void:
	var s := DirectionalLight3D.new()
	s.name = "Sun"
	s.rotation_degrees = rot_deg
	s.light_energy = energy
	s.light_color = color
	s.shadow_enabled = true
	s.directional_shadow_max_distance = 180.0
	lights.add_child(s)


# --- Finish ---------------------------------------------------------------------

func finalize(script_path: String, level_id: StringName, path: String, tree: SceneTree) -> void:
	# Bake the pets' navmesh from the static colliders (walkable floor only).
	root.remove_child(nav)
	tree.root.add_child(nav)
	nav.bake_navigation_mesh(false)
	var polys := nav.navigation_mesh.get_polygon_count()
	print("  navmesh %s: %d polygons" % [level_id, polys])
	tree.root.remove_child(nav)
	root.add_child(nav)
	root.move_child(nav, 0)
	root.set_script(load(script_path))
	root.set("level_id", level_id)
	ActorBuilder.own_all(root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed %s" % path)
	err = ResourceSaver.save(ps, path)
	if err != OK:
		push_error("save failed %s" % path)
	root.free()
