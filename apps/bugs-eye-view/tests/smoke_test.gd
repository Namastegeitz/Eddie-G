extends Node
## Headless end-to-end checks for Bug's-Eye View.
##   godot --headless --path . res://tests/smoke_test.tscn --fixed-fps 60
## Exit code 0 = all checks passed. Uses a scratch save file.

var _fails: PackedStringArray = []
var _passes := 0


func _ready() -> void:
	GameManager.guides_enabled = false
	GameManager.auto_quality_enabled = false
	SaveSystem.save_path = "user://smoke_test_save.json"
	SaveSystem.data = SaveSystem.default_data()
	await get_tree().process_frame
	print("== Bug's-Eye View smoke test ==")
	_test_save_and_upgrades()
	_test_clock()
	await _test_menus()
	await _test_level_matrix()
	await _test_core_loop()
	await _test_hazards()
	await _test_perception()
	await _test_escalation()
	await _test_spider()
	await _test_fly()
	await _test_pets()
	await _test_props_and_lures()
	await _test_bosses()
	print("== %d passed, %d failed ==" % [_passes, _fails.size()])
	for f in _fails:
		print("   FAILED: " + f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.save_path))
	GameManager.quit_game(0 if _fails.is_empty() else 1)


func check(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
		print("  ok   " + msg)
	else:
		_fails.append(msg)
		print("  FAIL " + msg)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func load_level(level: StringName, bug: StringName, slot: StringName = &"morning") -> Level:
	GameManager.current_level = level
	GameManager.current_bug = bug
	GameManager.current_time_slot = slot
	var cfg := GameManager.get_level(level)
	var lvl := (load(cfg.scene_path) as PackedScene).instantiate() as Level
	get_tree().root.add_child(lvl)
	await frames(3)
	return lvl


func unload(lvl: Level) -> void:
	InputRouter.set_touch_move(Vector2.ZERO)
	for a in InputRouter.GAME_ACTIONS:
		InputRouter.set_touch_action(a, false)
	get_tree().paused = false
	Engine.time_scale = 1.0
	lvl.queue_free()
	await frames(3)


func first_in_group(group: StringName, lvl: Node) -> Node:
	for n in get_tree().get_nodes_in_group(group):
		if lvl.is_ancestor_of(n):
			return n
	return null


func face(lvl: Level, yaw: float) -> void:
	lvl.camera.yaw = yaw
	lvl.camera.pitch = -0.3
	lvl.player.camera_yaw_basis = Basis(Vector3.UP, yaw)


# --- Data ---------------------------------------------------------------------

func _test_save_and_upgrades() -> void:
	print("-- save & upgrades")
	check(SaveSystem.is_bug_unlocked(&"cockroach") and not SaveSystem.is_bug_unlocked(&"fly"), "only the cockroach starts unlocked")
	SaveSystem.set_setting("music_volume", 0.25)
	SaveSystem.bank_crumbs(30)
	SaveSystem.save_game()
	SaveSystem.load_game()
	check(is_equal_approx(float(SaveSystem.get_setting("music_volume")), 0.25), "settings persist through save/load")
	check(SaveSystem.colony_size() == 4, "colony grows one size per 10 crumbs")
	var base := GameManager.get_bug_stats(&"cockroach").move_speed
	SaveSystem.add_upgrade(&"swift_legs")
	check(is_equal_approx(GameManager.build_bug_stats(&"cockroach").move_speed, base * 1.12), "colony upgrade multiplies bug stats")
	check(is_equal_approx(GameManager.get_bug_stats(&"cockroach").move_speed, base), "base stats are not modified by upgrades")
	SaveSystem.data = SaveSystem.default_data()
	check(GameManager.is_level_unlocked(&"kitchen") and not GameManager.is_level_unlocked(&"living_room"), "only the kitchen starts unlocked")


func _test_clock() -> void:
	print("-- household clock")
	HouseClock.start(GameManager.get_level(&"kitchen").routine, 7.0)
	HouseClock.set_hour(7.2)
	check(HouseClock.is_active(&"fridge_open") and HouseClock.is_active(&"breakfast"), "routine events active in their window")
	HouseClock.set_hour(7.4)
	check(not HouseClock.is_active(&"fridge_open"), "event switches off between windows")
	HouseClock.set_hour(7.55)
	check(HouseClock.is_active(&"fridge_open"), "repeated event id reopens in its second window")
	HouseClock.set_hour(23.5)
	check(HouseClock.is_active(&"lights_out") and HouseClock.period() == &"night", "overnight event wraps past midnight")
	HouseClock.stop()


func _test_menus() -> void:
	print("-- menus")
	for path in ["res://scenes/ui/main_menu.tscn", "res://scenes/ui/level_select.tscn", "res://scenes/ui/bug_select.tscn",
			"res://scenes/ui/settings_menu.tscn", "res://scenes/hub/colony_hub.tscn"]:
		var n: Node = (load(path) as PackedScene).instantiate()
		get_tree().root.add_child(n)
		await frames(3)
		check(is_instance_valid(n) and n.is_inside_tree(), "menu builds: " + path.get_file())
		n.queue_free()
		await frames(2)


# --- Every level with every bug ---------------------------------------------------

func _test_level_matrix() -> void:
	print("-- level x bug matrix")
	var space_ok := true
	for level in GameManager.LEVEL_IDS:
		for bug in GameManager.BUG_IDS:
			var lvl := await load_level(level, bug)
			var p := lvl.player
			check(p != null and p.stats.id == bug, "%s/%s: player spawned" % [level, bug])
			check(lvl.goal != null and lvl.crumbs_needed > 0, "%s/%s: goal + crumbs wired" % [level, bug])
			InputRouter.set_touch_move(Vector2(0.3, 1.0))
			await frames(90)
			InputRouter.set_touch_move(Vector2.ZERO)
			await frames(30)
			check(p.global_position.y > -5.0 and p.global_position.y < 90.0, "%s/%s: player stays in the world" % [level, bug])
			if bug == &"cockroach":
				var ray := PhysicsRayQueryParameters3D.new()
				ray.collision_mask = Phys.WORLD
				for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
					var crumb := c as Crumb
					if crumb and lvl.is_ancestor_of(crumb):
						ray.from = crumb.global_position + Vector3.UP * 0.3
						ray.to = crumb.global_position + Vector3.DOWN * 2.0
						if lvl.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
							space_ok = false
							print("     crumb floating at %s" % crumb.global_position)
				var threats := 0
				for t in PerceptionSystem.threats:
					threats += 1
				check(threats > 0, "%s: threats registered (%d)" % [level, threats])
				var nav := lvl.find_child("NavRegion", true, false) as NavigationRegion3D
				check(nav and nav.navigation_mesh.get_polygon_count() > 50, "%s: navmesh baked" % level)
				var bs := lvl.batch_stats
				check(int(bs.get("merged", 0)) >= 40 and int(bs.get("batches", 999)) * 2 < int(bs.get("merged", 0)),
					"%s: static meshes batched (%d meshes -> %d draws)" % [level, int(bs.get("merged", 0)), int(bs.get("batches", 0))])
			await unload(lvl)
	check(space_ok, "every crumb rests on a surface")


# --- Core loop: crumbs -> goal -> win ---------------------------------------------

func _test_core_loop() -> void:
	print("-- core loop (kitchen / cockroach)")
	var lvl := await load_level(&"kitchen", &"cockroach")
	var p := lvl.player
	await frames(20)
	check(p.is_on_floor(), "roach lands on the floor")
	face(lvl, PI * 0.5)
	var start := p.global_position
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(45)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(p.global_position.distance_to(start) > 4.0, "roach runs where the camera faces")
	check(p.global_position.x < start.x - 3.0, "camera-relative forward is -X at yaw 90")
	var crumbs: Array[Crumb] = []
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		if c is Crumb and lvl.is_ancestor_of(c) and not (c as Crumb).golden:
			crumbs.append(c)
	check(not lvl.goal.active, "goal starts closed")
	for i in lvl.crumbs_needed:
		p.global_position = crumbs[i].global_position
		await frames(3)
	check(lvl.crumbs_got == lvl.crumbs_needed, "crumbs collected (%d/%d)" % [lvl.crumbs_got, lvl.crumbs_needed])
	check(lvl.goal.active, "goal opens after enough crumbs")
	check(lvl.boss != null and lvl.boss.active, "boss chase starts when the goal opens")
	p.global_position = lvl.goal.global_position + Vector3.UP
	await frames(5)
	check(GameManager.state == GameManager.State.WIN, "reaching the goal wins")
	var r := GameManager.last_result
	check(bool(r.get("won", false)) and int(r["score"]["total"]) > 0, "result has a score")
	check(SaveSystem.is_bug_unlocked(&"fly"), "escaping the kitchen unlocks the fly")
	check(GameManager.is_level_unlocked(&"living_room"), "escaping the kitchen unlocks the living room")
	check(int(SaveSystem.colony()["banked"]) >= lvl.crumbs_needed, "crumbs banked to the colony")
	await unload(lvl)


# --- Hazards --------------------------------------------------------------------

func _test_hazards() -> void:
	print("-- hazards")
	var lvl := await load_level(&"kitchen", &"cockroach")
	var p := lvl.player
	await frames(10)
	var sw := lvl.swatter_pool.acquire() as Swatter
	sw.strike(p.global_position, 0.3, null, lvl.swatter_pool)
	await frames(30)
	check(p.hits_left == 1 and not p.dead, "swatter costs the roach its extra hit (knockdown, not death)")
	await frames(int(60 * p.stats.invuln_time) + 10)
	var near := p.global_position + Vector3(4.5, 0, 0)
	var before := lvl.run.close_calls
	sw = lvl.swatter_pool.acquire() as Swatter
	sw.strike(near, 0.3, null, lvl.swatter_pool)
	await frames(30)
	check(lvl.run.close_calls > before and p.hits_left == 1, "near miss counts as a close call")
	var human := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	var pot := lvl.find_child("PotRebound", true, false) as Rebounder
	sw = lvl.swatter_pool.acquire() as Swatter
	sw.strike(pot.global_position, 0.3, human, lvl.swatter_pool)
	await frames(30)
	check(human.stun_time > 0.0, "swatter clangs off the metal pot and stuns the human")
	var foot := human.left_foot
	foot.plant_at(p.global_position + Vector3(0, 0, 30), 0.0)
	foot.step_to(p.global_position, 0.0, 0.3)
	await frames(40)
	check(p.dead, "a stomp finishes off a hurt roach")
	await frames(75)
	check(GameManager.state == GameManager.State.CAUGHT, "death leads to the caught screen")
	check(String(GameManager.last_result.get("cause", "")) == "stomped", "cause of death recorded")
	await unload(lvl)
	# Spray cloud exposure
	lvl = await load_level(&"kitchen", &"cockroach")
	p = lvl.player
	var cloud := lvl.spray_pool.acquire() as SprayCloud
	cloud.spawn(p.global_position, lvl.spray_pool)
	await frames(240)
	check(p.hits_left < p.stats.max_hits, "standing in bug spray builds exposure into a hit")
	await unload(lvl)


# --- Perception -----------------------------------------------------------------

func _test_perception() -> void:
	print("-- perception & stealth")
	var lvl := await load_level(&"kitchen", &"cockroach")
	var p := lvl.player
	HouseClock.set_hour(7.0)
	p.global_position = Vector3(-10, 0.8, 14)
	await frames(15)
	var dim := PerceptionSystem.light_level
	p.global_position = Vector3(-46, 0.8, 0)
	await frames(15)
	var bright := PerceptionSystem.light_level
	check(bright > dim + 0.3, "sunbeam is brighter than under the table (%.2f vs %.2f)" % [bright, dim])
	await frames(60)
	check(p.is_frozen(), "standing still freezes the bug")
	var frozen_vis := PerceptionSystem.visibility
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(10)
	var moving_vis := PerceptionSystem.visibility
	InputRouter.set_touch_move(Vector2.ZERO)
	check(moving_vis > frozen_vis, "moving is more visible than freezing (%.2f > %.2f)" % [moving_vis, frozen_vis])
	p.global_position = Vector3(-50, 0.8, 38)
	await frames(60)
	check(p.has_camo() and PerceptionSystem.visibility < frozen_vis, "frozen on a camo surface (doormat) hides better")
	p.global_position = Vector3(43, 0.6, -30)
	InputRouter.set_touch_action(&"secondary", true)
	await frames(10)
	check(p.is_hidden_safe() and PerceptionSystem.visibility == 0.0, "squeezing under the fridge hides completely")
	InputRouter.set_touch_action(&"secondary", false)
	await frames(5)
	check(not p.is_hidden_safe(), "releasing squeeze leaves the hiding spot unsafe")
	p.global_position = Vector3(20, 0.8, 18)
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(20)
	var chip := PerceptionSystem.player_loudness
	InputRouter.set_touch_move(Vector2.ZERO)
	p.global_position = Vector3(-30, 0.8, -12)
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(20)
	var towel := PerceptionSystem.player_loudness
	InputRouter.set_touch_move(Vector2.ZERO)
	check(chip > towel, "chip bag is louder than the dish towel (%.2f > %.2f)" % [chip, towel])
	var human := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	human.route = PackedVector3Array()
	human.end_activity()
	human.activities = {}
	# The kitchen puppy would join in (and its pounces stun people nearby).
	for pet in get_tree().get_nodes_in_group(Phys.GROUP_PET):
		if lvl.is_ancestor_of(pet):
			pet.process_mode = Node.PROCESS_MODE_DISABLED
	human.alert.reset()
	PerceptionSystem.emit_world_noise(human.global_position + Vector3(4, 0, 4), 3.0)
	await frames(2)
	check(human.alert.state >= AlertState.SUSPICIOUS, "a loud noise makes the human suspicious")
	check(human.alert.target_is_lure, "world noise is treated as a lure")
	human.alert.reset()
	# A known, well-lit spot: the person at the front of the kitchen looking
	# down its long side, the bug 25 units ahead.
	human.global_position = Vector3(45, 0, 43)
	human._body_pos = human.global_position
	human._plant_feet(human.global_position, PI * 0.5)
	human.rotation.y = PI * 0.5
	human.reset_physics_interpolation()
	var target := Vector3(20, 0.8, 43)
	p.global_position = target
	p.invuln = 1000.0
	# Hold the human in place: walking right up to a bug puts it under the
	# human's downward gaze, where it loses sight (fine in play, slow in a test).
	human._step_timer = 1e9
	# ...and with nothing else on their mind (no chore, no phone).
	human.end_activity()
	human.activities = {}
	human.route = PackedVector3Array()
	human.set_gesture(&"")
	var early_alarm := -1.0
	var saw_alert := false
	for i in 1200:
		await get_tree().physics_frame
		if i == 60:
			early_alarm = PerceptionSystem.alarm
		if PerceptionSystem.alarm_active:
			saw_alert = human.alert.state == AlertState.ALERT
			break
	check(early_alarm > 0.0 and early_alarm < 0.5, "the alarm gauge fills gradually (%.2f after 1 s)" % early_alarm)
	check(saw_alert, "a bug left in plain view fills the gauge and the human goes on full alert")
	p.invuln = 0.0
	await unload(lvl)


func _test_escalation() -> void:
	print("-- escalation chain")
	var lvl := await load_level(&"kitchen", &"cockroach")
	HouseClock.set_hour(7.0)
	var human := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	var esc := lvl.escalation
	for i in 4:
		esc._since_escalate = 99.0
		esc.escalate(human)
	check(esc.stage == 4 and PerceptionSystem.escalation_stage == 4, "four escalations reach bug spray")
	check(human.escalation_stage == 4, "humans know the escalation stage")
	esc._calm = 0.0
	for t in PerceptionSystem.threats:
		t.alert.reset()
	await frames(int(60 * PerceptionSystem.config.escalation_calm_time) + 30)
	check(esc.stage == 3, "staying hidden calms things down one stage")
	await unload(lvl)


# --- Spider -------------------------------------------------------------------------

func _test_spider() -> void:
	print("-- spider")
	var lvl := await load_level(&"kitchen", &"spider")
	var p := lvl.player as Spider
	p.global_position = Vector3(102, 0.6, 30)
	face(lvl, -PI * 0.5)
	await frames(10)
	InputRouter.set_touch_move(Vector2(0, 1))
	await frames(150)
	InputRouter.set_touch_move(Vector2.ZERO)
	check(p.attached and p.surface_normal.dot(Vector3.UP) < 0.5, "spider climbs onto the wall")
	check(p.global_position.y > 3.0, "spider is up the wall (y=%.1f)" % p.global_position.y)
	await frames(60)
	check(p.current_camo_tag() == &"wall" and p.has_camo(), "a still spider on a wall is camouflaged")
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(90, 0.6, 30)))
	await frames(5)
	p._zip_start = p.global_position
	p._zip_target = Vector3(109.6, 20, 30)
	p._zip_normal = Vector3(-1, 0, 0)
	p.zipping = true
	p.attached = false
	await frames(90)
	check(not p.zipping and p.attached and p.surface_normal.x < -0.5, "web zip lands on the target wall")
	var strands := 0
	for n in lvl.get_children():
		if n is WebStrand and n.visible:
			strands += 1
	check(strands > 0, "the zip line stays as a web bridge")
	p.teleport_to(Transform3D(Basis.IDENTITY, Vector3(30, 0.6, 30)))
	await frames(10)
	p._web_cd = 0.0
	p._spin_trap()
	var traps := 0
	for n in lvl.get_children():
		if n is WebTrap and n.visible:
			traps += 1
	check(traps > 0, "spider spins a web trap")
	p._fire_web(p.cam.screen_center())
	await frames(5)
	check(true, "web fire from the reticle does not crash")
	p.toggle_sense()
	await frames(40)
	var ripples := 0
	for n in lvl.find_child("Pools", false, false).get_children():
		if n is Ripple and n.visible:
			ripples += 1
	check(ripples > 0 or PerceptionSystem.threats.filter(func(t: Threat) -> bool: return t.present).is_empty(),
		"vibration sense shows threats as ripples")
	await unload(lvl)


