extends TestBase
## Phase-by-phase audit of the build spec (deeper than the smoke test).
##   godot --headless --path . res://tests/phase_audit.tscn --fixed-fps 60
## Pass "-- --phase=N" to run one phase.


func _ready() -> void:
	GameManager.guides_enabled = false
	GameManager.auto_quality_enabled = false
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
	if only in [0, 3]:
		await _phase3()
	if only in [0, 4]:
		await _phase4()
	if only in [0, 5]:
		await _phase5()
	if only in [0, 6]:
		await _phase6()
	if only in [0, 7]:
		await _phase7()
	if only in [0, 8]:
		await _phase8()
	if only in [0, 9]:
		await _phase9()
	if only in [0, 10]:
		await _phase10()
	if only in [0, 11]:
		await _phase11()
	if only in [0, 12]:
		await _phase12()
	if only in [0, 13]:
		await _phase13()
	if only in [0, 14]:
		await _phase14()
	if only in [0, 15]:
		await _phase15()
	if only in [0, 16]:
		await _phase16()
	if only in [0, 17]:
		await _phase17()
	if only in [0, 18]:
		await _phase18()
	if only in [0, 19]:
		await _phase19()
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
	# Just walking (no chores) for this check.
	human.end_activity()
	human.activities = {}
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
		# The navigation map syncs on a background thread; wait until it answers.
		for i in 120:
			if NavigationServer3D.map_get_path(map, spawn, lvl.goal.global_position, true).size() > 0:
				break
			await get_tree().physics_frame
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
	GameManager.current_bug = &"fly"
	GameManager.begin_run(RunStats.new())
	GameManager.run.crumbs = 9
	GameManager.finish_run(true)
	check(SaveSystem.is_bug_unlocked(&"spider"), "escaping a room as the fly brings the spider out of the shade")
	GameManager.current_bug = &"cockroach"

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


# --- Phase 3: content, pets, newspaper, escalation, scoring --------------------------

func _phase3() -> void:
	print("-- Phase 3: living room, backyard, pets, newspaper, escalation, scoring")
	SaveSystem.data = SaveSystem.default_data()
	var lvl := await load_level(&"living_room", &"cockroach")
	var p := lvl.player
	HouseClock.set_hour(7.2)
	await frames(5)

	# Newspaper: hits inside its swept arc, misses outside it.
	var reader := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	reader.route = PackedVector3Array()
	check(reader.present and reader.newspaper != null, "the reader is home with a newspaper while the TV is on")
	var pivot := reader.global_position
	p.global_position = pivot + Vector3(0, 0.8, 10)
	await frames(5)
	reader.newspaper.sweep_at(pivot, p.global_position, 0.3)
	await frames(50)
	check(p.hits_left < p.stats.max_hits, "the newspaper sweep hits a bug inside its arc")
	await frames(int(60 * p.stats.invuln_time) + 10)
	var hits := p.hits_left
	p.global_position = pivot + Vector3(0, 0.8, -10)
	await frames(5)
	reader.newspaper.sweep_at(pivot, pivot + Vector3(0, 0, 10), 0.3)
	await frames(50)
	check(p.hits_left == hits, "a bug behind the reader is outside the sweep")

	# TV noise masks footsteps nearby.
	var near_tv := Vector3(-8, 0.8, 30)
	check(PerceptionSystem.get_ambient_noise_at(near_tv) >= 0.85, "the TV fills the room with masking noise")
	HouseClock.set_hour(9.5)
	await frames(2)
	check(PerceptionSystem.get_ambient_noise_at(near_tv) < 0.5, "with the TV off the room is quiet")

	# The cat: sight cone, nap, losing you when you hide.
	var cat := first_in_group(Phys.GROUP_PET, lvl) as Pet
	HouseClock.set_hour(8.3)
	await frames(10)
	check(cat.sleeping and not cat.can_see(p), "the cat naps on its routine and sees nothing")
	HouseClock.set_hour(7.2)
	await frames(10)
	# A calm cat on its own (not mid-game with the dog, which halves its watch).
	for pet in get_tree().get_nodes_in_group(Phys.GROUP_PET):
		if lvl.is_ancestor_of(pet) and (pet as Pet).barks:
			pet.process_mode = Node.PROCESS_MODE_DISABLED
	cat.stop_playing()
	cat._play_cd = 999.0
	cat.alert.reset()
	cat.waypoints = PackedVector3Array()
	cat.global_position = Vector3(0, 0.5, 10)
	cat.rotation.y = 0.0
	p.global_position = Vector3(0, 0.8, 25)
	await frames(15)
	check(not cat.player_visible, "the cat can't see a bug behind it")
	cat.rotation.y = PI
	var saw := false
	for i in 120:
		await get_tree().physics_frame
		if cat.alert.state >= AlertState.SUSPICIOUS:
			saw = true
			break
	check(saw, "the cat notices a bug in front of it")
	p.global_position = Vector3(-10, 0.6, -39)
	InputRouter.set_touch_action(&"secondary", true)
	cat.force_alert(AlertState.ALERT, Vector3(0, 0.8, 25))
	var calmed := false
	for i in int(60 * (cat.config.search_duration + 12.0)):
		await get_tree().physics_frame
		if cat.alert.state <= AlertState.SUSPICIOUS and i > 120:
			calmed = true
			break
	InputRouter.set_touch_action(&"secondary", false)
	check(calmed, "the cat gives up the hunt when you hide under the couch")
	await unload(lvl)

	# Time-based intensity floor and scoring math.
	lvl = await load_level(&"kitchen", &"cockroach")
	var s0 := lvl.hazard_speed()
	lvl._elapsed = lvl.config.intensity_ramp_seconds
	await frames(2)
	check(lvl.hazard_speed() > s0 + 0.2, "threats speed up as the run goes on (%.2f -> %.2f)" % [s0, lvl.hazard_speed()])
	await unload(lvl)
	var r := RunStats.new()
	r.crumbs = 8
	r.golden = true
	r.close_calls = 2
	r.lures_used = 1
	r.threats_stunned = 1
	r.hits_taken = 1
	r.time = 100.0
	r.won = true
	var sc := r.score(GameManager.scoring, 180.0)
	var cfg := GameManager.scoring
	var expected := 8 * cfg.crumb_points + cfg.golden_points + 2 * cfg.close_call_points + cfg.lure_points \
		+ cfg.stun_points + cfg.ghost_bonus + int(80.0 * cfg.speed_bonus_per_second) - cfg.hit_penalty
	check(int(sc["total"]) == expected, "score adds up (%d == %d)" % [int(sc["total"]), expected])
	var b := r.badges(180.0)
	check(b["ghost"] and b["speedrun"] and b["golden"], "a clean, fast run with the golden crumb earns all three badges")
	r.ever_alerted = true
	r.time = 200.0
	b = r.badges(180.0)
	check(not b["ghost"] and not b["speedrun"], "being spotted or slow loses those badges")

	# Backyard: the dog's bark calls the gardener; the yard keeps flyers in.
	lvl = await load_level(&"backyard", &"cockroach")
	HouseClock.set_hour(7.8)
	await frames(5)
	var gardener: Human = null
	for h in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
		if lvl.is_ancestor_of(h) and (h as Human).present:
			gardener = h
	var dog := first_in_group(Phys.GROUP_PET, lvl) as Pet
	check(gardener != null, "the gardener is out during gardening")
	gardener.alert.reset()
	dog.force_alert(AlertState.ALERT, lvl.player.global_position)
	await frames(10)
	check(gardener.alert.state >= AlertState.SEARCHING, "the dog's bark sends the gardener searching")
	await unload(lvl)
	lvl = await load_level(&"backyard", &"fly")
	var fly := lvl.player as Fly
	fly.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 45, 70)))
	fly.take_off()
	fly.stamina = 999.0
	face(lvl, PI)
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(240)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(fly.global_position.z < 102.0 and fly.global_position.y < 110.0, "invisible walls keep the fly inside the yard (z=%.1f)" % fly.global_position.z)
	await unload(lvl)

	# Both new rooms can be won and unlock what follows.
	for level in [&"living_room", &"backyard"]:
		lvl = await load_level(level, &"cockroach")
		await frames(5)
		var got := 0
		for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
			var crumb := c as Crumb
			if crumb and not crumb.golden and lvl.is_ancestor_of(crumb) and got < lvl.crumbs_needed:
				lvl.player.global_position = crumb.global_position
				await frames(3)
				got += 1
		check(lvl.goal.active, "%s: the exit opens after %d crumbs" % [level, lvl.crumbs_needed])
		lvl.player.global_position = lvl.goal.global_position + Vector3.UP
		await frames(5)
		check(GameManager.state == GameManager.State.WIN, "%s: reaching the exit wins" % level)
		await unload(lvl)
	check(SaveSystem.is_bug_unlocked(&"fly") and SaveSystem.is_level_completed(&"backyard"), "winning both rooms records the backyard (as the cockroach, that unlocks the fly)")


# --- Phase 4: the living house -------------------------------------------------------

func _active_node(lvl: Node, cls: String) -> int:
	var n := 0
	for c in lvl.find_children("*", cls, true, false):
		if (c as Node).process_mode != Node.PROCESS_MODE_DISABLED and (c as Node3D).visible:
			n += 1
	return n


func _phase4() -> void:
	print("-- Phase 4: routines, props, hazards, secret routes, bosses")
	SaveSystem.data = SaveSystem.default_data()
	var lvl := await load_level(&"kitchen", &"cockroach")
	var p := lvl.player
	var human := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	var vac := lvl.find_child("RobotVacuum", true, false) as RobotVacuum

	# Routine: who is home and what is lit follows the clock.
	HouseClock.set_hour(8.0)
	await frames(3)
	check(not human.present, "the kitchen empties after breakfast")
	HouseClock.set_hour(8.5)
	await frames(3)
	check(human.present, "the human comes back to do the dishes")
	check(not vac.present, "no vacuum before cleaning day")
	HouseClock.set_hour(9.2)
	await frames(3)
	check(vac.present, "the robot vacuum comes out on cleaning day")
	HouseClock.set_hour(10.0)
	await frames(3)
	check(not vac.present, "the vacuum docks when cleaning is over")
	HouseClock.set_hour(7.2)
	p.global_position = Vector3(43, 0.8, -9)
	await frames(10)
	check(PerceptionSystem.light_level >= 0.99, "the open fridge floods its doorway with light")
	HouseClock.set_hour(7.4)
	await frames(10)
	check(PerceptionSystem.light_level < 0.99, "the light goes when the fridge closes")

	# Sticky trap: slowed, then stuck; mashing tears you free.
	p.global_position = Vector3(-46, 0.8, 18)
	await frames(50)
	check(p.stuck_time > 0.0, "the glue trap sticks the roach")
	var stuck := p.stuck_time
	for i in 4:
		InputRouter.set_touch_action(&"dodge", true)
		await frames(1)
		InputRouter.set_touch_action(&"dodge", false)
		await frames(1)
	check(p.stuck_time < stuck - 1.0, "mashing buttons tears the roach free faster")
	p.stuck_time = 0.0
	p.global_position = Vector3(30, 0.8, 30)
	await frames(30)

	# Drain during the dishes: pulled in, washed out to the respawn spot.
	HouseClock.set_hour(8.5)
	await frames(3)
	var drain := lvl.find_child("SinkDrain", true, false) as Drain
	p.global_position = drain.global_position + Vector3(3.0, -0.2, 0)
	var d0 := Vector2(p.global_position.x - drain.global_position.x, p.global_position.z - drain.global_position.z).length()
	await frames(10)
	var d1 := Vector2(p.global_position.x - drain.global_position.x, p.global_position.z - drain.global_position.z).length()
	check(d1 < d0, "running water pulls the bug toward the drain")
	var hits := p.hits_left
	p.global_position = drain.global_position + Vector3(0.3, -0.2, 0)
	await frames(5)
	var respawn := drain.get_node("Respawn") as Node3D
	check(p.hits_left < hits and p.global_position.distance_to(respawn.global_position) < 3.0, "the drain washes you out with a hit")
	await frames(int(60 * p.stats.invuln_time) + 10)

	# Bug spray at the top of the escalation chain.
	HouseClock.set_hour(7.2)
	await frames(2)
	human.stun_time = 0.0
	human.escalation_stage = 4
	human._spray_cd = 0.0
	human.force_alert(AlertState.SEARCHING, Vector3(0, 0.8, 0))
	var sprayed := false
	for i in 60:
		await get_tree().physics_frame
		if human._spray_cd > 0.0:
			sprayed = true
			break
	check(sprayed and _active_node(lvl.find_child("Pools", false, false), "Node3D") > 0,
		"a stage-4 human sprays where it last noticed you")

	# A falling mug stuns the human it lands on (feet count).
	human.alert.reset()
	human.stun_time = 0.0
	human.route = PackedVector3Array()
	human.escalation_stage = 0
	human._step_timer = 999.0
	human.left_foot.plant_at(Vector3(24, 0, 10), 0.0)
	await frames(5)
	var mug: PhysicsProp = null
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		if lvl.is_ancestor_of(n) and (n as PhysicsProp).mass > 2.0:
			mug = n
	var foot_pos := human.left_foot.global_position
	mug.freeze = false
	mug.global_position = foot_pos + Vector3(0, 12, 0)
	mug.linear_velocity = Vector3.ZERO
	mug.sleeping = false
	await frames(60)
	check(human.stun_time > 0.0, "a mug dropped on the human's foot stuns them")
	# A planted foot is a solid obstacle wherever the human has walked to.
	human.left_foot.plant_at(Vector3(-20, 0, 38), 0.0)
	await frames(3)
	var rq := PhysicsRayQueryParameters3D.create(Vector3(-20, 20, 38), Vector3(-20, -1, 38))
	var hit := lvl.get_world_3d().direct_space_state.intersect_ray(rq)
	check(hit.get("collider") == human.left_foot.get_node("Body"), "the foot's collision follows the foot")
	p.global_position = Vector3(-20, 0.8, 28)
	face(lvl, 0.0)
	await frames(10)
	InputRouter.set_touch_move(Vector2(0, -1))
	await frames(60)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(p.global_position.z < 33.5, "a planted foot blocks the bug (z=%.1f)" % p.global_position.z)

	# Cereal boxes topple like dominoes.
	var boxes: Array[PhysicsProp] = []
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var pp := n as PhysicsProp
		if lvl.is_ancestor_of(pp) and pp.name.begins_with("CerealBox"):
			boxes.append(pp)
	boxes.sort_custom(func(a: PhysicsProp, b2: PhysicsProp) -> bool: return a.global_position.x < b2.global_position.x)
	var starts: Array[Basis] = []
	for bx in boxes:
		starts.append(bx.global_basis)
	boxes[0].freeze = false
	boxes[0].apply_impulse(Vector3(6, 0, 0) * boxes[0].mass, Vector3(0, 3, 0))
	await frames(120)
	var tipped := 0
	for i in boxes.size():
		if boxes[i].global_basis.y.dot(starts[i].y) < 0.8 or boxes[i].global_position.y < 40.0:
			tipped += 1
	check(tipped >= 2, "a pushed cereal box knocks over the next one (%d tipped)" % tipped)

	# Prop budget: far-away awake props get frozen.
	p.global_position = Vector3(50, 0.8, 34)
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var pp2 := n as PhysicsProp
		if lvl.is_ancestor_of(pp2):
			pp2.freeze = false
			pp2.sleeping = false
			pp2.apply_central_impulse(Vector3.UP * 0.01)
	await frames(40)
	var awake := 0
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var pp3 := n as PhysicsProp
		if lvl.is_ancestor_of(pp3) and not pp3.freeze and not pp3.sleeping:
			awake += 1
	check(awake <= Level.PROP_AWAKE_CAP, "no more than %d props simulate at once (%d awake)" % [Level.PROP_AWAKE_CAP, awake])
	await unload(lvl)

	# Secret routes: every passage leads somewhere solid; each bug finds a way to the golden crumb.
	for level in GameManager.LEVEL_IDS:
		for bug in GameManager.BUG_IDS:
			lvl = await load_level(level, bug)
			await frames(5)
			var gold: Crumb = null
			for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
				if lvl.is_ancestor_of(c) and (c as Crumb).golden:
					gold = c
			var route_ok := false
			for psg in lvl.find_children("*", "Area3D", true, false):
				var passage := psg as Passage
				if passage == null or not passage.can_interact(lvl.player) or passage.allowed_bugs.is_empty():
					continue
				lvl.player.teleport_to(Transform3D(Basis.IDENTITY, passage.global_position))
				await frames(4)
				lvl.player._do_interact()
				await frames(15)
				var pos := lvl.player.global_position
				if pos.distance_to(gold.global_position) < 15.0 and pos.y > -2.0:
					route_ok = true
			check(route_ok, "%s/%s: a secret route leads to the golden crumb" % [level, bug])
			await unload(lvl)

	# Living room: the fan blows a flying fly; the cat knocks the mug off the side table.
	lvl = await load_level(&"living_room", &"fly")
	var f := lvl.player as Fly
	HouseClock.set_hour(7.2)
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(85, 15, 18)))
	f.take_off()
	await frames(20)
	check(f.external_velocity.x < -2.0, "the fan pushes a flying fly (wind %.1f)" % f.external_velocity.x)
	var cat := first_in_group(Phys.GROUP_PET, lvl) as Pet
	var lmug: PhysicsProp = null
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		if lvl.is_ancestor_of(n) and (n as PhysicsProp).mass > 2.0:
			lmug = n
	var mug_y := lmug.global_position.y
	cat.stop_playing()
	cat._play_cd = 999.0
	# Put the fly down out of sight, or the cat goes after it instead.
	f.land()
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-55, 0.6, -40)))
	cat.alert.reset()
	cat.global_position = Vector3(100, 0.5, -18)
	cat.force_alert(AlertState.SEARCHING, Vector3(98, 25.5, -33))
	for i in 720:
		await get_tree().physics_frame
		if lmug.global_position.y < mug_y - 5.0:
			break
	check(lmug.global_position.y < mug_y - 5.0, "the cat leaps onto the side table and knocks the mug off (mug %.1f->%.1f, cat %s alert %d perch %d mood %d sleep %s pounce %d)" % [
		mug_y, lmug.global_position.y, cat.global_position, cat.alert.state, cat._perch_state, cat.mood, cat.sleeping, cat._pounce])
	await unload(lvl)

	# Backyard: fly paper, sprinklers, and the exterminator's fog.
	lvl = await load_level(&"backyard", &"fly")
	f = lvl.player as Fly
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(15, 25, -45)))
	f.take_off()
	await frames(60)
	check(f.stuck_time > 0.0 or not f.flying, "fly paper catches a flying fly")
	await unload(lvl)
	lvl = await load_level(&"backyard", &"cockroach")
	p = lvl.player
	HouseClock.set_hour(7.2)
	for z in range(10):
		p.global_position = Vector3(18 + z, 0.8, 25)
		await frames(3)
	check(PerceptionSystem.scent.strongest_near(Vector3(22, 0.8, 25), 6.0) < 0, "the sprinkler washes away your scent")
	var fog := lvl.find_child("FogFront", true, false) as FogFront
	fog.start()
	p.global_position = Vector3(0, 0.8, -59)
	var h0 := p.hits_left
	await frames(240)
	check(p.hits_left < h0, "caught behind the exterminator's fog, the bug takes a hit")
	await unload(lvl)


# --- Phase 5: shell & UX -------------------------------------------------------------

func _hud(lvl: Node) -> Node:
	for n in lvl.get_children():
		if n is CanvasLayer and n.has_method("toast"):
			return n
	return null


