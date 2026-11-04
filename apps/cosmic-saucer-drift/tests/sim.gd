extends Node
## Headless race simulator: AI-only races on each track/variant. Reports
## whether everyone finishes, lap pace, rescues (falls), stuck racers,
## hits and items, and logic cost per tick.
## godot --headless --path . res://tests/sim.tscn --fixed-fps 60 -- --laps=1 --tracks=asteroid_belt --variants=0,1,2

var failures := 0


func _ready() -> void:
	Save.disabled = true
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var laps := int(args.get("laps", "1"))
	var tracks: PackedStringArray = args.get("tracks", ",".join(Catalog.TRACK_IDS)).split(",")
	var variants: PackedStringArray = args.get("variants", "0").split(",")
	var cls := int(args.get("class", "2"))
	for t in tracks:
		for v in variants:
			await _run(t, int(v), laps, cls)
	print("SIM DONE failures=%d" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _run(track: String, variant: int, laps: int, cls: int) -> void:
	var req := Game.quick_request(track, variant, cls)
	req.autopilot = true
	req.fast = true
	req.laps = laps
	Game.request = req
	var race: Race = load("res://scenes/race.tscn").instantiate()
	add_child(race)
	var rescues := {}
	var cnt := {"hits": 0, "items": 0, "rolls": 0, "near": 0, "tricks": 0, "slips": 0, "emergency": 0, "purple": 0}
	for r in race.racers:
		rescues[r.idx] = 0
		r.event.connect(func(kind: String, _d: Dictionary) -> void:
			if kind == "respawn":
				rescues[r.idx] += 1
				if OS.get_cmdline_user_args().has("--verbose"):
					print("    rescue %s reason=%s from=%s to idx %d" % [r.display_name, _d.reason, _d.from, r.track_idx])
			elif kind == "hit":
				cnt.hits += 1
			elif kind == "item_used":
				cnt.items += 1
			elif kind == "item_roll":
				cnt.rolls += 1
			elif kind == "near_miss":
				cnt.near += 1
			elif kind == "trick":
				cnt.tricks += 1
			elif kind == "slipstream":
				cnt.slips += 1
			elif kind == "emergency":
				cnt.emergency += 1
			elif kind == "drift_boost" and _d.tier == 3:
				cnt.purple += 1)
	var state := {"finished": false}
	race.race_finished.connect(func(_res: Array) -> void: state.finished = true)
	var limit := int((race.td.main.length * laps / 22.0 + 20.0) * 60.0)
	var frames := 0
	var last_dist := {}
	var stuck := {}
	var t0 := Time.get_ticks_usec()
	while not state.finished and frames < limit:
		await get_tree().physics_frame
		frames += 1
		if frames % 300 == 0:
			for r in race.racers:
				var d: float = last_dist.get(r.idx, -99999.0)
				if race.racing and not r.finished and r.race_dist - d < 20.0:
					stuck[r.idx] = int(stuck.get(r.idx, 0)) + 1
				last_dist[r.idx] = r.race_dist
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / maxf(frames, 1)
	var fin := 0
	var best := INF
	var worst := 0.0
	for r in race.racers:
		if r.finished:
			fin += 1
			best = minf(best, r.finish_time)
			worst = maxf(worst, r.finish_time)
	var total_rescue := 0
	for k in rescues:
		total_rescue += rescues[k]
	var stuck_n := 0
	for k in stuck:
		if stuck[k] >= 2:
			stuck_n += 1
	var ok := fin == race.racers.size() and stuck_n == 0
	if not ok:
		failures += 1
	print("%s %-16s v%d len=%5.0fm laps=%d finished=%d/%d best=%6.1fs (%.1f m/s) worst=%6.1fs rescues=%d stuck=%d tick=%.2fms\n      %s" % [
		"OK  " if ok else "FAIL", track, variant, race.td.main.length, laps, fin, race.racers.size(), best,
		race.td.main.length * laps / maxf(best, 0.01), worst, total_rescue, stuck_n, ms, str(cnt)])
	if not ok:
		for r in race.racers:
			if not r.finished:
				print("    unfinished %s dist=%.0f idx=%d pos=%s rescues=%d" % [r.display_name, r.race_dist, r.track_idx, r.global_position, rescues[r.idx]])
	race.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
