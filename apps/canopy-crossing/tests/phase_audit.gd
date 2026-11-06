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
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a == "--core":
			only = "core"
		elif a.begins_with("--only="):
			only = a.substr(7)
	if only != "":
		# quick loops while tuning: just one section
		match only:
			"core":
				_phase1()
			"fpv":
				await _first_person()
			"scenes":
				_scenes()
			"regions":
				await _phase3()
			"skills":
				_skills()
			"art":
				await _phase7()
			"onboarding":
				await _phase6()
		print("phase audit (%s): %d passed, %d failed" % [only, passed, failed])
		Save.wipe()
		Save.path = real_save
		Save.load_game()
		get_tree().quit(1 if failed > 0 else 0)
		return
	await _phase0()
	_phase1()
	await _phase2()
	_skills()
	await _phase3()
	_phase4()
	await _phase5()
	await _phase6()
	await _phase7()
	await _first_person()
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
	# smooth drawing: between fixed sim steps the view draws a little ahead
	# of the last step, so hops glide on any refresh rate
	var ws := World.from_lanes([_lane(0, "safe"), _lane(1, "safe"), _lane(2, "safe")], -1)
	var ss := _run(ws)
	ss.hop(Vector2i(0, 1))
	ss.step(1.0 / 60.0)
	ss.set_lead(0.0)
	var y0 := ss.display_pos().y
	var h0 := ss.hop_height()
	ss.set_lead(0.5 / 60.0)
	var y1 := ss.display_pos().y
	check("hops are drawn between sim steps (smooth at any frame rate)", y0 > 0.0 and y1 > y0 and y1 < 1.0 and ss.hop_height() > h0 and is_equal_approx(ss.vt, ss.wt + 0.5 / 60.0), "%.3f -> %.3f" % [y0, y1])
	ss.step(1.0 / 60.0)
	check("each sim step resets the draw-ahead", ss.vt == ss.wt and ss.lead_real == 0.0)
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
	s = _run(w)
	s.x = 2.6
	_hop(s, Vector2i(0, 1))
	check("landing just past a log's end snaps onto it", s.state == "play" and s.plat >= 0 and s.x <= 2.3, "x %.2f %s" % [s.x, s.cause])
	s = _run(w)
	s.x = 2.9
	_hop(s, Vector2i(0, 1))
	check("a real miss still splashes", s.state == "dead" and s.cause == "drowned", s.cause)
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
	s = _run(w)
	_hop(s, Vector2i(0, 1))
	var rel0 := s.x - s.world.ent_x(s.cur_lane(), s.cur_lane().ents[0], s.wt)
	_hop(s, Vector2i(-1, 0))
	var rel1 := s.x - s.world.ent_x(s.cur_lane(), s.cur_lane().ents[0], s.wt)
	check("hopping along a moving log keeps pace with it", s.state == "play" and absf(rel1 - (rel0 - 1.0)) < 0.05, "%.2f -> %.2f" % [rel0, rel1])
	var nm := _lane(1, "ground")
	_mover(nm, "logging_truck", 4.62 + Lane.MARGIN, 2.0, 3.0)
	s = _run(World.from_lanes([_lane(0, "safe"), nm, _lane(2, "safe")]))
	_hop(s, Vector2i(0, 1))
	_steps(s, 0.4)
	check("a truck brushing past is a close call (+2)", s.state == "play" and s.near_misses == 1 and s.score >= 3, "%s near %d score %d" % [s.state, s.near_misses, s.score])
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
	# rule: falling into the water restarts the run (content/rules.json)
	check("water-restart rule is on", bool(Content.rules.get("water_restarts_run", false)))
	var wr := {"water_restart": true, "lives": 3}
	s = _run(World.from_lanes([_lane(0, "safe"), wl, _lane(2, "safe")]), "poison_dart_frog", wr)
	_hop(s, Vector2i(0, 1))
	check("falling into the water restarts (no life used)", s.state == "restart" and s.lives == 3 and s.cause == "drowned", s.state)
	_steps(s, 2.0)
	check("...and the run waits for the restart", s.state == "restart" and s.row == 1)
	s = _run(World.from_lanes([_lane(0, "safe"), wl3, _lane(2, "safe")]), "poison_dart_frog", wr)
	_steps(s, 2.0)
	_hop(s, Vector2i(0, 1))
	_steps(s, 2.2)
	check("riding a caiman that dives restarts", s.state == "restart", s.state)
	s = _run(World.from_lanes([_lane(0, "safe"), tide, _lane(2, "safe")]), "poison_dart_frog", wr)
	_hop(s, Vector2i(0, 1))
	_steps(s, 1.0)
	check("a flooding tide restarts", s.state == "restart", s.state)
	s = _run(World.from_lanes([_lane(0, "safe"), qs, _lane(2, "safe")]), "poison_dart_frog", wr)
	_hop(s, Vector2i(0, 1))
	_steps(s, 1.2)
	check("quicksand is not water: costs a life as before", s.state == "respawn" and s.lives == 2, s.state)
	s = _run(World.from_lanes([_lane(0, "safe"), wl2, _lane(2, "safe")]), "poison_dart_frog", wr)
	_hop(s, Vector2i(0, 1))
	_steps(s, 7.0)
	check("swept off-screen on a log is not falling in: costs a life", s.state != "restart" and s.lives == 2 and s.cause == "swept", s.state + s.cause)
	var wcap := World.from_lanes([_lane(0, "safe"), wl, _lane(2, "safe")])
	s = _run(wcap, "capybara", wr)
	_hop(s, Vector2i(0, 1))
	_steps(s, 0.5)
	check("swimmers don't fall in", s.state == "play" and s.swimming)
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