func _phase5() -> void:
	print("-- Phase 5: settings, rebinding, pause/results, HUD, colony, audio, menu flow")
	SaveSystem.data = SaveSystem.default_data()

	# Settings take effect.
	SaveSystem.set_setting("music_volume", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Music")), "music volume 0 mutes the music bus")
	SaveSystem.set_setting("sfx_volume", 0.5)
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"SFX")) - linear_to_db(0.5)) < 0.01, "the effects slider sets the effects bus")
	SaveSystem.set_setting("music_volume", 0.6)
	SaveSystem.set_setting("quality", "low")
	check(Engine.max_fps == 30 and get_viewport().scaling_3d_scale < 0.8 and not GameManager.shadows_enabled(), "low quality caps fps, lowers resolution and drops shadows")
	SaveSystem.set_setting("quality", "high")
	check(get_viewport().msaa_3d == Viewport.MSAA_4X and GameManager.shadows_enabled(), "high quality turns on antialiasing and shadows")
	SaveSystem.set_setting("quality", "medium")
	SaveSystem.set_setting("touch_controls", "on")
	check(InputRouter.is_touch_mode(), "touch controls can be forced on")
	SaveSystem.set_setting("touch_controls", "off")
	check(not InputRouter.is_touch_mode(), "and forced off")

	# Rebinding survives a restart and drives gameplay.
	var lvl := await load_level(&"kitchen", &"cockroach")
	var p := lvl.player
	await frames(15)
	var j := InputEventKey.new()
	j.physical_keycode = KEY_J
	InputRouter.rebind("jump", j)
	check(InputRouter.binding_text("jump") == "J", "jump rebinds to J")
	var y0 := p.global_position.y
	key(KEY_J, true)
	await frames(6)
	key(KEY_J, false)
	check(p.global_position.y > y0 + 0.15 or p.velocity.y > 1.0, "the new key makes the roach hop")
	SaveSystem.load_game()
	InputRouter.apply_saved_bindings()
	check(InputRouter.binding_text("jump") == "J", "the binding is saved and reloaded")
	InputRouter.reset_bindings()
	check(InputRouter.binding_text("jump") == "Space", "reset restores Space")
	await frames(30)

	# HUD readouts.
	var hud := _hud(lvl)
	check(hud != null, "the HUD is up")
	check((hud._crumbs as Label).text == "CRUMBS 0 / %d" % lvl.crumbs_needed, "the HUD counts crumbs")
	check((hud._clock as Label).text.begins_with(HouseClock.clock_text()), "the HUD shows the house clock")
	PerceptionSystem.set_escalation(2)
	await frames(2)
	check((hud._stages as Label).text.contains("[SWATTER]"), "the HUD marks reached escalation stages")
	PerceptionSystem.set_escalation(0)
	p.global_position = Vector3(43, 0.6, -30)
	await frames(30)
	check((hud._hint as Label).text == "Hold SQUEEZE to hide", "the HUD hints how to hide under the fridge")

	# Pause by key, resume from the menu.
	key(KEY_ESCAPE, true)
	await frames(2)
	key(KEY_ESCAPE, false)
	check(GameManager.state == GameManager.State.PAUSED and get_tree().paused, "Esc pauses the game")
	var resume: Button = null
	for b in lvl.find_children("*", "Button", true, false):
		if (b as Button).text == "Resume":
			resume = b
	resume.pressed.emit()
	await frames(2)
	check(GameManager.state == GameManager.State.PLAYING and not get_tree().paused, "Resume returns to play")

	# Result screens.
	p.take_hit(&"swatted", p.global_position)
	await frames(int(60 * p.stats.invuln_time) + 5)
	p.take_hit(&"swatted", p.global_position)
	await frames(80)
	var texts: PackedStringArray = []
	for l in lvl.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			texts.append((l as Label).text)
	check(texts.has("SQUISHED!") and texts.has("Swatted!"), "getting caught shows SQUISHED! with the cause")
	await unload(lvl)
	lvl = await load_level(&"kitchen", &"cockroach")
	await frames(5)
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		var crumb := c as Crumb
		if crumb and not crumb.golden and lvl.is_ancestor_of(crumb) and lvl.crumbs_got < lvl.crumbs_needed:
			lvl.player.global_position = crumb.global_position
			await frames(3)
	lvl.player.global_position = lvl.goal.global_position + Vector3.UP
	await frames(30)
	var labels: PackedStringArray = []
	for l in lvl.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			labels.append((l as Label).text)
	var buttons: PackedStringArray = []
	for b in lvl.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			buttons.append((b as Button).text)
	check(labels.has("ESCAPED!") and Array(labels).any(func(t: String) -> bool: return t.begins_with("Fly is out of the shade")),
		"winning shows ESCAPED! and the bug it brings out of the shade")
	check(buttons.has("Next level") and buttons.has("Colony"), "the win screen offers the next level and the colony")
	await unload(lvl)

	# Colony: buy an upgrade from the screen.
	SaveSystem.data["colony"] = {"banked": 0, "lifetime": 0, "upgrades": []}
	SaveSystem.bank_crumbs(20)
	var banked := int(SaveSystem.colony()["banked"])
	var hub: Node = (load("res://scenes/hub/colony_hub.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(hub)
	await frames(3)
	var buy: Button = null
	for b in hub.find_children("*", "Button", true, false):
		if (b as Button).text == "Buy - 15 crumbs":
			buy = b
	check(buy != null and not buy.disabled, "the colony offers Swift Legs for 15 crumbs")
	buy.pressed.emit()
	await frames(2)
	check(SaveSystem.has_upgrade(&"swift_legs") and int(SaveSystem.colony()["banked"]) == banked - 15, "buying it spends crumbs and owns the upgrade")
	var locked := 0
	for b in hub.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with("Buy") and (b as Button).disabled:
			locked += 1
	var needs := false
	for l in hub.find_children("*", "Label", true, false):
		if (l as Label).text == "Needs colony size 4":
			needs = true
	check(locked > 0 and needs, "upgrades that need a bigger colony stay locked (colony size %d)" % SaveSystem.colony_size())
	hub.queue_free()
	await frames(2)

	# Audio: every sound the code asks for exists, and tension drives the heartbeat.
	var missing: PackedStringArray = []
	var rx := RegEx.create_from_string("(?:play|play_at|make_loop_emitter)\\(&\"([a-z_]+)\"")
	var files: PackedStringArray = []
	var stack := ["res://scripts", "res://autoload"]
	while not stack.is_empty():
		var d: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(d):
			stack.append(d.path_join(sub))
		for fname in DirAccess.get_files_at(d):
			if fname.ends_with(".gd"):
				files.append(d.path_join(fname))
	for fpath in files:
		var src := FileAccess.get_file_as_string(fpath)
		for m in rx.search_all(src):
			var k := StringName(m.get_string(1))
			if AudioManager.get_stream(k) == null and not missing.has(String(k)):
				missing.append(String(k))
	for level in GameManager.LEVEL_IDS:
		var scene_src := FileAccess.get_file_as_string(GameManager.get_level(level).scene_path)
		for m in RegEx.create_from_string("sound_key = &\"([a-z_]+)\"").search_all(scene_src):
			if AudioManager.get_stream(StringName(m.get_string(1))) == null:
				missing.append(m.get_string(1))
	check(missing.is_empty(), "every sound the game plays exists (%d scripts scanned) %s" % [files.size(), ", ".join(missing)])
	AudioManager.play_music(&"music_ambient")
	AudioManager.set_tension(1.0)
	await frames(90)
	check(AudioManager._heartbeat.playing and AudioManager._heartbeat.volume_db > -12.0, "being hunted brings up the heartbeat")
	AudioManager.set_tension(0.0)
	await frames(150)
	check(not AudioManager._heartbeat.playing, "the heartbeat fades when things calm down")

	# Real menu flow: main menu -> level select -> bug select -> kitchen.
	var dummy := Node.new()
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	GameManager.goto("main_menu")
	await frames(30)
	check(get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("main_menu.tscn"), "the main menu opens")
	var play := _find_button(get_tree().current_scene, "Play")
	play.pressed.emit()
	await frames(30)
	check(get_tree().current_scene.scene_file_path.ends_with("level_select.tscn"), "Play opens the room list")
	_find_button(get_tree().current_scene, "Play Kitchen").pressed.emit()
	await frames(30)
	check(get_tree().current_scene.scene_file_path.ends_with("bug_select.tscn"), "picking a room opens bug select")
	_find_button(get_tree().current_scene, "Play as Cockroach").pressed.emit()
	await frames(45)
	check(get_tree().current_scene is Level and GameManager.state == GameManager.State.PLAYING, "picking a bug starts the kitchen")
	GameManager.goto("main_menu")
	await frames(30)
	var cur := get_tree().current_scene
	var back := Node.new()
	get_tree().root.add_child(back)
	get_tree().current_scene = back
	cur.queue_free()
	await frames(3)


# --- Phase 6: ship prep ----------------------------------------------------------------

func _phase6() -> void:
	print("-- Phase 6: performance, pooling, icons and export setup")
	SaveSystem.data = SaveSystem.default_data()
	for level in GameManager.LEVEL_IDS:
		var lvl := await load_level(level, &"cockroach")
		await frames(30)
		# Headless frames run back to back, so wall time per frame = CPU cost of
		# all game logic + physics (rendering excluded).
		var t0 := Time.get_ticks_usec()
		await frames(240)
		var ms := (Time.get_ticks_usec() - t0) / 240.0 / 1000.0
		var meshes := 0
		var cam_pos := lvl.camera.camera.global_position
		for m in lvl.find_children("*", "GeometryInstance3D", true, false):
			var gi := m as GeometryInstance3D
			# Brief extras (a blink, a phone in hand) don't count toward the
			# steady-state budget.
			var path := String(gi.get_path())
			if path.contains("/Lids/") or path.contains("/PhoneHold/"):
				continue
			# Beyond its draw distance the renderer skips it (pickups, props).
			if gi.visibility_range_end > 0.0 and gi.global_position.distance_to(cam_pos) > gi.visibility_range_end + gi.visibility_range_end_margin:
				continue
			if gi.is_visible_in_tree():
				meshes += 1
		print("     %s: %.2f ms per frame of logic + physics, %d visible meshes" % [level, ms, meshes])
		check(ms < 4.0, "%s runs its game logic in under 4 ms a frame (%.2f)" % [level, ms])
		# Budget: most of it is placeholder characters (a person ~34, a pet ~20,
		# your bug ~28). Generated models replace each with one or two meshes.
		check(meshes < 185, "%s keeps visible meshes low for phones (%d)" % [level, meshes])
		await unload(lvl)

	# Pools: a long fight doesn't keep creating objects.
	var lvl2 := await load_level(&"kitchen", &"cockroach")
	var p := lvl2.player
	p.global_position = Vector3(43, 0.6, -30)
	InputRouter.set_touch_action(&"secondary", true)
	var human := first_in_group(Phys.GROUP_HUMAN, lvl2) as Human
	await frames(30)
	var target := Vector3(10, 0.8, 10)
	var counts: Array[int] = []
	for _wave in 12:
		for i in 2:
			var sw := lvl2.swatter_pool.acquire() as Swatter
			sw.strike(target + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)), 0.3, human, lvl2.swatter_pool)
		var cloud := lvl2.spray_pool.acquire() as SprayCloud
		cloud.spawn(target, lvl2.spray_pool)
		await frames(60)
		counts.append(int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	InputRouter.set_touch_action(&"secondary", false)
	var growth := counts[-1] - counts[3]
	check(growth < 60, "pooled swatters and spray don't pile up objects (%d -> %d)" % [counts[3], counts[-1]])
	await unload(lvl2)

	# Icons, splash and export presets are project files (not shipped in a build).
	if not FileAccess.file_exists("res://export_presets.cfg"):
		print("     (running from an exported build: project-file checks skipped)")
		return
	for path in ["res://assets/icons/icon.png", "res://assets/icons/icon_1024.png", "res://assets/icons/icon_192.png",
			"res://assets/icons/adaptive_foreground.png", "res://assets/icons/adaptive_background.png",
			"res://assets/icons/icon.ico", "res://assets/icons/splash.png"]:
		check(FileAccess.file_exists(path), "asset present: " + path.get_file())
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/icons/icon_1024.png"))
	check(img and img.get_width() == 1024 and img.get_height() == 1024, "App Store icon is 1024x1024")
	var cfg := ConfigFile.new()
	check(cfg.load("res://export_presets.cfg") == OK, "export_presets.cfg loads")
	var platforms: PackedStringArray = []
	for sec in cfg.get_sections():
		if not sec.ends_with(".options"):
			platforms.append(String(cfg.get_value(sec, "platform")))
			var opts := sec + ".options"
			for k in cfg.get_section_keys(opts):
				var v: Variant = cfg.get_value(opts, k)
				if v is String and (v as String).begins_with("res://"):
					check(FileAccess.file_exists(v), "%s %s points at a real file" % [cfg.get_value(sec, "name"), k])
	for want in ["Android", "iOS", "Windows Desktop", "macOS", "Linux", "Web"]:
		check(platforms.has(want), "export preset for " + want)
	check(ProjectSettings.get_setting("display/window/handheld/orientation") == 6, "phones rotate freely (sensor orientation)")
	check(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc") == true, "mobile texture compression is enabled")


# --- Update: alarm gauge, gentler threats, fly escape tactics -----------------------

func _phase7() -> void:
	print("-- Update: alarm gauge, slower threats, fly escape tactics")
	SaveSystem.data = SaveSystem.default_data()

	# Threats are slower and less sharp-eyed than the bugs they chase.
	var roach := GameManager.get_bug_stats(&"cockroach")
	var cat_cfg: ThreatConfig = load("res://resources/threats/cat.tres")
	var dog_cfg: ThreatConfig = load("res://resources/threats/dog.tres")
	var human_cfg: ThreatConfig = load("res://resources/threats/human.tres")
	check(cat_cfg.chase_speed < roach.sprint_speed and dog_cfg.chase_speed < roach.sprint_speed,
		"a sprinting cockroach outruns the cat and the dog")
	check(human_cfg.attack_windup >= 1.0 and human_cfg.sight_range <= 60.0 and human_cfg.min_visibility >= 0.15,
		"humans wind up slower and see less far")
	var klvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(7.2)
	var kh := first_in_group(Phys.GROUP_HUMAN, klvl) as Human
	kh.route = PackedVector3Array()
	kh._step_timer = 1e9
	# Stand at the front-right of the kitchen looking down its long side (-X).
	kh._plant_feet(Vector3(45, 0, 43), PI * 0.5)
	kh.global_position = Vector3(45, 0, 43)
	kh.rotation.y = PI * 0.5
	await frames(5)
	var seen_at := []
	for d in [8.0, 30.0, 50.0, 70.0]:
		klvl.player.global_position = Vector3(45.0 - d, 0.8, 43)
		await frames(4)
		seen_at.append(kh.can_see(klvl.player))
	check(seen_at == [false, true, true, false], "a human sees the floor 30-50 units ahead, not right under its nose or past its range %s" % str(seen_at))
	await unload(klvl)

	# The gauge: gradual, house-wide, and it drains when you hide.
	var lvl := await load_level(&"living_room", &"cockroach")
	var p := lvl.player
	HouseClock.set_hour(7.2)
	var cat := first_in_group(Phys.GROUP_PET, lvl) as Pet
	var reader := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	# This is about the cat and the reader: keep the dog out of it (its pounces
	# stun the cat, and it would sniff you out under the couch).
	for pet in get_tree().get_nodes_in_group(Phys.GROUP_PET):
		if lvl.is_ancestor_of(pet) and (pet as Pet).barks:
			pet.process_mode = Node.PROCESS_MODE_DISABLED
	reader.route = PackedVector3Array()
	cat.waypoints = PackedVector3Array()
	cat.global_position = Vector3(0, 0.5, 10)
	cat.rotation.y = PI
	p.global_position = Vector3(0, 0.8, 22)
	p.invuln = 1000.0
	await frames(60)
	check(PerceptionSystem.alarm > 0.0 and PerceptionSystem.alarm < 0.5 and not PerceptionSystem.alarm_active,
		"one second in view only part-fills the gauge (%.2f)" % PerceptionSystem.alarm)
	check(cat.alert.state < AlertState.ALERT, "seen on its own, the cat investigates but doesn't attack")
	var raised := false
	for i in 1200:
		await get_tree().physics_frame
		if PerceptionSystem.alarm_active:
			raised = true
			break
	check(raised, "staying in view fills the gauge to full alarm")
	await frames(2)
	check(cat.alert.state == AlertState.ALERT and reader.alert.state == AlertState.ALERT,
		"full alarm alerts every threat in the room, not just the one that saw you")
	p.global_position = Vector3(-10, 0.6, -39)
	InputRouter.set_touch_action(&"secondary", true)
	var cleared := false
	for i in 900:
		await get_tree().physics_frame
		if not PerceptionSystem.alarm_active:
			cleared = true
			break
	InputRouter.set_touch_action(&"secondary", false)
	check(cleared, "hiding drains the gauge and calls the alarm off (%.2f)" % PerceptionSystem.alarm)
	await unload(lvl)

	lvl = await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(7.2)
	var human := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	human.route = PackedVector3Array()
	PerceptionSystem.emit_world_noise(human.global_position + Vector3(3, 0, 3), 3.0)
	check(PerceptionSystem.alarm == 0.0, "a lure's noise doesn't count against you")
	for i in 4:
		PerceptionSystem.emit_player_noise(human.global_position + Vector3(4, 0.8, 4), 1.5)
		await frames(15)
	check(PerceptionSystem.alarm > 0.0 and PerceptionSystem.alarm < 1.0, "your own noise nudges the gauge up (%.2f)" % PerceptionSystem.alarm)
	await unload(lvl)

	# Fly escape tactics.
	lvl = await load_level(&"kitchen", &"fly")
	var f := lvl.player as Fly
	await frames(10)
	var hud := _hud(lvl)
	check(hud != null and hud._alarm is AlarmGauge, "the HUD shows the alarm gauge")

	# Cling to a wall, blend in, take off again.
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(98, 20, 30)))
	f.take_off()
	face(lvl, -PI * 0.5)
	f.stamina = 4.0
	InputRouter.set_touch_move(Vector2(0, 1))
	InputRouter.set_touch_action(&"secondary", true)
	for i in 120:
		await get_tree().physics_frame
		if f.clinging:
			break
	InputRouter.set_touch_action(&"secondary", false)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(f.clinging and f.cling_normal.x < -0.5, "flying into a wall holding Down clings to it")
	var st := f.stamina
	await frames(70)
	check(f.clinging and f.stamina > st and f.current_noise() == 0.0, "clinging is silent and restores stamina")
	check(f.has_camo() and f.is_frozen(), "a still fly on a wall blends in")
	InputRouter.set_touch_action(&"jump", true)
	await frames(3)
	InputRouter.set_touch_action(&"jump", false)
	check(f.flying and not f.clinging, "Up takes off from the wall")

	# Cling to the ceiling: fly up into it holding Up.
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 92, 0)))
	f.stamina = f.stats.stamina_max
	InputRouter.set_touch_action(&"jump", true)
	for i in 120:
		await get_tree().physics_frame
		if f.clinging:
			break
	InputRouter.set_touch_action(&"jump", false)
	check(f.clinging and f.cling_normal.y < -0.7, "flying up into the ceiling holding Up clings to it")
	await frames(30)
	check(f.clinging and f.global_position.y > 95.0, "the fly hangs on the ceiling")
	InputRouter.set_touch_action(&"jump", true)
	await frames(3)
	InputRouter.set_touch_action(&"jump", false)

	# Evasive loop: double-tap Burst.
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 30, 40)))
	f.take_off()
	f.stamina = f.stats.stamina_max
	f._dodge_cd = 0.0
	await frames(20)
	var face0 := f.facing
	var st2 := f.stamina
	InputRouter.set_touch_action(&"dodge", true)
	await frames(1)
	InputRouter.set_touch_action(&"dodge", false)
	await frames(6)
	InputRouter.set_touch_action(&"dodge", true)
	await frames(1)
	InputRouter.set_touch_action(&"dodge", false)
	await frames(3)
	check(f.is_looping() and f.invuln > 0.3, "a quick double Burst starts an evasive loop with invulnerability")
	check(f.velocity.y > 5.0, "the loop climbs first")
	check(f.facing.dot(face0) < -0.5 and f.stamina < st2 - 1.0, "the loop turns you around and costs stamina")
	await frames(40)

	# Dive: Burst while holding Down.
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 60, 40)))
	f.stamina = f.stats.stamina_max
	f._dodge_cd = 0.0
	await frames(5)
	InputRouter.set_touch_action(&"secondary", true)
	InputRouter.set_touch_action(&"dodge", true)
	await frames(2)
	InputRouter.set_touch_action(&"dodge", false)
	await frames(3)
	check(f.is_diving() and f.velocity.y < -15.0 and f.current_noise() <= 0.05, "Burst while holding Down dives fast and silently")
	InputRouter.set_touch_action(&"secondary", false)
	await frames(40)

	# Jinking: a sharp turn at speed makes you harder to see.
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 50, 0)))
	if not f.flying:
		f.take_off()
	f.stamina = f.stats.stamina_max
	face(lvl, 0.0)
	InputRouter.set_touch_move(Vector2(0, 1))
	InputRouter.set_touch_action(&"primary", true)
	await frames(45)
	var straight := f._extra_visibility_mult()
	InputRouter.set_touch_move(Vector2(0, -1))
	var jinked := false
	for i in 45:
		await get_tree().physics_frame
		if f.is_jinking():
			jinked = true
			break
	InputRouter.set_touch_move(Vector2.ZERO)
	InputRouter.set_touch_action(&"primary", false)
	check(straight == 1.0 and jinked and f._extra_visibility_mult() < 0.7, "a sharp reversal at speed is a jink that lowers your visibility")
	await unload(lvl)


# --- Update: more places to hide, and slots for generated models --------------

const ROOMS: Array[StringName] = [&"kitchen", &"living_room", &"backyard"]
const BUGS: Array[StringName] = [&"cockroach", &"fly", &"spider"]


func _covers(lvl: Node, kind: String = "") -> Array[Marker3D]:
	var out: Array[Marker3D] = []
	for n in get_tree().get_nodes_in_group(Phys.GROUP_COVER):
		if lvl.is_ancestor_of(n) and (kind == "" or String(n.get_meta(&"kind", "")) == kind):
			out.append(n as Marker3D)
	return out


func _skins(root: Node) -> Array[SkinAnchor]:
	var out: Array[SkinAnchor] = []
	for n in root.find_children("*", "SkinAnchor", true, false):
		out.append(n as SkinAnchor)
	if root is SkinAnchor:
		out.append(root as SkinAnchor)
	return out


