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
	mi.name = name
	mi.mesh = m
	mi.material_override = mat(material)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func sphere(r: float, h: float = -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if h < 0.0 else h
	s.radial_segments = 16
	s.rings = 8
	return s


static func cyl(r: float, h: float, r2: float = -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r if r2 < 0.0 else r2
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 16
	c.rings = 1
	return c


static func capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 4
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


static func scripted(type_node: Node, script_path: String, name: String) -> Node:
	type_node.name = name
	type_node.set_script(load(script_path))
	return type_node


# --- Bugs ---------------------------------------------------------------------

static func _legs(v: Node3D, count_per_side: int, length: float, material: String, y: float, spread: float) -> void:
	for side in [-1.0, 1.0]:
		for i in count_per_side:
			var z := lerpf(-spread, spread, float(i) / maxf(count_per_side - 1, 1))
			mesh(v, "Leg", box(Vector3(length, 0.06, 0.06)), material,
				Vector3(side * length * 0.45, y, z), Vector3(0, -side * (z / spread) * 0.5, side * -0.35))


static func bugs(force: bool) -> void:
	# Cockroach
	var r := scripted(CharacterBody3D.new(), "res://scripts/bugs/cockroach.gd", "Cockroach")
	r.set("stats", load("res://resources/bugs/cockroach.tres"))
	shape(r, sphere_shape(0.35))
	var rv := node3d(r, "Visual")
	mesh(rv, "Body", sphere(0.5), "roach", Vector3(0, 0, 0.1), Vector3.ZERO, Vector3(0.75, 0.42, 1.25))
	mesh(rv, "Head", sphere(0.22), "roach", Vector3(0, 0.02, -0.62))
	mesh(rv, "AntennaL", box(Vector3(0.03, 0.03, 0.9)), "roach", Vector3(-0.15, 0.12, -1.05), Vector3(0.25, 0.3, 0))
	mesh(rv, "AntennaR", box(Vector3(0.03, 0.03, 0.9)), "roach", Vector3(0.15, 0.12, -1.05), Vector3(0.25, -0.3, 0))
	_legs(rv, 3, 0.7, "roach", -0.15, 0.4)
	var arrow := node3d(r, "SenseArrow", Vector3(0, 1.4, 0))
	var am := mesh(arrow, "Arrow", PrismMesh.new(), "arrow", Vector3(0, 0, -0.6), Vector3(-PI * 0.5, 0, 0), Vector3(0.6, 0.8, 0.15))
	am.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pack(r, "res://scenes/bugs/cockroach.tscn", force)

	# Fly
	var f := scripted(CharacterBody3D.new(), "res://scripts/bugs/fly.gd", "Fly")
	f.set("stats", load("res://resources/bugs/fly.tres"))
	shape(f, sphere_shape(0.35))
	var fv := node3d(f, "Visual")
	mesh(fv, "Body", sphere(0.4), "fly", Vector3(0, 0, 0.15), Vector3.ZERO, Vector3(0.85, 0.75, 1.2))
	mesh(fv, "Head", sphere(0.28), "fly", Vector3(0, 0.05, -0.45))
	mesh(fv, "EyeL", sphere(0.17), "fly_eye", Vector3(-0.18, 0.12, -0.55))
	mesh(fv, "EyeR", sphere(0.17), "fly_eye", Vector3(0.18, 0.12, -0.55))
	var wl := node3d(fv, "WingL", Vector3(-0.2, 0.3, 0.1))
	mesh(wl, "Wing", box(Vector3(0.9, 0.02, 0.45)), "wing", Vector3(-0.45, 0, 0.1))
	var wr := node3d(fv, "WingR", Vector3(0.2, 0.3, 0.1))
	mesh(wr, "Wing", box(Vector3(0.9, 0.02, 0.45)), "wing", Vector3(0.45, 0, 0.1))
	_legs(fv, 3, 0.5, "fly", -0.25, 0.25)
	pack(f, "res://scenes/bugs/fly.tscn", force)

	# Spider
	var s := scripted(CharacterBody3D.new(), "res://scripts/bugs/spider.gd", "Spider")
	s.set("stats", load("res://resources/bugs/spider.tres"))
	shape(s, sphere_shape(0.35))
	var sv := node3d(s, "Visual")
	mesh(sv, "Abdomen", sphere(0.42), "spider", Vector3(0, 0.1, 0.45), Vector3.ZERO, Vector3(1, 0.85, 1.15))
	mesh(sv, "Thorax", sphere(0.26), "spider", Vector3(0, 0.02, -0.15))
	mesh(sv, "Eyes", box(Vector3(0.22, 0.06, 0.04)), "fly_eye", Vector3(0, 0.12, -0.38))
	_legs(sv, 4, 1.1, "spider", -0.05, 0.4)
	var zl := mesh(s, "ZipLine", box(Vector3(0.06, 0.06, 1.0)), "web")
	zl.top_level = true
	zl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pack(s, "res://scenes/bugs/spider.tscn", force)

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
	mesh(v, "Leg", cyl(1.9, 36.0, 2.6), "jeans", Vector3(0, 20.5, 2.0))
	pack(f, "res://scenes/hazards/foot.tscn", force)


static func human(force: bool, path: String, config: String, torso_mat: String, has_paper: bool) -> void:
	var h := scripted(CharacterBody3D.new(), "res://scripts/threats/human.gd", "Human")
	h.set("config", load(config))
	h.set("icon_height", 78.0)
	var cap := CapsuleShape3D.new()
	cap.radius = 6.0
	cap.height = 34.0
	shape(h, cap, Vector3(0, 55, 0))
	var torso := node3d(h, "Torso")
	mesh(torso, "Hips", box(Vector3(13, 9, 7)), "jeans", Vector3(0, 39, 2))
	mesh(torso, "Chest", box(Vector3(15, 20, 8)), torso_mat, Vector3(0, 53, 2))
	mesh(torso, "ArmL", cyl(1.6, 20), "skin", Vector3(-9.5, 52, 2), Vector3(0, 0, 0.12))
	mesh(torso, "ArmR", cyl(1.6, 20), "skin", Vector3(9.5, 52, 2), Vector3(0, 0, -0.12))
	mesh(torso, "Head", sphere(5.0), "skin", Vector3(0, 68, 2))
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
		h.add_child(np)
		h.set("has_newspaper", true)
	pack(h, path, force)


static func pet(force: bool, path: String, config: String, color: String, big: bool, is_dog: bool) -> void:
	var p := scripted(CharacterBody3D.new(), "res://scripts/threats/pet.gd", "Dog" if is_dog else "Cat")
	p.set("config", load(config))
	p.set("barks", is_dog)
	p.set("uses_perches", not is_dog)
	var k := 1.4 if big else 1.0
	p.set("icon_height", 10.0 * k)
	var cap := CapsuleShape3D.new()
	cap.radius = 2.2 * k
	cap.height = 10.0 * k
	shape(p, cap, Vector3(0, 3.5 * k, 0), Vector3(PI * 0.5, 0, 0))
	var v := node3d(p, "Visual")
	mesh(v, "Body", capsule(2.4 * k, 11.0 * k), color, Vector3(0, 5.0 * k, 0.5), Vector3(PI * 0.5, 0, 0))
	mesh(v, "Head", sphere(2.3 * k), color, Vector3(0, 7.2 * k, -6.0 * k))
	if is_dog:
		mesh(v, "Snout", box(Vector3(1.8, 1.6, 2.6) * k), color, Vector3(0, 6.6 * k, -8.2 * k))
		mesh(v, "EarL", box(Vector3(0.6, 2.6, 1.6) * k), "dark_wood", Vector3(-2.0 * k, 7.2 * k, -5.6 * k))
		mesh(v, "EarR", box(Vector3(0.6, 2.6, 1.6) * k), "dark_wood", Vector3(2.0 * k, 7.2 * k, -5.6 * k))
	else:
		mesh(v, "EarL", PrismMesh.new(), color, Vector3(-1.2, 9.6, -6.0), Vector3.ZERO, Vector3(1.4, 1.8, 0.6))
		mesh(v, "EarR", PrismMesh.new(), color, Vector3(1.2, 9.6, -6.0), Vector3.ZERO, Vector3(1.4, 1.8, 0.6))
	mesh(v, "Tail", cyl(0.5 * k, 8.0 * k), color, Vector3(0, 7.0 * k, 7.5 * k), Vector3(0.8, 0, 0))
	for x in [-1.4, 1.4]:
		for z in [-3.5, 3.5]:
			mesh(v, "Leg", cyl(0.7 * k, 4.0 * k), color, Vector3(x * k, 1.8 * k, z * k))
	mesh(v, "EyeL", sphere(0.45), "fly_eye" if is_dog else "pea", Vector3(-0.9 * k, 7.9 * k, -7.9 * k))
	mesh(v, "EyeR", sphere(0.45), "fly_eye" if is_dog else "pea", Vector3(0.9 * k, 7.9 * k, -7.9 * k))
	var agent := NavigationAgent3D.new()
	agent.name = "Agent"
	agent.path_desired_distance = 1.5
	agent.target_desired_distance = 1.5
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
	pack(v, "res://scenes/threats/robot_vacuum.tscn", force)


static func threats(force: bool) -> void:
	foot(force)
	human(force, "res://scenes/threats/human.tscn", "res://resources/threats/human.tres", "shirt", false)
	human(force, "res://scenes/threats/human_reader.tscn", "res://resources/threats/human.tres", "cloth_blue", true)
	human(force, "res://scenes/threats/exterminator.tscn", "res://resources/threats/exterminator.tres", "hazmat", false)
	pet(force, "res://scenes/threats/cat.tscn", "res://resources/threats/cat.tres", "cat_orange", false, false)
	pet(force, "res://scenes/threats/dog.tscn", "res://resources/threats/dog.tres", "dog_brown", true, true)
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
		if golden:
			var glow := OmniLight3D.new()
			glow.name = "Glow"
			glow.light_color = Color(1, 0.8, 0.3)
			glow.omni_range = 6.0
			glow.light_energy = 1.5
			v.add_child(glow)
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