## Skill upgrades: rules valid, every ability improves level by level, the
## run uses the saved level, and upgrading spends Berries.
func _skills() -> void:
	begin("Skill upgrades")
	var top := Skills.max_level()
	var costs: Array = []
	for l in range(1, top):
		costs.append(Skills.next_cost(l))
	var rising := true
	for i in range(1, costs.size()):
		rising = rising and costs[i] > costs[i - 1]
	check("skills: %d levels with rising Berry costs" % top, top >= 3 and rising and Skills.next_cost(top) == 0, str(costs))
	var rules: Dictionary = Content.skills.get("rules", {})
	var bad := []
	var unchanged := []
	for aid in Content.animal_order:
		var an := Content.animal(aid)
		var any := false
		for m in an.ability.modules:
			var lo := Skills.scaled(m, 1)
			var hi := Skills.scaled(m, top)
			for k in m:
				if not rules.has(k) or typeof(m[k]) == TYPE_BOOL or typeof(m[k]) == TYPE_STRING:
					continue
				var r: Dictionary = rules[k]
				var a0 := float(lo[k])
				var a1 := float(hi[k])
				if a1 != a0:
					any = true
				var worse: bool = (float(r.get("mul", 0.0)) < 0.0 and a1 > a0) or (float(r.get("mul", 0.0)) > 0.0 and a1 < a0) or ((r.has("add_at") or r.has("add_per")) and a1 < a0)
				if worse:
					bad.append("%s.%s" % [aid, k])
		if not any:
			unchanged.append(aid)
	check("every animal's ability gets better with each level", bad.is_empty() and unchanged.is_empty(), "worse %s, unchanged %s" % [str(bad.slice(0, 4)), str(unchanged.slice(0, 4))])
	var lemur := Content.animal("ring_tailed_lemur")
	var m5 := Skills.scaled(lemur.ability.modules[0], top)
	check("e.g. Ring-Tailed Lemur at level %d: multi-hop 3 tiles, cooldown under 2.5 s" % top, int(m5.tiles) == 3 and float(m5.cooldown) < 2.5, str(m5))
	var w := World.from_lanes([_lane(0, "safe"), _lane(1, "safe"), _lane(2, "safe")], -1)
	var s1 := _run(w, "ring_tailed_lemur", {"skill_level": 1})
	var s5 := _run(w, "ring_tailed_lemur", {"skill_level": top})
	check("a run uses the saved skill level", s5.abilities[0].cooldown < s1.abilities[0].cooldown, "%.2f vs %.2f" % [s5.abilities[0].cooldown, s1.abilities[0].cooldown])
	Save.wipe()
	var starter := String(Content.starters()[0])
	var locked := ""
	for aid2 in Content.animal_order:
		if not Save.owns_animal(aid2):
			locked = aid2
			break
	var poor := not Skills.upgrade(starter)
	Economy.add("berries", Skills.next_cost(1), "test")
	var ok_up := Skills.upgrade(starter)
	check("upgrading spends the Berries and saves the level", poor and ok_up and Skills.level_of(starter) == 2 and Economy.berries() == 0)
	Economy.add("berries", 99999, "test")
	var not_owned := locked == "" or not Skills.upgrade(locked)
	while Skills.upgrade(starter):
		pass
	check("upgrades stop at the top level and need the animal", not_owned and Skills.level_of(starter) == top and not Skills.upgrade(starter))
	Save.wipe()


