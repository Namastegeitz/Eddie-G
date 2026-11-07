class_name Race
extends Node3D
## Runs one race: builds the world from Game.request, spawns racers, runs
## the countdown, ticks everything at a fixed rate, keeps positions and laps,
## handles bumps and slipstream, records ghosts and shows pause/results.

signal race_finished(results: Array)

var req: Dictionary
var tuning: Tuning
var td: TrackData
var racers: Array[Racer] = []
var humans: Array[Racer] = []
var pickups: Pickups
var items: Items
var hazards: Hazards
var racing := false
var done := false
var countdown_left := 4.0
var time := 0.0
var finish_order: Array[Racer] = []
var results: Array = []
var mod_speed := 1.0
var mod_gravity := 1.0
var mod_drain := 1.0
var mod_pod := 1.0
var mod_grip := 1.0
var autopilot := false

var cams: Array[RaceCamera] = []
var huds: Array[Hud] = []
var touch: TouchControls
var hints: DesktopHints
var ui_layer: CanvasLayer
var _pause_panel: Control
var _results_panel: Control
var _last_count := -1
var _all_done_t := -1.0
var _lap_start := {}
var _led := {}
var _was_short := {}
var ghost_racer: Racer
var _ghost_play := PackedFloat32Array()
var _ghost_rec := PackedFloat32Array()
var _ghost_t := 0.0
var _audio: RaceAudio
var _env: Environment
var _sun: DirectionalLight3D
## Stellar wind: blows away from this world's star, flat along the ground
## (the Photon Spinnaker tacks against it).
var stellar_wind := Vector3.RIGHT
var _sky_mat: ShaderMaterial
var fx: RaceFx
var _slowmo_until := 0
var _decor: Node3D
var _slow_t := 0.0
var _fps_lbl: Label

var prof := {"racers": 0, "pairs": 0, "pickups": 0, "items": 0, "hazards": 0, "rest": 0, "ticks": 0}
## Milliseconds each build stage took (track data, world, racers, systems,
## views, warm-up): tests/loadtime prints them.
var load_ms := {}
var _load_t := 0
## True once every part of the race exists. The build runs in stages over
## several frames behind the loading screen, so nothing ticks before this.
var loaded := false
signal race_loaded
var _fast := false
## Dynamic resolution: the 3D render scale eases down when frames run long
## and back up when they're comfortable, before any tier is dropped.
var res_scale := 1.0
var _ft_avg := 1.0 / 60.0
var _res_t := 0.0
const RES_MIN := 0.6
const GHOST_HZ := 15.0
const GHOST_STRIDE := 8


func _ready() -> void:
	req = Game.request if not Game.request.is_empty() else Game.quick_request("asteroid_belt", 0, 1)
	tuning = Game.tuning
	autopilot = req.get("autopilot", false)
	var mods: Dictionary = req.get("mods", {})
	mod_speed = mods.get("speed", 1.0)
	mod_gravity = mods.get("gravity", 1.0)
	mod_drain = mods.get("drain", 1.0)
	mod_pod = mods.get("pod", 1.0)
	mod_grip = mods.get("grip", 1.0)
	# Physics interpolation (project setting) is only for things moved by
	# the physics tick: racers, items and hazards turn it on for themselves.
	# Everything else here (camera, effects, scenery, HUD) moves per frame.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_fast = req.get("fast", false)
	_build()


## Lets a frame render between build stages (not in fast/test mode).
func _yield(frac: float, what: String) -> void:
	if _fast:
		return
	Game.loading_progress(frac, what)
	await get_tree().process_frame


func _build() -> void:
	_load_t = Time.get_ticks_usec()
	td = TrackData.make(req.track, req.variant)
	mod_gravity *= float(td.def.get("gravity", 1.0))
	if req.has("laps"):
		td.laps = req.laps
	_stage("track_data")
	await _yield(0.08, "Charting " + td.name)
	await _build_world()
	_stage("world")
	fx = RaceFx.new()
	fx.name = "Fx"
	add_child(fx)
	await _yield(0.55, "Rolling out the grid")
	await _spawn()
	_stage("racers")
	await _yield(0.8, "Arming the crates")
	pickups = Pickups.new()
	pickups.name = "Pickups"
	add_child(pickups)
	pickups.setup(self)
	items = Items.new()
	items.name = "Items"
	items.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(items)
	items.setup(self)
	items.only_item = (req.get("mods", {}) as Dictionary).get("only_item", "")
	if req.get("free_item", false):
		for h in humans:
			if h.item == "":
				h.item = items.roll(h)
	hazards = Hazards.new()
	hazards.name = "Hazards"
	hazards.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(hazards)
	hazards.setup(self)
	hazards.reset_physics_interpolation()
	_stage("systems")
	await _yield(0.9, "Lighting the track")
	_setup_views()
	_setup_cockpits()
	apply_quality()
	_stage("views")
	if not cams.is_empty() and not _fast:
		# Compile every effect shader during the countdown, not mid-race.
		items.warm_up(cams[0])
		fx.warm_up(cams[0])
	_audio = RaceAudio.new()
	_audio.name = "RaceAudio"
	add_child(_audio)
	_audio.setup(self)
	if req.mode == "tt":
		_setup_ghost()
	countdown_left = 4.0 if not req.get("fast", false) else 0.5
	for c in cams:
		c.intro = 2.4 if countdown_left > 2.0 else 0.0
	InputRouter.calibrate_tilt()
	InputRouter.mouse_recentre()
	InputRouter.mouse_active = false
	InputRouter.mouse_capture_wanted = not autopilot and humans.size() == 1 and not InputRouter.touch_seen
	Events.log_event("race_start", {"mode": req.mode, "track": td.id, "variant": td.variant})
	Audio.music("race")
	_stage("audio")
	loaded = true
	race_loaded.emit()
	if not _fast:
		# Two frames behind the overlay: the renderer uploads every mesh and
		# compiles anything left on the first draw before the player sees it.
		Game.loading_progress(1.0, "Ready")
		await get_tree().process_frame
		await get_tree().process_frame
	Game.hide_loading()


