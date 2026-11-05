extends Control
## Renders the first-person view inside every canopy scene of every region
## with the real renderer and fails if any frame comes out blank or flat.
## Also writes a contact sheet to look at.
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 720x1280 \
##     res://tools/fpv_check.tscn -- --no-boot [--out=/tmp/fpv.png] [--map=amazon] [--full=/tmp/dir] [--back=3: stand 3 rows before the zone] [--fast: 2 scenes a region]

const THUMB := Vector2i(180, 320)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var out := ""
	var only := ""
	var full := ""
	var back := 0
	var fast := OS.get_cmdline_user_args().has("--fast")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--back="):
			back = int(a.substr(7))
		if a.begins_with("--full="):
			full = a.substr(7)
		if a.begins_with("--out="):
			out = a.substr(6)
		if a.begins_with("--map="):
			only = a.substr(6)
	Save.path = "user://fpv_check_save.json"
	Save.wipe()
	Save.data.seen_intro = Content.playable_maps()
	var shots: Array[Image] = []
	var labels: Array[String] = []
	var bad: Array[String] = []
	var maps: Array = Content.playable_maps() if only == "" else [only]
	for map_id in maps:
		var map := Content.map(String(map_id))
		var scenes: Array = map.get("fpv_scenes", [])
		for si in (mini(2, scenes.size()) if fast else scenes.size()):
			var want := String(scenes[si].id)
			var found := _find(map, want)
			if found.is_empty():
				bad.append("%s/%s: no level uses it" % [map_id, want])
				continue
			var gs: Control = load("res://scripts/ui/game_screen.gd").new()
			gs.setup({"mode": "journey", "map": map_id, "stage": int(found.stage), "seed": int(found.seed), "animal": "poison_dart_frog"})
			gs.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(gs)
			gs.set_process(false)
			await get_tree().process_frame
			var zone: Vector2i = found.zone
			gs.sim.row = zone.x - back
			gs.sim.max_row = gs.sim.row
			gs.sim.x = 4.5
			gs.set_view("fpv", false)
			# settle the light without drawing every step, then draw a few frames
			for i in 30:
				gs._update_views(1.0 / 30.0)
			for i in 3:
				await get_tree().process_frame
				gs._update_views(1.0 / 30.0)
			await RenderingServer.frame_post_draw
			var img: Image = gs.wv3.vp3.get_texture().get_image()
			var stats := _stats(img)
			var ok: bool = stats.x > 0.03 and stats.x < 0.97 and stats.y > 0.035
			var lane_scene := String(gs.world.lane(zone.x).scene)
			if lane_scene != want:
				ok = false
			print("%-16s %-26s stage %d zone %s  mean %.2f  contrast %.3f  %s" % [map_id, want, int(found.stage) + 1, zone, stats.x, stats.y, "ok" if ok else "BAD"])
			if not ok:
				bad.append("%s/%s" % [map_id, want])
			if full != "":
				img.save_png("%s/%s_%s.png" % [full, map_id, want])
			img.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_BILINEAR)
			shots.append(img)
			labels.append(String(scenes[si].name))
			gs.queue_free()
			await get_tree().process_frame
	if out != "":
		_sheet(shots, out)
	print("fpv check: %d scenes, %d bad %s" % [shots.size(), bad.size(), str(bad)])
	Save.wipe()
	get_tree().quit(1 if not bad.is_empty() or shots.is_empty() else 0)


## The first Journey level (and its seed) whose first canopy zone uses `scene`.
func _find(map: Dictionary, scene: String) -> Dictionary:
	for st in map.get("stages", []).size():
		var seed := absi(hash([String(map.id), st, "journey"])) % 1000000
		var gen := LaneGenerator.new()
		gen.setup(map, "journey", st, seed)
		for z in gen.cover.size():
			if gen.cover_scenes[z] == scene:
				return {"stage": st, "seed": seed, "zone": gen.cover[z]}
	return {}


## x: mean luminance, y: its standard deviation (detail / contrast).
func _stats(img: Image) -> Vector2:
	var small := img.duplicate() as Image
	small.resize(64, 112, Image.INTERPOLATE_BILINEAR)
	var sum := 0.0
	var sq := 0.0
	var n := 0
	for y in small.get_height():
		for x in small.get_width():
			var l := small.get_pixel(x, y).get_luminance()
			sum += l
			sq += l * l
			n += 1
	var mean := sum / n
	return Vector2(mean, sqrt(maxf(0.0, sq / n - mean * mean)))


func _sheet(shots: Array[Image], path: String) -> void:
	var cols := 8
	var rows := int(ceil(float(shots.size()) / cols))
	var sheet := Image.create(cols * THUMB.x, rows * THUMB.y, false, Image.FORMAT_RGB8)
	for i in shots.size():
		var im := shots[i]
		im.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(im, Rect2i(Vector2i.ZERO, THUMB), Vector2i((i % cols) * THUMB.x, (i / cols) * THUMB.y))
	sheet.save_png(path)
	print("sheet ", path)