func _phase8() -> void:
	print("-- Update: more cover to hide behind, model slots for generated art")
	SaveSystem.data = SaveSystem.default_data()

	# Every room has several new hiding places, and every bug fits in every shelter.
	for room in ROOMS:
		for bug in BUGS:
			var lvl := await load_level(room, bug)
			var p := lvl.player
			p.invuln = 0.0
			var shelters := _covers(lvl, "shelter")
			if bug == &"cockroach":
				check(_covers(lvl).size() >= 5 and shelters.size() >= 2,
					"%s: %d new cover spots, %d of them shelters you can crawl into" % [room, _covers(lvl).size(), shelters.size()])
			var hidden: PackedStringArray = []
			var exposed: PackedStringArray = []
			for m in shelters:
				p.teleport_to(Transform3D(Basis.IDENTITY, m.global_position))
				await frames(6)
				var label := String(m.get_meta(&"label"))
				if p.is_hidden_safe() and PerceptionSystem.visibility == 0.0 \
						and not p.take_hit(&"test", m.global_position):
					hidden.append(label)
				else:
					exposed.append(label)
			check(exposed.is_empty(), "%s: the %s hides inside every shelter, invisible and out of reach %s" % [room, bug, str(exposed if not exposed.is_empty() else hidden)])
			await unload(lvl)

	# Solid cover blocks a pet's line of sight; step out from behind it and you're seen.
	var yard := await load_level(&"backyard", &"cockroach")
	HouseClock.set_hour(7.2)
	var dog := first_in_group(Phys.GROUP_PET, yard) as Pet
	dog.force_present(true)
	dog.process_mode = Node.PROCESS_MODE_DISABLED
	dog.global_position = Vector3(30, 0.5, 6)
	dog.rotation.y = 0.0
	var pl := yard.player
	pl.invuln = 1000.0
	pl.global_position = Vector3(30, 0.6, -14)
	await frames(4)
	var behind := dog.can_see(pl)
	pl.global_position = Vector3(38, 0.6, -14)
	await frames(4)
	var beside := dog.can_see(pl)
	check(not behind and beside, "the garden gnome blocks the dog's view; step out beside it and the dog sees you (%s, %s)" % [behind, beside])
	dog.process_mode = Node.PROCESS_MODE_INHERIT
	if not DirAccess.dir_exists_absolute("res://assets/models"):
		var live := _skins(yard)
		check(live.size() > 10 and live.all(func(s: SkinAnchor) -> bool: return s.model == null),
			"with no generated models yet, all %d slots in a live level keep their placeholders" % live.size())
	await unload(yard)

	# Model slots: every slot points at real placeholder meshes and a listed Meshy job.
	var ids := {}
	var bad_paths: PackedStringArray = []
	var scenes: Array[String] = []
	for room in ROOMS:
		scenes.append(GameManager.get_level(room).scene_path)
	for dir in ["res://scenes/bugs/", "res://scenes/threats/", "res://scenes/props/", "res://scenes/world/", "res://scenes/hazards/"]:
		for f in ResourceLoader.list_directory(dir):
			if f.ends_with(".tscn"):
				scenes.append(dir + f)
	for path in scenes:
		# Inspected detached from the tree, so no gameplay code runs.
		var inst := (load(path) as PackedScene).instantiate()
		for a in _skins(inst):
			ids[a.model_id] = true
			if a.hide_paths.is_empty():
				bad_paths.append("%s:%s (no placeholder)" % [path.get_file(), a.name])
			for hp in a.hide_paths:
				var n := a.get_node_or_null(hp) as Node3D
				if n == null or not n.visible:
					bad_paths.append("%s:%s -> %s" % [path.get_file(), a.name, hp])
		inst.free()
	check(ids.size() >= 50, "%d model slots across the bugs, threats, props and rooms" % ids.size())
	check(bad_paths.is_empty(), "every model slot points at visible placeholder meshes %s" % str(bad_paths.slice(0, 5)))

	# A generated model drops in: loaded at runtime, fitted to its box, placeholders hidden.
	var dir_path := "user://skin_test"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var src := Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2, 4, 1)
	mi.mesh = bm
	mi.position = Vector3(5, 7, -3)
	src.add_child(mi)
	mi.owner = src
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_scene(src, state)
	var glb := dir_path.path_join("fixture_box.glb")
	check(doc.write_to_filesystem(state, glb) == OK, "wrote a test model")
	src.free()
	var holder := Node3D.new()
	var placeholder := MeshInstance3D.new()
	placeholder.name = "Placeholder"
	placeholder.mesh = BoxMesh.new()
	holder.add_child(placeholder)
	var a := SkinAnchor.new()
	a.model_dir = dir_path
	a.model_id = "fixture_box"
	a.fit_size = Vector3(3, 2, 3)
	a.yaw_offset_deg = 0.0
	a.hide_paths = [NodePath("../Placeholder")]
	holder.add_child(a)
	add_child(holder)
	await get_tree().process_frame
	var bounds := SkinAnchor.mesh_bounds(a.model, a) if a.model else AABB()
	check(a.model != null and not placeholder.visible, "a model file swaps in and hides the placeholder")
	check(is_equal_approx(bounds.size.y, 2.0) and is_equal_approx(bounds.position.y, -1.0)
			and absf(bounds.get_center().x) < 0.01 and absf(bounds.get_center().z) < 0.01,
		"the model is scaled to fit its box, centred and standing on the floor %s" % str(bounds))
	var missing := SkinAnchor.new()
	missing.model_id = "not_generated_yet"
	holder.add_child(missing)
	check(missing.model == null and not missing.apply(), "a slot with no model file changes nothing")
	holder.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(glb))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir_path))

	# The Meshy job list is a project file (not shipped in a build).
	if not FileAccess.file_exists("res://export_presets.cfg"):
		print("     (running from an exported build: Meshy manifest check skipped)")
		return
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://tools/meshy/assets.json"))
	var listed := {}
	if manifest is Dictionary:
		for job in manifest.get("assets", []):
			listed[String(job["id"])] = true
	var unlisted: PackedStringArray = []
	for id in ids:
		if not listed.has(id):
			unlisted.append(id)
	check(not listed.is_empty() and unlisted.is_empty(), "every model slot has a Meshy job in tools/meshy/assets.json %s" % str(unlisted))


# --- Update: bigger rooms, human bodies, detailed bugs, bug food & crumb gems ---

func _floor_area(lvl: Node) -> float:
	for n in ["Floor", "Lawn"]:
		var body := lvl.find_child(n, true, false)
		if body:
			var cs := body.get_node_or_null("Shape") as CollisionShape3D
			if cs and cs.shape is BoxShape3D:
				var sz := (cs.shape as BoxShape3D).size
				return (sz.x - 4.0) * (sz.z - 4.0)
	return 0.0


func _items(lvl: Node, gem: bool) -> Array[PickupItem]:
	var out: Array[PickupItem] = []
	for n in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		var it := n as PickupItem
		if it and lvl.is_ancestor_of(it) and it.is_gem() == gem:
			out.append(it)
	return out


func _item(lvl: Node, id: StringName) -> PickupItem:
	for n in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		var it := n as PickupItem
		if it and lvl.is_ancestor_of(it) and it.def.id == id and not it.taken:
			return it
	return null


func _grab(lvl: Level, id: StringName) -> PickupItem:
	var it := _item(lvl, id)
	if it:
		lvl.player.teleport_to(Transform3D(Basis.IDENTITY, it.global_position + Vector3.UP * 0.8))
		await frames(4)
	return it


func _phase9() -> void:
	print("-- Update: bigger rooms, human-like people, detailed bugs, bug food and crumb gems")
	SaveSystem.data = SaveSystem.default_data()

	# Bigger rooms, each stocked with food and gems.
	var old_area := {&"kitchen": 120.0 * 90.0, &"living_room": 130.0 * 100.0, &"backyard": 164.0 * 124.0}
	for room in ROOMS:
		var rl := await load_level(room, &"cockroach")
		var area := _floor_area(rl)
		check(area >= old_area[room] * 1.35, "%s: floor is %d%% of its old size" % [room, int(area / old_area[room] * 100.0)])
		var foods := _items(rl, false)
		var gems := _items(rl, true)
		var floor_gem := gems.any(func(g: PickupItem) -> bool: return g.global_position.y < 1.0)
		check(foods.size() >= 4 and gems.size() >= 2 and floor_gem,
			"%s: %d bug foods and %d crumb gems (one on the floor for the cockroach)" % [room, foods.size(), gems.size()])
		var crumbs := 0
		for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
			if rl.is_ancestor_of(c) and not (c as Crumb).golden:
				crumbs += 1
		check(crumbs >= rl.config.crumbs_required + 5, "%s: %d crumbs for a target of %d" % [room, crumbs, rl.config.crumbs_required])
		await unload(rl)

	# People: a full body that walks like one.
	var klvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(7.2)
	var h := first_in_group(Phys.GROUP_HUMAN, klvl) as Human
	h.force_present(true)
	# Rigid parts are merged per material at build time, so look for materials.
	var want_mats := {"Torso/Head": ["skin", "hair", "eye_white", "lips"], "Torso/Head/Gaze": ["iris", "pupil"], "Torso": ["shirt", "jeans", "belt"],
		"Torso/ShoulderL/Elbow/Hand": ["skin"], "Torso/ShoulderR/Elbow": ["skin"], "Legs": ["jeans"]}
	var missing: PackedStringArray = []
	for path: String in want_mats.keys():
		var node := h.get_node_or_null(path)
		var have := {}
		if node:
			for c in node.get_children():
				if c is MeshInstance3D and (c as MeshInstance3D).material_override:
					have[(c as MeshInstance3D).material_override.resource_path.get_file().get_basename()] = true
		for m: String in want_mats[path]:
			if not have.has(m):
				missing.append("%s:%s" % [path, m])
	for path: String in ["Legs/ThighL", "Legs/KneeR", "Legs/ShinR", "Torso/ShoulderL/Elbow/Hand"]:
		if h.get_node_or_null(path) == null:
			missing.append(path)
	check(missing.is_empty(), "a human has a head with a face and hair, jointed arms with hands, a torso and knee-jointed legs %s" % str(missing))
	h.alert.reset()
	var sl := h.get_node("Torso/ShoulderL") as Node3D
	var lo := 9.0
	var hi := -9.0
	for i in 240:
		await get_tree().process_frame
		lo = minf(lo, sl.rotation.x)
		hi = maxf(hi, sl.rotation.x)
	check(hi - lo > 0.2, "arms swing while the human walks (%.2f rad)" % (hi - lo))
	h.pose_body(0.0)
	var gaps: Array = []
	var bends := true
	for i in 2:
		var foot := h.left_foot if i == 0 else h.right_foot
		var side := "L" if i == 0 else "R"
		var thigh := h.get_node("Legs/Thigh" + side) as Node3D
		var shin := h.get_node("Legs/Shin" + side) as Node3D
		var hip := h.global_transform * (Vector3((-1.0 if i == 0 else 1.0) * Human.HIP_X, Human.HIP_Y, Human.BODY_Z) + (h.get_node("Torso") as Node3D).position)
		var ankle := foot.global_transform * Human.ANKLE
		# Bones run along +Y from the upper joint to the lower one; their
		# rounded ends are centred on the joints (built at rest length).
		gaps.append(snappedf((thigh.global_transform * Vector3(0, -Human.THIGH * 0.5, 0)).distance_to(hip), 0.01))
		gaps.append(snappedf((shin.global_transform * Vector3(0, Human.SHIN * 0.5, 0)).distance_to(ankle), 0.01))
		var knee := (h.get_node("Legs/Knee" + side) as Node3D).global_position
		var fwd := -h.global_basis.z
		fwd.y = 0.0
		bends = bends and (knee - (hip + ankle) * 0.5).dot(fwd.normalized()) > 0.0
	check(gaps.all(func(g: float) -> bool: return g < 0.5) and bends,
		"legs run from hip to foot and bend forward at the knee %s" % str(gaps))
	var head := h.get_node("Torso/Head") as Node3D
	h.alert.force(AlertState.SUSPICIOUS, h.global_transform * Vector3(-40, 0, -12))
	for i in 30:
		h.pose_body(0.1)
	check(head.rotation.y > 0.3, "its head turns toward a noise (%.2f rad)" % head.rotation.y)
	h.alert.force(AlertState.ALERT, h.global_transform * Vector3(0, 0, -20))
	for i in 30:
		h.pose_body(0.1)
	check((h.get_node("Torso/ShoulderR") as Node3D).rotation.x > 1.2, "when it spots you it raises its swatting arm")
	await unload(klvl)

	# Bugs: jointed legs, antennae, eyes, wing veins; legs walk and tuck.
	var want := {"cockroach": 6, "fly": 6, "spider": 8}
	for b: String in want.keys():
		var inst := (load("res://scenes/bugs/%s.tscn" % b) as PackedScene).instantiate()
		var v := inst.get_node("Visual")
		var legs := 0
		var jointed := 0
		for c in v.get_children():
			if c.has_meta(&"group"):
				legs += 1
				var knee_node := c.get_node_or_null("Knee")
				if knee_node and knee_node.get_child_count() > 0 and c.get_child_count() > 1:
					jointed += 1
		var extra := ""
		match b:
			"cockroach":
				extra = "antennae" if v.get_node_or_null("AntennaL/Tip") and v.get_node_or_null("WingCover") else ""
			"fly":
				extra = "veined wings" if v.get_node_or_null("WingL/Vein") and v.get_node_or_null("Eye") else ""
			"spider":
				var eye := v.get_node_or_null("EyeBig") as MeshInstance3D
				var eye_verts := 0
				if eye:
					eye_verts = (eye.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				extra = "eight eyes and fangs" if eye_verts >= 8 * 100 and v.get_node_or_null("Fang") else ""
		check(legs == want[b] and jointed == legs and extra != "" and inst.get_node_or_null("Rig") is BugRig,
			"%s: %d jointed legs, %s, animated by a rig" % [b, legs, extra if extra != "" else "MISSING DETAIL"])
		inst.free()
	var lvl := await load_level(&"kitchen", &"cockroach")
	var p := lvl.player
	p.invuln = 1000.0
	var leg := p.get_node("Visual/LegL1") as Node3D
	face(lvl, 0.0)
	InputRouter.set_touch_move(Vector2(0, 1))
	var ylo := 9.0
	var yhi := -9.0
	for i in 60:
		await get_tree().process_frame
		ylo = minf(ylo, leg.rotation.y)
		yhi = maxf(yhi, leg.rotation.y)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(yhi - ylo > 0.2, "the cockroach's legs scuttle as it runs (%.2f rad)" % (yhi - ylo))
	for i in 60:
		await get_tree().process_frame
	check(absf(leg.rotation.y - float(leg.get_meta(&"base_yaw"))) < 0.05, "and settle when it stops")
	await unload(lvl)
	lvl = await load_level(&"kitchen", &"fly")
	var fl := lvl.player as Fly
	fl.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 20, 10)))
	fl.take_off()
	await frames(30)
	var fleg := fl.get_node("Visual/LegR2") as Node3D
	check(absf(fleg.rotation.z - float(fleg.get_meta(&"base_z"))) > 0.3, "the fly tucks its legs in flight")
	await unload(lvl)

	# Bug food.
	lvl = await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	p = lvl.player
	var hud := _hud(lvl)
	await _grab(lvl, &"sugar_cube")
	check(p.has_effect(&"speed") and is_equal_approx(p.speed_scale(), 1.35), "Sugar Cube: Sugar Rush makes you 35% faster")
	await get_tree().process_frame
	check(String(hud._effects.text).contains("SUGAR RUSH"), "the HUD shows active effects and their timers (%s)" % hud._effects.text)
	var before := p.hits_left
	await _grab(lvl, &"cheese")
	check(p.hits_left == before + 1 and String(hud._lives.text).count("O") == before + 1, "Cheese Crumb: one extra shell (%s)" % hud._lives.text)
	var got := lvl.crumbs_got
	await _grab(lvl, &"kibble")
	check(lvl.crumbs_got == got + 2, "Dog Kibble counts as two crumbs")
	await _grab(lvl, &"coffee_bean")
	p._dodge_cd = 1.0
	p.sense_active = true
	var sense0 := p.sense_meter
	await frames(10)
	check(p.has_effect(&"wired") and p._dodge_cd < 0.6 and p.sense_meter >= sense0, "Coffee Bean: dodges recharge fast and Sense doesn't run down")
	p._end_sense()
	await _grab(lvl, &"honey_drop")
	check(is_equal_approx(p.noise_scale(), 0.3), "Honey Drop: steps 70% quieter")
	PowerUps.apply(load("res://resources/items/mint_leaf.tres"), p)
	p.global_position = Vector3(20, 0.8, 60)
	await frames(3)
	check(not p.is_scent_active(), "Mint Leaf: no scent trail for the dog")
	check(lvl.run.foods_eaten == 5 and lvl.run.score(GameManager.scoring, 240.0)["lines"].any(
		func(l: Array) -> bool: return String(l[0]).begins_with("Bug food")), "eating counts on the score screen")

	# Crumb gems.
	var stunned0 := lvl.run.threats_stunned
	var human := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	human.force_present(true)
	await _grab(lvl, &"gem_amber")
	var frozen := PerceptionSystem.threats.filter(func(t: Threat) -> bool: return t.present and t.stun_time > 0.0)
	check(frozen.size() > 0 and frozen.size() == PerceptionSystem.threats.filter(func(t: Threat) -> bool: return t.present).size()
		and lvl.run.threats_stunned == stunned0, "Amber: every person and pet freezes (%d), without counting as tricked" % frozen.size())
	var crumb: Crumb = null
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		if lvl.is_ancestor_of(c) and not (c as Crumb).taken and not (c as Crumb).golden:
			crumb = c
			break
	var diamond := _item(lvl, &"gem_diamond")
	diamond.collect()
	p.global_position = crumb.global_position + Vector3(15, 0.2, 0)
	var d0 := crumb.global_position.distance_to(p.global_position)
	await frames(10)
	check(p.has_effect(&"magnet") and (crumb.taken or crumb.global_position.distance_to(p.global_position) < d0 - 3.0),
		"Diamond: crumbs fly toward you")
	PerceptionSystem.add_alarm_from_sight(1.0)
	PowerUps.apply(load("res://resources/items/gem_emerald.tres"), p)
	PerceptionSystem.add_alarm_from_sight(5.0)
	check(PerceptionSystem.alarm == 0.0 and not PerceptionSystem.alarm_active, "Emerald: the alarm empties and stays empty")
	p.invuln = 0.0
	PowerUps.apply(load("res://resources/items/gem_ruby.tres"), p)
	var hits := p.hits_left
	check(not p.take_hit(&"test", p.global_position) and p.hits_left == hits, "Ruby: Iron Shell blocks a hit")
	p.global_position = Vector3(-20, 0.8, 60)
	p.clear_effects()
	await frames(70)
	var vis0 := p.compute_visibility(1.0, PerceptionSystem.config)
	PowerUps.apply(load("res://resources/items/gem_amethyst.tres"), p)
	var vis1 := p.compute_visibility(1.0, PerceptionSystem.config)
	check(vis1 > 0.0 and vis1 <= vis0 * 0.21, "Amethyst: Shadow Cloak makes you near-invisible (%.2f -> %.2f)" % [vis0, vis1])
	human.stun_time = 0.0
	human.alert.reset()
	p.global_position = human.global_position + Vector3(8, 0.8, 0)
	PowerUps.apply(load("res://resources/items/gem_sapphire.tres"), p)
	var decoy := lvl.find_children("*", "DecoyEcho", true, false)
	await frames(40)
	check(not decoy.is_empty() and human.alert.state > AlertState.UNAWARE and human.alert.last_known.distance_to((decoy[0] as Node3D).global_position) < 2.0,
		"Sapphire: the echo decoy draws the human to where you stood")
	check(lvl.run.gems.size() == 2 and SaveSystem.gems_found().has("gem_amber"), "found gems are kept in your save")
	lvl.run.won = true
	check(bool(lvl.run.badges(240.0)["gem_hunter"]), "two gems in a won run earns the Gem Hunter badge")
	await unload(lvl)


# --- Update: time to read pickups, gentler touch look ----------------------------

func _touch_turn(lvl: Level, at: Vector2, px: float) -> Array:
	var cam := lvl.camera
	var yaw0 := cam.yaw
	touch(3, at, true)
	drag(3, at + Vector2(px, 0), Vector2(px, 0))
	await get_tree().process_frame
	var first := absf(cam.yaw - yaw0)
	await frames(60)
	touch(3, at + Vector2(px, 0), false)
	return [first, absf(cam.yaw - yaw0)]


func _phase10() -> void:
	print("-- Update: pickups stay on screen longer, slower and smoother touch look")
	SaveSystem.data = SaveSystem.default_data()
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	var hud := _hud(lvl)
	await _grab(lvl, &"gem_amber")
	check(hud._pickup.visible and String(hud._pickup_title.text).contains("AMBER") and String(hud._pickup_text.text).contains("Freeze"),
		"picking up a gem shows its name and what it does (%s)" % hud._pickup_title.text)
	lvl.set_hint("Threat stunned!")
	await frames(5 * 60)
	check(hud._pickup.visible and hud._pickup.modulate.a > 0.95 and String(hud._pickup_text.text).contains("Freeze"),
		"the gem's description stays fully readable for 5 seconds, even when other messages pop up")
	await frames(150)
	check(not hud._pickup.visible, "then fades away")
	await _grab(lvl, &"sugar_cube")
	await frames(3 * 60)
	var food_up: bool = hud._pickup.visible and hud._pickup.modulate.a > 0.95
	await frames(2 * 60)
	check(food_up and not hud._pickup.visible, "bug food shows for about 3.5 seconds")

	# Touch look: drag on the open screen (not the stick or buttons).
	SaveSystem.set_setting("touch_controls", "on")
	await frames(2)
	var tc: TouchControls = null
	for n in lvl.find_children("*", "Control", true, false):
		if n is TouchControls:
			tc = n
	var at := Vector2(tc.size.x * 0.55, tc.size.y * 0.3)
	var turn: Array = await _touch_turn(lvl, at, 100.0)
	check(turn[1] > 0.15 and turn[1] < 0.3, "a 100-pixel drag turns the view gently (%.2f rad; it was 0.56)" % turn[1])
	check(turn[0] < turn[1] * 0.4, "the turn eases in over several frames instead of snapping (%.2f of %.2f)" % [turn[0], turn[1]])
	SaveSystem.set_setting("touch_look_sensitivity", 0.5)
	var slow: Array = await _touch_turn(lvl, at, 100.0)
	check(absf(slow[1] - turn[1] * 0.5) < 0.03, "\"Touch look speed\" in Settings scales it (%.2f at 0.5x)" % slow[1])
	SaveSystem.set_setting("touch_look_sensitivity", 1.0)
	SaveSystem.set_setting("touch_controls", "auto")
	await unload(lvl)


# --- Update: fly flight, playful/alert animals, people's activities ---------------

func _fly_hold(f: Fly, move: Vector2, up: bool, n: int) -> float:
	var y0 := f.global_position.y
	InputRouter.set_touch_move(move)
	InputRouter.set_touch_action(&"jump", up)
	await frames(n)
	InputRouter.set_touch_move(Vector2.ZERO)
	InputRouter.set_touch_action(&"jump", false)
	return f.global_position.y - y0


func _place_human(h: Human, pos: Vector3, yaw: float) -> void:
	h.route = PackedVector3Array()
	h.global_position = pos
	h._body_pos = pos
	h.rotation.y = yaw
	h._plant_feet(pos, yaw)
	h._body_vel = Vector3.ZERO
	h._glide_dur = 0.0
	h.reset_physics_interpolation()


