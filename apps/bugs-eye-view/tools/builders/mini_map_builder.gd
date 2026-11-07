class_name MiniMapBuilder
## Builds the mini maps behind each room (see MiniMaps): under the sink,
## inside the walls, the basement, the attic and the hidden crawl spaces.
## Each map is laid out from its theme with a seeded random layout, so the
## ten maps of a room differ, and gets harder with its number: more traps,
## drafts and webs, and a cat or the robot vacuum on some.
##   godot --headless --path . res://tools/build_all.tscn -- --force --only=minis

const SCRIPT := "res://scripts/world/level.gd"


static func build_all(tree: SceneTree, force: bool) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/levels/minis"))
	for id in MiniMaps.all_ids():
		var path := "res://scenes/levels/minis/%s.tscn" % id
		if not force and ResourceLoader.exists(path):
			continue
		build(MiniMaps.entry(id), tree)


static func build(e: Dictionary, tree: SceneTree) -> void:
	var id: StringName = e["id"]
	var g := LevelGeo.new(String(id).to_pascal_case())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(id))
	var m := MiniMap.new(g, rng, e)
	match String(e["theme"]):
		"sink":
			_sink(m)
		"walls":
			_walls(m)
		"basement":
			_basement(m)
		"attic":
			_attic(m)
		_:
			_crawl(m)
	m.finish()
	g.finalize(SCRIPT, id, "res://scenes/levels/minis/%s.tscn" % id, tree)


# --- Under the sink ------------------------------------------------------------

## Inside the sink cabinet: the drain's U-bend and supply lines, bottles of
## cleaner, a bucket and a sponge pack; light through the gap in the doors.
static func _sink(m: MiniMap) -> void:
	var g := m.g
	var rng := m.rng
	g.environment(Color(0.03, 0.03, 0.035), Color(0.6, 0.65, 0.75), 0.55)
	g.sun(Vector3(-60, 30, 0), 0.25)
	m.bounds(70, 40, 44)
	m.start(Vector3(-26, 0.4, 10), 0.0)
	m.exit_floor(Vector3(30, 0, -18), "crack behind the pipes")
	g.room(Vector3(70, 40, 44), "dark_wood", &"wood", "wood", true)
	g.deco_box("DoorGap", Vector3(0, 20, 21.95), Vector3(1.2, 36, 0.1), "window", Vector3.ZERO, false)
	g.light_zone("CabinetDark", Vector3(0, 20, 0), Vector3(70, 40, 44), 0, 1)
	g.light_zone("DoorGapLight", Vector3(0, 8, 16), Vector3(12, 16, 12), 2, 2)
	# The drain: tailpiece, U-bend, trap arm into the back wall.
	var px := rng.randf_range(-10.0, 10.0)
	m.set_summit(Vector3(px + 2.4, 35.5, -4), "gap around the drain")
	g.pipe("Tailpiece", Vector3(px, 40, -4), Vector3(px, 12, -4), 1.6, "plastic_white", &"plastic")
	g.pipe("Bend", Vector3(px, 12, -2.5), Vector3(px, 12, -11.5), 1.6, "plastic_white", &"plastic")
	g.pipe("Riser", Vector3(px, 10.5, -10), Vector3(px, 19, -10), 1.6, "plastic_white", &"plastic")
	g.pipe("TrapArm", Vector3(px, 18, -10), Vector3(px, 18, -22.5), 1.6, "plastic_white", &"plastic")
	m.block(Vector3(px, 0, -7), 6, 14)
	m.spot(Vector3(px, 13.7, -7))
	m.spot(Vector3(px, 19.7, -13.5))
	m.high_spot(Vector3(px, 19.7, -17.5))
	# Hot and cold supply lines with shut-off valves.
	for sx in [-14.0, 14.0]:
		var vx: float = px + sx
		if absf(vx) < 32.0:
			g.pipe("Supply", Vector3(vx, 6, -21), Vector3(vx, 40, -21), 0.6, "copper")
			g.cylinder("Valve", Vector3(vx, 8, -20), 1.4, 2.5, "metal", &"metal")
			m.spot(Vector3(vx, 9.3, -20))
	g.scent_wiper("DripPuddle", Vector3(px, 0.6, -2), Vector3(7, 1.2, 6))
	g.deco_box("Puddle", Vector3(px, 0.03, -2), Vector3(7, 0.05, 6), "water", Vector3.ZERO, false)
	# Bottles of cleaner, a bucket, a sponge pack, a box of bin bags.
	var looks := ["label_red", "label_blue", "plastic_white", "chip_bag", "leaf_green"]
	for i in 5 + rng.randi() % 3:
		var r := rng.randf_range(2.0, 3.0)
		var h := rng.randf_range(7.0, 16.0)
		var p := m.place(r * 2.0 + 1.0, r * 2.0 + 1.0)
		if p == Vector3.INF:
			continue
		g.cylinder("Bottle", p + Vector3.UP * h * 0.5, r, h, looks[i % looks.size()], &"plastic")
		g.cylinder("Cap", p + Vector3.UP * (h + 0.6), r * 0.45, 1.2, "plastic_white", &"plastic", &"", false)
		m.spot(p + Vector3.UP * h)
		if h > 12.0:
			m.high_spot(p + Vector3.UP * h)
	var bp := m.place(11, 11)
	if bp != Vector3.INF:
		g.cylinder("Bucket", bp + Vector3.UP * 4.5, 5.0, 9.0, "metal", &"metal")
		m.spot(bp + Vector3.UP * 9.0)
	var sp := m.place(9, 6)
	if sp != Vector3.INF:
		g.box("SpongePack", sp + Vector3.UP * 1.5, Vector3(8, 3, 5), "sponge", &"cloth")
		m.spot(sp + Vector3.UP * 3.0)
	var cp := m.place(11, 7)
	if cp != Vector3.INF:
		g.cover_block("BinBags", cp, Vector3(10, 6, 6), "cardboard", "box of bin bags", "", &"paper")
		m.spot(cp + Vector3.UP * 6.0)
	m.hazards(0.0)