func _stage(name: String) -> void:
	var now := Time.get_ticks_usec()
	load_ms[name] = float(now - _load_t) / 1000.0
	_load_t = now


# ---------------------------------------------------------------- world
func _build_world() -> void:
	var theme := Themes.get_theme(td.theme)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/space_sky.gdshader")
	Themes.apply_sky(sm, theme)
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky = sky
	_sky_mat = sm
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = theme.ambient
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.glow_intensity = 0.7
	env.glow_strength = 1.0
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.fog_light_color = theme.fog
	env.fog_density = 0.0011
	env.fog_sky_affect = 0.0
	env.fog_height = _lowest_y() + 6.0
	env.fog_height_density = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_env = env
	var sun := DirectionalLight3D.new()
	sun.light_color = theme.sun
	sun.light_energy = 1.25
	add_child(sun)
	_sun = sun
	var ld := Themes.light_dir(theme)
	sun.look_at_from_position(Vector3.ZERO, ld, Vector3.UP if absf(ld.y) < 0.95 else Vector3.FORWARD)
	var wind := Vector3(ld.x, 0.0, ld.z)
	stellar_wind = wind.normalized() if wind.length() > 0.05 else Vector3.RIGHT
	_stage("world_env")
	await _yield(0.15, "Laying the road")
	var track := Node3D.new()
	track.name = "Track"
	add_child(track)
	TrackBuilder.build(td, track)
	_stage("world_track")
	await _yield(0.4, "Placing the scenery")
	TrackDecor.build(td, track)
	var biome := BiomeBuilder.pick(td)
	if not biome.is_empty():
		BiomeBuilder.apply_env(_env, _sun, biome)
	_stage("world_decor")
	_decor = track.get_node_or_null("Decor")
	apply_quality()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	InputRouter.release_mouse()


func _lowest_y() -> float:
	var y := INF
	for p in td.main.pts:
		y = minf(y, p.y)
	return y


## Applies the current graphics tier to lighting, effects and viewports.
## Called at load and whenever auto quality steps down.
func apply_quality() -> void:
	var qs := Gfx.q()
	_env.glow_enabled = bool(qs.glow)
	_env.fog_enabled = bool(qs.fog)
	_env.fog_height_density = 0.012 if int(qs.shadows) > 0 else 0.0
	_env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY if bool(qs.reflect) else Environment.REFLECTION_SOURCE_DISABLED
	_env.adjustment_enabled = int(qs.detail) > 0
	if _sky_mat:
		_sky_mat.set_shader_parameter("detail", float(qs.sky_detail))
	if _sun:
		Gfx.apply_sun(_sun, qs)
	var road_detail := float(qs.road_detail)
	TrackBuilder.set_quality(road_detail, bool(qs.reflect))
	Gfx.apply_viewport(get_viewport(), qs)
	for c in cams:
		if c.get_viewport() != get_viewport():
			Gfx.apply_viewport(c.get_viewport(), qs)
	_apply_res_scale()
	if _decor:
		_decor_density(float(qs.decor))
	if fx:
		fx.particles = float(qs.particles)
	for h in huds:
		h.set_speedlines(bool(qs.speedlines))


func _spawn() -> void:
	var entries: Array = req.racers
	var holder := Node3D.new()
	holder.name = "Racers"
	add_child(holder)
	for k in entries.size():
		var e: Dictionary = entries[k]
		var r := Racer.new()
		r.name = "Racer%d" % k
		holder.add_child(r)
		r.setup(self, k, e.look, e.get("upgrades", {}), e.get("kit", {}))
		r.is_human = e.get("human", false) and not autopilot
		r.slot = e.get("slot", -1) if r.is_human else -1
		if r.is_human:
			r.controller = PlayerDriver.new(r.slot)
			if req.get("bot_humans", false):
				r.controller = AIDriver.new(r.pilot.style, 0.85, k * 31)
			humans.append(r)
		else:
			var ai := AIDriver.new(e.get("style", r.pilot.style), e.get("skill", 0.7), hash(r.name) + k * 977)
			r.controller = ai
			r.speed_mult = e.get("speed", 1.0)
		r.place_at(td.grid_transform(k))
		r.event.connect(_on_racer_event.bind(r))
		racers.append(r)
		_lap_start[r.idx] = 0.0
		_led[r.idx] = false
		_was_short[r.idx] = false
		if k % 2 == 1 and k < entries.size() - 1:
			await _yield(0.55 + 0.25 * float(k + 1) / float(entries.size()), "Rolling out the grid")
	if autopilot and not racers.is_empty():
		humans.append(racers[0])


