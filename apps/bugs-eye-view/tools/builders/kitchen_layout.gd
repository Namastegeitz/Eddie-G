class_name KitchenLayout
## The Kitchen: 170 x 125 floor (1 unit ~ 2.5 cm; x -60..110, z -45..80).
## Counters + sink + stove on the back wall, fridge between them and the
## pantry, table and chairs in the middle, an island, pet bowls and a mop
## bucket in the east half. Secret route: the gap beside the fridge (roach) or
## the high air vent (fly/spider) leads into a wall cavity with the Golden Crumb.


static func build(tree: SceneTree) -> void:
	var g := LevelGeo.new("Kitchen")
	g.environment(Color(0.1, 0.085, 0.07), Color(0.95, 0.88, 0.75), 0.8)
	g.sun(Vector3(-58, 35, 0), 0.9)
	g.room(Vector3(170, 100, 125), "tile", &"tile", "wall_paint", true, Vector3(25, 0, 17.5))

	# --- Counter run along the back wall (x -60..0) with a toe-kick gap ---
	g.box("ToeKick", Vector3(-30, 2, -34.5), Vector3(60, 4, 21), "dark_wood", &"wood", &"dark_wood")
	g.box("Cabinets", Vector3(-30, 20, -33), Vector3(60, 32, 24), "wood", &"wood")
	g.box("Countertop", Vector3(-30, 37, -32.5), Vector3(62, 2, 27), "counter_stone", &"stone")
	g.hiding_spot("ToeKickGap", Vector3(-30, 1.6, -22.5), Vector3(58, 3.2, 3.0))
	g.light_zone("ToeKickShadow", Vector3(-30, 2, -22.5), Vector3(58, 4, 3.2), 0, 3)
	for i in 4:
		g.deco_box("CabinetDoor", Vector3(-52 + i * 15, 20, -20.9), Vector3(13, 28, 0.3), "dark_wood")
	# Sink + drain (dishes) on the counter.
	g.deco_box("SinkBasin", Vector3(-35, 38.05, -33), Vector3(16, 0.1, 12), "metal")
	g.drain("SinkDrain", Vector3(-35, 39.0, -33), 5.0, Vector3(-20, 38.6, -30), ["dishes"])
	g.deco_box("Faucet", Vector3(-35, 44, -42), Vector3(1.5, 12, 1.5), "metal")
	g.deco_box("FaucetSpout", Vector3(-35, 49.5, -38.5), Vector3(1.5, 1.5, 8), "metal")
	g.ambient("Dishwasher", Vector3(-10, 10, -30), 45.0, 0.8, "dishwasher", ["dishes"])
	# Lures and props on the counter.
	g.prop("pea", Vector3(-22, 38.6, -20.2))
	g.prop("bottle_cap", Vector3(-50, 38.3, -20.8))
	for i in 3:
		g.prop("cereal_box", Vector3(-14 + i * 4.0, 42.6, -26), Vector3(0, PI * 0.5, 0))
	g.lure("Spoon", LureProp.Kind.SPOON, Vector3(-46, 38.3, -27), Vector3(1.2, 0.4, 7), "metal", 2.6, "lure_spoon")
	# Things to knock off the edge: a crash makes everyone look (and a glass
	# or the plant pot breaks).
	g.prop("glass", Vector3(-38, 39.85, -20.6))
	g.prop("potted_plant", Vector3(-56, 39.65, -21.2))
	g.prop("teacup", Vector3(-20, 32.35, 1.6))
	g.prop("glass", Vector3(44, 31.85, 24.4))

	# --- Stove with a hanging pan, and a metal pot on the floor ---
	g.box("Stove", Vector3(13, 18, -33), Vector3(26, 36, 24), "dark_metal", &"metal")
	for p in [Vector3(7, 36.2, -38), Vector3(19, 36.2, -38), Vector3(7, 36.2, -27), Vector3(19, 36.2, -27)]:
		g.deco("Burner", _cyl(3.5, 0.4), "metal", p)
	g.deco("Pan", _cyl(6.0, 1.2), "dark_metal", Vector3(13, 58, -30))
	g.deco_box("PanHandle", Vector3(13, 58, -41), Vector3(1.2, 0.8, 12), "dark_metal")
	g.deco_box("PanHook", Vector3(13, 80, -30), Vector3(0.4, 44, 0.4), "metal")
	g.rebounder("PanRebound", Vector3(13, 37, -30), 7.0)
	g.cylinder("Pot", Vector3(14, 5, -11), 4.5, 10, "metal", &"metal")
	g.rebounder("PotRebound", Vector3(14, 0, -11), 6.5)
	g.box("FoilSheet", Vector3(25, -0.2, -14), Vector3(9, 0.5, 7), "foil", &"foil", &"", 0.0, false)

	# --- Fridge (raised on feet: the gap underneath is a hiding spot) ---
	g.box("Fridge", Vector3(43, 37, -30), Vector3(28, 70, 26), "fridge_white", &"metal")
	for fx in [31.0, 55.0]:
		for fz in [-41.0, -19.0]:
			g.box("FridgeFoot", Vector3(fx, 1, fz), Vector3(2, 2, 2), "dark_metal", &"metal")
	g.hiding_spot("UnderFridge", Vector3(43, 1, -30), Vector3(24, 2, 22))
	g.light_zone("UnderFridgeShadow", Vector3(43, 1, -30), Vector3(26, 2, 24), 0, 3)
	var fridge_light := g.light_zone("FridgeLight", Vector3(43, 6, -9), Vector3(30, 12, 16), 3, 4, ["fridge_open"], [], true, 3.0)
	# The door: the cook opens it and it swings out into the room (an obstacle;
	# the fridge light spills out while it's open).
	g.swing_door("FridgeDoor", Vector3(57, 37, -17), Vector3(28, 68, 1.5), "fridge_white", 1.9, fridge_light)
	g.ambient("FridgeHum", Vector3(43, 10, -30), 30.0, 0.35, "fridge_hum", [], [], -14.0)

	# --- Table, chairs and the roach's climbing route ---
	g.box("TableTop", Vector3(-12, 30.75, 14), Vector3(40, 1.5, 28), "wood", &"wood")
	for lp in [Vector3(-30, 15, 2), Vector3(6, 15, 2), Vector3(-30, 15, 26), Vector3(6, 15, 26)]:
		g.cylinder("TableLeg", lp, 1.2, 30, "dark_wood", &"wood", &"dark_wood")
	g.light_zone("UnderTable", Vector3(-12, 5, 14), Vector3(36, 10, 24), 1, 2)
	_chair(g, Vector3(-24, 0, -7), 0.0)
	_chair(g, Vector3(0, 0, 35), PI)
	g.ramp("CuttingBoard", Vector3(-52, 0.0, -7), Vector3(-31, 18.75, -7), 6.0, "dark_wood", &"wood", &"dark_wood")
	g.ramp("Cookbook", Vector3(-24, 18.75, -12.4), Vector3(-24, 31.55, 0.3), 7.0, "cloth_red", &"paper")
	g.lure("Phone", LureProp.Kind.PHONE, Vector3(-4, 31.75, 20), Vector3(3.2, 0.5, 6.4), "dark_metal", 2.2, "lure_phone")
	g.prop("mug", Vector3(6.5, 33.6, 25.5))

	# --- Floor clutter: noisy, quiet and camo surfaces ---
	g.box("ChipBag", Vector3(20, -0.2, 18), Vector3(10, 0.5, 7), "chip_bag", &"chip_bag", &"", 0.3)
	g.box("DishTowel", Vector3(-30, -0.2, -12), Vector3(10, 0.5, 7), "cloth_red", &"cloth", &"", 0.0, false)
	g.box("Doormat", Vector3(-50, -0.2, 38), Vector3(14, 0.5, 9), "carpet", &"carpet", &"soil", 0.0, false)
	g.scent_wiper("Puddle", Vector3(-38, 0.6, -15), Vector3(6, 1.2, 5))
	g.cylinder("TrashCan", Vector3(-50, 16, 30), 7.0, 32, "metal", &"metal")
	g.sticky_trap("GlueTrap", Vector3(-46, 0.5, 18), Vector3(7, 1, 7))
	g.prop("grape", Vector3(0, 0.9, -5))
	g.prop("grape", Vector3(-22, 0.9, 37))

	# --- Light: ceiling lamp while people are in, morning sunbeam ---
	g.light_zone("CeilingLight", Vector3(25, 20, 17.5), Vector3(168, 40, 123), 2, 1,
		["breakfast", "lunch", "late_snack", "dishes", "midnight_snack", "lights_on"], [], false, 0.45)
	g.light_zone("Sunbeam", Vector3(-46, 2, 0), Vector3(26, 4, 22), 3, 2, ["sunbeam"], ["lights_out"])
	g.deco_box("Window", Vector3(-59.85, 52, 0), Vector3(0.2, 30, 24), "window", Vector3.ZERO, false)

	# --- East half: pantry, second counter, island, pet bowls, mop bucket ---
	g.box("Pantry", Vector3(72, 36, -33), Vector3(24, 68, 24), "wood", &"wood")
	g.box("PantryKick", Vector3(72, 1, -35), Vector3(24, 2, 20), "dark_wood", &"wood", &"dark_wood")
	g.deco_box("PantryDoor", Vector3(72, 36, -20.9), Vector3(22, 64, 0.3), "dark_wood")
	g.deco_box("PantryKnob", Vector3(80, 36, -20.5), Vector3(1.2, 1.2, 1.2), "metal")
	g.box("ToeKick2", Vector3(97, 2, -34.5), Vector3(26, 4, 21), "dark_wood", &"wood", &"dark_wood")
	g.box("Cabinets2", Vector3(97, 20, -33), Vector3(26, 32, 24), "wood", &"wood")
	g.box("Countertop2", Vector3(97, 37, -32.5), Vector3(27, 2, 27), "counter_stone", &"stone")
	g.hiding_spot("ToeKickGap2", Vector3(97, 1.6, -22.5), Vector3(24, 3.2, 3.0))
	g.light_zone("ToeKickShadow2", Vector3(97, 2, -22.5), Vector3(24, 4, 3.2), 0, 3)
	g.box("Toaster", Vector3(93, 43, -36), Vector3(10, 10, 7), "metal", &"metal")
	g.box("BreadBox", Vector3(104, 42, -37), Vector3(9, 8, 8), "wood", &"wood")
	g.box("Island", Vector3(60, 14, 35), Vector3(36, 28, 20), "wood", &"wood")
	g.box("IslandTop", Vector3(60, 29, 35), Vector3(40, 2, 24), "counter_stone", &"stone")
	g.light_zone("UnderIslandLip", Vector3(60, 3, 35), Vector3(40, 6, 24), 1, 2)
	for x in [48.0, 72.0]:
		g.cylinder("StoolPost", Vector3(x, 12, 52), 1.0, 24, "metal", &"metal")
		g.cylinder("StoolSeat", Vector3(x, 25, 52), 5.5, 2, "dark_wood", &"wood", &"dark_wood")
	g.cylinder("FoodBowl", Vector3(92, 1.5, 64), 5.0, 3, "metal", &"metal")
	g.cylinder("WaterBowl", Vector3(102, 1.5, 64), 5.0, 3, "metal", &"metal")
	g.water_bowl(Vector3(102, 1.5, 64), Vector3(0, 0, -1), false)
	g.deco("BowlWater", _cyl(4.4, 0.2), "water", Vector3(102, 3.05, 64))
	g.scent_wiper("BowlSplash", Vector3(100, 0.6, 56), Vector3(7, 1.2, 5))
	g.cylinder("MopBucket", Vector3(98, 6, 8), 6.0, 12, "cloth_blue", &"metal")
	g.scent_wiper("MopSpill", Vector3(88, 0.6, 10), Vector3(8, 1.2, 7))
	g.box("PlaceMat", Vector3(60, -0.2, 64), Vector3(16, 0.5, 10), "rug", &"carpet", &"", 0.0, false)
	g.deco_box("WindowEast", Vector3(109.85, 52, 30), Vector3(0.2, 30, 24), "window", Vector3.ZERO, false)
	g.light_zone("SunbeamEast", Vector3(98, 2, 30), Vector3(22, 4, 22), 3, 2, ["sunbeam"], ["lights_out"])
	g.prop("ball", Vector3(75, 1.6, 66))

	# --- Warm air for the fly: over the stove while cooking, over the toaster ---
	g.thermal("StoveHeat", Vector3(13, 56, -30), Vector3(22, 36, 20), 7.0, ["breakfast", "lunch", "late_snack", "midnight_snack"])
	g.thermal("ToasterHeat", Vector3(93, 62, -36), Vector3(12, 28, 10), 6.0, ["breakfast"])

	# --- Crumbs ---
	for p in [Vector3(30, 0.6, 30), Vector3(14, 0.6, 2), Vector3(-10, 0.6, 14), Vector3(-28, 0.6, 22),
			Vector3(-45, 0.6, -17), Vector3(-20, 0.6, -22.5), Vector3(43, 0.6, -13), Vector3(52, 0.6, 5),
			Vector3(-55, 0.6, 20), Vector3(27, 0.6, 22), Vector3(-24, 19.4, -7), Vector3(-16, 32.2, 18),
			Vector3(-2, 32.2, 8), Vector3(-28, 38.6, -27), Vector3(5, 36.6, -28),
			Vector3(75, 0.6, 10), Vector3(95, 0.6, 22), Vector3(105, 0.6, 48), Vector3(75, 0.6, 72),
			Vector3(40, 0.6, 62), Vector3(10, 0.6, 70), Vector3(-30, 0.6, 62), Vector3(-50, 0.6, 58),
			Vector3(100, 38.6, -28), Vector3(52, 30.6, 32), Vector3(68, 30.6, 40)]:
		g.crumb(p)

	# --- Bug food and crumb gems ---
	g.item("sugar_cube", Vector3(-40, 38, -24))
	g.item("cheese", Vector3(-12, 0, 18))
	g.item("kibble", Vector3(87, 0, 60))
	g.item("kibble", Vector3(95, 0, 57))
	g.item("coffee_bean", Vector3(72, 0, 12))
	g.item("honey_drop", Vector3(66, 0, -16))
	g.item("gem_amber", Vector3(0, 0, 55))
	g.item("gem_diamond", Vector3(43, 72, -30))

	# --- Secret route into the wall cavity behind the back wall ---
	g.box("CavityFloor", Vector3(44, -1, -53), Vector3(32, 2, 12), "dark_wood", &"wood", &"dark_wood")
	g.box("CavityBack", Vector3(44, 6, -59.5), Vector3(32, 14, 1), "dark_wood", &"wood")
	g.box("CavityLeft", Vector3(27.5, 6, -53), Vector3(1, 14, 12), "dark_wood", &"wood")
	g.box("CavityRight", Vector3(60.5, 6, -53), Vector3(1, 14, 12), "dark_wood", &"wood")
	g.box("CavityTop", Vector3(44, 13.5, -53), Vector3(34, 1, 14), "dark_wood", &"wood")
	g.light_zone("CavityDark", Vector3(44, 6, -53), Vector3(32, 12, 12), 0, 3, [], [], false)
	g.crumb(Vector3(44, 0.6, -53), true)
	g.passage("FridgeGap", Vector3(58.5, 1.5, -16), Vector3(56, 0.8, -53), ["cockroach"], "gap behind the fridge")
	g.passage("AirVent", Vector3(-50, 62, -44), Vector3(40, 0.8, -53), ["fly", "spider"], "air vent",
		Vector3.UP, Vector3(7, 7, 4))
	g.deco_box("VentGrille", Vector3(-50, 62, -44.8), Vector3(8, 6, 0.4), "dark_metal")
	g.passage("CavityExit", Vector3(31, 1.5, -53), Vector3(56, 0.8, -10), [], "crack back to the kitchen")

	# --- Cover: places to duck into and things to hide behind ---
	g.shelter("PaperCup", Vector3(-40, 0, 8), Vector3(6.5, 3.4, 3.8), "plastic_white", true, "paper cup", "cover_paper_cup")
	g.shelter("Sneaker", Vector3(-36, 0, 42), Vector3(10, 4.2, 4.6), "cloth_blue", true, "old sneaker", "cover_sneaker", &"cloth")
	g.shelter("GroceryBag", Vector3(54, 0, 16), Vector3(6.5, 5.0, 9.0), "paper", false, "grocery bag", "cover_grocery_bag")
	g.cover_block("MailStack", Vector3(-15, 0, -16), Vector3(8, 2.6, 4.5), "paper", "stack of mail", "cover_mail_stack", &"paper")
	g.shelter("FoldedTowel", Vector3(-50, 38, -38), Vector3(8, 2.6, 6), "cloth_red", true, "folded towel", "cover_folded_towel", &"cloth")
	g.shelter("NapkinTent", Vector3(-20, 31.5, 8), Vector3(6, 2.4, 5), "paper", false, "napkin", "cover_napkin")
	g.shelter("RecycleBox", Vector3(102, 0, -6), Vector3(10, 8, 12), "paper", false, "recycling box", "cover_cardboard_box")
	g.cover_block("FlourSack", Vector3(30, 0, 72), Vector3(12, 6, 8), "paper", "flour sack", "cover_flour_sack", &"cloth")

	# --- Model slots for the furniture ---
	# The fridge model is open at the front (its door is the swinging one) and
	# stretched to fill the fridge's box exactly (things sit on top of it).
	var fridge_skin := g.skin_region("Fridge", "kitchen_fridge", Vector3(43, 36, -30), Vector3(28, 72, 26), ["Fridge"], 0.0)
	fridge_skin.stretch = true
	# Food on the shelves, seen whenever the door swings open.
	var food := Node3D.new()
	food.name = "FridgeFood"
	g.skins.add_child(food)
	for shelf: Array in [[30.0, 0.0, -1.0, 7.6], [38.9, 180.0, 0.5, 7.4], [47.4, 15.0, -0.5, 6.8]]:
		var hgt: float = shelf[3]
		var f := g.skin("FridgeFood", "fridge_groceries", Vector3(42.6 + float(shelf[2]), float(shelf[0]) + hgt * 0.5, -26.5),
			Vector3(hgt * 2.6, hgt, hgt * 1.9), [], float(shelf[1]))
		g.skins.remove_child(f)
		food.add_child(f)
	var fridge_door := g.geo.get_node("FridgeDoor") as SwingDoor
	fridge_door.reveal_path = fridge_door.get_path_to(food)
	g.skin_region("Stove", "kitchen_stove", Vector3(13, 18.2, -33), Vector3(26, 36.4, 24), ["Stove", "Burner"])
	g.skin_region("Pan", "frying_pan", Vector3(13, 58, -35), Vector3(12, 2, 24), ["Pan"])
	g.skin_region("Pot", "cooking_pot", Vector3(14, 5, -11), Vector3(9, 10, 9), ["Pot"])
	g.skin_region("Table", "kitchen_table", Vector3(-12, 15.75, 14), Vector3(40, 31.5, 28), ["TableTop", "TableLeg"])
	g.skin_region("ChairA", "kitchen_chair", Vector3(-24, 19, -7), Vector3(14, 38, 14), ["Chair"], 180.0)
	g.skin_region("ChairB", "kitchen_chair", Vector3(0, 19, 35), Vector3(14, 38, 14), ["Chair"], 0.0)
	g.skin_region("TrashCan", "kitchen_trash_can", Vector3(-50, 16, 30), Vector3(14, 32, 14), ["TrashCan"])
	g.skin_region("Island", "kitchen_island", Vector3(60, 15, 35), Vector3(40, 30, 24), ["Island"])
	g.skin_region("Toaster", "toaster", Vector3(93, 43, -36), Vector3(10, 10, 7), ["Toaster"])
	g.skin_region("PetBowls", "pet_bowl", Vector3(92, 1.5, 64), Vector3(10, 3, 10), ["FoodBowl"])
	g.skin_region("MopBucket", "mop_bucket", Vector3(98, 6, 8), Vector3(12, 12, 12), ["MopBucket"])

	# --- Spawn and escape ---
	g.spawn(Vector3(84, 0.8, 74), PI * 0.5)
	g.goal(Vector3(-58, 0, 40), "crack under the back door")
	g.deco_box("DoorCrack", Vector3(-59.85, 2.5, 40), Vector3(0.2, 5, 8), "hole", Vector3.ZERO, false)

	# --- Power-ups: ten tucked into the hidden corners ---
	g.item("power_turbo", Vector3(38, 0, -32))  # under the fridge
	g.item("power_shrink", Vector3(-48, 0, -22.5))  # in the toe-kick gap under the counter
	g.item("power_radar", Vector3(104, 0, -22.5))  # in the other toe-kick gap
	g.item("power_double", Vector3(-40, 0, 8))  # inside the paper cup
	g.item("power_spring", Vector3(-36, 0, 42))  # inside the sneaker
	g.item("power_turbo", Vector3(102, 0, -6))  # inside the recycling box
	g.item("power_double", Vector3(34, 0, -53))  # in the wall cavity (secret route)
	g.item("power_spring", Vector3(24, 0, 78))  # behind the flour sack
	g.item("power_radar", Vector3(-56, 0, 76))  # the far corner by the back door
	g.item("power_shrink", Vector3(-50, 38.15, -38))  # inside the folded towel on the counter

	# --- Climbing: a grocery tower and springy sponges ---
	# A spiral staircase of boxes and tins up to a summit by the east window.
	var tower := g.junk_tower("GroceryTower", Vector3(100, 0, 36), "groceries", 7, 4.5, 7.0, PI * 0.5)
	g.item("treasure_button", tower[1])
	g.item("power_spring", tower[3])
	g.item("treasure_teaspoon", tower[5])
	g.item("gem_amber", tower[6])
	g.item("treasure_thimble", tower[7])
	# Sponges fling you up: floor -> counter, counter -> top of the fridge,
	# and a pot holder by the island -> the island top.
	g.bounce_pad("FloorSponge", Vector3(-6, 0, -8), Vector3(6, 1.6, 4.5), "sponge", Vector3(-20, 38, -34), 14.0)
	g.bounce_pad("CounterSponge", Vector3(-3, 38, -37), Vector3(6, 1.6, 4.5), "sponge", Vector3(38, 72, -28), 5.0)
	g.bounce_pad("PotHolder", Vector3(60, 0, 57), Vector3(6, 1.4, 6), "cushion", Vector3(60, 30, 40), 5.0)
	# Treasures, gems and more power-ups up high.
	g.item("treasure_ring", Vector3(50, 72, -36))  # top of the fridge
	g.item("treasure_bead", Vector3(-26, 31.5, 22))  # on the table
	g.item("treasure_sea_glass", Vector3(-50, 32, 30))  # on the trash can lid
	g.item("gem_sapphire", Vector3(72, 70, -33))  # top of the pantry
	g.item("gem_emerald", Vector3(104, 46, -37))  # on the bread box
	g.item("power_turbo", Vector3(34, 72, -38))  # top of the fridge
	g.item("power_turbo", Vector3(70, 30, 30))  # island top
	g.item("power_radar", Vector3(-55, 38, -30))  # back of the counter
	g.item("power_double", Vector3(-2, 31.5, 24))  # on the table
	g.item("power_shrink", Vector3(92, 48, -36))  # on the toaster

	# --- Threats ---
	# The cook: cooks at the stove and does the dishes with their back to the
	# room, snacks at the table; cooking and snacking drop crumbs.
	var human := g.human("res://scenes/threats/human.tscn",
		[Vector3(40, 0, 8), Vector3(43, 0, -4), Vector3(5, 0, -17.5), Vector3(-38, 0, -16), Vector3(-56, 0, -16),
			Vector3(-56, 0, 5), Vector3(-20, 0, 34), Vector3(32, 0, 58), Vector3(82, 0, 62), Vector3(90, 0, 18),
			Vector3(65, 0, 8)],
		["breakfast", "dishes", "cleaning", "lunch", "late_snack", "midnight_snack"],
		{"exit_point": Vector3(-52, 0, 40), "activities": {
			1: {"kind": &"fridge", "time": 6.0, "face": Vector3(43, 40, -30)},
			2: {"kind": &"cook", "time": 10.0, "face": Vector3(7, 36, -33)},
			3: {"kind": &"dishes", "time": 8.0, "face": Vector3(-35, 38, -33)},
			6: {"kind": &"snack", "time": 7.0, "face": Vector3(-20, 30, 14)},
			7: {"kind": &"sweep", "time": 9.0, "face": Vector3(32, 0, 40)},
		}})
	# A playful puppy: plays with its ball, zooms around, naps after lunch.
	g.pet("res://scenes/threats/puppy.tscn", Vector3(-30, 0.5, 50),
		[Vector3(-30, 0, 50), Vector3(15, 0, 60), Vector3(60, 0, 68), Vector3(95, 0, 45), Vector3(90, 0, 30),
			Vector3(35, 0, 12)],
		["nap"])
	var vac := g.vacuum(Vector3(30, 0.2, 20), Vector3(-55, 0, -18), Vector3(105, 0, 76), ["cleaning"])
	g.escalation()
	g.boss(BossDirector.Kind.CLEANING_DAY, "Cleaning Day",
		"The robot vacuum hunts your noise - then the spray comes out. Run for the door!",
		{"vacuum_path": vac, "human_path": human})
	g.finalize("res://scripts/world/level.gd", &"kitchen", "res://scenes/levels/kitchen.tscn", tree)


static func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c


static func _chair(g: LevelGeo, base: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	g.box("ChairSeat", base + Vector3(0, 18, 0), Vector3(14, 1.5, 14), "dark_wood", &"wood", &"dark_wood", yaw)
	g.box("ChairBack", base + b * Vector3(0, 28, -6.5), Vector3(14, 20, 1.5), "dark_wood", &"wood", &"dark_wood", yaw)
	for x in [-6.0, 6.0]:
		for z in [-6.0, 6.0]:
			g.box("ChairLeg", base + b * Vector3(x, 8.6, z), Vector3(1.2, 17.2, 1.2), "dark_wood", &"wood", &"dark_wood", yaw)