# --- Inside the walls ------------------------------------------------------------

## A cut-away wall cavity: studs with drilled holes, fire blocks to get round,
## a copper pipe and wires, pink insulation to hide in, drafts and cobwebs.
## Seen from the room side (the open front); pushing forward climbs the back.
static func _walls(m: MiniMap) -> void:
	var g := m.g
	var rng := m.rng
	var w := 84.0
	var h := 72.0
	var d := 20.0
	g.environment(Color(0.05, 0.045, 0.04), Color(0.75, 0.65, 0.55), 0.6)
	g.sun(Vector3(-50, 25, 0), 0.35)
	m.bounds(w, h, d)
	m.start(Vector3(-w * 0.5 + 5.0, 0.4, 2.0), 0.0)
	m.exit_floor(Vector3(w * 0.5 - 4.0, 0, -d * 0.5 + 3.0), "hole in the bottom plate")
	m.set_summit(Vector3(w * 0.5 - 4.0, h - 4.0, -d * 0.5 + 3.0), "gap in the top plate")
	g.box("BottomPlate", Vector3(0, -1, 0), Vector3(w + 4, 2, d + 4), "wood", &"wood")
	g.box("Drywall", Vector3(0, h * 0.5, -d * 0.5 - 1), Vector3(w + 4, h, 2), "drywall", &"default", &"", 0.0, false)
	g.box("EndLeft", Vector3(-w * 0.5 - 1, h * 0.5, 0), Vector3(2, h, d + 4), "wood", &"wood")
	g.box("EndRight", Vector3(w * 0.5 + 1, h * 0.5, 0), Vector3(2, h, d + 4), "wood", &"wood")
	g.box("TopPlate", Vector3(0, h + 1, 0), Vector3(w + 4, 2, d + 4), "wood", &"wood", &"", 0.0, false)
	g.glass_wall("OpenSide", Vector3(0, h * 0.5, d * 0.5 + 1), Vector3(w + 4, h, 2))
	g.light_zone("CavityDark", Vector3(0, h * 0.5, 0), Vector3(w, h, d), 1, 1)
	var studs := [-28.0, -14.0, 0.0, 14.0, 28.0]
	var depth := d - 3.0
	var zc := -d * 0.5 + depth * 0.5
	for i in studs.size():
		var sx: float = studs[i]
		# A drilled hole at some height splits the stud in two.
		var hole := rng.randf_range(14.0, h - 14.0)
		g.box("Stud", Vector3(sx, (hole - 2.0) * 0.5, zc), Vector3(1.5, hole - 2.0, depth), "wood", &"wood")
		g.box("Stud", Vector3(sx, (hole + 2.0 + h) * 0.5, zc), Vector3(1.5, h - hole - 2.0, depth), "wood", &"wood")
		# Nail plates and brackets: little ledges up the studs.
		for j in 3:
			var ly := rng.randf_range(8.0, h - 8.0)
			var side: float = 1.0 if j % 2 == 0 else -1.0
			g.box("Bracket", Vector3(sx + side * 1.9, ly, -d * 0.5 + 2.5), Vector3(2.4, 0.5, 4.0), "metal", &"metal")
			m.spot(Vector3(sx + side * 1.9, ly + 0.3, -d * 0.5 + 2.5))
			if ly > h * 0.6:
				m.high_spot(Vector3(sx + side * 1.9, ly + 0.3, -d * 0.5 + 2.5))
	# Fire blocks across each bay, leaving a gap at one end to climb past.
	var edges := [-w * 0.5] + studs + [w * 0.5]
	for b in edges.size() - 1:
		var x0: float = edges[b] + 0.75
		var x1: float = edges[b + 1] - 0.75
		var fy := rng.randf_range(22.0, 48.0)
		var gap_left := b % 2 == 0
		var bw := (x1 - x0) - 5.0
		var bx := (x0 + 5.0 + bw * 0.5) if gap_left else (x0 + bw * 0.5)
		g.box("FireBlock", Vector3(bx, fy, zc), Vector3(bw, 1.5, depth), "wood", &"wood")
		m.spot(Vector3(bx, fy + 0.75, zc))
		m.high_spot(Vector3(bx, fy + 0.75, zc + 2.0))
		m.spot(Vector3((x0 + x1) * 0.5, 0.0, rng.randf_range(-5.0, 3.0)))
	# A copper pipe up one bay, wires across all of them.
	var pipe_bay := rng.randi_range(1, edges.size() - 3)
	var pxp: float = (edges[pipe_bay] + edges[pipe_bay + 1]) * 0.5
	g.pipe("CopperPipe", Vector3(pxp, 0, -d * 0.5 + 2.5), Vector3(pxp, h, -d * 0.5 + 2.5), 1.0, "copper")
	for wy in [rng.randf_range(16.0, 30.0), rng.randf_range(40.0, 60.0)]:
		g.pipe("Wire", Vector3(-w * 0.5, wy, -d * 0.5 + 4.0), Vector3(w * 0.5, wy, -d * 0.5 + 4.0), 0.35, "dark_metal", &"plastic")
	g.box("OutletBox", Vector3(studs[1] + 3.0, 18, -d * 0.5 + 1.5), Vector3(4, 6, 3), "plastic_white", &"plastic")
	m.spot(Vector3(studs[1] + 3.0, 21.0, -d * 0.5 + 1.5))
	# Pink insulation in a bay or two: hide in it.
	for b in [rng.randi_range(0, 2), rng.randi_range(3, edges.size() - 2)]:
		var x0b: float = edges[b] + 0.75
		var x1b: float = edges[b + 1] - 0.75
		var ih := rng.randf_range(10.0, 16.0)
		g.deco_box("Insulation", Vector3((x0b + x1b) * 0.5, ih * 0.5, -d * 0.5 + 5.0), Vector3(x1b - x0b, ih, 9.5), "insulation")
		g.hiding_spot("InInsulation", Vector3((x0b + x1b) * 0.5, ih * 0.5, -d * 0.5 + 5.0), Vector3(x1b - x0b, ih, 9.5), false, [], "Hidden in the insulation")
		g.light_zone("InsulationShade", Vector3((x0b + x1b) * 0.5, ih * 0.5, -d * 0.5 + 5.0), Vector3(x1b - x0b, ih, 9.5), 0, 3)
	# Drafts whistle up a bay; cobwebs in the corners.
	if m.level >= 3:
		var wb := rng.randi_range(1, edges.size() - 2)
		var wx: float = (edges[wb] + edges[wb + 1]) * 0.5
		g.wind("Draft", Vector3(wx, h * 0.5, zc), Vector3(10, h, depth), Vector3(0, 1, 0) if wb % 2 == 0 else Vector3(0, -1, 0), 22.0, [])
	for i in mini(int(m.level / 2.0), 3):
		var cb := rng.randi_range(0, edges.size() - 2)
		var cx: float = (edges[cb] + edges[cb + 1]) * 0.5
		g.sticky_trap("Cobweb", Vector3(cx, rng.randf_range(30.0, h - 6.0), -d * 0.5 + 1.0), Vector3(8, 6, 2), true)
	# Mouse traps along the bottom plate.
	for i in 1 + int(m.level / 3.0):
		var tb := rng.randi_range(1, edges.size() - 2)
		var tx: float = (edges[tb] + edges[tb + 1]) * 0.5 + rng.randf_range(-2.0, 2.0)
		g.mouse_trap(Vector3(tx, 0, -2.0), PI * 0.5)


