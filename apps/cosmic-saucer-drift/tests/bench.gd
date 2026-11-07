extends Node
## Performance probe: runs a race for a while at a graphics tier and prints
## CPU time per frame (process + physics), the game-logic profile, and the
## renderer's draw calls / primitives per frame. Needs a display (xvfb-run
## + opengl3); the GPU numbers come from the software renderer, so compare
## them between runs rather than reading them as phone frame times.
## xvfb-run godot --path . res://tests/bench.tscn --rendering-driver opengl3 -- --quality=medium --track=io --frames=600

func _ready() -> void:
	Racer.profiling = true
	Save.disabled = true
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var q: String = args.get("quality", "medium")
	Save.data.settings.quality = q
	var frames := int(args.get("frames", "600"))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var req := Game.quick_request(args.get("track", "io"), 0, 2)
	req.autopilot = true
	req.laps = 3
	Game.request = req
	var race: Race = load("res://scenes/race.tscn").instantiate()
	add_child(race)
	while not race.racing:
		await get_tree().process_frame
	for i in 60:
		await get_tree().process_frame
	for k in race.prof:
		race.prof[k] = 0
	for k in Racer.prof:
		Racer.prof[k] = 0
	var t0 := Time.get_ticks_usec()
	var pt0 := Performance.get_monitor(Performance.TIME_PROCESS)
	var ph0 := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	var proc := 0.0
	var phys := 0.0
	var worst := 0.0
	var spikes := 0
	var last := Time.get_ticks_usec()
	var dc := 0.0
	var prim := 0.0
	var objs := 0.0
	var n := 0
	for i in frames:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var ft := float(now - last) / 1000.0
		last = now
		worst = maxf(worst, ft)
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		dc += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		objs += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
		n += 1
	var wall := float(Time.get_ticks_usec() - t0) / 1000.0 / float(n)
	# How long a power-up takes to appear: pooled take vs building the model.
	var tb := Time.get_ticks_usec()
	var built := ItemModels.rocket(Color.RED)
	var build_us := Time.get_ticks_usec() - tb
	built.free()
	tb = Time.get_ticks_usec()
	var taken := race.items._take("rocket")
	var take_us := Time.get_ticks_usec() - tb
	race.items._give("rocket", taken)
	print("      rocket: build %d us, pooled take %d us; worst frame %.1f ms" % [build_us, take_us, worst])
	var ticks: int = maxi(race.prof.ticks, 1)
	print("BENCH tier=%s track=%s frames=%d wall=%.1fms/frame process=%.2fms physics=%.2fms draw_calls=%.0f prims=%.0f objects=%.0f" % [
		q, req.track, n, wall, proc / n * 1000.0, phys / n * 1000.0, dc / n, prim / n, objs / n])
	var pr: Dictionary = race.prof
	print("      logic us/tick: racers=%.0f pairs=%.0f pickups=%.0f items=%.0f hazards=%.0f rest=%.0f (ticks %d)" % [
		pr.racers / ticks, pr.pairs / ticks, pr.pickups / ticks, pr.items / ticks, pr.hazards / ticks, pr.rest / ticks, ticks])
	var rp: Dictionary = Racer.prof
	print("      racer us/tick: drive=%.0f ground=%.0f steer=%.0f integrate=%.0f progress=%.0f visuals=%.0f" % [
		rp.drive / ticks, rp.ground / ticks, rp.steer / ticks, rp.integrate / ticks, rp.progress / ticks, rp.visuals / ticks])
	print("      nodes=%d orphan=%d mem=%.1fMB" % [Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])
	get_tree().quit()