func _setup_views() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)
	var view_racers: Array[Racer] = []
	for h in humans:
		view_racers.append(h)
	if view_racers.is_empty():
		view_racers.append(racers[0])
	if view_racers.size() == 1:
		var cam := RaceCamera.new()
		add_child(cam)
		cam.target = view_racers[0]
		cam.current = true
		cam.snap()
		cams.append(cam)
		var hud := Hud.new()
		ui_layer.add_child(hud)
		hud.setup(self, view_racers[0], false)
		huds.append(hud)
		if Save.setting("show_fps"):
			_fps_lbl = UiKit.label("", 18, UiKit.DIM)
			hud.add_child(_fps_lbl)
			UiKit.place(_fps_lbl, Vector2(0, 1), Vector2(10, -30), Vector2(120, 24))
		if InputRouter.touch_seen and not autopilot:
			touch = TouchControls.new()
			touch.racer = view_racers[0]
			ui_layer.add_child(touch)
			hud.add_pause(_pause_button())
		elif not autopilot and bool(Save.setting("key_hints")):
			hints = DesktopHints.new()
			hints.racer = view_racers[0]
			ui_layer.add_child(hints)
	else:
		var split := VBoxContainer.new()
		split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		split.add_theme_constant_override("separation", 4)
		var bg_layer := CanvasLayer.new()
		bg_layer.layer = 0
		add_child(bg_layer)
		bg_layer.add_child(split)
		for r in view_racers:
			var svc := SubViewportContainer.new()
			svc.stretch = true
			svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
			split.add_child(svc)
			var sv := SubViewport.new()
			sv.audio_listener_enable_3d = r == view_racers[0]
			svc.add_child(sv)
			var cam := RaceCamera.new()
			sv.add_child(cam)
			cam.target = r
			cam.current = true
			cams.append(cam)
			var hud := Hud.new()
			svc.add_child(hud)
			hud.setup(self, r, true)
			huds.append(hud)
		get_viewport().disable_3d = true
		for c in cams:
			c.snap()


# ---------------------------------------------------------------- cockpit view
const PILOT_LAYER_BIT := 10     # render layer 11/12 hold player 1/2's own pilot


## Gives each viewed racer's pilot its own render layer (so their cockpit
## camera can leave it out), and starts in cockpit if that was last used.
func _setup_cockpits() -> void:
	for k in cams.size():
		var c := cams[k]
		if c.target == null or c.target.model == null:
			continue
		var bit := 1 << (PILOT_LAYER_BIT + k)
		c.target.model.set_pilot_layer(bit)
		c.pilot_mask = bit
		var h := hud_for(c.target)
		if h and h.cockpit_tab:
			h.cockpit_tab.pressed.connect(toggle_cockpit.bind(c.target))
			if touch:
				touch.blockers.append(h.cockpit_tab)
		if k == 0 and bool(Save.setting("cockpit")) and not autopilot:
			_set_cockpit(c.target, true)


func cockpit_on(r: Racer) -> bool:
	var c := cam_for(r)
	return c != null and c.cockpit


## Switch a player's view between chase camera and cockpit, any time.
func toggle_cockpit(r: Racer) -> void:
	_set_cockpit(r, not cockpit_on(r))
	if cams.size() == 1 or (not cams.is_empty() and cams[0].target == r):
		Save.set_setting("cockpit", cockpit_on(r))


func _set_cockpit(r: Racer, on: bool) -> void:
	var c := cam_for(r)
	if c == null:
		return
	c.set_cockpit(on)
	var h := hud_for(r)
	if h:
		h.set_cockpit(on)


## Auto quality: if the game runs below ~28 fps for 3 seconds, step the
## graphics down one tier (ultra -> high -> medium -> low) and say so.
func _process(dt: float) -> void:
	if not loaded:
		return
	if _slowmo_until > 0 and Time.get_ticks_msec() >= _slowmo_until:
		_slowmo_until = 0
		Engine.time_scale = 1.0
	if _fps_lbl:
		_fps_lbl.text = "%d fps  %s%s" % [Engine.get_frames_per_second(), Game.quality(), "" if res_scale >= 0.999 else "  %d%%" % int(res_scale * 100.0)]
	if Save.setting("quality") != "auto" or not racing or get_tree().paused:
		return
	_dyn_res(dt)
	if dt > 1.0 / 28.0:
		_slow_t += dt
	else:
		_slow_t = maxf(0.0, _slow_t - dt * 0.5)
	# Only drop a whole tier once the render scale is already at its floor.
	if _slow_t > 3.0 and res_scale <= RES_MIN + 0.001:
		_slow_t = 0.0
		var i := Gfx.tier_index(Game.detected_quality)
		if i <= 0:
			return
		Game.detected_quality = Gfx.TIERS[i - 1]
		res_scale = 1.0
		apply_quality()
		for h in huds:
			h.toast("Graphics lowered for smoother play", UiKit.DIM)


## Eases the 3D render scale down while frames run long (over ~25 ms on
## average) and back up once they're comfortably short again. Checked a few
## times a second so one hitch never changes anything.
func _dyn_res(dt: float) -> void:
	_ft_avg = lerpf(_ft_avg, minf(dt, 0.1), 0.08)
	_res_t += dt
	if _res_t < 0.5:
		return
	_res_t = 0.0
	var want := res_scale
	# Against the frame time we aim for: with a 30 fps cap (or a browser
	# throttled to 30 Hz) every frame took 33 ms "late" and the image
	# dropped to 60% for good.
	var target := 1.0 / float(Engine.max_fps) if Engine.max_fps > 0 else 1.0 / 60.0
	if _ft_avg > target * 1.5:
		want = maxf(RES_MIN, res_scale - 0.1)
	elif _ft_avg < target * 1.05:
		want = minf(1.0, res_scale + 0.05)
	if not is_equal_approx(want, res_scale):
		res_scale = want
		_apply_res_scale()