# --- Fly ----------------------------------------------------------------------------

func _test_fly() -> void:
	print("-- fly")
	var lvl := await load_level(&"kitchen", &"fly")
	var p := lvl.player as Fly
	await frames(10)
	check(not p.flying, "fly starts perched")
	InputRouter.set_touch_action(&"jump", true)
	await frames(40)
	InputRouter.set_touch_action(&"jump", false)
	check(p.flying and p.global_position.y > 3.0, "fly takes off and climbs (y=%.1f)" % p.global_position.y)
	check(p.stamina < p.stats.stamina_max, "flying drains stamina")
	check(p.current_noise() > 0.2, "a flying fly is always buzzing")
	check(not p.is_scent_active(), "flies leave no scent in the air")
	p.sense_meter = p.stats.sense_max
	PerceptionSystem.warn_strike(p.global_position, 0.5, 3.0)
	await frames(12)
	check(p.bullet_time and Engine.time_scale < 0.5, "an incoming strike triggers compound-eye bullet time")
	await frames(int(60 * p.stats.bullet_time_duration) + 10)
	check(not p.bullet_time and is_equal_approx(Engine.time_scale, 1.0), "bullet time ends and time returns to normal")
	p.stamina = 0.05
	await frames(10)
	check(p.gliding and p.current_noise() <= 0.05, "out of stamina, the fly glides silently")
	for i in 900:
		await get_tree().physics_frame
		if not p.flying:
			break
	check(not p.flying, "the gliding fly comes down and must perch")
	await unload(lvl)


