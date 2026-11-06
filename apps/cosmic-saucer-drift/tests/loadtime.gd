extends Node
## Load-time probe: builds a race on several tracks and prints how long each
## build stage took (ms), plus the time to build the main menu. CPU only, so
## it runs headless; shader compiles are not included.
## godot --headless --path . res://tests/loadtime.tscn -- --quality=high --tracks=io,saturn_rings,proxima_station

func _ready() -> void:
	Save.disabled = true
	Save.data = Save.defaults()
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Save.data.settings.quality = args.get("quality", "high")
	var tracks: PackedStringArray = String(args.get("tracks", "io,saturn_rings,proxima_station,trappist1h")).split(",")
	var rounds := int(args.get("rounds", "2"))
	await get_tree().process_frame
	# Main menu (what the player sees first).
	var t0 := Time.get_ticks_usec()
	var menu: Node = load("res://scenes/main.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	print("menu build: %.0f ms" % (float(Time.get_ticks_usec() - t0) / 1000.0))
	menu.queue_free()
	await get_tree().process_frame
	var totals := {}
	for round in rounds:
		for t in tracks:
			var req := Game.quick_request(t, 0, 2)
			req.autopilot = true
			req.fast = true
			Game.request = req
			var ta := Time.get_ticks_usec()
			var race: Race = load("res://scenes/race.tscn").instantiate()
			add_child(race)
			await get_tree().process_frame
			var total := float(Time.get_ticks_usec() - ta) / 1000.0
			var parts := []
			if round == 0 and t == tracks[0]:
				print("   per racer (ms): ", Racer.build_ms)
			for k in race.load_ms:
				parts.append("%s=%.0f" % [k, race.load_ms[k]])
				totals[k] = float(totals.get(k, 0.0)) + float(race.load_ms[k])
			print("%s%-16s total=%5.0f ms  %s" % ["   " if round > 0 else "", t, total, " ".join(parts)])
			race.queue_free()
			await get_tree().process_frame
			await get_tree().process_frame
	var n := float(rounds * tracks.size())
	var avg := []
	for k in totals:
		avg.append("%s=%.0f" % [k, totals[k] / n])
	print("average per stage (ms): ", " ".join(avg))
	get_tree().quit()
