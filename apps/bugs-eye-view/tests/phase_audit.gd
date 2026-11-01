extends TestBase
## Phase-by-phase audit of the build spec (deeper than the smoke test).
##   godot --headless --path . res://tests/phase_audit.tscn --fixed-fps 60
## Pass "-- --phase=N" to run one phase.


func _ready() -> void:
	SaveSystem.save_path = "user://phase_audit_save.json"
	SaveSystem.data = SaveSystem.default_data()
	await get_tree().process_frame
	var only := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--phase="):
			only = int(a.substr(8))
	print("== Bug's-Eye View phase audit ==")
	if only in [0, 1]:
		await _phase1()
	if only in [0, 2]:
		await _phase2()
	finish("phase audit")


# --- Phase 1: vertical slice + stealth foundation ------------------------------

func _phase1() -> void:
	print("-- Phase 1: cockroach, kitchen, input, stealth foundation")
	var lvl := await load_level(&"kitchen", &"cockroach")
	var p := lvl.player as Cockroach
	await frames(15)

	# Keyboard drives movement through InputRouter (gameplay never reads raw input).
	face(lvl, 0.0)
	var start := p.global_position
	key(KEY_W, true)
	await frames(30)
	check(InputRouter.get_move_vector().y > 0.9, "W key becomes a forward move action")
	key(KEY_W, false)
	await frames(5)
	check(p.global_position.z < start.z - 3.0, "keyboard moves the roach forward (dz=%.1f)" % (p.global_position.z - start.z))
	var y0 := p.global_position.y
	key(KEY_SPACE, true)
	await frames(6)
	key(KEY_SPACE, false)
	check(p.global_position.y > y0 + 0.15 or p.velocity.y > 1.0, "Space makes the roach hop")
	await frames(30)

	# Touch: joystick drag and an on-screen button.
	SaveSystem.set_setting("touch_controls", "on")
	var tc := lvl.find_child("*", true, false)
	tc = null
	for n in lvl.find_children("*", "Control", true, false):
		if n is TouchControls:
			tc = n
	check(tc != null and (tc as TouchControls).visible, "touch controls show when touch mode is on")
	var tcs := tc as TouchControls
	var stick_at := Vector2(tcs.size.x * 0.15, tcs.size.y * 0.85)
	touch(0, stick_at, true)
	drag(0, stick_at + Vector2(0, -80), Vector2(0, -80))
	await frames(2)
	check(InputRouter.get_move_vector().y > 0.5, "dragging the joystick up moves forward (%.2f)" % InputRouter.get_move_vector().y)
	start = p.global_position
	await frames(30)
	check(p.global_position.distance_to(start) > 2.0, "joystick moves the roach")
	touch(0, stick_at + Vector2(0, -80), false)
	await frames(2)
	check(InputRouter.get_move_vector().length() < 0.01, "releasing the joystick stops input")
	var pressed := [false]
	var on_press := func(a: StringName) -> void:
		if a == &"jump":
			pressed[0] = true
	InputRouter.action_pressed.connect(on_press)
	var jump_at: Vector2 = tcs._btn_pos[&"jump"]
	touch(1, jump_at, true)
	await frames(2)
	touch(1, jump_at, false)
	InputRouter.action_pressed.disconnect(on_press)
	check(pressed[0], "tapping the Hop button sends the jump action")
	var aimed := [false]
	var on_aim := func(_pos: Vector2) -> void:
		aimed[0] = true
	InputRouter.aim_at_screen.connect(on_aim)
	var look_at := Vector2(tcs.size.x * 0.6, tcs.size.y * 0.35)
	touch(2, look_at, true)
	await frames(1)
	touch(2, look_at, false)
	await frames(2)
	InputRouter.aim_at_screen.disconnect(on_aim)
	check(aimed[0], "a quick tap on open screen sends an aim point")
	SaveSystem.set_setting("touch_controls", "off")
	await frames(5)

	# The human actually walks its route during breakfast.
	var human := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	p.global_position = Vector3(43, 0.6, -30)
	InputRouter.set_touch_action(&"secondary", true)
	var foot0 := human.left_foot.global_position
	var body0 := human.global_position
	await frames(240)
	check(human.left_foot.global_position.distance_to(foot0) > 4.0, "the human's feet step along the route")
	check(human.global_position.distance_to(body0) > 4.0, "the human's body follows its feet")
	check(PerceptionSystem.visibility == 0.0, "the squeezed roach stays hidden under the fridge meanwhile")
	InputRouter.set_touch_action(&"secondary", false)
	await frames(5)

	# Cockroach senses.
	p.global_position = Vector3(10, 0.8, 10)
	await frames(10)
	p.sense_meter = p.stats.sense_max
	p.toggle_sense()
	await frames(20)
	var arrow := p.get_node("SenseArrow") as Node3D
	var nearest: Crumb = null
	var best := 1e9
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		var crumb := c as Crumb
		if crumb and not crumb.taken and lvl.is_ancestor_of(crumb):
			var d := crumb.global_position.distance_to(p.global_position)
			if d < best:
				best = d
				nearest = crumb
	var to := nearest.global_position - p.global_position
	to.y = 0.0
	var fwd := -arrow.global_basis.z
	fwd.y = 0.0
	check(arrow.visible and fwd.normalized().dot(to.normalized()) > 0.95, "smell: the antennae arrow points at the nearest crumb")
	p.toggle_sense()
	check(not arrow.visible, "smell turns off again")
	p.global_position = Vector3(-10, 0.8, 14)
	await frames(15)
	p.global_position = Vector3(-46, 0.8, 0)
	await frames(3)
	check(p._scatter > 0.0, "stepping from shade into the sunbeam triggers a scatter burst")
	human.route = PackedVector3Array()
	p.global_position = human.global_position + Vector3(10, 0.8, 0)
	human.force_alert(AlertState.SUSPICIOUS, p.global_position + Vector3(5, 0, 5))
	await frames(60)
	check(p.is_playing_dead(), "frozen next to a suspicious human, the roach plays dead")

	# Feedback: an impact near the player shakes the camera.
	lvl.camera._shake_time = 0.0
	Feedback.impact_at(p.global_position, 1.0)
	await frames(1)
	check(lvl.camera._shake_time > 0.0, "a nearby impact shakes the camera")
	await unload(lvl)

	# Every room can be finished on foot: crumbs and the exit are on the walkable floor.
	for level in GameManager.LEVEL_IDS:
		lvl = await load_level(level, &"cockroach")
		await frames(5)
		var map := lvl.get_world_3d().navigation_map
		var spawn := (lvl.find_child("PlayerSpawn", true, false) as Node3D).global_position
		var reachable := 0
		for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
			var crumb := c as Crumb
			if crumb and not crumb.golden and lvl.is_ancestor_of(crumb):
				var path := NavigationServer3D.map_get_path(map, spawn, crumb.global_position, true)
				if path.size() > 0 and Vector2(path[-1].x - crumb.global_position.x, path[-1].z - crumb.global_position.z).length() < 3.5:
					reachable += 1
		check(reachable >= lvl.crumbs_needed, "%s: %d floor crumbs reachable on foot (need %d)" % [level, reachable, lvl.crumbs_needed])
		var gpath := NavigationServer3D.map_get_path(map, spawn, lvl.goal.global_position, true)
		check(gpath.size() > 0 and Vector2(gpath[-1].x - lvl.goal.global_position.x, gpath[-1].z - lvl.goal.global_position.z).length() < 4.5,
			"%s: the exit is reachable on foot" % level)
		await unload(lvl)


