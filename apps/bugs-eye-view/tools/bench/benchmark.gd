extends TestBase
## Repeatable performance benchmark (UPGRADE step 1 / step 9).
## Loads each room with the cockroach, walks it in a slow circle for a fixed
## number of frames with every person, pet and the vacuum running, and
## records the wall time of each frame.
##   godot --headless --path . res://tools/bench/benchmark.tscn --fixed-fps 60 -- --out=/tmp/bench.json
## Headless = CPU cost only (game logic, physics, AI). Run it without
## --headless (e.g. under xvfb) to include rendering.
## Args: --out=FILE  --frames=N (default 600)  --rooms=kitchen,backyard
##       --quality=low|medium|high|ultra (default medium)

var out := ""
var n_frames := 600
var rooms: PackedStringArray = ["kitchen", "living_room", "backyard"]
var quality := "medium"
var _times: PackedFloat64Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--frames="):
			n_frames = int(a.substr(9))
		elif a.begins_with("--rooms="):
			rooms = a.substr(8).split(",")
		elif a.begins_with("--quality="):
			quality = a.substr(10)
	GameManager.auto_quality_enabled = false
	GameManager.guides_enabled = false  # the how-to card pauses the game
	SaveSystem.save_path = "user://bench_save.json"
	SaveSystem.data = SaveSystem.default_data()
	SaveSystem.set_setting("quality", quality)
	GameManager.apply_quality()
	var result := {"godot": Engine.get_version_info().string, "headless": DisplayServer.get_name() == "headless",
		"quality": quality, "frames": n_frames, "rooms": {}}
	for room in rooms:
		result["rooms"][room] = await _bench_room(StringName(room))
	var line := JSON.stringify(result)
	print("BENCH ", line)
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(line)
	get_tree().quit()


func _bench_room(room: StringName) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var lvl := await load_level(room, &"cockroach")
	var load_ms := (Time.get_ticks_usec() - t0) / 1000.0
	await frames(30)  # settle: first-time shader and physics setup
	assert(not get_tree().paused)
	_times.clear()
	key(KEY_W, true)
	var mem_peak := 0.0
	var last := Time.get_ticks_usec()
	for i in n_frames:
		if is_instance_valid(lvl.player):
			lvl.player.invuln = 1e9
			lvl.player.health = BugBase.MAX_HEALTH
		face(lvl, i * 0.012)
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		_times.append((now - last) / 1000.0)
		last = now
		mem_peak = maxf(mem_peak, Performance.get_monitor(Performance.MEMORY_STATIC))
	key(KEY_W, false)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	await unload(lvl)
	var sorted := _times.duplicate()
	sorted.sort()
	var total := 0.0
	for t in sorted:
		total += t
	var avg := total / maxf(sorted.size(), 1)
	var p99: float = sorted[int(sorted.size() * 0.99)] if sorted.size() > 0 else 0.0
	var p50: float = sorted[int(sorted.size() * 0.5)] if sorted.size() > 0 else 0.0
	return {
		"load_ms": snappedf(load_ms, 0.1),
		"frame_ms_avg": snappedf(avg, 0.001), "frame_ms_median": snappedf(p50, 0.001),
		"frame_ms_p99": snappedf(p99, 0.001), "frame_ms_worst": snappedf(sorted[-1] if sorted.size() > 0 else 0.0, 0.001),
		"fps_avg": snappedf(1000.0 / maxf(avg, 0.001), 0.1), "fps_1pct_low": snappedf(1000.0 / maxf(p99, 0.001), 0.1),
		"spikes_over_2x_budget": _count_over(sorted, 33.3),
		"memory_static_mb": snappedf(mem_peak / 1048576.0, 0.1), "objects": objects, "draw_calls": draw_calls,
	}


func _count_over(times: PackedFloat64Array, limit: float) -> int:
	var n := 0
	for t in times:
		if t > limit:
			n += 1
	return n
