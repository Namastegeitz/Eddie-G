class_name BackyardLayout
## The Backyard: 194 x 164 (x -82..112, z -62..102). Open sky, patio by the
## house, flower beds (soil camo), a picnic table, BBQ, doghouse (hide
## underneath), a vegetable garden, a garden shed (hide underneath), a bird
## bath, sprinklers and puddles that wash away your scent, leaf piles and a
## compost heap that crunch. The dog tracks your scent.
## Secret route: a foundation crack (roach) or a torn window screen
## (fly/spider) into the crawlspace. Boss: the exterminator's fog.


static func build(tree: SceneTree) -> void:
	var g := LevelGeo.new("Backyard")
	g.environment(Color(0.45, 0.65, 0.9), Color(0.85, 0.9, 1.0), 0.9)
	g.sun(Vector3(-50, 25, 0), 1.1, Color(1.0, 0.96, 0.86))
	g.box("Lawn", Vector3(15, -1, 20), Vector3(198, 2, 168), "grass", &"grass")
	g.box("HouseWall", Vector3(15, 40, -62), Vector3(198, 80, 4), "wall_paint", &"default", &"", 0.0, false)
	g.box("FenceFront", Vector3(15, 15, 103), Vector3(198, 30, 2), "fence", &"wood", &"dark_wood")
	g.box("FenceLeft", Vector3(-83, 15, 20), Vector3(2, 30, 168), "fence", &"wood", &"dark_wood")
	g.box("FenceRight", Vector3(113, 15, 20), Vector3(2, 30, 168), "fence", &"wood", &"dark_wood")
	# Invisible boundary so flyers can't leave the yard.
	g.invisible_wall("SkyFront", Vector3(15, 70, 103), Vector3(200, 80, 2))
	g.invisible_wall("SkyLeft", Vector3(-83, 70, 20), Vector3(2, 80, 170))
	g.invisible_wall("SkyRight", Vector3(113, 70, 20), Vector3(2, 80, 170))
	g.invisible_wall("SkyLid", Vector3(15, 110, 20), Vector3(200, 2, 170))

	# --- Patio, back door, porch light ---
	g.box("Patio", Vector3(0, -0.2, -48), Vector3(70, 0.5, 24), "patio", &"patio", &"", 0.0, false)
	g.deco_box("BackDoor", Vector3(0, 15, -59.9), Vector3(14, 30, 0.2), "dark_wood", Vector3.ZERO, false)
	g.light_zone("PorchLight", Vector3(0, 3, -50), Vector3(30, 6, 18), 3, 3, ["porch_light"], [], true, 2.5)
	g.drain("PatioDrain", Vector3(5, 0.9, -40), 3.5, Vector3(5, 0.8, -30), ["watering"])
	g.lure("WateringCan", LureProp.Kind.SPOON, Vector3(-10, 2.5, -40), Vector3(6, 5, 4), "metal", 3.0, "lure_watering_can")
	g.sticky_trap("FlyPaper", Vector3(15, 25, -45), Vector3(2, 10, 2), true)

	# --- Flower beds (soil camo + shade) ---
	g.box("FlowerBedW", Vector3(-58, -0.2, -22), Vector3(30, 0.5, 14), "soil", &"soil", &"soil", 0.0, false)
	g.box("FlowerBedE", Vector3(56, -0.2, -12), Vector3(18, 0.5, 34), "soil", &"soil", &"soil", 0.0, false)
	g.light_zone("BedShadeW", Vector3(-58, 3, -22), Vector3(30, 6, 14), 1, 2)
	g.light_zone("BedShadeE", Vector3(56, 3, -12), Vector3(18, 6, 34), 1, 2)
	for p in [Vector3(-68, 0, -24), Vector3(-60, 0, -19), Vector3(-50, 0, -25), Vector3(52, 0, -24),
			Vector3(60, 0, -12), Vector3(53, 0, 0), Vector3(59, 0, 2)]:
		g.deco("Stem", _cyl(0.4, 14.0), "leaf_green", p + Vector3(0, 7, 0))
		g.deco("Bloom", _sphere(2.6), "flower", p + Vector3(0, 15, 0))

	# --- Picnic table + rake ramp to the bench ---
	g.box("PicnicTop", Vector3(-20, 26, 15), Vector3(36, 1.5, 18), "wood", &"wood")
	for p in [Vector3(-34, 12.6, 9), Vector3(-6, 12.6, 9), Vector3(-34, 12.6, 21), Vector3(-6, 12.6, 21)]:
		g.box("PicnicLeg", p, Vector3(1.5, 25.25, 1.5), "dark_wood", &"wood", &"dark_wood")
	g.box("BenchA", Vector3(-20, 14, 3), Vector3(36, 1.5, 6), "wood", &"wood")
	g.box("BenchB", Vector3(-20, 14, 27), Vector3(36, 1.5, 6), "wood", &"wood")
	for p in [Vector3(-36, 6.6, 3), Vector3(-4, 6.6, 3), Vector3(-36, 6.6, 27), Vector3(-4, 6.6, 27)]:
		g.box("BenchLeg", p, Vector3(1.2, 13.25, 4), "dark_wood", &"wood", &"dark_wood")
	g.light_zone("UnderPicnic", Vector3(-20, 6, 15), Vector3(34, 12, 30), 1, 2)
	g.ramp("Rake", Vector3(-60, 0, 3), Vector3(-38.2, 14.75, 3), 5.0, "dark_wood", &"wood", &"dark_wood")
	g.lure("Phone", LureProp.Kind.PHONE, Vector3(-14, 27.0, 20), Vector3(3.2, 0.5, 6.4), "dark_metal", 2.2, "lure_phone")

	# --- BBQ (bright while grilling, metal clang) ---
	g.cylinder("Grill", Vector3(35, 14, -38), 6.0, 6, "dark_metal", &"metal")
	for p in [Vector3(31, 5.5, -38), Vector3(39, 5.5, -38)]:
		g.box("GrillLeg", p, Vector3(1, 11, 1), "dark_metal", &"metal")
	g.light_zone("GrillGlow", Vector3(35, 3, -30), Vector3(20, 6, 16), 3, 3, ["bbq"], [], true, 2.0)
	g.rebounder("GrillRebound", Vector3(35, 0, -38), 7.0)

	# --- Doghouse (raised: the gap underneath is a hiding spot) ---
	g.box("Doghouse", Vector3(-55, 11, 40), Vector3(20, 18, 16), "wood", &"wood")
	for p in [Vector3(-63, 1, 34), Vector3(-47, 1, 34), Vector3(-63, 1, 46), Vector3(-47, 1, 46)]:
		g.box("DoghouseBlock", p, Vector3(3, 2, 3), "patio", &"patio")
	g.deco("Roof", PrismMesh.new(), "cloth_red", Vector3(-55, 24, 40), Vector3.ZERO, Vector3(22, 8, 18))
	g.deco_box("DogDoor", Vector3(-55, 9, 31.9), Vector3(7, 9, 0.2), "hole", Vector3.ZERO, false)
	g.hiding_spot("UnderDoghouse", Vector3(-55, 1, 40), Vector3(18, 2, 14))
	g.water_bowl(Vector3(-40, 1.5, 46), Vector3(1, 0, 0))
	g.light_zone("UnderDoghouseShadow", Vector3(-55, 1, 40), Vector3(20, 2, 16), 0, 3)

	# --- Water: hose puddles and the sprinkler wash your scent away ---
	g.scent_wiper("Puddle", Vector3(10, 0.6, 5), Vector3(8, 1.2, 6))
	g.scent_wiper("Puddle", Vector3(-30, 0.6, -5), Vector3(6, 1.2, 6))
	g.scent_wiper("SprinklerSpray", Vector3(25, 2, 25), Vector3(26, 4, 26), ["watering"], false)
	g.ambient("Sprinkler", Vector3(25, 2, 25), 35.0, 0.7, "sprinkler", ["watering"], [], -8.0)
	g.deco("SprinklerHead", _cyl(1.0, 1.5), "metal", Vector3(25, 0.75, 25))
	g.box("LeafPile", Vector3(20, -0.2, 42), Vector3(16, 0.5, 12), "leaves", &"leaves", &"", 0.0, false)
	g.sticky_trap("GlueTrap", Vector3(-40, 0.5, 26), Vector3(7, 1, 7))
	g.prop("ball", Vector3(0, 1.6, 20))
	g.prop("acorn", Vector3(40, 0.7, 50))
	g.prop("acorn", Vector3(-30, 0.7, 50))

	# --- Vegetable garden (soil camo, shade under the leaves) ---
	g.box("VeggieBed", Vector3(95, -0.2, 28), Vector3(24, 0.5, 44), "soil", &"soil", &"soil", 0.0, false)
	g.light_zone("VeggieShade", Vector3(95, 3, 28), Vector3(24, 6, 44), 1, 2)
	for i in 4:
		for j in 2:
			var p := Vector3(88 + j * 14, 0, 12 + i * 11)
			g.deco("Lettuce", _sphere(3.2), "leaf_green", p + Vector3(0, 2.2, 0))
			if (i + j) % 2 == 0:
				g.deco("TomatoStake", _cyl(0.3, 18.0), "dark_wood", p + Vector3(3, 9, 3))
				g.deco("Tomato", _sphere(1.4), "cloth_red", p + Vector3(3.5, 7, 2.5))

	# --- Garden shed (raised on blocks: hide underneath) ---
	g.box("Shed", Vector3(92, 21, 86), Vector3(30, 36, 22), "fence", &"wood", &"dark_wood")
	for p in [Vector3(79, 1.5, 77), Vector3(105, 1.5, 77), Vector3(79, 1.5, 95), Vector3(105, 1.5, 95)]:
		g.box("ShedBlock", p, Vector3(3, 3, 3), "patio", &"stone")
	g.deco("ShedRoof", PrismMesh.new(), "dark_wood", Vector3(92, 43, 86), Vector3.ZERO, Vector3(33, 10, 25))
	g.deco_box("ShedDoor", Vector3(92, 19, 74.9), Vector3(10, 26, 0.2), "dark_wood", Vector3.ZERO, false)
	g.hiding_spot("UnderShed", Vector3(92, 1.5, 86), Vector3(26, 3, 18))
	g.light_zone("UnderShedShadow", Vector3(92, 1.5, 86), Vector3(28, 3, 20), 0, 3)

	# --- Bird bath (water on top washes scent), woodpile, wheelbarrow, compost ---
	g.cylinder("BirdBathPost", Vector3(55, 10, 72), 2.5, 20, "patio", &"stone")
	g.cylinder("BirdBathBowl", Vector3(55, 21.5, 72), 8.0, 3, "patio", &"stone")
	g.deco("BirdBathWater", _cyl(7.2, 0.2), "water", Vector3(55, 23.05, 72))
	g.scent_wiper("BirdBathPool", Vector3(55, 23.6, 72), Vector3(12, 1.2, 12), [], false)
	g.box("Compost", Vector3(-20, -0.2, 86), Vector3(18, 0.5, 13), "leaves", &"leaves", &"soil", 0.0, false)
	g.light_zone("CompostShade", Vector3(-20, 3, 86), Vector3(18, 6, 13), 1, 2)

	# --- Warm air for the fly: the grill, the sun-baked patio, the compost ---
	g.thermal("GrillHeat", Vector3(35, 40, -38), Vector3(14, 44, 14), 9.0, ["bbq"])
	g.thermal("PatioHeat", Vector3(0, 25, -48), Vector3(40, 40, 20), 4.0)
	g.thermal("CompostHeat", Vector3(-20, 12, 86), Vector3(16, 20, 12), 5.0)

	# --- Crumbs ---
	for p in [Vector3(-40, 0.6, -10), Vector3(-15, 0.6, -25), Vector3(20, 0.6, -15), Vector3(45, 0.6, 10),
			Vector3(30, 0.6, 35), Vector3(0, 0.6, 40), Vector3(-30, 0.6, 38), Vector3(-65, 0.6, 10),
			Vector3(-20, 0.6, 15), Vector3(60, 0.6, 40), Vector3(-58, 0.6, -22), Vector3(56, 0.6, -20),
			Vector3(-28, 15.4, 3), Vector3(-26, 27.4, 12), Vector3(-12, 27.4, 18), Vector3(35, 17.6, -38),
			Vector3(90, 0.6, 5), Vector3(102, 0.6, 40), Vector3(75, 0.6, 88), Vector3(45, 0.6, 70),
			Vector3(10, 0.6, 92), Vector3(-30, 0.6, 72), Vector3(-62, 0.6, 52), Vector3(30, 0.6, 85),
			Vector3(72, 0.6, 55)]:
		g.crumb(p)

	# --- Bug food and crumb gems ---
	g.item("mint_leaf", Vector3(95, 0, 34))
	g.item("mint_leaf", Vector3(-40, 0, 60))
	g.item("honey_drop", Vector3(-58, 0, -18))
	g.item("kibble", Vector3(-44, 0, 30))
	g.item("sugar_cube", Vector3(-25, 26.75, 18))
	g.item("cheese", Vector3(-20, 0, 15))
	g.item("coffee_bean", Vector3(-20, 0, 86))
	g.item("gem_ruby", Vector3(55, 23, 72))
	g.item("gem_emerald", Vector3(109, 0, 99))

	# --- Secret route: the crawlspace under the house ---
	g.box("CrawlFloor", Vector3(-25, -1, -72), Vector3(30, 2, 14), "soil", &"soil", &"soil")
	g.box("CrawlBack", Vector3(-25, 6, -79.5), Vector3(30, 14, 1), "patio", &"stone")
	g.box("CrawlEndA", Vector3(-40.5, 6, -72), Vector3(1, 14, 16), "patio", &"stone")
	g.box("CrawlEndB", Vector3(-9.5, 6, -72), Vector3(1, 14, 16), "patio", &"stone")
	g.box("CrawlTop", Vector3(-25, 13.5, -72), Vector3(32, 1, 16), "patio", &"stone")
	g.light_zone("CrawlDark", Vector3(-25, 6, -72), Vector3(30, 12, 14), 0, 3, [], [], false)
	g.crumb(Vector3(-25, 0.6, -72), true)
	g.passage("FoundationCrack", Vector3(-25, 1.5, -58.5), Vector3(-34, 0.8, -72), ["cockroach"], "foundation crack")
	g.passage("TornScreen", Vector3(20, 45, -59.5), Vector3(-18, 0.8, -72), ["fly", "spider"], "torn window screen",
		Vector3.UP, Vector3(6, 6, 4))
	g.deco_box("Screen", Vector3(20, 45, -59.9), Vector3(10, 10, 0.2), "glass", Vector3.ZERO, false)
	g.passage("CrawlExit", Vector3(-14, 1.5, -72), Vector3(-25, 0.8, -52), [], "crack back to the patio")

	# --- Cover ---
	g.shelter("Flowerpot", Vector3(2, 0, 15), Vector3(6.5, 5.0, 6.5), "soil", true, "overturned flowerpot", "cover_flowerpot", &"soil", &"soil")
	g.shelter("HoseCoil", Vector3(10, 0, -15), Vector3(5, 3.2, 10), "leaf_green", false, "coiled garden hose", "cover_hose_coil")
	g.cover_block("RockA", Vector3(55, 0, 30), Vector3(8, 5, 6), "patio", "rock", "cover_rock", &"stone")
	g.cover_block("RockB", Vector3(-62, 0, -5), Vector3(7, 4, 6), "patio", "rock", "cover_rock", &"stone")
	g.cover_block("RockC", Vector3(5, 0, 53), Vector3(9, 4, 5), "patio", "rock", "cover_rock", &"stone")
	g.cover_block("Gnome", Vector3(30, 0, -10), Vector3(5, 12, 5), "cloth_red", "garden gnome", "cover_garden_gnome")
	g.tall_grass("GrassA", Vector3(65, 0, 15), Vector3(12, 6, 12))
	g.tall_grass("GrassB", Vector3(-25, 0, 30), Vector3(10, 6, 8))
	g.tall_grass("GrassC", Vector3(40, 0, 88), Vector3(14, 6, 10))
	g.tall_grass("GrassD", Vector3(72, 0, 30), Vector3(10, 6, 14))
	g.cover_block("Woodpile", Vector3(-60, 0, 72), Vector3(16, 8, 8), "dark_wood", "woodpile", "cover_woodpile", &"wood")
	g.shelter("Wheelbarrow", Vector3(10, 0, 70), Vector3(14, 8, 10), "dark_metal", true, "tipped wheelbarrow", "cover_wheelbarrow", &"metal")
	g.cover_block("RockD", Vector3(60, 0, 92), Vector3(7, 4, 6), "patio", "rock", "cover_rock", &"stone")
	# Places the cat leaps up onto (and knocks things off).
	g.perch("PicnicPerch", Vector3(-20, 0, 34), Vector3(0, 26.75, -17), 9.0)
	g.perch("DoghousePerch", Vector3(-55, 0, 52), Vector3(0, 20.0, -12), 6.0)
	g.perch("ShedPerch", Vector3(92, 0, 70), Vector3(0, 39.0, 14), 8.0)

	# --- Model slots for the furniture ---
	g.skin_region("Picnic", "picnic_table", Vector3(-20, 13.4, 15), Vector3(36, 26.8, 30), ["Picnic", "Bench"])
	g.skin_region("Grill", "bbq_grill", Vector3(35, 8.5, -38), Vector3(12, 17, 12), ["Grill"])
	g.skin_region("Doghouse", "doghouse", Vector3(-55, 14, 40), Vector3(22, 28, 18), ["Doghouse", "Roof", "DogDoor"])
	g.skin_region("Shed", "garden_shed", Vector3(92, 24, 86), Vector3(33, 48, 25), ["Shed", "ShedRoof", "ShedDoor"])
	g.skin_region("BirdBath", "bird_bath", Vector3(55, 11.5, 72), Vector3(16, 23, 16), ["BirdBath"])

	# --- Spawn and escape ---
	g.spawn(Vector3(-5, 0.8, -54), PI)
	g.goal(Vector3(30, 0, 99), "gap under the fence")
	g.deco_box("FenceGap", Vector3(30, 2.5, 101.9), Vector3(8, 5, 0.2), "hole", Vector3.ZERO, false)

	# --- Threats ---
	g.human("res://scenes/threats/human.tscn",
		[Vector3(-45, 0, -14), Vector3(30, 0, -28), Vector3(80, 0, 22), Vector3(82, 0, 55), Vector3(32, 0, 52),
			Vector3(35, 0, 40), Vector3(25, 0, 88), Vector3(-25, 0, 62), Vector3(-50, 0, 20)],
		["gardening", "bbq"], {"name": "Gardener", "activities": {
			0: {"kind": &"water", "time": 8.0, "face": Vector3(-58, 0, -22)},
			2: {"kind": &"kneel", "time": 10.0, "face": Vector3(95, 0, 22)},
			4: {"kind": &"rake", "time": 9.0, "face": Vector3(20, 0, 44)},
			5: {"kind": &"fetch", "time": 9.0},
		}})
	g.pet("res://scenes/threats/dog.tscn", Vector3(-48, 0.5, 25),
		[Vector3(-40, 0, 0), Vector3(20, 0, 0), Vector3(40, 0, 30), Vector3(80, 0, 60), Vector3(20, 0, 60),
			Vector3(0, 0, 45), Vector3(-45, 0, 25)],
		["dog_nap"])
	# The cat is out too: suns itself while the gardener works, plays chase
	# with the dog, and prowls the garden beds.
	g.pet("res://scenes/threats/cat.tscn", Vector3(70, 0.5, 70),
		[Vector3(70, 0, 70), Vector3(40, 0, 60), Vector3(60, 0, 20), Vector3(75, 0, -5), Vector3(20, 0, 10),
			Vector3(-10, 0, 50)],
		["gardening"])
	var ext := g.human("res://scenes/threats/exterminator.tscn",
		[Vector3(-60, 0, -50), Vector3(0, 0, -30), Vector3(40, 0, 0), Vector3(30, 0, 50)],
		["exterminator_visit"], {"name": "Exterminator", "heavy_boots": true, "has_swatter": false, "spray_interval": 3.5})
	var fog := g.fog(Vector3(15, 0, -58), PI, 150.0, 98.0, 205.0)
	g.escalation()
	g.boss(BossDirector.Kind.EXTERMINATOR, "The Exterminator",
		"Fog is rolling across the yard. Get through the fence before it reaches you!",
		{"fog_path": fog, "human_path": ext})
	g.finalize("res://scripts/world/level.gd", &"backyard", "res://scenes/levels/backyard.tscn", tree)


static func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s