func _apply_res_scale() -> void:
	var qs := Gfx.q()
	var seen := {}
	for vp in [get_viewport()] + cams.map(func(c: Camera3D) -> Viewport: return c.get_viewport()):
		if vp == null or seen.has(vp):
			continue
		seen[vp] = true
		vp.scaling_3d_scale = clampf(float(qs.scale) * res_scale, 0.3, 1.0)


func _decor_density(k: float) -> void:
	if _decor == null:
		return
	for c in _decor.get_children():
		if c is MultiMeshInstance3D:
			var mm: MultiMesh = c.multimesh
			mm.visible_instance_count = -1 if k >= 1.0 else int(mm.instance_count * k)


func _thin_decor() -> void:
	_decor_density(0.5)


func _pause_button() -> Control:
	var b := Button.new()
	b.text = "II"
	b.add_theme_font_size_override("font_size", 30)
	b.custom_minimum_size = Vector2(70, 64)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(toggle_pause)
	return b


func hud_for(r: Racer) -> Hud:
	for h in huds:
		if h.racer == r:
			return h
	return null


func cam_for(r: Racer) -> RaceCamera:
	for c in cams:
		if c.target == r:
			return c
	return null


# ---------------------------------------------------------------- loop
func _physics_process(dt: float) -> void:
	if done or not loaded:
		return
	if not racing:
		countdown_left -= dt
		var n := ceili(countdown_left)
		if n != _last_count and n <= 3 and n >= 1:
			_last_count = n
			for h in huds:
				var sub := ""
				if n == 3:
					sub = td.name
				elif n == 2:
					var facts: Array = td.def.get("facts", [])
					sub = str(facts[0]) if not facts.is_empty() else ""
				elif req.mode != "tt":
					sub = "Hold GAS right on GO for a rocket start"
				h.big(str(n), sub, 0.9, UiKit.CYAN)
			Audio.play("count")
		if countdown_left <= 0.0:
			racing = true
			for h in huds:
				h.big("GO!", "", 0.8, UiKit.GREEN)
			Audio.play("go")
			for r in racers:
				r.on_go()
				_lap_start[r.idx] = 0.0
				# Leading from pole counts toward "lead a whole lap" on lap 1.
				_led[r.idx] = r.place == 1
	else:
		time += dt
	var t0 := Time.get_ticks_usec()
	for r in racers:
		r.tick(dt)
	var t1 := Time.get_ticks_usec()
	if racing:
		_bumps()
		_slipstream(dt)
		_rubber_band()
	var t2 := Time.get_ticks_usec()
	pickups.tick(dt)
	var t3 := Time.get_ticks_usec()
	items.tick(dt)
	var t4 := Time.get_ticks_usec()
	hazards.tick(dt)
	var t5 := Time.get_ticks_usec()
	_rank()
	_laps()
	_ghost_tick(dt)
	var t6 := Time.get_ticks_usec()
	prof.racers += t1 - t0
	prof.pairs += t2 - t1
	prof.pickups += t3 - t2
	prof.items += t4 - t3
	prof.hazards += t5 - t4
	prof.rest += t6 - t5
	prof.ticks += 1
	if _all_done_t >= 0.0:
		_all_done_t -= dt
		if _all_done_t <= 0.0:
			_finish_race()


func _bumps() -> void:
	var n := racers.size()
	for a in n:
		var ra := racers[a]
		if ra.is_ghost or ra.rescue_time > 0.0 or ra.cloak_time > 0.0:
			continue
		for b in range(a + 1, n):
			var rb := racers[b]
			if rb.is_ghost or rb.rescue_time > 0.0 or rb.cloak_time > 0.0:
				continue
			var d := rb.global_position - ra.global_position
			var dist := d.length()
			if dist > 2.75 or dist < 0.01:
				continue
			var nrm := (d - ra.up * d.dot(ra.up))
			if nrm.length() < 0.01:
				continue
			nrm = nrm.normalized()
			var wa := ra.weight * ra.bump_mult
			var wb := rb.weight * rb.bump_mult
			var tot := wa + wb
			var push := 2.75 - dist
			ra.global_position -= nrm * push * wb / tot
			rb.global_position += nrm * push * wa / tot
			var rel := (rb.velocity - ra.velocity).dot(nrm)
			if rel < 0.0:
				var imp := -rel * 1.3 + 2.0
				ra.velocity -= nrm * imp * wb / tot
				rb.velocity += nrm * imp * wa / tot
				if -rel > 5.0:
					ra.emit_signal("event", "bump", {"impact": -rel})
					rb.emit_signal("event", "bump", {"impact": -rel, "quiet": true})


func _slipstream(dt: float) -> void:
	for r in racers:
		if r.is_ghost or r.finished:
			continue
		var right := r.heading.cross(r.up)
		var close := false
		for o in racers:
			if o == r or o.is_ghost or o.fwd_speed < 20.0:
				continue
			var d := o.global_position - r.global_position
			var along := d.dot(r.heading)
			if along > 2.5 and along < tuning.slip_range * r.slip_range_mult and absf(d.dot(right)) < tuning.slip_width:
				close = true
				break
		r.update_slip(dt, close)


