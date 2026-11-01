class_name ResBuilder
## Writes every tunable .tres: materials, stealth/scoring config, bug stats,
## threat configs, upgrades, routines, level configs and the sound library.
## These files are the editable source of truth afterwards.

const MAT_DIR := "res://assets/materials/"


static func save(res: Resource, path: String, force: bool) -> Resource:
	if not force and ResourceLoader.exists(path):
		return load(path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("save failed %s (%d)" % [path, err])
	return load(path)


static func _mat(color: Color, rough: float = 0.8, metal: float = 0.0, alpha: bool = false,
		unshaded: bool = false, emission: Color = Color(0, 0, 0, 0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if alpha or color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission.a > 0.0:
		m.emission_enabled = true
		m.emission = Color(emission.r, emission.g, emission.b)
		m.emission_energy_multiplier = emission.a
	return m


static func materials(force: bool) -> void:
	var defs := {
		"tile": _mat(Color(0.74, 0.72, 0.66), 0.6),
		"wood": _mat(Color(0.66, 0.47, 0.28)),
		"dark_wood": _mat(Color(0.33, 0.2, 0.11)),
		"counter_stone": _mat(Color(0.42, 0.42, 0.44), 0.4),
		"metal": _mat(Color(0.72, 0.73, 0.76), 0.3, 0.8),
		"dark_metal": _mat(Color(0.18, 0.18, 0.2), 0.4, 0.6),
		"fridge_white": _mat(Color(0.93, 0.93, 0.9), 0.3),
		"wall_paint": _mat(Color(0.82, 0.76, 0.62)),
		"wall_blue": _mat(Color(0.5, 0.6, 0.68)),
		"ceiling": _mat(Color(0.92, 0.9, 0.86)),
		"cloth_red": _mat(Color(0.62, 0.16, 0.14), 1.0),
		"cloth_blue": _mat(Color(0.2, 0.32, 0.55), 1.0),
		"carpet": _mat(Color(0.45, 0.32, 0.22), 1.0),
		"rug": _mat(Color(0.55, 0.42, 0.62), 1.0),
		"glass": _mat(Color(0.7, 0.85, 0.95, 0.35), 0.1),
		"window": _mat(Color(0.75, 0.9, 1.0), 0.2, 0.0, false, true),
		"chip_bag": _mat(Color(0.95, 0.65, 0.1), 0.3, 0.5),
		"foil": _mat(Color(0.85, 0.86, 0.9), 0.15, 1.0),
		"paper": _mat(Color(0.92, 0.9, 0.84)),
		"grass": _mat(Color(0.32, 0.55, 0.22), 1.0),
		"soil": _mat(Color(0.3, 0.2, 0.12), 1.0),
		"patio": _mat(Color(0.62, 0.58, 0.52), 0.9),
		"fence": _mat(Color(0.55, 0.42, 0.3)),
		"leaf_green": _mat(Color(0.25, 0.6, 0.2)),
		"flower": _mat(Color(0.95, 0.4, 0.55)),
		"leaves": _mat(Color(0.7, 0.45, 0.15), 1.0),
		"crumb": _mat(Color(0.86, 0.66, 0.34)),
		"golden": _mat(Color(1.0, 0.8, 0.2), 0.2, 0.9, false, false, Color(1.0, 0.7, 0.2, 1.5)),
		"skin": _mat(Color(0.86, 0.66, 0.52)),
		"jeans": _mat(Color(0.22, 0.3, 0.5)),
		"shirt": _mat(Color(0.75, 0.3, 0.25)),
		"shoe": _mat(Color(0.2, 0.17, 0.15)),
		"hazmat": _mat(Color(0.95, 0.85, 0.15)),
		"cat_orange": _mat(Color(0.9, 0.55, 0.2)),
		"dog_brown": _mat(Color(0.5, 0.33, 0.18)),
		"vacuum": _mat(Color(0.12, 0.12, 0.14), 0.3, 0.5),
		"swatter": _mat(Color(0.85, 0.15, 0.12), 0.6),
		"roach": _mat(Color(0.42, 0.24, 0.1), 0.35),
		"fly": _mat(Color(0.15, 0.15, 0.17), 0.4),
		"fly_eye": _mat(Color(0.75, 0.1, 0.1), 0.2),
		"wing": _mat(Color(0.85, 0.9, 1.0, 0.35), 0.1),
		"spider": _mat(Color(0.08, 0.07, 0.07), 0.5),
		"web": _mat(Color(0.95, 0.95, 1.0, 0.65), 0.5, 0.0, true, true),
		"water": _mat(Color(0.35, 0.6, 0.9, 0.55), 0.05),
		"spray": _mat(Color(0.55, 0.95, 0.35, 0.35), 1.0, 0.0, true, true),
		"fog": _mat(Color(0.55, 0.9, 0.35, 0.45), 1.0, 0.0, true, true),
		"beacon": _mat(Color(1.0, 0.8, 0.25, 0.55), 1.0, 0.0, true, true),
		"screen_glow": _mat(Color(0.7, 0.85, 1.0), 1.0, 0.0, false, true),
		"tv_screen": _mat(Color(0.35, 0.55, 0.95), 1.0, 0.0, false, true),
		"shadow_tint": _mat(Color(0.0, 0.0, 0.0, 0.32), 1.0, 0.0, true, true),
		"light_tint": _mat(Color(1.0, 0.9, 0.55, 0.16), 1.0, 0.0, true, true),
		"hole": _mat(Color(0.02, 0.015, 0.01), 1.0, 0.0, false, true),
		"arrow": _mat(Color(1.0, 0.8, 0.25), 1.0, 0.0, false, true),
		"gust": _mat(Color(0.9, 0.95, 1.0, 0.12), 1.0, 0.0, true, true),
		"lamp": _mat(Color(1.0, 0.92, 0.7), 1.0, 0.0, false, true),
		"plastic_white": _mat(Color(0.95, 0.95, 0.95), 0.4),
		"grape": _mat(Color(0.45, 0.15, 0.5), 0.3),
		"pea": _mat(Color(0.4, 0.75, 0.25), 0.4),
		"ball": _mat(Color(0.9, 0.2, 0.2), 0.5),
	}
	for k: String in defs.keys():
		var mat: StandardMaterial3D = defs[k]
		if k in ["web", "beacon", "shadow_tint", "light_tint", "gust", "spray", "fog"]:
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		if k in ["shadow_tint", "light_tint", "gust", "beacon"]:
			mat.disable_receive_shadows = true
		save(mat, MAT_DIR + k + ".tres", force)


static func configs(force: bool) -> void:
	save(StealthConfig.new(), "res://resources/config/stealth_config.tres", force)
	save(ScoringConfig.new(), "res://resources/config/scoring_config.tres", force)


static func bugs(force: bool) -> void:
	var r := BugStats.new()
	r.id = &"cockroach"
	r.display_name = "Cockroach"
	r.description = "Fast on the ground and tough as nails. Squeezes flat into gaps, survives one extra hit, plays dead, smells crumbs and loves the dark."
	r.scene_path = "res://scenes/bugs/cockroach.tscn"
	r.color = Color(0.42, 0.24, 0.1)
	r.rating_speed = 0.8
	r.rating_stealth = 0.5
	r.rating_toughness = 0.9
	r.max_hits = 2
	r.knockdown_time = 1.0
	r.move_speed = 9.0
	r.sprint_speed = 15.0
	r.acceleration = 70.0
	r.jump_velocity = 7.0
	r.noise_mult = 0.9
	r.camo_tags = PackedStringArray(["dark_wood", "soil"])
	r.sense_max = 5.0
	r.sense_regen = 0.4
	r.sense_range = 60.0
	r.dodge_speed = 20.0
	r.push_force = 0.6
	save(r, "res://resources/bugs/cockroach.tres", force)

	var f := BugStats.new()
	f.id = &"fly"
	f.display_name = "Fly"
	f.description = "Erratic, buzzy flight in full 3D. Burst-dodge swats and see strikes in slow motion - but it can't stay airborne forever, and buzzing is loud."
	f.scene_path = "res://scenes/bugs/fly.tscn"
	f.color = Color(0.15, 0.15, 0.17)
	f.unlock_hint = "escape the Kitchen"
	f.rating_speed = 1.0
	f.rating_stealth = 0.35
	f.rating_toughness = 0.2
	f.max_hits = 1
	f.move_speed = 4.0
	f.acceleration = 50.0
	f.flight_speed = 13.0
	f.boost_speed = 21.0
	f.stamina_max = 8.0
	f.stamina_regen = 2.5
	f.visibility_mult = 1.1
	f.camo_tags = PackedStringArray(["dark_wood", "glass"])
	f.sense_max = 6.0
	f.sense_regen = 0.6
	f.dodge_speed = 22.0
	f.dodge_duration = 0.15
	f.dodge_cooldown = 0.7
	save(f, "res://resources/bugs/fly.tres", force)

	var s := BugStats.new()
	s.id = &"spider"
	s.display_name = "Spider"
	s.description = "Master of stealth and height. Crawls on walls and ceilings, zips on web lines that become bridges, spins traps and feels footsteps through the floor. Slow in the open."
	s.scene_path = "res://scenes/bugs/spider.tscn"
	s.color = Color(0.08, 0.07, 0.07)
	s.unlock_hint = "escape the Living Room"
	s.rating_speed = 0.55
	s.rating_stealth = 0.95
	s.rating_toughness = 0.3
	s.max_hits = 1
	s.move_speed = 7.0
	s.floor_speed_mult = 0.6
	s.wall_speed = 7.5
	s.jump_velocity = 9.0
	s.visibility_mult = 0.85
	s.noise_mult = 0.5
	s.camo_tags = PackedStringArray(["wall", "web", "dark_wood"])
	s.web_range = 32.0
	s.zip_speed = 32.0
	s.web_cooldown = 0.5
	s.bridge_duration = 10.0
	s.sense_max = 6.0
	s.sense_range = 70.0
	s.dodge_speed = 14.0
	s.dodge_duration = 0.15
	s.dodge_cooldown = 0.8
	save(s, "res://resources/bugs/spider.tres", force)


static func threats(force: bool) -> void:
	var h := ThreatConfig.new()
	h.sight_range = 70.0
	h.sight_angle_deg = 80.0
	h.near_sense_radius = 6.0
	h.eye_height = 62.0
	h.gaze_pitch_deg = 38.0
	h.min_visibility = 0.12
	h.hearing_radius = 22.0
	h.hearing_gain = 0.5
	h.suspicion_gain = 1.8
	h.lose_sight_time = 2.0
	h.search_duration = 9.0
	h.turn_speed = 3.0
	h.attack_range = 30.0
	h.attack_windup = 0.85
	h.attack_cooldown = 2.2
	h.stun_duration = 4.5
	save(h, "res://resources/threats/human.tres", force)

	var x: ThreatConfig = h.duplicate()
	x.sight_range = 80.0
	x.hearing_radius = 28.0
	x.attack_cooldown = 1.6
	x.attack_windup = 0.75
	x.search_duration = 12.0
	save(x, "res://resources/threats/exterminator.tres", force)

	var c := ThreatConfig.new()
	c.sight_range = 45.0
	c.sight_angle_deg = 140.0
	c.near_sense_radius = 4.0
	c.eye_height = 5.0
	c.gaze_pitch_deg = 10.0
	c.hearing_radius = 26.0
	c.hearing_gain = 0.7
	c.suspicion_gain = 2.0
	c.suspicion_decay = 0.3
	c.search_duration = 10.0
	c.patrol_speed = 6.0
	c.search_speed = 10.0
	c.chase_speed = 17.0
	c.turn_speed = 6.0
	c.attack_range = 9.0
	c.attack_windup = 0.55
	c.attack_cooldown = 1.8
	c.attack_radius = 2.8
	c.stun_duration = 4.0
	save(c, "res://resources/threats/cat.tres", force)

	var d := ThreatConfig.new()
	d.sight_range = 35.0
	d.sight_angle_deg = 120.0
	d.eye_height = 6.0
	d.gaze_pitch_deg = 5.0
	d.hearing_radius = 34.0
	d.hearing_gain = 0.8
	d.scent_tracking = true
	d.scent_radius = 16.0
	d.suspicion_gain = 1.4
	d.search_duration = 14.0
	d.patrol_speed = 6.0
	d.search_speed = 9.0
	d.chase_speed = 15.0
	d.attack_range = 7.0
	d.attack_windup = 0.7
	d.attack_cooldown = 2.0
	d.attack_radius = 3.2
	d.stun_duration = 3.5
	save(d, "res://resources/threats/dog.tres", force)

	var v := ThreatConfig.new()
	v.sight_range = 0.0
	v.hearing_radius = 30.0
	v.hearing_gain = 0.9
	v.search_duration = 12.0
	v.stun_duration = 4.0
	save(v, "res://resources/threats/vacuum.tres", force)


static func upgrades(force: bool) -> void:
	var defs := [
		["swift_legs", "Swift Legs", "+12% running, crawling and flying speed.", 15, 1, [],
			{"move_speed": 1.12, "sprint_speed": 1.12, "wall_speed": 1.12, "flight_speed": 1.08}],
		["hushed_steps", "Hushed Steps", "20% quieter footsteps.", 20, 2, ["cockroach", "spider"],
			{"noise_mult": 0.8}],
		["deep_camo", "Deep Camo", "Blending in hides you 35% better.", 25, 2, [],
			{"camo_mult": 1.35}],
		["tough_shell", "Tough Shell", "Recover from a knockdown 40% faster.", 20, 2, ["cockroach"],
			{"knockdown_time": 0.6, "invuln_time": 1.3}],
		["long_silk", "Long Silk", "30% longer web lines; bridges last 50% longer.", 25, 3, ["spider"],
			{"web_range": 1.3, "bridge_duration": 1.5}],
		["hushed_wings", "Hushed Wings", "25% quieter buzz and 15% less tiring flight.", 25, 3, ["fly"],
			{"noise_mult": 0.75, "stamina_drain": 0.85}],
		["keen_senses", "Keen Senses", "Bigger, faster-charging sense meter with more range.", 30, 4, [],
			{"sense_max": 1.4, "sense_regen": 1.3, "sense_range": 1.25}],
		["strong_wings", "Strong Wings", "35% more flight stamina.", 30, 4, ["fly"],
			{"stamina_max": 1.35}],
	]
	for d: Array in defs:
		var u := UpgradeDef.new()
		u.id = StringName(d[0])
		u.display_name = d[1]
		u.description = d[2]
		u.cost = d[3]
		u.required_colony = d[4]
		u.applies_to = PackedStringArray(d[5])
		u.modifiers = d[6]
		save(u, "res://resources/upgrades/%s.tres" % d[0], force)


static func _routine(events: Array, rate: float = 0.6) -> RoutineSchedule:
	var r := RoutineSchedule.new()
	r.hours_per_minute = rate
	var arr: Array[RoutineEvent] = []
	for e: Array in events:
		var ev := RoutineEvent.new()
		ev.id = StringName(e[0])
		ev.label = e[1]
		ev.start_hour = e[2]
		ev.end_hour = e[3]
		arr.append(ev)
	r.events = arr
	return r


static func routines(force: bool) -> Dictionary:
	var out := {}
	out["kitchen"] = save(_routine([
		["breakfast", "Breakfast rush", 7.0, 7.75],
		["fridge_open", "Fridge open", 7.15, 7.3],
		["fridge_open", "Fridge open", 7.5, 7.6],
		["sunbeam", "", 7.0, 11.0],
		["lights_on", "", 7.0, 8.25],
		["quiet", "Kitchen empty", 7.75, 8.25],
		["dishes", "Doing the dishes", 8.25, 8.9],
		["cleaning", "Cleaning day", 8.9, 9.8],
		["lunch", "Lunch", 13.0, 13.6],
		["fridge_open", "Fridge open", 13.2, 13.3],
		["lights_on", "", 13.0, 13.6],
		["nap", "Afternoon nap", 13.6, 14.3],
		["cleaning", "Cleaning day", 14.3, 15.2],
		["dishes", "Doing the dishes", 15.2, 15.8],
		["late_snack", "Late snack", 21.5, 22.0],
		["fridge_open", "Fridge open", 21.7, 21.85],
		["lights_on", "", 21.5, 22.0],
		["lights_out", "Lights out", 22.0, 5.0],
		["midnight_snack", "Midnight snack", 23.0, 23.4],
		["fridge_open", "Fridge open", 23.1, 23.2],
	]), "res://resources/routines/kitchen.tres", force)
	out["living_room"] = save(_routine([
		["tv_on", "TV on", 7.0, 8.0],
		["curtains_open", "", 7.5, 12.0],
		["fan_on", "Fan on", 7.0, 12.0],
		["reading", "Reading the paper", 8.0, 8.8],
		["cat_nap", "Cat napping", 8.0, 9.0],
		["tv_on", "TV on", 13.0, 14.0],
		["cat_nap", "Cat napping", 13.0, 13.8],
		["reading", "Reading the paper", 13.8, 14.6],
		["fan_on", "Fan on", 13.0, 17.0],
		["curtains_open", "", 13.0, 17.0],
		["lamp_on", "Lamp on", 21.5, 23.0],
		["tv_on", "Late-night TV", 21.5, 22.5],
		["reading", "Reading the paper", 22.5, 23.0],
		["lights_out", "Lights out", 23.0, 6.0],
	]), "res://resources/routines/living_room.tres", force)
	out["backyard"] = save(_routine([
		["watering", "Sprinklers on", 7.0, 7.6],
		["gardening", "Gardening", 7.6, 8.6],
		["dog_nap", "Dog napping", 8.6, 9.4],
		["bbq", "Barbecue", 13.0, 14.0],
		["dog_nap", "Dog napping", 14.0, 14.7],
		["watering", "Sprinklers on", 14.7, 15.3],
		["porch_light", "Porch light on", 21.5, 24.0],
		["gardening", "Night watering", 21.5, 22.2],
		["watering", "Sprinklers on", 21.5, 22.2],
		["lights_out", "", 22.2, 6.0],
	]), "res://resources/routines/backyard.tres", force)
	return out


static func levels(force: bool, routines_by_id: Dictionary) -> void:
	var k := LevelConfig.new()
	k.id = &"kitchen"
	k.display_name = "Kitchen"
	k.description = "Breakfast rush, a swatter by the sink and a robot vacuum on cleaning day. Learn to hide in the shadows."
	k.scene_path = "res://scenes/levels/kitchen.tscn"
	k.order = 0
	k.crumbs_required = 8
	k.par_time = 180.0
	k.unlocks_bug = &"fly"
	k.boss_name = "Cleaning Day"
	k.routine = routines_by_id["kitchen"]
	k.ambient_noise = 0.1
	save(k, "res://resources/levels/kitchen.tres", force)

	var l := LevelConfig.new()
	l.id = &"living_room"
	l.display_name = "Living Room"
	l.description = "The TV hides your noise, the rug muffles your steps - and the cat is always watching."
	l.scene_path = "res://scenes/levels/living_room.tscn"
	l.order = 1
	l.crumbs_required = 9
	l.par_time = 220.0
	l.unlock_after = &"kitchen"
	l.unlocks_bug = &"spider"
	l.boss_name = "The Cat"
	l.routine = routines_by_id["living_room"]
	l.ambient_light_by_period = {&"morning": 0.6, &"afternoon": 0.65, &"evening": 0.45, &"night": 0.25}
	l.ambient_noise = 0.05
	save(l, "res://resources/levels/living_room.tres", force)

	var b := LevelConfig.new()
	b.id = &"backyard"
	b.display_name = "Backyard"
	b.description = "Open sky, a dog with a nose for bugs, sprinklers and the exterminator's fog."
	b.scene_path = "res://scenes/levels/backyard.tscn"
	b.order = 2
	b.crumbs_required = 10
	b.par_time = 260.0
	b.unlock_after = &"living_room"
	b.boss_name = "The Exterminator"
	b.routine = routines_by_id["backyard"]
	b.ambient_light_by_period = {&"morning": 0.85, &"afternoon": 0.9, &"evening": 0.6, &"night": 0.22}
	b.ambient_noise = 0.15
	b.intensity_ramp_seconds = 300.0
	save(b, "res://resources/levels/backyard.tres", force)


static func sound_library(force: bool) -> void:
	var lib := SoundLibrary.new()
	var dir := DirAccess.open("res://assets/sfx")
	var sounds := {}
	for f in dir.get_files():
		if f.ends_with(".wav"):
			sounds[StringName(f.get_basename())] = load("res://assets/sfx/" + f)
	lib.sounds = sounds
	save(lib, "res://resources/audio/sound_library.tres", force)