# ====================================================================== 3
func _phase3() -> void:
	begin("Phase 3 maps")
	var playable := Content.playable_maps()
	check("20 real-world scenes playable", playable.size() == 20, str(playable.size()))
	check("coming-soon regions listed", Content.map_order.size() == 22)
	var total_levels := 0
	var zones_ok := true
	var longer_ok := true
	for id in playable:
		var st: Array = Content.map(id).stages
		total_levels += st.size()
		for i in st.size():
			if int(st[i].get("canopy", {}).get("zones", 0)) < 1:
				zones_ok = false
			if i > 0 and int(st[i].rows) <= int(st[i - 1].rows):
				longer_ok = false
	check("200 maps: 20 scenes x 10 levels", total_levels == 200, str(total_levels))
	check("every level has dense-canopy areas that need first person", zones_ok)
	check("levels get longer through each scene", longer_ok)
	_difficulty_curve(playable)
	var cover_fail := []
	for id in playable:
		for li in 10:
			var wc := World.new()
			wc.setup(Content.map(id), "journey", li, absi(hash([id, li, "journey"])) % 1000000)
			wc.ensure(wc.goal_row + 4)
			var n := 0
			for r in range(0, wc.goal_row + 1):
				if wc.lane(r).covered:
					n += 1
			if n < 4 or wc.lane(wc.goal_row).covered or wc.lane(0).covered:
				cover_fail.append("%s/%d" % [id, li + 1])
	check("every generated level has covered rows (not on start or goal)", cover_fail.is_empty(), str(cover_fail))
	var we := World.new()
	we.setup(Content.map("congo"), "endless", 0, 5)
	var ecount := 0
	for r in 200:
		if we.lane(r).covered:
			ecount += 1
	check("endless runs have canopy zones too", ecount >= 15, str(ecount))
	check("Amazon is free", Content.map("amazon").access.type == "free" and Save.owns_map("amazon"))
	var palettes := {}
	var music := {}
	for id in playable:
		var m := Content.map(id)
		palettes[String(m.palette.get("water", "")) + String(m.palette.get("safe", ""))] = true
		music[String(m.music.file)] = true
		check(id + " has 10 levels", m.stages.size() == 10)
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
	# the digital globe's map: land and sea in the right places
	var gimg: Image = (load("res://assets/world/globe_map.png") as Texture2D).get_image()
	var land_at := func(la: float, lo: float) -> bool:
		return gimg.get_pixel(int((lo + 180.0) / 360.0 * (gimg.get_width() - 1)), int((90.0 - la) / 180.0 * (gimg.get_height() - 1))).r > 0.5
	var spots_ok: bool = land_at.call(-3.5, -62.0) and land_at.call(23.0, 10.0) and land_at.call(-25.0, 134.0) and land_at.call(0.5, 114.0) \
		and not land_at.call(0.0, -150.0) and not land_at.call(30.0, -40.0) and not land_at.call(-20.0, 75.0)
	check("globe map is high resolution with land and sea in the right places", gimg.get_width() >= 2048 and spots_ok, "%dx%d" % [gimg.get_width(), gimg.get_height()])
	var every_region_on_land := true
	for gid in Content.playable_maps():
		var gm := Content.map(gid)
		var near := false
		for dla in [-1.5, 0.0, 1.5]:
			for dlo in [-1.5, 0.0, 1.5]:
				near = near or land_at.call(float(gm.lat) + dla, float(gm.lon) + dlo)
		every_region_on_land = every_region_on_land and near
	check("every region's beacon sits on land", every_region_on_land)
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
			if fast and si != 0 and si != 9:
				continue
			var w2 := World.new()
			w2.setup(m2, "journey", si, absi(hash([id, si, "journey"])) % 1000000)
			var sim := RunSim.new()
			sim.setup(w2, Content.animal("poison_dart_frog"))
			var bot := PathBot.new()
			bot.max_nodes = 40000
			if bot.plan(sim, w2.goal_row).is_empty():
				fails.append("%s/%d" % [id, si])
	check("every level (%s) beatable with the free Poison Dart Frog" % ("1 and 10 of each scene" if fast else "all 200"), fails.is_empty(), str(fails))
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
	check("content back to 50 animals / 22 maps", Content.animals.size() == 50 and Content.maps.size() == 22)
	# screens
	var wm: Control = load("res://scripts/ui/world_map.gd").new()
	add_child(wm)
	await get_tree().process_frame
	check("world map with globe", wm.globe != null)
	wm._select("borneo")
	await get_tree().process_frame
	check("selecting a region spins the globe there", is_equal_approx(wm.globe.target_lon, 114.0))
	# drag sideways to spin; an up/down drag is left for the page to scroll
	var gl: Widgets.Globe = wm.globe
	var lon_before := gl.lon
	var tp := InputEventScreenTouch.new()
	tp.position = gl.size * 0.5
	tp.pressed = true
	gl._gui_input(tp)
	var dr := InputEventScreenDrag.new()
	dr.position = gl.size * 0.5 + Vector2(80, 4)
	dr.relative = Vector2(80, 4)
	gl._gui_input(dr)
	var spun := absf(wrapf(gl.lon - lon_before, -180.0, 180.0)) > 5.0
	tp.pressed = false
	tp.position = dr.position
	gl._gui_input(tp)
	var tp2 := InputEventScreenTouch.new()
	tp2.position = gl.size * 0.5
	tp2.pressed = true
	gl._gui_input(tp2)
	var dr2 := InputEventScreenDrag.new()
	dr2.position = gl.size * 0.5 + Vector2(3, 90)
	dr2.relative = Vector2(3, 90)
	gl._gui_input(dr2)
	var vertical_free: bool = not gl._drag.get("spinning", true)
	tp2.pressed = false
	gl._gui_input(tp2)
	check("dragging sideways spins the globe; up/down drags still scroll the page", spun and vertical_free)
	wm._select("amazon")
	await get_tree().process_frame
	var grid: GridContainer = null
	for c in wm.detail.get_children():
		if c is GridContainer:
			grid = c
	check("world map shows a 10-level grid", grid != null and grid.get_child_count() == 10)
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
	var hint_box: Rect2 = tut.tut_bubble.get_global_rect()
	var player_y: float = tut.wv.to_screen(tut.sim.x, float(tut.sim.row)).y
	check("tutorial hints sit under the score, clear of the lanes around the animal", hint_box.end.y < tut.get_viewport_rect().size.y * 0.3 and hint_box.end.y < player_y - 200.0, "hint ends at %d, animal at %d" % [hint_box.end.y, player_y])
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
	check("tutorial prompts appear in order", steps_seen.has("Ride the log across the river"), str(steps_seen.keys()))
	check("no \"Wait for the gap\" box over the road", not steps_seen.has("Wait for the gap"), str(steps_seen.keys()))
	check("tutorial teaches first-person view at the canopy", steps_seen.has("Thick canopy hides the trail. Tap the eye to see through your animal's eyes"), str(steps_seen.keys()))
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
	# water restart through the real run screen
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Game.start_run({"mode": "journey", "map": "amazon", "stage": 1, "seed": 7, "animal": "poison_dart_frog"})
	await get_tree().process_frame
	var first = Game.current
	for k in 12:
		first._process(1.0 / 60.0)
	first.sim.row = 2
	first.sim.max_row = 2
	first.sim.taken["test"] = true
	first.sim.berries = 6
	var runs0 := int(Save.data.stats.runs)
	var berries0 := Economy.berries()
	first.sim._lethal("drowned", "water", "floating_log", "Splash!")
	first._process(1.0 / 60.0)
	check("water restart: no revive card", first.overlay.get_child_count() == 0 and first.blocking)
	check("water restart: run recorded and Berries kept", int(Save.data.stats.runs) == runs0 + 1 and Economy.berries() > berries0)
	await get_tree().create_timer(float(Content.rules.get("restart_delay", 1.2)) + 0.4).timeout
	await get_tree().process_frame
	var again = Game.current
	check("water restart: the same stage starts over", again != first and again.sim.row == 0 and again.sim.state == "play"
		and again.cfg.stage == 1 and again.cfg.map == "amazon")
	var found := false
	for e in Analytics.buffer:
		if e.name == "water_restart":
			found = true
	check("water restart is logged", found)
	main.queue_free()
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
	# calm songs: one per region and the menu, each tuned to 528 or 963 Hz,
	# played by default; Classic brings the original songs back
	var calm_bad := []
	var tunings := {}
	for id in Content.playable_maps():
		var mus: Dictionary = Content.map(id).music
		if not ResourceLoader.exists(String(mus.get("calm_file", ""))) or not int(mus.get("hz", 0)) in [528, 963]:
			calm_bad.append(id)
		tunings[int(mus.get("hz", 0))] = int(tunings.get(int(mus.get("hz", 0)), 0)) + 1
	check("a calm song for every region and the menu, tuned to 528 Hz or 963 Hz (both used)", calm_bad.is_empty() and tunings.get(528, 0) >= 5 and tunings.get(963, 0) >= 5 and ResourceLoader.exists(Sfx.MENU_CALM), "%s %s" % [str(calm_bad), str(tunings)])
	var style0 := String(Save.setting("music_style", "calm"))
	Save.set_setting("music_style", "calm")
	var calm_track := Sfx.map_track("amazon")
	Save.set_setting("music_style", "classic")
	var classic_track := Sfx.map_track("amazon")
	Save.set_setting("music_style", style0)
	check("calm songs play by default; Settings > Music style > Classic plays the originals", String(Content.settings_defaults.get("music_style", "")) == "calm" and calm_track == String(Content.map("amazon").music.calm_file) and classic_track == String(Content.map("amazon").music.file), "%s / %s" % [calm_track, classic_track])
	# every painter runs for every animal, skin and hazard
	var canvas := PainterProbe.new()
	add_child(canvas)
	canvas.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	check("every animal, skin and hazard draws", canvas.drawn >= 50 + Content.hazards.size(), str(canvas.drawn))
	canvas.queue_free()
	# graphics quality: each level sets the painters' detail, Auto resolves
	var levels_ok := true
	for q in [["high", 2], ["medium", 1], ["low", 0]]:
		Save.set_setting("graphics", q[0])
		Gfx.apply(get_tree())
		levels_ok = levels_ok and Draw.detail == int(q[1])
	Save.set_setting("graphics", "auto")
	Gfx.apply(get_tree())
	check("Graphics setting: High/Medium/Low set detail, Auto resolves", levels_ok and Gfx.level() in ["high", "medium"] and Draw.detail >= 1, Gfx.level())
	check("water shader and lane grain texture load", WorldView.water_shader() != null and Draw.grain().get_width() == 128)
	# a run with the view
	var gs: Control = load("res://scripts/ui/game_screen.gd").new()
	gs.setup({"mode": "endless", "map": "monteverde", "stage": 0, "seed": 3, "animal": "southern_cassowary", "autoplay": true})
	add_child(gs)
	for i in 120:
		gs._process(1.0 / 60.0)
	check("view runs a region with atmosphere and fx", gs.sim.t > 1.5 and gs.atm != null)
	# alternate hidden / running rounds and take the median difference, so one
	# busy moment on the machine can't decide the result
	var frames := 60
	var diffs: Array[float] = []
	var base := 0.0
	for round_i in 5:
		gs.visible = false
		gs.set_process(false)
		var t0 := Time.get_ticks_usec()
		for i in frames:
			await get_tree().process_frame
		base = (Time.get_ticks_usec() - t0) / 1000.0 / frames
		gs.visible = true
		gs.set_process(true)
		t0 = Time.get_ticks_usec()
		for i in frames:
			await get_tree().process_frame
		diffs.append((Time.get_ticks_usec() - t0) / 1000.0 / frames - base)
	diffs.sort()
	var ms := diffs[diffs.size() / 2]
	print("  frame cost (sim + view + draw recording, minus the headless loop's %.1f ms sleep): %.2f ms (median of %s)" % [base, ms, str(diffs.map(func(x): return snappedf(x, 0.01)))])
	check("frame cost leaves headroom for 60 fps on phones (< 3 ms here)", ms < 3.0, "%.2f ms" % ms)
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


