class_name LivingRoomLayout
## The Living Room: couch on the back wall (hide under it), coffee table and
## rug in the middle, TV on the front wall (its noise masks yours, its glow
## exposes you), bookshelf, side table with a lamp and a mug the cat can knock
## onto a foot, a fan by the window and the cat tree. Secret route: a wall
## crack by the couch (roach) or a high vent (fly/spider).


static func build(tree: SceneTree) -> void:
	var g := LevelGeo.new("LivingRoom")
	g.environment(Color(0.07, 0.07, 0.09), Color(0.8, 0.82, 0.95), 0.7)
	g.sun(Vector3(-40, -60, 0), 0.8, Color(1.0, 0.9, 0.75))
	g.room(Vector3(130, 90, 100), "wood", &"wood", "wall_blue", true)
	g.box("Rug", Vector3(0, -0.2, 2), Vector3(52, 0.5, 38), "rug", &"carpet", &"", 0.0, false)

	# --- Couch (hide underneath) ---
	g.box("CouchBase", Vector3(-10, 8.5, -39), Vector3(60, 11, 20), "cloth_red", &"cloth")
	g.box("CouchBack", Vector3(-10, 24, -46.5), Vector3(60, 20, 5), "cloth_red", &"cloth")
	g.box("CouchArm", Vector3(-42.5, 12.5, -39), Vector3(5, 19, 20), "cloth_red", &"cloth")
	g.box("CouchArm", Vector3(22.5, 12.5, -39), Vector3(5, 19, 20), "cloth_red", &"cloth")
	for p in [Vector3(-38, 1.5, -47), Vector3(18, 1.5, -47), Vector3(-38, 1.5, -31), Vector3(18, 1.5, -31)]:
		g.box("CouchLeg", p, Vector3(2, 3, 2), "dark_wood", &"wood", &"dark_wood")
	g.hiding_spot("UnderCouch", Vector3(-10, 1.4, -39), Vector3(56, 2.8, 18))
	g.light_zone("UnderCouchShadow", Vector3(-10, 1.5, -39), Vector3(58, 3, 20), 0, 3)
	g.lure("Phone", LureProp.Kind.PHONE, Vector3(22.5, 22.3, -38), Vector3(3.2, 0.5, 6.4), "dark_metal", 2.2, "lure_phone")

	# --- Coffee table + blanket ramp ---
	g.box("CoffeeTable", Vector3(-8, 16, -8), Vector3(34, 1.5, 18), "wood", &"wood")
	for p in [Vector3(-23, 7.6, -15), Vector3(7, 7.6, -15), Vector3(-23, 7.6, -1), Vector3(7, 7.6, -1)]:
		g.box("CoffeeLeg", p, Vector3(1.5, 15.25, 1.5), "dark_wood", &"wood", &"dark_wood")
	g.light_zone("UnderCoffeeTable", Vector3(-8, 4, -8), Vector3(32, 8, 16), 1, 2)
	g.ramp("Blanket", Vector3(29, 0, -8), Vector3(8.5, 16.8, -8), 7.0, "cloth_blue", &"cloth")

	# --- TV: noise cover and a glow that exposes you ---
	g.box("TVStand", Vector3(-8, 10, 44), Vector3(40, 20, 10), "dark_wood", &"wood", &"dark_wood")
	g.box("TV", Vector3(-8, 34, 47), Vector3(40, 24, 2), "dark_metal", &"metal")
	g.deco_box("Screen", Vector3(-8, 34, 45.9), Vector3(36, 20, 0.2), "tv_screen", Vector3.ZERO, false)
	var tv := g.ambient("TVSound", Vector3(-8, 30, 40), 55.0, 0.9, "tv_mumble", ["tv_on"], [], -6.0)
	g.light_zone("TVGlow", Vector3(-8, 5, 25), Vector3(44, 10, 26), 2, 2, ["tv_on"], [], true, 1.2)
	var remote := g.lure("Remote", LureProp.Kind.REMOTE, Vector3(-2, 17.0, -10), Vector3(2.5, 0.5, 7), "dark_metal", 3.5, "lure_remote")
	remote.linked_path = remote.get_path_to(tv)

	# --- Bookshelf (spider highway) ---
	g.box("Bookshelf", Vector3(-62, 35, 12), Vector3(6, 70, 32), "dark_wood", &"wood", &"dark_wood")
	for i in 5:
		g.deco_box("Books", Vector3(-58.8, 8 + i * 13, 12), Vector3(0.6, 9, 28), "cloth_red" if i % 2 == 0 else "cloth_blue")

	# --- Side table, lamp, mug (cat perch) ---
	g.box("SideTable", Vector3(50, 12, -36), Vector3(16, 24, 16), "wood", &"wood")
	g.deco("LampBase", _cyl(2.0, 6.0), "metal", Vector3(54, 27, -40))
	g.deco("LampShade", _cyl(5.0, 8.0, 3.0), "lamp", Vector3(54, 34, -40))
	g.light_zone("LampLight", Vector3(48, 5, -26), Vector3(40, 10, 34), 2, 2, ["lamp_on"], [], true, 2.0)
	g.prop("mug", Vector3(50, 26.1, -28.8))
	g.prop("bottle_cap", Vector3(45, 24.3, -30))
	g.perch("SideTablePerch", Vector3(50, 0, -22), Vector3(0, 24.6, -12), 9.0)

	# --- Fan by the window, sunbeam, cat tree ---
	g.deco("FanStand", _cyl(1.0, 18.0), "dark_metal", Vector3(58, 9, 18))
	g.deco("FanHead", _cyl(6.0, 2.0), "metal", Vector3(57, 19, 18), Vector3(0, 0, PI * 0.5))
	g.wind("FanWind", Vector3(35, 15, 18), Vector3(40, 20, 12), Vector3(-1, 0, 0), 60.0, ["fan_on"])
	g.ambient("FanHum", Vector3(57, 18, 18), 25.0, 0.4, "fan", ["fan_on"], [], -12.0)
	g.deco_box("Window", Vector3(64.85, 45, 10), Vector3(0.2, 34, 30), "window", Vector3.ZERO, false)
	g.light_zone("Sunbeam", Vector3(48, 2, 10), Vector3(26, 4, 26), 3, 2, ["curtains_open"], ["lights_out"])
	g.box("CatTreeBase", Vector3(55, 1, 40), Vector3(14, 2, 14), "carpet", &"carpet")
	g.cylinder("CatTreePost", Vector3(55, 16, 40), 2.0, 30, "carpet", &"carpet")
	g.box("CatTreeLow", Vector3(55, 15.5, 40), Vector3(12, 1, 12), "carpet", &"carpet")
	g.box("CatTreeTop", Vector3(55, 31.5, 40), Vector3(10, 1.5, 10), "carpet", &"carpet")
	g.perch("CatTreePerch", Vector3(46, 0, 40), Vector3(9, 32.5, 0), 4.0)

	# --- Clutter ---
	g.cylinder("UmbrellaStand", Vector3(30, 6, 44), 4.0, 12, "metal", &"metal")
	g.rebounder("UmbrellaRebound", Vector3(30, 0, 44), 6.0)
	g.cylinder("PlantPot", Vector3(-50, 8, -44), 6.0, 16, "soil", &"soil", &"soil")
	g.deco("Plant", _sphere(9.0), "leaf_green", Vector3(-50, 24, -44))
	g.scent_wiper("SpilledSoda", Vector3(-30, 0.6, -20), Vector3(6, 1.2, 5))
	g.sticky_trap("GlueTrap", Vector3(-52, 0.5, 32), Vector3(7, 1, 7))
	g.prop("ball", Vector3(10, 1.6, 10))
	g.prop("acorn", Vector3(-20, 0.7, 30))

	# --- Crumbs (popcorn) ---
	for p in [Vector3(-40, 0.6, 30), Vector3(-20, 0.6, 20), Vector3(0, 0.6, 5), Vector3(15, 0.6, -5),
			Vector3(-10, 0.6, -32), Vector3(-35, 0.6, -25), Vector3(12, 0.6, 36), Vector3(30, 0.6, 12),
			Vector3(44, 0.6, 28), Vector3(52, 0.6, -15), Vector3(-50, 0.6, 0),
			Vector3(-14, 17.4, -6), Vector3(-20, 14.6, -36), Vector3(-62, 70.6, 12), Vector3(46, 24.6, -38)]:
		g.crumb(p)

	# --- Secret route: wall cavity behind the left wall ---
	g.box("CavityFloor", Vector3(-73, -1, -30), Vector3(12, 2, 30), "dark_wood", &"wood", &"dark_wood")
	g.box("CavityOuter", Vector3(-79.5, 6, -30), Vector3(1, 14, 30), "dark_wood", &"wood")
	g.box("CavityEndA", Vector3(-73, 6, -45.5), Vector3(14, 14, 1), "dark_wood", &"wood")
	g.box("CavityEndB", Vector3(-73, 6, -14.5), Vector3(14, 14, 1), "dark_wood", &"wood")
	g.box("CavityTop", Vector3(-73, 13.5, -30), Vector3(14, 1, 32), "dark_wood", &"wood")
	g.light_zone("CavityDark", Vector3(-73, 6, -30), Vector3(12, 12, 30), 0, 3, [], [], false)
	g.crumb(Vector3(-73, 0.6, -30), true)
	g.passage("WallCrack", Vector3(-63.5, 1.5, -26), Vector3(-73, 0.8, -40), ["cockroach"], "crack in the wall")
	g.passage("HighVent", Vector3(-64.2, 70, -10), Vector3(-73, 0.8, -22), ["fly", "spider"], "air vent",
		Vector3.UP, Vector3(4, 7, 7))
	g.deco_box("VentGrille", Vector3(-64.85, 70, -10), Vector3(0.3, 6, 8), "dark_metal")
	g.passage("CavityExit", Vector3(-73, 1.5, -18), Vector3(-55, 0.8, -20), [], "crack back to the room")

	# --- Cover ---
	g.shelter("SlipperA", Vector3(-45, 0, 12), Vector3(4.6, 3.6, 9.5), "cloth_blue", false, "slipper", "cover_slipper", &"cloth")
	g.shelter("SlipperB", Vector3(-40, 0, -24), Vector3(9.5, 3.6, 4.6), "cloth_blue", true, "slipper", "cover_slipper", &"cloth")
	g.shelter("FallenPillow", Vector3(20, 0, 16), Vector3(9, 3.2, 9), "cloth_red", true, "fallen pillow", "cover_throw_pillow", &"cloth")
	g.shelter("Shoe", Vector3(34, 0, -46), Vector3(10, 4.2, 4.6), "shoe", true, "shoe", "cover_sneaker", &"cloth")
	g.cover_block("MagazinePile", Vector3(-20, 0, 10), Vector3(10, 2.2, 7), "paper", "magazine pile", "cover_magazines", &"paper")
	g.cover_block("ToyBlocks", Vector3(22, 0, 38), Vector3(6, 5, 6), "ball", "toy blocks", "cover_toy_blocks", &"wood")

	# --- Model slots for the furniture ---
	g.skin_region("Couch", "living_couch", Vector3(-10, 17, -39), Vector3(70, 34, 20), ["Couch"])
	g.skin_region("CoffeeTable", "coffee_table", Vector3(-8, 8.4, -8), Vector3(34, 16.8, 18), ["CoffeeTable", "CoffeeLeg"])
	g.skin_region("TVStand", "tv_stand", Vector3(-8, 10, 44), Vector3(40, 20, 10), ["TVStand"])
	g.skin_region("TV", "flat_tv", Vector3(-8, 34, 46.5), Vector3(40, 24, 3), ["TV", "Screen"])
	g.skin_region("Bookshelf", "bookshelf", Vector3(-62, 35, 12), Vector3(6, 70, 32), ["Bookshelf", "Books"], 90.0)
	g.skin_region("SideTable", "side_table", Vector3(50, 12, -36), Vector3(16, 24, 16), ["SideTable"])
	g.skin_region("Lamp", "table_lamp", Vector3(54, 31, -40), Vector3(10, 14, 10), ["Lamp"])
	g.skin_region("Fan", "desk_fan", Vector3(57.5, 10, 18), Vector3(4, 20, 12), ["Fan"], -90.0)
	g.skin_region("CatTree", "cat_tree", Vector3(55, 16.2, 40), Vector3(14, 32.4, 14), ["CatTree"])
	g.skin_region("UmbrellaStand", "umbrella_stand", Vector3(30, 6, 44), Vector3(8, 12, 8), ["UmbrellaStand"])
	g.skin_region("Plant", "potted_plant", Vector3(-50, 16.5, -44), Vector3(18, 33, 18), ["PlantPot", "Plant"])

	# --- Spawn and escape ---
	g.spawn(Vector3(-55, 0.8, 42), -PI * 0.5)
	g.goal(Vector3(61, 0, -46), "gap under the hall door")
	g.deco_box("DoorCrack", Vector3(64.85, 2.5, -46), Vector3(0.2, 5, 8), "hole", Vector3.ZERO, false)

	# --- Threats ---
	g.human("res://scenes/threats/human_reader.tscn",
		[Vector3(40, 0, -20), Vector3(-34, 0, -22), Vector3(-36, 0, 20), Vector3(25, 0, 26), Vector3(40, 0, 5)],
		["tv_on", "reading"], {"name": "Reader"})
	var cat := g.pet("res://scenes/threats/cat.tscn", Vector3(40, 0.5, 40),
		[Vector3(30, 0, 30), Vector3(-30, 0, 30), Vector3(-40, 0, -15), Vector3(30, 0, -15), Vector3(45, 0, 10)],
		["cat_nap"])
	g.escalation()
	g.boss(BossDirector.Kind.THE_CAT, "The Cat",
		"It has been watching you all along. Stalk, hunt, pounce - get to the door!",
		{"cat_path": cat})
	g.finalize("res://scripts/world/level.gd", &"living_room", "res://scenes/levels/living_room.tscn", tree)


static func _cyl(r: float, h: float, top: float = -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r if top < 0.0 else top
	c.bottom_radius = r
	c.height = h
	return c


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s