# --- Phase 2: full bug roster, bug select, unlocks ---------------------------------

func _phase2() -> void:
	print("-- Phase 2: fly, spider, bug select and unlocks")
	SaveSystem.data = SaveSystem.default_data()
	var lvl := await load_level(&"kitchen", &"fly")
	var f := lvl.player as Fly
	await frames(10)

	# Flight: boost is faster, buzz gets louder with speed.
	f.take_off()
	face(lvl, PI)
	f.stamina = f.stats.stamina_max
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(60)
	var cruise := f.velocity.length()
	var cruise_noise := f.current_noise()
	InputRouter.set_touch_action(&"primary", true)
	await frames(60)
	var boost := f.velocity.length()
	var boost_noise := f.current_noise()
	InputRouter.set_touch_action(&"primary", false)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(boost > cruise * 1.2, "fly boost is faster than cruising (%.1f > %.1f)" % [boost, cruise])
	check(boost_noise > cruise_noise, "the buzz is louder at speed (%.2f > %.2f)" % [boost_noise, cruise_noise])

	# Perch on the kitchen table by holding descend above it.
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-12, 36, 14)))
	f.stamina = f.stats.stamina_max
	await frames(5)
	InputRouter.set_touch_action(&"secondary", true)
	for i in 180:
		await get_tree().physics_frame
		if not f.flying:
			break
	InputRouter.set_touch_action(&"secondary", false)
	await frames(30)
	check(not f.flying and f.global_position.y > 30.0 and f.global_position.y < 34.0,
		"holding descend lands the fly on the table (y=%.1f)" % f.global_position.y)
	f.stamina = 2.0
	var before := f.stamina
	await frames(60)
	check(f.stamina > before, "a perched fly regains stamina")
	check(f.is_scent_active(), "a perched fly leaves scent again")
	f.stamina = 0.2
	f.take_off()
	check(not f.flying, "a tired fly can't take off")
	await unload(lvl)

	# Spider: ceilings, edges, leaping, real web aim.
	lvl = await load_level(&"kitchen", &"spider")
	var s := lvl.player as Spider
	await frames(10)
	s.teleport_to(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 99.6, 0)))
	await frames(60)
	check(s.attached and s.surface_normal.y < -0.9 and s.global_position.y > 98.0, "the spider clings to the ceiling")
	face(lvl, 0.0)
	var c0 := s.global_position
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(40)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(s.global_position.distance_to(c0) > 2.0 and s.global_position.y > 98.0, "the spider walks along the ceiling without falling")

	s.teleport_to(Transform3D(Basis.IDENTITY, Vector3(4, 32.0, 14)))
	await frames(10)
	face(lvl, -PI * 0.5)
	InputRouter.set_touch_move(Vector2(0, 1))
	for i in 120:
		await get_tree().physics_frame
		if s.surface_normal.y < 0.5:
			break
	InputRouter.set_touch_move(Vector2.ZERO)
	check(s.attached and s.surface_normal.y < 0.5, "walking off the table edge wraps the spider onto its side")

	s.teleport_to(Transform3D(Basis.IDENTITY, Vector3(30, 0.6, 20)))
	await frames(10)
	s._jump_queued = true
	await frames(4)
	check(not s.attached, "leaping lets go of the surface")
	await frames(90)
	check(s.attached, "the spider grabs the next surface it lands on")

	s.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.6, 30)))
	await frames(5)
	lvl.camera.yaw = -PI * 0.5
	lvl.camera.pitch = 0.0
	lvl.camera.snap()
	await frames(3)
	s._web_cd = 0.0
	s._fire_web(lvl.camera.screen_center())
	check(s.zipping, "firing at the reticle starts a web zip toward the wall")
	for i in 120:
		await get_tree().physics_frame
		if not s.zipping:
			break
	check(s.attached and s.surface_normal.x < -0.5, "the zip ends attached to the far wall")

	var spoon := lvl.find_child("Spoon", true, false) as LureProp
	s.teleport_to(Transform3D(Basis.IDENTITY, spoon.global_position + Vector3(8, 0.3, 4)))
	await frames(10)
	var to_spoon := spoon.global_position - s.global_position
	lvl.camera.yaw = atan2(-to_spoon.x, -to_spoon.z)
	lvl.camera.pitch = -0.35
	lvl.camera.snap()
	await frames(3)
	var lures := lvl.run.lures_used
	s._web_cd = 0.0
	s._fire_web(lvl.camera.camera.unproject_position(spoon.global_position))
	await frames(2)
	check(lvl.run.lures_used > lures, "a web line can trip the spoon from a distance (a lure)")
	await unload(lvl)

	lvl = await load_level(&"living_room", &"spider")
	var cat := first_in_group(Phys.GROUP_PET, lvl) as Pet
	var trap := (load("res://scenes/bugs/web_trap.tscn") as PackedScene).instantiate() as WebTrap
	lvl.add_child(trap)
	trap.setup(cat.global_position, Vector3.UP, 5.0, null)
	await frames(5)
	check(cat.web_time > 0.0 and cat.speed_mult() < 0.5, "a web trap slows the cat")
	await unload(lvl)

	# Bug select / unlock persistence.
	SaveSystem.data = SaveSystem.default_data()
	var texts := await _button_texts("res://scenes/ui/bug_select.tscn")
	check(texts.has("Play as Cockroach") and not texts.has("Play as Fly") and not texts.has("Play as Spider"),
		"bug select offers only the cockroach at first")
	SaveSystem.unlock_bug(&"fly")
	SaveSystem.save_game()
	SaveSystem.load_game()
	check(SaveSystem.is_bug_unlocked(&"fly"), "an unlocked bug survives save and reload")
	texts = await _button_texts("res://scenes/ui/bug_select.tscn")
	check(texts.has("Play as Fly"), "bug select offers the fly once unlocked")
	GameManager.current_level = &"living_room"
	GameManager.begin_run(RunStats.new())
	GameManager.run.crumbs = 9
	GameManager.finish_run(true)
	check(SaveSystem.is_bug_unlocked(&"spider"), "escaping the living room unlocks the spider")

	# Time slots unlock after a room is escaped, and each slot plays.
	SaveSystem.data = SaveSystem.default_data()
	var ls: Node = (load("res://scenes/ui/level_select.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(ls)
	await frames(2)
	var night_locked := _find_button(ls, "Night")
	check(night_locked != null and night_locked.disabled, "night is locked before the kitchen is escaped")
	ls.queue_free()
	SaveSystem.record_level_result(&"kitchen", true, 100, 100.0, {})
	ls = (load("res://scenes/ui/level_select.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(ls)
	await frames(2)
	var night_open := _find_button(ls, "Night")
	check(night_open != null and not night_open.disabled, "night unlocks after escaping the kitchen")
	ls.queue_free()
	await frames(2)
	for slot in [&"afternoon", &"night"]:
		lvl = await load_level(&"kitchen", &"cockroach", slot)
		await frames(30)
		check(is_equal_approx(floorf(HouseClock.hour), floorf(HouseClock.slot_hour(slot))), "kitchen %s starts at %s" % [slot, HouseClock.clock_text()])
		if slot == &"night":
			HouseClock.set_hour(22.5)
			await frames(70)
			check(PerceptionSystem.ambient_light <= 0.25, "lights out makes the kitchen dark (ambient %.2f)" % PerceptionSystem.ambient_light)
		await unload(lvl)


func _button_texts(path: String) -> PackedStringArray:
	var n: Node = (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(n)
	await frames(2)
	var out: PackedStringArray = []
	for b in n.find_children("*", "Button", true, false):
		out.append((b as Button).text)
	n.queue_free()
	await frames(1)
	return out


func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null