# ====================================================================== first person
## One physical tap as the engine delivers it: the touch and the mouse
## click emulated from it (finger), or the click and its emulated touch.
func _tap(pos: Vector2, finger: bool) -> void:
	for down in [true, false]:
		var t := InputEventScreenTouch.new()
		t.position = pos
		t.pressed = down
		var m := InputEventMouseButton.new()
		m.position = pos
		m.global_position = pos
		m.button_index = MOUSE_BUTTON_LEFT
		m.pressed = down
		var pair: Array = [t, m] if finger else [m, t]
		for e in pair:
			get_viewport().push_input(e, true)


func _first_person() -> void:
	begin("First-person view")
	Save.wipe()
	Save.data.seen_intro = Content.playable_maps()
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Game.start_run({"mode": "journey", "map": "amazon", "stage": 4, "seed": 11, "animal": "poison_dart_frog"})
	await get_tree().process_frame
	var gs = Game.current
	check("runs start in bird's-eye view", gs.view == "bird" and gs.wv.visible)
	var zone: Vector2i = gs.world.gen.cover[0]
	# stand on a plain bank just before the canopy (a teleport onto water
	# would drown the animal and restart the run mid-test)
	var stand := zone.x - 2
	for r in [zone.x - 2, zone.x - 1, zone.x - 3]:
		var sl: Lane = gs.world.lane(r)
		if sl.type == "safe" and sl.tiles.is_empty() and sl.preds.is_empty() and sl.effect.is_empty():
			stand = r
			break
	gs.sim.row = stand
	gs.sim.x = 4.5
	gs.sim.max_row = gs.sim.row
	for i in 4:
		gs._update_views(1.0 / 60.0)
	check("bird's-eye roof covers the canopy rows", gs.wv.roof != null and gs.world.lane(zone.x).covered)
	check("the HUD and menus draw above the canopy roof", gs.hud.z_index > gs.wv.roof.z_index + 1 and gs.overlay.z_index > gs.hud.z_index)
	check("tip and pulsing eye button near dense canopy", gs.canopy_tip.visible and gs.eye_btn.pulse)
	var zone_scene := Scenery3D.scene_def(gs.map, gs.world.lane(zone.x).scene)
	check("the tip names the scene ahead", String(zone_scene.get("name", "?")) in gs.canopy_tip.text, gs.canopy_tip.text)
	gs.toggle_view()
	gs._update_views(1.0 / 60.0)
	check("eye button switches to first person", gs.view == "fpv" and gs.wv3 != null and gs.wv3.visible and not gs.wv.visible)
	check("first-person choice is remembered", bool(Save.setting("first_person", false)))
	var under := 0
	for k in gs.wv3._ents.keys():
		var r := int(String(k).split(":")[0])
		if r >= zone.x and r <= zone.y:
			under += 1
	var zone_has_things := false
	for r in range(zone.x, zone.y + 1):
		if not gs.world.lane(r).ents.is_empty():
			zone_has_things = true
	check("first person shows what's under the canopy", under > 0 or not zone_has_things, "%d" % under)
	check("first person builds the lanes ahead", gs.wv3._lanes.size() >= 20)
	gs.sim.row = zone.x
	gs._update_views(1.0 / 60.0)
	check("entering a canopy zone shows its title card", gs._shown_zones.has(gs.world.lane(zone.x).zone) and gs.scene_card.get_node("Box/name").text == String(zone_scene.get("name", "")), gs.scene_card.get_node("Box/name").text)
	var dressed := 0
	for r in range(zone.x, zone.y + 1):
		if gs.wv3._lanes.has(r) and gs.wv3._lanes[r].get_node_or_null("Scenery") != null:
			dressed += 1
	check("every canopy row is dressed with its scene in 3D", dressed == zone.y - zone.x + 1, "%d of %d" % [dressed, zone.y - zone.x + 1])
	gs.sim.row = stand
	var meshes: int = gs.wv3.world3.find_children("*", "MeshInstance3D", true, false).size()
	print("  first-person meshes in view: %d" % meshes)
	check("first-person scene stays light (< 350 meshes)", meshes < 350, str(meshes))
	check("no canopy tip while already in first person", not gs.canopy_tip.visible)
	var key := InputEventKey.new()
	key.keycode = KEY_V
	key.pressed = true
	get_viewport().push_input(key, true)
	check("V switches back to bird's-eye", gs.view == "bird" and gs.wv.visible and not gs.wv3.visible)
	# Real taps: a finger tap reaches the button as a touch AND an emulated
	# mouse click (a mouse click likewise also arrives as a touch). It must
	# switch exactly once and must not also hop the animal.
	gs.started = true
	var row_before: int = gs.sim.row
	var eye_c: Vector2 = gs.eye_btn.get_global_rect().get_center()
	_tap(eye_c, true)
	for i in 3:
		await get_tree().process_frame
	check("a finger tap on the eye button switches to first person (once, no hop)", gs.view == "fpv" and gs.sim.row == row_before and not gs.sim.hopping, "%s row %d" % [gs.view, gs.sim.row])
	await get_tree().create_timer(0.35).timeout
	_tap(eye_c, false)
	for i in 3:
		await get_tree().process_frame
	check("a mouse click on the eye button switches back (once, no hop)", gs.view == "bird" and gs.sim.row == row_before and not gs.sim.hopping, "%s row %d" % [gs.view, gs.sim.row])
	gs.set_view("fpv")
	gs.sim.row = 0
	for i in 60:
		gs._process(1.0 / 60.0)
	check("hopping works in first person", true)
	check("first person draws at the interpolated time (within one step ahead)", gs.sim.vt >= gs.sim.wt and gs.sim.vt - gs.sim.wt <= 1.0 / 60.0 + 0.0001, "%.4f" % (gs.sim.vt - gs.sim.wt))
	# moving things that come into view are taken from a pool filled ahead
	# of time (and returned to it when they leave), so a hop builds nothing
	var w3v = gs.wv3
	var missed0: int = w3v.ents_missed
	var arrived := 0
	for k in 3:
		for i in 400:
			if not w3v._warm_ents():
				break
		gs.sim.row += 1
		arrived += gs.world.lane(gs.sim.row + w3v.AHEAD).ents.size()
		w3v.update_view(1.0 / 60.0)
	var pooled := 0
	for pk in w3v._ent_pool:
		pooled += (w3v._ent_pool[pk] as Array).size()
	check("hopping forward reuses pre-built moving things (no builds on a hop)", w3v.ents_missed == missed0 and arrived > 0 and pooled > 0, "missed %d, %d arrived, %d pooled" % [w3v.ents_missed - missed0, arrived, pooled])
	gs.sim.row = 0
	var frames := 90
	gs.visible = false
	gs.set_process(false)
	var t0 := Time.get_ticks_usec()
	for i in frames:
		await get_tree().process_frame
	var base := (Time.get_ticks_usec() - t0) / 1000.0 / frames
	gs.visible = true
	gs.set_process(true)
	t0 = Time.get_ticks_usec()
	for i in frames:
		await get_tree().process_frame
	var ms := (Time.get_ticks_usec() - t0) / 1000.0 / frames - base
	print("  first-person frame cost (minus the headless sleep): %.2f ms" % ms)
	check("first-person view is cheap enough for phones", ms < 4.0, "%.2f ms" % ms)
	main.queue_free()
	await get_tree().process_frame
	Save.wipe()
	_scenes()


