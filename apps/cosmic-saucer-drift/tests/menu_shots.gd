extends Node
## Screenshots of every menu screen (xvfb-run + opengl3).

func _ready() -> void:
	Save.disabled = true
	Save.data.credits = 4200
	Save.data.tutorial_done = true
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else "docs/screenshots"
	var screens: PackedStringArray = args[1].split(",") if args.size() > 1 else PackedStringArray(["garage", "quick", "howto", "cups"])
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var menu: Control = load("res://scenes/main.tscn").instantiate()
	add_child(menu)
	for s in screens:
		if s == "garage":
			menu._sel["garage_saucer"] = "dragon"
		menu.show_screen(s)
		for i in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/menu_%s.png" % [out, s])
		print("saved ", s)
	get_tree().quit()