# --- The basement ----------------------------------------------------------------

## Concrete and clutter: stairs up to the door, washer and dryer, the water
## heater and furnace, shelving with paint cans, box stacks and a workbench.
static func _basement(m: MiniMap) -> void:
	var g := m.g
	var rng := m.rng
	g.environment(Color(0.05, 0.05, 0.055), Color(0.7, 0.72, 0.8), 0.6)
	g.sun(Vector3(-55, 40, 0), 0.35)
	m.bounds(100, 40, 70)
	m.start(Vector3(-20, 0.4, 28), PI * 0.15)
	m.exit_floor(Vector3(-43, 38, -27), "gap under the basement door")
	m.summit_label = "vent in the ceiling"
	g.room(Vector3(100, 40, 70), "concrete", &"stone", "concrete", true)
	g.light_zone("BasementDim", Vector3(0, 20, 0), Vector3(100, 40, 70), 1, 1)
	g.light_zone("Bulb", Vector3(5, 10, 5), Vector3(36, 20, 30), 2, 2)
	g.deco("Bulb", _sphere(1.2), "lamp", Vector3(5, 37, 5))
	# Stairs up the left wall to the door at the top.
	g.ramp("Stairs", Vector3(-43, 0, 30), Vector3(-43, 38, -14), 10.0, "wood", &"wood")
	g.box("Landing", Vector3(-43, 37, -24), Vector3(10, 2, 20), "wood", &"wood")
	g.deco_box("Door", Vector3(-49.9, 52, -24), Vector3(0.2, 26, 12), "dark_wood", Vector3.ZERO, false)
	g.hiding_spot("UnderStairs", Vector3(-43, 3, 22), Vector3(9, 6, 12), false, [], "Hidden under the stairs")
	m.block(Vector3(-43, 0, 8), 12, 64)
	m.spot(Vector3(-43, 19.5, 8))
	# Washer and dryer on the back wall (the washer rumbles).
	for i in 2:
		var wx := 8.0 + i * 25.0
		g.box("Washer" if i == 0 else "Dryer", Vector3(wx, 14, -22), Vector3(22, 28, 22), "fridge_white", &"metal")
		m.block(Vector3(wx, 0, -22), 24, 24)
		m.spot(Vector3(wx + rng.randf_range(-6.0, 6.0), 28.0, -22))
	g.ambient("Washer", Vector3(8, 10, -22), 40.0, 0.7, "dishwasher", [], [], -10.0)
	# Water heater and furnace in the far corner.
	g.cylinder("WaterHeater", Vector3(42, 17, -26), 7.0, 34.0, "metal", &"metal")
	g.thermal("HeaterWarmth", Vector3(42, 38, -26), Vector3(12, 6, 12), 5.0)
	m.block(Vector3(42, 0, -26), 16, 16)
	m.high_spot(Vector3(42, 34.0, -26))
	g.box("Furnace", Vector3(40, 15, 4), Vector3(16, 30, 18), "dark_metal", &"metal")
	g.pipe("Duct", Vector3(40, 30, 4), Vector3(40, 40, 4), 3.0, "metal")
	m.block(Vector3(40, 0, 4), 18, 20)
	m.spot(Vector3(36, 30.0, 4))
	# A shelving unit or two, with paint cans on the shelves.
	for s in 2:
		var sp := m.place(30, 12)
		if sp == Vector3.INF:
			continue
		_shelves(m, sp, 28.0, 10.0, [10.0, 20.0, 30.0])
	# Box stacks and a workbench.
	for i in 4 + rng.randi() % 3:
		var bw := rng.randf_range(7.0, 11.0)
		var bp := m.place(bw + 1.0, bw + 1.0)
		if bp == Vector3.INF:
			continue
		var stack := rng.randi_range(1, 3)
		for k in stack:
			g.box("StorageBox", bp + Vector3(rng.randf_range(-0.6, 0.6), 3.5 + k * 7.0, rng.randf_range(-0.6, 0.6)), Vector3(bw, 7, bw), "cardboard", &"paper")
		m.spot(bp + Vector3.UP * stack * 7.0)
	var wb := m.place(30, 13)
	if wb != Vector3.INF:
		g.box("BenchTop", wb + Vector3.UP * 18, Vector3(28, 2, 11), "wood", &"wood")
		for lx in [-12.5, 12.5]:
			for lz in [-4.5, 4.5]:
				g.box("BenchLeg", wb + Vector3(lx, 8.5, lz), Vector3(1.5, 17, 1.5), "dark_wood", &"wood")
		m.spot(wb + Vector3(rng.randf_range(-10.0, 10.0), 19.0, 0))
	m.hazards(0.0)
	m.threat(Vector3(10, 0.5, 20))


