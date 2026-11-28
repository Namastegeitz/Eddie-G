extends Control
## Performance benchmark: the same scripted run every time, measured.
##
##   xvfb-run -a -s "-screen 0 800x1400x24" godot --path . --rendering-driver opengl3 \
##     --resolution 720x1280 --fixed-fps 60 res://tools/benchmark.tscn -- --no-boot \
##     [--out=build/bench.json] [--graphics=high] [--frames=480] [--map=amazon] [--stage=4] [--views=bird,fpv]
##
## It starts the game (home screen), then plays a fixed Journey level with the
## bot in the bird's-eye view, then the same in first person, and records:
##   startup_ms         engine start until the home screen has drawn twice
##   <view>.avg_ms      average frame time (wall clock)
##   <view>.low1_fps    "1% low": the frame rate of the slowest 1% of frames
##   <view>.worst_ms    the single worst frame (a spike)
##   <view>.cpu_ms      average time the game's own code took per frame
##   <view>.draw_calls / objects / primitives   what the GPU was asked to draw
##   mem_static_mb      peak memory held by the engine (CPU side)
##   vmem_mb            video memory in use at the end
## Draw calls, objects and primitives don't depend on how fast the machine
## is, so tools/bench_check.py gates on them; the timings are for comparing
## runs on the same machine and, above all, on real phones.

var out := ""
var frames := 480
var map_id := "amazon"
var stage := 4
var graphics := ""
var views := ["bird", "fpv"]
var res := {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--frames="):
			frames = maxi(60, int(a.substr(9)))
		elif a.begins_with("--map="):
			map_id = a.substr(6)
		elif a.begins_with("--stage="):
			stage = int(a.substr(8))
		elif a.begins_with("--graphics="):
			graphics = a.substr(11)
		elif a.begins_with("--views="):
			views = Array(a.substr(8).split(","))
	Save.path = "user://bench_save.json"
	Save.wipe()
	Save.load_game()
	Save.data.tutorial_done = true
	Save.data.seen_intro = Content.playable_maps()
	if graphics != "":
		Save.set_setting("graphics", graphics)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	Game.boot()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	res.startup_ms = Time.get_ticks_msec()
	res.graphics = Gfx.level()
	res.window = "%dx%d" % [get_viewport_rect().size.x, get_viewport_rect().size.y]
	res.engine = Engine.get_version_info().string
	res.map = map_id
	res.stage = stage + 1
	Game.start_run({"mode": "journey", "map": map_id, "stage": stage, "seed": 777, "animal": "poison_dart_frog", "autoplay": true})
	await get_tree().process_frame
	var gs = Game.current
	gs.started = true
	gs.blocking = false
	if "bird" in views:
		res.bird = await _measure()
	if "fpv" in views:
		gs.set_view("fpv", false)
		res.fpv = await _measure()
	res.mem_static_mb = snappedf(Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0, 0.1)
	res.vmem_mb = snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1)
	res.rows_reached = gs.sim.max_row
	var text := JSON.stringify(res, "  ")
	print("BENCH " + JSON.stringify(res))
	if out != "":
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(text)
		f.close()
	Save.wipe()
	get_tree().quit()


## Warm up for a second, then measure `frames` frames.
func _measure() -> Dictionary:
	for i in 60:
		await get_tree().process_frame
	var times: Array[float] = []
	var cpu := 0.0
	var dc := 0.0
	var dc_max := 0.0
	var obj := 0.0
	var prim := 0.0
	var last := Time.get_ticks_usec()
	for i in frames:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		cpu += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		var d := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		dc += d
		dc_max = maxf(dc_max, d)
		obj += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var n := float(frames)
	var sorted := times.duplicate()
	sorted.sort()
	var total := 0.0
	for t in times:
		total += t
	var slow := sorted.slice(int(n * 0.99))
	var slow_avg := 0.0
	for t in slow:
		slow_avg += t
	slow_avg /= maxf(1.0, slow.size())
	return {
		"avg_ms": snappedf(total / n, 0.01),
		"low1_fps": snappedf(1000.0 / maxf(0.001, slow_avg), 0.1),
		"worst_ms": snappedf(sorted[sorted.size() - 1], 0.01),
		"cpu_ms": snappedf(cpu / n, 0.01),
		"draw_calls": snappedf(dc / n, 0.1),
		"draw_calls_max": dc_max,
		"objects": snappedf(obj / n, 0.1),
		"primitives": int(prim / n),
	}