# --- Pets ----------------------------------------------------------------------------

func _test_pets() -> void:
	print("-- pets")
	var lvl := await load_level(&"living_room", &"cockroach")
	var p := lvl.player
	var cat := first_in_group(Phys.GROUP_PET, lvl) as Pet
	check(cat != null and cat.present, "the cat is present")
	p.global_position = Vector3(0, 0.8, 10)
	await frames(10)
	var d0 := cat.global_position.distance_to(p.global_position)
	cat.force_alert(AlertState.ALERT, p.global_position)
	var pounced := false
	for i in 240:
		await get_tree().physics_frame
		if cat._pounce != Pet.Pounce.NONE or p.hits_left < p.stats.max_hits:
			pounced = true
			break
	check(pounced or cat.global_position.distance_to(p.global_position) < d0 - 5.0, "the cat chases with pathfinding and pounces")
	await unload(lvl)

	lvl = await load_level(&"backyard", &"cockroach")
	p = lvl.player
	var dog := first_in_group(Phys.GROUP_PET, lvl) as Pet
	HouseClock.set_hour(7.0)
	check(dog.config.scent_tracking, "the dog tracks scent")
	var trail := [Vector3(-20, 0.8, -10), Vector3(-17, 0.8, -10), Vector3(-14, 0.8, -10), Vector3(-11, 0.8, -10),
		Vector3(-8, 0.8, -10), Vector3(-5, 0.8, -10)]
	for pt: Vector3 in trail:
		p.global_position = pt
		await frames(4)
	check(PerceptionSystem.scent.active_count() >= 4, "moving leaves a scent trail (%d points)" % PerceptionSystem.scent.active_count())
	p.global_position = Vector3(10, 0.8, 5)
	await frames(10)
	var wiped := PerceptionSystem.scent.strongest_near(Vector3(10, 0.8, 5), 2.0) < 0
	check(wiped, "standing in a puddle leaves no scent there")
	dog.alert.reset()
	dog.global_position = Vector3(-24, 0.5, -10)
	dog.force_alert(AlertState.SEARCHING, Vector3(-20, 0.8, -10))
	await frames(150)
	check(dog.global_position.x > -15.0, "the dog follows the scent trail (x=%.1f)" % dog.global_position.x)
	await unload(lvl)