func _phase11() -> void:
	print("-- Update: fly flight and moves, playful and alert animals, people's activities")
	SaveSystem.data = SaveSystem.default_data()

	# Flight: level by default, hover holds height cheaply, look or Up to climb.
	var lvl := await load_level(&"kitchen", &"fly")
	HouseClock.set_hour(13.9)
	var f := lvl.player as Fly
	f.invuln = 1000.0
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(20, 22, 62)))
	f.take_off()
	face(lvl, -PI * 0.5)
	lvl.camera.pitch = FollowCamera.DEFAULT_PITCH
	await frames(40)
	f.stamina = 99.0
	var dy := await _fly_hold(f, Vector2(0, 1), false, 90)
	check(absf(dy) < 2.0, "flying forward stays level (it used to sink toward the floor) (dy %.1f)" % dy)
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(20, 22, 62)))
	await frames(30)
	f.stamina = 5.0
	dy = await _fly_hold(f, Vector2.ZERO, false, 120)
	check(f.hovering and absf(dy) < 1.5 and f.stamina > 5.0 - 2.0 * Fly.HOVER_DRAIN - 0.1,
		"letting go hovers in place and costs a third of the stamina (dy %.1f, stamina %.2f)" % [dy, f.stamina])
	f.stamina = 99.0
	dy = await _fly_hold(f, Vector2.ZERO, true, 60)
	check(dy > 3.0, "holding Up climbs (%.1f)" % dy)
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-20, 20, 62)))
	face(lvl, PI * 0.5)
	lvl.camera.pitch = FollowCamera.DEFAULT_PITCH + 0.6
	f.stamina = 99.0
	dy = await _fly_hold(f, Vector2(0, 1), false, 60)
	check(dy > 3.0, "tilting the view up while flying forward climbs (%.1f)" % dy)
	SaveSystem.set_setting("fly_follow_look", false)
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-20, 20, 62)))
	await frames(20)
	dy = await _fly_hold(f, Vector2(0, 1), false, 60)
	check(absf(dy) < 2.0, "with \"Fly where you look\" off, the same tilt keeps you level (%.1f)" % dy)
	SaveSystem.set_setting("fly_follow_look", true)
	lvl.camera.pitch = FollowCamera.DEFAULT_PITCH

	# Updrafts: the stove's warm air while cooking lifts you and refills stamina.
	HouseClock.set_hour(7.2)
	await frames(2)
	var heat := lvl.find_child("StoveHeat", true, false) as Thermal
	check(heat != null and heat.is_active(), "the stove gives off warm air while cooking")
	f.teleport_to(Transform3D(Basis.IDENTITY, heat.global_position + Vector3(0, -8, 0)))
	f.stamina = 1.5
	var y0 := f.global_position.y
	await frames(60)
	check(f.global_position.y > y0 + 2.0 and f.stamina > 2.5, "an updraft lifts the fly and refills its stamina (%.1f, %.1f)" % [f.global_position.y - y0, f.stamina])
	# Run out of stamina beside the stove, then drift into its warm air.
	f.teleport_to(Transform3D(Basis.IDENTITY, heat.global_position + Vector3(-30, -6, 25)))
	f.stamina = 0.0
	var was_gliding := false
	for i in 60:
		await get_tree().physics_frame
		if f.gliding:
			was_gliding = true
			break
	f.global_position = heat.global_position + Vector3(0, -6, 0)
	await frames(90)
	check(was_gliding and not f.gliding, "a gliding fly can catch an updraft and fly again (%s, %s, stamina %.1f, flying %s)" % [was_gliding, f.gliding, f.stamina, f.flying])

	# Pester: buzz a person's face - they flail and can't see you.
	var cook := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	cook.force_present(true)
	_place_human(cook, Vector3(20, 0, 40), 0.0)
	await frames(5)
	f.teleport_to(Transform3D(Basis.IDENTITY, cook.eye_position() + Vector3(4, 0, -3)))
	f.stamina = 9.0
	await frames(2)
	check(f.pester_target() == cook and f.get_action_labels()["interact"] == "Pester", "near a person's head, Use becomes Pester")
	f._do_interact()
	await frames(2)
	check(cook.flustered > 0.0 and not cook.can_see(f) and lvl.run.pesters == 1, "pestered, they flail and can't see you for a few seconds")
	check(not cook.pestered(f), "they can't be pestered again straight away")
	await unload(lvl)

	# Animals: sharper in each room and as the house escalates.
	var aw := {}
	for room in ROOMS:
		var rl := await load_level(room, &"cockroach")
		var pet := first_in_group(Phys.GROUP_PET, rl) as Pet
		aw[room] = snappedf(pet.awareness, 0.01) if pet else 0.0
		await unload(rl)
	check(aw[&"kitchen"] > 0.0 and aw[&"kitchen"] < aw[&"living_room"] and aw[&"living_room"] < aw[&"backyard"],
		"every room has an animal, and each room's animals are sharper than the last %s" % str(aw))
	lvl = await load_level(&"backyard", &"cockroach")
	HouseClock.set_hour(7.2)
	var p := lvl.player
	p.invuln = 1000.0
	var dog := first_in_group(Phys.GROUP_PET, lvl) as Pet
	dog.force_present(true)
	dog.process_mode = Node.PROCESS_MODE_DISABLED
	dog.global_position = Vector3(-10, 0.5, 30)
	dog.rotation.y = 0.0
	p.global_position = Vector3(-10, 0.6, 22)
	await frames(70)
	var gains := []
	for a in [1.0, 1.6]:
		dog.awareness = a
		dog.alert.reset()
		for i in 10:
			dog._sense(0.1)
		gains.append(dog.alert.suspicion)
	PerceptionSystem.escalation_stage = 2
	var esc := dog.effective_awareness()
	PerceptionSystem.escalation_stage = 0
	check(gains[1] > gains[0] * 1.4 and is_equal_approx(esc, 1.6 * 1.2),
		"a sharper animal notices faster, and escalation sharpens it further (%.2f vs %.2f, %.2f)" % [gains[0], gains[1], esc])
	dog.awareness = 1.6
	dog.process_mode = Node.PROCESS_MODE_INHERIT

	# Playful: chases the ball, distracted while it plays.
	dog.alert.reset()
	dog.start_playing(&"toy")
	var toy := dog._toy
	var toy0 := toy.global_position if toy else Vector3.ZERO
	await frames(10)
	check(dog.mood == Pet.Mood.PLAY and dog.perception_mult() == Pet.PLAY_SEE_MULT, "a playing animal is in a playful mood and half as watchful")
	var moved := false
	for i in 480:
		await get_tree().physics_frame
		if toy and toy.global_position.distance_to(toy0) > 2.0:
			moved = true
			break
	check(moved, "it goes after its ball and knocks it around")
	dog.alert.force(AlertState.SUSPICIOUS, p.global_position)
	await frames(40)
	var tail := dog.get_node("Visual/Tail") as Node3D
	check(dog.mood == Pet.Mood.ALERT and dog.play == &"" and tail.rotation.x < -1.0,
		"anything suspicious ends play: alert, tail up stiff (%.2f)" % tail.rotation.x)
	dog.alert.reset()
	await frames(5)

	# Fetch: the gardener throws the ball and the dog runs after it.
	var gardener: Human = null
	for n in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
		if lvl.is_ancestor_of(n) and String(n.name).begins_with("Gardener"):
			gardener = n
	gardener.force_present(true)
	_place_human(gardener, Vector3(20, 0, 30), PI * 0.5)
	# Out of everyone's sight so nothing interrupts the game of fetch.
	PerceptionSystem.scent.wipe_sphere(p.global_position, 40.0)
	p.global_position = Vector3(108, 0.6, 99)
	dog.global_position = Vector3(10, 0.5, 30)
	dog.stop_playing()
	dog.alert.reset()
	gardener.alert.reset()
	# Same throw every run, and well clear of the dog's 8:36 nap.
	HouseClock.set_hour(7.7)
	seed(4242)
	await frames(5)
	gardener.start_activity({"kind": &"fetch", "time": 9.0})
	var fetched := false
	var carried := false
	var why := ""
	for i in 600:
		await get_tree().physics_frame
		if fetched and dog.play != &"fetch" and why == "":
			why = "stopped at %d: scared %.1f wet %.1f act %s alert %d stuck %.1f toy %s dog %s mood %d" % [i, dog.scared, dog.wet, dog.idle_act, dog.alert.state, dog._fetch_stuck_s, str(dog._toy.global_position) if dog._toy else "none", str(dog.global_position), dog.mood]
		fetched = fetched or dog.play == &"fetch"
		carried = carried or dog._carrying
		if carried:
			break
	if not carried:
		print("     fetch stopped early: ", why)
	check(fetched and carried, "the gardener throws the ball and the dog fetches it (%s %s, dog %s/%d, gardener %s/%d)" % [fetched, carried, dog.play, dog.alert.state, gardener.activity, gardener.alert.state])
	dog.stop_playing()

	# Watering washes your scent off but knocks you back; kneeling sees close by.
	gardener.end_activity()
	_place_human(gardener, Vector3(-45, 0, -14), 0.0)
	await frames(3)
	gardener.start_activity(gardener.activities[0])
	# Freeze the gardener mid-watering (a bug in plain view would interrupt them).
	gardener.process_mode = Node.PROCESS_MODE_DISABLED
	p.global_position = Vector3(-58, 0.6, -22)
	await frames(10)
	check(gardener._stream != null and not p.is_scent_active() and p.external_velocity.length() > 1.0,
		"watering the flowers: the spray washes your scent away and pushes you")
	gardener.process_mode = Node.PROCESS_MODE_INHERIT
	gardener.end_activity()
	_place_human(gardener, Vector3(80, 0, 22), -PI * 0.5)
	gardener.alert.reset()
	p.global_position = Vector3(70, 0.6, 22)
	await frames(3)
	var standing_sees := gardener.can_see(p)
	p.global_position = Vector3(108, 0.6, 99)
	gardener.start_activity(gardener.activities[2])
	await frames(90)
	var torso := gardener.get_node("Torso") as Node3D
	p.global_position = Vector3(70, 0.6, 22)
	await frames(3)
	check(not standing_sees and gardener.activity == &"kneel" and gardener.can_see(p) and torso.position.y < -10.0,
		"kneeling at the vegetables, the gardener spots a bug close behind them")
	gardener.end_activity()
	await unload(lvl)

	# A low-flying fly gets leapt at.
	lvl = await load_level(&"living_room", &"fly")
	HouseClock.set_hour(7.2)
	f = lvl.player as Fly
	f.invuln = 1000.0
	var cat := first_in_group(Phys.GROUP_PET, lvl) as Pet
	cat.force_present(true)
	cat.global_position = Vector3(0, 0.5, 20)
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 7, 15)))
	f.take_off()
	f.stamina = 99.0
	await frames(5)
	var floor_y := cat.global_position.y
	var top := floor_y
	cat.force_alert(AlertState.ALERT, f.global_position)
	for i in 150:
		await get_tree().physics_frame
		f.global_position = Vector3(0, 7, 15)
		top = maxf(top, cat.global_position.y)
	check(top > floor_y + 4.0, "the cat leaps at a fly hovering just above it (up %.1f)" % (top - floor_y))
	cat.alert.reset()
	cat.global_position = Vector3(0, 0.5, 20)
	cat._snap_cd = 0.0
	await frames(5)
	f.teleport_to(Transform3D(Basis.IDENTITY, cat.eye_position() + Vector3(3, 1, 0)))
	f.stamina = 9.0
	f._do_interact()
	check(cat.play == &"snap", "pestering a pet makes it playful: it snaps at the fly")
	await unload(lvl)

	# People's activities: the cook drops crumbs; the reader sits behind the paper; naps are blind.
	lvl = await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(7.2)
	cook = first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	var kinds := []
	for k: int in cook.activities.keys():
		kinds.append(String(cook.activities[k]["kind"]))
	kinds.sort()
	check(kinds == ["cook", "dishes", "fridge", "snack", "sweep"], "the cook cooks, does the dishes, snacks, opens the fridge and sweeps on their rounds %s" % str(kinds))
	_place_human(cook, Vector3(5, 0, -17.5), PI)
	cook.start_activity(cook.activities[2])
	var got := lvl.crumbs_got
	await frames(400)
	var dropped := lvl.find_children("DroppedCrumb*", "Crumb", true, false)
	check(dropped.size() == 2, "cooking drops crumbs on the floor (%d)" % dropped.size())
	var crumb_at := Vector3.ZERO
	if not dropped.is_empty():
		crumb_at = (dropped[0] as Node3D).global_position
		lvl.player.teleport_to(Transform3D(Basis.IDENTITY, crumb_at + Vector3.UP * 0.3))
		await frames(4)
	# Two crumbs can land side by side, so grabbing one may collect both.
	check(lvl.crumbs_got > got and not dropped.is_empty() and (dropped[0] as Crumb).taken, "and you can grab them (crumb %s taken %s, bug %s, got %d->%d)" % [
		crumb_at, (dropped[0] as Crumb).taken if not dropped.is_empty() else false, lvl.player.global_position, got, lvl.crumbs_got])
	await unload(lvl)

	lvl = await load_level(&"living_room", &"cockroach")
	HouseClock.set_hour(8.2)
	p = lvl.player
	p.invuln = 1000.0
	var reader := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	reader.force_present(true)
	_place_human(reader, Vector3(62, 0, -23), 0.0)
	var eye_standing := reader.eye_position().y
	reader.start_activity(reader.activities[8])
	await frames(120)
	p.global_position = Vector3(62, 0.6, 10)
	await frames(5)
	var paper := reader.get_node("Torso/ReadingPaper") as Node3D
	reader._peek = 0.0
	check(reader.is_sitting() and paper.visible and reader.eye_position().y < eye_standing - 15.0,
		"the reader sits down in the armchair with the paper up")
	check(not reader.can_see(p), "behind the paper they can't see across the room")
	reader.end_activity()
	_place_human(reader, Vector3(-10, 0, -23), 0.0)
	reader.start_activity(reader.activities[1])
	await frames(60)
	p.global_position = Vector3(-10, 0.6, -14)
	await frames(5)
	check(reader.activity == &"nap" and not reader.can_see(p) and reader._hearing_mult() < 0.5, "napping on the couch they can't see and barely hear")
	PerceptionSystem.emit_player_noise(reader.global_position + Vector3(2, 0.5, 2), 3.0)
	await frames(10)
	check(reader.activity == &"", "a loud noise right next to them wakes them up")
	await unload(lvl)



# --- Update: touch look stick and look-speed button --------------------------------

func _stick_turn(lvl: Level, tc: TouchControls, push: Vector2, n: int) -> float:
	await frames(45)  # let the previous turn finish easing out
	var yaw0 := lvl.camera.yaw
	touch(4, tc.look_center, true)
	drag(4, tc.look_center + push, push)
	await frames(n)
	var turned := absf(lvl.camera.yaw - yaw0)
	touch(4, tc.look_center + push, false)
	return turned


func _phase12() -> void:
	print("-- Update: touch look stick with a look-speed button")
	SaveSystem.data = SaveSystem.default_data()
	SaveSystem.set_setting("touch_controls", "on")
	var lvl := await load_level(&"kitchen", &"cockroach")
	await frames(3)
	var tc: TouchControls = null
	for n in lvl.find_children("*", "Control", true, false):
		if n is TouchControls:
			tc = n
	var r := tc.look_radius
	var sense_top := float(tc._btn_pos[&"sense"].y) - float(tc._btn_r[&"sense"])
	var overlaps := false
	for k: StringName in TouchControls.ACTIONS:
		var bp: Vector2 = tc._btn_pos[k]
		var br: float = tc._btn_r[k]
		overlaps = overlaps or bp.distance_to(tc.look_center) < br + r or bp.distance_to(tc.speed_center) < br + tc.speed_radius
	check(tc.look_center.x > tc.size.x * 0.5 and tc.look_center.y + r <= sense_top and not overlaps
		and tc.speed_center.distance_to(tc.look_center) < r + tc.speed_radius + 30.0,
		"a look stick sits on the right above the buttons, with the speed button beside it")
	var full := tc.look_radius
	var t1: float = await _stick_turn(lvl, tc, Vector2(full, 0), 60)
	var t2: float = await _stick_turn(lvl, tc, Vector2(full, 0), 120)
	check(t1 > 0.8 and t2 > t1 * 1.6, "holding the look stick keeps the view turning (%.2f rad in 1 s, %.2f in 2 s)" % [t1, t2])
	var gentle: float = await _stick_turn(lvl, tc, Vector2(full * 0.4, 0), 60)
	check(gentle < t1 * 0.25, "a small push turns gently, for fine aiming (%.2f vs %.2f)" % [gentle, t1])
	await frames(40)
	var yaw_after := lvl.camera.yaw
	await frames(30)
	check(absf(lvl.camera.yaw - yaw_after) < 0.01, "letting go stops the turn")
	var pitch0 := lvl.camera.pitch
	await _stick_turn(lvl, tc, Vector2(0, full), 40)
	check(lvl.camera.pitch < pitch0 - 0.2, "pushing the stick down looks down")
	check(TouchControls.speed_label(float(SaveSystem.get_setting("touch_look_sensitivity", 1.0))) == "1x", "the speed button shows the look speed (1x)")
	touch(5, tc.speed_center, true)
	await frames(2)
	touch(5, tc.speed_center, false)
	var faster := float(SaveSystem.get_setting("touch_look_sensitivity", 1.0))
	check(is_equal_approx(faster, 1.5), "tapping it steps the look speed up (1x -> %s)" % TouchControls.speed_label(faster))
	var t3: float = await _stick_turn(lvl, tc, Vector2(full, 0), 60)
	check(absf(t3 - t1 * 1.5) < t1 * 0.15, "and the stick turns faster to match (%.2f vs %.2f)" % [t3, t1])
	var seen: Array[String] = [TouchControls.speed_label(faster)]
	for i in 4:
		seen.append(TouchControls.speed_label(tc.cycle_look_speed()))
	check(seen == ["1.5x", "2x", "0.5x", "0.75x", "1x"], "it cycles 1.5x, 2x, 0.5x, 0.75x, back to 1x %s" % str(seen))
	SaveSystem.set_setting("touch_controls", "auto")
	await unload(lvl)



# --- Update: the upgraded dog, and a cat and a dog together in the harder rooms ---

func _pets(lvl: Node) -> Array[Pet]:
	var out: Array[Pet] = []
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PET):
		if lvl.is_ancestor_of(n):
			out.append(n as Pet)
	return out


func _mats_under(root: Node) -> Dictionary:
	var have := {}
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.material_override:
			have[mi.material_override.resource_path.get_file().get_basename()] = true
	return have


func _phase13() -> void:
	print("-- Update: upgraded dog; a cat and a dog playing together in the harder rooms")
	SaveSystem.data = SaveSystem.default_data()

	# The dog's new coat and face.
	var dog_scene := (load("res://scenes/threats/dog.tscn") as PackedScene).instantiate()
	var mats := _mats_under(dog_scene.get_node("Visual"))
	var head := dog_scene.get_node("Visual/Head")
	check(mats.has("dog_brown") and mats.has("dog_white") and mats.has("dog_black") and mats.has("cloth_red")
		and head.get_node_or_null("Muzzle") and head.get_node_or_null("EarL/Flap") and _mats_under(head.get_node("EarL")).size() == 1,
		"the dog has a tan, white and black coat, a white muzzle, floppy ears and a collar")
	dog_scene.free()

	# Who lives where.
	var who := {}
	for room in ROOMS:
		var rl := await load_level(room, &"cockroach")
		var kinds: Array[String] = []
		for pet in _pets(rl):
			kinds.append("puppy" if pet.is_puppy() else ("dog" if pet.barks else "cat"))
		kinds.sort()
		who[room] = kinds
		await unload(rl)
	check(who[&"kitchen"] == ["puppy"] and who[&"living_room"] == ["cat", "dog"] and who[&"backyard"] == ["cat", "dog"],
		"the kitchen has the puppy; the living room and backyard each have a cat and a dog %s" % str(who))

	# Playing chase together.
	var lvl := await load_level(&"living_room", &"cockroach")
	HouseClock.set_hour(7.2)
	var p := lvl.player
	p.invuln = 1000.0
	p.global_position = Vector3(-60, 0.6, 46)
	var cat: Pet = null
	var dog: Pet = null
	for pet in _pets(lvl):
		if pet.barks:
			dog = pet
		else:
			cat = pet
	for pet in [cat, dog]:
		pet.force_present(true)
		pet.stop_playing()
		pet.alert.reset()
	cat.global_position = Vector3(0, 0.5, 18)
	dog.global_position = Vector3(10, 0.5, 18)
	await frames(3)
	check(dog.start_buddy_play(cat) and dog.play == &"buddy" and cat.play == &"buddy" and dog.buddy == cat
		and dog.buddy_role != cat.buddy_role, "the dog starts a game of chase with the cat")
	var roles := {}
	var cat_ran := 0.0
	var dog_ran := 0.0
	var cat_last := cat.global_position
	var dog_last := dog.global_position
	var both_distracted := false
	for i in 420:
		await get_tree().physics_frame
		if dog.play != &"buddy":
			break
		roles[String(dog.buddy_role)] = true
		cat_ran += cat.global_position.distance_to(cat_last)
		dog_ran += dog.global_position.distance_to(dog_last)
		cat_last = cat.global_position
		dog_last = dog.global_position
		both_distracted = both_distracted or (dog.perception_mult() < 1.0 and cat.perception_mult() < 1.0)
	check(roles.size() == 2 and cat_ran > 8.0 and dog_ran > 8.0,
		"they chase, tag and swap who's 'it' %s (ran %.0f and %.0f)" % [str(roles.keys()), cat_ran, dog_ran])
	check(both_distracted, "while they play, both are distracted")
	cat.stop_playing()
	cat.alert.reset()
	dog.alert.reset()
	await frames(2)
	dog.start_buddy_play(cat)
	await frames(10)
	cat.force_alert(AlertState.SUSPICIOUS, cat.global_position + Vector3(5, 0, 5))
	await frames(3)
	check(cat.play == &"" and dog.play == &"" and dog.alert.state >= AlertState.SUSPICIOUS,
		"if one of them spots something, the game stops and the other is on guard too")
	await unload(lvl)

	# The dog sniffs out a bug hiding nearby.
	lvl = await load_level(&"backyard", &"cockroach")
	HouseClock.set_hour(7.2)
	p = lvl.player
	dog = null
	cat = null
	for pet in _pets(lvl):
		if pet.barks:
			dog = pet
		else:
			cat = pet
	var gardener: Human = null
	for n in get_tree().get_nodes_in_group(Phys.GROUP_HUMAN):
		if lvl.is_ancestor_of(n) and String(n.name).begins_with("Gardener"):
			gardener = n
	gardener.force_present(true)
	_place_human(gardener, Vector3(20, 0, -20), 0.0)
	cat.process_mode = Node.PROCESS_MODE_DISABLED
	dog.force_present(true)
	dog.stop_playing()
	dog._play_cd = 999.0
	dog.alert.reset()
	dog.global_position = Vector3(-50, 0.5, 49)
	p.global_position = Vector3(-55, 0.6, 40)
	InputRouter.set_touch_action(&"secondary", true)
	await frames(5)
	var hits := p.hits_left
	var pointed := false
	var nose_down := false
	for i in 240:
		await get_tree().physics_frame
		pointed = pointed or dog.pointing > 0.0
		nose_down = nose_down or (dog.pointing > 0.0 and (dog.get_node("Visual/Head") as Node3D).rotation.x < -0.5)
		if pointed and nose_down and PerceptionSystem.alarm > 0.1:
			break
	check(p.is_hidden_safe() and pointed, "a dog sniffs out a bug hiding under the doghouse")
	check(nose_down and PerceptionSystem.alarm > 0.1 and gardener.alert.state >= AlertState.SEARCHING,
		"nose to the ground, it barks at the spot: the alarm climbs and the gardener comes to look (%.2f)" % PerceptionSystem.alarm)
	check(p.hits_left == hits, "you're still safe in there - but it's time to move")
	InputRouter.set_touch_action(&"secondary", false)
	p.global_position = Vector3(-20, 0.6, 70)
	await frames(10)
	check(dog.pointing <= 0.0, "slip away and it stops barking at the empty spot")

	# The backyard cat leaps up onto things.
	cat.process_mode = Node.PROCESS_MODE_INHERIT
	dog.process_mode = Node.PROCESS_MODE_DISABLED
	var perches := 0
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PERCH):
		if lvl.is_ancestor_of(n):
			perches += 1
	cat.stop_playing()
	cat._play_cd = 999.0
	cat.global_position = Vector3(-20, 0.5, 40)
	cat.force_present(true)
	cat.force_alert(AlertState.SEARCHING, Vector3(-20, 27.5, 16))
	var top := 0.0
	for i in 600:
		await get_tree().physics_frame
		top = maxf(top, cat.global_position.y)
		if top > 20.0:
			break
	check(perches >= 3 and top > 20.0, "the backyard cat leaps up onto the picnic table (%d perches, up %.1f)" % [perches, top])
	await unload(lvl)