## AI near the humans race a little harder or softer so the pack stays close.
func _rubber_band() -> void:
	if humans.is_empty() or autopilot or req.mode == "tt":
		return
	var lead := -INF
	for h in humans:
		lead = maxf(lead, h.race_dist)
	var base_cls: Dictionary = Catalog.AI_CLASSES[clampi(req.get("ai_class", 1), 0, 3)]
	var bmin: float = base_cls.band[0]
	var bmax: float = base_cls.band[1]
	# Fair finish: in the last half lap the AI stops catching up from behind
	# (it still eases off when ahead, so you can still reel it in).
	var total := td.main.length * td.laps
	var late := lead > total - td.main.length * 0.5
	for r in racers:
		if r.is_human or r.is_ghost:
			continue
		var diff := r.race_dist - lead
		var band := clampf(-diff / 600.0, -bmin, bmax * (0.35 if late else 1.0))
		if req.mode == "boss":
			band = clampf(-diff / 700.0, -0.04, 0.05)
		r.speed_mult = float(base_cls.speed) * (1.0 + band) * float(req.get("boss_edge", 1.0) if req.mode == "boss" else 1.0)


## Places, every tick. One reused array and one sort function (it used to
## duplicate, filter and build two lambdas per tick).
var _order: Array[Racer] = []
var _order_n := -1
static func _ahead(a: Racer, b: Racer) -> bool:
	if a.finished and b.finished:
		return a.finish_time < b.finish_time
	if a.finished != b.finished:
		return a.finished
	return a.race_dist > b.race_dist


func _rank() -> void:
	if _order_n != racers.size():
		_order_n = racers.size()
		_order.clear()
		for r in racers:
			if not r.is_ghost:
				_order.append(r)
	_order.sort_custom(_ahead)
	var order := _order
	for k in order.size():
		var r: Racer = order[k]
		r.place = k + 1
		if r.place != 1:
			_led[r.idx] = false


func _laps() -> void:
	if not racing:
		return
	var L := td.main.length
	for r in racers:
		if r.finished or r.is_ghost:
			continue
		if r.on_shortcut and not _was_short[r.idx]:
			r.stats.shortcuts += 1
			if r.is_human:
				var fs: Dictionary = Save.data.get("found_short", {})
				fs[td.id] = true
				Save.data["found_short"] = fs
				Save.mark()
				var h := hud_for(r)
				if h:
					h.toast("SECRET SHORTCUT!", UiKit.GOLD)
		_was_short[r.idx] = r.on_shortcut
		var new_lap := maxi(1, floori(r.race_dist / L) + 1)
		if new_lap > r.lap:
			r.lap = new_lap
			var lap_time := time - float(_lap_start[r.idx])
			_lap_start[r.idx] = time
			if _led[r.idx]:
				r.stats.lead_laps += 1
			_led[r.idx] = r.place == 1
			if r.is_human:
				_on_human_lap(r, lap_time)
			if new_lap > td.laps:
				_finish(r)
			elif r.is_human:
				var h := hud_for(r)
				if h:
					if new_lap == td.laps:
						h.big("FINAL LAP", "Lap %s" % UiKit.time_str(lap_time), 1.6, UiKit.GOLD)
					else:
						h.big("LAP %d" % new_lap, "Lap %s" % UiKit.time_str(lap_time), 1.2, UiKit.CYAN)


func _on_human_lap(r: Racer, lap_time: float) -> void:
	if r.lap <= 1:
		return
	r.stats["best_lap"] = minf(float(r.stats.get("best_lap", INF)), lap_time)


func _finish(r: Racer) -> void:
	r.finished = true
	r.finish_time = time
	finish_order.append(r)
	if r.is_human or (autopilot and r == racers[0]):
		var ai := AIDriver.new(r.pilot.style, 0.8, r.idx)
		ai.cruise = true
		r.controller = ai
	elif r.controller is AIDriver:
		(r.controller as AIDriver).cruise = true
	if r.is_human:
		var h := hud_for(r)
		if h:
			var place := 0
			for o in racers:
				if o == r:
					place = o.place
			h.big("FINISHED!", UiKit.ordinal(place) + " place  " + UiKit.time_str(time), 3.0, UiKit.GOLD if place == 1 else Color.WHITE)
		Audio.play("finish")
		_fx_for("finish_fx", {}, r)
		# A moment of slow motion as you cross the line (one player only).
		if humans.size() == 1 and not req.get("fast", false):
			_slowmo_until = Time.get_ticks_msec() + 900
			Engine.time_scale = 0.35
	var all_humans_done := true
	for h in humans:
		if not h.finished:
			all_humans_done = false
	var everyone := true
	for o in racers:
		if not o.finished and not o.is_ghost:
			everyone = false
	if autopilot and req.get("fast", false):
		if everyone:
			_all_done_t = 0.01
	elif (all_humans_done and _all_done_t < 0.0) or everyone:
		_all_done_t = 0.05 if req.get("fast", false) else 2.5


func _finish_race() -> void:
	if done:
		return
	done = true
	racing = false
	InputRouter.release_mouse()
	# Estimate times for anyone still racing.
	var L := td.main.length * td.laps
	var est: Array = []
	for r in racers:
		if r.is_ghost:
			continue
		var t := r.finish_time
		if not r.finished:
			var left := maxf(L - r.race_dist, 0.0)
			t = time + left / maxf(r.max_speed * 0.8, 20.0)
		est.append({"r": r, "t": t, "fin": r.finished})
	est.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.t < b.t)
	results.clear()
	for k in est.size():
		var r: Racer = est[k].r
		results.append({"idx": r.idx, "name": r.display_name, "pilot": r.pilot.id, "saucer": r.saucer.id,
			"human": r.is_human, "slot": r.slot, "time": est[k].t, "place": k + 1, "stats": r.stats.duplicate()})
	_save_ghost()
	emit_signal("race_finished", results)
	if autopilot and req.get("fast", false):
		return
	Game.on_race_finished(self, results)


