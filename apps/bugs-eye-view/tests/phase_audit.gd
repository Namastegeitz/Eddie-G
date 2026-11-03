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
	fly.teleport_to(Transform3D(Basis.IDENTITY, Vector3(0, 45, 40)))
	fly.take_off()
	fly.stamina = 999.0
	face(lvl, PI)
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(240)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(fly.global_position.z < 62.0 and fly.global_position.y < 110.0, "invisible walls keep the fly inside the yard (z=%.1f)" % fly.global_position.z)
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
	check(SaveSystem.is_bug_unlocked(&"spider") and SaveSystem.is_level_completed(&"backyard"), "winning both rooms unlocks the spider and records the backyard")


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
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(35, 15, 18)))
	f.take_off()
	await frames(20)
	check(f.external_velocity.x < -2.0, "the fan pushes a flying fly (wind %.1f)" % f.external_velocity.x)
	var cat := first_in_group(Phys.GROUP_PET, lvl) as Pet
	var lmug: PhysicsProp = null
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		if lvl.is_ancestor_of(n) and (n as PhysicsProp).mass > 2.0:
			lmug = n
	var mug_y := lmug.global_position.y
	cat.global_position = Vector3(50, 0.5, -18)
	cat.force_alert(AlertState.SEARCHING, Vector3(48, 25.5, -33))
	await frames(360)
	check(lmug.global_position.y < mug_y - 5.0, "the cat leaps onto the side table and knocks the mug off")
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
	check(get_viewport().msaa_3d == Viewport.MSAA_2X and GameManager.shadows_enabled(), "high quality turns on antialiasing and shadows")
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
	check(labels.has("ESCAPED!") and labels.has("Fly unlocked!"), "winning shows ESCAPED! and the unlock")
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
		for m in lvl.find_children("*", "GeometryInstance3D", true, false):
			if (m as GeometryInstance3D).is_visible_in_tree():
				meshes += 1
		print("     %s: %.2f ms per frame of logic + physics, %d visible meshes" % [level, ms, meshes])
		check(ms < 4.0, "%s runs its game logic in under 4 ms a frame (%.2f)" % [level, ms])
		check(meshes < 160, "%s keeps visible meshes low for phones (%d)" % [level, meshes])
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
	f.teleport_to(Transform3D(Basis.IDENTITY, Vector3(50, 20, 30)))
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