# --- Update: five new bugs in the shade, a smoother and friendlier game ----------

const NEW_BUGS: Array[StringName] = [&"ant", &"cricket", &"ladybug", &"firefly", &"stink_bug"]


func _quiet_human(lvl: Level, pos: Vector3, yaw: float) -> Human:
	var h := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	h.force_present(true)
	h.end_activity()
	h.activities = {}
	_place_human(h, pos, yaw)
	h.alert.reset()
	return h


func _phase14() -> void:
	print("-- Update: five new bugs in the shade; smoother and friendlier")
	SaveSystem.data = SaveSystem.default_data()

	# The roster and the chain.
	var chain_ok := GameManager.BUG_IDS.size() == 8
	for i in range(1, GameManager.BUG_IDS.size()):
		var s := GameManager.get_bug_stats(GameManager.BUG_IDS[i])
		chain_ok = chain_ok and s != null and s.unlock_after_bug == GameManager.BUG_IDS[i - 1] \
			and ResourceLoader.exists(s.scene_path) and BugGuide.portrait(s.id) != null and s.guide.size() >= 4
	check(chain_ok, "eight bugs, each with a picture and a guide, each unlocked by the one before it")
	var order: Array[StringName] = []
	for id in GameManager.BUG_IDS:
		order.append_array(GameManager.unlock_after_escape(id))
	check(order == [&"fly", &"spider", &"ant", &"cricket", &"ladybug", &"firefly", &"stink_bug"] and GameManager.next_locked_bug() == &"",
		"escaping a room as each bug brings the next one out of the shade, in order %s" % str(order))
	check(SaveSystem.is_bug_new(&"ant") and SaveSystem.is_bug_completed(&"stink_bug"), "new arrivals are marked NEW; escapes are remembered")

	# Bug select: silhouettes in the shade.
	SaveSystem.data = SaveSystem.default_data()
	GameManager.unlock_after_escape(&"cockroach")
	GameManager.unlock_after_escape(&"fly")
	GameManager.unlock_after_escape(&"spider")
	var ant_card := BugSelect.card_for(GameManager.get_bug_stats(&"ant"))
	var cricket_card := BugSelect.card_for(GameManager.get_bug_stats(&"cricket"))
	var cricket_img := cricket_card.find_child("Portrait", true, false) as TextureRect
	var cricket_hint := cricket_card.find_child("Hint", true, false) as Label
	var later_card := BugSelect.card_for(GameManager.get_bug_stats(&"ladybug"))
	var later_hint := (later_card.find_child("Hint", true, false) as Label).text
	later_card.free()
	check(ant_card.find_child("Play", true, false) != null and ant_card.find_child("New", true, false) != null,
		"an unlocked bug's card has its picture, a NEW badge and a Play button")
	check(cricket_img and cricket_img.texture and cricket_img.self_modulate.r == 0.0 and cricket_img.self_modulate.a > 0.8
		and cricket_card.find_child("Play", true, false) == null and cricket_hint.text.contains("Ant"),
		"a locked bug stands in the shade - a dark silhouette - with what brings it out (%s)" % cricket_hint.text)
	check(later_hint.contains("Cricket") and later_hint.contains("first"), "bugs further down say which one to unlock first (%s)" % later_hint)
	SaveSystem.mark_bug_played(&"ant")
	var played_card := BugSelect.card_for(GameManager.get_bug_stats(&"ant"))
	check(played_card.find_child("New", true, false) == null, "playing a new bug clears its NEW badge")
	played_card.free()
	for c in [ant_card, cricket_card]:
		c.free()
	var texts := await _button_texts("res://scenes/ui/bug_select.tscn")
	check(texts.has("Play as Ant") and not texts.has("Play as Cricket"), "the bug select screen offers exactly the unlocked bugs")

	# Each new bug plays: it spawns and walks (the firefly flies).
	var moved: PackedStringArray = []
	for id in NEW_BUGS:
		var bl := await load_level(&"kitchen", id)
		var bp := bl.player
		bp.invuln = 1000.0
		bp.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 66)))
		face(bl, PI * 0.5)
		if bp is Fly:
			(bp as Fly).take_off()
		await frames(10)
		var start := bp.global_position
		InputRouter.set_touch_move(Vector2(0, 1))
		await frames(40)
		InputRouter.set_touch_move(Vector2.ZERO)
		if bp.global_position.distance_to(start) > 2.5 and bp.get_class() == "CharacterBody3D" and bp.get_script():
			moved.append(String(id))
		await unload(bl)
	check(moved.size() == 5, "all five new bugs spawn and move %s" % str(moved))

	# Ant: tiny (hidden in a gap without squeezing), decoys draw threats away.
	var lvl := await load_level(&"kitchen", &"ant")
	HouseClock.set_hour(13.5)
	var ant := lvl.player as Ant
	ant.invuln = 1000.0
	var cook := _quiet_human(lvl, Vector3(-30, 0, 2), PI)
	ant.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.6, -22.5)))
	await frames(5)
	check(ant.is_hidden_safe() and not ant.is_squeezing, "the ant hides in the toe-kick gap without squeezing")
	ant.facing = Vector3(0, 0, 1)
	var decoy := ant.send_decoys()
	check(decoy != null and ant.send_decoys() == null, "Secondary sends a column of decoy ants (then it recharges)")
	var lured := false
	for i in 180:
		await get_tree().physics_frame
		if cook.alert.state >= AlertState.SUSPICIOUS and cook.alert.target_is_lure and is_instance_valid(decoy) \
				and cook.alert.last_known.distance_to(decoy.global_position) < 4.0:
			lured = true
			break
	check(lured, "the cook hears the decoys and goes after them, not the hidden ant")
	await unload(lvl)

	# Cricket: charged leap; chirp throws its voice.
	lvl = await load_level(&"kitchen", &"cricket")
	HouseClock.set_hour(13.5)
	var cr := lvl.player as Cricket
	cr.invuln = 1000.0
	cr.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 70)))
	face(lvl, PI * 0.5)
	await frames(10)
	var y0 := cr.global_position.y
	InputRouter.set_touch_action(&"jump", true)
	await frames(2)
	InputRouter.set_touch_action(&"jump", false)
	var low := cr.global_position.y
	for i in 120:
		await get_tree().physics_frame
		low = maxf(low, cr.global_position.y)
		if not cr.leaping and i > 5:
			break
	check(low - y0 > 1.0 and low - y0 < 4.0, "a quick tap of Jump is just a little hop (up %.1f)" % (low - y0))
	cr.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 70)))
	await frames(10)
	var p0 := cr.global_position
	cr.facing = Vector3(-1, 0, 0)
	InputRouter.set_touch_action(&"jump", true)
	await frames(70)
	InputRouter.set_touch_action(&"jump", false)
	var peak := y0
	for i in 240:
		await get_tree().physics_frame
		peak = maxf(peak, cr.global_position.y)
		if not cr.leaping and i > 5:
			break
	var across := Vector2(cr.global_position.x - p0.x, cr.global_position.z - p0.z).length()
	check(peak > y0 + 15.0 and across > 20.0,
		"held, it charges a leap high enough to reach a chair seat, and far (up %.1f, across %.1f)" % [peak - y0, across])
	# The cook stands with her back to the room; the cricket chirps past her.
	cook = _quiet_human(lvl, Vector3(20, 0, 34), 0.0)
	cr.teleport_to(Transform3D(Basis.IDENTITY, Vector3(20, 0.6, 70)))
	face(lvl, 0.0)
	await frames(10)
	cook.alert.reset()
	cr.ability_cd = 0.0
	var spot := cr.chirp_spot()
	cr.chirp()
	await frames(5)
	check(cook.alert.state >= AlertState.SUSPICIOUS and cook.alert.last_known.distance_to(spot) < 3.0
		and spot.distance_to(cr.global_position) > 12.0 and not cr.chirp(),
		"a chirp makes the cook look where the voice came from, %.0f units from the cricket (then it recharges)" % spot.distance_to(cr.global_position))
	await unload(lvl)

	# Ladybug: shell up, flutter, and the people's soft spot.
	lvl = await load_level(&"kitchen", &"ladybug")
	HouseClock.set_hour(13.5)
	var lb := lvl.player as Ladybug
	lb.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 66)))
	await frames(10)
	lb.invuln = 0.0
	InputRouter.set_touch_action(&"primary", true)
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(5)
	var at := lb.global_position
	var hits := lb.hits_left
	var blocked := not lb.take_hit(&"test", lb.global_position)
	await frames(30)
	check(lb.shelled and blocked and lb.hits_left == hits and lb.global_position.distance_to(at) < 0.5,
		"Shell Up: nothing can hurt the ladybug, but it can't move")
	InputRouter.set_touch_action(&"primary", false)
	InputRouter.set_touch_move(Vector2.ZERO)
	lb.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 30, 66)))
	InputRouter.set_touch_action(&"jump", true)
	var top := lb.global_position.y
	await frames(60)
	InputRouter.set_touch_action(&"jump", false)
	check(top - lb.global_position.y < 5.0, "holding Jump in the air flutters down gently (fell %.1f in 1 s)" % (top - lb.global_position.y))
	lb.teleport_to(Transform3D(Basis.IDENTITY, Vector3(30, 0.6, 60)))
	await frames(30)
	cook = _quiet_human(lvl, Vector3(30, 0, 66), 0.0)
	lb.invuln = 0.0
	cook._attack_cd = 0.0
	cook.alert.force(AlertState.ALERT, lb.global_position)
	var spared := true
	for i in 90:
		await get_tree().physics_frame
		cook.alert.force(AlertState.ALERT, lb.global_position)
		spared = spared and cook._attack_cd <= 0.0
	PerceptionSystem.raise_alarm()
	lb.invuln = 1000.0
	var swung := false
	for i in 120:
		await get_tree().physics_frame
		swung = swung or cook._attack_cd > 0.0
	check(spared and swung, "people won't swat a ladybug - until the alarm is full")
	await unload(lvl)

	# Firefly: glows in flight, dark when it lands; Flash dazzles.
	lvl = await load_level(&"kitchen", &"firefly")
	HouseClock.set_hour(13.5)
	var ff := lvl.player as Firefly
	ff.invuln = 1000.0
	cook = _quiet_human(lvl, Vector3(20, 0, 50), 0.0)
	ff.teleport_to(Transform3D(Basis.IDENTITY, cook.eye_position() + Vector3(6, -4, 0)))
	ff.take_off()
	await frames(10)
	var glow := ff.get_node("Visual/Glow") as Light3D
	var lit := glow.visible and ff.compute_visibility(0.0, PerceptionSystem.config) > 0.0
	ff.sense_meter = ff.stats.sense_max
	ff.toggle_sense()
	check(lit and cook.blind_time > 0.0 and not cook.can_see(ff), "the firefly glows in flight, and its Flash dazzles the cook")
	ff.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 66)))
	ff.land()
	await frames(10)
	check(not glow.visible and ff.compute_visibility(0.0, PerceptionSystem.config) == 0.0, "landed, it goes dark")
	await unload(lvl)

	# Stink bug: three hits, a stink cloud that scatters pets and chokes people.
	lvl = await load_level(&"kitchen", &"stink_bug")
	HouseClock.set_hour(13.5)
	var sb := lvl.player as StinkBug
	sb.invuln = 1000.0
	sb.teleport_to(Transform3D(Basis.IDENTITY, Vector3(20, 0.6, 56)))
	cook = _quiet_human(lvl, Vector3(24, 0, 58), 0.0)
	var pup := first_in_group(Phys.GROUP_PET, lvl) as Pet
	pup.force_present(true)
	pup.stop_playing()
	pup.global_position = Vector3(16, 0.5, 60)
	await frames(5)
	var pup0 := pup.global_position.distance_to(sb.global_position)
	var cloud := sb.release_stink()
	await frames(15)
	var pup_scared := pup.scared > 0.0
	check(sb.stats.max_hits == 3 and cloud != null and pup_scared and cook.stun_time > 0.0 and cook.blind_time > 0.0,
		"the stink bug takes three hits; its cloud makes the puppy bolt and the cook cough")
	await frames(60)
	check(pup.global_position.distance_to(sb.global_position) > pup0 + 5.0 and sb.release_stink() == null and sb.scent_strength() > 1.0,
		"the puppy runs off; the cloud recharges; and your smell lingers")
	await unload(lvl)

	# Friendlier: the how-to-play card the first time you play a bug.
	SaveSystem.data = SaveSystem.default_data()
	SaveSystem.unlock_bug(&"ant")
	SaveSystem.set_setting("touch_controls", "on")
	GameManager.guides_enabled = true
	lvl = await load_level(&"kitchen", &"ant")
	await frames(2)
	var guide := lvl.find_child("BugGuide", true, false) as BugGuide
	var guide_text: PackedStringArray = []
	if guide:
		for l in guide.find_children("*", "Label", true, false):
			guide_text.append((l as Label).text)
	check(guide != null and get_tree().paused and guide_text.has("DECOYS") and guide_text.has("ANT"),
		"the first time you play the ant, a how-to-play card (with its button names) waits for you")
	if guide:
		(guide.find_child("GotIt", true, false) as Button).pressed.emit()
	await frames(2)
	check(not get_tree().paused and SaveSystem.has_seen_guide(&"ant"), "\"Got it\" starts the game")
	await unload(lvl)
	lvl = await load_level(&"kitchen", &"ant")
	await frames(2)
	check(lvl.find_child("BugGuide", true, false) == null, "it doesn't show again")
	GameManager.guides_enabled = false
	GameManager.toggle_pause()
	await frames(2)
	var pm: Node = null
	for n in lvl.find_children("*", "CanvasLayer", true, false):
		if n.has_method("_toggle_help"):
			pm = n
	pm.call("_toggle_help")
	await get_tree().process_frame
	var help_labels: PackedStringArray = []
	for l in (pm.get("_help") as Node).find_children("*", "Label", true, false):
		help_labels.append((l as Label).text)
	check(help_labels.has("ANT") and help_labels.has("DECOYS"), "Pause > Controls shows how to play the bug you're playing")
	GameManager.toggle_pause()
	SaveSystem.set_setting("touch_controls", "auto")
	await unload(lvl)

	# Smoother: auto quality steps down when it runs slowly; far small things cull.
	lvl = await load_level(&"kitchen", &"cockroach")
	GameManager.auto_quality_enabled = true
	SaveSystem.set_setting("quality", "high")
	GameManager._quality_cd = 0.0
	var steps: Array[String] = []
	steps.append("%s" % GameManager.check_frame_rate(60.0))
	steps.append("%s" % GameManager.check_frame_rate(15.0))
	var q1 := String(SaveSystem.get_setting("quality", ""))
	steps.append("%s" % GameManager.check_frame_rate(15.0))
	GameManager._quality_cd = 0.0
	GameManager.check_frame_rate(15.0)
	var q2 := String(SaveSystem.get_setting("quality", ""))
	var sun := lvl.find_child("Sun", true, false) as DirectionalLight3D
	check(steps == ["false", "true", "false"] and q1 == "medium" and q2 == "low" and not sun.shadow_enabled,
		"running slowly steps quality down (high -> medium -> low, shadows off), not more than once every 20 s")
	SaveSystem.set_setting("quality", "medium")
	SaveSystem.set_setting("auto_quality", false)
	GameManager._quality_cd = 0.0
	check(not GameManager.check_frame_rate(10.0), "with Auto quality off in Settings it leaves your choice alone")
	GameManager.auto_quality_enabled = false
	SaveSystem.set_setting("auto_quality", true)
	var crumb_mesh := (load("res://scenes/world/crumb.tscn") as PackedScene).instantiate()
	var culls := (crumb_mesh.find_children("*", "GeometryInstance3D", true, false)[0] as GeometryInstance3D).visibility_range_end
	crumb_mesh.free()
	check(culls > 50.0, "small far-away things (crumbs, pickups, props) stop drawing at a distance")
	await unload(lvl)



# --- Update: smoother play, lifelike people and pets, high-res graphics ----------

