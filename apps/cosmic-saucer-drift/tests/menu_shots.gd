extends Node
## Screenshots of every menu screen (xvfb-run + opengl3).

func _ready() -> void:
	Save.disabled = true
	Save.data.credits = 4200
	Save.data.tutorial_done = true
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else "docs/screenshots"
	var screens: PackedStringArray = args[1].split(",") if args.size() > 1 else PackedStringArray(["garage", "quick", "howto", "cups"])
	var portrait := args.size() > 2 and args[2] == "portrait"
	if "demo" in args:
		# Some Super Upgrades progress so the screens have something to show.
		for c in ["sail", "phantom", "dragon", "dyson"]:
			Save.unlock_saucer(c)
		Upgrades.add_stardust(2600)
		Upgrades.st().tiers["sail"] = 3
		Upgrades.st().perks.append("solar_wind")
		Upgrades.st().tiers["phantom"] = 2
		Upgrades.st().tiers["dragon"] = 1
		for m in ["fusion_heart", "corona_veil", "helio_thrusters", "null_reactor", "ion_sails"]:
			Upgrades.st().mods.append(m)
		Upgrades.fit("sail", "core", "fusion_heart")
		Upgrades.fit("sail", "field", "corona_veil")
		Upgrades.fit("sail", "drive", "helio_thrusters")
		Upgrades.fit("dragon", "core", "null_reactor")
		Upgrades.set_overclock("dragon", 2)
		Save.data.garage.saucer = "sail"
	DisplayServer.window_set_size(Vector2i(720, 1280) if portrait else Vector2i(1280, 720))
	await get_tree().process_frame
	Game.fit_orientation()
	var menu: Control = load("res://scenes/main.tscn").instantiate()
	add_child(menu)
	for s in screens:
		if s == "garage":
			menu._sel["garage_saucer"] = "dragon"
			if "demo" in args:
				menu._sel["garage_saucer"] = "sail"
				menu._sel["garage_tab"] = "mods"
			for a in args:
				if a.begins_with("craft="):   # e.g. craft=aurora (an HD craft)
					menu._sel["garage_saucer"] = a.substr(6)
		menu.show_screen(s)
		for i in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/menu_%s%s.png" % [out, s, "_portrait" if portrait else ""])
		print("saved ", s)
	get_tree().quit()
