class_name KitchenLayout
## The Kitchen: 120 x 90 floor (1 unit ~ 2.5 cm), counters + sink + stove on
## the back wall, fridge in the back-right corner, table and chairs in the
## middle. Secret route: the gap beside the fridge (roach) or the high air
## vent (fly/spider) leads into a wall cavity with the Golden Crumb.


static func build(tree: SceneTree) -> void:
	var g := LevelGeo.new("Kitchen")
	g.environment(Color(0.1, 0.085, 0.07), Color(0.95, 0.88, 0.75), 0.8)
	g.sun(Vector3(-58, 35, 0), 0.9)
	g.room(Vector3(120, 100, 90), "tile", &"tile", "wall_paint", true)

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
		g.prop("cereal_box", Vector3(-14 + i * 4.0, 42.6, -26), Vector3(0, 0, 0))
	g.lure("Spoon", LureProp.Kind.SPOON, Vector3(-46, 38.3, -27), Vector3(1.2, 0.4, 7), "metal", 2.6)

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
	g.deco_box("FridgeHandle", Vector3(32, 45, -16.6), Vector3(1.5, 30, 1.2), "metal")
	g.hiding_spot("UnderFridge", Vector3(43, 1, -30), Vector3(24, 2, 22))
	g.light_zone("UnderFridgeShadow", Vector3(43, 1, -30), Vector3(26, 2, 24), 0, 3)
	g.light_zone("FridgeLight", Vector3(43, 6, -9), Vector3(30, 12, 16), 3, 4, ["fridge_open"], [], true, 3.0)
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
	g.lure("Phone", LureProp.Kind.PHONE, Vector3(-4, 31.75, 20), Vector3(3.2, 0.5, 6.4), "dark_metal", 2.2)
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
	g.light_zone("CeilingLight", Vector3(0, 20, 0), Vector3(118, 40, 88), 2, 1,
		["breakfast", "lunch", "late_snack", "dishes", "midnight_snack", "lights_on"], [], false, 0.8)
	g.light_zone("Sunbeam", Vector3(-46, 2, 0), Vector3(26, 4, 22), 3, 2, ["sunbeam"], ["lights_out"])
	g.deco_box("Window", Vector3(-59.85, 52, 0), Vector3(0.2, 30, 24), "window", Vector3.ZERO, false)

	# --- Crumbs ---
	for p in [Vector3(30, 0.6, 30), Vector3(14, 0.6, 2), Vector3(-10, 0.6, 14), Vector3(-28, 0.6, 22),
			Vector3(-45, 0.6, -17), Vector3(-20, 0.6, -22.5), Vector3(43, 0.6, -13), Vector3(52, 0.6, 5),
			Vector3(-55, 0.6, 20), Vector3(27, 0.6, 22), Vector3(-24, 19.4, -7), Vector3(-16, 32.2, 18),
			Vector3(-2, 32.2, 8), Vector3(-28, 38.6, -27), Vector3(5, 36.6, -28)]:
		g.crumb(p)

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

	# --- Spawn and escape ---
	g.spawn(Vector3(50, 0.8, 34), PI * 0.5)
	g.goal(Vector3(-58, 0, 40), "crack under the back door")
	g.deco_box("DoorCrack", Vector3(-59.85, 2.5, 40), Vector3(0.2, 5, 8), "hole", Vector3.ZERO, false)

	# --- Threats ---
	var human := g.human("res://scenes/threats/human.tscn",
		[Vector3(40, 0, 8), Vector3(22, 0, -1), Vector3(12, 0, 30), Vector3(40, 0, 38)],
		["breakfast", "dishes", "cleaning", "lunch", "late_snack", "midnight_snack"])
	var vac := g.vacuum(Vector3(30, 0.2, 20), Vector3(-55, 0, -18), Vector3(57, 0, 42), ["cleaning"])
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