static func _shelves(m: MiniMap, base: Vector3, w: float, d: float, levels: Array) -> void:
	var g := m.g
	var top: float = levels[levels.size() - 1]
	for lx in [-w * 0.5 + 0.6, w * 0.5 - 0.6]:
		for lz in [-d * 0.5 + 0.6, d * 0.5 - 0.6]:
			g.box("ShelfPost", base + Vector3(lx, (top + 1.0) * 0.5, lz), Vector3(1.2, top + 1.0, 1.2), "dark_metal", &"metal")
	for y: float in levels:
		g.box("Shelf", base + Vector3(0, y, 0), Vector3(w, 1.0, d), "wood", &"wood")
		var cx := m.rng.randf_range(-w * 0.3, w * 0.3)
		g.cylinder("PaintCan", base + Vector3(cx, y + 3.0, 0), 2.5, 5.0, ["label_red", "label_blue", "metal"][m.rng.randi() % 3], &"metal")
		m.spot(base + Vector3(cx + (6.0 if cx < 0.0 else -6.0), y + 0.5, 0))
		if y >= top:
			m.high_spot(base + Vector3(cx, y + 5.5, 0))


# --- The attic ---------------------------------------------------------------------

## Under the sloping roof: boxes, an old trunk, suitcases, a rolled rug and a
## lamp; light from the gable window, an attic fan on the harder ones.
static func _attic(m: MiniMap) -> void:
	var g := m.g
	var rng := m.rng
	g.environment(Color(0.06, 0.05, 0.04), Color(0.85, 0.75, 0.6), 0.6)
	g.sun(Vector3(-40, 60, 0), 0.4, Color(1.0, 0.85, 0.65))
	m.bounds(100, 40, 60)
	m.start(Vector3(36, 0.4, 8), PI * 0.5)
	m.exit_floor(Vector3(-40, 0, 6.5), "gap around the attic hatch")
	m.set_summit(Vector3(10, 38, 0), "ridge vent")
	g.box("Floor", Vector3(0, -1, 0), Vector3(104, 2, 64), "wood", &"wood")
	for side in [-1.0, 1.0]:
		g.box("Eave", Vector3(0, 3, side * 31), Vector3(104, 6, 2), "dark_wood", &"wood")
		g.ramp("Roof", Vector3(0, 6, side * 30), Vector3(0, 40, 0), 104.0, "dark_wood", &"wood")
	g.box("GableLeft", Vector3(-51, 20, 0), Vector3(2, 40, 64), "wood", &"wood", &"", 0.0, false)
	g.box("GableRight", Vector3(51, 20, 0), Vector3(2, 40, 64), "wood", &"wood", &"", 0.0, false)
	for i in 9:
		var rx := -40.0 + i * 10.0
		g.deco_box("Rafter", Vector3(rx, 22, -15), Vector3(1.4, 1.4, 44), "wood", Vector3(deg_to_rad(-48.6), 0, 0))
		g.deco_box("Rafter", Vector3(rx, 22, 15), Vector3(1.4, 1.4, 44), "wood", Vector3(deg_to_rad(48.6), 0, 0))
	g.deco_box("GableWindow", Vector3(49.9, 20, 0), Vector3(0.2, 10, 8), "window", Vector3.ZERO, false)
	g.light_zone("AtticDim", Vector3(0, 20, 0), Vector3(100, 40, 60), 1, 1)
	g.light_zone("WindowLight", Vector3(38, 6, 0), Vector3(22, 12, 14), 3, 2)
	# Insulation between the floor joists (soft and quiet).
	for i in 4:
		var iz := -18.0 + i * 12.0
		g.box("Insulation", Vector3(rng.randf_range(-20.0, 20.0), -0.15, iz), Vector3(30, 0.6, 6), "insulation", &"carpet", &"", 0.0, false)
	m.keep_in(-44.0, 44.0, -18.0, 18.0)
	# Boxes, the trunk, suitcases, a rolled rug, a lamp.
	for i in 5 + rng.randi() % 3:
		var bw := rng.randf_range(7.0, 11.0)
		var bp := m.place(bw + 1.0, bw + 1.0)
		if bp == Vector3.INF:
			continue
		var stack := rng.randi_range(1, 3)
		for k in stack:
			g.box("AtticBox", bp + Vector3(rng.randf_range(-0.5, 0.5), 3.5 + k * 7.0, rng.randf_range(-0.5, 0.5)), Vector3(bw, 7, bw), "cardboard", &"paper")
		m.spot(bp + Vector3.UP * stack * 7.0)
		if stack >= 3:
			m.high_spot(bp + Vector3.UP * stack * 7.0)
	var tp := m.place(18, 11)
	if tp != Vector3.INF:
		g.box("Trunk", tp + Vector3.UP * 5.0, Vector3(16, 10, 9), "dark_wood", &"wood")
		for bx in [-5.0, 5.0]:
			g.deco_box("TrunkBand", tp + Vector3(bx, 5.0, 0), Vector3(1.0, 10.2, 9.2), "brass")
		m.spot(tp + Vector3.UP * 10.0)
	for i in 2:
		var sp := m.place(12, 5)
		if sp != Vector3.INF:
			g.box("Suitcase", sp + Vector3.UP * 4.0, Vector3(11, 8, 4), "shoe", &"cloth")
			m.spot(sp + Vector3.UP * 8.0)
	var rp := m.place(26, 7)
	if rp != Vector3.INF:
		g.pipe("RolledRug", rp + Vector3(-12, 3, 0), rp + Vector3(12, 3, 0), 3.0, "rug", &"carpet")
		m.spot(rp + Vector3(rng.randf_range(-8.0, 8.0), 6.2, 0))
	g.box("Hatch", Vector3(-40, 0.05, 0), Vector3(10, 0.2, 10), "dark_wood", &"wood", &"", 0.0, false)
	if m.level >= 4:
		g.wind("AtticFan", Vector3(-30, 10, 0), Vector3(40, 18, 30), Vector3(1, 0, 0), 18.0, [])
		g.deco("FanBlades", _cyl(6.0, 0.6), "metal", Vector3(-50.5, 18, 0), Vector3(0, 0, PI * 0.5))
	m.hazards(0.0)
	m.threat(Vector3(20, 0.5, 10))