# ---------------------------------------------------------------- events
## A racer's sound: 3D for rivals; flat for local players in split-screen
## (only player one's view has the 3D listener, so player two's own hits
## and items were silent once they were far from player one).
func _sound(name: String, r: Racer, vol_db := 0.0) -> void:
	if r.is_human and humans.size() > 1:
		Audio.play(name, vol_db - 3.0)
	else:
		Audio.play_at(name, r.global_position, vol_db)


func _on_racer_event(kind: String, d: Dictionary, r: Racer) -> void:
	var cam := cam_for(r)
	_fx_for(kind, d, r)
	match kind:
		"hit":
			if cam:
				cam.add_shake(0.8)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.9, 0.35)
			_sound("hit", r)
		"warped":
			if cam:
				cam.warp_cut()
			if r.is_human:
				InputRouter.rumble(r.slot, 0.5, 0.2)
		"wonder":
			if cam:
				cam.add_shake(0.45)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.8, 0.3)
			_sound("boost", r, 2.0)
		"burnout":
			if r.is_human:
				InputRouter.rumble(r.slot, 1.0, 0.5)
			_sound("alarm", r)
		"pulsed":
			if cam:
				cam.add_shake(0.4)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.6, 0.2)
		"glide_on":
			_sound("glide", r)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.3, 0.15)
		"walled", "repulsed":
			if cam:
				cam.add_shake(0.5)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.7, 0.25)
			_sound("hit", r)
		"wall":
			if cam and d.impact > 10.0:
				cam.add_shake(0.35)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.4, 0.12)
		"bump":
			if cam:
				cam.add_shake(0.3)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.5, 0.1)
			if not d.get("quiet", false) or r.is_human:
				_sound("bump", r)   # one sound per collision (both racers get the event)
		"land":
			if cam:
				cam.land(d.impact)
			if r.is_human and d.impact > 8.0:
				InputRouter.rumble(r.slot, 0.35, 0.08)
				if cam:
					cam.add_shake(0.2)
		"boost":
			if r.is_human:
				Audio.play("boost")
		"pod":
			if r.is_human:
				Audio.play("pod")
		"item_roll":
			if r.is_human:
				Audio.play("crate")
		"item_used":
			_sound("item_" + str(d.item), r)
		"trick":
			if r.is_human:
				Audio.play("trick")
		"emergency":
			if r.is_human:
				Audio.play("alarm")
				InputRouter.rumble(r.slot, 0.6, 0.4)
		"drift_tier":
			if r.is_human and d.tier > 0:
				Audio.play("tier", -4.0, 1.0 + 0.15 * d.tier)
		"near_miss", "slipstream":
			if r.is_human:
				Audio.play("whoosh")
	if r.is_human:
		Events.on_racer_event(kind, d)