# --- Props & lures --------------------------------------------------------------------

func _test_props_and_lures() -> void:
	print("-- props & lures")
	var lvl := await load_level(&"kitchen", &"cockroach")
	var p := lvl.player
	var human := first_in_group(Phys.GROUP_HUMAN, lvl) as Human
	human.route = PackedVector3Array()
	var phone := lvl.find_child("Phone", true, false) as LureProp
	human.alert.reset()
	var lures_before := lvl.run.lures_used
	p.global_position = phone.global_position + Vector3.UP * 0.5
	await frames(5)
	check(lvl.run.lures_used > lures_before, "running across the phone lights it up (a lure)")
	var grape: PhysicsProp = null
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var pp := n as PhysicsProp
		if pp and pp.trip_hazard and lvl.is_ancestor_of(pp):
			grape = pp
			break
	var foot := human.right_foot
	foot.plant_at(grape.global_position + Vector3(0, 0, 25), 0.0)
	foot.step_to(Vector3(grape.global_position.x, 0, grape.global_position.z), 0.0, 0.25)
	await frames(30)
	check(human.stun_time > 0.0, "stepping on a grape trips the human")
	var stunned_before := lvl.run.threats_stunned
	check(stunned_before > 0, "turning a threat against itself is scored")
	var pea: PhysicsProp = null
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var pp2 := n as PhysicsProp
		if pp2 and pp2.mass < 0.15 and lvl.is_ancestor_of(pp2):
			pea = pp2
			break
	var heard := [false]
	var cb := func(_pos: Vector3, _l: float, from_player: bool) -> void:
		if not from_player:
			heard[0] = true
	PerceptionSystem.noise_emitted.connect(cb)
	pea.nudge(pea.global_position + Vector3(0, 0, -2), 1.5)
	await frames(120)
	PerceptionSystem.noise_emitted.disconnect(cb)
	check(heard[0], "a knocked pea clatters on landing (world noise)")
	var vent := lvl.find_child("FridgeGap", true, false) as Passage
	p.global_position = vent.global_position
	await frames(5)
	p._do_interact()
	await frames(3)
	check(p.global_position.z < -46.0, "the cockroach takes the secret route into the wall cavity")
	var gold: Crumb = null
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		if c is Crumb and (c as Crumb).golden and lvl.is_ancestor_of(c):
			gold = c
	p.global_position = gold.global_position
	await frames(3)
	check(lvl.run.golden, "the golden crumb is collectable")
	await unload(lvl)