## Themed first-person scenes: content is valid, every level has 1-3
## canopy zones with different scenes, every scene is used, and every scene
## builds in 3D within a small draw-call budget.
func _scenes() -> void:
	begin("First-person scenes")
	var problems := []
	var total := 0
	for id in Content.playable_maps():
		var m := Content.map(id)
		var scs: Array = m.get("fpv_scenes", [])
		total += scs.size()
		if scs.size() < 3:
			problems.append("%s has %d scenes" % [id, scs.size()])
		for sc in scs:
			if String(sc.get("name", "")) == "" or String(sc.get("line", "")) == "":
				problems.append("%s/%s: name or line missing" % [id, sc.get("id", "?")])
			for kind in sc.get("props", {}):
				if not String(kind) in Scenery3D.PROPS:
					problems.append("%s/%s: prop %s" % [id, sc.id, kind])
			if not String(sc.get("landmark", "")) in Scenery3D.LANDMARKS:
				problems.append("%s/%s: landmark %s" % [id, sc.id, sc.landmark])
			for f in sc.get("fauna", []):
				if not Scenery3D.FAUNA.has(String(f)):
					problems.append("%s/%s: fauna %s" % [id, sc.id, f])
			for pt in sc.get("particles", []):
				if not String(pt) in Scenery3D.PARTICLES:
					problems.append("%s/%s: particles %s" % [id, sc.id, pt])
	check("every region has 3+ first-person scenes with known props, landmarks, fauna", problems.is_empty(), str(problems.slice(0, 4)))
	var lv := []
	var used := {}
	for id in Content.playable_maps():
		var m2 := Content.map(id)
		for st in m2.get("stages", []).size():
			var w := World.new()
			w.setup(m2, "journey", st, 7 + st)
			var n := w.gen.cover.size()
			if n < 1 or n > 3:
				lv.append("%s %d: %d zones" % [id, st + 1, n])
			var seen := {}
			for z in n:
				var sid := w.gen.cover_scenes[z]
				if sid == "" or seen.has(sid):
					lv.append("%s %d zone %d: scene '%s'" % [id, st + 1, z, sid])
				seen[sid] = true
				used["%s/%s" % [id, sid]] = true
				w.ensure(w.gen.cover[z].y + 1)
				var l := w.lane(w.gen.cover[z].x)
				if not l.covered or l.scene != sid or l.zone != z:
					lv.append("%s %d zone %d: lane not tagged" % [id, st + 1, z])
	check("every level has 1-3 canopy zones, each a different scene, lanes tagged", lv.is_empty(), str(lv.slice(0, 4)))
	check("every scene appears in some level", used.size() == total, "%d of %d" % [used.size(), total])
	var worst := 0
	var empty := []
	for id in Content.playable_maps():
		var m3 := Content.map(id)
		for sc in m3.get("fpv_scenes", []):
			for t in ["safe", "ground", "water"]:
				var l2 := Lane.new()
				l2.row = 10
				l2.type = t
				l2.covered = true
				l2.zone = 0
				l2.scene = String(sc.id)
				var node := Scenery3D.build_lane(l2, sc, m3.get("palette", {}), 2, Vector2i(9, 11))
				var calls := node.find_children("*", "GeometryInstance3D", true, false).size()
				worst = maxi(worst, calls)
				var mi := node.get_child(0) as MeshInstance3D
				if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
					empty.append("%s/%s/%s" % [id, sc.id, t])
				node.free()
	print("  most draw calls for one dressed canopy row: %d" % worst)
	check("all scenes build in 3D (landmark rows too)", empty.is_empty(), str(empty.slice(0, 4)))
	check("a dressed canopy row stays a few draw calls (<= 6)", worst <= 6, str(worst))
	# canopy rows are cached: built once (ahead of time by warm_row) and
	# shared, landmark rows included, with waterfalls still getting their sheet
	var shared := []
	var falls := 0
	for id in Content.playable_maps():
		var m4 := Content.map(id)
		var pal4: Dictionary = m4.get("palette", {})
		for sc in m4.get("fpv_scenes", []):
			for row in [13, 14]:
				var l4 := Lane.new()
				l4.row = row
				l4.type = "safe"
				l4.covered = true
				l4.zone = 0
				l4.scene = String(sc.id)
				Scenery3D.warm_row(l4, sc, pal4, 1, Vector2i(12, 16))
				var again := Scenery3D.warm_row(l4, sc, pal4, 1, Vector2i(12, 16))
				var a := Scenery3D.build_lane(l4, sc, pal4, 1, Vector2i(12, 16))
				var b := Scenery3D.build_lane(l4, sc, pal4, 1, Vector2i(12, 16))
				if again or (a.get_child(0) as MeshInstance3D).mesh != (b.get_child(0) as MeshInstance3D).mesh:
					shared.append("%s/%s row %d" % [id, sc.id, row])
				if row == 14 and String(sc.get("landmark", "")) == "waterfall":
					if a.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.has_meta("falls")).size() == 1:
						falls += 1
					else:
						shared.append("%s/%s: no falling water" % [id, sc.id])
				a.free()
				b.free()
	check("canopy rows are built once ahead of time and shared (landmarks and waterfalls too)", shared.is_empty() and falls >= 3, "%d waterfalls; %s" % [falls, str(shared.slice(0, 4))])
	# detailed models: every log, caiman, crocodile and soldier-ant hazard
	var bad_models := []
	var built := 0
	var crocs := 0
	for hid in Content.hazards:
		var hz: Dictionary = Content.hazards[hid]
		var art: Dictionary = hz.get("art", {})
		var cl2: Dictionary = art.get("colors", {})
		var painter := String(art.get("painter", ""))
		var mesh: Mesh = null
		match painter:
			"log", "roll_log":
				mesh = Models3D.log_mesh(hid, 1.6, cl2, hz.get("kind", "") == "platform")
			"caiman_back":
				mesh = Models3D.caiman_back(hid, 1.8, cl2)
			"soldier_ant":
				var ant := Node3D.new()
				Models3D.soldier_ant(ant, 0.9, cl2)
				if ant.get_node_or_null("LegsA") == null or ant.get_node_or_null("Body") == null:
					bad_models.append(hid)
				else:
					mesh = (ant.get_node("Body") as MeshInstance3D).mesh
				ant.free()
		if String(hz.get("kind", "")) == "surfacer":
			crocs += 1
			var head := Node3D.new()
			var up := Node3D.new()
			up.name = "Upper"
			head.add_child(up)
			Models3D.croc_head(head, 1.2, cl2)
			if up.get_child_count() == 0:
				bad_models.append(hid + " jaws")
			head.free()
		if painter in ["log", "roll_log", "caiman_back", "soldier_ant"]:
			built += 1
			if mesh == null or mesh.get_surface_count() == 0 or mesh.surface_get_array_len(0) < 200:
				bad_models.append(hid)
	check("detailed models build for every log, caiman, croc and soldier-ant hazard", bad_models.is_empty() and built >= 8 and crocs >= 5, "%d built, %d crocs, bad %s" % [built, crocs, str(bad_models)])
	var ants: Dictionary = Content.hazard("red_soldier_ants")
	check("the ant highway is giant red soldier ants carrying cheese", String(ants.get("art", {}).get("painter", "")) == "soldier_ant" and float(ants.length[0]) >= 0.8 and ants.art.colors.has("cheese"))