## Visual effects for racer events (all pooled in RaceFx).
func _fx_for(kind: String, d: Dictionary, r: Racer) -> void:
	if fx == null:
		return
	var pos := r.global_position
	match kind:
		"hit":
			var hk: String = d.get("kind", "")
			var hc: Color = (SaucerModel.REACT.get(hk, SaucerModel.REACT.hazard) as Array)[0]
			fx.flash(pos + r.up * 0.6, hc.lerp(Color.WHITE, 0.3), 4.5, 0.25)
			fx.sparks(pos + r.up * 0.4, r.up, hc, 30, 12.0)
			fx.shockwave(pos, r.up, hc, 6.0, 0.35)
			r.model.react(hk)
		"blocked":
			fx.flash(pos + r.up * 0.6, Color(0.4, 0.85, 1.0), 5.0, 0.25)
			fx.shockwave(pos, r.up, Color(0.4, 0.85, 1.0), 7.0, 0.4)
			fx.sparks(pos + r.up * 0.8, r.up, Color(0.5, 0.9, 1.0), 20, 10.0)
			r.model.react("block")
		"tractored":
			r.model.react("tractor")
		"wonder":
			var wc: Color = d.get("color", Color.WHITE)
			fx.shockwave(pos, r.up, wc, 11.0 * float(d.get("power", 1.0)), 0.55)
			fx.flash(pos + r.up * 0.8, wc.lerp(Color.WHITE, 0.3), 6.0, 0.3)
			fx.sparks(pos + r.up * 0.5 - r.heading * 1.5, -r.heading + r.up * 0.3, wc, 34, 14.0, 4.0)
		"burnout":
			fx.dust(pos + r.up * 0.8, r.up, Color(0.18, 0.16, 0.16), 30)
			fx.sparks(pos + r.up * 0.6, r.up, Color(1.0, 0.45, 0.15), 22, 8.0)
		"pulsed":
			fx.sparks(pos + r.up * 0.5, r.up, Color(0.7, 0.55, 1.0), 16, 9.0)
		"item_roll", "crate_smash":
			# The crate shatters into glowing shards.
			fx.sparks(pos + r.up * 1.0 + r.heading * 1.5, r.up + r.heading * 0.5, Color(0.85, 0.45, 1.0), 26, 11.0, 14.0)
			fx.flash(pos + r.up * 1.0 + r.heading * 1.5, Color(0.9, 0.6, 1.0), 3.2, 0.18)
		"wall":
			if d.get("impact", 0.0) > 6.0:
				var side := r.heading.cross(r.up).normalized() * signf(r.lateral)
				fx.sparks(pos + side * 1.6, -side + r.up * 0.5 - r.heading * 0.3, Color(1.0, 0.75, 0.35), 18, 9.0)
		"bump":
			fx.sparks(pos + r.up * 0.3, r.up, Color(1.0, 0.9, 0.6), 12, 7.0)
		"land":
			if d.get("impact", 0.0) > 5.0:
				var sc: Color = Catalog.surface(r.surface).color
				fx.dust(pos - r.up * 0.8, r.up, sc.lightened(0.25), 20)
				fx.shockwave(pos - r.up * 0.6, r.up, Color(1, 1, 1, 1).lerp(sc, 0.5), 5.5, 0.35)
		"boost":
			var kind_b: String = d.get("kind", "")
			var c: Color = r.model.trail_color
			if kind_b in ["nitro", "pad", "trick", "slip"]:
				fx.shockwave(pos, r.up, c, 6.5 if kind_b != "nitro" else 8.0, 0.4)
		"drift_boost":
			var tc: Color = SaucerModel.SPARK_COLORS[clampi(int(d.get("tier", 1)) - 1, 0, 2)]
			fx.shockwave(pos, r.up, tc, 5.0 + 1.5 * float(d.get("tier", 1)), 0.4)
			fx.sparks(pos + r.heading * -1.5, -r.heading + r.up * 0.4, tc, 16, 10.0)
		"drift_tier":
			if int(d.get("tier", 0)) > 0:
				var tc2: Color = SaucerModel.SPARK_COLORS[clampi(int(d.tier) - 1, 0, 2)]
				fx.flash(pos - r.heading * 1.6 - r.up * 0.2, tc2, 2.6, 0.18)
		"start_boost":
			fx.shockwave(pos, r.up, Color(0.5, 1.0, 0.6), 8.0, 0.5)
		"pod":
			fx.flash(pos + r.up * 0.8, Color(0.4, 1.0, 0.9), 2.2, 0.18)
		"trick":
			fx.sparks(pos + r.up * 0.5, r.up, Color(1.0, 0.9, 0.4), 20, 8.0, 6.0)
		"respawn", "rescued":
			fx.flash(pos + r.up * 0.6, Color(0.6, 0.9, 1.0), 5.0, 0.35)
			fx.shockwave(pos, r.up, Color(0.6, 0.9, 1.0), 6.0, 0.5)
		"glide_on":
			fx.flash(pos + r.up * 0.4, Color(0.5, 0.95, 1.0), 3.5, 0.25)
			fx.sparks(pos + r.up * 0.2, -r.heading, Color(0.5, 0.95, 1.0), 18, 7.0, 2.0)
		"warped":
			var from: Vector3 = d.get("from", pos)
			fx.flash(from + r.up * 0.6, Color(0.6, 0.45, 1.0), 6.0, 0.3)
			fx.shockwave(from, r.up, Color(0.6, 0.45, 1.0), 7.0, 0.4)
			fx.flash(pos + r.up * 0.6, Color(0.8, 0.7, 1.0), 7.0, 0.35)
			fx.shockwave(pos, r.up, Color(0.6, 0.45, 1.0), 9.0, 0.45)
			fx.sparks(pos + r.up * 0.5, r.heading, Color(0.7, 0.5, 1.0), 26, 12.0, 4.0)
		"decoy_popped":
			var dp: Vector3 = d.get("pos", pos)
			fx.flash(dp + Vector3.UP * 0.6, Color(0.5, 0.95, 1.0), 5.0, 0.3)
			fx.sparks(dp + Vector3.UP * 0.5, Vector3.UP, Color(0.5, 0.95, 1.0), 24, 9.0)
		"welled":
			fx.sparks(pos + r.up * 0.4, r.up, Color(0.55, 0.3, 1.0), 14, 6.0)
		"frosted":
			fx.dust(pos - r.up * 0.6, r.up, Color(0.8, 0.95, 1.0), 16)
		"overcharge":
			fx.shockwave(pos, r.up, Color(1.0, 0.6, 0.15), 9.0, 0.45)
			fx.flash(pos + r.up * 0.6, Color(1.0, 0.75, 0.3), 5.0, 0.3)
			r.model.react("overcharge")
		"flared":
			fx.flash(pos + r.up * 0.8, Color(1.0, 0.97, 0.8), 7.0, 0.4)
		"chained":
			fx.sparks(pos + r.up * 0.6, r.up, Color(0.6, 0.9, 1.0), 26, 10.0)
		"walled":
			fx.flash(pos + r.up * 0.6, Color(1.0, 0.3, 0.75), 5.0, 0.3)
			fx.sparks(pos + r.up * 0.5, -r.heading + r.up, Color(1.0, 0.4, 0.8), 28, 12.0)
			r.model.react("plasma")
		"stasis":
			fx.flash(pos + r.up * 0.6, Color(0.3, 0.95, 0.85), 3.5, 0.3)
		"cloaked":
			fx.flash(pos + r.up * 0.6, Color(0.8, 0.7, 1.0), 6.0, 0.35)
			fx.shockwave(pos, r.up, Color(0.8, 0.7, 1.0), 7.0, 0.4)
		"repulsed":
			fx.sparks(pos + r.up * 0.5, r.up, Color(1.0, 0.45, 0.2), 22, 10.0)
			fx.flash(pos + r.up * 0.6, Color(1.0, 0.5, 0.25), 4.0, 0.25)
			r.model.react("repulsor")
		"finish_fx":
			for c: Color in [Color(1.0, 0.85, 0.2), Color(0.3, 0.9, 1.0), Color(1.0, 0.35, 0.8)]:
				fx.sparks(pos + r.up * 1.5, r.up + r.heading * 0.3, c, 26, 14.0, 9.0)
			fx.shockwave(pos, r.up, Color(1.0, 0.85, 0.3), 10.0, 0.6)