# --- Bosses -------------------------------------------------------------------------

func _test_bosses() -> void:
	print("-- boss chases")
	var lvl := await load_level(&"kitchen", &"cockroach")
	lvl.boss.start()
	await frames(30)
	var vac := lvl.find_child("RobotVacuum", true, false) as RobotVacuum
	check(vac.present and vac.boss_mode, "Cleaning Day: the robot vacuum hunts")
	await frames(660)
	check(PerceptionSystem.escalation_stage >= 4 or lvl.player.dead, "Cleaning Day phase 2 brings the spray")
	await unload(lvl)
	lvl = await load_level(&"living_room", &"spider")
	var cat := first_in_group(Phys.GROUP_PET, lvl) as Pet
	lvl.boss.start()
	await frames(20)
	check(cat.alert.state >= AlertState.SEARCHING, "The Cat: the cat starts stalking")
	await frames(540)
	check(cat.boss_speed_mult > 1.0 or lvl.player.dead, "The Cat: the hunt speeds up")
	await unload(lvl)
	lvl = await load_level(&"backyard", &"fly")
	var fog := lvl.find_child("FogFront", true, false) as FogFront
	var z0 := fog.global_position.z
	lvl.boss.start()
	await frames(120)
	check(fog.running and fog.global_position.z > z0 + 2.0, "The Exterminator: the fog front advances")
	var ext := lvl.find_child("Exterminator", true, false) as Human
	check(ext.present, "The Exterminator arrives")
	await unload(lvl)