func _phase15() -> void:
	print("-- Update: smoother play, lifelike people and pets, high-res graphics")
	SaveSystem.data = SaveSystem.default_data()

	# Smooth at any frame rate: physics interpolation, with per-frame posing
	# riding on the smoothed bodies.
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	var p := lvl.player
	p.invuln = 1000.0
	var cook := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	var pup := first_in_group(Phys.GROUP_PET, lvl) as Pet
	var off := Node.PHYSICS_INTERPOLATION_MODE_OFF
	check(get_tree().physics_interpolation and p.is_physics_interpolated() and p.visual.physics_interpolation_mode == off
		and lvl.camera.physics_interpolation_mode == off and cook.get_node("Torso").physics_interpolation_mode == off
		and cook.get_node("Legs").physics_interpolation_mode == off and pup.get_node("Visual").physics_interpolation_mode == off,
		"motion is smoothed between physics steps (bugs, people, pets and the camera glide at any frame rate)")
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 66)))
	await get_tree().process_frame
	check(p.get_global_transform_interpolated().origin.distance_to(Vector3(40, 0.8, 66)) < 0.6,
		"a teleport doesn't streak across the screen")

	# Forgiving jumps: coyote time and a jump buffer.
	await frames(15)
	var y_floor := p.global_position.y
	p.global_position.y = y_floor + 2.0
	await frames(3)
	InputRouter.set_touch_action(&"jump", true)
	await frames(2)
	InputRouter.set_touch_action(&"jump", false)
	var coyote_ok := p.velocity.y > 2.0
	await frames(60)
	p.global_position.y = y_floor + 9.0
	await frames(20)
	InputRouter.set_touch_action(&"jump", true)
	await frames(2)
	InputRouter.set_touch_action(&"jump", false)
	var late_ok := p.velocity.y <= 0.5
	await frames(60)
	check(coyote_ok and late_ok, "you can still jump a moment after running off an edge (but not once you're falling)")
	p.global_position.y = y_floor + 3.0
	p.velocity = Vector3.ZERO
	var landed_at := -1
	var jumped := false
	for i in 60:
		await get_tree().physics_frame
		if landed_at < 0 and p.global_position.y < y_floor + 0.45 and p.velocity.y < -6.0:
			InputRouter.set_touch_action(&"jump", true)
			InputRouter.set_touch_action(&"jump", false)
			landed_at = i
		if landed_at >= 0 and i > landed_at + 1 and p.velocity.y > 2.0:
			jumped = true
			break
	check(jumped, "a jump pressed just before landing still happens")

	# The camera eases in when a wall gets in the way and back out after.
	var cam := lvl.camera as FollowCamera
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.6, -19)))
	face(lvl, PI)
	cam.snap()
	await frames(12)
	var pulled := cam._len
	# Turn round: the view behind is open again.
	face(lvl, 0.0)
	await frames(3)
	var early := cam._len
	await frames(90)
	var allowed := cam.arm.get_hit_length()
	check(pulled < cam.distance - 1.5 and early > pulled and early < allowed - 0.3 and absf(cam._len - allowed) < 0.3,
		"the camera pulls in when a wall is behind it and eases back out (%.1f -> %.1f -> %.1f of %.1f)" % [pulled, early, cam._len, allowed])

	# People walk, turn and look like people.
	HouseClock.set_hour(13.5)
	cook.force_present(true)
	cook.end_activity()
	cook.activities = {}
	_place_human(cook, Vector3(-30, 0, 20), 0.0)
	cook.alert.reset()
	var foot := cook.left_foot
	var start := foot.global_position
	var goal := start + Vector3(0, 0, -9)
	cook.set_physics_process(false)
	foot.step_to(goal, 0.0, 0.7, true)
	var early_h := 0.0
	var early_d := 0.0
	var mid_h := 0.0
	for i in 42:
		await get_tree().physics_frame
		var k := foot.swing_progress()
		if k >= 0.08 and k < 0.12:
			early_h = foot.global_position.y - start.y
			early_d = Vector2(foot.global_position.x - start.x, foot.global_position.z - start.z).length()
		if k >= 0.45 and k <= 0.55:
			mid_h = foot.global_position.y - start.y
	check(early_d < 9.0 * 0.12 and early_h > 0.5 and mid_h > foot.lift_height * 0.5 and foot.is_planted()
		and foot.global_position.distance_to(goal) < 0.1,
		"a walking step peels up, swings in an arc and lands where its shadow said (lift %.1f, mid %.1f)" % [early_h, mid_h])
	cook.set_physics_process(true)
	_place_human(cook, Vector3(-40, 0, 20), 0.0)
	cook.route = PackedVector3Array([Vector3(-40, 0, 20), Vector3(40, 0, 20)])
	cook._route_i = 1
	cook._pause = 0.0
	var speeds: Array[float] = []
	var last := cook.global_position
	for i in 210:
		await get_tree().physics_frame
		if i > 30:
			speeds.append(cook.global_position.distance_to(last) * 60.0)
		last = cook.global_position
	var mean := 0.0
	var top := 0.0
	for v in speeds:
		mean += v / speeds.size()
		top = maxf(top, v)
	check(mean > 3.0 and top < mean * 2.0, "people glide along as they walk instead of surging with each step (avg %.1f, peak %.1f)" % [mean, top])
	_place_human(cook, Vector3(-30, 0, 20), 0.0)
	cook.route = PackedVector3Array()
	cook.set_physics_process(false)
	var behind := cook.global_position + Vector3(0, 0, 20)
	var turned: Array[float] = []
	for i in 150:
		cook.face_towards(behind, 1.0 / 60.0)
		turned.append(absf(cook.rotation.y))
	check(turned[0] < 0.02 and absf(wrapf(cook.rotation.y - PI, -PI, PI)) < 0.1,
		"people ease into a turn and finish it (first step %.3f rad)" % turned[0])
	cook.rotation.y = 0.0
	cook.set_physics_process(true)
	# Nothing to look at: just a person standing in the kitchen.
	cook.blind_time = 20.0
	cook.alert.reset()
	await frames(2)
	var lids := cook.get_node("Torso/Head/Lids") as Node3D
	var gaze := cook.get_node("Torso/Head/Gaze") as Node3D
	var head := cook.get_node("Torso/Head") as Node3D
	var shut := 0
	var yaws: Array[float] = []
	for i in 600:
		await get_tree().process_frame
		if lids.visible:
			shut += 1
		yaws.append(head.rotation.y)
	yaws.sort()
	check(shut > 0 and shut < 90, "people blink every few seconds (eyes shut %d of 600 frames)" % shut)
	check(yaws[yaws.size() - 1] - yaws[0] > 0.3, "standing calm, they glance around")
	head.rotation.y = 0.0
	cook._glance = Vector2.ZERO
	cook.alert.force(AlertState.SUSPICIOUS, cook.global_position + Basis(Vector3.UP, cook.rotation.y) * Vector3(-30, 0, -20))
	var gaze_led := false
	for i in 4:
		await get_tree().process_frame
		gaze_led = gaze_led or absf(gaze.position.x) > 0.05
	var after6 := absf(head.rotation.y)
	await frames(2)
	check(gaze_led, "their eyes jump to a noise first, then the head follows")
	check(after6 > 0.35, "a sudden noise gets a quick double take (head %.2f rad in 6 frames)" % after6)
	cook.alert.reset()

	# Pets: ease into a run, breathe (and pant), blink, flick an ear.
	pup.force_present(true)
	pup.stop_playing()
	pup.alert.reset()
	pup.global_position = Vector3(10, 0.5, 40)
	pup.velocity = Vector3.ZERO
	pup.reset_physics_interpolation()
	pup.set_physics_process(false)
	await get_tree().physics_frame
	pup._move_to(Vector3(60, 0.5, 40), 10.0, 1.0 / 60.0)
	var first := Vector2(pup.velocity.x, pup.velocity.z).length()
	for i in 60:
		await get_tree().physics_frame
		pup._move_to(Vector3(80, 0.5, 40), 10.0, 1.0 / 60.0)
	var full := Vector2(pup.velocity.x, pup.velocity.z).length()
	check(first < 3.0 and full > 8.5, "pets build up to a run instead of jumping to full speed (%.1f -> %.1f)" % [first, full])
	await get_tree().process_frame
	check(pup._pant > 0.4, "after a run the puppy pants (%.2f)" % pup._pant)
	pup.velocity = Vector3.ZERO
	pup.set_physics_process(true)
	pup.alert.reset()
	var vis := pup.get_node("Visual") as Node3D
	var pl := pup.get_node("Visual/Head/Lids") as Node3D
	var sx: Array[float] = []
	var blinks := 0
	var twitched := false
	for i in 720:
		await get_tree().process_frame
		sx.append(vis.scale.x)
		blinks += 1 if pl.visible else 0
		twitched = twitched or pup._twitch_t > 0.0
	sx.sort()
	check(sx[sx.size() - 1] - sx[0] > 0.015 and blinks > 0, "pets breathe and blink")
	check(twitched or pup.mood != Pet.Mood.CALM, "a calm pet flicks an ear now and then")
	await unload(lvl)

	# Detail: eyes that move and blink, rounder bodies, pet anatomy.
	var human_scene := (load("res://scenes/threats/human.tscn") as PackedScene).instantiate()
	var verts := 0
	for mi in human_scene.find_children("*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).mesh
		if m and m.get_surface_count() > 0:
			verts += (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var cat := (load("res://scenes/threats/cat.tscn") as PackedScene).instantiate()
	var dog := (load("res://scenes/threats/dog.tscn") as PackedScene).instantiate()
	check(human_scene.get_node_or_null("Torso/Head/Gaze") != null and human_scene.get_node_or_null("Torso/Head/Lids") != null
		and cat.get_node_or_null("Visual/Head/Lids") != null and cat.get_node_or_null("Visual/Head/EarL/Inner") != null
		and dog.get_node_or_null("Visual/Head/Lids") != null and verts > 20000,
		"people have moving eyes and eyelids, pets have eyelids and cats inner ears; rounder models (%d vertices a person)" % verts)
	for n in [human_scene, cat, dog]:
		n.free()

	# High-resolution surfaces.
	var tex_ok := true
	var tex_names: PackedStringArray = []
	for mname in ["tile", "wood", "patio", "grass", "carpet", "skin", "hair", "jeans", "cat_orange", "dog_brown", "roach", "ladybug_red"]:
		var m := load("res://assets/materials/%s.tres" % mname) as StandardMaterial3D
		var ok := m.albedo_texture != null and m.normal_texture != null and m.uv1_triplanar and not m.uv1_world_triplanar
		tex_ok = tex_ok and ok
		if not ok:
			tex_names.append(mname)
	var floor_mat := load("res://assets/materials/tile.tres") as StandardMaterial3D
	var wood_tex := load("res://assets/textures/wood.png") as Texture2D
	# Source import settings exist in the project (not in an exported pack).
	var vram_ok := true
	var cfg := ConfigFile.new()
	if cfg.load("res://assets/textures/wood.png.import") == OK and cfg.has_section("params"):
		vram_ok = int(cfg.get_value("params", "compress/mode", 0)) == 2 and bool(cfg.get_value("params", "mipmaps/generate", false))
	check(tex_ok and floor_mat.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		and vram_ok and wood_tex != null and wood_tex.get_width() >= 512,
		"floors, walls, clothes, fur and shells have high-res texture and bump detail, sharp at low angles %s" % str(tex_names))

	# Quality tiers.
	lvl = await load_level(&"kitchen", &"cockroach")
	var vp := get_viewport()
	SaveSystem.set_setting("quality", "high")
	GameManager.apply_quality()
	var env := (lvl.find_child("Environment", true, false) as WorldEnvironment).environment
	var sun := lvl.find_child("Sun", true, false) as DirectionalLight3D
	var high_ok := vp.msaa_3d == Viewport.MSAA_4X and env.glow_enabled and env.fog_enabled \
		and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS and floor_mat.normal_enabled
	SaveSystem.set_setting("quality", "low")
	GameManager.apply_quality()
	var low_ok := not floor_mat.normal_enabled and not sun.shadow_enabled and not env.glow_enabled and vp.scaling_3d_scale < 1.0
	SaveSystem.set_setting("quality", "medium")
	GameManager.apply_quality()
	var mid_ok := floor_mat.normal_enabled and vp.msaa_3d == Viewport.MSAA_2X and vp.scaling_3d_scale == 1.0
	check(high_ok and low_ok and mid_ok,
		"High: 4x anti-aliasing, glow, two shadow cascades; Medium: full resolution, 2x anti-aliasing; Low: no bump maps or shadows")
	await unload(lvl)



# --- Update: new NPC movements, interactions, room changes and obstacles ----------

func _vacuum(lvl: Node) -> RobotVacuum:
	for t in PerceptionSystem.threats:
		if t is RobotVacuum and lvl.is_ancestor_of(t):
			return t
	return null


func _phase16() -> void:
	print("-- Update: new NPC movements, interactions, room changes and obstacles")
	SaveSystem.data = SaveSystem.default_data()
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	var p := lvl.player
	p.invuln = 1000.0
	var pup := first_in_group(Phys.GROUP_PET, lvl) as Pet
	pup.force_present(true)
	pup.stop_playing()
	pup._play_cd = 1000.0
	pup.global_position = Vector3(-50, 0.5, -40)
	pup.reset_physics_interpolation()
	var cook := _quiet_human(lvl, Vector3(45, 0, 43), PI * 0.5)

	# People: gestures. Eyes on the phone, they only notice what's close.
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(15, 0.8, 43)))
	await frames(6)
	var seen_plain := cook.can_see(p)
	cook.set_gesture(&"phone")
	await frames(3)
	var phone := cook.get_node("Torso/ShoulderR/Elbow/Hand/PhoneHold") as Node3D
	var phone_shown := phone.visible
	var seen_phone := cook.can_see(p)
	var poses_ok := true
	for g in Human.GESTURES:
		cook.set_gesture(g)
		poses_ok = poses_ok and not cook._activity_pose().is_empty()
	cook.set_gesture(&"phone")
	cook.alert.force(AlertState.SUSPICIOUS, p.global_position)
	await frames(2)
	check(seen_plain and not seen_phone and poses_ok and cook.gesture == &"" and not phone.visible and phone_shown,
		"(%s %s %s) pausing, people check their phone" % [seen_plain, seen_phone, poses_ok] + " (and miss what isn't close), stretch, scratch their head or check their watch - a noise ends it")
	cook.alert.reset()

	# Their feet knock small things out of the way.
	_place_human(cook, Vector3(45, 0, 43), PI * 0.5)
	var ball := (load("res://scenes/props/ball.tscn") as PackedScene).instantiate() as PhysicsProp
	lvl.add_child(ball)
	ball.global_position = Vector3(36, 1.6, 47)
	await frames(20)
	var ball0 := ball.global_position
	cook.set_physics_process(false)
	cook.right_foot.step_to(Vector3(36, 0, 43.5), PI * 0.5, 0.5, true)
	await frames(60)
	cook.set_physics_process(true)
	check(ball.global_position.distance_to(ball0) > 1.0 and ball._touched_by_player <= 0.0,
		"a person's foot knocks a toy out of the way (and it isn't your trick)")
	ball.queue_free()

	# They stop to pet a calm pet: it sits and wags.
	_place_human(cook, Vector3(20, 0, 50), 0.0)
	pup.global_position = Vector3(20, 0.5, 40)
	pup.velocity = Vector3.ZERO
	pup.reset_physics_interpolation()
	pup.alert.reset()
	await frames(10)
	var petted := cook.try_pet_nearby()
	await frames(30)
	var tail_y: Array[float] = []
	for i in 30:
		await get_tree().process_frame
		tail_y.append((pup.get_node("Visual/Tail") as Node3D).rotation.y)
	tail_y.sort()
	check(petted and cook.activity == &"pet" and pup.petted > 0.0 and pup.idle_act == &"sit" and pup.is_distracted()
		and pup._legs[2].rotation.x < -0.7 and tail_y[tail_y.size() - 1] - tail_y[0] > 0.4,
		"people crouch to pet a calm pet; it sits down, wags and isn't watching")
	await frames(200)
	check(cook.activity == &"" and pup.petted <= 0.0, "after a few seconds they carry on")

	# The fridge: the door swings out into the room, the light comes on, and
	# their head is in the fridge.
	var door := lvl.find_child("FridgeDoor", true, false) as SwingDoor
	var fridge_light := lvl.find_child("FridgeLight", true, false) as LightZone
	_place_human(cook, Vector3(43, 0, -4), PI)
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(43, 0.8, 2)))
	cook.start_activity({"kind": &"fridge", "time": 6.0, "face": Vector3(43, 40, -30)})
	await frames(90)
	var q := PhysicsRayQueryParameters3D.create(Vector3(52, 20, -2.4), Vector3(72, 20, -2.4), Phys.WORLD)
	var hit := lvl.get_world_3d().direct_space_state.intersect_ray(q)
	check(door.angle > 1.5 and fridge_light.is_active() and not hit.is_empty() and hit["collider"] == door and not cook.can_see(p)
		and (door.get_node("Panel") as Node3D).is_visible_in_tree(),
		"the cook opens the fridge: the door swings out as a solid obstacle, the light spills out, and they can't see past it")
	cook.end_activity()
	await frames(100)
	hit = lvl.get_world_3d().direct_space_state.intersect_ray(q)
	check(door.angle < 0.1 and hit.is_empty() and not fridge_light.is_active(), "then it swings shut and the light goes off")

	# The broom: it pushes crumbs along, shoves you and gives you away.
	_place_human(cook, Vector3(40, 0, 58), PI)
	cook.alert.reset()
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-40, 0.8, 60)))
	cook.start_activity({"kind": &"sweep", "time": 9.0, "face": Vector3(40, 0, 80)})
	await frames(4)
	var broom := cook._sweeper
	var crumb := lvl.spawn_crumb(broom.head_position() + Vector3.UP * 0.6)
	var c0 := crumb.global_position if crumb else Vector3.ZERO
	await frames(20)
	var swept_crumb := crumb != null and crumb.global_position.distance_to(c0) > 0.5
	p.teleport_to(Transform3D(Basis.IDENTITY, broom.head_position() + Vector3.UP * 0.8))
	var b0 := p.global_position
	await frames(30)
	var shoved := p.global_position.distance_to(b0)
	var noticed := cook.alert.state >= AlertState.SUSPICIOUS
	check(swept_crumb and shoved > 1.5 and noticed,
		"the cook sweeps: crumbs get swept along (%s, %s); the broom shoves you (%.1f) and they notice (%s)" % [swept_crumb, crumb, shoved, noticed])
	await frames(2)
	check(cook.activity == &"" and not is_instance_valid(broom), "noticing you, they stop sweeping and put the broom down")
	cook.alert.reset()
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-40, 0.8, 60)))

	# The puppy: habits (kept awake: after lunch is nap time).
	cook.force_present(false)
	pup._woken = 1000.0
	pup.global_position = Vector3(20, 0.5, 40)
	pup.reset_physics_interpolation()
	pup.alert.reset()
	var vis := pup.get_node("Visual") as Node3D
	var habit_ok := {}
	for act in [&"sit", &"stretch", &"lie", &"scratch"]:
		pup.start_idle_act(act)
		await frames(40)
		match act:
			&"sit":
				habit_ok[act] = pup._legs[2].rotation.x < -0.8 and vis.rotation.x < -0.2
			&"stretch":
				habit_ok[act] = vis.rotation.x > 0.15 and pup._legs[0].rotation.x < -0.6
			&"lie":
				habit_ok[act] = vis.position.y < -1.0
			&"scratch":
				var a := pup._legs[2].rotation.x
				await frames(3)
				habit_ok[act] = absf(pup._legs[2].rotation.x - a) > 0.02 and pup._legs[2].rotation.x < -1.0
		pup.idle_act = &""
		pup._idle = 0.0
	check(habit_ok.values().all(func(v: bool) -> bool: return v), "pets sit, stretch, lie down and scratch an ear %s" % str(habit_ok))

	# A drink at the water bowl.
	pup.global_position = Vector3(95, 0.5, 48)
	pup.reset_physics_interpolation()
	pup._bowl_cd = 0.0
	pup._idle = 0.0
	pup._pick_habit()
	var drank := false
	var head_down := false
	for i in 600:
		await get_tree().physics_frame
		if pup.idle_act == &"drink":
			drank = true
			head_down = head_down or (pup.get_node("Visual/Head") as Node3D).rotation.x < -0.6
			if head_down:
				break
	check(drank and head_down and _flat(pup.global_position, Vector3(102, 0, 64)) < 12.0,
		"thirsty pets trot over to the water bowl and lap from it (%s %s %.1f, %s %s)" % [drank, head_down, _flat(pup.global_position, Vector3(102, 0, 64)), pup._drink_at, pup.idle_act])
	pup._spill_puddle()
	await frames(2)
	var spills := 0
	for n in get_tree().get_nodes_in_group(&"water"):
		if String((n as Node).name).begins_with("Spill"):
			spills += 1
	check(spills > 0, "a sloppy drinker leaves a puddle by the bowl (it washes your scent away)")
	pup.idle_act = &""
	pup._idle = 0.0

	# Everyone keeps clear of the robot vacuum.
	var vac := _vacuum(lvl)
	vac.force_present(true)
	pup.global_position = Vector3(20, 0.5, 40)
	pup.reset_physics_interpolation()
	pup.alert.reset()
	vac.global_position = Vector3(28, 0.5, 40)
	vac.reset_physics_interpolation()
	await frames(30)
	var scared := pup.scared > 0.0
	await frames(40)
	check(scared and _flat(pup.global_position, vac.global_position) > 10.0, "pets run from the robot vacuum")

	# The vacuum eats crumbs (they turn up again later) and shoves toys.
	vac.global_position = Vector3(40, 0.5, 66)
	vac._heading = PI * 0.5
	vac.reset_physics_interpolation()
	var crumb2 := lvl.spawn_crumb(Vector3(46, 0.6, 66))
	var toy := (load("res://scenes/props/ball.tscn") as PackedScene).instantiate() as PhysicsProp
	lvl.add_child(toy)
	toy.global_position = Vector3(48, 1.6, 66.5)
	await frames(10)
	var t0 := toy.global_position
	await frames(60)
	var eaten := crumb2 != null and crumb2.taken and crumb2.is_sucked_up() and not crumb2.visible
	check(eaten and toy.global_position.distance_to(t0) > 1.0 and vac.crumbs_eaten > 0,
		"the robot vacuum hoovers up crumbs in its path and bumps toys aside")
	if crumb2:
		crumb2._back_in = 0.05
		await frames(5)
		check(not crumb2.taken and crumb2.visible, "eaten crumbs turn up again a little later")
	toy.queue_free()
	vac.force_present(false)
	await unload(lvl)

	# Living room: the reading lamp and the curtains.
	lvl = await load_level(&"living_room", &"cockroach")
	HouseClock.set_hour(9.0)
	var reader := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	reader.force_present(true)
	reader.end_activity()
	reader.activities = {}
	var lamp := lvl.find_child("ReadingLamp", true, false) as LightZone
	var lamp_before := lamp.is_active()
	_place_human(reader, Vector3(62, 0, -23), 0.0)
	reader.start_activity({"kind": &"read", "time": 6.0, "face": Vector3(62, 0, 10)})
	await frames(5)
	var lamp_on := lamp.is_active()
	reader.end_activity()
	await frames(5)
	check(not lamp_before and lamp_on and not lamp.is_active(), "the reader switches the lamp on to read and off again")
	var curtains := lvl.find_child("Curtains", true, false) as Curtains
	var beam := lvl.find_child("Sunbeam", true, false) as LightZone
	var was_closed := curtains.closed
	_place_human(reader, Vector3(95, 0, 20), PI * 0.5)
	reader.start_activity({"kind": &"curtains", "time": 3.0, "face": Vector3(114, 40, 10)})
	await frames(90)
	var panel_vis := (curtains.get_node("Panel").get_child(0) as Node3D).is_visible_in_tree()
	check(curtains.closed != was_closed and beam.is_active() == (not curtains.closed) and panel_vis,
		"the reader draws the curtains (the sunbeam goes) or opens them (it's back)")
	reader.end_activity()
	await unload(lvl)

	# Backyard: the rake, shaking off water, cats hating water, digging.
	lvl = await load_level(&"backyard", &"cockroach")
	HouseClock.set_hour(13.5)
	p = lvl.player
	p.invuln = 1000.0
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-60, 0.8, -60)))
	var gardener: Human = null
	var dog: Pet = null
	var cat: Pet = null
	for n in lvl.find_children("*", "", true, false):
		if n is Human and String(n.name).begins_with("Gardener"):
			gardener = n
		elif n is Pet and (n as Pet).barks and dog == null:
			dog = n
		elif n is Pet and not (n as Pet).barks and cat == null:
			cat = n
	gardener.force_present(true)
	gardener.end_activity()
	gardener.activities = {}
	_place_human(gardener, Vector3(32, 0, 52), 0.0)
	gardener.start_activity({"kind": &"rake", "time": 9.0, "face": Vector3(20, 0, 44)})
	await frames(5)
	check(gardener._sweeper != null and gardener._sweeper.kind == &"rake", "the gardener rakes the leaves (the rake sweeps like the broom)")
	gardener.end_activity()
	gardener.force_present(false)
	for pet in [dog, cat]:
		pet.force_present(true)
		pet.stop_playing()
		pet._play_cd = 1000.0
		pet.alert.reset()
	cat.global_position = Vector3(-30, 0.5, -5)
	cat.reset_physics_interpolation()
	dog.global_position = Vector3(10, 0.5, 5)
	dog.reset_physics_interpolation()
	await frames(30)
	var cat_hates := cat.scared > 0.0
	var dog_wet := dog.wet > 0.0
	dog.global_position = Vector3(10, 0.5, 30)
	dog.reset_physics_interpolation()
	var shook := false
	for i in 120:
		await get_tree().physics_frame
		shook = shook or dog.idle_act == &"shake"
	check(dog_wet and shook and cat_hates, "a wet dog shakes itself off; a cat runs out of the water")
	cat.force_present(false)
	dog._woken = 1000.0
	dog.global_position = Vector3(0, 0.5, 45)
	dog.reset_physics_interpolation()
	dog.idle_act = &""
	dog._idle = 0.0
	dog.velocity = Vector3.ZERO
	await frames(10)
	var can_dig := dog._can_dig_here()
	dog.start_idle_act(&"dig")
	var holes: Array[Node] = []
	for i in 300:
		await get_tree().physics_frame
		holes = get_tree().get_nodes_in_group(&"dug_hole")
		if not holes.is_empty():
			break
	var hole_ok := false
	if not holes.is_empty():
		var hole := holes[0] as DugHole
		dog.global_position = Vector3(-40, 0.5, -10)
		dog.reset_physics_interpolation()
		p.teleport_to(Transform3D(Basis.IDENTITY, hole.global_position + Vector3.UP * 0.6))
		await frames(10)
		hole_ok = p.is_hidden_safe() and hole.get_node_or_null("Mound") is StaticBody3D
	check(can_dig and hole_ok, "the dog digs a hole in the lawn: a dirt mound in the way, and a dark hollow any bug can hide in (%s %d %s)" % [can_dig, holes.size(), hole_ok])
	await unload(lvl)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()



