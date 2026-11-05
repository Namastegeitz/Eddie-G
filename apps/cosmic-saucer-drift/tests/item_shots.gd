extends Node
## Fires each power-up in a live race and screenshots it (needs a display:
## xvfb-run + opengl3). Checks the power-up models and effects.
## xvfb-run godot --path . res://tests/item_shots.tscn --rendering-driver opengl3 -- --out=/tmp/items [--quality=high] [--only=rocket,laser]

const PLAN := [
	# item, frames after use for the shot, look back?
	["rocket", 4, false], ["laser", 3, false], ["emp", 6, false], ["nitro", 8, false],
	["shield", 8, false], ["mine", 30, true], ["tractor", 8, false], ["comet", 40, false],
]


func _ready() -> void:
	Save.disabled = true
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var out: String = args.get("out", "/tmp/items")
	DirAccess.make_dir_recursive_absolute(out)
	Save.data.settings.quality = args.get("quality", "high")
	var only: PackedStringArray = String(args.get("only", "")).split(",", false)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var req := Game.quick_request(args.get("track", "saturn_rings"), 0, 2)
	req.autopilot = true
	req.laps = 3
	Game.request = req
	var race: Race = load("res://scenes/race.tscn").instantiate()
	add_child(race)
	while not race.racing:
		await get_tree().process_frame
	for i in 150:
		await get_tree().process_frame
	var me: Racer = race.racers[0]
	for step in PLAN:
		var it: String = step[0]
		if not only.is_empty() and not (it in only):
			continue
		# Make sure there's someone to hit just ahead for the aimed items.
		var ahead: Racer = race.racers[1]
		if it in ["rocket", "laser", "tractor", "emp"]:
			ahead.global_position = me.global_position + me.heading * (14.0 if it != "emp" else 7.0) + me.heading.cross(me.up).normalized() * 0.0
			ahead.race_dist = me.race_dist + 14.0
			ahead.reset_physics_interpolation()
			ahead.invuln_time = 0.0
			ahead.shield_time = 0.0
			ahead.item = ""
		me.item = it
		me.item_uses = 1
		me.item_roll = 0.0
		me.in_look_back = step[2]
		# Software rendering is slow; run game time slowly so short effects
		# (a 0.3 s laser) are still on screen when the shot is taken.
		Engine.time_scale = 0.06
		race.items.use_item(me)
		if OS.get_cmdline_user_args().has("--debug"):
			for b in race.items.beams:
				print("beam ", b.kind, " vis=", b.node.is_visible_in_tree(), " xf=", b.node.global_transform, " kids=", b.node.get_child_count())
		if it == "shield":
			# Show the held-shield badge too: give another shield to hold.
			race.racers[2].item = "shield"
		for i in int(step[1]):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if OS.get_cmdline_user_args().has("--debug"):
			var cam: RaceCamera = race.cams[0]
			print("cam=", cam.global_position, " tp=", cam._tp, " me=", me.global_position, " d=", cam.global_position.distance_to(me.global_position),
				" vis=", me.model.visible, " modelvis=", me.model.is_visible_in_tree(), " target_is_me=", cam.target == me, " fov=", cam.fov, " dip=", cam._dip, " stretch=", cam._stretch)
		get_viewport().get_texture().get_image().save_png("%s/item_%s.png" % [out, it])
		print("saved ", it)
		Engine.time_scale = 1.0
		me.in_look_back = false
		for i in 70:
			await get_tree().process_frame
	get_tree().quit()