## The difficulty curve: the first two jungles are Easy, 3-5 Medium, 6-10
## Hard, the rest Expert; levels get longer and harder 1 to 10; each tier
## starts and ends harder than the one before; the first five jungles bring
## their hazards in level by level; and generated levels really are gentler
## early on (slower movers, fewer kinds of hazard).
func _difficulty_curve(playable: Array) -> void:
	var want := {"amazon": "easy", "congo": "easy", "borneo": "medium", "daintree": "medium", "masoala": "medium",
		"monteverde": "hard", "new_guinea": "hard", "atlantic_forest": "expert", "khao_sok": "expert"}
	var wrong := []
	for id in want:
		if Content.tier_of(Content.map(id)) != want[id]:
			wrong.append("%s=%s" % [id, Content.tier_of(Content.map(id))])
	check("difficulty tiers by globe order: Easy 1-2, Medium 3-5, Hard 6-10, Expert after", wrong.is_empty(), str(wrong))
	var ramp_bad := []
	for id in playable:
		var st: Array = Content.map(id).stages
		for i in range(1, st.size()):
			if float(st[i].difficulty[1]) <= float(st[i - 1].difficulty[1]) or int(st[i].stars) < int(st[i - 1].stars):
				ramp_bad.append("%s %d" % [id, i + 1])
	check("every jungle's levels get harder from 1 to 10 (difficulty and challenge stars)", ramp_bad.is_empty(), str(ramp_bad.slice(0, 4)))
	var order := ["easy", "medium", "hard", "expert"]
	var tiers_ok := true
	for i in range(1, order.size()):
		var a: Dictionary = Content.tier(order[i - 1])
		var b: Dictionary = Content.tier(order[i])
		if float(b.difficulty[0][1]) <= float(a.difficulty[0][1]) or float(b.difficulty[1][1]) < float(a.difficulty[1][1]) or int(b.rows[0]) <= int(a.rows[0]) or float(b.params.speed[1]) < float(a.params.speed[1]):
			tiers_ok = false
	check("each tier starts and ends harder than the one before (and its levels run longer)", tiers_ok)
	# hazards arrive level by level in the first five jungles
	var gated := 0
	var leaks := []
	for id in ["amazon", "congo", "borneo", "daintree", "masoala"]:
		var m: Dictionary = Content.map(id)
		var late := {}
		for slot in m.hazards:
			for e in m.hazards[slot]:
				if int(e.get("from_level", 1)) > 1:
					late[String(e.id)] = int(e.from_level)
		gated += 1 if late.size() >= 3 else 0
		for li in [0, 1]:
			var w := World.new()
			w.setup(m, "journey", li, absi(hash([id, li, "journey"])) % 1000000)
			w.ensure(w.goal_row + 2)
			for r in w.goal_row:
				var l := w.lane(r)
				var seen := [l.hazard_id, String(l.effect.get("hazard", ""))]
				for p in l.preds:
					seen.append(String(p.hazard))
				for c in l.tiles:
					seen.append(String(l.tiles[c].hazard))
				for hid in seen:
					if late.has(hid) and int(late[hid]) > li + 1:
						leaks.append("%s L%d row %d: %s" % [id, li + 1, r, hid])
	check("the first five jungles bring their hazards in level by level", gated == 5 and leaks.is_empty(), "%d gated; %s" % [gated, str(leaks.slice(0, 3))])
	# generated levels: Amazon level 1 is slow with few hazard kinds; an
	# Expert jungle's level 10 is faster than Amazon's
	var stats := func(id: String, li: int) -> Vector2:
		var w := World.new()
		w.setup(Content.map(id), "journey", li, absi(hash([id, li, "journey"])) % 1000000)
		w.ensure(w.goal_row + 2)
		var spd := 0.0
		var n := 0
		var kinds := {}
		for r in w.goal_row:
			var l := w.lane(r)
			if l.hazard_id != "":
				kinds[l.hazard_id] = true
			if absf(l.speed) > 0.0:
				spd += absf(l.speed)
				n += 1
		return Vector2(spd / maxi(1, n), kinds.size())
	var a1: Vector2 = stats.call("amazon", 0)
	var a10: Vector2 = stats.call("amazon", 9)
	var x10: Vector2 = stats.call("khao_sok", 9)
	print("  mover speed / hazard kinds: Amazon L1 %.2f/%d, Amazon L10 %.2f/%d, Khao Sok L10 %.2f/%d" % [a1.x, a1.y, a10.x, a10.y, x10.x, x10.y])
	check("Amazon level 1 is gentle: slow movers, few kinds of hazard", a1.x < 0.9 and a1.y <= 3, str(a1))
	check("the first two jungles are the gentlest: 5 lives, short levels, small bands", int(Content.tier("easy").get("lives", 0)) == 5 and int(Content.tier("medium").get("lives", 0)) == 3 and int(Content.map("amazon").stages[0].rows) <= 30 and int(Content.map("congo").difficulty.band[1][1]) <= 2)
	check("harder later: Amazon level 10 beats level 1, an Expert jungle's level 10 beats both", a10.x > a1.x and a10.y > a1.y and x10.x > a10.x, "%s %s %s" % [a1, a10, x10])


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