# --- Update: bug's-eye view, Shift to run, power-ups, people finish the chase -------

func _is_tucked_away(lvl: Level, pos: Vector3) -> bool:
	var space := lvl.get_world_3d().direct_space_state
	var at := pos + Vector3.UP * 0.6
	# Up high (only climbers and flyers get there).
	if pos.y > 15.0:
		return true
	# Something overhead: under furniture, inside a shelter, in a cavity.
	var up := space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at + Vector3.UP * 15.0, Phys.WORLD))
	if not up.is_empty():
		return true
	# Next to cover (a rock, the woodpile, tall grass, a flour sack...).
	for m in get_tree().get_nodes_in_group(Phys.GROUP_COVER):
		if lvl.is_ancestor_of(m) and Vector2((m as Node3D).global_position.x - pos.x, (m as Node3D).global_position.z - pos.z).length() < 10.0:
			return true
	# In a corner: walls close by in two directions.
	var walls := 0
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at + d * 10.0, Phys.WORLD)).is_empty():
			walls += 1
	return walls >= 2


func _phase17() -> void:
	print("-- Update: bug's-eye view, Shift to run, power-ups, people finish the chase")
	SaveSystem.data = SaveSystem.default_data()

	# People don't vanish mid-chase when their routine ends: they finish
	# with you, calm down and walk out through the door.
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(7.3)
	await frames(5)
	var p := lvl.player
	p.invuln = 1000.0
	var cook := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	var came_in := cook.present and cook._body_pos.distance_to(cook.exit_point) < 15.0
	cook.activities = {}
	_place_human(cook, Vector3(-40, 0, 40), 0.0)
	cook.alert.force(AlertState.ALERT, p.global_position)
	HouseClock.set_hour(7.8)
	await frames(30)
	var stayed := cook.present and cook.visible and cook.leave_pending
	cook.alert.reset()
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.6, -22.5)))
	InputRouter.set_touch_action(&"secondary", true)
	var walked_out := false
	for i in 900:
		await get_tree().physics_frame
		walked_out = walked_out or cook.walking_out
		if not cook.present:
			break
	InputRouter.set_touch_action(&"secondary", false)
	check(came_in, "people come on shift through the door")
	check(stayed, "a person who has spotted you doesn't vanish when their routine ends")
	check(walked_out and not cook.present, "once calm they walk out through the door")
	await unload(lvl)

	# Shift: tap to dash, hold to run - for every bug.
	lvl = await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	p = lvl.player
	p.invuln = 1000.0
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(20, 0.8, 56)))
	face(lvl, 0.0)
	await frames(10)
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(30)
	var walk := Vector2(p.velocity.x, p.velocity.z).length()
	InputRouter.set_touch_action(&"dodge", true)
	await frames(2)
	var dashing := p._dodge_time > 0.0
	await frames(30)
	var run := Vector2(p.velocity.x, p.velocity.z).length()
	var running := p.is_running() and p.motion == BugBase.Motion.SPRINT
	InputRouter.set_touch_action(&"dodge", false)
	InputRouter.set_touch_move(Vector2.ZERO)
	var labels_ok := true
	for id in GameManager.BUG_IDS:
		var st := GameManager.get_bug_stats(id)
		var b := (load(st.scene_path) as PackedScene).instantiate() as BugBase
		b.stats = st
		var lab := String(b.get_action_labels().get("dodge", ""))
		labels_ok = labels_ok and (lab == "Run" or lab.begins_with("Burst"))
		b.free()
	check(dashing and running and run > walk * 1.3 and p.run_speed() >= p.stats.move_speed * 1.5,
		"Shift dashes on a tap and runs while held (walk %.1f, run %.1f units/s)" % [walk, run])
	check(labels_ok, "every bug's dash button is labelled Run (the fly's: Burst/Fast in the air)")
	await unload(lvl)

	# Power-ups: ten in each room, two of each kind, tucked away.
	var rooms_ok := true
	var detail: PackedStringArray = []
	for level in GameManager.LEVEL_IDS:
		lvl = await load_level(level, &"cockroach")
		var kinds := {}
		var tucked := 0
		var far := 0
		var n := 0
		for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
			var pi := it as PickupItem
			if pi and lvl.is_ancestor_of(pi) and pi.is_power():
				n += 1
				kinds[pi.def.id] = int(kinds.get(pi.def.id, 0)) + 1
				if _is_tucked_away(lvl, pi.global_position):
					tucked += 1
				if pi.global_position.distance_to(lvl.player.global_position) > 20.0:
					far += 1
		var ok := n >= 10 and kinds.size() == 5 and kinds.values().all(func(c: int) -> bool: return c >= 2) and tucked == n and far == n
		rooms_ok = rooms_ok and ok
		detail.append("%s %d/%d tucked" % [level, tucked, n])
		await unload(lvl)
	check(rooms_ok, "every room hides at least ten power-ups, two or more of each kind, in hidden corners and high places %s" % str(detail))

	# Picking one up; what each does.
	lvl = await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	p = lvl.player
	p.invuln = 1000.0
	var hud := lvl.find_child("HUD", true, false)
	var counter := hud.find_child("PowerUps", true, false) as Label
	var cup_power: PickupItem = null
	for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		var pi := it as PickupItem
		if pi and lvl.is_ancestor_of(pi) and pi.is_power() and pi.def.id == &"power_turbo":
			cup_power = pi
			break
	var power_total := 0
	for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		if it is PickupItem and lvl.is_ancestor_of(it) and (it as PickupItem).is_power():
			power_total += 1
	var before_text := counter.text
	p.teleport_to(Transform3D(Basis.IDENTITY, cup_power.global_position + Vector3.UP * 0.6))
	await frames(10)
	var score: Dictionary = lvl.run.score(GameManager.scoring, 999.0)
	var line_ok := false
	for l: Array in score["lines"]:
		line_ok = line_ok or String(l[0]).begins_with("Power-ups x1")
	check(cup_power.taken and p.has_effect(&"turbo") and p.speed_scale() >= 1.59 and lvl.run.powerups == 1
		and before_text == "POWER-UPS 0 / %d" % power_total and counter.text == "POWER-UPS 1 / %d" % power_total and line_ok,
		"grabbing a power-up (Turbo): 60%% faster, counted on screen (%s) and in the score" % counter.text)
	p.effects.clear()
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 30)))
	await frames(15)
	p.add_effect(&"spring", 10.0, 1.8)
	InputRouter.set_touch_action(&"jump", true)
	await frames(2)
	InputRouter.set_touch_action(&"jump", false)
	var vy := p.velocity.y
	await frames(60)
	check(vy > 7.0 * 1.7, "Spring Legs: jumps go much higher (%.1f)" % vy)
	p.add_effect(&"double", 10.0, 2.0)
	var got0 := lvl.crumbs_got
	var extra := lvl.spawn_crumb(Vector3(30, 0.6, 60))
	if extra:
		extra.collect()
	await frames(2)
	check(lvl.crumbs_got - got0 == 2, "Double Crumbs: a crumb counts twice (%d)" % (lvl.crumbs_got - got0))
	p.add_effect(&"radar", 10.0, 90.0)
	check(p.has_effect(&"radar") and hud.get("_markers") != null, "Bug Radar: crumbs and power-ups show on screen")
	p.add_effect(&"shrink", 10.0, 0.55)
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.6, -22.5)))
	await frames(80)
	check(p.visual.scale.x < 0.6 and p.is_hidden_safe() and not p.is_squeezing,
		"Shrink: tiny (%.2f) and hidden in a gap without squeezing" % p.visual.scale.x)
	p.effects.clear()
	await unload(lvl)

	# Bug's-eye view: through each bug's own eyes.
	var eye_ok: PackedStringArray = []
	var bad: PackedStringArray = []
	for id in GameManager.BUG_IDS:
		SaveSystem.unlock_bug(id)
		SaveSystem.set_setting("first_person", true)
		lvl = await load_level(&"kitchen", id)
		HouseClock.set_hour(13.5)
		p = lvl.player
		p.invuln = 1000.0
		p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 30)))
		face(lvl, PI * 0.5)
		var cam := lvl.camera as FollowCamera
		cam.pitch = 0.0
		await frames(12)
		await get_tree().process_frame
		var eye := p.visual.get_node("EyePoint") as Node3D
		var at_eyes := cam.camera.global_position.distance_to(eye.global_position) < 0.15
		var c3 := cam.camera
		# Its own parts in view: antennae looking level, mouthparts and front
		# legs looking down.
		var parts_seen := false
		for look in [0.0, -0.6]:
			cam.pitch = look
			await get_tree().process_frame
			await get_tree().process_frame
			var pts: Array[Vector3] = []
			for n in ["AntennaL/Tip", "AntennaR/Tip"]:
				var part := p.visual.get_node_or_null(n) as Node3D
				if part:
					pts.append(part.global_transform * Vector3(0, 0, -0.1))
			for n in ["PalpL", "PalpR"]:
				var palp := p.visual.get_node_or_null(n) as Node3D
				if palp:
					pts.append(palp.global_transform * Vector3(0, -0.02, -0.2))
			for n in ["LegL1/Knee", "LegR1/Knee"]:
				var knee := p.visual.get_node_or_null(n) as Node3D
				if knee:
					pts.append(knee.global_transform * Vector3(0.3 * signf(knee.position.x), 0, 0))
			for pt in pts:
				if c3.is_position_in_frustum(pt) and not c3.is_position_behind(pt):
					parts_seen = true
		# The fly and the firefly look out through their compound eyes (the
		# facet overlay, checked below) rather than past antennae.
		if p is Fly:
			parts_seen = true
		cam.pitch = 0.0
		await get_tree().process_frame
		var fov_ok := absf(c3.fov - p.stats.fp_fov) < 0.5
		var overlay := cam.get_node_or_null("EyeOverlay") as CanvasLayer
		var tex_path := ((overlay.get_node("Tex") as TextureRect).texture.resource_path) if overlay else ""
		var overlay_ok := overlay != null and overlay.visible and tex_path.ends_with("compound_eye.png" if p is Fly else "vignette.png")
		if at_eyes and parts_seen and fov_ok and overlay_ok:
			eye_ok.append(String(id))
		else:
			bad.append("%s(%s %s %s %s)" % [id, at_eyes, parts_seen, fov_ok, overlay_ok])
		await unload(lvl)
	check(bad.is_empty(), "through every bug's eyes: the camera sits at its sculpted eyes, its own antennae or mouthparts in view, its own field of view and eye overlay %s" % str(bad))

	SaveSystem.set_setting("first_person", true)
	lvl = await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	p = lvl.player
	p.invuln = 1000.0
	var fc := lvl.camera as FollowCamera
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(40, 0.8, 30)))
	face(lvl, PI * 0.5)
	fc.pitch = -0.4
	await frames(10)
	var legs_seen := false
	var heights: Array[float] = []
	InputRouter.set_touch_move(Vector2(0, 1))
	for i in 60:
		await get_tree().process_frame
		heights.append(fc.camera.global_position.y - p.get_global_transform_interpolated().origin.y)
		for leg_name in ["LegL1", "LegR1"]:
			var foot := p.visual.get_node("%s/Knee" % leg_name) as Node3D
			if fc.camera.is_position_in_frustum(foot.global_position + foot.global_basis.x * 0.3):
				legs_seen = true
	InputRouter.set_touch_move(Vector2.ZERO)
	heights.sort()
	var bob := heights[heights.size() - 1] - heights[0]
	# Crab sideways: the view doesn't swing round, the body keeps facing it.
	var yaw0 := fc.yaw
	InputRouter.set_touch_move(Vector2(1, 0))
	await frames(40)
	InputRouter.set_touch_move(Vector2.ZERO)
	var vis_yaw := p.visual.rotation.y
	check(legs_seen and bob > 0.005, "walking, you see your front legs step into view and the view bobs with the gait (%.3f)" % bob)
	check(absf(fc.yaw - yaw0) < 0.001 and absf(wrapf(vis_yaw - fc.yaw, -PI, PI)) < 0.1,
		"stepping sideways the view stays put and the body keeps facing where you look")
	var on := GameManager.toggle_first_person()
	await frames(10)
	var tp_dist := fc.camera.global_position.distance_to(p.global_position)
	check(not on and not fc.first_person and tp_dist > 3.0 and not (fc.get_node("EyeOverlay") as CanvasLayer).visible
		and not bool(SaveSystem.get_setting("first_person", true)),
		"V / EYES switches back behind the bug (and the choice is remembered)")
	await unload(lvl)

	# The spider's eyes follow the wall it's walking on.
	SaveSystem.set_setting("first_person", true)
	lvl = await load_level(&"kitchen", &"spider")
	var sp := lvl.player as Spider
	sp.invuln = 1000.0
	sp.teleport_to(Transform3D(Basis(Vector3.FORWARD.cross(Vector3.RIGHT), Vector3.RIGHT, Vector3.FORWARD).orthonormalized(), Vector3(-59.6, 20, 0)))
	await frames(30)
	var spc := lvl.camera as FollowCamera
	check(sp.attached and spc.global_basis.y.dot(sp.surface_normal) > 0.85,
		"on a wall, the spider's view is the wall's: up is away from the wall (%.2f)" % spc.global_basis.y.dot(sp.surface_normal))
	SaveSystem.set_setting("first_person", false)
	await unload(lvl)


func _phase18() -> void:
	print("-- Update: every bug climbs, jump-up routes, rare collectibles and the showcase")
	SaveSystem.data = SaveSystem.default_data()

	# Every bug climbs: push into the cupboards and you're up them, round the
	# counter's lip and onto the top.
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	var p := lvl.player
	p.invuln = 1000.0
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.4, -16)))
	face(lvl, 0.0)
	await frames(5)
	InputRouter.set_touch_move(Vector2(0, 1))
	var climbed := false
	var max_y := 0.0
	var on_top := false
	for i in 900:
		await get_tree().physics_frame
		climbed = climbed or p.climbing
		max_y = maxf(max_y, p.global_position.y)
		if not p.climbing and p.global_position.y > 37.5 and p.is_on_floor():
			on_top = true
			break
	InputRouter.set_touch_move(Vector2.ZERO)
	print("   roach climb: climbed=%s max_y=%.1f on_top=%s pos=%s" % [climbed, max_y, on_top, p.global_position])
	check(climbed, "pushing into the cupboards starts a climb")
	check(on_top, "the cockroach climbs the cupboards, round the counter's lip and onto the top (%.1f)" % max_y)

	# Down again: pull back on a wall and you climb down, then walk off.
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.4, -16)))
	face(lvl, 0.0)
	await frames(3)
	InputRouter.set_touch_move(Vector2(0, 1))
	for i in 200:
		await get_tree().physics_frame
		if p.climbing and p.global_position.y > 12.0:
			break
	InputRouter.set_touch_move(Vector2(0, -1))
	var down := false
	for i in 600:
		await get_tree().physics_frame
		if not p.climbing and p.global_position.y < 1.0:
			down = true
			break
	InputRouter.set_touch_move(Vector2.ZERO)
	await frames(3)
	check(down and p.motion_mode == CharacterBody3D.MOTION_MODE_GROUNDED and p.visual.global_basis.y.dot(Vector3.UP) > 0.9,
		"pull back to climb down; at the floor you're walking again, upright")

	# Leap off: Jump on a wall pushes you off it and you fall back to the floor.
	InputRouter.set_touch_move(Vector2(0, 1))
	for i in 200:
		await get_tree().physics_frame
		if p.climbing and p.global_position.y > 8.0:
			break
	InputRouter.set_touch_move(Vector2.ZERO)
	var was_up := p.climbing
	InputRouter.set_touch_action(&"jump", true)
	await frames(2)
	InputRouter.set_touch_action(&"jump", false)
	var off := not p.climbing
	var landed := false
	for i in 240:
		await get_tree().physics_frame
		if p.is_on_floor():
			landed = true
			break
	print("   leap: was_up=%s off=%s landed=%s pos=%s" % [was_up, off, landed, p.global_position])
	check(was_up and off and landed and p.global_position.z > -20.0, "Jump leaps off the wall, away from it, and you land")

	# Loose things you can push (a grape) get pushed, not climbed.
	var grape: PhysicsProp = null
	for pr in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		if pr is PhysicsProp and lvl.is_ancestor_of(pr) and (pr as Node3D).global_position.distance_to(Vector3(0, 0.9, -5)) < 2.0:
			grape = pr
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.4, -1.5)))
	face(lvl, 0.0)
	await frames(3)
	InputRouter.set_touch_move(Vector2(0, 1))
	var climbed_grape := false
	for i in 50:
		await get_tree().physics_frame
		climbed_grape = climbed_grape or p.climbing
	InputRouter.set_touch_move(Vector2.ZERO)
	check(grape != null and not climbed_grape, "a grape (a loose prop) gets pushed, not climbed")

	# Through the bug's eyes on a wall: the view is the wall's.
	SaveSystem.set_setting("first_person", true)
	lvl.camera.set_first_person(true)
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.4, -16)))
	face(lvl, 0.0)
	await frames(3)
	InputRouter.set_touch_move(Vector2(0, 1))
	for i in 240:
		await get_tree().physics_frame
		if p.climbing and p.global_position.y > 10.0:
			break
	InputRouter.set_touch_move(Vector2.ZERO)
	await frames(20)
	var fpc := lvl.camera.camera
	check(p.climbing and fpc.global_basis.y.dot(p.surface_normal) > 0.85,
		"climbing through the bug's eyes: up is away from the wall (%.2f)" % fpc.global_basis.y.dot(p.surface_normal))
	lvl.camera.set_first_person(false)
	SaveSystem.set_setting("first_person", false)

	# A table leg: up the leg, round the table top's edge and onto it.
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-32.5, 0.4, 2)))
	face(lvl, -PI * 0.5)
	await frames(3)
	InputRouter.set_touch_move(Vector2(0, 1))
	var on_table := false
	for i in 900:
		await get_tree().physics_frame
		if not p.climbing and p.global_position.y > 31.0 and p.is_on_floor():
			on_table = true
			break
	InputRouter.set_touch_move(Vector2.ZERO)
	print("   table: pos=%s climbing=%s" % [p.global_position, p.climbing])
	check(on_table, "up a table leg, round the table top's edge and onto the table")
	await unload(lvl)

	# Every bug (bar the spider, which crawls its own way) climbs.
	for bug: StringName in [&"ant", &"cricket", &"ladybug", &"stink_bug", &"fly", &"firefly"]:
		lvl = await load_level(&"kitchen", bug)
		HouseClock.set_hour(13.5)
		p = lvl.player
		p.invuln = 1000.0
		p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.4, -16)))
		face(lvl, 0.0)
		await frames(5)
		InputRouter.set_touch_move(Vector2(0, 1))
		var top := false
		for i in 1500:
			await get_tree().physics_frame
			if not p.climbing and p.global_position.y > 37.5 and p.is_on_floor():
				top = true
				break
		InputRouter.set_touch_move(Vector2.ZERO)
		check(top, "the %s climbs the cupboards onto the counter (%s)" % [bug, p.global_position])
		await unload(lvl)

	# Bounce pads: every one flings a bug up onto its target.
	var pads_ok := true
	var pad_detail: PackedStringArray = []
	for level in GameManager.LEVEL_IDS:
		lvl = await load_level(level, &"cockroach")
		HouseClock.set_hour(13.5)
		p = lvl.player
		p.invuln = 1000.0
		var pads: Array[BouncePad] = []
		for n in get_tree().get_nodes_in_group(&"bounce_pad"):
			if lvl.is_ancestor_of(n):
				pads.append(n as BouncePad)
		for pad in pads:
			# Drop onto the pad from just above it.
			p.teleport_to(Transform3D(Basis.IDENTITY, (pad.get_node("Shape") as Node3D).global_position + Vector3.UP * 0.3))
			var pad_landed := false
			var launched := false
			for i in 400:
				await get_tree().physics_frame
				launched = launched or p.global_position.y > pad.global_position.y + 4.0
				if launched and p.is_on_floor() and p.velocity.y <= 0.1:
					pad_landed = true
					break
			var miss := Vector2(p.global_position.x - pad.target.x, p.global_position.z - pad.target.z).length()
			var ok := pad_landed and miss < 2.0 and absf(p.global_position.y - pad.target.y) < 1.0
			pads_ok = pads_ok and ok
			pad_detail.append("%s %s miss %.1f y %.1f/%.1f" % [level, pad.get_parent().name, miss, p.global_position.y, pad.target.y])
		pads_ok = pads_ok and pads.size() == 3
		await unload(lvl)
	print("   pads: ", pad_detail)
	check(pads_ok, "three bounce pads per room, each flinging you onto its high spot %s" % str(pad_detail))

	# The junk towers: scramble up step by step (climbing each rise, hopping
	# each gap) to the summit, picking up what's on the way.
	var towers_ok := true
	var tower_detail: PackedStringArray = []
	for level in GameManager.LEVEL_IDS:
		lvl = await load_level(level, &"cockroach")
		HouseClock.set_hour(13.5)
		p = lvl.player
		p.invuln = 1000.0
		var prefix: String = {&"kitchen": "GroceryTowerStep", &"living_room": "BookTowerStep", &"backyard": "PotTowerStep"}[level]
		var steps: Array[Vector3] = []
		for b in lvl.find_children(prefix + "*", "StaticBody3D", true, false):
			var cs := (b as Node).get_node("Shape") as CollisionShape3D
			var hh: float = (cs.shape as BoxShape3D).size.y * 0.5 if cs.shape is BoxShape3D else (cs.shape as CylinderShape3D).height * 0.5
			steps.append((b as Node3D).global_position + Vector3.UP * hh)
		steps.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
		var first := steps[0]
		var out := Vector3(first.x - steps[-1].x, 0, first.z - steps[-1].z).normalized()
		p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(first.x, 0.4, first.z) + out * 7.0))
		await frames(3)
		var k := 0
		var top_y := 0.0
		for i in 3600:
			var tgt := steps[k]
			var d := Vector3(tgt.x - p.global_position.x, 0, tgt.z - p.global_position.z)
			if p.global_position.y >= tgt.y and d.length() < 1.6:
				k += 1
				if k >= steps.size():
					break
				continue
			if d.length() > 0.05:
				face(lvl, atan2(-d.x, -d.z))
			InputRouter.set_touch_move(Vector2(0, 1))
			await get_tree().physics_frame
			top_y = maxf(top_y, p.global_position.y)
		InputRouter.set_touch_move(Vector2.ZERO)
		var ok := k >= steps.size() and steps.size() == 8
		towers_ok = towers_ok and ok
		tower_detail.append("%s %d/%d steps, top %.1f of %.1f" % [level, k, steps.size(), top_y, steps[-1].y])
		await unload(lvl)
	print("   towers: ", tower_detail)
	check(towers_ok, "each room's junk tower can be scrambled up, step by step, to the summit %s" % str(tower_detail))

	# Treasures: six per room (two common, two rare, an epic and a legendary),
	# the rare ones glowing and the great ones sending up a beam.
	var tr_ok := true
	var tr_detail: PackedStringArray = []
	for level in GameManager.LEVEL_IDS:
		lvl = await load_level(level, &"cockroach")
		var counts := [0, 0, 0, 0]
		var beams := 0
		var gems := 0
		for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
			var pi := it as PickupItem
			if pi == null or not lvl.is_ancestor_of(pi):
				continue
			if pi.is_treasure():
				counts[pi.def.rarity] += 1
				if pi.get_node_or_null("Beam") != null:
					beams += 1
			elif pi.is_gem():
				gems += 1
		var ok := counts == [2, 2, 1, 1] and beams == 2 and gems >= 4
		tr_ok = tr_ok and ok
		tr_detail.append("%s %s beams %d gems %d" % [level, str(counts), beams, gems])
		await unload(lvl)
	check(tr_ok, "every room has six treasures (2 common, 2 rare, 1 epic, 1 legendary) and gems all around %s" % str(tr_detail))

	# Picking one up: it goes on the showcase, the banner says so, and the
	# second time it's already there.
	SaveSystem.data = SaveSystem.default_data()
	lvl = await load_level(&"kitchen", &"cockroach")
	p = lvl.player
	p.invuln = 1000.0
	var ring: PickupItem = null
	for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		if it is PickupItem and lvl.is_ancestor_of(it) and (it as PickupItem).def.id == &"treasure_ring":
			ring = it
	var was_found := Collection.is_found(&"treasure_ring")
	p.teleport_to(Transform3D(Basis.IDENTITY, ring.global_position + Vector3.UP * 0.4))
	await frames(10)
	var hud := lvl.find_child("HUD", true, false)
	var banner := ""
	if hud and hud.get("_pickup_title"):
		banner = (hud.get("_pickup_title") as Label).text
	check(ring != null and ring.taken and not was_found and Collection.is_found(&"treasure_ring") \
		and lvl.run.new_treasures.has(&"treasure_ring") and lvl.run.best_rarity == 3,
		"the Lost Wedding Ring goes on your showcase when you pick it up")
	check(banner.contains("NEW!") and banner.contains("LEGENDARY"), "the banner shouts NEW! LEGENDARY (%s)" % banner)
	var sc: Dictionary = lvl.run.score(GameManager.scoring, 240.0)
	check((sc["lines"] as Array).any(func(l: Array) -> bool: return String(l[0]).begins_with("Treasures") and int(l[1]) == 1000)
		and lvl.run.badges(240.0)["treasure_hunter"], "a legendary find scores 1000 and earns Treasure Hunter")
	await unload(lvl)
	lvl = await load_level(&"kitchen", &"cockroach")
	p = lvl.player
	p.invuln = 1000.0
	for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		if it is PickupItem and lvl.is_ancestor_of(it) and (it as PickupItem).def.id == &"treasure_ring":
			ring = it
	p.teleport_to(Transform3D(Basis.IDENTITY, ring.global_position + Vector3.UP * 0.4))
	await frames(10)
	check(ring.taken and lvl.run.new_treasures.is_empty() and int(SaveSystem.treasures_found()["treasure_ring"]) == 2,
		"found again: points, but it's already on the showcase (found x2)")
	await unload(lvl)

	# The showcase screen: every piece, room by room; found ones named.
	var show := (load("res://scenes/ui/showcase.tscn") as PackedScene).instantiate()
	add_child(show)
	await frames(2)
	var cards := show.find_children("Card_*", "", true, false)
	var ring_card := show.find_child("Card_treasure_ring", true, false)
	var ring_named := false
	for l in ring_card.find_children("*", "Label", true, false):
		ring_named = ring_named or (l as Label).text == "The Lost Wedding Ring"
	var pearl_card := show.find_child("Card_treasure_pearl", true, false)
	var pearl_hidden := false
	for l in pearl_card.find_children("*", "Label", true, false):
		pearl_hidden = pearl_hidden or (l as Label).text == "???"
	check(cards.size() == 24 and ring_named and pearl_hidden and Collection.all_ids().size() == 24,
		"the showcase lists all 24 pieces: found ones by name, the rest as ??? (%d)" % cards.size())
	show.queue_free()
	await frames(2)

	# The home screen: a Showcase button and the trophy shelf with your finds.
	SaveSystem.record_treasure(&"treasure_golden_acorn")
	SaveSystem.record_gem(&"gem_ruby")
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
	add_child(menu)
	await frames(2)
	var has_button := false
	for b in menu.find_children("*", "Button", true, false):
		has_button = has_button or (b as Button).text == "Showcase"
	var shelf: Array = menu.get("shelf_items")
	check(has_button and shelf.size() == 3 and Collection.best_found(7)[0] in [&"treasure_ring", &"treasure_golden_acorn"],
		"the home screen has a Showcase button and a trophy shelf with your finds, rarest first (%d)" % shelf.size())
	menu.queue_free()
	await frames(2)