# --- The crawl space --------------------------------------------------------------

## Low and dark under the floor: dirt, concrete piers, ducts and pipes,
## cobwebs - and gem shards everywhere, with a slow bug-bomb fog rolling in.
static func _crawl(m: MiniMap) -> void:
	var g := m.g
	var rng := m.rng
	g.environment(Color(0.02, 0.02, 0.02), Color(0.55, 0.55, 0.6), 0.45)
	g.sun(Vector3(-70, 20, 0), 0.2)
	m.bounds(110, 12, 80)
	m.start(Vector3(-50, 0.4, 0), -PI * 0.5)
	m.exit_floor(Vector3(52, 0, 0), "vent to the garden")
	g.room(Vector3(110, 12, 80), "soil", &"soil", "concrete", true)
	g.light_zone("CrawlDark", Vector3(0, 6, 0), Vector3(110, 12, 80), 0, 1)
	g.light_zone("VentLight", Vector3(-50, 3, 0), Vector3(12, 6, 14), 2, 2)
	g.light_zone("FarVentLight", Vector3(50, 3, 0), Vector3(12, 6, 14), 2, 2)
	for vx in [-54.9, 54.9]:
		g.deco_box("Vent", Vector3(vx, 6, 0), Vector3(0.2, 5, 8), "window", Vector3.ZERO, false)
	for jx in 11:
		g.deco_box("Joist", Vector3(-50 + jx * 10.0, 11.4, 0), Vector3(1.2, 1.2, 80), "wood")
	for px in [-30.0, -5.0, 20.0, 40.0]:
		for pz in [-22.0, 0.0, 22.0]:
			var p := Vector3(px + rng.randf_range(-3.0, 3.0), 0, pz + rng.randf_range(-3.0, 3.0))
			g.box("Pier", p + Vector3.UP * 6.0, Vector3(4, 12, 4), "concrete", &"stone")
			m.block(p, 5, 5)
	g.pipe("Duct", Vector3(-55, 8.5, -12), Vector3(55, 8.5, -12), 2.5, "metal")
	g.pipe("WaterPipe", Vector3(-55, 3, 15), Vector3(55, 3, 15), 0.8, "copper")
	g.pipe("DrainPipe", Vector3(10, 9, -40), Vector3(10, 5, 40), 1.4, "plastic_white", &"plastic")
	for i in 4:
		var p2 := m.place(9, 7)
		if p2 != Vector3.INF:
			g.cover_block("Rock", p2, Vector3(rng.randf_range(4.0, 7.0), rng.randf_range(2.0, 3.5), rng.randf_range(3.5, 6.0)), "patio", "rock", "", &"stone")
			m.spot(p2 + Vector3.UP * 2.0)
	for i in 3:
		g.sticky_trap("Cobweb", Vector3(rng.randf_range(-45.0, 45.0), 9.5, rng.randf_range(-35.0, 35.0)), Vector3(7, 3, 7), true)
		g.scent_wiper("Damp", Vector3(rng.randf_range(-40.0, 40.0), 0.6, rng.randf_range(-35.0, 35.0)), Vector3(8, 1.2, 6))
	# Shards everywhere: the reason to come down here.
	for i in 26:
		m.spot(Vector3(rng.randf_range(-50.0, 50.0), 0.0, rng.randf_range(-36.0, 36.0)))
	m.extra_shards = 10
	# Two crumb gems hidden in the far corners.
	var gems := ["gem_amber", "gem_amethyst", "gem_emerald", "gem_ruby", "gem_sapphire", "gem_diamond"]
	g.item(gems[rng.randi() % gems.size()], Vector3(45, 0, -33))
	g.item(gems[rng.randi() % gems.size()], Vector3(-25, 0, 34))
	g.item("power_turbo", Vector3(0, 0, 30))
	# The bug bomb's fog rolls in slowly from the far end.
	g.fog(Vector3(58, 0, 0), -PI * 0.5, 110.0, 150.0, 90.0)
	m.hazards(0.0)


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


static func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c
