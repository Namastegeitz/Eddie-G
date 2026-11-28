extends TestBase
## Screenshots of the key screens for visual regression tests and
## before/after comparisons (upgrade step 6 and 9). Needs a display (xvfb).
##   xvfb-run -a godot --path . --resolution 1280x720 res://tools/visual/visual_shots.tscn -- --out=DIR
## Args: --out=DIR  --shots=menu,settings_top,settings_privacy,kitchen
##       --quality=medium  --text=1.0 (text size)

var out := ""
var shots: PackedStringArray = ["menu", "settings_top", "settings_privacy", "kitchen"]
var quality := "medium"
var text_size := "1.0"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--shots="):
			shots = a.substr(8).split(",")
		elif a.begins_with("--quality="):
			quality = a.substr(10)
		elif a.begins_with("--text="):
			text_size = a.substr(7)
	DirAccess.make_dir_recursive_absolute(out)
	GameManager.guides_enabled = false
	GameManager.auto_quality_enabled = false
	SaveSystem.save_path = "user://visual_save.json"
	SaveSystem.data = SaveSystem.default_data()
	SaveSystem.set_setting("quality", quality)
	SaveSystem.set_setting("text_size", text_size)
	SaveSystem.set_setting("crash_reports", "off")
	for s in shots:
		await call("_shot_" + s)
	get_tree().quit()


func _save(shot: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(out.path_join(shot + ".png"))
	print("VISUAL ", shot, " ", img.get_width(), "x", img.get_height())


func _scene(path: String) -> Node:
	var n := (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(n)
	await frames(20)
	return n


func _shot_menu() -> void:
	var n: Node = await _scene("res://scenes/ui/main_menu.tscn")
	await _save("menu")
	n.queue_free()
	await frames(2)


func _shot_settings_top() -> void:
	var n: Node = await _scene("res://scenes/ui/settings_menu.tscn")
	await _save("settings_top")
	n.queue_free()
	await frames(2)


func _shot_settings_privacy() -> void:
	var n: Node = await _scene("res://scenes/ui/settings_menu.tscn")
	var sc := n.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
	sc.scroll_vertical = 100000
	await frames(4)
	await _save("settings_privacy")
	n.queue_free()
	await frames(2)


func _shot_kitchen() -> void:
	var lv := await load_level(&"kitchen", &"cockroach")
	face(lv, 0.4)
	await frames(45)
	lv.player.invuln = 0.0  # (invulnerability makes the bug blink)
	lv.player.visual.visible = true
	await _save("kitchen")
	await unload(lv)