func _phase19() -> void:
	print("-- Update: mini maps behind every room, credits, add-ons and the revolver")
	SaveSystem.data = SaveSystem.default_data()

	# Ten mini maps per room: inside the walls, under the sink, the basement,
	# the attic, and a hidden crawl space.
	var themes := {}
	var count := 0
	for room in GameManager.LEVEL_IDS:
		var ids := MiniMaps.ids_for(room)
		count += ids.size()
		for mid in ids:
			var mc := GameManager.get_level(mid)
			themes[mc.theme] = true
			if mc == null or not ResourceLoader.exists(mc.scene_path):
				count = -999
	check(count == 30 and themes.has("walls") and themes.has("sink") and themes.has("basement") and themes.has("attic") and themes.has("crawl"),
		"30 mini maps (10 per room): inside the walls, under the sink, basement, attic and crawl spaces (%d)" % count)
	check(GameManager.is_level_unlocked(&"kitchen_m1") and not GameManager.is_level_unlocked(&"kitchen_m2")
		and not GameManager.is_level_unlocked(&"kitchen_crawl") and not GameManager.is_level_unlocked(&"living_room_m1"),
		"the first mini map is open with its room; the rest open one by one; the crawl space is hidden")

	# Every mini map loads with its task in place.
	var maps_ok := true
	var maps_detail: PackedStringArray = []
	for mid in MiniMaps.all_ids():
		var lvl := await load_level(mid, &"cockroach")
		var mc := lvl.config
		var shards := 0
		for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
			if lvl.is_ancestor_of(c):
				shards += 1
		var has_key := false
		for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
			if lvl.is_ancestor_of(it) and (it as PickupItem).is_key():
				has_key = true
		var traps := 0
		for t in get_tree().get_nodes_in_group(&"mouse_trap"):
			if lvl.is_ancestor_of(t):
				traps += 1
		var ok := lvl.goal != null and shards >= mc.crumbs_required and shards >= 6 and lvl.player.global_position.distance_to(lvl.goal.global_position) > 20.0
		match mc.task:
			"key":
				ok = ok and has_key and not lvl.goal.active
			"summit":
				ok = ok and lvl.goal.active and lvl.goal.global_position.y > 15.0
			"timed":
				ok = ok and lvl.time_left > 30.0
		if mc.theme != "crawl":
			ok = ok and traps >= 1
		if not ok:
			maps_detail.append("%s(%s shards %d key %s traps %d)" % [mid, mc.task, shards, has_key, traps])
		maps_ok = maps_ok and ok
		await unload(lvl)
	check(maps_ok, "every mini map loads with its task: shards to gather, a key, a way out at the top, or a clock %s" % str(maps_detail))

	# A shards map, start to finish: gather, escape, get credits, open the next.
	SaveSystem.data = SaveSystem.default_data()
	var lv := await load_level(&"kitchen_m1", &"cockroach")
	var p := lv.player
	p.invuln = 1000.0
	check(lv.goal and not lv.goal.active, "the way out stays shut until the shards are in")
	var got := 0
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		if lv.is_ancestor_of(c) and got < lv.crumbs_needed:
			p.teleport_to(Transform3D(Basis.IDENTITY, (c as Node3D).global_position + Vector3.UP * 0.4))
			await frames(4)
			if (c as Crumb).taken:
				got += 1
	var hud := lv.find_child("HUD", true, false)
	var shard_text := (hud.get("_crumbs") as Label).text
	check(lv.goal.active and shard_text.begins_with("SHARDS"), "gathering the shards opens the way out (%s)" % shard_text)
	p.teleport_to(Transform3D(Basis.IDENTITY, lv.goal.global_position + Vector3.UP * 1.0))
	await frames(10)
	var res := GameManager.last_result
	check(lv.finished and bool(res.get("won", false)) and bool(res.get("mini", false))
		and int(res.get("credits", 0)) == got + MiniMaps.reward(1) and SaveSystem.credits() == int(res.get("credits", 0))
		and SaveSystem.is_mini_done(&"kitchen_m1") and GameManager.is_level_unlocked(&"kitchen_m2"),
		"escaping pays credits (shards + task bonus: %d) and opens the next mini map" % int(res.get("credits", 0)))
	await unload(lv)

	# A key map: the way out opens only with the key.
	lv = await load_level(&"kitchen_m3", &"cockroach")
	p = lv.player
	p.invuln = 1000.0
	var brass: PickupItem = null
	for it in get_tree().get_nodes_in_group(Phys.GROUP_ITEM):
		if lv.is_ancestor_of(it) and (it as PickupItem).is_key():
			brass = it
	var shut := not lv.goal.active
	p.teleport_to(Transform3D(Basis.IDENTITY, brass.global_position + Vector3.UP * 0.5))
	await frames(6)
	check(shut and lv.has_key and lv.goal.active, "a key map: the brass key opens the way out")
	await unload(lv)

	# A timed map: let the clock run out and you're out of time.
	lv = await load_level(&"kitchen_m4", &"cockroach")
	lv.player.invuln = 1000.0
	lv.time_left = 0.5
	await frames(60)
	check(lv.finished and StringName(GameManager.last_result.get("cause", &"")) == &"out_of_time",
		"a timed map: when the clock runs out, it's over")
	await unload(lv)

	# Mouse traps snap: anything on the plate takes a hit; flyers pass over.
	lv = await load_level(&"kitchen_m1", &"cockroach")
	p = lv.player
	var trap := first_in_group(&"mouse_trap", lv) as MouseTrap
	var hits0 := p.hits_left
	p.teleport_to(Transform3D(Basis.IDENTITY, trap.to_global(Vector3(0, 0.8, 1.4))))
	await frames(30)
	check(trap.snaps == 1 and (p.hits_left < hits0 or p.dead), "a mouse trap snaps on a bug that steps on the plate")
	await unload(lv)

	# The crawl space: opens now and then after a mini map, closes once played.
	SaveSystem.data = SaveSystem.default_data()
	seed(7)
	var opened_after := 0
	for i in 30:
		GameManager.current_level = &"kitchen_m1"
		GameManager.begin_run(RunStats.new())
		GameManager.run.crumbs = 5
		GameManager.finish_run(true)
		if SaveSystem.is_crawl_open(&"kitchen"):
			opened_after = i + 1
			break
	var crawl_open := GameManager.is_level_unlocked(&"kitchen_crawl")
	GameManager.current_level = &"kitchen_crawl"
	GameManager.begin_run(RunStats.new())
	GameManager.run.crumbs = 14
	var cres := GameManager.finish_run(true)
	check(opened_after > 0 and crawl_open and not SaveSystem.is_crawl_open(&"kitchen") and int(cres["credits"]) == 14 * 2 + MiniMaps.reward(10),
		"the hidden crawl space opens now and then (after %d maps), pays double for shards, and closes once played" % opened_after)
	GameManager.set_state(GameManager.State.MENU)

	# The revolver: starter add-ons in the first two chambers; open it, turn
	# to a chamber, fire. The game holds still while it's open.
	SaveSystem.data = SaveSystem.default_data()
	lv = await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	p = lv.player
	p.invuln = 0.0
	var rev := lv.find_child("Revolver", true, false) as Revolver
	check(rev != null and lv.loadout[0] == &"decoy_chirp" and lv.loadout[1] == &"iron_shell"
		and lv.charges_left(&"iron_shell") == 2 and lv.selected_addon() == &"decoy_chirp",
		"you start with Decoy Chirp and Iron Shell loaded (2 uses each)")
	rev.open()
	await frames(2)
	var paused := get_tree().paused and not InputRouter.enabled
	rev.select(1)
	await get_tree().process_frame
	var turned := lv.chamber == 1
	for i in 20:
		await get_tree().process_frame
	var hub := rev.press_at(rev.size * Vector2(0.5, 0.46))
	await frames(3)
	check(paused and turned and hub == "fire" and not rev.is_open and not get_tree().paused
		and p.has_effect(&"iron_shell") and lv.charges_left(&"iron_shell") == 1,
		"open the revolver (the game holds still), turn to Iron Shell, press USE: it fires")
	check(not p.take_hit(&"swatted", p.global_position + Vector3(3, 0, 0)), "Iron Shell: hits glance off")
	p.effects.clear()
	# Quick fire (G) uses the loaded chamber without opening.
	key(KEY_G, true)
	await get_tree().process_frame
	await get_tree().process_frame
	key(KEY_G, false)
	await frames(2)
	check(lv.charges_left(&"iron_shell") == 0 and not lv.fire_selected(), "G fires the loaded chamber; an empty one won't fire")
	rev.select(2)
	check(not lv.fire_selected(), "an empty chamber does nothing")
	rev.select(0)
	var before_decoys := 0
	for c in lv.get_children():
		if c is DecoyEcho:
			before_decoys += 1
	var fired_decoy := lv.fire_selected()
	var after_decoys := 0
	for c in lv.get_children():
		if c is DecoyEcho:
			after_decoys += 1
	check(fired_decoy and after_decoys == before_decoys + 1, "Decoy Chirp throws a noise where you look")
	# Touch: the TOOLS button opens it too.
	var tc := lv.find_child("TouchControls", true, false)
	if tc == null:
		for n in lv.find_children("*", "Control", true, false):
			if n.get("tools_center") != null:
				tc = n
	if tc:
		tc.set("visible", true)
		InputRouter.set_enabled(true)
		tc.call("_on_down", 7, tc.get("tools_center"))
	await frames(2)
	check(tc != null and rev.is_open, "the TOOLS touch button opens the revolver")
	rev.press_at(Vector2(4, 4))
	await frames(2)
	check(not rev.is_open and not get_tree().paused, "tapping outside closes it again")
	await unload(lv)

	# Buying and upgrading with credits; a new add-on goes into an empty chamber.
	SaveSystem.data = SaveSystem.default_data()
	check(not SaveSystem.buy_addon(&"power_legs"), "no credits, no add-ons")
	SaveSystem.add_credits(500)
	var bought := SaveSystem.buy_addon(&"power_legs")
	var up := SaveSystem.buy_addon(&"power_legs")
	check(bought and up and SaveSystem.addon_level(&"power_legs") == 2 and SaveSystem.credits() == 500 - 30 - 60
		and AddOns.charges(2) == 3, "buy an add-on, then upgrade it: level 2 has three uses (credits %d)" % SaveSystem.credits())
	var arm := (load("res://scenes/ui/armory.tscn") as PackedScene).instantiate()
	add_child(arm)
	await frames(2)
	var rows := arm.find_children("Row_*", "", true, false)
	arm.call("buy_addon", &"smoke_bomb")
	await frames(2)
	var rv := SaveSystem.revolver()
	check(rows.size() == 12 and SaveSystem.addon_level(&"smoke_bomb") == 1 and rv.has("smoke_bomb"),
		"the Armory lists 12 add-ons; buying one loads it into an empty chamber")
	arm.set("chamber", 5)
	arm.call("load_into", 5, &"power_legs")
	await frames(2)
	check(String(SaveSystem.revolver()[5]) == "power_legs" and SaveSystem.revolver().count("power_legs") == 1,
		"load an add-on into any chamber (it moves, never doubles up)")
	arm.queue_free()
	await frames(2)

	# Every add-on does its thing.
	for id in AddOns.ids():
		SaveSystem.data["addons"][String(id)] = 1
	lv = await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(13.5)
	p = lv.player
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(-30, 0.4, -12)))
	face(lv, 0.0)
	await frames(5)
	var results := {}
	AddOns.use(&"power_legs", 1, p)
	results["power_legs"] = p.has_effect(&"spring") and p.has_effect(&"grip")
	AddOns.use(&"dash_burst", 1, p)
	results["dash_burst"] = p._dodge_time > 0.0 and p.has_effect(&"turbo")
	await frames(30)
	var pup: Threat = first_in_group(Phys.GROUP_PET, lv) as Threat
	pup.global_position = p.global_position + Vector3(5, 0, 0)
	pup.reset_physics_interpolation()
	AddOns.use(&"ground_pound", 1, p)
	results["ground_pound"] = pup.stun_time > 0.0
	p.effects.clear()
	p.invuln = 0.0
	AddOns.use(&"spiky_armor", 1, p)
	pup.stun_time = 0.0
	var blocked := not p.take_hit(&"pounced", pup.global_position)
	results["spiky_armor"] = blocked and pup.stun_time > 0.0 and not p.has_effect(&"spikes")
	AddOns.use(&"shadow_cloak", 1, p)
	results["shadow_cloak"] = p.has_effect(&"cloak")
	AddOns.use(&"iron_shell", 1, p)
	results["iron_shell"] = p.has_effect(&"iron_shell")
	var shells := p.hits_left
	AddOns.use(&"second_wind", 1, p)
	results["second_wind"] = p.hits_left == shells + 1
	AddOns.use(&"smoke_bomb", 1, p)
	await frames(2)
	var smoke := false
	for c in lv.find_children("*", "Node3D", true, false):
		if c is StinkCloud and (c as StinkCloud).smoke:
			smoke = true
	results["smoke_bomb"] = smoke
	var decoys0 := 0
	for c in lv.get_children():
		if c is DecoyEcho:
			decoys0 += 1
	AddOns.use(&"decoy_chirp", 1, p)
	var decoys1 := 0
	for c in lv.get_children():
		if c is DecoyEcho:
			decoys1 += 1
	results["decoy_chirp"] = decoys1 == decoys0 + 1
	pup.global_position = p.global_position + Vector3(4, 0, 0)
	AddOns.use(&"flash_bead", 1, p)
	results["flash_bead"] = pup.blind_time > 0.0
	AddOns.use(&"crumb_magnet", 1, p)
	results["crumb_magnet"] = p.has_effect(&"magnet")
	# Silk Grapple: aim at the cupboards and zip over, then cling on.
	p.effects.clear()
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(20, 0.4, -4)))
	face(lv, 0.0)
	lv.camera.pitch = -0.05
	await frames(10)
	var from := p.global_position
	var fired := AddOns.use(&"silk_grapple", 1, p)
	for i in 60:
		await get_tree().physics_frame
	results["silk_grapple"] = fired and p.global_position.distance_to(from) > 8.0 and p.climbing
	var failed: PackedStringArray = []
	for k in results.keys():
		if not results[k]:
			failed.append(String(k))
	check(failed.is_empty() and results.size() == 12, "every add-on works: strength, defense and tactics %s" % str(failed))
	await unload(lv)

	# The level select shows each room's mini maps (the crawl space as ?).
	SaveSystem.data = SaveSystem.default_data()
	var ls := (load("res://scenes/ui/level_select.tscn") as PackedScene).instantiate()
	add_child(ls)
	await frames(2)
	var tiles := ls.find_children("Mini_*", "Button", true, false)
	var crawl_tile := ls.find_child("Mini_kitchen_crawl", true, false) as Button
	var m1 := ls.find_child("Mini_kitchen_m1", true, false) as Button
	check(tiles.size() == 10 and crawl_tile.text == "?" and crawl_tile.disabled and not m1.disabled
		and (ls.find_child("Mini_kitchen_m2", true, false) as Button).disabled,
		"an open room lists its ten mini maps: the first open, the rest locked, the crawl space as ? (%d)" % tiles.size())
	ls.queue_free()
	await frames(2)