func on_shard(r: Racer, slot: int) -> bool:
	var new_one := Save.take_shard(td.id, slot)
	if new_one:
		Save.add_credits(50)
	Audio.play("shard")
	return new_one


func shake_all(amount: float) -> void:
	for c in cams:
		c.add_shake(amount)


func shake_near(pos: Vector3, amount: float) -> void:
	for c in cams:
		if c.target and c.target.global_position.distance_to(pos) < 40.0:
			c.add_shake(amount)


# ---------------------------------------------------------------- ghost (time trial)
func ghost_key() -> String:
	return "%s_%d" % [td.id, td.variant]


func _setup_ghost() -> void:
	_ghost_play = Save.load_ghost(ghost_key())
	if _ghost_play.is_empty():
		return
	ghost_racer = Racer.new()
	ghost_racer.name = "Ghost"
	ghost_racer.is_ghost = true
	$Racers.add_child(ghost_racer)
	var look: Dictionary = Save.player_look()
	ghost_racer.setup(self, racers.size(), look, {})
	ghost_racer.collision_layer = 0
	ghost_racer.collision_mask = 0
	ghost_racer.display_name = "Ghost"
	_ghostify(ghost_racer.model)
	racers.append(ghost_racer)
	ghost_racer.place_at(td.grid_transform(0))


func _ghostify(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.7, 0.9, 1.0, 0.25)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			c.material_override = m
		elif c is CPUParticles3D:
			c.visible = false
		_ghostify(c)


func _ghost_tick(dt: float) -> void:
	if req.mode != "tt" or not racing:
		return
	_ghost_t += dt
	var me: Racer = humans[0] if not humans.is_empty() else null
	var frame := int(_ghost_t * GHOST_HZ)
	if me and not me.finished and _ghost_rec.size() / GHOST_STRIDE <= frame:
		var p := me.global_position
		var q := me.global_basis.get_rotation_quaternion()
		_ghost_rec.append_array([_ghost_t, p.x, p.y, p.z, q.x, q.y, q.z, q.w])
	if ghost_racer and not _ghost_play.is_empty():
		var n := _ghost_play.size() / GHOST_STRIDE
		var f := _ghost_t * GHOST_HZ
		var i := mini(int(f), n - 2)
		if i < 0 or n < 2:
			return
		var t := clampf(f - float(i), 0.0, 1.0)
		var a := i * GHOST_STRIDE
		var b := (i + 1) * GHOST_STRIDE
		var pa := Vector3(_ghost_play[a + 1], _ghost_play[a + 2], _ghost_play[a + 3])
		var pb := Vector3(_ghost_play[b + 1], _ghost_play[b + 2], _ghost_play[b + 3])
		var qa := Quaternion(_ghost_play[a + 4], _ghost_play[a + 5], _ghost_play[a + 6], _ghost_play[a + 7])
		var qb := Quaternion(_ghost_play[b + 4], _ghost_play[b + 5], _ghost_play[b + 6], _ghost_play[b + 7])
		ghost_racer.global_transform = Transform3D(Basis(qa.slerp(qb, t)), pa.lerp(pb, t))
		ghost_racer.track_idx = td.main.nearest(ghost_racer.global_position, ghost_racer.track_idx, 30)


func _save_ghost() -> void:
	if req.mode != "tt" or humans.is_empty():
		return
	var me := humans[0]
	if not me.finished:
		return
	var best: float = Save.data.best_time.get("%s:%d" % [td.id, td.variant], INF)
	if me.finish_time <= best + 0.001:
		Save.save_ghost(ghost_key(), _ghost_rec)


# ---------------------------------------------------------------- pause
func _unhandled_input(e: InputEvent) -> void:
	if done or not loaded:
		return
	var pause := false
	if e is InputEventKey and e.pressed and not e.echo:
		pause = e.physical_keycode == KEY_ESCAPE or e.physical_keycode == KEY_P
		# Cockpit view: V for player one, M for player two.
		if (e.physical_keycode == KEY_V or e.physical_keycode == KEY_M) and not cams.is_empty():
			var ci := 0 if e.physical_keycode == KEY_V else 1
			if ci < cams.size() and cams[ci].target:
				toggle_cockpit(cams[ci].target)
				get_viewport().set_input_as_handled()
	elif e is InputEventJoypadButton and e.pressed:
		pause = e.button_index == JOY_BUTTON_START
		if e.button_index == JOY_BUTTON_BACK:
			for c in cams:
				if c.target and (cams.size() == 1 or e.device in InputRouter._pad_for(c.target.slot)):
					toggle_cockpit(c.target)
					break
	if pause:
		toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if not loaded:
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not done and not get_tree().paused:
		toggle_pause()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and racing and not done and not get_tree().paused and OS.has_feature("mobile"):
		toggle_pause()


func toggle_pause() -> void:
	if done or not loaded:
		return
	var tree := get_tree()
	if tree.paused:
		tree.paused = false
		if _pause_panel:
			_pause_panel.queue_free()
			_pause_panel = null
		InputRouter.mouse_capture_wanted = not autopilot and humans.size() == 1 and not InputRouter.touch_seen
		return
	tree.paused = true
	InputRouter.release_mouse()
	_pause_panel = Game.pause_menu(self)
	ui_layer.add_child(_pause_panel)


func show_panel(p: Control) -> void:
	if _results_panel:
		_results_panel.queue_free()
	_results_panel = p
	ui_layer.add_child(p)
	if touch:
		touch.visible = false
