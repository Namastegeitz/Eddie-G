extends Node
## Records gameplay frames for the store trailer. Run with a fixed frame rate
## so motion is smooth however slowly this machine renders:
##   xvfb-run -a -s "-screen 0 2000x1200x24" godot --path . --resolution 1920x1080 --fixed-fps 30 \
##     res://tests/trailer.tscn --rendering-driver opengl3 -- --out=/tmp/frames [--seconds=6]
## Writes frame_00000.png ... across all clips; ffmpeg turns them into the video.

const CLIPS := [
	{"track": "saturn_rings", "craft": "", "cockpit": false},
	{"track": "mars", "craft": "aurora", "cockpit": false},
	{"track": "io", "craft": "aurora", "cockpit": true},
	{"track": "hd189733b", "craft": "", "cockpit": false},
	{"track": "kepler16b", "craft": "", "cockpit": false},
	{"track": "trappist1b", "craft": "", "cockpit": false},
]


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var out := String(args.get("out", "user://trailer"))
	var per_clip := int(float(args.get("seconds", "6")) * 30.0)   # --fixed-fps 30
	DirAccess.make_dir_recursive_absolute(out)
	Save.disabled = true
	Save.data.settings.quality = String(args.get("quality", "high"))
	var n := 0
	for clip: Dictionary in CLIPS:
		Save.data.garage.saucer = "classic"
		if clip.craft != "":
			Save.unlock_saucer(clip.craft)
			Save.data.garage.saucer = clip.craft
		var req := Game.quick_request(clip.track, 0, 2)
		req.autopilot = true
		req.laps = 3
		Game.request = req
		var race: Race = load("res://scenes/race.tscn").instantiate()
		add_child(race)
		while not race.loaded:
			await get_tree().process_frame
		if clip.cockpit:
			race._set_cockpit(race.racers[0], true)
		# Skip the countdown and the first seconds of jostling.
		for f in 210:
			await get_tree().process_frame
		for f in per_clip:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/frame_%05d.png" % [out, n])
			n += 1
		race.queue_free()
		await get_tree().process_frame
		print("clip ", clip.track, " done, frames ", n)
	print("TRAILER FRAMES ", n)
	get_tree().quit()
