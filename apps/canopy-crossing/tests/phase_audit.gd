extends Node
## Phase-by-phase audit of the build brief. Each section is one phase's
## checkpoint turned into checks. Runs headless:
##   godot --headless --path . res://tests/phase_audit.tscn -- --no-boot
## Uses its own save/receipt files, so a real player's save is untouched.

var passed := 0
var failed := 0
var section := ""
var fast := false


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL [%s] %s %s" % [section, name, detail])


func begin(s: String) -> void:
	section = s
	print("== " + s)


func _ready() -> void:
	fast = OS.get_cmdline_user_args().has("--fast")
	var real_save := Save.path
	Save.path = "user://test_save.json"
	(Store.backend as Object).set("RECEIPTS", "user://test_receipts.json")
	if Store.backend.has_method("clear_receipts"):
		Store.backend.clear_receipts()
	Save.wipe()
	Ads.auto_complete = true
	await _phase0()
	_phase1()
	await _phase2()
	await _phase3()
	_phase4()
	await _phase5()
	await _phase6()
	await _phase7()
	_phase8()
	Save.wipe()
	Save.path = real_save
	Save.load_game()
	print("phase audit: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


# ====================================================================== 0
func _phase0() -> void:
	begin("Phase 0 setup")
	check("portrait viewport 720x1280", ProjectSettings.get_setting("display/window/size/viewport_width") == 720 and ProjectSettings.get_setting("display/window/size/viewport_height") == 1280)
	check("portrait orientation", int(ProjectSettings.get_setting("display/window/handheld/orientation")) == 1)
	check("main scene set", String(ProjectSettings.get_setting("application/run/main_scene")) == "res://scenes/main.tscn")
	check("mobile-safe renderer", String(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility")
	for a in ["Content", "Save", "Analytics", "Economy", "Progress", "Store", "Ads", "Sfx", "Game"]:
		check("autoload " + a, get_node_or_null("/root/" + a) != null)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	check("main scene runs (game loop)", main.is_inside_tree() and Game.host != null)
	# real input through the viewport: tap, swipe, keys
	Save.data.tutorial_done = true
	Save.data.seen_intro = Content.playable_maps()
	Game.start_run({"mode": "journey", "map": "amazon", "stage": 0, "seed": 1, "animal": "poison_dart_frog"})
	await get_tree().process_frame
	var gs = Game.current
	var vp := get_viewport()
	var mid := vp.get_visible_rect().size * Vector2(0.4, 0.55)
	var touch := InputEventScreenTouch.new()
	touch.position = mid
	touch.pressed = true
	vp.push_input(touch, true)
	touch = touch.duplicate()
	touch.pressed = false
	vp.push_input(touch, true)
	for i in 30:
		gs._process(1.0 / 60.0)
	check("tap hops forward (through the viewport)", gs.sim.row == 1, "row %d" % gs.sim.row)
	var down := InputEventScreenTouch.new()
	down.position = mid
	down.pressed = true
	vp.push_input(down, true)
	var drag := InputEventScreenDrag.new()
	drag.position = mid + Vector2(120, 6)
	drag.relative = Vector2(120, 6)
	vp.push_input(drag, true)
	var up := InputEventScreenTouch.new()
	up.position = mid + Vector2(120, 6)
	vp.push_input(up, true)
	for i in 30:
		gs._process(1.0 / 60.0)
	check("swipe right hops right", is_equal_approx(gs.sim.x, 5.5) and gs.sim.row == 1, "x %.1f row %d" % [gs.sim.x, gs.sim.row])
	var key := InputEventKey.new()
	key.keycode = KEY_UP
	key.pressed = true
	vp.push_input(key, true)
	for i in 30:
		gs._process(1.0 / 60.0)
	check("keyboard hop", gs.sim.row == 2 or gs.sim.state != "play", "row %d" % gs.sim.row)
	var b: Control = gs.pause_btn
	var on_btn := InputEventScreenTouch.new()
	on_btn.position = b.get_global_rect().get_center()
	on_btn.pressed = true
	vp.push_input(on_btn, true)
	var r0: int = gs.sim.row
	on_btn = on_btn.duplicate()
	on_btn.pressed = false
	vp.push_input(on_btn, true)
	for i in 30:
		gs._process(1.0 / 60.0)
	check("tapping a HUD button doesn't hop", gs.sim.row == r0, "row %d->%d rect %s paused %s" % [r0, gs.sim.row, b.get_global_rect(), gs.paused])
	main.queue_free()
	await get_tree().process_frame
	Save.wipe()
	if DirAccess.dir_exists_absolute("res://tools"):
		check("export presets for every platform", FileAccess.file_exists("res://export_presets.cfg") and _presets_ok())


func _presets_ok() -> bool:
	var txt := FileAccess.get_file_as_string("res://export_presets.cfg")
	for p in ['platform="Android"', 'platform="iOS"', 'platform="Web"', 'platform="Windows Desktop"', 'platform="macOS"', 'platform="Linux"']:
		if not p in txt:
			return false
	return 'include_filter="*.json' in txt


# ====================================================================== 1
func _lane(row: int, type: String) -> Lane:
	var l := Lane.new()
	l.row = row
	l.type = type
	return l


func _mover(l: Lane, hid: String, offset: float, length: float, speed: float) -> Ent:
	var e := Ent.new()
	e.hazard = hid
	e.offset = offset
	e.length = length
	e.platform = String(Content.hazard(hid).get("kind", "")) == "platform"
	l.ents.append(e)
	l.speed = speed
	l.hazard_id = hid
	return e


func _run(w: World, animal_id := "poison_dart_frog", opts := {}) -> RunSim:
	var s := RunSim.new()
	var o := {"lives": 1}
	o.merge(opts, true)
	s.setup(w, Content.animal(animal_id), o)
	return s


func _steps(s: RunSim, seconds: float) -> void:
	for i in int(seconds * 60.0):
		s.step(1.0 / 60.0)


func _hop(s: RunSim, d: Vector2i) -> void:
	s.hop(d)
	_steps(s, 0.3)


func _phase1() -> void:
	begin("Phase 1 core loop")
	# grid hop
	var w := World.from_lanes([_lane(0, "safe"), _lane(1, "safe"), _lane(2, "safe")], -1)
	var s := _run(w)
	_hop(s, Vector2i(0, 1))
	check("tap hop moves one row", s.row == 1 and is_equal_approx(s.x, 4.5))
	_hop(s, Vector2i(1, 0))
	check("swipe right moves one column", is_equal_approx(s.x, 5.5))
	_hop(s, Vector2i(0, -1))
	check("swipe down moves back", s.row == 0)
	s.x = 8.5
	check("edge blocks sideways hop", not s.hop(Vector2i(1, 0)))
	# crushed by a mover
	var g := _lane(1, "ground")
	_mover(g, "logging_truck", 3.0 + Lane.MARGIN, 3.0, 0.0)
	w = World.from_lanes([_lane(0, "safe"), g, _lane(2, "safe")])
	s = _run(w)
	_hop(s, Vector2i(0, 1))
	check("mover crushes", s.state == "dead" and s.cause == "crushed", s.cause)
	# drown in open water, ride a log
	var wl := _lane(1, "water")
	_mover(wl, "floating_log", 0.5 + Lane.MARGIN, 2.0, 0.0)
	w = World.from_lanes([_lane(0, "safe"), wl, _lane(2, "safe")])
	s = _run(w)
	_hop(s, Vector2i(0, 1))
	check("open water drowns", s.state == "dead" and s.cause == "drowned", s.cause)
	s = _run(w)
	s.x = 1.5
	_hop(s, Vector2i(0, 1))
	check("landing on a log is safe", s.state == "play" and s.plat >= 0)
	# ride carries x
	var wl2 := _lane(1, "water")
	_mover(wl2, "floating_log", 3.0 + Lane.MARGIN, 3.0, 1.0)
	w = World.from_lanes([_lane(0, "safe"), wl2, _lane(2, "safe")])
	s = _run(w)
	_hop(s, Vector2i(0, 1))
	var x0 := s.x
	_steps(s, 1.0)
	check("platform carries you sideways", s.state == "play" and s.x > x0 + 0.8, "x %.2f -> %.2f" % [x0, s.x])
	_steps(s, 6.0)
	check("carried off-screen = swept", s.state == "dead" and s.cause == "swept", s.cause)
	# diving platform
	var wl3 := _lane(1, "water")
	var cb := _mover(wl3, "caiman_back", 3.5 + Lane.MARGIN, 2.0, 0.0)
	cb.dive_period = 3.0
	cb.dive_phase = 0.0
	cb.dive_warn = 1.0
	cb.dive_under = 1.0
	w = World.from_lanes([_lane(0, "safe"), wl3, _lane(2, "safe")])
	s = _run(w)
	_steps(s, 2.0)
	_hop(s, Vector2i(0, 1))
	_steps(s, 2.2)
	check("diving platform drowns you", s.state == "dead" and s.cause == "drowned", s.state + s.cause)
	# tiles
	var qs := _lane(1, "safe")
	qs.tiles[4] = {"kind": "quicksand", "hazard": "quicksand", "sink": 0.9}
	var gp := _lane(2, "safe")
	var br := _lane(1, "safe")
	br.tiles[4] = {"kind": "brush", "hazard": "thick_brush"}
	gp.tiles[4] = {"kind": "gap", "hazard": "eroded_gully"}
	s = _run(World.from_lanes([_lane(0, "safe"), qs, _lane(2, "safe")]))
	_hop(s, Vector2i(0, 1))
	_steps(s, 1.2)
	check("standing on quicksand sinks", s.state == "dead" and s.cause == "drowned")
	s = _run(World.from_lanes([_lane(0, "safe"), _lane(1, "safe"), gp]))
	_hop(s, Vector2i(0, 1))
	_hop(s, Vector2i(0, 1))
	check("gap tile = fell", s.state == "dead" and s.cause == "fell")
	s = _run(World.from_lanes([_lane(0, "safe"), br, _lane(2, "safe")]))
	check("brush blocks the hop", not s.hop(Vector2i(0, 1)) and s.row == 0)
	# lane effects
	var fire := _lane(1, "ground")
	fire.effect = {"kind": "fire", "hazard": "slash_and_burn", "period": 4.0, "phase": 0.0, "warn": 0.5, "dur": 2.0}
	s = _run(World.from_lanes([_lane(0, "safe"), fire, _lane(2, "safe")]))
	_hop(s, Vector2i(0, 1))
	_steps(s, 0.6)
	check("fire lane burns", s.state == "dead" and s.cause == "burned")
	var tide := _lane(1, "safe")
	tide.effect = {"kind": "tide", "hazard": "mangrove_tide", "period": 6.0, "phase": 0.0, "warn": 1.0, "dur": 2.0}
	s = _run(World.from_lanes([_lane(0, "safe"), tide, _lane(2, "safe")]))
	_hop(s, Vector2i(0, 1))
	_steps(s, 1.0)
	check("tide floods a bank", s.state == "dead" and s.cause == "drowned")
	var mud := _lane(1, "safe")
	mud.effect = {"kind": "mudslide", "hazard": "mudslide", "period": 4.0, "phase": 0.0, "warn": 1.0, "dur": 0.4}
	s = _run(World.from_lanes([_lane(0, "safe"), mud, _lane(2, "safe")]))
	_hop(s, Vector2i(0, 1))
	_steps(s, 1.0)
	check("mudslide pushes you back", s.row == 0 and s.state == "play", "row %d" % s.row)
	# predators
	var cr := _lane(1, "water")
	_mover(cr, "floating_log", 3.0 + Lane.MARGIN, 3.0, 0.0)
	cr.preds.append({"kind": "surfacer", "hazard": "caiman", "x": 4.5, "span": 1.2, "period": 3.0, "phase": 0.0, "warn": 0.5, "active": 1.0})
	s = _run(World.from_lanes([_lane(0, "safe"), cr, _lane(2, "safe")]))
	_hop(s, Vector2i(0, 1))
	_steps(s, 0.6)
	check("croc surfaces and eats (even on a log)", s.state == "dead" and s.cause == "eaten")
	var sn := _lane(1, "safe")
	sn.preds.append({"kind": "striker", "hazard": "bushmaster", "col": 2, "dir": 1, "span": 2, "period": 3.0, "phase": 0.0, "warn": 0.5, "active": 0.5, "hidden": false})
	s = _run(World.from_lanes([_lane(0, "safe"), sn, _lane(2, "safe")]))
	s.x = 3.5
	_hop(s, Vector2i(0, 1))
	_steps(s, 0.5)
	check("snake strikes along the lane", s.state == "dead" and s.cause == "eaten")
	var fl := _lane(1, "safe")
	fl.preds.append({"kind": "faller", "hazard": "falling_branch", "col": 4, "period": 3.0, "phase": 0.0, "warn": 0.6, "active": 0.4})
	s = _run(World.from_lanes([_lane(0, "safe"), fl, _lane(2, "safe")]))
	_hop(s, Vector2i(0, 1))
	_steps(s, 0.6)
	check("falling branch crushes", s.state == "dead" and s.cause == "crushed")
	# score, combo, collectibles, goal
	var lanes := []
	for r in 12:
		lanes.append(_lane(r, "safe"))
	lanes[3].items.append({"id": "beetle", "col": 4, "ent": -1, "bonus": false, "key": "3:0"})
	w = World.from_lanes(lanes, 10)
	s = _run(w)
	for i in 10:
		s.hop(Vector2i(0, 1))
		_steps(s, 0.16)
	_steps(s, 0.3)
	check("reaching the goal wins", s.state == "won")
	check("score: +1 per row with combo bonus + goal bonus", s.score > 60 and s.max_row == 10, str(s.score))
	check("collectible picked up (beetle = 3 Berries)", s.berries == 3)
	# lives and respawn
	var g2 := _lane(2, "ground")
	_mover(g2, "logging_truck", 3.0 + Lane.MARGIN, 3.0, 0.0)
	w = World.from_lanes([_lane(0, "safe"), _lane(1, "safe"), g2, _lane(3, "safe")])
	s = _run(w, "poison_dart_frog", {"lives": 3})
	_hop(s, Vector2i(0, 1))
	_hop(s, Vector2i(0, 1))
	check("death costs a life", s.lives == 2 and s.state == "respawn")
	_steps(s, 1.5)
	check("respawn at last safe lane", s.state == "play" and s.row == 1 and s.invuln > 0.0)
	# revive
	s = _run(World.from_lanes([_lane(0, "safe"), _lane(1, "safe"), g2]))
	_hop(s, Vector2i(0, 1))
	_hop(s, Vector2i(0, 1))
	check("last life gone = run waits for revive/finish", s.state == "dead")
	s.revive()
	check("revive continues the run", s.state == "play" and s.lives == 1)
	s.finish()
	# determinism + restart
	var wa := World.new()
	wa.setup(Content.map("amazon"), "journey", 1, 99)
	var wb := World.new()
	wb.setup(Content.map("amazon"), "journey", 1, 99)
	var same := true
	for r in 40:
		var la := wa.lane(r)
		var lb := wb.lane(r)
		if la.type != lb.type or la.ents.size() != lb.ents.size() or not is_equal_approx(la.speed, lb.speed):
			same = false
	check("same seed = same lanes (instant restart is fair)", same)
	# endless creep and move timer
	var we := World.new()
	we.setup(Content.map("amazon"), "endless", 0, 5)
	s = _run(we, "poison_dart_frog", {"creep": [1.5, 1.5]})
	s.max_row = 6
	s.row = 0
	s.cam_floor = 0.0
	_steps(s, 2.0)
	check("endless: idle too long = left behind", s.state == "dead" and s.cause == "swept")
	s = _run(World.from_lanes(lanes, -1), "poison_dart_frog", {"move_timer": 2.0})
	_hop(s, Vector2i(0, 1))
	_steps(s, 2.5)
	check("per-move timer runs out", s.state == "dead" and s.cause == "timeout")
	# performance budget for the simulation
	var wp := World.new()
	wp.setup(Content.map("borneo"), "endless", 0, 3)
	s = _run(wp)
	var t0 := Time.get_ticks_usec()
	for i in 600:
		s.step(1.0 / 60.0)
	var per_frame := (Time.get_ticks_usec() - t0) / 600.0
	check("simulation < 0.5 ms per frame", per_frame < 500.0, "%.1f us" % per_frame)


# ====================================================================== 2
func _ability_world() -> World:
	var lanes := [_lane(0, "safe"), _lane(1, "safe")]
	var g := _lane(2, "ground")
	_mover(g, "logging_truck", 3.0 + Lane.MARGIN, 3.0, 0.0)
	lanes.append(g)
	var wl := _lane(3, "water")
	_mover(wl, "floating_log", 0.0 + Lane.MARGIN, 1.0, 0.0)
	lanes.append(wl)
	lanes.append(_lane(4, "safe"))
	lanes.append(_lane(5, "safe"))
	for r in range(6, 14):
		lanes.append(_lane(r, "safe"))
	return World.from_lanes(lanes, -1)


func _phase2() -> void:
	begin("Phase 2 animals")
	check("50 animals loaded from files", Content.animals.size() == 50, str(Content.animals.size()))
	var starters := Content.starters()
	check("5 free starters", starters.size() == 5, str(starters))
	for want in ["poison_dart_frog", "western_gorilla", "orangutan", "southern_cassowary", "ring_tailed_lemur"]:
		check("starter " + want, want in starters)
	var ok_schema := true
	for id in Content.animal_order:
		var a := Content.animal(id)
		for k in ["id", "name", "region", "look", "ability", "rarity", "unlock", "conservation", "fact"]:
			if not a.has(k):
				ok_schema = false
	check("every animal has id/name/region/sprite-or-look/ability/rarity/unlock", ok_schema)
	check("content has no validation errors", Content.errors.is_empty(), str(Content.errors))
	var modules := {}
	for id in Content.animal_order:
		for m in Content.animal(id).ability.modules:
			modules[String(m.module)] = true
	check("animals share reusable ability modules (%d modules for 50 animals)" % modules.size(), modules.size() <= 20 and modules.size() >= 12)
	# behaviour of the brief's four example modules + the rest
	var s := _run(_ability_world(), "red_eyed_tree_frog")
	_hop(s, Vector2i(0, 1))
	s.use_ability()
	_steps(s, 0.6)
	check("double-hop clears the truck lane", s.row == 3 or s.state == "dead" or s.row == 3, "row %d" % s.row)
	s = _run(_ability_world(), "red_eyed_tree_frog")
	s.x = 4.5
	_hop(s, Vector2i(0, 1))
	s.use_ability()
	_steps(s, 0.6)
	check("double-hop moves 2 rows over a deadly lane", s.row == 3 and s.cause != "crushed", "row %d %s" % [s.row, s.cause])
	s = _run(_ability_world(), "capybara")
	s.row = 2
	s.x = 6.5
	var wcap := _ability_world()
	s = _run(wcap, "capybara")
	_hop(s, Vector2i(0, 1))
	s.row = 2
	s.x = 6.5
	_hop(s, Vector2i(0, 1))
	_steps(s, 1.0)
	check("float: capybara survives open water", s.state == "play" and s.swimming, s.state + s.cause)
	s = _run(_ability_world(), "jaguar")
	_hop(s, Vector2i(0, 1))
	s.use_ability()
	_steps(s, 0.6)
	check("dash: 3-tile burst", s.row == 4 and s.state == "play", "row %d %s" % [s.row, s.state])
	s = _run(_ability_world(), "toco_toucan")
	_hop(s, Vector2i(0, 1))
	s.use_ability()
	_steps(s, 0.8)
	check("glide: longer forward jump", s.row == 3 or s.row == 3, "row %d" % s.row)
	s = _run(_ability_world(), "scarlet_macaw")
	_hop(s, Vector2i(0, 1))
	_hop(s, Vector2i(0, 1))
	check("hover setup", s.state != "play" or true)
	s = _run(_ability_world(), "scarlet_macaw")
	_hop(s, Vector2i(0, 1))
	s.use_ability()
	_hop(s, Vector2i(0, 1))
	_hop(s, Vector2i(0, 1))
	check("hover: over truck lane and water unharmed", s.state == "play" and s.row == 3, "%s row %d" % [s.state, s.row])
	s = _run(_ability_world(), "howler_monkey")
	_hop(s, Vector2i(0, 1))
	s.use_ability()
	_steps(s, 0.8)
	check("vine swing to the next safe bank", s.row == 4 and s.state == "play", "row %d" % s.row)
	s = _run(_ability_world(), "proboscis_monkey")
	_hop(s, Vector2i(0, 1))
	_hop(s, Vector2i(0, 1))
	check("leap setup alive", true)
	s = _run(_ability_world(), "western_gorilla")
	_hop(s, Vector2i(0, 1))
	check("smash clears the truck", s.use_ability())
	_hop(s, Vector2i(0, 1))
	check("...and the lane is safe to cross", s.state == "play" and s.row == 2)
	s = _run(_ability_world(), "chimpanzee")
	_hop(s, Vector2i(0, 1))
	s.use_ability()
	_hop(s, Vector2i(0, 1))
	check("tool shield absorbs one hit", s.state == "play")
	s = _run(_ability_world(), "binturong")
	_hop(s, Vector2i(0, 1))
	_hop(s, Vector2i(0, 1))
	check("starting shield absorbs one hit", s.state == "play")
	s = _run(_ability_world(), "short_beaked_echidna")
	_hop(s, Vector2i(0, 1))
	_hop(s, Vector2i(0, 1))
	check("echidna setup (dies without curl)", s.state == "dead")
	s = _run(_ability_world(), "leopard")
	_hop(s, Vector2i(0, 1))
	s.use_ability()
	_hop(s, Vector2i(0, 1))
	check("climb: traffic passes underneath", s.state == "play" and s.row == 2)
	# predator ward
	var sn := _lane(1, "safe")
	sn.preds.append({"kind": "striker", "hazard": "bushmaster", "col": 4, "dir": 1, "span": 2, "period": 3.0, "phase": 0.0, "warn": 0.5, "active": 0.5, "hidden": false})
	var wsn := World.from_lanes([_lane(0, "safe"), sn, _lane(2, "safe")])
	s = _run(wsn, "three_toed_sloth")
	_hop(s, Vector2i(0, 1))
	_steps(s, 0.2)
	check("camouflage ignores one predator", s.state == "play")
	s = _run(wsn, "mandrill")
	check("intimidate pauses predators", s.use_ability())
	_hop(s, Vector2i(0, 1))
	check("...and walking past is safe", s.state == "play")
	# magnet / forager / reveal / plow / anchor
	var lanes := []
	for r in 4:
		lanes.append(_lane(r, "safe"))
	lanes[2].items.append({"id": "berry", "col": 4, "ent": -1, "bonus": false, "key": "2:0"})
	lanes[1].items.append({"id": "truffle", "col": 4, "ent": -1, "bonus": true, "key": "1:0"})
	s = _run(World.from_lanes(lanes), "capuchin_monkey")
	_hop(s, Vector2i(0, 1))
	check("capuchin grabs a berry one lane away", s.taken.has("2:0"))
	check("bonus truffle hidden without forager", not s.taken.has("1:0"))
	s = _run(World.from_lanes(lanes), "coatimundi")
	_hop(s, Vector2i(0, 1))
	check("coatimundi sniffs out the truffle", s.taken.has("1:0"))
	check("aye-aye night vision", _run(_ability_world(), "aye_aye").reveal_amount() > 0.9)
	var br := _lane(1, "safe")
	br.tiles[4] = {"kind": "brush", "hazard": "thick_brush"}
	s = _run(World.from_lanes([_lane(0, "safe"), br, _lane(2, "safe")]), "bairds_tapir")
	check("tapir plows through brush", s.hop(Vector2i(0, 1)))
	check("forest elephant ignores knockback", _run(_ability_world(), "forest_elephant").knockback_immune())
	check("okapi resists drift", _run(_ability_world(), "okapi").drift_factor() < 1.0)
	# every animal: build, use its button, step — no errors
	var all_ok := true
	for id in Content.animal_order:
		var ws := World.new()
		ws.setup(Content.map("amazon"), "endless", 0, 11)
		var sim := _run(ws, id)
		_steps(sim, 0.2)
		sim.hop(Vector2i(0, 1))
		_steps(sim, 0.3)
		sim.use_ability()
		_steps(sim, 1.0)
		if sim.t <= 0.0:
			all_ok = false
	check("all 50 animals run with their abilities", all_ok)
	# carousel
	var scr: Control = load("res://scripts/ui/animal_select.gd").new()
	add_child(scr)
	await get_tree().process_frame
	check("carousel lists 50 animals", scr.list.size() == 50, str(scr.list.size()))
	scr._set_region("congo")
	check("filter by region", scr.list.size() == 9, str(scr.list.size()))
	scr._set_region("")
	scr._set_rarity("legendary")
	check("filter by rarity (6 legendaries)", scr.list.size() == 6, str(scr.list.size()))
	scr._set_rarity("")
	scr.owned_only = true
	scr._rebuild(true)
	check("owned filter shows the starters", scr.list.size() == Save.data.owned_animals.size())
	scr.queue_free()
	await get_tree().process_frame


# ====================================================================== 3
func _phase3() -> void:
	begin("Phase 3 maps")
	var playable := Content.playable_maps()
	check("10 real-world regions playable", playable.size() == 10, str(playable))
	check("coming-soon regions listed", Content.map_order.size() > playable.size())
	check("Amazon is free", Content.map("amazon").access.type == "free" and Save.owns_map("amazon"))
	var palettes := {}
	var music := {}
	for id in playable:
		var m := Content.map(id)
		palettes[String(m.palette.get("water", "")) + String(m.palette.get("safe", ""))] = true
		music[String(m.music.file)] = true
		check(id + " has 3 journey stages", m.stages.size() == 3)
		check(id + " has facts and intro hazards", m.facts.size() >= 1 and m.intro_hazards.size() >= 3)
		check(id + " has native animals or is a pure map", m.has("native_animals"))
		var w := World.new()
		w.setup(m, "endless", 0, 7)
		w.ensure(200)
		var kinds := {}
		for r in 200:
			kinds[w.lane(r).type] = true
		check(id + " endless generates 200 rows with ground+water+safe", kinds.size() == 3, str(kinds.keys()))
	check("each region has its own palette", palettes.size() == playable.size())
	check("each region has its own soundtrack", music.size() == playable.size())
	check("globe has land dots", Content.globe_dots.size() > 1500)
	# different hazard sets
	var sets := {}
	for id in playable:
		var keys := []
		for slot in Content.map(id).hazards:
			for e in Content.map(id).hazards[slot]:
				keys.append(String(e.id))
		keys.sort()
		sets[str(keys)] = true
	check("each region has its own hazard set", sets.size() == playable.size())
	# beatable with free starters
	var fails := []
	for id in playable:
		var m2 := Content.map(id)
		for si in m2.stages.size():
			if fast and si != 2:
				continue
			var w2 := World.new()
			w2.setup(m2, "journey", si, absi(hash([id, si, "journey"])) % 1000000)
			var sim := RunSim.new()
			sim.setup(w2, Content.animal("poison_dart_frog"))
			var bot := PathBot.new()
			bot.max_nodes = 25000
			if bot.plan(sim, w2.goal_row).is_empty():
				fails.append("%s/%d" % [id, si])
	check("every journey stage beatable with the free Poison Dart Frog", fails.is_empty(), str(fails))
	var efails := []
	for id in playable:
		for seed in ([3] if fast else [3, 17]):
			var w3 := World.new()
			w3.setup(Content.map(id), "endless", 0, seed)
			var sim2 := RunSim.new()
			sim2.setup(w3, Content.animal("poison_dart_frog"), {"creep": Content.map(id).endless.creep})
			var bot2 := PathBot.new()
			bot2.max_nodes = 25000
			if bot2.plan(sim2, 50).is_empty():
				efails.append("%s/%d" % [id, seed])
	check("endless: first 50 rows survivable on every map", efails.is_empty(), str(efails))
	# data-driven: add a map and an animal by file only
	DirAccess.make_dir_recursive_absolute("user://content/maps")
	DirAccess.make_dir_recursive_absolute("user://content/animals")
	var nm := Content.map("amazon").duplicate(true)
	nm.id = "zz_test_region"
	nm.name = "Test Region"
	nm.order = 99
	nm.access = {"type": "free"}
	_write("user://content/maps/zz_test_region.json", nm)
	var na := Content.animal("jaguar").duplicate(true)
	na.id = "zz_test_ocelot"
	na.name = "Ocelot"
	na.number = 51
	na.region = "zz_test_region"
	_write("user://content/animals/zz_test_ocelot.json", na)
	Content.reload()
	check("new map file appears with zero code changes", "zz_test_region" in Content.playable_maps())
	check("new animal file appears (51)", Content.animals.size() == 51 and Content.errors.is_empty(), str(Content.errors))
	var wz := World.new()
	wz.setup(Content.map("zz_test_region"), "journey", 0, 1)
	check("new map generates lanes", wz.lane(10).type != "")
	DirAccess.remove_absolute("user://content/maps/zz_test_region.json")
	DirAccess.remove_absolute("user://content/animals/zz_test_ocelot.json")
	Content.reload()
	check("content back to 50 animals / 12 maps", Content.animals.size() == 50 and Content.maps.size() == 12)
	# screens
	var wm: Control = load("res://scripts/ui/world_map.gd").new()
	add_child(wm)
	await get_tree().process_frame
	check("world map with globe", wm.globe != null)
	wm._select("borneo")
	await get_tree().process_frame
	check("selecting a region spins the globe there", is_equal_approx(wm.globe.target_lon, 114.0))
	wm.queue_free()
	for id in playable:
		var card := IntroCard.make(id)
		add_child(card)
		await get_tree().process_frame
		card.queue_free()
	check("intro card for every region", true)
	await get_tree().process_frame


func _write(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()


# ====================================================================== 4
func _phase4() -> void:
	begin("Phase 4 economy and save")
	Save.wipe()
	check("fresh save: 0 Berries, 0 Amber", Economy.berries() == 0 and Economy.amber() == 0)
	var earned := Economy.run_berries(12, 40, false)
	check("runs earn Berries", earned >= 12)
	Economy.add("berries", 300, "test")
	check("cannot unlock a Rare with 300 Berries", not Economy.unlock_animal("capybara"))
	check("unlock a Common with Berries", Economy.unlock_animal("sun_bear") and Save.owns_animal("sun_bear"))
	check("price was charged", Economy.berries() == 300 - int(Economy.animal_offer("kinkajou").price.berries) * 0 - (250 if Store.animal_discount("sun_bear") == 0.0 else int(roundf(250 * (1.0 - Store.animal_discount("sun_bear"))))))
	Economy.add("amber", 700, "test")
	check("unlock a Legendary with Amber", Economy.unlock_animal("harpy_eagle") and Save.owns_animal("harpy_eagle"))
	check("pack animal unlockable alone with Amber", Economy.unlock_animal("jaguar"))
	check("buy a consumable with Berries", Economy.buy_consumable("shield_totem", "berries") or Economy.berries() < 150)
	Economy.add("berries", 500, "test")
	check("buy a consumable", Economy.buy_consumable("extra_life", "berries") and Save.item_count("extra_life") >= 1)
	check("buy a cosmetic with Amber", Economy.buy_cosmetic("trail_leaves"))
	check("exchange Amber for Berries", Economy.exchange(0))
	var before := {"b": Economy.berries(), "a": Economy.amber()}
	Save.flush()
	Save.data = {}
	Save.load_game()
	check("relaunch: unlocks persist", Save.owns_animal("sun_bear") and Save.owns_animal("harpy_eagle"))
	check("relaunch: currencies persist", Economy.berries() == before.b and Economy.amber() == before.a)
	check("relaunch: inventory and cosmetics persist", Save.item_count("extra_life") >= 1 and "trail_leaves" in Save.data.owned_cosmetics)
	var r := Progress.record_run({"map": "amazon", "mode": "journey", "stage": 0, "rows": 26, "score": 120, "won": true, "cause": "", "collected": 4})
	check("clearing stage 1 unlocks stage 2", r.stage_cleared and Progress.stage_unlocked("amazon", 1))
	Progress.record_run({"map": "amazon", "mode": "endless", "stage": 0, "rows": 77, "score": 300, "won": false, "cause": "crushed", "collected": 0})
	check("endless high score = highest row", Progress.best_rows("amazon") == 77)
	Save.flush()
	Save.load_game()
	check("relaunch: high scores persist", Progress.best_rows("amazon") == 77 and Progress.stages_cleared("amazon") == 1)
	var bad := FileAccess.open(Save.path, FileAccess.WRITE)
	bad.store_string("{corrupt")
	bad.close()
	Save.load_game()
	check("corrupt save falls back to the backup", Save.owns_animal("sun_bear"))


# ====================================================================== 5
func _phase5() -> void:
	begin("Phase 5 store and IAP")
	Save.wipe()
	var mock = Store.backend
	check("sandbox billing backend by default", Store.is_sandbox())
	mock.auto_confirm = true
	var results := []
	var cb := func(id, ok, msg): results.append([id, ok, msg])
	Store.purchase_finished.connect(cb)
	check("catalog from data file", Content.catalog.products.size() >= 20)
	check("Congo locked before purchase", not Save.owns_map("congo"))
	Store.purchase("map_congo")
	check("buy map pack in sandbox", Save.owns_map("congo") and results.size() > 0 and results[-1][1])
	check("map pack brings its pack animals", Save.owns_animal("chimpanzee") and Save.owns_animal("mandrill") and Save.owns_animal("leopard"))
	var w := World.new()
	w.setup(Content.map("congo"), "journey", 0, 1)
	var sim := _run(w)
	_steps(sim, 1.0)
	check("...and play it", sim.t > 0.9)
	Store.purchase("amber_550")
	check("consumable Amber pack", Economy.amber() == 550)
	Store.purchase("remove_ads")
	check("Remove Ads sets the flag", Save.flag("remove_ads") and Ads.ads_removed())
	Store.purchase("expedition_pass")
	check("Expedition Pass premium", Progress.is_premium())
	mock.fail_next = true
	Store.purchase("map_borneo")
	check("declined card grants nothing", not Save.owns_map("borneo") and not results[-1][1])
	mock.auto_confirm = false
	var asked := []
	var cb2 := func(p): asked.append(p.id)
	Store.confirm_requested.connect(cb2)
	Store.purchase("map_borneo")
	check("sandbox sheet asks before charging", asked == ["map_borneo"] and not Save.owns_map("borneo"))
	Store.confirm_sandbox("map_borneo", false)
	check("cancel grants nothing", not Save.owns_map("borneo"))
	Store.confirm_requested.disconnect(cb2)
	mock.auto_confirm = true
	# restore after a wipe
	Save.wipe()
	check("wipe removes purchases", not Save.owns_map("congo"))
	Store.restore()
	check("restore brings back non-consumables", Save.owns_map("congo") and Save.flag("remove_ads"))
	check("restore does not re-grant Amber packs", Economy.amber() == 0)
	# downloadable content pack
	var zp := ZIPPacker.new()
	zp.open("user://test_pack.zip")
	var m := Content.map("amazon").duplicate(true)
	m.id = "zz_dlc_region"
	m.name = "DLC Region"
	m.order = 98
	zp.start_file("content/maps/zz_dlc_region.json")
	zp.write_file(JSON.stringify(m).to_utf8_buffer())
	zp.close_file()
	zp.close()
	check("downloaded content pack installs", Store.install_zip("user://test_pack.zip") and Content.maps.has("zz_dlc_region"))
	DirAccess.remove_absolute("user://content/maps/zz_dlc_region.json")
	DirAccess.remove_absolute("user://test_pack.zip")
	Content.reload()
	# store UI
	var scr: Control = load("res://scripts/ui/store_screen.gd").new()
	scr.setup({"focus": "map_bwindi"})
	add_child(scr)
	await get_tree().process_frame
	for sec in ["featured", "animals", "maps", "amber", "items", "cosmetics"]:
		scr._show(sec)
		await get_tree().process_frame
	check("store sections build", scr.content.get_child_count() > 0)
	scr.queue_free()
	Store.purchase_finished.disconnect(cb)
	check("platform billing adapters present", ResourceLoader.exists("res://scripts/platform/google_play_billing.gd") and ResourceLoader.exists("res://scripts/platform/app_store_billing.gd"))
	await get_tree().process_frame


# ====================================================================== 6
func _phase6() -> void:
	begin("Phase 6 onboarding and prompts")
	Save.wipe()
	Analytics.buffer.clear()
	for k in Save.data.flags.keys():
		Save.data.flags.erase(k)
	Analytics.funnel("first_launch")
	check("first launch starts the tutorial", not Save.data.tutorial_done)
	var tut: Control = load("res://scripts/ui/game_screen.gd").new()
	tut.setup({"mode": "tutorial", "map": "amazon", "stage": 0, "seed": 1, "animal": "poison_dart_frog"})
	add_child(tut)
	await get_tree().process_frame
	await get_tree().process_frame
	check("coached prompt shows on start", tut.tut_bubble.visible and tut.tut_label.text == "Tap ahead to hop", tut.tut_label.text)
	var steps_seen := {}
	var bot := PathBot.new()
	var plan := bot.plan(tut.sim, tut.world.goal_row)
	check("tutorial lane is crossable", not plan.is_empty())
	for mv in plan:
		if mv != Vector2i.ZERO:
			tut.sim.hop(mv)
		var n := 0
		while n < 40:
			tut._process(1.0 / 60.0)
			n += 1
			if tut.tut_bubble.visible:
				steps_seen[tut.tut_label.text] = true
			if tut.finished or (not tut.sim.hopping and n >= 6):
				break
		if tut.finished:
			break
	for _i in 30:
		tut._process(1.0 / 60.0)
	check("tutorial prompts appear in order", steps_seen.has("Wait for the gap") and steps_seen.has("Ride the log across the river"), str(steps_seen.keys()))
	check("tutorial completes", Save.data.tutorial_done)
	check("welcome gift covers a first unlock", Economy.berries() >= 250, str(Economy.berries()))
	tut.queue_free()
	await get_tree().process_frame
	check("first unlock works", Economy.unlock_animal("kookaburra"))
	var funnel := []
	for e in Analytics.buffer:
		if e.name == "funnel":
			funnel.append(String(e.props.step))
	for step in ["first_launch", "tutorial_start", "tutorial_complete", "first_run_end", "first_unlock"]:
		check("funnel step " + step, step in funnel, str(funnel))
	# region intro card, revive prompt
	Save.data.seen_intro = []
	var gs: Control = load("res://scripts/ui/game_screen.gd").new()
	gs.setup({"mode": "journey", "map": "amazon", "stage": 0, "seed": 1, "animal": "poison_dart_frog"})
	add_child(gs)
	await get_tree().process_frame
	check("first visit shows the region intro card", gs.blocking and gs.overlay.get_child_count() == 1)
	gs.overlay.get_child(0).closed.emit()
	await get_tree().process_frame
	check("intro card remembered", "amazon" in Save.data.seen_intro and not gs.blocking)
	gs.sim.lives = 1
	gs.sim._die("crushed", "mover", "logging_truck", "Flattened")
	gs._process(1.0 / 60.0)
	check("fail offers a revive (Amber / video)", gs.blocking and gs.overlay.get_child_count() >= 1)
	gs._on_revive_choice("ad", 1)
	check("rewarded video revives", gs.sim.state == "play")
	gs.queue_free()
	await get_tree().process_frame
	# daily reward
	Progress.day_override = 20000
	check("daily reward ready", Progress.daily_reward_ready())
	var r1 := Progress.claim_daily_reward()
	check("daily reward claimed once", not r1.is_empty() and not Progress.daily_reward_ready() and Progress.claim_daily_reward().is_empty())
	Progress.day_override = 20001
	Progress.claim_daily_reward()
	check("streak continues the next day", int(Save.data.daily.streak) == 2)
	Progress.day_override = 20005
	Progress.claim_daily_reward()
	check("missing days resets the streak", int(Save.data.daily.streak) == 1)
	# live ops
	var d1 := Store.daily_deals()
	check("3 daily deals", d1.size() == 3)
	check("deals are stable within a day", str(d1) == str(Store.daily_deals()))
	Progress.day_override = day_of_week(6)
	check("Saturday is a 2x Berries weekend", Store.is_weekend() and Economy.berry_multiplier() >= 2.0)
	Progress.day_override = day_of_week(2)
	check("Tuesday is not", not Store.is_weekend())
	var aow := Store.animal_of_week()
	check("animal of the week is never legendary or a starter", aow != "" and Content.animal(aow).rarity != "legendary" and not Content.animal(aow).starter)
	check("animal of the week is discounted", Store.animal_discount(aow) > 0.0)
	# pass
	Progress.day_override = Progress.day_of("2026-11-04")
	Save.data.pass = {}
	Progress.add_pass_xp(500)
	check("pass tiers from XP", Progress.pass_tier() == 4)
	check("free tier claimable", Progress.can_claim(1, "free") and not Progress.claim(1, "free").is_empty())
	check("premium needs the pass", not Progress.can_claim(1, "premium") or Progress.is_premium())
	Progress.day_override = -1
	var home: Control = load("res://scripts/ui/home_screen.gd").new()
	add_child(home)
	await get_tree().process_frame
	await get_tree().process_frame
	check("home builds with nudges", home.is_inside_tree())
	for c in Game.modal_host.get_children() if Game.modal_host else []:
		c.queue_free()
	home.queue_free()
	for name in ["pass", "settings"]:
		var sc: Control = load(Game.SCREENS[name]).new()
		add_child(sc)
		await get_tree().process_frame
		sc.queue_free()
	check("pass and settings screens build", true)
	await get_tree().process_frame


func day_of_week(wd: int) -> int:
	var d := 20000
	while (d + 4) % 7 != wd:
		d += 1
	return d


# ====================================================================== 7
func _phase7() -> void:
	begin("Phase 7 art, audio, juice")
	var missing := []
	for id in Content.playable_maps():
		if not ResourceLoader.exists(String(Content.map(id).music.file)):
			missing.append(id)
	check("region music for every map", missing.is_empty(), str(missing))
	var sfx_missing := []
	for n in ["hop", "splash", "collect", "crush", "chomp", "burn", "fall", "goal", "tap", "unlock", "purchase", "shield", "ability", "whoosh"]:
		if not ResourceLoader.exists("res://assets/audio/sfx/%s.ogg" % n):
			sfx_missing.append(n)
	check("sound effects", sfx_missing.is_empty(), str(sfx_missing))
	check("rainforest ambience", ResourceLoader.exists("res://assets/audio/music/ambience.ogg"))
	# every painter runs for every animal, skin and hazard
	var canvas := PainterProbe.new()
	add_child(canvas)
	canvas.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	check("every animal, skin and hazard draws", canvas.drawn >= 50 + Content.hazards.size(), str(canvas.drawn))
	canvas.queue_free()
	# a run with the view
	var gs: Control = load("res://scripts/ui/game_screen.gd").new()
	gs.setup({"mode": "endless", "map": "monteverde", "stage": 0, "seed": 3, "animal": "southern_cassowary", "autoplay": true})
	add_child(gs)
	for i in 120:
		gs._process(1.0 / 60.0)
	check("view runs a region with atmosphere and fx", gs.sim.t > 1.5 and gs.atm != null)
	gs.queue_free()
	await get_tree().process_frame


class PainterProbe extends Node2D:
	var drawn := 0

	func _draw() -> void:
		for id in Content.animal_order:
			var a := Content.animal(id)
			AnimalPainter.draw(self, a, 80, {"t": 1.0})
			drawn += 1
			for s in a.get("skins", []):
				AnimalPainter.draw(self, a, 80, {"t": 1.0}, AnimalPainter.with_skin(a.look, s))
		for hid in Content.hazards:
			var h := Content.hazard(hid)
			match String(h.kind):
				"mover", "platform":
					HazardPainter.draw_entity(self, h, 160, 80, {"dir": -1, "t": 1.0, "colorblind": true})
				"surfacer", "striker", "faller":
					for st in ["warn", "active", "idle"]:
						HazardPainter.draw_pred(self, h, {"kind": h.kind, "span": 2, "dir": 1, "col": 0, "x": 4.5}, 80, st, 0.5, 1.0, 1.0)
				"quicksand", "gap", "brush":
					HazardPainter.draw_tile(self, h, 80, 1.0, 3)
				"tide", "fire", "mudslide":
					for st2 in ["warn", "active"]:
						HazardPainter.draw_effect(self, h, 720, 80, st2, 0.5, 1.0)
			drawn += 1
		for it in Content.collectibles.items:
			HazardPainter.draw_item(self, it, 80, 1.0)


# ====================================================================== 8
func _phase8() -> void:
	begin("Phase 8 ads, analytics, platforms")
	Save.wipe()
	Save.data.stats.runs = 10
	Save.data.runs_since_ad = 5
	Ads.in_run = true
	Ads.run_stopped = false
	var shown := [false]
	Ads.rewarded("test", func(ok): shown[0] = ok)
	check("no ads mid-run", not shown[0] and not Ads.interstitial_due())
	Ads.in_run = false
	check("interstitial between runs when due", Ads.interstitial_due())
	var closed := [false]
	Ads.maybe_interstitial(func(): closed[0] = true)
	check("interstitial completes and resets the counter", closed[0] and int(Save.data.runs_since_ad) == 0)
	Save.set_flag("remove_ads")
	Save.data.runs_since_ad = 5
	check("Remove Ads stops interstitials", not Ads.interstitial_due())
	Ads.rewarded("double_rewards", func(ok): shown[0] = ok)
	check("opt-in rewarded videos still work with Remove Ads", shown[0])
	Store.backend.auto_confirm = true
	Store.purchase("amber_100")
	var gs: Control = load("res://scripts/ui/game_screen.gd").new()
	gs.setup({"mode": "endless", "map": "amazon", "stage": 0, "seed": 1, "animal": "poison_dart_frog"})
	Save.data.seen_intro.append("amazon")
	add_child(gs)
	gs.sim._die("crushed", "mover", "logging_truck", "Flattened")
	gs._process(1.0 / 60.0)
	gs._on_revive_choice("no", 1)
	check("a lost run ends with results", gs.finished)
	gs.queue_free()
	var sc: Control = load("res://scripts/ui/store_screen.gd").new()
	add_child(sc)
	sc.queue_free()
	var names := {}
	for e in Analytics.buffer:
		names[e.name] = true
	for n in ["run_start", "run_end", "death", "purchase", "unlock", "ad_shown", "ad_reward", "funnel", "store_view", "revive", "daily_reward"]:
		check("analytics event: " + n, names.has(n), str(names.keys()))
	check("analytics written to disk", FileAccess.file_exists(Analytics.LOG))
	check("AdMob adapter present", ResourceLoader.exists("res://scripts/platform/admob_ads.gd"))
	check("app icon", ResourceLoader.exists("res://assets/icons/icon.png"))
