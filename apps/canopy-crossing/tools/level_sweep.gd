extends Node
## Solves every Journey level with the path-finding bot using the free
## Poison Dart Frog and prints effort per level and any it can't beat.
##   godot --headless --path . res://tools/level_sweep.tscn -- --no-boot [--map=amazon]

func _ready() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			only = a.substr(6)
	var fails := []
	var total := 0
	var t_all := Time.get_ticks_msec()
	for id in Content.playable_maps():
		if only != "" and id != only:
			continue
		var m := Content.map(id)
		var line := "%-16s" % id
		for li in m.stages.size():
			var w := World.new()
			w.setup(m, "journey", li, absi(hash([id, li, "journey"])) % 1000000)
			var sim := RunSim.new()
			sim.setup(w, Content.animal("poison_dart_frog"))
			var bot := PathBot.new()
			bot.max_nodes = 40000
			var t0 := Time.get_ticks_msec()
			var ok := not bot.plan(sim, w.goal_row).is_empty()
			total += 1
			line += " %d:%s%d/%.1fs" % [li + 1, "" if ok else "FAIL@", bot.nodes_expanded if ok else bot.best_row, (Time.get_ticks_msec() - t0) / 1000.0]
			if not ok:
				fails.append("%s/%d (stuck at row %d of %d)" % [id, li + 1, bot.best_row, w.goal_row])
		print(line)
	print("levels %d, failed %d, %.0fs: %s" % [total, fails.size(), (Time.get_ticks_msec() - t_all) / 1000.0, str(fails)])
	get_tree().quit(1 if not fails.is_empty() else 0)
