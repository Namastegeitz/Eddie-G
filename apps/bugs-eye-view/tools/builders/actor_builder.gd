class_name ActorBuilder
## Builds the reusable actor scenes (bugs, threats, hazards, pickups, props,
## FX, camera) from primitives. Every scene keeps its look under a "Visual"
## node so real models can replace it without touching gameplay.

static func mat(n: String) -> Material:
	return load("res://assets/materials/%s.tres" % n)


static func own_all(root: Node, node: Node = null) -> void:
	if node == null:
		node = root
	for c in node.get_children():
		c.owner = root
		if c.scene_file_path == "":
			own_all(root, c)


static func pack(root: Node, path: String, force: bool) -> void:
	if not force and ResourceLoader.exists(path):
		root.free()
		return
	own_all(root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed %s" % path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	err = ResourceSaver.save(ps, path)
	if err != OK:
		push_error("save failed %s" % path)
	root.free()


static func mesh(parent: Node, name: String, m: Mesh, material: String, pos: Vector3 = Vector3.ZERO,
		rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var unique := name
	var i := 2
	while parent.has_node(NodePath(unique)):
		unique = "%s%d" % [name, i]
		i += 1
	mi.name = unique
	mi.mesh = m
	mi.material_override = mat(material)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


## Merges the plain mesh children of `parent` that share a material into one
## mesh per material (far fewer draw calls on phones, same look). Pivots
## (nodes with children) and names in `skip` stay separate. A merged mesh keeps
## the first part's name.
static func merge_meshes(parent: Node, skip: Array = []) -> void:
	var groups := {}
	var order: Array = []
	for c in parent.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.get_child_count() > 0 or mi.mesh == null or skip.has(String(mi.name)):
			continue
		var key: Material = mi.material_override
		if not groups.has(key):
			groups[key] = []
			order.append(key)
		groups[key].append(mi)
	for key: Material in order:
		var list: Array = groups[key]
		if list.size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mi: MeshInstance3D in list:
			st.append_from(mi.mesh, 0, mi.transform)
		var first := list[0] as MeshInstance3D
		var merged := MeshInstance3D.new()
		# Compressed vertices (16-bit positions, packed normals): about half the
		# download for the same shape.
		merged.mesh = st.commit(null, Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		merged.material_override = key
		merged.cast_shadow = first.cast_shadow
		var keep_name := first.name
		var idx := first.get_index()
		for mi: MeshInstance3D in list:
			parent.remove_child(mi)
			mi.free()
		parent.add_child(merged)
		parent.move_child(merged, mini(idx, parent.get_child_count() - 1))
		merged.name = keep_name


## Small things stop drawing far away (they'd be a pixel or two anyway):
## fewer draw calls, smoother on phones. Lights fade out too.
static func _cull_far(root: Node, dist: float) -> void:
	for n in root.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		g.visibility_range_end = dist
		g.visibility_range_end_margin = dist * 0.15
		g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for n in root.find_children("*", "Light3D", true, false):
		var l := n as Light3D
		l.distance_fade_enabled = true
		l.distance_fade_begin = dist * 0.8
		l.distance_fade_length = dist * 0.2


static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func sphere(r: float, h: float = -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if h < 0.0 else h
	s.radial_segments = 20
	s.rings = 10
	return s


static func cyl(r: float, h: float, r2: float = -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r if r2 < 0.0 else r2
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 20
	c.rings = 1
	return c


static func capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 16
	c.rings = 6
	return c


static func shape(parent: Node, s: Shape3D, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, name: String = "Shape") -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.name = name
	cs.shape = s
	cs.position = pos
	cs.rotation = rot
	parent.add_child(cs)
	return cs


static func sphere_shape(r: float) -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = r
	return s


static func box_shape(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s


static func node3d(parent: Node, name: String, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	parent.add_child(n)
	return n


## Adds a model slot to a visual: a generated model with this id replaces
## every placeholder child except those named in `keep`.
static func add_skin(visual: Node3D, model_id: String, fit: Vector3, center: Vector3 = Vector3.ZERO,
		keep: Array = [], yaw_deg: float = 180.0) -> SkinAnchor:
	var a := SkinAnchor.new()
	a.name = "Skin"
	a.model_id = model_id
	a.fit_size = fit
	a.position = center
	a.yaw_offset_deg = yaw_deg
	var paths: Array[NodePath] = []
	for c in visual.get_children():
		if not keep.has(String(c.name)):
			paths.append(NodePath("../" + String(c.name)))
	a.hide_paths = paths
	visual.add_child(a)
	return a


static func scripted(type_node: Node, script_path: String, name: String) -> Node:
	type_node.name = name
	type_node.set_script(load(script_path))
	return type_node


# --- Bugs ---------------------------------------------------------------------

## One jointed leg: hip pivot (swings around Y, lifts around Z) -> femur ->
## knee pivot -> tibia -> foot. `fwd` angles it forward (+) or back (-).
## BugRig animates the pivots using the metadata stored here.
static func _leg(v: Node3D, name: String, side: float, fwd: float, hip: Vector3, femur: float, tibia: float,
		up: float, down: float, mat_f: String, mat_t: String, thick: float, group: int, spines: bool = false) -> Node3D:
	var pivot := node3d(v, name, hip)
	pivot.rotation = Vector3(0, side * fwd, side * up)
	pivot.set_meta(&"side", side)
	pivot.set_meta(&"group", group)
	pivot.set_meta(&"base_yaw", side * fwd)
	pivot.set_meta(&"base_z", side * up)
	mesh(pivot, "Femur", box(Vector3(femur, thick, thick)), mat_f, Vector3(side * femur * 0.5, 0, 0))
	var knee := node3d(pivot, "Knee", Vector3(side * femur, 0, 0))
	knee.rotation = Vector3(0, 0, -side * (up + down))
	mesh(knee, "Joint", sphere(thick * 0.75), mat_t)
	mesh(knee, "Tibia", box(Vector3(tibia, thick * 0.8, thick * 0.8)), mat_t, Vector3(side * tibia * 0.5, 0, 0))
	mesh(knee, "Foot", box(Vector3(tibia * 0.3, thick * 0.6, thick * 0.6)), mat_t,
		Vector3(side * tibia * 1.08, -thick * 0.2, 0), Vector3(0, 0, side * 0.6))
	if spines:
		for k in 2:
			mesh(knee, "Spine", box(Vector3(0.015, 0.09, 0.015)), "roach_dark",
				Vector3(side * tibia * (0.35 + k * 0.3), thick * 0.5, 0), Vector3(0, 0, -side * 0.5))
	return pivot


## A two-segment antenna on a pivot (BugRig sways it).
static func _antenna(v: Node3D, name: String, side: float, pos: Vector3, seg: float, thick: float, material: String) -> Node3D:
	var a := node3d(v, name, pos)
	a.rotation = Vector3(0.3, side * 0.35, 0)
	a.set_meta(&"side", side)
	a.set_meta(&"base", a.rotation)
	mesh(a, "Base", box(Vector3(thick, thick, seg)), material, Vector3(0, 0, -seg * 0.5))
	var tip := node3d(a, "Tip", Vector3(0, 0, -seg))
	tip.rotation = Vector3(0.12, side * 0.15, 0)
	mesh(tip, "Whip", box(Vector3(thick * 0.8, thick * 0.8, seg * 1.15)), material, Vector3(0, 0, -seg * 0.57))
	return a


static func _merge_bug(v: Node3D) -> void:
	merge_meshes(v, ["Abdomen"])
	for n: Node in _pivots(v).slice(1):
		merge_meshes(n)


## `root` and every non-mesh node under it (collected before any merging).
static func _pivots(root: Node) -> Array:
	var out: Array = [root]
	for n in root.find_children("*", "Node3D", true, false):
		if not n is MeshInstance3D:
			out.append(n)
	return out


## A bug body: script, stats, collision; the caller fills "Visual".
static func _bug_root(script: String, node_name: String, stats_id: String) -> CharacterBody3D:
	var b := scripted(CharacterBody3D.new(), script, node_name) as CharacterBody3D
	b.set("stats", load("res://resources/bugs/%s.tres" % stats_id))
	shape(b, sphere_shape(0.35))
	return b


## The crumb-finding arrow the ground bugs' antennae sense shows.
static func _sense_arrow(b: Node) -> void:
	var arrow := node3d(b, "SenseArrow", Vector3(0, 1.4, 0))
	var am := mesh(arrow, "Arrow", PrismMesh.new(), "arrow", Vector3(0, 0, -0.6), Vector3(-PI * 0.5, 0, 0), Vector3(0.6, 0.8, 0.15))
	am.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _six_legs(v: Node3D, mat_f: String, mat_t: String, femur: float, tibia: float, up: float, down: float,
		thick: float, hip_x: float, hip_y: float, z0: float, dz: float, spines: bool = false) -> void:
	var fwd := [0.6, 0.0, -0.6]
	for i in 3:
		for x in [-1.0, 1.0]:
			_leg(v, "Leg%s%d" % ["L" if x < 0.0 else "R", i + 1], x, fwd[i], Vector3(x * hip_x, hip_y, z0 + i * dz),
				femur, tibia, up, down, mat_f, mat_t, thick, (i + (1 if x > 0.0 else 0)) % 2, spines)


## The five newer bugs: ant, cricket, ladybug, firefly, stink bug.
static func new_bugs(force: bool) -> void:
	# Ant: three-part body, pinched waist, elbowed antennae, mandibles.
	var a := _bug_root("res://scripts/bugs/ant.gd", "Ant", "ant")
	var av := node3d(a, "Visual")
	mesh(av, "Abdomen", sphere(0.3), "ant", Vector3(0, 0.02, 0.42), Vector3.ZERO, Vector3(0.85, 0.75, 1.2))
	mesh(av, "Waist", sphere(0.09), "ant", Vector3(0, -0.02, 0.1))
	mesh(av, "Thorax", sphere(0.17), "ant", Vector3(0, 0.0, -0.14), Vector3.ZERO, Vector3(0.8, 0.75, 1.5))
	mesh(av, "Head", sphere(0.19), "ant", Vector3(0, 0.03, -0.46), Vector3.ZERO, Vector3(1.0, 0.9, 1.0))
	for x in [-1.0, 1.0]:
		mesh(av, "Mandible", box(Vector3(0.04, 0.03, 0.15)), "ant", Vector3(x * 0.06, -0.05, -0.64), Vector3(0, x * 0.45, 0))
		mesh(av, "Eye", sphere(0.05), "spider_eye", Vector3(x * 0.14, 0.07, -0.52))
		_antenna(av, "AntennaL" if x < 0.0 else "AntennaR", x, Vector3(x * 0.07, 0.12, -0.58), 0.3, 0.025, "ant")
	_six_legs(av, "ant", "ant", 0.3, 0.36, 0.55, 1.15, 0.035, 0.08, -0.04, -0.24, 0.08)
	_merge_bug(av)
	add_skin(av, "bug_ant", Vector3(0.9, 0.5, 1.5), Vector3(0, 0.0, -0.05))
	_rig(a, "tripod")
	_sense_arrow(a)
	pack(a, "res://scenes/bugs/ant.tscn", force)

	# Cricket: long body, folded wings, huge jumping hind legs, long antennae.
	var c := _bug_root("res://scripts/bugs/cricket.gd", "Cricket", "cricket")
	var cv := node3d(c, "Visual")
	mesh(cv, "Abdomen", sphere(0.3), "cricket", Vector3(0, 0.05, 0.35), Vector3.ZERO, Vector3(0.85, 0.8, 1.6))
	mesh(cv, "Thorax", box(Vector3(0.5, 0.38, 0.5)), "cricket_dark", Vector3(0, 0.12, -0.25))
	mesh(cv, "Head", sphere(0.24), "cricket_dark", Vector3(0, 0.12, -0.6))
	for x in [-1.0, 1.0]:
		mesh(cv, "Eye", sphere(0.07), "spider_eye", Vector3(x * 0.17, 0.22, -0.66))
		mesh(cv, "Wing", box(Vector3(0.22, 0.04, 0.95)), "cricket_dark", Vector3(x * 0.11, 0.33, 0.25), Vector3(0, -x * 0.05, 0))
		mesh(cv, "Cercus", cyl(0.03, 0.4, 0.005), "cricket", Vector3(x * 0.09, 0.05, 0.95), Vector3(PI * 0.5, 0, -x * 0.3))
		_antenna(cv, "AntennaL" if x < 0.0 else "AntennaR", x, Vector3(x * 0.08, 0.2, -0.78), 0.75, 0.02, "cricket")
	for i in 2:
		for x in [-1.0, 1.0]:
			_leg(cv, "Leg%s%d" % ["L" if x < 0.0 else "R", i + 1], x, [0.55, 0.05][i], Vector3(x * 0.2, -0.05, -0.35 + i * 0.2),
				0.3, 0.38, 0.4, 1.1, "cricket", "cricket_dark", 0.05, (i + (1 if x > 0.0 else 0)) % 2)
	for x in [-1.0, 1.0]:
		# The big jumping legs, folded high along the body.
		_leg(cv, "Leg%s3" % ("L" if x < 0.0 else "R"), x, -0.95, Vector3(x * 0.22, 0.0, 0.1),
			0.62, 0.66, 1.0, 1.75, "cricket", "cricket_dark", 0.1, 0 if x < 0.0 else 1, true)
	_merge_bug(cv)
	add_skin(cv, "bug_cricket", Vector3(1.0, 0.8, 2.2), Vector3(0, 0.1, 0.0))
	_rig(c, "tripod")
	_sense_arrow(c)
	pack(c, "res://scenes/bugs/cricket.tscn", force)

	# Ladybug: red spotted dome (two wing cases that lift to flutter).
	var l := _bug_root("res://scripts/bugs/ladybug.gd", "Ladybug", "ladybug")
	var lv := node3d(l, "Visual")
	mesh(lv, "Underside", sphere(0.42), "ladybug_black", Vector3(0, -0.02, 0.05), Vector3.ZERO, Vector3(1.0, 0.45, 1.15))
	mesh(lv, "Pronotum", sphere(0.26), "ladybug_black", Vector3(0, 0.1, -0.38), Vector3.ZERO, Vector3(1.25, 0.6, 0.7))
	mesh(lv, "Head", sphere(0.15), "ladybug_black", Vector3(0, 0.02, -0.54))
	for x in [-1.0, 1.0]:
		mesh(lv, "Cheek", sphere(0.07), "plastic_white", Vector3(x * 0.22, 0.14, -0.44), Vector3.ZERO, Vector3(1.0, 0.6, 1.0))
		_antenna(lv, "AntennaL" if x < 0.0 else "AntennaR", x, Vector3(x * 0.06, 0.08, -0.64), 0.17, 0.02, "ladybug_black")
		var half := node3d(lv, "ShellL" if x < 0.0 else "ShellR", Vector3(x * 0.02, 0.12, 0.0))
		mesh(half, "Case", sphere(0.45), "ladybug_red", Vector3(x * 0.2, 0.0, 0.08), Vector3.ZERO, Vector3(0.52, 0.62, 1.08))
		for spot in [Vector3(0.2, 0.25, -0.12), Vector3(0.26, 0.2, 0.18), Vector3(0.12, 0.27, 0.36)]:
			mesh(half, "Spot", sphere(0.07), "ladybug_black", Vector3(x * spot.x, spot.y, spot.z), Vector3.ZERO, Vector3(1.0, 0.45, 1.0))
	_six_legs(lv, "ladybug_black", "ladybug_black", 0.2, 0.25, 0.2, 1.1, 0.04, 0.2, -0.08, -0.2, 0.2)
	_merge_bug(lv)
	add_skin(lv, "bug_ladybug", Vector3(1.0, 0.6, 1.2), Vector3(0, 0.0, 0.0))
	_rig(l, "tripod")
	_sense_arrow(l)
	pack(l, "res://scenes/bugs/ladybug.tscn", force)

	# Firefly: dark body, orange shield, glowing lantern tail, wings.
	var f := _bug_root("res://scripts/bugs/firefly.gd", "Firefly", "firefly")
	var fv := node3d(f, "Visual")
	mesh(fv, "Thorax", sphere(0.22), "firefly_body", Vector3(0, 0.05, -0.1), Vector3.ZERO, Vector3(1, 0.8, 1.3))
	mesh(fv, "Abdomen", sphere(0.24), "firefly_body", Vector3(0, 0.0, 0.4), Vector3.ZERO, Vector3(0.9, 0.75, 1.6))
	mesh(fv, "Lantern", sphere(0.2), "firefly_glow", Vector3(0, -0.03, 0.78), Vector3.ZERO, Vector3(0.85, 0.7, 1.0))
	mesh(fv, "Shield", sphere(0.22), "firefly_orange", Vector3(0, 0.15, -0.38), Vector3.ZERO, Vector3(1.25, 0.5, 0.9))
	mesh(fv, "Head", sphere(0.12), "firefly_body", Vector3(0, 0.05, -0.53))
	for x in [-1.0, 1.0]:
		mesh(fv, "Eye", sphere(0.06), "spider_eye", Vector3(x * 0.09, 0.07, -0.58))
		_antenna(fv, "AntennaL" if x < 0.0 else "AntennaR", x, Vector3(x * 0.05, 0.1, -0.62), 0.3, 0.02, "firefly_body")
		var wing := node3d(fv, "WingL" if x < 0.0 else "WingR", Vector3(x * 0.15, 0.24, 0.0))
		mesh(wing, "Wing", sphere(0.5), "wing", Vector3(x * 0.42, 0, 0.15), Vector3(0, x * 0.2, 0), Vector3(0.85, 0.04, 0.38))
		mesh(wing, "Case", sphere(0.3), "firefly_body", Vector3(x * 0.12, 0.02, 0.3), Vector3.ZERO, Vector3(0.45, 0.2, 1.4))
	_six_legs(fv, "firefly_body", "firefly_body", 0.25, 0.3, 0.2, 1.1, 0.04, 0.13, -0.18, -0.22, 0.16)
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color(0.8, 1.0, 0.35)
	glow.omni_range = 6.0
	glow.light_energy = 1.4
	glow.position = Vector3(0, -0.05, 0.85)
	fv.add_child(glow)
	_merge_bug(fv)
	add_skin(fv, "bug_firefly", Vector3(0.9, 0.6, 1.5), Vector3(0, 0.0, 0.1), ["WingL", "WingR", "Glow"])
	_rig(f, "tripod")
	pack(f, "res://scenes/bugs/firefly.tscn", force)

	# Stink bug: broad shield shape, mottled, banded edges and legs.
	var k := _bug_root("res://scripts/bugs/stink_bug.gd", "StinkBug", "stink_bug")
	var kv := node3d(k, "Visual")
	mesh(kv, "Rim", sphere(0.56), "stink_edge", Vector3(0, -0.02, 0.15), Vector3.ZERO, Vector3(1.08, 0.24, 1.08))
	mesh(kv, "Shield", sphere(0.55), "stink", Vector3(0, 0.04, 0.15), Vector3.ZERO, Vector3(1.0, 0.35, 1.0))
	mesh(kv, "Shoulders", sphere(0.3), "stink", Vector3(0, 0.1, -0.36), Vector3.ZERO, Vector3(1.65, 0.45, 0.8))
	mesh(kv, "Head", sphere(0.15), "stink", Vector3(0, 0.07, -0.6), Vector3.ZERO, Vector3(1.0, 0.7, 1.1))
	for spot in [Vector3(-0.18, 0.22, 0.0), Vector3(0.2, 0.21, 0.1), Vector3(0.0, 0.23, 0.3), Vector3(-0.25, 0.18, 0.35), Vector3(0.28, 0.17, -0.2)]:
		mesh(kv, "Mottle", sphere(0.07), "stink_edge", spot, Vector3.ZERO, Vector3(1.0, 0.35, 1.0))
	for x in [-1.0, 1.0]:
		mesh(kv, "Eye", sphere(0.04), "spider_eye", Vector3(x * 0.1, 0.1, -0.68))
		_antenna(kv, "AntennaL" if x < 0.0 else "AntennaR", x, Vector3(x * 0.06, 0.08, -0.72), 0.3, 0.025, "stink_edge")
	_six_legs(kv, "stink", "stink_edge", 0.28, 0.32, 0.3, 1.1, 0.05, 0.25, -0.06, -0.25, 0.22)
	_merge_bug(kv)
	add_skin(kv, "bug_stink_bug", Vector3(1.4, 0.5, 1.4), Vector3(0, 0.0, 0.1))
	_rig(k, "tripod")
	_sense_arrow(k)
	pack(k, "res://scenes/bugs/stink_bug.tscn", force)


static func _rig(bug: Node, gait: String) -> void:
	var rig := scripted(Node.new(), "res://scripts/bugs/bug_rig.gd", "Rig")
	rig.set("gait", gait)
	bug.add_child(rig)


static func bugs(force: bool) -> void:
	# Cockroach: pale-ringed head shield, glossy wing covers, segmented
	# abdomen, long two-part antennae, tail cerci, spiny jointed legs.
	var r := scripted(CharacterBody3D.new(), "res://scripts/bugs/cockroach.gd", "Cockroach")
	r.set("stats", load("res://resources/bugs/cockroach.tres"))
	shape(r, sphere_shape(0.35))
	var rv := node3d(r, "Visual")
	mesh(rv, "Abdomen", sphere(0.5), "roach", Vector3(0, -0.04, 0.15), Vector3.ZERO, Vector3(0.7, 0.36, 1.2))
	for i in 3:
		mesh(rv, "Segment", sphere(0.5), "roach_dark", Vector3(0, -0.1, 0.42 + i * 0.13), Vector3.ZERO,
			Vector3(0.62 - i * 0.12, 0.2, 0.18))
	for x in [-1.0, 1.0]:
		mesh(rv, "WingCover", sphere(0.5), "roach_wing", Vector3(x * 0.15, 0.1, 0.22), Vector3(0, -x * 0.06, 0),
			Vector3(0.42, 0.13, 1.28))
	mesh(rv, "Shield", sphere(0.32), "roach_light", Vector3(0, 0.06, -0.47), Vector3(-0.15, 0, 0), Vector3(1.15, 0.32, 0.85))
	for x in [-1.0, 1.0]:
		mesh(rv, "ShieldSpot", sphere(0.1), "roach_dark", Vector3(x * 0.1, 0.15, -0.47), Vector3.ZERO, Vector3(1.0, 0.3, 1.3))
	mesh(rv, "Head", sphere(0.19), "roach_dark", Vector3(0, -0.05, -0.68), Vector3.ZERO, Vector3(1, 0.8, 0.9))
	for x in [-1.0, 1.0]:
		mesh(rv, "Eye", sphere(0.075), "spider_eye", Vector3(x * 0.13, 0.0, -0.73), Vector3.ZERO, Vector3(0.7, 1.2, 0.7))
		mesh(rv, "Palp", box(Vector3(0.04, 0.04, 0.18)), "roach", Vector3(x * 0.06, -0.14, -0.8), Vector3(0.6, x * 0.2, 0))
		mesh(rv, "Cercus", cyl(0.035, 0.28, 0.005), "roach", Vector3(x * 0.1, -0.02, 0.92), Vector3(PI * 0.5, 0, -x * 0.35))
		_antenna(rv, "AntennaL" if x < 0.0 else "AntennaR", x, Vector3(x * 0.08, 0.02, -0.78), 0.55, 0.035, "roach")
	var roach_fwd := [0.65, 0.05, -0.6]
	for i in 3:
		for x in [-1.0, 1.0]:
			_leg(rv, "Leg%s%d" % ["L" if x < 0.0 else "R", i + 1], x, roach_fwd[i], Vector3(x * 0.17, -0.08, -0.25 + i * 0.25),
				0.36 + i * 0.04, 0.48 + i * 0.06, 0.35, 1.0, "roach", "roach_dark", 0.06, (i + (1 if x > 0.0 else 0)) % 2, true)
	_merge_bug(rv)
	add_skin(rv, "bug_cockroach", Vector3(1.1, 0.6, 2.2), Vector3(0, -0.05, -0.3))
	_rig(r, "tripod")
	var arrow := node3d(r, "SenseArrow", Vector3(0, 1.4, 0))
	var am := mesh(arrow, "Arrow", PrismMesh.new(), "arrow", Vector3(0, 0, -0.6), Vector3(-PI * 0.5, 0, 0), Vector3(0.6, 0.8, 0.15))
	am.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pack(r, "res://scenes/bugs/cockroach.tscn", force)

	# Fly: huge red compound eyes, striped bristly thorax, checkered abdomen,
	# proboscis, veined wings with halteres, jointed legs with sticky pads.
	var f := scripted(CharacterBody3D.new(), "res://scripts/bugs/fly.gd", "Fly")
	f.set("stats", load("res://resources/bugs/fly.tres"))
	shape(f, sphere_shape(0.35))
	var fv := node3d(f, "Visual")
	mesh(fv, "Thorax", sphere(0.33), "fly", Vector3(0, 0.05, -0.1), Vector3.ZERO, Vector3(1, 0.95, 1.1))
	for x in [-0.12, 0.0, 0.12]:
		mesh(fv, "Stripe", box(Vector3(0.05, 0.03, 0.5)), "fly_stripe", Vector3(x, 0.36, -0.1))
	for i in 6:
		var bx := (i % 3 - 1) * 0.15
		mesh(fv, "Bristle", box(Vector3(0.02, 0.14, 0.02)), "fly", Vector3(bx, 0.36, -0.25 + floorf(i / 3.0) * 0.3), Vector3(0.4, 0, bx))
	mesh(fv, "Abdomen", sphere(0.32), "fly_belly", Vector3(0, 0.0, 0.36), Vector3.ZERO, Vector3(0.95, 0.78, 1.15))
	for i in 3:
		for x in [-1.0, 1.0]:
			if (i + (1 if x > 0.0 else 0)) % 2 == 0:
				mesh(fv, "Checker", sphere(0.14), "fly", Vector3(x * 0.12, 0.2, 0.22 + i * 0.13), Vector3.ZERO, Vector3(1.0, 0.35, 0.8))
	mesh(fv, "Head", sphere(0.24), "fly", Vector3(0, 0.02, -0.46))
	for x in [-1.0, 1.0]:
		mesh(fv, "Eye", sphere(0.2), "fly_eye", Vector3(x * 0.16, 0.07, -0.5), Vector3.ZERO, Vector3(0.85, 1.1, 0.95))
		mesh(fv, "Feeler", box(Vector3(0.025, 0.025, 0.12)), "fly", Vector3(x * 0.05, 0.12, -0.68), Vector3(0.5, x * 0.3, 0))
	mesh(fv, "Proboscis", cyl(0.04, 0.24), "fly", Vector3(0, -0.2, -0.56), Vector3(0.35, 0, 0))
	mesh(fv, "Pad", sphere(0.07), "fly", Vector3(0, -0.32, -0.6), Vector3.ZERO, Vector3(1.4, 0.6, 1.0))
	for x in [-1.0, 1.0]:
		var wing := node3d(fv, "WingL" if x < 0.0 else "WingR", Vector3(x * 0.2, 0.3, 0.05))
		mesh(wing, "Wing", sphere(0.5), "wing", Vector3(x * 0.45, 0, 0.12), Vector3(0, x * 0.2, 0), Vector3(0.95, 0.04, 0.42))
		for k in 3:
			mesh(wing, "Vein", box(Vector3(0.8 - k * 0.15, 0.015, 0.012)), "wing_vein",
				Vector3(x * (0.42 - k * 0.04), 0.012, 0.0 + k * 0.1), Vector3(0, x * (0.2 + k * 0.08), 0))
		mesh(fv, "Haltere", sphere(0.04), "fly_stripe", Vector3(x * 0.16, 0.15, 0.22))
	var fly_fwd := [0.55, 0.0, -0.55]
	for i in 3:
		for x in [-1.0, 1.0]:
			_leg(fv, "Leg%s%d" % ["L" if x < 0.0 else "R", i + 1], x, fly_fwd[i], Vector3(x * 0.14, -0.2, -0.25 + i * 0.17),
				0.27, 0.32, 0.2, 1.1, "fly", "fly", 0.045, (i + (1 if x > 0.0 else 0)) % 2)
	_merge_bug(fv)
	add_skin(fv, "bug_fly", Vector3(0.9, 0.7, 1.3), Vector3(0, -0.05, -0.05), ["WingL", "WingR"])
	_rig(f, "tripod")
	pack(f, "res://scenes/bugs/fly.tscn", force)

	# Spider: eight eyes, fangs, pedipalps, chevron-marked abdomen with
	# spinnerets, tall-kneed banded legs.
	var s := scripted(CharacterBody3D.new(), "res://scripts/bugs/spider.gd", "Spider")
	s.set("stats", load("res://resources/bugs/spider.tres"))
	shape(s, sphere_shape(0.35))
	var sv := node3d(s, "Visual")
	mesh(sv, "Abdomen", sphere(0.42), "spider", Vector3(0, 0.1, 0.45), Vector3.ZERO, Vector3(1, 0.85, 1.15))
	mesh(sv, "Stripe", box(Vector3(0.06, 0.03, 0.5)), "spider_mark", Vector3(0, 0.45, 0.42), Vector3(-0.1, 0, 0))
	for i in 3:
		for x in [-1.0, 1.0]:
			mesh(sv, "Chevron", box(Vector3(0.22 - i * 0.04, 0.025, 0.05)), "spider_mark",
				Vector3(x * 0.09, 0.44 - i * 0.03, 0.38 + i * 0.13), Vector3(0, x * 0.6, 0))
	for x in [-1.0, 1.0]:
		mesh(sv, "Spinneret", cyl(0.05, 0.12, 0.02), "spider_band", Vector3(x * 0.04, 0.02, 0.93), Vector3(PI * 0.5, 0, 0))
	mesh(sv, "Thorax", sphere(0.28), "spider", Vector3(0, 0.02, -0.15), Vector3.ZERO, Vector3(1, 0.7, 1.1))
	mesh(sv, "ThoraxBand", box(Vector3(0.1, 0.03, 0.4)), "spider_band", Vector3(0, 0.21, -0.15))
	for x in [-1.0, 1.0]:
		mesh(sv, "EyeBig", sphere(0.065), "spider_eye", Vector3(x * 0.055, 0.13, -0.42))
		mesh(sv, "EyeSide", sphere(0.045), "spider_eye", Vector3(x * 0.13, 0.12, -0.38))
		mesh(sv, "EyeTop", sphere(0.035), "spider_eye", Vector3(x * 0.06, 0.19, -0.34))
		mesh(sv, "EyeBack", sphere(0.035), "spider_eye", Vector3(x * 0.14, 0.18, -0.3))
		mesh(sv, "Chelicera", sphere(0.07), "spider", Vector3(x * 0.06, -0.04, -0.44), Vector3.ZERO, Vector3(0.8, 1.3, 0.8))
		mesh(sv, "Fang", cyl(0.025, 0.1, 0.0), "fang", Vector3(x * 0.06, -0.14, -0.46))
		var palp := node3d(sv, "Palp" + ("L" if x < 0.0 else "R"), Vector3(x * 0.11, -0.02, -0.4))
		mesh(palp, "Seg", box(Vector3(0.04, 0.04, 0.2)), "spider", Vector3(0, 0.03, -0.09), Vector3(0.4, x * 0.2, 0))
		mesh(palp, "Club", sphere(0.04), "spider_band", Vector3(0, -0.02, -0.2))
	var spider_fwd := [0.95, 0.35, -0.3, -0.9]
	for i in 4:
		for x in [-1.0, 1.0]:
			_leg(sv, "Leg%s%d" % ["L" if x < 0.0 else "R", i + 1], x, spider_fwd[i], Vector3(x * 0.16, 0.0, -0.3 + i * 0.1),
				0.75, 0.95, 0.9, 1.3, "spider", "spider_band", 0.07, (i + (1 if x > 0.0 else 0)) % 2)
	_merge_bug(sv)
	add_skin(sv, "bug_spider", Vector3(2.3, 0.8, 2.3), Vector3(0, 0.0, 0.1))
	_rig(s, "alternate")
	var zl := mesh(s, "ZipLine", box(Vector3(0.06, 0.06, 1.0)), "web")
	zl.top_level = true
	zl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pack(s, "res://scenes/bugs/spider.tscn", force)

	new_bugs(force)

	var w := scripted(StaticBody3D.new(), "res://scripts/bugs/web_strand.gd", "WebStrand")
	shape(w, box_shape(Vector3(0.6, 0.15, 1.0)))
	var wm := mesh(w, "Mesh", box(Vector3(0.12, 0.06, 1.0)), "web")
	wm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pack(w, "res://scenes/bugs/web_strand.tscn", force)

	var t := scripted(Area3D.new(), "res://scripts/bugs/web_trap.gd", "WebTrap")
	var cs := CylinderShape3D.new()
	cs.radius = 3.0
	cs.height = 2.0
	shape(t, cs)
	var disc := cyl(3.0, 0.05)
	disc.radial_segments = 8
	mesh(t, "Web", disc, "web")
	for i in 4:
		mesh(t, "Strand", box(Vector3(6.0, 0.06, 0.06)), "web", Vector3(0, 0.04, 0), Vector3(0, PI * i / 4.0, 0))
	pack(t, "res://scenes/bugs/web_trap.tscn", force)


# --- Threats ----------------------------------------------------------------

static func foot(force: bool) -> void:
	var f := scripted(Node3D.new(), "res://scripts/hazards/foot_hazard.gd", "Foot")
	var body := AnimatableBody3D.new()
	body.name = "Body"
	f.add_child(body)
	shape(body, box_shape(Vector3(4.0, 2.5, 10.0)), Vector3(0, 1.25, 0))
	var v := node3d(f, "Visual")
	mesh(v, "Shoe", box(Vector3(4.2, 2.6, 10.4)), "shoe", Vector3(0, 1.3, -0.6))
	mesh(v, "Toe", sphere(2.1), "shoe", Vector3(0, 1.2, -5.2), Vector3.ZERO, Vector3(1, 0.6, 0.6))
	mesh(v, "Sole", box(Vector3(4.4, 0.5, 11.2)), "plastic_white", Vector3(0, 0.25, -0.9))
	mesh(v, "Laces", box(Vector3(2.0, 0.3, 4.0)), "plastic_white", Vector3(0, 2.65, -2.4))
	merge_meshes(v)
	add_skin(v, "human_sneaker", Vector3(4.6, 3.2, 11.6), Vector3(0, 1.6, -1.0))
	pack(f, "res://scenes/hazards/foot.tscn", force)


## A person: jointed arms with hands, a face, hair, and legs that bend at the
## knee to reach each foot (posed every frame by human.gd). Forward is -Z;
## the body's centre line is at z = 2 (above the heels).
## outfit: "casual" (t-shirt, watch), "reader" (cardigan, glasses),
## "hazmat" (exterminator suit, hood, goggles, respirator, tank).
static func human(force: bool, path: String, config: String, outfit: String, has_paper: bool) -> void:
	var h := scripted(CharacterBody3D.new(), "res://scripts/threats/human.gd", "Human")
	h.set("config", load(config))
	h.set("icon_height", 80.0)
	var cap := CapsuleShape3D.new()
	cap.radius = 6.0
	cap.height = 34.0
	shape(h, cap, Vector3(0, 55, 0))
	var top: String = {"casual": "shirt", "reader": "cloth_blue", "hazmat": "hazmat"}[outfit]
	var pants := "hazmat" if outfit == "hazmat" else "jeans"
	var hand := "shoe" if outfit == "hazmat" else "skin"
	var sleeve_long := outfit != "casual"

	var torso := node3d(h, "Torso")
	mesh(torso, "Pelvis", sphere(1.0), pants, Vector3(0, 38.5, 2), Vector3.ZERO, Vector3(7.2, 5.5, 4.6))
	mesh(torso, "Belt", cyl(6.9, 1.6), "belt" if outfit != "hazmat" else "dark_metal", Vector3(0, 42.5, 2), Vector3.ZERO, Vector3(1, 1, 0.68))
	mesh(torso, "Buckle", box(Vector3(2.0, 1.4, 0.4)), "metal", Vector3(0, 42.5, -2.75))
	mesh(torso, "Waist", cyl(6.2, 7.0, 7.0), top, Vector3(0, 46.6, 2), Vector3.ZERO, Vector3(1, 1, 0.66))
	mesh(torso, "Chest", sphere(1.0), top, Vector3(0, 54.5, 2), Vector3.ZERO, Vector3(8.0, 9.0, 5.0))
	# Shoulder line and upper back: a smooth slope from neck to shoulders.
	mesh(torso, "ShoulderLine", capsule(2.6, 19.5), top, Vector3(0, 59.6, 2.2), Vector3(0, 0, PI * 0.5), Vector3(1.0, 1.0, 0.95))
	mesh(torso, "UpperBack", sphere(1.0), top, Vector3(0, 57.5, 3.6), Vector3.ZERO, Vector3(7.4, 5.2, 3.0))
	for x in [-1.0, 1.0]:
		mesh(torso, "Trapezius", sphere(1.0), top, Vector3(x * 3.6, 61.4, 2.4), Vector3(0, 0, -x * 0.35), Vector3(3.4, 1.6, 2.4))
	mesh(torso, "Collar", cyl(2.7, 1.4), top, Vector3(0, 62.6, 2))
	mesh(torso, "Neck", cyl(2.0, 4.0), "skin" if outfit != "hazmat" else "hazmat", Vector3(0, 64.2, 2))
	if outfit == "reader":
		for x in [-1.0, 1.0]:
			mesh(torso, "Button", sphere(0.35), "belt", Vector3(0, 50 + x * 3.0, -2.95))
		mesh(torso, "Placket", box(Vector3(0.5, 16, 0.3)), "belt", Vector3(0, 53, -2.85))
	if outfit == "hazmat":
		mesh(torso, "Tank", cyl(2.6, 14.0), "metal", Vector3(0, 52, 7.6))
		mesh(torso, "TankCap", cyl(1.0, 1.6), "dark_metal", Vector3(0, 59.8, 7.6))
		mesh(torso, "Strap", box(Vector3(1.2, 16, 0.4)), "dark_metal", Vector3(-3.5, 54, -2.9))
		mesh(torso, "Strap", box(Vector3(1.2, 16, 0.4)), "dark_metal", Vector3(3.5, 54, -2.9))

	var head := node3d(torso, "Head", Vector3(0, 65.5, 2))
	mesh(head, "Skull", sphere(4.4), "skin", Vector3(0, 4.8, 0), Vector3.ZERO, Vector3(1, 1.18, 1.08))
	mesh(head, "Jaw", sphere(3.4), "skin", Vector3(0, 2.6, -0.8), Vector3.ZERO, Vector3(1, 0.72, 1))
	# Eyes that move (Gaze: irises and pupils) and blink (Lids, shown briefly).
	var gaze := node3d(head, "Gaze")
	var lids := node3d(head, "Lids")
	lids.visible = false
	for x in [-1.0, 1.0]:
		var side := "L" if x < 0.0 else "R"
		mesh(head, "Eye" + side, sphere(0.7), "eye_white", Vector3(x * 1.6, 5.3, -4.05))
		mesh(gaze, "Iris" + side, sphere(0.36), "iris", Vector3(x * 1.6, 5.3, -4.65), Vector3.ZERO, Vector3(1, 1, 0.6))
		mesh(gaze, "Pupil" + side, sphere(0.17), "pupil", Vector3(x * 1.6, 5.3, -4.86), Vector3.ZERO, Vector3(1, 1, 0.5))
		mesh(lids, "Lid" + side, sphere(0.86), "skin", Vector3(x * 1.6, 5.35, -4.3), Vector3.ZERO, Vector3(1.05, 0.95, 1.0))
		mesh(head, "Brow" + side, box(Vector3(1.9, 0.35, 0.45)), "hair", Vector3(x * 1.6, 6.55, -4.25), Vector3(0, 0, -x * 0.08))
		mesh(head, "Crease" + side, sphere(0.75), "skin", Vector3(x * 1.6, 5.95, -4.05), Vector3.ZERO, Vector3(1.05, 0.35, 0.9))
		mesh(head, "Ear" + side, sphere(0.9), "skin", Vector3(x * 4.35, 4.8, 0.4), Vector3.ZERO, Vector3(0.5, 1.3, 1))
		mesh(head, "EarLobe" + side, sphere(0.35), "skin", Vector3(x * 4.4, 3.75, 0.2))
		mesh(head, "Cheek" + side, sphere(1.15), "skin", Vector3(x * 2.25, 3.7, -3.35), Vector3.ZERO, Vector3(1.0, 0.8, 0.75))
		mesh(head, "Nostril" + side, sphere(0.28), "skin", Vector3(x * 0.42, 3.75, -4.95))
	mesh(head, "Nose", sphere(0.6), "skin", Vector3(0, 4.2, -4.85), Vector3.ZERO, Vector3(0.8, 1.25, 1.3))
	mesh(head, "NoseBridge", capsule(0.32, 1.6), "skin", Vector3(0, 4.9, -4.55), Vector3(0.25, 0, 0))
	mesh(head, "Chin", sphere(1.05), "skin", Vector3(0, 1.45, -3.2), Vector3.ZERO, Vector3(1.15, 0.8, 0.9))
	mesh(head, "UpperLip", capsule(0.24, 2.1), "lips", Vector3(0, 2.72, -4.12), Vector3(0, 0, PI * 0.5))
	mesh(head, "LowerLip", capsule(0.28, 1.9), "lips", Vector3(0, 2.36, -4.0), Vector3(0, 0, PI * 0.5))
	if outfit == "hazmat":
		mesh(head, "Hood", sphere(4.9), "hazmat", Vector3(0, 5.6, 0.6), Vector3.ZERO, Vector3(1.05, 1.15, 1.12))
		mesh(head, "Goggles", box(Vector3(6.4, 1.8, 1.2)), "goggles", Vector3(0, 5.4, -4.3))
		mesh(head, "Respirator", cyl(1.5, 1.8, 1.1), "dark_metal", Vector3(0, 2.6, -4.6), Vector3(PI * 0.5, 0, 0))
		for x in [-1.0, 1.0]:
			mesh(head, "Filter", cyl(0.9, 1.0), "dark_metal", Vector3(x * 2.0, 2.2, -4.2), Vector3(PI * 0.5, 0, x * 0.6))
	else:
		mesh(head, "Hair", sphere(4.6), "hair", Vector3(0, 7.2, 0.7), Vector3.ZERO, Vector3(1.04, 0.8, 1.1))
		mesh(head, "HairBack", sphere(4.3), "hair", Vector3(0, 5.0, 2.6), Vector3.ZERO, Vector3(1.0, 1.0, 0.62))
		mesh(head, "Fringe", sphere(2.2), "hair", Vector3(-0.9, 8.6, -3.2), Vector3(0.2, 0, 0.25), Vector3(1.5, 0.55, 0.7))
		for x in [-1.0, 1.0]:
			mesh(head, "Temple", sphere(1.4), "hair", Vector3(x * 3.95, 6.4, 0.2), Vector3.ZERO, Vector3(0.45, 1.1, 1.3))
	if outfit == "reader":
		for x in [-1.0, 1.0]:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.95
			ring.outer_radius = 1.25
			mesh(head, "Lens", ring, "dark_metal", Vector3(x * 1.65, 5.3, -4.75), Vector3(PI * 0.5, 0, 0))
		mesh(head, "Bridge", box(Vector3(0.9, 0.2, 0.2)), "dark_metal", Vector3(0, 5.5, -4.95))

	for x in [-1.0, 1.0]:
		var side := "L" if x < 0.0 else "R"
		var sh := node3d(torso, "Shoulder" + side, Vector3(x * 8.4, 59.5, 2))
		sh.rotation = Vector3(0, 0, -x * 0.07)
		mesh(sh, "Deltoid", sphere(2.3), top, Vector3(0, -0.6, 0), Vector3.ZERO, Vector3(1.0, 1.2, 1.0))
		if sleeve_long:
			mesh(sh, "UpperArm", capsule(1.95, 13.0), top, Vector3(0, -6.0, 0))
		else:
			mesh(sh, "Sleeve", capsule(2.1, 7.0), top, Vector3(0, -3.0, 0))
			mesh(sh, "UpperArm", capsule(1.6, 9.5), "skin", Vector3(0, -7.4, 0))
		var el := node3d(sh, "Elbow", Vector3(0, -12.0, 0))
		el.rotation = Vector3(0.15, 0, 0)
		mesh(el, "Forearm", capsule(1.55 if not sleeve_long else 1.75, 11.5), "skin" if not sleeve_long else top, Vector3(0, -5.2, 0))
		if outfit == "hazmat":
			mesh(el, "Cuff", cyl(1.9, 1.2), "dark_metal", Vector3(0, -10.4, 0))
		elif x < 0.0 and outfit == "casual":
			mesh(el, "Watch", cyl(1.75, 1.0), "dark_metal", Vector3(0, -9.6, 0))
		var hd := node3d(el, "Hand", Vector3(0, -11.3, 0))
		mesh(hd, "Palm", sphere(1.0), hand, Vector3(0, -1.0, 0), Vector3.ZERO, Vector3(1.5, 1.9, 0.85))
		mesh(hd, "Thumb", capsule(0.45, 2.4), hand, Vector3(-x * 1.2, -1.2, -0.9), Vector3(0.5, 0, x * 0.5))
		for i in 4:
			mesh(hd, "Finger", capsule(0.36, 2.5 if i in [1, 2] else 2.1), hand,
				Vector3(lerpf(-1.05, 1.05, i / 3.0), -3.5, 0), Vector3(0.12, 0, 0))

	for n: Node in _pivots(torso):
		merge_meshes(n)
	if has_paper:
		# Held up while reading (human.gd shows it); kept separate from merges.
		var reading := mesh(torso, "ReadingPaper", box(Vector3(18, 13, 0.3)), "paper", Vector3(0, 64, -13.5), Vector3(-0.15, 0, 0))
		reading.visible = false

	# Legs: posed every frame from the hip sockets to the feet (two-bone IK).
	var legs := node3d(h, "Legs")
	legs.top_level = true
	for side in ["L", "R"]:
		mesh(legs, "Thigh" + side, capsule(2.75, 19.5), pants)
		mesh(legs, "Knee" + side, sphere(2.45), pants)
		mesh(legs, "Shin" + side, capsule(2.3, 19.0), pants)

	var foot_scene: PackedScene = load("res://scenes/hazards/foot.tscn")
	var lf := foot_scene.instantiate()
	lf.name = "LeftFoot"
	lf.position = Vector3(-1.7, 0, 0)
	h.add_child(lf)
	var rf := foot_scene.instantiate()
	rf.name = "RightFoot"
	rf.position = Vector3(1.7, 0, 0)
	h.add_child(rf)
	if has_paper:
		var np := scripted(Node3D.new(), "res://scripts/hazards/newspaper.gd", "Newspaper")
		var paper := node3d(np, "Paper")
		mesh(paper, "Roll", cyl(1.2, 16.0), "paper", Vector3(0, 0, -8.0), Vector3(PI * 0.5, 0, 0))
		add_skin(paper, "rolled_newspaper", Vector3(2.6, 2.6, 16.0), Vector3(0, 0, -8.0), [], 90.0)
		h.add_child(np)
		h.set("has_newspaper", true)
	pack(h, path, force)


## A cat or dog with a head that turns, ears that perk or flatten, a
## two-part tail, four jointed legs and a face. pet.gd animates the pivots
## (walk cycle, tail wag/swish, ears, head tracking, play bow, sleeping curl).
## size: 1.0 cat, 1.4 dog, 0.8 puppy.
static func pet(force: bool, path: String, config: String, color: String, size: float, is_dog: bool,
		node_name: String = "") -> void:
	var p := scripted(CharacterBody3D.new(), "res://scripts/threats/pet.gd", node_name if node_name != "" else ("Dog" if is_dog else "Cat"))
	p.set("config", load(config))
	p.set("barks", is_dog)
	p.set("uses_perches", not is_dog)
	p.set("pounce_height", 4.0 * size if is_dog else 8.0)
	var k := size
	p.set("icon_height", 11.0 * k)
	var cap := CapsuleShape3D.new()
	cap.radius = 2.4 * k
	cap.height = 10.0 * k
	# Bottom of the capsule at the origin so the pet's origin matches the navmesh.
	shape(p, cap, Vector3(0, 2.4 * k, 0), Vector3(PI * 0.5, 0, 0))
	var v := node3d(p, "Visual")
	# Dogs: a beagle-style tri-colour coat (tan body, white chest, muzzle, legs
	# and tail tip, a black saddle). Cats: an orange tabby.
	var dark := "fur_dark" if is_dog else "cat_stripe"
	var white := "dog_white"
	var black := "dog_black"
	mesh(v, "Body", capsule(2.35 * k, 11.5 * k), color, Vector3(0, 5.0 * k, 0.8 * k), Vector3(PI * 0.5, 0, 0))
	mesh(v, "Chest", sphere(2.6 * k), white if is_dog else color, Vector3(0, 5.3 * k, -3.4 * k), Vector3.ZERO, Vector3(1, 1.05, 1.1))
	if is_dog:
		mesh(v, "Saddle", sphere(2.4 * k), black, Vector3(0, 6.75 * k, 1.4 * k), Vector3.ZERO, Vector3(1.02, 0.5, 1.65))
		var collar := TorusMesh.new()
		collar.inner_radius = 1.55 * k
		collar.outer_radius = 2.0 * k
		mesh(v, "Collar", collar, "cloth_red", Vector3(0, 6.3 * k, -4.9 * k), Vector3(PI * 0.5 - 0.5, 0, 0))
		mesh(v, "Tag", cyl(0.45 * k, 0.15 * k), "golden", Vector3(0, 4.75 * k, -5.95 * k), Vector3(PI * 0.5, 0, 0))
	else:
		# Tabby bands that wrap the body.
		for i in 4:
			mesh(v, "Stripe", cyl(2.4 * k, 0.55 * k), dark, Vector3(0, 5.0 * k, -2.2 * k + i * 2.0 * k), Vector3(PI * 0.5, 0, 0), Vector3(1.0, 1.0, 1.0))
	# Neck, shoulders and haunches: one smooth animal, not a tube.
	mesh(v, "Neck", capsule(1.4 * k, 4.2 * k), color, Vector3(0, 6.4 * k, -4.9 * k), Vector3(-0.85, 0, 0))
	for x in [-1.0, 1.0]:
		mesh(v, "Shoulder", sphere(1.55 * k), color, Vector3(x * 1.15 * k, 5.4 * k, -3.3 * k), Vector3.ZERO, Vector3(0.8, 1.15, 1.1))
		mesh(v, "Haunch", sphere(1.9 * k), color, Vector3(x * 1.05 * k, 5.6 * k, 3.7 * k), Vector3.ZERO, Vector3(0.85, 1.15, 1.2))

	var head := node3d(v, "Head", Vector3(0, 7.0 * k, -6.2 * k))
	if is_dog:
		mesh(head, "Skull", sphere(2.2 * k), color, Vector3(0, 0.35 * k, -0.4 * k), Vector3.ZERO, Vector3(1.0, 0.95, 1.05))
		for x in [-1.0, 1.0]:
			mesh(head, "Brow", sphere(0.55 * k), color, Vector3(x * 0.9 * k, 1.35 * k, -1.85 * k), Vector3.ZERO, Vector3(1.2, 0.6, 0.8))
		mesh(head, "Snout", capsule(0.95 * k, 3.6 * k), color, Vector3(0, -0.45 * k, -2.7 * k), Vector3(PI * 0.5, 0, 0), Vector3(1.0, 1.0, 0.82))
		mesh(head, "Muzzle", sphere(1.1 * k), white, Vector3(0, -0.75 * k, -3.6 * k), Vector3.ZERO, Vector3(1.0, 0.75, 1.15))
		mesh(head, "Blaze", box(Vector3(0.55, 0.2, 3.2) * k), white, Vector3(0, 0.3 * k, -2.4 * k), Vector3(-0.25, 0, 0))
		for x in [-1.0, 1.0]:
			mesh(head, "Jowl", sphere(0.62 * k), white, Vector3(x * 0.7 * k, -1.15 * k, -3.25 * k), Vector3.ZERO, Vector3(0.9, 1.1, 1.3))
		mesh(head, "Nose", sphere(0.5 * k), black, Vector3(0, -0.15 * k, -4.4 * k), Vector3.ZERO, Vector3(1.25, 0.85, 0.8))
		var tongue := mesh(head, "Tongue", box(Vector3(0.9, 0.15, 1.6) * k), "lips", Vector3(0, -1.55 * k, -3.8 * k), Vector3(0.5, 0, 0))
		tongue.visible = false
	else:
		mesh(head, "Skull", sphere(2.2 * k), color, Vector3(0, 0.2 * k, -0.6 * k))
		mesh(head, "Muzzle", sphere(1.15 * k), white, Vector3(0, -0.55 * k, -2.25 * k), Vector3.ZERO, Vector3(1.25, 0.8, 0.9))
		mesh(head, "Nose", sphere(0.32 * k), "lips", Vector3(0, -0.15 * k, -3.1 * k))
		for x in [-1.0, 1.0]:
			for i in 3:
				mesh(head, "Whisker", box(Vector3(2.6, 0.05, 0.05) * k), white,
					Vector3(x * 1.7 * k, -0.6 * k + (i - 1) * 0.25 * k, -2.5 * k), Vector3(0, x * 0.15, x * (i - 1) * 0.15))
	var lids := node3d(head, "Lids")
	lids.visible = false
	for x in [-1.0, 1.0]:
		var side := "L" if x < 0.0 else "R"
		mesh(head, "Eye" + side, sphere(0.46 * k), "pet_eye_dog" if is_dog else "pet_eye_cat", Vector3(x * 0.95 * k, 0.75 * k, -2.05 * k))
		mesh(lids, "Lid" + side, sphere(0.56 * k), color, Vector3(x * 0.95 * k, 0.78 * k, -2.18 * k))
		var pupil: Mesh = box(Vector3(0.12, 0.6, 0.1) * k)
		if is_dog:
			pupil = sphere(0.22 * k)
		mesh(head, "Pupil" + side, pupil, black if is_dog else "spider", Vector3(x * 0.95 * k, 0.78 * k, -2.48 * k))
		var ear := node3d(head, "Ear" + side, Vector3(x * (1.3 if not is_dog else 2.05) * k, (1.9 if not is_dog else 1.2) * k, -0.2 * k))
		ear.set_meta(&"side", x)
		if is_dog:
			# Long, soft, floppy ears.
			mesh(ear, "Flap", capsule(0.95 * k, 4.4 * k), dark, Vector3(x * 0.3 * k, -1.9 * k, 0.1 * k), Vector3(0, 0, 0), Vector3(0.45, 1.0, 1.0))
		else:
			mesh(ear, "Point", PrismMesh.new(), color, Vector3(0, 0.8 * k, 0), Vector3.ZERO, Vector3(1.5, 1.9, 0.6) * k)
			mesh(ear, "Inner", PrismMesh.new(), "lips", Vector3(0, 0.72 * k, -0.2 * k), Vector3.ZERO, Vector3(0.95, 1.3, 0.3) * k)

	var tail := node3d(v, "Tail", Vector3(0, 6.6 * k, 6.2 * k))
	var tail_len := 4.2 if is_dog else 5.0
	tail.rotation = Vector3(-0.7 if is_dog else -0.5, 0, 0)
	mesh(tail, "Base", cyl(0.6 * k, tail_len * k, 0.45 * k), color, Vector3(0, 0, tail_len * 0.5 * k), Vector3(PI * 0.5, 0, 0))
	var tip := node3d(tail, "Tip", Vector3(0, 0, tail_len * k))
	mesh(tip, "Fluff", cyl(0.45 * k, tail_len * 0.8 * k, 0.2 * k), white if is_dog else dark,
		Vector3(0, 0, tail_len * 0.4 * k), Vector3(PI * 0.5, 0, 0))

	for leg_name in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var x := -1.0 if leg_name.ends_with("L") else 1.0
		var z := -3.6 if leg_name.contains("F") else 3.6
		var leg := node3d(v, leg_name, Vector3(x * 1.45 * k, 4.3 * k, z * k))
		leg.set_meta(&"front", z < 0.0)
		mesh(leg, "Upper", capsule(0.78 * k, 3.4 * k), color, Vector3(0, -1.2 * k, 0), Vector3.ZERO, Vector3(1.0, 1.0, 1.1))
		var knee := node3d(leg, "Knee", Vector3(0, -2.5 * k, 0))
		var lower := white if is_dog else color
		mesh(knee, "Joint", sphere(0.62 * k), lower)
		mesh(knee, "Lower", capsule(0.55 * k, 2.4 * k), lower, Vector3(0, -0.95 * k, 0))
		mesh(knee, "Paw", sphere(0.75 * k), lower, Vector3(0, -1.75 * k, -0.25 * k), Vector3.ZERO, Vector3(1, 0.6, 1.3))
		for t in 3:
			mesh(knee, "Toe", sphere(0.28 * k), lower, Vector3((t - 1) * 0.36 * k, -1.85 * k, -0.95 * k), Vector3.ZERO, Vector3(1, 0.8, 1.1))
	for n: Node in _pivots(v):
		merge_meshes(n)
	add_skin(v, "pet_dog" if is_dog else "pet_cat", Vector3(5.5, 10.0, 18.0) * k, Vector3(0, 5.0 * k, 0.5))
	var agent := NavigationAgent3D.new()
	agent.name = "Agent"
	agent.path_desired_distance = 2.0
	agent.target_desired_distance = 2.0
	agent.radius = 2.0 * k
	agent.height = 6.0 * k
	agent.path_max_distance = 6.0
	p.add_child(agent)
	pack(p, path, force)


static func vacuum(force: bool) -> void:
	var v := scripted(CharacterBody3D.new(), "res://scripts/threats/robot_vacuum.gd", "RobotVacuum")
	v.set("config", load("res://resources/threats/vacuum.tres"))
	v.set("icon_height", 5.0)
	var cs := CylinderShape3D.new()
	cs.radius = 4.0
	cs.height = 2.4
	shape(v, cs, Vector3(0, 1.3, 0))
	var vis := node3d(v, "Visual")
	mesh(vis, "Shell", cyl(4.0, 2.2), "vacuum", Vector3(0, 1.2, 0))
	mesh(vis, "Bumper", cyl(4.1, 0.8), "golden", Vector3(0, 0.8, 0))
	mesh(vis, "Sensor", cyl(0.8, 0.6), "screen_glow", Vector3(0, 2.5, -1.5))
	var brush := cyl(1.2, 0.2)
	mesh(vis, "Brush", brush, "metal", Vector3(-2.8, 0.15, -2.8))
	add_skin(vis, "robot_vacuum", Vector3(8.4, 2.8, 8.4), Vector3(0, 1.4, 0))
	pack(v, "res://scenes/threats/robot_vacuum.tscn", force)


static func threats(force: bool) -> void:
	foot(force)
	human(force, "res://scenes/threats/human.tscn", "res://resources/threats/human.tres", "casual", false)
	human(force, "res://scenes/threats/human_reader.tscn", "res://resources/threats/human.tres", "reader", true)
	human(force, "res://scenes/threats/exterminator.tscn", "res://resources/threats/exterminator.tres", "hazmat", false)
	pet(force, "res://scenes/threats/cat.tscn", "res://resources/threats/cat.tres", "cat_orange", 1.0, false)
	pet(force, "res://scenes/threats/dog.tscn", "res://resources/threats/dog.tres", "dog_brown", 1.4, true)
	pet(force, "res://scenes/threats/puppy.tscn", "res://resources/threats/puppy.tres", "fridge_white", 0.8, true, "Puppy")
	vacuum(force)


# --- Hazards, FX, pickups, props --------------------------------------------

static func hazards(force: bool) -> void:
	var s := scripted(Node3D.new(), "res://scripts/hazards/swatter.gd", "Swatter")
	s.set("impact_radius", 3.2)
	var paddle := node3d(s, "Paddle")
	mesh(paddle, "Head", box(Vector3(7.0, 0.35, 7.5)), "swatter", Vector3(0, 0.2, 0))
	for i in 4:
		mesh(paddle, "Slot", box(Vector3(5.6, 0.4, 0.25)), "dark_metal", Vector3(0, 0.22, -2.4 + i * 1.6))
	mesh(paddle, "Handle", box(Vector3(0.7, 0.5, 22.0)), "swatter", Vector3(0, 3.5, 14.5), Vector3(0.32, 0, 0))
	add_skin(paddle, "fly_swatter", Vector3(7.5, 8.0, 29.0), Vector3(0, 4.0, 10.75))
	pack(s, "res://scenes/hazards/swatter.tscn", force)

	var c := scripted(Node3D.new(), "res://scripts/hazards/spray_cloud.gd", "SprayCloud")
	var m := mesh(c, "Mesh", sphere(1.0), "spray")
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pack(c, "res://scenes/hazards/spray_cloud.tscn", force)

	var fog := scripted(Node3D.new(), "res://scripts/hazards/fog_front.gd", "FogFront")
	var fm := mesh(fog, "Mesh", box(Vector3(200, 40, 60)), "fog", Vector3(0, 20, 30))
	fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pack(fog, "res://scenes/hazards/fog_front.tscn", force)

	var rp := scripted(Node3D.new(), "res://scripts/fx/ripple.gd", "Ripple")
	pack(rp, "res://scenes/fx/ripple.tscn", force)

	var cam := scripted(Node3D.new(), "res://scripts/camera/follow_camera.gd", "FollowCamera")
	var arm := SpringArm3D.new()
	arm.name = "Arm"
	cam.add_child(arm)
	var c3 := Camera3D.new()
	c3.name = "Camera"
	arm.add_child(c3)
	pack(cam, "res://scenes/camera/follow_camera.tscn", force)


static func pickups(force: bool) -> void:
	for golden in [false, true]:
		var c := scripted(Area3D.new(), "res://scripts/world/crumb.gd", "GoldenCrumb" if golden else "Crumb")
		c.set("golden", golden)
		shape(c, sphere_shape(1.2))
		var v := node3d(c, "Visual", Vector3(0, 0.15, 0))
		var mname := "golden" if golden else "crumb"
		mesh(v, "A", box(Vector3(0.9, 0.6, 0.7)), mname, Vector3.ZERO, Vector3(0.3, 0.5, 0.2))
		mesh(v, "B", box(Vector3(0.6, 0.5, 0.8)), mname, Vector3(0.25, 0.15, 0.1), Vector3(-0.4, 1.1, 0.3))
		mesh(v, "C", box(Vector3(0.4, 0.4, 0.4)), mname, Vector3(-0.35, 0.05, -0.2), Vector3(0.7, 0.2, 0.9))
		merge_meshes(v)
		add_skin(v, "golden_crumb" if golden else "crumb", Vector3(1.3, 0.9, 1.3), Vector3(0, 0.05, 0))
		if golden:
			var glow := OmniLight3D.new()
			glow.name = "Glow"
			glow.light_color = Color(1, 0.8, 0.3)
			glow.omni_range = 6.0
			glow.light_energy = 1.5
			v.add_child(glow)
		_cull_far(c, 90.0)
		pack(c, "res://scenes/world/%s.tscn" % ("golden_crumb" if golden else "crumb"), force)

	var g := scripted(Area3D.new(), "res://scripts/world/goal.gd", "Goal")
	shape(g, box_shape(Vector3(5, 5, 5)), Vector3(0, 2.5, 0))
	var beacon := node3d(g, "Beacon")
	var beam := mesh(beacon, "Beam", cyl(1.6, 40.0, 0.4), "beacon", Vector3(0, 20, 0))
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring := TorusMesh.new()
	ring.inner_radius = 2.4
	ring.outer_radius = 3.0
	mesh(beacon, "Ring", ring, "arrow", Vector3(0, 0.3, 0))
	pack(g, "res://scenes/world/goal.tscn", force)


## Bug food and crumb gems: one scene per item, all using PickupItem.
static func items(force: bool) -> void:
	var foods := ["sugar_cube", "cheese", "mint_leaf", "honey_drop", "coffee_bean", "kibble"]
	var gems := ["gem_amethyst", "gem_amber", "gem_emerald", "gem_ruby", "gem_diamond", "gem_sapphire"]
	for id: String in foods + gems:
		var gem := id.begins_with("gem_")
		var it := scripted(Area3D.new(), "res://scripts/world/pickup_item.gd", id.to_pascal_case())
		it.set("def", load("res://resources/items/%s.tres" % id))
		var h := 1.7 if gem else 0.65
		shape(it, sphere_shape(1.5 if gem else 1.3), Vector3(0, h, 0))
		var v := node3d(it, "Visual", Vector3(0, h, 0))
		var fit := _item_visual(v, id)
		merge_meshes(v)
		var keep := ["Glow", "Sparkles"]
		add_skin(v, id, fit, Vector3.ZERO, keep, 180.0)
		if gem:
			var glow := OmniLight3D.new()
			glow.name = "Glow"
			glow.light_color = (load("res://resources/items/%s.tres" % id) as ItemDef).color
			glow.omni_range = 5.0
			glow.light_energy = 1.2
			v.add_child(glow)
			var sp := node3d(v, "Sparkles")
			for i in 4:
				var a := TAU * i / 4.0
				var m := mesh(sp, "Sparkle", box(Vector3(0.12, 0.12, 0.12)), "sparkle",
					Vector3(cos(a) * 1.1, 0.35 * sin(a * 2.0), sin(a) * 1.1), Vector3(0.6, a, 0.6))
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			merge_meshes(sp)
			var halo := mesh(it, "Halo", cyl(1.2, 0.04), "light_tint", Vector3(0, 0.05, 0))
			halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_cull_far(it, 110.0)
		pack(it, "res://scenes/items/%s.tscn" % id, force)


## Builds an item's placeholder look; returns the box a generated model fits in.
static func _item_visual(v: Node3D, id: String) -> Vector3:
	match id:
		"sugar_cube":
			mesh(v, "Cube", box(Vector3(1.1, 1.1, 1.1)), "sugar", Vector3.ZERO, Vector3(0.1, 0.4, 0.05))
			for p in [Vector3(0.8, -0.45, 0.3), Vector3(-0.7, -0.5, -0.4), Vector3(0.2, -0.5, -0.85)]:
				mesh(v, "Grain", box(Vector3(0.22, 0.22, 0.22)), "sugar", p, Vector3(0.5, p.x, 0.3))
			return Vector3(1.8, 1.3, 1.8)
		"cheese":
			var w := PrismMesh.new()
			w.size = Vector3(1.6, 1.0, 1.2)
			w.left_to_right = 0.0
			mesh(v, "Wedge", w, "cheese", Vector3(0, -0.1, 0))
			for p in [Vector3(-0.2, -0.05, 0.61), Vector3(0.25, -0.35, 0.61), Vector3(-0.45, -0.4, -0.61), Vector3(0.1, -0.2, -0.61)]:
				mesh(v, "Hole", sphere(0.13), "cheese_hole", p, Vector3.ZERO, Vector3(1, 1, 0.4))
			return Vector3(1.7, 1.1, 1.3)
		"mint_leaf":
			mesh(v, "Leaf", sphere(0.75), "mint", Vector3(0, -0.4, 0), Vector3(0, 0.3, 0), Vector3(0.8, 0.12, 1.5))
			mesh(v, "Rib", box(Vector3(0.06, 0.06, 1.9)), "leaf_green", Vector3(0, -0.3, 0), Vector3(0, 0.3, 0))
			mesh(v, "Stem", cyl(0.05, 0.6), "leaf_green", Vector3(0.38, -0.35, 0.95), Vector3(PI * 0.5, 0.3, 0))
			return Vector3(1.4, 0.4, 2.4)
		"honey_drop":
			mesh(v, "Drop", sphere(0.55), "honey", Vector3(0, -0.1, 0))
			mesh(v, "Tip", cyl(0.53, 0.75, 0.02), "honey", Vector3(0, 0.45, 0))
			mesh(v, "Puddle", cyl(0.75, 0.08), "honey", Vector3(0, -0.6, 0))
			return Vector3(1.5, 1.4, 1.5)
		"coffee_bean":
			mesh(v, "Bean", sphere(0.55), "coffee", Vector3(0, -0.2, 0), Vector3.ZERO, Vector3(0.85, 0.6, 1.2))
			mesh(v, "Crease", box(Vector3(0.07, 0.06, 1.15)), "roach_dark", Vector3(0, 0.12, 0), Vector3(0, 0, 0))
			return Vector3(1.0, 0.8, 1.4)
		"kibble":
			for p in [Vector3(-0.35, -0.4, 0.1), Vector3(0.4, -0.4, -0.15), Vector3(0.05, -0.05, 0.05)]:
				var k := cyl(0.42, 0.32)
				k.radial_segments = 6
				mesh(v, "Kibble", k, "kibble", p, Vector3(0.2 * p.x, p.z * 3.0, 0.15))
			return Vector3(1.7, 0.9, 1.3)
		"gem_amethyst":
			var col := cyl(0.42, 1.1)
			col.radial_segments = 6
			mesh(v, "Crystal", col, id, Vector3(0, -0.15, 0))
			var tip := cyl(0.42, 0.55, 0.0)
			tip.radial_segments = 6
			mesh(v, "Tip", tip, id, Vector3(0, 0.67, 0))
			var small := cyl(0.22, 0.7)
			small.radial_segments = 6
			mesh(v, "Shard", small, id, Vector3(0.45, -0.35, 0.1), Vector3(0, 0, -0.5))
			return Vector3(1.2, 1.9, 1.0)
		"gem_amber":
			mesh(v, "Amber", sphere(0.7), id, Vector3.ZERO, Vector3.ZERO, Vector3(0.85, 1.0, 0.7))
			# A tiny ancient bug trapped inside.
			mesh(v, "Fossil", sphere(0.16), "roach_dark", Vector3(0, -0.05, 0), Vector3.ZERO, Vector3(0.7, 0.5, 1.4))
			return Vector3(1.2, 1.4, 1.0)
		"gem_emerald":
			mesh(v, "Table", box(Vector3(0.8, 1.2, 0.45)), id)
			mesh(v, "Bevel", box(Vector3(0.6, 1.0, 0.6)), id, Vector3.ZERO, Vector3(0, PI * 0.25, 0))
			return Vector3(1.0, 1.3, 1.0)
		"gem_ruby", "gem_diamond":
			var segs := 8 if id == "gem_diamond" else 6
			var crown := cyl(0.75, 0.32, 0.5)
			crown.radial_segments = segs
			mesh(v, "Crown", crown, id, Vector3(0, 0.25, 0))
			var pav := cyl(0.0, 0.85, 0.75)
			pav.radial_segments = segs
			mesh(v, "Pavilion", pav, id, Vector3(0, -0.33, 0))
			return Vector3(1.6, 1.3, 1.6)
		"gem_sapphire":
			var ov := sphere(0.6)
			ov.radial_segments = 8
			ov.rings = 4
			mesh(v, "Oval", ov, id, Vector3.ZERO, Vector3.ZERO, Vector3(0.8, 1.15, 0.55))
			return Vector3(1.1, 1.5, 0.8)
	return Vector3.ONE


static func _prop(force: bool, name: String, m: Mesh, s: Shape3D, material: String, mass: float,
		trip: bool, noise: float, sound: String, offset: Vector3 = Vector3.ZERO) -> void:
	var p := scripted(RigidBody3D.new(), "res://scripts/stealth/physics_prop.gd", name.capitalize().replace(" ", ""))
	p.set("mass", mass)
	p.set("trip_hazard", trip)
	p.set("noise_on_impact", noise)
	p.set("impact_sound", StringName(sound))
	shape(p, s, offset)
	var v := node3d(p, "Visual")
	mesh(v, "Mesh", m, material, offset)
	add_skin(v, "prop_" + name, m.get_aabb().size, offset + m.get_aabb().get_center())
	_cull_far(p, 100.0)
	pack(p, "res://scenes/props/%s.tscn" % name, force)


static func props(force: bool) -> void:
	_prop(force, "grape", sphere(0.9), sphere_shape(0.9), "grape", 0.5, true, 0.8, "squish")
	_prop(force, "pea", sphere(0.5), sphere_shape(0.5), "pea", 0.1, false, 1.4, "clatter")
	var cap_shape := CylinderShape3D.new()
	cap_shape.radius = 1.0
	cap_shape.height = 0.4
	_prop(force, "bottle_cap", cyl(1.0, 0.4), cap_shape, "metal", 0.2, false, 2.2, "clatter")
	var mug_shape := CylinderShape3D.new()
	mug_shape.radius = 2.0
	mug_shape.height = 4.0
	_prop(force, "mug", cyl(2.0, 4.0), mug_shape, "plastic_white", 3.0, false, 2.5, "clang")
	_prop(force, "cereal_box", box(Vector3(5, 9, 2)), box_shape(Vector3(5, 9, 2)), "chip_bag", 1.2, false, 1.6, "thud")
	_prop(force, "ball", sphere(1.6), sphere_shape(1.6), "ball", 0.6, true, 1.0, "thud")
	_prop(force, "acorn", sphere(0.7, 1.0), sphere_shape(0.6), "dark_wood", 0.2, false, 1.2, "clatter")
